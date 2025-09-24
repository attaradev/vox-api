"""Admin customizations for the accounts app."""

from django.contrib import admin

from core.utils.audit import log_audit

from .models import Account, AccountTier, AccountUserRole


@admin.register(AccountTier)
class AccountTierAdmin(admin.ModelAdmin):
    """Customize admin for account tiers."""

    list_display = (
        "id",
        "name",
        "max_members",
        "max_polls",
        "price_per_month",
        "is_active",
    )
    search_fields = ("name",)


@admin.register(Account)
class AccountAdmin(admin.ModelAdmin):
    """Customize admin for account objects."""

    list_display = (
        "id",
        "name",
        "created_at",
        "tier",
        "billing_email",
        "subscription_status",
        "payment_provider_id",
    )
    search_fields = ("name", "billing_email")

    def save_model(self, request, obj, form, change):
        """Audit account creation and updates."""
        super().save_model(request, obj, form, change)
        action = "account_update" if change else "account_create"
        log_audit(
            user=request.user,
            action=action,
            object_type="Account",
            object_id=obj.id,
            details={"name": obj.name},
        )

    def delete_model(self, request, obj):
        """Audit account deletion."""
        log_audit(
            user=request.user,
            action="account_delete",
            object_type="Account",
            object_id=obj.id,
            details={"name": obj.name},
        )
        super().delete_model(request, obj)


@admin.register(AccountUserRole)
class AccountUserRoleAdmin(admin.ModelAdmin):
    """Customize admin for account user roles."""

    def save_model(self, request, obj, form, change):
        """Audit member addition and updates."""
        super().save_model(request, obj, form, change)
        action = "account_member_update" if change else "account_member_add"
        log_audit(
            user=request.user,
            action=action,
            object_type="AccountUserRole",
            object_id=obj.id,
            details={
                "user": obj.user.username,
                "account": obj.account.name,
                "role": obj.role,
            },
        )

    def delete_model(self, request, obj):
        """Audit member deletion."""
        log_audit(
            user=request.user,
            action="account_member_delete",
            object_type="AccountUserRole",
            object_id=obj.id,
            details={
                "user": obj.user.username,
                "account": obj.account.name,
                "role": obj.role,
            },
        )
        super().delete_model(request, obj)

    list_display = ("id", "user", "account", "role", "joined_at")
    list_filter = ("role", "account")
    search_fields = ("user__username", "account__name")
