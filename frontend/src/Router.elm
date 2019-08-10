module Router exposing (..)

import Url.Parser as URLParser exposing (Parser, (</>), int, map, oneOf, s, string, top)


type Route
    = Splash
    | Login
    | Unauthorized
    | Dashboard
    | PlayerList


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map Splash top
        , map Login (s "login")
        , map Dashboard (s "dashboard")
        , map PlayerList (s "players")
        , map Unauthorized (s "login" </> s "unauthorized")
        ]


parse =
    URLParser.parse
