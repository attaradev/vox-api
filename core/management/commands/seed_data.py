"""
Management command to seed the database with sample data for development.
"""

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.utils import timezone

from accounts.models import Account, AccountTier, AccountUserRole
from polls.models import Choice, Poll, Question, Vote


class Command(BaseCommand):
    """Seed the database with sample data."""

    help = "Seed the database with sample data for development"

    def handle(self, *args, **options):
        """Execute the seed command."""
        self.stdout.write("Seeding database with sample data...")

        # Create account tiers
        self.create_tiers()

        # Create sample accounts
        self.create_accounts()

        # Create sample users and assign roles
        self.create_users()

        # Create sample polls
        self.create_polls()

        # Create sample votes
        self.create_votes()

        self.stdout.write(
            self.style.SUCCESS("Successfully seeded database with sample data!")
        )

    def create_tiers(self):
        """Create account tiers."""
        self.stdout.write("Creating account tiers...")

        tiers_data = [
            {
                "name": "Free",
                "description": "Basic tier for small teams",
                "max_members": 5,
                "max_polls": 3,
                "price_per_month": 0.00,
                "feature_flags": {"basic_analytics": True},
            },
            {
                "name": "Pro",
                "description": "Professional tier for growing teams",
                "max_members": 25,
                "max_polls": 50,
                "price_per_month": 29.99,
                "feature_flags": {
                    "basic_analytics": True,
                    "advanced_analytics": True,
                    "custom_branding": True,
                },
            },
            {
                "name": "Enterprise",
                "description": "Enterprise tier for large organizations",
                "max_members": 100,
                "max_polls": 500,
                "price_per_month": 99.99,
                "feature_flags": {
                    "basic_analytics": True,
                    "advanced_analytics": True,
                    "custom_branding": True,
                    "api_access": True,
                    "priority_support": True,
                },
            },
        ]

        for tier_data in tiers_data:
            tier, created = AccountTier.objects.get_or_create(
                name=tier_data["name"],
                defaults=tier_data,
            )
            if created:
                self.stdout.write(f"  Created tier: {tier.name}")
            else:
                self.stdout.write(f"  Tier already exists: {tier.name}")

    def create_accounts(self):
        """Create sample accounts."""
        self.stdout.write("Creating sample accounts...")

        free_tier = AccountTier.objects.get(name="Free")
        pro_tier = AccountTier.objects.get(name="Pro")
        enterprise_tier = AccountTier.objects.get(name="Enterprise")

        accounts_data = [
            {
                "name": "Acme Corp",
                "tier": pro_tier,
                "subscription_status": "active",
                "status": "approved",
                "billing_email": "billing@acme.com",
            },
            {
                "name": "StartupXYZ",
                "tier": free_tier,
                "subscription_status": "trial",
                "status": "approved",
                "billing_email": "admin@startupxyz.com",
            },
            {
                "name": "TechGiant Inc",
                "tier": enterprise_tier,
                "subscription_status": "active",
                "status": "approved",
                "billing_email": "finance@techgiant.com",
            },
            {
                "name": "LocalCafe",
                "tier": free_tier,
                "subscription_status": "trial",
                "status": "pending",
                "billing_email": "owner@localcafe.com",
            },
        ]

        for account_data in accounts_data:
            account, created = Account.objects.get_or_create(
                name=account_data["name"],
                defaults=account_data,
            )
            if created:
                self.stdout.write(f"  Created account: {account.name}")
            else:
                self.stdout.write(f"  Account already exists: {account.name}")

    def create_users(self):
        """Create sample users and assign roles."""
        self.stdout.write("Creating sample users and roles...")

        User = get_user_model()

        acme_account = Account.objects.get(name="Acme Corp")
        startup_account = Account.objects.get(name="StartupXYZ")
        techgiant_account = Account.objects.get(name="TechGiant Inc")

        users_data = [
            {
                "username": "alice_smith",
                "email": "alice@acme.com",
                "first_name": "Alice",
                "last_name": "Smith",
                "account": acme_account,
                "role": "owner",
            },
            {
                "username": "bob_jones",
                "email": "bob@acme.com",
                "first_name": "Bob",
                "last_name": "Jones",
                "account": acme_account,
                "role": "admin",
            },
            {
                "username": "carol_davis",
                "email": "carol@acme.com",
                "first_name": "Carol",
                "last_name": "Davis",
                "account": acme_account,
                "role": "member",
            },
            {
                "username": "diana_prince",
                "email": "diana@startupxyz.com",
                "first_name": "Diana",
                "last_name": "Prince",
                "account": startup_account,
                "role": "owner",
            },
            {
                "username": "eve_adams",
                "email": "eve@techgiant.com",
                "first_name": "Eve",
                "last_name": "Adams",
                "account": techgiant_account,
                "role": "owner",
            },
            {
                "username": "frank_miller",
                "email": "frank@techgiant.com",
                "first_name": "Frank",
                "last_name": "Miller",
                "account": techgiant_account,
                "role": "admin",
            },
        ]

        for user_data in users_data:
            account = user_data.pop("account")
            role = user_data.pop("role")

            user, created = User.objects.get_or_create(
                username=user_data["username"],
                defaults=user_data,
            )
            if created:
                user.set_password("password123")
                user.save()
                self.stdout.write(f"  Created user: {user.username}")

            # Assign role
            role_obj, role_created = AccountUserRole.objects.get_or_create(
                user=user,
                account=account,
                defaults={"role": role},
            )
            if role_created:
                self.stdout.write(f"    Assigned {role} role in {account.name}")

    def create_polls(self):
        """Create sample polls with questions and choices."""
        self.stdout.write("Creating sample polls...")

        acme_account = Account.objects.get(name="Acme Corp")
        startup_account = Account.objects.get(name="StartupXYZ")
        techgiant_account = Account.objects.get(name="TechGiant Inc")

        polls_data = [
            {
                "account": acme_account,
                "title": "Q4 Team Building Event",
                "description": "Help us plan the best team building event for Q4!",
                "status": "active",
                "published_at": timezone.now(),
                "questions": [
                    {
                        "text": "Which type of team building activity would you "
                        "prefer?",
                        "order": 1,
                        "is_required": True,
                        "choices": [
                            "Outdoor adventure (hiking, rock climbing)",
                            "Indoor workshop (team building games, workshops)",
                            "Virtual event (online games, remote activities)",
                            "Food and drink focused (team dinner, brewery tour)",
                        ],
                    },
                    {
                        "text": "What is your availability for the event?",
                        "order": 2,
                        "is_required": True,
                        "choices": [
                            "Weekdays after 5 PM",
                            "Weekends (Saturday or Sunday)",
                            "Either weekday or weekend",
                            "Limited availability - need more details",
                        ],
                    },
                ],
            },
            {
                "account": startup_account,
                "title": "Product Launch Feedback",
                "description": "We'd love your feedback on our upcoming product "
                "launch!",
                "status": "active",
                "published_at": timezone.now(),
                "questions": [
                    {
                        "text": "How excited are you about the new product "
                        "features?",
                        "order": 1,
                        "is_required": True,
                        "choices": [
                            "Very excited - can't wait!",
                            "Somewhat excited",
                            "Neutral",
                            "Not very excited",
                            "Not excited at all",
                        ],
                    },
                ],
            },
            {
                "account": techgiant_account,
                "title": "Office Space Preferences",
                "description": "Survey to understand team preferences for our new "
                "office space",
                "status": "active",
                "published_at": timezone.now(),
                "questions": [
                    {
                        "text": "Which office layout do you prefer?",
                        "order": 1,
                        "is_required": True,
                        "choices": [
                            "Open floor plan",
                            "Cubicles with some privacy",
                            "Private offices for everyone",
                            "Hybrid (mix of open and private spaces)",
                        ],
                    },
                    {
                        "text": "What amenities are most important to you?",
                        "order": 2,
                        "is_required": False,
                        "choices": [
                            "Modern kitchen and break areas",
                            "Fitness center or gym",
                            "Quiet rooms for focused work",
                            "Outdoor spaces (patio, garden)",
                            "On-site childcare",
                        ],
                    },
                ],
            },
        ]

        for poll_data in polls_data:
            questions_data = poll_data.pop("questions")
            poll, created = Poll.objects.get_or_create(
                account=poll_data["account"],
                title=poll_data["title"],
                defaults=poll_data,
            )
            if created:
                self.stdout.write(f"  Created poll: {poll.title}")

                # Create questions and choices
                for question_data in questions_data:
                    choices_data = question_data.pop("choices")
                    question = Question.objects.create(poll=poll, **question_data)
                    self.stdout.write(f"    Created question: {question.text[:50]}...")

                    for i, choice_text in enumerate(choices_data):
                        Choice.objects.create(
                            question=question,
                            text=choice_text,
                            order=i + 1,
                        )
                    self.stdout.write(f"      Added {len(choices_data)} choices")

    def create_votes(self):
        """Create sample votes for the polls."""
        self.stdout.write("Creating sample votes...")

        # Get users and polls
        alice = get_user_model().objects.get(username="alice_smith")
        bob = get_user_model().objects.get(username="bob_jones")
        carol = get_user_model().objects.get(username="carol_davis")
        diana = get_user_model().objects.get(username="diana_prince")
        eve = get_user_model().objects.get(username="eve_adams")
        frank = get_user_model().objects.get(username="frank_miller")

        acme_poll = Poll.objects.get(title="Q4 Team Building Event")
        startup_poll = Poll.objects.get(title="Product Launch Feedback")
        techgiant_poll = Poll.objects.get(title="Office Space Preferences")

        # Votes for Acme poll
        acme_questions = list(acme_poll.questions.all())
        if len(acme_questions) >= 2:
            # Alice's votes
            Vote.objects.get_or_create(
                question=acme_questions[0],
                voter=alice,
                defaults={
                    "choice": acme_questions[0]
                    .choices.filter(text__icontains="outdoor")
                    .first()
                },
            )
            Vote.objects.get_or_create(
                question=acme_questions[1],
                voter=alice,
                defaults={
                    "choice": acme_questions[1]
                    .choices.filter(text__icontains="weekends")
                    .first()
                },
            )

            # Bob's votes
            Vote.objects.get_or_create(
                question=acme_questions[0],
                voter=bob,
                defaults={
                    "choice": acme_questions[0]
                    .choices.filter(text__icontains="workshop")
                    .first()
                },
            )
            Vote.objects.get_or_create(
                question=acme_questions[1],
                voter=bob,
                defaults={
                    "choice": acme_questions[1]
                    .choices.filter(text__icontains="weekday")
                    .first()
                },
            )

            # Carol's votes
            Vote.objects.get_or_create(
                question=acme_questions[0],
                voter=carol,
                defaults={
                    "choice": acme_questions[0]
                    .choices.filter(text__icontains="food")
                    .first()
                },
            )
            Vote.objects.get_or_create(
                question=acme_questions[1],
                voter=carol,
                defaults={
                    "choice": acme_questions[1]
                    .choices.filter(text__icontains="either")
                    .first()
                },
            )

        # Votes for startup poll
        startup_questions = list(startup_poll.questions.all())
        if startup_questions:
            Vote.objects.get_or_create(
                question=startup_questions[0],
                voter=diana,
                defaults={
                    "choice": startup_questions[0]
                    .choices.filter(text__icontains="very excited")
                    .first()
                },
            )

        # Votes for techgiant poll
        techgiant_questions = list(techgiant_poll.questions.all())
        if len(techgiant_questions) >= 2:
            # Eve's votes
            Vote.objects.get_or_create(
                question=techgiant_questions[0],
                voter=eve,
                defaults={
                    "choice": techgiant_questions[0]
                    .choices.filter(text__icontains="hybrid")
                    .first()
                },
            )
            Vote.objects.get_or_create(
                question=techgiant_questions[1],
                voter=eve,
                defaults={
                    "choice": techgiant_questions[1]
                    .choices.filter(text__icontains="kitchen")
                    .first()
                },
            )

            # Frank's votes
            Vote.objects.get_or_create(
                question=techgiant_questions[0],
                voter=frank,
                defaults={
                    "choice": techgiant_questions[0]
                    .choices.filter(text__icontains="open")
                    .first()
                },
            )
            Vote.objects.get_or_create(
                question=techgiant_questions[1],
                voter=frank,
                defaults={
                    "choice": techgiant_questions[1]
                    .choices.filter(text__icontains="fitness")
                    .first()
                },
            )

        self.stdout.write("  Created sample votes for demonstration")
