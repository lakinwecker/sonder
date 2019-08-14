from django.urls import path

from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('login', views.index, name='login'),
    path('login/status', views.auth_status, name='login.auth-status'),
    path('login/start', views.login, name='login.start'),
    path('login/authorize', views.authorize, name='login.authorize'),
    path('login/unauthorized', views.index, name='login.unauthorized'),
    path('dashboard', views.index, name='dashboard'),
    path('colours', views.index, name='colours'),
    path('players', views.index, name='players'),
    path('players/<str:username>', views.index, name='player-detail'),
]

