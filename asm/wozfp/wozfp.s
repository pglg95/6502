;           JULY 5, 1976
;     BASIC FLOATING POINT ROUTINES
;       FOR 6502 MICROPROCESSOR
;       BY R. RANKIN AND S. WOZNIAK
;
;     CONSISTING OF:
;        NATURAL LOG
;        COMMON LOG
;        EXPONENTIAL (E**X)
;        FLOAT      FIX
;        FADD       FSUB
;        FMUL       FDIV
;
;
;     FLOATING POINT REPRESENTATION (4-BYTES)
;                    EXPONENT BYTE 1
;                    MANTISSA BYTES 2-4
;
;     MANTISSA:    TWO'S COMPLIMENT REPRESENTATION WITH SIGN IN
;       MSB OF HIGH-ORDER BYTE.  MANTISSA IS NORMALIZED WITH AN
;       ASSUMED DECIMAL POINT BETWEEN BITS 5 AND 6 OF THE HIGH-ORDER
;       BYTE.  THUS THE MANTISSA IS IN THE RANGE 1. TO 2. EXCEPT
;       WHEN THE NUMBER IS LESS THAN 2**(-128).
;
;     EXPONENT:    THE EXPONENT REPRESENTS POWERS OF TWO.  THE
;       REPRESENTATION IS 2'S COMPLIMENT EXCEPT THAT THE SIGN
;       BIT (BIT 7) IS COMPLIMENTED.  THIS ALLOWS DIRECT COMPARISON
;       OF EXPONENTS FOR SIZE SINCE THEY ARE STORED IN INCREASING
;       NUMERICAL SEQUENCE RANGING FROM $00 (-128) TO $FF (+127)
;       ($ MEANS NUMBER IS HEXADECIMAL).
;
;     REPRESENTATION OF DECIMAL NUMBERS:    THE PRESENT FLOATING
;       POINT REPRESENTATION ALLOWS DECIMAL NUMBERS IN THE APPROXIMATE
;       RANGE OF 10**(-38) THROUGH 10**(38) WITH 6 TO 7 SIGNIFICANT
;       DIGITS.
;
;
       .org 3      ; SET BASE PAGE ADRESSES
       SIGN = *
       X2   = SIGN+1        ; EXPONENT 2
       M2   = X2+1          ; MANTISSA 2
       X1   = M2+3          ; EXPONENT 1
       M1   = X1+1          ; MANTISSA 1
       E    = M1+3          ; SCRATCH
       ZZ   = E+4
       T    = ZZ+4
       SEXP = T+4
       INT  = SEXP+4
;
       .org $1D00   ; STARTING LOCATION FOR LOG
;
;
;     NATURAL LOG OF MANT/EXP1 WITH RESULT IN MANT/EXP1
;
LOG:    LDA M1
        BEQ ERROR
        BPL CONT    ; IF ARG>0 OK
ERROR:  BRK         ; ERROR ARG<=0
;
CONT:  JSR SWAP    ; MOVE ARG TO EXP/MANT2
       LDX #0      ; LOAD X FOR HIGH BYTE OF EXPONENT
       LDA X2      ; HOLD EXPONENT
       LDY #$80
       STY X2      ; SET EXPONENT 2 TO 0 ($80)
       EOR #$80    ; COMPLIMENT SIGN BIT OF ORIGINAL EXPONENT
       STA M1+1    ; SET EXPONENT INTO MANTISSA 1 FOR FLOAT
       BPL *+3     ; IS EXPONENT NEGATIVE
       DEX         ; YES, SET X TO $FF
       STX M1      ; SET UPPER BYTE OF EXPONENT
       JSR FLOAT   ; CONVERT TO FLOATING POINT
       LDX #3      ; 4 BYTE TRANSFERS
