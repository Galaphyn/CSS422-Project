		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      	; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512			; 2^9 = 512 entries
	
INVALID		EQU		-1			; an invalid id
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
		EXPORT	_heap_init
_heap_init
	;; Implement by yourself
		PUSH	{R0-R2}
	
		LDR		R0, =MCB_TOP		;Top of block
		LDR		R1, =MCB_BOT		;Bottom of Block
		MOV		R2, #0x00004000		;Max allocation
		STR		R2, [R0], #4		;Set Top of block to max size to indicate available, increment by 4
		MOV		R2, #0
		
_start_loop
		CMP		R0, R1			
		BHI		_end_loop		;If R0 > R1, end loop
		STR		R2, [R0], #4    ;Set memory to 0
		B		_start_loop		;Loop
		
_end_loop		
		POP		{R0-R2}
		MOV		PC, LR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
; a1 is size
; r1 address space in memory, not mcb
		EXPORT	_kalloc
_kalloc
	;; Implement by yourself
	;R0 = Size of allocation, and return of address
	;R1 = MCB_TOP
	;R2 = MCB_BOT
	;R3 = blockSize
	;R4 = Middle address for start of right half
	;R5 = Left index
	;R6 = Right index
	;R7+ = General registers for various usages
	
		PUSH	{LR} ;Store return address
		
		;If size < min_size, size = min_size
		LDR 	R7, =MIN_SIZE
		CMP 	R7, R0
		BHI		set_size
		
		;Check if size is power of 2, else fix it
		SUB R7, R0, #1
		AND R7, R0, R7
		CMP R7, #0
		BEQ prepare_for_ralloc
		MOV R7, #1
		
find_power
		CMP R7, R0
		BHI set_size
		LSL R7, #1 ; *2^1
		B find_power
		
set_size
		MOV R0, R7
		
prepare_for_ralloc
		LDR		R1, =MCB_TOP ;Get Top of mem block
		LDR		R2, =MCB_BOT ;Get Bottom of mem block
		BL		_ralloc		 ;Call recursive func
		
		POP		{LR}
		MOV		PC, LR
		
_ralloc
		PUSH 	{LR}
		
		;blockSize = (right - left + mcb_ent_sz) * 16
		LDR		R3, =MCB_ENT_SZ
		ADD		R3, R2, R3
		SUB		R3, R1
		LSL		R3, #4	
		
		;middle = Left + ((right - left + mcb_ent_sz) / 2) 
		LDR		R4, =MCB_ENT_SZ
		ADD		R4, R2, R4
		SUB		R4, R1
		LSR		R4, #1	
		ADD		R4, R1
		
		;array[leftIndex]
		LDRH	R5, [R1]	;Loads halfword containing size and if in use
		;array[middleIndex]
		LDRH	R6, [R4]
		
		;If size > blockSize/2
		LSR		R7, R3, #1 
		CMP		R0, R7
		BLS		enough_space
		
		;;For chunks larger than half the max size
		;And if array[leftIndex]%2 == 0
		AND 	R7, R5, #1
		CMP		R7, #0
		BNE		set_invalid
		;And if	
		;array[leftIndex] >= size
		CMP		R5, R0
		BLO		set_invalid
		
		;array[leftIndex] = searchSize + 1
		MOV		R5, R3
		ADD		R5, R5, #1
		STRH	R5, [R1]
				
		;((left - mcb_top) * 16) + heap_top
		LDR		R0, =MCB_TOP
		SUB		R0, R1, R0		;Left(R1) - top(R0)
		LSL		R0, R0, #4	
		LDR		R7, =HEAP_TOP
		ADD		R0, R0, R7
		B		ralloc_return
	
enough_space
		;Array[middleIndex] == 0
		CMP		R6, #0
		BNE		check_block
		
		;Array[middleIndex] = blockSize / 2
		LSR		R7, R3, #1
		STRH	R7, [R4]
		MOV		R6, R3
		
check_block
		;size > blockSize/4
		LSR		R7, R3, #2
		CMP		R0, R7
		BLS		cut_in_half
		
		;array[leftIndex]%2 == 0
		AND 	R7, R5, #1
		CMP		R7, #0
		BNE		check_middle
				
		;array[leftIndex] >= size
		CMP		R5, R0
		BLO		set_invalid
				
		;array[leftIndex] == (blockSize/2) + 1
		LSR		R7, R3, #1
		MOV		R5, R7
		ADD		R5, R5, #1
		STRH	R5, [R1]
				
		;Return ((left - mcb_top) * 16) + heap_top
		LDR		R0, =MCB_TOP
		SUB		R0, R1, R0
		LSL		R0, R0, #4		
		PUSH	{R1}
		LDR		R1, =HEAP_TOP
		ADD		R0, R0, R1
		MOV 	R11, R0
		POP		{R1}
		B		ralloc_return
				
check_middle
				
		;X array[leftIndex] > size + 1
		ADD		R7, R0, #1
		CMP		R5, R7
		BHI		set_invalid
				
		;array[middleIndex] % 2 == 0
		AND		R7, R6, #1
		CMP		R7, #0
		BNE		set_invalid
				
		; array[middleIndex] >= size
		CMP		R6, R0
		BLO		set_invalid
				
		; array[middleIndex] = (blockSize/2) + 1
		LSR		R7, R3, #1
		MOV		R6, R7
		ADD		R6, R6, #1
		STRH	R6, [R4]
				
		; Return ((middle - mcb_top) * 16) + heap_top
		LDR		R0, =MCB_TOP
		SUB		R0, R4, R0
		LSL		R0, R0, #4		
		PUSH		{R1}
		LDR		R1, =HEAP_TOP
		ADD		R0, R0, R1
		MOV 	R11, R0
		POP		{R1}
		B		ralloc_return
	
