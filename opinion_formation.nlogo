;;;;;;;;;;;;;;;
;; VARIABLES ;;
;;;;;;;;;;;;;;;

globals [
  mean-inclination
  mean-connection
]

turtles-own [
  recom
  inclination
  dist-of-pol
  fav
  neutral?
  plot-index
  marked?
  grp-id
]

;;;;;;;;;;;
;; SETUP ;;
;;;;;;;;;;;

to setup
  clear-all
  reset-ticks
  set-default-shape turtles "circle"

  ; initialize the party tendencies
  crt no-of-turtles [
    set recom n-values no-of-ideology [(1 / no-of-ideology)]
    set dist-of-pol n-values no-of-ideology [0]
    set fav n-values no-of-ideology [(1 / no-of-ideology)]
  ]

  ; create a fully-connected network
  ask turtles [
    set color white
    create-links-with n-of floor(network-density * (no-of-turtles - 1)) other turtles
  ]

  ; set the layout of the network
  repeat 100 [ layout-spring turtles links 0.9 60 4 ]

end

to setup-more-realistic-network
  ask turtles [die]
  reset-ticks
  set-default-shape turtles "circle"

  foreach range(no-of-grp) [ x ->
    ; initialize the party tendencies
    crt floor(no-of-turtles / no-of-grp) [
      set recom n-values no-of-ideology [(1 / no-of-ideology)]
      set dist-of-pol n-values no-of-ideology [0]
      set fav n-values no-of-ideology [(1 / no-of-ideology)]
      set grp-id x
      setxy (max-pxcor / (x + 1)) * (-1) ^ x (max-pycor / (x + 1)) * (-1) ^ x
    ]

    ; create a fully-connected network
    ask turtles with [grp-id = x][
      set color white
      create-links-with n-of (floor(no-of-turtles / no-of-grp) - 1) other turtles with [grp-id = x]
    ]
  ]

  ask turtles [
    create-links-with n-of floor(network-density * (floor(no-of-turtles / no-of-grp) - 1)) other turtles
  ]

  ; set the layout of the network
  repeat 100 [ layout-spring turtles links 0.9 20 4 ]
end

to soft-setup
  ask turtles [die]
  reset-ticks
  set-default-shape turtles "circle"

  ; initialize the party tendencies
  crt no-of-turtles [
    set recom n-values no-of-ideology [(1 / no-of-ideology)]
    set dist-of-pol n-values no-of-ideology [0]
    set fav n-values no-of-ideology [(1 / no-of-ideology)]
  ]

  ; create a fully-connected network
  ask turtles [
    set color white
    create-links-with other turtles
  ]

  ; set the layout of the network
  repeat 100 [ layout-spring turtles links 0.9 60 4 ]

end

;;;;;;;;;;;;;;;;;;
;; USEFUL TOOLS ;;
;;;;;;;;;;;;;;;;;;


; weighted random selection, credits to ChatGPT
to-report weighted-selection [probabilities]

  let rnd random-float 1
  let cumulative-prob 0
  let selected-index 0

  foreach probabilities [
    prob ->
    if rnd <= cumulative-prob + prob [
      report selected-index
    ]
    set cumulative-prob cumulative-prob + prob
    set selected-index selected-index + 1
  ]
  report (length probabilities) - 1 ; return last index if no index is selected before
end


to-report pol
  ifelse inclination >= 2 [report position (max fav) fav] [report 11]
end


to-report add-kth-term-by-n [lis k n]
  let temp []
  let index 0
  foreach lis [ x ->
    ifelse index = k [set temp lput (x + n) temp] [
      ; else
      set temp lput x temp]
    set index (index + 1)
  ]
  report temp
end


to-report add-all-term-by-n [lis n]
  let temp []
  foreach lis [ x ->
    set temp lput (x + n) temp
  ]
  report temp
end


to-report no-of-neighbors [i j]
  report count(link-neighbors with [max-index = i and inclination = j])
end

to-report no-of-neutral
  report count(link-neighbors with [pol = 11])
end


to-report max-index
  report position (max fav) fav
end


