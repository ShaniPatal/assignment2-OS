
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8e013103          	ld	sp,-1824(sp) # 800088e0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	20c78793          	addi	a5,a5,524 # 80006270 <timervec>
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
    800000b2:	df278793          	addi	a5,a5,-526 # 80000ea0 <main>
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
    80000130:	9ce080e7          	jalr	-1586(ra) # 80002afa <either_copyin>
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
    800001c8:	b7e080e7          	jalr	-1154(ra) # 80001d42 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	356080e7          	jalr	854(ra) # 8000252a <sleep>
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
    80000214:	894080e7          	jalr	-1900(ra) # 80002aa4 <either_copyout>
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
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
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
    800002f2:	00003097          	auipc	ra,0x3
    800002f6:	85e080e7          	jalr	-1954(ra) # 80002b50 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
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
    8000044a:	28a080e7          	jalr	650(ra) # 800026d0 <wakeup>
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
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
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
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
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
    800008a4:	e30080e7          	jalr	-464(ra) # 800026d0 <wakeup>
    
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
    80000930:	bfe080e7          	jalr	-1026(ra) # 8000252a <sleep>
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
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
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
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
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
    80000a28:	2ce080e7          	jalr	718(ra) # 80000cf2 <memset>

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
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
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
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1c4080e7          	jalr	452(ra) # 80000cf2 <memset>
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
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
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
    80000b82:	1a0080e7          	jalr	416(ra) # 80001d1e <mycpu>
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
    80000bb4:	16e080e7          	jalr	366(ra) # 80001d1e <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	162080e7          	jalr	354(ra) # 80001d1e <mycpu>
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
    80000bd8:	14a080e7          	jalr	330(ra) # 80001d1e <mycpu>
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
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
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
    80000c18:	10a080e7          	jalr	266(ra) # 80001d1e <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	0de080e7          	jalr	222(ra) # 80001d1e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk)){
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    printf("%s \n", lk->name);
    80000cd0:	648c                	ld	a1,8(s1)
    80000cd2:	00007517          	auipc	a0,0x7
    80000cd6:	3c650513          	addi	a0,a0,966 # 80008098 <digits+0x58>
    80000cda:	00000097          	auipc	ra,0x0
    80000cde:	8ae080e7          	jalr	-1874(ra) # 80000588 <printf>
    panic("release");
    80000ce2:	00007517          	auipc	a0,0x7
    80000ce6:	3be50513          	addi	a0,a0,958 # 800080a0 <digits+0x60>
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	854080e7          	jalr	-1964(ra) # 8000053e <panic>

0000000080000cf2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cf2:	1141                	addi	sp,sp,-16
    80000cf4:	e422                	sd	s0,8(sp)
    80000cf6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cf8:	ce09                	beqz	a2,80000d12 <memset+0x20>
    80000cfa:	87aa                	mv	a5,a0
    80000cfc:	fff6071b          	addiw	a4,a2,-1
    80000d00:	1702                	slli	a4,a4,0x20
    80000d02:	9301                	srli	a4,a4,0x20
    80000d04:	0705                	addi	a4,a4,1
    80000d06:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d08:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d0c:	0785                	addi	a5,a5,1
    80000d0e:	fee79de3          	bne	a5,a4,80000d08 <memset+0x16>
  }
  return dst;
}
    80000d12:	6422                	ld	s0,8(sp)
    80000d14:	0141                	addi	sp,sp,16
    80000d16:	8082                	ret

0000000080000d18 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d18:	1141                	addi	sp,sp,-16
    80000d1a:	e422                	sd	s0,8(sp)
    80000d1c:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d1e:	ca05                	beqz	a2,80000d4e <memcmp+0x36>
    80000d20:	fff6069b          	addiw	a3,a2,-1
    80000d24:	1682                	slli	a3,a3,0x20
    80000d26:	9281                	srli	a3,a3,0x20
    80000d28:	0685                	addi	a3,a3,1
    80000d2a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d2c:	00054783          	lbu	a5,0(a0)
    80000d30:	0005c703          	lbu	a4,0(a1)
    80000d34:	00e79863          	bne	a5,a4,80000d44 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d38:	0505                	addi	a0,a0,1
    80000d3a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d3c:	fed518e3          	bne	a0,a3,80000d2c <memcmp+0x14>
  }

  return 0;
    80000d40:	4501                	li	a0,0
    80000d42:	a019                	j	80000d48 <memcmp+0x30>
      return *s1 - *s2;
    80000d44:	40e7853b          	subw	a0,a5,a4
}
    80000d48:	6422                	ld	s0,8(sp)
    80000d4a:	0141                	addi	sp,sp,16
    80000d4c:	8082                	ret
  return 0;
    80000d4e:	4501                	li	a0,0
    80000d50:	bfe5                	j	80000d48 <memcmp+0x30>

0000000080000d52 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d52:	1141                	addi	sp,sp,-16
    80000d54:	e422                	sd	s0,8(sp)
    80000d56:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d58:	ca0d                	beqz	a2,80000d8a <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d5a:	00a5f963          	bgeu	a1,a0,80000d6c <memmove+0x1a>
    80000d5e:	02061693          	slli	a3,a2,0x20
    80000d62:	9281                	srli	a3,a3,0x20
    80000d64:	00d58733          	add	a4,a1,a3
    80000d68:	02e56463          	bltu	a0,a4,80000d90 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d6c:	fff6079b          	addiw	a5,a2,-1
    80000d70:	1782                	slli	a5,a5,0x20
    80000d72:	9381                	srli	a5,a5,0x20
    80000d74:	0785                	addi	a5,a5,1
    80000d76:	97ae                	add	a5,a5,a1
    80000d78:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d7a:	0585                	addi	a1,a1,1
    80000d7c:	0705                	addi	a4,a4,1
    80000d7e:	fff5c683          	lbu	a3,-1(a1)
    80000d82:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d86:	fef59ae3          	bne	a1,a5,80000d7a <memmove+0x28>

  return dst;
}
    80000d8a:	6422                	ld	s0,8(sp)
    80000d8c:	0141                	addi	sp,sp,16
    80000d8e:	8082                	ret
    d += n;
    80000d90:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d92:	fff6079b          	addiw	a5,a2,-1
    80000d96:	1782                	slli	a5,a5,0x20
    80000d98:	9381                	srli	a5,a5,0x20
    80000d9a:	fff7c793          	not	a5,a5
    80000d9e:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000da0:	177d                	addi	a4,a4,-1
    80000da2:	16fd                	addi	a3,a3,-1
    80000da4:	00074603          	lbu	a2,0(a4)
    80000da8:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000dac:	fef71ae3          	bne	a4,a5,80000da0 <memmove+0x4e>
    80000db0:	bfe9                	j	80000d8a <memmove+0x38>

0000000080000db2 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000db2:	1141                	addi	sp,sp,-16
    80000db4:	e406                	sd	ra,8(sp)
    80000db6:	e022                	sd	s0,0(sp)
    80000db8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dba:	00000097          	auipc	ra,0x0
    80000dbe:	f98080e7          	jalr	-104(ra) # 80000d52 <memmove>
}
    80000dc2:	60a2                	ld	ra,8(sp)
    80000dc4:	6402                	ld	s0,0(sp)
    80000dc6:	0141                	addi	sp,sp,16
    80000dc8:	8082                	ret

0000000080000dca <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dca:	1141                	addi	sp,sp,-16
    80000dcc:	e422                	sd	s0,8(sp)
    80000dce:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dd0:	ce11                	beqz	a2,80000dec <strncmp+0x22>
    80000dd2:	00054783          	lbu	a5,0(a0)
    80000dd6:	cf89                	beqz	a5,80000df0 <strncmp+0x26>
    80000dd8:	0005c703          	lbu	a4,0(a1)
    80000ddc:	00f71a63          	bne	a4,a5,80000df0 <strncmp+0x26>
    n--, p++, q++;
    80000de0:	367d                	addiw	a2,a2,-1
    80000de2:	0505                	addi	a0,a0,1
    80000de4:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000de6:	f675                	bnez	a2,80000dd2 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000de8:	4501                	li	a0,0
    80000dea:	a809                	j	80000dfc <strncmp+0x32>
    80000dec:	4501                	li	a0,0
    80000dee:	a039                	j	80000dfc <strncmp+0x32>
  if(n == 0)
    80000df0:	ca09                	beqz	a2,80000e02 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000df2:	00054503          	lbu	a0,0(a0)
    80000df6:	0005c783          	lbu	a5,0(a1)
    80000dfa:	9d1d                	subw	a0,a0,a5
}
    80000dfc:	6422                	ld	s0,8(sp)
    80000dfe:	0141                	addi	sp,sp,16
    80000e00:	8082                	ret
    return 0;
    80000e02:	4501                	li	a0,0
    80000e04:	bfe5                	j	80000dfc <strncmp+0x32>

0000000080000e06 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e06:	1141                	addi	sp,sp,-16
    80000e08:	e422                	sd	s0,8(sp)
    80000e0a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e0c:	872a                	mv	a4,a0
    80000e0e:	8832                	mv	a6,a2
    80000e10:	367d                	addiw	a2,a2,-1
    80000e12:	01005963          	blez	a6,80000e24 <strncpy+0x1e>
    80000e16:	0705                	addi	a4,a4,1
    80000e18:	0005c783          	lbu	a5,0(a1)
    80000e1c:	fef70fa3          	sb	a5,-1(a4)
    80000e20:	0585                	addi	a1,a1,1
    80000e22:	f7f5                	bnez	a5,80000e0e <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e24:	00c05d63          	blez	a2,80000e3e <strncpy+0x38>
    80000e28:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e2a:	0685                	addi	a3,a3,1
    80000e2c:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e30:	fff6c793          	not	a5,a3
    80000e34:	9fb9                	addw	a5,a5,a4
    80000e36:	010787bb          	addw	a5,a5,a6
    80000e3a:	fef048e3          	bgtz	a5,80000e2a <strncpy+0x24>
  return os;
}
    80000e3e:	6422                	ld	s0,8(sp)
    80000e40:	0141                	addi	sp,sp,16
    80000e42:	8082                	ret

0000000080000e44 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e44:	1141                	addi	sp,sp,-16
    80000e46:	e422                	sd	s0,8(sp)
    80000e48:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e4a:	02c05363          	blez	a2,80000e70 <safestrcpy+0x2c>
    80000e4e:	fff6069b          	addiw	a3,a2,-1
    80000e52:	1682                	slli	a3,a3,0x20
    80000e54:	9281                	srli	a3,a3,0x20
    80000e56:	96ae                	add	a3,a3,a1
    80000e58:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e5a:	00d58963          	beq	a1,a3,80000e6c <safestrcpy+0x28>
    80000e5e:	0585                	addi	a1,a1,1
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	fff5c703          	lbu	a4,-1(a1)
    80000e66:	fee78fa3          	sb	a4,-1(a5)
    80000e6a:	fb65                	bnez	a4,80000e5a <safestrcpy+0x16>
    ;
  *s = 0;
    80000e6c:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e70:	6422                	ld	s0,8(sp)
    80000e72:	0141                	addi	sp,sp,16
    80000e74:	8082                	ret

0000000080000e76 <strlen>:

int
strlen(const char *s)
{
    80000e76:	1141                	addi	sp,sp,-16
    80000e78:	e422                	sd	s0,8(sp)
    80000e7a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e7c:	00054783          	lbu	a5,0(a0)
    80000e80:	cf91                	beqz	a5,80000e9c <strlen+0x26>
    80000e82:	0505                	addi	a0,a0,1
    80000e84:	87aa                	mv	a5,a0
    80000e86:	4685                	li	a3,1
    80000e88:	9e89                	subw	a3,a3,a0
    80000e8a:	00f6853b          	addw	a0,a3,a5
    80000e8e:	0785                	addi	a5,a5,1
    80000e90:	fff7c703          	lbu	a4,-1(a5)
    80000e94:	fb7d                	bnez	a4,80000e8a <strlen+0x14>
    ;
  return n;
}
    80000e96:	6422                	ld	s0,8(sp)
    80000e98:	0141                	addi	sp,sp,16
    80000e9a:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e9c:	4501                	li	a0,0
    80000e9e:	bfe5                	j	80000e96 <strlen+0x20>

0000000080000ea0 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ea0:	1141                	addi	sp,sp,-16
    80000ea2:	e406                	sd	ra,8(sp)
    80000ea4:	e022                	sd	s0,0(sp)
    80000ea6:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ea8:	00001097          	auipc	ra,0x1
    80000eac:	e66080e7          	jalr	-410(ra) # 80001d0e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eb0:	00008717          	auipc	a4,0x8
    80000eb4:	16870713          	addi	a4,a4,360 # 80009018 <started>
  if(cpuid() == 0){
    80000eb8:	c139                	beqz	a0,80000efe <main+0x5e>
    while(started == 0)
    80000eba:	431c                	lw	a5,0(a4)
    80000ebc:	2781                	sext.w	a5,a5
    80000ebe:	dff5                	beqz	a5,80000eba <main+0x1a>
      ;
    __sync_synchronize();
    80000ec0:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ec4:	00001097          	auipc	ra,0x1
    80000ec8:	e4a080e7          	jalr	-438(ra) # 80001d0e <cpuid>
    80000ecc:	85aa                	mv	a1,a0
    80000ece:	00007517          	auipc	a0,0x7
    80000ed2:	1f250513          	addi	a0,a0,498 # 800080c0 <digits+0x80>
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	6b2080e7          	jalr	1714(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	0d8080e7          	jalr	216(ra) # 80000fb6 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ee6:	00002097          	auipc	ra,0x2
    80000eea:	e22080e7          	jalr	-478(ra) # 80002d08 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eee:	00005097          	auipc	ra,0x5
    80000ef2:	3c2080e7          	jalr	962(ra) # 800062b0 <plicinithart>
  }

  scheduler();        
    80000ef6:	00001097          	auipc	ra,0x1
    80000efa:	416080e7          	jalr	1046(ra) # 8000230c <scheduler>
    consoleinit();
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	552080e7          	jalr	1362(ra) # 80000450 <consoleinit>
    printfinit();
    80000f06:	00000097          	auipc	ra,0x0
    80000f0a:	868080e7          	jalr	-1944(ra) # 8000076e <printfinit>
    printf("\n");
    80000f0e:	00007517          	auipc	a0,0x7
    80000f12:	1c250513          	addi	a0,a0,450 # 800080d0 <digits+0x90>
    80000f16:	fffff097          	auipc	ra,0xfffff
    80000f1a:	672080e7          	jalr	1650(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f1e:	00007517          	auipc	a0,0x7
    80000f22:	18a50513          	addi	a0,a0,394 # 800080a8 <digits+0x68>
    80000f26:	fffff097          	auipc	ra,0xfffff
    80000f2a:	662080e7          	jalr	1634(ra) # 80000588 <printf>
    printf("\n");
    80000f2e:	00007517          	auipc	a0,0x7
    80000f32:	1a250513          	addi	a0,a0,418 # 800080d0 <digits+0x90>
    80000f36:	fffff097          	auipc	ra,0xfffff
    80000f3a:	652080e7          	jalr	1618(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f3e:	00000097          	auipc	ra,0x0
    80000f42:	b7a080e7          	jalr	-1158(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f46:	00000097          	auipc	ra,0x0
    80000f4a:	322080e7          	jalr	802(ra) # 80001268 <kvminit>
    kvminithart();   // turn on paging
    80000f4e:	00000097          	auipc	ra,0x0
    80000f52:	068080e7          	jalr	104(ra) # 80000fb6 <kvminithart>
    procinit();      // process table
    80000f56:	00001097          	auipc	ra,0x1
    80000f5a:	cb2080e7          	jalr	-846(ra) # 80001c08 <procinit>
    trapinit();      // trap vectors
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	d82080e7          	jalr	-638(ra) # 80002ce0 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f66:	00002097          	auipc	ra,0x2
    80000f6a:	da2080e7          	jalr	-606(ra) # 80002d08 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	32c080e7          	jalr	812(ra) # 8000629a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f76:	00005097          	auipc	ra,0x5
    80000f7a:	33a080e7          	jalr	826(ra) # 800062b0 <plicinithart>
    binit();         // buffer cache
    80000f7e:	00002097          	auipc	ra,0x2
    80000f82:	516080e7          	jalr	1302(ra) # 80003494 <binit>
    iinit();         // inode table
    80000f86:	00003097          	auipc	ra,0x3
    80000f8a:	ba6080e7          	jalr	-1114(ra) # 80003b2c <iinit>
    fileinit();      // file table
    80000f8e:	00004097          	auipc	ra,0x4
    80000f92:	b50080e7          	jalr	-1200(ra) # 80004ade <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f96:	00005097          	auipc	ra,0x5
    80000f9a:	43c080e7          	jalr	1084(ra) # 800063d2 <virtio_disk_init>
    userinit();      // first user process
    80000f9e:	00001097          	auipc	ra,0x1
    80000fa2:	0f0080e7          	jalr	240(ra) # 8000208e <userinit>
    __sync_synchronize();
    80000fa6:	0ff0000f          	fence
    started = 1;
    80000faa:	4785                	li	a5,1
    80000fac:	00008717          	auipc	a4,0x8
    80000fb0:	06f72623          	sw	a5,108(a4) # 80009018 <started>
    80000fb4:	b789                	j	80000ef6 <main+0x56>

0000000080000fb6 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fb6:	1141                	addi	sp,sp,-16
    80000fb8:	e422                	sd	s0,8(sp)
    80000fba:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fbc:	00008797          	auipc	a5,0x8
    80000fc0:	0647b783          	ld	a5,100(a5) # 80009020 <kernel_pagetable>
    80000fc4:	83b1                	srli	a5,a5,0xc
    80000fc6:	577d                	li	a4,-1
    80000fc8:	177e                	slli	a4,a4,0x3f
    80000fca:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fcc:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fd0:	12000073          	sfence.vma
  sfence_vma();
}
    80000fd4:	6422                	ld	s0,8(sp)
    80000fd6:	0141                	addi	sp,sp,16
    80000fd8:	8082                	ret

0000000080000fda <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fda:	7139                	addi	sp,sp,-64
    80000fdc:	fc06                	sd	ra,56(sp)
    80000fde:	f822                	sd	s0,48(sp)
    80000fe0:	f426                	sd	s1,40(sp)
    80000fe2:	f04a                	sd	s2,32(sp)
    80000fe4:	ec4e                	sd	s3,24(sp)
    80000fe6:	e852                	sd	s4,16(sp)
    80000fe8:	e456                	sd	s5,8(sp)
    80000fea:	e05a                	sd	s6,0(sp)
    80000fec:	0080                	addi	s0,sp,64
    80000fee:	84aa                	mv	s1,a0
    80000ff0:	89ae                	mv	s3,a1
    80000ff2:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000ff4:	57fd                	li	a5,-1
    80000ff6:	83e9                	srli	a5,a5,0x1a
    80000ff8:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ffa:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ffc:	04b7f263          	bgeu	a5,a1,80001040 <walk+0x66>
    panic("walk");
    80001000:	00007517          	auipc	a0,0x7
    80001004:	0d850513          	addi	a0,a0,216 # 800080d8 <digits+0x98>
    80001008:	fffff097          	auipc	ra,0xfffff
    8000100c:	536080e7          	jalr	1334(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001010:	060a8663          	beqz	s5,8000107c <walk+0xa2>
    80001014:	00000097          	auipc	ra,0x0
    80001018:	ae0080e7          	jalr	-1312(ra) # 80000af4 <kalloc>
    8000101c:	84aa                	mv	s1,a0
    8000101e:	c529                	beqz	a0,80001068 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001020:	6605                	lui	a2,0x1
    80001022:	4581                	li	a1,0
    80001024:	00000097          	auipc	ra,0x0
    80001028:	cce080e7          	jalr	-818(ra) # 80000cf2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000102c:	00c4d793          	srli	a5,s1,0xc
    80001030:	07aa                	slli	a5,a5,0xa
    80001032:	0017e793          	ori	a5,a5,1
    80001036:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000103a:	3a5d                	addiw	s4,s4,-9
    8000103c:	036a0063          	beq	s4,s6,8000105c <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001040:	0149d933          	srl	s2,s3,s4
    80001044:	1ff97913          	andi	s2,s2,511
    80001048:	090e                	slli	s2,s2,0x3
    8000104a:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000104c:	00093483          	ld	s1,0(s2)
    80001050:	0014f793          	andi	a5,s1,1
    80001054:	dfd5                	beqz	a5,80001010 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001056:	80a9                	srli	s1,s1,0xa
    80001058:	04b2                	slli	s1,s1,0xc
    8000105a:	b7c5                	j	8000103a <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000105c:	00c9d513          	srli	a0,s3,0xc
    80001060:	1ff57513          	andi	a0,a0,511
    80001064:	050e                	slli	a0,a0,0x3
    80001066:	9526                	add	a0,a0,s1
}
    80001068:	70e2                	ld	ra,56(sp)
    8000106a:	7442                	ld	s0,48(sp)
    8000106c:	74a2                	ld	s1,40(sp)
    8000106e:	7902                	ld	s2,32(sp)
    80001070:	69e2                	ld	s3,24(sp)
    80001072:	6a42                	ld	s4,16(sp)
    80001074:	6aa2                	ld	s5,8(sp)
    80001076:	6b02                	ld	s6,0(sp)
    80001078:	6121                	addi	sp,sp,64
    8000107a:	8082                	ret
        return 0;
    8000107c:	4501                	li	a0,0
    8000107e:	b7ed                	j	80001068 <walk+0x8e>

0000000080001080 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001080:	57fd                	li	a5,-1
    80001082:	83e9                	srli	a5,a5,0x1a
    80001084:	00b7f463          	bgeu	a5,a1,8000108c <walkaddr+0xc>
    return 0;
    80001088:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000108a:	8082                	ret
{
    8000108c:	1141                	addi	sp,sp,-16
    8000108e:	e406                	sd	ra,8(sp)
    80001090:	e022                	sd	s0,0(sp)
    80001092:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001094:	4601                	li	a2,0
    80001096:	00000097          	auipc	ra,0x0
    8000109a:	f44080e7          	jalr	-188(ra) # 80000fda <walk>
  if(pte == 0)
    8000109e:	c105                	beqz	a0,800010be <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010a0:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010a2:	0117f693          	andi	a3,a5,17
    800010a6:	4745                	li	a4,17
    return 0;
    800010a8:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010aa:	00e68663          	beq	a3,a4,800010b6 <walkaddr+0x36>
}
    800010ae:	60a2                	ld	ra,8(sp)
    800010b0:	6402                	ld	s0,0(sp)
    800010b2:	0141                	addi	sp,sp,16
    800010b4:	8082                	ret
  pa = PTE2PA(*pte);
    800010b6:	00a7d513          	srli	a0,a5,0xa
    800010ba:	0532                	slli	a0,a0,0xc
  return pa;
    800010bc:	bfcd                	j	800010ae <walkaddr+0x2e>
    return 0;
    800010be:	4501                	li	a0,0
    800010c0:	b7fd                	j	800010ae <walkaddr+0x2e>

00000000800010c2 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010c2:	715d                	addi	sp,sp,-80
    800010c4:	e486                	sd	ra,72(sp)
    800010c6:	e0a2                	sd	s0,64(sp)
    800010c8:	fc26                	sd	s1,56(sp)
    800010ca:	f84a                	sd	s2,48(sp)
    800010cc:	f44e                	sd	s3,40(sp)
    800010ce:	f052                	sd	s4,32(sp)
    800010d0:	ec56                	sd	s5,24(sp)
    800010d2:	e85a                	sd	s6,16(sp)
    800010d4:	e45e                	sd	s7,8(sp)
    800010d6:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d8:	c205                	beqz	a2,800010f8 <mappages+0x36>
    800010da:	8aaa                	mv	s5,a0
    800010dc:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010de:	77fd                	lui	a5,0xfffff
    800010e0:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010e4:	15fd                	addi	a1,a1,-1
    800010e6:	00c589b3          	add	s3,a1,a2
    800010ea:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ee:	8952                	mv	s2,s4
    800010f0:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010f4:	6b85                	lui	s7,0x1
    800010f6:	a015                	j	8000111a <mappages+0x58>
    panic("mappages: size");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	fe850513          	addi	a0,a0,-24 # 800080e0 <digits+0xa0>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	43e080e7          	jalr	1086(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fe850513          	addi	a0,a0,-24 # 800080f0 <digits+0xb0>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	42e080e7          	jalr	1070(ra) # 8000053e <panic>
    a += PGSIZE;
    80001118:	995e                	add	s2,s2,s7
  for(;;){
    8000111a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000111e:	4605                	li	a2,1
    80001120:	85ca                	mv	a1,s2
    80001122:	8556                	mv	a0,s5
    80001124:	00000097          	auipc	ra,0x0
    80001128:	eb6080e7          	jalr	-330(ra) # 80000fda <walk>
    8000112c:	cd19                	beqz	a0,8000114a <mappages+0x88>
    if(*pte & PTE_V)
    8000112e:	611c                	ld	a5,0(a0)
    80001130:	8b85                	andi	a5,a5,1
    80001132:	fbf9                	bnez	a5,80001108 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001134:	80b1                	srli	s1,s1,0xc
    80001136:	04aa                	slli	s1,s1,0xa
    80001138:	0164e4b3          	or	s1,s1,s6
    8000113c:	0014e493          	ori	s1,s1,1
    80001140:	e104                	sd	s1,0(a0)
    if(a == last)
    80001142:	fd391be3          	bne	s2,s3,80001118 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001146:	4501                	li	a0,0
    80001148:	a011                	j	8000114c <mappages+0x8a>
      return -1;
    8000114a:	557d                	li	a0,-1
}
    8000114c:	60a6                	ld	ra,72(sp)
    8000114e:	6406                	ld	s0,64(sp)
    80001150:	74e2                	ld	s1,56(sp)
    80001152:	7942                	ld	s2,48(sp)
    80001154:	79a2                	ld	s3,40(sp)
    80001156:	7a02                	ld	s4,32(sp)
    80001158:	6ae2                	ld	s5,24(sp)
    8000115a:	6b42                	ld	s6,16(sp)
    8000115c:	6ba2                	ld	s7,8(sp)
    8000115e:	6161                	addi	sp,sp,80
    80001160:	8082                	ret

0000000080001162 <kvmmap>:
{
    80001162:	1141                	addi	sp,sp,-16
    80001164:	e406                	sd	ra,8(sp)
    80001166:	e022                	sd	s0,0(sp)
    80001168:	0800                	addi	s0,sp,16
    8000116a:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000116c:	86b2                	mv	a3,a2
    8000116e:	863e                	mv	a2,a5
    80001170:	00000097          	auipc	ra,0x0
    80001174:	f52080e7          	jalr	-174(ra) # 800010c2 <mappages>
    80001178:	e509                	bnez	a0,80001182 <kvmmap+0x20>
}
    8000117a:	60a2                	ld	ra,8(sp)
    8000117c:	6402                	ld	s0,0(sp)
    8000117e:	0141                	addi	sp,sp,16
    80001180:	8082                	ret
    panic("kvmmap");
    80001182:	00007517          	auipc	a0,0x7
    80001186:	f7e50513          	addi	a0,a0,-130 # 80008100 <digits+0xc0>
    8000118a:	fffff097          	auipc	ra,0xfffff
    8000118e:	3b4080e7          	jalr	948(ra) # 8000053e <panic>

0000000080001192 <kvmmake>:
{
    80001192:	1101                	addi	sp,sp,-32
    80001194:	ec06                	sd	ra,24(sp)
    80001196:	e822                	sd	s0,16(sp)
    80001198:	e426                	sd	s1,8(sp)
    8000119a:	e04a                	sd	s2,0(sp)
    8000119c:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	956080e7          	jalr	-1706(ra) # 80000af4 <kalloc>
    800011a6:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a8:	6605                	lui	a2,0x1
    800011aa:	4581                	li	a1,0
    800011ac:	00000097          	auipc	ra,0x0
    800011b0:	b46080e7          	jalr	-1210(ra) # 80000cf2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011b4:	4719                	li	a4,6
    800011b6:	6685                	lui	a3,0x1
    800011b8:	10000637          	lui	a2,0x10000
    800011bc:	100005b7          	lui	a1,0x10000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	fa0080e7          	jalr	-96(ra) # 80001162 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011ca:	4719                	li	a4,6
    800011cc:	6685                	lui	a3,0x1
    800011ce:	10001637          	lui	a2,0x10001
    800011d2:	100015b7          	lui	a1,0x10001
    800011d6:	8526                	mv	a0,s1
    800011d8:	00000097          	auipc	ra,0x0
    800011dc:	f8a080e7          	jalr	-118(ra) # 80001162 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011e0:	4719                	li	a4,6
    800011e2:	004006b7          	lui	a3,0x400
    800011e6:	0c000637          	lui	a2,0xc000
    800011ea:	0c0005b7          	lui	a1,0xc000
    800011ee:	8526                	mv	a0,s1
    800011f0:	00000097          	auipc	ra,0x0
    800011f4:	f72080e7          	jalr	-142(ra) # 80001162 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f8:	00007917          	auipc	s2,0x7
    800011fc:	e0890913          	addi	s2,s2,-504 # 80008000 <etext>
    80001200:	4729                	li	a4,10
    80001202:	80007697          	auipc	a3,0x80007
    80001206:	dfe68693          	addi	a3,a3,-514 # 8000 <_entry-0x7fff8000>
    8000120a:	4605                	li	a2,1
    8000120c:	067e                	slli	a2,a2,0x1f
    8000120e:	85b2                	mv	a1,a2
    80001210:	8526                	mv	a0,s1
    80001212:	00000097          	auipc	ra,0x0
    80001216:	f50080e7          	jalr	-176(ra) # 80001162 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000121a:	4719                	li	a4,6
    8000121c:	46c5                	li	a3,17
    8000121e:	06ee                	slli	a3,a3,0x1b
    80001220:	412686b3          	sub	a3,a3,s2
    80001224:	864a                	mv	a2,s2
    80001226:	85ca                	mv	a1,s2
    80001228:	8526                	mv	a0,s1
    8000122a:	00000097          	auipc	ra,0x0
    8000122e:	f38080e7          	jalr	-200(ra) # 80001162 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001232:	4729                	li	a4,10
    80001234:	6685                	lui	a3,0x1
    80001236:	00006617          	auipc	a2,0x6
    8000123a:	dca60613          	addi	a2,a2,-566 # 80007000 <_trampoline>
    8000123e:	040005b7          	lui	a1,0x4000
    80001242:	15fd                	addi	a1,a1,-1
    80001244:	05b2                	slli	a1,a1,0xc
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	f1a080e7          	jalr	-230(ra) # 80001162 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001250:	8526                	mv	a0,s1
    80001252:	00001097          	auipc	ra,0x1
    80001256:	920080e7          	jalr	-1760(ra) # 80001b72 <proc_mapstacks>
}
    8000125a:	8526                	mv	a0,s1
    8000125c:	60e2                	ld	ra,24(sp)
    8000125e:	6442                	ld	s0,16(sp)
    80001260:	64a2                	ld	s1,8(sp)
    80001262:	6902                	ld	s2,0(sp)
    80001264:	6105                	addi	sp,sp,32
    80001266:	8082                	ret

0000000080001268 <kvminit>:
{
    80001268:	1141                	addi	sp,sp,-16
    8000126a:	e406                	sd	ra,8(sp)
    8000126c:	e022                	sd	s0,0(sp)
    8000126e:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001270:	00000097          	auipc	ra,0x0
    80001274:	f22080e7          	jalr	-222(ra) # 80001192 <kvmmake>
    80001278:	00008797          	auipc	a5,0x8
    8000127c:	daa7b423          	sd	a0,-600(a5) # 80009020 <kernel_pagetable>
}
    80001280:	60a2                	ld	ra,8(sp)
    80001282:	6402                	ld	s0,0(sp)
    80001284:	0141                	addi	sp,sp,16
    80001286:	8082                	ret

0000000080001288 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001288:	715d                	addi	sp,sp,-80
    8000128a:	e486                	sd	ra,72(sp)
    8000128c:	e0a2                	sd	s0,64(sp)
    8000128e:	fc26                	sd	s1,56(sp)
    80001290:	f84a                	sd	s2,48(sp)
    80001292:	f44e                	sd	s3,40(sp)
    80001294:	f052                	sd	s4,32(sp)
    80001296:	ec56                	sd	s5,24(sp)
    80001298:	e85a                	sd	s6,16(sp)
    8000129a:	e45e                	sd	s7,8(sp)
    8000129c:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000129e:	03459793          	slli	a5,a1,0x34
    800012a2:	e795                	bnez	a5,800012ce <uvmunmap+0x46>
    800012a4:	8a2a                	mv	s4,a0
    800012a6:	892e                	mv	s2,a1
    800012a8:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012aa:	0632                	slli	a2,a2,0xc
    800012ac:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012b0:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012b2:	6b05                	lui	s6,0x1
    800012b4:	0735e863          	bltu	a1,s3,80001324 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b8:	60a6                	ld	ra,72(sp)
    800012ba:	6406                	ld	s0,64(sp)
    800012bc:	74e2                	ld	s1,56(sp)
    800012be:	7942                	ld	s2,48(sp)
    800012c0:	79a2                	ld	s3,40(sp)
    800012c2:	7a02                	ld	s4,32(sp)
    800012c4:	6ae2                	ld	s5,24(sp)
    800012c6:	6b42                	ld	s6,16(sp)
    800012c8:	6ba2                	ld	s7,8(sp)
    800012ca:	6161                	addi	sp,sp,80
    800012cc:	8082                	ret
    panic("uvmunmap: not aligned");
    800012ce:	00007517          	auipc	a0,0x7
    800012d2:	e3a50513          	addi	a0,a0,-454 # 80008108 <digits+0xc8>
    800012d6:	fffff097          	auipc	ra,0xfffff
    800012da:	268080e7          	jalr	616(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012de:	00007517          	auipc	a0,0x7
    800012e2:	e4250513          	addi	a0,a0,-446 # 80008120 <digits+0xe0>
    800012e6:	fffff097          	auipc	ra,0xfffff
    800012ea:	258080e7          	jalr	600(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ee:	00007517          	auipc	a0,0x7
    800012f2:	e4250513          	addi	a0,a0,-446 # 80008130 <digits+0xf0>
    800012f6:	fffff097          	auipc	ra,0xfffff
    800012fa:	248080e7          	jalr	584(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012fe:	00007517          	auipc	a0,0x7
    80001302:	e4a50513          	addi	a0,a0,-438 # 80008148 <digits+0x108>
    80001306:	fffff097          	auipc	ra,0xfffff
    8000130a:	238080e7          	jalr	568(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    8000130e:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001310:	0532                	slli	a0,a0,0xc
    80001312:	fffff097          	auipc	ra,0xfffff
    80001316:	6e6080e7          	jalr	1766(ra) # 800009f8 <kfree>
    *pte = 0;
    8000131a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000131e:	995a                	add	s2,s2,s6
    80001320:	f9397ce3          	bgeu	s2,s3,800012b8 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001324:	4601                	li	a2,0
    80001326:	85ca                	mv	a1,s2
    80001328:	8552                	mv	a0,s4
    8000132a:	00000097          	auipc	ra,0x0
    8000132e:	cb0080e7          	jalr	-848(ra) # 80000fda <walk>
    80001332:	84aa                	mv	s1,a0
    80001334:	d54d                	beqz	a0,800012de <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001336:	6108                	ld	a0,0(a0)
    80001338:	00157793          	andi	a5,a0,1
    8000133c:	dbcd                	beqz	a5,800012ee <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000133e:	3ff57793          	andi	a5,a0,1023
    80001342:	fb778ee3          	beq	a5,s7,800012fe <uvmunmap+0x76>
    if(do_free){
    80001346:	fc0a8ae3          	beqz	s5,8000131a <uvmunmap+0x92>
    8000134a:	b7d1                	j	8000130e <uvmunmap+0x86>

000000008000134c <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000134c:	1101                	addi	sp,sp,-32
    8000134e:	ec06                	sd	ra,24(sp)
    80001350:	e822                	sd	s0,16(sp)
    80001352:	e426                	sd	s1,8(sp)
    80001354:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001356:	fffff097          	auipc	ra,0xfffff
    8000135a:	79e080e7          	jalr	1950(ra) # 80000af4 <kalloc>
    8000135e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001360:	c519                	beqz	a0,8000136e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001362:	6605                	lui	a2,0x1
    80001364:	4581                	li	a1,0
    80001366:	00000097          	auipc	ra,0x0
    8000136a:	98c080e7          	jalr	-1652(ra) # 80000cf2 <memset>
  return pagetable;
}
    8000136e:	8526                	mv	a0,s1
    80001370:	60e2                	ld	ra,24(sp)
    80001372:	6442                	ld	s0,16(sp)
    80001374:	64a2                	ld	s1,8(sp)
    80001376:	6105                	addi	sp,sp,32
    80001378:	8082                	ret

000000008000137a <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000137a:	7179                	addi	sp,sp,-48
    8000137c:	f406                	sd	ra,40(sp)
    8000137e:	f022                	sd	s0,32(sp)
    80001380:	ec26                	sd	s1,24(sp)
    80001382:	e84a                	sd	s2,16(sp)
    80001384:	e44e                	sd	s3,8(sp)
    80001386:	e052                	sd	s4,0(sp)
    80001388:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000138a:	6785                	lui	a5,0x1
    8000138c:	04f67863          	bgeu	a2,a5,800013dc <uvminit+0x62>
    80001390:	8a2a                	mv	s4,a0
    80001392:	89ae                	mv	s3,a1
    80001394:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001396:	fffff097          	auipc	ra,0xfffff
    8000139a:	75e080e7          	jalr	1886(ra) # 80000af4 <kalloc>
    8000139e:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013a0:	6605                	lui	a2,0x1
    800013a2:	4581                	li	a1,0
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	94e080e7          	jalr	-1714(ra) # 80000cf2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013ac:	4779                	li	a4,30
    800013ae:	86ca                	mv	a3,s2
    800013b0:	6605                	lui	a2,0x1
    800013b2:	4581                	li	a1,0
    800013b4:	8552                	mv	a0,s4
    800013b6:	00000097          	auipc	ra,0x0
    800013ba:	d0c080e7          	jalr	-756(ra) # 800010c2 <mappages>
  memmove(mem, src, sz);
    800013be:	8626                	mv	a2,s1
    800013c0:	85ce                	mv	a1,s3
    800013c2:	854a                	mv	a0,s2
    800013c4:	00000097          	auipc	ra,0x0
    800013c8:	98e080e7          	jalr	-1650(ra) # 80000d52 <memmove>
}
    800013cc:	70a2                	ld	ra,40(sp)
    800013ce:	7402                	ld	s0,32(sp)
    800013d0:	64e2                	ld	s1,24(sp)
    800013d2:	6942                	ld	s2,16(sp)
    800013d4:	69a2                	ld	s3,8(sp)
    800013d6:	6a02                	ld	s4,0(sp)
    800013d8:	6145                	addi	sp,sp,48
    800013da:	8082                	ret
    panic("inituvm: more than a page");
    800013dc:	00007517          	auipc	a0,0x7
    800013e0:	d8450513          	addi	a0,a0,-636 # 80008160 <digits+0x120>
    800013e4:	fffff097          	auipc	ra,0xfffff
    800013e8:	15a080e7          	jalr	346(ra) # 8000053e <panic>

00000000800013ec <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013ec:	1101                	addi	sp,sp,-32
    800013ee:	ec06                	sd	ra,24(sp)
    800013f0:	e822                	sd	s0,16(sp)
    800013f2:	e426                	sd	s1,8(sp)
    800013f4:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013f6:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f8:	00b67d63          	bgeu	a2,a1,80001412 <uvmdealloc+0x26>
    800013fc:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013fe:	6785                	lui	a5,0x1
    80001400:	17fd                	addi	a5,a5,-1
    80001402:	00f60733          	add	a4,a2,a5
    80001406:	767d                	lui	a2,0xfffff
    80001408:	8f71                	and	a4,a4,a2
    8000140a:	97ae                	add	a5,a5,a1
    8000140c:	8ff1                	and	a5,a5,a2
    8000140e:	00f76863          	bltu	a4,a5,8000141e <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001412:	8526                	mv	a0,s1
    80001414:	60e2                	ld	ra,24(sp)
    80001416:	6442                	ld	s0,16(sp)
    80001418:	64a2                	ld	s1,8(sp)
    8000141a:	6105                	addi	sp,sp,32
    8000141c:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000141e:	8f99                	sub	a5,a5,a4
    80001420:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001422:	4685                	li	a3,1
    80001424:	0007861b          	sext.w	a2,a5
    80001428:	85ba                	mv	a1,a4
    8000142a:	00000097          	auipc	ra,0x0
    8000142e:	e5e080e7          	jalr	-418(ra) # 80001288 <uvmunmap>
    80001432:	b7c5                	j	80001412 <uvmdealloc+0x26>

0000000080001434 <uvmalloc>:
  if(newsz < oldsz)
    80001434:	0ab66163          	bltu	a2,a1,800014d6 <uvmalloc+0xa2>
{
    80001438:	7139                	addi	sp,sp,-64
    8000143a:	fc06                	sd	ra,56(sp)
    8000143c:	f822                	sd	s0,48(sp)
    8000143e:	f426                	sd	s1,40(sp)
    80001440:	f04a                	sd	s2,32(sp)
    80001442:	ec4e                	sd	s3,24(sp)
    80001444:	e852                	sd	s4,16(sp)
    80001446:	e456                	sd	s5,8(sp)
    80001448:	0080                	addi	s0,sp,64
    8000144a:	8aaa                	mv	s5,a0
    8000144c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000144e:	6985                	lui	s3,0x1
    80001450:	19fd                	addi	s3,s3,-1
    80001452:	95ce                	add	a1,a1,s3
    80001454:	79fd                	lui	s3,0xfffff
    80001456:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145a:	08c9f063          	bgeu	s3,a2,800014da <uvmalloc+0xa6>
    8000145e:	894e                	mv	s2,s3
    mem = kalloc();
    80001460:	fffff097          	auipc	ra,0xfffff
    80001464:	694080e7          	jalr	1684(ra) # 80000af4 <kalloc>
    80001468:	84aa                	mv	s1,a0
    if(mem == 0){
    8000146a:	c51d                	beqz	a0,80001498 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000146c:	6605                	lui	a2,0x1
    8000146e:	4581                	li	a1,0
    80001470:	00000097          	auipc	ra,0x0
    80001474:	882080e7          	jalr	-1918(ra) # 80000cf2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001478:	4779                	li	a4,30
    8000147a:	86a6                	mv	a3,s1
    8000147c:	6605                	lui	a2,0x1
    8000147e:	85ca                	mv	a1,s2
    80001480:	8556                	mv	a0,s5
    80001482:	00000097          	auipc	ra,0x0
    80001486:	c40080e7          	jalr	-960(ra) # 800010c2 <mappages>
    8000148a:	e905                	bnez	a0,800014ba <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148c:	6785                	lui	a5,0x1
    8000148e:	993e                	add	s2,s2,a5
    80001490:	fd4968e3          	bltu	s2,s4,80001460 <uvmalloc+0x2c>
  return newsz;
    80001494:	8552                	mv	a0,s4
    80001496:	a809                	j	800014a8 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001498:	864e                	mv	a2,s3
    8000149a:	85ca                	mv	a1,s2
    8000149c:	8556                	mv	a0,s5
    8000149e:	00000097          	auipc	ra,0x0
    800014a2:	f4e080e7          	jalr	-178(ra) # 800013ec <uvmdealloc>
      return 0;
    800014a6:	4501                	li	a0,0
}
    800014a8:	70e2                	ld	ra,56(sp)
    800014aa:	7442                	ld	s0,48(sp)
    800014ac:	74a2                	ld	s1,40(sp)
    800014ae:	7902                	ld	s2,32(sp)
    800014b0:	69e2                	ld	s3,24(sp)
    800014b2:	6a42                	ld	s4,16(sp)
    800014b4:	6aa2                	ld	s5,8(sp)
    800014b6:	6121                	addi	sp,sp,64
    800014b8:	8082                	ret
      kfree(mem);
    800014ba:	8526                	mv	a0,s1
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	53c080e7          	jalr	1340(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c4:	864e                	mv	a2,s3
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	f22080e7          	jalr	-222(ra) # 800013ec <uvmdealloc>
      return 0;
    800014d2:	4501                	li	a0,0
    800014d4:	bfd1                	j	800014a8 <uvmalloc+0x74>
    return oldsz;
    800014d6:	852e                	mv	a0,a1
}
    800014d8:	8082                	ret
  return newsz;
    800014da:	8532                	mv	a0,a2
    800014dc:	b7f1                	j	800014a8 <uvmalloc+0x74>

00000000800014de <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014de:	7179                	addi	sp,sp,-48
    800014e0:	f406                	sd	ra,40(sp)
    800014e2:	f022                	sd	s0,32(sp)
    800014e4:	ec26                	sd	s1,24(sp)
    800014e6:	e84a                	sd	s2,16(sp)
    800014e8:	e44e                	sd	s3,8(sp)
    800014ea:	e052                	sd	s4,0(sp)
    800014ec:	1800                	addi	s0,sp,48
    800014ee:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f0:	84aa                	mv	s1,a0
    800014f2:	6905                	lui	s2,0x1
    800014f4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	4985                	li	s3,1
    800014f8:	a821                	j	80001510 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014fa:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014fc:	0532                	slli	a0,a0,0xc
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	fe0080e7          	jalr	-32(ra) # 800014de <freewalk>
      pagetable[i] = 0;
    80001506:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000150a:	04a1                	addi	s1,s1,8
    8000150c:	03248163          	beq	s1,s2,8000152e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001510:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	00f57793          	andi	a5,a0,15
    80001516:	ff3782e3          	beq	a5,s3,800014fa <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000151a:	8905                	andi	a0,a0,1
    8000151c:	d57d                	beqz	a0,8000150a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151e:	00007517          	auipc	a0,0x7
    80001522:	c6250513          	addi	a0,a0,-926 # 80008180 <digits+0x140>
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	018080e7          	jalr	24(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000152e:	8552                	mv	a0,s4
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	4c8080e7          	jalr	1224(ra) # 800009f8 <kfree>
}
    80001538:	70a2                	ld	ra,40(sp)
    8000153a:	7402                	ld	s0,32(sp)
    8000153c:	64e2                	ld	s1,24(sp)
    8000153e:	6942                	ld	s2,16(sp)
    80001540:	69a2                	ld	s3,8(sp)
    80001542:	6a02                	ld	s4,0(sp)
    80001544:	6145                	addi	sp,sp,48
    80001546:	8082                	ret

0000000080001548 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001548:	1101                	addi	sp,sp,-32
    8000154a:	ec06                	sd	ra,24(sp)
    8000154c:	e822                	sd	s0,16(sp)
    8000154e:	e426                	sd	s1,8(sp)
    80001550:	1000                	addi	s0,sp,32
    80001552:	84aa                	mv	s1,a0
  if(sz > 0)
    80001554:	e999                	bnez	a1,8000156a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001556:	8526                	mv	a0,s1
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f86080e7          	jalr	-122(ra) # 800014de <freewalk>
}
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000156a:	6605                	lui	a2,0x1
    8000156c:	167d                	addi	a2,a2,-1
    8000156e:	962e                	add	a2,a2,a1
    80001570:	4685                	li	a3,1
    80001572:	8231                	srli	a2,a2,0xc
    80001574:	4581                	li	a1,0
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	d12080e7          	jalr	-750(ra) # 80001288 <uvmunmap>
    8000157e:	bfe1                	j	80001556 <uvmfree+0xe>

0000000080001580 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001580:	c679                	beqz	a2,8000164e <uvmcopy+0xce>
{
    80001582:	715d                	addi	sp,sp,-80
    80001584:	e486                	sd	ra,72(sp)
    80001586:	e0a2                	sd	s0,64(sp)
    80001588:	fc26                	sd	s1,56(sp)
    8000158a:	f84a                	sd	s2,48(sp)
    8000158c:	f44e                	sd	s3,40(sp)
    8000158e:	f052                	sd	s4,32(sp)
    80001590:	ec56                	sd	s5,24(sp)
    80001592:	e85a                	sd	s6,16(sp)
    80001594:	e45e                	sd	s7,8(sp)
    80001596:	0880                	addi	s0,sp,80
    80001598:	8b2a                	mv	s6,a0
    8000159a:	8aae                	mv	s5,a1
    8000159c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015a0:	4601                	li	a2,0
    800015a2:	85ce                	mv	a1,s3
    800015a4:	855a                	mv	a0,s6
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	a34080e7          	jalr	-1484(ra) # 80000fda <walk>
    800015ae:	c531                	beqz	a0,800015fa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015b0:	6118                	ld	a4,0(a0)
    800015b2:	00177793          	andi	a5,a4,1
    800015b6:	cbb1                	beqz	a5,8000160a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b8:	00a75593          	srli	a1,a4,0xa
    800015bc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	530080e7          	jalr	1328(ra) # 80000af4 <kalloc>
    800015cc:	892a                	mv	s2,a0
    800015ce:	c939                	beqz	a0,80001624 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d0:	6605                	lui	a2,0x1
    800015d2:	85de                	mv	a1,s7
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	77e080e7          	jalr	1918(ra) # 80000d52 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015dc:	8726                	mv	a4,s1
    800015de:	86ca                	mv	a3,s2
    800015e0:	6605                	lui	a2,0x1
    800015e2:	85ce                	mv	a1,s3
    800015e4:	8556                	mv	a0,s5
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	adc080e7          	jalr	-1316(ra) # 800010c2 <mappages>
    800015ee:	e515                	bnez	a0,8000161a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015f0:	6785                	lui	a5,0x1
    800015f2:	99be                	add	s3,s3,a5
    800015f4:	fb49e6e3          	bltu	s3,s4,800015a0 <uvmcopy+0x20>
    800015f8:	a081                	j	80001638 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015fa:	00007517          	auipc	a0,0x7
    800015fe:	b9650513          	addi	a0,a0,-1130 # 80008190 <digits+0x150>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	f3c080e7          	jalr	-196(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    8000160a:	00007517          	auipc	a0,0x7
    8000160e:	ba650513          	addi	a0,a0,-1114 # 800081b0 <digits+0x170>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      kfree(mem);
    8000161a:	854a                	mv	a0,s2
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	3dc080e7          	jalr	988(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001624:	4685                	li	a3,1
    80001626:	00c9d613          	srli	a2,s3,0xc
    8000162a:	4581                	li	a1,0
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	c5a080e7          	jalr	-934(ra) # 80001288 <uvmunmap>
  return -1;
    80001636:	557d                	li	a0,-1
}
    80001638:	60a6                	ld	ra,72(sp)
    8000163a:	6406                	ld	s0,64(sp)
    8000163c:	74e2                	ld	s1,56(sp)
    8000163e:	7942                	ld	s2,48(sp)
    80001640:	79a2                	ld	s3,40(sp)
    80001642:	7a02                	ld	s4,32(sp)
    80001644:	6ae2                	ld	s5,24(sp)
    80001646:	6b42                	ld	s6,16(sp)
    80001648:	6ba2                	ld	s7,8(sp)
    8000164a:	6161                	addi	sp,sp,80
    8000164c:	8082                	ret
  return 0;
    8000164e:	4501                	li	a0,0
}
    80001650:	8082                	ret

0000000080001652 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001652:	1141                	addi	sp,sp,-16
    80001654:	e406                	sd	ra,8(sp)
    80001656:	e022                	sd	s0,0(sp)
    80001658:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000165a:	4601                	li	a2,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	97e080e7          	jalr	-1666(ra) # 80000fda <walk>
  if(pte == 0)
    80001664:	c901                	beqz	a0,80001674 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001666:	611c                	ld	a5,0(a0)
    80001668:	9bbd                	andi	a5,a5,-17
    8000166a:	e11c                	sd	a5,0(a0)
}
    8000166c:	60a2                	ld	ra,8(sp)
    8000166e:	6402                	ld	s0,0(sp)
    80001670:	0141                	addi	sp,sp,16
    80001672:	8082                	ret
    panic("uvmclear");
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b5c50513          	addi	a0,a0,-1188 # 800081d0 <digits+0x190>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	ec2080e7          	jalr	-318(ra) # 8000053e <panic>

0000000080001684 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001684:	c6bd                	beqz	a3,800016f2 <copyout+0x6e>
{
    80001686:	715d                	addi	sp,sp,-80
    80001688:	e486                	sd	ra,72(sp)
    8000168a:	e0a2                	sd	s0,64(sp)
    8000168c:	fc26                	sd	s1,56(sp)
    8000168e:	f84a                	sd	s2,48(sp)
    80001690:	f44e                	sd	s3,40(sp)
    80001692:	f052                	sd	s4,32(sp)
    80001694:	ec56                	sd	s5,24(sp)
    80001696:	e85a                	sd	s6,16(sp)
    80001698:	e45e                	sd	s7,8(sp)
    8000169a:	e062                	sd	s8,0(sp)
    8000169c:	0880                	addi	s0,sp,80
    8000169e:	8b2a                	mv	s6,a0
    800016a0:	8c2e                	mv	s8,a1
    800016a2:	8a32                	mv	s4,a2
    800016a4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a8:	6a85                	lui	s5,0x1
    800016aa:	a015                	j	800016ce <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ac:	9562                	add	a0,a0,s8
    800016ae:	0004861b          	sext.w	a2,s1
    800016b2:	85d2                	mv	a1,s4
    800016b4:	41250533          	sub	a0,a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	69a080e7          	jalr	1690(ra) # 80000d52 <memmove>

    len -= n;
    800016c0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ca:	02098263          	beqz	s3,800016ee <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ce:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d2:	85ca                	mv	a1,s2
    800016d4:	855a                	mv	a0,s6
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	9aa080e7          	jalr	-1622(ra) # 80001080 <walkaddr>
    if(pa0 == 0)
    800016de:	cd01                	beqz	a0,800016f6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e0:	418904b3          	sub	s1,s2,s8
    800016e4:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e6:	fc99f3e3          	bgeu	s3,s1,800016ac <copyout+0x28>
    800016ea:	84ce                	mv	s1,s3
    800016ec:	b7c1                	j	800016ac <copyout+0x28>
  }
  return 0;
    800016ee:	4501                	li	a0,0
    800016f0:	a021                	j	800016f8 <copyout+0x74>
    800016f2:	4501                	li	a0,0
}
    800016f4:	8082                	ret
      return -1;
    800016f6:	557d                	li	a0,-1
}
    800016f8:	60a6                	ld	ra,72(sp)
    800016fa:	6406                	ld	s0,64(sp)
    800016fc:	74e2                	ld	s1,56(sp)
    800016fe:	7942                	ld	s2,48(sp)
    80001700:	79a2                	ld	s3,40(sp)
    80001702:	7a02                	ld	s4,32(sp)
    80001704:	6ae2                	ld	s5,24(sp)
    80001706:	6b42                	ld	s6,16(sp)
    80001708:	6ba2                	ld	s7,8(sp)
    8000170a:	6c02                	ld	s8,0(sp)
    8000170c:	6161                	addi	sp,sp,80
    8000170e:	8082                	ret

0000000080001710 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001710:	c6bd                	beqz	a3,8000177e <copyin+0x6e>
{
    80001712:	715d                	addi	sp,sp,-80
    80001714:	e486                	sd	ra,72(sp)
    80001716:	e0a2                	sd	s0,64(sp)
    80001718:	fc26                	sd	s1,56(sp)
    8000171a:	f84a                	sd	s2,48(sp)
    8000171c:	f44e                	sd	s3,40(sp)
    8000171e:	f052                	sd	s4,32(sp)
    80001720:	ec56                	sd	s5,24(sp)
    80001722:	e85a                	sd	s6,16(sp)
    80001724:	e45e                	sd	s7,8(sp)
    80001726:	e062                	sd	s8,0(sp)
    80001728:	0880                	addi	s0,sp,80
    8000172a:	8b2a                	mv	s6,a0
    8000172c:	8a2e                	mv	s4,a1
    8000172e:	8c32                	mv	s8,a2
    80001730:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001732:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001734:	6a85                	lui	s5,0x1
    80001736:	a015                	j	8000175a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001738:	9562                	add	a0,a0,s8
    8000173a:	0004861b          	sext.w	a2,s1
    8000173e:	412505b3          	sub	a1,a0,s2
    80001742:	8552                	mv	a0,s4
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	60e080e7          	jalr	1550(ra) # 80000d52 <memmove>

    len -= n;
    8000174c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001750:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001752:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001756:	02098263          	beqz	s3,8000177a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000175a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175e:	85ca                	mv	a1,s2
    80001760:	855a                	mv	a0,s6
    80001762:	00000097          	auipc	ra,0x0
    80001766:	91e080e7          	jalr	-1762(ra) # 80001080 <walkaddr>
    if(pa0 == 0)
    8000176a:	cd01                	beqz	a0,80001782 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000176c:	418904b3          	sub	s1,s2,s8
    80001770:	94d6                	add	s1,s1,s5
    if(n > len)
    80001772:	fc99f3e3          	bgeu	s3,s1,80001738 <copyin+0x28>
    80001776:	84ce                	mv	s1,s3
    80001778:	b7c1                	j	80001738 <copyin+0x28>
  }
  return 0;
    8000177a:	4501                	li	a0,0
    8000177c:	a021                	j	80001784 <copyin+0x74>
    8000177e:	4501                	li	a0,0
}
    80001780:	8082                	ret
      return -1;
    80001782:	557d                	li	a0,-1
}
    80001784:	60a6                	ld	ra,72(sp)
    80001786:	6406                	ld	s0,64(sp)
    80001788:	74e2                	ld	s1,56(sp)
    8000178a:	7942                	ld	s2,48(sp)
    8000178c:	79a2                	ld	s3,40(sp)
    8000178e:	7a02                	ld	s4,32(sp)
    80001790:	6ae2                	ld	s5,24(sp)
    80001792:	6b42                	ld	s6,16(sp)
    80001794:	6ba2                	ld	s7,8(sp)
    80001796:	6c02                	ld	s8,0(sp)
    80001798:	6161                	addi	sp,sp,80
    8000179a:	8082                	ret

000000008000179c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179c:	c6c5                	beqz	a3,80001844 <copyinstr+0xa8>
{
    8000179e:	715d                	addi	sp,sp,-80
    800017a0:	e486                	sd	ra,72(sp)
    800017a2:	e0a2                	sd	s0,64(sp)
    800017a4:	fc26                	sd	s1,56(sp)
    800017a6:	f84a                	sd	s2,48(sp)
    800017a8:	f44e                	sd	s3,40(sp)
    800017aa:	f052                	sd	s4,32(sp)
    800017ac:	ec56                	sd	s5,24(sp)
    800017ae:	e85a                	sd	s6,16(sp)
    800017b0:	e45e                	sd	s7,8(sp)
    800017b2:	0880                	addi	s0,sp,80
    800017b4:	8a2a                	mv	s4,a0
    800017b6:	8b2e                	mv	s6,a1
    800017b8:	8bb2                	mv	s7,a2
    800017ba:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017bc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017be:	6985                	lui	s3,0x1
    800017c0:	a035                	j	800017ec <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c8:	0017b793          	seqz	a5,a5
    800017cc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6161                	addi	sp,sp,80
    800017e4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ea:	c8a9                	beqz	s1,8000183c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ec:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	88c080e7          	jalr	-1908(ra) # 80001080 <walkaddr>
    if(pa0 == 0)
    800017fc:	c131                	beqz	a0,80001840 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fe:	41790833          	sub	a6,s2,s7
    80001802:	984e                	add	a6,a6,s3
    if(n > max)
    80001804:	0104f363          	bgeu	s1,a6,8000180a <copyinstr+0x6e>
    80001808:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000180a:	955e                	add	a0,a0,s7
    8000180c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001810:	fc080be3          	beqz	a6,800017e6 <copyinstr+0x4a>
    80001814:	985a                	add	a6,a6,s6
    80001816:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001818:	41650633          	sub	a2,a0,s6
    8000181c:	14fd                	addi	s1,s1,-1
    8000181e:	9b26                	add	s6,s6,s1
    80001820:	00f60733          	add	a4,a2,a5
    80001824:	00074703          	lbu	a4,0(a4)
    80001828:	df49                	beqz	a4,800017c2 <copyinstr+0x26>
        *dst = *p;
    8000182a:	00e78023          	sb	a4,0(a5)
      --max;
    8000182e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001832:	0785                	addi	a5,a5,1
    while(n > 0){
    80001834:	ff0796e3          	bne	a5,a6,80001820 <copyinstr+0x84>
      dst++;
    80001838:	8b42                	mv	s6,a6
    8000183a:	b775                	j	800017e6 <copyinstr+0x4a>
    8000183c:	4781                	li	a5,0
    8000183e:	b769                	j	800017c8 <copyinstr+0x2c>
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b779                	j	800017d0 <copyinstr+0x34>
  int got_null = 0;
    80001844:	4781                	li	a5,0
  if(got_null){
    80001846:	0017b793          	seqz	a5,a5
    8000184a:	40f00533          	neg	a0,a5
}
    8000184e:	8082                	ret

0000000080001850 <find_remove>:
int sleeping_head = -1;
int unused_head = -1;
struct spinlock zombie_lock, sleeping_lock, unused_lock;

int find_remove(struct proc *curr_proc, struct proc *to_remove)
{ 
    80001850:	7139                	addi	sp,sp,-64
    80001852:	fc06                	sd	ra,56(sp)
    80001854:	f822                	sd	s0,48(sp)
    80001856:	f426                	sd	s1,40(sp)
    80001858:	f04a                	sd	s2,32(sp)
    8000185a:	ec4e                	sd	s3,24(sp)
    8000185c:	e852                	sd	s4,16(sp)
    8000185e:	e456                	sd	s5,8(sp)
    80001860:	0080                	addi	s0,sp,64
    80001862:	84aa                	mv	s1,a0
  while (curr_proc->next != -1)
    80001864:	4928                	lw	a0,80(a0)
    80001866:	57fd                	li	a5,-1
    80001868:	04f50963          	beq	a0,a5,800018ba <find_remove+0x6a>
    8000186c:	8a2e                	mv	s4,a1
  {
    acquire(&proc[curr_proc->next].p_lock);
    8000186e:	18800993          	li	s3,392
    80001872:	00010917          	auipc	s2,0x10
    80001876:	fa690913          	addi	s2,s2,-90 # 80011818 <proc>
  while (curr_proc->next != -1)
    8000187a:	5afd                	li	s5,-1
    acquire(&proc[curr_proc->next].p_lock);
    8000187c:	03350533          	mul	a0,a0,s3
    80001880:	03850513          	addi	a0,a0,56
    80001884:	954a                	add	a0,a0,s2
    80001886:	fffff097          	auipc	ra,0xfffff
    8000188a:	35e080e7          	jalr	862(ra) # 80000be4 <acquire>
    if (proc[curr_proc->next].proc_idx == to_remove->proc_idx)
    8000188e:	48bc                	lw	a5,80(s1)
    80001890:	033787b3          	mul	a5,a5,s3
    80001894:	97ca                	add	a5,a5,s2
    80001896:	4bf8                	lw	a4,84(a5)
    80001898:	054a2783          	lw	a5,84(s4) # fffffffffffff054 <end+0xffffffff7ffd9054>
    8000189c:	02f70f63          	beq	a4,a5,800018da <find_remove+0x8a>
      to_remove->next = -1;
      release(&curr_proc->p_lock);
      release(&to_remove->p_lock);
      return 1;
    }else
    release(&curr_proc->p_lock);
    800018a0:	03848513          	addi	a0,s1,56
    800018a4:	fffff097          	auipc	ra,0xfffff
    800018a8:	3f4080e7          	jalr	1012(ra) # 80000c98 <release>
    curr_proc = &proc[curr_proc->next];
    800018ac:	48a4                	lw	s1,80(s1)
    800018ae:	033484b3          	mul	s1,s1,s3
    800018b2:	94ca                	add	s1,s1,s2
  while (curr_proc->next != -1)
    800018b4:	48a8                	lw	a0,80(s1)
    800018b6:	fd5513e3          	bne	a0,s5,8000187c <find_remove+0x2c>
  }
  release(&curr_proc->p_lock);
    800018ba:	03848513          	addi	a0,s1,56
    800018be:	fffff097          	auipc	ra,0xfffff
    800018c2:	3da080e7          	jalr	986(ra) # 80000c98 <release>
  return -1;
    800018c6:	557d                	li	a0,-1
}
    800018c8:	70e2                	ld	ra,56(sp)
    800018ca:	7442                	ld	s0,48(sp)
    800018cc:	74a2                	ld	s1,40(sp)
    800018ce:	7902                	ld	s2,32(sp)
    800018d0:	69e2                	ld	s3,24(sp)
    800018d2:	6a42                	ld	s4,16(sp)
    800018d4:	6aa2                	ld	s5,8(sp)
    800018d6:	6121                	addi	sp,sp,64
    800018d8:	8082                	ret
      curr_proc->next = to_remove->next;
    800018da:	050a2783          	lw	a5,80(s4)
    800018de:	c8bc                	sw	a5,80(s1)
      to_remove->next = -1;
    800018e0:	57fd                	li	a5,-1
    800018e2:	04fa2823          	sw	a5,80(s4)
      release(&curr_proc->p_lock);
    800018e6:	03848513          	addi	a0,s1,56
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	3ae080e7          	jalr	942(ra) # 80000c98 <release>
      release(&to_remove->p_lock);
    800018f2:	038a0513          	addi	a0,s4,56
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	3a2080e7          	jalr	930(ra) # 80000c98 <release>
      return 1;
    800018fe:	4505                	li	a0,1
    80001900:	b7e1                	j	800018c8 <find_remove+0x78>

0000000080001902 <remove_proc>:

int remove_proc(int *head_list, struct proc *to_remove, struct spinlock *head_lock)
{
    80001902:	7179                	addi	sp,sp,-48
    80001904:	f406                	sd	ra,40(sp)
    80001906:	f022                	sd	s0,32(sp)
    80001908:	ec26                	sd	s1,24(sp)
    8000190a:	e84a                	sd	s2,16(sp)
    8000190c:	e44e                	sd	s3,8(sp)
    8000190e:	e052                	sd	s4,0(sp)
    80001910:	1800                	addi	s0,sp,48
    80001912:	892a                	mv	s2,a0
    80001914:	8a2e                	mv	s4,a1
    80001916:	89b2                	mv	s3,a2
  // printf("%s \n", "im in remove------------------------------------");
  // printf("%d\n", to_remove->proc_idx );

  acquire(head_lock);
    80001918:	8532                	mv	a0,a2
    8000191a:	fffff097          	auipc	ra,0xfffff
    8000191e:	2ca080e7          	jalr	714(ra) # 80000be4 <acquire>
  if (*head_list == -1) // empty list case
    80001922:	00092483          	lw	s1,0(s2)
    80001926:	57fd                	li	a5,-1
    80001928:	06f48463          	beq	s1,a5,80001990 <remove_proc+0x8e>
  {
    release(head_lock); 
    return -1;
  }
  acquire(&proc[*head_list].p_lock);
    8000192c:	18800513          	li	a0,392
    80001930:	02a484b3          	mul	s1,s1,a0
    80001934:	00010517          	auipc	a0,0x10
    80001938:	f1c50513          	addi	a0,a0,-228 # 80011850 <proc+0x38>
    8000193c:	9526                	add	a0,a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	2a6080e7          	jalr	678(ra) # 80000be4 <acquire>
  if (*head_list == to_remove->proc_idx)
    80001946:	00092703          	lw	a4,0(s2)
    8000194a:	054a2783          	lw	a5,84(s4)
    8000194e:	04f70763          	beq	a4,a5,8000199c <remove_proc+0x9a>
    *head_list = to_remove->next;
    release(&to_remove->p_lock);
    release(head_lock);
    return 1;
  }
  release(head_lock);
    80001952:	854e                	mv	a0,s3
    80001954:	fffff097          	auipc	ra,0xfffff
    80001958:	344080e7          	jalr	836(ra) # 80000c98 <release>
  return find_remove(&proc[*head_list], to_remove);
    8000195c:	00092783          	lw	a5,0(s2)
    80001960:	18800513          	li	a0,392
    80001964:	02a787b3          	mul	a5,a5,a0
    80001968:	85d2                	mv	a1,s4
    8000196a:	00010517          	auipc	a0,0x10
    8000196e:	eae50513          	addi	a0,a0,-338 # 80011818 <proc>
    80001972:	953e                	add	a0,a0,a5
    80001974:	00000097          	auipc	ra,0x0
    80001978:	edc080e7          	jalr	-292(ra) # 80001850 <find_remove>
    8000197c:	84aa                	mv	s1,a0
}
    8000197e:	8526                	mv	a0,s1
    80001980:	70a2                	ld	ra,40(sp)
    80001982:	7402                	ld	s0,32(sp)
    80001984:	64e2                	ld	s1,24(sp)
    80001986:	6942                	ld	s2,16(sp)
    80001988:	69a2                	ld	s3,8(sp)
    8000198a:	6a02                	ld	s4,0(sp)
    8000198c:	6145                	addi	sp,sp,48
    8000198e:	8082                	ret
    release(head_lock); 
    80001990:	854e                	mv	a0,s3
    80001992:	fffff097          	auipc	ra,0xfffff
    80001996:	306080e7          	jalr	774(ra) # 80000c98 <release>
    return -1;
    8000199a:	b7d5                	j	8000197e <remove_proc+0x7c>
    *head_list = to_remove->next;
    8000199c:	050a2783          	lw	a5,80(s4)
    800019a0:	00f92023          	sw	a5,0(s2)
    release(&to_remove->p_lock);
    800019a4:	038a0513          	addi	a0,s4,56
    800019a8:	fffff097          	auipc	ra,0xfffff
    800019ac:	2f0080e7          	jalr	752(ra) # 80000c98 <release>
    release(head_lock);
    800019b0:	854e                	mv	a0,s3
    800019b2:	fffff097          	auipc	ra,0xfffff
    800019b6:	2e6080e7          	jalr	742(ra) # 80000c98 <release>
    return 1;
    800019ba:	4485                	li	s1,1
    800019bc:	b7c9                	j	8000197e <remove_proc+0x7c>

00000000800019be <add_not_first>:

void add_not_first(struct proc *curr, struct proc *to_add){
    800019be:	7139                	addi	sp,sp,-64
    800019c0:	fc06                	sd	ra,56(sp)
    800019c2:	f822                	sd	s0,48(sp)
    800019c4:	f426                	sd	s1,40(sp)
    800019c6:	f04a                	sd	s2,32(sp)
    800019c8:	ec4e                	sd	s3,24(sp)
    800019ca:	e852                	sd	s4,16(sp)
    800019cc:	e456                	sd	s5,8(sp)
    800019ce:	0080                	addi	s0,sp,64
    800019d0:	84aa                	mv	s1,a0
    800019d2:	8aae                	mv	s5,a1
  while(curr->next != -1)
    800019d4:	4938                	lw	a4,80(a0)
    800019d6:	57fd                	li	a5,-1
    800019d8:	02f70e63          	beq	a4,a5,80001a14 <add_not_first+0x56>
    800019dc:	18800a13          	li	s4,392
    {
      release(&curr->p_lock);
      curr = &proc[curr->next];
    800019e0:	00010917          	auipc	s2,0x10
    800019e4:	e3890913          	addi	s2,s2,-456 # 80011818 <proc>
  while(curr->next != -1)
    800019e8:	59fd                	li	s3,-1
      release(&curr->p_lock);
    800019ea:	03848513          	addi	a0,s1,56
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	2aa080e7          	jalr	682(ra) # 80000c98 <release>
      curr = &proc[curr->next];
    800019f6:	48a8                	lw	a0,80(s1)
    800019f8:	03450533          	mul	a0,a0,s4
    800019fc:	012504b3          	add	s1,a0,s2
      acquire(&curr->p_lock);
    80001a00:	03850513          	addi	a0,a0,56
    80001a04:	954a                	add	a0,a0,s2
    80001a06:	fffff097          	auipc	ra,0xfffff
    80001a0a:	1de080e7          	jalr	478(ra) # 80000be4 <acquire>
  while(curr->next != -1)
    80001a0e:	48bc                	lw	a5,80(s1)
    80001a10:	fd379de3          	bne	a5,s3,800019ea <add_not_first+0x2c>
    }
    curr->next = to_add->proc_idx;
    80001a14:	054aa783          	lw	a5,84(s5) # fffffffffffff054 <end+0xffffffff7ffd9054>
    80001a18:	c8bc                	sw	a5,80(s1)
    release(&curr->p_lock);
    80001a1a:	03848513          	addi	a0,s1,56
    80001a1e:	fffff097          	auipc	ra,0xfffff
    80001a22:	27a080e7          	jalr	634(ra) # 80000c98 <release>
}
    80001a26:	70e2                	ld	ra,56(sp)
    80001a28:	7442                	ld	s0,48(sp)
    80001a2a:	74a2                	ld	s1,40(sp)
    80001a2c:	7902                	ld	s2,32(sp)
    80001a2e:	69e2                	ld	s3,24(sp)
    80001a30:	6a42                	ld	s4,16(sp)
    80001a32:	6aa2                	ld	s5,8(sp)
    80001a34:	6121                	addi	sp,sp,64
    80001a36:	8082                	ret

0000000080001a38 <add_proc>:

void add_proc(int *head, struct proc *to_add, struct spinlock *head_lock)
{
    80001a38:	7139                	addi	sp,sp,-64
    80001a3a:	fc06                	sd	ra,56(sp)
    80001a3c:	f822                	sd	s0,48(sp)
    80001a3e:	f426                	sd	s1,40(sp)
    80001a40:	f04a                	sd	s2,32(sp)
    80001a42:	ec4e                	sd	s3,24(sp)
    80001a44:	e852                	sd	s4,16(sp)
    80001a46:	e456                	sd	s5,8(sp)
    80001a48:	0080                	addi	s0,sp,64
    80001a4a:	84aa                	mv	s1,a0
    80001a4c:	89ae                	mv	s3,a1
    80001a4e:	8932                	mv	s2,a2
  acquire(head_lock);
    80001a50:	8532                	mv	a0,a2
    80001a52:	fffff097          	auipc	ra,0xfffff
    80001a56:	192080e7          	jalr	402(ra) # 80000be4 <acquire>
  if (*head == -1)
    80001a5a:	409c                	lw	a5,0(s1)
    80001a5c:	577d                	li	a4,-1
    80001a5e:	04e78963          	beq	a5,a4,80001ab0 <add_proc+0x78>
    proc[*head].next = -1;
    release(head_lock);
  }
  else
  {
    acquire(&proc[*head].p_lock);
    80001a62:	18800a93          	li	s5,392
    80001a66:	035787b3          	mul	a5,a5,s5
    80001a6a:	03878793          	addi	a5,a5,56
    80001a6e:	00010a17          	auipc	s4,0x10
    80001a72:	daaa0a13          	addi	s4,s4,-598 # 80011818 <proc>
    80001a76:	00fa0533          	add	a0,s4,a5
    80001a7a:	fffff097          	auipc	ra,0xfffff
    80001a7e:	16a080e7          	jalr	362(ra) # 80000be4 <acquire>
    release(head_lock);
    80001a82:	854a                	mv	a0,s2
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	214080e7          	jalr	532(ra) # 80000c98 <release>
    add_not_first(&proc[*head], to_add);  
    80001a8c:	4088                	lw	a0,0(s1)
    80001a8e:	03550533          	mul	a0,a0,s5
    80001a92:	85ce                	mv	a1,s3
    80001a94:	9552                	add	a0,a0,s4
    80001a96:	00000097          	auipc	ra,0x0
    80001a9a:	f28080e7          	jalr	-216(ra) # 800019be <add_not_first>
  }
}
    80001a9e:	70e2                	ld	ra,56(sp)
    80001aa0:	7442                	ld	s0,48(sp)
    80001aa2:	74a2                	ld	s1,40(sp)
    80001aa4:	7902                	ld	s2,32(sp)
    80001aa6:	69e2                	ld	s3,24(sp)
    80001aa8:	6a42                	ld	s4,16(sp)
    80001aaa:	6aa2                	ld	s5,8(sp)
    80001aac:	6121                	addi	sp,sp,64
    80001aae:	8082                	ret
    *head = to_add->proc_idx;
    80001ab0:	0549a783          	lw	a5,84(s3) # 1054 <_entry-0x7fffefac>
    80001ab4:	c09c                	sw	a5,0(s1)
    proc[*head].next = -1;
    80001ab6:	18800713          	li	a4,392
    80001aba:	02e787b3          	mul	a5,a5,a4
    80001abe:	00010717          	auipc	a4,0x10
    80001ac2:	d5a70713          	addi	a4,a4,-678 # 80011818 <proc>
    80001ac6:	97ba                	add	a5,a5,a4
    80001ac8:	577d                	li	a4,-1
    80001aca:	cbb8                	sw	a4,80(a5)
    release(head_lock);
    80001acc:	854a                	mv	a0,s2
    80001ace:	fffff097          	auipc	ra,0xfffff
    80001ad2:	1ca080e7          	jalr	458(ra) # 80000c98 <release>
    80001ad6:	b7e1                	j	80001a9e <add_proc+0x66>

0000000080001ad8 <init_locks>:


void init_locks()
{
    80001ad8:	7179                	addi	sp,sp,-48
    80001ada:	f406                	sd	ra,40(sp)
    80001adc:	f022                	sd	s0,32(sp)
    80001ade:	ec26                	sd	s1,24(sp)
    80001ae0:	e84a                	sd	s2,16(sp)
    80001ae2:	e44e                	sd	s3,8(sp)
    80001ae4:	e052                	sd	s4,0(sp)
    80001ae6:	1800                	addi	s0,sp,48
  struct cpu *c;
  initlock(&zombie_lock, "zombie");
    80001ae8:	00006597          	auipc	a1,0x6
    80001aec:	6f858593          	addi	a1,a1,1784 # 800081e0 <digits+0x1a0>
    80001af0:	0000f517          	auipc	a0,0xf
    80001af4:	7b050513          	addi	a0,a0,1968 # 800112a0 <zombie_lock>
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	05c080e7          	jalr	92(ra) # 80000b54 <initlock>
  initlock(&unused_lock, "unused");
    80001b00:	00006597          	auipc	a1,0x6
    80001b04:	6e858593          	addi	a1,a1,1768 # 800081e8 <digits+0x1a8>
    80001b08:	0000f517          	auipc	a0,0xf
    80001b0c:	7b050513          	addi	a0,a0,1968 # 800112b8 <unused_lock>
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	044080e7          	jalr	68(ra) # 80000b54 <initlock>
  initlock(&sleeping_lock, "sleeping");
    80001b18:	00006597          	auipc	a1,0x6
    80001b1c:	6d858593          	addi	a1,a1,1752 # 800081f0 <digits+0x1b0>
    80001b20:	0000f517          	auipc	a0,0xf
    80001b24:	7b050513          	addi	a0,a0,1968 # 800112d0 <sleeping_lock>
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	02c080e7          	jalr	44(ra) # 80000b54 <initlock>
  for (c = cpus; c < &cpus[NCPU]; c++)
    80001b30:	00010497          	auipc	s1,0x10
    80001b34:	84048493          	addi	s1,s1,-1984 # 80011370 <cpus+0x88>
    80001b38:	00010a17          	auipc	s4,0x10
    80001b3c:	d38a0a13          	addi	s4,s4,-712 # 80011870 <proc+0x58>
  {
    c->runnable_head = -1;
    80001b40:	59fd                	li	s3,-1
    initlock(&c->head_lock, "runnable");
    80001b42:	00006917          	auipc	s2,0x6
    80001b46:	6be90913          	addi	s2,s2,1726 # 80008200 <digits+0x1c0>
    c->runnable_head = -1;
    80001b4a:	ff34ac23          	sw	s3,-8(s1)
    initlock(&c->head_lock, "runnable");
    80001b4e:	85ca                	mv	a1,s2
    80001b50:	8526                	mv	a0,s1
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	002080e7          	jalr	2(ra) # 80000b54 <initlock>
  for (c = cpus; c < &cpus[NCPU]; c++)
    80001b5a:	0a048493          	addi	s1,s1,160
    80001b5e:	ff4496e3          	bne	s1,s4,80001b4a <init_locks+0x72>
  }
}
    80001b62:	70a2                	ld	ra,40(sp)
    80001b64:	7402                	ld	s0,32(sp)
    80001b66:	64e2                	ld	s1,24(sp)
    80001b68:	6942                	ld	s2,16(sp)
    80001b6a:	69a2                	ld	s3,8(sp)
    80001b6c:	6a02                	ld	s4,0(sp)
    80001b6e:	6145                	addi	sp,sp,48
    80001b70:	8082                	ret

0000000080001b72 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001b72:	7139                	addi	sp,sp,-64
    80001b74:	fc06                	sd	ra,56(sp)
    80001b76:	f822                	sd	s0,48(sp)
    80001b78:	f426                	sd	s1,40(sp)
    80001b7a:	f04a                	sd	s2,32(sp)
    80001b7c:	ec4e                	sd	s3,24(sp)
    80001b7e:	e852                	sd	s4,16(sp)
    80001b80:	e456                	sd	s5,8(sp)
    80001b82:	e05a                	sd	s6,0(sp)
    80001b84:	0080                	addi	s0,sp,64
    80001b86:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001b88:	00010497          	auipc	s1,0x10
    80001b8c:	c9048493          	addi	s1,s1,-880 # 80011818 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001b90:	8b26                	mv	s6,s1
    80001b92:	00006a97          	auipc	s5,0x6
    80001b96:	46ea8a93          	addi	s5,s5,1134 # 80008000 <etext>
    80001b9a:	04000937          	lui	s2,0x4000
    80001b9e:	197d                	addi	s2,s2,-1
    80001ba0:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001ba2:	00016a17          	auipc	s4,0x16
    80001ba6:	e76a0a13          	addi	s4,s4,-394 # 80017a18 <tickslock>
    char *pa = kalloc();
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	f4a080e7          	jalr	-182(ra) # 80000af4 <kalloc>
    80001bb2:	862a                	mv	a2,a0
    if (pa == 0)
    80001bb4:	c131                	beqz	a0,80001bf8 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001bb6:	416485b3          	sub	a1,s1,s6
    80001bba:	858d                	srai	a1,a1,0x3
    80001bbc:	000ab783          	ld	a5,0(s5)
    80001bc0:	02f585b3          	mul	a1,a1,a5
    80001bc4:	2585                	addiw	a1,a1,1
    80001bc6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001bca:	4719                	li	a4,6
    80001bcc:	6685                	lui	a3,0x1
    80001bce:	40b905b3          	sub	a1,s2,a1
    80001bd2:	854e                	mv	a0,s3
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	58e080e7          	jalr	1422(ra) # 80001162 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bdc:	18848493          	addi	s1,s1,392
    80001be0:	fd4495e3          	bne	s1,s4,80001baa <proc_mapstacks+0x38>
  }
}
    80001be4:	70e2                	ld	ra,56(sp)
    80001be6:	7442                	ld	s0,48(sp)
    80001be8:	74a2                	ld	s1,40(sp)
    80001bea:	7902                	ld	s2,32(sp)
    80001bec:	69e2                	ld	s3,24(sp)
    80001bee:	6a42                	ld	s4,16(sp)
    80001bf0:	6aa2                	ld	s5,8(sp)
    80001bf2:	6b02                	ld	s6,0(sp)
    80001bf4:	6121                	addi	sp,sp,64
    80001bf6:	8082                	ret
      panic("kalloc");
    80001bf8:	00006517          	auipc	a0,0x6
    80001bfc:	61850513          	addi	a0,a0,1560 # 80008210 <digits+0x1d0>
    80001c00:	fffff097          	auipc	ra,0xfffff
    80001c04:	93e080e7          	jalr	-1730(ra) # 8000053e <panic>

0000000080001c08 <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    80001c08:	711d                	addi	sp,sp,-96
    80001c0a:	ec86                	sd	ra,88(sp)
    80001c0c:	e8a2                	sd	s0,80(sp)
    80001c0e:	e4a6                	sd	s1,72(sp)
    80001c10:	e0ca                	sd	s2,64(sp)
    80001c12:	fc4e                	sd	s3,56(sp)
    80001c14:	f852                	sd	s4,48(sp)
    80001c16:	f456                	sd	s5,40(sp)
    80001c18:	f05a                	sd	s6,32(sp)
    80001c1a:	ec5e                	sd	s7,24(sp)
    80001c1c:	e862                	sd	s8,16(sp)
    80001c1e:	e466                	sd	s9,8(sp)
    80001c20:	e06a                	sd	s10,0(sp)
    80001c22:	1080                	addi	s0,sp,96
  init_locks();
    80001c24:	00000097          	auipc	ra,0x0
    80001c28:	eb4080e7          	jalr	-332(ra) # 80001ad8 <init_locks>
  int i = 0;
  struct proc *p;
  initlock(&pid_lock, "nextpid");
    80001c2c:	00006597          	auipc	a1,0x6
    80001c30:	5ec58593          	addi	a1,a1,1516 # 80008218 <digits+0x1d8>
    80001c34:	00010517          	auipc	a0,0x10
    80001c38:	bb450513          	addi	a0,a0,-1100 # 800117e8 <pid_lock>
    80001c3c:	fffff097          	auipc	ra,0xfffff
    80001c40:	f18080e7          	jalr	-232(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001c44:	00006597          	auipc	a1,0x6
    80001c48:	5dc58593          	addi	a1,a1,1500 # 80008220 <digits+0x1e0>
    80001c4c:	00010517          	auipc	a0,0x10
    80001c50:	bb450513          	addi	a0,a0,-1100 # 80011800 <wait_lock>
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	f00080e7          	jalr	-256(ra) # 80000b54 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c5c:	00010497          	auipc	s1,0x10
    80001c60:	bbc48493          	addi	s1,s1,-1092 # 80011818 <proc>
  int i = 0;
    80001c64:	4901                	li	s2,0
  {
    initlock(&p->lock, "proc");
    80001c66:	00006d17          	auipc	s10,0x6
    80001c6a:	5cad0d13          	addi	s10,s10,1482 # 80008230 <digits+0x1f0>
    initlock(&p->p_lock, "p_lock");
    80001c6e:	00006c97          	auipc	s9,0x6
    80001c72:	5cac8c93          	addi	s9,s9,1482 # 80008238 <digits+0x1f8>

    p->kstack = KSTACK((int)(p - proc));
    80001c76:	8c26                	mv	s8,s1
    80001c78:	00006b97          	auipc	s7,0x6
    80001c7c:	388b8b93          	addi	s7,s7,904 # 80008000 <etext>
    80001c80:	040009b7          	lui	s3,0x4000
    80001c84:	19fd                	addi	s3,s3,-1
    80001c86:	09b2                	slli	s3,s3,0xc
    p->proc_idx = i;
    p->next = -1;
    80001c88:	5b7d                	li	s6,-1
    add_proc(&unused_head, p, &unused_lock);
    80001c8a:	0000fa97          	auipc	s5,0xf
    80001c8e:	62ea8a93          	addi	s5,s5,1582 # 800112b8 <unused_lock>
    80001c92:	00007a17          	auipc	s4,0x7
    80001c96:	bf2a0a13          	addi	s4,s4,-1038 # 80008884 <unused_head>
    initlock(&p->lock, "proc");
    80001c9a:	85ea                	mv	a1,s10
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	fffff097          	auipc	ra,0xfffff
    80001ca2:	eb6080e7          	jalr	-330(ra) # 80000b54 <initlock>
    initlock(&p->p_lock, "p_lock");
    80001ca6:	85e6                	mv	a1,s9
    80001ca8:	03848513          	addi	a0,s1,56
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	ea8080e7          	jalr	-344(ra) # 80000b54 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    80001cb4:	418487b3          	sub	a5,s1,s8
    80001cb8:	878d                	srai	a5,a5,0x3
    80001cba:	000bb703          	ld	a4,0(s7)
    80001cbe:	02e787b3          	mul	a5,a5,a4
    80001cc2:	2785                	addiw	a5,a5,1
    80001cc4:	00d7979b          	slliw	a5,a5,0xd
    80001cc8:	40f987b3          	sub	a5,s3,a5
    80001ccc:	f0bc                	sd	a5,96(s1)
    p->proc_idx = i;
    80001cce:	0524aa23          	sw	s2,84(s1)
    p->next = -1;
    80001cd2:	0564a823          	sw	s6,80(s1)
    add_proc(&unused_head, p, &unused_lock);
    80001cd6:	8656                	mv	a2,s5
    80001cd8:	85a6                	mv	a1,s1
    80001cda:	8552                	mv	a0,s4
    80001cdc:	00000097          	auipc	ra,0x0
    80001ce0:	d5c080e7          	jalr	-676(ra) # 80001a38 <add_proc>
    // printf("%d\n", p->proc_idx );
    i++;
    80001ce4:	2905                	addiw	s2,s2,1
  for (p = proc; p < &proc[NPROC]; p++)
    80001ce6:	18848493          	addi	s1,s1,392
    80001cea:	04000793          	li	a5,64
    80001cee:	faf916e3          	bne	s2,a5,80001c9a <procinit+0x92>
  // {
  //   remove_proc(&unused_head, p, &unused_lock);
  //   printf("%d\n", p->proc_idx );
  // }
  // printf("%d\n", proc[unused_head].next);
}
    80001cf2:	60e6                	ld	ra,88(sp)
    80001cf4:	6446                	ld	s0,80(sp)
    80001cf6:	64a6                	ld	s1,72(sp)
    80001cf8:	6906                	ld	s2,64(sp)
    80001cfa:	79e2                	ld	s3,56(sp)
    80001cfc:	7a42                	ld	s4,48(sp)
    80001cfe:	7aa2                	ld	s5,40(sp)
    80001d00:	7b02                	ld	s6,32(sp)
    80001d02:	6be2                	ld	s7,24(sp)
    80001d04:	6c42                	ld	s8,16(sp)
    80001d06:	6ca2                	ld	s9,8(sp)
    80001d08:	6d02                	ld	s10,0(sp)
    80001d0a:	6125                	addi	sp,sp,96
    80001d0c:	8082                	ret

0000000080001d0e <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001d0e:	1141                	addi	sp,sp,-16
    80001d10:	e422                	sd	s0,8(sp)
    80001d12:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d14:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001d16:	2501                	sext.w	a0,a0
    80001d18:	6422                	ld	s0,8(sp)
    80001d1a:	0141                	addi	sp,sp,16
    80001d1c:	8082                	ret

0000000080001d1e <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001d1e:	1141                	addi	sp,sp,-16
    80001d20:	e422                	sd	s0,8(sp)
    80001d22:	0800                	addi	s0,sp,16
    80001d24:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001d26:	0007851b          	sext.w	a0,a5
    80001d2a:	00251793          	slli	a5,a0,0x2
    80001d2e:	97aa                	add	a5,a5,a0
    80001d30:	0796                	slli	a5,a5,0x5
  return c;
}
    80001d32:	0000f517          	auipc	a0,0xf
    80001d36:	5b650513          	addi	a0,a0,1462 # 800112e8 <cpus>
    80001d3a:	953e                	add	a0,a0,a5
    80001d3c:	6422                	ld	s0,8(sp)
    80001d3e:	0141                	addi	sp,sp,16
    80001d40:	8082                	ret

0000000080001d42 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001d42:	1101                	addi	sp,sp,-32
    80001d44:	ec06                	sd	ra,24(sp)
    80001d46:	e822                	sd	s0,16(sp)
    80001d48:	e426                	sd	s1,8(sp)
    80001d4a:	1000                	addi	s0,sp,32
  push_off();
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	e4c080e7          	jalr	-436(ra) # 80000b98 <push_off>
    80001d54:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001d56:	0007871b          	sext.w	a4,a5
    80001d5a:	00271793          	slli	a5,a4,0x2
    80001d5e:	97ba                	add	a5,a5,a4
    80001d60:	0796                	slli	a5,a5,0x5
    80001d62:	0000f717          	auipc	a4,0xf
    80001d66:	53e70713          	addi	a4,a4,1342 # 800112a0 <zombie_lock>
    80001d6a:	97ba                	add	a5,a5,a4
    80001d6c:	67a4                	ld	s1,72(a5)
  pop_off();
    80001d6e:	fffff097          	auipc	ra,0xfffff
    80001d72:	eca080e7          	jalr	-310(ra) # 80000c38 <pop_off>
  return p;
}
    80001d76:	8526                	mv	a0,s1
    80001d78:	60e2                	ld	ra,24(sp)
    80001d7a:	6442                	ld	s0,16(sp)
    80001d7c:	64a2                	ld	s1,8(sp)
    80001d7e:	6105                	addi	sp,sp,32
    80001d80:	8082                	ret

0000000080001d82 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001d82:	1141                	addi	sp,sp,-16
    80001d84:	e406                	sd	ra,8(sp)
    80001d86:	e022                	sd	s0,0(sp)
    80001d88:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001d8a:	00000097          	auipc	ra,0x0
    80001d8e:	fb8080e7          	jalr	-72(ra) # 80001d42 <myproc>
    80001d92:	fffff097          	auipc	ra,0xfffff
    80001d96:	f06080e7          	jalr	-250(ra) # 80000c98 <release>

  if (first)
    80001d9a:	00007797          	auipc	a5,0x7
    80001d9e:	ae67a783          	lw	a5,-1306(a5) # 80008880 <first.1719>
    80001da2:	eb89                	bnez	a5,80001db4 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001da4:	00001097          	auipc	ra,0x1
    80001da8:	f7c080e7          	jalr	-132(ra) # 80002d20 <usertrapret>
}
    80001dac:	60a2                	ld	ra,8(sp)
    80001dae:	6402                	ld	s0,0(sp)
    80001db0:	0141                	addi	sp,sp,16
    80001db2:	8082                	ret
    first = 0;
    80001db4:	00007797          	auipc	a5,0x7
    80001db8:	ac07a623          	sw	zero,-1332(a5) # 80008880 <first.1719>
    fsinit(ROOTDEV);
    80001dbc:	4505                	li	a0,1
    80001dbe:	00002097          	auipc	ra,0x2
    80001dc2:	cee080e7          	jalr	-786(ra) # 80003aac <fsinit>
    80001dc6:	bff9                	j	80001da4 <forkret+0x22>

0000000080001dc8 <allocpid>:
{
    80001dc8:	1101                	addi	sp,sp,-32
    80001dca:	ec06                	sd	ra,24(sp)
    80001dcc:	e822                	sd	s0,16(sp)
    80001dce:	e426                	sd	s1,8(sp)
    80001dd0:	e04a                	sd	s2,0(sp)
    80001dd2:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001dd4:	00007917          	auipc	s2,0x7
    80001dd8:	abc90913          	addi	s2,s2,-1348 # 80008890 <nextpid>
    80001ddc:	00092483          	lw	s1,0(s2)
  } while (cas(&nextpid, pid, pid + 1));
    80001de0:	0014861b          	addiw	a2,s1,1
    80001de4:	85a6                	mv	a1,s1
    80001de6:	854a                	mv	a0,s2
    80001de8:	00005097          	auipc	ra,0x5
    80001dec:	ace080e7          	jalr	-1330(ra) # 800068b6 <cas>
    80001df0:	f575                	bnez	a0,80001ddc <allocpid+0x14>
}
    80001df2:	8526                	mv	a0,s1
    80001df4:	60e2                	ld	ra,24(sp)
    80001df6:	6442                	ld	s0,16(sp)
    80001df8:	64a2                	ld	s1,8(sp)
    80001dfa:	6902                	ld	s2,0(sp)
    80001dfc:	6105                	addi	sp,sp,32
    80001dfe:	8082                	ret

0000000080001e00 <proc_pagetable>:
{
    80001e00:	1101                	addi	sp,sp,-32
    80001e02:	ec06                	sd	ra,24(sp)
    80001e04:	e822                	sd	s0,16(sp)
    80001e06:	e426                	sd	s1,8(sp)
    80001e08:	e04a                	sd	s2,0(sp)
    80001e0a:	1000                	addi	s0,sp,32
    80001e0c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	53e080e7          	jalr	1342(ra) # 8000134c <uvmcreate>
    80001e16:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001e18:	c121                	beqz	a0,80001e58 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e1a:	4729                	li	a4,10
    80001e1c:	00005697          	auipc	a3,0x5
    80001e20:	1e468693          	addi	a3,a3,484 # 80007000 <_trampoline>
    80001e24:	6605                	lui	a2,0x1
    80001e26:	040005b7          	lui	a1,0x4000
    80001e2a:	15fd                	addi	a1,a1,-1
    80001e2c:	05b2                	slli	a1,a1,0xc
    80001e2e:	fffff097          	auipc	ra,0xfffff
    80001e32:	294080e7          	jalr	660(ra) # 800010c2 <mappages>
    80001e36:	02054863          	bltz	a0,80001e66 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e3a:	4719                	li	a4,6
    80001e3c:	07893683          	ld	a3,120(s2)
    80001e40:	6605                	lui	a2,0x1
    80001e42:	020005b7          	lui	a1,0x2000
    80001e46:	15fd                	addi	a1,a1,-1
    80001e48:	05b6                	slli	a1,a1,0xd
    80001e4a:	8526                	mv	a0,s1
    80001e4c:	fffff097          	auipc	ra,0xfffff
    80001e50:	276080e7          	jalr	630(ra) # 800010c2 <mappages>
    80001e54:	02054163          	bltz	a0,80001e76 <proc_pagetable+0x76>
}
    80001e58:	8526                	mv	a0,s1
    80001e5a:	60e2                	ld	ra,24(sp)
    80001e5c:	6442                	ld	s0,16(sp)
    80001e5e:	64a2                	ld	s1,8(sp)
    80001e60:	6902                	ld	s2,0(sp)
    80001e62:	6105                	addi	sp,sp,32
    80001e64:	8082                	ret
    uvmfree(pagetable, 0);
    80001e66:	4581                	li	a1,0
    80001e68:	8526                	mv	a0,s1
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	6de080e7          	jalr	1758(ra) # 80001548 <uvmfree>
    return 0;
    80001e72:	4481                	li	s1,0
    80001e74:	b7d5                	j	80001e58 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e76:	4681                	li	a3,0
    80001e78:	4605                	li	a2,1
    80001e7a:	040005b7          	lui	a1,0x4000
    80001e7e:	15fd                	addi	a1,a1,-1
    80001e80:	05b2                	slli	a1,a1,0xc
    80001e82:	8526                	mv	a0,s1
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	404080e7          	jalr	1028(ra) # 80001288 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e8c:	4581                	li	a1,0
    80001e8e:	8526                	mv	a0,s1
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	6b8080e7          	jalr	1720(ra) # 80001548 <uvmfree>
    return 0;
    80001e98:	4481                	li	s1,0
    80001e9a:	bf7d                	j	80001e58 <proc_pagetable+0x58>

0000000080001e9c <proc_freepagetable>:
{
    80001e9c:	1101                	addi	sp,sp,-32
    80001e9e:	ec06                	sd	ra,24(sp)
    80001ea0:	e822                	sd	s0,16(sp)
    80001ea2:	e426                	sd	s1,8(sp)
    80001ea4:	e04a                	sd	s2,0(sp)
    80001ea6:	1000                	addi	s0,sp,32
    80001ea8:	84aa                	mv	s1,a0
    80001eaa:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001eac:	4681                	li	a3,0
    80001eae:	4605                	li	a2,1
    80001eb0:	040005b7          	lui	a1,0x4000
    80001eb4:	15fd                	addi	a1,a1,-1
    80001eb6:	05b2                	slli	a1,a1,0xc
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	3d0080e7          	jalr	976(ra) # 80001288 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ec0:	4681                	li	a3,0
    80001ec2:	4605                	li	a2,1
    80001ec4:	020005b7          	lui	a1,0x2000
    80001ec8:	15fd                	addi	a1,a1,-1
    80001eca:	05b6                	slli	a1,a1,0xd
    80001ecc:	8526                	mv	a0,s1
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	3ba080e7          	jalr	954(ra) # 80001288 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ed6:	85ca                	mv	a1,s2
    80001ed8:	8526                	mv	a0,s1
    80001eda:	fffff097          	auipc	ra,0xfffff
    80001ede:	66e080e7          	jalr	1646(ra) # 80001548 <uvmfree>
}
    80001ee2:	60e2                	ld	ra,24(sp)
    80001ee4:	6442                	ld	s0,16(sp)
    80001ee6:	64a2                	ld	s1,8(sp)
    80001ee8:	6902                	ld	s2,0(sp)
    80001eea:	6105                	addi	sp,sp,32
    80001eec:	8082                	ret

0000000080001eee <freeproc>:
{
    80001eee:	1101                	addi	sp,sp,-32
    80001ef0:	ec06                	sd	ra,24(sp)
    80001ef2:	e822                	sd	s0,16(sp)
    80001ef4:	e426                	sd	s1,8(sp)
    80001ef6:	1000                	addi	s0,sp,32
    80001ef8:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001efa:	7d28                	ld	a0,120(a0)
    80001efc:	c509                	beqz	a0,80001f06 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	afa080e7          	jalr	-1286(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001f06:	0604bc23          	sd	zero,120(s1)
  if (p->pagetable)
    80001f0a:	78a8                	ld	a0,112(s1)
    80001f0c:	c511                	beqz	a0,80001f18 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001f0e:	74ac                	ld	a1,104(s1)
    80001f10:	00000097          	auipc	ra,0x0
    80001f14:	f8c080e7          	jalr	-116(ra) # 80001e9c <proc_freepagetable>
  p->pagetable = 0;
    80001f18:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80001f1c:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80001f20:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001f24:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80001f28:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80001f2c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001f30:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001f34:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001f38:	0004ac23          	sw	zero,24(s1)
  remove_proc(&zombie_head, p, &zombie_lock);
    80001f3c:	0000f617          	auipc	a2,0xf
    80001f40:	36460613          	addi	a2,a2,868 # 800112a0 <zombie_lock>
    80001f44:	85a6                	mv	a1,s1
    80001f46:	00007517          	auipc	a0,0x7
    80001f4a:	94650513          	addi	a0,a0,-1722 # 8000888c <zombie_head>
    80001f4e:	00000097          	auipc	ra,0x0
    80001f52:	9b4080e7          	jalr	-1612(ra) # 80001902 <remove_proc>
  add_proc(&unused_head, p, &unused_lock);
    80001f56:	0000f617          	auipc	a2,0xf
    80001f5a:	36260613          	addi	a2,a2,866 # 800112b8 <unused_lock>
    80001f5e:	85a6                	mv	a1,s1
    80001f60:	00007517          	auipc	a0,0x7
    80001f64:	92450513          	addi	a0,a0,-1756 # 80008884 <unused_head>
    80001f68:	00000097          	auipc	ra,0x0
    80001f6c:	ad0080e7          	jalr	-1328(ra) # 80001a38 <add_proc>
}
    80001f70:	60e2                	ld	ra,24(sp)
    80001f72:	6442                	ld	s0,16(sp)
    80001f74:	64a2                	ld	s1,8(sp)
    80001f76:	6105                	addi	sp,sp,32
    80001f78:	8082                	ret

0000000080001f7a <allocproc>:
{
    80001f7a:	7179                	addi	sp,sp,-48
    80001f7c:	f406                	sd	ra,40(sp)
    80001f7e:	f022                	sd	s0,32(sp)
    80001f80:	ec26                	sd	s1,24(sp)
    80001f82:	e84a                	sd	s2,16(sp)
    80001f84:	e44e                	sd	s3,8(sp)
    80001f86:	e052                	sd	s4,0(sp)
    80001f88:	1800                	addi	s0,sp,48
  if (unused_head != -1)
    80001f8a:	00007917          	auipc	s2,0x7
    80001f8e:	8fa92903          	lw	s2,-1798(s2) # 80008884 <unused_head>
    80001f92:	57fd                	li	a5,-1
  return 0;
    80001f94:	4481                	li	s1,0
  if (unused_head != -1)
    80001f96:	0af90b63          	beq	s2,a5,8000204c <allocproc+0xd2>
    p = &proc[unused_head];
    80001f9a:	18800993          	li	s3,392
    80001f9e:	033909b3          	mul	s3,s2,s3
    80001fa2:	00010497          	auipc	s1,0x10
    80001fa6:	87648493          	addi	s1,s1,-1930 # 80011818 <proc>
    80001faa:	94ce                	add	s1,s1,s3
    acquire(&p->lock);
    80001fac:	8526                	mv	a0,s1
    80001fae:	fffff097          	auipc	ra,0xfffff
    80001fb2:	c36080e7          	jalr	-970(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	e12080e7          	jalr	-494(ra) # 80001dc8 <allocpid>
    80001fbe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001fc0:	4785                	li	a5,1
    80001fc2:	cc9c                	sw	a5,24(s1)
  remove_proc(&unused_head, p, &unused_lock); 
    80001fc4:	0000f617          	auipc	a2,0xf
    80001fc8:	2f460613          	addi	a2,a2,756 # 800112b8 <unused_lock>
    80001fcc:	85a6                	mv	a1,s1
    80001fce:	00007517          	auipc	a0,0x7
    80001fd2:	8b650513          	addi	a0,a0,-1866 # 80008884 <unused_head>
    80001fd6:	00000097          	auipc	ra,0x0
    80001fda:	92c080e7          	jalr	-1748(ra) # 80001902 <remove_proc>
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	b16080e7          	jalr	-1258(ra) # 80000af4 <kalloc>
    80001fe6:	8a2a                	mv	s4,a0
    80001fe8:	fca8                	sd	a0,120(s1)
    80001fea:	c935                	beqz	a0,8000205e <allocproc+0xe4>
  p->pagetable = proc_pagetable(p);
    80001fec:	8526                	mv	a0,s1
    80001fee:	00000097          	auipc	ra,0x0
    80001ff2:	e12080e7          	jalr	-494(ra) # 80001e00 <proc_pagetable>
    80001ff6:	8a2a                	mv	s4,a0
    80001ff8:	18800793          	li	a5,392
    80001ffc:	02f90733          	mul	a4,s2,a5
    80002000:	00010797          	auipc	a5,0x10
    80002004:	81878793          	addi	a5,a5,-2024 # 80011818 <proc>
    80002008:	97ba                	add	a5,a5,a4
    8000200a:	fba8                	sd	a0,112(a5)
  if (p->pagetable == 0)
    8000200c:	c52d                	beqz	a0,80002076 <allocproc+0xfc>
  memset(&p->context, 0, sizeof(p->context));
    8000200e:	08098513          	addi	a0,s3,128 # 4000080 <_entry-0x7bffff80>
    80002012:	00010a17          	auipc	s4,0x10
    80002016:	806a0a13          	addi	s4,s4,-2042 # 80011818 <proc>
    8000201a:	07000613          	li	a2,112
    8000201e:	4581                	li	a1,0
    80002020:	9552                	add	a0,a0,s4
    80002022:	fffff097          	auipc	ra,0xfffff
    80002026:	cd0080e7          	jalr	-816(ra) # 80000cf2 <memset>
  p->context.ra = (uint64)forkret;
    8000202a:	18800793          	li	a5,392
    8000202e:	02f90933          	mul	s2,s2,a5
    80002032:	9952                	add	s2,s2,s4
    80002034:	00000797          	auipc	a5,0x0
    80002038:	d4e78793          	addi	a5,a5,-690 # 80001d82 <forkret>
    8000203c:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002040:	06093783          	ld	a5,96(s2)
    80002044:	6705                	lui	a4,0x1
    80002046:	97ba                	add	a5,a5,a4
    80002048:	08f93423          	sd	a5,136(s2)
}
    8000204c:	8526                	mv	a0,s1
    8000204e:	70a2                	ld	ra,40(sp)
    80002050:	7402                	ld	s0,32(sp)
    80002052:	64e2                	ld	s1,24(sp)
    80002054:	6942                	ld	s2,16(sp)
    80002056:	69a2                	ld	s3,8(sp)
    80002058:	6a02                	ld	s4,0(sp)
    8000205a:	6145                	addi	sp,sp,48
    8000205c:	8082                	ret
    freeproc(p);
    8000205e:	8526                	mv	a0,s1
    80002060:	00000097          	auipc	ra,0x0
    80002064:	e8e080e7          	jalr	-370(ra) # 80001eee <freeproc>
    release(&p->lock);
    80002068:	8526                	mv	a0,s1
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	c2e080e7          	jalr	-978(ra) # 80000c98 <release>
    return 0;
    80002072:	84d2                	mv	s1,s4
    80002074:	bfe1                	j	8000204c <allocproc+0xd2>
    freeproc(p);
    80002076:	8526                	mv	a0,s1
    80002078:	00000097          	auipc	ra,0x0
    8000207c:	e76080e7          	jalr	-394(ra) # 80001eee <freeproc>
    release(&p->lock);
    80002080:	8526                	mv	a0,s1
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	c16080e7          	jalr	-1002(ra) # 80000c98 <release>
    return 0;
    8000208a:	84d2                	mv	s1,s4
    8000208c:	b7c1                	j	8000204c <allocproc+0xd2>

000000008000208e <userinit>:
{
    8000208e:	1101                	addi	sp,sp,-32
    80002090:	ec06                	sd	ra,24(sp)
    80002092:	e822                	sd	s0,16(sp)
    80002094:	e426                	sd	s1,8(sp)
    80002096:	1000                	addi	s0,sp,32
  p = allocproc();
    80002098:	00000097          	auipc	ra,0x0
    8000209c:	ee2080e7          	jalr	-286(ra) # 80001f7a <allocproc>
    800020a0:	84aa                	mv	s1,a0
  initproc = p;
    800020a2:	00007797          	auipc	a5,0x7
    800020a6:	f8a7b323          	sd	a0,-122(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800020aa:	03400613          	li	a2,52
    800020ae:	00006597          	auipc	a1,0x6
    800020b2:	7f258593          	addi	a1,a1,2034 # 800088a0 <initcode>
    800020b6:	7928                	ld	a0,112(a0)
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	2c2080e7          	jalr	706(ra) # 8000137a <uvminit>
  p->sz = PGSIZE;
    800020c0:	6785                	lui	a5,0x1
    800020c2:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;     // user program counter
    800020c4:	7cb8                	ld	a4,120(s1)
    800020c6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    800020ca:	7cb8                	ld	a4,120(s1)
    800020cc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800020ce:	4641                	li	a2,16
    800020d0:	00006597          	auipc	a1,0x6
    800020d4:	17058593          	addi	a1,a1,368 # 80008240 <digits+0x200>
    800020d8:	17848513          	addi	a0,s1,376
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	d68080e7          	jalr	-664(ra) # 80000e44 <safestrcpy>
  p->cwd = namei("/");
    800020e4:	00006517          	auipc	a0,0x6
    800020e8:	16c50513          	addi	a0,a0,364 # 80008250 <digits+0x210>
    800020ec:	00002097          	auipc	ra,0x2
    800020f0:	3ee080e7          	jalr	1006(ra) # 800044da <namei>
    800020f4:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    800020f8:	478d                	li	a5,3
    800020fa:	cc9c                	sw	a5,24(s1)
  add_proc(&cpus[0].runnable_head, p, &cpus[0].head_lock);
    800020fc:	0000f617          	auipc	a2,0xf
    80002100:	27460613          	addi	a2,a2,628 # 80011370 <cpus+0x88>
    80002104:	85a6                	mv	a1,s1
    80002106:	0000f517          	auipc	a0,0xf
    8000210a:	26250513          	addi	a0,a0,610 # 80011368 <cpus+0x80>
    8000210e:	00000097          	auipc	ra,0x0
    80002112:	92a080e7          	jalr	-1750(ra) # 80001a38 <add_proc>
  release(&p->lock);
    80002116:	8526                	mv	a0,s1
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	b80080e7          	jalr	-1152(ra) # 80000c98 <release>
}
    80002120:	60e2                	ld	ra,24(sp)
    80002122:	6442                	ld	s0,16(sp)
    80002124:	64a2                	ld	s1,8(sp)
    80002126:	6105                	addi	sp,sp,32
    80002128:	8082                	ret

000000008000212a <growproc>:
{
    8000212a:	1101                	addi	sp,sp,-32
    8000212c:	ec06                	sd	ra,24(sp)
    8000212e:	e822                	sd	s0,16(sp)
    80002130:	e426                	sd	s1,8(sp)
    80002132:	e04a                	sd	s2,0(sp)
    80002134:	1000                	addi	s0,sp,32
    80002136:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002138:	00000097          	auipc	ra,0x0
    8000213c:	c0a080e7          	jalr	-1014(ra) # 80001d42 <myproc>
    80002140:	892a                	mv	s2,a0
  sz = p->sz;
    80002142:	752c                	ld	a1,104(a0)
    80002144:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80002148:	00904f63          	bgtz	s1,80002166 <growproc+0x3c>
  else if (n < 0)
    8000214c:	0204cc63          	bltz	s1,80002184 <growproc+0x5a>
  p->sz = sz;
    80002150:	1602                	slli	a2,a2,0x20
    80002152:	9201                	srli	a2,a2,0x20
    80002154:	06c93423          	sd	a2,104(s2)
  return 0;
    80002158:	4501                	li	a0,0
}
    8000215a:	60e2                	ld	ra,24(sp)
    8000215c:	6442                	ld	s0,16(sp)
    8000215e:	64a2                	ld	s1,8(sp)
    80002160:	6902                	ld	s2,0(sp)
    80002162:	6105                	addi	sp,sp,32
    80002164:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80002166:	9e25                	addw	a2,a2,s1
    80002168:	1602                	slli	a2,a2,0x20
    8000216a:	9201                	srli	a2,a2,0x20
    8000216c:	1582                	slli	a1,a1,0x20
    8000216e:	9181                	srli	a1,a1,0x20
    80002170:	7928                	ld	a0,112(a0)
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	2c2080e7          	jalr	706(ra) # 80001434 <uvmalloc>
    8000217a:	0005061b          	sext.w	a2,a0
    8000217e:	fa69                	bnez	a2,80002150 <growproc+0x26>
      return -1;
    80002180:	557d                	li	a0,-1
    80002182:	bfe1                	j	8000215a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002184:	9e25                	addw	a2,a2,s1
    80002186:	1602                	slli	a2,a2,0x20
    80002188:	9201                	srli	a2,a2,0x20
    8000218a:	1582                	slli	a1,a1,0x20
    8000218c:	9181                	srli	a1,a1,0x20
    8000218e:	7928                	ld	a0,112(a0)
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	25c080e7          	jalr	604(ra) # 800013ec <uvmdealloc>
    80002198:	0005061b          	sext.w	a2,a0
    8000219c:	bf55                	j	80002150 <growproc+0x26>

000000008000219e <fork>:
{
    8000219e:	7179                	addi	sp,sp,-48
    800021a0:	f406                	sd	ra,40(sp)
    800021a2:	f022                	sd	s0,32(sp)
    800021a4:	ec26                	sd	s1,24(sp)
    800021a6:	e84a                	sd	s2,16(sp)
    800021a8:	e44e                	sd	s3,8(sp)
    800021aa:	e052                	sd	s4,0(sp)
    800021ac:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021ae:	00000097          	auipc	ra,0x0
    800021b2:	b94080e7          	jalr	-1132(ra) # 80001d42 <myproc>
    800021b6:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    800021b8:	00000097          	auipc	ra,0x0
    800021bc:	dc2080e7          	jalr	-574(ra) # 80001f7a <allocproc>
    800021c0:	14050463          	beqz	a0,80002308 <fork+0x16a>
    800021c4:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    800021c6:	06893603          	ld	a2,104(s2)
    800021ca:	792c                	ld	a1,112(a0)
    800021cc:	07093503          	ld	a0,112(s2)
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	3b0080e7          	jalr	944(ra) # 80001580 <uvmcopy>
    800021d8:	04054663          	bltz	a0,80002224 <fork+0x86>
  np->sz = p->sz;
    800021dc:	06893783          	ld	a5,104(s2)
    800021e0:	06f9b423          	sd	a5,104(s3)
  *(np->trapframe) = *(p->trapframe);
    800021e4:	07893683          	ld	a3,120(s2)
    800021e8:	87b6                	mv	a5,a3
    800021ea:	0789b703          	ld	a4,120(s3)
    800021ee:	12068693          	addi	a3,a3,288
    800021f2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800021f6:	6788                	ld	a0,8(a5)
    800021f8:	6b8c                	ld	a1,16(a5)
    800021fa:	6f90                	ld	a2,24(a5)
    800021fc:	01073023          	sd	a6,0(a4)
    80002200:	e708                	sd	a0,8(a4)
    80002202:	eb0c                	sd	a1,16(a4)
    80002204:	ef10                	sd	a2,24(a4)
    80002206:	02078793          	addi	a5,a5,32
    8000220a:	02070713          	addi	a4,a4,32
    8000220e:	fed792e3          	bne	a5,a3,800021f2 <fork+0x54>
  np->trapframe->a0 = 0;
    80002212:	0789b783          	ld	a5,120(s3)
    80002216:	0607b823          	sd	zero,112(a5)
    8000221a:	0f000493          	li	s1,240
  for (i = 0; i < NOFILE; i++)
    8000221e:	17000a13          	li	s4,368
    80002222:	a03d                	j	80002250 <fork+0xb2>
    freeproc(np);
    80002224:	854e                	mv	a0,s3
    80002226:	00000097          	auipc	ra,0x0
    8000222a:	cc8080e7          	jalr	-824(ra) # 80001eee <freeproc>
    release(&np->lock);
    8000222e:	854e                	mv	a0,s3
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	a68080e7          	jalr	-1432(ra) # 80000c98 <release>
    return -1;
    80002238:	5a7d                	li	s4,-1
    8000223a:	a875                	j	800022f6 <fork+0x158>
      np->ofile[i] = filedup(p->ofile[i]);
    8000223c:	00003097          	auipc	ra,0x3
    80002240:	934080e7          	jalr	-1740(ra) # 80004b70 <filedup>
    80002244:	009987b3          	add	a5,s3,s1
    80002248:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    8000224a:	04a1                	addi	s1,s1,8
    8000224c:	01448763          	beq	s1,s4,8000225a <fork+0xbc>
    if (p->ofile[i])
    80002250:	009907b3          	add	a5,s2,s1
    80002254:	6388                	ld	a0,0(a5)
    80002256:	f17d                	bnez	a0,8000223c <fork+0x9e>
    80002258:	bfcd                	j	8000224a <fork+0xac>
  np->cwd = idup(p->cwd);
    8000225a:	17093503          	ld	a0,368(s2)
    8000225e:	00002097          	auipc	ra,0x2
    80002262:	a88080e7          	jalr	-1400(ra) # 80003ce6 <idup>
    80002266:	16a9b823          	sd	a0,368(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000226a:	4641                	li	a2,16
    8000226c:	17890593          	addi	a1,s2,376
    80002270:	17898513          	addi	a0,s3,376
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	bd0080e7          	jalr	-1072(ra) # 80000e44 <safestrcpy>
  pid = np->pid;
    8000227c:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80002280:	854e                	mv	a0,s3
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	a16080e7          	jalr	-1514(ra) # 80000c98 <release>
  acquire(&wait_lock);
    8000228a:	0000f497          	auipc	s1,0xf
    8000228e:	57648493          	addi	s1,s1,1398 # 80011800 <wait_lock>
    80002292:	8526                	mv	a0,s1
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	950080e7          	jalr	-1712(ra) # 80000be4 <acquire>
  np->parent = p;
    8000229c:	0529bc23          	sd	s2,88(s3)
  np->cpu = p->cpu; // need to modify later (q.4)
    800022a0:	03492783          	lw	a5,52(s2)
    800022a4:	02f9aa23          	sw	a5,52(s3)
  release(&wait_lock);
    800022a8:	8526                	mv	a0,s1
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	9ee080e7          	jalr	-1554(ra) # 80000c98 <release>
  acquire(&np->lock);
    800022b2:	854e                	mv	a0,s3
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	930080e7          	jalr	-1744(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800022bc:	478d                	li	a5,3
    800022be:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800022c2:	854e                	mv	a0,s3
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	9d4080e7          	jalr	-1580(ra) # 80000c98 <release>
  add_proc(&cpus[p->cpu].runnable_head, p, &cpus[p->cpu].head_lock);
    800022cc:	03492703          	lw	a4,52(s2)
    800022d0:	00271793          	slli	a5,a4,0x2
    800022d4:	97ba                	add	a5,a5,a4
    800022d6:	0796                	slli	a5,a5,0x5
    800022d8:	0000f517          	auipc	a0,0xf
    800022dc:	01050513          	addi	a0,a0,16 # 800112e8 <cpus>
    800022e0:	08878613          	addi	a2,a5,136
    800022e4:	08078793          	addi	a5,a5,128
    800022e8:	962a                	add	a2,a2,a0
    800022ea:	85ca                	mv	a1,s2
    800022ec:	953e                	add	a0,a0,a5
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	74a080e7          	jalr	1866(ra) # 80001a38 <add_proc>
}
    800022f6:	8552                	mv	a0,s4
    800022f8:	70a2                	ld	ra,40(sp)
    800022fa:	7402                	ld	s0,32(sp)
    800022fc:	64e2                	ld	s1,24(sp)
    800022fe:	6942                	ld	s2,16(sp)
    80002300:	69a2                	ld	s3,8(sp)
    80002302:	6a02                	ld	s4,0(sp)
    80002304:	6145                	addi	sp,sp,48
    80002306:	8082                	ret
    return -1;
    80002308:	5a7d                	li	s4,-1
    8000230a:	b7f5                	j	800022f6 <fork+0x158>

000000008000230c <scheduler>:
{
    8000230c:	711d                	addi	sp,sp,-96
    8000230e:	ec86                	sd	ra,88(sp)
    80002310:	e8a2                	sd	s0,80(sp)
    80002312:	e4a6                	sd	s1,72(sp)
    80002314:	e0ca                	sd	s2,64(sp)
    80002316:	fc4e                	sd	s3,56(sp)
    80002318:	f852                	sd	s4,48(sp)
    8000231a:	f456                	sd	s5,40(sp)
    8000231c:	f05a                	sd	s6,32(sp)
    8000231e:	ec5e                	sd	s7,24(sp)
    80002320:	e862                	sd	s8,16(sp)
    80002322:	e466                	sd	s9,8(sp)
    80002324:	e06a                	sd	s10,0(sp)
    80002326:	1080                	addi	s0,sp,96
    80002328:	8712                	mv	a4,tp
  int id = r_tp();
    8000232a:	2701                	sext.w	a4,a4
  c->proc = 0;
    8000232c:	00271793          	slli	a5,a4,0x2
    80002330:	00e786b3          	add	a3,a5,a4
    80002334:	00569613          	slli	a2,a3,0x5
    80002338:	0000f697          	auipc	a3,0xf
    8000233c:	f6868693          	addi	a3,a3,-152 # 800112a0 <zombie_lock>
    80002340:	96b2                	add	a3,a3,a2
    80002342:	0406b423          	sd	zero,72(a3)
        remove_proc(&c->runnable_head, p, &c->head_lock);
    80002346:	0000fa97          	auipc	s5,0xf
    8000234a:	fa2a8a93          	addi	s5,s5,-94 # 800112e8 <cpus>
    8000234e:	08060b93          	addi	s7,a2,128
    80002352:	9bd6                	add	s7,s7,s5
    80002354:	08860b13          	addi	s6,a2,136
    80002358:	9b56                	add	s6,s6,s5
        swtch(&c->context, &p->context);
    8000235a:	00860793          	addi	a5,a2,8
    8000235e:	9abe                	add	s5,s5,a5
      if (c->runnable_head != -1)
    80002360:	8936                	mv	s2,a3
    80002362:	59fd                	li	s3,-1
    80002364:	18800c93          	li	s9,392
        p = &proc[c->runnable_head];
    80002368:	0000fa17          	auipc	s4,0xf
    8000236c:	4b0a0a13          	addi	s4,s4,1200 # 80011818 <proc>
        p->state = RUNNING;
    80002370:	4c11                	li	s8,4
    80002372:	a0a1                	j	800023ba <scheduler+0xae>
        p = &proc[c->runnable_head];
    80002374:	039584b3          	mul	s1,a1,s9
    80002378:	01448d33          	add	s10,s1,s4
        acquire(&p->lock);
    8000237c:	856a                	mv	a0,s10
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	866080e7          	jalr	-1946(ra) # 80000be4 <acquire>
        remove_proc(&c->runnable_head, p, &c->head_lock);
    80002386:	865a                	mv	a2,s6
    80002388:	85ea                	mv	a1,s10
    8000238a:	855e                	mv	a0,s7
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	576080e7          	jalr	1398(ra) # 80001902 <remove_proc>
        p->state = RUNNING;
    80002394:	018d2c23          	sw	s8,24(s10)
        c->proc = p;
    80002398:	05a93423          	sd	s10,72(s2)
        swtch(&c->context, &p->context);
    8000239c:	08048593          	addi	a1,s1,128
    800023a0:	95d2                	add	a1,a1,s4
    800023a2:	8556                	mv	a0,s5
    800023a4:	00001097          	auipc	ra,0x1
    800023a8:	8d2080e7          	jalr	-1838(ra) # 80002c76 <swtch>
        c->proc = 0;
    800023ac:	04093423          	sd	zero,72(s2)
        release(&p->lock);
    800023b0:	856a                	mv	a0,s10
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	8e6080e7          	jalr	-1818(ra) # 80000c98 <release>
      if (c->runnable_head != -1)
    800023ba:	0c892583          	lw	a1,200(s2)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023be:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800023c2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800023c6:	10079073          	csrw	sstatus,a5
    800023ca:	ff358ae3          	beq	a1,s3,800023be <scheduler+0xb2>
    800023ce:	b75d                	j	80002374 <scheduler+0x68>

00000000800023d0 <sched>:
{
    800023d0:	7179                	addi	sp,sp,-48
    800023d2:	f406                	sd	ra,40(sp)
    800023d4:	f022                	sd	s0,32(sp)
    800023d6:	ec26                	sd	s1,24(sp)
    800023d8:	e84a                	sd	s2,16(sp)
    800023da:	e44e                	sd	s3,8(sp)
    800023dc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800023de:	00000097          	auipc	ra,0x0
    800023e2:	964080e7          	jalr	-1692(ra) # 80001d42 <myproc>
    800023e6:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800023e8:	ffffe097          	auipc	ra,0xffffe
    800023ec:	782080e7          	jalr	1922(ra) # 80000b6a <holding>
    800023f0:	c959                	beqz	a0,80002486 <sched+0xb6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023f2:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800023f4:	0007871b          	sext.w	a4,a5
    800023f8:	00271793          	slli	a5,a4,0x2
    800023fc:	97ba                	add	a5,a5,a4
    800023fe:	0796                	slli	a5,a5,0x5
    80002400:	0000f717          	auipc	a4,0xf
    80002404:	ea070713          	addi	a4,a4,-352 # 800112a0 <zombie_lock>
    80002408:	97ba                	add	a5,a5,a4
    8000240a:	0c07a703          	lw	a4,192(a5)
    8000240e:	4785                	li	a5,1
    80002410:	08f71363          	bne	a4,a5,80002496 <sched+0xc6>
  if (p->state == RUNNING)
    80002414:	4c98                	lw	a4,24(s1)
    80002416:	4791                	li	a5,4
    80002418:	08f70763          	beq	a4,a5,800024a6 <sched+0xd6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000241c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002420:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002422:	ebd1                	bnez	a5,800024b6 <sched+0xe6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002424:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002426:	0000f917          	auipc	s2,0xf
    8000242a:	e7a90913          	addi	s2,s2,-390 # 800112a0 <zombie_lock>
    8000242e:	0007871b          	sext.w	a4,a5
    80002432:	00271793          	slli	a5,a4,0x2
    80002436:	97ba                	add	a5,a5,a4
    80002438:	0796                	slli	a5,a5,0x5
    8000243a:	97ca                	add	a5,a5,s2
    8000243c:	0c47a983          	lw	s3,196(a5)
    80002440:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002442:	0007859b          	sext.w	a1,a5
    80002446:	00259793          	slli	a5,a1,0x2
    8000244a:	97ae                	add	a5,a5,a1
    8000244c:	0796                	slli	a5,a5,0x5
    8000244e:	0000f597          	auipc	a1,0xf
    80002452:	ea258593          	addi	a1,a1,-350 # 800112f0 <cpus+0x8>
    80002456:	95be                	add	a1,a1,a5
    80002458:	08048513          	addi	a0,s1,128
    8000245c:	00001097          	auipc	ra,0x1
    80002460:	81a080e7          	jalr	-2022(ra) # 80002c76 <swtch>
    80002464:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002466:	0007871b          	sext.w	a4,a5
    8000246a:	00271793          	slli	a5,a4,0x2
    8000246e:	97ba                	add	a5,a5,a4
    80002470:	0796                	slli	a5,a5,0x5
    80002472:	97ca                	add	a5,a5,s2
    80002474:	0d37a223          	sw	s3,196(a5)
}
    80002478:	70a2                	ld	ra,40(sp)
    8000247a:	7402                	ld	s0,32(sp)
    8000247c:	64e2                	ld	s1,24(sp)
    8000247e:	6942                	ld	s2,16(sp)
    80002480:	69a2                	ld	s3,8(sp)
    80002482:	6145                	addi	sp,sp,48
    80002484:	8082                	ret
    panic("sched p->lock");
    80002486:	00006517          	auipc	a0,0x6
    8000248a:	dd250513          	addi	a0,a0,-558 # 80008258 <digits+0x218>
    8000248e:	ffffe097          	auipc	ra,0xffffe
    80002492:	0b0080e7          	jalr	176(ra) # 8000053e <panic>
    panic("sched locks");
    80002496:	00006517          	auipc	a0,0x6
    8000249a:	dd250513          	addi	a0,a0,-558 # 80008268 <digits+0x228>
    8000249e:	ffffe097          	auipc	ra,0xffffe
    800024a2:	0a0080e7          	jalr	160(ra) # 8000053e <panic>
    panic("sched running");
    800024a6:	00006517          	auipc	a0,0x6
    800024aa:	dd250513          	addi	a0,a0,-558 # 80008278 <digits+0x238>
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	090080e7          	jalr	144(ra) # 8000053e <panic>
    panic("sched interruptible");
    800024b6:	00006517          	auipc	a0,0x6
    800024ba:	dd250513          	addi	a0,a0,-558 # 80008288 <digits+0x248>
    800024be:	ffffe097          	auipc	ra,0xffffe
    800024c2:	080080e7          	jalr	128(ra) # 8000053e <panic>

00000000800024c6 <yield>:
{
    800024c6:	1101                	addi	sp,sp,-32
    800024c8:	ec06                	sd	ra,24(sp)
    800024ca:	e822                	sd	s0,16(sp)
    800024cc:	e426                	sd	s1,8(sp)
    800024ce:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800024d0:	00000097          	auipc	ra,0x0
    800024d4:	872080e7          	jalr	-1934(ra) # 80001d42 <myproc>
    800024d8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	70a080e7          	jalr	1802(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800024e2:	478d                	li	a5,3
    800024e4:	cc9c                	sw	a5,24(s1)
  add_proc(&cpus[p->cpu].runnable_head, p, &cpus[p->cpu].head_lock);
    800024e6:	58c8                	lw	a0,52(s1)
    800024e8:	00251793          	slli	a5,a0,0x2
    800024ec:	97aa                	add	a5,a5,a0
    800024ee:	0796                	slli	a5,a5,0x5
    800024f0:	0000f517          	auipc	a0,0xf
    800024f4:	df850513          	addi	a0,a0,-520 # 800112e8 <cpus>
    800024f8:	08878613          	addi	a2,a5,136
    800024fc:	08078793          	addi	a5,a5,128
    80002500:	962a                	add	a2,a2,a0
    80002502:	85a6                	mv	a1,s1
    80002504:	953e                	add	a0,a0,a5
    80002506:	fffff097          	auipc	ra,0xfffff
    8000250a:	532080e7          	jalr	1330(ra) # 80001a38 <add_proc>
  sched();
    8000250e:	00000097          	auipc	ra,0x0
    80002512:	ec2080e7          	jalr	-318(ra) # 800023d0 <sched>
  release(&p->lock);
    80002516:	8526                	mv	a0,s1
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	780080e7          	jalr	1920(ra) # 80000c98 <release>
}
    80002520:	60e2                	ld	ra,24(sp)
    80002522:	6442                	ld	s0,16(sp)
    80002524:	64a2                	ld	s1,8(sp)
    80002526:	6105                	addi	sp,sp,32
    80002528:	8082                	ret

000000008000252a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000252a:	7179                	addi	sp,sp,-48
    8000252c:	f406                	sd	ra,40(sp)
    8000252e:	f022                	sd	s0,32(sp)
    80002530:	ec26                	sd	s1,24(sp)
    80002532:	e84a                	sd	s2,16(sp)
    80002534:	e44e                	sd	s3,8(sp)
    80002536:	1800                	addi	s0,sp,48
    80002538:	89aa                	mv	s3,a0
    8000253a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000253c:	00000097          	auipc	ra,0x0
    80002540:	806080e7          	jalr	-2042(ra) # 80001d42 <myproc>
    80002544:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	69e080e7          	jalr	1694(ra) # 80000be4 <acquire>
  p->chan = chan;
    8000254e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002552:	4789                	li	a5,2
    80002554:	cc9c                	sw	a5,24(s1)
  add_proc(&sleeping_head, p, &sleeping_lock);
    80002556:	0000f617          	auipc	a2,0xf
    8000255a:	d7a60613          	addi	a2,a2,-646 # 800112d0 <sleeping_lock>
    8000255e:	85a6                	mv	a1,s1
    80002560:	00006517          	auipc	a0,0x6
    80002564:	32850513          	addi	a0,a0,808 # 80008888 <sleeping_head>
    80002568:	fffff097          	auipc	ra,0xfffff
    8000256c:	4d0080e7          	jalr	1232(ra) # 80001a38 <add_proc>
  release(lk);
    80002570:	854a                	mv	a0,s2
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	726080e7          	jalr	1830(ra) # 80000c98 <release>

  // Go to sleep.

  sched();
    8000257a:	00000097          	auipc	ra,0x0
    8000257e:	e56080e7          	jalr	-426(ra) # 800023d0 <sched>

  // Tidy up.
  p->chan = 0;
    80002582:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002586:	8526                	mv	a0,s1
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	710080e7          	jalr	1808(ra) # 80000c98 <release>
  acquire(lk);
    80002590:	854a                	mv	a0,s2
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	652080e7          	jalr	1618(ra) # 80000be4 <acquire>
}
    8000259a:	70a2                	ld	ra,40(sp)
    8000259c:	7402                	ld	s0,32(sp)
    8000259e:	64e2                	ld	s1,24(sp)
    800025a0:	6942                	ld	s2,16(sp)
    800025a2:	69a2                	ld	s3,8(sp)
    800025a4:	6145                	addi	sp,sp,48
    800025a6:	8082                	ret

00000000800025a8 <wait>:
{
    800025a8:	715d                	addi	sp,sp,-80
    800025aa:	e486                	sd	ra,72(sp)
    800025ac:	e0a2                	sd	s0,64(sp)
    800025ae:	fc26                	sd	s1,56(sp)
    800025b0:	f84a                	sd	s2,48(sp)
    800025b2:	f44e                	sd	s3,40(sp)
    800025b4:	f052                	sd	s4,32(sp)
    800025b6:	ec56                	sd	s5,24(sp)
    800025b8:	e85a                	sd	s6,16(sp)
    800025ba:	e45e                	sd	s7,8(sp)
    800025bc:	e062                	sd	s8,0(sp)
    800025be:	0880                	addi	s0,sp,80
    800025c0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025c2:	fffff097          	auipc	ra,0xfffff
    800025c6:	780080e7          	jalr	1920(ra) # 80001d42 <myproc>
    800025ca:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800025cc:	0000f517          	auipc	a0,0xf
    800025d0:	23450513          	addi	a0,a0,564 # 80011800 <wait_lock>
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	610080e7          	jalr	1552(ra) # 80000be4 <acquire>
    havekids = 0;
    800025dc:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    800025de:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    800025e0:	00015997          	auipc	s3,0x15
    800025e4:	43898993          	addi	s3,s3,1080 # 80017a18 <tickslock>
        havekids = 1;
    800025e8:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    800025ea:	0000fc17          	auipc	s8,0xf
    800025ee:	216c0c13          	addi	s8,s8,534 # 80011800 <wait_lock>
    havekids = 0;
    800025f2:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    800025f4:	0000f497          	auipc	s1,0xf
    800025f8:	22448493          	addi	s1,s1,548 # 80011818 <proc>
    800025fc:	a0bd                	j	8000266a <wait+0xc2>
          pid = np->pid;
    800025fe:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002602:	000b0e63          	beqz	s6,8000261e <wait+0x76>
    80002606:	4691                	li	a3,4
    80002608:	02c48613          	addi	a2,s1,44
    8000260c:	85da                	mv	a1,s6
    8000260e:	07093503          	ld	a0,112(s2)
    80002612:	fffff097          	auipc	ra,0xfffff
    80002616:	072080e7          	jalr	114(ra) # 80001684 <copyout>
    8000261a:	02054563          	bltz	a0,80002644 <wait+0x9c>
          freeproc(np);
    8000261e:	8526                	mv	a0,s1
    80002620:	00000097          	auipc	ra,0x0
    80002624:	8ce080e7          	jalr	-1842(ra) # 80001eee <freeproc>
          release(&np->lock);
    80002628:	8526                	mv	a0,s1
    8000262a:	ffffe097          	auipc	ra,0xffffe
    8000262e:	66e080e7          	jalr	1646(ra) # 80000c98 <release>
          release(&wait_lock);
    80002632:	0000f517          	auipc	a0,0xf
    80002636:	1ce50513          	addi	a0,a0,462 # 80011800 <wait_lock>
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	65e080e7          	jalr	1630(ra) # 80000c98 <release>
          return pid;
    80002642:	a09d                	j	800026a8 <wait+0x100>
            release(&np->lock);
    80002644:	8526                	mv	a0,s1
    80002646:	ffffe097          	auipc	ra,0xffffe
    8000264a:	652080e7          	jalr	1618(ra) # 80000c98 <release>
            release(&wait_lock);
    8000264e:	0000f517          	auipc	a0,0xf
    80002652:	1b250513          	addi	a0,a0,434 # 80011800 <wait_lock>
    80002656:	ffffe097          	auipc	ra,0xffffe
    8000265a:	642080e7          	jalr	1602(ra) # 80000c98 <release>
            return -1;
    8000265e:	59fd                	li	s3,-1
    80002660:	a0a1                	j	800026a8 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    80002662:	18848493          	addi	s1,s1,392
    80002666:	03348463          	beq	s1,s3,8000268e <wait+0xe6>
      if (np->parent == p)
    8000266a:	6cbc                	ld	a5,88(s1)
    8000266c:	ff279be3          	bne	a5,s2,80002662 <wait+0xba>
        acquire(&np->lock);
    80002670:	8526                	mv	a0,s1
    80002672:	ffffe097          	auipc	ra,0xffffe
    80002676:	572080e7          	jalr	1394(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    8000267a:	4c9c                	lw	a5,24(s1)
    8000267c:	f94781e3          	beq	a5,s4,800025fe <wait+0x56>
        release(&np->lock);
    80002680:	8526                	mv	a0,s1
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	616080e7          	jalr	1558(ra) # 80000c98 <release>
        havekids = 1;
    8000268a:	8756                	mv	a4,s5
    8000268c:	bfd9                	j	80002662 <wait+0xba>
    if (!havekids || p->killed)
    8000268e:	c701                	beqz	a4,80002696 <wait+0xee>
    80002690:	02892783          	lw	a5,40(s2)
    80002694:	c79d                	beqz	a5,800026c2 <wait+0x11a>
      release(&wait_lock);
    80002696:	0000f517          	auipc	a0,0xf
    8000269a:	16a50513          	addi	a0,a0,362 # 80011800 <wait_lock>
    8000269e:	ffffe097          	auipc	ra,0xffffe
    800026a2:	5fa080e7          	jalr	1530(ra) # 80000c98 <release>
      return -1;
    800026a6:	59fd                	li	s3,-1
}
    800026a8:	854e                	mv	a0,s3
    800026aa:	60a6                	ld	ra,72(sp)
    800026ac:	6406                	ld	s0,64(sp)
    800026ae:	74e2                	ld	s1,56(sp)
    800026b0:	7942                	ld	s2,48(sp)
    800026b2:	79a2                	ld	s3,40(sp)
    800026b4:	7a02                	ld	s4,32(sp)
    800026b6:	6ae2                	ld	s5,24(sp)
    800026b8:	6b42                	ld	s6,16(sp)
    800026ba:	6ba2                	ld	s7,8(sp)
    800026bc:	6c02                	ld	s8,0(sp)
    800026be:	6161                	addi	sp,sp,80
    800026c0:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800026c2:	85e2                	mv	a1,s8
    800026c4:	854a                	mv	a0,s2
    800026c6:	00000097          	auipc	ra,0x0
    800026ca:	e64080e7          	jalr	-412(ra) # 8000252a <sleep>
    havekids = 0;
    800026ce:	b715                	j	800025f2 <wait+0x4a>

00000000800026d0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800026d0:	7159                	addi	sp,sp,-112
    800026d2:	f486                	sd	ra,104(sp)
    800026d4:	f0a2                	sd	s0,96(sp)
    800026d6:	eca6                	sd	s1,88(sp)
    800026d8:	e8ca                	sd	s2,80(sp)
    800026da:	e4ce                	sd	s3,72(sp)
    800026dc:	e0d2                	sd	s4,64(sp)
    800026de:	fc56                	sd	s5,56(sp)
    800026e0:	f85a                	sd	s6,48(sp)
    800026e2:	f45e                	sd	s7,40(sp)
    800026e4:	f062                	sd	s8,32(sp)
    800026e6:	ec66                	sd	s9,24(sp)
    800026e8:	e86a                	sd	s10,16(sp)
    800026ea:	e46e                	sd	s11,8(sp)
    800026ec:	1880                	addi	s0,sp,112
    800026ee:	8baa                	mv	s7,a0
  while(proc[sleeping_head].next != -1){
    800026f0:	00006797          	auipc	a5,0x6
    800026f4:	1987a783          	lw	a5,408(a5) # 80008888 <sleeping_head>
    800026f8:	18800713          	li	a4,392
    800026fc:	02e786b3          	mul	a3,a5,a4
    80002700:	0000f717          	auipc	a4,0xf
    80002704:	11870713          	addi	a4,a4,280 # 80011818 <proc>
    80002708:	9736                	add	a4,a4,a3
    8000270a:	4b34                	lw	a3,80(a4)
    8000270c:	577d                	li	a4,-1
    8000270e:	04e68863          	beq	a3,a4,8000275e <wakeup+0x8e>
    printf("%d\n", proc[sleeping_head].proc_idx);
    80002712:	0000f917          	auipc	s2,0xf
    80002716:	10690913          	addi	s2,s2,262 # 80011818 <proc>
    8000271a:	18800493          	li	s1,392
    8000271e:	00006a97          	auipc	s5,0x6
    80002722:	d62a8a93          	addi	s5,s5,-670 # 80008480 <states.1761+0x168>
    sleeping_head = proc[sleeping_head].next;
    80002726:	00006997          	auipc	s3,0x6
    8000272a:	16298993          	addi	s3,s3,354 # 80008888 <sleeping_head>
  while(proc[sleeping_head].next != -1){
    8000272e:	5a7d                	li	s4,-1
    printf("%d\n", proc[sleeping_head].proc_idx);
    80002730:	029787b3          	mul	a5,a5,s1
    80002734:	97ca                	add	a5,a5,s2
    80002736:	4bec                	lw	a1,84(a5)
    80002738:	8556                	mv	a0,s5
    8000273a:	ffffe097          	auipc	ra,0xffffe
    8000273e:	e4e080e7          	jalr	-434(ra) # 80000588 <printf>
    sleeping_head = proc[sleeping_head].next;
    80002742:	0009a783          	lw	a5,0(s3)
    80002746:	029787b3          	mul	a5,a5,s1
    8000274a:	97ca                	add	a5,a5,s2
    8000274c:	4bbc                	lw	a5,80(a5)
    8000274e:	00f9a023          	sw	a5,0(s3)
  while(proc[sleeping_head].next != -1){
    80002752:	02978733          	mul	a4,a5,s1
    80002756:	974a                	add	a4,a4,s2
    80002758:	4b38                	lw	a4,80(a4)
    8000275a:	fd471be3          	bne	a4,s4,80002730 <wakeup+0x60>
  }
  struct proc *p;
  printf("%s\n", "line 700---------------------");
    8000275e:	00006597          	auipc	a1,0x6
    80002762:	b4258593          	addi	a1,a1,-1214 # 800082a0 <digits+0x260>
    80002766:	00006517          	auipc	a0,0x6
    8000276a:	b5a50513          	addi	a0,a0,-1190 # 800082c0 <digits+0x280>
    8000276e:	ffffe097          	auipc	ra,0xffffe
    80002772:	e1a080e7          	jalr	-486(ra) # 80000588 <printf>
  if (sleeping_head != -1)
    80002776:	00006997          	auipc	s3,0x6
    8000277a:	1129a983          	lw	s3,274(s3) # 80008888 <sleeping_head>
    8000277e:	57fd                	li	a5,-1
    80002780:	02f99163          	bne	s3,a5,800027a2 <wakeup+0xd2>
      }
      else
        release(&p->p_lock);
    }
  }
}
    80002784:	70a6                	ld	ra,104(sp)
    80002786:	7406                	ld	s0,96(sp)
    80002788:	64e6                	ld	s1,88(sp)
    8000278a:	6946                	ld	s2,80(sp)
    8000278c:	69a6                	ld	s3,72(sp)
    8000278e:	6a06                	ld	s4,64(sp)
    80002790:	7ae2                	ld	s5,56(sp)
    80002792:	7b42                	ld	s6,48(sp)
    80002794:	7ba2                	ld	s7,40(sp)
    80002796:	7c02                	ld	s8,32(sp)
    80002798:	6ce2                	ld	s9,24(sp)
    8000279a:	6d42                	ld	s10,16(sp)
    8000279c:	6da2                	ld	s11,8(sp)
    8000279e:	6165                	addi	sp,sp,112
    800027a0:	8082                	ret
    printf("%d\n", p->proc_idx);
    800027a2:	0000f917          	auipc	s2,0xf
    800027a6:	07690913          	addi	s2,s2,118 # 80011818 <proc>
    800027aa:	18800493          	li	s1,392
    800027ae:	029984b3          	mul	s1,s3,s1
    800027b2:	00990ab3          	add	s5,s2,s1
    800027b6:	054aa583          	lw	a1,84(s5)
    800027ba:	00006517          	auipc	a0,0x6
    800027be:	cc650513          	addi	a0,a0,-826 # 80008480 <states.1761+0x168>
    800027c2:	ffffe097          	auipc	ra,0xffffe
    800027c6:	dc6080e7          	jalr	-570(ra) # 80000588 <printf>
    acquire(&p->p_lock);
    800027ca:	03848a13          	addi	s4,s1,56
    800027ce:	9a4a                	add	s4,s4,s2
    800027d0:	8552                	mv	a0,s4
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	412080e7          	jalr	1042(ra) # 80000be4 <acquire>
    int next_proc = p->next;
    800027da:	050aa903          	lw	s2,80(s5)
    if (p->chan == chan)
    800027de:	020ab783          	ld	a5,32(s5)
    800027e2:	03778763          	beq	a5,s7,80002810 <wakeup+0x140>
      release(&p->p_lock);
    800027e6:	8552                	mv	a0,s4
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	4b0080e7          	jalr	1200(ra) # 80000c98 <release>
    while (next_proc != -1)
    800027f0:	57fd                	li	a5,-1
    800027f2:	f8f909e3          	beq	s2,a5,80002784 <wakeup+0xb4>
    800027f6:	18800b13          	li	s6,392
      acquire(&p->p_lock);
    800027fa:	0000fa97          	auipc	s5,0xf
    800027fe:	01ea8a93          	addi	s5,s5,30 # 80011818 <proc>
        p->state = RUNNABLE;
    80002802:	4d8d                	li	s11,3
        add_proc(&cpus[cpu_num].runnable_head, p, &cpus[cpu_num].head_lock);
    80002804:	0000fd17          	auipc	s10,0xf
    80002808:	ae4d0d13          	addi	s10,s10,-1308 # 800112e8 <cpus>
    while (next_proc != -1)
    8000280c:	5c7d                	li	s8,-1
    8000280e:	a065                	j	800028b6 <wakeup+0x1e6>
    p = &proc[sleeping_head];
    80002810:	84d6                	mv	s1,s5
    int cpu_num = p->cpu;
    80002812:	034aaa83          	lw	s5,52(s5)
      release(&p->p_lock);
    80002816:	8552                	mv	a0,s4
    80002818:	ffffe097          	auipc	ra,0xffffe
    8000281c:	480080e7          	jalr	1152(ra) # 80000c98 <release>
      p->state = RUNNABLE;
    80002820:	478d                	li	a5,3
    80002822:	cc9c                	sw	a5,24(s1)
      remove_proc(&sleeping_head, p, &sleeping_lock);
    80002824:	0000f617          	auipc	a2,0xf
    80002828:	aac60613          	addi	a2,a2,-1364 # 800112d0 <sleeping_lock>
    8000282c:	85a6                	mv	a1,s1
    8000282e:	00006517          	auipc	a0,0x6
    80002832:	05a50513          	addi	a0,a0,90 # 80008888 <sleeping_head>
    80002836:	fffff097          	auipc	ra,0xfffff
    8000283a:	0cc080e7          	jalr	204(ra) # 80001902 <remove_proc>
      add_proc(&cpus[cpu_num].runnable_head, p, &cpus[cpu_num].head_lock);
    8000283e:	002a9793          	slli	a5,s5,0x2
    80002842:	97d6                	add	a5,a5,s5
    80002844:	0796                	slli	a5,a5,0x5
    80002846:	0000f517          	auipc	a0,0xf
    8000284a:	aa250513          	addi	a0,a0,-1374 # 800112e8 <cpus>
    8000284e:	08878613          	addi	a2,a5,136
    80002852:	08078793          	addi	a5,a5,128
    80002856:	962a                	add	a2,a2,a0
    80002858:	85a6                	mv	a1,s1
    8000285a:	953e                	add	a0,a0,a5
    8000285c:	fffff097          	auipc	ra,0xfffff
    80002860:	1dc080e7          	jalr	476(ra) # 80001a38 <add_proc>
    80002864:	b771                	j	800027f0 <wakeup+0x120>
      p = &proc[next_proc];
    80002866:	99d6                	add	s3,s3,s5
      cpu_num = p->cpu;
    80002868:	0349ac83          	lw	s9,52(s3)
        release(&p->p_lock);
    8000286c:	8526                	mv	a0,s1
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	42a080e7          	jalr	1066(ra) # 80000c98 <release>
        p->state = RUNNABLE;
    80002876:	01b9ac23          	sw	s11,24(s3)
        remove_proc(&sleeping_head, p, &sleeping_lock);
    8000287a:	0000f617          	auipc	a2,0xf
    8000287e:	a5660613          	addi	a2,a2,-1450 # 800112d0 <sleeping_lock>
    80002882:	85ce                	mv	a1,s3
    80002884:	00006517          	auipc	a0,0x6
    80002888:	00450513          	addi	a0,a0,4 # 80008888 <sleeping_head>
    8000288c:	fffff097          	auipc	ra,0xfffff
    80002890:	076080e7          	jalr	118(ra) # 80001902 <remove_proc>
        add_proc(&cpus[cpu_num].runnable_head, p, &cpus[cpu_num].head_lock);
    80002894:	002c9513          	slli	a0,s9,0x2
    80002898:	9566                	add	a0,a0,s9
    8000289a:	0516                	slli	a0,a0,0x5
    8000289c:	08850613          	addi	a2,a0,136
    800028a0:	08050513          	addi	a0,a0,128
    800028a4:	966a                	add	a2,a2,s10
    800028a6:	85ce                	mv	a1,s3
    800028a8:	956a                	add	a0,a0,s10
    800028aa:	fffff097          	auipc	ra,0xfffff
    800028ae:	18e080e7          	jalr	398(ra) # 80001a38 <add_proc>
    while (next_proc != -1)
    800028b2:	ed8909e3          	beq	s2,s8,80002784 <wakeup+0xb4>
      acquire(&p->p_lock);
    800028b6:	036909b3          	mul	s3,s2,s6
    800028ba:	03898493          	addi	s1,s3,56
    800028be:	94d6                	add	s1,s1,s5
    800028c0:	8526                	mv	a0,s1
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	322080e7          	jalr	802(ra) # 80000be4 <acquire>
      next_proc = p->next;
    800028ca:	013a87b3          	add	a5,s5,s3
    800028ce:	0507a903          	lw	s2,80(a5)
      if (p->chan == chan)
    800028d2:	013a87b3          	add	a5,s5,s3
    800028d6:	739c                	ld	a5,32(a5)
    800028d8:	f97787e3          	beq	a5,s7,80002866 <wakeup+0x196>
        release(&p->p_lock);
    800028dc:	8526                	mv	a0,s1
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	3ba080e7          	jalr	954(ra) # 80000c98 <release>
    800028e6:	b7f1                	j	800028b2 <wakeup+0x1e2>

00000000800028e8 <reparent>:
{
    800028e8:	7179                	addi	sp,sp,-48
    800028ea:	f406                	sd	ra,40(sp)
    800028ec:	f022                	sd	s0,32(sp)
    800028ee:	ec26                	sd	s1,24(sp)
    800028f0:	e84a                	sd	s2,16(sp)
    800028f2:	e44e                	sd	s3,8(sp)
    800028f4:	e052                	sd	s4,0(sp)
    800028f6:	1800                	addi	s0,sp,48
    800028f8:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800028fa:	0000f497          	auipc	s1,0xf
    800028fe:	f1e48493          	addi	s1,s1,-226 # 80011818 <proc>
      pp->parent = initproc;
    80002902:	00006a17          	auipc	s4,0x6
    80002906:	726a0a13          	addi	s4,s4,1830 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000290a:	00015997          	auipc	s3,0x15
    8000290e:	10e98993          	addi	s3,s3,270 # 80017a18 <tickslock>
    80002912:	a029                	j	8000291c <reparent+0x34>
    80002914:	18848493          	addi	s1,s1,392
    80002918:	01348d63          	beq	s1,s3,80002932 <reparent+0x4a>
    if (pp->parent == p)
    8000291c:	6cbc                	ld	a5,88(s1)
    8000291e:	ff279be3          	bne	a5,s2,80002914 <reparent+0x2c>
      pp->parent = initproc;
    80002922:	000a3503          	ld	a0,0(s4)
    80002926:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    80002928:	00000097          	auipc	ra,0x0
    8000292c:	da8080e7          	jalr	-600(ra) # 800026d0 <wakeup>
    80002930:	b7d5                	j	80002914 <reparent+0x2c>
}
    80002932:	70a2                	ld	ra,40(sp)
    80002934:	7402                	ld	s0,32(sp)
    80002936:	64e2                	ld	s1,24(sp)
    80002938:	6942                	ld	s2,16(sp)
    8000293a:	69a2                	ld	s3,8(sp)
    8000293c:	6a02                	ld	s4,0(sp)
    8000293e:	6145                	addi	sp,sp,48
    80002940:	8082                	ret

0000000080002942 <exit>:
{
    80002942:	7179                	addi	sp,sp,-48
    80002944:	f406                	sd	ra,40(sp)
    80002946:	f022                	sd	s0,32(sp)
    80002948:	ec26                	sd	s1,24(sp)
    8000294a:	e84a                	sd	s2,16(sp)
    8000294c:	e44e                	sd	s3,8(sp)
    8000294e:	e052                	sd	s4,0(sp)
    80002950:	1800                	addi	s0,sp,48
    80002952:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002954:	fffff097          	auipc	ra,0xfffff
    80002958:	3ee080e7          	jalr	1006(ra) # 80001d42 <myproc>
    8000295c:	89aa                	mv	s3,a0
  if (p == initproc)
    8000295e:	00006797          	auipc	a5,0x6
    80002962:	6ca7b783          	ld	a5,1738(a5) # 80009028 <initproc>
    80002966:	0f050493          	addi	s1,a0,240
    8000296a:	17050913          	addi	s2,a0,368
    8000296e:	02a79363          	bne	a5,a0,80002994 <exit+0x52>
    panic("init exiting");
    80002972:	00006517          	auipc	a0,0x6
    80002976:	95650513          	addi	a0,a0,-1706 # 800082c8 <digits+0x288>
    8000297a:	ffffe097          	auipc	ra,0xffffe
    8000297e:	bc4080e7          	jalr	-1084(ra) # 8000053e <panic>
      fileclose(f);
    80002982:	00002097          	auipc	ra,0x2
    80002986:	240080e7          	jalr	576(ra) # 80004bc2 <fileclose>
      p->ofile[fd] = 0;
    8000298a:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000298e:	04a1                	addi	s1,s1,8
    80002990:	01248563          	beq	s1,s2,8000299a <exit+0x58>
    if (p->ofile[fd])
    80002994:	6088                	ld	a0,0(s1)
    80002996:	f575                	bnez	a0,80002982 <exit+0x40>
    80002998:	bfdd                	j	8000298e <exit+0x4c>
  begin_op();
    8000299a:	00002097          	auipc	ra,0x2
    8000299e:	d5c080e7          	jalr	-676(ra) # 800046f6 <begin_op>
  iput(p->cwd);
    800029a2:	1709b503          	ld	a0,368(s3)
    800029a6:	00001097          	auipc	ra,0x1
    800029aa:	538080e7          	jalr	1336(ra) # 80003ede <iput>
  end_op();
    800029ae:	00002097          	auipc	ra,0x2
    800029b2:	dc8080e7          	jalr	-568(ra) # 80004776 <end_op>
  p->cwd = 0;
    800029b6:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    800029ba:	0000f497          	auipc	s1,0xf
    800029be:	e4648493          	addi	s1,s1,-442 # 80011800 <wait_lock>
    800029c2:	8526                	mv	a0,s1
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	220080e7          	jalr	544(ra) # 80000be4 <acquire>
  reparent(p);
    800029cc:	854e                	mv	a0,s3
    800029ce:	00000097          	auipc	ra,0x0
    800029d2:	f1a080e7          	jalr	-230(ra) # 800028e8 <reparent>
  wakeup(p->parent);
    800029d6:	0589b503          	ld	a0,88(s3)
    800029da:	00000097          	auipc	ra,0x0
    800029de:	cf6080e7          	jalr	-778(ra) # 800026d0 <wakeup>
  acquire(&p->lock);
    800029e2:	854e                	mv	a0,s3
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	200080e7          	jalr	512(ra) # 80000be4 <acquire>
  p->xstate = status;
    800029ec:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800029f0:	4795                	li	a5,5
    800029f2:	00f9ac23          	sw	a5,24(s3)
  add_proc(&zombie_head, p, &zombie_lock);
    800029f6:	0000f617          	auipc	a2,0xf
    800029fa:	8aa60613          	addi	a2,a2,-1878 # 800112a0 <zombie_lock>
    800029fe:	85ce                	mv	a1,s3
    80002a00:	00006517          	auipc	a0,0x6
    80002a04:	e8c50513          	addi	a0,a0,-372 # 8000888c <zombie_head>
    80002a08:	fffff097          	auipc	ra,0xfffff
    80002a0c:	030080e7          	jalr	48(ra) # 80001a38 <add_proc>
  release(&wait_lock);
    80002a10:	8526                	mv	a0,s1
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	286080e7          	jalr	646(ra) # 80000c98 <release>
  sched();
    80002a1a:	00000097          	auipc	ra,0x0
    80002a1e:	9b6080e7          	jalr	-1610(ra) # 800023d0 <sched>
  panic("zombie exit");
    80002a22:	00006517          	auipc	a0,0x6
    80002a26:	8b650513          	addi	a0,a0,-1866 # 800082d8 <digits+0x298>
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	b14080e7          	jalr	-1260(ra) # 8000053e <panic>

0000000080002a32 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002a32:	7179                	addi	sp,sp,-48
    80002a34:	f406                	sd	ra,40(sp)
    80002a36:	f022                	sd	s0,32(sp)
    80002a38:	ec26                	sd	s1,24(sp)
    80002a3a:	e84a                	sd	s2,16(sp)
    80002a3c:	e44e                	sd	s3,8(sp)
    80002a3e:	1800                	addi	s0,sp,48
    80002a40:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002a42:	0000f497          	auipc	s1,0xf
    80002a46:	dd648493          	addi	s1,s1,-554 # 80011818 <proc>
    80002a4a:	00015997          	auipc	s3,0x15
    80002a4e:	fce98993          	addi	s3,s3,-50 # 80017a18 <tickslock>
  {
    acquire(&p->lock);
    80002a52:	8526                	mv	a0,s1
    80002a54:	ffffe097          	auipc	ra,0xffffe
    80002a58:	190080e7          	jalr	400(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    80002a5c:	589c                	lw	a5,48(s1)
    80002a5e:	01278d63          	beq	a5,s2,80002a78 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002a62:	8526                	mv	a0,s1
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	234080e7          	jalr	564(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002a6c:	18848493          	addi	s1,s1,392
    80002a70:	ff3491e3          	bne	s1,s3,80002a52 <kill+0x20>
  }
  return -1;
    80002a74:	557d                	li	a0,-1
    80002a76:	a829                	j	80002a90 <kill+0x5e>
      p->killed = 1;
    80002a78:	4785                	li	a5,1
    80002a7a:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002a7c:	4c98                	lw	a4,24(s1)
    80002a7e:	4789                	li	a5,2
    80002a80:	00f70f63          	beq	a4,a5,80002a9e <kill+0x6c>
      release(&p->lock);
    80002a84:	8526                	mv	a0,s1
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	212080e7          	jalr	530(ra) # 80000c98 <release>
      return 0;
    80002a8e:	4501                	li	a0,0
}
    80002a90:	70a2                	ld	ra,40(sp)
    80002a92:	7402                	ld	s0,32(sp)
    80002a94:	64e2                	ld	s1,24(sp)
    80002a96:	6942                	ld	s2,16(sp)
    80002a98:	69a2                	ld	s3,8(sp)
    80002a9a:	6145                	addi	sp,sp,48
    80002a9c:	8082                	ret
        p->state = RUNNABLE;
    80002a9e:	478d                	li	a5,3
    80002aa0:	cc9c                	sw	a5,24(s1)
    80002aa2:	b7cd                	j	80002a84 <kill+0x52>

0000000080002aa4 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002aa4:	7179                	addi	sp,sp,-48
    80002aa6:	f406                	sd	ra,40(sp)
    80002aa8:	f022                	sd	s0,32(sp)
    80002aaa:	ec26                	sd	s1,24(sp)
    80002aac:	e84a                	sd	s2,16(sp)
    80002aae:	e44e                	sd	s3,8(sp)
    80002ab0:	e052                	sd	s4,0(sp)
    80002ab2:	1800                	addi	s0,sp,48
    80002ab4:	84aa                	mv	s1,a0
    80002ab6:	892e                	mv	s2,a1
    80002ab8:	89b2                	mv	s3,a2
    80002aba:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	286080e7          	jalr	646(ra) # 80001d42 <myproc>
  if (user_dst)
    80002ac4:	c08d                	beqz	s1,80002ae6 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002ac6:	86d2                	mv	a3,s4
    80002ac8:	864e                	mv	a2,s3
    80002aca:	85ca                	mv	a1,s2
    80002acc:	7928                	ld	a0,112(a0)
    80002ace:	fffff097          	auipc	ra,0xfffff
    80002ad2:	bb6080e7          	jalr	-1098(ra) # 80001684 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002ad6:	70a2                	ld	ra,40(sp)
    80002ad8:	7402                	ld	s0,32(sp)
    80002ada:	64e2                	ld	s1,24(sp)
    80002adc:	6942                	ld	s2,16(sp)
    80002ade:	69a2                	ld	s3,8(sp)
    80002ae0:	6a02                	ld	s4,0(sp)
    80002ae2:	6145                	addi	sp,sp,48
    80002ae4:	8082                	ret
    memmove((char *)dst, src, len);
    80002ae6:	000a061b          	sext.w	a2,s4
    80002aea:	85ce                	mv	a1,s3
    80002aec:	854a                	mv	a0,s2
    80002aee:	ffffe097          	auipc	ra,0xffffe
    80002af2:	264080e7          	jalr	612(ra) # 80000d52 <memmove>
    return 0;
    80002af6:	8526                	mv	a0,s1
    80002af8:	bff9                	j	80002ad6 <either_copyout+0x32>

0000000080002afa <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002afa:	7179                	addi	sp,sp,-48
    80002afc:	f406                	sd	ra,40(sp)
    80002afe:	f022                	sd	s0,32(sp)
    80002b00:	ec26                	sd	s1,24(sp)
    80002b02:	e84a                	sd	s2,16(sp)
    80002b04:	e44e                	sd	s3,8(sp)
    80002b06:	e052                	sd	s4,0(sp)
    80002b08:	1800                	addi	s0,sp,48
    80002b0a:	892a                	mv	s2,a0
    80002b0c:	84ae                	mv	s1,a1
    80002b0e:	89b2                	mv	s3,a2
    80002b10:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002b12:	fffff097          	auipc	ra,0xfffff
    80002b16:	230080e7          	jalr	560(ra) # 80001d42 <myproc>
  if (user_src)
    80002b1a:	c08d                	beqz	s1,80002b3c <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002b1c:	86d2                	mv	a3,s4
    80002b1e:	864e                	mv	a2,s3
    80002b20:	85ca                	mv	a1,s2
    80002b22:	7928                	ld	a0,112(a0)
    80002b24:	fffff097          	auipc	ra,0xfffff
    80002b28:	bec080e7          	jalr	-1044(ra) # 80001710 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002b2c:	70a2                	ld	ra,40(sp)
    80002b2e:	7402                	ld	s0,32(sp)
    80002b30:	64e2                	ld	s1,24(sp)
    80002b32:	6942                	ld	s2,16(sp)
    80002b34:	69a2                	ld	s3,8(sp)
    80002b36:	6a02                	ld	s4,0(sp)
    80002b38:	6145                	addi	sp,sp,48
    80002b3a:	8082                	ret
    memmove(dst, (char *)src, len);
    80002b3c:	000a061b          	sext.w	a2,s4
    80002b40:	85ce                	mv	a1,s3
    80002b42:	854a                	mv	a0,s2
    80002b44:	ffffe097          	auipc	ra,0xffffe
    80002b48:	20e080e7          	jalr	526(ra) # 80000d52 <memmove>
    return 0;
    80002b4c:	8526                	mv	a0,s1
    80002b4e:	bff9                	j	80002b2c <either_copyin+0x32>

0000000080002b50 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002b50:	715d                	addi	sp,sp,-80
    80002b52:	e486                	sd	ra,72(sp)
    80002b54:	e0a2                	sd	s0,64(sp)
    80002b56:	fc26                	sd	s1,56(sp)
    80002b58:	f84a                	sd	s2,48(sp)
    80002b5a:	f44e                	sd	s3,40(sp)
    80002b5c:	f052                	sd	s4,32(sp)
    80002b5e:	ec56                	sd	s5,24(sp)
    80002b60:	e85a                	sd	s6,16(sp)
    80002b62:	e45e                	sd	s7,8(sp)
    80002b64:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002b66:	00005517          	auipc	a0,0x5
    80002b6a:	56a50513          	addi	a0,a0,1386 # 800080d0 <digits+0x90>
    80002b6e:	ffffe097          	auipc	ra,0xffffe
    80002b72:	a1a080e7          	jalr	-1510(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002b76:	0000f497          	auipc	s1,0xf
    80002b7a:	e1a48493          	addi	s1,s1,-486 # 80011990 <proc+0x178>
    80002b7e:	00015917          	auipc	s2,0x15
    80002b82:	01290913          	addi	s2,s2,18 # 80017b90 <bcache+0x160>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b86:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002b88:	00005997          	auipc	s3,0x5
    80002b8c:	76098993          	addi	s3,s3,1888 # 800082e8 <digits+0x2a8>
    printf("%d %s %s", p->pid, state, p->name);
    80002b90:	00005a97          	auipc	s5,0x5
    80002b94:	760a8a93          	addi	s5,s5,1888 # 800082f0 <digits+0x2b0>
    printf("\n");
    80002b98:	00005a17          	auipc	s4,0x5
    80002b9c:	538a0a13          	addi	s4,s4,1336 # 800080d0 <digits+0x90>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ba0:	00005b97          	auipc	s7,0x5
    80002ba4:	778b8b93          	addi	s7,s7,1912 # 80008318 <states.1761>
    80002ba8:	a00d                	j	80002bca <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002baa:	eb86a583          	lw	a1,-328(a3)
    80002bae:	8556                	mv	a0,s5
    80002bb0:	ffffe097          	auipc	ra,0xffffe
    80002bb4:	9d8080e7          	jalr	-1576(ra) # 80000588 <printf>
    printf("\n");
    80002bb8:	8552                	mv	a0,s4
    80002bba:	ffffe097          	auipc	ra,0xffffe
    80002bbe:	9ce080e7          	jalr	-1586(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002bc2:	18848493          	addi	s1,s1,392
    80002bc6:	03248163          	beq	s1,s2,80002be8 <procdump+0x98>
    if (p->state == UNUSED)
    80002bca:	86a6                	mv	a3,s1
    80002bcc:	ea04a783          	lw	a5,-352(s1)
    80002bd0:	dbed                	beqz	a5,80002bc2 <procdump+0x72>
      state = "???";
    80002bd2:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002bd4:	fcfb6be3          	bltu	s6,a5,80002baa <procdump+0x5a>
    80002bd8:	1782                	slli	a5,a5,0x20
    80002bda:	9381                	srli	a5,a5,0x20
    80002bdc:	078e                	slli	a5,a5,0x3
    80002bde:	97de                	add	a5,a5,s7
    80002be0:	6390                	ld	a2,0(a5)
    80002be2:	f661                	bnez	a2,80002baa <procdump+0x5a>
      state = "???";
    80002be4:	864e                	mv	a2,s3
    80002be6:	b7d1                	j	80002baa <procdump+0x5a>
  }
}
    80002be8:	60a6                	ld	ra,72(sp)
    80002bea:	6406                	ld	s0,64(sp)
    80002bec:	74e2                	ld	s1,56(sp)
    80002bee:	7942                	ld	s2,48(sp)
    80002bf0:	79a2                	ld	s3,40(sp)
    80002bf2:	7a02                	ld	s4,32(sp)
    80002bf4:	6ae2                	ld	s5,24(sp)
    80002bf6:	6b42                	ld	s6,16(sp)
    80002bf8:	6ba2                	ld	s7,8(sp)
    80002bfa:	6161                	addi	sp,sp,80
    80002bfc:	8082                	ret

0000000080002bfe <set_cpu>:

int set_cpu(int cpu_num)
{
    80002bfe:	1101                	addi	sp,sp,-32
    80002c00:	ec06                	sd	ra,24(sp)
    80002c02:	e822                	sd	s0,16(sp)
    80002c04:	e426                	sd	s1,8(sp)
    80002c06:	1000                	addi	s0,sp,32
    80002c08:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c0a:	fffff097          	auipc	ra,0xfffff
    80002c0e:	138080e7          	jalr	312(ra) # 80001d42 <myproc>
  if (cas(&p->cpu, p->cpu, cpu_num) != 0)
    80002c12:	8626                	mv	a2,s1
    80002c14:	594c                	lw	a1,52(a0)
    80002c16:	03450513          	addi	a0,a0,52
    80002c1a:	00004097          	auipc	ra,0x4
    80002c1e:	c9c080e7          	jalr	-868(ra) # 800068b6 <cas>
    80002c22:	e919                	bnez	a0,80002c38 <set_cpu+0x3a>
    return -1;
  yield();
    80002c24:	00000097          	auipc	ra,0x0
    80002c28:	8a2080e7          	jalr	-1886(ra) # 800024c6 <yield>
  return cpu_num;
    80002c2c:	8526                	mv	a0,s1
}
    80002c2e:	60e2                	ld	ra,24(sp)
    80002c30:	6442                	ld	s0,16(sp)
    80002c32:	64a2                	ld	s1,8(sp)
    80002c34:	6105                	addi	sp,sp,32
    80002c36:	8082                	ret
    return -1;
    80002c38:	557d                	li	a0,-1
    80002c3a:	bfd5                	j	80002c2e <set_cpu+0x30>

0000000080002c3c <get_cpu>:

int get_cpu()
{
    80002c3c:	1101                	addi	sp,sp,-32
    80002c3e:	ec06                	sd	ra,24(sp)
    80002c40:	e822                	sd	s0,16(sp)
    80002c42:	e426                	sd	s1,8(sp)
    80002c44:	e04a                	sd	s2,0(sp)
    80002c46:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002c48:	fffff097          	auipc	ra,0xfffff
    80002c4c:	0fa080e7          	jalr	250(ra) # 80001d42 <myproc>
    80002c50:	84aa                	mv	s1,a0
  int cpu_num = -1;
  acquire(&p->lock);
    80002c52:	ffffe097          	auipc	ra,0xffffe
    80002c56:	f92080e7          	jalr	-110(ra) # 80000be4 <acquire>
  cpu_num = p->cpu;
    80002c5a:	0344a903          	lw	s2,52(s1)
  release(&p->lock);
    80002c5e:	8526                	mv	a0,s1
    80002c60:	ffffe097          	auipc	ra,0xffffe
    80002c64:	038080e7          	jalr	56(ra) # 80000c98 <release>
  return cpu_num;
}
    80002c68:	854a                	mv	a0,s2
    80002c6a:	60e2                	ld	ra,24(sp)
    80002c6c:	6442                	ld	s0,16(sp)
    80002c6e:	64a2                	ld	s1,8(sp)
    80002c70:	6902                	ld	s2,0(sp)
    80002c72:	6105                	addi	sp,sp,32
    80002c74:	8082                	ret

0000000080002c76 <swtch>:
    80002c76:	00153023          	sd	ra,0(a0)
    80002c7a:	00253423          	sd	sp,8(a0)
    80002c7e:	e900                	sd	s0,16(a0)
    80002c80:	ed04                	sd	s1,24(a0)
    80002c82:	03253023          	sd	s2,32(a0)
    80002c86:	03353423          	sd	s3,40(a0)
    80002c8a:	03453823          	sd	s4,48(a0)
    80002c8e:	03553c23          	sd	s5,56(a0)
    80002c92:	05653023          	sd	s6,64(a0)
    80002c96:	05753423          	sd	s7,72(a0)
    80002c9a:	05853823          	sd	s8,80(a0)
    80002c9e:	05953c23          	sd	s9,88(a0)
    80002ca2:	07a53023          	sd	s10,96(a0)
    80002ca6:	07b53423          	sd	s11,104(a0)
    80002caa:	0005b083          	ld	ra,0(a1)
    80002cae:	0085b103          	ld	sp,8(a1)
    80002cb2:	6980                	ld	s0,16(a1)
    80002cb4:	6d84                	ld	s1,24(a1)
    80002cb6:	0205b903          	ld	s2,32(a1)
    80002cba:	0285b983          	ld	s3,40(a1)
    80002cbe:	0305ba03          	ld	s4,48(a1)
    80002cc2:	0385ba83          	ld	s5,56(a1)
    80002cc6:	0405bb03          	ld	s6,64(a1)
    80002cca:	0485bb83          	ld	s7,72(a1)
    80002cce:	0505bc03          	ld	s8,80(a1)
    80002cd2:	0585bc83          	ld	s9,88(a1)
    80002cd6:	0605bd03          	ld	s10,96(a1)
    80002cda:	0685bd83          	ld	s11,104(a1)
    80002cde:	8082                	ret

0000000080002ce0 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002ce0:	1141                	addi	sp,sp,-16
    80002ce2:	e406                	sd	ra,8(sp)
    80002ce4:	e022                	sd	s0,0(sp)
    80002ce6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002ce8:	00005597          	auipc	a1,0x5
    80002cec:	66058593          	addi	a1,a1,1632 # 80008348 <states.1761+0x30>
    80002cf0:	00015517          	auipc	a0,0x15
    80002cf4:	d2850513          	addi	a0,a0,-728 # 80017a18 <tickslock>
    80002cf8:	ffffe097          	auipc	ra,0xffffe
    80002cfc:	e5c080e7          	jalr	-420(ra) # 80000b54 <initlock>
}
    80002d00:	60a2                	ld	ra,8(sp)
    80002d02:	6402                	ld	s0,0(sp)
    80002d04:	0141                	addi	sp,sp,16
    80002d06:	8082                	ret

0000000080002d08 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002d08:	1141                	addi	sp,sp,-16
    80002d0a:	e422                	sd	s0,8(sp)
    80002d0c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d0e:	00003797          	auipc	a5,0x3
    80002d12:	4d278793          	addi	a5,a5,1234 # 800061e0 <kernelvec>
    80002d16:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002d1a:	6422                	ld	s0,8(sp)
    80002d1c:	0141                	addi	sp,sp,16
    80002d1e:	8082                	ret

0000000080002d20 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002d20:	1141                	addi	sp,sp,-16
    80002d22:	e406                	sd	ra,8(sp)
    80002d24:	e022                	sd	s0,0(sp)
    80002d26:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002d28:	fffff097          	auipc	ra,0xfffff
    80002d2c:	01a080e7          	jalr	26(ra) # 80001d42 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d30:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002d34:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d36:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002d3a:	00004617          	auipc	a2,0x4
    80002d3e:	2c660613          	addi	a2,a2,710 # 80007000 <_trampoline>
    80002d42:	00004697          	auipc	a3,0x4
    80002d46:	2be68693          	addi	a3,a3,702 # 80007000 <_trampoline>
    80002d4a:	8e91                	sub	a3,a3,a2
    80002d4c:	040007b7          	lui	a5,0x4000
    80002d50:	17fd                	addi	a5,a5,-1
    80002d52:	07b2                	slli	a5,a5,0xc
    80002d54:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d56:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d5a:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d5c:	180026f3          	csrr	a3,satp
    80002d60:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d62:	7d38                	ld	a4,120(a0)
    80002d64:	7134                	ld	a3,96(a0)
    80002d66:	6585                	lui	a1,0x1
    80002d68:	96ae                	add	a3,a3,a1
    80002d6a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d6c:	7d38                	ld	a4,120(a0)
    80002d6e:	00000697          	auipc	a3,0x0
    80002d72:	13868693          	addi	a3,a3,312 # 80002ea6 <usertrap>
    80002d76:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d78:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d7a:	8692                	mv	a3,tp
    80002d7c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d7e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d82:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d86:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d8a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d8e:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d90:	6f18                	ld	a4,24(a4)
    80002d92:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d96:	792c                	ld	a1,112(a0)
    80002d98:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002d9a:	00004717          	auipc	a4,0x4
    80002d9e:	2f670713          	addi	a4,a4,758 # 80007090 <userret>
    80002da2:	8f11                	sub	a4,a4,a2
    80002da4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002da6:	577d                	li	a4,-1
    80002da8:	177e                	slli	a4,a4,0x3f
    80002daa:	8dd9                	or	a1,a1,a4
    80002dac:	02000537          	lui	a0,0x2000
    80002db0:	157d                	addi	a0,a0,-1
    80002db2:	0536                	slli	a0,a0,0xd
    80002db4:	9782                	jalr	a5
}
    80002db6:	60a2                	ld	ra,8(sp)
    80002db8:	6402                	ld	s0,0(sp)
    80002dba:	0141                	addi	sp,sp,16
    80002dbc:	8082                	ret

0000000080002dbe <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002dbe:	1101                	addi	sp,sp,-32
    80002dc0:	ec06                	sd	ra,24(sp)
    80002dc2:	e822                	sd	s0,16(sp)
    80002dc4:	e426                	sd	s1,8(sp)
    80002dc6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002dc8:	00015497          	auipc	s1,0x15
    80002dcc:	c5048493          	addi	s1,s1,-944 # 80017a18 <tickslock>
    80002dd0:	8526                	mv	a0,s1
    80002dd2:	ffffe097          	auipc	ra,0xffffe
    80002dd6:	e12080e7          	jalr	-494(ra) # 80000be4 <acquire>
  ticks++;
    80002dda:	00006517          	auipc	a0,0x6
    80002dde:	25650513          	addi	a0,a0,598 # 80009030 <ticks>
    80002de2:	411c                	lw	a5,0(a0)
    80002de4:	2785                	addiw	a5,a5,1
    80002de6:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002de8:	00000097          	auipc	ra,0x0
    80002dec:	8e8080e7          	jalr	-1816(ra) # 800026d0 <wakeup>
  release(&tickslock);
    80002df0:	8526                	mv	a0,s1
    80002df2:	ffffe097          	auipc	ra,0xffffe
    80002df6:	ea6080e7          	jalr	-346(ra) # 80000c98 <release>
}
    80002dfa:	60e2                	ld	ra,24(sp)
    80002dfc:	6442                	ld	s0,16(sp)
    80002dfe:	64a2                	ld	s1,8(sp)
    80002e00:	6105                	addi	sp,sp,32
    80002e02:	8082                	ret

0000000080002e04 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002e04:	1101                	addi	sp,sp,-32
    80002e06:	ec06                	sd	ra,24(sp)
    80002e08:	e822                	sd	s0,16(sp)
    80002e0a:	e426                	sd	s1,8(sp)
    80002e0c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e0e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002e12:	00074d63          	bltz	a4,80002e2c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002e16:	57fd                	li	a5,-1
    80002e18:	17fe                	slli	a5,a5,0x3f
    80002e1a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002e1c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002e1e:	06f70363          	beq	a4,a5,80002e84 <devintr+0x80>
  }
}
    80002e22:	60e2                	ld	ra,24(sp)
    80002e24:	6442                	ld	s0,16(sp)
    80002e26:	64a2                	ld	s1,8(sp)
    80002e28:	6105                	addi	sp,sp,32
    80002e2a:	8082                	ret
     (scause & 0xff) == 9){
    80002e2c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002e30:	46a5                	li	a3,9
    80002e32:	fed792e3          	bne	a5,a3,80002e16 <devintr+0x12>
    int irq = plic_claim();
    80002e36:	00003097          	auipc	ra,0x3
    80002e3a:	4b2080e7          	jalr	1202(ra) # 800062e8 <plic_claim>
    80002e3e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002e40:	47a9                	li	a5,10
    80002e42:	02f50763          	beq	a0,a5,80002e70 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002e46:	4785                	li	a5,1
    80002e48:	02f50963          	beq	a0,a5,80002e7a <devintr+0x76>
    return 1;
    80002e4c:	4505                	li	a0,1
    } else if(irq){
    80002e4e:	d8f1                	beqz	s1,80002e22 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e50:	85a6                	mv	a1,s1
    80002e52:	00005517          	auipc	a0,0x5
    80002e56:	4fe50513          	addi	a0,a0,1278 # 80008350 <states.1761+0x38>
    80002e5a:	ffffd097          	auipc	ra,0xffffd
    80002e5e:	72e080e7          	jalr	1838(ra) # 80000588 <printf>
      plic_complete(irq);
    80002e62:	8526                	mv	a0,s1
    80002e64:	00003097          	auipc	ra,0x3
    80002e68:	4a8080e7          	jalr	1192(ra) # 8000630c <plic_complete>
    return 1;
    80002e6c:	4505                	li	a0,1
    80002e6e:	bf55                	j	80002e22 <devintr+0x1e>
      uartintr();
    80002e70:	ffffe097          	auipc	ra,0xffffe
    80002e74:	b38080e7          	jalr	-1224(ra) # 800009a8 <uartintr>
    80002e78:	b7ed                	j	80002e62 <devintr+0x5e>
      virtio_disk_intr();
    80002e7a:	00004097          	auipc	ra,0x4
    80002e7e:	972080e7          	jalr	-1678(ra) # 800067ec <virtio_disk_intr>
    80002e82:	b7c5                	j	80002e62 <devintr+0x5e>
    if(cpuid() == 0){
    80002e84:	fffff097          	auipc	ra,0xfffff
    80002e88:	e8a080e7          	jalr	-374(ra) # 80001d0e <cpuid>
    80002e8c:	c901                	beqz	a0,80002e9c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e8e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e92:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e94:	14479073          	csrw	sip,a5
    return 2;
    80002e98:	4509                	li	a0,2
    80002e9a:	b761                	j	80002e22 <devintr+0x1e>
      clockintr();
    80002e9c:	00000097          	auipc	ra,0x0
    80002ea0:	f22080e7          	jalr	-222(ra) # 80002dbe <clockintr>
    80002ea4:	b7ed                	j	80002e8e <devintr+0x8a>

0000000080002ea6 <usertrap>:
{
    80002ea6:	1101                	addi	sp,sp,-32
    80002ea8:	ec06                	sd	ra,24(sp)
    80002eaa:	e822                	sd	s0,16(sp)
    80002eac:	e426                	sd	s1,8(sp)
    80002eae:	e04a                	sd	s2,0(sp)
    80002eb0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eb2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002eb6:	1007f793          	andi	a5,a5,256
    80002eba:	e3ad                	bnez	a5,80002f1c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ebc:	00003797          	auipc	a5,0x3
    80002ec0:	32478793          	addi	a5,a5,804 # 800061e0 <kernelvec>
    80002ec4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	e7a080e7          	jalr	-390(ra) # 80001d42 <myproc>
    80002ed0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ed2:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ed4:	14102773          	csrr	a4,sepc
    80002ed8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eda:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ede:	47a1                	li	a5,8
    80002ee0:	04f71c63          	bne	a4,a5,80002f38 <usertrap+0x92>
    if(p->killed)
    80002ee4:	551c                	lw	a5,40(a0)
    80002ee6:	e3b9                	bnez	a5,80002f2c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002ee8:	7cb8                	ld	a4,120(s1)
    80002eea:	6f1c                	ld	a5,24(a4)
    80002eec:	0791                	addi	a5,a5,4
    80002eee:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ef0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ef4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ef8:	10079073          	csrw	sstatus,a5
    syscall();
    80002efc:	00000097          	auipc	ra,0x0
    80002f00:	2e0080e7          	jalr	736(ra) # 800031dc <syscall>
  if(p->killed)
    80002f04:	549c                	lw	a5,40(s1)
    80002f06:	ebc1                	bnez	a5,80002f96 <usertrap+0xf0>
  usertrapret();
    80002f08:	00000097          	auipc	ra,0x0
    80002f0c:	e18080e7          	jalr	-488(ra) # 80002d20 <usertrapret>
}
    80002f10:	60e2                	ld	ra,24(sp)
    80002f12:	6442                	ld	s0,16(sp)
    80002f14:	64a2                	ld	s1,8(sp)
    80002f16:	6902                	ld	s2,0(sp)
    80002f18:	6105                	addi	sp,sp,32
    80002f1a:	8082                	ret
    panic("usertrap: not from user mode");
    80002f1c:	00005517          	auipc	a0,0x5
    80002f20:	45450513          	addi	a0,a0,1108 # 80008370 <states.1761+0x58>
    80002f24:	ffffd097          	auipc	ra,0xffffd
    80002f28:	61a080e7          	jalr	1562(ra) # 8000053e <panic>
      exit(-1);
    80002f2c:	557d                	li	a0,-1
    80002f2e:	00000097          	auipc	ra,0x0
    80002f32:	a14080e7          	jalr	-1516(ra) # 80002942 <exit>
    80002f36:	bf4d                	j	80002ee8 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002f38:	00000097          	auipc	ra,0x0
    80002f3c:	ecc080e7          	jalr	-308(ra) # 80002e04 <devintr>
    80002f40:	892a                	mv	s2,a0
    80002f42:	c501                	beqz	a0,80002f4a <usertrap+0xa4>
  if(p->killed)
    80002f44:	549c                	lw	a5,40(s1)
    80002f46:	c3a1                	beqz	a5,80002f86 <usertrap+0xe0>
    80002f48:	a815                	j	80002f7c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f4a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f4e:	5890                	lw	a2,48(s1)
    80002f50:	00005517          	auipc	a0,0x5
    80002f54:	44050513          	addi	a0,a0,1088 # 80008390 <states.1761+0x78>
    80002f58:	ffffd097          	auipc	ra,0xffffd
    80002f5c:	630080e7          	jalr	1584(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f60:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f64:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f68:	00005517          	auipc	a0,0x5
    80002f6c:	45850513          	addi	a0,a0,1112 # 800083c0 <states.1761+0xa8>
    80002f70:	ffffd097          	auipc	ra,0xffffd
    80002f74:	618080e7          	jalr	1560(ra) # 80000588 <printf>
    p->killed = 1;
    80002f78:	4785                	li	a5,1
    80002f7a:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002f7c:	557d                	li	a0,-1
    80002f7e:	00000097          	auipc	ra,0x0
    80002f82:	9c4080e7          	jalr	-1596(ra) # 80002942 <exit>
  if(which_dev == 2)
    80002f86:	4789                	li	a5,2
    80002f88:	f8f910e3          	bne	s2,a5,80002f08 <usertrap+0x62>
    yield();
    80002f8c:	fffff097          	auipc	ra,0xfffff
    80002f90:	53a080e7          	jalr	1338(ra) # 800024c6 <yield>
    80002f94:	bf95                	j	80002f08 <usertrap+0x62>
  int which_dev = 0;
    80002f96:	4901                	li	s2,0
    80002f98:	b7d5                	j	80002f7c <usertrap+0xd6>

0000000080002f9a <kerneltrap>:
{
    80002f9a:	7179                	addi	sp,sp,-48
    80002f9c:	f406                	sd	ra,40(sp)
    80002f9e:	f022                	sd	s0,32(sp)
    80002fa0:	ec26                	sd	s1,24(sp)
    80002fa2:	e84a                	sd	s2,16(sp)
    80002fa4:	e44e                	sd	s3,8(sp)
    80002fa6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fa8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fac:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fb0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002fb4:	1004f793          	andi	a5,s1,256
    80002fb8:	cb85                	beqz	a5,80002fe8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fba:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002fbe:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002fc0:	ef85                	bnez	a5,80002ff8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002fc2:	00000097          	auipc	ra,0x0
    80002fc6:	e42080e7          	jalr	-446(ra) # 80002e04 <devintr>
    80002fca:	cd1d                	beqz	a0,80003008 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002fcc:	4789                	li	a5,2
    80002fce:	06f50a63          	beq	a0,a5,80003042 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002fd2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fd6:	10049073          	csrw	sstatus,s1
}
    80002fda:	70a2                	ld	ra,40(sp)
    80002fdc:	7402                	ld	s0,32(sp)
    80002fde:	64e2                	ld	s1,24(sp)
    80002fe0:	6942                	ld	s2,16(sp)
    80002fe2:	69a2                	ld	s3,8(sp)
    80002fe4:	6145                	addi	sp,sp,48
    80002fe6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002fe8:	00005517          	auipc	a0,0x5
    80002fec:	3f850513          	addi	a0,a0,1016 # 800083e0 <states.1761+0xc8>
    80002ff0:	ffffd097          	auipc	ra,0xffffd
    80002ff4:	54e080e7          	jalr	1358(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002ff8:	00005517          	auipc	a0,0x5
    80002ffc:	41050513          	addi	a0,a0,1040 # 80008408 <states.1761+0xf0>
    80003000:	ffffd097          	auipc	ra,0xffffd
    80003004:	53e080e7          	jalr	1342(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003008:	85ce                	mv	a1,s3
    8000300a:	00005517          	auipc	a0,0x5
    8000300e:	41e50513          	addi	a0,a0,1054 # 80008428 <states.1761+0x110>
    80003012:	ffffd097          	auipc	ra,0xffffd
    80003016:	576080e7          	jalr	1398(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000301a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000301e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003022:	00005517          	auipc	a0,0x5
    80003026:	41650513          	addi	a0,a0,1046 # 80008438 <states.1761+0x120>
    8000302a:	ffffd097          	auipc	ra,0xffffd
    8000302e:	55e080e7          	jalr	1374(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003032:	00005517          	auipc	a0,0x5
    80003036:	41e50513          	addi	a0,a0,1054 # 80008450 <states.1761+0x138>
    8000303a:	ffffd097          	auipc	ra,0xffffd
    8000303e:	504080e7          	jalr	1284(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003042:	fffff097          	auipc	ra,0xfffff
    80003046:	d00080e7          	jalr	-768(ra) # 80001d42 <myproc>
    8000304a:	d541                	beqz	a0,80002fd2 <kerneltrap+0x38>
    8000304c:	fffff097          	auipc	ra,0xfffff
    80003050:	cf6080e7          	jalr	-778(ra) # 80001d42 <myproc>
    80003054:	4d18                	lw	a4,24(a0)
    80003056:	4791                	li	a5,4
    80003058:	f6f71de3          	bne	a4,a5,80002fd2 <kerneltrap+0x38>
    yield();
    8000305c:	fffff097          	auipc	ra,0xfffff
    80003060:	46a080e7          	jalr	1130(ra) # 800024c6 <yield>
    80003064:	b7bd                	j	80002fd2 <kerneltrap+0x38>

0000000080003066 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003066:	1101                	addi	sp,sp,-32
    80003068:	ec06                	sd	ra,24(sp)
    8000306a:	e822                	sd	s0,16(sp)
    8000306c:	e426                	sd	s1,8(sp)
    8000306e:	1000                	addi	s0,sp,32
    80003070:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003072:	fffff097          	auipc	ra,0xfffff
    80003076:	cd0080e7          	jalr	-816(ra) # 80001d42 <myproc>
  switch (n) {
    8000307a:	4795                	li	a5,5
    8000307c:	0497e163          	bltu	a5,s1,800030be <argraw+0x58>
    80003080:	048a                	slli	s1,s1,0x2
    80003082:	00005717          	auipc	a4,0x5
    80003086:	40670713          	addi	a4,a4,1030 # 80008488 <states.1761+0x170>
    8000308a:	94ba                	add	s1,s1,a4
    8000308c:	409c                	lw	a5,0(s1)
    8000308e:	97ba                	add	a5,a5,a4
    80003090:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003092:	7d3c                	ld	a5,120(a0)
    80003094:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003096:	60e2                	ld	ra,24(sp)
    80003098:	6442                	ld	s0,16(sp)
    8000309a:	64a2                	ld	s1,8(sp)
    8000309c:	6105                	addi	sp,sp,32
    8000309e:	8082                	ret
    return p->trapframe->a1;
    800030a0:	7d3c                	ld	a5,120(a0)
    800030a2:	7fa8                	ld	a0,120(a5)
    800030a4:	bfcd                	j	80003096 <argraw+0x30>
    return p->trapframe->a2;
    800030a6:	7d3c                	ld	a5,120(a0)
    800030a8:	63c8                	ld	a0,128(a5)
    800030aa:	b7f5                	j	80003096 <argraw+0x30>
    return p->trapframe->a3;
    800030ac:	7d3c                	ld	a5,120(a0)
    800030ae:	67c8                	ld	a0,136(a5)
    800030b0:	b7dd                	j	80003096 <argraw+0x30>
    return p->trapframe->a4;
    800030b2:	7d3c                	ld	a5,120(a0)
    800030b4:	6bc8                	ld	a0,144(a5)
    800030b6:	b7c5                	j	80003096 <argraw+0x30>
    return p->trapframe->a5;
    800030b8:	7d3c                	ld	a5,120(a0)
    800030ba:	6fc8                	ld	a0,152(a5)
    800030bc:	bfe9                	j	80003096 <argraw+0x30>
  panic("argraw");
    800030be:	00005517          	auipc	a0,0x5
    800030c2:	3a250513          	addi	a0,a0,930 # 80008460 <states.1761+0x148>
    800030c6:	ffffd097          	auipc	ra,0xffffd
    800030ca:	478080e7          	jalr	1144(ra) # 8000053e <panic>

00000000800030ce <fetchaddr>:
{
    800030ce:	1101                	addi	sp,sp,-32
    800030d0:	ec06                	sd	ra,24(sp)
    800030d2:	e822                	sd	s0,16(sp)
    800030d4:	e426                	sd	s1,8(sp)
    800030d6:	e04a                	sd	s2,0(sp)
    800030d8:	1000                	addi	s0,sp,32
    800030da:	84aa                	mv	s1,a0
    800030dc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800030de:	fffff097          	auipc	ra,0xfffff
    800030e2:	c64080e7          	jalr	-924(ra) # 80001d42 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800030e6:	753c                	ld	a5,104(a0)
    800030e8:	02f4f863          	bgeu	s1,a5,80003118 <fetchaddr+0x4a>
    800030ec:	00848713          	addi	a4,s1,8
    800030f0:	02e7e663          	bltu	a5,a4,8000311c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800030f4:	46a1                	li	a3,8
    800030f6:	8626                	mv	a2,s1
    800030f8:	85ca                	mv	a1,s2
    800030fa:	7928                	ld	a0,112(a0)
    800030fc:	ffffe097          	auipc	ra,0xffffe
    80003100:	614080e7          	jalr	1556(ra) # 80001710 <copyin>
    80003104:	00a03533          	snez	a0,a0
    80003108:	40a00533          	neg	a0,a0
}
    8000310c:	60e2                	ld	ra,24(sp)
    8000310e:	6442                	ld	s0,16(sp)
    80003110:	64a2                	ld	s1,8(sp)
    80003112:	6902                	ld	s2,0(sp)
    80003114:	6105                	addi	sp,sp,32
    80003116:	8082                	ret
    return -1;
    80003118:	557d                	li	a0,-1
    8000311a:	bfcd                	j	8000310c <fetchaddr+0x3e>
    8000311c:	557d                	li	a0,-1
    8000311e:	b7fd                	j	8000310c <fetchaddr+0x3e>

0000000080003120 <fetchstr>:
{
    80003120:	7179                	addi	sp,sp,-48
    80003122:	f406                	sd	ra,40(sp)
    80003124:	f022                	sd	s0,32(sp)
    80003126:	ec26                	sd	s1,24(sp)
    80003128:	e84a                	sd	s2,16(sp)
    8000312a:	e44e                	sd	s3,8(sp)
    8000312c:	1800                	addi	s0,sp,48
    8000312e:	892a                	mv	s2,a0
    80003130:	84ae                	mv	s1,a1
    80003132:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003134:	fffff097          	auipc	ra,0xfffff
    80003138:	c0e080e7          	jalr	-1010(ra) # 80001d42 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000313c:	86ce                	mv	a3,s3
    8000313e:	864a                	mv	a2,s2
    80003140:	85a6                	mv	a1,s1
    80003142:	7928                	ld	a0,112(a0)
    80003144:	ffffe097          	auipc	ra,0xffffe
    80003148:	658080e7          	jalr	1624(ra) # 8000179c <copyinstr>
  if(err < 0)
    8000314c:	00054763          	bltz	a0,8000315a <fetchstr+0x3a>
  return strlen(buf);
    80003150:	8526                	mv	a0,s1
    80003152:	ffffe097          	auipc	ra,0xffffe
    80003156:	d24080e7          	jalr	-732(ra) # 80000e76 <strlen>
}
    8000315a:	70a2                	ld	ra,40(sp)
    8000315c:	7402                	ld	s0,32(sp)
    8000315e:	64e2                	ld	s1,24(sp)
    80003160:	6942                	ld	s2,16(sp)
    80003162:	69a2                	ld	s3,8(sp)
    80003164:	6145                	addi	sp,sp,48
    80003166:	8082                	ret

0000000080003168 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003168:	1101                	addi	sp,sp,-32
    8000316a:	ec06                	sd	ra,24(sp)
    8000316c:	e822                	sd	s0,16(sp)
    8000316e:	e426                	sd	s1,8(sp)
    80003170:	1000                	addi	s0,sp,32
    80003172:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003174:	00000097          	auipc	ra,0x0
    80003178:	ef2080e7          	jalr	-270(ra) # 80003066 <argraw>
    8000317c:	c088                	sw	a0,0(s1)
  return 0;
}
    8000317e:	4501                	li	a0,0
    80003180:	60e2                	ld	ra,24(sp)
    80003182:	6442                	ld	s0,16(sp)
    80003184:	64a2                	ld	s1,8(sp)
    80003186:	6105                	addi	sp,sp,32
    80003188:	8082                	ret

000000008000318a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000318a:	1101                	addi	sp,sp,-32
    8000318c:	ec06                	sd	ra,24(sp)
    8000318e:	e822                	sd	s0,16(sp)
    80003190:	e426                	sd	s1,8(sp)
    80003192:	1000                	addi	s0,sp,32
    80003194:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003196:	00000097          	auipc	ra,0x0
    8000319a:	ed0080e7          	jalr	-304(ra) # 80003066 <argraw>
    8000319e:	e088                	sd	a0,0(s1)
  return 0;
}
    800031a0:	4501                	li	a0,0
    800031a2:	60e2                	ld	ra,24(sp)
    800031a4:	6442                	ld	s0,16(sp)
    800031a6:	64a2                	ld	s1,8(sp)
    800031a8:	6105                	addi	sp,sp,32
    800031aa:	8082                	ret

00000000800031ac <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800031ac:	1101                	addi	sp,sp,-32
    800031ae:	ec06                	sd	ra,24(sp)
    800031b0:	e822                	sd	s0,16(sp)
    800031b2:	e426                	sd	s1,8(sp)
    800031b4:	e04a                	sd	s2,0(sp)
    800031b6:	1000                	addi	s0,sp,32
    800031b8:	84ae                	mv	s1,a1
    800031ba:	8932                	mv	s2,a2
  *ip = argraw(n);
    800031bc:	00000097          	auipc	ra,0x0
    800031c0:	eaa080e7          	jalr	-342(ra) # 80003066 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800031c4:	864a                	mv	a2,s2
    800031c6:	85a6                	mv	a1,s1
    800031c8:	00000097          	auipc	ra,0x0
    800031cc:	f58080e7          	jalr	-168(ra) # 80003120 <fetchstr>
}
    800031d0:	60e2                	ld	ra,24(sp)
    800031d2:	6442                	ld	s0,16(sp)
    800031d4:	64a2                	ld	s1,8(sp)
    800031d6:	6902                	ld	s2,0(sp)
    800031d8:	6105                	addi	sp,sp,32
    800031da:	8082                	ret

00000000800031dc <syscall>:
[SYS_set_cpu] sys_set_cpu,
};

void
syscall(void)
{
    800031dc:	1101                	addi	sp,sp,-32
    800031de:	ec06                	sd	ra,24(sp)
    800031e0:	e822                	sd	s0,16(sp)
    800031e2:	e426                	sd	s1,8(sp)
    800031e4:	e04a                	sd	s2,0(sp)
    800031e6:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800031e8:	fffff097          	auipc	ra,0xfffff
    800031ec:	b5a080e7          	jalr	-1190(ra) # 80001d42 <myproc>
    800031f0:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800031f2:	07853903          	ld	s2,120(a0)
    800031f6:	0a893783          	ld	a5,168(s2)
    800031fa:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800031fe:	37fd                	addiw	a5,a5,-1
    80003200:	4759                	li	a4,22
    80003202:	00f76f63          	bltu	a4,a5,80003220 <syscall+0x44>
    80003206:	00369713          	slli	a4,a3,0x3
    8000320a:	00005797          	auipc	a5,0x5
    8000320e:	29678793          	addi	a5,a5,662 # 800084a0 <syscalls>
    80003212:	97ba                	add	a5,a5,a4
    80003214:	639c                	ld	a5,0(a5)
    80003216:	c789                	beqz	a5,80003220 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003218:	9782                	jalr	a5
    8000321a:	06a93823          	sd	a0,112(s2)
    8000321e:	a839                	j	8000323c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003220:	17848613          	addi	a2,s1,376
    80003224:	588c                	lw	a1,48(s1)
    80003226:	00005517          	auipc	a0,0x5
    8000322a:	24250513          	addi	a0,a0,578 # 80008468 <states.1761+0x150>
    8000322e:	ffffd097          	auipc	ra,0xffffd
    80003232:	35a080e7          	jalr	858(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003236:	7cbc                	ld	a5,120(s1)
    80003238:	577d                	li	a4,-1
    8000323a:	fbb8                	sd	a4,112(a5)
  }
}
    8000323c:	60e2                	ld	ra,24(sp)
    8000323e:	6442                	ld	s0,16(sp)
    80003240:	64a2                	ld	s1,8(sp)
    80003242:	6902                	ld	s2,0(sp)
    80003244:	6105                	addi	sp,sp,32
    80003246:	8082                	ret

0000000080003248 <sys_set_cpu>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_set_cpu(void)
{
    80003248:	1101                	addi	sp,sp,-32
    8000324a:	ec06                	sd	ra,24(sp)
    8000324c:	e822                	sd	s0,16(sp)
    8000324e:	1000                	addi	s0,sp,32
  int cpu_num;
  if(argint(0, &cpu_num) < 0)
    80003250:	fec40593          	addi	a1,s0,-20
    80003254:	4501                	li	a0,0
    80003256:	00000097          	auipc	ra,0x0
    8000325a:	f12080e7          	jalr	-238(ra) # 80003168 <argint>
    8000325e:	87aa                	mv	a5,a0
    return -1;
    80003260:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    80003262:	0007c863          	bltz	a5,80003272 <sys_set_cpu+0x2a>
  return set_cpu(cpu_num); 
    80003266:	fec42503          	lw	a0,-20(s0)
    8000326a:	00000097          	auipc	ra,0x0
    8000326e:	994080e7          	jalr	-1644(ra) # 80002bfe <set_cpu>
}
    80003272:	60e2                	ld	ra,24(sp)
    80003274:	6442                	ld	s0,16(sp)
    80003276:	6105                	addi	sp,sp,32
    80003278:	8082                	ret

000000008000327a <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    8000327a:	1141                	addi	sp,sp,-16
    8000327c:	e406                	sd	ra,8(sp)
    8000327e:	e022                	sd	s0,0(sp)
    80003280:	0800                	addi	s0,sp,16
  return get_cpu(); 
    80003282:	00000097          	auipc	ra,0x0
    80003286:	9ba080e7          	jalr	-1606(ra) # 80002c3c <get_cpu>
}
    8000328a:	60a2                	ld	ra,8(sp)
    8000328c:	6402                	ld	s0,0(sp)
    8000328e:	0141                	addi	sp,sp,16
    80003290:	8082                	ret

0000000080003292 <sys_exit>:

uint64
sys_exit(void)
{
    80003292:	1101                	addi	sp,sp,-32
    80003294:	ec06                	sd	ra,24(sp)
    80003296:	e822                	sd	s0,16(sp)
    80003298:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000329a:	fec40593          	addi	a1,s0,-20
    8000329e:	4501                	li	a0,0
    800032a0:	00000097          	auipc	ra,0x0
    800032a4:	ec8080e7          	jalr	-312(ra) # 80003168 <argint>
    return -1;
    800032a8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800032aa:	00054963          	bltz	a0,800032bc <sys_exit+0x2a>
  exit(n);
    800032ae:	fec42503          	lw	a0,-20(s0)
    800032b2:	fffff097          	auipc	ra,0xfffff
    800032b6:	690080e7          	jalr	1680(ra) # 80002942 <exit>
  return 0;  // not reached
    800032ba:	4781                	li	a5,0
}
    800032bc:	853e                	mv	a0,a5
    800032be:	60e2                	ld	ra,24(sp)
    800032c0:	6442                	ld	s0,16(sp)
    800032c2:	6105                	addi	sp,sp,32
    800032c4:	8082                	ret

00000000800032c6 <sys_getpid>:

uint64
sys_getpid(void)
{
    800032c6:	1141                	addi	sp,sp,-16
    800032c8:	e406                	sd	ra,8(sp)
    800032ca:	e022                	sd	s0,0(sp)
    800032cc:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800032ce:	fffff097          	auipc	ra,0xfffff
    800032d2:	a74080e7          	jalr	-1420(ra) # 80001d42 <myproc>
}
    800032d6:	5908                	lw	a0,48(a0)
    800032d8:	60a2                	ld	ra,8(sp)
    800032da:	6402                	ld	s0,0(sp)
    800032dc:	0141                	addi	sp,sp,16
    800032de:	8082                	ret

00000000800032e0 <sys_fork>:

uint64
sys_fork(void)
{
    800032e0:	1141                	addi	sp,sp,-16
    800032e2:	e406                	sd	ra,8(sp)
    800032e4:	e022                	sd	s0,0(sp)
    800032e6:	0800                	addi	s0,sp,16
  return fork();
    800032e8:	fffff097          	auipc	ra,0xfffff
    800032ec:	eb6080e7          	jalr	-330(ra) # 8000219e <fork>
}
    800032f0:	60a2                	ld	ra,8(sp)
    800032f2:	6402                	ld	s0,0(sp)
    800032f4:	0141                	addi	sp,sp,16
    800032f6:	8082                	ret

00000000800032f8 <sys_wait>:

uint64
sys_wait(void)
{
    800032f8:	1101                	addi	sp,sp,-32
    800032fa:	ec06                	sd	ra,24(sp)
    800032fc:	e822                	sd	s0,16(sp)
    800032fe:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003300:	fe840593          	addi	a1,s0,-24
    80003304:	4501                	li	a0,0
    80003306:	00000097          	auipc	ra,0x0
    8000330a:	e84080e7          	jalr	-380(ra) # 8000318a <argaddr>
    8000330e:	87aa                	mv	a5,a0
    return -1;
    80003310:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003312:	0007c863          	bltz	a5,80003322 <sys_wait+0x2a>
  return wait(p);
    80003316:	fe843503          	ld	a0,-24(s0)
    8000331a:	fffff097          	auipc	ra,0xfffff
    8000331e:	28e080e7          	jalr	654(ra) # 800025a8 <wait>
}
    80003322:	60e2                	ld	ra,24(sp)
    80003324:	6442                	ld	s0,16(sp)
    80003326:	6105                	addi	sp,sp,32
    80003328:	8082                	ret

000000008000332a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000332a:	7179                	addi	sp,sp,-48
    8000332c:	f406                	sd	ra,40(sp)
    8000332e:	f022                	sd	s0,32(sp)
    80003330:	ec26                	sd	s1,24(sp)
    80003332:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003334:	fdc40593          	addi	a1,s0,-36
    80003338:	4501                	li	a0,0
    8000333a:	00000097          	auipc	ra,0x0
    8000333e:	e2e080e7          	jalr	-466(ra) # 80003168 <argint>
    80003342:	87aa                	mv	a5,a0
    return -1;
    80003344:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003346:	0207c063          	bltz	a5,80003366 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000334a:	fffff097          	auipc	ra,0xfffff
    8000334e:	9f8080e7          	jalr	-1544(ra) # 80001d42 <myproc>
    80003352:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    80003354:	fdc42503          	lw	a0,-36(s0)
    80003358:	fffff097          	auipc	ra,0xfffff
    8000335c:	dd2080e7          	jalr	-558(ra) # 8000212a <growproc>
    80003360:	00054863          	bltz	a0,80003370 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003364:	8526                	mv	a0,s1
}
    80003366:	70a2                	ld	ra,40(sp)
    80003368:	7402                	ld	s0,32(sp)
    8000336a:	64e2                	ld	s1,24(sp)
    8000336c:	6145                	addi	sp,sp,48
    8000336e:	8082                	ret
    return -1;
    80003370:	557d                	li	a0,-1
    80003372:	bfd5                	j	80003366 <sys_sbrk+0x3c>

0000000080003374 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003374:	7139                	addi	sp,sp,-64
    80003376:	fc06                	sd	ra,56(sp)
    80003378:	f822                	sd	s0,48(sp)
    8000337a:	f426                	sd	s1,40(sp)
    8000337c:	f04a                	sd	s2,32(sp)
    8000337e:	ec4e                	sd	s3,24(sp)
    80003380:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003382:	fcc40593          	addi	a1,s0,-52
    80003386:	4501                	li	a0,0
    80003388:	00000097          	auipc	ra,0x0
    8000338c:	de0080e7          	jalr	-544(ra) # 80003168 <argint>
    return -1;
    80003390:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003392:	06054563          	bltz	a0,800033fc <sys_sleep+0x88>
  acquire(&tickslock);
    80003396:	00014517          	auipc	a0,0x14
    8000339a:	68250513          	addi	a0,a0,1666 # 80017a18 <tickslock>
    8000339e:	ffffe097          	auipc	ra,0xffffe
    800033a2:	846080e7          	jalr	-1978(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800033a6:	00006917          	auipc	s2,0x6
    800033aa:	c8a92903          	lw	s2,-886(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800033ae:	fcc42783          	lw	a5,-52(s0)
    800033b2:	cf85                	beqz	a5,800033ea <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800033b4:	00014997          	auipc	s3,0x14
    800033b8:	66498993          	addi	s3,s3,1636 # 80017a18 <tickslock>
    800033bc:	00006497          	auipc	s1,0x6
    800033c0:	c7448493          	addi	s1,s1,-908 # 80009030 <ticks>
    if(myproc()->killed){
    800033c4:	fffff097          	auipc	ra,0xfffff
    800033c8:	97e080e7          	jalr	-1666(ra) # 80001d42 <myproc>
    800033cc:	551c                	lw	a5,40(a0)
    800033ce:	ef9d                	bnez	a5,8000340c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800033d0:	85ce                	mv	a1,s3
    800033d2:	8526                	mv	a0,s1
    800033d4:	fffff097          	auipc	ra,0xfffff
    800033d8:	156080e7          	jalr	342(ra) # 8000252a <sleep>
  while(ticks - ticks0 < n){
    800033dc:	409c                	lw	a5,0(s1)
    800033de:	412787bb          	subw	a5,a5,s2
    800033e2:	fcc42703          	lw	a4,-52(s0)
    800033e6:	fce7efe3          	bltu	a5,a4,800033c4 <sys_sleep+0x50>
  }
  release(&tickslock);
    800033ea:	00014517          	auipc	a0,0x14
    800033ee:	62e50513          	addi	a0,a0,1582 # 80017a18 <tickslock>
    800033f2:	ffffe097          	auipc	ra,0xffffe
    800033f6:	8a6080e7          	jalr	-1882(ra) # 80000c98 <release>
  return 0;
    800033fa:	4781                	li	a5,0
}
    800033fc:	853e                	mv	a0,a5
    800033fe:	70e2                	ld	ra,56(sp)
    80003400:	7442                	ld	s0,48(sp)
    80003402:	74a2                	ld	s1,40(sp)
    80003404:	7902                	ld	s2,32(sp)
    80003406:	69e2                	ld	s3,24(sp)
    80003408:	6121                	addi	sp,sp,64
    8000340a:	8082                	ret
      release(&tickslock);
    8000340c:	00014517          	auipc	a0,0x14
    80003410:	60c50513          	addi	a0,a0,1548 # 80017a18 <tickslock>
    80003414:	ffffe097          	auipc	ra,0xffffe
    80003418:	884080e7          	jalr	-1916(ra) # 80000c98 <release>
      return -1;
    8000341c:	57fd                	li	a5,-1
    8000341e:	bff9                	j	800033fc <sys_sleep+0x88>

0000000080003420 <sys_kill>:

uint64
sys_kill(void)
{
    80003420:	1101                	addi	sp,sp,-32
    80003422:	ec06                	sd	ra,24(sp)
    80003424:	e822                	sd	s0,16(sp)
    80003426:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003428:	fec40593          	addi	a1,s0,-20
    8000342c:	4501                	li	a0,0
    8000342e:	00000097          	auipc	ra,0x0
    80003432:	d3a080e7          	jalr	-710(ra) # 80003168 <argint>
    80003436:	87aa                	mv	a5,a0
    return -1;
    80003438:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000343a:	0007c863          	bltz	a5,8000344a <sys_kill+0x2a>
  return kill(pid);
    8000343e:	fec42503          	lw	a0,-20(s0)
    80003442:	fffff097          	auipc	ra,0xfffff
    80003446:	5f0080e7          	jalr	1520(ra) # 80002a32 <kill>
}
    8000344a:	60e2                	ld	ra,24(sp)
    8000344c:	6442                	ld	s0,16(sp)
    8000344e:	6105                	addi	sp,sp,32
    80003450:	8082                	ret

0000000080003452 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003452:	1101                	addi	sp,sp,-32
    80003454:	ec06                	sd	ra,24(sp)
    80003456:	e822                	sd	s0,16(sp)
    80003458:	e426                	sd	s1,8(sp)
    8000345a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000345c:	00014517          	auipc	a0,0x14
    80003460:	5bc50513          	addi	a0,a0,1468 # 80017a18 <tickslock>
    80003464:	ffffd097          	auipc	ra,0xffffd
    80003468:	780080e7          	jalr	1920(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000346c:	00006497          	auipc	s1,0x6
    80003470:	bc44a483          	lw	s1,-1084(s1) # 80009030 <ticks>
  release(&tickslock);
    80003474:	00014517          	auipc	a0,0x14
    80003478:	5a450513          	addi	a0,a0,1444 # 80017a18 <tickslock>
    8000347c:	ffffe097          	auipc	ra,0xffffe
    80003480:	81c080e7          	jalr	-2020(ra) # 80000c98 <release>
  return xticks;
}
    80003484:	02049513          	slli	a0,s1,0x20
    80003488:	9101                	srli	a0,a0,0x20
    8000348a:	60e2                	ld	ra,24(sp)
    8000348c:	6442                	ld	s0,16(sp)
    8000348e:	64a2                	ld	s1,8(sp)
    80003490:	6105                	addi	sp,sp,32
    80003492:	8082                	ret

0000000080003494 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003494:	7179                	addi	sp,sp,-48
    80003496:	f406                	sd	ra,40(sp)
    80003498:	f022                	sd	s0,32(sp)
    8000349a:	ec26                	sd	s1,24(sp)
    8000349c:	e84a                	sd	s2,16(sp)
    8000349e:	e44e                	sd	s3,8(sp)
    800034a0:	e052                	sd	s4,0(sp)
    800034a2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800034a4:	00005597          	auipc	a1,0x5
    800034a8:	0bc58593          	addi	a1,a1,188 # 80008560 <syscalls+0xc0>
    800034ac:	00014517          	auipc	a0,0x14
    800034b0:	58450513          	addi	a0,a0,1412 # 80017a30 <bcache>
    800034b4:	ffffd097          	auipc	ra,0xffffd
    800034b8:	6a0080e7          	jalr	1696(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034bc:	0001c797          	auipc	a5,0x1c
    800034c0:	57478793          	addi	a5,a5,1396 # 8001fa30 <bcache+0x8000>
    800034c4:	0001c717          	auipc	a4,0x1c
    800034c8:	7d470713          	addi	a4,a4,2004 # 8001fc98 <bcache+0x8268>
    800034cc:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034d0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034d4:	00014497          	auipc	s1,0x14
    800034d8:	57448493          	addi	s1,s1,1396 # 80017a48 <bcache+0x18>
    b->next = bcache.head.next;
    800034dc:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034de:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034e0:	00005a17          	auipc	s4,0x5
    800034e4:	088a0a13          	addi	s4,s4,136 # 80008568 <syscalls+0xc8>
    b->next = bcache.head.next;
    800034e8:	2b893783          	ld	a5,696(s2)
    800034ec:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800034ee:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034f2:	85d2                	mv	a1,s4
    800034f4:	01048513          	addi	a0,s1,16
    800034f8:	00001097          	auipc	ra,0x1
    800034fc:	4bc080e7          	jalr	1212(ra) # 800049b4 <initsleeplock>
    bcache.head.next->prev = b;
    80003500:	2b893783          	ld	a5,696(s2)
    80003504:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003506:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000350a:	45848493          	addi	s1,s1,1112
    8000350e:	fd349de3          	bne	s1,s3,800034e8 <binit+0x54>
  }
}
    80003512:	70a2                	ld	ra,40(sp)
    80003514:	7402                	ld	s0,32(sp)
    80003516:	64e2                	ld	s1,24(sp)
    80003518:	6942                	ld	s2,16(sp)
    8000351a:	69a2                	ld	s3,8(sp)
    8000351c:	6a02                	ld	s4,0(sp)
    8000351e:	6145                	addi	sp,sp,48
    80003520:	8082                	ret

0000000080003522 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003522:	7179                	addi	sp,sp,-48
    80003524:	f406                	sd	ra,40(sp)
    80003526:	f022                	sd	s0,32(sp)
    80003528:	ec26                	sd	s1,24(sp)
    8000352a:	e84a                	sd	s2,16(sp)
    8000352c:	e44e                	sd	s3,8(sp)
    8000352e:	1800                	addi	s0,sp,48
    80003530:	89aa                	mv	s3,a0
    80003532:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003534:	00014517          	auipc	a0,0x14
    80003538:	4fc50513          	addi	a0,a0,1276 # 80017a30 <bcache>
    8000353c:	ffffd097          	auipc	ra,0xffffd
    80003540:	6a8080e7          	jalr	1704(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003544:	0001c497          	auipc	s1,0x1c
    80003548:	7a44b483          	ld	s1,1956(s1) # 8001fce8 <bcache+0x82b8>
    8000354c:	0001c797          	auipc	a5,0x1c
    80003550:	74c78793          	addi	a5,a5,1868 # 8001fc98 <bcache+0x8268>
    80003554:	02f48f63          	beq	s1,a5,80003592 <bread+0x70>
    80003558:	873e                	mv	a4,a5
    8000355a:	a021                	j	80003562 <bread+0x40>
    8000355c:	68a4                	ld	s1,80(s1)
    8000355e:	02e48a63          	beq	s1,a4,80003592 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003562:	449c                	lw	a5,8(s1)
    80003564:	ff379ce3          	bne	a5,s3,8000355c <bread+0x3a>
    80003568:	44dc                	lw	a5,12(s1)
    8000356a:	ff2799e3          	bne	a5,s2,8000355c <bread+0x3a>
      b->refcnt++;
    8000356e:	40bc                	lw	a5,64(s1)
    80003570:	2785                	addiw	a5,a5,1
    80003572:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003574:	00014517          	auipc	a0,0x14
    80003578:	4bc50513          	addi	a0,a0,1212 # 80017a30 <bcache>
    8000357c:	ffffd097          	auipc	ra,0xffffd
    80003580:	71c080e7          	jalr	1820(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003584:	01048513          	addi	a0,s1,16
    80003588:	00001097          	auipc	ra,0x1
    8000358c:	466080e7          	jalr	1126(ra) # 800049ee <acquiresleep>
      return b;
    80003590:	a8b9                	j	800035ee <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003592:	0001c497          	auipc	s1,0x1c
    80003596:	74e4b483          	ld	s1,1870(s1) # 8001fce0 <bcache+0x82b0>
    8000359a:	0001c797          	auipc	a5,0x1c
    8000359e:	6fe78793          	addi	a5,a5,1790 # 8001fc98 <bcache+0x8268>
    800035a2:	00f48863          	beq	s1,a5,800035b2 <bread+0x90>
    800035a6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800035a8:	40bc                	lw	a5,64(s1)
    800035aa:	cf81                	beqz	a5,800035c2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035ac:	64a4                	ld	s1,72(s1)
    800035ae:	fee49de3          	bne	s1,a4,800035a8 <bread+0x86>
  panic("bget: no buffers");
    800035b2:	00005517          	auipc	a0,0x5
    800035b6:	fbe50513          	addi	a0,a0,-66 # 80008570 <syscalls+0xd0>
    800035ba:	ffffd097          	auipc	ra,0xffffd
    800035be:	f84080e7          	jalr	-124(ra) # 8000053e <panic>
      b->dev = dev;
    800035c2:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800035c6:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800035ca:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035ce:	4785                	li	a5,1
    800035d0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035d2:	00014517          	auipc	a0,0x14
    800035d6:	45e50513          	addi	a0,a0,1118 # 80017a30 <bcache>
    800035da:	ffffd097          	auipc	ra,0xffffd
    800035de:	6be080e7          	jalr	1726(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800035e2:	01048513          	addi	a0,s1,16
    800035e6:	00001097          	auipc	ra,0x1
    800035ea:	408080e7          	jalr	1032(ra) # 800049ee <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800035ee:	409c                	lw	a5,0(s1)
    800035f0:	cb89                	beqz	a5,80003602 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035f2:	8526                	mv	a0,s1
    800035f4:	70a2                	ld	ra,40(sp)
    800035f6:	7402                	ld	s0,32(sp)
    800035f8:	64e2                	ld	s1,24(sp)
    800035fa:	6942                	ld	s2,16(sp)
    800035fc:	69a2                	ld	s3,8(sp)
    800035fe:	6145                	addi	sp,sp,48
    80003600:	8082                	ret
    virtio_disk_rw(b, 0);
    80003602:	4581                	li	a1,0
    80003604:	8526                	mv	a0,s1
    80003606:	00003097          	auipc	ra,0x3
    8000360a:	f10080e7          	jalr	-240(ra) # 80006516 <virtio_disk_rw>
    b->valid = 1;
    8000360e:	4785                	li	a5,1
    80003610:	c09c                	sw	a5,0(s1)
  return b;
    80003612:	b7c5                	j	800035f2 <bread+0xd0>

0000000080003614 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003614:	1101                	addi	sp,sp,-32
    80003616:	ec06                	sd	ra,24(sp)
    80003618:	e822                	sd	s0,16(sp)
    8000361a:	e426                	sd	s1,8(sp)
    8000361c:	1000                	addi	s0,sp,32
    8000361e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003620:	0541                	addi	a0,a0,16
    80003622:	00001097          	auipc	ra,0x1
    80003626:	466080e7          	jalr	1126(ra) # 80004a88 <holdingsleep>
    8000362a:	cd01                	beqz	a0,80003642 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000362c:	4585                	li	a1,1
    8000362e:	8526                	mv	a0,s1
    80003630:	00003097          	auipc	ra,0x3
    80003634:	ee6080e7          	jalr	-282(ra) # 80006516 <virtio_disk_rw>
}
    80003638:	60e2                	ld	ra,24(sp)
    8000363a:	6442                	ld	s0,16(sp)
    8000363c:	64a2                	ld	s1,8(sp)
    8000363e:	6105                	addi	sp,sp,32
    80003640:	8082                	ret
    panic("bwrite");
    80003642:	00005517          	auipc	a0,0x5
    80003646:	f4650513          	addi	a0,a0,-186 # 80008588 <syscalls+0xe8>
    8000364a:	ffffd097          	auipc	ra,0xffffd
    8000364e:	ef4080e7          	jalr	-268(ra) # 8000053e <panic>

0000000080003652 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003652:	1101                	addi	sp,sp,-32
    80003654:	ec06                	sd	ra,24(sp)
    80003656:	e822                	sd	s0,16(sp)
    80003658:	e426                	sd	s1,8(sp)
    8000365a:	e04a                	sd	s2,0(sp)
    8000365c:	1000                	addi	s0,sp,32
    8000365e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003660:	01050913          	addi	s2,a0,16
    80003664:	854a                	mv	a0,s2
    80003666:	00001097          	auipc	ra,0x1
    8000366a:	422080e7          	jalr	1058(ra) # 80004a88 <holdingsleep>
    8000366e:	c92d                	beqz	a0,800036e0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003670:	854a                	mv	a0,s2
    80003672:	00001097          	auipc	ra,0x1
    80003676:	3d2080e7          	jalr	978(ra) # 80004a44 <releasesleep>

  acquire(&bcache.lock);
    8000367a:	00014517          	auipc	a0,0x14
    8000367e:	3b650513          	addi	a0,a0,950 # 80017a30 <bcache>
    80003682:	ffffd097          	auipc	ra,0xffffd
    80003686:	562080e7          	jalr	1378(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000368a:	40bc                	lw	a5,64(s1)
    8000368c:	37fd                	addiw	a5,a5,-1
    8000368e:	0007871b          	sext.w	a4,a5
    80003692:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003694:	eb05                	bnez	a4,800036c4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003696:	68bc                	ld	a5,80(s1)
    80003698:	64b8                	ld	a4,72(s1)
    8000369a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000369c:	64bc                	ld	a5,72(s1)
    8000369e:	68b8                	ld	a4,80(s1)
    800036a0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800036a2:	0001c797          	auipc	a5,0x1c
    800036a6:	38e78793          	addi	a5,a5,910 # 8001fa30 <bcache+0x8000>
    800036aa:	2b87b703          	ld	a4,696(a5)
    800036ae:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800036b0:	0001c717          	auipc	a4,0x1c
    800036b4:	5e870713          	addi	a4,a4,1512 # 8001fc98 <bcache+0x8268>
    800036b8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800036ba:	2b87b703          	ld	a4,696(a5)
    800036be:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036c0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800036c4:	00014517          	auipc	a0,0x14
    800036c8:	36c50513          	addi	a0,a0,876 # 80017a30 <bcache>
    800036cc:	ffffd097          	auipc	ra,0xffffd
    800036d0:	5cc080e7          	jalr	1484(ra) # 80000c98 <release>
}
    800036d4:	60e2                	ld	ra,24(sp)
    800036d6:	6442                	ld	s0,16(sp)
    800036d8:	64a2                	ld	s1,8(sp)
    800036da:	6902                	ld	s2,0(sp)
    800036dc:	6105                	addi	sp,sp,32
    800036de:	8082                	ret
    panic("brelse");
    800036e0:	00005517          	auipc	a0,0x5
    800036e4:	eb050513          	addi	a0,a0,-336 # 80008590 <syscalls+0xf0>
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	e56080e7          	jalr	-426(ra) # 8000053e <panic>

00000000800036f0 <bpin>:

void
bpin(struct buf *b) {
    800036f0:	1101                	addi	sp,sp,-32
    800036f2:	ec06                	sd	ra,24(sp)
    800036f4:	e822                	sd	s0,16(sp)
    800036f6:	e426                	sd	s1,8(sp)
    800036f8:	1000                	addi	s0,sp,32
    800036fa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036fc:	00014517          	auipc	a0,0x14
    80003700:	33450513          	addi	a0,a0,820 # 80017a30 <bcache>
    80003704:	ffffd097          	auipc	ra,0xffffd
    80003708:	4e0080e7          	jalr	1248(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000370c:	40bc                	lw	a5,64(s1)
    8000370e:	2785                	addiw	a5,a5,1
    80003710:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003712:	00014517          	auipc	a0,0x14
    80003716:	31e50513          	addi	a0,a0,798 # 80017a30 <bcache>
    8000371a:	ffffd097          	auipc	ra,0xffffd
    8000371e:	57e080e7          	jalr	1406(ra) # 80000c98 <release>
}
    80003722:	60e2                	ld	ra,24(sp)
    80003724:	6442                	ld	s0,16(sp)
    80003726:	64a2                	ld	s1,8(sp)
    80003728:	6105                	addi	sp,sp,32
    8000372a:	8082                	ret

000000008000372c <bunpin>:

void
bunpin(struct buf *b) {
    8000372c:	1101                	addi	sp,sp,-32
    8000372e:	ec06                	sd	ra,24(sp)
    80003730:	e822                	sd	s0,16(sp)
    80003732:	e426                	sd	s1,8(sp)
    80003734:	1000                	addi	s0,sp,32
    80003736:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003738:	00014517          	auipc	a0,0x14
    8000373c:	2f850513          	addi	a0,a0,760 # 80017a30 <bcache>
    80003740:	ffffd097          	auipc	ra,0xffffd
    80003744:	4a4080e7          	jalr	1188(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003748:	40bc                	lw	a5,64(s1)
    8000374a:	37fd                	addiw	a5,a5,-1
    8000374c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000374e:	00014517          	auipc	a0,0x14
    80003752:	2e250513          	addi	a0,a0,738 # 80017a30 <bcache>
    80003756:	ffffd097          	auipc	ra,0xffffd
    8000375a:	542080e7          	jalr	1346(ra) # 80000c98 <release>
}
    8000375e:	60e2                	ld	ra,24(sp)
    80003760:	6442                	ld	s0,16(sp)
    80003762:	64a2                	ld	s1,8(sp)
    80003764:	6105                	addi	sp,sp,32
    80003766:	8082                	ret

0000000080003768 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003768:	1101                	addi	sp,sp,-32
    8000376a:	ec06                	sd	ra,24(sp)
    8000376c:	e822                	sd	s0,16(sp)
    8000376e:	e426                	sd	s1,8(sp)
    80003770:	e04a                	sd	s2,0(sp)
    80003772:	1000                	addi	s0,sp,32
    80003774:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003776:	00d5d59b          	srliw	a1,a1,0xd
    8000377a:	0001d797          	auipc	a5,0x1d
    8000377e:	9927a783          	lw	a5,-1646(a5) # 8002010c <sb+0x1c>
    80003782:	9dbd                	addw	a1,a1,a5
    80003784:	00000097          	auipc	ra,0x0
    80003788:	d9e080e7          	jalr	-610(ra) # 80003522 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000378c:	0074f713          	andi	a4,s1,7
    80003790:	4785                	li	a5,1
    80003792:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003796:	14ce                	slli	s1,s1,0x33
    80003798:	90d9                	srli	s1,s1,0x36
    8000379a:	00950733          	add	a4,a0,s1
    8000379e:	05874703          	lbu	a4,88(a4)
    800037a2:	00e7f6b3          	and	a3,a5,a4
    800037a6:	c69d                	beqz	a3,800037d4 <bfree+0x6c>
    800037a8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800037aa:	94aa                	add	s1,s1,a0
    800037ac:	fff7c793          	not	a5,a5
    800037b0:	8ff9                	and	a5,a5,a4
    800037b2:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800037b6:	00001097          	auipc	ra,0x1
    800037ba:	118080e7          	jalr	280(ra) # 800048ce <log_write>
  brelse(bp);
    800037be:	854a                	mv	a0,s2
    800037c0:	00000097          	auipc	ra,0x0
    800037c4:	e92080e7          	jalr	-366(ra) # 80003652 <brelse>
}
    800037c8:	60e2                	ld	ra,24(sp)
    800037ca:	6442                	ld	s0,16(sp)
    800037cc:	64a2                	ld	s1,8(sp)
    800037ce:	6902                	ld	s2,0(sp)
    800037d0:	6105                	addi	sp,sp,32
    800037d2:	8082                	ret
    panic("freeing free block");
    800037d4:	00005517          	auipc	a0,0x5
    800037d8:	dc450513          	addi	a0,a0,-572 # 80008598 <syscalls+0xf8>
    800037dc:	ffffd097          	auipc	ra,0xffffd
    800037e0:	d62080e7          	jalr	-670(ra) # 8000053e <panic>

00000000800037e4 <balloc>:
{
    800037e4:	711d                	addi	sp,sp,-96
    800037e6:	ec86                	sd	ra,88(sp)
    800037e8:	e8a2                	sd	s0,80(sp)
    800037ea:	e4a6                	sd	s1,72(sp)
    800037ec:	e0ca                	sd	s2,64(sp)
    800037ee:	fc4e                	sd	s3,56(sp)
    800037f0:	f852                	sd	s4,48(sp)
    800037f2:	f456                	sd	s5,40(sp)
    800037f4:	f05a                	sd	s6,32(sp)
    800037f6:	ec5e                	sd	s7,24(sp)
    800037f8:	e862                	sd	s8,16(sp)
    800037fa:	e466                	sd	s9,8(sp)
    800037fc:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037fe:	0001d797          	auipc	a5,0x1d
    80003802:	8f67a783          	lw	a5,-1802(a5) # 800200f4 <sb+0x4>
    80003806:	cbd1                	beqz	a5,8000389a <balloc+0xb6>
    80003808:	8baa                	mv	s7,a0
    8000380a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000380c:	0001db17          	auipc	s6,0x1d
    80003810:	8e4b0b13          	addi	s6,s6,-1820 # 800200f0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003814:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003816:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003818:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000381a:	6c89                	lui	s9,0x2
    8000381c:	a831                	j	80003838 <balloc+0x54>
    brelse(bp);
    8000381e:	854a                	mv	a0,s2
    80003820:	00000097          	auipc	ra,0x0
    80003824:	e32080e7          	jalr	-462(ra) # 80003652 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003828:	015c87bb          	addw	a5,s9,s5
    8000382c:	00078a9b          	sext.w	s5,a5
    80003830:	004b2703          	lw	a4,4(s6)
    80003834:	06eaf363          	bgeu	s5,a4,8000389a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003838:	41fad79b          	sraiw	a5,s5,0x1f
    8000383c:	0137d79b          	srliw	a5,a5,0x13
    80003840:	015787bb          	addw	a5,a5,s5
    80003844:	40d7d79b          	sraiw	a5,a5,0xd
    80003848:	01cb2583          	lw	a1,28(s6)
    8000384c:	9dbd                	addw	a1,a1,a5
    8000384e:	855e                	mv	a0,s7
    80003850:	00000097          	auipc	ra,0x0
    80003854:	cd2080e7          	jalr	-814(ra) # 80003522 <bread>
    80003858:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000385a:	004b2503          	lw	a0,4(s6)
    8000385e:	000a849b          	sext.w	s1,s5
    80003862:	8662                	mv	a2,s8
    80003864:	faa4fde3          	bgeu	s1,a0,8000381e <balloc+0x3a>
      m = 1 << (bi % 8);
    80003868:	41f6579b          	sraiw	a5,a2,0x1f
    8000386c:	01d7d69b          	srliw	a3,a5,0x1d
    80003870:	00c6873b          	addw	a4,a3,a2
    80003874:	00777793          	andi	a5,a4,7
    80003878:	9f95                	subw	a5,a5,a3
    8000387a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000387e:	4037571b          	sraiw	a4,a4,0x3
    80003882:	00e906b3          	add	a3,s2,a4
    80003886:	0586c683          	lbu	a3,88(a3)
    8000388a:	00d7f5b3          	and	a1,a5,a3
    8000388e:	cd91                	beqz	a1,800038aa <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003890:	2605                	addiw	a2,a2,1
    80003892:	2485                	addiw	s1,s1,1
    80003894:	fd4618e3          	bne	a2,s4,80003864 <balloc+0x80>
    80003898:	b759                	j	8000381e <balloc+0x3a>
  panic("balloc: out of blocks");
    8000389a:	00005517          	auipc	a0,0x5
    8000389e:	d1650513          	addi	a0,a0,-746 # 800085b0 <syscalls+0x110>
    800038a2:	ffffd097          	auipc	ra,0xffffd
    800038a6:	c9c080e7          	jalr	-868(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800038aa:	974a                	add	a4,a4,s2
    800038ac:	8fd5                	or	a5,a5,a3
    800038ae:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800038b2:	854a                	mv	a0,s2
    800038b4:	00001097          	auipc	ra,0x1
    800038b8:	01a080e7          	jalr	26(ra) # 800048ce <log_write>
        brelse(bp);
    800038bc:	854a                	mv	a0,s2
    800038be:	00000097          	auipc	ra,0x0
    800038c2:	d94080e7          	jalr	-620(ra) # 80003652 <brelse>
  bp = bread(dev, bno);
    800038c6:	85a6                	mv	a1,s1
    800038c8:	855e                	mv	a0,s7
    800038ca:	00000097          	auipc	ra,0x0
    800038ce:	c58080e7          	jalr	-936(ra) # 80003522 <bread>
    800038d2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038d4:	40000613          	li	a2,1024
    800038d8:	4581                	li	a1,0
    800038da:	05850513          	addi	a0,a0,88
    800038de:	ffffd097          	auipc	ra,0xffffd
    800038e2:	414080e7          	jalr	1044(ra) # 80000cf2 <memset>
  log_write(bp);
    800038e6:	854a                	mv	a0,s2
    800038e8:	00001097          	auipc	ra,0x1
    800038ec:	fe6080e7          	jalr	-26(ra) # 800048ce <log_write>
  brelse(bp);
    800038f0:	854a                	mv	a0,s2
    800038f2:	00000097          	auipc	ra,0x0
    800038f6:	d60080e7          	jalr	-672(ra) # 80003652 <brelse>
}
    800038fa:	8526                	mv	a0,s1
    800038fc:	60e6                	ld	ra,88(sp)
    800038fe:	6446                	ld	s0,80(sp)
    80003900:	64a6                	ld	s1,72(sp)
    80003902:	6906                	ld	s2,64(sp)
    80003904:	79e2                	ld	s3,56(sp)
    80003906:	7a42                	ld	s4,48(sp)
    80003908:	7aa2                	ld	s5,40(sp)
    8000390a:	7b02                	ld	s6,32(sp)
    8000390c:	6be2                	ld	s7,24(sp)
    8000390e:	6c42                	ld	s8,16(sp)
    80003910:	6ca2                	ld	s9,8(sp)
    80003912:	6125                	addi	sp,sp,96
    80003914:	8082                	ret

0000000080003916 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003916:	7179                	addi	sp,sp,-48
    80003918:	f406                	sd	ra,40(sp)
    8000391a:	f022                	sd	s0,32(sp)
    8000391c:	ec26                	sd	s1,24(sp)
    8000391e:	e84a                	sd	s2,16(sp)
    80003920:	e44e                	sd	s3,8(sp)
    80003922:	e052                	sd	s4,0(sp)
    80003924:	1800                	addi	s0,sp,48
    80003926:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003928:	47ad                	li	a5,11
    8000392a:	04b7fe63          	bgeu	a5,a1,80003986 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000392e:	ff45849b          	addiw	s1,a1,-12
    80003932:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003936:	0ff00793          	li	a5,255
    8000393a:	0ae7e363          	bltu	a5,a4,800039e0 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000393e:	08052583          	lw	a1,128(a0)
    80003942:	c5ad                	beqz	a1,800039ac <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003944:	00092503          	lw	a0,0(s2)
    80003948:	00000097          	auipc	ra,0x0
    8000394c:	bda080e7          	jalr	-1062(ra) # 80003522 <bread>
    80003950:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003952:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003956:	02049593          	slli	a1,s1,0x20
    8000395a:	9181                	srli	a1,a1,0x20
    8000395c:	058a                	slli	a1,a1,0x2
    8000395e:	00b784b3          	add	s1,a5,a1
    80003962:	0004a983          	lw	s3,0(s1)
    80003966:	04098d63          	beqz	s3,800039c0 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000396a:	8552                	mv	a0,s4
    8000396c:	00000097          	auipc	ra,0x0
    80003970:	ce6080e7          	jalr	-794(ra) # 80003652 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003974:	854e                	mv	a0,s3
    80003976:	70a2                	ld	ra,40(sp)
    80003978:	7402                	ld	s0,32(sp)
    8000397a:	64e2                	ld	s1,24(sp)
    8000397c:	6942                	ld	s2,16(sp)
    8000397e:	69a2                	ld	s3,8(sp)
    80003980:	6a02                	ld	s4,0(sp)
    80003982:	6145                	addi	sp,sp,48
    80003984:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003986:	02059493          	slli	s1,a1,0x20
    8000398a:	9081                	srli	s1,s1,0x20
    8000398c:	048a                	slli	s1,s1,0x2
    8000398e:	94aa                	add	s1,s1,a0
    80003990:	0504a983          	lw	s3,80(s1)
    80003994:	fe0990e3          	bnez	s3,80003974 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003998:	4108                	lw	a0,0(a0)
    8000399a:	00000097          	auipc	ra,0x0
    8000399e:	e4a080e7          	jalr	-438(ra) # 800037e4 <balloc>
    800039a2:	0005099b          	sext.w	s3,a0
    800039a6:	0534a823          	sw	s3,80(s1)
    800039aa:	b7e9                	j	80003974 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800039ac:	4108                	lw	a0,0(a0)
    800039ae:	00000097          	auipc	ra,0x0
    800039b2:	e36080e7          	jalr	-458(ra) # 800037e4 <balloc>
    800039b6:	0005059b          	sext.w	a1,a0
    800039ba:	08b92023          	sw	a1,128(s2)
    800039be:	b759                	j	80003944 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800039c0:	00092503          	lw	a0,0(s2)
    800039c4:	00000097          	auipc	ra,0x0
    800039c8:	e20080e7          	jalr	-480(ra) # 800037e4 <balloc>
    800039cc:	0005099b          	sext.w	s3,a0
    800039d0:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800039d4:	8552                	mv	a0,s4
    800039d6:	00001097          	auipc	ra,0x1
    800039da:	ef8080e7          	jalr	-264(ra) # 800048ce <log_write>
    800039de:	b771                	j	8000396a <bmap+0x54>
  panic("bmap: out of range");
    800039e0:	00005517          	auipc	a0,0x5
    800039e4:	be850513          	addi	a0,a0,-1048 # 800085c8 <syscalls+0x128>
    800039e8:	ffffd097          	auipc	ra,0xffffd
    800039ec:	b56080e7          	jalr	-1194(ra) # 8000053e <panic>

00000000800039f0 <iget>:
{
    800039f0:	7179                	addi	sp,sp,-48
    800039f2:	f406                	sd	ra,40(sp)
    800039f4:	f022                	sd	s0,32(sp)
    800039f6:	ec26                	sd	s1,24(sp)
    800039f8:	e84a                	sd	s2,16(sp)
    800039fa:	e44e                	sd	s3,8(sp)
    800039fc:	e052                	sd	s4,0(sp)
    800039fe:	1800                	addi	s0,sp,48
    80003a00:	89aa                	mv	s3,a0
    80003a02:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a04:	0001c517          	auipc	a0,0x1c
    80003a08:	70c50513          	addi	a0,a0,1804 # 80020110 <itable>
    80003a0c:	ffffd097          	auipc	ra,0xffffd
    80003a10:	1d8080e7          	jalr	472(ra) # 80000be4 <acquire>
  empty = 0;
    80003a14:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a16:	0001c497          	auipc	s1,0x1c
    80003a1a:	71248493          	addi	s1,s1,1810 # 80020128 <itable+0x18>
    80003a1e:	0001e697          	auipc	a3,0x1e
    80003a22:	19a68693          	addi	a3,a3,410 # 80021bb8 <log>
    80003a26:	a039                	j	80003a34 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a28:	02090b63          	beqz	s2,80003a5e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a2c:	08848493          	addi	s1,s1,136
    80003a30:	02d48a63          	beq	s1,a3,80003a64 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a34:	449c                	lw	a5,8(s1)
    80003a36:	fef059e3          	blez	a5,80003a28 <iget+0x38>
    80003a3a:	4098                	lw	a4,0(s1)
    80003a3c:	ff3716e3          	bne	a4,s3,80003a28 <iget+0x38>
    80003a40:	40d8                	lw	a4,4(s1)
    80003a42:	ff4713e3          	bne	a4,s4,80003a28 <iget+0x38>
      ip->ref++;
    80003a46:	2785                	addiw	a5,a5,1
    80003a48:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a4a:	0001c517          	auipc	a0,0x1c
    80003a4e:	6c650513          	addi	a0,a0,1734 # 80020110 <itable>
    80003a52:	ffffd097          	auipc	ra,0xffffd
    80003a56:	246080e7          	jalr	582(ra) # 80000c98 <release>
      return ip;
    80003a5a:	8926                	mv	s2,s1
    80003a5c:	a03d                	j	80003a8a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a5e:	f7f9                	bnez	a5,80003a2c <iget+0x3c>
    80003a60:	8926                	mv	s2,s1
    80003a62:	b7e9                	j	80003a2c <iget+0x3c>
  if(empty == 0)
    80003a64:	02090c63          	beqz	s2,80003a9c <iget+0xac>
  ip->dev = dev;
    80003a68:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a6c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a70:	4785                	li	a5,1
    80003a72:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a76:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a7a:	0001c517          	auipc	a0,0x1c
    80003a7e:	69650513          	addi	a0,a0,1686 # 80020110 <itable>
    80003a82:	ffffd097          	auipc	ra,0xffffd
    80003a86:	216080e7          	jalr	534(ra) # 80000c98 <release>
}
    80003a8a:	854a                	mv	a0,s2
    80003a8c:	70a2                	ld	ra,40(sp)
    80003a8e:	7402                	ld	s0,32(sp)
    80003a90:	64e2                	ld	s1,24(sp)
    80003a92:	6942                	ld	s2,16(sp)
    80003a94:	69a2                	ld	s3,8(sp)
    80003a96:	6a02                	ld	s4,0(sp)
    80003a98:	6145                	addi	sp,sp,48
    80003a9a:	8082                	ret
    panic("iget: no inodes");
    80003a9c:	00005517          	auipc	a0,0x5
    80003aa0:	b4450513          	addi	a0,a0,-1212 # 800085e0 <syscalls+0x140>
    80003aa4:	ffffd097          	auipc	ra,0xffffd
    80003aa8:	a9a080e7          	jalr	-1382(ra) # 8000053e <panic>

0000000080003aac <fsinit>:
fsinit(int dev) {
    80003aac:	7179                	addi	sp,sp,-48
    80003aae:	f406                	sd	ra,40(sp)
    80003ab0:	f022                	sd	s0,32(sp)
    80003ab2:	ec26                	sd	s1,24(sp)
    80003ab4:	e84a                	sd	s2,16(sp)
    80003ab6:	e44e                	sd	s3,8(sp)
    80003ab8:	1800                	addi	s0,sp,48
    80003aba:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003abc:	4585                	li	a1,1
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	a64080e7          	jalr	-1436(ra) # 80003522 <bread>
    80003ac6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003ac8:	0001c997          	auipc	s3,0x1c
    80003acc:	62898993          	addi	s3,s3,1576 # 800200f0 <sb>
    80003ad0:	02000613          	li	a2,32
    80003ad4:	05850593          	addi	a1,a0,88
    80003ad8:	854e                	mv	a0,s3
    80003ada:	ffffd097          	auipc	ra,0xffffd
    80003ade:	278080e7          	jalr	632(ra) # 80000d52 <memmove>
  brelse(bp);
    80003ae2:	8526                	mv	a0,s1
    80003ae4:	00000097          	auipc	ra,0x0
    80003ae8:	b6e080e7          	jalr	-1170(ra) # 80003652 <brelse>
  if(sb.magic != FSMAGIC)
    80003aec:	0009a703          	lw	a4,0(s3)
    80003af0:	102037b7          	lui	a5,0x10203
    80003af4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003af8:	02f71263          	bne	a4,a5,80003b1c <fsinit+0x70>
  initlog(dev, &sb);
    80003afc:	0001c597          	auipc	a1,0x1c
    80003b00:	5f458593          	addi	a1,a1,1524 # 800200f0 <sb>
    80003b04:	854a                	mv	a0,s2
    80003b06:	00001097          	auipc	ra,0x1
    80003b0a:	b4c080e7          	jalr	-1204(ra) # 80004652 <initlog>
}
    80003b0e:	70a2                	ld	ra,40(sp)
    80003b10:	7402                	ld	s0,32(sp)
    80003b12:	64e2                	ld	s1,24(sp)
    80003b14:	6942                	ld	s2,16(sp)
    80003b16:	69a2                	ld	s3,8(sp)
    80003b18:	6145                	addi	sp,sp,48
    80003b1a:	8082                	ret
    panic("invalid file system");
    80003b1c:	00005517          	auipc	a0,0x5
    80003b20:	ad450513          	addi	a0,a0,-1324 # 800085f0 <syscalls+0x150>
    80003b24:	ffffd097          	auipc	ra,0xffffd
    80003b28:	a1a080e7          	jalr	-1510(ra) # 8000053e <panic>

0000000080003b2c <iinit>:
{
    80003b2c:	7179                	addi	sp,sp,-48
    80003b2e:	f406                	sd	ra,40(sp)
    80003b30:	f022                	sd	s0,32(sp)
    80003b32:	ec26                	sd	s1,24(sp)
    80003b34:	e84a                	sd	s2,16(sp)
    80003b36:	e44e                	sd	s3,8(sp)
    80003b38:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b3a:	00005597          	auipc	a1,0x5
    80003b3e:	ace58593          	addi	a1,a1,-1330 # 80008608 <syscalls+0x168>
    80003b42:	0001c517          	auipc	a0,0x1c
    80003b46:	5ce50513          	addi	a0,a0,1486 # 80020110 <itable>
    80003b4a:	ffffd097          	auipc	ra,0xffffd
    80003b4e:	00a080e7          	jalr	10(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b52:	0001c497          	auipc	s1,0x1c
    80003b56:	5e648493          	addi	s1,s1,1510 # 80020138 <itable+0x28>
    80003b5a:	0001e997          	auipc	s3,0x1e
    80003b5e:	06e98993          	addi	s3,s3,110 # 80021bc8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b62:	00005917          	auipc	s2,0x5
    80003b66:	aae90913          	addi	s2,s2,-1362 # 80008610 <syscalls+0x170>
    80003b6a:	85ca                	mv	a1,s2
    80003b6c:	8526                	mv	a0,s1
    80003b6e:	00001097          	auipc	ra,0x1
    80003b72:	e46080e7          	jalr	-442(ra) # 800049b4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b76:	08848493          	addi	s1,s1,136
    80003b7a:	ff3498e3          	bne	s1,s3,80003b6a <iinit+0x3e>
}
    80003b7e:	70a2                	ld	ra,40(sp)
    80003b80:	7402                	ld	s0,32(sp)
    80003b82:	64e2                	ld	s1,24(sp)
    80003b84:	6942                	ld	s2,16(sp)
    80003b86:	69a2                	ld	s3,8(sp)
    80003b88:	6145                	addi	sp,sp,48
    80003b8a:	8082                	ret

0000000080003b8c <ialloc>:
{
    80003b8c:	715d                	addi	sp,sp,-80
    80003b8e:	e486                	sd	ra,72(sp)
    80003b90:	e0a2                	sd	s0,64(sp)
    80003b92:	fc26                	sd	s1,56(sp)
    80003b94:	f84a                	sd	s2,48(sp)
    80003b96:	f44e                	sd	s3,40(sp)
    80003b98:	f052                	sd	s4,32(sp)
    80003b9a:	ec56                	sd	s5,24(sp)
    80003b9c:	e85a                	sd	s6,16(sp)
    80003b9e:	e45e                	sd	s7,8(sp)
    80003ba0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ba2:	0001c717          	auipc	a4,0x1c
    80003ba6:	55a72703          	lw	a4,1370(a4) # 800200fc <sb+0xc>
    80003baa:	4785                	li	a5,1
    80003bac:	04e7fa63          	bgeu	a5,a4,80003c00 <ialloc+0x74>
    80003bb0:	8aaa                	mv	s5,a0
    80003bb2:	8bae                	mv	s7,a1
    80003bb4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003bb6:	0001ca17          	auipc	s4,0x1c
    80003bba:	53aa0a13          	addi	s4,s4,1338 # 800200f0 <sb>
    80003bbe:	00048b1b          	sext.w	s6,s1
    80003bc2:	0044d593          	srli	a1,s1,0x4
    80003bc6:	018a2783          	lw	a5,24(s4)
    80003bca:	9dbd                	addw	a1,a1,a5
    80003bcc:	8556                	mv	a0,s5
    80003bce:	00000097          	auipc	ra,0x0
    80003bd2:	954080e7          	jalr	-1708(ra) # 80003522 <bread>
    80003bd6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003bd8:	05850993          	addi	s3,a0,88
    80003bdc:	00f4f793          	andi	a5,s1,15
    80003be0:	079a                	slli	a5,a5,0x6
    80003be2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003be4:	00099783          	lh	a5,0(s3)
    80003be8:	c785                	beqz	a5,80003c10 <ialloc+0x84>
    brelse(bp);
    80003bea:	00000097          	auipc	ra,0x0
    80003bee:	a68080e7          	jalr	-1432(ra) # 80003652 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bf2:	0485                	addi	s1,s1,1
    80003bf4:	00ca2703          	lw	a4,12(s4)
    80003bf8:	0004879b          	sext.w	a5,s1
    80003bfc:	fce7e1e3          	bltu	a5,a4,80003bbe <ialloc+0x32>
  panic("ialloc: no inodes");
    80003c00:	00005517          	auipc	a0,0x5
    80003c04:	a1850513          	addi	a0,a0,-1512 # 80008618 <syscalls+0x178>
    80003c08:	ffffd097          	auipc	ra,0xffffd
    80003c0c:	936080e7          	jalr	-1738(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003c10:	04000613          	li	a2,64
    80003c14:	4581                	li	a1,0
    80003c16:	854e                	mv	a0,s3
    80003c18:	ffffd097          	auipc	ra,0xffffd
    80003c1c:	0da080e7          	jalr	218(ra) # 80000cf2 <memset>
      dip->type = type;
    80003c20:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c24:	854a                	mv	a0,s2
    80003c26:	00001097          	auipc	ra,0x1
    80003c2a:	ca8080e7          	jalr	-856(ra) # 800048ce <log_write>
      brelse(bp);
    80003c2e:	854a                	mv	a0,s2
    80003c30:	00000097          	auipc	ra,0x0
    80003c34:	a22080e7          	jalr	-1502(ra) # 80003652 <brelse>
      return iget(dev, inum);
    80003c38:	85da                	mv	a1,s6
    80003c3a:	8556                	mv	a0,s5
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	db4080e7          	jalr	-588(ra) # 800039f0 <iget>
}
    80003c44:	60a6                	ld	ra,72(sp)
    80003c46:	6406                	ld	s0,64(sp)
    80003c48:	74e2                	ld	s1,56(sp)
    80003c4a:	7942                	ld	s2,48(sp)
    80003c4c:	79a2                	ld	s3,40(sp)
    80003c4e:	7a02                	ld	s4,32(sp)
    80003c50:	6ae2                	ld	s5,24(sp)
    80003c52:	6b42                	ld	s6,16(sp)
    80003c54:	6ba2                	ld	s7,8(sp)
    80003c56:	6161                	addi	sp,sp,80
    80003c58:	8082                	ret

0000000080003c5a <iupdate>:
{
    80003c5a:	1101                	addi	sp,sp,-32
    80003c5c:	ec06                	sd	ra,24(sp)
    80003c5e:	e822                	sd	s0,16(sp)
    80003c60:	e426                	sd	s1,8(sp)
    80003c62:	e04a                	sd	s2,0(sp)
    80003c64:	1000                	addi	s0,sp,32
    80003c66:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c68:	415c                	lw	a5,4(a0)
    80003c6a:	0047d79b          	srliw	a5,a5,0x4
    80003c6e:	0001c597          	auipc	a1,0x1c
    80003c72:	49a5a583          	lw	a1,1178(a1) # 80020108 <sb+0x18>
    80003c76:	9dbd                	addw	a1,a1,a5
    80003c78:	4108                	lw	a0,0(a0)
    80003c7a:	00000097          	auipc	ra,0x0
    80003c7e:	8a8080e7          	jalr	-1880(ra) # 80003522 <bread>
    80003c82:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c84:	05850793          	addi	a5,a0,88
    80003c88:	40c8                	lw	a0,4(s1)
    80003c8a:	893d                	andi	a0,a0,15
    80003c8c:	051a                	slli	a0,a0,0x6
    80003c8e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c90:	04449703          	lh	a4,68(s1)
    80003c94:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003c98:	04649703          	lh	a4,70(s1)
    80003c9c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003ca0:	04849703          	lh	a4,72(s1)
    80003ca4:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003ca8:	04a49703          	lh	a4,74(s1)
    80003cac:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003cb0:	44f8                	lw	a4,76(s1)
    80003cb2:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003cb4:	03400613          	li	a2,52
    80003cb8:	05048593          	addi	a1,s1,80
    80003cbc:	0531                	addi	a0,a0,12
    80003cbe:	ffffd097          	auipc	ra,0xffffd
    80003cc2:	094080e7          	jalr	148(ra) # 80000d52 <memmove>
  log_write(bp);
    80003cc6:	854a                	mv	a0,s2
    80003cc8:	00001097          	auipc	ra,0x1
    80003ccc:	c06080e7          	jalr	-1018(ra) # 800048ce <log_write>
  brelse(bp);
    80003cd0:	854a                	mv	a0,s2
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	980080e7          	jalr	-1664(ra) # 80003652 <brelse>
}
    80003cda:	60e2                	ld	ra,24(sp)
    80003cdc:	6442                	ld	s0,16(sp)
    80003cde:	64a2                	ld	s1,8(sp)
    80003ce0:	6902                	ld	s2,0(sp)
    80003ce2:	6105                	addi	sp,sp,32
    80003ce4:	8082                	ret

0000000080003ce6 <idup>:
{
    80003ce6:	1101                	addi	sp,sp,-32
    80003ce8:	ec06                	sd	ra,24(sp)
    80003cea:	e822                	sd	s0,16(sp)
    80003cec:	e426                	sd	s1,8(sp)
    80003cee:	1000                	addi	s0,sp,32
    80003cf0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cf2:	0001c517          	auipc	a0,0x1c
    80003cf6:	41e50513          	addi	a0,a0,1054 # 80020110 <itable>
    80003cfa:	ffffd097          	auipc	ra,0xffffd
    80003cfe:	eea080e7          	jalr	-278(ra) # 80000be4 <acquire>
  ip->ref++;
    80003d02:	449c                	lw	a5,8(s1)
    80003d04:	2785                	addiw	a5,a5,1
    80003d06:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d08:	0001c517          	auipc	a0,0x1c
    80003d0c:	40850513          	addi	a0,a0,1032 # 80020110 <itable>
    80003d10:	ffffd097          	auipc	ra,0xffffd
    80003d14:	f88080e7          	jalr	-120(ra) # 80000c98 <release>
}
    80003d18:	8526                	mv	a0,s1
    80003d1a:	60e2                	ld	ra,24(sp)
    80003d1c:	6442                	ld	s0,16(sp)
    80003d1e:	64a2                	ld	s1,8(sp)
    80003d20:	6105                	addi	sp,sp,32
    80003d22:	8082                	ret

0000000080003d24 <ilock>:
{
    80003d24:	1101                	addi	sp,sp,-32
    80003d26:	ec06                	sd	ra,24(sp)
    80003d28:	e822                	sd	s0,16(sp)
    80003d2a:	e426                	sd	s1,8(sp)
    80003d2c:	e04a                	sd	s2,0(sp)
    80003d2e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d30:	c115                	beqz	a0,80003d54 <ilock+0x30>
    80003d32:	84aa                	mv	s1,a0
    80003d34:	451c                	lw	a5,8(a0)
    80003d36:	00f05f63          	blez	a5,80003d54 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d3a:	0541                	addi	a0,a0,16
    80003d3c:	00001097          	auipc	ra,0x1
    80003d40:	cb2080e7          	jalr	-846(ra) # 800049ee <acquiresleep>
  if(ip->valid == 0){
    80003d44:	40bc                	lw	a5,64(s1)
    80003d46:	cf99                	beqz	a5,80003d64 <ilock+0x40>
}
    80003d48:	60e2                	ld	ra,24(sp)
    80003d4a:	6442                	ld	s0,16(sp)
    80003d4c:	64a2                	ld	s1,8(sp)
    80003d4e:	6902                	ld	s2,0(sp)
    80003d50:	6105                	addi	sp,sp,32
    80003d52:	8082                	ret
    panic("ilock");
    80003d54:	00005517          	auipc	a0,0x5
    80003d58:	8dc50513          	addi	a0,a0,-1828 # 80008630 <syscalls+0x190>
    80003d5c:	ffffc097          	auipc	ra,0xffffc
    80003d60:	7e2080e7          	jalr	2018(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d64:	40dc                	lw	a5,4(s1)
    80003d66:	0047d79b          	srliw	a5,a5,0x4
    80003d6a:	0001c597          	auipc	a1,0x1c
    80003d6e:	39e5a583          	lw	a1,926(a1) # 80020108 <sb+0x18>
    80003d72:	9dbd                	addw	a1,a1,a5
    80003d74:	4088                	lw	a0,0(s1)
    80003d76:	fffff097          	auipc	ra,0xfffff
    80003d7a:	7ac080e7          	jalr	1964(ra) # 80003522 <bread>
    80003d7e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d80:	05850593          	addi	a1,a0,88
    80003d84:	40dc                	lw	a5,4(s1)
    80003d86:	8bbd                	andi	a5,a5,15
    80003d88:	079a                	slli	a5,a5,0x6
    80003d8a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d8c:	00059783          	lh	a5,0(a1)
    80003d90:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d94:	00259783          	lh	a5,2(a1)
    80003d98:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d9c:	00459783          	lh	a5,4(a1)
    80003da0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003da4:	00659783          	lh	a5,6(a1)
    80003da8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003dac:	459c                	lw	a5,8(a1)
    80003dae:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003db0:	03400613          	li	a2,52
    80003db4:	05b1                	addi	a1,a1,12
    80003db6:	05048513          	addi	a0,s1,80
    80003dba:	ffffd097          	auipc	ra,0xffffd
    80003dbe:	f98080e7          	jalr	-104(ra) # 80000d52 <memmove>
    brelse(bp);
    80003dc2:	854a                	mv	a0,s2
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	88e080e7          	jalr	-1906(ra) # 80003652 <brelse>
    ip->valid = 1;
    80003dcc:	4785                	li	a5,1
    80003dce:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003dd0:	04449783          	lh	a5,68(s1)
    80003dd4:	fbb5                	bnez	a5,80003d48 <ilock+0x24>
      panic("ilock: no type");
    80003dd6:	00005517          	auipc	a0,0x5
    80003dda:	86250513          	addi	a0,a0,-1950 # 80008638 <syscalls+0x198>
    80003dde:	ffffc097          	auipc	ra,0xffffc
    80003de2:	760080e7          	jalr	1888(ra) # 8000053e <panic>

0000000080003de6 <iunlock>:
{
    80003de6:	1101                	addi	sp,sp,-32
    80003de8:	ec06                	sd	ra,24(sp)
    80003dea:	e822                	sd	s0,16(sp)
    80003dec:	e426                	sd	s1,8(sp)
    80003dee:	e04a                	sd	s2,0(sp)
    80003df0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003df2:	c905                	beqz	a0,80003e22 <iunlock+0x3c>
    80003df4:	84aa                	mv	s1,a0
    80003df6:	01050913          	addi	s2,a0,16
    80003dfa:	854a                	mv	a0,s2
    80003dfc:	00001097          	auipc	ra,0x1
    80003e00:	c8c080e7          	jalr	-884(ra) # 80004a88 <holdingsleep>
    80003e04:	cd19                	beqz	a0,80003e22 <iunlock+0x3c>
    80003e06:	449c                	lw	a5,8(s1)
    80003e08:	00f05d63          	blez	a5,80003e22 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e0c:	854a                	mv	a0,s2
    80003e0e:	00001097          	auipc	ra,0x1
    80003e12:	c36080e7          	jalr	-970(ra) # 80004a44 <releasesleep>
}
    80003e16:	60e2                	ld	ra,24(sp)
    80003e18:	6442                	ld	s0,16(sp)
    80003e1a:	64a2                	ld	s1,8(sp)
    80003e1c:	6902                	ld	s2,0(sp)
    80003e1e:	6105                	addi	sp,sp,32
    80003e20:	8082                	ret
    panic("iunlock");
    80003e22:	00005517          	auipc	a0,0x5
    80003e26:	82650513          	addi	a0,a0,-2010 # 80008648 <syscalls+0x1a8>
    80003e2a:	ffffc097          	auipc	ra,0xffffc
    80003e2e:	714080e7          	jalr	1812(ra) # 8000053e <panic>

0000000080003e32 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e32:	7179                	addi	sp,sp,-48
    80003e34:	f406                	sd	ra,40(sp)
    80003e36:	f022                	sd	s0,32(sp)
    80003e38:	ec26                	sd	s1,24(sp)
    80003e3a:	e84a                	sd	s2,16(sp)
    80003e3c:	e44e                	sd	s3,8(sp)
    80003e3e:	e052                	sd	s4,0(sp)
    80003e40:	1800                	addi	s0,sp,48
    80003e42:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e44:	05050493          	addi	s1,a0,80
    80003e48:	08050913          	addi	s2,a0,128
    80003e4c:	a021                	j	80003e54 <itrunc+0x22>
    80003e4e:	0491                	addi	s1,s1,4
    80003e50:	01248d63          	beq	s1,s2,80003e6a <itrunc+0x38>
    if(ip->addrs[i]){
    80003e54:	408c                	lw	a1,0(s1)
    80003e56:	dde5                	beqz	a1,80003e4e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e58:	0009a503          	lw	a0,0(s3)
    80003e5c:	00000097          	auipc	ra,0x0
    80003e60:	90c080e7          	jalr	-1780(ra) # 80003768 <bfree>
      ip->addrs[i] = 0;
    80003e64:	0004a023          	sw	zero,0(s1)
    80003e68:	b7dd                	j	80003e4e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e6a:	0809a583          	lw	a1,128(s3)
    80003e6e:	e185                	bnez	a1,80003e8e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e70:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e74:	854e                	mv	a0,s3
    80003e76:	00000097          	auipc	ra,0x0
    80003e7a:	de4080e7          	jalr	-540(ra) # 80003c5a <iupdate>
}
    80003e7e:	70a2                	ld	ra,40(sp)
    80003e80:	7402                	ld	s0,32(sp)
    80003e82:	64e2                	ld	s1,24(sp)
    80003e84:	6942                	ld	s2,16(sp)
    80003e86:	69a2                	ld	s3,8(sp)
    80003e88:	6a02                	ld	s4,0(sp)
    80003e8a:	6145                	addi	sp,sp,48
    80003e8c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e8e:	0009a503          	lw	a0,0(s3)
    80003e92:	fffff097          	auipc	ra,0xfffff
    80003e96:	690080e7          	jalr	1680(ra) # 80003522 <bread>
    80003e9a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e9c:	05850493          	addi	s1,a0,88
    80003ea0:	45850913          	addi	s2,a0,1112
    80003ea4:	a811                	j	80003eb8 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003ea6:	0009a503          	lw	a0,0(s3)
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	8be080e7          	jalr	-1858(ra) # 80003768 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003eb2:	0491                	addi	s1,s1,4
    80003eb4:	01248563          	beq	s1,s2,80003ebe <itrunc+0x8c>
      if(a[j])
    80003eb8:	408c                	lw	a1,0(s1)
    80003eba:	dde5                	beqz	a1,80003eb2 <itrunc+0x80>
    80003ebc:	b7ed                	j	80003ea6 <itrunc+0x74>
    brelse(bp);
    80003ebe:	8552                	mv	a0,s4
    80003ec0:	fffff097          	auipc	ra,0xfffff
    80003ec4:	792080e7          	jalr	1938(ra) # 80003652 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ec8:	0809a583          	lw	a1,128(s3)
    80003ecc:	0009a503          	lw	a0,0(s3)
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	898080e7          	jalr	-1896(ra) # 80003768 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ed8:	0809a023          	sw	zero,128(s3)
    80003edc:	bf51                	j	80003e70 <itrunc+0x3e>

0000000080003ede <iput>:
{
    80003ede:	1101                	addi	sp,sp,-32
    80003ee0:	ec06                	sd	ra,24(sp)
    80003ee2:	e822                	sd	s0,16(sp)
    80003ee4:	e426                	sd	s1,8(sp)
    80003ee6:	e04a                	sd	s2,0(sp)
    80003ee8:	1000                	addi	s0,sp,32
    80003eea:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003eec:	0001c517          	auipc	a0,0x1c
    80003ef0:	22450513          	addi	a0,a0,548 # 80020110 <itable>
    80003ef4:	ffffd097          	auipc	ra,0xffffd
    80003ef8:	cf0080e7          	jalr	-784(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003efc:	4498                	lw	a4,8(s1)
    80003efe:	4785                	li	a5,1
    80003f00:	02f70363          	beq	a4,a5,80003f26 <iput+0x48>
  ip->ref--;
    80003f04:	449c                	lw	a5,8(s1)
    80003f06:	37fd                	addiw	a5,a5,-1
    80003f08:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f0a:	0001c517          	auipc	a0,0x1c
    80003f0e:	20650513          	addi	a0,a0,518 # 80020110 <itable>
    80003f12:	ffffd097          	auipc	ra,0xffffd
    80003f16:	d86080e7          	jalr	-634(ra) # 80000c98 <release>
}
    80003f1a:	60e2                	ld	ra,24(sp)
    80003f1c:	6442                	ld	s0,16(sp)
    80003f1e:	64a2                	ld	s1,8(sp)
    80003f20:	6902                	ld	s2,0(sp)
    80003f22:	6105                	addi	sp,sp,32
    80003f24:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f26:	40bc                	lw	a5,64(s1)
    80003f28:	dff1                	beqz	a5,80003f04 <iput+0x26>
    80003f2a:	04a49783          	lh	a5,74(s1)
    80003f2e:	fbf9                	bnez	a5,80003f04 <iput+0x26>
    acquiresleep(&ip->lock);
    80003f30:	01048913          	addi	s2,s1,16
    80003f34:	854a                	mv	a0,s2
    80003f36:	00001097          	auipc	ra,0x1
    80003f3a:	ab8080e7          	jalr	-1352(ra) # 800049ee <acquiresleep>
    release(&itable.lock);
    80003f3e:	0001c517          	auipc	a0,0x1c
    80003f42:	1d250513          	addi	a0,a0,466 # 80020110 <itable>
    80003f46:	ffffd097          	auipc	ra,0xffffd
    80003f4a:	d52080e7          	jalr	-686(ra) # 80000c98 <release>
    itrunc(ip);
    80003f4e:	8526                	mv	a0,s1
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	ee2080e7          	jalr	-286(ra) # 80003e32 <itrunc>
    ip->type = 0;
    80003f58:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f5c:	8526                	mv	a0,s1
    80003f5e:	00000097          	auipc	ra,0x0
    80003f62:	cfc080e7          	jalr	-772(ra) # 80003c5a <iupdate>
    ip->valid = 0;
    80003f66:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f6a:	854a                	mv	a0,s2
    80003f6c:	00001097          	auipc	ra,0x1
    80003f70:	ad8080e7          	jalr	-1320(ra) # 80004a44 <releasesleep>
    acquire(&itable.lock);
    80003f74:	0001c517          	auipc	a0,0x1c
    80003f78:	19c50513          	addi	a0,a0,412 # 80020110 <itable>
    80003f7c:	ffffd097          	auipc	ra,0xffffd
    80003f80:	c68080e7          	jalr	-920(ra) # 80000be4 <acquire>
    80003f84:	b741                	j	80003f04 <iput+0x26>

0000000080003f86 <iunlockput>:
{
    80003f86:	1101                	addi	sp,sp,-32
    80003f88:	ec06                	sd	ra,24(sp)
    80003f8a:	e822                	sd	s0,16(sp)
    80003f8c:	e426                	sd	s1,8(sp)
    80003f8e:	1000                	addi	s0,sp,32
    80003f90:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	e54080e7          	jalr	-428(ra) # 80003de6 <iunlock>
  iput(ip);
    80003f9a:	8526                	mv	a0,s1
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	f42080e7          	jalr	-190(ra) # 80003ede <iput>
}
    80003fa4:	60e2                	ld	ra,24(sp)
    80003fa6:	6442                	ld	s0,16(sp)
    80003fa8:	64a2                	ld	s1,8(sp)
    80003faa:	6105                	addi	sp,sp,32
    80003fac:	8082                	ret

0000000080003fae <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003fae:	1141                	addi	sp,sp,-16
    80003fb0:	e422                	sd	s0,8(sp)
    80003fb2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003fb4:	411c                	lw	a5,0(a0)
    80003fb6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003fb8:	415c                	lw	a5,4(a0)
    80003fba:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003fbc:	04451783          	lh	a5,68(a0)
    80003fc0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003fc4:	04a51783          	lh	a5,74(a0)
    80003fc8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003fcc:	04c56783          	lwu	a5,76(a0)
    80003fd0:	e99c                	sd	a5,16(a1)
}
    80003fd2:	6422                	ld	s0,8(sp)
    80003fd4:	0141                	addi	sp,sp,16
    80003fd6:	8082                	ret

0000000080003fd8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fd8:	457c                	lw	a5,76(a0)
    80003fda:	0ed7e963          	bltu	a5,a3,800040cc <readi+0xf4>
{
    80003fde:	7159                	addi	sp,sp,-112
    80003fe0:	f486                	sd	ra,104(sp)
    80003fe2:	f0a2                	sd	s0,96(sp)
    80003fe4:	eca6                	sd	s1,88(sp)
    80003fe6:	e8ca                	sd	s2,80(sp)
    80003fe8:	e4ce                	sd	s3,72(sp)
    80003fea:	e0d2                	sd	s4,64(sp)
    80003fec:	fc56                	sd	s5,56(sp)
    80003fee:	f85a                	sd	s6,48(sp)
    80003ff0:	f45e                	sd	s7,40(sp)
    80003ff2:	f062                	sd	s8,32(sp)
    80003ff4:	ec66                	sd	s9,24(sp)
    80003ff6:	e86a                	sd	s10,16(sp)
    80003ff8:	e46e                	sd	s11,8(sp)
    80003ffa:	1880                	addi	s0,sp,112
    80003ffc:	8baa                	mv	s7,a0
    80003ffe:	8c2e                	mv	s8,a1
    80004000:	8ab2                	mv	s5,a2
    80004002:	84b6                	mv	s1,a3
    80004004:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004006:	9f35                	addw	a4,a4,a3
    return 0;
    80004008:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000400a:	0ad76063          	bltu	a4,a3,800040aa <readi+0xd2>
  if(off + n > ip->size)
    8000400e:	00e7f463          	bgeu	a5,a4,80004016 <readi+0x3e>
    n = ip->size - off;
    80004012:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004016:	0a0b0963          	beqz	s6,800040c8 <readi+0xf0>
    8000401a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000401c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004020:	5cfd                	li	s9,-1
    80004022:	a82d                	j	8000405c <readi+0x84>
    80004024:	020a1d93          	slli	s11,s4,0x20
    80004028:	020ddd93          	srli	s11,s11,0x20
    8000402c:	05890613          	addi	a2,s2,88
    80004030:	86ee                	mv	a3,s11
    80004032:	963a                	add	a2,a2,a4
    80004034:	85d6                	mv	a1,s5
    80004036:	8562                	mv	a0,s8
    80004038:	fffff097          	auipc	ra,0xfffff
    8000403c:	a6c080e7          	jalr	-1428(ra) # 80002aa4 <either_copyout>
    80004040:	05950d63          	beq	a0,s9,8000409a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004044:	854a                	mv	a0,s2
    80004046:	fffff097          	auipc	ra,0xfffff
    8000404a:	60c080e7          	jalr	1548(ra) # 80003652 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000404e:	013a09bb          	addw	s3,s4,s3
    80004052:	009a04bb          	addw	s1,s4,s1
    80004056:	9aee                	add	s5,s5,s11
    80004058:	0569f763          	bgeu	s3,s6,800040a6 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000405c:	000ba903          	lw	s2,0(s7)
    80004060:	00a4d59b          	srliw	a1,s1,0xa
    80004064:	855e                	mv	a0,s7
    80004066:	00000097          	auipc	ra,0x0
    8000406a:	8b0080e7          	jalr	-1872(ra) # 80003916 <bmap>
    8000406e:	0005059b          	sext.w	a1,a0
    80004072:	854a                	mv	a0,s2
    80004074:	fffff097          	auipc	ra,0xfffff
    80004078:	4ae080e7          	jalr	1198(ra) # 80003522 <bread>
    8000407c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000407e:	3ff4f713          	andi	a4,s1,1023
    80004082:	40ed07bb          	subw	a5,s10,a4
    80004086:	413b06bb          	subw	a3,s6,s3
    8000408a:	8a3e                	mv	s4,a5
    8000408c:	2781                	sext.w	a5,a5
    8000408e:	0006861b          	sext.w	a2,a3
    80004092:	f8f679e3          	bgeu	a2,a5,80004024 <readi+0x4c>
    80004096:	8a36                	mv	s4,a3
    80004098:	b771                	j	80004024 <readi+0x4c>
      brelse(bp);
    8000409a:	854a                	mv	a0,s2
    8000409c:	fffff097          	auipc	ra,0xfffff
    800040a0:	5b6080e7          	jalr	1462(ra) # 80003652 <brelse>
      tot = -1;
    800040a4:	59fd                	li	s3,-1
  }
  return tot;
    800040a6:	0009851b          	sext.w	a0,s3
}
    800040aa:	70a6                	ld	ra,104(sp)
    800040ac:	7406                	ld	s0,96(sp)
    800040ae:	64e6                	ld	s1,88(sp)
    800040b0:	6946                	ld	s2,80(sp)
    800040b2:	69a6                	ld	s3,72(sp)
    800040b4:	6a06                	ld	s4,64(sp)
    800040b6:	7ae2                	ld	s5,56(sp)
    800040b8:	7b42                	ld	s6,48(sp)
    800040ba:	7ba2                	ld	s7,40(sp)
    800040bc:	7c02                	ld	s8,32(sp)
    800040be:	6ce2                	ld	s9,24(sp)
    800040c0:	6d42                	ld	s10,16(sp)
    800040c2:	6da2                	ld	s11,8(sp)
    800040c4:	6165                	addi	sp,sp,112
    800040c6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040c8:	89da                	mv	s3,s6
    800040ca:	bff1                	j	800040a6 <readi+0xce>
    return 0;
    800040cc:	4501                	li	a0,0
}
    800040ce:	8082                	ret

00000000800040d0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040d0:	457c                	lw	a5,76(a0)
    800040d2:	10d7e863          	bltu	a5,a3,800041e2 <writei+0x112>
{
    800040d6:	7159                	addi	sp,sp,-112
    800040d8:	f486                	sd	ra,104(sp)
    800040da:	f0a2                	sd	s0,96(sp)
    800040dc:	eca6                	sd	s1,88(sp)
    800040de:	e8ca                	sd	s2,80(sp)
    800040e0:	e4ce                	sd	s3,72(sp)
    800040e2:	e0d2                	sd	s4,64(sp)
    800040e4:	fc56                	sd	s5,56(sp)
    800040e6:	f85a                	sd	s6,48(sp)
    800040e8:	f45e                	sd	s7,40(sp)
    800040ea:	f062                	sd	s8,32(sp)
    800040ec:	ec66                	sd	s9,24(sp)
    800040ee:	e86a                	sd	s10,16(sp)
    800040f0:	e46e                	sd	s11,8(sp)
    800040f2:	1880                	addi	s0,sp,112
    800040f4:	8b2a                	mv	s6,a0
    800040f6:	8c2e                	mv	s8,a1
    800040f8:	8ab2                	mv	s5,a2
    800040fa:	8936                	mv	s2,a3
    800040fc:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800040fe:	00e687bb          	addw	a5,a3,a4
    80004102:	0ed7e263          	bltu	a5,a3,800041e6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004106:	00043737          	lui	a4,0x43
    8000410a:	0ef76063          	bltu	a4,a5,800041ea <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000410e:	0c0b8863          	beqz	s7,800041de <writei+0x10e>
    80004112:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004114:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004118:	5cfd                	li	s9,-1
    8000411a:	a091                	j	8000415e <writei+0x8e>
    8000411c:	02099d93          	slli	s11,s3,0x20
    80004120:	020ddd93          	srli	s11,s11,0x20
    80004124:	05848513          	addi	a0,s1,88
    80004128:	86ee                	mv	a3,s11
    8000412a:	8656                	mv	a2,s5
    8000412c:	85e2                	mv	a1,s8
    8000412e:	953a                	add	a0,a0,a4
    80004130:	fffff097          	auipc	ra,0xfffff
    80004134:	9ca080e7          	jalr	-1590(ra) # 80002afa <either_copyin>
    80004138:	07950263          	beq	a0,s9,8000419c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000413c:	8526                	mv	a0,s1
    8000413e:	00000097          	auipc	ra,0x0
    80004142:	790080e7          	jalr	1936(ra) # 800048ce <log_write>
    brelse(bp);
    80004146:	8526                	mv	a0,s1
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	50a080e7          	jalr	1290(ra) # 80003652 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004150:	01498a3b          	addw	s4,s3,s4
    80004154:	0129893b          	addw	s2,s3,s2
    80004158:	9aee                	add	s5,s5,s11
    8000415a:	057a7663          	bgeu	s4,s7,800041a6 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000415e:	000b2483          	lw	s1,0(s6)
    80004162:	00a9559b          	srliw	a1,s2,0xa
    80004166:	855a                	mv	a0,s6
    80004168:	fffff097          	auipc	ra,0xfffff
    8000416c:	7ae080e7          	jalr	1966(ra) # 80003916 <bmap>
    80004170:	0005059b          	sext.w	a1,a0
    80004174:	8526                	mv	a0,s1
    80004176:	fffff097          	auipc	ra,0xfffff
    8000417a:	3ac080e7          	jalr	940(ra) # 80003522 <bread>
    8000417e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004180:	3ff97713          	andi	a4,s2,1023
    80004184:	40ed07bb          	subw	a5,s10,a4
    80004188:	414b86bb          	subw	a3,s7,s4
    8000418c:	89be                	mv	s3,a5
    8000418e:	2781                	sext.w	a5,a5
    80004190:	0006861b          	sext.w	a2,a3
    80004194:	f8f674e3          	bgeu	a2,a5,8000411c <writei+0x4c>
    80004198:	89b6                	mv	s3,a3
    8000419a:	b749                	j	8000411c <writei+0x4c>
      brelse(bp);
    8000419c:	8526                	mv	a0,s1
    8000419e:	fffff097          	auipc	ra,0xfffff
    800041a2:	4b4080e7          	jalr	1204(ra) # 80003652 <brelse>
  }

  if(off > ip->size)
    800041a6:	04cb2783          	lw	a5,76(s6)
    800041aa:	0127f463          	bgeu	a5,s2,800041b2 <writei+0xe2>
    ip->size = off;
    800041ae:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800041b2:	855a                	mv	a0,s6
    800041b4:	00000097          	auipc	ra,0x0
    800041b8:	aa6080e7          	jalr	-1370(ra) # 80003c5a <iupdate>

  return tot;
    800041bc:	000a051b          	sext.w	a0,s4
}
    800041c0:	70a6                	ld	ra,104(sp)
    800041c2:	7406                	ld	s0,96(sp)
    800041c4:	64e6                	ld	s1,88(sp)
    800041c6:	6946                	ld	s2,80(sp)
    800041c8:	69a6                	ld	s3,72(sp)
    800041ca:	6a06                	ld	s4,64(sp)
    800041cc:	7ae2                	ld	s5,56(sp)
    800041ce:	7b42                	ld	s6,48(sp)
    800041d0:	7ba2                	ld	s7,40(sp)
    800041d2:	7c02                	ld	s8,32(sp)
    800041d4:	6ce2                	ld	s9,24(sp)
    800041d6:	6d42                	ld	s10,16(sp)
    800041d8:	6da2                	ld	s11,8(sp)
    800041da:	6165                	addi	sp,sp,112
    800041dc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041de:	8a5e                	mv	s4,s7
    800041e0:	bfc9                	j	800041b2 <writei+0xe2>
    return -1;
    800041e2:	557d                	li	a0,-1
}
    800041e4:	8082                	ret
    return -1;
    800041e6:	557d                	li	a0,-1
    800041e8:	bfe1                	j	800041c0 <writei+0xf0>
    return -1;
    800041ea:	557d                	li	a0,-1
    800041ec:	bfd1                	j	800041c0 <writei+0xf0>

00000000800041ee <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041ee:	1141                	addi	sp,sp,-16
    800041f0:	e406                	sd	ra,8(sp)
    800041f2:	e022                	sd	s0,0(sp)
    800041f4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041f6:	4639                	li	a2,14
    800041f8:	ffffd097          	auipc	ra,0xffffd
    800041fc:	bd2080e7          	jalr	-1070(ra) # 80000dca <strncmp>
}
    80004200:	60a2                	ld	ra,8(sp)
    80004202:	6402                	ld	s0,0(sp)
    80004204:	0141                	addi	sp,sp,16
    80004206:	8082                	ret

0000000080004208 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004208:	7139                	addi	sp,sp,-64
    8000420a:	fc06                	sd	ra,56(sp)
    8000420c:	f822                	sd	s0,48(sp)
    8000420e:	f426                	sd	s1,40(sp)
    80004210:	f04a                	sd	s2,32(sp)
    80004212:	ec4e                	sd	s3,24(sp)
    80004214:	e852                	sd	s4,16(sp)
    80004216:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004218:	04451703          	lh	a4,68(a0)
    8000421c:	4785                	li	a5,1
    8000421e:	00f71a63          	bne	a4,a5,80004232 <dirlookup+0x2a>
    80004222:	892a                	mv	s2,a0
    80004224:	89ae                	mv	s3,a1
    80004226:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004228:	457c                	lw	a5,76(a0)
    8000422a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000422c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000422e:	e79d                	bnez	a5,8000425c <dirlookup+0x54>
    80004230:	a8a5                	j	800042a8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004232:	00004517          	auipc	a0,0x4
    80004236:	41e50513          	addi	a0,a0,1054 # 80008650 <syscalls+0x1b0>
    8000423a:	ffffc097          	auipc	ra,0xffffc
    8000423e:	304080e7          	jalr	772(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004242:	00004517          	auipc	a0,0x4
    80004246:	42650513          	addi	a0,a0,1062 # 80008668 <syscalls+0x1c8>
    8000424a:	ffffc097          	auipc	ra,0xffffc
    8000424e:	2f4080e7          	jalr	756(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004252:	24c1                	addiw	s1,s1,16
    80004254:	04c92783          	lw	a5,76(s2)
    80004258:	04f4f763          	bgeu	s1,a5,800042a6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000425c:	4741                	li	a4,16
    8000425e:	86a6                	mv	a3,s1
    80004260:	fc040613          	addi	a2,s0,-64
    80004264:	4581                	li	a1,0
    80004266:	854a                	mv	a0,s2
    80004268:	00000097          	auipc	ra,0x0
    8000426c:	d70080e7          	jalr	-656(ra) # 80003fd8 <readi>
    80004270:	47c1                	li	a5,16
    80004272:	fcf518e3          	bne	a0,a5,80004242 <dirlookup+0x3a>
    if(de.inum == 0)
    80004276:	fc045783          	lhu	a5,-64(s0)
    8000427a:	dfe1                	beqz	a5,80004252 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000427c:	fc240593          	addi	a1,s0,-62
    80004280:	854e                	mv	a0,s3
    80004282:	00000097          	auipc	ra,0x0
    80004286:	f6c080e7          	jalr	-148(ra) # 800041ee <namecmp>
    8000428a:	f561                	bnez	a0,80004252 <dirlookup+0x4a>
      if(poff)
    8000428c:	000a0463          	beqz	s4,80004294 <dirlookup+0x8c>
        *poff = off;
    80004290:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004294:	fc045583          	lhu	a1,-64(s0)
    80004298:	00092503          	lw	a0,0(s2)
    8000429c:	fffff097          	auipc	ra,0xfffff
    800042a0:	754080e7          	jalr	1876(ra) # 800039f0 <iget>
    800042a4:	a011                	j	800042a8 <dirlookup+0xa0>
  return 0;
    800042a6:	4501                	li	a0,0
}
    800042a8:	70e2                	ld	ra,56(sp)
    800042aa:	7442                	ld	s0,48(sp)
    800042ac:	74a2                	ld	s1,40(sp)
    800042ae:	7902                	ld	s2,32(sp)
    800042b0:	69e2                	ld	s3,24(sp)
    800042b2:	6a42                	ld	s4,16(sp)
    800042b4:	6121                	addi	sp,sp,64
    800042b6:	8082                	ret

00000000800042b8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800042b8:	711d                	addi	sp,sp,-96
    800042ba:	ec86                	sd	ra,88(sp)
    800042bc:	e8a2                	sd	s0,80(sp)
    800042be:	e4a6                	sd	s1,72(sp)
    800042c0:	e0ca                	sd	s2,64(sp)
    800042c2:	fc4e                	sd	s3,56(sp)
    800042c4:	f852                	sd	s4,48(sp)
    800042c6:	f456                	sd	s5,40(sp)
    800042c8:	f05a                	sd	s6,32(sp)
    800042ca:	ec5e                	sd	s7,24(sp)
    800042cc:	e862                	sd	s8,16(sp)
    800042ce:	e466                	sd	s9,8(sp)
    800042d0:	1080                	addi	s0,sp,96
    800042d2:	84aa                	mv	s1,a0
    800042d4:	8b2e                	mv	s6,a1
    800042d6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042d8:	00054703          	lbu	a4,0(a0)
    800042dc:	02f00793          	li	a5,47
    800042e0:	02f70363          	beq	a4,a5,80004306 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042e4:	ffffe097          	auipc	ra,0xffffe
    800042e8:	a5e080e7          	jalr	-1442(ra) # 80001d42 <myproc>
    800042ec:	17053503          	ld	a0,368(a0)
    800042f0:	00000097          	auipc	ra,0x0
    800042f4:	9f6080e7          	jalr	-1546(ra) # 80003ce6 <idup>
    800042f8:	89aa                	mv	s3,a0
  while(*path == '/')
    800042fa:	02f00913          	li	s2,47
  len = path - s;
    800042fe:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004300:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004302:	4c05                	li	s8,1
    80004304:	a865                	j	800043bc <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004306:	4585                	li	a1,1
    80004308:	4505                	li	a0,1
    8000430a:	fffff097          	auipc	ra,0xfffff
    8000430e:	6e6080e7          	jalr	1766(ra) # 800039f0 <iget>
    80004312:	89aa                	mv	s3,a0
    80004314:	b7dd                	j	800042fa <namex+0x42>
      iunlockput(ip);
    80004316:	854e                	mv	a0,s3
    80004318:	00000097          	auipc	ra,0x0
    8000431c:	c6e080e7          	jalr	-914(ra) # 80003f86 <iunlockput>
      return 0;
    80004320:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004322:	854e                	mv	a0,s3
    80004324:	60e6                	ld	ra,88(sp)
    80004326:	6446                	ld	s0,80(sp)
    80004328:	64a6                	ld	s1,72(sp)
    8000432a:	6906                	ld	s2,64(sp)
    8000432c:	79e2                	ld	s3,56(sp)
    8000432e:	7a42                	ld	s4,48(sp)
    80004330:	7aa2                	ld	s5,40(sp)
    80004332:	7b02                	ld	s6,32(sp)
    80004334:	6be2                	ld	s7,24(sp)
    80004336:	6c42                	ld	s8,16(sp)
    80004338:	6ca2                	ld	s9,8(sp)
    8000433a:	6125                	addi	sp,sp,96
    8000433c:	8082                	ret
      iunlock(ip);
    8000433e:	854e                	mv	a0,s3
    80004340:	00000097          	auipc	ra,0x0
    80004344:	aa6080e7          	jalr	-1370(ra) # 80003de6 <iunlock>
      return ip;
    80004348:	bfe9                	j	80004322 <namex+0x6a>
      iunlockput(ip);
    8000434a:	854e                	mv	a0,s3
    8000434c:	00000097          	auipc	ra,0x0
    80004350:	c3a080e7          	jalr	-966(ra) # 80003f86 <iunlockput>
      return 0;
    80004354:	89d2                	mv	s3,s4
    80004356:	b7f1                	j	80004322 <namex+0x6a>
  len = path - s;
    80004358:	40b48633          	sub	a2,s1,a1
    8000435c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004360:	094cd463          	bge	s9,s4,800043e8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004364:	4639                	li	a2,14
    80004366:	8556                	mv	a0,s5
    80004368:	ffffd097          	auipc	ra,0xffffd
    8000436c:	9ea080e7          	jalr	-1558(ra) # 80000d52 <memmove>
  while(*path == '/')
    80004370:	0004c783          	lbu	a5,0(s1)
    80004374:	01279763          	bne	a5,s2,80004382 <namex+0xca>
    path++;
    80004378:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000437a:	0004c783          	lbu	a5,0(s1)
    8000437e:	ff278de3          	beq	a5,s2,80004378 <namex+0xc0>
    ilock(ip);
    80004382:	854e                	mv	a0,s3
    80004384:	00000097          	auipc	ra,0x0
    80004388:	9a0080e7          	jalr	-1632(ra) # 80003d24 <ilock>
    if(ip->type != T_DIR){
    8000438c:	04499783          	lh	a5,68(s3)
    80004390:	f98793e3          	bne	a5,s8,80004316 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004394:	000b0563          	beqz	s6,8000439e <namex+0xe6>
    80004398:	0004c783          	lbu	a5,0(s1)
    8000439c:	d3cd                	beqz	a5,8000433e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000439e:	865e                	mv	a2,s7
    800043a0:	85d6                	mv	a1,s5
    800043a2:	854e                	mv	a0,s3
    800043a4:	00000097          	auipc	ra,0x0
    800043a8:	e64080e7          	jalr	-412(ra) # 80004208 <dirlookup>
    800043ac:	8a2a                	mv	s4,a0
    800043ae:	dd51                	beqz	a0,8000434a <namex+0x92>
    iunlockput(ip);
    800043b0:	854e                	mv	a0,s3
    800043b2:	00000097          	auipc	ra,0x0
    800043b6:	bd4080e7          	jalr	-1068(ra) # 80003f86 <iunlockput>
    ip = next;
    800043ba:	89d2                	mv	s3,s4
  while(*path == '/')
    800043bc:	0004c783          	lbu	a5,0(s1)
    800043c0:	05279763          	bne	a5,s2,8000440e <namex+0x156>
    path++;
    800043c4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043c6:	0004c783          	lbu	a5,0(s1)
    800043ca:	ff278de3          	beq	a5,s2,800043c4 <namex+0x10c>
  if(*path == 0)
    800043ce:	c79d                	beqz	a5,800043fc <namex+0x144>
    path++;
    800043d0:	85a6                	mv	a1,s1
  len = path - s;
    800043d2:	8a5e                	mv	s4,s7
    800043d4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800043d6:	01278963          	beq	a5,s2,800043e8 <namex+0x130>
    800043da:	dfbd                	beqz	a5,80004358 <namex+0xa0>
    path++;
    800043dc:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800043de:	0004c783          	lbu	a5,0(s1)
    800043e2:	ff279ce3          	bne	a5,s2,800043da <namex+0x122>
    800043e6:	bf8d                	j	80004358 <namex+0xa0>
    memmove(name, s, len);
    800043e8:	2601                	sext.w	a2,a2
    800043ea:	8556                	mv	a0,s5
    800043ec:	ffffd097          	auipc	ra,0xffffd
    800043f0:	966080e7          	jalr	-1690(ra) # 80000d52 <memmove>
    name[len] = 0;
    800043f4:	9a56                	add	s4,s4,s5
    800043f6:	000a0023          	sb	zero,0(s4)
    800043fa:	bf9d                	j	80004370 <namex+0xb8>
  if(nameiparent){
    800043fc:	f20b03e3          	beqz	s6,80004322 <namex+0x6a>
    iput(ip);
    80004400:	854e                	mv	a0,s3
    80004402:	00000097          	auipc	ra,0x0
    80004406:	adc080e7          	jalr	-1316(ra) # 80003ede <iput>
    return 0;
    8000440a:	4981                	li	s3,0
    8000440c:	bf19                	j	80004322 <namex+0x6a>
  if(*path == 0)
    8000440e:	d7fd                	beqz	a5,800043fc <namex+0x144>
  while(*path != '/' && *path != 0)
    80004410:	0004c783          	lbu	a5,0(s1)
    80004414:	85a6                	mv	a1,s1
    80004416:	b7d1                	j	800043da <namex+0x122>

0000000080004418 <dirlink>:
{
    80004418:	7139                	addi	sp,sp,-64
    8000441a:	fc06                	sd	ra,56(sp)
    8000441c:	f822                	sd	s0,48(sp)
    8000441e:	f426                	sd	s1,40(sp)
    80004420:	f04a                	sd	s2,32(sp)
    80004422:	ec4e                	sd	s3,24(sp)
    80004424:	e852                	sd	s4,16(sp)
    80004426:	0080                	addi	s0,sp,64
    80004428:	892a                	mv	s2,a0
    8000442a:	8a2e                	mv	s4,a1
    8000442c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000442e:	4601                	li	a2,0
    80004430:	00000097          	auipc	ra,0x0
    80004434:	dd8080e7          	jalr	-552(ra) # 80004208 <dirlookup>
    80004438:	e93d                	bnez	a0,800044ae <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000443a:	04c92483          	lw	s1,76(s2)
    8000443e:	c49d                	beqz	s1,8000446c <dirlink+0x54>
    80004440:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004442:	4741                	li	a4,16
    80004444:	86a6                	mv	a3,s1
    80004446:	fc040613          	addi	a2,s0,-64
    8000444a:	4581                	li	a1,0
    8000444c:	854a                	mv	a0,s2
    8000444e:	00000097          	auipc	ra,0x0
    80004452:	b8a080e7          	jalr	-1142(ra) # 80003fd8 <readi>
    80004456:	47c1                	li	a5,16
    80004458:	06f51163          	bne	a0,a5,800044ba <dirlink+0xa2>
    if(de.inum == 0)
    8000445c:	fc045783          	lhu	a5,-64(s0)
    80004460:	c791                	beqz	a5,8000446c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004462:	24c1                	addiw	s1,s1,16
    80004464:	04c92783          	lw	a5,76(s2)
    80004468:	fcf4ede3          	bltu	s1,a5,80004442 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000446c:	4639                	li	a2,14
    8000446e:	85d2                	mv	a1,s4
    80004470:	fc240513          	addi	a0,s0,-62
    80004474:	ffffd097          	auipc	ra,0xffffd
    80004478:	992080e7          	jalr	-1646(ra) # 80000e06 <strncpy>
  de.inum = inum;
    8000447c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004480:	4741                	li	a4,16
    80004482:	86a6                	mv	a3,s1
    80004484:	fc040613          	addi	a2,s0,-64
    80004488:	4581                	li	a1,0
    8000448a:	854a                	mv	a0,s2
    8000448c:	00000097          	auipc	ra,0x0
    80004490:	c44080e7          	jalr	-956(ra) # 800040d0 <writei>
    80004494:	872a                	mv	a4,a0
    80004496:	47c1                	li	a5,16
  return 0;
    80004498:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000449a:	02f71863          	bne	a4,a5,800044ca <dirlink+0xb2>
}
    8000449e:	70e2                	ld	ra,56(sp)
    800044a0:	7442                	ld	s0,48(sp)
    800044a2:	74a2                	ld	s1,40(sp)
    800044a4:	7902                	ld	s2,32(sp)
    800044a6:	69e2                	ld	s3,24(sp)
    800044a8:	6a42                	ld	s4,16(sp)
    800044aa:	6121                	addi	sp,sp,64
    800044ac:	8082                	ret
    iput(ip);
    800044ae:	00000097          	auipc	ra,0x0
    800044b2:	a30080e7          	jalr	-1488(ra) # 80003ede <iput>
    return -1;
    800044b6:	557d                	li	a0,-1
    800044b8:	b7dd                	j	8000449e <dirlink+0x86>
      panic("dirlink read");
    800044ba:	00004517          	auipc	a0,0x4
    800044be:	1be50513          	addi	a0,a0,446 # 80008678 <syscalls+0x1d8>
    800044c2:	ffffc097          	auipc	ra,0xffffc
    800044c6:	07c080e7          	jalr	124(ra) # 8000053e <panic>
    panic("dirlink");
    800044ca:	00004517          	auipc	a0,0x4
    800044ce:	2be50513          	addi	a0,a0,702 # 80008788 <syscalls+0x2e8>
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	06c080e7          	jalr	108(ra) # 8000053e <panic>

00000000800044da <namei>:

struct inode*
namei(char *path)
{
    800044da:	1101                	addi	sp,sp,-32
    800044dc:	ec06                	sd	ra,24(sp)
    800044de:	e822                	sd	s0,16(sp)
    800044e0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044e2:	fe040613          	addi	a2,s0,-32
    800044e6:	4581                	li	a1,0
    800044e8:	00000097          	auipc	ra,0x0
    800044ec:	dd0080e7          	jalr	-560(ra) # 800042b8 <namex>
}
    800044f0:	60e2                	ld	ra,24(sp)
    800044f2:	6442                	ld	s0,16(sp)
    800044f4:	6105                	addi	sp,sp,32
    800044f6:	8082                	ret

00000000800044f8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044f8:	1141                	addi	sp,sp,-16
    800044fa:	e406                	sd	ra,8(sp)
    800044fc:	e022                	sd	s0,0(sp)
    800044fe:	0800                	addi	s0,sp,16
    80004500:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004502:	4585                	li	a1,1
    80004504:	00000097          	auipc	ra,0x0
    80004508:	db4080e7          	jalr	-588(ra) # 800042b8 <namex>
}
    8000450c:	60a2                	ld	ra,8(sp)
    8000450e:	6402                	ld	s0,0(sp)
    80004510:	0141                	addi	sp,sp,16
    80004512:	8082                	ret

0000000080004514 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004514:	1101                	addi	sp,sp,-32
    80004516:	ec06                	sd	ra,24(sp)
    80004518:	e822                	sd	s0,16(sp)
    8000451a:	e426                	sd	s1,8(sp)
    8000451c:	e04a                	sd	s2,0(sp)
    8000451e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004520:	0001d917          	auipc	s2,0x1d
    80004524:	69890913          	addi	s2,s2,1688 # 80021bb8 <log>
    80004528:	01892583          	lw	a1,24(s2)
    8000452c:	02892503          	lw	a0,40(s2)
    80004530:	fffff097          	auipc	ra,0xfffff
    80004534:	ff2080e7          	jalr	-14(ra) # 80003522 <bread>
    80004538:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000453a:	02c92683          	lw	a3,44(s2)
    8000453e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004540:	02d05763          	blez	a3,8000456e <write_head+0x5a>
    80004544:	0001d797          	auipc	a5,0x1d
    80004548:	6a478793          	addi	a5,a5,1700 # 80021be8 <log+0x30>
    8000454c:	05c50713          	addi	a4,a0,92
    80004550:	36fd                	addiw	a3,a3,-1
    80004552:	1682                	slli	a3,a3,0x20
    80004554:	9281                	srli	a3,a3,0x20
    80004556:	068a                	slli	a3,a3,0x2
    80004558:	0001d617          	auipc	a2,0x1d
    8000455c:	69460613          	addi	a2,a2,1684 # 80021bec <log+0x34>
    80004560:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004562:	4390                	lw	a2,0(a5)
    80004564:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004566:	0791                	addi	a5,a5,4
    80004568:	0711                	addi	a4,a4,4
    8000456a:	fed79ce3          	bne	a5,a3,80004562 <write_head+0x4e>
  }
  bwrite(buf);
    8000456e:	8526                	mv	a0,s1
    80004570:	fffff097          	auipc	ra,0xfffff
    80004574:	0a4080e7          	jalr	164(ra) # 80003614 <bwrite>
  brelse(buf);
    80004578:	8526                	mv	a0,s1
    8000457a:	fffff097          	auipc	ra,0xfffff
    8000457e:	0d8080e7          	jalr	216(ra) # 80003652 <brelse>
}
    80004582:	60e2                	ld	ra,24(sp)
    80004584:	6442                	ld	s0,16(sp)
    80004586:	64a2                	ld	s1,8(sp)
    80004588:	6902                	ld	s2,0(sp)
    8000458a:	6105                	addi	sp,sp,32
    8000458c:	8082                	ret

000000008000458e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000458e:	0001d797          	auipc	a5,0x1d
    80004592:	6567a783          	lw	a5,1622(a5) # 80021be4 <log+0x2c>
    80004596:	0af05d63          	blez	a5,80004650 <install_trans+0xc2>
{
    8000459a:	7139                	addi	sp,sp,-64
    8000459c:	fc06                	sd	ra,56(sp)
    8000459e:	f822                	sd	s0,48(sp)
    800045a0:	f426                	sd	s1,40(sp)
    800045a2:	f04a                	sd	s2,32(sp)
    800045a4:	ec4e                	sd	s3,24(sp)
    800045a6:	e852                	sd	s4,16(sp)
    800045a8:	e456                	sd	s5,8(sp)
    800045aa:	e05a                	sd	s6,0(sp)
    800045ac:	0080                	addi	s0,sp,64
    800045ae:	8b2a                	mv	s6,a0
    800045b0:	0001da97          	auipc	s5,0x1d
    800045b4:	638a8a93          	addi	s5,s5,1592 # 80021be8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045b8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045ba:	0001d997          	auipc	s3,0x1d
    800045be:	5fe98993          	addi	s3,s3,1534 # 80021bb8 <log>
    800045c2:	a035                	j	800045ee <install_trans+0x60>
      bunpin(dbuf);
    800045c4:	8526                	mv	a0,s1
    800045c6:	fffff097          	auipc	ra,0xfffff
    800045ca:	166080e7          	jalr	358(ra) # 8000372c <bunpin>
    brelse(lbuf);
    800045ce:	854a                	mv	a0,s2
    800045d0:	fffff097          	auipc	ra,0xfffff
    800045d4:	082080e7          	jalr	130(ra) # 80003652 <brelse>
    brelse(dbuf);
    800045d8:	8526                	mv	a0,s1
    800045da:	fffff097          	auipc	ra,0xfffff
    800045de:	078080e7          	jalr	120(ra) # 80003652 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045e2:	2a05                	addiw	s4,s4,1
    800045e4:	0a91                	addi	s5,s5,4
    800045e6:	02c9a783          	lw	a5,44(s3)
    800045ea:	04fa5963          	bge	s4,a5,8000463c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045ee:	0189a583          	lw	a1,24(s3)
    800045f2:	014585bb          	addw	a1,a1,s4
    800045f6:	2585                	addiw	a1,a1,1
    800045f8:	0289a503          	lw	a0,40(s3)
    800045fc:	fffff097          	auipc	ra,0xfffff
    80004600:	f26080e7          	jalr	-218(ra) # 80003522 <bread>
    80004604:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004606:	000aa583          	lw	a1,0(s5)
    8000460a:	0289a503          	lw	a0,40(s3)
    8000460e:	fffff097          	auipc	ra,0xfffff
    80004612:	f14080e7          	jalr	-236(ra) # 80003522 <bread>
    80004616:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004618:	40000613          	li	a2,1024
    8000461c:	05890593          	addi	a1,s2,88
    80004620:	05850513          	addi	a0,a0,88
    80004624:	ffffc097          	auipc	ra,0xffffc
    80004628:	72e080e7          	jalr	1838(ra) # 80000d52 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000462c:	8526                	mv	a0,s1
    8000462e:	fffff097          	auipc	ra,0xfffff
    80004632:	fe6080e7          	jalr	-26(ra) # 80003614 <bwrite>
    if(recovering == 0)
    80004636:	f80b1ce3          	bnez	s6,800045ce <install_trans+0x40>
    8000463a:	b769                	j	800045c4 <install_trans+0x36>
}
    8000463c:	70e2                	ld	ra,56(sp)
    8000463e:	7442                	ld	s0,48(sp)
    80004640:	74a2                	ld	s1,40(sp)
    80004642:	7902                	ld	s2,32(sp)
    80004644:	69e2                	ld	s3,24(sp)
    80004646:	6a42                	ld	s4,16(sp)
    80004648:	6aa2                	ld	s5,8(sp)
    8000464a:	6b02                	ld	s6,0(sp)
    8000464c:	6121                	addi	sp,sp,64
    8000464e:	8082                	ret
    80004650:	8082                	ret

0000000080004652 <initlog>:
{
    80004652:	7179                	addi	sp,sp,-48
    80004654:	f406                	sd	ra,40(sp)
    80004656:	f022                	sd	s0,32(sp)
    80004658:	ec26                	sd	s1,24(sp)
    8000465a:	e84a                	sd	s2,16(sp)
    8000465c:	e44e                	sd	s3,8(sp)
    8000465e:	1800                	addi	s0,sp,48
    80004660:	892a                	mv	s2,a0
    80004662:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004664:	0001d497          	auipc	s1,0x1d
    80004668:	55448493          	addi	s1,s1,1364 # 80021bb8 <log>
    8000466c:	00004597          	auipc	a1,0x4
    80004670:	01c58593          	addi	a1,a1,28 # 80008688 <syscalls+0x1e8>
    80004674:	8526                	mv	a0,s1
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	4de080e7          	jalr	1246(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000467e:	0149a583          	lw	a1,20(s3)
    80004682:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004684:	0109a783          	lw	a5,16(s3)
    80004688:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000468a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000468e:	854a                	mv	a0,s2
    80004690:	fffff097          	auipc	ra,0xfffff
    80004694:	e92080e7          	jalr	-366(ra) # 80003522 <bread>
  log.lh.n = lh->n;
    80004698:	4d3c                	lw	a5,88(a0)
    8000469a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000469c:	02f05563          	blez	a5,800046c6 <initlog+0x74>
    800046a0:	05c50713          	addi	a4,a0,92
    800046a4:	0001d697          	auipc	a3,0x1d
    800046a8:	54468693          	addi	a3,a3,1348 # 80021be8 <log+0x30>
    800046ac:	37fd                	addiw	a5,a5,-1
    800046ae:	1782                	slli	a5,a5,0x20
    800046b0:	9381                	srli	a5,a5,0x20
    800046b2:	078a                	slli	a5,a5,0x2
    800046b4:	06050613          	addi	a2,a0,96
    800046b8:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800046ba:	4310                	lw	a2,0(a4)
    800046bc:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800046be:	0711                	addi	a4,a4,4
    800046c0:	0691                	addi	a3,a3,4
    800046c2:	fef71ce3          	bne	a4,a5,800046ba <initlog+0x68>
  brelse(buf);
    800046c6:	fffff097          	auipc	ra,0xfffff
    800046ca:	f8c080e7          	jalr	-116(ra) # 80003652 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046ce:	4505                	li	a0,1
    800046d0:	00000097          	auipc	ra,0x0
    800046d4:	ebe080e7          	jalr	-322(ra) # 8000458e <install_trans>
  log.lh.n = 0;
    800046d8:	0001d797          	auipc	a5,0x1d
    800046dc:	5007a623          	sw	zero,1292(a5) # 80021be4 <log+0x2c>
  write_head(); // clear the log
    800046e0:	00000097          	auipc	ra,0x0
    800046e4:	e34080e7          	jalr	-460(ra) # 80004514 <write_head>
}
    800046e8:	70a2                	ld	ra,40(sp)
    800046ea:	7402                	ld	s0,32(sp)
    800046ec:	64e2                	ld	s1,24(sp)
    800046ee:	6942                	ld	s2,16(sp)
    800046f0:	69a2                	ld	s3,8(sp)
    800046f2:	6145                	addi	sp,sp,48
    800046f4:	8082                	ret

00000000800046f6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046f6:	1101                	addi	sp,sp,-32
    800046f8:	ec06                	sd	ra,24(sp)
    800046fa:	e822                	sd	s0,16(sp)
    800046fc:	e426                	sd	s1,8(sp)
    800046fe:	e04a                	sd	s2,0(sp)
    80004700:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004702:	0001d517          	auipc	a0,0x1d
    80004706:	4b650513          	addi	a0,a0,1206 # 80021bb8 <log>
    8000470a:	ffffc097          	auipc	ra,0xffffc
    8000470e:	4da080e7          	jalr	1242(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004712:	0001d497          	auipc	s1,0x1d
    80004716:	4a648493          	addi	s1,s1,1190 # 80021bb8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000471a:	4979                	li	s2,30
    8000471c:	a039                	j	8000472a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000471e:	85a6                	mv	a1,s1
    80004720:	8526                	mv	a0,s1
    80004722:	ffffe097          	auipc	ra,0xffffe
    80004726:	e08080e7          	jalr	-504(ra) # 8000252a <sleep>
    if(log.committing){
    8000472a:	50dc                	lw	a5,36(s1)
    8000472c:	fbed                	bnez	a5,8000471e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000472e:	509c                	lw	a5,32(s1)
    80004730:	0017871b          	addiw	a4,a5,1
    80004734:	0007069b          	sext.w	a3,a4
    80004738:	0027179b          	slliw	a5,a4,0x2
    8000473c:	9fb9                	addw	a5,a5,a4
    8000473e:	0017979b          	slliw	a5,a5,0x1
    80004742:	54d8                	lw	a4,44(s1)
    80004744:	9fb9                	addw	a5,a5,a4
    80004746:	00f95963          	bge	s2,a5,80004758 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000474a:	85a6                	mv	a1,s1
    8000474c:	8526                	mv	a0,s1
    8000474e:	ffffe097          	auipc	ra,0xffffe
    80004752:	ddc080e7          	jalr	-548(ra) # 8000252a <sleep>
    80004756:	bfd1                	j	8000472a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004758:	0001d517          	auipc	a0,0x1d
    8000475c:	46050513          	addi	a0,a0,1120 # 80021bb8 <log>
    80004760:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	536080e7          	jalr	1334(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000476a:	60e2                	ld	ra,24(sp)
    8000476c:	6442                	ld	s0,16(sp)
    8000476e:	64a2                	ld	s1,8(sp)
    80004770:	6902                	ld	s2,0(sp)
    80004772:	6105                	addi	sp,sp,32
    80004774:	8082                	ret

0000000080004776 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004776:	7139                	addi	sp,sp,-64
    80004778:	fc06                	sd	ra,56(sp)
    8000477a:	f822                	sd	s0,48(sp)
    8000477c:	f426                	sd	s1,40(sp)
    8000477e:	f04a                	sd	s2,32(sp)
    80004780:	ec4e                	sd	s3,24(sp)
    80004782:	e852                	sd	s4,16(sp)
    80004784:	e456                	sd	s5,8(sp)
    80004786:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004788:	0001d497          	auipc	s1,0x1d
    8000478c:	43048493          	addi	s1,s1,1072 # 80021bb8 <log>
    80004790:	8526                	mv	a0,s1
    80004792:	ffffc097          	auipc	ra,0xffffc
    80004796:	452080e7          	jalr	1106(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000479a:	509c                	lw	a5,32(s1)
    8000479c:	37fd                	addiw	a5,a5,-1
    8000479e:	0007891b          	sext.w	s2,a5
    800047a2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800047a4:	50dc                	lw	a5,36(s1)
    800047a6:	efb9                	bnez	a5,80004804 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800047a8:	06091663          	bnez	s2,80004814 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800047ac:	0001d497          	auipc	s1,0x1d
    800047b0:	40c48493          	addi	s1,s1,1036 # 80021bb8 <log>
    800047b4:	4785                	li	a5,1
    800047b6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800047b8:	8526                	mv	a0,s1
    800047ba:	ffffc097          	auipc	ra,0xffffc
    800047be:	4de080e7          	jalr	1246(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047c2:	54dc                	lw	a5,44(s1)
    800047c4:	06f04763          	bgtz	a5,80004832 <end_op+0xbc>
    acquire(&log.lock);
    800047c8:	0001d497          	auipc	s1,0x1d
    800047cc:	3f048493          	addi	s1,s1,1008 # 80021bb8 <log>
    800047d0:	8526                	mv	a0,s1
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	412080e7          	jalr	1042(ra) # 80000be4 <acquire>
    log.committing = 0;
    800047da:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047de:	8526                	mv	a0,s1
    800047e0:	ffffe097          	auipc	ra,0xffffe
    800047e4:	ef0080e7          	jalr	-272(ra) # 800026d0 <wakeup>
    release(&log.lock);
    800047e8:	8526                	mv	a0,s1
    800047ea:	ffffc097          	auipc	ra,0xffffc
    800047ee:	4ae080e7          	jalr	1198(ra) # 80000c98 <release>
}
    800047f2:	70e2                	ld	ra,56(sp)
    800047f4:	7442                	ld	s0,48(sp)
    800047f6:	74a2                	ld	s1,40(sp)
    800047f8:	7902                	ld	s2,32(sp)
    800047fa:	69e2                	ld	s3,24(sp)
    800047fc:	6a42                	ld	s4,16(sp)
    800047fe:	6aa2                	ld	s5,8(sp)
    80004800:	6121                	addi	sp,sp,64
    80004802:	8082                	ret
    panic("log.committing");
    80004804:	00004517          	auipc	a0,0x4
    80004808:	e8c50513          	addi	a0,a0,-372 # 80008690 <syscalls+0x1f0>
    8000480c:	ffffc097          	auipc	ra,0xffffc
    80004810:	d32080e7          	jalr	-718(ra) # 8000053e <panic>
    wakeup(&log);
    80004814:	0001d497          	auipc	s1,0x1d
    80004818:	3a448493          	addi	s1,s1,932 # 80021bb8 <log>
    8000481c:	8526                	mv	a0,s1
    8000481e:	ffffe097          	auipc	ra,0xffffe
    80004822:	eb2080e7          	jalr	-334(ra) # 800026d0 <wakeup>
  release(&log.lock);
    80004826:	8526                	mv	a0,s1
    80004828:	ffffc097          	auipc	ra,0xffffc
    8000482c:	470080e7          	jalr	1136(ra) # 80000c98 <release>
  if(do_commit){
    80004830:	b7c9                	j	800047f2 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004832:	0001da97          	auipc	s5,0x1d
    80004836:	3b6a8a93          	addi	s5,s5,950 # 80021be8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000483a:	0001da17          	auipc	s4,0x1d
    8000483e:	37ea0a13          	addi	s4,s4,894 # 80021bb8 <log>
    80004842:	018a2583          	lw	a1,24(s4)
    80004846:	012585bb          	addw	a1,a1,s2
    8000484a:	2585                	addiw	a1,a1,1
    8000484c:	028a2503          	lw	a0,40(s4)
    80004850:	fffff097          	auipc	ra,0xfffff
    80004854:	cd2080e7          	jalr	-814(ra) # 80003522 <bread>
    80004858:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000485a:	000aa583          	lw	a1,0(s5)
    8000485e:	028a2503          	lw	a0,40(s4)
    80004862:	fffff097          	auipc	ra,0xfffff
    80004866:	cc0080e7          	jalr	-832(ra) # 80003522 <bread>
    8000486a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000486c:	40000613          	li	a2,1024
    80004870:	05850593          	addi	a1,a0,88
    80004874:	05848513          	addi	a0,s1,88
    80004878:	ffffc097          	auipc	ra,0xffffc
    8000487c:	4da080e7          	jalr	1242(ra) # 80000d52 <memmove>
    bwrite(to);  // write the log
    80004880:	8526                	mv	a0,s1
    80004882:	fffff097          	auipc	ra,0xfffff
    80004886:	d92080e7          	jalr	-622(ra) # 80003614 <bwrite>
    brelse(from);
    8000488a:	854e                	mv	a0,s3
    8000488c:	fffff097          	auipc	ra,0xfffff
    80004890:	dc6080e7          	jalr	-570(ra) # 80003652 <brelse>
    brelse(to);
    80004894:	8526                	mv	a0,s1
    80004896:	fffff097          	auipc	ra,0xfffff
    8000489a:	dbc080e7          	jalr	-580(ra) # 80003652 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000489e:	2905                	addiw	s2,s2,1
    800048a0:	0a91                	addi	s5,s5,4
    800048a2:	02ca2783          	lw	a5,44(s4)
    800048a6:	f8f94ee3          	blt	s2,a5,80004842 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800048aa:	00000097          	auipc	ra,0x0
    800048ae:	c6a080e7          	jalr	-918(ra) # 80004514 <write_head>
    install_trans(0); // Now install writes to home locations
    800048b2:	4501                	li	a0,0
    800048b4:	00000097          	auipc	ra,0x0
    800048b8:	cda080e7          	jalr	-806(ra) # 8000458e <install_trans>
    log.lh.n = 0;
    800048bc:	0001d797          	auipc	a5,0x1d
    800048c0:	3207a423          	sw	zero,808(a5) # 80021be4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048c4:	00000097          	auipc	ra,0x0
    800048c8:	c50080e7          	jalr	-944(ra) # 80004514 <write_head>
    800048cc:	bdf5                	j	800047c8 <end_op+0x52>

00000000800048ce <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048ce:	1101                	addi	sp,sp,-32
    800048d0:	ec06                	sd	ra,24(sp)
    800048d2:	e822                	sd	s0,16(sp)
    800048d4:	e426                	sd	s1,8(sp)
    800048d6:	e04a                	sd	s2,0(sp)
    800048d8:	1000                	addi	s0,sp,32
    800048da:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048dc:	0001d917          	auipc	s2,0x1d
    800048e0:	2dc90913          	addi	s2,s2,732 # 80021bb8 <log>
    800048e4:	854a                	mv	a0,s2
    800048e6:	ffffc097          	auipc	ra,0xffffc
    800048ea:	2fe080e7          	jalr	766(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048ee:	02c92603          	lw	a2,44(s2)
    800048f2:	47f5                	li	a5,29
    800048f4:	06c7c563          	blt	a5,a2,8000495e <log_write+0x90>
    800048f8:	0001d797          	auipc	a5,0x1d
    800048fc:	2dc7a783          	lw	a5,732(a5) # 80021bd4 <log+0x1c>
    80004900:	37fd                	addiw	a5,a5,-1
    80004902:	04f65e63          	bge	a2,a5,8000495e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004906:	0001d797          	auipc	a5,0x1d
    8000490a:	2d27a783          	lw	a5,722(a5) # 80021bd8 <log+0x20>
    8000490e:	06f05063          	blez	a5,8000496e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004912:	4781                	li	a5,0
    80004914:	06c05563          	blez	a2,8000497e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004918:	44cc                	lw	a1,12(s1)
    8000491a:	0001d717          	auipc	a4,0x1d
    8000491e:	2ce70713          	addi	a4,a4,718 # 80021be8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004922:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004924:	4314                	lw	a3,0(a4)
    80004926:	04b68c63          	beq	a3,a1,8000497e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000492a:	2785                	addiw	a5,a5,1
    8000492c:	0711                	addi	a4,a4,4
    8000492e:	fef61be3          	bne	a2,a5,80004924 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004932:	0621                	addi	a2,a2,8
    80004934:	060a                	slli	a2,a2,0x2
    80004936:	0001d797          	auipc	a5,0x1d
    8000493a:	28278793          	addi	a5,a5,642 # 80021bb8 <log>
    8000493e:	963e                	add	a2,a2,a5
    80004940:	44dc                	lw	a5,12(s1)
    80004942:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004944:	8526                	mv	a0,s1
    80004946:	fffff097          	auipc	ra,0xfffff
    8000494a:	daa080e7          	jalr	-598(ra) # 800036f0 <bpin>
    log.lh.n++;
    8000494e:	0001d717          	auipc	a4,0x1d
    80004952:	26a70713          	addi	a4,a4,618 # 80021bb8 <log>
    80004956:	575c                	lw	a5,44(a4)
    80004958:	2785                	addiw	a5,a5,1
    8000495a:	d75c                	sw	a5,44(a4)
    8000495c:	a835                	j	80004998 <log_write+0xca>
    panic("too big a transaction");
    8000495e:	00004517          	auipc	a0,0x4
    80004962:	d4250513          	addi	a0,a0,-702 # 800086a0 <syscalls+0x200>
    80004966:	ffffc097          	auipc	ra,0xffffc
    8000496a:	bd8080e7          	jalr	-1064(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000496e:	00004517          	auipc	a0,0x4
    80004972:	d4a50513          	addi	a0,a0,-694 # 800086b8 <syscalls+0x218>
    80004976:	ffffc097          	auipc	ra,0xffffc
    8000497a:	bc8080e7          	jalr	-1080(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000497e:	00878713          	addi	a4,a5,8
    80004982:	00271693          	slli	a3,a4,0x2
    80004986:	0001d717          	auipc	a4,0x1d
    8000498a:	23270713          	addi	a4,a4,562 # 80021bb8 <log>
    8000498e:	9736                	add	a4,a4,a3
    80004990:	44d4                	lw	a3,12(s1)
    80004992:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004994:	faf608e3          	beq	a2,a5,80004944 <log_write+0x76>
  }
  release(&log.lock);
    80004998:	0001d517          	auipc	a0,0x1d
    8000499c:	22050513          	addi	a0,a0,544 # 80021bb8 <log>
    800049a0:	ffffc097          	auipc	ra,0xffffc
    800049a4:	2f8080e7          	jalr	760(ra) # 80000c98 <release>
}
    800049a8:	60e2                	ld	ra,24(sp)
    800049aa:	6442                	ld	s0,16(sp)
    800049ac:	64a2                	ld	s1,8(sp)
    800049ae:	6902                	ld	s2,0(sp)
    800049b0:	6105                	addi	sp,sp,32
    800049b2:	8082                	ret

00000000800049b4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800049b4:	1101                	addi	sp,sp,-32
    800049b6:	ec06                	sd	ra,24(sp)
    800049b8:	e822                	sd	s0,16(sp)
    800049ba:	e426                	sd	s1,8(sp)
    800049bc:	e04a                	sd	s2,0(sp)
    800049be:	1000                	addi	s0,sp,32
    800049c0:	84aa                	mv	s1,a0
    800049c2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049c4:	00004597          	auipc	a1,0x4
    800049c8:	d1458593          	addi	a1,a1,-748 # 800086d8 <syscalls+0x238>
    800049cc:	0521                	addi	a0,a0,8
    800049ce:	ffffc097          	auipc	ra,0xffffc
    800049d2:	186080e7          	jalr	390(ra) # 80000b54 <initlock>
  lk->name = name;
    800049d6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049da:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049de:	0204a423          	sw	zero,40(s1)
}
    800049e2:	60e2                	ld	ra,24(sp)
    800049e4:	6442                	ld	s0,16(sp)
    800049e6:	64a2                	ld	s1,8(sp)
    800049e8:	6902                	ld	s2,0(sp)
    800049ea:	6105                	addi	sp,sp,32
    800049ec:	8082                	ret

00000000800049ee <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049ee:	1101                	addi	sp,sp,-32
    800049f0:	ec06                	sd	ra,24(sp)
    800049f2:	e822                	sd	s0,16(sp)
    800049f4:	e426                	sd	s1,8(sp)
    800049f6:	e04a                	sd	s2,0(sp)
    800049f8:	1000                	addi	s0,sp,32
    800049fa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049fc:	00850913          	addi	s2,a0,8
    80004a00:	854a                	mv	a0,s2
    80004a02:	ffffc097          	auipc	ra,0xffffc
    80004a06:	1e2080e7          	jalr	482(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004a0a:	409c                	lw	a5,0(s1)
    80004a0c:	cb89                	beqz	a5,80004a1e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a0e:	85ca                	mv	a1,s2
    80004a10:	8526                	mv	a0,s1
    80004a12:	ffffe097          	auipc	ra,0xffffe
    80004a16:	b18080e7          	jalr	-1256(ra) # 8000252a <sleep>
  while (lk->locked) {
    80004a1a:	409c                	lw	a5,0(s1)
    80004a1c:	fbed                	bnez	a5,80004a0e <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a1e:	4785                	li	a5,1
    80004a20:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a22:	ffffd097          	auipc	ra,0xffffd
    80004a26:	320080e7          	jalr	800(ra) # 80001d42 <myproc>
    80004a2a:	591c                	lw	a5,48(a0)
    80004a2c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a2e:	854a                	mv	a0,s2
    80004a30:	ffffc097          	auipc	ra,0xffffc
    80004a34:	268080e7          	jalr	616(ra) # 80000c98 <release>
}
    80004a38:	60e2                	ld	ra,24(sp)
    80004a3a:	6442                	ld	s0,16(sp)
    80004a3c:	64a2                	ld	s1,8(sp)
    80004a3e:	6902                	ld	s2,0(sp)
    80004a40:	6105                	addi	sp,sp,32
    80004a42:	8082                	ret

0000000080004a44 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a44:	1101                	addi	sp,sp,-32
    80004a46:	ec06                	sd	ra,24(sp)
    80004a48:	e822                	sd	s0,16(sp)
    80004a4a:	e426                	sd	s1,8(sp)
    80004a4c:	e04a                	sd	s2,0(sp)
    80004a4e:	1000                	addi	s0,sp,32
    80004a50:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a52:	00850913          	addi	s2,a0,8
    80004a56:	854a                	mv	a0,s2
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	18c080e7          	jalr	396(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004a60:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a64:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a68:	8526                	mv	a0,s1
    80004a6a:	ffffe097          	auipc	ra,0xffffe
    80004a6e:	c66080e7          	jalr	-922(ra) # 800026d0 <wakeup>
  release(&lk->lk);
    80004a72:	854a                	mv	a0,s2
    80004a74:	ffffc097          	auipc	ra,0xffffc
    80004a78:	224080e7          	jalr	548(ra) # 80000c98 <release>
}
    80004a7c:	60e2                	ld	ra,24(sp)
    80004a7e:	6442                	ld	s0,16(sp)
    80004a80:	64a2                	ld	s1,8(sp)
    80004a82:	6902                	ld	s2,0(sp)
    80004a84:	6105                	addi	sp,sp,32
    80004a86:	8082                	ret

0000000080004a88 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a88:	7179                	addi	sp,sp,-48
    80004a8a:	f406                	sd	ra,40(sp)
    80004a8c:	f022                	sd	s0,32(sp)
    80004a8e:	ec26                	sd	s1,24(sp)
    80004a90:	e84a                	sd	s2,16(sp)
    80004a92:	e44e                	sd	s3,8(sp)
    80004a94:	1800                	addi	s0,sp,48
    80004a96:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a98:	00850913          	addi	s2,a0,8
    80004a9c:	854a                	mv	a0,s2
    80004a9e:	ffffc097          	auipc	ra,0xffffc
    80004aa2:	146080e7          	jalr	326(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004aa6:	409c                	lw	a5,0(s1)
    80004aa8:	ef99                	bnez	a5,80004ac6 <holdingsleep+0x3e>
    80004aaa:	4481                	li	s1,0
  release(&lk->lk);
    80004aac:	854a                	mv	a0,s2
    80004aae:	ffffc097          	auipc	ra,0xffffc
    80004ab2:	1ea080e7          	jalr	490(ra) # 80000c98 <release>
  return r;
}
    80004ab6:	8526                	mv	a0,s1
    80004ab8:	70a2                	ld	ra,40(sp)
    80004aba:	7402                	ld	s0,32(sp)
    80004abc:	64e2                	ld	s1,24(sp)
    80004abe:	6942                	ld	s2,16(sp)
    80004ac0:	69a2                	ld	s3,8(sp)
    80004ac2:	6145                	addi	sp,sp,48
    80004ac4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ac6:	0284a983          	lw	s3,40(s1)
    80004aca:	ffffd097          	auipc	ra,0xffffd
    80004ace:	278080e7          	jalr	632(ra) # 80001d42 <myproc>
    80004ad2:	5904                	lw	s1,48(a0)
    80004ad4:	413484b3          	sub	s1,s1,s3
    80004ad8:	0014b493          	seqz	s1,s1
    80004adc:	bfc1                	j	80004aac <holdingsleep+0x24>

0000000080004ade <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ade:	1141                	addi	sp,sp,-16
    80004ae0:	e406                	sd	ra,8(sp)
    80004ae2:	e022                	sd	s0,0(sp)
    80004ae4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004ae6:	00004597          	auipc	a1,0x4
    80004aea:	c0258593          	addi	a1,a1,-1022 # 800086e8 <syscalls+0x248>
    80004aee:	0001d517          	auipc	a0,0x1d
    80004af2:	21250513          	addi	a0,a0,530 # 80021d00 <ftable>
    80004af6:	ffffc097          	auipc	ra,0xffffc
    80004afa:	05e080e7          	jalr	94(ra) # 80000b54 <initlock>
}
    80004afe:	60a2                	ld	ra,8(sp)
    80004b00:	6402                	ld	s0,0(sp)
    80004b02:	0141                	addi	sp,sp,16
    80004b04:	8082                	ret

0000000080004b06 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b06:	1101                	addi	sp,sp,-32
    80004b08:	ec06                	sd	ra,24(sp)
    80004b0a:	e822                	sd	s0,16(sp)
    80004b0c:	e426                	sd	s1,8(sp)
    80004b0e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b10:	0001d517          	auipc	a0,0x1d
    80004b14:	1f050513          	addi	a0,a0,496 # 80021d00 <ftable>
    80004b18:	ffffc097          	auipc	ra,0xffffc
    80004b1c:	0cc080e7          	jalr	204(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b20:	0001d497          	auipc	s1,0x1d
    80004b24:	1f848493          	addi	s1,s1,504 # 80021d18 <ftable+0x18>
    80004b28:	0001e717          	auipc	a4,0x1e
    80004b2c:	19070713          	addi	a4,a4,400 # 80022cb8 <ftable+0xfb8>
    if(f->ref == 0){
    80004b30:	40dc                	lw	a5,4(s1)
    80004b32:	cf99                	beqz	a5,80004b50 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b34:	02848493          	addi	s1,s1,40
    80004b38:	fee49ce3          	bne	s1,a4,80004b30 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b3c:	0001d517          	auipc	a0,0x1d
    80004b40:	1c450513          	addi	a0,a0,452 # 80021d00 <ftable>
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	154080e7          	jalr	340(ra) # 80000c98 <release>
  return 0;
    80004b4c:	4481                	li	s1,0
    80004b4e:	a819                	j	80004b64 <filealloc+0x5e>
      f->ref = 1;
    80004b50:	4785                	li	a5,1
    80004b52:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b54:	0001d517          	auipc	a0,0x1d
    80004b58:	1ac50513          	addi	a0,a0,428 # 80021d00 <ftable>
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	13c080e7          	jalr	316(ra) # 80000c98 <release>
}
    80004b64:	8526                	mv	a0,s1
    80004b66:	60e2                	ld	ra,24(sp)
    80004b68:	6442                	ld	s0,16(sp)
    80004b6a:	64a2                	ld	s1,8(sp)
    80004b6c:	6105                	addi	sp,sp,32
    80004b6e:	8082                	ret

0000000080004b70 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b70:	1101                	addi	sp,sp,-32
    80004b72:	ec06                	sd	ra,24(sp)
    80004b74:	e822                	sd	s0,16(sp)
    80004b76:	e426                	sd	s1,8(sp)
    80004b78:	1000                	addi	s0,sp,32
    80004b7a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b7c:	0001d517          	auipc	a0,0x1d
    80004b80:	18450513          	addi	a0,a0,388 # 80021d00 <ftable>
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	060080e7          	jalr	96(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b8c:	40dc                	lw	a5,4(s1)
    80004b8e:	02f05263          	blez	a5,80004bb2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b92:	2785                	addiw	a5,a5,1
    80004b94:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b96:	0001d517          	auipc	a0,0x1d
    80004b9a:	16a50513          	addi	a0,a0,362 # 80021d00 <ftable>
    80004b9e:	ffffc097          	auipc	ra,0xffffc
    80004ba2:	0fa080e7          	jalr	250(ra) # 80000c98 <release>
  return f;
}
    80004ba6:	8526                	mv	a0,s1
    80004ba8:	60e2                	ld	ra,24(sp)
    80004baa:	6442                	ld	s0,16(sp)
    80004bac:	64a2                	ld	s1,8(sp)
    80004bae:	6105                	addi	sp,sp,32
    80004bb0:	8082                	ret
    panic("filedup");
    80004bb2:	00004517          	auipc	a0,0x4
    80004bb6:	b3e50513          	addi	a0,a0,-1218 # 800086f0 <syscalls+0x250>
    80004bba:	ffffc097          	auipc	ra,0xffffc
    80004bbe:	984080e7          	jalr	-1660(ra) # 8000053e <panic>

0000000080004bc2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004bc2:	7139                	addi	sp,sp,-64
    80004bc4:	fc06                	sd	ra,56(sp)
    80004bc6:	f822                	sd	s0,48(sp)
    80004bc8:	f426                	sd	s1,40(sp)
    80004bca:	f04a                	sd	s2,32(sp)
    80004bcc:	ec4e                	sd	s3,24(sp)
    80004bce:	e852                	sd	s4,16(sp)
    80004bd0:	e456                	sd	s5,8(sp)
    80004bd2:	0080                	addi	s0,sp,64
    80004bd4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004bd6:	0001d517          	auipc	a0,0x1d
    80004bda:	12a50513          	addi	a0,a0,298 # 80021d00 <ftable>
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	006080e7          	jalr	6(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004be6:	40dc                	lw	a5,4(s1)
    80004be8:	06f05163          	blez	a5,80004c4a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004bec:	37fd                	addiw	a5,a5,-1
    80004bee:	0007871b          	sext.w	a4,a5
    80004bf2:	c0dc                	sw	a5,4(s1)
    80004bf4:	06e04363          	bgtz	a4,80004c5a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004bf8:	0004a903          	lw	s2,0(s1)
    80004bfc:	0094ca83          	lbu	s5,9(s1)
    80004c00:	0104ba03          	ld	s4,16(s1)
    80004c04:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c08:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c0c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c10:	0001d517          	auipc	a0,0x1d
    80004c14:	0f050513          	addi	a0,a0,240 # 80021d00 <ftable>
    80004c18:	ffffc097          	auipc	ra,0xffffc
    80004c1c:	080080e7          	jalr	128(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004c20:	4785                	li	a5,1
    80004c22:	04f90d63          	beq	s2,a5,80004c7c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c26:	3979                	addiw	s2,s2,-2
    80004c28:	4785                	li	a5,1
    80004c2a:	0527e063          	bltu	a5,s2,80004c6a <fileclose+0xa8>
    begin_op();
    80004c2e:	00000097          	auipc	ra,0x0
    80004c32:	ac8080e7          	jalr	-1336(ra) # 800046f6 <begin_op>
    iput(ff.ip);
    80004c36:	854e                	mv	a0,s3
    80004c38:	fffff097          	auipc	ra,0xfffff
    80004c3c:	2a6080e7          	jalr	678(ra) # 80003ede <iput>
    end_op();
    80004c40:	00000097          	auipc	ra,0x0
    80004c44:	b36080e7          	jalr	-1226(ra) # 80004776 <end_op>
    80004c48:	a00d                	j	80004c6a <fileclose+0xa8>
    panic("fileclose");
    80004c4a:	00004517          	auipc	a0,0x4
    80004c4e:	aae50513          	addi	a0,a0,-1362 # 800086f8 <syscalls+0x258>
    80004c52:	ffffc097          	auipc	ra,0xffffc
    80004c56:	8ec080e7          	jalr	-1812(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004c5a:	0001d517          	auipc	a0,0x1d
    80004c5e:	0a650513          	addi	a0,a0,166 # 80021d00 <ftable>
    80004c62:	ffffc097          	auipc	ra,0xffffc
    80004c66:	036080e7          	jalr	54(ra) # 80000c98 <release>
  }
}
    80004c6a:	70e2                	ld	ra,56(sp)
    80004c6c:	7442                	ld	s0,48(sp)
    80004c6e:	74a2                	ld	s1,40(sp)
    80004c70:	7902                	ld	s2,32(sp)
    80004c72:	69e2                	ld	s3,24(sp)
    80004c74:	6a42                	ld	s4,16(sp)
    80004c76:	6aa2                	ld	s5,8(sp)
    80004c78:	6121                	addi	sp,sp,64
    80004c7a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c7c:	85d6                	mv	a1,s5
    80004c7e:	8552                	mv	a0,s4
    80004c80:	00000097          	auipc	ra,0x0
    80004c84:	34c080e7          	jalr	844(ra) # 80004fcc <pipeclose>
    80004c88:	b7cd                	j	80004c6a <fileclose+0xa8>

0000000080004c8a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c8a:	715d                	addi	sp,sp,-80
    80004c8c:	e486                	sd	ra,72(sp)
    80004c8e:	e0a2                	sd	s0,64(sp)
    80004c90:	fc26                	sd	s1,56(sp)
    80004c92:	f84a                	sd	s2,48(sp)
    80004c94:	f44e                	sd	s3,40(sp)
    80004c96:	0880                	addi	s0,sp,80
    80004c98:	84aa                	mv	s1,a0
    80004c9a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c9c:	ffffd097          	auipc	ra,0xffffd
    80004ca0:	0a6080e7          	jalr	166(ra) # 80001d42 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004ca4:	409c                	lw	a5,0(s1)
    80004ca6:	37f9                	addiw	a5,a5,-2
    80004ca8:	4705                	li	a4,1
    80004caa:	04f76763          	bltu	a4,a5,80004cf8 <filestat+0x6e>
    80004cae:	892a                	mv	s2,a0
    ilock(f->ip);
    80004cb0:	6c88                	ld	a0,24(s1)
    80004cb2:	fffff097          	auipc	ra,0xfffff
    80004cb6:	072080e7          	jalr	114(ra) # 80003d24 <ilock>
    stati(f->ip, &st);
    80004cba:	fb840593          	addi	a1,s0,-72
    80004cbe:	6c88                	ld	a0,24(s1)
    80004cc0:	fffff097          	auipc	ra,0xfffff
    80004cc4:	2ee080e7          	jalr	750(ra) # 80003fae <stati>
    iunlock(f->ip);
    80004cc8:	6c88                	ld	a0,24(s1)
    80004cca:	fffff097          	auipc	ra,0xfffff
    80004cce:	11c080e7          	jalr	284(ra) # 80003de6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cd2:	46e1                	li	a3,24
    80004cd4:	fb840613          	addi	a2,s0,-72
    80004cd8:	85ce                	mv	a1,s3
    80004cda:	07093503          	ld	a0,112(s2)
    80004cde:	ffffd097          	auipc	ra,0xffffd
    80004ce2:	9a6080e7          	jalr	-1626(ra) # 80001684 <copyout>
    80004ce6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004cea:	60a6                	ld	ra,72(sp)
    80004cec:	6406                	ld	s0,64(sp)
    80004cee:	74e2                	ld	s1,56(sp)
    80004cf0:	7942                	ld	s2,48(sp)
    80004cf2:	79a2                	ld	s3,40(sp)
    80004cf4:	6161                	addi	sp,sp,80
    80004cf6:	8082                	ret
  return -1;
    80004cf8:	557d                	li	a0,-1
    80004cfa:	bfc5                	j	80004cea <filestat+0x60>

0000000080004cfc <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004cfc:	7179                	addi	sp,sp,-48
    80004cfe:	f406                	sd	ra,40(sp)
    80004d00:	f022                	sd	s0,32(sp)
    80004d02:	ec26                	sd	s1,24(sp)
    80004d04:	e84a                	sd	s2,16(sp)
    80004d06:	e44e                	sd	s3,8(sp)
    80004d08:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d0a:	00854783          	lbu	a5,8(a0)
    80004d0e:	c3d5                	beqz	a5,80004db2 <fileread+0xb6>
    80004d10:	84aa                	mv	s1,a0
    80004d12:	89ae                	mv	s3,a1
    80004d14:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d16:	411c                	lw	a5,0(a0)
    80004d18:	4705                	li	a4,1
    80004d1a:	04e78963          	beq	a5,a4,80004d6c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d1e:	470d                	li	a4,3
    80004d20:	04e78d63          	beq	a5,a4,80004d7a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d24:	4709                	li	a4,2
    80004d26:	06e79e63          	bne	a5,a4,80004da2 <fileread+0xa6>
    ilock(f->ip);
    80004d2a:	6d08                	ld	a0,24(a0)
    80004d2c:	fffff097          	auipc	ra,0xfffff
    80004d30:	ff8080e7          	jalr	-8(ra) # 80003d24 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d34:	874a                	mv	a4,s2
    80004d36:	5094                	lw	a3,32(s1)
    80004d38:	864e                	mv	a2,s3
    80004d3a:	4585                	li	a1,1
    80004d3c:	6c88                	ld	a0,24(s1)
    80004d3e:	fffff097          	auipc	ra,0xfffff
    80004d42:	29a080e7          	jalr	666(ra) # 80003fd8 <readi>
    80004d46:	892a                	mv	s2,a0
    80004d48:	00a05563          	blez	a0,80004d52 <fileread+0x56>
      f->off += r;
    80004d4c:	509c                	lw	a5,32(s1)
    80004d4e:	9fa9                	addw	a5,a5,a0
    80004d50:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d52:	6c88                	ld	a0,24(s1)
    80004d54:	fffff097          	auipc	ra,0xfffff
    80004d58:	092080e7          	jalr	146(ra) # 80003de6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d5c:	854a                	mv	a0,s2
    80004d5e:	70a2                	ld	ra,40(sp)
    80004d60:	7402                	ld	s0,32(sp)
    80004d62:	64e2                	ld	s1,24(sp)
    80004d64:	6942                	ld	s2,16(sp)
    80004d66:	69a2                	ld	s3,8(sp)
    80004d68:	6145                	addi	sp,sp,48
    80004d6a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d6c:	6908                	ld	a0,16(a0)
    80004d6e:	00000097          	auipc	ra,0x0
    80004d72:	3c8080e7          	jalr	968(ra) # 80005136 <piperead>
    80004d76:	892a                	mv	s2,a0
    80004d78:	b7d5                	j	80004d5c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d7a:	02451783          	lh	a5,36(a0)
    80004d7e:	03079693          	slli	a3,a5,0x30
    80004d82:	92c1                	srli	a3,a3,0x30
    80004d84:	4725                	li	a4,9
    80004d86:	02d76863          	bltu	a4,a3,80004db6 <fileread+0xba>
    80004d8a:	0792                	slli	a5,a5,0x4
    80004d8c:	0001d717          	auipc	a4,0x1d
    80004d90:	ed470713          	addi	a4,a4,-300 # 80021c60 <devsw>
    80004d94:	97ba                	add	a5,a5,a4
    80004d96:	639c                	ld	a5,0(a5)
    80004d98:	c38d                	beqz	a5,80004dba <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d9a:	4505                	li	a0,1
    80004d9c:	9782                	jalr	a5
    80004d9e:	892a                	mv	s2,a0
    80004da0:	bf75                	j	80004d5c <fileread+0x60>
    panic("fileread");
    80004da2:	00004517          	auipc	a0,0x4
    80004da6:	96650513          	addi	a0,a0,-1690 # 80008708 <syscalls+0x268>
    80004daa:	ffffb097          	auipc	ra,0xffffb
    80004dae:	794080e7          	jalr	1940(ra) # 8000053e <panic>
    return -1;
    80004db2:	597d                	li	s2,-1
    80004db4:	b765                	j	80004d5c <fileread+0x60>
      return -1;
    80004db6:	597d                	li	s2,-1
    80004db8:	b755                	j	80004d5c <fileread+0x60>
    80004dba:	597d                	li	s2,-1
    80004dbc:	b745                	j	80004d5c <fileread+0x60>

0000000080004dbe <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004dbe:	715d                	addi	sp,sp,-80
    80004dc0:	e486                	sd	ra,72(sp)
    80004dc2:	e0a2                	sd	s0,64(sp)
    80004dc4:	fc26                	sd	s1,56(sp)
    80004dc6:	f84a                	sd	s2,48(sp)
    80004dc8:	f44e                	sd	s3,40(sp)
    80004dca:	f052                	sd	s4,32(sp)
    80004dcc:	ec56                	sd	s5,24(sp)
    80004dce:	e85a                	sd	s6,16(sp)
    80004dd0:	e45e                	sd	s7,8(sp)
    80004dd2:	e062                	sd	s8,0(sp)
    80004dd4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004dd6:	00954783          	lbu	a5,9(a0)
    80004dda:	10078663          	beqz	a5,80004ee6 <filewrite+0x128>
    80004dde:	892a                	mv	s2,a0
    80004de0:	8aae                	mv	s5,a1
    80004de2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004de4:	411c                	lw	a5,0(a0)
    80004de6:	4705                	li	a4,1
    80004de8:	02e78263          	beq	a5,a4,80004e0c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004dec:	470d                	li	a4,3
    80004dee:	02e78663          	beq	a5,a4,80004e1a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004df2:	4709                	li	a4,2
    80004df4:	0ee79163          	bne	a5,a4,80004ed6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004df8:	0ac05d63          	blez	a2,80004eb2 <filewrite+0xf4>
    int i = 0;
    80004dfc:	4981                	li	s3,0
    80004dfe:	6b05                	lui	s6,0x1
    80004e00:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004e04:	6b85                	lui	s7,0x1
    80004e06:	c00b8b9b          	addiw	s7,s7,-1024
    80004e0a:	a861                	j	80004ea2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004e0c:	6908                	ld	a0,16(a0)
    80004e0e:	00000097          	auipc	ra,0x0
    80004e12:	22e080e7          	jalr	558(ra) # 8000503c <pipewrite>
    80004e16:	8a2a                	mv	s4,a0
    80004e18:	a045                	j	80004eb8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e1a:	02451783          	lh	a5,36(a0)
    80004e1e:	03079693          	slli	a3,a5,0x30
    80004e22:	92c1                	srli	a3,a3,0x30
    80004e24:	4725                	li	a4,9
    80004e26:	0cd76263          	bltu	a4,a3,80004eea <filewrite+0x12c>
    80004e2a:	0792                	slli	a5,a5,0x4
    80004e2c:	0001d717          	auipc	a4,0x1d
    80004e30:	e3470713          	addi	a4,a4,-460 # 80021c60 <devsw>
    80004e34:	97ba                	add	a5,a5,a4
    80004e36:	679c                	ld	a5,8(a5)
    80004e38:	cbdd                	beqz	a5,80004eee <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e3a:	4505                	li	a0,1
    80004e3c:	9782                	jalr	a5
    80004e3e:	8a2a                	mv	s4,a0
    80004e40:	a8a5                	j	80004eb8 <filewrite+0xfa>
    80004e42:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e46:	00000097          	auipc	ra,0x0
    80004e4a:	8b0080e7          	jalr	-1872(ra) # 800046f6 <begin_op>
      ilock(f->ip);
    80004e4e:	01893503          	ld	a0,24(s2)
    80004e52:	fffff097          	auipc	ra,0xfffff
    80004e56:	ed2080e7          	jalr	-302(ra) # 80003d24 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e5a:	8762                	mv	a4,s8
    80004e5c:	02092683          	lw	a3,32(s2)
    80004e60:	01598633          	add	a2,s3,s5
    80004e64:	4585                	li	a1,1
    80004e66:	01893503          	ld	a0,24(s2)
    80004e6a:	fffff097          	auipc	ra,0xfffff
    80004e6e:	266080e7          	jalr	614(ra) # 800040d0 <writei>
    80004e72:	84aa                	mv	s1,a0
    80004e74:	00a05763          	blez	a0,80004e82 <filewrite+0xc4>
        f->off += r;
    80004e78:	02092783          	lw	a5,32(s2)
    80004e7c:	9fa9                	addw	a5,a5,a0
    80004e7e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e82:	01893503          	ld	a0,24(s2)
    80004e86:	fffff097          	auipc	ra,0xfffff
    80004e8a:	f60080e7          	jalr	-160(ra) # 80003de6 <iunlock>
      end_op();
    80004e8e:	00000097          	auipc	ra,0x0
    80004e92:	8e8080e7          	jalr	-1816(ra) # 80004776 <end_op>

      if(r != n1){
    80004e96:	009c1f63          	bne	s8,s1,80004eb4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e9a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e9e:	0149db63          	bge	s3,s4,80004eb4 <filewrite+0xf6>
      int n1 = n - i;
    80004ea2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004ea6:	84be                	mv	s1,a5
    80004ea8:	2781                	sext.w	a5,a5
    80004eaa:	f8fb5ce3          	bge	s6,a5,80004e42 <filewrite+0x84>
    80004eae:	84de                	mv	s1,s7
    80004eb0:	bf49                	j	80004e42 <filewrite+0x84>
    int i = 0;
    80004eb2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004eb4:	013a1f63          	bne	s4,s3,80004ed2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004eb8:	8552                	mv	a0,s4
    80004eba:	60a6                	ld	ra,72(sp)
    80004ebc:	6406                	ld	s0,64(sp)
    80004ebe:	74e2                	ld	s1,56(sp)
    80004ec0:	7942                	ld	s2,48(sp)
    80004ec2:	79a2                	ld	s3,40(sp)
    80004ec4:	7a02                	ld	s4,32(sp)
    80004ec6:	6ae2                	ld	s5,24(sp)
    80004ec8:	6b42                	ld	s6,16(sp)
    80004eca:	6ba2                	ld	s7,8(sp)
    80004ecc:	6c02                	ld	s8,0(sp)
    80004ece:	6161                	addi	sp,sp,80
    80004ed0:	8082                	ret
    ret = (i == n ? n : -1);
    80004ed2:	5a7d                	li	s4,-1
    80004ed4:	b7d5                	j	80004eb8 <filewrite+0xfa>
    panic("filewrite");
    80004ed6:	00004517          	auipc	a0,0x4
    80004eda:	84250513          	addi	a0,a0,-1982 # 80008718 <syscalls+0x278>
    80004ede:	ffffb097          	auipc	ra,0xffffb
    80004ee2:	660080e7          	jalr	1632(ra) # 8000053e <panic>
    return -1;
    80004ee6:	5a7d                	li	s4,-1
    80004ee8:	bfc1                	j	80004eb8 <filewrite+0xfa>
      return -1;
    80004eea:	5a7d                	li	s4,-1
    80004eec:	b7f1                	j	80004eb8 <filewrite+0xfa>
    80004eee:	5a7d                	li	s4,-1
    80004ef0:	b7e1                	j	80004eb8 <filewrite+0xfa>

0000000080004ef2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ef2:	7179                	addi	sp,sp,-48
    80004ef4:	f406                	sd	ra,40(sp)
    80004ef6:	f022                	sd	s0,32(sp)
    80004ef8:	ec26                	sd	s1,24(sp)
    80004efa:	e84a                	sd	s2,16(sp)
    80004efc:	e44e                	sd	s3,8(sp)
    80004efe:	e052                	sd	s4,0(sp)
    80004f00:	1800                	addi	s0,sp,48
    80004f02:	84aa                	mv	s1,a0
    80004f04:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f06:	0005b023          	sd	zero,0(a1)
    80004f0a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f0e:	00000097          	auipc	ra,0x0
    80004f12:	bf8080e7          	jalr	-1032(ra) # 80004b06 <filealloc>
    80004f16:	e088                	sd	a0,0(s1)
    80004f18:	c551                	beqz	a0,80004fa4 <pipealloc+0xb2>
    80004f1a:	00000097          	auipc	ra,0x0
    80004f1e:	bec080e7          	jalr	-1044(ra) # 80004b06 <filealloc>
    80004f22:	00aa3023          	sd	a0,0(s4)
    80004f26:	c92d                	beqz	a0,80004f98 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f28:	ffffc097          	auipc	ra,0xffffc
    80004f2c:	bcc080e7          	jalr	-1076(ra) # 80000af4 <kalloc>
    80004f30:	892a                	mv	s2,a0
    80004f32:	c125                	beqz	a0,80004f92 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f34:	4985                	li	s3,1
    80004f36:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f3a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f3e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f42:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f46:	00003597          	auipc	a1,0x3
    80004f4a:	7e258593          	addi	a1,a1,2018 # 80008728 <syscalls+0x288>
    80004f4e:	ffffc097          	auipc	ra,0xffffc
    80004f52:	c06080e7          	jalr	-1018(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004f56:	609c                	ld	a5,0(s1)
    80004f58:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f5c:	609c                	ld	a5,0(s1)
    80004f5e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f62:	609c                	ld	a5,0(s1)
    80004f64:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f68:	609c                	ld	a5,0(s1)
    80004f6a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f6e:	000a3783          	ld	a5,0(s4)
    80004f72:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f76:	000a3783          	ld	a5,0(s4)
    80004f7a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f7e:	000a3783          	ld	a5,0(s4)
    80004f82:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f86:	000a3783          	ld	a5,0(s4)
    80004f8a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f8e:	4501                	li	a0,0
    80004f90:	a025                	j	80004fb8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f92:	6088                	ld	a0,0(s1)
    80004f94:	e501                	bnez	a0,80004f9c <pipealloc+0xaa>
    80004f96:	a039                	j	80004fa4 <pipealloc+0xb2>
    80004f98:	6088                	ld	a0,0(s1)
    80004f9a:	c51d                	beqz	a0,80004fc8 <pipealloc+0xd6>
    fileclose(*f0);
    80004f9c:	00000097          	auipc	ra,0x0
    80004fa0:	c26080e7          	jalr	-986(ra) # 80004bc2 <fileclose>
  if(*f1)
    80004fa4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004fa8:	557d                	li	a0,-1
  if(*f1)
    80004faa:	c799                	beqz	a5,80004fb8 <pipealloc+0xc6>
    fileclose(*f1);
    80004fac:	853e                	mv	a0,a5
    80004fae:	00000097          	auipc	ra,0x0
    80004fb2:	c14080e7          	jalr	-1004(ra) # 80004bc2 <fileclose>
  return -1;
    80004fb6:	557d                	li	a0,-1
}
    80004fb8:	70a2                	ld	ra,40(sp)
    80004fba:	7402                	ld	s0,32(sp)
    80004fbc:	64e2                	ld	s1,24(sp)
    80004fbe:	6942                	ld	s2,16(sp)
    80004fc0:	69a2                	ld	s3,8(sp)
    80004fc2:	6a02                	ld	s4,0(sp)
    80004fc4:	6145                	addi	sp,sp,48
    80004fc6:	8082                	ret
  return -1;
    80004fc8:	557d                	li	a0,-1
    80004fca:	b7fd                	j	80004fb8 <pipealloc+0xc6>

0000000080004fcc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004fcc:	1101                	addi	sp,sp,-32
    80004fce:	ec06                	sd	ra,24(sp)
    80004fd0:	e822                	sd	s0,16(sp)
    80004fd2:	e426                	sd	s1,8(sp)
    80004fd4:	e04a                	sd	s2,0(sp)
    80004fd6:	1000                	addi	s0,sp,32
    80004fd8:	84aa                	mv	s1,a0
    80004fda:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004fdc:	ffffc097          	auipc	ra,0xffffc
    80004fe0:	c08080e7          	jalr	-1016(ra) # 80000be4 <acquire>
  if(writable){
    80004fe4:	02090d63          	beqz	s2,8000501e <pipeclose+0x52>
    pi->writeopen = 0;
    80004fe8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004fec:	21848513          	addi	a0,s1,536
    80004ff0:	ffffd097          	auipc	ra,0xffffd
    80004ff4:	6e0080e7          	jalr	1760(ra) # 800026d0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ff8:	2204b783          	ld	a5,544(s1)
    80004ffc:	eb95                	bnez	a5,80005030 <pipeclose+0x64>
    release(&pi->lock);
    80004ffe:	8526                	mv	a0,s1
    80005000:	ffffc097          	auipc	ra,0xffffc
    80005004:	c98080e7          	jalr	-872(ra) # 80000c98 <release>
    kfree((char*)pi);
    80005008:	8526                	mv	a0,s1
    8000500a:	ffffc097          	auipc	ra,0xffffc
    8000500e:	9ee080e7          	jalr	-1554(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80005012:	60e2                	ld	ra,24(sp)
    80005014:	6442                	ld	s0,16(sp)
    80005016:	64a2                	ld	s1,8(sp)
    80005018:	6902                	ld	s2,0(sp)
    8000501a:	6105                	addi	sp,sp,32
    8000501c:	8082                	ret
    pi->readopen = 0;
    8000501e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005022:	21c48513          	addi	a0,s1,540
    80005026:	ffffd097          	auipc	ra,0xffffd
    8000502a:	6aa080e7          	jalr	1706(ra) # 800026d0 <wakeup>
    8000502e:	b7e9                	j	80004ff8 <pipeclose+0x2c>
    release(&pi->lock);
    80005030:	8526                	mv	a0,s1
    80005032:	ffffc097          	auipc	ra,0xffffc
    80005036:	c66080e7          	jalr	-922(ra) # 80000c98 <release>
}
    8000503a:	bfe1                	j	80005012 <pipeclose+0x46>

000000008000503c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000503c:	7159                	addi	sp,sp,-112
    8000503e:	f486                	sd	ra,104(sp)
    80005040:	f0a2                	sd	s0,96(sp)
    80005042:	eca6                	sd	s1,88(sp)
    80005044:	e8ca                	sd	s2,80(sp)
    80005046:	e4ce                	sd	s3,72(sp)
    80005048:	e0d2                	sd	s4,64(sp)
    8000504a:	fc56                	sd	s5,56(sp)
    8000504c:	f85a                	sd	s6,48(sp)
    8000504e:	f45e                	sd	s7,40(sp)
    80005050:	f062                	sd	s8,32(sp)
    80005052:	ec66                	sd	s9,24(sp)
    80005054:	1880                	addi	s0,sp,112
    80005056:	84aa                	mv	s1,a0
    80005058:	8aae                	mv	s5,a1
    8000505a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000505c:	ffffd097          	auipc	ra,0xffffd
    80005060:	ce6080e7          	jalr	-794(ra) # 80001d42 <myproc>
    80005064:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005066:	8526                	mv	a0,s1
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	b7c080e7          	jalr	-1156(ra) # 80000be4 <acquire>
  while(i < n){
    80005070:	0d405163          	blez	s4,80005132 <pipewrite+0xf6>
    80005074:	8ba6                	mv	s7,s1
  int i = 0;
    80005076:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005078:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000507a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000507e:	21c48c13          	addi	s8,s1,540
    80005082:	a08d                	j	800050e4 <pipewrite+0xa8>
      release(&pi->lock);
    80005084:	8526                	mv	a0,s1
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	c12080e7          	jalr	-1006(ra) # 80000c98 <release>
      return -1;
    8000508e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005090:	854a                	mv	a0,s2
    80005092:	70a6                	ld	ra,104(sp)
    80005094:	7406                	ld	s0,96(sp)
    80005096:	64e6                	ld	s1,88(sp)
    80005098:	6946                	ld	s2,80(sp)
    8000509a:	69a6                	ld	s3,72(sp)
    8000509c:	6a06                	ld	s4,64(sp)
    8000509e:	7ae2                	ld	s5,56(sp)
    800050a0:	7b42                	ld	s6,48(sp)
    800050a2:	7ba2                	ld	s7,40(sp)
    800050a4:	7c02                	ld	s8,32(sp)
    800050a6:	6ce2                	ld	s9,24(sp)
    800050a8:	6165                	addi	sp,sp,112
    800050aa:	8082                	ret
      wakeup(&pi->nread);
    800050ac:	8566                	mv	a0,s9
    800050ae:	ffffd097          	auipc	ra,0xffffd
    800050b2:	622080e7          	jalr	1570(ra) # 800026d0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800050b6:	85de                	mv	a1,s7
    800050b8:	8562                	mv	a0,s8
    800050ba:	ffffd097          	auipc	ra,0xffffd
    800050be:	470080e7          	jalr	1136(ra) # 8000252a <sleep>
    800050c2:	a839                	j	800050e0 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050c4:	21c4a783          	lw	a5,540(s1)
    800050c8:	0017871b          	addiw	a4,a5,1
    800050cc:	20e4ae23          	sw	a4,540(s1)
    800050d0:	1ff7f793          	andi	a5,a5,511
    800050d4:	97a6                	add	a5,a5,s1
    800050d6:	f9f44703          	lbu	a4,-97(s0)
    800050da:	00e78c23          	sb	a4,24(a5)
      i++;
    800050de:	2905                	addiw	s2,s2,1
  while(i < n){
    800050e0:	03495d63          	bge	s2,s4,8000511a <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800050e4:	2204a783          	lw	a5,544(s1)
    800050e8:	dfd1                	beqz	a5,80005084 <pipewrite+0x48>
    800050ea:	0289a783          	lw	a5,40(s3)
    800050ee:	fbd9                	bnez	a5,80005084 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800050f0:	2184a783          	lw	a5,536(s1)
    800050f4:	21c4a703          	lw	a4,540(s1)
    800050f8:	2007879b          	addiw	a5,a5,512
    800050fc:	faf708e3          	beq	a4,a5,800050ac <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005100:	4685                	li	a3,1
    80005102:	01590633          	add	a2,s2,s5
    80005106:	f9f40593          	addi	a1,s0,-97
    8000510a:	0709b503          	ld	a0,112(s3)
    8000510e:	ffffc097          	auipc	ra,0xffffc
    80005112:	602080e7          	jalr	1538(ra) # 80001710 <copyin>
    80005116:	fb6517e3          	bne	a0,s6,800050c4 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000511a:	21848513          	addi	a0,s1,536
    8000511e:	ffffd097          	auipc	ra,0xffffd
    80005122:	5b2080e7          	jalr	1458(ra) # 800026d0 <wakeup>
  release(&pi->lock);
    80005126:	8526                	mv	a0,s1
    80005128:	ffffc097          	auipc	ra,0xffffc
    8000512c:	b70080e7          	jalr	-1168(ra) # 80000c98 <release>
  return i;
    80005130:	b785                	j	80005090 <pipewrite+0x54>
  int i = 0;
    80005132:	4901                	li	s2,0
    80005134:	b7dd                	j	8000511a <pipewrite+0xde>

0000000080005136 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005136:	715d                	addi	sp,sp,-80
    80005138:	e486                	sd	ra,72(sp)
    8000513a:	e0a2                	sd	s0,64(sp)
    8000513c:	fc26                	sd	s1,56(sp)
    8000513e:	f84a                	sd	s2,48(sp)
    80005140:	f44e                	sd	s3,40(sp)
    80005142:	f052                	sd	s4,32(sp)
    80005144:	ec56                	sd	s5,24(sp)
    80005146:	e85a                	sd	s6,16(sp)
    80005148:	0880                	addi	s0,sp,80
    8000514a:	84aa                	mv	s1,a0
    8000514c:	892e                	mv	s2,a1
    8000514e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005150:	ffffd097          	auipc	ra,0xffffd
    80005154:	bf2080e7          	jalr	-1038(ra) # 80001d42 <myproc>
    80005158:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000515a:	8b26                	mv	s6,s1
    8000515c:	8526                	mv	a0,s1
    8000515e:	ffffc097          	auipc	ra,0xffffc
    80005162:	a86080e7          	jalr	-1402(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005166:	2184a703          	lw	a4,536(s1)
    8000516a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000516e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005172:	02f71463          	bne	a4,a5,8000519a <piperead+0x64>
    80005176:	2244a783          	lw	a5,548(s1)
    8000517a:	c385                	beqz	a5,8000519a <piperead+0x64>
    if(pr->killed){
    8000517c:	028a2783          	lw	a5,40(s4)
    80005180:	ebc1                	bnez	a5,80005210 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005182:	85da                	mv	a1,s6
    80005184:	854e                	mv	a0,s3
    80005186:	ffffd097          	auipc	ra,0xffffd
    8000518a:	3a4080e7          	jalr	932(ra) # 8000252a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000518e:	2184a703          	lw	a4,536(s1)
    80005192:	21c4a783          	lw	a5,540(s1)
    80005196:	fef700e3          	beq	a4,a5,80005176 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000519a:	09505263          	blez	s5,8000521e <piperead+0xe8>
    8000519e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051a0:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800051a2:	2184a783          	lw	a5,536(s1)
    800051a6:	21c4a703          	lw	a4,540(s1)
    800051aa:	02f70d63          	beq	a4,a5,800051e4 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800051ae:	0017871b          	addiw	a4,a5,1
    800051b2:	20e4ac23          	sw	a4,536(s1)
    800051b6:	1ff7f793          	andi	a5,a5,511
    800051ba:	97a6                	add	a5,a5,s1
    800051bc:	0187c783          	lbu	a5,24(a5)
    800051c0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051c4:	4685                	li	a3,1
    800051c6:	fbf40613          	addi	a2,s0,-65
    800051ca:	85ca                	mv	a1,s2
    800051cc:	070a3503          	ld	a0,112(s4)
    800051d0:	ffffc097          	auipc	ra,0xffffc
    800051d4:	4b4080e7          	jalr	1204(ra) # 80001684 <copyout>
    800051d8:	01650663          	beq	a0,s6,800051e4 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051dc:	2985                	addiw	s3,s3,1
    800051de:	0905                	addi	s2,s2,1
    800051e0:	fd3a91e3          	bne	s5,s3,800051a2 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800051e4:	21c48513          	addi	a0,s1,540
    800051e8:	ffffd097          	auipc	ra,0xffffd
    800051ec:	4e8080e7          	jalr	1256(ra) # 800026d0 <wakeup>
  release(&pi->lock);
    800051f0:	8526                	mv	a0,s1
    800051f2:	ffffc097          	auipc	ra,0xffffc
    800051f6:	aa6080e7          	jalr	-1370(ra) # 80000c98 <release>
  return i;
}
    800051fa:	854e                	mv	a0,s3
    800051fc:	60a6                	ld	ra,72(sp)
    800051fe:	6406                	ld	s0,64(sp)
    80005200:	74e2                	ld	s1,56(sp)
    80005202:	7942                	ld	s2,48(sp)
    80005204:	79a2                	ld	s3,40(sp)
    80005206:	7a02                	ld	s4,32(sp)
    80005208:	6ae2                	ld	s5,24(sp)
    8000520a:	6b42                	ld	s6,16(sp)
    8000520c:	6161                	addi	sp,sp,80
    8000520e:	8082                	ret
      release(&pi->lock);
    80005210:	8526                	mv	a0,s1
    80005212:	ffffc097          	auipc	ra,0xffffc
    80005216:	a86080e7          	jalr	-1402(ra) # 80000c98 <release>
      return -1;
    8000521a:	59fd                	li	s3,-1
    8000521c:	bff9                	j	800051fa <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000521e:	4981                	li	s3,0
    80005220:	b7d1                	j	800051e4 <piperead+0xae>

0000000080005222 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005222:	df010113          	addi	sp,sp,-528
    80005226:	20113423          	sd	ra,520(sp)
    8000522a:	20813023          	sd	s0,512(sp)
    8000522e:	ffa6                	sd	s1,504(sp)
    80005230:	fbca                	sd	s2,496(sp)
    80005232:	f7ce                	sd	s3,488(sp)
    80005234:	f3d2                	sd	s4,480(sp)
    80005236:	efd6                	sd	s5,472(sp)
    80005238:	ebda                	sd	s6,464(sp)
    8000523a:	e7de                	sd	s7,456(sp)
    8000523c:	e3e2                	sd	s8,448(sp)
    8000523e:	ff66                	sd	s9,440(sp)
    80005240:	fb6a                	sd	s10,432(sp)
    80005242:	f76e                	sd	s11,424(sp)
    80005244:	0c00                	addi	s0,sp,528
    80005246:	84aa                	mv	s1,a0
    80005248:	dea43c23          	sd	a0,-520(s0)
    8000524c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005250:	ffffd097          	auipc	ra,0xffffd
    80005254:	af2080e7          	jalr	-1294(ra) # 80001d42 <myproc>
    80005258:	892a                	mv	s2,a0

  begin_op();
    8000525a:	fffff097          	auipc	ra,0xfffff
    8000525e:	49c080e7          	jalr	1180(ra) # 800046f6 <begin_op>

  if((ip = namei(path)) == 0){
    80005262:	8526                	mv	a0,s1
    80005264:	fffff097          	auipc	ra,0xfffff
    80005268:	276080e7          	jalr	630(ra) # 800044da <namei>
    8000526c:	c92d                	beqz	a0,800052de <exec+0xbc>
    8000526e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005270:	fffff097          	auipc	ra,0xfffff
    80005274:	ab4080e7          	jalr	-1356(ra) # 80003d24 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005278:	04000713          	li	a4,64
    8000527c:	4681                	li	a3,0
    8000527e:	e5040613          	addi	a2,s0,-432
    80005282:	4581                	li	a1,0
    80005284:	8526                	mv	a0,s1
    80005286:	fffff097          	auipc	ra,0xfffff
    8000528a:	d52080e7          	jalr	-686(ra) # 80003fd8 <readi>
    8000528e:	04000793          	li	a5,64
    80005292:	00f51a63          	bne	a0,a5,800052a6 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005296:	e5042703          	lw	a4,-432(s0)
    8000529a:	464c47b7          	lui	a5,0x464c4
    8000529e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800052a2:	04f70463          	beq	a4,a5,800052ea <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800052a6:	8526                	mv	a0,s1
    800052a8:	fffff097          	auipc	ra,0xfffff
    800052ac:	cde080e7          	jalr	-802(ra) # 80003f86 <iunlockput>
    end_op();
    800052b0:	fffff097          	auipc	ra,0xfffff
    800052b4:	4c6080e7          	jalr	1222(ra) # 80004776 <end_op>
  }
  return -1;
    800052b8:	557d                	li	a0,-1
}
    800052ba:	20813083          	ld	ra,520(sp)
    800052be:	20013403          	ld	s0,512(sp)
    800052c2:	74fe                	ld	s1,504(sp)
    800052c4:	795e                	ld	s2,496(sp)
    800052c6:	79be                	ld	s3,488(sp)
    800052c8:	7a1e                	ld	s4,480(sp)
    800052ca:	6afe                	ld	s5,472(sp)
    800052cc:	6b5e                	ld	s6,464(sp)
    800052ce:	6bbe                	ld	s7,456(sp)
    800052d0:	6c1e                	ld	s8,448(sp)
    800052d2:	7cfa                	ld	s9,440(sp)
    800052d4:	7d5a                	ld	s10,432(sp)
    800052d6:	7dba                	ld	s11,424(sp)
    800052d8:	21010113          	addi	sp,sp,528
    800052dc:	8082                	ret
    end_op();
    800052de:	fffff097          	auipc	ra,0xfffff
    800052e2:	498080e7          	jalr	1176(ra) # 80004776 <end_op>
    return -1;
    800052e6:	557d                	li	a0,-1
    800052e8:	bfc9                	j	800052ba <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800052ea:	854a                	mv	a0,s2
    800052ec:	ffffd097          	auipc	ra,0xffffd
    800052f0:	b14080e7          	jalr	-1260(ra) # 80001e00 <proc_pagetable>
    800052f4:	8baa                	mv	s7,a0
    800052f6:	d945                	beqz	a0,800052a6 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052f8:	e7042983          	lw	s3,-400(s0)
    800052fc:	e8845783          	lhu	a5,-376(s0)
    80005300:	c7ad                	beqz	a5,8000536a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005302:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005304:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005306:	6c85                	lui	s9,0x1
    80005308:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000530c:	def43823          	sd	a5,-528(s0)
    80005310:	a42d                	j	8000553a <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005312:	00003517          	auipc	a0,0x3
    80005316:	41e50513          	addi	a0,a0,1054 # 80008730 <syscalls+0x290>
    8000531a:	ffffb097          	auipc	ra,0xffffb
    8000531e:	224080e7          	jalr	548(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005322:	8756                	mv	a4,s5
    80005324:	012d86bb          	addw	a3,s11,s2
    80005328:	4581                	li	a1,0
    8000532a:	8526                	mv	a0,s1
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	cac080e7          	jalr	-852(ra) # 80003fd8 <readi>
    80005334:	2501                	sext.w	a0,a0
    80005336:	1aaa9963          	bne	s5,a0,800054e8 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000533a:	6785                	lui	a5,0x1
    8000533c:	0127893b          	addw	s2,a5,s2
    80005340:	77fd                	lui	a5,0xfffff
    80005342:	01478a3b          	addw	s4,a5,s4
    80005346:	1f897163          	bgeu	s2,s8,80005528 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000534a:	02091593          	slli	a1,s2,0x20
    8000534e:	9181                	srli	a1,a1,0x20
    80005350:	95ea                	add	a1,a1,s10
    80005352:	855e                	mv	a0,s7
    80005354:	ffffc097          	auipc	ra,0xffffc
    80005358:	d2c080e7          	jalr	-724(ra) # 80001080 <walkaddr>
    8000535c:	862a                	mv	a2,a0
    if(pa == 0)
    8000535e:	d955                	beqz	a0,80005312 <exec+0xf0>
      n = PGSIZE;
    80005360:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005362:	fd9a70e3          	bgeu	s4,s9,80005322 <exec+0x100>
      n = sz - i;
    80005366:	8ad2                	mv	s5,s4
    80005368:	bf6d                	j	80005322 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000536a:	4901                	li	s2,0
  iunlockput(ip);
    8000536c:	8526                	mv	a0,s1
    8000536e:	fffff097          	auipc	ra,0xfffff
    80005372:	c18080e7          	jalr	-1000(ra) # 80003f86 <iunlockput>
  end_op();
    80005376:	fffff097          	auipc	ra,0xfffff
    8000537a:	400080e7          	jalr	1024(ra) # 80004776 <end_op>
  p = myproc();
    8000537e:	ffffd097          	auipc	ra,0xffffd
    80005382:	9c4080e7          	jalr	-1596(ra) # 80001d42 <myproc>
    80005386:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005388:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    8000538c:	6785                	lui	a5,0x1
    8000538e:	17fd                	addi	a5,a5,-1
    80005390:	993e                	add	s2,s2,a5
    80005392:	757d                	lui	a0,0xfffff
    80005394:	00a977b3          	and	a5,s2,a0
    80005398:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000539c:	6609                	lui	a2,0x2
    8000539e:	963e                	add	a2,a2,a5
    800053a0:	85be                	mv	a1,a5
    800053a2:	855e                	mv	a0,s7
    800053a4:	ffffc097          	auipc	ra,0xffffc
    800053a8:	090080e7          	jalr	144(ra) # 80001434 <uvmalloc>
    800053ac:	8b2a                	mv	s6,a0
  ip = 0;
    800053ae:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800053b0:	12050c63          	beqz	a0,800054e8 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800053b4:	75f9                	lui	a1,0xffffe
    800053b6:	95aa                	add	a1,a1,a0
    800053b8:	855e                	mv	a0,s7
    800053ba:	ffffc097          	auipc	ra,0xffffc
    800053be:	298080e7          	jalr	664(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    800053c2:	7c7d                	lui	s8,0xfffff
    800053c4:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800053c6:	e0043783          	ld	a5,-512(s0)
    800053ca:	6388                	ld	a0,0(a5)
    800053cc:	c535                	beqz	a0,80005438 <exec+0x216>
    800053ce:	e9040993          	addi	s3,s0,-368
    800053d2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800053d6:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800053d8:	ffffc097          	auipc	ra,0xffffc
    800053dc:	a9e080e7          	jalr	-1378(ra) # 80000e76 <strlen>
    800053e0:	2505                	addiw	a0,a0,1
    800053e2:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800053e6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800053ea:	13896363          	bltu	s2,s8,80005510 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800053ee:	e0043d83          	ld	s11,-512(s0)
    800053f2:	000dba03          	ld	s4,0(s11)
    800053f6:	8552                	mv	a0,s4
    800053f8:	ffffc097          	auipc	ra,0xffffc
    800053fc:	a7e080e7          	jalr	-1410(ra) # 80000e76 <strlen>
    80005400:	0015069b          	addiw	a3,a0,1
    80005404:	8652                	mv	a2,s4
    80005406:	85ca                	mv	a1,s2
    80005408:	855e                	mv	a0,s7
    8000540a:	ffffc097          	auipc	ra,0xffffc
    8000540e:	27a080e7          	jalr	634(ra) # 80001684 <copyout>
    80005412:	10054363          	bltz	a0,80005518 <exec+0x2f6>
    ustack[argc] = sp;
    80005416:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000541a:	0485                	addi	s1,s1,1
    8000541c:	008d8793          	addi	a5,s11,8
    80005420:	e0f43023          	sd	a5,-512(s0)
    80005424:	008db503          	ld	a0,8(s11)
    80005428:	c911                	beqz	a0,8000543c <exec+0x21a>
    if(argc >= MAXARG)
    8000542a:	09a1                	addi	s3,s3,8
    8000542c:	fb3c96e3          	bne	s9,s3,800053d8 <exec+0x1b6>
  sz = sz1;
    80005430:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005434:	4481                	li	s1,0
    80005436:	a84d                	j	800054e8 <exec+0x2c6>
  sp = sz;
    80005438:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000543a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000543c:	00349793          	slli	a5,s1,0x3
    80005440:	f9040713          	addi	a4,s0,-112
    80005444:	97ba                	add	a5,a5,a4
    80005446:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000544a:	00148693          	addi	a3,s1,1
    8000544e:	068e                	slli	a3,a3,0x3
    80005450:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005454:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005458:	01897663          	bgeu	s2,s8,80005464 <exec+0x242>
  sz = sz1;
    8000545c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005460:	4481                	li	s1,0
    80005462:	a059                	j	800054e8 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005464:	e9040613          	addi	a2,s0,-368
    80005468:	85ca                	mv	a1,s2
    8000546a:	855e                	mv	a0,s7
    8000546c:	ffffc097          	auipc	ra,0xffffc
    80005470:	218080e7          	jalr	536(ra) # 80001684 <copyout>
    80005474:	0a054663          	bltz	a0,80005520 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005478:	078ab783          	ld	a5,120(s5)
    8000547c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005480:	df843783          	ld	a5,-520(s0)
    80005484:	0007c703          	lbu	a4,0(a5)
    80005488:	cf11                	beqz	a4,800054a4 <exec+0x282>
    8000548a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000548c:	02f00693          	li	a3,47
    80005490:	a039                	j	8000549e <exec+0x27c>
      last = s+1;
    80005492:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005496:	0785                	addi	a5,a5,1
    80005498:	fff7c703          	lbu	a4,-1(a5)
    8000549c:	c701                	beqz	a4,800054a4 <exec+0x282>
    if(*s == '/')
    8000549e:	fed71ce3          	bne	a4,a3,80005496 <exec+0x274>
    800054a2:	bfc5                	j	80005492 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800054a4:	4641                	li	a2,16
    800054a6:	df843583          	ld	a1,-520(s0)
    800054aa:	178a8513          	addi	a0,s5,376
    800054ae:	ffffc097          	auipc	ra,0xffffc
    800054b2:	996080e7          	jalr	-1642(ra) # 80000e44 <safestrcpy>
  oldpagetable = p->pagetable;
    800054b6:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    800054ba:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    800054be:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800054c2:	078ab783          	ld	a5,120(s5)
    800054c6:	e6843703          	ld	a4,-408(s0)
    800054ca:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800054cc:	078ab783          	ld	a5,120(s5)
    800054d0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054d4:	85ea                	mv	a1,s10
    800054d6:	ffffd097          	auipc	ra,0xffffd
    800054da:	9c6080e7          	jalr	-1594(ra) # 80001e9c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800054de:	0004851b          	sext.w	a0,s1
    800054e2:	bbe1                	j	800052ba <exec+0x98>
    800054e4:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800054e8:	e0843583          	ld	a1,-504(s0)
    800054ec:	855e                	mv	a0,s7
    800054ee:	ffffd097          	auipc	ra,0xffffd
    800054f2:	9ae080e7          	jalr	-1618(ra) # 80001e9c <proc_freepagetable>
  if(ip){
    800054f6:	da0498e3          	bnez	s1,800052a6 <exec+0x84>
  return -1;
    800054fa:	557d                	li	a0,-1
    800054fc:	bb7d                	j	800052ba <exec+0x98>
    800054fe:	e1243423          	sd	s2,-504(s0)
    80005502:	b7dd                	j	800054e8 <exec+0x2c6>
    80005504:	e1243423          	sd	s2,-504(s0)
    80005508:	b7c5                	j	800054e8 <exec+0x2c6>
    8000550a:	e1243423          	sd	s2,-504(s0)
    8000550e:	bfe9                	j	800054e8 <exec+0x2c6>
  sz = sz1;
    80005510:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005514:	4481                	li	s1,0
    80005516:	bfc9                	j	800054e8 <exec+0x2c6>
  sz = sz1;
    80005518:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000551c:	4481                	li	s1,0
    8000551e:	b7e9                	j	800054e8 <exec+0x2c6>
  sz = sz1;
    80005520:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005524:	4481                	li	s1,0
    80005526:	b7c9                	j	800054e8 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005528:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000552c:	2b05                	addiw	s6,s6,1
    8000552e:	0389899b          	addiw	s3,s3,56
    80005532:	e8845783          	lhu	a5,-376(s0)
    80005536:	e2fb5be3          	bge	s6,a5,8000536c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000553a:	2981                	sext.w	s3,s3
    8000553c:	03800713          	li	a4,56
    80005540:	86ce                	mv	a3,s3
    80005542:	e1840613          	addi	a2,s0,-488
    80005546:	4581                	li	a1,0
    80005548:	8526                	mv	a0,s1
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	a8e080e7          	jalr	-1394(ra) # 80003fd8 <readi>
    80005552:	03800793          	li	a5,56
    80005556:	f8f517e3          	bne	a0,a5,800054e4 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000555a:	e1842783          	lw	a5,-488(s0)
    8000555e:	4705                	li	a4,1
    80005560:	fce796e3          	bne	a5,a4,8000552c <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005564:	e4043603          	ld	a2,-448(s0)
    80005568:	e3843783          	ld	a5,-456(s0)
    8000556c:	f8f669e3          	bltu	a2,a5,800054fe <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005570:	e2843783          	ld	a5,-472(s0)
    80005574:	963e                	add	a2,a2,a5
    80005576:	f8f667e3          	bltu	a2,a5,80005504 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000557a:	85ca                	mv	a1,s2
    8000557c:	855e                	mv	a0,s7
    8000557e:	ffffc097          	auipc	ra,0xffffc
    80005582:	eb6080e7          	jalr	-330(ra) # 80001434 <uvmalloc>
    80005586:	e0a43423          	sd	a0,-504(s0)
    8000558a:	d141                	beqz	a0,8000550a <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000558c:	e2843d03          	ld	s10,-472(s0)
    80005590:	df043783          	ld	a5,-528(s0)
    80005594:	00fd77b3          	and	a5,s10,a5
    80005598:	fba1                	bnez	a5,800054e8 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000559a:	e2042d83          	lw	s11,-480(s0)
    8000559e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800055a2:	f80c03e3          	beqz	s8,80005528 <exec+0x306>
    800055a6:	8a62                	mv	s4,s8
    800055a8:	4901                	li	s2,0
    800055aa:	b345                	j	8000534a <exec+0x128>

00000000800055ac <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800055ac:	7179                	addi	sp,sp,-48
    800055ae:	f406                	sd	ra,40(sp)
    800055b0:	f022                	sd	s0,32(sp)
    800055b2:	ec26                	sd	s1,24(sp)
    800055b4:	e84a                	sd	s2,16(sp)
    800055b6:	1800                	addi	s0,sp,48
    800055b8:	892e                	mv	s2,a1
    800055ba:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800055bc:	fdc40593          	addi	a1,s0,-36
    800055c0:	ffffe097          	auipc	ra,0xffffe
    800055c4:	ba8080e7          	jalr	-1112(ra) # 80003168 <argint>
    800055c8:	04054063          	bltz	a0,80005608 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800055cc:	fdc42703          	lw	a4,-36(s0)
    800055d0:	47bd                	li	a5,15
    800055d2:	02e7ed63          	bltu	a5,a4,8000560c <argfd+0x60>
    800055d6:	ffffc097          	auipc	ra,0xffffc
    800055da:	76c080e7          	jalr	1900(ra) # 80001d42 <myproc>
    800055de:	fdc42703          	lw	a4,-36(s0)
    800055e2:	01e70793          	addi	a5,a4,30
    800055e6:	078e                	slli	a5,a5,0x3
    800055e8:	953e                	add	a0,a0,a5
    800055ea:	611c                	ld	a5,0(a0)
    800055ec:	c395                	beqz	a5,80005610 <argfd+0x64>
    return -1;
  if(pfd)
    800055ee:	00090463          	beqz	s2,800055f6 <argfd+0x4a>
    *pfd = fd;
    800055f2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800055f6:	4501                	li	a0,0
  if(pf)
    800055f8:	c091                	beqz	s1,800055fc <argfd+0x50>
    *pf = f;
    800055fa:	e09c                	sd	a5,0(s1)
}
    800055fc:	70a2                	ld	ra,40(sp)
    800055fe:	7402                	ld	s0,32(sp)
    80005600:	64e2                	ld	s1,24(sp)
    80005602:	6942                	ld	s2,16(sp)
    80005604:	6145                	addi	sp,sp,48
    80005606:	8082                	ret
    return -1;
    80005608:	557d                	li	a0,-1
    8000560a:	bfcd                	j	800055fc <argfd+0x50>
    return -1;
    8000560c:	557d                	li	a0,-1
    8000560e:	b7fd                	j	800055fc <argfd+0x50>
    80005610:	557d                	li	a0,-1
    80005612:	b7ed                	j	800055fc <argfd+0x50>

0000000080005614 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005614:	1101                	addi	sp,sp,-32
    80005616:	ec06                	sd	ra,24(sp)
    80005618:	e822                	sd	s0,16(sp)
    8000561a:	e426                	sd	s1,8(sp)
    8000561c:	1000                	addi	s0,sp,32
    8000561e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005620:	ffffc097          	auipc	ra,0xffffc
    80005624:	722080e7          	jalr	1826(ra) # 80001d42 <myproc>
    80005628:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000562a:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    8000562e:	4501                	li	a0,0
    80005630:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005632:	6398                	ld	a4,0(a5)
    80005634:	cb19                	beqz	a4,8000564a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005636:	2505                	addiw	a0,a0,1
    80005638:	07a1                	addi	a5,a5,8
    8000563a:	fed51ce3          	bne	a0,a3,80005632 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000563e:	557d                	li	a0,-1
}
    80005640:	60e2                	ld	ra,24(sp)
    80005642:	6442                	ld	s0,16(sp)
    80005644:	64a2                	ld	s1,8(sp)
    80005646:	6105                	addi	sp,sp,32
    80005648:	8082                	ret
      p->ofile[fd] = f;
    8000564a:	01e50793          	addi	a5,a0,30
    8000564e:	078e                	slli	a5,a5,0x3
    80005650:	963e                	add	a2,a2,a5
    80005652:	e204                	sd	s1,0(a2)
      return fd;
    80005654:	b7f5                	j	80005640 <fdalloc+0x2c>

0000000080005656 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005656:	715d                	addi	sp,sp,-80
    80005658:	e486                	sd	ra,72(sp)
    8000565a:	e0a2                	sd	s0,64(sp)
    8000565c:	fc26                	sd	s1,56(sp)
    8000565e:	f84a                	sd	s2,48(sp)
    80005660:	f44e                	sd	s3,40(sp)
    80005662:	f052                	sd	s4,32(sp)
    80005664:	ec56                	sd	s5,24(sp)
    80005666:	0880                	addi	s0,sp,80
    80005668:	89ae                	mv	s3,a1
    8000566a:	8ab2                	mv	s5,a2
    8000566c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000566e:	fb040593          	addi	a1,s0,-80
    80005672:	fffff097          	auipc	ra,0xfffff
    80005676:	e86080e7          	jalr	-378(ra) # 800044f8 <nameiparent>
    8000567a:	892a                	mv	s2,a0
    8000567c:	12050f63          	beqz	a0,800057ba <create+0x164>
    return 0;

  ilock(dp);
    80005680:	ffffe097          	auipc	ra,0xffffe
    80005684:	6a4080e7          	jalr	1700(ra) # 80003d24 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005688:	4601                	li	a2,0
    8000568a:	fb040593          	addi	a1,s0,-80
    8000568e:	854a                	mv	a0,s2
    80005690:	fffff097          	auipc	ra,0xfffff
    80005694:	b78080e7          	jalr	-1160(ra) # 80004208 <dirlookup>
    80005698:	84aa                	mv	s1,a0
    8000569a:	c921                	beqz	a0,800056ea <create+0x94>
    iunlockput(dp);
    8000569c:	854a                	mv	a0,s2
    8000569e:	fffff097          	auipc	ra,0xfffff
    800056a2:	8e8080e7          	jalr	-1816(ra) # 80003f86 <iunlockput>
    ilock(ip);
    800056a6:	8526                	mv	a0,s1
    800056a8:	ffffe097          	auipc	ra,0xffffe
    800056ac:	67c080e7          	jalr	1660(ra) # 80003d24 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800056b0:	2981                	sext.w	s3,s3
    800056b2:	4789                	li	a5,2
    800056b4:	02f99463          	bne	s3,a5,800056dc <create+0x86>
    800056b8:	0444d783          	lhu	a5,68(s1)
    800056bc:	37f9                	addiw	a5,a5,-2
    800056be:	17c2                	slli	a5,a5,0x30
    800056c0:	93c1                	srli	a5,a5,0x30
    800056c2:	4705                	li	a4,1
    800056c4:	00f76c63          	bltu	a4,a5,800056dc <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800056c8:	8526                	mv	a0,s1
    800056ca:	60a6                	ld	ra,72(sp)
    800056cc:	6406                	ld	s0,64(sp)
    800056ce:	74e2                	ld	s1,56(sp)
    800056d0:	7942                	ld	s2,48(sp)
    800056d2:	79a2                	ld	s3,40(sp)
    800056d4:	7a02                	ld	s4,32(sp)
    800056d6:	6ae2                	ld	s5,24(sp)
    800056d8:	6161                	addi	sp,sp,80
    800056da:	8082                	ret
    iunlockput(ip);
    800056dc:	8526                	mv	a0,s1
    800056de:	fffff097          	auipc	ra,0xfffff
    800056e2:	8a8080e7          	jalr	-1880(ra) # 80003f86 <iunlockput>
    return 0;
    800056e6:	4481                	li	s1,0
    800056e8:	b7c5                	j	800056c8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800056ea:	85ce                	mv	a1,s3
    800056ec:	00092503          	lw	a0,0(s2)
    800056f0:	ffffe097          	auipc	ra,0xffffe
    800056f4:	49c080e7          	jalr	1180(ra) # 80003b8c <ialloc>
    800056f8:	84aa                	mv	s1,a0
    800056fa:	c529                	beqz	a0,80005744 <create+0xee>
  ilock(ip);
    800056fc:	ffffe097          	auipc	ra,0xffffe
    80005700:	628080e7          	jalr	1576(ra) # 80003d24 <ilock>
  ip->major = major;
    80005704:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005708:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000570c:	4785                	li	a5,1
    8000570e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005712:	8526                	mv	a0,s1
    80005714:	ffffe097          	auipc	ra,0xffffe
    80005718:	546080e7          	jalr	1350(ra) # 80003c5a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000571c:	2981                	sext.w	s3,s3
    8000571e:	4785                	li	a5,1
    80005720:	02f98a63          	beq	s3,a5,80005754 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005724:	40d0                	lw	a2,4(s1)
    80005726:	fb040593          	addi	a1,s0,-80
    8000572a:	854a                	mv	a0,s2
    8000572c:	fffff097          	auipc	ra,0xfffff
    80005730:	cec080e7          	jalr	-788(ra) # 80004418 <dirlink>
    80005734:	06054b63          	bltz	a0,800057aa <create+0x154>
  iunlockput(dp);
    80005738:	854a                	mv	a0,s2
    8000573a:	fffff097          	auipc	ra,0xfffff
    8000573e:	84c080e7          	jalr	-1972(ra) # 80003f86 <iunlockput>
  return ip;
    80005742:	b759                	j	800056c8 <create+0x72>
    panic("create: ialloc");
    80005744:	00003517          	auipc	a0,0x3
    80005748:	00c50513          	addi	a0,a0,12 # 80008750 <syscalls+0x2b0>
    8000574c:	ffffb097          	auipc	ra,0xffffb
    80005750:	df2080e7          	jalr	-526(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005754:	04a95783          	lhu	a5,74(s2)
    80005758:	2785                	addiw	a5,a5,1
    8000575a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000575e:	854a                	mv	a0,s2
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	4fa080e7          	jalr	1274(ra) # 80003c5a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005768:	40d0                	lw	a2,4(s1)
    8000576a:	00003597          	auipc	a1,0x3
    8000576e:	ff658593          	addi	a1,a1,-10 # 80008760 <syscalls+0x2c0>
    80005772:	8526                	mv	a0,s1
    80005774:	fffff097          	auipc	ra,0xfffff
    80005778:	ca4080e7          	jalr	-860(ra) # 80004418 <dirlink>
    8000577c:	00054f63          	bltz	a0,8000579a <create+0x144>
    80005780:	00492603          	lw	a2,4(s2)
    80005784:	00003597          	auipc	a1,0x3
    80005788:	fe458593          	addi	a1,a1,-28 # 80008768 <syscalls+0x2c8>
    8000578c:	8526                	mv	a0,s1
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	c8a080e7          	jalr	-886(ra) # 80004418 <dirlink>
    80005796:	f80557e3          	bgez	a0,80005724 <create+0xce>
      panic("create dots");
    8000579a:	00003517          	auipc	a0,0x3
    8000579e:	fd650513          	addi	a0,a0,-42 # 80008770 <syscalls+0x2d0>
    800057a2:	ffffb097          	auipc	ra,0xffffb
    800057a6:	d9c080e7          	jalr	-612(ra) # 8000053e <panic>
    panic("create: dirlink");
    800057aa:	00003517          	auipc	a0,0x3
    800057ae:	fd650513          	addi	a0,a0,-42 # 80008780 <syscalls+0x2e0>
    800057b2:	ffffb097          	auipc	ra,0xffffb
    800057b6:	d8c080e7          	jalr	-628(ra) # 8000053e <panic>
    return 0;
    800057ba:	84aa                	mv	s1,a0
    800057bc:	b731                	j	800056c8 <create+0x72>

00000000800057be <sys_dup>:
{
    800057be:	7179                	addi	sp,sp,-48
    800057c0:	f406                	sd	ra,40(sp)
    800057c2:	f022                	sd	s0,32(sp)
    800057c4:	ec26                	sd	s1,24(sp)
    800057c6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800057c8:	fd840613          	addi	a2,s0,-40
    800057cc:	4581                	li	a1,0
    800057ce:	4501                	li	a0,0
    800057d0:	00000097          	auipc	ra,0x0
    800057d4:	ddc080e7          	jalr	-548(ra) # 800055ac <argfd>
    return -1;
    800057d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800057da:	02054363          	bltz	a0,80005800 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800057de:	fd843503          	ld	a0,-40(s0)
    800057e2:	00000097          	auipc	ra,0x0
    800057e6:	e32080e7          	jalr	-462(ra) # 80005614 <fdalloc>
    800057ea:	84aa                	mv	s1,a0
    return -1;
    800057ec:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800057ee:	00054963          	bltz	a0,80005800 <sys_dup+0x42>
  filedup(f);
    800057f2:	fd843503          	ld	a0,-40(s0)
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	37a080e7          	jalr	890(ra) # 80004b70 <filedup>
  return fd;
    800057fe:	87a6                	mv	a5,s1
}
    80005800:	853e                	mv	a0,a5
    80005802:	70a2                	ld	ra,40(sp)
    80005804:	7402                	ld	s0,32(sp)
    80005806:	64e2                	ld	s1,24(sp)
    80005808:	6145                	addi	sp,sp,48
    8000580a:	8082                	ret

000000008000580c <sys_read>:
{
    8000580c:	7179                	addi	sp,sp,-48
    8000580e:	f406                	sd	ra,40(sp)
    80005810:	f022                	sd	s0,32(sp)
    80005812:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005814:	fe840613          	addi	a2,s0,-24
    80005818:	4581                	li	a1,0
    8000581a:	4501                	li	a0,0
    8000581c:	00000097          	auipc	ra,0x0
    80005820:	d90080e7          	jalr	-624(ra) # 800055ac <argfd>
    return -1;
    80005824:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005826:	04054163          	bltz	a0,80005868 <sys_read+0x5c>
    8000582a:	fe440593          	addi	a1,s0,-28
    8000582e:	4509                	li	a0,2
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	938080e7          	jalr	-1736(ra) # 80003168 <argint>
    return -1;
    80005838:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000583a:	02054763          	bltz	a0,80005868 <sys_read+0x5c>
    8000583e:	fd840593          	addi	a1,s0,-40
    80005842:	4505                	li	a0,1
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	946080e7          	jalr	-1722(ra) # 8000318a <argaddr>
    return -1;
    8000584c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000584e:	00054d63          	bltz	a0,80005868 <sys_read+0x5c>
  return fileread(f, p, n);
    80005852:	fe442603          	lw	a2,-28(s0)
    80005856:	fd843583          	ld	a1,-40(s0)
    8000585a:	fe843503          	ld	a0,-24(s0)
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	49e080e7          	jalr	1182(ra) # 80004cfc <fileread>
    80005866:	87aa                	mv	a5,a0
}
    80005868:	853e                	mv	a0,a5
    8000586a:	70a2                	ld	ra,40(sp)
    8000586c:	7402                	ld	s0,32(sp)
    8000586e:	6145                	addi	sp,sp,48
    80005870:	8082                	ret

0000000080005872 <sys_write>:
{
    80005872:	7179                	addi	sp,sp,-48
    80005874:	f406                	sd	ra,40(sp)
    80005876:	f022                	sd	s0,32(sp)
    80005878:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000587a:	fe840613          	addi	a2,s0,-24
    8000587e:	4581                	li	a1,0
    80005880:	4501                	li	a0,0
    80005882:	00000097          	auipc	ra,0x0
    80005886:	d2a080e7          	jalr	-726(ra) # 800055ac <argfd>
    return -1;
    8000588a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000588c:	04054163          	bltz	a0,800058ce <sys_write+0x5c>
    80005890:	fe440593          	addi	a1,s0,-28
    80005894:	4509                	li	a0,2
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	8d2080e7          	jalr	-1838(ra) # 80003168 <argint>
    return -1;
    8000589e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058a0:	02054763          	bltz	a0,800058ce <sys_write+0x5c>
    800058a4:	fd840593          	addi	a1,s0,-40
    800058a8:	4505                	li	a0,1
    800058aa:	ffffe097          	auipc	ra,0xffffe
    800058ae:	8e0080e7          	jalr	-1824(ra) # 8000318a <argaddr>
    return -1;
    800058b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058b4:	00054d63          	bltz	a0,800058ce <sys_write+0x5c>
  return filewrite(f, p, n);
    800058b8:	fe442603          	lw	a2,-28(s0)
    800058bc:	fd843583          	ld	a1,-40(s0)
    800058c0:	fe843503          	ld	a0,-24(s0)
    800058c4:	fffff097          	auipc	ra,0xfffff
    800058c8:	4fa080e7          	jalr	1274(ra) # 80004dbe <filewrite>
    800058cc:	87aa                	mv	a5,a0
}
    800058ce:	853e                	mv	a0,a5
    800058d0:	70a2                	ld	ra,40(sp)
    800058d2:	7402                	ld	s0,32(sp)
    800058d4:	6145                	addi	sp,sp,48
    800058d6:	8082                	ret

00000000800058d8 <sys_close>:
{
    800058d8:	1101                	addi	sp,sp,-32
    800058da:	ec06                	sd	ra,24(sp)
    800058dc:	e822                	sd	s0,16(sp)
    800058de:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800058e0:	fe040613          	addi	a2,s0,-32
    800058e4:	fec40593          	addi	a1,s0,-20
    800058e8:	4501                	li	a0,0
    800058ea:	00000097          	auipc	ra,0x0
    800058ee:	cc2080e7          	jalr	-830(ra) # 800055ac <argfd>
    return -1;
    800058f2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800058f4:	02054463          	bltz	a0,8000591c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800058f8:	ffffc097          	auipc	ra,0xffffc
    800058fc:	44a080e7          	jalr	1098(ra) # 80001d42 <myproc>
    80005900:	fec42783          	lw	a5,-20(s0)
    80005904:	07f9                	addi	a5,a5,30
    80005906:	078e                	slli	a5,a5,0x3
    80005908:	97aa                	add	a5,a5,a0
    8000590a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000590e:	fe043503          	ld	a0,-32(s0)
    80005912:	fffff097          	auipc	ra,0xfffff
    80005916:	2b0080e7          	jalr	688(ra) # 80004bc2 <fileclose>
  return 0;
    8000591a:	4781                	li	a5,0
}
    8000591c:	853e                	mv	a0,a5
    8000591e:	60e2                	ld	ra,24(sp)
    80005920:	6442                	ld	s0,16(sp)
    80005922:	6105                	addi	sp,sp,32
    80005924:	8082                	ret

0000000080005926 <sys_fstat>:
{
    80005926:	1101                	addi	sp,sp,-32
    80005928:	ec06                	sd	ra,24(sp)
    8000592a:	e822                	sd	s0,16(sp)
    8000592c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000592e:	fe840613          	addi	a2,s0,-24
    80005932:	4581                	li	a1,0
    80005934:	4501                	li	a0,0
    80005936:	00000097          	auipc	ra,0x0
    8000593a:	c76080e7          	jalr	-906(ra) # 800055ac <argfd>
    return -1;
    8000593e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005940:	02054563          	bltz	a0,8000596a <sys_fstat+0x44>
    80005944:	fe040593          	addi	a1,s0,-32
    80005948:	4505                	li	a0,1
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	840080e7          	jalr	-1984(ra) # 8000318a <argaddr>
    return -1;
    80005952:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005954:	00054b63          	bltz	a0,8000596a <sys_fstat+0x44>
  return filestat(f, st);
    80005958:	fe043583          	ld	a1,-32(s0)
    8000595c:	fe843503          	ld	a0,-24(s0)
    80005960:	fffff097          	auipc	ra,0xfffff
    80005964:	32a080e7          	jalr	810(ra) # 80004c8a <filestat>
    80005968:	87aa                	mv	a5,a0
}
    8000596a:	853e                	mv	a0,a5
    8000596c:	60e2                	ld	ra,24(sp)
    8000596e:	6442                	ld	s0,16(sp)
    80005970:	6105                	addi	sp,sp,32
    80005972:	8082                	ret

0000000080005974 <sys_link>:
{
    80005974:	7169                	addi	sp,sp,-304
    80005976:	f606                	sd	ra,296(sp)
    80005978:	f222                	sd	s0,288(sp)
    8000597a:	ee26                	sd	s1,280(sp)
    8000597c:	ea4a                	sd	s2,272(sp)
    8000597e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005980:	08000613          	li	a2,128
    80005984:	ed040593          	addi	a1,s0,-304
    80005988:	4501                	li	a0,0
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	822080e7          	jalr	-2014(ra) # 800031ac <argstr>
    return -1;
    80005992:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005994:	10054e63          	bltz	a0,80005ab0 <sys_link+0x13c>
    80005998:	08000613          	li	a2,128
    8000599c:	f5040593          	addi	a1,s0,-176
    800059a0:	4505                	li	a0,1
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	80a080e7          	jalr	-2038(ra) # 800031ac <argstr>
    return -1;
    800059aa:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059ac:	10054263          	bltz	a0,80005ab0 <sys_link+0x13c>
  begin_op();
    800059b0:	fffff097          	auipc	ra,0xfffff
    800059b4:	d46080e7          	jalr	-698(ra) # 800046f6 <begin_op>
  if((ip = namei(old)) == 0){
    800059b8:	ed040513          	addi	a0,s0,-304
    800059bc:	fffff097          	auipc	ra,0xfffff
    800059c0:	b1e080e7          	jalr	-1250(ra) # 800044da <namei>
    800059c4:	84aa                	mv	s1,a0
    800059c6:	c551                	beqz	a0,80005a52 <sys_link+0xde>
  ilock(ip);
    800059c8:	ffffe097          	auipc	ra,0xffffe
    800059cc:	35c080e7          	jalr	860(ra) # 80003d24 <ilock>
  if(ip->type == T_DIR){
    800059d0:	04449703          	lh	a4,68(s1)
    800059d4:	4785                	li	a5,1
    800059d6:	08f70463          	beq	a4,a5,80005a5e <sys_link+0xea>
  ip->nlink++;
    800059da:	04a4d783          	lhu	a5,74(s1)
    800059de:	2785                	addiw	a5,a5,1
    800059e0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059e4:	8526                	mv	a0,s1
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	274080e7          	jalr	628(ra) # 80003c5a <iupdate>
  iunlock(ip);
    800059ee:	8526                	mv	a0,s1
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	3f6080e7          	jalr	1014(ra) # 80003de6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800059f8:	fd040593          	addi	a1,s0,-48
    800059fc:	f5040513          	addi	a0,s0,-176
    80005a00:	fffff097          	auipc	ra,0xfffff
    80005a04:	af8080e7          	jalr	-1288(ra) # 800044f8 <nameiparent>
    80005a08:	892a                	mv	s2,a0
    80005a0a:	c935                	beqz	a0,80005a7e <sys_link+0x10a>
  ilock(dp);
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	318080e7          	jalr	792(ra) # 80003d24 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a14:	00092703          	lw	a4,0(s2)
    80005a18:	409c                	lw	a5,0(s1)
    80005a1a:	04f71d63          	bne	a4,a5,80005a74 <sys_link+0x100>
    80005a1e:	40d0                	lw	a2,4(s1)
    80005a20:	fd040593          	addi	a1,s0,-48
    80005a24:	854a                	mv	a0,s2
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	9f2080e7          	jalr	-1550(ra) # 80004418 <dirlink>
    80005a2e:	04054363          	bltz	a0,80005a74 <sys_link+0x100>
  iunlockput(dp);
    80005a32:	854a                	mv	a0,s2
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	552080e7          	jalr	1362(ra) # 80003f86 <iunlockput>
  iput(ip);
    80005a3c:	8526                	mv	a0,s1
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	4a0080e7          	jalr	1184(ra) # 80003ede <iput>
  end_op();
    80005a46:	fffff097          	auipc	ra,0xfffff
    80005a4a:	d30080e7          	jalr	-720(ra) # 80004776 <end_op>
  return 0;
    80005a4e:	4781                	li	a5,0
    80005a50:	a085                	j	80005ab0 <sys_link+0x13c>
    end_op();
    80005a52:	fffff097          	auipc	ra,0xfffff
    80005a56:	d24080e7          	jalr	-732(ra) # 80004776 <end_op>
    return -1;
    80005a5a:	57fd                	li	a5,-1
    80005a5c:	a891                	j	80005ab0 <sys_link+0x13c>
    iunlockput(ip);
    80005a5e:	8526                	mv	a0,s1
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	526080e7          	jalr	1318(ra) # 80003f86 <iunlockput>
    end_op();
    80005a68:	fffff097          	auipc	ra,0xfffff
    80005a6c:	d0e080e7          	jalr	-754(ra) # 80004776 <end_op>
    return -1;
    80005a70:	57fd                	li	a5,-1
    80005a72:	a83d                	j	80005ab0 <sys_link+0x13c>
    iunlockput(dp);
    80005a74:	854a                	mv	a0,s2
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	510080e7          	jalr	1296(ra) # 80003f86 <iunlockput>
  ilock(ip);
    80005a7e:	8526                	mv	a0,s1
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	2a4080e7          	jalr	676(ra) # 80003d24 <ilock>
  ip->nlink--;
    80005a88:	04a4d783          	lhu	a5,74(s1)
    80005a8c:	37fd                	addiw	a5,a5,-1
    80005a8e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a92:	8526                	mv	a0,s1
    80005a94:	ffffe097          	auipc	ra,0xffffe
    80005a98:	1c6080e7          	jalr	454(ra) # 80003c5a <iupdate>
  iunlockput(ip);
    80005a9c:	8526                	mv	a0,s1
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	4e8080e7          	jalr	1256(ra) # 80003f86 <iunlockput>
  end_op();
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	cd0080e7          	jalr	-816(ra) # 80004776 <end_op>
  return -1;
    80005aae:	57fd                	li	a5,-1
}
    80005ab0:	853e                	mv	a0,a5
    80005ab2:	70b2                	ld	ra,296(sp)
    80005ab4:	7412                	ld	s0,288(sp)
    80005ab6:	64f2                	ld	s1,280(sp)
    80005ab8:	6952                	ld	s2,272(sp)
    80005aba:	6155                	addi	sp,sp,304
    80005abc:	8082                	ret

0000000080005abe <sys_unlink>:
{
    80005abe:	7151                	addi	sp,sp,-240
    80005ac0:	f586                	sd	ra,232(sp)
    80005ac2:	f1a2                	sd	s0,224(sp)
    80005ac4:	eda6                	sd	s1,216(sp)
    80005ac6:	e9ca                	sd	s2,208(sp)
    80005ac8:	e5ce                	sd	s3,200(sp)
    80005aca:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005acc:	08000613          	li	a2,128
    80005ad0:	f3040593          	addi	a1,s0,-208
    80005ad4:	4501                	li	a0,0
    80005ad6:	ffffd097          	auipc	ra,0xffffd
    80005ada:	6d6080e7          	jalr	1750(ra) # 800031ac <argstr>
    80005ade:	18054163          	bltz	a0,80005c60 <sys_unlink+0x1a2>
  begin_op();
    80005ae2:	fffff097          	auipc	ra,0xfffff
    80005ae6:	c14080e7          	jalr	-1004(ra) # 800046f6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005aea:	fb040593          	addi	a1,s0,-80
    80005aee:	f3040513          	addi	a0,s0,-208
    80005af2:	fffff097          	auipc	ra,0xfffff
    80005af6:	a06080e7          	jalr	-1530(ra) # 800044f8 <nameiparent>
    80005afa:	84aa                	mv	s1,a0
    80005afc:	c979                	beqz	a0,80005bd2 <sys_unlink+0x114>
  ilock(dp);
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	226080e7          	jalr	550(ra) # 80003d24 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b06:	00003597          	auipc	a1,0x3
    80005b0a:	c5a58593          	addi	a1,a1,-934 # 80008760 <syscalls+0x2c0>
    80005b0e:	fb040513          	addi	a0,s0,-80
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	6dc080e7          	jalr	1756(ra) # 800041ee <namecmp>
    80005b1a:	14050a63          	beqz	a0,80005c6e <sys_unlink+0x1b0>
    80005b1e:	00003597          	auipc	a1,0x3
    80005b22:	c4a58593          	addi	a1,a1,-950 # 80008768 <syscalls+0x2c8>
    80005b26:	fb040513          	addi	a0,s0,-80
    80005b2a:	ffffe097          	auipc	ra,0xffffe
    80005b2e:	6c4080e7          	jalr	1732(ra) # 800041ee <namecmp>
    80005b32:	12050e63          	beqz	a0,80005c6e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b36:	f2c40613          	addi	a2,s0,-212
    80005b3a:	fb040593          	addi	a1,s0,-80
    80005b3e:	8526                	mv	a0,s1
    80005b40:	ffffe097          	auipc	ra,0xffffe
    80005b44:	6c8080e7          	jalr	1736(ra) # 80004208 <dirlookup>
    80005b48:	892a                	mv	s2,a0
    80005b4a:	12050263          	beqz	a0,80005c6e <sys_unlink+0x1b0>
  ilock(ip);
    80005b4e:	ffffe097          	auipc	ra,0xffffe
    80005b52:	1d6080e7          	jalr	470(ra) # 80003d24 <ilock>
  if(ip->nlink < 1)
    80005b56:	04a91783          	lh	a5,74(s2)
    80005b5a:	08f05263          	blez	a5,80005bde <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b5e:	04491703          	lh	a4,68(s2)
    80005b62:	4785                	li	a5,1
    80005b64:	08f70563          	beq	a4,a5,80005bee <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b68:	4641                	li	a2,16
    80005b6a:	4581                	li	a1,0
    80005b6c:	fc040513          	addi	a0,s0,-64
    80005b70:	ffffb097          	auipc	ra,0xffffb
    80005b74:	182080e7          	jalr	386(ra) # 80000cf2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b78:	4741                	li	a4,16
    80005b7a:	f2c42683          	lw	a3,-212(s0)
    80005b7e:	fc040613          	addi	a2,s0,-64
    80005b82:	4581                	li	a1,0
    80005b84:	8526                	mv	a0,s1
    80005b86:	ffffe097          	auipc	ra,0xffffe
    80005b8a:	54a080e7          	jalr	1354(ra) # 800040d0 <writei>
    80005b8e:	47c1                	li	a5,16
    80005b90:	0af51563          	bne	a0,a5,80005c3a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b94:	04491703          	lh	a4,68(s2)
    80005b98:	4785                	li	a5,1
    80005b9a:	0af70863          	beq	a4,a5,80005c4a <sys_unlink+0x18c>
  iunlockput(dp);
    80005b9e:	8526                	mv	a0,s1
    80005ba0:	ffffe097          	auipc	ra,0xffffe
    80005ba4:	3e6080e7          	jalr	998(ra) # 80003f86 <iunlockput>
  ip->nlink--;
    80005ba8:	04a95783          	lhu	a5,74(s2)
    80005bac:	37fd                	addiw	a5,a5,-1
    80005bae:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005bb2:	854a                	mv	a0,s2
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	0a6080e7          	jalr	166(ra) # 80003c5a <iupdate>
  iunlockput(ip);
    80005bbc:	854a                	mv	a0,s2
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	3c8080e7          	jalr	968(ra) # 80003f86 <iunlockput>
  end_op();
    80005bc6:	fffff097          	auipc	ra,0xfffff
    80005bca:	bb0080e7          	jalr	-1104(ra) # 80004776 <end_op>
  return 0;
    80005bce:	4501                	li	a0,0
    80005bd0:	a84d                	j	80005c82 <sys_unlink+0x1c4>
    end_op();
    80005bd2:	fffff097          	auipc	ra,0xfffff
    80005bd6:	ba4080e7          	jalr	-1116(ra) # 80004776 <end_op>
    return -1;
    80005bda:	557d                	li	a0,-1
    80005bdc:	a05d                	j	80005c82 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005bde:	00003517          	auipc	a0,0x3
    80005be2:	bb250513          	addi	a0,a0,-1102 # 80008790 <syscalls+0x2f0>
    80005be6:	ffffb097          	auipc	ra,0xffffb
    80005bea:	958080e7          	jalr	-1704(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bee:	04c92703          	lw	a4,76(s2)
    80005bf2:	02000793          	li	a5,32
    80005bf6:	f6e7f9e3          	bgeu	a5,a4,80005b68 <sys_unlink+0xaa>
    80005bfa:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005bfe:	4741                	li	a4,16
    80005c00:	86ce                	mv	a3,s3
    80005c02:	f1840613          	addi	a2,s0,-232
    80005c06:	4581                	li	a1,0
    80005c08:	854a                	mv	a0,s2
    80005c0a:	ffffe097          	auipc	ra,0xffffe
    80005c0e:	3ce080e7          	jalr	974(ra) # 80003fd8 <readi>
    80005c12:	47c1                	li	a5,16
    80005c14:	00f51b63          	bne	a0,a5,80005c2a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c18:	f1845783          	lhu	a5,-232(s0)
    80005c1c:	e7a1                	bnez	a5,80005c64 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c1e:	29c1                	addiw	s3,s3,16
    80005c20:	04c92783          	lw	a5,76(s2)
    80005c24:	fcf9ede3          	bltu	s3,a5,80005bfe <sys_unlink+0x140>
    80005c28:	b781                	j	80005b68 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c2a:	00003517          	auipc	a0,0x3
    80005c2e:	b7e50513          	addi	a0,a0,-1154 # 800087a8 <syscalls+0x308>
    80005c32:	ffffb097          	auipc	ra,0xffffb
    80005c36:	90c080e7          	jalr	-1780(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005c3a:	00003517          	auipc	a0,0x3
    80005c3e:	b8650513          	addi	a0,a0,-1146 # 800087c0 <syscalls+0x320>
    80005c42:	ffffb097          	auipc	ra,0xffffb
    80005c46:	8fc080e7          	jalr	-1796(ra) # 8000053e <panic>
    dp->nlink--;
    80005c4a:	04a4d783          	lhu	a5,74(s1)
    80005c4e:	37fd                	addiw	a5,a5,-1
    80005c50:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c54:	8526                	mv	a0,s1
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	004080e7          	jalr	4(ra) # 80003c5a <iupdate>
    80005c5e:	b781                	j	80005b9e <sys_unlink+0xe0>
    return -1;
    80005c60:	557d                	li	a0,-1
    80005c62:	a005                	j	80005c82 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c64:	854a                	mv	a0,s2
    80005c66:	ffffe097          	auipc	ra,0xffffe
    80005c6a:	320080e7          	jalr	800(ra) # 80003f86 <iunlockput>
  iunlockput(dp);
    80005c6e:	8526                	mv	a0,s1
    80005c70:	ffffe097          	auipc	ra,0xffffe
    80005c74:	316080e7          	jalr	790(ra) # 80003f86 <iunlockput>
  end_op();
    80005c78:	fffff097          	auipc	ra,0xfffff
    80005c7c:	afe080e7          	jalr	-1282(ra) # 80004776 <end_op>
  return -1;
    80005c80:	557d                	li	a0,-1
}
    80005c82:	70ae                	ld	ra,232(sp)
    80005c84:	740e                	ld	s0,224(sp)
    80005c86:	64ee                	ld	s1,216(sp)
    80005c88:	694e                	ld	s2,208(sp)
    80005c8a:	69ae                	ld	s3,200(sp)
    80005c8c:	616d                	addi	sp,sp,240
    80005c8e:	8082                	ret

0000000080005c90 <sys_open>:

uint64
sys_open(void)
{
    80005c90:	7131                	addi	sp,sp,-192
    80005c92:	fd06                	sd	ra,184(sp)
    80005c94:	f922                	sd	s0,176(sp)
    80005c96:	f526                	sd	s1,168(sp)
    80005c98:	f14a                	sd	s2,160(sp)
    80005c9a:	ed4e                	sd	s3,152(sp)
    80005c9c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c9e:	08000613          	li	a2,128
    80005ca2:	f5040593          	addi	a1,s0,-176
    80005ca6:	4501                	li	a0,0
    80005ca8:	ffffd097          	auipc	ra,0xffffd
    80005cac:	504080e7          	jalr	1284(ra) # 800031ac <argstr>
    return -1;
    80005cb0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005cb2:	0c054163          	bltz	a0,80005d74 <sys_open+0xe4>
    80005cb6:	f4c40593          	addi	a1,s0,-180
    80005cba:	4505                	li	a0,1
    80005cbc:	ffffd097          	auipc	ra,0xffffd
    80005cc0:	4ac080e7          	jalr	1196(ra) # 80003168 <argint>
    80005cc4:	0a054863          	bltz	a0,80005d74 <sys_open+0xe4>

  begin_op();
    80005cc8:	fffff097          	auipc	ra,0xfffff
    80005ccc:	a2e080e7          	jalr	-1490(ra) # 800046f6 <begin_op>

  if(omode & O_CREATE){
    80005cd0:	f4c42783          	lw	a5,-180(s0)
    80005cd4:	2007f793          	andi	a5,a5,512
    80005cd8:	cbdd                	beqz	a5,80005d8e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005cda:	4681                	li	a3,0
    80005cdc:	4601                	li	a2,0
    80005cde:	4589                	li	a1,2
    80005ce0:	f5040513          	addi	a0,s0,-176
    80005ce4:	00000097          	auipc	ra,0x0
    80005ce8:	972080e7          	jalr	-1678(ra) # 80005656 <create>
    80005cec:	892a                	mv	s2,a0
    if(ip == 0){
    80005cee:	c959                	beqz	a0,80005d84 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005cf0:	04491703          	lh	a4,68(s2)
    80005cf4:	478d                	li	a5,3
    80005cf6:	00f71763          	bne	a4,a5,80005d04 <sys_open+0x74>
    80005cfa:	04695703          	lhu	a4,70(s2)
    80005cfe:	47a5                	li	a5,9
    80005d00:	0ce7ec63          	bltu	a5,a4,80005dd8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	e02080e7          	jalr	-510(ra) # 80004b06 <filealloc>
    80005d0c:	89aa                	mv	s3,a0
    80005d0e:	10050263          	beqz	a0,80005e12 <sys_open+0x182>
    80005d12:	00000097          	auipc	ra,0x0
    80005d16:	902080e7          	jalr	-1790(ra) # 80005614 <fdalloc>
    80005d1a:	84aa                	mv	s1,a0
    80005d1c:	0e054663          	bltz	a0,80005e08 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d20:	04491703          	lh	a4,68(s2)
    80005d24:	478d                	li	a5,3
    80005d26:	0cf70463          	beq	a4,a5,80005dee <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d2a:	4789                	li	a5,2
    80005d2c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d30:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d34:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d38:	f4c42783          	lw	a5,-180(s0)
    80005d3c:	0017c713          	xori	a4,a5,1
    80005d40:	8b05                	andi	a4,a4,1
    80005d42:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d46:	0037f713          	andi	a4,a5,3
    80005d4a:	00e03733          	snez	a4,a4
    80005d4e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d52:	4007f793          	andi	a5,a5,1024
    80005d56:	c791                	beqz	a5,80005d62 <sys_open+0xd2>
    80005d58:	04491703          	lh	a4,68(s2)
    80005d5c:	4789                	li	a5,2
    80005d5e:	08f70f63          	beq	a4,a5,80005dfc <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d62:	854a                	mv	a0,s2
    80005d64:	ffffe097          	auipc	ra,0xffffe
    80005d68:	082080e7          	jalr	130(ra) # 80003de6 <iunlock>
  end_op();
    80005d6c:	fffff097          	auipc	ra,0xfffff
    80005d70:	a0a080e7          	jalr	-1526(ra) # 80004776 <end_op>

  return fd;
}
    80005d74:	8526                	mv	a0,s1
    80005d76:	70ea                	ld	ra,184(sp)
    80005d78:	744a                	ld	s0,176(sp)
    80005d7a:	74aa                	ld	s1,168(sp)
    80005d7c:	790a                	ld	s2,160(sp)
    80005d7e:	69ea                	ld	s3,152(sp)
    80005d80:	6129                	addi	sp,sp,192
    80005d82:	8082                	ret
      end_op();
    80005d84:	fffff097          	auipc	ra,0xfffff
    80005d88:	9f2080e7          	jalr	-1550(ra) # 80004776 <end_op>
      return -1;
    80005d8c:	b7e5                	j	80005d74 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d8e:	f5040513          	addi	a0,s0,-176
    80005d92:	ffffe097          	auipc	ra,0xffffe
    80005d96:	748080e7          	jalr	1864(ra) # 800044da <namei>
    80005d9a:	892a                	mv	s2,a0
    80005d9c:	c905                	beqz	a0,80005dcc <sys_open+0x13c>
    ilock(ip);
    80005d9e:	ffffe097          	auipc	ra,0xffffe
    80005da2:	f86080e7          	jalr	-122(ra) # 80003d24 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005da6:	04491703          	lh	a4,68(s2)
    80005daa:	4785                	li	a5,1
    80005dac:	f4f712e3          	bne	a4,a5,80005cf0 <sys_open+0x60>
    80005db0:	f4c42783          	lw	a5,-180(s0)
    80005db4:	dba1                	beqz	a5,80005d04 <sys_open+0x74>
      iunlockput(ip);
    80005db6:	854a                	mv	a0,s2
    80005db8:	ffffe097          	auipc	ra,0xffffe
    80005dbc:	1ce080e7          	jalr	462(ra) # 80003f86 <iunlockput>
      end_op();
    80005dc0:	fffff097          	auipc	ra,0xfffff
    80005dc4:	9b6080e7          	jalr	-1610(ra) # 80004776 <end_op>
      return -1;
    80005dc8:	54fd                	li	s1,-1
    80005dca:	b76d                	j	80005d74 <sys_open+0xe4>
      end_op();
    80005dcc:	fffff097          	auipc	ra,0xfffff
    80005dd0:	9aa080e7          	jalr	-1622(ra) # 80004776 <end_op>
      return -1;
    80005dd4:	54fd                	li	s1,-1
    80005dd6:	bf79                	j	80005d74 <sys_open+0xe4>
    iunlockput(ip);
    80005dd8:	854a                	mv	a0,s2
    80005dda:	ffffe097          	auipc	ra,0xffffe
    80005dde:	1ac080e7          	jalr	428(ra) # 80003f86 <iunlockput>
    end_op();
    80005de2:	fffff097          	auipc	ra,0xfffff
    80005de6:	994080e7          	jalr	-1644(ra) # 80004776 <end_op>
    return -1;
    80005dea:	54fd                	li	s1,-1
    80005dec:	b761                	j	80005d74 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005dee:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005df2:	04691783          	lh	a5,70(s2)
    80005df6:	02f99223          	sh	a5,36(s3)
    80005dfa:	bf2d                	j	80005d34 <sys_open+0xa4>
    itrunc(ip);
    80005dfc:	854a                	mv	a0,s2
    80005dfe:	ffffe097          	auipc	ra,0xffffe
    80005e02:	034080e7          	jalr	52(ra) # 80003e32 <itrunc>
    80005e06:	bfb1                	j	80005d62 <sys_open+0xd2>
      fileclose(f);
    80005e08:	854e                	mv	a0,s3
    80005e0a:	fffff097          	auipc	ra,0xfffff
    80005e0e:	db8080e7          	jalr	-584(ra) # 80004bc2 <fileclose>
    iunlockput(ip);
    80005e12:	854a                	mv	a0,s2
    80005e14:	ffffe097          	auipc	ra,0xffffe
    80005e18:	172080e7          	jalr	370(ra) # 80003f86 <iunlockput>
    end_op();
    80005e1c:	fffff097          	auipc	ra,0xfffff
    80005e20:	95a080e7          	jalr	-1702(ra) # 80004776 <end_op>
    return -1;
    80005e24:	54fd                	li	s1,-1
    80005e26:	b7b9                	j	80005d74 <sys_open+0xe4>

0000000080005e28 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e28:	7175                	addi	sp,sp,-144
    80005e2a:	e506                	sd	ra,136(sp)
    80005e2c:	e122                	sd	s0,128(sp)
    80005e2e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e30:	fffff097          	auipc	ra,0xfffff
    80005e34:	8c6080e7          	jalr	-1850(ra) # 800046f6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e38:	08000613          	li	a2,128
    80005e3c:	f7040593          	addi	a1,s0,-144
    80005e40:	4501                	li	a0,0
    80005e42:	ffffd097          	auipc	ra,0xffffd
    80005e46:	36a080e7          	jalr	874(ra) # 800031ac <argstr>
    80005e4a:	02054963          	bltz	a0,80005e7c <sys_mkdir+0x54>
    80005e4e:	4681                	li	a3,0
    80005e50:	4601                	li	a2,0
    80005e52:	4585                	li	a1,1
    80005e54:	f7040513          	addi	a0,s0,-144
    80005e58:	fffff097          	auipc	ra,0xfffff
    80005e5c:	7fe080e7          	jalr	2046(ra) # 80005656 <create>
    80005e60:	cd11                	beqz	a0,80005e7c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e62:	ffffe097          	auipc	ra,0xffffe
    80005e66:	124080e7          	jalr	292(ra) # 80003f86 <iunlockput>
  end_op();
    80005e6a:	fffff097          	auipc	ra,0xfffff
    80005e6e:	90c080e7          	jalr	-1780(ra) # 80004776 <end_op>
  return 0;
    80005e72:	4501                	li	a0,0
}
    80005e74:	60aa                	ld	ra,136(sp)
    80005e76:	640a                	ld	s0,128(sp)
    80005e78:	6149                	addi	sp,sp,144
    80005e7a:	8082                	ret
    end_op();
    80005e7c:	fffff097          	auipc	ra,0xfffff
    80005e80:	8fa080e7          	jalr	-1798(ra) # 80004776 <end_op>
    return -1;
    80005e84:	557d                	li	a0,-1
    80005e86:	b7fd                	j	80005e74 <sys_mkdir+0x4c>

0000000080005e88 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e88:	7135                	addi	sp,sp,-160
    80005e8a:	ed06                	sd	ra,152(sp)
    80005e8c:	e922                	sd	s0,144(sp)
    80005e8e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e90:	fffff097          	auipc	ra,0xfffff
    80005e94:	866080e7          	jalr	-1946(ra) # 800046f6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e98:	08000613          	li	a2,128
    80005e9c:	f7040593          	addi	a1,s0,-144
    80005ea0:	4501                	li	a0,0
    80005ea2:	ffffd097          	auipc	ra,0xffffd
    80005ea6:	30a080e7          	jalr	778(ra) # 800031ac <argstr>
    80005eaa:	04054a63          	bltz	a0,80005efe <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005eae:	f6c40593          	addi	a1,s0,-148
    80005eb2:	4505                	li	a0,1
    80005eb4:	ffffd097          	auipc	ra,0xffffd
    80005eb8:	2b4080e7          	jalr	692(ra) # 80003168 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ebc:	04054163          	bltz	a0,80005efe <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ec0:	f6840593          	addi	a1,s0,-152
    80005ec4:	4509                	li	a0,2
    80005ec6:	ffffd097          	auipc	ra,0xffffd
    80005eca:	2a2080e7          	jalr	674(ra) # 80003168 <argint>
     argint(1, &major) < 0 ||
    80005ece:	02054863          	bltz	a0,80005efe <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ed2:	f6841683          	lh	a3,-152(s0)
    80005ed6:	f6c41603          	lh	a2,-148(s0)
    80005eda:	458d                	li	a1,3
    80005edc:	f7040513          	addi	a0,s0,-144
    80005ee0:	fffff097          	auipc	ra,0xfffff
    80005ee4:	776080e7          	jalr	1910(ra) # 80005656 <create>
     argint(2, &minor) < 0 ||
    80005ee8:	c919                	beqz	a0,80005efe <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005eea:	ffffe097          	auipc	ra,0xffffe
    80005eee:	09c080e7          	jalr	156(ra) # 80003f86 <iunlockput>
  end_op();
    80005ef2:	fffff097          	auipc	ra,0xfffff
    80005ef6:	884080e7          	jalr	-1916(ra) # 80004776 <end_op>
  return 0;
    80005efa:	4501                	li	a0,0
    80005efc:	a031                	j	80005f08 <sys_mknod+0x80>
    end_op();
    80005efe:	fffff097          	auipc	ra,0xfffff
    80005f02:	878080e7          	jalr	-1928(ra) # 80004776 <end_op>
    return -1;
    80005f06:	557d                	li	a0,-1
}
    80005f08:	60ea                	ld	ra,152(sp)
    80005f0a:	644a                	ld	s0,144(sp)
    80005f0c:	610d                	addi	sp,sp,160
    80005f0e:	8082                	ret

0000000080005f10 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f10:	7135                	addi	sp,sp,-160
    80005f12:	ed06                	sd	ra,152(sp)
    80005f14:	e922                	sd	s0,144(sp)
    80005f16:	e526                	sd	s1,136(sp)
    80005f18:	e14a                	sd	s2,128(sp)
    80005f1a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f1c:	ffffc097          	auipc	ra,0xffffc
    80005f20:	e26080e7          	jalr	-474(ra) # 80001d42 <myproc>
    80005f24:	892a                	mv	s2,a0
  
  begin_op();
    80005f26:	ffffe097          	auipc	ra,0xffffe
    80005f2a:	7d0080e7          	jalr	2000(ra) # 800046f6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f2e:	08000613          	li	a2,128
    80005f32:	f6040593          	addi	a1,s0,-160
    80005f36:	4501                	li	a0,0
    80005f38:	ffffd097          	auipc	ra,0xffffd
    80005f3c:	274080e7          	jalr	628(ra) # 800031ac <argstr>
    80005f40:	04054b63          	bltz	a0,80005f96 <sys_chdir+0x86>
    80005f44:	f6040513          	addi	a0,s0,-160
    80005f48:	ffffe097          	auipc	ra,0xffffe
    80005f4c:	592080e7          	jalr	1426(ra) # 800044da <namei>
    80005f50:	84aa                	mv	s1,a0
    80005f52:	c131                	beqz	a0,80005f96 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f54:	ffffe097          	auipc	ra,0xffffe
    80005f58:	dd0080e7          	jalr	-560(ra) # 80003d24 <ilock>
  if(ip->type != T_DIR){
    80005f5c:	04449703          	lh	a4,68(s1)
    80005f60:	4785                	li	a5,1
    80005f62:	04f71063          	bne	a4,a5,80005fa2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f66:	8526                	mv	a0,s1
    80005f68:	ffffe097          	auipc	ra,0xffffe
    80005f6c:	e7e080e7          	jalr	-386(ra) # 80003de6 <iunlock>
  iput(p->cwd);
    80005f70:	17093503          	ld	a0,368(s2)
    80005f74:	ffffe097          	auipc	ra,0xffffe
    80005f78:	f6a080e7          	jalr	-150(ra) # 80003ede <iput>
  end_op();
    80005f7c:	ffffe097          	auipc	ra,0xffffe
    80005f80:	7fa080e7          	jalr	2042(ra) # 80004776 <end_op>
  p->cwd = ip;
    80005f84:	16993823          	sd	s1,368(s2)
  return 0;
    80005f88:	4501                	li	a0,0
}
    80005f8a:	60ea                	ld	ra,152(sp)
    80005f8c:	644a                	ld	s0,144(sp)
    80005f8e:	64aa                	ld	s1,136(sp)
    80005f90:	690a                	ld	s2,128(sp)
    80005f92:	610d                	addi	sp,sp,160
    80005f94:	8082                	ret
    end_op();
    80005f96:	ffffe097          	auipc	ra,0xffffe
    80005f9a:	7e0080e7          	jalr	2016(ra) # 80004776 <end_op>
    return -1;
    80005f9e:	557d                	li	a0,-1
    80005fa0:	b7ed                	j	80005f8a <sys_chdir+0x7a>
    iunlockput(ip);
    80005fa2:	8526                	mv	a0,s1
    80005fa4:	ffffe097          	auipc	ra,0xffffe
    80005fa8:	fe2080e7          	jalr	-30(ra) # 80003f86 <iunlockput>
    end_op();
    80005fac:	ffffe097          	auipc	ra,0xffffe
    80005fb0:	7ca080e7          	jalr	1994(ra) # 80004776 <end_op>
    return -1;
    80005fb4:	557d                	li	a0,-1
    80005fb6:	bfd1                	j	80005f8a <sys_chdir+0x7a>

0000000080005fb8 <sys_exec>:

uint64
sys_exec(void)
{
    80005fb8:	7145                	addi	sp,sp,-464
    80005fba:	e786                	sd	ra,456(sp)
    80005fbc:	e3a2                	sd	s0,448(sp)
    80005fbe:	ff26                	sd	s1,440(sp)
    80005fc0:	fb4a                	sd	s2,432(sp)
    80005fc2:	f74e                	sd	s3,424(sp)
    80005fc4:	f352                	sd	s4,416(sp)
    80005fc6:	ef56                	sd	s5,408(sp)
    80005fc8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fca:	08000613          	li	a2,128
    80005fce:	f4040593          	addi	a1,s0,-192
    80005fd2:	4501                	li	a0,0
    80005fd4:	ffffd097          	auipc	ra,0xffffd
    80005fd8:	1d8080e7          	jalr	472(ra) # 800031ac <argstr>
    return -1;
    80005fdc:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fde:	0c054a63          	bltz	a0,800060b2 <sys_exec+0xfa>
    80005fe2:	e3840593          	addi	a1,s0,-456
    80005fe6:	4505                	li	a0,1
    80005fe8:	ffffd097          	auipc	ra,0xffffd
    80005fec:	1a2080e7          	jalr	418(ra) # 8000318a <argaddr>
    80005ff0:	0c054163          	bltz	a0,800060b2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ff4:	10000613          	li	a2,256
    80005ff8:	4581                	li	a1,0
    80005ffa:	e4040513          	addi	a0,s0,-448
    80005ffe:	ffffb097          	auipc	ra,0xffffb
    80006002:	cf4080e7          	jalr	-780(ra) # 80000cf2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006006:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000600a:	89a6                	mv	s3,s1
    8000600c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000600e:	02000a13          	li	s4,32
    80006012:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006016:	00391513          	slli	a0,s2,0x3
    8000601a:	e3040593          	addi	a1,s0,-464
    8000601e:	e3843783          	ld	a5,-456(s0)
    80006022:	953e                	add	a0,a0,a5
    80006024:	ffffd097          	auipc	ra,0xffffd
    80006028:	0aa080e7          	jalr	170(ra) # 800030ce <fetchaddr>
    8000602c:	02054a63          	bltz	a0,80006060 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006030:	e3043783          	ld	a5,-464(s0)
    80006034:	c3b9                	beqz	a5,8000607a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006036:	ffffb097          	auipc	ra,0xffffb
    8000603a:	abe080e7          	jalr	-1346(ra) # 80000af4 <kalloc>
    8000603e:	85aa                	mv	a1,a0
    80006040:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006044:	cd11                	beqz	a0,80006060 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006046:	6605                	lui	a2,0x1
    80006048:	e3043503          	ld	a0,-464(s0)
    8000604c:	ffffd097          	auipc	ra,0xffffd
    80006050:	0d4080e7          	jalr	212(ra) # 80003120 <fetchstr>
    80006054:	00054663          	bltz	a0,80006060 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006058:	0905                	addi	s2,s2,1
    8000605a:	09a1                	addi	s3,s3,8
    8000605c:	fb491be3          	bne	s2,s4,80006012 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006060:	10048913          	addi	s2,s1,256
    80006064:	6088                	ld	a0,0(s1)
    80006066:	c529                	beqz	a0,800060b0 <sys_exec+0xf8>
    kfree(argv[i]);
    80006068:	ffffb097          	auipc	ra,0xffffb
    8000606c:	990080e7          	jalr	-1648(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006070:	04a1                	addi	s1,s1,8
    80006072:	ff2499e3          	bne	s1,s2,80006064 <sys_exec+0xac>
  return -1;
    80006076:	597d                	li	s2,-1
    80006078:	a82d                	j	800060b2 <sys_exec+0xfa>
      argv[i] = 0;
    8000607a:	0a8e                	slli	s5,s5,0x3
    8000607c:	fc040793          	addi	a5,s0,-64
    80006080:	9abe                	add	s5,s5,a5
    80006082:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006086:	e4040593          	addi	a1,s0,-448
    8000608a:	f4040513          	addi	a0,s0,-192
    8000608e:	fffff097          	auipc	ra,0xfffff
    80006092:	194080e7          	jalr	404(ra) # 80005222 <exec>
    80006096:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006098:	10048993          	addi	s3,s1,256
    8000609c:	6088                	ld	a0,0(s1)
    8000609e:	c911                	beqz	a0,800060b2 <sys_exec+0xfa>
    kfree(argv[i]);
    800060a0:	ffffb097          	auipc	ra,0xffffb
    800060a4:	958080e7          	jalr	-1704(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060a8:	04a1                	addi	s1,s1,8
    800060aa:	ff3499e3          	bne	s1,s3,8000609c <sys_exec+0xe4>
    800060ae:	a011                	j	800060b2 <sys_exec+0xfa>
  return -1;
    800060b0:	597d                	li	s2,-1
}
    800060b2:	854a                	mv	a0,s2
    800060b4:	60be                	ld	ra,456(sp)
    800060b6:	641e                	ld	s0,448(sp)
    800060b8:	74fa                	ld	s1,440(sp)
    800060ba:	795a                	ld	s2,432(sp)
    800060bc:	79ba                	ld	s3,424(sp)
    800060be:	7a1a                	ld	s4,416(sp)
    800060c0:	6afa                	ld	s5,408(sp)
    800060c2:	6179                	addi	sp,sp,464
    800060c4:	8082                	ret

00000000800060c6 <sys_pipe>:

uint64
sys_pipe(void)
{
    800060c6:	7139                	addi	sp,sp,-64
    800060c8:	fc06                	sd	ra,56(sp)
    800060ca:	f822                	sd	s0,48(sp)
    800060cc:	f426                	sd	s1,40(sp)
    800060ce:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800060d0:	ffffc097          	auipc	ra,0xffffc
    800060d4:	c72080e7          	jalr	-910(ra) # 80001d42 <myproc>
    800060d8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800060da:	fd840593          	addi	a1,s0,-40
    800060de:	4501                	li	a0,0
    800060e0:	ffffd097          	auipc	ra,0xffffd
    800060e4:	0aa080e7          	jalr	170(ra) # 8000318a <argaddr>
    return -1;
    800060e8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800060ea:	0e054063          	bltz	a0,800061ca <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800060ee:	fc840593          	addi	a1,s0,-56
    800060f2:	fd040513          	addi	a0,s0,-48
    800060f6:	fffff097          	auipc	ra,0xfffff
    800060fa:	dfc080e7          	jalr	-516(ra) # 80004ef2 <pipealloc>
    return -1;
    800060fe:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006100:	0c054563          	bltz	a0,800061ca <sys_pipe+0x104>
  fd0 = -1;
    80006104:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006108:	fd043503          	ld	a0,-48(s0)
    8000610c:	fffff097          	auipc	ra,0xfffff
    80006110:	508080e7          	jalr	1288(ra) # 80005614 <fdalloc>
    80006114:	fca42223          	sw	a0,-60(s0)
    80006118:	08054c63          	bltz	a0,800061b0 <sys_pipe+0xea>
    8000611c:	fc843503          	ld	a0,-56(s0)
    80006120:	fffff097          	auipc	ra,0xfffff
    80006124:	4f4080e7          	jalr	1268(ra) # 80005614 <fdalloc>
    80006128:	fca42023          	sw	a0,-64(s0)
    8000612c:	06054863          	bltz	a0,8000619c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006130:	4691                	li	a3,4
    80006132:	fc440613          	addi	a2,s0,-60
    80006136:	fd843583          	ld	a1,-40(s0)
    8000613a:	78a8                	ld	a0,112(s1)
    8000613c:	ffffb097          	auipc	ra,0xffffb
    80006140:	548080e7          	jalr	1352(ra) # 80001684 <copyout>
    80006144:	02054063          	bltz	a0,80006164 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006148:	4691                	li	a3,4
    8000614a:	fc040613          	addi	a2,s0,-64
    8000614e:	fd843583          	ld	a1,-40(s0)
    80006152:	0591                	addi	a1,a1,4
    80006154:	78a8                	ld	a0,112(s1)
    80006156:	ffffb097          	auipc	ra,0xffffb
    8000615a:	52e080e7          	jalr	1326(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000615e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006160:	06055563          	bgez	a0,800061ca <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006164:	fc442783          	lw	a5,-60(s0)
    80006168:	07f9                	addi	a5,a5,30
    8000616a:	078e                	slli	a5,a5,0x3
    8000616c:	97a6                	add	a5,a5,s1
    8000616e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006172:	fc042503          	lw	a0,-64(s0)
    80006176:	0579                	addi	a0,a0,30
    80006178:	050e                	slli	a0,a0,0x3
    8000617a:	9526                	add	a0,a0,s1
    8000617c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006180:	fd043503          	ld	a0,-48(s0)
    80006184:	fffff097          	auipc	ra,0xfffff
    80006188:	a3e080e7          	jalr	-1474(ra) # 80004bc2 <fileclose>
    fileclose(wf);
    8000618c:	fc843503          	ld	a0,-56(s0)
    80006190:	fffff097          	auipc	ra,0xfffff
    80006194:	a32080e7          	jalr	-1486(ra) # 80004bc2 <fileclose>
    return -1;
    80006198:	57fd                	li	a5,-1
    8000619a:	a805                	j	800061ca <sys_pipe+0x104>
    if(fd0 >= 0)
    8000619c:	fc442783          	lw	a5,-60(s0)
    800061a0:	0007c863          	bltz	a5,800061b0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800061a4:	01e78513          	addi	a0,a5,30
    800061a8:	050e                	slli	a0,a0,0x3
    800061aa:	9526                	add	a0,a0,s1
    800061ac:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800061b0:	fd043503          	ld	a0,-48(s0)
    800061b4:	fffff097          	auipc	ra,0xfffff
    800061b8:	a0e080e7          	jalr	-1522(ra) # 80004bc2 <fileclose>
    fileclose(wf);
    800061bc:	fc843503          	ld	a0,-56(s0)
    800061c0:	fffff097          	auipc	ra,0xfffff
    800061c4:	a02080e7          	jalr	-1534(ra) # 80004bc2 <fileclose>
    return -1;
    800061c8:	57fd                	li	a5,-1
}
    800061ca:	853e                	mv	a0,a5
    800061cc:	70e2                	ld	ra,56(sp)
    800061ce:	7442                	ld	s0,48(sp)
    800061d0:	74a2                	ld	s1,40(sp)
    800061d2:	6121                	addi	sp,sp,64
    800061d4:	8082                	ret
	...

00000000800061e0 <kernelvec>:
    800061e0:	7111                	addi	sp,sp,-256
    800061e2:	e006                	sd	ra,0(sp)
    800061e4:	e40a                	sd	sp,8(sp)
    800061e6:	e80e                	sd	gp,16(sp)
    800061e8:	ec12                	sd	tp,24(sp)
    800061ea:	f016                	sd	t0,32(sp)
    800061ec:	f41a                	sd	t1,40(sp)
    800061ee:	f81e                	sd	t2,48(sp)
    800061f0:	fc22                	sd	s0,56(sp)
    800061f2:	e0a6                	sd	s1,64(sp)
    800061f4:	e4aa                	sd	a0,72(sp)
    800061f6:	e8ae                	sd	a1,80(sp)
    800061f8:	ecb2                	sd	a2,88(sp)
    800061fa:	f0b6                	sd	a3,96(sp)
    800061fc:	f4ba                	sd	a4,104(sp)
    800061fe:	f8be                	sd	a5,112(sp)
    80006200:	fcc2                	sd	a6,120(sp)
    80006202:	e146                	sd	a7,128(sp)
    80006204:	e54a                	sd	s2,136(sp)
    80006206:	e94e                	sd	s3,144(sp)
    80006208:	ed52                	sd	s4,152(sp)
    8000620a:	f156                	sd	s5,160(sp)
    8000620c:	f55a                	sd	s6,168(sp)
    8000620e:	f95e                	sd	s7,176(sp)
    80006210:	fd62                	sd	s8,184(sp)
    80006212:	e1e6                	sd	s9,192(sp)
    80006214:	e5ea                	sd	s10,200(sp)
    80006216:	e9ee                	sd	s11,208(sp)
    80006218:	edf2                	sd	t3,216(sp)
    8000621a:	f1f6                	sd	t4,224(sp)
    8000621c:	f5fa                	sd	t5,232(sp)
    8000621e:	f9fe                	sd	t6,240(sp)
    80006220:	d7bfc0ef          	jal	ra,80002f9a <kerneltrap>
    80006224:	6082                	ld	ra,0(sp)
    80006226:	6122                	ld	sp,8(sp)
    80006228:	61c2                	ld	gp,16(sp)
    8000622a:	7282                	ld	t0,32(sp)
    8000622c:	7322                	ld	t1,40(sp)
    8000622e:	73c2                	ld	t2,48(sp)
    80006230:	7462                	ld	s0,56(sp)
    80006232:	6486                	ld	s1,64(sp)
    80006234:	6526                	ld	a0,72(sp)
    80006236:	65c6                	ld	a1,80(sp)
    80006238:	6666                	ld	a2,88(sp)
    8000623a:	7686                	ld	a3,96(sp)
    8000623c:	7726                	ld	a4,104(sp)
    8000623e:	77c6                	ld	a5,112(sp)
    80006240:	7866                	ld	a6,120(sp)
    80006242:	688a                	ld	a7,128(sp)
    80006244:	692a                	ld	s2,136(sp)
    80006246:	69ca                	ld	s3,144(sp)
    80006248:	6a6a                	ld	s4,152(sp)
    8000624a:	7a8a                	ld	s5,160(sp)
    8000624c:	7b2a                	ld	s6,168(sp)
    8000624e:	7bca                	ld	s7,176(sp)
    80006250:	7c6a                	ld	s8,184(sp)
    80006252:	6c8e                	ld	s9,192(sp)
    80006254:	6d2e                	ld	s10,200(sp)
    80006256:	6dce                	ld	s11,208(sp)
    80006258:	6e6e                	ld	t3,216(sp)
    8000625a:	7e8e                	ld	t4,224(sp)
    8000625c:	7f2e                	ld	t5,232(sp)
    8000625e:	7fce                	ld	t6,240(sp)
    80006260:	6111                	addi	sp,sp,256
    80006262:	10200073          	sret
    80006266:	00000013          	nop
    8000626a:	00000013          	nop
    8000626e:	0001                	nop

0000000080006270 <timervec>:
    80006270:	34051573          	csrrw	a0,mscratch,a0
    80006274:	e10c                	sd	a1,0(a0)
    80006276:	e510                	sd	a2,8(a0)
    80006278:	e914                	sd	a3,16(a0)
    8000627a:	6d0c                	ld	a1,24(a0)
    8000627c:	7110                	ld	a2,32(a0)
    8000627e:	6194                	ld	a3,0(a1)
    80006280:	96b2                	add	a3,a3,a2
    80006282:	e194                	sd	a3,0(a1)
    80006284:	4589                	li	a1,2
    80006286:	14459073          	csrw	sip,a1
    8000628a:	6914                	ld	a3,16(a0)
    8000628c:	6510                	ld	a2,8(a0)
    8000628e:	610c                	ld	a1,0(a0)
    80006290:	34051573          	csrrw	a0,mscratch,a0
    80006294:	30200073          	mret
	...

000000008000629a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000629a:	1141                	addi	sp,sp,-16
    8000629c:	e422                	sd	s0,8(sp)
    8000629e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800062a0:	0c0007b7          	lui	a5,0xc000
    800062a4:	4705                	li	a4,1
    800062a6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800062a8:	c3d8                	sw	a4,4(a5)
}
    800062aa:	6422                	ld	s0,8(sp)
    800062ac:	0141                	addi	sp,sp,16
    800062ae:	8082                	ret

00000000800062b0 <plicinithart>:

void
plicinithart(void)
{
    800062b0:	1141                	addi	sp,sp,-16
    800062b2:	e406                	sd	ra,8(sp)
    800062b4:	e022                	sd	s0,0(sp)
    800062b6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062b8:	ffffc097          	auipc	ra,0xffffc
    800062bc:	a56080e7          	jalr	-1450(ra) # 80001d0e <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062c0:	0085171b          	slliw	a4,a0,0x8
    800062c4:	0c0027b7          	lui	a5,0xc002
    800062c8:	97ba                	add	a5,a5,a4
    800062ca:	40200713          	li	a4,1026
    800062ce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062d2:	00d5151b          	slliw	a0,a0,0xd
    800062d6:	0c2017b7          	lui	a5,0xc201
    800062da:	953e                	add	a0,a0,a5
    800062dc:	00052023          	sw	zero,0(a0)
}
    800062e0:	60a2                	ld	ra,8(sp)
    800062e2:	6402                	ld	s0,0(sp)
    800062e4:	0141                	addi	sp,sp,16
    800062e6:	8082                	ret

00000000800062e8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800062e8:	1141                	addi	sp,sp,-16
    800062ea:	e406                	sd	ra,8(sp)
    800062ec:	e022                	sd	s0,0(sp)
    800062ee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062f0:	ffffc097          	auipc	ra,0xffffc
    800062f4:	a1e080e7          	jalr	-1506(ra) # 80001d0e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800062f8:	00d5179b          	slliw	a5,a0,0xd
    800062fc:	0c201537          	lui	a0,0xc201
    80006300:	953e                	add	a0,a0,a5
  return irq;
}
    80006302:	4148                	lw	a0,4(a0)
    80006304:	60a2                	ld	ra,8(sp)
    80006306:	6402                	ld	s0,0(sp)
    80006308:	0141                	addi	sp,sp,16
    8000630a:	8082                	ret

000000008000630c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000630c:	1101                	addi	sp,sp,-32
    8000630e:	ec06                	sd	ra,24(sp)
    80006310:	e822                	sd	s0,16(sp)
    80006312:	e426                	sd	s1,8(sp)
    80006314:	1000                	addi	s0,sp,32
    80006316:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006318:	ffffc097          	auipc	ra,0xffffc
    8000631c:	9f6080e7          	jalr	-1546(ra) # 80001d0e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006320:	00d5151b          	slliw	a0,a0,0xd
    80006324:	0c2017b7          	lui	a5,0xc201
    80006328:	97aa                	add	a5,a5,a0
    8000632a:	c3c4                	sw	s1,4(a5)
}
    8000632c:	60e2                	ld	ra,24(sp)
    8000632e:	6442                	ld	s0,16(sp)
    80006330:	64a2                	ld	s1,8(sp)
    80006332:	6105                	addi	sp,sp,32
    80006334:	8082                	ret

0000000080006336 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006336:	1141                	addi	sp,sp,-16
    80006338:	e406                	sd	ra,8(sp)
    8000633a:	e022                	sd	s0,0(sp)
    8000633c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000633e:	479d                	li	a5,7
    80006340:	06a7c963          	blt	a5,a0,800063b2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006344:	0001d797          	auipc	a5,0x1d
    80006348:	cbc78793          	addi	a5,a5,-836 # 80023000 <disk>
    8000634c:	00a78733          	add	a4,a5,a0
    80006350:	6789                	lui	a5,0x2
    80006352:	97ba                	add	a5,a5,a4
    80006354:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006358:	e7ad                	bnez	a5,800063c2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000635a:	00451793          	slli	a5,a0,0x4
    8000635e:	0001f717          	auipc	a4,0x1f
    80006362:	ca270713          	addi	a4,a4,-862 # 80025000 <disk+0x2000>
    80006366:	6314                	ld	a3,0(a4)
    80006368:	96be                	add	a3,a3,a5
    8000636a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000636e:	6314                	ld	a3,0(a4)
    80006370:	96be                	add	a3,a3,a5
    80006372:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006376:	6314                	ld	a3,0(a4)
    80006378:	96be                	add	a3,a3,a5
    8000637a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000637e:	6318                	ld	a4,0(a4)
    80006380:	97ba                	add	a5,a5,a4
    80006382:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006386:	0001d797          	auipc	a5,0x1d
    8000638a:	c7a78793          	addi	a5,a5,-902 # 80023000 <disk>
    8000638e:	97aa                	add	a5,a5,a0
    80006390:	6509                	lui	a0,0x2
    80006392:	953e                	add	a0,a0,a5
    80006394:	4785                	li	a5,1
    80006396:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000639a:	0001f517          	auipc	a0,0x1f
    8000639e:	c7e50513          	addi	a0,a0,-898 # 80025018 <disk+0x2018>
    800063a2:	ffffc097          	auipc	ra,0xffffc
    800063a6:	32e080e7          	jalr	814(ra) # 800026d0 <wakeup>
}
    800063aa:	60a2                	ld	ra,8(sp)
    800063ac:	6402                	ld	s0,0(sp)
    800063ae:	0141                	addi	sp,sp,16
    800063b0:	8082                	ret
    panic("free_desc 1");
    800063b2:	00002517          	auipc	a0,0x2
    800063b6:	41e50513          	addi	a0,a0,1054 # 800087d0 <syscalls+0x330>
    800063ba:	ffffa097          	auipc	ra,0xffffa
    800063be:	184080e7          	jalr	388(ra) # 8000053e <panic>
    panic("free_desc 2");
    800063c2:	00002517          	auipc	a0,0x2
    800063c6:	41e50513          	addi	a0,a0,1054 # 800087e0 <syscalls+0x340>
    800063ca:	ffffa097          	auipc	ra,0xffffa
    800063ce:	174080e7          	jalr	372(ra) # 8000053e <panic>

00000000800063d2 <virtio_disk_init>:
{
    800063d2:	1101                	addi	sp,sp,-32
    800063d4:	ec06                	sd	ra,24(sp)
    800063d6:	e822                	sd	s0,16(sp)
    800063d8:	e426                	sd	s1,8(sp)
    800063da:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063dc:	00002597          	auipc	a1,0x2
    800063e0:	41458593          	addi	a1,a1,1044 # 800087f0 <syscalls+0x350>
    800063e4:	0001f517          	auipc	a0,0x1f
    800063e8:	d4450513          	addi	a0,a0,-700 # 80025128 <disk+0x2128>
    800063ec:	ffffa097          	auipc	ra,0xffffa
    800063f0:	768080e7          	jalr	1896(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063f4:	100017b7          	lui	a5,0x10001
    800063f8:	4398                	lw	a4,0(a5)
    800063fa:	2701                	sext.w	a4,a4
    800063fc:	747277b7          	lui	a5,0x74727
    80006400:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006404:	0ef71163          	bne	a4,a5,800064e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006408:	100017b7          	lui	a5,0x10001
    8000640c:	43dc                	lw	a5,4(a5)
    8000640e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006410:	4705                	li	a4,1
    80006412:	0ce79a63          	bne	a5,a4,800064e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006416:	100017b7          	lui	a5,0x10001
    8000641a:	479c                	lw	a5,8(a5)
    8000641c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000641e:	4709                	li	a4,2
    80006420:	0ce79363          	bne	a5,a4,800064e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006424:	100017b7          	lui	a5,0x10001
    80006428:	47d8                	lw	a4,12(a5)
    8000642a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000642c:	554d47b7          	lui	a5,0x554d4
    80006430:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006434:	0af71963          	bne	a4,a5,800064e6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006438:	100017b7          	lui	a5,0x10001
    8000643c:	4705                	li	a4,1
    8000643e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006440:	470d                	li	a4,3
    80006442:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006444:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006446:	c7ffe737          	lui	a4,0xc7ffe
    8000644a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000644e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006450:	2701                	sext.w	a4,a4
    80006452:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006454:	472d                	li	a4,11
    80006456:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006458:	473d                	li	a4,15
    8000645a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000645c:	6705                	lui	a4,0x1
    8000645e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006460:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006464:	5bdc                	lw	a5,52(a5)
    80006466:	2781                	sext.w	a5,a5
  if(max == 0)
    80006468:	c7d9                	beqz	a5,800064f6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000646a:	471d                	li	a4,7
    8000646c:	08f77d63          	bgeu	a4,a5,80006506 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006470:	100014b7          	lui	s1,0x10001
    80006474:	47a1                	li	a5,8
    80006476:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006478:	6609                	lui	a2,0x2
    8000647a:	4581                	li	a1,0
    8000647c:	0001d517          	auipc	a0,0x1d
    80006480:	b8450513          	addi	a0,a0,-1148 # 80023000 <disk>
    80006484:	ffffb097          	auipc	ra,0xffffb
    80006488:	86e080e7          	jalr	-1938(ra) # 80000cf2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000648c:	0001d717          	auipc	a4,0x1d
    80006490:	b7470713          	addi	a4,a4,-1164 # 80023000 <disk>
    80006494:	00c75793          	srli	a5,a4,0xc
    80006498:	2781                	sext.w	a5,a5
    8000649a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000649c:	0001f797          	auipc	a5,0x1f
    800064a0:	b6478793          	addi	a5,a5,-1180 # 80025000 <disk+0x2000>
    800064a4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800064a6:	0001d717          	auipc	a4,0x1d
    800064aa:	bda70713          	addi	a4,a4,-1062 # 80023080 <disk+0x80>
    800064ae:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800064b0:	0001e717          	auipc	a4,0x1e
    800064b4:	b5070713          	addi	a4,a4,-1200 # 80024000 <disk+0x1000>
    800064b8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800064ba:	4705                	li	a4,1
    800064bc:	00e78c23          	sb	a4,24(a5)
    800064c0:	00e78ca3          	sb	a4,25(a5)
    800064c4:	00e78d23          	sb	a4,26(a5)
    800064c8:	00e78da3          	sb	a4,27(a5)
    800064cc:	00e78e23          	sb	a4,28(a5)
    800064d0:	00e78ea3          	sb	a4,29(a5)
    800064d4:	00e78f23          	sb	a4,30(a5)
    800064d8:	00e78fa3          	sb	a4,31(a5)
}
    800064dc:	60e2                	ld	ra,24(sp)
    800064de:	6442                	ld	s0,16(sp)
    800064e0:	64a2                	ld	s1,8(sp)
    800064e2:	6105                	addi	sp,sp,32
    800064e4:	8082                	ret
    panic("could not find virtio disk");
    800064e6:	00002517          	auipc	a0,0x2
    800064ea:	31a50513          	addi	a0,a0,794 # 80008800 <syscalls+0x360>
    800064ee:	ffffa097          	auipc	ra,0xffffa
    800064f2:	050080e7          	jalr	80(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800064f6:	00002517          	auipc	a0,0x2
    800064fa:	32a50513          	addi	a0,a0,810 # 80008820 <syscalls+0x380>
    800064fe:	ffffa097          	auipc	ra,0xffffa
    80006502:	040080e7          	jalr	64(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006506:	00002517          	auipc	a0,0x2
    8000650a:	33a50513          	addi	a0,a0,826 # 80008840 <syscalls+0x3a0>
    8000650e:	ffffa097          	auipc	ra,0xffffa
    80006512:	030080e7          	jalr	48(ra) # 8000053e <panic>

0000000080006516 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006516:	7159                	addi	sp,sp,-112
    80006518:	f486                	sd	ra,104(sp)
    8000651a:	f0a2                	sd	s0,96(sp)
    8000651c:	eca6                	sd	s1,88(sp)
    8000651e:	e8ca                	sd	s2,80(sp)
    80006520:	e4ce                	sd	s3,72(sp)
    80006522:	e0d2                	sd	s4,64(sp)
    80006524:	fc56                	sd	s5,56(sp)
    80006526:	f85a                	sd	s6,48(sp)
    80006528:	f45e                	sd	s7,40(sp)
    8000652a:	f062                	sd	s8,32(sp)
    8000652c:	ec66                	sd	s9,24(sp)
    8000652e:	e86a                	sd	s10,16(sp)
    80006530:	1880                	addi	s0,sp,112
    80006532:	892a                	mv	s2,a0
    80006534:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006536:	00c52c83          	lw	s9,12(a0)
    8000653a:	001c9c9b          	slliw	s9,s9,0x1
    8000653e:	1c82                	slli	s9,s9,0x20
    80006540:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006544:	0001f517          	auipc	a0,0x1f
    80006548:	be450513          	addi	a0,a0,-1052 # 80025128 <disk+0x2128>
    8000654c:	ffffa097          	auipc	ra,0xffffa
    80006550:	698080e7          	jalr	1688(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006554:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006556:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006558:	0001db97          	auipc	s7,0x1d
    8000655c:	aa8b8b93          	addi	s7,s7,-1368 # 80023000 <disk>
    80006560:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006562:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006564:	8a4e                	mv	s4,s3
    80006566:	a051                	j	800065ea <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006568:	00fb86b3          	add	a3,s7,a5
    8000656c:	96da                	add	a3,a3,s6
    8000656e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006572:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006574:	0207c563          	bltz	a5,8000659e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006578:	2485                	addiw	s1,s1,1
    8000657a:	0711                	addi	a4,a4,4
    8000657c:	25548063          	beq	s1,s5,800067bc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006580:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006582:	0001f697          	auipc	a3,0x1f
    80006586:	a9668693          	addi	a3,a3,-1386 # 80025018 <disk+0x2018>
    8000658a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000658c:	0006c583          	lbu	a1,0(a3)
    80006590:	fde1                	bnez	a1,80006568 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006592:	2785                	addiw	a5,a5,1
    80006594:	0685                	addi	a3,a3,1
    80006596:	ff879be3          	bne	a5,s8,8000658c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000659a:	57fd                	li	a5,-1
    8000659c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000659e:	02905a63          	blez	s1,800065d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065a2:	f9042503          	lw	a0,-112(s0)
    800065a6:	00000097          	auipc	ra,0x0
    800065aa:	d90080e7          	jalr	-624(ra) # 80006336 <free_desc>
      for(int j = 0; j < i; j++)
    800065ae:	4785                	li	a5,1
    800065b0:	0297d163          	bge	a5,s1,800065d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065b4:	f9442503          	lw	a0,-108(s0)
    800065b8:	00000097          	auipc	ra,0x0
    800065bc:	d7e080e7          	jalr	-642(ra) # 80006336 <free_desc>
      for(int j = 0; j < i; j++)
    800065c0:	4789                	li	a5,2
    800065c2:	0097d863          	bge	a5,s1,800065d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065c6:	f9842503          	lw	a0,-104(s0)
    800065ca:	00000097          	auipc	ra,0x0
    800065ce:	d6c080e7          	jalr	-660(ra) # 80006336 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065d2:	0001f597          	auipc	a1,0x1f
    800065d6:	b5658593          	addi	a1,a1,-1194 # 80025128 <disk+0x2128>
    800065da:	0001f517          	auipc	a0,0x1f
    800065de:	a3e50513          	addi	a0,a0,-1474 # 80025018 <disk+0x2018>
    800065e2:	ffffc097          	auipc	ra,0xffffc
    800065e6:	f48080e7          	jalr	-184(ra) # 8000252a <sleep>
  for(int i = 0; i < 3; i++){
    800065ea:	f9040713          	addi	a4,s0,-112
    800065ee:	84ce                	mv	s1,s3
    800065f0:	bf41                	j	80006580 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800065f2:	20058713          	addi	a4,a1,512
    800065f6:	00471693          	slli	a3,a4,0x4
    800065fa:	0001d717          	auipc	a4,0x1d
    800065fe:	a0670713          	addi	a4,a4,-1530 # 80023000 <disk>
    80006602:	9736                	add	a4,a4,a3
    80006604:	4685                	li	a3,1
    80006606:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000660a:	20058713          	addi	a4,a1,512
    8000660e:	00471693          	slli	a3,a4,0x4
    80006612:	0001d717          	auipc	a4,0x1d
    80006616:	9ee70713          	addi	a4,a4,-1554 # 80023000 <disk>
    8000661a:	9736                	add	a4,a4,a3
    8000661c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006620:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006624:	7679                	lui	a2,0xffffe
    80006626:	963e                	add	a2,a2,a5
    80006628:	0001f697          	auipc	a3,0x1f
    8000662c:	9d868693          	addi	a3,a3,-1576 # 80025000 <disk+0x2000>
    80006630:	6298                	ld	a4,0(a3)
    80006632:	9732                	add	a4,a4,a2
    80006634:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006636:	6298                	ld	a4,0(a3)
    80006638:	9732                	add	a4,a4,a2
    8000663a:	4541                	li	a0,16
    8000663c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000663e:	6298                	ld	a4,0(a3)
    80006640:	9732                	add	a4,a4,a2
    80006642:	4505                	li	a0,1
    80006644:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006648:	f9442703          	lw	a4,-108(s0)
    8000664c:	6288                	ld	a0,0(a3)
    8000664e:	962a                	add	a2,a2,a0
    80006650:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006654:	0712                	slli	a4,a4,0x4
    80006656:	6290                	ld	a2,0(a3)
    80006658:	963a                	add	a2,a2,a4
    8000665a:	05890513          	addi	a0,s2,88
    8000665e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006660:	6294                	ld	a3,0(a3)
    80006662:	96ba                	add	a3,a3,a4
    80006664:	40000613          	li	a2,1024
    80006668:	c690                	sw	a2,8(a3)
  if(write)
    8000666a:	140d0063          	beqz	s10,800067aa <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000666e:	0001f697          	auipc	a3,0x1f
    80006672:	9926b683          	ld	a3,-1646(a3) # 80025000 <disk+0x2000>
    80006676:	96ba                	add	a3,a3,a4
    80006678:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000667c:	0001d817          	auipc	a6,0x1d
    80006680:	98480813          	addi	a6,a6,-1660 # 80023000 <disk>
    80006684:	0001f517          	auipc	a0,0x1f
    80006688:	97c50513          	addi	a0,a0,-1668 # 80025000 <disk+0x2000>
    8000668c:	6114                	ld	a3,0(a0)
    8000668e:	96ba                	add	a3,a3,a4
    80006690:	00c6d603          	lhu	a2,12(a3)
    80006694:	00166613          	ori	a2,a2,1
    80006698:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000669c:	f9842683          	lw	a3,-104(s0)
    800066a0:	6110                	ld	a2,0(a0)
    800066a2:	9732                	add	a4,a4,a2
    800066a4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800066a8:	20058613          	addi	a2,a1,512
    800066ac:	0612                	slli	a2,a2,0x4
    800066ae:	9642                	add	a2,a2,a6
    800066b0:	577d                	li	a4,-1
    800066b2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800066b6:	00469713          	slli	a4,a3,0x4
    800066ba:	6114                	ld	a3,0(a0)
    800066bc:	96ba                	add	a3,a3,a4
    800066be:	03078793          	addi	a5,a5,48
    800066c2:	97c2                	add	a5,a5,a6
    800066c4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800066c6:	611c                	ld	a5,0(a0)
    800066c8:	97ba                	add	a5,a5,a4
    800066ca:	4685                	li	a3,1
    800066cc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800066ce:	611c                	ld	a5,0(a0)
    800066d0:	97ba                	add	a5,a5,a4
    800066d2:	4809                	li	a6,2
    800066d4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800066d8:	611c                	ld	a5,0(a0)
    800066da:	973e                	add	a4,a4,a5
    800066dc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800066e0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800066e4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800066e8:	6518                	ld	a4,8(a0)
    800066ea:	00275783          	lhu	a5,2(a4)
    800066ee:	8b9d                	andi	a5,a5,7
    800066f0:	0786                	slli	a5,a5,0x1
    800066f2:	97ba                	add	a5,a5,a4
    800066f4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800066f8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800066fc:	6518                	ld	a4,8(a0)
    800066fe:	00275783          	lhu	a5,2(a4)
    80006702:	2785                	addiw	a5,a5,1
    80006704:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006708:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000670c:	100017b7          	lui	a5,0x10001
    80006710:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006714:	00492703          	lw	a4,4(s2)
    80006718:	4785                	li	a5,1
    8000671a:	02f71163          	bne	a4,a5,8000673c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000671e:	0001f997          	auipc	s3,0x1f
    80006722:	a0a98993          	addi	s3,s3,-1526 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006726:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006728:	85ce                	mv	a1,s3
    8000672a:	854a                	mv	a0,s2
    8000672c:	ffffc097          	auipc	ra,0xffffc
    80006730:	dfe080e7          	jalr	-514(ra) # 8000252a <sleep>
  while(b->disk == 1) {
    80006734:	00492783          	lw	a5,4(s2)
    80006738:	fe9788e3          	beq	a5,s1,80006728 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000673c:	f9042903          	lw	s2,-112(s0)
    80006740:	20090793          	addi	a5,s2,512
    80006744:	00479713          	slli	a4,a5,0x4
    80006748:	0001d797          	auipc	a5,0x1d
    8000674c:	8b878793          	addi	a5,a5,-1864 # 80023000 <disk>
    80006750:	97ba                	add	a5,a5,a4
    80006752:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006756:	0001f997          	auipc	s3,0x1f
    8000675a:	8aa98993          	addi	s3,s3,-1878 # 80025000 <disk+0x2000>
    8000675e:	00491713          	slli	a4,s2,0x4
    80006762:	0009b783          	ld	a5,0(s3)
    80006766:	97ba                	add	a5,a5,a4
    80006768:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000676c:	854a                	mv	a0,s2
    8000676e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006772:	00000097          	auipc	ra,0x0
    80006776:	bc4080e7          	jalr	-1084(ra) # 80006336 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000677a:	8885                	andi	s1,s1,1
    8000677c:	f0ed                	bnez	s1,8000675e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000677e:	0001f517          	auipc	a0,0x1f
    80006782:	9aa50513          	addi	a0,a0,-1622 # 80025128 <disk+0x2128>
    80006786:	ffffa097          	auipc	ra,0xffffa
    8000678a:	512080e7          	jalr	1298(ra) # 80000c98 <release>
}
    8000678e:	70a6                	ld	ra,104(sp)
    80006790:	7406                	ld	s0,96(sp)
    80006792:	64e6                	ld	s1,88(sp)
    80006794:	6946                	ld	s2,80(sp)
    80006796:	69a6                	ld	s3,72(sp)
    80006798:	6a06                	ld	s4,64(sp)
    8000679a:	7ae2                	ld	s5,56(sp)
    8000679c:	7b42                	ld	s6,48(sp)
    8000679e:	7ba2                	ld	s7,40(sp)
    800067a0:	7c02                	ld	s8,32(sp)
    800067a2:	6ce2                	ld	s9,24(sp)
    800067a4:	6d42                	ld	s10,16(sp)
    800067a6:	6165                	addi	sp,sp,112
    800067a8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800067aa:	0001f697          	auipc	a3,0x1f
    800067ae:	8566b683          	ld	a3,-1962(a3) # 80025000 <disk+0x2000>
    800067b2:	96ba                	add	a3,a3,a4
    800067b4:	4609                	li	a2,2
    800067b6:	00c69623          	sh	a2,12(a3)
    800067ba:	b5c9                	j	8000667c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800067bc:	f9042583          	lw	a1,-112(s0)
    800067c0:	20058793          	addi	a5,a1,512
    800067c4:	0792                	slli	a5,a5,0x4
    800067c6:	0001d517          	auipc	a0,0x1d
    800067ca:	8e250513          	addi	a0,a0,-1822 # 800230a8 <disk+0xa8>
    800067ce:	953e                	add	a0,a0,a5
  if(write)
    800067d0:	e20d11e3          	bnez	s10,800065f2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800067d4:	20058713          	addi	a4,a1,512
    800067d8:	00471693          	slli	a3,a4,0x4
    800067dc:	0001d717          	auipc	a4,0x1d
    800067e0:	82470713          	addi	a4,a4,-2012 # 80023000 <disk>
    800067e4:	9736                	add	a4,a4,a3
    800067e6:	0a072423          	sw	zero,168(a4)
    800067ea:	b505                	j	8000660a <virtio_disk_rw+0xf4>

00000000800067ec <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800067ec:	1101                	addi	sp,sp,-32
    800067ee:	ec06                	sd	ra,24(sp)
    800067f0:	e822                	sd	s0,16(sp)
    800067f2:	e426                	sd	s1,8(sp)
    800067f4:	e04a                	sd	s2,0(sp)
    800067f6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800067f8:	0001f517          	auipc	a0,0x1f
    800067fc:	93050513          	addi	a0,a0,-1744 # 80025128 <disk+0x2128>
    80006800:	ffffa097          	auipc	ra,0xffffa
    80006804:	3e4080e7          	jalr	996(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006808:	10001737          	lui	a4,0x10001
    8000680c:	533c                	lw	a5,96(a4)
    8000680e:	8b8d                	andi	a5,a5,3
    80006810:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006812:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006816:	0001e797          	auipc	a5,0x1e
    8000681a:	7ea78793          	addi	a5,a5,2026 # 80025000 <disk+0x2000>
    8000681e:	6b94                	ld	a3,16(a5)
    80006820:	0207d703          	lhu	a4,32(a5)
    80006824:	0026d783          	lhu	a5,2(a3)
    80006828:	06f70163          	beq	a4,a5,8000688a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000682c:	0001c917          	auipc	s2,0x1c
    80006830:	7d490913          	addi	s2,s2,2004 # 80023000 <disk>
    80006834:	0001e497          	auipc	s1,0x1e
    80006838:	7cc48493          	addi	s1,s1,1996 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000683c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006840:	6898                	ld	a4,16(s1)
    80006842:	0204d783          	lhu	a5,32(s1)
    80006846:	8b9d                	andi	a5,a5,7
    80006848:	078e                	slli	a5,a5,0x3
    8000684a:	97ba                	add	a5,a5,a4
    8000684c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000684e:	20078713          	addi	a4,a5,512
    80006852:	0712                	slli	a4,a4,0x4
    80006854:	974a                	add	a4,a4,s2
    80006856:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000685a:	e731                	bnez	a4,800068a6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000685c:	20078793          	addi	a5,a5,512
    80006860:	0792                	slli	a5,a5,0x4
    80006862:	97ca                	add	a5,a5,s2
    80006864:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006866:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000686a:	ffffc097          	auipc	ra,0xffffc
    8000686e:	e66080e7          	jalr	-410(ra) # 800026d0 <wakeup>

    disk.used_idx += 1;
    80006872:	0204d783          	lhu	a5,32(s1)
    80006876:	2785                	addiw	a5,a5,1
    80006878:	17c2                	slli	a5,a5,0x30
    8000687a:	93c1                	srli	a5,a5,0x30
    8000687c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006880:	6898                	ld	a4,16(s1)
    80006882:	00275703          	lhu	a4,2(a4)
    80006886:	faf71be3          	bne	a4,a5,8000683c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000688a:	0001f517          	auipc	a0,0x1f
    8000688e:	89e50513          	addi	a0,a0,-1890 # 80025128 <disk+0x2128>
    80006892:	ffffa097          	auipc	ra,0xffffa
    80006896:	406080e7          	jalr	1030(ra) # 80000c98 <release>
}
    8000689a:	60e2                	ld	ra,24(sp)
    8000689c:	6442                	ld	s0,16(sp)
    8000689e:	64a2                	ld	s1,8(sp)
    800068a0:	6902                	ld	s2,0(sp)
    800068a2:	6105                	addi	sp,sp,32
    800068a4:	8082                	ret
      panic("virtio_disk_intr status");
    800068a6:	00002517          	auipc	a0,0x2
    800068aa:	fba50513          	addi	a0,a0,-70 # 80008860 <syscalls+0x3c0>
    800068ae:	ffffa097          	auipc	ra,0xffffa
    800068b2:	c90080e7          	jalr	-880(ra) # 8000053e <panic>

00000000800068b6 <cas>:
    800068b6:	100522af          	lr.w	t0,(a0)
    800068ba:	00b29563          	bne	t0,a1,800068c4 <fail>
    800068be:	18c5252f          	sc.w	a0,a2,(a0)
    800068c2:	8082                	ret

00000000800068c4 <fail>:
    800068c4:	4505                	li	a0,1
    800068c6:	8082                	ret
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
