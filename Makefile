RGBLINK = rgblink
RGBFIX  = rgbfix
RGBASM  = rgbasm
RGBGFX  = rgbgfx

TITLE = JUDGMENT
TARGET = judgment.gb
SYM = judgment.sym

RGBLINKFLAGS = -n $(SYM)
RGBFIXFLAGS  = -v -p 0xFF -t $(TITLE)
RGBASMFLAGS  = -I inc
RGBASMFLAGS_JUDGE = $(RGBASMFLAGS) -I inc -I art/judge \
	-D _SOUL=$(T_SOUL) \
	-D _FEATHER=$(T_FEATHER) \
	-D _CHAIN=$(T_CHAIN) \
	-D _EYE=$(T_EYE) \
	-D _NOSE=$(T_NOSE) \
	-D _MOUTH=$(T_MOUTH) \
	-D _TOP_LEFT=$(T_TOP_LEFT) \
	-D _TOP_RIGHT=$(T_TOP_RIGHT) \

T_SOUL      = 01
T_FEATHER   = 1C
T_CHAIN     = 20
T_EYE       = 28
T_NOSE      = 2C
T_MOUTH     = 2E
T_TOP_LEFT  = AE
T_TOP_RIGHT = B0

OBJS = \
	src/main.o \
	src/oamdma.o \
	src/judge/judge_copy.o \
	src/judge/judge_main.o \
	src/judge/judge_lut.o \
	src/song_hideout.o \
	src/hUGEDriver.o \

INC = \
	inc/hardware.inc \
	inc/defs.inc \

JUDGE_INC = \
	inc/judge.inc \

JUDGE_1BPP = \
	art/judge/blank.1bpp \
	art/judge/judge_status.1bpp \
	art/judge/judge_eye.1bpp \
	art/judge/judge_nose.1bpp \
	art/judge/judge_mouth.1bpp \
	art/judge/judge_scales.1bpp \
	art/judge/judge_soul.1bpp \
	art/judge/judge_feather.1bpp \
	art/judge/judge_cat.1bpp \
	art/judge/judge_wave.1bpp \
	art/judge/judge_bubble.1bpp \
	art/judge/judge_paw.1bpp \
	art/judge/judge_fin.1bpp \
	art/judge/judge_back.1bpp \

JUDGE_2BPP = \
	art/judge/judge_top_left.2bpp \
	art/judge/judge_top_right.2bpp \

JUDGE_MAIN_MAPS = \
	art/judge/judge_status.tilemap \
	art/judge/judge_eye.tilemap \
	art/judge/judge_nose.tilemap \
	art/judge/judge_mouth.tilemap \
	art/judge/judge_soul.tilemap \
	art/judge/judge_feather.tilemap \
	art/judge/judge_cat.tilemap \
	art/judge/judge_wave.tilemap \
	art/judge/judge_bubble.tilemap \
	art/judge/judge_paw.tilemap \
	art/judge/judge_fin.tilemap \

JUDGE_MAPS = \
	art/judge/judge_back.tilemap \

JUDGE_PALS = \
	art/judge/judge_top.pal \

all: $(TARGET)

clean:
	rm -f $(TARGET) $(SYM) $(OBJS) $(JUDGE_1BPP) $(JUDGE_2BPP) $(JUDGE_MAPS) $(JUDGE_MAIN_MAPS) $(JUDGE_PALS)

$(TARGET): $(OBJS)
	$(RGBLINK) $(RGBLINKFLAGS) $^ -o $@
	$(RGBFIX) $(RGBFIXFLAGS) $@

src/judge/judge_copy.o: src/judge/judge_copy.asm $(INC) $(JUDGE_INC) $(JUDGE_1BPP) $(JUDGE_2BPP) $(JUDGE_MAPS)
	$(RGBASM) $(RGBASMFLAGS_JUDGE) $< -o $@

src/judge/judge_lut.o: src/judge/judge_lut.asm $(INC) $(JUDGE_INC) $(JUDGE_MAIN_MAPS)
	$(RGBASM) $(RGBASMFLAGS_JUDGE) $< -o $@

