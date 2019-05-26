module Main exposing (..)

import Array exposing (Array, fromList, get, length)
import Browser
import Browser.Navigation as Nav
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element exposing (..)
import Element.Font as Font
import Element.Region as Region
import FontAwesome.Attributes as Attributes
import FontAwesome.Icon as Icon
import FontAwesome.Solid as Solid
import FontAwesome.Styles as FAStyles
import Http
import Json.Decode exposing (Decoder, field, string)
import Router exposing (..)


-- import Html exposing (..)

import List exposing (concat)
import Random
import Url
import Colors as C
import Styles as S


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
        [ BackgroundImage "/static/sonder/frontend/images/architecture-building-city-1137525.jpg"
        , BackgroundImage "/static/sonder/frontend/images/20150716_Mexico_City_at_Night_IMG_6614_by_sebaso.jpg"
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


type PageStatus
    = Failure
    | Loading


type alias DashboardPageModel =
    { status : PageStatus
    }


type alias LoginPageModel =
    { status : PageStatus
    }


defaultLoginPageModel : LoginPageModel
defaultLoginPageModel =
    { status = Loading }


defaultDashboardModel : DashboardPageModel
defaultDashboardModel =
    { status = Loading }


type CurrentPage
    = LoginPage LoginPageModel
    | UnauthorizedPage
    | HomePage
    | DashboardPage DashboardPageModel


type alias Model =
    { key : Nav.Key
    , user : User
    , page : CurrentPage
    }


loadLoginURL : Cmd Msg
loadLoginURL =
    Http.get
        { url = "/login/start"
        , expect = Http.expectJson GotLichessOAuthURL loginURLDecoder
        }


loginURLDecoder : Decoder String
loginURLDecoder =
    field "url" string


urlToPage : Url.Url -> ( CurrentPage, Cmd Msg )
urlToPage url =
    let
        route =
            parse routeParser url
    in
        case route of
            Just Login ->
                ( LoginPage defaultLoginPageModel, loadLoginURL )

            Just Unauthorized ->
                ( UnauthorizedPage, Cmd.none )

            Just Dashboard ->
                ( DashboardPage defaultDashboardModel, Cmd.none )

            Nothing ->
                ( HomePage, Cmd.none )


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        ( page, cmd ) =
            urlToPage url
    in
        ( Model key
            (Anonymous defaultUserPreferences)
            page
        , cmd
        )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | BackgroundChanged Int
    | GotLichessOAuthURL (Result Http.Error String)


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
            let
                ( page, cmd ) =
                    urlToPage url
            in
                ( { model | page = page }
                , cmd
                )

        BackgroundChanged i ->
            let
                bg =
                    getBackground i
            in
                ( { model | user = newBackgroundForUser bg model.user }
                , Cmd.none
                )

        GotLichessOAuthURL result ->
            case result of
                Ok url ->
                    ( model, Nav.load url )

                Err _ ->
                    ( { model | page = LoginPage { status = Failure } }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Sonder"
    , body =
        [ FAStyles.css
        , Element.layout
            [ viewBackgroundForUser model.user ]
            (case model.page of
                HomePage ->
                    homePage

                LoginPage pageModel ->
                    loginPage pageModel

                UnauthorizedPage ->
                    unauthorizedPage

                DashboardPage pageModel ->
                    dashboardPage pageModel
            )
        ]
    }


viewBackground : UserBackground -> Element.Attribute Msg
viewBackground bg =
    case bg of
        BackgroundImage url ->
            Background.image url

        BackgroundColor r g b ->
            Background.color (rgb255 r g b)


viewBackgroundForUser : User -> Element.Attribute Msg
viewBackgroundForUser u =
    case u of
        Anonymous prefs ->
            viewBackground prefs.background

        UnauthorizedUser _ prefs ->
            viewBackground prefs.background

        AuthorizedUser _ prefs ->
            viewBackground prefs.background



--viewUser : User -> Html Msg
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


spinner =
    el
        (concat
            [ S.textBox
            , [ paddingXY 30 30, width fill ]
            ]
        )
        (el
            [ centerX ]
            (html
                (Icon.viewStyled
                    [ Attributes.fa4x, Attributes.spin ]
                    Solid.spinner
                )
            )
        )


loginPage : LoginPageModel -> Element Msg
loginPage model =
    column [ centerY, centerX, spacing 0, padding 200, width fill ]
        [ logo
        , case model.status of
            Loading ->
                spinner

            Failure ->
                error "Unable to fetch login URL. Please try again"
        ]


homePage =
    column [ centerY, centerX, spacing 0, padding 200 ]
        [ logo, intro ]


logo : Element Msg
logo =
    el
        (concat
            [ S.titleFont, S.heroBox, [ paddingXY 30 30, width fill ] ]
        )
        (text "Sonder")


intro : Element Msg
intro =
    el
        (concat
            [ S.textFont, S.textBox, S.introSize, [ paddingXY 30 30, width fill ] ]
        )
        (column [ spacing 30 ]
            [ paragraph []
                [ text "Wondering about the strangers you meet online, their lives, their habits and whether or not they cheated in that chess game you just played with them."
                ]
            , loginButton
            ]
        )


loginButton : Element Msg
loginButton =
    link
        (concat [ S.button ])
        { url = "/login", label = text "Login" }


error : String -> Element Msg
error msg =
    el
        (concat
            [ S.textFont, S.textBox, S.errorSize, [ paddingXY 30 30, width fill ] ]
        )
        (column [ spacing 30 ]
            [ paragraph [] [ text msg ], loginButton ]
        )


unauthorizedPage =
    column [ centerY, centerX, spacing 0, padding 200 ]
        [ logo, unauthorized ]


unauthorized : Element Msg
unauthorized =
    el
        (concat
            [ S.textFont, S.textBox, S.introSize, [ paddingXY 30 30, width fill ] ]
        )
        (column [ spacing 30 ]
            [ paragraph []
                [ text "You are not authorized to login to Sonder. You know who to contact if you should have access."
                ]
            , loginButton
            ]
        )


dashboardPage pageModel =
    column [ centerY, centerX, spacing 0, padding 200 ]
        [ logo, dashboard ]


dashboard : Element Msg
dashboard =
    el
        (concat
            [ S.textFont, S.textBox, S.introSize, [ paddingXY 30 30, width fill ] ]
        )
        (column [ spacing 30 ]
            [ paragraph []
                [ text "Welcome to sonder"
                ]
            ]
        )
