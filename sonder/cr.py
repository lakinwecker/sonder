from collections import defaultdict
from datetime import datetime
from functools import partial
from operator import eq, lt
from dataclasses import dataclass, field, asdict
from .pyutils import DefaultDictInt
from typing import List, Tuple, DefaultDict, Optional

from tqdm import tqdm

import click
import json
import math
import subprocess
import tempfile


from django.contrib.auth.models import User
from sonder.analysis.models import (
    AnalysisSource,
    Player,
    Game,
    GameAnalysis,
    CRReport
)

cr_export_sql_template = """
.mode csv
.headers off
.out {base_dir}/game.csv
select * from game;

.mode csv
.headers off
.out {base_dir}/gameplayer.csv
select * from gameplayer;

.mode csv
.headers off
.out {base_dir}/move.csv
select * from move;

.mode csv
.headers off
.out {base_dir}/player.csv
select * from player;

.exit

"""

def process_csv(taskname, filename,  callback):
    with open(filename, "r") as fd:
        progress = tqdm(fd.readlines(), taskname, leave=False)
        for line in progress:
            callback(*line.strip().split(","))
        progress.close()

def color_move_to_ply(color, move):
    if color == 'w':
        return (move-1)*2+1
    return move*2

def import_cr_database(database, analysis_source, stockfish_version):
    with tempfile.TemporaryDirectory() as base_dir:
        # Export the tables that we need
        lines = cr_export_sql_template.format(base_dir=base_dir)
        sqlite3 = subprocess.Popen(["/usr/bin/sqlite3", database], stdin=subprocess.PIPE)
        sqlite3.communicate(bytes(lines, "utf-8"))

        # Load the player table and insert all players and store
        # a mapping from id to player
        players_by_old_id = {}

        def process_player(old_player_id, username):
            player, _ = Player.objects.get_or_create(username=username.strip())
            players_by_old_id[old_player_id] = player
        process_csv("Loading players", f"{base_dir}/player.csv", process_player)
        click.secho("✓ Players Loaded", fg='green')

        players_by_lichess_game_id = defaultdict(lambda: dict((("w", None), ("b", None))))

        def process_gameplayer(_, lichess_id, color, player_id):
            player = players_by_old_id[player_id]
            players_by_lichess_game_id[lichess_id][color] = player
        process_csv("Loading Game Players", f"{base_dir}/gameplayer.csv", process_gameplayer)
        click.secho("✓ GamePlayers Loaded", fg='green')

        game_analysis_completed = {}

        def process_game(game_id, completed):
            completed = completed == "1"
            try:
                game = Game.objects.get(lichess_id=game_id.strip())
            except Game.DoesNotExist:
                game = Game(lichess_id=game_id.strip())
            players = players_by_lichess_game_id.get(game_id)
            if not players:
                print(f"Missing players for game: {game_id}")
                return
            if not players['w'] or not players['b']:
                raise AssertionError("Missing players")
            game.white_player = players['w']
            game.black_player = players['b']
            game.save()
            game_analysis_completed[game.lichess_id] = completed
        process_csv("Loading Games", f"{base_dir}/game.csv", process_game)
        click.secho("✓ Games Loaded", fg='green')

        game_analysis = defaultdict(lambda: defaultdict(dict))

        def process_move(_,game_id,color,number,pv1_eval,pv2_eval,pv3_eval,pv4_eval,pv5_eval,played_eval,played_rank,nodes,masterdb_matches):
            analysis = game_analysis[game_id]
            ply =  color_move_to_ply(color, int(number))
            analysis[ply].update({
                'color': color,
                'pv1_eval': pv1_eval,
                'pv2_eval': pv2_eval,
                'pv3_eval': pv3_eval,
                'pv4_eval': pv4_eval,
                'pv5_eval': pv5_eval,
                # These can ostensibly be extracted from the PVs, but CR analysis
                # didn't store the PVs so we don't have that data
                'played_eval': played_eval,
                'played_rank': played_rank,
                'nodes': nodes,
                'masterdb_matches': masterdb_matches,
            })
        process_csv("Loading Moves", f"{base_dir}/move.csv", process_move)
        click.secho("✓ Moves Loaded", fg='green')

        analysis_source, _ = AnalysisSource.objects.get_or_create(name=analysis_source)
        progress = tqdm(game_analysis.items(), "Processing analysis", leave=False)
        for game_id, cr_analysis in progress:
            game = Game.objects.get(lichess_id=game_id)
            game_analysis, _ = GameAnalysis.objects.get_or_create(
                game=game,
                source=analysis_source,
                stockfish_version=stockfish_version,
                defaults={
                    "analysis": [],
                    "is_completed": game_analysis_completed.get(game_id, False)
                }
            )
            moves  = list(sorted([(int(k), v) for k,v in cr_analysis.items()]))
            last_move_number, _ = moves[-1]

            def empty_move(num):
                return {
                    'move': num,
                    'pvs': [],
                    "cr": {}
                }
            sonder_analysis = [empty_move(i+1) for i in range(last_move_number)]
            for move_number, cr_move_analysis in moves:
                move_analysis = sonder_analysis[move_number-1]
                move_analysis.update({
                    "played_eval": cr_move_analysis['played_eval'],
                    "played_rank": cr_move_analysis['played_rank'],
                    "nodes": cr_move_analysis["nodes"],
                    "masterdb_matches": cr_move_analysis['masterdb_matches'],
                })

                def pv(cp):
                    return {"pv": "", "score": { "cp": cp, "mate": None }}
                move_analysis['pvs'] = [
                    pv(cr_move_analysis["pv1_eval"]),
                    pv(cr_move_analysis["pv2_eval"]),
                    pv(cr_move_analysis["pv3_eval"]),
                    pv(cr_move_analysis["pv4_eval"]),
                    pv(cr_move_analysis["pv5_eval"])
                ]

            game_analysis.analysis = sonder_analysis
            game_analysis.save()
        progress.close()
        click.secho("✓ Analysis Loaded", fg='green')

