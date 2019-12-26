module Data exposing (..)

import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, with)
import Sonder.Object
import Sonder.Object.Player as Player
import Sonder.Object.CRReport as CRReport
import Sonder.Object.CPLoss as CPLoss
import Sonder.Object.Game as Game
import Sonder.ScalarCodecs exposing (Id)


type alias CPLoss =
    { title : String
    , count : Int
    }


cpLossCompleteSelection : SelectionSet CPLoss Sonder.Object.CPLoss
cpLossCompleteSelection =
    SelectionSet.map2 CPLoss
        CPLoss.title
        CPLoss.count


type alias CRReport =
    { sampleSize : Int
    , sampleTotalCpl : Int
    , t1Total : Int
    , t1Count : Int
    , t2Total : Int
    , t2Count : Int
    , t3Total : Int
    , t3Count : Int
    , minRating : Maybe Int
    , maxRating : Maybe Int
    , gameList : List String
    , cpLossTotal : Int
    , cpLossCount : List CPLoss
    }


crReportResultCompleteSelection : SelectionSet CRReport Sonder.Object.CRReport
crReportResultCompleteSelection =
    SelectionSet.succeed CRReport
        |> with CRReport.sampleSize
        |> with CRReport.sampleTotalCpl
        |> with CRReport.t1Total
        |> with CRReport.t1Count
        |> with CRReport.t2Total
        |> with CRReport.t2Count
        |> with CRReport.t3Total
        |> with CRReport.t3Count
        |> with CRReport.minRating
        |> with CRReport.maxRating
        |> with CRReport.gameList
        |> with CRReport.cpLossTotal
        |> with (CRReport.cpLossCount cpLossCompleteSelection)


type alias Game =
    { id : Id
    , lichessId : String
    , whitePlayer : Player
    , blackPlayer : Player
    , timeControl : String
    }


gameSelection : SelectionSet Game Sonder.Object.Game
gameSelection =
    SelectionSet.succeed Game
        |> with Game.id
        |> with Game.lichessId
        |> with (Game.whitePlayer playerCompleteSelection)
        |> with (Game.blackPlayer playerCompleteSelection)
        |> with Game.timeControl


type alias Player =
    { username : String
    , totalGames : Int
    }


playerCompleteSelection : SelectionSet Player Sonder.Object.Player
playerCompleteSelection =
    SelectionSet.map2 Player
        Player.username
        Player.totalGames
