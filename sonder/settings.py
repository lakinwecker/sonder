"""
Django settings for sonder project.
"""

import os
import dj_database_url

# Build paths inside the project like this: os.path.join(BASE_DIR, ...)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/2.2/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.environ.get('SECRET_KEY', 'dr#-g98prpuk8&mbz+m02o&!&ne6pkhf^-6o^15f&k8t$dzn6s')
DEBUG = os.environ.get('DEBUG', False)

ALLOWED_HOSTS = [
    os.environ.get('ALLOWED_HOSTS', 'localhost'),
]


# Application definition

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'sonder.analysis',
    'sonder.frontend',
    'graphene_django',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'sonder.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'sonder.wsgi.application'

DATABASES = {}
DATABASES['default'] = dj_database_url.config(
    default='postgres://sonder:Eemoh8ait6taequ3ph@localhost:5432/sonder',
    conn_max_age=600
)

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',},
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_L10N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = os.environ.get('STATIC_ROOT', None)
STATICFILES_DIRS = [
]

LOGIN_URL = "/"
LOGIN_REDIRECT_URL = "/"
LICHESS_OAUTH_CLIENT_ID = os.environ.get('LICHESS_OAUTH_CLIENT_ID', '')
LICHESS_CLIENT_SECRET = os.environ.get('LICHESS_CLIENT_SECRET', '')
AUTHLIB_OAUTH_CLIENTS = {
    'lichess': {
        'client_id': LICHESS_OAUTH_CLIENT_ID,
        'client_secret': LICHESS_CLIENT_SECRET,
        #'request_token_url': 'https://oauth.lichess.org/oauth',
        #'request_token_params': None,
        'access_token_url': 'https://oauth.lichess.org/oauth',
        'access_token_params': None,
        'refresh_token_url': None,
        'authorize_url': 'https://oauth.lichess.org/oauth/authorize',
        'api_base_url': 'https://lichess.org/api',
        'client_kwargs': { }
    }
}

GRAPHENE = {
    'SCHEMA': 'sonder.schema.schema',
    'MIDDLEWARE': [
        'graphene_django_extras.ExtraGraphQLDirectiveMiddleware'
    ]
}
