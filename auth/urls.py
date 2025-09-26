"""URL routes for authentication and user management endpoints."""

from django.urls import path

from .views import (
    PasswordResetConfirmView,
    PasswordResetRequestView,
    RegisterView,
    TokenView,
)

urlpatterns = [
    path("register/", RegisterView.as_view(), name="user_register"),
    path("login/", TokenView.as_view(), name="user_login"),
    path(
        "password/reset/request/",
        PasswordResetRequestView.as_view(),
        name="password_reset_request",
    ),
    path(
        "password/reset/confirm/",
        PasswordResetConfirmView.as_view(),
        name="password_reset_confirm",
    ),
]
