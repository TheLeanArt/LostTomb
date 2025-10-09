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
	INCBIN "judge_beard.1bpp"
	INCBIN "judge_ear_left.1bpp"
	INCBIN "judge_ear_right.1bpp"
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
