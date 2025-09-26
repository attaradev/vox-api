import pytest
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APIClient

from accounts.models import Account, AccountTier
from core.models import AuditLog


@pytest.mark.django_db
def test_admin_can_create_account():
    tier = AccountTier.objects.create(name="Starter", max_members=5, max_polls=10)
    admin_user = get_user_model().objects.create_superuser(
        username="admin",
        email="admin@example.com",
        password="password",
    )
    client = APIClient()
    client.force_authenticate(admin_user)

    response = client.post(
        "/api/accounts/",
        {"name": "Acme", "tier": tier.id, "billing_email": "billing@acme.com"},
        format="json",
    )

    assert response.status_code == status.HTTP_201_CREATED, response.json()
    payload = response.json()
    assert payload["name"] == "Acme"
    assert payload["tier"] == tier.id
    assert payload["member_count"] == 1


@pytest.mark.django_db
def test_admin_can_manage_members():
    tier = AccountTier.objects.create(name="Team", max_members=2, max_polls=5)
    account = Account.objects.create(name="Team Account", tier=tier)
    member = get_user_model().objects.create_user(username="member", password="pw")
    admin_user = get_user_model().objects.create_superuser(
        username="admin", email="admin@example.com", password="password"
    )

    client = APIClient()
    client.force_authenticate(admin_user)

    response = client.post(
        f"/api/accounts/{account.id}/members/",
        {"user": member.id, "role": "member"},
        format="json",
    )
    payload = response.json()
    assert response.status_code == status.HTTP_201_CREATED, payload
    assert account.user_roles.count() == 1

    list_response = client.get(f"/api/accounts/{account.id}/members/")
    assert list_response.status_code == status.HTTP_200_OK
    assert len(list_response.json()) == 1


@pytest.mark.django_db
def test_member_limit_enforced():
    tier = AccountTier.objects.create(name="Solo", max_members=1, max_polls=5)
    account = Account.objects.create(name="Solo Account", tier=tier)
    admin_user = get_user_model().objects.create_superuser(
        username="admin", email="admin@example.com", password="password"
    )
    user_one = get_user_model().objects.create_user(username="one", password="pw")
    user_two = get_user_model().objects.create_user(username="two", password="pw")

    client = APIClient()
    client.force_authenticate(admin_user)
    client.post(
        f"/api/accounts/{account.id}/members/",
        {"user": user_one.id, "role": "member"},
        format="json",
    )

    response = client.post(
        f"/api/accounts/{account.id}/members/",
        {"user": user_two.id, "role": "member"},
        format="json",
    )
    error_payload = response.json()
    assert response.status_code == status.HTTP_400_BAD_REQUEST, error_payload
    assert "Member limit" in str(error_payload)


@pytest.mark.django_db
def test_set_tier_action():
    tier_a = AccountTier.objects.create(name="Basic", max_members=1, max_polls=1)
    tier_b = AccountTier.objects.create(name="Pro", max_members=5, max_polls=10)
    account = Account.objects.create(
        name="Tier Switch",
        tier=tier_a,
        status="approved",
        subscription_status="active",
    )
    admin_user = get_user_model().objects.create_superuser(
        username="admin", email="admin@example.com", password="password"
    )

    client = APIClient()
    client.force_authenticate(admin_user)
    response = client.post(
        f"/api/accounts/{account.id}/tier/",
        {"tier_id": tier_b.id},
        format="json",
    )
    assert response.status_code == status.HTTP_200_OK
    account.refresh_from_db()
    assert account.tier == tier_b
    tier_log = (
        AuditLog.objects.filter(action="account_tier_change", object_id=str(account.id))
        .order_by("-timestamp")
        .first()
    )
    assert tier_log is not None
    assert "Pro" in tier_log.details


