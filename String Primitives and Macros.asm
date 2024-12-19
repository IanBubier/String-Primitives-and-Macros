TITLE String Primitives and Macros     (Proj6_bubieri.asm)

; Author:	Ian Bubier
; Last Modified:	12/10/2023
; OSU email address:	bubieri@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:	6	Due Date:	12/10/2023
; Description: This program prompts a user to enter a certain number of integers. It displays valid input and keeps a running sum of the integers.
;			   Once input is complete, the program displays the integers, their sum, and their truncated average.

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Stores a user's keyboard input as a string in memory.
;
; Preconditions: countValue is not larger than length of inputAddr input string.

; Postconditions: None
;
; Receives: promptAddr = address of user prompt
;			countValue = number of characters to read
;			inputAddr = address of input string
;		    bytesAddr = number of characters entered
;
; Returns: inputAddr = address of filled input string
;		   bytesAddr = number of characters entered
; ---------------------------------------------------------------------------------
mGetString		MACRO	promptAddr, countValue, inputAddr, bytesAddr
	push			eax
	push			ebx
	push			ecx
	push			edx	
	mov				edx, promptAddr
	call			writestring
	mov				ecx, countValue
	mov				edx, inputAddr
	call			ReadString
	mov				bytesAddr, eax
	pop				edx
	pop				ecx
	pop				ebx
	pop				eax
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Prints a string to the console.
;
; Preconditions: None

; Postconditions: None
;
; Receives: stringAddr = address of string
;
; Returns: Displays string.
; ---------------------------------------------------------------------------------
mDisplayString	MACRO	stringAddr
	push			edx
	mov				edx, stringAddr
	call			writestring
	pop				edx
ENDM

INTARRAYLENGTH = 10		; Controls number of integers to be entered. May be changed.

.data
authorName		BYTE	"Ian Bubier",10, 0
projectName		BYTE	"String Primitives and Macros", 10, 0
extraCredit		BYTE	"**EC 1: Number each line of user input and display a running subtotal of the user’s valid numbers.", 10, 10, 0
periodSpace		BYTE	". ", 0
pleaseEnter		BYTE	"Please enter ", 0
userInstruct	BYTE	" integers which can fit within a 32-bit register. Positive and negative signs are permitted, but commas are not. ", 10,
						"This program will keep a running sum of the integers entered. When all integers are entered this program", 10, "will display your input, the sum of your integers, ",
						"and the truncated average of your integers.", 10, 10, 0
userPrompt		BYTE	"Please enter a valid integer: ", 0
runningSum		BYTE	"The current sum of your integers is: ", 0
intInput		BYTE	"The integers you input are: ", 0
commaSpace		BYTE	", ", 0
totalSum		BYTE	"The total sum of your integers is: ", 0
intAverage		BYTE	"The truncated average of your integers is: ", 0
sayGoodbye		BYTE	"Goodbye!", 10, 10, 0
inputError		BYTE	"Your integer is outside the specified range.", 10, 10, 0
inputString		BYTE	12 DUP(0)				; Max SDWORD value is 10 digits. 10 digit bytes + 1 sign byte + 1 null byte = 12 bytes max length.
convertedStr	BYTE	12 DUP(0)				; Max SDWORD value is 10 digits. 10 digit bytes + 1 sign byte + 1 null byte = 12 bytes max length.
currentSum		SDWORD	0
intArray		SDWORD	INTARRAYLENGTH DUP(0)
currentEntry	SDWORD	1

.code

; ---------------------------------------------------------------------------------
; Name: main
;
; Introduces author and program and gives extra credit statement.
; Gets INTARRAYLENGTH number of valid integers from the user. Stores integer values in intArray.
; Displays the integers, the sum of the integers, and the truncated average of the integers.
;
; Preconditions: None

