import logging
import os
from pathlib import Path
from urllib.parse import parse_qs, urlparse, urlunparse


def env(key: str, default=None):
    """Read an environment variable with a fallback."""

    return os.environ.get(key, default)


def env_bool(key: str, default: bool) -> bool:
    """Interpret an environment variable as a boolean flag."""

    value = os.environ.get(key)
    if value is None:
        return default
    return value.lower() in {"1", "true", "yes", "on"}


def env_int(key: str, default: int) -> int:
    """Return an integer environment variable, falling back on errors."""

    value = os.environ.get(key)
    if value is None:
        return default
    try:
        return int(value)
    except ValueError:
        return default


def env_float(key: str, default: float) -> float:
    """Return a float environment variable, falling back on errors."""

    value = os.environ.get(key)
    if value is None:
        return default
    try:
        return float(value)
    except ValueError:
        return default


DJANGO_ENV = env("DJANGO_ENV", "development")
IS_PRODUCTION = DJANGO_ENV == "production"
DEBUG = DJANGO_ENV == "development"

# Redis configuration

# Handle Redis URL - either direct URL or host/port components
REDIS_URL = env("REDIS_URL")
if REDIS_URL:
    # Parse the provided REDIS_URL
    parsed = urlparse(REDIS_URL)
    REDIS_HOST = parsed.hostname or "localhost"
    REDIS_PORT = parsed.port or 6379
else:
    # Fallback to individual host/port env vars
    REDIS_HOST = env("REDIS_HOST", "localhost")
    REDIS_PORT = env_int("REDIS_PORT", 6379)
    REDIS_URL = f"redis://{REDIS_HOST}:{REDIS_PORT}/0"


def _redis_url_with_db(url: str, db_alias: str) -> str:
    """Return the provided Redis URL pointed at the desired logical database."""

    parsed = urlparse(url)
    if not parsed.scheme.startswith("redis"):
        return url
    return urlunparse(parsed._replace(path=f"/{db_alias}"))


CACHE_URL = env("CACHE_URL")
if not CACHE_URL and REDIS_URL:
    cache_db = env("CACHE_REDIS_DB", "1")
    CACHE_URL = _redis_url_with_db(REDIS_URL, cache_db)

try:  # Optional dependency for redis-backed caches and Celery
    import redis  # noqa: F401

    _redis_driver_present = True
except ImportError:
    _redis_driver_present = False

CACHE_LOGGER = logging.getLogger("vox_api.settings.cache")


def _redis_cache_available(location: str) -> bool:
    if not _redis_driver_present or not location:
        return False
    if not location.startswith("redis://"):
        return False
    try:
        client = redis.Redis.from_url(  # type: ignore[attr-defined]
            location,
            socket_connect_timeout=env_float("CACHE_REDIS_CONNECT_TIMEOUT", 0.25),
        )
        client.ping()
        client.close()
        return True
    except Exception as exc:  # pragma: no cover - defensive guard
        CACHE_LOGGER.warning(
            "Redis cache unavailable at %s; falling back to in-memory cache. (%s)",
            location,
            exc,
        )
        return False


CACHE_DEFAULT_TIMEOUT = env_int("CACHE_DEFAULT_TIMEOUT", 300)

if _redis_cache_available(CACHE_URL or ""):
    CACHES = {
        "default": {
            "BACKEND": "django.core.cache.backends.redis.RedisCache",
            "LOCATION": CACHE_URL,
            "TIMEOUT": CACHE_DEFAULT_TIMEOUT,
            "OPTIONS": {
                "retry_on_timeout": True,
            },
        }
    }
else:
    CACHES = {
        "default": {
            "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
            "LOCATION": "vox-api-local",
            "TIMEOUT": CACHE_DEFAULT_TIMEOUT,
        }
    }
    if CACHE_URL and CACHE_URL.startswith("redis://") and not _redis_driver_present:
        CACHE_LOGGER.warning(
            "redis-py is not installed; falling back to in-memory caching backend."
        )

DEFAULT_CACHE_TTL = CACHE_DEFAULT_TIMEOUT
POLL_CACHE_TIMEOUT = env_int("POLL_CACHE_TIMEOUT", DEFAULT_CACHE_TTL)

