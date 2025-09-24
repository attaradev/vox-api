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
router.register(r"tiers", AccountTierViewSet, basename="account-tier")
router.register(r"permissions", PermissionViewSet, basename="permission")
router.register(
    r"account-permissions", AccountPermissionViewSet, basename="account-permission"
)
router.register(r"role-permissions", RolePermissionViewSet, basename="role-permission")

urlpatterns = router.urls
