import click
import inspect
import os
import os.path
import sys
import django

bin_dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
sys.path.insert(0, os.path.join(bin_dir, ".."))

from dotenv import load_dotenv

@click.group()
def cli():
    load_dotenv()
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sonder.settings')
    django.setup()


@cli.command()
@click.option('--database', required=True, help='The sqlite database to import')
@click.option('--analysis-source', required=True, help='Name of the analysis source')
@click.option('--stockfish-version', required=True, help='The stockfish version of the analysis')
def importchessreanalysis(database, analysis_source, stockfish_version):
    from sonder.cr import import_cr_database
    import_cr_database(database, analysis_source, stockfish_version)



@cli.command()
@click.option('--pgn', required=True, help='The pgn of game(s) to be added to database')
@click.option('--encoding', default="ISO-8859-1", required=False, help='Encoding of the file')
def importpgn(pgn, encoding):
    from sonder.utils import import_pgn_to_db
    import_pgn_to_db(pgn, encoding=encoding)

@cli.command()
@click.option('--league', required=True, help='team4545, lonewolf')
@click.option('--season', required=True, help='number for team4545, number with or without u1800 for lonewolf')
def get4545season(league, season):
    from sonder.league.utils import get_season_game_ids
    print(get_season_game_ids(league, season))

@cli.command()
@click.option('--gameids', required=True, help='List of Lichess game IDs', multiple='true')
def getpgns(gameids):
    from sonder.league.utils import get_game_pgns
    print(get_game_pgns(gameids))

@cli.command()
@click.option('--pgn', required=True, help='pgn to be converted to UCI moves')
def pgntouci(pgn):
    from sonder.utils import pgn_to_uci
    print(" ".join(pgn_to_uci(open(pgn, "r").read())))


if __name__ == '__main__':
    cli()
