extern printf
extern fprintf
extern malloc
extern free
extern fgets
extern fgetc

extern stderr
extern stdin
extern stdout

section .bss
	buffer: resb 80                 ;
	operands: resb 20               ;    define an array of length 5 for storing operands.
    last_link: resb 4
    new_link: resb 4
    stack_pointer: resb 4
    last_operand: resb 4
    new_operand: resb 4


section .rodata
	debug: db "-d", 0, 0
	S0: db "%s", 0, 0
	D0: db "%d", 10, 0
	X0: db "%X", 10, 0
	XP: db "%X", 0, 0
	pre: db ">>", 0, 0
	string: db ">>calc:", 32, 0     ;   string of procedure
	error_overflow:  db ">>Error: Operand Stack Overflow", 10, 0   ;   error string
	error_insufficient:  db ">>Error: Insufficient Number of Arguments on Stack", 10, 0   ;   error string
	error_exponent: db ">>Error: exponent too large", 10, 0
	error_invalid_operator: db ">>Error: Invalid Operator", 10, 0
    emptyLine:  db "", 10, 0   ;   error string
    bye:  db "bye bye", 10, 0   ;   bye check string


section .data
	operators_count: dd 0           ;   count operators
	counter: dd     0               ;    counts operands
	link_val: dd 0
    c: dd 0
    K: dd 0
    N: dd 0
	res: db 0
	tmp: db 0
	len: db 0
    chk: dd 0
	check_ans: db 0
	stop_clean: db 0
    d_print: db 0
    sum: dd 0


section .text
	align 16
	global main
	global my_calc
	global stack_check
	global newlink
	global list_sum
	global print_link
    global check_debug
    global make_list_demical

%macro print 2
	    pushad                      ;   save registers
	    push %1                 ;   push string
	    push %2                     ;   push string format
	    call printf                 ;   print
	    add esp, 8                  ;   clean stack
	    popad                       ;   retore registers
%endmacro

%macro check 1
		pushad                      ;   save registers
        push %1                      ;   push check case
        call stack_check            ;   check
        add esp, 4                  ;   clean stack
        cmp eax, -1                 ;   check if result is error
        popad                       ;   restore registers
        je start
%endmacro


main:
	;	CHECK ARGUMENT "-d"
	
	mov esi, [esp+4]	;	put argc in esi
	cmp esi, 1			;	check if argc is 1
	je cont_main		;	if yes jump to cont_main
	mov esi, [esp+8]	;	else put argv in esi
	mov esi, [esi+4]	;	put the second arg in esi
	mov edi, debug		;	save "-d" in edi
	mov ecx, 2			;	set length to 2
	cld					;	
	repe cmpsb			;	compare strings
	jne cont_main		;	jump
	mov byte [d_print], 1;	if equal set d_print to 1
	
cont_main:
	mov ebp, esp  
    pushad                 ;   save the start of the function
	call my_calc                   ;   call the primary procedure
    popad
	print dword [operators_count], D0   ;   print main result
	ret                            ;   return


my_calc:
    mov byte [counter], 0           ; put zero in stack counter

	start:

        mov dword [last_link], 0    ;   new number, new linked list
		mov dword [res], 0

        print string, S0            ;   print ">>calc:"
        push dword [stdin]          ;   push stream
        push dword 80               ;   push max length
        push dword buffer           ;   push buffer
        call fgets                  ;   get input
        add esp, 12                 ;   clean stack


    operators_check:
        cmp byte [buffer+1], 'A'
        jae invalid_operator
        cmp byte [buffer], 'a'      ;   check quit
        je print_array              ;   jump
        cmp byte [buffer], 'q'      ;   check quit
        je exit                     ;   jump
        cmp byte [buffer], '+'      ;   check add
        je operate_add                      ;   jump
        cmp byte [buffer], 'p'      ;   check pop_and_print
        je pop_and_print            ;   jump
        cmp byte [buffer], 'd'      ;   check duplicate
        je duplicate                ;   jump
        cmp byte [buffer], 'r'      ;   check shift_right
        je shift_right              ;   jump
        cmp byte [buffer], 'l'      ;   check shift_left
        je shift_left               ;   jump
        cmp byte [buffer], 10       ;   check empty input
        je start
	
    remove_0:
            cmp byte [eax], '0'     
            jne numeric_input
            inc eax
            cmp byte [eax], '0'
            je remove_0
            dec eax
            jmp numeric_input

    numeric_input:
        check 5
        mov edx, 0                  ;   reset edx
        jmp first                   ;   jump

    first:                          ;   CHECK INPUT LENGTH
        cmp byte [eax], 10          ;   check if iterator is at the endd of the input
    	je endofstring              ;   if so, jump to correct case
    	inc eax                     ;   iterate the input
    	inc edx                     ;   increase input length by 1

    	jmp first                   ;   else do it again.

    invalid_operator:
		print error_invalid_operator, S0
		jmp start
