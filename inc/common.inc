; Common Game Boy definitions
;
; Copyright (c) 2025 Dmitry Shechtman


MACRO DEF_TILE_ADDR
	DEF A_\1 EQU ROW_\1 * SCREEN_WIDTH + COL_\1
ENDM

MACRO DEF_VRAM_ADDR
	DEF V_\1 EQU TILEMAP{d:MAP_\1} + ROW_\1 * TILEMAP_WIDTH + COL_\1
ENDM

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
