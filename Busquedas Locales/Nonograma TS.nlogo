; Variables globales
globals [
  dist-filas     ; Distribución de activos en las filas, por ejemplo [3] o [2 5 2]
  dist-columnas  ; Distribución de activos en las columnas
  Error-Global   ; Energía del sistema global
]

patches-own [estado estado-previo]

to setup
    ca
    ask patches [
        set estado ifelse-value (random 100 < %-inicial) [true][false]
        set estado-previo true ]
    setupFigura1
    comprobarFigura
    muestraEstados
    calcularError-Global
    actualizaPlotError
end

to go
  let old-score 0
  let new-score 0
  let accept 0
  
    ;ask random-one-of patches [                            ;this line if using modifyPatch0
    ask one-of patches with [ estado ] [               ;this line if using modifyPatch1
        set old-score calculateStrip pxcor pycor
        recuerdaEstados
        modificaPatch1
        set new-score calculateStrip pxcor pycor
        set accept aceptarModificacion new-score old-score
        if not accept [ revertirEstados ]
    ]
    muestraEstados
    calcularError-Global
    actualizaPlotError
    if Error-Global = 0 [stop]
end

to setupFigura1
  ;dist-filas de arriba a abajo
  set dist-filas [ [2] [1] [4] [5] [3 2] [2 1] [3] ]
  
  ;dist-columnas de izquierda a derecha
  set dist-columnas [ [1] [3] [1 3] [5 1] [4] [3] [2] ]
end

to setupFigura2
    set dist-filas [
        [10 3 3]  [9 3 2]   [8 9 1]   [7 7 1]  [6 2 2]
        [5 3 3]   [4 2 2]   [3 1 1 3] [2 5]    [1 8 5]
        [8 3]     [8 3]     [3]       [3]      [3 3]
        [2 4]     [1 5]     [2]       [3 3]    [3 8]
        [3 8 1]   [2 8 2]   [1 1 3]   [2 4]    [3 5]
        [3 6]     [3 7]     [11 8]    [11 9]   ;[11 10]
     ]
    set dist-columnas [
        [2 10]    [2 9]     [2 8]     [2 7]     [5 5 5]
        [6 4 5]   [7 3 4]   [2 3]     [2 4 8 2] [2 5 7 1]
        [2 6 6]   [3 2 3]   [3 3 3]   [3 3 3]   [3 3 3 3]
        [3 3 6]   [1 8]     [2 2 2 2] [3 5 2]   [4 4 2]
        [5 5 2]   [6 5 2]   [7 4 3]   [8 3 2]   [9 1 1]
    ]
end

to comprobarFigura
    if (length dist-filas != world-height) [
        show sentence "screen-size-y  should be " length dist-filas
        stop
    ] 
    if (length dist-columnas != world-width) [
        show sentence "screen size-x  should be " length dist-columnas
        stop
    ] 
end

to recuerdaEstados
    ask neighbors [ set estado-previo estado ]
    set estado-previo estado
end

to-report calculateStrip [ x y ]
    report
        ( evaluaFila dec y max-pycor ) + ( evaluaFila y ) + ( evaluaFila inc y max-pycor ) + 
        ( evaluaColumna dec x max-pxcor ) + ( evaluaColumna pxcor ) + ( evaluaColumna inc x max-pxcor )
end

to revertirEstados
    ask neighbors [ set estado estado-previo ]
    set estado estado-previo
end

to-report aceptarModificacion [ nuevo antiguo ]
    ifelse nuevo < antiguo
        [ report true ]
        [
            let prob exp ( ( antiguo - nuevo ) / temperatura )
            ifelse random-float 1.0 < prob 
                [ report true ]
                [ report false ]
        ]
end

to calcularError-Global
  let error-fila    sum map [evaluaFila    ?] n-values world-width [? + min-pycor]
  let error-columna sum map [evaluaColumna ?] n-values world-width [? + min-pycor]  
;  repeat world-height [
;    set error-fila ( error-fila + evaluaFila y )
;    set y ( y + 1 )  ]
;  set x min-pxcor
;  let error-columna 0
;  repeat world-width [
;    set error-columna ( error-columna + evaluaColumna x )
;    set x ( x + 1 )  ]
  set Error-Global ( error-fila + error-columna )
end

to-report evaluaFila [fila]
  let elementosFila patches with [pycor = fila]
  let estadosFila [estado] of elementosFila
  let unaFilaDibujo agrupar estadosFila
  let target item ( fila + max-pycor ) dist-filas
  let errorFila calculaError unaFilaDibujo target
  report errorFila
end

to-report evaluaColumna [columna]
  let elementosColumna patches with [pxcor = columna]
  let estadosColumna [estado] of elementosColumna
  let unaColumnaDibujo agrupar estadosColumna
  set unaColumnaDibujo reverse unaColumnaDibujo
  let target item ( columna + max-pxcor ) dist-columnas
  let errorColumna calculaError unaColumnaDibujo target    
  report errorColumna
end

to-report calculaError [ vector1 vector2 ]
  ; penaliza una diferencia en la longitud
  let dif abs (length vector1 - length vector2)
  ; get the two vectors to be the same length by padding the shorter with zeroes
  while [ (length vector1) < (length vector2) ]
    [ set vector1 lput 0 vector1 ]
  while [ (length vector2) < (length vector1) ]
    [ set vector2 lput 0 vector2 ]
  ; calculate the distance between the two vectors
  let er 0
  let i 0
  repeat length vector1 [
    ;        set error ( error + abs( ( item i vector1 ) - ( item i vector2 ) ) )
    set er er + ( ( item i vector1 ) - ( item i vector2 ) ) * ( ( item i vector1 ) - ( item i vector2 ) )
    set i ( i + 1 )
  ]
  set er er + ( dif * wt-diff)
  report er
end

to-report agrupar[ estados ]
  let a-clue 0
  ifelse item 0 estados
    [set a-clue [0 1] ]
    [set a-clue [0] ]
  let i 1
  let i-max length estados
  repeat ( i-max - 1 ) [
    if (item i estados) and (item ( i - 1 ) estados)
      [ set a-clue replace-item ( -1 + length a-clue ) a-clue (1 + last a-clue) ]
    if (item i estados) and  not (item ( i - 1 ) estados)
      [ set a-clue lput 1 a-clue ]
    set i ( i + 1 )
  ]    
  if a-clue != [0]
    [ set a-clue remove 0 a-clue ]
  report a-clue
end

;==================
; UTILITY FUNCTIONS
;==================
to-report inc [ x limite ]
    ifelse x < limite
        [ report x + 1 ]
        [ report -1 * limite ]
end

to-report dec [ x limite ]
    ifelse x > (-1 * limite)
        [ report x - 1 ]
        [ report limite ] 
end

;========================
; PERTURBATION STRATEGIES
;========================
to modificaPatch0
    set estado not estado
end

to modificaPatch1
  let wt-total (wt-kill + wt-breed + wt-move)
  let ran random-float wt-total
  ifelse ran < wt-kill 
  [ killPatch ]
  [
    ifelse (ran < (wt-kill + wt-breed) ) 
    [ breedPatch ]
    [ movePatch ]
  ]
end

to killPatch
    set estado false
end

to breedPatch
    let vacant neighbors with [not estado]
    if count vacant > 0 [ ask one-of vacant [set estado true]]
end

to movePatch
    let vacant neighbors with [not estado]
    if count vacant > 0 [
        ask one-of vacant [set estado true]
        set estado false
    ]
end

;==================
; PLOTTING ROUTINES
;==================
to muestraEstados
    ask patches [
        ifelse estado
            [set pcolor black]
            [set pcolor white]
    ]
end

to actualizaPlotError
    set-current-plot "global error"
    plot Error-Global
end
@#$#@#$#@
GRAPHICS-WINDOW
321
10
566
180
3
3
20.0
1
10
1
1
1
0
1
1
1
-3
3
-3
3
0
0
1
ticks
30.0

BUTTON
13
50
80
83
setup
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
14
146
186
179
%-inicial
%-inicial
0
100
10
1
1
%
HORIZONTAL

BUTTON
13
97
81
130
go
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
14
193
187
226
temperatura
temperatura
0.1
5
-1.6858838272886673E-12
0.1
1
NIL
HORIZONTAL

PLOT
304
268
710
570
global error
NIL
NIL
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -65536 true "" ""

MONITOR
304
215
390
260
Error Global
Error-Global
3
1
11

SLIDER
15
263
187
296
wt-kill
wt-kill
0
10
5
1
1
NIL
HORIZONTAL

SLIDER
15
296
187
329
wt-breed
wt-breed
0
10
5
1
1
NIL
HORIZONTAL

SLIDER
15
327
187
360
wt-move
wt-move
0
10
5
1
1
NIL
HORIZONTAL

SLIDER
16
396
188
429
wt-diff
wt-diff
0
50
1
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This program solves nonograms (sometimes) using simulated annealing. 

A nonogram is a logic problem, invented in Japan and popularised in the UK. It consists of a rectangular grid with one set of clues for each row and column of the grid.  Solving the clues determines which cells in the puzzle are to be shaded to produce a picture.  Clues are of the form �x1,x2, ... ,xn�, which translates as x1 shaded cells followed by at least one blank cell, followed by x2 shaded squares followed by at least one blank cell etc.

For example, the following nonogram (it's a chicken, honest) has clues as shown

    � # # # � � �    3
    # # � # � � �    2,1
    � # # # � # #    3,2
    � � # # # # #    5
    � � # # # # �    4
    � � � � # � �    1
    � � � # # � �    2


    1 3 1 5 4 3 2
        3 1

If you want to solve anything other than the 'chicken' nonogram, you'll need to download the file and tinker with the input routines.

## HOW IT WORKS

Although there is a deterministic (and fast) algorithm - see "Related Models" below - I decided to try a simulated annealing approach:  
1) The 'energy' of the grid is calculated (an objective function comparing the clues that would be created by the current pattern against the desired target clues - when this reaches zero the nonagram is solved), E1.  
2) An agent is selected at random and allowed to move, breed or die.  
3) The energy of the grid is calculated again, E2.  
4) If E2<=E1, then the change in (2) is accepted. If E2>E1, the change in (2) has a probability of acceptance of exp(-(E2-E1)/T), where T is a 'temperature' that is gradually reduced as the annealing proceeds.

