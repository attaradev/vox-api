import json
import os

_BOTO3_IMPORT_ERROR = None

try:
    import boto3
    from botocore.exceptions import ClientError
except ImportError as exc:  # pragma: no cover - only triggered when boto3 missing
    boto3 = None
    ClientError = Exception  # type: ignore[assignment]
    _BOTO3_IMPORT_ERROR = exc


def get_aws_secret(secret_name, region_name=None):
    if boto3 is None:
        raise RuntimeError(
            "boto3 is required to load secrets from AWS Secrets Manager."
        ) from _BOTO3_IMPORT_ERROR

    region_name = region_name or os.environ.get("AWS_REGION", "us-east-1")
    session = boto3.session.Session()
    client = session.client(
        service_name="secretsmanager",
        region_name=region_name,
    )
    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
    except ClientError as e:
        raise RuntimeError(f"Unable to fetch secret {secret_name}: {e}")
    secret = get_secret_value_response.get("SecretString")
    if secret:
        return json.loads(secret)
    raise RuntimeError(f"Secret {secret_name} not found or empty.")
