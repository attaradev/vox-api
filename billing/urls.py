"""URL routes for the billing application."""

from django.urls import path

from .views import (
    BillingAccountDetailView,
    BillingAccountListCreateView,
    CreateSubscriptionView,
    InvoiceDetailView,
    InvoiceListCreateView,
    PaymentDetailView,
    PaymentListCreateView,
    StripeWebhookView,
    SubscriptionDetailView,
    SubscriptionListCreateView,
    SubscriptionStatusView,
)

urlpatterns = [
    path(
        "accounts/",
        BillingAccountListCreateView.as_view(),
        name="account-list",
    ),
    path(
        "accounts/<int:pk>/",
        BillingAccountDetailView.as_view(),
        name="account-detail",
    ),
    path("invoices/", InvoiceListCreateView.as_view(), name="invoice-list"),
    path("invoices/<int:pk>/", InvoiceDetailView.as_view(), name="invoice-detail"),
    path("payments/", PaymentListCreateView.as_view(), name="payment-list"),
    path("payments/<int:pk>/", PaymentDetailView.as_view(), name="payment-detail"),
    path(
        "subscriptions/", SubscriptionListCreateView.as_view(), name="subscription-list"
    ),
    path(
        "subscriptions/<int:pk>/",
        SubscriptionDetailView.as_view(),
        name="subscription-detail",
    ),
    path("webhooks/stripe/", StripeWebhookView.as_view(), name="stripe-webhook"),
    path(
        "subscriptions/<int:account_id>/status/",
        SubscriptionStatusView.as_view(),
        name="subscription-status",
    ),
    path(
        "subscriptions/<int:account_id>/create/",
        CreateSubscriptionView.as_view(),
        name="subscription-create",
    ),
]
