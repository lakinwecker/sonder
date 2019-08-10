from django.shortcuts import render
from django.urls import reverse
from django.db import transaction
from django.contrib.auth.models import User
from django.contrib.auth import login as authLogin
from django.http import (
    HttpResponseRedirect,
    JsonResponse,
)

from authlib.django.client import OAuth
from .models import OAuth2Token, UserPreferences
from .schema import UserLoginResult

from .. import jsonapi

def fetch_token(name, request):
    item = OAuth2Token.objects.get(
        name=name,
        user=request.user
    )
    return item.to_token()


oauth = OAuth(fetch_token=fetch_token)
oauth.register('lichess')


def index(request):
    return render(request, "sonder/frontend/index.html")

def login(request):
    redirect_uri = request.build_absolute_uri(reverse('login.authorize'))
    response = oauth.lichess.authorize_redirect(request, redirect_uri)
    return JsonResponse({'url': response.url})

@transaction.atomic
def authorize(request):
    token = oauth.lichess.authorize_access_token(request)
    response = oauth.lichess.get('/api/account', token=token)
    result = response.json()
    username = result['username']

    try:
        user = User.objects.get(username=username)
    except User.DoesNotExist:
        return HttpResponseRedirect(reverse("login.unauthorized"))

    try:
        db_token = OAuth2Token.objects.get(user=user)
    except OAuth2Token.DoesNotExist:
        db_token = OAuth2Token(user=user)

    db_token.update_from_token(user, token)
    db_token.save()

    user.backend = 'django.contrib.auth.backends.ModelBackend'
    authLogin(request, user)

    return HttpResponseRedirect(reverse("dashboard"))


@jsonapi.api(None, UserLoginResult)
def auth_status(request, _none):
    if request.user.is_authenticated:
        user_preferences, _ = UserPreferences.objects.get_or_create(
            user=request.user
        )
        return {
            "type": "authorized",
            "username": request.user.email, # TODO: consider changing this to an actual username?
            "preferences": {
                "background": user_preferences.background
            }
        }

    return {
        "type": "anonymous",
    }
