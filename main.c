asm(".global _start\n_start:\n li sp, 0x00002000\n call main\n j .\n");

#define IO_SW       (*(volatile unsigned int*)0x40000000)
#define IO_BTNC     (*(volatile unsigned int*)0x40000004)
#define IO_TIMER    (*(volatile unsigned int*)0x40000008)
#define IO_SEG      (*(volatile unsigned int*)0x4000000C)
#define IO_LED      (*(volatile unsigned int*)0x40000010)
#define IO_BLINK    (*(volatile unsigned int*)0x40000014)

unsigned int bin_to_bcd(unsigned int val) {
    unsigned int thou = 0, huns = 0, tens = 0, ones = 0;
    while (val >= 1000) { val -= 1000; thou++; }
    while (val >= 100)  { val -= 100;  huns++; }
    while (val >= 10)   { val -= 10;   tens++; }
    ones = val;
    return (thou << 12) | (huns << 8) | (tens << 4) | ones;
}

void delay_ms(unsigned int ms) {
    for (volatile unsigned int i = 0; i < ms * 5000; i++);
}

int main() {
    int state = 0; // 0: Setup, 1: Countdown, 2: Done, 3: Pause
    unsigned int current_time = 0;
    unsigned int btn_prev = 0;

    while(1) {
        unsigned int btn_now = IO_BTNC;
        int btnC_pressed = (btn_now & 0x01) && !(btn_prev & 0x01);
        
        if (btn_now != btn_prev) {
            delay_ms(20); 
        }
        btn_prev = btn_now;

        if (state == 0) {
            current_time = IO_SW;
            if (current_time > 9999) current_time = 9999;
            IO_SEG = bin_to_bcd(current_time);
            IO_LED = 0;
            IO_BLINK = 0;
            if (btnC_pressed) {
                state = 1;
                IO_TIMER; 
            }
        } 
        else if (state == 1) {
            IO_BLINK = 0; 
            if (btnC_pressed) {
                state = 3; 
            } else {
                if (IO_TIMER) {
                    if (current_time > 0) current_time--;
                    if (current_time == 0) state = 2;
                }
                IO_SEG = bin_to_bcd(current_time);
            }
        }
        else if (state == 2) {
            IO_SEG = 0;
            IO_LED = 0xFFFF;
            IO_BLINK = 1;
            if (btnC_pressed) {
                state = 0;
                IO_BLINK = 0;
                IO_LED = 0;
            }
        }
        else if (state == 3) {
            IO_SEG = bin_to_bcd(current_time);
            IO_BLINK = 1; 
            if (btnC_pressed) {
                state = 1;
                IO_BLINK = 0; 
                IO_TIMER; 
            }
        }
    }
    return 0;
}