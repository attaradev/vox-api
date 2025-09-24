"""View for obtaining authentication tokens via API."""

from rest_framework import permissions
from rest_framework.authtoken.views import ObtainAuthToken


class TokenView(ObtainAuthToken):
    """API endpoint for obtaining an authentication token."""

    permission_classes = [permissions.AllowAny]
