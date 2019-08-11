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
    , totalGames : String
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
    Query.players playerInfoSelection


playerInfoSelection : SelectionSet Player Sonder.Object.Player
playerInfoSelection =
    SelectionSet.map2 Player
        Player.username
        Player.totalGames


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
    case pageModel.players of
        RemoteData.NotAsked ->
            S.fullPageCog

        RemoteData.Loading ->
            S.fullPageSpinner

        RemoteData.Failure message ->
            errorMsgFromGraphQL message
                |> S.error session

        RemoteData.Success players ->
            viewLoaded pageModel session players


viewPlayer : Maybe Player -> Element Msg
viewPlayer maybePlayer =
    case maybePlayer of
        Nothing ->
            Element.none

        Just player ->
            el
                []
                (paragraph
                    []
                    [ text (player.username ++ player.totalGames)
                    ]
                )


viewPlayers : Response -> List (Element Msg)
viewPlayers maybePlayers =
    case maybePlayers of
        Nothing ->
            []

        Just players ->
            List.map viewPlayer players


viewLoaded : Model -> Session -> Response -> Element Msg
viewLoaded pageModel session players =
    el
        (concat
            [ S.textFont
            , S.textBox
            , S.introSize
            , [ paddingXY 30 30
              , width fill
              ]
            ]
        )
        (column [ spacing 30 ]
            [ paragraph []
                (viewPlayers players)
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
