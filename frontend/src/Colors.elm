module Colors exposing (..)

import Element exposing (Color, rgba255, toRgb, rgba)


alpha : Color -> Float -> Color
alpha color a =
    let
        c =
            toRgb color
    in
        rgba c.red c.green c.blue a



-- Coolors Exported Palette - coolors.co/00008a-4c74e3-05f8fc-8426f8-ff7a3f


white : Color
white =
    rgba255 255 255 255 1


black : Color
black =
    rgba255 0 0 0 1


grey : Color
grey =
    rgba255 90 90 90 1


lightGrey : Color
lightGrey =
    rgba255 230 230 230 1


primaryShade0 : Color
primaryShade0 =
    rgba255 232 232 234 1


secondaryShade0 : Color
secondaryShade0 =
    rgba255 238 238 238 1


ternaryShade0 =
    rgba255 234 236 239 1


quaternaryShade0 =
    rgba255 255 254 243 1


quinaryShade0 =
    rgba255 236 237 238 1


primaryShade1 =
    rgba255 140 141 151 1


secondaryShade1 =
    rgba255 173 173 171 1


ternaryShade1 =
    rgba255 154 160 175 1


quaternaryShade1 =
    rgba255 255 254 198 1


quinaryShade1 =
    rgba255 160 165 174 1


primaryShade2 =
    rgba255 26 28 47 1


secondaryShade2 =
    rgba255 92 92 87 1


ternaryShade2 =
    rgba255 54 65 95 1


quaternaryShade2 =
    rgba255 255 253 141 1


quinaryShade2 =
    rgba255 65 75 93 1


primaryShade3 =
    rgba255 3 4 18 1


secondaryShade3 =
    rgba255 49 49 46 1


ternaryShade3 =
    rgba255 22 30 51 1


quaternaryShade3 =
    rgba255 163 162 83 1


quinaryShade3 =
    rgba255 30 37 50 1


celestialBlue0 =
    rgba255 237 245 250 1


queenBlue0 =
    rgba255 235 240 244 1


charcoalBlue0 =
    rgba255 233 236 239 1


celestialBlue1 =
    rgba255 167 205 231 1


queenBlue1 =
    rgba255 158 183 204 1


charcoalBlue1 =
    rgba255 149 161 175 1


celestialBlue2 =
    rgba255 79 155 208 1


queenBlue2 =
    rgba255 61 112 153 1


charcoalBlue2 =
    rgba255 43 68 95 1


celestialBlue3 =
    rgba255 40 93 130 1


queenBlue3 =
    rgba255 27 63 92 1


charcoalBlue3 =
    rgba255 15 32 51 1
