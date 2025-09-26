"""ViewSet definitions for poll API endpoints."""

from django.db import transaction
from django.shortcuts import get_object_or_404
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response

from polls.models import Choice, Poll, Question, Vote
from polls.permissions import MANAGER_ROLES, IsAccountManagerOrReadOnly
from polls.serializers import (
    ChoiceCreateSerializer,
    ChoiceSerializer,
    PollSerializer,
    PollStatusUpdateSerializer,
    QuestionCreateSerializer,
    QuestionSerializer,
    VoteCastSerializer,
    VoteSerializer,
)


class PollQuestionPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = "page_size"


class PollViewSet(viewsets.ModelViewSet):
    """ViewSet for poll CRUD, status, choices, and voting endpoints."""

    serializer_class = PollSerializer
    permission_classes = [IsAccountManagerOrReadOnly]
    pagination_class = PollQuestionPagination

    def get_queryset(self):
        """Return queryset for polls, optionally filtered by account or status."""
        queryset = (
            Poll.objects.select_related("account")
            .prefetch_related("questions__choices")
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
        account = serializer.validated_data.get("account")
        request_user = getattr(self.request, "user", None)
        if not request_user or not request_user.is_authenticated:
            raise PermissionDenied("Authentication is required to create polls.")
        if not account.user_roles.filter(
            user=request_user, role__in=MANAGER_ROLES
        ).exists():
            raise PermissionDenied("You do not have permission to manage this account.")

        with transaction.atomic():
            poll = serializer.save()
            return poll

    def retrieve(self, request, *args, **kwargs):
        poll = self.get_object()
        questions_qs = poll.questions.prefetch_related("choices")
        if questions_qs.count() > 1 and self.paginator is not None:
            page = self.paginate_queryset(questions_qs)
            serializer = QuestionSerializer(page, many=True)
            poll_data = self.get_serializer(poll).data
            response = self.get_paginated_response(serializer.data)
            response.data["poll"] = poll_data
            return response

        serializer = self.get_serializer(poll)
        return Response(serializer.data)

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

    @action(detail=True, methods=["get", "post"], url_path="questions")
    def questions(self, request, pk=None):
        """List or create questions for a poll."""

        poll = self.get_object()
        if request.method.lower() == "get":
            serializer = QuestionSerializer(
                poll.questions.prefetch_related("choices"), many=True
            )
            return Response(serializer.data)

        self.check_object_permissions(request, poll)
        serializer = QuestionCreateSerializer(
            data=request.data,
            context={"poll": poll},
        )
        serializer.is_valid(raise_exception=True)
        question = serializer.save()
        return Response(
            QuestionSerializer(question).data, status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=["post"], url_path="questions/reorder")
    def reorder_questions(self, request, pk=None):
        """Reorder questions for a poll."""

        poll = self.get_object()
        self.check_object_permissions(request, poll)
        order = request.data.get("order", [])
        if not isinstance(order, list):
            return Response(
                {"order": "Provide a list of question IDs."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        with transaction.atomic():
            for index, question_id in enumerate(order):
                Question.objects.filter(poll=poll, id=question_id).update(order=index)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(
        detail=True,
        methods=["get", "post"],
        url_path="questions/(?P<question_id>[^/.]+)/choices",
    )
    def question_choices(self, request, pk=None, question_id=None):
        """List or create choices for a specific question."""

        poll = self.get_object()
        question = get_object_or_404(Question, poll=poll, pk=question_id)
        if request.method.lower() == "get":
            serializer = ChoiceSerializer(question.choices.all(), many=True)
            return Response(serializer.data)

        self.check_object_permissions(request, poll)
        serializer = ChoiceCreateSerializer(
            data=request.data,
            context={"question": question},
        )
        serializer.is_valid(raise_exception=True)
        choice = serializer.save()
        return Response(ChoiceSerializer(choice).data, status=status.HTTP_201_CREATED)

    @action(
        detail=True,
        methods=["post"],
        url_path="questions/(?P<question_id>[^/.]+)/choices/reorder",
    )
    def reorder_choices(self, request, pk=None, question_id=None):
        """Reorder choices within a question."""

        poll = self.get_object()
        question = get_object_or_404(Question, poll=poll, pk=question_id)
        self.check_object_permissions(request, poll)
        order = request.data.get("order", [])
        if not isinstance(order, list):
            return Response(
                {"order": "Provide a list of choice IDs."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        with transaction.atomic():
            for index, choice_id in enumerate(order):
                Choice.objects.filter(question=question, id=choice_id).update(
                    order=index
                )
        return Response(status=status.HTTP_204_NO_CONTENT)

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
        question = serializer.validated_data["question"]
        vote, created = Vote.objects.update_or_create(
            poll=poll,
            question=question,
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
        votes = poll.votes.select_related("choice", "question", "voter")
        serializer = VoteSerializer(votes, many=True)
        return Response(serializer.data)
