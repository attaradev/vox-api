import pytest
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError

from accounts.models import Account
from polls.models import Choice, Poll, Vote


@pytest.mark.django_db
def test_poll_status_transition_requires_choices():
    account = Account.objects.create(name="Org")
    poll = Poll.objects.create(account=account, title="Lunch options")

    with pytest.raises(ValidationError):
        poll.transition_status(Poll.Status.ACTIVE)

    Choice.objects.create(poll=poll, text="Pizza")
    poll.transition_status(Poll.Status.ACTIVE)
    assert poll.status == Poll.Status.ACTIVE
    assert poll.can_receive_votes()


@pytest.mark.django_db
def test_poll_cannot_reopen_after_closed():
    account = Account.objects.create(name="Org")
    poll = Poll.objects.create(account=account, title="Close me")
    Choice.objects.create(poll=poll, text="Option")
    poll.transition_status(Poll.Status.ACTIVE)
    poll.transition_status(Poll.Status.CLOSED)

    with pytest.raises(ValidationError):
        poll.transition_status(Poll.Status.ACTIVE)


@pytest.mark.django_db
def test_vote_validation_enforces_choice_relationship():
    account = Account.objects.create(name="Org")
    poll_one = Poll.objects.create(account=account, title="Poll 1")
    poll_two = Poll.objects.create(account=account, title="Poll 2")
    Choice.objects.create(poll=poll_one, text="Yes")
    choice_two = Choice.objects.create(poll=poll_two, text="No")

    poll_one.transition_status(Poll.Status.ACTIVE)
    user = get_user_model().objects.create_user(username="voter", password="pw")

    with pytest.raises(ValidationError):
        Vote.objects.create(poll=poll_one, choice=choice_two, voter=user)


@pytest.mark.django_db
def test_vote_requires_active_poll():
    account = Account.objects.create(name="Org")
    poll = Poll.objects.create(account=account, title="Inactive poll")
    choice = Choice.objects.create(poll=poll, text="Option")
    user = get_user_model().objects.create_user(username="voter", password="pw")

    with pytest.raises(ValidationError):
        Vote.objects.create(poll=poll, choice=choice, voter=user)
