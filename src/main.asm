; The Lost Tomb
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "defs.inc"


SECTION "Start", ROM0[$0100]
	di                         ; Disable interrupts during setup
	jp EntryPoint              ; Jump past the header space to our actual code
	ds $150 - @, 0             ; Allocate space for RGBFIX to insert our ROM header


SECTION "EntryPoint", ROM0
EntryPoint:
	ld sp, wStack.end          ; Set the stack pointer to the end of WRAM
	call CopyOAMDMA
	jp Judge


SECTION "Stack", WRAMX[$E000 - STACK_SIZE]
wStack:
	ds STACK_SIZE
.end
