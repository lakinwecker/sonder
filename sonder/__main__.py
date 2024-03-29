#!/usr/bin/env python
import inspect

import itertools
import os
import os.path
import random
import sys

import click
import django

from dotenv import load_dotenv

load_dotenv()
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "sonder.settings")
django.setup()

# pylint: disable=locally-disabled, wrong-import-position
from django.db.models import Q

from django.contrib.auth.models import User

from sonder import utils
from sonder.analysis.models import Player, Game
from sonder.league.utils import download_new_games
from sonder.league.utils import get_season_ids_for_league
from sonder.league.utils import get_game_pgns
from sonder.cr import import_cr_database
from sonder.cr import cr_text_report
from sonder.analysis.models import (
    IrwinReport,
    IrwinReportOrigin,
    IrwinReportRequiredGame,
    GameAnalysis,
    import_pgn_file_to_db,
    import_pgn_to_db,
)
from sonder.analysis.jobs import update_all_games_reports

BIN_DIR = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
sys.path.insert(0, os.path.join(BIN_DIR, ".."))


@click.group()
def cli():
    load_dotenv()
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "sonder.settings")
    django.setup()


# -------------------------------------------------------------------------------
# PGN Commands
# -------------------------------------------------------------------------------
@cli.group()
def pgn():
    pass


@pgn.command(name="import")
@click.option("--pgn", required=True, help="The pgn of game(s) to be added to database")
@click.option(
    "--encoding", default="ISO-8859-1", required=False, help="Encoding of the file"
)
def pgn_import(pgn, encoding):
    import_pgn_file_to_db(pgn, encoding=encoding)


@pgn.command(name="to_uci")
@click.option("--pgn", required=True, help="pgn to be converted to UCI moves")
def pgn_to_uci(pgn):
    print(" ".join(utils.pgn_to_uci(open(pgn, "r").read())))


@pgn.command(name="export")
@click.option("--player", help="Player we are interested in")
@click.option("--time_control", help="TimeControl to export")
def pgn_export(player=None, time_control=None):
    qs = Game.objects.exclude(source_pgn="")
    if player:
        try:
            username = Player.normalize_username(player)
            player = Player.objects.get(username=username)
        except Player.DoesNotExist:
            print(f"Unable to find player: {player}")
            sys.exit()
        qs = qs.filter(Q(white_player=player) | Q(black_player=player))
    if time_control:
        qs = qs.filter(time_control=time_control)
    for game in qs:
        print(f"""{game.source_pgn}\n\n\n""")


# -------------------------------------------------------------------------------
# League Commands
# -------------------------------------------------------------------------------
@cli.group()
def league():
    pass


@league.command(name="download-games")
@click.option("--league", required=True, help="team4545, lonewolf")
@click.option(
    "--season", help="number for team4545, number with or without u1800 for lonewolf"
)
def league_download_games(league, season=None):
    download_new_games(league, season)


@league.command(name="get-season-ids")
@click.option("--league", required=True, help="team4545, lonewolf")
def league_get_season_ids(league):
    print(get_season_ids_for_league(league))


# -------------------------------------------------------------------------------
# Lichess Commands
# -------------------------------------------------------------------------------
@cli.group()
def lichess():
    pass


@lichess.command(name="download-games")
@click.option(
    "--gameids", required=True, help="List of Lichess game IDs", multiple="true"
)
def lichess_download_games(gameids):
    for pgn in get_game_pgns(gameids):
        import_pgn_to_db(pgn)


# -------------------------------------------------------------------------------
# Lichess Commands
# -------------------------------------------------------------------------------
@cli.group()
def cr():
    pass


@cr.command(name="import")
@click.option("--database", required=True, help="The sqlite database to import")
@click.option("--analysis-source", required=True, help="Name of the analysis source")
@click.option(
    "--stockfish-version", required=True, help="The stockfish version of the analysis"
)
def cr_import(database, analysis_source, stockfish_version):
    import_cr_database(database, analysis_source, stockfish_version)


@cr.command(name="report")
@click.option(
    "--gameids",
    required=True,
    help="The games to include in the report as a whitespace separated string of lichess game IDs",
)
@click.option("--name", required=True, help="The name of the report")
def cr_txt_report(gameids, name):
    cr_text_report(gameids.split(), name)


@cr.command(name="game-cps-debug")
@click.option(
    "--gameids",
    required=True,
    help="The games to include in the report as a whitespace separated string of lichess game IDs",
)
def cr_game_cps_debug(gameids):
    """Simple tool to debug game cps. Compare this output to the output of the following commands run in a cr database:

    sqlite> .mode csv
    sqlite> .out moves.csv
    sqlite> SELECT color, number, pv1_eval, pv2_eval, pv3_eval, pv4_eval, pv5_eval FROM move WHERE game_id='{game_id}' ORDER BY number ASC, color DESC;

    """
    for game_id in gameids.split():
        ga = GameAnalysis.objects.get(game__lichess_id=game_id)
        colors = itertools.cycle(["w", "b"])
        for color, move, a in zip(colors, range(1024), ga.analysis):
            s = [pov["score"]["cp"] for pov in a["pvs"]]
            if move % 2 == 1:
                move = move - 1
            move = (move // 2) + 1
            print(f"{color},{move},{s[0]},{s[1]},{s[2]},{s[3]},{s[4]}")


# -------------------------------------------------------------------------------
# Jobs commands
# -------------------------------------------------------------------------------
@cli.group()
def jobs():
    pass


@jobs.command(name="update_all_games")
def jobs_update_all_games():
    update_all_games_reports(progress=True)


# -------------------------------------------------------------------------------
# Development related commands
# -------------------------------------------------------------------------------
@cli.group()
def development():
    pass


@development.command()
@click.option("--source", required=True, help="The source of the requests")
@click.option("--player", required=True, help="The target of the requests")
@click.option("--number", default=20, help="The number of games to require")
def create_test_irwin_jobs(source, player, number):
    try:
        player = Player.objects.get(username=player)
    except Player.DoesNotExist:
        click.secho(f"Unable to find player: {player}")

    try:
        moderator = User.objects.get(username=source)
    except User.DoesNotExist:
        click.secho(f"Unable to find source: {source}")

    precedence = random.randrange(1, 10000)

    report, _ = IrwinReport.objects.get_or_create(
        player=player, completed=False, precedence=precedence,
    )
    IrwinReportOrigin.objects.get_or_create(
        report=report,
        source=IrwinReportOrigin.SOURCE_CHOICES.MODERATOR,
        moderator=moderator,
        precedence=precedence,
    )
    games = Game.objects.filter(Q(white_player=player) | Q(black_player=player))[:number]
    for g in games:
        IrwinReportRequiredGame.objects.get_or_create(
            irwin_report=report,
            game=g,
            completed=False,
            owner=None
        )


if __name__ == "__main__":
    cli()
