module Dashboard exposing (..)

import Element exposing (..)
import Common exposing (..)
import List exposing (concat)
import Styles as S
import Http
import Auth
import Router


type alias Model =
    { status : PageStatus
    }


init : Session -> NoArgs -> ( Model, Cmd Msg )
init session _ =
    ( { status = PageLoading }
    , loadStatus
    )


view : Model -> Session -> Element Msg
view pageModel session =
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


type Msg
    = AuthStatus (Result Http.Error User)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
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
