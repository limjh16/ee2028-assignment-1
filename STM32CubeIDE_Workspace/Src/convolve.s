.syntax unified
.cpu cortex-m4
.fpu softvfp
.thumb

.global convolve
.global returnc
.global result

@ Start of executable code
.section .text

@ EE2028 Assignment 1, Sem 2, AY 2023/24
@ (c) ECE NUS, 2024

@ Write Student 1’s Name here: Leow Heng Hao, Cedric 	|		A0273084A
@ Write Student 2’s Name here: Lim Jing Heng 			|		A0272417E

@ write your program from here:

convolve:
	push {r4-r11, r14}

	cmp r3, #1
	bEQ convolve_kernel1

	cmp r3, #5
	bLS convolve_kernel5 @ 5 <= len(kernel)

	cmp r3, #16
	bLS convolve_kernel16 @ 5 < len(kernel) <= 16

	cmp r3, #16
	bHI convolve_generic @ len(kernel) > 16

returnc: 
	ldr r0, =result
	pop {r4-r11, r15}

convolve_kernel1:
	sub r2, #1		@ len(signal) - 1
	lsl r2, r2, #2	@ (word)len(signal) * 4 (<<2) = (byte)len(signal)
	add r2, r0		@ r2 = addr of end of signal array
	
	ldr r6, =result
	ldr r1, [r1]
	loop:
		ldr r4, [r0], #4
		mul r4, r1
		str r4, [r6], #4
		cmp r0, r2
		bLE loop

	b returnc

.lcomm result 512 @ max 128 results
