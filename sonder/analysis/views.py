
from django.http import HttpResponse
from django.shortcuts import render, get_object_or_404
from django.views.decorators.http import require_POST

from . import json
from .schema import (
    FishnetRequest,
    FishnetJob,
)
from .models import (
    AnalysisSource,
    IrwinReportRequiredGame
)

@require_POST
@json.api(FishnetRequest, FishnetJob)
def acquire(request, fishnet_request):
    analysis_source = get_object_or_404(
        AnalysisSource, secret_token=fishnet_request["fishnet"]["apikey"])
    if analysis_source.use_for_irwin:
        game = IrwinReportRequiredGame.assign_game(analysis_source)
        if game:
            return game.job()

    return HttpResponse('foo')
