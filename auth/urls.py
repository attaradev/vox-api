"""URL routes for authentication and user management endpoints."""

from django.urls import path

from .views import (
    PasswordResetConfirmView,
    PasswordResetRequestView,
    RegisterView,
    TokenView,
)

urlpatterns = [
    path("register/", RegisterView.as_view(), name="user-register"),
    path("login/", TokenView.as_view(), name="user-login"),
    path(
        "password-resets/request/",
        PasswordResetRequestView.as_view(),
        name="password-reset-request",
    ),
    path(
        "password-resets/confirm/",
        PasswordResetConfirmView.as_view(),
        name="password-reset-confirm",
    ),
]
