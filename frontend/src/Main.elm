module Main exposing (..)

import Array
    exposing
        ( Array
        , fromList
        , get
        , length
        )
import Auth
import Browser
import Browser.Events as Events
import Browser.Navigation as Nav
import Common exposing (..)
import Element exposing (..)
import FontAwesome.Styles as FAStyles
import Http
import List exposing (concat)
import Time
import Url


-- Sonder Stuff

import Colors as C
import Dashboard
import Login
import PlayerList
import Player
import Router
import StaticPage
import Styles as S


-- MAIN


type alias Flags =
    { width : Int, height : Int, csrfToken : String }


main : Program Flags Model Msg
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
-- Setup all of our sub pages


type SubPageModel
    = SplashModel StaticPage.Model
    | LoginModel Login.Model
    | PlayerListModel PlayerList.Model
    | PlayerModel Player.Model
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


playerPage =
    Player.page
        GotPlayerMsg
        PlayerModel


type alias SubPage initArgs subMsg subModel =
    SubPagePartial initArgs subMsg subModel Msg SubPageModel


subPageInit :
    SubPage initArgs subMsg subModel
    -> Session
    -> initArgs
    -> ( SubPageModel, Cmd Msg )
subPageInit subPage session initArgs =
    let
        ( subModel, subMsg ) =
            subPage.init session initArgs
    in
        ( subPage.model subModel
        , Cmd.map subPage.msg subMsg
        )


urlToPage : Url.Url -> Session -> ( SubPageModel, Cmd Msg )
urlToPage url session =
    let
        route =
            Router.parse Router.routeParser url
    in
        case route of
            Just Router.Splash ->
                subPageInit splashPage session NoArgs

            Just Router.Login ->
                subPageInit loginPage session NoArgs

            Just Router.Unauthorized ->
                subPageInit unauthorizedPage session NoArgs

            Just Router.Dashboard ->
                subPageInit dashboardPage session NoArgs

            Just Router.PlayerList ->
                subPageInit playerListPage session NoArgs

            Just (Router.Player username) ->
                subPageInit playerPage session (Player.initArgs username)

            Nothing ->
                subPageInit loginPage session NoArgs


loadAuthStatus : Cmd Msg
loadAuthStatus =
    Http.get
        { url = "/login/status"
        , expect = Http.expectJson GotAuthStatus Auth.userFromStatus
        }


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        session =
            Session
                (Anonymous defaultUserPreferences)
                key
                (classifyDevice flags)
                { width = flags.width, height = flags.height }
                flags.csrfToken

        ( page, cmd ) =
            urlToPage url session
    in
        ( Model session page
        , Cmd.batch
            [ cmd
            , loadAuthStatus
            ]
        )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | BrowserResize Int Int
    | GotSplashMsg StaticPage.Msg
    | GotLoginMsg Login.Msg
    | GotPlayerListMsg PlayerList.Msg
    | GotPlayerMsg Player.Msg
    | GotDashboardMsg Dashboard.Msg
    | GotUnauthorizedMsg StaticPage.Msg
    | GotAuthStatus (Result Http.Error User)
    | GotTick Time.Posix


subPageUpdate :
    SubPage initArgs subMsg subModel
    -> subMsg
    -> subModel
    -> Model
    -> ( Model, Cmd Msg )
subPageUpdate subPage subMsg subModel model =
    subPage.update subMsg subModel
        |> updateWith subPage.model subPage.msg model


updateWith :
    (subModel -> SubPageModel)
    -> (subMsg -> Msg)
    -> Model
    -> ( subModel, Cmd subMsg )
    -> ( Model, Cmd Msg )
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
                    ( model
                    , Nav.pushUrl
                        model.session.key
                        (Url.toString url)
                    )

                Browser.External href ->
                    ( model, Nav.load href )

        ( UrlChanged url, _ ) ->
            let
                ( page, cmd ) =
                    urlToPage url model.session
            in
                ( { model | subModel = page }
                , cmd
                )

        ( BrowserResize w h, _ ) ->
            let
                oldSession =
                    model.session

                size =
                    { width = w, height = h }

                device =
                    classifyDevice size

                newSession =
                    { oldSession | device = device, size = size }
            in
                ( { model | session = newSession }, Cmd.none )

        ( GotAuthStatus result, _ ) ->
            let
                oldSession =
                    model.session

                newSession =
                    case result of
                        Ok user ->
                            { oldSession | user = user }

                        Err _ ->
                            { oldSession | user = Auth.anonymousUser }
            in
                ( { model | session = newSession }, Cmd.none )

        ( GotLoginMsg subMsg, LoginModel subModel ) ->
            subPageUpdate loginPage subMsg subModel model

        ( GotPlayerListMsg subMsg, PlayerListModel subModel ) ->
            subPageUpdate playerListPage subMsg subModel model

        ( GotDashboardMsg subMsg, DashboardModel subModel ) ->
            subPageUpdate dashboardPage subMsg subModel model

        ( GotPlayerMsg subMsg, PlayerModel subModel ) ->
            subPageUpdate playerPage subMsg subModel model

        ( _, _ ) ->
            --Ignore by default
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subPageSubscriptions :
    SubPage initArgs subMsg subModel
    -> subModel
    -> Sub Msg
subPageSubscriptions subPage subModel =
    Sub.map subPage.msg (subPage.subscriptions subModel)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Events.onResize BrowserResize
        , Time.every 5000 GotTick
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
    SubPage initArgs subMsg subModel
    -> subModel
    -> Session
    -> Element Msg
subPageView subPage pageModel session =
    viewPage subPage.msg subPage.view pageModel session


subPageFullView :
    SubPage initArgs subMsg subModel
    -> subModel
    -> Session
    -> Element Msg
subPageFullView subPage subModel session =
    viewPage
        subPage.msg
        (S.fullPage subPage.view)
        subModel
        session


viewPage :
    (subMsg -> Msg)
    -> (subModel -> Session -> Element subMsg)
    -> subModel
    -> Session
    -> Element Msg
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

                PlayerModel pageModel ->
                    subPageFullView playerPage pageModel model.session
            )
        ]
    }
