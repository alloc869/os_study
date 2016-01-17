; ==========================================
; pmtest1.asm
; usage：nasm pmtest1.asm -o pmtest1.bin
; ==========================================

%include	"pm.inc"	; headfile

org	0100h
	jmp	LABEL_BEGIN

[SECTION .gdt]
; GDT
;                               base,       limit     , attr
LABEL_GDT:	   Descriptor       0,                0, 0           ; null desc
LABEL_DESC_NORMAL: Descriptor    0,         0ffffh, DA_DRW
LABEL_DESC_CODE32: Descriptor       0, SegCode32Len - 1, DA_C + DA_32; non-coherent code
LABEL_DESC_CODE16:  Descriptor    0,    0ffffh, DA_C
LABEL_DESC_DATA:    Descriptor    0,    DataLen-1, DA_DRW
LABEL_DESC_STACK:   Descriptor    0,    TopOfStack, DA_DRWA+DA_32
LABEL_DESC_CODE_DEST: Descriptor  0,    SegCodeDestLen-1, DA_C+DA_32
LABEL_DESC_TEST:    Descriptor 0500000h,0ffffh, DA_DRW
LABEL_DESC_LDT:     Descriptor       0,  LDTLen - 1, DA_LDT
LABEL_DESC_VIDEO:   Descriptor 0B8000h,  0ffffh, DA_DRW	+ DA_DPL3    ; viedo base adrress
LABEL_CALL_GATE_TEST: Gate SelectorCodeDest,   0,     0, DA_386CGate+DA_DPL3
; call gate

LABEL_DESC_CODE_RING3: Descriptor 0, SegCodeRing3Len-1, DA_C+DA_32+DA_DPL3
LABEL_DESC_STACK3:     Descriptor 0,       TopOfStack3, DA_DRWA+DA_32+DA_DPL3

LABEL_DESC_TSS:        Descriptor 0,          TSSLen-1, DA_386TSS

GdtLen		equ	$ - LABEL_GDT	; GDT length
GdtPtr		dw	GdtLen - 1	; GDT limit
		    dd	0		; GDT base address

; GDT selector
SelectorNormal		equ	LABEL_DESC_NORMAL	- LABEL_GDT
SelectorCode16		equ	LABEL_DESC_CODE16	- LABEL_GDT
SelectorData		equ	LABEL_DESC_DATA		- LABEL_GDT
SelectorCodeDest	equ	LABEL_DESC_CODE_DEST	- LABEL_GDT
SelectorStack		equ	LABEL_DESC_STACK	- LABEL_GDT
SelectorTest		equ	LABEL_DESC_TEST		- LABEL_GDT
SelectorCode32		equ	LABEL_DESC_CODE32	- LABEL_GDT
SelectorVideo		equ	LABEL_DESC_VIDEO	- LABEL_GDT
SelectorLDT		    equ	LABEL_DESC_LDT		- LABEL_GDT
SelectorCallGateTest	equ	LABEL_CALL_GATE_TEST	- LABEL_GDT + SA_RPL3
SelectorCodeRing3	equ	LABEL_DESC_CODE_RING3	- LABEL_GDT + SA_RPL3
SelectorStack3		equ	LABEL_DESC_STACK3	- LABEL_GDT + SA_RPL3
SelectorTSS		equ	LABEL_DESC_TSS		- LABEL_GDT
; END of [SECTION .gdt]

[SECTION .data1]	 ; data section
ALIGN	32
[BITS	32]
LABEL_DATA:
SPValueInRealMode	dw	0
PMMessage:		db	"In Protect Mode now. ^-^", 0
OffsetPMMessage		equ	PMMessage - $$
StrTest:		db	"ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0
OffsetStrTest		equ	StrTest - $$
DataLen			equ	$ - LABEL_DATA


[SECTION .gs] ; stack section
ALIGN	32
[BITS	32]
LABEL_STACK:
	times 512 db 0

TopOfStack	equ	$ - LABEL_STACK - 1

; ring3 stack
[SECTION .s3]
ALIGN	32
[BITS	32]
LABEL_STACK3:
	times 512 db 0
TopOfStack3	equ	$ - LABEL_STACK3 - 1

