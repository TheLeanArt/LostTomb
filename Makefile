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
RGBASMFLAGS_JUDGE = $(RGBASMFLAGS) \
	-I art/judge

OBJS = \
	src/main.o \
	src/oamdma.o \
	src/judge/judge_copy.o \
	src/judge/judge_obj.o \
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
	art/judge/judge_beard.1bpp \
	art/judge/judge_ear_left.1bpp \
	art/judge/judge_ear_right.1bpp \
	art/judge/judge_scarf.1bpp \
	art/judge/judge_scarf_tip.1bpp \
	art/judge/judge_chain.1bpp \
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
	art/judge/judge_scarf_tip.tilemap \
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
	$(RGBASM) $(RGBASMFLAGS) $< -o $@

src/oamdma.o: src/oamdma.asm $(INC)
	$(RGBASM) $(RGBASMFLAGS) $< -o $@

src/%.o: src/%.asm $(INC)
	$(RGBASM) $(RGBASMFLAGS) $< -o $@

art/judge/judge_soul.1bpp art/judge/judge_soul.tilemap: art/judge/judge_soul.png
	$(RGBGFX) -Z -d1 -T $< -o $@

art/judge/judge_feather.1bpp art/judge/judge_feather.tilemap: art/judge/judge_feather.png
	$(RGBGFX) -uZ -d1 -T $< -o $@

art/judge/judge_eye.1bpp art/judge/judge_eye.tilemap: art/judge/judge_eye.png
	$(RGBGFX) -u -d1 -T $< -o $@

art/judge/judge_nose.1bpp: art/judge/judge_nose.png
	$(RGBGFX) -Z -d1 $< -o $@

art/judge/judge_mouth.1bpp: art/judge/judge_mouth.png
	$(RGBGFX) -Z -d1 $< -o $@

art/judge/judge_status.1bpp art/judge/judge_status.tilemap: art/judge/judge_status.png art/judge/blank.1bpp
	$(RGBGFX) -u -d1 -T $< -o $@ -i art/judge/blank.1bpp

art/judge/judge_cat.1bpp art/judge/judge_cat.tilemap: art/judge/judge_cat.png art/judge/judge_status.1bpp
	$(RGBGFX) -u -d1 -T $< -o $@ -i art/judge/judge_status.1bpp

art/judge/judge_wave.1bpp art/judge/judge_wave.tilemap: art/judge/judge_wave.png art/judge/judge_cat.1bpp
	$(RGBGFX) -u -d1 -T $< -o $@ -i art/judge/judge_cat.1bpp

art/judge/judge_bubble.1bpp art/judge/judge_bubble.tilemap: art/judge/judge_bubble.png art/judge/judge_wave.1bpp
	$(RGBGFX) -u -d1 -T $< -o $@ -i art/judge/judge_wave.1bpp

art/judge/judge_scarf_tip.1bpp art/judge/judge_scarf_tip.tilemap: art/judge/judge_scarf_tip.png art/judge/judge_bubble.1bpp
	$(RGBGFX) -u -d1 -T $< -o $@ -i art/judge/judge_bubble.1bpp

art/judge/judge_paw.1bpp art/judge/judge_paw.tilemap: art/judge/judge_paw.png art/judge/judge_scarf_tip.1bpp
	$(RGBGFX) -u -d1 -T $< -o $@ -i art/judge/judge_scarf_tip.1bpp

art/judge/judge_fin.1bpp art/judge/judge_fin.tilemap: art/judge/judge_fin.png art/judge/judge_paw.1bpp
	$(RGBGFX) -u -d1 -T $< -o $@ -i art/judge/judge_paw.1bpp

art/judge/judge_back.1bpp art/judge/judge_back.tilemap: art/judge/judge_back.png art/judge/judge_fin.1bpp
	$(RGBGFX) -u -d1 -T $< -o $@ -i art/judge/judge_fin.1bpp

art/judge/judge_top_left.2bpp art/judge/judge_top.pal: art/judge/judge_top_left.png
	$(RGBGFX) -d2 $< -o $@ -p art/judge/judge_top.pal

art/judge/judge_top_right.2bpp: art/judge/judge_top_right.png art/judge/judge_top.pal
	$(RGBGFX) -d2 $< -o $@ -c gbc:art/judge/judge_top.pal

art/judge/%.1bpp: art/judge/%.png
	$(RGBGFX) -Z -d1 $< -o $@

art/%.2bpp: art/%.png
	$(RGBGFX) -d2 $< -o $@