## HOW TO USE IT

1) Initialise the nonagram by selecting a value for fraction-on (the fraction of patches that are originally occupied) and pressing 'setup'.

2) Set temperature (somewhere around the top end of the scale is good), and set the relative weights of agent death, breeding and moving (the bigger the weight, the more likely that action will be chosen by an agent). Leave wt-diff at zero for the time being (see 'Things to Try').

3) Press go. You'll see the developing solution in the grid and a graph of the global error as the annealing progresses. When this graph hits zero, the solution is found and the run automatically stops.

## THINGS TO NOTICE

As the global error reduces and you start to see the emergence of some vague pattern, start reducing the temperature. Somewhere round the 0.4 - 0.6 mark, you'll get a solution. If the temperature is much hotter, the probability of moving away from the solution is too high.

Once you have reduced the temperature, you might find that the global error gets stuck at some low but non-zero number (i.e. it's fallen into a local minimum). If this happens just briefly boil the chicken again and return to a low simmer.

## THINGS TO TRY

1) Different objective functions (I). Use a Euclidean distance in the objective function rather than a city-block distance. Any effect?

2) Different objective functions (II). On a large nonogram with large contiguous blocks, it might be a good idea to penalise differences in number of clues (see to-report calculateError). Does this have an effect?

3) Large nonagrams. I have included the clues for a 25 x 29 nonagram called 'Tea Break' (I got it off the Web somewhere). To use it:
	(i) In 'to setup', replace setupChickenClues by setupTeaBreakClues
	(ii) change the world size (by manual edit of the interface)
	to screen-edge-x = screen-edge-y = 3