#Notes:
#ChessReanalysis structures
#game gameplayer move player
#CREATE TABLE IF NOT EXISTS "game" ("id" VARCHAR(255) NOT NULL PRIMARY KEY, "is_analyzed" INTEGER NOT NULL);
#INSERT INTO game VALUES('6OuA9Pzz',1);
#CREATE TABLE IF NOT EXISTS "player" ("id" INTEGER NOT NULL PRIMARY KEY, "username" VARCHAR(255) NOT NULL);
#INSERT INTO player VALUES(1,'dotaautochess');
#CREATE TABLE IF NOT EXISTS "gameplayer" ("id" INTEGER NOT NULL PRIMARY KEY, "game_id" VARCHAR(255) NOT NULL, "color" CHAR(1) NOT NULL, "player_id" INTEGER NOT NULL, FOREIGN KEY ("game_id") REFERENCES "game" ("id"), FOREIGN KEY ("player_id") REFERENCES "player" ("id"));
#INSERT INTO gameplayer VALUES(1,'6OuA9Pzz','w',1);
#CREATE TABLE IF NOT EXISTS "move" ("id" INTEGER NOT NULL PRIMARY KEY, "game_id" VARCHAR(255) NOT NULL, "color" CHAR(1) NOT NULL, "number" INTEGER NOT NULL, "pv1_eval" INTEGER NOT NULL, "pv2_eval" INTEGER, "pv3_eval" INTEGER, "pv4_eval" INTEGER, "pv5_eval" INTEGER, "played_eval" INTEGER NOT NULL, "played_rank" INTEGER, "nodes" INTEGER, "masterdb_matches" INTEGER, FOREIGN KEY ("game_id") REFERENCES "game" ("id"));
#INSERT INTO move VALUES(1,'UjjpxfT2','w',23,29999,29996,29995,29994,29994,29999,1,4500592,NULL);
#workingset
#{'XdWz7xCj': <chess.pgn.Game object at 0x7fd1ddd294a8>, 'upCHAiZ8': <chess.pgn.Game object at 0x7fd1ddd29518>, '3PWBaiNU': <chess.pgn.Game object at 0x7fd1ddd29588>, 'sj0rRs0p': <chess.pgn.Game object at 0x7fd1db3e0828>, 'QE19nwbB': <chess.pgn.Game object at 0x7fd1ddd29978>, '3gxV6COp': <chess.pgn.Game object at 0x7fd1db36e9b0>, 'bIJWIld6': <chess.pgn.Game object at 0x7fd1db3bfa58>, 'pfPF6jVl': <chess.pgn.Game object at 0x7fd1db362ba8>, '6OuA9Pzz': <chess.pgn.Game object at 0x7fd1db31e780>, 'UjjpxfT2': <chess.pgn.Game object at 0x7fd1db2dcd68>, 'a9oIsdVx': <chess.pgn.Game object at 0x7fd1db3f9860>}

# TODO: Make this configurable via the config file.
_cp_loss_intervals = [0, 10, 25, 50, 100, 200, 500]
cp_loss_names = ["=0"] + [f">{cp_incr}" for cp_incr in _cp_loss_intervals]
_cp_loss_ops = [partial(eq,0)] + [partial(lt, cp_incr) for cp_incr in _cp_loss_intervals]



def get_analysed_game_pgns_from_db(gameids):
    working_set = {}
    for analysis in GameAnalysis.objects.filter(game__lichess_id__in=gameids).select_related('game'):
        working_set[analysis.game.lichess_id] = analysis.analysis
            #TODO: ensure all games are fully analysed here, ^ this only ensures analysis started
    return working_set


