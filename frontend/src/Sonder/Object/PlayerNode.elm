-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Sonder.Object.PlayerNode exposing (GamesAsBlackOptionalArguments, GamesAsWhiteOptionalArguments, gamesAsBlack, gamesAsWhite, id, username)

import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode
import Sonder.InputObject
import Sonder.Interface
import Sonder.Object
import Sonder.Scalar
import Sonder.ScalarCodecs
import Sonder.Union


{-| The ID of the object.
-}
id : SelectionSet Sonder.ScalarCodecs.Id Sonder.Object.PlayerNode
id =
    Object.selectionForField "ScalarCodecs.Id" "id" [] (Sonder.ScalarCodecs.codecs |> Sonder.Scalar.unwrapCodecs |> .codecId |> .decoder)


{-| -}
username : SelectionSet String Sonder.Object.PlayerNode
username =
    Object.selectionForField "String" "username" [] Decode.string


type alias GamesAsWhiteOptionalArguments =
    { before : OptionalArgument String
    , after : OptionalArgument String
    , first : OptionalArgument Int
    , last : OptionalArgument Int
    , whitePlayer_Username : OptionalArgument Sonder.ScalarCodecs.Id
    , blackPlayer_Username : OptionalArgument Sonder.ScalarCodecs.Id
    }


{-| -}
gamesAsWhite : (GamesAsWhiteOptionalArguments -> GamesAsWhiteOptionalArguments) -> SelectionSet decodesTo Sonder.Object.GameNodeConnection -> SelectionSet (Maybe decodesTo) Sonder.Object.PlayerNode
gamesAsWhite fillInOptionals object_ =
    let
        filledInOptionals =
            fillInOptionals { before = Absent, after = Absent, first = Absent, last = Absent, whitePlayer_Username = Absent, blackPlayer_Username = Absent }

        optionalArgs =
            [ Argument.optional "before" filledInOptionals.before Encode.string, Argument.optional "after" filledInOptionals.after Encode.string, Argument.optional "first" filledInOptionals.first Encode.int, Argument.optional "last" filledInOptionals.last Encode.int, Argument.optional "whitePlayer_Username" filledInOptionals.whitePlayer_Username (Sonder.ScalarCodecs.codecs |> Sonder.Scalar.unwrapEncoder .codecId), Argument.optional "blackPlayer_Username" filledInOptionals.blackPlayer_Username (Sonder.ScalarCodecs.codecs |> Sonder.Scalar.unwrapEncoder .codecId) ]
                |> List.filterMap identity
    in
    Object.selectionForCompositeField "gamesAsWhite" optionalArgs object_ (identity >> Decode.nullable)


type alias GamesAsBlackOptionalArguments =
    { before : OptionalArgument String
    , after : OptionalArgument String
    , first : OptionalArgument Int
    , last : OptionalArgument Int
    , whitePlayer_Username : OptionalArgument Sonder.ScalarCodecs.Id
    , blackPlayer_Username : OptionalArgument Sonder.ScalarCodecs.Id
    }


{-| -}
gamesAsBlack : (GamesAsBlackOptionalArguments -> GamesAsBlackOptionalArguments) -> SelectionSet decodesTo Sonder.Object.GameNodeConnection -> SelectionSet (Maybe decodesTo) Sonder.Object.PlayerNode
gamesAsBlack fillInOptionals object_ =
    let
        filledInOptionals =
            fillInOptionals { before = Absent, after = Absent, first = Absent, last = Absent, whitePlayer_Username = Absent, blackPlayer_Username = Absent }

        optionalArgs =
            [ Argument.optional "before" filledInOptionals.before Encode.string, Argument.optional "after" filledInOptionals.after Encode.string, Argument.optional "first" filledInOptionals.first Encode.int, Argument.optional "last" filledInOptionals.last Encode.int, Argument.optional "whitePlayer_Username" filledInOptionals.whitePlayer_Username (Sonder.ScalarCodecs.codecs |> Sonder.Scalar.unwrapEncoder .codecId), Argument.optional "blackPlayer_Username" filledInOptionals.blackPlayer_Username (Sonder.ScalarCodecs.codecs |> Sonder.Scalar.unwrapEncoder .codecId) ]
                |> List.filterMap identity
    in
    Object.selectionForCompositeField "gamesAsBlack" optionalArgs object_ (identity >> Decode.nullable)
