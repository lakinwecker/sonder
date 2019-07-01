module Dashboard exposing (..)

import Element exposing (..)
import Common exposing (..)
import List exposing (concat)
import Styles as S
import Auth


type alias Model =
    { status : PageStatus
    }


defaultModel : Model
defaultModel =
    { status = Loading }


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


load : Cmd Msg
load =
    Auth.loadStatus


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )
