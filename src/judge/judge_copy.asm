; The Lost Tomb
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "defs.inc"
include "judge.inc"


SECTION FRAGMENT "Judge", ROM0
Judge::
	xor a
	ldh [rBGP], a              ; Mask out the tile update

	ld hl, STARTOF(VRAM)
	ld de, ObjTiles
	ld bc, ObjTiles.end - ObjTiles
	call Copy1bppLongSafe

	ld hl, STARTOF(VRAM) | $0800
	ld bc, Back2Tiles.end - Back2Tiles
	call Copy1bppLongSafe

	ld b, BackTiles.end - BackTiles
	call Copy2bppSafe

	ld hl, STARTOF(VRAM) | $1000
	ld bc, Back1Tiles.end - Back1Tiles
	call Copy1bppLongSafe

	call CopyMaps

	ld hl, wShadowOAM
	ld bc, T_EYE << 8
	ld de, Y_EYE << 8 | X_EYE_LEFT
	call SetObject
	ld b, T_NOSE
	call SetAdjObject
	ld bc, T_EYE << 8 | OAM_XFLIP
	ld e, X_EYE_RIGHT
	call SetObject
	ld bc, T_MOUTH << 8
	ld de, Y_MOUTH << 8 | X_MOUTH
	call SetObject

.soul
	ld bc, T_SOUL << 8
	ld de, Y_SOUL_0 << 8 | X_SOUL
	call SetObject
	call SetNextObject
	inc b
	ld de, (Y_SOUL_0 + TILE_HEIGHT) << 8 | X_SOUL
	call SetObject
	call SetNextObject

.feather
	ld b, T_FEATHER
	ld de, Y_FEATHER_0 << 8 | X_FEATHER
	call SetObject
	inc b
	ld d, Y_FEATHER_0 + TILE_HEIGHT
	call SetObject

.left
	ld a, H_CHAIN_LEFT - 1
	ld de, Y_CHAIN_LEFT_0 << 8 | X_CHAIN_LEFT
	call InitChain
	inc b
	call InitString

	call SetNextObject
	call SetNextObject
	call SetNextObject
	ld bc, T_PLATE_SIDE << 8 | OAM_XFLIP
	call SetAdjObject

.right
	ld bc, T_CHAIN << 8 | OAM_PRIO | OAM_YFLIP
	ld de, Y_CHAIN_RIGHT_0 << 8 | X_CHAIN_RIGHT
	call SetObject
	ld d, Y_CHAIN_RIGHT_0 + TILE_HEIGHT
	call SetObject

	ld a, H_CHAIN_RIGHT - 1
	ld de, (Y_CHAIN_RIGHT_0 + TILE_HEIGHT + DX_CHAIN_RIGHT) << 8 | X_CHAIN_RIGHT
	call InitChain
	ld b, T_STRING
	call InitString

	ld b, T_PLATE
	call SetAdjObject
	call SetAdjObject
	call SetAdjObject
	ld bc, T_PLATE_SIDE << 8 | OAM_XFLIP
	call SetAdjObject
	; TODO Fall through

	call ClearOAM


SECTION "Copy1bppLongSafe", ROM0
Copy1bppLongSafe:
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld a, [de]                 ; Load a byte from the address DE points to into the A register
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	inc de                     ; Increment the source pointer in DE
	dec bc                     ; Decrement the loop counter in BC
	ld a, b                    ; Load the value in B into A
	or c                       ; Logical OR the value in A (from B) with C
	jr nz, Copy1bppLongSafe    ; If B and C are both zero, OR B will be zero, otherwise keep looping
	ret


SECTION "Copy2bppSafe", ROM0
Copy2bppSafe:
.loop
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld a, [de]                 ; Load a byte from the address DE points to into the A register
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	inc de                     ; Increment the source pointer in DE
	dec b                      ; Decrement the loop counter in B
	jr nz, .loop               ; If B is not zero, keep looping
	ret


SECTION "CopyMaps", ROM0
CopyMaps:
	ld hl, TILEMAP0
	ld b, SCREEN_HEIGHT
.loop
	call CopyRow
	ld a, l
	add TILEMAP_WIDTH - SCREEN_WIDTH
	ld l, a
	jr nc, .cont
	inc h
.cont	
	dec b
	jr nz, .loop
	ld hl, TILEMAP1
	; Fall through

CopyRow:
	ld c, SCREEN_WIDTH
.loop
	rst WaitVRAM
	ld a, [de]
	ld [hli], a
	inc de
	dec c
	jr nz, .loop
	ret


SECTION "SetObject", ROM0
InitChain:
	ld bc, T_CHAIN << 8 | OAM_PRIO
.loop
	push af
	call SetObject
	ld a, d
	add TILE_HEIGHT
	ld d, a
	pop af
	dec a
	jr nz, .loop
	ld b, T_SCALE_CONF
	jr SetObject

InitString:
	ld a, e
	sub TILE_WIDTH
	ld e, a
	call .nextRow

	ld c, OAM_XFLIP
	ld a, e
	add TILE_WIDTH * 2
	ld e, a
	call SetObject

	ld b, T_STRING
	ld a, e
	add TILE_WIDTH
	ld e, a
	call .nextRow

	ld a, e
	sub TILE_WIDTH * 4
	ld e, a
	ld c, 0
	call SetObject
	inc b
	; Fall through

.nextRow
	ld a, d
	add TILE_HEIGHT
	ld d, a
	jr SetObject

SetNextObject:
	inc b                      ; Advance the tile ID
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


SECTION "Judgment Tile Data", ROMX
ObjTiles:
	INCBIN "judge_soul.1bpp"
	INCBIN "judge_feather.1bpp"
	INCBIN "judge_scales.1bpp"
	INCBIN "judge_eye.1bpp"
	INCBIN "judge_nose.1bpp"
	INCBIN "judge_mouth.1bpp"
.end

Back2Tiles:
	INCBIN "judge_back.1bpp", 1024
.end

BackTiles:
	INCBIN "judge_top_left.2bpp"
	INCBIN "judge_top_right.2bpp"
.end

Back1Tiles:
	INCBIN "judge_back.1bpp", 0, 1024
.end

BackMap:
	INCBIN "judge_back.tilemap", 0, ROW_TOP_RIGHT * SCREEN_WIDTH + COL_TOP_RIGHT
	db T_TOP_RIGHT
	INCBIN "judge_back.tilemap", ROW_TOP_RIGHT * SCREEN_WIDTH + COL_TOP_RIGHT + 1, ROW_TOP_LEFT * SCREEN_WIDTH + COL_TOP_LEFT - (ROW_TOP_RIGHT * SCREEN_WIDTH + COL_TOP_RIGHT + 1)
	db T_TOP_LEFT1
	INCBIN "judge_back.tilemap", ROW_TOP_LEFT * SCREEN_WIDTH + COL_TOP_LEFT + 1, SCREEN_WIDTH - 1
	db T_TOP_LEFT2
	INCBIN "judge_back.tilemap", (ROW_TOP_LEFT + 1) * SCREEN_WIDTH + COL_TOP_LEFT + 1
.end

StatusMap:
	INCBIN "judge_status.tilemap"
.end
