; The Lost Tomb
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "defs.inc"
include "judge.inc"


MACRO COPY_1BPP_LONG_SAFE
	ld bc, \1Tiles.end - \1Tiles
	call Copy1bppLongSafe
ENDM

MACRO COPY_1BPP_HALF_SAFE
ASSERT HIGH(\1Tiles.end) == HIGH(\1Tiles)
	ld b, (\1Tiles.end - \1Tiles) / 8
	call Copy1bppHalfSafe
ENDM

MACRO COPY_2BPP_SAFE
ASSERT HIGH(\1Tiles.end) == HIGH(\1Tiles)
	ld b, \1Tiles.end - \1Tiles
	call Copy2bppSafe
ENDM

SECTION FRAGMENT "Judge", ROM0
Judge::
	xor a
	ldh [rBGP], a              ; Mask out the tile update

	ld hl, STARTOF(VRAM)
	ld de, JudgeChainTiles
	COPY_1BPP_LONG_SAFE JudgeChain

	ld de, JudgeObj8Tiles
	COPY_1BPP_HALF_SAFE JudgeObj8
	COPY_1BPP_LONG_SAFE JudgeObj16

	ld hl, STARTOF(VRAM) | $0800
	COPY_1BPP_LONG_SAFE JudgeBack2
	COPY_2BPP_SAFE JudgeBack

	ld hl, STARTOF(VRAM) | $1000
	COPY_1BPP_LONG_SAFE JudgeBack1

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
JudgeChainTiles::
	INCBIN "judge_chain.1bpp"
.end::

JudgeObj8Tiles::
	INCBIN "judge_scales.1bpp"
.eye::
	INCBIN "judge_eye.1bpp"
.mouth::
	INCBIN "judge_mouth.1bpp"
.end::

JudgeObj16Tiles::
.nose::
	INCBIN "judge_nose.1bpp"
.soul::
	INCBIN "judge_soul.1bpp"
.feather::
	INCBIN "judge_feather.1bpp"
.beard::
	INCBIN "judge_beard.1bpp"
.earLeft::
	INCBIN "judge_ear_left.1bpp"
.earRight::
	INCBIN "judge_ear_right.1bpp"
.scarf::
	INCBIN "judge_scarf.1bpp"
.end::

JudgeBack2Tiles::
	INCBIN "judge_back.1bpp", 1024
.end::

JudgeBackTiles:
	INCBIN "judge_top_left.2bpp"
	INCBIN "judge_top_right.2bpp"
.end

JudgeBack1Tiles:
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
