from django.db import models, transaction
from django.contrib.postgres.fields import JSONField
from django.utils.crypto import get_random_string
from django.contrib.auth.models import User

def create_api_token():
    return get_random_string(length=12)

class AnalysisSource(models.Model):
    name = models.CharField(max_length=255, unique=True)
    secret_token = models.CharField(max_length=12, unique=True, default=create_api_token)
    use_for_irwin = models.BooleanField(default=False)
    use_for_mods = models.BooleanField(default=False)
    enabled = models.BooleanField(default=False)

    date_created = models.DateTimeField(auto_now_add=True)
    date_modified = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

class Tag(models.Model):
    name = models.CharField(max_length=255, unique=True)


class Player(models.Model):
    username = models.CharField(max_length=255, unique=True)

    @classmethod
    def normalize_username(cls, username):
        if not username:
            return username
        return username.strip().lower()

    def __str__(self):
        return self.username

class Game(models.Model):
    lichess_id = models.CharField(max_length=32, unique=True)
    white_player = models.ForeignKey(
        Player,
        on_delete=models.CASCADE,
        related_name='games_as_white',
    )
    black_player = models.ForeignKey(
        Player,
        on_delete=models.CASCADE,
        related_name='games_as_black',
    )
    time_control = models.CharField(max_length=8, default='')

    # Storing the source PGN in case we want more information from
    # it later.
    source_pgn = models.TextField(default='')

    # list of uci moves
    moves = JSONField(null=True)
    # list of integers representing the emts from lila
    moves_emt = JSONField(null=True)
    # list of booleans representing the blur indication from lila
    moves_blur = JSONField(null=True)
    # list of ints representing the number of times masters have
    # played this move
    moves_masterdb_matches = JSONField(null=True)

    def set_pgn(self, pgn):
        from sonder.utils import pgn_to_uci
        self.source_pgn = pgn
        self.moves = pgn_to_uci(self.source_pgn)

class GameTag(models.Model):
    game = models.ForeignKey(Game, on_delete=models.CASCADE)
    tag = models.ForeignKey(Tag, on_delete=models.CASCADE)


colors = (('w', 'White'), ('b', 'Black'))

class GameAnalysis(models.Model):
    game = models.ForeignKey(Game, on_delete=models.CASCADE)
    source = models.ForeignKey(AnalysisSource, on_delete=models.CASCADE)
    stockfish_version = models.CharField(max_length=8)
    is_completed = models.BooleanField(default=False)

    # A list of position analysis where each position
    # has a list of PVs.
    # The position will be:
    # {
    #   'move': 1,
    #   'pvs': [],
    #   "cr": { # possibly empty  if the source of analysis is no CR
    #     "played_rank": 1, # the rank of the move they played
    #     "played_eval": 1, # the rank of the move they played
    #     "masterdb_matches": 45 # number of times position appears in masters db from CR
    #   }
    #   "time": 1004, # time spent processing
    #   "nodes": 1686023, # nodes processed
    #   "nps": 1670251, # nodes-per-second
    # }
    # pvs may be empty if no analysis was done.
    # Each pv is of the form:
    # {
    #   "pv": "e2e4 e7e5 g1f3 g8f6", # principle variation if provided
    #   "seldepth": 24, # TODO: Figure what what this is
    #   "tbhits": 0, # tablebase hits?
    #   "depth": 18, # depth reached
    #   "score": {
    #     "cp": 24, # cp eval
    #     "mate": None # number of moves until mate
    #   },
    # },
    analysis = JSONField()

    class Meta:
        index_together = [
            ['game', 'source']
        ]


class IrwinReport(models.Model):
    player = models.ForeignKey(
        Player,
        null=True,
        on_delete=models.SET_NULL,
    )
    completed = models.BooleanField(default=False)
    origin = models.CharField(max_length=32)

    precedence = models.PositiveIntegerField()

    date_created = models.DateTimeField(auto_now_add=True)
    date_modified = models.DateTimeField(auto_now=True)


class IrwinReportRequiredGame(models.Model):
    irwin_report = models.ForeignKey(IrwinReport, on_delete=models.CASCADE)
    game = models.ForeignKey(Game, null=True, on_delete=models.SET_NULL)
    completed = models.BooleanField()
    owner = models.ForeignKey(AnalysisSource, null=True, on_delete=models.SET_NULL)

    def job(self):
        return {
            "work": {
                "type": "analysis",
                "id": f"irwin-{self.id}",
            },
            "game_id": f"{self.game.lichess_id}",
            "position": "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
            "variant": "standard",
            "nodes": None,
            "skipPositions": list(range(10)),
            "moves": self.game.moves,
        }

    @classmethod
    def assign_game(cls, source):
        games = cls.objects.select_for_update().filter(
                owner__isnull=True,
                completed=False
            ).order_by(
                '-irwin_report__precedence',
                'irwin_report__date_modified'
            )
        with transaction.atomic():
            try:
                game = games[0]
                game.owner = source
                game.save()
                return game
            except IndexError:
                pass
        return None


class Criteria(models.Model):
    num_games = models.PositiveIntegerField()
    tags = models.ManyToManyField(Tag)


class CRReport(models.Model):
    player = models.ForeignKey(
        Player,
        null=True,
        on_delete=models.CASCADE,
    )
    name = models.CharField(max_length=255, default="")

    criteria = models.ForeignKey(Criteria, blank=True, null=True, on_delete=models.CASCADE)
    completed = models.BooleanField(default=False)
    requester = models.ForeignKey(User, on_delete=models.CASCADE, blank=True, null=True)
    sample_size = models.PositiveIntegerField(default=0)
    sample_total_cpl = models.PositiveIntegerField(default=0)

    t1_total = models.PositiveIntegerField(default=0)
    t1_count = models.PositiveIntegerField(default=0)
    t2_total = models.PositiveIntegerField(default=0)
    t2_count = models.PositiveIntegerField(default=0)
    t3_total = models.PositiveIntegerField(default=0)
    t3_count = models.PositiveIntegerField(default=0)

    min_rating = models.PositiveIntegerField(blank=True, null=True, default=None)
    max_rating = models.PositiveIntegerField(blank=True, null=True, default=None)

    game_list = JSONField(default=list)
    cp_loss_count = JSONField(default=list)
    cp_loss_total = models.PositiveIntegerField(default=0)

    date_created = models.DateTimeField(auto_now_add=True)
    date_modified = models.DateTimeField(auto_now=True)


    @classmethod
    def from_cr_report(cls, player_report):
        copy_attrs = [
            'sample_size', 'sample_total_cpl',
            't1_total', 't1_count', 't2_total', 't2_count',
            't3_total', 't3_count', 'min_rating', 'max_rating',
            'game_list', 'cp_loss_total',
        ]
        update_dict = {}
        for attr in copy_attrs:
            update_dict[attr] = getattr(player_report, attr)

        update_dict['cp_loss_count'] = player_report.cp_loss_count_list()
        return cls(**update_dict)