; TSS
[SECTION .tss]
ALIGN	32
[BITS	32]
LABEL_TSS:
		DD	0			; Back
		DD	TopOfStack		; 0 级堆栈
		DD	SelectorStack		; 
		DD	0			; 1 级堆栈
		DD	0			; 
		DD	0			; 2 级堆栈
		DD	0			; 
		DD	0			; CR3
		DD	0			; EIP
		DD	0			; EFLAGS
		DD	0			; EAX
		DD	0			; ECX
		DD	0			; EDX
		DD	0			; EBX
		DD	0			; ESP
		DD	0			; EBP
		DD	0			; ESI
		DD	0			; EDI
		DD	0			; ES
		DD	0			; CS
		DD	0			; SS
		DD	0			; DS
		DD	0			; FS
		DD	0			; GS
		DD	0			; LDT
		DW	0			; 调试陷阱标志
		DW	$ - LABEL_TSS + 2	; I/O位图基址
		DB	0ffh			; I/O位图结束标志
TSSLen		equ	$ - LABEL_TSS


[SECTION .s16] ; entry point
[BITS	16]
LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
    mov sp, 0100h

    mov [LABEL_GO_BACK_TO_REAL+3], ax
    mov [SPValueInRealMode], sp

    ; fill code16 descriptor
	mov	ax, cs
	movzx	eax, ax
	shl	eax, 4
	add	eax, LABEL_SEG_CODE16
	mov	word [LABEL_DESC_CODE16 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE16 + 4], al
	mov	byte [LABEL_DESC_CODE16 + 7], ah


	; fill code32 desc
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32
	mov	word [LABEL_DESC_CODE32 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE32 + 4], al
	mov	byte [LABEL_DESC_CODE32 + 7], ah

    ; fill call dest code
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE_DEST
	mov	word [LABEL_DESC_CODE_DEST + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE_DEST + 4], al
	mov	byte [LABEL_DESC_CODE_DEST + 7], ah

	; fill data desc
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_DATA
	mov	word [LABEL_DESC_DATA + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_DATA + 4], al
	mov	byte [LABEL_DESC_DATA + 7], ah

	; fill stack desc
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_STACK
	mov	word [LABEL_DESC_STACK + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_STACK + 4], al
	mov	byte [LABEL_DESC_STACK + 7], ah

    ; fill stack ring3
    xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_STACK3
	mov	word [LABEL_DESC_STACK3 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_STACK3 + 4], al
	mov	byte [LABEL_DESC_STACK3 + 7], ah

    ; fill ring3 code
    xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_CODE_RING3
	mov	word [LABEL_DESC_CODE_RING3 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE_RING3 + 4], al
	mov	byte [LABEL_DESC_CODE_RING3 + 7], ah

    ; fill ldt desc in gdt
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, LABEL_LDT
    mov word [LABEL_DESC_LDT + 2], ax
    shr eax, 16
    mov byte [LABEL_DESC_LDT + 4], al
    mov byte [LABEL_DESC_LDT + 7], ah

    ; fill ld
    xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_CODE_A
    mov word [LABEL_LDT_DESC_CODEA + 2], ax
    shr eax, 16
    mov byte [LABEL_LDT_DESC_CODEA + 4], al
    mov byte [LABEL_LDT_DESC_CODEA + 7], ah

    ; fill tss desc
    xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_TSS
	mov	word [LABEL_DESC_TSS + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_TSS + 4], al
	mov	byte [LABEL_DESC_TSS + 7], ah

	; fill gdtr desc
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT		; eax <- gdt base address
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt

	; load GDTR
	lgdt	[GdtPtr]

	; close interrupt
	cli

	; enable A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; enable protect mode
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax
	; jump to 32bit protect mode
	jmp	dword SelectorCode32:0	; load cs with SelectorCode32 and offset 0,
                                ; thus jmp to 32bit code

LABEL_REAL_ENTRY:		; protect mode to real address mode
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax

	mov	sp, [SPValueInRealMode]

	in	al, 92h		; `.
	and	al, 11111101b	;  disable A20
	out	92h, al		; /

	sti			;   open irq

	mov	ax, 4c00h	; `.
	int	21h		; /  to DOS
; END of [SECTION .s16]



[SECTION .s32]; 32 bit protect mode.
[BITS	32]