# Logging configuration


LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "{levelname} {asctime} {module} {message}",
            "style": "{",
        },
        "simple": {
            "format": "{levelname} {message}",
            "style": "{",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "verbose",
        },
    },
    "loggers": {
        "accounts.email": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
    },
}

# Email settings
EMAIL_BACKEND = env("EMAIL_BACKEND", "django.core.mail.backends.console.EmailBackend")
EMAIL_HOST = env("EMAIL_HOST", "smtp.gmail.com")
EMAIL_PORT = env_int("EMAIL_PORT", 587)
EMAIL_USE_TLS = env_bool("EMAIL_USE_TLS", True)
EMAIL_HOST_USER = env("EMAIL_HOST_USER", "")
EMAIL_HOST_PASSWORD = env("EMAIL_HOST_PASSWORD", "")

# Frontend URL for password reset links
FRONTEND_URL = env("FRONTEND_URL", "https://your-frontend")

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework.authentication.TokenAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.AllowAny",
    ],
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "DEFAULT_VERSIONING_CLASS": "rest_framework.versioning.NamespaceVersioning",
    "ALLOWED_VERSIONS": ["v1", "v2"],
    "VERSION_PARAM": "version",
    "DEFAULT_VERSION": "v1",
    # Throttling for scalability
    "DEFAULT_THROTTLE_CLASSES": [
        "rest_framework.throttling.UserRateThrottle",
        "rest_framework.throttling.AnonRateThrottle",
    ],
    "DEFAULT_THROTTLE_RATES": {
        "user": "1000/day",
        "anon": "100/day",
    },
    # Pagination for large lists
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
    # Custom exception handler for unified error responses
    "EXCEPTION_HANDLER": "vox_api.utils.custom_exception_handler",
}
# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent


# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/4.2/howto/deployment/checklist/


DATABASE_URL = env("DATABASE_URL")


def _database_config_from_url(url: str) -> dict:
    parsed = urlparse(url)
    scheme = parsed.scheme
    if "+" in scheme:
        scheme = scheme.split("+", 1)[0]
    scheme = scheme.replace("postgresql", "postgres")
    if not scheme.startswith("postgres"):
        raise ValueError(f"Unsupported database backend '{parsed.scheme}'.")

    query_params = {key: values[-1] for key, values in parse_qs(parsed.query).items()}

    config: dict[str, object] = {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": parsed.path.lstrip("/") or "postgres",
        "USER": parsed.username or "",
        "PASSWORD": parsed.password or "",
        "HOST": parsed.hostname or "",
        "PORT": str(parsed.port or "5432"),
    }
    if query_params:
        config["OPTIONS"] = query_params
    return config


POSTGRES_DB = env("POSTGRES_DB")
POSTGRES_USER = env("POSTGRES_USER")
POSTGRES_PASSWORD = env("POSTGRES_PASSWORD")
POSTGRES_HOST = env("POSTGRES_HOST", "db")
POSTGRES_PORT = env("POSTGRES_PORT", "5432")

AWS_STORAGE_BUCKET_NAME = env("AWS_STORAGE_BUCKET_NAME", "")
AWS_ACCESS_KEY_ID = env("AWS_ACCESS_KEY_ID", "")
AWS_SECRET_ACCESS_KEY = env("AWS_SECRET_ACCESS_KEY", "")
AWS_S3_REGION_NAME = env("AWS_S3_REGION_NAME", "us-east-1")

SECRET_KEY = env(
    "DJANGO_SECRET_KEY", "sample-secret-key-for-dev-only" if not IS_PRODUCTION else None
)

STRIPE_SECRET_KEY = env(
    "STRIPE_SECRET_KEY",
    "" if IS_PRODUCTION else "sk_test_your_default_key",
)
STRIPE_WEBHOOK_SECRET = env("STRIPE_WEBHOOK_SECRET", "")

USE_REDIS_FOR_CELERY = env_bool("USE_REDIS_FOR_CELERY", not DEBUG)

