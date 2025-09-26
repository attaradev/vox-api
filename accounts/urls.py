from rest_framework.routers import DefaultRouter

from .views import (
    AccountPermissionViewSet,
    AccountTierViewSet,
    AccountViewSet,
    PermissionViewSet,
    RolePermissionViewSet,
)

router = DefaultRouter()
router.register(r"accounts", AccountViewSet, basename="account")
router.register(r"tiers", AccountTierViewSet, basename="account_tier")
router.register(r"permissions", PermissionViewSet, basename="permission")
router.register(
    r"account_permissions", AccountPermissionViewSet, basename="account_permission"
)
router.register(r"role_permissions", RolePermissionViewSet, basename="role_permission")

urlpatterns = router.urls