SEXP1: LDA X2,X
       STA ZZ,X    ; COPY MANTISSA TO Z
       LDA X1,X
       STA SEXP,X  ; SAVE EXPONENT IN SEXP
       LDA R22,X   ; LOAD EXP/MANT1 WITH SQRT(2)
       STA X1,X
       DEX
       BPL SEXP1
       JSR FSUB    ; Z-SQRT(2)
       LDX #3      ; 4 BYTE TRANSFER
SAVET: LDA X1,X    ; SAVE EXP/MANT1 AS T
       STA T,X
       LDA ZZ,X    ; LOAD EXP/MANT1 WITH Z
       STA X1,X
       LDA R22,X   ; LOAD EXP/MANT2 WITH SQRT(2)
       STA X2,X
       DEX
       BPL SAVET
       JSR FADD    ; Z+SQRT(2)
       LDX #3      ; 4 BYTE TRANSFER
TM2:   LDA T,X
       STA X2,X    ; LOAD T INTO EXP/MANT2
       DEX
       BPL TM2
       JSR FDIV    ; T=(Z-SQRT(2))/(Z+SQRT(2))
       LDX #3      ; 4 BYTE TRANSFER
MIT:   LDA X1,X
       STA T,X     ; COPY EXP/MANT1 TO T AND
       STA X2,X    ; LOAD EXP/MANT2 WITH T
       DEX
       BPL MIT
       JSR FMUL    ; T*T
       JSR SWAP    ; MOVE T*T TO EXP/MANT2
       LDX #3      ; 4 BYTE TRANSFER
MIC:   LDA C,X
       STA X1,X    ; LOAD EXP/MANT1 WITH C
       DEX
       BPL MIC
       JSR FSUB    ; T*T-C
       LDX #3      ; 4 BYTE TRANSFER
M2MB:  LDA MB,X
       STA X2,X    ; LOAD EXP/MANT2 WITH MB
       DEX
       BPL M2MB
       JSR FDIV    ; MB/(T*T-C)
       LDX #3
M2A1:  LDA A1,X
       STA X2,X    ; LOAD EXP/MANT2 WITH A1
       DEX
       BPL M2A1
       JSR FADD    ; MB/(T*T-C)+A1
       LDX #3      ; 4 BYTE TRANSFER
M2T:   LDA T,X
       STA X2,X    ; LOAD EXP/MANT2 WITH T
       DEX
       BPL M2T
       JSR FMUL    ; (MB/(T*T-C)+A1)*T
       LDX #3      ; 4 BYTE TRANSFER
M2MHL: LDA MHLF,X
       STA X2,X    ; LOAD EXP/MANT2 WITH MHLF (.5)
       DEX
       BPL M2MHL
       JSR FADD    ; +.5
       LDX #3      ; 4 BYTE TRANSFER
LDEXP: LDA SEXP,X
       STA X2,X    ; LOAD EXP/MANT2 WITH ORIGINAL EXPONENT
       DEX
       BPL LDEXP
       JSR FADD    ; +EXPN
       LDX #3      ; 4 BYTE TRANSFER
MLE2:  LDA LE2,X
       STA X2,X    ; LOAD EXP/MANT2 WITH LN(2)
       DEX
       BPL MLE2
       JSR FMUL    ; *LN(2)
       RTS         ; RETURN RESULT IN MANT/EXP1
;
;     COMMON LOG OF MANT/EXP1 RESULT IN MANT/EXP1
;
LOG10: JSR LOG     ; COMPUTE NATURAL LOG
       LDX #3
L10:   LDA LN10,X
       STA X2,X    ; LOAD EXP/MANT2 WITH 1/LN(10)
       DEX
       BPL L10
       JSR FMUL    ; LOG10(X)=LN(X)/LN(10)
       RTS
;
LN10:  .byte $7E, $6F, $2D, $ED ; 0.4342945

R22:   .byte $80, $5A, $02, $7A ; 1.4142136 SQRT(2)

LE2:   .byte $7F, $58, $B9, $0C ; 0.69314718 LOG BASE E OF 2

