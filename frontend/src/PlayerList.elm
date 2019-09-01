module PlayerList exposing (..)

-- elmgraphql

import Graphql.Document as Document
import Graphql.Http
import Graphql.Operation exposing (RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, with)
import Graphql.OptionalArgument as OptionalArgument exposing (OptionalArgument(..))


-- Sonder API

import Sonder.Interface
import Sonder.Object
import Sonder.Object.Player
import Sonder.Query as Query


-- elm-ui

import Element exposing (..)
import Element.Events exposing (..)
import Element.Input as Input


-- Others

import RemoteData exposing (RemoteData)
import Common exposing (..)
import Pagination
import Styles as S
import Http
import Auth
import Sonder.Interface
import Router


pageSize : Int
pageSize =
    30


type alias Player =
    { username : String
    , totalGames : Int
    }


type alias PlayerList =
    List Player


type alias PageResponse =
    Pagination.Response (Graphql.Http.Error PlayerList) PlayerList


type alias PageInfo =
    Pagination.Page (Graphql.Http.Error PlayerList) Player


type alias Model =
    { pageInfo : PageInfo
    , session : Session
    }


query : PageInfo -> SelectionSet PlayerList RootQuery
query pageInfo =
    (Query.players
        (\optionals ->
            { optionals
                | offset = Present pageInfo.offset
                , limit = Present (pageInfo.pageSize + 1)
                , ordering = Present "username"
            }
        )
        playerSelection
    )
        |> SelectionSet.nonNullElementsOrFail


playerSelection : SelectionSet Player Sonder.Object.Player
playerSelection =
    SelectionSet.map2 Player
        Sonder.Object.Player.username
        Sonder.Object.Player.totalGames


init : Session -> NoArgs -> ( Model, Cmd Msg )
init session _ =
    let
        pageInfo =
            { listResponse = RemoteData.Loading
            , offset = 0
            , pageSize = pageSize
            }
    in
        ( { pageInfo = pageInfo
          , session = session
          }
        , loadPlayers pageInfo session
        )


loadPlayers : PageInfo -> Session -> Cmd Msg
loadPlayers pageInfo session =
    query pageInfo
        |> Graphql.Http.queryRequest "/graphql/"
        |> Graphql.Http.withHeader "X-CSRFToken" session.csrfToken
        |> Graphql.Http.send (RemoteData.fromResult >> GotResponse)


totalGamesStr : Player -> String
totalGamesStr player =
    String.fromInt player.totalGames


view : Model -> Session -> Element Msg
view pageModel session =
    S.remoteDataPage viewLoaded pageModel session pageModel.pageInfo.listResponse


playerLink : Player -> Element Msg
playerLink player =
    link
        []
        { url = "/players/" ++ player.username, label = text player.username }


viewLoaded : Model -> Session -> PlayerList -> Element Msg
viewLoaded model session response =
    column (S.content ++ [ width fill ])
        [ table
            []
            { data = (Pagination.getPageList model.pageInfo response)
            , columns =
                [ { header = S.tableHeader "Username"
                  , width = fill
                  , view =
                        S.tableCell [] playerLink
                  }
                , { header = S.tableHeader "# Games"
                  , width = fill
                  , view =
                        \player ->
                            totalGamesStr player
                                |> S.tableCell [] text
                  }
                ]
            }
        , row [ width fill ]
            (Pagination.controls model.pageInfo GetPreviousPage GetNextPage)
        ]


type Msg
    = GotResponse PageResponse
    | GetPreviousPage
    | GetNextPage


updatePage : PageInfo -> PageResponse -> PageInfo
updatePage pageInfo pageResponse =
    { pageInfo | listResponse = pageResponse }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotResponse pageResponse ->
            ( { model | pageInfo = (updatePage model.pageInfo pageResponse) }, Cmd.none )

        GetNextPage ->
            case model.pageInfo.listResponse of
                RemoteData.Success playerList ->
                    let
                        nextPage =
                            Pagination.nextPage model.pageInfo
                    in
                        if Pagination.hasNextPage model.pageInfo then
                            ( { model | pageInfo = nextPage }
                            , loadPlayers nextPage model.session
                            )
                        else
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        GetPreviousPage ->
            case model.pageInfo.listResponse of
                RemoteData.Success playerList ->
                    let
                        prevPage =
                            Pagination.prevPage model.pageInfo
                    in
                        if Pagination.hasPreviousPage model.pageInfo then
                            ( { model | pageInfo = prevPage }
                            , loadPlayers prevPage model.session
                            )
                        else
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- Grouping things together so we can refer to them more easily


type alias Page msg pageModel =
    SubPagePartial NoArgs Msg Model msg pageModel


page :
    (Msg -> localMsg)
    -> (Model -> pageModel)
    -> Page localMsg pageModel
page toMsg toModel =
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    , msg = toMsg
    , model = toModel
    }
