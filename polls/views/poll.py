"""ViewSet definitions for poll API endpoints."""

from django.db import transaction
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from polls.models import Choice, Poll, Vote
from polls.serializers import (
    ChoiceCreateSerializer,
    ChoiceSerializer,
    PollSerializer,
    PollStatusUpdateSerializer,
    VoteCastSerializer,
    VoteSerializer,
)


class PollViewSet(viewsets.ModelViewSet):
    """ViewSet for poll CRUD, status, choices, and voting endpoints."""

    serializer_class = PollSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        """Return queryset for polls, optionally filtered by account or status."""
        queryset = (
            Poll.objects.select_related("account")
            .prefetch_related("choices")
            .order_by("-created_at")
        )
        account_id = self.request.query_params.get("account")
        status_filter = self.request.query_params.get("status")
        if account_id:
            queryset = queryset.filter(account_id=account_id)
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        return queryset

    def perform_create(self, serializer):
        """Create a poll instance atomically."""
        with transaction.atomic():
            poll = serializer.save()
            return poll

    @action(detail=True, methods=["patch"], url_path="status")
    def update_status(self, request, pk=None):
        """Update the status of a poll."""
        poll = self.get_object()
        serializer = PollStatusUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        poll.transition_status(serializer.validated_data["status"])
        return Response(
            PollSerializer(poll, context=self.get_serializer_context()).data
        )

    @action(detail=True, methods=["get", "post"], url_path="choices")
    def poll_choices(self, request, pk=None):
        """List or create choices for a poll."""
        poll = self.get_object()
        if request.method.lower() == "get":
            serializer = ChoiceSerializer(poll.choices.all(), many=True)
            return Response(serializer.data)

        self.check_object_permissions(request, poll)
        serializer = ChoiceCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        choice = Choice.objects.create(poll=poll, **serializer.validated_data)
        return Response(ChoiceSerializer(choice).data, status=status.HTTP_201_CREATED)

    @action(
        detail=True,
        methods=["post"],
        url_path="votes",
        permission_classes=[permissions.IsAuthenticated],
    )
    def cast_vote(self, request, pk=None):
        """Cast a vote for a poll choice."""
        poll = self.get_object()
        serializer = VoteCastSerializer(data=request.data, context={"poll": poll})
        serializer.is_valid(raise_exception=True)
        choice = serializer.validated_data["choice"]
        vote, created = Vote.objects.update_or_create(
            poll=poll,
            voter=request.user,
            defaults={"choice": choice},
        )
        response_serializer = VoteSerializer(vote)
        status_code = status.HTTP_201_CREATED if created else status.HTTP_200_OK
        return Response(response_serializer.data, status=status_code)

    @cast_vote.mapping.get
    def list_votes(self, request, pk=None):
        """List all votes for a poll."""
        poll = self.get_object()
        votes = poll.votes.select_related("choice", "voter")
        serializer = VoteSerializer(votes, many=True)
        return Response(serializer.data)
