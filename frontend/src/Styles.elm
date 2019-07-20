module Styles exposing (..)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Region as Region
import Colors as C


scaled x =
    round (modular 20 1.25 x)


lato =
    Font.family [ Font.typeface "Lato", Font.typeface "sans-serif" ]


raleway =
    Font.family [ Font.typeface "Raleway", Font.typeface "sans-serif" ]


coustard =
    Font.family [ Font.typeface "Coustard", Font.typeface "sans-serif" ]


backgroundAlpha =
    0.85


bg : Color -> Color
bg c =
    C.alpha c backgroundAlpha


titleFont : List (Attribute msg)
titleFont =
    [ coustard
    , Font.size (scaled 4)
    ]


heroBox : List (Attribute msg)
heroBox =
    [ Background.color (bg C.primaryShade3)
    , Font.color C.quaternaryShade2
    ]


textFont : List (Attribute msg)
textFont =
    [ raleway ]


textBox : List (Attribute msg)
textBox =
    [ Background.color (bg C.white)
    , Font.color C.black
    ]


introSize : List (Attribute msg)
introSize =
    [ Font.size (scaled 1)
    , Font.regular
    ]


errorSize : List (Attribute msg)
errorSize =
    [ Font.size (scaled 1)
    ]


button : List (Attribute msg)
button =
    [ Background.color C.queenBlue2
    , Border.color C.charcoalBlue1
    , Border.rounded 10
    , Border.width 4
    , Font.color C.celestialBlue0
    , paddingXY 50 20
    , Font.variant Font.smallCaps
    , coustard
    , alignRight
    ]
