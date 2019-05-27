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
@click.option('--gameids', required=True, help='The games to include in the report as a whitespace separated string of lichess game IDs')

def main(gameids):
    load_dotenv()
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sonder.settings')
    django.setup()
    from sonder.utils import cr_report
    cr_report(gameids.split())

if __name__ == '__main__':
    main()