src/judge/%.o: src/judge/%.asm $(INC) $(JUDGE_INC)
	$(RGBASM) $(RGBASMFLAGS_JUDGE) $< -o $@

src/oamdma.o: src/oamdma.asm $(INC)
	$(RGBASM) $(RGBASMFLAGS) $< -o $@

src/%.o: src/%.asm $(INC)
	$(RGBASM) $(RGBASMFLAGS) $< -o $@

art/judge/judge_scales.1bpp: art/judge/judge_scales.png
	$(RGBGFX) -um -d1 $< -o $@

art/judge/judge_soul.1bpp art/judge/judge_soul.tilemap: art/judge/judge_soul.png art/judge/blank.1bpp
	$(RGBGFX) -u -d1 -T $< -o $@ -i art/judge/blank.1bpp

art/judge/judge_feather.1bpp art/judge/judge_feather.tilemap: art/judge/judge_feather.png
	$(RGBGFX) -u -d1 -T -b 0x$(T_FEATHER) $< -o $@

art/judge/judge_eye.1bpp art/judge/judge_eye.tilemap: art/judge/judge_eye.png
	$(RGBGFX) -u -d1 -T -b 0x$(T_EYE) $< -o $@

art/judge/judge_nose.1bpp art/judge/judge_nose.tilemap: art/judge/judge_nose.png
	$(RGBGFX) -u -d1 -T -b 0x$(T_NOSE) $< -o $@

art/judge/judge_mouth.1bpp art/judge/judge_mouth.tilemap: art/judge/judge_mouth.png
	$(RGBGFX) -u -d1 -T -b 0x$(T_MOUTH) $< -o $@

art/judge/judge_status.1bpp art/judge/judge_status.tilemap: art/judge/judge_status.png art/judge/blank.1bpp
	$(RGBGFX) -u -d1 -T $< -o $@ -i art/judge/blank.1bpp

art/judge/judge_cat.1bpp art/judge/judge_cat.tilemap: art/judge/judge_cat.png art/judge/judge_status.1bpp
	$(RGBGFX) -u -d1 -T $< -o $@ -i art/judge/judge_status.1bpp

art/judge/judge_wave.1bpp art/judge/judge_wave.tilemap: art/judge/judge_wave.png art/judge/judge_cat.1bpp
	$(RGBGFX) -u -d1 -T $< -o $@ -i art/judge/judge_cat.1bpp

art/judge/judge_bubble.1bpp art/judge/judge_bubble.tilemap: art/judge/judge_bubble.png art/judge/judge_wave.1bpp
	$(RGBGFX) -u -d1 -T $< -o $@ -i art/judge/judge_wave.1bpp

art/judge/judge_paw.1bpp art/judge/judge_paw.tilemap: art/judge/judge_paw.png art/judge/judge_bubble.1bpp
	$(RGBGFX) -u -d1 -T $< -o $@ -i art/judge/judge_bubble.1bpp

art/judge/judge_fin.1bpp art/judge/judge_fin.tilemap: art/judge/judge_fin.png art/judge/judge_paw.1bpp
	$(RGBGFX) -u -d1 -T $< -o $@ -i art/judge/judge_paw.1bpp

art/judge/judge_back.1bpp art/judge/judge_back.tilemap: art/judge/judge_back.png art/judge/judge_fin.1bpp
	$(RGBGFX) -u -d1 -T $< -o $@ -i art/judge/judge_fin.1bpp

art/judge/judge_top_left.2bpp art/judge/judge_top.pal: art/judge/judge_top_left.png
	$(RGBGFX) -d2 $< -o $@ -p art/judge/judge_top.pal

art/judge/judge_top_right.2bpp: art/judge/judge_top_right.png art/judge/judge_top.pal
	$(RGBGFX) -d2 $< -o $@ -c gbc:art/judge/judge_top.pal

art/%.1bpp: art/%.png
	$(RGBGFX) -d1 $< -o $@

art/%.2bpp: art/%.png
	$(RGBGFX) -d2 $< -o $@