A1:    .byte $80, $52, $80, 40 ; 1.2920074

MB:    .byte $81, $AB, $86, $49 ; -2.6398577

C:     .byte $80, $6A, $08, $66 ; 1.6567626

MHLF:  .byte $7F, $40, $00, $00 ; 0.5

;
       .res $1e00-*
       .org $1E00   ; STARTING LOCATION FOR EXP
;
;     EXP OF MANT/EXP1 RESULT IN MANT/EXP1
;
EXP:   LDX #3      ; 4 BYTE TRANSFER
       LDA L2E,X
       STA X2,X    ; LOAD EXP/MANT2 WITH LOG BASE 2 OF E
       DEX
       BPL EXP+2
       JSR FMUL    ; LOG2(3)*X
       LDX #3      ; 4 BYTE TRANSFER
FSA:   LDA X1,X
       STA ZZ,X    ; STORE EXP/MANT1 IN Z
       DEX
       BPL FSA     ; SAVE Z=LN(2)*X
       JSR FIX     ; CONVERT CONTENTS OF EXP/MANT1 TO AN INTEGER
       LDA M1+1
       STA INT     ; SAVE RESULT AS INT
       SEC         ; SET CARRY FOR SUBTRACTION
       SBC #124    ; INT-124
       LDA M1
       SBC #0
       BPL OVFLW   ; OVERFLOW INT>=124
       CLC         ; CLEAR CARRY FOR ADD
       LDA M1+1
       ADC #120    ; ADD 120 TO INT
       LDA M1
       ADC #0
       BPL CONTIN  ; IF RESULT POSITIVE CONTINUE
       LDA #0      ; INT<-120 SET RESULT TO ZERO AND RETURN
       LDX #3      ; 4 BYTE MOVE
ZERO:  STA X1,X    ; SET EXP/MANT1 TO ZERO
       DEX
       BPL ZERO
       RTS         ; RETURN
;
OVFLW: BRK         ; OVERFLOW
;
CONTIN: JSR FLOAT   ; FLOAT INT
       LDX #3
ENTD:  LDA ZZ,X
       STA X2,X    ; LOAD EXP/MANT2 WITH Z
       DEX
       BPL ENTD
       JSR FSUB    ; Z*Z-FLOAT(INT)
       LDX #3      ; 4 BYTE MOVE
ZSAV:  LDA X1,X
       STA ZZ,X    ; SAVE EXP/MANT1 IN Z
       STA X2,X    ; COPY EXP/MANT1 TO EXP/MANT2
       DEX
       BPL ZSAV
       JSR FMUL    ; Z*Z
       LDX #3      ; 4 BYTE MOVE
LA2:   LDA A2,X
       STA X2,X    ; LOAD EXP/MANT2 WITH A2
       LDA X1,X
       STA SEXP,X  ; SAVE EXP/MANT1 AS SEXP
       DEX
       BPL LA2
       JSR FADD    ; Z*Z+A2
       LDX #3      ; 4 BYTE MOVE
LB2:   LDA B2,X
       STA X2,X    ; LOAD EXP/MANT2 WITH B2
       DEX
       BPL LB2
       JSR FDIV    ; T=B/(Z*Z+A2)
       LDX #3      ; 4 BYTE MOVE
DLOAD: LDA X1,X
       STA T,X     ; SAVE EXP/MANT1 AS T
       LDA C2,X
       STA X1,X    ; LOAD EXP/MANT1 WITH C2
       LDA SEXP,X
       STA X2,X    ; LOAD EXP/MANT2 WITH SEXP
       DEX
       BPL DLOAD
       JSR FMUL    ; Z*Z*C2
       JSR SWAP    ; MOVE EXP/MANT1 TO EXP/MANT2
       LDX #3      ; 4 BYTE TRANSFER
