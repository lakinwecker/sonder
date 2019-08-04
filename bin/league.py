#!/usr/bin/env python
import click
import os
import sys

sys.path.insert(0, "..")

from dotenv import load_dotenv

@click.command()
@click.option('--league', required=True, help='team4545, lonewolf')
@click.option('--season', required=True, help='number for team4545, number with or without u1800 for lonewolf')
def main(league, season):
    load_dotenv()
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sonder.settings')
    from sonder.league.utils import get_season_game_ids
    print(get_season_game_ids(league, season))

if __name__ == '__main__':
    main() # pylint: disable=no-value-for-parameter
