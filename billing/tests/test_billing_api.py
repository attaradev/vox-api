"""API-level tests for billing endpoints."""

import pytest
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APIClient

from accounts.models import Account
from billing.models import BillingAccount
from billing.models.subscription import Subscription


@pytest.mark.django_db
def test_admin_can_create_billing_account():
    """Ensure administrators can create billing accounts via the API."""

    account = Account.objects.create(name="Billable")
    admin_user = get_user_model().objects.create_superuser(
        username="admin", email="admin@example.com", password="password"
    )

    client = APIClient()
    client.force_authenticate(admin_user)

    response = client.post(
        "/api/billing/accounts/",
        {
            "account": account.id,
            "provider": "stripe",
            "billing_email": "bill@example.com",
        },
        format="json",
    )
    assert response.status_code == status.HTTP_201_CREATED
    assert BillingAccount.objects.filter(account=account).exists()


@pytest.mark.django_db
def test_subscription_status_requires_authentication():
    """Verify subscription status endpoint enforces authentication."""

    account = Account.objects.create(name="Sub Account")
    BillingAccount.objects.create(account=account, billing_email="acct@example.com")

    client = APIClient()
    unauthenticated = client.get(f"/api/billing/subscriptions/{account.id}/status/")
    assert unauthenticated.status_code == status.HTTP_401_UNAUTHORIZED

    user = get_user_model().objects.create_user(username="user", password="pw")
    client.force_authenticate(user)
    response = client.get(f"/api/billing/subscriptions/{account.id}/status/")
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["status"] == "trial"


@pytest.mark.django_db
def test_list_subscriptions_requires_admin():
    """Confirm subscription listings are restricted to admin users."""

    account = Account.objects.create(name="Sub Account")
    Subscription.objects.create(account=account, provider="stripe")
    user = get_user_model().objects.create_user(username="user", password="pw")
    admin = get_user_model().objects.create_superuser(
        username="admin", email="admin@example.com", password="password"
    )

    client = APIClient()
    client.force_authenticate(user)
    assert (
        client.get("/api/billing/subscriptions/").status_code
        == status.HTTP_403_FORBIDDEN
    )

    client.force_authenticate(admin)
    response = client.get("/api/billing/subscriptions/")
    assert response.status_code == status.HTTP_200_OK, response.json()
    payload = response.json()
    assert payload["count"] == 1
