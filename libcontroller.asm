; libcontroller.asm


; USER MEMORY
;	(client must invoke .rsset before including any library files that define variables.)
PLAYER1_INPUTS	.rs 1
PLAYER2_INPUTS	.rs 1


CONTROLLERLATCH = $4016
CONTROLLER1 = $4016
CONTROLLER2 = $4017

BUTTON_A_MASK 		= %10000000
BUTTON_B_MASK 		= %01000000
BUTTON_SELECT_MASK 	= %00100000
BUTTON_START_MASK 	= %00010000
BUTTON_UP_MASK 		= %00001000
BUTTON_DOWN_MASK 	= %00000100
BUTTON_LEFT_MASK 	= %00000010
BUTTON_RIGHT_MASK 	= %00000001


readControllers:
; Reset user inputs read from last cycle:
  LDA #$00
  STA PLAYER1_INPUTS
  LDA #$00
  STA PLAYER2_INPUTS
  
latchControllers:
  LDA #$01
  STA CONTROLLERLATCH
  LDA #$00
  STA CONTROLLERLATCH
  
; Read Controller 1:
  LDX #$08
readController1:
  LDA CONTROLLER1		; A-Button
  LSR A			
  ROL PLAYER1_INPUTS
  DEX
  BNE readController1
  
; Read Controller 2:
  LDX #$08
readController2:
  LDA CONTROLLER2
  LSR A
  ROL PLAYER2_INPUTS
  DEX
  BNE readController2
  RTS