The solution is below. I've not been able to converge to it. This rather suggests that simulated annealing is *not* the best solution to solving nonagrams (also see 'Related models' below).


    ###########�����#########
    ###########������########
    ����###�����������#######
    ����###������������######
    ����###��������������####
    �����##���������������###
    ����#�#�########�������##
    ����##��########��������#
    ����###�########���������
    ����###�###��������������
    ����###��##��������������
    ��������#�#####����������
    ��������##�####����������
    ��������###�###����������
    ��������###��������������
    ��������###��������������
    ��������########��###����
    ��������########��###����
    #�������########�#####���
    ##���������������#####���
    ###�������������#�#�###��
    ####������������##���##��
    #####����������###���###�
    ######���������##�����##�
    #######��������#######�#�
    ########������#########�#
    #########�����###�����##�
    ##########����###�����###


## NETLOGO FEATURES

I used patches rather than turtles as my agents because of the one-to-one correspondence between patches and cells of the grid - I didn't need to worry about how to evaluate objective functions if multiple turtles decided to squat on the same patch.

## RELATED MODELS

Simulated annealing might be fun but it's criminally slow. It's actually possible to work out an extremely fast algorithm that relies solely on the same sort of logical processes you'd use if you were solving one long-hand. For example, you'd probably start with that 5-row in the middle. The extreme positions for the block are either all the way left and all the way right, that is:

