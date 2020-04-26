"""
Some helpers to deal with json in/json out
"""
import json
from functools import wraps

from jsonschema import validate, ValidationError

from django.conf import settings
from django.http import (
    JsonResponse,
    HttpResponse,
    HttpResponseBadRequest,
    HttpResponseServerError,
)
from django.utils.log import log_response

def api(in_schema=None, out_schema=None):
    """
    Decorator to make a view only accept and return a particular json schema. Usage::
        @json_api(JobRequest, JobResponse)
        def my_view(request, job_request):
            job_response = JobResponse()
            return job_response

    Both parameters are optional and if left out, no processing will be done for that
    direction.
    """
    def decorator(func):
        @wraps(func)
        def inner(request, *args, **kwargs):
            def log(title, response):
                log_response(
                    f'{title} ({request.method}): {request.path}',
                    response=response,
                    request=request,
                )

            json_request = None
            if in_schema:
                try:
                    json_request = json.loads(request.body)
                except json.JSONDecodeError:
                    response = HttpResponseBadRequest("Unable to decode json body")
                    log("Bad Request", response)
                    return response

                try:
                    validate(instance=json_request, schema=in_schema)
                except ValidationError as e:
                    response = HttpResponseBadRequest(json.dumps(
                        {'error': str(e.message)}
                    ))
                    log("Bad Request", response)
                    return response
            response = func(request, json_request, *args, **kwargs)
            if isinstance(response, HttpResponse):
                return response

            if out_schema:
                try:
                    validate(instance=response, schema=out_schema)
                except ValidationError as e:
                    if settings.DEBUG:
                        raise
                    response = HttpResponseServerError("Invalid response type")
                    log("Server Error", response)
                    return response
                return JsonResponse(response)
            else:
                return response

        return inner
    return decorator

