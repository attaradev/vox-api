"""Custom permission classes for poll access control."""

from rest_framework.permissions import SAFE_METHODS, BasePermission

MANAGER_ROLES = {"owner", "admin"}


class IsAccountManagerOrReadOnly(BasePermission):
    """Allow safe methods for everyone and restrict writes to account managers."""

    def has_permission(self, request, view):
        if request.method in SAFE_METHODS:
            return True
        return request.user and request.user.is_authenticated

    def has_object_permission(self, request, view, obj):
        if request.method in SAFE_METHODS:
            return True
        user = request.user
        if not user or not user.is_authenticated:
            return False
        account = getattr(obj, "account", None)
        if account is None:
            return False
        return account.user_roles.filter(user=user, role__in=MANAGER_ROLES).exists()