; Postconditions: None
;
; Receives: Keyboard input integers from user.
;
; Returns: Input values stored in intArray. 
;		   Displays input, sum of input, and truncated average of input.
; ---------------------------------------------------------------------------------
main		PROC

	; Give names of author and project, and instruct user.
	pushad
	mDisplayString	offset authorName
	mDisplayString	offset projectName
	mDisplayString	offset extraCredit
	mDisplayString	offset pleaseEnter
	mov				eax, INTARRAYLENGTH
	push			eax
	push			offset convertedStr
	call			WriteVal
	mDisplayString	offset userInstruct

	; Recieve and display input and running sum.
	mov				ecx, INTARRAYLENGTH
	mov				edi, offset intArray
_InputLoop:
	push			currentEntry
	push			offset convertedStr
	call			WriteVal
	inc				currentEntry
	mDisplayString	offset periodSpace
	push			offset inputError
	push			offset userPrompt
	push			offset inputString
	push			edi
	call			ReadVal
	mDisplayString	offset runningSum
	mov				eax, currentSum
	add				eax, [edi]
	mov				currentSum, eax
	push			currentSum
	push			offset convertedStr
	call			WriteVal
	call			crlf
	call			crlf
	add				edi, 4
	loop			_InputLoop

	; Display integers entered.
	mov				esi, offset intArray
	mov				ecx, INTARRAYLENGTH
	dec				ecx
	mDisplayString	offset intInput
_OutputLoop:
	push			[esi]
	push			offset convertedStr
	call			WriteVal
	add				esi, 4
	mDisplayString	offset commaSpace
	loop			_OutputLoop
	push			[esi]
	push			offset convertedStr
	call			WriteVal					; Last integer is not followed by comma.
	call			crlf
	call			crlf

	; Calculate and display sum and truncated average.
	mDisplayString	offset totalSum
	push			currentSum					; At the end of input, currentSum is total sum.
	push			offset convertedStr
	call			WriteVal
	call			crlf
	call			crlf
	mDisplayString	offset intAverage
	mov				eax, currentSum
	cdq
	mov				ebx, INTARRAYLENGTH
	idiv			ebx							; Average is truncated, so no need for further calculation.
	push			eax
	push			offset convertedStr
	call			WriteVal
	call			crlf
	call			crlf
	mDisplayString	offset sayGoodbye
	popad

	Invoke	ExitProcess,0	; exit to operating system
main		ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; Converts a string representing an integer into a SDWORD value stored in memory. Starting from the least significant digit, 
; each character is converted from ASCII and multiplied by the appropriate power of 10.
;
; Preconditions: None

; Postconditions: None
;
; Receives: [ebp+20] = Address of error message.
;			[ebp+16] = Address of user prompt.
;			[ebp+12] = Address of string to store user input.
;			[ebp+8]  = Address of SDWORD to store converted integer values.
;
; Returns: Converts integer string to value stored in memory.
; ---------------------------------------------------------------------------------
ReadVal		PROC
	LOCAL			bytesRead:	DWORD
	LOCAL			placeMult:	DWORD
	push			esi
	push			edi
	push			eax
	push			ebx
	push			ecx
	push			edx
_RedoInput:
	mov				esi, [ebp+16]
	mov				edi, [ebp+12]
_mGetString:
	mGetString	esi, 12, edi, bytesRead

	; Check that the string represents an integer.
	mov				esi, [ebp+12]
	cmp				bytesRead, 0				; Check that there was input.
	je				_InputError
	cmp				bytesRead, 1
	je				_CheckOnlyChar
	cmp				bytesRead, 11				; If more than 11 characters are read, integer must be too large for a 32-bit register.
	jg				_InputError
	add				esi, bytesRead
	dec				esi
	mov				ecx, bytesRead
	dec				ecx
	std
_CheckString:									; Digits are allowed.
	lodsb
	cmp				al, 57
	jg				_InputError
	cmp				al, 48
	jl				_InputError
	loop			_CheckString
_CheckFirstChar:								; Digits and signs are allowed.
	lodsb
	cmp				al, 43
	je				_PosString
	cmp				al, 45
	je				_NegString
	cmp				al, 57
	jg				_InputError
	cmp				al, 48
	jl				_InputError
	jmp				_UnsignedString
