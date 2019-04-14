import click
import os
import urllib.request, urllib.parse, urllib.error
import re

from dotenv import load_dotenv


@click.command()
@click.option('--league', required=True, help='team4545, lonewolf')
@click.option('--season', required=True, help='number for team4545, number with or without u1800 for lonewolf')

def callgameList(league, season):
    print(gameList(league, season))

def gameList(league, season):
    """build list of gameIDs from the round(s) by scraping lichess4545.com website"""
    gameIDs = [1]
    for roundnum in range(1,12):
        try:
            connection = urllib.request.urlopen(f'https://www.lichess4545.com/{league}/season/{season}/round/{roundnum}/pairings/')
        except urllib.error.URLError as e:
            if hasattr(e, 'reason'):
                print('Request failed.')
                print('Reason: ', e.reason)
            if hasattr(e, 'code'):
                print('Error code: ', e.code)
        response = connection.read().decode('utf-8')
        links = re.findall(r'en\.lichess\.org\/([\w]+)', response)
        gameIDs.extend(links)
    return gameIDs

if __name__ == '__main__':
    load_dotenv()
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sonder.settings')
    callgameList()