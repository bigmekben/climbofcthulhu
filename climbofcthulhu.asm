; CLIMB OF CTHULHU
; programming : Benjamin James Thompson bigmekben@gmail.com
; code started on May 26, 2019

  .include "inesheader.asm"
  .rsset	$0000
  
;;;;;;;;;;;;;;;; GLOBAL DEFINES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  .include "libppu.asm"
  .include "libapu.asm"


;;;;;;;;;;;;;;;;; GAME ROM AREA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;; BANK 0 -- GAME CODE ;;;;;;;;;;;;;;;;;;;;;;;;;;;
  .bank 0
  .org $C000
RESET:
  SEI
  CLD
; Turn off APU interrupt:
  LDX #$40
  STX $4017
  
; Init stack pointer:
  LDX #$FF
  TXS
  
; Turn off other interrupts:
  INX
  STX PPUCTRL	; NMI
  STX PPUMASK	; Rendering
  STX $4010 	; DMC
  
  JSR vblankdelay
  
; Zero out RAM (except range $0200-$02FF needs to be $FE since it's sprite OAM):
initmemory:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0300, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0300, x
  INX
  BNE initmemory
  JSR vblankdelay

start:
; (TODO: review why we do these next three writes):
  LDA #%00000000
  STA PPUMASK
  LDA #%10000000
  STA PPUCTRL
  LDA #%00010000
  STA PPUMASK
  
LoadPalettes:
; Point PPU to $3F00 and reset latches:
  LDA PPUSTATUS
  LDA #$3F
  STA PPUADDR
  LDA #$00
  STA PPUADDR
  
; Make sure BG palette loop will start at index 0:  
  LDX #$00		 
LoadBgPaletteLoop:
  LDA bgpalette, x
  STA PPUDATA
  INX
  CPX #$10            
  BNE LoadBgPaletteLoop
  
; Make sure sprite palette loop will start at index 0:  
  LDX #$00
LoadSpritePaletteLoop:
  LDA spritepalette, x
  STA PPUDATA
  INX
  CPX #$10
  BNE LoadSpritePaletteLoop
  
enableSound:
  LDA #$0F
  STA APUFLAGS
  
  
prepareSpriteOne:
  LDA #MINVISIBLEX
  STA $0203		; X pos
  LDA #$80
  STA $0200  	; Y pos
  LDA #$00
  STA $0201		; tile #
  STA $0202		; attributes
prepareSpriteTwo:
  LDA #MAXVISIBLEX
  STA $0207		; X pos
  LDA #$80
  STA $0204		; Y pos
  LDA #$01		
  STA $0205		; tile #
  LDA #$41
  STA $0206		; attributes		(to do: flip left)

; turn on NMI and use pattern table 0:
  LDA #%10000000
  STA PPUCTRL
; turn on sprites:
  LDA #%00010000
  STA PPUMASK
  
gameloop:
  JMP gameloop
  
NMI:
  ;;; Copy sprite data to PPU:
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMHiByte
  JSR readControllers
  JSR processInputs
  RTI
  
processInputs:
; Process all user inputs:
; Check player 1:
  LDA PLAYER1_INPUTS
  AND #BUTTON_UP_MASK
  BEQ No_P1_Up
  LDA $0200       ; subtract 1 from Y position
  SEC             
  SBC #$01        
  STA $0200       
  
No_P1_Up:
  LDA PLAYER1_INPUTS
  AND #BUTTON_DOWN_MASK
  BEQ No_P1_Down
  LDA $0200       ; load sprite Y position
  CLC             
  ADC #$01        
  STA $0200       

No_P1_Down:
  LDA PLAYER1_INPUTS
  AND #BUTTON_LEFT_MASK
  BEQ No_P1_Left
  LDA $0203       ; subtract 1 from X position
  SEC             
  SBC #$01        
  STA $0203       
  
No_P1_Left:
  LDA PLAYER1_INPUTS
  AND #BUTTON_RIGHT_MASK
  BEQ No_P1_Right
  LDA $0203       ; add 1 to X position
  CLC             
  ADC #$01        
  STA $0203       

No_P1_Right:

; Check player 2:
  LDA PLAYER2_INPUTS
  AND #BUTTON_UP_MASK
  BEQ No_P2_Up
  LDA $0204       ; subtract 1 from Y position
  SEC             
  SBC #$01        
  STA $0204       
  
No_P2_Up:
  LDA PLAYER2_INPUTS
  AND #BUTTON_DOWN_MASK
  BEQ No_P2_Down
  LDA $0204       ; load sprite Y position
  CLC             
  ADC #$01        
  STA $0204       

No_P2_Down:
  LDA PLAYER2_INPUTS
  AND #BUTTON_LEFT_MASK
  BEQ No_P2_Left
  LDA $0207       ; subtract 1 from X position
  SEC             
  SBC #$01        
  STA $0207       
  
No_P2_Left:
  LDA PLAYER2_INPUTS
  AND #BUTTON_RIGHT_MASK
  BEQ No_P2_Right
  LDA $0207       ; add 1 to X position
  CLC             
  ADC #$01        
  STA $0207       

No_P2_Right:
  RTI
  
  .include "libcontroller.asm"  




  
;;;;;;;;; BANK 1 -- INTERRUPTS CODE ;;;;;;;;;;;;;;;;;;;;;;;;;;;
  .bank 1
  .org $E000
bgpalette:
  .db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F
spritepalette:
  .db $0F,$02,$15,$3C,$0F,$07,$02,$38,$0F,$0A,$1C,$15,$0F,$38,$02,$38

;;;;;;;;;;;; INTERRUPTS VECTORS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  .org $FFFA
  .dw NMI
  .dw RESET
  .dw 0

;;;;;;;;; BANK 2 -- BINARY INCLUDES ;;;;;;;;;;;;;;;;;;;;;
  .bank 2
  .org $0000
  .incbin "climbofcthulhu.chr"