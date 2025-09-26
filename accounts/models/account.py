"""Model for representing an account and its subscription tier."""

from django.conf import settings
from django.db import models
from django.utils import timezone

from core.utils.audit import log_audit

from .tier import AccountTier


class Account(models.Model):
    """Model representing an organization account and its tier."""

    name = models.CharField(max_length=100, unique=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    tier = models.ForeignKey(
        AccountTier,
        on_delete=models.PROTECT,
        related_name="accounts",
        null=True,
        blank=True,
        help_text="Tier controls feature limits such as members and polls",
    )
    billing_email = models.EmailField(blank=True)
    subscription_status = models.CharField(
        max_length=20,
        choices=[
            ("active", "Active"),
            ("past_due", "Past Due"),
            ("canceled", "Canceled"),
            ("trial", "Trial"),
        ],
        default="trial",
    )
    payment_provider_id = models.CharField(
        max_length=128,
        blank=True,
        help_text="ID from payment provider (e.g., Stripe customer ID)",
    )
    status = models.CharField(
        max_length=20,
        choices=[
            ("pending", "Pending"),
            ("approved", "Approved"),
            ("suspended", "Suspended"),
        ],
        default="pending",
        help_text="Lifecycle state of the account",
    )
    status_changed_at = models.DateTimeField(null=True, blank=True)
    status_changed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="account_status_changes",
    )
    status_reason = models.CharField(max_length=255, blank=True)

    def __str__(self):
        """Return the account name as string representation."""
        return self.name

    def can_add_member(self) -> bool:
        """Check if a new member can be added based on tier limits."""
        if not self.tier:
            return True
        return self.user_roles.count() < self.tier.max_members

    def can_add_poll(self) -> bool:
        """Check if a new poll can be added based on tier limits."""
        if not self.tier:
            return True
        from polls.models.poll import Poll

        return self.is_active and (
            Poll.objects.filter(account=self).count() < self.tier.max_polls
        )

    def tier_features(self):
        """Return a dictionary of tier features for this account."""
        if not self.tier:
            return {}
        return {
            "max_members": self.tier.max_members,
            "max_polls": self.tier.max_polls,
            "price_per_month": self.tier.price_per_month,
            "is_active": self.tier.is_active,
        }

    STATUS_TRANSITIONS = {
        "pending": {"approved", "suspended"},
        "approved": {"suspended"},
        "suspended": {"approved"},
    }

    def _set_status(self, new_status: str, user=None, reason: str = "") -> None:
        current = self.status or "pending"
        allowed = self.STATUS_TRANSITIONS.get(current, set())
        if new_status == current:
            return
        if new_status not in allowed:
            raise ValueError(
                f"Transition from '{current}' to '{new_status}' is not permitted."
            )
        self.status = new_status
        self.status_changed_at = timezone.now()
        self.status_changed_by = user
        self.status_reason = reason
        self.save(
            update_fields=[
                "status",
                "status_changed_at",
                "status_changed_by",
                "status_reason",
            ]
        )
        log_audit(
            user=user or "system",
            action=f"account_status_{new_status}",
            object_type="Account",
            object_id=self.id,
            details={
                "previous_status": current,
                "new_status": new_status,
                "reason": reason,
            },
        )

    def approve(self, user=None):
        """Transition the account to the approved state."""

        self._set_status("approved", user=user)
        default_tier = None
        if not self.tier:
            default_tier = (
                AccountTier.objects.filter(is_active=True)
                .order_by("price_per_month", "id")
                .first()
            )
            if default_tier:
                self.tier = default_tier
        previous_subscription_status = self.subscription_status
        if self.subscription_status != "active":
            self.subscription_status = "active"
        if default_tier or self.subscription_status != previous_subscription_status:
            update_fields = []
            if default_tier:
                update_fields.append("tier")
            if self.subscription_status != previous_subscription_status:
                update_fields.append("subscription_status")
            if update_fields:
                self.save(update_fields=update_fields)
            log_audit(
                user=user or "system",
                action="account_subscription_updated",
                object_type="Account",
                object_id=self.id,
                details={
                    "tier": getattr(self.tier, "name", None),
                    "subscription_status": self.subscription_status,
                },
            )

    def suspend(self, user=None, reason: str = "") -> None:
        """Suspend the account with an optional reason."""

        self._set_status("suspended", user=user, reason=reason)

    def reinstate(self, user=None) -> None:
        """Reinstate a suspended account back to approved."""

        if self.status == "suspended":
            self._set_status("approved", user=user)
        else:
            raise ValueError("Only suspended accounts can be reinstated.")

    def change_tier(self, tier: AccountTier, user=None):
        previous = self.tier
        self.tier = tier
        self.save(update_fields=["tier"])
        log_audit(
            user=user or "system",
            action="account_tier_change",
            object_type="Account",
            object_id=self.id,
            details={
                "previous_tier": getattr(previous, "name", None),
                "new_tier": tier.name,
            },
        )

    @property
    def is_approved(self) -> bool:
        return self.status == "approved"

    @property
    def is_suspended(self) -> bool:
        return self.status == "suspended"

    @property
    def is_active(self) -> bool:
        return self.status == "approved" and self.subscription_status == "active"
