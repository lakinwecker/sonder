from collections import defaultdict
import subprocess
import tempfile

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

def import_cr_database(database, analysis_source, stockfish_version):
    with tempfile.TemporaryDirectory() as base_dir:
        # Export the tables that we need
        lines = cr_export_sql_template.format(base_dir=base_dir)
        sqlite3 = subprocess.Popen(["sqlite3", database], stdin=subprocess.PIPE)
        sqlite3.communicate(bytes(lines, "utf-8"))

        # Load the player table and insert all players and store
        # a mapping of id to player
        players_by_old_id = {}
        with open(f"{base_dir}/player.csv", "r") as player_fd:
            for line in player_fd.readlines():
                _id, username = line.strip().split(",")
                player, _ = Player.objects.get_or_create(username=username.strip())
                players_by_old_id[_id] = player

        game_players = defaultdict(lambda: dict((("w", None), ("b", None))))
        with open(f"{base_dir}/gameplayer.csv", "r") as gameplayer_fd:
            for line in gameplayer_fd.readlines():
                _id, lichess_id, color, player_id = line.strip().split(",")
                player = players_by_old_id[player_id]
                game_players[lichess_id][color] = player

        game_analysis_completed = {}
        with open(f"{base_dir}/game.csv", "r") as game_fd:
            for line in game_fd.readlines():
                game_id, completed = line.strip().split(",")
                completed = completed == "1"
                game, _ = Game.objects.get_or_create(lichess_id=game_id.strip())
                players = game_players.get(game_id)
                if players:
                    assert players['w']
                    assert players['b']
                    game.white_player = players['w']
                    game.black_player = players['b']
                    game.save()
                game_analysis_completed[game.lichess_id] = completed

        game_analysis = defaultdict(lambda: defaultdict(dict))
        with open(f"{base_dir}/move.csv", "r") as moves_fd:
            for line in moves_fd.readlines():
                parts = line.strip().split(",")
                _,game_id,color,number,pv1_eval,pv2_eval,pv3_eval,pv4_eval,pv5_eval,_,_,nodes,masterdb_matches = parts
                analysis = game_analysis[game_id]
                analysis[number].update({
                    'color': color,
                    'pv1_eval': pv1_eval,
                    'pv2_eval': pv2_eval,
                    'pv3_eval': pv3_eval,
                    'pv4_eval': pv4_eval,
                    'pv5_eval': pv5_eval,
                    #  TODO: I believe these should be extracted from the next move eval
                    # 'played_eval': played_eval,
                    # 'played_rank': played_rank,
                    'nodes': nodes,
                    'masterdb_matches': masterdb_matches,
                })

        analysis_source, _ = AnalysisSource.objects.get_or_create(name=analysis_source)
        for game_id, cr_analysis in game_analysis.items():
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
            cr_analysis  = [(int(k), v) for k,v in cr_analysis.items()]
            moves = list(sorted(cr_analysis))
            last_move_number, _ = moves[-1]
            sonder_analysis = [[] for x in range(last_move_number)]
            for move_number, move_analysis in moves:
                move_index = move_number-1
                eval_keys = [f"pv{i}_eval" for i in range(1, 6)]
                for key in eval_keys:
                    sonder_analysis[move_index].append({
                        "pv": "",
                        #"seldepth": 24
                        #"tbhits": 0,
                        #"depths": 18,
                        "score": {
                            "cp": move_analysis[key],
                            "mate": None
                        },
                        # "time": 0
                        "nodes": move_analysis["nodes"],
                        #"nps": ??
                        #"masterdb_matches": ??
                    })
            game_analysis.analysis = sonder_analysis
            game_analysis.save()








