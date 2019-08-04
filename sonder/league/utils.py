import requests
import re

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
    print(body)
    url = 'https://lichess.org/games/export/_ids'
    response = requests.post(url, headers=headers, data=body)
    return response.text.split("\n\n\n")
