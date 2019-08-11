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


init : Session -> ( Model, Cmd Msg )
init session =
    ( { status = RedirectLoading }
    , load
    )


load : Cmd Msg
load =
    Http.get
        { url = "/login/start"
        , expect = Http.expectJson GotLichessOAuthURL loginURLDecoder
        }


loginURLDecoder : Decoder String
loginURLDecoder =
    field "url" string


view : Model -> Session -> Element Msg
view model session =
    column [ centerY, centerX, spacing 0, padding 200, width fill ]
        [ S.logo
        , case model.status of
            RedirectLoading ->
                S.spinner

            RedirectFailure message ->
                S.error session message
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
