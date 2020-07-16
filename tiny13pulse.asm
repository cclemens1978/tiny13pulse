; header file of ATtiny13
.include "tn13def.inc"


; register name of R16 .. R25
.def foo = R16      ; temporary register
.def SREGsvd = R17  ; temporary Status Register
.def CNT2 = R18     ; CNT[23:16]: 24 bit counter
.def CNT1 = R19     ; CNT[15:8]: 24 bit counter
.def CNT0 = R20     ; CNT[7:0]: 24 bit counter


; reset and interrupt vectors
rjmp RESET     ; Reset Handler
rjmp IRQ0      ; IRQ0 Handler
reti           ; PCIRQ0 Handler
rjmp TIM0_OVF  ; Timer0 Overflow Handler
reti           ; EEPROM Ready Handler
reti           ; AC Comparison Handler
reti           ; Timer0 CompareA Handler
reti           ; Timer0 CompareB Handler
reti           ; Watchdog Overflow Handler
reti           ; ADC Conversion Handler


RESET:
  ; initialise Port B
  ldi foo, 0b00010101
  out DDRB, foo        ; set PB5:I, PB4:O, PB3:I, PB2:O, PB1:I, PB0:O
  ldi foo, 0b01000000
  out MCUCR, foo       ; deactivate all pull-up resistors

  ; initialise Interrupt Request 0
  ldi foo, 0b01000010
  out MCUCR, foo       ; set Interrupt Sense Control 0: Falling Edge
  ldi foo, 0b01000000
  out GIMSK, foo       ; enable Interrupt Request 0

  ; initialise Analog Comparator
  ldi foo, 0b10000000
  out ACSR, foo        ; deactivate Analog Comparator

  ; initialise Watchdog
  ldi foo, 0b00000000
  out MCUSR, foo
  ldi foo, 0b00011000
  out WDTCR, foo
  ldi foo, 0b00000000
  out WDTCR, foo       ; deactivate Watchdog

  ; enable Global Interrupt
  sei

  ; initialise Sleep Mode
  ldi foo, 0b01100010
  out MCUCR, foo       ; set Sleep Mode: Idle, enable Sleep Mode


MAIN:
  ; activate Sleep Mode
  sleep

  ; loop
  rjmp MAIN


IRQ0:
  ; store Status Register
  in SREGsvd, SREG

  ; initialise Z-register
  ldi ZH, 0x01
  ldi ZL, 0x00

  ; load first definition to Port B
  lpm foo, Z+
  out PORTB, foo

  ; load first definition to CNT
  lpm CNT2, Z+
  lpm CNT1, Z+
  lpm CNT0, Z+

  ; initialise Timer0
  ldi foo, 0x83
  out TCNT0, foo
  ldi foo, 0b00000011
  out TCCR0B, foo
  ldi foo, 0b00000010
  out TIMSK0, foo

  ; restore Status Register
  out SREG, SREGsvd

  ; return from IRQ0
  reti


TIM0_OVF:
  ; store Status Register
  in SREGsvd, SREG

  ; load Timer0
  ldi foo, 0x83
  out TCNT0, foo

  ; decrement 24 bit counter
  subi CNT0, 0x01
  sbci CNT1, 0x00
  sbci CNT2, 0x00

  ; compare 24 bit counter
  cpi CNT2, 0x00
  brne D1
  cpi CNT1, 0x00
  brne D1
  cpi CNT0, 0x00
  brne D1

  ; load next definition to Port B
  lpm foo, Z+
  out PORTB, foo

  ; load next definition to CNT
  lpm CNT2, Z+
  lpm CNT1, Z+
  lpm CNT0, Z+

  ; compare 24 bit counter
  cpi CNT2, 0x00
  brne D1
  cpi CNT1, 0x00
  brne D1
  cpi CNT0, 0x00
  brne D1

  ; deinitialise Timer0
  ldi foo, 0b00000000
  out TIMSK0, foo
  ldi foo, 0b00000000
  out TCCR0B, foo
  ldi foo, 0x00
  out TCNT0, foo

  D1:

  ; restore Status Register
  out SREG, SREGsvd

  ; return from TIM0_OVF
  reti


; definitions of Port B and CNT
.org 0x080
.db 0b00000000, 0x00, 0x00, 0x18  ; define PB4:0, PB2:0, PB0:0, CNT: 0.096 s
.db 0b00000001, 0x00, 0x00, 0x18  ; define PB4:0, PB2:0, PB0:1, CNT: 0.096 s
.db 0b00000101, 0x00, 0x00, 0x18  ; define PB4:0, PB2:1, PB0:1, CNT: 0.096 s
.db 0b00010101, 0x00, 0x00, 0x18  ; define PB4:1, PB2:1, PB0:1, CNT: 0.096 s
.db 0b00010100, 0x00, 0x00, 0x18  ; define PB4:1, PB2:1, PB0:0, CNT: 0.096 s
.db 0b00010000, 0x00, 0x00, 0x18  ; define PB4:1, PB2:0, PB0:0, CNT: 0.096 s
.db 0b00000000, 0x00, 0x00, 0x00  ; define PB4:0, PB2:0, PB0:0
