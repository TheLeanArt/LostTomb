; The Lost Tomb
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "common.inc"
include "defs.inc"
include "judge.inc"


SECTION FRAGMENT "Judge", ROM0
JudgeMain:
	call hFixedOAMDMA

	ld a, %11_11_00_00         ; Mask chain links
	ldh [rBGP], a              ; Set the background palette
	ldh [rOBP0], a             ; Set the object palette (required for GBC)
	ld a, Y_WINDOW_INIT
	ldh [rWY], a
	ld a, X_WINDOW_INIT
	ldh [rWX], a

	ld a, LCDC_ON | LCDC_BG_ON | LCDC_OBJ_ON | LCDC_OBJ_16 | LCDC_WIN_ON | LCDC_WIN_9C00
	ldh [rLCDC], a

	ld a, IE_VBLANK
	ldh [rIE], a
	xor a
	ldh [rIF], a
	ei

IF JUDGE_MUSIC

	; Optimized by ISSOtm
	ld hl, rNR52               ; Load the audio master register's address into HL
	ld [hl], a                 ; Turn the APU off
	dec a                      ; A is zero from previous operations
	ld [hld], a                ; Turn the APU on
	ld [hld], a                ; Enable all channels
	ld [hl], $77               ; Set max volume but not VIN

	ld hl, song_hideout
	call hUGE_init

	ld a, MUSIC_DELAY
	ldh [hDelay], a

ENDC

	ld e, 0
.loop
	push de
	rst WaitVBlank

	ld a, e
	and $07
	jp nz, .loopCont

	ld a, e
	and $38
	add a
	swap a
	ld d, a

.health
	cpl
	ld hl, V_HEALTH
	bit 6, e
	jr z, .healthDown

	and 1
	add T_HEALTH_HALF
	ld [hl], a
	jr .healthDone

.healthDown
	; Optimized by calc84maniac
	add MAX_HEALTH + 1
	ld hl, V_HEALTH
.healthLoop
	sub 2
	ld b, T_HEALTH_FULL
	jr nc, .healthCont
	add b                      ; T_HEALTH_EMPTY or T_HEALTH_HALF
	ld b, a
	xor a
.healthCont
	ld [hl], b
	inc l
	bit 2, l
	jr z, .healthLoop
.healthDone

.wave
	ld a, d
	bit 7, e
	jr z, .waveCont
	cpl
.waveCont
	and $07
	add T_WAVE
	ld bc, V_WAVE
.waveLoop
	ld [bc], a
	inc c
	bit TZCOUNT(TILEMAP_WIDTH), c
	jr z, .waveLoop

.bubble:
	ld h, HIGH(Bubbles)        ; Load upper source address byte
	ld a, e                    ; Load the step counter
	rlca                       ; Divide by 64
	rlca                       ; ...
	and $03                    ; Isolate bits 0 and 1
	ld l, a                    ; Load lower source address byte
	ld c, [hl]                 ; Load lower destination address byte
	inc l                      ; Advance to the current bubble
	xor a                      ; Set A to 0
	ld [bc], a                 ; Clear the previous bubble
	ld c, [hl]                 ; Load lower destination address byte
	ld a, d                    ; Load the current step
	add T_BUBBLE               ; Add base tile ID
	ld [bc], a                 ; Set the current bubble

.cat
	add T_CAT - T_BUBBLE
	ld c, LOW(V_CAT)
	ld [bc], a

	ld l, d
	swap l
	ld h, HIGH(JudgeLUT) >> 1
	add hl, hl

.fin
	call UpdateFinAndPaw

.eyes
	ld a, [hli]
	ld bc, A_EYE_LEFT_TILEID
	bit 6, e
	jr z, .mouth
	ld [bc], a
	ld c, LOW(A_EYE_RIGHT_TILEID)
	ld [bc], a

.nose
	ld a, [hl]
	ld c, LOW(A_NOSE_TILEID)
	ld [bc], a

.mouth
	inc l
	ld a, e
	and $C0
	ld a, [hli]
IF JUDGE_CART == 1
	ld d, Y_CART - 1
	jr nz, .mouthDone
ELSE
	jr nz, .cartDone
ENDC
	ld c, LOW(A_MOUTH_TILEID)
	ld [bc], a
IF JUDGE_CART == 1
	inc d