def int_or_none(val):
    try:
        return int(val)
    except (ValueError, TypeError):
        return None

def wilson_interval(ns, n):
    z = 1.95996 # 0.95 confidence
    a = 1 / (n + z**2)
    b = ns + z**2 / 2
    c = z * (ns * (n - ns) / n + z**2 / 4)**(1/2)
    return (a * (b - c), a * (b + c))

def generate_stats_string(sample, total):
    percentage = sample / total
    stderr = std_error(percentage, total)
    ci = wilson_interval(sample, total)
    return f'{sample}/{total}; {percentage:.01%} (CI: {ci[0]*100:.01f} - {ci[1]*100:.01f})'

def std_error(p, n):
    return math.sqrt(p*(1-p)/n)


class Move:
    def __init__(self, move_analysis):
        self.move_analysis = move_analysis
        self.pvs = move_analysis['pvs']

    @property
    #TODO: change cp to account for mates if present (cp_to_score from CR)
    def pv1_eval(self):
        return int_or_none(self.pvs[0]['score']['cp'])

    @property
    def pv2_eval(self):
        return int_or_none(self.pvs[1]['score']['cp'])

    @property
    def pv3_eval(self):
        return int_or_none(self.pvs[2]['score']['cp'])

    @property
    def pv4_eval(self):
        return int_or_none(self.pvs[3]['score']['cp'])

    @property
    def pv5_eval(self):
        return int_or_none(self.pvs[4]['score']['cp'])

    @property
    def played_eval(self):
        return int_or_none(self.move_analysis['cr']['played_eval'])
        #Look up which move they played, if it's in the pv list then use that eval, if not, look at the pv[0] from the next move

    @property
    def played_rank(self):
        if self.move_analysis['cr']['played_rank'] == "":
            return None
        return int(self.move_analysis['cr']['played_rank'])
        #Look up which move they played, if it's in the pv list us it, if it's not there, use len(pvs)+1

    @property
    def color(self):
        if self.move_analysis['move'] % 2 == 1:
            return 'w'
        else:
            return 'b'

    @property
    def number(self):
        return ((self.move_analysis['move']-1) // 2) + 1

@dataclass
class PgnSpyResult():
    sample_size: int = 0
    sample_total_cpl: int = 0

    t1_total: int = 0
    t1_count: int = 0
    t2_total: int = 0
    t2_count: int = 0
    t3_total: int = 0
    t3_count: int = 0

    min_rating: Optional[int] = None
    max_rating: Optional[int] = None
    game_list: List[str] = field(default_factory=list)
    cp_loss_count: DefaultDictInt = field(default_factory=DefaultDictInt)
    cp_loss_total: int = 0

    def add(self, other):
        self.sample_size += other.sample_size
        self.sample_total_cpl += other.sample_total_cpl
        self.t1_total += other.t1_total
        self.t1_count += other.t1_count
        self.t2_total += other.t2_total
        self.t2_count += other.t2_count
        self.t3_total += other.t3_total
        self.t3_count += other.t3_count
        self.with_rating(other.min_rating)
        self.with_rating(other.max_rating)
        self.game_list += other.game_list
        for k in cp_loss_names:
            self.cp_loss_count[k] += other.cp_loss_count[k]
        self.cp_loss_total += other.cp_loss_total

    def with_rating(self, rating):
        if rating is None:
            return
        self.min_rating = min(self.min_rating, rating) if self.min_rating else rating
        self.max_rating = max(self.max_rating, rating) if self.max_rating else rating

    @property
    def acpl(self):
        return self.sample_total_cpl / float(self.sample_size) if self.sample_size else None

    @property
    def t3_sort(self):
        if self.t3_total == 0:
            return 0
        return -wilson_interval(self.t3_count, self.t3_total)[0]

    def asdict(self):
        return asdict(self)

    def cp_loss_count_list(self):
        return [ {"title": k, "count": self.cp_loss_count[k]} for k in cp_loss_names ]

CR_CONFIG = """
{
    "book_depth": 10,
    "forced_move_thresh": 50,
    "unclear_pos_thresh": 100,
    "undecided_pos_thresh": 200,
    "losing_pos_thresh": 500,
    "exclude_forced": true,
    "include_only_unclear": true,
    "exclude_flat": true,
    "max_cpl": 501
}
"""

# TODO: Make appropriate types for these functions.
@dataclass
class A1Report:
    by_player: DefaultDict[Player, PgnSpyResult]
    by_game: DefaultDict[Tuple[Player, str], PgnSpyResult]

    def __init__(self):
        self.by_player = defaultdict(PgnSpyResult)
        self.by_game = defaultdict(PgnSpyResult)

def generate_a1_report(working_set) -> A1Report:
    config = json.loads(CR_CONFIG)
    report = A1Report()

    working_set.update({
        gid: [Move(a) for a in analysis]
        for gid, analysis in working_set.items()
    })

    for gid, moves in working_set.items():
        def add_player_result(player, color):
            result = a1_game(gid, config, moves, color, player)
            report.by_player[player].add(result)
            report.by_game[(player, gid)].add(result)

        add_player_result(Game.objects.get(lichess_id=gid).white_player, 'w')
        add_player_result(Game.objects.get(lichess_id=gid).black_player, 'b')
    return report


def write_a1_to_txt(report: A1Report, report_name: str):
    out_path = f'report-a1--{datetime.now():%Y-%m-%d--%H-%M-%S}--{report_name}.txt'
    with open(out_path, 'w') as fout:
        fout.write('------ BY PLAYER ------\n\n')
        for player, result in sorted(report.by_player.items(), key=lambda i: i[1].t3_sort):
            fout.write(f'{player.username} ({result.min_rating} - {result.max_rating})\n')
            t_output(fout, result)
            fout.write(' '.join(result.game_list) + '\n')
            fout.write('\n')

        fout.write('\n------ BY GAME ------\n\n')
        for (player, gameid), result in sorted(report.by_game.items(), key=lambda i: i[1].t3_sort):
            fout.write(f'{player.username} ({result.min_rating})\n')
            t_output(fout, result)
            fout.write(' '.join(result.game_list) + '\n')
            fout.write('\n')
    print(f'Wrote report to "{out_path}"')

def a1_game(gid, config, moves, color, player):
    r = PgnSpyResult()
    r.game_list.append(gid)
#  moves = list(Move.select().where(Move.game == game_obj).order_by(Move.number, -Move.color))

    evals = []
    for m in moves:
        # print(f"{m.color},{m.number},{m.pv1_eval},{m.pv2_eval},{m.pv3_eval},{m.pv4_eval},{m.pv5_eval}")
        if m.color != color:
            evals.append(-m.pv1_eval)
            continue
        evals.append(m.pv1_eval)

        if m.number <= config['book_depth']:
            continue

        if m.pv1_eval <= -config['undecided_pos_thresh'] or m.pv1_eval >= config['undecided_pos_thresh']:
            continue

        if m.pv2_eval is not None and m.pv1_eval <= m.pv2_eval + config['forced_move_thresh'] and m.pv1_eval <= m.pv2_eval + config['unclear_pos_thresh']:
            if m.pv2_eval < m.pv1_eval:
                r.t1_total += 1
                if m.played_rank and m.played_rank <= 1:
                    r.t1_count += 1

            if m.pv3_eval is not None and m.pv2_eval <= m.pv3_eval + config['forced_move_thresh'] and m.pv1_eval <= m.pv3_eval + config['unclear_pos_thresh']:
                if m.pv3_eval < m.pv2_eval:
                    r.t2_total += 1
                    if m.played_rank and m.played_rank <= 2:
                        r.t2_count += 1

                if m.pv4_eval is not None and m.pv3_eval <= m.pv4_eval + config['forced_move_thresh'] and m.pv1_eval <= m.pv4_eval + config['unclear_pos_thresh']:
                    if m.pv4_eval < m.pv3_eval:
                        r.t3_total += 1
                        if m.played_rank and m.played_rank <= 3:
                            r.t3_count += 1

        cpl = min(max(m.pv1_eval - m.played_eval, 0), config['max_cpl'])
        r.cp_loss_total += 1
        for cp_name, cp_op in zip(cp_loss_names, _cp_loss_ops):
            if cp_op(cpl):
                r.cp_loss_count[cp_name] += 1

        if config['exclude_flat'] and cpl == 0 and evals[-3:] == [m.pv1_eval] * 3:
            # Exclude flat evals from CPL, e.g. dead drawn endings
            continue

        r.sample_size += 1
        r.sample_total_cpl += cpl

    return r


def t_output(fout, result):
    if result.t1_total:
        fout.write('T1: {}\n'.format(generate_stats_string(result.t1_count, result.t1_total)))
    if result.t2_total:
        fout.write('T2: {}\n'.format(generate_stats_string(result.t2_count, result.t2_total)))
    if result.t3_total:
        fout.write('T3: {}\n'.format(generate_stats_string(result.t3_count, result.t3_total)))
    if result.acpl:
        fout.write(f'ACPL: {result.acpl:.1f} ({result.sample_size})\n')
    total = result.cp_loss_total
    if total > 0:
        for cp_loss_name in cp_loss_names:
            loss_count = result.cp_loss_count[cp_loss_name]
            stats_str = generate_stats_string(loss_count, total)
            fout.write(f'  {cp_loss_name} CP loss: {stats_str}\n')


def cr_text_report(gameids, report_name: str):
    working_set = get_analysed_game_pgns_from_db(gameids)
    report = generate_a1_report(working_set)
    return write_a1_to_txt(report, report_name)
