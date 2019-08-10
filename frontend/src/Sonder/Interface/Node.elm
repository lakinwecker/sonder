-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Sonder.Interface.Node exposing (Fragments, fragments, id, maybeFragments)

import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (FragmentSelectionSet(..), SelectionSet(..))
import Json.Decode as Decode
import Sonder.InputObject
import Sonder.Interface
import Sonder.Object
import Sonder.Scalar
import Sonder.ScalarCodecs
import Sonder.Union


type alias Fragments decodesTo =
    { onPlayerNode : SelectionSet decodesTo Sonder.Object.PlayerNode
    , onGameNode : SelectionSet decodesTo Sonder.Object.GameNode
    }


{-| Build an exhaustive selection of type-specific fragments.
-}
fragments :
    Fragments decodesTo
    -> SelectionSet decodesTo Sonder.Interface.Node
fragments selections =
    Object.exhuastiveFragmentSelection
        [ Object.buildFragment "PlayerNode" selections.onPlayerNode
        , Object.buildFragment "GameNode" selections.onGameNode
        ]


{-| Can be used to create a non-exhuastive set of fragments by using the record
update syntax to add `SelectionSet`s for the types you want to handle.
-}
maybeFragments : Fragments (Maybe decodesTo)
maybeFragments =
    { onPlayerNode = Graphql.SelectionSet.empty |> Graphql.SelectionSet.map (\_ -> Nothing)
    , onGameNode = Graphql.SelectionSet.empty |> Graphql.SelectionSet.map (\_ -> Nothing)
    }


{-| The ID of the object.
-}
id : SelectionSet Sonder.ScalarCodecs.Id Sonder.Interface.Node
id =
    Object.selectionForField "ScalarCodecs.Id" "id" [] (Sonder.ScalarCodecs.codecs |> Sonder.Scalar.unwrapCodecs |> .codecId |> .decoder)