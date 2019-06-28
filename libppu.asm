; libppu.asm

; PPU stuff (graphics, backgrounds, sprites)


; Registers/memory locations
PPUCTRL = $2000
PPUMASK = $2001
PPUSTATUS = $2002
OAMADDR = $2003
OAMDATA = $2004
PPUSCROLL = $2005
PPUADDR = $2006
PPUDATA = $2007
OAMHiByte = $4014  

; Numeric constants
; For these, remember to put # at the front, e.g.: "  CMP #MINVISIBLEX":
MINVISIBLEX = $08
MINVISIBLEY = $07
MAXVISIBLEX = $F7

vblankdelay:
  BIT PPUSTATUS
  BPL vblankdelay
  RTS