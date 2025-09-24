"""Model-level tests for billing domain objects."""

import pytest

from accounts.models import Account
from billing.models import BillingAccount


@pytest.mark.django_db
def test_billing_account_creation():
    """Ensure billing accounts can be created with minimal data."""

    account = Account.objects.create(name="TestBillingAccount")
    billing = BillingAccount.objects.create(
        account=account, billing_email="test@example.com"
    )
    assert billing.account.name == "TestBillingAccount"
    assert billing.billing_email == "test@example.com"


@pytest.mark.django_db
def test_billing_provider_id():
    """Confirm billing accounts persist provider identifiers."""

    account = Account.objects.create(name="StripeAccount")
    billing = BillingAccount.objects.create(
        account=account, payment_provider_id="cus_123"
    )
    assert billing.payment_provider_id == "cus_123"


@pytest.mark.django_db
def test_subscription_status_change():
    """Verify the subscription status field accepts updates."""

    account = Account.objects.create(name="TestSubStatus")
    billing = BillingAccount.objects.create(account=account)
    billing.subscription_status = "active"
    billing.save()
    assert billing.subscription_status == "active"
    billing.subscription_status = "canceled"
    billing.save()
    assert billing.subscription_status == "canceled"


@pytest.mark.django_db
def test_duplicate_billing_account():
    """Ensure duplicate billing accounts raise an error."""

    account = Account.objects.create(name="DupBilling")
    BillingAccount.objects.create(account=account)
    with pytest.raises(Exception):
        BillingAccount.objects.create(account=account)


@pytest.mark.django_db
def test_missing_billing_email():
    """Check billing accounts default to an empty billing email."""

    account = Account.objects.create(name="NoEmailBilling")
    billing = BillingAccount.objects.create(account=account)
    assert billing.billing_email == ""
