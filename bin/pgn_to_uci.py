import click
import inspect
import os
import os.path
import sys
import chess.pgn
import io
from sonder.utils import pgn_to_uci

bin_dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
sys.path.insert(0, os.path.join(bin_dir, ".."))

from dotenv import load_dotenv

@click.command()
@click.option('--pgn', help='pgn to be converted to UCI moves')
def callpgn_to_uci(pgn):
    print(" ".join(pgn_to_uci(open(pgn, "r").read()))

if __name__ == '__main__':
    sys.path.insert(0, "..")
    load_dotenv()
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sonder.settings')
    callpgn_to_uci()
