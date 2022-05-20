
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
    80000068:	3fc78793          	addi	a5,a5,1020 # 80006460 <timervec>
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
    80000130:	b9c080e7          	jalr	-1124(ra) # 80002cc8 <either_copyin>
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
    800001d8:	536080e7          	jalr	1334(ra) # 8000270a <sleep>
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
    80000214:	a62080e7          	jalr	-1438(ra) # 80002c72 <either_copyout>
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
    800002f6:	a2c080e7          	jalr	-1492(ra) # 80002d1e <procdump>
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
    8000044a:	542080e7          	jalr	1346(ra) # 80002988 <wakeup>
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
    800008a4:	0e8080e7          	jalr	232(ra) # 80002988 <wakeup>
    
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
    80000930:	dde080e7          	jalr	-546(ra) # 8000270a <sleep>
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
    80000f0a:	ff6080e7          	jalr	-10(ra) # 80002efc <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0e:	00005097          	auipc	ra,0x5
    80000f12:	592080e7          	jalr	1426(ra) # 800064a0 <plicinithart>
  }

  scheduler();        
    80000f16:	00001097          	auipc	ra,0x1
    80000f1a:	5f8080e7          	jalr	1528(ra) # 8000250e <scheduler>
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
    80000f82:	f56080e7          	jalr	-170(ra) # 80002ed4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f86:	00002097          	auipc	ra,0x2
    80000f8a:	f76080e7          	jalr	-138(ra) # 80002efc <trapinithart>
    plicinit();      // set up interrupt controller
    80000f8e:	00005097          	auipc	ra,0x5
    80000f92:	4fc080e7          	jalr	1276(ra) # 8000648a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f96:	00005097          	auipc	ra,0x5
    80000f9a:	50a080e7          	jalr	1290(ra) # 800064a0 <plicinithart>
    binit();         // buffer cache
    80000f9e:	00002097          	auipc	ra,0x2
    80000fa2:	6ea080e7          	jalr	1770(ra) # 80003688 <binit>
    iinit();         // inode table
    80000fa6:	00003097          	auipc	ra,0x3
    80000faa:	d7a080e7          	jalr	-646(ra) # 80003d20 <iinit>
    fileinit();      // file table
    80000fae:	00004097          	auipc	ra,0x4
    80000fb2:	d24080e7          	jalr	-732(ra) # 80004cd2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb6:	00005097          	auipc	ra,0x5
    80000fba:	60c080e7          	jalr	1548(ra) # 800065c2 <virtio_disk_init>
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
    80001eb6:	99e7a783          	lw	a5,-1634(a5) # 80008850 <first.1755>
    80001eba:	eb89                	bnez	a5,80001ecc <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001ebc:	00001097          	auipc	ra,0x1
    80001ec0:	058080e7          	jalr	88(ra) # 80002f14 <usertrapret>
}
    80001ec4:	60a2                	ld	ra,8(sp)
    80001ec6:	6402                	ld	s0,0(sp)
    80001ec8:	0141                	addi	sp,sp,16
    80001eca:	8082                	ret
    first = 0;
    80001ecc:	00007797          	auipc	a5,0x7
    80001ed0:	9807a223          	sw	zero,-1660(a5) # 80008850 <first.1755>
    fsinit(ROOTDEV);
    80001ed4:	4505                	li	a0,1
    80001ed6:	00002097          	auipc	ra,0x2
    80001eda:	dca080e7          	jalr	-566(ra) # 80003ca0 <fsinit>
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
    80001f06:	ba4080e7          	jalr	-1116(ra) # 80006aa6 <cas>
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
    8000220a:	4c8080e7          	jalr	1224(ra) # 800046ce <namei>
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
    800022d4:	00004097          	auipc	ra,0x4
    800022d8:	7d2080e7          	jalr	2002(ra) # 80006aa6 <cas>
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
    80002340:	7139                	addi	sp,sp,-64
    80002342:	fc06                	sd	ra,56(sp)
    80002344:	f822                	sd	s0,48(sp)
    80002346:	f426                	sd	s1,40(sp)
    80002348:	f04a                	sd	s2,32(sp)
    8000234a:	ec4e                	sd	s3,24(sp)
    8000234c:	e852                	sd	s4,16(sp)
    8000234e:	e456                	sd	s5,8(sp)
    80002350:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002352:	00000097          	auipc	ra,0x0
    80002356:	b0a080e7          	jalr	-1270(ra) # 80001e5c <myproc>
    8000235a:	89aa                	mv	s3,a0
  if ((np = allocproc()) == 0)
    8000235c:	00000097          	auipc	ra,0x0
    80002360:	d38080e7          	jalr	-712(ra) # 80002094 <allocproc>
    80002364:	1a050363          	beqz	a0,8000250a <fork+0x1ca>
    80002368:	892a                	mv	s2,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    8000236a:	0689b603          	ld	a2,104(s3)
    8000236e:	792c                	ld	a1,112(a0)
    80002370:	0709b503          	ld	a0,112(s3)
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	22c080e7          	jalr	556(ra) # 800015a0 <uvmcopy>
    8000237c:	04054663          	bltz	a0,800023c8 <fork+0x88>
  np->sz = p->sz;
    80002380:	0689b783          	ld	a5,104(s3)
    80002384:	06f93423          	sd	a5,104(s2)
  *(np->trapframe) = *(p->trapframe);
    80002388:	0789b683          	ld	a3,120(s3)
    8000238c:	87b6                	mv	a5,a3
    8000238e:	07893703          	ld	a4,120(s2)
    80002392:	12068693          	addi	a3,a3,288
    80002396:	0007b803          	ld	a6,0(a5)
    8000239a:	6788                	ld	a0,8(a5)
    8000239c:	6b8c                	ld	a1,16(a5)
    8000239e:	6f90                	ld	a2,24(a5)
    800023a0:	01073023          	sd	a6,0(a4)
    800023a4:	e708                	sd	a0,8(a4)
    800023a6:	eb0c                	sd	a1,16(a4)
    800023a8:	ef10                	sd	a2,24(a4)
    800023aa:	02078793          	addi	a5,a5,32
    800023ae:	02070713          	addi	a4,a4,32
    800023b2:	fed792e3          	bne	a5,a3,80002396 <fork+0x56>
  np->trapframe->a0 = 0;
    800023b6:	07893783          	ld	a5,120(s2)
    800023ba:	0607b823          	sd	zero,112(a5)
    800023be:	0f000493          	li	s1,240
  for (i = 0; i < NOFILE; i++)
    800023c2:	17000a13          	li	s4,368
    800023c6:	a03d                	j	800023f4 <fork+0xb4>
    freeproc(np);
    800023c8:	854a                	mv	a0,s2
    800023ca:	00000097          	auipc	ra,0x0
    800023ce:	c3e080e7          	jalr	-962(ra) # 80002008 <freeproc>
    release(&np->lock);
    800023d2:	854a                	mv	a0,s2
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	8e4080e7          	jalr	-1820(ra) # 80000cb8 <release>
    return -1;
    800023dc:	5a7d                	li	s4,-1
    800023de:	a0f1                	j	800024aa <fork+0x16a>
      np->ofile[i] = filedup(p->ofile[i]);
    800023e0:	00003097          	auipc	ra,0x3
    800023e4:	984080e7          	jalr	-1660(ra) # 80004d64 <filedup>
    800023e8:	009907b3          	add	a5,s2,s1
    800023ec:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    800023ee:	04a1                	addi	s1,s1,8
    800023f0:	01448763          	beq	s1,s4,800023fe <fork+0xbe>
    if (p->ofile[i])
    800023f4:	009987b3          	add	a5,s3,s1
    800023f8:	6388                	ld	a0,0(a5)
    800023fa:	f17d                	bnez	a0,800023e0 <fork+0xa0>
    800023fc:	bfcd                	j	800023ee <fork+0xae>
  np->cwd = idup(p->cwd);
    800023fe:	1709b503          	ld	a0,368(s3)
    80002402:	00002097          	auipc	ra,0x2
    80002406:	ad8080e7          	jalr	-1320(ra) # 80003eda <idup>
    8000240a:	16a93823          	sd	a0,368(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000240e:	4641                	li	a2,16
    80002410:	17898593          	addi	a1,s3,376
    80002414:	17890513          	addi	a0,s2,376
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	a4c080e7          	jalr	-1460(ra) # 80000e64 <safestrcpy>
  pid = np->pid;
    80002420:	03092a03          	lw	s4,48(s2)
  release(&np->lock);
    80002424:	854a                	mv	a0,s2
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	892080e7          	jalr	-1902(ra) # 80000cb8 <release>
  acquire(&wait_lock);
    8000242e:	0000f517          	auipc	a0,0xf
    80002432:	45250513          	addi	a0,a0,1106 # 80011880 <wait_lock>
    80002436:	ffffe097          	auipc	ra,0xffffe
    8000243a:	7b6080e7          	jalr	1974(ra) # 80000bec <acquire>
  np->parent = p;
    8000243e:	05393c23          	sd	s3,88(s2)
  np->cpu = p->cpu;
    80002442:	0349a783          	lw	a5,52(s3)
    80002446:	2781                	sext.w	a5,a5
    80002448:	02f92a23          	sw	a5,52(s2)
  struct cpu *c = &cpus[np->cpu];
    8000244c:	03492983          	lw	s3,52(s2)
    80002450:	2981                	sext.w	s3,s3
    80002452:	0b000493          	li	s1,176
    80002456:	029987b3          	mul	a5,s3,s1
    8000245a:	0000f497          	auipc	s1,0xf
    8000245e:	e4648493          	addi	s1,s1,-442 # 800112a0 <cpus>
    80002462:	94be                	add	s1,s1,a5
  if (load_balancer)
    80002464:	00006797          	auipc	a5,0x6
    80002468:	3f47a783          	lw	a5,1012(a5) # 80008858 <load_balancer>
    8000246c:	eba9                	bnez	a5,800024be <fork+0x17e>
  release(&wait_lock);
    8000246e:	0000f517          	auipc	a0,0xf
    80002472:	41250513          	addi	a0,a0,1042 # 80011880 <wait_lock>
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	842080e7          	jalr	-1982(ra) # 80000cb8 <release>
  acquire(&np->lock);
    8000247e:	854a                	mv	a0,s2
    80002480:	ffffe097          	auipc	ra,0xffffe
    80002484:	76c080e7          	jalr	1900(ra) # 80000bec <acquire>
  np->state = RUNNABLE;
    80002488:	478d                	li	a5,3
    8000248a:	00f92c23          	sw	a5,24(s2)
  add_proc(&c->runnable_head, np, &c->head_lock);
    8000248e:	09048613          	addi	a2,s1,144
    80002492:	85ca                	mv	a1,s2
    80002494:	08848513          	addi	a0,s1,136
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	65a080e7          	jalr	1626(ra) # 80001af2 <add_proc>
  release(&np->lock);
    800024a0:	854a                	mv	a0,s2
    800024a2:	fffff097          	auipc	ra,0xfffff
    800024a6:	816080e7          	jalr	-2026(ra) # 80000cb8 <release>
}
    800024aa:	8552                	mv	a0,s4
    800024ac:	70e2                	ld	ra,56(sp)
    800024ae:	7442                	ld	s0,48(sp)
    800024b0:	74a2                	ld	s1,40(sp)
    800024b2:	7902                	ld	s2,32(sp)
    800024b4:	69e2                	ld	s3,24(sp)
    800024b6:	6a42                	ld	s4,16(sp)
    800024b8:	6aa2                	ld	s5,8(sp)
    800024ba:	6121                	addi	sp,sp,64
    800024bc:	8082                	ret
    int np_cpu_num = least_used_cpu();
    800024be:	fffff097          	auipc	ra,0xfffff
    800024c2:	77a080e7          	jalr	1914(ra) # 80001c38 <least_used_cpu>
    np->cpu = np_cpu_num;
    800024c6:	02a92a23          	sw	a0,52(s2)
    if(np_cpu_num != c->cpu_idx){
    800024ca:	409c                	lw	a5,0(s1)
    800024cc:	faa781e3          	beq	a5,a0,8000246e <fork+0x12e>
      c = &cpus[np->cpu];
    800024d0:	03492783          	lw	a5,52(s2)
    800024d4:	2781                	sext.w	a5,a5
    800024d6:	0b000713          	li	a4,176
    800024da:	02e78733          	mul	a4,a5,a4
    800024de:	0000f997          	auipc	s3,0xf
    800024e2:	dc298993          	addi	s3,s3,-574 # 800112a0 <cpus>
    800024e6:	00e984b3          	add	s1,s3,a4
      }while(cas(&c->proc_counter, counter, counter + 1));
    800024ea:	0a870713          	addi	a4,a4,168
    800024ee:	99ba                	add	s3,s3,a4
        counter = c->proc_counter;
    800024f0:	8aa6                	mv	s5,s1
    800024f2:	0a8ab583          	ld	a1,168(s5)
      }while(cas(&c->proc_counter, counter, counter + 1));
    800024f6:	0015861b          	addiw	a2,a1,1
    800024fa:	2581                	sext.w	a1,a1
    800024fc:	854e                	mv	a0,s3
    800024fe:	00004097          	auipc	ra,0x4
    80002502:	5a8080e7          	jalr	1448(ra) # 80006aa6 <cas>
    80002506:	f575                	bnez	a0,800024f2 <fork+0x1b2>
    80002508:	b79d                	j	8000246e <fork+0x12e>
    return -1;
    8000250a:	5a7d                	li	s4,-1
    8000250c:	bf79                	j	800024aa <fork+0x16a>

000000008000250e <scheduler>:
{
    8000250e:	711d                	addi	sp,sp,-96
    80002510:	ec86                	sd	ra,88(sp)
    80002512:	e8a2                	sd	s0,80(sp)
    80002514:	e4a6                	sd	s1,72(sp)
    80002516:	e0ca                	sd	s2,64(sp)
    80002518:	fc4e                	sd	s3,56(sp)
    8000251a:	f852                	sd	s4,48(sp)
    8000251c:	f456                	sd	s5,40(sp)
    8000251e:	f05a                	sd	s6,32(sp)
    80002520:	ec5e                	sd	s7,24(sp)
    80002522:	e862                	sd	s8,16(sp)
    80002524:	e466                	sd	s9,8(sp)
    80002526:	e06a                	sd	s10,0(sp)
    80002528:	1080                	addi	s0,sp,96
    8000252a:	8712                	mv	a4,tp
  int id = r_tp();
    8000252c:	2701                	sext.w	a4,a4
  c->proc = 0;
    8000252e:	0000fb97          	auipc	s7,0xf
    80002532:	d72b8b93          	addi	s7,s7,-654 # 800112a0 <cpus>
    80002536:	0b000793          	li	a5,176
    8000253a:	02f707b3          	mul	a5,a4,a5
    8000253e:	00fb86b3          	add	a3,s7,a5
    80002542:	0006b423          	sd	zero,8(a3)
    int next_running = remove_first(&c->runnable_head, &c->head_lock);
    80002546:	08878993          	addi	s3,a5,136
    8000254a:	99de                	add	s3,s3,s7
    8000254c:	09078913          	addi	s2,a5,144
    80002550:	995e                	add	s2,s2,s7
      swtch(&c->context, &p->context);
    80002552:	07c1                	addi	a5,a5,16
    80002554:	9bbe                	add	s7,s7,a5
    if (next_running != -1)
    80002556:	5a7d                	li	s4,-1
    80002558:	18800c93          	li	s9,392
      p = &proc[next_running];
    8000255c:	0000fb17          	auipc	s6,0xf
    80002560:	33cb0b13          	addi	s6,s6,828 # 80011898 <proc>
      p->state = RUNNING;
    80002564:	4c11                	li	s8,4
      c->proc = p;
    80002566:	8ab6                	mv	s5,a3
    80002568:	a82d                	j	800025a2 <scheduler+0x94>
      p = &proc[next_running];
    8000256a:	039504b3          	mul	s1,a0,s9
    8000256e:	01648d33          	add	s10,s1,s6
      acquire(&p->lock);
    80002572:	856a                	mv	a0,s10
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	678080e7          	jalr	1656(ra) # 80000bec <acquire>
      p->state = RUNNING;
    8000257c:	018d2c23          	sw	s8,24(s10)
      c->proc = p;
    80002580:	01aab423          	sd	s10,8(s5)
      swtch(&c->context, &p->context);
    80002584:	08048593          	addi	a1,s1,128
    80002588:	95da                	add	a1,a1,s6
    8000258a:	855e                	mv	a0,s7
    8000258c:	00001097          	auipc	ra,0x1
    80002590:	8de080e7          	jalr	-1826(ra) # 80002e6a <swtch>
      c->proc = 0;
    80002594:	000ab423          	sd	zero,8(s5)
      release(&p->lock);
    80002598:	856a                	mv	a0,s10
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	71e080e7          	jalr	1822(ra) # 80000cb8 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025a2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800025a6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025aa:	10079073          	csrw	sstatus,a5
    int next_running = remove_first(&c->runnable_head, &c->head_lock);
    800025ae:	85ca                	mv	a1,s2
    800025b0:	854e                	mv	a0,s3
    800025b2:	fffff097          	auipc	ra,0xfffff
    800025b6:	2be080e7          	jalr	702(ra) # 80001870 <remove_first>
    if (next_running != -1)
    800025ba:	ff4504e3          	beq	a0,s4,800025a2 <scheduler+0x94>
    800025be:	b775                	j	8000256a <scheduler+0x5c>

00000000800025c0 <sched>:
{
    800025c0:	7179                	addi	sp,sp,-48
    800025c2:	f406                	sd	ra,40(sp)
    800025c4:	f022                	sd	s0,32(sp)
    800025c6:	ec26                	sd	s1,24(sp)
    800025c8:	e84a                	sd	s2,16(sp)
    800025ca:	e44e                	sd	s3,8(sp)
    800025cc:	e052                	sd	s4,0(sp)
    800025ce:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800025d0:	00000097          	auipc	ra,0x0
    800025d4:	88c080e7          	jalr	-1908(ra) # 80001e5c <myproc>
    800025d8:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800025da:	ffffe097          	auipc	ra,0xffffe
    800025de:	590080e7          	jalr	1424(ra) # 80000b6a <holding>
    800025e2:	c149                	beqz	a0,80002664 <sched+0xa4>
  asm volatile("mv %0, tp" : "=r" (x) );
    800025e4:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800025e6:	2781                	sext.w	a5,a5
    800025e8:	0b000713          	li	a4,176
    800025ec:	02e787b3          	mul	a5,a5,a4
    800025f0:	0000f717          	auipc	a4,0xf
    800025f4:	cb070713          	addi	a4,a4,-848 # 800112a0 <cpus>
    800025f8:	97ba                	add	a5,a5,a4
    800025fa:	0807a703          	lw	a4,128(a5)
    800025fe:	4785                	li	a5,1
    80002600:	06f71a63          	bne	a4,a5,80002674 <sched+0xb4>
  if (p->state == RUNNING)
    80002604:	4c98                	lw	a4,24(s1)
    80002606:	4791                	li	a5,4
    80002608:	06f70e63          	beq	a4,a5,80002684 <sched+0xc4>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000260c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002610:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002612:	e3c9                	bnez	a5,80002694 <sched+0xd4>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002614:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002616:	0000f917          	auipc	s2,0xf
    8000261a:	c8a90913          	addi	s2,s2,-886 # 800112a0 <cpus>
    8000261e:	2781                	sext.w	a5,a5
    80002620:	0b000993          	li	s3,176
    80002624:	033787b3          	mul	a5,a5,s3
    80002628:	97ca                	add	a5,a5,s2
    8000262a:	0847aa03          	lw	s4,132(a5)
    8000262e:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    80002630:	2581                	sext.w	a1,a1
    80002632:	033585b3          	mul	a1,a1,s3
    80002636:	05c1                	addi	a1,a1,16
    80002638:	95ca                	add	a1,a1,s2
    8000263a:	08048513          	addi	a0,s1,128
    8000263e:	00001097          	auipc	ra,0x1
    80002642:	82c080e7          	jalr	-2004(ra) # 80002e6a <swtch>
    80002646:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002648:	2781                	sext.w	a5,a5
    8000264a:	033787b3          	mul	a5,a5,s3
    8000264e:	993e                	add	s2,s2,a5
    80002650:	09492223          	sw	s4,132(s2)
}
    80002654:	70a2                	ld	ra,40(sp)
    80002656:	7402                	ld	s0,32(sp)
    80002658:	64e2                	ld	s1,24(sp)
    8000265a:	6942                	ld	s2,16(sp)
    8000265c:	69a2                	ld	s3,8(sp)
    8000265e:	6a02                	ld	s4,0(sp)
    80002660:	6145                	addi	sp,sp,48
    80002662:	8082                	ret
    panic("sched p->lock");
    80002664:	00006517          	auipc	a0,0x6
    80002668:	bf450513          	addi	a0,a0,-1036 # 80008258 <digits+0x218>
    8000266c:	ffffe097          	auipc	ra,0xffffe
    80002670:	ed2080e7          	jalr	-302(ra) # 8000053e <panic>
    panic("sched locks");
    80002674:	00006517          	auipc	a0,0x6
    80002678:	bf450513          	addi	a0,a0,-1036 # 80008268 <digits+0x228>
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	ec2080e7          	jalr	-318(ra) # 8000053e <panic>
    panic("sched running");
    80002684:	00006517          	auipc	a0,0x6
    80002688:	bf450513          	addi	a0,a0,-1036 # 80008278 <digits+0x238>
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	eb2080e7          	jalr	-334(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002694:	00006517          	auipc	a0,0x6
    80002698:	bf450513          	addi	a0,a0,-1036 # 80008288 <digits+0x248>
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	ea2080e7          	jalr	-350(ra) # 8000053e <panic>

00000000800026a4 <yield>:
{
    800026a4:	1101                	addi	sp,sp,-32
    800026a6:	ec06                	sd	ra,24(sp)
    800026a8:	e822                	sd	s0,16(sp)
    800026aa:	e426                	sd	s1,8(sp)
    800026ac:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800026ae:	fffff097          	auipc	ra,0xfffff
    800026b2:	7ae080e7          	jalr	1966(ra) # 80001e5c <myproc>
    800026b6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	534080e7          	jalr	1332(ra) # 80000bec <acquire>
  p->state = RUNNABLE;
    800026c0:	478d                	li	a5,3
    800026c2:	cc9c                	sw	a5,24(s1)
  struct cpu *c = &cpus[p->cpu];
    800026c4:	58dc                	lw	a5,52(s1)
    800026c6:	2781                	sext.w	a5,a5
  add_proc(&c->runnable_head, p, &c->head_lock);
    800026c8:	0b000513          	li	a0,176
    800026cc:	02a787b3          	mul	a5,a5,a0
    800026d0:	0000f517          	auipc	a0,0xf
    800026d4:	bd050513          	addi	a0,a0,-1072 # 800112a0 <cpus>
    800026d8:	09078613          	addi	a2,a5,144
    800026dc:	08878793          	addi	a5,a5,136
    800026e0:	962a                	add	a2,a2,a0
    800026e2:	85a6                	mv	a1,s1
    800026e4:	953e                	add	a0,a0,a5
    800026e6:	fffff097          	auipc	ra,0xfffff
    800026ea:	40c080e7          	jalr	1036(ra) # 80001af2 <add_proc>
  sched();
    800026ee:	00000097          	auipc	ra,0x0
    800026f2:	ed2080e7          	jalr	-302(ra) # 800025c0 <sched>
  release(&p->lock);
    800026f6:	8526                	mv	a0,s1
    800026f8:	ffffe097          	auipc	ra,0xffffe
    800026fc:	5c0080e7          	jalr	1472(ra) # 80000cb8 <release>
}
    80002700:	60e2                	ld	ra,24(sp)
    80002702:	6442                	ld	s0,16(sp)
    80002704:	64a2                	ld	s1,8(sp)
    80002706:	6105                	addi	sp,sp,32
    80002708:	8082                	ret

000000008000270a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000270a:	7179                	addi	sp,sp,-48
    8000270c:	f406                	sd	ra,40(sp)
    8000270e:	f022                	sd	s0,32(sp)
    80002710:	ec26                	sd	s1,24(sp)
    80002712:	e84a                	sd	s2,16(sp)
    80002714:	e44e                	sd	s3,8(sp)
    80002716:	1800                	addi	s0,sp,48
    80002718:	89aa                	mv	s3,a0
    8000271a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000271c:	fffff097          	auipc	ra,0xfffff
    80002720:	740080e7          	jalr	1856(ra) # 80001e5c <myproc>
    80002724:	84aa                	mv	s1,a0
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.
  acquire(&p->lock); // DOC: sleeplock1
    80002726:	ffffe097          	auipc	ra,0xffffe
    8000272a:	4c6080e7          	jalr	1222(ra) # 80000bec <acquire>

  add_proc(&sleeping_head, p, &sleeping_lock);
    8000272e:	0000f617          	auipc	a2,0xf
    80002732:	12260613          	addi	a2,a2,290 # 80011850 <sleeping_lock>
    80002736:	85a6                	mv	a1,s1
    80002738:	00006517          	auipc	a0,0x6
    8000273c:	12850513          	addi	a0,a0,296 # 80008860 <sleeping_head>
    80002740:	fffff097          	auipc	ra,0xfffff
    80002744:	3b2080e7          	jalr	946(ra) # 80001af2 <add_proc>
  release(lk);
    80002748:	854a                	mv	a0,s2
    8000274a:	ffffe097          	auipc	ra,0xffffe
    8000274e:	56e080e7          	jalr	1390(ra) # 80000cb8 <release>
  p->chan = chan;
    80002752:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002756:	4789                	li	a5,2
    80002758:	cc9c                	sw	a5,24(s1)

  // Go to sleep.
  // in your dream

  sched();
    8000275a:	00000097          	auipc	ra,0x0
    8000275e:	e66080e7          	jalr	-410(ra) # 800025c0 <sched>

  // Tidy up.
  p->chan = 0;
    80002762:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002766:	8526                	mv	a0,s1
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	550080e7          	jalr	1360(ra) # 80000cb8 <release>
  acquire(lk);
    80002770:	854a                	mv	a0,s2
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	47a080e7          	jalr	1146(ra) # 80000bec <acquire>
}
    8000277a:	70a2                	ld	ra,40(sp)
    8000277c:	7402                	ld	s0,32(sp)
    8000277e:	64e2                	ld	s1,24(sp)
    80002780:	6942                	ld	s2,16(sp)
    80002782:	69a2                	ld	s3,8(sp)
    80002784:	6145                	addi	sp,sp,48
    80002786:	8082                	ret

0000000080002788 <wait>:
{
    80002788:	715d                	addi	sp,sp,-80
    8000278a:	e486                	sd	ra,72(sp)
    8000278c:	e0a2                	sd	s0,64(sp)
    8000278e:	fc26                	sd	s1,56(sp)
    80002790:	f84a                	sd	s2,48(sp)
    80002792:	f44e                	sd	s3,40(sp)
    80002794:	f052                	sd	s4,32(sp)
    80002796:	ec56                	sd	s5,24(sp)
    80002798:	e85a                	sd	s6,16(sp)
    8000279a:	e45e                	sd	s7,8(sp)
    8000279c:	e062                	sd	s8,0(sp)
    8000279e:	0880                	addi	s0,sp,80
    800027a0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800027a2:	fffff097          	auipc	ra,0xfffff
    800027a6:	6ba080e7          	jalr	1722(ra) # 80001e5c <myproc>
    800027aa:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800027ac:	0000f517          	auipc	a0,0xf
    800027b0:	0d450513          	addi	a0,a0,212 # 80011880 <wait_lock>
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	438080e7          	jalr	1080(ra) # 80000bec <acquire>
    havekids = 0;
    800027bc:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    800027be:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    800027c0:	00015997          	auipc	s3,0x15
    800027c4:	2d898993          	addi	s3,s3,728 # 80017a98 <tickslock>
        havekids = 1;
    800027c8:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    800027ca:	0000fc17          	auipc	s8,0xf
    800027ce:	0b6c0c13          	addi	s8,s8,182 # 80011880 <wait_lock>
    havekids = 0;
    800027d2:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    800027d4:	0000f497          	auipc	s1,0xf
    800027d8:	0c448493          	addi	s1,s1,196 # 80011898 <proc>
    800027dc:	a0bd                	j	8000284a <wait+0xc2>
          pid = np->pid;
    800027de:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800027e2:	000b0e63          	beqz	s6,800027fe <wait+0x76>
    800027e6:	4691                	li	a3,4
    800027e8:	02c48613          	addi	a2,s1,44
    800027ec:	85da                	mv	a1,s6
    800027ee:	07093503          	ld	a0,112(s2)
    800027f2:	fffff097          	auipc	ra,0xfffff
    800027f6:	eb2080e7          	jalr	-334(ra) # 800016a4 <copyout>
    800027fa:	02054563          	bltz	a0,80002824 <wait+0x9c>
          freeproc(np);
    800027fe:	8526                	mv	a0,s1
    80002800:	00000097          	auipc	ra,0x0
    80002804:	808080e7          	jalr	-2040(ra) # 80002008 <freeproc>
          release(&np->lock);
    80002808:	8526                	mv	a0,s1
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	4ae080e7          	jalr	1198(ra) # 80000cb8 <release>
          release(&wait_lock);
    80002812:	0000f517          	auipc	a0,0xf
    80002816:	06e50513          	addi	a0,a0,110 # 80011880 <wait_lock>
    8000281a:	ffffe097          	auipc	ra,0xffffe
    8000281e:	49e080e7          	jalr	1182(ra) # 80000cb8 <release>
          return pid;
    80002822:	a09d                	j	80002888 <wait+0x100>
            release(&np->lock);
    80002824:	8526                	mv	a0,s1
    80002826:	ffffe097          	auipc	ra,0xffffe
    8000282a:	492080e7          	jalr	1170(ra) # 80000cb8 <release>
            release(&wait_lock);
    8000282e:	0000f517          	auipc	a0,0xf
    80002832:	05250513          	addi	a0,a0,82 # 80011880 <wait_lock>
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	482080e7          	jalr	1154(ra) # 80000cb8 <release>
            return -1;
    8000283e:	59fd                	li	s3,-1
    80002840:	a0a1                	j	80002888 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    80002842:	18848493          	addi	s1,s1,392
    80002846:	03348463          	beq	s1,s3,8000286e <wait+0xe6>
      if (np->parent == p)
    8000284a:	6cbc                	ld	a5,88(s1)
    8000284c:	ff279be3          	bne	a5,s2,80002842 <wait+0xba>
        acquire(&np->lock);
    80002850:	8526                	mv	a0,s1
    80002852:	ffffe097          	auipc	ra,0xffffe
    80002856:	39a080e7          	jalr	922(ra) # 80000bec <acquire>
        if (np->state == ZOMBIE)
    8000285a:	4c9c                	lw	a5,24(s1)
    8000285c:	f94781e3          	beq	a5,s4,800027de <wait+0x56>
        release(&np->lock);
    80002860:	8526                	mv	a0,s1
    80002862:	ffffe097          	auipc	ra,0xffffe
    80002866:	456080e7          	jalr	1110(ra) # 80000cb8 <release>
        havekids = 1;
    8000286a:	8756                	mv	a4,s5
    8000286c:	bfd9                	j	80002842 <wait+0xba>
    if (!havekids || p->killed)
    8000286e:	c701                	beqz	a4,80002876 <wait+0xee>
    80002870:	02892783          	lw	a5,40(s2)
    80002874:	c79d                	beqz	a5,800028a2 <wait+0x11a>
      release(&wait_lock);
    80002876:	0000f517          	auipc	a0,0xf
    8000287a:	00a50513          	addi	a0,a0,10 # 80011880 <wait_lock>
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	43a080e7          	jalr	1082(ra) # 80000cb8 <release>
      return -1;
    80002886:	59fd                	li	s3,-1
}
    80002888:	854e                	mv	a0,s3
    8000288a:	60a6                	ld	ra,72(sp)
    8000288c:	6406                	ld	s0,64(sp)
    8000288e:	74e2                	ld	s1,56(sp)
    80002890:	7942                	ld	s2,48(sp)
    80002892:	79a2                	ld	s3,40(sp)
    80002894:	7a02                	ld	s4,32(sp)
    80002896:	6ae2                	ld	s5,24(sp)
    80002898:	6b42                	ld	s6,16(sp)
    8000289a:	6ba2                	ld	s7,8(sp)
    8000289c:	6c02                	ld	s8,0(sp)
    8000289e:	6161                	addi	sp,sp,80
    800028a0:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800028a2:	85e2                	mv	a1,s8
    800028a4:	854a                	mv	a0,s2
    800028a6:	00000097          	auipc	ra,0x0
    800028aa:	e64080e7          	jalr	-412(ra) # 8000270a <sleep>
    havekids = 0;
    800028ae:	b715                	j	800027d2 <wait+0x4a>

00000000800028b0 <wakeup_help>:

void wakeup_help(struct proc *p, void *chan)
{
  if (p->state == SLEEPING && p->chan == chan)
    800028b0:	4d18                	lw	a4,24(a0)
    800028b2:	4789                	li	a5,2
    800028b4:	00f70363          	beq	a4,a5,800028ba <wakeup_help+0xa>
    800028b8:	8082                	ret
{
    800028ba:	7179                	addi	sp,sp,-48
    800028bc:	f406                	sd	ra,40(sp)
    800028be:	f022                	sd	s0,32(sp)
    800028c0:	ec26                	sd	s1,24(sp)
    800028c2:	e84a                	sd	s2,16(sp)
    800028c4:	e44e                	sd	s3,8(sp)
    800028c6:	1800                	addi	s0,sp,48
    800028c8:	84aa                	mv	s1,a0
  if (p->state == SLEEPING && p->chan == chan)
    800028ca:	711c                	ld	a5,32(a0)
    800028cc:	00b78963          	beq	a5,a1,800028de <wakeup_help+0x2e>
    }
    int cpu_num = p->cpu;
    remove_proc(&sleeping_head, p, &sleeping_lock);
    add_proc(&cpus[cpu_num].runnable_head, p, &cpus[cpu_num].head_lock);
  }
}
    800028d0:	70a2                	ld	ra,40(sp)
    800028d2:	7402                	ld	s0,32(sp)
    800028d4:	64e2                	ld	s1,24(sp)
    800028d6:	6942                	ld	s2,16(sp)
    800028d8:	69a2                	ld	s3,8(sp)
    800028da:	6145                	addi	sp,sp,48
    800028dc:	8082                	ret
    p->state = RUNNABLE;
    800028de:	478d                	li	a5,3
    800028e0:	cd1c                	sw	a5,24(a0)
    if (load_balancer)
    800028e2:	00006797          	auipc	a5,0x6
    800028e6:	f767a783          	lw	a5,-138(a5) # 80008858 <load_balancer>
    800028ea:	e7a9                	bnez	a5,80002934 <wakeup_help+0x84>
    int cpu_num = p->cpu;
    800028ec:	58c8                	lw	a0,52(s1)
    800028ee:	0005091b          	sext.w	s2,a0
    remove_proc(&sleeping_head, p, &sleeping_lock);
    800028f2:	0000f997          	auipc	s3,0xf
    800028f6:	9ae98993          	addi	s3,s3,-1618 # 800112a0 <cpus>
    800028fa:	0000f617          	auipc	a2,0xf
    800028fe:	f5660613          	addi	a2,a2,-170 # 80011850 <sleeping_lock>
    80002902:	85a6                	mv	a1,s1
    80002904:	00006517          	auipc	a0,0x6
    80002908:	f5c50513          	addi	a0,a0,-164 # 80008860 <sleeping_head>
    8000290c:	fffff097          	auipc	ra,0xfffff
    80002910:	0a2080e7          	jalr	162(ra) # 800019ae <remove_proc>
    add_proc(&cpus[cpu_num].runnable_head, p, &cpus[cpu_num].head_lock);
    80002914:	0b000513          	li	a0,176
    80002918:	02a90533          	mul	a0,s2,a0
    8000291c:	09050613          	addi	a2,a0,144
    80002920:	08850513          	addi	a0,a0,136
    80002924:	964e                	add	a2,a2,s3
    80002926:	85a6                	mv	a1,s1
    80002928:	954e                	add	a0,a0,s3
    8000292a:	fffff097          	auipc	ra,0xfffff
    8000292e:	1c8080e7          	jalr	456(ra) # 80001af2 <add_proc>
}
    80002932:	bf79                	j	800028d0 <wakeup_help+0x20>
      int least_cpu_num = least_used_cpu();
    80002934:	fffff097          	auipc	ra,0xfffff
    80002938:	304080e7          	jalr	772(ra) # 80001c38 <least_used_cpu>
      if(p->cpu != least_cpu_num){
    8000293c:	58dc                	lw	a5,52(s1)
    8000293e:	2781                	sext.w	a5,a5
    80002940:	faa786e3          	beq	a5,a0,800028ec <wakeup_help+0x3c>
        p->cpu = least_cpu_num;
    80002944:	d8c8                	sw	a0,52(s1)
        struct cpu *c = &cpus[p->cpu];
    80002946:	0344a983          	lw	s3,52(s1)
    8000294a:	2981                	sext.w	s3,s3
        } while (cas(&c->proc_counter, count, count + 1) != 0);
    8000294c:	0b000913          	li	s2,176
    80002950:	03298933          	mul	s2,s3,s2
    80002954:	0000f797          	auipc	a5,0xf
    80002958:	9f478793          	addi	a5,a5,-1548 # 80011348 <cpus+0xa8>
    8000295c:	993e                	add	s2,s2,a5
          count = c->proc_counter;
    8000295e:	0b000793          	li	a5,176
    80002962:	02f987b3          	mul	a5,s3,a5
    80002966:	0000f997          	auipc	s3,0xf
    8000296a:	93a98993          	addi	s3,s3,-1734 # 800112a0 <cpus>
    8000296e:	99be                	add	s3,s3,a5
    80002970:	0a89b583          	ld	a1,168(s3)
        } while (cas(&c->proc_counter, count, count + 1) != 0);
    80002974:	0015861b          	addiw	a2,a1,1
    80002978:	2581                	sext.w	a1,a1
    8000297a:	854a                	mv	a0,s2
    8000297c:	00004097          	auipc	ra,0x4
    80002980:	12a080e7          	jalr	298(ra) # 80006aa6 <cas>
    80002984:	f575                	bnez	a0,80002970 <wakeup_help+0xc0>
    80002986:	b79d                	j	800028ec <wakeup_help+0x3c>

0000000080002988 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002988:	715d                	addi	sp,sp,-80
    8000298a:	e486                	sd	ra,72(sp)
    8000298c:	e0a2                	sd	s0,64(sp)
    8000298e:	fc26                	sd	s1,56(sp)
    80002990:	f84a                	sd	s2,48(sp)
    80002992:	f44e                	sd	s3,40(sp)
    80002994:	f052                	sd	s4,32(sp)
    80002996:	ec56                	sd	s5,24(sp)
    80002998:	e85a                	sd	s6,16(sp)
    8000299a:	e45e                	sd	s7,8(sp)
    8000299c:	0880                	addi	s0,sp,80
    8000299e:	8a2a                	mv	s4,a0
  struct proc *p;
  acquire(&sleeping_lock);
    800029a0:	0000f517          	auipc	a0,0xf
    800029a4:	eb050513          	addi	a0,a0,-336 # 80011850 <sleeping_lock>
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	244080e7          	jalr	580(ra) # 80000bec <acquire>
  if (sleeping_head != -1)
    800029b0:	00006497          	auipc	s1,0x6
    800029b4:	eb04a483          	lw	s1,-336(s1) # 80008860 <sleeping_head>
    800029b8:	57fd                	li	a5,-1
    800029ba:	0af48263          	beq	s1,a5,80002a5e <wakeup+0xd6>
  {
    int next_proc;
    p = &proc[sleeping_head];
    800029be:	18800793          	li	a5,392
    800029c2:	02f484b3          	mul	s1,s1,a5
    800029c6:	0000f797          	auipc	a5,0xf
    800029ca:	ed278793          	addi	a5,a5,-302 # 80011898 <proc>
    800029ce:	94be                	add	s1,s1,a5
    acquire(&p->lock);
    800029d0:	8526                	mv	a0,s1
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	21a080e7          	jalr	538(ra) # 80000bec <acquire>
    release(&sleeping_lock);
    800029da:	0000f517          	auipc	a0,0xf
    800029de:	e7650513          	addi	a0,a0,-394 # 80011850 <sleeping_lock>
    800029e2:	ffffe097          	auipc	ra,0xffffe
    800029e6:	2d6080e7          	jalr	726(ra) # 80000cb8 <release>
    next_proc = p->next;
    800029ea:	0504a903          	lw	s2,80(s1)
    wakeup_help(p, chan);
    800029ee:	85d2                	mv	a1,s4
    800029f0:	8526                	mv	a0,s1
    800029f2:	00000097          	auipc	ra,0x0
    800029f6:	ebe080e7          	jalr	-322(ra) # 800028b0 <wakeup_help>
    while (next_proc != -1)
    800029fa:	57fd                	li	a5,-1
    800029fc:	04f90163          	beq	s2,a5,80002a3e <wakeup+0xb6>
    {
      struct proc *temp = &proc[next_proc];
    80002a00:	18800b93          	li	s7,392
    80002a04:	0000fb17          	auipc	s6,0xf
    80002a08:	e94b0b13          	addi	s6,s6,-364 # 80011898 <proc>
    while (next_proc != -1)
    80002a0c:	5afd                	li	s5,-1
      struct proc *temp = &proc[next_proc];
    80002a0e:	89a6                	mv	s3,s1
    80002a10:	037904b3          	mul	s1,s2,s7
    80002a14:	94da                	add	s1,s1,s6
      acquire(&temp->lock);
    80002a16:	8526                	mv	a0,s1
    80002a18:	ffffe097          	auipc	ra,0xffffe
    80002a1c:	1d4080e7          	jalr	468(ra) # 80000bec <acquire>
      release(&p->lock);
    80002a20:	854e                	mv	a0,s3
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	296080e7          	jalr	662(ra) # 80000cb8 <release>
      p = temp;
      next_proc = p->next;
    80002a2a:	0504a903          	lw	s2,80(s1)
      wakeup_help(p, chan);
    80002a2e:	85d2                	mv	a1,s4
    80002a30:	8526                	mv	a0,s1
    80002a32:	00000097          	auipc	ra,0x0
    80002a36:	e7e080e7          	jalr	-386(ra) # 800028b0 <wakeup_help>
    while (next_proc != -1)
    80002a3a:	fd591ae3          	bne	s2,s5,80002a0e <wakeup+0x86>
    }
    release(&p->lock);
    80002a3e:	8526                	mv	a0,s1
    80002a40:	ffffe097          	auipc	ra,0xffffe
    80002a44:	278080e7          	jalr	632(ra) # 80000cb8 <release>
  }
  else{
    release(&sleeping_lock);
  }
}
    80002a48:	60a6                	ld	ra,72(sp)
    80002a4a:	6406                	ld	s0,64(sp)
    80002a4c:	74e2                	ld	s1,56(sp)
    80002a4e:	7942                	ld	s2,48(sp)
    80002a50:	79a2                	ld	s3,40(sp)
    80002a52:	7a02                	ld	s4,32(sp)
    80002a54:	6ae2                	ld	s5,24(sp)
    80002a56:	6b42                	ld	s6,16(sp)
    80002a58:	6ba2                	ld	s7,8(sp)
    80002a5a:	6161                	addi	sp,sp,80
    80002a5c:	8082                	ret
    release(&sleeping_lock);
    80002a5e:	0000f517          	auipc	a0,0xf
    80002a62:	df250513          	addi	a0,a0,-526 # 80011850 <sleeping_lock>
    80002a66:	ffffe097          	auipc	ra,0xffffe
    80002a6a:	252080e7          	jalr	594(ra) # 80000cb8 <release>
}
    80002a6e:	bfe9                	j	80002a48 <wakeup+0xc0>

0000000080002a70 <reparent>:
{
    80002a70:	7179                	addi	sp,sp,-48
    80002a72:	f406                	sd	ra,40(sp)
    80002a74:	f022                	sd	s0,32(sp)
    80002a76:	ec26                	sd	s1,24(sp)
    80002a78:	e84a                	sd	s2,16(sp)
    80002a7a:	e44e                	sd	s3,8(sp)
    80002a7c:	e052                	sd	s4,0(sp)
    80002a7e:	1800                	addi	s0,sp,48
    80002a80:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002a82:	0000f497          	auipc	s1,0xf
    80002a86:	e1648493          	addi	s1,s1,-490 # 80011898 <proc>
      pp->parent = initproc;
    80002a8a:	00006a17          	auipc	s4,0x6
    80002a8e:	59ea0a13          	addi	s4,s4,1438 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002a92:	00015997          	auipc	s3,0x15
    80002a96:	00698993          	addi	s3,s3,6 # 80017a98 <tickslock>
    80002a9a:	a029                	j	80002aa4 <reparent+0x34>
    80002a9c:	18848493          	addi	s1,s1,392
    80002aa0:	01348d63          	beq	s1,s3,80002aba <reparent+0x4a>
    if (pp->parent == p)
    80002aa4:	6cbc                	ld	a5,88(s1)
    80002aa6:	ff279be3          	bne	a5,s2,80002a9c <reparent+0x2c>
      pp->parent = initproc;
    80002aaa:	000a3503          	ld	a0,0(s4)
    80002aae:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    80002ab0:	00000097          	auipc	ra,0x0
    80002ab4:	ed8080e7          	jalr	-296(ra) # 80002988 <wakeup>
    80002ab8:	b7d5                	j	80002a9c <reparent+0x2c>
}
    80002aba:	70a2                	ld	ra,40(sp)
    80002abc:	7402                	ld	s0,32(sp)
    80002abe:	64e2                	ld	s1,24(sp)
    80002ac0:	6942                	ld	s2,16(sp)
    80002ac2:	69a2                	ld	s3,8(sp)
    80002ac4:	6a02                	ld	s4,0(sp)
    80002ac6:	6145                	addi	sp,sp,48
    80002ac8:	8082                	ret

0000000080002aca <exit>:
{
    80002aca:	7179                	addi	sp,sp,-48
    80002acc:	f406                	sd	ra,40(sp)
    80002ace:	f022                	sd	s0,32(sp)
    80002ad0:	ec26                	sd	s1,24(sp)
    80002ad2:	e84a                	sd	s2,16(sp)
    80002ad4:	e44e                	sd	s3,8(sp)
    80002ad6:	e052                	sd	s4,0(sp)
    80002ad8:	1800                	addi	s0,sp,48
    80002ada:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002adc:	fffff097          	auipc	ra,0xfffff
    80002ae0:	380080e7          	jalr	896(ra) # 80001e5c <myproc>
    80002ae4:	89aa                	mv	s3,a0
  if (p == initproc)
    80002ae6:	00006797          	auipc	a5,0x6
    80002aea:	5427b783          	ld	a5,1346(a5) # 80009028 <initproc>
    80002aee:	0f050493          	addi	s1,a0,240
    80002af2:	17050913          	addi	s2,a0,368
    80002af6:	02a79363          	bne	a5,a0,80002b1c <exit+0x52>
    panic("init exiting");
    80002afa:	00005517          	auipc	a0,0x5
    80002afe:	7a650513          	addi	a0,a0,1958 # 800082a0 <digits+0x260>
    80002b02:	ffffe097          	auipc	ra,0xffffe
    80002b06:	a3c080e7          	jalr	-1476(ra) # 8000053e <panic>
      fileclose(f);
    80002b0a:	00002097          	auipc	ra,0x2
    80002b0e:	2ac080e7          	jalr	684(ra) # 80004db6 <fileclose>
      p->ofile[fd] = 0;
    80002b12:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002b16:	04a1                	addi	s1,s1,8
    80002b18:	01248563          	beq	s1,s2,80002b22 <exit+0x58>
    if (p->ofile[fd])
    80002b1c:	6088                	ld	a0,0(s1)
    80002b1e:	f575                	bnez	a0,80002b0a <exit+0x40>
    80002b20:	bfdd                	j	80002b16 <exit+0x4c>
  begin_op();
    80002b22:	00002097          	auipc	ra,0x2
    80002b26:	dc8080e7          	jalr	-568(ra) # 800048ea <begin_op>
  iput(p->cwd);
    80002b2a:	1709b503          	ld	a0,368(s3)
    80002b2e:	00001097          	auipc	ra,0x1
    80002b32:	5a4080e7          	jalr	1444(ra) # 800040d2 <iput>
  end_op();
    80002b36:	00002097          	auipc	ra,0x2
    80002b3a:	e34080e7          	jalr	-460(ra) # 8000496a <end_op>
  p->cwd = 0;
    80002b3e:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    80002b42:	0000f497          	auipc	s1,0xf
    80002b46:	d3e48493          	addi	s1,s1,-706 # 80011880 <wait_lock>
    80002b4a:	8526                	mv	a0,s1
    80002b4c:	ffffe097          	auipc	ra,0xffffe
    80002b50:	0a0080e7          	jalr	160(ra) # 80000bec <acquire>
  reparent(p);
    80002b54:	854e                	mv	a0,s3
    80002b56:	00000097          	auipc	ra,0x0
    80002b5a:	f1a080e7          	jalr	-230(ra) # 80002a70 <reparent>
  wakeup(p->parent);
    80002b5e:	0589b503          	ld	a0,88(s3)
    80002b62:	00000097          	auipc	ra,0x0
    80002b66:	e26080e7          	jalr	-474(ra) # 80002988 <wakeup>
  acquire(&p->lock);
    80002b6a:	854e                	mv	a0,s3
    80002b6c:	ffffe097          	auipc	ra,0xffffe
    80002b70:	080080e7          	jalr	128(ra) # 80000bec <acquire>
  p->xstate = status;
    80002b74:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002b78:	4795                	li	a5,5
    80002b7a:	00f9ac23          	sw	a5,24(s3)
  add_proc(&zombie_head, p, &zombie_lock);
    80002b7e:	0000f617          	auipc	a2,0xf
    80002b82:	ca260613          	addi	a2,a2,-862 # 80011820 <zombie_lock>
    80002b86:	85ce                	mv	a1,s3
    80002b88:	00006517          	auipc	a0,0x6
    80002b8c:	cdc50513          	addi	a0,a0,-804 # 80008864 <zombie_head>
    80002b90:	fffff097          	auipc	ra,0xfffff
    80002b94:	f62080e7          	jalr	-158(ra) # 80001af2 <add_proc>
  release(&wait_lock);
    80002b98:	8526                	mv	a0,s1
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	11e080e7          	jalr	286(ra) # 80000cb8 <release>
  sched();
    80002ba2:	00000097          	auipc	ra,0x0
    80002ba6:	a1e080e7          	jalr	-1506(ra) # 800025c0 <sched>
  panic("zombie exit");
    80002baa:	00005517          	auipc	a0,0x5
    80002bae:	70650513          	addi	a0,a0,1798 # 800082b0 <digits+0x270>
    80002bb2:	ffffe097          	auipc	ra,0xffffe
    80002bb6:	98c080e7          	jalr	-1652(ra) # 8000053e <panic>

0000000080002bba <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002bba:	7179                	addi	sp,sp,-48
    80002bbc:	f406                	sd	ra,40(sp)
    80002bbe:	f022                	sd	s0,32(sp)
    80002bc0:	ec26                	sd	s1,24(sp)
    80002bc2:	e84a                	sd	s2,16(sp)
    80002bc4:	e44e                	sd	s3,8(sp)
    80002bc6:	1800                	addi	s0,sp,48
    80002bc8:	892a                	mv	s2,a0
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002bca:	0000f497          	auipc	s1,0xf
    80002bce:	cce48493          	addi	s1,s1,-818 # 80011898 <proc>
    80002bd2:	00015997          	auipc	s3,0x15
    80002bd6:	ec698993          	addi	s3,s3,-314 # 80017a98 <tickslock>
  {
    acquire(&p->lock);
    80002bda:	8526                	mv	a0,s1
    80002bdc:	ffffe097          	auipc	ra,0xffffe
    80002be0:	010080e7          	jalr	16(ra) # 80000bec <acquire>
    if (p->pid == pid)
    80002be4:	589c                	lw	a5,48(s1)
    80002be6:	01278d63          	beq	a5,s2,80002c00 <kill+0x46>
        add_proc(&c->runnable_head, p, &c->head_lock);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002bea:	8526                	mv	a0,s1
    80002bec:	ffffe097          	auipc	ra,0xffffe
    80002bf0:	0cc080e7          	jalr	204(ra) # 80000cb8 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002bf4:	18848493          	addi	s1,s1,392
    80002bf8:	ff3491e3          	bne	s1,s3,80002bda <kill+0x20>
  }
  return -1;
    80002bfc:	557d                	li	a0,-1
    80002bfe:	a829                	j	80002c18 <kill+0x5e>
      p->killed = 1;
    80002c00:	4785                	li	a5,1
    80002c02:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002c04:	4c98                	lw	a4,24(s1)
    80002c06:	4789                	li	a5,2
    80002c08:	00f70f63          	beq	a4,a5,80002c26 <kill+0x6c>
      release(&p->lock);
    80002c0c:	8526                	mv	a0,s1
    80002c0e:	ffffe097          	auipc	ra,0xffffe
    80002c12:	0aa080e7          	jalr	170(ra) # 80000cb8 <release>
      return 0;
    80002c16:	4501                	li	a0,0
}
    80002c18:	70a2                	ld	ra,40(sp)
    80002c1a:	7402                	ld	s0,32(sp)
    80002c1c:	64e2                	ld	s1,24(sp)
    80002c1e:	6942                	ld	s2,16(sp)
    80002c20:	69a2                	ld	s3,8(sp)
    80002c22:	6145                	addi	sp,sp,48
    80002c24:	8082                	ret
        remove_proc(&sleeping_head, p, &sleeping_lock);
    80002c26:	0000e917          	auipc	s2,0xe
    80002c2a:	67a90913          	addi	s2,s2,1658 # 800112a0 <cpus>
    80002c2e:	0000f617          	auipc	a2,0xf
    80002c32:	c2260613          	addi	a2,a2,-990 # 80011850 <sleeping_lock>
    80002c36:	85a6                	mv	a1,s1
    80002c38:	00006517          	auipc	a0,0x6
    80002c3c:	c2850513          	addi	a0,a0,-984 # 80008860 <sleeping_head>
    80002c40:	fffff097          	auipc	ra,0xfffff
    80002c44:	d6e080e7          	jalr	-658(ra) # 800019ae <remove_proc>
        p->state = RUNNABLE;
    80002c48:	478d                	li	a5,3
    80002c4a:	cc9c                	sw	a5,24(s1)
        struct cpu *c = &cpus[p->cpu];
    80002c4c:	58dc                	lw	a5,52(s1)
    80002c4e:	2781                	sext.w	a5,a5
        add_proc(&c->runnable_head, p, &c->head_lock);
    80002c50:	0b000713          	li	a4,176
    80002c54:	02e787b3          	mul	a5,a5,a4
    80002c58:	09078613          	addi	a2,a5,144
    80002c5c:	08878793          	addi	a5,a5,136
    80002c60:	964a                	add	a2,a2,s2
    80002c62:	85a6                	mv	a1,s1
    80002c64:	00f90533          	add	a0,s2,a5
    80002c68:	fffff097          	auipc	ra,0xfffff
    80002c6c:	e8a080e7          	jalr	-374(ra) # 80001af2 <add_proc>
    80002c70:	bf71                	j	80002c0c <kill+0x52>

0000000080002c72 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002c72:	7179                	addi	sp,sp,-48
    80002c74:	f406                	sd	ra,40(sp)
    80002c76:	f022                	sd	s0,32(sp)
    80002c78:	ec26                	sd	s1,24(sp)
    80002c7a:	e84a                	sd	s2,16(sp)
    80002c7c:	e44e                	sd	s3,8(sp)
    80002c7e:	e052                	sd	s4,0(sp)
    80002c80:	1800                	addi	s0,sp,48
    80002c82:	84aa                	mv	s1,a0
    80002c84:	892e                	mv	s2,a1
    80002c86:	89b2                	mv	s3,a2
    80002c88:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002c8a:	fffff097          	auipc	ra,0xfffff
    80002c8e:	1d2080e7          	jalr	466(ra) # 80001e5c <myproc>
  if (user_dst)
    80002c92:	c08d                	beqz	s1,80002cb4 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002c94:	86d2                	mv	a3,s4
    80002c96:	864e                	mv	a2,s3
    80002c98:	85ca                	mv	a1,s2
    80002c9a:	7928                	ld	a0,112(a0)
    80002c9c:	fffff097          	auipc	ra,0xfffff
    80002ca0:	a08080e7          	jalr	-1528(ra) # 800016a4 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002ca4:	70a2                	ld	ra,40(sp)
    80002ca6:	7402                	ld	s0,32(sp)
    80002ca8:	64e2                	ld	s1,24(sp)
    80002caa:	6942                	ld	s2,16(sp)
    80002cac:	69a2                	ld	s3,8(sp)
    80002cae:	6a02                	ld	s4,0(sp)
    80002cb0:	6145                	addi	sp,sp,48
    80002cb2:	8082                	ret
    memmove((char *)dst, src, len);
    80002cb4:	000a061b          	sext.w	a2,s4
    80002cb8:	85ce                	mv	a1,s3
    80002cba:	854a                	mv	a0,s2
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	0b6080e7          	jalr	182(ra) # 80000d72 <memmove>
    return 0;
    80002cc4:	8526                	mv	a0,s1
    80002cc6:	bff9                	j	80002ca4 <either_copyout+0x32>

0000000080002cc8 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002cc8:	7179                	addi	sp,sp,-48
    80002cca:	f406                	sd	ra,40(sp)
    80002ccc:	f022                	sd	s0,32(sp)
    80002cce:	ec26                	sd	s1,24(sp)
    80002cd0:	e84a                	sd	s2,16(sp)
    80002cd2:	e44e                	sd	s3,8(sp)
    80002cd4:	e052                	sd	s4,0(sp)
    80002cd6:	1800                	addi	s0,sp,48
    80002cd8:	892a                	mv	s2,a0
    80002cda:	84ae                	mv	s1,a1
    80002cdc:	89b2                	mv	s3,a2
    80002cde:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002ce0:	fffff097          	auipc	ra,0xfffff
    80002ce4:	17c080e7          	jalr	380(ra) # 80001e5c <myproc>
  if (user_src)
    80002ce8:	c08d                	beqz	s1,80002d0a <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002cea:	86d2                	mv	a3,s4
    80002cec:	864e                	mv	a2,s3
    80002cee:	85ca                	mv	a1,s2
    80002cf0:	7928                	ld	a0,112(a0)
    80002cf2:	fffff097          	auipc	ra,0xfffff
    80002cf6:	a3e080e7          	jalr	-1474(ra) # 80001730 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002cfa:	70a2                	ld	ra,40(sp)
    80002cfc:	7402                	ld	s0,32(sp)
    80002cfe:	64e2                	ld	s1,24(sp)
    80002d00:	6942                	ld	s2,16(sp)
    80002d02:	69a2                	ld	s3,8(sp)
    80002d04:	6a02                	ld	s4,0(sp)
    80002d06:	6145                	addi	sp,sp,48
    80002d08:	8082                	ret
    memmove(dst, (char *)src, len);
    80002d0a:	000a061b          	sext.w	a2,s4
    80002d0e:	85ce                	mv	a1,s3
    80002d10:	854a                	mv	a0,s2
    80002d12:	ffffe097          	auipc	ra,0xffffe
    80002d16:	060080e7          	jalr	96(ra) # 80000d72 <memmove>
    return 0;
    80002d1a:	8526                	mv	a0,s1
    80002d1c:	bff9                	j	80002cfa <either_copyin+0x32>

0000000080002d1e <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002d1e:	715d                	addi	sp,sp,-80
    80002d20:	e486                	sd	ra,72(sp)
    80002d22:	e0a2                	sd	s0,64(sp)
    80002d24:	fc26                	sd	s1,56(sp)
    80002d26:	f84a                	sd	s2,48(sp)
    80002d28:	f44e                	sd	s3,40(sp)
    80002d2a:	f052                	sd	s4,32(sp)
    80002d2c:	ec56                	sd	s5,24(sp)
    80002d2e:	e85a                	sd	s6,16(sp)
    80002d30:	e45e                	sd	s7,8(sp)
    80002d32:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002d34:	00005517          	auipc	a0,0x5
    80002d38:	39c50513          	addi	a0,a0,924 # 800080d0 <digits+0x90>
    80002d3c:	ffffe097          	auipc	ra,0xffffe
    80002d40:	84c080e7          	jalr	-1972(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002d44:	0000f497          	auipc	s1,0xf
    80002d48:	ccc48493          	addi	s1,s1,-820 # 80011a10 <proc+0x178>
    80002d4c:	00015917          	auipc	s2,0x15
    80002d50:	ec490913          	addi	s2,s2,-316 # 80017c10 <bcache+0x160>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002d54:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002d56:	00005997          	auipc	s3,0x5
    80002d5a:	56a98993          	addi	s3,s3,1386 # 800082c0 <digits+0x280>
    printf("%d %s %s", p->pid, state, p->name);
    80002d5e:	00005a97          	auipc	s5,0x5
    80002d62:	56aa8a93          	addi	s5,s5,1386 # 800082c8 <digits+0x288>
    printf("\n");
    80002d66:	00005a17          	auipc	s4,0x5
    80002d6a:	36aa0a13          	addi	s4,s4,874 # 800080d0 <digits+0x90>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002d6e:	00005b97          	auipc	s7,0x5
    80002d72:	582b8b93          	addi	s7,s7,1410 # 800082f0 <states.1805>
    80002d76:	a00d                	j	80002d98 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002d78:	eb86a583          	lw	a1,-328(a3)
    80002d7c:	8556                	mv	a0,s5
    80002d7e:	ffffe097          	auipc	ra,0xffffe
    80002d82:	80a080e7          	jalr	-2038(ra) # 80000588 <printf>
    printf("\n");
    80002d86:	8552                	mv	a0,s4
    80002d88:	ffffe097          	auipc	ra,0xffffe
    80002d8c:	800080e7          	jalr	-2048(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002d90:	18848493          	addi	s1,s1,392
    80002d94:	03248163          	beq	s1,s2,80002db6 <procdump+0x98>
    if (p->state == UNUSED)
    80002d98:	86a6                	mv	a3,s1
    80002d9a:	ea04a783          	lw	a5,-352(s1)
    80002d9e:	dbed                	beqz	a5,80002d90 <procdump+0x72>
      state = "???";
    80002da0:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002da2:	fcfb6be3          	bltu	s6,a5,80002d78 <procdump+0x5a>
    80002da6:	1782                	slli	a5,a5,0x20
    80002da8:	9381                	srli	a5,a5,0x20
    80002daa:	078e                	slli	a5,a5,0x3
    80002dac:	97de                	add	a5,a5,s7
    80002dae:	6390                	ld	a2,0(a5)
    80002db0:	f661                	bnez	a2,80002d78 <procdump+0x5a>
      state = "???";
    80002db2:	864e                	mv	a2,s3
    80002db4:	b7d1                	j	80002d78 <procdump+0x5a>
  }
}
    80002db6:	60a6                	ld	ra,72(sp)
    80002db8:	6406                	ld	s0,64(sp)
    80002dba:	74e2                	ld	s1,56(sp)
    80002dbc:	7942                	ld	s2,48(sp)
    80002dbe:	79a2                	ld	s3,40(sp)
    80002dc0:	7a02                	ld	s4,32(sp)
    80002dc2:	6ae2                	ld	s5,24(sp)
    80002dc4:	6b42                	ld	s6,16(sp)
    80002dc6:	6ba2                	ld	s7,8(sp)
    80002dc8:	6161                	addi	sp,sp,80
    80002dca:	8082                	ret

0000000080002dcc <get_cpu>:

int get_cpu()
{
    80002dcc:	1101                	addi	sp,sp,-32
    80002dce:	ec06                	sd	ra,24(sp)
    80002dd0:	e822                	sd	s0,16(sp)
    80002dd2:	e426                	sd	s1,8(sp)
    80002dd4:	e04a                	sd	s2,0(sp)
    80002dd6:	1000                	addi	s0,sp,32
  int cpu_num = -1;
  struct proc *p = myproc();
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	084080e7          	jalr	132(ra) # 80001e5c <myproc>
    80002de0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002de2:	ffffe097          	auipc	ra,0xffffe
    80002de6:	e0a080e7          	jalr	-502(ra) # 80000bec <acquire>
  cpu_num = p->cpu;
    80002dea:	0344a903          	lw	s2,52(s1)
    80002dee:	2901                	sext.w	s2,s2
  release(&p->lock);
    80002df0:	8526                	mv	a0,s1
    80002df2:	ffffe097          	auipc	ra,0xffffe
    80002df6:	ec6080e7          	jalr	-314(ra) # 80000cb8 <release>
  return cpu_num;
}
    80002dfa:	854a                	mv	a0,s2
    80002dfc:	60e2                	ld	ra,24(sp)
    80002dfe:	6442                	ld	s0,16(sp)
    80002e00:	64a2                	ld	s1,8(sp)
    80002e02:	6902                	ld	s2,0(sp)
    80002e04:	6105                	addi	sp,sp,32
    80002e06:	8082                	ret

0000000080002e08 <set_cpu>:

int set_cpu(int cpu_num)
{
    80002e08:	1101                	addi	sp,sp,-32
    80002e0a:	ec06                	sd	ra,24(sp)
    80002e0c:	e822                	sd	s0,16(sp)
    80002e0e:	e426                	sd	s1,8(sp)
    80002e10:	1000                	addi	s0,sp,32
    80002e12:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e14:	fffff097          	auipc	ra,0xfffff
    80002e18:	048080e7          	jalr	72(ra) # 80001e5c <myproc>
  if (cas(&p->cpu, p->cpu, cpu_num) != 0)
    80002e1c:	594c                	lw	a1,52(a0)
    80002e1e:	8626                	mv	a2,s1
    80002e20:	2581                	sext.w	a1,a1
    80002e22:	03450513          	addi	a0,a0,52
    80002e26:	00004097          	auipc	ra,0x4
    80002e2a:	c80080e7          	jalr	-896(ra) # 80006aa6 <cas>
    80002e2e:	e919                	bnez	a0,80002e44 <set_cpu+0x3c>
    return -1;
  yield();
    80002e30:	00000097          	auipc	ra,0x0
    80002e34:	874080e7          	jalr	-1932(ra) # 800026a4 <yield>
  return cpu_num;
    80002e38:	8526                	mv	a0,s1
}
    80002e3a:	60e2                	ld	ra,24(sp)
    80002e3c:	6442                	ld	s0,16(sp)
    80002e3e:	64a2                	ld	s1,8(sp)
    80002e40:	6105                	addi	sp,sp,32
    80002e42:	8082                	ret
    return -1;
    80002e44:	557d                	li	a0,-1
    80002e46:	bfd5                	j	80002e3a <set_cpu+0x32>

0000000080002e48 <cpu_process_count>:

int cpu_process_count(int cpu_num)
{
    80002e48:	1141                	addi	sp,sp,-16
    80002e4a:	e422                	sd	s0,8(sp)
    80002e4c:	0800                	addi	s0,sp,16
  return (cpus[cpu_num].proc_counter);
    80002e4e:	0b000793          	li	a5,176
    80002e52:	02f507b3          	mul	a5,a0,a5
    80002e56:	0000e517          	auipc	a0,0xe
    80002e5a:	44a50513          	addi	a0,a0,1098 # 800112a0 <cpus>
    80002e5e:	953e                	add	a0,a0,a5
    80002e60:	7548                	ld	a0,168(a0)
    80002e62:	2501                	sext.w	a0,a0
    80002e64:	6422                	ld	s0,8(sp)
    80002e66:	0141                	addi	sp,sp,16
    80002e68:	8082                	ret

0000000080002e6a <swtch>:
    80002e6a:	00153023          	sd	ra,0(a0)
    80002e6e:	00253423          	sd	sp,8(a0)
    80002e72:	e900                	sd	s0,16(a0)
    80002e74:	ed04                	sd	s1,24(a0)
    80002e76:	03253023          	sd	s2,32(a0)
    80002e7a:	03353423          	sd	s3,40(a0)
    80002e7e:	03453823          	sd	s4,48(a0)
    80002e82:	03553c23          	sd	s5,56(a0)
    80002e86:	05653023          	sd	s6,64(a0)
    80002e8a:	05753423          	sd	s7,72(a0)
    80002e8e:	05853823          	sd	s8,80(a0)
    80002e92:	05953c23          	sd	s9,88(a0)
    80002e96:	07a53023          	sd	s10,96(a0)
    80002e9a:	07b53423          	sd	s11,104(a0)
    80002e9e:	0005b083          	ld	ra,0(a1)
    80002ea2:	0085b103          	ld	sp,8(a1)
    80002ea6:	6980                	ld	s0,16(a1)
    80002ea8:	6d84                	ld	s1,24(a1)
    80002eaa:	0205b903          	ld	s2,32(a1)
    80002eae:	0285b983          	ld	s3,40(a1)
    80002eb2:	0305ba03          	ld	s4,48(a1)
    80002eb6:	0385ba83          	ld	s5,56(a1)
    80002eba:	0405bb03          	ld	s6,64(a1)
    80002ebe:	0485bb83          	ld	s7,72(a1)
    80002ec2:	0505bc03          	ld	s8,80(a1)
    80002ec6:	0585bc83          	ld	s9,88(a1)
    80002eca:	0605bd03          	ld	s10,96(a1)
    80002ece:	0685bd83          	ld	s11,104(a1)
    80002ed2:	8082                	ret

0000000080002ed4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002ed4:	1141                	addi	sp,sp,-16
    80002ed6:	e406                	sd	ra,8(sp)
    80002ed8:	e022                	sd	s0,0(sp)
    80002eda:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002edc:	00005597          	auipc	a1,0x5
    80002ee0:	44458593          	addi	a1,a1,1092 # 80008320 <states.1805+0x30>
    80002ee4:	00015517          	auipc	a0,0x15
    80002ee8:	bb450513          	addi	a0,a0,-1100 # 80017a98 <tickslock>
    80002eec:	ffffe097          	auipc	ra,0xffffe
    80002ef0:	c68080e7          	jalr	-920(ra) # 80000b54 <initlock>
}
    80002ef4:	60a2                	ld	ra,8(sp)
    80002ef6:	6402                	ld	s0,0(sp)
    80002ef8:	0141                	addi	sp,sp,16
    80002efa:	8082                	ret

0000000080002efc <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002efc:	1141                	addi	sp,sp,-16
    80002efe:	e422                	sd	s0,8(sp)
    80002f00:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f02:	00003797          	auipc	a5,0x3
    80002f06:	4ce78793          	addi	a5,a5,1230 # 800063d0 <kernelvec>
    80002f0a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002f0e:	6422                	ld	s0,8(sp)
    80002f10:	0141                	addi	sp,sp,16
    80002f12:	8082                	ret

0000000080002f14 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002f14:	1141                	addi	sp,sp,-16
    80002f16:	e406                	sd	ra,8(sp)
    80002f18:	e022                	sd	s0,0(sp)
    80002f1a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002f1c:	fffff097          	auipc	ra,0xfffff
    80002f20:	f40080e7          	jalr	-192(ra) # 80001e5c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f24:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002f28:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f2a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002f2e:	00004617          	auipc	a2,0x4
    80002f32:	0d260613          	addi	a2,a2,210 # 80007000 <_trampoline>
    80002f36:	00004697          	auipc	a3,0x4
    80002f3a:	0ca68693          	addi	a3,a3,202 # 80007000 <_trampoline>
    80002f3e:	8e91                	sub	a3,a3,a2
    80002f40:	040007b7          	lui	a5,0x4000
    80002f44:	17fd                	addi	a5,a5,-1
    80002f46:	07b2                	slli	a5,a5,0xc
    80002f48:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f4a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002f4e:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002f50:	180026f3          	csrr	a3,satp
    80002f54:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002f56:	7d38                	ld	a4,120(a0)
    80002f58:	7134                	ld	a3,96(a0)
    80002f5a:	6585                	lui	a1,0x1
    80002f5c:	96ae                	add	a3,a3,a1
    80002f5e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002f60:	7d38                	ld	a4,120(a0)
    80002f62:	00000697          	auipc	a3,0x0
    80002f66:	13868693          	addi	a3,a3,312 # 8000309a <usertrap>
    80002f6a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002f6c:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002f6e:	8692                	mv	a3,tp
    80002f70:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f72:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002f76:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002f7a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f7e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002f82:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f84:	6f18                	ld	a4,24(a4)
    80002f86:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002f8a:	792c                	ld	a1,112(a0)
    80002f8c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002f8e:	00004717          	auipc	a4,0x4
    80002f92:	10270713          	addi	a4,a4,258 # 80007090 <userret>
    80002f96:	8f11                	sub	a4,a4,a2
    80002f98:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002f9a:	577d                	li	a4,-1
    80002f9c:	177e                	slli	a4,a4,0x3f
    80002f9e:	8dd9                	or	a1,a1,a4
    80002fa0:	02000537          	lui	a0,0x2000
    80002fa4:	157d                	addi	a0,a0,-1
    80002fa6:	0536                	slli	a0,a0,0xd
    80002fa8:	9782                	jalr	a5
}
    80002faa:	60a2                	ld	ra,8(sp)
    80002fac:	6402                	ld	s0,0(sp)
    80002fae:	0141                	addi	sp,sp,16
    80002fb0:	8082                	ret

0000000080002fb2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002fb2:	1101                	addi	sp,sp,-32
    80002fb4:	ec06                	sd	ra,24(sp)
    80002fb6:	e822                	sd	s0,16(sp)
    80002fb8:	e426                	sd	s1,8(sp)
    80002fba:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002fbc:	00015497          	auipc	s1,0x15
    80002fc0:	adc48493          	addi	s1,s1,-1316 # 80017a98 <tickslock>
    80002fc4:	8526                	mv	a0,s1
    80002fc6:	ffffe097          	auipc	ra,0xffffe
    80002fca:	c26080e7          	jalr	-986(ra) # 80000bec <acquire>
  ticks++;
    80002fce:	00006517          	auipc	a0,0x6
    80002fd2:	06250513          	addi	a0,a0,98 # 80009030 <ticks>
    80002fd6:	411c                	lw	a5,0(a0)
    80002fd8:	2785                	addiw	a5,a5,1
    80002fda:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002fdc:	00000097          	auipc	ra,0x0
    80002fe0:	9ac080e7          	jalr	-1620(ra) # 80002988 <wakeup>
  release(&tickslock);
    80002fe4:	8526                	mv	a0,s1
    80002fe6:	ffffe097          	auipc	ra,0xffffe
    80002fea:	cd2080e7          	jalr	-814(ra) # 80000cb8 <release>
}
    80002fee:	60e2                	ld	ra,24(sp)
    80002ff0:	6442                	ld	s0,16(sp)
    80002ff2:	64a2                	ld	s1,8(sp)
    80002ff4:	6105                	addi	sp,sp,32
    80002ff6:	8082                	ret

0000000080002ff8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002ff8:	1101                	addi	sp,sp,-32
    80002ffa:	ec06                	sd	ra,24(sp)
    80002ffc:	e822                	sd	s0,16(sp)
    80002ffe:	e426                	sd	s1,8(sp)
    80003000:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003002:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003006:	00074d63          	bltz	a4,80003020 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000300a:	57fd                	li	a5,-1
    8000300c:	17fe                	slli	a5,a5,0x3f
    8000300e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80003010:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003012:	06f70363          	beq	a4,a5,80003078 <devintr+0x80>
  }
}
    80003016:	60e2                	ld	ra,24(sp)
    80003018:	6442                	ld	s0,16(sp)
    8000301a:	64a2                	ld	s1,8(sp)
    8000301c:	6105                	addi	sp,sp,32
    8000301e:	8082                	ret
     (scause & 0xff) == 9){
    80003020:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003024:	46a5                	li	a3,9
    80003026:	fed792e3          	bne	a5,a3,8000300a <devintr+0x12>
    int irq = plic_claim();
    8000302a:	00003097          	auipc	ra,0x3
    8000302e:	4ae080e7          	jalr	1198(ra) # 800064d8 <plic_claim>
    80003032:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003034:	47a9                	li	a5,10
    80003036:	02f50763          	beq	a0,a5,80003064 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000303a:	4785                	li	a5,1
    8000303c:	02f50963          	beq	a0,a5,8000306e <devintr+0x76>
    return 1;
    80003040:	4505                	li	a0,1
    } else if(irq){
    80003042:	d8f1                	beqz	s1,80003016 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003044:	85a6                	mv	a1,s1
    80003046:	00005517          	auipc	a0,0x5
    8000304a:	2e250513          	addi	a0,a0,738 # 80008328 <states.1805+0x38>
    8000304e:	ffffd097          	auipc	ra,0xffffd
    80003052:	53a080e7          	jalr	1338(ra) # 80000588 <printf>
      plic_complete(irq);
    80003056:	8526                	mv	a0,s1
    80003058:	00003097          	auipc	ra,0x3
    8000305c:	4a4080e7          	jalr	1188(ra) # 800064fc <plic_complete>
    return 1;
    80003060:	4505                	li	a0,1
    80003062:	bf55                	j	80003016 <devintr+0x1e>
      uartintr();
    80003064:	ffffe097          	auipc	ra,0xffffe
    80003068:	944080e7          	jalr	-1724(ra) # 800009a8 <uartintr>
    8000306c:	b7ed                	j	80003056 <devintr+0x5e>
      virtio_disk_intr();
    8000306e:	00004097          	auipc	ra,0x4
    80003072:	96e080e7          	jalr	-1682(ra) # 800069dc <virtio_disk_intr>
    80003076:	b7c5                	j	80003056 <devintr+0x5e>
    if(cpuid() == 0){
    80003078:	fffff097          	auipc	ra,0xfffff
    8000307c:	db2080e7          	jalr	-590(ra) # 80001e2a <cpuid>
    80003080:	c901                	beqz	a0,80003090 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003082:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003086:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003088:	14479073          	csrw	sip,a5
    return 2;
    8000308c:	4509                	li	a0,2
    8000308e:	b761                	j	80003016 <devintr+0x1e>
      clockintr();
    80003090:	00000097          	auipc	ra,0x0
    80003094:	f22080e7          	jalr	-222(ra) # 80002fb2 <clockintr>
    80003098:	b7ed                	j	80003082 <devintr+0x8a>

000000008000309a <usertrap>:
{
    8000309a:	1101                	addi	sp,sp,-32
    8000309c:	ec06                	sd	ra,24(sp)
    8000309e:	e822                	sd	s0,16(sp)
    800030a0:	e426                	sd	s1,8(sp)
    800030a2:	e04a                	sd	s2,0(sp)
    800030a4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030a6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800030aa:	1007f793          	andi	a5,a5,256
    800030ae:	e3ad                	bnez	a5,80003110 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800030b0:	00003797          	auipc	a5,0x3
    800030b4:	32078793          	addi	a5,a5,800 # 800063d0 <kernelvec>
    800030b8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800030bc:	fffff097          	auipc	ra,0xfffff
    800030c0:	da0080e7          	jalr	-608(ra) # 80001e5c <myproc>
    800030c4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800030c6:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030c8:	14102773          	csrr	a4,sepc
    800030cc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030ce:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800030d2:	47a1                	li	a5,8
    800030d4:	04f71c63          	bne	a4,a5,8000312c <usertrap+0x92>
    if(p->killed)
    800030d8:	551c                	lw	a5,40(a0)
    800030da:	e3b9                	bnez	a5,80003120 <usertrap+0x86>
    p->trapframe->epc += 4;
    800030dc:	7cb8                	ld	a4,120(s1)
    800030de:	6f1c                	ld	a5,24(a4)
    800030e0:	0791                	addi	a5,a5,4
    800030e2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030e4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800030e8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030ec:	10079073          	csrw	sstatus,a5
    syscall();
    800030f0:	00000097          	auipc	ra,0x0
    800030f4:	2e0080e7          	jalr	736(ra) # 800033d0 <syscall>
  if(p->killed)
    800030f8:	549c                	lw	a5,40(s1)
    800030fa:	ebc1                	bnez	a5,8000318a <usertrap+0xf0>
  usertrapret();
    800030fc:	00000097          	auipc	ra,0x0
    80003100:	e18080e7          	jalr	-488(ra) # 80002f14 <usertrapret>
}
    80003104:	60e2                	ld	ra,24(sp)
    80003106:	6442                	ld	s0,16(sp)
    80003108:	64a2                	ld	s1,8(sp)
    8000310a:	6902                	ld	s2,0(sp)
    8000310c:	6105                	addi	sp,sp,32
    8000310e:	8082                	ret
    panic("usertrap: not from user mode");
    80003110:	00005517          	auipc	a0,0x5
    80003114:	23850513          	addi	a0,a0,568 # 80008348 <states.1805+0x58>
    80003118:	ffffd097          	auipc	ra,0xffffd
    8000311c:	426080e7          	jalr	1062(ra) # 8000053e <panic>
      exit(-1);
    80003120:	557d                	li	a0,-1
    80003122:	00000097          	auipc	ra,0x0
    80003126:	9a8080e7          	jalr	-1624(ra) # 80002aca <exit>
    8000312a:	bf4d                	j	800030dc <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000312c:	00000097          	auipc	ra,0x0
    80003130:	ecc080e7          	jalr	-308(ra) # 80002ff8 <devintr>
    80003134:	892a                	mv	s2,a0
    80003136:	c501                	beqz	a0,8000313e <usertrap+0xa4>
  if(p->killed)
    80003138:	549c                	lw	a5,40(s1)
    8000313a:	c3a1                	beqz	a5,8000317a <usertrap+0xe0>
    8000313c:	a815                	j	80003170 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000313e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003142:	5890                	lw	a2,48(s1)
    80003144:	00005517          	auipc	a0,0x5
    80003148:	22450513          	addi	a0,a0,548 # 80008368 <states.1805+0x78>
    8000314c:	ffffd097          	auipc	ra,0xffffd
    80003150:	43c080e7          	jalr	1084(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003154:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003158:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000315c:	00005517          	auipc	a0,0x5
    80003160:	23c50513          	addi	a0,a0,572 # 80008398 <states.1805+0xa8>
    80003164:	ffffd097          	auipc	ra,0xffffd
    80003168:	424080e7          	jalr	1060(ra) # 80000588 <printf>
    p->killed = 1;
    8000316c:	4785                	li	a5,1
    8000316e:	d49c                	sw	a5,40(s1)
    exit(-1);
    80003170:	557d                	li	a0,-1
    80003172:	00000097          	auipc	ra,0x0
    80003176:	958080e7          	jalr	-1704(ra) # 80002aca <exit>
  if(which_dev == 2)
    8000317a:	4789                	li	a5,2
    8000317c:	f8f910e3          	bne	s2,a5,800030fc <usertrap+0x62>
    yield();
    80003180:	fffff097          	auipc	ra,0xfffff
    80003184:	524080e7          	jalr	1316(ra) # 800026a4 <yield>
    80003188:	bf95                	j	800030fc <usertrap+0x62>
  int which_dev = 0;
    8000318a:	4901                	li	s2,0
    8000318c:	b7d5                	j	80003170 <usertrap+0xd6>

000000008000318e <kerneltrap>:
{
    8000318e:	7179                	addi	sp,sp,-48
    80003190:	f406                	sd	ra,40(sp)
    80003192:	f022                	sd	s0,32(sp)
    80003194:	ec26                	sd	s1,24(sp)
    80003196:	e84a                	sd	s2,16(sp)
    80003198:	e44e                	sd	s3,8(sp)
    8000319a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000319c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031a0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031a4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800031a8:	1004f793          	andi	a5,s1,256
    800031ac:	cb85                	beqz	a5,800031dc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031ae:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800031b2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800031b4:	ef85                	bnez	a5,800031ec <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800031b6:	00000097          	auipc	ra,0x0
    800031ba:	e42080e7          	jalr	-446(ra) # 80002ff8 <devintr>
    800031be:	cd1d                	beqz	a0,800031fc <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800031c0:	4789                	li	a5,2
    800031c2:	06f50a63          	beq	a0,a5,80003236 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800031c6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031ca:	10049073          	csrw	sstatus,s1
}
    800031ce:	70a2                	ld	ra,40(sp)
    800031d0:	7402                	ld	s0,32(sp)
    800031d2:	64e2                	ld	s1,24(sp)
    800031d4:	6942                	ld	s2,16(sp)
    800031d6:	69a2                	ld	s3,8(sp)
    800031d8:	6145                	addi	sp,sp,48
    800031da:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800031dc:	00005517          	auipc	a0,0x5
    800031e0:	1dc50513          	addi	a0,a0,476 # 800083b8 <states.1805+0xc8>
    800031e4:	ffffd097          	auipc	ra,0xffffd
    800031e8:	35a080e7          	jalr	858(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800031ec:	00005517          	auipc	a0,0x5
    800031f0:	1f450513          	addi	a0,a0,500 # 800083e0 <states.1805+0xf0>
    800031f4:	ffffd097          	auipc	ra,0xffffd
    800031f8:	34a080e7          	jalr	842(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800031fc:	85ce                	mv	a1,s3
    800031fe:	00005517          	auipc	a0,0x5
    80003202:	20250513          	addi	a0,a0,514 # 80008400 <states.1805+0x110>
    80003206:	ffffd097          	auipc	ra,0xffffd
    8000320a:	382080e7          	jalr	898(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000320e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003212:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003216:	00005517          	auipc	a0,0x5
    8000321a:	1fa50513          	addi	a0,a0,506 # 80008410 <states.1805+0x120>
    8000321e:	ffffd097          	auipc	ra,0xffffd
    80003222:	36a080e7          	jalr	874(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003226:	00005517          	auipc	a0,0x5
    8000322a:	20250513          	addi	a0,a0,514 # 80008428 <states.1805+0x138>
    8000322e:	ffffd097          	auipc	ra,0xffffd
    80003232:	310080e7          	jalr	784(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003236:	fffff097          	auipc	ra,0xfffff
    8000323a:	c26080e7          	jalr	-986(ra) # 80001e5c <myproc>
    8000323e:	d541                	beqz	a0,800031c6 <kerneltrap+0x38>
    80003240:	fffff097          	auipc	ra,0xfffff
    80003244:	c1c080e7          	jalr	-996(ra) # 80001e5c <myproc>
    80003248:	4d18                	lw	a4,24(a0)
    8000324a:	4791                	li	a5,4
    8000324c:	f6f71de3          	bne	a4,a5,800031c6 <kerneltrap+0x38>
    yield();
    80003250:	fffff097          	auipc	ra,0xfffff
    80003254:	454080e7          	jalr	1108(ra) # 800026a4 <yield>
    80003258:	b7bd                	j	800031c6 <kerneltrap+0x38>

000000008000325a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000325a:	1101                	addi	sp,sp,-32
    8000325c:	ec06                	sd	ra,24(sp)
    8000325e:	e822                	sd	s0,16(sp)
    80003260:	e426                	sd	s1,8(sp)
    80003262:	1000                	addi	s0,sp,32
    80003264:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003266:	fffff097          	auipc	ra,0xfffff
    8000326a:	bf6080e7          	jalr	-1034(ra) # 80001e5c <myproc>
  switch (n) {
    8000326e:	4795                	li	a5,5
    80003270:	0497e163          	bltu	a5,s1,800032b2 <argraw+0x58>
    80003274:	048a                	slli	s1,s1,0x2
    80003276:	00005717          	auipc	a4,0x5
    8000327a:	1ea70713          	addi	a4,a4,490 # 80008460 <states.1805+0x170>
    8000327e:	94ba                	add	s1,s1,a4
    80003280:	409c                	lw	a5,0(s1)
    80003282:	97ba                	add	a5,a5,a4
    80003284:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003286:	7d3c                	ld	a5,120(a0)
    80003288:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000328a:	60e2                	ld	ra,24(sp)
    8000328c:	6442                	ld	s0,16(sp)
    8000328e:	64a2                	ld	s1,8(sp)
    80003290:	6105                	addi	sp,sp,32
    80003292:	8082                	ret
    return p->trapframe->a1;
    80003294:	7d3c                	ld	a5,120(a0)
    80003296:	7fa8                	ld	a0,120(a5)
    80003298:	bfcd                	j	8000328a <argraw+0x30>
    return p->trapframe->a2;
    8000329a:	7d3c                	ld	a5,120(a0)
    8000329c:	63c8                	ld	a0,128(a5)
    8000329e:	b7f5                	j	8000328a <argraw+0x30>
    return p->trapframe->a3;
    800032a0:	7d3c                	ld	a5,120(a0)
    800032a2:	67c8                	ld	a0,136(a5)
    800032a4:	b7dd                	j	8000328a <argraw+0x30>
    return p->trapframe->a4;
    800032a6:	7d3c                	ld	a5,120(a0)
    800032a8:	6bc8                	ld	a0,144(a5)
    800032aa:	b7c5                	j	8000328a <argraw+0x30>
    return p->trapframe->a5;
    800032ac:	7d3c                	ld	a5,120(a0)
    800032ae:	6fc8                	ld	a0,152(a5)
    800032b0:	bfe9                	j	8000328a <argraw+0x30>
  panic("argraw");
    800032b2:	00005517          	auipc	a0,0x5
    800032b6:	18650513          	addi	a0,a0,390 # 80008438 <states.1805+0x148>
    800032ba:	ffffd097          	auipc	ra,0xffffd
    800032be:	284080e7          	jalr	644(ra) # 8000053e <panic>

00000000800032c2 <fetchaddr>:
{
    800032c2:	1101                	addi	sp,sp,-32
    800032c4:	ec06                	sd	ra,24(sp)
    800032c6:	e822                	sd	s0,16(sp)
    800032c8:	e426                	sd	s1,8(sp)
    800032ca:	e04a                	sd	s2,0(sp)
    800032cc:	1000                	addi	s0,sp,32
    800032ce:	84aa                	mv	s1,a0
    800032d0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800032d2:	fffff097          	auipc	ra,0xfffff
    800032d6:	b8a080e7          	jalr	-1142(ra) # 80001e5c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800032da:	753c                	ld	a5,104(a0)
    800032dc:	02f4f863          	bgeu	s1,a5,8000330c <fetchaddr+0x4a>
    800032e0:	00848713          	addi	a4,s1,8
    800032e4:	02e7e663          	bltu	a5,a4,80003310 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800032e8:	46a1                	li	a3,8
    800032ea:	8626                	mv	a2,s1
    800032ec:	85ca                	mv	a1,s2
    800032ee:	7928                	ld	a0,112(a0)
    800032f0:	ffffe097          	auipc	ra,0xffffe
    800032f4:	440080e7          	jalr	1088(ra) # 80001730 <copyin>
    800032f8:	00a03533          	snez	a0,a0
    800032fc:	40a00533          	neg	a0,a0
}
    80003300:	60e2                	ld	ra,24(sp)
    80003302:	6442                	ld	s0,16(sp)
    80003304:	64a2                	ld	s1,8(sp)
    80003306:	6902                	ld	s2,0(sp)
    80003308:	6105                	addi	sp,sp,32
    8000330a:	8082                	ret
    return -1;
    8000330c:	557d                	li	a0,-1
    8000330e:	bfcd                	j	80003300 <fetchaddr+0x3e>
    80003310:	557d                	li	a0,-1
    80003312:	b7fd                	j	80003300 <fetchaddr+0x3e>

0000000080003314 <fetchstr>:
{
    80003314:	7179                	addi	sp,sp,-48
    80003316:	f406                	sd	ra,40(sp)
    80003318:	f022                	sd	s0,32(sp)
    8000331a:	ec26                	sd	s1,24(sp)
    8000331c:	e84a                	sd	s2,16(sp)
    8000331e:	e44e                	sd	s3,8(sp)
    80003320:	1800                	addi	s0,sp,48
    80003322:	892a                	mv	s2,a0
    80003324:	84ae                	mv	s1,a1
    80003326:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003328:	fffff097          	auipc	ra,0xfffff
    8000332c:	b34080e7          	jalr	-1228(ra) # 80001e5c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003330:	86ce                	mv	a3,s3
    80003332:	864a                	mv	a2,s2
    80003334:	85a6                	mv	a1,s1
    80003336:	7928                	ld	a0,112(a0)
    80003338:	ffffe097          	auipc	ra,0xffffe
    8000333c:	484080e7          	jalr	1156(ra) # 800017bc <copyinstr>
  if(err < 0)
    80003340:	00054763          	bltz	a0,8000334e <fetchstr+0x3a>
  return strlen(buf);
    80003344:	8526                	mv	a0,s1
    80003346:	ffffe097          	auipc	ra,0xffffe
    8000334a:	b50080e7          	jalr	-1200(ra) # 80000e96 <strlen>
}
    8000334e:	70a2                	ld	ra,40(sp)
    80003350:	7402                	ld	s0,32(sp)
    80003352:	64e2                	ld	s1,24(sp)
    80003354:	6942                	ld	s2,16(sp)
    80003356:	69a2                	ld	s3,8(sp)
    80003358:	6145                	addi	sp,sp,48
    8000335a:	8082                	ret

000000008000335c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000335c:	1101                	addi	sp,sp,-32
    8000335e:	ec06                	sd	ra,24(sp)
    80003360:	e822                	sd	s0,16(sp)
    80003362:	e426                	sd	s1,8(sp)
    80003364:	1000                	addi	s0,sp,32
    80003366:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003368:	00000097          	auipc	ra,0x0
    8000336c:	ef2080e7          	jalr	-270(ra) # 8000325a <argraw>
    80003370:	c088                	sw	a0,0(s1)
  return 0;
}
    80003372:	4501                	li	a0,0
    80003374:	60e2                	ld	ra,24(sp)
    80003376:	6442                	ld	s0,16(sp)
    80003378:	64a2                	ld	s1,8(sp)
    8000337a:	6105                	addi	sp,sp,32
    8000337c:	8082                	ret

000000008000337e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000337e:	1101                	addi	sp,sp,-32
    80003380:	ec06                	sd	ra,24(sp)
    80003382:	e822                	sd	s0,16(sp)
    80003384:	e426                	sd	s1,8(sp)
    80003386:	1000                	addi	s0,sp,32
    80003388:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000338a:	00000097          	auipc	ra,0x0
    8000338e:	ed0080e7          	jalr	-304(ra) # 8000325a <argraw>
    80003392:	e088                	sd	a0,0(s1)
  return 0;
}
    80003394:	4501                	li	a0,0
    80003396:	60e2                	ld	ra,24(sp)
    80003398:	6442                	ld	s0,16(sp)
    8000339a:	64a2                	ld	s1,8(sp)
    8000339c:	6105                	addi	sp,sp,32
    8000339e:	8082                	ret

00000000800033a0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800033a0:	1101                	addi	sp,sp,-32
    800033a2:	ec06                	sd	ra,24(sp)
    800033a4:	e822                	sd	s0,16(sp)
    800033a6:	e426                	sd	s1,8(sp)
    800033a8:	e04a                	sd	s2,0(sp)
    800033aa:	1000                	addi	s0,sp,32
    800033ac:	84ae                	mv	s1,a1
    800033ae:	8932                	mv	s2,a2
  *ip = argraw(n);
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	eaa080e7          	jalr	-342(ra) # 8000325a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800033b8:	864a                	mv	a2,s2
    800033ba:	85a6                	mv	a1,s1
    800033bc:	00000097          	auipc	ra,0x0
    800033c0:	f58080e7          	jalr	-168(ra) # 80003314 <fetchstr>
}
    800033c4:	60e2                	ld	ra,24(sp)
    800033c6:	6442                	ld	s0,16(sp)
    800033c8:	64a2                	ld	s1,8(sp)
    800033ca:	6902                	ld	s2,0(sp)
    800033cc:	6105                	addi	sp,sp,32
    800033ce:	8082                	ret

00000000800033d0 <syscall>:
[SYS_set_cpu] sys_set_cpu,
};

void
syscall(void)
{
    800033d0:	1101                	addi	sp,sp,-32
    800033d2:	ec06                	sd	ra,24(sp)
    800033d4:	e822                	sd	s0,16(sp)
    800033d6:	e426                	sd	s1,8(sp)
    800033d8:	e04a                	sd	s2,0(sp)
    800033da:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800033dc:	fffff097          	auipc	ra,0xfffff
    800033e0:	a80080e7          	jalr	-1408(ra) # 80001e5c <myproc>
    800033e4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800033e6:	07853903          	ld	s2,120(a0)
    800033ea:	0a893783          	ld	a5,168(s2)
    800033ee:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800033f2:	37fd                	addiw	a5,a5,-1
    800033f4:	4759                	li	a4,22
    800033f6:	00f76f63          	bltu	a4,a5,80003414 <syscall+0x44>
    800033fa:	00369713          	slli	a4,a3,0x3
    800033fe:	00005797          	auipc	a5,0x5
    80003402:	07a78793          	addi	a5,a5,122 # 80008478 <syscalls>
    80003406:	97ba                	add	a5,a5,a4
    80003408:	639c                	ld	a5,0(a5)
    8000340a:	c789                	beqz	a5,80003414 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000340c:	9782                	jalr	a5
    8000340e:	06a93823          	sd	a0,112(s2)
    80003412:	a839                	j	80003430 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003414:	17848613          	addi	a2,s1,376
    80003418:	588c                	lw	a1,48(s1)
    8000341a:	00005517          	auipc	a0,0x5
    8000341e:	02650513          	addi	a0,a0,38 # 80008440 <states.1805+0x150>
    80003422:	ffffd097          	auipc	ra,0xffffd
    80003426:	166080e7          	jalr	358(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000342a:	7cbc                	ld	a5,120(s1)
    8000342c:	577d                	li	a4,-1
    8000342e:	fbb8                	sd	a4,112(a5)
  }
}
    80003430:	60e2                	ld	ra,24(sp)
    80003432:	6442                	ld	s0,16(sp)
    80003434:	64a2                	ld	s1,8(sp)
    80003436:	6902                	ld	s2,0(sp)
    80003438:	6105                	addi	sp,sp,32
    8000343a:	8082                	ret

000000008000343c <sys_set_cpu>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_set_cpu(void)
{
    8000343c:	1101                	addi	sp,sp,-32
    8000343e:	ec06                	sd	ra,24(sp)
    80003440:	e822                	sd	s0,16(sp)
    80003442:	1000                	addi	s0,sp,32
  int cpu_num;
  if(argint(0, &cpu_num) < 0)
    80003444:	fec40593          	addi	a1,s0,-20
    80003448:	4501                	li	a0,0
    8000344a:	00000097          	auipc	ra,0x0
    8000344e:	f12080e7          	jalr	-238(ra) # 8000335c <argint>
    80003452:	87aa                	mv	a5,a0
    return -1;
    80003454:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    80003456:	0007c863          	bltz	a5,80003466 <sys_set_cpu+0x2a>
  return set_cpu(cpu_num); 
    8000345a:	fec42503          	lw	a0,-20(s0)
    8000345e:	00000097          	auipc	ra,0x0
    80003462:	9aa080e7          	jalr	-1622(ra) # 80002e08 <set_cpu>
}
    80003466:	60e2                	ld	ra,24(sp)
    80003468:	6442                	ld	s0,16(sp)
    8000346a:	6105                	addi	sp,sp,32
    8000346c:	8082                	ret

000000008000346e <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    8000346e:	1141                	addi	sp,sp,-16
    80003470:	e406                	sd	ra,8(sp)
    80003472:	e022                	sd	s0,0(sp)
    80003474:	0800                	addi	s0,sp,16
  return get_cpu(); 
    80003476:	00000097          	auipc	ra,0x0
    8000347a:	956080e7          	jalr	-1706(ra) # 80002dcc <get_cpu>
}
    8000347e:	60a2                	ld	ra,8(sp)
    80003480:	6402                	ld	s0,0(sp)
    80003482:	0141                	addi	sp,sp,16
    80003484:	8082                	ret

0000000080003486 <sys_exit>:

uint64
sys_exit(void)
{
    80003486:	1101                	addi	sp,sp,-32
    80003488:	ec06                	sd	ra,24(sp)
    8000348a:	e822                	sd	s0,16(sp)
    8000348c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000348e:	fec40593          	addi	a1,s0,-20
    80003492:	4501                	li	a0,0
    80003494:	00000097          	auipc	ra,0x0
    80003498:	ec8080e7          	jalr	-312(ra) # 8000335c <argint>
    return -1;
    8000349c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000349e:	00054963          	bltz	a0,800034b0 <sys_exit+0x2a>
  exit(n);
    800034a2:	fec42503          	lw	a0,-20(s0)
    800034a6:	fffff097          	auipc	ra,0xfffff
    800034aa:	624080e7          	jalr	1572(ra) # 80002aca <exit>
  return 0;  // not reached
    800034ae:	4781                	li	a5,0
}
    800034b0:	853e                	mv	a0,a5
    800034b2:	60e2                	ld	ra,24(sp)
    800034b4:	6442                	ld	s0,16(sp)
    800034b6:	6105                	addi	sp,sp,32
    800034b8:	8082                	ret

00000000800034ba <sys_getpid>:

uint64
sys_getpid(void)
{
    800034ba:	1141                	addi	sp,sp,-16
    800034bc:	e406                	sd	ra,8(sp)
    800034be:	e022                	sd	s0,0(sp)
    800034c0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800034c2:	fffff097          	auipc	ra,0xfffff
    800034c6:	99a080e7          	jalr	-1638(ra) # 80001e5c <myproc>
}
    800034ca:	5908                	lw	a0,48(a0)
    800034cc:	60a2                	ld	ra,8(sp)
    800034ce:	6402                	ld	s0,0(sp)
    800034d0:	0141                	addi	sp,sp,16
    800034d2:	8082                	ret

00000000800034d4 <sys_fork>:

uint64
sys_fork(void)
{
    800034d4:	1141                	addi	sp,sp,-16
    800034d6:	e406                	sd	ra,8(sp)
    800034d8:	e022                	sd	s0,0(sp)
    800034da:	0800                	addi	s0,sp,16
  return fork();
    800034dc:	fffff097          	auipc	ra,0xfffff
    800034e0:	e64080e7          	jalr	-412(ra) # 80002340 <fork>
}
    800034e4:	60a2                	ld	ra,8(sp)
    800034e6:	6402                	ld	s0,0(sp)
    800034e8:	0141                	addi	sp,sp,16
    800034ea:	8082                	ret

00000000800034ec <sys_wait>:

uint64
sys_wait(void)
{
    800034ec:	1101                	addi	sp,sp,-32
    800034ee:	ec06                	sd	ra,24(sp)
    800034f0:	e822                	sd	s0,16(sp)
    800034f2:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800034f4:	fe840593          	addi	a1,s0,-24
    800034f8:	4501                	li	a0,0
    800034fa:	00000097          	auipc	ra,0x0
    800034fe:	e84080e7          	jalr	-380(ra) # 8000337e <argaddr>
    80003502:	87aa                	mv	a5,a0
    return -1;
    80003504:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003506:	0007c863          	bltz	a5,80003516 <sys_wait+0x2a>
  return wait(p);
    8000350a:	fe843503          	ld	a0,-24(s0)
    8000350e:	fffff097          	auipc	ra,0xfffff
    80003512:	27a080e7          	jalr	634(ra) # 80002788 <wait>
}
    80003516:	60e2                	ld	ra,24(sp)
    80003518:	6442                	ld	s0,16(sp)
    8000351a:	6105                	addi	sp,sp,32
    8000351c:	8082                	ret

000000008000351e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000351e:	7179                	addi	sp,sp,-48
    80003520:	f406                	sd	ra,40(sp)
    80003522:	f022                	sd	s0,32(sp)
    80003524:	ec26                	sd	s1,24(sp)
    80003526:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003528:	fdc40593          	addi	a1,s0,-36
    8000352c:	4501                	li	a0,0
    8000352e:	00000097          	auipc	ra,0x0
    80003532:	e2e080e7          	jalr	-466(ra) # 8000335c <argint>
    80003536:	87aa                	mv	a5,a0
    return -1;
    80003538:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000353a:	0207c063          	bltz	a5,8000355a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000353e:	fffff097          	auipc	ra,0xfffff
    80003542:	91e080e7          	jalr	-1762(ra) # 80001e5c <myproc>
    80003546:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    80003548:	fdc42503          	lw	a0,-36(s0)
    8000354c:	fffff097          	auipc	ra,0xfffff
    80003550:	cf8080e7          	jalr	-776(ra) # 80002244 <growproc>
    80003554:	00054863          	bltz	a0,80003564 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003558:	8526                	mv	a0,s1
}
    8000355a:	70a2                	ld	ra,40(sp)
    8000355c:	7402                	ld	s0,32(sp)
    8000355e:	64e2                	ld	s1,24(sp)
    80003560:	6145                	addi	sp,sp,48
    80003562:	8082                	ret
    return -1;
    80003564:	557d                	li	a0,-1
    80003566:	bfd5                	j	8000355a <sys_sbrk+0x3c>

0000000080003568 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003568:	7139                	addi	sp,sp,-64
    8000356a:	fc06                	sd	ra,56(sp)
    8000356c:	f822                	sd	s0,48(sp)
    8000356e:	f426                	sd	s1,40(sp)
    80003570:	f04a                	sd	s2,32(sp)
    80003572:	ec4e                	sd	s3,24(sp)
    80003574:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003576:	fcc40593          	addi	a1,s0,-52
    8000357a:	4501                	li	a0,0
    8000357c:	00000097          	auipc	ra,0x0
    80003580:	de0080e7          	jalr	-544(ra) # 8000335c <argint>
    return -1;
    80003584:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003586:	06054563          	bltz	a0,800035f0 <sys_sleep+0x88>
  acquire(&tickslock);
    8000358a:	00014517          	auipc	a0,0x14
    8000358e:	50e50513          	addi	a0,a0,1294 # 80017a98 <tickslock>
    80003592:	ffffd097          	auipc	ra,0xffffd
    80003596:	65a080e7          	jalr	1626(ra) # 80000bec <acquire>
  ticks0 = ticks;
    8000359a:	00006917          	auipc	s2,0x6
    8000359e:	a9692903          	lw	s2,-1386(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800035a2:	fcc42783          	lw	a5,-52(s0)
    800035a6:	cf85                	beqz	a5,800035de <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800035a8:	00014997          	auipc	s3,0x14
    800035ac:	4f098993          	addi	s3,s3,1264 # 80017a98 <tickslock>
    800035b0:	00006497          	auipc	s1,0x6
    800035b4:	a8048493          	addi	s1,s1,-1408 # 80009030 <ticks>
    if(myproc()->killed){
    800035b8:	fffff097          	auipc	ra,0xfffff
    800035bc:	8a4080e7          	jalr	-1884(ra) # 80001e5c <myproc>
    800035c0:	551c                	lw	a5,40(a0)
    800035c2:	ef9d                	bnez	a5,80003600 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800035c4:	85ce                	mv	a1,s3
    800035c6:	8526                	mv	a0,s1
    800035c8:	fffff097          	auipc	ra,0xfffff
    800035cc:	142080e7          	jalr	322(ra) # 8000270a <sleep>
  while(ticks - ticks0 < n){
    800035d0:	409c                	lw	a5,0(s1)
    800035d2:	412787bb          	subw	a5,a5,s2
    800035d6:	fcc42703          	lw	a4,-52(s0)
    800035da:	fce7efe3          	bltu	a5,a4,800035b8 <sys_sleep+0x50>
  }
  release(&tickslock);
    800035de:	00014517          	auipc	a0,0x14
    800035e2:	4ba50513          	addi	a0,a0,1210 # 80017a98 <tickslock>
    800035e6:	ffffd097          	auipc	ra,0xffffd
    800035ea:	6d2080e7          	jalr	1746(ra) # 80000cb8 <release>
  return 0;
    800035ee:	4781                	li	a5,0
}
    800035f0:	853e                	mv	a0,a5
    800035f2:	70e2                	ld	ra,56(sp)
    800035f4:	7442                	ld	s0,48(sp)
    800035f6:	74a2                	ld	s1,40(sp)
    800035f8:	7902                	ld	s2,32(sp)
    800035fa:	69e2                	ld	s3,24(sp)
    800035fc:	6121                	addi	sp,sp,64
    800035fe:	8082                	ret
      release(&tickslock);
    80003600:	00014517          	auipc	a0,0x14
    80003604:	49850513          	addi	a0,a0,1176 # 80017a98 <tickslock>
    80003608:	ffffd097          	auipc	ra,0xffffd
    8000360c:	6b0080e7          	jalr	1712(ra) # 80000cb8 <release>
      return -1;
    80003610:	57fd                	li	a5,-1
    80003612:	bff9                	j	800035f0 <sys_sleep+0x88>

0000000080003614 <sys_kill>:

uint64
sys_kill(void)
{
    80003614:	1101                	addi	sp,sp,-32
    80003616:	ec06                	sd	ra,24(sp)
    80003618:	e822                	sd	s0,16(sp)
    8000361a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000361c:	fec40593          	addi	a1,s0,-20
    80003620:	4501                	li	a0,0
    80003622:	00000097          	auipc	ra,0x0
    80003626:	d3a080e7          	jalr	-710(ra) # 8000335c <argint>
    8000362a:	87aa                	mv	a5,a0
    return -1;
    8000362c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000362e:	0007c863          	bltz	a5,8000363e <sys_kill+0x2a>
  return kill(pid);
    80003632:	fec42503          	lw	a0,-20(s0)
    80003636:	fffff097          	auipc	ra,0xfffff
    8000363a:	584080e7          	jalr	1412(ra) # 80002bba <kill>
}
    8000363e:	60e2                	ld	ra,24(sp)
    80003640:	6442                	ld	s0,16(sp)
    80003642:	6105                	addi	sp,sp,32
    80003644:	8082                	ret

0000000080003646 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003646:	1101                	addi	sp,sp,-32
    80003648:	ec06                	sd	ra,24(sp)
    8000364a:	e822                	sd	s0,16(sp)
    8000364c:	e426                	sd	s1,8(sp)
    8000364e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003650:	00014517          	auipc	a0,0x14
    80003654:	44850513          	addi	a0,a0,1096 # 80017a98 <tickslock>
    80003658:	ffffd097          	auipc	ra,0xffffd
    8000365c:	594080e7          	jalr	1428(ra) # 80000bec <acquire>
  xticks = ticks;
    80003660:	00006497          	auipc	s1,0x6
    80003664:	9d04a483          	lw	s1,-1584(s1) # 80009030 <ticks>
  release(&tickslock);
    80003668:	00014517          	auipc	a0,0x14
    8000366c:	43050513          	addi	a0,a0,1072 # 80017a98 <tickslock>
    80003670:	ffffd097          	auipc	ra,0xffffd
    80003674:	648080e7          	jalr	1608(ra) # 80000cb8 <release>
  return xticks;
}
    80003678:	02049513          	slli	a0,s1,0x20
    8000367c:	9101                	srli	a0,a0,0x20
    8000367e:	60e2                	ld	ra,24(sp)
    80003680:	6442                	ld	s0,16(sp)
    80003682:	64a2                	ld	s1,8(sp)
    80003684:	6105                	addi	sp,sp,32
    80003686:	8082                	ret

0000000080003688 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003688:	7179                	addi	sp,sp,-48
    8000368a:	f406                	sd	ra,40(sp)
    8000368c:	f022                	sd	s0,32(sp)
    8000368e:	ec26                	sd	s1,24(sp)
    80003690:	e84a                	sd	s2,16(sp)
    80003692:	e44e                	sd	s3,8(sp)
    80003694:	e052                	sd	s4,0(sp)
    80003696:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003698:	00005597          	auipc	a1,0x5
    8000369c:	ea058593          	addi	a1,a1,-352 # 80008538 <syscalls+0xc0>
    800036a0:	00014517          	auipc	a0,0x14
    800036a4:	41050513          	addi	a0,a0,1040 # 80017ab0 <bcache>
    800036a8:	ffffd097          	auipc	ra,0xffffd
    800036ac:	4ac080e7          	jalr	1196(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800036b0:	0001c797          	auipc	a5,0x1c
    800036b4:	40078793          	addi	a5,a5,1024 # 8001fab0 <bcache+0x8000>
    800036b8:	0001c717          	auipc	a4,0x1c
    800036bc:	66070713          	addi	a4,a4,1632 # 8001fd18 <bcache+0x8268>
    800036c0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800036c4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036c8:	00014497          	auipc	s1,0x14
    800036cc:	40048493          	addi	s1,s1,1024 # 80017ac8 <bcache+0x18>
    b->next = bcache.head.next;
    800036d0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800036d2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800036d4:	00005a17          	auipc	s4,0x5
    800036d8:	e6ca0a13          	addi	s4,s4,-404 # 80008540 <syscalls+0xc8>
    b->next = bcache.head.next;
    800036dc:	2b893783          	ld	a5,696(s2)
    800036e0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800036e2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800036e6:	85d2                	mv	a1,s4
    800036e8:	01048513          	addi	a0,s1,16
    800036ec:	00001097          	auipc	ra,0x1
    800036f0:	4bc080e7          	jalr	1212(ra) # 80004ba8 <initsleeplock>
    bcache.head.next->prev = b;
    800036f4:	2b893783          	ld	a5,696(s2)
    800036f8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800036fa:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036fe:	45848493          	addi	s1,s1,1112
    80003702:	fd349de3          	bne	s1,s3,800036dc <binit+0x54>
  }
}
    80003706:	70a2                	ld	ra,40(sp)
    80003708:	7402                	ld	s0,32(sp)
    8000370a:	64e2                	ld	s1,24(sp)
    8000370c:	6942                	ld	s2,16(sp)
    8000370e:	69a2                	ld	s3,8(sp)
    80003710:	6a02                	ld	s4,0(sp)
    80003712:	6145                	addi	sp,sp,48
    80003714:	8082                	ret

0000000080003716 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003716:	7179                	addi	sp,sp,-48
    80003718:	f406                	sd	ra,40(sp)
    8000371a:	f022                	sd	s0,32(sp)
    8000371c:	ec26                	sd	s1,24(sp)
    8000371e:	e84a                	sd	s2,16(sp)
    80003720:	e44e                	sd	s3,8(sp)
    80003722:	1800                	addi	s0,sp,48
    80003724:	89aa                	mv	s3,a0
    80003726:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003728:	00014517          	auipc	a0,0x14
    8000372c:	38850513          	addi	a0,a0,904 # 80017ab0 <bcache>
    80003730:	ffffd097          	auipc	ra,0xffffd
    80003734:	4bc080e7          	jalr	1212(ra) # 80000bec <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003738:	0001c497          	auipc	s1,0x1c
    8000373c:	6304b483          	ld	s1,1584(s1) # 8001fd68 <bcache+0x82b8>
    80003740:	0001c797          	auipc	a5,0x1c
    80003744:	5d878793          	addi	a5,a5,1496 # 8001fd18 <bcache+0x8268>
    80003748:	02f48f63          	beq	s1,a5,80003786 <bread+0x70>
    8000374c:	873e                	mv	a4,a5
    8000374e:	a021                	j	80003756 <bread+0x40>
    80003750:	68a4                	ld	s1,80(s1)
    80003752:	02e48a63          	beq	s1,a4,80003786 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003756:	449c                	lw	a5,8(s1)
    80003758:	ff379ce3          	bne	a5,s3,80003750 <bread+0x3a>
    8000375c:	44dc                	lw	a5,12(s1)
    8000375e:	ff2799e3          	bne	a5,s2,80003750 <bread+0x3a>
      b->refcnt++;
    80003762:	40bc                	lw	a5,64(s1)
    80003764:	2785                	addiw	a5,a5,1
    80003766:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003768:	00014517          	auipc	a0,0x14
    8000376c:	34850513          	addi	a0,a0,840 # 80017ab0 <bcache>
    80003770:	ffffd097          	auipc	ra,0xffffd
    80003774:	548080e7          	jalr	1352(ra) # 80000cb8 <release>
      acquiresleep(&b->lock);
    80003778:	01048513          	addi	a0,s1,16
    8000377c:	00001097          	auipc	ra,0x1
    80003780:	466080e7          	jalr	1126(ra) # 80004be2 <acquiresleep>
      return b;
    80003784:	a8b9                	j	800037e2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003786:	0001c497          	auipc	s1,0x1c
    8000378a:	5da4b483          	ld	s1,1498(s1) # 8001fd60 <bcache+0x82b0>
    8000378e:	0001c797          	auipc	a5,0x1c
    80003792:	58a78793          	addi	a5,a5,1418 # 8001fd18 <bcache+0x8268>
    80003796:	00f48863          	beq	s1,a5,800037a6 <bread+0x90>
    8000379a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000379c:	40bc                	lw	a5,64(s1)
    8000379e:	cf81                	beqz	a5,800037b6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800037a0:	64a4                	ld	s1,72(s1)
    800037a2:	fee49de3          	bne	s1,a4,8000379c <bread+0x86>
  panic("bget: no buffers");
    800037a6:	00005517          	auipc	a0,0x5
    800037aa:	da250513          	addi	a0,a0,-606 # 80008548 <syscalls+0xd0>
    800037ae:	ffffd097          	auipc	ra,0xffffd
    800037b2:	d90080e7          	jalr	-624(ra) # 8000053e <panic>
      b->dev = dev;
    800037b6:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800037ba:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800037be:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800037c2:	4785                	li	a5,1
    800037c4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800037c6:	00014517          	auipc	a0,0x14
    800037ca:	2ea50513          	addi	a0,a0,746 # 80017ab0 <bcache>
    800037ce:	ffffd097          	auipc	ra,0xffffd
    800037d2:	4ea080e7          	jalr	1258(ra) # 80000cb8 <release>
      acquiresleep(&b->lock);
    800037d6:	01048513          	addi	a0,s1,16
    800037da:	00001097          	auipc	ra,0x1
    800037de:	408080e7          	jalr	1032(ra) # 80004be2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800037e2:	409c                	lw	a5,0(s1)
    800037e4:	cb89                	beqz	a5,800037f6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800037e6:	8526                	mv	a0,s1
    800037e8:	70a2                	ld	ra,40(sp)
    800037ea:	7402                	ld	s0,32(sp)
    800037ec:	64e2                	ld	s1,24(sp)
    800037ee:	6942                	ld	s2,16(sp)
    800037f0:	69a2                	ld	s3,8(sp)
    800037f2:	6145                	addi	sp,sp,48
    800037f4:	8082                	ret
    virtio_disk_rw(b, 0);
    800037f6:	4581                	li	a1,0
    800037f8:	8526                	mv	a0,s1
    800037fa:	00003097          	auipc	ra,0x3
    800037fe:	f0c080e7          	jalr	-244(ra) # 80006706 <virtio_disk_rw>
    b->valid = 1;
    80003802:	4785                	li	a5,1
    80003804:	c09c                	sw	a5,0(s1)
  return b;
    80003806:	b7c5                	j	800037e6 <bread+0xd0>

0000000080003808 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003808:	1101                	addi	sp,sp,-32
    8000380a:	ec06                	sd	ra,24(sp)
    8000380c:	e822                	sd	s0,16(sp)
    8000380e:	e426                	sd	s1,8(sp)
    80003810:	1000                	addi	s0,sp,32
    80003812:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003814:	0541                	addi	a0,a0,16
    80003816:	00001097          	auipc	ra,0x1
    8000381a:	466080e7          	jalr	1126(ra) # 80004c7c <holdingsleep>
    8000381e:	cd01                	beqz	a0,80003836 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003820:	4585                	li	a1,1
    80003822:	8526                	mv	a0,s1
    80003824:	00003097          	auipc	ra,0x3
    80003828:	ee2080e7          	jalr	-286(ra) # 80006706 <virtio_disk_rw>
}
    8000382c:	60e2                	ld	ra,24(sp)
    8000382e:	6442                	ld	s0,16(sp)
    80003830:	64a2                	ld	s1,8(sp)
    80003832:	6105                	addi	sp,sp,32
    80003834:	8082                	ret
    panic("bwrite");
    80003836:	00005517          	auipc	a0,0x5
    8000383a:	d2a50513          	addi	a0,a0,-726 # 80008560 <syscalls+0xe8>
    8000383e:	ffffd097          	auipc	ra,0xffffd
    80003842:	d00080e7          	jalr	-768(ra) # 8000053e <panic>

0000000080003846 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003846:	1101                	addi	sp,sp,-32
    80003848:	ec06                	sd	ra,24(sp)
    8000384a:	e822                	sd	s0,16(sp)
    8000384c:	e426                	sd	s1,8(sp)
    8000384e:	e04a                	sd	s2,0(sp)
    80003850:	1000                	addi	s0,sp,32
    80003852:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003854:	01050913          	addi	s2,a0,16
    80003858:	854a                	mv	a0,s2
    8000385a:	00001097          	auipc	ra,0x1
    8000385e:	422080e7          	jalr	1058(ra) # 80004c7c <holdingsleep>
    80003862:	c92d                	beqz	a0,800038d4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003864:	854a                	mv	a0,s2
    80003866:	00001097          	auipc	ra,0x1
    8000386a:	3d2080e7          	jalr	978(ra) # 80004c38 <releasesleep>

  acquire(&bcache.lock);
    8000386e:	00014517          	auipc	a0,0x14
    80003872:	24250513          	addi	a0,a0,578 # 80017ab0 <bcache>
    80003876:	ffffd097          	auipc	ra,0xffffd
    8000387a:	376080e7          	jalr	886(ra) # 80000bec <acquire>
  b->refcnt--;
    8000387e:	40bc                	lw	a5,64(s1)
    80003880:	37fd                	addiw	a5,a5,-1
    80003882:	0007871b          	sext.w	a4,a5
    80003886:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003888:	eb05                	bnez	a4,800038b8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000388a:	68bc                	ld	a5,80(s1)
    8000388c:	64b8                	ld	a4,72(s1)
    8000388e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003890:	64bc                	ld	a5,72(s1)
    80003892:	68b8                	ld	a4,80(s1)
    80003894:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003896:	0001c797          	auipc	a5,0x1c
    8000389a:	21a78793          	addi	a5,a5,538 # 8001fab0 <bcache+0x8000>
    8000389e:	2b87b703          	ld	a4,696(a5)
    800038a2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800038a4:	0001c717          	auipc	a4,0x1c
    800038a8:	47470713          	addi	a4,a4,1140 # 8001fd18 <bcache+0x8268>
    800038ac:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800038ae:	2b87b703          	ld	a4,696(a5)
    800038b2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800038b4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800038b8:	00014517          	auipc	a0,0x14
    800038bc:	1f850513          	addi	a0,a0,504 # 80017ab0 <bcache>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	3f8080e7          	jalr	1016(ra) # 80000cb8 <release>
}
    800038c8:	60e2                	ld	ra,24(sp)
    800038ca:	6442                	ld	s0,16(sp)
    800038cc:	64a2                	ld	s1,8(sp)
    800038ce:	6902                	ld	s2,0(sp)
    800038d0:	6105                	addi	sp,sp,32
    800038d2:	8082                	ret
    panic("brelse");
    800038d4:	00005517          	auipc	a0,0x5
    800038d8:	c9450513          	addi	a0,a0,-876 # 80008568 <syscalls+0xf0>
    800038dc:	ffffd097          	auipc	ra,0xffffd
    800038e0:	c62080e7          	jalr	-926(ra) # 8000053e <panic>

00000000800038e4 <bpin>:

void
bpin(struct buf *b) {
    800038e4:	1101                	addi	sp,sp,-32
    800038e6:	ec06                	sd	ra,24(sp)
    800038e8:	e822                	sd	s0,16(sp)
    800038ea:	e426                	sd	s1,8(sp)
    800038ec:	1000                	addi	s0,sp,32
    800038ee:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038f0:	00014517          	auipc	a0,0x14
    800038f4:	1c050513          	addi	a0,a0,448 # 80017ab0 <bcache>
    800038f8:	ffffd097          	auipc	ra,0xffffd
    800038fc:	2f4080e7          	jalr	756(ra) # 80000bec <acquire>
  b->refcnt++;
    80003900:	40bc                	lw	a5,64(s1)
    80003902:	2785                	addiw	a5,a5,1
    80003904:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003906:	00014517          	auipc	a0,0x14
    8000390a:	1aa50513          	addi	a0,a0,426 # 80017ab0 <bcache>
    8000390e:	ffffd097          	auipc	ra,0xffffd
    80003912:	3aa080e7          	jalr	938(ra) # 80000cb8 <release>
}
    80003916:	60e2                	ld	ra,24(sp)
    80003918:	6442                	ld	s0,16(sp)
    8000391a:	64a2                	ld	s1,8(sp)
    8000391c:	6105                	addi	sp,sp,32
    8000391e:	8082                	ret

0000000080003920 <bunpin>:

void
bunpin(struct buf *b) {
    80003920:	1101                	addi	sp,sp,-32
    80003922:	ec06                	sd	ra,24(sp)
    80003924:	e822                	sd	s0,16(sp)
    80003926:	e426                	sd	s1,8(sp)
    80003928:	1000                	addi	s0,sp,32
    8000392a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000392c:	00014517          	auipc	a0,0x14
    80003930:	18450513          	addi	a0,a0,388 # 80017ab0 <bcache>
    80003934:	ffffd097          	auipc	ra,0xffffd
    80003938:	2b8080e7          	jalr	696(ra) # 80000bec <acquire>
  b->refcnt--;
    8000393c:	40bc                	lw	a5,64(s1)
    8000393e:	37fd                	addiw	a5,a5,-1
    80003940:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003942:	00014517          	auipc	a0,0x14
    80003946:	16e50513          	addi	a0,a0,366 # 80017ab0 <bcache>
    8000394a:	ffffd097          	auipc	ra,0xffffd
    8000394e:	36e080e7          	jalr	878(ra) # 80000cb8 <release>
}
    80003952:	60e2                	ld	ra,24(sp)
    80003954:	6442                	ld	s0,16(sp)
    80003956:	64a2                	ld	s1,8(sp)
    80003958:	6105                	addi	sp,sp,32
    8000395a:	8082                	ret

000000008000395c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000395c:	1101                	addi	sp,sp,-32
    8000395e:	ec06                	sd	ra,24(sp)
    80003960:	e822                	sd	s0,16(sp)
    80003962:	e426                	sd	s1,8(sp)
    80003964:	e04a                	sd	s2,0(sp)
    80003966:	1000                	addi	s0,sp,32
    80003968:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000396a:	00d5d59b          	srliw	a1,a1,0xd
    8000396e:	0001d797          	auipc	a5,0x1d
    80003972:	81e7a783          	lw	a5,-2018(a5) # 8002018c <sb+0x1c>
    80003976:	9dbd                	addw	a1,a1,a5
    80003978:	00000097          	auipc	ra,0x0
    8000397c:	d9e080e7          	jalr	-610(ra) # 80003716 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003980:	0074f713          	andi	a4,s1,7
    80003984:	4785                	li	a5,1
    80003986:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000398a:	14ce                	slli	s1,s1,0x33
    8000398c:	90d9                	srli	s1,s1,0x36
    8000398e:	00950733          	add	a4,a0,s1
    80003992:	05874703          	lbu	a4,88(a4)
    80003996:	00e7f6b3          	and	a3,a5,a4
    8000399a:	c69d                	beqz	a3,800039c8 <bfree+0x6c>
    8000399c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000399e:	94aa                	add	s1,s1,a0
    800039a0:	fff7c793          	not	a5,a5
    800039a4:	8ff9                	and	a5,a5,a4
    800039a6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800039aa:	00001097          	auipc	ra,0x1
    800039ae:	118080e7          	jalr	280(ra) # 80004ac2 <log_write>
  brelse(bp);
    800039b2:	854a                	mv	a0,s2
    800039b4:	00000097          	auipc	ra,0x0
    800039b8:	e92080e7          	jalr	-366(ra) # 80003846 <brelse>
}
    800039bc:	60e2                	ld	ra,24(sp)
    800039be:	6442                	ld	s0,16(sp)
    800039c0:	64a2                	ld	s1,8(sp)
    800039c2:	6902                	ld	s2,0(sp)
    800039c4:	6105                	addi	sp,sp,32
    800039c6:	8082                	ret
    panic("freeing free block");
    800039c8:	00005517          	auipc	a0,0x5
    800039cc:	ba850513          	addi	a0,a0,-1112 # 80008570 <syscalls+0xf8>
    800039d0:	ffffd097          	auipc	ra,0xffffd
    800039d4:	b6e080e7          	jalr	-1170(ra) # 8000053e <panic>

00000000800039d8 <balloc>:
{
    800039d8:	711d                	addi	sp,sp,-96
    800039da:	ec86                	sd	ra,88(sp)
    800039dc:	e8a2                	sd	s0,80(sp)
    800039de:	e4a6                	sd	s1,72(sp)
    800039e0:	e0ca                	sd	s2,64(sp)
    800039e2:	fc4e                	sd	s3,56(sp)
    800039e4:	f852                	sd	s4,48(sp)
    800039e6:	f456                	sd	s5,40(sp)
    800039e8:	f05a                	sd	s6,32(sp)
    800039ea:	ec5e                	sd	s7,24(sp)
    800039ec:	e862                	sd	s8,16(sp)
    800039ee:	e466                	sd	s9,8(sp)
    800039f0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800039f2:	0001c797          	auipc	a5,0x1c
    800039f6:	7827a783          	lw	a5,1922(a5) # 80020174 <sb+0x4>
    800039fa:	cbd1                	beqz	a5,80003a8e <balloc+0xb6>
    800039fc:	8baa                	mv	s7,a0
    800039fe:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003a00:	0001cb17          	auipc	s6,0x1c
    80003a04:	770b0b13          	addi	s6,s6,1904 # 80020170 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a08:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003a0a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a0c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003a0e:	6c89                	lui	s9,0x2
    80003a10:	a831                	j	80003a2c <balloc+0x54>
    brelse(bp);
    80003a12:	854a                	mv	a0,s2
    80003a14:	00000097          	auipc	ra,0x0
    80003a18:	e32080e7          	jalr	-462(ra) # 80003846 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003a1c:	015c87bb          	addw	a5,s9,s5
    80003a20:	00078a9b          	sext.w	s5,a5
    80003a24:	004b2703          	lw	a4,4(s6)
    80003a28:	06eaf363          	bgeu	s5,a4,80003a8e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003a2c:	41fad79b          	sraiw	a5,s5,0x1f
    80003a30:	0137d79b          	srliw	a5,a5,0x13
    80003a34:	015787bb          	addw	a5,a5,s5
    80003a38:	40d7d79b          	sraiw	a5,a5,0xd
    80003a3c:	01cb2583          	lw	a1,28(s6)
    80003a40:	9dbd                	addw	a1,a1,a5
    80003a42:	855e                	mv	a0,s7
    80003a44:	00000097          	auipc	ra,0x0
    80003a48:	cd2080e7          	jalr	-814(ra) # 80003716 <bread>
    80003a4c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a4e:	004b2503          	lw	a0,4(s6)
    80003a52:	000a849b          	sext.w	s1,s5
    80003a56:	8662                	mv	a2,s8
    80003a58:	faa4fde3          	bgeu	s1,a0,80003a12 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003a5c:	41f6579b          	sraiw	a5,a2,0x1f
    80003a60:	01d7d69b          	srliw	a3,a5,0x1d
    80003a64:	00c6873b          	addw	a4,a3,a2
    80003a68:	00777793          	andi	a5,a4,7
    80003a6c:	9f95                	subw	a5,a5,a3
    80003a6e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a72:	4037571b          	sraiw	a4,a4,0x3
    80003a76:	00e906b3          	add	a3,s2,a4
    80003a7a:	0586c683          	lbu	a3,88(a3)
    80003a7e:	00d7f5b3          	and	a1,a5,a3
    80003a82:	cd91                	beqz	a1,80003a9e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a84:	2605                	addiw	a2,a2,1
    80003a86:	2485                	addiw	s1,s1,1
    80003a88:	fd4618e3          	bne	a2,s4,80003a58 <balloc+0x80>
    80003a8c:	b759                	j	80003a12 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003a8e:	00005517          	auipc	a0,0x5
    80003a92:	afa50513          	addi	a0,a0,-1286 # 80008588 <syscalls+0x110>
    80003a96:	ffffd097          	auipc	ra,0xffffd
    80003a9a:	aa8080e7          	jalr	-1368(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003a9e:	974a                	add	a4,a4,s2
    80003aa0:	8fd5                	or	a5,a5,a3
    80003aa2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003aa6:	854a                	mv	a0,s2
    80003aa8:	00001097          	auipc	ra,0x1
    80003aac:	01a080e7          	jalr	26(ra) # 80004ac2 <log_write>
        brelse(bp);
    80003ab0:	854a                	mv	a0,s2
    80003ab2:	00000097          	auipc	ra,0x0
    80003ab6:	d94080e7          	jalr	-620(ra) # 80003846 <brelse>
  bp = bread(dev, bno);
    80003aba:	85a6                	mv	a1,s1
    80003abc:	855e                	mv	a0,s7
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	c58080e7          	jalr	-936(ra) # 80003716 <bread>
    80003ac6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003ac8:	40000613          	li	a2,1024
    80003acc:	4581                	li	a1,0
    80003ace:	05850513          	addi	a0,a0,88
    80003ad2:	ffffd097          	auipc	ra,0xffffd
    80003ad6:	240080e7          	jalr	576(ra) # 80000d12 <memset>
  log_write(bp);
    80003ada:	854a                	mv	a0,s2
    80003adc:	00001097          	auipc	ra,0x1
    80003ae0:	fe6080e7          	jalr	-26(ra) # 80004ac2 <log_write>
  brelse(bp);
    80003ae4:	854a                	mv	a0,s2
    80003ae6:	00000097          	auipc	ra,0x0
    80003aea:	d60080e7          	jalr	-672(ra) # 80003846 <brelse>
}
    80003aee:	8526                	mv	a0,s1
    80003af0:	60e6                	ld	ra,88(sp)
    80003af2:	6446                	ld	s0,80(sp)
    80003af4:	64a6                	ld	s1,72(sp)
    80003af6:	6906                	ld	s2,64(sp)
    80003af8:	79e2                	ld	s3,56(sp)
    80003afa:	7a42                	ld	s4,48(sp)
    80003afc:	7aa2                	ld	s5,40(sp)
    80003afe:	7b02                	ld	s6,32(sp)
    80003b00:	6be2                	ld	s7,24(sp)
    80003b02:	6c42                	ld	s8,16(sp)
    80003b04:	6ca2                	ld	s9,8(sp)
    80003b06:	6125                	addi	sp,sp,96
    80003b08:	8082                	ret

0000000080003b0a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003b0a:	7179                	addi	sp,sp,-48
    80003b0c:	f406                	sd	ra,40(sp)
    80003b0e:	f022                	sd	s0,32(sp)
    80003b10:	ec26                	sd	s1,24(sp)
    80003b12:	e84a                	sd	s2,16(sp)
    80003b14:	e44e                	sd	s3,8(sp)
    80003b16:	e052                	sd	s4,0(sp)
    80003b18:	1800                	addi	s0,sp,48
    80003b1a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003b1c:	47ad                	li	a5,11
    80003b1e:	04b7fe63          	bgeu	a5,a1,80003b7a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003b22:	ff45849b          	addiw	s1,a1,-12
    80003b26:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003b2a:	0ff00793          	li	a5,255
    80003b2e:	0ae7e363          	bltu	a5,a4,80003bd4 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003b32:	08052583          	lw	a1,128(a0)
    80003b36:	c5ad                	beqz	a1,80003ba0 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003b38:	00092503          	lw	a0,0(s2)
    80003b3c:	00000097          	auipc	ra,0x0
    80003b40:	bda080e7          	jalr	-1062(ra) # 80003716 <bread>
    80003b44:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003b46:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003b4a:	02049593          	slli	a1,s1,0x20
    80003b4e:	9181                	srli	a1,a1,0x20
    80003b50:	058a                	slli	a1,a1,0x2
    80003b52:	00b784b3          	add	s1,a5,a1
    80003b56:	0004a983          	lw	s3,0(s1)
    80003b5a:	04098d63          	beqz	s3,80003bb4 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003b5e:	8552                	mv	a0,s4
    80003b60:	00000097          	auipc	ra,0x0
    80003b64:	ce6080e7          	jalr	-794(ra) # 80003846 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003b68:	854e                	mv	a0,s3
    80003b6a:	70a2                	ld	ra,40(sp)
    80003b6c:	7402                	ld	s0,32(sp)
    80003b6e:	64e2                	ld	s1,24(sp)
    80003b70:	6942                	ld	s2,16(sp)
    80003b72:	69a2                	ld	s3,8(sp)
    80003b74:	6a02                	ld	s4,0(sp)
    80003b76:	6145                	addi	sp,sp,48
    80003b78:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003b7a:	02059493          	slli	s1,a1,0x20
    80003b7e:	9081                	srli	s1,s1,0x20
    80003b80:	048a                	slli	s1,s1,0x2
    80003b82:	94aa                	add	s1,s1,a0
    80003b84:	0504a983          	lw	s3,80(s1)
    80003b88:	fe0990e3          	bnez	s3,80003b68 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003b8c:	4108                	lw	a0,0(a0)
    80003b8e:	00000097          	auipc	ra,0x0
    80003b92:	e4a080e7          	jalr	-438(ra) # 800039d8 <balloc>
    80003b96:	0005099b          	sext.w	s3,a0
    80003b9a:	0534a823          	sw	s3,80(s1)
    80003b9e:	b7e9                	j	80003b68 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003ba0:	4108                	lw	a0,0(a0)
    80003ba2:	00000097          	auipc	ra,0x0
    80003ba6:	e36080e7          	jalr	-458(ra) # 800039d8 <balloc>
    80003baa:	0005059b          	sext.w	a1,a0
    80003bae:	08b92023          	sw	a1,128(s2)
    80003bb2:	b759                	j	80003b38 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003bb4:	00092503          	lw	a0,0(s2)
    80003bb8:	00000097          	auipc	ra,0x0
    80003bbc:	e20080e7          	jalr	-480(ra) # 800039d8 <balloc>
    80003bc0:	0005099b          	sext.w	s3,a0
    80003bc4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003bc8:	8552                	mv	a0,s4
    80003bca:	00001097          	auipc	ra,0x1
    80003bce:	ef8080e7          	jalr	-264(ra) # 80004ac2 <log_write>
    80003bd2:	b771                	j	80003b5e <bmap+0x54>
  panic("bmap: out of range");
    80003bd4:	00005517          	auipc	a0,0x5
    80003bd8:	9cc50513          	addi	a0,a0,-1588 # 800085a0 <syscalls+0x128>
    80003bdc:	ffffd097          	auipc	ra,0xffffd
    80003be0:	962080e7          	jalr	-1694(ra) # 8000053e <panic>

0000000080003be4 <iget>:
{
    80003be4:	7179                	addi	sp,sp,-48
    80003be6:	f406                	sd	ra,40(sp)
    80003be8:	f022                	sd	s0,32(sp)
    80003bea:	ec26                	sd	s1,24(sp)
    80003bec:	e84a                	sd	s2,16(sp)
    80003bee:	e44e                	sd	s3,8(sp)
    80003bf0:	e052                	sd	s4,0(sp)
    80003bf2:	1800                	addi	s0,sp,48
    80003bf4:	89aa                	mv	s3,a0
    80003bf6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003bf8:	0001c517          	auipc	a0,0x1c
    80003bfc:	59850513          	addi	a0,a0,1432 # 80020190 <itable>
    80003c00:	ffffd097          	auipc	ra,0xffffd
    80003c04:	fec080e7          	jalr	-20(ra) # 80000bec <acquire>
  empty = 0;
    80003c08:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c0a:	0001c497          	auipc	s1,0x1c
    80003c0e:	59e48493          	addi	s1,s1,1438 # 800201a8 <itable+0x18>
    80003c12:	0001e697          	auipc	a3,0x1e
    80003c16:	02668693          	addi	a3,a3,38 # 80021c38 <log>
    80003c1a:	a039                	j	80003c28 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c1c:	02090b63          	beqz	s2,80003c52 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c20:	08848493          	addi	s1,s1,136
    80003c24:	02d48a63          	beq	s1,a3,80003c58 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003c28:	449c                	lw	a5,8(s1)
    80003c2a:	fef059e3          	blez	a5,80003c1c <iget+0x38>
    80003c2e:	4098                	lw	a4,0(s1)
    80003c30:	ff3716e3          	bne	a4,s3,80003c1c <iget+0x38>
    80003c34:	40d8                	lw	a4,4(s1)
    80003c36:	ff4713e3          	bne	a4,s4,80003c1c <iget+0x38>
      ip->ref++;
    80003c3a:	2785                	addiw	a5,a5,1
    80003c3c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003c3e:	0001c517          	auipc	a0,0x1c
    80003c42:	55250513          	addi	a0,a0,1362 # 80020190 <itable>
    80003c46:	ffffd097          	auipc	ra,0xffffd
    80003c4a:	072080e7          	jalr	114(ra) # 80000cb8 <release>
      return ip;
    80003c4e:	8926                	mv	s2,s1
    80003c50:	a03d                	j	80003c7e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c52:	f7f9                	bnez	a5,80003c20 <iget+0x3c>
    80003c54:	8926                	mv	s2,s1
    80003c56:	b7e9                	j	80003c20 <iget+0x3c>
  if(empty == 0)
    80003c58:	02090c63          	beqz	s2,80003c90 <iget+0xac>
  ip->dev = dev;
    80003c5c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003c60:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c64:	4785                	li	a5,1
    80003c66:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c6a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c6e:	0001c517          	auipc	a0,0x1c
    80003c72:	52250513          	addi	a0,a0,1314 # 80020190 <itable>
    80003c76:	ffffd097          	auipc	ra,0xffffd
    80003c7a:	042080e7          	jalr	66(ra) # 80000cb8 <release>
}
    80003c7e:	854a                	mv	a0,s2
    80003c80:	70a2                	ld	ra,40(sp)
    80003c82:	7402                	ld	s0,32(sp)
    80003c84:	64e2                	ld	s1,24(sp)
    80003c86:	6942                	ld	s2,16(sp)
    80003c88:	69a2                	ld	s3,8(sp)
    80003c8a:	6a02                	ld	s4,0(sp)
    80003c8c:	6145                	addi	sp,sp,48
    80003c8e:	8082                	ret
    panic("iget: no inodes");
    80003c90:	00005517          	auipc	a0,0x5
    80003c94:	92850513          	addi	a0,a0,-1752 # 800085b8 <syscalls+0x140>
    80003c98:	ffffd097          	auipc	ra,0xffffd
    80003c9c:	8a6080e7          	jalr	-1882(ra) # 8000053e <panic>

0000000080003ca0 <fsinit>:
fsinit(int dev) {
    80003ca0:	7179                	addi	sp,sp,-48
    80003ca2:	f406                	sd	ra,40(sp)
    80003ca4:	f022                	sd	s0,32(sp)
    80003ca6:	ec26                	sd	s1,24(sp)
    80003ca8:	e84a                	sd	s2,16(sp)
    80003caa:	e44e                	sd	s3,8(sp)
    80003cac:	1800                	addi	s0,sp,48
    80003cae:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003cb0:	4585                	li	a1,1
    80003cb2:	00000097          	auipc	ra,0x0
    80003cb6:	a64080e7          	jalr	-1436(ra) # 80003716 <bread>
    80003cba:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003cbc:	0001c997          	auipc	s3,0x1c
    80003cc0:	4b498993          	addi	s3,s3,1204 # 80020170 <sb>
    80003cc4:	02000613          	li	a2,32
    80003cc8:	05850593          	addi	a1,a0,88
    80003ccc:	854e                	mv	a0,s3
    80003cce:	ffffd097          	auipc	ra,0xffffd
    80003cd2:	0a4080e7          	jalr	164(ra) # 80000d72 <memmove>
  brelse(bp);
    80003cd6:	8526                	mv	a0,s1
    80003cd8:	00000097          	auipc	ra,0x0
    80003cdc:	b6e080e7          	jalr	-1170(ra) # 80003846 <brelse>
  if(sb.magic != FSMAGIC)
    80003ce0:	0009a703          	lw	a4,0(s3)
    80003ce4:	102037b7          	lui	a5,0x10203
    80003ce8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003cec:	02f71263          	bne	a4,a5,80003d10 <fsinit+0x70>
  initlog(dev, &sb);
    80003cf0:	0001c597          	auipc	a1,0x1c
    80003cf4:	48058593          	addi	a1,a1,1152 # 80020170 <sb>
    80003cf8:	854a                	mv	a0,s2
    80003cfa:	00001097          	auipc	ra,0x1
    80003cfe:	b4c080e7          	jalr	-1204(ra) # 80004846 <initlog>
}
    80003d02:	70a2                	ld	ra,40(sp)
    80003d04:	7402                	ld	s0,32(sp)
    80003d06:	64e2                	ld	s1,24(sp)
    80003d08:	6942                	ld	s2,16(sp)
    80003d0a:	69a2                	ld	s3,8(sp)
    80003d0c:	6145                	addi	sp,sp,48
    80003d0e:	8082                	ret
    panic("invalid file system");
    80003d10:	00005517          	auipc	a0,0x5
    80003d14:	8b850513          	addi	a0,a0,-1864 # 800085c8 <syscalls+0x150>
    80003d18:	ffffd097          	auipc	ra,0xffffd
    80003d1c:	826080e7          	jalr	-2010(ra) # 8000053e <panic>

0000000080003d20 <iinit>:
{
    80003d20:	7179                	addi	sp,sp,-48
    80003d22:	f406                	sd	ra,40(sp)
    80003d24:	f022                	sd	s0,32(sp)
    80003d26:	ec26                	sd	s1,24(sp)
    80003d28:	e84a                	sd	s2,16(sp)
    80003d2a:	e44e                	sd	s3,8(sp)
    80003d2c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003d2e:	00005597          	auipc	a1,0x5
    80003d32:	8b258593          	addi	a1,a1,-1870 # 800085e0 <syscalls+0x168>
    80003d36:	0001c517          	auipc	a0,0x1c
    80003d3a:	45a50513          	addi	a0,a0,1114 # 80020190 <itable>
    80003d3e:	ffffd097          	auipc	ra,0xffffd
    80003d42:	e16080e7          	jalr	-490(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003d46:	0001c497          	auipc	s1,0x1c
    80003d4a:	47248493          	addi	s1,s1,1138 # 800201b8 <itable+0x28>
    80003d4e:	0001e997          	auipc	s3,0x1e
    80003d52:	efa98993          	addi	s3,s3,-262 # 80021c48 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003d56:	00005917          	auipc	s2,0x5
    80003d5a:	89290913          	addi	s2,s2,-1902 # 800085e8 <syscalls+0x170>
    80003d5e:	85ca                	mv	a1,s2
    80003d60:	8526                	mv	a0,s1
    80003d62:	00001097          	auipc	ra,0x1
    80003d66:	e46080e7          	jalr	-442(ra) # 80004ba8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d6a:	08848493          	addi	s1,s1,136
    80003d6e:	ff3498e3          	bne	s1,s3,80003d5e <iinit+0x3e>
}
    80003d72:	70a2                	ld	ra,40(sp)
    80003d74:	7402                	ld	s0,32(sp)
    80003d76:	64e2                	ld	s1,24(sp)
    80003d78:	6942                	ld	s2,16(sp)
    80003d7a:	69a2                	ld	s3,8(sp)
    80003d7c:	6145                	addi	sp,sp,48
    80003d7e:	8082                	ret

0000000080003d80 <ialloc>:
{
    80003d80:	715d                	addi	sp,sp,-80
    80003d82:	e486                	sd	ra,72(sp)
    80003d84:	e0a2                	sd	s0,64(sp)
    80003d86:	fc26                	sd	s1,56(sp)
    80003d88:	f84a                	sd	s2,48(sp)
    80003d8a:	f44e                	sd	s3,40(sp)
    80003d8c:	f052                	sd	s4,32(sp)
    80003d8e:	ec56                	sd	s5,24(sp)
    80003d90:	e85a                	sd	s6,16(sp)
    80003d92:	e45e                	sd	s7,8(sp)
    80003d94:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d96:	0001c717          	auipc	a4,0x1c
    80003d9a:	3e672703          	lw	a4,998(a4) # 8002017c <sb+0xc>
    80003d9e:	4785                	li	a5,1
    80003da0:	04e7fa63          	bgeu	a5,a4,80003df4 <ialloc+0x74>
    80003da4:	8aaa                	mv	s5,a0
    80003da6:	8bae                	mv	s7,a1
    80003da8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003daa:	0001ca17          	auipc	s4,0x1c
    80003dae:	3c6a0a13          	addi	s4,s4,966 # 80020170 <sb>
    80003db2:	00048b1b          	sext.w	s6,s1
    80003db6:	0044d593          	srli	a1,s1,0x4
    80003dba:	018a2783          	lw	a5,24(s4)
    80003dbe:	9dbd                	addw	a1,a1,a5
    80003dc0:	8556                	mv	a0,s5
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	954080e7          	jalr	-1708(ra) # 80003716 <bread>
    80003dca:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003dcc:	05850993          	addi	s3,a0,88
    80003dd0:	00f4f793          	andi	a5,s1,15
    80003dd4:	079a                	slli	a5,a5,0x6
    80003dd6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003dd8:	00099783          	lh	a5,0(s3)
    80003ddc:	c785                	beqz	a5,80003e04 <ialloc+0x84>
    brelse(bp);
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	a68080e7          	jalr	-1432(ra) # 80003846 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003de6:	0485                	addi	s1,s1,1
    80003de8:	00ca2703          	lw	a4,12(s4)
    80003dec:	0004879b          	sext.w	a5,s1
    80003df0:	fce7e1e3          	bltu	a5,a4,80003db2 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003df4:	00004517          	auipc	a0,0x4
    80003df8:	7fc50513          	addi	a0,a0,2044 # 800085f0 <syscalls+0x178>
    80003dfc:	ffffc097          	auipc	ra,0xffffc
    80003e00:	742080e7          	jalr	1858(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003e04:	04000613          	li	a2,64
    80003e08:	4581                	li	a1,0
    80003e0a:	854e                	mv	a0,s3
    80003e0c:	ffffd097          	auipc	ra,0xffffd
    80003e10:	f06080e7          	jalr	-250(ra) # 80000d12 <memset>
      dip->type = type;
    80003e14:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003e18:	854a                	mv	a0,s2
    80003e1a:	00001097          	auipc	ra,0x1
    80003e1e:	ca8080e7          	jalr	-856(ra) # 80004ac2 <log_write>
      brelse(bp);
    80003e22:	854a                	mv	a0,s2
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	a22080e7          	jalr	-1502(ra) # 80003846 <brelse>
      return iget(dev, inum);
    80003e2c:	85da                	mv	a1,s6
    80003e2e:	8556                	mv	a0,s5
    80003e30:	00000097          	auipc	ra,0x0
    80003e34:	db4080e7          	jalr	-588(ra) # 80003be4 <iget>
}
    80003e38:	60a6                	ld	ra,72(sp)
    80003e3a:	6406                	ld	s0,64(sp)
    80003e3c:	74e2                	ld	s1,56(sp)
    80003e3e:	7942                	ld	s2,48(sp)
    80003e40:	79a2                	ld	s3,40(sp)
    80003e42:	7a02                	ld	s4,32(sp)
    80003e44:	6ae2                	ld	s5,24(sp)
    80003e46:	6b42                	ld	s6,16(sp)
    80003e48:	6ba2                	ld	s7,8(sp)
    80003e4a:	6161                	addi	sp,sp,80
    80003e4c:	8082                	ret

0000000080003e4e <iupdate>:
{
    80003e4e:	1101                	addi	sp,sp,-32
    80003e50:	ec06                	sd	ra,24(sp)
    80003e52:	e822                	sd	s0,16(sp)
    80003e54:	e426                	sd	s1,8(sp)
    80003e56:	e04a                	sd	s2,0(sp)
    80003e58:	1000                	addi	s0,sp,32
    80003e5a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e5c:	415c                	lw	a5,4(a0)
    80003e5e:	0047d79b          	srliw	a5,a5,0x4
    80003e62:	0001c597          	auipc	a1,0x1c
    80003e66:	3265a583          	lw	a1,806(a1) # 80020188 <sb+0x18>
    80003e6a:	9dbd                	addw	a1,a1,a5
    80003e6c:	4108                	lw	a0,0(a0)
    80003e6e:	00000097          	auipc	ra,0x0
    80003e72:	8a8080e7          	jalr	-1880(ra) # 80003716 <bread>
    80003e76:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e78:	05850793          	addi	a5,a0,88
    80003e7c:	40c8                	lw	a0,4(s1)
    80003e7e:	893d                	andi	a0,a0,15
    80003e80:	051a                	slli	a0,a0,0x6
    80003e82:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003e84:	04449703          	lh	a4,68(s1)
    80003e88:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003e8c:	04649703          	lh	a4,70(s1)
    80003e90:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003e94:	04849703          	lh	a4,72(s1)
    80003e98:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003e9c:	04a49703          	lh	a4,74(s1)
    80003ea0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003ea4:	44f8                	lw	a4,76(s1)
    80003ea6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003ea8:	03400613          	li	a2,52
    80003eac:	05048593          	addi	a1,s1,80
    80003eb0:	0531                	addi	a0,a0,12
    80003eb2:	ffffd097          	auipc	ra,0xffffd
    80003eb6:	ec0080e7          	jalr	-320(ra) # 80000d72 <memmove>
  log_write(bp);
    80003eba:	854a                	mv	a0,s2
    80003ebc:	00001097          	auipc	ra,0x1
    80003ec0:	c06080e7          	jalr	-1018(ra) # 80004ac2 <log_write>
  brelse(bp);
    80003ec4:	854a                	mv	a0,s2
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	980080e7          	jalr	-1664(ra) # 80003846 <brelse>
}
    80003ece:	60e2                	ld	ra,24(sp)
    80003ed0:	6442                	ld	s0,16(sp)
    80003ed2:	64a2                	ld	s1,8(sp)
    80003ed4:	6902                	ld	s2,0(sp)
    80003ed6:	6105                	addi	sp,sp,32
    80003ed8:	8082                	ret

0000000080003eda <idup>:
{
    80003eda:	1101                	addi	sp,sp,-32
    80003edc:	ec06                	sd	ra,24(sp)
    80003ede:	e822                	sd	s0,16(sp)
    80003ee0:	e426                	sd	s1,8(sp)
    80003ee2:	1000                	addi	s0,sp,32
    80003ee4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ee6:	0001c517          	auipc	a0,0x1c
    80003eea:	2aa50513          	addi	a0,a0,682 # 80020190 <itable>
    80003eee:	ffffd097          	auipc	ra,0xffffd
    80003ef2:	cfe080e7          	jalr	-770(ra) # 80000bec <acquire>
  ip->ref++;
    80003ef6:	449c                	lw	a5,8(s1)
    80003ef8:	2785                	addiw	a5,a5,1
    80003efa:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003efc:	0001c517          	auipc	a0,0x1c
    80003f00:	29450513          	addi	a0,a0,660 # 80020190 <itable>
    80003f04:	ffffd097          	auipc	ra,0xffffd
    80003f08:	db4080e7          	jalr	-588(ra) # 80000cb8 <release>
}
    80003f0c:	8526                	mv	a0,s1
    80003f0e:	60e2                	ld	ra,24(sp)
    80003f10:	6442                	ld	s0,16(sp)
    80003f12:	64a2                	ld	s1,8(sp)
    80003f14:	6105                	addi	sp,sp,32
    80003f16:	8082                	ret

0000000080003f18 <ilock>:
{
    80003f18:	1101                	addi	sp,sp,-32
    80003f1a:	ec06                	sd	ra,24(sp)
    80003f1c:	e822                	sd	s0,16(sp)
    80003f1e:	e426                	sd	s1,8(sp)
    80003f20:	e04a                	sd	s2,0(sp)
    80003f22:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003f24:	c115                	beqz	a0,80003f48 <ilock+0x30>
    80003f26:	84aa                	mv	s1,a0
    80003f28:	451c                	lw	a5,8(a0)
    80003f2a:	00f05f63          	blez	a5,80003f48 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003f2e:	0541                	addi	a0,a0,16
    80003f30:	00001097          	auipc	ra,0x1
    80003f34:	cb2080e7          	jalr	-846(ra) # 80004be2 <acquiresleep>
  if(ip->valid == 0){
    80003f38:	40bc                	lw	a5,64(s1)
    80003f3a:	cf99                	beqz	a5,80003f58 <ilock+0x40>
}
    80003f3c:	60e2                	ld	ra,24(sp)
    80003f3e:	6442                	ld	s0,16(sp)
    80003f40:	64a2                	ld	s1,8(sp)
    80003f42:	6902                	ld	s2,0(sp)
    80003f44:	6105                	addi	sp,sp,32
    80003f46:	8082                	ret
    panic("ilock");
    80003f48:	00004517          	auipc	a0,0x4
    80003f4c:	6c050513          	addi	a0,a0,1728 # 80008608 <syscalls+0x190>
    80003f50:	ffffc097          	auipc	ra,0xffffc
    80003f54:	5ee080e7          	jalr	1518(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f58:	40dc                	lw	a5,4(s1)
    80003f5a:	0047d79b          	srliw	a5,a5,0x4
    80003f5e:	0001c597          	auipc	a1,0x1c
    80003f62:	22a5a583          	lw	a1,554(a1) # 80020188 <sb+0x18>
    80003f66:	9dbd                	addw	a1,a1,a5
    80003f68:	4088                	lw	a0,0(s1)
    80003f6a:	fffff097          	auipc	ra,0xfffff
    80003f6e:	7ac080e7          	jalr	1964(ra) # 80003716 <bread>
    80003f72:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f74:	05850593          	addi	a1,a0,88
    80003f78:	40dc                	lw	a5,4(s1)
    80003f7a:	8bbd                	andi	a5,a5,15
    80003f7c:	079a                	slli	a5,a5,0x6
    80003f7e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f80:	00059783          	lh	a5,0(a1)
    80003f84:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f88:	00259783          	lh	a5,2(a1)
    80003f8c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f90:	00459783          	lh	a5,4(a1)
    80003f94:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f98:	00659783          	lh	a5,6(a1)
    80003f9c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003fa0:	459c                	lw	a5,8(a1)
    80003fa2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003fa4:	03400613          	li	a2,52
    80003fa8:	05b1                	addi	a1,a1,12
    80003faa:	05048513          	addi	a0,s1,80
    80003fae:	ffffd097          	auipc	ra,0xffffd
    80003fb2:	dc4080e7          	jalr	-572(ra) # 80000d72 <memmove>
    brelse(bp);
    80003fb6:	854a                	mv	a0,s2
    80003fb8:	00000097          	auipc	ra,0x0
    80003fbc:	88e080e7          	jalr	-1906(ra) # 80003846 <brelse>
    ip->valid = 1;
    80003fc0:	4785                	li	a5,1
    80003fc2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003fc4:	04449783          	lh	a5,68(s1)
    80003fc8:	fbb5                	bnez	a5,80003f3c <ilock+0x24>
      panic("ilock: no type");
    80003fca:	00004517          	auipc	a0,0x4
    80003fce:	64650513          	addi	a0,a0,1606 # 80008610 <syscalls+0x198>
    80003fd2:	ffffc097          	auipc	ra,0xffffc
    80003fd6:	56c080e7          	jalr	1388(ra) # 8000053e <panic>

0000000080003fda <iunlock>:
{
    80003fda:	1101                	addi	sp,sp,-32
    80003fdc:	ec06                	sd	ra,24(sp)
    80003fde:	e822                	sd	s0,16(sp)
    80003fe0:	e426                	sd	s1,8(sp)
    80003fe2:	e04a                	sd	s2,0(sp)
    80003fe4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003fe6:	c905                	beqz	a0,80004016 <iunlock+0x3c>
    80003fe8:	84aa                	mv	s1,a0
    80003fea:	01050913          	addi	s2,a0,16
    80003fee:	854a                	mv	a0,s2
    80003ff0:	00001097          	auipc	ra,0x1
    80003ff4:	c8c080e7          	jalr	-884(ra) # 80004c7c <holdingsleep>
    80003ff8:	cd19                	beqz	a0,80004016 <iunlock+0x3c>
    80003ffa:	449c                	lw	a5,8(s1)
    80003ffc:	00f05d63          	blez	a5,80004016 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004000:	854a                	mv	a0,s2
    80004002:	00001097          	auipc	ra,0x1
    80004006:	c36080e7          	jalr	-970(ra) # 80004c38 <releasesleep>
}
    8000400a:	60e2                	ld	ra,24(sp)
    8000400c:	6442                	ld	s0,16(sp)
    8000400e:	64a2                	ld	s1,8(sp)
    80004010:	6902                	ld	s2,0(sp)
    80004012:	6105                	addi	sp,sp,32
    80004014:	8082                	ret
    panic("iunlock");
    80004016:	00004517          	auipc	a0,0x4
    8000401a:	60a50513          	addi	a0,a0,1546 # 80008620 <syscalls+0x1a8>
    8000401e:	ffffc097          	auipc	ra,0xffffc
    80004022:	520080e7          	jalr	1312(ra) # 8000053e <panic>

0000000080004026 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004026:	7179                	addi	sp,sp,-48
    80004028:	f406                	sd	ra,40(sp)
    8000402a:	f022                	sd	s0,32(sp)
    8000402c:	ec26                	sd	s1,24(sp)
    8000402e:	e84a                	sd	s2,16(sp)
    80004030:	e44e                	sd	s3,8(sp)
    80004032:	e052                	sd	s4,0(sp)
    80004034:	1800                	addi	s0,sp,48
    80004036:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004038:	05050493          	addi	s1,a0,80
    8000403c:	08050913          	addi	s2,a0,128
    80004040:	a021                	j	80004048 <itrunc+0x22>
    80004042:	0491                	addi	s1,s1,4
    80004044:	01248d63          	beq	s1,s2,8000405e <itrunc+0x38>
    if(ip->addrs[i]){
    80004048:	408c                	lw	a1,0(s1)
    8000404a:	dde5                	beqz	a1,80004042 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000404c:	0009a503          	lw	a0,0(s3)
    80004050:	00000097          	auipc	ra,0x0
    80004054:	90c080e7          	jalr	-1780(ra) # 8000395c <bfree>
      ip->addrs[i] = 0;
    80004058:	0004a023          	sw	zero,0(s1)
    8000405c:	b7dd                	j	80004042 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000405e:	0809a583          	lw	a1,128(s3)
    80004062:	e185                	bnez	a1,80004082 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004064:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004068:	854e                	mv	a0,s3
    8000406a:	00000097          	auipc	ra,0x0
    8000406e:	de4080e7          	jalr	-540(ra) # 80003e4e <iupdate>
}
    80004072:	70a2                	ld	ra,40(sp)
    80004074:	7402                	ld	s0,32(sp)
    80004076:	64e2                	ld	s1,24(sp)
    80004078:	6942                	ld	s2,16(sp)
    8000407a:	69a2                	ld	s3,8(sp)
    8000407c:	6a02                	ld	s4,0(sp)
    8000407e:	6145                	addi	sp,sp,48
    80004080:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004082:	0009a503          	lw	a0,0(s3)
    80004086:	fffff097          	auipc	ra,0xfffff
    8000408a:	690080e7          	jalr	1680(ra) # 80003716 <bread>
    8000408e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004090:	05850493          	addi	s1,a0,88
    80004094:	45850913          	addi	s2,a0,1112
    80004098:	a811                	j	800040ac <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000409a:	0009a503          	lw	a0,0(s3)
    8000409e:	00000097          	auipc	ra,0x0
    800040a2:	8be080e7          	jalr	-1858(ra) # 8000395c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800040a6:	0491                	addi	s1,s1,4
    800040a8:	01248563          	beq	s1,s2,800040b2 <itrunc+0x8c>
      if(a[j])
    800040ac:	408c                	lw	a1,0(s1)
    800040ae:	dde5                	beqz	a1,800040a6 <itrunc+0x80>
    800040b0:	b7ed                	j	8000409a <itrunc+0x74>
    brelse(bp);
    800040b2:	8552                	mv	a0,s4
    800040b4:	fffff097          	auipc	ra,0xfffff
    800040b8:	792080e7          	jalr	1938(ra) # 80003846 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800040bc:	0809a583          	lw	a1,128(s3)
    800040c0:	0009a503          	lw	a0,0(s3)
    800040c4:	00000097          	auipc	ra,0x0
    800040c8:	898080e7          	jalr	-1896(ra) # 8000395c <bfree>
    ip->addrs[NDIRECT] = 0;
    800040cc:	0809a023          	sw	zero,128(s3)
    800040d0:	bf51                	j	80004064 <itrunc+0x3e>

00000000800040d2 <iput>:
{
    800040d2:	1101                	addi	sp,sp,-32
    800040d4:	ec06                	sd	ra,24(sp)
    800040d6:	e822                	sd	s0,16(sp)
    800040d8:	e426                	sd	s1,8(sp)
    800040da:	e04a                	sd	s2,0(sp)
    800040dc:	1000                	addi	s0,sp,32
    800040de:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800040e0:	0001c517          	auipc	a0,0x1c
    800040e4:	0b050513          	addi	a0,a0,176 # 80020190 <itable>
    800040e8:	ffffd097          	auipc	ra,0xffffd
    800040ec:	b04080e7          	jalr	-1276(ra) # 80000bec <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040f0:	4498                	lw	a4,8(s1)
    800040f2:	4785                	li	a5,1
    800040f4:	02f70363          	beq	a4,a5,8000411a <iput+0x48>
  ip->ref--;
    800040f8:	449c                	lw	a5,8(s1)
    800040fa:	37fd                	addiw	a5,a5,-1
    800040fc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800040fe:	0001c517          	auipc	a0,0x1c
    80004102:	09250513          	addi	a0,a0,146 # 80020190 <itable>
    80004106:	ffffd097          	auipc	ra,0xffffd
    8000410a:	bb2080e7          	jalr	-1102(ra) # 80000cb8 <release>
}
    8000410e:	60e2                	ld	ra,24(sp)
    80004110:	6442                	ld	s0,16(sp)
    80004112:	64a2                	ld	s1,8(sp)
    80004114:	6902                	ld	s2,0(sp)
    80004116:	6105                	addi	sp,sp,32
    80004118:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000411a:	40bc                	lw	a5,64(s1)
    8000411c:	dff1                	beqz	a5,800040f8 <iput+0x26>
    8000411e:	04a49783          	lh	a5,74(s1)
    80004122:	fbf9                	bnez	a5,800040f8 <iput+0x26>
    acquiresleep(&ip->lock);
    80004124:	01048913          	addi	s2,s1,16
    80004128:	854a                	mv	a0,s2
    8000412a:	00001097          	auipc	ra,0x1
    8000412e:	ab8080e7          	jalr	-1352(ra) # 80004be2 <acquiresleep>
    release(&itable.lock);
    80004132:	0001c517          	auipc	a0,0x1c
    80004136:	05e50513          	addi	a0,a0,94 # 80020190 <itable>
    8000413a:	ffffd097          	auipc	ra,0xffffd
    8000413e:	b7e080e7          	jalr	-1154(ra) # 80000cb8 <release>
    itrunc(ip);
    80004142:	8526                	mv	a0,s1
    80004144:	00000097          	auipc	ra,0x0
    80004148:	ee2080e7          	jalr	-286(ra) # 80004026 <itrunc>
    ip->type = 0;
    8000414c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004150:	8526                	mv	a0,s1
    80004152:	00000097          	auipc	ra,0x0
    80004156:	cfc080e7          	jalr	-772(ra) # 80003e4e <iupdate>
    ip->valid = 0;
    8000415a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000415e:	854a                	mv	a0,s2
    80004160:	00001097          	auipc	ra,0x1
    80004164:	ad8080e7          	jalr	-1320(ra) # 80004c38 <releasesleep>
    acquire(&itable.lock);
    80004168:	0001c517          	auipc	a0,0x1c
    8000416c:	02850513          	addi	a0,a0,40 # 80020190 <itable>
    80004170:	ffffd097          	auipc	ra,0xffffd
    80004174:	a7c080e7          	jalr	-1412(ra) # 80000bec <acquire>
    80004178:	b741                	j	800040f8 <iput+0x26>

000000008000417a <iunlockput>:
{
    8000417a:	1101                	addi	sp,sp,-32
    8000417c:	ec06                	sd	ra,24(sp)
    8000417e:	e822                	sd	s0,16(sp)
    80004180:	e426                	sd	s1,8(sp)
    80004182:	1000                	addi	s0,sp,32
    80004184:	84aa                	mv	s1,a0
  iunlock(ip);
    80004186:	00000097          	auipc	ra,0x0
    8000418a:	e54080e7          	jalr	-428(ra) # 80003fda <iunlock>
  iput(ip);
    8000418e:	8526                	mv	a0,s1
    80004190:	00000097          	auipc	ra,0x0
    80004194:	f42080e7          	jalr	-190(ra) # 800040d2 <iput>
}
    80004198:	60e2                	ld	ra,24(sp)
    8000419a:	6442                	ld	s0,16(sp)
    8000419c:	64a2                	ld	s1,8(sp)
    8000419e:	6105                	addi	sp,sp,32
    800041a0:	8082                	ret

00000000800041a2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800041a2:	1141                	addi	sp,sp,-16
    800041a4:	e422                	sd	s0,8(sp)
    800041a6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800041a8:	411c                	lw	a5,0(a0)
    800041aa:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800041ac:	415c                	lw	a5,4(a0)
    800041ae:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800041b0:	04451783          	lh	a5,68(a0)
    800041b4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800041b8:	04a51783          	lh	a5,74(a0)
    800041bc:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800041c0:	04c56783          	lwu	a5,76(a0)
    800041c4:	e99c                	sd	a5,16(a1)
}
    800041c6:	6422                	ld	s0,8(sp)
    800041c8:	0141                	addi	sp,sp,16
    800041ca:	8082                	ret

00000000800041cc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041cc:	457c                	lw	a5,76(a0)
    800041ce:	0ed7e963          	bltu	a5,a3,800042c0 <readi+0xf4>
{
    800041d2:	7159                	addi	sp,sp,-112
    800041d4:	f486                	sd	ra,104(sp)
    800041d6:	f0a2                	sd	s0,96(sp)
    800041d8:	eca6                	sd	s1,88(sp)
    800041da:	e8ca                	sd	s2,80(sp)
    800041dc:	e4ce                	sd	s3,72(sp)
    800041de:	e0d2                	sd	s4,64(sp)
    800041e0:	fc56                	sd	s5,56(sp)
    800041e2:	f85a                	sd	s6,48(sp)
    800041e4:	f45e                	sd	s7,40(sp)
    800041e6:	f062                	sd	s8,32(sp)
    800041e8:	ec66                	sd	s9,24(sp)
    800041ea:	e86a                	sd	s10,16(sp)
    800041ec:	e46e                	sd	s11,8(sp)
    800041ee:	1880                	addi	s0,sp,112
    800041f0:	8baa                	mv	s7,a0
    800041f2:	8c2e                	mv	s8,a1
    800041f4:	8ab2                	mv	s5,a2
    800041f6:	84b6                	mv	s1,a3
    800041f8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800041fa:	9f35                	addw	a4,a4,a3
    return 0;
    800041fc:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800041fe:	0ad76063          	bltu	a4,a3,8000429e <readi+0xd2>
  if(off + n > ip->size)
    80004202:	00e7f463          	bgeu	a5,a4,8000420a <readi+0x3e>
    n = ip->size - off;
    80004206:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000420a:	0a0b0963          	beqz	s6,800042bc <readi+0xf0>
    8000420e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004210:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004214:	5cfd                	li	s9,-1
    80004216:	a82d                	j	80004250 <readi+0x84>
    80004218:	020a1d93          	slli	s11,s4,0x20
    8000421c:	020ddd93          	srli	s11,s11,0x20
    80004220:	05890613          	addi	a2,s2,88
    80004224:	86ee                	mv	a3,s11
    80004226:	963a                	add	a2,a2,a4
    80004228:	85d6                	mv	a1,s5
    8000422a:	8562                	mv	a0,s8
    8000422c:	fffff097          	auipc	ra,0xfffff
    80004230:	a46080e7          	jalr	-1466(ra) # 80002c72 <either_copyout>
    80004234:	05950d63          	beq	a0,s9,8000428e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004238:	854a                	mv	a0,s2
    8000423a:	fffff097          	auipc	ra,0xfffff
    8000423e:	60c080e7          	jalr	1548(ra) # 80003846 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004242:	013a09bb          	addw	s3,s4,s3
    80004246:	009a04bb          	addw	s1,s4,s1
    8000424a:	9aee                	add	s5,s5,s11
    8000424c:	0569f763          	bgeu	s3,s6,8000429a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004250:	000ba903          	lw	s2,0(s7)
    80004254:	00a4d59b          	srliw	a1,s1,0xa
    80004258:	855e                	mv	a0,s7
    8000425a:	00000097          	auipc	ra,0x0
    8000425e:	8b0080e7          	jalr	-1872(ra) # 80003b0a <bmap>
    80004262:	0005059b          	sext.w	a1,a0
    80004266:	854a                	mv	a0,s2
    80004268:	fffff097          	auipc	ra,0xfffff
    8000426c:	4ae080e7          	jalr	1198(ra) # 80003716 <bread>
    80004270:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004272:	3ff4f713          	andi	a4,s1,1023
    80004276:	40ed07bb          	subw	a5,s10,a4
    8000427a:	413b06bb          	subw	a3,s6,s3
    8000427e:	8a3e                	mv	s4,a5
    80004280:	2781                	sext.w	a5,a5
    80004282:	0006861b          	sext.w	a2,a3
    80004286:	f8f679e3          	bgeu	a2,a5,80004218 <readi+0x4c>
    8000428a:	8a36                	mv	s4,a3
    8000428c:	b771                	j	80004218 <readi+0x4c>
      brelse(bp);
    8000428e:	854a                	mv	a0,s2
    80004290:	fffff097          	auipc	ra,0xfffff
    80004294:	5b6080e7          	jalr	1462(ra) # 80003846 <brelse>
      tot = -1;
    80004298:	59fd                	li	s3,-1
  }
  return tot;
    8000429a:	0009851b          	sext.w	a0,s3
}
    8000429e:	70a6                	ld	ra,104(sp)
    800042a0:	7406                	ld	s0,96(sp)
    800042a2:	64e6                	ld	s1,88(sp)
    800042a4:	6946                	ld	s2,80(sp)
    800042a6:	69a6                	ld	s3,72(sp)
    800042a8:	6a06                	ld	s4,64(sp)
    800042aa:	7ae2                	ld	s5,56(sp)
    800042ac:	7b42                	ld	s6,48(sp)
    800042ae:	7ba2                	ld	s7,40(sp)
    800042b0:	7c02                	ld	s8,32(sp)
    800042b2:	6ce2                	ld	s9,24(sp)
    800042b4:	6d42                	ld	s10,16(sp)
    800042b6:	6da2                	ld	s11,8(sp)
    800042b8:	6165                	addi	sp,sp,112
    800042ba:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042bc:	89da                	mv	s3,s6
    800042be:	bff1                	j	8000429a <readi+0xce>
    return 0;
    800042c0:	4501                	li	a0,0
}
    800042c2:	8082                	ret

00000000800042c4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800042c4:	457c                	lw	a5,76(a0)
    800042c6:	10d7e863          	bltu	a5,a3,800043d6 <writei+0x112>
{
    800042ca:	7159                	addi	sp,sp,-112
    800042cc:	f486                	sd	ra,104(sp)
    800042ce:	f0a2                	sd	s0,96(sp)
    800042d0:	eca6                	sd	s1,88(sp)
    800042d2:	e8ca                	sd	s2,80(sp)
    800042d4:	e4ce                	sd	s3,72(sp)
    800042d6:	e0d2                	sd	s4,64(sp)
    800042d8:	fc56                	sd	s5,56(sp)
    800042da:	f85a                	sd	s6,48(sp)
    800042dc:	f45e                	sd	s7,40(sp)
    800042de:	f062                	sd	s8,32(sp)
    800042e0:	ec66                	sd	s9,24(sp)
    800042e2:	e86a                	sd	s10,16(sp)
    800042e4:	e46e                	sd	s11,8(sp)
    800042e6:	1880                	addi	s0,sp,112
    800042e8:	8b2a                	mv	s6,a0
    800042ea:	8c2e                	mv	s8,a1
    800042ec:	8ab2                	mv	s5,a2
    800042ee:	8936                	mv	s2,a3
    800042f0:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800042f2:	00e687bb          	addw	a5,a3,a4
    800042f6:	0ed7e263          	bltu	a5,a3,800043da <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800042fa:	00043737          	lui	a4,0x43
    800042fe:	0ef76063          	bltu	a4,a5,800043de <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004302:	0c0b8863          	beqz	s7,800043d2 <writei+0x10e>
    80004306:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004308:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000430c:	5cfd                	li	s9,-1
    8000430e:	a091                	j	80004352 <writei+0x8e>
    80004310:	02099d93          	slli	s11,s3,0x20
    80004314:	020ddd93          	srli	s11,s11,0x20
    80004318:	05848513          	addi	a0,s1,88
    8000431c:	86ee                	mv	a3,s11
    8000431e:	8656                	mv	a2,s5
    80004320:	85e2                	mv	a1,s8
    80004322:	953a                	add	a0,a0,a4
    80004324:	fffff097          	auipc	ra,0xfffff
    80004328:	9a4080e7          	jalr	-1628(ra) # 80002cc8 <either_copyin>
    8000432c:	07950263          	beq	a0,s9,80004390 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004330:	8526                	mv	a0,s1
    80004332:	00000097          	auipc	ra,0x0
    80004336:	790080e7          	jalr	1936(ra) # 80004ac2 <log_write>
    brelse(bp);
    8000433a:	8526                	mv	a0,s1
    8000433c:	fffff097          	auipc	ra,0xfffff
    80004340:	50a080e7          	jalr	1290(ra) # 80003846 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004344:	01498a3b          	addw	s4,s3,s4
    80004348:	0129893b          	addw	s2,s3,s2
    8000434c:	9aee                	add	s5,s5,s11
    8000434e:	057a7663          	bgeu	s4,s7,8000439a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004352:	000b2483          	lw	s1,0(s6)
    80004356:	00a9559b          	srliw	a1,s2,0xa
    8000435a:	855a                	mv	a0,s6
    8000435c:	fffff097          	auipc	ra,0xfffff
    80004360:	7ae080e7          	jalr	1966(ra) # 80003b0a <bmap>
    80004364:	0005059b          	sext.w	a1,a0
    80004368:	8526                	mv	a0,s1
    8000436a:	fffff097          	auipc	ra,0xfffff
    8000436e:	3ac080e7          	jalr	940(ra) # 80003716 <bread>
    80004372:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004374:	3ff97713          	andi	a4,s2,1023
    80004378:	40ed07bb          	subw	a5,s10,a4
    8000437c:	414b86bb          	subw	a3,s7,s4
    80004380:	89be                	mv	s3,a5
    80004382:	2781                	sext.w	a5,a5
    80004384:	0006861b          	sext.w	a2,a3
    80004388:	f8f674e3          	bgeu	a2,a5,80004310 <writei+0x4c>
    8000438c:	89b6                	mv	s3,a3
    8000438e:	b749                	j	80004310 <writei+0x4c>
      brelse(bp);
    80004390:	8526                	mv	a0,s1
    80004392:	fffff097          	auipc	ra,0xfffff
    80004396:	4b4080e7          	jalr	1204(ra) # 80003846 <brelse>
  }

  if(off > ip->size)
    8000439a:	04cb2783          	lw	a5,76(s6)
    8000439e:	0127f463          	bgeu	a5,s2,800043a6 <writei+0xe2>
    ip->size = off;
    800043a2:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800043a6:	855a                	mv	a0,s6
    800043a8:	00000097          	auipc	ra,0x0
    800043ac:	aa6080e7          	jalr	-1370(ra) # 80003e4e <iupdate>

  return tot;
    800043b0:	000a051b          	sext.w	a0,s4
}
    800043b4:	70a6                	ld	ra,104(sp)
    800043b6:	7406                	ld	s0,96(sp)
    800043b8:	64e6                	ld	s1,88(sp)
    800043ba:	6946                	ld	s2,80(sp)
    800043bc:	69a6                	ld	s3,72(sp)
    800043be:	6a06                	ld	s4,64(sp)
    800043c0:	7ae2                	ld	s5,56(sp)
    800043c2:	7b42                	ld	s6,48(sp)
    800043c4:	7ba2                	ld	s7,40(sp)
    800043c6:	7c02                	ld	s8,32(sp)
    800043c8:	6ce2                	ld	s9,24(sp)
    800043ca:	6d42                	ld	s10,16(sp)
    800043cc:	6da2                	ld	s11,8(sp)
    800043ce:	6165                	addi	sp,sp,112
    800043d0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043d2:	8a5e                	mv	s4,s7
    800043d4:	bfc9                	j	800043a6 <writei+0xe2>
    return -1;
    800043d6:	557d                	li	a0,-1
}
    800043d8:	8082                	ret
    return -1;
    800043da:	557d                	li	a0,-1
    800043dc:	bfe1                	j	800043b4 <writei+0xf0>
    return -1;
    800043de:	557d                	li	a0,-1
    800043e0:	bfd1                	j	800043b4 <writei+0xf0>

00000000800043e2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800043e2:	1141                	addi	sp,sp,-16
    800043e4:	e406                	sd	ra,8(sp)
    800043e6:	e022                	sd	s0,0(sp)
    800043e8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800043ea:	4639                	li	a2,14
    800043ec:	ffffd097          	auipc	ra,0xffffd
    800043f0:	9fe080e7          	jalr	-1538(ra) # 80000dea <strncmp>
}
    800043f4:	60a2                	ld	ra,8(sp)
    800043f6:	6402                	ld	s0,0(sp)
    800043f8:	0141                	addi	sp,sp,16
    800043fa:	8082                	ret

00000000800043fc <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800043fc:	7139                	addi	sp,sp,-64
    800043fe:	fc06                	sd	ra,56(sp)
    80004400:	f822                	sd	s0,48(sp)
    80004402:	f426                	sd	s1,40(sp)
    80004404:	f04a                	sd	s2,32(sp)
    80004406:	ec4e                	sd	s3,24(sp)
    80004408:	e852                	sd	s4,16(sp)
    8000440a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000440c:	04451703          	lh	a4,68(a0)
    80004410:	4785                	li	a5,1
    80004412:	00f71a63          	bne	a4,a5,80004426 <dirlookup+0x2a>
    80004416:	892a                	mv	s2,a0
    80004418:	89ae                	mv	s3,a1
    8000441a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000441c:	457c                	lw	a5,76(a0)
    8000441e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004420:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004422:	e79d                	bnez	a5,80004450 <dirlookup+0x54>
    80004424:	a8a5                	j	8000449c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004426:	00004517          	auipc	a0,0x4
    8000442a:	20250513          	addi	a0,a0,514 # 80008628 <syscalls+0x1b0>
    8000442e:	ffffc097          	auipc	ra,0xffffc
    80004432:	110080e7          	jalr	272(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004436:	00004517          	auipc	a0,0x4
    8000443a:	20a50513          	addi	a0,a0,522 # 80008640 <syscalls+0x1c8>
    8000443e:	ffffc097          	auipc	ra,0xffffc
    80004442:	100080e7          	jalr	256(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004446:	24c1                	addiw	s1,s1,16
    80004448:	04c92783          	lw	a5,76(s2)
    8000444c:	04f4f763          	bgeu	s1,a5,8000449a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004450:	4741                	li	a4,16
    80004452:	86a6                	mv	a3,s1
    80004454:	fc040613          	addi	a2,s0,-64
    80004458:	4581                	li	a1,0
    8000445a:	854a                	mv	a0,s2
    8000445c:	00000097          	auipc	ra,0x0
    80004460:	d70080e7          	jalr	-656(ra) # 800041cc <readi>
    80004464:	47c1                	li	a5,16
    80004466:	fcf518e3          	bne	a0,a5,80004436 <dirlookup+0x3a>
    if(de.inum == 0)
    8000446a:	fc045783          	lhu	a5,-64(s0)
    8000446e:	dfe1                	beqz	a5,80004446 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004470:	fc240593          	addi	a1,s0,-62
    80004474:	854e                	mv	a0,s3
    80004476:	00000097          	auipc	ra,0x0
    8000447a:	f6c080e7          	jalr	-148(ra) # 800043e2 <namecmp>
    8000447e:	f561                	bnez	a0,80004446 <dirlookup+0x4a>
      if(poff)
    80004480:	000a0463          	beqz	s4,80004488 <dirlookup+0x8c>
        *poff = off;
    80004484:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004488:	fc045583          	lhu	a1,-64(s0)
    8000448c:	00092503          	lw	a0,0(s2)
    80004490:	fffff097          	auipc	ra,0xfffff
    80004494:	754080e7          	jalr	1876(ra) # 80003be4 <iget>
    80004498:	a011                	j	8000449c <dirlookup+0xa0>
  return 0;
    8000449a:	4501                	li	a0,0
}
    8000449c:	70e2                	ld	ra,56(sp)
    8000449e:	7442                	ld	s0,48(sp)
    800044a0:	74a2                	ld	s1,40(sp)
    800044a2:	7902                	ld	s2,32(sp)
    800044a4:	69e2                	ld	s3,24(sp)
    800044a6:	6a42                	ld	s4,16(sp)
    800044a8:	6121                	addi	sp,sp,64
    800044aa:	8082                	ret

00000000800044ac <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800044ac:	711d                	addi	sp,sp,-96
    800044ae:	ec86                	sd	ra,88(sp)
    800044b0:	e8a2                	sd	s0,80(sp)
    800044b2:	e4a6                	sd	s1,72(sp)
    800044b4:	e0ca                	sd	s2,64(sp)
    800044b6:	fc4e                	sd	s3,56(sp)
    800044b8:	f852                	sd	s4,48(sp)
    800044ba:	f456                	sd	s5,40(sp)
    800044bc:	f05a                	sd	s6,32(sp)
    800044be:	ec5e                	sd	s7,24(sp)
    800044c0:	e862                	sd	s8,16(sp)
    800044c2:	e466                	sd	s9,8(sp)
    800044c4:	1080                	addi	s0,sp,96
    800044c6:	84aa                	mv	s1,a0
    800044c8:	8b2e                	mv	s6,a1
    800044ca:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800044cc:	00054703          	lbu	a4,0(a0)
    800044d0:	02f00793          	li	a5,47
    800044d4:	02f70363          	beq	a4,a5,800044fa <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800044d8:	ffffe097          	auipc	ra,0xffffe
    800044dc:	984080e7          	jalr	-1660(ra) # 80001e5c <myproc>
    800044e0:	17053503          	ld	a0,368(a0)
    800044e4:	00000097          	auipc	ra,0x0
    800044e8:	9f6080e7          	jalr	-1546(ra) # 80003eda <idup>
    800044ec:	89aa                	mv	s3,a0
  while(*path == '/')
    800044ee:	02f00913          	li	s2,47
  len = path - s;
    800044f2:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800044f4:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800044f6:	4c05                	li	s8,1
    800044f8:	a865                	j	800045b0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800044fa:	4585                	li	a1,1
    800044fc:	4505                	li	a0,1
    800044fe:	fffff097          	auipc	ra,0xfffff
    80004502:	6e6080e7          	jalr	1766(ra) # 80003be4 <iget>
    80004506:	89aa                	mv	s3,a0
    80004508:	b7dd                	j	800044ee <namex+0x42>
      iunlockput(ip);
    8000450a:	854e                	mv	a0,s3
    8000450c:	00000097          	auipc	ra,0x0
    80004510:	c6e080e7          	jalr	-914(ra) # 8000417a <iunlockput>
      return 0;
    80004514:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004516:	854e                	mv	a0,s3
    80004518:	60e6                	ld	ra,88(sp)
    8000451a:	6446                	ld	s0,80(sp)
    8000451c:	64a6                	ld	s1,72(sp)
    8000451e:	6906                	ld	s2,64(sp)
    80004520:	79e2                	ld	s3,56(sp)
    80004522:	7a42                	ld	s4,48(sp)
    80004524:	7aa2                	ld	s5,40(sp)
    80004526:	7b02                	ld	s6,32(sp)
    80004528:	6be2                	ld	s7,24(sp)
    8000452a:	6c42                	ld	s8,16(sp)
    8000452c:	6ca2                	ld	s9,8(sp)
    8000452e:	6125                	addi	sp,sp,96
    80004530:	8082                	ret
      iunlock(ip);
    80004532:	854e                	mv	a0,s3
    80004534:	00000097          	auipc	ra,0x0
    80004538:	aa6080e7          	jalr	-1370(ra) # 80003fda <iunlock>
      return ip;
    8000453c:	bfe9                	j	80004516 <namex+0x6a>
      iunlockput(ip);
    8000453e:	854e                	mv	a0,s3
    80004540:	00000097          	auipc	ra,0x0
    80004544:	c3a080e7          	jalr	-966(ra) # 8000417a <iunlockput>
      return 0;
    80004548:	89d2                	mv	s3,s4
    8000454a:	b7f1                	j	80004516 <namex+0x6a>
  len = path - s;
    8000454c:	40b48633          	sub	a2,s1,a1
    80004550:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004554:	094cd463          	bge	s9,s4,800045dc <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004558:	4639                	li	a2,14
    8000455a:	8556                	mv	a0,s5
    8000455c:	ffffd097          	auipc	ra,0xffffd
    80004560:	816080e7          	jalr	-2026(ra) # 80000d72 <memmove>
  while(*path == '/')
    80004564:	0004c783          	lbu	a5,0(s1)
    80004568:	01279763          	bne	a5,s2,80004576 <namex+0xca>
    path++;
    8000456c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000456e:	0004c783          	lbu	a5,0(s1)
    80004572:	ff278de3          	beq	a5,s2,8000456c <namex+0xc0>
    ilock(ip);
    80004576:	854e                	mv	a0,s3
    80004578:	00000097          	auipc	ra,0x0
    8000457c:	9a0080e7          	jalr	-1632(ra) # 80003f18 <ilock>
    if(ip->type != T_DIR){
    80004580:	04499783          	lh	a5,68(s3)
    80004584:	f98793e3          	bne	a5,s8,8000450a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004588:	000b0563          	beqz	s6,80004592 <namex+0xe6>
    8000458c:	0004c783          	lbu	a5,0(s1)
    80004590:	d3cd                	beqz	a5,80004532 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004592:	865e                	mv	a2,s7
    80004594:	85d6                	mv	a1,s5
    80004596:	854e                	mv	a0,s3
    80004598:	00000097          	auipc	ra,0x0
    8000459c:	e64080e7          	jalr	-412(ra) # 800043fc <dirlookup>
    800045a0:	8a2a                	mv	s4,a0
    800045a2:	dd51                	beqz	a0,8000453e <namex+0x92>
    iunlockput(ip);
    800045a4:	854e                	mv	a0,s3
    800045a6:	00000097          	auipc	ra,0x0
    800045aa:	bd4080e7          	jalr	-1068(ra) # 8000417a <iunlockput>
    ip = next;
    800045ae:	89d2                	mv	s3,s4
  while(*path == '/')
    800045b0:	0004c783          	lbu	a5,0(s1)
    800045b4:	05279763          	bne	a5,s2,80004602 <namex+0x156>
    path++;
    800045b8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800045ba:	0004c783          	lbu	a5,0(s1)
    800045be:	ff278de3          	beq	a5,s2,800045b8 <namex+0x10c>
  if(*path == 0)
    800045c2:	c79d                	beqz	a5,800045f0 <namex+0x144>
    path++;
    800045c4:	85a6                	mv	a1,s1
  len = path - s;
    800045c6:	8a5e                	mv	s4,s7
    800045c8:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800045ca:	01278963          	beq	a5,s2,800045dc <namex+0x130>
    800045ce:	dfbd                	beqz	a5,8000454c <namex+0xa0>
    path++;
    800045d0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800045d2:	0004c783          	lbu	a5,0(s1)
    800045d6:	ff279ce3          	bne	a5,s2,800045ce <namex+0x122>
    800045da:	bf8d                	j	8000454c <namex+0xa0>
    memmove(name, s, len);
    800045dc:	2601                	sext.w	a2,a2
    800045de:	8556                	mv	a0,s5
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	792080e7          	jalr	1938(ra) # 80000d72 <memmove>
    name[len] = 0;
    800045e8:	9a56                	add	s4,s4,s5
    800045ea:	000a0023          	sb	zero,0(s4)
    800045ee:	bf9d                	j	80004564 <namex+0xb8>
  if(nameiparent){
    800045f0:	f20b03e3          	beqz	s6,80004516 <namex+0x6a>
    iput(ip);
    800045f4:	854e                	mv	a0,s3
    800045f6:	00000097          	auipc	ra,0x0
    800045fa:	adc080e7          	jalr	-1316(ra) # 800040d2 <iput>
    return 0;
    800045fe:	4981                	li	s3,0
    80004600:	bf19                	j	80004516 <namex+0x6a>
  if(*path == 0)
    80004602:	d7fd                	beqz	a5,800045f0 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004604:	0004c783          	lbu	a5,0(s1)
    80004608:	85a6                	mv	a1,s1
    8000460a:	b7d1                	j	800045ce <namex+0x122>

000000008000460c <dirlink>:
{
    8000460c:	7139                	addi	sp,sp,-64
    8000460e:	fc06                	sd	ra,56(sp)
    80004610:	f822                	sd	s0,48(sp)
    80004612:	f426                	sd	s1,40(sp)
    80004614:	f04a                	sd	s2,32(sp)
    80004616:	ec4e                	sd	s3,24(sp)
    80004618:	e852                	sd	s4,16(sp)
    8000461a:	0080                	addi	s0,sp,64
    8000461c:	892a                	mv	s2,a0
    8000461e:	8a2e                	mv	s4,a1
    80004620:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004622:	4601                	li	a2,0
    80004624:	00000097          	auipc	ra,0x0
    80004628:	dd8080e7          	jalr	-552(ra) # 800043fc <dirlookup>
    8000462c:	e93d                	bnez	a0,800046a2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000462e:	04c92483          	lw	s1,76(s2)
    80004632:	c49d                	beqz	s1,80004660 <dirlink+0x54>
    80004634:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004636:	4741                	li	a4,16
    80004638:	86a6                	mv	a3,s1
    8000463a:	fc040613          	addi	a2,s0,-64
    8000463e:	4581                	li	a1,0
    80004640:	854a                	mv	a0,s2
    80004642:	00000097          	auipc	ra,0x0
    80004646:	b8a080e7          	jalr	-1142(ra) # 800041cc <readi>
    8000464a:	47c1                	li	a5,16
    8000464c:	06f51163          	bne	a0,a5,800046ae <dirlink+0xa2>
    if(de.inum == 0)
    80004650:	fc045783          	lhu	a5,-64(s0)
    80004654:	c791                	beqz	a5,80004660 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004656:	24c1                	addiw	s1,s1,16
    80004658:	04c92783          	lw	a5,76(s2)
    8000465c:	fcf4ede3          	bltu	s1,a5,80004636 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004660:	4639                	li	a2,14
    80004662:	85d2                	mv	a1,s4
    80004664:	fc240513          	addi	a0,s0,-62
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	7be080e7          	jalr	1982(ra) # 80000e26 <strncpy>
  de.inum = inum;
    80004670:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004674:	4741                	li	a4,16
    80004676:	86a6                	mv	a3,s1
    80004678:	fc040613          	addi	a2,s0,-64
    8000467c:	4581                	li	a1,0
    8000467e:	854a                	mv	a0,s2
    80004680:	00000097          	auipc	ra,0x0
    80004684:	c44080e7          	jalr	-956(ra) # 800042c4 <writei>
    80004688:	872a                	mv	a4,a0
    8000468a:	47c1                	li	a5,16
  return 0;
    8000468c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000468e:	02f71863          	bne	a4,a5,800046be <dirlink+0xb2>
}
    80004692:	70e2                	ld	ra,56(sp)
    80004694:	7442                	ld	s0,48(sp)
    80004696:	74a2                	ld	s1,40(sp)
    80004698:	7902                	ld	s2,32(sp)
    8000469a:	69e2                	ld	s3,24(sp)
    8000469c:	6a42                	ld	s4,16(sp)
    8000469e:	6121                	addi	sp,sp,64
    800046a0:	8082                	ret
    iput(ip);
    800046a2:	00000097          	auipc	ra,0x0
    800046a6:	a30080e7          	jalr	-1488(ra) # 800040d2 <iput>
    return -1;
    800046aa:	557d                	li	a0,-1
    800046ac:	b7dd                	j	80004692 <dirlink+0x86>
      panic("dirlink read");
    800046ae:	00004517          	auipc	a0,0x4
    800046b2:	fa250513          	addi	a0,a0,-94 # 80008650 <syscalls+0x1d8>
    800046b6:	ffffc097          	auipc	ra,0xffffc
    800046ba:	e88080e7          	jalr	-376(ra) # 8000053e <panic>
    panic("dirlink");
    800046be:	00004517          	auipc	a0,0x4
    800046c2:	0a250513          	addi	a0,a0,162 # 80008760 <syscalls+0x2e8>
    800046c6:	ffffc097          	auipc	ra,0xffffc
    800046ca:	e78080e7          	jalr	-392(ra) # 8000053e <panic>

00000000800046ce <namei>:

struct inode*
namei(char *path)
{
    800046ce:	1101                	addi	sp,sp,-32
    800046d0:	ec06                	sd	ra,24(sp)
    800046d2:	e822                	sd	s0,16(sp)
    800046d4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800046d6:	fe040613          	addi	a2,s0,-32
    800046da:	4581                	li	a1,0
    800046dc:	00000097          	auipc	ra,0x0
    800046e0:	dd0080e7          	jalr	-560(ra) # 800044ac <namex>
}
    800046e4:	60e2                	ld	ra,24(sp)
    800046e6:	6442                	ld	s0,16(sp)
    800046e8:	6105                	addi	sp,sp,32
    800046ea:	8082                	ret

00000000800046ec <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800046ec:	1141                	addi	sp,sp,-16
    800046ee:	e406                	sd	ra,8(sp)
    800046f0:	e022                	sd	s0,0(sp)
    800046f2:	0800                	addi	s0,sp,16
    800046f4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800046f6:	4585                	li	a1,1
    800046f8:	00000097          	auipc	ra,0x0
    800046fc:	db4080e7          	jalr	-588(ra) # 800044ac <namex>
}
    80004700:	60a2                	ld	ra,8(sp)
    80004702:	6402                	ld	s0,0(sp)
    80004704:	0141                	addi	sp,sp,16
    80004706:	8082                	ret

0000000080004708 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004708:	1101                	addi	sp,sp,-32
    8000470a:	ec06                	sd	ra,24(sp)
    8000470c:	e822                	sd	s0,16(sp)
    8000470e:	e426                	sd	s1,8(sp)
    80004710:	e04a                	sd	s2,0(sp)
    80004712:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004714:	0001d917          	auipc	s2,0x1d
    80004718:	52490913          	addi	s2,s2,1316 # 80021c38 <log>
    8000471c:	01892583          	lw	a1,24(s2)
    80004720:	02892503          	lw	a0,40(s2)
    80004724:	fffff097          	auipc	ra,0xfffff
    80004728:	ff2080e7          	jalr	-14(ra) # 80003716 <bread>
    8000472c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000472e:	02c92683          	lw	a3,44(s2)
    80004732:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004734:	02d05763          	blez	a3,80004762 <write_head+0x5a>
    80004738:	0001d797          	auipc	a5,0x1d
    8000473c:	53078793          	addi	a5,a5,1328 # 80021c68 <log+0x30>
    80004740:	05c50713          	addi	a4,a0,92
    80004744:	36fd                	addiw	a3,a3,-1
    80004746:	1682                	slli	a3,a3,0x20
    80004748:	9281                	srli	a3,a3,0x20
    8000474a:	068a                	slli	a3,a3,0x2
    8000474c:	0001d617          	auipc	a2,0x1d
    80004750:	52060613          	addi	a2,a2,1312 # 80021c6c <log+0x34>
    80004754:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004756:	4390                	lw	a2,0(a5)
    80004758:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000475a:	0791                	addi	a5,a5,4
    8000475c:	0711                	addi	a4,a4,4
    8000475e:	fed79ce3          	bne	a5,a3,80004756 <write_head+0x4e>
  }
  bwrite(buf);
    80004762:	8526                	mv	a0,s1
    80004764:	fffff097          	auipc	ra,0xfffff
    80004768:	0a4080e7          	jalr	164(ra) # 80003808 <bwrite>
  brelse(buf);
    8000476c:	8526                	mv	a0,s1
    8000476e:	fffff097          	auipc	ra,0xfffff
    80004772:	0d8080e7          	jalr	216(ra) # 80003846 <brelse>
}
    80004776:	60e2                	ld	ra,24(sp)
    80004778:	6442                	ld	s0,16(sp)
    8000477a:	64a2                	ld	s1,8(sp)
    8000477c:	6902                	ld	s2,0(sp)
    8000477e:	6105                	addi	sp,sp,32
    80004780:	8082                	ret

0000000080004782 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004782:	0001d797          	auipc	a5,0x1d
    80004786:	4e27a783          	lw	a5,1250(a5) # 80021c64 <log+0x2c>
    8000478a:	0af05d63          	blez	a5,80004844 <install_trans+0xc2>
{
    8000478e:	7139                	addi	sp,sp,-64
    80004790:	fc06                	sd	ra,56(sp)
    80004792:	f822                	sd	s0,48(sp)
    80004794:	f426                	sd	s1,40(sp)
    80004796:	f04a                	sd	s2,32(sp)
    80004798:	ec4e                	sd	s3,24(sp)
    8000479a:	e852                	sd	s4,16(sp)
    8000479c:	e456                	sd	s5,8(sp)
    8000479e:	e05a                	sd	s6,0(sp)
    800047a0:	0080                	addi	s0,sp,64
    800047a2:	8b2a                	mv	s6,a0
    800047a4:	0001da97          	auipc	s5,0x1d
    800047a8:	4c4a8a93          	addi	s5,s5,1220 # 80021c68 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047ac:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800047ae:	0001d997          	auipc	s3,0x1d
    800047b2:	48a98993          	addi	s3,s3,1162 # 80021c38 <log>
    800047b6:	a035                	j	800047e2 <install_trans+0x60>
      bunpin(dbuf);
    800047b8:	8526                	mv	a0,s1
    800047ba:	fffff097          	auipc	ra,0xfffff
    800047be:	166080e7          	jalr	358(ra) # 80003920 <bunpin>
    brelse(lbuf);
    800047c2:	854a                	mv	a0,s2
    800047c4:	fffff097          	auipc	ra,0xfffff
    800047c8:	082080e7          	jalr	130(ra) # 80003846 <brelse>
    brelse(dbuf);
    800047cc:	8526                	mv	a0,s1
    800047ce:	fffff097          	auipc	ra,0xfffff
    800047d2:	078080e7          	jalr	120(ra) # 80003846 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047d6:	2a05                	addiw	s4,s4,1
    800047d8:	0a91                	addi	s5,s5,4
    800047da:	02c9a783          	lw	a5,44(s3)
    800047de:	04fa5963          	bge	s4,a5,80004830 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800047e2:	0189a583          	lw	a1,24(s3)
    800047e6:	014585bb          	addw	a1,a1,s4
    800047ea:	2585                	addiw	a1,a1,1
    800047ec:	0289a503          	lw	a0,40(s3)
    800047f0:	fffff097          	auipc	ra,0xfffff
    800047f4:	f26080e7          	jalr	-218(ra) # 80003716 <bread>
    800047f8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800047fa:	000aa583          	lw	a1,0(s5)
    800047fe:	0289a503          	lw	a0,40(s3)
    80004802:	fffff097          	auipc	ra,0xfffff
    80004806:	f14080e7          	jalr	-236(ra) # 80003716 <bread>
    8000480a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000480c:	40000613          	li	a2,1024
    80004810:	05890593          	addi	a1,s2,88
    80004814:	05850513          	addi	a0,a0,88
    80004818:	ffffc097          	auipc	ra,0xffffc
    8000481c:	55a080e7          	jalr	1370(ra) # 80000d72 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004820:	8526                	mv	a0,s1
    80004822:	fffff097          	auipc	ra,0xfffff
    80004826:	fe6080e7          	jalr	-26(ra) # 80003808 <bwrite>
    if(recovering == 0)
    8000482a:	f80b1ce3          	bnez	s6,800047c2 <install_trans+0x40>
    8000482e:	b769                	j	800047b8 <install_trans+0x36>
}
    80004830:	70e2                	ld	ra,56(sp)
    80004832:	7442                	ld	s0,48(sp)
    80004834:	74a2                	ld	s1,40(sp)
    80004836:	7902                	ld	s2,32(sp)
    80004838:	69e2                	ld	s3,24(sp)
    8000483a:	6a42                	ld	s4,16(sp)
    8000483c:	6aa2                	ld	s5,8(sp)
    8000483e:	6b02                	ld	s6,0(sp)
    80004840:	6121                	addi	sp,sp,64
    80004842:	8082                	ret
    80004844:	8082                	ret

0000000080004846 <initlog>:
{
    80004846:	7179                	addi	sp,sp,-48
    80004848:	f406                	sd	ra,40(sp)
    8000484a:	f022                	sd	s0,32(sp)
    8000484c:	ec26                	sd	s1,24(sp)
    8000484e:	e84a                	sd	s2,16(sp)
    80004850:	e44e                	sd	s3,8(sp)
    80004852:	1800                	addi	s0,sp,48
    80004854:	892a                	mv	s2,a0
    80004856:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004858:	0001d497          	auipc	s1,0x1d
    8000485c:	3e048493          	addi	s1,s1,992 # 80021c38 <log>
    80004860:	00004597          	auipc	a1,0x4
    80004864:	e0058593          	addi	a1,a1,-512 # 80008660 <syscalls+0x1e8>
    80004868:	8526                	mv	a0,s1
    8000486a:	ffffc097          	auipc	ra,0xffffc
    8000486e:	2ea080e7          	jalr	746(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004872:	0149a583          	lw	a1,20(s3)
    80004876:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004878:	0109a783          	lw	a5,16(s3)
    8000487c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000487e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004882:	854a                	mv	a0,s2
    80004884:	fffff097          	auipc	ra,0xfffff
    80004888:	e92080e7          	jalr	-366(ra) # 80003716 <bread>
  log.lh.n = lh->n;
    8000488c:	4d3c                	lw	a5,88(a0)
    8000488e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004890:	02f05563          	blez	a5,800048ba <initlog+0x74>
    80004894:	05c50713          	addi	a4,a0,92
    80004898:	0001d697          	auipc	a3,0x1d
    8000489c:	3d068693          	addi	a3,a3,976 # 80021c68 <log+0x30>
    800048a0:	37fd                	addiw	a5,a5,-1
    800048a2:	1782                	slli	a5,a5,0x20
    800048a4:	9381                	srli	a5,a5,0x20
    800048a6:	078a                	slli	a5,a5,0x2
    800048a8:	06050613          	addi	a2,a0,96
    800048ac:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800048ae:	4310                	lw	a2,0(a4)
    800048b0:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800048b2:	0711                	addi	a4,a4,4
    800048b4:	0691                	addi	a3,a3,4
    800048b6:	fef71ce3          	bne	a4,a5,800048ae <initlog+0x68>
  brelse(buf);
    800048ba:	fffff097          	auipc	ra,0xfffff
    800048be:	f8c080e7          	jalr	-116(ra) # 80003846 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800048c2:	4505                	li	a0,1
    800048c4:	00000097          	auipc	ra,0x0
    800048c8:	ebe080e7          	jalr	-322(ra) # 80004782 <install_trans>
  log.lh.n = 0;
    800048cc:	0001d797          	auipc	a5,0x1d
    800048d0:	3807ac23          	sw	zero,920(a5) # 80021c64 <log+0x2c>
  write_head(); // clear the log
    800048d4:	00000097          	auipc	ra,0x0
    800048d8:	e34080e7          	jalr	-460(ra) # 80004708 <write_head>
}
    800048dc:	70a2                	ld	ra,40(sp)
    800048de:	7402                	ld	s0,32(sp)
    800048e0:	64e2                	ld	s1,24(sp)
    800048e2:	6942                	ld	s2,16(sp)
    800048e4:	69a2                	ld	s3,8(sp)
    800048e6:	6145                	addi	sp,sp,48
    800048e8:	8082                	ret

00000000800048ea <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800048ea:	1101                	addi	sp,sp,-32
    800048ec:	ec06                	sd	ra,24(sp)
    800048ee:	e822                	sd	s0,16(sp)
    800048f0:	e426                	sd	s1,8(sp)
    800048f2:	e04a                	sd	s2,0(sp)
    800048f4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800048f6:	0001d517          	auipc	a0,0x1d
    800048fa:	34250513          	addi	a0,a0,834 # 80021c38 <log>
    800048fe:	ffffc097          	auipc	ra,0xffffc
    80004902:	2ee080e7          	jalr	750(ra) # 80000bec <acquire>
  while(1){
    if(log.committing){
    80004906:	0001d497          	auipc	s1,0x1d
    8000490a:	33248493          	addi	s1,s1,818 # 80021c38 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000490e:	4979                	li	s2,30
    80004910:	a039                	j	8000491e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004912:	85a6                	mv	a1,s1
    80004914:	8526                	mv	a0,s1
    80004916:	ffffe097          	auipc	ra,0xffffe
    8000491a:	df4080e7          	jalr	-524(ra) # 8000270a <sleep>
    if(log.committing){
    8000491e:	50dc                	lw	a5,36(s1)
    80004920:	fbed                	bnez	a5,80004912 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004922:	509c                	lw	a5,32(s1)
    80004924:	0017871b          	addiw	a4,a5,1
    80004928:	0007069b          	sext.w	a3,a4
    8000492c:	0027179b          	slliw	a5,a4,0x2
    80004930:	9fb9                	addw	a5,a5,a4
    80004932:	0017979b          	slliw	a5,a5,0x1
    80004936:	54d8                	lw	a4,44(s1)
    80004938:	9fb9                	addw	a5,a5,a4
    8000493a:	00f95963          	bge	s2,a5,8000494c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000493e:	85a6                	mv	a1,s1
    80004940:	8526                	mv	a0,s1
    80004942:	ffffe097          	auipc	ra,0xffffe
    80004946:	dc8080e7          	jalr	-568(ra) # 8000270a <sleep>
    8000494a:	bfd1                	j	8000491e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000494c:	0001d517          	auipc	a0,0x1d
    80004950:	2ec50513          	addi	a0,a0,748 # 80021c38 <log>
    80004954:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004956:	ffffc097          	auipc	ra,0xffffc
    8000495a:	362080e7          	jalr	866(ra) # 80000cb8 <release>
      break;
    }
  }
}
    8000495e:	60e2                	ld	ra,24(sp)
    80004960:	6442                	ld	s0,16(sp)
    80004962:	64a2                	ld	s1,8(sp)
    80004964:	6902                	ld	s2,0(sp)
    80004966:	6105                	addi	sp,sp,32
    80004968:	8082                	ret

000000008000496a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000496a:	7139                	addi	sp,sp,-64
    8000496c:	fc06                	sd	ra,56(sp)
    8000496e:	f822                	sd	s0,48(sp)
    80004970:	f426                	sd	s1,40(sp)
    80004972:	f04a                	sd	s2,32(sp)
    80004974:	ec4e                	sd	s3,24(sp)
    80004976:	e852                	sd	s4,16(sp)
    80004978:	e456                	sd	s5,8(sp)
    8000497a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000497c:	0001d497          	auipc	s1,0x1d
    80004980:	2bc48493          	addi	s1,s1,700 # 80021c38 <log>
    80004984:	8526                	mv	a0,s1
    80004986:	ffffc097          	auipc	ra,0xffffc
    8000498a:	266080e7          	jalr	614(ra) # 80000bec <acquire>
  log.outstanding -= 1;
    8000498e:	509c                	lw	a5,32(s1)
    80004990:	37fd                	addiw	a5,a5,-1
    80004992:	0007891b          	sext.w	s2,a5
    80004996:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004998:	50dc                	lw	a5,36(s1)
    8000499a:	efb9                	bnez	a5,800049f8 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000499c:	06091663          	bnez	s2,80004a08 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800049a0:	0001d497          	auipc	s1,0x1d
    800049a4:	29848493          	addi	s1,s1,664 # 80021c38 <log>
    800049a8:	4785                	li	a5,1
    800049aa:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800049ac:	8526                	mv	a0,s1
    800049ae:	ffffc097          	auipc	ra,0xffffc
    800049b2:	30a080e7          	jalr	778(ra) # 80000cb8 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800049b6:	54dc                	lw	a5,44(s1)
    800049b8:	06f04763          	bgtz	a5,80004a26 <end_op+0xbc>
    acquire(&log.lock);
    800049bc:	0001d497          	auipc	s1,0x1d
    800049c0:	27c48493          	addi	s1,s1,636 # 80021c38 <log>
    800049c4:	8526                	mv	a0,s1
    800049c6:	ffffc097          	auipc	ra,0xffffc
    800049ca:	226080e7          	jalr	550(ra) # 80000bec <acquire>
    log.committing = 0;
    800049ce:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800049d2:	8526                	mv	a0,s1
    800049d4:	ffffe097          	auipc	ra,0xffffe
    800049d8:	fb4080e7          	jalr	-76(ra) # 80002988 <wakeup>
    release(&log.lock);
    800049dc:	8526                	mv	a0,s1
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	2da080e7          	jalr	730(ra) # 80000cb8 <release>
}
    800049e6:	70e2                	ld	ra,56(sp)
    800049e8:	7442                	ld	s0,48(sp)
    800049ea:	74a2                	ld	s1,40(sp)
    800049ec:	7902                	ld	s2,32(sp)
    800049ee:	69e2                	ld	s3,24(sp)
    800049f0:	6a42                	ld	s4,16(sp)
    800049f2:	6aa2                	ld	s5,8(sp)
    800049f4:	6121                	addi	sp,sp,64
    800049f6:	8082                	ret
    panic("log.committing");
    800049f8:	00004517          	auipc	a0,0x4
    800049fc:	c7050513          	addi	a0,a0,-912 # 80008668 <syscalls+0x1f0>
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	b3e080e7          	jalr	-1218(ra) # 8000053e <panic>
    wakeup(&log);
    80004a08:	0001d497          	auipc	s1,0x1d
    80004a0c:	23048493          	addi	s1,s1,560 # 80021c38 <log>
    80004a10:	8526                	mv	a0,s1
    80004a12:	ffffe097          	auipc	ra,0xffffe
    80004a16:	f76080e7          	jalr	-138(ra) # 80002988 <wakeup>
  release(&log.lock);
    80004a1a:	8526                	mv	a0,s1
    80004a1c:	ffffc097          	auipc	ra,0xffffc
    80004a20:	29c080e7          	jalr	668(ra) # 80000cb8 <release>
  if(do_commit){
    80004a24:	b7c9                	j	800049e6 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a26:	0001da97          	auipc	s5,0x1d
    80004a2a:	242a8a93          	addi	s5,s5,578 # 80021c68 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004a2e:	0001da17          	auipc	s4,0x1d
    80004a32:	20aa0a13          	addi	s4,s4,522 # 80021c38 <log>
    80004a36:	018a2583          	lw	a1,24(s4)
    80004a3a:	012585bb          	addw	a1,a1,s2
    80004a3e:	2585                	addiw	a1,a1,1
    80004a40:	028a2503          	lw	a0,40(s4)
    80004a44:	fffff097          	auipc	ra,0xfffff
    80004a48:	cd2080e7          	jalr	-814(ra) # 80003716 <bread>
    80004a4c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004a4e:	000aa583          	lw	a1,0(s5)
    80004a52:	028a2503          	lw	a0,40(s4)
    80004a56:	fffff097          	auipc	ra,0xfffff
    80004a5a:	cc0080e7          	jalr	-832(ra) # 80003716 <bread>
    80004a5e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004a60:	40000613          	li	a2,1024
    80004a64:	05850593          	addi	a1,a0,88
    80004a68:	05848513          	addi	a0,s1,88
    80004a6c:	ffffc097          	auipc	ra,0xffffc
    80004a70:	306080e7          	jalr	774(ra) # 80000d72 <memmove>
    bwrite(to);  // write the log
    80004a74:	8526                	mv	a0,s1
    80004a76:	fffff097          	auipc	ra,0xfffff
    80004a7a:	d92080e7          	jalr	-622(ra) # 80003808 <bwrite>
    brelse(from);
    80004a7e:	854e                	mv	a0,s3
    80004a80:	fffff097          	auipc	ra,0xfffff
    80004a84:	dc6080e7          	jalr	-570(ra) # 80003846 <brelse>
    brelse(to);
    80004a88:	8526                	mv	a0,s1
    80004a8a:	fffff097          	auipc	ra,0xfffff
    80004a8e:	dbc080e7          	jalr	-580(ra) # 80003846 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a92:	2905                	addiw	s2,s2,1
    80004a94:	0a91                	addi	s5,s5,4
    80004a96:	02ca2783          	lw	a5,44(s4)
    80004a9a:	f8f94ee3          	blt	s2,a5,80004a36 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004a9e:	00000097          	auipc	ra,0x0
    80004aa2:	c6a080e7          	jalr	-918(ra) # 80004708 <write_head>
    install_trans(0); // Now install writes to home locations
    80004aa6:	4501                	li	a0,0
    80004aa8:	00000097          	auipc	ra,0x0
    80004aac:	cda080e7          	jalr	-806(ra) # 80004782 <install_trans>
    log.lh.n = 0;
    80004ab0:	0001d797          	auipc	a5,0x1d
    80004ab4:	1a07aa23          	sw	zero,436(a5) # 80021c64 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004ab8:	00000097          	auipc	ra,0x0
    80004abc:	c50080e7          	jalr	-944(ra) # 80004708 <write_head>
    80004ac0:	bdf5                	j	800049bc <end_op+0x52>

0000000080004ac2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004ac2:	1101                	addi	sp,sp,-32
    80004ac4:	ec06                	sd	ra,24(sp)
    80004ac6:	e822                	sd	s0,16(sp)
    80004ac8:	e426                	sd	s1,8(sp)
    80004aca:	e04a                	sd	s2,0(sp)
    80004acc:	1000                	addi	s0,sp,32
    80004ace:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004ad0:	0001d917          	auipc	s2,0x1d
    80004ad4:	16890913          	addi	s2,s2,360 # 80021c38 <log>
    80004ad8:	854a                	mv	a0,s2
    80004ada:	ffffc097          	auipc	ra,0xffffc
    80004ade:	112080e7          	jalr	274(ra) # 80000bec <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004ae2:	02c92603          	lw	a2,44(s2)
    80004ae6:	47f5                	li	a5,29
    80004ae8:	06c7c563          	blt	a5,a2,80004b52 <log_write+0x90>
    80004aec:	0001d797          	auipc	a5,0x1d
    80004af0:	1687a783          	lw	a5,360(a5) # 80021c54 <log+0x1c>
    80004af4:	37fd                	addiw	a5,a5,-1
    80004af6:	04f65e63          	bge	a2,a5,80004b52 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004afa:	0001d797          	auipc	a5,0x1d
    80004afe:	15e7a783          	lw	a5,350(a5) # 80021c58 <log+0x20>
    80004b02:	06f05063          	blez	a5,80004b62 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004b06:	4781                	li	a5,0
    80004b08:	06c05563          	blez	a2,80004b72 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004b0c:	44cc                	lw	a1,12(s1)
    80004b0e:	0001d717          	auipc	a4,0x1d
    80004b12:	15a70713          	addi	a4,a4,346 # 80021c68 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004b16:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004b18:	4314                	lw	a3,0(a4)
    80004b1a:	04b68c63          	beq	a3,a1,80004b72 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004b1e:	2785                	addiw	a5,a5,1
    80004b20:	0711                	addi	a4,a4,4
    80004b22:	fef61be3          	bne	a2,a5,80004b18 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004b26:	0621                	addi	a2,a2,8
    80004b28:	060a                	slli	a2,a2,0x2
    80004b2a:	0001d797          	auipc	a5,0x1d
    80004b2e:	10e78793          	addi	a5,a5,270 # 80021c38 <log>
    80004b32:	963e                	add	a2,a2,a5
    80004b34:	44dc                	lw	a5,12(s1)
    80004b36:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004b38:	8526                	mv	a0,s1
    80004b3a:	fffff097          	auipc	ra,0xfffff
    80004b3e:	daa080e7          	jalr	-598(ra) # 800038e4 <bpin>
    log.lh.n++;
    80004b42:	0001d717          	auipc	a4,0x1d
    80004b46:	0f670713          	addi	a4,a4,246 # 80021c38 <log>
    80004b4a:	575c                	lw	a5,44(a4)
    80004b4c:	2785                	addiw	a5,a5,1
    80004b4e:	d75c                	sw	a5,44(a4)
    80004b50:	a835                	j	80004b8c <log_write+0xca>
    panic("too big a transaction");
    80004b52:	00004517          	auipc	a0,0x4
    80004b56:	b2650513          	addi	a0,a0,-1242 # 80008678 <syscalls+0x200>
    80004b5a:	ffffc097          	auipc	ra,0xffffc
    80004b5e:	9e4080e7          	jalr	-1564(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004b62:	00004517          	auipc	a0,0x4
    80004b66:	b2e50513          	addi	a0,a0,-1234 # 80008690 <syscalls+0x218>
    80004b6a:	ffffc097          	auipc	ra,0xffffc
    80004b6e:	9d4080e7          	jalr	-1580(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004b72:	00878713          	addi	a4,a5,8
    80004b76:	00271693          	slli	a3,a4,0x2
    80004b7a:	0001d717          	auipc	a4,0x1d
    80004b7e:	0be70713          	addi	a4,a4,190 # 80021c38 <log>
    80004b82:	9736                	add	a4,a4,a3
    80004b84:	44d4                	lw	a3,12(s1)
    80004b86:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004b88:	faf608e3          	beq	a2,a5,80004b38 <log_write+0x76>
  }
  release(&log.lock);
    80004b8c:	0001d517          	auipc	a0,0x1d
    80004b90:	0ac50513          	addi	a0,a0,172 # 80021c38 <log>
    80004b94:	ffffc097          	auipc	ra,0xffffc
    80004b98:	124080e7          	jalr	292(ra) # 80000cb8 <release>
}
    80004b9c:	60e2                	ld	ra,24(sp)
    80004b9e:	6442                	ld	s0,16(sp)
    80004ba0:	64a2                	ld	s1,8(sp)
    80004ba2:	6902                	ld	s2,0(sp)
    80004ba4:	6105                	addi	sp,sp,32
    80004ba6:	8082                	ret

0000000080004ba8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004ba8:	1101                	addi	sp,sp,-32
    80004baa:	ec06                	sd	ra,24(sp)
    80004bac:	e822                	sd	s0,16(sp)
    80004bae:	e426                	sd	s1,8(sp)
    80004bb0:	e04a                	sd	s2,0(sp)
    80004bb2:	1000                	addi	s0,sp,32
    80004bb4:	84aa                	mv	s1,a0
    80004bb6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004bb8:	00004597          	auipc	a1,0x4
    80004bbc:	af858593          	addi	a1,a1,-1288 # 800086b0 <syscalls+0x238>
    80004bc0:	0521                	addi	a0,a0,8
    80004bc2:	ffffc097          	auipc	ra,0xffffc
    80004bc6:	f92080e7          	jalr	-110(ra) # 80000b54 <initlock>
  lk->name = name;
    80004bca:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004bce:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004bd2:	0204a423          	sw	zero,40(s1)
}
    80004bd6:	60e2                	ld	ra,24(sp)
    80004bd8:	6442                	ld	s0,16(sp)
    80004bda:	64a2                	ld	s1,8(sp)
    80004bdc:	6902                	ld	s2,0(sp)
    80004bde:	6105                	addi	sp,sp,32
    80004be0:	8082                	ret

0000000080004be2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004be2:	1101                	addi	sp,sp,-32
    80004be4:	ec06                	sd	ra,24(sp)
    80004be6:	e822                	sd	s0,16(sp)
    80004be8:	e426                	sd	s1,8(sp)
    80004bea:	e04a                	sd	s2,0(sp)
    80004bec:	1000                	addi	s0,sp,32
    80004bee:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004bf0:	00850913          	addi	s2,a0,8
    80004bf4:	854a                	mv	a0,s2
    80004bf6:	ffffc097          	auipc	ra,0xffffc
    80004bfa:	ff6080e7          	jalr	-10(ra) # 80000bec <acquire>
  while (lk->locked) {
    80004bfe:	409c                	lw	a5,0(s1)
    80004c00:	cb89                	beqz	a5,80004c12 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004c02:	85ca                	mv	a1,s2
    80004c04:	8526                	mv	a0,s1
    80004c06:	ffffe097          	auipc	ra,0xffffe
    80004c0a:	b04080e7          	jalr	-1276(ra) # 8000270a <sleep>
  while (lk->locked) {
    80004c0e:	409c                	lw	a5,0(s1)
    80004c10:	fbed                	bnez	a5,80004c02 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004c12:	4785                	li	a5,1
    80004c14:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004c16:	ffffd097          	auipc	ra,0xffffd
    80004c1a:	246080e7          	jalr	582(ra) # 80001e5c <myproc>
    80004c1e:	591c                	lw	a5,48(a0)
    80004c20:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004c22:	854a                	mv	a0,s2
    80004c24:	ffffc097          	auipc	ra,0xffffc
    80004c28:	094080e7          	jalr	148(ra) # 80000cb8 <release>
}
    80004c2c:	60e2                	ld	ra,24(sp)
    80004c2e:	6442                	ld	s0,16(sp)
    80004c30:	64a2                	ld	s1,8(sp)
    80004c32:	6902                	ld	s2,0(sp)
    80004c34:	6105                	addi	sp,sp,32
    80004c36:	8082                	ret

0000000080004c38 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004c38:	1101                	addi	sp,sp,-32
    80004c3a:	ec06                	sd	ra,24(sp)
    80004c3c:	e822                	sd	s0,16(sp)
    80004c3e:	e426                	sd	s1,8(sp)
    80004c40:	e04a                	sd	s2,0(sp)
    80004c42:	1000                	addi	s0,sp,32
    80004c44:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c46:	00850913          	addi	s2,a0,8
    80004c4a:	854a                	mv	a0,s2
    80004c4c:	ffffc097          	auipc	ra,0xffffc
    80004c50:	fa0080e7          	jalr	-96(ra) # 80000bec <acquire>
  lk->locked = 0;
    80004c54:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c58:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004c5c:	8526                	mv	a0,s1
    80004c5e:	ffffe097          	auipc	ra,0xffffe
    80004c62:	d2a080e7          	jalr	-726(ra) # 80002988 <wakeup>
  release(&lk->lk);
    80004c66:	854a                	mv	a0,s2
    80004c68:	ffffc097          	auipc	ra,0xffffc
    80004c6c:	050080e7          	jalr	80(ra) # 80000cb8 <release>
}
    80004c70:	60e2                	ld	ra,24(sp)
    80004c72:	6442                	ld	s0,16(sp)
    80004c74:	64a2                	ld	s1,8(sp)
    80004c76:	6902                	ld	s2,0(sp)
    80004c78:	6105                	addi	sp,sp,32
    80004c7a:	8082                	ret

0000000080004c7c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004c7c:	7179                	addi	sp,sp,-48
    80004c7e:	f406                	sd	ra,40(sp)
    80004c80:	f022                	sd	s0,32(sp)
    80004c82:	ec26                	sd	s1,24(sp)
    80004c84:	e84a                	sd	s2,16(sp)
    80004c86:	e44e                	sd	s3,8(sp)
    80004c88:	1800                	addi	s0,sp,48
    80004c8a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004c8c:	00850913          	addi	s2,a0,8
    80004c90:	854a                	mv	a0,s2
    80004c92:	ffffc097          	auipc	ra,0xffffc
    80004c96:	f5a080e7          	jalr	-166(ra) # 80000bec <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c9a:	409c                	lw	a5,0(s1)
    80004c9c:	ef99                	bnez	a5,80004cba <holdingsleep+0x3e>
    80004c9e:	4481                	li	s1,0
  release(&lk->lk);
    80004ca0:	854a                	mv	a0,s2
    80004ca2:	ffffc097          	auipc	ra,0xffffc
    80004ca6:	016080e7          	jalr	22(ra) # 80000cb8 <release>
  return r;
}
    80004caa:	8526                	mv	a0,s1
    80004cac:	70a2                	ld	ra,40(sp)
    80004cae:	7402                	ld	s0,32(sp)
    80004cb0:	64e2                	ld	s1,24(sp)
    80004cb2:	6942                	ld	s2,16(sp)
    80004cb4:	69a2                	ld	s3,8(sp)
    80004cb6:	6145                	addi	sp,sp,48
    80004cb8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004cba:	0284a983          	lw	s3,40(s1)
    80004cbe:	ffffd097          	auipc	ra,0xffffd
    80004cc2:	19e080e7          	jalr	414(ra) # 80001e5c <myproc>
    80004cc6:	5904                	lw	s1,48(a0)
    80004cc8:	413484b3          	sub	s1,s1,s3
    80004ccc:	0014b493          	seqz	s1,s1
    80004cd0:	bfc1                	j	80004ca0 <holdingsleep+0x24>

0000000080004cd2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004cd2:	1141                	addi	sp,sp,-16
    80004cd4:	e406                	sd	ra,8(sp)
    80004cd6:	e022                	sd	s0,0(sp)
    80004cd8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004cda:	00004597          	auipc	a1,0x4
    80004cde:	9e658593          	addi	a1,a1,-1562 # 800086c0 <syscalls+0x248>
    80004ce2:	0001d517          	auipc	a0,0x1d
    80004ce6:	09e50513          	addi	a0,a0,158 # 80021d80 <ftable>
    80004cea:	ffffc097          	auipc	ra,0xffffc
    80004cee:	e6a080e7          	jalr	-406(ra) # 80000b54 <initlock>
}
    80004cf2:	60a2                	ld	ra,8(sp)
    80004cf4:	6402                	ld	s0,0(sp)
    80004cf6:	0141                	addi	sp,sp,16
    80004cf8:	8082                	ret

0000000080004cfa <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004cfa:	1101                	addi	sp,sp,-32
    80004cfc:	ec06                	sd	ra,24(sp)
    80004cfe:	e822                	sd	s0,16(sp)
    80004d00:	e426                	sd	s1,8(sp)
    80004d02:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004d04:	0001d517          	auipc	a0,0x1d
    80004d08:	07c50513          	addi	a0,a0,124 # 80021d80 <ftable>
    80004d0c:	ffffc097          	auipc	ra,0xffffc
    80004d10:	ee0080e7          	jalr	-288(ra) # 80000bec <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d14:	0001d497          	auipc	s1,0x1d
    80004d18:	08448493          	addi	s1,s1,132 # 80021d98 <ftable+0x18>
    80004d1c:	0001e717          	auipc	a4,0x1e
    80004d20:	01c70713          	addi	a4,a4,28 # 80022d38 <ftable+0xfb8>
    if(f->ref == 0){
    80004d24:	40dc                	lw	a5,4(s1)
    80004d26:	cf99                	beqz	a5,80004d44 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d28:	02848493          	addi	s1,s1,40
    80004d2c:	fee49ce3          	bne	s1,a4,80004d24 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004d30:	0001d517          	auipc	a0,0x1d
    80004d34:	05050513          	addi	a0,a0,80 # 80021d80 <ftable>
    80004d38:	ffffc097          	auipc	ra,0xffffc
    80004d3c:	f80080e7          	jalr	-128(ra) # 80000cb8 <release>
  return 0;
    80004d40:	4481                	li	s1,0
    80004d42:	a819                	j	80004d58 <filealloc+0x5e>
      f->ref = 1;
    80004d44:	4785                	li	a5,1
    80004d46:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004d48:	0001d517          	auipc	a0,0x1d
    80004d4c:	03850513          	addi	a0,a0,56 # 80021d80 <ftable>
    80004d50:	ffffc097          	auipc	ra,0xffffc
    80004d54:	f68080e7          	jalr	-152(ra) # 80000cb8 <release>
}
    80004d58:	8526                	mv	a0,s1
    80004d5a:	60e2                	ld	ra,24(sp)
    80004d5c:	6442                	ld	s0,16(sp)
    80004d5e:	64a2                	ld	s1,8(sp)
    80004d60:	6105                	addi	sp,sp,32
    80004d62:	8082                	ret

0000000080004d64 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004d64:	1101                	addi	sp,sp,-32
    80004d66:	ec06                	sd	ra,24(sp)
    80004d68:	e822                	sd	s0,16(sp)
    80004d6a:	e426                	sd	s1,8(sp)
    80004d6c:	1000                	addi	s0,sp,32
    80004d6e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004d70:	0001d517          	auipc	a0,0x1d
    80004d74:	01050513          	addi	a0,a0,16 # 80021d80 <ftable>
    80004d78:	ffffc097          	auipc	ra,0xffffc
    80004d7c:	e74080e7          	jalr	-396(ra) # 80000bec <acquire>
  if(f->ref < 1)
    80004d80:	40dc                	lw	a5,4(s1)
    80004d82:	02f05263          	blez	a5,80004da6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004d86:	2785                	addiw	a5,a5,1
    80004d88:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004d8a:	0001d517          	auipc	a0,0x1d
    80004d8e:	ff650513          	addi	a0,a0,-10 # 80021d80 <ftable>
    80004d92:	ffffc097          	auipc	ra,0xffffc
    80004d96:	f26080e7          	jalr	-218(ra) # 80000cb8 <release>
  return f;
}
    80004d9a:	8526                	mv	a0,s1
    80004d9c:	60e2                	ld	ra,24(sp)
    80004d9e:	6442                	ld	s0,16(sp)
    80004da0:	64a2                	ld	s1,8(sp)
    80004da2:	6105                	addi	sp,sp,32
    80004da4:	8082                	ret
    panic("filedup");
    80004da6:	00004517          	auipc	a0,0x4
    80004daa:	92250513          	addi	a0,a0,-1758 # 800086c8 <syscalls+0x250>
    80004dae:	ffffb097          	auipc	ra,0xffffb
    80004db2:	790080e7          	jalr	1936(ra) # 8000053e <panic>

0000000080004db6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004db6:	7139                	addi	sp,sp,-64
    80004db8:	fc06                	sd	ra,56(sp)
    80004dba:	f822                	sd	s0,48(sp)
    80004dbc:	f426                	sd	s1,40(sp)
    80004dbe:	f04a                	sd	s2,32(sp)
    80004dc0:	ec4e                	sd	s3,24(sp)
    80004dc2:	e852                	sd	s4,16(sp)
    80004dc4:	e456                	sd	s5,8(sp)
    80004dc6:	0080                	addi	s0,sp,64
    80004dc8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004dca:	0001d517          	auipc	a0,0x1d
    80004dce:	fb650513          	addi	a0,a0,-74 # 80021d80 <ftable>
    80004dd2:	ffffc097          	auipc	ra,0xffffc
    80004dd6:	e1a080e7          	jalr	-486(ra) # 80000bec <acquire>
  if(f->ref < 1)
    80004dda:	40dc                	lw	a5,4(s1)
    80004ddc:	06f05163          	blez	a5,80004e3e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004de0:	37fd                	addiw	a5,a5,-1
    80004de2:	0007871b          	sext.w	a4,a5
    80004de6:	c0dc                	sw	a5,4(s1)
    80004de8:	06e04363          	bgtz	a4,80004e4e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004dec:	0004a903          	lw	s2,0(s1)
    80004df0:	0094ca83          	lbu	s5,9(s1)
    80004df4:	0104ba03          	ld	s4,16(s1)
    80004df8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004dfc:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004e00:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004e04:	0001d517          	auipc	a0,0x1d
    80004e08:	f7c50513          	addi	a0,a0,-132 # 80021d80 <ftable>
    80004e0c:	ffffc097          	auipc	ra,0xffffc
    80004e10:	eac080e7          	jalr	-340(ra) # 80000cb8 <release>

  if(ff.type == FD_PIPE){
    80004e14:	4785                	li	a5,1
    80004e16:	04f90d63          	beq	s2,a5,80004e70 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004e1a:	3979                	addiw	s2,s2,-2
    80004e1c:	4785                	li	a5,1
    80004e1e:	0527e063          	bltu	a5,s2,80004e5e <fileclose+0xa8>
    begin_op();
    80004e22:	00000097          	auipc	ra,0x0
    80004e26:	ac8080e7          	jalr	-1336(ra) # 800048ea <begin_op>
    iput(ff.ip);
    80004e2a:	854e                	mv	a0,s3
    80004e2c:	fffff097          	auipc	ra,0xfffff
    80004e30:	2a6080e7          	jalr	678(ra) # 800040d2 <iput>
    end_op();
    80004e34:	00000097          	auipc	ra,0x0
    80004e38:	b36080e7          	jalr	-1226(ra) # 8000496a <end_op>
    80004e3c:	a00d                	j	80004e5e <fileclose+0xa8>
    panic("fileclose");
    80004e3e:	00004517          	auipc	a0,0x4
    80004e42:	89250513          	addi	a0,a0,-1902 # 800086d0 <syscalls+0x258>
    80004e46:	ffffb097          	auipc	ra,0xffffb
    80004e4a:	6f8080e7          	jalr	1784(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004e4e:	0001d517          	auipc	a0,0x1d
    80004e52:	f3250513          	addi	a0,a0,-206 # 80021d80 <ftable>
    80004e56:	ffffc097          	auipc	ra,0xffffc
    80004e5a:	e62080e7          	jalr	-414(ra) # 80000cb8 <release>
  }
}
    80004e5e:	70e2                	ld	ra,56(sp)
    80004e60:	7442                	ld	s0,48(sp)
    80004e62:	74a2                	ld	s1,40(sp)
    80004e64:	7902                	ld	s2,32(sp)
    80004e66:	69e2                	ld	s3,24(sp)
    80004e68:	6a42                	ld	s4,16(sp)
    80004e6a:	6aa2                	ld	s5,8(sp)
    80004e6c:	6121                	addi	sp,sp,64
    80004e6e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004e70:	85d6                	mv	a1,s5
    80004e72:	8552                	mv	a0,s4
    80004e74:	00000097          	auipc	ra,0x0
    80004e78:	34c080e7          	jalr	844(ra) # 800051c0 <pipeclose>
    80004e7c:	b7cd                	j	80004e5e <fileclose+0xa8>

0000000080004e7e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004e7e:	715d                	addi	sp,sp,-80
    80004e80:	e486                	sd	ra,72(sp)
    80004e82:	e0a2                	sd	s0,64(sp)
    80004e84:	fc26                	sd	s1,56(sp)
    80004e86:	f84a                	sd	s2,48(sp)
    80004e88:	f44e                	sd	s3,40(sp)
    80004e8a:	0880                	addi	s0,sp,80
    80004e8c:	84aa                	mv	s1,a0
    80004e8e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004e90:	ffffd097          	auipc	ra,0xffffd
    80004e94:	fcc080e7          	jalr	-52(ra) # 80001e5c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004e98:	409c                	lw	a5,0(s1)
    80004e9a:	37f9                	addiw	a5,a5,-2
    80004e9c:	4705                	li	a4,1
    80004e9e:	04f76763          	bltu	a4,a5,80004eec <filestat+0x6e>
    80004ea2:	892a                	mv	s2,a0
    ilock(f->ip);
    80004ea4:	6c88                	ld	a0,24(s1)
    80004ea6:	fffff097          	auipc	ra,0xfffff
    80004eaa:	072080e7          	jalr	114(ra) # 80003f18 <ilock>
    stati(f->ip, &st);
    80004eae:	fb840593          	addi	a1,s0,-72
    80004eb2:	6c88                	ld	a0,24(s1)
    80004eb4:	fffff097          	auipc	ra,0xfffff
    80004eb8:	2ee080e7          	jalr	750(ra) # 800041a2 <stati>
    iunlock(f->ip);
    80004ebc:	6c88                	ld	a0,24(s1)
    80004ebe:	fffff097          	auipc	ra,0xfffff
    80004ec2:	11c080e7          	jalr	284(ra) # 80003fda <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004ec6:	46e1                	li	a3,24
    80004ec8:	fb840613          	addi	a2,s0,-72
    80004ecc:	85ce                	mv	a1,s3
    80004ece:	07093503          	ld	a0,112(s2)
    80004ed2:	ffffc097          	auipc	ra,0xffffc
    80004ed6:	7d2080e7          	jalr	2002(ra) # 800016a4 <copyout>
    80004eda:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ede:	60a6                	ld	ra,72(sp)
    80004ee0:	6406                	ld	s0,64(sp)
    80004ee2:	74e2                	ld	s1,56(sp)
    80004ee4:	7942                	ld	s2,48(sp)
    80004ee6:	79a2                	ld	s3,40(sp)
    80004ee8:	6161                	addi	sp,sp,80
    80004eea:	8082                	ret
  return -1;
    80004eec:	557d                	li	a0,-1
    80004eee:	bfc5                	j	80004ede <filestat+0x60>

0000000080004ef0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ef0:	7179                	addi	sp,sp,-48
    80004ef2:	f406                	sd	ra,40(sp)
    80004ef4:	f022                	sd	s0,32(sp)
    80004ef6:	ec26                	sd	s1,24(sp)
    80004ef8:	e84a                	sd	s2,16(sp)
    80004efa:	e44e                	sd	s3,8(sp)
    80004efc:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004efe:	00854783          	lbu	a5,8(a0)
    80004f02:	c3d5                	beqz	a5,80004fa6 <fileread+0xb6>
    80004f04:	84aa                	mv	s1,a0
    80004f06:	89ae                	mv	s3,a1
    80004f08:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f0a:	411c                	lw	a5,0(a0)
    80004f0c:	4705                	li	a4,1
    80004f0e:	04e78963          	beq	a5,a4,80004f60 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f12:	470d                	li	a4,3
    80004f14:	04e78d63          	beq	a5,a4,80004f6e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f18:	4709                	li	a4,2
    80004f1a:	06e79e63          	bne	a5,a4,80004f96 <fileread+0xa6>
    ilock(f->ip);
    80004f1e:	6d08                	ld	a0,24(a0)
    80004f20:	fffff097          	auipc	ra,0xfffff
    80004f24:	ff8080e7          	jalr	-8(ra) # 80003f18 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004f28:	874a                	mv	a4,s2
    80004f2a:	5094                	lw	a3,32(s1)
    80004f2c:	864e                	mv	a2,s3
    80004f2e:	4585                	li	a1,1
    80004f30:	6c88                	ld	a0,24(s1)
    80004f32:	fffff097          	auipc	ra,0xfffff
    80004f36:	29a080e7          	jalr	666(ra) # 800041cc <readi>
    80004f3a:	892a                	mv	s2,a0
    80004f3c:	00a05563          	blez	a0,80004f46 <fileread+0x56>
      f->off += r;
    80004f40:	509c                	lw	a5,32(s1)
    80004f42:	9fa9                	addw	a5,a5,a0
    80004f44:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004f46:	6c88                	ld	a0,24(s1)
    80004f48:	fffff097          	auipc	ra,0xfffff
    80004f4c:	092080e7          	jalr	146(ra) # 80003fda <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004f50:	854a                	mv	a0,s2
    80004f52:	70a2                	ld	ra,40(sp)
    80004f54:	7402                	ld	s0,32(sp)
    80004f56:	64e2                	ld	s1,24(sp)
    80004f58:	6942                	ld	s2,16(sp)
    80004f5a:	69a2                	ld	s3,8(sp)
    80004f5c:	6145                	addi	sp,sp,48
    80004f5e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004f60:	6908                	ld	a0,16(a0)
    80004f62:	00000097          	auipc	ra,0x0
    80004f66:	3c8080e7          	jalr	968(ra) # 8000532a <piperead>
    80004f6a:	892a                	mv	s2,a0
    80004f6c:	b7d5                	j	80004f50 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004f6e:	02451783          	lh	a5,36(a0)
    80004f72:	03079693          	slli	a3,a5,0x30
    80004f76:	92c1                	srli	a3,a3,0x30
    80004f78:	4725                	li	a4,9
    80004f7a:	02d76863          	bltu	a4,a3,80004faa <fileread+0xba>
    80004f7e:	0792                	slli	a5,a5,0x4
    80004f80:	0001d717          	auipc	a4,0x1d
    80004f84:	d6070713          	addi	a4,a4,-672 # 80021ce0 <devsw>
    80004f88:	97ba                	add	a5,a5,a4
    80004f8a:	639c                	ld	a5,0(a5)
    80004f8c:	c38d                	beqz	a5,80004fae <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004f8e:	4505                	li	a0,1
    80004f90:	9782                	jalr	a5
    80004f92:	892a                	mv	s2,a0
    80004f94:	bf75                	j	80004f50 <fileread+0x60>
    panic("fileread");
    80004f96:	00003517          	auipc	a0,0x3
    80004f9a:	74a50513          	addi	a0,a0,1866 # 800086e0 <syscalls+0x268>
    80004f9e:	ffffb097          	auipc	ra,0xffffb
    80004fa2:	5a0080e7          	jalr	1440(ra) # 8000053e <panic>
    return -1;
    80004fa6:	597d                	li	s2,-1
    80004fa8:	b765                	j	80004f50 <fileread+0x60>
      return -1;
    80004faa:	597d                	li	s2,-1
    80004fac:	b755                	j	80004f50 <fileread+0x60>
    80004fae:	597d                	li	s2,-1
    80004fb0:	b745                	j	80004f50 <fileread+0x60>

0000000080004fb2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004fb2:	715d                	addi	sp,sp,-80
    80004fb4:	e486                	sd	ra,72(sp)
    80004fb6:	e0a2                	sd	s0,64(sp)
    80004fb8:	fc26                	sd	s1,56(sp)
    80004fba:	f84a                	sd	s2,48(sp)
    80004fbc:	f44e                	sd	s3,40(sp)
    80004fbe:	f052                	sd	s4,32(sp)
    80004fc0:	ec56                	sd	s5,24(sp)
    80004fc2:	e85a                	sd	s6,16(sp)
    80004fc4:	e45e                	sd	s7,8(sp)
    80004fc6:	e062                	sd	s8,0(sp)
    80004fc8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004fca:	00954783          	lbu	a5,9(a0)
    80004fce:	10078663          	beqz	a5,800050da <filewrite+0x128>
    80004fd2:	892a                	mv	s2,a0
    80004fd4:	8aae                	mv	s5,a1
    80004fd6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004fd8:	411c                	lw	a5,0(a0)
    80004fda:	4705                	li	a4,1
    80004fdc:	02e78263          	beq	a5,a4,80005000 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004fe0:	470d                	li	a4,3
    80004fe2:	02e78663          	beq	a5,a4,8000500e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004fe6:	4709                	li	a4,2
    80004fe8:	0ee79163          	bne	a5,a4,800050ca <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004fec:	0ac05d63          	blez	a2,800050a6 <filewrite+0xf4>
    int i = 0;
    80004ff0:	4981                	li	s3,0
    80004ff2:	6b05                	lui	s6,0x1
    80004ff4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004ff8:	6b85                	lui	s7,0x1
    80004ffa:	c00b8b9b          	addiw	s7,s7,-1024
    80004ffe:	a861                	j	80005096 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005000:	6908                	ld	a0,16(a0)
    80005002:	00000097          	auipc	ra,0x0
    80005006:	22e080e7          	jalr	558(ra) # 80005230 <pipewrite>
    8000500a:	8a2a                	mv	s4,a0
    8000500c:	a045                	j	800050ac <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000500e:	02451783          	lh	a5,36(a0)
    80005012:	03079693          	slli	a3,a5,0x30
    80005016:	92c1                	srli	a3,a3,0x30
    80005018:	4725                	li	a4,9
    8000501a:	0cd76263          	bltu	a4,a3,800050de <filewrite+0x12c>
    8000501e:	0792                	slli	a5,a5,0x4
    80005020:	0001d717          	auipc	a4,0x1d
    80005024:	cc070713          	addi	a4,a4,-832 # 80021ce0 <devsw>
    80005028:	97ba                	add	a5,a5,a4
    8000502a:	679c                	ld	a5,8(a5)
    8000502c:	cbdd                	beqz	a5,800050e2 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000502e:	4505                	li	a0,1
    80005030:	9782                	jalr	a5
    80005032:	8a2a                	mv	s4,a0
    80005034:	a8a5                	j	800050ac <filewrite+0xfa>
    80005036:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000503a:	00000097          	auipc	ra,0x0
    8000503e:	8b0080e7          	jalr	-1872(ra) # 800048ea <begin_op>
      ilock(f->ip);
    80005042:	01893503          	ld	a0,24(s2)
    80005046:	fffff097          	auipc	ra,0xfffff
    8000504a:	ed2080e7          	jalr	-302(ra) # 80003f18 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000504e:	8762                	mv	a4,s8
    80005050:	02092683          	lw	a3,32(s2)
    80005054:	01598633          	add	a2,s3,s5
    80005058:	4585                	li	a1,1
    8000505a:	01893503          	ld	a0,24(s2)
    8000505e:	fffff097          	auipc	ra,0xfffff
    80005062:	266080e7          	jalr	614(ra) # 800042c4 <writei>
    80005066:	84aa                	mv	s1,a0
    80005068:	00a05763          	blez	a0,80005076 <filewrite+0xc4>
        f->off += r;
    8000506c:	02092783          	lw	a5,32(s2)
    80005070:	9fa9                	addw	a5,a5,a0
    80005072:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005076:	01893503          	ld	a0,24(s2)
    8000507a:	fffff097          	auipc	ra,0xfffff
    8000507e:	f60080e7          	jalr	-160(ra) # 80003fda <iunlock>
      end_op();
    80005082:	00000097          	auipc	ra,0x0
    80005086:	8e8080e7          	jalr	-1816(ra) # 8000496a <end_op>

      if(r != n1){
    8000508a:	009c1f63          	bne	s8,s1,800050a8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000508e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005092:	0149db63          	bge	s3,s4,800050a8 <filewrite+0xf6>
      int n1 = n - i;
    80005096:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000509a:	84be                	mv	s1,a5
    8000509c:	2781                	sext.w	a5,a5
    8000509e:	f8fb5ce3          	bge	s6,a5,80005036 <filewrite+0x84>
    800050a2:	84de                	mv	s1,s7
    800050a4:	bf49                	j	80005036 <filewrite+0x84>
    int i = 0;
    800050a6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800050a8:	013a1f63          	bne	s4,s3,800050c6 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800050ac:	8552                	mv	a0,s4
    800050ae:	60a6                	ld	ra,72(sp)
    800050b0:	6406                	ld	s0,64(sp)
    800050b2:	74e2                	ld	s1,56(sp)
    800050b4:	7942                	ld	s2,48(sp)
    800050b6:	79a2                	ld	s3,40(sp)
    800050b8:	7a02                	ld	s4,32(sp)
    800050ba:	6ae2                	ld	s5,24(sp)
    800050bc:	6b42                	ld	s6,16(sp)
    800050be:	6ba2                	ld	s7,8(sp)
    800050c0:	6c02                	ld	s8,0(sp)
    800050c2:	6161                	addi	sp,sp,80
    800050c4:	8082                	ret
    ret = (i == n ? n : -1);
    800050c6:	5a7d                	li	s4,-1
    800050c8:	b7d5                	j	800050ac <filewrite+0xfa>
    panic("filewrite");
    800050ca:	00003517          	auipc	a0,0x3
    800050ce:	62650513          	addi	a0,a0,1574 # 800086f0 <syscalls+0x278>
    800050d2:	ffffb097          	auipc	ra,0xffffb
    800050d6:	46c080e7          	jalr	1132(ra) # 8000053e <panic>
    return -1;
    800050da:	5a7d                	li	s4,-1
    800050dc:	bfc1                	j	800050ac <filewrite+0xfa>
      return -1;
    800050de:	5a7d                	li	s4,-1
    800050e0:	b7f1                	j	800050ac <filewrite+0xfa>
    800050e2:	5a7d                	li	s4,-1
    800050e4:	b7e1                	j	800050ac <filewrite+0xfa>

00000000800050e6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800050e6:	7179                	addi	sp,sp,-48
    800050e8:	f406                	sd	ra,40(sp)
    800050ea:	f022                	sd	s0,32(sp)
    800050ec:	ec26                	sd	s1,24(sp)
    800050ee:	e84a                	sd	s2,16(sp)
    800050f0:	e44e                	sd	s3,8(sp)
    800050f2:	e052                	sd	s4,0(sp)
    800050f4:	1800                	addi	s0,sp,48
    800050f6:	84aa                	mv	s1,a0
    800050f8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800050fa:	0005b023          	sd	zero,0(a1)
    800050fe:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005102:	00000097          	auipc	ra,0x0
    80005106:	bf8080e7          	jalr	-1032(ra) # 80004cfa <filealloc>
    8000510a:	e088                	sd	a0,0(s1)
    8000510c:	c551                	beqz	a0,80005198 <pipealloc+0xb2>
    8000510e:	00000097          	auipc	ra,0x0
    80005112:	bec080e7          	jalr	-1044(ra) # 80004cfa <filealloc>
    80005116:	00aa3023          	sd	a0,0(s4)
    8000511a:	c92d                	beqz	a0,8000518c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000511c:	ffffc097          	auipc	ra,0xffffc
    80005120:	9d8080e7          	jalr	-1576(ra) # 80000af4 <kalloc>
    80005124:	892a                	mv	s2,a0
    80005126:	c125                	beqz	a0,80005186 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005128:	4985                	li	s3,1
    8000512a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000512e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005132:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005136:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000513a:	00003597          	auipc	a1,0x3
    8000513e:	5c658593          	addi	a1,a1,1478 # 80008700 <syscalls+0x288>
    80005142:	ffffc097          	auipc	ra,0xffffc
    80005146:	a12080e7          	jalr	-1518(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000514a:	609c                	ld	a5,0(s1)
    8000514c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005150:	609c                	ld	a5,0(s1)
    80005152:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005156:	609c                	ld	a5,0(s1)
    80005158:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000515c:	609c                	ld	a5,0(s1)
    8000515e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005162:	000a3783          	ld	a5,0(s4)
    80005166:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000516a:	000a3783          	ld	a5,0(s4)
    8000516e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005172:	000a3783          	ld	a5,0(s4)
    80005176:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000517a:	000a3783          	ld	a5,0(s4)
    8000517e:	0127b823          	sd	s2,16(a5)
  return 0;
    80005182:	4501                	li	a0,0
    80005184:	a025                	j	800051ac <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005186:	6088                	ld	a0,0(s1)
    80005188:	e501                	bnez	a0,80005190 <pipealloc+0xaa>
    8000518a:	a039                	j	80005198 <pipealloc+0xb2>
    8000518c:	6088                	ld	a0,0(s1)
    8000518e:	c51d                	beqz	a0,800051bc <pipealloc+0xd6>
    fileclose(*f0);
    80005190:	00000097          	auipc	ra,0x0
    80005194:	c26080e7          	jalr	-986(ra) # 80004db6 <fileclose>
  if(*f1)
    80005198:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000519c:	557d                	li	a0,-1
  if(*f1)
    8000519e:	c799                	beqz	a5,800051ac <pipealloc+0xc6>
    fileclose(*f1);
    800051a0:	853e                	mv	a0,a5
    800051a2:	00000097          	auipc	ra,0x0
    800051a6:	c14080e7          	jalr	-1004(ra) # 80004db6 <fileclose>
  return -1;
    800051aa:	557d                	li	a0,-1
}
    800051ac:	70a2                	ld	ra,40(sp)
    800051ae:	7402                	ld	s0,32(sp)
    800051b0:	64e2                	ld	s1,24(sp)
    800051b2:	6942                	ld	s2,16(sp)
    800051b4:	69a2                	ld	s3,8(sp)
    800051b6:	6a02                	ld	s4,0(sp)
    800051b8:	6145                	addi	sp,sp,48
    800051ba:	8082                	ret
  return -1;
    800051bc:	557d                	li	a0,-1
    800051be:	b7fd                	j	800051ac <pipealloc+0xc6>

00000000800051c0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800051c0:	1101                	addi	sp,sp,-32
    800051c2:	ec06                	sd	ra,24(sp)
    800051c4:	e822                	sd	s0,16(sp)
    800051c6:	e426                	sd	s1,8(sp)
    800051c8:	e04a                	sd	s2,0(sp)
    800051ca:	1000                	addi	s0,sp,32
    800051cc:	84aa                	mv	s1,a0
    800051ce:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800051d0:	ffffc097          	auipc	ra,0xffffc
    800051d4:	a1c080e7          	jalr	-1508(ra) # 80000bec <acquire>
  if(writable){
    800051d8:	02090d63          	beqz	s2,80005212 <pipeclose+0x52>
    pi->writeopen = 0;
    800051dc:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800051e0:	21848513          	addi	a0,s1,536
    800051e4:	ffffd097          	auipc	ra,0xffffd
    800051e8:	7a4080e7          	jalr	1956(ra) # 80002988 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800051ec:	2204b783          	ld	a5,544(s1)
    800051f0:	eb95                	bnez	a5,80005224 <pipeclose+0x64>
    release(&pi->lock);
    800051f2:	8526                	mv	a0,s1
    800051f4:	ffffc097          	auipc	ra,0xffffc
    800051f8:	ac4080e7          	jalr	-1340(ra) # 80000cb8 <release>
    kfree((char*)pi);
    800051fc:	8526                	mv	a0,s1
    800051fe:	ffffb097          	auipc	ra,0xffffb
    80005202:	7fa080e7          	jalr	2042(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80005206:	60e2                	ld	ra,24(sp)
    80005208:	6442                	ld	s0,16(sp)
    8000520a:	64a2                	ld	s1,8(sp)
    8000520c:	6902                	ld	s2,0(sp)
    8000520e:	6105                	addi	sp,sp,32
    80005210:	8082                	ret
    pi->readopen = 0;
    80005212:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005216:	21c48513          	addi	a0,s1,540
    8000521a:	ffffd097          	auipc	ra,0xffffd
    8000521e:	76e080e7          	jalr	1902(ra) # 80002988 <wakeup>
    80005222:	b7e9                	j	800051ec <pipeclose+0x2c>
    release(&pi->lock);
    80005224:	8526                	mv	a0,s1
    80005226:	ffffc097          	auipc	ra,0xffffc
    8000522a:	a92080e7          	jalr	-1390(ra) # 80000cb8 <release>
}
    8000522e:	bfe1                	j	80005206 <pipeclose+0x46>

0000000080005230 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005230:	7159                	addi	sp,sp,-112
    80005232:	f486                	sd	ra,104(sp)
    80005234:	f0a2                	sd	s0,96(sp)
    80005236:	eca6                	sd	s1,88(sp)
    80005238:	e8ca                	sd	s2,80(sp)
    8000523a:	e4ce                	sd	s3,72(sp)
    8000523c:	e0d2                	sd	s4,64(sp)
    8000523e:	fc56                	sd	s5,56(sp)
    80005240:	f85a                	sd	s6,48(sp)
    80005242:	f45e                	sd	s7,40(sp)
    80005244:	f062                	sd	s8,32(sp)
    80005246:	ec66                	sd	s9,24(sp)
    80005248:	1880                	addi	s0,sp,112
    8000524a:	84aa                	mv	s1,a0
    8000524c:	8aae                	mv	s5,a1
    8000524e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005250:	ffffd097          	auipc	ra,0xffffd
    80005254:	c0c080e7          	jalr	-1012(ra) # 80001e5c <myproc>
    80005258:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000525a:	8526                	mv	a0,s1
    8000525c:	ffffc097          	auipc	ra,0xffffc
    80005260:	990080e7          	jalr	-1648(ra) # 80000bec <acquire>
  while(i < n){
    80005264:	0d405163          	blez	s4,80005326 <pipewrite+0xf6>
    80005268:	8ba6                	mv	s7,s1
  int i = 0;
    8000526a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000526c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000526e:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005272:	21c48c13          	addi	s8,s1,540
    80005276:	a08d                	j	800052d8 <pipewrite+0xa8>
      release(&pi->lock);
    80005278:	8526                	mv	a0,s1
    8000527a:	ffffc097          	auipc	ra,0xffffc
    8000527e:	a3e080e7          	jalr	-1474(ra) # 80000cb8 <release>
      return -1;
    80005282:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005284:	854a                	mv	a0,s2
    80005286:	70a6                	ld	ra,104(sp)
    80005288:	7406                	ld	s0,96(sp)
    8000528a:	64e6                	ld	s1,88(sp)
    8000528c:	6946                	ld	s2,80(sp)
    8000528e:	69a6                	ld	s3,72(sp)
    80005290:	6a06                	ld	s4,64(sp)
    80005292:	7ae2                	ld	s5,56(sp)
    80005294:	7b42                	ld	s6,48(sp)
    80005296:	7ba2                	ld	s7,40(sp)
    80005298:	7c02                	ld	s8,32(sp)
    8000529a:	6ce2                	ld	s9,24(sp)
    8000529c:	6165                	addi	sp,sp,112
    8000529e:	8082                	ret
      wakeup(&pi->nread);
    800052a0:	8566                	mv	a0,s9
    800052a2:	ffffd097          	auipc	ra,0xffffd
    800052a6:	6e6080e7          	jalr	1766(ra) # 80002988 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800052aa:	85de                	mv	a1,s7
    800052ac:	8562                	mv	a0,s8
    800052ae:	ffffd097          	auipc	ra,0xffffd
    800052b2:	45c080e7          	jalr	1116(ra) # 8000270a <sleep>
    800052b6:	a839                	j	800052d4 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800052b8:	21c4a783          	lw	a5,540(s1)
    800052bc:	0017871b          	addiw	a4,a5,1
    800052c0:	20e4ae23          	sw	a4,540(s1)
    800052c4:	1ff7f793          	andi	a5,a5,511
    800052c8:	97a6                	add	a5,a5,s1
    800052ca:	f9f44703          	lbu	a4,-97(s0)
    800052ce:	00e78c23          	sb	a4,24(a5)
      i++;
    800052d2:	2905                	addiw	s2,s2,1
  while(i < n){
    800052d4:	03495d63          	bge	s2,s4,8000530e <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800052d8:	2204a783          	lw	a5,544(s1)
    800052dc:	dfd1                	beqz	a5,80005278 <pipewrite+0x48>
    800052de:	0289a783          	lw	a5,40(s3)
    800052e2:	fbd9                	bnez	a5,80005278 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800052e4:	2184a783          	lw	a5,536(s1)
    800052e8:	21c4a703          	lw	a4,540(s1)
    800052ec:	2007879b          	addiw	a5,a5,512
    800052f0:	faf708e3          	beq	a4,a5,800052a0 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800052f4:	4685                	li	a3,1
    800052f6:	01590633          	add	a2,s2,s5
    800052fa:	f9f40593          	addi	a1,s0,-97
    800052fe:	0709b503          	ld	a0,112(s3)
    80005302:	ffffc097          	auipc	ra,0xffffc
    80005306:	42e080e7          	jalr	1070(ra) # 80001730 <copyin>
    8000530a:	fb6517e3          	bne	a0,s6,800052b8 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000530e:	21848513          	addi	a0,s1,536
    80005312:	ffffd097          	auipc	ra,0xffffd
    80005316:	676080e7          	jalr	1654(ra) # 80002988 <wakeup>
  release(&pi->lock);
    8000531a:	8526                	mv	a0,s1
    8000531c:	ffffc097          	auipc	ra,0xffffc
    80005320:	99c080e7          	jalr	-1636(ra) # 80000cb8 <release>
  return i;
    80005324:	b785                	j	80005284 <pipewrite+0x54>
  int i = 0;
    80005326:	4901                	li	s2,0
    80005328:	b7dd                	j	8000530e <pipewrite+0xde>

000000008000532a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000532a:	715d                	addi	sp,sp,-80
    8000532c:	e486                	sd	ra,72(sp)
    8000532e:	e0a2                	sd	s0,64(sp)
    80005330:	fc26                	sd	s1,56(sp)
    80005332:	f84a                	sd	s2,48(sp)
    80005334:	f44e                	sd	s3,40(sp)
    80005336:	f052                	sd	s4,32(sp)
    80005338:	ec56                	sd	s5,24(sp)
    8000533a:	e85a                	sd	s6,16(sp)
    8000533c:	0880                	addi	s0,sp,80
    8000533e:	84aa                	mv	s1,a0
    80005340:	892e                	mv	s2,a1
    80005342:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005344:	ffffd097          	auipc	ra,0xffffd
    80005348:	b18080e7          	jalr	-1256(ra) # 80001e5c <myproc>
    8000534c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000534e:	8b26                	mv	s6,s1
    80005350:	8526                	mv	a0,s1
    80005352:	ffffc097          	auipc	ra,0xffffc
    80005356:	89a080e7          	jalr	-1894(ra) # 80000bec <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000535a:	2184a703          	lw	a4,536(s1)
    8000535e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005362:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005366:	02f71463          	bne	a4,a5,8000538e <piperead+0x64>
    8000536a:	2244a783          	lw	a5,548(s1)
    8000536e:	c385                	beqz	a5,8000538e <piperead+0x64>
    if(pr->killed){
    80005370:	028a2783          	lw	a5,40(s4)
    80005374:	ebc1                	bnez	a5,80005404 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005376:	85da                	mv	a1,s6
    80005378:	854e                	mv	a0,s3
    8000537a:	ffffd097          	auipc	ra,0xffffd
    8000537e:	390080e7          	jalr	912(ra) # 8000270a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005382:	2184a703          	lw	a4,536(s1)
    80005386:	21c4a783          	lw	a5,540(s1)
    8000538a:	fef700e3          	beq	a4,a5,8000536a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000538e:	09505263          	blez	s5,80005412 <piperead+0xe8>
    80005392:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005394:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005396:	2184a783          	lw	a5,536(s1)
    8000539a:	21c4a703          	lw	a4,540(s1)
    8000539e:	02f70d63          	beq	a4,a5,800053d8 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800053a2:	0017871b          	addiw	a4,a5,1
    800053a6:	20e4ac23          	sw	a4,536(s1)
    800053aa:	1ff7f793          	andi	a5,a5,511
    800053ae:	97a6                	add	a5,a5,s1
    800053b0:	0187c783          	lbu	a5,24(a5)
    800053b4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800053b8:	4685                	li	a3,1
    800053ba:	fbf40613          	addi	a2,s0,-65
    800053be:	85ca                	mv	a1,s2
    800053c0:	070a3503          	ld	a0,112(s4)
    800053c4:	ffffc097          	auipc	ra,0xffffc
    800053c8:	2e0080e7          	jalr	736(ra) # 800016a4 <copyout>
    800053cc:	01650663          	beq	a0,s6,800053d8 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053d0:	2985                	addiw	s3,s3,1
    800053d2:	0905                	addi	s2,s2,1
    800053d4:	fd3a91e3          	bne	s5,s3,80005396 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800053d8:	21c48513          	addi	a0,s1,540
    800053dc:	ffffd097          	auipc	ra,0xffffd
    800053e0:	5ac080e7          	jalr	1452(ra) # 80002988 <wakeup>
  release(&pi->lock);
    800053e4:	8526                	mv	a0,s1
    800053e6:	ffffc097          	auipc	ra,0xffffc
    800053ea:	8d2080e7          	jalr	-1838(ra) # 80000cb8 <release>
  return i;
}
    800053ee:	854e                	mv	a0,s3
    800053f0:	60a6                	ld	ra,72(sp)
    800053f2:	6406                	ld	s0,64(sp)
    800053f4:	74e2                	ld	s1,56(sp)
    800053f6:	7942                	ld	s2,48(sp)
    800053f8:	79a2                	ld	s3,40(sp)
    800053fa:	7a02                	ld	s4,32(sp)
    800053fc:	6ae2                	ld	s5,24(sp)
    800053fe:	6b42                	ld	s6,16(sp)
    80005400:	6161                	addi	sp,sp,80
    80005402:	8082                	ret
      release(&pi->lock);
    80005404:	8526                	mv	a0,s1
    80005406:	ffffc097          	auipc	ra,0xffffc
    8000540a:	8b2080e7          	jalr	-1870(ra) # 80000cb8 <release>
      return -1;
    8000540e:	59fd                	li	s3,-1
    80005410:	bff9                	j	800053ee <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005412:	4981                	li	s3,0
    80005414:	b7d1                	j	800053d8 <piperead+0xae>

0000000080005416 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005416:	df010113          	addi	sp,sp,-528
    8000541a:	20113423          	sd	ra,520(sp)
    8000541e:	20813023          	sd	s0,512(sp)
    80005422:	ffa6                	sd	s1,504(sp)
    80005424:	fbca                	sd	s2,496(sp)
    80005426:	f7ce                	sd	s3,488(sp)
    80005428:	f3d2                	sd	s4,480(sp)
    8000542a:	efd6                	sd	s5,472(sp)
    8000542c:	ebda                	sd	s6,464(sp)
    8000542e:	e7de                	sd	s7,456(sp)
    80005430:	e3e2                	sd	s8,448(sp)
    80005432:	ff66                	sd	s9,440(sp)
    80005434:	fb6a                	sd	s10,432(sp)
    80005436:	f76e                	sd	s11,424(sp)
    80005438:	0c00                	addi	s0,sp,528
    8000543a:	84aa                	mv	s1,a0
    8000543c:	dea43c23          	sd	a0,-520(s0)
    80005440:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005444:	ffffd097          	auipc	ra,0xffffd
    80005448:	a18080e7          	jalr	-1512(ra) # 80001e5c <myproc>
    8000544c:	892a                	mv	s2,a0

  begin_op();
    8000544e:	fffff097          	auipc	ra,0xfffff
    80005452:	49c080e7          	jalr	1180(ra) # 800048ea <begin_op>

  if((ip = namei(path)) == 0){
    80005456:	8526                	mv	a0,s1
    80005458:	fffff097          	auipc	ra,0xfffff
    8000545c:	276080e7          	jalr	630(ra) # 800046ce <namei>
    80005460:	c92d                	beqz	a0,800054d2 <exec+0xbc>
    80005462:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005464:	fffff097          	auipc	ra,0xfffff
    80005468:	ab4080e7          	jalr	-1356(ra) # 80003f18 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000546c:	04000713          	li	a4,64
    80005470:	4681                	li	a3,0
    80005472:	e5040613          	addi	a2,s0,-432
    80005476:	4581                	li	a1,0
    80005478:	8526                	mv	a0,s1
    8000547a:	fffff097          	auipc	ra,0xfffff
    8000547e:	d52080e7          	jalr	-686(ra) # 800041cc <readi>
    80005482:	04000793          	li	a5,64
    80005486:	00f51a63          	bne	a0,a5,8000549a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000548a:	e5042703          	lw	a4,-432(s0)
    8000548e:	464c47b7          	lui	a5,0x464c4
    80005492:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005496:	04f70463          	beq	a4,a5,800054de <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000549a:	8526                	mv	a0,s1
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	cde080e7          	jalr	-802(ra) # 8000417a <iunlockput>
    end_op();
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	4c6080e7          	jalr	1222(ra) # 8000496a <end_op>
  }
  return -1;
    800054ac:	557d                	li	a0,-1
}
    800054ae:	20813083          	ld	ra,520(sp)
    800054b2:	20013403          	ld	s0,512(sp)
    800054b6:	74fe                	ld	s1,504(sp)
    800054b8:	795e                	ld	s2,496(sp)
    800054ba:	79be                	ld	s3,488(sp)
    800054bc:	7a1e                	ld	s4,480(sp)
    800054be:	6afe                	ld	s5,472(sp)
    800054c0:	6b5e                	ld	s6,464(sp)
    800054c2:	6bbe                	ld	s7,456(sp)
    800054c4:	6c1e                	ld	s8,448(sp)
    800054c6:	7cfa                	ld	s9,440(sp)
    800054c8:	7d5a                	ld	s10,432(sp)
    800054ca:	7dba                	ld	s11,424(sp)
    800054cc:	21010113          	addi	sp,sp,528
    800054d0:	8082                	ret
    end_op();
    800054d2:	fffff097          	auipc	ra,0xfffff
    800054d6:	498080e7          	jalr	1176(ra) # 8000496a <end_op>
    return -1;
    800054da:	557d                	li	a0,-1
    800054dc:	bfc9                	j	800054ae <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800054de:	854a                	mv	a0,s2
    800054e0:	ffffd097          	auipc	ra,0xffffd
    800054e4:	a3a080e7          	jalr	-1478(ra) # 80001f1a <proc_pagetable>
    800054e8:	8baa                	mv	s7,a0
    800054ea:	d945                	beqz	a0,8000549a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054ec:	e7042983          	lw	s3,-400(s0)
    800054f0:	e8845783          	lhu	a5,-376(s0)
    800054f4:	c7ad                	beqz	a5,8000555e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800054f6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054f8:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800054fa:	6c85                	lui	s9,0x1
    800054fc:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005500:	def43823          	sd	a5,-528(s0)
    80005504:	a42d                	j	8000572e <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005506:	00003517          	auipc	a0,0x3
    8000550a:	20250513          	addi	a0,a0,514 # 80008708 <syscalls+0x290>
    8000550e:	ffffb097          	auipc	ra,0xffffb
    80005512:	030080e7          	jalr	48(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005516:	8756                	mv	a4,s5
    80005518:	012d86bb          	addw	a3,s11,s2
    8000551c:	4581                	li	a1,0
    8000551e:	8526                	mv	a0,s1
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	cac080e7          	jalr	-852(ra) # 800041cc <readi>
    80005528:	2501                	sext.w	a0,a0
    8000552a:	1aaa9963          	bne	s5,a0,800056dc <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000552e:	6785                	lui	a5,0x1
    80005530:	0127893b          	addw	s2,a5,s2
    80005534:	77fd                	lui	a5,0xfffff
    80005536:	01478a3b          	addw	s4,a5,s4
    8000553a:	1f897163          	bgeu	s2,s8,8000571c <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000553e:	02091593          	slli	a1,s2,0x20
    80005542:	9181                	srli	a1,a1,0x20
    80005544:	95ea                	add	a1,a1,s10
    80005546:	855e                	mv	a0,s7
    80005548:	ffffc097          	auipc	ra,0xffffc
    8000554c:	b58080e7          	jalr	-1192(ra) # 800010a0 <walkaddr>
    80005550:	862a                	mv	a2,a0
    if(pa == 0)
    80005552:	d955                	beqz	a0,80005506 <exec+0xf0>
      n = PGSIZE;
    80005554:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005556:	fd9a70e3          	bgeu	s4,s9,80005516 <exec+0x100>
      n = sz - i;
    8000555a:	8ad2                	mv	s5,s4
    8000555c:	bf6d                	j	80005516 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000555e:	4901                	li	s2,0
  iunlockput(ip);
    80005560:	8526                	mv	a0,s1
    80005562:	fffff097          	auipc	ra,0xfffff
    80005566:	c18080e7          	jalr	-1000(ra) # 8000417a <iunlockput>
  end_op();
    8000556a:	fffff097          	auipc	ra,0xfffff
    8000556e:	400080e7          	jalr	1024(ra) # 8000496a <end_op>
  p = myproc();
    80005572:	ffffd097          	auipc	ra,0xffffd
    80005576:	8ea080e7          	jalr	-1814(ra) # 80001e5c <myproc>
    8000557a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000557c:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    80005580:	6785                	lui	a5,0x1
    80005582:	17fd                	addi	a5,a5,-1
    80005584:	993e                	add	s2,s2,a5
    80005586:	757d                	lui	a0,0xfffff
    80005588:	00a977b3          	and	a5,s2,a0
    8000558c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005590:	6609                	lui	a2,0x2
    80005592:	963e                	add	a2,a2,a5
    80005594:	85be                	mv	a1,a5
    80005596:	855e                	mv	a0,s7
    80005598:	ffffc097          	auipc	ra,0xffffc
    8000559c:	ebc080e7          	jalr	-324(ra) # 80001454 <uvmalloc>
    800055a0:	8b2a                	mv	s6,a0
  ip = 0;
    800055a2:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800055a4:	12050c63          	beqz	a0,800056dc <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800055a8:	75f9                	lui	a1,0xffffe
    800055aa:	95aa                	add	a1,a1,a0
    800055ac:	855e                	mv	a0,s7
    800055ae:	ffffc097          	auipc	ra,0xffffc
    800055b2:	0c4080e7          	jalr	196(ra) # 80001672 <uvmclear>
  stackbase = sp - PGSIZE;
    800055b6:	7c7d                	lui	s8,0xfffff
    800055b8:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800055ba:	e0043783          	ld	a5,-512(s0)
    800055be:	6388                	ld	a0,0(a5)
    800055c0:	c535                	beqz	a0,8000562c <exec+0x216>
    800055c2:	e9040993          	addi	s3,s0,-368
    800055c6:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800055ca:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800055cc:	ffffc097          	auipc	ra,0xffffc
    800055d0:	8ca080e7          	jalr	-1846(ra) # 80000e96 <strlen>
    800055d4:	2505                	addiw	a0,a0,1
    800055d6:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800055da:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800055de:	13896363          	bltu	s2,s8,80005704 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800055e2:	e0043d83          	ld	s11,-512(s0)
    800055e6:	000dba03          	ld	s4,0(s11)
    800055ea:	8552                	mv	a0,s4
    800055ec:	ffffc097          	auipc	ra,0xffffc
    800055f0:	8aa080e7          	jalr	-1878(ra) # 80000e96 <strlen>
    800055f4:	0015069b          	addiw	a3,a0,1
    800055f8:	8652                	mv	a2,s4
    800055fa:	85ca                	mv	a1,s2
    800055fc:	855e                	mv	a0,s7
    800055fe:	ffffc097          	auipc	ra,0xffffc
    80005602:	0a6080e7          	jalr	166(ra) # 800016a4 <copyout>
    80005606:	10054363          	bltz	a0,8000570c <exec+0x2f6>
    ustack[argc] = sp;
    8000560a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000560e:	0485                	addi	s1,s1,1
    80005610:	008d8793          	addi	a5,s11,8
    80005614:	e0f43023          	sd	a5,-512(s0)
    80005618:	008db503          	ld	a0,8(s11)
    8000561c:	c911                	beqz	a0,80005630 <exec+0x21a>
    if(argc >= MAXARG)
    8000561e:	09a1                	addi	s3,s3,8
    80005620:	fb3c96e3          	bne	s9,s3,800055cc <exec+0x1b6>
  sz = sz1;
    80005624:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005628:	4481                	li	s1,0
    8000562a:	a84d                	j	800056dc <exec+0x2c6>
  sp = sz;
    8000562c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000562e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005630:	00349793          	slli	a5,s1,0x3
    80005634:	f9040713          	addi	a4,s0,-112
    80005638:	97ba                	add	a5,a5,a4
    8000563a:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000563e:	00148693          	addi	a3,s1,1
    80005642:	068e                	slli	a3,a3,0x3
    80005644:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005648:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000564c:	01897663          	bgeu	s2,s8,80005658 <exec+0x242>
  sz = sz1;
    80005650:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005654:	4481                	li	s1,0
    80005656:	a059                	j	800056dc <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005658:	e9040613          	addi	a2,s0,-368
    8000565c:	85ca                	mv	a1,s2
    8000565e:	855e                	mv	a0,s7
    80005660:	ffffc097          	auipc	ra,0xffffc
    80005664:	044080e7          	jalr	68(ra) # 800016a4 <copyout>
    80005668:	0a054663          	bltz	a0,80005714 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000566c:	078ab783          	ld	a5,120(s5)
    80005670:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005674:	df843783          	ld	a5,-520(s0)
    80005678:	0007c703          	lbu	a4,0(a5)
    8000567c:	cf11                	beqz	a4,80005698 <exec+0x282>
    8000567e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005680:	02f00693          	li	a3,47
    80005684:	a039                	j	80005692 <exec+0x27c>
      last = s+1;
    80005686:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000568a:	0785                	addi	a5,a5,1
    8000568c:	fff7c703          	lbu	a4,-1(a5)
    80005690:	c701                	beqz	a4,80005698 <exec+0x282>
    if(*s == '/')
    80005692:	fed71ce3          	bne	a4,a3,8000568a <exec+0x274>
    80005696:	bfc5                	j	80005686 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005698:	4641                	li	a2,16
    8000569a:	df843583          	ld	a1,-520(s0)
    8000569e:	178a8513          	addi	a0,s5,376
    800056a2:	ffffb097          	auipc	ra,0xffffb
    800056a6:	7c2080e7          	jalr	1986(ra) # 80000e64 <safestrcpy>
  oldpagetable = p->pagetable;
    800056aa:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    800056ae:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    800056b2:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800056b6:	078ab783          	ld	a5,120(s5)
    800056ba:	e6843703          	ld	a4,-408(s0)
    800056be:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800056c0:	078ab783          	ld	a5,120(s5)
    800056c4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800056c8:	85ea                	mv	a1,s10
    800056ca:	ffffd097          	auipc	ra,0xffffd
    800056ce:	8ec080e7          	jalr	-1812(ra) # 80001fb6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800056d2:	0004851b          	sext.w	a0,s1
    800056d6:	bbe1                	j	800054ae <exec+0x98>
    800056d8:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800056dc:	e0843583          	ld	a1,-504(s0)
    800056e0:	855e                	mv	a0,s7
    800056e2:	ffffd097          	auipc	ra,0xffffd
    800056e6:	8d4080e7          	jalr	-1836(ra) # 80001fb6 <proc_freepagetable>
  if(ip){
    800056ea:	da0498e3          	bnez	s1,8000549a <exec+0x84>
  return -1;
    800056ee:	557d                	li	a0,-1
    800056f0:	bb7d                	j	800054ae <exec+0x98>
    800056f2:	e1243423          	sd	s2,-504(s0)
    800056f6:	b7dd                	j	800056dc <exec+0x2c6>
    800056f8:	e1243423          	sd	s2,-504(s0)
    800056fc:	b7c5                	j	800056dc <exec+0x2c6>
    800056fe:	e1243423          	sd	s2,-504(s0)
    80005702:	bfe9                	j	800056dc <exec+0x2c6>
  sz = sz1;
    80005704:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005708:	4481                	li	s1,0
    8000570a:	bfc9                	j	800056dc <exec+0x2c6>
  sz = sz1;
    8000570c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005710:	4481                	li	s1,0
    80005712:	b7e9                	j	800056dc <exec+0x2c6>
  sz = sz1;
    80005714:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005718:	4481                	li	s1,0
    8000571a:	b7c9                	j	800056dc <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000571c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005720:	2b05                	addiw	s6,s6,1
    80005722:	0389899b          	addiw	s3,s3,56
    80005726:	e8845783          	lhu	a5,-376(s0)
    8000572a:	e2fb5be3          	bge	s6,a5,80005560 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000572e:	2981                	sext.w	s3,s3
    80005730:	03800713          	li	a4,56
    80005734:	86ce                	mv	a3,s3
    80005736:	e1840613          	addi	a2,s0,-488
    8000573a:	4581                	li	a1,0
    8000573c:	8526                	mv	a0,s1
    8000573e:	fffff097          	auipc	ra,0xfffff
    80005742:	a8e080e7          	jalr	-1394(ra) # 800041cc <readi>
    80005746:	03800793          	li	a5,56
    8000574a:	f8f517e3          	bne	a0,a5,800056d8 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000574e:	e1842783          	lw	a5,-488(s0)
    80005752:	4705                	li	a4,1
    80005754:	fce796e3          	bne	a5,a4,80005720 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005758:	e4043603          	ld	a2,-448(s0)
    8000575c:	e3843783          	ld	a5,-456(s0)
    80005760:	f8f669e3          	bltu	a2,a5,800056f2 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005764:	e2843783          	ld	a5,-472(s0)
    80005768:	963e                	add	a2,a2,a5
    8000576a:	f8f667e3          	bltu	a2,a5,800056f8 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000576e:	85ca                	mv	a1,s2
    80005770:	855e                	mv	a0,s7
    80005772:	ffffc097          	auipc	ra,0xffffc
    80005776:	ce2080e7          	jalr	-798(ra) # 80001454 <uvmalloc>
    8000577a:	e0a43423          	sd	a0,-504(s0)
    8000577e:	d141                	beqz	a0,800056fe <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005780:	e2843d03          	ld	s10,-472(s0)
    80005784:	df043783          	ld	a5,-528(s0)
    80005788:	00fd77b3          	and	a5,s10,a5
    8000578c:	fba1                	bnez	a5,800056dc <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000578e:	e2042d83          	lw	s11,-480(s0)
    80005792:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005796:	f80c03e3          	beqz	s8,8000571c <exec+0x306>
    8000579a:	8a62                	mv	s4,s8
    8000579c:	4901                	li	s2,0
    8000579e:	b345                	j	8000553e <exec+0x128>

00000000800057a0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800057a0:	7179                	addi	sp,sp,-48
    800057a2:	f406                	sd	ra,40(sp)
    800057a4:	f022                	sd	s0,32(sp)
    800057a6:	ec26                	sd	s1,24(sp)
    800057a8:	e84a                	sd	s2,16(sp)
    800057aa:	1800                	addi	s0,sp,48
    800057ac:	892e                	mv	s2,a1
    800057ae:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800057b0:	fdc40593          	addi	a1,s0,-36
    800057b4:	ffffe097          	auipc	ra,0xffffe
    800057b8:	ba8080e7          	jalr	-1112(ra) # 8000335c <argint>
    800057bc:	04054063          	bltz	a0,800057fc <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800057c0:	fdc42703          	lw	a4,-36(s0)
    800057c4:	47bd                	li	a5,15
    800057c6:	02e7ed63          	bltu	a5,a4,80005800 <argfd+0x60>
    800057ca:	ffffc097          	auipc	ra,0xffffc
    800057ce:	692080e7          	jalr	1682(ra) # 80001e5c <myproc>
    800057d2:	fdc42703          	lw	a4,-36(s0)
    800057d6:	01e70793          	addi	a5,a4,30
    800057da:	078e                	slli	a5,a5,0x3
    800057dc:	953e                	add	a0,a0,a5
    800057de:	611c                	ld	a5,0(a0)
    800057e0:	c395                	beqz	a5,80005804 <argfd+0x64>
    return -1;
  if(pfd)
    800057e2:	00090463          	beqz	s2,800057ea <argfd+0x4a>
    *pfd = fd;
    800057e6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800057ea:	4501                	li	a0,0
  if(pf)
    800057ec:	c091                	beqz	s1,800057f0 <argfd+0x50>
    *pf = f;
    800057ee:	e09c                	sd	a5,0(s1)
}
    800057f0:	70a2                	ld	ra,40(sp)
    800057f2:	7402                	ld	s0,32(sp)
    800057f4:	64e2                	ld	s1,24(sp)
    800057f6:	6942                	ld	s2,16(sp)
    800057f8:	6145                	addi	sp,sp,48
    800057fa:	8082                	ret
    return -1;
    800057fc:	557d                	li	a0,-1
    800057fe:	bfcd                	j	800057f0 <argfd+0x50>
    return -1;
    80005800:	557d                	li	a0,-1
    80005802:	b7fd                	j	800057f0 <argfd+0x50>
    80005804:	557d                	li	a0,-1
    80005806:	b7ed                	j	800057f0 <argfd+0x50>

0000000080005808 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005808:	1101                	addi	sp,sp,-32
    8000580a:	ec06                	sd	ra,24(sp)
    8000580c:	e822                	sd	s0,16(sp)
    8000580e:	e426                	sd	s1,8(sp)
    80005810:	1000                	addi	s0,sp,32
    80005812:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005814:	ffffc097          	auipc	ra,0xffffc
    80005818:	648080e7          	jalr	1608(ra) # 80001e5c <myproc>
    8000581c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000581e:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    80005822:	4501                	li	a0,0
    80005824:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005826:	6398                	ld	a4,0(a5)
    80005828:	cb19                	beqz	a4,8000583e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000582a:	2505                	addiw	a0,a0,1
    8000582c:	07a1                	addi	a5,a5,8
    8000582e:	fed51ce3          	bne	a0,a3,80005826 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005832:	557d                	li	a0,-1
}
    80005834:	60e2                	ld	ra,24(sp)
    80005836:	6442                	ld	s0,16(sp)
    80005838:	64a2                	ld	s1,8(sp)
    8000583a:	6105                	addi	sp,sp,32
    8000583c:	8082                	ret
      p->ofile[fd] = f;
    8000583e:	01e50793          	addi	a5,a0,30
    80005842:	078e                	slli	a5,a5,0x3
    80005844:	963e                	add	a2,a2,a5
    80005846:	e204                	sd	s1,0(a2)
      return fd;
    80005848:	b7f5                	j	80005834 <fdalloc+0x2c>

000000008000584a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000584a:	715d                	addi	sp,sp,-80
    8000584c:	e486                	sd	ra,72(sp)
    8000584e:	e0a2                	sd	s0,64(sp)
    80005850:	fc26                	sd	s1,56(sp)
    80005852:	f84a                	sd	s2,48(sp)
    80005854:	f44e                	sd	s3,40(sp)
    80005856:	f052                	sd	s4,32(sp)
    80005858:	ec56                	sd	s5,24(sp)
    8000585a:	0880                	addi	s0,sp,80
    8000585c:	89ae                	mv	s3,a1
    8000585e:	8ab2                	mv	s5,a2
    80005860:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005862:	fb040593          	addi	a1,s0,-80
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	e86080e7          	jalr	-378(ra) # 800046ec <nameiparent>
    8000586e:	892a                	mv	s2,a0
    80005870:	12050f63          	beqz	a0,800059ae <create+0x164>
    return 0;

  ilock(dp);
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	6a4080e7          	jalr	1700(ra) # 80003f18 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000587c:	4601                	li	a2,0
    8000587e:	fb040593          	addi	a1,s0,-80
    80005882:	854a                	mv	a0,s2
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	b78080e7          	jalr	-1160(ra) # 800043fc <dirlookup>
    8000588c:	84aa                	mv	s1,a0
    8000588e:	c921                	beqz	a0,800058de <create+0x94>
    iunlockput(dp);
    80005890:	854a                	mv	a0,s2
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	8e8080e7          	jalr	-1816(ra) # 8000417a <iunlockput>
    ilock(ip);
    8000589a:	8526                	mv	a0,s1
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	67c080e7          	jalr	1660(ra) # 80003f18 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800058a4:	2981                	sext.w	s3,s3
    800058a6:	4789                	li	a5,2
    800058a8:	02f99463          	bne	s3,a5,800058d0 <create+0x86>
    800058ac:	0444d783          	lhu	a5,68(s1)
    800058b0:	37f9                	addiw	a5,a5,-2
    800058b2:	17c2                	slli	a5,a5,0x30
    800058b4:	93c1                	srli	a5,a5,0x30
    800058b6:	4705                	li	a4,1
    800058b8:	00f76c63          	bltu	a4,a5,800058d0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800058bc:	8526                	mv	a0,s1
    800058be:	60a6                	ld	ra,72(sp)
    800058c0:	6406                	ld	s0,64(sp)
    800058c2:	74e2                	ld	s1,56(sp)
    800058c4:	7942                	ld	s2,48(sp)
    800058c6:	79a2                	ld	s3,40(sp)
    800058c8:	7a02                	ld	s4,32(sp)
    800058ca:	6ae2                	ld	s5,24(sp)
    800058cc:	6161                	addi	sp,sp,80
    800058ce:	8082                	ret
    iunlockput(ip);
    800058d0:	8526                	mv	a0,s1
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	8a8080e7          	jalr	-1880(ra) # 8000417a <iunlockput>
    return 0;
    800058da:	4481                	li	s1,0
    800058dc:	b7c5                	j	800058bc <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800058de:	85ce                	mv	a1,s3
    800058e0:	00092503          	lw	a0,0(s2)
    800058e4:	ffffe097          	auipc	ra,0xffffe
    800058e8:	49c080e7          	jalr	1180(ra) # 80003d80 <ialloc>
    800058ec:	84aa                	mv	s1,a0
    800058ee:	c529                	beqz	a0,80005938 <create+0xee>
  ilock(ip);
    800058f0:	ffffe097          	auipc	ra,0xffffe
    800058f4:	628080e7          	jalr	1576(ra) # 80003f18 <ilock>
  ip->major = major;
    800058f8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800058fc:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005900:	4785                	li	a5,1
    80005902:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005906:	8526                	mv	a0,s1
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	546080e7          	jalr	1350(ra) # 80003e4e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005910:	2981                	sext.w	s3,s3
    80005912:	4785                	li	a5,1
    80005914:	02f98a63          	beq	s3,a5,80005948 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005918:	40d0                	lw	a2,4(s1)
    8000591a:	fb040593          	addi	a1,s0,-80
    8000591e:	854a                	mv	a0,s2
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	cec080e7          	jalr	-788(ra) # 8000460c <dirlink>
    80005928:	06054b63          	bltz	a0,8000599e <create+0x154>
  iunlockput(dp);
    8000592c:	854a                	mv	a0,s2
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	84c080e7          	jalr	-1972(ra) # 8000417a <iunlockput>
  return ip;
    80005936:	b759                	j	800058bc <create+0x72>
    panic("create: ialloc");
    80005938:	00003517          	auipc	a0,0x3
    8000593c:	df050513          	addi	a0,a0,-528 # 80008728 <syscalls+0x2b0>
    80005940:	ffffb097          	auipc	ra,0xffffb
    80005944:	bfe080e7          	jalr	-1026(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005948:	04a95783          	lhu	a5,74(s2)
    8000594c:	2785                	addiw	a5,a5,1
    8000594e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005952:	854a                	mv	a0,s2
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	4fa080e7          	jalr	1274(ra) # 80003e4e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000595c:	40d0                	lw	a2,4(s1)
    8000595e:	00003597          	auipc	a1,0x3
    80005962:	dda58593          	addi	a1,a1,-550 # 80008738 <syscalls+0x2c0>
    80005966:	8526                	mv	a0,s1
    80005968:	fffff097          	auipc	ra,0xfffff
    8000596c:	ca4080e7          	jalr	-860(ra) # 8000460c <dirlink>
    80005970:	00054f63          	bltz	a0,8000598e <create+0x144>
    80005974:	00492603          	lw	a2,4(s2)
    80005978:	00003597          	auipc	a1,0x3
    8000597c:	dc858593          	addi	a1,a1,-568 # 80008740 <syscalls+0x2c8>
    80005980:	8526                	mv	a0,s1
    80005982:	fffff097          	auipc	ra,0xfffff
    80005986:	c8a080e7          	jalr	-886(ra) # 8000460c <dirlink>
    8000598a:	f80557e3          	bgez	a0,80005918 <create+0xce>
      panic("create dots");
    8000598e:	00003517          	auipc	a0,0x3
    80005992:	dba50513          	addi	a0,a0,-582 # 80008748 <syscalls+0x2d0>
    80005996:	ffffb097          	auipc	ra,0xffffb
    8000599a:	ba8080e7          	jalr	-1112(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000599e:	00003517          	auipc	a0,0x3
    800059a2:	dba50513          	addi	a0,a0,-582 # 80008758 <syscalls+0x2e0>
    800059a6:	ffffb097          	auipc	ra,0xffffb
    800059aa:	b98080e7          	jalr	-1128(ra) # 8000053e <panic>
    return 0;
    800059ae:	84aa                	mv	s1,a0
    800059b0:	b731                	j	800058bc <create+0x72>

00000000800059b2 <sys_dup>:
{
    800059b2:	7179                	addi	sp,sp,-48
    800059b4:	f406                	sd	ra,40(sp)
    800059b6:	f022                	sd	s0,32(sp)
    800059b8:	ec26                	sd	s1,24(sp)
    800059ba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800059bc:	fd840613          	addi	a2,s0,-40
    800059c0:	4581                	li	a1,0
    800059c2:	4501                	li	a0,0
    800059c4:	00000097          	auipc	ra,0x0
    800059c8:	ddc080e7          	jalr	-548(ra) # 800057a0 <argfd>
    return -1;
    800059cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800059ce:	02054363          	bltz	a0,800059f4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800059d2:	fd843503          	ld	a0,-40(s0)
    800059d6:	00000097          	auipc	ra,0x0
    800059da:	e32080e7          	jalr	-462(ra) # 80005808 <fdalloc>
    800059de:	84aa                	mv	s1,a0
    return -1;
    800059e0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800059e2:	00054963          	bltz	a0,800059f4 <sys_dup+0x42>
  filedup(f);
    800059e6:	fd843503          	ld	a0,-40(s0)
    800059ea:	fffff097          	auipc	ra,0xfffff
    800059ee:	37a080e7          	jalr	890(ra) # 80004d64 <filedup>
  return fd;
    800059f2:	87a6                	mv	a5,s1
}
    800059f4:	853e                	mv	a0,a5
    800059f6:	70a2                	ld	ra,40(sp)
    800059f8:	7402                	ld	s0,32(sp)
    800059fa:	64e2                	ld	s1,24(sp)
    800059fc:	6145                	addi	sp,sp,48
    800059fe:	8082                	ret

0000000080005a00 <sys_read>:
{
    80005a00:	7179                	addi	sp,sp,-48
    80005a02:	f406                	sd	ra,40(sp)
    80005a04:	f022                	sd	s0,32(sp)
    80005a06:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a08:	fe840613          	addi	a2,s0,-24
    80005a0c:	4581                	li	a1,0
    80005a0e:	4501                	li	a0,0
    80005a10:	00000097          	auipc	ra,0x0
    80005a14:	d90080e7          	jalr	-624(ra) # 800057a0 <argfd>
    return -1;
    80005a18:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a1a:	04054163          	bltz	a0,80005a5c <sys_read+0x5c>
    80005a1e:	fe440593          	addi	a1,s0,-28
    80005a22:	4509                	li	a0,2
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	938080e7          	jalr	-1736(ra) # 8000335c <argint>
    return -1;
    80005a2c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a2e:	02054763          	bltz	a0,80005a5c <sys_read+0x5c>
    80005a32:	fd840593          	addi	a1,s0,-40
    80005a36:	4505                	li	a0,1
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	946080e7          	jalr	-1722(ra) # 8000337e <argaddr>
    return -1;
    80005a40:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a42:	00054d63          	bltz	a0,80005a5c <sys_read+0x5c>
  return fileread(f, p, n);
    80005a46:	fe442603          	lw	a2,-28(s0)
    80005a4a:	fd843583          	ld	a1,-40(s0)
    80005a4e:	fe843503          	ld	a0,-24(s0)
    80005a52:	fffff097          	auipc	ra,0xfffff
    80005a56:	49e080e7          	jalr	1182(ra) # 80004ef0 <fileread>
    80005a5a:	87aa                	mv	a5,a0
}
    80005a5c:	853e                	mv	a0,a5
    80005a5e:	70a2                	ld	ra,40(sp)
    80005a60:	7402                	ld	s0,32(sp)
    80005a62:	6145                	addi	sp,sp,48
    80005a64:	8082                	ret

0000000080005a66 <sys_write>:
{
    80005a66:	7179                	addi	sp,sp,-48
    80005a68:	f406                	sd	ra,40(sp)
    80005a6a:	f022                	sd	s0,32(sp)
    80005a6c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a6e:	fe840613          	addi	a2,s0,-24
    80005a72:	4581                	li	a1,0
    80005a74:	4501                	li	a0,0
    80005a76:	00000097          	auipc	ra,0x0
    80005a7a:	d2a080e7          	jalr	-726(ra) # 800057a0 <argfd>
    return -1;
    80005a7e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a80:	04054163          	bltz	a0,80005ac2 <sys_write+0x5c>
    80005a84:	fe440593          	addi	a1,s0,-28
    80005a88:	4509                	li	a0,2
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	8d2080e7          	jalr	-1838(ra) # 8000335c <argint>
    return -1;
    80005a92:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a94:	02054763          	bltz	a0,80005ac2 <sys_write+0x5c>
    80005a98:	fd840593          	addi	a1,s0,-40
    80005a9c:	4505                	li	a0,1
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	8e0080e7          	jalr	-1824(ra) # 8000337e <argaddr>
    return -1;
    80005aa6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005aa8:	00054d63          	bltz	a0,80005ac2 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005aac:	fe442603          	lw	a2,-28(s0)
    80005ab0:	fd843583          	ld	a1,-40(s0)
    80005ab4:	fe843503          	ld	a0,-24(s0)
    80005ab8:	fffff097          	auipc	ra,0xfffff
    80005abc:	4fa080e7          	jalr	1274(ra) # 80004fb2 <filewrite>
    80005ac0:	87aa                	mv	a5,a0
}
    80005ac2:	853e                	mv	a0,a5
    80005ac4:	70a2                	ld	ra,40(sp)
    80005ac6:	7402                	ld	s0,32(sp)
    80005ac8:	6145                	addi	sp,sp,48
    80005aca:	8082                	ret

0000000080005acc <sys_close>:
{
    80005acc:	1101                	addi	sp,sp,-32
    80005ace:	ec06                	sd	ra,24(sp)
    80005ad0:	e822                	sd	s0,16(sp)
    80005ad2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005ad4:	fe040613          	addi	a2,s0,-32
    80005ad8:	fec40593          	addi	a1,s0,-20
    80005adc:	4501                	li	a0,0
    80005ade:	00000097          	auipc	ra,0x0
    80005ae2:	cc2080e7          	jalr	-830(ra) # 800057a0 <argfd>
    return -1;
    80005ae6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005ae8:	02054463          	bltz	a0,80005b10 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005aec:	ffffc097          	auipc	ra,0xffffc
    80005af0:	370080e7          	jalr	880(ra) # 80001e5c <myproc>
    80005af4:	fec42783          	lw	a5,-20(s0)
    80005af8:	07f9                	addi	a5,a5,30
    80005afa:	078e                	slli	a5,a5,0x3
    80005afc:	97aa                	add	a5,a5,a0
    80005afe:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005b02:	fe043503          	ld	a0,-32(s0)
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	2b0080e7          	jalr	688(ra) # 80004db6 <fileclose>
  return 0;
    80005b0e:	4781                	li	a5,0
}
    80005b10:	853e                	mv	a0,a5
    80005b12:	60e2                	ld	ra,24(sp)
    80005b14:	6442                	ld	s0,16(sp)
    80005b16:	6105                	addi	sp,sp,32
    80005b18:	8082                	ret

0000000080005b1a <sys_fstat>:
{
    80005b1a:	1101                	addi	sp,sp,-32
    80005b1c:	ec06                	sd	ra,24(sp)
    80005b1e:	e822                	sd	s0,16(sp)
    80005b20:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b22:	fe840613          	addi	a2,s0,-24
    80005b26:	4581                	li	a1,0
    80005b28:	4501                	li	a0,0
    80005b2a:	00000097          	auipc	ra,0x0
    80005b2e:	c76080e7          	jalr	-906(ra) # 800057a0 <argfd>
    return -1;
    80005b32:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b34:	02054563          	bltz	a0,80005b5e <sys_fstat+0x44>
    80005b38:	fe040593          	addi	a1,s0,-32
    80005b3c:	4505                	li	a0,1
    80005b3e:	ffffe097          	auipc	ra,0xffffe
    80005b42:	840080e7          	jalr	-1984(ra) # 8000337e <argaddr>
    return -1;
    80005b46:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b48:	00054b63          	bltz	a0,80005b5e <sys_fstat+0x44>
  return filestat(f, st);
    80005b4c:	fe043583          	ld	a1,-32(s0)
    80005b50:	fe843503          	ld	a0,-24(s0)
    80005b54:	fffff097          	auipc	ra,0xfffff
    80005b58:	32a080e7          	jalr	810(ra) # 80004e7e <filestat>
    80005b5c:	87aa                	mv	a5,a0
}
    80005b5e:	853e                	mv	a0,a5
    80005b60:	60e2                	ld	ra,24(sp)
    80005b62:	6442                	ld	s0,16(sp)
    80005b64:	6105                	addi	sp,sp,32
    80005b66:	8082                	ret

0000000080005b68 <sys_link>:
{
    80005b68:	7169                	addi	sp,sp,-304
    80005b6a:	f606                	sd	ra,296(sp)
    80005b6c:	f222                	sd	s0,288(sp)
    80005b6e:	ee26                	sd	s1,280(sp)
    80005b70:	ea4a                	sd	s2,272(sp)
    80005b72:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b74:	08000613          	li	a2,128
    80005b78:	ed040593          	addi	a1,s0,-304
    80005b7c:	4501                	li	a0,0
    80005b7e:	ffffe097          	auipc	ra,0xffffe
    80005b82:	822080e7          	jalr	-2014(ra) # 800033a0 <argstr>
    return -1;
    80005b86:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b88:	10054e63          	bltz	a0,80005ca4 <sys_link+0x13c>
    80005b8c:	08000613          	li	a2,128
    80005b90:	f5040593          	addi	a1,s0,-176
    80005b94:	4505                	li	a0,1
    80005b96:	ffffe097          	auipc	ra,0xffffe
    80005b9a:	80a080e7          	jalr	-2038(ra) # 800033a0 <argstr>
    return -1;
    80005b9e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ba0:	10054263          	bltz	a0,80005ca4 <sys_link+0x13c>
  begin_op();
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	d46080e7          	jalr	-698(ra) # 800048ea <begin_op>
  if((ip = namei(old)) == 0){
    80005bac:	ed040513          	addi	a0,s0,-304
    80005bb0:	fffff097          	auipc	ra,0xfffff
    80005bb4:	b1e080e7          	jalr	-1250(ra) # 800046ce <namei>
    80005bb8:	84aa                	mv	s1,a0
    80005bba:	c551                	beqz	a0,80005c46 <sys_link+0xde>
  ilock(ip);
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	35c080e7          	jalr	860(ra) # 80003f18 <ilock>
  if(ip->type == T_DIR){
    80005bc4:	04449703          	lh	a4,68(s1)
    80005bc8:	4785                	li	a5,1
    80005bca:	08f70463          	beq	a4,a5,80005c52 <sys_link+0xea>
  ip->nlink++;
    80005bce:	04a4d783          	lhu	a5,74(s1)
    80005bd2:	2785                	addiw	a5,a5,1
    80005bd4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005bd8:	8526                	mv	a0,s1
    80005bda:	ffffe097          	auipc	ra,0xffffe
    80005bde:	274080e7          	jalr	628(ra) # 80003e4e <iupdate>
  iunlock(ip);
    80005be2:	8526                	mv	a0,s1
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	3f6080e7          	jalr	1014(ra) # 80003fda <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005bec:	fd040593          	addi	a1,s0,-48
    80005bf0:	f5040513          	addi	a0,s0,-176
    80005bf4:	fffff097          	auipc	ra,0xfffff
    80005bf8:	af8080e7          	jalr	-1288(ra) # 800046ec <nameiparent>
    80005bfc:	892a                	mv	s2,a0
    80005bfe:	c935                	beqz	a0,80005c72 <sys_link+0x10a>
  ilock(dp);
    80005c00:	ffffe097          	auipc	ra,0xffffe
    80005c04:	318080e7          	jalr	792(ra) # 80003f18 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005c08:	00092703          	lw	a4,0(s2)
    80005c0c:	409c                	lw	a5,0(s1)
    80005c0e:	04f71d63          	bne	a4,a5,80005c68 <sys_link+0x100>
    80005c12:	40d0                	lw	a2,4(s1)
    80005c14:	fd040593          	addi	a1,s0,-48
    80005c18:	854a                	mv	a0,s2
    80005c1a:	fffff097          	auipc	ra,0xfffff
    80005c1e:	9f2080e7          	jalr	-1550(ra) # 8000460c <dirlink>
    80005c22:	04054363          	bltz	a0,80005c68 <sys_link+0x100>
  iunlockput(dp);
    80005c26:	854a                	mv	a0,s2
    80005c28:	ffffe097          	auipc	ra,0xffffe
    80005c2c:	552080e7          	jalr	1362(ra) # 8000417a <iunlockput>
  iput(ip);
    80005c30:	8526                	mv	a0,s1
    80005c32:	ffffe097          	auipc	ra,0xffffe
    80005c36:	4a0080e7          	jalr	1184(ra) # 800040d2 <iput>
  end_op();
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	d30080e7          	jalr	-720(ra) # 8000496a <end_op>
  return 0;
    80005c42:	4781                	li	a5,0
    80005c44:	a085                	j	80005ca4 <sys_link+0x13c>
    end_op();
    80005c46:	fffff097          	auipc	ra,0xfffff
    80005c4a:	d24080e7          	jalr	-732(ra) # 8000496a <end_op>
    return -1;
    80005c4e:	57fd                	li	a5,-1
    80005c50:	a891                	j	80005ca4 <sys_link+0x13c>
    iunlockput(ip);
    80005c52:	8526                	mv	a0,s1
    80005c54:	ffffe097          	auipc	ra,0xffffe
    80005c58:	526080e7          	jalr	1318(ra) # 8000417a <iunlockput>
    end_op();
    80005c5c:	fffff097          	auipc	ra,0xfffff
    80005c60:	d0e080e7          	jalr	-754(ra) # 8000496a <end_op>
    return -1;
    80005c64:	57fd                	li	a5,-1
    80005c66:	a83d                	j	80005ca4 <sys_link+0x13c>
    iunlockput(dp);
    80005c68:	854a                	mv	a0,s2
    80005c6a:	ffffe097          	auipc	ra,0xffffe
    80005c6e:	510080e7          	jalr	1296(ra) # 8000417a <iunlockput>
  ilock(ip);
    80005c72:	8526                	mv	a0,s1
    80005c74:	ffffe097          	auipc	ra,0xffffe
    80005c78:	2a4080e7          	jalr	676(ra) # 80003f18 <ilock>
  ip->nlink--;
    80005c7c:	04a4d783          	lhu	a5,74(s1)
    80005c80:	37fd                	addiw	a5,a5,-1
    80005c82:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c86:	8526                	mv	a0,s1
    80005c88:	ffffe097          	auipc	ra,0xffffe
    80005c8c:	1c6080e7          	jalr	454(ra) # 80003e4e <iupdate>
  iunlockput(ip);
    80005c90:	8526                	mv	a0,s1
    80005c92:	ffffe097          	auipc	ra,0xffffe
    80005c96:	4e8080e7          	jalr	1256(ra) # 8000417a <iunlockput>
  end_op();
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	cd0080e7          	jalr	-816(ra) # 8000496a <end_op>
  return -1;
    80005ca2:	57fd                	li	a5,-1
}
    80005ca4:	853e                	mv	a0,a5
    80005ca6:	70b2                	ld	ra,296(sp)
    80005ca8:	7412                	ld	s0,288(sp)
    80005caa:	64f2                	ld	s1,280(sp)
    80005cac:	6952                	ld	s2,272(sp)
    80005cae:	6155                	addi	sp,sp,304
    80005cb0:	8082                	ret

0000000080005cb2 <sys_unlink>:
{
    80005cb2:	7151                	addi	sp,sp,-240
    80005cb4:	f586                	sd	ra,232(sp)
    80005cb6:	f1a2                	sd	s0,224(sp)
    80005cb8:	eda6                	sd	s1,216(sp)
    80005cba:	e9ca                	sd	s2,208(sp)
    80005cbc:	e5ce                	sd	s3,200(sp)
    80005cbe:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005cc0:	08000613          	li	a2,128
    80005cc4:	f3040593          	addi	a1,s0,-208
    80005cc8:	4501                	li	a0,0
    80005cca:	ffffd097          	auipc	ra,0xffffd
    80005cce:	6d6080e7          	jalr	1750(ra) # 800033a0 <argstr>
    80005cd2:	18054163          	bltz	a0,80005e54 <sys_unlink+0x1a2>
  begin_op();
    80005cd6:	fffff097          	auipc	ra,0xfffff
    80005cda:	c14080e7          	jalr	-1004(ra) # 800048ea <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005cde:	fb040593          	addi	a1,s0,-80
    80005ce2:	f3040513          	addi	a0,s0,-208
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	a06080e7          	jalr	-1530(ra) # 800046ec <nameiparent>
    80005cee:	84aa                	mv	s1,a0
    80005cf0:	c979                	beqz	a0,80005dc6 <sys_unlink+0x114>
  ilock(dp);
    80005cf2:	ffffe097          	auipc	ra,0xffffe
    80005cf6:	226080e7          	jalr	550(ra) # 80003f18 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005cfa:	00003597          	auipc	a1,0x3
    80005cfe:	a3e58593          	addi	a1,a1,-1474 # 80008738 <syscalls+0x2c0>
    80005d02:	fb040513          	addi	a0,s0,-80
    80005d06:	ffffe097          	auipc	ra,0xffffe
    80005d0a:	6dc080e7          	jalr	1756(ra) # 800043e2 <namecmp>
    80005d0e:	14050a63          	beqz	a0,80005e62 <sys_unlink+0x1b0>
    80005d12:	00003597          	auipc	a1,0x3
    80005d16:	a2e58593          	addi	a1,a1,-1490 # 80008740 <syscalls+0x2c8>
    80005d1a:	fb040513          	addi	a0,s0,-80
    80005d1e:	ffffe097          	auipc	ra,0xffffe
    80005d22:	6c4080e7          	jalr	1732(ra) # 800043e2 <namecmp>
    80005d26:	12050e63          	beqz	a0,80005e62 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005d2a:	f2c40613          	addi	a2,s0,-212
    80005d2e:	fb040593          	addi	a1,s0,-80
    80005d32:	8526                	mv	a0,s1
    80005d34:	ffffe097          	auipc	ra,0xffffe
    80005d38:	6c8080e7          	jalr	1736(ra) # 800043fc <dirlookup>
    80005d3c:	892a                	mv	s2,a0
    80005d3e:	12050263          	beqz	a0,80005e62 <sys_unlink+0x1b0>
  ilock(ip);
    80005d42:	ffffe097          	auipc	ra,0xffffe
    80005d46:	1d6080e7          	jalr	470(ra) # 80003f18 <ilock>
  if(ip->nlink < 1)
    80005d4a:	04a91783          	lh	a5,74(s2)
    80005d4e:	08f05263          	blez	a5,80005dd2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005d52:	04491703          	lh	a4,68(s2)
    80005d56:	4785                	li	a5,1
    80005d58:	08f70563          	beq	a4,a5,80005de2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005d5c:	4641                	li	a2,16
    80005d5e:	4581                	li	a1,0
    80005d60:	fc040513          	addi	a0,s0,-64
    80005d64:	ffffb097          	auipc	ra,0xffffb
    80005d68:	fae080e7          	jalr	-82(ra) # 80000d12 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d6c:	4741                	li	a4,16
    80005d6e:	f2c42683          	lw	a3,-212(s0)
    80005d72:	fc040613          	addi	a2,s0,-64
    80005d76:	4581                	li	a1,0
    80005d78:	8526                	mv	a0,s1
    80005d7a:	ffffe097          	auipc	ra,0xffffe
    80005d7e:	54a080e7          	jalr	1354(ra) # 800042c4 <writei>
    80005d82:	47c1                	li	a5,16
    80005d84:	0af51563          	bne	a0,a5,80005e2e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005d88:	04491703          	lh	a4,68(s2)
    80005d8c:	4785                	li	a5,1
    80005d8e:	0af70863          	beq	a4,a5,80005e3e <sys_unlink+0x18c>
  iunlockput(dp);
    80005d92:	8526                	mv	a0,s1
    80005d94:	ffffe097          	auipc	ra,0xffffe
    80005d98:	3e6080e7          	jalr	998(ra) # 8000417a <iunlockput>
  ip->nlink--;
    80005d9c:	04a95783          	lhu	a5,74(s2)
    80005da0:	37fd                	addiw	a5,a5,-1
    80005da2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005da6:	854a                	mv	a0,s2
    80005da8:	ffffe097          	auipc	ra,0xffffe
    80005dac:	0a6080e7          	jalr	166(ra) # 80003e4e <iupdate>
  iunlockput(ip);
    80005db0:	854a                	mv	a0,s2
    80005db2:	ffffe097          	auipc	ra,0xffffe
    80005db6:	3c8080e7          	jalr	968(ra) # 8000417a <iunlockput>
  end_op();
    80005dba:	fffff097          	auipc	ra,0xfffff
    80005dbe:	bb0080e7          	jalr	-1104(ra) # 8000496a <end_op>
  return 0;
    80005dc2:	4501                	li	a0,0
    80005dc4:	a84d                	j	80005e76 <sys_unlink+0x1c4>
    end_op();
    80005dc6:	fffff097          	auipc	ra,0xfffff
    80005dca:	ba4080e7          	jalr	-1116(ra) # 8000496a <end_op>
    return -1;
    80005dce:	557d                	li	a0,-1
    80005dd0:	a05d                	j	80005e76 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005dd2:	00003517          	auipc	a0,0x3
    80005dd6:	99650513          	addi	a0,a0,-1642 # 80008768 <syscalls+0x2f0>
    80005dda:	ffffa097          	auipc	ra,0xffffa
    80005dde:	764080e7          	jalr	1892(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005de2:	04c92703          	lw	a4,76(s2)
    80005de6:	02000793          	li	a5,32
    80005dea:	f6e7f9e3          	bgeu	a5,a4,80005d5c <sys_unlink+0xaa>
    80005dee:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005df2:	4741                	li	a4,16
    80005df4:	86ce                	mv	a3,s3
    80005df6:	f1840613          	addi	a2,s0,-232
    80005dfa:	4581                	li	a1,0
    80005dfc:	854a                	mv	a0,s2
    80005dfe:	ffffe097          	auipc	ra,0xffffe
    80005e02:	3ce080e7          	jalr	974(ra) # 800041cc <readi>
    80005e06:	47c1                	li	a5,16
    80005e08:	00f51b63          	bne	a0,a5,80005e1e <sys_unlink+0x16c>
    if(de.inum != 0)
    80005e0c:	f1845783          	lhu	a5,-232(s0)
    80005e10:	e7a1                	bnez	a5,80005e58 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e12:	29c1                	addiw	s3,s3,16
    80005e14:	04c92783          	lw	a5,76(s2)
    80005e18:	fcf9ede3          	bltu	s3,a5,80005df2 <sys_unlink+0x140>
    80005e1c:	b781                	j	80005d5c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005e1e:	00003517          	auipc	a0,0x3
    80005e22:	96250513          	addi	a0,a0,-1694 # 80008780 <syscalls+0x308>
    80005e26:	ffffa097          	auipc	ra,0xffffa
    80005e2a:	718080e7          	jalr	1816(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005e2e:	00003517          	auipc	a0,0x3
    80005e32:	96a50513          	addi	a0,a0,-1686 # 80008798 <syscalls+0x320>
    80005e36:	ffffa097          	auipc	ra,0xffffa
    80005e3a:	708080e7          	jalr	1800(ra) # 8000053e <panic>
    dp->nlink--;
    80005e3e:	04a4d783          	lhu	a5,74(s1)
    80005e42:	37fd                	addiw	a5,a5,-1
    80005e44:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005e48:	8526                	mv	a0,s1
    80005e4a:	ffffe097          	auipc	ra,0xffffe
    80005e4e:	004080e7          	jalr	4(ra) # 80003e4e <iupdate>
    80005e52:	b781                	j	80005d92 <sys_unlink+0xe0>
    return -1;
    80005e54:	557d                	li	a0,-1
    80005e56:	a005                	j	80005e76 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005e58:	854a                	mv	a0,s2
    80005e5a:	ffffe097          	auipc	ra,0xffffe
    80005e5e:	320080e7          	jalr	800(ra) # 8000417a <iunlockput>
  iunlockput(dp);
    80005e62:	8526                	mv	a0,s1
    80005e64:	ffffe097          	auipc	ra,0xffffe
    80005e68:	316080e7          	jalr	790(ra) # 8000417a <iunlockput>
  end_op();
    80005e6c:	fffff097          	auipc	ra,0xfffff
    80005e70:	afe080e7          	jalr	-1282(ra) # 8000496a <end_op>
  return -1;
    80005e74:	557d                	li	a0,-1
}
    80005e76:	70ae                	ld	ra,232(sp)
    80005e78:	740e                	ld	s0,224(sp)
    80005e7a:	64ee                	ld	s1,216(sp)
    80005e7c:	694e                	ld	s2,208(sp)
    80005e7e:	69ae                	ld	s3,200(sp)
    80005e80:	616d                	addi	sp,sp,240
    80005e82:	8082                	ret

0000000080005e84 <sys_open>:

uint64
sys_open(void)
{
    80005e84:	7131                	addi	sp,sp,-192
    80005e86:	fd06                	sd	ra,184(sp)
    80005e88:	f922                	sd	s0,176(sp)
    80005e8a:	f526                	sd	s1,168(sp)
    80005e8c:	f14a                	sd	s2,160(sp)
    80005e8e:	ed4e                	sd	s3,152(sp)
    80005e90:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005e92:	08000613          	li	a2,128
    80005e96:	f5040593          	addi	a1,s0,-176
    80005e9a:	4501                	li	a0,0
    80005e9c:	ffffd097          	auipc	ra,0xffffd
    80005ea0:	504080e7          	jalr	1284(ra) # 800033a0 <argstr>
    return -1;
    80005ea4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ea6:	0c054163          	bltz	a0,80005f68 <sys_open+0xe4>
    80005eaa:	f4c40593          	addi	a1,s0,-180
    80005eae:	4505                	li	a0,1
    80005eb0:	ffffd097          	auipc	ra,0xffffd
    80005eb4:	4ac080e7          	jalr	1196(ra) # 8000335c <argint>
    80005eb8:	0a054863          	bltz	a0,80005f68 <sys_open+0xe4>

  begin_op();
    80005ebc:	fffff097          	auipc	ra,0xfffff
    80005ec0:	a2e080e7          	jalr	-1490(ra) # 800048ea <begin_op>

  if(omode & O_CREATE){
    80005ec4:	f4c42783          	lw	a5,-180(s0)
    80005ec8:	2007f793          	andi	a5,a5,512
    80005ecc:	cbdd                	beqz	a5,80005f82 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ece:	4681                	li	a3,0
    80005ed0:	4601                	li	a2,0
    80005ed2:	4589                	li	a1,2
    80005ed4:	f5040513          	addi	a0,s0,-176
    80005ed8:	00000097          	auipc	ra,0x0
    80005edc:	972080e7          	jalr	-1678(ra) # 8000584a <create>
    80005ee0:	892a                	mv	s2,a0
    if(ip == 0){
    80005ee2:	c959                	beqz	a0,80005f78 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ee4:	04491703          	lh	a4,68(s2)
    80005ee8:	478d                	li	a5,3
    80005eea:	00f71763          	bne	a4,a5,80005ef8 <sys_open+0x74>
    80005eee:	04695703          	lhu	a4,70(s2)
    80005ef2:	47a5                	li	a5,9
    80005ef4:	0ce7ec63          	bltu	a5,a4,80005fcc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005ef8:	fffff097          	auipc	ra,0xfffff
    80005efc:	e02080e7          	jalr	-510(ra) # 80004cfa <filealloc>
    80005f00:	89aa                	mv	s3,a0
    80005f02:	10050263          	beqz	a0,80006006 <sys_open+0x182>
    80005f06:	00000097          	auipc	ra,0x0
    80005f0a:	902080e7          	jalr	-1790(ra) # 80005808 <fdalloc>
    80005f0e:	84aa                	mv	s1,a0
    80005f10:	0e054663          	bltz	a0,80005ffc <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005f14:	04491703          	lh	a4,68(s2)
    80005f18:	478d                	li	a5,3
    80005f1a:	0cf70463          	beq	a4,a5,80005fe2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005f1e:	4789                	li	a5,2
    80005f20:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005f24:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005f28:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005f2c:	f4c42783          	lw	a5,-180(s0)
    80005f30:	0017c713          	xori	a4,a5,1
    80005f34:	8b05                	andi	a4,a4,1
    80005f36:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005f3a:	0037f713          	andi	a4,a5,3
    80005f3e:	00e03733          	snez	a4,a4
    80005f42:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005f46:	4007f793          	andi	a5,a5,1024
    80005f4a:	c791                	beqz	a5,80005f56 <sys_open+0xd2>
    80005f4c:	04491703          	lh	a4,68(s2)
    80005f50:	4789                	li	a5,2
    80005f52:	08f70f63          	beq	a4,a5,80005ff0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005f56:	854a                	mv	a0,s2
    80005f58:	ffffe097          	auipc	ra,0xffffe
    80005f5c:	082080e7          	jalr	130(ra) # 80003fda <iunlock>
  end_op();
    80005f60:	fffff097          	auipc	ra,0xfffff
    80005f64:	a0a080e7          	jalr	-1526(ra) # 8000496a <end_op>

  return fd;
}
    80005f68:	8526                	mv	a0,s1
    80005f6a:	70ea                	ld	ra,184(sp)
    80005f6c:	744a                	ld	s0,176(sp)
    80005f6e:	74aa                	ld	s1,168(sp)
    80005f70:	790a                	ld	s2,160(sp)
    80005f72:	69ea                	ld	s3,152(sp)
    80005f74:	6129                	addi	sp,sp,192
    80005f76:	8082                	ret
      end_op();
    80005f78:	fffff097          	auipc	ra,0xfffff
    80005f7c:	9f2080e7          	jalr	-1550(ra) # 8000496a <end_op>
      return -1;
    80005f80:	b7e5                	j	80005f68 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005f82:	f5040513          	addi	a0,s0,-176
    80005f86:	ffffe097          	auipc	ra,0xffffe
    80005f8a:	748080e7          	jalr	1864(ra) # 800046ce <namei>
    80005f8e:	892a                	mv	s2,a0
    80005f90:	c905                	beqz	a0,80005fc0 <sys_open+0x13c>
    ilock(ip);
    80005f92:	ffffe097          	auipc	ra,0xffffe
    80005f96:	f86080e7          	jalr	-122(ra) # 80003f18 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005f9a:	04491703          	lh	a4,68(s2)
    80005f9e:	4785                	li	a5,1
    80005fa0:	f4f712e3          	bne	a4,a5,80005ee4 <sys_open+0x60>
    80005fa4:	f4c42783          	lw	a5,-180(s0)
    80005fa8:	dba1                	beqz	a5,80005ef8 <sys_open+0x74>
      iunlockput(ip);
    80005faa:	854a                	mv	a0,s2
    80005fac:	ffffe097          	auipc	ra,0xffffe
    80005fb0:	1ce080e7          	jalr	462(ra) # 8000417a <iunlockput>
      end_op();
    80005fb4:	fffff097          	auipc	ra,0xfffff
    80005fb8:	9b6080e7          	jalr	-1610(ra) # 8000496a <end_op>
      return -1;
    80005fbc:	54fd                	li	s1,-1
    80005fbe:	b76d                	j	80005f68 <sys_open+0xe4>
      end_op();
    80005fc0:	fffff097          	auipc	ra,0xfffff
    80005fc4:	9aa080e7          	jalr	-1622(ra) # 8000496a <end_op>
      return -1;
    80005fc8:	54fd                	li	s1,-1
    80005fca:	bf79                	j	80005f68 <sys_open+0xe4>
    iunlockput(ip);
    80005fcc:	854a                	mv	a0,s2
    80005fce:	ffffe097          	auipc	ra,0xffffe
    80005fd2:	1ac080e7          	jalr	428(ra) # 8000417a <iunlockput>
    end_op();
    80005fd6:	fffff097          	auipc	ra,0xfffff
    80005fda:	994080e7          	jalr	-1644(ra) # 8000496a <end_op>
    return -1;
    80005fde:	54fd                	li	s1,-1
    80005fe0:	b761                	j	80005f68 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005fe2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005fe6:	04691783          	lh	a5,70(s2)
    80005fea:	02f99223          	sh	a5,36(s3)
    80005fee:	bf2d                	j	80005f28 <sys_open+0xa4>
    itrunc(ip);
    80005ff0:	854a                	mv	a0,s2
    80005ff2:	ffffe097          	auipc	ra,0xffffe
    80005ff6:	034080e7          	jalr	52(ra) # 80004026 <itrunc>
    80005ffa:	bfb1                	j	80005f56 <sys_open+0xd2>
      fileclose(f);
    80005ffc:	854e                	mv	a0,s3
    80005ffe:	fffff097          	auipc	ra,0xfffff
    80006002:	db8080e7          	jalr	-584(ra) # 80004db6 <fileclose>
    iunlockput(ip);
    80006006:	854a                	mv	a0,s2
    80006008:	ffffe097          	auipc	ra,0xffffe
    8000600c:	172080e7          	jalr	370(ra) # 8000417a <iunlockput>
    end_op();
    80006010:	fffff097          	auipc	ra,0xfffff
    80006014:	95a080e7          	jalr	-1702(ra) # 8000496a <end_op>
    return -1;
    80006018:	54fd                	li	s1,-1
    8000601a:	b7b9                	j	80005f68 <sys_open+0xe4>

000000008000601c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000601c:	7175                	addi	sp,sp,-144
    8000601e:	e506                	sd	ra,136(sp)
    80006020:	e122                	sd	s0,128(sp)
    80006022:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006024:	fffff097          	auipc	ra,0xfffff
    80006028:	8c6080e7          	jalr	-1850(ra) # 800048ea <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000602c:	08000613          	li	a2,128
    80006030:	f7040593          	addi	a1,s0,-144
    80006034:	4501                	li	a0,0
    80006036:	ffffd097          	auipc	ra,0xffffd
    8000603a:	36a080e7          	jalr	874(ra) # 800033a0 <argstr>
    8000603e:	02054963          	bltz	a0,80006070 <sys_mkdir+0x54>
    80006042:	4681                	li	a3,0
    80006044:	4601                	li	a2,0
    80006046:	4585                	li	a1,1
    80006048:	f7040513          	addi	a0,s0,-144
    8000604c:	fffff097          	auipc	ra,0xfffff
    80006050:	7fe080e7          	jalr	2046(ra) # 8000584a <create>
    80006054:	cd11                	beqz	a0,80006070 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006056:	ffffe097          	auipc	ra,0xffffe
    8000605a:	124080e7          	jalr	292(ra) # 8000417a <iunlockput>
  end_op();
    8000605e:	fffff097          	auipc	ra,0xfffff
    80006062:	90c080e7          	jalr	-1780(ra) # 8000496a <end_op>
  return 0;
    80006066:	4501                	li	a0,0
}
    80006068:	60aa                	ld	ra,136(sp)
    8000606a:	640a                	ld	s0,128(sp)
    8000606c:	6149                	addi	sp,sp,144
    8000606e:	8082                	ret
    end_op();
    80006070:	fffff097          	auipc	ra,0xfffff
    80006074:	8fa080e7          	jalr	-1798(ra) # 8000496a <end_op>
    return -1;
    80006078:	557d                	li	a0,-1
    8000607a:	b7fd                	j	80006068 <sys_mkdir+0x4c>

000000008000607c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000607c:	7135                	addi	sp,sp,-160
    8000607e:	ed06                	sd	ra,152(sp)
    80006080:	e922                	sd	s0,144(sp)
    80006082:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006084:	fffff097          	auipc	ra,0xfffff
    80006088:	866080e7          	jalr	-1946(ra) # 800048ea <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000608c:	08000613          	li	a2,128
    80006090:	f7040593          	addi	a1,s0,-144
    80006094:	4501                	li	a0,0
    80006096:	ffffd097          	auipc	ra,0xffffd
    8000609a:	30a080e7          	jalr	778(ra) # 800033a0 <argstr>
    8000609e:	04054a63          	bltz	a0,800060f2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800060a2:	f6c40593          	addi	a1,s0,-148
    800060a6:	4505                	li	a0,1
    800060a8:	ffffd097          	auipc	ra,0xffffd
    800060ac:	2b4080e7          	jalr	692(ra) # 8000335c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800060b0:	04054163          	bltz	a0,800060f2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800060b4:	f6840593          	addi	a1,s0,-152
    800060b8:	4509                	li	a0,2
    800060ba:	ffffd097          	auipc	ra,0xffffd
    800060be:	2a2080e7          	jalr	674(ra) # 8000335c <argint>
     argint(1, &major) < 0 ||
    800060c2:	02054863          	bltz	a0,800060f2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800060c6:	f6841683          	lh	a3,-152(s0)
    800060ca:	f6c41603          	lh	a2,-148(s0)
    800060ce:	458d                	li	a1,3
    800060d0:	f7040513          	addi	a0,s0,-144
    800060d4:	fffff097          	auipc	ra,0xfffff
    800060d8:	776080e7          	jalr	1910(ra) # 8000584a <create>
     argint(2, &minor) < 0 ||
    800060dc:	c919                	beqz	a0,800060f2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800060de:	ffffe097          	auipc	ra,0xffffe
    800060e2:	09c080e7          	jalr	156(ra) # 8000417a <iunlockput>
  end_op();
    800060e6:	fffff097          	auipc	ra,0xfffff
    800060ea:	884080e7          	jalr	-1916(ra) # 8000496a <end_op>
  return 0;
    800060ee:	4501                	li	a0,0
    800060f0:	a031                	j	800060fc <sys_mknod+0x80>
    end_op();
    800060f2:	fffff097          	auipc	ra,0xfffff
    800060f6:	878080e7          	jalr	-1928(ra) # 8000496a <end_op>
    return -1;
    800060fa:	557d                	li	a0,-1
}
    800060fc:	60ea                	ld	ra,152(sp)
    800060fe:	644a                	ld	s0,144(sp)
    80006100:	610d                	addi	sp,sp,160
    80006102:	8082                	ret

0000000080006104 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006104:	7135                	addi	sp,sp,-160
    80006106:	ed06                	sd	ra,152(sp)
    80006108:	e922                	sd	s0,144(sp)
    8000610a:	e526                	sd	s1,136(sp)
    8000610c:	e14a                	sd	s2,128(sp)
    8000610e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006110:	ffffc097          	auipc	ra,0xffffc
    80006114:	d4c080e7          	jalr	-692(ra) # 80001e5c <myproc>
    80006118:	892a                	mv	s2,a0
  
  begin_op();
    8000611a:	ffffe097          	auipc	ra,0xffffe
    8000611e:	7d0080e7          	jalr	2000(ra) # 800048ea <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006122:	08000613          	li	a2,128
    80006126:	f6040593          	addi	a1,s0,-160
    8000612a:	4501                	li	a0,0
    8000612c:	ffffd097          	auipc	ra,0xffffd
    80006130:	274080e7          	jalr	628(ra) # 800033a0 <argstr>
    80006134:	04054b63          	bltz	a0,8000618a <sys_chdir+0x86>
    80006138:	f6040513          	addi	a0,s0,-160
    8000613c:	ffffe097          	auipc	ra,0xffffe
    80006140:	592080e7          	jalr	1426(ra) # 800046ce <namei>
    80006144:	84aa                	mv	s1,a0
    80006146:	c131                	beqz	a0,8000618a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006148:	ffffe097          	auipc	ra,0xffffe
    8000614c:	dd0080e7          	jalr	-560(ra) # 80003f18 <ilock>
  if(ip->type != T_DIR){
    80006150:	04449703          	lh	a4,68(s1)
    80006154:	4785                	li	a5,1
    80006156:	04f71063          	bne	a4,a5,80006196 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000615a:	8526                	mv	a0,s1
    8000615c:	ffffe097          	auipc	ra,0xffffe
    80006160:	e7e080e7          	jalr	-386(ra) # 80003fda <iunlock>
  iput(p->cwd);
    80006164:	17093503          	ld	a0,368(s2)
    80006168:	ffffe097          	auipc	ra,0xffffe
    8000616c:	f6a080e7          	jalr	-150(ra) # 800040d2 <iput>
  end_op();
    80006170:	ffffe097          	auipc	ra,0xffffe
    80006174:	7fa080e7          	jalr	2042(ra) # 8000496a <end_op>
  p->cwd = ip;
    80006178:	16993823          	sd	s1,368(s2)
  return 0;
    8000617c:	4501                	li	a0,0
}
    8000617e:	60ea                	ld	ra,152(sp)
    80006180:	644a                	ld	s0,144(sp)
    80006182:	64aa                	ld	s1,136(sp)
    80006184:	690a                	ld	s2,128(sp)
    80006186:	610d                	addi	sp,sp,160
    80006188:	8082                	ret
    end_op();
    8000618a:	ffffe097          	auipc	ra,0xffffe
    8000618e:	7e0080e7          	jalr	2016(ra) # 8000496a <end_op>
    return -1;
    80006192:	557d                	li	a0,-1
    80006194:	b7ed                	j	8000617e <sys_chdir+0x7a>
    iunlockput(ip);
    80006196:	8526                	mv	a0,s1
    80006198:	ffffe097          	auipc	ra,0xffffe
    8000619c:	fe2080e7          	jalr	-30(ra) # 8000417a <iunlockput>
    end_op();
    800061a0:	ffffe097          	auipc	ra,0xffffe
    800061a4:	7ca080e7          	jalr	1994(ra) # 8000496a <end_op>
    return -1;
    800061a8:	557d                	li	a0,-1
    800061aa:	bfd1                	j	8000617e <sys_chdir+0x7a>

00000000800061ac <sys_exec>:

uint64
sys_exec(void)
{
    800061ac:	7145                	addi	sp,sp,-464
    800061ae:	e786                	sd	ra,456(sp)
    800061b0:	e3a2                	sd	s0,448(sp)
    800061b2:	ff26                	sd	s1,440(sp)
    800061b4:	fb4a                	sd	s2,432(sp)
    800061b6:	f74e                	sd	s3,424(sp)
    800061b8:	f352                	sd	s4,416(sp)
    800061ba:	ef56                	sd	s5,408(sp)
    800061bc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800061be:	08000613          	li	a2,128
    800061c2:	f4040593          	addi	a1,s0,-192
    800061c6:	4501                	li	a0,0
    800061c8:	ffffd097          	auipc	ra,0xffffd
    800061cc:	1d8080e7          	jalr	472(ra) # 800033a0 <argstr>
    return -1;
    800061d0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800061d2:	0c054a63          	bltz	a0,800062a6 <sys_exec+0xfa>
    800061d6:	e3840593          	addi	a1,s0,-456
    800061da:	4505                	li	a0,1
    800061dc:	ffffd097          	auipc	ra,0xffffd
    800061e0:	1a2080e7          	jalr	418(ra) # 8000337e <argaddr>
    800061e4:	0c054163          	bltz	a0,800062a6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800061e8:	10000613          	li	a2,256
    800061ec:	4581                	li	a1,0
    800061ee:	e4040513          	addi	a0,s0,-448
    800061f2:	ffffb097          	auipc	ra,0xffffb
    800061f6:	b20080e7          	jalr	-1248(ra) # 80000d12 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800061fa:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800061fe:	89a6                	mv	s3,s1
    80006200:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006202:	02000a13          	li	s4,32
    80006206:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000620a:	00391513          	slli	a0,s2,0x3
    8000620e:	e3040593          	addi	a1,s0,-464
    80006212:	e3843783          	ld	a5,-456(s0)
    80006216:	953e                	add	a0,a0,a5
    80006218:	ffffd097          	auipc	ra,0xffffd
    8000621c:	0aa080e7          	jalr	170(ra) # 800032c2 <fetchaddr>
    80006220:	02054a63          	bltz	a0,80006254 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006224:	e3043783          	ld	a5,-464(s0)
    80006228:	c3b9                	beqz	a5,8000626e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000622a:	ffffb097          	auipc	ra,0xffffb
    8000622e:	8ca080e7          	jalr	-1846(ra) # 80000af4 <kalloc>
    80006232:	85aa                	mv	a1,a0
    80006234:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006238:	cd11                	beqz	a0,80006254 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000623a:	6605                	lui	a2,0x1
    8000623c:	e3043503          	ld	a0,-464(s0)
    80006240:	ffffd097          	auipc	ra,0xffffd
    80006244:	0d4080e7          	jalr	212(ra) # 80003314 <fetchstr>
    80006248:	00054663          	bltz	a0,80006254 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000624c:	0905                	addi	s2,s2,1
    8000624e:	09a1                	addi	s3,s3,8
    80006250:	fb491be3          	bne	s2,s4,80006206 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006254:	10048913          	addi	s2,s1,256
    80006258:	6088                	ld	a0,0(s1)
    8000625a:	c529                	beqz	a0,800062a4 <sys_exec+0xf8>
    kfree(argv[i]);
    8000625c:	ffffa097          	auipc	ra,0xffffa
    80006260:	79c080e7          	jalr	1948(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006264:	04a1                	addi	s1,s1,8
    80006266:	ff2499e3          	bne	s1,s2,80006258 <sys_exec+0xac>
  return -1;
    8000626a:	597d                	li	s2,-1
    8000626c:	a82d                	j	800062a6 <sys_exec+0xfa>
      argv[i] = 0;
    8000626e:	0a8e                	slli	s5,s5,0x3
    80006270:	fc040793          	addi	a5,s0,-64
    80006274:	9abe                	add	s5,s5,a5
    80006276:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000627a:	e4040593          	addi	a1,s0,-448
    8000627e:	f4040513          	addi	a0,s0,-192
    80006282:	fffff097          	auipc	ra,0xfffff
    80006286:	194080e7          	jalr	404(ra) # 80005416 <exec>
    8000628a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000628c:	10048993          	addi	s3,s1,256
    80006290:	6088                	ld	a0,0(s1)
    80006292:	c911                	beqz	a0,800062a6 <sys_exec+0xfa>
    kfree(argv[i]);
    80006294:	ffffa097          	auipc	ra,0xffffa
    80006298:	764080e7          	jalr	1892(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000629c:	04a1                	addi	s1,s1,8
    8000629e:	ff3499e3          	bne	s1,s3,80006290 <sys_exec+0xe4>
    800062a2:	a011                	j	800062a6 <sys_exec+0xfa>
  return -1;
    800062a4:	597d                	li	s2,-1
}
    800062a6:	854a                	mv	a0,s2
    800062a8:	60be                	ld	ra,456(sp)
    800062aa:	641e                	ld	s0,448(sp)
    800062ac:	74fa                	ld	s1,440(sp)
    800062ae:	795a                	ld	s2,432(sp)
    800062b0:	79ba                	ld	s3,424(sp)
    800062b2:	7a1a                	ld	s4,416(sp)
    800062b4:	6afa                	ld	s5,408(sp)
    800062b6:	6179                	addi	sp,sp,464
    800062b8:	8082                	ret

00000000800062ba <sys_pipe>:

uint64
sys_pipe(void)
{
    800062ba:	7139                	addi	sp,sp,-64
    800062bc:	fc06                	sd	ra,56(sp)
    800062be:	f822                	sd	s0,48(sp)
    800062c0:	f426                	sd	s1,40(sp)
    800062c2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800062c4:	ffffc097          	auipc	ra,0xffffc
    800062c8:	b98080e7          	jalr	-1128(ra) # 80001e5c <myproc>
    800062cc:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800062ce:	fd840593          	addi	a1,s0,-40
    800062d2:	4501                	li	a0,0
    800062d4:	ffffd097          	auipc	ra,0xffffd
    800062d8:	0aa080e7          	jalr	170(ra) # 8000337e <argaddr>
    return -1;
    800062dc:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800062de:	0e054063          	bltz	a0,800063be <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800062e2:	fc840593          	addi	a1,s0,-56
    800062e6:	fd040513          	addi	a0,s0,-48
    800062ea:	fffff097          	auipc	ra,0xfffff
    800062ee:	dfc080e7          	jalr	-516(ra) # 800050e6 <pipealloc>
    return -1;
    800062f2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800062f4:	0c054563          	bltz	a0,800063be <sys_pipe+0x104>
  fd0 = -1;
    800062f8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800062fc:	fd043503          	ld	a0,-48(s0)
    80006300:	fffff097          	auipc	ra,0xfffff
    80006304:	508080e7          	jalr	1288(ra) # 80005808 <fdalloc>
    80006308:	fca42223          	sw	a0,-60(s0)
    8000630c:	08054c63          	bltz	a0,800063a4 <sys_pipe+0xea>
    80006310:	fc843503          	ld	a0,-56(s0)
    80006314:	fffff097          	auipc	ra,0xfffff
    80006318:	4f4080e7          	jalr	1268(ra) # 80005808 <fdalloc>
    8000631c:	fca42023          	sw	a0,-64(s0)
    80006320:	06054863          	bltz	a0,80006390 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006324:	4691                	li	a3,4
    80006326:	fc440613          	addi	a2,s0,-60
    8000632a:	fd843583          	ld	a1,-40(s0)
    8000632e:	78a8                	ld	a0,112(s1)
    80006330:	ffffb097          	auipc	ra,0xffffb
    80006334:	374080e7          	jalr	884(ra) # 800016a4 <copyout>
    80006338:	02054063          	bltz	a0,80006358 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000633c:	4691                	li	a3,4
    8000633e:	fc040613          	addi	a2,s0,-64
    80006342:	fd843583          	ld	a1,-40(s0)
    80006346:	0591                	addi	a1,a1,4
    80006348:	78a8                	ld	a0,112(s1)
    8000634a:	ffffb097          	auipc	ra,0xffffb
    8000634e:	35a080e7          	jalr	858(ra) # 800016a4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006352:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006354:	06055563          	bgez	a0,800063be <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006358:	fc442783          	lw	a5,-60(s0)
    8000635c:	07f9                	addi	a5,a5,30
    8000635e:	078e                	slli	a5,a5,0x3
    80006360:	97a6                	add	a5,a5,s1
    80006362:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006366:	fc042503          	lw	a0,-64(s0)
    8000636a:	0579                	addi	a0,a0,30
    8000636c:	050e                	slli	a0,a0,0x3
    8000636e:	9526                	add	a0,a0,s1
    80006370:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006374:	fd043503          	ld	a0,-48(s0)
    80006378:	fffff097          	auipc	ra,0xfffff
    8000637c:	a3e080e7          	jalr	-1474(ra) # 80004db6 <fileclose>
    fileclose(wf);
    80006380:	fc843503          	ld	a0,-56(s0)
    80006384:	fffff097          	auipc	ra,0xfffff
    80006388:	a32080e7          	jalr	-1486(ra) # 80004db6 <fileclose>
    return -1;
    8000638c:	57fd                	li	a5,-1
    8000638e:	a805                	j	800063be <sys_pipe+0x104>
    if(fd0 >= 0)
    80006390:	fc442783          	lw	a5,-60(s0)
    80006394:	0007c863          	bltz	a5,800063a4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006398:	01e78513          	addi	a0,a5,30
    8000639c:	050e                	slli	a0,a0,0x3
    8000639e:	9526                	add	a0,a0,s1
    800063a0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800063a4:	fd043503          	ld	a0,-48(s0)
    800063a8:	fffff097          	auipc	ra,0xfffff
    800063ac:	a0e080e7          	jalr	-1522(ra) # 80004db6 <fileclose>
    fileclose(wf);
    800063b0:	fc843503          	ld	a0,-56(s0)
    800063b4:	fffff097          	auipc	ra,0xfffff
    800063b8:	a02080e7          	jalr	-1534(ra) # 80004db6 <fileclose>
    return -1;
    800063bc:	57fd                	li	a5,-1
}
    800063be:	853e                	mv	a0,a5
    800063c0:	70e2                	ld	ra,56(sp)
    800063c2:	7442                	ld	s0,48(sp)
    800063c4:	74a2                	ld	s1,40(sp)
    800063c6:	6121                	addi	sp,sp,64
    800063c8:	8082                	ret
    800063ca:	0000                	unimp
    800063cc:	0000                	unimp
	...

00000000800063d0 <kernelvec>:
    800063d0:	7111                	addi	sp,sp,-256
    800063d2:	e006                	sd	ra,0(sp)
    800063d4:	e40a                	sd	sp,8(sp)
    800063d6:	e80e                	sd	gp,16(sp)
    800063d8:	ec12                	sd	tp,24(sp)
    800063da:	f016                	sd	t0,32(sp)
    800063dc:	f41a                	sd	t1,40(sp)
    800063de:	f81e                	sd	t2,48(sp)
    800063e0:	fc22                	sd	s0,56(sp)
    800063e2:	e0a6                	sd	s1,64(sp)
    800063e4:	e4aa                	sd	a0,72(sp)
    800063e6:	e8ae                	sd	a1,80(sp)
    800063e8:	ecb2                	sd	a2,88(sp)
    800063ea:	f0b6                	sd	a3,96(sp)
    800063ec:	f4ba                	sd	a4,104(sp)
    800063ee:	f8be                	sd	a5,112(sp)
    800063f0:	fcc2                	sd	a6,120(sp)
    800063f2:	e146                	sd	a7,128(sp)
    800063f4:	e54a                	sd	s2,136(sp)
    800063f6:	e94e                	sd	s3,144(sp)
    800063f8:	ed52                	sd	s4,152(sp)
    800063fa:	f156                	sd	s5,160(sp)
    800063fc:	f55a                	sd	s6,168(sp)
    800063fe:	f95e                	sd	s7,176(sp)
    80006400:	fd62                	sd	s8,184(sp)
    80006402:	e1e6                	sd	s9,192(sp)
    80006404:	e5ea                	sd	s10,200(sp)
    80006406:	e9ee                	sd	s11,208(sp)
    80006408:	edf2                	sd	t3,216(sp)
    8000640a:	f1f6                	sd	t4,224(sp)
    8000640c:	f5fa                	sd	t5,232(sp)
    8000640e:	f9fe                	sd	t6,240(sp)
    80006410:	d7ffc0ef          	jal	ra,8000318e <kerneltrap>
    80006414:	6082                	ld	ra,0(sp)
    80006416:	6122                	ld	sp,8(sp)
    80006418:	61c2                	ld	gp,16(sp)
    8000641a:	7282                	ld	t0,32(sp)
    8000641c:	7322                	ld	t1,40(sp)
    8000641e:	73c2                	ld	t2,48(sp)
    80006420:	7462                	ld	s0,56(sp)
    80006422:	6486                	ld	s1,64(sp)
    80006424:	6526                	ld	a0,72(sp)
    80006426:	65c6                	ld	a1,80(sp)
    80006428:	6666                	ld	a2,88(sp)
    8000642a:	7686                	ld	a3,96(sp)
    8000642c:	7726                	ld	a4,104(sp)
    8000642e:	77c6                	ld	a5,112(sp)
    80006430:	7866                	ld	a6,120(sp)
    80006432:	688a                	ld	a7,128(sp)
    80006434:	692a                	ld	s2,136(sp)
    80006436:	69ca                	ld	s3,144(sp)
    80006438:	6a6a                	ld	s4,152(sp)
    8000643a:	7a8a                	ld	s5,160(sp)
    8000643c:	7b2a                	ld	s6,168(sp)
    8000643e:	7bca                	ld	s7,176(sp)
    80006440:	7c6a                	ld	s8,184(sp)
    80006442:	6c8e                	ld	s9,192(sp)
    80006444:	6d2e                	ld	s10,200(sp)
    80006446:	6dce                	ld	s11,208(sp)
    80006448:	6e6e                	ld	t3,216(sp)
    8000644a:	7e8e                	ld	t4,224(sp)
    8000644c:	7f2e                	ld	t5,232(sp)
    8000644e:	7fce                	ld	t6,240(sp)
    80006450:	6111                	addi	sp,sp,256
    80006452:	10200073          	sret
    80006456:	00000013          	nop
    8000645a:	00000013          	nop
    8000645e:	0001                	nop

0000000080006460 <timervec>:
    80006460:	34051573          	csrrw	a0,mscratch,a0
    80006464:	e10c                	sd	a1,0(a0)
    80006466:	e510                	sd	a2,8(a0)
    80006468:	e914                	sd	a3,16(a0)
    8000646a:	6d0c                	ld	a1,24(a0)
    8000646c:	7110                	ld	a2,32(a0)
    8000646e:	6194                	ld	a3,0(a1)
    80006470:	96b2                	add	a3,a3,a2
    80006472:	e194                	sd	a3,0(a1)
    80006474:	4589                	li	a1,2
    80006476:	14459073          	csrw	sip,a1
    8000647a:	6914                	ld	a3,16(a0)
    8000647c:	6510                	ld	a2,8(a0)
    8000647e:	610c                	ld	a1,0(a0)
    80006480:	34051573          	csrrw	a0,mscratch,a0
    80006484:	30200073          	mret
	...

000000008000648a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000648a:	1141                	addi	sp,sp,-16
    8000648c:	e422                	sd	s0,8(sp)
    8000648e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006490:	0c0007b7          	lui	a5,0xc000
    80006494:	4705                	li	a4,1
    80006496:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006498:	c3d8                	sw	a4,4(a5)
}
    8000649a:	6422                	ld	s0,8(sp)
    8000649c:	0141                	addi	sp,sp,16
    8000649e:	8082                	ret

00000000800064a0 <plicinithart>:

void
plicinithart(void)
{
    800064a0:	1141                	addi	sp,sp,-16
    800064a2:	e406                	sd	ra,8(sp)
    800064a4:	e022                	sd	s0,0(sp)
    800064a6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064a8:	ffffc097          	auipc	ra,0xffffc
    800064ac:	982080e7          	jalr	-1662(ra) # 80001e2a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800064b0:	0085171b          	slliw	a4,a0,0x8
    800064b4:	0c0027b7          	lui	a5,0xc002
    800064b8:	97ba                	add	a5,a5,a4
    800064ba:	40200713          	li	a4,1026
    800064be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800064c2:	00d5151b          	slliw	a0,a0,0xd
    800064c6:	0c2017b7          	lui	a5,0xc201
    800064ca:	953e                	add	a0,a0,a5
    800064cc:	00052023          	sw	zero,0(a0)
}
    800064d0:	60a2                	ld	ra,8(sp)
    800064d2:	6402                	ld	s0,0(sp)
    800064d4:	0141                	addi	sp,sp,16
    800064d6:	8082                	ret

00000000800064d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800064d8:	1141                	addi	sp,sp,-16
    800064da:	e406                	sd	ra,8(sp)
    800064dc:	e022                	sd	s0,0(sp)
    800064de:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064e0:	ffffc097          	auipc	ra,0xffffc
    800064e4:	94a080e7          	jalr	-1718(ra) # 80001e2a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800064e8:	00d5179b          	slliw	a5,a0,0xd
    800064ec:	0c201537          	lui	a0,0xc201
    800064f0:	953e                	add	a0,a0,a5
  return irq;
}
    800064f2:	4148                	lw	a0,4(a0)
    800064f4:	60a2                	ld	ra,8(sp)
    800064f6:	6402                	ld	s0,0(sp)
    800064f8:	0141                	addi	sp,sp,16
    800064fa:	8082                	ret

00000000800064fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800064fc:	1101                	addi	sp,sp,-32
    800064fe:	ec06                	sd	ra,24(sp)
    80006500:	e822                	sd	s0,16(sp)
    80006502:	e426                	sd	s1,8(sp)
    80006504:	1000                	addi	s0,sp,32
    80006506:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006508:	ffffc097          	auipc	ra,0xffffc
    8000650c:	922080e7          	jalr	-1758(ra) # 80001e2a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006510:	00d5151b          	slliw	a0,a0,0xd
    80006514:	0c2017b7          	lui	a5,0xc201
    80006518:	97aa                	add	a5,a5,a0
    8000651a:	c3c4                	sw	s1,4(a5)
}
    8000651c:	60e2                	ld	ra,24(sp)
    8000651e:	6442                	ld	s0,16(sp)
    80006520:	64a2                	ld	s1,8(sp)
    80006522:	6105                	addi	sp,sp,32
    80006524:	8082                	ret

0000000080006526 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006526:	1141                	addi	sp,sp,-16
    80006528:	e406                	sd	ra,8(sp)
    8000652a:	e022                	sd	s0,0(sp)
    8000652c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000652e:	479d                	li	a5,7
    80006530:	06a7c963          	blt	a5,a0,800065a2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006534:	0001d797          	auipc	a5,0x1d
    80006538:	acc78793          	addi	a5,a5,-1332 # 80023000 <disk>
    8000653c:	00a78733          	add	a4,a5,a0
    80006540:	6789                	lui	a5,0x2
    80006542:	97ba                	add	a5,a5,a4
    80006544:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006548:	e7ad                	bnez	a5,800065b2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000654a:	00451793          	slli	a5,a0,0x4
    8000654e:	0001f717          	auipc	a4,0x1f
    80006552:	ab270713          	addi	a4,a4,-1358 # 80025000 <disk+0x2000>
    80006556:	6314                	ld	a3,0(a4)
    80006558:	96be                	add	a3,a3,a5
    8000655a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000655e:	6314                	ld	a3,0(a4)
    80006560:	96be                	add	a3,a3,a5
    80006562:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006566:	6314                	ld	a3,0(a4)
    80006568:	96be                	add	a3,a3,a5
    8000656a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000656e:	6318                	ld	a4,0(a4)
    80006570:	97ba                	add	a5,a5,a4
    80006572:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006576:	0001d797          	auipc	a5,0x1d
    8000657a:	a8a78793          	addi	a5,a5,-1398 # 80023000 <disk>
    8000657e:	97aa                	add	a5,a5,a0
    80006580:	6509                	lui	a0,0x2
    80006582:	953e                	add	a0,a0,a5
    80006584:	4785                	li	a5,1
    80006586:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000658a:	0001f517          	auipc	a0,0x1f
    8000658e:	a8e50513          	addi	a0,a0,-1394 # 80025018 <disk+0x2018>
    80006592:	ffffc097          	auipc	ra,0xffffc
    80006596:	3f6080e7          	jalr	1014(ra) # 80002988 <wakeup>
}
    8000659a:	60a2                	ld	ra,8(sp)
    8000659c:	6402                	ld	s0,0(sp)
    8000659e:	0141                	addi	sp,sp,16
    800065a0:	8082                	ret
    panic("free_desc 1");
    800065a2:	00002517          	auipc	a0,0x2
    800065a6:	20650513          	addi	a0,a0,518 # 800087a8 <syscalls+0x330>
    800065aa:	ffffa097          	auipc	ra,0xffffa
    800065ae:	f94080e7          	jalr	-108(ra) # 8000053e <panic>
    panic("free_desc 2");
    800065b2:	00002517          	auipc	a0,0x2
    800065b6:	20650513          	addi	a0,a0,518 # 800087b8 <syscalls+0x340>
    800065ba:	ffffa097          	auipc	ra,0xffffa
    800065be:	f84080e7          	jalr	-124(ra) # 8000053e <panic>

00000000800065c2 <virtio_disk_init>:
{
    800065c2:	1101                	addi	sp,sp,-32
    800065c4:	ec06                	sd	ra,24(sp)
    800065c6:	e822                	sd	s0,16(sp)
    800065c8:	e426                	sd	s1,8(sp)
    800065ca:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800065cc:	00002597          	auipc	a1,0x2
    800065d0:	1fc58593          	addi	a1,a1,508 # 800087c8 <syscalls+0x350>
    800065d4:	0001f517          	auipc	a0,0x1f
    800065d8:	b5450513          	addi	a0,a0,-1196 # 80025128 <disk+0x2128>
    800065dc:	ffffa097          	auipc	ra,0xffffa
    800065e0:	578080e7          	jalr	1400(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065e4:	100017b7          	lui	a5,0x10001
    800065e8:	4398                	lw	a4,0(a5)
    800065ea:	2701                	sext.w	a4,a4
    800065ec:	747277b7          	lui	a5,0x74727
    800065f0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800065f4:	0ef71163          	bne	a4,a5,800066d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800065f8:	100017b7          	lui	a5,0x10001
    800065fc:	43dc                	lw	a5,4(a5)
    800065fe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006600:	4705                	li	a4,1
    80006602:	0ce79a63          	bne	a5,a4,800066d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006606:	100017b7          	lui	a5,0x10001
    8000660a:	479c                	lw	a5,8(a5)
    8000660c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000660e:	4709                	li	a4,2
    80006610:	0ce79363          	bne	a5,a4,800066d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006614:	100017b7          	lui	a5,0x10001
    80006618:	47d8                	lw	a4,12(a5)
    8000661a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000661c:	554d47b7          	lui	a5,0x554d4
    80006620:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006624:	0af71963          	bne	a4,a5,800066d6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006628:	100017b7          	lui	a5,0x10001
    8000662c:	4705                	li	a4,1
    8000662e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006630:	470d                	li	a4,3
    80006632:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006634:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006636:	c7ffe737          	lui	a4,0xc7ffe
    8000663a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000663e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006640:	2701                	sext.w	a4,a4
    80006642:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006644:	472d                	li	a4,11
    80006646:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006648:	473d                	li	a4,15
    8000664a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000664c:	6705                	lui	a4,0x1
    8000664e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006650:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006654:	5bdc                	lw	a5,52(a5)
    80006656:	2781                	sext.w	a5,a5
  if(max == 0)
    80006658:	c7d9                	beqz	a5,800066e6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000665a:	471d                	li	a4,7
    8000665c:	08f77d63          	bgeu	a4,a5,800066f6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006660:	100014b7          	lui	s1,0x10001
    80006664:	47a1                	li	a5,8
    80006666:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006668:	6609                	lui	a2,0x2
    8000666a:	4581                	li	a1,0
    8000666c:	0001d517          	auipc	a0,0x1d
    80006670:	99450513          	addi	a0,a0,-1644 # 80023000 <disk>
    80006674:	ffffa097          	auipc	ra,0xffffa
    80006678:	69e080e7          	jalr	1694(ra) # 80000d12 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000667c:	0001d717          	auipc	a4,0x1d
    80006680:	98470713          	addi	a4,a4,-1660 # 80023000 <disk>
    80006684:	00c75793          	srli	a5,a4,0xc
    80006688:	2781                	sext.w	a5,a5
    8000668a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000668c:	0001f797          	auipc	a5,0x1f
    80006690:	97478793          	addi	a5,a5,-1676 # 80025000 <disk+0x2000>
    80006694:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006696:	0001d717          	auipc	a4,0x1d
    8000669a:	9ea70713          	addi	a4,a4,-1558 # 80023080 <disk+0x80>
    8000669e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800066a0:	0001e717          	auipc	a4,0x1e
    800066a4:	96070713          	addi	a4,a4,-1696 # 80024000 <disk+0x1000>
    800066a8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800066aa:	4705                	li	a4,1
    800066ac:	00e78c23          	sb	a4,24(a5)
    800066b0:	00e78ca3          	sb	a4,25(a5)
    800066b4:	00e78d23          	sb	a4,26(a5)
    800066b8:	00e78da3          	sb	a4,27(a5)
    800066bc:	00e78e23          	sb	a4,28(a5)
    800066c0:	00e78ea3          	sb	a4,29(a5)
    800066c4:	00e78f23          	sb	a4,30(a5)
    800066c8:	00e78fa3          	sb	a4,31(a5)
}
    800066cc:	60e2                	ld	ra,24(sp)
    800066ce:	6442                	ld	s0,16(sp)
    800066d0:	64a2                	ld	s1,8(sp)
    800066d2:	6105                	addi	sp,sp,32
    800066d4:	8082                	ret
    panic("could not find virtio disk");
    800066d6:	00002517          	auipc	a0,0x2
    800066da:	10250513          	addi	a0,a0,258 # 800087d8 <syscalls+0x360>
    800066de:	ffffa097          	auipc	ra,0xffffa
    800066e2:	e60080e7          	jalr	-416(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800066e6:	00002517          	auipc	a0,0x2
    800066ea:	11250513          	addi	a0,a0,274 # 800087f8 <syscalls+0x380>
    800066ee:	ffffa097          	auipc	ra,0xffffa
    800066f2:	e50080e7          	jalr	-432(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800066f6:	00002517          	auipc	a0,0x2
    800066fa:	12250513          	addi	a0,a0,290 # 80008818 <syscalls+0x3a0>
    800066fe:	ffffa097          	auipc	ra,0xffffa
    80006702:	e40080e7          	jalr	-448(ra) # 8000053e <panic>

0000000080006706 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006706:	7159                	addi	sp,sp,-112
    80006708:	f486                	sd	ra,104(sp)
    8000670a:	f0a2                	sd	s0,96(sp)
    8000670c:	eca6                	sd	s1,88(sp)
    8000670e:	e8ca                	sd	s2,80(sp)
    80006710:	e4ce                	sd	s3,72(sp)
    80006712:	e0d2                	sd	s4,64(sp)
    80006714:	fc56                	sd	s5,56(sp)
    80006716:	f85a                	sd	s6,48(sp)
    80006718:	f45e                	sd	s7,40(sp)
    8000671a:	f062                	sd	s8,32(sp)
    8000671c:	ec66                	sd	s9,24(sp)
    8000671e:	e86a                	sd	s10,16(sp)
    80006720:	1880                	addi	s0,sp,112
    80006722:	892a                	mv	s2,a0
    80006724:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006726:	00c52c83          	lw	s9,12(a0)
    8000672a:	001c9c9b          	slliw	s9,s9,0x1
    8000672e:	1c82                	slli	s9,s9,0x20
    80006730:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006734:	0001f517          	auipc	a0,0x1f
    80006738:	9f450513          	addi	a0,a0,-1548 # 80025128 <disk+0x2128>
    8000673c:	ffffa097          	auipc	ra,0xffffa
    80006740:	4b0080e7          	jalr	1200(ra) # 80000bec <acquire>
  for(int i = 0; i < 3; i++){
    80006744:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006746:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006748:	0001db97          	auipc	s7,0x1d
    8000674c:	8b8b8b93          	addi	s7,s7,-1864 # 80023000 <disk>
    80006750:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006752:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006754:	8a4e                	mv	s4,s3
    80006756:	a051                	j	800067da <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006758:	00fb86b3          	add	a3,s7,a5
    8000675c:	96da                	add	a3,a3,s6
    8000675e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006762:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006764:	0207c563          	bltz	a5,8000678e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006768:	2485                	addiw	s1,s1,1
    8000676a:	0711                	addi	a4,a4,4
    8000676c:	25548063          	beq	s1,s5,800069ac <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006770:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006772:	0001f697          	auipc	a3,0x1f
    80006776:	8a668693          	addi	a3,a3,-1882 # 80025018 <disk+0x2018>
    8000677a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000677c:	0006c583          	lbu	a1,0(a3)
    80006780:	fde1                	bnez	a1,80006758 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006782:	2785                	addiw	a5,a5,1
    80006784:	0685                	addi	a3,a3,1
    80006786:	ff879be3          	bne	a5,s8,8000677c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000678a:	57fd                	li	a5,-1
    8000678c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000678e:	02905a63          	blez	s1,800067c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006792:	f9042503          	lw	a0,-112(s0)
    80006796:	00000097          	auipc	ra,0x0
    8000679a:	d90080e7          	jalr	-624(ra) # 80006526 <free_desc>
      for(int j = 0; j < i; j++)
    8000679e:	4785                	li	a5,1
    800067a0:	0297d163          	bge	a5,s1,800067c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800067a4:	f9442503          	lw	a0,-108(s0)
    800067a8:	00000097          	auipc	ra,0x0
    800067ac:	d7e080e7          	jalr	-642(ra) # 80006526 <free_desc>
      for(int j = 0; j < i; j++)
    800067b0:	4789                	li	a5,2
    800067b2:	0097d863          	bge	a5,s1,800067c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800067b6:	f9842503          	lw	a0,-104(s0)
    800067ba:	00000097          	auipc	ra,0x0
    800067be:	d6c080e7          	jalr	-660(ra) # 80006526 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800067c2:	0001f597          	auipc	a1,0x1f
    800067c6:	96658593          	addi	a1,a1,-1690 # 80025128 <disk+0x2128>
    800067ca:	0001f517          	auipc	a0,0x1f
    800067ce:	84e50513          	addi	a0,a0,-1970 # 80025018 <disk+0x2018>
    800067d2:	ffffc097          	auipc	ra,0xffffc
    800067d6:	f38080e7          	jalr	-200(ra) # 8000270a <sleep>
  for(int i = 0; i < 3; i++){
    800067da:	f9040713          	addi	a4,s0,-112
    800067de:	84ce                	mv	s1,s3
    800067e0:	bf41                	j	80006770 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800067e2:	20058713          	addi	a4,a1,512
    800067e6:	00471693          	slli	a3,a4,0x4
    800067ea:	0001d717          	auipc	a4,0x1d
    800067ee:	81670713          	addi	a4,a4,-2026 # 80023000 <disk>
    800067f2:	9736                	add	a4,a4,a3
    800067f4:	4685                	li	a3,1
    800067f6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800067fa:	20058713          	addi	a4,a1,512
    800067fe:	00471693          	slli	a3,a4,0x4
    80006802:	0001c717          	auipc	a4,0x1c
    80006806:	7fe70713          	addi	a4,a4,2046 # 80023000 <disk>
    8000680a:	9736                	add	a4,a4,a3
    8000680c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006810:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006814:	7679                	lui	a2,0xffffe
    80006816:	963e                	add	a2,a2,a5
    80006818:	0001e697          	auipc	a3,0x1e
    8000681c:	7e868693          	addi	a3,a3,2024 # 80025000 <disk+0x2000>
    80006820:	6298                	ld	a4,0(a3)
    80006822:	9732                	add	a4,a4,a2
    80006824:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006826:	6298                	ld	a4,0(a3)
    80006828:	9732                	add	a4,a4,a2
    8000682a:	4541                	li	a0,16
    8000682c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000682e:	6298                	ld	a4,0(a3)
    80006830:	9732                	add	a4,a4,a2
    80006832:	4505                	li	a0,1
    80006834:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006838:	f9442703          	lw	a4,-108(s0)
    8000683c:	6288                	ld	a0,0(a3)
    8000683e:	962a                	add	a2,a2,a0
    80006840:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006844:	0712                	slli	a4,a4,0x4
    80006846:	6290                	ld	a2,0(a3)
    80006848:	963a                	add	a2,a2,a4
    8000684a:	05890513          	addi	a0,s2,88
    8000684e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006850:	6294                	ld	a3,0(a3)
    80006852:	96ba                	add	a3,a3,a4
    80006854:	40000613          	li	a2,1024
    80006858:	c690                	sw	a2,8(a3)
  if(write)
    8000685a:	140d0063          	beqz	s10,8000699a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000685e:	0001e697          	auipc	a3,0x1e
    80006862:	7a26b683          	ld	a3,1954(a3) # 80025000 <disk+0x2000>
    80006866:	96ba                	add	a3,a3,a4
    80006868:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000686c:	0001c817          	auipc	a6,0x1c
    80006870:	79480813          	addi	a6,a6,1940 # 80023000 <disk>
    80006874:	0001e517          	auipc	a0,0x1e
    80006878:	78c50513          	addi	a0,a0,1932 # 80025000 <disk+0x2000>
    8000687c:	6114                	ld	a3,0(a0)
    8000687e:	96ba                	add	a3,a3,a4
    80006880:	00c6d603          	lhu	a2,12(a3)
    80006884:	00166613          	ori	a2,a2,1
    80006888:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000688c:	f9842683          	lw	a3,-104(s0)
    80006890:	6110                	ld	a2,0(a0)
    80006892:	9732                	add	a4,a4,a2
    80006894:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006898:	20058613          	addi	a2,a1,512
    8000689c:	0612                	slli	a2,a2,0x4
    8000689e:	9642                	add	a2,a2,a6
    800068a0:	577d                	li	a4,-1
    800068a2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800068a6:	00469713          	slli	a4,a3,0x4
    800068aa:	6114                	ld	a3,0(a0)
    800068ac:	96ba                	add	a3,a3,a4
    800068ae:	03078793          	addi	a5,a5,48
    800068b2:	97c2                	add	a5,a5,a6
    800068b4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800068b6:	611c                	ld	a5,0(a0)
    800068b8:	97ba                	add	a5,a5,a4
    800068ba:	4685                	li	a3,1
    800068bc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800068be:	611c                	ld	a5,0(a0)
    800068c0:	97ba                	add	a5,a5,a4
    800068c2:	4809                	li	a6,2
    800068c4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800068c8:	611c                	ld	a5,0(a0)
    800068ca:	973e                	add	a4,a4,a5
    800068cc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800068d0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800068d4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800068d8:	6518                	ld	a4,8(a0)
    800068da:	00275783          	lhu	a5,2(a4)
    800068de:	8b9d                	andi	a5,a5,7
    800068e0:	0786                	slli	a5,a5,0x1
    800068e2:	97ba                	add	a5,a5,a4
    800068e4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800068e8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800068ec:	6518                	ld	a4,8(a0)
    800068ee:	00275783          	lhu	a5,2(a4)
    800068f2:	2785                	addiw	a5,a5,1
    800068f4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800068f8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800068fc:	100017b7          	lui	a5,0x10001
    80006900:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006904:	00492703          	lw	a4,4(s2)
    80006908:	4785                	li	a5,1
    8000690a:	02f71163          	bne	a4,a5,8000692c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000690e:	0001f997          	auipc	s3,0x1f
    80006912:	81a98993          	addi	s3,s3,-2022 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006916:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006918:	85ce                	mv	a1,s3
    8000691a:	854a                	mv	a0,s2
    8000691c:	ffffc097          	auipc	ra,0xffffc
    80006920:	dee080e7          	jalr	-530(ra) # 8000270a <sleep>
  while(b->disk == 1) {
    80006924:	00492783          	lw	a5,4(s2)
    80006928:	fe9788e3          	beq	a5,s1,80006918 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000692c:	f9042903          	lw	s2,-112(s0)
    80006930:	20090793          	addi	a5,s2,512
    80006934:	00479713          	slli	a4,a5,0x4
    80006938:	0001c797          	auipc	a5,0x1c
    8000693c:	6c878793          	addi	a5,a5,1736 # 80023000 <disk>
    80006940:	97ba                	add	a5,a5,a4
    80006942:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006946:	0001e997          	auipc	s3,0x1e
    8000694a:	6ba98993          	addi	s3,s3,1722 # 80025000 <disk+0x2000>
    8000694e:	00491713          	slli	a4,s2,0x4
    80006952:	0009b783          	ld	a5,0(s3)
    80006956:	97ba                	add	a5,a5,a4
    80006958:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000695c:	854a                	mv	a0,s2
    8000695e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006962:	00000097          	auipc	ra,0x0
    80006966:	bc4080e7          	jalr	-1084(ra) # 80006526 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000696a:	8885                	andi	s1,s1,1
    8000696c:	f0ed                	bnez	s1,8000694e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000696e:	0001e517          	auipc	a0,0x1e
    80006972:	7ba50513          	addi	a0,a0,1978 # 80025128 <disk+0x2128>
    80006976:	ffffa097          	auipc	ra,0xffffa
    8000697a:	342080e7          	jalr	834(ra) # 80000cb8 <release>
}
    8000697e:	70a6                	ld	ra,104(sp)
    80006980:	7406                	ld	s0,96(sp)
    80006982:	64e6                	ld	s1,88(sp)
    80006984:	6946                	ld	s2,80(sp)
    80006986:	69a6                	ld	s3,72(sp)
    80006988:	6a06                	ld	s4,64(sp)
    8000698a:	7ae2                	ld	s5,56(sp)
    8000698c:	7b42                	ld	s6,48(sp)
    8000698e:	7ba2                	ld	s7,40(sp)
    80006990:	7c02                	ld	s8,32(sp)
    80006992:	6ce2                	ld	s9,24(sp)
    80006994:	6d42                	ld	s10,16(sp)
    80006996:	6165                	addi	sp,sp,112
    80006998:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000699a:	0001e697          	auipc	a3,0x1e
    8000699e:	6666b683          	ld	a3,1638(a3) # 80025000 <disk+0x2000>
    800069a2:	96ba                	add	a3,a3,a4
    800069a4:	4609                	li	a2,2
    800069a6:	00c69623          	sh	a2,12(a3)
    800069aa:	b5c9                	j	8000686c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800069ac:	f9042583          	lw	a1,-112(s0)
    800069b0:	20058793          	addi	a5,a1,512
    800069b4:	0792                	slli	a5,a5,0x4
    800069b6:	0001c517          	auipc	a0,0x1c
    800069ba:	6f250513          	addi	a0,a0,1778 # 800230a8 <disk+0xa8>
    800069be:	953e                	add	a0,a0,a5
  if(write)
    800069c0:	e20d11e3          	bnez	s10,800067e2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800069c4:	20058713          	addi	a4,a1,512
    800069c8:	00471693          	slli	a3,a4,0x4
    800069cc:	0001c717          	auipc	a4,0x1c
    800069d0:	63470713          	addi	a4,a4,1588 # 80023000 <disk>
    800069d4:	9736                	add	a4,a4,a3
    800069d6:	0a072423          	sw	zero,168(a4)
    800069da:	b505                	j	800067fa <virtio_disk_rw+0xf4>

00000000800069dc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800069dc:	1101                	addi	sp,sp,-32
    800069de:	ec06                	sd	ra,24(sp)
    800069e0:	e822                	sd	s0,16(sp)
    800069e2:	e426                	sd	s1,8(sp)
    800069e4:	e04a                	sd	s2,0(sp)
    800069e6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800069e8:	0001e517          	auipc	a0,0x1e
    800069ec:	74050513          	addi	a0,a0,1856 # 80025128 <disk+0x2128>
    800069f0:	ffffa097          	auipc	ra,0xffffa
    800069f4:	1fc080e7          	jalr	508(ra) # 80000bec <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800069f8:	10001737          	lui	a4,0x10001
    800069fc:	533c                	lw	a5,96(a4)
    800069fe:	8b8d                	andi	a5,a5,3
    80006a00:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006a02:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006a06:	0001e797          	auipc	a5,0x1e
    80006a0a:	5fa78793          	addi	a5,a5,1530 # 80025000 <disk+0x2000>
    80006a0e:	6b94                	ld	a3,16(a5)
    80006a10:	0207d703          	lhu	a4,32(a5)
    80006a14:	0026d783          	lhu	a5,2(a3)
    80006a18:	06f70163          	beq	a4,a5,80006a7a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006a1c:	0001c917          	auipc	s2,0x1c
    80006a20:	5e490913          	addi	s2,s2,1508 # 80023000 <disk>
    80006a24:	0001e497          	auipc	s1,0x1e
    80006a28:	5dc48493          	addi	s1,s1,1500 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006a2c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006a30:	6898                	ld	a4,16(s1)
    80006a32:	0204d783          	lhu	a5,32(s1)
    80006a36:	8b9d                	andi	a5,a5,7
    80006a38:	078e                	slli	a5,a5,0x3
    80006a3a:	97ba                	add	a5,a5,a4
    80006a3c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006a3e:	20078713          	addi	a4,a5,512
    80006a42:	0712                	slli	a4,a4,0x4
    80006a44:	974a                	add	a4,a4,s2
    80006a46:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006a4a:	e731                	bnez	a4,80006a96 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006a4c:	20078793          	addi	a5,a5,512
    80006a50:	0792                	slli	a5,a5,0x4
    80006a52:	97ca                	add	a5,a5,s2
    80006a54:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006a56:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006a5a:	ffffc097          	auipc	ra,0xffffc
    80006a5e:	f2e080e7          	jalr	-210(ra) # 80002988 <wakeup>

    disk.used_idx += 1;
    80006a62:	0204d783          	lhu	a5,32(s1)
    80006a66:	2785                	addiw	a5,a5,1
    80006a68:	17c2                	slli	a5,a5,0x30
    80006a6a:	93c1                	srli	a5,a5,0x30
    80006a6c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006a70:	6898                	ld	a4,16(s1)
    80006a72:	00275703          	lhu	a4,2(a4)
    80006a76:	faf71be3          	bne	a4,a5,80006a2c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006a7a:	0001e517          	auipc	a0,0x1e
    80006a7e:	6ae50513          	addi	a0,a0,1710 # 80025128 <disk+0x2128>
    80006a82:	ffffa097          	auipc	ra,0xffffa
    80006a86:	236080e7          	jalr	566(ra) # 80000cb8 <release>
}
    80006a8a:	60e2                	ld	ra,24(sp)
    80006a8c:	6442                	ld	s0,16(sp)
    80006a8e:	64a2                	ld	s1,8(sp)
    80006a90:	6902                	ld	s2,0(sp)
    80006a92:	6105                	addi	sp,sp,32
    80006a94:	8082                	ret
      panic("virtio_disk_intr status");
    80006a96:	00002517          	auipc	a0,0x2
    80006a9a:	da250513          	addi	a0,a0,-606 # 80008838 <syscalls+0x3c0>
    80006a9e:	ffffa097          	auipc	ra,0xffffa
    80006aa2:	aa0080e7          	jalr	-1376(ra) # 8000053e <panic>

0000000080006aa6 <cas>:
    80006aa6:	100522af          	lr.w	t0,(a0)
    80006aaa:	00b29563          	bne	t0,a1,80006ab4 <fail>
    80006aae:	18c5252f          	sc.w	a0,a2,(a0)
    80006ab2:	8082                	ret

0000000080006ab4 <fail>:
    80006ab4:	4505                	li	a0,1
    80006ab6:	8082                	ret
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
