"""Admin customizations for the billing app."""

from django.contrib import admin

from core.utils.audit import log_audit

from .models import BillingAccount


@admin.register(BillingAccount)
class BillingAccountAdmin(admin.ModelAdmin):
    """Customize admin interactions for billing accounts."""

    def save_model(self, request, obj, form, change):
        """Persist and audit billing account changes created via the admin."""

        super().save_model(request, obj, form, change)
        action = "billing_account_update" if change else "billing_account_create"
        log_audit(
            user=request.user,
            action=action,
            object_type="BillingAccount",
            object_id=obj.id,
            details={"account": obj.account.name, "status": obj.status},
        )

    def delete_model(self, request, obj):
        """Audit and delete billing accounts from the admin interface."""

        log_audit(
            user=request.user,
            action="billing_account_delete",
            object_type="BillingAccount",
            object_id=obj.id,
            details={"account": obj.account.name, "status": obj.status},
        )
        super().delete_model(request, obj)

    list_display = (
        "id",
        "account",
        "billing_email",
        "subscription_status",
        "payment_provider_id",
        "created_at",
        "updated_at",
    )
    search_fields = ("account__name", "billing_email")
