; The Lost Tomb
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "defs.inc"
include "judge.inc"


DEF M_WAVE   EQUS READFILE("judge_wave.tilemap")
DEF M_BUBBLE EQUS READFILE("judge_bubble.tilemap")
DEF M_CAT    EQUS READFILE("judge_cat.tilemap")
DEF M_EYE    EQUS READFILE("judge_eye.tilemap")
DEF M_NOSE   EQUS READFILE("judge_nose.tilemap")
DEF M_MOUTH  EQUS READFILE("judge_mouth.tilemap")

SECTION "JudgeLUT", ROMX, ALIGN[9]
JudgeLUT::

FOR I, 8
	INCBIN "judge_paw.tilemap", I * H_PAW * W_PAW, H_PAW * W_PAW
	INCBIN "judge_fin.tilemap", I * W_FIN, W_FIN
	db STRBYTE(#M_WAVE,   I)
	db STRBYTE(#M_BUBBLE, I)
	db STRBYTE(#M_CAT,    I)
	db STRBYTE(#M_EYE,    I)
	db STRBYTE(#M_NOSE,   I)
	db STRBYTE(#M_MOUTH,  I)

	db Y_SOUL_{d:I}
	INCBIN "judge_soul.tilemap", I * H_SOUL * W_SOUL, H_SOUL * W_SOUL

	db Y_FEATHER_{d:I}
	INCBIN "judge_feather.tilemap", I * W_FEATHER, W_FEATHER

	db Y_CHAIN_RIGHT_{d:I}
	db Y_CHAIN_LEFT_{d:I}
ENDR