@pytest.mark.django_db
def test_set_tier_action_supports_patch():
    tier_a = AccountTier.objects.create(name="Starter", max_members=1, max_polls=1)
    tier_b = AccountTier.objects.create(name="Plus", max_members=5, max_polls=10)
    account = Account.objects.create(
        name="Tier Switch Patch",
        tier=tier_a,
        status="approved",
        subscription_status="active",
    )
    admin_user = get_user_model().objects.create_superuser(
        username="admin2", email="admin2@example.com", password="password"
    )

    client = APIClient()
    client.force_authenticate(admin_user)
    response = client.patch(
        f"/api/accounts/{account.id}/tier/",
        {"tier_id": tier_b.id},
        format="json",
    )
    assert response.status_code == status.HTTP_200_OK
    account.refresh_from_db()
    assert account.tier == tier_b
    tier_log_patch = (
        AuditLog.objects.filter(action="account_tier_change", object_id=str(account.id))
        .order_by("-timestamp")
        .first()
    )
    assert tier_log_patch is not None
    assert "Plus" in tier_log_patch.details


@pytest.mark.django_db
def test_admin_can_approve_account():
    free_tier = AccountTier.objects.create(
        name="Free", max_members=3, max_polls=3, price_per_month=0, is_active=True
    )
    account = Account.objects.create(name="Pending")
    admin_user = get_user_model().objects.create_superuser(
        username="admin3", email="admin3@example.com", password="password"
    )

    client = APIClient()
    client.force_authenticate(admin_user)

    response = client.post(f"/api/accounts/{account.id}/approve/")
    assert response.status_code == status.HTTP_200_OK
    payload = response.json()
    assert payload["status"] == "approved"
    account.refresh_from_db()
    assert account.is_approved is True
    assert account.status_changed_by == admin_user
    assert account.subscription_status == "active"
    assert account.tier == free_tier
    log = (
        AuditLog.objects.filter(
            action="account_status_approved", object_id=str(account.id)
        )
        .order_by("-timestamp")
        .first()
    )
    assert log is not None
    assert "approved" in log.details
    subscription_log = (
        AuditLog.objects.filter(
            action="account_subscription_updated", object_id=str(account.id)
        )
        .order_by("-timestamp")
        .first()
    )
    assert subscription_log is not None
    assert "Free" in subscription_log.details


@pytest.mark.django_db
def test_admin_can_suspend_and_reinstate_account():
    account = Account.objects.create(name="Suspendable", status="approved")
    admin_user = get_user_model().objects.create_superuser(
        username="admin4", email="admin4@example.com", password="password"
    )

    client = APIClient()
    client.force_authenticate(admin_user)

    suspend_response = client.post(
        f"/api/accounts/{account.id}/suspend/",
        {"reason": "Violation"},
        format="json",
    )
    assert suspend_response.status_code == status.HTTP_200_OK
    account.refresh_from_db()
    assert account.is_suspended is True
    assert account.status_reason == "Violation"
    assert account.status_changed_by == admin_user
    suspended_log = (
        AuditLog.objects.filter(
            action="account_status_suspended", object_id=str(account.id)
        )
        .order_by("-timestamp")
        .first()
    )
    assert suspended_log is not None
    assert "Violation" in suspended_log.details

    reinstate_response = client.post(f"/api/accounts/{account.id}/reinstate/")
    assert reinstate_response.status_code == status.HTTP_200_OK
    account.refresh_from_db()
    assert account.is_suspended is False
    assert account.status_reason == ""
    reinstated_log = (
        AuditLog.objects.filter(
            action="account_status_approved", object_id=str(account.id)
        )
        .order_by("-timestamp")
        .first()
    )
    assert reinstated_log is not None


@pytest.mark.django_db
def test_non_staff_cannot_change_account_state():
    account = Account.objects.create(name="Pending Access")
    regular_user = get_user_model().objects.create_user(username="user", password="pw")

    client = APIClient()
    client.force_authenticate(regular_user)

    approve = client.post(f"/api/accounts/{account.id}/approve/")
    assert approve.status_code == status.HTTP_403_FORBIDDEN
    suspend = client.post(f"/api/accounts/{account.id}/suspend/", {"reason": ""})
    assert suspend.status_code == status.HTTP_403_FORBIDDEN
    assert (
        AuditLog.objects.filter(
            object_id=str(account.id), action__startswith="account_status"
        ).count()
        == 0
    )
