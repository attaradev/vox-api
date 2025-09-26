import json
import os

import boto3
from botocore.exceptions import ClientError


def get_aws_secret(secret_name, region_name=None):
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
