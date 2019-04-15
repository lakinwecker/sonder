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

def import_cr_database(database, analysis_source, fishnet_version):
    with tempfile.TemporaryDirectory() as base_dir:
        lines = cr_export_sql_template.format(base_dir=base_dir)
        sqlite3 = subprocess.Popen(["sqlite3", database], stdin=subprocess.PIPE)
        sqlite3.communicate(bytes(lines, "utf-8"))
        players_by_old_id = {}
        with open(f"{base_dir}/player.csv", "r") as player_fd:
            for line in player_fd.readlines():
                _id, username = line.strip().split(",")
                player, _ = Player.objects.get_or_create(username=username.strip())
                players_by_old_id[_id] = player

        game_players = {}
        with open(f"{base_dir}/gameplayer.csv", "r") as player_fd:
            for line in player_fd.readlines():
                _id, lichess_id, color, player_id = line.strip().split(",")
                player = players_by_old_id[player_id]
                game_players.setdefault(lichess_id, {"w": None, "b": None})[color] = player

        game_analysis_completed = {}
        with open(f"{base_dir}/game.csv", "r") as player_fd:
            for line in player_fd.readlines():
                game_id, completed = line.strip().split(",")
                completed = completed == "1"
                game, _ = Game.objects.get_or_create(lichess_id=game_id.strip())
                players = game_players.get(game_id)
                if players:
                    game.white_player = players['w']
                    game.black_player = players['b']
                    game.save()
                game_analysis_completed[game.lichess_id] = completed