_CheckOnlyChar:									; Digits are allowed.
	lodsb
	cmp				al, 57
	jg				_InputError
	cmp				al, 48
	jl				_InputError

	; Convert positive string to value.
_UnsignedString:
	cmp				bytesRead, 10
	jg				_InputError
	mov				esi, [ebp+12]
	add				esi, bytesRead
	dec				esi
	mov				edi, [ebp+8]
	mov				ecx, bytesRead
	mov				placeMult, 1
	std
	jmp		_ConvertPosString
_PosString:									
	mov				esi, [ebp+12]
	add				esi, bytesRead
	dec				esi
	mov				edi, [ebp+8]
	mov				ecx, bytesRead
	dec				ecx							; If integer is signed, exclude first character from multiplication.
	mov				placeMult, 1
	std
_ConvertPosString:
	mov				eax, 0
	lodsb
	sub				al, 48
	imul			placeMult
	jo				_InputError					; Check for 32-bit overflow.
	add				[edi], eax
	jo				_InputError					; Check for 32-bit overflow.
	mov				eax, placeMult
	mov				ebx, 10
	mul				ebx
	mov				placeMult, eax
	loop			_ConvertPosString
	jmp				_EndReadVal

	; Convert negative string to value.
_NegString:
	mov				esi, [ebp+12]
	add				esi, bytesRead
	dec				esi
	mov				edi, [ebp+8]
	mov				ecx, bytesRead
	dec				ecx							; If integer is signed, exclude first character from multiplication.
	mov				placeMult, 1
	std
_ConvertNegString:
	mov				eax, 0
	lodsb
	sub				al, 48
	imul			placeMult
	jo				_InputError					; Check for 32-bit overflow.
	sub				[edi], eax
	jo				_InputError					; Check for 32-bit overflow.
	mov				eax, placeMult
	mov				ebx, 10
	mul				ebx
	mov				placeMult, eax
	loop			_ConvertNegString
	jmp				_EndReadVal

	; In case of incorrect input.
_InputError:		
	mDisplayString	[ebp+20]
	jmp				_RedoInput

	; Cleanup
_EndReadVal:
	pop				edx
	pop				ecx
	pop				ebx
	pop				eax
	pop				edi
	pop				esi
	ret				16

ReadVal		ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; Converts an integer value to an ASCII byte string and displays the string.
;
; Preconditions: Array is type SDWORD and filled with integer values.

; Postconditions: None
;
; Receives: [ebp+12] = Value to convert to string.
;			[ebp+8]  = Address of string to store converted value.
;
; Returns: Displays value as a string.
; ---------------------------------------------------------------------------------
WriteVal	PROC
	push			ebp
	mov				ebp, esp
	push			esi
	push			edi
	push			edx
	push			ecx
	push			ebx
	push			eax
	mov				eax, [ebp+12]
	mov				edi, [ebp+8]
	mov				ecx, 0
	cld

	; Include "-" for negatives.
	cmp				eax, 0
	jge				_ConvertVal
	mov				al, 45
	stosb
	mov				eax, [ebp+12]
	neg				eax

	; Convert value to string.
_ConvertVal:
	mov				edx, 0
	mov				ebx, 10
	div				ebx							; Remainder of division by 10 is trailing digit of integer.
	cmp				eax, 0						; When dividend is 0, all digits have been isolated.
	je				_LastChar
	add				dl, 48
	push			edx
	inc				ecx
	jmp				_ConvertVal
_LastChar:
	add				dl, 48
	push			edx							; Digits pushed in order of least to most significant.
	inc				ecx
_ConvertString:
	pop				edx							; Digits poped in order of most to least significant, per decimal system.
	mov				al, dl
	stosb
	loop			_ConvertString
	mov				al, 0
	stosb
	mov				esi, [ebp+8]
	mDisplayString	esi

	; Cleanup
	pop				eax
	pop				ebx
	pop				ecx
	pop				edx
	pop				edi
	pop				esi
	pop				ebp
	ret				8

WriteVal	ENDP

END main
