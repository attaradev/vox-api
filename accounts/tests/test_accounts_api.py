import pytest
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APIClient

from accounts.models import Account, AccountTier


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
    account = Account.objects.create(name="Tier Switch", tier=tier_a)
    admin_user = get_user_model().objects.create_superuser(
        username="admin", email="admin@example.com", password="password"
    )

    client = APIClient()
    client.force_authenticate(admin_user)
    response = client.post(
        f"/api/accounts/{account.id}/set-tier/",
        {"tier_id": tier_b.id},
        format="json",
    )
    assert response.status_code == status.HTTP_200_OK
    account.refresh_from_db()
    assert account.tier == tier_b
