#!/usr/bin/env python
import click
import inspect
import os
import os.path
import sys
import django
import chess.pgn
import io

bin_dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
sys.path.insert(0, os.path.join(bin_dir, ".."))

from dotenv import load_dotenv

@click.command()
@click.option('--pgn', required=True, help='The pgn of game(s) to be added to database')
def import_pgn_to_db(pgn):
    pgn_in = open(pgn)
    while True:
        game = chess.pgn.read_game(pgn_in)
        if game is None:
            break
        into_db(game)

def into_db(game):
    from sonder.analysis.models import Game, Player
    w, _ = Player.objects.get_or_create(username=game.headers['White'])
    b, _ = Player.objects.get_or_create(username=game.headers['Black'])
    exporter = chess.pgn.StringExporter(headers=True, variations=False, comments=False)
    pgn_text = game.accept(exporter)
    g = Game(
        lichess_id = game.headers['Site'][-8:],
        white_player = w,
        black_player = b,
        time_control = game.headers['TimeControl'])
    g.set_pgn(pgn_text)
    g.save()



if __name__ == '__main__':
    load_dotenv()
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sonder.settings')
    django.setup()
    import_pgn_to_db()
