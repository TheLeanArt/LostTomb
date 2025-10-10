; The Lost Tomb
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "defs.inc"
include "judge.inc"


SECTION FRAGMENT "Judge", ROM0
	call InitJudgeObjects
	call ClearOAM


SECTION "SetObject", ROM0
InitJudgeObjects:
	ld hl, wShadowOAM
	ld bc, T_EYE << 8
	ld de, Y_EYE << 8 | X_EYE_LEFT
	call SetObject
	ld bc, T_EYE << 8 | OAM_XFLIP
	ld e, X_EYE_RIGHT
	call SetObject
	ld b, T_SCARF_0
	ld de, Y_SCARF << 8 | X_SCARF_RIGHT
	call SetObject
	ld c, 0
	ld e, X_SCARF_LEFT
	call SetObject
	ld b, T_NOSE_0
	ld de, Y_NOSE << 8 | X_NOSE
	call SetObject
	ld b, T_MOUTH_0
	ld de, Y_MOUTH << 8 | X_MOUTH
	call SetObject
	ld b, T_BEARD
	ld d, Y_BEARD
	call SetObject
	ld b, T_EAR_LEFT
	ld de, Y_EAR_LEFT << 8 | X_EAR_LEFT
	call SetObject
	ld b, T_EAR_RIGHT
	ld de, Y_EAR_RIGHT << 8 | X_EAR_RIGHT
	call SetObject

.soul
	ld bc, T_SOUL << 8
	ld de, Y_SOUL_0 << 8 | X_SOUL
	call SetObject
	inc b                      ; Advance the tile ID
	inc b                      ; Advance the tile ID
	call SetAdjObject

.feather
	ld b, T_FEATHER
	ld de, Y_FEATHER_0 << 8 | X_FEATHER
	call SetObject

.left
	ld a, Y_CHAIN_LEFT_0
	call SetLeftChain
	call SetLeftPlate

.right
	ld a, Y_CHAIN_RIGHT_0
	; Fall through

SetRightChainAndPlate::
	ld d, a
	ld e, X_CHAIN_RIGHT
	ld bc, T_CHAIN << 8 | OAM_PRIO | OAM_YFLIP
	call SetObject

	add DX_CHAIN_RIGHT + TILE_HEIGHT * 2
	ld d, a
	ld a, H_CHAIN_RIGHT - 1
	call InitChain

	ld b, T_STRING
	ld a, TILE_HEIGHT * 2
	ld e, X_CHAIN_RIGHT - TILE_WIDTH
	call InitNextString

	ld e, X_CHAIN_RIGHT + TILE_WIDTH
	ld a, TILE_HEIGHT
	call InitString

	ld b, T_PLATE
	call SetAdjObject
	call SetAdjObject
	; Fall through

SetAdjObject:
	ld [hl], d                 ; Set the Y coordinate
	inc l                      ; Increment the lower address byte
	ld a, e                    ; Load the X coordinate from E
	add TILE_WIDTH             ; Advance the X coordinate
	ld [hli], a                ; Set the X coordinate
	ld e, a                    ; Store the updated X coordinate
	ld a, b                    ; Load the tile ID from B
	ld [hli], a                ; Set the tile ID
	ld a, c                    ; Load the attributes from C
	ld [hli], a                ; Set the attributes
	ret

SetObject:
	ld [hl], d                 ; Set the Y coordinate
	inc l                      ; Increment the lower address byte
	ld [hl], e                 ; Set the X coordinate
	inc l                      ; Increment the lower address byte
	ld [hl], b                 ; Set the tile ID
	inc l                      ; Increment the lower address byte
	ld [hl], c                 ; Set the attributes
	inc l                      ; Increment the lower address byte
	ret

SetLeftChainAndPlate::
	push de                    ; Save the flip indicator
	call SetLeftChain          ; Update the chain
	ld d, a                    ; Store the Y value in D
	pop bc                     ; Restore the flip indicator in C
	; Fall through

SetLeftPlate:
	ld a, c                    ; Load the flip indicator into A
	rlc c                      ; Multiply C by 4
	rlc c                      ; ...
	rrca                       ; Divide A by 2
	add T_PLATE_LEFT1          ; Calculate left tile ID
	ld b, a                    ; Store the tile ID in B
	ld e, X_PLATE_LEFT1        ; Store the X coordinate in E
	call SetObject             ; Set the first object
	ld b, T_PLATE_LEFT2        ; Store the tile ID in B
	ld e, X_PLATE_LEFT2        ; Store the X coordinate in E
	call SetObject             ; Set the second object
	xor T_PLATE ^ T_PLATE_LEFT1; Flip first and third
	ld b, a                    ; Store the tile ID in B
	ld e, X_PLATE_LEFT3        ; Store the X coordinate in E
	jr SetObject               ; Set the third object and return

InitChain:
	ld bc, T_CHAIN << 8 | OAM_PRIO
.loop
	push af
	call SetObject
	ld a, d
	add TILE_HEIGHT * 2
	ld d, a
	pop af
	dec a
	jr nz, .loop
	ld b, T_SCALE_CONF
	jr SetObject

InitNextString:
	add d
	ld d, a
	jr SetObject


SECTION "InitString", ROM0
SetLeftChain:
	ld d, a
	ld e, X_CHAIN_LEFT
	ld a, H_CHAIN_LEFT - 1
	call InitChain

	ld b, T_STRING2
	ld a, TILE_HEIGHT
	ld e, X_CHAIN_LEFT - TILE_WIDTH
	call InitNextString

	ld e, X_CHAIN_LEFT + TILE_WIDTH
	ld a, TILE_HEIGHT * 2
	; Fall through

InitString:
	ld c, OAM_XFLIP
	call SetObject

	add d
	ld d, a
	ld b, T_PLATE_SIDE
	call SetAdjObject

	ld a, e
	sub TILE_WIDTH * 4
	ld e, a
	ld c, 0
	call SetObject
	ld a, d
	add TILE_HEIGHT
	ld d, a
	ret
