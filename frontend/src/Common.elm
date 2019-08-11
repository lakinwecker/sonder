module Common exposing (..)

import Array exposing (Array, fromList, get, length)
import Browser
import Browser.Navigation as Nav
import Element exposing (..)
import Http
import Json.Decode
import List exposing (concat)
import Random
import String
import Url
import Graphql.Http
import Router


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
    = PageFailure String
    | PageLoading
    | PageLoaded


type RedirectStatus
    = RedirectFailure String
    | RedirectLoading


type NoArgs
    = NoArgs


type alias SubPagePartial initArgs subMsg subModel msg pageModel =
    { init : Session -> initArgs -> ( subModel, Cmd subMsg )
    , view : subModel -> Session -> Element subMsg
    , update : subMsg -> subModel -> ( subModel, Cmd subMsg )
    , subscriptions : subModel -> Sub subMsg
    , msg : subMsg -> msg
    , model : subModel -> pageModel
    }


type User
    = AuthorizedUser Username UserPreferences
    | Anonymous UserPreferences


type Username
    = Username String


type alias Size =
    { width : Int, height : Int }


type alias Session =
    { user : User
    , key : Nav.Key
    , device : Device
    , size : Size
    , csrfToken : String
    }


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


errorMsgFromHttp : Http.Error -> String
errorMsgFromHttp error =
    case error of
        Http.BadUrl message ->
            "Bad Url: " ++ message

        Http.Timeout ->
            "Timeout"

        Http.NetworkError ->
            "Network Error"

        Http.BadStatus status ->
            "Bad Status: " ++ String.fromInt (status)

        Http.BadBody message ->
            "Bad Body" ++ message


errorMsgFromGraphQL : Graphql.Http.Error a -> String
errorMsgFromGraphQL error =
    case error of
        Graphql.Http.GraphqlError _ errors ->
            "GraphQL Error"

        Graphql.Http.HttpError httpError ->
            case httpError of
                Graphql.Http.BadUrl message ->
                    "Bad Url: " ++ message

                Graphql.Http.Timeout ->
                    "Timeout"

                Graphql.Http.NetworkError ->
                    "Network Error"

                Graphql.Http.BadStatus metadata body ->
                    "Bad Status: " ++ String.fromInt (metadata.statusCode)

                Graphql.Http.BadPayload jsonError ->
                    "Bad Payload" ++ (Json.Decode.errorToString jsonError)
