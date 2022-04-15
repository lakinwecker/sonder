"""
json schema schemas for our input/outputs
"""
import graphene
from graphene import ObjectType
from graphene_django.types import DjangoObjectType
from django_filters import FilterSet

from ..graphene_utils import LoginRequired
from graphene_django_extras import DjangoFilterPaginateListField
from graphene_django_extras.paginations import LimitOffsetGraphqlPagination

from . import models
from .. import cr

# TODO: welp, this wasn't nearly as succinct as I was hoping. :P
FishnetRequest = {
    "title": "FishnetRequest",
    "type": "object",
    "required": ["fishnet", "stockfish"],
    "properties": {
        "fishnet": {
            "type": "object",
            "required": ["version", "python", "apikey"],
            "properties": {
                "version": {"type": "string"},
                "python": {"type": "string"},
                "apikey": {"type": "string"},
            },
        },
        "stockfish": {
            "type": "object",
            "required": ["name", "options"],
            "properties": {
                "name": {"type": "string"},
                "options": {"type": "object" },
            },
        },
    },
}
FishnetJob = {
    "title": "FishnetJob",
    "type": "object",
    "required": ["work", "position", "variant", "moves"],
    "properties": {
        "work": {
            "type": "object",
            "required": ["type", "id"],
            "properties": {"type": {"type": "string"}, "id": {"type": "string"}},
        },
        "game_id": {"type": "string"},
        "position": {"type": "string"},
        "variant": {"type": "string"},
        "moves": {"type": "string"},
        "nodes": {"type": "number", "minimum": 0},
        "multipv": {"type": "number", "minimum": 0},
        "skipPositions": {"type": "array", "items": {"type": "number"},},
    },
}

FishnetAnalysis = {
    "title": "FishnetAnalysis",
    "type": "object",
    "required": ["fishnet", "stockfish", "analysis"],
    "properties": {
        "fishnet": {
            "type": "object",
            "required": ["version", "python", "apikey"],
            "properties": {
                "version": {"type": "string"},
                "python": {"type": "string"},
                "apikey": {"type": "string"},
            },
        },
        "stockfish": {
            "type": "object",
            "required": ["name", "options"],
            "properties": {
                "name": {"type": "string"},
                "options": {"type": "object"},
            }
        },
        "analysis": {
            "type": "array",
            "items": {
                "anyOf": [{
                    "type": "null",
                }, {
                    "type": "object",
                    "properties": {
                        "skipped": {"type": "boolean"},
                        "bsetmove": {"type": "string"},
                        "pv": {"type": "string"},
                        "seldepth": {"type": "number"},
                        "tbhits": {"type": "number"},
                        "depth": {"type": "number"},
                        "score": {
                            "type": "object",
                            "properties": {
                                "cp": {"type": "number"},
                                "mate": {"type": "number"},
                             }
                        },
                        "time": {"type": "number"},
                        "nodes": {"type": "number"},
                        "nps": {"type": "number"},
                    }
                    }]
            }
        }
    }
}


class CPLoss(ObjectType):
    title = graphene.String(required=True)
    count = graphene.Int(required=True)


class CRReport(DjangoObjectType, LoginRequired):
    class Meta:
        model = models.CRReport
        filter_fields = {
            "player__username": ("icontains", "iexact"),
            "type": ("iexact",),
            "name": ("icontains", "iexact",),
        }
        fields = [
            "player",
            "report_type",
            "completed",
            "requester",
            "sample_size",
            "sample_total_cpl",
            "t1_total",
            "t1_count",
            "t2_total",
            "t2_count",
            "t3_total",
            "t3_count",
            "min_rating",
            "max_rating",
            "cp_loss_total",
        ]

    t1_percentage = graphene.Float(required=True)

    def resolve_t1_percentage(parent, info):
        return float(parent.t1_count) / float(parent.t1_total)

    t2_percentage = graphene.Float(required=True)

    def resolve_t2_percentage(parent, info):
        return float(parent.t2_count) / float(parent.t2_total)

    t3_percentage = graphene.Float(required=True)

    def resolve_t3_percentage(parent, info):
        return float(parent.t3_count) / float(parent.t3_total)

    game_list = graphene.List(graphene.NonNull(graphene.String), required=True)

    def resolve_game_list(parent, info):
        return parent.game_list

    cp_loss_count = graphene.List(graphene.NonNull(CPLoss), required=True)

    def resolve_cp_loss_count(parent, info):
        return [
            {"title": k, "count": parent["cp_loss_count"][k]} for k in cr.cp_loss_names
        ]


class Game(DjangoObjectType, LoginRequired):
    class Meta:
        model = models.Game
        filter_fields = [
            "white_player__username",
            "black_player__username",
        ]


class PlayerFilter(FilterSet):
    class Meta:
        model = models.Player
        fields = {
            "id": ("exact",),
            "username": ("icontains", "iexact"),
        }

    @property
    def qs(self):
        # The query context can be found in self.request.
        return super(PlayerFilter, self).qs.prefetch_related(
            "games_as_white", "games_as_black"
        )


class Player(DjangoObjectType, LoginRequired):
    class Meta:
        model = models.Player
        pagination = LimitOffsetGraphqlPagination(
            default_limit=25, ordering="username"
        )  # ordering can be: string, tuple or list

    totalGames = graphene.Int(required=True)

    def resolve_totalGames(parent, info):
        return parent.games_as_white.count() + parent.games_as_black.count()


class Query(ObjectType, LoginRequired):
    player = graphene.Field(Player, username=graphene.String(required=True))
    players = DjangoFilterPaginateListField(
        Player,
        required=True,
        pagination=LimitOffsetGraphqlPagination(),
        filterset_class=PlayerFilter,
    )

    @classmethod
    def resolve_player(cls, info, **kwargs):
        if info.context.user.is_anonymous:
            return None
        _id = kwargs.get("id")
        username = kwargs.get("username")

        if _id is not None:
            return models.Player.objects.get(pk=_id)

        if username is not None:
            return models.Player.objects.get(username=username)

        return None

