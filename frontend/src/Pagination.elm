module Pagination exposing (..)

import RemoteData exposing (RemoteData)
import List


type alias Response error response =
    RemoteData error response


type alias Page error dataType =
    { listResponse : Response error (List dataType)
    , offset : Int
    , pageSize : Int
    }


hasPreviousPage : Page error dataType -> Bool
hasPreviousPage paginator =
    paginator.offset > 0


hasNextPage : Page error dataType -> Bool
hasNextPage paginator =
    case paginator.listResponse of
        RemoteData.Success playerList ->
            List.length playerList > paginator.pageSize

        _ ->
            False


nextPage : Page error dataType -> Page error dataType
nextPage page =
    { page
        | listResponse = RemoteData.Loading
        , offset = page.offset + page.pageSize
    }


prevPage : Page error dataType -> Page error dataType
prevPage page =
    { page
        | listResponse = RemoteData.Loading
        , offset = (max 0 (page.offset - page.pageSize))
    }