; ---------------------------------------------------------------------------------------------------------------
;                                       HANDLE INPUT
;  EDX - string length ;   EAX - string pointer
; ---------------------------------------------------------------------------------------------------------------
    end_input:
        pushfd
        pushad
        push dword [d_print]
        call check_debug
        add esp, 4
        popad
        popfd
        jmp start


    endofstring:                    ;   WE RETURN TO HERE    
        cmp edx, 0                  ;   check if string length is 0
        je end_input                    ;   jump to get new input
    	cmp edx, 1                  ;   check if string is only one 1 digit
    	je oneDigit                 ;   jump to correct case

    break:                          ;   HANDLES TWO DIGITS OR MORE
        dec eax                     ;   decrease input pointer
        dec edx                     ;   decrease input length
        mov bl, [eax]               ;   save digit in bl
        sub bl, 48                  ;   get original value
        dec eax                     ;   decrease input pointer
        dec edx                     ;   decrease input length
        mov bh, [eax]               ;   save digit in bh
        sub bh, 48                  ;   get original value
        shl bh, 4                   ;   move bh to the left 4 bits
        mov byte [res], bh          ;   save bh in res
        add byte [res], bl          ;   add bl to the result
        jmp alloc                   ;   jump

    oneDigit:                       ;   HANDLES 1 DIGIT
        dec eax                     ;   decrease input pointer
        dec edx                     ;   decrease input length
        mov bl, [eax]               ;   save digit in bl
        sub bl, 48                  ;   get original value
        mov byte [res], bl          ;   save bl in res
        jmp alloc                   ;   jump to alloc

    alloc:                          ;   ALLOCATE  SPACE FOR NEW
        pushad                      ;   save registers
        call newlink                ;   malloc

        popad                       ;   restore registers

        jmp endofstring

    

;--------------------------------------------------------------------------------------------------------------------
;                                                   OPERATORS
;--------------------------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------------------------
;                                                     ADD
;---------------------------------------------------------------------------------------------------------------------
    operate_add:
        check 0
        check 1
        
        mov ecx, [counter]
        dec ecx
        mov edi, [operands +4*ecx]  ;   put last operand in edi
        dec ecx
        mov esi, [operands +4*ecx]  ;   put last operand in esi
        sub dword [counter], 2      ;   TODO CHECK IF NEED 1

	add:
			clc          ;   reset carry flag
			pushad       ;   save registers
			push edi     ;   push
			push esi     ;   push
			call list_sum;   call list sums
			add esp, 8   ;   clean stack
			popad        ;   restore registers
   

			jmp inc_count                ;   jump

;---------------------------------------------------------------------------------------------------------------------
;                                                 POP AND PRINT
;---------------------------------------------------------------------------------------------------------------------
    pop_and_print:
        check 0
        mov ecx, [counter]          ;   put counter inregister
        dec ecx                     ;   decrease ecx for getting the last operand
        mov edi, [operands +4*ecx]  ;   put last operand in edi

        pushad
        push edi
        call print_link
        add esp, 4
        popad
        dec dword [counter]
        inc byte [operators_count]
        jmp start                ;   jump

