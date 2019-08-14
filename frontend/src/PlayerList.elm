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
import Styles as S
import Http
import Auth
import Sonder.Interface
import Router


type alias Player =
    { username : String
    , totalGames : Int
    }


totalGamesStr : Player -> String
totalGamesStr player =
    String.fromInt player.totalGames


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


init : Session -> NoArgs -> ( Model, Cmd Msg )
init session _ =
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
    S.remoteDataPage viewLoaded pageModel session pageModel.players


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


playerLink : Player -> Element Msg
playerLink player =
    link
        []
        { url = "/players/" ++ player.username, label = text player.username }


viewLoaded : Model -> Session -> Response -> Element Msg
viewLoaded pageModel session maybePlayers =
    case maybePlayers of
        Nothing ->
            none

        Just players ->
            table
                S.content
                { data = players
                , columns =
                    [ { header = S.tableHeader "Username"
                      , width = fill
                      , view =
                            \person ->
                                maybeAttr identity (S.tableCell [] playerLink) person
                      }
                    , { header = S.tableHeader "# Games"
                      , width = fill
                      , view =
                            \person ->
                                maybeAttr totalGamesStr (S.tableCell [] text) person
                      }
                    ]
                }


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
