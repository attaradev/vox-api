"""Abstract base classes for billing providers."""

from abc import ABC, abstractmethod


class PaymentProvider(ABC):
    """Define the interface for payment provider integrations."""

    @abstractmethod
    def create_subscription(self, *args, **kwargs):
        """Create a subscription with the provider and return provider metadata."""

        raise NotImplementedError

    @abstractmethod
    def cancel_subscription(self, subscription_id):
        """Cancel an existing provider subscription."""

        raise NotImplementedError

    @abstractmethod
    def get_subscription_status(self, subscription_id):
        """Return the provider-reported status for a subscription."""

        raise NotImplementedError
