"""Views for user registration and serialization."""

from django.contrib.auth import get_user_model
from rest_framework import generics, permissions, serializers


class UserSerializer(serializers.ModelSerializer):
    """Serializer for user registration and creation."""

    class Meta:
        model = get_user_model()
        fields = ["id", "username", "email", "password"]
        extra_kwargs = {"password": {"write_only": True}}

    def create(self, validated_data):
        """Create a new user with validated data."""
        user = get_user_model().objects.create_user(
            username=validated_data["username"],
            email=validated_data.get("email", ""),
            password=validated_data["password"],
        )
        return user


class RegisterView(generics.CreateAPIView):
    """API endpoint for user registration."""

    queryset = get_user_model().objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.AllowAny]
