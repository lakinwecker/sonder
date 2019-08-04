import click
import requests
import re
from itertools import product
import io
import time

from tqdm import tqdm
from   ..utils import import_pgn_to_db
from ..analysis.models import Game, Tag, GameTag

def get_season_game_ids(league, season, rounds=None):
    """build list of game_ids from the round(s) by scraping lichess4545.com website"""
    if rounds is None:
        rounds = range(1, 12)
    results = []
    for roundnum in rounds:
        url = f'https://www.lichess4545.com/{league}/season/{season}/round/{roundnum}/pairings/'
        response = requests.get(url)
        ids = re.findall(r'en\.lichess\.org\/([\w]+)', response.content.decode("utf-8"))
        results.extend([(league, season, roundnum, id) for id in ids])
    return results


def get_game_pgns(game_ids):
    """get game data from games listed in gameIDs using lichess.org API"""
    headers = {'Accept' : 'application/vnd.lichess.v3+json', 'content-type': 'text/plain'}
    body = ",".join(game_ids)
    url = 'https://lichess.org/games/export/_ids'
    response = requests.post(url, headers=headers, data=body)
    if response.status_code == 429:
        time.sleep(120)
        response = requests.post(url, headers=headers, data=body)
    return [
        pgn for pgn in
        [part.strip() for part in response.text.split('\n\n\n')]
        if pgn
    ]

def get_season_ids_for_league(league):
    # They all have a season 2, lonewolf doesn't have a season 1. :'(
    url = f"https://www.lichess4545.com/{league}/season/2/summary/"
    response = requests.get(url)
    ids = re.findall(rf'{league}/season/([\w]+)/summary', response.content.decode("utf-8"))
    return ids

def chunks(l, n):
    """Yield successive n-sized chunks from l."""
    for i in range(0, len(l), n):
        yield l[i:i + n]

def download_new_games(league, _season=None):
    seasons = [_season]
    if not _season:
        seasons = get_season_ids_for_league(league)
    rounds = range(1, 12)

    league_tag, _ = Tag.objects.get_or_create(name=league)
    games_to_download = []
    for season, _round in tqdm(list(product(seasons, rounds)), f"Downloading pairing games", leave=False):
        season_tag, _ = Tag.objects.get_or_create(name=season)
        for _, _, _, game_id in get_season_game_ids(league, season, rounds=[_round]):
            game, created = Game.objects.get_or_create(lichess_id=game_id)
            GameTag.objects.get_or_create(game=game, tag=league_tag)
            GameTag.objects.get_or_create(game=game, tag=season_tag)
            if created or game.source_pgn.strip():
                continue
            games_to_download.append(game_id)
    click.secho(f"✓ Found {len(games_to_download)} new games", fg='green')

    pgns = []
    for game_ids in tqdm(list(chunks(games_to_download, 300)), "Downloading PGNs (300/request)", leave=False):
        pgns.extend(get_game_pgns(game_ids))
    click.secho(f"✓ Downloaded {len(pgns)} games pgns", fg='green')

    for pgn in tqdm(pgns, "Processing PGNs", leave=False):
        import_pgn_to_db(io.StringIO(pgn))
    click.secho(f"✓ Imported {len(pgns)} games pgns", fg='green')
