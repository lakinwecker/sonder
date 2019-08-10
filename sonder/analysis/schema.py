"""
json schema schemas for our input/outputs
"""
import graphene
from graphene import relay, ObjectType
from graphene_django.types import DjangoObjectType
from graphene_django.filter import DjangoFilterConnectionField

from .models import Player, Game

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


class PlayerNode(DjangoObjectType):
    class Meta:
        model = Player
        filter_fields = ['username']
        interfaces = (relay.Node,)

class GameNode(DjangoObjectType):
    class Meta:
        model = Game
        filter_fields = [
            'white_player__username',
            'black_player__username',
        ]
        interfaces = (relay.Node,)

class Query(ObjectType):
    player = relay.Node.Field(PlayerNode)
    players = DjangoFilterConnectionField(PlayerNode)

    game = relay.Node.Field(GameNode)
    games = DjangoFilterConnectionField(GameNode)

    def resolve_games(self, info, **kwargs):
        return Game.objects.all().select_related('white_player', 'black_player')

schema = graphene.Schema(query=Query)
