"""
Serializers for account and role permissions.
"""

from rest_framework import serializers

from accounts.models.account import Account
from accounts.models.permission import AccountPermission, Permission, RolePermission


class PermissionSerializer(serializers.ModelSerializer):
    """Serializer for Permission model."""

    class Meta:
        model = Permission
        fields = ["id", "code", "description"]


class AccountPermissionSerializer(serializers.ModelSerializer):
    """Serializer for AccountPermission model."""

    account = serializers.PrimaryKeyRelatedField(queryset=Account.objects.all())
    permission = serializers.PrimaryKeyRelatedField(queryset=Permission.objects.all())

    class Meta:
        model = AccountPermission
        fields = ["id", "account", "permission", "enabled"]


class RolePermissionSerializer(serializers.ModelSerializer):
    """Serializer for RolePermission model."""

    permission = serializers.PrimaryKeyRelatedField(queryset=Permission.objects.all())

    class Meta:
        model = RolePermission
        fields = ["id", "role", "permission", "enabled"]