# # # # # � �  and � � # # # # #
   
which means that the three central blocks must be occupied thus:

� � # # # � �

You can then use this as a constraint on the column clues, working out what cells can and cannot be occupied, and continue in this fashion till the nonogram is solved. You can find a Java program that uses this approach at http://www.morleysoft.freeserve.co.uk/computing/java/griddler.html. It might be fast, but it's not as much fun as boiling the chicken and cooling it down.

@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

ant
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -7500403 true true 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -7500403 true true 78 58 99 116 139 123 137 128 95 119
Polygon -7500403 true true 48 103 90 147 129 147 130 151 86 151
Polygon -7500403 true true 65 224 92 171 134 160 135 164 95 175
Polygon -7500403 true true 235 222 210 170 163 162 161 166 208 174
Polygon -7500403 true true 249 107 211 147 168 147 168 150 213 150

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bee
true
0
Polygon -1184463 true false 151 152 137 77 105 67 89 67 66 74 48 85 36 100 24 116 14 134 0 151 15 167 22 182 40 206 58 220 82 226 105 226 134 222
Polygon -16777216 true false 151 150 149 128 149 114 155 98 178 80 197 80 217 81 233 95 242 117 246 141 247 151 245 177 234 195 218 207 206 211 184 211 161 204 151 189 148 171
Polygon -7500403 true true 246 151 241 119 240 96 250 81 261 78 275 87 282 103 277 115 287 121 299 150 286 180 277 189 283 197 281 210 270 222 256 222 243 212 242 192
Polygon -16777216 true false 115 70 129 74 128 223 114 224
Polygon -16777216 true false 89 67 74 71 74 224 89 225 89 67
Polygon -16777216 true false 43 91 31 106 31 195 45 211
Line -1 false 200 144 213 70
Line -1 false 213 70 213 45
Line -1 false 214 45 203 26
Line -1 false 204 26 185 22
Line -1 false 185 22 170 25
Line -1 false 169 26 159 37
Line -1 false 159 37 156 55
Line -1 false 157 55 199 143
Line -1 false 200 141 162 227
Line -1 false 162 227 163 241
Line -1 false 163 241 171 249
Line -1 false 171 249 190 254
Line -1 false 192 253 203 248
Line -1 false 205 249 218 235
Line -1 false 218 235 200 144

