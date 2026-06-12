# Phosphor — a package of vector arcade games for Playdate.
#
#   make rubble            build games/rubble -> out/Rubble.pdx
#   make rubble-smoke      instrumented build -> out/RubbleSmoke.pdx
#   make all               every game, release builds
#
# A build stages vec/* + games/<g>/* into build/<g>/source (pdc wants one
# source root), writes smokeflag.lua, then runs pdc.

GAMES := rubble welldiver touchdown ringkeep bordercircuit lifters webguard treadline nightvector trenchfire gravitywells duelstar

OUT := out

define TITLECASE
$(shell echo $(1) | awk '{print toupper(substr($$0,1,1)) substr($$0,2)}')
endef

all: $(GAMES)

define GAME_RULES
$(1): build/$(1)/source
	pdc build/$(1)/source $(OUT)/$(call TITLECASE,$(1)).pdx

$(1)-smoke: build/$(1)-smoke/source
	pdc build/$(1)-smoke/source $(OUT)/$(call TITLECASE,$(1))Smoke.pdx

build/$(1)/source: vec/*.lua games/$(1)/*
	mkdir -p $$@ $(OUT)
	cp vec/*.lua $$@/
	cp -r games/$(1)/* $$@/
	rm -f $$@/README.md $$@/screenshot.png
	echo 'SMOKE_BUILD = false' > $$@/smokeflag.lua

build/$(1)-smoke/source: vec/*.lua games/$(1)/*
	mkdir -p $$@ $(OUT)
	cp vec/*.lua $$@/
	cp -r games/$(1)/* $$@/
	rm -f $$@/README.md $$@/screenshot.png
	echo 'SMOKE_BUILD = true' > $$@/smokeflag.lua

.PHONY: $(1) $(1)-smoke
endef

$(foreach g,$(GAMES),$(eval $(call GAME_RULES,$(g))))

clean:
	rm -rf build $(OUT)

.PHONY: all clean
