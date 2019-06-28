; 2019-06-28 Benjamin Thompson
; adapted from background2\background.asm by bunny boy: http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=8172
; The base code started from "night #6" of the nerdy nights tutorial; then I used part of the tutorial from "advanced night #3" to add the scrolling.
; I had to figure out the wall-clipping myself to get this to constrain to just 2 rooms worth of screen, with old-school stop-scrolling-when-close-to-room-edge logic.


  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring
  

; next task: instead of auto scrolling, only scroll when player gets close to the edge of the screen (within a tolerance) and is moving toward edge of screen.  Stop scrolling when it gets
; close enough to the edge.  This means getting within L-tolerance of 0 when nametable = #$00; and within R-tolerance of 255 when nametable = $01.
; so the code that knows to skip the scroll inc/dec would do a different check depending on if the player is moving left or right and if the nametable is #$00 or #$01.
; actually, it's simpler than that.  When moving left, normally the code would unconditionally dec the scroll counter.  But since we are in the "moving left" code, we know to check whether the nametable is $00.
; When moving left,
;	if nametable is #$01, we are safe to just dec the scroll like normal.
;	if nametable is $00, only dec scroll if it is greater than LTOL.
; When moving right,
;	if nametable is #$00, we are safe to just inc the scroll like normal.
;   if nametable is #$01, only inc the scroll if it is less than RTOL.
;;;;;;;;;;;;;;;

;  .rsset	$0000
;loByte	.rs 1
;hiByte  .rs 1
loByte = $0000
scroll = $0002
nametable = $0003

LTOL = $40		; 64 pixels from left edge, or scroll = 0
RTOL = $C0		; 64 pixels from right edge, or scroll = 192

  .bank 0
  .org $C000 
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0300, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0200, x
  INX
  BNE clrmem
   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2


LoadPalettes:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address
  LDX #$00              ; start out at 0
LoadPalettesLoop:
  LDA palette, x        ; load data from address (palette + the value in x)
                          ; 1st time through loop it will load palette+0
                          ; 2nd time through loop it will load palette+1
                          ; 3rd time through loop it will load palette+2
                          ; etc
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$20              ; Compare X to hex $10, decimal 16 - copying 16 bytes = 4 sprites
  BNE LoadPalettesLoop  ; Branch to LoadPalettesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down



LoadSprites:
  LDX #$00              ; start at 0
LoadSpritesLoop:
  LDA sprites, x        ; load data from address (sprites +  x)
  STA $0200, x          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  CPX #$10              ; Compare X to hex $10, decimal 16
  BNE LoadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                        ; if compare was equal to 16, keep going down
              
InitScrolling:              
  LDA #$00
  STA scroll
  STA nametable
LoadBackground:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006             ; write the high byte of $2000 address
  LDA #$00
  STA $2006             ; write the low byte of $2000 address
  LDA #low(background)
  STA loByte
  LDA #high(background)
  STA loByte+1
  LDX #$08				; 4 = one screen; 8 = two screens
  LDY #$00
LoadBGLoop:
  LDA [loByte],y	; NESASM uses [] instead of () for indirect indexed addressing
  STA $2007             ; write to PPU
  INY
  BNE LoadBGLoop
  DEX
  BEQ LoadBGDone
  INC loByte+1
  JMP LoadBGLoop
LoadBGDone:
              
LoadAttribute:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$23
  STA $2006             ; write the high byte of $23C0 address
  LDA #$C0
  STA $2006             ; write the low byte of $23C0 address
  LDX #$00              ; start out at 0
