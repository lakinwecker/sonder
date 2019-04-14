from django.contrib import admin
from . import models

class AnalysisSourceAdmin(admin.ModelAdmin):
    list_display = ('name', 'enabled', 'use_for_irwin', 'use_for_mods',)
    list_filter = ('enabled', 'use_for_irwin', 'use_for_mods')
admin.site.register(models.AnalysisSource, AnalysisSourceAdmin)
