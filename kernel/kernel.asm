
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8b013103          	ld	sp,-1872(sp) # 800088b0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	44c78793          	addi	a5,a5,1100 # 800064b0 <timervec>
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
    800000b2:	e1278793          	addi	a5,a5,-494 # 80000ec0 <main>
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
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	bec080e7          	jalr	-1044(ra) # 80002d18 <either_copyin>
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
    80000198:	a58080e7          	jalr	-1448(ra) # 80000bec <acquire>
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
    800001c8:	c98080e7          	jalr	-872(ra) # 80001e5c <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	516080e7          	jalr	1302(ra) # 800026ea <sleep>
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
    80000210:	00003097          	auipc	ra,0x3
    80000214:	ab2080e7          	jalr	-1358(ra) # 80002cc2 <either_copyout>
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
    80000230:	a8c080e7          	jalr	-1396(ra) # 80000cb8 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a76080e7          	jalr	-1418(ra) # 80000cb8 <release>
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
    800002d8:	918080e7          	jalr	-1768(ra) # 80000bec <acquire>

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
    800002f2:	00003097          	auipc	ra,0x3
    800002f6:	a7c080e7          	jalr	-1412(ra) # 80002d6e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	9b6080e7          	jalr	-1610(ra) # 80000cb8 <release>
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
    8000044a:	596080e7          	jalr	1430(ra) # 800029dc <wakeup>
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
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	86878793          	addi	a5,a5,-1944 # 80021ce0 <devsw>
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
    80000604:	5ec080e7          	jalr	1516(ra) # 80000bec <acquire>
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
    80000768:	554080e7          	jalr	1364(ra) # 80000cb8 <release>
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
    80000832:	424080e7          	jalr	1060(ra) # 80000c52 <pop_off>
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
    800008a4:	13c080e7          	jalr	316(ra) # 800029dc <wakeup>
    
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
    800008e8:	308080e7          	jalr	776(ra) # 80000bec <acquire>
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
    80000930:	dbe080e7          	jalr	-578(ra) # 800026ea <sleep>
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
    8000096c:	350080e7          	jalr	848(ra) # 80000cb8 <release>
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
    800009d8:	218080e7          	jalr	536(ra) # 80000bec <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2d2080e7          	jalr	722(ra) # 80000cb8 <release>
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
    80000a28:	2ee080e7          	jalr	750(ra) # 80000d12 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1b6080e7          	jalr	438(ra) # 80000bec <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	26e080e7          	jalr	622(ra) # 80000cb8 <release>
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
    80000b0c:	0e4080e7          	jalr	228(ra) # 80000bec <acquire>
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
    80000b24:	198080e7          	jalr	408(ra) # 80000cb8 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1e4080e7          	jalr	484(ra) # 80000d12 <memset>
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
    80000b4e:	16e080e7          	jalr	366(ra) # 80000cb8 <release>
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
    80000b82:	2bc080e7          	jalr	700(ra) # 80001e3a <mycpu>
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
    80000bb4:	28a080e7          	jalr	650(ra) # 80001e3a <mycpu>
    80000bb8:	08052783          	lw	a5,128(a0)
    80000bbc:	cf99                	beqz	a5,80000bda <push_off+0x42>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbe:	00001097          	auipc	ra,0x1
    80000bc2:	27c080e7          	jalr	636(ra) # 80001e3a <mycpu>
    80000bc6:	08052783          	lw	a5,128(a0)
    80000bca:	2785                	addiw	a5,a5,1
    80000bcc:	08f52023          	sw	a5,128(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	260080e7          	jalr	608(ra) # 80001e3a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	08952223          	sw	s1,132(a0)
    80000bea:	bfd1                	j	80000bbe <push_off+0x26>

0000000080000bec <acquire>:
{
    80000bec:	1101                	addi	sp,sp,-32
    80000bee:	ec06                	sd	ra,24(sp)
    80000bf0:	e822                	sd	s0,16(sp)
    80000bf2:	e426                	sd	s1,8(sp)
    80000bf4:	1000                	addi	s0,sp,32
    80000bf6:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf8:	00000097          	auipc	ra,0x0
    80000bfc:	fa0080e7          	jalr	-96(ra) # 80000b98 <push_off>
  if(holding(lk)){
    80000c00:	8526                	mv	a0,s1
    80000c02:	00000097          	auipc	ra,0x0
    80000c06:	f68080e7          	jalr	-152(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0a:	4705                	li	a4,1
  if(holding(lk)){
    80000c0c:	e115                	bnez	a0,80000c30 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0e:	87ba                	mv	a5,a4
    80000c10:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c14:	2781                	sext.w	a5,a5
    80000c16:	ffe5                	bnez	a5,80000c0e <acquire+0x22>
  __sync_synchronize();
    80000c18:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1c:	00001097          	auipc	ra,0x1
    80000c20:	21e080e7          	jalr	542(ra) # 80001e3a <mycpu>
    80000c24:	e888                	sd	a0,16(s1)
}
    80000c26:	60e2                	ld	ra,24(sp)
    80000c28:	6442                	ld	s0,16(sp)
    80000c2a:	64a2                	ld	s1,8(sp)
    80000c2c:	6105                	addi	sp,sp,32
    80000c2e:	8082                	ret
  printf("%s \n", lk->name);
    80000c30:	648c                	ld	a1,8(s1)
    80000c32:	00007517          	auipc	a0,0x7
    80000c36:	43e50513          	addi	a0,a0,1086 # 80008070 <digits+0x30>
    80000c3a:	00000097          	auipc	ra,0x0
    80000c3e:	94e080e7          	jalr	-1714(ra) # 80000588 <printf>
    panic("acquire");
    80000c42:	00007517          	auipc	a0,0x7
    80000c46:	43650513          	addi	a0,a0,1078 # 80008078 <digits+0x38>
    80000c4a:	00000097          	auipc	ra,0x0
    80000c4e:	8f4080e7          	jalr	-1804(ra) # 8000053e <panic>

0000000080000c52 <pop_off>:

void
pop_off(void)
{
    80000c52:	1141                	addi	sp,sp,-16
    80000c54:	e406                	sd	ra,8(sp)
    80000c56:	e022                	sd	s0,0(sp)
    80000c58:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c5a:	00001097          	auipc	ra,0x1
    80000c5e:	1e0080e7          	jalr	480(ra) # 80001e3a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c62:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c66:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c68:	eb85                	bnez	a5,80000c98 <pop_off+0x46>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c6a:	08052783          	lw	a5,128(a0)
    80000c6e:	02f05d63          	blez	a5,80000ca8 <pop_off+0x56>
    panic("pop_off");
  c->noff -= 1;
    80000c72:	37fd                	addiw	a5,a5,-1
    80000c74:	0007871b          	sext.w	a4,a5
    80000c78:	08f52023          	sw	a5,128(a0)
  if(c->noff == 0 && c->intena)
    80000c7c:	eb11                	bnez	a4,80000c90 <pop_off+0x3e>
    80000c7e:	08452783          	lw	a5,132(a0)
    80000c82:	c799                	beqz	a5,80000c90 <pop_off+0x3e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c88:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c8c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c90:	60a2                	ld	ra,8(sp)
    80000c92:	6402                	ld	s0,0(sp)
    80000c94:	0141                	addi	sp,sp,16
    80000c96:	8082                	ret
    panic("pop_off - interruptible");
    80000c98:	00007517          	auipc	a0,0x7
    80000c9c:	3e850513          	addi	a0,a0,1000 # 80008080 <digits+0x40>
    80000ca0:	00000097          	auipc	ra,0x0
    80000ca4:	89e080e7          	jalr	-1890(ra) # 8000053e <panic>
    panic("pop_off");
    80000ca8:	00007517          	auipc	a0,0x7
    80000cac:	3f050513          	addi	a0,a0,1008 # 80008098 <digits+0x58>
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	88e080e7          	jalr	-1906(ra) # 8000053e <panic>

0000000080000cb8 <release>:
{
    80000cb8:	1101                	addi	sp,sp,-32
    80000cba:	ec06                	sd	ra,24(sp)
    80000cbc:	e822                	sd	s0,16(sp)
    80000cbe:	e426                	sd	s1,8(sp)
    80000cc0:	1000                	addi	s0,sp,32
    80000cc2:	84aa                	mv	s1,a0
  if(!holding(lk)){
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	ea6080e7          	jalr	-346(ra) # 80000b6a <holding>
    80000ccc:	c115                	beqz	a0,80000cf0 <release+0x38>
  lk->cpu = 0;
    80000cce:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cd2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cd6:	0f50000f          	fence	iorw,ow
    80000cda:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	f74080e7          	jalr	-140(ra) # 80000c52 <pop_off>
}
    80000ce6:	60e2                	ld	ra,24(sp)
    80000ce8:	6442                	ld	s0,16(sp)
    80000cea:	64a2                	ld	s1,8(sp)
    80000cec:	6105                	addi	sp,sp,32
    80000cee:	8082                	ret
    printf("%s \n", lk->name);
    80000cf0:	648c                	ld	a1,8(s1)
    80000cf2:	00007517          	auipc	a0,0x7
    80000cf6:	37e50513          	addi	a0,a0,894 # 80008070 <digits+0x30>
    80000cfa:	00000097          	auipc	ra,0x0
    80000cfe:	88e080e7          	jalr	-1906(ra) # 80000588 <printf>
    panic("release");
    80000d02:	00007517          	auipc	a0,0x7
    80000d06:	39e50513          	addi	a0,a0,926 # 800080a0 <digits+0x60>
    80000d0a:	00000097          	auipc	ra,0x0
    80000d0e:	834080e7          	jalr	-1996(ra) # 8000053e <panic>

0000000080000d12 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d12:	1141                	addi	sp,sp,-16
    80000d14:	e422                	sd	s0,8(sp)
    80000d16:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d18:	ce09                	beqz	a2,80000d32 <memset+0x20>
    80000d1a:	87aa                	mv	a5,a0
    80000d1c:	fff6071b          	addiw	a4,a2,-1
    80000d20:	1702                	slli	a4,a4,0x20
    80000d22:	9301                	srli	a4,a4,0x20
    80000d24:	0705                	addi	a4,a4,1
    80000d26:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d28:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d2c:	0785                	addi	a5,a5,1
    80000d2e:	fee79de3          	bne	a5,a4,80000d28 <memset+0x16>
  }
  return dst;
}
    80000d32:	6422                	ld	s0,8(sp)
    80000d34:	0141                	addi	sp,sp,16
    80000d36:	8082                	ret

0000000080000d38 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d38:	1141                	addi	sp,sp,-16
    80000d3a:	e422                	sd	s0,8(sp)
    80000d3c:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d3e:	ca05                	beqz	a2,80000d6e <memcmp+0x36>
    80000d40:	fff6069b          	addiw	a3,a2,-1
    80000d44:	1682                	slli	a3,a3,0x20
    80000d46:	9281                	srli	a3,a3,0x20
    80000d48:	0685                	addi	a3,a3,1
    80000d4a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d4c:	00054783          	lbu	a5,0(a0)
    80000d50:	0005c703          	lbu	a4,0(a1)
    80000d54:	00e79863          	bne	a5,a4,80000d64 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d58:	0505                	addi	a0,a0,1
    80000d5a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d5c:	fed518e3          	bne	a0,a3,80000d4c <memcmp+0x14>
  }

  return 0;
    80000d60:	4501                	li	a0,0
    80000d62:	a019                	j	80000d68 <memcmp+0x30>
      return *s1 - *s2;
    80000d64:	40e7853b          	subw	a0,a5,a4
}
    80000d68:	6422                	ld	s0,8(sp)
    80000d6a:	0141                	addi	sp,sp,16
    80000d6c:	8082                	ret
  return 0;
    80000d6e:	4501                	li	a0,0
    80000d70:	bfe5                	j	80000d68 <memcmp+0x30>

0000000080000d72 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d72:	1141                	addi	sp,sp,-16
    80000d74:	e422                	sd	s0,8(sp)
    80000d76:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d78:	ca0d                	beqz	a2,80000daa <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d7a:	00a5f963          	bgeu	a1,a0,80000d8c <memmove+0x1a>
    80000d7e:	02061693          	slli	a3,a2,0x20
    80000d82:	9281                	srli	a3,a3,0x20
    80000d84:	00d58733          	add	a4,a1,a3
    80000d88:	02e56463          	bltu	a0,a4,80000db0 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d8c:	fff6079b          	addiw	a5,a2,-1
    80000d90:	1782                	slli	a5,a5,0x20
    80000d92:	9381                	srli	a5,a5,0x20
    80000d94:	0785                	addi	a5,a5,1
    80000d96:	97ae                	add	a5,a5,a1
    80000d98:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d9a:	0585                	addi	a1,a1,1
    80000d9c:	0705                	addi	a4,a4,1
    80000d9e:	fff5c683          	lbu	a3,-1(a1)
    80000da2:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000da6:	fef59ae3          	bne	a1,a5,80000d9a <memmove+0x28>

  return dst;
}
    80000daa:	6422                	ld	s0,8(sp)
    80000dac:	0141                	addi	sp,sp,16
    80000dae:	8082                	ret
    d += n;
    80000db0:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000db2:	fff6079b          	addiw	a5,a2,-1
    80000db6:	1782                	slli	a5,a5,0x20
    80000db8:	9381                	srli	a5,a5,0x20
    80000dba:	fff7c793          	not	a5,a5
    80000dbe:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dc0:	177d                	addi	a4,a4,-1
    80000dc2:	16fd                	addi	a3,a3,-1
    80000dc4:	00074603          	lbu	a2,0(a4)
    80000dc8:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000dcc:	fef71ae3          	bne	a4,a5,80000dc0 <memmove+0x4e>
    80000dd0:	bfe9                	j	80000daa <memmove+0x38>

0000000080000dd2 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e406                	sd	ra,8(sp)
    80000dd6:	e022                	sd	s0,0(sp)
    80000dd8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dda:	00000097          	auipc	ra,0x0
    80000dde:	f98080e7          	jalr	-104(ra) # 80000d72 <memmove>
}
    80000de2:	60a2                	ld	ra,8(sp)
    80000de4:	6402                	ld	s0,0(sp)
    80000de6:	0141                	addi	sp,sp,16
    80000de8:	8082                	ret

0000000080000dea <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dea:	1141                	addi	sp,sp,-16
    80000dec:	e422                	sd	s0,8(sp)
    80000dee:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000df0:	ce11                	beqz	a2,80000e0c <strncmp+0x22>
    80000df2:	00054783          	lbu	a5,0(a0)
    80000df6:	cf89                	beqz	a5,80000e10 <strncmp+0x26>
    80000df8:	0005c703          	lbu	a4,0(a1)
    80000dfc:	00f71a63          	bne	a4,a5,80000e10 <strncmp+0x26>
    n--, p++, q++;
    80000e00:	367d                	addiw	a2,a2,-1
    80000e02:	0505                	addi	a0,a0,1
    80000e04:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e06:	f675                	bnez	a2,80000df2 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e08:	4501                	li	a0,0
    80000e0a:	a809                	j	80000e1c <strncmp+0x32>
    80000e0c:	4501                	li	a0,0
    80000e0e:	a039                	j	80000e1c <strncmp+0x32>
  if(n == 0)
    80000e10:	ca09                	beqz	a2,80000e22 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e12:	00054503          	lbu	a0,0(a0)
    80000e16:	0005c783          	lbu	a5,0(a1)
    80000e1a:	9d1d                	subw	a0,a0,a5
}
    80000e1c:	6422                	ld	s0,8(sp)
    80000e1e:	0141                	addi	sp,sp,16
    80000e20:	8082                	ret
    return 0;
    80000e22:	4501                	li	a0,0
    80000e24:	bfe5                	j	80000e1c <strncmp+0x32>

0000000080000e26 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e26:	1141                	addi	sp,sp,-16
    80000e28:	e422                	sd	s0,8(sp)
    80000e2a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e2c:	872a                	mv	a4,a0
    80000e2e:	8832                	mv	a6,a2
    80000e30:	367d                	addiw	a2,a2,-1
    80000e32:	01005963          	blez	a6,80000e44 <strncpy+0x1e>
    80000e36:	0705                	addi	a4,a4,1
    80000e38:	0005c783          	lbu	a5,0(a1)
    80000e3c:	fef70fa3          	sb	a5,-1(a4)
    80000e40:	0585                	addi	a1,a1,1
    80000e42:	f7f5                	bnez	a5,80000e2e <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e44:	00c05d63          	blez	a2,80000e5e <strncpy+0x38>
    80000e48:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e4a:	0685                	addi	a3,a3,1
    80000e4c:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e50:	fff6c793          	not	a5,a3
    80000e54:	9fb9                	addw	a5,a5,a4
    80000e56:	010787bb          	addw	a5,a5,a6
    80000e5a:	fef048e3          	bgtz	a5,80000e4a <strncpy+0x24>
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e6a:	02c05363          	blez	a2,80000e90 <safestrcpy+0x2c>
    80000e6e:	fff6069b          	addiw	a3,a2,-1
    80000e72:	1682                	slli	a3,a3,0x20
    80000e74:	9281                	srli	a3,a3,0x20
    80000e76:	96ae                	add	a3,a3,a1
    80000e78:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e7a:	00d58963          	beq	a1,a3,80000e8c <safestrcpy+0x28>
    80000e7e:	0585                	addi	a1,a1,1
    80000e80:	0785                	addi	a5,a5,1
    80000e82:	fff5c703          	lbu	a4,-1(a1)
    80000e86:	fee78fa3          	sb	a4,-1(a5)
    80000e8a:	fb65                	bnez	a4,80000e7a <safestrcpy+0x16>
    ;
  *s = 0;
    80000e8c:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e90:	6422                	ld	s0,8(sp)
    80000e92:	0141                	addi	sp,sp,16
    80000e94:	8082                	ret

0000000080000e96 <strlen>:

int
strlen(const char *s)
{
    80000e96:	1141                	addi	sp,sp,-16
    80000e98:	e422                	sd	s0,8(sp)
    80000e9a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e9c:	00054783          	lbu	a5,0(a0)
    80000ea0:	cf91                	beqz	a5,80000ebc <strlen+0x26>
    80000ea2:	0505                	addi	a0,a0,1
    80000ea4:	87aa                	mv	a5,a0
    80000ea6:	4685                	li	a3,1
    80000ea8:	9e89                	subw	a3,a3,a0
    80000eaa:	00f6853b          	addw	a0,a3,a5
    80000eae:	0785                	addi	a5,a5,1
    80000eb0:	fff7c703          	lbu	a4,-1(a5)
    80000eb4:	fb7d                	bnez	a4,80000eaa <strlen+0x14>
    ;
  return n;
}
    80000eb6:	6422                	ld	s0,8(sp)
    80000eb8:	0141                	addi	sp,sp,16
    80000eba:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ebc:	4501                	li	a0,0
    80000ebe:	bfe5                	j	80000eb6 <strlen+0x20>

0000000080000ec0 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ec0:	1141                	addi	sp,sp,-16
    80000ec2:	e406                	sd	ra,8(sp)
    80000ec4:	e022                	sd	s0,0(sp)
    80000ec6:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	f62080e7          	jalr	-158(ra) # 80001e2a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ed0:	00008717          	auipc	a4,0x8
    80000ed4:	14870713          	addi	a4,a4,328 # 80009018 <started>
  if(cpuid() == 0){
    80000ed8:	c139                	beqz	a0,80000f1e <main+0x5e>
    while(started == 0)
    80000eda:	431c                	lw	a5,0(a4)
    80000edc:	2781                	sext.w	a5,a5
    80000ede:	dff5                	beqz	a5,80000eda <main+0x1a>
      ;
    __sync_synchronize();
    80000ee0:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	f46080e7          	jalr	-186(ra) # 80001e2a <cpuid>
    80000eec:	85aa                	mv	a1,a0
    80000eee:	00007517          	auipc	a0,0x7
    80000ef2:	1d250513          	addi	a0,a0,466 # 800080c0 <digits+0x80>
    80000ef6:	fffff097          	auipc	ra,0xfffff
    80000efa:	692080e7          	jalr	1682(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000efe:	00000097          	auipc	ra,0x0
    80000f02:	0d8080e7          	jalr	216(ra) # 80000fd6 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f06:	00002097          	auipc	ra,0x2
    80000f0a:	046080e7          	jalr	70(ra) # 80002f4c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0e:	00005097          	auipc	ra,0x5
    80000f12:	5e2080e7          	jalr	1506(ra) # 800064f0 <plicinithart>
  }

  scheduler();        
    80000f16:	00001097          	auipc	ra,0x1
    80000f1a:	5d8080e7          	jalr	1496(ra) # 800024ee <scheduler>
    consoleinit();
    80000f1e:	fffff097          	auipc	ra,0xfffff
    80000f22:	532080e7          	jalr	1330(ra) # 80000450 <consoleinit>
    printfinit();
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	848080e7          	jalr	-1976(ra) # 8000076e <printfinit>
    printf("\n");
    80000f2e:	00007517          	auipc	a0,0x7
    80000f32:	1a250513          	addi	a0,a0,418 # 800080d0 <digits+0x90>
    80000f36:	fffff097          	auipc	ra,0xfffff
    80000f3a:	652080e7          	jalr	1618(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f3e:	00007517          	auipc	a0,0x7
    80000f42:	16a50513          	addi	a0,a0,362 # 800080a8 <digits+0x68>
    80000f46:	fffff097          	auipc	ra,0xfffff
    80000f4a:	642080e7          	jalr	1602(ra) # 80000588 <printf>
    printf("\n");
    80000f4e:	00007517          	auipc	a0,0x7
    80000f52:	18250513          	addi	a0,a0,386 # 800080d0 <digits+0x90>
    80000f56:	fffff097          	auipc	ra,0xfffff
    80000f5a:	632080e7          	jalr	1586(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f5e:	00000097          	auipc	ra,0x0
    80000f62:	b5a080e7          	jalr	-1190(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f66:	00000097          	auipc	ra,0x0
    80000f6a:	322080e7          	jalr	802(ra) # 80001288 <kvminit>
    kvminithart();   // turn on paging
    80000f6e:	00000097          	auipc	ra,0x0
    80000f72:	068080e7          	jalr	104(ra) # 80000fd6 <kvminithart>
    procinit();      // process table
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	dae080e7          	jalr	-594(ra) # 80001d24 <procinit>
    trapinit();      // trap vectors
    80000f7e:	00002097          	auipc	ra,0x2
    80000f82:	fa6080e7          	jalr	-90(ra) # 80002f24 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f86:	00002097          	auipc	ra,0x2
    80000f8a:	fc6080e7          	jalr	-58(ra) # 80002f4c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f8e:	00005097          	auipc	ra,0x5
    80000f92:	54c080e7          	jalr	1356(ra) # 800064da <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f96:	00005097          	auipc	ra,0x5
    80000f9a:	55a080e7          	jalr	1370(ra) # 800064f0 <plicinithart>
    binit();         // buffer cache
    80000f9e:	00002097          	auipc	ra,0x2
    80000fa2:	73a080e7          	jalr	1850(ra) # 800036d8 <binit>
    iinit();         // inode table
    80000fa6:	00003097          	auipc	ra,0x3
    80000faa:	dca080e7          	jalr	-566(ra) # 80003d70 <iinit>
    fileinit();      // file table
    80000fae:	00004097          	auipc	ra,0x4
    80000fb2:	d74080e7          	jalr	-652(ra) # 80004d22 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb6:	00005097          	auipc	ra,0x5
    80000fba:	65c080e7          	jalr	1628(ra) # 80006612 <virtio_disk_init>
    userinit();      // first user process
    80000fbe:	00001097          	auipc	ra,0x1
    80000fc2:	1ea080e7          	jalr	490(ra) # 800021a8 <userinit>
    __sync_synchronize();
    80000fc6:	0ff0000f          	fence
    started = 1;
    80000fca:	4785                	li	a5,1
    80000fcc:	00008717          	auipc	a4,0x8
    80000fd0:	04f72623          	sw	a5,76(a4) # 80009018 <started>
    80000fd4:	b789                	j	80000f16 <main+0x56>

0000000080000fd6 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fd6:	1141                	addi	sp,sp,-16
    80000fd8:	e422                	sd	s0,8(sp)
    80000fda:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fdc:	00008797          	auipc	a5,0x8
    80000fe0:	0447b783          	ld	a5,68(a5) # 80009020 <kernel_pagetable>
    80000fe4:	83b1                	srli	a5,a5,0xc
    80000fe6:	577d                	li	a4,-1
    80000fe8:	177e                	slli	a4,a4,0x3f
    80000fea:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fec:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ff0:	12000073          	sfence.vma
  sfence_vma();
}
    80000ff4:	6422                	ld	s0,8(sp)
    80000ff6:	0141                	addi	sp,sp,16
    80000ff8:	8082                	ret

0000000080000ffa <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000ffa:	7139                	addi	sp,sp,-64
    80000ffc:	fc06                	sd	ra,56(sp)
    80000ffe:	f822                	sd	s0,48(sp)
    80001000:	f426                	sd	s1,40(sp)
    80001002:	f04a                	sd	s2,32(sp)
    80001004:	ec4e                	sd	s3,24(sp)
    80001006:	e852                	sd	s4,16(sp)
    80001008:	e456                	sd	s5,8(sp)
    8000100a:	e05a                	sd	s6,0(sp)
    8000100c:	0080                	addi	s0,sp,64
    8000100e:	84aa                	mv	s1,a0
    80001010:	89ae                	mv	s3,a1
    80001012:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001014:	57fd                	li	a5,-1
    80001016:	83e9                	srli	a5,a5,0x1a
    80001018:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000101a:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000101c:	04b7f263          	bgeu	a5,a1,80001060 <walk+0x66>
    panic("walk");
    80001020:	00007517          	auipc	a0,0x7
    80001024:	0b850513          	addi	a0,a0,184 # 800080d8 <digits+0x98>
    80001028:	fffff097          	auipc	ra,0xfffff
    8000102c:	516080e7          	jalr	1302(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001030:	060a8663          	beqz	s5,8000109c <walk+0xa2>
    80001034:	00000097          	auipc	ra,0x0
    80001038:	ac0080e7          	jalr	-1344(ra) # 80000af4 <kalloc>
    8000103c:	84aa                	mv	s1,a0
    8000103e:	c529                	beqz	a0,80001088 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001040:	6605                	lui	a2,0x1
    80001042:	4581                	li	a1,0
    80001044:	00000097          	auipc	ra,0x0
    80001048:	cce080e7          	jalr	-818(ra) # 80000d12 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000104c:	00c4d793          	srli	a5,s1,0xc
    80001050:	07aa                	slli	a5,a5,0xa
    80001052:	0017e793          	ori	a5,a5,1
    80001056:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000105a:	3a5d                	addiw	s4,s4,-9
    8000105c:	036a0063          	beq	s4,s6,8000107c <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001060:	0149d933          	srl	s2,s3,s4
    80001064:	1ff97913          	andi	s2,s2,511
    80001068:	090e                	slli	s2,s2,0x3
    8000106a:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000106c:	00093483          	ld	s1,0(s2)
    80001070:	0014f793          	andi	a5,s1,1
    80001074:	dfd5                	beqz	a5,80001030 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001076:	80a9                	srli	s1,s1,0xa
    80001078:	04b2                	slli	s1,s1,0xc
    8000107a:	b7c5                	j	8000105a <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000107c:	00c9d513          	srli	a0,s3,0xc
    80001080:	1ff57513          	andi	a0,a0,511
    80001084:	050e                	slli	a0,a0,0x3
    80001086:	9526                	add	a0,a0,s1
}
    80001088:	70e2                	ld	ra,56(sp)
    8000108a:	7442                	ld	s0,48(sp)
    8000108c:	74a2                	ld	s1,40(sp)
    8000108e:	7902                	ld	s2,32(sp)
    80001090:	69e2                	ld	s3,24(sp)
    80001092:	6a42                	ld	s4,16(sp)
    80001094:	6aa2                	ld	s5,8(sp)
    80001096:	6b02                	ld	s6,0(sp)
    80001098:	6121                	addi	sp,sp,64
    8000109a:	8082                	ret
        return 0;
    8000109c:	4501                	li	a0,0
    8000109e:	b7ed                	j	80001088 <walk+0x8e>

00000000800010a0 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010a0:	57fd                	li	a5,-1
    800010a2:	83e9                	srli	a5,a5,0x1a
    800010a4:	00b7f463          	bgeu	a5,a1,800010ac <walkaddr+0xc>
    return 0;
    800010a8:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010aa:	8082                	ret
{
    800010ac:	1141                	addi	sp,sp,-16
    800010ae:	e406                	sd	ra,8(sp)
    800010b0:	e022                	sd	s0,0(sp)
    800010b2:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010b4:	4601                	li	a2,0
    800010b6:	00000097          	auipc	ra,0x0
    800010ba:	f44080e7          	jalr	-188(ra) # 80000ffa <walk>
  if(pte == 0)
    800010be:	c105                	beqz	a0,800010de <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010c0:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c2:	0117f693          	andi	a3,a5,17
    800010c6:	4745                	li	a4,17
    return 0;
    800010c8:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010ca:	00e68663          	beq	a3,a4,800010d6 <walkaddr+0x36>
}
    800010ce:	60a2                	ld	ra,8(sp)
    800010d0:	6402                	ld	s0,0(sp)
    800010d2:	0141                	addi	sp,sp,16
    800010d4:	8082                	ret
  pa = PTE2PA(*pte);
    800010d6:	00a7d513          	srli	a0,a5,0xa
    800010da:	0532                	slli	a0,a0,0xc
  return pa;
    800010dc:	bfcd                	j	800010ce <walkaddr+0x2e>
    return 0;
    800010de:	4501                	li	a0,0
    800010e0:	b7fd                	j	800010ce <walkaddr+0x2e>

00000000800010e2 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010e2:	715d                	addi	sp,sp,-80
    800010e4:	e486                	sd	ra,72(sp)
    800010e6:	e0a2                	sd	s0,64(sp)
    800010e8:	fc26                	sd	s1,56(sp)
    800010ea:	f84a                	sd	s2,48(sp)
    800010ec:	f44e                	sd	s3,40(sp)
    800010ee:	f052                	sd	s4,32(sp)
    800010f0:	ec56                	sd	s5,24(sp)
    800010f2:	e85a                	sd	s6,16(sp)
    800010f4:	e45e                	sd	s7,8(sp)
    800010f6:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010f8:	c205                	beqz	a2,80001118 <mappages+0x36>
    800010fa:	8aaa                	mv	s5,a0
    800010fc:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010fe:	77fd                	lui	a5,0xfffff
    80001100:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001104:	15fd                	addi	a1,a1,-1
    80001106:	00c589b3          	add	s3,a1,a2
    8000110a:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    8000110e:	8952                	mv	s2,s4
    80001110:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001114:	6b85                	lui	s7,0x1
    80001116:	a015                	j	8000113a <mappages+0x58>
    panic("mappages: size");
    80001118:	00007517          	auipc	a0,0x7
    8000111c:	fc850513          	addi	a0,a0,-56 # 800080e0 <digits+0xa0>
    80001120:	fffff097          	auipc	ra,0xfffff
    80001124:	41e080e7          	jalr	1054(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001128:	00007517          	auipc	a0,0x7
    8000112c:	fc850513          	addi	a0,a0,-56 # 800080f0 <digits+0xb0>
    80001130:	fffff097          	auipc	ra,0xfffff
    80001134:	40e080e7          	jalr	1038(ra) # 8000053e <panic>
    a += PGSIZE;
    80001138:	995e                	add	s2,s2,s7
  for(;;){
    8000113a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000113e:	4605                	li	a2,1
    80001140:	85ca                	mv	a1,s2
    80001142:	8556                	mv	a0,s5
    80001144:	00000097          	auipc	ra,0x0
    80001148:	eb6080e7          	jalr	-330(ra) # 80000ffa <walk>
    8000114c:	cd19                	beqz	a0,8000116a <mappages+0x88>
    if(*pte & PTE_V)
    8000114e:	611c                	ld	a5,0(a0)
    80001150:	8b85                	andi	a5,a5,1
    80001152:	fbf9                	bnez	a5,80001128 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001154:	80b1                	srli	s1,s1,0xc
    80001156:	04aa                	slli	s1,s1,0xa
    80001158:	0164e4b3          	or	s1,s1,s6
    8000115c:	0014e493          	ori	s1,s1,1
    80001160:	e104                	sd	s1,0(a0)
    if(a == last)
    80001162:	fd391be3          	bne	s2,s3,80001138 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001166:	4501                	li	a0,0
    80001168:	a011                	j	8000116c <mappages+0x8a>
      return -1;
    8000116a:	557d                	li	a0,-1
}
    8000116c:	60a6                	ld	ra,72(sp)
    8000116e:	6406                	ld	s0,64(sp)
    80001170:	74e2                	ld	s1,56(sp)
    80001172:	7942                	ld	s2,48(sp)
    80001174:	79a2                	ld	s3,40(sp)
    80001176:	7a02                	ld	s4,32(sp)
    80001178:	6ae2                	ld	s5,24(sp)
    8000117a:	6b42                	ld	s6,16(sp)
    8000117c:	6ba2                	ld	s7,8(sp)
    8000117e:	6161                	addi	sp,sp,80
    80001180:	8082                	ret

0000000080001182 <kvmmap>:
{
    80001182:	1141                	addi	sp,sp,-16
    80001184:	e406                	sd	ra,8(sp)
    80001186:	e022                	sd	s0,0(sp)
    80001188:	0800                	addi	s0,sp,16
    8000118a:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000118c:	86b2                	mv	a3,a2
    8000118e:	863e                	mv	a2,a5
    80001190:	00000097          	auipc	ra,0x0
    80001194:	f52080e7          	jalr	-174(ra) # 800010e2 <mappages>
    80001198:	e509                	bnez	a0,800011a2 <kvmmap+0x20>
}
    8000119a:	60a2                	ld	ra,8(sp)
    8000119c:	6402                	ld	s0,0(sp)
    8000119e:	0141                	addi	sp,sp,16
    800011a0:	8082                	ret
    panic("kvmmap");
    800011a2:	00007517          	auipc	a0,0x7
    800011a6:	f5e50513          	addi	a0,a0,-162 # 80008100 <digits+0xc0>
    800011aa:	fffff097          	auipc	ra,0xfffff
    800011ae:	394080e7          	jalr	916(ra) # 8000053e <panic>

00000000800011b2 <kvmmake>:
{
    800011b2:	1101                	addi	sp,sp,-32
    800011b4:	ec06                	sd	ra,24(sp)
    800011b6:	e822                	sd	s0,16(sp)
    800011b8:	e426                	sd	s1,8(sp)
    800011ba:	e04a                	sd	s2,0(sp)
    800011bc:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011be:	00000097          	auipc	ra,0x0
    800011c2:	936080e7          	jalr	-1738(ra) # 80000af4 <kalloc>
    800011c6:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011c8:	6605                	lui	a2,0x1
    800011ca:	4581                	li	a1,0
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	b46080e7          	jalr	-1210(ra) # 80000d12 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011d4:	4719                	li	a4,6
    800011d6:	6685                	lui	a3,0x1
    800011d8:	10000637          	lui	a2,0x10000
    800011dc:	100005b7          	lui	a1,0x10000
    800011e0:	8526                	mv	a0,s1
    800011e2:	00000097          	auipc	ra,0x0
    800011e6:	fa0080e7          	jalr	-96(ra) # 80001182 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011ea:	4719                	li	a4,6
    800011ec:	6685                	lui	a3,0x1
    800011ee:	10001637          	lui	a2,0x10001
    800011f2:	100015b7          	lui	a1,0x10001
    800011f6:	8526                	mv	a0,s1
    800011f8:	00000097          	auipc	ra,0x0
    800011fc:	f8a080e7          	jalr	-118(ra) # 80001182 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001200:	4719                	li	a4,6
    80001202:	004006b7          	lui	a3,0x400
    80001206:	0c000637          	lui	a2,0xc000
    8000120a:	0c0005b7          	lui	a1,0xc000
    8000120e:	8526                	mv	a0,s1
    80001210:	00000097          	auipc	ra,0x0
    80001214:	f72080e7          	jalr	-142(ra) # 80001182 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001218:	00007917          	auipc	s2,0x7
    8000121c:	de890913          	addi	s2,s2,-536 # 80008000 <etext>
    80001220:	4729                	li	a4,10
    80001222:	80007697          	auipc	a3,0x80007
    80001226:	dde68693          	addi	a3,a3,-546 # 8000 <_entry-0x7fff8000>
    8000122a:	4605                	li	a2,1
    8000122c:	067e                	slli	a2,a2,0x1f
    8000122e:	85b2                	mv	a1,a2
    80001230:	8526                	mv	a0,s1
    80001232:	00000097          	auipc	ra,0x0
    80001236:	f50080e7          	jalr	-176(ra) # 80001182 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000123a:	4719                	li	a4,6
    8000123c:	46c5                	li	a3,17
    8000123e:	06ee                	slli	a3,a3,0x1b
    80001240:	412686b3          	sub	a3,a3,s2
    80001244:	864a                	mv	a2,s2
    80001246:	85ca                	mv	a1,s2
    80001248:	8526                	mv	a0,s1
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	f38080e7          	jalr	-200(ra) # 80001182 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001252:	4729                	li	a4,10
    80001254:	6685                	lui	a3,0x1
    80001256:	00006617          	auipc	a2,0x6
    8000125a:	daa60613          	addi	a2,a2,-598 # 80007000 <_trampoline>
    8000125e:	040005b7          	lui	a1,0x4000
    80001262:	15fd                	addi	a1,a1,-1
    80001264:	05b2                	slli	a1,a1,0xc
    80001266:	8526                	mv	a0,s1
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f1a080e7          	jalr	-230(ra) # 80001182 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001270:	8526                	mv	a0,s1
    80001272:	00001097          	auipc	ra,0x1
    80001276:	a1c080e7          	jalr	-1508(ra) # 80001c8e <proc_mapstacks>
}
    8000127a:	8526                	mv	a0,s1
    8000127c:	60e2                	ld	ra,24(sp)
    8000127e:	6442                	ld	s0,16(sp)
    80001280:	64a2                	ld	s1,8(sp)
    80001282:	6902                	ld	s2,0(sp)
    80001284:	6105                	addi	sp,sp,32
    80001286:	8082                	ret

0000000080001288 <kvminit>:
{
    80001288:	1141                	addi	sp,sp,-16
    8000128a:	e406                	sd	ra,8(sp)
    8000128c:	e022                	sd	s0,0(sp)
    8000128e:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001290:	00000097          	auipc	ra,0x0
    80001294:	f22080e7          	jalr	-222(ra) # 800011b2 <kvmmake>
    80001298:	00008797          	auipc	a5,0x8
    8000129c:	d8a7b423          	sd	a0,-632(a5) # 80009020 <kernel_pagetable>
}
    800012a0:	60a2                	ld	ra,8(sp)
    800012a2:	6402                	ld	s0,0(sp)
    800012a4:	0141                	addi	sp,sp,16
    800012a6:	8082                	ret

00000000800012a8 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012a8:	715d                	addi	sp,sp,-80
    800012aa:	e486                	sd	ra,72(sp)
    800012ac:	e0a2                	sd	s0,64(sp)
    800012ae:	fc26                	sd	s1,56(sp)
    800012b0:	f84a                	sd	s2,48(sp)
    800012b2:	f44e                	sd	s3,40(sp)
    800012b4:	f052                	sd	s4,32(sp)
    800012b6:	ec56                	sd	s5,24(sp)
    800012b8:	e85a                	sd	s6,16(sp)
    800012ba:	e45e                	sd	s7,8(sp)
    800012bc:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012be:	03459793          	slli	a5,a1,0x34
    800012c2:	e795                	bnez	a5,800012ee <uvmunmap+0x46>
    800012c4:	8a2a                	mv	s4,a0
    800012c6:	892e                	mv	s2,a1
    800012c8:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ca:	0632                	slli	a2,a2,0xc
    800012cc:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012d0:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d2:	6b05                	lui	s6,0x1
    800012d4:	0735e863          	bltu	a1,s3,80001344 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012d8:	60a6                	ld	ra,72(sp)
    800012da:	6406                	ld	s0,64(sp)
    800012dc:	74e2                	ld	s1,56(sp)
    800012de:	7942                	ld	s2,48(sp)
    800012e0:	79a2                	ld	s3,40(sp)
    800012e2:	7a02                	ld	s4,32(sp)
    800012e4:	6ae2                	ld	s5,24(sp)
    800012e6:	6b42                	ld	s6,16(sp)
    800012e8:	6ba2                	ld	s7,8(sp)
    800012ea:	6161                	addi	sp,sp,80
    800012ec:	8082                	ret
    panic("uvmunmap: not aligned");
    800012ee:	00007517          	auipc	a0,0x7
    800012f2:	e1a50513          	addi	a0,a0,-486 # 80008108 <digits+0xc8>
    800012f6:	fffff097          	auipc	ra,0xfffff
    800012fa:	248080e7          	jalr	584(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012fe:	00007517          	auipc	a0,0x7
    80001302:	e2250513          	addi	a0,a0,-478 # 80008120 <digits+0xe0>
    80001306:	fffff097          	auipc	ra,0xfffff
    8000130a:	238080e7          	jalr	568(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    8000130e:	00007517          	auipc	a0,0x7
    80001312:	e2250513          	addi	a0,a0,-478 # 80008130 <digits+0xf0>
    80001316:	fffff097          	auipc	ra,0xfffff
    8000131a:	228080e7          	jalr	552(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    8000131e:	00007517          	auipc	a0,0x7
    80001322:	e2a50513          	addi	a0,a0,-470 # 80008148 <digits+0x108>
    80001326:	fffff097          	auipc	ra,0xfffff
    8000132a:	218080e7          	jalr	536(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    8000132e:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001330:	0532                	slli	a0,a0,0xc
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	6c6080e7          	jalr	1734(ra) # 800009f8 <kfree>
    *pte = 0;
    8000133a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000133e:	995a                	add	s2,s2,s6
    80001340:	f9397ce3          	bgeu	s2,s3,800012d8 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001344:	4601                	li	a2,0
    80001346:	85ca                	mv	a1,s2
    80001348:	8552                	mv	a0,s4
    8000134a:	00000097          	auipc	ra,0x0
    8000134e:	cb0080e7          	jalr	-848(ra) # 80000ffa <walk>
    80001352:	84aa                	mv	s1,a0
    80001354:	d54d                	beqz	a0,800012fe <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001356:	6108                	ld	a0,0(a0)
    80001358:	00157793          	andi	a5,a0,1
    8000135c:	dbcd                	beqz	a5,8000130e <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000135e:	3ff57793          	andi	a5,a0,1023
    80001362:	fb778ee3          	beq	a5,s7,8000131e <uvmunmap+0x76>
    if(do_free){
    80001366:	fc0a8ae3          	beqz	s5,8000133a <uvmunmap+0x92>
    8000136a:	b7d1                	j	8000132e <uvmunmap+0x86>

000000008000136c <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000136c:	1101                	addi	sp,sp,-32
    8000136e:	ec06                	sd	ra,24(sp)
    80001370:	e822                	sd	s0,16(sp)
    80001372:	e426                	sd	s1,8(sp)
    80001374:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001376:	fffff097          	auipc	ra,0xfffff
    8000137a:	77e080e7          	jalr	1918(ra) # 80000af4 <kalloc>
    8000137e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001380:	c519                	beqz	a0,8000138e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	00000097          	auipc	ra,0x0
    8000138a:	98c080e7          	jalr	-1652(ra) # 80000d12 <memset>
  return pagetable;
}
    8000138e:	8526                	mv	a0,s1
    80001390:	60e2                	ld	ra,24(sp)
    80001392:	6442                	ld	s0,16(sp)
    80001394:	64a2                	ld	s1,8(sp)
    80001396:	6105                	addi	sp,sp,32
    80001398:	8082                	ret

000000008000139a <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000139a:	7179                	addi	sp,sp,-48
    8000139c:	f406                	sd	ra,40(sp)
    8000139e:	f022                	sd	s0,32(sp)
    800013a0:	ec26                	sd	s1,24(sp)
    800013a2:	e84a                	sd	s2,16(sp)
    800013a4:	e44e                	sd	s3,8(sp)
    800013a6:	e052                	sd	s4,0(sp)
    800013a8:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013aa:	6785                	lui	a5,0x1
    800013ac:	04f67863          	bgeu	a2,a5,800013fc <uvminit+0x62>
    800013b0:	8a2a                	mv	s4,a0
    800013b2:	89ae                	mv	s3,a1
    800013b4:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	73e080e7          	jalr	1854(ra) # 80000af4 <kalloc>
    800013be:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013c0:	6605                	lui	a2,0x1
    800013c2:	4581                	li	a1,0
    800013c4:	00000097          	auipc	ra,0x0
    800013c8:	94e080e7          	jalr	-1714(ra) # 80000d12 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013cc:	4779                	li	a4,30
    800013ce:	86ca                	mv	a3,s2
    800013d0:	6605                	lui	a2,0x1
    800013d2:	4581                	li	a1,0
    800013d4:	8552                	mv	a0,s4
    800013d6:	00000097          	auipc	ra,0x0
    800013da:	d0c080e7          	jalr	-756(ra) # 800010e2 <mappages>
  memmove(mem, src, sz);
    800013de:	8626                	mv	a2,s1
    800013e0:	85ce                	mv	a1,s3
    800013e2:	854a                	mv	a0,s2
    800013e4:	00000097          	auipc	ra,0x0
    800013e8:	98e080e7          	jalr	-1650(ra) # 80000d72 <memmove>
}
    800013ec:	70a2                	ld	ra,40(sp)
    800013ee:	7402                	ld	s0,32(sp)
    800013f0:	64e2                	ld	s1,24(sp)
    800013f2:	6942                	ld	s2,16(sp)
    800013f4:	69a2                	ld	s3,8(sp)
    800013f6:	6a02                	ld	s4,0(sp)
    800013f8:	6145                	addi	sp,sp,48
    800013fa:	8082                	ret
    panic("inituvm: more than a page");
    800013fc:	00007517          	auipc	a0,0x7
    80001400:	d6450513          	addi	a0,a0,-668 # 80008160 <digits+0x120>
    80001404:	fffff097          	auipc	ra,0xfffff
    80001408:	13a080e7          	jalr	314(ra) # 8000053e <panic>

000000008000140c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000140c:	1101                	addi	sp,sp,-32
    8000140e:	ec06                	sd	ra,24(sp)
    80001410:	e822                	sd	s0,16(sp)
    80001412:	e426                	sd	s1,8(sp)
    80001414:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001416:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001418:	00b67d63          	bgeu	a2,a1,80001432 <uvmdealloc+0x26>
    8000141c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000141e:	6785                	lui	a5,0x1
    80001420:	17fd                	addi	a5,a5,-1
    80001422:	00f60733          	add	a4,a2,a5
    80001426:	767d                	lui	a2,0xfffff
    80001428:	8f71                	and	a4,a4,a2
    8000142a:	97ae                	add	a5,a5,a1
    8000142c:	8ff1                	and	a5,a5,a2
    8000142e:	00f76863          	bltu	a4,a5,8000143e <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001432:	8526                	mv	a0,s1
    80001434:	60e2                	ld	ra,24(sp)
    80001436:	6442                	ld	s0,16(sp)
    80001438:	64a2                	ld	s1,8(sp)
    8000143a:	6105                	addi	sp,sp,32
    8000143c:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000143e:	8f99                	sub	a5,a5,a4
    80001440:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001442:	4685                	li	a3,1
    80001444:	0007861b          	sext.w	a2,a5
    80001448:	85ba                	mv	a1,a4
    8000144a:	00000097          	auipc	ra,0x0
    8000144e:	e5e080e7          	jalr	-418(ra) # 800012a8 <uvmunmap>
    80001452:	b7c5                	j	80001432 <uvmdealloc+0x26>

0000000080001454 <uvmalloc>:
  if(newsz < oldsz)
    80001454:	0ab66163          	bltu	a2,a1,800014f6 <uvmalloc+0xa2>
{
    80001458:	7139                	addi	sp,sp,-64
    8000145a:	fc06                	sd	ra,56(sp)
    8000145c:	f822                	sd	s0,48(sp)
    8000145e:	f426                	sd	s1,40(sp)
    80001460:	f04a                	sd	s2,32(sp)
    80001462:	ec4e                	sd	s3,24(sp)
    80001464:	e852                	sd	s4,16(sp)
    80001466:	e456                	sd	s5,8(sp)
    80001468:	0080                	addi	s0,sp,64
    8000146a:	8aaa                	mv	s5,a0
    8000146c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000146e:	6985                	lui	s3,0x1
    80001470:	19fd                	addi	s3,s3,-1
    80001472:	95ce                	add	a1,a1,s3
    80001474:	79fd                	lui	s3,0xfffff
    80001476:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	08c9f063          	bgeu	s3,a2,800014fa <uvmalloc+0xa6>
    8000147e:	894e                	mv	s2,s3
    mem = kalloc();
    80001480:	fffff097          	auipc	ra,0xfffff
    80001484:	674080e7          	jalr	1652(ra) # 80000af4 <kalloc>
    80001488:	84aa                	mv	s1,a0
    if(mem == 0){
    8000148a:	c51d                	beqz	a0,800014b8 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000148c:	6605                	lui	a2,0x1
    8000148e:	4581                	li	a1,0
    80001490:	00000097          	auipc	ra,0x0
    80001494:	882080e7          	jalr	-1918(ra) # 80000d12 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001498:	4779                	li	a4,30
    8000149a:	86a6                	mv	a3,s1
    8000149c:	6605                	lui	a2,0x1
    8000149e:	85ca                	mv	a1,s2
    800014a0:	8556                	mv	a0,s5
    800014a2:	00000097          	auipc	ra,0x0
    800014a6:	c40080e7          	jalr	-960(ra) # 800010e2 <mappages>
    800014aa:	e905                	bnez	a0,800014da <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014ac:	6785                	lui	a5,0x1
    800014ae:	993e                	add	s2,s2,a5
    800014b0:	fd4968e3          	bltu	s2,s4,80001480 <uvmalloc+0x2c>
  return newsz;
    800014b4:	8552                	mv	a0,s4
    800014b6:	a809                	j	800014c8 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014b8:	864e                	mv	a2,s3
    800014ba:	85ca                	mv	a1,s2
    800014bc:	8556                	mv	a0,s5
    800014be:	00000097          	auipc	ra,0x0
    800014c2:	f4e080e7          	jalr	-178(ra) # 8000140c <uvmdealloc>
      return 0;
    800014c6:	4501                	li	a0,0
}
    800014c8:	70e2                	ld	ra,56(sp)
    800014ca:	7442                	ld	s0,48(sp)
    800014cc:	74a2                	ld	s1,40(sp)
    800014ce:	7902                	ld	s2,32(sp)
    800014d0:	69e2                	ld	s3,24(sp)
    800014d2:	6a42                	ld	s4,16(sp)
    800014d4:	6aa2                	ld	s5,8(sp)
    800014d6:	6121                	addi	sp,sp,64
    800014d8:	8082                	ret
      kfree(mem);
    800014da:	8526                	mv	a0,s1
    800014dc:	fffff097          	auipc	ra,0xfffff
    800014e0:	51c080e7          	jalr	1308(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014e4:	864e                	mv	a2,s3
    800014e6:	85ca                	mv	a1,s2
    800014e8:	8556                	mv	a0,s5
    800014ea:	00000097          	auipc	ra,0x0
    800014ee:	f22080e7          	jalr	-222(ra) # 8000140c <uvmdealloc>
      return 0;
    800014f2:	4501                	li	a0,0
    800014f4:	bfd1                	j	800014c8 <uvmalloc+0x74>
    return oldsz;
    800014f6:	852e                	mv	a0,a1
}
    800014f8:	8082                	ret
  return newsz;
    800014fa:	8532                	mv	a0,a2
    800014fc:	b7f1                	j	800014c8 <uvmalloc+0x74>

00000000800014fe <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014fe:	7179                	addi	sp,sp,-48
    80001500:	f406                	sd	ra,40(sp)
    80001502:	f022                	sd	s0,32(sp)
    80001504:	ec26                	sd	s1,24(sp)
    80001506:	e84a                	sd	s2,16(sp)
    80001508:	e44e                	sd	s3,8(sp)
    8000150a:	e052                	sd	s4,0(sp)
    8000150c:	1800                	addi	s0,sp,48
    8000150e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001510:	84aa                	mv	s1,a0
    80001512:	6905                	lui	s2,0x1
    80001514:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001516:	4985                	li	s3,1
    80001518:	a821                	j	80001530 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000151a:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000151c:	0532                	slli	a0,a0,0xc
    8000151e:	00000097          	auipc	ra,0x0
    80001522:	fe0080e7          	jalr	-32(ra) # 800014fe <freewalk>
      pagetable[i] = 0;
    80001526:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000152a:	04a1                	addi	s1,s1,8
    8000152c:	03248163          	beq	s1,s2,8000154e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001530:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001532:	00f57793          	andi	a5,a0,15
    80001536:	ff3782e3          	beq	a5,s3,8000151a <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000153a:	8905                	andi	a0,a0,1
    8000153c:	d57d                	beqz	a0,8000152a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000153e:	00007517          	auipc	a0,0x7
    80001542:	c4250513          	addi	a0,a0,-958 # 80008180 <digits+0x140>
    80001546:	fffff097          	auipc	ra,0xfffff
    8000154a:	ff8080e7          	jalr	-8(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000154e:	8552                	mv	a0,s4
    80001550:	fffff097          	auipc	ra,0xfffff
    80001554:	4a8080e7          	jalr	1192(ra) # 800009f8 <kfree>
}
    80001558:	70a2                	ld	ra,40(sp)
    8000155a:	7402                	ld	s0,32(sp)
    8000155c:	64e2                	ld	s1,24(sp)
    8000155e:	6942                	ld	s2,16(sp)
    80001560:	69a2                	ld	s3,8(sp)
    80001562:	6a02                	ld	s4,0(sp)
    80001564:	6145                	addi	sp,sp,48
    80001566:	8082                	ret

0000000080001568 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001568:	1101                	addi	sp,sp,-32
    8000156a:	ec06                	sd	ra,24(sp)
    8000156c:	e822                	sd	s0,16(sp)
    8000156e:	e426                	sd	s1,8(sp)
    80001570:	1000                	addi	s0,sp,32
    80001572:	84aa                	mv	s1,a0
  if(sz > 0)
    80001574:	e999                	bnez	a1,8000158a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001576:	8526                	mv	a0,s1
    80001578:	00000097          	auipc	ra,0x0
    8000157c:	f86080e7          	jalr	-122(ra) # 800014fe <freewalk>
}
    80001580:	60e2                	ld	ra,24(sp)
    80001582:	6442                	ld	s0,16(sp)
    80001584:	64a2                	ld	s1,8(sp)
    80001586:	6105                	addi	sp,sp,32
    80001588:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000158a:	6605                	lui	a2,0x1
    8000158c:	167d                	addi	a2,a2,-1
    8000158e:	962e                	add	a2,a2,a1
    80001590:	4685                	li	a3,1
    80001592:	8231                	srli	a2,a2,0xc
    80001594:	4581                	li	a1,0
    80001596:	00000097          	auipc	ra,0x0
    8000159a:	d12080e7          	jalr	-750(ra) # 800012a8 <uvmunmap>
    8000159e:	bfe1                	j	80001576 <uvmfree+0xe>

00000000800015a0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015a0:	c679                	beqz	a2,8000166e <uvmcopy+0xce>
{
    800015a2:	715d                	addi	sp,sp,-80
    800015a4:	e486                	sd	ra,72(sp)
    800015a6:	e0a2                	sd	s0,64(sp)
    800015a8:	fc26                	sd	s1,56(sp)
    800015aa:	f84a                	sd	s2,48(sp)
    800015ac:	f44e                	sd	s3,40(sp)
    800015ae:	f052                	sd	s4,32(sp)
    800015b0:	ec56                	sd	s5,24(sp)
    800015b2:	e85a                	sd	s6,16(sp)
    800015b4:	e45e                	sd	s7,8(sp)
    800015b6:	0880                	addi	s0,sp,80
    800015b8:	8b2a                	mv	s6,a0
    800015ba:	8aae                	mv	s5,a1
    800015bc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015be:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015c0:	4601                	li	a2,0
    800015c2:	85ce                	mv	a1,s3
    800015c4:	855a                	mv	a0,s6
    800015c6:	00000097          	auipc	ra,0x0
    800015ca:	a34080e7          	jalr	-1484(ra) # 80000ffa <walk>
    800015ce:	c531                	beqz	a0,8000161a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015d0:	6118                	ld	a4,0(a0)
    800015d2:	00177793          	andi	a5,a4,1
    800015d6:	cbb1                	beqz	a5,8000162a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015d8:	00a75593          	srli	a1,a4,0xa
    800015dc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015e0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	510080e7          	jalr	1296(ra) # 80000af4 <kalloc>
    800015ec:	892a                	mv	s2,a0
    800015ee:	c939                	beqz	a0,80001644 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015f0:	6605                	lui	a2,0x1
    800015f2:	85de                	mv	a1,s7
    800015f4:	fffff097          	auipc	ra,0xfffff
    800015f8:	77e080e7          	jalr	1918(ra) # 80000d72 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015fc:	8726                	mv	a4,s1
    800015fe:	86ca                	mv	a3,s2
    80001600:	6605                	lui	a2,0x1
    80001602:	85ce                	mv	a1,s3
    80001604:	8556                	mv	a0,s5
    80001606:	00000097          	auipc	ra,0x0
    8000160a:	adc080e7          	jalr	-1316(ra) # 800010e2 <mappages>
    8000160e:	e515                	bnez	a0,8000163a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001610:	6785                	lui	a5,0x1
    80001612:	99be                	add	s3,s3,a5
    80001614:	fb49e6e3          	bltu	s3,s4,800015c0 <uvmcopy+0x20>
    80001618:	a081                	j	80001658 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000161a:	00007517          	auipc	a0,0x7
    8000161e:	b7650513          	addi	a0,a0,-1162 # 80008190 <digits+0x150>
    80001622:	fffff097          	auipc	ra,0xfffff
    80001626:	f1c080e7          	jalr	-228(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    8000162a:	00007517          	auipc	a0,0x7
    8000162e:	b8650513          	addi	a0,a0,-1146 # 800081b0 <digits+0x170>
    80001632:	fffff097          	auipc	ra,0xfffff
    80001636:	f0c080e7          	jalr	-244(ra) # 8000053e <panic>
      kfree(mem);
    8000163a:	854a                	mv	a0,s2
    8000163c:	fffff097          	auipc	ra,0xfffff
    80001640:	3bc080e7          	jalr	956(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001644:	4685                	li	a3,1
    80001646:	00c9d613          	srli	a2,s3,0xc
    8000164a:	4581                	li	a1,0
    8000164c:	8556                	mv	a0,s5
    8000164e:	00000097          	auipc	ra,0x0
    80001652:	c5a080e7          	jalr	-934(ra) # 800012a8 <uvmunmap>
  return -1;
    80001656:	557d                	li	a0,-1
}
    80001658:	60a6                	ld	ra,72(sp)
    8000165a:	6406                	ld	s0,64(sp)
    8000165c:	74e2                	ld	s1,56(sp)
    8000165e:	7942                	ld	s2,48(sp)
    80001660:	79a2                	ld	s3,40(sp)
    80001662:	7a02                	ld	s4,32(sp)
    80001664:	6ae2                	ld	s5,24(sp)
    80001666:	6b42                	ld	s6,16(sp)
    80001668:	6ba2                	ld	s7,8(sp)
    8000166a:	6161                	addi	sp,sp,80
    8000166c:	8082                	ret
  return 0;
    8000166e:	4501                	li	a0,0
}
    80001670:	8082                	ret

0000000080001672 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001672:	1141                	addi	sp,sp,-16
    80001674:	e406                	sd	ra,8(sp)
    80001676:	e022                	sd	s0,0(sp)
    80001678:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000167a:	4601                	li	a2,0
    8000167c:	00000097          	auipc	ra,0x0
    80001680:	97e080e7          	jalr	-1666(ra) # 80000ffa <walk>
  if(pte == 0)
    80001684:	c901                	beqz	a0,80001694 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001686:	611c                	ld	a5,0(a0)
    80001688:	9bbd                	andi	a5,a5,-17
    8000168a:	e11c                	sd	a5,0(a0)
}
    8000168c:	60a2                	ld	ra,8(sp)
    8000168e:	6402                	ld	s0,0(sp)
    80001690:	0141                	addi	sp,sp,16
    80001692:	8082                	ret
    panic("uvmclear");
    80001694:	00007517          	auipc	a0,0x7
    80001698:	b3c50513          	addi	a0,a0,-1220 # 800081d0 <digits+0x190>
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	ea2080e7          	jalr	-350(ra) # 8000053e <panic>

00000000800016a4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016a4:	c6bd                	beqz	a3,80001712 <copyout+0x6e>
{
    800016a6:	715d                	addi	sp,sp,-80
    800016a8:	e486                	sd	ra,72(sp)
    800016aa:	e0a2                	sd	s0,64(sp)
    800016ac:	fc26                	sd	s1,56(sp)
    800016ae:	f84a                	sd	s2,48(sp)
    800016b0:	f44e                	sd	s3,40(sp)
    800016b2:	f052                	sd	s4,32(sp)
    800016b4:	ec56                	sd	s5,24(sp)
    800016b6:	e85a                	sd	s6,16(sp)
    800016b8:	e45e                	sd	s7,8(sp)
    800016ba:	e062                	sd	s8,0(sp)
    800016bc:	0880                	addi	s0,sp,80
    800016be:	8b2a                	mv	s6,a0
    800016c0:	8c2e                	mv	s8,a1
    800016c2:	8a32                	mv	s4,a2
    800016c4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016c6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016c8:	6a85                	lui	s5,0x1
    800016ca:	a015                	j	800016ee <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016cc:	9562                	add	a0,a0,s8
    800016ce:	0004861b          	sext.w	a2,s1
    800016d2:	85d2                	mv	a1,s4
    800016d4:	41250533          	sub	a0,a0,s2
    800016d8:	fffff097          	auipc	ra,0xfffff
    800016dc:	69a080e7          	jalr	1690(ra) # 80000d72 <memmove>

    len -= n;
    800016e0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016e4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016e6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ea:	02098263          	beqz	s3,8000170e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ee:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016f2:	85ca                	mv	a1,s2
    800016f4:	855a                	mv	a0,s6
    800016f6:	00000097          	auipc	ra,0x0
    800016fa:	9aa080e7          	jalr	-1622(ra) # 800010a0 <walkaddr>
    if(pa0 == 0)
    800016fe:	cd01                	beqz	a0,80001716 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001700:	418904b3          	sub	s1,s2,s8
    80001704:	94d6                	add	s1,s1,s5
    if(n > len)
    80001706:	fc99f3e3          	bgeu	s3,s1,800016cc <copyout+0x28>
    8000170a:	84ce                	mv	s1,s3
    8000170c:	b7c1                	j	800016cc <copyout+0x28>
  }
  return 0;
    8000170e:	4501                	li	a0,0
    80001710:	a021                	j	80001718 <copyout+0x74>
    80001712:	4501                	li	a0,0
}
    80001714:	8082                	ret
      return -1;
    80001716:	557d                	li	a0,-1
}
    80001718:	60a6                	ld	ra,72(sp)
    8000171a:	6406                	ld	s0,64(sp)
    8000171c:	74e2                	ld	s1,56(sp)
    8000171e:	7942                	ld	s2,48(sp)
    80001720:	79a2                	ld	s3,40(sp)
    80001722:	7a02                	ld	s4,32(sp)
    80001724:	6ae2                	ld	s5,24(sp)
    80001726:	6b42                	ld	s6,16(sp)
    80001728:	6ba2                	ld	s7,8(sp)
    8000172a:	6c02                	ld	s8,0(sp)
    8000172c:	6161                	addi	sp,sp,80
    8000172e:	8082                	ret

0000000080001730 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001730:	c6bd                	beqz	a3,8000179e <copyin+0x6e>
{
    80001732:	715d                	addi	sp,sp,-80
    80001734:	e486                	sd	ra,72(sp)
    80001736:	e0a2                	sd	s0,64(sp)
    80001738:	fc26                	sd	s1,56(sp)
    8000173a:	f84a                	sd	s2,48(sp)
    8000173c:	f44e                	sd	s3,40(sp)
    8000173e:	f052                	sd	s4,32(sp)
    80001740:	ec56                	sd	s5,24(sp)
    80001742:	e85a                	sd	s6,16(sp)
    80001744:	e45e                	sd	s7,8(sp)
    80001746:	e062                	sd	s8,0(sp)
    80001748:	0880                	addi	s0,sp,80
    8000174a:	8b2a                	mv	s6,a0
    8000174c:	8a2e                	mv	s4,a1
    8000174e:	8c32                	mv	s8,a2
    80001750:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001752:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001754:	6a85                	lui	s5,0x1
    80001756:	a015                	j	8000177a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001758:	9562                	add	a0,a0,s8
    8000175a:	0004861b          	sext.w	a2,s1
    8000175e:	412505b3          	sub	a1,a0,s2
    80001762:	8552                	mv	a0,s4
    80001764:	fffff097          	auipc	ra,0xfffff
    80001768:	60e080e7          	jalr	1550(ra) # 80000d72 <memmove>

    len -= n;
    8000176c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001770:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001772:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001776:	02098263          	beqz	s3,8000179a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000177a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000177e:	85ca                	mv	a1,s2
    80001780:	855a                	mv	a0,s6
    80001782:	00000097          	auipc	ra,0x0
    80001786:	91e080e7          	jalr	-1762(ra) # 800010a0 <walkaddr>
    if(pa0 == 0)
    8000178a:	cd01                	beqz	a0,800017a2 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000178c:	418904b3          	sub	s1,s2,s8
    80001790:	94d6                	add	s1,s1,s5
    if(n > len)
    80001792:	fc99f3e3          	bgeu	s3,s1,80001758 <copyin+0x28>
    80001796:	84ce                	mv	s1,s3
    80001798:	b7c1                	j	80001758 <copyin+0x28>
  }
  return 0;
    8000179a:	4501                	li	a0,0
    8000179c:	a021                	j	800017a4 <copyin+0x74>
    8000179e:	4501                	li	a0,0
}
    800017a0:	8082                	ret
      return -1;
    800017a2:	557d                	li	a0,-1
}
    800017a4:	60a6                	ld	ra,72(sp)
    800017a6:	6406                	ld	s0,64(sp)
    800017a8:	74e2                	ld	s1,56(sp)
    800017aa:	7942                	ld	s2,48(sp)
    800017ac:	79a2                	ld	s3,40(sp)
    800017ae:	7a02                	ld	s4,32(sp)
    800017b0:	6ae2                	ld	s5,24(sp)
    800017b2:	6b42                	ld	s6,16(sp)
    800017b4:	6ba2                	ld	s7,8(sp)
    800017b6:	6c02                	ld	s8,0(sp)
    800017b8:	6161                	addi	sp,sp,80
    800017ba:	8082                	ret

00000000800017bc <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017bc:	c6c5                	beqz	a3,80001864 <copyinstr+0xa8>
{
    800017be:	715d                	addi	sp,sp,-80
    800017c0:	e486                	sd	ra,72(sp)
    800017c2:	e0a2                	sd	s0,64(sp)
    800017c4:	fc26                	sd	s1,56(sp)
    800017c6:	f84a                	sd	s2,48(sp)
    800017c8:	f44e                	sd	s3,40(sp)
    800017ca:	f052                	sd	s4,32(sp)
    800017cc:	ec56                	sd	s5,24(sp)
    800017ce:	e85a                	sd	s6,16(sp)
    800017d0:	e45e                	sd	s7,8(sp)
    800017d2:	0880                	addi	s0,sp,80
    800017d4:	8a2a                	mv	s4,a0
    800017d6:	8b2e                	mv	s6,a1
    800017d8:	8bb2                	mv	s7,a2
    800017da:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017dc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017de:	6985                	lui	s3,0x1
    800017e0:	a035                	j	8000180c <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017e2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017e6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017e8:	0017b793          	seqz	a5,a5
    800017ec:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017f0:	60a6                	ld	ra,72(sp)
    800017f2:	6406                	ld	s0,64(sp)
    800017f4:	74e2                	ld	s1,56(sp)
    800017f6:	7942                	ld	s2,48(sp)
    800017f8:	79a2                	ld	s3,40(sp)
    800017fa:	7a02                	ld	s4,32(sp)
    800017fc:	6ae2                	ld	s5,24(sp)
    800017fe:	6b42                	ld	s6,16(sp)
    80001800:	6ba2                	ld	s7,8(sp)
    80001802:	6161                	addi	sp,sp,80
    80001804:	8082                	ret
    srcva = va0 + PGSIZE;
    80001806:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000180a:	c8a9                	beqz	s1,8000185c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000180c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001810:	85ca                	mv	a1,s2
    80001812:	8552                	mv	a0,s4
    80001814:	00000097          	auipc	ra,0x0
    80001818:	88c080e7          	jalr	-1908(ra) # 800010a0 <walkaddr>
    if(pa0 == 0)
    8000181c:	c131                	beqz	a0,80001860 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000181e:	41790833          	sub	a6,s2,s7
    80001822:	984e                	add	a6,a6,s3
    if(n > max)
    80001824:	0104f363          	bgeu	s1,a6,8000182a <copyinstr+0x6e>
    80001828:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000182a:	955e                	add	a0,a0,s7
    8000182c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001830:	fc080be3          	beqz	a6,80001806 <copyinstr+0x4a>
    80001834:	985a                	add	a6,a6,s6
    80001836:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001838:	41650633          	sub	a2,a0,s6
    8000183c:	14fd                	addi	s1,s1,-1
    8000183e:	9b26                	add	s6,s6,s1
    80001840:	00f60733          	add	a4,a2,a5
    80001844:	00074703          	lbu	a4,0(a4)
    80001848:	df49                	beqz	a4,800017e2 <copyinstr+0x26>
        *dst = *p;
    8000184a:	00e78023          	sb	a4,0(a5)
      --max;
    8000184e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001852:	0785                	addi	a5,a5,1
    while(n > 0){
    80001854:	ff0796e3          	bne	a5,a6,80001840 <copyinstr+0x84>
      dst++;
    80001858:	8b42                	mv	s6,a6
    8000185a:	b775                	j	80001806 <copyinstr+0x4a>
    8000185c:	4781                	li	a5,0
    8000185e:	b769                	j	800017e8 <copyinstr+0x2c>
      return -1;
    80001860:	557d                	li	a0,-1
    80001862:	b779                	j	800017f0 <copyinstr+0x34>
  int got_null = 0;
    80001864:	4781                	li	a5,0
  if(got_null){
    80001866:	0017b793          	seqz	a5,a5
    8000186a:	40f00533          	neg	a0,a5
}
    8000186e:	8082                	ret

0000000080001870 <remove_first>:
#endif

int cpus_num = CPUS;

int remove_first(int *head_list, struct spinlock *head_lock)
{
    80001870:	7139                	addi	sp,sp,-64
    80001872:	fc06                	sd	ra,56(sp)
    80001874:	f822                	sd	s0,48(sp)
    80001876:	f426                	sd	s1,40(sp)
    80001878:	f04a                	sd	s2,32(sp)
    8000187a:	ec4e                	sd	s3,24(sp)
    8000187c:	e852                	sd	s4,16(sp)
    8000187e:	e456                	sd	s5,8(sp)
    80001880:	0080                	addi	s0,sp,64
    80001882:	8aaa                	mv	s5,a0
    80001884:	89ae                	mv	s3,a1
  acquire(head_lock);
    80001886:	852e                	mv	a0,a1
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	364080e7          	jalr	868(ra) # 80000bec <acquire>
  if (*head_list == -1)
    80001890:	000aa483          	lw	s1,0(s5) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001894:	57fd                	li	a5,-1
    80001896:	04f48d63          	beq	s1,a5,800018f0 <remove_first+0x80>
  {
    release(head_lock);
    return -1;
  }
  struct proc *p = &proc[*head_list];
  acquire(&p->p_lock);
    8000189a:	18800793          	li	a5,392
    8000189e:	02f484b3          	mul	s1,s1,a5
    800018a2:	03848a13          	addi	s4,s1,56
    800018a6:	00010917          	auipc	s2,0x10
    800018aa:	ff290913          	addi	s2,s2,-14 # 80011898 <proc>
    800018ae:	9a4a                	add	s4,s4,s2
    800018b0:	8552                	mv	a0,s4
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	33a080e7          	jalr	826(ra) # 80000bec <acquire>
  *head_list = p->next;
    800018ba:	94ca                	add	s1,s1,s2
    800018bc:	48bc                	lw	a5,80(s1)
    800018be:	00faa023          	sw	a5,0(s5)
  p->next = -1;
    800018c2:	57fd                	li	a5,-1
    800018c4:	c8bc                	sw	a5,80(s1)
  release(&p->p_lock);
    800018c6:	8552                	mv	a0,s4
    800018c8:	fffff097          	auipc	ra,0xfffff
    800018cc:	3f0080e7          	jalr	1008(ra) # 80000cb8 <release>
  release(head_lock);
    800018d0:	854e                	mv	a0,s3
    800018d2:	fffff097          	auipc	ra,0xfffff
    800018d6:	3e6080e7          	jalr	998(ra) # 80000cb8 <release>
  return p->proc_idx;
    800018da:	48e4                	lw	s1,84(s1)
}
    800018dc:	8526                	mv	a0,s1
    800018de:	70e2                	ld	ra,56(sp)
    800018e0:	7442                	ld	s0,48(sp)
    800018e2:	74a2                	ld	s1,40(sp)
    800018e4:	7902                	ld	s2,32(sp)
    800018e6:	69e2                	ld	s3,24(sp)
    800018e8:	6a42                	ld	s4,16(sp)
    800018ea:	6aa2                	ld	s5,8(sp)
    800018ec:	6121                	addi	sp,sp,64
    800018ee:	8082                	ret
    release(head_lock);
    800018f0:	854e                	mv	a0,s3
    800018f2:	fffff097          	auipc	ra,0xfffff
    800018f6:	3c6080e7          	jalr	966(ra) # 80000cb8 <release>
    return -1;
    800018fa:	b7cd                	j	800018dc <remove_first+0x6c>

00000000800018fc <find_remove>:

int find_remove(struct proc *curr_proc, struct proc *to_remove)
{
    800018fc:	7139                	addi	sp,sp,-64
    800018fe:	fc06                	sd	ra,56(sp)
    80001900:	f822                	sd	s0,48(sp)
    80001902:	f426                	sd	s1,40(sp)
    80001904:	f04a                	sd	s2,32(sp)
    80001906:	ec4e                	sd	s3,24(sp)
    80001908:	e852                	sd	s4,16(sp)
    8000190a:	e456                	sd	s5,8(sp)
    8000190c:	0080                	addi	s0,sp,64
    8000190e:	84aa                	mv	s1,a0
  while (curr_proc->next != -1)
    80001910:	4928                	lw	a0,80(a0)
    80001912:	57fd                	li	a5,-1
    80001914:	04f50963          	beq	a0,a5,80001966 <find_remove+0x6a>
    80001918:	8a2e                	mv	s4,a1
  {
    acquire(&proc[curr_proc->next].p_lock);
    8000191a:	18800993          	li	s3,392
    8000191e:	00010917          	auipc	s2,0x10
    80001922:	f7a90913          	addi	s2,s2,-134 # 80011898 <proc>
  while (curr_proc->next != -1)
    80001926:	5afd                	li	s5,-1
    acquire(&proc[curr_proc->next].p_lock);
    80001928:	03350533          	mul	a0,a0,s3
    8000192c:	03850513          	addi	a0,a0,56
    80001930:	954a                	add	a0,a0,s2
    80001932:	fffff097          	auipc	ra,0xfffff
    80001936:	2ba080e7          	jalr	698(ra) # 80000bec <acquire>
    if (proc[curr_proc->next].proc_idx == to_remove->proc_idx)
    8000193a:	48bc                	lw	a5,80(s1)
    8000193c:	033787b3          	mul	a5,a5,s3
    80001940:	97ca                	add	a5,a5,s2
    80001942:	4bf8                	lw	a4,84(a5)
    80001944:	054a2783          	lw	a5,84(s4) # fffffffffffff054 <end+0xffffffff7ffd9054>
    80001948:	02f70f63          	beq	a4,a5,80001986 <find_remove+0x8a>
      to_remove->next = -1;
      release(&to_remove->p_lock);
      release(&curr_proc->p_lock);
      return 1;
    }
    release(&curr_proc->p_lock);
    8000194c:	03848513          	addi	a0,s1,56
    80001950:	fffff097          	auipc	ra,0xfffff
    80001954:	368080e7          	jalr	872(ra) # 80000cb8 <release>
    curr_proc = &proc[curr_proc->next];
    80001958:	48a4                	lw	s1,80(s1)
    8000195a:	033484b3          	mul	s1,s1,s3
    8000195e:	94ca                	add	s1,s1,s2
  while (curr_proc->next != -1)
    80001960:	48a8                	lw	a0,80(s1)
    80001962:	fd5513e3          	bne	a0,s5,80001928 <find_remove+0x2c>
  }
  release(&curr_proc->p_lock);
    80001966:	03848513          	addi	a0,s1,56
    8000196a:	fffff097          	auipc	ra,0xfffff
    8000196e:	34e080e7          	jalr	846(ra) # 80000cb8 <release>
  return -1;
    80001972:	557d                	li	a0,-1
}
    80001974:	70e2                	ld	ra,56(sp)
    80001976:	7442                	ld	s0,48(sp)
    80001978:	74a2                	ld	s1,40(sp)
    8000197a:	7902                	ld	s2,32(sp)
    8000197c:	69e2                	ld	s3,24(sp)
    8000197e:	6a42                	ld	s4,16(sp)
    80001980:	6aa2                	ld	s5,8(sp)
    80001982:	6121                	addi	sp,sp,64
    80001984:	8082                	ret
      curr_proc->next = to_remove->next;
    80001986:	050a2783          	lw	a5,80(s4)
    8000198a:	c8bc                	sw	a5,80(s1)
      to_remove->next = -1;
    8000198c:	57fd                	li	a5,-1
    8000198e:	04fa2823          	sw	a5,80(s4)
      release(&to_remove->p_lock);
    80001992:	038a0513          	addi	a0,s4,56
    80001996:	fffff097          	auipc	ra,0xfffff
    8000199a:	322080e7          	jalr	802(ra) # 80000cb8 <release>
      release(&curr_proc->p_lock);
    8000199e:	03848513          	addi	a0,s1,56
    800019a2:	fffff097          	auipc	ra,0xfffff
    800019a6:	316080e7          	jalr	790(ra) # 80000cb8 <release>
      return 1;
    800019aa:	4505                	li	a0,1
    800019ac:	b7e1                	j	80001974 <find_remove+0x78>

00000000800019ae <remove_proc>:

int remove_proc(int *head_list, struct proc *to_remove, struct spinlock *head_lock)
{
    800019ae:	7179                	addi	sp,sp,-48
    800019b0:	f406                	sd	ra,40(sp)
    800019b2:	f022                	sd	s0,32(sp)
    800019b4:	ec26                	sd	s1,24(sp)
    800019b6:	e84a                	sd	s2,16(sp)
    800019b8:	e44e                	sd	s3,8(sp)
    800019ba:	e052                	sd	s4,0(sp)
    800019bc:	1800                	addi	s0,sp,48
    800019be:	892a                	mv	s2,a0
    800019c0:	8a2e                	mv	s4,a1
    800019c2:	89b2                	mv	s3,a2
  acquire(head_lock);
    800019c4:	8532                	mv	a0,a2
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	226080e7          	jalr	550(ra) # 80000bec <acquire>
  if (*head_list == -1) // empty list case
    800019ce:	00092483          	lw	s1,0(s2)
    800019d2:	57fd                	li	a5,-1
    800019d4:	06f48463          	beq	s1,a5,80001a3c <remove_proc+0x8e>
  {
    release(head_lock);
    return -1;
  }
  acquire(&proc[*head_list].p_lock);
    800019d8:	18800513          	li	a0,392
    800019dc:	02a484b3          	mul	s1,s1,a0
    800019e0:	00010517          	auipc	a0,0x10
    800019e4:	ef050513          	addi	a0,a0,-272 # 800118d0 <proc+0x38>
    800019e8:	9526                	add	a0,a0,s1
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	202080e7          	jalr	514(ra) # 80000bec <acquire>
  if (*head_list == to_remove->proc_idx)
    800019f2:	00092703          	lw	a4,0(s2)
    800019f6:	054a2783          	lw	a5,84(s4)
    800019fa:	04f70763          	beq	a4,a5,80001a48 <remove_proc+0x9a>
    to_remove->next = -1;
    release(&to_remove->p_lock);
    release(head_lock);
    return 1;
  }
  release(head_lock);
    800019fe:	854e                	mv	a0,s3
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	2b8080e7          	jalr	696(ra) # 80000cb8 <release>
  return find_remove(&proc[*head_list], to_remove);
    80001a08:	00092783          	lw	a5,0(s2)
    80001a0c:	18800513          	li	a0,392
    80001a10:	02a787b3          	mul	a5,a5,a0
    80001a14:	85d2                	mv	a1,s4
    80001a16:	00010517          	auipc	a0,0x10
    80001a1a:	e8250513          	addi	a0,a0,-382 # 80011898 <proc>
    80001a1e:	953e                	add	a0,a0,a5
    80001a20:	00000097          	auipc	ra,0x0
    80001a24:	edc080e7          	jalr	-292(ra) # 800018fc <find_remove>
    80001a28:	84aa                	mv	s1,a0
}
    80001a2a:	8526                	mv	a0,s1
    80001a2c:	70a2                	ld	ra,40(sp)
    80001a2e:	7402                	ld	s0,32(sp)
    80001a30:	64e2                	ld	s1,24(sp)
    80001a32:	6942                	ld	s2,16(sp)
    80001a34:	69a2                	ld	s3,8(sp)
    80001a36:	6a02                	ld	s4,0(sp)
    80001a38:	6145                	addi	sp,sp,48
    80001a3a:	8082                	ret
    release(head_lock);
    80001a3c:	854e                	mv	a0,s3
    80001a3e:	fffff097          	auipc	ra,0xfffff
    80001a42:	27a080e7          	jalr	634(ra) # 80000cb8 <release>
    return -1;
    80001a46:	b7d5                	j	80001a2a <remove_proc+0x7c>
    *head_list = to_remove->next;
    80001a48:	050a2783          	lw	a5,80(s4)
    80001a4c:	00f92023          	sw	a5,0(s2)
    to_remove->next = -1;
    80001a50:	57fd                	li	a5,-1
    80001a52:	04fa2823          	sw	a5,80(s4)
    release(&to_remove->p_lock);
    80001a56:	038a0513          	addi	a0,s4,56
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	25e080e7          	jalr	606(ra) # 80000cb8 <release>
    release(head_lock);
    80001a62:	854e                	mv	a0,s3
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	254080e7          	jalr	596(ra) # 80000cb8 <release>
    return 1;
    80001a6c:	4485                	li	s1,1
    80001a6e:	bf75                	j	80001a2a <remove_proc+0x7c>

0000000080001a70 <add_not_first>:

void add_not_first(struct proc *curr, struct proc *to_add)
{
    80001a70:	7139                	addi	sp,sp,-64
    80001a72:	fc06                	sd	ra,56(sp)
    80001a74:	f822                	sd	s0,48(sp)
    80001a76:	f426                	sd	s1,40(sp)
    80001a78:	f04a                	sd	s2,32(sp)
    80001a7a:	ec4e                	sd	s3,24(sp)
    80001a7c:	e852                	sd	s4,16(sp)
    80001a7e:	e456                	sd	s5,8(sp)
    80001a80:	0080                	addi	s0,sp,64
    80001a82:	84aa                	mv	s1,a0
    80001a84:	8aae                	mv	s5,a1
  while (curr->next != -1)
    80001a86:	4928                	lw	a0,80(a0)
    80001a88:	57fd                	li	a5,-1
    80001a8a:	02f50f63          	beq	a0,a5,80001ac8 <add_not_first+0x58>
  {
    acquire(&proc[curr->next].p_lock);
    80001a8e:	18800993          	li	s3,392
    80001a92:	00010917          	auipc	s2,0x10
    80001a96:	e0690913          	addi	s2,s2,-506 # 80011898 <proc>
  while (curr->next != -1)
    80001a9a:	5a7d                	li	s4,-1
    acquire(&proc[curr->next].p_lock);
    80001a9c:	03350533          	mul	a0,a0,s3
    80001aa0:	03850513          	addi	a0,a0,56
    80001aa4:	954a                	add	a0,a0,s2
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	146080e7          	jalr	326(ra) # 80000bec <acquire>
    release(&curr->p_lock); //  NEED to add prev
    80001aae:	03848513          	addi	a0,s1,56
    80001ab2:	fffff097          	auipc	ra,0xfffff
    80001ab6:	206080e7          	jalr	518(ra) # 80000cb8 <release>
    curr = &proc[curr->next];
    80001aba:	48a4                	lw	s1,80(s1)
    80001abc:	033484b3          	mul	s1,s1,s3
    80001ac0:	94ca                	add	s1,s1,s2
  while (curr->next != -1)
    80001ac2:	48a8                	lw	a0,80(s1)
    80001ac4:	fd451ce3          	bne	a0,s4,80001a9c <add_not_first+0x2c>
  }
  to_add->next = -1;
    80001ac8:	57fd                	li	a5,-1
    80001aca:	04faa823          	sw	a5,80(s5)
  curr->next = to_add->proc_idx;
    80001ace:	054aa783          	lw	a5,84(s5)
    80001ad2:	c8bc                	sw	a5,80(s1)
  release(&curr->p_lock);
    80001ad4:	03848513          	addi	a0,s1,56
    80001ad8:	fffff097          	auipc	ra,0xfffff
    80001adc:	1e0080e7          	jalr	480(ra) # 80000cb8 <release>
}
    80001ae0:	70e2                	ld	ra,56(sp)
    80001ae2:	7442                	ld	s0,48(sp)
    80001ae4:	74a2                	ld	s1,40(sp)
    80001ae6:	7902                	ld	s2,32(sp)
    80001ae8:	69e2                	ld	s3,24(sp)
    80001aea:	6a42                	ld	s4,16(sp)
    80001aec:	6aa2                	ld	s5,8(sp)
    80001aee:	6121                	addi	sp,sp,64
    80001af0:	8082                	ret

0000000080001af2 <add_proc>:

void add_proc(int *head, struct proc *to_add, struct spinlock *head_lock)
{
    80001af2:	7139                	addi	sp,sp,-64
    80001af4:	fc06                	sd	ra,56(sp)
    80001af6:	f822                	sd	s0,48(sp)
    80001af8:	f426                	sd	s1,40(sp)
    80001afa:	f04a                	sd	s2,32(sp)
    80001afc:	ec4e                	sd	s3,24(sp)
    80001afe:	e852                	sd	s4,16(sp)
    80001b00:	e456                	sd	s5,8(sp)
    80001b02:	0080                	addi	s0,sp,64
    80001b04:	84aa                	mv	s1,a0
    80001b06:	89ae                	mv	s3,a1
    80001b08:	8932                	mv	s2,a2
  acquire(head_lock);
    80001b0a:	8532                	mv	a0,a2
    80001b0c:	fffff097          	auipc	ra,0xfffff
    80001b10:	0e0080e7          	jalr	224(ra) # 80000bec <acquire>
  if (*head == -1)
    80001b14:	409c                	lw	a5,0(s1)
    80001b16:	577d                	li	a4,-1
    80001b18:	04e78963          	beq	a5,a4,80001b6a <add_proc+0x78>
    proc[*head].next = -1;
    release(head_lock);
  }
  else
  {
    acquire(&proc[*head].p_lock);
    80001b1c:	18800a93          	li	s5,392
    80001b20:	035787b3          	mul	a5,a5,s5
    80001b24:	03878793          	addi	a5,a5,56
    80001b28:	00010a17          	auipc	s4,0x10
    80001b2c:	d70a0a13          	addi	s4,s4,-656 # 80011898 <proc>
    80001b30:	00fa0533          	add	a0,s4,a5
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	0b8080e7          	jalr	184(ra) # 80000bec <acquire>
    release(head_lock);
    80001b3c:	854a                	mv	a0,s2
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	17a080e7          	jalr	378(ra) # 80000cb8 <release>
    add_not_first(&proc[*head], to_add);
    80001b46:	4088                	lw	a0,0(s1)
    80001b48:	03550533          	mul	a0,a0,s5
    80001b4c:	85ce                	mv	a1,s3
    80001b4e:	9552                	add	a0,a0,s4
    80001b50:	00000097          	auipc	ra,0x0
    80001b54:	f20080e7          	jalr	-224(ra) # 80001a70 <add_not_first>
  }
}
    80001b58:	70e2                	ld	ra,56(sp)
    80001b5a:	7442                	ld	s0,48(sp)
    80001b5c:	74a2                	ld	s1,40(sp)
    80001b5e:	7902                	ld	s2,32(sp)
    80001b60:	69e2                	ld	s3,24(sp)
    80001b62:	6a42                	ld	s4,16(sp)
    80001b64:	6aa2                	ld	s5,8(sp)
    80001b66:	6121                	addi	sp,sp,64
    80001b68:	8082                	ret
    *head = to_add->proc_idx;
    80001b6a:	0549a783          	lw	a5,84(s3) # 1054 <_entry-0x7fffefac>
    80001b6e:	c09c                	sw	a5,0(s1)
    proc[*head].next = -1;
    80001b70:	18800713          	li	a4,392
    80001b74:	02e787b3          	mul	a5,a5,a4
    80001b78:	00010717          	auipc	a4,0x10
    80001b7c:	d2070713          	addi	a4,a4,-736 # 80011898 <proc>
    80001b80:	97ba                	add	a5,a5,a4
    80001b82:	577d                	li	a4,-1
    80001b84:	cbb8                	sw	a4,80(a5)
    release(head_lock);
    80001b86:	854a                	mv	a0,s2
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	130080e7          	jalr	304(ra) # 80000cb8 <release>
    80001b90:	b7e1                	j	80001b58 <add_proc+0x66>

0000000080001b92 <init_locksncpus>:
void init_locksncpus()
{
    80001b92:	7139                	addi	sp,sp,-64
    80001b94:	fc06                	sd	ra,56(sp)
    80001b96:	f822                	sd	s0,48(sp)
    80001b98:	f426                	sd	s1,40(sp)
    80001b9a:	f04a                	sd	s2,32(sp)
    80001b9c:	ec4e                	sd	s3,24(sp)
    80001b9e:	e852                	sd	s4,16(sp)
    80001ba0:	e456                	sd	s5,8(sp)
    80001ba2:	0080                	addi	s0,sp,64
  struct cpu *c;
  int i = 0;
  initlock(&zombie_lock, "zombie");
    80001ba4:	00006597          	auipc	a1,0x6
    80001ba8:	63c58593          	addi	a1,a1,1596 # 800081e0 <digits+0x1a0>
    80001bac:	00010517          	auipc	a0,0x10
    80001bb0:	c7450513          	addi	a0,a0,-908 # 80011820 <zombie_lock>
    80001bb4:	fffff097          	auipc	ra,0xfffff
    80001bb8:	fa0080e7          	jalr	-96(ra) # 80000b54 <initlock>
  initlock(&unused_lock, "unused");
    80001bbc:	00006597          	auipc	a1,0x6
    80001bc0:	62c58593          	addi	a1,a1,1580 # 800081e8 <digits+0x1a8>
    80001bc4:	00010517          	auipc	a0,0x10
    80001bc8:	c7450513          	addi	a0,a0,-908 # 80011838 <unused_lock>
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	f88080e7          	jalr	-120(ra) # 80000b54 <initlock>
  initlock(&sleeping_lock, "sleeping");
    80001bd4:	00006597          	auipc	a1,0x6
    80001bd8:	61c58593          	addi	a1,a1,1564 # 800081f0 <digits+0x1b0>
    80001bdc:	00010517          	auipc	a0,0x10
    80001be0:	c7450513          	addi	a0,a0,-908 # 80011850 <sleeping_lock>
    80001be4:	fffff097          	auipc	ra,0xfffff
    80001be8:	f70080e7          	jalr	-144(ra) # 80000b54 <initlock>
  int i = 0;
    80001bec:	4901                	li	s2,0
  for (c = cpus; c < &cpus[NCPU]; c++)
    80001bee:	0000f497          	auipc	s1,0xf
    80001bf2:	6b248493          	addi	s1,s1,1714 # 800112a0 <cpus>
  {
    c->cpu_idx = i;
    c->runnable_head = -1;
    80001bf6:	5afd                	li	s5,-1
    c->proc_counter = 0;
    initlock(&c->head_lock, "runnable");
    80001bf8:	00006a17          	auipc	s4,0x6
    80001bfc:	608a0a13          	addi	s4,s4,1544 # 80008200 <digits+0x1c0>
  for (c = cpus; c < &cpus[NCPU]; c++)
    80001c00:	49a1                	li	s3,8
    c->cpu_idx = i;
    80001c02:	0124a023          	sw	s2,0(s1)
    c->runnable_head = -1;
    80001c06:	0954a423          	sw	s5,136(s1)
    c->proc_counter = 0;
    80001c0a:	0a04b423          	sd	zero,168(s1)
    initlock(&c->head_lock, "runnable");
    80001c0e:	85d2                	mv	a1,s4
    80001c10:	09048513          	addi	a0,s1,144
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	f40080e7          	jalr	-192(ra) # 80000b54 <initlock>
    i++;
    80001c1c:	2905                	addiw	s2,s2,1
  for (c = cpus; c < &cpus[NCPU]; c++)
    80001c1e:	0b048493          	addi	s1,s1,176
    80001c22:	ff3910e3          	bne	s2,s3,80001c02 <init_locksncpus+0x70>
  }
}
    80001c26:	70e2                	ld	ra,56(sp)
    80001c28:	7442                	ld	s0,48(sp)
    80001c2a:	74a2                	ld	s1,40(sp)
    80001c2c:	7902                	ld	s2,32(sp)
    80001c2e:	69e2                	ld	s3,24(sp)
    80001c30:	6a42                	ld	s4,16(sp)
    80001c32:	6aa2                	ld	s5,8(sp)
    80001c34:	6121                	addi	sp,sp,64
    80001c36:	8082                	ret

0000000080001c38 <least_used_cpu>:

int least_used_cpu()
{
    80001c38:	1141                	addi	sp,sp,-16
    80001c3a:	e422                	sd	s0,8(sp)
    80001c3c:	0800                	addi	s0,sp,16
  struct cpu *c = &cpus[0];
  int least_used = 0;
  int min_proc_counter = c->proc_counter;
    80001c3e:	0000f697          	auipc	a3,0xf
    80001c42:	70a6b683          	ld	a3,1802(a3) # 80011348 <cpus+0xa8>

  for (int i = 1; i < cpus_num; i++)
    80001c46:	00007817          	auipc	a6,0x7
    80001c4a:	c0e82803          	lw	a6,-1010(a6) # 80008854 <cpus_num>
    80001c4e:	4785                	li	a5,1
    80001c50:	0307db63          	bge	a5,a6,80001c86 <least_used_cpu+0x4e>
    80001c54:	2681                	sext.w	a3,a3
  int least_used = 0;
    80001c56:	4501                	li	a0,0
  {
    c = &cpus[i];
    if (c->proc_counter < min_proc_counter)
    80001c58:	0000f597          	auipc	a1,0xf
    80001c5c:	64858593          	addi	a1,a1,1608 # 800112a0 <cpus>
    80001c60:	0b000613          	li	a2,176
    80001c64:	a021                	j	80001c6c <least_used_cpu+0x34>
  for (int i = 1; i < cpus_num; i++)
    80001c66:	2785                	addiw	a5,a5,1
    80001c68:	03078063          	beq	a5,a6,80001c88 <least_used_cpu+0x50>
    if (c->proc_counter < min_proc_counter)
    80001c6c:	02c78733          	mul	a4,a5,a2
    80001c70:	972e                	add	a4,a4,a1
    80001c72:	7758                	ld	a4,168(a4)
    80001c74:	fed779e3          	bgeu	a4,a3,80001c66 <least_used_cpu+0x2e>
    {
      least_used = i;
      min_proc_counter = c->proc_counter;
    80001c78:	02c78733          	mul	a4,a5,a2
    80001c7c:	972e                	add	a4,a4,a1
    80001c7e:	7754                	ld	a3,168(a4)
    80001c80:	2681                	sext.w	a3,a3
    80001c82:	853e                	mv	a0,a5
    80001c84:	b7cd                	j	80001c66 <least_used_cpu+0x2e>
  int least_used = 0;
    80001c86:	4501                	li	a0,0
    }
  }
  return least_used;
}
    80001c88:	6422                	ld	s0,8(sp)
    80001c8a:	0141                	addi	sp,sp,16
    80001c8c:	8082                	ret

0000000080001c8e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001c8e:	7139                	addi	sp,sp,-64
    80001c90:	fc06                	sd	ra,56(sp)
    80001c92:	f822                	sd	s0,48(sp)
    80001c94:	f426                	sd	s1,40(sp)
    80001c96:	f04a                	sd	s2,32(sp)
    80001c98:	ec4e                	sd	s3,24(sp)
    80001c9a:	e852                	sd	s4,16(sp)
    80001c9c:	e456                	sd	s5,8(sp)
    80001c9e:	e05a                	sd	s6,0(sp)
    80001ca0:	0080                	addi	s0,sp,64
    80001ca2:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001ca4:	00010497          	auipc	s1,0x10
    80001ca8:	bf448493          	addi	s1,s1,-1036 # 80011898 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001cac:	8b26                	mv	s6,s1
    80001cae:	00006a97          	auipc	s5,0x6
    80001cb2:	352a8a93          	addi	s5,s5,850 # 80008000 <etext>
    80001cb6:	04000937          	lui	s2,0x4000
    80001cba:	197d                	addi	s2,s2,-1
    80001cbc:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001cbe:	00016a17          	auipc	s4,0x16
    80001cc2:	ddaa0a13          	addi	s4,s4,-550 # 80017a98 <tickslock>
    char *pa = kalloc();
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	e2e080e7          	jalr	-466(ra) # 80000af4 <kalloc>
    80001cce:	862a                	mv	a2,a0
    if (pa == 0)
    80001cd0:	c131                	beqz	a0,80001d14 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001cd2:	416485b3          	sub	a1,s1,s6
    80001cd6:	858d                	srai	a1,a1,0x3
    80001cd8:	000ab783          	ld	a5,0(s5)
    80001cdc:	02f585b3          	mul	a1,a1,a5
    80001ce0:	2585                	addiw	a1,a1,1
    80001ce2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ce6:	4719                	li	a4,6
    80001ce8:	6685                	lui	a3,0x1
    80001cea:	40b905b3          	sub	a1,s2,a1
    80001cee:	854e                	mv	a0,s3
    80001cf0:	fffff097          	auipc	ra,0xfffff
    80001cf4:	492080e7          	jalr	1170(ra) # 80001182 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001cf8:	18848493          	addi	s1,s1,392
    80001cfc:	fd4495e3          	bne	s1,s4,80001cc6 <proc_mapstacks+0x38>
  }
}
    80001d00:	70e2                	ld	ra,56(sp)
    80001d02:	7442                	ld	s0,48(sp)
    80001d04:	74a2                	ld	s1,40(sp)
    80001d06:	7902                	ld	s2,32(sp)
    80001d08:	69e2                	ld	s3,24(sp)
    80001d0a:	6a42                	ld	s4,16(sp)
    80001d0c:	6aa2                	ld	s5,8(sp)
    80001d0e:	6b02                	ld	s6,0(sp)
    80001d10:	6121                	addi	sp,sp,64
    80001d12:	8082                	ret
      panic("kalloc");
    80001d14:	00006517          	auipc	a0,0x6
    80001d18:	4fc50513          	addi	a0,a0,1276 # 80008210 <digits+0x1d0>
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	822080e7          	jalr	-2014(ra) # 8000053e <panic>

0000000080001d24 <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    80001d24:	711d                	addi	sp,sp,-96
    80001d26:	ec86                	sd	ra,88(sp)
    80001d28:	e8a2                	sd	s0,80(sp)
    80001d2a:	e4a6                	sd	s1,72(sp)
    80001d2c:	e0ca                	sd	s2,64(sp)
    80001d2e:	fc4e                	sd	s3,56(sp)
    80001d30:	f852                	sd	s4,48(sp)
    80001d32:	f456                	sd	s5,40(sp)
    80001d34:	f05a                	sd	s6,32(sp)
    80001d36:	ec5e                	sd	s7,24(sp)
    80001d38:	e862                	sd	s8,16(sp)
    80001d3a:	e466                	sd	s9,8(sp)
    80001d3c:	e06a                	sd	s10,0(sp)
    80001d3e:	1080                	addi	s0,sp,96
  init_locksncpus();
    80001d40:	00000097          	auipc	ra,0x0
    80001d44:	e52080e7          	jalr	-430(ra) # 80001b92 <init_locksncpus>
  int i = 0;
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001d48:	00006597          	auipc	a1,0x6
    80001d4c:	4d058593          	addi	a1,a1,1232 # 80008218 <digits+0x1d8>
    80001d50:	00010517          	auipc	a0,0x10
    80001d54:	b1850513          	addi	a0,a0,-1256 # 80011868 <pid_lock>
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	dfc080e7          	jalr	-516(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001d60:	00006597          	auipc	a1,0x6
    80001d64:	4c058593          	addi	a1,a1,1216 # 80008220 <digits+0x1e0>
    80001d68:	00010517          	auipc	a0,0x10
    80001d6c:	b1850513          	addi	a0,a0,-1256 # 80011880 <wait_lock>
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	de4080e7          	jalr	-540(ra) # 80000b54 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d78:	00010497          	auipc	s1,0x10
    80001d7c:	b2048493          	addi	s1,s1,-1248 # 80011898 <proc>
  int i = 0;
    80001d80:	4901                	li	s2,0
  {
    initlock(&p->lock, "proc");
    80001d82:	00006d17          	auipc	s10,0x6
    80001d86:	4aed0d13          	addi	s10,s10,1198 # 80008230 <digits+0x1f0>
    initlock(&p->p_lock, "p_lock");
    80001d8a:	00006c97          	auipc	s9,0x6
    80001d8e:	4aec8c93          	addi	s9,s9,1198 # 80008238 <digits+0x1f8>
    p->kstack = KSTACK((int)(p - proc));
    80001d92:	8c26                	mv	s8,s1
    80001d94:	00006b97          	auipc	s7,0x6
    80001d98:	26cb8b93          	addi	s7,s7,620 # 80008000 <etext>
    80001d9c:	040009b7          	lui	s3,0x4000
    80001da0:	19fd                	addi	s3,s3,-1
    80001da2:	09b2                	slli	s3,s3,0xc
    p->proc_idx = i;
    p->next = -1;
    80001da4:	5b7d                	li	s6,-1
    add_proc(&unused_head, p, &unused_lock);
    80001da6:	00010a97          	auipc	s5,0x10
    80001daa:	a92a8a93          	addi	s5,s5,-1390 # 80011838 <unused_lock>
    80001dae:	00007a17          	auipc	s4,0x7
    80001db2:	aaea0a13          	addi	s4,s4,-1362 # 8000885c <unused_head>
    initlock(&p->lock, "proc");
    80001db6:	85ea                	mv	a1,s10
    80001db8:	8526                	mv	a0,s1
    80001dba:	fffff097          	auipc	ra,0xfffff
    80001dbe:	d9a080e7          	jalr	-614(ra) # 80000b54 <initlock>
    initlock(&p->p_lock, "p_lock");
    80001dc2:	85e6                	mv	a1,s9
    80001dc4:	03848513          	addi	a0,s1,56
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	d8c080e7          	jalr	-628(ra) # 80000b54 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    80001dd0:	418487b3          	sub	a5,s1,s8
    80001dd4:	878d                	srai	a5,a5,0x3
    80001dd6:	000bb703          	ld	a4,0(s7)
    80001dda:	02e787b3          	mul	a5,a5,a4
    80001dde:	2785                	addiw	a5,a5,1
    80001de0:	00d7979b          	slliw	a5,a5,0xd
    80001de4:	40f987b3          	sub	a5,s3,a5
    80001de8:	f0bc                	sd	a5,96(s1)
    p->proc_idx = i;
    80001dea:	0524aa23          	sw	s2,84(s1)
    p->next = -1;
    80001dee:	0564a823          	sw	s6,80(s1)
    add_proc(&unused_head, p, &unused_lock);
    80001df2:	8656                	mv	a2,s5
    80001df4:	85a6                	mv	a1,s1
    80001df6:	8552                	mv	a0,s4
    80001df8:	00000097          	auipc	ra,0x0
    80001dfc:	cfa080e7          	jalr	-774(ra) # 80001af2 <add_proc>
    i++;
    80001e00:	2905                	addiw	s2,s2,1
  for (p = proc; p < &proc[NPROC]; p++)
    80001e02:	18848493          	addi	s1,s1,392
    80001e06:	04000793          	li	a5,64
    80001e0a:	faf916e3          	bne	s2,a5,80001db6 <procinit+0x92>
  }
}
    80001e0e:	60e6                	ld	ra,88(sp)
    80001e10:	6446                	ld	s0,80(sp)
    80001e12:	64a6                	ld	s1,72(sp)
    80001e14:	6906                	ld	s2,64(sp)
    80001e16:	79e2                	ld	s3,56(sp)
    80001e18:	7a42                	ld	s4,48(sp)
    80001e1a:	7aa2                	ld	s5,40(sp)
    80001e1c:	7b02                	ld	s6,32(sp)
    80001e1e:	6be2                	ld	s7,24(sp)
    80001e20:	6c42                	ld	s8,16(sp)
    80001e22:	6ca2                	ld	s9,8(sp)
    80001e24:	6d02                	ld	s10,0(sp)
    80001e26:	6125                	addi	sp,sp,96
    80001e28:	8082                	ret

0000000080001e2a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001e2a:	1141                	addi	sp,sp,-16
    80001e2c:	e422                	sd	s0,8(sp)
    80001e2e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e30:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001e32:	2501                	sext.w	a0,a0
    80001e34:	6422                	ld	s0,8(sp)
    80001e36:	0141                	addi	sp,sp,16
    80001e38:	8082                	ret

0000000080001e3a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001e3a:	1141                	addi	sp,sp,-16
    80001e3c:	e422                	sd	s0,8(sp)
    80001e3e:	0800                	addi	s0,sp,16
    80001e40:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001e42:	2781                	sext.w	a5,a5
    80001e44:	0b000513          	li	a0,176
    80001e48:	02a787b3          	mul	a5,a5,a0
  return c;
}
    80001e4c:	0000f517          	auipc	a0,0xf
    80001e50:	45450513          	addi	a0,a0,1108 # 800112a0 <cpus>
    80001e54:	953e                	add	a0,a0,a5
    80001e56:	6422                	ld	s0,8(sp)
    80001e58:	0141                	addi	sp,sp,16
    80001e5a:	8082                	ret

0000000080001e5c <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001e5c:	1101                	addi	sp,sp,-32
    80001e5e:	ec06                	sd	ra,24(sp)
    80001e60:	e822                	sd	s0,16(sp)
    80001e62:	e426                	sd	s1,8(sp)
    80001e64:	1000                	addi	s0,sp,32
  push_off();
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	d32080e7          	jalr	-718(ra) # 80000b98 <push_off>
    80001e6e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001e70:	2781                	sext.w	a5,a5
    80001e72:	0b000713          	li	a4,176
    80001e76:	02e787b3          	mul	a5,a5,a4
    80001e7a:	0000f717          	auipc	a4,0xf
    80001e7e:	42670713          	addi	a4,a4,1062 # 800112a0 <cpus>
    80001e82:	97ba                	add	a5,a5,a4
    80001e84:	6784                	ld	s1,8(a5)
  pop_off();
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	dcc080e7          	jalr	-564(ra) # 80000c52 <pop_off>
  return p;
}
    80001e8e:	8526                	mv	a0,s1
    80001e90:	60e2                	ld	ra,24(sp)
    80001e92:	6442                	ld	s0,16(sp)
    80001e94:	64a2                	ld	s1,8(sp)
    80001e96:	6105                	addi	sp,sp,32
    80001e98:	8082                	ret

0000000080001e9a <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001e9a:	1141                	addi	sp,sp,-16
    80001e9c:	e406                	sd	ra,8(sp)
    80001e9e:	e022                	sd	s0,0(sp)
    80001ea0:	0800                	addi	s0,sp,16
  static int first = 1;
  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001ea2:	00000097          	auipc	ra,0x0
    80001ea6:	fba080e7          	jalr	-70(ra) # 80001e5c <myproc>
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	e0e080e7          	jalr	-498(ra) # 80000cb8 <release>

  if (first)
    80001eb2:	00007797          	auipc	a5,0x7
    80001eb6:	99e7a783          	lw	a5,-1634(a5) # 80008850 <first.1751>
    80001eba:	eb89                	bnez	a5,80001ecc <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001ebc:	00001097          	auipc	ra,0x1
    80001ec0:	0a8080e7          	jalr	168(ra) # 80002f64 <usertrapret>
}
    80001ec4:	60a2                	ld	ra,8(sp)
    80001ec6:	6402                	ld	s0,0(sp)
    80001ec8:	0141                	addi	sp,sp,16
    80001eca:	8082                	ret
    first = 0;
    80001ecc:	00007797          	auipc	a5,0x7
    80001ed0:	9807a223          	sw	zero,-1660(a5) # 80008850 <first.1751>
    fsinit(ROOTDEV);
    80001ed4:	4505                	li	a0,1
    80001ed6:	00002097          	auipc	ra,0x2
    80001eda:	e1a080e7          	jalr	-486(ra) # 80003cf0 <fsinit>
    80001ede:	bff9                	j	80001ebc <forkret+0x22>

0000000080001ee0 <allocpid>:
{
    80001ee0:	1101                	addi	sp,sp,-32
    80001ee2:	ec06                	sd	ra,24(sp)
    80001ee4:	e822                	sd	s0,16(sp)
    80001ee6:	e426                	sd	s1,8(sp)
    80001ee8:	e04a                	sd	s2,0(sp)
    80001eea:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001eec:	00007917          	auipc	s2,0x7
    80001ef0:	97c90913          	addi	s2,s2,-1668 # 80008868 <nextpid>
    80001ef4:	00092603          	lw	a2,0(s2)
    80001ef8:	0006049b          	sext.w	s1,a2
  } while (cas(&nextpid, pid, pid + 1));
    80001efc:	2605                	addiw	a2,a2,1
    80001efe:	85a6                	mv	a1,s1
    80001f00:	854a                	mv	a0,s2
    80001f02:	00005097          	auipc	ra,0x5
    80001f06:	bf4080e7          	jalr	-1036(ra) # 80006af6 <cas>
    80001f0a:	f56d                	bnez	a0,80001ef4 <allocpid+0x14>
}
    80001f0c:	8526                	mv	a0,s1
    80001f0e:	60e2                	ld	ra,24(sp)
    80001f10:	6442                	ld	s0,16(sp)
    80001f12:	64a2                	ld	s1,8(sp)
    80001f14:	6902                	ld	s2,0(sp)
    80001f16:	6105                	addi	sp,sp,32
    80001f18:	8082                	ret

0000000080001f1a <proc_pagetable>:
{
    80001f1a:	1101                	addi	sp,sp,-32
    80001f1c:	ec06                	sd	ra,24(sp)
    80001f1e:	e822                	sd	s0,16(sp)
    80001f20:	e426                	sd	s1,8(sp)
    80001f22:	e04a                	sd	s2,0(sp)
    80001f24:	1000                	addi	s0,sp,32
    80001f26:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	444080e7          	jalr	1092(ra) # 8000136c <uvmcreate>
    80001f30:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001f32:	c121                	beqz	a0,80001f72 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001f34:	4729                	li	a4,10
    80001f36:	00005697          	auipc	a3,0x5
    80001f3a:	0ca68693          	addi	a3,a3,202 # 80007000 <_trampoline>
    80001f3e:	6605                	lui	a2,0x1
    80001f40:	040005b7          	lui	a1,0x4000
    80001f44:	15fd                	addi	a1,a1,-1
    80001f46:	05b2                	slli	a1,a1,0xc
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	19a080e7          	jalr	410(ra) # 800010e2 <mappages>
    80001f50:	02054863          	bltz	a0,80001f80 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001f54:	4719                	li	a4,6
    80001f56:	07893683          	ld	a3,120(s2)
    80001f5a:	6605                	lui	a2,0x1
    80001f5c:	020005b7          	lui	a1,0x2000
    80001f60:	15fd                	addi	a1,a1,-1
    80001f62:	05b6                	slli	a1,a1,0xd
    80001f64:	8526                	mv	a0,s1
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	17c080e7          	jalr	380(ra) # 800010e2 <mappages>
    80001f6e:	02054163          	bltz	a0,80001f90 <proc_pagetable+0x76>
}
    80001f72:	8526                	mv	a0,s1
    80001f74:	60e2                	ld	ra,24(sp)
    80001f76:	6442                	ld	s0,16(sp)
    80001f78:	64a2                	ld	s1,8(sp)
    80001f7a:	6902                	ld	s2,0(sp)
    80001f7c:	6105                	addi	sp,sp,32
    80001f7e:	8082                	ret
    uvmfree(pagetable, 0);
    80001f80:	4581                	li	a1,0
    80001f82:	8526                	mv	a0,s1
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	5e4080e7          	jalr	1508(ra) # 80001568 <uvmfree>
    return 0;
    80001f8c:	4481                	li	s1,0
    80001f8e:	b7d5                	j	80001f72 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f90:	4681                	li	a3,0
    80001f92:	4605                	li	a2,1
    80001f94:	040005b7          	lui	a1,0x4000
    80001f98:	15fd                	addi	a1,a1,-1
    80001f9a:	05b2                	slli	a1,a1,0xc
    80001f9c:	8526                	mv	a0,s1
    80001f9e:	fffff097          	auipc	ra,0xfffff
    80001fa2:	30a080e7          	jalr	778(ra) # 800012a8 <uvmunmap>
    uvmfree(pagetable, 0);
    80001fa6:	4581                	li	a1,0
    80001fa8:	8526                	mv	a0,s1
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	5be080e7          	jalr	1470(ra) # 80001568 <uvmfree>
    return 0;
    80001fb2:	4481                	li	s1,0
    80001fb4:	bf7d                	j	80001f72 <proc_pagetable+0x58>

0000000080001fb6 <proc_freepagetable>:
{
    80001fb6:	1101                	addi	sp,sp,-32
    80001fb8:	ec06                	sd	ra,24(sp)
    80001fba:	e822                	sd	s0,16(sp)
    80001fbc:	e426                	sd	s1,8(sp)
    80001fbe:	e04a                	sd	s2,0(sp)
    80001fc0:	1000                	addi	s0,sp,32
    80001fc2:	84aa                	mv	s1,a0
    80001fc4:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001fc6:	4681                	li	a3,0
    80001fc8:	4605                	li	a2,1
    80001fca:	040005b7          	lui	a1,0x4000
    80001fce:	15fd                	addi	a1,a1,-1
    80001fd0:	05b2                	slli	a1,a1,0xc
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	2d6080e7          	jalr	726(ra) # 800012a8 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001fda:	4681                	li	a3,0
    80001fdc:	4605                	li	a2,1
    80001fde:	020005b7          	lui	a1,0x2000
    80001fe2:	15fd                	addi	a1,a1,-1
    80001fe4:	05b6                	slli	a1,a1,0xd
    80001fe6:	8526                	mv	a0,s1
    80001fe8:	fffff097          	auipc	ra,0xfffff
    80001fec:	2c0080e7          	jalr	704(ra) # 800012a8 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ff0:	85ca                	mv	a1,s2
    80001ff2:	8526                	mv	a0,s1
    80001ff4:	fffff097          	auipc	ra,0xfffff
    80001ff8:	574080e7          	jalr	1396(ra) # 80001568 <uvmfree>
}
    80001ffc:	60e2                	ld	ra,24(sp)
    80001ffe:	6442                	ld	s0,16(sp)
    80002000:	64a2                	ld	s1,8(sp)
    80002002:	6902                	ld	s2,0(sp)
    80002004:	6105                	addi	sp,sp,32
    80002006:	8082                	ret

0000000080002008 <freeproc>:
{
    80002008:	1101                	addi	sp,sp,-32
    8000200a:	ec06                	sd	ra,24(sp)
    8000200c:	e822                	sd	s0,16(sp)
    8000200e:	e426                	sd	s1,8(sp)
    80002010:	1000                	addi	s0,sp,32
    80002012:	84aa                	mv	s1,a0
  if (p->trapframe)
    80002014:	7d28                	ld	a0,120(a0)
    80002016:	c509                	beqz	a0,80002020 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80002018:	fffff097          	auipc	ra,0xfffff
    8000201c:	9e0080e7          	jalr	-1568(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80002020:	0604bc23          	sd	zero,120(s1)
  if (p->pagetable)
    80002024:	78a8                	ld	a0,112(s1)
    80002026:	c511                	beqz	a0,80002032 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80002028:	74ac                	ld	a1,104(s1)
    8000202a:	00000097          	auipc	ra,0x0
    8000202e:	f8c080e7          	jalr	-116(ra) # 80001fb6 <proc_freepagetable>
  p->pagetable = 0;
    80002032:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80002036:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    8000203a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    8000203e:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80002042:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80002046:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    8000204a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    8000204e:	0204a623          	sw	zero,44(s1)
  remove_proc(&zombie_head, p, &zombie_lock);
    80002052:	0000f617          	auipc	a2,0xf
    80002056:	7ce60613          	addi	a2,a2,1998 # 80011820 <zombie_lock>
    8000205a:	85a6                	mv	a1,s1
    8000205c:	00007517          	auipc	a0,0x7
    80002060:	80850513          	addi	a0,a0,-2040 # 80008864 <zombie_head>
    80002064:	00000097          	auipc	ra,0x0
    80002068:	94a080e7          	jalr	-1718(ra) # 800019ae <remove_proc>
  p->state = UNUSED;
    8000206c:	0004ac23          	sw	zero,24(s1)
  add_proc(&unused_head, p, &unused_lock);
    80002070:	0000f617          	auipc	a2,0xf
    80002074:	7c860613          	addi	a2,a2,1992 # 80011838 <unused_lock>
    80002078:	85a6                	mv	a1,s1
    8000207a:	00006517          	auipc	a0,0x6
    8000207e:	7e250513          	addi	a0,a0,2018 # 8000885c <unused_head>
    80002082:	00000097          	auipc	ra,0x0
    80002086:	a70080e7          	jalr	-1424(ra) # 80001af2 <add_proc>
}
    8000208a:	60e2                	ld	ra,24(sp)
    8000208c:	6442                	ld	s0,16(sp)
    8000208e:	64a2                	ld	s1,8(sp)
    80002090:	6105                	addi	sp,sp,32
    80002092:	8082                	ret

0000000080002094 <allocproc>:
{
    80002094:	7179                	addi	sp,sp,-48
    80002096:	f406                	sd	ra,40(sp)
    80002098:	f022                	sd	s0,32(sp)
    8000209a:	ec26                	sd	s1,24(sp)
    8000209c:	e84a                	sd	s2,16(sp)
    8000209e:	e44e                	sd	s3,8(sp)
    800020a0:	e052                	sd	s4,0(sp)
    800020a2:	1800                	addi	s0,sp,48
  if (unused_head != -1)
    800020a4:	00006917          	auipc	s2,0x6
    800020a8:	7b892903          	lw	s2,1976(s2) # 8000885c <unused_head>
    800020ac:	57fd                	li	a5,-1
  return 0;
    800020ae:	4481                	li	s1,0
  if (unused_head != -1)
    800020b0:	0af90b63          	beq	s2,a5,80002166 <allocproc+0xd2>
    p = &proc[unused_head];
    800020b4:	18800993          	li	s3,392
    800020b8:	033909b3          	mul	s3,s2,s3
    800020bc:	0000f497          	auipc	s1,0xf
    800020c0:	7dc48493          	addi	s1,s1,2012 # 80011898 <proc>
    800020c4:	94ce                	add	s1,s1,s3
    acquire(&p->lock);
    800020c6:	8526                	mv	a0,s1
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	b24080e7          	jalr	-1244(ra) # 80000bec <acquire>
  p->pid = allocpid();
    800020d0:	00000097          	auipc	ra,0x0
    800020d4:	e10080e7          	jalr	-496(ra) # 80001ee0 <allocpid>
    800020d8:	d888                	sw	a0,48(s1)
  remove_proc(&unused_head, p, &unused_lock);
    800020da:	0000f617          	auipc	a2,0xf
    800020de:	75e60613          	addi	a2,a2,1886 # 80011838 <unused_lock>
    800020e2:	85a6                	mv	a1,s1
    800020e4:	00006517          	auipc	a0,0x6
    800020e8:	77850513          	addi	a0,a0,1912 # 8000885c <unused_head>
    800020ec:	00000097          	auipc	ra,0x0
    800020f0:	8c2080e7          	jalr	-1854(ra) # 800019ae <remove_proc>
  p->state = USED;
    800020f4:	4785                	li	a5,1
    800020f6:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	9fc080e7          	jalr	-1540(ra) # 80000af4 <kalloc>
    80002100:	8a2a                	mv	s4,a0
    80002102:	fca8                	sd	a0,120(s1)
    80002104:	c935                	beqz	a0,80002178 <allocproc+0xe4>
  p->pagetable = proc_pagetable(p);
    80002106:	8526                	mv	a0,s1
    80002108:	00000097          	auipc	ra,0x0
    8000210c:	e12080e7          	jalr	-494(ra) # 80001f1a <proc_pagetable>
    80002110:	8a2a                	mv	s4,a0
    80002112:	18800793          	li	a5,392
    80002116:	02f90733          	mul	a4,s2,a5
    8000211a:	0000f797          	auipc	a5,0xf
    8000211e:	77e78793          	addi	a5,a5,1918 # 80011898 <proc>
    80002122:	97ba                	add	a5,a5,a4
    80002124:	fba8                	sd	a0,112(a5)
  if (p->pagetable == 0)
    80002126:	c52d                	beqz	a0,80002190 <allocproc+0xfc>
  memset(&p->context, 0, sizeof(p->context));
    80002128:	08098513          	addi	a0,s3,128 # 4000080 <_entry-0x7bffff80>
    8000212c:	0000fa17          	auipc	s4,0xf
    80002130:	76ca0a13          	addi	s4,s4,1900 # 80011898 <proc>
    80002134:	07000613          	li	a2,112
    80002138:	4581                	li	a1,0
    8000213a:	9552                	add	a0,a0,s4
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	bd6080e7          	jalr	-1066(ra) # 80000d12 <memset>
  p->context.ra = (uint64)forkret;
    80002144:	18800793          	li	a5,392
    80002148:	02f90933          	mul	s2,s2,a5
    8000214c:	9952                	add	s2,s2,s4
    8000214e:	00000797          	auipc	a5,0x0
    80002152:	d4c78793          	addi	a5,a5,-692 # 80001e9a <forkret>
    80002156:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    8000215a:	06093783          	ld	a5,96(s2)
    8000215e:	6705                	lui	a4,0x1
    80002160:	97ba                	add	a5,a5,a4
    80002162:	08f93423          	sd	a5,136(s2)
}
    80002166:	8526                	mv	a0,s1
    80002168:	70a2                	ld	ra,40(sp)
    8000216a:	7402                	ld	s0,32(sp)
    8000216c:	64e2                	ld	s1,24(sp)
    8000216e:	6942                	ld	s2,16(sp)
    80002170:	69a2                	ld	s3,8(sp)
    80002172:	6a02                	ld	s4,0(sp)
    80002174:	6145                	addi	sp,sp,48
    80002176:	8082                	ret
    freeproc(p);
    80002178:	8526                	mv	a0,s1
    8000217a:	00000097          	auipc	ra,0x0
    8000217e:	e8e080e7          	jalr	-370(ra) # 80002008 <freeproc>
    release(&p->lock);
    80002182:	8526                	mv	a0,s1
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	b34080e7          	jalr	-1228(ra) # 80000cb8 <release>
    return 0;
    8000218c:	84d2                	mv	s1,s4
    8000218e:	bfe1                	j	80002166 <allocproc+0xd2>
    freeproc(p);
    80002190:	8526                	mv	a0,s1
    80002192:	00000097          	auipc	ra,0x0
    80002196:	e76080e7          	jalr	-394(ra) # 80002008 <freeproc>
    release(&p->lock);
    8000219a:	8526                	mv	a0,s1
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	b1c080e7          	jalr	-1252(ra) # 80000cb8 <release>
    return 0;
    800021a4:	84d2                	mv	s1,s4
    800021a6:	b7c1                	j	80002166 <allocproc+0xd2>

00000000800021a8 <userinit>:
{
    800021a8:	1101                	addi	sp,sp,-32
    800021aa:	ec06                	sd	ra,24(sp)
    800021ac:	e822                	sd	s0,16(sp)
    800021ae:	e426                	sd	s1,8(sp)
    800021b0:	1000                	addi	s0,sp,32
  p = allocproc();
    800021b2:	00000097          	auipc	ra,0x0
    800021b6:	ee2080e7          	jalr	-286(ra) # 80002094 <allocproc>
    800021ba:	84aa                	mv	s1,a0
  initproc = p;
    800021bc:	00007797          	auipc	a5,0x7
    800021c0:	e6a7b623          	sd	a0,-404(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800021c4:	03400613          	li	a2,52
    800021c8:	00006597          	auipc	a1,0x6
    800021cc:	6a858593          	addi	a1,a1,1704 # 80008870 <initcode>
    800021d0:	7928                	ld	a0,112(a0)
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	1c8080e7          	jalr	456(ra) # 8000139a <uvminit>
  p->sz = PGSIZE;
    800021da:	6785                	lui	a5,0x1
    800021dc:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;     // user program counter
    800021de:	7cb8                	ld	a4,120(s1)
    800021e0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    800021e4:	7cb8                	ld	a4,120(s1)
    800021e6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800021e8:	4641                	li	a2,16
    800021ea:	00006597          	auipc	a1,0x6
    800021ee:	05658593          	addi	a1,a1,86 # 80008240 <digits+0x200>
    800021f2:	17848513          	addi	a0,s1,376
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	c6e080e7          	jalr	-914(ra) # 80000e64 <safestrcpy>
  p->cwd = namei("/");
    800021fe:	00006517          	auipc	a0,0x6
    80002202:	05250513          	addi	a0,a0,82 # 80008250 <digits+0x210>
    80002206:	00002097          	auipc	ra,0x2
    8000220a:	518080e7          	jalr	1304(ra) # 8000471e <namei>
    8000220e:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80002212:	478d                	li	a5,3
    80002214:	cc9c                	sw	a5,24(s1)
  add_proc(&cpus[0].runnable_head, p, &cpus[0].head_lock);
    80002216:	0000f617          	auipc	a2,0xf
    8000221a:	11a60613          	addi	a2,a2,282 # 80011330 <cpus+0x90>
    8000221e:	85a6                	mv	a1,s1
    80002220:	0000f517          	auipc	a0,0xf
    80002224:	10850513          	addi	a0,a0,264 # 80011328 <cpus+0x88>
    80002228:	00000097          	auipc	ra,0x0
    8000222c:	8ca080e7          	jalr	-1846(ra) # 80001af2 <add_proc>
  release(&p->lock);
    80002230:	8526                	mv	a0,s1
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	a86080e7          	jalr	-1402(ra) # 80000cb8 <release>
}
    8000223a:	60e2                	ld	ra,24(sp)
    8000223c:	6442                	ld	s0,16(sp)
    8000223e:	64a2                	ld	s1,8(sp)
    80002240:	6105                	addi	sp,sp,32
    80002242:	8082                	ret

0000000080002244 <growproc>:
{
    80002244:	1101                	addi	sp,sp,-32
    80002246:	ec06                	sd	ra,24(sp)
    80002248:	e822                	sd	s0,16(sp)
    8000224a:	e426                	sd	s1,8(sp)
    8000224c:	e04a                	sd	s2,0(sp)
    8000224e:	1000                	addi	s0,sp,32
    80002250:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002252:	00000097          	auipc	ra,0x0
    80002256:	c0a080e7          	jalr	-1014(ra) # 80001e5c <myproc>
    8000225a:	892a                	mv	s2,a0
  sz = p->sz;
    8000225c:	752c                	ld	a1,104(a0)
    8000225e:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80002262:	00904f63          	bgtz	s1,80002280 <growproc+0x3c>
  else if (n < 0)
    80002266:	0204cc63          	bltz	s1,8000229e <growproc+0x5a>
  p->sz = sz;
    8000226a:	1602                	slli	a2,a2,0x20
    8000226c:	9201                	srli	a2,a2,0x20
    8000226e:	06c93423          	sd	a2,104(s2)
  return 0;
    80002272:	4501                	li	a0,0
}
    80002274:	60e2                	ld	ra,24(sp)
    80002276:	6442                	ld	s0,16(sp)
    80002278:	64a2                	ld	s1,8(sp)
    8000227a:	6902                	ld	s2,0(sp)
    8000227c:	6105                	addi	sp,sp,32
    8000227e:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80002280:	9e25                	addw	a2,a2,s1
    80002282:	1602                	slli	a2,a2,0x20
    80002284:	9201                	srli	a2,a2,0x20
    80002286:	1582                	slli	a1,a1,0x20
    80002288:	9181                	srli	a1,a1,0x20
    8000228a:	7928                	ld	a0,112(a0)
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	1c8080e7          	jalr	456(ra) # 80001454 <uvmalloc>
    80002294:	0005061b          	sext.w	a2,a0
    80002298:	fa69                	bnez	a2,8000226a <growproc+0x26>
      return -1;
    8000229a:	557d                	li	a0,-1
    8000229c:	bfe1                	j	80002274 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000229e:	9e25                	addw	a2,a2,s1
    800022a0:	1602                	slli	a2,a2,0x20
    800022a2:	9201                	srli	a2,a2,0x20
    800022a4:	1582                	slli	a1,a1,0x20
    800022a6:	9181                	srli	a1,a1,0x20
    800022a8:	7928                	ld	a0,112(a0)
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	162080e7          	jalr	354(ra) # 8000140c <uvmdealloc>
    800022b2:	0005061b          	sext.w	a2,a0
    800022b6:	bf55                	j	8000226a <growproc+0x26>

00000000800022b8 <increase_num_process>:
void increase_num_process(struct cpu* c){
    800022b8:	1101                	addi	sp,sp,-32
    800022ba:	ec06                	sd	ra,24(sp)
    800022bc:	e822                	sd	s0,16(sp)
    800022be:	e426                	sd	s1,8(sp)
    800022c0:	e04a                	sd	s2,0(sp)
    800022c2:	1000                	addi	s0,sp,32
    800022c4:	84aa                	mv	s1,a0
    while(cas(&c->proc_counter, c->proc_counter, c->proc_counter + 1) != 0);
    800022c6:	0a850913          	addi	s2,a0,168
    800022ca:	74cc                	ld	a1,168(s1)
    800022cc:	74d0                	ld	a2,168(s1)
    800022ce:	2605                	addiw	a2,a2,1
    800022d0:	2581                	sext.w	a1,a1
    800022d2:	854a                	mv	a0,s2
    800022d4:	00005097          	auipc	ra,0x5
    800022d8:	822080e7          	jalr	-2014(ra) # 80006af6 <cas>
    800022dc:	f57d                	bnez	a0,800022ca <increase_num_process+0x12>
}
    800022de:	60e2                	ld	ra,24(sp)
    800022e0:	6442                	ld	s0,16(sp)
    800022e2:	64a2                	ld	s1,8(sp)
    800022e4:	6902                	ld	s2,0(sp)
    800022e6:	6105                	addi	sp,sp,32
    800022e8:	8082                	ret

00000000800022ea <update_cpu>:
int update_cpu(int cpu_id){
    800022ea:	1101                	addi	sp,sp,-32
    800022ec:	ec06                	sd	ra,24(sp)
    800022ee:	e822                	sd	s0,16(sp)
    800022f0:	e426                	sd	s1,8(sp)
    800022f2:	e04a                	sd	s2,0(sp)
    800022f4:	1000                	addi	s0,sp,32
    800022f6:	84aa                	mv	s1,a0
    if (load_balancer)
    800022f8:	00006797          	auipc	a5,0x6
    800022fc:	5607a783          	lw	a5,1376(a5) # 80008858 <load_balancer>
    80002300:	eb81                	bnez	a5,80002310 <update_cpu+0x26>
}
    80002302:	8526                	mv	a0,s1
    80002304:	60e2                	ld	ra,24(sp)
    80002306:	6442                	ld	s0,16(sp)
    80002308:	64a2                	ld	s1,8(sp)
    8000230a:	6902                	ld	s2,0(sp)
    8000230c:	6105                	addi	sp,sp,32
    8000230e:	8082                	ret
        new_cpu = least_used_cpu();
    80002310:	00000097          	auipc	ra,0x0
    80002314:	928080e7          	jalr	-1752(ra) # 80001c38 <least_used_cpu>
    80002318:	892a                	mv	s2,a0
    if (new_cpu != cpu_id)
    8000231a:	02a48163          	beq	s1,a0,8000233c <update_cpu+0x52>
        increase_num_process(&cpus[new_cpu]);
    8000231e:	0b000793          	li	a5,176
    80002322:	02f507b3          	mul	a5,a0,a5
    80002326:	0000f517          	auipc	a0,0xf
    8000232a:	f7a50513          	addi	a0,a0,-134 # 800112a0 <cpus>
    8000232e:	953e                	add	a0,a0,a5
    80002330:	00000097          	auipc	ra,0x0
    80002334:	f88080e7          	jalr	-120(ra) # 800022b8 <increase_num_process>
        new_cpu = least_used_cpu();
    80002338:	84ca                	mv	s1,s2
    8000233a:	b7e1                	j	80002302 <update_cpu+0x18>
    8000233c:	84aa                	mv	s1,a0
    8000233e:	b7d1                	j	80002302 <update_cpu+0x18>

0000000080002340 <fork>:
{
    80002340:	7179                	addi	sp,sp,-48
    80002342:	f406                	sd	ra,40(sp)
    80002344:	f022                	sd	s0,32(sp)
    80002346:	ec26                	sd	s1,24(sp)
    80002348:	e84a                	sd	s2,16(sp)
    8000234a:	e44e                	sd	s3,8(sp)
    8000234c:	e052                	sd	s4,0(sp)
    8000234e:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80002350:	00000097          	auipc	ra,0x0
    80002354:	b0c080e7          	jalr	-1268(ra) # 80001e5c <myproc>
    80002358:	89aa                	mv	s3,a0
    if((np = allocproc()) == 0){
    8000235a:	00000097          	auipc	ra,0x0
    8000235e:	d3a080e7          	jalr	-710(ra) # 80002094 <allocproc>
    80002362:	18050463          	beqz	a0,800024ea <fork+0x1aa>
    80002366:	892a                	mv	s2,a0
    if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002368:	0689b603          	ld	a2,104(s3)
    8000236c:	792c                	ld	a1,112(a0)
    8000236e:	0709b503          	ld	a0,112(s3)
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	22e080e7          	jalr	558(ra) # 800015a0 <uvmcopy>
    8000237a:	04054663          	bltz	a0,800023c6 <fork+0x86>
    np->sz = p->sz;
    8000237e:	0689b783          	ld	a5,104(s3)
    80002382:	06f93423          	sd	a5,104(s2)
    *(np->trapframe) = *(p->trapframe);
    80002386:	0789b683          	ld	a3,120(s3)
    8000238a:	87b6                	mv	a5,a3
    8000238c:	07893703          	ld	a4,120(s2)
    80002390:	12068693          	addi	a3,a3,288
    80002394:	0007b803          	ld	a6,0(a5)
    80002398:	6788                	ld	a0,8(a5)
    8000239a:	6b8c                	ld	a1,16(a5)
    8000239c:	6f90                	ld	a2,24(a5)
    8000239e:	01073023          	sd	a6,0(a4)
    800023a2:	e708                	sd	a0,8(a4)
    800023a4:	eb0c                	sd	a1,16(a4)
    800023a6:	ef10                	sd	a2,24(a4)
    800023a8:	02078793          	addi	a5,a5,32
    800023ac:	02070713          	addi	a4,a4,32
    800023b0:	fed792e3          	bne	a5,a3,80002394 <fork+0x54>
    np->trapframe->a0 = 0;
    800023b4:	07893783          	ld	a5,120(s2)
    800023b8:	0607b823          	sd	zero,112(a5)
    800023bc:	0f000493          	li	s1,240
    for(i = 0; i < NOFILE; i++)
    800023c0:	17000a13          	li	s4,368
    800023c4:	a03d                	j	800023f2 <fork+0xb2>
        freeproc(np);
    800023c6:	854a                	mv	a0,s2
    800023c8:	00000097          	auipc	ra,0x0
    800023cc:	c40080e7          	jalr	-960(ra) # 80002008 <freeproc>
        release(&np->lock);
    800023d0:	854a                	mv	a0,s2
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	8e6080e7          	jalr	-1818(ra) # 80000cb8 <release>
        return -1;
    800023da:	5a7d                	li	s4,-1
    800023dc:	a0f9                	j	800024aa <fork+0x16a>
            np->ofile[i] = filedup(p->ofile[i]);
    800023de:	00003097          	auipc	ra,0x3
    800023e2:	9d6080e7          	jalr	-1578(ra) # 80004db4 <filedup>
    800023e6:	009907b3          	add	a5,s2,s1
    800023ea:	e388                	sd	a0,0(a5)
    for(i = 0; i < NOFILE; i++)
    800023ec:	04a1                	addi	s1,s1,8
    800023ee:	01448763          	beq	s1,s4,800023fc <fork+0xbc>
        if(p->ofile[i])
    800023f2:	009987b3          	add	a5,s3,s1
    800023f6:	6388                	ld	a0,0(a5)
    800023f8:	f17d                	bnez	a0,800023de <fork+0x9e>
    800023fa:	bfcd                	j	800023ec <fork+0xac>
    np->cwd = idup(p->cwd);
    800023fc:	1709b503          	ld	a0,368(s3)
    80002400:	00002097          	auipc	ra,0x2
    80002404:	b2a080e7          	jalr	-1238(ra) # 80003f2a <idup>
    80002408:	16a93823          	sd	a0,368(s2)
    safestrcpy(np->name, p->name, sizeof(p->name));
    8000240c:	4641                	li	a2,16
    8000240e:	17898593          	addi	a1,s3,376
    80002412:	17890513          	addi	a0,s2,376
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	a4e080e7          	jalr	-1458(ra) # 80000e64 <safestrcpy>
    pid = np->pid;
    8000241e:	03092a03          	lw	s4,48(s2)
    release(&np->lock);
    80002422:	854a                	mv	a0,s2
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	894080e7          	jalr	-1900(ra) # 80000cb8 <release>
    acquire(&wait_lock);
    8000242c:	0000f517          	auipc	a0,0xf
    80002430:	45450513          	addi	a0,a0,1108 # 80011880 <wait_lock>
    80002434:	ffffe097          	auipc	ra,0xffffe
    80002438:	7b8080e7          	jalr	1976(ra) # 80000bec <acquire>
    np->parent = p;
    8000243c:	05393c23          	sd	s3,88(s2)
    np->cpu = p->cpu;;
    80002440:	0349a783          	lw	a5,52(s3)
    80002444:	2781                	sext.w	a5,a5
    80002446:	02f92a23          	sw	a5,52(s2)
    if (load_balancer){
    8000244a:	00006797          	auipc	a5,0x6
    8000244e:	40e7a783          	lw	a5,1038(a5) # 80008858 <load_balancer>
    80002452:	e7ad                	bnez	a5,800024bc <fork+0x17c>
    release(&wait_lock);
    80002454:	0000f497          	auipc	s1,0xf
    80002458:	e4c48493          	addi	s1,s1,-436 # 800112a0 <cpus>
    8000245c:	0000f517          	auipc	a0,0xf
    80002460:	42450513          	addi	a0,a0,1060 # 80011880 <wait_lock>
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	854080e7          	jalr	-1964(ra) # 80000cb8 <release>
    acquire(&np->lock);
    8000246c:	854a                	mv	a0,s2
    8000246e:	ffffe097          	auipc	ra,0xffffe
    80002472:	77e080e7          	jalr	1918(ra) # 80000bec <acquire>
    np->state = RUNNABLE;
    80002476:	478d                	li	a5,3
    80002478:	00f92c23          	sw	a5,24(s2)
    struct cpu *c = &cpus[np->cpu];
    8000247c:	03492503          	lw	a0,52(s2)
    80002480:	2501                	sext.w	a0,a0
    add_proc(&c->runnable_head, np, &c->head_lock);
    80002482:	0b000793          	li	a5,176
    80002486:	02f50533          	mul	a0,a0,a5
    8000248a:	09050613          	addi	a2,a0,144
    8000248e:	08850513          	addi	a0,a0,136
    80002492:	9626                	add	a2,a2,s1
    80002494:	85ca                	mv	a1,s2
    80002496:	9526                	add	a0,a0,s1
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	65a080e7          	jalr	1626(ra) # 80001af2 <add_proc>
    release(&np->lock);
    800024a0:	854a                	mv	a0,s2
    800024a2:	fffff097          	auipc	ra,0xfffff
    800024a6:	816080e7          	jalr	-2026(ra) # 80000cb8 <release>
}
    800024aa:	8552                	mv	a0,s4
    800024ac:	70a2                	ld	ra,40(sp)
    800024ae:	7402                	ld	s0,32(sp)
    800024b0:	64e2                	ld	s1,24(sp)
    800024b2:	6942                	ld	s2,16(sp)
    800024b4:	69a2                	ld	s3,8(sp)
    800024b6:	6a02                	ld	s4,0(sp)
    800024b8:	6145                	addi	sp,sp,48
    800024ba:	8082                	ret
        np->cpu = least_used_cpu();
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	77c080e7          	jalr	1916(ra) # 80001c38 <least_used_cpu>
    800024c4:	02a92a23          	sw	a0,52(s2)
        increase_num_process(&cpus[np->cpu]);
    800024c8:	03492783          	lw	a5,52(s2)
    800024cc:	2781                	sext.w	a5,a5
    800024ce:	0b000513          	li	a0,176
    800024d2:	02a787b3          	mul	a5,a5,a0
    800024d6:	0000f517          	auipc	a0,0xf
    800024da:	dca50513          	addi	a0,a0,-566 # 800112a0 <cpus>
    800024de:	953e                	add	a0,a0,a5
    800024e0:	00000097          	auipc	ra,0x0
    800024e4:	dd8080e7          	jalr	-552(ra) # 800022b8 <increase_num_process>
    800024e8:	b7b5                	j	80002454 <fork+0x114>
        return -1;
    800024ea:	5a7d                	li	s4,-1
    800024ec:	bf7d                	j	800024aa <fork+0x16a>

00000000800024ee <scheduler>:
{
    800024ee:	711d                	addi	sp,sp,-96
    800024f0:	ec86                	sd	ra,88(sp)
    800024f2:	e8a2                	sd	s0,80(sp)
    800024f4:	e4a6                	sd	s1,72(sp)
    800024f6:	e0ca                	sd	s2,64(sp)
    800024f8:	fc4e                	sd	s3,56(sp)
    800024fa:	f852                	sd	s4,48(sp)
    800024fc:	f456                	sd	s5,40(sp)
    800024fe:	f05a                	sd	s6,32(sp)
    80002500:	ec5e                	sd	s7,24(sp)
    80002502:	e862                	sd	s8,16(sp)
    80002504:	e466                	sd	s9,8(sp)
    80002506:	e06a                	sd	s10,0(sp)
    80002508:	1080                	addi	s0,sp,96
    8000250a:	8712                	mv	a4,tp
  int id = r_tp();
    8000250c:	2701                	sext.w	a4,a4
  c->proc = 0;
    8000250e:	0000fb97          	auipc	s7,0xf
    80002512:	d92b8b93          	addi	s7,s7,-622 # 800112a0 <cpus>
    80002516:	0b000793          	li	a5,176
    8000251a:	02f707b3          	mul	a5,a4,a5
    8000251e:	00fb86b3          	add	a3,s7,a5
    80002522:	0006b423          	sd	zero,8(a3)
    int next_running = remove_first(&c->runnable_head, &c->head_lock);
    80002526:	08878993          	addi	s3,a5,136
    8000252a:	99de                	add	s3,s3,s7
    8000252c:	09078913          	addi	s2,a5,144
    80002530:	995e                	add	s2,s2,s7
      swtch(&c->context, &p->context);
    80002532:	07c1                	addi	a5,a5,16
    80002534:	9bbe                	add	s7,s7,a5
    if (next_running != -1)
    80002536:	5a7d                	li	s4,-1
    80002538:	18800c93          	li	s9,392
      p = &proc[next_running];
    8000253c:	0000fb17          	auipc	s6,0xf
    80002540:	35cb0b13          	addi	s6,s6,860 # 80011898 <proc>
      p->state = RUNNING;
    80002544:	4c11                	li	s8,4
      c->proc = p;
    80002546:	8ab6                	mv	s5,a3
    80002548:	a82d                	j	80002582 <scheduler+0x94>
      p = &proc[next_running];
    8000254a:	039504b3          	mul	s1,a0,s9
    8000254e:	01648d33          	add	s10,s1,s6
      acquire(&p->lock);
    80002552:	856a                	mv	a0,s10
    80002554:	ffffe097          	auipc	ra,0xffffe
    80002558:	698080e7          	jalr	1688(ra) # 80000bec <acquire>
      p->state = RUNNING;
    8000255c:	018d2c23          	sw	s8,24(s10)
      c->proc = p;
    80002560:	01aab423          	sd	s10,8(s5)
      swtch(&c->context, &p->context);
    80002564:	08048593          	addi	a1,s1,128
    80002568:	95da                	add	a1,a1,s6
    8000256a:	855e                	mv	a0,s7
    8000256c:	00001097          	auipc	ra,0x1
    80002570:	94e080e7          	jalr	-1714(ra) # 80002eba <swtch>
      c->proc = 0;
    80002574:	000ab423          	sd	zero,8(s5)
      release(&p->lock);
    80002578:	856a                	mv	a0,s10
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	73e080e7          	jalr	1854(ra) # 80000cb8 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002582:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002586:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000258a:	10079073          	csrw	sstatus,a5
    int next_running = remove_first(&c->runnable_head, &c->head_lock);
    8000258e:	85ca                	mv	a1,s2
    80002590:	854e                	mv	a0,s3
    80002592:	fffff097          	auipc	ra,0xfffff
    80002596:	2de080e7          	jalr	734(ra) # 80001870 <remove_first>
    if (next_running != -1)
    8000259a:	ff4504e3          	beq	a0,s4,80002582 <scheduler+0x94>
    8000259e:	b775                	j	8000254a <scheduler+0x5c>

00000000800025a0 <sched>:
{
    800025a0:	7179                	addi	sp,sp,-48
    800025a2:	f406                	sd	ra,40(sp)
    800025a4:	f022                	sd	s0,32(sp)
    800025a6:	ec26                	sd	s1,24(sp)
    800025a8:	e84a                	sd	s2,16(sp)
    800025aa:	e44e                	sd	s3,8(sp)
    800025ac:	e052                	sd	s4,0(sp)
    800025ae:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800025b0:	00000097          	auipc	ra,0x0
    800025b4:	8ac080e7          	jalr	-1876(ra) # 80001e5c <myproc>
    800025b8:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800025ba:	ffffe097          	auipc	ra,0xffffe
    800025be:	5b0080e7          	jalr	1456(ra) # 80000b6a <holding>
    800025c2:	c149                	beqz	a0,80002644 <sched+0xa4>
  asm volatile("mv %0, tp" : "=r" (x) );
    800025c4:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800025c6:	2781                	sext.w	a5,a5
    800025c8:	0b000713          	li	a4,176
    800025cc:	02e787b3          	mul	a5,a5,a4
    800025d0:	0000f717          	auipc	a4,0xf
    800025d4:	cd070713          	addi	a4,a4,-816 # 800112a0 <cpus>
    800025d8:	97ba                	add	a5,a5,a4
    800025da:	0807a703          	lw	a4,128(a5)
    800025de:	4785                	li	a5,1
    800025e0:	06f71a63          	bne	a4,a5,80002654 <sched+0xb4>
  if (p->state == RUNNING)
    800025e4:	4c98                	lw	a4,24(s1)
    800025e6:	4791                	li	a5,4
    800025e8:	06f70e63          	beq	a4,a5,80002664 <sched+0xc4>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025ec:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800025f0:	8b89                	andi	a5,a5,2
  if (intr_get())
    800025f2:	e3c9                	bnez	a5,80002674 <sched+0xd4>
  asm volatile("mv %0, tp" : "=r" (x) );
    800025f4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800025f6:	0000f917          	auipc	s2,0xf
    800025fa:	caa90913          	addi	s2,s2,-854 # 800112a0 <cpus>
    800025fe:	2781                	sext.w	a5,a5
    80002600:	0b000993          	li	s3,176
    80002604:	033787b3          	mul	a5,a5,s3
    80002608:	97ca                	add	a5,a5,s2
    8000260a:	0847aa03          	lw	s4,132(a5)
    8000260e:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    80002610:	2581                	sext.w	a1,a1
    80002612:	033585b3          	mul	a1,a1,s3
    80002616:	05c1                	addi	a1,a1,16
    80002618:	95ca                	add	a1,a1,s2
    8000261a:	08048513          	addi	a0,s1,128
    8000261e:	00001097          	auipc	ra,0x1
    80002622:	89c080e7          	jalr	-1892(ra) # 80002eba <swtch>
    80002626:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002628:	2781                	sext.w	a5,a5
    8000262a:	033787b3          	mul	a5,a5,s3
    8000262e:	993e                	add	s2,s2,a5
    80002630:	09492223          	sw	s4,132(s2)
}
    80002634:	70a2                	ld	ra,40(sp)
    80002636:	7402                	ld	s0,32(sp)
    80002638:	64e2                	ld	s1,24(sp)
    8000263a:	6942                	ld	s2,16(sp)
    8000263c:	69a2                	ld	s3,8(sp)
    8000263e:	6a02                	ld	s4,0(sp)
    80002640:	6145                	addi	sp,sp,48
    80002642:	8082                	ret
    panic("sched p->lock");
    80002644:	00006517          	auipc	a0,0x6
    80002648:	c1450513          	addi	a0,a0,-1004 # 80008258 <digits+0x218>
    8000264c:	ffffe097          	auipc	ra,0xffffe
    80002650:	ef2080e7          	jalr	-270(ra) # 8000053e <panic>
    panic("sched locks");
    80002654:	00006517          	auipc	a0,0x6
    80002658:	c1450513          	addi	a0,a0,-1004 # 80008268 <digits+0x228>
    8000265c:	ffffe097          	auipc	ra,0xffffe
    80002660:	ee2080e7          	jalr	-286(ra) # 8000053e <panic>
    panic("sched running");
    80002664:	00006517          	auipc	a0,0x6
    80002668:	c1450513          	addi	a0,a0,-1004 # 80008278 <digits+0x238>
    8000266c:	ffffe097          	auipc	ra,0xffffe
    80002670:	ed2080e7          	jalr	-302(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002674:	00006517          	auipc	a0,0x6
    80002678:	c1450513          	addi	a0,a0,-1004 # 80008288 <digits+0x248>
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	ec2080e7          	jalr	-318(ra) # 8000053e <panic>

0000000080002684 <yield>:
{
    80002684:	1101                	addi	sp,sp,-32
    80002686:	ec06                	sd	ra,24(sp)
    80002688:	e822                	sd	s0,16(sp)
    8000268a:	e426                	sd	s1,8(sp)
    8000268c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000268e:	fffff097          	auipc	ra,0xfffff
    80002692:	7ce080e7          	jalr	1998(ra) # 80001e5c <myproc>
    80002696:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	554080e7          	jalr	1364(ra) # 80000bec <acquire>
  p->state = RUNNABLE;
    800026a0:	478d                	li	a5,3
    800026a2:	cc9c                	sw	a5,24(s1)
  struct cpu *c = &cpus[p->cpu];
    800026a4:	58dc                	lw	a5,52(s1)
    800026a6:	2781                	sext.w	a5,a5
  add_proc(&c->runnable_head, p, &c->head_lock);
    800026a8:	0b000513          	li	a0,176
    800026ac:	02a787b3          	mul	a5,a5,a0
    800026b0:	0000f517          	auipc	a0,0xf
    800026b4:	bf050513          	addi	a0,a0,-1040 # 800112a0 <cpus>
    800026b8:	09078613          	addi	a2,a5,144
    800026bc:	08878793          	addi	a5,a5,136
    800026c0:	962a                	add	a2,a2,a0
    800026c2:	85a6                	mv	a1,s1
    800026c4:	953e                	add	a0,a0,a5
    800026c6:	fffff097          	auipc	ra,0xfffff
    800026ca:	42c080e7          	jalr	1068(ra) # 80001af2 <add_proc>
  sched();
    800026ce:	00000097          	auipc	ra,0x0
    800026d2:	ed2080e7          	jalr	-302(ra) # 800025a0 <sched>
  release(&p->lock);
    800026d6:	8526                	mv	a0,s1
    800026d8:	ffffe097          	auipc	ra,0xffffe
    800026dc:	5e0080e7          	jalr	1504(ra) # 80000cb8 <release>
}
    800026e0:	60e2                	ld	ra,24(sp)
    800026e2:	6442                	ld	s0,16(sp)
    800026e4:	64a2                	ld	s1,8(sp)
    800026e6:	6105                	addi	sp,sp,32
    800026e8:	8082                	ret

00000000800026ea <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800026ea:	7179                	addi	sp,sp,-48
    800026ec:	f406                	sd	ra,40(sp)
    800026ee:	f022                	sd	s0,32(sp)
    800026f0:	ec26                	sd	s1,24(sp)
    800026f2:	e84a                	sd	s2,16(sp)
    800026f4:	e44e                	sd	s3,8(sp)
    800026f6:	1800                	addi	s0,sp,48
    800026f8:	89aa                	mv	s3,a0
    800026fa:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800026fc:	fffff097          	auipc	ra,0xfffff
    80002700:	760080e7          	jalr	1888(ra) # 80001e5c <myproc>
    80002704:	84aa                	mv	s1,a0
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.
  acquire(&p->lock); // DOC: sleeplock1
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	4e6080e7          	jalr	1254(ra) # 80000bec <acquire>

  add_proc(&sleeping_head, p, &sleeping_lock);
    8000270e:	0000f617          	auipc	a2,0xf
    80002712:	14260613          	addi	a2,a2,322 # 80011850 <sleeping_lock>
    80002716:	85a6                	mv	a1,s1
    80002718:	00006517          	auipc	a0,0x6
    8000271c:	14850513          	addi	a0,a0,328 # 80008860 <sleeping_head>
    80002720:	fffff097          	auipc	ra,0xfffff
    80002724:	3d2080e7          	jalr	978(ra) # 80001af2 <add_proc>
  release(lk);
    80002728:	854a                	mv	a0,s2
    8000272a:	ffffe097          	auipc	ra,0xffffe
    8000272e:	58e080e7          	jalr	1422(ra) # 80000cb8 <release>
  p->chan = chan;
    80002732:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002736:	4789                	li	a5,2
    80002738:	cc9c                	sw	a5,24(s1)

  // Go to sleep.
  // in your dream

  sched();
    8000273a:	00000097          	auipc	ra,0x0
    8000273e:	e66080e7          	jalr	-410(ra) # 800025a0 <sched>

  // Tidy up.
  p->chan = 0;
    80002742:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002746:	8526                	mv	a0,s1
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	570080e7          	jalr	1392(ra) # 80000cb8 <release>
  acquire(lk);
    80002750:	854a                	mv	a0,s2
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	49a080e7          	jalr	1178(ra) # 80000bec <acquire>
}
    8000275a:	70a2                	ld	ra,40(sp)
    8000275c:	7402                	ld	s0,32(sp)
    8000275e:	64e2                	ld	s1,24(sp)
    80002760:	6942                	ld	s2,16(sp)
    80002762:	69a2                	ld	s3,8(sp)
    80002764:	6145                	addi	sp,sp,48
    80002766:	8082                	ret

0000000080002768 <wait>:
{
    80002768:	715d                	addi	sp,sp,-80
    8000276a:	e486                	sd	ra,72(sp)
    8000276c:	e0a2                	sd	s0,64(sp)
    8000276e:	fc26                	sd	s1,56(sp)
    80002770:	f84a                	sd	s2,48(sp)
    80002772:	f44e                	sd	s3,40(sp)
    80002774:	f052                	sd	s4,32(sp)
    80002776:	ec56                	sd	s5,24(sp)
    80002778:	e85a                	sd	s6,16(sp)
    8000277a:	e45e                	sd	s7,8(sp)
    8000277c:	e062                	sd	s8,0(sp)
    8000277e:	0880                	addi	s0,sp,80
    80002780:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002782:	fffff097          	auipc	ra,0xfffff
    80002786:	6da080e7          	jalr	1754(ra) # 80001e5c <myproc>
    8000278a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000278c:	0000f517          	auipc	a0,0xf
    80002790:	0f450513          	addi	a0,a0,244 # 80011880 <wait_lock>
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	458080e7          	jalr	1112(ra) # 80000bec <acquire>
    havekids = 0;
    8000279c:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    8000279e:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    800027a0:	00015997          	auipc	s3,0x15
    800027a4:	2f898993          	addi	s3,s3,760 # 80017a98 <tickslock>
        havekids = 1;
    800027a8:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    800027aa:	0000fc17          	auipc	s8,0xf
    800027ae:	0d6c0c13          	addi	s8,s8,214 # 80011880 <wait_lock>
    havekids = 0;
    800027b2:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    800027b4:	0000f497          	auipc	s1,0xf
    800027b8:	0e448493          	addi	s1,s1,228 # 80011898 <proc>
    800027bc:	a0bd                	j	8000282a <wait+0xc2>
          pid = np->pid;
    800027be:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800027c2:	000b0e63          	beqz	s6,800027de <wait+0x76>
    800027c6:	4691                	li	a3,4
    800027c8:	02c48613          	addi	a2,s1,44
    800027cc:	85da                	mv	a1,s6
    800027ce:	07093503          	ld	a0,112(s2)
    800027d2:	fffff097          	auipc	ra,0xfffff
    800027d6:	ed2080e7          	jalr	-302(ra) # 800016a4 <copyout>
    800027da:	02054563          	bltz	a0,80002804 <wait+0x9c>
          freeproc(np);
    800027de:	8526                	mv	a0,s1
    800027e0:	00000097          	auipc	ra,0x0
    800027e4:	828080e7          	jalr	-2008(ra) # 80002008 <freeproc>
          release(&np->lock);
    800027e8:	8526                	mv	a0,s1
    800027ea:	ffffe097          	auipc	ra,0xffffe
    800027ee:	4ce080e7          	jalr	1230(ra) # 80000cb8 <release>
          release(&wait_lock);
    800027f2:	0000f517          	auipc	a0,0xf
    800027f6:	08e50513          	addi	a0,a0,142 # 80011880 <wait_lock>
    800027fa:	ffffe097          	auipc	ra,0xffffe
    800027fe:	4be080e7          	jalr	1214(ra) # 80000cb8 <release>
          return pid;
    80002802:	a09d                	j	80002868 <wait+0x100>
            release(&np->lock);
    80002804:	8526                	mv	a0,s1
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	4b2080e7          	jalr	1202(ra) # 80000cb8 <release>
            release(&wait_lock);
    8000280e:	0000f517          	auipc	a0,0xf
    80002812:	07250513          	addi	a0,a0,114 # 80011880 <wait_lock>
    80002816:	ffffe097          	auipc	ra,0xffffe
    8000281a:	4a2080e7          	jalr	1186(ra) # 80000cb8 <release>
            return -1;
    8000281e:	59fd                	li	s3,-1
    80002820:	a0a1                	j	80002868 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    80002822:	18848493          	addi	s1,s1,392
    80002826:	03348463          	beq	s1,s3,8000284e <wait+0xe6>
      if (np->parent == p)
    8000282a:	6cbc                	ld	a5,88(s1)
    8000282c:	ff279be3          	bne	a5,s2,80002822 <wait+0xba>
        acquire(&np->lock);
    80002830:	8526                	mv	a0,s1
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	3ba080e7          	jalr	954(ra) # 80000bec <acquire>
        if (np->state == ZOMBIE)
    8000283a:	4c9c                	lw	a5,24(s1)
    8000283c:	f94781e3          	beq	a5,s4,800027be <wait+0x56>
        release(&np->lock);
    80002840:	8526                	mv	a0,s1
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	476080e7          	jalr	1142(ra) # 80000cb8 <release>
        havekids = 1;
    8000284a:	8756                	mv	a4,s5
    8000284c:	bfd9                	j	80002822 <wait+0xba>
    if (!havekids || p->killed)
    8000284e:	c701                	beqz	a4,80002856 <wait+0xee>
    80002850:	02892783          	lw	a5,40(s2)
    80002854:	c79d                	beqz	a5,80002882 <wait+0x11a>
      release(&wait_lock);
    80002856:	0000f517          	auipc	a0,0xf
    8000285a:	02a50513          	addi	a0,a0,42 # 80011880 <wait_lock>
    8000285e:	ffffe097          	auipc	ra,0xffffe
    80002862:	45a080e7          	jalr	1114(ra) # 80000cb8 <release>
      return -1;
    80002866:	59fd                	li	s3,-1
}
    80002868:	854e                	mv	a0,s3
    8000286a:	60a6                	ld	ra,72(sp)
    8000286c:	6406                	ld	s0,64(sp)
    8000286e:	74e2                	ld	s1,56(sp)
    80002870:	7942                	ld	s2,48(sp)
    80002872:	79a2                	ld	s3,40(sp)
    80002874:	7a02                	ld	s4,32(sp)
    80002876:	6ae2                	ld	s5,24(sp)
    80002878:	6b42                	ld	s6,16(sp)
    8000287a:	6ba2                	ld	s7,8(sp)
    8000287c:	6c02                	ld	s8,0(sp)
    8000287e:	6161                	addi	sp,sp,80
    80002880:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002882:	85e2                	mv	a1,s8
    80002884:	854a                	mv	a0,s2
    80002886:	00000097          	auipc	ra,0x0
    8000288a:	e64080e7          	jalr	-412(ra) # 800026ea <sleep>
    havekids = 0;
    8000288e:	b715                	j	800027b2 <wait+0x4a>

0000000080002890 <wakeup_help>:

void wakeup_help(struct proc *p, void *chan)
{
  if (p->state == SLEEPING && p->chan == chan)
    80002890:	4d18                	lw	a4,24(a0)
    80002892:	4789                	li	a5,2
    80002894:	00f70363          	beq	a4,a5,8000289a <wakeup_help+0xa>
    80002898:	8082                	ret
{
    8000289a:	7179                	addi	sp,sp,-48
    8000289c:	f406                	sd	ra,40(sp)
    8000289e:	f022                	sd	s0,32(sp)
    800028a0:	ec26                	sd	s1,24(sp)
    800028a2:	e84a                	sd	s2,16(sp)
    800028a4:	e44e                	sd	s3,8(sp)
    800028a6:	1800                	addi	s0,sp,48
    800028a8:	84aa                	mv	s1,a0
  if (p->state == SLEEPING && p->chan == chan)
    800028aa:	711c                	ld	a5,32(a0)
    800028ac:	00b78963          	beq	a5,a1,800028be <wakeup_help+0x2e>
      } while (cas(&c->proc_counter, count, count + 1) != 0);
    }
    int cpu_num = p->cpu;
    add_proc(&cpus[cpu_num].runnable_head, p, &cpus[cpu_num].head_lock);
  }
}
    800028b0:	70a2                	ld	ra,40(sp)
    800028b2:	7402                	ld	s0,32(sp)
    800028b4:	64e2                	ld	s1,24(sp)
    800028b6:	6942                	ld	s2,16(sp)
    800028b8:	69a2                	ld	s3,8(sp)
    800028ba:	6145                	addi	sp,sp,48
    800028bc:	8082                	ret
    remove_proc(&sleeping_head, p, &sleeping_lock);
    800028be:	0000f617          	auipc	a2,0xf
    800028c2:	f9260613          	addi	a2,a2,-110 # 80011850 <sleeping_lock>
    800028c6:	85aa                	mv	a1,a0
    800028c8:	00006517          	auipc	a0,0x6
    800028cc:	f9850513          	addi	a0,a0,-104 # 80008860 <sleeping_head>
    800028d0:	fffff097          	auipc	ra,0xfffff
    800028d4:	0de080e7          	jalr	222(ra) # 800019ae <remove_proc>
    p->state = RUNNABLE;
    800028d8:	478d                	li	a5,3
    800028da:	cc9c                	sw	a5,24(s1)
    if (load_balancer)
    800028dc:	00006797          	auipc	a5,0x6
    800028e0:	f7c7a783          	lw	a5,-132(a5) # 80008858 <load_balancer>
    800028e4:	e79d                	bnez	a5,80002912 <wakeup_help+0x82>
    int cpu_num = p->cpu;
    800028e6:	58dc                	lw	a5,52(s1)
    800028e8:	2781                	sext.w	a5,a5
    add_proc(&cpus[cpu_num].runnable_head, p, &cpus[cpu_num].head_lock);
    800028ea:	0b000513          	li	a0,176
    800028ee:	02a787b3          	mul	a5,a5,a0
    800028f2:	0000f517          	auipc	a0,0xf
    800028f6:	9ae50513          	addi	a0,a0,-1618 # 800112a0 <cpus>
    800028fa:	09078613          	addi	a2,a5,144
    800028fe:	08878793          	addi	a5,a5,136
    80002902:	962a                	add	a2,a2,a0
    80002904:	85a6                	mv	a1,s1
    80002906:	953e                	add	a0,a0,a5
    80002908:	fffff097          	auipc	ra,0xfffff
    8000290c:	1ea080e7          	jalr	490(ra) # 80001af2 <add_proc>
}
    80002910:	b745                	j	800028b0 <wakeup_help+0x20>
      p->cpu = least_used_cpu();
    80002912:	fffff097          	auipc	ra,0xfffff
    80002916:	326080e7          	jalr	806(ra) # 80001c38 <least_used_cpu>
    8000291a:	d8c8                	sw	a0,52(s1)
      struct cpu *c = &cpus[p->cpu];
    8000291c:	0344a983          	lw	s3,52(s1)
    80002920:	2981                	sext.w	s3,s3
      } while (cas(&c->proc_counter, count, count + 1) != 0);
    80002922:	0b000913          	li	s2,176
    80002926:	03298933          	mul	s2,s3,s2
    8000292a:	0000f797          	auipc	a5,0xf
    8000292e:	a1e78793          	addi	a5,a5,-1506 # 80011348 <cpus+0xa8>
    80002932:	993e                	add	s2,s2,a5
        count = c->proc_counter;
    80002934:	0b000793          	li	a5,176
    80002938:	02f987b3          	mul	a5,s3,a5
    8000293c:	0000f997          	auipc	s3,0xf
    80002940:	96498993          	addi	s3,s3,-1692 # 800112a0 <cpus>
    80002944:	99be                	add	s3,s3,a5
    80002946:	0a89b583          	ld	a1,168(s3)
      } while (cas(&c->proc_counter, count, count + 1) != 0);
    8000294a:	0015861b          	addiw	a2,a1,1
    8000294e:	2581                	sext.w	a1,a1
    80002950:	854a                	mv	a0,s2
    80002952:	00004097          	auipc	ra,0x4
    80002956:	1a4080e7          	jalr	420(ra) # 80006af6 <cas>
    8000295a:	f575                	bnez	a0,80002946 <wakeup_help+0xb6>
    8000295c:	b769                	j	800028e6 <wakeup_help+0x56>

000000008000295e <trigger_wakeup>:
// }


void trigger_wakeup(void * chan, struct proc* p){
    struct cpu *c;
    if (p->state == SLEEPING && p->chan == chan) {
    8000295e:	4d98                	lw	a4,24(a1)
    80002960:	4789                	li	a5,2
    80002962:	00f70363          	beq	a4,a5,80002968 <trigger_wakeup+0xa>
    80002966:	8082                	ret
void trigger_wakeup(void * chan, struct proc* p){
    80002968:	1101                	addi	sp,sp,-32
    8000296a:	ec06                	sd	ra,24(sp)
    8000296c:	e822                	sd	s0,16(sp)
    8000296e:	e426                	sd	s1,8(sp)
    80002970:	1000                	addi	s0,sp,32
    80002972:	84ae                	mv	s1,a1
    if (p->state == SLEEPING && p->chan == chan) {
    80002974:	719c                	ld	a5,32(a1)
    80002976:	00a78763          	beq	a5,a0,80002984 <trigger_wakeup+0x26>
            p->cpu = update_cpu(p->cpu);
            c = &cpus[p->cpu];
            add_proc(&c->runnable_head, p, &c->head_lock);
        }
    }
}
    8000297a:	60e2                	ld	ra,24(sp)
    8000297c:	6442                	ld	s0,16(sp)
    8000297e:	64a2                	ld	s1,8(sp)
    80002980:	6105                	addi	sp,sp,32
    80002982:	8082                	ret
        if(remove_proc(&sleeping_head, p, &sleeping_lock)){
    80002984:	0000f617          	auipc	a2,0xf
    80002988:	ecc60613          	addi	a2,a2,-308 # 80011850 <sleeping_lock>
    8000298c:	00006517          	auipc	a0,0x6
    80002990:	ed450513          	addi	a0,a0,-300 # 80008860 <sleeping_head>
    80002994:	fffff097          	auipc	ra,0xfffff
    80002998:	01a080e7          	jalr	26(ra) # 800019ae <remove_proc>
    8000299c:	dd79                	beqz	a0,8000297a <trigger_wakeup+0x1c>
            p->state = RUNNABLE;
    8000299e:	478d                	li	a5,3
    800029a0:	cc9c                	sw	a5,24(s1)
            p->cpu = update_cpu(p->cpu);
    800029a2:	58c8                	lw	a0,52(s1)
    800029a4:	2501                	sext.w	a0,a0
    800029a6:	00000097          	auipc	ra,0x0
    800029aa:	944080e7          	jalr	-1724(ra) # 800022ea <update_cpu>
    800029ae:	d8c8                	sw	a0,52(s1)
            c = &cpus[p->cpu];
    800029b0:	58dc                	lw	a5,52(s1)
    800029b2:	2781                	sext.w	a5,a5
            add_proc(&c->runnable_head, p, &c->head_lock);
    800029b4:	0b000513          	li	a0,176
    800029b8:	02a787b3          	mul	a5,a5,a0
    800029bc:	0000f517          	auipc	a0,0xf
    800029c0:	8e450513          	addi	a0,a0,-1820 # 800112a0 <cpus>
    800029c4:	09078613          	addi	a2,a5,144
    800029c8:	08878793          	addi	a5,a5,136
    800029cc:	962a                	add	a2,a2,a0
    800029ce:	85a6                	mv	a1,s1
    800029d0:	953e                	add	a0,a0,a5
    800029d2:	fffff097          	auipc	ra,0xfffff
    800029d6:	120080e7          	jalr	288(ra) # 80001af2 <add_proc>
}
    800029da:	b745                	j	8000297a <trigger_wakeup+0x1c>

00000000800029dc <wakeup>:

void
wakeup(void *chan)
{
    800029dc:	7139                	addi	sp,sp,-64
    800029de:	fc06                	sd	ra,56(sp)
    800029e0:	f822                	sd	s0,48(sp)
    800029e2:	f426                	sd	s1,40(sp)
    800029e4:	f04a                	sd	s2,32(sp)
    800029e6:	ec4e                	sd	s3,24(sp)
    800029e8:	e852                	sd	s4,16(sp)
    800029ea:	e456                	sd	s5,8(sp)
    800029ec:	e05a                	sd	s6,0(sp)
    800029ee:	0080                	addi	s0,sp,64
    800029f0:	89aa                	mv	s3,a0
    struct proc *p;
    acquire(&sleeping_lock);
    800029f2:	0000f517          	auipc	a0,0xf
    800029f6:	e5e50513          	addi	a0,a0,-418 # 80011850 <sleeping_lock>
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	1f2080e7          	jalr	498(ra) # 80000bec <acquire>
    if(sleeping_head == -1){
    80002a02:	00006917          	auipc	s2,0x6
    80002a06:	e5e92903          	lw	s2,-418(s2) # 80008860 <sleeping_head>
    80002a0a:	57fd                	li	a5,-1
    80002a0c:	0af90163          	beq	s2,a5,80002aae <wakeup+0xd2>
        release(&sleeping_lock);
        return;
    }
    p = &proc[sleeping_head];
    80002a10:	18800793          	li	a5,392
    80002a14:	02f90933          	mul	s2,s2,a5
    80002a18:	0000f797          	auipc	a5,0xf
    80002a1c:	e8078793          	addi	a5,a5,-384 # 80011898 <proc>
    80002a20:	993e                	add	s2,s2,a5
    acquire(&p->lock);
    80002a22:	854a                	mv	a0,s2
    80002a24:	ffffe097          	auipc	ra,0xffffe
    80002a28:	1c8080e7          	jalr	456(ra) # 80000bec <acquire>
    release(&sleeping_lock);
    80002a2c:	0000f517          	auipc	a0,0xf
    80002a30:	e2450513          	addi	a0,a0,-476 # 80011850 <sleeping_lock>
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	284080e7          	jalr	644(ra) # 80000cb8 <release>
    int next = p->next;
    80002a3c:	05092483          	lw	s1,80(s2)
    trigger_wakeup(chan, p);
    80002a40:	85ca                	mv	a1,s2
    80002a42:	854e                	mv	a0,s3
    80002a44:	00000097          	auipc	ra,0x0
    80002a48:	f1a080e7          	jalr	-230(ra) # 8000295e <trigger_wakeup>
    release(&p->lock);
    80002a4c:	854a                	mv	a0,s2
    80002a4e:	ffffe097          	auipc	ra,0xffffe
    80002a52:	26a080e7          	jalr	618(ra) # 80000cb8 <release>

    while(next != -1){
    80002a56:	57fd                	li	a5,-1
    80002a58:	04f48163          	beq	s1,a5,80002a9a <wakeup+0xbe>
        p = &proc[next];
    80002a5c:	18800b13          	li	s6,392
    80002a60:	0000fa97          	auipc	s5,0xf
    80002a64:	e38a8a93          	addi	s5,s5,-456 # 80011898 <proc>
    while(next != -1){
    80002a68:	5a7d                	li	s4,-1
        p = &proc[next];
    80002a6a:	036484b3          	mul	s1,s1,s6
    80002a6e:	01548933          	add	s2,s1,s5
        acquire(&p->lock);
    80002a72:	854a                	mv	a0,s2
    80002a74:	ffffe097          	auipc	ra,0xffffe
    80002a78:	178080e7          	jalr	376(ra) # 80000bec <acquire>
        next = p->next;
    80002a7c:	05092483          	lw	s1,80(s2)
        trigger_wakeup(chan, p);
    80002a80:	85ca                	mv	a1,s2
    80002a82:	854e                	mv	a0,s3
    80002a84:	00000097          	auipc	ra,0x0
    80002a88:	eda080e7          	jalr	-294(ra) # 8000295e <trigger_wakeup>
        release(&p->lock);
    80002a8c:	854a                	mv	a0,s2
    80002a8e:	ffffe097          	auipc	ra,0xffffe
    80002a92:	22a080e7          	jalr	554(ra) # 80000cb8 <release>
    while(next != -1){
    80002a96:	fd449ae3          	bne	s1,s4,80002a6a <wakeup+0x8e>
    }
}
    80002a9a:	70e2                	ld	ra,56(sp)
    80002a9c:	7442                	ld	s0,48(sp)
    80002a9e:	74a2                	ld	s1,40(sp)
    80002aa0:	7902                	ld	s2,32(sp)
    80002aa2:	69e2                	ld	s3,24(sp)
    80002aa4:	6a42                	ld	s4,16(sp)
    80002aa6:	6aa2                	ld	s5,8(sp)
    80002aa8:	6b02                	ld	s6,0(sp)
    80002aaa:	6121                	addi	sp,sp,64
    80002aac:	8082                	ret
        release(&sleeping_lock);
    80002aae:	0000f517          	auipc	a0,0xf
    80002ab2:	da250513          	addi	a0,a0,-606 # 80011850 <sleeping_lock>
    80002ab6:	ffffe097          	auipc	ra,0xffffe
    80002aba:	202080e7          	jalr	514(ra) # 80000cb8 <release>
        return;
    80002abe:	bff1                	j	80002a9a <wakeup+0xbe>

0000000080002ac0 <reparent>:
{
    80002ac0:	7179                	addi	sp,sp,-48
    80002ac2:	f406                	sd	ra,40(sp)
    80002ac4:	f022                	sd	s0,32(sp)
    80002ac6:	ec26                	sd	s1,24(sp)
    80002ac8:	e84a                	sd	s2,16(sp)
    80002aca:	e44e                	sd	s3,8(sp)
    80002acc:	e052                	sd	s4,0(sp)
    80002ace:	1800                	addi	s0,sp,48
    80002ad0:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002ad2:	0000f497          	auipc	s1,0xf
    80002ad6:	dc648493          	addi	s1,s1,-570 # 80011898 <proc>
      pp->parent = initproc;
    80002ada:	00006a17          	auipc	s4,0x6
    80002ade:	54ea0a13          	addi	s4,s4,1358 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002ae2:	00015997          	auipc	s3,0x15
    80002ae6:	fb698993          	addi	s3,s3,-74 # 80017a98 <tickslock>
    80002aea:	a029                	j	80002af4 <reparent+0x34>
    80002aec:	18848493          	addi	s1,s1,392
    80002af0:	01348d63          	beq	s1,s3,80002b0a <reparent+0x4a>
    if (pp->parent == p)
    80002af4:	6cbc                	ld	a5,88(s1)
    80002af6:	ff279be3          	bne	a5,s2,80002aec <reparent+0x2c>
      pp->parent = initproc;
    80002afa:	000a3503          	ld	a0,0(s4)
    80002afe:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    80002b00:	00000097          	auipc	ra,0x0
    80002b04:	edc080e7          	jalr	-292(ra) # 800029dc <wakeup>
    80002b08:	b7d5                	j	80002aec <reparent+0x2c>
}
    80002b0a:	70a2                	ld	ra,40(sp)
    80002b0c:	7402                	ld	s0,32(sp)
    80002b0e:	64e2                	ld	s1,24(sp)
    80002b10:	6942                	ld	s2,16(sp)
    80002b12:	69a2                	ld	s3,8(sp)
    80002b14:	6a02                	ld	s4,0(sp)
    80002b16:	6145                	addi	sp,sp,48
    80002b18:	8082                	ret

0000000080002b1a <exit>:
{
    80002b1a:	7179                	addi	sp,sp,-48
    80002b1c:	f406                	sd	ra,40(sp)
    80002b1e:	f022                	sd	s0,32(sp)
    80002b20:	ec26                	sd	s1,24(sp)
    80002b22:	e84a                	sd	s2,16(sp)
    80002b24:	e44e                	sd	s3,8(sp)
    80002b26:	e052                	sd	s4,0(sp)
    80002b28:	1800                	addi	s0,sp,48
    80002b2a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002b2c:	fffff097          	auipc	ra,0xfffff
    80002b30:	330080e7          	jalr	816(ra) # 80001e5c <myproc>
    80002b34:	89aa                	mv	s3,a0
  if (p == initproc)
    80002b36:	00006797          	auipc	a5,0x6
    80002b3a:	4f27b783          	ld	a5,1266(a5) # 80009028 <initproc>
    80002b3e:	0f050493          	addi	s1,a0,240
    80002b42:	17050913          	addi	s2,a0,368
    80002b46:	02a79363          	bne	a5,a0,80002b6c <exit+0x52>
    panic("init exiting");
    80002b4a:	00005517          	auipc	a0,0x5
    80002b4e:	75650513          	addi	a0,a0,1878 # 800082a0 <digits+0x260>
    80002b52:	ffffe097          	auipc	ra,0xffffe
    80002b56:	9ec080e7          	jalr	-1556(ra) # 8000053e <panic>
      fileclose(f);
    80002b5a:	00002097          	auipc	ra,0x2
    80002b5e:	2ac080e7          	jalr	684(ra) # 80004e06 <fileclose>
      p->ofile[fd] = 0;
    80002b62:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002b66:	04a1                	addi	s1,s1,8
    80002b68:	01248563          	beq	s1,s2,80002b72 <exit+0x58>
    if (p->ofile[fd])
    80002b6c:	6088                	ld	a0,0(s1)
    80002b6e:	f575                	bnez	a0,80002b5a <exit+0x40>
    80002b70:	bfdd                	j	80002b66 <exit+0x4c>
  begin_op();
    80002b72:	00002097          	auipc	ra,0x2
    80002b76:	dc8080e7          	jalr	-568(ra) # 8000493a <begin_op>
  iput(p->cwd);
    80002b7a:	1709b503          	ld	a0,368(s3)
    80002b7e:	00001097          	auipc	ra,0x1
    80002b82:	5a4080e7          	jalr	1444(ra) # 80004122 <iput>
  end_op();
    80002b86:	00002097          	auipc	ra,0x2
    80002b8a:	e34080e7          	jalr	-460(ra) # 800049ba <end_op>
  p->cwd = 0;
    80002b8e:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    80002b92:	0000f497          	auipc	s1,0xf
    80002b96:	cee48493          	addi	s1,s1,-786 # 80011880 <wait_lock>
    80002b9a:	8526                	mv	a0,s1
    80002b9c:	ffffe097          	auipc	ra,0xffffe
    80002ba0:	050080e7          	jalr	80(ra) # 80000bec <acquire>
  reparent(p);
    80002ba4:	854e                	mv	a0,s3
    80002ba6:	00000097          	auipc	ra,0x0
    80002baa:	f1a080e7          	jalr	-230(ra) # 80002ac0 <reparent>
  wakeup(p->parent);
    80002bae:	0589b503          	ld	a0,88(s3)
    80002bb2:	00000097          	auipc	ra,0x0
    80002bb6:	e2a080e7          	jalr	-470(ra) # 800029dc <wakeup>
  acquire(&p->lock);
    80002bba:	854e                	mv	a0,s3
    80002bbc:	ffffe097          	auipc	ra,0xffffe
    80002bc0:	030080e7          	jalr	48(ra) # 80000bec <acquire>
  p->xstate = status;
    80002bc4:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002bc8:	4795                	li	a5,5
    80002bca:	00f9ac23          	sw	a5,24(s3)
  add_proc(&zombie_head, p, &zombie_lock);
    80002bce:	0000f617          	auipc	a2,0xf
    80002bd2:	c5260613          	addi	a2,a2,-942 # 80011820 <zombie_lock>
    80002bd6:	85ce                	mv	a1,s3
    80002bd8:	00006517          	auipc	a0,0x6
    80002bdc:	c8c50513          	addi	a0,a0,-884 # 80008864 <zombie_head>
    80002be0:	fffff097          	auipc	ra,0xfffff
    80002be4:	f12080e7          	jalr	-238(ra) # 80001af2 <add_proc>
  release(&wait_lock);
    80002be8:	8526                	mv	a0,s1
    80002bea:	ffffe097          	auipc	ra,0xffffe
    80002bee:	0ce080e7          	jalr	206(ra) # 80000cb8 <release>
  sched();
    80002bf2:	00000097          	auipc	ra,0x0
    80002bf6:	9ae080e7          	jalr	-1618(ra) # 800025a0 <sched>
  panic("zombie exit");
    80002bfa:	00005517          	auipc	a0,0x5
    80002bfe:	6b650513          	addi	a0,a0,1718 # 800082b0 <digits+0x270>
    80002c02:	ffffe097          	auipc	ra,0xffffe
    80002c06:	93c080e7          	jalr	-1732(ra) # 8000053e <panic>

0000000080002c0a <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002c0a:	7179                	addi	sp,sp,-48
    80002c0c:	f406                	sd	ra,40(sp)
    80002c0e:	f022                	sd	s0,32(sp)
    80002c10:	ec26                	sd	s1,24(sp)
    80002c12:	e84a                	sd	s2,16(sp)
    80002c14:	e44e                	sd	s3,8(sp)
    80002c16:	1800                	addi	s0,sp,48
    80002c18:	892a                	mv	s2,a0
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002c1a:	0000f497          	auipc	s1,0xf
    80002c1e:	c7e48493          	addi	s1,s1,-898 # 80011898 <proc>
    80002c22:	00015997          	auipc	s3,0x15
    80002c26:	e7698993          	addi	s3,s3,-394 # 80017a98 <tickslock>
  {
    acquire(&p->lock);
    80002c2a:	8526                	mv	a0,s1
    80002c2c:	ffffe097          	auipc	ra,0xffffe
    80002c30:	fc0080e7          	jalr	-64(ra) # 80000bec <acquire>
    if (p->pid == pid)
    80002c34:	589c                	lw	a5,48(s1)
    80002c36:	01278d63          	beq	a5,s2,80002c50 <kill+0x46>
        add_proc(&c->runnable_head, p, &c->head_lock);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002c3a:	8526                	mv	a0,s1
    80002c3c:	ffffe097          	auipc	ra,0xffffe
    80002c40:	07c080e7          	jalr	124(ra) # 80000cb8 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002c44:	18848493          	addi	s1,s1,392
    80002c48:	ff3491e3          	bne	s1,s3,80002c2a <kill+0x20>
  }
  return -1;
    80002c4c:	557d                	li	a0,-1
    80002c4e:	a829                	j	80002c68 <kill+0x5e>
      p->killed = 1;
    80002c50:	4785                	li	a5,1
    80002c52:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002c54:	4c98                	lw	a4,24(s1)
    80002c56:	4789                	li	a5,2
    80002c58:	00f70f63          	beq	a4,a5,80002c76 <kill+0x6c>
      release(&p->lock);
    80002c5c:	8526                	mv	a0,s1
    80002c5e:	ffffe097          	auipc	ra,0xffffe
    80002c62:	05a080e7          	jalr	90(ra) # 80000cb8 <release>
      return 0;
    80002c66:	4501                	li	a0,0
}
    80002c68:	70a2                	ld	ra,40(sp)
    80002c6a:	7402                	ld	s0,32(sp)
    80002c6c:	64e2                	ld	s1,24(sp)
    80002c6e:	6942                	ld	s2,16(sp)
    80002c70:	69a2                	ld	s3,8(sp)
    80002c72:	6145                	addi	sp,sp,48
    80002c74:	8082                	ret
        remove_proc(&sleeping_head, p, &sleeping_lock);
    80002c76:	0000e917          	auipc	s2,0xe
    80002c7a:	62a90913          	addi	s2,s2,1578 # 800112a0 <cpus>
    80002c7e:	0000f617          	auipc	a2,0xf
    80002c82:	bd260613          	addi	a2,a2,-1070 # 80011850 <sleeping_lock>
    80002c86:	85a6                	mv	a1,s1
    80002c88:	00006517          	auipc	a0,0x6
    80002c8c:	bd850513          	addi	a0,a0,-1064 # 80008860 <sleeping_head>
    80002c90:	fffff097          	auipc	ra,0xfffff
    80002c94:	d1e080e7          	jalr	-738(ra) # 800019ae <remove_proc>
        p->state = RUNNABLE;
    80002c98:	478d                	li	a5,3
    80002c9a:	cc9c                	sw	a5,24(s1)
        struct cpu *c = &cpus[p->cpu];
    80002c9c:	58dc                	lw	a5,52(s1)
    80002c9e:	2781                	sext.w	a5,a5
        add_proc(&c->runnable_head, p, &c->head_lock);
    80002ca0:	0b000713          	li	a4,176
    80002ca4:	02e787b3          	mul	a5,a5,a4
    80002ca8:	09078613          	addi	a2,a5,144
    80002cac:	08878793          	addi	a5,a5,136
    80002cb0:	964a                	add	a2,a2,s2
    80002cb2:	85a6                	mv	a1,s1
    80002cb4:	00f90533          	add	a0,s2,a5
    80002cb8:	fffff097          	auipc	ra,0xfffff
    80002cbc:	e3a080e7          	jalr	-454(ra) # 80001af2 <add_proc>
    80002cc0:	bf71                	j	80002c5c <kill+0x52>

0000000080002cc2 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002cc2:	7179                	addi	sp,sp,-48
    80002cc4:	f406                	sd	ra,40(sp)
    80002cc6:	f022                	sd	s0,32(sp)
    80002cc8:	ec26                	sd	s1,24(sp)
    80002cca:	e84a                	sd	s2,16(sp)
    80002ccc:	e44e                	sd	s3,8(sp)
    80002cce:	e052                	sd	s4,0(sp)
    80002cd0:	1800                	addi	s0,sp,48
    80002cd2:	84aa                	mv	s1,a0
    80002cd4:	892e                	mv	s2,a1
    80002cd6:	89b2                	mv	s3,a2
    80002cd8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002cda:	fffff097          	auipc	ra,0xfffff
    80002cde:	182080e7          	jalr	386(ra) # 80001e5c <myproc>
  if (user_dst)
    80002ce2:	c08d                	beqz	s1,80002d04 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002ce4:	86d2                	mv	a3,s4
    80002ce6:	864e                	mv	a2,s3
    80002ce8:	85ca                	mv	a1,s2
    80002cea:	7928                	ld	a0,112(a0)
    80002cec:	fffff097          	auipc	ra,0xfffff
    80002cf0:	9b8080e7          	jalr	-1608(ra) # 800016a4 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002cf4:	70a2                	ld	ra,40(sp)
    80002cf6:	7402                	ld	s0,32(sp)
    80002cf8:	64e2                	ld	s1,24(sp)
    80002cfa:	6942                	ld	s2,16(sp)
    80002cfc:	69a2                	ld	s3,8(sp)
    80002cfe:	6a02                	ld	s4,0(sp)
    80002d00:	6145                	addi	sp,sp,48
    80002d02:	8082                	ret
    memmove((char *)dst, src, len);
    80002d04:	000a061b          	sext.w	a2,s4
    80002d08:	85ce                	mv	a1,s3
    80002d0a:	854a                	mv	a0,s2
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	066080e7          	jalr	102(ra) # 80000d72 <memmove>
    return 0;
    80002d14:	8526                	mv	a0,s1
    80002d16:	bff9                	j	80002cf4 <either_copyout+0x32>

0000000080002d18 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002d18:	7179                	addi	sp,sp,-48
    80002d1a:	f406                	sd	ra,40(sp)
    80002d1c:	f022                	sd	s0,32(sp)
    80002d1e:	ec26                	sd	s1,24(sp)
    80002d20:	e84a                	sd	s2,16(sp)
    80002d22:	e44e                	sd	s3,8(sp)
    80002d24:	e052                	sd	s4,0(sp)
    80002d26:	1800                	addi	s0,sp,48
    80002d28:	892a                	mv	s2,a0
    80002d2a:	84ae                	mv	s1,a1
    80002d2c:	89b2                	mv	s3,a2
    80002d2e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002d30:	fffff097          	auipc	ra,0xfffff
    80002d34:	12c080e7          	jalr	300(ra) # 80001e5c <myproc>
  if (user_src)
    80002d38:	c08d                	beqz	s1,80002d5a <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002d3a:	86d2                	mv	a3,s4
    80002d3c:	864e                	mv	a2,s3
    80002d3e:	85ca                	mv	a1,s2
    80002d40:	7928                	ld	a0,112(a0)
    80002d42:	fffff097          	auipc	ra,0xfffff
    80002d46:	9ee080e7          	jalr	-1554(ra) # 80001730 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002d4a:	70a2                	ld	ra,40(sp)
    80002d4c:	7402                	ld	s0,32(sp)
    80002d4e:	64e2                	ld	s1,24(sp)
    80002d50:	6942                	ld	s2,16(sp)
    80002d52:	69a2                	ld	s3,8(sp)
    80002d54:	6a02                	ld	s4,0(sp)
    80002d56:	6145                	addi	sp,sp,48
    80002d58:	8082                	ret
    memmove(dst, (char *)src, len);
    80002d5a:	000a061b          	sext.w	a2,s4
    80002d5e:	85ce                	mv	a1,s3
    80002d60:	854a                	mv	a0,s2
    80002d62:	ffffe097          	auipc	ra,0xffffe
    80002d66:	010080e7          	jalr	16(ra) # 80000d72 <memmove>
    return 0;
    80002d6a:	8526                	mv	a0,s1
    80002d6c:	bff9                	j	80002d4a <either_copyin+0x32>

0000000080002d6e <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002d6e:	715d                	addi	sp,sp,-80
    80002d70:	e486                	sd	ra,72(sp)
    80002d72:	e0a2                	sd	s0,64(sp)
    80002d74:	fc26                	sd	s1,56(sp)
    80002d76:	f84a                	sd	s2,48(sp)
    80002d78:	f44e                	sd	s3,40(sp)
    80002d7a:	f052                	sd	s4,32(sp)
    80002d7c:	ec56                	sd	s5,24(sp)
    80002d7e:	e85a                	sd	s6,16(sp)
    80002d80:	e45e                	sd	s7,8(sp)
    80002d82:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002d84:	00005517          	auipc	a0,0x5
    80002d88:	34c50513          	addi	a0,a0,844 # 800080d0 <digits+0x90>
    80002d8c:	ffffd097          	auipc	ra,0xffffd
    80002d90:	7fc080e7          	jalr	2044(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002d94:	0000f497          	auipc	s1,0xf
    80002d98:	c7c48493          	addi	s1,s1,-900 # 80011a10 <proc+0x178>
    80002d9c:	00015917          	auipc	s2,0x15
    80002da0:	e7490913          	addi	s2,s2,-396 # 80017c10 <bcache+0x160>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002da4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002da6:	00005997          	auipc	s3,0x5
    80002daa:	51a98993          	addi	s3,s3,1306 # 800082c0 <digits+0x280>
    printf("%d %s %s", p->pid, state, p->name);
    80002dae:	00005a97          	auipc	s5,0x5
    80002db2:	51aa8a93          	addi	s5,s5,1306 # 800082c8 <digits+0x288>
    printf("\n");
    80002db6:	00005a17          	auipc	s4,0x5
    80002dba:	31aa0a13          	addi	s4,s4,794 # 800080d0 <digits+0x90>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002dbe:	00005b97          	auipc	s7,0x5
    80002dc2:	532b8b93          	addi	s7,s7,1330 # 800082f0 <states.1804>
    80002dc6:	a00d                	j	80002de8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002dc8:	eb86a583          	lw	a1,-328(a3)
    80002dcc:	8556                	mv	a0,s5
    80002dce:	ffffd097          	auipc	ra,0xffffd
    80002dd2:	7ba080e7          	jalr	1978(ra) # 80000588 <printf>
    printf("\n");
    80002dd6:	8552                	mv	a0,s4
    80002dd8:	ffffd097          	auipc	ra,0xffffd
    80002ddc:	7b0080e7          	jalr	1968(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002de0:	18848493          	addi	s1,s1,392
    80002de4:	03248163          	beq	s1,s2,80002e06 <procdump+0x98>
    if (p->state == UNUSED)
    80002de8:	86a6                	mv	a3,s1
    80002dea:	ea04a783          	lw	a5,-352(s1)
    80002dee:	dbed                	beqz	a5,80002de0 <procdump+0x72>
      state = "???";
    80002df0:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002df2:	fcfb6be3          	bltu	s6,a5,80002dc8 <procdump+0x5a>
    80002df6:	1782                	slli	a5,a5,0x20
    80002df8:	9381                	srli	a5,a5,0x20
    80002dfa:	078e                	slli	a5,a5,0x3
    80002dfc:	97de                	add	a5,a5,s7
    80002dfe:	6390                	ld	a2,0(a5)
    80002e00:	f661                	bnez	a2,80002dc8 <procdump+0x5a>
      state = "???";
    80002e02:	864e                	mv	a2,s3
    80002e04:	b7d1                	j	80002dc8 <procdump+0x5a>
  }
}
    80002e06:	60a6                	ld	ra,72(sp)
    80002e08:	6406                	ld	s0,64(sp)
    80002e0a:	74e2                	ld	s1,56(sp)
    80002e0c:	7942                	ld	s2,48(sp)
    80002e0e:	79a2                	ld	s3,40(sp)
    80002e10:	7a02                	ld	s4,32(sp)
    80002e12:	6ae2                	ld	s5,24(sp)
    80002e14:	6b42                	ld	s6,16(sp)
    80002e16:	6ba2                	ld	s7,8(sp)
    80002e18:	6161                	addi	sp,sp,80
    80002e1a:	8082                	ret

0000000080002e1c <get_cpu>:

int get_cpu()
{
    80002e1c:	1101                	addi	sp,sp,-32
    80002e1e:	ec06                	sd	ra,24(sp)
    80002e20:	e822                	sd	s0,16(sp)
    80002e22:	e426                	sd	s1,8(sp)
    80002e24:	e04a                	sd	s2,0(sp)
    80002e26:	1000                	addi	s0,sp,32
  int cpu_num = -1;
  struct proc *p = myproc();
    80002e28:	fffff097          	auipc	ra,0xfffff
    80002e2c:	034080e7          	jalr	52(ra) # 80001e5c <myproc>
    80002e30:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002e32:	ffffe097          	auipc	ra,0xffffe
    80002e36:	dba080e7          	jalr	-582(ra) # 80000bec <acquire>
  cpu_num = p->cpu;
    80002e3a:	0344a903          	lw	s2,52(s1)
    80002e3e:	2901                	sext.w	s2,s2
  release(&p->lock);
    80002e40:	8526                	mv	a0,s1
    80002e42:	ffffe097          	auipc	ra,0xffffe
    80002e46:	e76080e7          	jalr	-394(ra) # 80000cb8 <release>
  return cpu_num;
}
    80002e4a:	854a                	mv	a0,s2
    80002e4c:	60e2                	ld	ra,24(sp)
    80002e4e:	6442                	ld	s0,16(sp)
    80002e50:	64a2                	ld	s1,8(sp)
    80002e52:	6902                	ld	s2,0(sp)
    80002e54:	6105                	addi	sp,sp,32
    80002e56:	8082                	ret

0000000080002e58 <set_cpu>:

int set_cpu(int cpu_num)
{
    80002e58:	1101                	addi	sp,sp,-32
    80002e5a:	ec06                	sd	ra,24(sp)
    80002e5c:	e822                	sd	s0,16(sp)
    80002e5e:	e426                	sd	s1,8(sp)
    80002e60:	1000                	addi	s0,sp,32
    80002e62:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e64:	fffff097          	auipc	ra,0xfffff
    80002e68:	ff8080e7          	jalr	-8(ra) # 80001e5c <myproc>
  if (cas(&p->cpu, p->cpu, cpu_num) != 0)
    80002e6c:	594c                	lw	a1,52(a0)
    80002e6e:	8626                	mv	a2,s1
    80002e70:	2581                	sext.w	a1,a1
    80002e72:	03450513          	addi	a0,a0,52
    80002e76:	00004097          	auipc	ra,0x4
    80002e7a:	c80080e7          	jalr	-896(ra) # 80006af6 <cas>
    80002e7e:	e919                	bnez	a0,80002e94 <set_cpu+0x3c>
    return -1;
  yield();
    80002e80:	00000097          	auipc	ra,0x0
    80002e84:	804080e7          	jalr	-2044(ra) # 80002684 <yield>
  return cpu_num;
    80002e88:	8526                	mv	a0,s1
}
    80002e8a:	60e2                	ld	ra,24(sp)
    80002e8c:	6442                	ld	s0,16(sp)
    80002e8e:	64a2                	ld	s1,8(sp)
    80002e90:	6105                	addi	sp,sp,32
    80002e92:	8082                	ret
    return -1;
    80002e94:	557d                	li	a0,-1
    80002e96:	bfd5                	j	80002e8a <set_cpu+0x32>

0000000080002e98 <cpu_process_count>:

int cpu_process_count(int cpu_num)
{
    80002e98:	1141                	addi	sp,sp,-16
    80002e9a:	e422                	sd	s0,8(sp)
    80002e9c:	0800                	addi	s0,sp,16
  return (cpus[cpu_num].proc_counter);
    80002e9e:	0b000793          	li	a5,176
    80002ea2:	02f507b3          	mul	a5,a0,a5
    80002ea6:	0000e517          	auipc	a0,0xe
    80002eaa:	3fa50513          	addi	a0,a0,1018 # 800112a0 <cpus>
    80002eae:	953e                	add	a0,a0,a5
    80002eb0:	7548                	ld	a0,168(a0)
    80002eb2:	2501                	sext.w	a0,a0
    80002eb4:	6422                	ld	s0,8(sp)
    80002eb6:	0141                	addi	sp,sp,16
    80002eb8:	8082                	ret

0000000080002eba <swtch>:
    80002eba:	00153023          	sd	ra,0(a0)
    80002ebe:	00253423          	sd	sp,8(a0)
    80002ec2:	e900                	sd	s0,16(a0)
    80002ec4:	ed04                	sd	s1,24(a0)
    80002ec6:	03253023          	sd	s2,32(a0)
    80002eca:	03353423          	sd	s3,40(a0)
    80002ece:	03453823          	sd	s4,48(a0)
    80002ed2:	03553c23          	sd	s5,56(a0)
    80002ed6:	05653023          	sd	s6,64(a0)
    80002eda:	05753423          	sd	s7,72(a0)
    80002ede:	05853823          	sd	s8,80(a0)
    80002ee2:	05953c23          	sd	s9,88(a0)
    80002ee6:	07a53023          	sd	s10,96(a0)
    80002eea:	07b53423          	sd	s11,104(a0)
    80002eee:	0005b083          	ld	ra,0(a1)
    80002ef2:	0085b103          	ld	sp,8(a1)
    80002ef6:	6980                	ld	s0,16(a1)
    80002ef8:	6d84                	ld	s1,24(a1)
    80002efa:	0205b903          	ld	s2,32(a1)
    80002efe:	0285b983          	ld	s3,40(a1)
    80002f02:	0305ba03          	ld	s4,48(a1)
    80002f06:	0385ba83          	ld	s5,56(a1)
    80002f0a:	0405bb03          	ld	s6,64(a1)
    80002f0e:	0485bb83          	ld	s7,72(a1)
    80002f12:	0505bc03          	ld	s8,80(a1)
    80002f16:	0585bc83          	ld	s9,88(a1)
    80002f1a:	0605bd03          	ld	s10,96(a1)
    80002f1e:	0685bd83          	ld	s11,104(a1)
    80002f22:	8082                	ret

0000000080002f24 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002f24:	1141                	addi	sp,sp,-16
    80002f26:	e406                	sd	ra,8(sp)
    80002f28:	e022                	sd	s0,0(sp)
    80002f2a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002f2c:	00005597          	auipc	a1,0x5
    80002f30:	3f458593          	addi	a1,a1,1012 # 80008320 <states.1804+0x30>
    80002f34:	00015517          	auipc	a0,0x15
    80002f38:	b6450513          	addi	a0,a0,-1180 # 80017a98 <tickslock>
    80002f3c:	ffffe097          	auipc	ra,0xffffe
    80002f40:	c18080e7          	jalr	-1000(ra) # 80000b54 <initlock>
}
    80002f44:	60a2                	ld	ra,8(sp)
    80002f46:	6402                	ld	s0,0(sp)
    80002f48:	0141                	addi	sp,sp,16
    80002f4a:	8082                	ret

0000000080002f4c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002f4c:	1141                	addi	sp,sp,-16
    80002f4e:	e422                	sd	s0,8(sp)
    80002f50:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f52:	00003797          	auipc	a5,0x3
    80002f56:	4ce78793          	addi	a5,a5,1230 # 80006420 <kernelvec>
    80002f5a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002f5e:	6422                	ld	s0,8(sp)
    80002f60:	0141                	addi	sp,sp,16
    80002f62:	8082                	ret

0000000080002f64 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002f64:	1141                	addi	sp,sp,-16
    80002f66:	e406                	sd	ra,8(sp)
    80002f68:	e022                	sd	s0,0(sp)
    80002f6a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002f6c:	fffff097          	auipc	ra,0xfffff
    80002f70:	ef0080e7          	jalr	-272(ra) # 80001e5c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f74:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002f78:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f7a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002f7e:	00004617          	auipc	a2,0x4
    80002f82:	08260613          	addi	a2,a2,130 # 80007000 <_trampoline>
    80002f86:	00004697          	auipc	a3,0x4
    80002f8a:	07a68693          	addi	a3,a3,122 # 80007000 <_trampoline>
    80002f8e:	8e91                	sub	a3,a3,a2
    80002f90:	040007b7          	lui	a5,0x4000
    80002f94:	17fd                	addi	a5,a5,-1
    80002f96:	07b2                	slli	a5,a5,0xc
    80002f98:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f9a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002f9e:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002fa0:	180026f3          	csrr	a3,satp
    80002fa4:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002fa6:	7d38                	ld	a4,120(a0)
    80002fa8:	7134                	ld	a3,96(a0)
    80002faa:	6585                	lui	a1,0x1
    80002fac:	96ae                	add	a3,a3,a1
    80002fae:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002fb0:	7d38                	ld	a4,120(a0)
    80002fb2:	00000697          	auipc	a3,0x0
    80002fb6:	13868693          	addi	a3,a3,312 # 800030ea <usertrap>
    80002fba:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002fbc:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002fbe:	8692                	mv	a3,tp
    80002fc0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fc2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002fc6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002fca:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fce:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002fd2:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002fd4:	6f18                	ld	a4,24(a4)
    80002fd6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002fda:	792c                	ld	a1,112(a0)
    80002fdc:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002fde:	00004717          	auipc	a4,0x4
    80002fe2:	0b270713          	addi	a4,a4,178 # 80007090 <userret>
    80002fe6:	8f11                	sub	a4,a4,a2
    80002fe8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002fea:	577d                	li	a4,-1
    80002fec:	177e                	slli	a4,a4,0x3f
    80002fee:	8dd9                	or	a1,a1,a4
    80002ff0:	02000537          	lui	a0,0x2000
    80002ff4:	157d                	addi	a0,a0,-1
    80002ff6:	0536                	slli	a0,a0,0xd
    80002ff8:	9782                	jalr	a5
}
    80002ffa:	60a2                	ld	ra,8(sp)
    80002ffc:	6402                	ld	s0,0(sp)
    80002ffe:	0141                	addi	sp,sp,16
    80003000:	8082                	ret

0000000080003002 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80003002:	1101                	addi	sp,sp,-32
    80003004:	ec06                	sd	ra,24(sp)
    80003006:	e822                	sd	s0,16(sp)
    80003008:	e426                	sd	s1,8(sp)
    8000300a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000300c:	00015497          	auipc	s1,0x15
    80003010:	a8c48493          	addi	s1,s1,-1396 # 80017a98 <tickslock>
    80003014:	8526                	mv	a0,s1
    80003016:	ffffe097          	auipc	ra,0xffffe
    8000301a:	bd6080e7          	jalr	-1066(ra) # 80000bec <acquire>
  ticks++;
    8000301e:	00006517          	auipc	a0,0x6
    80003022:	01250513          	addi	a0,a0,18 # 80009030 <ticks>
    80003026:	411c                	lw	a5,0(a0)
    80003028:	2785                	addiw	a5,a5,1
    8000302a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000302c:	00000097          	auipc	ra,0x0
    80003030:	9b0080e7          	jalr	-1616(ra) # 800029dc <wakeup>
  release(&tickslock);
    80003034:	8526                	mv	a0,s1
    80003036:	ffffe097          	auipc	ra,0xffffe
    8000303a:	c82080e7          	jalr	-894(ra) # 80000cb8 <release>
}
    8000303e:	60e2                	ld	ra,24(sp)
    80003040:	6442                	ld	s0,16(sp)
    80003042:	64a2                	ld	s1,8(sp)
    80003044:	6105                	addi	sp,sp,32
    80003046:	8082                	ret

0000000080003048 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003048:	1101                	addi	sp,sp,-32
    8000304a:	ec06                	sd	ra,24(sp)
    8000304c:	e822                	sd	s0,16(sp)
    8000304e:	e426                	sd	s1,8(sp)
    80003050:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003052:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003056:	00074d63          	bltz	a4,80003070 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000305a:	57fd                	li	a5,-1
    8000305c:	17fe                	slli	a5,a5,0x3f
    8000305e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80003060:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003062:	06f70363          	beq	a4,a5,800030c8 <devintr+0x80>
  }
}
    80003066:	60e2                	ld	ra,24(sp)
    80003068:	6442                	ld	s0,16(sp)
    8000306a:	64a2                	ld	s1,8(sp)
    8000306c:	6105                	addi	sp,sp,32
    8000306e:	8082                	ret
     (scause & 0xff) == 9){
    80003070:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003074:	46a5                	li	a3,9
    80003076:	fed792e3          	bne	a5,a3,8000305a <devintr+0x12>
    int irq = plic_claim();
    8000307a:	00003097          	auipc	ra,0x3
    8000307e:	4ae080e7          	jalr	1198(ra) # 80006528 <plic_claim>
    80003082:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003084:	47a9                	li	a5,10
    80003086:	02f50763          	beq	a0,a5,800030b4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000308a:	4785                	li	a5,1
    8000308c:	02f50963          	beq	a0,a5,800030be <devintr+0x76>
    return 1;
    80003090:	4505                	li	a0,1
    } else if(irq){
    80003092:	d8f1                	beqz	s1,80003066 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003094:	85a6                	mv	a1,s1
    80003096:	00005517          	auipc	a0,0x5
    8000309a:	29250513          	addi	a0,a0,658 # 80008328 <states.1804+0x38>
    8000309e:	ffffd097          	auipc	ra,0xffffd
    800030a2:	4ea080e7          	jalr	1258(ra) # 80000588 <printf>
      plic_complete(irq);
    800030a6:	8526                	mv	a0,s1
    800030a8:	00003097          	auipc	ra,0x3
    800030ac:	4a4080e7          	jalr	1188(ra) # 8000654c <plic_complete>
    return 1;
    800030b0:	4505                	li	a0,1
    800030b2:	bf55                	j	80003066 <devintr+0x1e>
      uartintr();
    800030b4:	ffffe097          	auipc	ra,0xffffe
    800030b8:	8f4080e7          	jalr	-1804(ra) # 800009a8 <uartintr>
    800030bc:	b7ed                	j	800030a6 <devintr+0x5e>
      virtio_disk_intr();
    800030be:	00004097          	auipc	ra,0x4
    800030c2:	96e080e7          	jalr	-1682(ra) # 80006a2c <virtio_disk_intr>
    800030c6:	b7c5                	j	800030a6 <devintr+0x5e>
    if(cpuid() == 0){
    800030c8:	fffff097          	auipc	ra,0xfffff
    800030cc:	d62080e7          	jalr	-670(ra) # 80001e2a <cpuid>
    800030d0:	c901                	beqz	a0,800030e0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800030d2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800030d6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800030d8:	14479073          	csrw	sip,a5
    return 2;
    800030dc:	4509                	li	a0,2
    800030de:	b761                	j	80003066 <devintr+0x1e>
      clockintr();
    800030e0:	00000097          	auipc	ra,0x0
    800030e4:	f22080e7          	jalr	-222(ra) # 80003002 <clockintr>
    800030e8:	b7ed                	j	800030d2 <devintr+0x8a>

00000000800030ea <usertrap>:
{
    800030ea:	1101                	addi	sp,sp,-32
    800030ec:	ec06                	sd	ra,24(sp)
    800030ee:	e822                	sd	s0,16(sp)
    800030f0:	e426                	sd	s1,8(sp)
    800030f2:	e04a                	sd	s2,0(sp)
    800030f4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030f6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800030fa:	1007f793          	andi	a5,a5,256
    800030fe:	e3ad                	bnez	a5,80003160 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003100:	00003797          	auipc	a5,0x3
    80003104:	32078793          	addi	a5,a5,800 # 80006420 <kernelvec>
    80003108:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000310c:	fffff097          	auipc	ra,0xfffff
    80003110:	d50080e7          	jalr	-688(ra) # 80001e5c <myproc>
    80003114:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003116:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003118:	14102773          	csrr	a4,sepc
    8000311c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000311e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003122:	47a1                	li	a5,8
    80003124:	04f71c63          	bne	a4,a5,8000317c <usertrap+0x92>
    if(p->killed)
    80003128:	551c                	lw	a5,40(a0)
    8000312a:	e3b9                	bnez	a5,80003170 <usertrap+0x86>
    p->trapframe->epc += 4;
    8000312c:	7cb8                	ld	a4,120(s1)
    8000312e:	6f1c                	ld	a5,24(a4)
    80003130:	0791                	addi	a5,a5,4
    80003132:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003134:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003138:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000313c:	10079073          	csrw	sstatus,a5
    syscall();
    80003140:	00000097          	auipc	ra,0x0
    80003144:	2e0080e7          	jalr	736(ra) # 80003420 <syscall>
  if(p->killed)
    80003148:	549c                	lw	a5,40(s1)
    8000314a:	ebc1                	bnez	a5,800031da <usertrap+0xf0>
  usertrapret();
    8000314c:	00000097          	auipc	ra,0x0
    80003150:	e18080e7          	jalr	-488(ra) # 80002f64 <usertrapret>
}
    80003154:	60e2                	ld	ra,24(sp)
    80003156:	6442                	ld	s0,16(sp)
    80003158:	64a2                	ld	s1,8(sp)
    8000315a:	6902                	ld	s2,0(sp)
    8000315c:	6105                	addi	sp,sp,32
    8000315e:	8082                	ret
    panic("usertrap: not from user mode");
    80003160:	00005517          	auipc	a0,0x5
    80003164:	1e850513          	addi	a0,a0,488 # 80008348 <states.1804+0x58>
    80003168:	ffffd097          	auipc	ra,0xffffd
    8000316c:	3d6080e7          	jalr	982(ra) # 8000053e <panic>
      exit(-1);
    80003170:	557d                	li	a0,-1
    80003172:	00000097          	auipc	ra,0x0
    80003176:	9a8080e7          	jalr	-1624(ra) # 80002b1a <exit>
    8000317a:	bf4d                	j	8000312c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000317c:	00000097          	auipc	ra,0x0
    80003180:	ecc080e7          	jalr	-308(ra) # 80003048 <devintr>
    80003184:	892a                	mv	s2,a0
    80003186:	c501                	beqz	a0,8000318e <usertrap+0xa4>
  if(p->killed)
    80003188:	549c                	lw	a5,40(s1)
    8000318a:	c3a1                	beqz	a5,800031ca <usertrap+0xe0>
    8000318c:	a815                	j	800031c0 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000318e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003192:	5890                	lw	a2,48(s1)
    80003194:	00005517          	auipc	a0,0x5
    80003198:	1d450513          	addi	a0,a0,468 # 80008368 <states.1804+0x78>
    8000319c:	ffffd097          	auipc	ra,0xffffd
    800031a0:	3ec080e7          	jalr	1004(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031a4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800031a8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800031ac:	00005517          	auipc	a0,0x5
    800031b0:	1ec50513          	addi	a0,a0,492 # 80008398 <states.1804+0xa8>
    800031b4:	ffffd097          	auipc	ra,0xffffd
    800031b8:	3d4080e7          	jalr	980(ra) # 80000588 <printf>
    p->killed = 1;
    800031bc:	4785                	li	a5,1
    800031be:	d49c                	sw	a5,40(s1)
    exit(-1);
    800031c0:	557d                	li	a0,-1
    800031c2:	00000097          	auipc	ra,0x0
    800031c6:	958080e7          	jalr	-1704(ra) # 80002b1a <exit>
  if(which_dev == 2)
    800031ca:	4789                	li	a5,2
    800031cc:	f8f910e3          	bne	s2,a5,8000314c <usertrap+0x62>
    yield();
    800031d0:	fffff097          	auipc	ra,0xfffff
    800031d4:	4b4080e7          	jalr	1204(ra) # 80002684 <yield>
    800031d8:	bf95                	j	8000314c <usertrap+0x62>
  int which_dev = 0;
    800031da:	4901                	li	s2,0
    800031dc:	b7d5                	j	800031c0 <usertrap+0xd6>

00000000800031de <kerneltrap>:
{
    800031de:	7179                	addi	sp,sp,-48
    800031e0:	f406                	sd	ra,40(sp)
    800031e2:	f022                	sd	s0,32(sp)
    800031e4:	ec26                	sd	s1,24(sp)
    800031e6:	e84a                	sd	s2,16(sp)
    800031e8:	e44e                	sd	s3,8(sp)
    800031ea:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031ec:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031f0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031f4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800031f8:	1004f793          	andi	a5,s1,256
    800031fc:	cb85                	beqz	a5,8000322c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031fe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003202:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003204:	ef85                	bnez	a5,8000323c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003206:	00000097          	auipc	ra,0x0
    8000320a:	e42080e7          	jalr	-446(ra) # 80003048 <devintr>
    8000320e:	cd1d                	beqz	a0,8000324c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003210:	4789                	li	a5,2
    80003212:	06f50a63          	beq	a0,a5,80003286 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003216:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000321a:	10049073          	csrw	sstatus,s1
}
    8000321e:	70a2                	ld	ra,40(sp)
    80003220:	7402                	ld	s0,32(sp)
    80003222:	64e2                	ld	s1,24(sp)
    80003224:	6942                	ld	s2,16(sp)
    80003226:	69a2                	ld	s3,8(sp)
    80003228:	6145                	addi	sp,sp,48
    8000322a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000322c:	00005517          	auipc	a0,0x5
    80003230:	18c50513          	addi	a0,a0,396 # 800083b8 <states.1804+0xc8>
    80003234:	ffffd097          	auipc	ra,0xffffd
    80003238:	30a080e7          	jalr	778(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    8000323c:	00005517          	auipc	a0,0x5
    80003240:	1a450513          	addi	a0,a0,420 # 800083e0 <states.1804+0xf0>
    80003244:	ffffd097          	auipc	ra,0xffffd
    80003248:	2fa080e7          	jalr	762(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    8000324c:	85ce                	mv	a1,s3
    8000324e:	00005517          	auipc	a0,0x5
    80003252:	1b250513          	addi	a0,a0,434 # 80008400 <states.1804+0x110>
    80003256:	ffffd097          	auipc	ra,0xffffd
    8000325a:	332080e7          	jalr	818(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000325e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003262:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003266:	00005517          	auipc	a0,0x5
    8000326a:	1aa50513          	addi	a0,a0,426 # 80008410 <states.1804+0x120>
    8000326e:	ffffd097          	auipc	ra,0xffffd
    80003272:	31a080e7          	jalr	794(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003276:	00005517          	auipc	a0,0x5
    8000327a:	1b250513          	addi	a0,a0,434 # 80008428 <states.1804+0x138>
    8000327e:	ffffd097          	auipc	ra,0xffffd
    80003282:	2c0080e7          	jalr	704(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003286:	fffff097          	auipc	ra,0xfffff
    8000328a:	bd6080e7          	jalr	-1066(ra) # 80001e5c <myproc>
    8000328e:	d541                	beqz	a0,80003216 <kerneltrap+0x38>
    80003290:	fffff097          	auipc	ra,0xfffff
    80003294:	bcc080e7          	jalr	-1076(ra) # 80001e5c <myproc>
    80003298:	4d18                	lw	a4,24(a0)
    8000329a:	4791                	li	a5,4
    8000329c:	f6f71de3          	bne	a4,a5,80003216 <kerneltrap+0x38>
    yield();
    800032a0:	fffff097          	auipc	ra,0xfffff
    800032a4:	3e4080e7          	jalr	996(ra) # 80002684 <yield>
    800032a8:	b7bd                	j	80003216 <kerneltrap+0x38>

00000000800032aa <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800032aa:	1101                	addi	sp,sp,-32
    800032ac:	ec06                	sd	ra,24(sp)
    800032ae:	e822                	sd	s0,16(sp)
    800032b0:	e426                	sd	s1,8(sp)
    800032b2:	1000                	addi	s0,sp,32
    800032b4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800032b6:	fffff097          	auipc	ra,0xfffff
    800032ba:	ba6080e7          	jalr	-1114(ra) # 80001e5c <myproc>
  switch (n) {
    800032be:	4795                	li	a5,5
    800032c0:	0497e163          	bltu	a5,s1,80003302 <argraw+0x58>
    800032c4:	048a                	slli	s1,s1,0x2
    800032c6:	00005717          	auipc	a4,0x5
    800032ca:	19a70713          	addi	a4,a4,410 # 80008460 <states.1804+0x170>
    800032ce:	94ba                	add	s1,s1,a4
    800032d0:	409c                	lw	a5,0(s1)
    800032d2:	97ba                	add	a5,a5,a4
    800032d4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800032d6:	7d3c                	ld	a5,120(a0)
    800032d8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800032da:	60e2                	ld	ra,24(sp)
    800032dc:	6442                	ld	s0,16(sp)
    800032de:	64a2                	ld	s1,8(sp)
    800032e0:	6105                	addi	sp,sp,32
    800032e2:	8082                	ret
    return p->trapframe->a1;
    800032e4:	7d3c                	ld	a5,120(a0)
    800032e6:	7fa8                	ld	a0,120(a5)
    800032e8:	bfcd                	j	800032da <argraw+0x30>
    return p->trapframe->a2;
    800032ea:	7d3c                	ld	a5,120(a0)
    800032ec:	63c8                	ld	a0,128(a5)
    800032ee:	b7f5                	j	800032da <argraw+0x30>
    return p->trapframe->a3;
    800032f0:	7d3c                	ld	a5,120(a0)
    800032f2:	67c8                	ld	a0,136(a5)
    800032f4:	b7dd                	j	800032da <argraw+0x30>
    return p->trapframe->a4;
    800032f6:	7d3c                	ld	a5,120(a0)
    800032f8:	6bc8                	ld	a0,144(a5)
    800032fa:	b7c5                	j	800032da <argraw+0x30>
    return p->trapframe->a5;
    800032fc:	7d3c                	ld	a5,120(a0)
    800032fe:	6fc8                	ld	a0,152(a5)
    80003300:	bfe9                	j	800032da <argraw+0x30>
  panic("argraw");
    80003302:	00005517          	auipc	a0,0x5
    80003306:	13650513          	addi	a0,a0,310 # 80008438 <states.1804+0x148>
    8000330a:	ffffd097          	auipc	ra,0xffffd
    8000330e:	234080e7          	jalr	564(ra) # 8000053e <panic>

0000000080003312 <fetchaddr>:
{
    80003312:	1101                	addi	sp,sp,-32
    80003314:	ec06                	sd	ra,24(sp)
    80003316:	e822                	sd	s0,16(sp)
    80003318:	e426                	sd	s1,8(sp)
    8000331a:	e04a                	sd	s2,0(sp)
    8000331c:	1000                	addi	s0,sp,32
    8000331e:	84aa                	mv	s1,a0
    80003320:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003322:	fffff097          	auipc	ra,0xfffff
    80003326:	b3a080e7          	jalr	-1222(ra) # 80001e5c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    8000332a:	753c                	ld	a5,104(a0)
    8000332c:	02f4f863          	bgeu	s1,a5,8000335c <fetchaddr+0x4a>
    80003330:	00848713          	addi	a4,s1,8
    80003334:	02e7e663          	bltu	a5,a4,80003360 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003338:	46a1                	li	a3,8
    8000333a:	8626                	mv	a2,s1
    8000333c:	85ca                	mv	a1,s2
    8000333e:	7928                	ld	a0,112(a0)
    80003340:	ffffe097          	auipc	ra,0xffffe
    80003344:	3f0080e7          	jalr	1008(ra) # 80001730 <copyin>
    80003348:	00a03533          	snez	a0,a0
    8000334c:	40a00533          	neg	a0,a0
}
    80003350:	60e2                	ld	ra,24(sp)
    80003352:	6442                	ld	s0,16(sp)
    80003354:	64a2                	ld	s1,8(sp)
    80003356:	6902                	ld	s2,0(sp)
    80003358:	6105                	addi	sp,sp,32
    8000335a:	8082                	ret
    return -1;
    8000335c:	557d                	li	a0,-1
    8000335e:	bfcd                	j	80003350 <fetchaddr+0x3e>
    80003360:	557d                	li	a0,-1
    80003362:	b7fd                	j	80003350 <fetchaddr+0x3e>

0000000080003364 <fetchstr>:
{
    80003364:	7179                	addi	sp,sp,-48
    80003366:	f406                	sd	ra,40(sp)
    80003368:	f022                	sd	s0,32(sp)
    8000336a:	ec26                	sd	s1,24(sp)
    8000336c:	e84a                	sd	s2,16(sp)
    8000336e:	e44e                	sd	s3,8(sp)
    80003370:	1800                	addi	s0,sp,48
    80003372:	892a                	mv	s2,a0
    80003374:	84ae                	mv	s1,a1
    80003376:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003378:	fffff097          	auipc	ra,0xfffff
    8000337c:	ae4080e7          	jalr	-1308(ra) # 80001e5c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003380:	86ce                	mv	a3,s3
    80003382:	864a                	mv	a2,s2
    80003384:	85a6                	mv	a1,s1
    80003386:	7928                	ld	a0,112(a0)
    80003388:	ffffe097          	auipc	ra,0xffffe
    8000338c:	434080e7          	jalr	1076(ra) # 800017bc <copyinstr>
  if(err < 0)
    80003390:	00054763          	bltz	a0,8000339e <fetchstr+0x3a>
  return strlen(buf);
    80003394:	8526                	mv	a0,s1
    80003396:	ffffe097          	auipc	ra,0xffffe
    8000339a:	b00080e7          	jalr	-1280(ra) # 80000e96 <strlen>
}
    8000339e:	70a2                	ld	ra,40(sp)
    800033a0:	7402                	ld	s0,32(sp)
    800033a2:	64e2                	ld	s1,24(sp)
    800033a4:	6942                	ld	s2,16(sp)
    800033a6:	69a2                	ld	s3,8(sp)
    800033a8:	6145                	addi	sp,sp,48
    800033aa:	8082                	ret

00000000800033ac <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800033ac:	1101                	addi	sp,sp,-32
    800033ae:	ec06                	sd	ra,24(sp)
    800033b0:	e822                	sd	s0,16(sp)
    800033b2:	e426                	sd	s1,8(sp)
    800033b4:	1000                	addi	s0,sp,32
    800033b6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800033b8:	00000097          	auipc	ra,0x0
    800033bc:	ef2080e7          	jalr	-270(ra) # 800032aa <argraw>
    800033c0:	c088                	sw	a0,0(s1)
  return 0;
}
    800033c2:	4501                	li	a0,0
    800033c4:	60e2                	ld	ra,24(sp)
    800033c6:	6442                	ld	s0,16(sp)
    800033c8:	64a2                	ld	s1,8(sp)
    800033ca:	6105                	addi	sp,sp,32
    800033cc:	8082                	ret

00000000800033ce <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800033ce:	1101                	addi	sp,sp,-32
    800033d0:	ec06                	sd	ra,24(sp)
    800033d2:	e822                	sd	s0,16(sp)
    800033d4:	e426                	sd	s1,8(sp)
    800033d6:	1000                	addi	s0,sp,32
    800033d8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800033da:	00000097          	auipc	ra,0x0
    800033de:	ed0080e7          	jalr	-304(ra) # 800032aa <argraw>
    800033e2:	e088                	sd	a0,0(s1)
  return 0;
}
    800033e4:	4501                	li	a0,0
    800033e6:	60e2                	ld	ra,24(sp)
    800033e8:	6442                	ld	s0,16(sp)
    800033ea:	64a2                	ld	s1,8(sp)
    800033ec:	6105                	addi	sp,sp,32
    800033ee:	8082                	ret

00000000800033f0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800033f0:	1101                	addi	sp,sp,-32
    800033f2:	ec06                	sd	ra,24(sp)
    800033f4:	e822                	sd	s0,16(sp)
    800033f6:	e426                	sd	s1,8(sp)
    800033f8:	e04a                	sd	s2,0(sp)
    800033fa:	1000                	addi	s0,sp,32
    800033fc:	84ae                	mv	s1,a1
    800033fe:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003400:	00000097          	auipc	ra,0x0
    80003404:	eaa080e7          	jalr	-342(ra) # 800032aa <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003408:	864a                	mv	a2,s2
    8000340a:	85a6                	mv	a1,s1
    8000340c:	00000097          	auipc	ra,0x0
    80003410:	f58080e7          	jalr	-168(ra) # 80003364 <fetchstr>
}
    80003414:	60e2                	ld	ra,24(sp)
    80003416:	6442                	ld	s0,16(sp)
    80003418:	64a2                	ld	s1,8(sp)
    8000341a:	6902                	ld	s2,0(sp)
    8000341c:	6105                	addi	sp,sp,32
    8000341e:	8082                	ret

0000000080003420 <syscall>:
[SYS_set_cpu] sys_set_cpu,
};

void
syscall(void)
{
    80003420:	1101                	addi	sp,sp,-32
    80003422:	ec06                	sd	ra,24(sp)
    80003424:	e822                	sd	s0,16(sp)
    80003426:	e426                	sd	s1,8(sp)
    80003428:	e04a                	sd	s2,0(sp)
    8000342a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000342c:	fffff097          	auipc	ra,0xfffff
    80003430:	a30080e7          	jalr	-1488(ra) # 80001e5c <myproc>
    80003434:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003436:	07853903          	ld	s2,120(a0)
    8000343a:	0a893783          	ld	a5,168(s2)
    8000343e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003442:	37fd                	addiw	a5,a5,-1
    80003444:	4759                	li	a4,22
    80003446:	00f76f63          	bltu	a4,a5,80003464 <syscall+0x44>
    8000344a:	00369713          	slli	a4,a3,0x3
    8000344e:	00005797          	auipc	a5,0x5
    80003452:	02a78793          	addi	a5,a5,42 # 80008478 <syscalls>
    80003456:	97ba                	add	a5,a5,a4
    80003458:	639c                	ld	a5,0(a5)
    8000345a:	c789                	beqz	a5,80003464 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000345c:	9782                	jalr	a5
    8000345e:	06a93823          	sd	a0,112(s2)
    80003462:	a839                	j	80003480 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003464:	17848613          	addi	a2,s1,376
    80003468:	588c                	lw	a1,48(s1)
    8000346a:	00005517          	auipc	a0,0x5
    8000346e:	fd650513          	addi	a0,a0,-42 # 80008440 <states.1804+0x150>
    80003472:	ffffd097          	auipc	ra,0xffffd
    80003476:	116080e7          	jalr	278(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000347a:	7cbc                	ld	a5,120(s1)
    8000347c:	577d                	li	a4,-1
    8000347e:	fbb8                	sd	a4,112(a5)
  }
}
    80003480:	60e2                	ld	ra,24(sp)
    80003482:	6442                	ld	s0,16(sp)
    80003484:	64a2                	ld	s1,8(sp)
    80003486:	6902                	ld	s2,0(sp)
    80003488:	6105                	addi	sp,sp,32
    8000348a:	8082                	ret

000000008000348c <sys_set_cpu>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_set_cpu(void)
{
    8000348c:	1101                	addi	sp,sp,-32
    8000348e:	ec06                	sd	ra,24(sp)
    80003490:	e822                	sd	s0,16(sp)
    80003492:	1000                	addi	s0,sp,32
  int cpu_num;
  if(argint(0, &cpu_num) < 0)
    80003494:	fec40593          	addi	a1,s0,-20
    80003498:	4501                	li	a0,0
    8000349a:	00000097          	auipc	ra,0x0
    8000349e:	f12080e7          	jalr	-238(ra) # 800033ac <argint>
    800034a2:	87aa                	mv	a5,a0
    return -1;
    800034a4:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    800034a6:	0007c863          	bltz	a5,800034b6 <sys_set_cpu+0x2a>
  return set_cpu(cpu_num); 
    800034aa:	fec42503          	lw	a0,-20(s0)
    800034ae:	00000097          	auipc	ra,0x0
    800034b2:	9aa080e7          	jalr	-1622(ra) # 80002e58 <set_cpu>
}
    800034b6:	60e2                	ld	ra,24(sp)
    800034b8:	6442                	ld	s0,16(sp)
    800034ba:	6105                	addi	sp,sp,32
    800034bc:	8082                	ret

00000000800034be <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    800034be:	1141                	addi	sp,sp,-16
    800034c0:	e406                	sd	ra,8(sp)
    800034c2:	e022                	sd	s0,0(sp)
    800034c4:	0800                	addi	s0,sp,16
  return get_cpu(); 
    800034c6:	00000097          	auipc	ra,0x0
    800034ca:	956080e7          	jalr	-1706(ra) # 80002e1c <get_cpu>
}
    800034ce:	60a2                	ld	ra,8(sp)
    800034d0:	6402                	ld	s0,0(sp)
    800034d2:	0141                	addi	sp,sp,16
    800034d4:	8082                	ret

00000000800034d6 <sys_exit>:

uint64
sys_exit(void)
{
    800034d6:	1101                	addi	sp,sp,-32
    800034d8:	ec06                	sd	ra,24(sp)
    800034da:	e822                	sd	s0,16(sp)
    800034dc:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800034de:	fec40593          	addi	a1,s0,-20
    800034e2:	4501                	li	a0,0
    800034e4:	00000097          	auipc	ra,0x0
    800034e8:	ec8080e7          	jalr	-312(ra) # 800033ac <argint>
    return -1;
    800034ec:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800034ee:	00054963          	bltz	a0,80003500 <sys_exit+0x2a>
  exit(n);
    800034f2:	fec42503          	lw	a0,-20(s0)
    800034f6:	fffff097          	auipc	ra,0xfffff
    800034fa:	624080e7          	jalr	1572(ra) # 80002b1a <exit>
  return 0;  // not reached
    800034fe:	4781                	li	a5,0
}
    80003500:	853e                	mv	a0,a5
    80003502:	60e2                	ld	ra,24(sp)
    80003504:	6442                	ld	s0,16(sp)
    80003506:	6105                	addi	sp,sp,32
    80003508:	8082                	ret

000000008000350a <sys_getpid>:

uint64
sys_getpid(void)
{
    8000350a:	1141                	addi	sp,sp,-16
    8000350c:	e406                	sd	ra,8(sp)
    8000350e:	e022                	sd	s0,0(sp)
    80003510:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003512:	fffff097          	auipc	ra,0xfffff
    80003516:	94a080e7          	jalr	-1718(ra) # 80001e5c <myproc>
}
    8000351a:	5908                	lw	a0,48(a0)
    8000351c:	60a2                	ld	ra,8(sp)
    8000351e:	6402                	ld	s0,0(sp)
    80003520:	0141                	addi	sp,sp,16
    80003522:	8082                	ret

0000000080003524 <sys_fork>:

uint64
sys_fork(void)
{
    80003524:	1141                	addi	sp,sp,-16
    80003526:	e406                	sd	ra,8(sp)
    80003528:	e022                	sd	s0,0(sp)
    8000352a:	0800                	addi	s0,sp,16
  return fork();
    8000352c:	fffff097          	auipc	ra,0xfffff
    80003530:	e14080e7          	jalr	-492(ra) # 80002340 <fork>
}
    80003534:	60a2                	ld	ra,8(sp)
    80003536:	6402                	ld	s0,0(sp)
    80003538:	0141                	addi	sp,sp,16
    8000353a:	8082                	ret

000000008000353c <sys_wait>:

uint64
sys_wait(void)
{
    8000353c:	1101                	addi	sp,sp,-32
    8000353e:	ec06                	sd	ra,24(sp)
    80003540:	e822                	sd	s0,16(sp)
    80003542:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003544:	fe840593          	addi	a1,s0,-24
    80003548:	4501                	li	a0,0
    8000354a:	00000097          	auipc	ra,0x0
    8000354e:	e84080e7          	jalr	-380(ra) # 800033ce <argaddr>
    80003552:	87aa                	mv	a5,a0
    return -1;
    80003554:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003556:	0007c863          	bltz	a5,80003566 <sys_wait+0x2a>
  return wait(p);
    8000355a:	fe843503          	ld	a0,-24(s0)
    8000355e:	fffff097          	auipc	ra,0xfffff
    80003562:	20a080e7          	jalr	522(ra) # 80002768 <wait>
}
    80003566:	60e2                	ld	ra,24(sp)
    80003568:	6442                	ld	s0,16(sp)
    8000356a:	6105                	addi	sp,sp,32
    8000356c:	8082                	ret

000000008000356e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000356e:	7179                	addi	sp,sp,-48
    80003570:	f406                	sd	ra,40(sp)
    80003572:	f022                	sd	s0,32(sp)
    80003574:	ec26                	sd	s1,24(sp)
    80003576:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003578:	fdc40593          	addi	a1,s0,-36
    8000357c:	4501                	li	a0,0
    8000357e:	00000097          	auipc	ra,0x0
    80003582:	e2e080e7          	jalr	-466(ra) # 800033ac <argint>
    80003586:	87aa                	mv	a5,a0
    return -1;
    80003588:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000358a:	0207c063          	bltz	a5,800035aa <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000358e:	fffff097          	auipc	ra,0xfffff
    80003592:	8ce080e7          	jalr	-1842(ra) # 80001e5c <myproc>
    80003596:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    80003598:	fdc42503          	lw	a0,-36(s0)
    8000359c:	fffff097          	auipc	ra,0xfffff
    800035a0:	ca8080e7          	jalr	-856(ra) # 80002244 <growproc>
    800035a4:	00054863          	bltz	a0,800035b4 <sys_sbrk+0x46>
    return -1;
  return addr;
    800035a8:	8526                	mv	a0,s1
}
    800035aa:	70a2                	ld	ra,40(sp)
    800035ac:	7402                	ld	s0,32(sp)
    800035ae:	64e2                	ld	s1,24(sp)
    800035b0:	6145                	addi	sp,sp,48
    800035b2:	8082                	ret
    return -1;
    800035b4:	557d                	li	a0,-1
    800035b6:	bfd5                	j	800035aa <sys_sbrk+0x3c>

00000000800035b8 <sys_sleep>:

uint64
sys_sleep(void)
{
    800035b8:	7139                	addi	sp,sp,-64
    800035ba:	fc06                	sd	ra,56(sp)
    800035bc:	f822                	sd	s0,48(sp)
    800035be:	f426                	sd	s1,40(sp)
    800035c0:	f04a                	sd	s2,32(sp)
    800035c2:	ec4e                	sd	s3,24(sp)
    800035c4:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800035c6:	fcc40593          	addi	a1,s0,-52
    800035ca:	4501                	li	a0,0
    800035cc:	00000097          	auipc	ra,0x0
    800035d0:	de0080e7          	jalr	-544(ra) # 800033ac <argint>
    return -1;
    800035d4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800035d6:	06054563          	bltz	a0,80003640 <sys_sleep+0x88>
  acquire(&tickslock);
    800035da:	00014517          	auipc	a0,0x14
    800035de:	4be50513          	addi	a0,a0,1214 # 80017a98 <tickslock>
    800035e2:	ffffd097          	auipc	ra,0xffffd
    800035e6:	60a080e7          	jalr	1546(ra) # 80000bec <acquire>
  ticks0 = ticks;
    800035ea:	00006917          	auipc	s2,0x6
    800035ee:	a4692903          	lw	s2,-1466(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800035f2:	fcc42783          	lw	a5,-52(s0)
    800035f6:	cf85                	beqz	a5,8000362e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800035f8:	00014997          	auipc	s3,0x14
    800035fc:	4a098993          	addi	s3,s3,1184 # 80017a98 <tickslock>
    80003600:	00006497          	auipc	s1,0x6
    80003604:	a3048493          	addi	s1,s1,-1488 # 80009030 <ticks>
    if(myproc()->killed){
    80003608:	fffff097          	auipc	ra,0xfffff
    8000360c:	854080e7          	jalr	-1964(ra) # 80001e5c <myproc>
    80003610:	551c                	lw	a5,40(a0)
    80003612:	ef9d                	bnez	a5,80003650 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003614:	85ce                	mv	a1,s3
    80003616:	8526                	mv	a0,s1
    80003618:	fffff097          	auipc	ra,0xfffff
    8000361c:	0d2080e7          	jalr	210(ra) # 800026ea <sleep>
  while(ticks - ticks0 < n){
    80003620:	409c                	lw	a5,0(s1)
    80003622:	412787bb          	subw	a5,a5,s2
    80003626:	fcc42703          	lw	a4,-52(s0)
    8000362a:	fce7efe3          	bltu	a5,a4,80003608 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000362e:	00014517          	auipc	a0,0x14
    80003632:	46a50513          	addi	a0,a0,1130 # 80017a98 <tickslock>
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	682080e7          	jalr	1666(ra) # 80000cb8 <release>
  return 0;
    8000363e:	4781                	li	a5,0
}
    80003640:	853e                	mv	a0,a5
    80003642:	70e2                	ld	ra,56(sp)
    80003644:	7442                	ld	s0,48(sp)
    80003646:	74a2                	ld	s1,40(sp)
    80003648:	7902                	ld	s2,32(sp)
    8000364a:	69e2                	ld	s3,24(sp)
    8000364c:	6121                	addi	sp,sp,64
    8000364e:	8082                	ret
      release(&tickslock);
    80003650:	00014517          	auipc	a0,0x14
    80003654:	44850513          	addi	a0,a0,1096 # 80017a98 <tickslock>
    80003658:	ffffd097          	auipc	ra,0xffffd
    8000365c:	660080e7          	jalr	1632(ra) # 80000cb8 <release>
      return -1;
    80003660:	57fd                	li	a5,-1
    80003662:	bff9                	j	80003640 <sys_sleep+0x88>

0000000080003664 <sys_kill>:

uint64
sys_kill(void)
{
    80003664:	1101                	addi	sp,sp,-32
    80003666:	ec06                	sd	ra,24(sp)
    80003668:	e822                	sd	s0,16(sp)
    8000366a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000366c:	fec40593          	addi	a1,s0,-20
    80003670:	4501                	li	a0,0
    80003672:	00000097          	auipc	ra,0x0
    80003676:	d3a080e7          	jalr	-710(ra) # 800033ac <argint>
    8000367a:	87aa                	mv	a5,a0
    return -1;
    8000367c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000367e:	0007c863          	bltz	a5,8000368e <sys_kill+0x2a>
  return kill(pid);
    80003682:	fec42503          	lw	a0,-20(s0)
    80003686:	fffff097          	auipc	ra,0xfffff
    8000368a:	584080e7          	jalr	1412(ra) # 80002c0a <kill>
}
    8000368e:	60e2                	ld	ra,24(sp)
    80003690:	6442                	ld	s0,16(sp)
    80003692:	6105                	addi	sp,sp,32
    80003694:	8082                	ret

0000000080003696 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003696:	1101                	addi	sp,sp,-32
    80003698:	ec06                	sd	ra,24(sp)
    8000369a:	e822                	sd	s0,16(sp)
    8000369c:	e426                	sd	s1,8(sp)
    8000369e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800036a0:	00014517          	auipc	a0,0x14
    800036a4:	3f850513          	addi	a0,a0,1016 # 80017a98 <tickslock>
    800036a8:	ffffd097          	auipc	ra,0xffffd
    800036ac:	544080e7          	jalr	1348(ra) # 80000bec <acquire>
  xticks = ticks;
    800036b0:	00006497          	auipc	s1,0x6
    800036b4:	9804a483          	lw	s1,-1664(s1) # 80009030 <ticks>
  release(&tickslock);
    800036b8:	00014517          	auipc	a0,0x14
    800036bc:	3e050513          	addi	a0,a0,992 # 80017a98 <tickslock>
    800036c0:	ffffd097          	auipc	ra,0xffffd
    800036c4:	5f8080e7          	jalr	1528(ra) # 80000cb8 <release>
  return xticks;
}
    800036c8:	02049513          	slli	a0,s1,0x20
    800036cc:	9101                	srli	a0,a0,0x20
    800036ce:	60e2                	ld	ra,24(sp)
    800036d0:	6442                	ld	s0,16(sp)
    800036d2:	64a2                	ld	s1,8(sp)
    800036d4:	6105                	addi	sp,sp,32
    800036d6:	8082                	ret

00000000800036d8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800036d8:	7179                	addi	sp,sp,-48
    800036da:	f406                	sd	ra,40(sp)
    800036dc:	f022                	sd	s0,32(sp)
    800036de:	ec26                	sd	s1,24(sp)
    800036e0:	e84a                	sd	s2,16(sp)
    800036e2:	e44e                	sd	s3,8(sp)
    800036e4:	e052                	sd	s4,0(sp)
    800036e6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800036e8:	00005597          	auipc	a1,0x5
    800036ec:	e5058593          	addi	a1,a1,-432 # 80008538 <syscalls+0xc0>
    800036f0:	00014517          	auipc	a0,0x14
    800036f4:	3c050513          	addi	a0,a0,960 # 80017ab0 <bcache>
    800036f8:	ffffd097          	auipc	ra,0xffffd
    800036fc:	45c080e7          	jalr	1116(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003700:	0001c797          	auipc	a5,0x1c
    80003704:	3b078793          	addi	a5,a5,944 # 8001fab0 <bcache+0x8000>
    80003708:	0001c717          	auipc	a4,0x1c
    8000370c:	61070713          	addi	a4,a4,1552 # 8001fd18 <bcache+0x8268>
    80003710:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003714:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003718:	00014497          	auipc	s1,0x14
    8000371c:	3b048493          	addi	s1,s1,944 # 80017ac8 <bcache+0x18>
    b->next = bcache.head.next;
    80003720:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003722:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003724:	00005a17          	auipc	s4,0x5
    80003728:	e1ca0a13          	addi	s4,s4,-484 # 80008540 <syscalls+0xc8>
    b->next = bcache.head.next;
    8000372c:	2b893783          	ld	a5,696(s2)
    80003730:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003732:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003736:	85d2                	mv	a1,s4
    80003738:	01048513          	addi	a0,s1,16
    8000373c:	00001097          	auipc	ra,0x1
    80003740:	4bc080e7          	jalr	1212(ra) # 80004bf8 <initsleeplock>
    bcache.head.next->prev = b;
    80003744:	2b893783          	ld	a5,696(s2)
    80003748:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000374a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000374e:	45848493          	addi	s1,s1,1112
    80003752:	fd349de3          	bne	s1,s3,8000372c <binit+0x54>
  }
}
    80003756:	70a2                	ld	ra,40(sp)
    80003758:	7402                	ld	s0,32(sp)
    8000375a:	64e2                	ld	s1,24(sp)
    8000375c:	6942                	ld	s2,16(sp)
    8000375e:	69a2                	ld	s3,8(sp)
    80003760:	6a02                	ld	s4,0(sp)
    80003762:	6145                	addi	sp,sp,48
    80003764:	8082                	ret

0000000080003766 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003766:	7179                	addi	sp,sp,-48
    80003768:	f406                	sd	ra,40(sp)
    8000376a:	f022                	sd	s0,32(sp)
    8000376c:	ec26                	sd	s1,24(sp)
    8000376e:	e84a                	sd	s2,16(sp)
    80003770:	e44e                	sd	s3,8(sp)
    80003772:	1800                	addi	s0,sp,48
    80003774:	89aa                	mv	s3,a0
    80003776:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003778:	00014517          	auipc	a0,0x14
    8000377c:	33850513          	addi	a0,a0,824 # 80017ab0 <bcache>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	46c080e7          	jalr	1132(ra) # 80000bec <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003788:	0001c497          	auipc	s1,0x1c
    8000378c:	5e04b483          	ld	s1,1504(s1) # 8001fd68 <bcache+0x82b8>
    80003790:	0001c797          	auipc	a5,0x1c
    80003794:	58878793          	addi	a5,a5,1416 # 8001fd18 <bcache+0x8268>
    80003798:	02f48f63          	beq	s1,a5,800037d6 <bread+0x70>
    8000379c:	873e                	mv	a4,a5
    8000379e:	a021                	j	800037a6 <bread+0x40>
    800037a0:	68a4                	ld	s1,80(s1)
    800037a2:	02e48a63          	beq	s1,a4,800037d6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800037a6:	449c                	lw	a5,8(s1)
    800037a8:	ff379ce3          	bne	a5,s3,800037a0 <bread+0x3a>
    800037ac:	44dc                	lw	a5,12(s1)
    800037ae:	ff2799e3          	bne	a5,s2,800037a0 <bread+0x3a>
      b->refcnt++;
    800037b2:	40bc                	lw	a5,64(s1)
    800037b4:	2785                	addiw	a5,a5,1
    800037b6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800037b8:	00014517          	auipc	a0,0x14
    800037bc:	2f850513          	addi	a0,a0,760 # 80017ab0 <bcache>
    800037c0:	ffffd097          	auipc	ra,0xffffd
    800037c4:	4f8080e7          	jalr	1272(ra) # 80000cb8 <release>
      acquiresleep(&b->lock);
    800037c8:	01048513          	addi	a0,s1,16
    800037cc:	00001097          	auipc	ra,0x1
    800037d0:	466080e7          	jalr	1126(ra) # 80004c32 <acquiresleep>
      return b;
    800037d4:	a8b9                	j	80003832 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800037d6:	0001c497          	auipc	s1,0x1c
    800037da:	58a4b483          	ld	s1,1418(s1) # 8001fd60 <bcache+0x82b0>
    800037de:	0001c797          	auipc	a5,0x1c
    800037e2:	53a78793          	addi	a5,a5,1338 # 8001fd18 <bcache+0x8268>
    800037e6:	00f48863          	beq	s1,a5,800037f6 <bread+0x90>
    800037ea:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800037ec:	40bc                	lw	a5,64(s1)
    800037ee:	cf81                	beqz	a5,80003806 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800037f0:	64a4                	ld	s1,72(s1)
    800037f2:	fee49de3          	bne	s1,a4,800037ec <bread+0x86>
  panic("bget: no buffers");
    800037f6:	00005517          	auipc	a0,0x5
    800037fa:	d5250513          	addi	a0,a0,-686 # 80008548 <syscalls+0xd0>
    800037fe:	ffffd097          	auipc	ra,0xffffd
    80003802:	d40080e7          	jalr	-704(ra) # 8000053e <panic>
      b->dev = dev;
    80003806:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000380a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000380e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003812:	4785                	li	a5,1
    80003814:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003816:	00014517          	auipc	a0,0x14
    8000381a:	29a50513          	addi	a0,a0,666 # 80017ab0 <bcache>
    8000381e:	ffffd097          	auipc	ra,0xffffd
    80003822:	49a080e7          	jalr	1178(ra) # 80000cb8 <release>
      acquiresleep(&b->lock);
    80003826:	01048513          	addi	a0,s1,16
    8000382a:	00001097          	auipc	ra,0x1
    8000382e:	408080e7          	jalr	1032(ra) # 80004c32 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003832:	409c                	lw	a5,0(s1)
    80003834:	cb89                	beqz	a5,80003846 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003836:	8526                	mv	a0,s1
    80003838:	70a2                	ld	ra,40(sp)
    8000383a:	7402                	ld	s0,32(sp)
    8000383c:	64e2                	ld	s1,24(sp)
    8000383e:	6942                	ld	s2,16(sp)
    80003840:	69a2                	ld	s3,8(sp)
    80003842:	6145                	addi	sp,sp,48
    80003844:	8082                	ret
    virtio_disk_rw(b, 0);
    80003846:	4581                	li	a1,0
    80003848:	8526                	mv	a0,s1
    8000384a:	00003097          	auipc	ra,0x3
    8000384e:	f0c080e7          	jalr	-244(ra) # 80006756 <virtio_disk_rw>
    b->valid = 1;
    80003852:	4785                	li	a5,1
    80003854:	c09c                	sw	a5,0(s1)
  return b;
    80003856:	b7c5                	j	80003836 <bread+0xd0>

0000000080003858 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003858:	1101                	addi	sp,sp,-32
    8000385a:	ec06                	sd	ra,24(sp)
    8000385c:	e822                	sd	s0,16(sp)
    8000385e:	e426                	sd	s1,8(sp)
    80003860:	1000                	addi	s0,sp,32
    80003862:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003864:	0541                	addi	a0,a0,16
    80003866:	00001097          	auipc	ra,0x1
    8000386a:	466080e7          	jalr	1126(ra) # 80004ccc <holdingsleep>
    8000386e:	cd01                	beqz	a0,80003886 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003870:	4585                	li	a1,1
    80003872:	8526                	mv	a0,s1
    80003874:	00003097          	auipc	ra,0x3
    80003878:	ee2080e7          	jalr	-286(ra) # 80006756 <virtio_disk_rw>
}
    8000387c:	60e2                	ld	ra,24(sp)
    8000387e:	6442                	ld	s0,16(sp)
    80003880:	64a2                	ld	s1,8(sp)
    80003882:	6105                	addi	sp,sp,32
    80003884:	8082                	ret
    panic("bwrite");
    80003886:	00005517          	auipc	a0,0x5
    8000388a:	cda50513          	addi	a0,a0,-806 # 80008560 <syscalls+0xe8>
    8000388e:	ffffd097          	auipc	ra,0xffffd
    80003892:	cb0080e7          	jalr	-848(ra) # 8000053e <panic>

0000000080003896 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003896:	1101                	addi	sp,sp,-32
    80003898:	ec06                	sd	ra,24(sp)
    8000389a:	e822                	sd	s0,16(sp)
    8000389c:	e426                	sd	s1,8(sp)
    8000389e:	e04a                	sd	s2,0(sp)
    800038a0:	1000                	addi	s0,sp,32
    800038a2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800038a4:	01050913          	addi	s2,a0,16
    800038a8:	854a                	mv	a0,s2
    800038aa:	00001097          	auipc	ra,0x1
    800038ae:	422080e7          	jalr	1058(ra) # 80004ccc <holdingsleep>
    800038b2:	c92d                	beqz	a0,80003924 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800038b4:	854a                	mv	a0,s2
    800038b6:	00001097          	auipc	ra,0x1
    800038ba:	3d2080e7          	jalr	978(ra) # 80004c88 <releasesleep>

  acquire(&bcache.lock);
    800038be:	00014517          	auipc	a0,0x14
    800038c2:	1f250513          	addi	a0,a0,498 # 80017ab0 <bcache>
    800038c6:	ffffd097          	auipc	ra,0xffffd
    800038ca:	326080e7          	jalr	806(ra) # 80000bec <acquire>
  b->refcnt--;
    800038ce:	40bc                	lw	a5,64(s1)
    800038d0:	37fd                	addiw	a5,a5,-1
    800038d2:	0007871b          	sext.w	a4,a5
    800038d6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800038d8:	eb05                	bnez	a4,80003908 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800038da:	68bc                	ld	a5,80(s1)
    800038dc:	64b8                	ld	a4,72(s1)
    800038de:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800038e0:	64bc                	ld	a5,72(s1)
    800038e2:	68b8                	ld	a4,80(s1)
    800038e4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800038e6:	0001c797          	auipc	a5,0x1c
    800038ea:	1ca78793          	addi	a5,a5,458 # 8001fab0 <bcache+0x8000>
    800038ee:	2b87b703          	ld	a4,696(a5)
    800038f2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800038f4:	0001c717          	auipc	a4,0x1c
    800038f8:	42470713          	addi	a4,a4,1060 # 8001fd18 <bcache+0x8268>
    800038fc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800038fe:	2b87b703          	ld	a4,696(a5)
    80003902:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003904:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003908:	00014517          	auipc	a0,0x14
    8000390c:	1a850513          	addi	a0,a0,424 # 80017ab0 <bcache>
    80003910:	ffffd097          	auipc	ra,0xffffd
    80003914:	3a8080e7          	jalr	936(ra) # 80000cb8 <release>
}
    80003918:	60e2                	ld	ra,24(sp)
    8000391a:	6442                	ld	s0,16(sp)
    8000391c:	64a2                	ld	s1,8(sp)
    8000391e:	6902                	ld	s2,0(sp)
    80003920:	6105                	addi	sp,sp,32
    80003922:	8082                	ret
    panic("brelse");
    80003924:	00005517          	auipc	a0,0x5
    80003928:	c4450513          	addi	a0,a0,-956 # 80008568 <syscalls+0xf0>
    8000392c:	ffffd097          	auipc	ra,0xffffd
    80003930:	c12080e7          	jalr	-1006(ra) # 8000053e <panic>

0000000080003934 <bpin>:

void
bpin(struct buf *b) {
    80003934:	1101                	addi	sp,sp,-32
    80003936:	ec06                	sd	ra,24(sp)
    80003938:	e822                	sd	s0,16(sp)
    8000393a:	e426                	sd	s1,8(sp)
    8000393c:	1000                	addi	s0,sp,32
    8000393e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003940:	00014517          	auipc	a0,0x14
    80003944:	17050513          	addi	a0,a0,368 # 80017ab0 <bcache>
    80003948:	ffffd097          	auipc	ra,0xffffd
    8000394c:	2a4080e7          	jalr	676(ra) # 80000bec <acquire>
  b->refcnt++;
    80003950:	40bc                	lw	a5,64(s1)
    80003952:	2785                	addiw	a5,a5,1
    80003954:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003956:	00014517          	auipc	a0,0x14
    8000395a:	15a50513          	addi	a0,a0,346 # 80017ab0 <bcache>
    8000395e:	ffffd097          	auipc	ra,0xffffd
    80003962:	35a080e7          	jalr	858(ra) # 80000cb8 <release>
}
    80003966:	60e2                	ld	ra,24(sp)
    80003968:	6442                	ld	s0,16(sp)
    8000396a:	64a2                	ld	s1,8(sp)
    8000396c:	6105                	addi	sp,sp,32
    8000396e:	8082                	ret

0000000080003970 <bunpin>:

void
bunpin(struct buf *b) {
    80003970:	1101                	addi	sp,sp,-32
    80003972:	ec06                	sd	ra,24(sp)
    80003974:	e822                	sd	s0,16(sp)
    80003976:	e426                	sd	s1,8(sp)
    80003978:	1000                	addi	s0,sp,32
    8000397a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000397c:	00014517          	auipc	a0,0x14
    80003980:	13450513          	addi	a0,a0,308 # 80017ab0 <bcache>
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	268080e7          	jalr	616(ra) # 80000bec <acquire>
  b->refcnt--;
    8000398c:	40bc                	lw	a5,64(s1)
    8000398e:	37fd                	addiw	a5,a5,-1
    80003990:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003992:	00014517          	auipc	a0,0x14
    80003996:	11e50513          	addi	a0,a0,286 # 80017ab0 <bcache>
    8000399a:	ffffd097          	auipc	ra,0xffffd
    8000399e:	31e080e7          	jalr	798(ra) # 80000cb8 <release>
}
    800039a2:	60e2                	ld	ra,24(sp)
    800039a4:	6442                	ld	s0,16(sp)
    800039a6:	64a2                	ld	s1,8(sp)
    800039a8:	6105                	addi	sp,sp,32
    800039aa:	8082                	ret

00000000800039ac <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800039ac:	1101                	addi	sp,sp,-32
    800039ae:	ec06                	sd	ra,24(sp)
    800039b0:	e822                	sd	s0,16(sp)
    800039b2:	e426                	sd	s1,8(sp)
    800039b4:	e04a                	sd	s2,0(sp)
    800039b6:	1000                	addi	s0,sp,32
    800039b8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800039ba:	00d5d59b          	srliw	a1,a1,0xd
    800039be:	0001c797          	auipc	a5,0x1c
    800039c2:	7ce7a783          	lw	a5,1998(a5) # 8002018c <sb+0x1c>
    800039c6:	9dbd                	addw	a1,a1,a5
    800039c8:	00000097          	auipc	ra,0x0
    800039cc:	d9e080e7          	jalr	-610(ra) # 80003766 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800039d0:	0074f713          	andi	a4,s1,7
    800039d4:	4785                	li	a5,1
    800039d6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800039da:	14ce                	slli	s1,s1,0x33
    800039dc:	90d9                	srli	s1,s1,0x36
    800039de:	00950733          	add	a4,a0,s1
    800039e2:	05874703          	lbu	a4,88(a4)
    800039e6:	00e7f6b3          	and	a3,a5,a4
    800039ea:	c69d                	beqz	a3,80003a18 <bfree+0x6c>
    800039ec:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800039ee:	94aa                	add	s1,s1,a0
    800039f0:	fff7c793          	not	a5,a5
    800039f4:	8ff9                	and	a5,a5,a4
    800039f6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800039fa:	00001097          	auipc	ra,0x1
    800039fe:	118080e7          	jalr	280(ra) # 80004b12 <log_write>
  brelse(bp);
    80003a02:	854a                	mv	a0,s2
    80003a04:	00000097          	auipc	ra,0x0
    80003a08:	e92080e7          	jalr	-366(ra) # 80003896 <brelse>
}
    80003a0c:	60e2                	ld	ra,24(sp)
    80003a0e:	6442                	ld	s0,16(sp)
    80003a10:	64a2                	ld	s1,8(sp)
    80003a12:	6902                	ld	s2,0(sp)
    80003a14:	6105                	addi	sp,sp,32
    80003a16:	8082                	ret
    panic("freeing free block");
    80003a18:	00005517          	auipc	a0,0x5
    80003a1c:	b5850513          	addi	a0,a0,-1192 # 80008570 <syscalls+0xf8>
    80003a20:	ffffd097          	auipc	ra,0xffffd
    80003a24:	b1e080e7          	jalr	-1250(ra) # 8000053e <panic>

0000000080003a28 <balloc>:
{
    80003a28:	711d                	addi	sp,sp,-96
    80003a2a:	ec86                	sd	ra,88(sp)
    80003a2c:	e8a2                	sd	s0,80(sp)
    80003a2e:	e4a6                	sd	s1,72(sp)
    80003a30:	e0ca                	sd	s2,64(sp)
    80003a32:	fc4e                	sd	s3,56(sp)
    80003a34:	f852                	sd	s4,48(sp)
    80003a36:	f456                	sd	s5,40(sp)
    80003a38:	f05a                	sd	s6,32(sp)
    80003a3a:	ec5e                	sd	s7,24(sp)
    80003a3c:	e862                	sd	s8,16(sp)
    80003a3e:	e466                	sd	s9,8(sp)
    80003a40:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003a42:	0001c797          	auipc	a5,0x1c
    80003a46:	7327a783          	lw	a5,1842(a5) # 80020174 <sb+0x4>
    80003a4a:	cbd1                	beqz	a5,80003ade <balloc+0xb6>
    80003a4c:	8baa                	mv	s7,a0
    80003a4e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003a50:	0001cb17          	auipc	s6,0x1c
    80003a54:	720b0b13          	addi	s6,s6,1824 # 80020170 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a58:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003a5a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a5c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003a5e:	6c89                	lui	s9,0x2
    80003a60:	a831                	j	80003a7c <balloc+0x54>
    brelse(bp);
    80003a62:	854a                	mv	a0,s2
    80003a64:	00000097          	auipc	ra,0x0
    80003a68:	e32080e7          	jalr	-462(ra) # 80003896 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003a6c:	015c87bb          	addw	a5,s9,s5
    80003a70:	00078a9b          	sext.w	s5,a5
    80003a74:	004b2703          	lw	a4,4(s6)
    80003a78:	06eaf363          	bgeu	s5,a4,80003ade <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003a7c:	41fad79b          	sraiw	a5,s5,0x1f
    80003a80:	0137d79b          	srliw	a5,a5,0x13
    80003a84:	015787bb          	addw	a5,a5,s5
    80003a88:	40d7d79b          	sraiw	a5,a5,0xd
    80003a8c:	01cb2583          	lw	a1,28(s6)
    80003a90:	9dbd                	addw	a1,a1,a5
    80003a92:	855e                	mv	a0,s7
    80003a94:	00000097          	auipc	ra,0x0
    80003a98:	cd2080e7          	jalr	-814(ra) # 80003766 <bread>
    80003a9c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a9e:	004b2503          	lw	a0,4(s6)
    80003aa2:	000a849b          	sext.w	s1,s5
    80003aa6:	8662                	mv	a2,s8
    80003aa8:	faa4fde3          	bgeu	s1,a0,80003a62 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003aac:	41f6579b          	sraiw	a5,a2,0x1f
    80003ab0:	01d7d69b          	srliw	a3,a5,0x1d
    80003ab4:	00c6873b          	addw	a4,a3,a2
    80003ab8:	00777793          	andi	a5,a4,7
    80003abc:	9f95                	subw	a5,a5,a3
    80003abe:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003ac2:	4037571b          	sraiw	a4,a4,0x3
    80003ac6:	00e906b3          	add	a3,s2,a4
    80003aca:	0586c683          	lbu	a3,88(a3)
    80003ace:	00d7f5b3          	and	a1,a5,a3
    80003ad2:	cd91                	beqz	a1,80003aee <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ad4:	2605                	addiw	a2,a2,1
    80003ad6:	2485                	addiw	s1,s1,1
    80003ad8:	fd4618e3          	bne	a2,s4,80003aa8 <balloc+0x80>
    80003adc:	b759                	j	80003a62 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003ade:	00005517          	auipc	a0,0x5
    80003ae2:	aaa50513          	addi	a0,a0,-1366 # 80008588 <syscalls+0x110>
    80003ae6:	ffffd097          	auipc	ra,0xffffd
    80003aea:	a58080e7          	jalr	-1448(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003aee:	974a                	add	a4,a4,s2
    80003af0:	8fd5                	or	a5,a5,a3
    80003af2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003af6:	854a                	mv	a0,s2
    80003af8:	00001097          	auipc	ra,0x1
    80003afc:	01a080e7          	jalr	26(ra) # 80004b12 <log_write>
        brelse(bp);
    80003b00:	854a                	mv	a0,s2
    80003b02:	00000097          	auipc	ra,0x0
    80003b06:	d94080e7          	jalr	-620(ra) # 80003896 <brelse>
  bp = bread(dev, bno);
    80003b0a:	85a6                	mv	a1,s1
    80003b0c:	855e                	mv	a0,s7
    80003b0e:	00000097          	auipc	ra,0x0
    80003b12:	c58080e7          	jalr	-936(ra) # 80003766 <bread>
    80003b16:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003b18:	40000613          	li	a2,1024
    80003b1c:	4581                	li	a1,0
    80003b1e:	05850513          	addi	a0,a0,88
    80003b22:	ffffd097          	auipc	ra,0xffffd
    80003b26:	1f0080e7          	jalr	496(ra) # 80000d12 <memset>
  log_write(bp);
    80003b2a:	854a                	mv	a0,s2
    80003b2c:	00001097          	auipc	ra,0x1
    80003b30:	fe6080e7          	jalr	-26(ra) # 80004b12 <log_write>
  brelse(bp);
    80003b34:	854a                	mv	a0,s2
    80003b36:	00000097          	auipc	ra,0x0
    80003b3a:	d60080e7          	jalr	-672(ra) # 80003896 <brelse>
}
    80003b3e:	8526                	mv	a0,s1
    80003b40:	60e6                	ld	ra,88(sp)
    80003b42:	6446                	ld	s0,80(sp)
    80003b44:	64a6                	ld	s1,72(sp)
    80003b46:	6906                	ld	s2,64(sp)
    80003b48:	79e2                	ld	s3,56(sp)
    80003b4a:	7a42                	ld	s4,48(sp)
    80003b4c:	7aa2                	ld	s5,40(sp)
    80003b4e:	7b02                	ld	s6,32(sp)
    80003b50:	6be2                	ld	s7,24(sp)
    80003b52:	6c42                	ld	s8,16(sp)
    80003b54:	6ca2                	ld	s9,8(sp)
    80003b56:	6125                	addi	sp,sp,96
    80003b58:	8082                	ret

0000000080003b5a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003b5a:	7179                	addi	sp,sp,-48
    80003b5c:	f406                	sd	ra,40(sp)
    80003b5e:	f022                	sd	s0,32(sp)
    80003b60:	ec26                	sd	s1,24(sp)
    80003b62:	e84a                	sd	s2,16(sp)
    80003b64:	e44e                	sd	s3,8(sp)
    80003b66:	e052                	sd	s4,0(sp)
    80003b68:	1800                	addi	s0,sp,48
    80003b6a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003b6c:	47ad                	li	a5,11
    80003b6e:	04b7fe63          	bgeu	a5,a1,80003bca <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003b72:	ff45849b          	addiw	s1,a1,-12
    80003b76:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003b7a:	0ff00793          	li	a5,255
    80003b7e:	0ae7e363          	bltu	a5,a4,80003c24 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003b82:	08052583          	lw	a1,128(a0)
    80003b86:	c5ad                	beqz	a1,80003bf0 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003b88:	00092503          	lw	a0,0(s2)
    80003b8c:	00000097          	auipc	ra,0x0
    80003b90:	bda080e7          	jalr	-1062(ra) # 80003766 <bread>
    80003b94:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003b96:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003b9a:	02049593          	slli	a1,s1,0x20
    80003b9e:	9181                	srli	a1,a1,0x20
    80003ba0:	058a                	slli	a1,a1,0x2
    80003ba2:	00b784b3          	add	s1,a5,a1
    80003ba6:	0004a983          	lw	s3,0(s1)
    80003baa:	04098d63          	beqz	s3,80003c04 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003bae:	8552                	mv	a0,s4
    80003bb0:	00000097          	auipc	ra,0x0
    80003bb4:	ce6080e7          	jalr	-794(ra) # 80003896 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003bb8:	854e                	mv	a0,s3
    80003bba:	70a2                	ld	ra,40(sp)
    80003bbc:	7402                	ld	s0,32(sp)
    80003bbe:	64e2                	ld	s1,24(sp)
    80003bc0:	6942                	ld	s2,16(sp)
    80003bc2:	69a2                	ld	s3,8(sp)
    80003bc4:	6a02                	ld	s4,0(sp)
    80003bc6:	6145                	addi	sp,sp,48
    80003bc8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003bca:	02059493          	slli	s1,a1,0x20
    80003bce:	9081                	srli	s1,s1,0x20
    80003bd0:	048a                	slli	s1,s1,0x2
    80003bd2:	94aa                	add	s1,s1,a0
    80003bd4:	0504a983          	lw	s3,80(s1)
    80003bd8:	fe0990e3          	bnez	s3,80003bb8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003bdc:	4108                	lw	a0,0(a0)
    80003bde:	00000097          	auipc	ra,0x0
    80003be2:	e4a080e7          	jalr	-438(ra) # 80003a28 <balloc>
    80003be6:	0005099b          	sext.w	s3,a0
    80003bea:	0534a823          	sw	s3,80(s1)
    80003bee:	b7e9                	j	80003bb8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003bf0:	4108                	lw	a0,0(a0)
    80003bf2:	00000097          	auipc	ra,0x0
    80003bf6:	e36080e7          	jalr	-458(ra) # 80003a28 <balloc>
    80003bfa:	0005059b          	sext.w	a1,a0
    80003bfe:	08b92023          	sw	a1,128(s2)
    80003c02:	b759                	j	80003b88 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003c04:	00092503          	lw	a0,0(s2)
    80003c08:	00000097          	auipc	ra,0x0
    80003c0c:	e20080e7          	jalr	-480(ra) # 80003a28 <balloc>
    80003c10:	0005099b          	sext.w	s3,a0
    80003c14:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003c18:	8552                	mv	a0,s4
    80003c1a:	00001097          	auipc	ra,0x1
    80003c1e:	ef8080e7          	jalr	-264(ra) # 80004b12 <log_write>
    80003c22:	b771                	j	80003bae <bmap+0x54>
  panic("bmap: out of range");
    80003c24:	00005517          	auipc	a0,0x5
    80003c28:	97c50513          	addi	a0,a0,-1668 # 800085a0 <syscalls+0x128>
    80003c2c:	ffffd097          	auipc	ra,0xffffd
    80003c30:	912080e7          	jalr	-1774(ra) # 8000053e <panic>

0000000080003c34 <iget>:
{
    80003c34:	7179                	addi	sp,sp,-48
    80003c36:	f406                	sd	ra,40(sp)
    80003c38:	f022                	sd	s0,32(sp)
    80003c3a:	ec26                	sd	s1,24(sp)
    80003c3c:	e84a                	sd	s2,16(sp)
    80003c3e:	e44e                	sd	s3,8(sp)
    80003c40:	e052                	sd	s4,0(sp)
    80003c42:	1800                	addi	s0,sp,48
    80003c44:	89aa                	mv	s3,a0
    80003c46:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003c48:	0001c517          	auipc	a0,0x1c
    80003c4c:	54850513          	addi	a0,a0,1352 # 80020190 <itable>
    80003c50:	ffffd097          	auipc	ra,0xffffd
    80003c54:	f9c080e7          	jalr	-100(ra) # 80000bec <acquire>
  empty = 0;
    80003c58:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c5a:	0001c497          	auipc	s1,0x1c
    80003c5e:	54e48493          	addi	s1,s1,1358 # 800201a8 <itable+0x18>
    80003c62:	0001e697          	auipc	a3,0x1e
    80003c66:	fd668693          	addi	a3,a3,-42 # 80021c38 <log>
    80003c6a:	a039                	j	80003c78 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c6c:	02090b63          	beqz	s2,80003ca2 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c70:	08848493          	addi	s1,s1,136
    80003c74:	02d48a63          	beq	s1,a3,80003ca8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003c78:	449c                	lw	a5,8(s1)
    80003c7a:	fef059e3          	blez	a5,80003c6c <iget+0x38>
    80003c7e:	4098                	lw	a4,0(s1)
    80003c80:	ff3716e3          	bne	a4,s3,80003c6c <iget+0x38>
    80003c84:	40d8                	lw	a4,4(s1)
    80003c86:	ff4713e3          	bne	a4,s4,80003c6c <iget+0x38>
      ip->ref++;
    80003c8a:	2785                	addiw	a5,a5,1
    80003c8c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003c8e:	0001c517          	auipc	a0,0x1c
    80003c92:	50250513          	addi	a0,a0,1282 # 80020190 <itable>
    80003c96:	ffffd097          	auipc	ra,0xffffd
    80003c9a:	022080e7          	jalr	34(ra) # 80000cb8 <release>
      return ip;
    80003c9e:	8926                	mv	s2,s1
    80003ca0:	a03d                	j	80003cce <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ca2:	f7f9                	bnez	a5,80003c70 <iget+0x3c>
    80003ca4:	8926                	mv	s2,s1
    80003ca6:	b7e9                	j	80003c70 <iget+0x3c>
  if(empty == 0)
    80003ca8:	02090c63          	beqz	s2,80003ce0 <iget+0xac>
  ip->dev = dev;
    80003cac:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003cb0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003cb4:	4785                	li	a5,1
    80003cb6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003cba:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003cbe:	0001c517          	auipc	a0,0x1c
    80003cc2:	4d250513          	addi	a0,a0,1234 # 80020190 <itable>
    80003cc6:	ffffd097          	auipc	ra,0xffffd
    80003cca:	ff2080e7          	jalr	-14(ra) # 80000cb8 <release>
}
    80003cce:	854a                	mv	a0,s2
    80003cd0:	70a2                	ld	ra,40(sp)
    80003cd2:	7402                	ld	s0,32(sp)
    80003cd4:	64e2                	ld	s1,24(sp)
    80003cd6:	6942                	ld	s2,16(sp)
    80003cd8:	69a2                	ld	s3,8(sp)
    80003cda:	6a02                	ld	s4,0(sp)
    80003cdc:	6145                	addi	sp,sp,48
    80003cde:	8082                	ret
    panic("iget: no inodes");
    80003ce0:	00005517          	auipc	a0,0x5
    80003ce4:	8d850513          	addi	a0,a0,-1832 # 800085b8 <syscalls+0x140>
    80003ce8:	ffffd097          	auipc	ra,0xffffd
    80003cec:	856080e7          	jalr	-1962(ra) # 8000053e <panic>

0000000080003cf0 <fsinit>:
fsinit(int dev) {
    80003cf0:	7179                	addi	sp,sp,-48
    80003cf2:	f406                	sd	ra,40(sp)
    80003cf4:	f022                	sd	s0,32(sp)
    80003cf6:	ec26                	sd	s1,24(sp)
    80003cf8:	e84a                	sd	s2,16(sp)
    80003cfa:	e44e                	sd	s3,8(sp)
    80003cfc:	1800                	addi	s0,sp,48
    80003cfe:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003d00:	4585                	li	a1,1
    80003d02:	00000097          	auipc	ra,0x0
    80003d06:	a64080e7          	jalr	-1436(ra) # 80003766 <bread>
    80003d0a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003d0c:	0001c997          	auipc	s3,0x1c
    80003d10:	46498993          	addi	s3,s3,1124 # 80020170 <sb>
    80003d14:	02000613          	li	a2,32
    80003d18:	05850593          	addi	a1,a0,88
    80003d1c:	854e                	mv	a0,s3
    80003d1e:	ffffd097          	auipc	ra,0xffffd
    80003d22:	054080e7          	jalr	84(ra) # 80000d72 <memmove>
  brelse(bp);
    80003d26:	8526                	mv	a0,s1
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	b6e080e7          	jalr	-1170(ra) # 80003896 <brelse>
  if(sb.magic != FSMAGIC)
    80003d30:	0009a703          	lw	a4,0(s3)
    80003d34:	102037b7          	lui	a5,0x10203
    80003d38:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003d3c:	02f71263          	bne	a4,a5,80003d60 <fsinit+0x70>
  initlog(dev, &sb);
    80003d40:	0001c597          	auipc	a1,0x1c
    80003d44:	43058593          	addi	a1,a1,1072 # 80020170 <sb>
    80003d48:	854a                	mv	a0,s2
    80003d4a:	00001097          	auipc	ra,0x1
    80003d4e:	b4c080e7          	jalr	-1204(ra) # 80004896 <initlog>
}
    80003d52:	70a2                	ld	ra,40(sp)
    80003d54:	7402                	ld	s0,32(sp)
    80003d56:	64e2                	ld	s1,24(sp)
    80003d58:	6942                	ld	s2,16(sp)
    80003d5a:	69a2                	ld	s3,8(sp)
    80003d5c:	6145                	addi	sp,sp,48
    80003d5e:	8082                	ret
    panic("invalid file system");
    80003d60:	00005517          	auipc	a0,0x5
    80003d64:	86850513          	addi	a0,a0,-1944 # 800085c8 <syscalls+0x150>
    80003d68:	ffffc097          	auipc	ra,0xffffc
    80003d6c:	7d6080e7          	jalr	2006(ra) # 8000053e <panic>

0000000080003d70 <iinit>:
{
    80003d70:	7179                	addi	sp,sp,-48
    80003d72:	f406                	sd	ra,40(sp)
    80003d74:	f022                	sd	s0,32(sp)
    80003d76:	ec26                	sd	s1,24(sp)
    80003d78:	e84a                	sd	s2,16(sp)
    80003d7a:	e44e                	sd	s3,8(sp)
    80003d7c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003d7e:	00005597          	auipc	a1,0x5
    80003d82:	86258593          	addi	a1,a1,-1950 # 800085e0 <syscalls+0x168>
    80003d86:	0001c517          	auipc	a0,0x1c
    80003d8a:	40a50513          	addi	a0,a0,1034 # 80020190 <itable>
    80003d8e:	ffffd097          	auipc	ra,0xffffd
    80003d92:	dc6080e7          	jalr	-570(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003d96:	0001c497          	auipc	s1,0x1c
    80003d9a:	42248493          	addi	s1,s1,1058 # 800201b8 <itable+0x28>
    80003d9e:	0001e997          	auipc	s3,0x1e
    80003da2:	eaa98993          	addi	s3,s3,-342 # 80021c48 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003da6:	00005917          	auipc	s2,0x5
    80003daa:	84290913          	addi	s2,s2,-1982 # 800085e8 <syscalls+0x170>
    80003dae:	85ca                	mv	a1,s2
    80003db0:	8526                	mv	a0,s1
    80003db2:	00001097          	auipc	ra,0x1
    80003db6:	e46080e7          	jalr	-442(ra) # 80004bf8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003dba:	08848493          	addi	s1,s1,136
    80003dbe:	ff3498e3          	bne	s1,s3,80003dae <iinit+0x3e>
}
    80003dc2:	70a2                	ld	ra,40(sp)
    80003dc4:	7402                	ld	s0,32(sp)
    80003dc6:	64e2                	ld	s1,24(sp)
    80003dc8:	6942                	ld	s2,16(sp)
    80003dca:	69a2                	ld	s3,8(sp)
    80003dcc:	6145                	addi	sp,sp,48
    80003dce:	8082                	ret

0000000080003dd0 <ialloc>:
{
    80003dd0:	715d                	addi	sp,sp,-80
    80003dd2:	e486                	sd	ra,72(sp)
    80003dd4:	e0a2                	sd	s0,64(sp)
    80003dd6:	fc26                	sd	s1,56(sp)
    80003dd8:	f84a                	sd	s2,48(sp)
    80003dda:	f44e                	sd	s3,40(sp)
    80003ddc:	f052                	sd	s4,32(sp)
    80003dde:	ec56                	sd	s5,24(sp)
    80003de0:	e85a                	sd	s6,16(sp)
    80003de2:	e45e                	sd	s7,8(sp)
    80003de4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003de6:	0001c717          	auipc	a4,0x1c
    80003dea:	39672703          	lw	a4,918(a4) # 8002017c <sb+0xc>
    80003dee:	4785                	li	a5,1
    80003df0:	04e7fa63          	bgeu	a5,a4,80003e44 <ialloc+0x74>
    80003df4:	8aaa                	mv	s5,a0
    80003df6:	8bae                	mv	s7,a1
    80003df8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003dfa:	0001ca17          	auipc	s4,0x1c
    80003dfe:	376a0a13          	addi	s4,s4,886 # 80020170 <sb>
    80003e02:	00048b1b          	sext.w	s6,s1
    80003e06:	0044d593          	srli	a1,s1,0x4
    80003e0a:	018a2783          	lw	a5,24(s4)
    80003e0e:	9dbd                	addw	a1,a1,a5
    80003e10:	8556                	mv	a0,s5
    80003e12:	00000097          	auipc	ra,0x0
    80003e16:	954080e7          	jalr	-1708(ra) # 80003766 <bread>
    80003e1a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003e1c:	05850993          	addi	s3,a0,88
    80003e20:	00f4f793          	andi	a5,s1,15
    80003e24:	079a                	slli	a5,a5,0x6
    80003e26:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003e28:	00099783          	lh	a5,0(s3)
    80003e2c:	c785                	beqz	a5,80003e54 <ialloc+0x84>
    brelse(bp);
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	a68080e7          	jalr	-1432(ra) # 80003896 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e36:	0485                	addi	s1,s1,1
    80003e38:	00ca2703          	lw	a4,12(s4)
    80003e3c:	0004879b          	sext.w	a5,s1
    80003e40:	fce7e1e3          	bltu	a5,a4,80003e02 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003e44:	00004517          	auipc	a0,0x4
    80003e48:	7ac50513          	addi	a0,a0,1964 # 800085f0 <syscalls+0x178>
    80003e4c:	ffffc097          	auipc	ra,0xffffc
    80003e50:	6f2080e7          	jalr	1778(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003e54:	04000613          	li	a2,64
    80003e58:	4581                	li	a1,0
    80003e5a:	854e                	mv	a0,s3
    80003e5c:	ffffd097          	auipc	ra,0xffffd
    80003e60:	eb6080e7          	jalr	-330(ra) # 80000d12 <memset>
      dip->type = type;
    80003e64:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003e68:	854a                	mv	a0,s2
    80003e6a:	00001097          	auipc	ra,0x1
    80003e6e:	ca8080e7          	jalr	-856(ra) # 80004b12 <log_write>
      brelse(bp);
    80003e72:	854a                	mv	a0,s2
    80003e74:	00000097          	auipc	ra,0x0
    80003e78:	a22080e7          	jalr	-1502(ra) # 80003896 <brelse>
      return iget(dev, inum);
    80003e7c:	85da                	mv	a1,s6
    80003e7e:	8556                	mv	a0,s5
    80003e80:	00000097          	auipc	ra,0x0
    80003e84:	db4080e7          	jalr	-588(ra) # 80003c34 <iget>
}
    80003e88:	60a6                	ld	ra,72(sp)
    80003e8a:	6406                	ld	s0,64(sp)
    80003e8c:	74e2                	ld	s1,56(sp)
    80003e8e:	7942                	ld	s2,48(sp)
    80003e90:	79a2                	ld	s3,40(sp)
    80003e92:	7a02                	ld	s4,32(sp)
    80003e94:	6ae2                	ld	s5,24(sp)
    80003e96:	6b42                	ld	s6,16(sp)
    80003e98:	6ba2                	ld	s7,8(sp)
    80003e9a:	6161                	addi	sp,sp,80
    80003e9c:	8082                	ret

0000000080003e9e <iupdate>:
{
    80003e9e:	1101                	addi	sp,sp,-32
    80003ea0:	ec06                	sd	ra,24(sp)
    80003ea2:	e822                	sd	s0,16(sp)
    80003ea4:	e426                	sd	s1,8(sp)
    80003ea6:	e04a                	sd	s2,0(sp)
    80003ea8:	1000                	addi	s0,sp,32
    80003eaa:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003eac:	415c                	lw	a5,4(a0)
    80003eae:	0047d79b          	srliw	a5,a5,0x4
    80003eb2:	0001c597          	auipc	a1,0x1c
    80003eb6:	2d65a583          	lw	a1,726(a1) # 80020188 <sb+0x18>
    80003eba:	9dbd                	addw	a1,a1,a5
    80003ebc:	4108                	lw	a0,0(a0)
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	8a8080e7          	jalr	-1880(ra) # 80003766 <bread>
    80003ec6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ec8:	05850793          	addi	a5,a0,88
    80003ecc:	40c8                	lw	a0,4(s1)
    80003ece:	893d                	andi	a0,a0,15
    80003ed0:	051a                	slli	a0,a0,0x6
    80003ed2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003ed4:	04449703          	lh	a4,68(s1)
    80003ed8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003edc:	04649703          	lh	a4,70(s1)
    80003ee0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003ee4:	04849703          	lh	a4,72(s1)
    80003ee8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003eec:	04a49703          	lh	a4,74(s1)
    80003ef0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003ef4:	44f8                	lw	a4,76(s1)
    80003ef6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003ef8:	03400613          	li	a2,52
    80003efc:	05048593          	addi	a1,s1,80
    80003f00:	0531                	addi	a0,a0,12
    80003f02:	ffffd097          	auipc	ra,0xffffd
    80003f06:	e70080e7          	jalr	-400(ra) # 80000d72 <memmove>
  log_write(bp);
    80003f0a:	854a                	mv	a0,s2
    80003f0c:	00001097          	auipc	ra,0x1
    80003f10:	c06080e7          	jalr	-1018(ra) # 80004b12 <log_write>
  brelse(bp);
    80003f14:	854a                	mv	a0,s2
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	980080e7          	jalr	-1664(ra) # 80003896 <brelse>
}
    80003f1e:	60e2                	ld	ra,24(sp)
    80003f20:	6442                	ld	s0,16(sp)
    80003f22:	64a2                	ld	s1,8(sp)
    80003f24:	6902                	ld	s2,0(sp)
    80003f26:	6105                	addi	sp,sp,32
    80003f28:	8082                	ret

0000000080003f2a <idup>:
{
    80003f2a:	1101                	addi	sp,sp,-32
    80003f2c:	ec06                	sd	ra,24(sp)
    80003f2e:	e822                	sd	s0,16(sp)
    80003f30:	e426                	sd	s1,8(sp)
    80003f32:	1000                	addi	s0,sp,32
    80003f34:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f36:	0001c517          	auipc	a0,0x1c
    80003f3a:	25a50513          	addi	a0,a0,602 # 80020190 <itable>
    80003f3e:	ffffd097          	auipc	ra,0xffffd
    80003f42:	cae080e7          	jalr	-850(ra) # 80000bec <acquire>
  ip->ref++;
    80003f46:	449c                	lw	a5,8(s1)
    80003f48:	2785                	addiw	a5,a5,1
    80003f4a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f4c:	0001c517          	auipc	a0,0x1c
    80003f50:	24450513          	addi	a0,a0,580 # 80020190 <itable>
    80003f54:	ffffd097          	auipc	ra,0xffffd
    80003f58:	d64080e7          	jalr	-668(ra) # 80000cb8 <release>
}
    80003f5c:	8526                	mv	a0,s1
    80003f5e:	60e2                	ld	ra,24(sp)
    80003f60:	6442                	ld	s0,16(sp)
    80003f62:	64a2                	ld	s1,8(sp)
    80003f64:	6105                	addi	sp,sp,32
    80003f66:	8082                	ret

0000000080003f68 <ilock>:
{
    80003f68:	1101                	addi	sp,sp,-32
    80003f6a:	ec06                	sd	ra,24(sp)
    80003f6c:	e822                	sd	s0,16(sp)
    80003f6e:	e426                	sd	s1,8(sp)
    80003f70:	e04a                	sd	s2,0(sp)
    80003f72:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003f74:	c115                	beqz	a0,80003f98 <ilock+0x30>
    80003f76:	84aa                	mv	s1,a0
    80003f78:	451c                	lw	a5,8(a0)
    80003f7a:	00f05f63          	blez	a5,80003f98 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003f7e:	0541                	addi	a0,a0,16
    80003f80:	00001097          	auipc	ra,0x1
    80003f84:	cb2080e7          	jalr	-846(ra) # 80004c32 <acquiresleep>
  if(ip->valid == 0){
    80003f88:	40bc                	lw	a5,64(s1)
    80003f8a:	cf99                	beqz	a5,80003fa8 <ilock+0x40>
}
    80003f8c:	60e2                	ld	ra,24(sp)
    80003f8e:	6442                	ld	s0,16(sp)
    80003f90:	64a2                	ld	s1,8(sp)
    80003f92:	6902                	ld	s2,0(sp)
    80003f94:	6105                	addi	sp,sp,32
    80003f96:	8082                	ret
    panic("ilock");
    80003f98:	00004517          	auipc	a0,0x4
    80003f9c:	67050513          	addi	a0,a0,1648 # 80008608 <syscalls+0x190>
    80003fa0:	ffffc097          	auipc	ra,0xffffc
    80003fa4:	59e080e7          	jalr	1438(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003fa8:	40dc                	lw	a5,4(s1)
    80003faa:	0047d79b          	srliw	a5,a5,0x4
    80003fae:	0001c597          	auipc	a1,0x1c
    80003fb2:	1da5a583          	lw	a1,474(a1) # 80020188 <sb+0x18>
    80003fb6:	9dbd                	addw	a1,a1,a5
    80003fb8:	4088                	lw	a0,0(s1)
    80003fba:	fffff097          	auipc	ra,0xfffff
    80003fbe:	7ac080e7          	jalr	1964(ra) # 80003766 <bread>
    80003fc2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003fc4:	05850593          	addi	a1,a0,88
    80003fc8:	40dc                	lw	a5,4(s1)
    80003fca:	8bbd                	andi	a5,a5,15
    80003fcc:	079a                	slli	a5,a5,0x6
    80003fce:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003fd0:	00059783          	lh	a5,0(a1)
    80003fd4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003fd8:	00259783          	lh	a5,2(a1)
    80003fdc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003fe0:	00459783          	lh	a5,4(a1)
    80003fe4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003fe8:	00659783          	lh	a5,6(a1)
    80003fec:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ff0:	459c                	lw	a5,8(a1)
    80003ff2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ff4:	03400613          	li	a2,52
    80003ff8:	05b1                	addi	a1,a1,12
    80003ffa:	05048513          	addi	a0,s1,80
    80003ffe:	ffffd097          	auipc	ra,0xffffd
    80004002:	d74080e7          	jalr	-652(ra) # 80000d72 <memmove>
    brelse(bp);
    80004006:	854a                	mv	a0,s2
    80004008:	00000097          	auipc	ra,0x0
    8000400c:	88e080e7          	jalr	-1906(ra) # 80003896 <brelse>
    ip->valid = 1;
    80004010:	4785                	li	a5,1
    80004012:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004014:	04449783          	lh	a5,68(s1)
    80004018:	fbb5                	bnez	a5,80003f8c <ilock+0x24>
      panic("ilock: no type");
    8000401a:	00004517          	auipc	a0,0x4
    8000401e:	5f650513          	addi	a0,a0,1526 # 80008610 <syscalls+0x198>
    80004022:	ffffc097          	auipc	ra,0xffffc
    80004026:	51c080e7          	jalr	1308(ra) # 8000053e <panic>

000000008000402a <iunlock>:
{
    8000402a:	1101                	addi	sp,sp,-32
    8000402c:	ec06                	sd	ra,24(sp)
    8000402e:	e822                	sd	s0,16(sp)
    80004030:	e426                	sd	s1,8(sp)
    80004032:	e04a                	sd	s2,0(sp)
    80004034:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004036:	c905                	beqz	a0,80004066 <iunlock+0x3c>
    80004038:	84aa                	mv	s1,a0
    8000403a:	01050913          	addi	s2,a0,16
    8000403e:	854a                	mv	a0,s2
    80004040:	00001097          	auipc	ra,0x1
    80004044:	c8c080e7          	jalr	-884(ra) # 80004ccc <holdingsleep>
    80004048:	cd19                	beqz	a0,80004066 <iunlock+0x3c>
    8000404a:	449c                	lw	a5,8(s1)
    8000404c:	00f05d63          	blez	a5,80004066 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004050:	854a                	mv	a0,s2
    80004052:	00001097          	auipc	ra,0x1
    80004056:	c36080e7          	jalr	-970(ra) # 80004c88 <releasesleep>
}
    8000405a:	60e2                	ld	ra,24(sp)
    8000405c:	6442                	ld	s0,16(sp)
    8000405e:	64a2                	ld	s1,8(sp)
    80004060:	6902                	ld	s2,0(sp)
    80004062:	6105                	addi	sp,sp,32
    80004064:	8082                	ret
    panic("iunlock");
    80004066:	00004517          	auipc	a0,0x4
    8000406a:	5ba50513          	addi	a0,a0,1466 # 80008620 <syscalls+0x1a8>
    8000406e:	ffffc097          	auipc	ra,0xffffc
    80004072:	4d0080e7          	jalr	1232(ra) # 8000053e <panic>

0000000080004076 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004076:	7179                	addi	sp,sp,-48
    80004078:	f406                	sd	ra,40(sp)
    8000407a:	f022                	sd	s0,32(sp)
    8000407c:	ec26                	sd	s1,24(sp)
    8000407e:	e84a                	sd	s2,16(sp)
    80004080:	e44e                	sd	s3,8(sp)
    80004082:	e052                	sd	s4,0(sp)
    80004084:	1800                	addi	s0,sp,48
    80004086:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004088:	05050493          	addi	s1,a0,80
    8000408c:	08050913          	addi	s2,a0,128
    80004090:	a021                	j	80004098 <itrunc+0x22>
    80004092:	0491                	addi	s1,s1,4
    80004094:	01248d63          	beq	s1,s2,800040ae <itrunc+0x38>
    if(ip->addrs[i]){
    80004098:	408c                	lw	a1,0(s1)
    8000409a:	dde5                	beqz	a1,80004092 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000409c:	0009a503          	lw	a0,0(s3)
    800040a0:	00000097          	auipc	ra,0x0
    800040a4:	90c080e7          	jalr	-1780(ra) # 800039ac <bfree>
      ip->addrs[i] = 0;
    800040a8:	0004a023          	sw	zero,0(s1)
    800040ac:	b7dd                	j	80004092 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800040ae:	0809a583          	lw	a1,128(s3)
    800040b2:	e185                	bnez	a1,800040d2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800040b4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800040b8:	854e                	mv	a0,s3
    800040ba:	00000097          	auipc	ra,0x0
    800040be:	de4080e7          	jalr	-540(ra) # 80003e9e <iupdate>
}
    800040c2:	70a2                	ld	ra,40(sp)
    800040c4:	7402                	ld	s0,32(sp)
    800040c6:	64e2                	ld	s1,24(sp)
    800040c8:	6942                	ld	s2,16(sp)
    800040ca:	69a2                	ld	s3,8(sp)
    800040cc:	6a02                	ld	s4,0(sp)
    800040ce:	6145                	addi	sp,sp,48
    800040d0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800040d2:	0009a503          	lw	a0,0(s3)
    800040d6:	fffff097          	auipc	ra,0xfffff
    800040da:	690080e7          	jalr	1680(ra) # 80003766 <bread>
    800040de:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800040e0:	05850493          	addi	s1,a0,88
    800040e4:	45850913          	addi	s2,a0,1112
    800040e8:	a811                	j	800040fc <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800040ea:	0009a503          	lw	a0,0(s3)
    800040ee:	00000097          	auipc	ra,0x0
    800040f2:	8be080e7          	jalr	-1858(ra) # 800039ac <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800040f6:	0491                	addi	s1,s1,4
    800040f8:	01248563          	beq	s1,s2,80004102 <itrunc+0x8c>
      if(a[j])
    800040fc:	408c                	lw	a1,0(s1)
    800040fe:	dde5                	beqz	a1,800040f6 <itrunc+0x80>
    80004100:	b7ed                	j	800040ea <itrunc+0x74>
    brelse(bp);
    80004102:	8552                	mv	a0,s4
    80004104:	fffff097          	auipc	ra,0xfffff
    80004108:	792080e7          	jalr	1938(ra) # 80003896 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000410c:	0809a583          	lw	a1,128(s3)
    80004110:	0009a503          	lw	a0,0(s3)
    80004114:	00000097          	auipc	ra,0x0
    80004118:	898080e7          	jalr	-1896(ra) # 800039ac <bfree>
    ip->addrs[NDIRECT] = 0;
    8000411c:	0809a023          	sw	zero,128(s3)
    80004120:	bf51                	j	800040b4 <itrunc+0x3e>

0000000080004122 <iput>:
{
    80004122:	1101                	addi	sp,sp,-32
    80004124:	ec06                	sd	ra,24(sp)
    80004126:	e822                	sd	s0,16(sp)
    80004128:	e426                	sd	s1,8(sp)
    8000412a:	e04a                	sd	s2,0(sp)
    8000412c:	1000                	addi	s0,sp,32
    8000412e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004130:	0001c517          	auipc	a0,0x1c
    80004134:	06050513          	addi	a0,a0,96 # 80020190 <itable>
    80004138:	ffffd097          	auipc	ra,0xffffd
    8000413c:	ab4080e7          	jalr	-1356(ra) # 80000bec <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004140:	4498                	lw	a4,8(s1)
    80004142:	4785                	li	a5,1
    80004144:	02f70363          	beq	a4,a5,8000416a <iput+0x48>
  ip->ref--;
    80004148:	449c                	lw	a5,8(s1)
    8000414a:	37fd                	addiw	a5,a5,-1
    8000414c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000414e:	0001c517          	auipc	a0,0x1c
    80004152:	04250513          	addi	a0,a0,66 # 80020190 <itable>
    80004156:	ffffd097          	auipc	ra,0xffffd
    8000415a:	b62080e7          	jalr	-1182(ra) # 80000cb8 <release>
}
    8000415e:	60e2                	ld	ra,24(sp)
    80004160:	6442                	ld	s0,16(sp)
    80004162:	64a2                	ld	s1,8(sp)
    80004164:	6902                	ld	s2,0(sp)
    80004166:	6105                	addi	sp,sp,32
    80004168:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000416a:	40bc                	lw	a5,64(s1)
    8000416c:	dff1                	beqz	a5,80004148 <iput+0x26>
    8000416e:	04a49783          	lh	a5,74(s1)
    80004172:	fbf9                	bnez	a5,80004148 <iput+0x26>
    acquiresleep(&ip->lock);
    80004174:	01048913          	addi	s2,s1,16
    80004178:	854a                	mv	a0,s2
    8000417a:	00001097          	auipc	ra,0x1
    8000417e:	ab8080e7          	jalr	-1352(ra) # 80004c32 <acquiresleep>
    release(&itable.lock);
    80004182:	0001c517          	auipc	a0,0x1c
    80004186:	00e50513          	addi	a0,a0,14 # 80020190 <itable>
    8000418a:	ffffd097          	auipc	ra,0xffffd
    8000418e:	b2e080e7          	jalr	-1234(ra) # 80000cb8 <release>
    itrunc(ip);
    80004192:	8526                	mv	a0,s1
    80004194:	00000097          	auipc	ra,0x0
    80004198:	ee2080e7          	jalr	-286(ra) # 80004076 <itrunc>
    ip->type = 0;
    8000419c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800041a0:	8526                	mv	a0,s1
    800041a2:	00000097          	auipc	ra,0x0
    800041a6:	cfc080e7          	jalr	-772(ra) # 80003e9e <iupdate>
    ip->valid = 0;
    800041aa:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800041ae:	854a                	mv	a0,s2
    800041b0:	00001097          	auipc	ra,0x1
    800041b4:	ad8080e7          	jalr	-1320(ra) # 80004c88 <releasesleep>
    acquire(&itable.lock);
    800041b8:	0001c517          	auipc	a0,0x1c
    800041bc:	fd850513          	addi	a0,a0,-40 # 80020190 <itable>
    800041c0:	ffffd097          	auipc	ra,0xffffd
    800041c4:	a2c080e7          	jalr	-1492(ra) # 80000bec <acquire>
    800041c8:	b741                	j	80004148 <iput+0x26>

00000000800041ca <iunlockput>:
{
    800041ca:	1101                	addi	sp,sp,-32
    800041cc:	ec06                	sd	ra,24(sp)
    800041ce:	e822                	sd	s0,16(sp)
    800041d0:	e426                	sd	s1,8(sp)
    800041d2:	1000                	addi	s0,sp,32
    800041d4:	84aa                	mv	s1,a0
  iunlock(ip);
    800041d6:	00000097          	auipc	ra,0x0
    800041da:	e54080e7          	jalr	-428(ra) # 8000402a <iunlock>
  iput(ip);
    800041de:	8526                	mv	a0,s1
    800041e0:	00000097          	auipc	ra,0x0
    800041e4:	f42080e7          	jalr	-190(ra) # 80004122 <iput>
}
    800041e8:	60e2                	ld	ra,24(sp)
    800041ea:	6442                	ld	s0,16(sp)
    800041ec:	64a2                	ld	s1,8(sp)
    800041ee:	6105                	addi	sp,sp,32
    800041f0:	8082                	ret

00000000800041f2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800041f2:	1141                	addi	sp,sp,-16
    800041f4:	e422                	sd	s0,8(sp)
    800041f6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800041f8:	411c                	lw	a5,0(a0)
    800041fa:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800041fc:	415c                	lw	a5,4(a0)
    800041fe:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004200:	04451783          	lh	a5,68(a0)
    80004204:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004208:	04a51783          	lh	a5,74(a0)
    8000420c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004210:	04c56783          	lwu	a5,76(a0)
    80004214:	e99c                	sd	a5,16(a1)
}
    80004216:	6422                	ld	s0,8(sp)
    80004218:	0141                	addi	sp,sp,16
    8000421a:	8082                	ret

000000008000421c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000421c:	457c                	lw	a5,76(a0)
    8000421e:	0ed7e963          	bltu	a5,a3,80004310 <readi+0xf4>
{
    80004222:	7159                	addi	sp,sp,-112
    80004224:	f486                	sd	ra,104(sp)
    80004226:	f0a2                	sd	s0,96(sp)
    80004228:	eca6                	sd	s1,88(sp)
    8000422a:	e8ca                	sd	s2,80(sp)
    8000422c:	e4ce                	sd	s3,72(sp)
    8000422e:	e0d2                	sd	s4,64(sp)
    80004230:	fc56                	sd	s5,56(sp)
    80004232:	f85a                	sd	s6,48(sp)
    80004234:	f45e                	sd	s7,40(sp)
    80004236:	f062                	sd	s8,32(sp)
    80004238:	ec66                	sd	s9,24(sp)
    8000423a:	e86a                	sd	s10,16(sp)
    8000423c:	e46e                	sd	s11,8(sp)
    8000423e:	1880                	addi	s0,sp,112
    80004240:	8baa                	mv	s7,a0
    80004242:	8c2e                	mv	s8,a1
    80004244:	8ab2                	mv	s5,a2
    80004246:	84b6                	mv	s1,a3
    80004248:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000424a:	9f35                	addw	a4,a4,a3
    return 0;
    8000424c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000424e:	0ad76063          	bltu	a4,a3,800042ee <readi+0xd2>
  if(off + n > ip->size)
    80004252:	00e7f463          	bgeu	a5,a4,8000425a <readi+0x3e>
    n = ip->size - off;
    80004256:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000425a:	0a0b0963          	beqz	s6,8000430c <readi+0xf0>
    8000425e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004260:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004264:	5cfd                	li	s9,-1
    80004266:	a82d                	j	800042a0 <readi+0x84>
    80004268:	020a1d93          	slli	s11,s4,0x20
    8000426c:	020ddd93          	srli	s11,s11,0x20
    80004270:	05890613          	addi	a2,s2,88
    80004274:	86ee                	mv	a3,s11
    80004276:	963a                	add	a2,a2,a4
    80004278:	85d6                	mv	a1,s5
    8000427a:	8562                	mv	a0,s8
    8000427c:	fffff097          	auipc	ra,0xfffff
    80004280:	a46080e7          	jalr	-1466(ra) # 80002cc2 <either_copyout>
    80004284:	05950d63          	beq	a0,s9,800042de <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004288:	854a                	mv	a0,s2
    8000428a:	fffff097          	auipc	ra,0xfffff
    8000428e:	60c080e7          	jalr	1548(ra) # 80003896 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004292:	013a09bb          	addw	s3,s4,s3
    80004296:	009a04bb          	addw	s1,s4,s1
    8000429a:	9aee                	add	s5,s5,s11
    8000429c:	0569f763          	bgeu	s3,s6,800042ea <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800042a0:	000ba903          	lw	s2,0(s7)
    800042a4:	00a4d59b          	srliw	a1,s1,0xa
    800042a8:	855e                	mv	a0,s7
    800042aa:	00000097          	auipc	ra,0x0
    800042ae:	8b0080e7          	jalr	-1872(ra) # 80003b5a <bmap>
    800042b2:	0005059b          	sext.w	a1,a0
    800042b6:	854a                	mv	a0,s2
    800042b8:	fffff097          	auipc	ra,0xfffff
    800042bc:	4ae080e7          	jalr	1198(ra) # 80003766 <bread>
    800042c0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800042c2:	3ff4f713          	andi	a4,s1,1023
    800042c6:	40ed07bb          	subw	a5,s10,a4
    800042ca:	413b06bb          	subw	a3,s6,s3
    800042ce:	8a3e                	mv	s4,a5
    800042d0:	2781                	sext.w	a5,a5
    800042d2:	0006861b          	sext.w	a2,a3
    800042d6:	f8f679e3          	bgeu	a2,a5,80004268 <readi+0x4c>
    800042da:	8a36                	mv	s4,a3
    800042dc:	b771                	j	80004268 <readi+0x4c>
      brelse(bp);
    800042de:	854a                	mv	a0,s2
    800042e0:	fffff097          	auipc	ra,0xfffff
    800042e4:	5b6080e7          	jalr	1462(ra) # 80003896 <brelse>
      tot = -1;
    800042e8:	59fd                	li	s3,-1
  }
  return tot;
    800042ea:	0009851b          	sext.w	a0,s3
}
    800042ee:	70a6                	ld	ra,104(sp)
    800042f0:	7406                	ld	s0,96(sp)
    800042f2:	64e6                	ld	s1,88(sp)
    800042f4:	6946                	ld	s2,80(sp)
    800042f6:	69a6                	ld	s3,72(sp)
    800042f8:	6a06                	ld	s4,64(sp)
    800042fa:	7ae2                	ld	s5,56(sp)
    800042fc:	7b42                	ld	s6,48(sp)
    800042fe:	7ba2                	ld	s7,40(sp)
    80004300:	7c02                	ld	s8,32(sp)
    80004302:	6ce2                	ld	s9,24(sp)
    80004304:	6d42                	ld	s10,16(sp)
    80004306:	6da2                	ld	s11,8(sp)
    80004308:	6165                	addi	sp,sp,112
    8000430a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000430c:	89da                	mv	s3,s6
    8000430e:	bff1                	j	800042ea <readi+0xce>
    return 0;
    80004310:	4501                	li	a0,0
}
    80004312:	8082                	ret

0000000080004314 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004314:	457c                	lw	a5,76(a0)
    80004316:	10d7e863          	bltu	a5,a3,80004426 <writei+0x112>
{
    8000431a:	7159                	addi	sp,sp,-112
    8000431c:	f486                	sd	ra,104(sp)
    8000431e:	f0a2                	sd	s0,96(sp)
    80004320:	eca6                	sd	s1,88(sp)
    80004322:	e8ca                	sd	s2,80(sp)
    80004324:	e4ce                	sd	s3,72(sp)
    80004326:	e0d2                	sd	s4,64(sp)
    80004328:	fc56                	sd	s5,56(sp)
    8000432a:	f85a                	sd	s6,48(sp)
    8000432c:	f45e                	sd	s7,40(sp)
    8000432e:	f062                	sd	s8,32(sp)
    80004330:	ec66                	sd	s9,24(sp)
    80004332:	e86a                	sd	s10,16(sp)
    80004334:	e46e                	sd	s11,8(sp)
    80004336:	1880                	addi	s0,sp,112
    80004338:	8b2a                	mv	s6,a0
    8000433a:	8c2e                	mv	s8,a1
    8000433c:	8ab2                	mv	s5,a2
    8000433e:	8936                	mv	s2,a3
    80004340:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004342:	00e687bb          	addw	a5,a3,a4
    80004346:	0ed7e263          	bltu	a5,a3,8000442a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000434a:	00043737          	lui	a4,0x43
    8000434e:	0ef76063          	bltu	a4,a5,8000442e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004352:	0c0b8863          	beqz	s7,80004422 <writei+0x10e>
    80004356:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004358:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000435c:	5cfd                	li	s9,-1
    8000435e:	a091                	j	800043a2 <writei+0x8e>
    80004360:	02099d93          	slli	s11,s3,0x20
    80004364:	020ddd93          	srli	s11,s11,0x20
    80004368:	05848513          	addi	a0,s1,88
    8000436c:	86ee                	mv	a3,s11
    8000436e:	8656                	mv	a2,s5
    80004370:	85e2                	mv	a1,s8
    80004372:	953a                	add	a0,a0,a4
    80004374:	fffff097          	auipc	ra,0xfffff
    80004378:	9a4080e7          	jalr	-1628(ra) # 80002d18 <either_copyin>
    8000437c:	07950263          	beq	a0,s9,800043e0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004380:	8526                	mv	a0,s1
    80004382:	00000097          	auipc	ra,0x0
    80004386:	790080e7          	jalr	1936(ra) # 80004b12 <log_write>
    brelse(bp);
    8000438a:	8526                	mv	a0,s1
    8000438c:	fffff097          	auipc	ra,0xfffff
    80004390:	50a080e7          	jalr	1290(ra) # 80003896 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004394:	01498a3b          	addw	s4,s3,s4
    80004398:	0129893b          	addw	s2,s3,s2
    8000439c:	9aee                	add	s5,s5,s11
    8000439e:	057a7663          	bgeu	s4,s7,800043ea <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800043a2:	000b2483          	lw	s1,0(s6)
    800043a6:	00a9559b          	srliw	a1,s2,0xa
    800043aa:	855a                	mv	a0,s6
    800043ac:	fffff097          	auipc	ra,0xfffff
    800043b0:	7ae080e7          	jalr	1966(ra) # 80003b5a <bmap>
    800043b4:	0005059b          	sext.w	a1,a0
    800043b8:	8526                	mv	a0,s1
    800043ba:	fffff097          	auipc	ra,0xfffff
    800043be:	3ac080e7          	jalr	940(ra) # 80003766 <bread>
    800043c2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800043c4:	3ff97713          	andi	a4,s2,1023
    800043c8:	40ed07bb          	subw	a5,s10,a4
    800043cc:	414b86bb          	subw	a3,s7,s4
    800043d0:	89be                	mv	s3,a5
    800043d2:	2781                	sext.w	a5,a5
    800043d4:	0006861b          	sext.w	a2,a3
    800043d8:	f8f674e3          	bgeu	a2,a5,80004360 <writei+0x4c>
    800043dc:	89b6                	mv	s3,a3
    800043de:	b749                	j	80004360 <writei+0x4c>
      brelse(bp);
    800043e0:	8526                	mv	a0,s1
    800043e2:	fffff097          	auipc	ra,0xfffff
    800043e6:	4b4080e7          	jalr	1204(ra) # 80003896 <brelse>
  }

  if(off > ip->size)
    800043ea:	04cb2783          	lw	a5,76(s6)
    800043ee:	0127f463          	bgeu	a5,s2,800043f6 <writei+0xe2>
    ip->size = off;
    800043f2:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800043f6:	855a                	mv	a0,s6
    800043f8:	00000097          	auipc	ra,0x0
    800043fc:	aa6080e7          	jalr	-1370(ra) # 80003e9e <iupdate>

  return tot;
    80004400:	000a051b          	sext.w	a0,s4
}
    80004404:	70a6                	ld	ra,104(sp)
    80004406:	7406                	ld	s0,96(sp)
    80004408:	64e6                	ld	s1,88(sp)
    8000440a:	6946                	ld	s2,80(sp)
    8000440c:	69a6                	ld	s3,72(sp)
    8000440e:	6a06                	ld	s4,64(sp)
    80004410:	7ae2                	ld	s5,56(sp)
    80004412:	7b42                	ld	s6,48(sp)
    80004414:	7ba2                	ld	s7,40(sp)
    80004416:	7c02                	ld	s8,32(sp)
    80004418:	6ce2                	ld	s9,24(sp)
    8000441a:	6d42                	ld	s10,16(sp)
    8000441c:	6da2                	ld	s11,8(sp)
    8000441e:	6165                	addi	sp,sp,112
    80004420:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004422:	8a5e                	mv	s4,s7
    80004424:	bfc9                	j	800043f6 <writei+0xe2>
    return -1;
    80004426:	557d                	li	a0,-1
}
    80004428:	8082                	ret
    return -1;
    8000442a:	557d                	li	a0,-1
    8000442c:	bfe1                	j	80004404 <writei+0xf0>
    return -1;
    8000442e:	557d                	li	a0,-1
    80004430:	bfd1                	j	80004404 <writei+0xf0>

0000000080004432 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004432:	1141                	addi	sp,sp,-16
    80004434:	e406                	sd	ra,8(sp)
    80004436:	e022                	sd	s0,0(sp)
    80004438:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000443a:	4639                	li	a2,14
    8000443c:	ffffd097          	auipc	ra,0xffffd
    80004440:	9ae080e7          	jalr	-1618(ra) # 80000dea <strncmp>
}
    80004444:	60a2                	ld	ra,8(sp)
    80004446:	6402                	ld	s0,0(sp)
    80004448:	0141                	addi	sp,sp,16
    8000444a:	8082                	ret

000000008000444c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000444c:	7139                	addi	sp,sp,-64
    8000444e:	fc06                	sd	ra,56(sp)
    80004450:	f822                	sd	s0,48(sp)
    80004452:	f426                	sd	s1,40(sp)
    80004454:	f04a                	sd	s2,32(sp)
    80004456:	ec4e                	sd	s3,24(sp)
    80004458:	e852                	sd	s4,16(sp)
    8000445a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000445c:	04451703          	lh	a4,68(a0)
    80004460:	4785                	li	a5,1
    80004462:	00f71a63          	bne	a4,a5,80004476 <dirlookup+0x2a>
    80004466:	892a                	mv	s2,a0
    80004468:	89ae                	mv	s3,a1
    8000446a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000446c:	457c                	lw	a5,76(a0)
    8000446e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004470:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004472:	e79d                	bnez	a5,800044a0 <dirlookup+0x54>
    80004474:	a8a5                	j	800044ec <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004476:	00004517          	auipc	a0,0x4
    8000447a:	1b250513          	addi	a0,a0,434 # 80008628 <syscalls+0x1b0>
    8000447e:	ffffc097          	auipc	ra,0xffffc
    80004482:	0c0080e7          	jalr	192(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004486:	00004517          	auipc	a0,0x4
    8000448a:	1ba50513          	addi	a0,a0,442 # 80008640 <syscalls+0x1c8>
    8000448e:	ffffc097          	auipc	ra,0xffffc
    80004492:	0b0080e7          	jalr	176(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004496:	24c1                	addiw	s1,s1,16
    80004498:	04c92783          	lw	a5,76(s2)
    8000449c:	04f4f763          	bgeu	s1,a5,800044ea <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044a0:	4741                	li	a4,16
    800044a2:	86a6                	mv	a3,s1
    800044a4:	fc040613          	addi	a2,s0,-64
    800044a8:	4581                	li	a1,0
    800044aa:	854a                	mv	a0,s2
    800044ac:	00000097          	auipc	ra,0x0
    800044b0:	d70080e7          	jalr	-656(ra) # 8000421c <readi>
    800044b4:	47c1                	li	a5,16
    800044b6:	fcf518e3          	bne	a0,a5,80004486 <dirlookup+0x3a>
    if(de.inum == 0)
    800044ba:	fc045783          	lhu	a5,-64(s0)
    800044be:	dfe1                	beqz	a5,80004496 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800044c0:	fc240593          	addi	a1,s0,-62
    800044c4:	854e                	mv	a0,s3
    800044c6:	00000097          	auipc	ra,0x0
    800044ca:	f6c080e7          	jalr	-148(ra) # 80004432 <namecmp>
    800044ce:	f561                	bnez	a0,80004496 <dirlookup+0x4a>
      if(poff)
    800044d0:	000a0463          	beqz	s4,800044d8 <dirlookup+0x8c>
        *poff = off;
    800044d4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800044d8:	fc045583          	lhu	a1,-64(s0)
    800044dc:	00092503          	lw	a0,0(s2)
    800044e0:	fffff097          	auipc	ra,0xfffff
    800044e4:	754080e7          	jalr	1876(ra) # 80003c34 <iget>
    800044e8:	a011                	j	800044ec <dirlookup+0xa0>
  return 0;
    800044ea:	4501                	li	a0,0
}
    800044ec:	70e2                	ld	ra,56(sp)
    800044ee:	7442                	ld	s0,48(sp)
    800044f0:	74a2                	ld	s1,40(sp)
    800044f2:	7902                	ld	s2,32(sp)
    800044f4:	69e2                	ld	s3,24(sp)
    800044f6:	6a42                	ld	s4,16(sp)
    800044f8:	6121                	addi	sp,sp,64
    800044fa:	8082                	ret

00000000800044fc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800044fc:	711d                	addi	sp,sp,-96
    800044fe:	ec86                	sd	ra,88(sp)
    80004500:	e8a2                	sd	s0,80(sp)
    80004502:	e4a6                	sd	s1,72(sp)
    80004504:	e0ca                	sd	s2,64(sp)
    80004506:	fc4e                	sd	s3,56(sp)
    80004508:	f852                	sd	s4,48(sp)
    8000450a:	f456                	sd	s5,40(sp)
    8000450c:	f05a                	sd	s6,32(sp)
    8000450e:	ec5e                	sd	s7,24(sp)
    80004510:	e862                	sd	s8,16(sp)
    80004512:	e466                	sd	s9,8(sp)
    80004514:	1080                	addi	s0,sp,96
    80004516:	84aa                	mv	s1,a0
    80004518:	8b2e                	mv	s6,a1
    8000451a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000451c:	00054703          	lbu	a4,0(a0)
    80004520:	02f00793          	li	a5,47
    80004524:	02f70363          	beq	a4,a5,8000454a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004528:	ffffe097          	auipc	ra,0xffffe
    8000452c:	934080e7          	jalr	-1740(ra) # 80001e5c <myproc>
    80004530:	17053503          	ld	a0,368(a0)
    80004534:	00000097          	auipc	ra,0x0
    80004538:	9f6080e7          	jalr	-1546(ra) # 80003f2a <idup>
    8000453c:	89aa                	mv	s3,a0
  while(*path == '/')
    8000453e:	02f00913          	li	s2,47
  len = path - s;
    80004542:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004544:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004546:	4c05                	li	s8,1
    80004548:	a865                	j	80004600 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000454a:	4585                	li	a1,1
    8000454c:	4505                	li	a0,1
    8000454e:	fffff097          	auipc	ra,0xfffff
    80004552:	6e6080e7          	jalr	1766(ra) # 80003c34 <iget>
    80004556:	89aa                	mv	s3,a0
    80004558:	b7dd                	j	8000453e <namex+0x42>
      iunlockput(ip);
    8000455a:	854e                	mv	a0,s3
    8000455c:	00000097          	auipc	ra,0x0
    80004560:	c6e080e7          	jalr	-914(ra) # 800041ca <iunlockput>
      return 0;
    80004564:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004566:	854e                	mv	a0,s3
    80004568:	60e6                	ld	ra,88(sp)
    8000456a:	6446                	ld	s0,80(sp)
    8000456c:	64a6                	ld	s1,72(sp)
    8000456e:	6906                	ld	s2,64(sp)
    80004570:	79e2                	ld	s3,56(sp)
    80004572:	7a42                	ld	s4,48(sp)
    80004574:	7aa2                	ld	s5,40(sp)
    80004576:	7b02                	ld	s6,32(sp)
    80004578:	6be2                	ld	s7,24(sp)
    8000457a:	6c42                	ld	s8,16(sp)
    8000457c:	6ca2                	ld	s9,8(sp)
    8000457e:	6125                	addi	sp,sp,96
    80004580:	8082                	ret
      iunlock(ip);
    80004582:	854e                	mv	a0,s3
    80004584:	00000097          	auipc	ra,0x0
    80004588:	aa6080e7          	jalr	-1370(ra) # 8000402a <iunlock>
      return ip;
    8000458c:	bfe9                	j	80004566 <namex+0x6a>
      iunlockput(ip);
    8000458e:	854e                	mv	a0,s3
    80004590:	00000097          	auipc	ra,0x0
    80004594:	c3a080e7          	jalr	-966(ra) # 800041ca <iunlockput>
      return 0;
    80004598:	89d2                	mv	s3,s4
    8000459a:	b7f1                	j	80004566 <namex+0x6a>
  len = path - s;
    8000459c:	40b48633          	sub	a2,s1,a1
    800045a0:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800045a4:	094cd463          	bge	s9,s4,8000462c <namex+0x130>
    memmove(name, s, DIRSIZ);
    800045a8:	4639                	li	a2,14
    800045aa:	8556                	mv	a0,s5
    800045ac:	ffffc097          	auipc	ra,0xffffc
    800045b0:	7c6080e7          	jalr	1990(ra) # 80000d72 <memmove>
  while(*path == '/')
    800045b4:	0004c783          	lbu	a5,0(s1)
    800045b8:	01279763          	bne	a5,s2,800045c6 <namex+0xca>
    path++;
    800045bc:	0485                	addi	s1,s1,1
  while(*path == '/')
    800045be:	0004c783          	lbu	a5,0(s1)
    800045c2:	ff278de3          	beq	a5,s2,800045bc <namex+0xc0>
    ilock(ip);
    800045c6:	854e                	mv	a0,s3
    800045c8:	00000097          	auipc	ra,0x0
    800045cc:	9a0080e7          	jalr	-1632(ra) # 80003f68 <ilock>
    if(ip->type != T_DIR){
    800045d0:	04499783          	lh	a5,68(s3)
    800045d4:	f98793e3          	bne	a5,s8,8000455a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800045d8:	000b0563          	beqz	s6,800045e2 <namex+0xe6>
    800045dc:	0004c783          	lbu	a5,0(s1)
    800045e0:	d3cd                	beqz	a5,80004582 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800045e2:	865e                	mv	a2,s7
    800045e4:	85d6                	mv	a1,s5
    800045e6:	854e                	mv	a0,s3
    800045e8:	00000097          	auipc	ra,0x0
    800045ec:	e64080e7          	jalr	-412(ra) # 8000444c <dirlookup>
    800045f0:	8a2a                	mv	s4,a0
    800045f2:	dd51                	beqz	a0,8000458e <namex+0x92>
    iunlockput(ip);
    800045f4:	854e                	mv	a0,s3
    800045f6:	00000097          	auipc	ra,0x0
    800045fa:	bd4080e7          	jalr	-1068(ra) # 800041ca <iunlockput>
    ip = next;
    800045fe:	89d2                	mv	s3,s4
  while(*path == '/')
    80004600:	0004c783          	lbu	a5,0(s1)
    80004604:	05279763          	bne	a5,s2,80004652 <namex+0x156>
    path++;
    80004608:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000460a:	0004c783          	lbu	a5,0(s1)
    8000460e:	ff278de3          	beq	a5,s2,80004608 <namex+0x10c>
  if(*path == 0)
    80004612:	c79d                	beqz	a5,80004640 <namex+0x144>
    path++;
    80004614:	85a6                	mv	a1,s1
  len = path - s;
    80004616:	8a5e                	mv	s4,s7
    80004618:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000461a:	01278963          	beq	a5,s2,8000462c <namex+0x130>
    8000461e:	dfbd                	beqz	a5,8000459c <namex+0xa0>
    path++;
    80004620:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004622:	0004c783          	lbu	a5,0(s1)
    80004626:	ff279ce3          	bne	a5,s2,8000461e <namex+0x122>
    8000462a:	bf8d                	j	8000459c <namex+0xa0>
    memmove(name, s, len);
    8000462c:	2601                	sext.w	a2,a2
    8000462e:	8556                	mv	a0,s5
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	742080e7          	jalr	1858(ra) # 80000d72 <memmove>
    name[len] = 0;
    80004638:	9a56                	add	s4,s4,s5
    8000463a:	000a0023          	sb	zero,0(s4)
    8000463e:	bf9d                	j	800045b4 <namex+0xb8>
  if(nameiparent){
    80004640:	f20b03e3          	beqz	s6,80004566 <namex+0x6a>
    iput(ip);
    80004644:	854e                	mv	a0,s3
    80004646:	00000097          	auipc	ra,0x0
    8000464a:	adc080e7          	jalr	-1316(ra) # 80004122 <iput>
    return 0;
    8000464e:	4981                	li	s3,0
    80004650:	bf19                	j	80004566 <namex+0x6a>
  if(*path == 0)
    80004652:	d7fd                	beqz	a5,80004640 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004654:	0004c783          	lbu	a5,0(s1)
    80004658:	85a6                	mv	a1,s1
    8000465a:	b7d1                	j	8000461e <namex+0x122>

000000008000465c <dirlink>:
{
    8000465c:	7139                	addi	sp,sp,-64
    8000465e:	fc06                	sd	ra,56(sp)
    80004660:	f822                	sd	s0,48(sp)
    80004662:	f426                	sd	s1,40(sp)
    80004664:	f04a                	sd	s2,32(sp)
    80004666:	ec4e                	sd	s3,24(sp)
    80004668:	e852                	sd	s4,16(sp)
    8000466a:	0080                	addi	s0,sp,64
    8000466c:	892a                	mv	s2,a0
    8000466e:	8a2e                	mv	s4,a1
    80004670:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004672:	4601                	li	a2,0
    80004674:	00000097          	auipc	ra,0x0
    80004678:	dd8080e7          	jalr	-552(ra) # 8000444c <dirlookup>
    8000467c:	e93d                	bnez	a0,800046f2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000467e:	04c92483          	lw	s1,76(s2)
    80004682:	c49d                	beqz	s1,800046b0 <dirlink+0x54>
    80004684:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004686:	4741                	li	a4,16
    80004688:	86a6                	mv	a3,s1
    8000468a:	fc040613          	addi	a2,s0,-64
    8000468e:	4581                	li	a1,0
    80004690:	854a                	mv	a0,s2
    80004692:	00000097          	auipc	ra,0x0
    80004696:	b8a080e7          	jalr	-1142(ra) # 8000421c <readi>
    8000469a:	47c1                	li	a5,16
    8000469c:	06f51163          	bne	a0,a5,800046fe <dirlink+0xa2>
    if(de.inum == 0)
    800046a0:	fc045783          	lhu	a5,-64(s0)
    800046a4:	c791                	beqz	a5,800046b0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046a6:	24c1                	addiw	s1,s1,16
    800046a8:	04c92783          	lw	a5,76(s2)
    800046ac:	fcf4ede3          	bltu	s1,a5,80004686 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800046b0:	4639                	li	a2,14
    800046b2:	85d2                	mv	a1,s4
    800046b4:	fc240513          	addi	a0,s0,-62
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	76e080e7          	jalr	1902(ra) # 80000e26 <strncpy>
  de.inum = inum;
    800046c0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046c4:	4741                	li	a4,16
    800046c6:	86a6                	mv	a3,s1
    800046c8:	fc040613          	addi	a2,s0,-64
    800046cc:	4581                	li	a1,0
    800046ce:	854a                	mv	a0,s2
    800046d0:	00000097          	auipc	ra,0x0
    800046d4:	c44080e7          	jalr	-956(ra) # 80004314 <writei>
    800046d8:	872a                	mv	a4,a0
    800046da:	47c1                	li	a5,16
  return 0;
    800046dc:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046de:	02f71863          	bne	a4,a5,8000470e <dirlink+0xb2>
}
    800046e2:	70e2                	ld	ra,56(sp)
    800046e4:	7442                	ld	s0,48(sp)
    800046e6:	74a2                	ld	s1,40(sp)
    800046e8:	7902                	ld	s2,32(sp)
    800046ea:	69e2                	ld	s3,24(sp)
    800046ec:	6a42                	ld	s4,16(sp)
    800046ee:	6121                	addi	sp,sp,64
    800046f0:	8082                	ret
    iput(ip);
    800046f2:	00000097          	auipc	ra,0x0
    800046f6:	a30080e7          	jalr	-1488(ra) # 80004122 <iput>
    return -1;
    800046fa:	557d                	li	a0,-1
    800046fc:	b7dd                	j	800046e2 <dirlink+0x86>
      panic("dirlink read");
    800046fe:	00004517          	auipc	a0,0x4
    80004702:	f5250513          	addi	a0,a0,-174 # 80008650 <syscalls+0x1d8>
    80004706:	ffffc097          	auipc	ra,0xffffc
    8000470a:	e38080e7          	jalr	-456(ra) # 8000053e <panic>
    panic("dirlink");
    8000470e:	00004517          	auipc	a0,0x4
    80004712:	05250513          	addi	a0,a0,82 # 80008760 <syscalls+0x2e8>
    80004716:	ffffc097          	auipc	ra,0xffffc
    8000471a:	e28080e7          	jalr	-472(ra) # 8000053e <panic>

000000008000471e <namei>:

struct inode*
namei(char *path)
{
    8000471e:	1101                	addi	sp,sp,-32
    80004720:	ec06                	sd	ra,24(sp)
    80004722:	e822                	sd	s0,16(sp)
    80004724:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004726:	fe040613          	addi	a2,s0,-32
    8000472a:	4581                	li	a1,0
    8000472c:	00000097          	auipc	ra,0x0
    80004730:	dd0080e7          	jalr	-560(ra) # 800044fc <namex>
}
    80004734:	60e2                	ld	ra,24(sp)
    80004736:	6442                	ld	s0,16(sp)
    80004738:	6105                	addi	sp,sp,32
    8000473a:	8082                	ret

000000008000473c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000473c:	1141                	addi	sp,sp,-16
    8000473e:	e406                	sd	ra,8(sp)
    80004740:	e022                	sd	s0,0(sp)
    80004742:	0800                	addi	s0,sp,16
    80004744:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004746:	4585                	li	a1,1
    80004748:	00000097          	auipc	ra,0x0
    8000474c:	db4080e7          	jalr	-588(ra) # 800044fc <namex>
}
    80004750:	60a2                	ld	ra,8(sp)
    80004752:	6402                	ld	s0,0(sp)
    80004754:	0141                	addi	sp,sp,16
    80004756:	8082                	ret

0000000080004758 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004758:	1101                	addi	sp,sp,-32
    8000475a:	ec06                	sd	ra,24(sp)
    8000475c:	e822                	sd	s0,16(sp)
    8000475e:	e426                	sd	s1,8(sp)
    80004760:	e04a                	sd	s2,0(sp)
    80004762:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004764:	0001d917          	auipc	s2,0x1d
    80004768:	4d490913          	addi	s2,s2,1236 # 80021c38 <log>
    8000476c:	01892583          	lw	a1,24(s2)
    80004770:	02892503          	lw	a0,40(s2)
    80004774:	fffff097          	auipc	ra,0xfffff
    80004778:	ff2080e7          	jalr	-14(ra) # 80003766 <bread>
    8000477c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000477e:	02c92683          	lw	a3,44(s2)
    80004782:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004784:	02d05763          	blez	a3,800047b2 <write_head+0x5a>
    80004788:	0001d797          	auipc	a5,0x1d
    8000478c:	4e078793          	addi	a5,a5,1248 # 80021c68 <log+0x30>
    80004790:	05c50713          	addi	a4,a0,92
    80004794:	36fd                	addiw	a3,a3,-1
    80004796:	1682                	slli	a3,a3,0x20
    80004798:	9281                	srli	a3,a3,0x20
    8000479a:	068a                	slli	a3,a3,0x2
    8000479c:	0001d617          	auipc	a2,0x1d
    800047a0:	4d060613          	addi	a2,a2,1232 # 80021c6c <log+0x34>
    800047a4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800047a6:	4390                	lw	a2,0(a5)
    800047a8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800047aa:	0791                	addi	a5,a5,4
    800047ac:	0711                	addi	a4,a4,4
    800047ae:	fed79ce3          	bne	a5,a3,800047a6 <write_head+0x4e>
  }
  bwrite(buf);
    800047b2:	8526                	mv	a0,s1
    800047b4:	fffff097          	auipc	ra,0xfffff
    800047b8:	0a4080e7          	jalr	164(ra) # 80003858 <bwrite>
  brelse(buf);
    800047bc:	8526                	mv	a0,s1
    800047be:	fffff097          	auipc	ra,0xfffff
    800047c2:	0d8080e7          	jalr	216(ra) # 80003896 <brelse>
}
    800047c6:	60e2                	ld	ra,24(sp)
    800047c8:	6442                	ld	s0,16(sp)
    800047ca:	64a2                	ld	s1,8(sp)
    800047cc:	6902                	ld	s2,0(sp)
    800047ce:	6105                	addi	sp,sp,32
    800047d0:	8082                	ret

00000000800047d2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800047d2:	0001d797          	auipc	a5,0x1d
    800047d6:	4927a783          	lw	a5,1170(a5) # 80021c64 <log+0x2c>
    800047da:	0af05d63          	blez	a5,80004894 <install_trans+0xc2>
{
    800047de:	7139                	addi	sp,sp,-64
    800047e0:	fc06                	sd	ra,56(sp)
    800047e2:	f822                	sd	s0,48(sp)
    800047e4:	f426                	sd	s1,40(sp)
    800047e6:	f04a                	sd	s2,32(sp)
    800047e8:	ec4e                	sd	s3,24(sp)
    800047ea:	e852                	sd	s4,16(sp)
    800047ec:	e456                	sd	s5,8(sp)
    800047ee:	e05a                	sd	s6,0(sp)
    800047f0:	0080                	addi	s0,sp,64
    800047f2:	8b2a                	mv	s6,a0
    800047f4:	0001da97          	auipc	s5,0x1d
    800047f8:	474a8a93          	addi	s5,s5,1140 # 80021c68 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047fc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800047fe:	0001d997          	auipc	s3,0x1d
    80004802:	43a98993          	addi	s3,s3,1082 # 80021c38 <log>
    80004806:	a035                	j	80004832 <install_trans+0x60>
      bunpin(dbuf);
    80004808:	8526                	mv	a0,s1
    8000480a:	fffff097          	auipc	ra,0xfffff
    8000480e:	166080e7          	jalr	358(ra) # 80003970 <bunpin>
    brelse(lbuf);
    80004812:	854a                	mv	a0,s2
    80004814:	fffff097          	auipc	ra,0xfffff
    80004818:	082080e7          	jalr	130(ra) # 80003896 <brelse>
    brelse(dbuf);
    8000481c:	8526                	mv	a0,s1
    8000481e:	fffff097          	auipc	ra,0xfffff
    80004822:	078080e7          	jalr	120(ra) # 80003896 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004826:	2a05                	addiw	s4,s4,1
    80004828:	0a91                	addi	s5,s5,4
    8000482a:	02c9a783          	lw	a5,44(s3)
    8000482e:	04fa5963          	bge	s4,a5,80004880 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004832:	0189a583          	lw	a1,24(s3)
    80004836:	014585bb          	addw	a1,a1,s4
    8000483a:	2585                	addiw	a1,a1,1
    8000483c:	0289a503          	lw	a0,40(s3)
    80004840:	fffff097          	auipc	ra,0xfffff
    80004844:	f26080e7          	jalr	-218(ra) # 80003766 <bread>
    80004848:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000484a:	000aa583          	lw	a1,0(s5)
    8000484e:	0289a503          	lw	a0,40(s3)
    80004852:	fffff097          	auipc	ra,0xfffff
    80004856:	f14080e7          	jalr	-236(ra) # 80003766 <bread>
    8000485a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000485c:	40000613          	li	a2,1024
    80004860:	05890593          	addi	a1,s2,88
    80004864:	05850513          	addi	a0,a0,88
    80004868:	ffffc097          	auipc	ra,0xffffc
    8000486c:	50a080e7          	jalr	1290(ra) # 80000d72 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004870:	8526                	mv	a0,s1
    80004872:	fffff097          	auipc	ra,0xfffff
    80004876:	fe6080e7          	jalr	-26(ra) # 80003858 <bwrite>
    if(recovering == 0)
    8000487a:	f80b1ce3          	bnez	s6,80004812 <install_trans+0x40>
    8000487e:	b769                	j	80004808 <install_trans+0x36>
}
    80004880:	70e2                	ld	ra,56(sp)
    80004882:	7442                	ld	s0,48(sp)
    80004884:	74a2                	ld	s1,40(sp)
    80004886:	7902                	ld	s2,32(sp)
    80004888:	69e2                	ld	s3,24(sp)
    8000488a:	6a42                	ld	s4,16(sp)
    8000488c:	6aa2                	ld	s5,8(sp)
    8000488e:	6b02                	ld	s6,0(sp)
    80004890:	6121                	addi	sp,sp,64
    80004892:	8082                	ret
    80004894:	8082                	ret

0000000080004896 <initlog>:
{
    80004896:	7179                	addi	sp,sp,-48
    80004898:	f406                	sd	ra,40(sp)
    8000489a:	f022                	sd	s0,32(sp)
    8000489c:	ec26                	sd	s1,24(sp)
    8000489e:	e84a                	sd	s2,16(sp)
    800048a0:	e44e                	sd	s3,8(sp)
    800048a2:	1800                	addi	s0,sp,48
    800048a4:	892a                	mv	s2,a0
    800048a6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800048a8:	0001d497          	auipc	s1,0x1d
    800048ac:	39048493          	addi	s1,s1,912 # 80021c38 <log>
    800048b0:	00004597          	auipc	a1,0x4
    800048b4:	db058593          	addi	a1,a1,-592 # 80008660 <syscalls+0x1e8>
    800048b8:	8526                	mv	a0,s1
    800048ba:	ffffc097          	auipc	ra,0xffffc
    800048be:	29a080e7          	jalr	666(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800048c2:	0149a583          	lw	a1,20(s3)
    800048c6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800048c8:	0109a783          	lw	a5,16(s3)
    800048cc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800048ce:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800048d2:	854a                	mv	a0,s2
    800048d4:	fffff097          	auipc	ra,0xfffff
    800048d8:	e92080e7          	jalr	-366(ra) # 80003766 <bread>
  log.lh.n = lh->n;
    800048dc:	4d3c                	lw	a5,88(a0)
    800048de:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800048e0:	02f05563          	blez	a5,8000490a <initlog+0x74>
    800048e4:	05c50713          	addi	a4,a0,92
    800048e8:	0001d697          	auipc	a3,0x1d
    800048ec:	38068693          	addi	a3,a3,896 # 80021c68 <log+0x30>
    800048f0:	37fd                	addiw	a5,a5,-1
    800048f2:	1782                	slli	a5,a5,0x20
    800048f4:	9381                	srli	a5,a5,0x20
    800048f6:	078a                	slli	a5,a5,0x2
    800048f8:	06050613          	addi	a2,a0,96
    800048fc:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800048fe:	4310                	lw	a2,0(a4)
    80004900:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004902:	0711                	addi	a4,a4,4
    80004904:	0691                	addi	a3,a3,4
    80004906:	fef71ce3          	bne	a4,a5,800048fe <initlog+0x68>
  brelse(buf);
    8000490a:	fffff097          	auipc	ra,0xfffff
    8000490e:	f8c080e7          	jalr	-116(ra) # 80003896 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004912:	4505                	li	a0,1
    80004914:	00000097          	auipc	ra,0x0
    80004918:	ebe080e7          	jalr	-322(ra) # 800047d2 <install_trans>
  log.lh.n = 0;
    8000491c:	0001d797          	auipc	a5,0x1d
    80004920:	3407a423          	sw	zero,840(a5) # 80021c64 <log+0x2c>
  write_head(); // clear the log
    80004924:	00000097          	auipc	ra,0x0
    80004928:	e34080e7          	jalr	-460(ra) # 80004758 <write_head>
}
    8000492c:	70a2                	ld	ra,40(sp)
    8000492e:	7402                	ld	s0,32(sp)
    80004930:	64e2                	ld	s1,24(sp)
    80004932:	6942                	ld	s2,16(sp)
    80004934:	69a2                	ld	s3,8(sp)
    80004936:	6145                	addi	sp,sp,48
    80004938:	8082                	ret

000000008000493a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000493a:	1101                	addi	sp,sp,-32
    8000493c:	ec06                	sd	ra,24(sp)
    8000493e:	e822                	sd	s0,16(sp)
    80004940:	e426                	sd	s1,8(sp)
    80004942:	e04a                	sd	s2,0(sp)
    80004944:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004946:	0001d517          	auipc	a0,0x1d
    8000494a:	2f250513          	addi	a0,a0,754 # 80021c38 <log>
    8000494e:	ffffc097          	auipc	ra,0xffffc
    80004952:	29e080e7          	jalr	670(ra) # 80000bec <acquire>
  while(1){
    if(log.committing){
    80004956:	0001d497          	auipc	s1,0x1d
    8000495a:	2e248493          	addi	s1,s1,738 # 80021c38 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000495e:	4979                	li	s2,30
    80004960:	a039                	j	8000496e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004962:	85a6                	mv	a1,s1
    80004964:	8526                	mv	a0,s1
    80004966:	ffffe097          	auipc	ra,0xffffe
    8000496a:	d84080e7          	jalr	-636(ra) # 800026ea <sleep>
    if(log.committing){
    8000496e:	50dc                	lw	a5,36(s1)
    80004970:	fbed                	bnez	a5,80004962 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004972:	509c                	lw	a5,32(s1)
    80004974:	0017871b          	addiw	a4,a5,1
    80004978:	0007069b          	sext.w	a3,a4
    8000497c:	0027179b          	slliw	a5,a4,0x2
    80004980:	9fb9                	addw	a5,a5,a4
    80004982:	0017979b          	slliw	a5,a5,0x1
    80004986:	54d8                	lw	a4,44(s1)
    80004988:	9fb9                	addw	a5,a5,a4
    8000498a:	00f95963          	bge	s2,a5,8000499c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000498e:	85a6                	mv	a1,s1
    80004990:	8526                	mv	a0,s1
    80004992:	ffffe097          	auipc	ra,0xffffe
    80004996:	d58080e7          	jalr	-680(ra) # 800026ea <sleep>
    8000499a:	bfd1                	j	8000496e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000499c:	0001d517          	auipc	a0,0x1d
    800049a0:	29c50513          	addi	a0,a0,668 # 80021c38 <log>
    800049a4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800049a6:	ffffc097          	auipc	ra,0xffffc
    800049aa:	312080e7          	jalr	786(ra) # 80000cb8 <release>
      break;
    }
  }
}
    800049ae:	60e2                	ld	ra,24(sp)
    800049b0:	6442                	ld	s0,16(sp)
    800049b2:	64a2                	ld	s1,8(sp)
    800049b4:	6902                	ld	s2,0(sp)
    800049b6:	6105                	addi	sp,sp,32
    800049b8:	8082                	ret

00000000800049ba <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800049ba:	7139                	addi	sp,sp,-64
    800049bc:	fc06                	sd	ra,56(sp)
    800049be:	f822                	sd	s0,48(sp)
    800049c0:	f426                	sd	s1,40(sp)
    800049c2:	f04a                	sd	s2,32(sp)
    800049c4:	ec4e                	sd	s3,24(sp)
    800049c6:	e852                	sd	s4,16(sp)
    800049c8:	e456                	sd	s5,8(sp)
    800049ca:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800049cc:	0001d497          	auipc	s1,0x1d
    800049d0:	26c48493          	addi	s1,s1,620 # 80021c38 <log>
    800049d4:	8526                	mv	a0,s1
    800049d6:	ffffc097          	auipc	ra,0xffffc
    800049da:	216080e7          	jalr	534(ra) # 80000bec <acquire>
  log.outstanding -= 1;
    800049de:	509c                	lw	a5,32(s1)
    800049e0:	37fd                	addiw	a5,a5,-1
    800049e2:	0007891b          	sext.w	s2,a5
    800049e6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800049e8:	50dc                	lw	a5,36(s1)
    800049ea:	efb9                	bnez	a5,80004a48 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800049ec:	06091663          	bnez	s2,80004a58 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800049f0:	0001d497          	auipc	s1,0x1d
    800049f4:	24848493          	addi	s1,s1,584 # 80021c38 <log>
    800049f8:	4785                	li	a5,1
    800049fa:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800049fc:	8526                	mv	a0,s1
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	2ba080e7          	jalr	698(ra) # 80000cb8 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004a06:	54dc                	lw	a5,44(s1)
    80004a08:	06f04763          	bgtz	a5,80004a76 <end_op+0xbc>
    acquire(&log.lock);
    80004a0c:	0001d497          	auipc	s1,0x1d
    80004a10:	22c48493          	addi	s1,s1,556 # 80021c38 <log>
    80004a14:	8526                	mv	a0,s1
    80004a16:	ffffc097          	auipc	ra,0xffffc
    80004a1a:	1d6080e7          	jalr	470(ra) # 80000bec <acquire>
    log.committing = 0;
    80004a1e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004a22:	8526                	mv	a0,s1
    80004a24:	ffffe097          	auipc	ra,0xffffe
    80004a28:	fb8080e7          	jalr	-72(ra) # 800029dc <wakeup>
    release(&log.lock);
    80004a2c:	8526                	mv	a0,s1
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	28a080e7          	jalr	650(ra) # 80000cb8 <release>
}
    80004a36:	70e2                	ld	ra,56(sp)
    80004a38:	7442                	ld	s0,48(sp)
    80004a3a:	74a2                	ld	s1,40(sp)
    80004a3c:	7902                	ld	s2,32(sp)
    80004a3e:	69e2                	ld	s3,24(sp)
    80004a40:	6a42                	ld	s4,16(sp)
    80004a42:	6aa2                	ld	s5,8(sp)
    80004a44:	6121                	addi	sp,sp,64
    80004a46:	8082                	ret
    panic("log.committing");
    80004a48:	00004517          	auipc	a0,0x4
    80004a4c:	c2050513          	addi	a0,a0,-992 # 80008668 <syscalls+0x1f0>
    80004a50:	ffffc097          	auipc	ra,0xffffc
    80004a54:	aee080e7          	jalr	-1298(ra) # 8000053e <panic>
    wakeup(&log);
    80004a58:	0001d497          	auipc	s1,0x1d
    80004a5c:	1e048493          	addi	s1,s1,480 # 80021c38 <log>
    80004a60:	8526                	mv	a0,s1
    80004a62:	ffffe097          	auipc	ra,0xffffe
    80004a66:	f7a080e7          	jalr	-134(ra) # 800029dc <wakeup>
  release(&log.lock);
    80004a6a:	8526                	mv	a0,s1
    80004a6c:	ffffc097          	auipc	ra,0xffffc
    80004a70:	24c080e7          	jalr	588(ra) # 80000cb8 <release>
  if(do_commit){
    80004a74:	b7c9                	j	80004a36 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a76:	0001da97          	auipc	s5,0x1d
    80004a7a:	1f2a8a93          	addi	s5,s5,498 # 80021c68 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004a7e:	0001da17          	auipc	s4,0x1d
    80004a82:	1baa0a13          	addi	s4,s4,442 # 80021c38 <log>
    80004a86:	018a2583          	lw	a1,24(s4)
    80004a8a:	012585bb          	addw	a1,a1,s2
    80004a8e:	2585                	addiw	a1,a1,1
    80004a90:	028a2503          	lw	a0,40(s4)
    80004a94:	fffff097          	auipc	ra,0xfffff
    80004a98:	cd2080e7          	jalr	-814(ra) # 80003766 <bread>
    80004a9c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004a9e:	000aa583          	lw	a1,0(s5)
    80004aa2:	028a2503          	lw	a0,40(s4)
    80004aa6:	fffff097          	auipc	ra,0xfffff
    80004aaa:	cc0080e7          	jalr	-832(ra) # 80003766 <bread>
    80004aae:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004ab0:	40000613          	li	a2,1024
    80004ab4:	05850593          	addi	a1,a0,88
    80004ab8:	05848513          	addi	a0,s1,88
    80004abc:	ffffc097          	auipc	ra,0xffffc
    80004ac0:	2b6080e7          	jalr	694(ra) # 80000d72 <memmove>
    bwrite(to);  // write the log
    80004ac4:	8526                	mv	a0,s1
    80004ac6:	fffff097          	auipc	ra,0xfffff
    80004aca:	d92080e7          	jalr	-622(ra) # 80003858 <bwrite>
    brelse(from);
    80004ace:	854e                	mv	a0,s3
    80004ad0:	fffff097          	auipc	ra,0xfffff
    80004ad4:	dc6080e7          	jalr	-570(ra) # 80003896 <brelse>
    brelse(to);
    80004ad8:	8526                	mv	a0,s1
    80004ada:	fffff097          	auipc	ra,0xfffff
    80004ade:	dbc080e7          	jalr	-580(ra) # 80003896 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ae2:	2905                	addiw	s2,s2,1
    80004ae4:	0a91                	addi	s5,s5,4
    80004ae6:	02ca2783          	lw	a5,44(s4)
    80004aea:	f8f94ee3          	blt	s2,a5,80004a86 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004aee:	00000097          	auipc	ra,0x0
    80004af2:	c6a080e7          	jalr	-918(ra) # 80004758 <write_head>
    install_trans(0); // Now install writes to home locations
    80004af6:	4501                	li	a0,0
    80004af8:	00000097          	auipc	ra,0x0
    80004afc:	cda080e7          	jalr	-806(ra) # 800047d2 <install_trans>
    log.lh.n = 0;
    80004b00:	0001d797          	auipc	a5,0x1d
    80004b04:	1607a223          	sw	zero,356(a5) # 80021c64 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004b08:	00000097          	auipc	ra,0x0
    80004b0c:	c50080e7          	jalr	-944(ra) # 80004758 <write_head>
    80004b10:	bdf5                	j	80004a0c <end_op+0x52>

0000000080004b12 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004b12:	1101                	addi	sp,sp,-32
    80004b14:	ec06                	sd	ra,24(sp)
    80004b16:	e822                	sd	s0,16(sp)
    80004b18:	e426                	sd	s1,8(sp)
    80004b1a:	e04a                	sd	s2,0(sp)
    80004b1c:	1000                	addi	s0,sp,32
    80004b1e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004b20:	0001d917          	auipc	s2,0x1d
    80004b24:	11890913          	addi	s2,s2,280 # 80021c38 <log>
    80004b28:	854a                	mv	a0,s2
    80004b2a:	ffffc097          	auipc	ra,0xffffc
    80004b2e:	0c2080e7          	jalr	194(ra) # 80000bec <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004b32:	02c92603          	lw	a2,44(s2)
    80004b36:	47f5                	li	a5,29
    80004b38:	06c7c563          	blt	a5,a2,80004ba2 <log_write+0x90>
    80004b3c:	0001d797          	auipc	a5,0x1d
    80004b40:	1187a783          	lw	a5,280(a5) # 80021c54 <log+0x1c>
    80004b44:	37fd                	addiw	a5,a5,-1
    80004b46:	04f65e63          	bge	a2,a5,80004ba2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004b4a:	0001d797          	auipc	a5,0x1d
    80004b4e:	10e7a783          	lw	a5,270(a5) # 80021c58 <log+0x20>
    80004b52:	06f05063          	blez	a5,80004bb2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004b56:	4781                	li	a5,0
    80004b58:	06c05563          	blez	a2,80004bc2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004b5c:	44cc                	lw	a1,12(s1)
    80004b5e:	0001d717          	auipc	a4,0x1d
    80004b62:	10a70713          	addi	a4,a4,266 # 80021c68 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004b66:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004b68:	4314                	lw	a3,0(a4)
    80004b6a:	04b68c63          	beq	a3,a1,80004bc2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004b6e:	2785                	addiw	a5,a5,1
    80004b70:	0711                	addi	a4,a4,4
    80004b72:	fef61be3          	bne	a2,a5,80004b68 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004b76:	0621                	addi	a2,a2,8
    80004b78:	060a                	slli	a2,a2,0x2
    80004b7a:	0001d797          	auipc	a5,0x1d
    80004b7e:	0be78793          	addi	a5,a5,190 # 80021c38 <log>
    80004b82:	963e                	add	a2,a2,a5
    80004b84:	44dc                	lw	a5,12(s1)
    80004b86:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004b88:	8526                	mv	a0,s1
    80004b8a:	fffff097          	auipc	ra,0xfffff
    80004b8e:	daa080e7          	jalr	-598(ra) # 80003934 <bpin>
    log.lh.n++;
    80004b92:	0001d717          	auipc	a4,0x1d
    80004b96:	0a670713          	addi	a4,a4,166 # 80021c38 <log>
    80004b9a:	575c                	lw	a5,44(a4)
    80004b9c:	2785                	addiw	a5,a5,1
    80004b9e:	d75c                	sw	a5,44(a4)
    80004ba0:	a835                	j	80004bdc <log_write+0xca>
    panic("too big a transaction");
    80004ba2:	00004517          	auipc	a0,0x4
    80004ba6:	ad650513          	addi	a0,a0,-1322 # 80008678 <syscalls+0x200>
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	994080e7          	jalr	-1644(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004bb2:	00004517          	auipc	a0,0x4
    80004bb6:	ade50513          	addi	a0,a0,-1314 # 80008690 <syscalls+0x218>
    80004bba:	ffffc097          	auipc	ra,0xffffc
    80004bbe:	984080e7          	jalr	-1660(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004bc2:	00878713          	addi	a4,a5,8
    80004bc6:	00271693          	slli	a3,a4,0x2
    80004bca:	0001d717          	auipc	a4,0x1d
    80004bce:	06e70713          	addi	a4,a4,110 # 80021c38 <log>
    80004bd2:	9736                	add	a4,a4,a3
    80004bd4:	44d4                	lw	a3,12(s1)
    80004bd6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004bd8:	faf608e3          	beq	a2,a5,80004b88 <log_write+0x76>
  }
  release(&log.lock);
    80004bdc:	0001d517          	auipc	a0,0x1d
    80004be0:	05c50513          	addi	a0,a0,92 # 80021c38 <log>
    80004be4:	ffffc097          	auipc	ra,0xffffc
    80004be8:	0d4080e7          	jalr	212(ra) # 80000cb8 <release>
}
    80004bec:	60e2                	ld	ra,24(sp)
    80004bee:	6442                	ld	s0,16(sp)
    80004bf0:	64a2                	ld	s1,8(sp)
    80004bf2:	6902                	ld	s2,0(sp)
    80004bf4:	6105                	addi	sp,sp,32
    80004bf6:	8082                	ret

0000000080004bf8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004bf8:	1101                	addi	sp,sp,-32
    80004bfa:	ec06                	sd	ra,24(sp)
    80004bfc:	e822                	sd	s0,16(sp)
    80004bfe:	e426                	sd	s1,8(sp)
    80004c00:	e04a                	sd	s2,0(sp)
    80004c02:	1000                	addi	s0,sp,32
    80004c04:	84aa                	mv	s1,a0
    80004c06:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004c08:	00004597          	auipc	a1,0x4
    80004c0c:	aa858593          	addi	a1,a1,-1368 # 800086b0 <syscalls+0x238>
    80004c10:	0521                	addi	a0,a0,8
    80004c12:	ffffc097          	auipc	ra,0xffffc
    80004c16:	f42080e7          	jalr	-190(ra) # 80000b54 <initlock>
  lk->name = name;
    80004c1a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004c1e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c22:	0204a423          	sw	zero,40(s1)
}
    80004c26:	60e2                	ld	ra,24(sp)
    80004c28:	6442                	ld	s0,16(sp)
    80004c2a:	64a2                	ld	s1,8(sp)
    80004c2c:	6902                	ld	s2,0(sp)
    80004c2e:	6105                	addi	sp,sp,32
    80004c30:	8082                	ret

0000000080004c32 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004c32:	1101                	addi	sp,sp,-32
    80004c34:	ec06                	sd	ra,24(sp)
    80004c36:	e822                	sd	s0,16(sp)
    80004c38:	e426                	sd	s1,8(sp)
    80004c3a:	e04a                	sd	s2,0(sp)
    80004c3c:	1000                	addi	s0,sp,32
    80004c3e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c40:	00850913          	addi	s2,a0,8
    80004c44:	854a                	mv	a0,s2
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	fa6080e7          	jalr	-90(ra) # 80000bec <acquire>
  while (lk->locked) {
    80004c4e:	409c                	lw	a5,0(s1)
    80004c50:	cb89                	beqz	a5,80004c62 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004c52:	85ca                	mv	a1,s2
    80004c54:	8526                	mv	a0,s1
    80004c56:	ffffe097          	auipc	ra,0xffffe
    80004c5a:	a94080e7          	jalr	-1388(ra) # 800026ea <sleep>
  while (lk->locked) {
    80004c5e:	409c                	lw	a5,0(s1)
    80004c60:	fbed                	bnez	a5,80004c52 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004c62:	4785                	li	a5,1
    80004c64:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004c66:	ffffd097          	auipc	ra,0xffffd
    80004c6a:	1f6080e7          	jalr	502(ra) # 80001e5c <myproc>
    80004c6e:	591c                	lw	a5,48(a0)
    80004c70:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004c72:	854a                	mv	a0,s2
    80004c74:	ffffc097          	auipc	ra,0xffffc
    80004c78:	044080e7          	jalr	68(ra) # 80000cb8 <release>
}
    80004c7c:	60e2                	ld	ra,24(sp)
    80004c7e:	6442                	ld	s0,16(sp)
    80004c80:	64a2                	ld	s1,8(sp)
    80004c82:	6902                	ld	s2,0(sp)
    80004c84:	6105                	addi	sp,sp,32
    80004c86:	8082                	ret

0000000080004c88 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004c88:	1101                	addi	sp,sp,-32
    80004c8a:	ec06                	sd	ra,24(sp)
    80004c8c:	e822                	sd	s0,16(sp)
    80004c8e:	e426                	sd	s1,8(sp)
    80004c90:	e04a                	sd	s2,0(sp)
    80004c92:	1000                	addi	s0,sp,32
    80004c94:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c96:	00850913          	addi	s2,a0,8
    80004c9a:	854a                	mv	a0,s2
    80004c9c:	ffffc097          	auipc	ra,0xffffc
    80004ca0:	f50080e7          	jalr	-176(ra) # 80000bec <acquire>
  lk->locked = 0;
    80004ca4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ca8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004cac:	8526                	mv	a0,s1
    80004cae:	ffffe097          	auipc	ra,0xffffe
    80004cb2:	d2e080e7          	jalr	-722(ra) # 800029dc <wakeup>
  release(&lk->lk);
    80004cb6:	854a                	mv	a0,s2
    80004cb8:	ffffc097          	auipc	ra,0xffffc
    80004cbc:	000080e7          	jalr	ra # 80000cb8 <release>
}
    80004cc0:	60e2                	ld	ra,24(sp)
    80004cc2:	6442                	ld	s0,16(sp)
    80004cc4:	64a2                	ld	s1,8(sp)
    80004cc6:	6902                	ld	s2,0(sp)
    80004cc8:	6105                	addi	sp,sp,32
    80004cca:	8082                	ret

0000000080004ccc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004ccc:	7179                	addi	sp,sp,-48
    80004cce:	f406                	sd	ra,40(sp)
    80004cd0:	f022                	sd	s0,32(sp)
    80004cd2:	ec26                	sd	s1,24(sp)
    80004cd4:	e84a                	sd	s2,16(sp)
    80004cd6:	e44e                	sd	s3,8(sp)
    80004cd8:	1800                	addi	s0,sp,48
    80004cda:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004cdc:	00850913          	addi	s2,a0,8
    80004ce0:	854a                	mv	a0,s2
    80004ce2:	ffffc097          	auipc	ra,0xffffc
    80004ce6:	f0a080e7          	jalr	-246(ra) # 80000bec <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004cea:	409c                	lw	a5,0(s1)
    80004cec:	ef99                	bnez	a5,80004d0a <holdingsleep+0x3e>
    80004cee:	4481                	li	s1,0
  release(&lk->lk);
    80004cf0:	854a                	mv	a0,s2
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	fc6080e7          	jalr	-58(ra) # 80000cb8 <release>
  return r;
}
    80004cfa:	8526                	mv	a0,s1
    80004cfc:	70a2                	ld	ra,40(sp)
    80004cfe:	7402                	ld	s0,32(sp)
    80004d00:	64e2                	ld	s1,24(sp)
    80004d02:	6942                	ld	s2,16(sp)
    80004d04:	69a2                	ld	s3,8(sp)
    80004d06:	6145                	addi	sp,sp,48
    80004d08:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004d0a:	0284a983          	lw	s3,40(s1)
    80004d0e:	ffffd097          	auipc	ra,0xffffd
    80004d12:	14e080e7          	jalr	334(ra) # 80001e5c <myproc>
    80004d16:	5904                	lw	s1,48(a0)
    80004d18:	413484b3          	sub	s1,s1,s3
    80004d1c:	0014b493          	seqz	s1,s1
    80004d20:	bfc1                	j	80004cf0 <holdingsleep+0x24>

0000000080004d22 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004d22:	1141                	addi	sp,sp,-16
    80004d24:	e406                	sd	ra,8(sp)
    80004d26:	e022                	sd	s0,0(sp)
    80004d28:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004d2a:	00004597          	auipc	a1,0x4
    80004d2e:	99658593          	addi	a1,a1,-1642 # 800086c0 <syscalls+0x248>
    80004d32:	0001d517          	auipc	a0,0x1d
    80004d36:	04e50513          	addi	a0,a0,78 # 80021d80 <ftable>
    80004d3a:	ffffc097          	auipc	ra,0xffffc
    80004d3e:	e1a080e7          	jalr	-486(ra) # 80000b54 <initlock>
}
    80004d42:	60a2                	ld	ra,8(sp)
    80004d44:	6402                	ld	s0,0(sp)
    80004d46:	0141                	addi	sp,sp,16
    80004d48:	8082                	ret

0000000080004d4a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004d4a:	1101                	addi	sp,sp,-32
    80004d4c:	ec06                	sd	ra,24(sp)
    80004d4e:	e822                	sd	s0,16(sp)
    80004d50:	e426                	sd	s1,8(sp)
    80004d52:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004d54:	0001d517          	auipc	a0,0x1d
    80004d58:	02c50513          	addi	a0,a0,44 # 80021d80 <ftable>
    80004d5c:	ffffc097          	auipc	ra,0xffffc
    80004d60:	e90080e7          	jalr	-368(ra) # 80000bec <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d64:	0001d497          	auipc	s1,0x1d
    80004d68:	03448493          	addi	s1,s1,52 # 80021d98 <ftable+0x18>
    80004d6c:	0001e717          	auipc	a4,0x1e
    80004d70:	fcc70713          	addi	a4,a4,-52 # 80022d38 <ftable+0xfb8>
    if(f->ref == 0){
    80004d74:	40dc                	lw	a5,4(s1)
    80004d76:	cf99                	beqz	a5,80004d94 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d78:	02848493          	addi	s1,s1,40
    80004d7c:	fee49ce3          	bne	s1,a4,80004d74 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004d80:	0001d517          	auipc	a0,0x1d
    80004d84:	00050513          	mv	a0,a0
    80004d88:	ffffc097          	auipc	ra,0xffffc
    80004d8c:	f30080e7          	jalr	-208(ra) # 80000cb8 <release>
  return 0;
    80004d90:	4481                	li	s1,0
    80004d92:	a819                	j	80004da8 <filealloc+0x5e>
      f->ref = 1;
    80004d94:	4785                	li	a5,1
    80004d96:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004d98:	0001d517          	auipc	a0,0x1d
    80004d9c:	fe850513          	addi	a0,a0,-24 # 80021d80 <ftable>
    80004da0:	ffffc097          	auipc	ra,0xffffc
    80004da4:	f18080e7          	jalr	-232(ra) # 80000cb8 <release>
}
    80004da8:	8526                	mv	a0,s1
    80004daa:	60e2                	ld	ra,24(sp)
    80004dac:	6442                	ld	s0,16(sp)
    80004dae:	64a2                	ld	s1,8(sp)
    80004db0:	6105                	addi	sp,sp,32
    80004db2:	8082                	ret

0000000080004db4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004db4:	1101                	addi	sp,sp,-32
    80004db6:	ec06                	sd	ra,24(sp)
    80004db8:	e822                	sd	s0,16(sp)
    80004dba:	e426                	sd	s1,8(sp)
    80004dbc:	1000                	addi	s0,sp,32
    80004dbe:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004dc0:	0001d517          	auipc	a0,0x1d
    80004dc4:	fc050513          	addi	a0,a0,-64 # 80021d80 <ftable>
    80004dc8:	ffffc097          	auipc	ra,0xffffc
    80004dcc:	e24080e7          	jalr	-476(ra) # 80000bec <acquire>
  if(f->ref < 1)
    80004dd0:	40dc                	lw	a5,4(s1)
    80004dd2:	02f05263          	blez	a5,80004df6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004dd6:	2785                	addiw	a5,a5,1
    80004dd8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004dda:	0001d517          	auipc	a0,0x1d
    80004dde:	fa650513          	addi	a0,a0,-90 # 80021d80 <ftable>
    80004de2:	ffffc097          	auipc	ra,0xffffc
    80004de6:	ed6080e7          	jalr	-298(ra) # 80000cb8 <release>
  return f;
}
    80004dea:	8526                	mv	a0,s1
    80004dec:	60e2                	ld	ra,24(sp)
    80004dee:	6442                	ld	s0,16(sp)
    80004df0:	64a2                	ld	s1,8(sp)
    80004df2:	6105                	addi	sp,sp,32
    80004df4:	8082                	ret
    panic("filedup");
    80004df6:	00004517          	auipc	a0,0x4
    80004dfa:	8d250513          	addi	a0,a0,-1838 # 800086c8 <syscalls+0x250>
    80004dfe:	ffffb097          	auipc	ra,0xffffb
    80004e02:	740080e7          	jalr	1856(ra) # 8000053e <panic>

0000000080004e06 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004e06:	7139                	addi	sp,sp,-64
    80004e08:	fc06                	sd	ra,56(sp)
    80004e0a:	f822                	sd	s0,48(sp)
    80004e0c:	f426                	sd	s1,40(sp)
    80004e0e:	f04a                	sd	s2,32(sp)
    80004e10:	ec4e                	sd	s3,24(sp)
    80004e12:	e852                	sd	s4,16(sp)
    80004e14:	e456                	sd	s5,8(sp)
    80004e16:	0080                	addi	s0,sp,64
    80004e18:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004e1a:	0001d517          	auipc	a0,0x1d
    80004e1e:	f6650513          	addi	a0,a0,-154 # 80021d80 <ftable>
    80004e22:	ffffc097          	auipc	ra,0xffffc
    80004e26:	dca080e7          	jalr	-566(ra) # 80000bec <acquire>
  if(f->ref < 1)
    80004e2a:	40dc                	lw	a5,4(s1)
    80004e2c:	06f05163          	blez	a5,80004e8e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004e30:	37fd                	addiw	a5,a5,-1
    80004e32:	0007871b          	sext.w	a4,a5
    80004e36:	c0dc                	sw	a5,4(s1)
    80004e38:	06e04363          	bgtz	a4,80004e9e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004e3c:	0004a903          	lw	s2,0(s1)
    80004e40:	0094ca83          	lbu	s5,9(s1)
    80004e44:	0104ba03          	ld	s4,16(s1)
    80004e48:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004e4c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004e50:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004e54:	0001d517          	auipc	a0,0x1d
    80004e58:	f2c50513          	addi	a0,a0,-212 # 80021d80 <ftable>
    80004e5c:	ffffc097          	auipc	ra,0xffffc
    80004e60:	e5c080e7          	jalr	-420(ra) # 80000cb8 <release>

  if(ff.type == FD_PIPE){
    80004e64:	4785                	li	a5,1
    80004e66:	04f90d63          	beq	s2,a5,80004ec0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004e6a:	3979                	addiw	s2,s2,-2
    80004e6c:	4785                	li	a5,1
    80004e6e:	0527e063          	bltu	a5,s2,80004eae <fileclose+0xa8>
    begin_op();
    80004e72:	00000097          	auipc	ra,0x0
    80004e76:	ac8080e7          	jalr	-1336(ra) # 8000493a <begin_op>
    iput(ff.ip);
    80004e7a:	854e                	mv	a0,s3
    80004e7c:	fffff097          	auipc	ra,0xfffff
    80004e80:	2a6080e7          	jalr	678(ra) # 80004122 <iput>
    end_op();
    80004e84:	00000097          	auipc	ra,0x0
    80004e88:	b36080e7          	jalr	-1226(ra) # 800049ba <end_op>
    80004e8c:	a00d                	j	80004eae <fileclose+0xa8>
    panic("fileclose");
    80004e8e:	00004517          	auipc	a0,0x4
    80004e92:	84250513          	addi	a0,a0,-1982 # 800086d0 <syscalls+0x258>
    80004e96:	ffffb097          	auipc	ra,0xffffb
    80004e9a:	6a8080e7          	jalr	1704(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004e9e:	0001d517          	auipc	a0,0x1d
    80004ea2:	ee250513          	addi	a0,a0,-286 # 80021d80 <ftable>
    80004ea6:	ffffc097          	auipc	ra,0xffffc
    80004eaa:	e12080e7          	jalr	-494(ra) # 80000cb8 <release>
  }
}
    80004eae:	70e2                	ld	ra,56(sp)
    80004eb0:	7442                	ld	s0,48(sp)
    80004eb2:	74a2                	ld	s1,40(sp)
    80004eb4:	7902                	ld	s2,32(sp)
    80004eb6:	69e2                	ld	s3,24(sp)
    80004eb8:	6a42                	ld	s4,16(sp)
    80004eba:	6aa2                	ld	s5,8(sp)
    80004ebc:	6121                	addi	sp,sp,64
    80004ebe:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004ec0:	85d6                	mv	a1,s5
    80004ec2:	8552                	mv	a0,s4
    80004ec4:	00000097          	auipc	ra,0x0
    80004ec8:	34c080e7          	jalr	844(ra) # 80005210 <pipeclose>
    80004ecc:	b7cd                	j	80004eae <fileclose+0xa8>

0000000080004ece <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ece:	715d                	addi	sp,sp,-80
    80004ed0:	e486                	sd	ra,72(sp)
    80004ed2:	e0a2                	sd	s0,64(sp)
    80004ed4:	fc26                	sd	s1,56(sp)
    80004ed6:	f84a                	sd	s2,48(sp)
    80004ed8:	f44e                	sd	s3,40(sp)
    80004eda:	0880                	addi	s0,sp,80
    80004edc:	84aa                	mv	s1,a0
    80004ede:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ee0:	ffffd097          	auipc	ra,0xffffd
    80004ee4:	f7c080e7          	jalr	-132(ra) # 80001e5c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004ee8:	409c                	lw	a5,0(s1)
    80004eea:	37f9                	addiw	a5,a5,-2
    80004eec:	4705                	li	a4,1
    80004eee:	04f76763          	bltu	a4,a5,80004f3c <filestat+0x6e>
    80004ef2:	892a                	mv	s2,a0
    ilock(f->ip);
    80004ef4:	6c88                	ld	a0,24(s1)
    80004ef6:	fffff097          	auipc	ra,0xfffff
    80004efa:	072080e7          	jalr	114(ra) # 80003f68 <ilock>
    stati(f->ip, &st);
    80004efe:	fb840593          	addi	a1,s0,-72
    80004f02:	6c88                	ld	a0,24(s1)
    80004f04:	fffff097          	auipc	ra,0xfffff
    80004f08:	2ee080e7          	jalr	750(ra) # 800041f2 <stati>
    iunlock(f->ip);
    80004f0c:	6c88                	ld	a0,24(s1)
    80004f0e:	fffff097          	auipc	ra,0xfffff
    80004f12:	11c080e7          	jalr	284(ra) # 8000402a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004f16:	46e1                	li	a3,24
    80004f18:	fb840613          	addi	a2,s0,-72
    80004f1c:	85ce                	mv	a1,s3
    80004f1e:	07093503          	ld	a0,112(s2)
    80004f22:	ffffc097          	auipc	ra,0xffffc
    80004f26:	782080e7          	jalr	1922(ra) # 800016a4 <copyout>
    80004f2a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004f2e:	60a6                	ld	ra,72(sp)
    80004f30:	6406                	ld	s0,64(sp)
    80004f32:	74e2                	ld	s1,56(sp)
    80004f34:	7942                	ld	s2,48(sp)
    80004f36:	79a2                	ld	s3,40(sp)
    80004f38:	6161                	addi	sp,sp,80
    80004f3a:	8082                	ret
  return -1;
    80004f3c:	557d                	li	a0,-1
    80004f3e:	bfc5                	j	80004f2e <filestat+0x60>

0000000080004f40 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004f40:	7179                	addi	sp,sp,-48
    80004f42:	f406                	sd	ra,40(sp)
    80004f44:	f022                	sd	s0,32(sp)
    80004f46:	ec26                	sd	s1,24(sp)
    80004f48:	e84a                	sd	s2,16(sp)
    80004f4a:	e44e                	sd	s3,8(sp)
    80004f4c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004f4e:	00854783          	lbu	a5,8(a0)
    80004f52:	c3d5                	beqz	a5,80004ff6 <fileread+0xb6>
    80004f54:	84aa                	mv	s1,a0
    80004f56:	89ae                	mv	s3,a1
    80004f58:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f5a:	411c                	lw	a5,0(a0)
    80004f5c:	4705                	li	a4,1
    80004f5e:	04e78963          	beq	a5,a4,80004fb0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f62:	470d                	li	a4,3
    80004f64:	04e78d63          	beq	a5,a4,80004fbe <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f68:	4709                	li	a4,2
    80004f6a:	06e79e63          	bne	a5,a4,80004fe6 <fileread+0xa6>
    ilock(f->ip);
    80004f6e:	6d08                	ld	a0,24(a0)
    80004f70:	fffff097          	auipc	ra,0xfffff
    80004f74:	ff8080e7          	jalr	-8(ra) # 80003f68 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004f78:	874a                	mv	a4,s2
    80004f7a:	5094                	lw	a3,32(s1)
    80004f7c:	864e                	mv	a2,s3
    80004f7e:	4585                	li	a1,1
    80004f80:	6c88                	ld	a0,24(s1)
    80004f82:	fffff097          	auipc	ra,0xfffff
    80004f86:	29a080e7          	jalr	666(ra) # 8000421c <readi>
    80004f8a:	892a                	mv	s2,a0
    80004f8c:	00a05563          	blez	a0,80004f96 <fileread+0x56>
      f->off += r;
    80004f90:	509c                	lw	a5,32(s1)
    80004f92:	9fa9                	addw	a5,a5,a0
    80004f94:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004f96:	6c88                	ld	a0,24(s1)
    80004f98:	fffff097          	auipc	ra,0xfffff
    80004f9c:	092080e7          	jalr	146(ra) # 8000402a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004fa0:	854a                	mv	a0,s2
    80004fa2:	70a2                	ld	ra,40(sp)
    80004fa4:	7402                	ld	s0,32(sp)
    80004fa6:	64e2                	ld	s1,24(sp)
    80004fa8:	6942                	ld	s2,16(sp)
    80004faa:	69a2                	ld	s3,8(sp)
    80004fac:	6145                	addi	sp,sp,48
    80004fae:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004fb0:	6908                	ld	a0,16(a0)
    80004fb2:	00000097          	auipc	ra,0x0
    80004fb6:	3c8080e7          	jalr	968(ra) # 8000537a <piperead>
    80004fba:	892a                	mv	s2,a0
    80004fbc:	b7d5                	j	80004fa0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004fbe:	02451783          	lh	a5,36(a0)
    80004fc2:	03079693          	slli	a3,a5,0x30
    80004fc6:	92c1                	srli	a3,a3,0x30
    80004fc8:	4725                	li	a4,9
    80004fca:	02d76863          	bltu	a4,a3,80004ffa <fileread+0xba>
    80004fce:	0792                	slli	a5,a5,0x4
    80004fd0:	0001d717          	auipc	a4,0x1d
    80004fd4:	d1070713          	addi	a4,a4,-752 # 80021ce0 <devsw>
    80004fd8:	97ba                	add	a5,a5,a4
    80004fda:	639c                	ld	a5,0(a5)
    80004fdc:	c38d                	beqz	a5,80004ffe <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004fde:	4505                	li	a0,1
    80004fe0:	9782                	jalr	a5
    80004fe2:	892a                	mv	s2,a0
    80004fe4:	bf75                	j	80004fa0 <fileread+0x60>
    panic("fileread");
    80004fe6:	00003517          	auipc	a0,0x3
    80004fea:	6fa50513          	addi	a0,a0,1786 # 800086e0 <syscalls+0x268>
    80004fee:	ffffb097          	auipc	ra,0xffffb
    80004ff2:	550080e7          	jalr	1360(ra) # 8000053e <panic>
    return -1;
    80004ff6:	597d                	li	s2,-1
    80004ff8:	b765                	j	80004fa0 <fileread+0x60>
      return -1;
    80004ffa:	597d                	li	s2,-1
    80004ffc:	b755                	j	80004fa0 <fileread+0x60>
    80004ffe:	597d                	li	s2,-1
    80005000:	b745                	j	80004fa0 <fileread+0x60>

0000000080005002 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005002:	715d                	addi	sp,sp,-80
    80005004:	e486                	sd	ra,72(sp)
    80005006:	e0a2                	sd	s0,64(sp)
    80005008:	fc26                	sd	s1,56(sp)
    8000500a:	f84a                	sd	s2,48(sp)
    8000500c:	f44e                	sd	s3,40(sp)
    8000500e:	f052                	sd	s4,32(sp)
    80005010:	ec56                	sd	s5,24(sp)
    80005012:	e85a                	sd	s6,16(sp)
    80005014:	e45e                	sd	s7,8(sp)
    80005016:	e062                	sd	s8,0(sp)
    80005018:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000501a:	00954783          	lbu	a5,9(a0)
    8000501e:	10078663          	beqz	a5,8000512a <filewrite+0x128>
    80005022:	892a                	mv	s2,a0
    80005024:	8aae                	mv	s5,a1
    80005026:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005028:	411c                	lw	a5,0(a0)
    8000502a:	4705                	li	a4,1
    8000502c:	02e78263          	beq	a5,a4,80005050 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005030:	470d                	li	a4,3
    80005032:	02e78663          	beq	a5,a4,8000505e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005036:	4709                	li	a4,2
    80005038:	0ee79163          	bne	a5,a4,8000511a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000503c:	0ac05d63          	blez	a2,800050f6 <filewrite+0xf4>
    int i = 0;
    80005040:	4981                	li	s3,0
    80005042:	6b05                	lui	s6,0x1
    80005044:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005048:	6b85                	lui	s7,0x1
    8000504a:	c00b8b9b          	addiw	s7,s7,-1024
    8000504e:	a861                	j	800050e6 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005050:	6908                	ld	a0,16(a0)
    80005052:	00000097          	auipc	ra,0x0
    80005056:	22e080e7          	jalr	558(ra) # 80005280 <pipewrite>
    8000505a:	8a2a                	mv	s4,a0
    8000505c:	a045                	j	800050fc <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000505e:	02451783          	lh	a5,36(a0)
    80005062:	03079693          	slli	a3,a5,0x30
    80005066:	92c1                	srli	a3,a3,0x30
    80005068:	4725                	li	a4,9
    8000506a:	0cd76263          	bltu	a4,a3,8000512e <filewrite+0x12c>
    8000506e:	0792                	slli	a5,a5,0x4
    80005070:	0001d717          	auipc	a4,0x1d
    80005074:	c7070713          	addi	a4,a4,-912 # 80021ce0 <devsw>
    80005078:	97ba                	add	a5,a5,a4
    8000507a:	679c                	ld	a5,8(a5)
    8000507c:	cbdd                	beqz	a5,80005132 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000507e:	4505                	li	a0,1
    80005080:	9782                	jalr	a5
    80005082:	8a2a                	mv	s4,a0
    80005084:	a8a5                	j	800050fc <filewrite+0xfa>
    80005086:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000508a:	00000097          	auipc	ra,0x0
    8000508e:	8b0080e7          	jalr	-1872(ra) # 8000493a <begin_op>
      ilock(f->ip);
    80005092:	01893503          	ld	a0,24(s2)
    80005096:	fffff097          	auipc	ra,0xfffff
    8000509a:	ed2080e7          	jalr	-302(ra) # 80003f68 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000509e:	8762                	mv	a4,s8
    800050a0:	02092683          	lw	a3,32(s2)
    800050a4:	01598633          	add	a2,s3,s5
    800050a8:	4585                	li	a1,1
    800050aa:	01893503          	ld	a0,24(s2)
    800050ae:	fffff097          	auipc	ra,0xfffff
    800050b2:	266080e7          	jalr	614(ra) # 80004314 <writei>
    800050b6:	84aa                	mv	s1,a0
    800050b8:	00a05763          	blez	a0,800050c6 <filewrite+0xc4>
        f->off += r;
    800050bc:	02092783          	lw	a5,32(s2)
    800050c0:	9fa9                	addw	a5,a5,a0
    800050c2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800050c6:	01893503          	ld	a0,24(s2)
    800050ca:	fffff097          	auipc	ra,0xfffff
    800050ce:	f60080e7          	jalr	-160(ra) # 8000402a <iunlock>
      end_op();
    800050d2:	00000097          	auipc	ra,0x0
    800050d6:	8e8080e7          	jalr	-1816(ra) # 800049ba <end_op>

      if(r != n1){
    800050da:	009c1f63          	bne	s8,s1,800050f8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800050de:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800050e2:	0149db63          	bge	s3,s4,800050f8 <filewrite+0xf6>
      int n1 = n - i;
    800050e6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800050ea:	84be                	mv	s1,a5
    800050ec:	2781                	sext.w	a5,a5
    800050ee:	f8fb5ce3          	bge	s6,a5,80005086 <filewrite+0x84>
    800050f2:	84de                	mv	s1,s7
    800050f4:	bf49                	j	80005086 <filewrite+0x84>
    int i = 0;
    800050f6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800050f8:	013a1f63          	bne	s4,s3,80005116 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800050fc:	8552                	mv	a0,s4
    800050fe:	60a6                	ld	ra,72(sp)
    80005100:	6406                	ld	s0,64(sp)
    80005102:	74e2                	ld	s1,56(sp)
    80005104:	7942                	ld	s2,48(sp)
    80005106:	79a2                	ld	s3,40(sp)
    80005108:	7a02                	ld	s4,32(sp)
    8000510a:	6ae2                	ld	s5,24(sp)
    8000510c:	6b42                	ld	s6,16(sp)
    8000510e:	6ba2                	ld	s7,8(sp)
    80005110:	6c02                	ld	s8,0(sp)
    80005112:	6161                	addi	sp,sp,80
    80005114:	8082                	ret
    ret = (i == n ? n : -1);
    80005116:	5a7d                	li	s4,-1
    80005118:	b7d5                	j	800050fc <filewrite+0xfa>
    panic("filewrite");
    8000511a:	00003517          	auipc	a0,0x3
    8000511e:	5d650513          	addi	a0,a0,1494 # 800086f0 <syscalls+0x278>
    80005122:	ffffb097          	auipc	ra,0xffffb
    80005126:	41c080e7          	jalr	1052(ra) # 8000053e <panic>
    return -1;
    8000512a:	5a7d                	li	s4,-1
    8000512c:	bfc1                	j	800050fc <filewrite+0xfa>
      return -1;
    8000512e:	5a7d                	li	s4,-1
    80005130:	b7f1                	j	800050fc <filewrite+0xfa>
    80005132:	5a7d                	li	s4,-1
    80005134:	b7e1                	j	800050fc <filewrite+0xfa>

0000000080005136 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005136:	7179                	addi	sp,sp,-48
    80005138:	f406                	sd	ra,40(sp)
    8000513a:	f022                	sd	s0,32(sp)
    8000513c:	ec26                	sd	s1,24(sp)
    8000513e:	e84a                	sd	s2,16(sp)
    80005140:	e44e                	sd	s3,8(sp)
    80005142:	e052                	sd	s4,0(sp)
    80005144:	1800                	addi	s0,sp,48
    80005146:	84aa                	mv	s1,a0
    80005148:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000514a:	0005b023          	sd	zero,0(a1)
    8000514e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005152:	00000097          	auipc	ra,0x0
    80005156:	bf8080e7          	jalr	-1032(ra) # 80004d4a <filealloc>
    8000515a:	e088                	sd	a0,0(s1)
    8000515c:	c551                	beqz	a0,800051e8 <pipealloc+0xb2>
    8000515e:	00000097          	auipc	ra,0x0
    80005162:	bec080e7          	jalr	-1044(ra) # 80004d4a <filealloc>
    80005166:	00aa3023          	sd	a0,0(s4)
    8000516a:	c92d                	beqz	a0,800051dc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000516c:	ffffc097          	auipc	ra,0xffffc
    80005170:	988080e7          	jalr	-1656(ra) # 80000af4 <kalloc>
    80005174:	892a                	mv	s2,a0
    80005176:	c125                	beqz	a0,800051d6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005178:	4985                	li	s3,1
    8000517a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000517e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005182:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005186:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000518a:	00003597          	auipc	a1,0x3
    8000518e:	57658593          	addi	a1,a1,1398 # 80008700 <syscalls+0x288>
    80005192:	ffffc097          	auipc	ra,0xffffc
    80005196:	9c2080e7          	jalr	-1598(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000519a:	609c                	ld	a5,0(s1)
    8000519c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800051a0:	609c                	ld	a5,0(s1)
    800051a2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800051a6:	609c                	ld	a5,0(s1)
    800051a8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800051ac:	609c                	ld	a5,0(s1)
    800051ae:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800051b2:	000a3783          	ld	a5,0(s4)
    800051b6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800051ba:	000a3783          	ld	a5,0(s4)
    800051be:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800051c2:	000a3783          	ld	a5,0(s4)
    800051c6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800051ca:	000a3783          	ld	a5,0(s4)
    800051ce:	0127b823          	sd	s2,16(a5)
  return 0;
    800051d2:	4501                	li	a0,0
    800051d4:	a025                	j	800051fc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800051d6:	6088                	ld	a0,0(s1)
    800051d8:	e501                	bnez	a0,800051e0 <pipealloc+0xaa>
    800051da:	a039                	j	800051e8 <pipealloc+0xb2>
    800051dc:	6088                	ld	a0,0(s1)
    800051de:	c51d                	beqz	a0,8000520c <pipealloc+0xd6>
    fileclose(*f0);
    800051e0:	00000097          	auipc	ra,0x0
    800051e4:	c26080e7          	jalr	-986(ra) # 80004e06 <fileclose>
  if(*f1)
    800051e8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800051ec:	557d                	li	a0,-1
  if(*f1)
    800051ee:	c799                	beqz	a5,800051fc <pipealloc+0xc6>
    fileclose(*f1);
    800051f0:	853e                	mv	a0,a5
    800051f2:	00000097          	auipc	ra,0x0
    800051f6:	c14080e7          	jalr	-1004(ra) # 80004e06 <fileclose>
  return -1;
    800051fa:	557d                	li	a0,-1
}
    800051fc:	70a2                	ld	ra,40(sp)
    800051fe:	7402                	ld	s0,32(sp)
    80005200:	64e2                	ld	s1,24(sp)
    80005202:	6942                	ld	s2,16(sp)
    80005204:	69a2                	ld	s3,8(sp)
    80005206:	6a02                	ld	s4,0(sp)
    80005208:	6145                	addi	sp,sp,48
    8000520a:	8082                	ret
  return -1;
    8000520c:	557d                	li	a0,-1
    8000520e:	b7fd                	j	800051fc <pipealloc+0xc6>

0000000080005210 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005210:	1101                	addi	sp,sp,-32
    80005212:	ec06                	sd	ra,24(sp)
    80005214:	e822                	sd	s0,16(sp)
    80005216:	e426                	sd	s1,8(sp)
    80005218:	e04a                	sd	s2,0(sp)
    8000521a:	1000                	addi	s0,sp,32
    8000521c:	84aa                	mv	s1,a0
    8000521e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005220:	ffffc097          	auipc	ra,0xffffc
    80005224:	9cc080e7          	jalr	-1588(ra) # 80000bec <acquire>
  if(writable){
    80005228:	02090d63          	beqz	s2,80005262 <pipeclose+0x52>
    pi->writeopen = 0;
    8000522c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005230:	21848513          	addi	a0,s1,536
    80005234:	ffffd097          	auipc	ra,0xffffd
    80005238:	7a8080e7          	jalr	1960(ra) # 800029dc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000523c:	2204b783          	ld	a5,544(s1)
    80005240:	eb95                	bnez	a5,80005274 <pipeclose+0x64>
    release(&pi->lock);
    80005242:	8526                	mv	a0,s1
    80005244:	ffffc097          	auipc	ra,0xffffc
    80005248:	a74080e7          	jalr	-1420(ra) # 80000cb8 <release>
    kfree((char*)pi);
    8000524c:	8526                	mv	a0,s1
    8000524e:	ffffb097          	auipc	ra,0xffffb
    80005252:	7aa080e7          	jalr	1962(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80005256:	60e2                	ld	ra,24(sp)
    80005258:	6442                	ld	s0,16(sp)
    8000525a:	64a2                	ld	s1,8(sp)
    8000525c:	6902                	ld	s2,0(sp)
    8000525e:	6105                	addi	sp,sp,32
    80005260:	8082                	ret
    pi->readopen = 0;
    80005262:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005266:	21c48513          	addi	a0,s1,540
    8000526a:	ffffd097          	auipc	ra,0xffffd
    8000526e:	772080e7          	jalr	1906(ra) # 800029dc <wakeup>
    80005272:	b7e9                	j	8000523c <pipeclose+0x2c>
    release(&pi->lock);
    80005274:	8526                	mv	a0,s1
    80005276:	ffffc097          	auipc	ra,0xffffc
    8000527a:	a42080e7          	jalr	-1470(ra) # 80000cb8 <release>
}
    8000527e:	bfe1                	j	80005256 <pipeclose+0x46>

0000000080005280 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005280:	7159                	addi	sp,sp,-112
    80005282:	f486                	sd	ra,104(sp)
    80005284:	f0a2                	sd	s0,96(sp)
    80005286:	eca6                	sd	s1,88(sp)
    80005288:	e8ca                	sd	s2,80(sp)
    8000528a:	e4ce                	sd	s3,72(sp)
    8000528c:	e0d2                	sd	s4,64(sp)
    8000528e:	fc56                	sd	s5,56(sp)
    80005290:	f85a                	sd	s6,48(sp)
    80005292:	f45e                	sd	s7,40(sp)
    80005294:	f062                	sd	s8,32(sp)
    80005296:	ec66                	sd	s9,24(sp)
    80005298:	1880                	addi	s0,sp,112
    8000529a:	84aa                	mv	s1,a0
    8000529c:	8aae                	mv	s5,a1
    8000529e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800052a0:	ffffd097          	auipc	ra,0xffffd
    800052a4:	bbc080e7          	jalr	-1092(ra) # 80001e5c <myproc>
    800052a8:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800052aa:	8526                	mv	a0,s1
    800052ac:	ffffc097          	auipc	ra,0xffffc
    800052b0:	940080e7          	jalr	-1728(ra) # 80000bec <acquire>
  while(i < n){
    800052b4:	0d405163          	blez	s4,80005376 <pipewrite+0xf6>
    800052b8:	8ba6                	mv	s7,s1
  int i = 0;
    800052ba:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800052bc:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800052be:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800052c2:	21c48c13          	addi	s8,s1,540
    800052c6:	a08d                	j	80005328 <pipewrite+0xa8>
      release(&pi->lock);
    800052c8:	8526                	mv	a0,s1
    800052ca:	ffffc097          	auipc	ra,0xffffc
    800052ce:	9ee080e7          	jalr	-1554(ra) # 80000cb8 <release>
      return -1;
    800052d2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800052d4:	854a                	mv	a0,s2
    800052d6:	70a6                	ld	ra,104(sp)
    800052d8:	7406                	ld	s0,96(sp)
    800052da:	64e6                	ld	s1,88(sp)
    800052dc:	6946                	ld	s2,80(sp)
    800052de:	69a6                	ld	s3,72(sp)
    800052e0:	6a06                	ld	s4,64(sp)
    800052e2:	7ae2                	ld	s5,56(sp)
    800052e4:	7b42                	ld	s6,48(sp)
    800052e6:	7ba2                	ld	s7,40(sp)
    800052e8:	7c02                	ld	s8,32(sp)
    800052ea:	6ce2                	ld	s9,24(sp)
    800052ec:	6165                	addi	sp,sp,112
    800052ee:	8082                	ret
      wakeup(&pi->nread);
    800052f0:	8566                	mv	a0,s9
    800052f2:	ffffd097          	auipc	ra,0xffffd
    800052f6:	6ea080e7          	jalr	1770(ra) # 800029dc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800052fa:	85de                	mv	a1,s7
    800052fc:	8562                	mv	a0,s8
    800052fe:	ffffd097          	auipc	ra,0xffffd
    80005302:	3ec080e7          	jalr	1004(ra) # 800026ea <sleep>
    80005306:	a839                	j	80005324 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005308:	21c4a783          	lw	a5,540(s1)
    8000530c:	0017871b          	addiw	a4,a5,1
    80005310:	20e4ae23          	sw	a4,540(s1)
    80005314:	1ff7f793          	andi	a5,a5,511
    80005318:	97a6                	add	a5,a5,s1
    8000531a:	f9f44703          	lbu	a4,-97(s0)
    8000531e:	00e78c23          	sb	a4,24(a5)
      i++;
    80005322:	2905                	addiw	s2,s2,1
  while(i < n){
    80005324:	03495d63          	bge	s2,s4,8000535e <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005328:	2204a783          	lw	a5,544(s1)
    8000532c:	dfd1                	beqz	a5,800052c8 <pipewrite+0x48>
    8000532e:	0289a783          	lw	a5,40(s3)
    80005332:	fbd9                	bnez	a5,800052c8 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005334:	2184a783          	lw	a5,536(s1)
    80005338:	21c4a703          	lw	a4,540(s1)
    8000533c:	2007879b          	addiw	a5,a5,512
    80005340:	faf708e3          	beq	a4,a5,800052f0 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005344:	4685                	li	a3,1
    80005346:	01590633          	add	a2,s2,s5
    8000534a:	f9f40593          	addi	a1,s0,-97
    8000534e:	0709b503          	ld	a0,112(s3)
    80005352:	ffffc097          	auipc	ra,0xffffc
    80005356:	3de080e7          	jalr	990(ra) # 80001730 <copyin>
    8000535a:	fb6517e3          	bne	a0,s6,80005308 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000535e:	21848513          	addi	a0,s1,536
    80005362:	ffffd097          	auipc	ra,0xffffd
    80005366:	67a080e7          	jalr	1658(ra) # 800029dc <wakeup>
  release(&pi->lock);
    8000536a:	8526                	mv	a0,s1
    8000536c:	ffffc097          	auipc	ra,0xffffc
    80005370:	94c080e7          	jalr	-1716(ra) # 80000cb8 <release>
  return i;
    80005374:	b785                	j	800052d4 <pipewrite+0x54>
  int i = 0;
    80005376:	4901                	li	s2,0
    80005378:	b7dd                	j	8000535e <pipewrite+0xde>

000000008000537a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000537a:	715d                	addi	sp,sp,-80
    8000537c:	e486                	sd	ra,72(sp)
    8000537e:	e0a2                	sd	s0,64(sp)
    80005380:	fc26                	sd	s1,56(sp)
    80005382:	f84a                	sd	s2,48(sp)
    80005384:	f44e                	sd	s3,40(sp)
    80005386:	f052                	sd	s4,32(sp)
    80005388:	ec56                	sd	s5,24(sp)
    8000538a:	e85a                	sd	s6,16(sp)
    8000538c:	0880                	addi	s0,sp,80
    8000538e:	84aa                	mv	s1,a0
    80005390:	892e                	mv	s2,a1
    80005392:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005394:	ffffd097          	auipc	ra,0xffffd
    80005398:	ac8080e7          	jalr	-1336(ra) # 80001e5c <myproc>
    8000539c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000539e:	8b26                	mv	s6,s1
    800053a0:	8526                	mv	a0,s1
    800053a2:	ffffc097          	auipc	ra,0xffffc
    800053a6:	84a080e7          	jalr	-1974(ra) # 80000bec <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800053aa:	2184a703          	lw	a4,536(s1)
    800053ae:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800053b2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800053b6:	02f71463          	bne	a4,a5,800053de <piperead+0x64>
    800053ba:	2244a783          	lw	a5,548(s1)
    800053be:	c385                	beqz	a5,800053de <piperead+0x64>
    if(pr->killed){
    800053c0:	028a2783          	lw	a5,40(s4)
    800053c4:	ebc1                	bnez	a5,80005454 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800053c6:	85da                	mv	a1,s6
    800053c8:	854e                	mv	a0,s3
    800053ca:	ffffd097          	auipc	ra,0xffffd
    800053ce:	320080e7          	jalr	800(ra) # 800026ea <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800053d2:	2184a703          	lw	a4,536(s1)
    800053d6:	21c4a783          	lw	a5,540(s1)
    800053da:	fef700e3          	beq	a4,a5,800053ba <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053de:	09505263          	blez	s5,80005462 <piperead+0xe8>
    800053e2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800053e4:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800053e6:	2184a783          	lw	a5,536(s1)
    800053ea:	21c4a703          	lw	a4,540(s1)
    800053ee:	02f70d63          	beq	a4,a5,80005428 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800053f2:	0017871b          	addiw	a4,a5,1
    800053f6:	20e4ac23          	sw	a4,536(s1)
    800053fa:	1ff7f793          	andi	a5,a5,511
    800053fe:	97a6                	add	a5,a5,s1
    80005400:	0187c783          	lbu	a5,24(a5)
    80005404:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005408:	4685                	li	a3,1
    8000540a:	fbf40613          	addi	a2,s0,-65
    8000540e:	85ca                	mv	a1,s2
    80005410:	070a3503          	ld	a0,112(s4)
    80005414:	ffffc097          	auipc	ra,0xffffc
    80005418:	290080e7          	jalr	656(ra) # 800016a4 <copyout>
    8000541c:	01650663          	beq	a0,s6,80005428 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005420:	2985                	addiw	s3,s3,1
    80005422:	0905                	addi	s2,s2,1
    80005424:	fd3a91e3          	bne	s5,s3,800053e6 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005428:	21c48513          	addi	a0,s1,540
    8000542c:	ffffd097          	auipc	ra,0xffffd
    80005430:	5b0080e7          	jalr	1456(ra) # 800029dc <wakeup>
  release(&pi->lock);
    80005434:	8526                	mv	a0,s1
    80005436:	ffffc097          	auipc	ra,0xffffc
    8000543a:	882080e7          	jalr	-1918(ra) # 80000cb8 <release>
  return i;
}
    8000543e:	854e                	mv	a0,s3
    80005440:	60a6                	ld	ra,72(sp)
    80005442:	6406                	ld	s0,64(sp)
    80005444:	74e2                	ld	s1,56(sp)
    80005446:	7942                	ld	s2,48(sp)
    80005448:	79a2                	ld	s3,40(sp)
    8000544a:	7a02                	ld	s4,32(sp)
    8000544c:	6ae2                	ld	s5,24(sp)
    8000544e:	6b42                	ld	s6,16(sp)
    80005450:	6161                	addi	sp,sp,80
    80005452:	8082                	ret
      release(&pi->lock);
    80005454:	8526                	mv	a0,s1
    80005456:	ffffc097          	auipc	ra,0xffffc
    8000545a:	862080e7          	jalr	-1950(ra) # 80000cb8 <release>
      return -1;
    8000545e:	59fd                	li	s3,-1
    80005460:	bff9                	j	8000543e <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005462:	4981                	li	s3,0
    80005464:	b7d1                	j	80005428 <piperead+0xae>

0000000080005466 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005466:	df010113          	addi	sp,sp,-528
    8000546a:	20113423          	sd	ra,520(sp)
    8000546e:	20813023          	sd	s0,512(sp)
    80005472:	ffa6                	sd	s1,504(sp)
    80005474:	fbca                	sd	s2,496(sp)
    80005476:	f7ce                	sd	s3,488(sp)
    80005478:	f3d2                	sd	s4,480(sp)
    8000547a:	efd6                	sd	s5,472(sp)
    8000547c:	ebda                	sd	s6,464(sp)
    8000547e:	e7de                	sd	s7,456(sp)
    80005480:	e3e2                	sd	s8,448(sp)
    80005482:	ff66                	sd	s9,440(sp)
    80005484:	fb6a                	sd	s10,432(sp)
    80005486:	f76e                	sd	s11,424(sp)
    80005488:	0c00                	addi	s0,sp,528
    8000548a:	84aa                	mv	s1,a0
    8000548c:	dea43c23          	sd	a0,-520(s0)
    80005490:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005494:	ffffd097          	auipc	ra,0xffffd
    80005498:	9c8080e7          	jalr	-1592(ra) # 80001e5c <myproc>
    8000549c:	892a                	mv	s2,a0

  begin_op();
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	49c080e7          	jalr	1180(ra) # 8000493a <begin_op>

  if((ip = namei(path)) == 0){
    800054a6:	8526                	mv	a0,s1
    800054a8:	fffff097          	auipc	ra,0xfffff
    800054ac:	276080e7          	jalr	630(ra) # 8000471e <namei>
    800054b0:	c92d                	beqz	a0,80005522 <exec+0xbc>
    800054b2:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	ab4080e7          	jalr	-1356(ra) # 80003f68 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800054bc:	04000713          	li	a4,64
    800054c0:	4681                	li	a3,0
    800054c2:	e5040613          	addi	a2,s0,-432
    800054c6:	4581                	li	a1,0
    800054c8:	8526                	mv	a0,s1
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	d52080e7          	jalr	-686(ra) # 8000421c <readi>
    800054d2:	04000793          	li	a5,64
    800054d6:	00f51a63          	bne	a0,a5,800054ea <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800054da:	e5042703          	lw	a4,-432(s0)
    800054de:	464c47b7          	lui	a5,0x464c4
    800054e2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800054e6:	04f70463          	beq	a4,a5,8000552e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800054ea:	8526                	mv	a0,s1
    800054ec:	fffff097          	auipc	ra,0xfffff
    800054f0:	cde080e7          	jalr	-802(ra) # 800041ca <iunlockput>
    end_op();
    800054f4:	fffff097          	auipc	ra,0xfffff
    800054f8:	4c6080e7          	jalr	1222(ra) # 800049ba <end_op>
  }
  return -1;
    800054fc:	557d                	li	a0,-1
}
    800054fe:	20813083          	ld	ra,520(sp)
    80005502:	20013403          	ld	s0,512(sp)
    80005506:	74fe                	ld	s1,504(sp)
    80005508:	795e                	ld	s2,496(sp)
    8000550a:	79be                	ld	s3,488(sp)
    8000550c:	7a1e                	ld	s4,480(sp)
    8000550e:	6afe                	ld	s5,472(sp)
    80005510:	6b5e                	ld	s6,464(sp)
    80005512:	6bbe                	ld	s7,456(sp)
    80005514:	6c1e                	ld	s8,448(sp)
    80005516:	7cfa                	ld	s9,440(sp)
    80005518:	7d5a                	ld	s10,432(sp)
    8000551a:	7dba                	ld	s11,424(sp)
    8000551c:	21010113          	addi	sp,sp,528
    80005520:	8082                	ret
    end_op();
    80005522:	fffff097          	auipc	ra,0xfffff
    80005526:	498080e7          	jalr	1176(ra) # 800049ba <end_op>
    return -1;
    8000552a:	557d                	li	a0,-1
    8000552c:	bfc9                	j	800054fe <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000552e:	854a                	mv	a0,s2
    80005530:	ffffd097          	auipc	ra,0xffffd
    80005534:	9ea080e7          	jalr	-1558(ra) # 80001f1a <proc_pagetable>
    80005538:	8baa                	mv	s7,a0
    8000553a:	d945                	beqz	a0,800054ea <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000553c:	e7042983          	lw	s3,-400(s0)
    80005540:	e8845783          	lhu	a5,-376(s0)
    80005544:	c7ad                	beqz	a5,800055ae <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005546:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005548:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    8000554a:	6c85                	lui	s9,0x1
    8000554c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005550:	def43823          	sd	a5,-528(s0)
    80005554:	a42d                	j	8000577e <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005556:	00003517          	auipc	a0,0x3
    8000555a:	1b250513          	addi	a0,a0,434 # 80008708 <syscalls+0x290>
    8000555e:	ffffb097          	auipc	ra,0xffffb
    80005562:	fe0080e7          	jalr	-32(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005566:	8756                	mv	a4,s5
    80005568:	012d86bb          	addw	a3,s11,s2
    8000556c:	4581                	li	a1,0
    8000556e:	8526                	mv	a0,s1
    80005570:	fffff097          	auipc	ra,0xfffff
    80005574:	cac080e7          	jalr	-852(ra) # 8000421c <readi>
    80005578:	2501                	sext.w	a0,a0
    8000557a:	1aaa9963          	bne	s5,a0,8000572c <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000557e:	6785                	lui	a5,0x1
    80005580:	0127893b          	addw	s2,a5,s2
    80005584:	77fd                	lui	a5,0xfffff
    80005586:	01478a3b          	addw	s4,a5,s4
    8000558a:	1f897163          	bgeu	s2,s8,8000576c <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000558e:	02091593          	slli	a1,s2,0x20
    80005592:	9181                	srli	a1,a1,0x20
    80005594:	95ea                	add	a1,a1,s10
    80005596:	855e                	mv	a0,s7
    80005598:	ffffc097          	auipc	ra,0xffffc
    8000559c:	b08080e7          	jalr	-1272(ra) # 800010a0 <walkaddr>
    800055a0:	862a                	mv	a2,a0
    if(pa == 0)
    800055a2:	d955                	beqz	a0,80005556 <exec+0xf0>
      n = PGSIZE;
    800055a4:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800055a6:	fd9a70e3          	bgeu	s4,s9,80005566 <exec+0x100>
      n = sz - i;
    800055aa:	8ad2                	mv	s5,s4
    800055ac:	bf6d                	j	80005566 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800055ae:	4901                	li	s2,0
  iunlockput(ip);
    800055b0:	8526                	mv	a0,s1
    800055b2:	fffff097          	auipc	ra,0xfffff
    800055b6:	c18080e7          	jalr	-1000(ra) # 800041ca <iunlockput>
  end_op();
    800055ba:	fffff097          	auipc	ra,0xfffff
    800055be:	400080e7          	jalr	1024(ra) # 800049ba <end_op>
  p = myproc();
    800055c2:	ffffd097          	auipc	ra,0xffffd
    800055c6:	89a080e7          	jalr	-1894(ra) # 80001e5c <myproc>
    800055ca:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800055cc:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    800055d0:	6785                	lui	a5,0x1
    800055d2:	17fd                	addi	a5,a5,-1
    800055d4:	993e                	add	s2,s2,a5
    800055d6:	757d                	lui	a0,0xfffff
    800055d8:	00a977b3          	and	a5,s2,a0
    800055dc:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800055e0:	6609                	lui	a2,0x2
    800055e2:	963e                	add	a2,a2,a5
    800055e4:	85be                	mv	a1,a5
    800055e6:	855e                	mv	a0,s7
    800055e8:	ffffc097          	auipc	ra,0xffffc
    800055ec:	e6c080e7          	jalr	-404(ra) # 80001454 <uvmalloc>
    800055f0:	8b2a                	mv	s6,a0
  ip = 0;
    800055f2:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800055f4:	12050c63          	beqz	a0,8000572c <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800055f8:	75f9                	lui	a1,0xffffe
    800055fa:	95aa                	add	a1,a1,a0
    800055fc:	855e                	mv	a0,s7
    800055fe:	ffffc097          	auipc	ra,0xffffc
    80005602:	074080e7          	jalr	116(ra) # 80001672 <uvmclear>
  stackbase = sp - PGSIZE;
    80005606:	7c7d                	lui	s8,0xfffff
    80005608:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000560a:	e0043783          	ld	a5,-512(s0)
    8000560e:	6388                	ld	a0,0(a5)
    80005610:	c535                	beqz	a0,8000567c <exec+0x216>
    80005612:	e9040993          	addi	s3,s0,-368
    80005616:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000561a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000561c:	ffffc097          	auipc	ra,0xffffc
    80005620:	87a080e7          	jalr	-1926(ra) # 80000e96 <strlen>
    80005624:	2505                	addiw	a0,a0,1
    80005626:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000562a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000562e:	13896363          	bltu	s2,s8,80005754 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005632:	e0043d83          	ld	s11,-512(s0)
    80005636:	000dba03          	ld	s4,0(s11)
    8000563a:	8552                	mv	a0,s4
    8000563c:	ffffc097          	auipc	ra,0xffffc
    80005640:	85a080e7          	jalr	-1958(ra) # 80000e96 <strlen>
    80005644:	0015069b          	addiw	a3,a0,1
    80005648:	8652                	mv	a2,s4
    8000564a:	85ca                	mv	a1,s2
    8000564c:	855e                	mv	a0,s7
    8000564e:	ffffc097          	auipc	ra,0xffffc
    80005652:	056080e7          	jalr	86(ra) # 800016a4 <copyout>
    80005656:	10054363          	bltz	a0,8000575c <exec+0x2f6>
    ustack[argc] = sp;
    8000565a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000565e:	0485                	addi	s1,s1,1
    80005660:	008d8793          	addi	a5,s11,8
    80005664:	e0f43023          	sd	a5,-512(s0)
    80005668:	008db503          	ld	a0,8(s11)
    8000566c:	c911                	beqz	a0,80005680 <exec+0x21a>
    if(argc >= MAXARG)
    8000566e:	09a1                	addi	s3,s3,8
    80005670:	fb3c96e3          	bne	s9,s3,8000561c <exec+0x1b6>
  sz = sz1;
    80005674:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005678:	4481                	li	s1,0
    8000567a:	a84d                	j	8000572c <exec+0x2c6>
  sp = sz;
    8000567c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000567e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005680:	00349793          	slli	a5,s1,0x3
    80005684:	f9040713          	addi	a4,s0,-112
    80005688:	97ba                	add	a5,a5,a4
    8000568a:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000568e:	00148693          	addi	a3,s1,1
    80005692:	068e                	slli	a3,a3,0x3
    80005694:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005698:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000569c:	01897663          	bgeu	s2,s8,800056a8 <exec+0x242>
  sz = sz1;
    800056a0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056a4:	4481                	li	s1,0
    800056a6:	a059                	j	8000572c <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800056a8:	e9040613          	addi	a2,s0,-368
    800056ac:	85ca                	mv	a1,s2
    800056ae:	855e                	mv	a0,s7
    800056b0:	ffffc097          	auipc	ra,0xffffc
    800056b4:	ff4080e7          	jalr	-12(ra) # 800016a4 <copyout>
    800056b8:	0a054663          	bltz	a0,80005764 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800056bc:	078ab783          	ld	a5,120(s5)
    800056c0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800056c4:	df843783          	ld	a5,-520(s0)
    800056c8:	0007c703          	lbu	a4,0(a5)
    800056cc:	cf11                	beqz	a4,800056e8 <exec+0x282>
    800056ce:	0785                	addi	a5,a5,1
    if(*s == '/')
    800056d0:	02f00693          	li	a3,47
    800056d4:	a039                	j	800056e2 <exec+0x27c>
      last = s+1;
    800056d6:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800056da:	0785                	addi	a5,a5,1
    800056dc:	fff7c703          	lbu	a4,-1(a5)
    800056e0:	c701                	beqz	a4,800056e8 <exec+0x282>
    if(*s == '/')
    800056e2:	fed71ce3          	bne	a4,a3,800056da <exec+0x274>
    800056e6:	bfc5                	j	800056d6 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800056e8:	4641                	li	a2,16
    800056ea:	df843583          	ld	a1,-520(s0)
    800056ee:	178a8513          	addi	a0,s5,376
    800056f2:	ffffb097          	auipc	ra,0xffffb
    800056f6:	772080e7          	jalr	1906(ra) # 80000e64 <safestrcpy>
  oldpagetable = p->pagetable;
    800056fa:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    800056fe:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    80005702:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005706:	078ab783          	ld	a5,120(s5)
    8000570a:	e6843703          	ld	a4,-408(s0)
    8000570e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005710:	078ab783          	ld	a5,120(s5)
    80005714:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005718:	85ea                	mv	a1,s10
    8000571a:	ffffd097          	auipc	ra,0xffffd
    8000571e:	89c080e7          	jalr	-1892(ra) # 80001fb6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005722:	0004851b          	sext.w	a0,s1
    80005726:	bbe1                	j	800054fe <exec+0x98>
    80005728:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000572c:	e0843583          	ld	a1,-504(s0)
    80005730:	855e                	mv	a0,s7
    80005732:	ffffd097          	auipc	ra,0xffffd
    80005736:	884080e7          	jalr	-1916(ra) # 80001fb6 <proc_freepagetable>
  if(ip){
    8000573a:	da0498e3          	bnez	s1,800054ea <exec+0x84>
  return -1;
    8000573e:	557d                	li	a0,-1
    80005740:	bb7d                	j	800054fe <exec+0x98>
    80005742:	e1243423          	sd	s2,-504(s0)
    80005746:	b7dd                	j	8000572c <exec+0x2c6>
    80005748:	e1243423          	sd	s2,-504(s0)
    8000574c:	b7c5                	j	8000572c <exec+0x2c6>
    8000574e:	e1243423          	sd	s2,-504(s0)
    80005752:	bfe9                	j	8000572c <exec+0x2c6>
  sz = sz1;
    80005754:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005758:	4481                	li	s1,0
    8000575a:	bfc9                	j	8000572c <exec+0x2c6>
  sz = sz1;
    8000575c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005760:	4481                	li	s1,0
    80005762:	b7e9                	j	8000572c <exec+0x2c6>
  sz = sz1;
    80005764:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005768:	4481                	li	s1,0
    8000576a:	b7c9                	j	8000572c <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000576c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005770:	2b05                	addiw	s6,s6,1
    80005772:	0389899b          	addiw	s3,s3,56
    80005776:	e8845783          	lhu	a5,-376(s0)
    8000577a:	e2fb5be3          	bge	s6,a5,800055b0 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000577e:	2981                	sext.w	s3,s3
    80005780:	03800713          	li	a4,56
    80005784:	86ce                	mv	a3,s3
    80005786:	e1840613          	addi	a2,s0,-488
    8000578a:	4581                	li	a1,0
    8000578c:	8526                	mv	a0,s1
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	a8e080e7          	jalr	-1394(ra) # 8000421c <readi>
    80005796:	03800793          	li	a5,56
    8000579a:	f8f517e3          	bne	a0,a5,80005728 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000579e:	e1842783          	lw	a5,-488(s0)
    800057a2:	4705                	li	a4,1
    800057a4:	fce796e3          	bne	a5,a4,80005770 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800057a8:	e4043603          	ld	a2,-448(s0)
    800057ac:	e3843783          	ld	a5,-456(s0)
    800057b0:	f8f669e3          	bltu	a2,a5,80005742 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800057b4:	e2843783          	ld	a5,-472(s0)
    800057b8:	963e                	add	a2,a2,a5
    800057ba:	f8f667e3          	bltu	a2,a5,80005748 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800057be:	85ca                	mv	a1,s2
    800057c0:	855e                	mv	a0,s7
    800057c2:	ffffc097          	auipc	ra,0xffffc
    800057c6:	c92080e7          	jalr	-878(ra) # 80001454 <uvmalloc>
    800057ca:	e0a43423          	sd	a0,-504(s0)
    800057ce:	d141                	beqz	a0,8000574e <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800057d0:	e2843d03          	ld	s10,-472(s0)
    800057d4:	df043783          	ld	a5,-528(s0)
    800057d8:	00fd77b3          	and	a5,s10,a5
    800057dc:	fba1                	bnez	a5,8000572c <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800057de:	e2042d83          	lw	s11,-480(s0)
    800057e2:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800057e6:	f80c03e3          	beqz	s8,8000576c <exec+0x306>
    800057ea:	8a62                	mv	s4,s8
    800057ec:	4901                	li	s2,0
    800057ee:	b345                	j	8000558e <exec+0x128>

00000000800057f0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800057f0:	7179                	addi	sp,sp,-48
    800057f2:	f406                	sd	ra,40(sp)
    800057f4:	f022                	sd	s0,32(sp)
    800057f6:	ec26                	sd	s1,24(sp)
    800057f8:	e84a                	sd	s2,16(sp)
    800057fa:	1800                	addi	s0,sp,48
    800057fc:	892e                	mv	s2,a1
    800057fe:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005800:	fdc40593          	addi	a1,s0,-36
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	ba8080e7          	jalr	-1112(ra) # 800033ac <argint>
    8000580c:	04054063          	bltz	a0,8000584c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005810:	fdc42703          	lw	a4,-36(s0)
    80005814:	47bd                	li	a5,15
    80005816:	02e7ed63          	bltu	a5,a4,80005850 <argfd+0x60>
    8000581a:	ffffc097          	auipc	ra,0xffffc
    8000581e:	642080e7          	jalr	1602(ra) # 80001e5c <myproc>
    80005822:	fdc42703          	lw	a4,-36(s0)
    80005826:	01e70793          	addi	a5,a4,30
    8000582a:	078e                	slli	a5,a5,0x3
    8000582c:	953e                	add	a0,a0,a5
    8000582e:	611c                	ld	a5,0(a0)
    80005830:	c395                	beqz	a5,80005854 <argfd+0x64>
    return -1;
  if(pfd)
    80005832:	00090463          	beqz	s2,8000583a <argfd+0x4a>
    *pfd = fd;
    80005836:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000583a:	4501                	li	a0,0
  if(pf)
    8000583c:	c091                	beqz	s1,80005840 <argfd+0x50>
    *pf = f;
    8000583e:	e09c                	sd	a5,0(s1)
}
    80005840:	70a2                	ld	ra,40(sp)
    80005842:	7402                	ld	s0,32(sp)
    80005844:	64e2                	ld	s1,24(sp)
    80005846:	6942                	ld	s2,16(sp)
    80005848:	6145                	addi	sp,sp,48
    8000584a:	8082                	ret
    return -1;
    8000584c:	557d                	li	a0,-1
    8000584e:	bfcd                	j	80005840 <argfd+0x50>
    return -1;
    80005850:	557d                	li	a0,-1
    80005852:	b7fd                	j	80005840 <argfd+0x50>
    80005854:	557d                	li	a0,-1
    80005856:	b7ed                	j	80005840 <argfd+0x50>

0000000080005858 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005858:	1101                	addi	sp,sp,-32
    8000585a:	ec06                	sd	ra,24(sp)
    8000585c:	e822                	sd	s0,16(sp)
    8000585e:	e426                	sd	s1,8(sp)
    80005860:	1000                	addi	s0,sp,32
    80005862:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005864:	ffffc097          	auipc	ra,0xffffc
    80005868:	5f8080e7          	jalr	1528(ra) # 80001e5c <myproc>
    8000586c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000586e:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    80005872:	4501                	li	a0,0
    80005874:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005876:	6398                	ld	a4,0(a5)
    80005878:	cb19                	beqz	a4,8000588e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000587a:	2505                	addiw	a0,a0,1
    8000587c:	07a1                	addi	a5,a5,8
    8000587e:	fed51ce3          	bne	a0,a3,80005876 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005882:	557d                	li	a0,-1
}
    80005884:	60e2                	ld	ra,24(sp)
    80005886:	6442                	ld	s0,16(sp)
    80005888:	64a2                	ld	s1,8(sp)
    8000588a:	6105                	addi	sp,sp,32
    8000588c:	8082                	ret
      p->ofile[fd] = f;
    8000588e:	01e50793          	addi	a5,a0,30
    80005892:	078e                	slli	a5,a5,0x3
    80005894:	963e                	add	a2,a2,a5
    80005896:	e204                	sd	s1,0(a2)
      return fd;
    80005898:	b7f5                	j	80005884 <fdalloc+0x2c>

000000008000589a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000589a:	715d                	addi	sp,sp,-80
    8000589c:	e486                	sd	ra,72(sp)
    8000589e:	e0a2                	sd	s0,64(sp)
    800058a0:	fc26                	sd	s1,56(sp)
    800058a2:	f84a                	sd	s2,48(sp)
    800058a4:	f44e                	sd	s3,40(sp)
    800058a6:	f052                	sd	s4,32(sp)
    800058a8:	ec56                	sd	s5,24(sp)
    800058aa:	0880                	addi	s0,sp,80
    800058ac:	89ae                	mv	s3,a1
    800058ae:	8ab2                	mv	s5,a2
    800058b0:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800058b2:	fb040593          	addi	a1,s0,-80
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	e86080e7          	jalr	-378(ra) # 8000473c <nameiparent>
    800058be:	892a                	mv	s2,a0
    800058c0:	12050f63          	beqz	a0,800059fe <create+0x164>
    return 0;

  ilock(dp);
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	6a4080e7          	jalr	1700(ra) # 80003f68 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800058cc:	4601                	li	a2,0
    800058ce:	fb040593          	addi	a1,s0,-80
    800058d2:	854a                	mv	a0,s2
    800058d4:	fffff097          	auipc	ra,0xfffff
    800058d8:	b78080e7          	jalr	-1160(ra) # 8000444c <dirlookup>
    800058dc:	84aa                	mv	s1,a0
    800058de:	c921                	beqz	a0,8000592e <create+0x94>
    iunlockput(dp);
    800058e0:	854a                	mv	a0,s2
    800058e2:	fffff097          	auipc	ra,0xfffff
    800058e6:	8e8080e7          	jalr	-1816(ra) # 800041ca <iunlockput>
    ilock(ip);
    800058ea:	8526                	mv	a0,s1
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	67c080e7          	jalr	1660(ra) # 80003f68 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800058f4:	2981                	sext.w	s3,s3
    800058f6:	4789                	li	a5,2
    800058f8:	02f99463          	bne	s3,a5,80005920 <create+0x86>
    800058fc:	0444d783          	lhu	a5,68(s1)
    80005900:	37f9                	addiw	a5,a5,-2
    80005902:	17c2                	slli	a5,a5,0x30
    80005904:	93c1                	srli	a5,a5,0x30
    80005906:	4705                	li	a4,1
    80005908:	00f76c63          	bltu	a4,a5,80005920 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000590c:	8526                	mv	a0,s1
    8000590e:	60a6                	ld	ra,72(sp)
    80005910:	6406                	ld	s0,64(sp)
    80005912:	74e2                	ld	s1,56(sp)
    80005914:	7942                	ld	s2,48(sp)
    80005916:	79a2                	ld	s3,40(sp)
    80005918:	7a02                	ld	s4,32(sp)
    8000591a:	6ae2                	ld	s5,24(sp)
    8000591c:	6161                	addi	sp,sp,80
    8000591e:	8082                	ret
    iunlockput(ip);
    80005920:	8526                	mv	a0,s1
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	8a8080e7          	jalr	-1880(ra) # 800041ca <iunlockput>
    return 0;
    8000592a:	4481                	li	s1,0
    8000592c:	b7c5                	j	8000590c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000592e:	85ce                	mv	a1,s3
    80005930:	00092503          	lw	a0,0(s2)
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	49c080e7          	jalr	1180(ra) # 80003dd0 <ialloc>
    8000593c:	84aa                	mv	s1,a0
    8000593e:	c529                	beqz	a0,80005988 <create+0xee>
  ilock(ip);
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	628080e7          	jalr	1576(ra) # 80003f68 <ilock>
  ip->major = major;
    80005948:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000594c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005950:	4785                	li	a5,1
    80005952:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005956:	8526                	mv	a0,s1
    80005958:	ffffe097          	auipc	ra,0xffffe
    8000595c:	546080e7          	jalr	1350(ra) # 80003e9e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005960:	2981                	sext.w	s3,s3
    80005962:	4785                	li	a5,1
    80005964:	02f98a63          	beq	s3,a5,80005998 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005968:	40d0                	lw	a2,4(s1)
    8000596a:	fb040593          	addi	a1,s0,-80
    8000596e:	854a                	mv	a0,s2
    80005970:	fffff097          	auipc	ra,0xfffff
    80005974:	cec080e7          	jalr	-788(ra) # 8000465c <dirlink>
    80005978:	06054b63          	bltz	a0,800059ee <create+0x154>
  iunlockput(dp);
    8000597c:	854a                	mv	a0,s2
    8000597e:	fffff097          	auipc	ra,0xfffff
    80005982:	84c080e7          	jalr	-1972(ra) # 800041ca <iunlockput>
  return ip;
    80005986:	b759                	j	8000590c <create+0x72>
    panic("create: ialloc");
    80005988:	00003517          	auipc	a0,0x3
    8000598c:	da050513          	addi	a0,a0,-608 # 80008728 <syscalls+0x2b0>
    80005990:	ffffb097          	auipc	ra,0xffffb
    80005994:	bae080e7          	jalr	-1106(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005998:	04a95783          	lhu	a5,74(s2)
    8000599c:	2785                	addiw	a5,a5,1
    8000599e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800059a2:	854a                	mv	a0,s2
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	4fa080e7          	jalr	1274(ra) # 80003e9e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800059ac:	40d0                	lw	a2,4(s1)
    800059ae:	00003597          	auipc	a1,0x3
    800059b2:	d8a58593          	addi	a1,a1,-630 # 80008738 <syscalls+0x2c0>
    800059b6:	8526                	mv	a0,s1
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	ca4080e7          	jalr	-860(ra) # 8000465c <dirlink>
    800059c0:	00054f63          	bltz	a0,800059de <create+0x144>
    800059c4:	00492603          	lw	a2,4(s2)
    800059c8:	00003597          	auipc	a1,0x3
    800059cc:	d7858593          	addi	a1,a1,-648 # 80008740 <syscalls+0x2c8>
    800059d0:	8526                	mv	a0,s1
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	c8a080e7          	jalr	-886(ra) # 8000465c <dirlink>
    800059da:	f80557e3          	bgez	a0,80005968 <create+0xce>
      panic("create dots");
    800059de:	00003517          	auipc	a0,0x3
    800059e2:	d6a50513          	addi	a0,a0,-662 # 80008748 <syscalls+0x2d0>
    800059e6:	ffffb097          	auipc	ra,0xffffb
    800059ea:	b58080e7          	jalr	-1192(ra) # 8000053e <panic>
    panic("create: dirlink");
    800059ee:	00003517          	auipc	a0,0x3
    800059f2:	d6a50513          	addi	a0,a0,-662 # 80008758 <syscalls+0x2e0>
    800059f6:	ffffb097          	auipc	ra,0xffffb
    800059fa:	b48080e7          	jalr	-1208(ra) # 8000053e <panic>
    return 0;
    800059fe:	84aa                	mv	s1,a0
    80005a00:	b731                	j	8000590c <create+0x72>

0000000080005a02 <sys_dup>:
{
    80005a02:	7179                	addi	sp,sp,-48
    80005a04:	f406                	sd	ra,40(sp)
    80005a06:	f022                	sd	s0,32(sp)
    80005a08:	ec26                	sd	s1,24(sp)
    80005a0a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005a0c:	fd840613          	addi	a2,s0,-40
    80005a10:	4581                	li	a1,0
    80005a12:	4501                	li	a0,0
    80005a14:	00000097          	auipc	ra,0x0
    80005a18:	ddc080e7          	jalr	-548(ra) # 800057f0 <argfd>
    return -1;
    80005a1c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005a1e:	02054363          	bltz	a0,80005a44 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005a22:	fd843503          	ld	a0,-40(s0)
    80005a26:	00000097          	auipc	ra,0x0
    80005a2a:	e32080e7          	jalr	-462(ra) # 80005858 <fdalloc>
    80005a2e:	84aa                	mv	s1,a0
    return -1;
    80005a30:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005a32:	00054963          	bltz	a0,80005a44 <sys_dup+0x42>
  filedup(f);
    80005a36:	fd843503          	ld	a0,-40(s0)
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	37a080e7          	jalr	890(ra) # 80004db4 <filedup>
  return fd;
    80005a42:	87a6                	mv	a5,s1
}
    80005a44:	853e                	mv	a0,a5
    80005a46:	70a2                	ld	ra,40(sp)
    80005a48:	7402                	ld	s0,32(sp)
    80005a4a:	64e2                	ld	s1,24(sp)
    80005a4c:	6145                	addi	sp,sp,48
    80005a4e:	8082                	ret

0000000080005a50 <sys_read>:
{
    80005a50:	7179                	addi	sp,sp,-48
    80005a52:	f406                	sd	ra,40(sp)
    80005a54:	f022                	sd	s0,32(sp)
    80005a56:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a58:	fe840613          	addi	a2,s0,-24
    80005a5c:	4581                	li	a1,0
    80005a5e:	4501                	li	a0,0
    80005a60:	00000097          	auipc	ra,0x0
    80005a64:	d90080e7          	jalr	-624(ra) # 800057f0 <argfd>
    return -1;
    80005a68:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a6a:	04054163          	bltz	a0,80005aac <sys_read+0x5c>
    80005a6e:	fe440593          	addi	a1,s0,-28
    80005a72:	4509                	li	a0,2
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	938080e7          	jalr	-1736(ra) # 800033ac <argint>
    return -1;
    80005a7c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a7e:	02054763          	bltz	a0,80005aac <sys_read+0x5c>
    80005a82:	fd840593          	addi	a1,s0,-40
    80005a86:	4505                	li	a0,1
    80005a88:	ffffe097          	auipc	ra,0xffffe
    80005a8c:	946080e7          	jalr	-1722(ra) # 800033ce <argaddr>
    return -1;
    80005a90:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a92:	00054d63          	bltz	a0,80005aac <sys_read+0x5c>
  return fileread(f, p, n);
    80005a96:	fe442603          	lw	a2,-28(s0)
    80005a9a:	fd843583          	ld	a1,-40(s0)
    80005a9e:	fe843503          	ld	a0,-24(s0)
    80005aa2:	fffff097          	auipc	ra,0xfffff
    80005aa6:	49e080e7          	jalr	1182(ra) # 80004f40 <fileread>
    80005aaa:	87aa                	mv	a5,a0
}
    80005aac:	853e                	mv	a0,a5
    80005aae:	70a2                	ld	ra,40(sp)
    80005ab0:	7402                	ld	s0,32(sp)
    80005ab2:	6145                	addi	sp,sp,48
    80005ab4:	8082                	ret

0000000080005ab6 <sys_write>:
{
    80005ab6:	7179                	addi	sp,sp,-48
    80005ab8:	f406                	sd	ra,40(sp)
    80005aba:	f022                	sd	s0,32(sp)
    80005abc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005abe:	fe840613          	addi	a2,s0,-24
    80005ac2:	4581                	li	a1,0
    80005ac4:	4501                	li	a0,0
    80005ac6:	00000097          	auipc	ra,0x0
    80005aca:	d2a080e7          	jalr	-726(ra) # 800057f0 <argfd>
    return -1;
    80005ace:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ad0:	04054163          	bltz	a0,80005b12 <sys_write+0x5c>
    80005ad4:	fe440593          	addi	a1,s0,-28
    80005ad8:	4509                	li	a0,2
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	8d2080e7          	jalr	-1838(ra) # 800033ac <argint>
    return -1;
    80005ae2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ae4:	02054763          	bltz	a0,80005b12 <sys_write+0x5c>
    80005ae8:	fd840593          	addi	a1,s0,-40
    80005aec:	4505                	li	a0,1
    80005aee:	ffffe097          	auipc	ra,0xffffe
    80005af2:	8e0080e7          	jalr	-1824(ra) # 800033ce <argaddr>
    return -1;
    80005af6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005af8:	00054d63          	bltz	a0,80005b12 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005afc:	fe442603          	lw	a2,-28(s0)
    80005b00:	fd843583          	ld	a1,-40(s0)
    80005b04:	fe843503          	ld	a0,-24(s0)
    80005b08:	fffff097          	auipc	ra,0xfffff
    80005b0c:	4fa080e7          	jalr	1274(ra) # 80005002 <filewrite>
    80005b10:	87aa                	mv	a5,a0
}
    80005b12:	853e                	mv	a0,a5
    80005b14:	70a2                	ld	ra,40(sp)
    80005b16:	7402                	ld	s0,32(sp)
    80005b18:	6145                	addi	sp,sp,48
    80005b1a:	8082                	ret

0000000080005b1c <sys_close>:
{
    80005b1c:	1101                	addi	sp,sp,-32
    80005b1e:	ec06                	sd	ra,24(sp)
    80005b20:	e822                	sd	s0,16(sp)
    80005b22:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005b24:	fe040613          	addi	a2,s0,-32
    80005b28:	fec40593          	addi	a1,s0,-20
    80005b2c:	4501                	li	a0,0
    80005b2e:	00000097          	auipc	ra,0x0
    80005b32:	cc2080e7          	jalr	-830(ra) # 800057f0 <argfd>
    return -1;
    80005b36:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005b38:	02054463          	bltz	a0,80005b60 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005b3c:	ffffc097          	auipc	ra,0xffffc
    80005b40:	320080e7          	jalr	800(ra) # 80001e5c <myproc>
    80005b44:	fec42783          	lw	a5,-20(s0)
    80005b48:	07f9                	addi	a5,a5,30
    80005b4a:	078e                	slli	a5,a5,0x3
    80005b4c:	97aa                	add	a5,a5,a0
    80005b4e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005b52:	fe043503          	ld	a0,-32(s0)
    80005b56:	fffff097          	auipc	ra,0xfffff
    80005b5a:	2b0080e7          	jalr	688(ra) # 80004e06 <fileclose>
  return 0;
    80005b5e:	4781                	li	a5,0
}
    80005b60:	853e                	mv	a0,a5
    80005b62:	60e2                	ld	ra,24(sp)
    80005b64:	6442                	ld	s0,16(sp)
    80005b66:	6105                	addi	sp,sp,32
    80005b68:	8082                	ret

0000000080005b6a <sys_fstat>:
{
    80005b6a:	1101                	addi	sp,sp,-32
    80005b6c:	ec06                	sd	ra,24(sp)
    80005b6e:	e822                	sd	s0,16(sp)
    80005b70:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b72:	fe840613          	addi	a2,s0,-24
    80005b76:	4581                	li	a1,0
    80005b78:	4501                	li	a0,0
    80005b7a:	00000097          	auipc	ra,0x0
    80005b7e:	c76080e7          	jalr	-906(ra) # 800057f0 <argfd>
    return -1;
    80005b82:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b84:	02054563          	bltz	a0,80005bae <sys_fstat+0x44>
    80005b88:	fe040593          	addi	a1,s0,-32
    80005b8c:	4505                	li	a0,1
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	840080e7          	jalr	-1984(ra) # 800033ce <argaddr>
    return -1;
    80005b96:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b98:	00054b63          	bltz	a0,80005bae <sys_fstat+0x44>
  return filestat(f, st);
    80005b9c:	fe043583          	ld	a1,-32(s0)
    80005ba0:	fe843503          	ld	a0,-24(s0)
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	32a080e7          	jalr	810(ra) # 80004ece <filestat>
    80005bac:	87aa                	mv	a5,a0
}
    80005bae:	853e                	mv	a0,a5
    80005bb0:	60e2                	ld	ra,24(sp)
    80005bb2:	6442                	ld	s0,16(sp)
    80005bb4:	6105                	addi	sp,sp,32
    80005bb6:	8082                	ret

0000000080005bb8 <sys_link>:
{
    80005bb8:	7169                	addi	sp,sp,-304
    80005bba:	f606                	sd	ra,296(sp)
    80005bbc:	f222                	sd	s0,288(sp)
    80005bbe:	ee26                	sd	s1,280(sp)
    80005bc0:	ea4a                	sd	s2,272(sp)
    80005bc2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005bc4:	08000613          	li	a2,128
    80005bc8:	ed040593          	addi	a1,s0,-304
    80005bcc:	4501                	li	a0,0
    80005bce:	ffffe097          	auipc	ra,0xffffe
    80005bd2:	822080e7          	jalr	-2014(ra) # 800033f0 <argstr>
    return -1;
    80005bd6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005bd8:	10054e63          	bltz	a0,80005cf4 <sys_link+0x13c>
    80005bdc:	08000613          	li	a2,128
    80005be0:	f5040593          	addi	a1,s0,-176
    80005be4:	4505                	li	a0,1
    80005be6:	ffffe097          	auipc	ra,0xffffe
    80005bea:	80a080e7          	jalr	-2038(ra) # 800033f0 <argstr>
    return -1;
    80005bee:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005bf0:	10054263          	bltz	a0,80005cf4 <sys_link+0x13c>
  begin_op();
    80005bf4:	fffff097          	auipc	ra,0xfffff
    80005bf8:	d46080e7          	jalr	-698(ra) # 8000493a <begin_op>
  if((ip = namei(old)) == 0){
    80005bfc:	ed040513          	addi	a0,s0,-304
    80005c00:	fffff097          	auipc	ra,0xfffff
    80005c04:	b1e080e7          	jalr	-1250(ra) # 8000471e <namei>
    80005c08:	84aa                	mv	s1,a0
    80005c0a:	c551                	beqz	a0,80005c96 <sys_link+0xde>
  ilock(ip);
    80005c0c:	ffffe097          	auipc	ra,0xffffe
    80005c10:	35c080e7          	jalr	860(ra) # 80003f68 <ilock>
  if(ip->type == T_DIR){
    80005c14:	04449703          	lh	a4,68(s1)
    80005c18:	4785                	li	a5,1
    80005c1a:	08f70463          	beq	a4,a5,80005ca2 <sys_link+0xea>
  ip->nlink++;
    80005c1e:	04a4d783          	lhu	a5,74(s1)
    80005c22:	2785                	addiw	a5,a5,1
    80005c24:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c28:	8526                	mv	a0,s1
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	274080e7          	jalr	628(ra) # 80003e9e <iupdate>
  iunlock(ip);
    80005c32:	8526                	mv	a0,s1
    80005c34:	ffffe097          	auipc	ra,0xffffe
    80005c38:	3f6080e7          	jalr	1014(ra) # 8000402a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005c3c:	fd040593          	addi	a1,s0,-48
    80005c40:	f5040513          	addi	a0,s0,-176
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	af8080e7          	jalr	-1288(ra) # 8000473c <nameiparent>
    80005c4c:	892a                	mv	s2,a0
    80005c4e:	c935                	beqz	a0,80005cc2 <sys_link+0x10a>
  ilock(dp);
    80005c50:	ffffe097          	auipc	ra,0xffffe
    80005c54:	318080e7          	jalr	792(ra) # 80003f68 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005c58:	00092703          	lw	a4,0(s2)
    80005c5c:	409c                	lw	a5,0(s1)
    80005c5e:	04f71d63          	bne	a4,a5,80005cb8 <sys_link+0x100>
    80005c62:	40d0                	lw	a2,4(s1)
    80005c64:	fd040593          	addi	a1,s0,-48
    80005c68:	854a                	mv	a0,s2
    80005c6a:	fffff097          	auipc	ra,0xfffff
    80005c6e:	9f2080e7          	jalr	-1550(ra) # 8000465c <dirlink>
    80005c72:	04054363          	bltz	a0,80005cb8 <sys_link+0x100>
  iunlockput(dp);
    80005c76:	854a                	mv	a0,s2
    80005c78:	ffffe097          	auipc	ra,0xffffe
    80005c7c:	552080e7          	jalr	1362(ra) # 800041ca <iunlockput>
  iput(ip);
    80005c80:	8526                	mv	a0,s1
    80005c82:	ffffe097          	auipc	ra,0xffffe
    80005c86:	4a0080e7          	jalr	1184(ra) # 80004122 <iput>
  end_op();
    80005c8a:	fffff097          	auipc	ra,0xfffff
    80005c8e:	d30080e7          	jalr	-720(ra) # 800049ba <end_op>
  return 0;
    80005c92:	4781                	li	a5,0
    80005c94:	a085                	j	80005cf4 <sys_link+0x13c>
    end_op();
    80005c96:	fffff097          	auipc	ra,0xfffff
    80005c9a:	d24080e7          	jalr	-732(ra) # 800049ba <end_op>
    return -1;
    80005c9e:	57fd                	li	a5,-1
    80005ca0:	a891                	j	80005cf4 <sys_link+0x13c>
    iunlockput(ip);
    80005ca2:	8526                	mv	a0,s1
    80005ca4:	ffffe097          	auipc	ra,0xffffe
    80005ca8:	526080e7          	jalr	1318(ra) # 800041ca <iunlockput>
    end_op();
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	d0e080e7          	jalr	-754(ra) # 800049ba <end_op>
    return -1;
    80005cb4:	57fd                	li	a5,-1
    80005cb6:	a83d                	j	80005cf4 <sys_link+0x13c>
    iunlockput(dp);
    80005cb8:	854a                	mv	a0,s2
    80005cba:	ffffe097          	auipc	ra,0xffffe
    80005cbe:	510080e7          	jalr	1296(ra) # 800041ca <iunlockput>
  ilock(ip);
    80005cc2:	8526                	mv	a0,s1
    80005cc4:	ffffe097          	auipc	ra,0xffffe
    80005cc8:	2a4080e7          	jalr	676(ra) # 80003f68 <ilock>
  ip->nlink--;
    80005ccc:	04a4d783          	lhu	a5,74(s1)
    80005cd0:	37fd                	addiw	a5,a5,-1
    80005cd2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005cd6:	8526                	mv	a0,s1
    80005cd8:	ffffe097          	auipc	ra,0xffffe
    80005cdc:	1c6080e7          	jalr	454(ra) # 80003e9e <iupdate>
  iunlockput(ip);
    80005ce0:	8526                	mv	a0,s1
    80005ce2:	ffffe097          	auipc	ra,0xffffe
    80005ce6:	4e8080e7          	jalr	1256(ra) # 800041ca <iunlockput>
  end_op();
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	cd0080e7          	jalr	-816(ra) # 800049ba <end_op>
  return -1;
    80005cf2:	57fd                	li	a5,-1
}
    80005cf4:	853e                	mv	a0,a5
    80005cf6:	70b2                	ld	ra,296(sp)
    80005cf8:	7412                	ld	s0,288(sp)
    80005cfa:	64f2                	ld	s1,280(sp)
    80005cfc:	6952                	ld	s2,272(sp)
    80005cfe:	6155                	addi	sp,sp,304
    80005d00:	8082                	ret

0000000080005d02 <sys_unlink>:
{
    80005d02:	7151                	addi	sp,sp,-240
    80005d04:	f586                	sd	ra,232(sp)
    80005d06:	f1a2                	sd	s0,224(sp)
    80005d08:	eda6                	sd	s1,216(sp)
    80005d0a:	e9ca                	sd	s2,208(sp)
    80005d0c:	e5ce                	sd	s3,200(sp)
    80005d0e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005d10:	08000613          	li	a2,128
    80005d14:	f3040593          	addi	a1,s0,-208
    80005d18:	4501                	li	a0,0
    80005d1a:	ffffd097          	auipc	ra,0xffffd
    80005d1e:	6d6080e7          	jalr	1750(ra) # 800033f0 <argstr>
    80005d22:	18054163          	bltz	a0,80005ea4 <sys_unlink+0x1a2>
  begin_op();
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	c14080e7          	jalr	-1004(ra) # 8000493a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005d2e:	fb040593          	addi	a1,s0,-80
    80005d32:	f3040513          	addi	a0,s0,-208
    80005d36:	fffff097          	auipc	ra,0xfffff
    80005d3a:	a06080e7          	jalr	-1530(ra) # 8000473c <nameiparent>
    80005d3e:	84aa                	mv	s1,a0
    80005d40:	c979                	beqz	a0,80005e16 <sys_unlink+0x114>
  ilock(dp);
    80005d42:	ffffe097          	auipc	ra,0xffffe
    80005d46:	226080e7          	jalr	550(ra) # 80003f68 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005d4a:	00003597          	auipc	a1,0x3
    80005d4e:	9ee58593          	addi	a1,a1,-1554 # 80008738 <syscalls+0x2c0>
    80005d52:	fb040513          	addi	a0,s0,-80
    80005d56:	ffffe097          	auipc	ra,0xffffe
    80005d5a:	6dc080e7          	jalr	1756(ra) # 80004432 <namecmp>
    80005d5e:	14050a63          	beqz	a0,80005eb2 <sys_unlink+0x1b0>
    80005d62:	00003597          	auipc	a1,0x3
    80005d66:	9de58593          	addi	a1,a1,-1570 # 80008740 <syscalls+0x2c8>
    80005d6a:	fb040513          	addi	a0,s0,-80
    80005d6e:	ffffe097          	auipc	ra,0xffffe
    80005d72:	6c4080e7          	jalr	1732(ra) # 80004432 <namecmp>
    80005d76:	12050e63          	beqz	a0,80005eb2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005d7a:	f2c40613          	addi	a2,s0,-212
    80005d7e:	fb040593          	addi	a1,s0,-80
    80005d82:	8526                	mv	a0,s1
    80005d84:	ffffe097          	auipc	ra,0xffffe
    80005d88:	6c8080e7          	jalr	1736(ra) # 8000444c <dirlookup>
    80005d8c:	892a                	mv	s2,a0
    80005d8e:	12050263          	beqz	a0,80005eb2 <sys_unlink+0x1b0>
  ilock(ip);
    80005d92:	ffffe097          	auipc	ra,0xffffe
    80005d96:	1d6080e7          	jalr	470(ra) # 80003f68 <ilock>
  if(ip->nlink < 1)
    80005d9a:	04a91783          	lh	a5,74(s2)
    80005d9e:	08f05263          	blez	a5,80005e22 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005da2:	04491703          	lh	a4,68(s2)
    80005da6:	4785                	li	a5,1
    80005da8:	08f70563          	beq	a4,a5,80005e32 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005dac:	4641                	li	a2,16
    80005dae:	4581                	li	a1,0
    80005db0:	fc040513          	addi	a0,s0,-64
    80005db4:	ffffb097          	auipc	ra,0xffffb
    80005db8:	f5e080e7          	jalr	-162(ra) # 80000d12 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005dbc:	4741                	li	a4,16
    80005dbe:	f2c42683          	lw	a3,-212(s0)
    80005dc2:	fc040613          	addi	a2,s0,-64
    80005dc6:	4581                	li	a1,0
    80005dc8:	8526                	mv	a0,s1
    80005dca:	ffffe097          	auipc	ra,0xffffe
    80005dce:	54a080e7          	jalr	1354(ra) # 80004314 <writei>
    80005dd2:	47c1                	li	a5,16
    80005dd4:	0af51563          	bne	a0,a5,80005e7e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005dd8:	04491703          	lh	a4,68(s2)
    80005ddc:	4785                	li	a5,1
    80005dde:	0af70863          	beq	a4,a5,80005e8e <sys_unlink+0x18c>
  iunlockput(dp);
    80005de2:	8526                	mv	a0,s1
    80005de4:	ffffe097          	auipc	ra,0xffffe
    80005de8:	3e6080e7          	jalr	998(ra) # 800041ca <iunlockput>
  ip->nlink--;
    80005dec:	04a95783          	lhu	a5,74(s2)
    80005df0:	37fd                	addiw	a5,a5,-1
    80005df2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005df6:	854a                	mv	a0,s2
    80005df8:	ffffe097          	auipc	ra,0xffffe
    80005dfc:	0a6080e7          	jalr	166(ra) # 80003e9e <iupdate>
  iunlockput(ip);
    80005e00:	854a                	mv	a0,s2
    80005e02:	ffffe097          	auipc	ra,0xffffe
    80005e06:	3c8080e7          	jalr	968(ra) # 800041ca <iunlockput>
  end_op();
    80005e0a:	fffff097          	auipc	ra,0xfffff
    80005e0e:	bb0080e7          	jalr	-1104(ra) # 800049ba <end_op>
  return 0;
    80005e12:	4501                	li	a0,0
    80005e14:	a84d                	j	80005ec6 <sys_unlink+0x1c4>
    end_op();
    80005e16:	fffff097          	auipc	ra,0xfffff
    80005e1a:	ba4080e7          	jalr	-1116(ra) # 800049ba <end_op>
    return -1;
    80005e1e:	557d                	li	a0,-1
    80005e20:	a05d                	j	80005ec6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005e22:	00003517          	auipc	a0,0x3
    80005e26:	94650513          	addi	a0,a0,-1722 # 80008768 <syscalls+0x2f0>
    80005e2a:	ffffa097          	auipc	ra,0xffffa
    80005e2e:	714080e7          	jalr	1812(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e32:	04c92703          	lw	a4,76(s2)
    80005e36:	02000793          	li	a5,32
    80005e3a:	f6e7f9e3          	bgeu	a5,a4,80005dac <sys_unlink+0xaa>
    80005e3e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e42:	4741                	li	a4,16
    80005e44:	86ce                	mv	a3,s3
    80005e46:	f1840613          	addi	a2,s0,-232
    80005e4a:	4581                	li	a1,0
    80005e4c:	854a                	mv	a0,s2
    80005e4e:	ffffe097          	auipc	ra,0xffffe
    80005e52:	3ce080e7          	jalr	974(ra) # 8000421c <readi>
    80005e56:	47c1                	li	a5,16
    80005e58:	00f51b63          	bne	a0,a5,80005e6e <sys_unlink+0x16c>
    if(de.inum != 0)
    80005e5c:	f1845783          	lhu	a5,-232(s0)
    80005e60:	e7a1                	bnez	a5,80005ea8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e62:	29c1                	addiw	s3,s3,16
    80005e64:	04c92783          	lw	a5,76(s2)
    80005e68:	fcf9ede3          	bltu	s3,a5,80005e42 <sys_unlink+0x140>
    80005e6c:	b781                	j	80005dac <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005e6e:	00003517          	auipc	a0,0x3
    80005e72:	91250513          	addi	a0,a0,-1774 # 80008780 <syscalls+0x308>
    80005e76:	ffffa097          	auipc	ra,0xffffa
    80005e7a:	6c8080e7          	jalr	1736(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005e7e:	00003517          	auipc	a0,0x3
    80005e82:	91a50513          	addi	a0,a0,-1766 # 80008798 <syscalls+0x320>
    80005e86:	ffffa097          	auipc	ra,0xffffa
    80005e8a:	6b8080e7          	jalr	1720(ra) # 8000053e <panic>
    dp->nlink--;
    80005e8e:	04a4d783          	lhu	a5,74(s1)
    80005e92:	37fd                	addiw	a5,a5,-1
    80005e94:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005e98:	8526                	mv	a0,s1
    80005e9a:	ffffe097          	auipc	ra,0xffffe
    80005e9e:	004080e7          	jalr	4(ra) # 80003e9e <iupdate>
    80005ea2:	b781                	j	80005de2 <sys_unlink+0xe0>
    return -1;
    80005ea4:	557d                	li	a0,-1
    80005ea6:	a005                	j	80005ec6 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005ea8:	854a                	mv	a0,s2
    80005eaa:	ffffe097          	auipc	ra,0xffffe
    80005eae:	320080e7          	jalr	800(ra) # 800041ca <iunlockput>
  iunlockput(dp);
    80005eb2:	8526                	mv	a0,s1
    80005eb4:	ffffe097          	auipc	ra,0xffffe
    80005eb8:	316080e7          	jalr	790(ra) # 800041ca <iunlockput>
  end_op();
    80005ebc:	fffff097          	auipc	ra,0xfffff
    80005ec0:	afe080e7          	jalr	-1282(ra) # 800049ba <end_op>
  return -1;
    80005ec4:	557d                	li	a0,-1
}
    80005ec6:	70ae                	ld	ra,232(sp)
    80005ec8:	740e                	ld	s0,224(sp)
    80005eca:	64ee                	ld	s1,216(sp)
    80005ecc:	694e                	ld	s2,208(sp)
    80005ece:	69ae                	ld	s3,200(sp)
    80005ed0:	616d                	addi	sp,sp,240
    80005ed2:	8082                	ret

0000000080005ed4 <sys_open>:

uint64
sys_open(void)
{
    80005ed4:	7131                	addi	sp,sp,-192
    80005ed6:	fd06                	sd	ra,184(sp)
    80005ed8:	f922                	sd	s0,176(sp)
    80005eda:	f526                	sd	s1,168(sp)
    80005edc:	f14a                	sd	s2,160(sp)
    80005ede:	ed4e                	sd	s3,152(sp)
    80005ee0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ee2:	08000613          	li	a2,128
    80005ee6:	f5040593          	addi	a1,s0,-176
    80005eea:	4501                	li	a0,0
    80005eec:	ffffd097          	auipc	ra,0xffffd
    80005ef0:	504080e7          	jalr	1284(ra) # 800033f0 <argstr>
    return -1;
    80005ef4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ef6:	0c054163          	bltz	a0,80005fb8 <sys_open+0xe4>
    80005efa:	f4c40593          	addi	a1,s0,-180
    80005efe:	4505                	li	a0,1
    80005f00:	ffffd097          	auipc	ra,0xffffd
    80005f04:	4ac080e7          	jalr	1196(ra) # 800033ac <argint>
    80005f08:	0a054863          	bltz	a0,80005fb8 <sys_open+0xe4>

  begin_op();
    80005f0c:	fffff097          	auipc	ra,0xfffff
    80005f10:	a2e080e7          	jalr	-1490(ra) # 8000493a <begin_op>

  if(omode & O_CREATE){
    80005f14:	f4c42783          	lw	a5,-180(s0)
    80005f18:	2007f793          	andi	a5,a5,512
    80005f1c:	cbdd                	beqz	a5,80005fd2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005f1e:	4681                	li	a3,0
    80005f20:	4601                	li	a2,0
    80005f22:	4589                	li	a1,2
    80005f24:	f5040513          	addi	a0,s0,-176
    80005f28:	00000097          	auipc	ra,0x0
    80005f2c:	972080e7          	jalr	-1678(ra) # 8000589a <create>
    80005f30:	892a                	mv	s2,a0
    if(ip == 0){
    80005f32:	c959                	beqz	a0,80005fc8 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005f34:	04491703          	lh	a4,68(s2)
    80005f38:	478d                	li	a5,3
    80005f3a:	00f71763          	bne	a4,a5,80005f48 <sys_open+0x74>
    80005f3e:	04695703          	lhu	a4,70(s2)
    80005f42:	47a5                	li	a5,9
    80005f44:	0ce7ec63          	bltu	a5,a4,8000601c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005f48:	fffff097          	auipc	ra,0xfffff
    80005f4c:	e02080e7          	jalr	-510(ra) # 80004d4a <filealloc>
    80005f50:	89aa                	mv	s3,a0
    80005f52:	10050263          	beqz	a0,80006056 <sys_open+0x182>
    80005f56:	00000097          	auipc	ra,0x0
    80005f5a:	902080e7          	jalr	-1790(ra) # 80005858 <fdalloc>
    80005f5e:	84aa                	mv	s1,a0
    80005f60:	0e054663          	bltz	a0,8000604c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005f64:	04491703          	lh	a4,68(s2)
    80005f68:	478d                	li	a5,3
    80005f6a:	0cf70463          	beq	a4,a5,80006032 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005f6e:	4789                	li	a5,2
    80005f70:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005f74:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005f78:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005f7c:	f4c42783          	lw	a5,-180(s0)
    80005f80:	0017c713          	xori	a4,a5,1
    80005f84:	8b05                	andi	a4,a4,1
    80005f86:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005f8a:	0037f713          	andi	a4,a5,3
    80005f8e:	00e03733          	snez	a4,a4
    80005f92:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005f96:	4007f793          	andi	a5,a5,1024
    80005f9a:	c791                	beqz	a5,80005fa6 <sys_open+0xd2>
    80005f9c:	04491703          	lh	a4,68(s2)
    80005fa0:	4789                	li	a5,2
    80005fa2:	08f70f63          	beq	a4,a5,80006040 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005fa6:	854a                	mv	a0,s2
    80005fa8:	ffffe097          	auipc	ra,0xffffe
    80005fac:	082080e7          	jalr	130(ra) # 8000402a <iunlock>
  end_op();
    80005fb0:	fffff097          	auipc	ra,0xfffff
    80005fb4:	a0a080e7          	jalr	-1526(ra) # 800049ba <end_op>

  return fd;
}
    80005fb8:	8526                	mv	a0,s1
    80005fba:	70ea                	ld	ra,184(sp)
    80005fbc:	744a                	ld	s0,176(sp)
    80005fbe:	74aa                	ld	s1,168(sp)
    80005fc0:	790a                	ld	s2,160(sp)
    80005fc2:	69ea                	ld	s3,152(sp)
    80005fc4:	6129                	addi	sp,sp,192
    80005fc6:	8082                	ret
      end_op();
    80005fc8:	fffff097          	auipc	ra,0xfffff
    80005fcc:	9f2080e7          	jalr	-1550(ra) # 800049ba <end_op>
      return -1;
    80005fd0:	b7e5                	j	80005fb8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005fd2:	f5040513          	addi	a0,s0,-176
    80005fd6:	ffffe097          	auipc	ra,0xffffe
    80005fda:	748080e7          	jalr	1864(ra) # 8000471e <namei>
    80005fde:	892a                	mv	s2,a0
    80005fe0:	c905                	beqz	a0,80006010 <sys_open+0x13c>
    ilock(ip);
    80005fe2:	ffffe097          	auipc	ra,0xffffe
    80005fe6:	f86080e7          	jalr	-122(ra) # 80003f68 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005fea:	04491703          	lh	a4,68(s2)
    80005fee:	4785                	li	a5,1
    80005ff0:	f4f712e3          	bne	a4,a5,80005f34 <sys_open+0x60>
    80005ff4:	f4c42783          	lw	a5,-180(s0)
    80005ff8:	dba1                	beqz	a5,80005f48 <sys_open+0x74>
      iunlockput(ip);
    80005ffa:	854a                	mv	a0,s2
    80005ffc:	ffffe097          	auipc	ra,0xffffe
    80006000:	1ce080e7          	jalr	462(ra) # 800041ca <iunlockput>
      end_op();
    80006004:	fffff097          	auipc	ra,0xfffff
    80006008:	9b6080e7          	jalr	-1610(ra) # 800049ba <end_op>
      return -1;
    8000600c:	54fd                	li	s1,-1
    8000600e:	b76d                	j	80005fb8 <sys_open+0xe4>
      end_op();
    80006010:	fffff097          	auipc	ra,0xfffff
    80006014:	9aa080e7          	jalr	-1622(ra) # 800049ba <end_op>
      return -1;
    80006018:	54fd                	li	s1,-1
    8000601a:	bf79                	j	80005fb8 <sys_open+0xe4>
    iunlockput(ip);
    8000601c:	854a                	mv	a0,s2
    8000601e:	ffffe097          	auipc	ra,0xffffe
    80006022:	1ac080e7          	jalr	428(ra) # 800041ca <iunlockput>
    end_op();
    80006026:	fffff097          	auipc	ra,0xfffff
    8000602a:	994080e7          	jalr	-1644(ra) # 800049ba <end_op>
    return -1;
    8000602e:	54fd                	li	s1,-1
    80006030:	b761                	j	80005fb8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006032:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006036:	04691783          	lh	a5,70(s2)
    8000603a:	02f99223          	sh	a5,36(s3)
    8000603e:	bf2d                	j	80005f78 <sys_open+0xa4>
    itrunc(ip);
    80006040:	854a                	mv	a0,s2
    80006042:	ffffe097          	auipc	ra,0xffffe
    80006046:	034080e7          	jalr	52(ra) # 80004076 <itrunc>
    8000604a:	bfb1                	j	80005fa6 <sys_open+0xd2>
      fileclose(f);
    8000604c:	854e                	mv	a0,s3
    8000604e:	fffff097          	auipc	ra,0xfffff
    80006052:	db8080e7          	jalr	-584(ra) # 80004e06 <fileclose>
    iunlockput(ip);
    80006056:	854a                	mv	a0,s2
    80006058:	ffffe097          	auipc	ra,0xffffe
    8000605c:	172080e7          	jalr	370(ra) # 800041ca <iunlockput>
    end_op();
    80006060:	fffff097          	auipc	ra,0xfffff
    80006064:	95a080e7          	jalr	-1702(ra) # 800049ba <end_op>
    return -1;
    80006068:	54fd                	li	s1,-1
    8000606a:	b7b9                	j	80005fb8 <sys_open+0xe4>

000000008000606c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000606c:	7175                	addi	sp,sp,-144
    8000606e:	e506                	sd	ra,136(sp)
    80006070:	e122                	sd	s0,128(sp)
    80006072:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006074:	fffff097          	auipc	ra,0xfffff
    80006078:	8c6080e7          	jalr	-1850(ra) # 8000493a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000607c:	08000613          	li	a2,128
    80006080:	f7040593          	addi	a1,s0,-144
    80006084:	4501                	li	a0,0
    80006086:	ffffd097          	auipc	ra,0xffffd
    8000608a:	36a080e7          	jalr	874(ra) # 800033f0 <argstr>
    8000608e:	02054963          	bltz	a0,800060c0 <sys_mkdir+0x54>
    80006092:	4681                	li	a3,0
    80006094:	4601                	li	a2,0
    80006096:	4585                	li	a1,1
    80006098:	f7040513          	addi	a0,s0,-144
    8000609c:	fffff097          	auipc	ra,0xfffff
    800060a0:	7fe080e7          	jalr	2046(ra) # 8000589a <create>
    800060a4:	cd11                	beqz	a0,800060c0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800060a6:	ffffe097          	auipc	ra,0xffffe
    800060aa:	124080e7          	jalr	292(ra) # 800041ca <iunlockput>
  end_op();
    800060ae:	fffff097          	auipc	ra,0xfffff
    800060b2:	90c080e7          	jalr	-1780(ra) # 800049ba <end_op>
  return 0;
    800060b6:	4501                	li	a0,0
}
    800060b8:	60aa                	ld	ra,136(sp)
    800060ba:	640a                	ld	s0,128(sp)
    800060bc:	6149                	addi	sp,sp,144
    800060be:	8082                	ret
    end_op();
    800060c0:	fffff097          	auipc	ra,0xfffff
    800060c4:	8fa080e7          	jalr	-1798(ra) # 800049ba <end_op>
    return -1;
    800060c8:	557d                	li	a0,-1
    800060ca:	b7fd                	j	800060b8 <sys_mkdir+0x4c>

00000000800060cc <sys_mknod>:

uint64
sys_mknod(void)
{
    800060cc:	7135                	addi	sp,sp,-160
    800060ce:	ed06                	sd	ra,152(sp)
    800060d0:	e922                	sd	s0,144(sp)
    800060d2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800060d4:	fffff097          	auipc	ra,0xfffff
    800060d8:	866080e7          	jalr	-1946(ra) # 8000493a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800060dc:	08000613          	li	a2,128
    800060e0:	f7040593          	addi	a1,s0,-144
    800060e4:	4501                	li	a0,0
    800060e6:	ffffd097          	auipc	ra,0xffffd
    800060ea:	30a080e7          	jalr	778(ra) # 800033f0 <argstr>
    800060ee:	04054a63          	bltz	a0,80006142 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800060f2:	f6c40593          	addi	a1,s0,-148
    800060f6:	4505                	li	a0,1
    800060f8:	ffffd097          	auipc	ra,0xffffd
    800060fc:	2b4080e7          	jalr	692(ra) # 800033ac <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006100:	04054163          	bltz	a0,80006142 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006104:	f6840593          	addi	a1,s0,-152
    80006108:	4509                	li	a0,2
    8000610a:	ffffd097          	auipc	ra,0xffffd
    8000610e:	2a2080e7          	jalr	674(ra) # 800033ac <argint>
     argint(1, &major) < 0 ||
    80006112:	02054863          	bltz	a0,80006142 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006116:	f6841683          	lh	a3,-152(s0)
    8000611a:	f6c41603          	lh	a2,-148(s0)
    8000611e:	458d                	li	a1,3
    80006120:	f7040513          	addi	a0,s0,-144
    80006124:	fffff097          	auipc	ra,0xfffff
    80006128:	776080e7          	jalr	1910(ra) # 8000589a <create>
     argint(2, &minor) < 0 ||
    8000612c:	c919                	beqz	a0,80006142 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000612e:	ffffe097          	auipc	ra,0xffffe
    80006132:	09c080e7          	jalr	156(ra) # 800041ca <iunlockput>
  end_op();
    80006136:	fffff097          	auipc	ra,0xfffff
    8000613a:	884080e7          	jalr	-1916(ra) # 800049ba <end_op>
  return 0;
    8000613e:	4501                	li	a0,0
    80006140:	a031                	j	8000614c <sys_mknod+0x80>
    end_op();
    80006142:	fffff097          	auipc	ra,0xfffff
    80006146:	878080e7          	jalr	-1928(ra) # 800049ba <end_op>
    return -1;
    8000614a:	557d                	li	a0,-1
}
    8000614c:	60ea                	ld	ra,152(sp)
    8000614e:	644a                	ld	s0,144(sp)
    80006150:	610d                	addi	sp,sp,160
    80006152:	8082                	ret

0000000080006154 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006154:	7135                	addi	sp,sp,-160
    80006156:	ed06                	sd	ra,152(sp)
    80006158:	e922                	sd	s0,144(sp)
    8000615a:	e526                	sd	s1,136(sp)
    8000615c:	e14a                	sd	s2,128(sp)
    8000615e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006160:	ffffc097          	auipc	ra,0xffffc
    80006164:	cfc080e7          	jalr	-772(ra) # 80001e5c <myproc>
    80006168:	892a                	mv	s2,a0
  
  begin_op();
    8000616a:	ffffe097          	auipc	ra,0xffffe
    8000616e:	7d0080e7          	jalr	2000(ra) # 8000493a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006172:	08000613          	li	a2,128
    80006176:	f6040593          	addi	a1,s0,-160
    8000617a:	4501                	li	a0,0
    8000617c:	ffffd097          	auipc	ra,0xffffd
    80006180:	274080e7          	jalr	628(ra) # 800033f0 <argstr>
    80006184:	04054b63          	bltz	a0,800061da <sys_chdir+0x86>
    80006188:	f6040513          	addi	a0,s0,-160
    8000618c:	ffffe097          	auipc	ra,0xffffe
    80006190:	592080e7          	jalr	1426(ra) # 8000471e <namei>
    80006194:	84aa                	mv	s1,a0
    80006196:	c131                	beqz	a0,800061da <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006198:	ffffe097          	auipc	ra,0xffffe
    8000619c:	dd0080e7          	jalr	-560(ra) # 80003f68 <ilock>
  if(ip->type != T_DIR){
    800061a0:	04449703          	lh	a4,68(s1)
    800061a4:	4785                	li	a5,1
    800061a6:	04f71063          	bne	a4,a5,800061e6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800061aa:	8526                	mv	a0,s1
    800061ac:	ffffe097          	auipc	ra,0xffffe
    800061b0:	e7e080e7          	jalr	-386(ra) # 8000402a <iunlock>
  iput(p->cwd);
    800061b4:	17093503          	ld	a0,368(s2)
    800061b8:	ffffe097          	auipc	ra,0xffffe
    800061bc:	f6a080e7          	jalr	-150(ra) # 80004122 <iput>
  end_op();
    800061c0:	ffffe097          	auipc	ra,0xffffe
    800061c4:	7fa080e7          	jalr	2042(ra) # 800049ba <end_op>
  p->cwd = ip;
    800061c8:	16993823          	sd	s1,368(s2)
  return 0;
    800061cc:	4501                	li	a0,0
}
    800061ce:	60ea                	ld	ra,152(sp)
    800061d0:	644a                	ld	s0,144(sp)
    800061d2:	64aa                	ld	s1,136(sp)
    800061d4:	690a                	ld	s2,128(sp)
    800061d6:	610d                	addi	sp,sp,160
    800061d8:	8082                	ret
    end_op();
    800061da:	ffffe097          	auipc	ra,0xffffe
    800061de:	7e0080e7          	jalr	2016(ra) # 800049ba <end_op>
    return -1;
    800061e2:	557d                	li	a0,-1
    800061e4:	b7ed                	j	800061ce <sys_chdir+0x7a>
    iunlockput(ip);
    800061e6:	8526                	mv	a0,s1
    800061e8:	ffffe097          	auipc	ra,0xffffe
    800061ec:	fe2080e7          	jalr	-30(ra) # 800041ca <iunlockput>
    end_op();
    800061f0:	ffffe097          	auipc	ra,0xffffe
    800061f4:	7ca080e7          	jalr	1994(ra) # 800049ba <end_op>
    return -1;
    800061f8:	557d                	li	a0,-1
    800061fa:	bfd1                	j	800061ce <sys_chdir+0x7a>

00000000800061fc <sys_exec>:

uint64
sys_exec(void)
{
    800061fc:	7145                	addi	sp,sp,-464
    800061fe:	e786                	sd	ra,456(sp)
    80006200:	e3a2                	sd	s0,448(sp)
    80006202:	ff26                	sd	s1,440(sp)
    80006204:	fb4a                	sd	s2,432(sp)
    80006206:	f74e                	sd	s3,424(sp)
    80006208:	f352                	sd	s4,416(sp)
    8000620a:	ef56                	sd	s5,408(sp)
    8000620c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000620e:	08000613          	li	a2,128
    80006212:	f4040593          	addi	a1,s0,-192
    80006216:	4501                	li	a0,0
    80006218:	ffffd097          	auipc	ra,0xffffd
    8000621c:	1d8080e7          	jalr	472(ra) # 800033f0 <argstr>
    return -1;
    80006220:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006222:	0c054a63          	bltz	a0,800062f6 <sys_exec+0xfa>
    80006226:	e3840593          	addi	a1,s0,-456
    8000622a:	4505                	li	a0,1
    8000622c:	ffffd097          	auipc	ra,0xffffd
    80006230:	1a2080e7          	jalr	418(ra) # 800033ce <argaddr>
    80006234:	0c054163          	bltz	a0,800062f6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006238:	10000613          	li	a2,256
    8000623c:	4581                	li	a1,0
    8000623e:	e4040513          	addi	a0,s0,-448
    80006242:	ffffb097          	auipc	ra,0xffffb
    80006246:	ad0080e7          	jalr	-1328(ra) # 80000d12 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000624a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000624e:	89a6                	mv	s3,s1
    80006250:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006252:	02000a13          	li	s4,32
    80006256:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000625a:	00391513          	slli	a0,s2,0x3
    8000625e:	e3040593          	addi	a1,s0,-464
    80006262:	e3843783          	ld	a5,-456(s0)
    80006266:	953e                	add	a0,a0,a5
    80006268:	ffffd097          	auipc	ra,0xffffd
    8000626c:	0aa080e7          	jalr	170(ra) # 80003312 <fetchaddr>
    80006270:	02054a63          	bltz	a0,800062a4 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006274:	e3043783          	ld	a5,-464(s0)
    80006278:	c3b9                	beqz	a5,800062be <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000627a:	ffffb097          	auipc	ra,0xffffb
    8000627e:	87a080e7          	jalr	-1926(ra) # 80000af4 <kalloc>
    80006282:	85aa                	mv	a1,a0
    80006284:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006288:	cd11                	beqz	a0,800062a4 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000628a:	6605                	lui	a2,0x1
    8000628c:	e3043503          	ld	a0,-464(s0)
    80006290:	ffffd097          	auipc	ra,0xffffd
    80006294:	0d4080e7          	jalr	212(ra) # 80003364 <fetchstr>
    80006298:	00054663          	bltz	a0,800062a4 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000629c:	0905                	addi	s2,s2,1
    8000629e:	09a1                	addi	s3,s3,8
    800062a0:	fb491be3          	bne	s2,s4,80006256 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062a4:	10048913          	addi	s2,s1,256
    800062a8:	6088                	ld	a0,0(s1)
    800062aa:	c529                	beqz	a0,800062f4 <sys_exec+0xf8>
    kfree(argv[i]);
    800062ac:	ffffa097          	auipc	ra,0xffffa
    800062b0:	74c080e7          	jalr	1868(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062b4:	04a1                	addi	s1,s1,8
    800062b6:	ff2499e3          	bne	s1,s2,800062a8 <sys_exec+0xac>
  return -1;
    800062ba:	597d                	li	s2,-1
    800062bc:	a82d                	j	800062f6 <sys_exec+0xfa>
      argv[i] = 0;
    800062be:	0a8e                	slli	s5,s5,0x3
    800062c0:	fc040793          	addi	a5,s0,-64
    800062c4:	9abe                	add	s5,s5,a5
    800062c6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800062ca:	e4040593          	addi	a1,s0,-448
    800062ce:	f4040513          	addi	a0,s0,-192
    800062d2:	fffff097          	auipc	ra,0xfffff
    800062d6:	194080e7          	jalr	404(ra) # 80005466 <exec>
    800062da:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062dc:	10048993          	addi	s3,s1,256
    800062e0:	6088                	ld	a0,0(s1)
    800062e2:	c911                	beqz	a0,800062f6 <sys_exec+0xfa>
    kfree(argv[i]);
    800062e4:	ffffa097          	auipc	ra,0xffffa
    800062e8:	714080e7          	jalr	1812(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062ec:	04a1                	addi	s1,s1,8
    800062ee:	ff3499e3          	bne	s1,s3,800062e0 <sys_exec+0xe4>
    800062f2:	a011                	j	800062f6 <sys_exec+0xfa>
  return -1;
    800062f4:	597d                	li	s2,-1
}
    800062f6:	854a                	mv	a0,s2
    800062f8:	60be                	ld	ra,456(sp)
    800062fa:	641e                	ld	s0,448(sp)
    800062fc:	74fa                	ld	s1,440(sp)
    800062fe:	795a                	ld	s2,432(sp)
    80006300:	79ba                	ld	s3,424(sp)
    80006302:	7a1a                	ld	s4,416(sp)
    80006304:	6afa                	ld	s5,408(sp)
    80006306:	6179                	addi	sp,sp,464
    80006308:	8082                	ret

000000008000630a <sys_pipe>:

uint64
sys_pipe(void)
{
    8000630a:	7139                	addi	sp,sp,-64
    8000630c:	fc06                	sd	ra,56(sp)
    8000630e:	f822                	sd	s0,48(sp)
    80006310:	f426                	sd	s1,40(sp)
    80006312:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006314:	ffffc097          	auipc	ra,0xffffc
    80006318:	b48080e7          	jalr	-1208(ra) # 80001e5c <myproc>
    8000631c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000631e:	fd840593          	addi	a1,s0,-40
    80006322:	4501                	li	a0,0
    80006324:	ffffd097          	auipc	ra,0xffffd
    80006328:	0aa080e7          	jalr	170(ra) # 800033ce <argaddr>
    return -1;
    8000632c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000632e:	0e054063          	bltz	a0,8000640e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006332:	fc840593          	addi	a1,s0,-56
    80006336:	fd040513          	addi	a0,s0,-48
    8000633a:	fffff097          	auipc	ra,0xfffff
    8000633e:	dfc080e7          	jalr	-516(ra) # 80005136 <pipealloc>
    return -1;
    80006342:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006344:	0c054563          	bltz	a0,8000640e <sys_pipe+0x104>
  fd0 = -1;
    80006348:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000634c:	fd043503          	ld	a0,-48(s0)
    80006350:	fffff097          	auipc	ra,0xfffff
    80006354:	508080e7          	jalr	1288(ra) # 80005858 <fdalloc>
    80006358:	fca42223          	sw	a0,-60(s0)
    8000635c:	08054c63          	bltz	a0,800063f4 <sys_pipe+0xea>
    80006360:	fc843503          	ld	a0,-56(s0)
    80006364:	fffff097          	auipc	ra,0xfffff
    80006368:	4f4080e7          	jalr	1268(ra) # 80005858 <fdalloc>
    8000636c:	fca42023          	sw	a0,-64(s0)
    80006370:	06054863          	bltz	a0,800063e0 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006374:	4691                	li	a3,4
    80006376:	fc440613          	addi	a2,s0,-60
    8000637a:	fd843583          	ld	a1,-40(s0)
    8000637e:	78a8                	ld	a0,112(s1)
    80006380:	ffffb097          	auipc	ra,0xffffb
    80006384:	324080e7          	jalr	804(ra) # 800016a4 <copyout>
    80006388:	02054063          	bltz	a0,800063a8 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000638c:	4691                	li	a3,4
    8000638e:	fc040613          	addi	a2,s0,-64
    80006392:	fd843583          	ld	a1,-40(s0)
    80006396:	0591                	addi	a1,a1,4
    80006398:	78a8                	ld	a0,112(s1)
    8000639a:	ffffb097          	auipc	ra,0xffffb
    8000639e:	30a080e7          	jalr	778(ra) # 800016a4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800063a2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800063a4:	06055563          	bgez	a0,8000640e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800063a8:	fc442783          	lw	a5,-60(s0)
    800063ac:	07f9                	addi	a5,a5,30
    800063ae:	078e                	slli	a5,a5,0x3
    800063b0:	97a6                	add	a5,a5,s1
    800063b2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800063b6:	fc042503          	lw	a0,-64(s0)
    800063ba:	0579                	addi	a0,a0,30
    800063bc:	050e                	slli	a0,a0,0x3
    800063be:	9526                	add	a0,a0,s1
    800063c0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800063c4:	fd043503          	ld	a0,-48(s0)
    800063c8:	fffff097          	auipc	ra,0xfffff
    800063cc:	a3e080e7          	jalr	-1474(ra) # 80004e06 <fileclose>
    fileclose(wf);
    800063d0:	fc843503          	ld	a0,-56(s0)
    800063d4:	fffff097          	auipc	ra,0xfffff
    800063d8:	a32080e7          	jalr	-1486(ra) # 80004e06 <fileclose>
    return -1;
    800063dc:	57fd                	li	a5,-1
    800063de:	a805                	j	8000640e <sys_pipe+0x104>
    if(fd0 >= 0)
    800063e0:	fc442783          	lw	a5,-60(s0)
    800063e4:	0007c863          	bltz	a5,800063f4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800063e8:	01e78513          	addi	a0,a5,30
    800063ec:	050e                	slli	a0,a0,0x3
    800063ee:	9526                	add	a0,a0,s1
    800063f0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800063f4:	fd043503          	ld	a0,-48(s0)
    800063f8:	fffff097          	auipc	ra,0xfffff
    800063fc:	a0e080e7          	jalr	-1522(ra) # 80004e06 <fileclose>
    fileclose(wf);
    80006400:	fc843503          	ld	a0,-56(s0)
    80006404:	fffff097          	auipc	ra,0xfffff
    80006408:	a02080e7          	jalr	-1534(ra) # 80004e06 <fileclose>
    return -1;
    8000640c:	57fd                	li	a5,-1
}
    8000640e:	853e                	mv	a0,a5
    80006410:	70e2                	ld	ra,56(sp)
    80006412:	7442                	ld	s0,48(sp)
    80006414:	74a2                	ld	s1,40(sp)
    80006416:	6121                	addi	sp,sp,64
    80006418:	8082                	ret
    8000641a:	0000                	unimp
    8000641c:	0000                	unimp
	...

0000000080006420 <kernelvec>:
    80006420:	7111                	addi	sp,sp,-256
    80006422:	e006                	sd	ra,0(sp)
    80006424:	e40a                	sd	sp,8(sp)
    80006426:	e80e                	sd	gp,16(sp)
    80006428:	ec12                	sd	tp,24(sp)
    8000642a:	f016                	sd	t0,32(sp)
    8000642c:	f41a                	sd	t1,40(sp)
    8000642e:	f81e                	sd	t2,48(sp)
    80006430:	fc22                	sd	s0,56(sp)
    80006432:	e0a6                	sd	s1,64(sp)
    80006434:	e4aa                	sd	a0,72(sp)
    80006436:	e8ae                	sd	a1,80(sp)
    80006438:	ecb2                	sd	a2,88(sp)
    8000643a:	f0b6                	sd	a3,96(sp)
    8000643c:	f4ba                	sd	a4,104(sp)
    8000643e:	f8be                	sd	a5,112(sp)
    80006440:	fcc2                	sd	a6,120(sp)
    80006442:	e146                	sd	a7,128(sp)
    80006444:	e54a                	sd	s2,136(sp)
    80006446:	e94e                	sd	s3,144(sp)
    80006448:	ed52                	sd	s4,152(sp)
    8000644a:	f156                	sd	s5,160(sp)
    8000644c:	f55a                	sd	s6,168(sp)
    8000644e:	f95e                	sd	s7,176(sp)
    80006450:	fd62                	sd	s8,184(sp)
    80006452:	e1e6                	sd	s9,192(sp)
    80006454:	e5ea                	sd	s10,200(sp)
    80006456:	e9ee                	sd	s11,208(sp)
    80006458:	edf2                	sd	t3,216(sp)
    8000645a:	f1f6                	sd	t4,224(sp)
    8000645c:	f5fa                	sd	t5,232(sp)
    8000645e:	f9fe                	sd	t6,240(sp)
    80006460:	d7ffc0ef          	jal	ra,800031de <kerneltrap>
    80006464:	6082                	ld	ra,0(sp)
    80006466:	6122                	ld	sp,8(sp)
    80006468:	61c2                	ld	gp,16(sp)
    8000646a:	7282                	ld	t0,32(sp)
    8000646c:	7322                	ld	t1,40(sp)
    8000646e:	73c2                	ld	t2,48(sp)
    80006470:	7462                	ld	s0,56(sp)
    80006472:	6486                	ld	s1,64(sp)
    80006474:	6526                	ld	a0,72(sp)
    80006476:	65c6                	ld	a1,80(sp)
    80006478:	6666                	ld	a2,88(sp)
    8000647a:	7686                	ld	a3,96(sp)
    8000647c:	7726                	ld	a4,104(sp)
    8000647e:	77c6                	ld	a5,112(sp)
    80006480:	7866                	ld	a6,120(sp)
    80006482:	688a                	ld	a7,128(sp)
    80006484:	692a                	ld	s2,136(sp)
    80006486:	69ca                	ld	s3,144(sp)
    80006488:	6a6a                	ld	s4,152(sp)
    8000648a:	7a8a                	ld	s5,160(sp)
    8000648c:	7b2a                	ld	s6,168(sp)
    8000648e:	7bca                	ld	s7,176(sp)
    80006490:	7c6a                	ld	s8,184(sp)
    80006492:	6c8e                	ld	s9,192(sp)
    80006494:	6d2e                	ld	s10,200(sp)
    80006496:	6dce                	ld	s11,208(sp)
    80006498:	6e6e                	ld	t3,216(sp)
    8000649a:	7e8e                	ld	t4,224(sp)
    8000649c:	7f2e                	ld	t5,232(sp)
    8000649e:	7fce                	ld	t6,240(sp)
    800064a0:	6111                	addi	sp,sp,256
    800064a2:	10200073          	sret
    800064a6:	00000013          	nop
    800064aa:	00000013          	nop
    800064ae:	0001                	nop

00000000800064b0 <timervec>:
    800064b0:	34051573          	csrrw	a0,mscratch,a0
    800064b4:	e10c                	sd	a1,0(a0)
    800064b6:	e510                	sd	a2,8(a0)
    800064b8:	e914                	sd	a3,16(a0)
    800064ba:	6d0c                	ld	a1,24(a0)
    800064bc:	7110                	ld	a2,32(a0)
    800064be:	6194                	ld	a3,0(a1)
    800064c0:	96b2                	add	a3,a3,a2
    800064c2:	e194                	sd	a3,0(a1)
    800064c4:	4589                	li	a1,2
    800064c6:	14459073          	csrw	sip,a1
    800064ca:	6914                	ld	a3,16(a0)
    800064cc:	6510                	ld	a2,8(a0)
    800064ce:	610c                	ld	a1,0(a0)
    800064d0:	34051573          	csrrw	a0,mscratch,a0
    800064d4:	30200073          	mret
	...

00000000800064da <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800064da:	1141                	addi	sp,sp,-16
    800064dc:	e422                	sd	s0,8(sp)
    800064de:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800064e0:	0c0007b7          	lui	a5,0xc000
    800064e4:	4705                	li	a4,1
    800064e6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800064e8:	c3d8                	sw	a4,4(a5)
}
    800064ea:	6422                	ld	s0,8(sp)
    800064ec:	0141                	addi	sp,sp,16
    800064ee:	8082                	ret

00000000800064f0 <plicinithart>:

void
plicinithart(void)
{
    800064f0:	1141                	addi	sp,sp,-16
    800064f2:	e406                	sd	ra,8(sp)
    800064f4:	e022                	sd	s0,0(sp)
    800064f6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064f8:	ffffc097          	auipc	ra,0xffffc
    800064fc:	932080e7          	jalr	-1742(ra) # 80001e2a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006500:	0085171b          	slliw	a4,a0,0x8
    80006504:	0c0027b7          	lui	a5,0xc002
    80006508:	97ba                	add	a5,a5,a4
    8000650a:	40200713          	li	a4,1026
    8000650e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006512:	00d5151b          	slliw	a0,a0,0xd
    80006516:	0c2017b7          	lui	a5,0xc201
    8000651a:	953e                	add	a0,a0,a5
    8000651c:	00052023          	sw	zero,0(a0)
}
    80006520:	60a2                	ld	ra,8(sp)
    80006522:	6402                	ld	s0,0(sp)
    80006524:	0141                	addi	sp,sp,16
    80006526:	8082                	ret

0000000080006528 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006528:	1141                	addi	sp,sp,-16
    8000652a:	e406                	sd	ra,8(sp)
    8000652c:	e022                	sd	s0,0(sp)
    8000652e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006530:	ffffc097          	auipc	ra,0xffffc
    80006534:	8fa080e7          	jalr	-1798(ra) # 80001e2a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006538:	00d5179b          	slliw	a5,a0,0xd
    8000653c:	0c201537          	lui	a0,0xc201
    80006540:	953e                	add	a0,a0,a5
  return irq;
}
    80006542:	4148                	lw	a0,4(a0)
    80006544:	60a2                	ld	ra,8(sp)
    80006546:	6402                	ld	s0,0(sp)
    80006548:	0141                	addi	sp,sp,16
    8000654a:	8082                	ret

000000008000654c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000654c:	1101                	addi	sp,sp,-32
    8000654e:	ec06                	sd	ra,24(sp)
    80006550:	e822                	sd	s0,16(sp)
    80006552:	e426                	sd	s1,8(sp)
    80006554:	1000                	addi	s0,sp,32
    80006556:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006558:	ffffc097          	auipc	ra,0xffffc
    8000655c:	8d2080e7          	jalr	-1838(ra) # 80001e2a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006560:	00d5151b          	slliw	a0,a0,0xd
    80006564:	0c2017b7          	lui	a5,0xc201
    80006568:	97aa                	add	a5,a5,a0
    8000656a:	c3c4                	sw	s1,4(a5)
}
    8000656c:	60e2                	ld	ra,24(sp)
    8000656e:	6442                	ld	s0,16(sp)
    80006570:	64a2                	ld	s1,8(sp)
    80006572:	6105                	addi	sp,sp,32
    80006574:	8082                	ret

0000000080006576 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006576:	1141                	addi	sp,sp,-16
    80006578:	e406                	sd	ra,8(sp)
    8000657a:	e022                	sd	s0,0(sp)
    8000657c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000657e:	479d                	li	a5,7
    80006580:	06a7c963          	blt	a5,a0,800065f2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006584:	0001d797          	auipc	a5,0x1d
    80006588:	a7c78793          	addi	a5,a5,-1412 # 80023000 <disk>
    8000658c:	00a78733          	add	a4,a5,a0
    80006590:	6789                	lui	a5,0x2
    80006592:	97ba                	add	a5,a5,a4
    80006594:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006598:	e7ad                	bnez	a5,80006602 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000659a:	00451793          	slli	a5,a0,0x4
    8000659e:	0001f717          	auipc	a4,0x1f
    800065a2:	a6270713          	addi	a4,a4,-1438 # 80025000 <disk+0x2000>
    800065a6:	6314                	ld	a3,0(a4)
    800065a8:	96be                	add	a3,a3,a5
    800065aa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800065ae:	6314                	ld	a3,0(a4)
    800065b0:	96be                	add	a3,a3,a5
    800065b2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800065b6:	6314                	ld	a3,0(a4)
    800065b8:	96be                	add	a3,a3,a5
    800065ba:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800065be:	6318                	ld	a4,0(a4)
    800065c0:	97ba                	add	a5,a5,a4
    800065c2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800065c6:	0001d797          	auipc	a5,0x1d
    800065ca:	a3a78793          	addi	a5,a5,-1478 # 80023000 <disk>
    800065ce:	97aa                	add	a5,a5,a0
    800065d0:	6509                	lui	a0,0x2
    800065d2:	953e                	add	a0,a0,a5
    800065d4:	4785                	li	a5,1
    800065d6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800065da:	0001f517          	auipc	a0,0x1f
    800065de:	a3e50513          	addi	a0,a0,-1474 # 80025018 <disk+0x2018>
    800065e2:	ffffc097          	auipc	ra,0xffffc
    800065e6:	3fa080e7          	jalr	1018(ra) # 800029dc <wakeup>
}
    800065ea:	60a2                	ld	ra,8(sp)
    800065ec:	6402                	ld	s0,0(sp)
    800065ee:	0141                	addi	sp,sp,16
    800065f0:	8082                	ret
    panic("free_desc 1");
    800065f2:	00002517          	auipc	a0,0x2
    800065f6:	1b650513          	addi	a0,a0,438 # 800087a8 <syscalls+0x330>
    800065fa:	ffffa097          	auipc	ra,0xffffa
    800065fe:	f44080e7          	jalr	-188(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006602:	00002517          	auipc	a0,0x2
    80006606:	1b650513          	addi	a0,a0,438 # 800087b8 <syscalls+0x340>
    8000660a:	ffffa097          	auipc	ra,0xffffa
    8000660e:	f34080e7          	jalr	-204(ra) # 8000053e <panic>

0000000080006612 <virtio_disk_init>:
{
    80006612:	1101                	addi	sp,sp,-32
    80006614:	ec06                	sd	ra,24(sp)
    80006616:	e822                	sd	s0,16(sp)
    80006618:	e426                	sd	s1,8(sp)
    8000661a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000661c:	00002597          	auipc	a1,0x2
    80006620:	1ac58593          	addi	a1,a1,428 # 800087c8 <syscalls+0x350>
    80006624:	0001f517          	auipc	a0,0x1f
    80006628:	b0450513          	addi	a0,a0,-1276 # 80025128 <disk+0x2128>
    8000662c:	ffffa097          	auipc	ra,0xffffa
    80006630:	528080e7          	jalr	1320(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006634:	100017b7          	lui	a5,0x10001
    80006638:	4398                	lw	a4,0(a5)
    8000663a:	2701                	sext.w	a4,a4
    8000663c:	747277b7          	lui	a5,0x74727
    80006640:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006644:	0ef71163          	bne	a4,a5,80006726 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006648:	100017b7          	lui	a5,0x10001
    8000664c:	43dc                	lw	a5,4(a5)
    8000664e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006650:	4705                	li	a4,1
    80006652:	0ce79a63          	bne	a5,a4,80006726 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006656:	100017b7          	lui	a5,0x10001
    8000665a:	479c                	lw	a5,8(a5)
    8000665c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000665e:	4709                	li	a4,2
    80006660:	0ce79363          	bne	a5,a4,80006726 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006664:	100017b7          	lui	a5,0x10001
    80006668:	47d8                	lw	a4,12(a5)
    8000666a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000666c:	554d47b7          	lui	a5,0x554d4
    80006670:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006674:	0af71963          	bne	a4,a5,80006726 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006678:	100017b7          	lui	a5,0x10001
    8000667c:	4705                	li	a4,1
    8000667e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006680:	470d                	li	a4,3
    80006682:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006684:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006686:	c7ffe737          	lui	a4,0xc7ffe
    8000668a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000668e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006690:	2701                	sext.w	a4,a4
    80006692:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006694:	472d                	li	a4,11
    80006696:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006698:	473d                	li	a4,15
    8000669a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000669c:	6705                	lui	a4,0x1
    8000669e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800066a0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800066a4:	5bdc                	lw	a5,52(a5)
    800066a6:	2781                	sext.w	a5,a5
  if(max == 0)
    800066a8:	c7d9                	beqz	a5,80006736 <virtio_disk_init+0x124>
  if(max < NUM)
    800066aa:	471d                	li	a4,7
    800066ac:	08f77d63          	bgeu	a4,a5,80006746 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800066b0:	100014b7          	lui	s1,0x10001
    800066b4:	47a1                	li	a5,8
    800066b6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800066b8:	6609                	lui	a2,0x2
    800066ba:	4581                	li	a1,0
    800066bc:	0001d517          	auipc	a0,0x1d
    800066c0:	94450513          	addi	a0,a0,-1724 # 80023000 <disk>
    800066c4:	ffffa097          	auipc	ra,0xffffa
    800066c8:	64e080e7          	jalr	1614(ra) # 80000d12 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800066cc:	0001d717          	auipc	a4,0x1d
    800066d0:	93470713          	addi	a4,a4,-1740 # 80023000 <disk>
    800066d4:	00c75793          	srli	a5,a4,0xc
    800066d8:	2781                	sext.w	a5,a5
    800066da:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800066dc:	0001f797          	auipc	a5,0x1f
    800066e0:	92478793          	addi	a5,a5,-1756 # 80025000 <disk+0x2000>
    800066e4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800066e6:	0001d717          	auipc	a4,0x1d
    800066ea:	99a70713          	addi	a4,a4,-1638 # 80023080 <disk+0x80>
    800066ee:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800066f0:	0001e717          	auipc	a4,0x1e
    800066f4:	91070713          	addi	a4,a4,-1776 # 80024000 <disk+0x1000>
    800066f8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800066fa:	4705                	li	a4,1
    800066fc:	00e78c23          	sb	a4,24(a5)
    80006700:	00e78ca3          	sb	a4,25(a5)
    80006704:	00e78d23          	sb	a4,26(a5)
    80006708:	00e78da3          	sb	a4,27(a5)
    8000670c:	00e78e23          	sb	a4,28(a5)
    80006710:	00e78ea3          	sb	a4,29(a5)
    80006714:	00e78f23          	sb	a4,30(a5)
    80006718:	00e78fa3          	sb	a4,31(a5)
}
    8000671c:	60e2                	ld	ra,24(sp)
    8000671e:	6442                	ld	s0,16(sp)
    80006720:	64a2                	ld	s1,8(sp)
    80006722:	6105                	addi	sp,sp,32
    80006724:	8082                	ret
    panic("could not find virtio disk");
    80006726:	00002517          	auipc	a0,0x2
    8000672a:	0b250513          	addi	a0,a0,178 # 800087d8 <syscalls+0x360>
    8000672e:	ffffa097          	auipc	ra,0xffffa
    80006732:	e10080e7          	jalr	-496(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006736:	00002517          	auipc	a0,0x2
    8000673a:	0c250513          	addi	a0,a0,194 # 800087f8 <syscalls+0x380>
    8000673e:	ffffa097          	auipc	ra,0xffffa
    80006742:	e00080e7          	jalr	-512(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006746:	00002517          	auipc	a0,0x2
    8000674a:	0d250513          	addi	a0,a0,210 # 80008818 <syscalls+0x3a0>
    8000674e:	ffffa097          	auipc	ra,0xffffa
    80006752:	df0080e7          	jalr	-528(ra) # 8000053e <panic>

0000000080006756 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006756:	7159                	addi	sp,sp,-112
    80006758:	f486                	sd	ra,104(sp)
    8000675a:	f0a2                	sd	s0,96(sp)
    8000675c:	eca6                	sd	s1,88(sp)
    8000675e:	e8ca                	sd	s2,80(sp)
    80006760:	e4ce                	sd	s3,72(sp)
    80006762:	e0d2                	sd	s4,64(sp)
    80006764:	fc56                	sd	s5,56(sp)
    80006766:	f85a                	sd	s6,48(sp)
    80006768:	f45e                	sd	s7,40(sp)
    8000676a:	f062                	sd	s8,32(sp)
    8000676c:	ec66                	sd	s9,24(sp)
    8000676e:	e86a                	sd	s10,16(sp)
    80006770:	1880                	addi	s0,sp,112
    80006772:	892a                	mv	s2,a0
    80006774:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006776:	00c52c83          	lw	s9,12(a0)
    8000677a:	001c9c9b          	slliw	s9,s9,0x1
    8000677e:	1c82                	slli	s9,s9,0x20
    80006780:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006784:	0001f517          	auipc	a0,0x1f
    80006788:	9a450513          	addi	a0,a0,-1628 # 80025128 <disk+0x2128>
    8000678c:	ffffa097          	auipc	ra,0xffffa
    80006790:	460080e7          	jalr	1120(ra) # 80000bec <acquire>
  for(int i = 0; i < 3; i++){
    80006794:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006796:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006798:	0001db97          	auipc	s7,0x1d
    8000679c:	868b8b93          	addi	s7,s7,-1944 # 80023000 <disk>
    800067a0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800067a2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800067a4:	8a4e                	mv	s4,s3
    800067a6:	a051                	j	8000682a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800067a8:	00fb86b3          	add	a3,s7,a5
    800067ac:	96da                	add	a3,a3,s6
    800067ae:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800067b2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800067b4:	0207c563          	bltz	a5,800067de <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800067b8:	2485                	addiw	s1,s1,1
    800067ba:	0711                	addi	a4,a4,4
    800067bc:	25548063          	beq	s1,s5,800069fc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800067c0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800067c2:	0001f697          	auipc	a3,0x1f
    800067c6:	85668693          	addi	a3,a3,-1962 # 80025018 <disk+0x2018>
    800067ca:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800067cc:	0006c583          	lbu	a1,0(a3)
    800067d0:	fde1                	bnez	a1,800067a8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800067d2:	2785                	addiw	a5,a5,1
    800067d4:	0685                	addi	a3,a3,1
    800067d6:	ff879be3          	bne	a5,s8,800067cc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800067da:	57fd                	li	a5,-1
    800067dc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800067de:	02905a63          	blez	s1,80006812 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800067e2:	f9042503          	lw	a0,-112(s0)
    800067e6:	00000097          	auipc	ra,0x0
    800067ea:	d90080e7          	jalr	-624(ra) # 80006576 <free_desc>
      for(int j = 0; j < i; j++)
    800067ee:	4785                	li	a5,1
    800067f0:	0297d163          	bge	a5,s1,80006812 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800067f4:	f9442503          	lw	a0,-108(s0)
    800067f8:	00000097          	auipc	ra,0x0
    800067fc:	d7e080e7          	jalr	-642(ra) # 80006576 <free_desc>
      for(int j = 0; j < i; j++)
    80006800:	4789                	li	a5,2
    80006802:	0097d863          	bge	a5,s1,80006812 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006806:	f9842503          	lw	a0,-104(s0)
    8000680a:	00000097          	auipc	ra,0x0
    8000680e:	d6c080e7          	jalr	-660(ra) # 80006576 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006812:	0001f597          	auipc	a1,0x1f
    80006816:	91658593          	addi	a1,a1,-1770 # 80025128 <disk+0x2128>
    8000681a:	0001e517          	auipc	a0,0x1e
    8000681e:	7fe50513          	addi	a0,a0,2046 # 80025018 <disk+0x2018>
    80006822:	ffffc097          	auipc	ra,0xffffc
    80006826:	ec8080e7          	jalr	-312(ra) # 800026ea <sleep>
  for(int i = 0; i < 3; i++){
    8000682a:	f9040713          	addi	a4,s0,-112
    8000682e:	84ce                	mv	s1,s3
    80006830:	bf41                	j	800067c0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006832:	20058713          	addi	a4,a1,512
    80006836:	00471693          	slli	a3,a4,0x4
    8000683a:	0001c717          	auipc	a4,0x1c
    8000683e:	7c670713          	addi	a4,a4,1990 # 80023000 <disk>
    80006842:	9736                	add	a4,a4,a3
    80006844:	4685                	li	a3,1
    80006846:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000684a:	20058713          	addi	a4,a1,512
    8000684e:	00471693          	slli	a3,a4,0x4
    80006852:	0001c717          	auipc	a4,0x1c
    80006856:	7ae70713          	addi	a4,a4,1966 # 80023000 <disk>
    8000685a:	9736                	add	a4,a4,a3
    8000685c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006860:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006864:	7679                	lui	a2,0xffffe
    80006866:	963e                	add	a2,a2,a5
    80006868:	0001e697          	auipc	a3,0x1e
    8000686c:	79868693          	addi	a3,a3,1944 # 80025000 <disk+0x2000>
    80006870:	6298                	ld	a4,0(a3)
    80006872:	9732                	add	a4,a4,a2
    80006874:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006876:	6298                	ld	a4,0(a3)
    80006878:	9732                	add	a4,a4,a2
    8000687a:	4541                	li	a0,16
    8000687c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000687e:	6298                	ld	a4,0(a3)
    80006880:	9732                	add	a4,a4,a2
    80006882:	4505                	li	a0,1
    80006884:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006888:	f9442703          	lw	a4,-108(s0)
    8000688c:	6288                	ld	a0,0(a3)
    8000688e:	962a                	add	a2,a2,a0
    80006890:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006894:	0712                	slli	a4,a4,0x4
    80006896:	6290                	ld	a2,0(a3)
    80006898:	963a                	add	a2,a2,a4
    8000689a:	05890513          	addi	a0,s2,88
    8000689e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800068a0:	6294                	ld	a3,0(a3)
    800068a2:	96ba                	add	a3,a3,a4
    800068a4:	40000613          	li	a2,1024
    800068a8:	c690                	sw	a2,8(a3)
  if(write)
    800068aa:	140d0063          	beqz	s10,800069ea <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800068ae:	0001e697          	auipc	a3,0x1e
    800068b2:	7526b683          	ld	a3,1874(a3) # 80025000 <disk+0x2000>
    800068b6:	96ba                	add	a3,a3,a4
    800068b8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800068bc:	0001c817          	auipc	a6,0x1c
    800068c0:	74480813          	addi	a6,a6,1860 # 80023000 <disk>
    800068c4:	0001e517          	auipc	a0,0x1e
    800068c8:	73c50513          	addi	a0,a0,1852 # 80025000 <disk+0x2000>
    800068cc:	6114                	ld	a3,0(a0)
    800068ce:	96ba                	add	a3,a3,a4
    800068d0:	00c6d603          	lhu	a2,12(a3)
    800068d4:	00166613          	ori	a2,a2,1
    800068d8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800068dc:	f9842683          	lw	a3,-104(s0)
    800068e0:	6110                	ld	a2,0(a0)
    800068e2:	9732                	add	a4,a4,a2
    800068e4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800068e8:	20058613          	addi	a2,a1,512
    800068ec:	0612                	slli	a2,a2,0x4
    800068ee:	9642                	add	a2,a2,a6
    800068f0:	577d                	li	a4,-1
    800068f2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800068f6:	00469713          	slli	a4,a3,0x4
    800068fa:	6114                	ld	a3,0(a0)
    800068fc:	96ba                	add	a3,a3,a4
    800068fe:	03078793          	addi	a5,a5,48
    80006902:	97c2                	add	a5,a5,a6
    80006904:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006906:	611c                	ld	a5,0(a0)
    80006908:	97ba                	add	a5,a5,a4
    8000690a:	4685                	li	a3,1
    8000690c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000690e:	611c                	ld	a5,0(a0)
    80006910:	97ba                	add	a5,a5,a4
    80006912:	4809                	li	a6,2
    80006914:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006918:	611c                	ld	a5,0(a0)
    8000691a:	973e                	add	a4,a4,a5
    8000691c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006920:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006924:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006928:	6518                	ld	a4,8(a0)
    8000692a:	00275783          	lhu	a5,2(a4)
    8000692e:	8b9d                	andi	a5,a5,7
    80006930:	0786                	slli	a5,a5,0x1
    80006932:	97ba                	add	a5,a5,a4
    80006934:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006938:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000693c:	6518                	ld	a4,8(a0)
    8000693e:	00275783          	lhu	a5,2(a4)
    80006942:	2785                	addiw	a5,a5,1
    80006944:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006948:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000694c:	100017b7          	lui	a5,0x10001
    80006950:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006954:	00492703          	lw	a4,4(s2)
    80006958:	4785                	li	a5,1
    8000695a:	02f71163          	bne	a4,a5,8000697c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000695e:	0001e997          	auipc	s3,0x1e
    80006962:	7ca98993          	addi	s3,s3,1994 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006966:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006968:	85ce                	mv	a1,s3
    8000696a:	854a                	mv	a0,s2
    8000696c:	ffffc097          	auipc	ra,0xffffc
    80006970:	d7e080e7          	jalr	-642(ra) # 800026ea <sleep>
  while(b->disk == 1) {
    80006974:	00492783          	lw	a5,4(s2)
    80006978:	fe9788e3          	beq	a5,s1,80006968 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000697c:	f9042903          	lw	s2,-112(s0)
    80006980:	20090793          	addi	a5,s2,512
    80006984:	00479713          	slli	a4,a5,0x4
    80006988:	0001c797          	auipc	a5,0x1c
    8000698c:	67878793          	addi	a5,a5,1656 # 80023000 <disk>
    80006990:	97ba                	add	a5,a5,a4
    80006992:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006996:	0001e997          	auipc	s3,0x1e
    8000699a:	66a98993          	addi	s3,s3,1642 # 80025000 <disk+0x2000>
    8000699e:	00491713          	slli	a4,s2,0x4
    800069a2:	0009b783          	ld	a5,0(s3)
    800069a6:	97ba                	add	a5,a5,a4
    800069a8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800069ac:	854a                	mv	a0,s2
    800069ae:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800069b2:	00000097          	auipc	ra,0x0
    800069b6:	bc4080e7          	jalr	-1084(ra) # 80006576 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800069ba:	8885                	andi	s1,s1,1
    800069bc:	f0ed                	bnez	s1,8000699e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800069be:	0001e517          	auipc	a0,0x1e
    800069c2:	76a50513          	addi	a0,a0,1898 # 80025128 <disk+0x2128>
    800069c6:	ffffa097          	auipc	ra,0xffffa
    800069ca:	2f2080e7          	jalr	754(ra) # 80000cb8 <release>
}
    800069ce:	70a6                	ld	ra,104(sp)
    800069d0:	7406                	ld	s0,96(sp)
    800069d2:	64e6                	ld	s1,88(sp)
    800069d4:	6946                	ld	s2,80(sp)
    800069d6:	69a6                	ld	s3,72(sp)
    800069d8:	6a06                	ld	s4,64(sp)
    800069da:	7ae2                	ld	s5,56(sp)
    800069dc:	7b42                	ld	s6,48(sp)
    800069de:	7ba2                	ld	s7,40(sp)
    800069e0:	7c02                	ld	s8,32(sp)
    800069e2:	6ce2                	ld	s9,24(sp)
    800069e4:	6d42                	ld	s10,16(sp)
    800069e6:	6165                	addi	sp,sp,112
    800069e8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800069ea:	0001e697          	auipc	a3,0x1e
    800069ee:	6166b683          	ld	a3,1558(a3) # 80025000 <disk+0x2000>
    800069f2:	96ba                	add	a3,a3,a4
    800069f4:	4609                	li	a2,2
    800069f6:	00c69623          	sh	a2,12(a3)
    800069fa:	b5c9                	j	800068bc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800069fc:	f9042583          	lw	a1,-112(s0)
    80006a00:	20058793          	addi	a5,a1,512
    80006a04:	0792                	slli	a5,a5,0x4
    80006a06:	0001c517          	auipc	a0,0x1c
    80006a0a:	6a250513          	addi	a0,a0,1698 # 800230a8 <disk+0xa8>
    80006a0e:	953e                	add	a0,a0,a5
  if(write)
    80006a10:	e20d11e3          	bnez	s10,80006832 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006a14:	20058713          	addi	a4,a1,512
    80006a18:	00471693          	slli	a3,a4,0x4
    80006a1c:	0001c717          	auipc	a4,0x1c
    80006a20:	5e470713          	addi	a4,a4,1508 # 80023000 <disk>
    80006a24:	9736                	add	a4,a4,a3
    80006a26:	0a072423          	sw	zero,168(a4)
    80006a2a:	b505                	j	8000684a <virtio_disk_rw+0xf4>

0000000080006a2c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006a2c:	1101                	addi	sp,sp,-32
    80006a2e:	ec06                	sd	ra,24(sp)
    80006a30:	e822                	sd	s0,16(sp)
    80006a32:	e426                	sd	s1,8(sp)
    80006a34:	e04a                	sd	s2,0(sp)
    80006a36:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006a38:	0001e517          	auipc	a0,0x1e
    80006a3c:	6f050513          	addi	a0,a0,1776 # 80025128 <disk+0x2128>
    80006a40:	ffffa097          	auipc	ra,0xffffa
    80006a44:	1ac080e7          	jalr	428(ra) # 80000bec <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006a48:	10001737          	lui	a4,0x10001
    80006a4c:	533c                	lw	a5,96(a4)
    80006a4e:	8b8d                	andi	a5,a5,3
    80006a50:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006a52:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006a56:	0001e797          	auipc	a5,0x1e
    80006a5a:	5aa78793          	addi	a5,a5,1450 # 80025000 <disk+0x2000>
    80006a5e:	6b94                	ld	a3,16(a5)
    80006a60:	0207d703          	lhu	a4,32(a5)
    80006a64:	0026d783          	lhu	a5,2(a3)
    80006a68:	06f70163          	beq	a4,a5,80006aca <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006a6c:	0001c917          	auipc	s2,0x1c
    80006a70:	59490913          	addi	s2,s2,1428 # 80023000 <disk>
    80006a74:	0001e497          	auipc	s1,0x1e
    80006a78:	58c48493          	addi	s1,s1,1420 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006a7c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006a80:	6898                	ld	a4,16(s1)
    80006a82:	0204d783          	lhu	a5,32(s1)
    80006a86:	8b9d                	andi	a5,a5,7
    80006a88:	078e                	slli	a5,a5,0x3
    80006a8a:	97ba                	add	a5,a5,a4
    80006a8c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006a8e:	20078713          	addi	a4,a5,512
    80006a92:	0712                	slli	a4,a4,0x4
    80006a94:	974a                	add	a4,a4,s2
    80006a96:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006a9a:	e731                	bnez	a4,80006ae6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006a9c:	20078793          	addi	a5,a5,512
    80006aa0:	0792                	slli	a5,a5,0x4
    80006aa2:	97ca                	add	a5,a5,s2
    80006aa4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006aa6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006aaa:	ffffc097          	auipc	ra,0xffffc
    80006aae:	f32080e7          	jalr	-206(ra) # 800029dc <wakeup>

    disk.used_idx += 1;
    80006ab2:	0204d783          	lhu	a5,32(s1)
    80006ab6:	2785                	addiw	a5,a5,1
    80006ab8:	17c2                	slli	a5,a5,0x30
    80006aba:	93c1                	srli	a5,a5,0x30
    80006abc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006ac0:	6898                	ld	a4,16(s1)
    80006ac2:	00275703          	lhu	a4,2(a4)
    80006ac6:	faf71be3          	bne	a4,a5,80006a7c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006aca:	0001e517          	auipc	a0,0x1e
    80006ace:	65e50513          	addi	a0,a0,1630 # 80025128 <disk+0x2128>
    80006ad2:	ffffa097          	auipc	ra,0xffffa
    80006ad6:	1e6080e7          	jalr	486(ra) # 80000cb8 <release>
}
    80006ada:	60e2                	ld	ra,24(sp)
    80006adc:	6442                	ld	s0,16(sp)
    80006ade:	64a2                	ld	s1,8(sp)
    80006ae0:	6902                	ld	s2,0(sp)
    80006ae2:	6105                	addi	sp,sp,32
    80006ae4:	8082                	ret
      panic("virtio_disk_intr status");
    80006ae6:	00002517          	auipc	a0,0x2
    80006aea:	d5250513          	addi	a0,a0,-686 # 80008838 <syscalls+0x3c0>
    80006aee:	ffffa097          	auipc	ra,0xffffa
    80006af2:	a50080e7          	jalr	-1456(ra) # 8000053e <panic>

0000000080006af6 <cas>:
    80006af6:	100522af          	lr.w	t0,(a0)
    80006afa:	00b29563          	bne	t0,a1,80006b04 <fail>
    80006afe:	18c5252f          	sc.w	a0,a2,(a0)
    80006b02:	8082                	ret

0000000080006b04 <fail>:
    80006b04:	4505                	li	a0,1
    80006b06:	8082                	ret
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
