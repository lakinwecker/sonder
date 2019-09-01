"""
Some simple graphene related object
"""


class LoginRequired:

    @classmethod
    def get_queryset(cls, queryset, info):
        if info.context.user.is_anonymous:
            return queryset.none()
        return queryset

    # TODO: is this the right way to implement this or can I
    #       call super somehow?
    @classmethod
    def get_node(cls, info, id):
        if info.context.user.is_anonymous:
            return None
        try:
            return cls._meta.model.objects.get(id=id)
        except cls._meta.model.DoesNotExist:
            return None

