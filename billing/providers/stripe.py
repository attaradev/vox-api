"""Stripe billing provider implementation."""

import stripe
from django.conf import settings

stripe.api_key = settings.STRIPE_SECRET_KEY


class StripeProvider:
    """Interact with Stripe APIs for billing operations."""

    def create_customer(self, email):
        """Create a Stripe customer for the supplied email."""

        return stripe.Customer.create(email=email)

    def create_subscription(self, customer_id, price_id):
        """Create a new Stripe subscription for the given customer."""

        return stripe.Subscription.create(
            customer=customer_id,
            items=[{"price": price_id}],
            payment_behavior="default_incomplete",
            expand=["latest_invoice.payment_intent"],
        )

    def cancel_subscription(self, subscription_id):
        """Cancel an existing Stripe subscription."""

        return stripe.Subscription.delete(subscription_id)

    def update_subscription(self, subscription_id, price_id):
        """Update the pricing details of an existing Stripe subscription."""

        return stripe.Subscription.modify(
            subscription_id,
            items=[{"price": price_id}],
        )

    def get_event(self, payload, sig_header):
        """Validate and parse a Stripe webhook payload."""

        return stripe.Webhook.construct_event(
            payload, sig_header, settings.STRIPE_WEBHOOK_SECRET
        )
