;; patches: gray (city), blue (river), green (plain), brown (hill)

;; we will leverage significant logic and concepts from Ethnocentrism by Uri Wilensky (1997): http://ccl.northwestern.edu/netlogo/models/models/Sample%20Models/Social%20Science/Ethnocentrism.nlogo
;; See notebook for citation

;; agents have a probablity to reproduce and a strategy
breed [ people person ]
breed [ institutions institution ]



people-own [ ptr cooperate-with-same? cooperate-with-different? ]
institutions-own [ tick-of-birth level ]

patches-own [
  is-city?
  is-river?
  is-plain?
  is-hill?
  max-cap
  headroom
  has-institution?
  served-by-institution
  ethno2-ticks
]

globals [
  patch-data
  current-regime
  current-regime-message
  ethno1-pop
  ethno2-pop
  total-capacity
  current-population
  institution-power

  ;; from ethocentrism stats
  meet
  meet-agg
  meetown
  meetown-agg
  meetother
  meetother-agg
  coopown
  coopown-agg
  coopother
  coopother-agg
  defother
  defother-agg

  ;; regime policies
  regime-base-immigration
  regime-base-emigration
  regime-cost-coop
  regime-gain-coop
  regime-coop-1-2
  regime-coop-2-1
  regime-same-policy
  regime-different-policy
  regime-institution-policy

  ;; institutions
  formation-time
  formation-threshold
  upgrade-time
  upgrade-threshold
  community-radius

]

to setup
  clear-all
  load-patch-data
  show-patch-data
  initialize-variables
  set current-regime 1
  load-regime
  ask patches [ seed-ethno1-pops ]
  set current-population current-pop
  reset-ticks
end

to initialize-variables
  set total-capacity get-capacity
  set current-population 0

  set formation-time 5
  set formation-threshold 10
  set upgrade-time 200
  set upgrade-threshold 50
  set community-radius 20
  set institution-power 0

  ;; regimes
  set current-regime-message "Long Live The King."
  set regime-base-immigration 0
  set regime-base-emigration 0
  set regime-cost-coop 0
  set regime-gain-coop 0
  set regime-coop-1-2 0
  set regime-coop-2-1 0
  set regime-same-policy 0
  set regime-different-policy 0
  set regime-institution-policy 0

  ;; ethno stats
  set meetown 0
  set meetown-agg 0
  set meet 0
  set meet-agg 0
  set coopown 0
  set coopown-agg 0
  set defother 0
  set defother-agg 0
  set meetother 0
  set meetother-agg 0
  set coopother 0
  set coopother-agg 0
end

to-report get-capacity
  report ( count patches with [ is-city? ] * 48 ) + ( count patches with [ is-plain? ] * 6 ) + ( count patches with [ is-hill? ] * 1 )
end

