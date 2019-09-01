"""
json schema schemas for our input/outputs
"""

import graphene
from graphene import ObjectType, String, Field

UserLoginResult = {
    "title": "UserLoginResult",
    "type" : "object",
    "required": ["preferences"],
    "properties" : {
        "preferences" : {
            "type" : "object",
            "required": ["background"],
            "properties": {
                "background": {"type": "string"},
            }
        }
    }
}

class AuthStatus(graphene.Enum):
    AUTHORIZED = 1
    UNAUTHORIZED = 2
    ANONYMOUS = 3

class Preferences(ObjectType):
    background = String()

class UserStatus(ObjectType):
    status = Field(AuthStatus)
    preferences = Field(Preferences, required=False)


class Query(ObjectType):
    userStatus = Field(UserStatus)

    def resolve_userStatus(self, info, **kwargs):
        user = info.context.user
        if user.is_authenticated:
            return UserStatus(
                status=AuthStatus.AUTHORIZED,
                preferences=None
            )
        else:
            return UserStatus(
                status=AuthStatus.ANONYMOUS,
                preferences=None
            )

schema = graphene.Schema(query=Query)
