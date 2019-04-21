import click
import inspect
import os
import os.path
import sys
import chess.pgn
import io

bin_dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
sys.path.insert(0, os.path.join(bin_dir, ".."))

from dotenv import load_dotenv

@click.command()
@click.option('--pgn', help='pgn to be converted to UCI moves')
def callpgn_to_uci(pgn):
    print(pgn_to_uci(pgn))

def pgn_to_uci(pgn):
    pgn_in = open(pgn)
    game = chess.pgn.read_game(pgn_in)
    moves = []
    for move in game.mainline_moves():
        moves.append(move.uci())
    return " ".join(moves)

if __name__ == '__main__':
    sys.path.insert(0, "..")
    load_dotenv()
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sonder.settings')
    callpgn_to_uci()