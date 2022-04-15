from pprint import pprint

from django.http import HttpResponse, Http404
from django.shortcuts import get_object_or_404
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST

from .. import jsonapi
from .schema import FishnetRequest, FishnetJob, FishnetAnalysis
from .models import AnalysisSource, IrwinReportRequiredGame, GameAnalysis

def no_content():
    return HttpResponse(status=204)

def bad_request():
    return HttpResponse(status=400)

def source_from_request(analysis):
    return get_object_or_404(AnalysisSource, secret_token=analysis["fishnet"]["apikey"])


def required_game_from_request(work_id, source=None):
    [irwin, pk] = work_id.split("-", 1)
    if irwin != "irwin":
        return bad_request()
    kwargs = {"pk": pk}
    if source:
        kwargs["owner"] = source
    return get_object_or_404(IrwinReportRequiredGame, **kwargs)


def job_for_source(analysis_source):
    if analysis_source.use_for_irwin:
        game = IrwinReportRequiredGame.assign_game(analysis_source)
        if game:
            return game.job()

    return no_content()


@csrf_exempt
@require_POST
@jsonapi.api(FishnetRequest, FishnetJob, status=202)
def acquire(request, fishnet_request):
    analysis_source = source_from_request(fishnet_request)
    return job_for_source(analysis_source)


@csrf_exempt
@require_POST
@jsonapi.api(FishnetAnalysis, FishnetJob, status=202)
def analysis(request, analysis, work_id):
    analysis_source = source_from_request(analysis)
    required_game = required_game_from_request(work_id, analysis_source)
    should_stop = request.GET.get("stop", "false") == "true"
    is_completed = False
    # TODO: verify that we have the number of pvs that we wanted.
    game_analysis, _ = GameAnalysis.objects.get_or_create(
        game=required_game.game,
        source=analysis_source,
        defaults={"stockfish_version": analysis["stockfish"]["name"],},
    )
    pprint(analysis['analysis'])
    game_analysis.analysis = analysis["analysis"]
    game_analysis.update_complete(required_game)
    game_analysis.save()
    is_completed = required_game.is_completed = game_analysis.is_completed
    if is_completed:
        required_game.owner = None
    required_game.save()

    wants_next_job = is_completed and not should_stop
    return (
        job_for_source(analysis_source) if wants_next_job else no_content()
    )


@csrf_exempt
@require_POST
@jsonapi.api(FishnetRequest, status=202)
def abort(request, analysis, work_id):
    analysis_source = source_from_request(analysis)
    required_game = required_game_from_request(work_id, analysis_source)

    IrwinReportRequiredGame.objects.filter(pk=required_game.pk).update(owner=None)

    return no_content()


@csrf_exempt
def status(request):
    # TODO: not sure if sonder needs to support this or not, probably not
    raise Http404