LoadAttributeLoop:
  LDA attribute, x      ; load data from address (attribute + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$08              ; Compare X to hex $08, decimal 8 - copying 8 bytes
  BNE LoadAttributeLoop  ; Branch to LoadAttributeLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down


              
              
              
  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000

  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA $2001

Forever:
  JMP Forever     ;jump back to Forever, infinite loop
  
 

NMI:
  LDA #$00
  STA $2003       ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014       ; set the high byte (02) of the RAM address, start the transfer


LatchController:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016       ; tell both the controllers to latch buttons


ReadA: 
  LDA $4016       ; player 1 - A
ReadB:
  LDA $4016
ReadSelect:
  LDA $4016
ReadStart:
  LDA $4016
ReadUp:
  LDA $4016
ReadDown:
  LDA $4016
  
ReadLeft:
  LDA $4016
  AND #%00000001  
  BEQ ReadLeftDone
  
  LDA nametable
  BNE PlayerOnScreen1
  LDA scroll
  BEQ TryMovePlayerLeft 
  DEC scroll
  JMP ReadLeftDone
	
PlayerOnScreen1:
  LDA $0203
  CMP #$80
  BNE TryMovePlayerLeft
  LDA #$00
  STA nametable
  LDA #$FF
  STA scroll
  JMP ReadLeftDone 
  
TryMovePlayerLeft:
  LDA $0203       ; load sprite X position
  BEQ ReadLeftDone
  SEC             ; make sure carry flag is set
  SBC #$01        ; A = A - 1
  STA $0203       ; save sprite X position
  LDA $0207
  SEC
  SBC #$01
  STA $0207
  LDA $020B
  SEC
  SBC #$01
  STA $020B
  LDA $020F
  SEC
  SBC #$01
  STA $020F
ReadLeftDone:

ReadRight:
  LDA $4016
  AND #%00000001  
  BEQ ReadRightDone

  LDA nametable
  BEQ PlayerOnScreen0
  ; If player is on screen 1, the screen is as far as it will go and the player should always be moved right. 
  JMP TryMovePlayerRight
PlayerOnScreen0:
  ; If player is on screen 0, goal is to get player to X = 128 before scrolling.
  ; so if player X = 128, scroll the screen; don't move the player.  (might cause nametable to flip to 1).
  ; otherwise, need to move the player to the right. [Wouldn't need to worry about edge of screen, but since other
  ; paths will end up at that label, keep the code simple by always checking the player's x vs screen bounds.]
  LDA $0203
  CMP #$80
  BEQ DoScrollRight
  JMP TryMovePlayerRight
  
DoScrollRight:
  INC scroll
  BNE ReadRightDone
  LDA #$01
  STA nametable

TryMovePlayerRight:
  LDA $0203
  CMP #$F0
  BEQ ReadRightDone
  CLC             ; make sure the carry flag is clear
  ADC #$01        ; A = A + 1
  STA $0203       ; save sprite X position
  LDA $0207
  CLC
  ADC #$01
  STA $0207
  LDA $020B
  CLC
  ADC #$01
  STA $020B
  LDA $020F
  CLC
  ADC #$01
  STA $020F
ReadRightDone:


SetHScroll:
  LDA scroll	
  STA $2005		; first byte: horizontal scroll
SetVScroll:
  LDA #$00      ; second byte: vertical scroll
  STA $2005
 

  ;;This is the PPU clean up section, so rendering the next frame starts properly.
  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  ORA nametable
  STA $2000
  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA $2001
  
  
  RTI             ; return from interrupt
 
;;;;;;;;;;;;;;  
  
  
  
  .bank 1
  .org $E000
palette:
  .incbin "D:\nes_homebrew\nerdynights\background2\screen1.pal" ; if we store multiple bg palettes, would have to have code that's smart enough to copy the correct palette to the PPU
  .db $22,$1C,$15,$14,  $22,$02,$38,$3C,  $22,$1C,$15,$14,  $22,$02,$38,$3C   ;;sprite palette

sprites:
     ;vert tile attr horiz
  .db $80, $32, $00, $80   ;sprite 0
  .db $80, $33, $00, $88   ;sprite 1
  .db $88, $34, $00, $80   ;sprite 2
  .db $88, $35, $00, $88   ;sprite 3


background:
  .incbin "D:\nes_homebrew\nerdynights\background2\screen1.nam"
  .incbin "D:\nes_homebrew\nerdynights\background2\screen2.nam"





  
attribute:
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000



  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial
  
  
;;;;;;;;;;;;;;  
  
  
  .bank 2
  .org $0000
  .incbin "D:\nes_homebrew\nerdynights\background2\mario.chr"   ;includes 8KB graphics file from SMB1