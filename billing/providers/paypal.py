"""Simplified PayPal provider stub used for testing flows."""


class PayPalProvider:
    """Mimic the interactions expected from a PayPal integration."""

    def create_subscription(self, email):
        """Return a fake subscription payload for the provided email."""

        return {"id": "paypal-sub-123", "status": "ACTIVE"}

    def cancel_subscription(self, subscription_id):
        """Return a canned response representing subscription cancellation."""

        return {"id": subscription_id, "status": "CANCELLED"}

    def get_subscription_status(self, subscription_id):
        """Return a fixed subscription status for demonstration purposes."""

        return {"id": subscription_id, "status": "ACTIVE"}
