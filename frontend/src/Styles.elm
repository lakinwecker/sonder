module Styles exposing (..)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Region as Region
import Colors as C
import FontAwesome.Attributes as Attributes
import FontAwesome.Solid as Solid
import FontAwesome.Icon as Icon
import Common exposing (..)
import RemoteData exposing (RemoteData)
import Graphql.Http
import Content


--------------------------------------------------------------------------------
-- Style Attributes
--------------------------------------------------------------------------------


type alias BorderWidth =
    { bottom : Int
    , left : Int
    , right : Int
    , top : Int
    }


defaultBorder : BorderWidth
defaultBorder =
    { bottom = 0, left = 0, right = 0, top = 0 }


scaled : Int -> Int
scaled x =
    round (modular 14 1.25 x)


lato : Attribute msg
lato =
    Font.family [ Font.typeface "Lato", Font.typeface "sans-serif" ]


raleway : Attribute msg
raleway =
    Font.family [ Font.typeface "Raleway", Font.typeface "sans-serif" ]


coustard : Attribute msg
coustard =
    Font.family [ Font.typeface "Coustard", Font.typeface "serif" ]


robotoSlab : Attribute msg
robotoSlab =
    Font.family [ Font.typeface "Roboto Slab", Font.typeface "serif" ]


backgroundAlpha : Float
backgroundAlpha =
    0.85


background : Color -> Color
background c =
    C.alpha c backgroundAlpha


logoFont : List (Attribute msg)
logoFont =
    [ coustard
    , Font.size (scaled 6)
    ]


smallLogoFont : List (Attribute msg)
smallLogoFont =
    [ coustard
    , Font.size (scaled 5)
    ]


heroBox : List (Attribute msg)
heroBox =
    [ Background.color (background C.primaryShade3)
    , Font.color C.quaternaryShade2
    ]


textFont : List (Attribute msg)
textFont =
    [ raleway ]


footerFont : List (Attribute msg)
footerFont =
    [ raleway ]


textBox : List (Attribute msg)
textBox =
    [ Background.color (background C.white)
    , Font.color C.black
    ]


content : List (Attribute msg)
content =
    [ Background.color C.white
    , Font.color C.black
    , Border.rounded 5
    , Border.width 1
    , Border.color C.quaternaryShade2
    , padding 5
    ]


introSize : List (Attribute msg)
introSize =
    [ Font.size (scaled 3)
    , Font.regular
    ]


errorSize : List (Attribute msg)
errorSize =
    [ Font.size (scaled 3)
    ]


footerSize : List (Attribute msg)
footerSize =
    [ Font.size (scaled 1)
    ]


fillXY : List (Attribute msg)
fillXY =
    [ height fill, width fill ]


centerXY : List (Attribute msg)
centerXY =
    [ centerX, centerY ]


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


spinIcon : List (Attribute msg) -> Icon.Icon -> Element msg
spinIcon extra icon =
    el
        (fillXY ++ extra)
        (el
            [ centerX, centerY ]
            (html
                (Icon.viewStyled
                    [ Attributes.fa4x, Attributes.spin ]
                    icon
                )
            )
        )


spinnerBase : List (Attribute msg) -> Element msg
spinnerBase extra =
    spinIcon extra Solid.spinner


spinner : Element msg
spinner =
    spinnerBase []


fullPageSpinner : Element msg
fullPageSpinner =
    spinnerBase fillXY


cogBase : List (Attribute msg) -> Element msg
cogBase extra =
    spinIcon extra Solid.cog


cog : Element msg
cog =
    cogBase []


fullPageCog : Element msg
fullPageCog =
    cogBase fillXY


viewBackground : UserBackground -> Element.Attribute msg
viewBackground bg =
    case bg of
        BackgroundImage url ->
            Background.image url

        BackgroundColor r g b ->
            Background.color (rgb255 r g b)


viewBackgroundForUser : User -> Element.Attribute msg
viewBackgroundForUser u =
    case u of
        Anonymous prefs ->
            viewBackground prefs.background

        AuthorizedUser _ prefs ->
            viewBackground prefs.background



--------------------------------------------------------------------------------
-- Fragments of a view
--------------------------------------------------------------------------------


loginButton : Element msg
loginButton =
    link
        button
        { url = "/login", label = text "Login" }


logo : Element msg
logo =
    el
        (logoFont
            ++ heroBox
            ++ [ padding 30, width fill ]
        )
        (text "Sonder")


thinLogo : Element msg
thinLogo =
    el
        (smallLogoFont
            ++ heroBox
            ++ [ paddingXY 30 10, width fill ]
        )
        (text "Sonder")


intro : Element msg
intro =
    el
        (textFont
            ++ textBox
            ++ introSize
            ++ [ paddingXY 30 30, width fill ]
        )
        (column [ spacing 30 ]
            [ paragraph []
                [ text Content.intro
                ]
            , loginButton
            ]
        )


unauthorizedPage : Session -> Element msg
unauthorizedPage session =
    column [ centerY, centerX, spacing 0, padding 200 ]
        [ logo, unauthorized ]


unauthorized : Element msg
unauthorized =
    el
        (textFont
            ++ textBox
            ++ introSize
            ++ [ paddingXY 30 30, width fill ]
        )
        (column [ spacing 30 ]
            [ paragraph []
                [ text Content.unauthorized
                ]
            , loginButton
            ]
        )


footer : Session -> Element msg
footer session =
    el
        (footerFont
            ++ footerSize
            ++ [ spacing 2, height shrink, width fill ]
        )
        (row []
            [ footerDevice session.device
            , footerUser session.user
            ]
        )


