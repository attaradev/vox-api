import django.db.models.deletion
from django.db import migrations, models


def create_questions_and_assign(apps, schema_editor):
    Poll = apps.get_model("polls", "Poll")
    Question = apps.get_model("polls", "Question")
    Choice = apps.get_model("polls", "Choice")
    Vote = apps.get_model("polls", "Vote")

    for poll in Poll.objects.all():
        question = Question.objects.create(
            poll=poll,
            text=poll.title or "Question",
            order=0,
            is_required=True,
        )

        for index, choice in enumerate(
            Choice.objects.filter(poll=poll).order_by("created_at", "id")
        ):
            choice.question = question
            choice.order = index
            choice.save(update_fields=["question", "order"])

        Vote.objects.filter(poll=poll).update(question=question)


def noop_reverse(apps, schema_editor):
    """No-op reverse migration."""


class Migration(migrations.Migration):

    dependencies = [
        ("polls", "0001_initial"),
    ]

    operations = [
        migrations.CreateModel(
            name="Question",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("text", models.CharField(max_length=512)),
                ("order", models.PositiveIntegerField(default=0)),
                ("is_required", models.BooleanField(default=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "poll",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="questions",
                        to="polls.poll",
                    ),
                ),
            ],
            options={
                "ordering": ["order", "id"],
                "unique_together": {("poll", "order")},
            },
        ),
        migrations.RemoveConstraint(
            model_name="choice",
            name="choice_unique_per_poll",
        ),
        migrations.AddField(
            model_name="poll",
            name="require_all_questions",
            field=models.BooleanField(
                default=False,
                help_text="Require answers to all questions when voting",
            ),
        ),
        migrations.AddField(
            model_name="choice",
            name="order",
            field=models.PositiveIntegerField(default=0),
        ),
        migrations.AddField(
            model_name="choice",
            name="question",
            field=models.ForeignKey(
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name="choices",
                to="polls.question",
            ),
        ),
        migrations.AddField(
            model_name="vote",
            name="question",
            field=models.ForeignKey(
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name="votes",
                to="polls.question",
            ),
        ),
        migrations.RemoveConstraint(
            model_name="vote",
            name="unique_vote_per_poll_for_user",
        ),
        migrations.RunPython(create_questions_and_assign, noop_reverse),
        migrations.AlterField(
            model_name="choice",
            name="question",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="choices",
                to="polls.question",
            ),
        ),
        migrations.AlterField(
            model_name="vote",
            name="question",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="votes",
                to="polls.question",
            ),
        ),
        migrations.AddConstraint(
            model_name="choice",
            constraint=models.UniqueConstraint(
                fields=("question", "text"), name="choice_unique_per_question"
            ),
        ),
        migrations.AddConstraint(
            model_name="choice",
            constraint=models.UniqueConstraint(
                fields=("question", "order"), name="choice_order_unique_per_question"
            ),
        ),
        migrations.AddConstraint(
            model_name="vote",
            constraint=models.UniqueConstraint(
                fields=("question", "voter"),
                name="unique_vote_per_question_for_user",
            ),
        ),
    ]
