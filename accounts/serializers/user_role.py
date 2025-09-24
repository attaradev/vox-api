"""
Serializers for account user roles.
"""

from django.contrib.auth import get_user_model
from rest_framework import serializers

from accounts.models.user_role import AccountUserRole


class AccountUserRoleSerializer(serializers.ModelSerializer):
    """Serializer for AccountUserRole model."""

    user = serializers.PrimaryKeyRelatedField(queryset=get_user_model().objects.all())
    account = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = AccountUserRole
        fields = ["id", "user", "account", "role", "joined_at"]
        read_only_fields = ["joined_at"]

    def validate(self, attrs):
        """Validate account and member limit for role assignment."""
        account = attrs.get("account") or self.context.get("account")
        if not account:
            raise serializers.ValidationError(
                {"account": "Account is required for assigning a role."}
            )
        attrs["account"] = account

        account = attrs["account"]
        if not account.can_add_member():
            raise serializers.ValidationError(
                {"account": "Member limit reached for this account tier."}
            )
        return super().validate(attrs)

    def create(self, validated_data):
        """Create a new AccountUserRole instance."""
        return AccountUserRole.objects.create(**validated_data)
