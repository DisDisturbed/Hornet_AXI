CC32 = riscv32-unknown-elf
CCFLAGS = -march=rv32imf -mabi=ilp32f -O3 -fno-math-errno -T linksc.ld -lm -nostartfiles -ffunction-sections -fdata-sections -Wl,--gc-sections -g -ggdb -o temp.elf

HEX_FMT = -v -e '1/4 "%08x\n"'

build: AES.elf
	$(CC32)-objdump -D AES.elf > AES.dump
	$(CC32)-objcopy -O binary -j .init -j .text temp.elf instr.bin
	hexdump $(HEX_FMT) instr.bin > ins_mem.mem
	$(CC32)-objcopy -O binary -j .rodata -j .sdata -j .data temp.elf data.bin
	hexdump $(HEX_FMT) data.bin > data_mem.mem
	rm instr.bin data.bin

AES.elf: bubble_sort.c crt0.s
	$(CC32)-gcc bubble_sort.c crt0.s $(CCFLAGS) 
	# if you need to change the file change .c name 

clean:
	rm -f *.elf *.bin *.mem *.dump