;---------------------------------------------------------------------------------------------------------------------
;                                               DUPLICATE
;---------------------------------------------------------------------------------------------------------------------
    duplicate:
        check 5                     ;   jump
        check 0                 ;   jump

        mov ecx, [counter]          ;   put counter in register
        dec ecx                     ;   decrease ecx for getting the last operand in the stack
        mov edi, [operands+4*ecx]   ;   put in edi the operand in the top of stack

	    pushad                      ;   save registers
        call newlink                ;   allocate space
        popad                       ;   clean stack
        mov esi, [new_link]         ;   put new link in register

        inc ecx
        mov [operands+4*ecx], esi   ;   put new link in the stack
        mov [last_operand], edi     ;   save last operand adress in a variable
        mov [new_operand], esi      ;   save new operand adress in a variable
        mov edi, [last_operand]     ;   put last operand adress in a register
        mov esi, [new_operand]      ;   put new operand adress in a register



    copy:
        mov bl, [edi]               ;   save value of last operand
        mov [esi], bl               ;   copy the last operand value to the new link first byte

        mov dword [esi+1], 0        ;   set new link next to 0
        cmp dword [edi+1], 0        ;   check if the link of last operand is the last link
        je inc_count                ;   jump

        mov edi, [edi+1]            ;   put in edi the next link in list

        pushad                      ;   save registers
        call newlink                ;   allocate
        mov [esi+1], eax            ;   put allocated space adress in new link next
        popad                       ;   restore registers

        mov esi, [esi+1]            ;   set esi to new allocated space adress
        jmp copy                    ;   jump

;---------------------------------------------------------------------------------------------------------------------
;                                                     SHIFT RIGHT
;---------------------------------------------------------------------------------------------------------------------
    shift_right:

            check 0                     ;   check that the stack is not empty
            check 1                     ;   check that there is more than one operand

	        mov ecx, [counter]          ;   put counter in ecx
	        dec ecx                     ;   decrease ecx
	        mov edx, [operands +4*ecx]  ;   put last operand in edi |       THIS IS K
	        mov eax, [edx]              ;   save link value in eax
	        mov [K], eax                ;   save link value in [K]
	        dec ecx                     ;   decrease ecx for getting next operand
	        mov esi, [operands +4*ecx]  ;   put last operand in esi |       THIS IS N
	        mov al, [esi]              ;   save link value in register
	        mov [N], al                ;   save link value in a variable N
            
            cmp dword [edx+1], 0        ;   check if k is greater than 99 (more than 1 link)
            jne print_error_exponent    ;   jump

            dec dword [counter]

            ;   MAKE N DEMICAL
            mov dword [chk], 0
            mov eax, 0                  ;   reset EAX           
            mov al, [N]                 ;   put k in al
            mov [chk], al
            cmp eax, 10                 ;   check if k is less than 10
            jb make_K_demical                   ;   if so, continue to square 
            and al, 240                 ;   else, save only high 4 bits
            shr al, 4                   ;   move the 4 bits to the right
            mov ebx, 10                 ;   multiply by 10
            mul ebx                     ;   ""
            mov ebx, 0                  ;   reset ebx
            mov bl, [N]                 ;   put k in bl
            and bl, 15                  ;   save only lower 4 bits
            add eax, ebx                ;   add al and bl (decimal value of k)

            mov [chk], al

        make_K_demical:
            ;   MAKE K DEMICAL
            mov ecx, 0
            mov eax, 0                  ;   reset EAX           
            mov al, [K]                 ;   put k in al
            mov edx, eax
            push edx

            mov ecx, edx
            cmp eax, 10                 ;   check if k is less than 10
            jb check_fracture
            and al, 240                 ;   else, save only high 4 bits
            shr al, 4                   ;   move the 4 bits to the right
            mov ebx, 10                 ;   multiply by 10
            mul ebx                     ;   ""
            mov ebx, 0                  ;   reset ebx
            mov bl, [K]                 ;   put k in bl
            and bl, 15                  ;   save only lower 4 bits
            
            add eax, ebx                ;   add al and bl (decimal value of k)
            pop edx
            mov edx, eax
            mov ecx, eax


        check_fracture:            ;   
            mov eax, 1
            mov ebx, 2
            cmp ecx, 0
            je pow0  
            jmp divide


        fracture:
            dec dword [counter]
            mov dword [res], 0
            pushad
            call newlink
            popad
            mov ecx, [counter]          ;   put counter in register
            dec ecx                     ;   decrease ecx for getting the last operand in the stack
            mov edi, [operands+4*ecx]   ;   put in edi the operand in the top of stack
            mov eax, 0
            mov al, [edi]
            jmp inc_count

        pow0:
            dec dword [counter]
            mov dword [res], 1
            pushad
            call newlink
            popad
            mov ecx, [counter]          ;   put counter in register
            dec ecx                     ;   decrease ecx for getting the last operand in the stack
            mov edi, [operands+4*ecx]   ;   put in edi the operand in the top of stack
            mov eax, 0
            mov al, [edi]

            jmp inc_count
            
        divide:
            mov dword [last_link], 0    ;   new number, new linked list 
            cmp edx, 0
            je end_Rshift
            dec dword [counter]
            mov eax, 0
            mov ebx, 0
            mov ecx, 0

            shift:
                mov al, [N]                 ;   put N in al
                mov bl, al                  ;    put N in bl
                mov cl, bl                  ;   put N in cl
                and cl, 16                  ;   check only fifth  
                mov dword [c], 1            ;   set c to zero
                and [c], al                 ;   check if fifth bit in al is on
                shr bl, 1                   ;   shift bl (high) right
                and bl, 240                 ;   check 4 high bits in bl
                and al, 15                  ;   check 4 low bits in al
                shr al, 1


                add al, bl
                cmp cl, 16
                jne checkHigh
                add al, 5

            checkHigh:
                cmp byte [c], 1
                jne updateN
                cmp byte [last_link], 0
                je updateN
                mov edi, [last_link]
                add byte [edi], 80

            updateN:                
                cmp al, 0
                jne add_link
                cmp dword [esi+1], 0
                je skip_link

            add_link:
                mov [res], al
                pushad
                call newlink
                popad
                cmp dword [esi+1], 0
                je skip_link

            nextShift:
                mov esi, [esi+1]
                mov eax, 0
                mov al, [esi]              ;   save link value in register
                mov [N], al                ;   save link value in a variable N
                jmp shift

            skip_link:
                dec edx
                mov ecx, [counter]          ;   put counter in ecx
                dec ecx
                mov esi, [operands +4*ecx]  ;   put last operand in edi |       THIS IS K

                mov eax, 0
                mov al, [esi]

                mov [N], al

                jmp divide

            end_Rshift:
                
                jmp inc_count

