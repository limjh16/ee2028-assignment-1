.syntax unified
.cpu cortex-m4
.fpu softvfp
.thumb

.global convolve_kernel5

@ Start of executable code
.section .text

@R0 - First Address of Signal --> current result address
@R1 - First Address of Kernel --> current signal address
@R2 - Len(Signal) --> last signal address
@R3 - Len(Kernel) --> latest signal value, signal[4]
@R4-R7 - loaded kernel values !! use from 7 to 4 to 12 !!
@R8-R11 - current signal values
@R12 - kernel[4]

convolve_kernel5:
	bl loading_kernel
	bl init_signal
	bl loop_signal

	b returnc

loading_kernel:
	sub r3, #1 @ len(kernel) - 1
	lsl r3, r3, #2 @ (word)len(kernel) * 4 (<<2) = (byte)len(kernel), cannot combine line 29,30 as r3 will not be updated after LSL
	add r3, r1 @ r3 = addr of last kernel data

	ldr r12, [r1], #4
	ldr r4, [r1], #4
	cmp r1, r3
	itttt HI
	MOVHI r5, #0
	set_r6_0: MOVHI r6, #0
	set_r7_0: MOVHI r7, #0
	BXHI lr

	ldr r5, [r1], #4
	cmp r1, r3
	BHI set_r6_0

	ldr r6, [r1], #4
	cmp r1, r3
	BHI set_r7_0

	ldr r7, [r1]
	bx lr

init_signal:
	mov r1, r0 @ move first addr of signal from r0 to r1, addr of kernel is unneeded already
	ldr r0, =result
	sub r2, #1 @ len(signal) - 1
	lsl r2, r2, #2 @ (word)len(signal) * 4 (<<2) = (byte)len(signal)
	add r2, r1 @ r2 = addr of last signal data

	mov r3, #0
	mov r11, #0
	mov r10, #0
	mov r9, #0
	@ mov r8, #0 @ r8 will be loaded on first loop_signal run
	bx lr

loop_signal:
	mov r8, r9
	mov r9, r10
	mov r10, r11
	mov r11, r3
	ldr r3, [r1], #4 	@ load signal address
	mul r8, r7			@ kernel[0] (r7) * signal[0](r8) (since this will be discarded anyways, use this to store result)
	mla r8, r12, r3, r8	@ kernel[4] (r12) * signal[4](r3)
	mla r8, r4, r11, r8	@ kernel[3] (r4) * signal[3](r11)
	mla r8, r5, r10, r8	@ kernel[2] (r5) * signal[2](r10)
	mla r8, r6, r9, r8	@ kernel[1] (r6) * signal[1](r9)
	str r8, [r0], #4	@ store final result (which is also signal[0] (r8)) to memory

	cmp r1, r2 			@ compare current signal address with final signal address
	bHI hardcode 		@ if current is over the final address, run hardcode

	b loop_signal

hardcode:
	@ hardcode so we save mov operation !! signal[0] is now r9, signal[1] is r10, signal[2] is r11, signal[3] is r3
	@ mov r8, r9
	@ mov r9, r10
	@ mov r10, r11
	@ mov r11, r3
	@ mov r3, #0

	mul r8, r4, r3 @ kernel[3] (r4) * signal[3](r3)
	mla r8, r5, r11, r8 @ kernel[2] (r5) * signal[2](r11)
	mla r8, r6, r10, r8 @ kernel[1] (r6) * signal[1](r10)
	mla r8, r7, r9, r8 @ kernel[0] (r7) * signal[0](r9)
	str r8, [r0], #4

	@ hardcode so we save mov operation !! signal[0] is now r10, signal[1] is r11, signal[2] is r3
	mul r8, r5, r3 @ kernel[2] (r5) * signal[2](r3)
	mla r8, r6, r11, r8 @ kernel[1] (r6) * signal[1](r11)
	mla r8, r7, r10, r8 @ kernel[0] (r7) * signal[0](r10)
	str r8, [r0], #4

	@ hardcode so we save mov operation !! signal[0] is now r11, signal[1] is r3
	mul r8, r6, r3 @ kernel[1] (r6) * signal[1](r3)
	mla r8, r7, r11, r8 @ kernel[0] (r7) * signal[0](r11)
	str r8, [r0], #4

	@ hardcode so we save mov operation !! signal[0] is now r3
	mul r8, r7, r3 @ kernel[0] (r7) * signal[0](r3)
	str r8, [r0], #4

	bx lr