footerDevice : Device -> Element msg
footerDevice device =
    el
        (footerFont
            ++ footerSize
            ++ [ paddingXY 5 5, width fill ]
        )
        (row []
            [ html
                (Icon.viewStyled
                    []
                    (case device.class of
                        Phone ->
                            Solid.mobile

                        Tablet ->
                            Solid.tablet

                        Desktop ->
                            Solid.desktop

                        BigDesktop ->
                            Solid.tv
                    )
                )
            ]
        )


footerUser : User -> Element msg
footerUser user =
    el
        (footerFont
            ++ footerSize
            ++ [ paddingXY 5 5, width fill ]
        )
        (row []
            [ html
                (Icon.viewStyled
                    []
                    (case user of
                        Anonymous _ ->
                            Solid.userSlash

                        AuthorizedUser _ _ ->
                            Solid.user
                    )
                )
            ]
        )


nav session =
    column
        [ height fill
        , padding 30
        , spacing 20
        ]
        [ link
            []
            { url = "/players", label = text "Players" }

        --text "Reports"
        --, text "Analysis"
        --, text "Tags"
        ]


sidebar session =
    column
        (textFont
            ++ textBox
            ++ [ height fill
               , Border.widthEach { defaultBorder | right = 2 }
               ]
        )
        [ row [ height fill ] [ nav session ]
        , footer session
        ]


tableHeader : String -> Element msg
tableHeader val =
    el
        [ robotoSlab
        , paddingXY 10 10
        , Font.bold
        , Border.widthEach { defaultBorder | bottom = 2 }
        , Border.color C.secondaryShade2
        ]
        (text val)


tableCell : List (Attribute msg) -> (a -> Element msg) -> a -> Element msg
tableCell extra toEl val =
    el
        ([ lato, paddingXY 10 10 ]
            ++ extra
        )
        (toEl val)


remoteDataPage :
    (model -> Session -> a -> Element msg)
    -> model
    -> Session
    -> RemoteData (Graphql.Http.Error a) a
    -> Element msg
remoteDataPage view model session maybeData =
    case maybeData of
        RemoteData.NotAsked ->
            fullPageCog

        RemoteData.Loading ->
            fullPageSpinner

        RemoteData.Failure message ->
            errorMsgFromGraphQL message
                |> error session

        RemoteData.Success data ->
            view model session data



--------------------------------------------------------------------------------
-- Views
--------------------------------------------------------------------------------
-- The hardcoded 50px in fullPage is a bit too much but
-- it's the only way I can get the scrollbars working


fullPage mainFunc pageModel session =
    column [ spacing 0, width fill, height (px session.size.height) ]
        [ row [ width fill, height (px 50) ] [ thinLogo ]
        , row fillXY
            [ sidebar session
            , el
                (textBox
                    ++ textFont
                    ++ [ paddingXY 10 10
                       , width fill
                       , height (px (session.size.height - 50))
                       , scrollbars
                       ]
                )
                (case session.user of
                    Anonymous _ ->
                        fullPageSpinner

                    (AuthorizedUser _ _) as user ->
                        mainFunc pageModel session
                )
            ]
        ]


splashPage : Session -> Element msg
splashPage session =
    column
        [ centerY
        , centerX
        , spacing 0
        , padding 200
        ]
        [ logo, intro ]


coloursTable : pageModel -> Session -> Element msg
coloursTable pageModel session =
    let
        c color title =
            el
                ([ Background.color color ]
                    ++ fillXY
                )
                (el
                    ([ coustard ]
                        ++ centerXY
                    )
                    (text title)
                )
    in
        column
            (fillXY
                ++ content
            )
            [ column
                (centerXY
                    ++ fillXY
                )
                [ (column
                    ([ spacing 10 ]
                        ++ fillXY
                    )
                    [ row
                        ([ spacing 10 ]
                            ++ fillXY
                        )
                        [ c C.primaryShade0 "Primary 0"
                        , c C.secondaryShade0 "Secondary 0"
                        , c C.ternaryShade0 "Ternary 0"
                        , c C.quaternaryShade0 "Quaternary 0"
                        , c C.quinaryShade0 "Quinary 0"
                        ]
                    , row
                        ([ spacing 10 ]
                            ++ fillXY
                        )
                        [ c C.primaryShade1 "Primary 1"
                        , c C.secondaryShade1 "Secondary 1"
                        , c C.ternaryShade1 "Ternary 1"
                        , c C.quaternaryShade1 "Quaternary 1"
                        , c C.quinaryShade1 "Quinary 1"
                        ]
                    , row
                        ([ spacing 10 ]
                            ++ fillXY
                        )
                        [ c C.primaryShade2 "Primary 2"
                        , c C.secondaryShade2 "Secondary 2"
                        , c C.ternaryShade2 "Ternary 2"
                        , c C.quaternaryShade2 "Quaternary 2"
                        , c C.quinaryShade2 "Quinary 2"
                        ]
                    , row
                        ([ spacing 10 ]
                            ++ fillXY
                        )
                        [ c C.primaryShade3 "Primary 3"
                        , c C.secondaryShade3 "Secondary 3"
                        , c C.ternaryShade3 "Ternary 3"
                        , c C.quaternaryShade3 "Quaternary 3"
                        , c C.quinaryShade3 "Quinary 3"
                        ]
                    ]
                  )
                ]
            ]


coloursPage : Session -> Element msg
coloursPage session =
    fullPage coloursTable [] session


error : Session -> String -> Element msg
error session msg =
    el
        (textFont
            ++ textBox
            ++ errorSize
            ++ [ paddingXY 30 30, width fill ]
        )
        (column [ spacing 30 ]
            (case session.user of
                Anonymous _ ->
                    [ paragraph [] [ text msg ]
                    , loginButton
                    ]

                AuthorizedUser _ _ ->
                    [ paragraph [] [ text msg ] ]
            )
        )
