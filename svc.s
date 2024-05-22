		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
SYSTEMCALLTBL	EQU		0x20007B00 ; originally 0x20007500
SYS_EXIT		EQU		0x0		; address 20007B00
SYS_ALARM		EQU		0x1		; address 20007B04
SYS_SIGNAL		EQU		0x2		; address 20007B08
SYS_MALLOC		EQU		0x3		; address 20007B10
SYS_FREE		EQU		0x4		; address 20007B14

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Initialization
		EXPORT	_syscall_table_init
		IMPORT _kfree
		IMPORT _kalloc
		IMPORT _signal_handler
		IMPORT _timer_start
			
_syscall_table_init
	;; Implement by yourself	
		LDR R0, =SYSTEMCALLTBL ;Load location of table

		;LDR R1, =SYS_EXIT ;Not sure what to put here yet, justing using this temporaryilyyly
		LDR R1, =SYS_EXIT
		STR R1, [R0], #4
		
		LDR R1, =_timer_start ;Get address of function to be stored
		STR R1, [R0], #4 ;Store call address in table, increment by 4

		LDR R1, =_signal_handler
		STR R1, [R0], #4
		
		LDR R1, =_kalloc
		STR R1, [R0], #4	

		LDR R1, =_kfree
		STR R1, [R0], #4

		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Jump Routine
        EXPORT	_syscall_table_jump
_syscall_table_jump
	;; Implement by yourself
		PUSH 	{lr} ;Save original registers in stack 
		
		LDR R2, =SYSTEMCALLTBL 		;Get address of table. Use Reg 2 as 0 and 1 are used for arguments.
		LDR R3, [R2, R7, LSL #2]   	; Each entry is 4 bytes. Multiply R7 by 2^2 (4) to get offset for address location
		BLX R3 						;Jump to function

sys_exit
		POP 	{lr}
		MOV		pc, lr	
		END


		
