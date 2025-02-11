
extensions [gis]
breed [targets target]
globals [
         build            ;; GIS dataset
         foot             ;; GIS dataset
         inter            ;; GIS dataset
         patch_size
         build_col
         foot_col
         inter_col
         nest_col
         back_col
         ]

patches-own
[
  turtles-num   ;; number of turtles on the patch
    counter
]

turtles-own
[
  destination?                ;; true on destination patches, false elsewhere
  stop?
  old-px
  old-py
  px
  py
  cnt
  speed
  time
  dist
]


to setup

  __clear-all-and-reset-ticks

  set build_col 7
  set foot_col 38
  set inter_col 38
  set nest_col green
  set back_col 9.7


  set patch_size 5
  set-patch-size patch_size


  set build gis:load-dataset "data/buildings.shp"
  set inter gis:load-dataset "data/internal_roads.shp"
  set foot gis:load-dataset "data/footways.shp"

  draw
  display-gis-in-patches
  setup-agents

end

to draw
  clear-drawing
  setup-world-envelope
  gis:set-drawing-color build_col gis:draw build 10
  gis:set-drawing-color foot_col  gis:draw foot 10
  gis:set-drawing-color inter_col  gis:draw inter 10
    ask patches [set pcolor back_col]
end

to setup-world-envelope
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of build)
                                                (gis:envelope-of foot)
                                                (gis:envelope-of inter))
end


to display-gis-in-patches   ;; patch procedure
  ask patches gis:intersecting build
  [ set pcolor build_col ]
  ask patches gis:intersecting foot
  [set pcolor foot_col]
  ask patches gis:intersecting inter
  [ set pcolor inter_col  ]
end

to setup-patches-destination
  ask turtles  [setup-destination]

end

to setup-destination  ;; patch procedure
  set stop? false
  set destination? patch 27 -58
  ask (patch-set destination?) [set pcolor nest_col]
end



to setup-agents
  set-default-shape turtles "arrow"
  create-turtles num-agen
  put-on-place
  ask turtles [set speed 1]
  ask turtles [set cnt 0]
  setup-patches-destination

end

to put-on-place
  ask turtles [setxy -76 88  ]
end


to go

  ask turtles [ pen-down ]
  ask turtles with [ stop? = false ]

  [
    set old-px pxcor
    set old-py pycor
    set time time + 1

    if (any? patches in-radius 2 with [ pcolor = nest_col ]) [ set stop? true stop ]

    go-to-destination

    if (([pcolor] of patch-ahead 1 = foot_col)  or ([pcolor] of patch-ahead 2 = foot_col))
    [fd 1
     set dist dist + 1
    ]

    if ([pcolor] of patch-ahead 1 != foot_col) and ([pcolor] of patch-ahead 2 != foot_col)
       [rt random 15  ]

    set px pxcor
    set py pycor

    if (old-px = px) and (old-py = py)
    [set cnt cnt + 1]
    if cnt > 3
    [rt 180
    set cnt 0]
 ]

ask patches [
  if (pcolor = foot_col) [
    if count turtles-here > 0 [
      set counter (counter + 1)
  ]  ] ]


;; save time and distance to file
if ticks > 2000 [

    file-open "time.txt"
    ask turtles with [ stop? = true ]
    [ file-write time
    ]
    file-close
    file-open "dist.txt"
    ask turtles with [ stop? = true ]
    [ file-write dist
    ]
    file-close
    stop
 ]

tick
end

to go-to-destination  ;; turtle procedure
  if patch-here != destination? [check_correct_direction]
end

