import click
import os
import requests
import json
import time

from dotenv import load_dotenv

@click.command()
@click.option('--gameids', help='List of Lichess game IDs')

def callgetGames(gameids):
    print(getGames(gameids))

def getGames(gameids):
	headers = {'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:64.0) Gecko/20100101 Firefox/64.0', b'Accept': 'application/vnd.lichess.v3+json'}
	response = requests.get('https://lichess.org/game/export/15Dupv9q', headers=headers)
	print(response)
	game = json.loads(response.text)
	print(game)
'''
def getGames(gameids):
    """get game data from games listed in gameIDs using lichess.org API"""
    headers = {'Accept' : 'application/vnd.lichess.v3+json'}
    games = {}
    for num, gameid in enumerate(gameids):
        response = requests.get(f'https://lichess.org/game/export/{gameid}', headers=headers)
        print(response.text)
        games[gameid] = json.loads(response.text)
        time.sleep(1) # wait to prevent server overload
        print("got game", num)
    return games
'''

if __name__ == '__main__':
    load_dotenv()
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sonder.settings')
    callgetGames()