ENDC
.mouthDone

IF JUDGE_CART == 1
	ld a, d
ELIF JUDGE_CART == 2
	rrca                          ; Divide A by 2
	add Y_CART - T_MOUTH / 2 - 1  ; Adjust cart's Y coordinate
ENDC
IF JUDGE_CART
	ld c, LOW(A_CART_Y)
	ld [bc], a                    ; Set Y
ENDC
.cartDone

.ears
	ld a, e                       ; Load the value in E into A
	rlca                          ; Divide A by 2
	and 1                         ; Isolate bit 0

	add X_EAR_RIGHT               ; Adjust right ear's X coordinate
	ld c, LOW(A_EAR_RIGHT_X)
	ld [bc], a                    ; Set X

	cpl                           ; Negate
	add LOW(X_EAR_RIGHT + X_EAR_LEFT + 1)
	ld c, LOW(A_EAR_LEFT_X)
	ld [bc], a                    ; Set X

.scales
	ld c, l
	ld b, h
	ld hl, A_SOUL_Y

.soul
	call UpdateSoul

.feather
	call UpdateFeather

.left
	ld a, [bc]                 ; Load Y
	inc c                      ; Advance the source address
	push bc                    ; Save the source address
	call SetLeftChainAndPlate  ; Update the left chain and plate
	pop bc                     ; Restore the source address

.right
	ld a, [bc]                 ; Load Y
	call SetRightChainAndPlate ; Update the right chain and plate

	call hFixedOAMDMA

	ldh a, [rWY]
	cp Y_WINDOW_FINAL
	jr z, .loopCont
	dec a
	ldh [rWY], a

.loopCont

IF JUDGE_MUSIC

	ldh a, [hDelay]
	or a
	jr z, .doSound
	dec a
	ldh [hDelay], a
	jr .loopDone

.doSound
	call hUGE_dosound

ENDC

.loopDone
	pop de
	inc e
	jp .loop


SECTION "UpdateFinAndPaw", ROM0
UpdateFinAndPaw:
.fin
	ld c, LOW(V_FIN)
	call CopyFour

.paw
	ld bc, V_PAW0
	call CopyFour
	ld c, LOW(V_PAW1)
	call CopyFour
	ld c, LOW(V_PAW2)
	; Fall through

CopyFour:
	ld d, 4
.loop
	ld a, [hli]
	ld [bc], a
	dec d
	ret z
	inc c
	jr .loop


SECTION "UpdateFeather", ROM0
UpdateFeather:
	call .half                 ; Update Y
	; Fall through

.half
	ld a, [bc]                 ; Load Y/tile ID
	inc c                      ; Advance the source address
	ld [hli], a                ; Set Y/tile ID and advance to X/attributes
	inc l                      ; Advance to tile ID/next object
	ret


SECTION "UpdateSoul", ROM0
UpdateSoul:
	ld a, [bc]                 ; Load Y
	inc c                      ; Advance the source address

.left
	ld [hli], a                ; Set Y and advance to X
	ld d, a                    ; Store Y in D
	ld a, e                    ; Load the step counter
	swap a                     ; Divide A by 16
	and OAM_XFLIP >> 2         ; Isolate bit 3
	ld e, a                    ; Store the flip indicator in E
	call .rest                 ; Update the rest of the left object

.right
	ld a, d                    ; Load Y
	ld [hli], a                ; Set Y and advance to X
	ld a, e                    ; Load the flip indicator
	xor TILE_WIDTH             ; Flip the flip indicator
	; Fall through

.rest
	add X_SOUL                 ; Add base X
	ld [hli], a                ; Set X and advance to tile ID
	ld a, [bc]                 ; Load tile ID
	inc c                      ; Advance source address
	ld [hli], a                ; Set tile ID and advance to attributes
	ld a, e                    ; Load the flip indicator
	add a                      ; Multiply by 4
	add a                      ; ...
	ld [hli], a                ; Set attributes and advance to the next object
	ret


SECTION "Judge Bubbles", ROMX, ALIGN[8]
Bubbles:
FOR I, BUBBLE_COUNT
	db LOW(V_BUBBLE{d:I})
ENDR
	db LOW(V_BUBBLE0)


IF JUDGE_MUSIC

SECTION "Judgment Delay", HRAM
hDelay:
	ds 1

ENDC
