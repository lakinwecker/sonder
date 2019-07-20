import chess.pgn
import io
import json
from collections import defaultdict
from sonder.analysis.models import Game, Player, GameAnalysis
from datetime import datetime
from functools import partial
from operator import eq, lt
import math

# TODO: Make this configurable via the config file.
_cp_loss_intervals = [0, 10, 25, 50, 100, 200, 500]
_cp_loss_names = ["=0"] + [f">{cp_incr}" for cp_incr in _cp_loss_intervals]
_cp_loss_ops = [partial(eq,0)] + [partial(lt, cp_incr) for cp_incr in _cp_loss_intervals]

def pgn_to_uci(pgn):
    """A method that should take a PGN string and return a list of uci moves.
    """
    pgn = io.StringIO(pgn)
    game = chess.pgn.read_game(pgn)
    moves = []
    for move in game.mainline_moves():
        moves.append(move.uci())
    return moves

def import_pgn_to_db(pgn, encoding="ISO-8859-1"):
    pgn_in = open(pgn, encoding=encoding)
    game = chess.pgn.read_game(pgn_in)
    while game:
        insert_game_into_db(game)
        game = chess.pgn.read_game(pgn_in)

def insert_game_into_db(game):
    from sonder.analysis.models import Game, Player
    w, _ = Player.objects.get_or_create(username=game.headers['White'])
    b, _ = Player.objects.get_or_create(username=game.headers['Black'])
    exporter = chess.pgn.StringExporter(headers=True, variations=False, comments=False)
    pgn_text = game.accept(exporter)
    lichess_id = game.headers['Site'][-8:]
    g, _ = Game.objects.get_or_create(
        lichess_id=lichess_id,
        defaults={
            'white_player': w,
            'black_player': b,
            'time_control': game.headers['TimeControl']
        }
    )
    g.set_pgn(pgn_text)
    g.save()

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


def get_analysed_game_pgns_from_db(gameids):
    working_set = {}
    for gameid in gameids:
        if GameAnalysis.objects.filter(game__lichess_id=gameid).exists():
            working_set[gameid] = GameAnalysis.objects.get(game__lichess_id=gameid).analysis
            #TODO: ensure all games are fully analysed here, ^ this only ensures analysis started
    return working_set

def cr_report(gameids):
    class PgnSpyResult():
        def __init__(self):
            self.sample_size = 0
            self.sample_total_cpl = 0
            self.gt0 = 0
            self.gt10 = 0
            self.t1_total = 0
            self.t1_count = 0
            self.t2_total = 0
            self.t2_count = 0
            self.t3_total = 0
            self.t3_count = 0
            self.min_rating = None
            self.max_rating = None
            self.game_list = []
            self.cp_loss_count = defaultdict(int)
            self.cp_loss_total = 0

        def add(self, other):
            self.sample_size += other.sample_size
            self.sample_total_cpl += other.sample_total_cpl
            self.gt0 += other.gt0
            self.gt10 += other.gt10
            self.t1_total += other.t1_total
            self.t1_count += other.t1_count
            self.t2_total += other.t2_total
            self.t2_count += other.t2_count
            self.t3_total += other.t3_total
            self.t3_count += other.t3_count
            self.with_rating(other.min_rating)
            self.with_rating(other.max_rating)
            self.game_list += other.game_list
            for k in _cp_loss_names:
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

    def a1(working_set, report_name):
        p = json.loads('{"book_depth": 10,"forced_move_thresh": 50,"unclear_pos_thresh": 100,"undecided_pos_thresh": 200,"losing_pos_thresh": 500,"exclude_forced": true,"include_only_unclear": true,"exclude_flat": true,"max_cpl": 501}')
        by_player = defaultdict(PgnSpyResult)
        by_game = defaultdict(PgnSpyResult)
        
        class Move:
            def __init__(self, move_analysis, next_move_analysis, move_ply):
                self.move_analysis = move_analysis
                self.next_move_analysis = next_move_analysis
                self.move_ply = move_ply

            @property
            def pv1_eval(self):
                return int(move_analysis[0]['score']['cp'])
            @property
            def pv2_eval(self):
                return int(move_analysis[1]['score']['cp'])
            @property
            def pv3_eval(self):
                return int(move_analysis[2]['score']['cp'])
            @property
            def pv4_eval(self):
                return int(move_analysis[3]['score']['cp'])
            @property
            def pv5_eval(self):
                return int(move_analysis[4]['score']['cp'])
            @property
            def played_eval(self):
                try:
                    return int(next_move_analysis[0]['score']['cp'])
                except TypeError:
                    return 0
                #Look up which move they played, if it's in the pv list then use that eval, if not, look at the pv[0] from the next move
            @property
            def played_rank(self):
                for i, pv_eval in enumerate([self.pv1_eval, self.pv2_eval, self.pv3_eval, self.pv4_eval, self.pv5_eval]):
                    if pv_eval == self.played_eval:
                        return i+1
                    else:
                        return 6
                #Look up which move they played, if it's in the pv list us it, if it's not there, use len(pvs)+1
            @property
            def color(self):
                if self.move_ply % 2 == 0:
                    return 'w'
                else:
                    return 'b'
            @property
            def number(self):
                return (self.move_ply+2)//2

        for gid, analysis in working_set.items():
            moves = []
            for i in range(len(analysis)):
                move_ply = i
                move_analysis = analysis[i]
                try:
                    next_move_analysis = analysis[i+1]
                except IndexError:
                    next_move_analysis = None
                moves.append(Move(move_analysis, next_move_analysis, move_ply))
                #print(gid, Move(move_analysis).pv1_eval)
            working_set[gid] = moves


        for gid, moves in working_set.items():

            a1_game(gid, p, by_player, by_game, moves, 'w', Game.objects.get(lichess_id=gid).white_player)
            a1_game(gid, p, by_player, by_game, moves, 'b', Game.objects.get(lichess_id=gid).black_player)

        out_path = f'report-a1--{datetime.now():%Y-%m-%d--%H-%M-%S}--{report_name}.txt'
        with open(out_path, 'w') as fout:
            fout.write('------ BY PLAYER ------\n\n')
            for player, result in sorted(by_player.items(), key=lambda i: i[1].t3_sort):
                fout.write(f'{player.username} ({result.min_rating} - {result.max_rating})\n')
                t_output(fout, result)
                fout.write(' '.join(result.game_list) + '\n')
                fout.write('\n')

            fout.write('\n------ BY GAME ------\n\n')
            for (player, gameid), result in sorted(by_game.items(), key=lambda i: i[1].t3_sort):
                fout.write(f'{player.username} ({result.min_rating})\n')
                t_output(fout, result)
                fout.write(' '.join(result.game_list) + '\n')
                fout.write('\n')
        print(f'Wrote report on x games to "{out_path}"')

    def a1_game(gid, p, by_player, by_game, analysis, color, player):
        class Move():
            def __init__(self, game, color, number, pv1_eval, pv2_eval, pv3_eval, pv4_eval, pv5_eval, played_eval, played_rank, nodes):
                self.game = game
                self.color = color
                self.number = number
                self.pv1_eval = pv1_eval
                self.pv2_eval = pv2_eval
                self.pv3_eval = pv3_eval
                self.pv4_eval = pv4_eval
                self.pv5_eval = pv5_eval
                self.played_eval = played_eval
                self.played_rank = played_rank
                self.nodes = nodes
        moves = []
        for n, move in enumerate(analysis):
            move_color = "w" if n%2==0 else "b"
            Move(gid, move_color, n//2,\
             move[0]['score']['cp'],\
             move[1]['score']['cp'],\
             move[2]['score']['cp'],\
             move[3]['score']['cp'],\
             move[4]['score']['cp'],\
             )

