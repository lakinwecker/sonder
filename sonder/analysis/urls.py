from django.urls import path

from . import views

urlpatterns = [
    path('acquire', views.acquire, name='acquire'),
    path("graphql/", views.PrivateGraphQLView.as_view(graphiql=True)),
]
