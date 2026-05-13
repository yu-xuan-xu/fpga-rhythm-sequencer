
#define MEM_TOTAL 0x20000 /* 128 KB */


#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_uart_data   (*(volatile uint32_t*)0x02000008)
#define rgb_leds (*(volatile uint32_t*)0x03000000)
#define leds (*(volatile uint32_t*)0x04000000)
#define disp03 (*(volatile uint32_t*)0x04000004)
#define disp47 (*(volatile uint32_t*)0x04000008)
#define keys (*(volatile uint32_t*)0x0400000C)



void delay_1s();
void putchar(char c);
void print(const char *p);
void print_hex(uint32_t v, int digits);
void print_int(uint32_t v);
