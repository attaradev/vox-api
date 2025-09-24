from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import exception_handler


def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is not None:
        # Add a consistent error structure
        response.data = {
            "error": True,
            "detail": response.data,
            "status_code": response.status_code,
        }
    else:
        # Handle non-DRF exceptions
        return Response(
            {
                "error": True,
                "detail": str(exc),
                "status_code": status.HTTP_500_INTERNAL_SERVER_ERROR,
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )
    return response
