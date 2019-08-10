module Auth exposing (..)

import Element exposing (..)
import Common exposing (..)
import Json.Decode exposing (Decoder, field, string, oneOf, succeed, at)
import Json.Decode.Extra exposing (when, andMap)
import Http


is : a -> a -> Bool
is a b =
    a == b


userType : Decoder String
userType =
    field "type" string


userFromStatus : Decoder User
userFromStatus =
    oneOf
        [ when userType
            (is "anonymous")
            (succeed
                (Anonymous
                    { background = (getBackground 0) }
                )
            )
        , when userType
            (is "authorized")
            (succeed authorizedUserFromDict
                |> andMap (field "username" string)
                |> andMap (at [ "preferences", "background" ] string)
            )
        ]


authorizedUserFromDict : String -> String -> User
authorizedUserFromDict username background =
    AuthorizedUser
        (Username username)
        (userPreferenceBackground background)


userPreferenceBackground : String -> UserPreferences
userPreferenceBackground url =
    { background =
        case url of
            "" ->
                getBackground 0

            _ ->
                BackgroundImage url
    }