;---------------------------------------------------------------------------------------------------------------------
;                                                     SHIFT LEFT
;---------------------------------------------------------------------------------------------------------------------
    shift_left:
		check 0                     ;   check that the stack is not empty
        check 1                     ;   check that there is more than one operand

        mov ecx, [counter]          ;   put counter in ecx
        dec ecx                     ;   decrease ecx
        mov edx, [operands +4*ecx]  ;   put last operand in edi |       THIS IS K
        mov eax, [edx]              ;   save link value in eax
        
        mov [K], eax                ;   save link value in [K]
        dec ecx                     ;   decrease ecx for getting next operand
        mov ebx, [operands +4*ecx]  ;   put last operand in esi |       THIS IS N
        mov eax, [ebx]              ;   save link value in register
        mov [N], eax                ;   save link value in a variable N

		cmp dword [edx+1], 0        ;   check if k is greater than 99 (more than 1 link)
        jne print_error_exponent    ;   jump

		sub dword [counter], 1      ;   decrease stack counter by 1
        mov eax, 0                  ;   reset EAX
		mov al, [K]                 ;   put k in al
        cmp eax, 10                 ;   check if k is less than 10
        jb square                   ;   if so, continue to square 
        and al, 240                 ;   else, save only high 4 bits
        shr al, 4                   ;   move the 4 bits to the right
        mov ebx, 10                 ;   multiply by 10
        mul ebx                     ;   ""
        mov ebx, 0                  ;   reset ebx
        mov bl, [K]                 ;   put k in bl
        and bl, 15                  ;   save only lower 4 bits
        add eax, ebx                ;   add al and bl (decimal value of k)

    square:
            mov ebx, [operands +4*ecx]  ;   put last operand in esi |       THIS IS N
            cmp eax, 0
            je end_shift
        multiply:
            sub dword [counter], 1      ;   decrease stack counter by 1

            mov dword [last_link], 0    ;   new number, new linked list
            pushad
            push ebx
            push ebx
            call list_sum
            add esp, 8
            popad
            mov bl, [res]
            mov [N], bl
            dec eax
            jmp square
	;   ----------------------------------------------------------------------------------------------------------------
    end_shift:
        jmp inc_count




	print_error_exponent:
		print error_exponent, S0
		jmp start

    print_array:
        mov edx, [counter]
        dec edx
        mov esi, [operands+edx*4]
        mov eax, 0                  ;   sums the result
        mov ecx, 0                  ;   counter for links

    list_length:
		cmp byte [esi+ecx*4+1], 0
		je list_end
		inc ecx
		jmp list_length

    list_end:
		print bye, S0

    exit:
		ret             ;

	inc_count:
        inc dword [operators_count]          ;   increase counter
        pushfd
        pushad
        push dword [d_print]
        call check_debug
        add esp, 4
        popad
        popfd
        jmp start


