"""Views for password reset request and confirmation endpoints."""

from django.contrib.auth import get_user_model
from django.contrib.auth.tokens import PasswordResetTokenGenerator
from rest_framework import generics, permissions, serializers
from rest_framework.response import Response


class PasswordResetRequestSerializer(serializers.Serializer):
    """Request payload for initiating password reset."""

    email = serializers.EmailField()


class PasswordResetRequestView(generics.GenericAPIView):
    """API endpoint for requesting a password reset email."""

    serializer_class = PasswordResetRequestSerializer
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data["email"]
        user = get_user_model().objects.filter(email=email).first()
        if user:
            token = PasswordResetTokenGenerator().make_token(user)
            from django.conf import settings

            reset_url = (
                f"{settings.FRONTEND_URL}/reset-password?token={token}&uid={user.pk}"
            )
            from accounts.signals import password_reset_requested

            password_reset_requested.send(
                sender=self.__class__, email=email, reset_url=reset_url
            )

        return Response(
            {
                "detail": (
                    "If an account exists for that email, a reset link has been sent."
                )
            }
        )


class PasswordResetConfirmSerializer(serializers.Serializer):
    """Serializer for confirming password resets."""

    uid = serializers.CharField()
    token = serializers.CharField()
    new_password = serializers.CharField(write_only=True)


class PasswordResetConfirmView(generics.GenericAPIView):
    """API endpoint for confirming password reset and setting new password."""

    serializer_class = PasswordResetConfirmSerializer
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        uid = serializer.validated_data["uid"]
        token = serializer.validated_data["token"]
        new_password = serializer.validated_data["new_password"]
        user = get_user_model().objects.filter(pk=uid).first()
        if not user or not PasswordResetTokenGenerator().check_token(user, token):
            return Response({"detail": "Invalid token."}, status=400)
        user.set_password(new_password)
        user.save()
        return Response({"detail": "Password has been reset."})
