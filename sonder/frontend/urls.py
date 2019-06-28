from django.urls import path

from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('login', views.index, name='login'),
    path('dashboard', views.index, name='dashboard'),
    path('login/start', views.login, name='login.start'),
    path('login/authorize', views.authorize, name='login.authorize'),
    path('login/unauthorized', views.index, name='login.unauthorized'),
]

