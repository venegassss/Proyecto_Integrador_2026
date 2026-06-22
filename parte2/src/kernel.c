#include <stdint.h>
#include <stddef.h>

#define VGA_WIDTH  80
#define VGA_HEIGHT 25

static uint16_t* vga_buf = (uint16_t*)0xB8000;
static size_t vga_row = 0;
static size_t vga_col = 0;
static uint8_t vga_color = 0x0F;

void set_color(uint8_t fg, uint8_t bg) {
    vga_color = (bg << 4) | fg;
}

void clear_screen(void) {
    for (size_t y = 0; y < VGA_HEIGHT; y++)
        for (size_t x = 0; x < VGA_WIDTH; x++)
            vga_buf[y * VGA_WIDTH + x] = ' ' | ((uint16_t)vga_color << 8);
    vga_row = 0;
    vga_col = 0;
}

void print_char(char c) {
    if (c == '\n') {
        vga_col = 0;
        if (++vga_row == VGA_HEIGHT) vga_row = 0;
        return;
    }
    vga_buf[vga_row * VGA_WIDTH + vga_col] =
        (uint8_t)c | ((uint16_t)vga_color << 8);
    if (++vga_col == VGA_WIDTH) {
        vga_col = 0;
        ++vga_row;
    }
}

void print_str(const char* str) {
    for (size_t i = 0; str[i]; i++)
        print_char(str[i]);
}

void kernel_main(void) {
    clear_screen();
    set_color(0xA, 0x0);
    print_str("=== Kernel 64-bit UIDE 2026 ===\n");
    set_color(0xF, 0x0);
    print_str("Integrantes:\n");
    print_str("  - Henry Quijia\n");
    print_str("  - Isaak Romero\n");
    print_str("  - Cristofer Venegas\n\n");
    set_color(0xB, 0x0);
    print_str("Long mode:   ACTIVO\n");
    print_str("Paginacion:  ACTIVA\n");
    print_str("GDT 64-bit:  CARGADA\n");
}
