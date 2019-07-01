module Common exposing (..)

import Array exposing (Array, fromList, get, length)
import Browser
import Element exposing (..)
import Http
import List exposing (concat)
import Random
import Url


type UserBackground
    = BackgroundImage String
    | BackgroundColor Int Int Int


backgrounds : Array UserBackground
backgrounds =
    fromList
        [ BackgroundImage "/static/sonder/frontend/images/architecture-building-city-1137525.jpg"
        , BackgroundImage "/static/sonder/frontend/images/architecture-buildings-city-2067048.jpg"
        ]


type alias UserPreferences =
    { background : UserBackground }


defaultUserPreferences =
    { background = defaultBackground }


type PageStatus
    = Failure
    | Loading


type User
    = AuthorizedUser Username UserPreferences
    | Anonymous UserPreferences


type Username
    = Username String


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotLichessOAuthURL (Result Http.Error String)
    | AuthStatus (Result Http.Error User)
    | BrowserResize Int Int


defaultBackgroundColor =
    BackgroundColor 0 0 0


getBackground : Int -> UserBackground
getBackground i =
    Maybe.withDefault defaultBackgroundColor (get i backgrounds)


defaultBackground : UserBackground
defaultBackground =
    getBackground 0


newBackground : UserBackground -> UserPreferences -> UserPreferences
newBackground bg up =
    { up | background = bg }


newBackgroundForUser : UserBackground -> User -> User
newBackgroundForUser bg u =
    case u of
        Anonymous prefs ->
            Anonymous (newBackground bg prefs)

        AuthorizedUser (Username username) prefs ->
            AuthorizedUser (Username username) (newBackground bg prefs)


randomBackgroundIndex : Random.Generator Int
randomBackgroundIndex =
    length backgrounds |> Random.int 0
