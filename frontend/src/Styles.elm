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
import List exposing (concat)
import Common exposing (..)
import Content


scaled x =
    round (modular 14 1.25 x)


lato =
    Font.family [ Font.typeface "Lato", Font.typeface "sans-serif" ]


raleway =
    Font.family [ Font.typeface "Raleway", Font.typeface "sans-serif" ]


coustard =
    Font.family [ Font.typeface "Coustard", Font.typeface "sans-serif" ]


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


spinIcon extra icon =
    el
        (concat
            [ textBox
            , [ paddingXY 30 30, width fill ]
            , extra
            ]
        )
        (el
            [ centerX ]
            (html
                (Icon.viewStyled
                    [ Attributes.fa4x, Attributes.spin ]
                    icon
                )
            )
        )


spinnerBase extra =
    spinIcon extra Solid.spinner


spinner =
    spinnerBase []


fullPageSpinner =
    spinnerBase [ height fill ]


cogBase extra =
    spinIcon extra Solid.cog


cog =
    cogBase []


fullPageCog =
    cogBase [ height fill ]


loginButton : Element msg
loginButton =
    link
        (concat [ button ])
        { url = "/login", label = text "Login" }


error : Session -> String -> Element msg
error session msg =
    el
        (concat
            [ textFont
            , textBox
            , errorSize
            , [ paddingXY 30 30, width fill ]
            ]
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


logo : Element msg
logo =
    el
        (concat
            [ logoFont, heroBox, [ padding 30, width fill ] ]
        )
        (text "Sonder")


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


splashPage : Session -> Element msg
splashPage session =
    column
        [ centerY
        , centerX
        , spacing 0
        , padding 200
        ]
        [ logo, intro ]


thinLogo : Element msg
thinLogo =
    el
        (concat
            [ smallLogoFont
            , heroBox
            , [ paddingXY 30 10, width fill ]
            ]
        )
        (text "Sonder")


intro : Element msg
intro =
    el
        (concat
            [ textFont
            , textBox
            , introSize
            , [ paddingXY 30 30, width fill ]
            ]
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
        (concat
            [ textFont
            , textBox
            , introSize
            , [ paddingXY 30 30, width fill ]
            ]
        )
        (column [ spacing 30 ]
            [ paragraph []
                [ text Content.unauthorized
                ]
            , loginButton
            ]
        )


fullPage mainFunc pageModel session =
    column [ spacing 0, width fill, height (px session.size.height) ]
        [ row [ width fill, height (px 50) ] [ thinLogo ]
        , row [ width fill, height fill ]
            [ sidebar session
            , el [ width fill, height (px (session.size.height - 50)), scrollbars ]
                (case session.user of
                    Anonymous _ ->
                        fullPageSpinner

                    (AuthorizedUser _ _) as user ->
                        mainFunc pageModel session
                )
            ]
        ]


footer : Session -> Element msg
footer session =
    el
        (concat
            [ footerFont
            , footerSize
            , [ spacing 2, height shrink, width fill ]
            ]
        )
        (row []
            [ footerDevice session.device
            , footerUser session.user
            ]
        )


footerDevice : Device -> Element msg
footerDevice device =
    el
        (concat
            [ footerFont
            , footerSize
            , [ paddingXY 5 5, width fill ]
            ]
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
        (concat
            [ footerFont
            , footerSize
            , [ paddingXY 5 5, width fill ]
            ]
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
        (concat
            [ textFont
            , textBox
            , [ height fill
              , Border.widthEach { bottom = 0, top = 0, left = 0, right = 2 }
              ]
            ]
        )
        [ row [ height fill ] [ nav session ]
        , footer session
        ]
