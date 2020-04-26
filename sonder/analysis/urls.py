from django.urls import path

from . import views

urlpatterns = [
    path("acquire", views.acquire, name="acquire"),
    path("status", views.status, name="status"),
]
