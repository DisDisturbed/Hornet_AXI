
AES.elf:     file format elf32-littleriscv


Disassembly of section .text:

00000000 <_start>:
_start:
    /* ------------------------------------------------- */
    /* 1. Initialize Stack Pointer                       */
    /* ------------------------------------------------- */
    /* Sets SP to the top of the Main RAM (defined in linker) */
    la sp, __stack_top
   0:	10000117          	auipc	sp,0x10000
   4:	00010113          	mv	sp,sp

    /* Optional: Clear Frame Pointer (s0) for debugging  */
    add s0, sp, zero
   8:	00010433          	add	s0,sp,zero

    /* ------------------------------------------------- */
    /* 2. Jump to C Code                                 */
    /* ------------------------------------------------- */
    jal ra, main
   c:	008000ef          	jal	14 <main>

    /* ------------------------------------------------- */
    /* 3. Trap Loop                                      */
    /* ------------------------------------------------- */
    /* If main() returns, spin here to prevent crashing. */
  10:	0000006f          	j	10 <_start+0x10>

00000014 <main>:
    int i, j;
    uint32_t temp;

    // 2. Initialize data LOCALLY on the Stack
    // This lives in the CPU's private memory (Slave 0), not the AXI Peripheral.
    uint32_t local_data[10] = {45, 12, 89, 2, 7, 63, 15, 99, 31, 20};
  14:	39800793          	li	a5,920
  18:	0087a703          	lw	a4,8(a5)
