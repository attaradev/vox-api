import pytest
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APIClient

from accounts.models import Account, AccountTier, AccountUserRole
from polls.models import Choice, Poll, Question


@pytest.mark.django_db
def test_create_poll_and_manage_choices():
    tier = AccountTier.objects.create(name="Growth", max_members=5, max_polls=5)
    account = Account.objects.create(
        name="Growth Org",
        tier=tier,
        status="approved",
        subscription_status="active",
    )
    user = get_user_model().objects.create_user(username="creator", password="pw")
    AccountUserRole.objects.create(account=account, user=user, role="owner")

    client = APIClient()
    client.force_authenticate(user)

    response = client.post(
        "/api/polls/",
        {"account": account.id, "title": "Lunch?", "description": "Pick lunch"},
        format="json",
    )
    assert response.status_code == status.HTTP_201_CREATED
    poll_id = response.json()["id"]

    question_response = client.post(
        f"/api/polls/{poll_id}/questions/",
        {"text": "What should we eat?"},
        format="json",
    )
    assert question_response.status_code == status.HTTP_201_CREATED
    question_id = question_response.json()["id"]

    choice_response = client.post(
        f"/api/polls/{poll_id}/questions/{question_id}/choices/",
        {"text": "Pizza"},
        format="json",
    )
    assert (
        choice_response.status_code == status.HTTP_201_CREATED
    ), choice_response.json()
    assert choice_response.json()["text"] == "Pizza"

    list_response = client.get(f"/api/polls/{poll_id}/questions/{question_id}/choices/")
    assert list_response.status_code == status.HTTP_200_OK
    assert len(list_response.json()) == 1


@pytest.mark.django_db
def test_choice_custom_fields():
    """Test that choices can have custom fields like name and image."""
    tier = AccountTier.objects.create(name="Growth", max_members=5, max_polls=5)
    account = Account.objects.create(
        name="Custom Fields Org",
        tier=tier,
        status="approved",
        subscription_status="active",
    )
    user = get_user_model().objects.create_user(username="creator", password="pw")
    AccountUserRole.objects.create(account=account, user=user, role="owner")

    client = APIClient()
    client.force_authenticate(user)

    # Create poll and question
    response = client.post(
        "/api/polls/",
        {
            "account": account.id,
            "title": "Candidate Poll",
            "description": "Vote for candidates",
        },
        format="json",
    )
    assert response.status_code == status.HTTP_201_CREATED
    poll_id = response.json()["id"]

    question_response = client.post(
        f"/api/polls/{poll_id}/questions/",
        {"text": "Who should be president?"},
        format="json",
    )
    assert question_response.status_code == status.HTTP_201_CREATED
    question_id = question_response.json()["id"]

    # Create choice with custom fields
    choice_data = {
        "text": "Candidate A",
        "custom_fields": {
            "name": "John Doe",
            "image": "https://example.com/john.jpg",
            "party": "Independent",
            "age": 45,
        },
    }
    choice_response = client.post(
        f"/api/polls/{poll_id}/questions/{question_id}/choices/",
        choice_data,
        format="json",
    )
    assert choice_response.status_code == status.HTTP_201_CREATED
    choice_data_response = choice_response.json()
    assert choice_data_response["text"] == "Candidate A"
    assert choice_data_response["custom_fields"]["name"] == "John Doe"
    assert (
        choice_data_response["custom_fields"]["image"] == "https://example.com/john.jpg"
    )
    assert choice_data_response["custom_fields"]["party"] == "Independent"
    assert choice_data_response["custom_fields"]["age"] == 45

    # Test retrieving the choice
    list_response = client.get(f"/api/polls/{poll_id}/questions/{question_id}/choices/")
    assert list_response.status_code == status.HTTP_200_OK
    choices = list_response.json()
    assert len(choices) == 1
    assert choices[0]["custom_fields"] == choice_data["custom_fields"]


@pytest.mark.django_db
def test_vote_flow_requires_auth_and_respects_uniqueness():
    account = Account.objects.create(
        name="Vote Org", status="approved", subscription_status="active"
    )
    poll = Poll.objects.create(account=account, title="Best fruit")
    question = Question.objects.create(poll=poll, text="Favourite fruit")
    choice_one = Choice.objects.create(question=question, text="Apple", order=0)
    choice_two = Choice.objects.create(question=question, text="Banana", order=1)

    poll.transition_status(Poll.Status.ACTIVE)

    voter = get_user_model().objects.create_user(username="voter", password="pw")
    client = APIClient()

    unauthenticated = client.post(
        f"/api/polls/{poll.id}/votes/",
        {"choice_id": choice_one.id},
        format="json",
    )
    assert unauthenticated.status_code == status.HTTP_401_UNAUTHORIZED

    client.force_authenticate(voter)
    first_vote = client.post(
        f"/api/polls/{poll.id}/votes/",
        {"choice_id": choice_one.id},
        format="json",
    )
    assert first_vote.status_code == status.HTTP_201_CREATED
    assert first_vote.json()["choice"] == choice_one.id

    updated_vote = client.post(
        f"/api/polls/{poll.id}/votes/",
        {"choice_id": choice_two.id},
        format="json",
    )
    assert updated_vote.status_code == status.HTTP_200_OK
    assert updated_vote.json()["choice"] == choice_two.id

    votes_list = client.get(f"/api/polls/{poll.id}/votes/")
    assert votes_list.status_code == status.HTTP_200_OK
    assert len(votes_list.json()) == 1
    assert votes_list.json()[0]["choice"] == choice_two.id


@pytest.mark.django_db
def test_update_poll_status_endpoint():
    account = Account.objects.create(
        name="Status Org", status="approved", subscription_status="active"
    )
    poll = Poll.objects.create(account=account, title="Status change test")
    question = Question.objects.create(poll=poll, text="First question")
    Choice.objects.create(question=question, text="Option A", order=0)

    user = get_user_model().objects.create_user(username="user", password="pw")
    AccountUserRole.objects.create(account=account, user=user, role="admin")
    client = APIClient()
    client.force_authenticate(user)

    response = client.patch(
        f"/api/polls/{poll.id}/status/",
        {"status": Poll.Status.ACTIVE},
        format="json",
    )
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["status"] == Poll.Status.ACTIVE


@pytest.mark.django_db
def test_poll_detail_pagination_for_questions():
    account = Account.objects.create(
        name="Multi", status="approved", subscription_status="active"
    )
    poll = Poll.objects.create(account=account, title="Multi question poll")
    for idx in range(3):
        question = Question.objects.create(poll=poll, text=f"Question {idx}", order=idx)
        Choice.objects.create(question=question, text=f"Choice {idx}", order=0)

    client = APIClient()
    response = client.get(f"/api/polls/{poll.id}/", {"page_size": 2})
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert "results" in data and "poll" in data
    assert len(data["results"]) == 2
    assert data["poll"]["title"] == "Multi question poll"