to check_correct_direction  ;; turtle procedure                        TUTAJ ODBIERAM WARTOŚĆ SCENT JEŻELI JEST ŻÓŁTY

  let attraction 42000
  let amp amp-val
  let pahead patch-ahead 1
  let pahead2 patch-ahead 2

  let attraction2-back_col 0.0002 * attraction
  let attraction2-build_col 0.0001 * attraction


  let attraction-ahead  attraction - [ distance pahead ] of destination? * amp
  ifelse ([pcolor] of pahead = foot_col)
  [
     if ([pcolor] of pahead2 = back_col)
     [set attraction-ahead attraction-ahead - attraction2-back_col ]
     if ([pcolor] of pahead2 = build_col)
     [set attraction-ahead attraction-ahead - attraction2-build_col ]
    ]
  [set attraction-ahead attraction-ahead - attraction]

  let prahead patch-right-and-ahead 45 1
  let prahead2 patch-right-and-ahead 45 2


  let attraction-right-ahead  attraction - [ distance prahead ] of destination? * amp
   ifelse ([pcolor] of prahead = foot_col)
  [
  if ([pcolor] of prahead2 = back_col)
     [set attraction-right-ahead attraction-right-ahead - attraction2-back_col ]
  if ([pcolor] of prahead2 = build_col)
     [set attraction-right-ahead attraction-right-ahead - attraction2-build_col ]
  ]
  [set attraction-right-ahead attraction-right-ahead - attraction]

  let plahead patch-left-and-ahead 45 1
  let plahead2 patch-left-and-ahead 45 2


  let attraction-left-ahead   attraction - [ distance plahead ] of destination? * amp
  ifelse ([pcolor] of plahead = foot_col)
  [
      if ([pcolor] of plahead2 = back_col)
     [set attraction-left-ahead attraction-left-ahead - attraction2-back_col ]
   if ([pcolor] of plahead2 = build_col)
     [set attraction-left-ahead attraction-left-ahead - attraction2-build_col ]
  ]
  [set attraction-left-ahead attraction-left-ahead  - attraction]

  let pl patch-left-and-ahead 90 1
  let pl2 patch-left-and-ahead 90 2
  let attraction-left   attraction - [ distance pl ] of destination? * amp
   ifelse ([pcolor] of pl = foot_col)
   [
      if ([pcolor] of pl2 = back_col)
     [set attraction-left attraction-left - attraction2-back_col ]
  if ([pcolor] of pl2 = build_col)
     [set attraction-left attraction-left - attraction2-build_col ]
  ]
   [set attraction-left attraction-left - attraction]


  let pr patch-right-and-ahead 90 1
  let pr2 patch-right-and-ahead 90 2

  let attraction-right  attraction - [ distance pr ] of destination? * amp
   ifelse ([pcolor] of pr = foot_col)
   [
     if ([pcolor] of pr2 = back_col)
     [set attraction-right attraction-right - attraction2-back_col ]
   if ([pcolor] of pr2 = build_col)
     [set attraction-right attraction-right - attraction2-build_col ]

  ]
   [set attraction-right attraction-right - attraction]

  if (attraction-right-ahead > attraction-ahead) and (attraction-right-ahead > attraction-left-ahead) and (attraction-right-ahead > attraction-left) and (attraction-right-ahead > attraction-right)
  [rt 45]
   if (attraction-left-ahead > attraction-ahead) and (attraction-left-ahead > attraction-right-ahead) and (attraction-left-ahead > attraction-left) and (attraction-left-ahead > attraction-right)
  [lt 45]
   if (attraction-left > attraction-ahead) and (attraction-left > attraction-left-ahead) and (attraction-left > attraction-right-ahead)  and (attraction-left > attraction-right)
  [lt 90]
   if (attraction-right > attraction-ahead) and (attraction-right > attraction-left-ahead) and (attraction-right > attraction-left) and (attraction-right > attraction-right-ahead)
  [rt 90]

end


to-report time-var

  if ticks > 2000 [
    report [time] of turtles with [ stop? = true ]
  ]

end

to-report dist-var
  if ticks > 2000 [
    report [dist] of turtles with [ stop? = true ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
405
10
1418
1024
-1
-1
5.0
1
10
1
1
1
0
0
0
1
-100
100
-100
100
1
1
1
ticks
30.0

BUTTON
40
286
152
319
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
181
290
353
323
num-agen
num-agen
0
100
15.0
1
1
NIL
HORIZONTAL

BUTTON
48
331
138
366
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
180
338
354
371
amp-val
amp-val
0
20
16.0
1
1
NIL
HORIZONTAL

PLOT
32
428
374
705
Patches
Time
Patches visited
0.0
2001.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count patches with [counter > 0]"

@#$#@#$#@
## WHAT IS IT?

This model uses GIS extension in order to simulate traffic in the city of Torino (Italy) and it shows how traffic conditions influence pollution in the city; in addition it is possible to approximate the amount of money lost due to traffic delays.

## HOW IT WORKS

Patches not intersecting the GIS represent streets and, of course, turtles (cars) can only move on these patches. Turtles are expected to "drive" on the right, speed is represented by the number of patches they go forward and it decreases if there are any other turtles ahead.
Each patch has an indicator of its pollution levels depending on the number of cars on it and pollution diffuses to other patches as time passes.
Each turtle shows speed, waiting time and motion time.

## HOW TO USE IT

First of all setup allows to import the GIS, then it is possible to move on the map and choose different areas of the city of Torino; there is a zoom utility but it is recommended to set zoom between 0.05 and 0.08 before going on.
Display-streets-in-patches (a bit slow) makes the distinction between streets and buildings, while draw-streets draws roadways. Notice that it is possible to open or close parts of a street using close-street-here and open-street-here.
Setup-cars creates the selected number of turtles and Go makes them move.
Two buttons allow to follow one of the turtles and to change color to its path.
Two switches allow to consider pollution and to show its concentration on the map; notice that original colors can be brought back using cancel-colors.
Change-street-color makes streets fade at car passage.

## THINGS TO NOTICE

It is advisable to follow this order in pressing buttons:
setup / display-streets-in-patches / draw-streets / setup-cars / go.

## THINGS TO TRY

Sliders:

cost-of-working represents the average cost of an hour of work (in euros or dollars)

poll-dispersion, if positioned at 1.00 no pollution is dissipated, if positioned at 2.00 50% of pollution disappears

The pollution growth caused by cars is represented by a normal probability distribution with parameters pollution-mean and deviation-mean

## CREDITS AND REFERENCES

SantaFeStreets model -- http://backspaces.net/wiki/NetLogo_Bag_of_Tricks#NetLogo_GIS
Traffic Grid model -- Netlogo Library
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
1.0
-0.2 1 1.0 0.0
0.0 1 1.0 0.0
0.2 1 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
