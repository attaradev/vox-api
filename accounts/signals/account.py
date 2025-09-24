"""Signal handlers for account creation and role assignment."""

from django.db.models.signals import post_save
from django.dispatch import receiver

from accounts.models import Account, AccountUserRole


@receiver(post_save, sender=Account)
def assign_owner_role(sender, instance, created, **kwargs):
    """Assign owner role to the user who created the account."""
    request = getattr(instance, "_request", None)
    if created and request and request.user.is_authenticated:
        AccountUserRole.objects.get_or_create(
            user=request.user, account=instance, role="owner"
        )
