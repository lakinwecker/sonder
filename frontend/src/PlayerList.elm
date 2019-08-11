module PlayerList exposing (..)

-- elmgraphql

import Graphql.Document as Document
import Graphql.Http
import Graphql.Operation exposing (RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)


-- Sonder APi

import Sonder.Interface
import Sonder.Object
import Sonder.Object.Player as Player
import Sonder.Query as Query


-- Others

import RemoteData exposing (RemoteData)
import Element exposing (..)
import Common exposing (..)
import List exposing (concat)
import Styles as S
import Http
import Auth
import Sonder.Interface


type alias Player =
    { username : String
    }


type alias Response =
    Maybe (List (Maybe Player))


type alias ModelResponse =
    RemoteData (Graphql.Http.Error Response) Response


type alias Model =
    { players : ModelResponse
    }


query : SelectionSet Response RootQuery
query =
    -- We use `identity` to say that we aren't giving any
    -- optional arguments to `hero`. Read this blog post for more:
    -- https://medium.com/@zenitram.oiram/graphqelm-optional-arguments-in-a-language-without-optional-arguments-d8074ca3cf74
    Query.players playerInfoSelection


playerInfoSelection : SelectionSet Player Sonder.Object.Player
playerInfoSelection =
    SelectionSet.map Player
        Player.username


init : Session -> ( Model, Cmd Msg )
init session =
    ( { players = RemoteData.Loading
      }
    , loadPlayers session
    )


loadPlayers : Session -> Cmd Msg
loadPlayers session =
    query
        |> Graphql.Http.queryRequest "/analysis/graphql/"
        |> Graphql.Http.withHeader "X-CSRFToken" session.csrfToken
        |> Graphql.Http.send (RemoteData.fromResult >> GotResponse)


view : Model -> Session -> Element Msg
view pageModel session =
    let
        a =
            Debug.log "PlayersList.view" pageModel.players
    in
        case pageModel.players of
            RemoteData.NotAsked ->
                viewWaiting pageModel session

            RemoteData.Loading ->
                viewLoading pageModel session

            -- TODO: Not appropriate
            RemoteData.Failure message ->
                viewError pageModel session

            -- TODO: Not appropriate
            RemoteData.Success players ->
                viewLoaded pageModel session players


viewLoading : Model -> Session -> Element Msg
viewLoading pageModel session =
    S.fullPageSpinner


viewWaiting : Model -> Session -> Element Msg
viewWaiting pageModel session =
    el
        (concat
            [ S.textFont
            , S.textBox
            , S.introSize
            , [ paddingXY 30 30
              , width fill
              , height fill
              ]
            ]
        )
        (column [ spacing 30 ]
            [ paragraph []
                [ text "error"
                ]
            ]
        )


viewError : Model -> Session -> Element Msg
viewError pageModel session =
    el
        (concat
            [ S.textFont
            , S.textBox
            , S.introSize
            , [ paddingXY 30 30
              , width fill
              , height fill
              ]
            ]
        )
        (column [ spacing 30 ]
            [ paragraph []
                [ text "error"
                ]
            ]
        )


viewLoaded : Model -> Session -> Response -> Element Msg
viewLoaded pageModel session players =
    el
        (concat
            [ S.textFont
            , S.textBox
            , S.introSize
            , [ paddingXY 30 30
              , width fill
              , height fill
              ]
            ]
        )
        (column [ spacing 30 ]
            [ paragraph []
                [ text "Loaded"
                ]
            ]
        )


type Msg
    = GotResponse ModelResponse


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotResponse players ->
            ( { model | players = players }, Cmd.none )



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- Grouping things together so we can refer to them more easily


type alias Page msg pageModel =
    SubPagePartial Msg Model msg pageModel


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
