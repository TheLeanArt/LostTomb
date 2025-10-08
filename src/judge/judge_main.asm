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

	ld a, LCDC_ON | LCDC_BG_ON | LCDC_OBJ_ON | LCDC_WIN_ON | LCDC_WIN_9C00
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
	ld l, a
	swap a

	and $02
	add T_HEALTH_FULL
	ld [MAP_HEALTH + ROW_HEALTH * TILEMAP_WIDTH + COL_HEALTH], a

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
	ld d, H_CHAIN_LEFT
	call UpdateChain
	call UpdateSoulPlate

.right
	ld d, H_CHAIN_RIGHT
	call UpdateChain
	ld d, W_PLATE
	call UpdateRow

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
	jr .loop


SECTION "UpdateSoulPlate", ROM0
UpdateSoulPlate:
	add TILE_HEIGHT            ; Advance to the next row
.0
	ld [hl], a                 ; Set Y
	ld d, a                    ; Store the Y value in D

	ld a, e                    ; Load the flip indicator
	add a                      ; Multiply by 4
	add a                      ; ...
	ld e, a                    ; Store the attributes in E (indicator no longer needed)

.1
	ld l, (O_PLATE_LEFT + 1) * OBJ_SIZE
	ld [hl], d                 ; Set Y
	inc l                      ; Advance to X
	inc l                      ; Advance to tile ID
	swap a                     ; 0 or 8
	add T_PLATE_LEFT1          ; Calculate left tile ID
	ld [hli], a                ; Set tile ID and advance to attributes
	ld [hl], e                 ; Set attributes
	inc l                      ; Advance to the next object's Y

.2
	ld [hl], d                 ; Set Y
	ld l, (O_PLATE_LEFT + 2) * OBJ_SIZE + OAMA_FLAGS
	ld [hl], e                 ; Set attributes
	inc l                      ; Advance to the next object's Y

.3
	ld [hl], d                 ; Set Y
	ld l, (O_PLATE_LEFT + 3) * OBJ_SIZE + OAMA_TILEID
	xor T_PLATE ^ T_PLATE_LEFT1; Flip 2nd left and 2nd right
	ld [hli], a                ; Set tile ID and advance to attributes
	ld [hl], e                 ; Set attributes
	inc l                      ; Advance to the next object's Y

.4
	ld [hl], d                 ; Set Y

	ld l, O_CHAIN_RIGHT * OBJ_SIZE
	ret


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
	ld a, [bc]
	inc c
	ld d, a
	call UpdateSingle
	ld a, d
	add TILE_HEIGHT
	; Fall through

UpdateSingle:
	ld [hli], a
	inc l
	ld a, [bc]
	inc c
	ld [hli], a
	inc l
	ret


SECTION "UpdateSoul", ROM0
UpdateSoul:
	ld a, e                    ; Load the step counter
	and OAM_XFLIP << 2         ; Isolate bit 7
	swap a                     ; Move to bit 3
	ld e, a                    ; Store the flip indicator in E

	ld a, [bc]                 ; Load Y
	inc c                      ; Advance the source address
	call UpdatePair            ; Update the upper tile pair
	ld a, d                    ; Store Y in D
	add TILE_HEIGHT            ; Add tile height
	; Fall through

UpdatePair:
	ld d, a                    ; Load Y
	ld [hli], a                ; Set Y and advance to X
	ld a, e                    ; Load the flip indicator
	call UpdateHalf            ; Update the left tile

	ld a, d                    ; Load Y
	ld [hli], a                ; Set Y and advance to X
	ld a, e                    ; Load the flip indicator
	xor TILE_WIDTH             ; Flip the flip indicator
	; Fall through

UpdateHalf:
	add X_SOUL                 ; Add base X
	ld [hli], a                ; Set X and advance to tile ID
	ld a, [bc]                 ; Load tile ID
	inc c                      ; Advance source address
	ld [hli], a                ; Set tile ID and advance to attributes
	ld a, e                    ; Load the flip indicator
	add a                      ; Multiply by 4
	add a                      ; ...
	ld [hli], a                ; Set tile ID
	ret


SECTION "UpdateRow", ROM0
UpdateChain:
	ld a, [bc]
	inc c
.loop
	ld [hli], a
REPT OBJ_SIZE - 1
	inc l
ENDR
	add TILE_HEIGHT
	dec d
	jr nz, .loop
	ld d, 2
	call UpdateRow.loop
	ld d, 2
	; Fall through

UpdateRow:
	add TILE_HEIGHT
.loop
	ld [hli], a
REPT OBJ_SIZE - 1
	inc l
ENDR
	dec d
	jr nz, .loop
	ret


SECTION "Judgment Delay", HRAM
hDelay:
	ds 1