to load-patch-data
  ; Check to make sure the file exists first
  ifelse ( file-exists? "cluj-data.txt" )
  [
    set patch-data []
    file-open "cluj-data.txt"

    while [ not file-at-end? ]
    [
      ;; file-read gives you variables.  In this case numbers.
      ;; We store them in a nested list (eg [[1 1 9.9999] [1 2 9.9999] ... )
      ;; Each iteration we append the next nested item to the current list
      set patch-data sentence patch-data (list (list file-read file-read file-read))
    ]

    ;; user-message "File loading complete!"
    file-close
  ]
  [ user-message "There is no cluj-data.txt file in current directory!" ]
end

; This procedure will use the loaded in patch data to color the patches.
; The list is a list of tuples where the first item is the pxcor, the
; second is the pycor, and the third is pcolor. Ex. [ [ 0 0 5 ] [ 1 34 26 ] ... ]
to show-patch-data
  clear-patches
  clear-turtles
  ask patches [
    set is-city? false
    set is-river? false
    set is-plain? false
    set is-hill? false
    set ethno2-ticks 0
    set has-institution? false
    set served-by-institution 0
  ]

  ifelse ( is-list? patch-data )
    [ foreach patch-data [ three-tuple -> ask patch first three-tuple item 1 three-tuple [
      set pcolor last three-tuple
      if ( pcolor = 4.0 ) [ set is-city? true set max-cap 48 ]
      if ( pcolor = 95.0 ) [ set is-river? true set max-cap 0 ]
      if ( pcolor = 55.0 ) [ set is-plain? true set max-cap 6 ]
      if ( pcolor = 33.0 ) [ set is-hill? true set max-cap 1 ]
      ] ] ]
    [ user-message "Please load in patch data first." ]
  display

  ;; finally, we are safe to dump patch-data
  set patch-data 0
end


to seed-ethno1-pops
  ;; ask patches
  ;; ethno1 color: black
  ;; based on the patch data, we will create num-agents agents with a certain probability
  ;; density is 48:6:1
  if ( is-river? ) [ stop ]  ;; stop. no agents in the river
  let num-agents 0
  if ( is-city? )
  [
    ;; roll 4d6
    set num-agents ( 8 * (1 + random 6) ) / 2
  ]
  if ( is-plain? )
  [
    ;; roll 1d3
    set num-agents ( 1 + random 6 ) / 2
  ]
  if ( is-hill? )
  [
    ;; flip two coins, two heads = 1 agent
    set num-agents ( random 2 * random 2 )
  ]
  sprout-people num-agents [
    setup-ethno1-agent
  ]
  ;; for the patch we need to update headroom by subtracting the number of agents
  set headroom max-cap - (count people-here)
end

to setup-ethno1-agent ;;; helper, mostly for visuals
  set color black
  set size .4
  ;; determine the strategy for interacting with someone of the same color
  set cooperate-with-same? ((random-float 1.0) < regime-same-policy)
  ;; determine the strategy for interacting with someone of a different color
  set cooperate-with-different? ((random-float 1.0) < regime-different-policy)

  ;; this offset just helps the agent be visible on the patch
  let offset-magnitude 0.3 ;; How far from the center (max 0.5)
  set xcor xcor + (random-float (2 * offset-magnitude)) - offset-magnitude
  set ycor ycor + (random-float (2 * offset-magnitude)) - offset-magnitude
end

to setup-ethno2-agent ;;; helper, mostly for visuals
  set color red
  set size .4
  ;; determine the strategy for interacting with someone of the same color
  set cooperate-with-same? (random-float 1.0 < .5)
  ;; determine the strategy for interacting with someone of a different color
  set cooperate-with-different? (random-float 1.0 < .5)

  ;; this offset just helps the agent be visible on the patch
  let offset-magnitude 0.3 ;; How far from the center (max 0.5)
  set xcor xcor + (random-float (2 * offset-magnitude)) - offset-magnitude
  set ycor ycor + (random-float (2 * offset-magnitude)) - offset-magnitude
end

to go
  check-regime

  immigrate

  ask people [ set ptr base-ptr ]
  ;; have all of the agents interact with other agents if they can
  ask people [ interact ]
  ;; now they reproduce
  ask people [ reproduce ]

  check-institutions ;; call to review institution formation and status

  emigrate
  death           ;; kill some of the agents
  ;;update-stats    ;; update the states for the aggregate and last 100 ticks


  ask patches [ update-headroom ]
  set current-population current-pop
  tick
end

;; random individuals enter the world on empty cells
to immigrate
  let undercap-patches patches with [headroom > 0]
  ;; we can't have more immigrants than there are empty patches
  let want-to-immigrate floor((random-float 1.0) * immigration-pressure)
  let can-immigrate floor( want-to-immigrate * regime-base-immigration )
  let how-many min list (can-immigrate) (count undercap-patches)
  ask n-of how-many undercap-patches [
    sprout-people 1 [
      setup-ethno2-agent
      ask patch-here [ update-headroom ]
    ]
  ]
end

to emigrate
  let want-to-emigrate ceiling((random-float 1.0) * emigration-pressure)
  let need-emigrate ceiling(want-to-emigrate * regime-base-emigration)
  ask up-to-n-of need-emigrate people with [ color = red ] [
    die
    ask patch-here [ update-headroom ]
  ]
end

to interact  ;; person procedure
  ;; Dresslar: this code is signifcantly borrowed from Ethnocentrism, with the goal of maintaining some fidelity to that modelʻs
  ;; approach. The changes are to ask people on-patch and neighbors. We also dampen benefit on very crowded patches.
  ;; Finally, we have a modification on the impact of cooperation based upon what the regime currently is.

  ;; based on patch type people are given a maximum number of interactions per turn (distance between interactions)
  let current-patch patch-here
  let max-interactions 0
  let crowding 0.001
  if [ is-city? ] of current-patch [
    set max-interactions 6
  ]
  if [ is-plain? ] of current-patch [
    set max-interactions 2
  ]
  if [ is-hill? ] of current-patch [
    set max-interactions 1
  ]

  ask up-to-n-of max-interactions people in-radius 1.5 [
    ;; the commands inside the ASK are written from the point of view
    ;; of the agent being interacted with.  To refer back to the agent
    ;; that initiated the interaction, we use the MYSELF primitive.
    set meet meet + 1
    set meet-agg meet-agg + 1
    ;; do one thing if the individual interacting is the same color as me
    if color = [color] of myself [
      ;; record the fact the agent met someone of the own color
      set meetown meetown + 1
      set meetown-agg meetown-agg + 1
      ;; if I cooperate then I reduce my PTR and increase my neighbors
      if [cooperate-with-same?] of myself [
        set coopown coopown + 1
        set coopown-agg coopown-agg + 1
        ask myself [ set ptr ptr - cost-of-giving ]
        set ptr ptr + (gain-of-receiving)
      ]
    ]
    ;; if we are different colors we take a different strategy
    if color != [color] of myself [
      ;; record stats on encounters
      set meetother meetother + 1
      set meetother-agg meetother-agg + 1
      ;; if we cooperate with different colors then reduce our PTR and increase our neighbors
      ifelse [cooperate-with-different?] of myself [
        set coopother coopother + 1
        set coopother-agg coopother-agg + 1
        ask myself [ set ptr (ptr - (cost-of-giving * regime-cost-coop)) ] ;; Dresslar: regime modifier
        set ptr (ptr + ((gain-of-receiving * regime-gain-coop)))             ;; Dresslar: regime modifier
      ]
      [
        set defother defother + 1
        set defother-agg defother-agg + 1
      ]
    ]
  ]
end

;; use PTR to determine if the agent gets to reproduce
to reproduce  ;; person procedure
  ;; if a random variable is less than the PTR the agent can reproduce
  if random-float 1.0 < ptr [
    ;; find an empty location to reproduce into
    let destination one-of neighbors4 with [headroom > 0]
    if destination != nobody [
      ;; if the location exists hatch a copy of the current person in the new location
      hatch-people 1 [
        move-to destination

        set cooperate-with-same? (random-float 1.0 < .5)  ;; deal with cooperators dying out automatically

        ;; this offset just helps the agent be visible on the patch
        let offset-magnitude 0.3 ;; How far from the center (max 0.5)
        set xcor xcor + (random-float (2 * offset-magnitude)) - offset-magnitude
        set ycor ycor + (random-float (2 * offset-magnitude)) - offset-magnitude

        ask patch-here [ update-headroom ]
        ;; mutate   (no mutation in this model, yet.)
      ]
    ]
  ]
end

to death
  ;; check to see if a random variable is less than the death rate for each agent
  ask people [
    let crowding-ratio max(list 0.5 (current-population / total-capacity) )
    ;;let crowding (crowding-ratio - 0.5) ^ 6
    let crowding 0
    if random-float 1.0 < (death-rate + crowding) [
      die
      ask patch-here [ update-headroom ]
    ]
  ]
end

to death-of-an-institution
  ask institutions [
    ;; criteria here
    ask patches with [ served-by-institution = self ] [
      set served-by-institution 0
    ]
    ask patch-here [
      set has-institution? false
      set ethno2-ticks 0

    ]
    die
  ]
  update-institution-power
end


to check-institutions ;; observer procedure
  ask patches with [ not is-river? and not has-institution? and served-by-institution = 0] [
    ;; count ethno2 nearby
    let ethno2-here people in-radius 1.5 with [color = red]
    let num-ethno2 count ethno2-here

    ;; Check if threshold is met
    ifelse num-ethno2 >= (formation-threshold + regime-institution-policy) [
      ;; If met, increment the counter
      set ethno2-ticks ethno2-ticks + 1
      output-print (word "patch " self " has " num-ethno2 " ethno2")
    ] [
      ;; If not met, reset the counter
      set ethno2-ticks 0
    ]

    ;; Check if formation time is reached
    if ethno2-ticks >= formation-time and served-by-institution = 0 [   ;; must ask again in specfic context due to agentset processing
      sprout-institutions 1 [
        set shape "house"
        set size .8
        set color white
        set level 1
        set tick-of-birth ticks
      ]

     let new-institution one-of institutions-here ;; should be just 1
     ;; Now ask the patches to store the 'who' number of the new institution
     ask patches in-radius community-radius [ set served-by-institution [who] of new-institution ]
     ;; Update the patch where the institution was sprouted
     set has-institution? true
     set ethno2-ticks 0 ;; Reset counter for this patch
    ]
  ]

  update-institution-power

end

to check-regime
  if ticks = 100 [
      set current-regime 2
      load-regime
  ]
  if ticks = 200 [
      set current-regime 3
      load-regime
  ]
end

to load-regime
  if current-regime = 1 [
    set current-regime-message "His Majesty sees no reason to allow ethnicity2 to sully His Kingdom"
    set regime-base-immigration .05
    set regime-base-emigration 1
    set regime-cost-coop 1
    set regime-gain-coop 1
    set regime-coop-1-2 1
    set regime-coop-2-1 1
    set regime-same-policy 0.8
    set regime-different-policy .02
    set regime-institution-policy 999
    ask people with [ color = black ] [
      set cooperate-with-different? (random-float 1.0 < regime-different-policy)
    ]
  ]

  if current-regime = 2 [
    set current-regime-message "His Majesty II will allow ethnicity2 to settle in certain areas of His Kingdom. They must follow His Edicts."
    set regime-base-immigration .2
    set regime-base-emigration .1
    set regime-cost-coop 1.25
    set regime-gain-coop 0.75
    set regime-coop-1-2 1
    set regime-coop-2-1 1
    set regime-same-policy 0.8
    set regime-different-policy .20
    set regime-institution-policy 20
    ask people with [ color = black ] [
      set cooperate-with-different? (random-float 1.0 < regime-different-policy)
    ]
  ]

 if current-regime = 3 [
  set current-regime-message "Emperor Joseph II declares tolerance for all religious and ethnic minorities, but they must serve His greater glory."
  set regime-base-immigration 0.3    ;; More open to immigration
  set regime-base-emigration 0.3     ;; Some control but not preventing movement
  set regime-cost-coop 0.8           ;; Lower cost for cooperation (incentivized)
  set regime-gain-coop 1.2           ;; Higher benefit for cooperation
  set regime-coop-1-2 1.1            ;; Slightly favor black-to-red cooperation
  set regime-coop-2-1 1.1            ;; Slightly favor red-to-black cooperation
  set regime-same-policy 0.9         ;; High intra-group cooperation
  set regime-different-policy 0.35   ;; Moderate inter-group cooperation
  set regime-institution-policy 0    ;; Allows institutions but with oversight
  ask people with [ color = black ] [
    set cooperate-with-different? (random-float 1.0 < regime-different-policy)
  ]
 ]


end

to update-institution-power
  ;; sum of institution levels (for each institution, i-p i-p + level)
  ask institutions [
    set institution-power institution-power + level
  ]
end


to update-headroom
  set headroom max-cap - ( count people-here )
end

to-report current-pop
  report count people
end
@#$#@#$#@
GRAPHICS-WINDOW
201
65
898
763
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-26
26
-26
26
0
0
1
days
30.0

BUTTON
15
68
81
101
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

MONITOR
199
13
257
51
regime
current-regime
17
1
9

BUTTON
13
115
76
148
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
10
264
200
297
immigration-pressure
immigration-pressure
0
100
25.0
1
1
NIL
HORIZONTAL

SLIDER
16
182
188
215
base-PTR
base-PTR
0.01
1
0.11
0.01
1
NIL
HORIZONTAL

SLIDER
15
373
187
406
cost-of-giving
cost-of-giving
0.01
1
0.02
0.01
1
NIL
HORIZONTAL

SLIDER
12
413
184
446
gain-of-receiving
gain-of-receiving
0.01
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
5
516
194
549
institutional-pressure
institutional-pressure
0
100
48.0
1
1
NIL
HORIZONTAL

SLIDER
5
305
192
338
emigration-pressure
emigration-pressure
0
100
10.0
1
1
NIL
HORIZONTAL

PLOT
25
565
185
697
density
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -8020277 true "" "plot 100 * current-population / total-capacity"

SLIDER
18
226
191
259
death-rate
death-rate
.01
1
0.14
.01
1
NIL
HORIZONTAL

PLOT
964
216
1164
366
ethnicity counts
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles with [ color = black ]"
"pen-1" 1.0 0 -5298144 true "" "plot count turtles with [ color = red ]"

PLOT
966
441
1243
629
cooperators
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"with-same?" 1.0 0 -13840069 true "" "plot count people with [ cooperate-with-same? = true ]"
"with-different?" 1.0 0 -4699768 true "" "plot count people with [ cooperate-with-different? = true ]"

MONITOR
263
14
899
52
Hear Ye! Hear Ye!
current-regime-message
17
1
9

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
