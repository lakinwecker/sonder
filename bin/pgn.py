#!/usr/bin/env python
import click
import inspect
import os
import os.path
import sys

bin_dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
sys.path.insert(0, os.path.join(bin_dir, ".."))

from dotenv import load_dotenv

@click.command()
@click.option('--gameids', help='List of Lichess game IDs', multiple='true')
def main(gameids):
    sys.path.insert(0, "..")
    load_dotenv()
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sonder.settings')
    from sonder.league.utils import get_game_pgns
    print(get_game_pgns(gameids))

if __name__ == '__main__':
    main()
