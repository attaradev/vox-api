"""Views for password reset request and confirmation endpoints."""

from django.contrib.auth import get_user_model
from django.contrib.auth.tokens import PasswordResetTokenGenerator
from rest_framework import generics, permissions, serializers
from rest_framework.response import Response


class PasswordResetRequestView(generics.GenericAPIView):
    """API endpoint for requesting a password reset email."""

    serializer_class = serializers.Serializer
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get("email")
        user = get_user_model().objects.filter(email=email).first()
        if not user:
            return Response({"detail": "User not found."}, status=404)
        token = PasswordResetTokenGenerator().make_token(user)
        from django.conf import settings

        reset_url = (
            f"{settings.FRONTEND_URL}/reset-password?token={token}&uid={user.pk}"
        )
        from accounts.signals import password_reset_requested

        password_reset_requested.send(
            sender=self.__class__, email=email, reset_url=reset_url
        )
        return Response({"detail": "Password reset email sent."})


class PasswordResetConfirmView(generics.GenericAPIView):
    """API endpoint for confirming password reset and setting new password."""

    serializer_class = serializers.Serializer
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        uid = request.data.get("uid")
        token = request.data.get("token")
        new_password = request.data.get("new_password")
        user = get_user_model().objects.filter(pk=uid).first()
        if not user or not PasswordResetTokenGenerator().check_token(user, token):
            return Response({"detail": "Invalid token."}, status=400)
        user.set_password(new_password)
        user.save()
        return Response({"detail": "Password has been reset."})
