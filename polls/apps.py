from django.apps import AppConfig


class PollsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "polls"
    verbose_name = "Polls"

    def ready(self):  # pragma: no cover - import side effects
        from . import signals  # noqa: F401