"""Move.create(game=game_obj, color=color, number=board.fullmove_number, \
pv1_eval=evals.get(1), pv2_eval=evals.get(2), pv3_eval=evals.get(3), \
pv4_eval=evals.get(4), pv5_eval=evals.get(5), \
played_rank=played_index, played_eval=played_eval

[{'pv': '', 'nodes': '4501294', 'score': {'cp': '76', 'mate': None}}, {'pv': '', 'nodes': '4501294', 'score': {'cp': '46', 'mate': None}}, {'pv': '', 'nodes': '4501294', 'score': {'cp': '46', 'mate': None}}, {'pv': '', 'nodes': '4501294', 'score': {'cp': '38', 'mate': None}}, {'pv': '', 'nodes': '4501294', 'score': {'cp': '39', 'mate': None}}]
            """

        r = PgnSpyResult()
        r.game_list.append(gid)
      #  moves = list(Move.select().where(Move.game == game_obj).order_by(Move.number, -Move.color))

        evals = []
        for m in moves:
            #print(m.pv1_eval)
            if m.color != color:
                evals.append(-m.pv1_eval)
                continue
            evals.append(m.pv1_eval)

            if m.number <= p['book_depth']:
                continue

            if m.pv1_eval <= -p['undecided_pos_thresh'] or m.pv1_eval >= p['undecided_pos_thresh']:
                continue

            if m.pv2_eval is not None and m.pv1_eval <= m.pv2_eval + p['forced_move_thresh'] and m.pv1_eval <= m.pv2_eval + p['unclear_pos_thresh']:
                if m.pv2_eval < m.pv1_eval:
                    r.t1_total += 1
                    if m.played_rank and m.played_rank <= 1:
                        r.t1_count += 1

                if m.pv3_eval is not None and m.pv2_eval <= m.pv3_eval + p['forced_move_thresh'] and m.pv1_eval <= m.pv3_eval + p['unclear_pos_thresh']:
                    if m.pv3_eval < m.pv2_eval:
                        r.t2_total += 1
                        if m.played_rank and m.played_rank <= 2:
                            r.t2_count += 1

                    if m.pv4_eval is not None and m.pv3_eval <= m.pv4_eval + p['forced_move_thresh'] and m.pv1_eval <= m.pv4_eval + p['unclear_pos_thresh']:
                        if m.pv4_eval < m.pv3_eval:
                            r.t3_total += 1
                            if m.played_rank and m.played_rank <= 3:
                                r.t3_count += 1

            cpl = min(max(m.pv1_eval - m.played_eval, 0), p['max_cpl'])
            r.cp_loss_total += 1
            for cp_name, cp_op in zip(_cp_loss_names, _cp_loss_ops):
                if cp_op(cpl):
                    r.cp_loss_count[cp_name] += 1

            if p['exclude_flat'] and cpl == 0 and evals[-3:] == [m.pv1_eval] * 3:
                # Exclude flat evals from CPL, e.g. dead drawn endings
                continue

            r.sample_size += 1
            r.sample_total_cpl += cpl
            if cpl > 0:
                r.gt0 += 1
            if cpl > 10:
                r.gt10 += 1

        by_player[player].add(r)
        by_game[(player, gid)].add(r)

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
            for cp_loss_name in _cp_loss_names:
                loss_count = result.cp_loss_count[cp_loss_name]
                stats_str = generate_stats_string(loss_count, total)
                fout.write(f'  {cp_loss_name} CP loss: {stats_str}\n')

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
    
    working_set = get_analysed_game_pgns_from_db(gameids)
    a1(working_set, "test")
