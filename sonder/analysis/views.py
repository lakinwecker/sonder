
from django.http import HttpResponse, Http404
from django.shortcuts import get_object_or_404
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST

from .. import jsonapi
from .schema import (
    FishnetRequest,
    FishnetJob,
)
from .models import (
    AnalysisSource,
    IrwinReportRequiredGame
)

@csrf_exempt
@require_POST
@jsonapi.api(FishnetRequest, FishnetJob)
def acquire(request, fishnet_request):
    analysis_source = get_object_or_404(
        AnalysisSource, secret_token=fishnet_request["fishnet"]["apikey"])
    if analysis_source.use_for_irwin:
        game = IrwinReportRequiredGame.assign_game(analysis_source)
        if game:
            return game.job()

    return HttpResponse(status=204)


@csrf_exempt
def status(request):
    # TODO: not sure if sonder needs to support this or not, probably not
    raise Http404

