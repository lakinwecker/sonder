module Main exposing (..)

import Array exposing (Array, fromList, get, length)
import Browser
import Browser.Navigation as Nav
import Browser.Events as Events
import Element exposing (..)
import FontAwesome.Styles as FAStyles
import Router
import Common exposing (..)
import Http


-- Pages

import Login
import PlayerList
import Dashboard
import StaticPage


-- import Html exposing (..)

import List exposing (concat)
import Url
import Colors as C
import Styles as S


-- Setup all of our sub pages
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


type SubPageModel
    = SplashModel StaticPage.Model
    | LoginModel Login.Model
    | PlayerListModel PlayerList.Model
    | DashboardModel Dashboard.Model
    | UnauthorizedModel StaticPage.Model


type alias Model =
    { session : Session
    , subModel : SubPageModel
    }


splashPage =
    StaticPage.page
        S.splashPage
        GotSplashMsg
        SplashModel


loginPage =
    Login.page
        GotLoginMsg
        LoginModel


unauthorizedPage =
    StaticPage.page
        S.unauthorizedPage
        GotUnauthorizedMsg
        UnauthorizedModel


dashboardPage =
    Dashboard.page
        GotDashboardMsg
        DashboardModel


playerListPage =
    PlayerList.page
        GotPlayerListMsg
        PlayerListModel


type alias SubPage subMsg subModel =
    SubPagePartial subMsg subModel Msg SubPageModel


subPageInit :
    SubPage subMsg subModel
    -> ( SubPageModel, Cmd Msg )
subPageInit subPage =
    ( subPage.model subPage.init
    , Cmd.map subPage.msg subPage.load
    )


urlToPage : Url.Url -> ( SubPageModel, Cmd Msg )
urlToPage url =
    let
        route =
            Router.parse Router.routeParser url
    in
        case route of
            Just Router.Splash ->
                subPageInit splashPage

            Just Router.Login ->
                subPageInit loginPage

            Just Router.Unauthorized ->
                subPageInit unauthorizedPage

            Just Router.Dashboard ->
                subPageInit dashboardPage

            Just Router.PlayerList ->
                subPageInit playerListPage

            Nothing ->
                subPageInit loginPage


init : BrowserSize -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        ( page, cmd ) =
            urlToPage url
    in
        ( Model
            (Session
                (Anonymous defaultUserPreferences)
                key
                (classifyDevice flags)
            )
            page
        , cmd
        )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
      --| AuthStatus (Result Http.Error User)
    | BrowserResize Int Int
    | GotSplashMsg StaticPage.Msg
    | GotLoginMsg Login.Msg
    | GotPlayerListMsg PlayerList.Msg
    | GotDashboardMsg Dashboard.Msg
    | GotUnauthorizedMsg StaticPage.Msg


subPageUpdate :
    SubPage subMsg subModel
    -> subMsg
    -> subModel
    -> Model
    -> ( Model, Cmd Msg )
subPageUpdate subPage subMsg subModel model =
    subPage.update subMsg subModel
        |> updateWith subPage.model subPage.msg model


updateWith : (subModel -> SubPageModel) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toCurrentPage toMsg model ( subModel, subCmd ) =
    ( { model | subModel = toCurrentPage subModel }
    , Cmd.map toMsg subCmd
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.subModel ) of
        ( LinkClicked urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.session.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        ( UrlChanged url, _ ) ->
            let
                ( page, cmd ) =
                    urlToPage url
            in
                ( { model | subModel = page }
                , cmd
                )

        ( BrowserResize w h, _ ) ->
            let
                oldSession =
                    model.session

                newSession =
                    { oldSession | device = classifyDevice { width = w, height = h } }
            in
                ( { model | session = newSession }, Cmd.none )

        ( GotLoginMsg subMsg, LoginModel subModel ) ->
            subPageUpdate loginPage subMsg subModel model

        ( GotPlayerListMsg subMsg, PlayerListModel subModel ) ->
            subPageUpdate playerListPage subMsg subModel model

        ( GotDashboardMsg subMsg, DashboardModel subModel ) ->
            subPageUpdate dashboardPage subMsg subModel model

        ( _, _ ) ->
            -- Ignore by default
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subPageSubscriptions :
    SubPage subMsg subModel
    -> subModel
    -> Sub Msg
subPageSubscriptions subPage subModel =
    Sub.map subPage.msg (subPage.subscriptions subModel)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Events.onResize BrowserResize
        , (case model.subModel of
            LoginModel subModel ->
                subPageSubscriptions loginPage subModel

            DashboardModel subModel ->
                subPageSubscriptions dashboardPage subModel

            PlayerListModel subModel ->
                subPageSubscriptions playerListPage subModel

            _ ->
                -- Ignore by default
                Sub.none
          )
        ]



-- VIEW


subPageView :
    SubPage subMsg subModel
    -> subModel
    -> Session
    -> Element Msg
subPageView subPage pageModel session =
    viewPage subPage.msg subPage.view pageModel session


subPageFullView :
    SubPage subMsg subModel
    -> subModel
    -> Session
    -> Element Msg
subPageFullView subPage subModel session =
    viewPage subPage.msg (S.fullPage subPage.view) subModel session


viewPage : (subMsg -> Msg) -> (subModel -> Session -> Element subMsg) -> subModel -> Session -> Element Msg
viewPage toMsg subView model session =
    let
        body =
            subView model session
    in
        Element.map toMsg body


view : Model -> Browser.Document Msg
view model =
    { title = "Sonder"
    , body =
        [ FAStyles.css
        , Element.layout
            [ S.viewBackgroundForUser model.session.user ]
            (case model.subModel of
                SplashModel pageModel ->
                    subPageView splashPage pageModel model.session

                LoginModel pageModel ->
                    subPageView loginPage pageModel model.session

                UnauthorizedModel pageModel ->
                    subPageView unauthorizedPage pageModel model.session

                DashboardModel pageModel ->
                    subPageFullView dashboardPage pageModel model.session

                PlayerListModel pageModel ->
                    subPageFullView playerListPage pageModel model.session
            )
        ]
    }
