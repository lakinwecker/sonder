module Router exposing (..)

import Url.Parser as URLParser exposing (Parser, (</>), int, map, oneOf, s, string)


type Route
    = Login
    | Unauthorized
    | Dashboard


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map Login (s "login")
        , map Unauthorized (s "login" </> s "unauthorized")
        , map Dashboard (s "dashboard")
        ]


parse =
    URLParser.parse