;;;;;;;;;;;;:
;; UPDATES ;;
;;;;;;;;;;;;:

to update-fav

  let selected-index weighted-selection recom

  if mode != "minimize-preference" [
    set fav (add-kth-term-by-n fav selected-index learning-rate)
    set fav map([ [x] -> x / sum(fav) ]) fav]

  if mode = "maximize-preference" [set recom fav]
  if mode = "minimize-preference" [
    foreach range(no-of-ideology) [x -> if selected-index != x [set fav (add-kth-term-by-n fav selected-index learning-rate)]]
    set fav map([ [x] -> x / sum(fav) ]) fav
  ]

  if mode = "average-recommendation" [] ;do nothing
  if mode = "conformity" [

    let temp recom
    foreach range(no-of-ideology) [ x ->
      if count(link-neighbors) != 0 [
        let update-num sum(map [ [y] -> (no-of-neighbors x y) * learning-rate ] range(6) )
        set temp replace-item x temp (update-num + item x temp)]

    ]
    if sum(temp) != 0 [set temp map([ [z] -> z / sum(temp) ]) temp]
    set recom temp

    ]

  if mode = "network-distribution" [

    let temp recom
    foreach range(no-of-ideology) [ x ->
      if count(link-neighbors) != 0 [
        let update-num sum(map [ [y] -> (no-of-neighbors x y) * learning-rate ] [2 3 4 5] )
        set temp replace-item x temp (update-num + item x temp + (no-of-neutral * 1 / no-of-ideology))]

    ]
    if sum(temp) != 0 [set temp map([ [z] -> z / sum(temp) ]) temp]
    set recom temp

    ]

end

to update-inclination

  let segment ((no-of-ideology - 1) / no-of-ideology)
  let prob (max fav) - (1 / no-of-ideology)
  set inclination (floor ((prob / segment) * 5))

end

to update-turtle
  ; set color according to party inclination
  let color-list [10 70 40 60 20 80 90 110 120 130 False False]
  let party-color item max-index color-list
  ifelse debug = True [set color (party-color + 4)] [
    ; else
    set color (party-color + 8 - inclination)
  ]
end

to disconnect

  if random-float 1 < disconnect-prob [
    let to-disconnect one-of links with [
      [pol] of end1 != 11 and [pol] of end2 != 11 and
      [pol] of end1 != [pol] of end2 and
      [inclination] of end1 > 2]
    if to-disconnect != nobody [ask to-disconnect [ die ]]
  ]
end

;;;;;;;;;;;;
;; LAYOUT ;;
;;;;;;;;;;;;

; adjust the layout over time
; credits to Wilensky, U. (2005). NetLogo Preferential Attachment model.
to layout
  ;; the more turtles we have to fit into the same amount of space,
  ;; the smaller the inputs to layout-spring we'll need to use
  let factor sqrt count turtles
  ;; numbers here are arbitrarily chosen for pleasing appearance
  let network-size 500 * (exp (-0.001 * ticks)) + 200
  ;layout-spring turtles links (9 / factor) (network-size / factor) (9 / factor)
  layout-spring turtles links (1 / factor) ((network-size / factor) - 20) (1 / factor)
  display  ;; for smooth animation
end


;;;;;;;;;
;; GO! ;;
;;;;;;;;;

to go
  let no-of-connection 0
  ask turtles [

    update-fav
    update-inclination
    update-turtle
    set no-of-connection (no-of-connection + count(link-neighbors))
  ]

  if disconnect? = True [disconnect]
  set mean-inclination mean([inclination] of turtles)
  set-plot-index
  set mean-connection (no-of-connection / no-of-turtles ^ 2)
  tick
end

to plotting
  let no-of-connection 0
  ask turtles [
    update-fav
    update-inclination
    update-turtle
    set no-of-connection (no-of-connection + count(link-neighbors))
  ]

  if disconnect? = True [disconnect layout]
  set mean-inclination mean([inclination] of turtles)
  set-plot-index
  set mean-connection (no-of-connection / no-of-turtles ^ 2)
  tick

  if ticks >= 2000 [stop]
