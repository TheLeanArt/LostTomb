; The Lost Tomb
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
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

	dec a                        ; A is zero from previous operations
	ldh [rNR52], a               ; Enable all channels
IF !MUSIC_STEREO
	ldh [rNR51], a               ; Play all channels on both speakers
ENDC
	ldh [rNR50], a               ; Set the volume to max

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

IF JUDGE_HEALTH < 2

	and 1 << JUDGE_HEALTH
REPT JUDGE_HEALTH
	rrca
ENDR
	add T_HEALTH_HALF
	ld [MAP_HEALTH + ROW_HEALTH * TILEMAP_WIDTH + COL_HEALTH], a

ELIF JUDGE_HEALTH == 2

	; Optimized by calc84maniac
	cpl
	add MAX_HEALTH + 1
	ld hl, MAP_HEALTH + ROW_HEALTH * TILEMAP_WIDTH + COL_HEALTH
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

ELSE

	; Optimized by calc84maniac
	sub MAX_HEALTH + 1
	rra
	ld b, a
	ld hl, MAP_HEALTH + ROW_HEALTH * TILEMAP_WIDTH + COL_HEALTH
	ld a, T_HEALTH_FULL
.healthLoop
	inc b
	jr nz, .healthCont
	adc -2					   ; T_HEALTH_EMPTY or T_HEALTH_HALF
.healthCont
	ld [hli], a
	res 0, a				   ; Change T_HEALTH_HALF to T_HEALTH_EMPTY
	bit 2, l
	jr z, .healthLoop

ENDC

.wave
	ld a, d
	bit 7, e
	jr z, .waveCont
	cpl
.waveCont
	and $07
	add T_WAVE
	ld bc, MAP_WAVE + ROW_WAVE * TILEMAP_WIDTH + COL_WAVE
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

	ld l, d
	swap l
	ld h, HIGH(JudgeLUT) >> 1
	add hl, hl

.fin
	call UpdateFinAndPaw

.cat
	ld a, [hli]
	ld bc, MAP_CAT + ROW_CAT * TILEMAP_WIDTH + COL_CAT
	ld [bc], a
	inc c

IF JUDGE_SCARF
	ld a, e
	and $C0
	ld a, T_SCARF_TIP
	ld d, T_SCARF
	jr nz, .scarfCont
	ld a, T_SCARF_TIP + 3
	ld d, T_SCARF + 2
.scarfCont
	ld [bc], a
REPT 2
	inc c
	inc a
	ld [bc], a
ENDR
	ld a, d
	ld bc, wShadowOAM + O_SCARF_RIGHT * OBJ_SIZE + OAMA_TILEID
	ld [bc], a
	ld c, O_SCARF_LEFT * OBJ_SIZE + OAMA_TILEID
	ld [bc], a
ENDC

.eyes
	ld a, [hli]
IF JUDGE_SCARF
	ld c, O_EYE_LEFT * OBJ_SIZE + OAMA_TILEID
ELSE
	ld bc, wShadowOAM + O_EYE_LEFT * OBJ_SIZE + OAMA_TILEID
ENDC
	bit 6, e
	jr z, .mouth
	ld [bc], a
	ld c, O_EYE_RIGHT * OBJ_SIZE + OAMA_TILEID
	ld [bc], a

.nose
	ld a, [hl]
	ld c, O_NOSE * OBJ_SIZE + OAMA_TILEID
	ld [bc], a

.mouth
	inc l
	ld a, e
	and $C0
	ld a, [hli]
	jr nz, .cartDone
	ld c, O_MOUTH * OBJ_SIZE + OAMA_TILEID
	ld [bc], a

IF JUDGE_CART
	rrca                          ; Divide A by 2
	add Y_CART - T_MOUTH / 2 - 1 ; Adjust cart's Y coordinate
	ld c, O_CART * OBJ_SIZE + OAMA_Y
	ld [bc], a                    ; Set Y
ENDC
.cartDone

.ears
	ld a, e                       ; Load the value in E into A
	rlca                          ; Divide A by 2
	and 1                         ; Isolate bit 0

	add X_EAR_RIGHT               ; Adjust right ear's X coordinate
	ld c, O_EAR_RIGHT * OBJ_SIZE + OAMA_X
	ld [bc], a                    ; Set X

	cpl                           ; Negate
	add LOW(X_EAR_RIGHT + X_EAR_LEFT + 1)
	ld c, O_EAR_LEFT * OBJ_SIZE + OAMA_X
	ld [bc], a                    ; Set X

.scales
	ld c, l
	ld b, h
	ld hl, wShadowOAM + O_SOUL * OBJ_SIZE + OAMA_Y

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
	ld c, LOW(ROW_FIN * TILEMAP_WIDTH + COL_FIN)
	call CopyFour

.paw
	ld bc, MAP_PAW + ROW_PAW * TILEMAP_WIDTH + COL_PAW
	call CopyFour
	ld c, (ROW_PAW + 1) * TILEMAP_WIDTH + COL_PAW
	call CopyFour
	ld c, (ROW_PAW + 2) * TILEMAP_WIDTH + COL_PAW
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
	db LOW(ROW_BUBBLE * TILEMAP_WIDTH + COL_BUBBLE{d:I})
ENDR
	db LOW(ROW_BUBBLE * TILEMAP_WIDTH + COL_BUBBLE0)


IF JUDGE_MUSIC

SECTION "Judgment Delay", HRAM
hDelay:
	ds 1

ENDC
