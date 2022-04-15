from django.urls import path

from . import views

urlpatterns = [
    path("acquire", views.acquire, name="acquire"),
    path("analysis/<work_id>", views.analysis, name="analysis"),
    path("abort/<work_id>", views.abort, name="abort"),
    path("status", views.status, name="status"),
]
