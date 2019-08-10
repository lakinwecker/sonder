module Main exposing (..)

import Array exposing (Array, fromList, get, length)
import Browser
import Browser.Navigation as Nav
import Browser.Events as Events
import Element exposing (..)
import FontAwesome.Styles as FAStyles
import Router
import Common exposing (..)
import Login
import PlayerList
import Http
import Dashboard


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
    = LoginModel Login.Model
    | PlayerListModel PlayerList.Model
    | DashboardModel Dashboard.Model



-- TODO: add these in later
--| UnauthorizedPage
--| HomePage


type alias Model =
    { session : Session
    , subModel : SubPageModel
    }


loginPage =
    Login.page
        GotLoginMsg
        LoginModel


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
            Just Router.Login ->
                subPageInit loginPage

            Just Router.Unauthorized ->
                subPageInit loginPage

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
    | GotLoginMsg Login.Msg
    | GotPlayerListMsg PlayerList.Msg
    | GotDashboardMsg Dashboard.Msg


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
            -- Disregard messages that arrived for the wrong page.
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
          )
        ]



-- VIEW


viewPage : (subMsg -> Msg) -> (subModel -> Session -> Element subMsg) -> subModel -> Session -> Element Msg
viewPage toMsg subView model session =
    let
        body =
            subView model session
    in
        Element.map toMsg body


view : Model -> Browser.Document Msg
view model =
    let
        viewFullPage toMsg subView subModel =
            viewPage toMsg (S.fullPage subView) subModel model.session
    in
        { title = "Sonder"
        , body =
            [ FAStyles.css
            , Element.layout
                [ S.viewBackgroundForUser model.session.user ]
                (case model.subModel of
                    LoginModel pageModel ->
                        viewPage GotLoginMsg Login.view pageModel model.session

                    DashboardModel pageModel ->
                        viewFullPage GotDashboardMsg Dashboard.view pageModel

                    PlayerListModel pageModel ->
                        viewFullPage GotPlayerListMsg PlayerList.view pageModel
                )
            ]
        }
