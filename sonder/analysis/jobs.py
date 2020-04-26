"""
Some background jobs.
"""
from .models import Player
from tqdm import tqdm


def update_all_games_reports(progress=False):
    qs = Player.objects.all()
    if progress:
        qs = tqdm(qs)
    for player in qs:
        player.update_full_report()
