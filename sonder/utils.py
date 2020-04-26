import chess.pgn
import io

from django.db import models
from django.utils.text import slugify

def pgn_to_uci(pgn):
    """A method that should take a PGN string and return a list of uci moves.
    """
    pgn = io.StringIO(pgn)
    game = chess.pgn.read_game(pgn)
    moves = []
    for move in game.mainline_moves():
        moves.append(move.uci())
    return moves

def _const_name(name):
    return slugify(name).replace("-", "_").upper()

class Choices:
    """
    A better choices field with less repetition, compared to django.


    Django recommends this pattern for choices on char fields:
    class Student(models.Model):
        FRESHMAN = 'FR'
        SOPHOMORE = 'SO'
        JUNIOR = 'JR'
        SENIOR = 'SR'
        YEAR_IN_SCHOOL_CHOICES = [
            (FRESHMAN, 'Freshman'),
            (SOPHOMORE, 'Sophomore'),
            (JUNIOR, 'Junior'),
            (SENIOR, 'Senior'),
        ]
        year_in_school = models.CharField(
            max_length=2,
            choices=YEAR_IN_SCHOOL_CHOICES,
            default=FRESHMAN,
        )
        def is_upperclass(self):
            return self.year_in_school in (self.JUNIOR, self.SENIOR)

    Using this, you can write this instead:
    class Student(models.Model):
        YEAR_IN_SCHOOL_CHOICES = Choices([
            ('FR', 'Freshman'),
            ('SO', 'Sophomore'),
            ('JR', 'Junior'),
            ('SR', 'Senior'),
        ])
        year_in_school = YEAR_IN_SCHOOL_CHOICES.get_field(default='FR')

        def is_upperclass(self):
            return self.year_in_school in (
                    self.YEAR_IN_SCHOOL_CHOICES.JUNIOR,
                    self.YEAR_IN_SCHOOL_CHOICES.SENIOR
                )


    """
    def __init__(self, choices):
        self.choices = choices

        # Calculate choices list
        self.max_length = 0
        for value, display in self.choices:
            self.max_length = max(self.max_length, len(value))

            # Set a constant accessor for each of them
            setattr(self, _const_name(display), value)

    # provide a helper to generate the field.
    def get_field(self, *args, **kwargs):
        return models.CharField(
            max_length=self.max_length,
            choices=self.choices,
            *args,
            **kwargs
        )
