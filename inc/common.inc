; Common Game Boy definitions
;
; Copyright (c) 2025 Dmitry Shechtman


MACRO DEF_TILE_ADDR
	DEF A_\1 EQU ROW_\1 * SCREEN_WIDTH + COL_\1
ENDM

MACRO DEF_VRAM_ADDR
	DEF V_\1 EQU TILEMAP{d:MAP_\1} + ROW_\1 * TILEMAP_WIDTH + COL_\1
ENDM

MACRO DEF_Y_ADDR
	DEF A_\1_Y EQUS "wShadowOAM + O_\1 * OBJ_SIZE + OAMA_Y"
ENDM

MACRO DEF_X_ADDR
	DEF A_\1_X EQUS "wShadowOAM + O_\1 * OBJ_SIZE + OAMA_X"
ENDM

MACRO DEF_TILEID_ADDR
	DEF A_\1_TILEID EQUS "wShadowOAM + O_\1 * OBJ_SIZE + OAMA_TILEID"
ENDM

MACRO DEF_FLAGS_ADDR
	DEF A_\1_FLAGS EQUS "wShadowOAM + O_\1 * OBJ_SIZE + OAMA_FLAGS"
ENDM

; @param \1 Tiles prefix
MACRO COPY_1BPP_LONG_SAFE
	ld bc, \1Tiles.end - \1Tiles
	call Copy1bppLongSafe
ENDM

; @param \1 Tiles prefix
MACRO COPY_1BPP_HALF_SAFE
ASSERT HIGH(\1Tiles.end) == HIGH(\1Tiles)
	ld b, (\1Tiles.end - \1Tiles) / 8
	call Copy1bppHalfSafe
ENDM

; @param \1 Tiles prefix
MACRO COPY_2BPP_SAFE
ASSERT HIGH(\1Tiles.end) == HIGH(\1Tiles)
	ld b, \1Tiles.end - \1Tiles
	call Copy2bppSafe
ENDM