bird1
false
0
Polygon -7500403 true true 2 6 2 39 270 298 297 298 299 271 187 160 279 75 276 22 100 67 31 0

bird2
false
0
Polygon -7500403 true true 2 4 33 4 298 270 298 298 272 298 155 184 117 289 61 295 61 105 0 43

boat1
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

boat2
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 157 54 175 79 174 96 185 102 178 112 194 124 196 131 190 139 192 146 211 151 216 154 157 154
Polygon -7500403 true true 150 74 146 91 139 99 143 114 141 123 137 126 131 129 132 139 142 136 126 142 119 147 148 147

boat3
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 37 172 45 188 59 202 79 217 109 220 130 218 147 204 156 158 156 161 142 170 123 170 102 169 88 165 62
Polygon -7500403 true true 149 66 142 78 139 96 141 111 146 139 148 147 110 147 113 131 118 106 126 71

box
true
0
Polygon -7500403 true true 45 255 255 255 255 45 45 45

butterfly1
true
0
Polygon -16777216 true false 151 76 138 91 138 284 150 296 162 286 162 91
Polygon -7500403 true true 164 106 184 79 205 61 236 48 259 53 279 86 287 119 289 158 278 177 256 182 164 181
Polygon -7500403 true true 136 110 119 82 110 71 85 61 59 48 36 56 17 88 6 115 2 147 15 178 134 178
Polygon -7500403 true true 46 181 28 227 50 255 77 273 112 283 135 274 135 180
Polygon -7500403 true true 165 185 254 184 272 224 255 251 236 267 191 283 164 276
Line -7500403 true 167 47 159 82
Line -7500403 true 136 47 145 81
Circle -7500403 true true 165 45 8
Circle -7500403 true true 134 45 6
Circle -7500403 true true 133 44 7
Circle -7500403 true true 133 43 8

circle
false
0
Circle -7500403 true true 35 35 230

person
false
0
Circle -7500403 true true 155 20 63
Rectangle -7500403 true true 158 79 217 164
Polygon -7500403 true true 158 81 110 129 131 143 158 109 165 110
Polygon -7500403 true true 216 83 267 123 248 143 215 107
Polygon -7500403 true true 167 163 145 234 183 234 183 163
Polygon -7500403 true true 195 163 195 233 227 233 206 159

sheep
false
15
Rectangle -1 true true 90 75 270 225
Circle -1 true true 15 75 150
Rectangle -16777216 true false 81 225 134 286
Rectangle -16777216 true false 180 225 238 285
Circle -16777216 true false 1 88 92

spacecraft
true
0
Polygon -7500403 true true 150 0 180 135 255 255 225 240 150 180 75 240 45 255 120 135

thin-arrow
true
0
Polygon -7500403 true true 150 0 0 150 120 150 120 293 180 293 180 150 300 150

truck-down
false
0
Polygon -7500403 true true 225 30 225 270 120 270 105 210 60 180 45 30 105 60 105 30
Polygon -8630108 true false 195 75 195 120 240 120 240 75
Polygon -8630108 true false 195 225 195 180 240 180 240 225

truck-left
false
0
Polygon -7500403 true true 120 135 225 135 225 210 75 210 75 165 105 165
Polygon -8630108 true false 90 210 105 225 120 210
Polygon -8630108 true false 180 210 195 225 210 210

truck-right
false
0
Polygon -7500403 true true 180 135 75 135 75 210 225 210 225 165 195 165
Polygon -8630108 true false 210 210 195 225 180 210
Polygon -8630108 true false 120 210 105 225 90 210

turtle
true
0
Polygon -7500403 true true 138 75 162 75 165 105 225 105 225 142 195 135 195 187 225 195 225 225 195 217 195 202 105 202 105 217 75 225 75 195 105 187 105 135 75 142 75 105 135 105

