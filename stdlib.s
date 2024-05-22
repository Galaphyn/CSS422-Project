		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
		EXPORT	_bzero
_bzero
		PUSH 	{R0-R11, lr} 	;Save registers in stack to follow APCS
		MOV	 	R2, #0 
loop
		CMP 	R1, #0
		BLE 	bend 			;If n = 0, end
		STR 	R2, [R0], #1	;Replace cur byte with 0
		SUB 	R1, R1, #1		;Decrement R1
		B loop
		
bend
		POP 	{R0-R11, lr} ;Restore registers
		MOV		pc, lr	;return
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncpy( char* dest, char* src, int size )
; Parameters
;   	dest 	- pointer to the buffer to copy to
;	src	- pointer to the zero-terminated string to copy from
;	size	- a total of n bytes
; Return value
;   dest

        EXPORT    _strncpy
_strncpy
        ; implement your complete logic, including stack operations    
        PUSH    {R0-R11, lr}	;Save registers in stack  

copy_loop
        CMP     R2, #0
        BEQ     copy_end     ;If size equal 0, end. BLE
        LDR    	R3, [R1], #1    ;Load byte from address R1 to R3, then increment R1 by 1
        STRB    R3, [R0], #1    ;Store byte from R3 to address R0, then increment R0 by 1
        SUB     R2, R2, #1      ; Decrement size
        B       copy_loop
        
copy_end
		POP     {R0-R11, lr}	;Save registers in stack  
        MOV     pc, lr           
		
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _malloc( int size )
; Parameters
;	size	- #bytes to allocate
; Return value
;   	void*	a pointer to the allocated space
		EXPORT	_malloc
_malloc
		; save registers
		PUSH 	{R4-R10, lr} ;Save registers in stack 
		
		MOV 	R7, #0x3 ;Store call numer
		SVC 	    #0x0 ;Call svc handler
		
		; resume registers
		POP 	{R4-R10, lr}
		MOV     R0, R11 ;Bring back our return address since R0 resets on return from svc
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _free( void* addr )
; Parameters
;	size	- the address of a space to deallocate
; Return value
;   	none
		EXPORT	_free
_free
		; save registers
		PUSH 	{R4-R11, lr} ;Save registers in stack 
		
		; set the system call # to R7
		MOV 	R7, #0x4
		SVC 	    #0x0

		; resume registers
		POP 	{R4-R11, lr} ;Restore registers
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; unsigned int _alarm( unsigned int seconds )
; Parameters
;   seconds - seconds when a SIGALRM signal should be delivered to the calling program	
; Return value
;   unsigned int - the number of seconds remaining until any previously scheduled alarm
;                  was due to be delivered, or zero if there was no previously schedul-
;                  ed alarm. 
		EXPORT	_alarm
_alarm
		; save registers
		PUSH 	{R4-R10, lr} ;Save registers in stack 

		; set the system call # to R7
		MOV 	R7, #0x1
		SVC     	#0x0
		
		; resume registers
		POP 	{R4-R10, lr} ;Restore registers
		MOV		R0, R11 ;return int
		MOV		pc, lr
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _signal( int signum, void *handler )
; Parameters
;   signum - a signal number (assumed to be 14 = SIGALRM)
;   handler - a pointer to a user-level signal handling function
; Return value
;   void*   - a pointer to the user-level signal handling function previously handled
;             (the same as the 2nd parameter in this project)
		EXPORT	_signal
_signal
		; save registers
		PUSH 	{R4-R10, lr} ;Save registers in stack 

		; set the system call # to R7
		MOV 	R7, #0x2
		SVC     	#0x0
		
		; resume registers
		POP 	{R4-R10, lr} ;Restore registers
		MOV 	R0, R11 ;Return pointer
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		END			
