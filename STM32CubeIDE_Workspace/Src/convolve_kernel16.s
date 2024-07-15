.syntax unified
.cpu cortex-m4
.fpu softvfp
.thumb

.global convolve_kernel16

@ Start of executable code
.section .text

@R0 - First Address of Signal --> current result address
@R1 - First Address of Kernel --> current signal address
@R2 - Len(Signal) --> last signal address
@R3 - Len(Kernel) --> current output value (mla)
@R4-R7 - loaded kernel values !! use from 7 to 4 !!
@R8-R11 - current signal values
@R12 - for loading / processing kernel values
@!LR - for loading / processing signal values (MUST PUSH!)

convolve_kernel16:
	bl loading_kernel
	bl init_signal
	bl loop_signal

	b returnc

loading_kernel:
@R8 - offset value (0/8/16/24)
@R9 - temporary kernel register before moving to r4/5/6/7
@R10 - lr to go back to convolve_kernel16 program (fake stack)
@R12 - kernel value from ldr

	mov r10, lr
	sub r3, #1 @ len(kernel) - 1
	lsl r3, r3, #2 @ (word)len(kernel) * 4 (<<2) = (byte)len(kernel)
	add r3, r1 @ r3 = addr of last kernel data

	mov r4, #0
	mov r5, #0
	mov r6, #0
	mov r7, #0

	@! kernel[0] is lowest byte of r4 (last loaded is 0 since kernel is flipped)

	bl byteload
	mov r7, r9
	bl byteload
	mov r6, r9
	bl byteload
	mov r5, r9
	bl byteload
	mov r4, r9
	bx r10

	byteload:
		cmp r1, r3 @ check if loop exited because kernel finished loading, or because we should shift to the next register
		it HI
		bxHI r10 @ if kernel address overshot (i.e. finished loading), go back to main convolve_kernel16 program
		mov r8, #24 @ reset r8 r9 since this is a new register
		mov r9, #0
		b byteload_loop

	byteload_loop:
		ldr r12, [r1], #4
		and r12, #0x000000ff @ remove all the signed 2s ff except relevant 8bit ones
		lsl r12, r8 @ shift loaded value by the r8 offset (basically the counter)
		orr r9, r9, r12 @ bitwise OR with currently loaded values into temporary r9

		sub r8, #8 @ decrease offset by 8
		cmp r8, #0 @ if offset is negative (finished this register), go back to store r9 in r4/5/6/7
		it LT
		bxLT lr

		cmp r1, r3 @ if kernel finished loading and kernel address overshoot, go back to store r9, and also go back to main convolve_kernel16 program
		it HI
		bxHI lr

		b byteload_loop @ if nothing, loop


init_signal:
	mov r1, r0 @ move first addr of signal from r0 to r1, addr of kernel is unneeded already
	ldr r0, =result
	sub r2, #1 @ len(signal) - 1
	lsl r2, r2, #2 @ (word)len(signal) * 4 (<<2) = (byte)len(signal)
	add r2, r1 @ r2 = addr of last signal data

	mov r11, #0
	mov r10, #0
	mov r9, #0
	mov r8, #0
	bx lr

