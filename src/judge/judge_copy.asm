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
	ld de, Obj8Tiles
	ld b, (Obj8Tiles.end - Obj8Tiles) >> 3
ASSERT HIGH(Obj8Tiles.end) == HIGH(Obj8Tiles)
	call Copy1bppHalfSafe

	ld bc, Obj16Tiles.end - Obj16Tiles
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

	call InitJudgeObjects
	call ClearOAM


SECTION "InitJudgeObjects", ROM0
InitJudgeObjects:
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
	call InitString

	ld b, T_PLATE
	call SetAdjObject
	call SetAdjObject
	jp SetAdjObject


SECTION "SetLeftChainAndPlate", ROM0
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


SECTION "Copy1bppHalfSafe", ROM0
Copy1bppHalfSafe:
	ld c, TILE_HEIGHT          ; Set the loop pointer to half tile size
.copyLoop
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld a, [de]                 ; Load a byte from the address DE points to into the A register
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	inc e                      ; Increment the source pointer in E
	dec c                      ; Decrement the inner loop counter in C
	jr nz, .copyLoop           ; If C is not zero, continue to loop
	ld c, 8
.clearLoop
	rst WaitVRAM
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	dec c                      ; Decrement the inner loop counter in C
	jr nz, .clearLoop          ; If C is not zero, continue to loop
	dec b                      ; Decrement the outer loop counter in B
	jr nz, Copy1bppHalfSafe    ; If B is not zero, continue to loop
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
	add TILE_HEIGHT * 2
	ld d, a
	pop af
	dec a
	jr nz, .loop
	ld b, T_SCALE_CONF
	jr SetObject

SetLeftChain:
	ld d, a
	ld e, X_CHAIN_LEFT
	ld a, H_CHAIN_LEFT - 1
	call InitChain
	ld b, T_STRING2
	; Fall through

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

	ld b, T_PLATE_SIDE
	ld a, e
	add TILE_WIDTH
	ld e, a
	ld a, TILE_HEIGHT * 2
	call .next

	ld a, e
	sub TILE_WIDTH * 4
	ld e, a
	ld c, 0
	call SetObject
	ld a, d
	add TILE_HEIGHT
	ld d, a
	ret

.nextRow
	ld a, TILE_HEIGHT

.next
	add d
	ld d, a
	jr SetObject

SetNextObject:
	inc b                      ; Advance the tile ID
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


SECTION "Judgment Tile Data", ROMX, ALIGN[8]
Obj8Tiles:
	INCBIN "judge_eye.1bpp"
	INCBIN "judge_nose.1bpp"
	INCBIN "judge_mouth.1bpp"
.end

Obj16Tiles:
	INCBIN "judge_scales.1bpp"
	INCBIN "judge_soul.1bpp"
	INCBIN "judge_feather.1bpp"
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