;----------------------------------------------------------------------------------------------------------------------
;                                       FUNCTIONS
;----------------------------------------------------------------------------------------------------------------------
print_link:
		mov edi, [esp+4]
	    mov ecx, 0
    		forward:

                    mov ebx, 0                  ;   we put zero in ebx
                    mov bl, [edi]               ;   save the value of the current link in bl
                    push ebx                    ;   push value to processor stack
                    inc ecx                     ;   increase links counter
                    cmp dword [edi+1], 0        ;   check if current link is the last
            		je printit1                 ;  if so, jump to print


                    mov edi, [edi+1]            ;   update edi to the next link

                    jmp forward                 ;   jump

                printit1:
                    mov dword [c], ecx
                    print pre, S0

                printit2:
                    cmp dword [c], 0                  ;   check if links counter is 0
                    je end_pop_and_print        ;   if so jump to finish

                    pop eax
                    cmp eax, 10
                    jae over10
                    cmp dword [c], ecx
                    je over10
                    mov ebx, 0
                    print ebx, XP

                over10:
                    dec dword [c]                     ;   else decrease the counter
                    print eax, XP
                    jmp printit2                 ;   jump

                end_pop_and_print:
                    dec dword [c]                     ;   else decrease the counter
                    print emptyLine, S0
					ret


stack_check:
    mov ebx, [esp+4]            ;   get argument that we will compare the counter with (can be 5, 0, 1, 2)
    cmp [counter], ebx          ;   check case
    je stack_error              ;   if case, jump to error
    mov eax, 0                  ;   CHECK IS OK
	ret

	stack_error:
		cmp ebx, 0
		je insufficient
		cmp ebx, 1
		je insufficient
		cmp ebx, 99
		je tooBig
		jmp overflow ; 5

	tooBig:
		print error_exponent, S0
		mov eax, -1
        ret

    overflow:                           ; case eax = 6
        print error_overflow, S0
        mov eax, -1
		ret

	insufficient:
        print error_insufficient, S0
        mov eax, -1
        ret


newlink:                                ;   ALLOCATE  SPACE FOR NEW
	    pushad                      ;   save registers
	    push dword 5                ;   push size to allocate
	    call malloc                 ;   malloc
	    add esp, 4                  ;   clean stack
	    mov [new_link], eax         ;   we put the pointer to the malloc in newlink variable
	    popad
	    mov esi, [new_link]         ;   we put the adress of the malloc in esi
	    mov bl, [res]               ;   we put the result in a tmp byte

	    mov byte [esi], bl          ;   we put inside the malloc of newlink the result
	    mov dword [esi+1], 0        ;   set next to 0

	    cmp dword [last_link], 0    ;   check if there is no link yet
	    je first_link               ;   jump to create first link
	                                ;   else
	    mov esi, [last_link]        ;   save last link in register
	    mov edi, [new_link]
	    mov dword [esi+1], edi      ;   change last links next to new link
	    mov [last_link], edi        ;   save new link as last link
	    mov eax, [last_link]
		ret

	first_link:                     ;   HANDLES CASE OF FIRST link IN STACK CELL
	    mov ebx, [counter]          ;   save counter in ebx
	    mov [operands+ebx*4], esi   ;   save new link in the stack
	    inc byte [counter]          ;   increase counter

	    mov [last_link], esi        ;   save new link as last link
	    mov eax, esi
	    ret