wolf
false
0
Rectangle -7500403 true true 15 105 105 165
Rectangle -7500403 true true 45 90 105 105
Polygon -7500403 true true 60 90 83 44 104 90
Polygon -16777216 true false 67 90 82 59 97 89
Rectangle -1 true false 48 93 59 105
Rectangle -16777216 true false 51 96 55 101
Rectangle -16777216 true false 0 121 15 135
Rectangle -16777216 true false 15 136 60 151
Polygon -1 true false 15 136 23 149 31 136
Polygon -1 true false 30 151 37 136 43 151
Rectangle -7500403 true true 105 120 263 195
Rectangle -7500403 true true 108 195 259 201
Rectangle -7500403 true true 114 201 252 210
Rectangle -7500403 true true 120 210 243 214
Rectangle -7500403 true true 115 114 255 120
Rectangle -7500403 true true 128 108 248 114
Rectangle -7500403 true true 150 105 225 108
Rectangle -7500403 true true 132 214 155 270
Rectangle -7500403 true true 110 260 132 270
Rectangle -7500403 true true 210 214 232 270
Rectangle -7500403 true true 189 260 210 270
Line -7500403 true 263 127 281 155
Line -7500403 true 281 155 281 192

wolf-left
false
3
Polygon -6459832 true true 117 97 91 74 66 74 60 85 36 85 38 92 44 97 62 97 81 117 84 134 92 147 109 152 136 144 174 144 174 103 143 103 134 97
Polygon -6459832 true true 87 80 79 55 76 79
Polygon -6459832 true true 81 75 70 58 73 82
Polygon -6459832 true true 99 131 76 152 76 163 96 182 104 182 109 173 102 167 99 173 87 159 104 140
Polygon -6459832 true true 107 138 107 186 98 190 99 196 112 196 115 190
Polygon -6459832 true true 116 140 114 189 105 137
Rectangle -6459832 true true 109 150 114 192
Rectangle -6459832 true true 111 143 116 191
Polygon -6459832 true true 168 106 184 98 205 98 218 115 218 137 186 164 196 176 195 194 178 195 178 183 188 183 169 164 173 144
Polygon -6459832 true true 207 140 200 163 206 175 207 192 193 189 192 177 198 176 185 150
Polygon -6459832 true true 214 134 203 168 192 148
Polygon -6459832 true true 204 151 203 176 193 148
Polygon -6459832 true true 207 103 221 98 236 101 243 115 243 128 256 142 239 143 233 133 225 115 214 114

wolf-right
false
3
Polygon -6459832 true true 170 127 200 93 231 93 237 103 262 103 261 113 253 119 231 119 215 143 213 160 208 173 189 187 169 190 154 190 126 180 106 171 72 171 73 126 122 126 144 123 159 123
Polygon -6459832 true true 201 99 214 69 215 99
Polygon -6459832 true true 207 98 223 71 220 101
Polygon -6459832 true true 184 172 189 234 203 238 203 246 187 247 180 239 171 180
Polygon -6459832 true true 197 174 204 220 218 224 219 234 201 232 195 225 179 179
Polygon -6459832 true true 78 167 95 187 95 208 79 220 92 234 98 235 100 249 81 246 76 241 61 212 65 195 52 170 45 150 44 128 55 121 69 121 81 135
Polygon -6459832 true true 48 143 58 141
Polygon -6459832 true true 46 136 68 137
Polygon -6459832 true true 45 129 35 142 37 159 53 192 47 210 62 238 80 237
Line -16777216 false 74 237 59 213
Line -16777216 false 59 213 59 212
Line -16777216 false 58 211 67 192
Polygon -6459832 true true 38 138 66 149
Polygon -6459832 true true 46 128 33 120 21 118 11 123 3 138 5 160 13 178 9 192 0 199 20 196 25 179 24 161 25 148 45 140
Polygon -6459832 true true 67 122 96 126 63 144

@#$#@#$#@
NetLogo 5.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