cut_in_half		

		;Go left if NOT odd and array[left] >= blockSize/2
		;array[leftIndex]%2 == 0
		AND		R7, R5, #1
		CMP		R7, #0
		BEQ		go_left
		
		;array[leftIndex] >= blockSize/2
		LSR		R7, R3, #1
		CMP		R5, R7
		BHS		check_right

go_left
		;_ralloc(size (R0), left(R1), (R2) middle - mcb_ent_sz)
		PUSH	{R0-R6, LR}
		LDR		R3, =MCB_ENT_SZ
		SUB		R2, R4, R3
		BL		_ralloc
		MOV		R11, R0
		POP		{R0-R6, LR}
		
		; return was NOT invalid
		LDR R7, =INVALID
		CMP		R11, R7	; R10 stores temporary return value
		BNE		ralloc_valid

check_right
		;Go right if array[left] < blockSize
		;array[middle] is even and >= blockSize/2
		
		; array[left] >= searchSize, end
		CMP		R5, R3
		BHS		ralloc_return
		
		; array[middle]%2 == 0
		AND		R7, R6, #1
		CMP		R7, #0
		BEQ		go_right
		
		; array[middle] >= searchSize/2
		LSR		R7, R3, #1
		CMP		R6, R7
		BHS		set_invalid

go_right
		; _ralloc(size(R0), middle(R1), right(R2))
		PUSH	{R0-R6, LR}
		MOV		R1, R4
		BL		_ralloc
		MOV		R11, R0
		POP		{R0-R6, LR}
		
		LDR R7, =INVALID
		CMP		R11, R7	; R10 stores temporary return value
		BEQ		ralloc_return
		
ralloc_valid
		MOV		R0, R11
		B 		ralloc_return

set_invalid
		LDR		R0, =INVALID

ralloc_return
		POP		{LR}
		MOV		PC, LR
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void free( void *ptr )
; a1 pointer of memory to be deallocated (R0)
		EXPORT	_kfree
_kfree
	;; Implement by yourself
	;R0 = Target/MCB Address
	;R1 = Index/Data of MCB Address
	;R2 = Location of mem block
	;R3 = Size of memory in index
		PUSH	{LR}

		;If addr < HEAP_TOP return invalid
		LDR		R1, =HEAP_TOP
		CMP		R0, R1
		BLO		kfree_invalid
		
		;Or If addr > HEAP_BOT return invalid
		LDR		R1, =HEAP_BOT
		CMP		R0, R1
		BHI		kfree_invalid
		
		;mcb_addr = MCB_TOP + ((addr - HEAP_TOP) / 16)
		LDR		R1, =HEAP_TOP
		SUB		R0, R0, R1		
		LSR		R0, R0, #4 		
		LDR 	R1, =MCB_TOP
		ADD		R0, R0, R1
		
		BL		_rfree
		BL		kfree_return
	
kfree_invalid
		LDR		R0, =INVALID

kfree_return
		POP		{LR}
		MOV		PC, LR

; a1 is mcb address space to be deallocated
_rfree
		PUSH 	{LR}
		
		;index = array[mcb_addr]
		LDRH	R1, [R0]
		
		;If array[index] % 2 == 0, is already unusued, return
		AND		R4, R1, #1
		CMP		R4, #0
		BEQ		rfree_return
		
		;Decrement to mark as now empty
		SUB		R1, R1, #1
		STRH	R1, [R0]
		
		;Size = array[index] / 16
		LSR		R3, R1, #4
		
		;If ((mcb_addr - mcb_top)%(size * 2) == 0)
		LDR		R2, =MCB_TOP
		SUB		R2, R0, R2
		LSL 	R4, R3, #1
		UDIV 	R5, R2, R4  ; Divide R2 by R4, result is in R5
		MUL  	R6, R5, R4  ; Multiply R5 by R4, result is in R6
		SUB  	R5, R2, R6  ; Subtract R6 from R2, result is in R5
		CMP  	R5, #0      ; Compare R5 with 0
		BNE 	check_left_bud

		;And if index + size <= m2a(mcb_bot)
		ADD		R4, R0, R3 ;Use mem address being cleared (R0) instead of index for this case so no conversion needed
		LDR		R5, =MCB_BOT
		CMP		R4, R5
		BHI		rfree_return
		
		;And if array[index + size]%2 == 0
		LDRH	R5, [R4]
		AND 	R5, R5, #1
		CMP		R5, #0
		BNE 	rfree_return
		
		;Then
		MOV		R5, #0
		STRH	R5, [R4]
		LSL		R1, R1, #1
		ADD		R1, R1, #1
		STRH	R1, [R0]
		
		PUSH	{R0-R6}
		BL		_rfree
		POP		{R0-R6}
		B		rfree_return
		
check_left_bud
		;If index - size >= m2a(mcb_top)
		SUB		R5, R0, R3
		LDR		R6, =MCB_TOP
		CMP		R5, R6
		BLO		rfree_return
		
		;And if array[index - size]%2 == 0
		AND		R6, R5, #1
		CMP		R6, #0
		BNE 	rfree_return
		
		;And if array[index - size] == array[index]
		LDR		R6, [R5]
		CMP		R6, R1
		BNE		rfree_return
		
		;Array[index - size] = (array[index - size] * 2) + 1
		LSL		R6, R6, #1
		ADD		R6, R6, #1
		STRH	R6, [R5]
		
		;Array[index] = 0
		MOV		R1, #0
		STRH	R1, [R0]
		
		PUSH	{R0-R3}
		MOV		R0, R5
		BL		_rfree
		POP		{R0-R3}
		B		rfree_return
		
rfree_return
		POP		{LR}
		MOV		PC, LR
		
		END
