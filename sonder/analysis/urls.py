from django.urls import path

from sonder.analysis import views

urlpatterns = [
    path('acquire', views.acquire, name='acquire'),
]

