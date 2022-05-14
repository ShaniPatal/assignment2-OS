
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8d013103          	ld	sp,-1840(sp) # 800088d0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	16c78793          	addi	a5,a5,364 # 800061d0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	e0478793          	addi	a5,a5,-508 # 80000eb2 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	7b4080e7          	jalr	1972(ra) # 800028e0 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	bd2080e7          	jalr	-1070(ra) # 80001d96 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	242080e7          	jalr	578(ra) # 80002416 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	67a080e7          	jalr	1658(ra) # 8000288a <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a7e080e7          	jalr	-1410(ra) # 80000caa <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a68080e7          	jalr	-1432(ra) # 80000caa <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	644080e7          	jalr	1604(ra) # 80002936 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	9a8080e7          	jalr	-1624(ra) # 80000caa <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	176080e7          	jalr	374(ra) # 800025bc <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	7e878793          	addi	a5,a5,2024 # 80021c60 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b6450513          	addi	a0,a0,-1180 # 800080d0 <digits+0x90>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	546080e7          	jalr	1350(ra) # 80000caa <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	41c080e7          	jalr	1052(ra) # 80000c4a <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	d1c080e7          	jalr	-740(ra) # 800025bc <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	aea080e7          	jalr	-1302(ra) # 80002416 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	342080e7          	jalr	834(ra) # 80000caa <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2c4080e7          	jalr	708(ra) # 80000caa <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2e0080e7          	jalr	736(ra) # 80000d04 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	260080e7          	jalr	608(ra) # 80000caa <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	18a080e7          	jalr	394(ra) # 80000caa <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1d6080e7          	jalr	470(ra) # 80000d04 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	160080e7          	jalr	352(ra) # 80000caa <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	1f4080e7          	jalr	500(ra) # 80001d72 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	1c2080e7          	jalr	450(ra) # 80001d72 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	1b6080e7          	jalr	438(ra) # 80001d72 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	19e080e7          	jalr	414(ra) # 80001d72 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk)){
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk)){
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	15e080e7          	jalr	350(ra) # 80001d72 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
  printf("%s \n", lk->name);
    80000c28:	648c                	ld	a1,8(s1)
    80000c2a:	00007517          	auipc	a0,0x7
    80000c2e:	44650513          	addi	a0,a0,1094 # 80008070 <digits+0x30>
    80000c32:	00000097          	auipc	ra,0x0
    80000c36:	956080e7          	jalr	-1706(ra) # 80000588 <printf>
    panic("acquire");
    80000c3a:	00007517          	auipc	a0,0x7
    80000c3e:	43e50513          	addi	a0,a0,1086 # 80008078 <digits+0x38>
    80000c42:	00000097          	auipc	ra,0x0
    80000c46:	8fc080e7          	jalr	-1796(ra) # 8000053e <panic>

0000000080000c4a <pop_off>:

void
pop_off(void)
{
    80000c4a:	1141                	addi	sp,sp,-16
    80000c4c:	e406                	sd	ra,8(sp)
    80000c4e:	e022                	sd	s0,0(sp)
    80000c50:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c52:	00001097          	auipc	ra,0x1
    80000c56:	120080e7          	jalr	288(ra) # 80001d72 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c5a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c5e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c60:	e78d                	bnez	a5,80000c8a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c62:	5d3c                	lw	a5,120(a0)
    80000c64:	02f05b63          	blez	a5,80000c9a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c68:	37fd                	addiw	a5,a5,-1
    80000c6a:	0007871b          	sext.w	a4,a5
    80000c6e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c70:	eb09                	bnez	a4,80000c82 <pop_off+0x38>
    80000c72:	5d7c                	lw	a5,124(a0)
    80000c74:	c799                	beqz	a5,80000c82 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c76:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c7a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c7e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c82:	60a2                	ld	ra,8(sp)
    80000c84:	6402                	ld	s0,0(sp)
    80000c86:	0141                	addi	sp,sp,16
    80000c88:	8082                	ret
    panic("pop_off - interruptible");
    80000c8a:	00007517          	auipc	a0,0x7
    80000c8e:	3f650513          	addi	a0,a0,1014 # 80008080 <digits+0x40>
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	8ac080e7          	jalr	-1876(ra) # 8000053e <panic>
    panic("pop_off");
    80000c9a:	00007517          	auipc	a0,0x7
    80000c9e:	3fe50513          	addi	a0,a0,1022 # 80008098 <digits+0x58>
    80000ca2:	00000097          	auipc	ra,0x0
    80000ca6:	89c080e7          	jalr	-1892(ra) # 8000053e <panic>

0000000080000caa <release>:
{
    80000caa:	1101                	addi	sp,sp,-32
    80000cac:	ec06                	sd	ra,24(sp)
    80000cae:	e822                	sd	s0,16(sp)
    80000cb0:	e426                	sd	s1,8(sp)
    80000cb2:	1000                	addi	s0,sp,32
    80000cb4:	84aa                	mv	s1,a0
  if(!holding(lk)){
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	eb4080e7          	jalr	-332(ra) # 80000b6a <holding>
    80000cbe:	c115                	beqz	a0,80000ce2 <release+0x38>
  lk->cpu = 0;
    80000cc0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cc4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cc8:	0f50000f          	fence	iorw,ow
    80000ccc:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	f7a080e7          	jalr	-134(ra) # 80000c4a <pop_off>
}
    80000cd8:	60e2                	ld	ra,24(sp)
    80000cda:	6442                	ld	s0,16(sp)
    80000cdc:	64a2                	ld	s1,8(sp)
    80000cde:	6105                	addi	sp,sp,32
    80000ce0:	8082                	ret
    printf("%s \n", lk->name);
    80000ce2:	648c                	ld	a1,8(s1)
    80000ce4:	00007517          	auipc	a0,0x7
    80000ce8:	38c50513          	addi	a0,a0,908 # 80008070 <digits+0x30>
    80000cec:	00000097          	auipc	ra,0x0
    80000cf0:	89c080e7          	jalr	-1892(ra) # 80000588 <printf>
    panic("release");
    80000cf4:	00007517          	auipc	a0,0x7
    80000cf8:	3ac50513          	addi	a0,a0,940 # 800080a0 <digits+0x60>
    80000cfc:	00000097          	auipc	ra,0x0
    80000d00:	842080e7          	jalr	-1982(ra) # 8000053e <panic>

0000000080000d04 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d04:	1141                	addi	sp,sp,-16
    80000d06:	e422                	sd	s0,8(sp)
    80000d08:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d0a:	ce09                	beqz	a2,80000d24 <memset+0x20>
    80000d0c:	87aa                	mv	a5,a0
    80000d0e:	fff6071b          	addiw	a4,a2,-1
    80000d12:	1702                	slli	a4,a4,0x20
    80000d14:	9301                	srli	a4,a4,0x20
    80000d16:	0705                	addi	a4,a4,1
    80000d18:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d1a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d1e:	0785                	addi	a5,a5,1
    80000d20:	fee79de3          	bne	a5,a4,80000d1a <memset+0x16>
  }
  return dst;
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret

0000000080000d2a <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d2a:	1141                	addi	sp,sp,-16
    80000d2c:	e422                	sd	s0,8(sp)
    80000d2e:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d30:	ca05                	beqz	a2,80000d60 <memcmp+0x36>
    80000d32:	fff6069b          	addiw	a3,a2,-1
    80000d36:	1682                	slli	a3,a3,0x20
    80000d38:	9281                	srli	a3,a3,0x20
    80000d3a:	0685                	addi	a3,a3,1
    80000d3c:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d3e:	00054783          	lbu	a5,0(a0)
    80000d42:	0005c703          	lbu	a4,0(a1)
    80000d46:	00e79863          	bne	a5,a4,80000d56 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d4a:	0505                	addi	a0,a0,1
    80000d4c:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d4e:	fed518e3          	bne	a0,a3,80000d3e <memcmp+0x14>
  }

  return 0;
    80000d52:	4501                	li	a0,0
    80000d54:	a019                	j	80000d5a <memcmp+0x30>
      return *s1 - *s2;
    80000d56:	40e7853b          	subw	a0,a5,a4
}
    80000d5a:	6422                	ld	s0,8(sp)
    80000d5c:	0141                	addi	sp,sp,16
    80000d5e:	8082                	ret
  return 0;
    80000d60:	4501                	li	a0,0
    80000d62:	bfe5                	j	80000d5a <memcmp+0x30>

0000000080000d64 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d64:	1141                	addi	sp,sp,-16
    80000d66:	e422                	sd	s0,8(sp)
    80000d68:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d6a:	ca0d                	beqz	a2,80000d9c <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d6c:	00a5f963          	bgeu	a1,a0,80000d7e <memmove+0x1a>
    80000d70:	02061693          	slli	a3,a2,0x20
    80000d74:	9281                	srli	a3,a3,0x20
    80000d76:	00d58733          	add	a4,a1,a3
    80000d7a:	02e56463          	bltu	a0,a4,80000da2 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d7e:	fff6079b          	addiw	a5,a2,-1
    80000d82:	1782                	slli	a5,a5,0x20
    80000d84:	9381                	srli	a5,a5,0x20
    80000d86:	0785                	addi	a5,a5,1
    80000d88:	97ae                	add	a5,a5,a1
    80000d8a:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d8c:	0585                	addi	a1,a1,1
    80000d8e:	0705                	addi	a4,a4,1
    80000d90:	fff5c683          	lbu	a3,-1(a1)
    80000d94:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d98:	fef59ae3          	bne	a1,a5,80000d8c <memmove+0x28>

  return dst;
}
    80000d9c:	6422                	ld	s0,8(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret
    d += n;
    80000da2:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000da4:	fff6079b          	addiw	a5,a2,-1
    80000da8:	1782                	slli	a5,a5,0x20
    80000daa:	9381                	srli	a5,a5,0x20
    80000dac:	fff7c793          	not	a5,a5
    80000db0:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000db2:	177d                	addi	a4,a4,-1
    80000db4:	16fd                	addi	a3,a3,-1
    80000db6:	00074603          	lbu	a2,0(a4)
    80000dba:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000dbe:	fef71ae3          	bne	a4,a5,80000db2 <memmove+0x4e>
    80000dc2:	bfe9                	j	80000d9c <memmove+0x38>

0000000080000dc4 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dc4:	1141                	addi	sp,sp,-16
    80000dc6:	e406                	sd	ra,8(sp)
    80000dc8:	e022                	sd	s0,0(sp)
    80000dca:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dcc:	00000097          	auipc	ra,0x0
    80000dd0:	f98080e7          	jalr	-104(ra) # 80000d64 <memmove>
}
    80000dd4:	60a2                	ld	ra,8(sp)
    80000dd6:	6402                	ld	s0,0(sp)
    80000dd8:	0141                	addi	sp,sp,16
    80000dda:	8082                	ret

0000000080000ddc <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000ddc:	1141                	addi	sp,sp,-16
    80000dde:	e422                	sd	s0,8(sp)
    80000de0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000de2:	ce11                	beqz	a2,80000dfe <strncmp+0x22>
    80000de4:	00054783          	lbu	a5,0(a0)
    80000de8:	cf89                	beqz	a5,80000e02 <strncmp+0x26>
    80000dea:	0005c703          	lbu	a4,0(a1)
    80000dee:	00f71a63          	bne	a4,a5,80000e02 <strncmp+0x26>
    n--, p++, q++;
    80000df2:	367d                	addiw	a2,a2,-1
    80000df4:	0505                	addi	a0,a0,1
    80000df6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000df8:	f675                	bnez	a2,80000de4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dfa:	4501                	li	a0,0
    80000dfc:	a809                	j	80000e0e <strncmp+0x32>
    80000dfe:	4501                	li	a0,0
    80000e00:	a039                	j	80000e0e <strncmp+0x32>
  if(n == 0)
    80000e02:	ca09                	beqz	a2,80000e14 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e04:	00054503          	lbu	a0,0(a0)
    80000e08:	0005c783          	lbu	a5,0(a1)
    80000e0c:	9d1d                	subw	a0,a0,a5
}
    80000e0e:	6422                	ld	s0,8(sp)
    80000e10:	0141                	addi	sp,sp,16
    80000e12:	8082                	ret
    return 0;
    80000e14:	4501                	li	a0,0
    80000e16:	bfe5                	j	80000e0e <strncmp+0x32>

0000000080000e18 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e18:	1141                	addi	sp,sp,-16
    80000e1a:	e422                	sd	s0,8(sp)
    80000e1c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e1e:	872a                	mv	a4,a0
    80000e20:	8832                	mv	a6,a2
    80000e22:	367d                	addiw	a2,a2,-1
    80000e24:	01005963          	blez	a6,80000e36 <strncpy+0x1e>
    80000e28:	0705                	addi	a4,a4,1
    80000e2a:	0005c783          	lbu	a5,0(a1)
    80000e2e:	fef70fa3          	sb	a5,-1(a4)
    80000e32:	0585                	addi	a1,a1,1
    80000e34:	f7f5                	bnez	a5,80000e20 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e36:	00c05d63          	blez	a2,80000e50 <strncpy+0x38>
    80000e3a:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e3c:	0685                	addi	a3,a3,1
    80000e3e:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e42:	fff6c793          	not	a5,a3
    80000e46:	9fb9                	addw	a5,a5,a4
    80000e48:	010787bb          	addw	a5,a5,a6
    80000e4c:	fef048e3          	bgtz	a5,80000e3c <strncpy+0x24>
  return os;
}
    80000e50:	6422                	ld	s0,8(sp)
    80000e52:	0141                	addi	sp,sp,16
    80000e54:	8082                	ret

0000000080000e56 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e56:	1141                	addi	sp,sp,-16
    80000e58:	e422                	sd	s0,8(sp)
    80000e5a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e5c:	02c05363          	blez	a2,80000e82 <safestrcpy+0x2c>
    80000e60:	fff6069b          	addiw	a3,a2,-1
    80000e64:	1682                	slli	a3,a3,0x20
    80000e66:	9281                	srli	a3,a3,0x20
    80000e68:	96ae                	add	a3,a3,a1
    80000e6a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e6c:	00d58963          	beq	a1,a3,80000e7e <safestrcpy+0x28>
    80000e70:	0585                	addi	a1,a1,1
    80000e72:	0785                	addi	a5,a5,1
    80000e74:	fff5c703          	lbu	a4,-1(a1)
    80000e78:	fee78fa3          	sb	a4,-1(a5)
    80000e7c:	fb65                	bnez	a4,80000e6c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e7e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e82:	6422                	ld	s0,8(sp)
    80000e84:	0141                	addi	sp,sp,16
    80000e86:	8082                	ret

0000000080000e88 <strlen>:

int
strlen(const char *s)
{
    80000e88:	1141                	addi	sp,sp,-16
    80000e8a:	e422                	sd	s0,8(sp)
    80000e8c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e8e:	00054783          	lbu	a5,0(a0)
    80000e92:	cf91                	beqz	a5,80000eae <strlen+0x26>
    80000e94:	0505                	addi	a0,a0,1
    80000e96:	87aa                	mv	a5,a0
    80000e98:	4685                	li	a3,1
    80000e9a:	9e89                	subw	a3,a3,a0
    80000e9c:	00f6853b          	addw	a0,a3,a5
    80000ea0:	0785                	addi	a5,a5,1
    80000ea2:	fff7c703          	lbu	a4,-1(a5)
    80000ea6:	fb7d                	bnez	a4,80000e9c <strlen+0x14>
    ;
  return n;
}
    80000ea8:	6422                	ld	s0,8(sp)
    80000eaa:	0141                	addi	sp,sp,16
    80000eac:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eae:	4501                	li	a0,0
    80000eb0:	bfe5                	j	80000ea8 <strlen+0x20>

0000000080000eb2 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000eb2:	1141                	addi	sp,sp,-16
    80000eb4:	e406                	sd	ra,8(sp)
    80000eb6:	e022                	sd	s0,0(sp)
    80000eb8:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eba:	00001097          	auipc	ra,0x1
    80000ebe:	ea8080e7          	jalr	-344(ra) # 80001d62 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ec2:	00008717          	auipc	a4,0x8
    80000ec6:	15670713          	addi	a4,a4,342 # 80009018 <started>
  if(cpuid() == 0){
    80000eca:	c139                	beqz	a0,80000f10 <main+0x5e>
    while(started == 0)
    80000ecc:	431c                	lw	a5,0(a4)
    80000ece:	2781                	sext.w	a5,a5
    80000ed0:	dff5                	beqz	a5,80000ecc <main+0x1a>
      ;
    __sync_synchronize();
    80000ed2:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ed6:	00001097          	auipc	ra,0x1
    80000eda:	e8c080e7          	jalr	-372(ra) # 80001d62 <cpuid>
    80000ede:	85aa                	mv	a1,a0
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e050513          	addi	a0,a0,480 # 800080c0 <digits+0x80>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	6a0080e7          	jalr	1696(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ef0:	00000097          	auipc	ra,0x0
    80000ef4:	0d8080e7          	jalr	216(ra) # 80000fc8 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ef8:	00002097          	auipc	ra,0x2
    80000efc:	d76080e7          	jalr	-650(ra) # 80002c6e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f00:	00005097          	auipc	ra,0x5
    80000f04:	310080e7          	jalr	784(ra) # 80006210 <plicinithart>
  }

  scheduler();        
    80000f08:	00001097          	auipc	ra,0x1
    80000f0c:	2ec080e7          	jalr	748(ra) # 800021f4 <scheduler>
    consoleinit();
    80000f10:	fffff097          	auipc	ra,0xfffff
    80000f14:	540080e7          	jalr	1344(ra) # 80000450 <consoleinit>
    printfinit();
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	856080e7          	jalr	-1962(ra) # 8000076e <printfinit>
    printf("\n");
    80000f20:	00007517          	auipc	a0,0x7
    80000f24:	1b050513          	addi	a0,a0,432 # 800080d0 <digits+0x90>
    80000f28:	fffff097          	auipc	ra,0xfffff
    80000f2c:	660080e7          	jalr	1632(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f30:	00007517          	auipc	a0,0x7
    80000f34:	17850513          	addi	a0,a0,376 # 800080a8 <digits+0x68>
    80000f38:	fffff097          	auipc	ra,0xfffff
    80000f3c:	650080e7          	jalr	1616(ra) # 80000588 <printf>
    printf("\n");
    80000f40:	00007517          	auipc	a0,0x7
    80000f44:	19050513          	addi	a0,a0,400 # 800080d0 <digits+0x90>
    80000f48:	fffff097          	auipc	ra,0xfffff
    80000f4c:	640080e7          	jalr	1600(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f50:	00000097          	auipc	ra,0x0
    80000f54:	b68080e7          	jalr	-1176(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f58:	00000097          	auipc	ra,0x0
    80000f5c:	322080e7          	jalr	802(ra) # 8000127a <kvminit>
    kvminithart();   // turn on paging
    80000f60:	00000097          	auipc	ra,0x0
    80000f64:	068080e7          	jalr	104(ra) # 80000fc8 <kvminithart>
    procinit();      // process table
    80000f68:	00001097          	auipc	ra,0x1
    80000f6c:	cf4080e7          	jalr	-780(ra) # 80001c5c <procinit>
    trapinit();      // trap vectors
    80000f70:	00002097          	auipc	ra,0x2
    80000f74:	cd6080e7          	jalr	-810(ra) # 80002c46 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f78:	00002097          	auipc	ra,0x2
    80000f7c:	cf6080e7          	jalr	-778(ra) # 80002c6e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f80:	00005097          	auipc	ra,0x5
    80000f84:	27a080e7          	jalr	634(ra) # 800061fa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f88:	00005097          	auipc	ra,0x5
    80000f8c:	288080e7          	jalr	648(ra) # 80006210 <plicinithart>
    binit();         // buffer cache
    80000f90:	00002097          	auipc	ra,0x2
    80000f94:	46a080e7          	jalr	1130(ra) # 800033fa <binit>
    iinit();         // inode table
    80000f98:	00003097          	auipc	ra,0x3
    80000f9c:	afa080e7          	jalr	-1286(ra) # 80003a92 <iinit>
    fileinit();      // file table
    80000fa0:	00004097          	auipc	ra,0x4
    80000fa4:	aa4080e7          	jalr	-1372(ra) # 80004a44 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa8:	00005097          	auipc	ra,0x5
    80000fac:	38a080e7          	jalr	906(ra) # 80006332 <virtio_disk_init>
    userinit();      // first user process
    80000fb0:	00001097          	auipc	ra,0x1
    80000fb4:	134080e7          	jalr	308(ra) # 800020e4 <userinit>
    __sync_synchronize();
    80000fb8:	0ff0000f          	fence
    started = 1;
    80000fbc:	4785                	li	a5,1
    80000fbe:	00008717          	auipc	a4,0x8
    80000fc2:	04f72d23          	sw	a5,90(a4) # 80009018 <started>
    80000fc6:	b789                	j	80000f08 <main+0x56>

0000000080000fc8 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fc8:	1141                	addi	sp,sp,-16
    80000fca:	e422                	sd	s0,8(sp)
    80000fcc:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fce:	00008797          	auipc	a5,0x8
    80000fd2:	0527b783          	ld	a5,82(a5) # 80009020 <kernel_pagetable>
    80000fd6:	83b1                	srli	a5,a5,0xc
    80000fd8:	577d                	li	a4,-1
    80000fda:	177e                	slli	a4,a4,0x3f
    80000fdc:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fde:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fe2:	12000073          	sfence.vma
  sfence_vma();
}
    80000fe6:	6422                	ld	s0,8(sp)
    80000fe8:	0141                	addi	sp,sp,16
    80000fea:	8082                	ret

0000000080000fec <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fec:	7139                	addi	sp,sp,-64
    80000fee:	fc06                	sd	ra,56(sp)
    80000ff0:	f822                	sd	s0,48(sp)
    80000ff2:	f426                	sd	s1,40(sp)
    80000ff4:	f04a                	sd	s2,32(sp)
    80000ff6:	ec4e                	sd	s3,24(sp)
    80000ff8:	e852                	sd	s4,16(sp)
    80000ffa:	e456                	sd	s5,8(sp)
    80000ffc:	e05a                	sd	s6,0(sp)
    80000ffe:	0080                	addi	s0,sp,64
    80001000:	84aa                	mv	s1,a0
    80001002:	89ae                	mv	s3,a1
    80001004:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001006:	57fd                	li	a5,-1
    80001008:	83e9                	srli	a5,a5,0x1a
    8000100a:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000100c:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000100e:	04b7f263          	bgeu	a5,a1,80001052 <walk+0x66>
    panic("walk");
    80001012:	00007517          	auipc	a0,0x7
    80001016:	0c650513          	addi	a0,a0,198 # 800080d8 <digits+0x98>
    8000101a:	fffff097          	auipc	ra,0xfffff
    8000101e:	524080e7          	jalr	1316(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001022:	060a8663          	beqz	s5,8000108e <walk+0xa2>
    80001026:	00000097          	auipc	ra,0x0
    8000102a:	ace080e7          	jalr	-1330(ra) # 80000af4 <kalloc>
    8000102e:	84aa                	mv	s1,a0
    80001030:	c529                	beqz	a0,8000107a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001032:	6605                	lui	a2,0x1
    80001034:	4581                	li	a1,0
    80001036:	00000097          	auipc	ra,0x0
    8000103a:	cce080e7          	jalr	-818(ra) # 80000d04 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000103e:	00c4d793          	srli	a5,s1,0xc
    80001042:	07aa                	slli	a5,a5,0xa
    80001044:	0017e793          	ori	a5,a5,1
    80001048:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000104c:	3a5d                	addiw	s4,s4,-9
    8000104e:	036a0063          	beq	s4,s6,8000106e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001052:	0149d933          	srl	s2,s3,s4
    80001056:	1ff97913          	andi	s2,s2,511
    8000105a:	090e                	slli	s2,s2,0x3
    8000105c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000105e:	00093483          	ld	s1,0(s2)
    80001062:	0014f793          	andi	a5,s1,1
    80001066:	dfd5                	beqz	a5,80001022 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001068:	80a9                	srli	s1,s1,0xa
    8000106a:	04b2                	slli	s1,s1,0xc
    8000106c:	b7c5                	j	8000104c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000106e:	00c9d513          	srli	a0,s3,0xc
    80001072:	1ff57513          	andi	a0,a0,511
    80001076:	050e                	slli	a0,a0,0x3
    80001078:	9526                	add	a0,a0,s1
}
    8000107a:	70e2                	ld	ra,56(sp)
    8000107c:	7442                	ld	s0,48(sp)
    8000107e:	74a2                	ld	s1,40(sp)
    80001080:	7902                	ld	s2,32(sp)
    80001082:	69e2                	ld	s3,24(sp)
    80001084:	6a42                	ld	s4,16(sp)
    80001086:	6aa2                	ld	s5,8(sp)
    80001088:	6b02                	ld	s6,0(sp)
    8000108a:	6121                	addi	sp,sp,64
    8000108c:	8082                	ret
        return 0;
    8000108e:	4501                	li	a0,0
    80001090:	b7ed                	j	8000107a <walk+0x8e>

0000000080001092 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001092:	57fd                	li	a5,-1
    80001094:	83e9                	srli	a5,a5,0x1a
    80001096:	00b7f463          	bgeu	a5,a1,8000109e <walkaddr+0xc>
    return 0;
    8000109a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000109c:	8082                	ret
{
    8000109e:	1141                	addi	sp,sp,-16
    800010a0:	e406                	sd	ra,8(sp)
    800010a2:	e022                	sd	s0,0(sp)
    800010a4:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010a6:	4601                	li	a2,0
    800010a8:	00000097          	auipc	ra,0x0
    800010ac:	f44080e7          	jalr	-188(ra) # 80000fec <walk>
  if(pte == 0)
    800010b0:	c105                	beqz	a0,800010d0 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010b2:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010b4:	0117f693          	andi	a3,a5,17
    800010b8:	4745                	li	a4,17
    return 0;
    800010ba:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010bc:	00e68663          	beq	a3,a4,800010c8 <walkaddr+0x36>
}
    800010c0:	60a2                	ld	ra,8(sp)
    800010c2:	6402                	ld	s0,0(sp)
    800010c4:	0141                	addi	sp,sp,16
    800010c6:	8082                	ret
  pa = PTE2PA(*pte);
    800010c8:	00a7d513          	srli	a0,a5,0xa
    800010cc:	0532                	slli	a0,a0,0xc
  return pa;
    800010ce:	bfcd                	j	800010c0 <walkaddr+0x2e>
    return 0;
    800010d0:	4501                	li	a0,0
    800010d2:	b7fd                	j	800010c0 <walkaddr+0x2e>

00000000800010d4 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010d4:	715d                	addi	sp,sp,-80
    800010d6:	e486                	sd	ra,72(sp)
    800010d8:	e0a2                	sd	s0,64(sp)
    800010da:	fc26                	sd	s1,56(sp)
    800010dc:	f84a                	sd	s2,48(sp)
    800010de:	f44e                	sd	s3,40(sp)
    800010e0:	f052                	sd	s4,32(sp)
    800010e2:	ec56                	sd	s5,24(sp)
    800010e4:	e85a                	sd	s6,16(sp)
    800010e6:	e45e                	sd	s7,8(sp)
    800010e8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ea:	c205                	beqz	a2,8000110a <mappages+0x36>
    800010ec:	8aaa                	mv	s5,a0
    800010ee:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010f0:	77fd                	lui	a5,0xfffff
    800010f2:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010f6:	15fd                	addi	a1,a1,-1
    800010f8:	00c589b3          	add	s3,a1,a2
    800010fc:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    80001100:	8952                	mv	s2,s4
    80001102:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001106:	6b85                	lui	s7,0x1
    80001108:	a015                	j	8000112c <mappages+0x58>
    panic("mappages: size");
    8000110a:	00007517          	auipc	a0,0x7
    8000110e:	fd650513          	addi	a0,a0,-42 # 800080e0 <digits+0xa0>
    80001112:	fffff097          	auipc	ra,0xfffff
    80001116:	42c080e7          	jalr	1068(ra) # 8000053e <panic>
      panic("mappages: remap");
    8000111a:	00007517          	auipc	a0,0x7
    8000111e:	fd650513          	addi	a0,a0,-42 # 800080f0 <digits+0xb0>
    80001122:	fffff097          	auipc	ra,0xfffff
    80001126:	41c080e7          	jalr	1052(ra) # 8000053e <panic>
    a += PGSIZE;
    8000112a:	995e                	add	s2,s2,s7
  for(;;){
    8000112c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001130:	4605                	li	a2,1
    80001132:	85ca                	mv	a1,s2
    80001134:	8556                	mv	a0,s5
    80001136:	00000097          	auipc	ra,0x0
    8000113a:	eb6080e7          	jalr	-330(ra) # 80000fec <walk>
    8000113e:	cd19                	beqz	a0,8000115c <mappages+0x88>
    if(*pte & PTE_V)
    80001140:	611c                	ld	a5,0(a0)
    80001142:	8b85                	andi	a5,a5,1
    80001144:	fbf9                	bnez	a5,8000111a <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001146:	80b1                	srli	s1,s1,0xc
    80001148:	04aa                	slli	s1,s1,0xa
    8000114a:	0164e4b3          	or	s1,s1,s6
    8000114e:	0014e493          	ori	s1,s1,1
    80001152:	e104                	sd	s1,0(a0)
    if(a == last)
    80001154:	fd391be3          	bne	s2,s3,8000112a <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001158:	4501                	li	a0,0
    8000115a:	a011                	j	8000115e <mappages+0x8a>
      return -1;
    8000115c:	557d                	li	a0,-1
}
    8000115e:	60a6                	ld	ra,72(sp)
    80001160:	6406                	ld	s0,64(sp)
    80001162:	74e2                	ld	s1,56(sp)
    80001164:	7942                	ld	s2,48(sp)
    80001166:	79a2                	ld	s3,40(sp)
    80001168:	7a02                	ld	s4,32(sp)
    8000116a:	6ae2                	ld	s5,24(sp)
    8000116c:	6b42                	ld	s6,16(sp)
    8000116e:	6ba2                	ld	s7,8(sp)
    80001170:	6161                	addi	sp,sp,80
    80001172:	8082                	ret

0000000080001174 <kvmmap>:
{
    80001174:	1141                	addi	sp,sp,-16
    80001176:	e406                	sd	ra,8(sp)
    80001178:	e022                	sd	s0,0(sp)
    8000117a:	0800                	addi	s0,sp,16
    8000117c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000117e:	86b2                	mv	a3,a2
    80001180:	863e                	mv	a2,a5
    80001182:	00000097          	auipc	ra,0x0
    80001186:	f52080e7          	jalr	-174(ra) # 800010d4 <mappages>
    8000118a:	e509                	bnez	a0,80001194 <kvmmap+0x20>
}
    8000118c:	60a2                	ld	ra,8(sp)
    8000118e:	6402                	ld	s0,0(sp)
    80001190:	0141                	addi	sp,sp,16
    80001192:	8082                	ret
    panic("kvmmap");
    80001194:	00007517          	auipc	a0,0x7
    80001198:	f6c50513          	addi	a0,a0,-148 # 80008100 <digits+0xc0>
    8000119c:	fffff097          	auipc	ra,0xfffff
    800011a0:	3a2080e7          	jalr	930(ra) # 8000053e <panic>

00000000800011a4 <kvmmake>:
{
    800011a4:	1101                	addi	sp,sp,-32
    800011a6:	ec06                	sd	ra,24(sp)
    800011a8:	e822                	sd	s0,16(sp)
    800011aa:	e426                	sd	s1,8(sp)
    800011ac:	e04a                	sd	s2,0(sp)
    800011ae:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	944080e7          	jalr	-1724(ra) # 80000af4 <kalloc>
    800011b8:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011ba:	6605                	lui	a2,0x1
    800011bc:	4581                	li	a1,0
    800011be:	00000097          	auipc	ra,0x0
    800011c2:	b46080e7          	jalr	-1210(ra) # 80000d04 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011c6:	4719                	li	a4,6
    800011c8:	6685                	lui	a3,0x1
    800011ca:	10000637          	lui	a2,0x10000
    800011ce:	100005b7          	lui	a1,0x10000
    800011d2:	8526                	mv	a0,s1
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	fa0080e7          	jalr	-96(ra) # 80001174 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011dc:	4719                	li	a4,6
    800011de:	6685                	lui	a3,0x1
    800011e0:	10001637          	lui	a2,0x10001
    800011e4:	100015b7          	lui	a1,0x10001
    800011e8:	8526                	mv	a0,s1
    800011ea:	00000097          	auipc	ra,0x0
    800011ee:	f8a080e7          	jalr	-118(ra) # 80001174 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011f2:	4719                	li	a4,6
    800011f4:	004006b7          	lui	a3,0x400
    800011f8:	0c000637          	lui	a2,0xc000
    800011fc:	0c0005b7          	lui	a1,0xc000
    80001200:	8526                	mv	a0,s1
    80001202:	00000097          	auipc	ra,0x0
    80001206:	f72080e7          	jalr	-142(ra) # 80001174 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000120a:	00007917          	auipc	s2,0x7
    8000120e:	df690913          	addi	s2,s2,-522 # 80008000 <etext>
    80001212:	4729                	li	a4,10
    80001214:	80007697          	auipc	a3,0x80007
    80001218:	dec68693          	addi	a3,a3,-532 # 8000 <_entry-0x7fff8000>
    8000121c:	4605                	li	a2,1
    8000121e:	067e                	slli	a2,a2,0x1f
    80001220:	85b2                	mv	a1,a2
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f50080e7          	jalr	-176(ra) # 80001174 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000122c:	4719                	li	a4,6
    8000122e:	46c5                	li	a3,17
    80001230:	06ee                	slli	a3,a3,0x1b
    80001232:	412686b3          	sub	a3,a3,s2
    80001236:	864a                	mv	a2,s2
    80001238:	85ca                	mv	a1,s2
    8000123a:	8526                	mv	a0,s1
    8000123c:	00000097          	auipc	ra,0x0
    80001240:	f38080e7          	jalr	-200(ra) # 80001174 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001244:	4729                	li	a4,10
    80001246:	6685                	lui	a3,0x1
    80001248:	00006617          	auipc	a2,0x6
    8000124c:	db860613          	addi	a2,a2,-584 # 80007000 <_trampoline>
    80001250:	040005b7          	lui	a1,0x4000
    80001254:	15fd                	addi	a1,a1,-1
    80001256:	05b2                	slli	a1,a1,0xc
    80001258:	8526                	mv	a0,s1
    8000125a:	00000097          	auipc	ra,0x0
    8000125e:	f1a080e7          	jalr	-230(ra) # 80001174 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001262:	8526                	mv	a0,s1
    80001264:	00001097          	auipc	ra,0x1
    80001268:	962080e7          	jalr	-1694(ra) # 80001bc6 <proc_mapstacks>
}
    8000126c:	8526                	mv	a0,s1
    8000126e:	60e2                	ld	ra,24(sp)
    80001270:	6442                	ld	s0,16(sp)
    80001272:	64a2                	ld	s1,8(sp)
    80001274:	6902                	ld	s2,0(sp)
    80001276:	6105                	addi	sp,sp,32
    80001278:	8082                	ret

000000008000127a <kvminit>:
{
    8000127a:	1141                	addi	sp,sp,-16
    8000127c:	e406                	sd	ra,8(sp)
    8000127e:	e022                	sd	s0,0(sp)
    80001280:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001282:	00000097          	auipc	ra,0x0
    80001286:	f22080e7          	jalr	-222(ra) # 800011a4 <kvmmake>
    8000128a:	00008797          	auipc	a5,0x8
    8000128e:	d8a7bb23          	sd	a0,-618(a5) # 80009020 <kernel_pagetable>
}
    80001292:	60a2                	ld	ra,8(sp)
    80001294:	6402                	ld	s0,0(sp)
    80001296:	0141                	addi	sp,sp,16
    80001298:	8082                	ret

000000008000129a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000129a:	715d                	addi	sp,sp,-80
    8000129c:	e486                	sd	ra,72(sp)
    8000129e:	e0a2                	sd	s0,64(sp)
    800012a0:	fc26                	sd	s1,56(sp)
    800012a2:	f84a                	sd	s2,48(sp)
    800012a4:	f44e                	sd	s3,40(sp)
    800012a6:	f052                	sd	s4,32(sp)
    800012a8:	ec56                	sd	s5,24(sp)
    800012aa:	e85a                	sd	s6,16(sp)
    800012ac:	e45e                	sd	s7,8(sp)
    800012ae:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012b0:	03459793          	slli	a5,a1,0x34
    800012b4:	e795                	bnez	a5,800012e0 <uvmunmap+0x46>
    800012b6:	8a2a                	mv	s4,a0
    800012b8:	892e                	mv	s2,a1
    800012ba:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012bc:	0632                	slli	a2,a2,0xc
    800012be:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012c2:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012c4:	6b05                	lui	s6,0x1
    800012c6:	0735e863          	bltu	a1,s3,80001336 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012ca:	60a6                	ld	ra,72(sp)
    800012cc:	6406                	ld	s0,64(sp)
    800012ce:	74e2                	ld	s1,56(sp)
    800012d0:	7942                	ld	s2,48(sp)
    800012d2:	79a2                	ld	s3,40(sp)
    800012d4:	7a02                	ld	s4,32(sp)
    800012d6:	6ae2                	ld	s5,24(sp)
    800012d8:	6b42                	ld	s6,16(sp)
    800012da:	6ba2                	ld	s7,8(sp)
    800012dc:	6161                	addi	sp,sp,80
    800012de:	8082                	ret
    panic("uvmunmap: not aligned");
    800012e0:	00007517          	auipc	a0,0x7
    800012e4:	e2850513          	addi	a0,a0,-472 # 80008108 <digits+0xc8>
    800012e8:	fffff097          	auipc	ra,0xfffff
    800012ec:	256080e7          	jalr	598(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012f0:	00007517          	auipc	a0,0x7
    800012f4:	e3050513          	addi	a0,a0,-464 # 80008120 <digits+0xe0>
    800012f8:	fffff097          	auipc	ra,0xfffff
    800012fc:	246080e7          	jalr	582(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    80001300:	00007517          	auipc	a0,0x7
    80001304:	e3050513          	addi	a0,a0,-464 # 80008130 <digits+0xf0>
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	236080e7          	jalr	566(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    80001310:	00007517          	auipc	a0,0x7
    80001314:	e3850513          	addi	a0,a0,-456 # 80008148 <digits+0x108>
    80001318:	fffff097          	auipc	ra,0xfffff
    8000131c:	226080e7          	jalr	550(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    80001320:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001322:	0532                	slli	a0,a0,0xc
    80001324:	fffff097          	auipc	ra,0xfffff
    80001328:	6d4080e7          	jalr	1748(ra) # 800009f8 <kfree>
    *pte = 0;
    8000132c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001330:	995a                	add	s2,s2,s6
    80001332:	f9397ce3          	bgeu	s2,s3,800012ca <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001336:	4601                	li	a2,0
    80001338:	85ca                	mv	a1,s2
    8000133a:	8552                	mv	a0,s4
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	cb0080e7          	jalr	-848(ra) # 80000fec <walk>
    80001344:	84aa                	mv	s1,a0
    80001346:	d54d                	beqz	a0,800012f0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001348:	6108                	ld	a0,0(a0)
    8000134a:	00157793          	andi	a5,a0,1
    8000134e:	dbcd                	beqz	a5,80001300 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001350:	3ff57793          	andi	a5,a0,1023
    80001354:	fb778ee3          	beq	a5,s7,80001310 <uvmunmap+0x76>
    if(do_free){
    80001358:	fc0a8ae3          	beqz	s5,8000132c <uvmunmap+0x92>
    8000135c:	b7d1                	j	80001320 <uvmunmap+0x86>

000000008000135e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000135e:	1101                	addi	sp,sp,-32
    80001360:	ec06                	sd	ra,24(sp)
    80001362:	e822                	sd	s0,16(sp)
    80001364:	e426                	sd	s1,8(sp)
    80001366:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	78c080e7          	jalr	1932(ra) # 80000af4 <kalloc>
    80001370:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001372:	c519                	beqz	a0,80001380 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001374:	6605                	lui	a2,0x1
    80001376:	4581                	li	a1,0
    80001378:	00000097          	auipc	ra,0x0
    8000137c:	98c080e7          	jalr	-1652(ra) # 80000d04 <memset>
  return pagetable;
}
    80001380:	8526                	mv	a0,s1
    80001382:	60e2                	ld	ra,24(sp)
    80001384:	6442                	ld	s0,16(sp)
    80001386:	64a2                	ld	s1,8(sp)
    80001388:	6105                	addi	sp,sp,32
    8000138a:	8082                	ret

000000008000138c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000138c:	7179                	addi	sp,sp,-48
    8000138e:	f406                	sd	ra,40(sp)
    80001390:	f022                	sd	s0,32(sp)
    80001392:	ec26                	sd	s1,24(sp)
    80001394:	e84a                	sd	s2,16(sp)
    80001396:	e44e                	sd	s3,8(sp)
    80001398:	e052                	sd	s4,0(sp)
    8000139a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000139c:	6785                	lui	a5,0x1
    8000139e:	04f67863          	bgeu	a2,a5,800013ee <uvminit+0x62>
    800013a2:	8a2a                	mv	s4,a0
    800013a4:	89ae                	mv	s3,a1
    800013a6:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013a8:	fffff097          	auipc	ra,0xfffff
    800013ac:	74c080e7          	jalr	1868(ra) # 80000af4 <kalloc>
    800013b0:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013b2:	6605                	lui	a2,0x1
    800013b4:	4581                	li	a1,0
    800013b6:	00000097          	auipc	ra,0x0
    800013ba:	94e080e7          	jalr	-1714(ra) # 80000d04 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013be:	4779                	li	a4,30
    800013c0:	86ca                	mv	a3,s2
    800013c2:	6605                	lui	a2,0x1
    800013c4:	4581                	li	a1,0
    800013c6:	8552                	mv	a0,s4
    800013c8:	00000097          	auipc	ra,0x0
    800013cc:	d0c080e7          	jalr	-756(ra) # 800010d4 <mappages>
  memmove(mem, src, sz);
    800013d0:	8626                	mv	a2,s1
    800013d2:	85ce                	mv	a1,s3
    800013d4:	854a                	mv	a0,s2
    800013d6:	00000097          	auipc	ra,0x0
    800013da:	98e080e7          	jalr	-1650(ra) # 80000d64 <memmove>
}
    800013de:	70a2                	ld	ra,40(sp)
    800013e0:	7402                	ld	s0,32(sp)
    800013e2:	64e2                	ld	s1,24(sp)
    800013e4:	6942                	ld	s2,16(sp)
    800013e6:	69a2                	ld	s3,8(sp)
    800013e8:	6a02                	ld	s4,0(sp)
    800013ea:	6145                	addi	sp,sp,48
    800013ec:	8082                	ret
    panic("inituvm: more than a page");
    800013ee:	00007517          	auipc	a0,0x7
    800013f2:	d7250513          	addi	a0,a0,-654 # 80008160 <digits+0x120>
    800013f6:	fffff097          	auipc	ra,0xfffff
    800013fa:	148080e7          	jalr	328(ra) # 8000053e <panic>

00000000800013fe <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013fe:	1101                	addi	sp,sp,-32
    80001400:	ec06                	sd	ra,24(sp)
    80001402:	e822                	sd	s0,16(sp)
    80001404:	e426                	sd	s1,8(sp)
    80001406:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001408:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000140a:	00b67d63          	bgeu	a2,a1,80001424 <uvmdealloc+0x26>
    8000140e:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001410:	6785                	lui	a5,0x1
    80001412:	17fd                	addi	a5,a5,-1
    80001414:	00f60733          	add	a4,a2,a5
    80001418:	767d                	lui	a2,0xfffff
    8000141a:	8f71                	and	a4,a4,a2
    8000141c:	97ae                	add	a5,a5,a1
    8000141e:	8ff1                	and	a5,a5,a2
    80001420:	00f76863          	bltu	a4,a5,80001430 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001424:	8526                	mv	a0,s1
    80001426:	60e2                	ld	ra,24(sp)
    80001428:	6442                	ld	s0,16(sp)
    8000142a:	64a2                	ld	s1,8(sp)
    8000142c:	6105                	addi	sp,sp,32
    8000142e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001430:	8f99                	sub	a5,a5,a4
    80001432:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001434:	4685                	li	a3,1
    80001436:	0007861b          	sext.w	a2,a5
    8000143a:	85ba                	mv	a1,a4
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	e5e080e7          	jalr	-418(ra) # 8000129a <uvmunmap>
    80001444:	b7c5                	j	80001424 <uvmdealloc+0x26>

0000000080001446 <uvmalloc>:
  if(newsz < oldsz)
    80001446:	0ab66163          	bltu	a2,a1,800014e8 <uvmalloc+0xa2>
{
    8000144a:	7139                	addi	sp,sp,-64
    8000144c:	fc06                	sd	ra,56(sp)
    8000144e:	f822                	sd	s0,48(sp)
    80001450:	f426                	sd	s1,40(sp)
    80001452:	f04a                	sd	s2,32(sp)
    80001454:	ec4e                	sd	s3,24(sp)
    80001456:	e852                	sd	s4,16(sp)
    80001458:	e456                	sd	s5,8(sp)
    8000145a:	0080                	addi	s0,sp,64
    8000145c:	8aaa                	mv	s5,a0
    8000145e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001460:	6985                	lui	s3,0x1
    80001462:	19fd                	addi	s3,s3,-1
    80001464:	95ce                	add	a1,a1,s3
    80001466:	79fd                	lui	s3,0xfffff
    80001468:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146c:	08c9f063          	bgeu	s3,a2,800014ec <uvmalloc+0xa6>
    80001470:	894e                	mv	s2,s3
    mem = kalloc();
    80001472:	fffff097          	auipc	ra,0xfffff
    80001476:	682080e7          	jalr	1666(ra) # 80000af4 <kalloc>
    8000147a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000147c:	c51d                	beqz	a0,800014aa <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000147e:	6605                	lui	a2,0x1
    80001480:	4581                	li	a1,0
    80001482:	00000097          	auipc	ra,0x0
    80001486:	882080e7          	jalr	-1918(ra) # 80000d04 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000148a:	4779                	li	a4,30
    8000148c:	86a6                	mv	a3,s1
    8000148e:	6605                	lui	a2,0x1
    80001490:	85ca                	mv	a1,s2
    80001492:	8556                	mv	a0,s5
    80001494:	00000097          	auipc	ra,0x0
    80001498:	c40080e7          	jalr	-960(ra) # 800010d4 <mappages>
    8000149c:	e905                	bnez	a0,800014cc <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000149e:	6785                	lui	a5,0x1
    800014a0:	993e                	add	s2,s2,a5
    800014a2:	fd4968e3          	bltu	s2,s4,80001472 <uvmalloc+0x2c>
  return newsz;
    800014a6:	8552                	mv	a0,s4
    800014a8:	a809                	j	800014ba <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014aa:	864e                	mv	a2,s3
    800014ac:	85ca                	mv	a1,s2
    800014ae:	8556                	mv	a0,s5
    800014b0:	00000097          	auipc	ra,0x0
    800014b4:	f4e080e7          	jalr	-178(ra) # 800013fe <uvmdealloc>
      return 0;
    800014b8:	4501                	li	a0,0
}
    800014ba:	70e2                	ld	ra,56(sp)
    800014bc:	7442                	ld	s0,48(sp)
    800014be:	74a2                	ld	s1,40(sp)
    800014c0:	7902                	ld	s2,32(sp)
    800014c2:	69e2                	ld	s3,24(sp)
    800014c4:	6a42                	ld	s4,16(sp)
    800014c6:	6aa2                	ld	s5,8(sp)
    800014c8:	6121                	addi	sp,sp,64
    800014ca:	8082                	ret
      kfree(mem);
    800014cc:	8526                	mv	a0,s1
    800014ce:	fffff097          	auipc	ra,0xfffff
    800014d2:	52a080e7          	jalr	1322(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014d6:	864e                	mv	a2,s3
    800014d8:	85ca                	mv	a1,s2
    800014da:	8556                	mv	a0,s5
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	f22080e7          	jalr	-222(ra) # 800013fe <uvmdealloc>
      return 0;
    800014e4:	4501                	li	a0,0
    800014e6:	bfd1                	j	800014ba <uvmalloc+0x74>
    return oldsz;
    800014e8:	852e                	mv	a0,a1
}
    800014ea:	8082                	ret
  return newsz;
    800014ec:	8532                	mv	a0,a2
    800014ee:	b7f1                	j	800014ba <uvmalloc+0x74>

00000000800014f0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014f0:	7179                	addi	sp,sp,-48
    800014f2:	f406                	sd	ra,40(sp)
    800014f4:	f022                	sd	s0,32(sp)
    800014f6:	ec26                	sd	s1,24(sp)
    800014f8:	e84a                	sd	s2,16(sp)
    800014fa:	e44e                	sd	s3,8(sp)
    800014fc:	e052                	sd	s4,0(sp)
    800014fe:	1800                	addi	s0,sp,48
    80001500:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001502:	84aa                	mv	s1,a0
    80001504:	6905                	lui	s2,0x1
    80001506:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001508:	4985                	li	s3,1
    8000150a:	a821                	j	80001522 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000150c:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000150e:	0532                	slli	a0,a0,0xc
    80001510:	00000097          	auipc	ra,0x0
    80001514:	fe0080e7          	jalr	-32(ra) # 800014f0 <freewalk>
      pagetable[i] = 0;
    80001518:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000151c:	04a1                	addi	s1,s1,8
    8000151e:	03248163          	beq	s1,s2,80001540 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001522:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001524:	00f57793          	andi	a5,a0,15
    80001528:	ff3782e3          	beq	a5,s3,8000150c <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000152c:	8905                	andi	a0,a0,1
    8000152e:	d57d                	beqz	a0,8000151c <freewalk+0x2c>
      panic("freewalk: leaf");
    80001530:	00007517          	auipc	a0,0x7
    80001534:	c5050513          	addi	a0,a0,-944 # 80008180 <digits+0x140>
    80001538:	fffff097          	auipc	ra,0xfffff
    8000153c:	006080e7          	jalr	6(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001540:	8552                	mv	a0,s4
    80001542:	fffff097          	auipc	ra,0xfffff
    80001546:	4b6080e7          	jalr	1206(ra) # 800009f8 <kfree>
}
    8000154a:	70a2                	ld	ra,40(sp)
    8000154c:	7402                	ld	s0,32(sp)
    8000154e:	64e2                	ld	s1,24(sp)
    80001550:	6942                	ld	s2,16(sp)
    80001552:	69a2                	ld	s3,8(sp)
    80001554:	6a02                	ld	s4,0(sp)
    80001556:	6145                	addi	sp,sp,48
    80001558:	8082                	ret

000000008000155a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000155a:	1101                	addi	sp,sp,-32
    8000155c:	ec06                	sd	ra,24(sp)
    8000155e:	e822                	sd	s0,16(sp)
    80001560:	e426                	sd	s1,8(sp)
    80001562:	1000                	addi	s0,sp,32
    80001564:	84aa                	mv	s1,a0
  if(sz > 0)
    80001566:	e999                	bnez	a1,8000157c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001568:	8526                	mv	a0,s1
    8000156a:	00000097          	auipc	ra,0x0
    8000156e:	f86080e7          	jalr	-122(ra) # 800014f0 <freewalk>
}
    80001572:	60e2                	ld	ra,24(sp)
    80001574:	6442                	ld	s0,16(sp)
    80001576:	64a2                	ld	s1,8(sp)
    80001578:	6105                	addi	sp,sp,32
    8000157a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000157c:	6605                	lui	a2,0x1
    8000157e:	167d                	addi	a2,a2,-1
    80001580:	962e                	add	a2,a2,a1
    80001582:	4685                	li	a3,1
    80001584:	8231                	srli	a2,a2,0xc
    80001586:	4581                	li	a1,0
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	d12080e7          	jalr	-750(ra) # 8000129a <uvmunmap>
    80001590:	bfe1                	j	80001568 <uvmfree+0xe>

0000000080001592 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001592:	c679                	beqz	a2,80001660 <uvmcopy+0xce>
{
    80001594:	715d                	addi	sp,sp,-80
    80001596:	e486                	sd	ra,72(sp)
    80001598:	e0a2                	sd	s0,64(sp)
    8000159a:	fc26                	sd	s1,56(sp)
    8000159c:	f84a                	sd	s2,48(sp)
    8000159e:	f44e                	sd	s3,40(sp)
    800015a0:	f052                	sd	s4,32(sp)
    800015a2:	ec56                	sd	s5,24(sp)
    800015a4:	e85a                	sd	s6,16(sp)
    800015a6:	e45e                	sd	s7,8(sp)
    800015a8:	0880                	addi	s0,sp,80
    800015aa:	8b2a                	mv	s6,a0
    800015ac:	8aae                	mv	s5,a1
    800015ae:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015b0:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015b2:	4601                	li	a2,0
    800015b4:	85ce                	mv	a1,s3
    800015b6:	855a                	mv	a0,s6
    800015b8:	00000097          	auipc	ra,0x0
    800015bc:	a34080e7          	jalr	-1484(ra) # 80000fec <walk>
    800015c0:	c531                	beqz	a0,8000160c <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015c2:	6118                	ld	a4,0(a0)
    800015c4:	00177793          	andi	a5,a4,1
    800015c8:	cbb1                	beqz	a5,8000161c <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015ca:	00a75593          	srli	a1,a4,0xa
    800015ce:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015d2:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015d6:	fffff097          	auipc	ra,0xfffff
    800015da:	51e080e7          	jalr	1310(ra) # 80000af4 <kalloc>
    800015de:	892a                	mv	s2,a0
    800015e0:	c939                	beqz	a0,80001636 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015e2:	6605                	lui	a2,0x1
    800015e4:	85de                	mv	a1,s7
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	77e080e7          	jalr	1918(ra) # 80000d64 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ee:	8726                	mv	a4,s1
    800015f0:	86ca                	mv	a3,s2
    800015f2:	6605                	lui	a2,0x1
    800015f4:	85ce                	mv	a1,s3
    800015f6:	8556                	mv	a0,s5
    800015f8:	00000097          	auipc	ra,0x0
    800015fc:	adc080e7          	jalr	-1316(ra) # 800010d4 <mappages>
    80001600:	e515                	bnez	a0,8000162c <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001602:	6785                	lui	a5,0x1
    80001604:	99be                	add	s3,s3,a5
    80001606:	fb49e6e3          	bltu	s3,s4,800015b2 <uvmcopy+0x20>
    8000160a:	a081                	j	8000164a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000160c:	00007517          	auipc	a0,0x7
    80001610:	b8450513          	addi	a0,a0,-1148 # 80008190 <digits+0x150>
    80001614:	fffff097          	auipc	ra,0xfffff
    80001618:	f2a080e7          	jalr	-214(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    8000161c:	00007517          	auipc	a0,0x7
    80001620:	b9450513          	addi	a0,a0,-1132 # 800081b0 <digits+0x170>
    80001624:	fffff097          	auipc	ra,0xfffff
    80001628:	f1a080e7          	jalr	-230(ra) # 8000053e <panic>
      kfree(mem);
    8000162c:	854a                	mv	a0,s2
    8000162e:	fffff097          	auipc	ra,0xfffff
    80001632:	3ca080e7          	jalr	970(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001636:	4685                	li	a3,1
    80001638:	00c9d613          	srli	a2,s3,0xc
    8000163c:	4581                	li	a1,0
    8000163e:	8556                	mv	a0,s5
    80001640:	00000097          	auipc	ra,0x0
    80001644:	c5a080e7          	jalr	-934(ra) # 8000129a <uvmunmap>
  return -1;
    80001648:	557d                	li	a0,-1
}
    8000164a:	60a6                	ld	ra,72(sp)
    8000164c:	6406                	ld	s0,64(sp)
    8000164e:	74e2                	ld	s1,56(sp)
    80001650:	7942                	ld	s2,48(sp)
    80001652:	79a2                	ld	s3,40(sp)
    80001654:	7a02                	ld	s4,32(sp)
    80001656:	6ae2                	ld	s5,24(sp)
    80001658:	6b42                	ld	s6,16(sp)
    8000165a:	6ba2                	ld	s7,8(sp)
    8000165c:	6161                	addi	sp,sp,80
    8000165e:	8082                	ret
  return 0;
    80001660:	4501                	li	a0,0
}
    80001662:	8082                	ret

0000000080001664 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001664:	1141                	addi	sp,sp,-16
    80001666:	e406                	sd	ra,8(sp)
    80001668:	e022                	sd	s0,0(sp)
    8000166a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000166c:	4601                	li	a2,0
    8000166e:	00000097          	auipc	ra,0x0
    80001672:	97e080e7          	jalr	-1666(ra) # 80000fec <walk>
  if(pte == 0)
    80001676:	c901                	beqz	a0,80001686 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001678:	611c                	ld	a5,0(a0)
    8000167a:	9bbd                	andi	a5,a5,-17
    8000167c:	e11c                	sd	a5,0(a0)
}
    8000167e:	60a2                	ld	ra,8(sp)
    80001680:	6402                	ld	s0,0(sp)
    80001682:	0141                	addi	sp,sp,16
    80001684:	8082                	ret
    panic("uvmclear");
    80001686:	00007517          	auipc	a0,0x7
    8000168a:	b4a50513          	addi	a0,a0,-1206 # 800081d0 <digits+0x190>
    8000168e:	fffff097          	auipc	ra,0xfffff
    80001692:	eb0080e7          	jalr	-336(ra) # 8000053e <panic>

0000000080001696 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001696:	c6bd                	beqz	a3,80001704 <copyout+0x6e>
{
    80001698:	715d                	addi	sp,sp,-80
    8000169a:	e486                	sd	ra,72(sp)
    8000169c:	e0a2                	sd	s0,64(sp)
    8000169e:	fc26                	sd	s1,56(sp)
    800016a0:	f84a                	sd	s2,48(sp)
    800016a2:	f44e                	sd	s3,40(sp)
    800016a4:	f052                	sd	s4,32(sp)
    800016a6:	ec56                	sd	s5,24(sp)
    800016a8:	e85a                	sd	s6,16(sp)
    800016aa:	e45e                	sd	s7,8(sp)
    800016ac:	e062                	sd	s8,0(sp)
    800016ae:	0880                	addi	s0,sp,80
    800016b0:	8b2a                	mv	s6,a0
    800016b2:	8c2e                	mv	s8,a1
    800016b4:	8a32                	mv	s4,a2
    800016b6:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016b8:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016ba:	6a85                	lui	s5,0x1
    800016bc:	a015                	j	800016e0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016be:	9562                	add	a0,a0,s8
    800016c0:	0004861b          	sext.w	a2,s1
    800016c4:	85d2                	mv	a1,s4
    800016c6:	41250533          	sub	a0,a0,s2
    800016ca:	fffff097          	auipc	ra,0xfffff
    800016ce:	69a080e7          	jalr	1690(ra) # 80000d64 <memmove>

    len -= n;
    800016d2:	409989b3          	sub	s3,s3,s1
    src += n;
    800016d6:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016d8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016dc:	02098263          	beqz	s3,80001700 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016e0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016e4:	85ca                	mv	a1,s2
    800016e6:	855a                	mv	a0,s6
    800016e8:	00000097          	auipc	ra,0x0
    800016ec:	9aa080e7          	jalr	-1622(ra) # 80001092 <walkaddr>
    if(pa0 == 0)
    800016f0:	cd01                	beqz	a0,80001708 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016f2:	418904b3          	sub	s1,s2,s8
    800016f6:	94d6                	add	s1,s1,s5
    if(n > len)
    800016f8:	fc99f3e3          	bgeu	s3,s1,800016be <copyout+0x28>
    800016fc:	84ce                	mv	s1,s3
    800016fe:	b7c1                	j	800016be <copyout+0x28>
  }
  return 0;
    80001700:	4501                	li	a0,0
    80001702:	a021                	j	8000170a <copyout+0x74>
    80001704:	4501                	li	a0,0
}
    80001706:	8082                	ret
      return -1;
    80001708:	557d                	li	a0,-1
}
    8000170a:	60a6                	ld	ra,72(sp)
    8000170c:	6406                	ld	s0,64(sp)
    8000170e:	74e2                	ld	s1,56(sp)
    80001710:	7942                	ld	s2,48(sp)
    80001712:	79a2                	ld	s3,40(sp)
    80001714:	7a02                	ld	s4,32(sp)
    80001716:	6ae2                	ld	s5,24(sp)
    80001718:	6b42                	ld	s6,16(sp)
    8000171a:	6ba2                	ld	s7,8(sp)
    8000171c:	6c02                	ld	s8,0(sp)
    8000171e:	6161                	addi	sp,sp,80
    80001720:	8082                	ret

0000000080001722 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001722:	c6bd                	beqz	a3,80001790 <copyin+0x6e>
{
    80001724:	715d                	addi	sp,sp,-80
    80001726:	e486                	sd	ra,72(sp)
    80001728:	e0a2                	sd	s0,64(sp)
    8000172a:	fc26                	sd	s1,56(sp)
    8000172c:	f84a                	sd	s2,48(sp)
    8000172e:	f44e                	sd	s3,40(sp)
    80001730:	f052                	sd	s4,32(sp)
    80001732:	ec56                	sd	s5,24(sp)
    80001734:	e85a                	sd	s6,16(sp)
    80001736:	e45e                	sd	s7,8(sp)
    80001738:	e062                	sd	s8,0(sp)
    8000173a:	0880                	addi	s0,sp,80
    8000173c:	8b2a                	mv	s6,a0
    8000173e:	8a2e                	mv	s4,a1
    80001740:	8c32                	mv	s8,a2
    80001742:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001744:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001746:	6a85                	lui	s5,0x1
    80001748:	a015                	j	8000176c <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000174a:	9562                	add	a0,a0,s8
    8000174c:	0004861b          	sext.w	a2,s1
    80001750:	412505b3          	sub	a1,a0,s2
    80001754:	8552                	mv	a0,s4
    80001756:	fffff097          	auipc	ra,0xfffff
    8000175a:	60e080e7          	jalr	1550(ra) # 80000d64 <memmove>

    len -= n;
    8000175e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001762:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001764:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001768:	02098263          	beqz	s3,8000178c <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000176c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001770:	85ca                	mv	a1,s2
    80001772:	855a                	mv	a0,s6
    80001774:	00000097          	auipc	ra,0x0
    80001778:	91e080e7          	jalr	-1762(ra) # 80001092 <walkaddr>
    if(pa0 == 0)
    8000177c:	cd01                	beqz	a0,80001794 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000177e:	418904b3          	sub	s1,s2,s8
    80001782:	94d6                	add	s1,s1,s5
    if(n > len)
    80001784:	fc99f3e3          	bgeu	s3,s1,8000174a <copyin+0x28>
    80001788:	84ce                	mv	s1,s3
    8000178a:	b7c1                	j	8000174a <copyin+0x28>
  }
  return 0;
    8000178c:	4501                	li	a0,0
    8000178e:	a021                	j	80001796 <copyin+0x74>
    80001790:	4501                	li	a0,0
}
    80001792:	8082                	ret
      return -1;
    80001794:	557d                	li	a0,-1
}
    80001796:	60a6                	ld	ra,72(sp)
    80001798:	6406                	ld	s0,64(sp)
    8000179a:	74e2                	ld	s1,56(sp)
    8000179c:	7942                	ld	s2,48(sp)
    8000179e:	79a2                	ld	s3,40(sp)
    800017a0:	7a02                	ld	s4,32(sp)
    800017a2:	6ae2                	ld	s5,24(sp)
    800017a4:	6b42                	ld	s6,16(sp)
    800017a6:	6ba2                	ld	s7,8(sp)
    800017a8:	6c02                	ld	s8,0(sp)
    800017aa:	6161                	addi	sp,sp,80
    800017ac:	8082                	ret

00000000800017ae <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017ae:	c6c5                	beqz	a3,80001856 <copyinstr+0xa8>
{
    800017b0:	715d                	addi	sp,sp,-80
    800017b2:	e486                	sd	ra,72(sp)
    800017b4:	e0a2                	sd	s0,64(sp)
    800017b6:	fc26                	sd	s1,56(sp)
    800017b8:	f84a                	sd	s2,48(sp)
    800017ba:	f44e                	sd	s3,40(sp)
    800017bc:	f052                	sd	s4,32(sp)
    800017be:	ec56                	sd	s5,24(sp)
    800017c0:	e85a                	sd	s6,16(sp)
    800017c2:	e45e                	sd	s7,8(sp)
    800017c4:	0880                	addi	s0,sp,80
    800017c6:	8a2a                	mv	s4,a0
    800017c8:	8b2e                	mv	s6,a1
    800017ca:	8bb2                	mv	s7,a2
    800017cc:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017ce:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017d0:	6985                	lui	s3,0x1
    800017d2:	a035                	j	800017fe <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017d4:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017d8:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017da:	0017b793          	seqz	a5,a5
    800017de:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017e2:	60a6                	ld	ra,72(sp)
    800017e4:	6406                	ld	s0,64(sp)
    800017e6:	74e2                	ld	s1,56(sp)
    800017e8:	7942                	ld	s2,48(sp)
    800017ea:	79a2                	ld	s3,40(sp)
    800017ec:	7a02                	ld	s4,32(sp)
    800017ee:	6ae2                	ld	s5,24(sp)
    800017f0:	6b42                	ld	s6,16(sp)
    800017f2:	6ba2                	ld	s7,8(sp)
    800017f4:	6161                	addi	sp,sp,80
    800017f6:	8082                	ret
    srcva = va0 + PGSIZE;
    800017f8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017fc:	c8a9                	beqz	s1,8000184e <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017fe:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001802:	85ca                	mv	a1,s2
    80001804:	8552                	mv	a0,s4
    80001806:	00000097          	auipc	ra,0x0
    8000180a:	88c080e7          	jalr	-1908(ra) # 80001092 <walkaddr>
    if(pa0 == 0)
    8000180e:	c131                	beqz	a0,80001852 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001810:	41790833          	sub	a6,s2,s7
    80001814:	984e                	add	a6,a6,s3
    if(n > max)
    80001816:	0104f363          	bgeu	s1,a6,8000181c <copyinstr+0x6e>
    8000181a:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000181c:	955e                	add	a0,a0,s7
    8000181e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001822:	fc080be3          	beqz	a6,800017f8 <copyinstr+0x4a>
    80001826:	985a                	add	a6,a6,s6
    80001828:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000182a:	41650633          	sub	a2,a0,s6
    8000182e:	14fd                	addi	s1,s1,-1
    80001830:	9b26                	add	s6,s6,s1
    80001832:	00f60733          	add	a4,a2,a5
    80001836:	00074703          	lbu	a4,0(a4)
    8000183a:	df49                	beqz	a4,800017d4 <copyinstr+0x26>
        *dst = *p;
    8000183c:	00e78023          	sb	a4,0(a5)
      --max;
    80001840:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001844:	0785                	addi	a5,a5,1
    while(n > 0){
    80001846:	ff0796e3          	bne	a5,a6,80001832 <copyinstr+0x84>
      dst++;
    8000184a:	8b42                	mv	s6,a6
    8000184c:	b775                	j	800017f8 <copyinstr+0x4a>
    8000184e:	4781                	li	a5,0
    80001850:	b769                	j	800017da <copyinstr+0x2c>
      return -1;
    80001852:	557d                	li	a0,-1
    80001854:	b779                	j	800017e2 <copyinstr+0x34>
  int got_null = 0;
    80001856:	4781                	li	a5,0
  if(got_null){
    80001858:	0017b793          	seqz	a5,a5
    8000185c:	40f00533          	neg	a0,a5
}
    80001860:	8082                	ret

0000000080001862 <print_list>:
int sleeping_head = -1;
int unused_head = -1;
struct spinlock zombie_lock, sleeping_lock, unused_lock;

void print_list(int first_id)
{
    80001862:	7139                	addi	sp,sp,-64
    80001864:	fc06                	sd	ra,56(sp)
    80001866:	f822                	sd	s0,48(sp)
    80001868:	f426                	sd	s1,40(sp)
    8000186a:	f04a                	sd	s2,32(sp)
    8000186c:	ec4e                	sd	s3,24(sp)
    8000186e:	e852                	sd	s4,16(sp)
    80001870:	e456                	sd	s5,8(sp)
    80001872:	0080                	addi	s0,sp,64
    80001874:	84aa                	mv	s1,a0
  printf("list:      ");
    80001876:	00007517          	auipc	a0,0x7
    8000187a:	96a50513          	addi	a0,a0,-1686 # 800081e0 <digits+0x1a0>
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	d0a080e7          	jalr	-758(ra) # 80000588 <printf>
  int curr = first_id;
  while (curr != -1)
    80001886:	57fd                	li	a5,-1
    80001888:	02f48963          	beq	s1,a5,800018ba <print_list+0x58>
  {
    printf("%d -> ", curr);
    8000188c:	00007a97          	auipc	s5,0x7
    80001890:	964a8a93          	addi	s5,s5,-1692 # 800081f0 <digits+0x1b0>
    curr = proc[curr].next;
    80001894:	00010a17          	auipc	s4,0x10
    80001898:	f84a0a13          	addi	s4,s4,-124 # 80011818 <proc>
    8000189c:	18800993          	li	s3,392
  while (curr != -1)
    800018a0:	597d                	li	s2,-1
    printf("%d -> ", curr);
    800018a2:	85a6                	mv	a1,s1
    800018a4:	8556                	mv	a0,s5
    800018a6:	fffff097          	auipc	ra,0xfffff
    800018aa:	ce2080e7          	jalr	-798(ra) # 80000588 <printf>
    curr = proc[curr].next;
    800018ae:	033484b3          	mul	s1,s1,s3
    800018b2:	94d2                	add	s1,s1,s4
    800018b4:	48a4                	lw	s1,80(s1)
  while (curr != -1)
    800018b6:	ff2496e3          	bne	s1,s2,800018a2 <print_list+0x40>
  }
  printf("\n");
    800018ba:	00007517          	auipc	a0,0x7
    800018be:	81650513          	addi	a0,a0,-2026 # 800080d0 <digits+0x90>
    800018c2:	fffff097          	auipc	ra,0xfffff
    800018c6:	cc6080e7          	jalr	-826(ra) # 80000588 <printf>
}
    800018ca:	70e2                	ld	ra,56(sp)
    800018cc:	7442                	ld	s0,48(sp)
    800018ce:	74a2                	ld	s1,40(sp)
    800018d0:	7902                	ld	s2,32(sp)
    800018d2:	69e2                	ld	s3,24(sp)
    800018d4:	6a42                	ld	s4,16(sp)
    800018d6:	6aa2                	ld	s5,8(sp)
    800018d8:	6121                	addi	sp,sp,64
    800018da:	8082                	ret

00000000800018dc <find_remove>:
//     release(&remove_proc->p_lock);
//     release(&curr_proc->p_lock);
// }

int find_remove(struct proc *curr_proc, struct proc *to_remove)
{
    800018dc:	7139                	addi	sp,sp,-64
    800018de:	fc06                	sd	ra,56(sp)
    800018e0:	f822                	sd	s0,48(sp)
    800018e2:	f426                	sd	s1,40(sp)
    800018e4:	f04a                	sd	s2,32(sp)
    800018e6:	ec4e                	sd	s3,24(sp)
    800018e8:	e852                	sd	s4,16(sp)
    800018ea:	e456                	sd	s5,8(sp)
    800018ec:	0080                	addi	s0,sp,64
    800018ee:	84aa                	mv	s1,a0
  while (curr_proc->next != -1)
    800018f0:	4928                	lw	a0,80(a0)
    800018f2:	57fd                	li	a5,-1
    800018f4:	04f50963          	beq	a0,a5,80001946 <find_remove+0x6a>
    800018f8:	8a2e                	mv	s4,a1
  {
    acquire(&proc[curr_proc->next].p_lock);
    800018fa:	18800993          	li	s3,392
    800018fe:	00010917          	auipc	s2,0x10
    80001902:	f1a90913          	addi	s2,s2,-230 # 80011818 <proc>
  while (curr_proc->next != -1)
    80001906:	5afd                	li	s5,-1
    acquire(&proc[curr_proc->next].p_lock);
    80001908:	03350533          	mul	a0,a0,s3
    8000190c:	03850513          	addi	a0,a0,56
    80001910:	954a                	add	a0,a0,s2
    80001912:	fffff097          	auipc	ra,0xfffff
    80001916:	2d2080e7          	jalr	722(ra) # 80000be4 <acquire>
    if (proc[curr_proc->next].proc_idx == to_remove->proc_idx)
    8000191a:	48bc                	lw	a5,80(s1)
    8000191c:	033787b3          	mul	a5,a5,s3
    80001920:	97ca                	add	a5,a5,s2
    80001922:	4bf8                	lw	a4,84(a5)
    80001924:	054a2783          	lw	a5,84(s4)
    80001928:	02f70f63          	beq	a4,a5,80001966 <find_remove+0x8a>
      to_remove->next = -1;
      release(&curr_proc->p_lock);
      release(&to_remove->p_lock);
      return 1;
    }
    release(&curr_proc->p_lock);
    8000192c:	03848513          	addi	a0,s1,56
    80001930:	fffff097          	auipc	ra,0xfffff
    80001934:	37a080e7          	jalr	890(ra) # 80000caa <release>
    curr_proc = &proc[curr_proc->next];
    80001938:	48a4                	lw	s1,80(s1)
    8000193a:	033484b3          	mul	s1,s1,s3
    8000193e:	94ca                	add	s1,s1,s2
  while (curr_proc->next != -1)
    80001940:	48a8                	lw	a0,80(s1)
    80001942:	fd5513e3          	bne	a0,s5,80001908 <find_remove+0x2c>
  }
  release(&curr_proc->p_lock);
    80001946:	03848513          	addi	a0,s1,56
    8000194a:	fffff097          	auipc	ra,0xfffff
    8000194e:	360080e7          	jalr	864(ra) # 80000caa <release>
  return -1;
    80001952:	557d                	li	a0,-1
}
    80001954:	70e2                	ld	ra,56(sp)
    80001956:	7442                	ld	s0,48(sp)
    80001958:	74a2                	ld	s1,40(sp)
    8000195a:	7902                	ld	s2,32(sp)
    8000195c:	69e2                	ld	s3,24(sp)
    8000195e:	6a42                	ld	s4,16(sp)
    80001960:	6aa2                	ld	s5,8(sp)
    80001962:	6121                	addi	sp,sp,64
    80001964:	8082                	ret
      curr_proc->next = to_remove->next;
    80001966:	050a2783          	lw	a5,80(s4)
    8000196a:	c8bc                	sw	a5,80(s1)
      to_remove->next = -1;
    8000196c:	57fd                	li	a5,-1
    8000196e:	04fa2823          	sw	a5,80(s4)
      release(&curr_proc->p_lock);
    80001972:	03848513          	addi	a0,s1,56
    80001976:	fffff097          	auipc	ra,0xfffff
    8000197a:	334080e7          	jalr	820(ra) # 80000caa <release>
      release(&to_remove->p_lock);
    8000197e:	038a0513          	addi	a0,s4,56
    80001982:	fffff097          	auipc	ra,0xfffff
    80001986:	328080e7          	jalr	808(ra) # 80000caa <release>
      return 1;
    8000198a:	4505                	li	a0,1
    8000198c:	b7e1                	j	80001954 <find_remove+0x78>

000000008000198e <remove_proc>:

int remove_proc(int *head_list, struct proc *to_remove, struct spinlock *head_lock)
{
    8000198e:	7179                	addi	sp,sp,-48
    80001990:	f406                	sd	ra,40(sp)
    80001992:	f022                	sd	s0,32(sp)
    80001994:	ec26                	sd	s1,24(sp)
    80001996:	e84a                	sd	s2,16(sp)
    80001998:	e44e                	sd	s3,8(sp)
    8000199a:	e052                	sd	s4,0(sp)
    8000199c:	1800                	addi	s0,sp,48
    8000199e:	892a                	mv	s2,a0
    800019a0:	8a2e                	mv	s4,a1
    800019a2:	89b2                	mv	s3,a2
  acquire(head_lock);
    800019a4:	8532                	mv	a0,a2
    800019a6:	fffff097          	auipc	ra,0xfffff
    800019aa:	23e080e7          	jalr	574(ra) # 80000be4 <acquire>
  if (*head_list == -1) // empty list case
    800019ae:	00092483          	lw	s1,0(s2)
    800019b2:	57fd                	li	a5,-1
    800019b4:	06f48463          	beq	s1,a5,80001a1c <remove_proc+0x8e>
  {
    release(head_lock);
    return -1;
  }
  acquire(&proc[*head_list].p_lock);
    800019b8:	18800513          	li	a0,392
    800019bc:	02a484b3          	mul	s1,s1,a0
    800019c0:	00010517          	auipc	a0,0x10
    800019c4:	e9050513          	addi	a0,a0,-368 # 80011850 <proc+0x38>
    800019c8:	9526                	add	a0,a0,s1
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	21a080e7          	jalr	538(ra) # 80000be4 <acquire>
  if (*head_list == to_remove->proc_idx)
    800019d2:	00092703          	lw	a4,0(s2)
    800019d6:	054a2783          	lw	a5,84(s4)
    800019da:	04f70763          	beq	a4,a5,80001a28 <remove_proc+0x9a>
    to_remove->next = -1;
    release(&to_remove->p_lock);
    release(head_lock);
    return 1;
  }
  release(head_lock);
    800019de:	854e                	mv	a0,s3
    800019e0:	fffff097          	auipc	ra,0xfffff
    800019e4:	2ca080e7          	jalr	714(ra) # 80000caa <release>
  return find_remove(&proc[*head_list], to_remove);
    800019e8:	00092783          	lw	a5,0(s2)
    800019ec:	18800513          	li	a0,392
    800019f0:	02a787b3          	mul	a5,a5,a0
    800019f4:	85d2                	mv	a1,s4
    800019f6:	00010517          	auipc	a0,0x10
    800019fa:	e2250513          	addi	a0,a0,-478 # 80011818 <proc>
    800019fe:	953e                	add	a0,a0,a5
    80001a00:	00000097          	auipc	ra,0x0
    80001a04:	edc080e7          	jalr	-292(ra) # 800018dc <find_remove>
    80001a08:	84aa                	mv	s1,a0
}
    80001a0a:	8526                	mv	a0,s1
    80001a0c:	70a2                	ld	ra,40(sp)
    80001a0e:	7402                	ld	s0,32(sp)
    80001a10:	64e2                	ld	s1,24(sp)
    80001a12:	6942                	ld	s2,16(sp)
    80001a14:	69a2                	ld	s3,8(sp)
    80001a16:	6a02                	ld	s4,0(sp)
    80001a18:	6145                	addi	sp,sp,48
    80001a1a:	8082                	ret
    release(head_lock);
    80001a1c:	854e                	mv	a0,s3
    80001a1e:	fffff097          	auipc	ra,0xfffff
    80001a22:	28c080e7          	jalr	652(ra) # 80000caa <release>
    return -1;
    80001a26:	b7d5                	j	80001a0a <remove_proc+0x7c>
    *head_list = to_remove->next;
    80001a28:	050a2783          	lw	a5,80(s4)
    80001a2c:	00f92023          	sw	a5,0(s2)
    to_remove->next = -1;
    80001a30:	57fd                	li	a5,-1
    80001a32:	04fa2823          	sw	a5,80(s4)
    release(&to_remove->p_lock);
    80001a36:	038a0513          	addi	a0,s4,56
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	270080e7          	jalr	624(ra) # 80000caa <release>
    release(head_lock);
    80001a42:	854e                	mv	a0,s3
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	266080e7          	jalr	614(ra) # 80000caa <release>
    return 1;
    80001a4c:	4485                	li	s1,1
    80001a4e:	bf75                	j	80001a0a <remove_proc+0x7c>

0000000080001a50 <add_proc>:

void add_proc(int* first_proc_id, struct proc* new_proc, struct spinlock* first_lock) {  //Tali's
    80001a50:	7139                	addi	sp,sp,-64
    80001a52:	fc06                	sd	ra,56(sp)
    80001a54:	f822                	sd	s0,48(sp)
    80001a56:	f426                	sd	s1,40(sp)
    80001a58:	f04a                	sd	s2,32(sp)
    80001a5a:	ec4e                	sd	s3,24(sp)
    80001a5c:	e852                	sd	s4,16(sp)
    80001a5e:	e456                	sd	s5,8(sp)
    80001a60:	e05a                	sd	s6,0(sp)
    80001a62:	0080                	addi	s0,sp,64
    80001a64:	84aa                	mv	s1,a0
    80001a66:	8b2e                	mv	s6,a1
    80001a68:	8932                	mv	s2,a2
    struct proc *curr_proc;
    struct proc *prev_proc;
    acquire(first_lock);
    80001a6a:	8532                	mv	a0,a2
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	178080e7          	jalr	376(ra) # 80000be4 <acquire>
    if (*first_proc_id == -1){
    80001a74:	409c                	lw	a5,0(s1)
    80001a76:	577d                	li	a4,-1
    80001a78:	08e78e63          	beq	a5,a4,80001b14 <add_proc+0xc4>
        *first_proc_id = new_proc->proc_idx;
        new_proc->next = -1;
        release(first_lock);
        return;
    }
    curr_proc = &proc[*first_proc_id];
    80001a7c:	18800513          	li	a0,392
    80001a80:	02a787b3          	mul	a5,a5,a0
    80001a84:	00010517          	auipc	a0,0x10
    80001a88:	d9450513          	addi	a0,a0,-620 # 80011818 <proc>
    80001a8c:	00a784b3          	add	s1,a5,a0
    acquire(&curr_proc->p_lock);
    80001a90:	03878793          	addi	a5,a5,56
    80001a94:	953e                	add	a0,a0,a5
    80001a96:	fffff097          	auipc	ra,0xfffff
    80001a9a:	14e080e7          	jalr	334(ra) # 80000be4 <acquire>
    release(first_lock);
    80001a9e:	854a                	mv	a0,s2
    80001aa0:	fffff097          	auipc	ra,0xfffff
    80001aa4:	20a080e7          	jalr	522(ra) # 80000caa <release>
    while (curr_proc->next != -1){
    80001aa8:	48a8                	lw	a0,80(s1)
    80001aaa:	57fd                	li	a5,-1
    80001aac:	02f50e63          	beq	a0,a5,80001ae8 <add_proc+0x98>
    80001ab0:	18800a93          	li	s5,392
        prev_proc = curr_proc;
        curr_proc = &proc[curr_proc->next];
    80001ab4:	00010917          	auipc	s2,0x10
    80001ab8:	d6490913          	addi	s2,s2,-668 # 80011818 <proc>
    while (curr_proc->next != -1){
    80001abc:	5a7d                	li	s4,-1
        curr_proc = &proc[curr_proc->next];
    80001abe:	03550533          	mul	a0,a0,s5
    80001ac2:	89a6                	mv	s3,s1
    80001ac4:	012504b3          	add	s1,a0,s2
        acquire(&curr_proc->p_lock);
    80001ac8:	03850513          	addi	a0,a0,56
    80001acc:	954a                	add	a0,a0,s2
    80001ace:	fffff097          	auipc	ra,0xfffff
    80001ad2:	116080e7          	jalr	278(ra) # 80000be4 <acquire>
        release(&prev_proc->p_lock);
    80001ad6:	03898513          	addi	a0,s3,56 # 1038 <_entry-0x7fffefc8>
    80001ada:	fffff097          	auipc	ra,0xfffff
    80001ade:	1d0080e7          	jalr	464(ra) # 80000caa <release>
    while (curr_proc->next != -1){
    80001ae2:	48a8                	lw	a0,80(s1)
    80001ae4:	fd451de3          	bne	a0,s4,80001abe <add_proc+0x6e>
    }
    curr_proc->next = new_proc->proc_idx;
    80001ae8:	054b2783          	lw	a5,84(s6) # 1054 <_entry-0x7fffefac>
    80001aec:	c8bc                	sw	a5,80(s1)
    new_proc->next= -1;
    80001aee:	57fd                	li	a5,-1
    80001af0:	04fb2823          	sw	a5,80(s6)
    release(&curr_proc->p_lock);
    80001af4:	03848513          	addi	a0,s1,56
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	1b2080e7          	jalr	434(ra) # 80000caa <release>
}
    80001b00:	70e2                	ld	ra,56(sp)
    80001b02:	7442                	ld	s0,48(sp)
    80001b04:	74a2                	ld	s1,40(sp)
    80001b06:	7902                	ld	s2,32(sp)
    80001b08:	69e2                	ld	s3,24(sp)
    80001b0a:	6a42                	ld	s4,16(sp)
    80001b0c:	6aa2                	ld	s5,8(sp)
    80001b0e:	6b02                	ld	s6,0(sp)
    80001b10:	6121                	addi	sp,sp,64
    80001b12:	8082                	ret
        *first_proc_id = new_proc->proc_idx;
    80001b14:	054b2783          	lw	a5,84(s6)
    80001b18:	c09c                	sw	a5,0(s1)
        new_proc->next = -1;
    80001b1a:	57fd                	li	a5,-1
    80001b1c:	04fb2823          	sw	a5,80(s6)
        release(first_lock);
    80001b20:	854a                	mv	a0,s2
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	188080e7          	jalr	392(ra) # 80000caa <release>
        return;
    80001b2a:	bfd9                	j	80001b00 <add_proc+0xb0>

0000000080001b2c <init_locks>:
//     release(head_lock);
//     add_not_first(&proc[*head], to_add);
//   }
// }
void init_locks()
{
    80001b2c:	7179                	addi	sp,sp,-48
    80001b2e:	f406                	sd	ra,40(sp)
    80001b30:	f022                	sd	s0,32(sp)
    80001b32:	ec26                	sd	s1,24(sp)
    80001b34:	e84a                	sd	s2,16(sp)
    80001b36:	e44e                	sd	s3,8(sp)
    80001b38:	e052                	sd	s4,0(sp)
    80001b3a:	1800                	addi	s0,sp,48
  struct cpu *c;
  initlock(&zombie_lock, "zombie");
    80001b3c:	00006597          	auipc	a1,0x6
    80001b40:	6bc58593          	addi	a1,a1,1724 # 800081f8 <digits+0x1b8>
    80001b44:	0000f517          	auipc	a0,0xf
    80001b48:	75c50513          	addi	a0,a0,1884 # 800112a0 <zombie_lock>
    80001b4c:	fffff097          	auipc	ra,0xfffff
    80001b50:	008080e7          	jalr	8(ra) # 80000b54 <initlock>
  initlock(&unused_lock, "unused");
    80001b54:	00006597          	auipc	a1,0x6
    80001b58:	6ac58593          	addi	a1,a1,1708 # 80008200 <digits+0x1c0>
    80001b5c:	0000f517          	auipc	a0,0xf
    80001b60:	75c50513          	addi	a0,a0,1884 # 800112b8 <unused_lock>
    80001b64:	fffff097          	auipc	ra,0xfffff
    80001b68:	ff0080e7          	jalr	-16(ra) # 80000b54 <initlock>
  initlock(&sleeping_lock, "sleeping");
    80001b6c:	00006597          	auipc	a1,0x6
    80001b70:	69c58593          	addi	a1,a1,1692 # 80008208 <digits+0x1c8>
    80001b74:	0000f517          	auipc	a0,0xf
    80001b78:	75c50513          	addi	a0,a0,1884 # 800112d0 <sleeping_lock>
    80001b7c:	fffff097          	auipc	ra,0xfffff
    80001b80:	fd8080e7          	jalr	-40(ra) # 80000b54 <initlock>
  for (c = cpus; c < &cpus[NCPU]; c++)
    80001b84:	0000f497          	auipc	s1,0xf
    80001b88:	7ec48493          	addi	s1,s1,2028 # 80011370 <cpus+0x88>
    80001b8c:	00010a17          	auipc	s4,0x10
    80001b90:	ce4a0a13          	addi	s4,s4,-796 # 80011870 <proc+0x58>
  {
    c->runnable_head = -1;
    80001b94:	59fd                	li	s3,-1
    initlock(&c->head_lock, "runnable");
    80001b96:	00006917          	auipc	s2,0x6
    80001b9a:	68290913          	addi	s2,s2,1666 # 80008218 <digits+0x1d8>
    c->runnable_head = -1;
    80001b9e:	ff34ac23          	sw	s3,-8(s1)
    initlock(&c->head_lock, "runnable");
    80001ba2:	85ca                	mv	a1,s2
    80001ba4:	8526                	mv	a0,s1
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	fae080e7          	jalr	-82(ra) # 80000b54 <initlock>
  for (c = cpus; c < &cpus[NCPU]; c++)
    80001bae:	0a048493          	addi	s1,s1,160
    80001bb2:	ff4496e3          	bne	s1,s4,80001b9e <init_locks+0x72>
  }
}
    80001bb6:	70a2                	ld	ra,40(sp)
    80001bb8:	7402                	ld	s0,32(sp)
    80001bba:	64e2                	ld	s1,24(sp)
    80001bbc:	6942                	ld	s2,16(sp)
    80001bbe:	69a2                	ld	s3,8(sp)
    80001bc0:	6a02                	ld	s4,0(sp)
    80001bc2:	6145                	addi	sp,sp,48
    80001bc4:	8082                	ret

0000000080001bc6 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001bc6:	7139                	addi	sp,sp,-64
    80001bc8:	fc06                	sd	ra,56(sp)
    80001bca:	f822                	sd	s0,48(sp)
    80001bcc:	f426                	sd	s1,40(sp)
    80001bce:	f04a                	sd	s2,32(sp)
    80001bd0:	ec4e                	sd	s3,24(sp)
    80001bd2:	e852                	sd	s4,16(sp)
    80001bd4:	e456                	sd	s5,8(sp)
    80001bd6:	e05a                	sd	s6,0(sp)
    80001bd8:	0080                	addi	s0,sp,64
    80001bda:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001bdc:	00010497          	auipc	s1,0x10
    80001be0:	c3c48493          	addi	s1,s1,-964 # 80011818 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001be4:	8b26                	mv	s6,s1
    80001be6:	00006a97          	auipc	s5,0x6
    80001bea:	41aa8a93          	addi	s5,s5,1050 # 80008000 <etext>
    80001bee:	04000937          	lui	s2,0x4000
    80001bf2:	197d                	addi	s2,s2,-1
    80001bf4:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001bf6:	00016a17          	auipc	s4,0x16
    80001bfa:	e22a0a13          	addi	s4,s4,-478 # 80017a18 <tickslock>
    char *pa = kalloc();
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	ef6080e7          	jalr	-266(ra) # 80000af4 <kalloc>
    80001c06:	862a                	mv	a2,a0
    if (pa == 0)
    80001c08:	c131                	beqz	a0,80001c4c <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001c0a:	416485b3          	sub	a1,s1,s6
    80001c0e:	858d                	srai	a1,a1,0x3
    80001c10:	000ab783          	ld	a5,0(s5)
    80001c14:	02f585b3          	mul	a1,a1,a5
    80001c18:	2585                	addiw	a1,a1,1
    80001c1a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001c1e:	4719                	li	a4,6
    80001c20:	6685                	lui	a3,0x1
    80001c22:	40b905b3          	sub	a1,s2,a1
    80001c26:	854e                	mv	a0,s3
    80001c28:	fffff097          	auipc	ra,0xfffff
    80001c2c:	54c080e7          	jalr	1356(ra) # 80001174 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c30:	18848493          	addi	s1,s1,392
    80001c34:	fd4495e3          	bne	s1,s4,80001bfe <proc_mapstacks+0x38>
  }
}
    80001c38:	70e2                	ld	ra,56(sp)
    80001c3a:	7442                	ld	s0,48(sp)
    80001c3c:	74a2                	ld	s1,40(sp)
    80001c3e:	7902                	ld	s2,32(sp)
    80001c40:	69e2                	ld	s3,24(sp)
    80001c42:	6a42                	ld	s4,16(sp)
    80001c44:	6aa2                	ld	s5,8(sp)
    80001c46:	6b02                	ld	s6,0(sp)
    80001c48:	6121                	addi	sp,sp,64
    80001c4a:	8082                	ret
      panic("kalloc");
    80001c4c:	00006517          	auipc	a0,0x6
    80001c50:	5dc50513          	addi	a0,a0,1500 # 80008228 <digits+0x1e8>
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	8ea080e7          	jalr	-1814(ra) # 8000053e <panic>

0000000080001c5c <procinit>:
//     }
// }

// initialize the proc table at boot time.
void procinit(void)
{
    80001c5c:	711d                	addi	sp,sp,-96
    80001c5e:	ec86                	sd	ra,88(sp)
    80001c60:	e8a2                	sd	s0,80(sp)
    80001c62:	e4a6                	sd	s1,72(sp)
    80001c64:	e0ca                	sd	s2,64(sp)
    80001c66:	fc4e                	sd	s3,56(sp)
    80001c68:	f852                	sd	s4,48(sp)
    80001c6a:	f456                	sd	s5,40(sp)
    80001c6c:	f05a                	sd	s6,32(sp)
    80001c6e:	ec5e                	sd	s7,24(sp)
    80001c70:	e862                	sd	s8,16(sp)
    80001c72:	e466                	sd	s9,8(sp)
    80001c74:	e06a                	sd	s10,0(sp)
    80001c76:	1080                	addi	s0,sp,96
  init_locks();
    80001c78:	00000097          	auipc	ra,0x0
    80001c7c:	eb4080e7          	jalr	-332(ra) # 80001b2c <init_locks>
  int i = 0;
  struct proc *p;
  initlock(&pid_lock, "nextpid");
    80001c80:	00006597          	auipc	a1,0x6
    80001c84:	5b058593          	addi	a1,a1,1456 # 80008230 <digits+0x1f0>
    80001c88:	00010517          	auipc	a0,0x10
    80001c8c:	b6050513          	addi	a0,a0,-1184 # 800117e8 <pid_lock>
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	ec4080e7          	jalr	-316(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001c98:	00006597          	auipc	a1,0x6
    80001c9c:	5a058593          	addi	a1,a1,1440 # 80008238 <digits+0x1f8>
    80001ca0:	00010517          	auipc	a0,0x10
    80001ca4:	b6050513          	addi	a0,a0,-1184 # 80011800 <wait_lock>
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	eac080e7          	jalr	-340(ra) # 80000b54 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001cb0:	00010497          	auipc	s1,0x10
    80001cb4:	b6848493          	addi	s1,s1,-1176 # 80011818 <proc>
  int i = 0;
    80001cb8:	4901                	li	s2,0
  {
    initlock(&p->lock, "proc");
    80001cba:	00006d17          	auipc	s10,0x6
    80001cbe:	58ed0d13          	addi	s10,s10,1422 # 80008248 <digits+0x208>
    initlock(&p->p_lock, "p_lock");
    80001cc2:	00006c97          	auipc	s9,0x6
    80001cc6:	58ec8c93          	addi	s9,s9,1422 # 80008250 <digits+0x210>

    p->kstack = KSTACK((int)(p - proc));
    80001cca:	8c26                	mv	s8,s1
    80001ccc:	00006b97          	auipc	s7,0x6
    80001cd0:	334b8b93          	addi	s7,s7,820 # 80008000 <etext>
    80001cd4:	040009b7          	lui	s3,0x4000
    80001cd8:	19fd                	addi	s3,s3,-1
    80001cda:	09b2                	slli	s3,s3,0xc
    p->proc_idx = i;
    p->next = -1;
    80001cdc:	5b7d                	li	s6,-1
    add_proc(&unused_head, p, &unused_lock);
    80001cde:	0000fa97          	auipc	s5,0xf
    80001ce2:	5daa8a93          	addi	s5,s5,1498 # 800112b8 <unused_lock>
    80001ce6:	00007a17          	auipc	s4,0x7
    80001cea:	b8ea0a13          	addi	s4,s4,-1138 # 80008874 <unused_head>
    initlock(&p->lock, "proc");
    80001cee:	85ea                	mv	a1,s10
    80001cf0:	8526                	mv	a0,s1
    80001cf2:	fffff097          	auipc	ra,0xfffff
    80001cf6:	e62080e7          	jalr	-414(ra) # 80000b54 <initlock>
    initlock(&p->p_lock, "p_lock");
    80001cfa:	85e6                	mv	a1,s9
    80001cfc:	03848513          	addi	a0,s1,56
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	e54080e7          	jalr	-428(ra) # 80000b54 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    80001d08:	418487b3          	sub	a5,s1,s8
    80001d0c:	878d                	srai	a5,a5,0x3
    80001d0e:	000bb703          	ld	a4,0(s7)
    80001d12:	02e787b3          	mul	a5,a5,a4
    80001d16:	2785                	addiw	a5,a5,1
    80001d18:	00d7979b          	slliw	a5,a5,0xd
    80001d1c:	40f987b3          	sub	a5,s3,a5
    80001d20:	f0bc                	sd	a5,96(s1)
    p->proc_idx = i;
    80001d22:	0524aa23          	sw	s2,84(s1)
    p->next = -1;
    80001d26:	0564a823          	sw	s6,80(s1)
    add_proc(&unused_head, p, &unused_lock);
    80001d2a:	8656                	mv	a2,s5
    80001d2c:	85a6                	mv	a1,s1
    80001d2e:	8552                	mv	a0,s4
    80001d30:	00000097          	auipc	ra,0x0
    80001d34:	d20080e7          	jalr	-736(ra) # 80001a50 <add_proc>
    i++;
    80001d38:	2905                	addiw	s2,s2,1
  for (p = proc; p < &proc[NPROC]; p++)
    80001d3a:	18848493          	addi	s1,s1,392
    80001d3e:	04000793          	li	a5,64
    80001d42:	faf916e3          	bne	s2,a5,80001cee <procinit+0x92>
  // {
  //   remove_proc(&unused_head, p, &unused_lock);
  //   printf("%d\n", p->proc_idx );
  // }
  //   printf("last %d\n", proc[unused_head].next);
}
    80001d46:	60e6                	ld	ra,88(sp)
    80001d48:	6446                	ld	s0,80(sp)
    80001d4a:	64a6                	ld	s1,72(sp)
    80001d4c:	6906                	ld	s2,64(sp)
    80001d4e:	79e2                	ld	s3,56(sp)
    80001d50:	7a42                	ld	s4,48(sp)
    80001d52:	7aa2                	ld	s5,40(sp)
    80001d54:	7b02                	ld	s6,32(sp)
    80001d56:	6be2                	ld	s7,24(sp)
    80001d58:	6c42                	ld	s8,16(sp)
    80001d5a:	6ca2                	ld	s9,8(sp)
    80001d5c:	6d02                	ld	s10,0(sp)
    80001d5e:	6125                	addi	sp,sp,96
    80001d60:	8082                	ret

0000000080001d62 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001d62:	1141                	addi	sp,sp,-16
    80001d64:	e422                	sd	s0,8(sp)
    80001d66:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d68:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001d6a:	2501                	sext.w	a0,a0
    80001d6c:	6422                	ld	s0,8(sp)
    80001d6e:	0141                	addi	sp,sp,16
    80001d70:	8082                	ret

0000000080001d72 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001d72:	1141                	addi	sp,sp,-16
    80001d74:	e422                	sd	s0,8(sp)
    80001d76:	0800                	addi	s0,sp,16
    80001d78:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001d7a:	0007851b          	sext.w	a0,a5
    80001d7e:	00251793          	slli	a5,a0,0x2
    80001d82:	97aa                	add	a5,a5,a0
    80001d84:	0796                	slli	a5,a5,0x5
  return c;
}
    80001d86:	0000f517          	auipc	a0,0xf
    80001d8a:	56250513          	addi	a0,a0,1378 # 800112e8 <cpus>
    80001d8e:	953e                	add	a0,a0,a5
    80001d90:	6422                	ld	s0,8(sp)
    80001d92:	0141                	addi	sp,sp,16
    80001d94:	8082                	ret

0000000080001d96 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001d96:	1101                	addi	sp,sp,-32
    80001d98:	ec06                	sd	ra,24(sp)
    80001d9a:	e822                	sd	s0,16(sp)
    80001d9c:	e426                	sd	s1,8(sp)
    80001d9e:	1000                	addi	s0,sp,32
  push_off();
    80001da0:	fffff097          	auipc	ra,0xfffff
    80001da4:	df8080e7          	jalr	-520(ra) # 80000b98 <push_off>
    80001da8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001daa:	0007871b          	sext.w	a4,a5
    80001dae:	00271793          	slli	a5,a4,0x2
    80001db2:	97ba                	add	a5,a5,a4
    80001db4:	0796                	slli	a5,a5,0x5
    80001db6:	0000f717          	auipc	a4,0xf
    80001dba:	4ea70713          	addi	a4,a4,1258 # 800112a0 <zombie_lock>
    80001dbe:	97ba                	add	a5,a5,a4
    80001dc0:	67a4                	ld	s1,72(a5)
  pop_off();
    80001dc2:	fffff097          	auipc	ra,0xfffff
    80001dc6:	e88080e7          	jalr	-376(ra) # 80000c4a <pop_off>
  return p;
}
    80001dca:	8526                	mv	a0,s1
    80001dcc:	60e2                	ld	ra,24(sp)
    80001dce:	6442                	ld	s0,16(sp)
    80001dd0:	64a2                	ld	s1,8(sp)
    80001dd2:	6105                	addi	sp,sp,32
    80001dd4:	8082                	ret

0000000080001dd6 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001dd6:	1141                	addi	sp,sp,-16
    80001dd8:	e406                	sd	ra,8(sp)
    80001dda:	e022                	sd	s0,0(sp)
    80001ddc:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001dde:	00000097          	auipc	ra,0x0
    80001de2:	fb8080e7          	jalr	-72(ra) # 80001d96 <myproc>
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	ec4080e7          	jalr	-316(ra) # 80000caa <release>

  if (first)
    80001dee:	00007797          	auipc	a5,0x7
    80001df2:	a827a783          	lw	a5,-1406(a5) # 80008870 <first.1726>
    80001df6:	eb89                	bnez	a5,80001e08 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001df8:	00001097          	auipc	ra,0x1
    80001dfc:	e8e080e7          	jalr	-370(ra) # 80002c86 <usertrapret>
}
    80001e00:	60a2                	ld	ra,8(sp)
    80001e02:	6402                	ld	s0,0(sp)
    80001e04:	0141                	addi	sp,sp,16
    80001e06:	8082                	ret
    first = 0;
    80001e08:	00007797          	auipc	a5,0x7
    80001e0c:	a607a423          	sw	zero,-1432(a5) # 80008870 <first.1726>
    fsinit(ROOTDEV);
    80001e10:	4505                	li	a0,1
    80001e12:	00002097          	auipc	ra,0x2
    80001e16:	c00080e7          	jalr	-1024(ra) # 80003a12 <fsinit>
    80001e1a:	bff9                	j	80001df8 <forkret+0x22>

0000000080001e1c <allocpid>:
{
    80001e1c:	1101                	addi	sp,sp,-32
    80001e1e:	ec06                	sd	ra,24(sp)
    80001e20:	e822                	sd	s0,16(sp)
    80001e22:	e426                	sd	s1,8(sp)
    80001e24:	e04a                	sd	s2,0(sp)
    80001e26:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001e28:	00007917          	auipc	s2,0x7
    80001e2c:	a5890913          	addi	s2,s2,-1448 # 80008880 <nextpid>
    80001e30:	00092603          	lw	a2,0(s2)
    80001e34:	0006049b          	sext.w	s1,a2
  } while (cas(&nextpid, pid, pid + 1));
    80001e38:	2605                	addiw	a2,a2,1
    80001e3a:	85a6                	mv	a1,s1
    80001e3c:	854a                	mv	a0,s2
    80001e3e:	00005097          	auipc	ra,0x5
    80001e42:	9d8080e7          	jalr	-1576(ra) # 80006816 <cas>
    80001e46:	f56d                	bnez	a0,80001e30 <allocpid+0x14>
}
    80001e48:	8526                	mv	a0,s1
    80001e4a:	60e2                	ld	ra,24(sp)
    80001e4c:	6442                	ld	s0,16(sp)
    80001e4e:	64a2                	ld	s1,8(sp)
    80001e50:	6902                	ld	s2,0(sp)
    80001e52:	6105                	addi	sp,sp,32
    80001e54:	8082                	ret

0000000080001e56 <proc_pagetable>:
{
    80001e56:	1101                	addi	sp,sp,-32
    80001e58:	ec06                	sd	ra,24(sp)
    80001e5a:	e822                	sd	s0,16(sp)
    80001e5c:	e426                	sd	s1,8(sp)
    80001e5e:	e04a                	sd	s2,0(sp)
    80001e60:	1000                	addi	s0,sp,32
    80001e62:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	4fa080e7          	jalr	1274(ra) # 8000135e <uvmcreate>
    80001e6c:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001e6e:	c121                	beqz	a0,80001eae <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e70:	4729                	li	a4,10
    80001e72:	00005697          	auipc	a3,0x5
    80001e76:	18e68693          	addi	a3,a3,398 # 80007000 <_trampoline>
    80001e7a:	6605                	lui	a2,0x1
    80001e7c:	040005b7          	lui	a1,0x4000
    80001e80:	15fd                	addi	a1,a1,-1
    80001e82:	05b2                	slli	a1,a1,0xc
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	250080e7          	jalr	592(ra) # 800010d4 <mappages>
    80001e8c:	02054863          	bltz	a0,80001ebc <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e90:	4719                	li	a4,6
    80001e92:	07893683          	ld	a3,120(s2)
    80001e96:	6605                	lui	a2,0x1
    80001e98:	020005b7          	lui	a1,0x2000
    80001e9c:	15fd                	addi	a1,a1,-1
    80001e9e:	05b6                	slli	a1,a1,0xd
    80001ea0:	8526                	mv	a0,s1
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	232080e7          	jalr	562(ra) # 800010d4 <mappages>
    80001eaa:	02054163          	bltz	a0,80001ecc <proc_pagetable+0x76>
}
    80001eae:	8526                	mv	a0,s1
    80001eb0:	60e2                	ld	ra,24(sp)
    80001eb2:	6442                	ld	s0,16(sp)
    80001eb4:	64a2                	ld	s1,8(sp)
    80001eb6:	6902                	ld	s2,0(sp)
    80001eb8:	6105                	addi	sp,sp,32
    80001eba:	8082                	ret
    uvmfree(pagetable, 0);
    80001ebc:	4581                	li	a1,0
    80001ebe:	8526                	mv	a0,s1
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	69a080e7          	jalr	1690(ra) # 8000155a <uvmfree>
    return 0;
    80001ec8:	4481                	li	s1,0
    80001eca:	b7d5                	j	80001eae <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ecc:	4681                	li	a3,0
    80001ece:	4605                	li	a2,1
    80001ed0:	040005b7          	lui	a1,0x4000
    80001ed4:	15fd                	addi	a1,a1,-1
    80001ed6:	05b2                	slli	a1,a1,0xc
    80001ed8:	8526                	mv	a0,s1
    80001eda:	fffff097          	auipc	ra,0xfffff
    80001ede:	3c0080e7          	jalr	960(ra) # 8000129a <uvmunmap>
    uvmfree(pagetable, 0);
    80001ee2:	4581                	li	a1,0
    80001ee4:	8526                	mv	a0,s1
    80001ee6:	fffff097          	auipc	ra,0xfffff
    80001eea:	674080e7          	jalr	1652(ra) # 8000155a <uvmfree>
    return 0;
    80001eee:	4481                	li	s1,0
    80001ef0:	bf7d                	j	80001eae <proc_pagetable+0x58>

0000000080001ef2 <proc_freepagetable>:
{
    80001ef2:	1101                	addi	sp,sp,-32
    80001ef4:	ec06                	sd	ra,24(sp)
    80001ef6:	e822                	sd	s0,16(sp)
    80001ef8:	e426                	sd	s1,8(sp)
    80001efa:	e04a                	sd	s2,0(sp)
    80001efc:	1000                	addi	s0,sp,32
    80001efe:	84aa                	mv	s1,a0
    80001f00:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f02:	4681                	li	a3,0
    80001f04:	4605                	li	a2,1
    80001f06:	040005b7          	lui	a1,0x4000
    80001f0a:	15fd                	addi	a1,a1,-1
    80001f0c:	05b2                	slli	a1,a1,0xc
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	38c080e7          	jalr	908(ra) # 8000129a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001f16:	4681                	li	a3,0
    80001f18:	4605                	li	a2,1
    80001f1a:	020005b7          	lui	a1,0x2000
    80001f1e:	15fd                	addi	a1,a1,-1
    80001f20:	05b6                	slli	a1,a1,0xd
    80001f22:	8526                	mv	a0,s1
    80001f24:	fffff097          	auipc	ra,0xfffff
    80001f28:	376080e7          	jalr	886(ra) # 8000129a <uvmunmap>
  uvmfree(pagetable, sz);
    80001f2c:	85ca                	mv	a1,s2
    80001f2e:	8526                	mv	a0,s1
    80001f30:	fffff097          	auipc	ra,0xfffff
    80001f34:	62a080e7          	jalr	1578(ra) # 8000155a <uvmfree>
}
    80001f38:	60e2                	ld	ra,24(sp)
    80001f3a:	6442                	ld	s0,16(sp)
    80001f3c:	64a2                	ld	s1,8(sp)
    80001f3e:	6902                	ld	s2,0(sp)
    80001f40:	6105                	addi	sp,sp,32
    80001f42:	8082                	ret

0000000080001f44 <freeproc>:
{
    80001f44:	1101                	addi	sp,sp,-32
    80001f46:	ec06                	sd	ra,24(sp)
    80001f48:	e822                	sd	s0,16(sp)
    80001f4a:	e426                	sd	s1,8(sp)
    80001f4c:	1000                	addi	s0,sp,32
    80001f4e:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001f50:	7d28                	ld	a0,120(a0)
    80001f52:	c509                	beqz	a0,80001f5c <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	aa4080e7          	jalr	-1372(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001f5c:	0604bc23          	sd	zero,120(s1)
  if (p->pagetable)
    80001f60:	78a8                	ld	a0,112(s1)
    80001f62:	c511                	beqz	a0,80001f6e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001f64:	74ac                	ld	a1,104(s1)
    80001f66:	00000097          	auipc	ra,0x0
    80001f6a:	f8c080e7          	jalr	-116(ra) # 80001ef2 <proc_freepagetable>
  p->pagetable = 0;
    80001f6e:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80001f72:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80001f76:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001f7a:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80001f7e:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80001f82:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001f86:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001f8a:	0204a623          	sw	zero,44(s1)
  remove_proc(&zombie_head, p, &zombie_lock);
    80001f8e:	0000f617          	auipc	a2,0xf
    80001f92:	31260613          	addi	a2,a2,786 # 800112a0 <zombie_lock>
    80001f96:	85a6                	mv	a1,s1
    80001f98:	00007517          	auipc	a0,0x7
    80001f9c:	8e450513          	addi	a0,a0,-1820 # 8000887c <zombie_head>
    80001fa0:	00000097          	auipc	ra,0x0
    80001fa4:	9ee080e7          	jalr	-1554(ra) # 8000198e <remove_proc>
  p->state = UNUSED;
    80001fa8:	0004ac23          	sw	zero,24(s1)
  add_proc(&unused_head, p, &unused_lock);
    80001fac:	0000f617          	auipc	a2,0xf
    80001fb0:	30c60613          	addi	a2,a2,780 # 800112b8 <unused_lock>
    80001fb4:	85a6                	mv	a1,s1
    80001fb6:	00007517          	auipc	a0,0x7
    80001fba:	8be50513          	addi	a0,a0,-1858 # 80008874 <unused_head>
    80001fbe:	00000097          	auipc	ra,0x0
    80001fc2:	a92080e7          	jalr	-1390(ra) # 80001a50 <add_proc>
}
    80001fc6:	60e2                	ld	ra,24(sp)
    80001fc8:	6442                	ld	s0,16(sp)
    80001fca:	64a2                	ld	s1,8(sp)
    80001fcc:	6105                	addi	sp,sp,32
    80001fce:	8082                	ret

0000000080001fd0 <allocproc>:
{
    80001fd0:	7179                	addi	sp,sp,-48
    80001fd2:	f406                	sd	ra,40(sp)
    80001fd4:	f022                	sd	s0,32(sp)
    80001fd6:	ec26                	sd	s1,24(sp)
    80001fd8:	e84a                	sd	s2,16(sp)
    80001fda:	e44e                	sd	s3,8(sp)
    80001fdc:	e052                	sd	s4,0(sp)
    80001fde:	1800                	addi	s0,sp,48
  if (unused_head != -1)
    80001fe0:	00007917          	auipc	s2,0x7
    80001fe4:	89492903          	lw	s2,-1900(s2) # 80008874 <unused_head>
    80001fe8:	57fd                	li	a5,-1
  return 0;
    80001fea:	4481                	li	s1,0
  if (unused_head != -1)
    80001fec:	0af90b63          	beq	s2,a5,800020a2 <allocproc+0xd2>
    p = &proc[unused_head];
    80001ff0:	18800993          	li	s3,392
    80001ff4:	033909b3          	mul	s3,s2,s3
    80001ff8:	00010497          	auipc	s1,0x10
    80001ffc:	82048493          	addi	s1,s1,-2016 # 80011818 <proc>
    80002000:	94ce                	add	s1,s1,s3
    acquire(&p->lock);
    80002002:	8526                	mv	a0,s1
    80002004:	fffff097          	auipc	ra,0xfffff
    80002008:	be0080e7          	jalr	-1056(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    8000200c:	00000097          	auipc	ra,0x0
    80002010:	e10080e7          	jalr	-496(ra) # 80001e1c <allocpid>
    80002014:	d888                	sw	a0,48(s1)
  remove_proc(&unused_head, p, &unused_lock);
    80002016:	0000f617          	auipc	a2,0xf
    8000201a:	2a260613          	addi	a2,a2,674 # 800112b8 <unused_lock>
    8000201e:	85a6                	mv	a1,s1
    80002020:	00007517          	auipc	a0,0x7
    80002024:	85450513          	addi	a0,a0,-1964 # 80008874 <unused_head>
    80002028:	00000097          	auipc	ra,0x0
    8000202c:	966080e7          	jalr	-1690(ra) # 8000198e <remove_proc>
  p->state = USED;
    80002030:	4785                	li	a5,1
    80002032:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	ac0080e7          	jalr	-1344(ra) # 80000af4 <kalloc>
    8000203c:	8a2a                	mv	s4,a0
    8000203e:	fca8                	sd	a0,120(s1)
    80002040:	c935                	beqz	a0,800020b4 <allocproc+0xe4>
  p->pagetable = proc_pagetable(p);
    80002042:	8526                	mv	a0,s1
    80002044:	00000097          	auipc	ra,0x0
    80002048:	e12080e7          	jalr	-494(ra) # 80001e56 <proc_pagetable>
    8000204c:	8a2a                	mv	s4,a0
    8000204e:	18800793          	li	a5,392
    80002052:	02f90733          	mul	a4,s2,a5
    80002056:	0000f797          	auipc	a5,0xf
    8000205a:	7c278793          	addi	a5,a5,1986 # 80011818 <proc>
    8000205e:	97ba                	add	a5,a5,a4
    80002060:	fba8                	sd	a0,112(a5)
  if (p->pagetable == 0)
    80002062:	c52d                	beqz	a0,800020cc <allocproc+0xfc>
  memset(&p->context, 0, sizeof(p->context));
    80002064:	08098513          	addi	a0,s3,128 # 4000080 <_entry-0x7bffff80>
    80002068:	0000fa17          	auipc	s4,0xf
    8000206c:	7b0a0a13          	addi	s4,s4,1968 # 80011818 <proc>
    80002070:	07000613          	li	a2,112
    80002074:	4581                	li	a1,0
    80002076:	9552                	add	a0,a0,s4
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	c8c080e7          	jalr	-884(ra) # 80000d04 <memset>
  p->context.ra = (uint64)forkret;
    80002080:	18800793          	li	a5,392
    80002084:	02f90933          	mul	s2,s2,a5
    80002088:	9952                	add	s2,s2,s4
    8000208a:	00000797          	auipc	a5,0x0
    8000208e:	d4c78793          	addi	a5,a5,-692 # 80001dd6 <forkret>
    80002092:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002096:	06093783          	ld	a5,96(s2)
    8000209a:	6705                	lui	a4,0x1
    8000209c:	97ba                	add	a5,a5,a4
    8000209e:	08f93423          	sd	a5,136(s2)
}
    800020a2:	8526                	mv	a0,s1
    800020a4:	70a2                	ld	ra,40(sp)
    800020a6:	7402                	ld	s0,32(sp)
    800020a8:	64e2                	ld	s1,24(sp)
    800020aa:	6942                	ld	s2,16(sp)
    800020ac:	69a2                	ld	s3,8(sp)
    800020ae:	6a02                	ld	s4,0(sp)
    800020b0:	6145                	addi	sp,sp,48
    800020b2:	8082                	ret
    freeproc(p);
    800020b4:	8526                	mv	a0,s1
    800020b6:	00000097          	auipc	ra,0x0
    800020ba:	e8e080e7          	jalr	-370(ra) # 80001f44 <freeproc>
    release(&p->lock);
    800020be:	8526                	mv	a0,s1
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	bea080e7          	jalr	-1046(ra) # 80000caa <release>
    return 0;
    800020c8:	84d2                	mv	s1,s4
    800020ca:	bfe1                	j	800020a2 <allocproc+0xd2>
    freeproc(p);
    800020cc:	8526                	mv	a0,s1
    800020ce:	00000097          	auipc	ra,0x0
    800020d2:	e76080e7          	jalr	-394(ra) # 80001f44 <freeproc>
    release(&p->lock);
    800020d6:	8526                	mv	a0,s1
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	bd2080e7          	jalr	-1070(ra) # 80000caa <release>
    return 0;
    800020e0:	84d2                	mv	s1,s4
    800020e2:	b7c1                	j	800020a2 <allocproc+0xd2>

00000000800020e4 <userinit>:
{
    800020e4:	1101                	addi	sp,sp,-32
    800020e6:	ec06                	sd	ra,24(sp)
    800020e8:	e822                	sd	s0,16(sp)
    800020ea:	e426                	sd	s1,8(sp)
    800020ec:	1000                	addi	s0,sp,32
  p = allocproc();
    800020ee:	00000097          	auipc	ra,0x0
    800020f2:	ee2080e7          	jalr	-286(ra) # 80001fd0 <allocproc>
    800020f6:	84aa                	mv	s1,a0
  initproc = p;
    800020f8:	00007797          	auipc	a5,0x7
    800020fc:	f2a7b823          	sd	a0,-208(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002100:	03400613          	li	a2,52
    80002104:	00006597          	auipc	a1,0x6
    80002108:	78c58593          	addi	a1,a1,1932 # 80008890 <initcode>
    8000210c:	7928                	ld	a0,112(a0)
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	27e080e7          	jalr	638(ra) # 8000138c <uvminit>
  p->sz = PGSIZE;
    80002116:	6785                	lui	a5,0x1
    80002118:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;     // user program counter
    8000211a:	7cb8                	ld	a4,120(s1)
    8000211c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80002120:	7cb8                	ld	a4,120(s1)
    80002122:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002124:	4641                	li	a2,16
    80002126:	00006597          	auipc	a1,0x6
    8000212a:	13258593          	addi	a1,a1,306 # 80008258 <digits+0x218>
    8000212e:	17848513          	addi	a0,s1,376
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	d24080e7          	jalr	-732(ra) # 80000e56 <safestrcpy>
  p->cwd = namei("/");
    8000213a:	00006517          	auipc	a0,0x6
    8000213e:	12e50513          	addi	a0,a0,302 # 80008268 <digits+0x228>
    80002142:	00002097          	auipc	ra,0x2
    80002146:	2fe080e7          	jalr	766(ra) # 80004440 <namei>
    8000214a:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    8000214e:	478d                	li	a5,3
    80002150:	cc9c                	sw	a5,24(s1)
  add_proc(&cpus[0].runnable_head, p, &cpus[0].head_lock);
    80002152:	0000f617          	auipc	a2,0xf
    80002156:	21e60613          	addi	a2,a2,542 # 80011370 <cpus+0x88>
    8000215a:	85a6                	mv	a1,s1
    8000215c:	0000f517          	auipc	a0,0xf
    80002160:	20c50513          	addi	a0,a0,524 # 80011368 <cpus+0x80>
    80002164:	00000097          	auipc	ra,0x0
    80002168:	8ec080e7          	jalr	-1812(ra) # 80001a50 <add_proc>
  release(&p->lock);
    8000216c:	8526                	mv	a0,s1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	b3c080e7          	jalr	-1220(ra) # 80000caa <release>
}
    80002176:	60e2                	ld	ra,24(sp)
    80002178:	6442                	ld	s0,16(sp)
    8000217a:	64a2                	ld	s1,8(sp)
    8000217c:	6105                	addi	sp,sp,32
    8000217e:	8082                	ret

0000000080002180 <growproc>:
{
    80002180:	1101                	addi	sp,sp,-32
    80002182:	ec06                	sd	ra,24(sp)
    80002184:	e822                	sd	s0,16(sp)
    80002186:	e426                	sd	s1,8(sp)
    80002188:	e04a                	sd	s2,0(sp)
    8000218a:	1000                	addi	s0,sp,32
    8000218c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000218e:	00000097          	auipc	ra,0x0
    80002192:	c08080e7          	jalr	-1016(ra) # 80001d96 <myproc>
    80002196:	892a                	mv	s2,a0
  sz = p->sz;
    80002198:	752c                	ld	a1,104(a0)
    8000219a:	0005861b          	sext.w	a2,a1
  if (n > 0)
    8000219e:	00904f63          	bgtz	s1,800021bc <growproc+0x3c>
  else if (n < 0)
    800021a2:	0204cc63          	bltz	s1,800021da <growproc+0x5a>
  p->sz = sz;
    800021a6:	1602                	slli	a2,a2,0x20
    800021a8:	9201                	srli	a2,a2,0x20
    800021aa:	06c93423          	sd	a2,104(s2)
  return 0;
    800021ae:	4501                	li	a0,0
}
    800021b0:	60e2                	ld	ra,24(sp)
    800021b2:	6442                	ld	s0,16(sp)
    800021b4:	64a2                	ld	s1,8(sp)
    800021b6:	6902                	ld	s2,0(sp)
    800021b8:	6105                	addi	sp,sp,32
    800021ba:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    800021bc:	9e25                	addw	a2,a2,s1
    800021be:	1602                	slli	a2,a2,0x20
    800021c0:	9201                	srli	a2,a2,0x20
    800021c2:	1582                	slli	a1,a1,0x20
    800021c4:	9181                	srli	a1,a1,0x20
    800021c6:	7928                	ld	a0,112(a0)
    800021c8:	fffff097          	auipc	ra,0xfffff
    800021cc:	27e080e7          	jalr	638(ra) # 80001446 <uvmalloc>
    800021d0:	0005061b          	sext.w	a2,a0
    800021d4:	fa69                	bnez	a2,800021a6 <growproc+0x26>
      return -1;
    800021d6:	557d                	li	a0,-1
    800021d8:	bfe1                	j	800021b0 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800021da:	9e25                	addw	a2,a2,s1
    800021dc:	1602                	slli	a2,a2,0x20
    800021de:	9201                	srli	a2,a2,0x20
    800021e0:	1582                	slli	a1,a1,0x20
    800021e2:	9181                	srli	a1,a1,0x20
    800021e4:	7928                	ld	a0,112(a0)
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	218080e7          	jalr	536(ra) # 800013fe <uvmdealloc>
    800021ee:	0005061b          	sext.w	a2,a0
    800021f2:	bf55                	j	800021a6 <growproc+0x26>

00000000800021f4 <scheduler>:
{
    800021f4:	711d                	addi	sp,sp,-96
    800021f6:	ec86                	sd	ra,88(sp)
    800021f8:	e8a2                	sd	s0,80(sp)
    800021fa:	e4a6                	sd	s1,72(sp)
    800021fc:	e0ca                	sd	s2,64(sp)
    800021fe:	fc4e                	sd	s3,56(sp)
    80002200:	f852                	sd	s4,48(sp)
    80002202:	f456                	sd	s5,40(sp)
    80002204:	f05a                	sd	s6,32(sp)
    80002206:	ec5e                	sd	s7,24(sp)
    80002208:	e862                	sd	s8,16(sp)
    8000220a:	e466                	sd	s9,8(sp)
    8000220c:	e06a                	sd	s10,0(sp)
    8000220e:	1080                	addi	s0,sp,96
    80002210:	8712                	mv	a4,tp
  int id = r_tp();
    80002212:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002214:	00271793          	slli	a5,a4,0x2
    80002218:	00e786b3          	add	a3,a5,a4
    8000221c:	00569613          	slli	a2,a3,0x5
    80002220:	0000f697          	auipc	a3,0xf
    80002224:	08068693          	addi	a3,a3,128 # 800112a0 <zombie_lock>
    80002228:	96b2                	add	a3,a3,a2
    8000222a:	0406b423          	sd	zero,72(a3)
      remove_proc(&c->runnable_head, p, &c->head_lock);
    8000222e:	0000fa97          	auipc	s5,0xf
    80002232:	0baa8a93          	addi	s5,s5,186 # 800112e8 <cpus>
    80002236:	08060b93          	addi	s7,a2,128
    8000223a:	9bd6                	add	s7,s7,s5
    8000223c:	08860b13          	addi	s6,a2,136
    80002240:	9b56                	add	s6,s6,s5
      swtch(&c->context, &p->context);
    80002242:	00860793          	addi	a5,a2,8
    80002246:	9abe                	add	s5,s5,a5
    if (c->runnable_head != -1)
    80002248:	8936                	mv	s2,a3
    8000224a:	59fd                	li	s3,-1
    8000224c:	18800c93          	li	s9,392
      p = &proc[c->runnable_head];
    80002250:	0000fa17          	auipc	s4,0xf
    80002254:	5c8a0a13          	addi	s4,s4,1480 # 80011818 <proc>
      p->state = RUNNING;
    80002258:	4c11                	li	s8,4
    8000225a:	a0a1                	j	800022a2 <scheduler+0xae>
      p = &proc[c->runnable_head];
    8000225c:	039584b3          	mul	s1,a1,s9
    80002260:	01448d33          	add	s10,s1,s4
      acquire(&p->lock);
    80002264:	856a                	mv	a0,s10
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	97e080e7          	jalr	-1666(ra) # 80000be4 <acquire>
      remove_proc(&c->runnable_head, p, &c->head_lock);
    8000226e:	865a                	mv	a2,s6
    80002270:	85ea                	mv	a1,s10
    80002272:	855e                	mv	a0,s7
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	71a080e7          	jalr	1818(ra) # 8000198e <remove_proc>
      p->state = RUNNING;
    8000227c:	018d2c23          	sw	s8,24(s10)
      c->proc = p;
    80002280:	05a93423          	sd	s10,72(s2)
      swtch(&c->context, &p->context);
    80002284:	08048593          	addi	a1,s1,128
    80002288:	95d2                	add	a1,a1,s4
    8000228a:	8556                	mv	a0,s5
    8000228c:	00001097          	auipc	ra,0x1
    80002290:	950080e7          	jalr	-1712(ra) # 80002bdc <swtch>
      c->proc = 0;
    80002294:	04093423          	sd	zero,72(s2)
      release(&p->lock);
    80002298:	856a                	mv	a0,s10
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	a10080e7          	jalr	-1520(ra) # 80000caa <release>
    if (c->runnable_head != -1)
    800022a2:	0c892583          	lw	a1,200(s2)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022a6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022aa:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022ae:	10079073          	csrw	sstatus,a5
    800022b2:	ff358ae3          	beq	a1,s3,800022a6 <scheduler+0xb2>
    800022b6:	b75d                	j	8000225c <scheduler+0x68>

00000000800022b8 <sched>:
{
    800022b8:	7179                	addi	sp,sp,-48
    800022ba:	f406                	sd	ra,40(sp)
    800022bc:	f022                	sd	s0,32(sp)
    800022be:	ec26                	sd	s1,24(sp)
    800022c0:	e84a                	sd	s2,16(sp)
    800022c2:	e44e                	sd	s3,8(sp)
    800022c4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022c6:	00000097          	auipc	ra,0x0
    800022ca:	ad0080e7          	jalr	-1328(ra) # 80001d96 <myproc>
    800022ce:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	89a080e7          	jalr	-1894(ra) # 80000b6a <holding>
    800022d8:	c959                	beqz	a0,8000236e <sched+0xb6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022da:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800022dc:	0007871b          	sext.w	a4,a5
    800022e0:	00271793          	slli	a5,a4,0x2
    800022e4:	97ba                	add	a5,a5,a4
    800022e6:	0796                	slli	a5,a5,0x5
    800022e8:	0000f717          	auipc	a4,0xf
    800022ec:	fb870713          	addi	a4,a4,-72 # 800112a0 <zombie_lock>
    800022f0:	97ba                	add	a5,a5,a4
    800022f2:	0c07a703          	lw	a4,192(a5) # 10c0 <_entry-0x7fffef40>
    800022f6:	4785                	li	a5,1
    800022f8:	08f71363          	bne	a4,a5,8000237e <sched+0xc6>
  if (p->state == RUNNING)
    800022fc:	4c98                	lw	a4,24(s1)
    800022fe:	4791                	li	a5,4
    80002300:	08f70763          	beq	a4,a5,8000238e <sched+0xd6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002304:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002308:	8b89                	andi	a5,a5,2
  if (intr_get())
    8000230a:	ebd1                	bnez	a5,8000239e <sched+0xe6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000230c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000230e:	0000f917          	auipc	s2,0xf
    80002312:	f9290913          	addi	s2,s2,-110 # 800112a0 <zombie_lock>
    80002316:	0007871b          	sext.w	a4,a5
    8000231a:	00271793          	slli	a5,a4,0x2
    8000231e:	97ba                	add	a5,a5,a4
    80002320:	0796                	slli	a5,a5,0x5
    80002322:	97ca                	add	a5,a5,s2
    80002324:	0c47a983          	lw	s3,196(a5)
    80002328:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000232a:	0007859b          	sext.w	a1,a5
    8000232e:	00259793          	slli	a5,a1,0x2
    80002332:	97ae                	add	a5,a5,a1
    80002334:	0796                	slli	a5,a5,0x5
    80002336:	0000f597          	auipc	a1,0xf
    8000233a:	fba58593          	addi	a1,a1,-70 # 800112f0 <cpus+0x8>
    8000233e:	95be                	add	a1,a1,a5
    80002340:	08048513          	addi	a0,s1,128
    80002344:	00001097          	auipc	ra,0x1
    80002348:	898080e7          	jalr	-1896(ra) # 80002bdc <swtch>
    8000234c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000234e:	0007871b          	sext.w	a4,a5
    80002352:	00271793          	slli	a5,a4,0x2
    80002356:	97ba                	add	a5,a5,a4
    80002358:	0796                	slli	a5,a5,0x5
    8000235a:	97ca                	add	a5,a5,s2
    8000235c:	0d37a223          	sw	s3,196(a5)
}
    80002360:	70a2                	ld	ra,40(sp)
    80002362:	7402                	ld	s0,32(sp)
    80002364:	64e2                	ld	s1,24(sp)
    80002366:	6942                	ld	s2,16(sp)
    80002368:	69a2                	ld	s3,8(sp)
    8000236a:	6145                	addi	sp,sp,48
    8000236c:	8082                	ret
    panic("sched p->lock");
    8000236e:	00006517          	auipc	a0,0x6
    80002372:	f0250513          	addi	a0,a0,-254 # 80008270 <digits+0x230>
    80002376:	ffffe097          	auipc	ra,0xffffe
    8000237a:	1c8080e7          	jalr	456(ra) # 8000053e <panic>
    panic("sched locks");
    8000237e:	00006517          	auipc	a0,0x6
    80002382:	f0250513          	addi	a0,a0,-254 # 80008280 <digits+0x240>
    80002386:	ffffe097          	auipc	ra,0xffffe
    8000238a:	1b8080e7          	jalr	440(ra) # 8000053e <panic>
    panic("sched running");
    8000238e:	00006517          	auipc	a0,0x6
    80002392:	f0250513          	addi	a0,a0,-254 # 80008290 <digits+0x250>
    80002396:	ffffe097          	auipc	ra,0xffffe
    8000239a:	1a8080e7          	jalr	424(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000239e:	00006517          	auipc	a0,0x6
    800023a2:	f0250513          	addi	a0,a0,-254 # 800082a0 <digits+0x260>
    800023a6:	ffffe097          	auipc	ra,0xffffe
    800023aa:	198080e7          	jalr	408(ra) # 8000053e <panic>

00000000800023ae <yield>:
{
    800023ae:	1101                	addi	sp,sp,-32
    800023b0:	ec06                	sd	ra,24(sp)
    800023b2:	e822                	sd	s0,16(sp)
    800023b4:	e426                	sd	s1,8(sp)
    800023b6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800023b8:	00000097          	auipc	ra,0x0
    800023bc:	9de080e7          	jalr	-1570(ra) # 80001d96 <myproc>
    800023c0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	822080e7          	jalr	-2014(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800023ca:	478d                	li	a5,3
    800023cc:	cc9c                	sw	a5,24(s1)
  struct cpu *c = &cpus[p->cpu];
    800023ce:	58dc                	lw	a5,52(s1)
    800023d0:	0007851b          	sext.w	a0,a5
  add_proc(&c->runnable_head, p, &c->head_lock);
    800023d4:	00251793          	slli	a5,a0,0x2
    800023d8:	97aa                	add	a5,a5,a0
    800023da:	0796                	slli	a5,a5,0x5
    800023dc:	0000f517          	auipc	a0,0xf
    800023e0:	f0c50513          	addi	a0,a0,-244 # 800112e8 <cpus>
    800023e4:	08878613          	addi	a2,a5,136
    800023e8:	08078793          	addi	a5,a5,128
    800023ec:	962a                	add	a2,a2,a0
    800023ee:	85a6                	mv	a1,s1
    800023f0:	953e                	add	a0,a0,a5
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	65e080e7          	jalr	1630(ra) # 80001a50 <add_proc>
  sched();
    800023fa:	00000097          	auipc	ra,0x0
    800023fe:	ebe080e7          	jalr	-322(ra) # 800022b8 <sched>
  release(&p->lock);
    80002402:	8526                	mv	a0,s1
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	8a6080e7          	jalr	-1882(ra) # 80000caa <release>
}
    8000240c:	60e2                	ld	ra,24(sp)
    8000240e:	6442                	ld	s0,16(sp)
    80002410:	64a2                	ld	s1,8(sp)
    80002412:	6105                	addi	sp,sp,32
    80002414:	8082                	ret

0000000080002416 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002416:	7179                	addi	sp,sp,-48
    80002418:	f406                	sd	ra,40(sp)
    8000241a:	f022                	sd	s0,32(sp)
    8000241c:	ec26                	sd	s1,24(sp)
    8000241e:	e84a                	sd	s2,16(sp)
    80002420:	e44e                	sd	s3,8(sp)
    80002422:	1800                	addi	s0,sp,48
    80002424:	89aa                	mv	s3,a0
    80002426:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002428:	00000097          	auipc	ra,0x0
    8000242c:	96e080e7          	jalr	-1682(ra) # 80001d96 <myproc>
    80002430:	84aa                	mv	s1,a0
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.
  acquire(&p->lock); // DOC: sleeplock1
    80002432:	ffffe097          	auipc	ra,0xffffe
    80002436:	7b2080e7          	jalr	1970(ra) # 80000be4 <acquire>


  add_proc(&sleeping_head, p, &sleeping_lock);
    8000243a:	0000f617          	auipc	a2,0xf
    8000243e:	e9660613          	addi	a2,a2,-362 # 800112d0 <sleeping_lock>
    80002442:	85a6                	mv	a1,s1
    80002444:	00006517          	auipc	a0,0x6
    80002448:	43450513          	addi	a0,a0,1076 # 80008878 <sleeping_head>
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	604080e7          	jalr	1540(ra) # 80001a50 <add_proc>
  release(lk);
    80002454:	854a                	mv	a0,s2
    80002456:	fffff097          	auipc	ra,0xfffff
    8000245a:	854080e7          	jalr	-1964(ra) # 80000caa <release>
  p->chan = chan;
    8000245e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002462:	4789                	li	a5,2
    80002464:	cc9c                	sw	a5,24(s1)

  // Go to sleep.

  sched();
    80002466:	00000097          	auipc	ra,0x0
    8000246a:	e52080e7          	jalr	-430(ra) # 800022b8 <sched>

  // Tidy up.
  p->chan = 0;
    8000246e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002472:	8526                	mv	a0,s1
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	836080e7          	jalr	-1994(ra) # 80000caa <release>
  acquire(lk);
    8000247c:	854a                	mv	a0,s2
    8000247e:	ffffe097          	auipc	ra,0xffffe
    80002482:	766080e7          	jalr	1894(ra) # 80000be4 <acquire>
}
    80002486:	70a2                	ld	ra,40(sp)
    80002488:	7402                	ld	s0,32(sp)
    8000248a:	64e2                	ld	s1,24(sp)
    8000248c:	6942                	ld	s2,16(sp)
    8000248e:	69a2                	ld	s3,8(sp)
    80002490:	6145                	addi	sp,sp,48
    80002492:	8082                	ret

0000000080002494 <wait>:
{
    80002494:	715d                	addi	sp,sp,-80
    80002496:	e486                	sd	ra,72(sp)
    80002498:	e0a2                	sd	s0,64(sp)
    8000249a:	fc26                	sd	s1,56(sp)
    8000249c:	f84a                	sd	s2,48(sp)
    8000249e:	f44e                	sd	s3,40(sp)
    800024a0:	f052                	sd	s4,32(sp)
    800024a2:	ec56                	sd	s5,24(sp)
    800024a4:	e85a                	sd	s6,16(sp)
    800024a6:	e45e                	sd	s7,8(sp)
    800024a8:	e062                	sd	s8,0(sp)
    800024aa:	0880                	addi	s0,sp,80
    800024ac:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024ae:	00000097          	auipc	ra,0x0
    800024b2:	8e8080e7          	jalr	-1816(ra) # 80001d96 <myproc>
    800024b6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024b8:	0000f517          	auipc	a0,0xf
    800024bc:	34850513          	addi	a0,a0,840 # 80011800 <wait_lock>
    800024c0:	ffffe097          	auipc	ra,0xffffe
    800024c4:	724080e7          	jalr	1828(ra) # 80000be4 <acquire>
    havekids = 0;
    800024c8:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    800024ca:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    800024cc:	00015997          	auipc	s3,0x15
    800024d0:	54c98993          	addi	s3,s3,1356 # 80017a18 <tickslock>
        havekids = 1;
    800024d4:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024d6:	0000fc17          	auipc	s8,0xf
    800024da:	32ac0c13          	addi	s8,s8,810 # 80011800 <wait_lock>
    havekids = 0;
    800024de:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    800024e0:	0000f497          	auipc	s1,0xf
    800024e4:	33848493          	addi	s1,s1,824 # 80011818 <proc>
    800024e8:	a0bd                	j	80002556 <wait+0xc2>
          pid = np->pid;
    800024ea:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800024ee:	000b0e63          	beqz	s6,8000250a <wait+0x76>
    800024f2:	4691                	li	a3,4
    800024f4:	02c48613          	addi	a2,s1,44
    800024f8:	85da                	mv	a1,s6
    800024fa:	07093503          	ld	a0,112(s2)
    800024fe:	fffff097          	auipc	ra,0xfffff
    80002502:	198080e7          	jalr	408(ra) # 80001696 <copyout>
    80002506:	02054563          	bltz	a0,80002530 <wait+0x9c>
          freeproc(np);
    8000250a:	8526                	mv	a0,s1
    8000250c:	00000097          	auipc	ra,0x0
    80002510:	a38080e7          	jalr	-1480(ra) # 80001f44 <freeproc>
          release(&np->lock);
    80002514:	8526                	mv	a0,s1
    80002516:	ffffe097          	auipc	ra,0xffffe
    8000251a:	794080e7          	jalr	1940(ra) # 80000caa <release>
          release(&wait_lock);
    8000251e:	0000f517          	auipc	a0,0xf
    80002522:	2e250513          	addi	a0,a0,738 # 80011800 <wait_lock>
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	784080e7          	jalr	1924(ra) # 80000caa <release>
          return pid;
    8000252e:	a09d                	j	80002594 <wait+0x100>
            release(&np->lock);
    80002530:	8526                	mv	a0,s1
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	778080e7          	jalr	1912(ra) # 80000caa <release>
            release(&wait_lock);
    8000253a:	0000f517          	auipc	a0,0xf
    8000253e:	2c650513          	addi	a0,a0,710 # 80011800 <wait_lock>
    80002542:	ffffe097          	auipc	ra,0xffffe
    80002546:	768080e7          	jalr	1896(ra) # 80000caa <release>
            return -1;
    8000254a:	59fd                	li	s3,-1
    8000254c:	a0a1                	j	80002594 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    8000254e:	18848493          	addi	s1,s1,392
    80002552:	03348463          	beq	s1,s3,8000257a <wait+0xe6>
      if (np->parent == p)
    80002556:	6cbc                	ld	a5,88(s1)
    80002558:	ff279be3          	bne	a5,s2,8000254e <wait+0xba>
        acquire(&np->lock);
    8000255c:	8526                	mv	a0,s1
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	686080e7          	jalr	1670(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    80002566:	4c9c                	lw	a5,24(s1)
    80002568:	f94781e3          	beq	a5,s4,800024ea <wait+0x56>
        release(&np->lock);
    8000256c:	8526                	mv	a0,s1
    8000256e:	ffffe097          	auipc	ra,0xffffe
    80002572:	73c080e7          	jalr	1852(ra) # 80000caa <release>
        havekids = 1;
    80002576:	8756                	mv	a4,s5
    80002578:	bfd9                	j	8000254e <wait+0xba>
    if (!havekids || p->killed)
    8000257a:	c701                	beqz	a4,80002582 <wait+0xee>
    8000257c:	02892783          	lw	a5,40(s2)
    80002580:	c79d                	beqz	a5,800025ae <wait+0x11a>
      release(&wait_lock);
    80002582:	0000f517          	auipc	a0,0xf
    80002586:	27e50513          	addi	a0,a0,638 # 80011800 <wait_lock>
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	720080e7          	jalr	1824(ra) # 80000caa <release>
      return -1;
    80002592:	59fd                	li	s3,-1
}
    80002594:	854e                	mv	a0,s3
    80002596:	60a6                	ld	ra,72(sp)
    80002598:	6406                	ld	s0,64(sp)
    8000259a:	74e2                	ld	s1,56(sp)
    8000259c:	7942                	ld	s2,48(sp)
    8000259e:	79a2                	ld	s3,40(sp)
    800025a0:	7a02                	ld	s4,32(sp)
    800025a2:	6ae2                	ld	s5,24(sp)
    800025a4:	6b42                	ld	s6,16(sp)
    800025a6:	6ba2                	ld	s7,8(sp)
    800025a8:	6c02                	ld	s8,0(sp)
    800025aa:	6161                	addi	sp,sp,80
    800025ac:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800025ae:	85e2                	mv	a1,s8
    800025b0:	854a                	mv	a0,s2
    800025b2:	00000097          	auipc	ra,0x0
    800025b6:	e64080e7          	jalr	-412(ra) # 80002416 <sleep>
    havekids = 0;
    800025ba:	b715                	j	800024de <wait+0x4a>

00000000800025bc <wakeup>:

void wakeup(void *chan) // Tali's
{
    800025bc:	715d                	addi	sp,sp,-80
    800025be:	e486                	sd	ra,72(sp)
    800025c0:	e0a2                	sd	s0,64(sp)
    800025c2:	fc26                	sd	s1,56(sp)
    800025c4:	f84a                	sd	s2,48(sp)
    800025c6:	f44e                	sd	s3,40(sp)
    800025c8:	f052                	sd	s4,32(sp)
    800025ca:	ec56                	sd	s5,24(sp)
    800025cc:	e85a                	sd	s6,16(sp)
    800025ce:	e45e                	sd	s7,8(sp)
    800025d0:	e062                	sd	s8,0(sp)
    800025d2:	0880                	addi	s0,sp,80
    800025d4:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800025d6:	0000f497          	auipc	s1,0xf
    800025da:	24248493          	addi	s1,s1,578 # 80011818 <proc>
  { // TODO: update to run on sleeping only
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800025de:	4989                	li	s3,2
      {
        // printf("%s \n","sleeping");
        remove_proc(&sleeping_head, p, &sleeping_lock);
    800025e0:	0000fc17          	auipc	s8,0xf
    800025e4:	cf0c0c13          	addi	s8,s8,-784 # 800112d0 <sleeping_lock>
    800025e8:	00006b97          	auipc	s7,0x6
    800025ec:	290b8b93          	addi	s7,s7,656 # 80008878 <sleeping_head>
        p->state = RUNNABLE;
    800025f0:	4b0d                	li	s6,3
        // p->cpu = update_cpu(p->cpu);
        struct cpu *c = &cpus[p->cpu];
        add_proc(&c->runnable_head, p, &c->head_lock);
    800025f2:	0000fa97          	auipc	s5,0xf
    800025f6:	cf6a8a93          	addi	s5,s5,-778 # 800112e8 <cpus>
  for (p = proc; p < &proc[NPROC]; p++)
    800025fa:	00015917          	auipc	s2,0x15
    800025fe:	41e90913          	addi	s2,s2,1054 # 80017a18 <tickslock>
    80002602:	a811                	j	80002616 <wakeup+0x5a>
      }
      release(&p->lock);
    80002604:	8526                	mv	a0,s1
    80002606:	ffffe097          	auipc	ra,0xffffe
    8000260a:	6a4080e7          	jalr	1700(ra) # 80000caa <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000260e:	18848493          	addi	s1,s1,392
    80002612:	05248f63          	beq	s1,s2,80002670 <wakeup+0xb4>
    if (p != myproc())
    80002616:	fffff097          	auipc	ra,0xfffff
    8000261a:	780080e7          	jalr	1920(ra) # 80001d96 <myproc>
    8000261e:	fea488e3          	beq	s1,a0,8000260e <wakeup+0x52>
      acquire(&p->lock);
    80002622:	8526                	mv	a0,s1
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	5c0080e7          	jalr	1472(ra) # 80000be4 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000262c:	4c9c                	lw	a5,24(s1)
    8000262e:	fd379be3          	bne	a5,s3,80002604 <wakeup+0x48>
    80002632:	709c                	ld	a5,32(s1)
    80002634:	fd4798e3          	bne	a5,s4,80002604 <wakeup+0x48>
        remove_proc(&sleeping_head, p, &sleeping_lock);
    80002638:	8662                	mv	a2,s8
    8000263a:	85a6                	mv	a1,s1
    8000263c:	855e                	mv	a0,s7
    8000263e:	fffff097          	auipc	ra,0xfffff
    80002642:	350080e7          	jalr	848(ra) # 8000198e <remove_proc>
        p->state = RUNNABLE;
    80002646:	0164ac23          	sw	s6,24(s1)
        struct cpu *c = &cpus[p->cpu];
    8000264a:	58c8                	lw	a0,52(s1)
    8000264c:	0005079b          	sext.w	a5,a0
        add_proc(&c->runnable_head, p, &c->head_lock);
    80002650:	00279513          	slli	a0,a5,0x2
    80002654:	953e                	add	a0,a0,a5
    80002656:	0516                	slli	a0,a0,0x5
    80002658:	08850613          	addi	a2,a0,136
    8000265c:	08050513          	addi	a0,a0,128
    80002660:	9656                	add	a2,a2,s5
    80002662:	85a6                	mv	a1,s1
    80002664:	9556                	add	a0,a0,s5
    80002666:	fffff097          	auipc	ra,0xfffff
    8000266a:	3ea080e7          	jalr	1002(ra) # 80001a50 <add_proc>
    8000266e:	bf59                	j	80002604 <wakeup+0x48>
    }
  }
}
    80002670:	60a6                	ld	ra,72(sp)
    80002672:	6406                	ld	s0,64(sp)
    80002674:	74e2                	ld	s1,56(sp)
    80002676:	7942                	ld	s2,48(sp)
    80002678:	79a2                	ld	s3,40(sp)
    8000267a:	7a02                	ld	s4,32(sp)
    8000267c:	6ae2                	ld	s5,24(sp)
    8000267e:	6b42                	ld	s6,16(sp)
    80002680:	6ba2                	ld	s7,8(sp)
    80002682:	6c02                	ld	s8,0(sp)
    80002684:	6161                	addi	sp,sp,80
    80002686:	8082                	ret

0000000080002688 <reparent>:
{
    80002688:	7179                	addi	sp,sp,-48
    8000268a:	f406                	sd	ra,40(sp)
    8000268c:	f022                	sd	s0,32(sp)
    8000268e:	ec26                	sd	s1,24(sp)
    80002690:	e84a                	sd	s2,16(sp)
    80002692:	e44e                	sd	s3,8(sp)
    80002694:	e052                	sd	s4,0(sp)
    80002696:	1800                	addi	s0,sp,48
    80002698:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000269a:	0000f497          	auipc	s1,0xf
    8000269e:	17e48493          	addi	s1,s1,382 # 80011818 <proc>
      pp->parent = initproc;
    800026a2:	00007a17          	auipc	s4,0x7
    800026a6:	986a0a13          	addi	s4,s4,-1658 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800026aa:	00015997          	auipc	s3,0x15
    800026ae:	36e98993          	addi	s3,s3,878 # 80017a18 <tickslock>
    800026b2:	a029                	j	800026bc <reparent+0x34>
    800026b4:	18848493          	addi	s1,s1,392
    800026b8:	01348d63          	beq	s1,s3,800026d2 <reparent+0x4a>
    if (pp->parent == p)
    800026bc:	6cbc                	ld	a5,88(s1)
    800026be:	ff279be3          	bne	a5,s2,800026b4 <reparent+0x2c>
      pp->parent = initproc;
    800026c2:	000a3503          	ld	a0,0(s4)
    800026c6:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    800026c8:	00000097          	auipc	ra,0x0
    800026cc:	ef4080e7          	jalr	-268(ra) # 800025bc <wakeup>
    800026d0:	b7d5                	j	800026b4 <reparent+0x2c>
}
    800026d2:	70a2                	ld	ra,40(sp)
    800026d4:	7402                	ld	s0,32(sp)
    800026d6:	64e2                	ld	s1,24(sp)
    800026d8:	6942                	ld	s2,16(sp)
    800026da:	69a2                	ld	s3,8(sp)
    800026dc:	6a02                	ld	s4,0(sp)
    800026de:	6145                	addi	sp,sp,48
    800026e0:	8082                	ret

00000000800026e2 <exit>:
{
    800026e2:	7179                	addi	sp,sp,-48
    800026e4:	f406                	sd	ra,40(sp)
    800026e6:	f022                	sd	s0,32(sp)
    800026e8:	ec26                	sd	s1,24(sp)
    800026ea:	e84a                	sd	s2,16(sp)
    800026ec:	e44e                	sd	s3,8(sp)
    800026ee:	e052                	sd	s4,0(sp)
    800026f0:	1800                	addi	s0,sp,48
    800026f2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800026f4:	fffff097          	auipc	ra,0xfffff
    800026f8:	6a2080e7          	jalr	1698(ra) # 80001d96 <myproc>
    800026fc:	89aa                	mv	s3,a0
  if (p == initproc)
    800026fe:	00007797          	auipc	a5,0x7
    80002702:	92a7b783          	ld	a5,-1750(a5) # 80009028 <initproc>
    80002706:	0f050493          	addi	s1,a0,240
    8000270a:	17050913          	addi	s2,a0,368
    8000270e:	02a79363          	bne	a5,a0,80002734 <exit+0x52>
    panic("init exiting");
    80002712:	00006517          	auipc	a0,0x6
    80002716:	ba650513          	addi	a0,a0,-1114 # 800082b8 <digits+0x278>
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	e24080e7          	jalr	-476(ra) # 8000053e <panic>
      fileclose(f);
    80002722:	00002097          	auipc	ra,0x2
    80002726:	406080e7          	jalr	1030(ra) # 80004b28 <fileclose>
      p->ofile[fd] = 0;
    8000272a:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000272e:	04a1                	addi	s1,s1,8
    80002730:	01248563          	beq	s1,s2,8000273a <exit+0x58>
    if (p->ofile[fd])
    80002734:	6088                	ld	a0,0(s1)
    80002736:	f575                	bnez	a0,80002722 <exit+0x40>
    80002738:	bfdd                	j	8000272e <exit+0x4c>
  begin_op();
    8000273a:	00002097          	auipc	ra,0x2
    8000273e:	f22080e7          	jalr	-222(ra) # 8000465c <begin_op>
  iput(p->cwd);
    80002742:	1709b503          	ld	a0,368(s3)
    80002746:	00001097          	auipc	ra,0x1
    8000274a:	6fe080e7          	jalr	1790(ra) # 80003e44 <iput>
  end_op();
    8000274e:	00002097          	auipc	ra,0x2
    80002752:	f8e080e7          	jalr	-114(ra) # 800046dc <end_op>
  p->cwd = 0;
    80002756:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    8000275a:	0000f497          	auipc	s1,0xf
    8000275e:	0a648493          	addi	s1,s1,166 # 80011800 <wait_lock>
    80002762:	8526                	mv	a0,s1
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	480080e7          	jalr	1152(ra) # 80000be4 <acquire>
  reparent(p);
    8000276c:	854e                	mv	a0,s3
    8000276e:	00000097          	auipc	ra,0x0
    80002772:	f1a080e7          	jalr	-230(ra) # 80002688 <reparent>
  wakeup(p->parent);
    80002776:	0589b503          	ld	a0,88(s3)
    8000277a:	00000097          	auipc	ra,0x0
    8000277e:	e42080e7          	jalr	-446(ra) # 800025bc <wakeup>
  acquire(&p->lock);
    80002782:	854e                	mv	a0,s3
    80002784:	ffffe097          	auipc	ra,0xffffe
    80002788:	460080e7          	jalr	1120(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000278c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002790:	4795                	li	a5,5
    80002792:	00f9ac23          	sw	a5,24(s3)
  add_proc(&zombie_head, p, &zombie_lock);
    80002796:	0000f617          	auipc	a2,0xf
    8000279a:	b0a60613          	addi	a2,a2,-1270 # 800112a0 <zombie_lock>
    8000279e:	85ce                	mv	a1,s3
    800027a0:	00006517          	auipc	a0,0x6
    800027a4:	0dc50513          	addi	a0,a0,220 # 8000887c <zombie_head>
    800027a8:	fffff097          	auipc	ra,0xfffff
    800027ac:	2a8080e7          	jalr	680(ra) # 80001a50 <add_proc>
  release(&wait_lock);
    800027b0:	8526                	mv	a0,s1
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	4f8080e7          	jalr	1272(ra) # 80000caa <release>
  sched();
    800027ba:	00000097          	auipc	ra,0x0
    800027be:	afe080e7          	jalr	-1282(ra) # 800022b8 <sched>
  panic("zombie exit");
    800027c2:	00006517          	auipc	a0,0x6
    800027c6:	b0650513          	addi	a0,a0,-1274 # 800082c8 <digits+0x288>
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	d74080e7          	jalr	-652(ra) # 8000053e <panic>

00000000800027d2 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800027d2:	7179                	addi	sp,sp,-48
    800027d4:	f406                	sd	ra,40(sp)
    800027d6:	f022                	sd	s0,32(sp)
    800027d8:	ec26                	sd	s1,24(sp)
    800027da:	e84a                	sd	s2,16(sp)
    800027dc:	e44e                	sd	s3,8(sp)
    800027de:	1800                	addi	s0,sp,48
    800027e0:	892a                	mv	s2,a0
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    800027e2:	0000f497          	auipc	s1,0xf
    800027e6:	03648493          	addi	s1,s1,54 # 80011818 <proc>
    800027ea:	00015997          	auipc	s3,0x15
    800027ee:	22e98993          	addi	s3,s3,558 # 80017a18 <tickslock>
  {
    acquire(&p->lock);
    800027f2:	8526                	mv	a0,s1
    800027f4:	ffffe097          	auipc	ra,0xffffe
    800027f8:	3f0080e7          	jalr	1008(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    800027fc:	589c                	lw	a5,48(s1)
    800027fe:	01278d63          	beq	a5,s2,80002818 <kill+0x46>
        add_proc(&c->runnable_head, p, &c->head_lock);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002802:	8526                	mv	a0,s1
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	4a6080e7          	jalr	1190(ra) # 80000caa <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000280c:	18848493          	addi	s1,s1,392
    80002810:	ff3491e3          	bne	s1,s3,800027f2 <kill+0x20>
  }
  return -1;
    80002814:	557d                	li	a0,-1
    80002816:	a829                	j	80002830 <kill+0x5e>
      p->killed = 1;
    80002818:	4785                	li	a5,1
    8000281a:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000281c:	4c98                	lw	a4,24(s1)
    8000281e:	4789                	li	a5,2
    80002820:	00f70f63          	beq	a4,a5,8000283e <kill+0x6c>
      release(&p->lock);
    80002824:	8526                	mv	a0,s1
    80002826:	ffffe097          	auipc	ra,0xffffe
    8000282a:	484080e7          	jalr	1156(ra) # 80000caa <release>
      return 0;
    8000282e:	4501                	li	a0,0
}
    80002830:	70a2                	ld	ra,40(sp)
    80002832:	7402                	ld	s0,32(sp)
    80002834:	64e2                	ld	s1,24(sp)
    80002836:	6942                	ld	s2,16(sp)
    80002838:	69a2                	ld	s3,8(sp)
    8000283a:	6145                	addi	sp,sp,48
    8000283c:	8082                	ret
        remove_proc(&sleeping_head, p, &sleeping_lock);
    8000283e:	0000f617          	auipc	a2,0xf
    80002842:	a9260613          	addi	a2,a2,-1390 # 800112d0 <sleeping_lock>
    80002846:	85a6                	mv	a1,s1
    80002848:	00006517          	auipc	a0,0x6
    8000284c:	03050513          	addi	a0,a0,48 # 80008878 <sleeping_head>
    80002850:	fffff097          	auipc	ra,0xfffff
    80002854:	13e080e7          	jalr	318(ra) # 8000198e <remove_proc>
        p->state = RUNNABLE;
    80002858:	478d                	li	a5,3
    8000285a:	cc9c                	sw	a5,24(s1)
        struct cpu *c = &cpus[p->cpu];
    8000285c:	58dc                	lw	a5,52(s1)
    8000285e:	0007871b          	sext.w	a4,a5
        add_proc(&c->runnable_head, p, &c->head_lock);
    80002862:	00271793          	slli	a5,a4,0x2
    80002866:	97ba                	add	a5,a5,a4
    80002868:	0796                	slli	a5,a5,0x5
    8000286a:	0000f517          	auipc	a0,0xf
    8000286e:	a7e50513          	addi	a0,a0,-1410 # 800112e8 <cpus>
    80002872:	08878613          	addi	a2,a5,136
    80002876:	08078793          	addi	a5,a5,128
    8000287a:	962a                	add	a2,a2,a0
    8000287c:	85a6                	mv	a1,s1
    8000287e:	953e                	add	a0,a0,a5
    80002880:	fffff097          	auipc	ra,0xfffff
    80002884:	1d0080e7          	jalr	464(ra) # 80001a50 <add_proc>
    80002888:	bf71                	j	80002824 <kill+0x52>

000000008000288a <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000288a:	7179                	addi	sp,sp,-48
    8000288c:	f406                	sd	ra,40(sp)
    8000288e:	f022                	sd	s0,32(sp)
    80002890:	ec26                	sd	s1,24(sp)
    80002892:	e84a                	sd	s2,16(sp)
    80002894:	e44e                	sd	s3,8(sp)
    80002896:	e052                	sd	s4,0(sp)
    80002898:	1800                	addi	s0,sp,48
    8000289a:	84aa                	mv	s1,a0
    8000289c:	892e                	mv	s2,a1
    8000289e:	89b2                	mv	s3,a2
    800028a0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800028a2:	fffff097          	auipc	ra,0xfffff
    800028a6:	4f4080e7          	jalr	1268(ra) # 80001d96 <myproc>
  if (user_dst)
    800028aa:	c08d                	beqz	s1,800028cc <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800028ac:	86d2                	mv	a3,s4
    800028ae:	864e                	mv	a2,s3
    800028b0:	85ca                	mv	a1,s2
    800028b2:	7928                	ld	a0,112(a0)
    800028b4:	fffff097          	auipc	ra,0xfffff
    800028b8:	de2080e7          	jalr	-542(ra) # 80001696 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800028bc:	70a2                	ld	ra,40(sp)
    800028be:	7402                	ld	s0,32(sp)
    800028c0:	64e2                	ld	s1,24(sp)
    800028c2:	6942                	ld	s2,16(sp)
    800028c4:	69a2                	ld	s3,8(sp)
    800028c6:	6a02                	ld	s4,0(sp)
    800028c8:	6145                	addi	sp,sp,48
    800028ca:	8082                	ret
    memmove((char *)dst, src, len);
    800028cc:	000a061b          	sext.w	a2,s4
    800028d0:	85ce                	mv	a1,s3
    800028d2:	854a                	mv	a0,s2
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	490080e7          	jalr	1168(ra) # 80000d64 <memmove>
    return 0;
    800028dc:	8526                	mv	a0,s1
    800028de:	bff9                	j	800028bc <either_copyout+0x32>

00000000800028e0 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800028e0:	7179                	addi	sp,sp,-48
    800028e2:	f406                	sd	ra,40(sp)
    800028e4:	f022                	sd	s0,32(sp)
    800028e6:	ec26                	sd	s1,24(sp)
    800028e8:	e84a                	sd	s2,16(sp)
    800028ea:	e44e                	sd	s3,8(sp)
    800028ec:	e052                	sd	s4,0(sp)
    800028ee:	1800                	addi	s0,sp,48
    800028f0:	892a                	mv	s2,a0
    800028f2:	84ae                	mv	s1,a1
    800028f4:	89b2                	mv	s3,a2
    800028f6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800028f8:	fffff097          	auipc	ra,0xfffff
    800028fc:	49e080e7          	jalr	1182(ra) # 80001d96 <myproc>
  if (user_src)
    80002900:	c08d                	beqz	s1,80002922 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002902:	86d2                	mv	a3,s4
    80002904:	864e                	mv	a2,s3
    80002906:	85ca                	mv	a1,s2
    80002908:	7928                	ld	a0,112(a0)
    8000290a:	fffff097          	auipc	ra,0xfffff
    8000290e:	e18080e7          	jalr	-488(ra) # 80001722 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002912:	70a2                	ld	ra,40(sp)
    80002914:	7402                	ld	s0,32(sp)
    80002916:	64e2                	ld	s1,24(sp)
    80002918:	6942                	ld	s2,16(sp)
    8000291a:	69a2                	ld	s3,8(sp)
    8000291c:	6a02                	ld	s4,0(sp)
    8000291e:	6145                	addi	sp,sp,48
    80002920:	8082                	ret
    memmove(dst, (char *)src, len);
    80002922:	000a061b          	sext.w	a2,s4
    80002926:	85ce                	mv	a1,s3
    80002928:	854a                	mv	a0,s2
    8000292a:	ffffe097          	auipc	ra,0xffffe
    8000292e:	43a080e7          	jalr	1082(ra) # 80000d64 <memmove>
    return 0;
    80002932:	8526                	mv	a0,s1
    80002934:	bff9                	j	80002912 <either_copyin+0x32>

0000000080002936 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002936:	715d                	addi	sp,sp,-80
    80002938:	e486                	sd	ra,72(sp)
    8000293a:	e0a2                	sd	s0,64(sp)
    8000293c:	fc26                	sd	s1,56(sp)
    8000293e:	f84a                	sd	s2,48(sp)
    80002940:	f44e                	sd	s3,40(sp)
    80002942:	f052                	sd	s4,32(sp)
    80002944:	ec56                	sd	s5,24(sp)
    80002946:	e85a                	sd	s6,16(sp)
    80002948:	e45e                	sd	s7,8(sp)
    8000294a:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000294c:	00005517          	auipc	a0,0x5
    80002950:	78450513          	addi	a0,a0,1924 # 800080d0 <digits+0x90>
    80002954:	ffffe097          	auipc	ra,0xffffe
    80002958:	c34080e7          	jalr	-972(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000295c:	0000f497          	auipc	s1,0xf
    80002960:	03448493          	addi	s1,s1,52 # 80011990 <proc+0x178>
    80002964:	00015917          	auipc	s2,0x15
    80002968:	22c90913          	addi	s2,s2,556 # 80017b90 <bcache+0x160>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000296c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000296e:	00006997          	auipc	s3,0x6
    80002972:	96a98993          	addi	s3,s3,-1686 # 800082d8 <digits+0x298>
    printf("%d %s %s", p->pid, state, p->name);
    80002976:	00006a97          	auipc	s5,0x6
    8000297a:	96aa8a93          	addi	s5,s5,-1686 # 800082e0 <digits+0x2a0>
    printf("\n");
    8000297e:	00005a17          	auipc	s4,0x5
    80002982:	752a0a13          	addi	s4,s4,1874 # 800080d0 <digits+0x90>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002986:	00006b97          	auipc	s7,0x6
    8000298a:	982b8b93          	addi	s7,s7,-1662 # 80008308 <states.1765>
    8000298e:	a00d                	j	800029b0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002990:	eb86a583          	lw	a1,-328(a3)
    80002994:	8556                	mv	a0,s5
    80002996:	ffffe097          	auipc	ra,0xffffe
    8000299a:	bf2080e7          	jalr	-1038(ra) # 80000588 <printf>
    printf("\n");
    8000299e:	8552                	mv	a0,s4
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	be8080e7          	jalr	-1048(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800029a8:	18848493          	addi	s1,s1,392
    800029ac:	03248163          	beq	s1,s2,800029ce <procdump+0x98>
    if (p->state == UNUSED)
    800029b0:	86a6                	mv	a3,s1
    800029b2:	ea04a783          	lw	a5,-352(s1)
    800029b6:	dbed                	beqz	a5,800029a8 <procdump+0x72>
      state = "???";
    800029b8:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029ba:	fcfb6be3          	bltu	s6,a5,80002990 <procdump+0x5a>
    800029be:	1782                	slli	a5,a5,0x20
    800029c0:	9381                	srli	a5,a5,0x20
    800029c2:	078e                	slli	a5,a5,0x3
    800029c4:	97de                	add	a5,a5,s7
    800029c6:	6390                	ld	a2,0(a5)
    800029c8:	f661                	bnez	a2,80002990 <procdump+0x5a>
      state = "???";
    800029ca:	864e                	mv	a2,s3
    800029cc:	b7d1                	j	80002990 <procdump+0x5a>
  }
}
    800029ce:	60a6                	ld	ra,72(sp)
    800029d0:	6406                	ld	s0,64(sp)
    800029d2:	74e2                	ld	s1,56(sp)
    800029d4:	7942                	ld	s2,48(sp)
    800029d6:	79a2                	ld	s3,40(sp)
    800029d8:	7a02                	ld	s4,32(sp)
    800029da:	6ae2                	ld	s5,24(sp)
    800029dc:	6b42                	ld	s6,16(sp)
    800029de:	6ba2                	ld	s7,8(sp)
    800029e0:	6161                	addi	sp,sp,80
    800029e2:	8082                	ret

00000000800029e4 <fork>:
{
    800029e4:	7179                	addi	sp,sp,-48
    800029e6:	f406                	sd	ra,40(sp)
    800029e8:	f022                	sd	s0,32(sp)
    800029ea:	ec26                	sd	s1,24(sp)
    800029ec:	e84a                	sd	s2,16(sp)
    800029ee:	e44e                	sd	s3,8(sp)
    800029f0:	e052                	sd	s4,0(sp)
    800029f2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800029f4:	fffff097          	auipc	ra,0xfffff
    800029f8:	3a2080e7          	jalr	930(ra) # 80001d96 <myproc>
    800029fc:	89aa                	mv	s3,a0
  if ((np = allocproc()) == 0)
    800029fe:	fffff097          	auipc	ra,0xfffff
    80002a02:	5d2080e7          	jalr	1490(ra) # 80001fd0 <allocproc>
    80002a06:	14050b63          	beqz	a0,80002b5c <fork+0x178>
    80002a0a:	892a                	mv	s2,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80002a0c:	0689b603          	ld	a2,104(s3)
    80002a10:	792c                	ld	a1,112(a0)
    80002a12:	0709b503          	ld	a0,112(s3)
    80002a16:	fffff097          	auipc	ra,0xfffff
    80002a1a:	b7c080e7          	jalr	-1156(ra) # 80001592 <uvmcopy>
    80002a1e:	04054663          	bltz	a0,80002a6a <fork+0x86>
  np->sz = p->sz;
    80002a22:	0689b783          	ld	a5,104(s3)
    80002a26:	06f93423          	sd	a5,104(s2)
  *(np->trapframe) = *(p->trapframe);
    80002a2a:	0789b683          	ld	a3,120(s3)
    80002a2e:	87b6                	mv	a5,a3
    80002a30:	07893703          	ld	a4,120(s2)
    80002a34:	12068693          	addi	a3,a3,288
    80002a38:	0007b803          	ld	a6,0(a5)
    80002a3c:	6788                	ld	a0,8(a5)
    80002a3e:	6b8c                	ld	a1,16(a5)
    80002a40:	6f90                	ld	a2,24(a5)
    80002a42:	01073023          	sd	a6,0(a4)
    80002a46:	e708                	sd	a0,8(a4)
    80002a48:	eb0c                	sd	a1,16(a4)
    80002a4a:	ef10                	sd	a2,24(a4)
    80002a4c:	02078793          	addi	a5,a5,32
    80002a50:	02070713          	addi	a4,a4,32
    80002a54:	fed792e3          	bne	a5,a3,80002a38 <fork+0x54>
  np->trapframe->a0 = 0;
    80002a58:	07893783          	ld	a5,120(s2)
    80002a5c:	0607b823          	sd	zero,112(a5)
    80002a60:	0f000493          	li	s1,240
  for (i = 0; i < NOFILE; i++)
    80002a64:	17000a13          	li	s4,368
    80002a68:	a03d                	j	80002a96 <fork+0xb2>
    freeproc(np);
    80002a6a:	854a                	mv	a0,s2
    80002a6c:	fffff097          	auipc	ra,0xfffff
    80002a70:	4d8080e7          	jalr	1240(ra) # 80001f44 <freeproc>
    release(&np->lock);
    80002a74:	854a                	mv	a0,s2
    80002a76:	ffffe097          	auipc	ra,0xffffe
    80002a7a:	234080e7          	jalr	564(ra) # 80000caa <release>
    return -1;
    80002a7e:	54fd                	li	s1,-1
    80002a80:	a0e9                	j	80002b4a <fork+0x166>
      np->ofile[i] = filedup(p->ofile[i]);
    80002a82:	00002097          	auipc	ra,0x2
    80002a86:	054080e7          	jalr	84(ra) # 80004ad6 <filedup>
    80002a8a:	009907b3          	add	a5,s2,s1
    80002a8e:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80002a90:	04a1                	addi	s1,s1,8
    80002a92:	01448763          	beq	s1,s4,80002aa0 <fork+0xbc>
    if (p->ofile[i])
    80002a96:	009987b3          	add	a5,s3,s1
    80002a9a:	6388                	ld	a0,0(a5)
    80002a9c:	f17d                	bnez	a0,80002a82 <fork+0x9e>
    80002a9e:	bfcd                	j	80002a90 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002aa0:	1709b503          	ld	a0,368(s3)
    80002aa4:	00001097          	auipc	ra,0x1
    80002aa8:	1a8080e7          	jalr	424(ra) # 80003c4c <idup>
    80002aac:	16a93823          	sd	a0,368(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002ab0:	4641                	li	a2,16
    80002ab2:	17898593          	addi	a1,s3,376
    80002ab6:	17890513          	addi	a0,s2,376
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	39c080e7          	jalr	924(ra) # 80000e56 <safestrcpy>
  pid = np->pid;
    80002ac2:	03092483          	lw	s1,48(s2)
  release(&np->lock);
    80002ac6:	854a                	mv	a0,s2
    80002ac8:	ffffe097          	auipc	ra,0xffffe
    80002acc:	1e2080e7          	jalr	482(ra) # 80000caa <release>
  acquire(&wait_lock);
    80002ad0:	0000fa17          	auipc	s4,0xf
    80002ad4:	d30a0a13          	addi	s4,s4,-720 # 80011800 <wait_lock>
    80002ad8:	8552                	mv	a0,s4
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	10a080e7          	jalr	266(ra) # 80000be4 <acquire>
  np->parent = p;
    80002ae2:	05393c23          	sd	s3,88(s2)
  np->cpu = p->cpu; // need to modify later (q.4)
    80002ae6:	0349a783          	lw	a5,52(s3)
    80002aea:	2781                	sext.w	a5,a5
    80002aec:	02f92a23          	sw	a5,52(s2)
  release(&wait_lock);
    80002af0:	8552                	mv	a0,s4
    80002af2:	ffffe097          	auipc	ra,0xffffe
    80002af6:	1b8080e7          	jalr	440(ra) # 80000caa <release>
  acquire(&np->lock);
    80002afa:	854a                	mv	a0,s2
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	0e8080e7          	jalr	232(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002b04:	478d                	li	a5,3
    80002b06:	00f92c23          	sw	a5,24(s2)
  struct cpu *c = &cpus[np->cpu]; // is p and np must be in the same cpu?
    80002b0a:	03492783          	lw	a5,52(s2)
    80002b0e:	0007871b          	sext.w	a4,a5
  add_proc(&c->runnable_head, np, &c->head_lock);
    80002b12:	00271793          	slli	a5,a4,0x2
    80002b16:	97ba                	add	a5,a5,a4
    80002b18:	0796                	slli	a5,a5,0x5
    80002b1a:	0000e517          	auipc	a0,0xe
    80002b1e:	7ce50513          	addi	a0,a0,1998 # 800112e8 <cpus>
    80002b22:	08878613          	addi	a2,a5,136
    80002b26:	08078793          	addi	a5,a5,128
    80002b2a:	962a                	add	a2,a2,a0
    80002b2c:	85ca                	mv	a1,s2
    80002b2e:	953e                	add	a0,a0,a5
    80002b30:	fffff097          	auipc	ra,0xfffff
    80002b34:	f20080e7          	jalr	-224(ra) # 80001a50 <add_proc>
  release(&np->lock);
    80002b38:	854a                	mv	a0,s2
    80002b3a:	ffffe097          	auipc	ra,0xffffe
    80002b3e:	170080e7          	jalr	368(ra) # 80000caa <release>
  procdump();
    80002b42:	00000097          	auipc	ra,0x0
    80002b46:	df4080e7          	jalr	-524(ra) # 80002936 <procdump>
}
    80002b4a:	8526                	mv	a0,s1
    80002b4c:	70a2                	ld	ra,40(sp)
    80002b4e:	7402                	ld	s0,32(sp)
    80002b50:	64e2                	ld	s1,24(sp)
    80002b52:	6942                	ld	s2,16(sp)
    80002b54:	69a2                	ld	s3,8(sp)
    80002b56:	6a02                	ld	s4,0(sp)
    80002b58:	6145                	addi	sp,sp,48
    80002b5a:	8082                	ret
    return -1;
    80002b5c:	54fd                	li	s1,-1
    80002b5e:	b7f5                	j	80002b4a <fork+0x166>

0000000080002b60 <set_cpu>:

int set_cpu(int cpu_num)
{
    80002b60:	1101                	addi	sp,sp,-32
    80002b62:	ec06                	sd	ra,24(sp)
    80002b64:	e822                	sd	s0,16(sp)
    80002b66:	e426                	sd	s1,8(sp)
    80002b68:	1000                	addi	s0,sp,32
    80002b6a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b6c:	fffff097          	auipc	ra,0xfffff
    80002b70:	22a080e7          	jalr	554(ra) # 80001d96 <myproc>
  if (cas(&p->cpu, p->cpu, cpu_num) != 0)
    80002b74:	594c                	lw	a1,52(a0)
    80002b76:	8626                	mv	a2,s1
    80002b78:	2581                	sext.w	a1,a1
    80002b7a:	03450513          	addi	a0,a0,52
    80002b7e:	00004097          	auipc	ra,0x4
    80002b82:	c98080e7          	jalr	-872(ra) # 80006816 <cas>
    80002b86:	e919                	bnez	a0,80002b9c <set_cpu+0x3c>
    return -1;
  yield();
    80002b88:	00000097          	auipc	ra,0x0
    80002b8c:	826080e7          	jalr	-2010(ra) # 800023ae <yield>
  return cpu_num;
    80002b90:	8526                	mv	a0,s1
}
    80002b92:	60e2                	ld	ra,24(sp)
    80002b94:	6442                	ld	s0,16(sp)
    80002b96:	64a2                	ld	s1,8(sp)
    80002b98:	6105                	addi	sp,sp,32
    80002b9a:	8082                	ret
    return -1;
    80002b9c:	557d                	li	a0,-1
    80002b9e:	bfd5                	j	80002b92 <set_cpu+0x32>

0000000080002ba0 <get_cpu>:

int get_cpu()
{
    80002ba0:	1101                	addi	sp,sp,-32
    80002ba2:	ec06                	sd	ra,24(sp)
    80002ba4:	e822                	sd	s0,16(sp)
    80002ba6:	e426                	sd	s1,8(sp)
    80002ba8:	e04a                	sd	s2,0(sp)
    80002baa:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002bac:	fffff097          	auipc	ra,0xfffff
    80002bb0:	1ea080e7          	jalr	490(ra) # 80001d96 <myproc>
    80002bb4:	84aa                	mv	s1,a0
  int cpu_num = -1;
  acquire(&p->lock);
    80002bb6:	ffffe097          	auipc	ra,0xffffe
    80002bba:	02e080e7          	jalr	46(ra) # 80000be4 <acquire>
  cpu_num = p->cpu;
    80002bbe:	0344a903          	lw	s2,52(s1)
    80002bc2:	2901                	sext.w	s2,s2
  release(&p->lock);
    80002bc4:	8526                	mv	a0,s1
    80002bc6:	ffffe097          	auipc	ra,0xffffe
    80002bca:	0e4080e7          	jalr	228(ra) # 80000caa <release>
  return cpu_num;
}
    80002bce:	854a                	mv	a0,s2
    80002bd0:	60e2                	ld	ra,24(sp)
    80002bd2:	6442                	ld	s0,16(sp)
    80002bd4:	64a2                	ld	s1,8(sp)
    80002bd6:	6902                	ld	s2,0(sp)
    80002bd8:	6105                	addi	sp,sp,32
    80002bda:	8082                	ret

0000000080002bdc <swtch>:
    80002bdc:	00153023          	sd	ra,0(a0)
    80002be0:	00253423          	sd	sp,8(a0)
    80002be4:	e900                	sd	s0,16(a0)
    80002be6:	ed04                	sd	s1,24(a0)
    80002be8:	03253023          	sd	s2,32(a0)
    80002bec:	03353423          	sd	s3,40(a0)
    80002bf0:	03453823          	sd	s4,48(a0)
    80002bf4:	03553c23          	sd	s5,56(a0)
    80002bf8:	05653023          	sd	s6,64(a0)
    80002bfc:	05753423          	sd	s7,72(a0)
    80002c00:	05853823          	sd	s8,80(a0)
    80002c04:	05953c23          	sd	s9,88(a0)
    80002c08:	07a53023          	sd	s10,96(a0)
    80002c0c:	07b53423          	sd	s11,104(a0)
    80002c10:	0005b083          	ld	ra,0(a1)
    80002c14:	0085b103          	ld	sp,8(a1)
    80002c18:	6980                	ld	s0,16(a1)
    80002c1a:	6d84                	ld	s1,24(a1)
    80002c1c:	0205b903          	ld	s2,32(a1)
    80002c20:	0285b983          	ld	s3,40(a1)
    80002c24:	0305ba03          	ld	s4,48(a1)
    80002c28:	0385ba83          	ld	s5,56(a1)
    80002c2c:	0405bb03          	ld	s6,64(a1)
    80002c30:	0485bb83          	ld	s7,72(a1)
    80002c34:	0505bc03          	ld	s8,80(a1)
    80002c38:	0585bc83          	ld	s9,88(a1)
    80002c3c:	0605bd03          	ld	s10,96(a1)
    80002c40:	0685bd83          	ld	s11,104(a1)
    80002c44:	8082                	ret

0000000080002c46 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c46:	1141                	addi	sp,sp,-16
    80002c48:	e406                	sd	ra,8(sp)
    80002c4a:	e022                	sd	s0,0(sp)
    80002c4c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c4e:	00005597          	auipc	a1,0x5
    80002c52:	6ea58593          	addi	a1,a1,1770 # 80008338 <states.1765+0x30>
    80002c56:	00015517          	auipc	a0,0x15
    80002c5a:	dc250513          	addi	a0,a0,-574 # 80017a18 <tickslock>
    80002c5e:	ffffe097          	auipc	ra,0xffffe
    80002c62:	ef6080e7          	jalr	-266(ra) # 80000b54 <initlock>
}
    80002c66:	60a2                	ld	ra,8(sp)
    80002c68:	6402                	ld	s0,0(sp)
    80002c6a:	0141                	addi	sp,sp,16
    80002c6c:	8082                	ret

0000000080002c6e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c6e:	1141                	addi	sp,sp,-16
    80002c70:	e422                	sd	s0,8(sp)
    80002c72:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c74:	00003797          	auipc	a5,0x3
    80002c78:	4cc78793          	addi	a5,a5,1228 # 80006140 <kernelvec>
    80002c7c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c80:	6422                	ld	s0,8(sp)
    80002c82:	0141                	addi	sp,sp,16
    80002c84:	8082                	ret

0000000080002c86 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c86:	1141                	addi	sp,sp,-16
    80002c88:	e406                	sd	ra,8(sp)
    80002c8a:	e022                	sd	s0,0(sp)
    80002c8c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c8e:	fffff097          	auipc	ra,0xfffff
    80002c92:	108080e7          	jalr	264(ra) # 80001d96 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c96:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c9a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c9c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002ca0:	00004617          	auipc	a2,0x4
    80002ca4:	36060613          	addi	a2,a2,864 # 80007000 <_trampoline>
    80002ca8:	00004697          	auipc	a3,0x4
    80002cac:	35868693          	addi	a3,a3,856 # 80007000 <_trampoline>
    80002cb0:	8e91                	sub	a3,a3,a2
    80002cb2:	040007b7          	lui	a5,0x4000
    80002cb6:	17fd                	addi	a5,a5,-1
    80002cb8:	07b2                	slli	a5,a5,0xc
    80002cba:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cbc:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002cc0:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002cc2:	180026f3          	csrr	a3,satp
    80002cc6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002cc8:	7d38                	ld	a4,120(a0)
    80002cca:	7134                	ld	a3,96(a0)
    80002ccc:	6585                	lui	a1,0x1
    80002cce:	96ae                	add	a3,a3,a1
    80002cd0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002cd2:	7d38                	ld	a4,120(a0)
    80002cd4:	00000697          	auipc	a3,0x0
    80002cd8:	13868693          	addi	a3,a3,312 # 80002e0c <usertrap>
    80002cdc:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002cde:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ce0:	8692                	mv	a3,tp
    80002ce2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ce4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ce8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002cec:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cf0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002cf4:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cf6:	6f18                	ld	a4,24(a4)
    80002cf8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002cfc:	792c                	ld	a1,112(a0)
    80002cfe:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002d00:	00004717          	auipc	a4,0x4
    80002d04:	39070713          	addi	a4,a4,912 # 80007090 <userret>
    80002d08:	8f11                	sub	a4,a4,a2
    80002d0a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002d0c:	577d                	li	a4,-1
    80002d0e:	177e                	slli	a4,a4,0x3f
    80002d10:	8dd9                	or	a1,a1,a4
    80002d12:	02000537          	lui	a0,0x2000
    80002d16:	157d                	addi	a0,a0,-1
    80002d18:	0536                	slli	a0,a0,0xd
    80002d1a:	9782                	jalr	a5
}
    80002d1c:	60a2                	ld	ra,8(sp)
    80002d1e:	6402                	ld	s0,0(sp)
    80002d20:	0141                	addi	sp,sp,16
    80002d22:	8082                	ret

0000000080002d24 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d24:	1101                	addi	sp,sp,-32
    80002d26:	ec06                	sd	ra,24(sp)
    80002d28:	e822                	sd	s0,16(sp)
    80002d2a:	e426                	sd	s1,8(sp)
    80002d2c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d2e:	00015497          	auipc	s1,0x15
    80002d32:	cea48493          	addi	s1,s1,-790 # 80017a18 <tickslock>
    80002d36:	8526                	mv	a0,s1
    80002d38:	ffffe097          	auipc	ra,0xffffe
    80002d3c:	eac080e7          	jalr	-340(ra) # 80000be4 <acquire>
  ticks++;
    80002d40:	00006517          	auipc	a0,0x6
    80002d44:	2f050513          	addi	a0,a0,752 # 80009030 <ticks>
    80002d48:	411c                	lw	a5,0(a0)
    80002d4a:	2785                	addiw	a5,a5,1
    80002d4c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002d4e:	00000097          	auipc	ra,0x0
    80002d52:	86e080e7          	jalr	-1938(ra) # 800025bc <wakeup>
  release(&tickslock);
    80002d56:	8526                	mv	a0,s1
    80002d58:	ffffe097          	auipc	ra,0xffffe
    80002d5c:	f52080e7          	jalr	-174(ra) # 80000caa <release>
}
    80002d60:	60e2                	ld	ra,24(sp)
    80002d62:	6442                	ld	s0,16(sp)
    80002d64:	64a2                	ld	s1,8(sp)
    80002d66:	6105                	addi	sp,sp,32
    80002d68:	8082                	ret

0000000080002d6a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002d6a:	1101                	addi	sp,sp,-32
    80002d6c:	ec06                	sd	ra,24(sp)
    80002d6e:	e822                	sd	s0,16(sp)
    80002d70:	e426                	sd	s1,8(sp)
    80002d72:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d74:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002d78:	00074d63          	bltz	a4,80002d92 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002d7c:	57fd                	li	a5,-1
    80002d7e:	17fe                	slli	a5,a5,0x3f
    80002d80:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002d82:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002d84:	06f70363          	beq	a4,a5,80002dea <devintr+0x80>
  }
}
    80002d88:	60e2                	ld	ra,24(sp)
    80002d8a:	6442                	ld	s0,16(sp)
    80002d8c:	64a2                	ld	s1,8(sp)
    80002d8e:	6105                	addi	sp,sp,32
    80002d90:	8082                	ret
     (scause & 0xff) == 9){
    80002d92:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002d96:	46a5                	li	a3,9
    80002d98:	fed792e3          	bne	a5,a3,80002d7c <devintr+0x12>
    int irq = plic_claim();
    80002d9c:	00003097          	auipc	ra,0x3
    80002da0:	4ac080e7          	jalr	1196(ra) # 80006248 <plic_claim>
    80002da4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002da6:	47a9                	li	a5,10
    80002da8:	02f50763          	beq	a0,a5,80002dd6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002dac:	4785                	li	a5,1
    80002dae:	02f50963          	beq	a0,a5,80002de0 <devintr+0x76>
    return 1;
    80002db2:	4505                	li	a0,1
    } else if(irq){
    80002db4:	d8f1                	beqz	s1,80002d88 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002db6:	85a6                	mv	a1,s1
    80002db8:	00005517          	auipc	a0,0x5
    80002dbc:	58850513          	addi	a0,a0,1416 # 80008340 <states.1765+0x38>
    80002dc0:	ffffd097          	auipc	ra,0xffffd
    80002dc4:	7c8080e7          	jalr	1992(ra) # 80000588 <printf>
      plic_complete(irq);
    80002dc8:	8526                	mv	a0,s1
    80002dca:	00003097          	auipc	ra,0x3
    80002dce:	4a2080e7          	jalr	1186(ra) # 8000626c <plic_complete>
    return 1;
    80002dd2:	4505                	li	a0,1
    80002dd4:	bf55                	j	80002d88 <devintr+0x1e>
      uartintr();
    80002dd6:	ffffe097          	auipc	ra,0xffffe
    80002dda:	bd2080e7          	jalr	-1070(ra) # 800009a8 <uartintr>
    80002dde:	b7ed                	j	80002dc8 <devintr+0x5e>
      virtio_disk_intr();
    80002de0:	00004097          	auipc	ra,0x4
    80002de4:	96c080e7          	jalr	-1684(ra) # 8000674c <virtio_disk_intr>
    80002de8:	b7c5                	j	80002dc8 <devintr+0x5e>
    if(cpuid() == 0){
    80002dea:	fffff097          	auipc	ra,0xfffff
    80002dee:	f78080e7          	jalr	-136(ra) # 80001d62 <cpuid>
    80002df2:	c901                	beqz	a0,80002e02 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002df4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002df8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002dfa:	14479073          	csrw	sip,a5
    return 2;
    80002dfe:	4509                	li	a0,2
    80002e00:	b761                	j	80002d88 <devintr+0x1e>
      clockintr();
    80002e02:	00000097          	auipc	ra,0x0
    80002e06:	f22080e7          	jalr	-222(ra) # 80002d24 <clockintr>
    80002e0a:	b7ed                	j	80002df4 <devintr+0x8a>

0000000080002e0c <usertrap>:
{
    80002e0c:	1101                	addi	sp,sp,-32
    80002e0e:	ec06                	sd	ra,24(sp)
    80002e10:	e822                	sd	s0,16(sp)
    80002e12:	e426                	sd	s1,8(sp)
    80002e14:	e04a                	sd	s2,0(sp)
    80002e16:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e18:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e1c:	1007f793          	andi	a5,a5,256
    80002e20:	e3ad                	bnez	a5,80002e82 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e22:	00003797          	auipc	a5,0x3
    80002e26:	31e78793          	addi	a5,a5,798 # 80006140 <kernelvec>
    80002e2a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	f68080e7          	jalr	-152(ra) # 80001d96 <myproc>
    80002e36:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e38:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e3a:	14102773          	csrr	a4,sepc
    80002e3e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e40:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002e44:	47a1                	li	a5,8
    80002e46:	04f71c63          	bne	a4,a5,80002e9e <usertrap+0x92>
    if(p->killed)
    80002e4a:	551c                	lw	a5,40(a0)
    80002e4c:	e3b9                	bnez	a5,80002e92 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002e4e:	7cb8                	ld	a4,120(s1)
    80002e50:	6f1c                	ld	a5,24(a4)
    80002e52:	0791                	addi	a5,a5,4
    80002e54:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e5e:	10079073          	csrw	sstatus,a5
    syscall();
    80002e62:	00000097          	auipc	ra,0x0
    80002e66:	2e0080e7          	jalr	736(ra) # 80003142 <syscall>
  if(p->killed)
    80002e6a:	549c                	lw	a5,40(s1)
    80002e6c:	ebc1                	bnez	a5,80002efc <usertrap+0xf0>
  usertrapret();
    80002e6e:	00000097          	auipc	ra,0x0
    80002e72:	e18080e7          	jalr	-488(ra) # 80002c86 <usertrapret>
}
    80002e76:	60e2                	ld	ra,24(sp)
    80002e78:	6442                	ld	s0,16(sp)
    80002e7a:	64a2                	ld	s1,8(sp)
    80002e7c:	6902                	ld	s2,0(sp)
    80002e7e:	6105                	addi	sp,sp,32
    80002e80:	8082                	ret
    panic("usertrap: not from user mode");
    80002e82:	00005517          	auipc	a0,0x5
    80002e86:	4de50513          	addi	a0,a0,1246 # 80008360 <states.1765+0x58>
    80002e8a:	ffffd097          	auipc	ra,0xffffd
    80002e8e:	6b4080e7          	jalr	1716(ra) # 8000053e <panic>
      exit(-1);
    80002e92:	557d                	li	a0,-1
    80002e94:	00000097          	auipc	ra,0x0
    80002e98:	84e080e7          	jalr	-1970(ra) # 800026e2 <exit>
    80002e9c:	bf4d                	j	80002e4e <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002e9e:	00000097          	auipc	ra,0x0
    80002ea2:	ecc080e7          	jalr	-308(ra) # 80002d6a <devintr>
    80002ea6:	892a                	mv	s2,a0
    80002ea8:	c501                	beqz	a0,80002eb0 <usertrap+0xa4>
  if(p->killed)
    80002eaa:	549c                	lw	a5,40(s1)
    80002eac:	c3a1                	beqz	a5,80002eec <usertrap+0xe0>
    80002eae:	a815                	j	80002ee2 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eb0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002eb4:	5890                	lw	a2,48(s1)
    80002eb6:	00005517          	auipc	a0,0x5
    80002eba:	4ca50513          	addi	a0,a0,1226 # 80008380 <states.1765+0x78>
    80002ebe:	ffffd097          	auipc	ra,0xffffd
    80002ec2:	6ca080e7          	jalr	1738(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ec6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002eca:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ece:	00005517          	auipc	a0,0x5
    80002ed2:	4e250513          	addi	a0,a0,1250 # 800083b0 <states.1765+0xa8>
    80002ed6:	ffffd097          	auipc	ra,0xffffd
    80002eda:	6b2080e7          	jalr	1714(ra) # 80000588 <printf>
    p->killed = 1;
    80002ede:	4785                	li	a5,1
    80002ee0:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002ee2:	557d                	li	a0,-1
    80002ee4:	fffff097          	auipc	ra,0xfffff
    80002ee8:	7fe080e7          	jalr	2046(ra) # 800026e2 <exit>
  if(which_dev == 2)
    80002eec:	4789                	li	a5,2
    80002eee:	f8f910e3          	bne	s2,a5,80002e6e <usertrap+0x62>
    yield();
    80002ef2:	fffff097          	auipc	ra,0xfffff
    80002ef6:	4bc080e7          	jalr	1212(ra) # 800023ae <yield>
    80002efa:	bf95                	j	80002e6e <usertrap+0x62>
  int which_dev = 0;
    80002efc:	4901                	li	s2,0
    80002efe:	b7d5                	j	80002ee2 <usertrap+0xd6>

0000000080002f00 <kerneltrap>:
{
    80002f00:	7179                	addi	sp,sp,-48
    80002f02:	f406                	sd	ra,40(sp)
    80002f04:	f022                	sd	s0,32(sp)
    80002f06:	ec26                	sd	s1,24(sp)
    80002f08:	e84a                	sd	s2,16(sp)
    80002f0a:	e44e                	sd	s3,8(sp)
    80002f0c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f0e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f12:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f16:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f1a:	1004f793          	andi	a5,s1,256
    80002f1e:	cb85                	beqz	a5,80002f4e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f20:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f24:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f26:	ef85                	bnez	a5,80002f5e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f28:	00000097          	auipc	ra,0x0
    80002f2c:	e42080e7          	jalr	-446(ra) # 80002d6a <devintr>
    80002f30:	cd1d                	beqz	a0,80002f6e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f32:	4789                	li	a5,2
    80002f34:	06f50a63          	beq	a0,a5,80002fa8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f38:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f3c:	10049073          	csrw	sstatus,s1
}
    80002f40:	70a2                	ld	ra,40(sp)
    80002f42:	7402                	ld	s0,32(sp)
    80002f44:	64e2                	ld	s1,24(sp)
    80002f46:	6942                	ld	s2,16(sp)
    80002f48:	69a2                	ld	s3,8(sp)
    80002f4a:	6145                	addi	sp,sp,48
    80002f4c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f4e:	00005517          	auipc	a0,0x5
    80002f52:	48250513          	addi	a0,a0,1154 # 800083d0 <states.1765+0xc8>
    80002f56:	ffffd097          	auipc	ra,0xffffd
    80002f5a:	5e8080e7          	jalr	1512(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002f5e:	00005517          	auipc	a0,0x5
    80002f62:	49a50513          	addi	a0,a0,1178 # 800083f8 <states.1765+0xf0>
    80002f66:	ffffd097          	auipc	ra,0xffffd
    80002f6a:	5d8080e7          	jalr	1496(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002f6e:	85ce                	mv	a1,s3
    80002f70:	00005517          	auipc	a0,0x5
    80002f74:	4a850513          	addi	a0,a0,1192 # 80008418 <states.1765+0x110>
    80002f78:	ffffd097          	auipc	ra,0xffffd
    80002f7c:	610080e7          	jalr	1552(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f80:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f84:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f88:	00005517          	auipc	a0,0x5
    80002f8c:	4a050513          	addi	a0,a0,1184 # 80008428 <states.1765+0x120>
    80002f90:	ffffd097          	auipc	ra,0xffffd
    80002f94:	5f8080e7          	jalr	1528(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002f98:	00005517          	auipc	a0,0x5
    80002f9c:	4a850513          	addi	a0,a0,1192 # 80008440 <states.1765+0x138>
    80002fa0:	ffffd097          	auipc	ra,0xffffd
    80002fa4:	59e080e7          	jalr	1438(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002fa8:	fffff097          	auipc	ra,0xfffff
    80002fac:	dee080e7          	jalr	-530(ra) # 80001d96 <myproc>
    80002fb0:	d541                	beqz	a0,80002f38 <kerneltrap+0x38>
    80002fb2:	fffff097          	auipc	ra,0xfffff
    80002fb6:	de4080e7          	jalr	-540(ra) # 80001d96 <myproc>
    80002fba:	4d18                	lw	a4,24(a0)
    80002fbc:	4791                	li	a5,4
    80002fbe:	f6f71de3          	bne	a4,a5,80002f38 <kerneltrap+0x38>
    yield();
    80002fc2:	fffff097          	auipc	ra,0xfffff
    80002fc6:	3ec080e7          	jalr	1004(ra) # 800023ae <yield>
    80002fca:	b7bd                	j	80002f38 <kerneltrap+0x38>

0000000080002fcc <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002fcc:	1101                	addi	sp,sp,-32
    80002fce:	ec06                	sd	ra,24(sp)
    80002fd0:	e822                	sd	s0,16(sp)
    80002fd2:	e426                	sd	s1,8(sp)
    80002fd4:	1000                	addi	s0,sp,32
    80002fd6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002fd8:	fffff097          	auipc	ra,0xfffff
    80002fdc:	dbe080e7          	jalr	-578(ra) # 80001d96 <myproc>
  switch (n) {
    80002fe0:	4795                	li	a5,5
    80002fe2:	0497e163          	bltu	a5,s1,80003024 <argraw+0x58>
    80002fe6:	048a                	slli	s1,s1,0x2
    80002fe8:	00005717          	auipc	a4,0x5
    80002fec:	49070713          	addi	a4,a4,1168 # 80008478 <states.1765+0x170>
    80002ff0:	94ba                	add	s1,s1,a4
    80002ff2:	409c                	lw	a5,0(s1)
    80002ff4:	97ba                	add	a5,a5,a4
    80002ff6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ff8:	7d3c                	ld	a5,120(a0)
    80002ffa:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ffc:	60e2                	ld	ra,24(sp)
    80002ffe:	6442                	ld	s0,16(sp)
    80003000:	64a2                	ld	s1,8(sp)
    80003002:	6105                	addi	sp,sp,32
    80003004:	8082                	ret
    return p->trapframe->a1;
    80003006:	7d3c                	ld	a5,120(a0)
    80003008:	7fa8                	ld	a0,120(a5)
    8000300a:	bfcd                	j	80002ffc <argraw+0x30>
    return p->trapframe->a2;
    8000300c:	7d3c                	ld	a5,120(a0)
    8000300e:	63c8                	ld	a0,128(a5)
    80003010:	b7f5                	j	80002ffc <argraw+0x30>
    return p->trapframe->a3;
    80003012:	7d3c                	ld	a5,120(a0)
    80003014:	67c8                	ld	a0,136(a5)
    80003016:	b7dd                	j	80002ffc <argraw+0x30>
    return p->trapframe->a4;
    80003018:	7d3c                	ld	a5,120(a0)
    8000301a:	6bc8                	ld	a0,144(a5)
    8000301c:	b7c5                	j	80002ffc <argraw+0x30>
    return p->trapframe->a5;
    8000301e:	7d3c                	ld	a5,120(a0)
    80003020:	6fc8                	ld	a0,152(a5)
    80003022:	bfe9                	j	80002ffc <argraw+0x30>
  panic("argraw");
    80003024:	00005517          	auipc	a0,0x5
    80003028:	42c50513          	addi	a0,a0,1068 # 80008450 <states.1765+0x148>
    8000302c:	ffffd097          	auipc	ra,0xffffd
    80003030:	512080e7          	jalr	1298(ra) # 8000053e <panic>

0000000080003034 <fetchaddr>:
{
    80003034:	1101                	addi	sp,sp,-32
    80003036:	ec06                	sd	ra,24(sp)
    80003038:	e822                	sd	s0,16(sp)
    8000303a:	e426                	sd	s1,8(sp)
    8000303c:	e04a                	sd	s2,0(sp)
    8000303e:	1000                	addi	s0,sp,32
    80003040:	84aa                	mv	s1,a0
    80003042:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003044:	fffff097          	auipc	ra,0xfffff
    80003048:	d52080e7          	jalr	-686(ra) # 80001d96 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    8000304c:	753c                	ld	a5,104(a0)
    8000304e:	02f4f863          	bgeu	s1,a5,8000307e <fetchaddr+0x4a>
    80003052:	00848713          	addi	a4,s1,8
    80003056:	02e7e663          	bltu	a5,a4,80003082 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000305a:	46a1                	li	a3,8
    8000305c:	8626                	mv	a2,s1
    8000305e:	85ca                	mv	a1,s2
    80003060:	7928                	ld	a0,112(a0)
    80003062:	ffffe097          	auipc	ra,0xffffe
    80003066:	6c0080e7          	jalr	1728(ra) # 80001722 <copyin>
    8000306a:	00a03533          	snez	a0,a0
    8000306e:	40a00533          	neg	a0,a0
}
    80003072:	60e2                	ld	ra,24(sp)
    80003074:	6442                	ld	s0,16(sp)
    80003076:	64a2                	ld	s1,8(sp)
    80003078:	6902                	ld	s2,0(sp)
    8000307a:	6105                	addi	sp,sp,32
    8000307c:	8082                	ret
    return -1;
    8000307e:	557d                	li	a0,-1
    80003080:	bfcd                	j	80003072 <fetchaddr+0x3e>
    80003082:	557d                	li	a0,-1
    80003084:	b7fd                	j	80003072 <fetchaddr+0x3e>

0000000080003086 <fetchstr>:
{
    80003086:	7179                	addi	sp,sp,-48
    80003088:	f406                	sd	ra,40(sp)
    8000308a:	f022                	sd	s0,32(sp)
    8000308c:	ec26                	sd	s1,24(sp)
    8000308e:	e84a                	sd	s2,16(sp)
    80003090:	e44e                	sd	s3,8(sp)
    80003092:	1800                	addi	s0,sp,48
    80003094:	892a                	mv	s2,a0
    80003096:	84ae                	mv	s1,a1
    80003098:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000309a:	fffff097          	auipc	ra,0xfffff
    8000309e:	cfc080e7          	jalr	-772(ra) # 80001d96 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800030a2:	86ce                	mv	a3,s3
    800030a4:	864a                	mv	a2,s2
    800030a6:	85a6                	mv	a1,s1
    800030a8:	7928                	ld	a0,112(a0)
    800030aa:	ffffe097          	auipc	ra,0xffffe
    800030ae:	704080e7          	jalr	1796(ra) # 800017ae <copyinstr>
  if(err < 0)
    800030b2:	00054763          	bltz	a0,800030c0 <fetchstr+0x3a>
  return strlen(buf);
    800030b6:	8526                	mv	a0,s1
    800030b8:	ffffe097          	auipc	ra,0xffffe
    800030bc:	dd0080e7          	jalr	-560(ra) # 80000e88 <strlen>
}
    800030c0:	70a2                	ld	ra,40(sp)
    800030c2:	7402                	ld	s0,32(sp)
    800030c4:	64e2                	ld	s1,24(sp)
    800030c6:	6942                	ld	s2,16(sp)
    800030c8:	69a2                	ld	s3,8(sp)
    800030ca:	6145                	addi	sp,sp,48
    800030cc:	8082                	ret

00000000800030ce <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800030ce:	1101                	addi	sp,sp,-32
    800030d0:	ec06                	sd	ra,24(sp)
    800030d2:	e822                	sd	s0,16(sp)
    800030d4:	e426                	sd	s1,8(sp)
    800030d6:	1000                	addi	s0,sp,32
    800030d8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030da:	00000097          	auipc	ra,0x0
    800030de:	ef2080e7          	jalr	-270(ra) # 80002fcc <argraw>
    800030e2:	c088                	sw	a0,0(s1)
  return 0;
}
    800030e4:	4501                	li	a0,0
    800030e6:	60e2                	ld	ra,24(sp)
    800030e8:	6442                	ld	s0,16(sp)
    800030ea:	64a2                	ld	s1,8(sp)
    800030ec:	6105                	addi	sp,sp,32
    800030ee:	8082                	ret

00000000800030f0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800030f0:	1101                	addi	sp,sp,-32
    800030f2:	ec06                	sd	ra,24(sp)
    800030f4:	e822                	sd	s0,16(sp)
    800030f6:	e426                	sd	s1,8(sp)
    800030f8:	1000                	addi	s0,sp,32
    800030fa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030fc:	00000097          	auipc	ra,0x0
    80003100:	ed0080e7          	jalr	-304(ra) # 80002fcc <argraw>
    80003104:	e088                	sd	a0,0(s1)
  return 0;
}
    80003106:	4501                	li	a0,0
    80003108:	60e2                	ld	ra,24(sp)
    8000310a:	6442                	ld	s0,16(sp)
    8000310c:	64a2                	ld	s1,8(sp)
    8000310e:	6105                	addi	sp,sp,32
    80003110:	8082                	ret

0000000080003112 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003112:	1101                	addi	sp,sp,-32
    80003114:	ec06                	sd	ra,24(sp)
    80003116:	e822                	sd	s0,16(sp)
    80003118:	e426                	sd	s1,8(sp)
    8000311a:	e04a                	sd	s2,0(sp)
    8000311c:	1000                	addi	s0,sp,32
    8000311e:	84ae                	mv	s1,a1
    80003120:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003122:	00000097          	auipc	ra,0x0
    80003126:	eaa080e7          	jalr	-342(ra) # 80002fcc <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000312a:	864a                	mv	a2,s2
    8000312c:	85a6                	mv	a1,s1
    8000312e:	00000097          	auipc	ra,0x0
    80003132:	f58080e7          	jalr	-168(ra) # 80003086 <fetchstr>
}
    80003136:	60e2                	ld	ra,24(sp)
    80003138:	6442                	ld	s0,16(sp)
    8000313a:	64a2                	ld	s1,8(sp)
    8000313c:	6902                	ld	s2,0(sp)
    8000313e:	6105                	addi	sp,sp,32
    80003140:	8082                	ret

0000000080003142 <syscall>:
[SYS_set_cpu] sys_set_cpu,
};

void
syscall(void)
{
    80003142:	1101                	addi	sp,sp,-32
    80003144:	ec06                	sd	ra,24(sp)
    80003146:	e822                	sd	s0,16(sp)
    80003148:	e426                	sd	s1,8(sp)
    8000314a:	e04a                	sd	s2,0(sp)
    8000314c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000314e:	fffff097          	auipc	ra,0xfffff
    80003152:	c48080e7          	jalr	-952(ra) # 80001d96 <myproc>
    80003156:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003158:	07853903          	ld	s2,120(a0)
    8000315c:	0a893783          	ld	a5,168(s2)
    80003160:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003164:	37fd                	addiw	a5,a5,-1
    80003166:	4759                	li	a4,22
    80003168:	00f76f63          	bltu	a4,a5,80003186 <syscall+0x44>
    8000316c:	00369713          	slli	a4,a3,0x3
    80003170:	00005797          	auipc	a5,0x5
    80003174:	32078793          	addi	a5,a5,800 # 80008490 <syscalls>
    80003178:	97ba                	add	a5,a5,a4
    8000317a:	639c                	ld	a5,0(a5)
    8000317c:	c789                	beqz	a5,80003186 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000317e:	9782                	jalr	a5
    80003180:	06a93823          	sd	a0,112(s2)
    80003184:	a839                	j	800031a2 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003186:	17848613          	addi	a2,s1,376
    8000318a:	588c                	lw	a1,48(s1)
    8000318c:	00005517          	auipc	a0,0x5
    80003190:	2cc50513          	addi	a0,a0,716 # 80008458 <states.1765+0x150>
    80003194:	ffffd097          	auipc	ra,0xffffd
    80003198:	3f4080e7          	jalr	1012(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000319c:	7cbc                	ld	a5,120(s1)
    8000319e:	577d                	li	a4,-1
    800031a0:	fbb8                	sd	a4,112(a5)
  }
}
    800031a2:	60e2                	ld	ra,24(sp)
    800031a4:	6442                	ld	s0,16(sp)
    800031a6:	64a2                	ld	s1,8(sp)
    800031a8:	6902                	ld	s2,0(sp)
    800031aa:	6105                	addi	sp,sp,32
    800031ac:	8082                	ret

00000000800031ae <sys_set_cpu>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_set_cpu(void)
{
    800031ae:	1101                	addi	sp,sp,-32
    800031b0:	ec06                	sd	ra,24(sp)
    800031b2:	e822                	sd	s0,16(sp)
    800031b4:	1000                	addi	s0,sp,32
  int cpu_num;
  if(argint(0, &cpu_num) < 0)
    800031b6:	fec40593          	addi	a1,s0,-20
    800031ba:	4501                	li	a0,0
    800031bc:	00000097          	auipc	ra,0x0
    800031c0:	f12080e7          	jalr	-238(ra) # 800030ce <argint>
    800031c4:	87aa                	mv	a5,a0
    return -1;
    800031c6:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    800031c8:	0007c863          	bltz	a5,800031d8 <sys_set_cpu+0x2a>
  return set_cpu(cpu_num); 
    800031cc:	fec42503          	lw	a0,-20(s0)
    800031d0:	00000097          	auipc	ra,0x0
    800031d4:	990080e7          	jalr	-1648(ra) # 80002b60 <set_cpu>
}
    800031d8:	60e2                	ld	ra,24(sp)
    800031da:	6442                	ld	s0,16(sp)
    800031dc:	6105                	addi	sp,sp,32
    800031de:	8082                	ret

00000000800031e0 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    800031e0:	1141                	addi	sp,sp,-16
    800031e2:	e406                	sd	ra,8(sp)
    800031e4:	e022                	sd	s0,0(sp)
    800031e6:	0800                	addi	s0,sp,16
  return get_cpu(); 
    800031e8:	00000097          	auipc	ra,0x0
    800031ec:	9b8080e7          	jalr	-1608(ra) # 80002ba0 <get_cpu>
}
    800031f0:	60a2                	ld	ra,8(sp)
    800031f2:	6402                	ld	s0,0(sp)
    800031f4:	0141                	addi	sp,sp,16
    800031f6:	8082                	ret

00000000800031f8 <sys_exit>:

uint64
sys_exit(void)
{
    800031f8:	1101                	addi	sp,sp,-32
    800031fa:	ec06                	sd	ra,24(sp)
    800031fc:	e822                	sd	s0,16(sp)
    800031fe:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003200:	fec40593          	addi	a1,s0,-20
    80003204:	4501                	li	a0,0
    80003206:	00000097          	auipc	ra,0x0
    8000320a:	ec8080e7          	jalr	-312(ra) # 800030ce <argint>
    return -1;
    8000320e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003210:	00054963          	bltz	a0,80003222 <sys_exit+0x2a>
  exit(n);
    80003214:	fec42503          	lw	a0,-20(s0)
    80003218:	fffff097          	auipc	ra,0xfffff
    8000321c:	4ca080e7          	jalr	1226(ra) # 800026e2 <exit>
  return 0;  // not reached
    80003220:	4781                	li	a5,0
}
    80003222:	853e                	mv	a0,a5
    80003224:	60e2                	ld	ra,24(sp)
    80003226:	6442                	ld	s0,16(sp)
    80003228:	6105                	addi	sp,sp,32
    8000322a:	8082                	ret

000000008000322c <sys_getpid>:

uint64
sys_getpid(void)
{
    8000322c:	1141                	addi	sp,sp,-16
    8000322e:	e406                	sd	ra,8(sp)
    80003230:	e022                	sd	s0,0(sp)
    80003232:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003234:	fffff097          	auipc	ra,0xfffff
    80003238:	b62080e7          	jalr	-1182(ra) # 80001d96 <myproc>
}
    8000323c:	5908                	lw	a0,48(a0)
    8000323e:	60a2                	ld	ra,8(sp)
    80003240:	6402                	ld	s0,0(sp)
    80003242:	0141                	addi	sp,sp,16
    80003244:	8082                	ret

0000000080003246 <sys_fork>:

uint64
sys_fork(void)
{
    80003246:	1141                	addi	sp,sp,-16
    80003248:	e406                	sd	ra,8(sp)
    8000324a:	e022                	sd	s0,0(sp)
    8000324c:	0800                	addi	s0,sp,16
  return fork();
    8000324e:	fffff097          	auipc	ra,0xfffff
    80003252:	796080e7          	jalr	1942(ra) # 800029e4 <fork>
}
    80003256:	60a2                	ld	ra,8(sp)
    80003258:	6402                	ld	s0,0(sp)
    8000325a:	0141                	addi	sp,sp,16
    8000325c:	8082                	ret

000000008000325e <sys_wait>:

uint64
sys_wait(void)
{
    8000325e:	1101                	addi	sp,sp,-32
    80003260:	ec06                	sd	ra,24(sp)
    80003262:	e822                	sd	s0,16(sp)
    80003264:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003266:	fe840593          	addi	a1,s0,-24
    8000326a:	4501                	li	a0,0
    8000326c:	00000097          	auipc	ra,0x0
    80003270:	e84080e7          	jalr	-380(ra) # 800030f0 <argaddr>
    80003274:	87aa                	mv	a5,a0
    return -1;
    80003276:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003278:	0007c863          	bltz	a5,80003288 <sys_wait+0x2a>
  return wait(p);
    8000327c:	fe843503          	ld	a0,-24(s0)
    80003280:	fffff097          	auipc	ra,0xfffff
    80003284:	214080e7          	jalr	532(ra) # 80002494 <wait>
}
    80003288:	60e2                	ld	ra,24(sp)
    8000328a:	6442                	ld	s0,16(sp)
    8000328c:	6105                	addi	sp,sp,32
    8000328e:	8082                	ret

0000000080003290 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003290:	7179                	addi	sp,sp,-48
    80003292:	f406                	sd	ra,40(sp)
    80003294:	f022                	sd	s0,32(sp)
    80003296:	ec26                	sd	s1,24(sp)
    80003298:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000329a:	fdc40593          	addi	a1,s0,-36
    8000329e:	4501                	li	a0,0
    800032a0:	00000097          	auipc	ra,0x0
    800032a4:	e2e080e7          	jalr	-466(ra) # 800030ce <argint>
    800032a8:	87aa                	mv	a5,a0
    return -1;
    800032aa:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800032ac:	0207c063          	bltz	a5,800032cc <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800032b0:	fffff097          	auipc	ra,0xfffff
    800032b4:	ae6080e7          	jalr	-1306(ra) # 80001d96 <myproc>
    800032b8:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    800032ba:	fdc42503          	lw	a0,-36(s0)
    800032be:	fffff097          	auipc	ra,0xfffff
    800032c2:	ec2080e7          	jalr	-318(ra) # 80002180 <growproc>
    800032c6:	00054863          	bltz	a0,800032d6 <sys_sbrk+0x46>
    return -1;
  return addr;
    800032ca:	8526                	mv	a0,s1
}
    800032cc:	70a2                	ld	ra,40(sp)
    800032ce:	7402                	ld	s0,32(sp)
    800032d0:	64e2                	ld	s1,24(sp)
    800032d2:	6145                	addi	sp,sp,48
    800032d4:	8082                	ret
    return -1;
    800032d6:	557d                	li	a0,-1
    800032d8:	bfd5                	j	800032cc <sys_sbrk+0x3c>

00000000800032da <sys_sleep>:

uint64
sys_sleep(void)
{
    800032da:	7139                	addi	sp,sp,-64
    800032dc:	fc06                	sd	ra,56(sp)
    800032de:	f822                	sd	s0,48(sp)
    800032e0:	f426                	sd	s1,40(sp)
    800032e2:	f04a                	sd	s2,32(sp)
    800032e4:	ec4e                	sd	s3,24(sp)
    800032e6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800032e8:	fcc40593          	addi	a1,s0,-52
    800032ec:	4501                	li	a0,0
    800032ee:	00000097          	auipc	ra,0x0
    800032f2:	de0080e7          	jalr	-544(ra) # 800030ce <argint>
    return -1;
    800032f6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800032f8:	06054563          	bltz	a0,80003362 <sys_sleep+0x88>
  acquire(&tickslock);
    800032fc:	00014517          	auipc	a0,0x14
    80003300:	71c50513          	addi	a0,a0,1820 # 80017a18 <tickslock>
    80003304:	ffffe097          	auipc	ra,0xffffe
    80003308:	8e0080e7          	jalr	-1824(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000330c:	00006917          	auipc	s2,0x6
    80003310:	d2492903          	lw	s2,-732(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003314:	fcc42783          	lw	a5,-52(s0)
    80003318:	cf85                	beqz	a5,80003350 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000331a:	00014997          	auipc	s3,0x14
    8000331e:	6fe98993          	addi	s3,s3,1790 # 80017a18 <tickslock>
    80003322:	00006497          	auipc	s1,0x6
    80003326:	d0e48493          	addi	s1,s1,-754 # 80009030 <ticks>
    if(myproc()->killed){
    8000332a:	fffff097          	auipc	ra,0xfffff
    8000332e:	a6c080e7          	jalr	-1428(ra) # 80001d96 <myproc>
    80003332:	551c                	lw	a5,40(a0)
    80003334:	ef9d                	bnez	a5,80003372 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003336:	85ce                	mv	a1,s3
    80003338:	8526                	mv	a0,s1
    8000333a:	fffff097          	auipc	ra,0xfffff
    8000333e:	0dc080e7          	jalr	220(ra) # 80002416 <sleep>
  while(ticks - ticks0 < n){
    80003342:	409c                	lw	a5,0(s1)
    80003344:	412787bb          	subw	a5,a5,s2
    80003348:	fcc42703          	lw	a4,-52(s0)
    8000334c:	fce7efe3          	bltu	a5,a4,8000332a <sys_sleep+0x50>
  }
  release(&tickslock);
    80003350:	00014517          	auipc	a0,0x14
    80003354:	6c850513          	addi	a0,a0,1736 # 80017a18 <tickslock>
    80003358:	ffffe097          	auipc	ra,0xffffe
    8000335c:	952080e7          	jalr	-1710(ra) # 80000caa <release>
  return 0;
    80003360:	4781                	li	a5,0
}
    80003362:	853e                	mv	a0,a5
    80003364:	70e2                	ld	ra,56(sp)
    80003366:	7442                	ld	s0,48(sp)
    80003368:	74a2                	ld	s1,40(sp)
    8000336a:	7902                	ld	s2,32(sp)
    8000336c:	69e2                	ld	s3,24(sp)
    8000336e:	6121                	addi	sp,sp,64
    80003370:	8082                	ret
      release(&tickslock);
    80003372:	00014517          	auipc	a0,0x14
    80003376:	6a650513          	addi	a0,a0,1702 # 80017a18 <tickslock>
    8000337a:	ffffe097          	auipc	ra,0xffffe
    8000337e:	930080e7          	jalr	-1744(ra) # 80000caa <release>
      return -1;
    80003382:	57fd                	li	a5,-1
    80003384:	bff9                	j	80003362 <sys_sleep+0x88>

0000000080003386 <sys_kill>:

uint64
sys_kill(void)
{
    80003386:	1101                	addi	sp,sp,-32
    80003388:	ec06                	sd	ra,24(sp)
    8000338a:	e822                	sd	s0,16(sp)
    8000338c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000338e:	fec40593          	addi	a1,s0,-20
    80003392:	4501                	li	a0,0
    80003394:	00000097          	auipc	ra,0x0
    80003398:	d3a080e7          	jalr	-710(ra) # 800030ce <argint>
    8000339c:	87aa                	mv	a5,a0
    return -1;
    8000339e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800033a0:	0007c863          	bltz	a5,800033b0 <sys_kill+0x2a>
  return kill(pid);
    800033a4:	fec42503          	lw	a0,-20(s0)
    800033a8:	fffff097          	auipc	ra,0xfffff
    800033ac:	42a080e7          	jalr	1066(ra) # 800027d2 <kill>
}
    800033b0:	60e2                	ld	ra,24(sp)
    800033b2:	6442                	ld	s0,16(sp)
    800033b4:	6105                	addi	sp,sp,32
    800033b6:	8082                	ret

00000000800033b8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033b8:	1101                	addi	sp,sp,-32
    800033ba:	ec06                	sd	ra,24(sp)
    800033bc:	e822                	sd	s0,16(sp)
    800033be:	e426                	sd	s1,8(sp)
    800033c0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800033c2:	00014517          	auipc	a0,0x14
    800033c6:	65650513          	addi	a0,a0,1622 # 80017a18 <tickslock>
    800033ca:	ffffe097          	auipc	ra,0xffffe
    800033ce:	81a080e7          	jalr	-2022(ra) # 80000be4 <acquire>
  xticks = ticks;
    800033d2:	00006497          	auipc	s1,0x6
    800033d6:	c5e4a483          	lw	s1,-930(s1) # 80009030 <ticks>
  release(&tickslock);
    800033da:	00014517          	auipc	a0,0x14
    800033de:	63e50513          	addi	a0,a0,1598 # 80017a18 <tickslock>
    800033e2:	ffffe097          	auipc	ra,0xffffe
    800033e6:	8c8080e7          	jalr	-1848(ra) # 80000caa <release>
  return xticks;
}
    800033ea:	02049513          	slli	a0,s1,0x20
    800033ee:	9101                	srli	a0,a0,0x20
    800033f0:	60e2                	ld	ra,24(sp)
    800033f2:	6442                	ld	s0,16(sp)
    800033f4:	64a2                	ld	s1,8(sp)
    800033f6:	6105                	addi	sp,sp,32
    800033f8:	8082                	ret

00000000800033fa <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800033fa:	7179                	addi	sp,sp,-48
    800033fc:	f406                	sd	ra,40(sp)
    800033fe:	f022                	sd	s0,32(sp)
    80003400:	ec26                	sd	s1,24(sp)
    80003402:	e84a                	sd	s2,16(sp)
    80003404:	e44e                	sd	s3,8(sp)
    80003406:	e052                	sd	s4,0(sp)
    80003408:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000340a:	00005597          	auipc	a1,0x5
    8000340e:	14658593          	addi	a1,a1,326 # 80008550 <syscalls+0xc0>
    80003412:	00014517          	auipc	a0,0x14
    80003416:	61e50513          	addi	a0,a0,1566 # 80017a30 <bcache>
    8000341a:	ffffd097          	auipc	ra,0xffffd
    8000341e:	73a080e7          	jalr	1850(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003422:	0001c797          	auipc	a5,0x1c
    80003426:	60e78793          	addi	a5,a5,1550 # 8001fa30 <bcache+0x8000>
    8000342a:	0001d717          	auipc	a4,0x1d
    8000342e:	86e70713          	addi	a4,a4,-1938 # 8001fc98 <bcache+0x8268>
    80003432:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003436:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000343a:	00014497          	auipc	s1,0x14
    8000343e:	60e48493          	addi	s1,s1,1550 # 80017a48 <bcache+0x18>
    b->next = bcache.head.next;
    80003442:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003444:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003446:	00005a17          	auipc	s4,0x5
    8000344a:	112a0a13          	addi	s4,s4,274 # 80008558 <syscalls+0xc8>
    b->next = bcache.head.next;
    8000344e:	2b893783          	ld	a5,696(s2)
    80003452:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003454:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003458:	85d2                	mv	a1,s4
    8000345a:	01048513          	addi	a0,s1,16
    8000345e:	00001097          	auipc	ra,0x1
    80003462:	4bc080e7          	jalr	1212(ra) # 8000491a <initsleeplock>
    bcache.head.next->prev = b;
    80003466:	2b893783          	ld	a5,696(s2)
    8000346a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000346c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003470:	45848493          	addi	s1,s1,1112
    80003474:	fd349de3          	bne	s1,s3,8000344e <binit+0x54>
  }
}
    80003478:	70a2                	ld	ra,40(sp)
    8000347a:	7402                	ld	s0,32(sp)
    8000347c:	64e2                	ld	s1,24(sp)
    8000347e:	6942                	ld	s2,16(sp)
    80003480:	69a2                	ld	s3,8(sp)
    80003482:	6a02                	ld	s4,0(sp)
    80003484:	6145                	addi	sp,sp,48
    80003486:	8082                	ret

0000000080003488 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003488:	7179                	addi	sp,sp,-48
    8000348a:	f406                	sd	ra,40(sp)
    8000348c:	f022                	sd	s0,32(sp)
    8000348e:	ec26                	sd	s1,24(sp)
    80003490:	e84a                	sd	s2,16(sp)
    80003492:	e44e                	sd	s3,8(sp)
    80003494:	1800                	addi	s0,sp,48
    80003496:	89aa                	mv	s3,a0
    80003498:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000349a:	00014517          	auipc	a0,0x14
    8000349e:	59650513          	addi	a0,a0,1430 # 80017a30 <bcache>
    800034a2:	ffffd097          	auipc	ra,0xffffd
    800034a6:	742080e7          	jalr	1858(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800034aa:	0001d497          	auipc	s1,0x1d
    800034ae:	83e4b483          	ld	s1,-1986(s1) # 8001fce8 <bcache+0x82b8>
    800034b2:	0001c797          	auipc	a5,0x1c
    800034b6:	7e678793          	addi	a5,a5,2022 # 8001fc98 <bcache+0x8268>
    800034ba:	02f48f63          	beq	s1,a5,800034f8 <bread+0x70>
    800034be:	873e                	mv	a4,a5
    800034c0:	a021                	j	800034c8 <bread+0x40>
    800034c2:	68a4                	ld	s1,80(s1)
    800034c4:	02e48a63          	beq	s1,a4,800034f8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800034c8:	449c                	lw	a5,8(s1)
    800034ca:	ff379ce3          	bne	a5,s3,800034c2 <bread+0x3a>
    800034ce:	44dc                	lw	a5,12(s1)
    800034d0:	ff2799e3          	bne	a5,s2,800034c2 <bread+0x3a>
      b->refcnt++;
    800034d4:	40bc                	lw	a5,64(s1)
    800034d6:	2785                	addiw	a5,a5,1
    800034d8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034da:	00014517          	auipc	a0,0x14
    800034de:	55650513          	addi	a0,a0,1366 # 80017a30 <bcache>
    800034e2:	ffffd097          	auipc	ra,0xffffd
    800034e6:	7c8080e7          	jalr	1992(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    800034ea:	01048513          	addi	a0,s1,16
    800034ee:	00001097          	auipc	ra,0x1
    800034f2:	466080e7          	jalr	1126(ra) # 80004954 <acquiresleep>
      return b;
    800034f6:	a8b9                	j	80003554 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034f8:	0001c497          	auipc	s1,0x1c
    800034fc:	7e84b483          	ld	s1,2024(s1) # 8001fce0 <bcache+0x82b0>
    80003500:	0001c797          	auipc	a5,0x1c
    80003504:	79878793          	addi	a5,a5,1944 # 8001fc98 <bcache+0x8268>
    80003508:	00f48863          	beq	s1,a5,80003518 <bread+0x90>
    8000350c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000350e:	40bc                	lw	a5,64(s1)
    80003510:	cf81                	beqz	a5,80003528 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003512:	64a4                	ld	s1,72(s1)
    80003514:	fee49de3          	bne	s1,a4,8000350e <bread+0x86>
  panic("bget: no buffers");
    80003518:	00005517          	auipc	a0,0x5
    8000351c:	04850513          	addi	a0,a0,72 # 80008560 <syscalls+0xd0>
    80003520:	ffffd097          	auipc	ra,0xffffd
    80003524:	01e080e7          	jalr	30(ra) # 8000053e <panic>
      b->dev = dev;
    80003528:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000352c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003530:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003534:	4785                	li	a5,1
    80003536:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003538:	00014517          	auipc	a0,0x14
    8000353c:	4f850513          	addi	a0,a0,1272 # 80017a30 <bcache>
    80003540:	ffffd097          	auipc	ra,0xffffd
    80003544:	76a080e7          	jalr	1898(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    80003548:	01048513          	addi	a0,s1,16
    8000354c:	00001097          	auipc	ra,0x1
    80003550:	408080e7          	jalr	1032(ra) # 80004954 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003554:	409c                	lw	a5,0(s1)
    80003556:	cb89                	beqz	a5,80003568 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003558:	8526                	mv	a0,s1
    8000355a:	70a2                	ld	ra,40(sp)
    8000355c:	7402                	ld	s0,32(sp)
    8000355e:	64e2                	ld	s1,24(sp)
    80003560:	6942                	ld	s2,16(sp)
    80003562:	69a2                	ld	s3,8(sp)
    80003564:	6145                	addi	sp,sp,48
    80003566:	8082                	ret
    virtio_disk_rw(b, 0);
    80003568:	4581                	li	a1,0
    8000356a:	8526                	mv	a0,s1
    8000356c:	00003097          	auipc	ra,0x3
    80003570:	f0a080e7          	jalr	-246(ra) # 80006476 <virtio_disk_rw>
    b->valid = 1;
    80003574:	4785                	li	a5,1
    80003576:	c09c                	sw	a5,0(s1)
  return b;
    80003578:	b7c5                	j	80003558 <bread+0xd0>

000000008000357a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000357a:	1101                	addi	sp,sp,-32
    8000357c:	ec06                	sd	ra,24(sp)
    8000357e:	e822                	sd	s0,16(sp)
    80003580:	e426                	sd	s1,8(sp)
    80003582:	1000                	addi	s0,sp,32
    80003584:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003586:	0541                	addi	a0,a0,16
    80003588:	00001097          	auipc	ra,0x1
    8000358c:	466080e7          	jalr	1126(ra) # 800049ee <holdingsleep>
    80003590:	cd01                	beqz	a0,800035a8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003592:	4585                	li	a1,1
    80003594:	8526                	mv	a0,s1
    80003596:	00003097          	auipc	ra,0x3
    8000359a:	ee0080e7          	jalr	-288(ra) # 80006476 <virtio_disk_rw>
}
    8000359e:	60e2                	ld	ra,24(sp)
    800035a0:	6442                	ld	s0,16(sp)
    800035a2:	64a2                	ld	s1,8(sp)
    800035a4:	6105                	addi	sp,sp,32
    800035a6:	8082                	ret
    panic("bwrite");
    800035a8:	00005517          	auipc	a0,0x5
    800035ac:	fd050513          	addi	a0,a0,-48 # 80008578 <syscalls+0xe8>
    800035b0:	ffffd097          	auipc	ra,0xffffd
    800035b4:	f8e080e7          	jalr	-114(ra) # 8000053e <panic>

00000000800035b8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800035b8:	1101                	addi	sp,sp,-32
    800035ba:	ec06                	sd	ra,24(sp)
    800035bc:	e822                	sd	s0,16(sp)
    800035be:	e426                	sd	s1,8(sp)
    800035c0:	e04a                	sd	s2,0(sp)
    800035c2:	1000                	addi	s0,sp,32
    800035c4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035c6:	01050913          	addi	s2,a0,16
    800035ca:	854a                	mv	a0,s2
    800035cc:	00001097          	auipc	ra,0x1
    800035d0:	422080e7          	jalr	1058(ra) # 800049ee <holdingsleep>
    800035d4:	c92d                	beqz	a0,80003646 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800035d6:	854a                	mv	a0,s2
    800035d8:	00001097          	auipc	ra,0x1
    800035dc:	3d2080e7          	jalr	978(ra) # 800049aa <releasesleep>

  acquire(&bcache.lock);
    800035e0:	00014517          	auipc	a0,0x14
    800035e4:	45050513          	addi	a0,a0,1104 # 80017a30 <bcache>
    800035e8:	ffffd097          	auipc	ra,0xffffd
    800035ec:	5fc080e7          	jalr	1532(ra) # 80000be4 <acquire>
  b->refcnt--;
    800035f0:	40bc                	lw	a5,64(s1)
    800035f2:	37fd                	addiw	a5,a5,-1
    800035f4:	0007871b          	sext.w	a4,a5
    800035f8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800035fa:	eb05                	bnez	a4,8000362a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035fc:	68bc                	ld	a5,80(s1)
    800035fe:	64b8                	ld	a4,72(s1)
    80003600:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003602:	64bc                	ld	a5,72(s1)
    80003604:	68b8                	ld	a4,80(s1)
    80003606:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003608:	0001c797          	auipc	a5,0x1c
    8000360c:	42878793          	addi	a5,a5,1064 # 8001fa30 <bcache+0x8000>
    80003610:	2b87b703          	ld	a4,696(a5)
    80003614:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003616:	0001c717          	auipc	a4,0x1c
    8000361a:	68270713          	addi	a4,a4,1666 # 8001fc98 <bcache+0x8268>
    8000361e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003620:	2b87b703          	ld	a4,696(a5)
    80003624:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003626:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000362a:	00014517          	auipc	a0,0x14
    8000362e:	40650513          	addi	a0,a0,1030 # 80017a30 <bcache>
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	678080e7          	jalr	1656(ra) # 80000caa <release>
}
    8000363a:	60e2                	ld	ra,24(sp)
    8000363c:	6442                	ld	s0,16(sp)
    8000363e:	64a2                	ld	s1,8(sp)
    80003640:	6902                	ld	s2,0(sp)
    80003642:	6105                	addi	sp,sp,32
    80003644:	8082                	ret
    panic("brelse");
    80003646:	00005517          	auipc	a0,0x5
    8000364a:	f3a50513          	addi	a0,a0,-198 # 80008580 <syscalls+0xf0>
    8000364e:	ffffd097          	auipc	ra,0xffffd
    80003652:	ef0080e7          	jalr	-272(ra) # 8000053e <panic>

0000000080003656 <bpin>:

void
bpin(struct buf *b) {
    80003656:	1101                	addi	sp,sp,-32
    80003658:	ec06                	sd	ra,24(sp)
    8000365a:	e822                	sd	s0,16(sp)
    8000365c:	e426                	sd	s1,8(sp)
    8000365e:	1000                	addi	s0,sp,32
    80003660:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003662:	00014517          	auipc	a0,0x14
    80003666:	3ce50513          	addi	a0,a0,974 # 80017a30 <bcache>
    8000366a:	ffffd097          	auipc	ra,0xffffd
    8000366e:	57a080e7          	jalr	1402(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003672:	40bc                	lw	a5,64(s1)
    80003674:	2785                	addiw	a5,a5,1
    80003676:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003678:	00014517          	auipc	a0,0x14
    8000367c:	3b850513          	addi	a0,a0,952 # 80017a30 <bcache>
    80003680:	ffffd097          	auipc	ra,0xffffd
    80003684:	62a080e7          	jalr	1578(ra) # 80000caa <release>
}
    80003688:	60e2                	ld	ra,24(sp)
    8000368a:	6442                	ld	s0,16(sp)
    8000368c:	64a2                	ld	s1,8(sp)
    8000368e:	6105                	addi	sp,sp,32
    80003690:	8082                	ret

0000000080003692 <bunpin>:

void
bunpin(struct buf *b) {
    80003692:	1101                	addi	sp,sp,-32
    80003694:	ec06                	sd	ra,24(sp)
    80003696:	e822                	sd	s0,16(sp)
    80003698:	e426                	sd	s1,8(sp)
    8000369a:	1000                	addi	s0,sp,32
    8000369c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000369e:	00014517          	auipc	a0,0x14
    800036a2:	39250513          	addi	a0,a0,914 # 80017a30 <bcache>
    800036a6:	ffffd097          	auipc	ra,0xffffd
    800036aa:	53e080e7          	jalr	1342(ra) # 80000be4 <acquire>
  b->refcnt--;
    800036ae:	40bc                	lw	a5,64(s1)
    800036b0:	37fd                	addiw	a5,a5,-1
    800036b2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036b4:	00014517          	auipc	a0,0x14
    800036b8:	37c50513          	addi	a0,a0,892 # 80017a30 <bcache>
    800036bc:	ffffd097          	auipc	ra,0xffffd
    800036c0:	5ee080e7          	jalr	1518(ra) # 80000caa <release>
}
    800036c4:	60e2                	ld	ra,24(sp)
    800036c6:	6442                	ld	s0,16(sp)
    800036c8:	64a2                	ld	s1,8(sp)
    800036ca:	6105                	addi	sp,sp,32
    800036cc:	8082                	ret

00000000800036ce <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800036ce:	1101                	addi	sp,sp,-32
    800036d0:	ec06                	sd	ra,24(sp)
    800036d2:	e822                	sd	s0,16(sp)
    800036d4:	e426                	sd	s1,8(sp)
    800036d6:	e04a                	sd	s2,0(sp)
    800036d8:	1000                	addi	s0,sp,32
    800036da:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800036dc:	00d5d59b          	srliw	a1,a1,0xd
    800036e0:	0001d797          	auipc	a5,0x1d
    800036e4:	a2c7a783          	lw	a5,-1492(a5) # 8002010c <sb+0x1c>
    800036e8:	9dbd                	addw	a1,a1,a5
    800036ea:	00000097          	auipc	ra,0x0
    800036ee:	d9e080e7          	jalr	-610(ra) # 80003488 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800036f2:	0074f713          	andi	a4,s1,7
    800036f6:	4785                	li	a5,1
    800036f8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800036fc:	14ce                	slli	s1,s1,0x33
    800036fe:	90d9                	srli	s1,s1,0x36
    80003700:	00950733          	add	a4,a0,s1
    80003704:	05874703          	lbu	a4,88(a4)
    80003708:	00e7f6b3          	and	a3,a5,a4
    8000370c:	c69d                	beqz	a3,8000373a <bfree+0x6c>
    8000370e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003710:	94aa                	add	s1,s1,a0
    80003712:	fff7c793          	not	a5,a5
    80003716:	8ff9                	and	a5,a5,a4
    80003718:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000371c:	00001097          	auipc	ra,0x1
    80003720:	118080e7          	jalr	280(ra) # 80004834 <log_write>
  brelse(bp);
    80003724:	854a                	mv	a0,s2
    80003726:	00000097          	auipc	ra,0x0
    8000372a:	e92080e7          	jalr	-366(ra) # 800035b8 <brelse>
}
    8000372e:	60e2                	ld	ra,24(sp)
    80003730:	6442                	ld	s0,16(sp)
    80003732:	64a2                	ld	s1,8(sp)
    80003734:	6902                	ld	s2,0(sp)
    80003736:	6105                	addi	sp,sp,32
    80003738:	8082                	ret
    panic("freeing free block");
    8000373a:	00005517          	auipc	a0,0x5
    8000373e:	e4e50513          	addi	a0,a0,-434 # 80008588 <syscalls+0xf8>
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	dfc080e7          	jalr	-516(ra) # 8000053e <panic>

000000008000374a <balloc>:
{
    8000374a:	711d                	addi	sp,sp,-96
    8000374c:	ec86                	sd	ra,88(sp)
    8000374e:	e8a2                	sd	s0,80(sp)
    80003750:	e4a6                	sd	s1,72(sp)
    80003752:	e0ca                	sd	s2,64(sp)
    80003754:	fc4e                	sd	s3,56(sp)
    80003756:	f852                	sd	s4,48(sp)
    80003758:	f456                	sd	s5,40(sp)
    8000375a:	f05a                	sd	s6,32(sp)
    8000375c:	ec5e                	sd	s7,24(sp)
    8000375e:	e862                	sd	s8,16(sp)
    80003760:	e466                	sd	s9,8(sp)
    80003762:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003764:	0001d797          	auipc	a5,0x1d
    80003768:	9907a783          	lw	a5,-1648(a5) # 800200f4 <sb+0x4>
    8000376c:	cbd1                	beqz	a5,80003800 <balloc+0xb6>
    8000376e:	8baa                	mv	s7,a0
    80003770:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003772:	0001db17          	auipc	s6,0x1d
    80003776:	97eb0b13          	addi	s6,s6,-1666 # 800200f0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000377a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000377c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000377e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003780:	6c89                	lui	s9,0x2
    80003782:	a831                	j	8000379e <balloc+0x54>
    brelse(bp);
    80003784:	854a                	mv	a0,s2
    80003786:	00000097          	auipc	ra,0x0
    8000378a:	e32080e7          	jalr	-462(ra) # 800035b8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000378e:	015c87bb          	addw	a5,s9,s5
    80003792:	00078a9b          	sext.w	s5,a5
    80003796:	004b2703          	lw	a4,4(s6)
    8000379a:	06eaf363          	bgeu	s5,a4,80003800 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000379e:	41fad79b          	sraiw	a5,s5,0x1f
    800037a2:	0137d79b          	srliw	a5,a5,0x13
    800037a6:	015787bb          	addw	a5,a5,s5
    800037aa:	40d7d79b          	sraiw	a5,a5,0xd
    800037ae:	01cb2583          	lw	a1,28(s6)
    800037b2:	9dbd                	addw	a1,a1,a5
    800037b4:	855e                	mv	a0,s7
    800037b6:	00000097          	auipc	ra,0x0
    800037ba:	cd2080e7          	jalr	-814(ra) # 80003488 <bread>
    800037be:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037c0:	004b2503          	lw	a0,4(s6)
    800037c4:	000a849b          	sext.w	s1,s5
    800037c8:	8662                	mv	a2,s8
    800037ca:	faa4fde3          	bgeu	s1,a0,80003784 <balloc+0x3a>
      m = 1 << (bi % 8);
    800037ce:	41f6579b          	sraiw	a5,a2,0x1f
    800037d2:	01d7d69b          	srliw	a3,a5,0x1d
    800037d6:	00c6873b          	addw	a4,a3,a2
    800037da:	00777793          	andi	a5,a4,7
    800037de:	9f95                	subw	a5,a5,a3
    800037e0:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800037e4:	4037571b          	sraiw	a4,a4,0x3
    800037e8:	00e906b3          	add	a3,s2,a4
    800037ec:	0586c683          	lbu	a3,88(a3)
    800037f0:	00d7f5b3          	and	a1,a5,a3
    800037f4:	cd91                	beqz	a1,80003810 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037f6:	2605                	addiw	a2,a2,1
    800037f8:	2485                	addiw	s1,s1,1
    800037fa:	fd4618e3          	bne	a2,s4,800037ca <balloc+0x80>
    800037fe:	b759                	j	80003784 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003800:	00005517          	auipc	a0,0x5
    80003804:	da050513          	addi	a0,a0,-608 # 800085a0 <syscalls+0x110>
    80003808:	ffffd097          	auipc	ra,0xffffd
    8000380c:	d36080e7          	jalr	-714(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003810:	974a                	add	a4,a4,s2
    80003812:	8fd5                	or	a5,a5,a3
    80003814:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003818:	854a                	mv	a0,s2
    8000381a:	00001097          	auipc	ra,0x1
    8000381e:	01a080e7          	jalr	26(ra) # 80004834 <log_write>
        brelse(bp);
    80003822:	854a                	mv	a0,s2
    80003824:	00000097          	auipc	ra,0x0
    80003828:	d94080e7          	jalr	-620(ra) # 800035b8 <brelse>
  bp = bread(dev, bno);
    8000382c:	85a6                	mv	a1,s1
    8000382e:	855e                	mv	a0,s7
    80003830:	00000097          	auipc	ra,0x0
    80003834:	c58080e7          	jalr	-936(ra) # 80003488 <bread>
    80003838:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000383a:	40000613          	li	a2,1024
    8000383e:	4581                	li	a1,0
    80003840:	05850513          	addi	a0,a0,88
    80003844:	ffffd097          	auipc	ra,0xffffd
    80003848:	4c0080e7          	jalr	1216(ra) # 80000d04 <memset>
  log_write(bp);
    8000384c:	854a                	mv	a0,s2
    8000384e:	00001097          	auipc	ra,0x1
    80003852:	fe6080e7          	jalr	-26(ra) # 80004834 <log_write>
  brelse(bp);
    80003856:	854a                	mv	a0,s2
    80003858:	00000097          	auipc	ra,0x0
    8000385c:	d60080e7          	jalr	-672(ra) # 800035b8 <brelse>
}
    80003860:	8526                	mv	a0,s1
    80003862:	60e6                	ld	ra,88(sp)
    80003864:	6446                	ld	s0,80(sp)
    80003866:	64a6                	ld	s1,72(sp)
    80003868:	6906                	ld	s2,64(sp)
    8000386a:	79e2                	ld	s3,56(sp)
    8000386c:	7a42                	ld	s4,48(sp)
    8000386e:	7aa2                	ld	s5,40(sp)
    80003870:	7b02                	ld	s6,32(sp)
    80003872:	6be2                	ld	s7,24(sp)
    80003874:	6c42                	ld	s8,16(sp)
    80003876:	6ca2                	ld	s9,8(sp)
    80003878:	6125                	addi	sp,sp,96
    8000387a:	8082                	ret

000000008000387c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000387c:	7179                	addi	sp,sp,-48
    8000387e:	f406                	sd	ra,40(sp)
    80003880:	f022                	sd	s0,32(sp)
    80003882:	ec26                	sd	s1,24(sp)
    80003884:	e84a                	sd	s2,16(sp)
    80003886:	e44e                	sd	s3,8(sp)
    80003888:	e052                	sd	s4,0(sp)
    8000388a:	1800                	addi	s0,sp,48
    8000388c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000388e:	47ad                	li	a5,11
    80003890:	04b7fe63          	bgeu	a5,a1,800038ec <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003894:	ff45849b          	addiw	s1,a1,-12
    80003898:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000389c:	0ff00793          	li	a5,255
    800038a0:	0ae7e363          	bltu	a5,a4,80003946 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800038a4:	08052583          	lw	a1,128(a0)
    800038a8:	c5ad                	beqz	a1,80003912 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800038aa:	00092503          	lw	a0,0(s2)
    800038ae:	00000097          	auipc	ra,0x0
    800038b2:	bda080e7          	jalr	-1062(ra) # 80003488 <bread>
    800038b6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800038b8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800038bc:	02049593          	slli	a1,s1,0x20
    800038c0:	9181                	srli	a1,a1,0x20
    800038c2:	058a                	slli	a1,a1,0x2
    800038c4:	00b784b3          	add	s1,a5,a1
    800038c8:	0004a983          	lw	s3,0(s1)
    800038cc:	04098d63          	beqz	s3,80003926 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800038d0:	8552                	mv	a0,s4
    800038d2:	00000097          	auipc	ra,0x0
    800038d6:	ce6080e7          	jalr	-794(ra) # 800035b8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038da:	854e                	mv	a0,s3
    800038dc:	70a2                	ld	ra,40(sp)
    800038de:	7402                	ld	s0,32(sp)
    800038e0:	64e2                	ld	s1,24(sp)
    800038e2:	6942                	ld	s2,16(sp)
    800038e4:	69a2                	ld	s3,8(sp)
    800038e6:	6a02                	ld	s4,0(sp)
    800038e8:	6145                	addi	sp,sp,48
    800038ea:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800038ec:	02059493          	slli	s1,a1,0x20
    800038f0:	9081                	srli	s1,s1,0x20
    800038f2:	048a                	slli	s1,s1,0x2
    800038f4:	94aa                	add	s1,s1,a0
    800038f6:	0504a983          	lw	s3,80(s1)
    800038fa:	fe0990e3          	bnez	s3,800038da <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800038fe:	4108                	lw	a0,0(a0)
    80003900:	00000097          	auipc	ra,0x0
    80003904:	e4a080e7          	jalr	-438(ra) # 8000374a <balloc>
    80003908:	0005099b          	sext.w	s3,a0
    8000390c:	0534a823          	sw	s3,80(s1)
    80003910:	b7e9                	j	800038da <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003912:	4108                	lw	a0,0(a0)
    80003914:	00000097          	auipc	ra,0x0
    80003918:	e36080e7          	jalr	-458(ra) # 8000374a <balloc>
    8000391c:	0005059b          	sext.w	a1,a0
    80003920:	08b92023          	sw	a1,128(s2)
    80003924:	b759                	j	800038aa <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003926:	00092503          	lw	a0,0(s2)
    8000392a:	00000097          	auipc	ra,0x0
    8000392e:	e20080e7          	jalr	-480(ra) # 8000374a <balloc>
    80003932:	0005099b          	sext.w	s3,a0
    80003936:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000393a:	8552                	mv	a0,s4
    8000393c:	00001097          	auipc	ra,0x1
    80003940:	ef8080e7          	jalr	-264(ra) # 80004834 <log_write>
    80003944:	b771                	j	800038d0 <bmap+0x54>
  panic("bmap: out of range");
    80003946:	00005517          	auipc	a0,0x5
    8000394a:	c7250513          	addi	a0,a0,-910 # 800085b8 <syscalls+0x128>
    8000394e:	ffffd097          	auipc	ra,0xffffd
    80003952:	bf0080e7          	jalr	-1040(ra) # 8000053e <panic>

0000000080003956 <iget>:
{
    80003956:	7179                	addi	sp,sp,-48
    80003958:	f406                	sd	ra,40(sp)
    8000395a:	f022                	sd	s0,32(sp)
    8000395c:	ec26                	sd	s1,24(sp)
    8000395e:	e84a                	sd	s2,16(sp)
    80003960:	e44e                	sd	s3,8(sp)
    80003962:	e052                	sd	s4,0(sp)
    80003964:	1800                	addi	s0,sp,48
    80003966:	89aa                	mv	s3,a0
    80003968:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000396a:	0001c517          	auipc	a0,0x1c
    8000396e:	7a650513          	addi	a0,a0,1958 # 80020110 <itable>
    80003972:	ffffd097          	auipc	ra,0xffffd
    80003976:	272080e7          	jalr	626(ra) # 80000be4 <acquire>
  empty = 0;
    8000397a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000397c:	0001c497          	auipc	s1,0x1c
    80003980:	7ac48493          	addi	s1,s1,1964 # 80020128 <itable+0x18>
    80003984:	0001e697          	auipc	a3,0x1e
    80003988:	23468693          	addi	a3,a3,564 # 80021bb8 <log>
    8000398c:	a039                	j	8000399a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000398e:	02090b63          	beqz	s2,800039c4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003992:	08848493          	addi	s1,s1,136
    80003996:	02d48a63          	beq	s1,a3,800039ca <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000399a:	449c                	lw	a5,8(s1)
    8000399c:	fef059e3          	blez	a5,8000398e <iget+0x38>
    800039a0:	4098                	lw	a4,0(s1)
    800039a2:	ff3716e3          	bne	a4,s3,8000398e <iget+0x38>
    800039a6:	40d8                	lw	a4,4(s1)
    800039a8:	ff4713e3          	bne	a4,s4,8000398e <iget+0x38>
      ip->ref++;
    800039ac:	2785                	addiw	a5,a5,1
    800039ae:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800039b0:	0001c517          	auipc	a0,0x1c
    800039b4:	76050513          	addi	a0,a0,1888 # 80020110 <itable>
    800039b8:	ffffd097          	auipc	ra,0xffffd
    800039bc:	2f2080e7          	jalr	754(ra) # 80000caa <release>
      return ip;
    800039c0:	8926                	mv	s2,s1
    800039c2:	a03d                	j	800039f0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039c4:	f7f9                	bnez	a5,80003992 <iget+0x3c>
    800039c6:	8926                	mv	s2,s1
    800039c8:	b7e9                	j	80003992 <iget+0x3c>
  if(empty == 0)
    800039ca:	02090c63          	beqz	s2,80003a02 <iget+0xac>
  ip->dev = dev;
    800039ce:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800039d2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800039d6:	4785                	li	a5,1
    800039d8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800039dc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800039e0:	0001c517          	auipc	a0,0x1c
    800039e4:	73050513          	addi	a0,a0,1840 # 80020110 <itable>
    800039e8:	ffffd097          	auipc	ra,0xffffd
    800039ec:	2c2080e7          	jalr	706(ra) # 80000caa <release>
}
    800039f0:	854a                	mv	a0,s2
    800039f2:	70a2                	ld	ra,40(sp)
    800039f4:	7402                	ld	s0,32(sp)
    800039f6:	64e2                	ld	s1,24(sp)
    800039f8:	6942                	ld	s2,16(sp)
    800039fa:	69a2                	ld	s3,8(sp)
    800039fc:	6a02                	ld	s4,0(sp)
    800039fe:	6145                	addi	sp,sp,48
    80003a00:	8082                	ret
    panic("iget: no inodes");
    80003a02:	00005517          	auipc	a0,0x5
    80003a06:	bce50513          	addi	a0,a0,-1074 # 800085d0 <syscalls+0x140>
    80003a0a:	ffffd097          	auipc	ra,0xffffd
    80003a0e:	b34080e7          	jalr	-1228(ra) # 8000053e <panic>

0000000080003a12 <fsinit>:
fsinit(int dev) {
    80003a12:	7179                	addi	sp,sp,-48
    80003a14:	f406                	sd	ra,40(sp)
    80003a16:	f022                	sd	s0,32(sp)
    80003a18:	ec26                	sd	s1,24(sp)
    80003a1a:	e84a                	sd	s2,16(sp)
    80003a1c:	e44e                	sd	s3,8(sp)
    80003a1e:	1800                	addi	s0,sp,48
    80003a20:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a22:	4585                	li	a1,1
    80003a24:	00000097          	auipc	ra,0x0
    80003a28:	a64080e7          	jalr	-1436(ra) # 80003488 <bread>
    80003a2c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a2e:	0001c997          	auipc	s3,0x1c
    80003a32:	6c298993          	addi	s3,s3,1730 # 800200f0 <sb>
    80003a36:	02000613          	li	a2,32
    80003a3a:	05850593          	addi	a1,a0,88
    80003a3e:	854e                	mv	a0,s3
    80003a40:	ffffd097          	auipc	ra,0xffffd
    80003a44:	324080e7          	jalr	804(ra) # 80000d64 <memmove>
  brelse(bp);
    80003a48:	8526                	mv	a0,s1
    80003a4a:	00000097          	auipc	ra,0x0
    80003a4e:	b6e080e7          	jalr	-1170(ra) # 800035b8 <brelse>
  if(sb.magic != FSMAGIC)
    80003a52:	0009a703          	lw	a4,0(s3)
    80003a56:	102037b7          	lui	a5,0x10203
    80003a5a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a5e:	02f71263          	bne	a4,a5,80003a82 <fsinit+0x70>
  initlog(dev, &sb);
    80003a62:	0001c597          	auipc	a1,0x1c
    80003a66:	68e58593          	addi	a1,a1,1678 # 800200f0 <sb>
    80003a6a:	854a                	mv	a0,s2
    80003a6c:	00001097          	auipc	ra,0x1
    80003a70:	b4c080e7          	jalr	-1204(ra) # 800045b8 <initlog>
}
    80003a74:	70a2                	ld	ra,40(sp)
    80003a76:	7402                	ld	s0,32(sp)
    80003a78:	64e2                	ld	s1,24(sp)
    80003a7a:	6942                	ld	s2,16(sp)
    80003a7c:	69a2                	ld	s3,8(sp)
    80003a7e:	6145                	addi	sp,sp,48
    80003a80:	8082                	ret
    panic("invalid file system");
    80003a82:	00005517          	auipc	a0,0x5
    80003a86:	b5e50513          	addi	a0,a0,-1186 # 800085e0 <syscalls+0x150>
    80003a8a:	ffffd097          	auipc	ra,0xffffd
    80003a8e:	ab4080e7          	jalr	-1356(ra) # 8000053e <panic>

0000000080003a92 <iinit>:
{
    80003a92:	7179                	addi	sp,sp,-48
    80003a94:	f406                	sd	ra,40(sp)
    80003a96:	f022                	sd	s0,32(sp)
    80003a98:	ec26                	sd	s1,24(sp)
    80003a9a:	e84a                	sd	s2,16(sp)
    80003a9c:	e44e                	sd	s3,8(sp)
    80003a9e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003aa0:	00005597          	auipc	a1,0x5
    80003aa4:	b5858593          	addi	a1,a1,-1192 # 800085f8 <syscalls+0x168>
    80003aa8:	0001c517          	auipc	a0,0x1c
    80003aac:	66850513          	addi	a0,a0,1640 # 80020110 <itable>
    80003ab0:	ffffd097          	auipc	ra,0xffffd
    80003ab4:	0a4080e7          	jalr	164(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003ab8:	0001c497          	auipc	s1,0x1c
    80003abc:	68048493          	addi	s1,s1,1664 # 80020138 <itable+0x28>
    80003ac0:	0001e997          	auipc	s3,0x1e
    80003ac4:	10898993          	addi	s3,s3,264 # 80021bc8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003ac8:	00005917          	auipc	s2,0x5
    80003acc:	b3890913          	addi	s2,s2,-1224 # 80008600 <syscalls+0x170>
    80003ad0:	85ca                	mv	a1,s2
    80003ad2:	8526                	mv	a0,s1
    80003ad4:	00001097          	auipc	ra,0x1
    80003ad8:	e46080e7          	jalr	-442(ra) # 8000491a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003adc:	08848493          	addi	s1,s1,136
    80003ae0:	ff3498e3          	bne	s1,s3,80003ad0 <iinit+0x3e>
}
    80003ae4:	70a2                	ld	ra,40(sp)
    80003ae6:	7402                	ld	s0,32(sp)
    80003ae8:	64e2                	ld	s1,24(sp)
    80003aea:	6942                	ld	s2,16(sp)
    80003aec:	69a2                	ld	s3,8(sp)
    80003aee:	6145                	addi	sp,sp,48
    80003af0:	8082                	ret

0000000080003af2 <ialloc>:
{
    80003af2:	715d                	addi	sp,sp,-80
    80003af4:	e486                	sd	ra,72(sp)
    80003af6:	e0a2                	sd	s0,64(sp)
    80003af8:	fc26                	sd	s1,56(sp)
    80003afa:	f84a                	sd	s2,48(sp)
    80003afc:	f44e                	sd	s3,40(sp)
    80003afe:	f052                	sd	s4,32(sp)
    80003b00:	ec56                	sd	s5,24(sp)
    80003b02:	e85a                	sd	s6,16(sp)
    80003b04:	e45e                	sd	s7,8(sp)
    80003b06:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b08:	0001c717          	auipc	a4,0x1c
    80003b0c:	5f472703          	lw	a4,1524(a4) # 800200fc <sb+0xc>
    80003b10:	4785                	li	a5,1
    80003b12:	04e7fa63          	bgeu	a5,a4,80003b66 <ialloc+0x74>
    80003b16:	8aaa                	mv	s5,a0
    80003b18:	8bae                	mv	s7,a1
    80003b1a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b1c:	0001ca17          	auipc	s4,0x1c
    80003b20:	5d4a0a13          	addi	s4,s4,1492 # 800200f0 <sb>
    80003b24:	00048b1b          	sext.w	s6,s1
    80003b28:	0044d593          	srli	a1,s1,0x4
    80003b2c:	018a2783          	lw	a5,24(s4)
    80003b30:	9dbd                	addw	a1,a1,a5
    80003b32:	8556                	mv	a0,s5
    80003b34:	00000097          	auipc	ra,0x0
    80003b38:	954080e7          	jalr	-1708(ra) # 80003488 <bread>
    80003b3c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b3e:	05850993          	addi	s3,a0,88
    80003b42:	00f4f793          	andi	a5,s1,15
    80003b46:	079a                	slli	a5,a5,0x6
    80003b48:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b4a:	00099783          	lh	a5,0(s3)
    80003b4e:	c785                	beqz	a5,80003b76 <ialloc+0x84>
    brelse(bp);
    80003b50:	00000097          	auipc	ra,0x0
    80003b54:	a68080e7          	jalr	-1432(ra) # 800035b8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b58:	0485                	addi	s1,s1,1
    80003b5a:	00ca2703          	lw	a4,12(s4)
    80003b5e:	0004879b          	sext.w	a5,s1
    80003b62:	fce7e1e3          	bltu	a5,a4,80003b24 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003b66:	00005517          	auipc	a0,0x5
    80003b6a:	aa250513          	addi	a0,a0,-1374 # 80008608 <syscalls+0x178>
    80003b6e:	ffffd097          	auipc	ra,0xffffd
    80003b72:	9d0080e7          	jalr	-1584(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003b76:	04000613          	li	a2,64
    80003b7a:	4581                	li	a1,0
    80003b7c:	854e                	mv	a0,s3
    80003b7e:	ffffd097          	auipc	ra,0xffffd
    80003b82:	186080e7          	jalr	390(ra) # 80000d04 <memset>
      dip->type = type;
    80003b86:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b8a:	854a                	mv	a0,s2
    80003b8c:	00001097          	auipc	ra,0x1
    80003b90:	ca8080e7          	jalr	-856(ra) # 80004834 <log_write>
      brelse(bp);
    80003b94:	854a                	mv	a0,s2
    80003b96:	00000097          	auipc	ra,0x0
    80003b9a:	a22080e7          	jalr	-1502(ra) # 800035b8 <brelse>
      return iget(dev, inum);
    80003b9e:	85da                	mv	a1,s6
    80003ba0:	8556                	mv	a0,s5
    80003ba2:	00000097          	auipc	ra,0x0
    80003ba6:	db4080e7          	jalr	-588(ra) # 80003956 <iget>
}
    80003baa:	60a6                	ld	ra,72(sp)
    80003bac:	6406                	ld	s0,64(sp)
    80003bae:	74e2                	ld	s1,56(sp)
    80003bb0:	7942                	ld	s2,48(sp)
    80003bb2:	79a2                	ld	s3,40(sp)
    80003bb4:	7a02                	ld	s4,32(sp)
    80003bb6:	6ae2                	ld	s5,24(sp)
    80003bb8:	6b42                	ld	s6,16(sp)
    80003bba:	6ba2                	ld	s7,8(sp)
    80003bbc:	6161                	addi	sp,sp,80
    80003bbe:	8082                	ret

0000000080003bc0 <iupdate>:
{
    80003bc0:	1101                	addi	sp,sp,-32
    80003bc2:	ec06                	sd	ra,24(sp)
    80003bc4:	e822                	sd	s0,16(sp)
    80003bc6:	e426                	sd	s1,8(sp)
    80003bc8:	e04a                	sd	s2,0(sp)
    80003bca:	1000                	addi	s0,sp,32
    80003bcc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bce:	415c                	lw	a5,4(a0)
    80003bd0:	0047d79b          	srliw	a5,a5,0x4
    80003bd4:	0001c597          	auipc	a1,0x1c
    80003bd8:	5345a583          	lw	a1,1332(a1) # 80020108 <sb+0x18>
    80003bdc:	9dbd                	addw	a1,a1,a5
    80003bde:	4108                	lw	a0,0(a0)
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	8a8080e7          	jalr	-1880(ra) # 80003488 <bread>
    80003be8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bea:	05850793          	addi	a5,a0,88
    80003bee:	40c8                	lw	a0,4(s1)
    80003bf0:	893d                	andi	a0,a0,15
    80003bf2:	051a                	slli	a0,a0,0x6
    80003bf4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003bf6:	04449703          	lh	a4,68(s1)
    80003bfa:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003bfe:	04649703          	lh	a4,70(s1)
    80003c02:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003c06:	04849703          	lh	a4,72(s1)
    80003c0a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c0e:	04a49703          	lh	a4,74(s1)
    80003c12:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c16:	44f8                	lw	a4,76(s1)
    80003c18:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c1a:	03400613          	li	a2,52
    80003c1e:	05048593          	addi	a1,s1,80
    80003c22:	0531                	addi	a0,a0,12
    80003c24:	ffffd097          	auipc	ra,0xffffd
    80003c28:	140080e7          	jalr	320(ra) # 80000d64 <memmove>
  log_write(bp);
    80003c2c:	854a                	mv	a0,s2
    80003c2e:	00001097          	auipc	ra,0x1
    80003c32:	c06080e7          	jalr	-1018(ra) # 80004834 <log_write>
  brelse(bp);
    80003c36:	854a                	mv	a0,s2
    80003c38:	00000097          	auipc	ra,0x0
    80003c3c:	980080e7          	jalr	-1664(ra) # 800035b8 <brelse>
}
    80003c40:	60e2                	ld	ra,24(sp)
    80003c42:	6442                	ld	s0,16(sp)
    80003c44:	64a2                	ld	s1,8(sp)
    80003c46:	6902                	ld	s2,0(sp)
    80003c48:	6105                	addi	sp,sp,32
    80003c4a:	8082                	ret

0000000080003c4c <idup>:
{
    80003c4c:	1101                	addi	sp,sp,-32
    80003c4e:	ec06                	sd	ra,24(sp)
    80003c50:	e822                	sd	s0,16(sp)
    80003c52:	e426                	sd	s1,8(sp)
    80003c54:	1000                	addi	s0,sp,32
    80003c56:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c58:	0001c517          	auipc	a0,0x1c
    80003c5c:	4b850513          	addi	a0,a0,1208 # 80020110 <itable>
    80003c60:	ffffd097          	auipc	ra,0xffffd
    80003c64:	f84080e7          	jalr	-124(ra) # 80000be4 <acquire>
  ip->ref++;
    80003c68:	449c                	lw	a5,8(s1)
    80003c6a:	2785                	addiw	a5,a5,1
    80003c6c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c6e:	0001c517          	auipc	a0,0x1c
    80003c72:	4a250513          	addi	a0,a0,1186 # 80020110 <itable>
    80003c76:	ffffd097          	auipc	ra,0xffffd
    80003c7a:	034080e7          	jalr	52(ra) # 80000caa <release>
}
    80003c7e:	8526                	mv	a0,s1
    80003c80:	60e2                	ld	ra,24(sp)
    80003c82:	6442                	ld	s0,16(sp)
    80003c84:	64a2                	ld	s1,8(sp)
    80003c86:	6105                	addi	sp,sp,32
    80003c88:	8082                	ret

0000000080003c8a <ilock>:
{
    80003c8a:	1101                	addi	sp,sp,-32
    80003c8c:	ec06                	sd	ra,24(sp)
    80003c8e:	e822                	sd	s0,16(sp)
    80003c90:	e426                	sd	s1,8(sp)
    80003c92:	e04a                	sd	s2,0(sp)
    80003c94:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c96:	c115                	beqz	a0,80003cba <ilock+0x30>
    80003c98:	84aa                	mv	s1,a0
    80003c9a:	451c                	lw	a5,8(a0)
    80003c9c:	00f05f63          	blez	a5,80003cba <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ca0:	0541                	addi	a0,a0,16
    80003ca2:	00001097          	auipc	ra,0x1
    80003ca6:	cb2080e7          	jalr	-846(ra) # 80004954 <acquiresleep>
  if(ip->valid == 0){
    80003caa:	40bc                	lw	a5,64(s1)
    80003cac:	cf99                	beqz	a5,80003cca <ilock+0x40>
}
    80003cae:	60e2                	ld	ra,24(sp)
    80003cb0:	6442                	ld	s0,16(sp)
    80003cb2:	64a2                	ld	s1,8(sp)
    80003cb4:	6902                	ld	s2,0(sp)
    80003cb6:	6105                	addi	sp,sp,32
    80003cb8:	8082                	ret
    panic("ilock");
    80003cba:	00005517          	auipc	a0,0x5
    80003cbe:	96650513          	addi	a0,a0,-1690 # 80008620 <syscalls+0x190>
    80003cc2:	ffffd097          	auipc	ra,0xffffd
    80003cc6:	87c080e7          	jalr	-1924(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cca:	40dc                	lw	a5,4(s1)
    80003ccc:	0047d79b          	srliw	a5,a5,0x4
    80003cd0:	0001c597          	auipc	a1,0x1c
    80003cd4:	4385a583          	lw	a1,1080(a1) # 80020108 <sb+0x18>
    80003cd8:	9dbd                	addw	a1,a1,a5
    80003cda:	4088                	lw	a0,0(s1)
    80003cdc:	fffff097          	auipc	ra,0xfffff
    80003ce0:	7ac080e7          	jalr	1964(ra) # 80003488 <bread>
    80003ce4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ce6:	05850593          	addi	a1,a0,88
    80003cea:	40dc                	lw	a5,4(s1)
    80003cec:	8bbd                	andi	a5,a5,15
    80003cee:	079a                	slli	a5,a5,0x6
    80003cf0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003cf2:	00059783          	lh	a5,0(a1)
    80003cf6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003cfa:	00259783          	lh	a5,2(a1)
    80003cfe:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d02:	00459783          	lh	a5,4(a1)
    80003d06:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d0a:	00659783          	lh	a5,6(a1)
    80003d0e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d12:	459c                	lw	a5,8(a1)
    80003d14:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d16:	03400613          	li	a2,52
    80003d1a:	05b1                	addi	a1,a1,12
    80003d1c:	05048513          	addi	a0,s1,80
    80003d20:	ffffd097          	auipc	ra,0xffffd
    80003d24:	044080e7          	jalr	68(ra) # 80000d64 <memmove>
    brelse(bp);
    80003d28:	854a                	mv	a0,s2
    80003d2a:	00000097          	auipc	ra,0x0
    80003d2e:	88e080e7          	jalr	-1906(ra) # 800035b8 <brelse>
    ip->valid = 1;
    80003d32:	4785                	li	a5,1
    80003d34:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d36:	04449783          	lh	a5,68(s1)
    80003d3a:	fbb5                	bnez	a5,80003cae <ilock+0x24>
      panic("ilock: no type");
    80003d3c:	00005517          	auipc	a0,0x5
    80003d40:	8ec50513          	addi	a0,a0,-1812 # 80008628 <syscalls+0x198>
    80003d44:	ffffc097          	auipc	ra,0xffffc
    80003d48:	7fa080e7          	jalr	2042(ra) # 8000053e <panic>

0000000080003d4c <iunlock>:
{
    80003d4c:	1101                	addi	sp,sp,-32
    80003d4e:	ec06                	sd	ra,24(sp)
    80003d50:	e822                	sd	s0,16(sp)
    80003d52:	e426                	sd	s1,8(sp)
    80003d54:	e04a                	sd	s2,0(sp)
    80003d56:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d58:	c905                	beqz	a0,80003d88 <iunlock+0x3c>
    80003d5a:	84aa                	mv	s1,a0
    80003d5c:	01050913          	addi	s2,a0,16
    80003d60:	854a                	mv	a0,s2
    80003d62:	00001097          	auipc	ra,0x1
    80003d66:	c8c080e7          	jalr	-884(ra) # 800049ee <holdingsleep>
    80003d6a:	cd19                	beqz	a0,80003d88 <iunlock+0x3c>
    80003d6c:	449c                	lw	a5,8(s1)
    80003d6e:	00f05d63          	blez	a5,80003d88 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d72:	854a                	mv	a0,s2
    80003d74:	00001097          	auipc	ra,0x1
    80003d78:	c36080e7          	jalr	-970(ra) # 800049aa <releasesleep>
}
    80003d7c:	60e2                	ld	ra,24(sp)
    80003d7e:	6442                	ld	s0,16(sp)
    80003d80:	64a2                	ld	s1,8(sp)
    80003d82:	6902                	ld	s2,0(sp)
    80003d84:	6105                	addi	sp,sp,32
    80003d86:	8082                	ret
    panic("iunlock");
    80003d88:	00005517          	auipc	a0,0x5
    80003d8c:	8b050513          	addi	a0,a0,-1872 # 80008638 <syscalls+0x1a8>
    80003d90:	ffffc097          	auipc	ra,0xffffc
    80003d94:	7ae080e7          	jalr	1966(ra) # 8000053e <panic>

0000000080003d98 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d98:	7179                	addi	sp,sp,-48
    80003d9a:	f406                	sd	ra,40(sp)
    80003d9c:	f022                	sd	s0,32(sp)
    80003d9e:	ec26                	sd	s1,24(sp)
    80003da0:	e84a                	sd	s2,16(sp)
    80003da2:	e44e                	sd	s3,8(sp)
    80003da4:	e052                	sd	s4,0(sp)
    80003da6:	1800                	addi	s0,sp,48
    80003da8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003daa:	05050493          	addi	s1,a0,80
    80003dae:	08050913          	addi	s2,a0,128
    80003db2:	a021                	j	80003dba <itrunc+0x22>
    80003db4:	0491                	addi	s1,s1,4
    80003db6:	01248d63          	beq	s1,s2,80003dd0 <itrunc+0x38>
    if(ip->addrs[i]){
    80003dba:	408c                	lw	a1,0(s1)
    80003dbc:	dde5                	beqz	a1,80003db4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003dbe:	0009a503          	lw	a0,0(s3)
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	90c080e7          	jalr	-1780(ra) # 800036ce <bfree>
      ip->addrs[i] = 0;
    80003dca:	0004a023          	sw	zero,0(s1)
    80003dce:	b7dd                	j	80003db4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003dd0:	0809a583          	lw	a1,128(s3)
    80003dd4:	e185                	bnez	a1,80003df4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003dd6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003dda:	854e                	mv	a0,s3
    80003ddc:	00000097          	auipc	ra,0x0
    80003de0:	de4080e7          	jalr	-540(ra) # 80003bc0 <iupdate>
}
    80003de4:	70a2                	ld	ra,40(sp)
    80003de6:	7402                	ld	s0,32(sp)
    80003de8:	64e2                	ld	s1,24(sp)
    80003dea:	6942                	ld	s2,16(sp)
    80003dec:	69a2                	ld	s3,8(sp)
    80003dee:	6a02                	ld	s4,0(sp)
    80003df0:	6145                	addi	sp,sp,48
    80003df2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003df4:	0009a503          	lw	a0,0(s3)
    80003df8:	fffff097          	auipc	ra,0xfffff
    80003dfc:	690080e7          	jalr	1680(ra) # 80003488 <bread>
    80003e00:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e02:	05850493          	addi	s1,a0,88
    80003e06:	45850913          	addi	s2,a0,1112
    80003e0a:	a811                	j	80003e1e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003e0c:	0009a503          	lw	a0,0(s3)
    80003e10:	00000097          	auipc	ra,0x0
    80003e14:	8be080e7          	jalr	-1858(ra) # 800036ce <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003e18:	0491                	addi	s1,s1,4
    80003e1a:	01248563          	beq	s1,s2,80003e24 <itrunc+0x8c>
      if(a[j])
    80003e1e:	408c                	lw	a1,0(s1)
    80003e20:	dde5                	beqz	a1,80003e18 <itrunc+0x80>
    80003e22:	b7ed                	j	80003e0c <itrunc+0x74>
    brelse(bp);
    80003e24:	8552                	mv	a0,s4
    80003e26:	fffff097          	auipc	ra,0xfffff
    80003e2a:	792080e7          	jalr	1938(ra) # 800035b8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e2e:	0809a583          	lw	a1,128(s3)
    80003e32:	0009a503          	lw	a0,0(s3)
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	898080e7          	jalr	-1896(ra) # 800036ce <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e3e:	0809a023          	sw	zero,128(s3)
    80003e42:	bf51                	j	80003dd6 <itrunc+0x3e>

0000000080003e44 <iput>:
{
    80003e44:	1101                	addi	sp,sp,-32
    80003e46:	ec06                	sd	ra,24(sp)
    80003e48:	e822                	sd	s0,16(sp)
    80003e4a:	e426                	sd	s1,8(sp)
    80003e4c:	e04a                	sd	s2,0(sp)
    80003e4e:	1000                	addi	s0,sp,32
    80003e50:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e52:	0001c517          	auipc	a0,0x1c
    80003e56:	2be50513          	addi	a0,a0,702 # 80020110 <itable>
    80003e5a:	ffffd097          	auipc	ra,0xffffd
    80003e5e:	d8a080e7          	jalr	-630(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e62:	4498                	lw	a4,8(s1)
    80003e64:	4785                	li	a5,1
    80003e66:	02f70363          	beq	a4,a5,80003e8c <iput+0x48>
  ip->ref--;
    80003e6a:	449c                	lw	a5,8(s1)
    80003e6c:	37fd                	addiw	a5,a5,-1
    80003e6e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e70:	0001c517          	auipc	a0,0x1c
    80003e74:	2a050513          	addi	a0,a0,672 # 80020110 <itable>
    80003e78:	ffffd097          	auipc	ra,0xffffd
    80003e7c:	e32080e7          	jalr	-462(ra) # 80000caa <release>
}
    80003e80:	60e2                	ld	ra,24(sp)
    80003e82:	6442                	ld	s0,16(sp)
    80003e84:	64a2                	ld	s1,8(sp)
    80003e86:	6902                	ld	s2,0(sp)
    80003e88:	6105                	addi	sp,sp,32
    80003e8a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e8c:	40bc                	lw	a5,64(s1)
    80003e8e:	dff1                	beqz	a5,80003e6a <iput+0x26>
    80003e90:	04a49783          	lh	a5,74(s1)
    80003e94:	fbf9                	bnez	a5,80003e6a <iput+0x26>
    acquiresleep(&ip->lock);
    80003e96:	01048913          	addi	s2,s1,16
    80003e9a:	854a                	mv	a0,s2
    80003e9c:	00001097          	auipc	ra,0x1
    80003ea0:	ab8080e7          	jalr	-1352(ra) # 80004954 <acquiresleep>
    release(&itable.lock);
    80003ea4:	0001c517          	auipc	a0,0x1c
    80003ea8:	26c50513          	addi	a0,a0,620 # 80020110 <itable>
    80003eac:	ffffd097          	auipc	ra,0xffffd
    80003eb0:	dfe080e7          	jalr	-514(ra) # 80000caa <release>
    itrunc(ip);
    80003eb4:	8526                	mv	a0,s1
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	ee2080e7          	jalr	-286(ra) # 80003d98 <itrunc>
    ip->type = 0;
    80003ebe:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ec2:	8526                	mv	a0,s1
    80003ec4:	00000097          	auipc	ra,0x0
    80003ec8:	cfc080e7          	jalr	-772(ra) # 80003bc0 <iupdate>
    ip->valid = 0;
    80003ecc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ed0:	854a                	mv	a0,s2
    80003ed2:	00001097          	auipc	ra,0x1
    80003ed6:	ad8080e7          	jalr	-1320(ra) # 800049aa <releasesleep>
    acquire(&itable.lock);
    80003eda:	0001c517          	auipc	a0,0x1c
    80003ede:	23650513          	addi	a0,a0,566 # 80020110 <itable>
    80003ee2:	ffffd097          	auipc	ra,0xffffd
    80003ee6:	d02080e7          	jalr	-766(ra) # 80000be4 <acquire>
    80003eea:	b741                	j	80003e6a <iput+0x26>

0000000080003eec <iunlockput>:
{
    80003eec:	1101                	addi	sp,sp,-32
    80003eee:	ec06                	sd	ra,24(sp)
    80003ef0:	e822                	sd	s0,16(sp)
    80003ef2:	e426                	sd	s1,8(sp)
    80003ef4:	1000                	addi	s0,sp,32
    80003ef6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ef8:	00000097          	auipc	ra,0x0
    80003efc:	e54080e7          	jalr	-428(ra) # 80003d4c <iunlock>
  iput(ip);
    80003f00:	8526                	mv	a0,s1
    80003f02:	00000097          	auipc	ra,0x0
    80003f06:	f42080e7          	jalr	-190(ra) # 80003e44 <iput>
}
    80003f0a:	60e2                	ld	ra,24(sp)
    80003f0c:	6442                	ld	s0,16(sp)
    80003f0e:	64a2                	ld	s1,8(sp)
    80003f10:	6105                	addi	sp,sp,32
    80003f12:	8082                	ret

0000000080003f14 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f14:	1141                	addi	sp,sp,-16
    80003f16:	e422                	sd	s0,8(sp)
    80003f18:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f1a:	411c                	lw	a5,0(a0)
    80003f1c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f1e:	415c                	lw	a5,4(a0)
    80003f20:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f22:	04451783          	lh	a5,68(a0)
    80003f26:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f2a:	04a51783          	lh	a5,74(a0)
    80003f2e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f32:	04c56783          	lwu	a5,76(a0)
    80003f36:	e99c                	sd	a5,16(a1)
}
    80003f38:	6422                	ld	s0,8(sp)
    80003f3a:	0141                	addi	sp,sp,16
    80003f3c:	8082                	ret

0000000080003f3e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f3e:	457c                	lw	a5,76(a0)
    80003f40:	0ed7e963          	bltu	a5,a3,80004032 <readi+0xf4>
{
    80003f44:	7159                	addi	sp,sp,-112
    80003f46:	f486                	sd	ra,104(sp)
    80003f48:	f0a2                	sd	s0,96(sp)
    80003f4a:	eca6                	sd	s1,88(sp)
    80003f4c:	e8ca                	sd	s2,80(sp)
    80003f4e:	e4ce                	sd	s3,72(sp)
    80003f50:	e0d2                	sd	s4,64(sp)
    80003f52:	fc56                	sd	s5,56(sp)
    80003f54:	f85a                	sd	s6,48(sp)
    80003f56:	f45e                	sd	s7,40(sp)
    80003f58:	f062                	sd	s8,32(sp)
    80003f5a:	ec66                	sd	s9,24(sp)
    80003f5c:	e86a                	sd	s10,16(sp)
    80003f5e:	e46e                	sd	s11,8(sp)
    80003f60:	1880                	addi	s0,sp,112
    80003f62:	8baa                	mv	s7,a0
    80003f64:	8c2e                	mv	s8,a1
    80003f66:	8ab2                	mv	s5,a2
    80003f68:	84b6                	mv	s1,a3
    80003f6a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f6c:	9f35                	addw	a4,a4,a3
    return 0;
    80003f6e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f70:	0ad76063          	bltu	a4,a3,80004010 <readi+0xd2>
  if(off + n > ip->size)
    80003f74:	00e7f463          	bgeu	a5,a4,80003f7c <readi+0x3e>
    n = ip->size - off;
    80003f78:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f7c:	0a0b0963          	beqz	s6,8000402e <readi+0xf0>
    80003f80:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f82:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f86:	5cfd                	li	s9,-1
    80003f88:	a82d                	j	80003fc2 <readi+0x84>
    80003f8a:	020a1d93          	slli	s11,s4,0x20
    80003f8e:	020ddd93          	srli	s11,s11,0x20
    80003f92:	05890613          	addi	a2,s2,88
    80003f96:	86ee                	mv	a3,s11
    80003f98:	963a                	add	a2,a2,a4
    80003f9a:	85d6                	mv	a1,s5
    80003f9c:	8562                	mv	a0,s8
    80003f9e:	fffff097          	auipc	ra,0xfffff
    80003fa2:	8ec080e7          	jalr	-1812(ra) # 8000288a <either_copyout>
    80003fa6:	05950d63          	beq	a0,s9,80004000 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003faa:	854a                	mv	a0,s2
    80003fac:	fffff097          	auipc	ra,0xfffff
    80003fb0:	60c080e7          	jalr	1548(ra) # 800035b8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fb4:	013a09bb          	addw	s3,s4,s3
    80003fb8:	009a04bb          	addw	s1,s4,s1
    80003fbc:	9aee                	add	s5,s5,s11
    80003fbe:	0569f763          	bgeu	s3,s6,8000400c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fc2:	000ba903          	lw	s2,0(s7)
    80003fc6:	00a4d59b          	srliw	a1,s1,0xa
    80003fca:	855e                	mv	a0,s7
    80003fcc:	00000097          	auipc	ra,0x0
    80003fd0:	8b0080e7          	jalr	-1872(ra) # 8000387c <bmap>
    80003fd4:	0005059b          	sext.w	a1,a0
    80003fd8:	854a                	mv	a0,s2
    80003fda:	fffff097          	auipc	ra,0xfffff
    80003fde:	4ae080e7          	jalr	1198(ra) # 80003488 <bread>
    80003fe2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fe4:	3ff4f713          	andi	a4,s1,1023
    80003fe8:	40ed07bb          	subw	a5,s10,a4
    80003fec:	413b06bb          	subw	a3,s6,s3
    80003ff0:	8a3e                	mv	s4,a5
    80003ff2:	2781                	sext.w	a5,a5
    80003ff4:	0006861b          	sext.w	a2,a3
    80003ff8:	f8f679e3          	bgeu	a2,a5,80003f8a <readi+0x4c>
    80003ffc:	8a36                	mv	s4,a3
    80003ffe:	b771                	j	80003f8a <readi+0x4c>
      brelse(bp);
    80004000:	854a                	mv	a0,s2
    80004002:	fffff097          	auipc	ra,0xfffff
    80004006:	5b6080e7          	jalr	1462(ra) # 800035b8 <brelse>
      tot = -1;
    8000400a:	59fd                	li	s3,-1
  }
  return tot;
    8000400c:	0009851b          	sext.w	a0,s3
}
    80004010:	70a6                	ld	ra,104(sp)
    80004012:	7406                	ld	s0,96(sp)
    80004014:	64e6                	ld	s1,88(sp)
    80004016:	6946                	ld	s2,80(sp)
    80004018:	69a6                	ld	s3,72(sp)
    8000401a:	6a06                	ld	s4,64(sp)
    8000401c:	7ae2                	ld	s5,56(sp)
    8000401e:	7b42                	ld	s6,48(sp)
    80004020:	7ba2                	ld	s7,40(sp)
    80004022:	7c02                	ld	s8,32(sp)
    80004024:	6ce2                	ld	s9,24(sp)
    80004026:	6d42                	ld	s10,16(sp)
    80004028:	6da2                	ld	s11,8(sp)
    8000402a:	6165                	addi	sp,sp,112
    8000402c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000402e:	89da                	mv	s3,s6
    80004030:	bff1                	j	8000400c <readi+0xce>
    return 0;
    80004032:	4501                	li	a0,0
}
    80004034:	8082                	ret

0000000080004036 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004036:	457c                	lw	a5,76(a0)
    80004038:	10d7e863          	bltu	a5,a3,80004148 <writei+0x112>
{
    8000403c:	7159                	addi	sp,sp,-112
    8000403e:	f486                	sd	ra,104(sp)
    80004040:	f0a2                	sd	s0,96(sp)
    80004042:	eca6                	sd	s1,88(sp)
    80004044:	e8ca                	sd	s2,80(sp)
    80004046:	e4ce                	sd	s3,72(sp)
    80004048:	e0d2                	sd	s4,64(sp)
    8000404a:	fc56                	sd	s5,56(sp)
    8000404c:	f85a                	sd	s6,48(sp)
    8000404e:	f45e                	sd	s7,40(sp)
    80004050:	f062                	sd	s8,32(sp)
    80004052:	ec66                	sd	s9,24(sp)
    80004054:	e86a                	sd	s10,16(sp)
    80004056:	e46e                	sd	s11,8(sp)
    80004058:	1880                	addi	s0,sp,112
    8000405a:	8b2a                	mv	s6,a0
    8000405c:	8c2e                	mv	s8,a1
    8000405e:	8ab2                	mv	s5,a2
    80004060:	8936                	mv	s2,a3
    80004062:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004064:	00e687bb          	addw	a5,a3,a4
    80004068:	0ed7e263          	bltu	a5,a3,8000414c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000406c:	00043737          	lui	a4,0x43
    80004070:	0ef76063          	bltu	a4,a5,80004150 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004074:	0c0b8863          	beqz	s7,80004144 <writei+0x10e>
    80004078:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000407a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000407e:	5cfd                	li	s9,-1
    80004080:	a091                	j	800040c4 <writei+0x8e>
    80004082:	02099d93          	slli	s11,s3,0x20
    80004086:	020ddd93          	srli	s11,s11,0x20
    8000408a:	05848513          	addi	a0,s1,88
    8000408e:	86ee                	mv	a3,s11
    80004090:	8656                	mv	a2,s5
    80004092:	85e2                	mv	a1,s8
    80004094:	953a                	add	a0,a0,a4
    80004096:	fffff097          	auipc	ra,0xfffff
    8000409a:	84a080e7          	jalr	-1974(ra) # 800028e0 <either_copyin>
    8000409e:	07950263          	beq	a0,s9,80004102 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800040a2:	8526                	mv	a0,s1
    800040a4:	00000097          	auipc	ra,0x0
    800040a8:	790080e7          	jalr	1936(ra) # 80004834 <log_write>
    brelse(bp);
    800040ac:	8526                	mv	a0,s1
    800040ae:	fffff097          	auipc	ra,0xfffff
    800040b2:	50a080e7          	jalr	1290(ra) # 800035b8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040b6:	01498a3b          	addw	s4,s3,s4
    800040ba:	0129893b          	addw	s2,s3,s2
    800040be:	9aee                	add	s5,s5,s11
    800040c0:	057a7663          	bgeu	s4,s7,8000410c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800040c4:	000b2483          	lw	s1,0(s6)
    800040c8:	00a9559b          	srliw	a1,s2,0xa
    800040cc:	855a                	mv	a0,s6
    800040ce:	fffff097          	auipc	ra,0xfffff
    800040d2:	7ae080e7          	jalr	1966(ra) # 8000387c <bmap>
    800040d6:	0005059b          	sext.w	a1,a0
    800040da:	8526                	mv	a0,s1
    800040dc:	fffff097          	auipc	ra,0xfffff
    800040e0:	3ac080e7          	jalr	940(ra) # 80003488 <bread>
    800040e4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040e6:	3ff97713          	andi	a4,s2,1023
    800040ea:	40ed07bb          	subw	a5,s10,a4
    800040ee:	414b86bb          	subw	a3,s7,s4
    800040f2:	89be                	mv	s3,a5
    800040f4:	2781                	sext.w	a5,a5
    800040f6:	0006861b          	sext.w	a2,a3
    800040fa:	f8f674e3          	bgeu	a2,a5,80004082 <writei+0x4c>
    800040fe:	89b6                	mv	s3,a3
    80004100:	b749                	j	80004082 <writei+0x4c>
      brelse(bp);
    80004102:	8526                	mv	a0,s1
    80004104:	fffff097          	auipc	ra,0xfffff
    80004108:	4b4080e7          	jalr	1204(ra) # 800035b8 <brelse>
  }

  if(off > ip->size)
    8000410c:	04cb2783          	lw	a5,76(s6)
    80004110:	0127f463          	bgeu	a5,s2,80004118 <writei+0xe2>
    ip->size = off;
    80004114:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004118:	855a                	mv	a0,s6
    8000411a:	00000097          	auipc	ra,0x0
    8000411e:	aa6080e7          	jalr	-1370(ra) # 80003bc0 <iupdate>

  return tot;
    80004122:	000a051b          	sext.w	a0,s4
}
    80004126:	70a6                	ld	ra,104(sp)
    80004128:	7406                	ld	s0,96(sp)
    8000412a:	64e6                	ld	s1,88(sp)
    8000412c:	6946                	ld	s2,80(sp)
    8000412e:	69a6                	ld	s3,72(sp)
    80004130:	6a06                	ld	s4,64(sp)
    80004132:	7ae2                	ld	s5,56(sp)
    80004134:	7b42                	ld	s6,48(sp)
    80004136:	7ba2                	ld	s7,40(sp)
    80004138:	7c02                	ld	s8,32(sp)
    8000413a:	6ce2                	ld	s9,24(sp)
    8000413c:	6d42                	ld	s10,16(sp)
    8000413e:	6da2                	ld	s11,8(sp)
    80004140:	6165                	addi	sp,sp,112
    80004142:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004144:	8a5e                	mv	s4,s7
    80004146:	bfc9                	j	80004118 <writei+0xe2>
    return -1;
    80004148:	557d                	li	a0,-1
}
    8000414a:	8082                	ret
    return -1;
    8000414c:	557d                	li	a0,-1
    8000414e:	bfe1                	j	80004126 <writei+0xf0>
    return -1;
    80004150:	557d                	li	a0,-1
    80004152:	bfd1                	j	80004126 <writei+0xf0>

0000000080004154 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004154:	1141                	addi	sp,sp,-16
    80004156:	e406                	sd	ra,8(sp)
    80004158:	e022                	sd	s0,0(sp)
    8000415a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000415c:	4639                	li	a2,14
    8000415e:	ffffd097          	auipc	ra,0xffffd
    80004162:	c7e080e7          	jalr	-898(ra) # 80000ddc <strncmp>
}
    80004166:	60a2                	ld	ra,8(sp)
    80004168:	6402                	ld	s0,0(sp)
    8000416a:	0141                	addi	sp,sp,16
    8000416c:	8082                	ret

000000008000416e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000416e:	7139                	addi	sp,sp,-64
    80004170:	fc06                	sd	ra,56(sp)
    80004172:	f822                	sd	s0,48(sp)
    80004174:	f426                	sd	s1,40(sp)
    80004176:	f04a                	sd	s2,32(sp)
    80004178:	ec4e                	sd	s3,24(sp)
    8000417a:	e852                	sd	s4,16(sp)
    8000417c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000417e:	04451703          	lh	a4,68(a0)
    80004182:	4785                	li	a5,1
    80004184:	00f71a63          	bne	a4,a5,80004198 <dirlookup+0x2a>
    80004188:	892a                	mv	s2,a0
    8000418a:	89ae                	mv	s3,a1
    8000418c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000418e:	457c                	lw	a5,76(a0)
    80004190:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004192:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004194:	e79d                	bnez	a5,800041c2 <dirlookup+0x54>
    80004196:	a8a5                	j	8000420e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004198:	00004517          	auipc	a0,0x4
    8000419c:	4a850513          	addi	a0,a0,1192 # 80008640 <syscalls+0x1b0>
    800041a0:	ffffc097          	auipc	ra,0xffffc
    800041a4:	39e080e7          	jalr	926(ra) # 8000053e <panic>
      panic("dirlookup read");
    800041a8:	00004517          	auipc	a0,0x4
    800041ac:	4b050513          	addi	a0,a0,1200 # 80008658 <syscalls+0x1c8>
    800041b0:	ffffc097          	auipc	ra,0xffffc
    800041b4:	38e080e7          	jalr	910(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041b8:	24c1                	addiw	s1,s1,16
    800041ba:	04c92783          	lw	a5,76(s2)
    800041be:	04f4f763          	bgeu	s1,a5,8000420c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041c2:	4741                	li	a4,16
    800041c4:	86a6                	mv	a3,s1
    800041c6:	fc040613          	addi	a2,s0,-64
    800041ca:	4581                	li	a1,0
    800041cc:	854a                	mv	a0,s2
    800041ce:	00000097          	auipc	ra,0x0
    800041d2:	d70080e7          	jalr	-656(ra) # 80003f3e <readi>
    800041d6:	47c1                	li	a5,16
    800041d8:	fcf518e3          	bne	a0,a5,800041a8 <dirlookup+0x3a>
    if(de.inum == 0)
    800041dc:	fc045783          	lhu	a5,-64(s0)
    800041e0:	dfe1                	beqz	a5,800041b8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800041e2:	fc240593          	addi	a1,s0,-62
    800041e6:	854e                	mv	a0,s3
    800041e8:	00000097          	auipc	ra,0x0
    800041ec:	f6c080e7          	jalr	-148(ra) # 80004154 <namecmp>
    800041f0:	f561                	bnez	a0,800041b8 <dirlookup+0x4a>
      if(poff)
    800041f2:	000a0463          	beqz	s4,800041fa <dirlookup+0x8c>
        *poff = off;
    800041f6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041fa:	fc045583          	lhu	a1,-64(s0)
    800041fe:	00092503          	lw	a0,0(s2)
    80004202:	fffff097          	auipc	ra,0xfffff
    80004206:	754080e7          	jalr	1876(ra) # 80003956 <iget>
    8000420a:	a011                	j	8000420e <dirlookup+0xa0>
  return 0;
    8000420c:	4501                	li	a0,0
}
    8000420e:	70e2                	ld	ra,56(sp)
    80004210:	7442                	ld	s0,48(sp)
    80004212:	74a2                	ld	s1,40(sp)
    80004214:	7902                	ld	s2,32(sp)
    80004216:	69e2                	ld	s3,24(sp)
    80004218:	6a42                	ld	s4,16(sp)
    8000421a:	6121                	addi	sp,sp,64
    8000421c:	8082                	ret

000000008000421e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000421e:	711d                	addi	sp,sp,-96
    80004220:	ec86                	sd	ra,88(sp)
    80004222:	e8a2                	sd	s0,80(sp)
    80004224:	e4a6                	sd	s1,72(sp)
    80004226:	e0ca                	sd	s2,64(sp)
    80004228:	fc4e                	sd	s3,56(sp)
    8000422a:	f852                	sd	s4,48(sp)
    8000422c:	f456                	sd	s5,40(sp)
    8000422e:	f05a                	sd	s6,32(sp)
    80004230:	ec5e                	sd	s7,24(sp)
    80004232:	e862                	sd	s8,16(sp)
    80004234:	e466                	sd	s9,8(sp)
    80004236:	1080                	addi	s0,sp,96
    80004238:	84aa                	mv	s1,a0
    8000423a:	8b2e                	mv	s6,a1
    8000423c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000423e:	00054703          	lbu	a4,0(a0)
    80004242:	02f00793          	li	a5,47
    80004246:	02f70363          	beq	a4,a5,8000426c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000424a:	ffffe097          	auipc	ra,0xffffe
    8000424e:	b4c080e7          	jalr	-1204(ra) # 80001d96 <myproc>
    80004252:	17053503          	ld	a0,368(a0)
    80004256:	00000097          	auipc	ra,0x0
    8000425a:	9f6080e7          	jalr	-1546(ra) # 80003c4c <idup>
    8000425e:	89aa                	mv	s3,a0
  while(*path == '/')
    80004260:	02f00913          	li	s2,47
  len = path - s;
    80004264:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004266:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004268:	4c05                	li	s8,1
    8000426a:	a865                	j	80004322 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000426c:	4585                	li	a1,1
    8000426e:	4505                	li	a0,1
    80004270:	fffff097          	auipc	ra,0xfffff
    80004274:	6e6080e7          	jalr	1766(ra) # 80003956 <iget>
    80004278:	89aa                	mv	s3,a0
    8000427a:	b7dd                	j	80004260 <namex+0x42>
      iunlockput(ip);
    8000427c:	854e                	mv	a0,s3
    8000427e:	00000097          	auipc	ra,0x0
    80004282:	c6e080e7          	jalr	-914(ra) # 80003eec <iunlockput>
      return 0;
    80004286:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004288:	854e                	mv	a0,s3
    8000428a:	60e6                	ld	ra,88(sp)
    8000428c:	6446                	ld	s0,80(sp)
    8000428e:	64a6                	ld	s1,72(sp)
    80004290:	6906                	ld	s2,64(sp)
    80004292:	79e2                	ld	s3,56(sp)
    80004294:	7a42                	ld	s4,48(sp)
    80004296:	7aa2                	ld	s5,40(sp)
    80004298:	7b02                	ld	s6,32(sp)
    8000429a:	6be2                	ld	s7,24(sp)
    8000429c:	6c42                	ld	s8,16(sp)
    8000429e:	6ca2                	ld	s9,8(sp)
    800042a0:	6125                	addi	sp,sp,96
    800042a2:	8082                	ret
      iunlock(ip);
    800042a4:	854e                	mv	a0,s3
    800042a6:	00000097          	auipc	ra,0x0
    800042aa:	aa6080e7          	jalr	-1370(ra) # 80003d4c <iunlock>
      return ip;
    800042ae:	bfe9                	j	80004288 <namex+0x6a>
      iunlockput(ip);
    800042b0:	854e                	mv	a0,s3
    800042b2:	00000097          	auipc	ra,0x0
    800042b6:	c3a080e7          	jalr	-966(ra) # 80003eec <iunlockput>
      return 0;
    800042ba:	89d2                	mv	s3,s4
    800042bc:	b7f1                	j	80004288 <namex+0x6a>
  len = path - s;
    800042be:	40b48633          	sub	a2,s1,a1
    800042c2:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800042c6:	094cd463          	bge	s9,s4,8000434e <namex+0x130>
    memmove(name, s, DIRSIZ);
    800042ca:	4639                	li	a2,14
    800042cc:	8556                	mv	a0,s5
    800042ce:	ffffd097          	auipc	ra,0xffffd
    800042d2:	a96080e7          	jalr	-1386(ra) # 80000d64 <memmove>
  while(*path == '/')
    800042d6:	0004c783          	lbu	a5,0(s1)
    800042da:	01279763          	bne	a5,s2,800042e8 <namex+0xca>
    path++;
    800042de:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042e0:	0004c783          	lbu	a5,0(s1)
    800042e4:	ff278de3          	beq	a5,s2,800042de <namex+0xc0>
    ilock(ip);
    800042e8:	854e                	mv	a0,s3
    800042ea:	00000097          	auipc	ra,0x0
    800042ee:	9a0080e7          	jalr	-1632(ra) # 80003c8a <ilock>
    if(ip->type != T_DIR){
    800042f2:	04499783          	lh	a5,68(s3)
    800042f6:	f98793e3          	bne	a5,s8,8000427c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800042fa:	000b0563          	beqz	s6,80004304 <namex+0xe6>
    800042fe:	0004c783          	lbu	a5,0(s1)
    80004302:	d3cd                	beqz	a5,800042a4 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004304:	865e                	mv	a2,s7
    80004306:	85d6                	mv	a1,s5
    80004308:	854e                	mv	a0,s3
    8000430a:	00000097          	auipc	ra,0x0
    8000430e:	e64080e7          	jalr	-412(ra) # 8000416e <dirlookup>
    80004312:	8a2a                	mv	s4,a0
    80004314:	dd51                	beqz	a0,800042b0 <namex+0x92>
    iunlockput(ip);
    80004316:	854e                	mv	a0,s3
    80004318:	00000097          	auipc	ra,0x0
    8000431c:	bd4080e7          	jalr	-1068(ra) # 80003eec <iunlockput>
    ip = next;
    80004320:	89d2                	mv	s3,s4
  while(*path == '/')
    80004322:	0004c783          	lbu	a5,0(s1)
    80004326:	05279763          	bne	a5,s2,80004374 <namex+0x156>
    path++;
    8000432a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000432c:	0004c783          	lbu	a5,0(s1)
    80004330:	ff278de3          	beq	a5,s2,8000432a <namex+0x10c>
  if(*path == 0)
    80004334:	c79d                	beqz	a5,80004362 <namex+0x144>
    path++;
    80004336:	85a6                	mv	a1,s1
  len = path - s;
    80004338:	8a5e                	mv	s4,s7
    8000433a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000433c:	01278963          	beq	a5,s2,8000434e <namex+0x130>
    80004340:	dfbd                	beqz	a5,800042be <namex+0xa0>
    path++;
    80004342:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004344:	0004c783          	lbu	a5,0(s1)
    80004348:	ff279ce3          	bne	a5,s2,80004340 <namex+0x122>
    8000434c:	bf8d                	j	800042be <namex+0xa0>
    memmove(name, s, len);
    8000434e:	2601                	sext.w	a2,a2
    80004350:	8556                	mv	a0,s5
    80004352:	ffffd097          	auipc	ra,0xffffd
    80004356:	a12080e7          	jalr	-1518(ra) # 80000d64 <memmove>
    name[len] = 0;
    8000435a:	9a56                	add	s4,s4,s5
    8000435c:	000a0023          	sb	zero,0(s4)
    80004360:	bf9d                	j	800042d6 <namex+0xb8>
  if(nameiparent){
    80004362:	f20b03e3          	beqz	s6,80004288 <namex+0x6a>
    iput(ip);
    80004366:	854e                	mv	a0,s3
    80004368:	00000097          	auipc	ra,0x0
    8000436c:	adc080e7          	jalr	-1316(ra) # 80003e44 <iput>
    return 0;
    80004370:	4981                	li	s3,0
    80004372:	bf19                	j	80004288 <namex+0x6a>
  if(*path == 0)
    80004374:	d7fd                	beqz	a5,80004362 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004376:	0004c783          	lbu	a5,0(s1)
    8000437a:	85a6                	mv	a1,s1
    8000437c:	b7d1                	j	80004340 <namex+0x122>

000000008000437e <dirlink>:
{
    8000437e:	7139                	addi	sp,sp,-64
    80004380:	fc06                	sd	ra,56(sp)
    80004382:	f822                	sd	s0,48(sp)
    80004384:	f426                	sd	s1,40(sp)
    80004386:	f04a                	sd	s2,32(sp)
    80004388:	ec4e                	sd	s3,24(sp)
    8000438a:	e852                	sd	s4,16(sp)
    8000438c:	0080                	addi	s0,sp,64
    8000438e:	892a                	mv	s2,a0
    80004390:	8a2e                	mv	s4,a1
    80004392:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004394:	4601                	li	a2,0
    80004396:	00000097          	auipc	ra,0x0
    8000439a:	dd8080e7          	jalr	-552(ra) # 8000416e <dirlookup>
    8000439e:	e93d                	bnez	a0,80004414 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043a0:	04c92483          	lw	s1,76(s2)
    800043a4:	c49d                	beqz	s1,800043d2 <dirlink+0x54>
    800043a6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043a8:	4741                	li	a4,16
    800043aa:	86a6                	mv	a3,s1
    800043ac:	fc040613          	addi	a2,s0,-64
    800043b0:	4581                	li	a1,0
    800043b2:	854a                	mv	a0,s2
    800043b4:	00000097          	auipc	ra,0x0
    800043b8:	b8a080e7          	jalr	-1142(ra) # 80003f3e <readi>
    800043bc:	47c1                	li	a5,16
    800043be:	06f51163          	bne	a0,a5,80004420 <dirlink+0xa2>
    if(de.inum == 0)
    800043c2:	fc045783          	lhu	a5,-64(s0)
    800043c6:	c791                	beqz	a5,800043d2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043c8:	24c1                	addiw	s1,s1,16
    800043ca:	04c92783          	lw	a5,76(s2)
    800043ce:	fcf4ede3          	bltu	s1,a5,800043a8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800043d2:	4639                	li	a2,14
    800043d4:	85d2                	mv	a1,s4
    800043d6:	fc240513          	addi	a0,s0,-62
    800043da:	ffffd097          	auipc	ra,0xffffd
    800043de:	a3e080e7          	jalr	-1474(ra) # 80000e18 <strncpy>
  de.inum = inum;
    800043e2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043e6:	4741                	li	a4,16
    800043e8:	86a6                	mv	a3,s1
    800043ea:	fc040613          	addi	a2,s0,-64
    800043ee:	4581                	li	a1,0
    800043f0:	854a                	mv	a0,s2
    800043f2:	00000097          	auipc	ra,0x0
    800043f6:	c44080e7          	jalr	-956(ra) # 80004036 <writei>
    800043fa:	872a                	mv	a4,a0
    800043fc:	47c1                	li	a5,16
  return 0;
    800043fe:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004400:	02f71863          	bne	a4,a5,80004430 <dirlink+0xb2>
}
    80004404:	70e2                	ld	ra,56(sp)
    80004406:	7442                	ld	s0,48(sp)
    80004408:	74a2                	ld	s1,40(sp)
    8000440a:	7902                	ld	s2,32(sp)
    8000440c:	69e2                	ld	s3,24(sp)
    8000440e:	6a42                	ld	s4,16(sp)
    80004410:	6121                	addi	sp,sp,64
    80004412:	8082                	ret
    iput(ip);
    80004414:	00000097          	auipc	ra,0x0
    80004418:	a30080e7          	jalr	-1488(ra) # 80003e44 <iput>
    return -1;
    8000441c:	557d                	li	a0,-1
    8000441e:	b7dd                	j	80004404 <dirlink+0x86>
      panic("dirlink read");
    80004420:	00004517          	auipc	a0,0x4
    80004424:	24850513          	addi	a0,a0,584 # 80008668 <syscalls+0x1d8>
    80004428:	ffffc097          	auipc	ra,0xffffc
    8000442c:	116080e7          	jalr	278(ra) # 8000053e <panic>
    panic("dirlink");
    80004430:	00004517          	auipc	a0,0x4
    80004434:	34850513          	addi	a0,a0,840 # 80008778 <syscalls+0x2e8>
    80004438:	ffffc097          	auipc	ra,0xffffc
    8000443c:	106080e7          	jalr	262(ra) # 8000053e <panic>

0000000080004440 <namei>:

struct inode*
namei(char *path)
{
    80004440:	1101                	addi	sp,sp,-32
    80004442:	ec06                	sd	ra,24(sp)
    80004444:	e822                	sd	s0,16(sp)
    80004446:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004448:	fe040613          	addi	a2,s0,-32
    8000444c:	4581                	li	a1,0
    8000444e:	00000097          	auipc	ra,0x0
    80004452:	dd0080e7          	jalr	-560(ra) # 8000421e <namex>
}
    80004456:	60e2                	ld	ra,24(sp)
    80004458:	6442                	ld	s0,16(sp)
    8000445a:	6105                	addi	sp,sp,32
    8000445c:	8082                	ret

000000008000445e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000445e:	1141                	addi	sp,sp,-16
    80004460:	e406                	sd	ra,8(sp)
    80004462:	e022                	sd	s0,0(sp)
    80004464:	0800                	addi	s0,sp,16
    80004466:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004468:	4585                	li	a1,1
    8000446a:	00000097          	auipc	ra,0x0
    8000446e:	db4080e7          	jalr	-588(ra) # 8000421e <namex>
}
    80004472:	60a2                	ld	ra,8(sp)
    80004474:	6402                	ld	s0,0(sp)
    80004476:	0141                	addi	sp,sp,16
    80004478:	8082                	ret

000000008000447a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000447a:	1101                	addi	sp,sp,-32
    8000447c:	ec06                	sd	ra,24(sp)
    8000447e:	e822                	sd	s0,16(sp)
    80004480:	e426                	sd	s1,8(sp)
    80004482:	e04a                	sd	s2,0(sp)
    80004484:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004486:	0001d917          	auipc	s2,0x1d
    8000448a:	73290913          	addi	s2,s2,1842 # 80021bb8 <log>
    8000448e:	01892583          	lw	a1,24(s2)
    80004492:	02892503          	lw	a0,40(s2)
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	ff2080e7          	jalr	-14(ra) # 80003488 <bread>
    8000449e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800044a0:	02c92683          	lw	a3,44(s2)
    800044a4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800044a6:	02d05763          	blez	a3,800044d4 <write_head+0x5a>
    800044aa:	0001d797          	auipc	a5,0x1d
    800044ae:	73e78793          	addi	a5,a5,1854 # 80021be8 <log+0x30>
    800044b2:	05c50713          	addi	a4,a0,92
    800044b6:	36fd                	addiw	a3,a3,-1
    800044b8:	1682                	slli	a3,a3,0x20
    800044ba:	9281                	srli	a3,a3,0x20
    800044bc:	068a                	slli	a3,a3,0x2
    800044be:	0001d617          	auipc	a2,0x1d
    800044c2:	72e60613          	addi	a2,a2,1838 # 80021bec <log+0x34>
    800044c6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800044c8:	4390                	lw	a2,0(a5)
    800044ca:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044cc:	0791                	addi	a5,a5,4
    800044ce:	0711                	addi	a4,a4,4
    800044d0:	fed79ce3          	bne	a5,a3,800044c8 <write_head+0x4e>
  }
  bwrite(buf);
    800044d4:	8526                	mv	a0,s1
    800044d6:	fffff097          	auipc	ra,0xfffff
    800044da:	0a4080e7          	jalr	164(ra) # 8000357a <bwrite>
  brelse(buf);
    800044de:	8526                	mv	a0,s1
    800044e0:	fffff097          	auipc	ra,0xfffff
    800044e4:	0d8080e7          	jalr	216(ra) # 800035b8 <brelse>
}
    800044e8:	60e2                	ld	ra,24(sp)
    800044ea:	6442                	ld	s0,16(sp)
    800044ec:	64a2                	ld	s1,8(sp)
    800044ee:	6902                	ld	s2,0(sp)
    800044f0:	6105                	addi	sp,sp,32
    800044f2:	8082                	ret

00000000800044f4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800044f4:	0001d797          	auipc	a5,0x1d
    800044f8:	6f07a783          	lw	a5,1776(a5) # 80021be4 <log+0x2c>
    800044fc:	0af05d63          	blez	a5,800045b6 <install_trans+0xc2>
{
    80004500:	7139                	addi	sp,sp,-64
    80004502:	fc06                	sd	ra,56(sp)
    80004504:	f822                	sd	s0,48(sp)
    80004506:	f426                	sd	s1,40(sp)
    80004508:	f04a                	sd	s2,32(sp)
    8000450a:	ec4e                	sd	s3,24(sp)
    8000450c:	e852                	sd	s4,16(sp)
    8000450e:	e456                	sd	s5,8(sp)
    80004510:	e05a                	sd	s6,0(sp)
    80004512:	0080                	addi	s0,sp,64
    80004514:	8b2a                	mv	s6,a0
    80004516:	0001da97          	auipc	s5,0x1d
    8000451a:	6d2a8a93          	addi	s5,s5,1746 # 80021be8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000451e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004520:	0001d997          	auipc	s3,0x1d
    80004524:	69898993          	addi	s3,s3,1688 # 80021bb8 <log>
    80004528:	a035                	j	80004554 <install_trans+0x60>
      bunpin(dbuf);
    8000452a:	8526                	mv	a0,s1
    8000452c:	fffff097          	auipc	ra,0xfffff
    80004530:	166080e7          	jalr	358(ra) # 80003692 <bunpin>
    brelse(lbuf);
    80004534:	854a                	mv	a0,s2
    80004536:	fffff097          	auipc	ra,0xfffff
    8000453a:	082080e7          	jalr	130(ra) # 800035b8 <brelse>
    brelse(dbuf);
    8000453e:	8526                	mv	a0,s1
    80004540:	fffff097          	auipc	ra,0xfffff
    80004544:	078080e7          	jalr	120(ra) # 800035b8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004548:	2a05                	addiw	s4,s4,1
    8000454a:	0a91                	addi	s5,s5,4
    8000454c:	02c9a783          	lw	a5,44(s3)
    80004550:	04fa5963          	bge	s4,a5,800045a2 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004554:	0189a583          	lw	a1,24(s3)
    80004558:	014585bb          	addw	a1,a1,s4
    8000455c:	2585                	addiw	a1,a1,1
    8000455e:	0289a503          	lw	a0,40(s3)
    80004562:	fffff097          	auipc	ra,0xfffff
    80004566:	f26080e7          	jalr	-218(ra) # 80003488 <bread>
    8000456a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000456c:	000aa583          	lw	a1,0(s5)
    80004570:	0289a503          	lw	a0,40(s3)
    80004574:	fffff097          	auipc	ra,0xfffff
    80004578:	f14080e7          	jalr	-236(ra) # 80003488 <bread>
    8000457c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000457e:	40000613          	li	a2,1024
    80004582:	05890593          	addi	a1,s2,88
    80004586:	05850513          	addi	a0,a0,88
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	7da080e7          	jalr	2010(ra) # 80000d64 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004592:	8526                	mv	a0,s1
    80004594:	fffff097          	auipc	ra,0xfffff
    80004598:	fe6080e7          	jalr	-26(ra) # 8000357a <bwrite>
    if(recovering == 0)
    8000459c:	f80b1ce3          	bnez	s6,80004534 <install_trans+0x40>
    800045a0:	b769                	j	8000452a <install_trans+0x36>
}
    800045a2:	70e2                	ld	ra,56(sp)
    800045a4:	7442                	ld	s0,48(sp)
    800045a6:	74a2                	ld	s1,40(sp)
    800045a8:	7902                	ld	s2,32(sp)
    800045aa:	69e2                	ld	s3,24(sp)
    800045ac:	6a42                	ld	s4,16(sp)
    800045ae:	6aa2                	ld	s5,8(sp)
    800045b0:	6b02                	ld	s6,0(sp)
    800045b2:	6121                	addi	sp,sp,64
    800045b4:	8082                	ret
    800045b6:	8082                	ret

00000000800045b8 <initlog>:
{
    800045b8:	7179                	addi	sp,sp,-48
    800045ba:	f406                	sd	ra,40(sp)
    800045bc:	f022                	sd	s0,32(sp)
    800045be:	ec26                	sd	s1,24(sp)
    800045c0:	e84a                	sd	s2,16(sp)
    800045c2:	e44e                	sd	s3,8(sp)
    800045c4:	1800                	addi	s0,sp,48
    800045c6:	892a                	mv	s2,a0
    800045c8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800045ca:	0001d497          	auipc	s1,0x1d
    800045ce:	5ee48493          	addi	s1,s1,1518 # 80021bb8 <log>
    800045d2:	00004597          	auipc	a1,0x4
    800045d6:	0a658593          	addi	a1,a1,166 # 80008678 <syscalls+0x1e8>
    800045da:	8526                	mv	a0,s1
    800045dc:	ffffc097          	auipc	ra,0xffffc
    800045e0:	578080e7          	jalr	1400(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800045e4:	0149a583          	lw	a1,20(s3)
    800045e8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800045ea:	0109a783          	lw	a5,16(s3)
    800045ee:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800045f0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800045f4:	854a                	mv	a0,s2
    800045f6:	fffff097          	auipc	ra,0xfffff
    800045fa:	e92080e7          	jalr	-366(ra) # 80003488 <bread>
  log.lh.n = lh->n;
    800045fe:	4d3c                	lw	a5,88(a0)
    80004600:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004602:	02f05563          	blez	a5,8000462c <initlog+0x74>
    80004606:	05c50713          	addi	a4,a0,92
    8000460a:	0001d697          	auipc	a3,0x1d
    8000460e:	5de68693          	addi	a3,a3,1502 # 80021be8 <log+0x30>
    80004612:	37fd                	addiw	a5,a5,-1
    80004614:	1782                	slli	a5,a5,0x20
    80004616:	9381                	srli	a5,a5,0x20
    80004618:	078a                	slli	a5,a5,0x2
    8000461a:	06050613          	addi	a2,a0,96
    8000461e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004620:	4310                	lw	a2,0(a4)
    80004622:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004624:	0711                	addi	a4,a4,4
    80004626:	0691                	addi	a3,a3,4
    80004628:	fef71ce3          	bne	a4,a5,80004620 <initlog+0x68>
  brelse(buf);
    8000462c:	fffff097          	auipc	ra,0xfffff
    80004630:	f8c080e7          	jalr	-116(ra) # 800035b8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004634:	4505                	li	a0,1
    80004636:	00000097          	auipc	ra,0x0
    8000463a:	ebe080e7          	jalr	-322(ra) # 800044f4 <install_trans>
  log.lh.n = 0;
    8000463e:	0001d797          	auipc	a5,0x1d
    80004642:	5a07a323          	sw	zero,1446(a5) # 80021be4 <log+0x2c>
  write_head(); // clear the log
    80004646:	00000097          	auipc	ra,0x0
    8000464a:	e34080e7          	jalr	-460(ra) # 8000447a <write_head>
}
    8000464e:	70a2                	ld	ra,40(sp)
    80004650:	7402                	ld	s0,32(sp)
    80004652:	64e2                	ld	s1,24(sp)
    80004654:	6942                	ld	s2,16(sp)
    80004656:	69a2                	ld	s3,8(sp)
    80004658:	6145                	addi	sp,sp,48
    8000465a:	8082                	ret

000000008000465c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000465c:	1101                	addi	sp,sp,-32
    8000465e:	ec06                	sd	ra,24(sp)
    80004660:	e822                	sd	s0,16(sp)
    80004662:	e426                	sd	s1,8(sp)
    80004664:	e04a                	sd	s2,0(sp)
    80004666:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004668:	0001d517          	auipc	a0,0x1d
    8000466c:	55050513          	addi	a0,a0,1360 # 80021bb8 <log>
    80004670:	ffffc097          	auipc	ra,0xffffc
    80004674:	574080e7          	jalr	1396(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004678:	0001d497          	auipc	s1,0x1d
    8000467c:	54048493          	addi	s1,s1,1344 # 80021bb8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004680:	4979                	li	s2,30
    80004682:	a039                	j	80004690 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004684:	85a6                	mv	a1,s1
    80004686:	8526                	mv	a0,s1
    80004688:	ffffe097          	auipc	ra,0xffffe
    8000468c:	d8e080e7          	jalr	-626(ra) # 80002416 <sleep>
    if(log.committing){
    80004690:	50dc                	lw	a5,36(s1)
    80004692:	fbed                	bnez	a5,80004684 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004694:	509c                	lw	a5,32(s1)
    80004696:	0017871b          	addiw	a4,a5,1
    8000469a:	0007069b          	sext.w	a3,a4
    8000469e:	0027179b          	slliw	a5,a4,0x2
    800046a2:	9fb9                	addw	a5,a5,a4
    800046a4:	0017979b          	slliw	a5,a5,0x1
    800046a8:	54d8                	lw	a4,44(s1)
    800046aa:	9fb9                	addw	a5,a5,a4
    800046ac:	00f95963          	bge	s2,a5,800046be <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800046b0:	85a6                	mv	a1,s1
    800046b2:	8526                	mv	a0,s1
    800046b4:	ffffe097          	auipc	ra,0xffffe
    800046b8:	d62080e7          	jalr	-670(ra) # 80002416 <sleep>
    800046bc:	bfd1                	j	80004690 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800046be:	0001d517          	auipc	a0,0x1d
    800046c2:	4fa50513          	addi	a0,a0,1274 # 80021bb8 <log>
    800046c6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	5e2080e7          	jalr	1506(ra) # 80000caa <release>
      break;
    }
  }
}
    800046d0:	60e2                	ld	ra,24(sp)
    800046d2:	6442                	ld	s0,16(sp)
    800046d4:	64a2                	ld	s1,8(sp)
    800046d6:	6902                	ld	s2,0(sp)
    800046d8:	6105                	addi	sp,sp,32
    800046da:	8082                	ret

00000000800046dc <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800046dc:	7139                	addi	sp,sp,-64
    800046de:	fc06                	sd	ra,56(sp)
    800046e0:	f822                	sd	s0,48(sp)
    800046e2:	f426                	sd	s1,40(sp)
    800046e4:	f04a                	sd	s2,32(sp)
    800046e6:	ec4e                	sd	s3,24(sp)
    800046e8:	e852                	sd	s4,16(sp)
    800046ea:	e456                	sd	s5,8(sp)
    800046ec:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800046ee:	0001d497          	auipc	s1,0x1d
    800046f2:	4ca48493          	addi	s1,s1,1226 # 80021bb8 <log>
    800046f6:	8526                	mv	a0,s1
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	4ec080e7          	jalr	1260(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004700:	509c                	lw	a5,32(s1)
    80004702:	37fd                	addiw	a5,a5,-1
    80004704:	0007891b          	sext.w	s2,a5
    80004708:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000470a:	50dc                	lw	a5,36(s1)
    8000470c:	efb9                	bnez	a5,8000476a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000470e:	06091663          	bnez	s2,8000477a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004712:	0001d497          	auipc	s1,0x1d
    80004716:	4a648493          	addi	s1,s1,1190 # 80021bb8 <log>
    8000471a:	4785                	li	a5,1
    8000471c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000471e:	8526                	mv	a0,s1
    80004720:	ffffc097          	auipc	ra,0xffffc
    80004724:	58a080e7          	jalr	1418(ra) # 80000caa <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004728:	54dc                	lw	a5,44(s1)
    8000472a:	06f04763          	bgtz	a5,80004798 <end_op+0xbc>
    acquire(&log.lock);
    8000472e:	0001d497          	auipc	s1,0x1d
    80004732:	48a48493          	addi	s1,s1,1162 # 80021bb8 <log>
    80004736:	8526                	mv	a0,s1
    80004738:	ffffc097          	auipc	ra,0xffffc
    8000473c:	4ac080e7          	jalr	1196(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004740:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004744:	8526                	mv	a0,s1
    80004746:	ffffe097          	auipc	ra,0xffffe
    8000474a:	e76080e7          	jalr	-394(ra) # 800025bc <wakeup>
    release(&log.lock);
    8000474e:	8526                	mv	a0,s1
    80004750:	ffffc097          	auipc	ra,0xffffc
    80004754:	55a080e7          	jalr	1370(ra) # 80000caa <release>
}
    80004758:	70e2                	ld	ra,56(sp)
    8000475a:	7442                	ld	s0,48(sp)
    8000475c:	74a2                	ld	s1,40(sp)
    8000475e:	7902                	ld	s2,32(sp)
    80004760:	69e2                	ld	s3,24(sp)
    80004762:	6a42                	ld	s4,16(sp)
    80004764:	6aa2                	ld	s5,8(sp)
    80004766:	6121                	addi	sp,sp,64
    80004768:	8082                	ret
    panic("log.committing");
    8000476a:	00004517          	auipc	a0,0x4
    8000476e:	f1650513          	addi	a0,a0,-234 # 80008680 <syscalls+0x1f0>
    80004772:	ffffc097          	auipc	ra,0xffffc
    80004776:	dcc080e7          	jalr	-564(ra) # 8000053e <panic>
    wakeup(&log);
    8000477a:	0001d497          	auipc	s1,0x1d
    8000477e:	43e48493          	addi	s1,s1,1086 # 80021bb8 <log>
    80004782:	8526                	mv	a0,s1
    80004784:	ffffe097          	auipc	ra,0xffffe
    80004788:	e38080e7          	jalr	-456(ra) # 800025bc <wakeup>
  release(&log.lock);
    8000478c:	8526                	mv	a0,s1
    8000478e:	ffffc097          	auipc	ra,0xffffc
    80004792:	51c080e7          	jalr	1308(ra) # 80000caa <release>
  if(do_commit){
    80004796:	b7c9                	j	80004758 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004798:	0001da97          	auipc	s5,0x1d
    8000479c:	450a8a93          	addi	s5,s5,1104 # 80021be8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800047a0:	0001da17          	auipc	s4,0x1d
    800047a4:	418a0a13          	addi	s4,s4,1048 # 80021bb8 <log>
    800047a8:	018a2583          	lw	a1,24(s4)
    800047ac:	012585bb          	addw	a1,a1,s2
    800047b0:	2585                	addiw	a1,a1,1
    800047b2:	028a2503          	lw	a0,40(s4)
    800047b6:	fffff097          	auipc	ra,0xfffff
    800047ba:	cd2080e7          	jalr	-814(ra) # 80003488 <bread>
    800047be:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800047c0:	000aa583          	lw	a1,0(s5)
    800047c4:	028a2503          	lw	a0,40(s4)
    800047c8:	fffff097          	auipc	ra,0xfffff
    800047cc:	cc0080e7          	jalr	-832(ra) # 80003488 <bread>
    800047d0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800047d2:	40000613          	li	a2,1024
    800047d6:	05850593          	addi	a1,a0,88
    800047da:	05848513          	addi	a0,s1,88
    800047de:	ffffc097          	auipc	ra,0xffffc
    800047e2:	586080e7          	jalr	1414(ra) # 80000d64 <memmove>
    bwrite(to);  // write the log
    800047e6:	8526                	mv	a0,s1
    800047e8:	fffff097          	auipc	ra,0xfffff
    800047ec:	d92080e7          	jalr	-622(ra) # 8000357a <bwrite>
    brelse(from);
    800047f0:	854e                	mv	a0,s3
    800047f2:	fffff097          	auipc	ra,0xfffff
    800047f6:	dc6080e7          	jalr	-570(ra) # 800035b8 <brelse>
    brelse(to);
    800047fa:	8526                	mv	a0,s1
    800047fc:	fffff097          	auipc	ra,0xfffff
    80004800:	dbc080e7          	jalr	-580(ra) # 800035b8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004804:	2905                	addiw	s2,s2,1
    80004806:	0a91                	addi	s5,s5,4
    80004808:	02ca2783          	lw	a5,44(s4)
    8000480c:	f8f94ee3          	blt	s2,a5,800047a8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004810:	00000097          	auipc	ra,0x0
    80004814:	c6a080e7          	jalr	-918(ra) # 8000447a <write_head>
    install_trans(0); // Now install writes to home locations
    80004818:	4501                	li	a0,0
    8000481a:	00000097          	auipc	ra,0x0
    8000481e:	cda080e7          	jalr	-806(ra) # 800044f4 <install_trans>
    log.lh.n = 0;
    80004822:	0001d797          	auipc	a5,0x1d
    80004826:	3c07a123          	sw	zero,962(a5) # 80021be4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000482a:	00000097          	auipc	ra,0x0
    8000482e:	c50080e7          	jalr	-944(ra) # 8000447a <write_head>
    80004832:	bdf5                	j	8000472e <end_op+0x52>

0000000080004834 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004834:	1101                	addi	sp,sp,-32
    80004836:	ec06                	sd	ra,24(sp)
    80004838:	e822                	sd	s0,16(sp)
    8000483a:	e426                	sd	s1,8(sp)
    8000483c:	e04a                	sd	s2,0(sp)
    8000483e:	1000                	addi	s0,sp,32
    80004840:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004842:	0001d917          	auipc	s2,0x1d
    80004846:	37690913          	addi	s2,s2,886 # 80021bb8 <log>
    8000484a:	854a                	mv	a0,s2
    8000484c:	ffffc097          	auipc	ra,0xffffc
    80004850:	398080e7          	jalr	920(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004854:	02c92603          	lw	a2,44(s2)
    80004858:	47f5                	li	a5,29
    8000485a:	06c7c563          	blt	a5,a2,800048c4 <log_write+0x90>
    8000485e:	0001d797          	auipc	a5,0x1d
    80004862:	3767a783          	lw	a5,886(a5) # 80021bd4 <log+0x1c>
    80004866:	37fd                	addiw	a5,a5,-1
    80004868:	04f65e63          	bge	a2,a5,800048c4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000486c:	0001d797          	auipc	a5,0x1d
    80004870:	36c7a783          	lw	a5,876(a5) # 80021bd8 <log+0x20>
    80004874:	06f05063          	blez	a5,800048d4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004878:	4781                	li	a5,0
    8000487a:	06c05563          	blez	a2,800048e4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000487e:	44cc                	lw	a1,12(s1)
    80004880:	0001d717          	auipc	a4,0x1d
    80004884:	36870713          	addi	a4,a4,872 # 80021be8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004888:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000488a:	4314                	lw	a3,0(a4)
    8000488c:	04b68c63          	beq	a3,a1,800048e4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004890:	2785                	addiw	a5,a5,1
    80004892:	0711                	addi	a4,a4,4
    80004894:	fef61be3          	bne	a2,a5,8000488a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004898:	0621                	addi	a2,a2,8
    8000489a:	060a                	slli	a2,a2,0x2
    8000489c:	0001d797          	auipc	a5,0x1d
    800048a0:	31c78793          	addi	a5,a5,796 # 80021bb8 <log>
    800048a4:	963e                	add	a2,a2,a5
    800048a6:	44dc                	lw	a5,12(s1)
    800048a8:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800048aa:	8526                	mv	a0,s1
    800048ac:	fffff097          	auipc	ra,0xfffff
    800048b0:	daa080e7          	jalr	-598(ra) # 80003656 <bpin>
    log.lh.n++;
    800048b4:	0001d717          	auipc	a4,0x1d
    800048b8:	30470713          	addi	a4,a4,772 # 80021bb8 <log>
    800048bc:	575c                	lw	a5,44(a4)
    800048be:	2785                	addiw	a5,a5,1
    800048c0:	d75c                	sw	a5,44(a4)
    800048c2:	a835                	j	800048fe <log_write+0xca>
    panic("too big a transaction");
    800048c4:	00004517          	auipc	a0,0x4
    800048c8:	dcc50513          	addi	a0,a0,-564 # 80008690 <syscalls+0x200>
    800048cc:	ffffc097          	auipc	ra,0xffffc
    800048d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800048d4:	00004517          	auipc	a0,0x4
    800048d8:	dd450513          	addi	a0,a0,-556 # 800086a8 <syscalls+0x218>
    800048dc:	ffffc097          	auipc	ra,0xffffc
    800048e0:	c62080e7          	jalr	-926(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800048e4:	00878713          	addi	a4,a5,8
    800048e8:	00271693          	slli	a3,a4,0x2
    800048ec:	0001d717          	auipc	a4,0x1d
    800048f0:	2cc70713          	addi	a4,a4,716 # 80021bb8 <log>
    800048f4:	9736                	add	a4,a4,a3
    800048f6:	44d4                	lw	a3,12(s1)
    800048f8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800048fa:	faf608e3          	beq	a2,a5,800048aa <log_write+0x76>
  }
  release(&log.lock);
    800048fe:	0001d517          	auipc	a0,0x1d
    80004902:	2ba50513          	addi	a0,a0,698 # 80021bb8 <log>
    80004906:	ffffc097          	auipc	ra,0xffffc
    8000490a:	3a4080e7          	jalr	932(ra) # 80000caa <release>
}
    8000490e:	60e2                	ld	ra,24(sp)
    80004910:	6442                	ld	s0,16(sp)
    80004912:	64a2                	ld	s1,8(sp)
    80004914:	6902                	ld	s2,0(sp)
    80004916:	6105                	addi	sp,sp,32
    80004918:	8082                	ret

000000008000491a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000491a:	1101                	addi	sp,sp,-32
    8000491c:	ec06                	sd	ra,24(sp)
    8000491e:	e822                	sd	s0,16(sp)
    80004920:	e426                	sd	s1,8(sp)
    80004922:	e04a                	sd	s2,0(sp)
    80004924:	1000                	addi	s0,sp,32
    80004926:	84aa                	mv	s1,a0
    80004928:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000492a:	00004597          	auipc	a1,0x4
    8000492e:	d9e58593          	addi	a1,a1,-610 # 800086c8 <syscalls+0x238>
    80004932:	0521                	addi	a0,a0,8
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	220080e7          	jalr	544(ra) # 80000b54 <initlock>
  lk->name = name;
    8000493c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004940:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004944:	0204a423          	sw	zero,40(s1)
}
    80004948:	60e2                	ld	ra,24(sp)
    8000494a:	6442                	ld	s0,16(sp)
    8000494c:	64a2                	ld	s1,8(sp)
    8000494e:	6902                	ld	s2,0(sp)
    80004950:	6105                	addi	sp,sp,32
    80004952:	8082                	ret

0000000080004954 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004954:	1101                	addi	sp,sp,-32
    80004956:	ec06                	sd	ra,24(sp)
    80004958:	e822                	sd	s0,16(sp)
    8000495a:	e426                	sd	s1,8(sp)
    8000495c:	e04a                	sd	s2,0(sp)
    8000495e:	1000                	addi	s0,sp,32
    80004960:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004962:	00850913          	addi	s2,a0,8
    80004966:	854a                	mv	a0,s2
    80004968:	ffffc097          	auipc	ra,0xffffc
    8000496c:	27c080e7          	jalr	636(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004970:	409c                	lw	a5,0(s1)
    80004972:	cb89                	beqz	a5,80004984 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004974:	85ca                	mv	a1,s2
    80004976:	8526                	mv	a0,s1
    80004978:	ffffe097          	auipc	ra,0xffffe
    8000497c:	a9e080e7          	jalr	-1378(ra) # 80002416 <sleep>
  while (lk->locked) {
    80004980:	409c                	lw	a5,0(s1)
    80004982:	fbed                	bnez	a5,80004974 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004984:	4785                	li	a5,1
    80004986:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004988:	ffffd097          	auipc	ra,0xffffd
    8000498c:	40e080e7          	jalr	1038(ra) # 80001d96 <myproc>
    80004990:	591c                	lw	a5,48(a0)
    80004992:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004994:	854a                	mv	a0,s2
    80004996:	ffffc097          	auipc	ra,0xffffc
    8000499a:	314080e7          	jalr	788(ra) # 80000caa <release>
}
    8000499e:	60e2                	ld	ra,24(sp)
    800049a0:	6442                	ld	s0,16(sp)
    800049a2:	64a2                	ld	s1,8(sp)
    800049a4:	6902                	ld	s2,0(sp)
    800049a6:	6105                	addi	sp,sp,32
    800049a8:	8082                	ret

00000000800049aa <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800049aa:	1101                	addi	sp,sp,-32
    800049ac:	ec06                	sd	ra,24(sp)
    800049ae:	e822                	sd	s0,16(sp)
    800049b0:	e426                	sd	s1,8(sp)
    800049b2:	e04a                	sd	s2,0(sp)
    800049b4:	1000                	addi	s0,sp,32
    800049b6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049b8:	00850913          	addi	s2,a0,8
    800049bc:	854a                	mv	a0,s2
    800049be:	ffffc097          	auipc	ra,0xffffc
    800049c2:	226080e7          	jalr	550(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800049c6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049ca:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800049ce:	8526                	mv	a0,s1
    800049d0:	ffffe097          	auipc	ra,0xffffe
    800049d4:	bec080e7          	jalr	-1044(ra) # 800025bc <wakeup>
  release(&lk->lk);
    800049d8:	854a                	mv	a0,s2
    800049da:	ffffc097          	auipc	ra,0xffffc
    800049de:	2d0080e7          	jalr	720(ra) # 80000caa <release>
}
    800049e2:	60e2                	ld	ra,24(sp)
    800049e4:	6442                	ld	s0,16(sp)
    800049e6:	64a2                	ld	s1,8(sp)
    800049e8:	6902                	ld	s2,0(sp)
    800049ea:	6105                	addi	sp,sp,32
    800049ec:	8082                	ret

00000000800049ee <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800049ee:	7179                	addi	sp,sp,-48
    800049f0:	f406                	sd	ra,40(sp)
    800049f2:	f022                	sd	s0,32(sp)
    800049f4:	ec26                	sd	s1,24(sp)
    800049f6:	e84a                	sd	s2,16(sp)
    800049f8:	e44e                	sd	s3,8(sp)
    800049fa:	1800                	addi	s0,sp,48
    800049fc:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800049fe:	00850913          	addi	s2,a0,8
    80004a02:	854a                	mv	a0,s2
    80004a04:	ffffc097          	auipc	ra,0xffffc
    80004a08:	1e0080e7          	jalr	480(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a0c:	409c                	lw	a5,0(s1)
    80004a0e:	ef99                	bnez	a5,80004a2c <holdingsleep+0x3e>
    80004a10:	4481                	li	s1,0
  release(&lk->lk);
    80004a12:	854a                	mv	a0,s2
    80004a14:	ffffc097          	auipc	ra,0xffffc
    80004a18:	296080e7          	jalr	662(ra) # 80000caa <release>
  return r;
}
    80004a1c:	8526                	mv	a0,s1
    80004a1e:	70a2                	ld	ra,40(sp)
    80004a20:	7402                	ld	s0,32(sp)
    80004a22:	64e2                	ld	s1,24(sp)
    80004a24:	6942                	ld	s2,16(sp)
    80004a26:	69a2                	ld	s3,8(sp)
    80004a28:	6145                	addi	sp,sp,48
    80004a2a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a2c:	0284a983          	lw	s3,40(s1)
    80004a30:	ffffd097          	auipc	ra,0xffffd
    80004a34:	366080e7          	jalr	870(ra) # 80001d96 <myproc>
    80004a38:	5904                	lw	s1,48(a0)
    80004a3a:	413484b3          	sub	s1,s1,s3
    80004a3e:	0014b493          	seqz	s1,s1
    80004a42:	bfc1                	j	80004a12 <holdingsleep+0x24>

0000000080004a44 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a44:	1141                	addi	sp,sp,-16
    80004a46:	e406                	sd	ra,8(sp)
    80004a48:	e022                	sd	s0,0(sp)
    80004a4a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a4c:	00004597          	auipc	a1,0x4
    80004a50:	c8c58593          	addi	a1,a1,-884 # 800086d8 <syscalls+0x248>
    80004a54:	0001d517          	auipc	a0,0x1d
    80004a58:	2ac50513          	addi	a0,a0,684 # 80021d00 <ftable>
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	0f8080e7          	jalr	248(ra) # 80000b54 <initlock>
}
    80004a64:	60a2                	ld	ra,8(sp)
    80004a66:	6402                	ld	s0,0(sp)
    80004a68:	0141                	addi	sp,sp,16
    80004a6a:	8082                	ret

0000000080004a6c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a6c:	1101                	addi	sp,sp,-32
    80004a6e:	ec06                	sd	ra,24(sp)
    80004a70:	e822                	sd	s0,16(sp)
    80004a72:	e426                	sd	s1,8(sp)
    80004a74:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a76:	0001d517          	auipc	a0,0x1d
    80004a7a:	28a50513          	addi	a0,a0,650 # 80021d00 <ftable>
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	166080e7          	jalr	358(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a86:	0001d497          	auipc	s1,0x1d
    80004a8a:	29248493          	addi	s1,s1,658 # 80021d18 <ftable+0x18>
    80004a8e:	0001e717          	auipc	a4,0x1e
    80004a92:	22a70713          	addi	a4,a4,554 # 80022cb8 <ftable+0xfb8>
    if(f->ref == 0){
    80004a96:	40dc                	lw	a5,4(s1)
    80004a98:	cf99                	beqz	a5,80004ab6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a9a:	02848493          	addi	s1,s1,40
    80004a9e:	fee49ce3          	bne	s1,a4,80004a96 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004aa2:	0001d517          	auipc	a0,0x1d
    80004aa6:	25e50513          	addi	a0,a0,606 # 80021d00 <ftable>
    80004aaa:	ffffc097          	auipc	ra,0xffffc
    80004aae:	200080e7          	jalr	512(ra) # 80000caa <release>
  return 0;
    80004ab2:	4481                	li	s1,0
    80004ab4:	a819                	j	80004aca <filealloc+0x5e>
      f->ref = 1;
    80004ab6:	4785                	li	a5,1
    80004ab8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004aba:	0001d517          	auipc	a0,0x1d
    80004abe:	24650513          	addi	a0,a0,582 # 80021d00 <ftable>
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	1e8080e7          	jalr	488(ra) # 80000caa <release>
}
    80004aca:	8526                	mv	a0,s1
    80004acc:	60e2                	ld	ra,24(sp)
    80004ace:	6442                	ld	s0,16(sp)
    80004ad0:	64a2                	ld	s1,8(sp)
    80004ad2:	6105                	addi	sp,sp,32
    80004ad4:	8082                	ret

0000000080004ad6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004ad6:	1101                	addi	sp,sp,-32
    80004ad8:	ec06                	sd	ra,24(sp)
    80004ada:	e822                	sd	s0,16(sp)
    80004adc:	e426                	sd	s1,8(sp)
    80004ade:	1000                	addi	s0,sp,32
    80004ae0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004ae2:	0001d517          	auipc	a0,0x1d
    80004ae6:	21e50513          	addi	a0,a0,542 # 80021d00 <ftable>
    80004aea:	ffffc097          	auipc	ra,0xffffc
    80004aee:	0fa080e7          	jalr	250(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004af2:	40dc                	lw	a5,4(s1)
    80004af4:	02f05263          	blez	a5,80004b18 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004af8:	2785                	addiw	a5,a5,1
    80004afa:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004afc:	0001d517          	auipc	a0,0x1d
    80004b00:	20450513          	addi	a0,a0,516 # 80021d00 <ftable>
    80004b04:	ffffc097          	auipc	ra,0xffffc
    80004b08:	1a6080e7          	jalr	422(ra) # 80000caa <release>
  return f;
}
    80004b0c:	8526                	mv	a0,s1
    80004b0e:	60e2                	ld	ra,24(sp)
    80004b10:	6442                	ld	s0,16(sp)
    80004b12:	64a2                	ld	s1,8(sp)
    80004b14:	6105                	addi	sp,sp,32
    80004b16:	8082                	ret
    panic("filedup");
    80004b18:	00004517          	auipc	a0,0x4
    80004b1c:	bc850513          	addi	a0,a0,-1080 # 800086e0 <syscalls+0x250>
    80004b20:	ffffc097          	auipc	ra,0xffffc
    80004b24:	a1e080e7          	jalr	-1506(ra) # 8000053e <panic>

0000000080004b28 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b28:	7139                	addi	sp,sp,-64
    80004b2a:	fc06                	sd	ra,56(sp)
    80004b2c:	f822                	sd	s0,48(sp)
    80004b2e:	f426                	sd	s1,40(sp)
    80004b30:	f04a                	sd	s2,32(sp)
    80004b32:	ec4e                	sd	s3,24(sp)
    80004b34:	e852                	sd	s4,16(sp)
    80004b36:	e456                	sd	s5,8(sp)
    80004b38:	0080                	addi	s0,sp,64
    80004b3a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b3c:	0001d517          	auipc	a0,0x1d
    80004b40:	1c450513          	addi	a0,a0,452 # 80021d00 <ftable>
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	0a0080e7          	jalr	160(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b4c:	40dc                	lw	a5,4(s1)
    80004b4e:	06f05163          	blez	a5,80004bb0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b52:	37fd                	addiw	a5,a5,-1
    80004b54:	0007871b          	sext.w	a4,a5
    80004b58:	c0dc                	sw	a5,4(s1)
    80004b5a:	06e04363          	bgtz	a4,80004bc0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b5e:	0004a903          	lw	s2,0(s1)
    80004b62:	0094ca83          	lbu	s5,9(s1)
    80004b66:	0104ba03          	ld	s4,16(s1)
    80004b6a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b6e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b72:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b76:	0001d517          	auipc	a0,0x1d
    80004b7a:	18a50513          	addi	a0,a0,394 # 80021d00 <ftable>
    80004b7e:	ffffc097          	auipc	ra,0xffffc
    80004b82:	12c080e7          	jalr	300(ra) # 80000caa <release>

  if(ff.type == FD_PIPE){
    80004b86:	4785                	li	a5,1
    80004b88:	04f90d63          	beq	s2,a5,80004be2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b8c:	3979                	addiw	s2,s2,-2
    80004b8e:	4785                	li	a5,1
    80004b90:	0527e063          	bltu	a5,s2,80004bd0 <fileclose+0xa8>
    begin_op();
    80004b94:	00000097          	auipc	ra,0x0
    80004b98:	ac8080e7          	jalr	-1336(ra) # 8000465c <begin_op>
    iput(ff.ip);
    80004b9c:	854e                	mv	a0,s3
    80004b9e:	fffff097          	auipc	ra,0xfffff
    80004ba2:	2a6080e7          	jalr	678(ra) # 80003e44 <iput>
    end_op();
    80004ba6:	00000097          	auipc	ra,0x0
    80004baa:	b36080e7          	jalr	-1226(ra) # 800046dc <end_op>
    80004bae:	a00d                	j	80004bd0 <fileclose+0xa8>
    panic("fileclose");
    80004bb0:	00004517          	auipc	a0,0x4
    80004bb4:	b3850513          	addi	a0,a0,-1224 # 800086e8 <syscalls+0x258>
    80004bb8:	ffffc097          	auipc	ra,0xffffc
    80004bbc:	986080e7          	jalr	-1658(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004bc0:	0001d517          	auipc	a0,0x1d
    80004bc4:	14050513          	addi	a0,a0,320 # 80021d00 <ftable>
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	0e2080e7          	jalr	226(ra) # 80000caa <release>
  }
}
    80004bd0:	70e2                	ld	ra,56(sp)
    80004bd2:	7442                	ld	s0,48(sp)
    80004bd4:	74a2                	ld	s1,40(sp)
    80004bd6:	7902                	ld	s2,32(sp)
    80004bd8:	69e2                	ld	s3,24(sp)
    80004bda:	6a42                	ld	s4,16(sp)
    80004bdc:	6aa2                	ld	s5,8(sp)
    80004bde:	6121                	addi	sp,sp,64
    80004be0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004be2:	85d6                	mv	a1,s5
    80004be4:	8552                	mv	a0,s4
    80004be6:	00000097          	auipc	ra,0x0
    80004bea:	34c080e7          	jalr	844(ra) # 80004f32 <pipeclose>
    80004bee:	b7cd                	j	80004bd0 <fileclose+0xa8>

0000000080004bf0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004bf0:	715d                	addi	sp,sp,-80
    80004bf2:	e486                	sd	ra,72(sp)
    80004bf4:	e0a2                	sd	s0,64(sp)
    80004bf6:	fc26                	sd	s1,56(sp)
    80004bf8:	f84a                	sd	s2,48(sp)
    80004bfa:	f44e                	sd	s3,40(sp)
    80004bfc:	0880                	addi	s0,sp,80
    80004bfe:	84aa                	mv	s1,a0
    80004c00:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c02:	ffffd097          	auipc	ra,0xffffd
    80004c06:	194080e7          	jalr	404(ra) # 80001d96 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c0a:	409c                	lw	a5,0(s1)
    80004c0c:	37f9                	addiw	a5,a5,-2
    80004c0e:	4705                	li	a4,1
    80004c10:	04f76763          	bltu	a4,a5,80004c5e <filestat+0x6e>
    80004c14:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c16:	6c88                	ld	a0,24(s1)
    80004c18:	fffff097          	auipc	ra,0xfffff
    80004c1c:	072080e7          	jalr	114(ra) # 80003c8a <ilock>
    stati(f->ip, &st);
    80004c20:	fb840593          	addi	a1,s0,-72
    80004c24:	6c88                	ld	a0,24(s1)
    80004c26:	fffff097          	auipc	ra,0xfffff
    80004c2a:	2ee080e7          	jalr	750(ra) # 80003f14 <stati>
    iunlock(f->ip);
    80004c2e:	6c88                	ld	a0,24(s1)
    80004c30:	fffff097          	auipc	ra,0xfffff
    80004c34:	11c080e7          	jalr	284(ra) # 80003d4c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c38:	46e1                	li	a3,24
    80004c3a:	fb840613          	addi	a2,s0,-72
    80004c3e:	85ce                	mv	a1,s3
    80004c40:	07093503          	ld	a0,112(s2)
    80004c44:	ffffd097          	auipc	ra,0xffffd
    80004c48:	a52080e7          	jalr	-1454(ra) # 80001696 <copyout>
    80004c4c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c50:	60a6                	ld	ra,72(sp)
    80004c52:	6406                	ld	s0,64(sp)
    80004c54:	74e2                	ld	s1,56(sp)
    80004c56:	7942                	ld	s2,48(sp)
    80004c58:	79a2                	ld	s3,40(sp)
    80004c5a:	6161                	addi	sp,sp,80
    80004c5c:	8082                	ret
  return -1;
    80004c5e:	557d                	li	a0,-1
    80004c60:	bfc5                	j	80004c50 <filestat+0x60>

0000000080004c62 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c62:	7179                	addi	sp,sp,-48
    80004c64:	f406                	sd	ra,40(sp)
    80004c66:	f022                	sd	s0,32(sp)
    80004c68:	ec26                	sd	s1,24(sp)
    80004c6a:	e84a                	sd	s2,16(sp)
    80004c6c:	e44e                	sd	s3,8(sp)
    80004c6e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c70:	00854783          	lbu	a5,8(a0)
    80004c74:	c3d5                	beqz	a5,80004d18 <fileread+0xb6>
    80004c76:	84aa                	mv	s1,a0
    80004c78:	89ae                	mv	s3,a1
    80004c7a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c7c:	411c                	lw	a5,0(a0)
    80004c7e:	4705                	li	a4,1
    80004c80:	04e78963          	beq	a5,a4,80004cd2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c84:	470d                	li	a4,3
    80004c86:	04e78d63          	beq	a5,a4,80004ce0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c8a:	4709                	li	a4,2
    80004c8c:	06e79e63          	bne	a5,a4,80004d08 <fileread+0xa6>
    ilock(f->ip);
    80004c90:	6d08                	ld	a0,24(a0)
    80004c92:	fffff097          	auipc	ra,0xfffff
    80004c96:	ff8080e7          	jalr	-8(ra) # 80003c8a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c9a:	874a                	mv	a4,s2
    80004c9c:	5094                	lw	a3,32(s1)
    80004c9e:	864e                	mv	a2,s3
    80004ca0:	4585                	li	a1,1
    80004ca2:	6c88                	ld	a0,24(s1)
    80004ca4:	fffff097          	auipc	ra,0xfffff
    80004ca8:	29a080e7          	jalr	666(ra) # 80003f3e <readi>
    80004cac:	892a                	mv	s2,a0
    80004cae:	00a05563          	blez	a0,80004cb8 <fileread+0x56>
      f->off += r;
    80004cb2:	509c                	lw	a5,32(s1)
    80004cb4:	9fa9                	addw	a5,a5,a0
    80004cb6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004cb8:	6c88                	ld	a0,24(s1)
    80004cba:	fffff097          	auipc	ra,0xfffff
    80004cbe:	092080e7          	jalr	146(ra) # 80003d4c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004cc2:	854a                	mv	a0,s2
    80004cc4:	70a2                	ld	ra,40(sp)
    80004cc6:	7402                	ld	s0,32(sp)
    80004cc8:	64e2                	ld	s1,24(sp)
    80004cca:	6942                	ld	s2,16(sp)
    80004ccc:	69a2                	ld	s3,8(sp)
    80004cce:	6145                	addi	sp,sp,48
    80004cd0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004cd2:	6908                	ld	a0,16(a0)
    80004cd4:	00000097          	auipc	ra,0x0
    80004cd8:	3c8080e7          	jalr	968(ra) # 8000509c <piperead>
    80004cdc:	892a                	mv	s2,a0
    80004cde:	b7d5                	j	80004cc2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004ce0:	02451783          	lh	a5,36(a0)
    80004ce4:	03079693          	slli	a3,a5,0x30
    80004ce8:	92c1                	srli	a3,a3,0x30
    80004cea:	4725                	li	a4,9
    80004cec:	02d76863          	bltu	a4,a3,80004d1c <fileread+0xba>
    80004cf0:	0792                	slli	a5,a5,0x4
    80004cf2:	0001d717          	auipc	a4,0x1d
    80004cf6:	f6e70713          	addi	a4,a4,-146 # 80021c60 <devsw>
    80004cfa:	97ba                	add	a5,a5,a4
    80004cfc:	639c                	ld	a5,0(a5)
    80004cfe:	c38d                	beqz	a5,80004d20 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d00:	4505                	li	a0,1
    80004d02:	9782                	jalr	a5
    80004d04:	892a                	mv	s2,a0
    80004d06:	bf75                	j	80004cc2 <fileread+0x60>
    panic("fileread");
    80004d08:	00004517          	auipc	a0,0x4
    80004d0c:	9f050513          	addi	a0,a0,-1552 # 800086f8 <syscalls+0x268>
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	82e080e7          	jalr	-2002(ra) # 8000053e <panic>
    return -1;
    80004d18:	597d                	li	s2,-1
    80004d1a:	b765                	j	80004cc2 <fileread+0x60>
      return -1;
    80004d1c:	597d                	li	s2,-1
    80004d1e:	b755                	j	80004cc2 <fileread+0x60>
    80004d20:	597d                	li	s2,-1
    80004d22:	b745                	j	80004cc2 <fileread+0x60>

0000000080004d24 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d24:	715d                	addi	sp,sp,-80
    80004d26:	e486                	sd	ra,72(sp)
    80004d28:	e0a2                	sd	s0,64(sp)
    80004d2a:	fc26                	sd	s1,56(sp)
    80004d2c:	f84a                	sd	s2,48(sp)
    80004d2e:	f44e                	sd	s3,40(sp)
    80004d30:	f052                	sd	s4,32(sp)
    80004d32:	ec56                	sd	s5,24(sp)
    80004d34:	e85a                	sd	s6,16(sp)
    80004d36:	e45e                	sd	s7,8(sp)
    80004d38:	e062                	sd	s8,0(sp)
    80004d3a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d3c:	00954783          	lbu	a5,9(a0)
    80004d40:	10078663          	beqz	a5,80004e4c <filewrite+0x128>
    80004d44:	892a                	mv	s2,a0
    80004d46:	8aae                	mv	s5,a1
    80004d48:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d4a:	411c                	lw	a5,0(a0)
    80004d4c:	4705                	li	a4,1
    80004d4e:	02e78263          	beq	a5,a4,80004d72 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d52:	470d                	li	a4,3
    80004d54:	02e78663          	beq	a5,a4,80004d80 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d58:	4709                	li	a4,2
    80004d5a:	0ee79163          	bne	a5,a4,80004e3c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d5e:	0ac05d63          	blez	a2,80004e18 <filewrite+0xf4>
    int i = 0;
    80004d62:	4981                	li	s3,0
    80004d64:	6b05                	lui	s6,0x1
    80004d66:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004d6a:	6b85                	lui	s7,0x1
    80004d6c:	c00b8b9b          	addiw	s7,s7,-1024
    80004d70:	a861                	j	80004e08 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d72:	6908                	ld	a0,16(a0)
    80004d74:	00000097          	auipc	ra,0x0
    80004d78:	22e080e7          	jalr	558(ra) # 80004fa2 <pipewrite>
    80004d7c:	8a2a                	mv	s4,a0
    80004d7e:	a045                	j	80004e1e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d80:	02451783          	lh	a5,36(a0)
    80004d84:	03079693          	slli	a3,a5,0x30
    80004d88:	92c1                	srli	a3,a3,0x30
    80004d8a:	4725                	li	a4,9
    80004d8c:	0cd76263          	bltu	a4,a3,80004e50 <filewrite+0x12c>
    80004d90:	0792                	slli	a5,a5,0x4
    80004d92:	0001d717          	auipc	a4,0x1d
    80004d96:	ece70713          	addi	a4,a4,-306 # 80021c60 <devsw>
    80004d9a:	97ba                	add	a5,a5,a4
    80004d9c:	679c                	ld	a5,8(a5)
    80004d9e:	cbdd                	beqz	a5,80004e54 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004da0:	4505                	li	a0,1
    80004da2:	9782                	jalr	a5
    80004da4:	8a2a                	mv	s4,a0
    80004da6:	a8a5                	j	80004e1e <filewrite+0xfa>
    80004da8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004dac:	00000097          	auipc	ra,0x0
    80004db0:	8b0080e7          	jalr	-1872(ra) # 8000465c <begin_op>
      ilock(f->ip);
    80004db4:	01893503          	ld	a0,24(s2)
    80004db8:	fffff097          	auipc	ra,0xfffff
    80004dbc:	ed2080e7          	jalr	-302(ra) # 80003c8a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004dc0:	8762                	mv	a4,s8
    80004dc2:	02092683          	lw	a3,32(s2)
    80004dc6:	01598633          	add	a2,s3,s5
    80004dca:	4585                	li	a1,1
    80004dcc:	01893503          	ld	a0,24(s2)
    80004dd0:	fffff097          	auipc	ra,0xfffff
    80004dd4:	266080e7          	jalr	614(ra) # 80004036 <writei>
    80004dd8:	84aa                	mv	s1,a0
    80004dda:	00a05763          	blez	a0,80004de8 <filewrite+0xc4>
        f->off += r;
    80004dde:	02092783          	lw	a5,32(s2)
    80004de2:	9fa9                	addw	a5,a5,a0
    80004de4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004de8:	01893503          	ld	a0,24(s2)
    80004dec:	fffff097          	auipc	ra,0xfffff
    80004df0:	f60080e7          	jalr	-160(ra) # 80003d4c <iunlock>
      end_op();
    80004df4:	00000097          	auipc	ra,0x0
    80004df8:	8e8080e7          	jalr	-1816(ra) # 800046dc <end_op>

      if(r != n1){
    80004dfc:	009c1f63          	bne	s8,s1,80004e1a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e00:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e04:	0149db63          	bge	s3,s4,80004e1a <filewrite+0xf6>
      int n1 = n - i;
    80004e08:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004e0c:	84be                	mv	s1,a5
    80004e0e:	2781                	sext.w	a5,a5
    80004e10:	f8fb5ce3          	bge	s6,a5,80004da8 <filewrite+0x84>
    80004e14:	84de                	mv	s1,s7
    80004e16:	bf49                	j	80004da8 <filewrite+0x84>
    int i = 0;
    80004e18:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e1a:	013a1f63          	bne	s4,s3,80004e38 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e1e:	8552                	mv	a0,s4
    80004e20:	60a6                	ld	ra,72(sp)
    80004e22:	6406                	ld	s0,64(sp)
    80004e24:	74e2                	ld	s1,56(sp)
    80004e26:	7942                	ld	s2,48(sp)
    80004e28:	79a2                	ld	s3,40(sp)
    80004e2a:	7a02                	ld	s4,32(sp)
    80004e2c:	6ae2                	ld	s5,24(sp)
    80004e2e:	6b42                	ld	s6,16(sp)
    80004e30:	6ba2                	ld	s7,8(sp)
    80004e32:	6c02                	ld	s8,0(sp)
    80004e34:	6161                	addi	sp,sp,80
    80004e36:	8082                	ret
    ret = (i == n ? n : -1);
    80004e38:	5a7d                	li	s4,-1
    80004e3a:	b7d5                	j	80004e1e <filewrite+0xfa>
    panic("filewrite");
    80004e3c:	00004517          	auipc	a0,0x4
    80004e40:	8cc50513          	addi	a0,a0,-1844 # 80008708 <syscalls+0x278>
    80004e44:	ffffb097          	auipc	ra,0xffffb
    80004e48:	6fa080e7          	jalr	1786(ra) # 8000053e <panic>
    return -1;
    80004e4c:	5a7d                	li	s4,-1
    80004e4e:	bfc1                	j	80004e1e <filewrite+0xfa>
      return -1;
    80004e50:	5a7d                	li	s4,-1
    80004e52:	b7f1                	j	80004e1e <filewrite+0xfa>
    80004e54:	5a7d                	li	s4,-1
    80004e56:	b7e1                	j	80004e1e <filewrite+0xfa>

0000000080004e58 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e58:	7179                	addi	sp,sp,-48
    80004e5a:	f406                	sd	ra,40(sp)
    80004e5c:	f022                	sd	s0,32(sp)
    80004e5e:	ec26                	sd	s1,24(sp)
    80004e60:	e84a                	sd	s2,16(sp)
    80004e62:	e44e                	sd	s3,8(sp)
    80004e64:	e052                	sd	s4,0(sp)
    80004e66:	1800                	addi	s0,sp,48
    80004e68:	84aa                	mv	s1,a0
    80004e6a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e6c:	0005b023          	sd	zero,0(a1)
    80004e70:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e74:	00000097          	auipc	ra,0x0
    80004e78:	bf8080e7          	jalr	-1032(ra) # 80004a6c <filealloc>
    80004e7c:	e088                	sd	a0,0(s1)
    80004e7e:	c551                	beqz	a0,80004f0a <pipealloc+0xb2>
    80004e80:	00000097          	auipc	ra,0x0
    80004e84:	bec080e7          	jalr	-1044(ra) # 80004a6c <filealloc>
    80004e88:	00aa3023          	sd	a0,0(s4)
    80004e8c:	c92d                	beqz	a0,80004efe <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e8e:	ffffc097          	auipc	ra,0xffffc
    80004e92:	c66080e7          	jalr	-922(ra) # 80000af4 <kalloc>
    80004e96:	892a                	mv	s2,a0
    80004e98:	c125                	beqz	a0,80004ef8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e9a:	4985                	li	s3,1
    80004e9c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ea0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ea4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ea8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004eac:	00004597          	auipc	a1,0x4
    80004eb0:	86c58593          	addi	a1,a1,-1940 # 80008718 <syscalls+0x288>
    80004eb4:	ffffc097          	auipc	ra,0xffffc
    80004eb8:	ca0080e7          	jalr	-864(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004ebc:	609c                	ld	a5,0(s1)
    80004ebe:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ec2:	609c                	ld	a5,0(s1)
    80004ec4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ec8:	609c                	ld	a5,0(s1)
    80004eca:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ece:	609c                	ld	a5,0(s1)
    80004ed0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ed4:	000a3783          	ld	a5,0(s4)
    80004ed8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004edc:	000a3783          	ld	a5,0(s4)
    80004ee0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ee4:	000a3783          	ld	a5,0(s4)
    80004ee8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004eec:	000a3783          	ld	a5,0(s4)
    80004ef0:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ef4:	4501                	li	a0,0
    80004ef6:	a025                	j	80004f1e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ef8:	6088                	ld	a0,0(s1)
    80004efa:	e501                	bnez	a0,80004f02 <pipealloc+0xaa>
    80004efc:	a039                	j	80004f0a <pipealloc+0xb2>
    80004efe:	6088                	ld	a0,0(s1)
    80004f00:	c51d                	beqz	a0,80004f2e <pipealloc+0xd6>
    fileclose(*f0);
    80004f02:	00000097          	auipc	ra,0x0
    80004f06:	c26080e7          	jalr	-986(ra) # 80004b28 <fileclose>
  if(*f1)
    80004f0a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f0e:	557d                	li	a0,-1
  if(*f1)
    80004f10:	c799                	beqz	a5,80004f1e <pipealloc+0xc6>
    fileclose(*f1);
    80004f12:	853e                	mv	a0,a5
    80004f14:	00000097          	auipc	ra,0x0
    80004f18:	c14080e7          	jalr	-1004(ra) # 80004b28 <fileclose>
  return -1;
    80004f1c:	557d                	li	a0,-1
}
    80004f1e:	70a2                	ld	ra,40(sp)
    80004f20:	7402                	ld	s0,32(sp)
    80004f22:	64e2                	ld	s1,24(sp)
    80004f24:	6942                	ld	s2,16(sp)
    80004f26:	69a2                	ld	s3,8(sp)
    80004f28:	6a02                	ld	s4,0(sp)
    80004f2a:	6145                	addi	sp,sp,48
    80004f2c:	8082                	ret
  return -1;
    80004f2e:	557d                	li	a0,-1
    80004f30:	b7fd                	j	80004f1e <pipealloc+0xc6>

0000000080004f32 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f32:	1101                	addi	sp,sp,-32
    80004f34:	ec06                	sd	ra,24(sp)
    80004f36:	e822                	sd	s0,16(sp)
    80004f38:	e426                	sd	s1,8(sp)
    80004f3a:	e04a                	sd	s2,0(sp)
    80004f3c:	1000                	addi	s0,sp,32
    80004f3e:	84aa                	mv	s1,a0
    80004f40:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f42:	ffffc097          	auipc	ra,0xffffc
    80004f46:	ca2080e7          	jalr	-862(ra) # 80000be4 <acquire>
  if(writable){
    80004f4a:	02090d63          	beqz	s2,80004f84 <pipeclose+0x52>
    pi->writeopen = 0;
    80004f4e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f52:	21848513          	addi	a0,s1,536
    80004f56:	ffffd097          	auipc	ra,0xffffd
    80004f5a:	666080e7          	jalr	1638(ra) # 800025bc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f5e:	2204b783          	ld	a5,544(s1)
    80004f62:	eb95                	bnez	a5,80004f96 <pipeclose+0x64>
    release(&pi->lock);
    80004f64:	8526                	mv	a0,s1
    80004f66:	ffffc097          	auipc	ra,0xffffc
    80004f6a:	d44080e7          	jalr	-700(ra) # 80000caa <release>
    kfree((char*)pi);
    80004f6e:	8526                	mv	a0,s1
    80004f70:	ffffc097          	auipc	ra,0xffffc
    80004f74:	a88080e7          	jalr	-1400(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004f78:	60e2                	ld	ra,24(sp)
    80004f7a:	6442                	ld	s0,16(sp)
    80004f7c:	64a2                	ld	s1,8(sp)
    80004f7e:	6902                	ld	s2,0(sp)
    80004f80:	6105                	addi	sp,sp,32
    80004f82:	8082                	ret
    pi->readopen = 0;
    80004f84:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f88:	21c48513          	addi	a0,s1,540
    80004f8c:	ffffd097          	auipc	ra,0xffffd
    80004f90:	630080e7          	jalr	1584(ra) # 800025bc <wakeup>
    80004f94:	b7e9                	j	80004f5e <pipeclose+0x2c>
    release(&pi->lock);
    80004f96:	8526                	mv	a0,s1
    80004f98:	ffffc097          	auipc	ra,0xffffc
    80004f9c:	d12080e7          	jalr	-750(ra) # 80000caa <release>
}
    80004fa0:	bfe1                	j	80004f78 <pipeclose+0x46>

0000000080004fa2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004fa2:	7159                	addi	sp,sp,-112
    80004fa4:	f486                	sd	ra,104(sp)
    80004fa6:	f0a2                	sd	s0,96(sp)
    80004fa8:	eca6                	sd	s1,88(sp)
    80004faa:	e8ca                	sd	s2,80(sp)
    80004fac:	e4ce                	sd	s3,72(sp)
    80004fae:	e0d2                	sd	s4,64(sp)
    80004fb0:	fc56                	sd	s5,56(sp)
    80004fb2:	f85a                	sd	s6,48(sp)
    80004fb4:	f45e                	sd	s7,40(sp)
    80004fb6:	f062                	sd	s8,32(sp)
    80004fb8:	ec66                	sd	s9,24(sp)
    80004fba:	1880                	addi	s0,sp,112
    80004fbc:	84aa                	mv	s1,a0
    80004fbe:	8aae                	mv	s5,a1
    80004fc0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004fc2:	ffffd097          	auipc	ra,0xffffd
    80004fc6:	dd4080e7          	jalr	-556(ra) # 80001d96 <myproc>
    80004fca:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004fcc:	8526                	mv	a0,s1
    80004fce:	ffffc097          	auipc	ra,0xffffc
    80004fd2:	c16080e7          	jalr	-1002(ra) # 80000be4 <acquire>
  while(i < n){
    80004fd6:	0d405163          	blez	s4,80005098 <pipewrite+0xf6>
    80004fda:	8ba6                	mv	s7,s1
  int i = 0;
    80004fdc:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fde:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004fe0:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004fe4:	21c48c13          	addi	s8,s1,540
    80004fe8:	a08d                	j	8000504a <pipewrite+0xa8>
      release(&pi->lock);
    80004fea:	8526                	mv	a0,s1
    80004fec:	ffffc097          	auipc	ra,0xffffc
    80004ff0:	cbe080e7          	jalr	-834(ra) # 80000caa <release>
      return -1;
    80004ff4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ff6:	854a                	mv	a0,s2
    80004ff8:	70a6                	ld	ra,104(sp)
    80004ffa:	7406                	ld	s0,96(sp)
    80004ffc:	64e6                	ld	s1,88(sp)
    80004ffe:	6946                	ld	s2,80(sp)
    80005000:	69a6                	ld	s3,72(sp)
    80005002:	6a06                	ld	s4,64(sp)
    80005004:	7ae2                	ld	s5,56(sp)
    80005006:	7b42                	ld	s6,48(sp)
    80005008:	7ba2                	ld	s7,40(sp)
    8000500a:	7c02                	ld	s8,32(sp)
    8000500c:	6ce2                	ld	s9,24(sp)
    8000500e:	6165                	addi	sp,sp,112
    80005010:	8082                	ret
      wakeup(&pi->nread);
    80005012:	8566                	mv	a0,s9
    80005014:	ffffd097          	auipc	ra,0xffffd
    80005018:	5a8080e7          	jalr	1448(ra) # 800025bc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000501c:	85de                	mv	a1,s7
    8000501e:	8562                	mv	a0,s8
    80005020:	ffffd097          	auipc	ra,0xffffd
    80005024:	3f6080e7          	jalr	1014(ra) # 80002416 <sleep>
    80005028:	a839                	j	80005046 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000502a:	21c4a783          	lw	a5,540(s1)
    8000502e:	0017871b          	addiw	a4,a5,1
    80005032:	20e4ae23          	sw	a4,540(s1)
    80005036:	1ff7f793          	andi	a5,a5,511
    8000503a:	97a6                	add	a5,a5,s1
    8000503c:	f9f44703          	lbu	a4,-97(s0)
    80005040:	00e78c23          	sb	a4,24(a5)
      i++;
    80005044:	2905                	addiw	s2,s2,1
  while(i < n){
    80005046:	03495d63          	bge	s2,s4,80005080 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    8000504a:	2204a783          	lw	a5,544(s1)
    8000504e:	dfd1                	beqz	a5,80004fea <pipewrite+0x48>
    80005050:	0289a783          	lw	a5,40(s3)
    80005054:	fbd9                	bnez	a5,80004fea <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005056:	2184a783          	lw	a5,536(s1)
    8000505a:	21c4a703          	lw	a4,540(s1)
    8000505e:	2007879b          	addiw	a5,a5,512
    80005062:	faf708e3          	beq	a4,a5,80005012 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005066:	4685                	li	a3,1
    80005068:	01590633          	add	a2,s2,s5
    8000506c:	f9f40593          	addi	a1,s0,-97
    80005070:	0709b503          	ld	a0,112(s3)
    80005074:	ffffc097          	auipc	ra,0xffffc
    80005078:	6ae080e7          	jalr	1710(ra) # 80001722 <copyin>
    8000507c:	fb6517e3          	bne	a0,s6,8000502a <pipewrite+0x88>
  wakeup(&pi->nread);
    80005080:	21848513          	addi	a0,s1,536
    80005084:	ffffd097          	auipc	ra,0xffffd
    80005088:	538080e7          	jalr	1336(ra) # 800025bc <wakeup>
  release(&pi->lock);
    8000508c:	8526                	mv	a0,s1
    8000508e:	ffffc097          	auipc	ra,0xffffc
    80005092:	c1c080e7          	jalr	-996(ra) # 80000caa <release>
  return i;
    80005096:	b785                	j	80004ff6 <pipewrite+0x54>
  int i = 0;
    80005098:	4901                	li	s2,0
    8000509a:	b7dd                	j	80005080 <pipewrite+0xde>

000000008000509c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000509c:	715d                	addi	sp,sp,-80
    8000509e:	e486                	sd	ra,72(sp)
    800050a0:	e0a2                	sd	s0,64(sp)
    800050a2:	fc26                	sd	s1,56(sp)
    800050a4:	f84a                	sd	s2,48(sp)
    800050a6:	f44e                	sd	s3,40(sp)
    800050a8:	f052                	sd	s4,32(sp)
    800050aa:	ec56                	sd	s5,24(sp)
    800050ac:	e85a                	sd	s6,16(sp)
    800050ae:	0880                	addi	s0,sp,80
    800050b0:	84aa                	mv	s1,a0
    800050b2:	892e                	mv	s2,a1
    800050b4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800050b6:	ffffd097          	auipc	ra,0xffffd
    800050ba:	ce0080e7          	jalr	-800(ra) # 80001d96 <myproc>
    800050be:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800050c0:	8b26                	mv	s6,s1
    800050c2:	8526                	mv	a0,s1
    800050c4:	ffffc097          	auipc	ra,0xffffc
    800050c8:	b20080e7          	jalr	-1248(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050cc:	2184a703          	lw	a4,536(s1)
    800050d0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050d4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050d8:	02f71463          	bne	a4,a5,80005100 <piperead+0x64>
    800050dc:	2244a783          	lw	a5,548(s1)
    800050e0:	c385                	beqz	a5,80005100 <piperead+0x64>
    if(pr->killed){
    800050e2:	028a2783          	lw	a5,40(s4)
    800050e6:	ebc1                	bnez	a5,80005176 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050e8:	85da                	mv	a1,s6
    800050ea:	854e                	mv	a0,s3
    800050ec:	ffffd097          	auipc	ra,0xffffd
    800050f0:	32a080e7          	jalr	810(ra) # 80002416 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050f4:	2184a703          	lw	a4,536(s1)
    800050f8:	21c4a783          	lw	a5,540(s1)
    800050fc:	fef700e3          	beq	a4,a5,800050dc <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005100:	09505263          	blez	s5,80005184 <piperead+0xe8>
    80005104:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005106:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005108:	2184a783          	lw	a5,536(s1)
    8000510c:	21c4a703          	lw	a4,540(s1)
    80005110:	02f70d63          	beq	a4,a5,8000514a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005114:	0017871b          	addiw	a4,a5,1
    80005118:	20e4ac23          	sw	a4,536(s1)
    8000511c:	1ff7f793          	andi	a5,a5,511
    80005120:	97a6                	add	a5,a5,s1
    80005122:	0187c783          	lbu	a5,24(a5)
    80005126:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000512a:	4685                	li	a3,1
    8000512c:	fbf40613          	addi	a2,s0,-65
    80005130:	85ca                	mv	a1,s2
    80005132:	070a3503          	ld	a0,112(s4)
    80005136:	ffffc097          	auipc	ra,0xffffc
    8000513a:	560080e7          	jalr	1376(ra) # 80001696 <copyout>
    8000513e:	01650663          	beq	a0,s6,8000514a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005142:	2985                	addiw	s3,s3,1
    80005144:	0905                	addi	s2,s2,1
    80005146:	fd3a91e3          	bne	s5,s3,80005108 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000514a:	21c48513          	addi	a0,s1,540
    8000514e:	ffffd097          	auipc	ra,0xffffd
    80005152:	46e080e7          	jalr	1134(ra) # 800025bc <wakeup>
  release(&pi->lock);
    80005156:	8526                	mv	a0,s1
    80005158:	ffffc097          	auipc	ra,0xffffc
    8000515c:	b52080e7          	jalr	-1198(ra) # 80000caa <release>
  return i;
}
    80005160:	854e                	mv	a0,s3
    80005162:	60a6                	ld	ra,72(sp)
    80005164:	6406                	ld	s0,64(sp)
    80005166:	74e2                	ld	s1,56(sp)
    80005168:	7942                	ld	s2,48(sp)
    8000516a:	79a2                	ld	s3,40(sp)
    8000516c:	7a02                	ld	s4,32(sp)
    8000516e:	6ae2                	ld	s5,24(sp)
    80005170:	6b42                	ld	s6,16(sp)
    80005172:	6161                	addi	sp,sp,80
    80005174:	8082                	ret
      release(&pi->lock);
    80005176:	8526                	mv	a0,s1
    80005178:	ffffc097          	auipc	ra,0xffffc
    8000517c:	b32080e7          	jalr	-1230(ra) # 80000caa <release>
      return -1;
    80005180:	59fd                	li	s3,-1
    80005182:	bff9                	j	80005160 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005184:	4981                	li	s3,0
    80005186:	b7d1                	j	8000514a <piperead+0xae>

0000000080005188 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005188:	df010113          	addi	sp,sp,-528
    8000518c:	20113423          	sd	ra,520(sp)
    80005190:	20813023          	sd	s0,512(sp)
    80005194:	ffa6                	sd	s1,504(sp)
    80005196:	fbca                	sd	s2,496(sp)
    80005198:	f7ce                	sd	s3,488(sp)
    8000519a:	f3d2                	sd	s4,480(sp)
    8000519c:	efd6                	sd	s5,472(sp)
    8000519e:	ebda                	sd	s6,464(sp)
    800051a0:	e7de                	sd	s7,456(sp)
    800051a2:	e3e2                	sd	s8,448(sp)
    800051a4:	ff66                	sd	s9,440(sp)
    800051a6:	fb6a                	sd	s10,432(sp)
    800051a8:	f76e                	sd	s11,424(sp)
    800051aa:	0c00                	addi	s0,sp,528
    800051ac:	84aa                	mv	s1,a0
    800051ae:	dea43c23          	sd	a0,-520(s0)
    800051b2:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800051b6:	ffffd097          	auipc	ra,0xffffd
    800051ba:	be0080e7          	jalr	-1056(ra) # 80001d96 <myproc>
    800051be:	892a                	mv	s2,a0

  begin_op();
    800051c0:	fffff097          	auipc	ra,0xfffff
    800051c4:	49c080e7          	jalr	1180(ra) # 8000465c <begin_op>

  if((ip = namei(path)) == 0){
    800051c8:	8526                	mv	a0,s1
    800051ca:	fffff097          	auipc	ra,0xfffff
    800051ce:	276080e7          	jalr	630(ra) # 80004440 <namei>
    800051d2:	c92d                	beqz	a0,80005244 <exec+0xbc>
    800051d4:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800051d6:	fffff097          	auipc	ra,0xfffff
    800051da:	ab4080e7          	jalr	-1356(ra) # 80003c8a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800051de:	04000713          	li	a4,64
    800051e2:	4681                	li	a3,0
    800051e4:	e5040613          	addi	a2,s0,-432
    800051e8:	4581                	li	a1,0
    800051ea:	8526                	mv	a0,s1
    800051ec:	fffff097          	auipc	ra,0xfffff
    800051f0:	d52080e7          	jalr	-686(ra) # 80003f3e <readi>
    800051f4:	04000793          	li	a5,64
    800051f8:	00f51a63          	bne	a0,a5,8000520c <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800051fc:	e5042703          	lw	a4,-432(s0)
    80005200:	464c47b7          	lui	a5,0x464c4
    80005204:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005208:	04f70463          	beq	a4,a5,80005250 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000520c:	8526                	mv	a0,s1
    8000520e:	fffff097          	auipc	ra,0xfffff
    80005212:	cde080e7          	jalr	-802(ra) # 80003eec <iunlockput>
    end_op();
    80005216:	fffff097          	auipc	ra,0xfffff
    8000521a:	4c6080e7          	jalr	1222(ra) # 800046dc <end_op>
  }
  return -1;
    8000521e:	557d                	li	a0,-1
}
    80005220:	20813083          	ld	ra,520(sp)
    80005224:	20013403          	ld	s0,512(sp)
    80005228:	74fe                	ld	s1,504(sp)
    8000522a:	795e                	ld	s2,496(sp)
    8000522c:	79be                	ld	s3,488(sp)
    8000522e:	7a1e                	ld	s4,480(sp)
    80005230:	6afe                	ld	s5,472(sp)
    80005232:	6b5e                	ld	s6,464(sp)
    80005234:	6bbe                	ld	s7,456(sp)
    80005236:	6c1e                	ld	s8,448(sp)
    80005238:	7cfa                	ld	s9,440(sp)
    8000523a:	7d5a                	ld	s10,432(sp)
    8000523c:	7dba                	ld	s11,424(sp)
    8000523e:	21010113          	addi	sp,sp,528
    80005242:	8082                	ret
    end_op();
    80005244:	fffff097          	auipc	ra,0xfffff
    80005248:	498080e7          	jalr	1176(ra) # 800046dc <end_op>
    return -1;
    8000524c:	557d                	li	a0,-1
    8000524e:	bfc9                	j	80005220 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005250:	854a                	mv	a0,s2
    80005252:	ffffd097          	auipc	ra,0xffffd
    80005256:	c04080e7          	jalr	-1020(ra) # 80001e56 <proc_pagetable>
    8000525a:	8baa                	mv	s7,a0
    8000525c:	d945                	beqz	a0,8000520c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000525e:	e7042983          	lw	s3,-400(s0)
    80005262:	e8845783          	lhu	a5,-376(s0)
    80005266:	c7ad                	beqz	a5,800052d0 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005268:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000526a:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    8000526c:	6c85                	lui	s9,0x1
    8000526e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005272:	def43823          	sd	a5,-528(s0)
    80005276:	a42d                	j	800054a0 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005278:	00003517          	auipc	a0,0x3
    8000527c:	4a850513          	addi	a0,a0,1192 # 80008720 <syscalls+0x290>
    80005280:	ffffb097          	auipc	ra,0xffffb
    80005284:	2be080e7          	jalr	702(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005288:	8756                	mv	a4,s5
    8000528a:	012d86bb          	addw	a3,s11,s2
    8000528e:	4581                	li	a1,0
    80005290:	8526                	mv	a0,s1
    80005292:	fffff097          	auipc	ra,0xfffff
    80005296:	cac080e7          	jalr	-852(ra) # 80003f3e <readi>
    8000529a:	2501                	sext.w	a0,a0
    8000529c:	1aaa9963          	bne	s5,a0,8000544e <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800052a0:	6785                	lui	a5,0x1
    800052a2:	0127893b          	addw	s2,a5,s2
    800052a6:	77fd                	lui	a5,0xfffff
    800052a8:	01478a3b          	addw	s4,a5,s4
    800052ac:	1f897163          	bgeu	s2,s8,8000548e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800052b0:	02091593          	slli	a1,s2,0x20
    800052b4:	9181                	srli	a1,a1,0x20
    800052b6:	95ea                	add	a1,a1,s10
    800052b8:	855e                	mv	a0,s7
    800052ba:	ffffc097          	auipc	ra,0xffffc
    800052be:	dd8080e7          	jalr	-552(ra) # 80001092 <walkaddr>
    800052c2:	862a                	mv	a2,a0
    if(pa == 0)
    800052c4:	d955                	beqz	a0,80005278 <exec+0xf0>
      n = PGSIZE;
    800052c6:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800052c8:	fd9a70e3          	bgeu	s4,s9,80005288 <exec+0x100>
      n = sz - i;
    800052cc:	8ad2                	mv	s5,s4
    800052ce:	bf6d                	j	80005288 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052d0:	4901                	li	s2,0
  iunlockput(ip);
    800052d2:	8526                	mv	a0,s1
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	c18080e7          	jalr	-1000(ra) # 80003eec <iunlockput>
  end_op();
    800052dc:	fffff097          	auipc	ra,0xfffff
    800052e0:	400080e7          	jalr	1024(ra) # 800046dc <end_op>
  p = myproc();
    800052e4:	ffffd097          	auipc	ra,0xffffd
    800052e8:	ab2080e7          	jalr	-1358(ra) # 80001d96 <myproc>
    800052ec:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800052ee:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    800052f2:	6785                	lui	a5,0x1
    800052f4:	17fd                	addi	a5,a5,-1
    800052f6:	993e                	add	s2,s2,a5
    800052f8:	757d                	lui	a0,0xfffff
    800052fa:	00a977b3          	and	a5,s2,a0
    800052fe:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005302:	6609                	lui	a2,0x2
    80005304:	963e                	add	a2,a2,a5
    80005306:	85be                	mv	a1,a5
    80005308:	855e                	mv	a0,s7
    8000530a:	ffffc097          	auipc	ra,0xffffc
    8000530e:	13c080e7          	jalr	316(ra) # 80001446 <uvmalloc>
    80005312:	8b2a                	mv	s6,a0
  ip = 0;
    80005314:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005316:	12050c63          	beqz	a0,8000544e <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000531a:	75f9                	lui	a1,0xffffe
    8000531c:	95aa                	add	a1,a1,a0
    8000531e:	855e                	mv	a0,s7
    80005320:	ffffc097          	auipc	ra,0xffffc
    80005324:	344080e7          	jalr	836(ra) # 80001664 <uvmclear>
  stackbase = sp - PGSIZE;
    80005328:	7c7d                	lui	s8,0xfffff
    8000532a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000532c:	e0043783          	ld	a5,-512(s0)
    80005330:	6388                	ld	a0,0(a5)
    80005332:	c535                	beqz	a0,8000539e <exec+0x216>
    80005334:	e9040993          	addi	s3,s0,-368
    80005338:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000533c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000533e:	ffffc097          	auipc	ra,0xffffc
    80005342:	b4a080e7          	jalr	-1206(ra) # 80000e88 <strlen>
    80005346:	2505                	addiw	a0,a0,1
    80005348:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000534c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005350:	13896363          	bltu	s2,s8,80005476 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005354:	e0043d83          	ld	s11,-512(s0)
    80005358:	000dba03          	ld	s4,0(s11)
    8000535c:	8552                	mv	a0,s4
    8000535e:	ffffc097          	auipc	ra,0xffffc
    80005362:	b2a080e7          	jalr	-1238(ra) # 80000e88 <strlen>
    80005366:	0015069b          	addiw	a3,a0,1
    8000536a:	8652                	mv	a2,s4
    8000536c:	85ca                	mv	a1,s2
    8000536e:	855e                	mv	a0,s7
    80005370:	ffffc097          	auipc	ra,0xffffc
    80005374:	326080e7          	jalr	806(ra) # 80001696 <copyout>
    80005378:	10054363          	bltz	a0,8000547e <exec+0x2f6>
    ustack[argc] = sp;
    8000537c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005380:	0485                	addi	s1,s1,1
    80005382:	008d8793          	addi	a5,s11,8
    80005386:	e0f43023          	sd	a5,-512(s0)
    8000538a:	008db503          	ld	a0,8(s11)
    8000538e:	c911                	beqz	a0,800053a2 <exec+0x21a>
    if(argc >= MAXARG)
    80005390:	09a1                	addi	s3,s3,8
    80005392:	fb3c96e3          	bne	s9,s3,8000533e <exec+0x1b6>
  sz = sz1;
    80005396:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000539a:	4481                	li	s1,0
    8000539c:	a84d                	j	8000544e <exec+0x2c6>
  sp = sz;
    8000539e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800053a0:	4481                	li	s1,0
  ustack[argc] = 0;
    800053a2:	00349793          	slli	a5,s1,0x3
    800053a6:	f9040713          	addi	a4,s0,-112
    800053aa:	97ba                	add	a5,a5,a4
    800053ac:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800053b0:	00148693          	addi	a3,s1,1
    800053b4:	068e                	slli	a3,a3,0x3
    800053b6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800053ba:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800053be:	01897663          	bgeu	s2,s8,800053ca <exec+0x242>
  sz = sz1;
    800053c2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053c6:	4481                	li	s1,0
    800053c8:	a059                	j	8000544e <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053ca:	e9040613          	addi	a2,s0,-368
    800053ce:	85ca                	mv	a1,s2
    800053d0:	855e                	mv	a0,s7
    800053d2:	ffffc097          	auipc	ra,0xffffc
    800053d6:	2c4080e7          	jalr	708(ra) # 80001696 <copyout>
    800053da:	0a054663          	bltz	a0,80005486 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800053de:	078ab783          	ld	a5,120(s5)
    800053e2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800053e6:	df843783          	ld	a5,-520(s0)
    800053ea:	0007c703          	lbu	a4,0(a5)
    800053ee:	cf11                	beqz	a4,8000540a <exec+0x282>
    800053f0:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053f2:	02f00693          	li	a3,47
    800053f6:	a039                	j	80005404 <exec+0x27c>
      last = s+1;
    800053f8:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800053fc:	0785                	addi	a5,a5,1
    800053fe:	fff7c703          	lbu	a4,-1(a5)
    80005402:	c701                	beqz	a4,8000540a <exec+0x282>
    if(*s == '/')
    80005404:	fed71ce3          	bne	a4,a3,800053fc <exec+0x274>
    80005408:	bfc5                	j	800053f8 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000540a:	4641                	li	a2,16
    8000540c:	df843583          	ld	a1,-520(s0)
    80005410:	178a8513          	addi	a0,s5,376
    80005414:	ffffc097          	auipc	ra,0xffffc
    80005418:	a42080e7          	jalr	-1470(ra) # 80000e56 <safestrcpy>
  oldpagetable = p->pagetable;
    8000541c:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    80005420:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    80005424:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005428:	078ab783          	ld	a5,120(s5)
    8000542c:	e6843703          	ld	a4,-408(s0)
    80005430:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005432:	078ab783          	ld	a5,120(s5)
    80005436:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000543a:	85ea                	mv	a1,s10
    8000543c:	ffffd097          	auipc	ra,0xffffd
    80005440:	ab6080e7          	jalr	-1354(ra) # 80001ef2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005444:	0004851b          	sext.w	a0,s1
    80005448:	bbe1                	j	80005220 <exec+0x98>
    8000544a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000544e:	e0843583          	ld	a1,-504(s0)
    80005452:	855e                	mv	a0,s7
    80005454:	ffffd097          	auipc	ra,0xffffd
    80005458:	a9e080e7          	jalr	-1378(ra) # 80001ef2 <proc_freepagetable>
  if(ip){
    8000545c:	da0498e3          	bnez	s1,8000520c <exec+0x84>
  return -1;
    80005460:	557d                	li	a0,-1
    80005462:	bb7d                	j	80005220 <exec+0x98>
    80005464:	e1243423          	sd	s2,-504(s0)
    80005468:	b7dd                	j	8000544e <exec+0x2c6>
    8000546a:	e1243423          	sd	s2,-504(s0)
    8000546e:	b7c5                	j	8000544e <exec+0x2c6>
    80005470:	e1243423          	sd	s2,-504(s0)
    80005474:	bfe9                	j	8000544e <exec+0x2c6>
  sz = sz1;
    80005476:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000547a:	4481                	li	s1,0
    8000547c:	bfc9                	j	8000544e <exec+0x2c6>
  sz = sz1;
    8000547e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005482:	4481                	li	s1,0
    80005484:	b7e9                	j	8000544e <exec+0x2c6>
  sz = sz1;
    80005486:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000548a:	4481                	li	s1,0
    8000548c:	b7c9                	j	8000544e <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000548e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005492:	2b05                	addiw	s6,s6,1
    80005494:	0389899b          	addiw	s3,s3,56
    80005498:	e8845783          	lhu	a5,-376(s0)
    8000549c:	e2fb5be3          	bge	s6,a5,800052d2 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800054a0:	2981                	sext.w	s3,s3
    800054a2:	03800713          	li	a4,56
    800054a6:	86ce                	mv	a3,s3
    800054a8:	e1840613          	addi	a2,s0,-488
    800054ac:	4581                	li	a1,0
    800054ae:	8526                	mv	a0,s1
    800054b0:	fffff097          	auipc	ra,0xfffff
    800054b4:	a8e080e7          	jalr	-1394(ra) # 80003f3e <readi>
    800054b8:	03800793          	li	a5,56
    800054bc:	f8f517e3          	bne	a0,a5,8000544a <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800054c0:	e1842783          	lw	a5,-488(s0)
    800054c4:	4705                	li	a4,1
    800054c6:	fce796e3          	bne	a5,a4,80005492 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800054ca:	e4043603          	ld	a2,-448(s0)
    800054ce:	e3843783          	ld	a5,-456(s0)
    800054d2:	f8f669e3          	bltu	a2,a5,80005464 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800054d6:	e2843783          	ld	a5,-472(s0)
    800054da:	963e                	add	a2,a2,a5
    800054dc:	f8f667e3          	bltu	a2,a5,8000546a <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800054e0:	85ca                	mv	a1,s2
    800054e2:	855e                	mv	a0,s7
    800054e4:	ffffc097          	auipc	ra,0xffffc
    800054e8:	f62080e7          	jalr	-158(ra) # 80001446 <uvmalloc>
    800054ec:	e0a43423          	sd	a0,-504(s0)
    800054f0:	d141                	beqz	a0,80005470 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800054f2:	e2843d03          	ld	s10,-472(s0)
    800054f6:	df043783          	ld	a5,-528(s0)
    800054fa:	00fd77b3          	and	a5,s10,a5
    800054fe:	fba1                	bnez	a5,8000544e <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005500:	e2042d83          	lw	s11,-480(s0)
    80005504:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005508:	f80c03e3          	beqz	s8,8000548e <exec+0x306>
    8000550c:	8a62                	mv	s4,s8
    8000550e:	4901                	li	s2,0
    80005510:	b345                	j	800052b0 <exec+0x128>

0000000080005512 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005512:	7179                	addi	sp,sp,-48
    80005514:	f406                	sd	ra,40(sp)
    80005516:	f022                	sd	s0,32(sp)
    80005518:	ec26                	sd	s1,24(sp)
    8000551a:	e84a                	sd	s2,16(sp)
    8000551c:	1800                	addi	s0,sp,48
    8000551e:	892e                	mv	s2,a1
    80005520:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005522:	fdc40593          	addi	a1,s0,-36
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	ba8080e7          	jalr	-1112(ra) # 800030ce <argint>
    8000552e:	04054063          	bltz	a0,8000556e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005532:	fdc42703          	lw	a4,-36(s0)
    80005536:	47bd                	li	a5,15
    80005538:	02e7ed63          	bltu	a5,a4,80005572 <argfd+0x60>
    8000553c:	ffffd097          	auipc	ra,0xffffd
    80005540:	85a080e7          	jalr	-1958(ra) # 80001d96 <myproc>
    80005544:	fdc42703          	lw	a4,-36(s0)
    80005548:	01e70793          	addi	a5,a4,30
    8000554c:	078e                	slli	a5,a5,0x3
    8000554e:	953e                	add	a0,a0,a5
    80005550:	611c                	ld	a5,0(a0)
    80005552:	c395                	beqz	a5,80005576 <argfd+0x64>
    return -1;
  if(pfd)
    80005554:	00090463          	beqz	s2,8000555c <argfd+0x4a>
    *pfd = fd;
    80005558:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000555c:	4501                	li	a0,0
  if(pf)
    8000555e:	c091                	beqz	s1,80005562 <argfd+0x50>
    *pf = f;
    80005560:	e09c                	sd	a5,0(s1)
}
    80005562:	70a2                	ld	ra,40(sp)
    80005564:	7402                	ld	s0,32(sp)
    80005566:	64e2                	ld	s1,24(sp)
    80005568:	6942                	ld	s2,16(sp)
    8000556a:	6145                	addi	sp,sp,48
    8000556c:	8082                	ret
    return -1;
    8000556e:	557d                	li	a0,-1
    80005570:	bfcd                	j	80005562 <argfd+0x50>
    return -1;
    80005572:	557d                	li	a0,-1
    80005574:	b7fd                	j	80005562 <argfd+0x50>
    80005576:	557d                	li	a0,-1
    80005578:	b7ed                	j	80005562 <argfd+0x50>

000000008000557a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000557a:	1101                	addi	sp,sp,-32
    8000557c:	ec06                	sd	ra,24(sp)
    8000557e:	e822                	sd	s0,16(sp)
    80005580:	e426                	sd	s1,8(sp)
    80005582:	1000                	addi	s0,sp,32
    80005584:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005586:	ffffd097          	auipc	ra,0xffffd
    8000558a:	810080e7          	jalr	-2032(ra) # 80001d96 <myproc>
    8000558e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005590:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    80005594:	4501                	li	a0,0
    80005596:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005598:	6398                	ld	a4,0(a5)
    8000559a:	cb19                	beqz	a4,800055b0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000559c:	2505                	addiw	a0,a0,1
    8000559e:	07a1                	addi	a5,a5,8
    800055a0:	fed51ce3          	bne	a0,a3,80005598 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800055a4:	557d                	li	a0,-1
}
    800055a6:	60e2                	ld	ra,24(sp)
    800055a8:	6442                	ld	s0,16(sp)
    800055aa:	64a2                	ld	s1,8(sp)
    800055ac:	6105                	addi	sp,sp,32
    800055ae:	8082                	ret
      p->ofile[fd] = f;
    800055b0:	01e50793          	addi	a5,a0,30
    800055b4:	078e                	slli	a5,a5,0x3
    800055b6:	963e                	add	a2,a2,a5
    800055b8:	e204                	sd	s1,0(a2)
      return fd;
    800055ba:	b7f5                	j	800055a6 <fdalloc+0x2c>

00000000800055bc <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800055bc:	715d                	addi	sp,sp,-80
    800055be:	e486                	sd	ra,72(sp)
    800055c0:	e0a2                	sd	s0,64(sp)
    800055c2:	fc26                	sd	s1,56(sp)
    800055c4:	f84a                	sd	s2,48(sp)
    800055c6:	f44e                	sd	s3,40(sp)
    800055c8:	f052                	sd	s4,32(sp)
    800055ca:	ec56                	sd	s5,24(sp)
    800055cc:	0880                	addi	s0,sp,80
    800055ce:	89ae                	mv	s3,a1
    800055d0:	8ab2                	mv	s5,a2
    800055d2:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055d4:	fb040593          	addi	a1,s0,-80
    800055d8:	fffff097          	auipc	ra,0xfffff
    800055dc:	e86080e7          	jalr	-378(ra) # 8000445e <nameiparent>
    800055e0:	892a                	mv	s2,a0
    800055e2:	12050f63          	beqz	a0,80005720 <create+0x164>
    return 0;

  ilock(dp);
    800055e6:	ffffe097          	auipc	ra,0xffffe
    800055ea:	6a4080e7          	jalr	1700(ra) # 80003c8a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800055ee:	4601                	li	a2,0
    800055f0:	fb040593          	addi	a1,s0,-80
    800055f4:	854a                	mv	a0,s2
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	b78080e7          	jalr	-1160(ra) # 8000416e <dirlookup>
    800055fe:	84aa                	mv	s1,a0
    80005600:	c921                	beqz	a0,80005650 <create+0x94>
    iunlockput(dp);
    80005602:	854a                	mv	a0,s2
    80005604:	fffff097          	auipc	ra,0xfffff
    80005608:	8e8080e7          	jalr	-1816(ra) # 80003eec <iunlockput>
    ilock(ip);
    8000560c:	8526                	mv	a0,s1
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	67c080e7          	jalr	1660(ra) # 80003c8a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005616:	2981                	sext.w	s3,s3
    80005618:	4789                	li	a5,2
    8000561a:	02f99463          	bne	s3,a5,80005642 <create+0x86>
    8000561e:	0444d783          	lhu	a5,68(s1)
    80005622:	37f9                	addiw	a5,a5,-2
    80005624:	17c2                	slli	a5,a5,0x30
    80005626:	93c1                	srli	a5,a5,0x30
    80005628:	4705                	li	a4,1
    8000562a:	00f76c63          	bltu	a4,a5,80005642 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000562e:	8526                	mv	a0,s1
    80005630:	60a6                	ld	ra,72(sp)
    80005632:	6406                	ld	s0,64(sp)
    80005634:	74e2                	ld	s1,56(sp)
    80005636:	7942                	ld	s2,48(sp)
    80005638:	79a2                	ld	s3,40(sp)
    8000563a:	7a02                	ld	s4,32(sp)
    8000563c:	6ae2                	ld	s5,24(sp)
    8000563e:	6161                	addi	sp,sp,80
    80005640:	8082                	ret
    iunlockput(ip);
    80005642:	8526                	mv	a0,s1
    80005644:	fffff097          	auipc	ra,0xfffff
    80005648:	8a8080e7          	jalr	-1880(ra) # 80003eec <iunlockput>
    return 0;
    8000564c:	4481                	li	s1,0
    8000564e:	b7c5                	j	8000562e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005650:	85ce                	mv	a1,s3
    80005652:	00092503          	lw	a0,0(s2)
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	49c080e7          	jalr	1180(ra) # 80003af2 <ialloc>
    8000565e:	84aa                	mv	s1,a0
    80005660:	c529                	beqz	a0,800056aa <create+0xee>
  ilock(ip);
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	628080e7          	jalr	1576(ra) # 80003c8a <ilock>
  ip->major = major;
    8000566a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000566e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005672:	4785                	li	a5,1
    80005674:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005678:	8526                	mv	a0,s1
    8000567a:	ffffe097          	auipc	ra,0xffffe
    8000567e:	546080e7          	jalr	1350(ra) # 80003bc0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005682:	2981                	sext.w	s3,s3
    80005684:	4785                	li	a5,1
    80005686:	02f98a63          	beq	s3,a5,800056ba <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000568a:	40d0                	lw	a2,4(s1)
    8000568c:	fb040593          	addi	a1,s0,-80
    80005690:	854a                	mv	a0,s2
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	cec080e7          	jalr	-788(ra) # 8000437e <dirlink>
    8000569a:	06054b63          	bltz	a0,80005710 <create+0x154>
  iunlockput(dp);
    8000569e:	854a                	mv	a0,s2
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	84c080e7          	jalr	-1972(ra) # 80003eec <iunlockput>
  return ip;
    800056a8:	b759                	j	8000562e <create+0x72>
    panic("create: ialloc");
    800056aa:	00003517          	auipc	a0,0x3
    800056ae:	09650513          	addi	a0,a0,150 # 80008740 <syscalls+0x2b0>
    800056b2:	ffffb097          	auipc	ra,0xffffb
    800056b6:	e8c080e7          	jalr	-372(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800056ba:	04a95783          	lhu	a5,74(s2)
    800056be:	2785                	addiw	a5,a5,1
    800056c0:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800056c4:	854a                	mv	a0,s2
    800056c6:	ffffe097          	auipc	ra,0xffffe
    800056ca:	4fa080e7          	jalr	1274(ra) # 80003bc0 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800056ce:	40d0                	lw	a2,4(s1)
    800056d0:	00003597          	auipc	a1,0x3
    800056d4:	08058593          	addi	a1,a1,128 # 80008750 <syscalls+0x2c0>
    800056d8:	8526                	mv	a0,s1
    800056da:	fffff097          	auipc	ra,0xfffff
    800056de:	ca4080e7          	jalr	-860(ra) # 8000437e <dirlink>
    800056e2:	00054f63          	bltz	a0,80005700 <create+0x144>
    800056e6:	00492603          	lw	a2,4(s2)
    800056ea:	00003597          	auipc	a1,0x3
    800056ee:	06e58593          	addi	a1,a1,110 # 80008758 <syscalls+0x2c8>
    800056f2:	8526                	mv	a0,s1
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	c8a080e7          	jalr	-886(ra) # 8000437e <dirlink>
    800056fc:	f80557e3          	bgez	a0,8000568a <create+0xce>
      panic("create dots");
    80005700:	00003517          	auipc	a0,0x3
    80005704:	06050513          	addi	a0,a0,96 # 80008760 <syscalls+0x2d0>
    80005708:	ffffb097          	auipc	ra,0xffffb
    8000570c:	e36080e7          	jalr	-458(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005710:	00003517          	auipc	a0,0x3
    80005714:	06050513          	addi	a0,a0,96 # 80008770 <syscalls+0x2e0>
    80005718:	ffffb097          	auipc	ra,0xffffb
    8000571c:	e26080e7          	jalr	-474(ra) # 8000053e <panic>
    return 0;
    80005720:	84aa                	mv	s1,a0
    80005722:	b731                	j	8000562e <create+0x72>

0000000080005724 <sys_dup>:
{
    80005724:	7179                	addi	sp,sp,-48
    80005726:	f406                	sd	ra,40(sp)
    80005728:	f022                	sd	s0,32(sp)
    8000572a:	ec26                	sd	s1,24(sp)
    8000572c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000572e:	fd840613          	addi	a2,s0,-40
    80005732:	4581                	li	a1,0
    80005734:	4501                	li	a0,0
    80005736:	00000097          	auipc	ra,0x0
    8000573a:	ddc080e7          	jalr	-548(ra) # 80005512 <argfd>
    return -1;
    8000573e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005740:	02054363          	bltz	a0,80005766 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005744:	fd843503          	ld	a0,-40(s0)
    80005748:	00000097          	auipc	ra,0x0
    8000574c:	e32080e7          	jalr	-462(ra) # 8000557a <fdalloc>
    80005750:	84aa                	mv	s1,a0
    return -1;
    80005752:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005754:	00054963          	bltz	a0,80005766 <sys_dup+0x42>
  filedup(f);
    80005758:	fd843503          	ld	a0,-40(s0)
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	37a080e7          	jalr	890(ra) # 80004ad6 <filedup>
  return fd;
    80005764:	87a6                	mv	a5,s1
}
    80005766:	853e                	mv	a0,a5
    80005768:	70a2                	ld	ra,40(sp)
    8000576a:	7402                	ld	s0,32(sp)
    8000576c:	64e2                	ld	s1,24(sp)
    8000576e:	6145                	addi	sp,sp,48
    80005770:	8082                	ret

0000000080005772 <sys_read>:
{
    80005772:	7179                	addi	sp,sp,-48
    80005774:	f406                	sd	ra,40(sp)
    80005776:	f022                	sd	s0,32(sp)
    80005778:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000577a:	fe840613          	addi	a2,s0,-24
    8000577e:	4581                	li	a1,0
    80005780:	4501                	li	a0,0
    80005782:	00000097          	auipc	ra,0x0
    80005786:	d90080e7          	jalr	-624(ra) # 80005512 <argfd>
    return -1;
    8000578a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000578c:	04054163          	bltz	a0,800057ce <sys_read+0x5c>
    80005790:	fe440593          	addi	a1,s0,-28
    80005794:	4509                	li	a0,2
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	938080e7          	jalr	-1736(ra) # 800030ce <argint>
    return -1;
    8000579e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057a0:	02054763          	bltz	a0,800057ce <sys_read+0x5c>
    800057a4:	fd840593          	addi	a1,s0,-40
    800057a8:	4505                	li	a0,1
    800057aa:	ffffe097          	auipc	ra,0xffffe
    800057ae:	946080e7          	jalr	-1722(ra) # 800030f0 <argaddr>
    return -1;
    800057b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057b4:	00054d63          	bltz	a0,800057ce <sys_read+0x5c>
  return fileread(f, p, n);
    800057b8:	fe442603          	lw	a2,-28(s0)
    800057bc:	fd843583          	ld	a1,-40(s0)
    800057c0:	fe843503          	ld	a0,-24(s0)
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	49e080e7          	jalr	1182(ra) # 80004c62 <fileread>
    800057cc:	87aa                	mv	a5,a0
}
    800057ce:	853e                	mv	a0,a5
    800057d0:	70a2                	ld	ra,40(sp)
    800057d2:	7402                	ld	s0,32(sp)
    800057d4:	6145                	addi	sp,sp,48
    800057d6:	8082                	ret

00000000800057d8 <sys_write>:
{
    800057d8:	7179                	addi	sp,sp,-48
    800057da:	f406                	sd	ra,40(sp)
    800057dc:	f022                	sd	s0,32(sp)
    800057de:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057e0:	fe840613          	addi	a2,s0,-24
    800057e4:	4581                	li	a1,0
    800057e6:	4501                	li	a0,0
    800057e8:	00000097          	auipc	ra,0x0
    800057ec:	d2a080e7          	jalr	-726(ra) # 80005512 <argfd>
    return -1;
    800057f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057f2:	04054163          	bltz	a0,80005834 <sys_write+0x5c>
    800057f6:	fe440593          	addi	a1,s0,-28
    800057fa:	4509                	li	a0,2
    800057fc:	ffffe097          	auipc	ra,0xffffe
    80005800:	8d2080e7          	jalr	-1838(ra) # 800030ce <argint>
    return -1;
    80005804:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005806:	02054763          	bltz	a0,80005834 <sys_write+0x5c>
    8000580a:	fd840593          	addi	a1,s0,-40
    8000580e:	4505                	li	a0,1
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	8e0080e7          	jalr	-1824(ra) # 800030f0 <argaddr>
    return -1;
    80005818:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000581a:	00054d63          	bltz	a0,80005834 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000581e:	fe442603          	lw	a2,-28(s0)
    80005822:	fd843583          	ld	a1,-40(s0)
    80005826:	fe843503          	ld	a0,-24(s0)
    8000582a:	fffff097          	auipc	ra,0xfffff
    8000582e:	4fa080e7          	jalr	1274(ra) # 80004d24 <filewrite>
    80005832:	87aa                	mv	a5,a0
}
    80005834:	853e                	mv	a0,a5
    80005836:	70a2                	ld	ra,40(sp)
    80005838:	7402                	ld	s0,32(sp)
    8000583a:	6145                	addi	sp,sp,48
    8000583c:	8082                	ret

000000008000583e <sys_close>:
{
    8000583e:	1101                	addi	sp,sp,-32
    80005840:	ec06                	sd	ra,24(sp)
    80005842:	e822                	sd	s0,16(sp)
    80005844:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005846:	fe040613          	addi	a2,s0,-32
    8000584a:	fec40593          	addi	a1,s0,-20
    8000584e:	4501                	li	a0,0
    80005850:	00000097          	auipc	ra,0x0
    80005854:	cc2080e7          	jalr	-830(ra) # 80005512 <argfd>
    return -1;
    80005858:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000585a:	02054463          	bltz	a0,80005882 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000585e:	ffffc097          	auipc	ra,0xffffc
    80005862:	538080e7          	jalr	1336(ra) # 80001d96 <myproc>
    80005866:	fec42783          	lw	a5,-20(s0)
    8000586a:	07f9                	addi	a5,a5,30
    8000586c:	078e                	slli	a5,a5,0x3
    8000586e:	97aa                	add	a5,a5,a0
    80005870:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005874:	fe043503          	ld	a0,-32(s0)
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	2b0080e7          	jalr	688(ra) # 80004b28 <fileclose>
  return 0;
    80005880:	4781                	li	a5,0
}
    80005882:	853e                	mv	a0,a5
    80005884:	60e2                	ld	ra,24(sp)
    80005886:	6442                	ld	s0,16(sp)
    80005888:	6105                	addi	sp,sp,32
    8000588a:	8082                	ret

000000008000588c <sys_fstat>:
{
    8000588c:	1101                	addi	sp,sp,-32
    8000588e:	ec06                	sd	ra,24(sp)
    80005890:	e822                	sd	s0,16(sp)
    80005892:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005894:	fe840613          	addi	a2,s0,-24
    80005898:	4581                	li	a1,0
    8000589a:	4501                	li	a0,0
    8000589c:	00000097          	auipc	ra,0x0
    800058a0:	c76080e7          	jalr	-906(ra) # 80005512 <argfd>
    return -1;
    800058a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058a6:	02054563          	bltz	a0,800058d0 <sys_fstat+0x44>
    800058aa:	fe040593          	addi	a1,s0,-32
    800058ae:	4505                	li	a0,1
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	840080e7          	jalr	-1984(ra) # 800030f0 <argaddr>
    return -1;
    800058b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058ba:	00054b63          	bltz	a0,800058d0 <sys_fstat+0x44>
  return filestat(f, st);
    800058be:	fe043583          	ld	a1,-32(s0)
    800058c2:	fe843503          	ld	a0,-24(s0)
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	32a080e7          	jalr	810(ra) # 80004bf0 <filestat>
    800058ce:	87aa                	mv	a5,a0
}
    800058d0:	853e                	mv	a0,a5
    800058d2:	60e2                	ld	ra,24(sp)
    800058d4:	6442                	ld	s0,16(sp)
    800058d6:	6105                	addi	sp,sp,32
    800058d8:	8082                	ret

00000000800058da <sys_link>:
{
    800058da:	7169                	addi	sp,sp,-304
    800058dc:	f606                	sd	ra,296(sp)
    800058de:	f222                	sd	s0,288(sp)
    800058e0:	ee26                	sd	s1,280(sp)
    800058e2:	ea4a                	sd	s2,272(sp)
    800058e4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058e6:	08000613          	li	a2,128
    800058ea:	ed040593          	addi	a1,s0,-304
    800058ee:	4501                	li	a0,0
    800058f0:	ffffe097          	auipc	ra,0xffffe
    800058f4:	822080e7          	jalr	-2014(ra) # 80003112 <argstr>
    return -1;
    800058f8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058fa:	10054e63          	bltz	a0,80005a16 <sys_link+0x13c>
    800058fe:	08000613          	li	a2,128
    80005902:	f5040593          	addi	a1,s0,-176
    80005906:	4505                	li	a0,1
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	80a080e7          	jalr	-2038(ra) # 80003112 <argstr>
    return -1;
    80005910:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005912:	10054263          	bltz	a0,80005a16 <sys_link+0x13c>
  begin_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	d46080e7          	jalr	-698(ra) # 8000465c <begin_op>
  if((ip = namei(old)) == 0){
    8000591e:	ed040513          	addi	a0,s0,-304
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	b1e080e7          	jalr	-1250(ra) # 80004440 <namei>
    8000592a:	84aa                	mv	s1,a0
    8000592c:	c551                	beqz	a0,800059b8 <sys_link+0xde>
  ilock(ip);
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	35c080e7          	jalr	860(ra) # 80003c8a <ilock>
  if(ip->type == T_DIR){
    80005936:	04449703          	lh	a4,68(s1)
    8000593a:	4785                	li	a5,1
    8000593c:	08f70463          	beq	a4,a5,800059c4 <sys_link+0xea>
  ip->nlink++;
    80005940:	04a4d783          	lhu	a5,74(s1)
    80005944:	2785                	addiw	a5,a5,1
    80005946:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000594a:	8526                	mv	a0,s1
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	274080e7          	jalr	628(ra) # 80003bc0 <iupdate>
  iunlock(ip);
    80005954:	8526                	mv	a0,s1
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	3f6080e7          	jalr	1014(ra) # 80003d4c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000595e:	fd040593          	addi	a1,s0,-48
    80005962:	f5040513          	addi	a0,s0,-176
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	af8080e7          	jalr	-1288(ra) # 8000445e <nameiparent>
    8000596e:	892a                	mv	s2,a0
    80005970:	c935                	beqz	a0,800059e4 <sys_link+0x10a>
  ilock(dp);
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	318080e7          	jalr	792(ra) # 80003c8a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000597a:	00092703          	lw	a4,0(s2)
    8000597e:	409c                	lw	a5,0(s1)
    80005980:	04f71d63          	bne	a4,a5,800059da <sys_link+0x100>
    80005984:	40d0                	lw	a2,4(s1)
    80005986:	fd040593          	addi	a1,s0,-48
    8000598a:	854a                	mv	a0,s2
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	9f2080e7          	jalr	-1550(ra) # 8000437e <dirlink>
    80005994:	04054363          	bltz	a0,800059da <sys_link+0x100>
  iunlockput(dp);
    80005998:	854a                	mv	a0,s2
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	552080e7          	jalr	1362(ra) # 80003eec <iunlockput>
  iput(ip);
    800059a2:	8526                	mv	a0,s1
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	4a0080e7          	jalr	1184(ra) # 80003e44 <iput>
  end_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	d30080e7          	jalr	-720(ra) # 800046dc <end_op>
  return 0;
    800059b4:	4781                	li	a5,0
    800059b6:	a085                	j	80005a16 <sys_link+0x13c>
    end_op();
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	d24080e7          	jalr	-732(ra) # 800046dc <end_op>
    return -1;
    800059c0:	57fd                	li	a5,-1
    800059c2:	a891                	j	80005a16 <sys_link+0x13c>
    iunlockput(ip);
    800059c4:	8526                	mv	a0,s1
    800059c6:	ffffe097          	auipc	ra,0xffffe
    800059ca:	526080e7          	jalr	1318(ra) # 80003eec <iunlockput>
    end_op();
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	d0e080e7          	jalr	-754(ra) # 800046dc <end_op>
    return -1;
    800059d6:	57fd                	li	a5,-1
    800059d8:	a83d                	j	80005a16 <sys_link+0x13c>
    iunlockput(dp);
    800059da:	854a                	mv	a0,s2
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	510080e7          	jalr	1296(ra) # 80003eec <iunlockput>
  ilock(ip);
    800059e4:	8526                	mv	a0,s1
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	2a4080e7          	jalr	676(ra) # 80003c8a <ilock>
  ip->nlink--;
    800059ee:	04a4d783          	lhu	a5,74(s1)
    800059f2:	37fd                	addiw	a5,a5,-1
    800059f4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059f8:	8526                	mv	a0,s1
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	1c6080e7          	jalr	454(ra) # 80003bc0 <iupdate>
  iunlockput(ip);
    80005a02:	8526                	mv	a0,s1
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	4e8080e7          	jalr	1256(ra) # 80003eec <iunlockput>
  end_op();
    80005a0c:	fffff097          	auipc	ra,0xfffff
    80005a10:	cd0080e7          	jalr	-816(ra) # 800046dc <end_op>
  return -1;
    80005a14:	57fd                	li	a5,-1
}
    80005a16:	853e                	mv	a0,a5
    80005a18:	70b2                	ld	ra,296(sp)
    80005a1a:	7412                	ld	s0,288(sp)
    80005a1c:	64f2                	ld	s1,280(sp)
    80005a1e:	6952                	ld	s2,272(sp)
    80005a20:	6155                	addi	sp,sp,304
    80005a22:	8082                	ret

0000000080005a24 <sys_unlink>:
{
    80005a24:	7151                	addi	sp,sp,-240
    80005a26:	f586                	sd	ra,232(sp)
    80005a28:	f1a2                	sd	s0,224(sp)
    80005a2a:	eda6                	sd	s1,216(sp)
    80005a2c:	e9ca                	sd	s2,208(sp)
    80005a2e:	e5ce                	sd	s3,200(sp)
    80005a30:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a32:	08000613          	li	a2,128
    80005a36:	f3040593          	addi	a1,s0,-208
    80005a3a:	4501                	li	a0,0
    80005a3c:	ffffd097          	auipc	ra,0xffffd
    80005a40:	6d6080e7          	jalr	1750(ra) # 80003112 <argstr>
    80005a44:	18054163          	bltz	a0,80005bc6 <sys_unlink+0x1a2>
  begin_op();
    80005a48:	fffff097          	auipc	ra,0xfffff
    80005a4c:	c14080e7          	jalr	-1004(ra) # 8000465c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a50:	fb040593          	addi	a1,s0,-80
    80005a54:	f3040513          	addi	a0,s0,-208
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	a06080e7          	jalr	-1530(ra) # 8000445e <nameiparent>
    80005a60:	84aa                	mv	s1,a0
    80005a62:	c979                	beqz	a0,80005b38 <sys_unlink+0x114>
  ilock(dp);
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	226080e7          	jalr	550(ra) # 80003c8a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a6c:	00003597          	auipc	a1,0x3
    80005a70:	ce458593          	addi	a1,a1,-796 # 80008750 <syscalls+0x2c0>
    80005a74:	fb040513          	addi	a0,s0,-80
    80005a78:	ffffe097          	auipc	ra,0xffffe
    80005a7c:	6dc080e7          	jalr	1756(ra) # 80004154 <namecmp>
    80005a80:	14050a63          	beqz	a0,80005bd4 <sys_unlink+0x1b0>
    80005a84:	00003597          	auipc	a1,0x3
    80005a88:	cd458593          	addi	a1,a1,-812 # 80008758 <syscalls+0x2c8>
    80005a8c:	fb040513          	addi	a0,s0,-80
    80005a90:	ffffe097          	auipc	ra,0xffffe
    80005a94:	6c4080e7          	jalr	1732(ra) # 80004154 <namecmp>
    80005a98:	12050e63          	beqz	a0,80005bd4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a9c:	f2c40613          	addi	a2,s0,-212
    80005aa0:	fb040593          	addi	a1,s0,-80
    80005aa4:	8526                	mv	a0,s1
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	6c8080e7          	jalr	1736(ra) # 8000416e <dirlookup>
    80005aae:	892a                	mv	s2,a0
    80005ab0:	12050263          	beqz	a0,80005bd4 <sys_unlink+0x1b0>
  ilock(ip);
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	1d6080e7          	jalr	470(ra) # 80003c8a <ilock>
  if(ip->nlink < 1)
    80005abc:	04a91783          	lh	a5,74(s2)
    80005ac0:	08f05263          	blez	a5,80005b44 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005ac4:	04491703          	lh	a4,68(s2)
    80005ac8:	4785                	li	a5,1
    80005aca:	08f70563          	beq	a4,a5,80005b54 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005ace:	4641                	li	a2,16
    80005ad0:	4581                	li	a1,0
    80005ad2:	fc040513          	addi	a0,s0,-64
    80005ad6:	ffffb097          	auipc	ra,0xffffb
    80005ada:	22e080e7          	jalr	558(ra) # 80000d04 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ade:	4741                	li	a4,16
    80005ae0:	f2c42683          	lw	a3,-212(s0)
    80005ae4:	fc040613          	addi	a2,s0,-64
    80005ae8:	4581                	li	a1,0
    80005aea:	8526                	mv	a0,s1
    80005aec:	ffffe097          	auipc	ra,0xffffe
    80005af0:	54a080e7          	jalr	1354(ra) # 80004036 <writei>
    80005af4:	47c1                	li	a5,16
    80005af6:	0af51563          	bne	a0,a5,80005ba0 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005afa:	04491703          	lh	a4,68(s2)
    80005afe:	4785                	li	a5,1
    80005b00:	0af70863          	beq	a4,a5,80005bb0 <sys_unlink+0x18c>
  iunlockput(dp);
    80005b04:	8526                	mv	a0,s1
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	3e6080e7          	jalr	998(ra) # 80003eec <iunlockput>
  ip->nlink--;
    80005b0e:	04a95783          	lhu	a5,74(s2)
    80005b12:	37fd                	addiw	a5,a5,-1
    80005b14:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b18:	854a                	mv	a0,s2
    80005b1a:	ffffe097          	auipc	ra,0xffffe
    80005b1e:	0a6080e7          	jalr	166(ra) # 80003bc0 <iupdate>
  iunlockput(ip);
    80005b22:	854a                	mv	a0,s2
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	3c8080e7          	jalr	968(ra) # 80003eec <iunlockput>
  end_op();
    80005b2c:	fffff097          	auipc	ra,0xfffff
    80005b30:	bb0080e7          	jalr	-1104(ra) # 800046dc <end_op>
  return 0;
    80005b34:	4501                	li	a0,0
    80005b36:	a84d                	j	80005be8 <sys_unlink+0x1c4>
    end_op();
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	ba4080e7          	jalr	-1116(ra) # 800046dc <end_op>
    return -1;
    80005b40:	557d                	li	a0,-1
    80005b42:	a05d                	j	80005be8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b44:	00003517          	auipc	a0,0x3
    80005b48:	c3c50513          	addi	a0,a0,-964 # 80008780 <syscalls+0x2f0>
    80005b4c:	ffffb097          	auipc	ra,0xffffb
    80005b50:	9f2080e7          	jalr	-1550(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b54:	04c92703          	lw	a4,76(s2)
    80005b58:	02000793          	li	a5,32
    80005b5c:	f6e7f9e3          	bgeu	a5,a4,80005ace <sys_unlink+0xaa>
    80005b60:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b64:	4741                	li	a4,16
    80005b66:	86ce                	mv	a3,s3
    80005b68:	f1840613          	addi	a2,s0,-232
    80005b6c:	4581                	li	a1,0
    80005b6e:	854a                	mv	a0,s2
    80005b70:	ffffe097          	auipc	ra,0xffffe
    80005b74:	3ce080e7          	jalr	974(ra) # 80003f3e <readi>
    80005b78:	47c1                	li	a5,16
    80005b7a:	00f51b63          	bne	a0,a5,80005b90 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b7e:	f1845783          	lhu	a5,-232(s0)
    80005b82:	e7a1                	bnez	a5,80005bca <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b84:	29c1                	addiw	s3,s3,16
    80005b86:	04c92783          	lw	a5,76(s2)
    80005b8a:	fcf9ede3          	bltu	s3,a5,80005b64 <sys_unlink+0x140>
    80005b8e:	b781                	j	80005ace <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b90:	00003517          	auipc	a0,0x3
    80005b94:	c0850513          	addi	a0,a0,-1016 # 80008798 <syscalls+0x308>
    80005b98:	ffffb097          	auipc	ra,0xffffb
    80005b9c:	9a6080e7          	jalr	-1626(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005ba0:	00003517          	auipc	a0,0x3
    80005ba4:	c1050513          	addi	a0,a0,-1008 # 800087b0 <syscalls+0x320>
    80005ba8:	ffffb097          	auipc	ra,0xffffb
    80005bac:	996080e7          	jalr	-1642(ra) # 8000053e <panic>
    dp->nlink--;
    80005bb0:	04a4d783          	lhu	a5,74(s1)
    80005bb4:	37fd                	addiw	a5,a5,-1
    80005bb6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005bba:	8526                	mv	a0,s1
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	004080e7          	jalr	4(ra) # 80003bc0 <iupdate>
    80005bc4:	b781                	j	80005b04 <sys_unlink+0xe0>
    return -1;
    80005bc6:	557d                	li	a0,-1
    80005bc8:	a005                	j	80005be8 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005bca:	854a                	mv	a0,s2
    80005bcc:	ffffe097          	auipc	ra,0xffffe
    80005bd0:	320080e7          	jalr	800(ra) # 80003eec <iunlockput>
  iunlockput(dp);
    80005bd4:	8526                	mv	a0,s1
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	316080e7          	jalr	790(ra) # 80003eec <iunlockput>
  end_op();
    80005bde:	fffff097          	auipc	ra,0xfffff
    80005be2:	afe080e7          	jalr	-1282(ra) # 800046dc <end_op>
  return -1;
    80005be6:	557d                	li	a0,-1
}
    80005be8:	70ae                	ld	ra,232(sp)
    80005bea:	740e                	ld	s0,224(sp)
    80005bec:	64ee                	ld	s1,216(sp)
    80005bee:	694e                	ld	s2,208(sp)
    80005bf0:	69ae                	ld	s3,200(sp)
    80005bf2:	616d                	addi	sp,sp,240
    80005bf4:	8082                	ret

0000000080005bf6 <sys_open>:

uint64
sys_open(void)
{
    80005bf6:	7131                	addi	sp,sp,-192
    80005bf8:	fd06                	sd	ra,184(sp)
    80005bfa:	f922                	sd	s0,176(sp)
    80005bfc:	f526                	sd	s1,168(sp)
    80005bfe:	f14a                	sd	s2,160(sp)
    80005c00:	ed4e                	sd	s3,152(sp)
    80005c02:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c04:	08000613          	li	a2,128
    80005c08:	f5040593          	addi	a1,s0,-176
    80005c0c:	4501                	li	a0,0
    80005c0e:	ffffd097          	auipc	ra,0xffffd
    80005c12:	504080e7          	jalr	1284(ra) # 80003112 <argstr>
    return -1;
    80005c16:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c18:	0c054163          	bltz	a0,80005cda <sys_open+0xe4>
    80005c1c:	f4c40593          	addi	a1,s0,-180
    80005c20:	4505                	li	a0,1
    80005c22:	ffffd097          	auipc	ra,0xffffd
    80005c26:	4ac080e7          	jalr	1196(ra) # 800030ce <argint>
    80005c2a:	0a054863          	bltz	a0,80005cda <sys_open+0xe4>

  begin_op();
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	a2e080e7          	jalr	-1490(ra) # 8000465c <begin_op>

  if(omode & O_CREATE){
    80005c36:	f4c42783          	lw	a5,-180(s0)
    80005c3a:	2007f793          	andi	a5,a5,512
    80005c3e:	cbdd                	beqz	a5,80005cf4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c40:	4681                	li	a3,0
    80005c42:	4601                	li	a2,0
    80005c44:	4589                	li	a1,2
    80005c46:	f5040513          	addi	a0,s0,-176
    80005c4a:	00000097          	auipc	ra,0x0
    80005c4e:	972080e7          	jalr	-1678(ra) # 800055bc <create>
    80005c52:	892a                	mv	s2,a0
    if(ip == 0){
    80005c54:	c959                	beqz	a0,80005cea <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c56:	04491703          	lh	a4,68(s2)
    80005c5a:	478d                	li	a5,3
    80005c5c:	00f71763          	bne	a4,a5,80005c6a <sys_open+0x74>
    80005c60:	04695703          	lhu	a4,70(s2)
    80005c64:	47a5                	li	a5,9
    80005c66:	0ce7ec63          	bltu	a5,a4,80005d3e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c6a:	fffff097          	auipc	ra,0xfffff
    80005c6e:	e02080e7          	jalr	-510(ra) # 80004a6c <filealloc>
    80005c72:	89aa                	mv	s3,a0
    80005c74:	10050263          	beqz	a0,80005d78 <sys_open+0x182>
    80005c78:	00000097          	auipc	ra,0x0
    80005c7c:	902080e7          	jalr	-1790(ra) # 8000557a <fdalloc>
    80005c80:	84aa                	mv	s1,a0
    80005c82:	0e054663          	bltz	a0,80005d6e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c86:	04491703          	lh	a4,68(s2)
    80005c8a:	478d                	li	a5,3
    80005c8c:	0cf70463          	beq	a4,a5,80005d54 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c90:	4789                	li	a5,2
    80005c92:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c96:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c9a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c9e:	f4c42783          	lw	a5,-180(s0)
    80005ca2:	0017c713          	xori	a4,a5,1
    80005ca6:	8b05                	andi	a4,a4,1
    80005ca8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005cac:	0037f713          	andi	a4,a5,3
    80005cb0:	00e03733          	snez	a4,a4
    80005cb4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005cb8:	4007f793          	andi	a5,a5,1024
    80005cbc:	c791                	beqz	a5,80005cc8 <sys_open+0xd2>
    80005cbe:	04491703          	lh	a4,68(s2)
    80005cc2:	4789                	li	a5,2
    80005cc4:	08f70f63          	beq	a4,a5,80005d62 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005cc8:	854a                	mv	a0,s2
    80005cca:	ffffe097          	auipc	ra,0xffffe
    80005cce:	082080e7          	jalr	130(ra) # 80003d4c <iunlock>
  end_op();
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	a0a080e7          	jalr	-1526(ra) # 800046dc <end_op>

  return fd;
}
    80005cda:	8526                	mv	a0,s1
    80005cdc:	70ea                	ld	ra,184(sp)
    80005cde:	744a                	ld	s0,176(sp)
    80005ce0:	74aa                	ld	s1,168(sp)
    80005ce2:	790a                	ld	s2,160(sp)
    80005ce4:	69ea                	ld	s3,152(sp)
    80005ce6:	6129                	addi	sp,sp,192
    80005ce8:	8082                	ret
      end_op();
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	9f2080e7          	jalr	-1550(ra) # 800046dc <end_op>
      return -1;
    80005cf2:	b7e5                	j	80005cda <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005cf4:	f5040513          	addi	a0,s0,-176
    80005cf8:	ffffe097          	auipc	ra,0xffffe
    80005cfc:	748080e7          	jalr	1864(ra) # 80004440 <namei>
    80005d00:	892a                	mv	s2,a0
    80005d02:	c905                	beqz	a0,80005d32 <sys_open+0x13c>
    ilock(ip);
    80005d04:	ffffe097          	auipc	ra,0xffffe
    80005d08:	f86080e7          	jalr	-122(ra) # 80003c8a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d0c:	04491703          	lh	a4,68(s2)
    80005d10:	4785                	li	a5,1
    80005d12:	f4f712e3          	bne	a4,a5,80005c56 <sys_open+0x60>
    80005d16:	f4c42783          	lw	a5,-180(s0)
    80005d1a:	dba1                	beqz	a5,80005c6a <sys_open+0x74>
      iunlockput(ip);
    80005d1c:	854a                	mv	a0,s2
    80005d1e:	ffffe097          	auipc	ra,0xffffe
    80005d22:	1ce080e7          	jalr	462(ra) # 80003eec <iunlockput>
      end_op();
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	9b6080e7          	jalr	-1610(ra) # 800046dc <end_op>
      return -1;
    80005d2e:	54fd                	li	s1,-1
    80005d30:	b76d                	j	80005cda <sys_open+0xe4>
      end_op();
    80005d32:	fffff097          	auipc	ra,0xfffff
    80005d36:	9aa080e7          	jalr	-1622(ra) # 800046dc <end_op>
      return -1;
    80005d3a:	54fd                	li	s1,-1
    80005d3c:	bf79                	j	80005cda <sys_open+0xe4>
    iunlockput(ip);
    80005d3e:	854a                	mv	a0,s2
    80005d40:	ffffe097          	auipc	ra,0xffffe
    80005d44:	1ac080e7          	jalr	428(ra) # 80003eec <iunlockput>
    end_op();
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	994080e7          	jalr	-1644(ra) # 800046dc <end_op>
    return -1;
    80005d50:	54fd                	li	s1,-1
    80005d52:	b761                	j	80005cda <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d54:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d58:	04691783          	lh	a5,70(s2)
    80005d5c:	02f99223          	sh	a5,36(s3)
    80005d60:	bf2d                	j	80005c9a <sys_open+0xa4>
    itrunc(ip);
    80005d62:	854a                	mv	a0,s2
    80005d64:	ffffe097          	auipc	ra,0xffffe
    80005d68:	034080e7          	jalr	52(ra) # 80003d98 <itrunc>
    80005d6c:	bfb1                	j	80005cc8 <sys_open+0xd2>
      fileclose(f);
    80005d6e:	854e                	mv	a0,s3
    80005d70:	fffff097          	auipc	ra,0xfffff
    80005d74:	db8080e7          	jalr	-584(ra) # 80004b28 <fileclose>
    iunlockput(ip);
    80005d78:	854a                	mv	a0,s2
    80005d7a:	ffffe097          	auipc	ra,0xffffe
    80005d7e:	172080e7          	jalr	370(ra) # 80003eec <iunlockput>
    end_op();
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	95a080e7          	jalr	-1702(ra) # 800046dc <end_op>
    return -1;
    80005d8a:	54fd                	li	s1,-1
    80005d8c:	b7b9                	j	80005cda <sys_open+0xe4>

0000000080005d8e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d8e:	7175                	addi	sp,sp,-144
    80005d90:	e506                	sd	ra,136(sp)
    80005d92:	e122                	sd	s0,128(sp)
    80005d94:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	8c6080e7          	jalr	-1850(ra) # 8000465c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d9e:	08000613          	li	a2,128
    80005da2:	f7040593          	addi	a1,s0,-144
    80005da6:	4501                	li	a0,0
    80005da8:	ffffd097          	auipc	ra,0xffffd
    80005dac:	36a080e7          	jalr	874(ra) # 80003112 <argstr>
    80005db0:	02054963          	bltz	a0,80005de2 <sys_mkdir+0x54>
    80005db4:	4681                	li	a3,0
    80005db6:	4601                	li	a2,0
    80005db8:	4585                	li	a1,1
    80005dba:	f7040513          	addi	a0,s0,-144
    80005dbe:	fffff097          	auipc	ra,0xfffff
    80005dc2:	7fe080e7          	jalr	2046(ra) # 800055bc <create>
    80005dc6:	cd11                	beqz	a0,80005de2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005dc8:	ffffe097          	auipc	ra,0xffffe
    80005dcc:	124080e7          	jalr	292(ra) # 80003eec <iunlockput>
  end_op();
    80005dd0:	fffff097          	auipc	ra,0xfffff
    80005dd4:	90c080e7          	jalr	-1780(ra) # 800046dc <end_op>
  return 0;
    80005dd8:	4501                	li	a0,0
}
    80005dda:	60aa                	ld	ra,136(sp)
    80005ddc:	640a                	ld	s0,128(sp)
    80005dde:	6149                	addi	sp,sp,144
    80005de0:	8082                	ret
    end_op();
    80005de2:	fffff097          	auipc	ra,0xfffff
    80005de6:	8fa080e7          	jalr	-1798(ra) # 800046dc <end_op>
    return -1;
    80005dea:	557d                	li	a0,-1
    80005dec:	b7fd                	j	80005dda <sys_mkdir+0x4c>

0000000080005dee <sys_mknod>:

uint64
sys_mknod(void)
{
    80005dee:	7135                	addi	sp,sp,-160
    80005df0:	ed06                	sd	ra,152(sp)
    80005df2:	e922                	sd	s0,144(sp)
    80005df4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005df6:	fffff097          	auipc	ra,0xfffff
    80005dfa:	866080e7          	jalr	-1946(ra) # 8000465c <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005dfe:	08000613          	li	a2,128
    80005e02:	f7040593          	addi	a1,s0,-144
    80005e06:	4501                	li	a0,0
    80005e08:	ffffd097          	auipc	ra,0xffffd
    80005e0c:	30a080e7          	jalr	778(ra) # 80003112 <argstr>
    80005e10:	04054a63          	bltz	a0,80005e64 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005e14:	f6c40593          	addi	a1,s0,-148
    80005e18:	4505                	li	a0,1
    80005e1a:	ffffd097          	auipc	ra,0xffffd
    80005e1e:	2b4080e7          	jalr	692(ra) # 800030ce <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e22:	04054163          	bltz	a0,80005e64 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005e26:	f6840593          	addi	a1,s0,-152
    80005e2a:	4509                	li	a0,2
    80005e2c:	ffffd097          	auipc	ra,0xffffd
    80005e30:	2a2080e7          	jalr	674(ra) # 800030ce <argint>
     argint(1, &major) < 0 ||
    80005e34:	02054863          	bltz	a0,80005e64 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e38:	f6841683          	lh	a3,-152(s0)
    80005e3c:	f6c41603          	lh	a2,-148(s0)
    80005e40:	458d                	li	a1,3
    80005e42:	f7040513          	addi	a0,s0,-144
    80005e46:	fffff097          	auipc	ra,0xfffff
    80005e4a:	776080e7          	jalr	1910(ra) # 800055bc <create>
     argint(2, &minor) < 0 ||
    80005e4e:	c919                	beqz	a0,80005e64 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e50:	ffffe097          	auipc	ra,0xffffe
    80005e54:	09c080e7          	jalr	156(ra) # 80003eec <iunlockput>
  end_op();
    80005e58:	fffff097          	auipc	ra,0xfffff
    80005e5c:	884080e7          	jalr	-1916(ra) # 800046dc <end_op>
  return 0;
    80005e60:	4501                	li	a0,0
    80005e62:	a031                	j	80005e6e <sys_mknod+0x80>
    end_op();
    80005e64:	fffff097          	auipc	ra,0xfffff
    80005e68:	878080e7          	jalr	-1928(ra) # 800046dc <end_op>
    return -1;
    80005e6c:	557d                	li	a0,-1
}
    80005e6e:	60ea                	ld	ra,152(sp)
    80005e70:	644a                	ld	s0,144(sp)
    80005e72:	610d                	addi	sp,sp,160
    80005e74:	8082                	ret

0000000080005e76 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e76:	7135                	addi	sp,sp,-160
    80005e78:	ed06                	sd	ra,152(sp)
    80005e7a:	e922                	sd	s0,144(sp)
    80005e7c:	e526                	sd	s1,136(sp)
    80005e7e:	e14a                	sd	s2,128(sp)
    80005e80:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e82:	ffffc097          	auipc	ra,0xffffc
    80005e86:	f14080e7          	jalr	-236(ra) # 80001d96 <myproc>
    80005e8a:	892a                	mv	s2,a0
  
  begin_op();
    80005e8c:	ffffe097          	auipc	ra,0xffffe
    80005e90:	7d0080e7          	jalr	2000(ra) # 8000465c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e94:	08000613          	li	a2,128
    80005e98:	f6040593          	addi	a1,s0,-160
    80005e9c:	4501                	li	a0,0
    80005e9e:	ffffd097          	auipc	ra,0xffffd
    80005ea2:	274080e7          	jalr	628(ra) # 80003112 <argstr>
    80005ea6:	04054b63          	bltz	a0,80005efc <sys_chdir+0x86>
    80005eaa:	f6040513          	addi	a0,s0,-160
    80005eae:	ffffe097          	auipc	ra,0xffffe
    80005eb2:	592080e7          	jalr	1426(ra) # 80004440 <namei>
    80005eb6:	84aa                	mv	s1,a0
    80005eb8:	c131                	beqz	a0,80005efc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005eba:	ffffe097          	auipc	ra,0xffffe
    80005ebe:	dd0080e7          	jalr	-560(ra) # 80003c8a <ilock>
  if(ip->type != T_DIR){
    80005ec2:	04449703          	lh	a4,68(s1)
    80005ec6:	4785                	li	a5,1
    80005ec8:	04f71063          	bne	a4,a5,80005f08 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ecc:	8526                	mv	a0,s1
    80005ece:	ffffe097          	auipc	ra,0xffffe
    80005ed2:	e7e080e7          	jalr	-386(ra) # 80003d4c <iunlock>
  iput(p->cwd);
    80005ed6:	17093503          	ld	a0,368(s2)
    80005eda:	ffffe097          	auipc	ra,0xffffe
    80005ede:	f6a080e7          	jalr	-150(ra) # 80003e44 <iput>
  end_op();
    80005ee2:	ffffe097          	auipc	ra,0xffffe
    80005ee6:	7fa080e7          	jalr	2042(ra) # 800046dc <end_op>
  p->cwd = ip;
    80005eea:	16993823          	sd	s1,368(s2)
  return 0;
    80005eee:	4501                	li	a0,0
}
    80005ef0:	60ea                	ld	ra,152(sp)
    80005ef2:	644a                	ld	s0,144(sp)
    80005ef4:	64aa                	ld	s1,136(sp)
    80005ef6:	690a                	ld	s2,128(sp)
    80005ef8:	610d                	addi	sp,sp,160
    80005efa:	8082                	ret
    end_op();
    80005efc:	ffffe097          	auipc	ra,0xffffe
    80005f00:	7e0080e7          	jalr	2016(ra) # 800046dc <end_op>
    return -1;
    80005f04:	557d                	li	a0,-1
    80005f06:	b7ed                	j	80005ef0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005f08:	8526                	mv	a0,s1
    80005f0a:	ffffe097          	auipc	ra,0xffffe
    80005f0e:	fe2080e7          	jalr	-30(ra) # 80003eec <iunlockput>
    end_op();
    80005f12:	ffffe097          	auipc	ra,0xffffe
    80005f16:	7ca080e7          	jalr	1994(ra) # 800046dc <end_op>
    return -1;
    80005f1a:	557d                	li	a0,-1
    80005f1c:	bfd1                	j	80005ef0 <sys_chdir+0x7a>

0000000080005f1e <sys_exec>:

uint64
sys_exec(void)
{
    80005f1e:	7145                	addi	sp,sp,-464
    80005f20:	e786                	sd	ra,456(sp)
    80005f22:	e3a2                	sd	s0,448(sp)
    80005f24:	ff26                	sd	s1,440(sp)
    80005f26:	fb4a                	sd	s2,432(sp)
    80005f28:	f74e                	sd	s3,424(sp)
    80005f2a:	f352                	sd	s4,416(sp)
    80005f2c:	ef56                	sd	s5,408(sp)
    80005f2e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f30:	08000613          	li	a2,128
    80005f34:	f4040593          	addi	a1,s0,-192
    80005f38:	4501                	li	a0,0
    80005f3a:	ffffd097          	auipc	ra,0xffffd
    80005f3e:	1d8080e7          	jalr	472(ra) # 80003112 <argstr>
    return -1;
    80005f42:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f44:	0c054a63          	bltz	a0,80006018 <sys_exec+0xfa>
    80005f48:	e3840593          	addi	a1,s0,-456
    80005f4c:	4505                	li	a0,1
    80005f4e:	ffffd097          	auipc	ra,0xffffd
    80005f52:	1a2080e7          	jalr	418(ra) # 800030f0 <argaddr>
    80005f56:	0c054163          	bltz	a0,80006018 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005f5a:	10000613          	li	a2,256
    80005f5e:	4581                	li	a1,0
    80005f60:	e4040513          	addi	a0,s0,-448
    80005f64:	ffffb097          	auipc	ra,0xffffb
    80005f68:	da0080e7          	jalr	-608(ra) # 80000d04 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f6c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f70:	89a6                	mv	s3,s1
    80005f72:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f74:	02000a13          	li	s4,32
    80005f78:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f7c:	00391513          	slli	a0,s2,0x3
    80005f80:	e3040593          	addi	a1,s0,-464
    80005f84:	e3843783          	ld	a5,-456(s0)
    80005f88:	953e                	add	a0,a0,a5
    80005f8a:	ffffd097          	auipc	ra,0xffffd
    80005f8e:	0aa080e7          	jalr	170(ra) # 80003034 <fetchaddr>
    80005f92:	02054a63          	bltz	a0,80005fc6 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005f96:	e3043783          	ld	a5,-464(s0)
    80005f9a:	c3b9                	beqz	a5,80005fe0 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f9c:	ffffb097          	auipc	ra,0xffffb
    80005fa0:	b58080e7          	jalr	-1192(ra) # 80000af4 <kalloc>
    80005fa4:	85aa                	mv	a1,a0
    80005fa6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005faa:	cd11                	beqz	a0,80005fc6 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005fac:	6605                	lui	a2,0x1
    80005fae:	e3043503          	ld	a0,-464(s0)
    80005fb2:	ffffd097          	auipc	ra,0xffffd
    80005fb6:	0d4080e7          	jalr	212(ra) # 80003086 <fetchstr>
    80005fba:	00054663          	bltz	a0,80005fc6 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005fbe:	0905                	addi	s2,s2,1
    80005fc0:	09a1                	addi	s3,s3,8
    80005fc2:	fb491be3          	bne	s2,s4,80005f78 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fc6:	10048913          	addi	s2,s1,256
    80005fca:	6088                	ld	a0,0(s1)
    80005fcc:	c529                	beqz	a0,80006016 <sys_exec+0xf8>
    kfree(argv[i]);
    80005fce:	ffffb097          	auipc	ra,0xffffb
    80005fd2:	a2a080e7          	jalr	-1494(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fd6:	04a1                	addi	s1,s1,8
    80005fd8:	ff2499e3          	bne	s1,s2,80005fca <sys_exec+0xac>
  return -1;
    80005fdc:	597d                	li	s2,-1
    80005fde:	a82d                	j	80006018 <sys_exec+0xfa>
      argv[i] = 0;
    80005fe0:	0a8e                	slli	s5,s5,0x3
    80005fe2:	fc040793          	addi	a5,s0,-64
    80005fe6:	9abe                	add	s5,s5,a5
    80005fe8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005fec:	e4040593          	addi	a1,s0,-448
    80005ff0:	f4040513          	addi	a0,s0,-192
    80005ff4:	fffff097          	auipc	ra,0xfffff
    80005ff8:	194080e7          	jalr	404(ra) # 80005188 <exec>
    80005ffc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ffe:	10048993          	addi	s3,s1,256
    80006002:	6088                	ld	a0,0(s1)
    80006004:	c911                	beqz	a0,80006018 <sys_exec+0xfa>
    kfree(argv[i]);
    80006006:	ffffb097          	auipc	ra,0xffffb
    8000600a:	9f2080e7          	jalr	-1550(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000600e:	04a1                	addi	s1,s1,8
    80006010:	ff3499e3          	bne	s1,s3,80006002 <sys_exec+0xe4>
    80006014:	a011                	j	80006018 <sys_exec+0xfa>
  return -1;
    80006016:	597d                	li	s2,-1
}
    80006018:	854a                	mv	a0,s2
    8000601a:	60be                	ld	ra,456(sp)
    8000601c:	641e                	ld	s0,448(sp)
    8000601e:	74fa                	ld	s1,440(sp)
    80006020:	795a                	ld	s2,432(sp)
    80006022:	79ba                	ld	s3,424(sp)
    80006024:	7a1a                	ld	s4,416(sp)
    80006026:	6afa                	ld	s5,408(sp)
    80006028:	6179                	addi	sp,sp,464
    8000602a:	8082                	ret

000000008000602c <sys_pipe>:

uint64
sys_pipe(void)
{
    8000602c:	7139                	addi	sp,sp,-64
    8000602e:	fc06                	sd	ra,56(sp)
    80006030:	f822                	sd	s0,48(sp)
    80006032:	f426                	sd	s1,40(sp)
    80006034:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006036:	ffffc097          	auipc	ra,0xffffc
    8000603a:	d60080e7          	jalr	-672(ra) # 80001d96 <myproc>
    8000603e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006040:	fd840593          	addi	a1,s0,-40
    80006044:	4501                	li	a0,0
    80006046:	ffffd097          	auipc	ra,0xffffd
    8000604a:	0aa080e7          	jalr	170(ra) # 800030f0 <argaddr>
    return -1;
    8000604e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006050:	0e054063          	bltz	a0,80006130 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006054:	fc840593          	addi	a1,s0,-56
    80006058:	fd040513          	addi	a0,s0,-48
    8000605c:	fffff097          	auipc	ra,0xfffff
    80006060:	dfc080e7          	jalr	-516(ra) # 80004e58 <pipealloc>
    return -1;
    80006064:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006066:	0c054563          	bltz	a0,80006130 <sys_pipe+0x104>
  fd0 = -1;
    8000606a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000606e:	fd043503          	ld	a0,-48(s0)
    80006072:	fffff097          	auipc	ra,0xfffff
    80006076:	508080e7          	jalr	1288(ra) # 8000557a <fdalloc>
    8000607a:	fca42223          	sw	a0,-60(s0)
    8000607e:	08054c63          	bltz	a0,80006116 <sys_pipe+0xea>
    80006082:	fc843503          	ld	a0,-56(s0)
    80006086:	fffff097          	auipc	ra,0xfffff
    8000608a:	4f4080e7          	jalr	1268(ra) # 8000557a <fdalloc>
    8000608e:	fca42023          	sw	a0,-64(s0)
    80006092:	06054863          	bltz	a0,80006102 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006096:	4691                	li	a3,4
    80006098:	fc440613          	addi	a2,s0,-60
    8000609c:	fd843583          	ld	a1,-40(s0)
    800060a0:	78a8                	ld	a0,112(s1)
    800060a2:	ffffb097          	auipc	ra,0xffffb
    800060a6:	5f4080e7          	jalr	1524(ra) # 80001696 <copyout>
    800060aa:	02054063          	bltz	a0,800060ca <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800060ae:	4691                	li	a3,4
    800060b0:	fc040613          	addi	a2,s0,-64
    800060b4:	fd843583          	ld	a1,-40(s0)
    800060b8:	0591                	addi	a1,a1,4
    800060ba:	78a8                	ld	a0,112(s1)
    800060bc:	ffffb097          	auipc	ra,0xffffb
    800060c0:	5da080e7          	jalr	1498(ra) # 80001696 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800060c4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060c6:	06055563          	bgez	a0,80006130 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800060ca:	fc442783          	lw	a5,-60(s0)
    800060ce:	07f9                	addi	a5,a5,30
    800060d0:	078e                	slli	a5,a5,0x3
    800060d2:	97a6                	add	a5,a5,s1
    800060d4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800060d8:	fc042503          	lw	a0,-64(s0)
    800060dc:	0579                	addi	a0,a0,30
    800060de:	050e                	slli	a0,a0,0x3
    800060e0:	9526                	add	a0,a0,s1
    800060e2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800060e6:	fd043503          	ld	a0,-48(s0)
    800060ea:	fffff097          	auipc	ra,0xfffff
    800060ee:	a3e080e7          	jalr	-1474(ra) # 80004b28 <fileclose>
    fileclose(wf);
    800060f2:	fc843503          	ld	a0,-56(s0)
    800060f6:	fffff097          	auipc	ra,0xfffff
    800060fa:	a32080e7          	jalr	-1486(ra) # 80004b28 <fileclose>
    return -1;
    800060fe:	57fd                	li	a5,-1
    80006100:	a805                	j	80006130 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006102:	fc442783          	lw	a5,-60(s0)
    80006106:	0007c863          	bltz	a5,80006116 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000610a:	01e78513          	addi	a0,a5,30
    8000610e:	050e                	slli	a0,a0,0x3
    80006110:	9526                	add	a0,a0,s1
    80006112:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006116:	fd043503          	ld	a0,-48(s0)
    8000611a:	fffff097          	auipc	ra,0xfffff
    8000611e:	a0e080e7          	jalr	-1522(ra) # 80004b28 <fileclose>
    fileclose(wf);
    80006122:	fc843503          	ld	a0,-56(s0)
    80006126:	fffff097          	auipc	ra,0xfffff
    8000612a:	a02080e7          	jalr	-1534(ra) # 80004b28 <fileclose>
    return -1;
    8000612e:	57fd                	li	a5,-1
}
    80006130:	853e                	mv	a0,a5
    80006132:	70e2                	ld	ra,56(sp)
    80006134:	7442                	ld	s0,48(sp)
    80006136:	74a2                	ld	s1,40(sp)
    80006138:	6121                	addi	sp,sp,64
    8000613a:	8082                	ret
    8000613c:	0000                	unimp
	...

0000000080006140 <kernelvec>:
    80006140:	7111                	addi	sp,sp,-256
    80006142:	e006                	sd	ra,0(sp)
    80006144:	e40a                	sd	sp,8(sp)
    80006146:	e80e                	sd	gp,16(sp)
    80006148:	ec12                	sd	tp,24(sp)
    8000614a:	f016                	sd	t0,32(sp)
    8000614c:	f41a                	sd	t1,40(sp)
    8000614e:	f81e                	sd	t2,48(sp)
    80006150:	fc22                	sd	s0,56(sp)
    80006152:	e0a6                	sd	s1,64(sp)
    80006154:	e4aa                	sd	a0,72(sp)
    80006156:	e8ae                	sd	a1,80(sp)
    80006158:	ecb2                	sd	a2,88(sp)
    8000615a:	f0b6                	sd	a3,96(sp)
    8000615c:	f4ba                	sd	a4,104(sp)
    8000615e:	f8be                	sd	a5,112(sp)
    80006160:	fcc2                	sd	a6,120(sp)
    80006162:	e146                	sd	a7,128(sp)
    80006164:	e54a                	sd	s2,136(sp)
    80006166:	e94e                	sd	s3,144(sp)
    80006168:	ed52                	sd	s4,152(sp)
    8000616a:	f156                	sd	s5,160(sp)
    8000616c:	f55a                	sd	s6,168(sp)
    8000616e:	f95e                	sd	s7,176(sp)
    80006170:	fd62                	sd	s8,184(sp)
    80006172:	e1e6                	sd	s9,192(sp)
    80006174:	e5ea                	sd	s10,200(sp)
    80006176:	e9ee                	sd	s11,208(sp)
    80006178:	edf2                	sd	t3,216(sp)
    8000617a:	f1f6                	sd	t4,224(sp)
    8000617c:	f5fa                	sd	t5,232(sp)
    8000617e:	f9fe                	sd	t6,240(sp)
    80006180:	d81fc0ef          	jal	ra,80002f00 <kerneltrap>
    80006184:	6082                	ld	ra,0(sp)
    80006186:	6122                	ld	sp,8(sp)
    80006188:	61c2                	ld	gp,16(sp)
    8000618a:	7282                	ld	t0,32(sp)
    8000618c:	7322                	ld	t1,40(sp)
    8000618e:	73c2                	ld	t2,48(sp)
    80006190:	7462                	ld	s0,56(sp)
    80006192:	6486                	ld	s1,64(sp)
    80006194:	6526                	ld	a0,72(sp)
    80006196:	65c6                	ld	a1,80(sp)
    80006198:	6666                	ld	a2,88(sp)
    8000619a:	7686                	ld	a3,96(sp)
    8000619c:	7726                	ld	a4,104(sp)
    8000619e:	77c6                	ld	a5,112(sp)
    800061a0:	7866                	ld	a6,120(sp)
    800061a2:	688a                	ld	a7,128(sp)
    800061a4:	692a                	ld	s2,136(sp)
    800061a6:	69ca                	ld	s3,144(sp)
    800061a8:	6a6a                	ld	s4,152(sp)
    800061aa:	7a8a                	ld	s5,160(sp)
    800061ac:	7b2a                	ld	s6,168(sp)
    800061ae:	7bca                	ld	s7,176(sp)
    800061b0:	7c6a                	ld	s8,184(sp)
    800061b2:	6c8e                	ld	s9,192(sp)
    800061b4:	6d2e                	ld	s10,200(sp)
    800061b6:	6dce                	ld	s11,208(sp)
    800061b8:	6e6e                	ld	t3,216(sp)
    800061ba:	7e8e                	ld	t4,224(sp)
    800061bc:	7f2e                	ld	t5,232(sp)
    800061be:	7fce                	ld	t6,240(sp)
    800061c0:	6111                	addi	sp,sp,256
    800061c2:	10200073          	sret
    800061c6:	00000013          	nop
    800061ca:	00000013          	nop
    800061ce:	0001                	nop

00000000800061d0 <timervec>:
    800061d0:	34051573          	csrrw	a0,mscratch,a0
    800061d4:	e10c                	sd	a1,0(a0)
    800061d6:	e510                	sd	a2,8(a0)
    800061d8:	e914                	sd	a3,16(a0)
    800061da:	6d0c                	ld	a1,24(a0)
    800061dc:	7110                	ld	a2,32(a0)
    800061de:	6194                	ld	a3,0(a1)
    800061e0:	96b2                	add	a3,a3,a2
    800061e2:	e194                	sd	a3,0(a1)
    800061e4:	4589                	li	a1,2
    800061e6:	14459073          	csrw	sip,a1
    800061ea:	6914                	ld	a3,16(a0)
    800061ec:	6510                	ld	a2,8(a0)
    800061ee:	610c                	ld	a1,0(a0)
    800061f0:	34051573          	csrrw	a0,mscratch,a0
    800061f4:	30200073          	mret
	...

00000000800061fa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800061fa:	1141                	addi	sp,sp,-16
    800061fc:	e422                	sd	s0,8(sp)
    800061fe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006200:	0c0007b7          	lui	a5,0xc000
    80006204:	4705                	li	a4,1
    80006206:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006208:	c3d8                	sw	a4,4(a5)
}
    8000620a:	6422                	ld	s0,8(sp)
    8000620c:	0141                	addi	sp,sp,16
    8000620e:	8082                	ret

0000000080006210 <plicinithart>:

void
plicinithart(void)
{
    80006210:	1141                	addi	sp,sp,-16
    80006212:	e406                	sd	ra,8(sp)
    80006214:	e022                	sd	s0,0(sp)
    80006216:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006218:	ffffc097          	auipc	ra,0xffffc
    8000621c:	b4a080e7          	jalr	-1206(ra) # 80001d62 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006220:	0085171b          	slliw	a4,a0,0x8
    80006224:	0c0027b7          	lui	a5,0xc002
    80006228:	97ba                	add	a5,a5,a4
    8000622a:	40200713          	li	a4,1026
    8000622e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006232:	00d5151b          	slliw	a0,a0,0xd
    80006236:	0c2017b7          	lui	a5,0xc201
    8000623a:	953e                	add	a0,a0,a5
    8000623c:	00052023          	sw	zero,0(a0)
}
    80006240:	60a2                	ld	ra,8(sp)
    80006242:	6402                	ld	s0,0(sp)
    80006244:	0141                	addi	sp,sp,16
    80006246:	8082                	ret

0000000080006248 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006248:	1141                	addi	sp,sp,-16
    8000624a:	e406                	sd	ra,8(sp)
    8000624c:	e022                	sd	s0,0(sp)
    8000624e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006250:	ffffc097          	auipc	ra,0xffffc
    80006254:	b12080e7          	jalr	-1262(ra) # 80001d62 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006258:	00d5179b          	slliw	a5,a0,0xd
    8000625c:	0c201537          	lui	a0,0xc201
    80006260:	953e                	add	a0,a0,a5
  return irq;
}
    80006262:	4148                	lw	a0,4(a0)
    80006264:	60a2                	ld	ra,8(sp)
    80006266:	6402                	ld	s0,0(sp)
    80006268:	0141                	addi	sp,sp,16
    8000626a:	8082                	ret

000000008000626c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000626c:	1101                	addi	sp,sp,-32
    8000626e:	ec06                	sd	ra,24(sp)
    80006270:	e822                	sd	s0,16(sp)
    80006272:	e426                	sd	s1,8(sp)
    80006274:	1000                	addi	s0,sp,32
    80006276:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006278:	ffffc097          	auipc	ra,0xffffc
    8000627c:	aea080e7          	jalr	-1302(ra) # 80001d62 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006280:	00d5151b          	slliw	a0,a0,0xd
    80006284:	0c2017b7          	lui	a5,0xc201
    80006288:	97aa                	add	a5,a5,a0
    8000628a:	c3c4                	sw	s1,4(a5)
}
    8000628c:	60e2                	ld	ra,24(sp)
    8000628e:	6442                	ld	s0,16(sp)
    80006290:	64a2                	ld	s1,8(sp)
    80006292:	6105                	addi	sp,sp,32
    80006294:	8082                	ret

0000000080006296 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006296:	1141                	addi	sp,sp,-16
    80006298:	e406                	sd	ra,8(sp)
    8000629a:	e022                	sd	s0,0(sp)
    8000629c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000629e:	479d                	li	a5,7
    800062a0:	06a7c963          	blt	a5,a0,80006312 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800062a4:	0001d797          	auipc	a5,0x1d
    800062a8:	d5c78793          	addi	a5,a5,-676 # 80023000 <disk>
    800062ac:	00a78733          	add	a4,a5,a0
    800062b0:	6789                	lui	a5,0x2
    800062b2:	97ba                	add	a5,a5,a4
    800062b4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800062b8:	e7ad                	bnez	a5,80006322 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062ba:	00451793          	slli	a5,a0,0x4
    800062be:	0001f717          	auipc	a4,0x1f
    800062c2:	d4270713          	addi	a4,a4,-702 # 80025000 <disk+0x2000>
    800062c6:	6314                	ld	a3,0(a4)
    800062c8:	96be                	add	a3,a3,a5
    800062ca:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800062ce:	6314                	ld	a3,0(a4)
    800062d0:	96be                	add	a3,a3,a5
    800062d2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800062d6:	6314                	ld	a3,0(a4)
    800062d8:	96be                	add	a3,a3,a5
    800062da:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800062de:	6318                	ld	a4,0(a4)
    800062e0:	97ba                	add	a5,a5,a4
    800062e2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800062e6:	0001d797          	auipc	a5,0x1d
    800062ea:	d1a78793          	addi	a5,a5,-742 # 80023000 <disk>
    800062ee:	97aa                	add	a5,a5,a0
    800062f0:	6509                	lui	a0,0x2
    800062f2:	953e                	add	a0,a0,a5
    800062f4:	4785                	li	a5,1
    800062f6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800062fa:	0001f517          	auipc	a0,0x1f
    800062fe:	d1e50513          	addi	a0,a0,-738 # 80025018 <disk+0x2018>
    80006302:	ffffc097          	auipc	ra,0xffffc
    80006306:	2ba080e7          	jalr	698(ra) # 800025bc <wakeup>
}
    8000630a:	60a2                	ld	ra,8(sp)
    8000630c:	6402                	ld	s0,0(sp)
    8000630e:	0141                	addi	sp,sp,16
    80006310:	8082                	ret
    panic("free_desc 1");
    80006312:	00002517          	auipc	a0,0x2
    80006316:	4ae50513          	addi	a0,a0,1198 # 800087c0 <syscalls+0x330>
    8000631a:	ffffa097          	auipc	ra,0xffffa
    8000631e:	224080e7          	jalr	548(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006322:	00002517          	auipc	a0,0x2
    80006326:	4ae50513          	addi	a0,a0,1198 # 800087d0 <syscalls+0x340>
    8000632a:	ffffa097          	auipc	ra,0xffffa
    8000632e:	214080e7          	jalr	532(ra) # 8000053e <panic>

0000000080006332 <virtio_disk_init>:
{
    80006332:	1101                	addi	sp,sp,-32
    80006334:	ec06                	sd	ra,24(sp)
    80006336:	e822                	sd	s0,16(sp)
    80006338:	e426                	sd	s1,8(sp)
    8000633a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000633c:	00002597          	auipc	a1,0x2
    80006340:	4a458593          	addi	a1,a1,1188 # 800087e0 <syscalls+0x350>
    80006344:	0001f517          	auipc	a0,0x1f
    80006348:	de450513          	addi	a0,a0,-540 # 80025128 <disk+0x2128>
    8000634c:	ffffb097          	auipc	ra,0xffffb
    80006350:	808080e7          	jalr	-2040(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006354:	100017b7          	lui	a5,0x10001
    80006358:	4398                	lw	a4,0(a5)
    8000635a:	2701                	sext.w	a4,a4
    8000635c:	747277b7          	lui	a5,0x74727
    80006360:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006364:	0ef71163          	bne	a4,a5,80006446 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006368:	100017b7          	lui	a5,0x10001
    8000636c:	43dc                	lw	a5,4(a5)
    8000636e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006370:	4705                	li	a4,1
    80006372:	0ce79a63          	bne	a5,a4,80006446 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006376:	100017b7          	lui	a5,0x10001
    8000637a:	479c                	lw	a5,8(a5)
    8000637c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000637e:	4709                	li	a4,2
    80006380:	0ce79363          	bne	a5,a4,80006446 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006384:	100017b7          	lui	a5,0x10001
    80006388:	47d8                	lw	a4,12(a5)
    8000638a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000638c:	554d47b7          	lui	a5,0x554d4
    80006390:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006394:	0af71963          	bne	a4,a5,80006446 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006398:	100017b7          	lui	a5,0x10001
    8000639c:	4705                	li	a4,1
    8000639e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063a0:	470d                	li	a4,3
    800063a2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800063a4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800063a6:	c7ffe737          	lui	a4,0xc7ffe
    800063aa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800063ae:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800063b0:	2701                	sext.w	a4,a4
    800063b2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063b4:	472d                	li	a4,11
    800063b6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063b8:	473d                	li	a4,15
    800063ba:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800063bc:	6705                	lui	a4,0x1
    800063be:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800063c0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063c4:	5bdc                	lw	a5,52(a5)
    800063c6:	2781                	sext.w	a5,a5
  if(max == 0)
    800063c8:	c7d9                	beqz	a5,80006456 <virtio_disk_init+0x124>
  if(max < NUM)
    800063ca:	471d                	li	a4,7
    800063cc:	08f77d63          	bgeu	a4,a5,80006466 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800063d0:	100014b7          	lui	s1,0x10001
    800063d4:	47a1                	li	a5,8
    800063d6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800063d8:	6609                	lui	a2,0x2
    800063da:	4581                	li	a1,0
    800063dc:	0001d517          	auipc	a0,0x1d
    800063e0:	c2450513          	addi	a0,a0,-988 # 80023000 <disk>
    800063e4:	ffffb097          	auipc	ra,0xffffb
    800063e8:	920080e7          	jalr	-1760(ra) # 80000d04 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800063ec:	0001d717          	auipc	a4,0x1d
    800063f0:	c1470713          	addi	a4,a4,-1004 # 80023000 <disk>
    800063f4:	00c75793          	srli	a5,a4,0xc
    800063f8:	2781                	sext.w	a5,a5
    800063fa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800063fc:	0001f797          	auipc	a5,0x1f
    80006400:	c0478793          	addi	a5,a5,-1020 # 80025000 <disk+0x2000>
    80006404:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006406:	0001d717          	auipc	a4,0x1d
    8000640a:	c7a70713          	addi	a4,a4,-902 # 80023080 <disk+0x80>
    8000640e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006410:	0001e717          	auipc	a4,0x1e
    80006414:	bf070713          	addi	a4,a4,-1040 # 80024000 <disk+0x1000>
    80006418:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000641a:	4705                	li	a4,1
    8000641c:	00e78c23          	sb	a4,24(a5)
    80006420:	00e78ca3          	sb	a4,25(a5)
    80006424:	00e78d23          	sb	a4,26(a5)
    80006428:	00e78da3          	sb	a4,27(a5)
    8000642c:	00e78e23          	sb	a4,28(a5)
    80006430:	00e78ea3          	sb	a4,29(a5)
    80006434:	00e78f23          	sb	a4,30(a5)
    80006438:	00e78fa3          	sb	a4,31(a5)
}
    8000643c:	60e2                	ld	ra,24(sp)
    8000643e:	6442                	ld	s0,16(sp)
    80006440:	64a2                	ld	s1,8(sp)
    80006442:	6105                	addi	sp,sp,32
    80006444:	8082                	ret
    panic("could not find virtio disk");
    80006446:	00002517          	auipc	a0,0x2
    8000644a:	3aa50513          	addi	a0,a0,938 # 800087f0 <syscalls+0x360>
    8000644e:	ffffa097          	auipc	ra,0xffffa
    80006452:	0f0080e7          	jalr	240(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006456:	00002517          	auipc	a0,0x2
    8000645a:	3ba50513          	addi	a0,a0,954 # 80008810 <syscalls+0x380>
    8000645e:	ffffa097          	auipc	ra,0xffffa
    80006462:	0e0080e7          	jalr	224(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006466:	00002517          	auipc	a0,0x2
    8000646a:	3ca50513          	addi	a0,a0,970 # 80008830 <syscalls+0x3a0>
    8000646e:	ffffa097          	auipc	ra,0xffffa
    80006472:	0d0080e7          	jalr	208(ra) # 8000053e <panic>

0000000080006476 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006476:	7159                	addi	sp,sp,-112
    80006478:	f486                	sd	ra,104(sp)
    8000647a:	f0a2                	sd	s0,96(sp)
    8000647c:	eca6                	sd	s1,88(sp)
    8000647e:	e8ca                	sd	s2,80(sp)
    80006480:	e4ce                	sd	s3,72(sp)
    80006482:	e0d2                	sd	s4,64(sp)
    80006484:	fc56                	sd	s5,56(sp)
    80006486:	f85a                	sd	s6,48(sp)
    80006488:	f45e                	sd	s7,40(sp)
    8000648a:	f062                	sd	s8,32(sp)
    8000648c:	ec66                	sd	s9,24(sp)
    8000648e:	e86a                	sd	s10,16(sp)
    80006490:	1880                	addi	s0,sp,112
    80006492:	892a                	mv	s2,a0
    80006494:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006496:	00c52c83          	lw	s9,12(a0)
    8000649a:	001c9c9b          	slliw	s9,s9,0x1
    8000649e:	1c82                	slli	s9,s9,0x20
    800064a0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800064a4:	0001f517          	auipc	a0,0x1f
    800064a8:	c8450513          	addi	a0,a0,-892 # 80025128 <disk+0x2128>
    800064ac:	ffffa097          	auipc	ra,0xffffa
    800064b0:	738080e7          	jalr	1848(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800064b4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800064b6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800064b8:	0001db97          	auipc	s7,0x1d
    800064bc:	b48b8b93          	addi	s7,s7,-1208 # 80023000 <disk>
    800064c0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800064c2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800064c4:	8a4e                	mv	s4,s3
    800064c6:	a051                	j	8000654a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800064c8:	00fb86b3          	add	a3,s7,a5
    800064cc:	96da                	add	a3,a3,s6
    800064ce:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800064d2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800064d4:	0207c563          	bltz	a5,800064fe <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800064d8:	2485                	addiw	s1,s1,1
    800064da:	0711                	addi	a4,a4,4
    800064dc:	25548063          	beq	s1,s5,8000671c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800064e0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800064e2:	0001f697          	auipc	a3,0x1f
    800064e6:	b3668693          	addi	a3,a3,-1226 # 80025018 <disk+0x2018>
    800064ea:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800064ec:	0006c583          	lbu	a1,0(a3)
    800064f0:	fde1                	bnez	a1,800064c8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800064f2:	2785                	addiw	a5,a5,1
    800064f4:	0685                	addi	a3,a3,1
    800064f6:	ff879be3          	bne	a5,s8,800064ec <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800064fa:	57fd                	li	a5,-1
    800064fc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800064fe:	02905a63          	blez	s1,80006532 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006502:	f9042503          	lw	a0,-112(s0)
    80006506:	00000097          	auipc	ra,0x0
    8000650a:	d90080e7          	jalr	-624(ra) # 80006296 <free_desc>
      for(int j = 0; j < i; j++)
    8000650e:	4785                	li	a5,1
    80006510:	0297d163          	bge	a5,s1,80006532 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006514:	f9442503          	lw	a0,-108(s0)
    80006518:	00000097          	auipc	ra,0x0
    8000651c:	d7e080e7          	jalr	-642(ra) # 80006296 <free_desc>
      for(int j = 0; j < i; j++)
    80006520:	4789                	li	a5,2
    80006522:	0097d863          	bge	a5,s1,80006532 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006526:	f9842503          	lw	a0,-104(s0)
    8000652a:	00000097          	auipc	ra,0x0
    8000652e:	d6c080e7          	jalr	-660(ra) # 80006296 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006532:	0001f597          	auipc	a1,0x1f
    80006536:	bf658593          	addi	a1,a1,-1034 # 80025128 <disk+0x2128>
    8000653a:	0001f517          	auipc	a0,0x1f
    8000653e:	ade50513          	addi	a0,a0,-1314 # 80025018 <disk+0x2018>
    80006542:	ffffc097          	auipc	ra,0xffffc
    80006546:	ed4080e7          	jalr	-300(ra) # 80002416 <sleep>
  for(int i = 0; i < 3; i++){
    8000654a:	f9040713          	addi	a4,s0,-112
    8000654e:	84ce                	mv	s1,s3
    80006550:	bf41                	j	800064e0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006552:	20058713          	addi	a4,a1,512
    80006556:	00471693          	slli	a3,a4,0x4
    8000655a:	0001d717          	auipc	a4,0x1d
    8000655e:	aa670713          	addi	a4,a4,-1370 # 80023000 <disk>
    80006562:	9736                	add	a4,a4,a3
    80006564:	4685                	li	a3,1
    80006566:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000656a:	20058713          	addi	a4,a1,512
    8000656e:	00471693          	slli	a3,a4,0x4
    80006572:	0001d717          	auipc	a4,0x1d
    80006576:	a8e70713          	addi	a4,a4,-1394 # 80023000 <disk>
    8000657a:	9736                	add	a4,a4,a3
    8000657c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006580:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006584:	7679                	lui	a2,0xffffe
    80006586:	963e                	add	a2,a2,a5
    80006588:	0001f697          	auipc	a3,0x1f
    8000658c:	a7868693          	addi	a3,a3,-1416 # 80025000 <disk+0x2000>
    80006590:	6298                	ld	a4,0(a3)
    80006592:	9732                	add	a4,a4,a2
    80006594:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006596:	6298                	ld	a4,0(a3)
    80006598:	9732                	add	a4,a4,a2
    8000659a:	4541                	li	a0,16
    8000659c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000659e:	6298                	ld	a4,0(a3)
    800065a0:	9732                	add	a4,a4,a2
    800065a2:	4505                	li	a0,1
    800065a4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800065a8:	f9442703          	lw	a4,-108(s0)
    800065ac:	6288                	ld	a0,0(a3)
    800065ae:	962a                	add	a2,a2,a0
    800065b0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800065b4:	0712                	slli	a4,a4,0x4
    800065b6:	6290                	ld	a2,0(a3)
    800065b8:	963a                	add	a2,a2,a4
    800065ba:	05890513          	addi	a0,s2,88
    800065be:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800065c0:	6294                	ld	a3,0(a3)
    800065c2:	96ba                	add	a3,a3,a4
    800065c4:	40000613          	li	a2,1024
    800065c8:	c690                	sw	a2,8(a3)
  if(write)
    800065ca:	140d0063          	beqz	s10,8000670a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800065ce:	0001f697          	auipc	a3,0x1f
    800065d2:	a326b683          	ld	a3,-1486(a3) # 80025000 <disk+0x2000>
    800065d6:	96ba                	add	a3,a3,a4
    800065d8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800065dc:	0001d817          	auipc	a6,0x1d
    800065e0:	a2480813          	addi	a6,a6,-1500 # 80023000 <disk>
    800065e4:	0001f517          	auipc	a0,0x1f
    800065e8:	a1c50513          	addi	a0,a0,-1508 # 80025000 <disk+0x2000>
    800065ec:	6114                	ld	a3,0(a0)
    800065ee:	96ba                	add	a3,a3,a4
    800065f0:	00c6d603          	lhu	a2,12(a3)
    800065f4:	00166613          	ori	a2,a2,1
    800065f8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800065fc:	f9842683          	lw	a3,-104(s0)
    80006600:	6110                	ld	a2,0(a0)
    80006602:	9732                	add	a4,a4,a2
    80006604:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006608:	20058613          	addi	a2,a1,512
    8000660c:	0612                	slli	a2,a2,0x4
    8000660e:	9642                	add	a2,a2,a6
    80006610:	577d                	li	a4,-1
    80006612:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006616:	00469713          	slli	a4,a3,0x4
    8000661a:	6114                	ld	a3,0(a0)
    8000661c:	96ba                	add	a3,a3,a4
    8000661e:	03078793          	addi	a5,a5,48
    80006622:	97c2                	add	a5,a5,a6
    80006624:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006626:	611c                	ld	a5,0(a0)
    80006628:	97ba                	add	a5,a5,a4
    8000662a:	4685                	li	a3,1
    8000662c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000662e:	611c                	ld	a5,0(a0)
    80006630:	97ba                	add	a5,a5,a4
    80006632:	4809                	li	a6,2
    80006634:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006638:	611c                	ld	a5,0(a0)
    8000663a:	973e                	add	a4,a4,a5
    8000663c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006640:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006644:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006648:	6518                	ld	a4,8(a0)
    8000664a:	00275783          	lhu	a5,2(a4)
    8000664e:	8b9d                	andi	a5,a5,7
    80006650:	0786                	slli	a5,a5,0x1
    80006652:	97ba                	add	a5,a5,a4
    80006654:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006658:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000665c:	6518                	ld	a4,8(a0)
    8000665e:	00275783          	lhu	a5,2(a4)
    80006662:	2785                	addiw	a5,a5,1
    80006664:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006668:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000666c:	100017b7          	lui	a5,0x10001
    80006670:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006674:	00492703          	lw	a4,4(s2)
    80006678:	4785                	li	a5,1
    8000667a:	02f71163          	bne	a4,a5,8000669c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000667e:	0001f997          	auipc	s3,0x1f
    80006682:	aaa98993          	addi	s3,s3,-1366 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006686:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006688:	85ce                	mv	a1,s3
    8000668a:	854a                	mv	a0,s2
    8000668c:	ffffc097          	auipc	ra,0xffffc
    80006690:	d8a080e7          	jalr	-630(ra) # 80002416 <sleep>
  while(b->disk == 1) {
    80006694:	00492783          	lw	a5,4(s2)
    80006698:	fe9788e3          	beq	a5,s1,80006688 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000669c:	f9042903          	lw	s2,-112(s0)
    800066a0:	20090793          	addi	a5,s2,512
    800066a4:	00479713          	slli	a4,a5,0x4
    800066a8:	0001d797          	auipc	a5,0x1d
    800066ac:	95878793          	addi	a5,a5,-1704 # 80023000 <disk>
    800066b0:	97ba                	add	a5,a5,a4
    800066b2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800066b6:	0001f997          	auipc	s3,0x1f
    800066ba:	94a98993          	addi	s3,s3,-1718 # 80025000 <disk+0x2000>
    800066be:	00491713          	slli	a4,s2,0x4
    800066c2:	0009b783          	ld	a5,0(s3)
    800066c6:	97ba                	add	a5,a5,a4
    800066c8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800066cc:	854a                	mv	a0,s2
    800066ce:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800066d2:	00000097          	auipc	ra,0x0
    800066d6:	bc4080e7          	jalr	-1084(ra) # 80006296 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800066da:	8885                	andi	s1,s1,1
    800066dc:	f0ed                	bnez	s1,800066be <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800066de:	0001f517          	auipc	a0,0x1f
    800066e2:	a4a50513          	addi	a0,a0,-1462 # 80025128 <disk+0x2128>
    800066e6:	ffffa097          	auipc	ra,0xffffa
    800066ea:	5c4080e7          	jalr	1476(ra) # 80000caa <release>
}
    800066ee:	70a6                	ld	ra,104(sp)
    800066f0:	7406                	ld	s0,96(sp)
    800066f2:	64e6                	ld	s1,88(sp)
    800066f4:	6946                	ld	s2,80(sp)
    800066f6:	69a6                	ld	s3,72(sp)
    800066f8:	6a06                	ld	s4,64(sp)
    800066fa:	7ae2                	ld	s5,56(sp)
    800066fc:	7b42                	ld	s6,48(sp)
    800066fe:	7ba2                	ld	s7,40(sp)
    80006700:	7c02                	ld	s8,32(sp)
    80006702:	6ce2                	ld	s9,24(sp)
    80006704:	6d42                	ld	s10,16(sp)
    80006706:	6165                	addi	sp,sp,112
    80006708:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000670a:	0001f697          	auipc	a3,0x1f
    8000670e:	8f66b683          	ld	a3,-1802(a3) # 80025000 <disk+0x2000>
    80006712:	96ba                	add	a3,a3,a4
    80006714:	4609                	li	a2,2
    80006716:	00c69623          	sh	a2,12(a3)
    8000671a:	b5c9                	j	800065dc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000671c:	f9042583          	lw	a1,-112(s0)
    80006720:	20058793          	addi	a5,a1,512
    80006724:	0792                	slli	a5,a5,0x4
    80006726:	0001d517          	auipc	a0,0x1d
    8000672a:	98250513          	addi	a0,a0,-1662 # 800230a8 <disk+0xa8>
    8000672e:	953e                	add	a0,a0,a5
  if(write)
    80006730:	e20d11e3          	bnez	s10,80006552 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006734:	20058713          	addi	a4,a1,512
    80006738:	00471693          	slli	a3,a4,0x4
    8000673c:	0001d717          	auipc	a4,0x1d
    80006740:	8c470713          	addi	a4,a4,-1852 # 80023000 <disk>
    80006744:	9736                	add	a4,a4,a3
    80006746:	0a072423          	sw	zero,168(a4)
    8000674a:	b505                	j	8000656a <virtio_disk_rw+0xf4>

000000008000674c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000674c:	1101                	addi	sp,sp,-32
    8000674e:	ec06                	sd	ra,24(sp)
    80006750:	e822                	sd	s0,16(sp)
    80006752:	e426                	sd	s1,8(sp)
    80006754:	e04a                	sd	s2,0(sp)
    80006756:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006758:	0001f517          	auipc	a0,0x1f
    8000675c:	9d050513          	addi	a0,a0,-1584 # 80025128 <disk+0x2128>
    80006760:	ffffa097          	auipc	ra,0xffffa
    80006764:	484080e7          	jalr	1156(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006768:	10001737          	lui	a4,0x10001
    8000676c:	533c                	lw	a5,96(a4)
    8000676e:	8b8d                	andi	a5,a5,3
    80006770:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006772:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006776:	0001f797          	auipc	a5,0x1f
    8000677a:	88a78793          	addi	a5,a5,-1910 # 80025000 <disk+0x2000>
    8000677e:	6b94                	ld	a3,16(a5)
    80006780:	0207d703          	lhu	a4,32(a5)
    80006784:	0026d783          	lhu	a5,2(a3)
    80006788:	06f70163          	beq	a4,a5,800067ea <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000678c:	0001d917          	auipc	s2,0x1d
    80006790:	87490913          	addi	s2,s2,-1932 # 80023000 <disk>
    80006794:	0001f497          	auipc	s1,0x1f
    80006798:	86c48493          	addi	s1,s1,-1940 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000679c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067a0:	6898                	ld	a4,16(s1)
    800067a2:	0204d783          	lhu	a5,32(s1)
    800067a6:	8b9d                	andi	a5,a5,7
    800067a8:	078e                	slli	a5,a5,0x3
    800067aa:	97ba                	add	a5,a5,a4
    800067ac:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800067ae:	20078713          	addi	a4,a5,512
    800067b2:	0712                	slli	a4,a4,0x4
    800067b4:	974a                	add	a4,a4,s2
    800067b6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800067ba:	e731                	bnez	a4,80006806 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800067bc:	20078793          	addi	a5,a5,512
    800067c0:	0792                	slli	a5,a5,0x4
    800067c2:	97ca                	add	a5,a5,s2
    800067c4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800067c6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800067ca:	ffffc097          	auipc	ra,0xffffc
    800067ce:	df2080e7          	jalr	-526(ra) # 800025bc <wakeup>

    disk.used_idx += 1;
    800067d2:	0204d783          	lhu	a5,32(s1)
    800067d6:	2785                	addiw	a5,a5,1
    800067d8:	17c2                	slli	a5,a5,0x30
    800067da:	93c1                	srli	a5,a5,0x30
    800067dc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800067e0:	6898                	ld	a4,16(s1)
    800067e2:	00275703          	lhu	a4,2(a4)
    800067e6:	faf71be3          	bne	a4,a5,8000679c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800067ea:	0001f517          	auipc	a0,0x1f
    800067ee:	93e50513          	addi	a0,a0,-1730 # 80025128 <disk+0x2128>
    800067f2:	ffffa097          	auipc	ra,0xffffa
    800067f6:	4b8080e7          	jalr	1208(ra) # 80000caa <release>
}
    800067fa:	60e2                	ld	ra,24(sp)
    800067fc:	6442                	ld	s0,16(sp)
    800067fe:	64a2                	ld	s1,8(sp)
    80006800:	6902                	ld	s2,0(sp)
    80006802:	6105                	addi	sp,sp,32
    80006804:	8082                	ret
      panic("virtio_disk_intr status");
    80006806:	00002517          	auipc	a0,0x2
    8000680a:	04a50513          	addi	a0,a0,74 # 80008850 <syscalls+0x3c0>
    8000680e:	ffffa097          	auipc	ra,0xffffa
    80006812:	d30080e7          	jalr	-720(ra) # 8000053e <panic>

0000000080006816 <cas>:
    80006816:	100522af          	lr.w	t0,(a0)
    8000681a:	00b29563          	bne	t0,a1,80006824 <fail>
    8000681e:	18c5252f          	sc.w	a0,a2,(a0)
    80006822:	8082                	ret

0000000080006824 <fail>:
    80006824:	4505                	li	a0,1
    80006826:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