LABEL_SEG_CODE32:
    ; load correct selector for segment register
	mov	ax, SelectorData
	mov     ds, ax
	mov	ax, SelectorTest
    mov es, ax
    mov ax, SelectorVideo
    mov gs, ax

    mov ax, SelectorStack
    mov ss, ax
    mov esp, TopOfStack

    mov ah, 0xC
    xor esi, esi
    xor edi, edi
    mov esi, OffsetPMMessage
	mov	edi, (80 * 10 + 0) * 2	; row 10, colmun 0

    cld
.1:
    lodsb
    test al, al
    jz .2
    mov [gs:edi], ax
    add edi, 2
    jmp .1

.2:

    call DispReturn

    mov ax, SelectorTSS
    ltr ax

    push SelectorStack3
    push TopOfStack3
    push SelectorCodeRing3
    push 0
    retf    ; Ring0 -> Ring3

TestRead:
    xor esi, esi
    mov ecx, 8
.loop:
    mov al, [es:esi]
    call DispAL
    inc esi
    loop .loop

    call DispReturn
    ret

TestWrite:
    push esi
    push edi
    xor esi, esi
    xor edi, edi
    mov esi, OffsetStrTest
    cld

.1:
    lodsb
    test al, al
    jz .2
    mov [es:edi], al
    inc edi
    jmp .1

.2:
    pop edi
    pop esi
    ret

DispAL:
    push ecx
    push edx

    mov ah, 0xC
    mov dl, al
    shr al, 4
    mov ecx, 2

.begin:
    and al, 0xf
    cmp al, 9
    ja .1
    add al, '0'
    jmp .2

.1:
    sub al, 0xA
    add al, 'A'

.2:
    mov [gs:edi], ax
    add edi, 2

    mov al, dl
    loop .begin

    pop edx
    pop ecx
    ret

DispReturn:
    push eax
    push ebx
    mov eax, edi
    mov bl, 160
    div bl
    and eax, 0xff
    inc eax
    mov bl, 160
    mul bl
    mov edi, eax
    pop ebx
    pop eax
    ret
SegCode32Len	equ	$ - LABEL_SEG_CODE32
; END of [SECTION .s32]

[SECTION .sdest]; 调用门目标段
[BITS	32]

LABEL_SEG_CODE_DEST:
	mov	ax, SelectorVideo
	mov	gs, ax
	mov	edi, (80 * 12 + 1) * 2
	mov	ah, 0Ch
	mov	al, 'C'
	mov	[gs:edi], ax

    ; load LDT
    mov ax, SelectorLDT
    lldt ax

    jmp SelectorLDTCodeA:0
	;retf

SegCodeDestLen	equ	$ - LABEL_SEG_CODE_DEST

[SECTION .s16code]
ALIGN 32
[BITS 16]
LABEL_SEG_CODE16:
    mov ax, SelectorNormal
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    ;disable protect mode and return to real mode
    mov eax, cr0
    and al, 0xfe
    mov cr0, eax

LABEL_GO_BACK_TO_REAL:
    jmp 0:LABEL_REAL_ENTRY

Code16Len equ $ - LABEL_SEG_CODE16
; END of [Section .s16code]

;LDT
[SECTION .ldt]
ALIGN 32
LABEL_LDT:

LABEL_LDT_DESC_CODEA:  Descriptor 0, CodeALen - 1, DA_C + DA_32

LDTLen      equ $ - LABEL_LDT

SelectorLDTCodeA	equ	LABEL_LDT_DESC_CODEA - LABEL_LDT + SA_TIL


; CodeA(LDT, 32)
[SECTION .la]
ALIGN	32
[BITS	32]
LABEL_CODE_A:
	mov	ax, SelectorVideo
	mov	gs, ax
	mov	edi, (80 * 13 + 0) * 2
    mov	ah, 0Ch
	mov	al, 'L'
	mov	[gs:edi], ax
	jmp	SelectorCode16:0

CodeALen	equ	$ - LABEL_CODE_A
; END of [SECTION .la]

; CodeRing3
[SECTION .ring3]
ALIGN	32
[BITS	32]
LABEL_CODE_RING3:
	mov	ax, SelectorVideo
	mov	gs, ax
	mov	edi, (80 * 14 + 0) * 2
	mov	ah, 0Ch
    mov	al, '3'
	mov	[gs:edi], ax

    call SelectorCallGateTest:0

	;jmp	$
SegCodeRing3Len	equ	$ - LABEL_CODE_RING3
; END of [SECTION .ring3]
