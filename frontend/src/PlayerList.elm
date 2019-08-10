module PlayerList exposing (..)

import Element exposing (..)
import Common exposing (..)
import List exposing (concat)
import Styles as S
import Http
import Auth


type alias Player =
    { username : String
    }


type alias Model =
    { status : PageStatus
    , players : List Player
    }


init : Model
init =
    { status = PageLoading
    , players = []
    }


loadStatus : Cmd Msg
loadStatus =
    Http.get
        { url = "/login/status"
        , expect = Http.expectJson AuthStatus Auth.userFromStatus
        }


load : Cmd Msg
load =
    loadStatus


view : Model -> User -> Element Msg
view pageModel user =
    case pageModel.status of
        PageLoading ->
            viewLoading pageModel user

        -- TODO: Not appropriate
        PageFailure message ->
            viewLoading pageModel user

        -- TODO: Not appropriate
        PageLoaded ->
            viewLoading pageModel user


viewLoading : Model -> User -> Element Msg
viewLoading pageModel user =
    S.fullPageSpinner


viewLoaded : Model -> User -> Element Msg
viewLoaded pageModel user =
    el
        (concat
            [ S.textFont, S.textBox, S.introSize, [ paddingXY 30 30, width fill, height fill ] ]
        )
        (column [ spacing 30 ]
            [ paragraph []
                [ text "List of Players2"
                ]
            ]
        )


type Msg
    = AuthStatus (Result Http.Error User)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )
