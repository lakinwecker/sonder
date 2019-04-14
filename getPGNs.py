import click
import os
import requests
import json

from dotenv import load_dotenv

@click.command()
@click.option('--gameids', help='List of Lichess game IDs')

def getGames(gameids):
    """get game data from games listed in gameIDs using lichess.org API"""
    games = {}
    for num, gameid in enumerate(gameids):
        response = requests.get(f'https://lichess.org/game/export/{gameid}')
        print(response.text)
        games[gameid] = json.loads(response.text)
        time.sleep(1) # wait to prevent server overload
        print("got game", num)
    return games


if __name__ == '__main__':
    load_dotenv()
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sonder.settings')
    getGames()