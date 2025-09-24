import pytest
from django.db import IntegrityError

from accounts.models import Account, AccountPermission, AccountTier, Permission
from accounts.serializers.account import AccountSerializer
from polls.models import Poll


@pytest.mark.django_db
def test_account_creation_without_tier():
    account = Account.objects.create(name="TestOrg")
    assert account.name == "TestOrg"
    assert account.tier is None


@pytest.mark.django_db
def test_account_tier_limits_enforced():
    tier = AccountTier.objects.create(name="Pro", max_members=1, max_polls=1)
    account = Account.objects.create(name="TierOrg", tier=tier)

    assert account.can_add_member() is True
    assert account.can_add_poll() is True

    Poll.objects.create(account=account, title="Poll 1")
    assert account.can_add_poll() is False


@pytest.mark.django_db
def test_permission_assignment():
    account = Account.objects.create(name="PermOrg")
    perm = Permission.objects.create(code="poll_create")
    acc_perm = AccountPermission.objects.create(account=account, permission=perm)
    assert acc_perm.enabled is True
    assert acc_perm.permission.code == "poll_create"


@pytest.mark.django_db
def test_duplicate_account_name():
    Account.objects.create(name="DupOrg")
    with pytest.raises(IntegrityError):
        Account.objects.create(name="DupOrg")


@pytest.mark.django_db
def test_invalid_tier_rejected_by_serializer():
    serializer = AccountSerializer(data={"name": "BadTierOrg", "tier": 9999})
    assert serializer.is_valid() is False
    assert "tier" in serializer.errors