LTMP:  LDA T,X
       STA X1,X    ; LOAD EXP/MANT1 WITH T
       DEX
       BPL LTMP
       JSR FSUB    ; C2*Z*Z-B2/(Z*Z+A2)
       LDX #3      ; 4 BYTE TRANSFER
LDD:   LDA D,X
       STA X2,X    ; LOAD EXP/MANT2 WITH D
       DEX
       BPL LDD
       JSR FADD    ; D+C2*Z*Z-B2/(Z*Z+A2)
       JSR SWAP    ; MOVE EXP/MANT1 TO EXP/MANT2
       LDX #3      ; 4 BYTE TRANSFER
LFA:   LDA ZZ,X
       STA X1,X    ; LOAD EXP/MANT1 WITH Z
       DEX
       BPL LFA
       JSR FSUB    ; -Z+D+C2*Z*Z-B2/(Z*Z+A2)
       LDX #3      ; 4 BYTE TRANSFER
LF3:   LDA ZZ,X
       STA X2,X    ; LOAD EXP/MANT2 WITH Z
       DEX
       BPL LF3
       JSR FDIV    ; Z/(**** )
       LDX #3      ; 4 BYTE TRANSFER
LD12:  LDA MHLF,X
       STA X2,X    ; LOAD EXP/MANT2 WITH .5
       DEX
       BPL LD12
       JSR FADD    ; +Z/(***)+.5
       SEC         ; ADD INT TO EXPONENT WITH CARRY SET
       LDA INT     ; TO MULTIPLY BY
       ADC X1      ; 2**(INT+1)
       STA X1      ; RETURN RESULT TO EXPONENT
       RTS         ; RETURN ANS=(.5+Z/(-Z+D+C2*Z*Z-B2/(Z*Z+A2))*2**(INT+1)
L2E:   .byte $80, $5C, $55, $1E ; 1.4426950409 LOG BASE 2 OF E

A2:    .byte $86, $57, $6A, $E1 ; 87.417497202

B2:    .byte $89, $4D, $3F, $1D ; 617.9722695

C2:    .byte $7B, $46, $FA, $70 ; .03465735903

D:     .byte $83, $4F, $A3, $03 ; 9.9545957821

;
;
;     BASIC FLOATING POINT ROUTINES
;
       .res $1F00-*
       .org $1F00  ; START OF BASIC FLOATING POINT ROUTINES
ADD:   CLC         ; CLEAR CARRY
       LDX #$02    ; INDEX FOR 3-BYTE ADD
ADD1:  LDA M1,X
       ADC M2,X    ; ADD A BYTE OF MANT2 TO MANT1
       STA M1,X
       DEX         ; ADVANCE INDEX TO NEXT MORE SIGNIF.BYTE
       BPL ADD1    ; LOOP UNTIL DONE.
       RTS         ; RETURN
MD1:   ASL SIGN    ; CLEAR LSB OF SIGN
       JSR ABSWAP  ; ABS VAL OF MANT1, THEN SWAP MANT2
ABSWAP: BIT M1     ; MANT1 NEG?
       BPL ABSWP1  ; NO,SWAP WITH MANT2 AND RETURN
       JSR FCOMPL  ; YES, COMPLIMENT IT.
       INC SIGN    ; INCR SIGN, COMPLEMENTING LSB
ABSWP1: SEC        ; SET CARRY FOR RETURN TO MUL/DIV
;
;     SWAP EXP/MANT1 WITH EXP/MANT2
;
SWAP:  LDX #$04    ; INDEX FOR 4-BYTE SWAP.
SWAP1: STY E-1,X
       LDA X1-1,X  ; SWAP A BYTE OF EXP/MANT1 WITH
       LDY X2-1,X  ; EXP/MANT2 AND LEAVEA COPY OF
       STY X1-1,X  ; MANT1 IN E(3BYTES). E+3 USED.
       STA X2-1,X
       DEX         ; ADVANCE INDEX TO NEXT BYTE
       BNE SWAP1   ; LOOP UNTIL DONE.
       RTS
;
;
;
;     CONVERT 16 BIT INTEGER IN M1(HIGH) AND M1+1(LOW) TO F.P.
;     RESULT IN EXP/MANT1.  EXP/MANT2 UNEFFECTED
;
;
FLOAT: LDA #$8E
       STA X1      ; SET EXPN TO 14 DEC
       LDA #0      ; CLEAR LOW ORDER BYTE
       STA M1+2
       BEQ NORM    ; NORMALIZE RESULT
NORM1: DEC X1      ; DECREMENT EXP1
       ASL M1+2
       ROL M1+1    ; SHIFT MANT1 (3 BYTES) LEFT
       ROL M1
NORM:  LDA M1      ; HIGH ORDER MANT1 BYTE
       ASL         ; UPPER TWO BITS UNEQUAL?
       EOR M1
       BMI RTS1    ; YES,RETURN WITH MANT1 NORMALIZED
       LDA X1      ; EXP1 ZERO?
       BNE NORM1   ; NO, CONTINUE NORMALIZING
RTS1:  RTS         ; RETURN
;
;
;     EXP/MANT2-EXP/MANT1 RESULT IN EXP/MANT1
;
FSUB:  JSR FCOMPL  ; CMPL MANT1 CLEARS CARRY UNLESS ZERO
SWPALG: JSR ALGNSW ; RIGHT SHIFT MANT1 OR SWAP WITH MANT2 ON CARRY
;
;     ADD EXP/MANT1 AND EXP/MANT2 RESULT IN EXP/MANT1
;
FADD:  LDA X2
       CMP X1      ; COMPARE EXP1 WITH EXP2
       BNE SWPALG  ; IF UNEQUAL, SWAP ADDENDS OR ALIGN MANTISSAS
       JSR ADD     ; ADD ALIGNED MANTISSAS
ADDEND: BVC NORM   ; NO OVERFLOW, NORMALIZE RESULTS
       BVS RTLOG   ; OV: SHIFT MANT1 RIGHT. NOTE CARRY IS CORRECT SIGN
ALGNSW: BCC SWAP   ; SWAP IF CARRY CLEAR, ELSE SHIFT RIGHT ARITH.
RTAR:  LDA M1      ; SIGN OF MANT1 INTO CARRY FOR
       ASL         ; RIGHT ARITH SHIFT
RTLOG: INC X1      ; INCR EXP1 TO COMPENSATE FOR RT SHIFT
       BEQ OVFL    ; EXP1 OUT OF RANGE.
RTLOG1: LDX #$FA   ; INDEX FOR 6 BYTE RIGHT SHIFT
ROR1:  LDA #$80
       BCS ROR2
       ASL
ROR2:  LSR E+3,X   ; SIMULATE ROR E+3,X
       ORA E+3,X
       STA E+3,X
       INX         ; NEXT BYTE OF SHIFT
       BNE ROR1    ; LOOP UNTIL DONE
       RTS         ; RETURN
;
;
;     EXP/MANT1 X EXP/MANT2 RESULT IN EXP/MANT1
;
FMUL:  JSR MD1     ; ABS. VAL OF MANT1, MANT2
       ADC X1      ; ADD EXP1 TO EXP2 FOR PRODUCT EXPONENT
       JSR MD2     ; CHECK PRODUCT EXP AND PREPARE FOR MUL
       CLC         ; CLEAR CARRY
MUL1:  JSR RTLOG1  ; MANT1 AND E RIGHT.(PRODUCT AND MPLIER)
       BCC MUL2    ; IF CARRY CLEAR, SKIP PARTIAL PRODUCT
       JSR ADD     ; ADD MULTIPLICAN TO PRODUCT
MUL2:  DEY         ; NEXT MUL ITERATION
       BPL MUL1    ; LOOP UNTIL DONE
MDEND: LSR SIGN    ; TEST SIGN (EVEN/ODD)
NORMX: BCC NORM    ; IF EXEN, NORMALIZE PRODUCT, ELSE COMPLEMENT
FCOMPL: SEC        ; SET CARRY FOR SUBTRACT
       LDX #$03    ; INDEX FOR 3 BYTE SUBTRACTION
COMPL1: LDA #$00   ; CLEAR A
       SBC X1,X    ; SUBTRACT BYTE OF EXP1
       STA X1,X    ; RESTORE IT
       DEX         ; NEXT MORE SIGNIFICANT BYTE
       BNE COMPL1  ; LOOP UNTIL DONE
       BEQ ADDEND  ; NORMALIZE (OR SHIFT RIGHT IF OVERFLOW)
;
;
;     EXP/MANT2 / EXP/MANT1 RESULT IN EXP/MANT1
;
FDIV:  JSR MD1     ; TAKE ABS VAL OF MANT1, MANT2
       SBC X1      ; SUBTRACT EXP1 FROM EXP2
       JSR MD2     ; SAVE AS QUOTIENT EXP
DIV1:  SEC         ; SET CARRY FOR SUBTRACT
       LDX #$02    ; INDEX FOR 3-BYTE INSTRUCTION
DIV2:  LDA M2,X
       SBC E,X     ; SUBTRACT A BYTE OF E FROM MANT2
       PHA         ; SAVE ON STACK
       DEX         ; NEXT MORE SIGNIF BYTE
       BPL DIV2    ; LOOP UNTIL DONE
       LDX #$FD    ; INDEX FOR 3-BYTE CONDITIONAL MOVE
DIV3:  PLA         ; PULL A BYTE OF DIFFERENCE OFF STACK
       BCC DIV4    ; IF MANT2<E THEN DONT RESTORE MANT2
       STA M2+3,X
DIV4:  INX         ; NEXT LESS SIGNIF BYTE
       BNE DIV3    ; LOOP UNTIL DONE
       ROL M1+2
       ROL M1+1    ; ROLL QUOTIENT LEFT, CARRY INTO LSB
       ROL M1
       ASL M2+2
       ROL M2+1    ; SHIFT DIVIDEND LEFT
       ROL M2
       BCS OVFL    ; OVERFLOW IS DUE TO UNNORMALIZED DIVISOR
       DEY         ; NEXT DIVIDE ITERATION
       BNE DIV1    ; LOOP UNTIL DONE 23 ITERATIONS
       BEQ MDEND   ; NORMALIZE QUOTIENT AND CORRECT SIGN
MD2:   STX M1+2
       STX M1+1    ; CLR MANT1 (3 BYTES) FOR MUL/DIV
       STX M1
       BCS OVCHK   ; IF EXP CALC SET CARRY, CHECK FOR OVFL
       BMI MD3     ; IF NEG NO UNDERFLOW
       PLA         ; POP ONE
       PLA         ; RETURN LEVEL
       BCC NORMX   ; CLEAR X1 AND RETURN
MD3:   EOR #$80    ; COMPLIMENT SIGN BIT OF EXP
       STA X1      ; STORE IT
       LDY #$17    ; COUNT FOR 24 MUL OR 23 DIV ITERATIONS
       RTS         ; RETURN
OVCHK: BPL MD3     ; IF POS EXP THEN NO OVERFLOW
OVFL:  BRK
;
;
;     CONVERT EXP/MANT1 TO INTEGER IN M1 (HIGH) AND M1+1(LOW)
;      EXP/MANT2 UNEFFECTED
;
       JSR RTAR    ; SHIFT MANT1 RT AND INCREMENT EXPNT
FIX:   LDA X1      ; CHECK EXPONENT
       CMP #$8E    ; IS EXPONENT 14?
       BNE FIX-3   ; NO, SHIFT
RTRN:  RTS         ; RETURN

