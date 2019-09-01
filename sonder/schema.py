import graphene

import sonder.analysis.schema
import sonder.frontend.schema
from graphene_django_extras import all_directives

class Query(
    sonder.frontend.schema.Query,
    sonder.analysis.schema.Query,
    graphene.ObjectType
):
    # This class will inherit from multiple Queries
    # as we begin to add more apps to our project
    pass

schema = graphene.Schema(
    query=Query,
    directives=all_directives
)
