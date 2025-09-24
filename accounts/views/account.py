"""Viewsets for account management and related resources."""

from django.shortcuts import get_object_or_404
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from accounts.models import (
    Account,
    AccountPermission,
    AccountTier,
    AccountUserRole,
    Permission,
    RolePermission,
)
from accounts.serializers import (
    AccountPermissionSerializer,
    AccountSerializer,
    AccountTierSerializer,
    AccountUserRoleSerializer,
    PermissionSerializer,
    RolePermissionSerializer,
)


class AccountViewSet(viewsets.ModelViewSet):
    """Manage account CRUD operations and related membership actions."""

    serializer_class = AccountSerializer
    permission_classes = [permissions.IsAdminUser]

    def get_queryset(self):
        """Return accounts with related tier and user role data."""

        return (
            Account.objects.select_related("tier")
            .prefetch_related("user_roles__user")
            .order_by("name")
        )

    def get_permissions(self):
        """Use read-only permissions for safe actions and admin otherwise."""

        if self.action in {"list", "retrieve"}:
            permission_classes = [permissions.IsAuthenticated]
        else:
            permission_classes = self.permission_classes
        return [permission() for permission in permission_classes]

    def perform_create(self, serializer):
        """Create an account and auto-assign the creator as owner."""

        account = serializer.save()
        if self.request.user.is_authenticated:
            AccountUserRole.objects.get_or_create(
                user=self.request.user, account=account, role="owner"
            )
        return account

    @action(
        detail=True,
        methods=["get", "post", "delete"],
        url_path="members",
        permission_classes=[permissions.IsAdminUser],
    )
    def members(self, request, pk=None):
        """Manage account membership list via nested routes."""

        account = self.get_object()
        if request.method.lower() == "get":
            serializer = AccountUserRoleSerializer(
                account.user_roles.select_related("user"), many=True
            )
            return Response(serializer.data)

        if request.method.lower() == "delete":
            user_id = request.data.get("user")
            if not user_id:
                return Response(
                    {"detail": "user is required"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            deleted, _ = account.user_roles.filter(user_id=user_id).delete()
            if not deleted:
                return Response(
                    {"detail": "Membership not found."},
                    status=status.HTTP_404_NOT_FOUND,
                )
            return Response(status=status.HTTP_204_NO_CONTENT)

        serializer = AccountUserRoleSerializer(
            data=request.data,
            context={"account": account},
        )
        serializer.is_valid(raise_exception=True)
        role = serializer.save()
        return Response(
            AccountUserRoleSerializer(role).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=["post"], url_path="set-tier")
    def set_tier(self, request, pk=None):
        """Assign a tier to the selected account."""

        account = self.get_object()
        tier_id = request.data.get("tier_id")
        tier = get_object_or_404(AccountTier, pk=tier_id)
        account.tier = tier
        account.save(update_fields=["tier"])
        return Response(AccountSerializer(account).data)


class AccountTierViewSet(viewsets.ModelViewSet):
    """Expose CRUD operations for account tiers."""

    queryset = AccountTier.objects.all().order_by("price_per_month")
    serializer_class = AccountTierSerializer
    permission_classes = [permissions.IsAdminUser]


class PermissionViewSet(viewsets.ModelViewSet):
    """Manage permission catalog entries."""

    queryset = Permission.objects.all().order_by("code")
    serializer_class = PermissionSerializer
    permission_classes = [permissions.IsAdminUser]


class AccountPermissionViewSet(viewsets.ModelViewSet):
    """CRUD viewset for account-specific permissions."""

    queryset = AccountPermission.objects.select_related("account", "permission")
    serializer_class = AccountPermissionSerializer
    permission_classes = [permissions.IsAdminUser]


class RolePermissionViewSet(viewsets.ModelViewSet):
    """Manage assignments between roles and permissions."""

    queryset = RolePermission.objects.select_related("permission")
    serializer_class = RolePermissionSerializer
    permission_classes = [permissions.IsAdminUser]
