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
@click.option('--fishnet-version', required=True, help='The fishnet version of the analysis')
def import_cr_games(database, analysis_source, fishnet_version):
    from sonder.cr import import_cr_database
    import_cr_database(database, analysis_source, fishnet_version)



if __name__ == '__main__':
    load_dotenv()
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sonder.settings')
    django.setup()
    import_cr_games()