;---------------------------------------------------------------------------------------------------------------------
;                                               recursive function for pop and print
;---------------------------------------------------------------------------------------------------------------------

 list_sum:
        mov ecx, 0
        mov edi, [esp+4]          ;   get first argument - the sec list  
        mov esi, [esp+8]          ;   get sec argument - the first list
    sumcheck:        
        mov edx, 0              ;   reset edx   
        mov eax, 0              ;   reset eax   
        
        mov al, [esi]           ;   put in al value of esi
        mov dl, [edi]           ;   put in dl value of edi

        adc al, dl;             ;   add al and dl with carry
        daa                     ;   make it bcd
        pushfd
        
        mov [res], al           ;   put in res the sum result
        
        pushad                  ;   save registers
        call newlink            ;   call newlink
        popad
        
        cmp dword [esi+1], 0
        je end_add
        cmp dword [edi+1], 0
        je end_add
        
        mov esi, [esi+1]
        mov edi, [edi+1]
        popfd
        jmp sumcheck

    end_add:
        cmp dword [esi+1], 0
        je edilong
        cmp dword [edi+1], 0
        je esilong
        jmp checkcarry
    
    edilong:
        cmp dword [edi+1], 0
        je checkcarry
        
        mov edi, [edi+1]
        mov eax, 0
        mov al, [edi]
        
        popfd
        adc al, 0
        daa
        mov [edi], al
        pushfd
        
        mov esi, [last_link]
        mov [esi+1], edi
        mov [last_link], edi
        jmp edilong
        
    esilong:
        cmp dword [esi+1], 0
        je checkcarry
        
        mov esi, [esi+1]
        mov eax, 0
        mov al, [esi]
        
        popfd
        adc al, 0
        daa
        mov [esi], al
        pushfd
        
        mov edi, [last_link]
        mov [edi+1], esi
        mov [last_link], esi
        jmp esilong
    
    checkcarry:
        popfd
        jnc go_ret
        mov dword [res], 1
        pushad
        call newlink
        popad

    go_ret:
        ret
        

check_debug:
    mov eax, [esp+4]
    cmp eax, 0
    je end_func    
    cmp dword [counter], 0
    je end_func
    mov ecx, [counter]          ;   put counter inregister
    dec ecx                     ;   decrease ecx for getting the last operand
    mov edi, [operands +4*ecx]  ;   put last operand in edi

    pushad
    push edi
    call print_link
    add esp, 4
    popad
end_func:
    ret


make_list_demical:
    mov eax, 1
    mov edx, 0
    mov ebx, 10
    mov esi, [esp+4]
sum_it: 
    mov ecx, 0
    mov edx, 0                  ;   reset EAX           
    mov dl, [esi]                 ;   put k in al
    cmp edx, 10                 ;   check if k is less than 10
    jb sum_cont
    and dl, 240                 ;   else, save only high 4 bits
    shr dl, 4                   ;   move the 4 bits to the right
    mov ebx, 10                 ;   multiply by 10
    push eax
    mov eax, edx
    mul ebx                     ;   ""
    mov edx, eax
    pop eax
    mov ebx, 0                  ;   reset ebx
    mov bl, [esi]                 ;   put k in bl
    and bl, 15                  ;   save only lower 4 bits
    add edx, ebx                ;   add al and bl (decimal value of k)
    print bye, S0
    print edx, D0

sum_cont:   
    push eax
    mov ecx, eax
add_loop:
    add [sum], edx
    loop add_loop, ecx
    pop eax
    mul ebx
    cmp dword [esi+1], 0
    je end_list_sum
    mov esi, [esi+1]
    jmp sum_it

end_list_sum:
    mov eax, [sum]
    ret