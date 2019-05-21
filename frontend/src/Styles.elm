module Styles exposing (..)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Region as Region
import Colors as C


scaled x =
    round (modular 24 1.25 x)


alfaSlab =
    Font.family [ Font.typeface "Alfa Slab One", Font.typeface "cursive" ]


lora =
    Font.family [ Font.typeface "Lora", Font.typeface "serif" ]


lato =
    Font.family [ Font.typeface "Lato", Font.typeface "sans-serif" ]


titleFont : List (Attribute msg)
titleFont =
    [ alfaSlab
    , Font.size (scaled 8)
    ]


heroBox : List (Attribute msg)
heroBox =
    [ Background.color C.secondaryShade2
    , Font.color C.quinaryShade1
    , alpha 0.97
    ]


textFont : List (Attribute msg)
textFont =
    [ lora ]


textBox : List (Attribute msg)
textBox =
    [ Background.color C.lightGrey
    , Font.color C.secondaryShade3
    ]


introSize : List (Attribute msg)
introSize =
    [ Font.size (scaled 2)
    , Font.bold
    ]


button : List (Attribute msg)
button =
    [ Background.color C.primaryShade1
    , Border.color C.primaryShade2
    , Border.rounded 10
    , Border.width 4
    , Font.color C.primaryShade3
    , paddingXY 50 20
    , Font.variant Font.smallCaps
    , lato
    , alignRight
    ]
