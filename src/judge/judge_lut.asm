; The Lost Tomb
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "defs.inc"
include "judge.inc"


DEF M_CAT     EQUS READFILE("judge_cat.tilemap")
DEF M_SOUL    EQUS READFILE("judge_soul.tilemap")
DEF M_FEATHER EQUS READFILE("judge_feather.tilemap")

SECTION "JudgeLUT", ROMX, ALIGN[9]
JudgeLUT::

FOR I, 8
	db STRBYTE(#M_CAT,     I)

	INCBIN "judge_fin.tilemap", I * W_FIN, W_FIN
	INCBIN "judge_paw.tilemap", I * H_PAW * W_PAW, H_PAW * W_PAW

	db T_EYE_{d:I}
	db T_NOSE_{d:I}
	db T_MOUTH_{d:I}

	db Y_SOUL_{d:I}
	db STRBYTE(#M_SOUL,    I * W_SOUL * H_SOUL)          + T_SOUL
	db STRBYTE(#M_SOUL,    I * W_SOUL * H_SOUL + H_SOUL) + T_SOUL

	db Y_FEATHER_{d:I}
	db STRBYTE(#M_FEATHER, I * W_FEATHER * H_FEATHER)    + T_FEATHER

	db Y_CHAIN_LEFT_{d:I}
	db Y_CHAIN_RIGHT_{d:I}

	ds 5
ENDR
