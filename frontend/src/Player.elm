module Player exposing (..)

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
import Styles as S
import Http
import Auth
import Sonder.Interface
import Router
import Data exposing (..)


type alias Response =
    Maybe Player


type alias ModelResponse =
    RemoteData (Graphql.Http.Error Response) Response


type alias Model =
    { player : ModelResponse
    , username : String
    }


query : String -> SelectionSet Response RootQuery
query username =
    Query.player { username = username } playerCompleteSelection


type alias InitArgs =
    { username : String }


initArgs : String -> InitArgs
initArgs val =
    { username = val }


init : Session -> InitArgs -> ( Model, Cmd Msg )
init session args =
    ( { player = RemoteData.Loading
      , username = args.username
      }
    , loadPlayer args.username session
    )


loadPlayer : String -> Session -> Cmd Msg
loadPlayer username session =
    query username
        |> Graphql.Http.queryRequest "/graphql/"
        |> Graphql.Http.withHeader "X-CSRFToken" session.csrfToken
        |> Graphql.Http.send (RemoteData.fromResult >> GotResponse)


view : Model -> Session -> Element Msg
view pageModel session =
    S.remoteDataPage viewLoaded pageModel session pageModel.player


maybeAttr :
    (Player -> a)
    -> (a -> Element Msg)
    -> Maybe Player
    -> Element Msg
maybeAttr toA toElement player =
    case player of
        Nothing ->
            none

        Just p ->
            toElement (toA p)


viewLoaded : Model -> Session -> Response -> Element Msg
viewLoaded pageModel session maybePlayer =
    el
        (S.content ++ S.fillXY ++ [ padding 20 ])
        (case maybePlayer of
            Nothing ->
                text "Nothing"

            Just player ->
                el
                    []
                    (S.h3 player.username)
        )


type Msg
    = GotResponse ModelResponse


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotResponse player ->
            ( { model | player = (Debug.log "player" player) }, Cmd.none )



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- Grouping things together so we can refer to them more easily


type alias Page msg pageModel =
    SubPagePartial InitArgs Msg Model msg pageModel


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
