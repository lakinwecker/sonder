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
    | PlayerListPage PlayerList.Model
    | DashboardPage Dashboard.Model



-- TODO: add these in later
--| UnauthorizedPage
--| HomePage


type alias Model =
    { session : Session
    , page : CurrentPage
    }


urlToPage : Url.Url -> ( CurrentPage, Cmd Msg )
urlToPage url =
    let
        route =
            Router.parse Router.routeParser url
    in
        case route of
            Just Router.Login ->
                ( LoginPage Login.init, Cmd.map GotLoginMsg Login.load )

            Just Router.Unauthorized ->
                ( LoginPage Login.init, Cmd.map GotLoginMsg Login.load )

            --( UnauthorizedPage, Cmd.none )
            Just Router.Dashboard ->
                ( DashboardPage Dashboard.init, Cmd.map GotDashboardMsg Dashboard.load )

            Just Router.PlayerList ->
                ( PlayerListPage PlayerList.init, Cmd.map GotPlayerListMsg PlayerList.load )

            Nothing ->
                ( LoginPage Login.init, Cmd.map GotLoginMsg Login.load )


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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
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
                ( { model | page = page }
                , cmd
                )

        --( AuthStatus result, _ ) ->
        --case result of
        --Ok user ->
        --( { model | user = user }, Cmd.none )
        --
        --Err _ ->
        --( { model | page = LoginPage { status = Failure } }, Cmd.none )
        ( BrowserResize w h, _ ) ->
            let
                oldSession =
                    model.session

                newSession =
                    { oldSession | device = classifyDevice { width = w, height = h } }
            in
                ( { model | session = newSession }, Cmd.none )

        ( GotLoginMsg subMsg, LoginPage subModel ) ->
            Login.update subMsg subModel
                |> updateWith LoginPage GotLoginMsg model

        ( GotPlayerListMsg subMsg, PlayerListPage subModel ) ->
            PlayerList.update subMsg subModel
                |> updateWith PlayerListPage GotPlayerListMsg model

        ( GotDashboardMsg subMsg, DashboardPage subModel ) ->
            Dashboard.update subMsg subModel
                |> updateWith DashboardPage GotDashboardMsg model

        ( _, _ ) ->
            -- Disregard messages that arrived for the wrong page.
            ( model, Cmd.none )


updateWith : (subModel -> CurrentPage) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toCurrentPage toMsg model ( subModel, subCmd ) =
    ( { model | page = toCurrentPage subModel }
    , Cmd.map toMsg subCmd
    )



{--
        _ ->
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


viewPage : (subMsg -> Msg) -> (subModel -> Element subMsg) -> subModel -> Element Msg
viewPage toMsg subView model =
    let
        body =
            subView model
    in
        Element.map toMsg body


view : Model -> Browser.Document Msg
view model =
    let
        viewFullPage toMsg subView subModel =
            viewPage toMsg (S.fullPage model.session subView) subModel
    in
        { title = "Sonder"
        , body =
            [ FAStyles.css
            , Element.layout
                [ S.viewBackgroundForUser model.session.user ]
                (case model.page of
                    LoginPage pageModel ->
                        viewPage GotLoginMsg Login.view pageModel

                    DashboardPage pageModel ->
                        viewFullPage GotDashboardMsg Dashboard.view pageModel

                    --UnauthorizedPage ->
                    --S.unauthorizedPage
                    PlayerListPage pageModel ->
                        viewFullPage GotPlayerListMsg PlayerList.view pageModel
                )
            ]
        }
