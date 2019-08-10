module Dashboard exposing (..)

import Element exposing (..)
import Common exposing (..)
import List exposing (concat)
import Styles as S
import Http
import Auth


type alias Model =
    { status : PageStatus
    }


init : Model
init =
    { status = PageLoading }


view : Model -> User -> Element Msg
view pageModel user =
    el
        (concat
            [ S.textFont, S.textBox, S.introSize, [ paddingXY 30 30, width fill, height fill ] ]
        )
        (column [ spacing 30 ]
            [ paragraph []
                [ text "Welcome to sonder"
                ]
            ]
        )


loadStatus : Cmd Msg
loadStatus =
    Http.get
        { url = "/login/status"
        , expect = Http.expectJson AuthStatus Auth.userFromStatus
        }


load : Cmd Msg
load =
    loadStatus


type Msg
    = AuthStatus (Result Http.Error User)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )
