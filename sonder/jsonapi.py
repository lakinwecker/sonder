"""
Some helpers to deal with json in/json out
"""
import json
from functools import wraps

from jsonschema import validate, ValidationError

from django.conf import settings
from django.http import JsonResponse, HttpResponseBadRequest, HttpResponseServerError
from django.utils.log import log_response

def api(in_schema, out_schema):
    """
    Decorator to make a view only accept and return a particular json schema. Usage::
        @json_api(JobRequest, JobResponse)
        def my_view(request, job_request):
            job_response = JobResponse()
            return job_response
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

            try:
                in_instance = json.loads(request.body)
            except json.JSONDecodeError:
                response = HttpResponseBadRequest("Unable to decode json body")
                log("Bad Request", response)
                return response

            try:
                validate(instance=in_instance, schema=in_schema)
            except ValidationError as e:
                response = HttpResponseBadRequest(json.dumps(
                    {'error': str(e.message)}
                ))
                log("Bad Request", response)
                return response

            out_instance = func(request, in_instance, *args, **kwargs)
            try:
                validate(instance=out_instance, schema=out_schema)
            except ValidationError as e:
                if settings.DEBUG:
                    raise
                response = HttpResponseServerError("Invalid response type")
                log("Server Error", response)
                return response
            return JsonResponse(json.dumps(out_instance))
        return inner
    return decorator

