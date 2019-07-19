module Main exposing (..)

import Array exposing (Array, fromList, get, length)
import Browser
import Browser.Navigation as Nav
import Browser.Events as Events
import Element exposing (..)
import FontAwesome.Styles as FAStyles
import Router
import Common exposing (..)
import Dashboard
import Login
import PlayerList


-- import Html exposing (..)

import List exposing (concat)
import Url
import Colors as C
import Styles as S


-- MAIN


type alias BrowserSize =
    { width : Int, height : Int }


main : Program BrowserSize Model Msg
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


type CurrentPage
    = LoginPage Login.Model
    | UnauthorizedPage
    | HomePage
    | DashboardPage Dashboard.Model
    | PlayerListPage PlayerList.Model


type alias Model =
    { key : Nav.Key
    , user : User
    , page : CurrentPage
    , device : Device
    }


urlToPage : Url.Url -> ( CurrentPage, Cmd Msg )
urlToPage url =
    let
        route =
            Router.parse Router.routeParser url
    in
        case route of
            Just Router.Login ->
                ( LoginPage Login.init, Login.load )

            Just Router.Unauthorized ->
                ( UnauthorizedPage, Cmd.none )

            Just Router.Dashboard ->
                ( DashboardPage Dashboard.init, Dashboard.load )

            Just Router.PlayerList ->
                ( PlayerListPage PlayerList.init, PlayerList.load )

            Nothing ->
                ( HomePage, Cmd.none )


init : BrowserSize -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        ( page, cmd ) =
            urlToPage url
    in
        ( Model key
            (Anonymous defaultUserPreferences)
            page
            (classifyDevice flags)
        , cmd
        )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotLichessOAuthURL (Result Http.Error String)
    | AuthStatus (Result Http.Error User)
    | BrowserResize Int Int


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

        GotLichessOAuthURL result ->
            case result of
                Ok url ->
                    ( model, Nav.load url )

                Err _ ->
                    ( { model | page = LoginPage { status = Failure } }, Cmd.none )

        AuthStatus result ->
            case result of
                Ok user ->
                    ( { model | user = user }, Cmd.none )

                Err _ ->
                    ( { model | page = LoginPage { status = Failure } }, Cmd.none )

        BrowserResize w h ->
            ( { model | device = classifyDevice { width = w, height = h } }, Cmd.none )



{--
        _ ->
            case model.page of
                DashboardPage pageModel ->
                    let
                        ( newPageModel, cmd ) =
                            (Dashboard.update msg pageModel)
                    in
                        ( { model | page = DashboardPage newPageModel }, cmd )

                PlayerListPage pageModel ->
                    let
                        ( newPageModel, cmd ) =
                            (PlayerList.update msg pageModel)
                    in
                        ( { model | page = PlayerListPage newPageModel }, cmd )

                LoginPage pageModel ->
                    let
                        ( newPageModel, cmd ) =
                            (Login.update msg pageModel)
                    in
                        ( { model | page = LoginPage newPageModel }, cmd )

                _ ->
                    ( model, Cmd.none )
        --}
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Events.onResize BrowserResize



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Sonder"
    , body =
        [ FAStyles.css
        , Element.layout
            [ S.viewBackgroundForUser model.user ]
            (case model.page of
                HomePage ->
                    S.homePage

                LoginPage pageModel ->
                    Login.view pageModel

                UnauthorizedPage ->
                    S.unauthorizedPage

                DashboardPage pageModel ->
                    S.fullPage model Dashboard.view pageModel

                PlayerListPage pageModel ->
                    S.fullPage model PlayerList.view pageModel
            )
        ]
    }
