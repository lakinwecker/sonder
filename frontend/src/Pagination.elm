module Pagination exposing (..)

import Element exposing (..)
import Element.Input as Input
import RemoteData exposing (RemoteData)
import List
import Styles as S


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


getPageList : Page error dataType -> List dataType -> List dataType
getPageList pageInfo pageList =
    List.take pageInfo.pageSize pageList


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


controls : Page error response -> msg -> msg -> List (Element msg)
controls pageInfo getPreviousPage getNextPage =
    [ case hasPreviousPage pageInfo of
        True ->
            Input.button (S.secondaryButton ++ [ alignLeft ])
                { onPress = Just getPreviousPage, label = text "Prev Page" }

        False ->
            Input.button (S.disabledButton ++ [ alignLeft ])
                { onPress = Nothing, label = text "Prev Page" }
    , case hasNextPage pageInfo of
        True ->
            Input.button (S.secondaryButton ++ [ alignRight ])
                { onPress = Just getNextPage, label = text "Next Page" }

        False ->
            Input.button (S.disabledButton ++ [ alignRight ])
                { onPress = Nothing, label = text "Next Page" }
    ]
