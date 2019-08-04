from collections import defaultdict
import subprocess
import tempfile
import crayons
from tqdm import tqdm

from sonder.analysis.models import (
    AnalysisSource,
    Player,
    Game,
    GameAnalysis,
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
    else:
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
        print(crayons.green("✓ Players Loaded"))

        players_by_lichess_game_id = defaultdict(lambda: dict((("w", None), ("b", None))))
        def process_gameplayer(_, lichess_id, color, player_id):
            player = players_by_old_id[player_id]
            players_by_lichess_game_id[lichess_id][color] = player
        process_csv("Loading Game Players", f"{base_dir}/gameplayer.csv", process_gameplayer)
        print(crayons.green("✓ GamePlayers Loaded"))

        game_analysis_completed = {}
        def process_game(game_id, completed):
            completed = completed == "1"
            game, _ = Game.objects.get_or_create(lichess_id=game_id.strip())
            players = players_by_lichess_game_id.get(game_id)
            if players:
                if not players['w'] or not players['b']:
                    raise AssertionError("Missing players")
                game.white_player = players['w']
                game.black_player = players['b']
                game.save()
            game_analysis_completed[game.lichess_id] = completed
        process_csv("Loading Games", f"{base_dir}/game.csv", process_game)
        print(crayons.green("✓ Games Loaded"))

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
        print(crayons.green("✓ Moves Loaded"))

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
                move_analysis["cr"].update({
                    "played_eval": cr_move_analysis['played_eval'],
                    "played_rank": cr_move_analysis['played_rank'],
                    "nodes": cr_move_analysis["nodes"],
                    "masterdb_matches": cr_move_analysis['masterdb_matches'],
                })

                def add_pv(name):
                    move_analysis["pvs"].append({
                        "pv": "",
                        "score": { "cp": cr_move_analysis[name], "mate": None },
                    })
                add_pv("pv1_eval")
                add_pv("pv2_eval")
                add_pv("pv3_eval")
                add_pv("pv4_eval")
                add_pv("pv5_eval")

            game_analysis.analysis = sonder_analysis
            game_analysis.save()
        progress.close()
        print(crayons.green("✓ Analysis processed"))








