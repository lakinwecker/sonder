module Login exposing (..)

import Browser.Navigation as Nav
import Http
import Json.Decode exposing (Decoder, field, string)
import Element exposing (..)
import Styles as S
import Common exposing (..)


-- MODEL


type alias Model =
    { status : RedirectStatus
    }


init : Model
init =
    { status = RedirectLoading }


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
            RedirectLoading ->
                S.spinner

            RedirectFailure message ->
                S.error message
        ]



-- Update


type Msg
    = GotLichessOAuthURL (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotLichessOAuthURL result ->
            case result of
                Ok url ->
                    ( model, Nav.load url )

                Err _ ->
                    ( { status = RedirectFailure "Unable to load Lichess OAuth Url"
                      }
                    , Cmd.none
                    )
