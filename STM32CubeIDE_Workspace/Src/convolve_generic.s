.syntax unified
.cpu cortex-m4
.fpu softvfp
.thumb

.global convolve_generic

@ Start of executable code
.section .text

/*
r0 - first address of signal
r1 - first address of kernel
r2 - len(signal) --> last address of signal
r3 - len(kernel) --> last address of kernel

r4 - current signal address
r5 - travelling start signal address
r6 - current kernel address

r7 - current signal loaded number
r8 - current kernel loaded number

r9 - mla
r10 - current lcomm address
*/

convolve_generic:

	sub r2, #1		@ len(signal) - 1
	lsl r2, r2, #2	@ (word)len(signal) * 4 (<<2) = (byte)len(signal)
	add r2, r0		@ r2 = addr of end of signal array

	sub r3, #1		@ len(kernel) - 1
	lsl r3, r3, #2	@ (word)len(kernel) * 4 (<<2) = (byte)len(kernel)
	sub r5, r0, r3	@ set the travelling start before signal array (based on kernel length)
	add r3, r1		@ r3 = addr of end of kernel array
	ldr r10, =result

large_loop:

	cmp r5, r2		@ exit condition, when travelling start > end of signal array
	bGT returnc

	mov r6, r3		@ kernel starts from start, but flip, so start from end
	
	cmp r5, r0		@ check if travelling signal address is before signal array
	ittte LT
	subLT r4, r0, r5@ temporarily use r4 to store kernel offset
	subLT r6, r4	@ offset kernel address to where signal starts
	movLT r4, r0	@ move signal address to the start
	movGE r4, r5	@ signal starts from travelling start

	mov r9, #0		@ init mla variable

	small_loop:
		
		cmp r4, r2		@ check if current signal address is after signal array
		bGT exit_small_loop

		ldr r7, [r4], #4 @ if no problem, load current signal
		ldr r8, [r6], #-4 @ load kernel
		mla r9, r8, r7, r9

		cmp r6, r1
		bGE small_loop	@ if current kernel address still >= start address (within range), continue

	exit_small_loop: str r9, [r10], #4
	add r5, #4
	b large_loop
