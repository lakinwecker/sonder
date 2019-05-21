from django.shortcuts import render

def index(request):
    return render(request, "sonder/frontend/index.html")
