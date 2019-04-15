import click
import inspect
import os
import os.path
import sys
bin_dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
sys.path.insert(0, os.path.join(bin_dir, ".."))

from dotenv import load_dotenv

from sonder.league.utils import get_game_pgns

@click.command()
@click.option('--gameids', help='List of Lichess game IDs', multiple='true')
def callgetGames(gameids):
    print(get_game_pgns(gameids))


if __name__ == '__main__':
    sys.path.insert(0, "..")
    load_dotenv()
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sonder.settings')
    callgetGames()
