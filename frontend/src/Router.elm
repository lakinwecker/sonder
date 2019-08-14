module Router exposing (..)

import Url.Parser as URLParser exposing (Parser, (</>), int, map, oneOf, s, string, top)


type Route
    = Splash
    | Login
    | Unauthorized
    | Dashboard
    | PlayerList
    | Player String
    | Colours


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map Splash top
        , map Login (s "login")
        , map Dashboard (s "dashboard")
        , map PlayerList (s "players")
        , map Colours (s "colours")
        , map Player (s "players" </> string)
        , map Unauthorized (s "login" </> s "unauthorized")
        ]


parse =
    URLParser.parse
