		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Timer Definition
STCTRL		EQU		0xE000E010		; SysTick Control and Status Register
STRELOAD	EQU		0xE000E014		; SysTick Reload Value Register
STCURRENT	EQU		0xE000E018		; SysTick Current Value Register
	
STCTRL_STOP	EQU		0x00000004		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 0, Bit 0 (ENABLE) = 0
STCTRL_GO	EQU		0x00000007		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 1, Bit 0 (ENABLE) = 1
STRELOAD_MX	EQU		0x00FFFFFF		; MAX Value = 1/16MHz * 16M = 1 second
STCURR_CLR	EQU		0x00000000		; Clear STCURRENT and STCTRL.COUNT	
SIGALRM		EQU		14				; sig alarm

; System Variables
SECOND_LEFT	EQU		0x20007B80		; Secounds left for alarm( )
USR_HANDLER     EQU		0x20007B84		; Address of a user-given signal handler function	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer initialization
; void timer_init( )
		EXPORT		_timer_init
_timer_init
	;; Implement by yourself
		LDR 	R0, =STCTRL
		LDR 	R1, =STCTRL_STOP
		STR 	R1, [R0] ;Set current control and status to inactive/stop
		
		LDR 	R0, =STRELOAD
		LDR 	R1, =STRELOAD_MX
		STR 	R1, [R0] ;Load max time(?I think?) that the alarm runs for? 
	
		MOV		pc, lr		; return to Reset_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer start
; int timer_start( int seconds )
		EXPORT		_timer_start
_timer_start
	;; Implement by yourself
		MOV 	R1, R0 ;Copy R0
		LDR 	R2, =SECOND_LEFT ;Retrieve seconds left		
		LDR 	R0, [R2] ;copy seconds left to R0 for return
		STR 	R1, [R2] ;Store new time to seconds left.
		
		LDR 	R1, =STCTRL ;Retrieve control register values
		LDR 	R2, =STCTRL_GO ;Retrieve activation bit value things
		STR 	R2, [R1] ;Enable SysTick
		
		LDR 	R1, =STCURRENT ;Retrieve cur value register
		LDR 	R2, =STCURR_CLR ;Retrieve clear value of 0x00000000
		STR 	R2, [R1] ;Clear STCURRENT
		
		MOV 	R11, R0 ;Store seconds left in R11 since R0-3 and 12 get reset on return
		MOV		pc, lr		; return to SVC_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void timer_update( )
		EXPORT		_timer_update
_timer_update
	;; Implement by yourself
		;Read SECOND_LEFT
		;Decrement seconds by 1, save back into second left
		;If new value not 0, branch to _timer_update_done
		;otherwise,
		;Stop timer with STCTRL_STOP		
		;invoke user function at USR_HANDLER
		PUSH 	{lr}

		LDR 	R0, =SECOND_LEFT
		LDR 	R1, [R0]
		SUB 	R1, #1
		STR 	R1, [R0] ;Decrement and store seconds left
		
		CMP 	R1, #0 ;Check if timer is done
		BGT 	_timer_update_done
		LDR 	R0, =STCTRL_STOP
		LDR 	R1, =STCTRL
		STR 	R0, [R1] ;Stop timer
		
		LDR 	R0, =USR_HANDLER
		LDR 	R1, [R0]
		BLX 	R1 ;Invoke user function
		
_timer_update_done
		POP 	{lr}
		MOV		pc, lr		; return to SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void* signal_handler( int signum, void* handler )
	    EXPORT	_signal_handler
_signal_handler
	;; Implement by yourself
	
		LDR 	R2, =SIGALRM ;Retrieve alarm signal value, 14
		CMP 	R0, R2 ;If R0 is alarm, branch
		BEQ 	update_handler
	
return
		MOV 	R11, R0
		MOV		pc, lr		; return to Reset_Handler
		
update_handler
		LDR 	R2, =USR_HANDLER ;Load handler address
		LDR 	R0, [R2] ;Copy previous handler value to R0 for return
		STR 	R1, [R2] ;Store new handler
		B 		return
		
		END		
