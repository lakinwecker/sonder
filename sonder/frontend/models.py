"""The front end models are primarily about oauth.
"""
import datetime
from django.db import models

from django.contrib.auth.models import User

class InvalidUserTokenError(AssertionError):
    pass

class OAuth2Token(models.Model):
    user =  models.ForeignKey(User, on_delete=models.CASCADE)
    name = models.CharField(max_length=40)
    token_type = models.CharField(max_length=20)
    access_token = models.CharField(max_length=1024)
    refresh_token = models.CharField(max_length=1024)
    # oauth 2 expires time
    expires_at = models.DateTimeField()

    def update_from_token(self, user, token):
        if self.user != user or self.user is None:
            raise InvalidUserTokenError("Invalid user for this token")
        self.user = user
        self.token_type = token.get('token_type', 'bearer')
        self.access_token = token.get('access_token')
        self.refresh_token = token.get('refresh_token')
        expires_at = datetime.datetime.fromtimestamp(token.get('expires_at'))
        self.expires_at = expires_at

    def to_token(self):
        return dict(
            access_token=self.access_token,
            token_type=self.token_type,
            refresh_token=self.refresh_token,
            expires_at=self.expires_at,
        )


class UserPreferences(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    background = models.CharField(max_length=255, default="")

    def json(self):
        return {"background": self.background}

