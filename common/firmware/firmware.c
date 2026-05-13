/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 */

#include <stdint.h>
#include <stdbool.h>

#include "firmware.h"

// --------------------------------------------------------

void delay_1s() {
	for(int k=0;k<125000;k++) {
	}
}

void putchar(char c)
{
	if (c == '\n')
		putchar('\r');
	reg_uart_data = c;
}

void print(const char *p)
{
	while (*p)
		putchar(*(p++));
}

void print_hex(uint32_t v, int digits)
{
	for (int i = 7; i >= 0; i--) {
		char c = "0123456789abcdef"[(v >> (4*i)) & 15];
		if (c == '0' && i >= digits) continue;
		putchar(c);
		digits = i;
	}
}

void print_int(uint32_t v) {
	char buf[8];
	buf[7] = 0; // null-terminate
	int i=6;
	while(v>0) {
		buf[i--] = '0' + (v % 10);
		v /= 10;
	}
	print(&buf[i+1]); // print from first non-zero digit
}