end

to set-plot-index
  ask turtles [set marked? false]
  let total-turtle no-of-turtles

  foreach range(count turtles with [pol = 11]) [ y ->
    let unmarked one-of turtles with [pol = 11 and not marked?]
    ask unmarked
      [set plot-index total-turtle
      set total-turtle (total-turtle - 1)
    set marked? True]
  ]

  foreach range(no-of-ideology) [ x ->

    foreach range(count turtles with [pol = x]) [ y ->
      let unmarked one-of turtles with [pol = x and not marked?]
      ask unmarked
        [set plot-index total-turtle
        set total-turtle (total-turtle - 1)
      set marked? True]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
246
12
781
548
-1
-1
5.433
1
10
1
1
1
0
0
0
1
-48
48
-48
48
0
0
1
ticks
30.0

BUTTON
43
15
216
48
NIL
setup\n\n
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
43
52
215
85
no-of-ideology
no-of-ideology
2
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
42
137
214
170
no-of-turtles
no-of-turtles
2
100
60.0
1
1
NIL
HORIZONTAL

SLIDER
42
174
214
207
learning-rate
learning-rate
0
0.5
0.5
0.01
1
NIL
HORIZONTAL

BUTTON
35
215
98
248
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

SWITCH
105
212
220
245
disconnect?
disconnect?
0
1
-1000

BUTTON
35
254
99
287
layout
layout
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
105
252
221
285
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
415
567
592
600
debug
debug
1
1
-1000

BUTTON
414
604
500
637
print fav
ask turtles [print fav]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
504
604
591
637
print recom
ask turtles [print recom]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
414
642
501
675
update
ask turtles [update-turtle]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
24
335
233
380
mode
mode
"maximize-preference" "minimize-preference" "conformity" "network-distribution" "average-recommendation"
3

BUTTON
505
642
592
675
print inclination
ask turtles [print inclination]
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
37
290
222
323
disconnect-prob
disconnect-prob
0.01
1
1.0
0.01
1
NIL
HORIZONTAL

BUTTON
517
682
614
715
NIL
soft-setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
467
722
547
755
NIL
plotting
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
44
97
218
130
network-density
network-density
0
1
0.15
0.01
1
NIL
HORIZONTAL

BUTTON
389
680
508
715
make extreme
ask n-of floor(no-of-turtles * 0.2) turtles with [max-index = 0] [set fav [1 0 0]]\nask n-of floor(no-of-turtles * 0.2) turtles with [max-index = 1] [set fav [0 1 0]]\nask n-of floor(no-of-turtles * 0.2) turtles with [max-index = 2] [set fav [0 0 1]]
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
24
515
236
549
no-of-grp
no-of-grp
0
10
10.0
1
1
NIL
HORIZONTAL

BUTTON
22
477
241
511
NIL
setup-more-realistic-network
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
29
555
236
589
NIL
layout-for-realistic-network
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
100
420
164
454
NIL
tick
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
805
279
1550
618
Size of Echo Chamber / Average Connection over Number of Cluster
Number of Cluster
NIL
0.0
11.0
0.0
0.5
true
true
"" ""
PENS
"Size of Echo Chamber" 1.0 2 -5298144 true "" "if ticks = 2500 [plotxy no-of-grp ((no-of-turtles - count(turtles with [not any? link-neighbors]))/ no-of-turtles)]"
"Connection" 1.0 2 -14070903 true "" "if ticks = 2500 [plotxy no-of-grp mean-connection]"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="100" runMetricsEveryStep="false">
    <setup>soft-setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <exitCondition>ticks = 300</exitCondition>
    <metric>count (turtles with [pol = 0]) / (no-of-turtles)</metric>
    <runMetricsCondition>ticks = 299</runMetricsCondition>
  </experiment>
  <experiment name="experiment2" repetitions="20" runMetricsEveryStep="false">
    <setup>setup-more-realistic-network</setup>
    <go>go</go>
    <exitCondition>ticks = 2500</exitCondition>
    <steppedValueSet variable="no-of-grp" first="1" step="1" last="10"/>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