celery_broker = env("CELERY_BROKER_URL")
celery_backend = env("CELERY_RESULT_BACKEND")

if USE_REDIS_FOR_CELERY and not celery_broker:
    celery_broker = REDIS_URL
if USE_REDIS_FOR_CELERY and not celery_backend:
    celery_backend = REDIS_URL

CELERY_BROKER_URL = celery_broker or "memory://"

if celery_backend:
    CELERY_RESULT_BACKEND = celery_backend
elif CELERY_BROKER_URL.startswith("redis://"):
    CELERY_RESULT_BACKEND = CELERY_BROKER_URL
else:
    CELERY_RESULT_BACKEND = "cache+memory://"

CELERY_TASK_ALWAYS_EAGER = env_bool("CELERY_TASK_ALWAYS_EAGER", DEBUG)

CELERY_TASK_EAGER_PROPAGATES = True

# Allowed hosts default to local development values. When DEBUG is enabled we
# widen the list to include common testing hosts (127.0.0.1, testserver) so dev
# tooling like Swagger UI and Django's test client don't trip DisallowedHost.
_raw_allowed_hosts = env("DJANGO_ALLOWED_HOSTS", "0.0.0.0,localhost").split(",")
_clean_allowed_hosts = [host.strip() for host in _raw_allowed_hosts if host.strip()]
_base_hosts = ["localhost", "127.0.0.1"]
if DEBUG:
    _base_hosts.append("testserver")
_clean_allowed_hosts.extend(_base_hosts)

if env_bool("ALLOW_BIND_ALL_HOSTS", False):
    _clean_allowed_hosts.append("0.0.0.0")  # nosec B104

ALLOWED_HOSTS = list(dict.fromkeys(_clean_allowed_hosts))


# Application definition

DJANGO_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
]

THIRD_PARTY_APPS = [
    "rest_framework",
    "rest_framework.authtoken",
    "drf_spectacular",
]

LOCAL_APPS = [
    "accounts",
    "auth",
    "polls",
    "billing",
    "core",
]

INSTALLED_APPS = list(dict.fromkeys([*DJANGO_APPS, *THIRD_PARTY_APPS, *LOCAL_APPS]))

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "vox_api.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "vox_api.wsgi.application"


# Database
# https://docs.djangoproject.com/en/4.2/ref/settings/#databases


if DATABASE_URL:
    DATABASES = {"default": _database_config_from_url(DATABASE_URL)}
elif IS_PRODUCTION:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": POSTGRES_DB,
            "USER": POSTGRES_USER,
            "PASSWORD": POSTGRES_PASSWORD,
            "HOST": POSTGRES_HOST,
            "PORT": POSTGRES_PORT,
        }
    }
elif POSTGRES_DB:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": POSTGRES_DB,
            "USER": POSTGRES_USER,
            "PASSWORD": POSTGRES_PASSWORD,
            "HOST": POSTGRES_HOST,
            "PORT": POSTGRES_PORT,
        }
    }
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": str(BASE_DIR / "db.sqlite3"),
        }
    }


# Password validation
# https://docs.djangoproject.com/en/4.2/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": (
            "django.contrib.auth.password_validation."
            "UserAttributeSimilarityValidator"
        ),
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]


# Internationalization
# https://docs.djangoproject.com/en/4.2/topics/i18n/

LANGUAGE_CODE = "en-us"

TIME_ZONE = "UTC"

USE_I18N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

# Media files
MEDIA_URL = "media/"
MEDIA_ROOT = BASE_DIR / "media"

# Security best practices
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SECURE_SSL_REDIRECT = not DEBUG
SESSION_COOKIE_SECURE = not DEBUG
CSRF_COOKIE_SECURE = not DEBUG
X_FRAME_OPTIONS = "DENY"

# Enforce HTTPS in production
if not DEBUG:
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_REFERRER_POLICY = "same-origin"

# DRF Spectacular settings for modular API docs
SPECTACULAR_SETTINGS = {
    "TITLE": "Vox Poll API",
    "DESCRIPTION": "Online poll system backend with modular, production-ready APIs.",
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,
}

# Default primary key field type
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
