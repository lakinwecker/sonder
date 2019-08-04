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
@click.option('--database', required=True, help='The sqlite database to import')
@click.option('--analysis-source', required=True, help='Name of the analysis source')
@click.option('--stockfish-version', required=True, help='The stockfish version of the analysis')
def main(database, analysis_source, stockfish_version):
    load_dotenv()
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sonder.settings')
    django.setup()
    from sonder.cr import import_cr_database
    import_cr_database(database, analysis_source, stockfish_version)

if __name__ == '__main__':
    main() # pylint: disable=no-value-for-parameter
