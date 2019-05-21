module Main exposing (..)

import Array exposing (Array, fromList, get, length)
import Browser
import Browser.Navigation as Nav
import Element.Background as Background
import Element.Border as Border
import Element exposing (..)
import Element.Font as Font
import Element.Region as Region


-- import Html exposing (..)

import List exposing (concat)
import Random
import Url
import Colors as C
import Styles as S


-- Simple helper


attrs l =
    concat l



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- MODEL


type UserBackground
    = BackgroundImage String
    | BackgroundColor Int Int Int


backgrounds : Array UserBackground
backgrounds =
    fromList
        [ BackgroundImage "/static/sonder/frontend/images/20150716_Mexico_City_at_Night_IMG_6614_by_sebaso.jpg"
        , BackgroundImage "/static/sonder/frontend/images/architecture-buildings-city-2067048.jpg"
        ]


randomBackgroundIndex =
    length backgrounds |> Random.int 0


defaultBackgroundColor =
    BackgroundColor 0 0 0


getBackground : Int -> UserBackground
getBackground i =
    Maybe.withDefault defaultBackgroundColor (get i backgrounds)


defaultBackground : UserBackground
defaultBackground =
    getBackground 0


type Username
    = Username String


type alias UserPreferences =
    { background : UserBackground }


defaultUserPreferences =
    { background = defaultBackground }


newBackground : UserBackground -> UserPreferences -> UserPreferences
newBackground bg up =
    { up | background = bg }


type User
    = AuthorizedUser Username UserPreferences
    | UnauthorizedUser Username UserPreferences
    | Anonymous UserPreferences


newBackgroundForUser : UserBackground -> User -> User
newBackgroundForUser bg u =
    case u of
        Anonymous prefs ->
            Anonymous (newBackground bg prefs)

        UnauthorizedUser (Username username) prefs ->
            UnauthorizedUser (Username username) (newBackground bg prefs)

        AuthorizedUser (Username username) prefs ->
            AuthorizedUser (Username username) (newBackground bg prefs)


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , user : User
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( Model key url (Anonymous defaultUserPreferences), Cmd.none )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | BackgroundChanged Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model | url = url }
            , Cmd.none
            )

        BackgroundChanged i ->
            let
                bg =
                    getBackground i
            in
                ( { model | user = newBackgroundForUser bg model.user }
                , Cmd.none
                )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Sonder"
    , body =
        [ Element.layout [ viewBackgroundForUser model.user ]
            homePage
        ]
    }


viewBackground : UserBackground -> Element.Attribute msg
viewBackground bg =
    case bg of
        BackgroundImage url ->
            Background.image url

        BackgroundColor r g b ->
            Background.color (rgb255 r g b)


viewBackgroundForUser : User -> Element.Attribute msg
viewBackgroundForUser u =
    case u of
        Anonymous prefs ->
            viewBackground prefs.background

        UnauthorizedUser _ prefs ->
            viewBackground prefs.background

        AuthorizedUser _ prefs ->
            viewBackground prefs.background



--viewUser : User -> Html msg
--viewUser user =
--case user of
--Anonymous prefs ->
--div []
--[ b [] [ Html.text "Not Logged In" ]
--, a [] [ Html.text "Login" ]
--]
--
--AuthorizedUser (Username username) prefs ->
--b [] [ Html.text ("Authorized: " ++ username) ]
--
--UnauthorizedUser (Username username) prefs ->
--b [] [ Html.text ("Go away: " ++ username) ]
-- TODO: introduce and make it all responsive


homePage =
    column [ centerY, centerX, spacing 0, padding 200 ]
        [ logo
        , intro
        ]


logo : Element msg
logo =
    el
        (attrs
            [ S.titleFont
            , S.heroBox
            , [ paddingXY 30 30, width fill ]
            ]
        )
        (text "Sonder")


intro : Element msg
intro =
    el
        (attrs
            [ S.textFont
            , S.textBox
            , S.introSize
            , [ paddingXY 30 30, width fill ]
            ]
        )
        (column [ spacing 30 ]
            [ paragraph []
                [ text "Wondering about the strangers you meet online, their lives, their habits and whether or not they cheated in that chess game you just played with them."
                ]
            , loginButton
            ]
        )


loginButton : Element msg
loginButton =
    link
        (attrs
            [ S.button
            ]
        )
        { url = "/login", label = text "Login" }
