module Login exposing (..)

import Http
import Json.Decode exposing (Decoder, field, string)
import Element exposing (..)
import Styles as S
import Common exposing (..)


type alias Model =
    { status : PageStatus
    }


defaultModel : Model
defaultModel =
    { status = Loading }


load : Cmd Msg
load =
    Http.get
        { url = "/login/start"
        , expect = Http.expectJson GotLichessOAuthURL loginURLDecoder
        }


loginURLDecoder : Decoder String
loginURLDecoder =
    field "url" string


view : Model -> Element Msg
view model =
    column [ centerY, centerX, spacing 0, padding 200, width fill ]
        [ S.logo
        , case model.status of
            Loading ->
                S.spinner

            Failure ->
                S.error "Unable to fetch login URL. Please try again"
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )
