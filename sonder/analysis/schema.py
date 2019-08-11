"""
json schema schemas for our input/outputs
"""
import graphene
from graphene import relay, ObjectType
from graphene_django.types import DjangoObjectType
from graphene_django.filter import DjangoFilterConnectionField

from . import models

# TODO: welp, this wasn't nearly as succinct as I was hoping. :P
FishnetRequest = {
    "title": "FishnetRequest",
    "type" : "object",
    "required": ["fishnet", "engine"],
    "properties" : {
        "fishnet" : {
            "type" : "object",
            "required": ["version", "python", "apikey"],
            "properties": {
                "version": {"type": "string"},
                "python": {"type": "string"},
                "apikey": {"type": "string"}
            }
        },
        "engine" : {
            "type" : "object",
            "required": ["name", "options"],
            "properties": {
                "name": {"type": "string"},
                "options": {
                    "type": "object",
                    "properties": {
                        "hash": {"type": "string"}, # TODO: string?!
                        "threads": {"type": "string"} # TODO: string?!
                    }
                }
            }
        }
    }
}
FishnetJob = {
    "title": "FishnetJob",
    "type" : "object",
    "required": ["work", "position", "variant", "moves"],
    "properties" : {
        "work" : {
            "type" : "object",
            "required": ["type", "id"],
            "properties": {
                "type": {"type": "string"},
                "id": {"type": "string"}
            }
        },
        "game_id": {"type": "string"},
        "position": {"type": "string"},
        "variant": {"type": "string"},
        "moves": {"type": "string"},
        "nodes": { "type": "number", "minimum": 0 },
        "skipPositions": {
            "type": "array",
            "items": {"type": "number"},
        }
    }
}


class Player(DjangoObjectType):
    class Meta:
        model = models.Player
        filter_fields = ['username']
        interfaces = (relay.Node, )

    totalGames = graphene.String(required=True)

    def resolve_totalGames(parent, info):
        return len(parent.games_as_white.all()) + len(parent.games_as_black.all())


class Game(DjangoObjectType):
    class Meta:
        model = models.Game
        filter_fields = [
            'white_player__username',
            'black_player__username',
        ]
        interfaces = (relay.Node, )

class Query(ObjectType):
    players = graphene.List(Player)
    games = graphene.List(Game)


    def resolve_players(self, info, **kwargs):
        return models.Player.objects.all() \
                .order_by('username') \
                .prefetch_related('games_as_white', 'games_as_black')


    def resolve_games(self, info, **kwargs):
        return models.Game.objects.all().select_related('white_player', 'black_player')

schema = graphene.Schema(query=Query)
