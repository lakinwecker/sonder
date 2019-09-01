"""sonder URL Configuration
"""
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path

import sonder.frontend.views

urlpatterns = [
    path('', include('sonder.frontend.urls')),
    path('admin/', admin.site.urls),
    path('analysis/', include('sonder.analysis.urls')),
    path("graphql/", sonder.frontend.views.PrivateGraphQLView.as_view(graphiql=True)),
] + static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
