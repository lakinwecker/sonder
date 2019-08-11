module StaticPage exposing (..)

import Element exposing (..)
import Common exposing (..)
import Styles as S


type alias Model =
    {}


init : Session -> ( Model, Cmd Msg )
init session =
    ( {}, Cmd.none )


view : (Session -> Element Msg) -> Model -> Session -> Element Msg
view content pageModel session =
    content session


type Msg
    = Nothing


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- Grouping things together so we can refer to them more easily


type alias Page msg pageModel =
    SubPagePartial Msg Model msg pageModel


page :
    (Session -> Element Msg)
    -> (Msg -> localMsg)
    -> (Model -> pageModel)
    -> Page localMsg pageModel
page content toMsg toModel =
    { init = init
    , view = view content
    , update = update
    , subscriptions = subscriptions
    , msg = toMsg
    , model = toModel
    }
