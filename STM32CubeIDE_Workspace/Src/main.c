/**
 ******************************************************************************
 * @project        : EE2028 Assignment 1 Program Template
 * @file           : main.c
 * @author         : Hou Linxin, ECE, NUS
 * @brief          : Main program body
 ******************************************************************************
 * @attention
 *
 * <h2><center>&copy; Copyright (c) 2021 STMicroelectronics.
 * All rights reserved.</center></h2>
 *
 * This software component is licensed by ST under BSD 3-Clause license,
 * the "License"; You may not use this file except in compliance with the
 * License. You may obtain a copy of the License at:
 *                        opensource.org/licenses/BSD-3-Clause
 *
 ******************************************************************************
 */

#include "stdio.h"
#include "stdlib.h"

// helper functions to get the min and max of two numbers
#define MIN(X, Y) (((X) < (Y)) ? (X) : (Y))
#define MAX(X, Y) (((X) < (Y)) ? (Y) : (X))

#define M 3	 // size of signal array
#define N 16	 // size of kernel array


// 1D convolution implementation in C
int* convolution_c(int h[], int x[], int lenH, int lenX, int* lenY)
{
  int nconv = lenH+lenX-1;
  (*lenY) = nconv;
  int i,j,h_start,x_start,x_end;

  int *y = (int*) calloc(nconv, sizeof(int));

  for (i=0; i<nconv; i++)
  {
    x_start = MAX(0,i-lenH+1);
    x_end   = MIN(i+1,lenX);
    h_start = MIN(i,lenH-1);
    for(j=x_start; j<x_end; j++)
    {
      y[i] += h[h_start--]*x[j];
    }
  }
  return y;
}

// function to print an array
void printArray(int arr[], int size) {
	printf("The result array is: {");
	for (int i = 0; i < size; ++i) {
		printf("%d  ", arr[i]);
	}
	printf("}\n");
}


// Necessary function to enable printf() using semihosting
extern void initialise_monitor_handles(void);
void _kill(void){
	while(1);
}

// Functions to be written
extern int* convolve(int* arg1, int* arg2, int arg3, int arg4);

int main(void)
{
	// Necessary function to enable printf() using semihosting
	initialise_monitor_handles();

	int h[] = { -1,2,-3,0,5,0,-7,-8,-9,-10,9,10,5,3,-4,-6,2,-7,8,1 };
	// int x[] = { 0xff,0xfe,0xfd,0xfc,0xef,0xee,0xed,0xec,0xdf,0xde,0xdd,0xdc,0xcf,0xce,0xcd,0xcc };
	// int h[] = { 0xff,0xfe,0xfd,0xfc,0xef,0xee,0xed,0xec,0xdf,0xde,0xdd,0xdc,0xcf,0xce,0xcd,0xcc };
	int x[] = {-11,-12,-13,-14,1,-11,-12,-13,-14,1,-11,-12,-13,-14,1,-11,-12,-13,-14,1,-11,-12,-13,-14,1,2};
	int lenY;
	lenY = M + N - 1;

	//call convolution.s
	printf("Output from convolution.s: \n");
	int *yc = convolve((int*)h, (int*)x, (int)M, (int)N);
	// R0 should be the pointer of the result array
	printArray(yc, lenY);

	//call convolution_c:
	printf("Output from convolution_c: \n");
	int *ys = convolution_c(h,x,M,N,&lenY);
	printArray(ys, lenY);
}