void main(void) {
  1c:	fd010113          	addi	sp,sp,-48 # fffffd0 <__bss_end+0xffffc10>
    uint32_t local_data[10] = {45, 12, 89, 2, 7, 63, 15, 99, 31, 20};
  20:	0007a603          	lw	a2,0(a5)
  24:	0047a683          	lw	a3,4(a5)
  28:	00e12823          	sw	a4,16(sp)
  2c:	0147a703          	lw	a4,20(a5)
  30:	00c12423          	sw	a2,8(sp)
  34:	00d12623          	sw	a3,12(sp)
  38:	00c7a603          	lw	a2,12(a5)
  3c:	0107a683          	lw	a3,16(a5)
  40:	00e12e23          	sw	a4,28(sp)
  44:	0207a703          	lw	a4,32(a5)
  48:	00c12a23          	sw	a2,20(sp)
  4c:	00d12c23          	sw	a3,24(sp)
  50:	0187a603          	lw	a2,24(a5)
  54:	01c7a683          	lw	a3,28(a5)
  58:	02e12423          	sw	a4,40(sp)
  5c:	0247a703          	lw	a4,36(a5)
  60:	02c12023          	sw	a2,32(sp)
  64:	02d12223          	sw	a3,36(sp)

    // 3. Perform Bubble Sort LOCALLY
    // No AXI transactions happen here. Zero bus latency.
    for (i = 0; i < 9; i++) {
  68:	00000793          	li	a5,0
        for (j = 0; j < 9 - i; j++) {
  6c:	00800513          	li	a0,8
    uint32_t local_data[10] = {45, 12, 89, 2, 7, 63, 15, 99, 31, 20};
  70:	02e12623          	sw	a4,44(sp)
        for (j = 0; j < 9 - i; j++) {
  74:	00200e93          	li	t4,2
  78:	00300e13          	li	t3,3
  7c:	00400313          	li	t1,4
  80:	00500893          	li	a7,5
  84:	00600813          	li	a6,6
  88:	00700593          	li	a1,7
            if (local_data[j] > local_data[j+1]) {
  8c:	00812603          	lw	a2,8(sp)
  90:	00c12703          	lw	a4,12(sp)
  94:	00c77e63          	bgeu	a4,a2,b0 <main+0x9c>
                temp = local_data[j];
                __asm__ volatile ("nop");
  98:	00000013          	nop
                local_data[j] = local_data[j+1];
  9c:	00c12703          	lw	a4,12(sp)
  a0:	00e12423          	sw	a4,8(sp)
                __asm__ volatile ("nop");
  a4:	00000013          	nop
                local_data[j+1] = temp;
  a8:	00c12623          	sw	a2,12(sp)
                __asm__ volatile ("nop");
  ac:	00000013          	nop
        for (j = 0; j < 9 - i; j++) {
  b0:	1ca78263          	beq	a5,a0,274 <main+0x260>
  b4:	00c12703          	lw	a4,12(sp)
  b8:	01012683          	lw	a3,16(sp)
            if (local_data[j] > local_data[j+1]) {
  bc:	06e6e863          	bltu	a3,a4,12c <main+0x118>
        for (j = 0; j < 9 - i; j++) {
  c0:	1ab78463          	beq	a5,a1,268 <main+0x254>
            if (local_data[j] > local_data[j+1]) {
  c4:	01412703          	lw	a4,20(sp)
  c8:	08d76663          	bltu	a4,a3,154 <main+0x140>
        for (j = 0; j < 9 - i; j++) {
  cc:	23078a63          	beq	a5,a6,300 <main+0x2ec>
            if (local_data[j] > local_data[j+1]) {
  d0:	01812683          	lw	a3,24(sp)
  d4:	0ae6e463          	bltu	a3,a4,17c <main+0x168>
        for (j = 0; j < 9 - i; j++) {
  d8:	23178e63          	beq	a5,a7,314 <main+0x300>
            if (local_data[j] > local_data[j+1]) {
  dc:	01c12703          	lw	a4,28(sp)
  e0:	0cd76263          	bltu	a4,a3,1a4 <main+0x190>
        for (j = 0; j < 9 - i; j++) {
  e4:	24678463          	beq	a5,t1,32c <main+0x318>
            if (local_data[j] > local_data[j+1]) {
  e8:	02012683          	lw	a3,32(sp)
  ec:	0ee6e063          	bltu	a3,a4,1cc <main+0x1b8>
        for (j = 0; j < 9 - i; j++) {
  f0:	25c78a63          	beq	a5,t3,344 <main+0x330>
            if (local_data[j] > local_data[j+1]) {
  f4:	02412703          	lw	a4,36(sp)
  f8:	0ed76e63          	bltu	a4,a3,1f4 <main+0x1e0>
        for (j = 0; j < 9 - i; j++) {
  fc:	27d78063          	beq	a5,t4,35c <main+0x348>
            if (local_data[j] > local_data[j+1]) {
 100:	02812683          	lw	a3,40(sp)
 104:	10e6ec63          	bltu	a3,a4,21c <main+0x208>
        for (j = 0; j < 9 - i; j++) {
 108:	26079c63          	bnez	a5,380 <main+0x36c>
            if (local_data[j] > local_data[j+1]) {
 10c:	02c12783          	lw	a5,44(sp)
 110:	12d7ea63          	bltu	a5,a3,244 <main+0x230>
 114:	00812603          	lw	a2,8(sp)
 118:	00c12703          	lw	a4,12(sp)
    for (i = 0; i < 9; i++) {
 11c:	00100793          	li	a5,1
            if (local_data[j] > local_data[j+1]) {
 120:	f6c76ce3          	bltu	a4,a2,98 <main+0x84>
 124:	01012683          	lw	a3,16(sp)
 128:	f8e6fce3          	bgeu	a3,a4,c0 <main+0xac>
                __asm__ volatile ("nop");
 12c:	00000013          	nop
                local_data[j] = local_data[j+1];
 130:	01012683          	lw	a3,16(sp)
 134:	00d12623          	sw	a3,12(sp)
                __asm__ volatile ("nop");
 138:	00000013          	nop
                local_data[j+1] = temp;
 13c:	00e12823          	sw	a4,16(sp)
                __asm__ volatile ("nop");
 140:	00000013          	nop
        for (j = 0; j < 9 - i; j++) {
 144:	10b78e63          	beq	a5,a1,260 <main+0x24c>
 148:	01012683          	lw	a3,16(sp)
            if (local_data[j] > local_data[j+1]) {
 14c:	01412703          	lw	a4,20(sp)
 150:	f6d77ee3          	bgeu	a4,a3,cc <main+0xb8>
                __asm__ volatile ("nop");
 154:	00000013          	nop
                local_data[j] = local_data[j+1];
 158:	01412703          	lw	a4,20(sp)
 15c:	00e12823          	sw	a4,16(sp)
                __asm__ volatile ("nop");
 160:	00000013          	nop
                local_data[j+1] = temp;
 164:	00d12a23          	sw	a3,20(sp)
                __asm__ volatile ("nop");
 168:	00000013          	nop
        for (j = 0; j < 9 - i; j++) {
 16c:	0f078a63          	beq	a5,a6,260 <main+0x24c>
 170:	01412703          	lw	a4,20(sp)
            if (local_data[j] > local_data[j+1]) {
 174:	01812683          	lw	a3,24(sp)
 178:	f6e6f0e3          	bgeu	a3,a4,d8 <main+0xc4>
                __asm__ volatile ("nop");
 17c:	00000013          	nop
                local_data[j] = local_data[j+1];
 180:	01812683          	lw	a3,24(sp)
 184:	00d12a23          	sw	a3,20(sp)
                __asm__ volatile ("nop");
 188:	00000013          	nop
                local_data[j+1] = temp;
 18c:	00e12c23          	sw	a4,24(sp)
                __asm__ volatile ("nop");
 190:	00000013          	nop
        for (j = 0; j < 9 - i; j++) {
 194:	0d178663          	beq	a5,a7,260 <main+0x24c>
 198:	01812683          	lw	a3,24(sp)
            if (local_data[j] > local_data[j+1]) {
 19c:	01c12703          	lw	a4,28(sp)
 1a0:	f4d772e3          	bgeu	a4,a3,e4 <main+0xd0>
                __asm__ volatile ("nop");
 1a4:	00000013          	nop
                local_data[j] = local_data[j+1];
 1a8:	01c12703          	lw	a4,28(sp)
 1ac:	00e12c23          	sw	a4,24(sp)
                __asm__ volatile ("nop");
 1b0:	00000013          	nop
                local_data[j+1] = temp;
 1b4:	00d12e23          	sw	a3,28(sp)
                __asm__ volatile ("nop");
 1b8:	00000013          	nop
        for (j = 0; j < 9 - i; j++) {
 1bc:	0a678263          	beq	a5,t1,260 <main+0x24c>
 1c0:	01c12703          	lw	a4,28(sp)
            if (local_data[j] > local_data[j+1]) {
 1c4:	02012683          	lw	a3,32(sp)
 1c8:	f2e6f4e3          	bgeu	a3,a4,f0 <main+0xdc>
                __asm__ volatile ("nop");
 1cc:	00000013          	nop
                local_data[j] = local_data[j+1];
 1d0:	02012683          	lw	a3,32(sp)
 1d4:	00d12e23          	sw	a3,28(sp)
                __asm__ volatile ("nop");
 1d8:	00000013          	nop
                local_data[j+1] = temp;
 1dc:	02e12023          	sw	a4,32(sp)
                __asm__ volatile ("nop");
 1e0:	00000013          	nop
        for (j = 0; j < 9 - i; j++) {
 1e4:	07c78e63          	beq	a5,t3,260 <main+0x24c>
 1e8:	02012683          	lw	a3,32(sp)
            if (local_data[j] > local_data[j+1]) {
 1ec:	02412703          	lw	a4,36(sp)
 1f0:	f0d776e3          	bgeu	a4,a3,fc <main+0xe8>
                __asm__ volatile ("nop");
 1f4:	00000013          	nop
                local_data[j] = local_data[j+1];
 1f8:	02412703          	lw	a4,36(sp)
 1fc:	02e12023          	sw	a4,32(sp)
                __asm__ volatile ("nop");
 200:	00000013          	nop
                local_data[j+1] = temp;
 204:	02d12223          	sw	a3,36(sp)
                __asm__ volatile ("nop");
 208:	00000013          	nop
        for (j = 0; j < 9 - i; j++) {
 20c:	05d78a63          	beq	a5,t4,260 <main+0x24c>
 210:	02412703          	lw	a4,36(sp)
            if (local_data[j] > local_data[j+1]) {
 214:	02812683          	lw	a3,40(sp)
 218:	eee6f8e3          	bgeu	a3,a4,108 <main+0xf4>
                __asm__ volatile ("nop");
 21c:	00000013          	nop
                local_data[j] = local_data[j+1];
 220:	02812683          	lw	a3,40(sp)
 224:	02d12223          	sw	a3,36(sp)
                __asm__ volatile ("nop");
 228:	00000013          	nop
                local_data[j+1] = temp;
 22c:	02e12423          	sw	a4,40(sp)
                __asm__ volatile ("nop");
 230:	00000013          	nop
        for (j = 0; j < 9 - i; j++) {
 234:	14079063          	bnez	a5,374 <main+0x360>
 238:	02812683          	lw	a3,40(sp)
            if (local_data[j] > local_data[j+1]) {
 23c:	02c12783          	lw	a5,44(sp)
 240:	ecd7fae3          	bgeu	a5,a3,114 <main+0x100>
                __asm__ volatile ("nop");
 244:	00000013          	nop
                local_data[j] = local_data[j+1];
 248:	02c12783          	lw	a5,44(sp)
 24c:	02f12423          	sw	a5,40(sp)
                __asm__ volatile ("nop");
 250:	00000013          	nop
                local_data[j+1] = temp;
 254:	02d12623          	sw	a3,44(sp)
                __asm__ volatile ("nop");
 258:	00000013          	nop
        for (j = 0; j < 9 - i; j++) {
 25c:	00000793          	li	a5,0
    for (i = 0; i < 9; i++) {
 260:	00178793          	addi	a5,a5,1
 264:	e29ff06f          	j	8c <main+0x78>
            if (local_data[j] > local_data[j+1]) {
 268:	00812603          	lw	a2,8(sp)
    for (i = 0; i < 9; i++) {
 26c:	00800793          	li	a5,8
            if (local_data[j] > local_data[j+1]) {
 270:	e2c764e3          	bltu	a4,a2,98 <main+0x84>
            }
        }
    }
    
    // Optional: Write the debug marker if you still want it
    axi_output[19] = 0xAAAAAAAA; 
 274:	aaaab737          	lui	a4,0xaaaab
 278:	100017b7          	lui	a5,0x10001
 27c:	aaa70713          	addi	a4,a4,-1366 # aaaaaaaa <__stack_top+0x9aaaaaaa>
 280:	04e7a623          	sw	a4,76(a5) # 1000104c <__stack_top+0x104c>

    // 4. Burst Write the Result to Dummy Memory
    // This generates a clean sequence of Store (Write) transactions.
    // We write to offset 20 just like your previous code.
    for (i = 0; i < 10; i++) {
        axi_output[20 + i] = local_data[i]; 
 284:	00812703          	lw	a4,8(sp)
 288:	100017b7          	lui	a5,0x10001
 28c:	04e7a823          	sw	a4,80(a5) # 10001050 <__stack_top+0x1050>
 290:	00c12703          	lw	a4,12(sp)
 294:	100017b7          	lui	a5,0x10001
 298:	04e7aa23          	sw	a4,84(a5) # 10001054 <__stack_top+0x1054>
 29c:	01012703          	lw	a4,16(sp)
 2a0:	100017b7          	lui	a5,0x10001
 2a4:	04e7ac23          	sw	a4,88(a5) # 10001058 <__stack_top+0x1058>
 2a8:	01412703          	lw	a4,20(sp)
 2ac:	100017b7          	lui	a5,0x10001
 2b0:	04e7ae23          	sw	a4,92(a5) # 1000105c <__stack_top+0x105c>
 2b4:	01812703          	lw	a4,24(sp)
 2b8:	100017b7          	lui	a5,0x10001
 2bc:	06e7a023          	sw	a4,96(a5) # 10001060 <__stack_top+0x1060>
 2c0:	01c12703          	lw	a4,28(sp)
 2c4:	100017b7          	lui	a5,0x10001
 2c8:	06e7a223          	sw	a4,100(a5) # 10001064 <__stack_top+0x1064>
 2cc:	02012703          	lw	a4,32(sp)
 2d0:	100017b7          	lui	a5,0x10001
 2d4:	06e7a423          	sw	a4,104(a5) # 10001068 <__stack_top+0x1068>
 2d8:	02412703          	lw	a4,36(sp)
 2dc:	100017b7          	lui	a5,0x10001
 2e0:	06e7a623          	sw	a4,108(a5) # 1000106c <__stack_top+0x106c>
 2e4:	02812703          	lw	a4,40(sp)
 2e8:	100017b7          	lui	a5,0x10001
 2ec:	06e7a823          	sw	a4,112(a5) # 10001070 <__stack_top+0x1070>
 2f0:	02c12703          	lw	a4,44(sp)
 2f4:	100017b7          	lui	a5,0x10001
 2f8:	06e7aa23          	sw	a4,116(a5) # 10001074 <__stack_top+0x1074>
    }

    // Spin forever
    while(1);
 2fc:	0000006f          	j	2fc <main+0x2e8>
            if (local_data[j] > local_data[j+1]) {
 300:	00812603          	lw	a2,8(sp)
 304:	00c12703          	lw	a4,12(sp)
    for (i = 0; i < 9; i++) {
 308:	00700793          	li	a5,7
            if (local_data[j] > local_data[j+1]) {
 30c:	d8c766e3          	bltu	a4,a2,98 <main+0x84>
 310:	dadff06f          	j	bc <main+0xa8>
 314:	00812603          	lw	a2,8(sp)
 318:	00c12703          	lw	a4,12(sp)
    for (i = 0; i < 9; i++) {
 31c:	00600793          	li	a5,6
            if (local_data[j] > local_data[j+1]) {
 320:	d6c76ce3          	bltu	a4,a2,98 <main+0x84>
 324:	01012683          	lw	a3,16(sp)
 328:	e01ff06f          	j	128 <main+0x114>
 32c:	00812603          	lw	a2,8(sp)
 330:	00c12703          	lw	a4,12(sp)
    for (i = 0; i < 9; i++) {
 334:	00500793          	li	a5,5
            if (local_data[j] > local_data[j+1]) {
 338:	d6c760e3          	bltu	a4,a2,98 <main+0x84>
 33c:	01012683          	lw	a3,16(sp)
 340:	de9ff06f          	j	128 <main+0x114>
 344:	00812603          	lw	a2,8(sp)
 348:	00c12703          	lw	a4,12(sp)
    for (i = 0; i < 9; i++) {
 34c:	00400793          	li	a5,4
            if (local_data[j] > local_data[j+1]) {
 350:	d4c764e3          	bltu	a4,a2,98 <main+0x84>
 354:	01012683          	lw	a3,16(sp)
 358:	dd1ff06f          	j	128 <main+0x114>
 35c:	00812603          	lw	a2,8(sp)
 360:	00c12703          	lw	a4,12(sp)
    for (i = 0; i < 9; i++) {
 364:	00300793          	li	a5,3
            if (local_data[j] > local_data[j+1]) {
 368:	d2c768e3          	bltu	a4,a2,98 <main+0x84>
 36c:	01012683          	lw	a3,16(sp)
 370:	db9ff06f          	j	128 <main+0x114>
        for (j = 0; j < 9 - i; j++) {
 374:	00100793          	li	a5,1
    for (i = 0; i < 9; i++) {
 378:	00178793          	addi	a5,a5,1
 37c:	d11ff06f          	j	8c <main+0x78>
            if (local_data[j] > local_data[j+1]) {
 380:	00812603          	lw	a2,8(sp)
 384:	00c12703          	lw	a4,12(sp)
    for (i = 0; i < 9; i++) {
 388:	00200793          	li	a5,2
            if (local_data[j] > local_data[j+1]) {
 38c:	d0c766e3          	bltu	a4,a2,98 <main+0x84>
 390:	01012683          	lw	a3,16(sp)
 394:	d95ff06f          	j	128 <main+0x114>
