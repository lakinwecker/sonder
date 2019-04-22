#!/usr/bin/env python
import click
import inspect
import os
import os.path
import sys
import django

bin_dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
sys.path.insert(0, os.path.join(bin_dir, ".."))

from dotenv import load_dotenv

@click.command()
@click.option('--pgn', required=True, help='The pgn of game(s) to be added to database')
def main(pgn):
    load_dotenv()
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sonder.settings')
    django.setup()
    from sonder.utils import import_pgn_to_db
    import_pgn_to_db(pgn)

if __name__ == '__main__':
    main()
