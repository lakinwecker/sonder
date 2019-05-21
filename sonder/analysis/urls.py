from django.urls import path

from . import views

urlpatterns = [
    path('acquire', views.acquire, name='acquire'),
]

