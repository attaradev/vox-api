import pytest
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APIClient

from accounts.models import Account, AccountTier
from polls.models import Choice, Poll


@pytest.mark.django_db
def test_create_poll_and_manage_choices():
    tier = AccountTier.objects.create(name="Growth", max_members=5, max_polls=5)
    account = Account.objects.create(name="Growth Org", tier=tier)
    user = get_user_model().objects.create_user(username="creator", password="pw")

    client = APIClient()
    client.force_authenticate(user)

    response = client.post(
        "/api/polls/",
        {"account": account.id, "title": "Lunch?", "description": "Pick lunch"},
        format="json",
    )
    assert response.status_code == status.HTTP_201_CREATED
    poll_id = response.json()["id"]

    choice_response = client.post(
        f"/api/polls/{poll_id}/choices/",
        {"text": "Pizza"},
        format="json",
    )
    assert (
        choice_response.status_code == status.HTTP_201_CREATED
    ), choice_response.json()
    assert choice_response.json()["text"] == "Pizza"

    list_response = client.get(f"/api/polls/{poll_id}/choices/")
    assert list_response.status_code == status.HTTP_200_OK
    assert len(list_response.json()) == 1


@pytest.mark.django_db
def test_vote_flow_requires_auth_and_respects_uniqueness():
    account = Account.objects.create(name="Vote Org")
    poll = Poll.objects.create(account=account, title="Best fruit")
    choice_one = Choice.objects.create(poll=poll, text="Apple")
    choice_two = Choice.objects.create(poll=poll, text="Banana")

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
    account = Account.objects.create(name="Status Org")
    poll = Poll.objects.create(account=account, title="Status change test")
    Choice.objects.create(poll=poll, text="Option A")

    user = get_user_model().objects.create_user(username="user", password="pw")
    client = APIClient()
    client.force_authenticate(user)

    response = client.patch(
        f"/api/polls/{poll.id}/status/",
        {"status": Poll.Status.ACTIVE},
        format="json",
    )
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["status"] == Poll.Status.ACTIVE