loop_signal:
	push {lr} @! important !!

	@! signal[0] is highest byte of r11 (first loaded value)
	loop:
		cmp r1, #0
		bNE postcheck
		sub r2, #1
		cmp r2, #0
		it LT
		popLT {pc}

		postcheck: lsl r11, r11, #8		@ shift left by 1 byte, discard highest byte
		orr r11, r11, r10, lsr #24	@ bitwise OR with the highest byte of lower register
		lsl r10, r10, #8
		orr r10, r10, r9, lsr #24
		lsl r9, r9, #8
		orr r9, r9, r8, lsr #24

		@! lr will store current signal value!!

		signal_15_12:

			@? loading signal
			cmp r1, #0				@ if r1 == 0 like we manually set, signal is fully loaded. fill lr with 0 instead.
			itee EQ
			movEQ lr, #0
			ldrNE lr, [r1], #4		@ signal[15] (last loaded value)
			andNE lr, #0x000000ff

			orr r8, lr, r8, lsl #8	@ load latest signal[15] from lr into lowest byte of r8
			lsr r12, r7, #24		@ kernel[15], highest byte of r7

				@? bit masking
				and r12, #0x000000ff
				cmp r12, #0x00000080	@ in 8 bit, 0x80 is -128 in twos complement
				it CS
				orrCS r12, #0xffffff00	@ if >=128, must fill with ff to make it negative in 32bit 
				and lr, #0x000000ff
				cmp lr, #0x00000080
				it CS
				orrCS lr, #0xffffff00

			mul r3, lr, r12

			lsr r12, r7, #16		@ kernel[14]
			lsr lr, r8, #8			@ signal[14]

				@? bit masking
				and r12, #0x000000ff
				cmp r12, #0x00000080
				it CS
				orrCS r12, #0xffffff00
				and lr, #0x000000ff
				cmp lr, #0x00000080
				it CS
				orrCS lr, #0xffffff00


			mla r3, r12, lr, r3

			lsr r12, r7, #8			@ kernel[13]
			lsr lr, r8, #16			@ signal[13]

				@? bit masking
				and r12, #0x000000ff
				cmp r12, #0x00000080
				it CS
				orrCS r12, #0xffffff00
				and lr, #0x000000ff
				cmp lr, #0x00000080
				it CS
				orrCS lr, #0xffffff00
				

			mla r3, r12, lr, r3

			mov r12, r7				@ kernel[12], lowest byte of r7
			lsr lr, r8, #24			@ signal[12], highest byte of r8

				@? bit masking
				and r12, #0x000000ff
				cmp r12, #0x00000080
				it CS
				orrCS r12, #0xffffff00
				and lr, #0x000000ff
				cmp lr, #0x00000080
				it CS
				orrCS lr, #0xffffff00
				

			mla r3, r12, lr, r3

		signal_11_8:
			lsr r12, r6, #24		@ kernel[11], highest byte of r6
			mov lr, r9				@ signal[11], lowest byte of r9

				@? bit masking
				and r12, #0x000000ff
				cmp r12, #0x00000080
				it CS
				orrCS r12, #0xffffff00
				and lr, #0x000000ff
				cmp lr, #0x00000080
				it CS
				orrCS lr, #0xffffff00
				

			mla r3, r12, lr, r3
			
			lsr r12, r6, #16		@ kernel[10]
			lsr lr, r9, #8			@ signal[10]

				@? bit masking
				and r12, #0x000000ff
				cmp r12, #0x00000080
				it CS
				orrCS r12, #0xffffff00
				and lr, #0x000000ff
				cmp lr, #0x00000080
				it CS
				orrCS lr, #0xffffff00
				

			mla r3, r12, lr, r3

			lsr r12, r6, #8			@ kernel[9]
			lsr lr, r9, #16			@ signal[9]

				@? bit masking
				and r12, #0x000000ff
				cmp r12, #0x00000080
				it CS
				orrCS r12, #0xffffff00
				and lr, #0x000000ff
				cmp lr, #0x00000080
				it CS
				orrCS lr, #0xffffff00
				

			mla r3, r12, lr, r3

			mov r12, r6				@ kernel[8], lowest byte of r6
			lsr lr, r9, #24			@ signal[8], highest byte of r9

				@? bit masking
				and r12, #0x000000ff
				cmp r12, #0x00000080
				it CS
				orrCS r12, #0xffffff00
				and lr, #0x000000ff
				cmp lr, #0x00000080
				it CS
				orrCS lr, #0xffffff00
				

			mla r3, r12, lr, r3

		signal_7_4:
			lsr r12, r5, #24		@ kernel[7], highest byte of r5
			mov lr, r10				@ signal[7], lowest byte of r10

				@? bit masking
				and r12, #0x000000ff
				cmp r12, #0x00000080
				it CS
				orrCS r12, #0xffffff00
				and lr, #0x000000ff
				cmp lr, #0x00000080
				it CS
				orrCS lr, #0xffffff00
				

			mla r3, r12, lr, r3
			
			lsr r12, r5, #16		@ kernel[6]
			lsr lr, r10, #8			@ signal[6]

				@? bit masking
				and r12, #0x000000ff
				cmp r12, #0x00000080
				it CS
				orrCS r12, #0xffffff00
				and lr, #0x000000ff
				cmp lr, #0x00000080
				it CS
				orrCS lr, #0xffffff00
				

			mla r3, r12, lr, r3

			lsr r12, r5, #8			@ kernel[5]
			lsr lr, r10, #16		@ signal[5]

				@? bit masking
				and r12, #0x000000ff
				cmp r12, #0x00000080
				it CS
				orrCS r12, #0xffffff00
				and lr, #0x000000ff
				cmp lr, #0x00000080
				it CS
				orrCS lr, #0xffffff00
				

			mla r3, r12, lr, r3

			mov r12, r5				@ kernel[4], lowest byte of r5
			lsr lr, r10, #24		@ signal[4], highest byte of r10

				@? bit masking
				and r12, #0x000000ff
				cmp r12, #0x00000080
				it CS
				orrCS r12, #0xffffff00
				and lr, #0x000000ff
				cmp lr, #0x00000080
				it CS
				orrCS lr, #0xffffff00
				

			mla r3, r12, lr, r3

		signal_3_0:
			lsr r12, r4, #24		@ kernel[3], highest byte of r4
			mov lr, r11				@ signal[3], lowest byte of r11

				@? bit masking
				and r12, #0x000000ff
				cmp r12, #0x00000080
				it CS
				orrCS r12, #0xffffff00
				and lr, #0x000000ff
				cmp lr, #0x00000080
				it CS
				orrCS lr, #0xffffff00
				

			mla r3, r12, lr, r3
			
			lsr r12, r4, #16		@ kernel[2]
			lsr lr, r11, #8			@ signal[2]

				@? bit masking
				and r12, #0x000000ff
				cmp r12, #0x00000080
				it CS
				orrCS r12, #0xffffff00
				and lr, #0x000000ff
				cmp lr, #0x00000080
				it CS
				orrCS lr, #0xffffff00
				

			mla r3, r12, lr, r3

			lsr r12, r4, #8			@ kernel[1]
			lsr lr, r11, #16		@ signal[1]

				@? bit masking
				and r12, #0x000000ff
				cmp r12, #0x00000080
				it CS
				orrCS r12, #0xffffff00
				and lr, #0x000000ff
				cmp lr, #0x00000080
				it CS
				orrCS lr, #0xffffff00
				

			mla r3, r12, lr, r3

			mov r12, r4				@ kernel[0], lowest byte of r4
			lsr lr, r11, #24		@ signal[0], highest byte of r11

				@? bit masking
				and r12, #0x000000ff
				cmp r12, #0x00000080
				it CS
				orrCS r12, #0xffffff00
				and lr, #0x000000ff
				cmp lr, #0x00000080
				it CS
				orrCS lr, #0xffffff00
				

			mla r3, r12, lr, r3

		str r3, [r0], #4
		cmp r1, r2	@ compare current signal address with final signal address
		itt HI
		@ signal has been fully loaded, but kernel still needs to finish multiplying
		@ r1 will be countdown for how many more loops
		movHI r1, #0
		movHI r2, #15
		b loop
