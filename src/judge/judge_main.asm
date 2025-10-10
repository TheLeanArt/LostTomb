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

	ld e, 0
.loop
	push de
	rst WaitVBlank

	ld a, e
	and $07
	jr nz, .loopCont

	ld a, e
	and $38
	add a
	ld b, a
	swap a

; Optimized by calc84maniac
.health
	cpl
	add MAX_HEALTH + 1
	ld hl, MAP_HEALTH + ROW_HEALTH * TILEMAP_WIDTH + COL_HEALTH
.healthLoop
	sub 2
	ld d, T_HEALTH_FULL
	jr nc, .healthCont
	add d                      ; T_HEALTH_EMPTY or T_HEALTH_HALF
	ld d, a
	xor a
.healthCont
	ld [hl], d
	inc l
	bit 2, l
	jr z, .healthLoop

	ld l, b
	ld h, HIGH(JudgeLUT) >> 1
	add hl, hl
	call SetPawAndFin

	ld a, [hli]
	ld c, LOW(ROW_WAVE * TILEMAP_WIDTH + COL_WAVE)
.waveLoop
	ld [bc], a
	inc c
	bit TZCOUNT(TILEMAP_WIDTH), c
	jr z, .waveLoop

	ld a, [hli]
	ld [bc], a
	ld c, LOW(ROW_BUBBLE * TILEMAP_WIDTH + COL_BUBBLE1)
	ld [bc], a
	ld c, LOW(ROW_BUBBLE * TILEMAP_WIDTH + COL_BUBBLE2)
	ld [bc], a
	ld c, LOW(ROW_BUBBLE * TILEMAP_WIDTH + COL_BUBBLE3)
	ld [bc], a

	ld a, [hli]
	ld c, LOW(ROW_CAT * TILEMAP_WIDTH + COL_CAT)
	ld [bc], a

.eyes
	ld a, [hli]
	ld bc, wShadowOAM + O_EYE_LEFT * OBJ_SIZE + OAMA_TILEID
	ld [bc], a
	ld c, O_EYE_RIGHT * OBJ_SIZE + OAMA_TILEID
	ld [bc], a

.nose
	ld a, [hli]
	ld c, O_NOSE * OBJ_SIZE + OAMA_TILEID
	ld [bc], a

.mouth
	ld a, [hli]
	ld c, O_MOUTH * OBJ_SIZE + OAMA_TILEID
	ld [bc], a

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
	ldh a, [hDelay]
	or a
	jr z, .doSound
	dec a
	ldh [hDelay], a
	jr .loopDone

.doSound
	call hUGE_dosound

.loopDone
	pop de
	inc e
	jp .loop


SECTION "SetPawAndFin", ROM0
SetPawAndFin:

FOR Y, ROW_PAW, ROW_PAW + H_PAW
IF Y == ROW_PAW
	ld bc, MAP_PAW + ROW_PAW * TILEMAP_WIDTH + COL_PAW
ELSE
	ld c, Y * TILEMAP_WIDTH + COL_PAW
ENDC
	call CopyFour
ENDR

	ld bc, MAP_FIN + ROW_FIN * TILEMAP_WIDTH + COL_FIN
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
	and OAM_XFLIP << 2         ; Isolate bit 7
	swap a                     ; Move to bit 3
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


SECTION "Judgment Delay", HRAM
hDelay:
	ds 1
