
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
    80000068:	22c78793          	addi	a5,a5,556 # 80006290 <timervec>
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
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	9f4080e7          	jalr	-1548(ra) # 80002b20 <either_copyin>
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
    800001c8:	ca4080e7          	jalr	-860(ra) # 80001e68 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	482080e7          	jalr	1154(ra) # 80002656 <sleep>
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
    80000214:	8ba080e7          	jalr	-1862(ra) # 80002aca <either_copyout>
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
    800002f2:	00003097          	auipc	ra,0x3
    800002f6:	884080e7          	jalr	-1916(ra) # 80002b76 <procdump>
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
    8000044a:	3b6080e7          	jalr	950(ra) # 800027fc <wakeup>
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
    800008a4:	f5c080e7          	jalr	-164(ra) # 800027fc <wakeup>
    
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
    80000930:	d2a080e7          	jalr	-726(ra) # 80002656 <sleep>
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
    80000b82:	2c6080e7          	jalr	710(ra) # 80001e44 <mycpu>
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
    80000bb4:	294080e7          	jalr	660(ra) # 80001e44 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	288080e7          	jalr	648(ra) # 80001e44 <mycpu>
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
    80000bd8:	270080e7          	jalr	624(ra) # 80001e44 <mycpu>
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
    80000c18:	230080e7          	jalr	560(ra) # 80001e44 <mycpu>
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
    80000c56:	1f2080e7          	jalr	498(ra) # 80001e44 <mycpu>
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
    80000ebe:	f7a080e7          	jalr	-134(ra) # 80001e34 <cpuid>
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
    80000eda:	f5e080e7          	jalr	-162(ra) # 80001e34 <cpuid>
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
    80000efc:	e3a080e7          	jalr	-454(ra) # 80002d32 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f00:	00005097          	auipc	ra,0x5
    80000f04:	3d0080e7          	jalr	976(ra) # 800062d0 <plicinithart>
  }

  scheduler();        
    80000f08:	00001097          	auipc	ra,0x1
    80000f0c:	532080e7          	jalr	1330(ra) # 8000243a <scheduler>
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
    80000f6c:	dc6080e7          	jalr	-570(ra) # 80001d2e <procinit>
    trapinit();      // trap vectors
    80000f70:	00002097          	auipc	ra,0x2
    80000f74:	d9a080e7          	jalr	-614(ra) # 80002d0a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f78:	00002097          	auipc	ra,0x2
    80000f7c:	dba080e7          	jalr	-582(ra) # 80002d32 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f80:	00005097          	auipc	ra,0x5
    80000f84:	33a080e7          	jalr	826(ra) # 800062ba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f88:	00005097          	auipc	ra,0x5
    80000f8c:	348080e7          	jalr	840(ra) # 800062d0 <plicinithart>
    binit();         // buffer cache
    80000f90:	00002097          	auipc	ra,0x2
    80000f94:	52e080e7          	jalr	1326(ra) # 800034be <binit>
    iinit();         // inode table
    80000f98:	00003097          	auipc	ra,0x3
    80000f9c:	bbe080e7          	jalr	-1090(ra) # 80003b56 <iinit>
    fileinit();      // file table
    80000fa0:	00004097          	auipc	ra,0x4
    80000fa4:	b68080e7          	jalr	-1176(ra) # 80004b08 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa8:	00005097          	auipc	ra,0x5
    80000fac:	44a080e7          	jalr	1098(ra) # 800063f2 <virtio_disk_init>
    userinit();      // first user process
    80000fb0:	00001097          	auipc	ra,0x1
    80000fb4:	206080e7          	jalr	518(ra) # 800021b6 <userinit>
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
    80001268:	a34080e7          	jalr	-1484(ra) # 80001c98 <proc_mapstacks>
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
      release(&to_remove->p_lock);
      release(&curr_proc->p_lock);
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
      release(&to_remove->p_lock);
    80001972:	038a0513          	addi	a0,s4,56
    80001976:	fffff097          	auipc	ra,0xfffff
    8000197a:	334080e7          	jalr	820(ra) # 80000caa <release>
      release(&curr_proc->p_lock);
    8000197e:	03848513          	addi	a0,s1,56
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

0000000080001a50 <remove_first>:

int remove_first(int* head_list, struct spinlock* head_lock) {
    80001a50:	7139                	addi	sp,sp,-64
    80001a52:	fc06                	sd	ra,56(sp)
    80001a54:	f822                	sd	s0,48(sp)
    80001a56:	f426                	sd	s1,40(sp)
    80001a58:	f04a                	sd	s2,32(sp)
    80001a5a:	ec4e                	sd	s3,24(sp)
    80001a5c:	e852                	sd	s4,16(sp)
    80001a5e:	e456                	sd	s5,8(sp)
    80001a60:	0080                	addi	s0,sp,64
    80001a62:	8aaa                	mv	s5,a0
    80001a64:	89ae                	mv	s3,a1
    acquire(head_lock);
    80001a66:	852e                	mv	a0,a1
    80001a68:	fffff097          	auipc	ra,0xfffff
    80001a6c:	17c080e7          	jalr	380(ra) # 80000be4 <acquire>
    if (*head_list == -1){
    80001a70:	000aa483          	lw	s1,0(s5)
    80001a74:	57fd                	li	a5,-1
    80001a76:	04f48d63          	beq	s1,a5,80001ad0 <remove_first+0x80>
        release(head_lock);
        return -1;
    }
    struct proc *p = &proc[*head_list];
    acquire(&p->p_lock);
    80001a7a:	18800793          	li	a5,392
    80001a7e:	02f484b3          	mul	s1,s1,a5
    80001a82:	03848a13          	addi	s4,s1,56
    80001a86:	00010917          	auipc	s2,0x10
    80001a8a:	d9290913          	addi	s2,s2,-622 # 80011818 <proc>
    80001a8e:	9a4a                	add	s4,s4,s2
    80001a90:	8552                	mv	a0,s4
    80001a92:	fffff097          	auipc	ra,0xfffff
    80001a96:	152080e7          	jalr	338(ra) # 80000be4 <acquire>
    *head_list = p->next;
    80001a9a:	94ca                	add	s1,s1,s2
    80001a9c:	48bc                	lw	a5,80(s1)
    80001a9e:	00faa023          	sw	a5,0(s5)
    p->next = -1;
    80001aa2:	57fd                	li	a5,-1
    80001aa4:	c8bc                	sw	a5,80(s1)
    release(&p->p_lock);
    80001aa6:	8552                	mv	a0,s4
    80001aa8:	fffff097          	auipc	ra,0xfffff
    80001aac:	202080e7          	jalr	514(ra) # 80000caa <release>
    release(head_lock);
    80001ab0:	854e                	mv	a0,s3
    80001ab2:	fffff097          	auipc	ra,0xfffff
    80001ab6:	1f8080e7          	jalr	504(ra) # 80000caa <release>
    return p->proc_idx;
    80001aba:	48e4                	lw	s1,84(s1)
}
    80001abc:	8526                	mv	a0,s1
    80001abe:	70e2                	ld	ra,56(sp)
    80001ac0:	7442                	ld	s0,48(sp)
    80001ac2:	74a2                	ld	s1,40(sp)
    80001ac4:	7902                	ld	s2,32(sp)
    80001ac6:	69e2                	ld	s3,24(sp)
    80001ac8:	6a42                	ld	s4,16(sp)
    80001aca:	6aa2                	ld	s5,8(sp)
    80001acc:	6121                	addi	sp,sp,64
    80001ace:	8082                	ret
        release(head_lock);
    80001ad0:	854e                	mv	a0,s3
    80001ad2:	fffff097          	auipc	ra,0xfffff
    80001ad6:	1d8080e7          	jalr	472(ra) # 80000caa <release>
        return -1;
    80001ada:	b7cd                	j	80001abc <remove_first+0x6c>

0000000080001adc <add_not_first>:
//     new_proc->next= -1;
//     release(&curr_proc->p_lock);
// }

void add_not_first(struct proc *curr, struct proc *to_add)
{
    80001adc:	7139                	addi	sp,sp,-64
    80001ade:	fc06                	sd	ra,56(sp)
    80001ae0:	f822                	sd	s0,48(sp)
    80001ae2:	f426                	sd	s1,40(sp)
    80001ae4:	f04a                	sd	s2,32(sp)
    80001ae6:	ec4e                	sd	s3,24(sp)
    80001ae8:	e852                	sd	s4,16(sp)
    80001aea:	e456                	sd	s5,8(sp)
    80001aec:	0080                	addi	s0,sp,64
    80001aee:	84aa                	mv	s1,a0
    80001af0:	8aae                	mv	s5,a1
  while (curr->next != -1)
    80001af2:	4928                	lw	a0,80(a0)
    80001af4:	57fd                	li	a5,-1
    80001af6:	02f50f63          	beq	a0,a5,80001b34 <add_not_first+0x58>
  {
    acquire(&proc[curr->next].p_lock);
    80001afa:	18800993          	li	s3,392
    80001afe:	00010917          	auipc	s2,0x10
    80001b02:	d1a90913          	addi	s2,s2,-742 # 80011818 <proc>
  while (curr->next != -1)
    80001b06:	5a7d                	li	s4,-1
    acquire(&proc[curr->next].p_lock);
    80001b08:	03350533          	mul	a0,a0,s3
    80001b0c:	03850513          	addi	a0,a0,56
    80001b10:	954a                	add	a0,a0,s2
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	0d2080e7          	jalr	210(ra) # 80000be4 <acquire>
    release(&curr->p_lock); //  NEED to add prev
    80001b1a:	03848513          	addi	a0,s1,56
    80001b1e:	fffff097          	auipc	ra,0xfffff
    80001b22:	18c080e7          	jalr	396(ra) # 80000caa <release>
    curr = &proc[curr->next];
    80001b26:	48a4                	lw	s1,80(s1)
    80001b28:	033484b3          	mul	s1,s1,s3
    80001b2c:	94ca                	add	s1,s1,s2
  while (curr->next != -1)
    80001b2e:	48a8                	lw	a0,80(s1)
    80001b30:	fd451ce3          	bne	a0,s4,80001b08 <add_not_first+0x2c>
  }
  to_add->next = -1;
    80001b34:	57fd                	li	a5,-1
    80001b36:	04faa823          	sw	a5,80(s5)
  curr->next = to_add->proc_idx;
    80001b3a:	054aa783          	lw	a5,84(s5)
    80001b3e:	c8bc                	sw	a5,80(s1)
  release(&curr->p_lock);
    80001b40:	03848513          	addi	a0,s1,56
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	166080e7          	jalr	358(ra) # 80000caa <release>
}
    80001b4c:	70e2                	ld	ra,56(sp)
    80001b4e:	7442                	ld	s0,48(sp)
    80001b50:	74a2                	ld	s1,40(sp)
    80001b52:	7902                	ld	s2,32(sp)
    80001b54:	69e2                	ld	s3,24(sp)
    80001b56:	6a42                	ld	s4,16(sp)
    80001b58:	6aa2                	ld	s5,8(sp)
    80001b5a:	6121                	addi	sp,sp,64
    80001b5c:	8082                	ret

0000000080001b5e <add_proc>:

void add_proc(int *head, struct proc *to_add, struct spinlock *head_lock)
{
    80001b5e:	7139                	addi	sp,sp,-64
    80001b60:	fc06                	sd	ra,56(sp)
    80001b62:	f822                	sd	s0,48(sp)
    80001b64:	f426                	sd	s1,40(sp)
    80001b66:	f04a                	sd	s2,32(sp)
    80001b68:	ec4e                	sd	s3,24(sp)
    80001b6a:	e852                	sd	s4,16(sp)
    80001b6c:	e456                	sd	s5,8(sp)
    80001b6e:	0080                	addi	s0,sp,64
    80001b70:	84aa                	mv	s1,a0
    80001b72:	89ae                	mv	s3,a1
    80001b74:	8932                	mv	s2,a2
  acquire(head_lock);
    80001b76:	8532                	mv	a0,a2
    80001b78:	fffff097          	auipc	ra,0xfffff
    80001b7c:	06c080e7          	jalr	108(ra) # 80000be4 <acquire>
  if (*head == -1)
    80001b80:	409c                	lw	a5,0(s1)
    80001b82:	577d                	li	a4,-1
    80001b84:	04e78963          	beq	a5,a4,80001bd6 <add_proc+0x78>
    proc[*head].next = -1;
    release(head_lock);
  }
  else
  {
    acquire(&proc[*head].p_lock);
    80001b88:	18800a93          	li	s5,392
    80001b8c:	035787b3          	mul	a5,a5,s5
    80001b90:	03878793          	addi	a5,a5,56
    80001b94:	00010a17          	auipc	s4,0x10
    80001b98:	c84a0a13          	addi	s4,s4,-892 # 80011818 <proc>
    80001b9c:	00fa0533          	add	a0,s4,a5
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	044080e7          	jalr	68(ra) # 80000be4 <acquire>
    release(head_lock);
    80001ba8:	854a                	mv	a0,s2
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	100080e7          	jalr	256(ra) # 80000caa <release>
    add_not_first(&proc[*head], to_add);
    80001bb2:	4088                	lw	a0,0(s1)
    80001bb4:	03550533          	mul	a0,a0,s5
    80001bb8:	85ce                	mv	a1,s3
    80001bba:	9552                	add	a0,a0,s4
    80001bbc:	00000097          	auipc	ra,0x0
    80001bc0:	f20080e7          	jalr	-224(ra) # 80001adc <add_not_first>
  }
}
    80001bc4:	70e2                	ld	ra,56(sp)
    80001bc6:	7442                	ld	s0,48(sp)
    80001bc8:	74a2                	ld	s1,40(sp)
    80001bca:	7902                	ld	s2,32(sp)
    80001bcc:	69e2                	ld	s3,24(sp)
    80001bce:	6a42                	ld	s4,16(sp)
    80001bd0:	6aa2                	ld	s5,8(sp)
    80001bd2:	6121                	addi	sp,sp,64
    80001bd4:	8082                	ret
    *head = to_add->proc_idx;
    80001bd6:	0549a783          	lw	a5,84(s3) # 1054 <_entry-0x7fffefac>
    80001bda:	c09c                	sw	a5,0(s1)
    proc[*head].next = -1;
    80001bdc:	18800713          	li	a4,392
    80001be0:	02e787b3          	mul	a5,a5,a4
    80001be4:	00010717          	auipc	a4,0x10
    80001be8:	c3470713          	addi	a4,a4,-972 # 80011818 <proc>
    80001bec:	97ba                	add	a5,a5,a4
    80001bee:	577d                	li	a4,-1
    80001bf0:	cbb8                	sw	a4,80(a5)
    release(head_lock);
    80001bf2:	854a                	mv	a0,s2
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	0b6080e7          	jalr	182(ra) # 80000caa <release>
    80001bfc:	b7e1                	j	80001bc4 <add_proc+0x66>

0000000080001bfe <init_locks>:
void init_locks()
{
    80001bfe:	7179                	addi	sp,sp,-48
    80001c00:	f406                	sd	ra,40(sp)
    80001c02:	f022                	sd	s0,32(sp)
    80001c04:	ec26                	sd	s1,24(sp)
    80001c06:	e84a                	sd	s2,16(sp)
    80001c08:	e44e                	sd	s3,8(sp)
    80001c0a:	e052                	sd	s4,0(sp)
    80001c0c:	1800                	addi	s0,sp,48
  struct cpu *c;
  initlock(&zombie_lock, "zombie");
    80001c0e:	00006597          	auipc	a1,0x6
    80001c12:	5ea58593          	addi	a1,a1,1514 # 800081f8 <digits+0x1b8>
    80001c16:	0000f517          	auipc	a0,0xf
    80001c1a:	68a50513          	addi	a0,a0,1674 # 800112a0 <zombie_lock>
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	f36080e7          	jalr	-202(ra) # 80000b54 <initlock>
  initlock(&unused_lock, "unused");
    80001c26:	00006597          	auipc	a1,0x6
    80001c2a:	5da58593          	addi	a1,a1,1498 # 80008200 <digits+0x1c0>
    80001c2e:	0000f517          	auipc	a0,0xf
    80001c32:	68a50513          	addi	a0,a0,1674 # 800112b8 <unused_lock>
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	f1e080e7          	jalr	-226(ra) # 80000b54 <initlock>
  initlock(&sleeping_lock, "sleeping");
    80001c3e:	00006597          	auipc	a1,0x6
    80001c42:	5ca58593          	addi	a1,a1,1482 # 80008208 <digits+0x1c8>
    80001c46:	0000f517          	auipc	a0,0xf
    80001c4a:	68a50513          	addi	a0,a0,1674 # 800112d0 <sleeping_lock>
    80001c4e:	fffff097          	auipc	ra,0xfffff
    80001c52:	f06080e7          	jalr	-250(ra) # 80000b54 <initlock>
  for (c = cpus; c < &cpus[NCPU]; c++)
    80001c56:	0000f497          	auipc	s1,0xf
    80001c5a:	71a48493          	addi	s1,s1,1818 # 80011370 <cpus+0x88>
    80001c5e:	00010a17          	auipc	s4,0x10
    80001c62:	c12a0a13          	addi	s4,s4,-1006 # 80011870 <proc+0x58>
  {
    c->runnable_head = -1;
    80001c66:	59fd                	li	s3,-1
    initlock(&c->head_lock, "runnable");
    80001c68:	00006917          	auipc	s2,0x6
    80001c6c:	5b090913          	addi	s2,s2,1456 # 80008218 <digits+0x1d8>
    c->runnable_head = -1;
    80001c70:	ff34ac23          	sw	s3,-8(s1)
    initlock(&c->head_lock, "runnable");
    80001c74:	85ca                	mv	a1,s2
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	edc080e7          	jalr	-292(ra) # 80000b54 <initlock>
  for (c = cpus; c < &cpus[NCPU]; c++)
    80001c80:	0a048493          	addi	s1,s1,160
    80001c84:	ff4496e3          	bne	s1,s4,80001c70 <init_locks+0x72>
  }
}
    80001c88:	70a2                	ld	ra,40(sp)
    80001c8a:	7402                	ld	s0,32(sp)
    80001c8c:	64e2                	ld	s1,24(sp)
    80001c8e:	6942                	ld	s2,16(sp)
    80001c90:	69a2                	ld	s3,8(sp)
    80001c92:	6a02                	ld	s4,0(sp)
    80001c94:	6145                	addi	sp,sp,48
    80001c96:	8082                	ret

0000000080001c98 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001c98:	7139                	addi	sp,sp,-64
    80001c9a:	fc06                	sd	ra,56(sp)
    80001c9c:	f822                	sd	s0,48(sp)
    80001c9e:	f426                	sd	s1,40(sp)
    80001ca0:	f04a                	sd	s2,32(sp)
    80001ca2:	ec4e                	sd	s3,24(sp)
    80001ca4:	e852                	sd	s4,16(sp)
    80001ca6:	e456                	sd	s5,8(sp)
    80001ca8:	e05a                	sd	s6,0(sp)
    80001caa:	0080                	addi	s0,sp,64
    80001cac:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001cae:	00010497          	auipc	s1,0x10
    80001cb2:	b6a48493          	addi	s1,s1,-1174 # 80011818 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001cb6:	8b26                	mv	s6,s1
    80001cb8:	00006a97          	auipc	s5,0x6
    80001cbc:	348a8a93          	addi	s5,s5,840 # 80008000 <etext>
    80001cc0:	04000937          	lui	s2,0x4000
    80001cc4:	197d                	addi	s2,s2,-1
    80001cc6:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001cc8:	00016a17          	auipc	s4,0x16
    80001ccc:	d50a0a13          	addi	s4,s4,-688 # 80017a18 <tickslock>
    char *pa = kalloc();
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	e24080e7          	jalr	-476(ra) # 80000af4 <kalloc>
    80001cd8:	862a                	mv	a2,a0
    if (pa == 0)
    80001cda:	c131                	beqz	a0,80001d1e <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001cdc:	416485b3          	sub	a1,s1,s6
    80001ce0:	858d                	srai	a1,a1,0x3
    80001ce2:	000ab783          	ld	a5,0(s5)
    80001ce6:	02f585b3          	mul	a1,a1,a5
    80001cea:	2585                	addiw	a1,a1,1
    80001cec:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001cf0:	4719                	li	a4,6
    80001cf2:	6685                	lui	a3,0x1
    80001cf4:	40b905b3          	sub	a1,s2,a1
    80001cf8:	854e                	mv	a0,s3
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	47a080e7          	jalr	1146(ra) # 80001174 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d02:	18848493          	addi	s1,s1,392
    80001d06:	fd4495e3          	bne	s1,s4,80001cd0 <proc_mapstacks+0x38>
  }
}
    80001d0a:	70e2                	ld	ra,56(sp)
    80001d0c:	7442                	ld	s0,48(sp)
    80001d0e:	74a2                	ld	s1,40(sp)
    80001d10:	7902                	ld	s2,32(sp)
    80001d12:	69e2                	ld	s3,24(sp)
    80001d14:	6a42                	ld	s4,16(sp)
    80001d16:	6aa2                	ld	s5,8(sp)
    80001d18:	6b02                	ld	s6,0(sp)
    80001d1a:	6121                	addi	sp,sp,64
    80001d1c:	8082                	ret
      panic("kalloc");
    80001d1e:	00006517          	auipc	a0,0x6
    80001d22:	50a50513          	addi	a0,a0,1290 # 80008228 <digits+0x1e8>
    80001d26:	fffff097          	auipc	ra,0xfffff
    80001d2a:	818080e7          	jalr	-2024(ra) # 8000053e <panic>

0000000080001d2e <procinit>:
//     }
// }

// initialize the proc table at boot time.
void procinit(void)
{
    80001d2e:	711d                	addi	sp,sp,-96
    80001d30:	ec86                	sd	ra,88(sp)
    80001d32:	e8a2                	sd	s0,80(sp)
    80001d34:	e4a6                	sd	s1,72(sp)
    80001d36:	e0ca                	sd	s2,64(sp)
    80001d38:	fc4e                	sd	s3,56(sp)
    80001d3a:	f852                	sd	s4,48(sp)
    80001d3c:	f456                	sd	s5,40(sp)
    80001d3e:	f05a                	sd	s6,32(sp)
    80001d40:	ec5e                	sd	s7,24(sp)
    80001d42:	e862                	sd	s8,16(sp)
    80001d44:	e466                	sd	s9,8(sp)
    80001d46:	e06a                	sd	s10,0(sp)
    80001d48:	1080                	addi	s0,sp,96
  init_locks();
    80001d4a:	00000097          	auipc	ra,0x0
    80001d4e:	eb4080e7          	jalr	-332(ra) # 80001bfe <init_locks>
  int i = 0;
  struct proc *p;
  initlock(&pid_lock, "nextpid");
    80001d52:	00006597          	auipc	a1,0x6
    80001d56:	4de58593          	addi	a1,a1,1246 # 80008230 <digits+0x1f0>
    80001d5a:	00010517          	auipc	a0,0x10
    80001d5e:	a8e50513          	addi	a0,a0,-1394 # 800117e8 <pid_lock>
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	df2080e7          	jalr	-526(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001d6a:	00006597          	auipc	a1,0x6
    80001d6e:	4ce58593          	addi	a1,a1,1230 # 80008238 <digits+0x1f8>
    80001d72:	00010517          	auipc	a0,0x10
    80001d76:	a8e50513          	addi	a0,a0,-1394 # 80011800 <wait_lock>
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	dda080e7          	jalr	-550(ra) # 80000b54 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d82:	00010497          	auipc	s1,0x10
    80001d86:	a9648493          	addi	s1,s1,-1386 # 80011818 <proc>
  int i = 0;
    80001d8a:	4901                	li	s2,0
  {
    initlock(&p->lock, "proc");
    80001d8c:	00006d17          	auipc	s10,0x6
    80001d90:	4bcd0d13          	addi	s10,s10,1212 # 80008248 <digits+0x208>
    initlock(&p->p_lock, "p_lock");
    80001d94:	00006c97          	auipc	s9,0x6
    80001d98:	4bcc8c93          	addi	s9,s9,1212 # 80008250 <digits+0x210>

    p->kstack = KSTACK((int)(p - proc));
    80001d9c:	8c26                	mv	s8,s1
    80001d9e:	00006b97          	auipc	s7,0x6
    80001da2:	262b8b93          	addi	s7,s7,610 # 80008000 <etext>
    80001da6:	040009b7          	lui	s3,0x4000
    80001daa:	19fd                	addi	s3,s3,-1
    80001dac:	09b2                	slli	s3,s3,0xc
    p->proc_idx = i;
    p->next = -1;
    80001dae:	5b7d                	li	s6,-1
    add_proc(&unused_head, p, &unused_lock);
    80001db0:	0000fa97          	auipc	s5,0xf
    80001db4:	508a8a93          	addi	s5,s5,1288 # 800112b8 <unused_lock>
    80001db8:	00007a17          	auipc	s4,0x7
    80001dbc:	abca0a13          	addi	s4,s4,-1348 # 80008874 <unused_head>
    initlock(&p->lock, "proc");
    80001dc0:	85ea                	mv	a1,s10
    80001dc2:	8526                	mv	a0,s1
    80001dc4:	fffff097          	auipc	ra,0xfffff
    80001dc8:	d90080e7          	jalr	-624(ra) # 80000b54 <initlock>
    initlock(&p->p_lock, "p_lock");
    80001dcc:	85e6                	mv	a1,s9
    80001dce:	03848513          	addi	a0,s1,56
    80001dd2:	fffff097          	auipc	ra,0xfffff
    80001dd6:	d82080e7          	jalr	-638(ra) # 80000b54 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    80001dda:	418487b3          	sub	a5,s1,s8
    80001dde:	878d                	srai	a5,a5,0x3
    80001de0:	000bb703          	ld	a4,0(s7)
    80001de4:	02e787b3          	mul	a5,a5,a4
    80001de8:	2785                	addiw	a5,a5,1
    80001dea:	00d7979b          	slliw	a5,a5,0xd
    80001dee:	40f987b3          	sub	a5,s3,a5
    80001df2:	f0bc                	sd	a5,96(s1)
    p->proc_idx = i;
    80001df4:	0524aa23          	sw	s2,84(s1)
    p->next = -1;
    80001df8:	0564a823          	sw	s6,80(s1)
    add_proc(&unused_head, p, &unused_lock);
    80001dfc:	8656                	mv	a2,s5
    80001dfe:	85a6                	mv	a1,s1
    80001e00:	8552                	mv	a0,s4
    80001e02:	00000097          	auipc	ra,0x0
    80001e06:	d5c080e7          	jalr	-676(ra) # 80001b5e <add_proc>
    i++;
    80001e0a:	2905                	addiw	s2,s2,1
  for (p = proc; p < &proc[NPROC]; p++)
    80001e0c:	18848493          	addi	s1,s1,392
    80001e10:	04000793          	li	a5,64
    80001e14:	faf916e3          	bne	s2,a5,80001dc0 <procinit+0x92>
  // {
  //   remove_proc(&unused_head, p, &unused_lock);
  //   printf("%d\n", p->proc_idx );
  // }
  //   printf("last %d\n", proc[unused_head].next);
}
    80001e18:	60e6                	ld	ra,88(sp)
    80001e1a:	6446                	ld	s0,80(sp)
    80001e1c:	64a6                	ld	s1,72(sp)
    80001e1e:	6906                	ld	s2,64(sp)
    80001e20:	79e2                	ld	s3,56(sp)
    80001e22:	7a42                	ld	s4,48(sp)
    80001e24:	7aa2                	ld	s5,40(sp)
    80001e26:	7b02                	ld	s6,32(sp)
    80001e28:	6be2                	ld	s7,24(sp)
    80001e2a:	6c42                	ld	s8,16(sp)
    80001e2c:	6ca2                	ld	s9,8(sp)
    80001e2e:	6d02                	ld	s10,0(sp)
    80001e30:	6125                	addi	sp,sp,96
    80001e32:	8082                	ret

0000000080001e34 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001e34:	1141                	addi	sp,sp,-16
    80001e36:	e422                	sd	s0,8(sp)
    80001e38:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e3a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001e3c:	2501                	sext.w	a0,a0
    80001e3e:	6422                	ld	s0,8(sp)
    80001e40:	0141                	addi	sp,sp,16
    80001e42:	8082                	ret

0000000080001e44 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001e44:	1141                	addi	sp,sp,-16
    80001e46:	e422                	sd	s0,8(sp)
    80001e48:	0800                	addi	s0,sp,16
    80001e4a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001e4c:	0007851b          	sext.w	a0,a5
    80001e50:	00251793          	slli	a5,a0,0x2
    80001e54:	97aa                	add	a5,a5,a0
    80001e56:	0796                	slli	a5,a5,0x5
  return c;
}
    80001e58:	0000f517          	auipc	a0,0xf
    80001e5c:	49050513          	addi	a0,a0,1168 # 800112e8 <cpus>
    80001e60:	953e                	add	a0,a0,a5
    80001e62:	6422                	ld	s0,8(sp)
    80001e64:	0141                	addi	sp,sp,16
    80001e66:	8082                	ret

0000000080001e68 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001e68:	1101                	addi	sp,sp,-32
    80001e6a:	ec06                	sd	ra,24(sp)
    80001e6c:	e822                	sd	s0,16(sp)
    80001e6e:	e426                	sd	s1,8(sp)
    80001e70:	1000                	addi	s0,sp,32
  push_off();
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d26080e7          	jalr	-730(ra) # 80000b98 <push_off>
    80001e7a:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001e7c:	0007871b          	sext.w	a4,a5
    80001e80:	00271793          	slli	a5,a4,0x2
    80001e84:	97ba                	add	a5,a5,a4
    80001e86:	0796                	slli	a5,a5,0x5
    80001e88:	0000f717          	auipc	a4,0xf
    80001e8c:	41870713          	addi	a4,a4,1048 # 800112a0 <zombie_lock>
    80001e90:	97ba                	add	a5,a5,a4
    80001e92:	67a4                	ld	s1,72(a5)
  pop_off();
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	db6080e7          	jalr	-586(ra) # 80000c4a <pop_off>
  return p;
}
    80001e9c:	8526                	mv	a0,s1
    80001e9e:	60e2                	ld	ra,24(sp)
    80001ea0:	6442                	ld	s0,16(sp)
    80001ea2:	64a2                	ld	s1,8(sp)
    80001ea4:	6105                	addi	sp,sp,32
    80001ea6:	8082                	ret

0000000080001ea8 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001ea8:	1141                	addi	sp,sp,-16
    80001eaa:	e406                	sd	ra,8(sp)
    80001eac:	e022                	sd	s0,0(sp)
    80001eae:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001eb0:	00000097          	auipc	ra,0x0
    80001eb4:	fb8080e7          	jalr	-72(ra) # 80001e68 <myproc>
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	df2080e7          	jalr	-526(ra) # 80000caa <release>

  if (first)
    80001ec0:	00007797          	auipc	a5,0x7
    80001ec4:	9b07a783          	lw	a5,-1616(a5) # 80008870 <first.1734>
    80001ec8:	eb89                	bnez	a5,80001eda <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001eca:	00001097          	auipc	ra,0x1
    80001ece:	e80080e7          	jalr	-384(ra) # 80002d4a <usertrapret>
}
    80001ed2:	60a2                	ld	ra,8(sp)
    80001ed4:	6402                	ld	s0,0(sp)
    80001ed6:	0141                	addi	sp,sp,16
    80001ed8:	8082                	ret
    first = 0;
    80001eda:	00007797          	auipc	a5,0x7
    80001ede:	9807ab23          	sw	zero,-1642(a5) # 80008870 <first.1734>
    fsinit(ROOTDEV);
    80001ee2:	4505                	li	a0,1
    80001ee4:	00002097          	auipc	ra,0x2
    80001ee8:	bf2080e7          	jalr	-1038(ra) # 80003ad6 <fsinit>
    80001eec:	bff9                	j	80001eca <forkret+0x22>

0000000080001eee <allocpid>:
{
    80001eee:	1101                	addi	sp,sp,-32
    80001ef0:	ec06                	sd	ra,24(sp)
    80001ef2:	e822                	sd	s0,16(sp)
    80001ef4:	e426                	sd	s1,8(sp)
    80001ef6:	e04a                	sd	s2,0(sp)
    80001ef8:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001efa:	00007917          	auipc	s2,0x7
    80001efe:	98690913          	addi	s2,s2,-1658 # 80008880 <nextpid>
    80001f02:	00092603          	lw	a2,0(s2)
    80001f06:	0006049b          	sext.w	s1,a2
  } while (cas(&nextpid, pid, pid + 1));
    80001f0a:	2605                	addiw	a2,a2,1
    80001f0c:	85a6                	mv	a1,s1
    80001f0e:	854a                	mv	a0,s2
    80001f10:	00005097          	auipc	ra,0x5
    80001f14:	9c6080e7          	jalr	-1594(ra) # 800068d6 <cas>
    80001f18:	f56d                	bnez	a0,80001f02 <allocpid+0x14>
}
    80001f1a:	8526                	mv	a0,s1
    80001f1c:	60e2                	ld	ra,24(sp)
    80001f1e:	6442                	ld	s0,16(sp)
    80001f20:	64a2                	ld	s1,8(sp)
    80001f22:	6902                	ld	s2,0(sp)
    80001f24:	6105                	addi	sp,sp,32
    80001f26:	8082                	ret

0000000080001f28 <proc_pagetable>:
{
    80001f28:	1101                	addi	sp,sp,-32
    80001f2a:	ec06                	sd	ra,24(sp)
    80001f2c:	e822                	sd	s0,16(sp)
    80001f2e:	e426                	sd	s1,8(sp)
    80001f30:	e04a                	sd	s2,0(sp)
    80001f32:	1000                	addi	s0,sp,32
    80001f34:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	428080e7          	jalr	1064(ra) # 8000135e <uvmcreate>
    80001f3e:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001f40:	c121                	beqz	a0,80001f80 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001f42:	4729                	li	a4,10
    80001f44:	00005697          	auipc	a3,0x5
    80001f48:	0bc68693          	addi	a3,a3,188 # 80007000 <_trampoline>
    80001f4c:	6605                	lui	a2,0x1
    80001f4e:	040005b7          	lui	a1,0x4000
    80001f52:	15fd                	addi	a1,a1,-1
    80001f54:	05b2                	slli	a1,a1,0xc
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	17e080e7          	jalr	382(ra) # 800010d4 <mappages>
    80001f5e:	02054863          	bltz	a0,80001f8e <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001f62:	4719                	li	a4,6
    80001f64:	07893683          	ld	a3,120(s2)
    80001f68:	6605                	lui	a2,0x1
    80001f6a:	020005b7          	lui	a1,0x2000
    80001f6e:	15fd                	addi	a1,a1,-1
    80001f70:	05b6                	slli	a1,a1,0xd
    80001f72:	8526                	mv	a0,s1
    80001f74:	fffff097          	auipc	ra,0xfffff
    80001f78:	160080e7          	jalr	352(ra) # 800010d4 <mappages>
    80001f7c:	02054163          	bltz	a0,80001f9e <proc_pagetable+0x76>
}
    80001f80:	8526                	mv	a0,s1
    80001f82:	60e2                	ld	ra,24(sp)
    80001f84:	6442                	ld	s0,16(sp)
    80001f86:	64a2                	ld	s1,8(sp)
    80001f88:	6902                	ld	s2,0(sp)
    80001f8a:	6105                	addi	sp,sp,32
    80001f8c:	8082                	ret
    uvmfree(pagetable, 0);
    80001f8e:	4581                	li	a1,0
    80001f90:	8526                	mv	a0,s1
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	5c8080e7          	jalr	1480(ra) # 8000155a <uvmfree>
    return 0;
    80001f9a:	4481                	li	s1,0
    80001f9c:	b7d5                	j	80001f80 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f9e:	4681                	li	a3,0
    80001fa0:	4605                	li	a2,1
    80001fa2:	040005b7          	lui	a1,0x4000
    80001fa6:	15fd                	addi	a1,a1,-1
    80001fa8:	05b2                	slli	a1,a1,0xc
    80001faa:	8526                	mv	a0,s1
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	2ee080e7          	jalr	750(ra) # 8000129a <uvmunmap>
    uvmfree(pagetable, 0);
    80001fb4:	4581                	li	a1,0
    80001fb6:	8526                	mv	a0,s1
    80001fb8:	fffff097          	auipc	ra,0xfffff
    80001fbc:	5a2080e7          	jalr	1442(ra) # 8000155a <uvmfree>
    return 0;
    80001fc0:	4481                	li	s1,0
    80001fc2:	bf7d                	j	80001f80 <proc_pagetable+0x58>

0000000080001fc4 <proc_freepagetable>:
{
    80001fc4:	1101                	addi	sp,sp,-32
    80001fc6:	ec06                	sd	ra,24(sp)
    80001fc8:	e822                	sd	s0,16(sp)
    80001fca:	e426                	sd	s1,8(sp)
    80001fcc:	e04a                	sd	s2,0(sp)
    80001fce:	1000                	addi	s0,sp,32
    80001fd0:	84aa                	mv	s1,a0
    80001fd2:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001fd4:	4681                	li	a3,0
    80001fd6:	4605                	li	a2,1
    80001fd8:	040005b7          	lui	a1,0x4000
    80001fdc:	15fd                	addi	a1,a1,-1
    80001fde:	05b2                	slli	a1,a1,0xc
    80001fe0:	fffff097          	auipc	ra,0xfffff
    80001fe4:	2ba080e7          	jalr	698(ra) # 8000129a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001fe8:	4681                	li	a3,0
    80001fea:	4605                	li	a2,1
    80001fec:	020005b7          	lui	a1,0x2000
    80001ff0:	15fd                	addi	a1,a1,-1
    80001ff2:	05b6                	slli	a1,a1,0xd
    80001ff4:	8526                	mv	a0,s1
    80001ff6:	fffff097          	auipc	ra,0xfffff
    80001ffa:	2a4080e7          	jalr	676(ra) # 8000129a <uvmunmap>
  uvmfree(pagetable, sz);
    80001ffe:	85ca                	mv	a1,s2
    80002000:	8526                	mv	a0,s1
    80002002:	fffff097          	auipc	ra,0xfffff
    80002006:	558080e7          	jalr	1368(ra) # 8000155a <uvmfree>
}
    8000200a:	60e2                	ld	ra,24(sp)
    8000200c:	6442                	ld	s0,16(sp)
    8000200e:	64a2                	ld	s1,8(sp)
    80002010:	6902                	ld	s2,0(sp)
    80002012:	6105                	addi	sp,sp,32
    80002014:	8082                	ret

0000000080002016 <freeproc>:
{
    80002016:	1101                	addi	sp,sp,-32
    80002018:	ec06                	sd	ra,24(sp)
    8000201a:	e822                	sd	s0,16(sp)
    8000201c:	e426                	sd	s1,8(sp)
    8000201e:	1000                	addi	s0,sp,32
    80002020:	84aa                	mv	s1,a0
  if (p->trapframe)
    80002022:	7d28                	ld	a0,120(a0)
    80002024:	c509                	beqz	a0,8000202e <freeproc+0x18>
    kfree((void *)p->trapframe);
    80002026:	fffff097          	auipc	ra,0xfffff
    8000202a:	9d2080e7          	jalr	-1582(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    8000202e:	0604bc23          	sd	zero,120(s1)
  if (p->pagetable)
    80002032:	78a8                	ld	a0,112(s1)
    80002034:	c511                	beqz	a0,80002040 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80002036:	74ac                	ld	a1,104(s1)
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	f8c080e7          	jalr	-116(ra) # 80001fc4 <proc_freepagetable>
  p->pagetable = 0;
    80002040:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80002044:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80002048:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    8000204c:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80002050:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80002054:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80002058:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    8000205c:	0204a623          	sw	zero,44(s1)
  remove_proc(&zombie_head, p, &zombie_lock);
    80002060:	0000f617          	auipc	a2,0xf
    80002064:	24060613          	addi	a2,a2,576 # 800112a0 <zombie_lock>
    80002068:	85a6                	mv	a1,s1
    8000206a:	00007517          	auipc	a0,0x7
    8000206e:	81250513          	addi	a0,a0,-2030 # 8000887c <zombie_head>
    80002072:	00000097          	auipc	ra,0x0
    80002076:	91c080e7          	jalr	-1764(ra) # 8000198e <remove_proc>
  p->state = UNUSED;
    8000207a:	0004ac23          	sw	zero,24(s1)
  add_proc(&unused_head, p, &unused_lock);
    8000207e:	0000f617          	auipc	a2,0xf
    80002082:	23a60613          	addi	a2,a2,570 # 800112b8 <unused_lock>
    80002086:	85a6                	mv	a1,s1
    80002088:	00006517          	auipc	a0,0x6
    8000208c:	7ec50513          	addi	a0,a0,2028 # 80008874 <unused_head>
    80002090:	00000097          	auipc	ra,0x0
    80002094:	ace080e7          	jalr	-1330(ra) # 80001b5e <add_proc>
}
    80002098:	60e2                	ld	ra,24(sp)
    8000209a:	6442                	ld	s0,16(sp)
    8000209c:	64a2                	ld	s1,8(sp)
    8000209e:	6105                	addi	sp,sp,32
    800020a0:	8082                	ret

00000000800020a2 <allocproc>:
{
    800020a2:	7179                	addi	sp,sp,-48
    800020a4:	f406                	sd	ra,40(sp)
    800020a6:	f022                	sd	s0,32(sp)
    800020a8:	ec26                	sd	s1,24(sp)
    800020aa:	e84a                	sd	s2,16(sp)
    800020ac:	e44e                	sd	s3,8(sp)
    800020ae:	e052                	sd	s4,0(sp)
    800020b0:	1800                	addi	s0,sp,48
  if (unused_head != -1)
    800020b2:	00006917          	auipc	s2,0x6
    800020b6:	7c292903          	lw	s2,1986(s2) # 80008874 <unused_head>
    800020ba:	57fd                	li	a5,-1
  return 0;
    800020bc:	4481                	li	s1,0
  if (unused_head != -1)
    800020be:	0af90b63          	beq	s2,a5,80002174 <allocproc+0xd2>
    p = &proc[unused_head];
    800020c2:	18800993          	li	s3,392
    800020c6:	033909b3          	mul	s3,s2,s3
    800020ca:	0000f497          	auipc	s1,0xf
    800020ce:	74e48493          	addi	s1,s1,1870 # 80011818 <proc>
    800020d2:	94ce                	add	s1,s1,s3
    acquire(&p->lock);
    800020d4:	8526                	mv	a0,s1
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	b0e080e7          	jalr	-1266(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	e10080e7          	jalr	-496(ra) # 80001eee <allocpid>
    800020e6:	d888                	sw	a0,48(s1)
  remove_proc(&unused_head, p, &unused_lock);
    800020e8:	0000f617          	auipc	a2,0xf
    800020ec:	1d060613          	addi	a2,a2,464 # 800112b8 <unused_lock>
    800020f0:	85a6                	mv	a1,s1
    800020f2:	00006517          	auipc	a0,0x6
    800020f6:	78250513          	addi	a0,a0,1922 # 80008874 <unused_head>
    800020fa:	00000097          	auipc	ra,0x0
    800020fe:	894080e7          	jalr	-1900(ra) # 8000198e <remove_proc>
  p->state = USED;
    80002102:	4785                	li	a5,1
    80002104:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80002106:	fffff097          	auipc	ra,0xfffff
    8000210a:	9ee080e7          	jalr	-1554(ra) # 80000af4 <kalloc>
    8000210e:	8a2a                	mv	s4,a0
    80002110:	fca8                	sd	a0,120(s1)
    80002112:	c935                	beqz	a0,80002186 <allocproc+0xe4>
  p->pagetable = proc_pagetable(p);
    80002114:	8526                	mv	a0,s1
    80002116:	00000097          	auipc	ra,0x0
    8000211a:	e12080e7          	jalr	-494(ra) # 80001f28 <proc_pagetable>
    8000211e:	8a2a                	mv	s4,a0
    80002120:	18800793          	li	a5,392
    80002124:	02f90733          	mul	a4,s2,a5
    80002128:	0000f797          	auipc	a5,0xf
    8000212c:	6f078793          	addi	a5,a5,1776 # 80011818 <proc>
    80002130:	97ba                	add	a5,a5,a4
    80002132:	fba8                	sd	a0,112(a5)
  if (p->pagetable == 0)
    80002134:	c52d                	beqz	a0,8000219e <allocproc+0xfc>
  memset(&p->context, 0, sizeof(p->context));
    80002136:	08098513          	addi	a0,s3,128 # 4000080 <_entry-0x7bffff80>
    8000213a:	0000fa17          	auipc	s4,0xf
    8000213e:	6dea0a13          	addi	s4,s4,1758 # 80011818 <proc>
    80002142:	07000613          	li	a2,112
    80002146:	4581                	li	a1,0
    80002148:	9552                	add	a0,a0,s4
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	bba080e7          	jalr	-1094(ra) # 80000d04 <memset>
  p->context.ra = (uint64)forkret;
    80002152:	18800793          	li	a5,392
    80002156:	02f90933          	mul	s2,s2,a5
    8000215a:	9952                	add	s2,s2,s4
    8000215c:	00000797          	auipc	a5,0x0
    80002160:	d4c78793          	addi	a5,a5,-692 # 80001ea8 <forkret>
    80002164:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002168:	06093783          	ld	a5,96(s2)
    8000216c:	6705                	lui	a4,0x1
    8000216e:	97ba                	add	a5,a5,a4
    80002170:	08f93423          	sd	a5,136(s2)
}
    80002174:	8526                	mv	a0,s1
    80002176:	70a2                	ld	ra,40(sp)
    80002178:	7402                	ld	s0,32(sp)
    8000217a:	64e2                	ld	s1,24(sp)
    8000217c:	6942                	ld	s2,16(sp)
    8000217e:	69a2                	ld	s3,8(sp)
    80002180:	6a02                	ld	s4,0(sp)
    80002182:	6145                	addi	sp,sp,48
    80002184:	8082                	ret
    freeproc(p);
    80002186:	8526                	mv	a0,s1
    80002188:	00000097          	auipc	ra,0x0
    8000218c:	e8e080e7          	jalr	-370(ra) # 80002016 <freeproc>
    release(&p->lock);
    80002190:	8526                	mv	a0,s1
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	b18080e7          	jalr	-1256(ra) # 80000caa <release>
    return 0;
    8000219a:	84d2                	mv	s1,s4
    8000219c:	bfe1                	j	80002174 <allocproc+0xd2>
    freeproc(p);
    8000219e:	8526                	mv	a0,s1
    800021a0:	00000097          	auipc	ra,0x0
    800021a4:	e76080e7          	jalr	-394(ra) # 80002016 <freeproc>
    release(&p->lock);
    800021a8:	8526                	mv	a0,s1
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	b00080e7          	jalr	-1280(ra) # 80000caa <release>
    return 0;
    800021b2:	84d2                	mv	s1,s4
    800021b4:	b7c1                	j	80002174 <allocproc+0xd2>

00000000800021b6 <userinit>:
{
    800021b6:	1101                	addi	sp,sp,-32
    800021b8:	ec06                	sd	ra,24(sp)
    800021ba:	e822                	sd	s0,16(sp)
    800021bc:	e426                	sd	s1,8(sp)
    800021be:	1000                	addi	s0,sp,32
  p = allocproc();
    800021c0:	00000097          	auipc	ra,0x0
    800021c4:	ee2080e7          	jalr	-286(ra) # 800020a2 <allocproc>
    800021c8:	84aa                	mv	s1,a0
  initproc = p;
    800021ca:	00007797          	auipc	a5,0x7
    800021ce:	e4a7bf23          	sd	a0,-418(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800021d2:	03400613          	li	a2,52
    800021d6:	00006597          	auipc	a1,0x6
    800021da:	6ba58593          	addi	a1,a1,1722 # 80008890 <initcode>
    800021de:	7928                	ld	a0,112(a0)
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	1ac080e7          	jalr	428(ra) # 8000138c <uvminit>
  p->sz = PGSIZE;
    800021e8:	6785                	lui	a5,0x1
    800021ea:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;     // user program counter
    800021ec:	7cb8                	ld	a4,120(s1)
    800021ee:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    800021f2:	7cb8                	ld	a4,120(s1)
    800021f4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800021f6:	4641                	li	a2,16
    800021f8:	00006597          	auipc	a1,0x6
    800021fc:	06058593          	addi	a1,a1,96 # 80008258 <digits+0x218>
    80002200:	17848513          	addi	a0,s1,376
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	c52080e7          	jalr	-942(ra) # 80000e56 <safestrcpy>
  p->cwd = namei("/");
    8000220c:	00006517          	auipc	a0,0x6
    80002210:	05c50513          	addi	a0,a0,92 # 80008268 <digits+0x228>
    80002214:	00002097          	auipc	ra,0x2
    80002218:	2f0080e7          	jalr	752(ra) # 80004504 <namei>
    8000221c:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80002220:	478d                	li	a5,3
    80002222:	cc9c                	sw	a5,24(s1)
  add_proc(&cpus[0].runnable_head, p, &cpus[0].head_lock);
    80002224:	0000f617          	auipc	a2,0xf
    80002228:	14c60613          	addi	a2,a2,332 # 80011370 <cpus+0x88>
    8000222c:	85a6                	mv	a1,s1
    8000222e:	0000f517          	auipc	a0,0xf
    80002232:	13a50513          	addi	a0,a0,314 # 80011368 <cpus+0x80>
    80002236:	00000097          	auipc	ra,0x0
    8000223a:	928080e7          	jalr	-1752(ra) # 80001b5e <add_proc>
  release(&p->lock);
    8000223e:	8526                	mv	a0,s1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	a6a080e7          	jalr	-1430(ra) # 80000caa <release>
}
    80002248:	60e2                	ld	ra,24(sp)
    8000224a:	6442                	ld	s0,16(sp)
    8000224c:	64a2                	ld	s1,8(sp)
    8000224e:	6105                	addi	sp,sp,32
    80002250:	8082                	ret

0000000080002252 <growproc>:
{
    80002252:	1101                	addi	sp,sp,-32
    80002254:	ec06                	sd	ra,24(sp)
    80002256:	e822                	sd	s0,16(sp)
    80002258:	e426                	sd	s1,8(sp)
    8000225a:	e04a                	sd	s2,0(sp)
    8000225c:	1000                	addi	s0,sp,32
    8000225e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002260:	00000097          	auipc	ra,0x0
    80002264:	c08080e7          	jalr	-1016(ra) # 80001e68 <myproc>
    80002268:	892a                	mv	s2,a0
  sz = p->sz;
    8000226a:	752c                	ld	a1,104(a0)
    8000226c:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80002270:	00904f63          	bgtz	s1,8000228e <growproc+0x3c>
  else if (n < 0)
    80002274:	0204cc63          	bltz	s1,800022ac <growproc+0x5a>
  p->sz = sz;
    80002278:	1602                	slli	a2,a2,0x20
    8000227a:	9201                	srli	a2,a2,0x20
    8000227c:	06c93423          	sd	a2,104(s2)
  return 0;
    80002280:	4501                	li	a0,0
}
    80002282:	60e2                	ld	ra,24(sp)
    80002284:	6442                	ld	s0,16(sp)
    80002286:	64a2                	ld	s1,8(sp)
    80002288:	6902                	ld	s2,0(sp)
    8000228a:	6105                	addi	sp,sp,32
    8000228c:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    8000228e:	9e25                	addw	a2,a2,s1
    80002290:	1602                	slli	a2,a2,0x20
    80002292:	9201                	srli	a2,a2,0x20
    80002294:	1582                	slli	a1,a1,0x20
    80002296:	9181                	srli	a1,a1,0x20
    80002298:	7928                	ld	a0,112(a0)
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	1ac080e7          	jalr	428(ra) # 80001446 <uvmalloc>
    800022a2:	0005061b          	sext.w	a2,a0
    800022a6:	fa69                	bnez	a2,80002278 <growproc+0x26>
      return -1;
    800022a8:	557d                	li	a0,-1
    800022aa:	bfe1                	j	80002282 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800022ac:	9e25                	addw	a2,a2,s1
    800022ae:	1602                	slli	a2,a2,0x20
    800022b0:	9201                	srli	a2,a2,0x20
    800022b2:	1582                	slli	a1,a1,0x20
    800022b4:	9181                	srli	a1,a1,0x20
    800022b6:	7928                	ld	a0,112(a0)
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	146080e7          	jalr	326(ra) # 800013fe <uvmdealloc>
    800022c0:	0005061b          	sext.w	a2,a0
    800022c4:	bf55                	j	80002278 <growproc+0x26>

00000000800022c6 <fork>:
{
    800022c6:	7179                	addi	sp,sp,-48
    800022c8:	f406                	sd	ra,40(sp)
    800022ca:	f022                	sd	s0,32(sp)
    800022cc:	ec26                	sd	s1,24(sp)
    800022ce:	e84a                	sd	s2,16(sp)
    800022d0:	e44e                	sd	s3,8(sp)
    800022d2:	e052                	sd	s4,0(sp)
    800022d4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022d6:	00000097          	auipc	ra,0x0
    800022da:	b92080e7          	jalr	-1134(ra) # 80001e68 <myproc>
    800022de:	89aa                	mv	s3,a0
  if ((np = allocproc()) == 0)
    800022e0:	00000097          	auipc	ra,0x0
    800022e4:	dc2080e7          	jalr	-574(ra) # 800020a2 <allocproc>
    800022e8:	14050763          	beqz	a0,80002436 <fork+0x170>
    800022ec:	892a                	mv	s2,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    800022ee:	0689b603          	ld	a2,104(s3)
    800022f2:	792c                	ld	a1,112(a0)
    800022f4:	0709b503          	ld	a0,112(s3)
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	29a080e7          	jalr	666(ra) # 80001592 <uvmcopy>
    80002300:	04054663          	bltz	a0,8000234c <fork+0x86>
  np->sz = p->sz;
    80002304:	0689b783          	ld	a5,104(s3)
    80002308:	06f93423          	sd	a5,104(s2)
  *(np->trapframe) = *(p->trapframe);
    8000230c:	0789b683          	ld	a3,120(s3)
    80002310:	87b6                	mv	a5,a3
    80002312:	07893703          	ld	a4,120(s2)
    80002316:	12068693          	addi	a3,a3,288
    8000231a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000231e:	6788                	ld	a0,8(a5)
    80002320:	6b8c                	ld	a1,16(a5)
    80002322:	6f90                	ld	a2,24(a5)
    80002324:	01073023          	sd	a6,0(a4)
    80002328:	e708                	sd	a0,8(a4)
    8000232a:	eb0c                	sd	a1,16(a4)
    8000232c:	ef10                	sd	a2,24(a4)
    8000232e:	02078793          	addi	a5,a5,32
    80002332:	02070713          	addi	a4,a4,32
    80002336:	fed792e3          	bne	a5,a3,8000231a <fork+0x54>
  np->trapframe->a0 = 0;
    8000233a:	07893783          	ld	a5,120(s2)
    8000233e:	0607b823          	sd	zero,112(a5)
    80002342:	0f000493          	li	s1,240
  for (i = 0; i < NOFILE; i++)
    80002346:	17000a13          	li	s4,368
    8000234a:	a03d                	j	80002378 <fork+0xb2>
    freeproc(np);
    8000234c:	854a                	mv	a0,s2
    8000234e:	00000097          	auipc	ra,0x0
    80002352:	cc8080e7          	jalr	-824(ra) # 80002016 <freeproc>
    release(&np->lock);
    80002356:	854a                	mv	a0,s2
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	952080e7          	jalr	-1710(ra) # 80000caa <release>
    return -1;
    80002360:	54fd                	li	s1,-1
    80002362:	a0c9                	j	80002424 <fork+0x15e>
      np->ofile[i] = filedup(p->ofile[i]);
    80002364:	00003097          	auipc	ra,0x3
    80002368:	836080e7          	jalr	-1994(ra) # 80004b9a <filedup>
    8000236c:	009907b3          	add	a5,s2,s1
    80002370:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80002372:	04a1                	addi	s1,s1,8
    80002374:	01448763          	beq	s1,s4,80002382 <fork+0xbc>
    if (p->ofile[i])
    80002378:	009987b3          	add	a5,s3,s1
    8000237c:	6388                	ld	a0,0(a5)
    8000237e:	f17d                	bnez	a0,80002364 <fork+0x9e>
    80002380:	bfcd                	j	80002372 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002382:	1709b503          	ld	a0,368(s3)
    80002386:	00002097          	auipc	ra,0x2
    8000238a:	98a080e7          	jalr	-1654(ra) # 80003d10 <idup>
    8000238e:	16a93823          	sd	a0,368(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002392:	4641                	li	a2,16
    80002394:	17898593          	addi	a1,s3,376
    80002398:	17890513          	addi	a0,s2,376
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	aba080e7          	jalr	-1350(ra) # 80000e56 <safestrcpy>
  pid = np->pid;
    800023a4:	03092483          	lw	s1,48(s2)
  release(&np->lock);
    800023a8:	854a                	mv	a0,s2
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	900080e7          	jalr	-1792(ra) # 80000caa <release>
  acquire(&wait_lock);
    800023b2:	0000fa17          	auipc	s4,0xf
    800023b6:	44ea0a13          	addi	s4,s4,1102 # 80011800 <wait_lock>
    800023ba:	8552                	mv	a0,s4
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	828080e7          	jalr	-2008(ra) # 80000be4 <acquire>
  np->parent = p;
    800023c4:	05393c23          	sd	s3,88(s2)
  np->cpu = p->cpu; // need to modify later (q.4)
    800023c8:	0349a783          	lw	a5,52(s3)
    800023cc:	2781                	sext.w	a5,a5
    800023ce:	02f92a23          	sw	a5,52(s2)
  release(&wait_lock);
    800023d2:	8552                	mv	a0,s4
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	8d6080e7          	jalr	-1834(ra) # 80000caa <release>
  acquire(&np->lock);
    800023dc:	854a                	mv	a0,s2
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	806080e7          	jalr	-2042(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800023e6:	478d                	li	a5,3
    800023e8:	00f92c23          	sw	a5,24(s2)
  struct cpu *c = &cpus[np->cpu]; // is p and np must be in the same cpu?
    800023ec:	03492783          	lw	a5,52(s2)
    800023f0:	0007871b          	sext.w	a4,a5
  add_proc(&c->runnable_head, np, &c->head_lock);
    800023f4:	00271793          	slli	a5,a4,0x2
    800023f8:	97ba                	add	a5,a5,a4
    800023fa:	0796                	slli	a5,a5,0x5
    800023fc:	0000f517          	auipc	a0,0xf
    80002400:	eec50513          	addi	a0,a0,-276 # 800112e8 <cpus>
    80002404:	08878613          	addi	a2,a5,136
    80002408:	08078793          	addi	a5,a5,128
    8000240c:	962a                	add	a2,a2,a0
    8000240e:	85ca                	mv	a1,s2
    80002410:	953e                	add	a0,a0,a5
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	74c080e7          	jalr	1868(ra) # 80001b5e <add_proc>
  release(&np->lock);
    8000241a:	854a                	mv	a0,s2
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	88e080e7          	jalr	-1906(ra) # 80000caa <release>
}
    80002424:	8526                	mv	a0,s1
    80002426:	70a2                	ld	ra,40(sp)
    80002428:	7402                	ld	s0,32(sp)
    8000242a:	64e2                	ld	s1,24(sp)
    8000242c:	6942                	ld	s2,16(sp)
    8000242e:	69a2                	ld	s3,8(sp)
    80002430:	6a02                	ld	s4,0(sp)
    80002432:	6145                	addi	sp,sp,48
    80002434:	8082                	ret
    return -1;
    80002436:	54fd                	li	s1,-1
    80002438:	b7f5                	j	80002424 <fork+0x15e>

000000008000243a <scheduler>:
{
    8000243a:	711d                	addi	sp,sp,-96
    8000243c:	ec86                	sd	ra,88(sp)
    8000243e:	e8a2                	sd	s0,80(sp)
    80002440:	e4a6                	sd	s1,72(sp)
    80002442:	e0ca                	sd	s2,64(sp)
    80002444:	fc4e                	sd	s3,56(sp)
    80002446:	f852                	sd	s4,48(sp)
    80002448:	f456                	sd	s5,40(sp)
    8000244a:	f05a                	sd	s6,32(sp)
    8000244c:	ec5e                	sd	s7,24(sp)
    8000244e:	e862                	sd	s8,16(sp)
    80002450:	e466                	sd	s9,8(sp)
    80002452:	e06a                	sd	s10,0(sp)
    80002454:	1080                	addi	s0,sp,96
    80002456:	8712                	mv	a4,tp
  int id = r_tp();
    80002458:	2701                	sext.w	a4,a4
  c->proc = 0;
    8000245a:	00271793          	slli	a5,a4,0x2
    8000245e:	00e786b3          	add	a3,a5,a4
    80002462:	00569613          	slli	a2,a3,0x5
    80002466:	0000f697          	auipc	a3,0xf
    8000246a:	e3a68693          	addi	a3,a3,-454 # 800112a0 <zombie_lock>
    8000246e:	96b2                	add	a3,a3,a2
    80002470:	0406b423          	sd	zero,72(a3)
    int proc_to_run = remove_first(&c->runnable_head, &c->head_lock);
    80002474:	0000fb97          	auipc	s7,0xf
    80002478:	e74b8b93          	addi	s7,s7,-396 # 800112e8 <cpus>
    8000247c:	08060993          	addi	s3,a2,128
    80002480:	99de                	add	s3,s3,s7
    80002482:	08860913          	addi	s2,a2,136
    80002486:	995e                	add	s2,s2,s7
      swtch(&c->context, &p->context);
    80002488:	00860793          	addi	a5,a2,8
    8000248c:	9bbe                	add	s7,s7,a5
    if (proc_to_run != -1)
    8000248e:	5a7d                	li	s4,-1
    80002490:	18800c93          	li	s9,392
      p = &proc[proc_to_run];
    80002494:	0000fb17          	auipc	s6,0xf
    80002498:	384b0b13          	addi	s6,s6,900 # 80011818 <proc>
      p->state = RUNNING;
    8000249c:	4c11                	li	s8,4
      c->proc = p;
    8000249e:	8ab6                	mv	s5,a3
    800024a0:	a82d                	j	800024da <scheduler+0xa0>
      p = &proc[proc_to_run];
    800024a2:	039504b3          	mul	s1,a0,s9
    800024a6:	01648d33          	add	s10,s1,s6
      acquire(&p->lock);
    800024aa:	856a                	mv	a0,s10
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	738080e7          	jalr	1848(ra) # 80000be4 <acquire>
      p->state = RUNNING;
    800024b4:	018d2c23          	sw	s8,24(s10)
      c->proc = p;
    800024b8:	05aab423          	sd	s10,72(s5)
      swtch(&c->context, &p->context);
    800024bc:	08048593          	addi	a1,s1,128
    800024c0:	95da                	add	a1,a1,s6
    800024c2:	855e                	mv	a0,s7
    800024c4:	00000097          	auipc	ra,0x0
    800024c8:	7dc080e7          	jalr	2012(ra) # 80002ca0 <swtch>
      c->proc = 0;
    800024cc:	040ab423          	sd	zero,72(s5)
      release(&p->lock);
    800024d0:	856a                	mv	a0,s10
    800024d2:	ffffe097          	auipc	ra,0xffffe
    800024d6:	7d8080e7          	jalr	2008(ra) # 80000caa <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800024da:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800024de:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800024e2:	10079073          	csrw	sstatus,a5
    int proc_to_run = remove_first(&c->runnable_head, &c->head_lock);
    800024e6:	85ca                	mv	a1,s2
    800024e8:	854e                	mv	a0,s3
    800024ea:	fffff097          	auipc	ra,0xfffff
    800024ee:	566080e7          	jalr	1382(ra) # 80001a50 <remove_first>
    if (proc_to_run != -1)
    800024f2:	ff4504e3          	beq	a0,s4,800024da <scheduler+0xa0>
    800024f6:	b775                	j	800024a2 <scheduler+0x68>

00000000800024f8 <sched>:
{
    800024f8:	7179                	addi	sp,sp,-48
    800024fa:	f406                	sd	ra,40(sp)
    800024fc:	f022                	sd	s0,32(sp)
    800024fe:	ec26                	sd	s1,24(sp)
    80002500:	e84a                	sd	s2,16(sp)
    80002502:	e44e                	sd	s3,8(sp)
    80002504:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002506:	00000097          	auipc	ra,0x0
    8000250a:	962080e7          	jalr	-1694(ra) # 80001e68 <myproc>
    8000250e:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002510:	ffffe097          	auipc	ra,0xffffe
    80002514:	65a080e7          	jalr	1626(ra) # 80000b6a <holding>
    80002518:	c959                	beqz	a0,800025ae <sched+0xb6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000251a:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    8000251c:	0007871b          	sext.w	a4,a5
    80002520:	00271793          	slli	a5,a4,0x2
    80002524:	97ba                	add	a5,a5,a4
    80002526:	0796                	slli	a5,a5,0x5
    80002528:	0000f717          	auipc	a4,0xf
    8000252c:	d7870713          	addi	a4,a4,-648 # 800112a0 <zombie_lock>
    80002530:	97ba                	add	a5,a5,a4
    80002532:	0c07a703          	lw	a4,192(a5)
    80002536:	4785                	li	a5,1
    80002538:	08f71363          	bne	a4,a5,800025be <sched+0xc6>
  if (p->state == RUNNING)
    8000253c:	4c98                	lw	a4,24(s1)
    8000253e:	4791                	li	a5,4
    80002540:	08f70763          	beq	a4,a5,800025ce <sched+0xd6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002544:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002548:	8b89                	andi	a5,a5,2
  if (intr_get())
    8000254a:	ebd1                	bnez	a5,800025de <sched+0xe6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000254c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000254e:	0000f917          	auipc	s2,0xf
    80002552:	d5290913          	addi	s2,s2,-686 # 800112a0 <zombie_lock>
    80002556:	0007871b          	sext.w	a4,a5
    8000255a:	00271793          	slli	a5,a4,0x2
    8000255e:	97ba                	add	a5,a5,a4
    80002560:	0796                	slli	a5,a5,0x5
    80002562:	97ca                	add	a5,a5,s2
    80002564:	0c47a983          	lw	s3,196(a5)
    80002568:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000256a:	0007859b          	sext.w	a1,a5
    8000256e:	00259793          	slli	a5,a1,0x2
    80002572:	97ae                	add	a5,a5,a1
    80002574:	0796                	slli	a5,a5,0x5
    80002576:	0000f597          	auipc	a1,0xf
    8000257a:	d7a58593          	addi	a1,a1,-646 # 800112f0 <cpus+0x8>
    8000257e:	95be                	add	a1,a1,a5
    80002580:	08048513          	addi	a0,s1,128
    80002584:	00000097          	auipc	ra,0x0
    80002588:	71c080e7          	jalr	1820(ra) # 80002ca0 <swtch>
    8000258c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000258e:	0007871b          	sext.w	a4,a5
    80002592:	00271793          	slli	a5,a4,0x2
    80002596:	97ba                	add	a5,a5,a4
    80002598:	0796                	slli	a5,a5,0x5
    8000259a:	97ca                	add	a5,a5,s2
    8000259c:	0d37a223          	sw	s3,196(a5)
}
    800025a0:	70a2                	ld	ra,40(sp)
    800025a2:	7402                	ld	s0,32(sp)
    800025a4:	64e2                	ld	s1,24(sp)
    800025a6:	6942                	ld	s2,16(sp)
    800025a8:	69a2                	ld	s3,8(sp)
    800025aa:	6145                	addi	sp,sp,48
    800025ac:	8082                	ret
    panic("sched p->lock");
    800025ae:	00006517          	auipc	a0,0x6
    800025b2:	cc250513          	addi	a0,a0,-830 # 80008270 <digits+0x230>
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	f88080e7          	jalr	-120(ra) # 8000053e <panic>
    panic("sched locks");
    800025be:	00006517          	auipc	a0,0x6
    800025c2:	cc250513          	addi	a0,a0,-830 # 80008280 <digits+0x240>
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	f78080e7          	jalr	-136(ra) # 8000053e <panic>
    panic("sched running");
    800025ce:	00006517          	auipc	a0,0x6
    800025d2:	cc250513          	addi	a0,a0,-830 # 80008290 <digits+0x250>
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	f68080e7          	jalr	-152(ra) # 8000053e <panic>
    panic("sched interruptible");
    800025de:	00006517          	auipc	a0,0x6
    800025e2:	cc250513          	addi	a0,a0,-830 # 800082a0 <digits+0x260>
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	f58080e7          	jalr	-168(ra) # 8000053e <panic>

00000000800025ee <yield>:
{
    800025ee:	1101                	addi	sp,sp,-32
    800025f0:	ec06                	sd	ra,24(sp)
    800025f2:	e822                	sd	s0,16(sp)
    800025f4:	e426                	sd	s1,8(sp)
    800025f6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800025f8:	00000097          	auipc	ra,0x0
    800025fc:	870080e7          	jalr	-1936(ra) # 80001e68 <myproc>
    80002600:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002602:	ffffe097          	auipc	ra,0xffffe
    80002606:	5e2080e7          	jalr	1506(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000260a:	478d                	li	a5,3
    8000260c:	cc9c                	sw	a5,24(s1)
  struct cpu *c = &cpus[p->cpu];
    8000260e:	58dc                	lw	a5,52(s1)
    80002610:	0007851b          	sext.w	a0,a5
  add_proc(&c->runnable_head, p, &c->head_lock);
    80002614:	00251793          	slli	a5,a0,0x2
    80002618:	97aa                	add	a5,a5,a0
    8000261a:	0796                	slli	a5,a5,0x5
    8000261c:	0000f517          	auipc	a0,0xf
    80002620:	ccc50513          	addi	a0,a0,-820 # 800112e8 <cpus>
    80002624:	08878613          	addi	a2,a5,136
    80002628:	08078793          	addi	a5,a5,128
    8000262c:	962a                	add	a2,a2,a0
    8000262e:	85a6                	mv	a1,s1
    80002630:	953e                	add	a0,a0,a5
    80002632:	fffff097          	auipc	ra,0xfffff
    80002636:	52c080e7          	jalr	1324(ra) # 80001b5e <add_proc>
  sched();
    8000263a:	00000097          	auipc	ra,0x0
    8000263e:	ebe080e7          	jalr	-322(ra) # 800024f8 <sched>
  release(&p->lock);
    80002642:	8526                	mv	a0,s1
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	666080e7          	jalr	1638(ra) # 80000caa <release>
}
    8000264c:	60e2                	ld	ra,24(sp)
    8000264e:	6442                	ld	s0,16(sp)
    80002650:	64a2                	ld	s1,8(sp)
    80002652:	6105                	addi	sp,sp,32
    80002654:	8082                	ret

0000000080002656 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002656:	7179                	addi	sp,sp,-48
    80002658:	f406                	sd	ra,40(sp)
    8000265a:	f022                	sd	s0,32(sp)
    8000265c:	ec26                	sd	s1,24(sp)
    8000265e:	e84a                	sd	s2,16(sp)
    80002660:	e44e                	sd	s3,8(sp)
    80002662:	1800                	addi	s0,sp,48
    80002664:	89aa                	mv	s3,a0
    80002666:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002668:	00000097          	auipc	ra,0x0
    8000266c:	800080e7          	jalr	-2048(ra) # 80001e68 <myproc>
    80002670:	84aa                	mv	s1,a0
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.
  acquire(&p->lock); // DOC: sleeplock1
    80002672:	ffffe097          	auipc	ra,0xffffe
    80002676:	572080e7          	jalr	1394(ra) # 80000be4 <acquire>


  add_proc(&sleeping_head, p, &sleeping_lock);
    8000267a:	0000f617          	auipc	a2,0xf
    8000267e:	c5660613          	addi	a2,a2,-938 # 800112d0 <sleeping_lock>
    80002682:	85a6                	mv	a1,s1
    80002684:	00006517          	auipc	a0,0x6
    80002688:	1f450513          	addi	a0,a0,500 # 80008878 <sleeping_head>
    8000268c:	fffff097          	auipc	ra,0xfffff
    80002690:	4d2080e7          	jalr	1234(ra) # 80001b5e <add_proc>
  release(lk);
    80002694:	854a                	mv	a0,s2
    80002696:	ffffe097          	auipc	ra,0xffffe
    8000269a:	614080e7          	jalr	1556(ra) # 80000caa <release>
  p->chan = chan;
    8000269e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800026a2:	4789                	li	a5,2
    800026a4:	cc9c                	sw	a5,24(s1)

  // Go to sleep.

  sched();
    800026a6:	00000097          	auipc	ra,0x0
    800026aa:	e52080e7          	jalr	-430(ra) # 800024f8 <sched>

  // Tidy up.
  p->chan = 0;
    800026ae:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800026b2:	8526                	mv	a0,s1
    800026b4:	ffffe097          	auipc	ra,0xffffe
    800026b8:	5f6080e7          	jalr	1526(ra) # 80000caa <release>
  acquire(lk);
    800026bc:	854a                	mv	a0,s2
    800026be:	ffffe097          	auipc	ra,0xffffe
    800026c2:	526080e7          	jalr	1318(ra) # 80000be4 <acquire>
}
    800026c6:	70a2                	ld	ra,40(sp)
    800026c8:	7402                	ld	s0,32(sp)
    800026ca:	64e2                	ld	s1,24(sp)
    800026cc:	6942                	ld	s2,16(sp)
    800026ce:	69a2                	ld	s3,8(sp)
    800026d0:	6145                	addi	sp,sp,48
    800026d2:	8082                	ret

00000000800026d4 <wait>:
{
    800026d4:	715d                	addi	sp,sp,-80
    800026d6:	e486                	sd	ra,72(sp)
    800026d8:	e0a2                	sd	s0,64(sp)
    800026da:	fc26                	sd	s1,56(sp)
    800026dc:	f84a                	sd	s2,48(sp)
    800026de:	f44e                	sd	s3,40(sp)
    800026e0:	f052                	sd	s4,32(sp)
    800026e2:	ec56                	sd	s5,24(sp)
    800026e4:	e85a                	sd	s6,16(sp)
    800026e6:	e45e                	sd	s7,8(sp)
    800026e8:	e062                	sd	s8,0(sp)
    800026ea:	0880                	addi	s0,sp,80
    800026ec:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800026ee:	fffff097          	auipc	ra,0xfffff
    800026f2:	77a080e7          	jalr	1914(ra) # 80001e68 <myproc>
    800026f6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800026f8:	0000f517          	auipc	a0,0xf
    800026fc:	10850513          	addi	a0,a0,264 # 80011800 <wait_lock>
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	4e4080e7          	jalr	1252(ra) # 80000be4 <acquire>
    havekids = 0;
    80002708:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    8000270a:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    8000270c:	00015997          	auipc	s3,0x15
    80002710:	30c98993          	addi	s3,s3,780 # 80017a18 <tickslock>
        havekids = 1;
    80002714:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002716:	0000fc17          	auipc	s8,0xf
    8000271a:	0eac0c13          	addi	s8,s8,234 # 80011800 <wait_lock>
    havekids = 0;
    8000271e:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    80002720:	0000f497          	auipc	s1,0xf
    80002724:	0f848493          	addi	s1,s1,248 # 80011818 <proc>
    80002728:	a0bd                	j	80002796 <wait+0xc2>
          pid = np->pid;
    8000272a:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000272e:	000b0e63          	beqz	s6,8000274a <wait+0x76>
    80002732:	4691                	li	a3,4
    80002734:	02c48613          	addi	a2,s1,44
    80002738:	85da                	mv	a1,s6
    8000273a:	07093503          	ld	a0,112(s2)
    8000273e:	fffff097          	auipc	ra,0xfffff
    80002742:	f58080e7          	jalr	-168(ra) # 80001696 <copyout>
    80002746:	02054563          	bltz	a0,80002770 <wait+0x9c>
          freeproc(np);
    8000274a:	8526                	mv	a0,s1
    8000274c:	00000097          	auipc	ra,0x0
    80002750:	8ca080e7          	jalr	-1846(ra) # 80002016 <freeproc>
          release(&np->lock);
    80002754:	8526                	mv	a0,s1
    80002756:	ffffe097          	auipc	ra,0xffffe
    8000275a:	554080e7          	jalr	1364(ra) # 80000caa <release>
          release(&wait_lock);
    8000275e:	0000f517          	auipc	a0,0xf
    80002762:	0a250513          	addi	a0,a0,162 # 80011800 <wait_lock>
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	544080e7          	jalr	1348(ra) # 80000caa <release>
          return pid;
    8000276e:	a09d                	j	800027d4 <wait+0x100>
            release(&np->lock);
    80002770:	8526                	mv	a0,s1
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	538080e7          	jalr	1336(ra) # 80000caa <release>
            release(&wait_lock);
    8000277a:	0000f517          	auipc	a0,0xf
    8000277e:	08650513          	addi	a0,a0,134 # 80011800 <wait_lock>
    80002782:	ffffe097          	auipc	ra,0xffffe
    80002786:	528080e7          	jalr	1320(ra) # 80000caa <release>
            return -1;
    8000278a:	59fd                	li	s3,-1
    8000278c:	a0a1                	j	800027d4 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    8000278e:	18848493          	addi	s1,s1,392
    80002792:	03348463          	beq	s1,s3,800027ba <wait+0xe6>
      if (np->parent == p)
    80002796:	6cbc                	ld	a5,88(s1)
    80002798:	ff279be3          	bne	a5,s2,8000278e <wait+0xba>
        acquire(&np->lock);
    8000279c:	8526                	mv	a0,s1
    8000279e:	ffffe097          	auipc	ra,0xffffe
    800027a2:	446080e7          	jalr	1094(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    800027a6:	4c9c                	lw	a5,24(s1)
    800027a8:	f94781e3          	beq	a5,s4,8000272a <wait+0x56>
        release(&np->lock);
    800027ac:	8526                	mv	a0,s1
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	4fc080e7          	jalr	1276(ra) # 80000caa <release>
        havekids = 1;
    800027b6:	8756                	mv	a4,s5
    800027b8:	bfd9                	j	8000278e <wait+0xba>
    if (!havekids || p->killed)
    800027ba:	c701                	beqz	a4,800027c2 <wait+0xee>
    800027bc:	02892783          	lw	a5,40(s2)
    800027c0:	c79d                	beqz	a5,800027ee <wait+0x11a>
      release(&wait_lock);
    800027c2:	0000f517          	auipc	a0,0xf
    800027c6:	03e50513          	addi	a0,a0,62 # 80011800 <wait_lock>
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	4e0080e7          	jalr	1248(ra) # 80000caa <release>
      return -1;
    800027d2:	59fd                	li	s3,-1
}
    800027d4:	854e                	mv	a0,s3
    800027d6:	60a6                	ld	ra,72(sp)
    800027d8:	6406                	ld	s0,64(sp)
    800027da:	74e2                	ld	s1,56(sp)
    800027dc:	7942                	ld	s2,48(sp)
    800027de:	79a2                	ld	s3,40(sp)
    800027e0:	7a02                	ld	s4,32(sp)
    800027e2:	6ae2                	ld	s5,24(sp)
    800027e4:	6b42                	ld	s6,16(sp)
    800027e6:	6ba2                	ld	s7,8(sp)
    800027e8:	6c02                	ld	s8,0(sp)
    800027ea:	6161                	addi	sp,sp,80
    800027ec:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800027ee:	85e2                	mv	a1,s8
    800027f0:	854a                	mv	a0,s2
    800027f2:	00000097          	auipc	ra,0x0
    800027f6:	e64080e7          	jalr	-412(ra) # 80002656 <sleep>
    havekids = 0;
    800027fa:	b715                	j	8000271e <wait+0x4a>

00000000800027fc <wakeup>:

void wakeup(void *chan) // Tali's
{
    800027fc:	715d                	addi	sp,sp,-80
    800027fe:	e486                	sd	ra,72(sp)
    80002800:	e0a2                	sd	s0,64(sp)
    80002802:	fc26                	sd	s1,56(sp)
    80002804:	f84a                	sd	s2,48(sp)
    80002806:	f44e                	sd	s3,40(sp)
    80002808:	f052                	sd	s4,32(sp)
    8000280a:	ec56                	sd	s5,24(sp)
    8000280c:	e85a                	sd	s6,16(sp)
    8000280e:	e45e                	sd	s7,8(sp)
    80002810:	e062                	sd	s8,0(sp)
    80002812:	0880                	addi	s0,sp,80
    80002814:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002816:	0000f497          	auipc	s1,0xf
    8000281a:	00248493          	addi	s1,s1,2 # 80011818 <proc>
  { // TODO: update to run on sleeping only
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000281e:	4989                	li	s3,2
      {
        // printf("%s \n","sleeping");
        remove_proc(&sleeping_head, p, &sleeping_lock);
    80002820:	0000fc17          	auipc	s8,0xf
    80002824:	ab0c0c13          	addi	s8,s8,-1360 # 800112d0 <sleeping_lock>
    80002828:	00006b97          	auipc	s7,0x6
    8000282c:	050b8b93          	addi	s7,s7,80 # 80008878 <sleeping_head>
        p->state = RUNNABLE;
    80002830:	4b0d                	li	s6,3
        // p->cpu = update_cpu(p->cpu);
        struct cpu *c = &cpus[p->cpu];
        add_proc(&c->runnable_head, p, &c->head_lock);
    80002832:	0000fa97          	auipc	s5,0xf
    80002836:	ab6a8a93          	addi	s5,s5,-1354 # 800112e8 <cpus>
  for (p = proc; p < &proc[NPROC]; p++)
    8000283a:	00015917          	auipc	s2,0x15
    8000283e:	1de90913          	addi	s2,s2,478 # 80017a18 <tickslock>
    80002842:	a811                	j	80002856 <wakeup+0x5a>
      }
      release(&p->lock);
    80002844:	8526                	mv	a0,s1
    80002846:	ffffe097          	auipc	ra,0xffffe
    8000284a:	464080e7          	jalr	1124(ra) # 80000caa <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000284e:	18848493          	addi	s1,s1,392
    80002852:	05248f63          	beq	s1,s2,800028b0 <wakeup+0xb4>
    if (p != myproc())
    80002856:	fffff097          	auipc	ra,0xfffff
    8000285a:	612080e7          	jalr	1554(ra) # 80001e68 <myproc>
    8000285e:	fea488e3          	beq	s1,a0,8000284e <wakeup+0x52>
      acquire(&p->lock);
    80002862:	8526                	mv	a0,s1
    80002864:	ffffe097          	auipc	ra,0xffffe
    80002868:	380080e7          	jalr	896(ra) # 80000be4 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000286c:	4c9c                	lw	a5,24(s1)
    8000286e:	fd379be3          	bne	a5,s3,80002844 <wakeup+0x48>
    80002872:	709c                	ld	a5,32(s1)
    80002874:	fd4798e3          	bne	a5,s4,80002844 <wakeup+0x48>
        remove_proc(&sleeping_head, p, &sleeping_lock);
    80002878:	8662                	mv	a2,s8
    8000287a:	85a6                	mv	a1,s1
    8000287c:	855e                	mv	a0,s7
    8000287e:	fffff097          	auipc	ra,0xfffff
    80002882:	110080e7          	jalr	272(ra) # 8000198e <remove_proc>
        p->state = RUNNABLE;
    80002886:	0164ac23          	sw	s6,24(s1)
        struct cpu *c = &cpus[p->cpu];
    8000288a:	58c8                	lw	a0,52(s1)
    8000288c:	0005079b          	sext.w	a5,a0
        add_proc(&c->runnable_head, p, &c->head_lock);
    80002890:	00279513          	slli	a0,a5,0x2
    80002894:	953e                	add	a0,a0,a5
    80002896:	0516                	slli	a0,a0,0x5
    80002898:	08850613          	addi	a2,a0,136
    8000289c:	08050513          	addi	a0,a0,128
    800028a0:	9656                	add	a2,a2,s5
    800028a2:	85a6                	mv	a1,s1
    800028a4:	9556                	add	a0,a0,s5
    800028a6:	fffff097          	auipc	ra,0xfffff
    800028aa:	2b8080e7          	jalr	696(ra) # 80001b5e <add_proc>
    800028ae:	bf59                	j	80002844 <wakeup+0x48>
    }
  }
}
    800028b0:	60a6                	ld	ra,72(sp)
    800028b2:	6406                	ld	s0,64(sp)
    800028b4:	74e2                	ld	s1,56(sp)
    800028b6:	7942                	ld	s2,48(sp)
    800028b8:	79a2                	ld	s3,40(sp)
    800028ba:	7a02                	ld	s4,32(sp)
    800028bc:	6ae2                	ld	s5,24(sp)
    800028be:	6b42                	ld	s6,16(sp)
    800028c0:	6ba2                	ld	s7,8(sp)
    800028c2:	6c02                	ld	s8,0(sp)
    800028c4:	6161                	addi	sp,sp,80
    800028c6:	8082                	ret

00000000800028c8 <reparent>:
{
    800028c8:	7179                	addi	sp,sp,-48
    800028ca:	f406                	sd	ra,40(sp)
    800028cc:	f022                	sd	s0,32(sp)
    800028ce:	ec26                	sd	s1,24(sp)
    800028d0:	e84a                	sd	s2,16(sp)
    800028d2:	e44e                	sd	s3,8(sp)
    800028d4:	e052                	sd	s4,0(sp)
    800028d6:	1800                	addi	s0,sp,48
    800028d8:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800028da:	0000f497          	auipc	s1,0xf
    800028de:	f3e48493          	addi	s1,s1,-194 # 80011818 <proc>
      pp->parent = initproc;
    800028e2:	00006a17          	auipc	s4,0x6
    800028e6:	746a0a13          	addi	s4,s4,1862 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800028ea:	00015997          	auipc	s3,0x15
    800028ee:	12e98993          	addi	s3,s3,302 # 80017a18 <tickslock>
    800028f2:	a029                	j	800028fc <reparent+0x34>
    800028f4:	18848493          	addi	s1,s1,392
    800028f8:	01348d63          	beq	s1,s3,80002912 <reparent+0x4a>
    if (pp->parent == p)
    800028fc:	6cbc                	ld	a5,88(s1)
    800028fe:	ff279be3          	bne	a5,s2,800028f4 <reparent+0x2c>
      pp->parent = initproc;
    80002902:	000a3503          	ld	a0,0(s4)
    80002906:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    80002908:	00000097          	auipc	ra,0x0
    8000290c:	ef4080e7          	jalr	-268(ra) # 800027fc <wakeup>
    80002910:	b7d5                	j	800028f4 <reparent+0x2c>
}
    80002912:	70a2                	ld	ra,40(sp)
    80002914:	7402                	ld	s0,32(sp)
    80002916:	64e2                	ld	s1,24(sp)
    80002918:	6942                	ld	s2,16(sp)
    8000291a:	69a2                	ld	s3,8(sp)
    8000291c:	6a02                	ld	s4,0(sp)
    8000291e:	6145                	addi	sp,sp,48
    80002920:	8082                	ret

0000000080002922 <exit>:
{
    80002922:	7179                	addi	sp,sp,-48
    80002924:	f406                	sd	ra,40(sp)
    80002926:	f022                	sd	s0,32(sp)
    80002928:	ec26                	sd	s1,24(sp)
    8000292a:	e84a                	sd	s2,16(sp)
    8000292c:	e44e                	sd	s3,8(sp)
    8000292e:	e052                	sd	s4,0(sp)
    80002930:	1800                	addi	s0,sp,48
    80002932:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002934:	fffff097          	auipc	ra,0xfffff
    80002938:	534080e7          	jalr	1332(ra) # 80001e68 <myproc>
    8000293c:	89aa                	mv	s3,a0
  if (p == initproc)
    8000293e:	00006797          	auipc	a5,0x6
    80002942:	6ea7b783          	ld	a5,1770(a5) # 80009028 <initproc>
    80002946:	0f050493          	addi	s1,a0,240
    8000294a:	17050913          	addi	s2,a0,368
    8000294e:	02a79363          	bne	a5,a0,80002974 <exit+0x52>
    panic("init exiting");
    80002952:	00006517          	auipc	a0,0x6
    80002956:	96650513          	addi	a0,a0,-1690 # 800082b8 <digits+0x278>
    8000295a:	ffffe097          	auipc	ra,0xffffe
    8000295e:	be4080e7          	jalr	-1052(ra) # 8000053e <panic>
      fileclose(f);
    80002962:	00002097          	auipc	ra,0x2
    80002966:	28a080e7          	jalr	650(ra) # 80004bec <fileclose>
      p->ofile[fd] = 0;
    8000296a:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000296e:	04a1                	addi	s1,s1,8
    80002970:	01248563          	beq	s1,s2,8000297a <exit+0x58>
    if (p->ofile[fd])
    80002974:	6088                	ld	a0,0(s1)
    80002976:	f575                	bnez	a0,80002962 <exit+0x40>
    80002978:	bfdd                	j	8000296e <exit+0x4c>
  begin_op();
    8000297a:	00002097          	auipc	ra,0x2
    8000297e:	da6080e7          	jalr	-602(ra) # 80004720 <begin_op>
  iput(p->cwd);
    80002982:	1709b503          	ld	a0,368(s3)
    80002986:	00001097          	auipc	ra,0x1
    8000298a:	582080e7          	jalr	1410(ra) # 80003f08 <iput>
  end_op();
    8000298e:	00002097          	auipc	ra,0x2
    80002992:	e12080e7          	jalr	-494(ra) # 800047a0 <end_op>
  p->cwd = 0;
    80002996:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    8000299a:	0000f497          	auipc	s1,0xf
    8000299e:	e6648493          	addi	s1,s1,-410 # 80011800 <wait_lock>
    800029a2:	8526                	mv	a0,s1
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	240080e7          	jalr	576(ra) # 80000be4 <acquire>
  reparent(p);
    800029ac:	854e                	mv	a0,s3
    800029ae:	00000097          	auipc	ra,0x0
    800029b2:	f1a080e7          	jalr	-230(ra) # 800028c8 <reparent>
  wakeup(p->parent);
    800029b6:	0589b503          	ld	a0,88(s3)
    800029ba:	00000097          	auipc	ra,0x0
    800029be:	e42080e7          	jalr	-446(ra) # 800027fc <wakeup>
  acquire(&p->lock);
    800029c2:	854e                	mv	a0,s3
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	220080e7          	jalr	544(ra) # 80000be4 <acquire>
  p->xstate = status;
    800029cc:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800029d0:	4795                	li	a5,5
    800029d2:	00f9ac23          	sw	a5,24(s3)
  add_proc(&zombie_head, p, &zombie_lock);
    800029d6:	0000f617          	auipc	a2,0xf
    800029da:	8ca60613          	addi	a2,a2,-1846 # 800112a0 <zombie_lock>
    800029de:	85ce                	mv	a1,s3
    800029e0:	00006517          	auipc	a0,0x6
    800029e4:	e9c50513          	addi	a0,a0,-356 # 8000887c <zombie_head>
    800029e8:	fffff097          	auipc	ra,0xfffff
    800029ec:	176080e7          	jalr	374(ra) # 80001b5e <add_proc>
  release(&wait_lock);
    800029f0:	8526                	mv	a0,s1
    800029f2:	ffffe097          	auipc	ra,0xffffe
    800029f6:	2b8080e7          	jalr	696(ra) # 80000caa <release>
  sched();
    800029fa:	00000097          	auipc	ra,0x0
    800029fe:	afe080e7          	jalr	-1282(ra) # 800024f8 <sched>
  panic("zombie exit");
    80002a02:	00006517          	auipc	a0,0x6
    80002a06:	8c650513          	addi	a0,a0,-1850 # 800082c8 <digits+0x288>
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	b34080e7          	jalr	-1228(ra) # 8000053e <panic>

0000000080002a12 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002a12:	7179                	addi	sp,sp,-48
    80002a14:	f406                	sd	ra,40(sp)
    80002a16:	f022                	sd	s0,32(sp)
    80002a18:	ec26                	sd	s1,24(sp)
    80002a1a:	e84a                	sd	s2,16(sp)
    80002a1c:	e44e                	sd	s3,8(sp)
    80002a1e:	1800                	addi	s0,sp,48
    80002a20:	892a                	mv	s2,a0
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002a22:	0000f497          	auipc	s1,0xf
    80002a26:	df648493          	addi	s1,s1,-522 # 80011818 <proc>
    80002a2a:	00015997          	auipc	s3,0x15
    80002a2e:	fee98993          	addi	s3,s3,-18 # 80017a18 <tickslock>
  {
    acquire(&p->lock);
    80002a32:	8526                	mv	a0,s1
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	1b0080e7          	jalr	432(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    80002a3c:	589c                	lw	a5,48(s1)
    80002a3e:	01278d63          	beq	a5,s2,80002a58 <kill+0x46>
        add_proc(&c->runnable_head, p, &c->head_lock);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002a42:	8526                	mv	a0,s1
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	266080e7          	jalr	614(ra) # 80000caa <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002a4c:	18848493          	addi	s1,s1,392
    80002a50:	ff3491e3          	bne	s1,s3,80002a32 <kill+0x20>
  }
  return -1;
    80002a54:	557d                	li	a0,-1
    80002a56:	a829                	j	80002a70 <kill+0x5e>
      p->killed = 1;
    80002a58:	4785                	li	a5,1
    80002a5a:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002a5c:	4c98                	lw	a4,24(s1)
    80002a5e:	4789                	li	a5,2
    80002a60:	00f70f63          	beq	a4,a5,80002a7e <kill+0x6c>
      release(&p->lock);
    80002a64:	8526                	mv	a0,s1
    80002a66:	ffffe097          	auipc	ra,0xffffe
    80002a6a:	244080e7          	jalr	580(ra) # 80000caa <release>
      return 0;
    80002a6e:	4501                	li	a0,0
}
    80002a70:	70a2                	ld	ra,40(sp)
    80002a72:	7402                	ld	s0,32(sp)
    80002a74:	64e2                	ld	s1,24(sp)
    80002a76:	6942                	ld	s2,16(sp)
    80002a78:	69a2                	ld	s3,8(sp)
    80002a7a:	6145                	addi	sp,sp,48
    80002a7c:	8082                	ret
        remove_proc(&sleeping_head, p, &sleeping_lock);
    80002a7e:	0000f617          	auipc	a2,0xf
    80002a82:	85260613          	addi	a2,a2,-1966 # 800112d0 <sleeping_lock>
    80002a86:	85a6                	mv	a1,s1
    80002a88:	00006517          	auipc	a0,0x6
    80002a8c:	df050513          	addi	a0,a0,-528 # 80008878 <sleeping_head>
    80002a90:	fffff097          	auipc	ra,0xfffff
    80002a94:	efe080e7          	jalr	-258(ra) # 8000198e <remove_proc>
        p->state = RUNNABLE;
    80002a98:	478d                	li	a5,3
    80002a9a:	cc9c                	sw	a5,24(s1)
        struct cpu *c = &cpus[p->cpu];
    80002a9c:	58dc                	lw	a5,52(s1)
    80002a9e:	0007871b          	sext.w	a4,a5
        add_proc(&c->runnable_head, p, &c->head_lock);
    80002aa2:	00271793          	slli	a5,a4,0x2
    80002aa6:	97ba                	add	a5,a5,a4
    80002aa8:	0796                	slli	a5,a5,0x5
    80002aaa:	0000f517          	auipc	a0,0xf
    80002aae:	83e50513          	addi	a0,a0,-1986 # 800112e8 <cpus>
    80002ab2:	08878613          	addi	a2,a5,136
    80002ab6:	08078793          	addi	a5,a5,128
    80002aba:	962a                	add	a2,a2,a0
    80002abc:	85a6                	mv	a1,s1
    80002abe:	953e                	add	a0,a0,a5
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	09e080e7          	jalr	158(ra) # 80001b5e <add_proc>
    80002ac8:	bf71                	j	80002a64 <kill+0x52>

0000000080002aca <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002aca:	7179                	addi	sp,sp,-48
    80002acc:	f406                	sd	ra,40(sp)
    80002ace:	f022                	sd	s0,32(sp)
    80002ad0:	ec26                	sd	s1,24(sp)
    80002ad2:	e84a                	sd	s2,16(sp)
    80002ad4:	e44e                	sd	s3,8(sp)
    80002ad6:	e052                	sd	s4,0(sp)
    80002ad8:	1800                	addi	s0,sp,48
    80002ada:	84aa                	mv	s1,a0
    80002adc:	892e                	mv	s2,a1
    80002ade:	89b2                	mv	s3,a2
    80002ae0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002ae2:	fffff097          	auipc	ra,0xfffff
    80002ae6:	386080e7          	jalr	902(ra) # 80001e68 <myproc>
  if (user_dst)
    80002aea:	c08d                	beqz	s1,80002b0c <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002aec:	86d2                	mv	a3,s4
    80002aee:	864e                	mv	a2,s3
    80002af0:	85ca                	mv	a1,s2
    80002af2:	7928                	ld	a0,112(a0)
    80002af4:	fffff097          	auipc	ra,0xfffff
    80002af8:	ba2080e7          	jalr	-1118(ra) # 80001696 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002afc:	70a2                	ld	ra,40(sp)
    80002afe:	7402                	ld	s0,32(sp)
    80002b00:	64e2                	ld	s1,24(sp)
    80002b02:	6942                	ld	s2,16(sp)
    80002b04:	69a2                	ld	s3,8(sp)
    80002b06:	6a02                	ld	s4,0(sp)
    80002b08:	6145                	addi	sp,sp,48
    80002b0a:	8082                	ret
    memmove((char *)dst, src, len);
    80002b0c:	000a061b          	sext.w	a2,s4
    80002b10:	85ce                	mv	a1,s3
    80002b12:	854a                	mv	a0,s2
    80002b14:	ffffe097          	auipc	ra,0xffffe
    80002b18:	250080e7          	jalr	592(ra) # 80000d64 <memmove>
    return 0;
    80002b1c:	8526                	mv	a0,s1
    80002b1e:	bff9                	j	80002afc <either_copyout+0x32>

0000000080002b20 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002b20:	7179                	addi	sp,sp,-48
    80002b22:	f406                	sd	ra,40(sp)
    80002b24:	f022                	sd	s0,32(sp)
    80002b26:	ec26                	sd	s1,24(sp)
    80002b28:	e84a                	sd	s2,16(sp)
    80002b2a:	e44e                	sd	s3,8(sp)
    80002b2c:	e052                	sd	s4,0(sp)
    80002b2e:	1800                	addi	s0,sp,48
    80002b30:	892a                	mv	s2,a0
    80002b32:	84ae                	mv	s1,a1
    80002b34:	89b2                	mv	s3,a2
    80002b36:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002b38:	fffff097          	auipc	ra,0xfffff
    80002b3c:	330080e7          	jalr	816(ra) # 80001e68 <myproc>
  if (user_src)
    80002b40:	c08d                	beqz	s1,80002b62 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002b42:	86d2                	mv	a3,s4
    80002b44:	864e                	mv	a2,s3
    80002b46:	85ca                	mv	a1,s2
    80002b48:	7928                	ld	a0,112(a0)
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	bd8080e7          	jalr	-1064(ra) # 80001722 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002b52:	70a2                	ld	ra,40(sp)
    80002b54:	7402                	ld	s0,32(sp)
    80002b56:	64e2                	ld	s1,24(sp)
    80002b58:	6942                	ld	s2,16(sp)
    80002b5a:	69a2                	ld	s3,8(sp)
    80002b5c:	6a02                	ld	s4,0(sp)
    80002b5e:	6145                	addi	sp,sp,48
    80002b60:	8082                	ret
    memmove(dst, (char *)src, len);
    80002b62:	000a061b          	sext.w	a2,s4
    80002b66:	85ce                	mv	a1,s3
    80002b68:	854a                	mv	a0,s2
    80002b6a:	ffffe097          	auipc	ra,0xffffe
    80002b6e:	1fa080e7          	jalr	506(ra) # 80000d64 <memmove>
    return 0;
    80002b72:	8526                	mv	a0,s1
    80002b74:	bff9                	j	80002b52 <either_copyin+0x32>

0000000080002b76 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002b76:	715d                	addi	sp,sp,-80
    80002b78:	e486                	sd	ra,72(sp)
    80002b7a:	e0a2                	sd	s0,64(sp)
    80002b7c:	fc26                	sd	s1,56(sp)
    80002b7e:	f84a                	sd	s2,48(sp)
    80002b80:	f44e                	sd	s3,40(sp)
    80002b82:	f052                	sd	s4,32(sp)
    80002b84:	ec56                	sd	s5,24(sp)
    80002b86:	e85a                	sd	s6,16(sp)
    80002b88:	e45e                	sd	s7,8(sp)
    80002b8a:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002b8c:	00005517          	auipc	a0,0x5
    80002b90:	54450513          	addi	a0,a0,1348 # 800080d0 <digits+0x90>
    80002b94:	ffffe097          	auipc	ra,0xffffe
    80002b98:	9f4080e7          	jalr	-1548(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002b9c:	0000f497          	auipc	s1,0xf
    80002ba0:	df448493          	addi	s1,s1,-524 # 80011990 <proc+0x178>
    80002ba4:	00015917          	auipc	s2,0x15
    80002ba8:	fec90913          	addi	s2,s2,-20 # 80017b90 <bcache+0x160>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002bac:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002bae:	00005997          	auipc	s3,0x5
    80002bb2:	72a98993          	addi	s3,s3,1834 # 800082d8 <digits+0x298>
    printf("%d %s %s", p->pid, state, p->name);
    80002bb6:	00005a97          	auipc	s5,0x5
    80002bba:	72aa8a93          	addi	s5,s5,1834 # 800082e0 <digits+0x2a0>
    printf("\n");
    80002bbe:	00005a17          	auipc	s4,0x5
    80002bc2:	512a0a13          	addi	s4,s4,1298 # 800080d0 <digits+0x90>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002bc6:	00005b97          	auipc	s7,0x5
    80002bca:	742b8b93          	addi	s7,s7,1858 # 80008308 <states.1773>
    80002bce:	a00d                	j	80002bf0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002bd0:	eb86a583          	lw	a1,-328(a3)
    80002bd4:	8556                	mv	a0,s5
    80002bd6:	ffffe097          	auipc	ra,0xffffe
    80002bda:	9b2080e7          	jalr	-1614(ra) # 80000588 <printf>
    printf("\n");
    80002bde:	8552                	mv	a0,s4
    80002be0:	ffffe097          	auipc	ra,0xffffe
    80002be4:	9a8080e7          	jalr	-1624(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002be8:	18848493          	addi	s1,s1,392
    80002bec:	03248163          	beq	s1,s2,80002c0e <procdump+0x98>
    if (p->state == UNUSED)
    80002bf0:	86a6                	mv	a3,s1
    80002bf2:	ea04a783          	lw	a5,-352(s1)
    80002bf6:	dbed                	beqz	a5,80002be8 <procdump+0x72>
      state = "???";
    80002bf8:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002bfa:	fcfb6be3          	bltu	s6,a5,80002bd0 <procdump+0x5a>
    80002bfe:	1782                	slli	a5,a5,0x20
    80002c00:	9381                	srli	a5,a5,0x20
    80002c02:	078e                	slli	a5,a5,0x3
    80002c04:	97de                	add	a5,a5,s7
    80002c06:	6390                	ld	a2,0(a5)
    80002c08:	f661                	bnez	a2,80002bd0 <procdump+0x5a>
      state = "???";
    80002c0a:	864e                	mv	a2,s3
    80002c0c:	b7d1                	j	80002bd0 <procdump+0x5a>
  }
}
    80002c0e:	60a6                	ld	ra,72(sp)
    80002c10:	6406                	ld	s0,64(sp)
    80002c12:	74e2                	ld	s1,56(sp)
    80002c14:	7942                	ld	s2,48(sp)
    80002c16:	79a2                	ld	s3,40(sp)
    80002c18:	7a02                	ld	s4,32(sp)
    80002c1a:	6ae2                	ld	s5,24(sp)
    80002c1c:	6b42                	ld	s6,16(sp)
    80002c1e:	6ba2                	ld	s7,8(sp)
    80002c20:	6161                	addi	sp,sp,80
    80002c22:	8082                	ret

0000000080002c24 <set_cpu>:

int set_cpu(int cpu_num)
{
    80002c24:	1101                	addi	sp,sp,-32
    80002c26:	ec06                	sd	ra,24(sp)
    80002c28:	e822                	sd	s0,16(sp)
    80002c2a:	e426                	sd	s1,8(sp)
    80002c2c:	1000                	addi	s0,sp,32
    80002c2e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	238080e7          	jalr	568(ra) # 80001e68 <myproc>
  if (cas(&p->cpu, p->cpu, cpu_num) != 0)
    80002c38:	594c                	lw	a1,52(a0)
    80002c3a:	8626                	mv	a2,s1
    80002c3c:	2581                	sext.w	a1,a1
    80002c3e:	03450513          	addi	a0,a0,52
    80002c42:	00004097          	auipc	ra,0x4
    80002c46:	c94080e7          	jalr	-876(ra) # 800068d6 <cas>
    80002c4a:	e919                	bnez	a0,80002c60 <set_cpu+0x3c>
    return -1;
  yield();
    80002c4c:	00000097          	auipc	ra,0x0
    80002c50:	9a2080e7          	jalr	-1630(ra) # 800025ee <yield>
  return cpu_num;
    80002c54:	8526                	mv	a0,s1
}
    80002c56:	60e2                	ld	ra,24(sp)
    80002c58:	6442                	ld	s0,16(sp)
    80002c5a:	64a2                	ld	s1,8(sp)
    80002c5c:	6105                	addi	sp,sp,32
    80002c5e:	8082                	ret
    return -1;
    80002c60:	557d                	li	a0,-1
    80002c62:	bfd5                	j	80002c56 <set_cpu+0x32>

0000000080002c64 <get_cpu>:

int get_cpu()
{
    80002c64:	1101                	addi	sp,sp,-32
    80002c66:	ec06                	sd	ra,24(sp)
    80002c68:	e822                	sd	s0,16(sp)
    80002c6a:	e426                	sd	s1,8(sp)
    80002c6c:	e04a                	sd	s2,0(sp)
    80002c6e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002c70:	fffff097          	auipc	ra,0xfffff
    80002c74:	1f8080e7          	jalr	504(ra) # 80001e68 <myproc>
    80002c78:	84aa                	mv	s1,a0
  int cpu_num = -1;
  acquire(&p->lock);
    80002c7a:	ffffe097          	auipc	ra,0xffffe
    80002c7e:	f6a080e7          	jalr	-150(ra) # 80000be4 <acquire>
  cpu_num = p->cpu;
    80002c82:	0344a903          	lw	s2,52(s1)
    80002c86:	2901                	sext.w	s2,s2
  release(&p->lock);
    80002c88:	8526                	mv	a0,s1
    80002c8a:	ffffe097          	auipc	ra,0xffffe
    80002c8e:	020080e7          	jalr	32(ra) # 80000caa <release>
  return cpu_num;
}
    80002c92:	854a                	mv	a0,s2
    80002c94:	60e2                	ld	ra,24(sp)
    80002c96:	6442                	ld	s0,16(sp)
    80002c98:	64a2                	ld	s1,8(sp)
    80002c9a:	6902                	ld	s2,0(sp)
    80002c9c:	6105                	addi	sp,sp,32
    80002c9e:	8082                	ret

0000000080002ca0 <swtch>:
    80002ca0:	00153023          	sd	ra,0(a0)
    80002ca4:	00253423          	sd	sp,8(a0)
    80002ca8:	e900                	sd	s0,16(a0)
    80002caa:	ed04                	sd	s1,24(a0)
    80002cac:	03253023          	sd	s2,32(a0)
    80002cb0:	03353423          	sd	s3,40(a0)
    80002cb4:	03453823          	sd	s4,48(a0)
    80002cb8:	03553c23          	sd	s5,56(a0)
    80002cbc:	05653023          	sd	s6,64(a0)
    80002cc0:	05753423          	sd	s7,72(a0)
    80002cc4:	05853823          	sd	s8,80(a0)
    80002cc8:	05953c23          	sd	s9,88(a0)
    80002ccc:	07a53023          	sd	s10,96(a0)
    80002cd0:	07b53423          	sd	s11,104(a0)
    80002cd4:	0005b083          	ld	ra,0(a1)
    80002cd8:	0085b103          	ld	sp,8(a1)
    80002cdc:	6980                	ld	s0,16(a1)
    80002cde:	6d84                	ld	s1,24(a1)
    80002ce0:	0205b903          	ld	s2,32(a1)
    80002ce4:	0285b983          	ld	s3,40(a1)
    80002ce8:	0305ba03          	ld	s4,48(a1)
    80002cec:	0385ba83          	ld	s5,56(a1)
    80002cf0:	0405bb03          	ld	s6,64(a1)
    80002cf4:	0485bb83          	ld	s7,72(a1)
    80002cf8:	0505bc03          	ld	s8,80(a1)
    80002cfc:	0585bc83          	ld	s9,88(a1)
    80002d00:	0605bd03          	ld	s10,96(a1)
    80002d04:	0685bd83          	ld	s11,104(a1)
    80002d08:	8082                	ret

0000000080002d0a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002d0a:	1141                	addi	sp,sp,-16
    80002d0c:	e406                	sd	ra,8(sp)
    80002d0e:	e022                	sd	s0,0(sp)
    80002d10:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002d12:	00005597          	auipc	a1,0x5
    80002d16:	62658593          	addi	a1,a1,1574 # 80008338 <states.1773+0x30>
    80002d1a:	00015517          	auipc	a0,0x15
    80002d1e:	cfe50513          	addi	a0,a0,-770 # 80017a18 <tickslock>
    80002d22:	ffffe097          	auipc	ra,0xffffe
    80002d26:	e32080e7          	jalr	-462(ra) # 80000b54 <initlock>
}
    80002d2a:	60a2                	ld	ra,8(sp)
    80002d2c:	6402                	ld	s0,0(sp)
    80002d2e:	0141                	addi	sp,sp,16
    80002d30:	8082                	ret

0000000080002d32 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002d32:	1141                	addi	sp,sp,-16
    80002d34:	e422                	sd	s0,8(sp)
    80002d36:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d38:	00003797          	auipc	a5,0x3
    80002d3c:	4c878793          	addi	a5,a5,1224 # 80006200 <kernelvec>
    80002d40:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002d44:	6422                	ld	s0,8(sp)
    80002d46:	0141                	addi	sp,sp,16
    80002d48:	8082                	ret

0000000080002d4a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002d4a:	1141                	addi	sp,sp,-16
    80002d4c:	e406                	sd	ra,8(sp)
    80002d4e:	e022                	sd	s0,0(sp)
    80002d50:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002d52:	fffff097          	auipc	ra,0xfffff
    80002d56:	116080e7          	jalr	278(ra) # 80001e68 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d5a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002d5e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d60:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002d64:	00004617          	auipc	a2,0x4
    80002d68:	29c60613          	addi	a2,a2,668 # 80007000 <_trampoline>
    80002d6c:	00004697          	auipc	a3,0x4
    80002d70:	29468693          	addi	a3,a3,660 # 80007000 <_trampoline>
    80002d74:	8e91                	sub	a3,a3,a2
    80002d76:	040007b7          	lui	a5,0x4000
    80002d7a:	17fd                	addi	a5,a5,-1
    80002d7c:	07b2                	slli	a5,a5,0xc
    80002d7e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d80:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d84:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d86:	180026f3          	csrr	a3,satp
    80002d8a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d8c:	7d38                	ld	a4,120(a0)
    80002d8e:	7134                	ld	a3,96(a0)
    80002d90:	6585                	lui	a1,0x1
    80002d92:	96ae                	add	a3,a3,a1
    80002d94:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d96:	7d38                	ld	a4,120(a0)
    80002d98:	00000697          	auipc	a3,0x0
    80002d9c:	13868693          	addi	a3,a3,312 # 80002ed0 <usertrap>
    80002da0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002da2:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002da4:	8692                	mv	a3,tp
    80002da6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002da8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002dac:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002db0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002db4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002db8:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002dba:	6f18                	ld	a4,24(a4)
    80002dbc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002dc0:	792c                	ld	a1,112(a0)
    80002dc2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002dc4:	00004717          	auipc	a4,0x4
    80002dc8:	2cc70713          	addi	a4,a4,716 # 80007090 <userret>
    80002dcc:	8f11                	sub	a4,a4,a2
    80002dce:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002dd0:	577d                	li	a4,-1
    80002dd2:	177e                	slli	a4,a4,0x3f
    80002dd4:	8dd9                	or	a1,a1,a4
    80002dd6:	02000537          	lui	a0,0x2000
    80002dda:	157d                	addi	a0,a0,-1
    80002ddc:	0536                	slli	a0,a0,0xd
    80002dde:	9782                	jalr	a5
}
    80002de0:	60a2                	ld	ra,8(sp)
    80002de2:	6402                	ld	s0,0(sp)
    80002de4:	0141                	addi	sp,sp,16
    80002de6:	8082                	ret

0000000080002de8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002de8:	1101                	addi	sp,sp,-32
    80002dea:	ec06                	sd	ra,24(sp)
    80002dec:	e822                	sd	s0,16(sp)
    80002dee:	e426                	sd	s1,8(sp)
    80002df0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002df2:	00015497          	auipc	s1,0x15
    80002df6:	c2648493          	addi	s1,s1,-986 # 80017a18 <tickslock>
    80002dfa:	8526                	mv	a0,s1
    80002dfc:	ffffe097          	auipc	ra,0xffffe
    80002e00:	de8080e7          	jalr	-536(ra) # 80000be4 <acquire>
  ticks++;
    80002e04:	00006517          	auipc	a0,0x6
    80002e08:	22c50513          	addi	a0,a0,556 # 80009030 <ticks>
    80002e0c:	411c                	lw	a5,0(a0)
    80002e0e:	2785                	addiw	a5,a5,1
    80002e10:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002e12:	00000097          	auipc	ra,0x0
    80002e16:	9ea080e7          	jalr	-1558(ra) # 800027fc <wakeup>
  release(&tickslock);
    80002e1a:	8526                	mv	a0,s1
    80002e1c:	ffffe097          	auipc	ra,0xffffe
    80002e20:	e8e080e7          	jalr	-370(ra) # 80000caa <release>
}
    80002e24:	60e2                	ld	ra,24(sp)
    80002e26:	6442                	ld	s0,16(sp)
    80002e28:	64a2                	ld	s1,8(sp)
    80002e2a:	6105                	addi	sp,sp,32
    80002e2c:	8082                	ret

0000000080002e2e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002e2e:	1101                	addi	sp,sp,-32
    80002e30:	ec06                	sd	ra,24(sp)
    80002e32:	e822                	sd	s0,16(sp)
    80002e34:	e426                	sd	s1,8(sp)
    80002e36:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e38:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002e3c:	00074d63          	bltz	a4,80002e56 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002e40:	57fd                	li	a5,-1
    80002e42:	17fe                	slli	a5,a5,0x3f
    80002e44:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002e46:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002e48:	06f70363          	beq	a4,a5,80002eae <devintr+0x80>
  }
}
    80002e4c:	60e2                	ld	ra,24(sp)
    80002e4e:	6442                	ld	s0,16(sp)
    80002e50:	64a2                	ld	s1,8(sp)
    80002e52:	6105                	addi	sp,sp,32
    80002e54:	8082                	ret
     (scause & 0xff) == 9){
    80002e56:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002e5a:	46a5                	li	a3,9
    80002e5c:	fed792e3          	bne	a5,a3,80002e40 <devintr+0x12>
    int irq = plic_claim();
    80002e60:	00003097          	auipc	ra,0x3
    80002e64:	4a8080e7          	jalr	1192(ra) # 80006308 <plic_claim>
    80002e68:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002e6a:	47a9                	li	a5,10
    80002e6c:	02f50763          	beq	a0,a5,80002e9a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002e70:	4785                	li	a5,1
    80002e72:	02f50963          	beq	a0,a5,80002ea4 <devintr+0x76>
    return 1;
    80002e76:	4505                	li	a0,1
    } else if(irq){
    80002e78:	d8f1                	beqz	s1,80002e4c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e7a:	85a6                	mv	a1,s1
    80002e7c:	00005517          	auipc	a0,0x5
    80002e80:	4c450513          	addi	a0,a0,1220 # 80008340 <states.1773+0x38>
    80002e84:	ffffd097          	auipc	ra,0xffffd
    80002e88:	704080e7          	jalr	1796(ra) # 80000588 <printf>
      plic_complete(irq);
    80002e8c:	8526                	mv	a0,s1
    80002e8e:	00003097          	auipc	ra,0x3
    80002e92:	49e080e7          	jalr	1182(ra) # 8000632c <plic_complete>
    return 1;
    80002e96:	4505                	li	a0,1
    80002e98:	bf55                	j	80002e4c <devintr+0x1e>
      uartintr();
    80002e9a:	ffffe097          	auipc	ra,0xffffe
    80002e9e:	b0e080e7          	jalr	-1266(ra) # 800009a8 <uartintr>
    80002ea2:	b7ed                	j	80002e8c <devintr+0x5e>
      virtio_disk_intr();
    80002ea4:	00004097          	auipc	ra,0x4
    80002ea8:	968080e7          	jalr	-1688(ra) # 8000680c <virtio_disk_intr>
    80002eac:	b7c5                	j	80002e8c <devintr+0x5e>
    if(cpuid() == 0){
    80002eae:	fffff097          	auipc	ra,0xfffff
    80002eb2:	f86080e7          	jalr	-122(ra) # 80001e34 <cpuid>
    80002eb6:	c901                	beqz	a0,80002ec6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002eb8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ebc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ebe:	14479073          	csrw	sip,a5
    return 2;
    80002ec2:	4509                	li	a0,2
    80002ec4:	b761                	j	80002e4c <devintr+0x1e>
      clockintr();
    80002ec6:	00000097          	auipc	ra,0x0
    80002eca:	f22080e7          	jalr	-222(ra) # 80002de8 <clockintr>
    80002ece:	b7ed                	j	80002eb8 <devintr+0x8a>

0000000080002ed0 <usertrap>:
{
    80002ed0:	1101                	addi	sp,sp,-32
    80002ed2:	ec06                	sd	ra,24(sp)
    80002ed4:	e822                	sd	s0,16(sp)
    80002ed6:	e426                	sd	s1,8(sp)
    80002ed8:	e04a                	sd	s2,0(sp)
    80002eda:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002edc:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ee0:	1007f793          	andi	a5,a5,256
    80002ee4:	e3ad                	bnez	a5,80002f46 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ee6:	00003797          	auipc	a5,0x3
    80002eea:	31a78793          	addi	a5,a5,794 # 80006200 <kernelvec>
    80002eee:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ef2:	fffff097          	auipc	ra,0xfffff
    80002ef6:	f76080e7          	jalr	-138(ra) # 80001e68 <myproc>
    80002efa:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002efc:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002efe:	14102773          	csrr	a4,sepc
    80002f02:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f04:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002f08:	47a1                	li	a5,8
    80002f0a:	04f71c63          	bne	a4,a5,80002f62 <usertrap+0x92>
    if(p->killed)
    80002f0e:	551c                	lw	a5,40(a0)
    80002f10:	e3b9                	bnez	a5,80002f56 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002f12:	7cb8                	ld	a4,120(s1)
    80002f14:	6f1c                	ld	a5,24(a4)
    80002f16:	0791                	addi	a5,a5,4
    80002f18:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f1a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002f1e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f22:	10079073          	csrw	sstatus,a5
    syscall();
    80002f26:	00000097          	auipc	ra,0x0
    80002f2a:	2e0080e7          	jalr	736(ra) # 80003206 <syscall>
  if(p->killed)
    80002f2e:	549c                	lw	a5,40(s1)
    80002f30:	ebc1                	bnez	a5,80002fc0 <usertrap+0xf0>
  usertrapret();
    80002f32:	00000097          	auipc	ra,0x0
    80002f36:	e18080e7          	jalr	-488(ra) # 80002d4a <usertrapret>
}
    80002f3a:	60e2                	ld	ra,24(sp)
    80002f3c:	6442                	ld	s0,16(sp)
    80002f3e:	64a2                	ld	s1,8(sp)
    80002f40:	6902                	ld	s2,0(sp)
    80002f42:	6105                	addi	sp,sp,32
    80002f44:	8082                	ret
    panic("usertrap: not from user mode");
    80002f46:	00005517          	auipc	a0,0x5
    80002f4a:	41a50513          	addi	a0,a0,1050 # 80008360 <states.1773+0x58>
    80002f4e:	ffffd097          	auipc	ra,0xffffd
    80002f52:	5f0080e7          	jalr	1520(ra) # 8000053e <panic>
      exit(-1);
    80002f56:	557d                	li	a0,-1
    80002f58:	00000097          	auipc	ra,0x0
    80002f5c:	9ca080e7          	jalr	-1590(ra) # 80002922 <exit>
    80002f60:	bf4d                	j	80002f12 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002f62:	00000097          	auipc	ra,0x0
    80002f66:	ecc080e7          	jalr	-308(ra) # 80002e2e <devintr>
    80002f6a:	892a                	mv	s2,a0
    80002f6c:	c501                	beqz	a0,80002f74 <usertrap+0xa4>
  if(p->killed)
    80002f6e:	549c                	lw	a5,40(s1)
    80002f70:	c3a1                	beqz	a5,80002fb0 <usertrap+0xe0>
    80002f72:	a815                	j	80002fa6 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f74:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f78:	5890                	lw	a2,48(s1)
    80002f7a:	00005517          	auipc	a0,0x5
    80002f7e:	40650513          	addi	a0,a0,1030 # 80008380 <states.1773+0x78>
    80002f82:	ffffd097          	auipc	ra,0xffffd
    80002f86:	606080e7          	jalr	1542(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f8a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f8e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f92:	00005517          	auipc	a0,0x5
    80002f96:	41e50513          	addi	a0,a0,1054 # 800083b0 <states.1773+0xa8>
    80002f9a:	ffffd097          	auipc	ra,0xffffd
    80002f9e:	5ee080e7          	jalr	1518(ra) # 80000588 <printf>
    p->killed = 1;
    80002fa2:	4785                	li	a5,1
    80002fa4:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002fa6:	557d                	li	a0,-1
    80002fa8:	00000097          	auipc	ra,0x0
    80002fac:	97a080e7          	jalr	-1670(ra) # 80002922 <exit>
  if(which_dev == 2)
    80002fb0:	4789                	li	a5,2
    80002fb2:	f8f910e3          	bne	s2,a5,80002f32 <usertrap+0x62>
    yield();
    80002fb6:	fffff097          	auipc	ra,0xfffff
    80002fba:	638080e7          	jalr	1592(ra) # 800025ee <yield>
    80002fbe:	bf95                	j	80002f32 <usertrap+0x62>
  int which_dev = 0;
    80002fc0:	4901                	li	s2,0
    80002fc2:	b7d5                	j	80002fa6 <usertrap+0xd6>

0000000080002fc4 <kerneltrap>:
{
    80002fc4:	7179                	addi	sp,sp,-48
    80002fc6:	f406                	sd	ra,40(sp)
    80002fc8:	f022                	sd	s0,32(sp)
    80002fca:	ec26                	sd	s1,24(sp)
    80002fcc:	e84a                	sd	s2,16(sp)
    80002fce:	e44e                	sd	s3,8(sp)
    80002fd0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fd2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fd6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fda:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002fde:	1004f793          	andi	a5,s1,256
    80002fe2:	cb85                	beqz	a5,80003012 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fe4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002fe8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002fea:	ef85                	bnez	a5,80003022 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002fec:	00000097          	auipc	ra,0x0
    80002ff0:	e42080e7          	jalr	-446(ra) # 80002e2e <devintr>
    80002ff4:	cd1d                	beqz	a0,80003032 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ff6:	4789                	li	a5,2
    80002ff8:	06f50a63          	beq	a0,a5,8000306c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ffc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003000:	10049073          	csrw	sstatus,s1
}
    80003004:	70a2                	ld	ra,40(sp)
    80003006:	7402                	ld	s0,32(sp)
    80003008:	64e2                	ld	s1,24(sp)
    8000300a:	6942                	ld	s2,16(sp)
    8000300c:	69a2                	ld	s3,8(sp)
    8000300e:	6145                	addi	sp,sp,48
    80003010:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003012:	00005517          	auipc	a0,0x5
    80003016:	3be50513          	addi	a0,a0,958 # 800083d0 <states.1773+0xc8>
    8000301a:	ffffd097          	auipc	ra,0xffffd
    8000301e:	524080e7          	jalr	1316(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003022:	00005517          	auipc	a0,0x5
    80003026:	3d650513          	addi	a0,a0,982 # 800083f8 <states.1773+0xf0>
    8000302a:	ffffd097          	auipc	ra,0xffffd
    8000302e:	514080e7          	jalr	1300(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003032:	85ce                	mv	a1,s3
    80003034:	00005517          	auipc	a0,0x5
    80003038:	3e450513          	addi	a0,a0,996 # 80008418 <states.1773+0x110>
    8000303c:	ffffd097          	auipc	ra,0xffffd
    80003040:	54c080e7          	jalr	1356(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003044:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003048:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000304c:	00005517          	auipc	a0,0x5
    80003050:	3dc50513          	addi	a0,a0,988 # 80008428 <states.1773+0x120>
    80003054:	ffffd097          	auipc	ra,0xffffd
    80003058:	534080e7          	jalr	1332(ra) # 80000588 <printf>
    panic("kerneltrap");
    8000305c:	00005517          	auipc	a0,0x5
    80003060:	3e450513          	addi	a0,a0,996 # 80008440 <states.1773+0x138>
    80003064:	ffffd097          	auipc	ra,0xffffd
    80003068:	4da080e7          	jalr	1242(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000306c:	fffff097          	auipc	ra,0xfffff
    80003070:	dfc080e7          	jalr	-516(ra) # 80001e68 <myproc>
    80003074:	d541                	beqz	a0,80002ffc <kerneltrap+0x38>
    80003076:	fffff097          	auipc	ra,0xfffff
    8000307a:	df2080e7          	jalr	-526(ra) # 80001e68 <myproc>
    8000307e:	4d18                	lw	a4,24(a0)
    80003080:	4791                	li	a5,4
    80003082:	f6f71de3          	bne	a4,a5,80002ffc <kerneltrap+0x38>
    yield();
    80003086:	fffff097          	auipc	ra,0xfffff
    8000308a:	568080e7          	jalr	1384(ra) # 800025ee <yield>
    8000308e:	b7bd                	j	80002ffc <kerneltrap+0x38>

0000000080003090 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003090:	1101                	addi	sp,sp,-32
    80003092:	ec06                	sd	ra,24(sp)
    80003094:	e822                	sd	s0,16(sp)
    80003096:	e426                	sd	s1,8(sp)
    80003098:	1000                	addi	s0,sp,32
    8000309a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000309c:	fffff097          	auipc	ra,0xfffff
    800030a0:	dcc080e7          	jalr	-564(ra) # 80001e68 <myproc>
  switch (n) {
    800030a4:	4795                	li	a5,5
    800030a6:	0497e163          	bltu	a5,s1,800030e8 <argraw+0x58>
    800030aa:	048a                	slli	s1,s1,0x2
    800030ac:	00005717          	auipc	a4,0x5
    800030b0:	3cc70713          	addi	a4,a4,972 # 80008478 <states.1773+0x170>
    800030b4:	94ba                	add	s1,s1,a4
    800030b6:	409c                	lw	a5,0(s1)
    800030b8:	97ba                	add	a5,a5,a4
    800030ba:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800030bc:	7d3c                	ld	a5,120(a0)
    800030be:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800030c0:	60e2                	ld	ra,24(sp)
    800030c2:	6442                	ld	s0,16(sp)
    800030c4:	64a2                	ld	s1,8(sp)
    800030c6:	6105                	addi	sp,sp,32
    800030c8:	8082                	ret
    return p->trapframe->a1;
    800030ca:	7d3c                	ld	a5,120(a0)
    800030cc:	7fa8                	ld	a0,120(a5)
    800030ce:	bfcd                	j	800030c0 <argraw+0x30>
    return p->trapframe->a2;
    800030d0:	7d3c                	ld	a5,120(a0)
    800030d2:	63c8                	ld	a0,128(a5)
    800030d4:	b7f5                	j	800030c0 <argraw+0x30>
    return p->trapframe->a3;
    800030d6:	7d3c                	ld	a5,120(a0)
    800030d8:	67c8                	ld	a0,136(a5)
    800030da:	b7dd                	j	800030c0 <argraw+0x30>
    return p->trapframe->a4;
    800030dc:	7d3c                	ld	a5,120(a0)
    800030de:	6bc8                	ld	a0,144(a5)
    800030e0:	b7c5                	j	800030c0 <argraw+0x30>
    return p->trapframe->a5;
    800030e2:	7d3c                	ld	a5,120(a0)
    800030e4:	6fc8                	ld	a0,152(a5)
    800030e6:	bfe9                	j	800030c0 <argraw+0x30>
  panic("argraw");
    800030e8:	00005517          	auipc	a0,0x5
    800030ec:	36850513          	addi	a0,a0,872 # 80008450 <states.1773+0x148>
    800030f0:	ffffd097          	auipc	ra,0xffffd
    800030f4:	44e080e7          	jalr	1102(ra) # 8000053e <panic>

00000000800030f8 <fetchaddr>:
{
    800030f8:	1101                	addi	sp,sp,-32
    800030fa:	ec06                	sd	ra,24(sp)
    800030fc:	e822                	sd	s0,16(sp)
    800030fe:	e426                	sd	s1,8(sp)
    80003100:	e04a                	sd	s2,0(sp)
    80003102:	1000                	addi	s0,sp,32
    80003104:	84aa                	mv	s1,a0
    80003106:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003108:	fffff097          	auipc	ra,0xfffff
    8000310c:	d60080e7          	jalr	-672(ra) # 80001e68 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003110:	753c                	ld	a5,104(a0)
    80003112:	02f4f863          	bgeu	s1,a5,80003142 <fetchaddr+0x4a>
    80003116:	00848713          	addi	a4,s1,8
    8000311a:	02e7e663          	bltu	a5,a4,80003146 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000311e:	46a1                	li	a3,8
    80003120:	8626                	mv	a2,s1
    80003122:	85ca                	mv	a1,s2
    80003124:	7928                	ld	a0,112(a0)
    80003126:	ffffe097          	auipc	ra,0xffffe
    8000312a:	5fc080e7          	jalr	1532(ra) # 80001722 <copyin>
    8000312e:	00a03533          	snez	a0,a0
    80003132:	40a00533          	neg	a0,a0
}
    80003136:	60e2                	ld	ra,24(sp)
    80003138:	6442                	ld	s0,16(sp)
    8000313a:	64a2                	ld	s1,8(sp)
    8000313c:	6902                	ld	s2,0(sp)
    8000313e:	6105                	addi	sp,sp,32
    80003140:	8082                	ret
    return -1;
    80003142:	557d                	li	a0,-1
    80003144:	bfcd                	j	80003136 <fetchaddr+0x3e>
    80003146:	557d                	li	a0,-1
    80003148:	b7fd                	j	80003136 <fetchaddr+0x3e>

000000008000314a <fetchstr>:
{
    8000314a:	7179                	addi	sp,sp,-48
    8000314c:	f406                	sd	ra,40(sp)
    8000314e:	f022                	sd	s0,32(sp)
    80003150:	ec26                	sd	s1,24(sp)
    80003152:	e84a                	sd	s2,16(sp)
    80003154:	e44e                	sd	s3,8(sp)
    80003156:	1800                	addi	s0,sp,48
    80003158:	892a                	mv	s2,a0
    8000315a:	84ae                	mv	s1,a1
    8000315c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000315e:	fffff097          	auipc	ra,0xfffff
    80003162:	d0a080e7          	jalr	-758(ra) # 80001e68 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003166:	86ce                	mv	a3,s3
    80003168:	864a                	mv	a2,s2
    8000316a:	85a6                	mv	a1,s1
    8000316c:	7928                	ld	a0,112(a0)
    8000316e:	ffffe097          	auipc	ra,0xffffe
    80003172:	640080e7          	jalr	1600(ra) # 800017ae <copyinstr>
  if(err < 0)
    80003176:	00054763          	bltz	a0,80003184 <fetchstr+0x3a>
  return strlen(buf);
    8000317a:	8526                	mv	a0,s1
    8000317c:	ffffe097          	auipc	ra,0xffffe
    80003180:	d0c080e7          	jalr	-756(ra) # 80000e88 <strlen>
}
    80003184:	70a2                	ld	ra,40(sp)
    80003186:	7402                	ld	s0,32(sp)
    80003188:	64e2                	ld	s1,24(sp)
    8000318a:	6942                	ld	s2,16(sp)
    8000318c:	69a2                	ld	s3,8(sp)
    8000318e:	6145                	addi	sp,sp,48
    80003190:	8082                	ret

0000000080003192 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003192:	1101                	addi	sp,sp,-32
    80003194:	ec06                	sd	ra,24(sp)
    80003196:	e822                	sd	s0,16(sp)
    80003198:	e426                	sd	s1,8(sp)
    8000319a:	1000                	addi	s0,sp,32
    8000319c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000319e:	00000097          	auipc	ra,0x0
    800031a2:	ef2080e7          	jalr	-270(ra) # 80003090 <argraw>
    800031a6:	c088                	sw	a0,0(s1)
  return 0;
}
    800031a8:	4501                	li	a0,0
    800031aa:	60e2                	ld	ra,24(sp)
    800031ac:	6442                	ld	s0,16(sp)
    800031ae:	64a2                	ld	s1,8(sp)
    800031b0:	6105                	addi	sp,sp,32
    800031b2:	8082                	ret

00000000800031b4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800031b4:	1101                	addi	sp,sp,-32
    800031b6:	ec06                	sd	ra,24(sp)
    800031b8:	e822                	sd	s0,16(sp)
    800031ba:	e426                	sd	s1,8(sp)
    800031bc:	1000                	addi	s0,sp,32
    800031be:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031c0:	00000097          	auipc	ra,0x0
    800031c4:	ed0080e7          	jalr	-304(ra) # 80003090 <argraw>
    800031c8:	e088                	sd	a0,0(s1)
  return 0;
}
    800031ca:	4501                	li	a0,0
    800031cc:	60e2                	ld	ra,24(sp)
    800031ce:	6442                	ld	s0,16(sp)
    800031d0:	64a2                	ld	s1,8(sp)
    800031d2:	6105                	addi	sp,sp,32
    800031d4:	8082                	ret

00000000800031d6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800031d6:	1101                	addi	sp,sp,-32
    800031d8:	ec06                	sd	ra,24(sp)
    800031da:	e822                	sd	s0,16(sp)
    800031dc:	e426                	sd	s1,8(sp)
    800031de:	e04a                	sd	s2,0(sp)
    800031e0:	1000                	addi	s0,sp,32
    800031e2:	84ae                	mv	s1,a1
    800031e4:	8932                	mv	s2,a2
  *ip = argraw(n);
    800031e6:	00000097          	auipc	ra,0x0
    800031ea:	eaa080e7          	jalr	-342(ra) # 80003090 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800031ee:	864a                	mv	a2,s2
    800031f0:	85a6                	mv	a1,s1
    800031f2:	00000097          	auipc	ra,0x0
    800031f6:	f58080e7          	jalr	-168(ra) # 8000314a <fetchstr>
}
    800031fa:	60e2                	ld	ra,24(sp)
    800031fc:	6442                	ld	s0,16(sp)
    800031fe:	64a2                	ld	s1,8(sp)
    80003200:	6902                	ld	s2,0(sp)
    80003202:	6105                	addi	sp,sp,32
    80003204:	8082                	ret

0000000080003206 <syscall>:
[SYS_set_cpu] sys_set_cpu,
};

void
syscall(void)
{
    80003206:	1101                	addi	sp,sp,-32
    80003208:	ec06                	sd	ra,24(sp)
    8000320a:	e822                	sd	s0,16(sp)
    8000320c:	e426                	sd	s1,8(sp)
    8000320e:	e04a                	sd	s2,0(sp)
    80003210:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003212:	fffff097          	auipc	ra,0xfffff
    80003216:	c56080e7          	jalr	-938(ra) # 80001e68 <myproc>
    8000321a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000321c:	07853903          	ld	s2,120(a0)
    80003220:	0a893783          	ld	a5,168(s2)
    80003224:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003228:	37fd                	addiw	a5,a5,-1
    8000322a:	4759                	li	a4,22
    8000322c:	00f76f63          	bltu	a4,a5,8000324a <syscall+0x44>
    80003230:	00369713          	slli	a4,a3,0x3
    80003234:	00005797          	auipc	a5,0x5
    80003238:	25c78793          	addi	a5,a5,604 # 80008490 <syscalls>
    8000323c:	97ba                	add	a5,a5,a4
    8000323e:	639c                	ld	a5,0(a5)
    80003240:	c789                	beqz	a5,8000324a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003242:	9782                	jalr	a5
    80003244:	06a93823          	sd	a0,112(s2)
    80003248:	a839                	j	80003266 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000324a:	17848613          	addi	a2,s1,376
    8000324e:	588c                	lw	a1,48(s1)
    80003250:	00005517          	auipc	a0,0x5
    80003254:	20850513          	addi	a0,a0,520 # 80008458 <states.1773+0x150>
    80003258:	ffffd097          	auipc	ra,0xffffd
    8000325c:	330080e7          	jalr	816(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003260:	7cbc                	ld	a5,120(s1)
    80003262:	577d                	li	a4,-1
    80003264:	fbb8                	sd	a4,112(a5)
  }
}
    80003266:	60e2                	ld	ra,24(sp)
    80003268:	6442                	ld	s0,16(sp)
    8000326a:	64a2                	ld	s1,8(sp)
    8000326c:	6902                	ld	s2,0(sp)
    8000326e:	6105                	addi	sp,sp,32
    80003270:	8082                	ret

0000000080003272 <sys_set_cpu>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_set_cpu(void)
{
    80003272:	1101                	addi	sp,sp,-32
    80003274:	ec06                	sd	ra,24(sp)
    80003276:	e822                	sd	s0,16(sp)
    80003278:	1000                	addi	s0,sp,32
  int cpu_num;
  if(argint(0, &cpu_num) < 0)
    8000327a:	fec40593          	addi	a1,s0,-20
    8000327e:	4501                	li	a0,0
    80003280:	00000097          	auipc	ra,0x0
    80003284:	f12080e7          	jalr	-238(ra) # 80003192 <argint>
    80003288:	87aa                	mv	a5,a0
    return -1;
    8000328a:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    8000328c:	0007c863          	bltz	a5,8000329c <sys_set_cpu+0x2a>
  return set_cpu(cpu_num); 
    80003290:	fec42503          	lw	a0,-20(s0)
    80003294:	00000097          	auipc	ra,0x0
    80003298:	990080e7          	jalr	-1648(ra) # 80002c24 <set_cpu>
}
    8000329c:	60e2                	ld	ra,24(sp)
    8000329e:	6442                	ld	s0,16(sp)
    800032a0:	6105                	addi	sp,sp,32
    800032a2:	8082                	ret

00000000800032a4 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    800032a4:	1141                	addi	sp,sp,-16
    800032a6:	e406                	sd	ra,8(sp)
    800032a8:	e022                	sd	s0,0(sp)
    800032aa:	0800                	addi	s0,sp,16
  return get_cpu(); 
    800032ac:	00000097          	auipc	ra,0x0
    800032b0:	9b8080e7          	jalr	-1608(ra) # 80002c64 <get_cpu>
}
    800032b4:	60a2                	ld	ra,8(sp)
    800032b6:	6402                	ld	s0,0(sp)
    800032b8:	0141                	addi	sp,sp,16
    800032ba:	8082                	ret

00000000800032bc <sys_exit>:

uint64
sys_exit(void)
{
    800032bc:	1101                	addi	sp,sp,-32
    800032be:	ec06                	sd	ra,24(sp)
    800032c0:	e822                	sd	s0,16(sp)
    800032c2:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800032c4:	fec40593          	addi	a1,s0,-20
    800032c8:	4501                	li	a0,0
    800032ca:	00000097          	auipc	ra,0x0
    800032ce:	ec8080e7          	jalr	-312(ra) # 80003192 <argint>
    return -1;
    800032d2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800032d4:	00054963          	bltz	a0,800032e6 <sys_exit+0x2a>
  exit(n);
    800032d8:	fec42503          	lw	a0,-20(s0)
    800032dc:	fffff097          	auipc	ra,0xfffff
    800032e0:	646080e7          	jalr	1606(ra) # 80002922 <exit>
  return 0;  // not reached
    800032e4:	4781                	li	a5,0
}
    800032e6:	853e                	mv	a0,a5
    800032e8:	60e2                	ld	ra,24(sp)
    800032ea:	6442                	ld	s0,16(sp)
    800032ec:	6105                	addi	sp,sp,32
    800032ee:	8082                	ret

00000000800032f0 <sys_getpid>:

uint64
sys_getpid(void)
{
    800032f0:	1141                	addi	sp,sp,-16
    800032f2:	e406                	sd	ra,8(sp)
    800032f4:	e022                	sd	s0,0(sp)
    800032f6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800032f8:	fffff097          	auipc	ra,0xfffff
    800032fc:	b70080e7          	jalr	-1168(ra) # 80001e68 <myproc>
}
    80003300:	5908                	lw	a0,48(a0)
    80003302:	60a2                	ld	ra,8(sp)
    80003304:	6402                	ld	s0,0(sp)
    80003306:	0141                	addi	sp,sp,16
    80003308:	8082                	ret

000000008000330a <sys_fork>:

uint64
sys_fork(void)
{
    8000330a:	1141                	addi	sp,sp,-16
    8000330c:	e406                	sd	ra,8(sp)
    8000330e:	e022                	sd	s0,0(sp)
    80003310:	0800                	addi	s0,sp,16
  return fork();
    80003312:	fffff097          	auipc	ra,0xfffff
    80003316:	fb4080e7          	jalr	-76(ra) # 800022c6 <fork>
}
    8000331a:	60a2                	ld	ra,8(sp)
    8000331c:	6402                	ld	s0,0(sp)
    8000331e:	0141                	addi	sp,sp,16
    80003320:	8082                	ret

0000000080003322 <sys_wait>:

uint64
sys_wait(void)
{
    80003322:	1101                	addi	sp,sp,-32
    80003324:	ec06                	sd	ra,24(sp)
    80003326:	e822                	sd	s0,16(sp)
    80003328:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000332a:	fe840593          	addi	a1,s0,-24
    8000332e:	4501                	li	a0,0
    80003330:	00000097          	auipc	ra,0x0
    80003334:	e84080e7          	jalr	-380(ra) # 800031b4 <argaddr>
    80003338:	87aa                	mv	a5,a0
    return -1;
    8000333a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000333c:	0007c863          	bltz	a5,8000334c <sys_wait+0x2a>
  return wait(p);
    80003340:	fe843503          	ld	a0,-24(s0)
    80003344:	fffff097          	auipc	ra,0xfffff
    80003348:	390080e7          	jalr	912(ra) # 800026d4 <wait>
}
    8000334c:	60e2                	ld	ra,24(sp)
    8000334e:	6442                	ld	s0,16(sp)
    80003350:	6105                	addi	sp,sp,32
    80003352:	8082                	ret

0000000080003354 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003354:	7179                	addi	sp,sp,-48
    80003356:	f406                	sd	ra,40(sp)
    80003358:	f022                	sd	s0,32(sp)
    8000335a:	ec26                	sd	s1,24(sp)
    8000335c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000335e:	fdc40593          	addi	a1,s0,-36
    80003362:	4501                	li	a0,0
    80003364:	00000097          	auipc	ra,0x0
    80003368:	e2e080e7          	jalr	-466(ra) # 80003192 <argint>
    8000336c:	87aa                	mv	a5,a0
    return -1;
    8000336e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003370:	0207c063          	bltz	a5,80003390 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003374:	fffff097          	auipc	ra,0xfffff
    80003378:	af4080e7          	jalr	-1292(ra) # 80001e68 <myproc>
    8000337c:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    8000337e:	fdc42503          	lw	a0,-36(s0)
    80003382:	fffff097          	auipc	ra,0xfffff
    80003386:	ed0080e7          	jalr	-304(ra) # 80002252 <growproc>
    8000338a:	00054863          	bltz	a0,8000339a <sys_sbrk+0x46>
    return -1;
  return addr;
    8000338e:	8526                	mv	a0,s1
}
    80003390:	70a2                	ld	ra,40(sp)
    80003392:	7402                	ld	s0,32(sp)
    80003394:	64e2                	ld	s1,24(sp)
    80003396:	6145                	addi	sp,sp,48
    80003398:	8082                	ret
    return -1;
    8000339a:	557d                	li	a0,-1
    8000339c:	bfd5                	j	80003390 <sys_sbrk+0x3c>

000000008000339e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000339e:	7139                	addi	sp,sp,-64
    800033a0:	fc06                	sd	ra,56(sp)
    800033a2:	f822                	sd	s0,48(sp)
    800033a4:	f426                	sd	s1,40(sp)
    800033a6:	f04a                	sd	s2,32(sp)
    800033a8:	ec4e                	sd	s3,24(sp)
    800033aa:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800033ac:	fcc40593          	addi	a1,s0,-52
    800033b0:	4501                	li	a0,0
    800033b2:	00000097          	auipc	ra,0x0
    800033b6:	de0080e7          	jalr	-544(ra) # 80003192 <argint>
    return -1;
    800033ba:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800033bc:	06054563          	bltz	a0,80003426 <sys_sleep+0x88>
  acquire(&tickslock);
    800033c0:	00014517          	auipc	a0,0x14
    800033c4:	65850513          	addi	a0,a0,1624 # 80017a18 <tickslock>
    800033c8:	ffffe097          	auipc	ra,0xffffe
    800033cc:	81c080e7          	jalr	-2020(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800033d0:	00006917          	auipc	s2,0x6
    800033d4:	c6092903          	lw	s2,-928(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800033d8:	fcc42783          	lw	a5,-52(s0)
    800033dc:	cf85                	beqz	a5,80003414 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800033de:	00014997          	auipc	s3,0x14
    800033e2:	63a98993          	addi	s3,s3,1594 # 80017a18 <tickslock>
    800033e6:	00006497          	auipc	s1,0x6
    800033ea:	c4a48493          	addi	s1,s1,-950 # 80009030 <ticks>
    if(myproc()->killed){
    800033ee:	fffff097          	auipc	ra,0xfffff
    800033f2:	a7a080e7          	jalr	-1414(ra) # 80001e68 <myproc>
    800033f6:	551c                	lw	a5,40(a0)
    800033f8:	ef9d                	bnez	a5,80003436 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800033fa:	85ce                	mv	a1,s3
    800033fc:	8526                	mv	a0,s1
    800033fe:	fffff097          	auipc	ra,0xfffff
    80003402:	258080e7          	jalr	600(ra) # 80002656 <sleep>
  while(ticks - ticks0 < n){
    80003406:	409c                	lw	a5,0(s1)
    80003408:	412787bb          	subw	a5,a5,s2
    8000340c:	fcc42703          	lw	a4,-52(s0)
    80003410:	fce7efe3          	bltu	a5,a4,800033ee <sys_sleep+0x50>
  }
  release(&tickslock);
    80003414:	00014517          	auipc	a0,0x14
    80003418:	60450513          	addi	a0,a0,1540 # 80017a18 <tickslock>
    8000341c:	ffffe097          	auipc	ra,0xffffe
    80003420:	88e080e7          	jalr	-1906(ra) # 80000caa <release>
  return 0;
    80003424:	4781                	li	a5,0
}
    80003426:	853e                	mv	a0,a5
    80003428:	70e2                	ld	ra,56(sp)
    8000342a:	7442                	ld	s0,48(sp)
    8000342c:	74a2                	ld	s1,40(sp)
    8000342e:	7902                	ld	s2,32(sp)
    80003430:	69e2                	ld	s3,24(sp)
    80003432:	6121                	addi	sp,sp,64
    80003434:	8082                	ret
      release(&tickslock);
    80003436:	00014517          	auipc	a0,0x14
    8000343a:	5e250513          	addi	a0,a0,1506 # 80017a18 <tickslock>
    8000343e:	ffffe097          	auipc	ra,0xffffe
    80003442:	86c080e7          	jalr	-1940(ra) # 80000caa <release>
      return -1;
    80003446:	57fd                	li	a5,-1
    80003448:	bff9                	j	80003426 <sys_sleep+0x88>

000000008000344a <sys_kill>:

uint64
sys_kill(void)
{
    8000344a:	1101                	addi	sp,sp,-32
    8000344c:	ec06                	sd	ra,24(sp)
    8000344e:	e822                	sd	s0,16(sp)
    80003450:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003452:	fec40593          	addi	a1,s0,-20
    80003456:	4501                	li	a0,0
    80003458:	00000097          	auipc	ra,0x0
    8000345c:	d3a080e7          	jalr	-710(ra) # 80003192 <argint>
    80003460:	87aa                	mv	a5,a0
    return -1;
    80003462:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003464:	0007c863          	bltz	a5,80003474 <sys_kill+0x2a>
  return kill(pid);
    80003468:	fec42503          	lw	a0,-20(s0)
    8000346c:	fffff097          	auipc	ra,0xfffff
    80003470:	5a6080e7          	jalr	1446(ra) # 80002a12 <kill>
}
    80003474:	60e2                	ld	ra,24(sp)
    80003476:	6442                	ld	s0,16(sp)
    80003478:	6105                	addi	sp,sp,32
    8000347a:	8082                	ret

000000008000347c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000347c:	1101                	addi	sp,sp,-32
    8000347e:	ec06                	sd	ra,24(sp)
    80003480:	e822                	sd	s0,16(sp)
    80003482:	e426                	sd	s1,8(sp)
    80003484:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003486:	00014517          	auipc	a0,0x14
    8000348a:	59250513          	addi	a0,a0,1426 # 80017a18 <tickslock>
    8000348e:	ffffd097          	auipc	ra,0xffffd
    80003492:	756080e7          	jalr	1878(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003496:	00006497          	auipc	s1,0x6
    8000349a:	b9a4a483          	lw	s1,-1126(s1) # 80009030 <ticks>
  release(&tickslock);
    8000349e:	00014517          	auipc	a0,0x14
    800034a2:	57a50513          	addi	a0,a0,1402 # 80017a18 <tickslock>
    800034a6:	ffffe097          	auipc	ra,0xffffe
    800034aa:	804080e7          	jalr	-2044(ra) # 80000caa <release>
  return xticks;
}
    800034ae:	02049513          	slli	a0,s1,0x20
    800034b2:	9101                	srli	a0,a0,0x20
    800034b4:	60e2                	ld	ra,24(sp)
    800034b6:	6442                	ld	s0,16(sp)
    800034b8:	64a2                	ld	s1,8(sp)
    800034ba:	6105                	addi	sp,sp,32
    800034bc:	8082                	ret

00000000800034be <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800034be:	7179                	addi	sp,sp,-48
    800034c0:	f406                	sd	ra,40(sp)
    800034c2:	f022                	sd	s0,32(sp)
    800034c4:	ec26                	sd	s1,24(sp)
    800034c6:	e84a                	sd	s2,16(sp)
    800034c8:	e44e                	sd	s3,8(sp)
    800034ca:	e052                	sd	s4,0(sp)
    800034cc:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800034ce:	00005597          	auipc	a1,0x5
    800034d2:	08258593          	addi	a1,a1,130 # 80008550 <syscalls+0xc0>
    800034d6:	00014517          	auipc	a0,0x14
    800034da:	55a50513          	addi	a0,a0,1370 # 80017a30 <bcache>
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	676080e7          	jalr	1654(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034e6:	0001c797          	auipc	a5,0x1c
    800034ea:	54a78793          	addi	a5,a5,1354 # 8001fa30 <bcache+0x8000>
    800034ee:	0001c717          	auipc	a4,0x1c
    800034f2:	7aa70713          	addi	a4,a4,1962 # 8001fc98 <bcache+0x8268>
    800034f6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034fa:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034fe:	00014497          	auipc	s1,0x14
    80003502:	54a48493          	addi	s1,s1,1354 # 80017a48 <bcache+0x18>
    b->next = bcache.head.next;
    80003506:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003508:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000350a:	00005a17          	auipc	s4,0x5
    8000350e:	04ea0a13          	addi	s4,s4,78 # 80008558 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003512:	2b893783          	ld	a5,696(s2)
    80003516:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003518:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000351c:	85d2                	mv	a1,s4
    8000351e:	01048513          	addi	a0,s1,16
    80003522:	00001097          	auipc	ra,0x1
    80003526:	4bc080e7          	jalr	1212(ra) # 800049de <initsleeplock>
    bcache.head.next->prev = b;
    8000352a:	2b893783          	ld	a5,696(s2)
    8000352e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003530:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003534:	45848493          	addi	s1,s1,1112
    80003538:	fd349de3          	bne	s1,s3,80003512 <binit+0x54>
  }
}
    8000353c:	70a2                	ld	ra,40(sp)
    8000353e:	7402                	ld	s0,32(sp)
    80003540:	64e2                	ld	s1,24(sp)
    80003542:	6942                	ld	s2,16(sp)
    80003544:	69a2                	ld	s3,8(sp)
    80003546:	6a02                	ld	s4,0(sp)
    80003548:	6145                	addi	sp,sp,48
    8000354a:	8082                	ret

000000008000354c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000354c:	7179                	addi	sp,sp,-48
    8000354e:	f406                	sd	ra,40(sp)
    80003550:	f022                	sd	s0,32(sp)
    80003552:	ec26                	sd	s1,24(sp)
    80003554:	e84a                	sd	s2,16(sp)
    80003556:	e44e                	sd	s3,8(sp)
    80003558:	1800                	addi	s0,sp,48
    8000355a:	89aa                	mv	s3,a0
    8000355c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000355e:	00014517          	auipc	a0,0x14
    80003562:	4d250513          	addi	a0,a0,1234 # 80017a30 <bcache>
    80003566:	ffffd097          	auipc	ra,0xffffd
    8000356a:	67e080e7          	jalr	1662(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000356e:	0001c497          	auipc	s1,0x1c
    80003572:	77a4b483          	ld	s1,1914(s1) # 8001fce8 <bcache+0x82b8>
    80003576:	0001c797          	auipc	a5,0x1c
    8000357a:	72278793          	addi	a5,a5,1826 # 8001fc98 <bcache+0x8268>
    8000357e:	02f48f63          	beq	s1,a5,800035bc <bread+0x70>
    80003582:	873e                	mv	a4,a5
    80003584:	a021                	j	8000358c <bread+0x40>
    80003586:	68a4                	ld	s1,80(s1)
    80003588:	02e48a63          	beq	s1,a4,800035bc <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000358c:	449c                	lw	a5,8(s1)
    8000358e:	ff379ce3          	bne	a5,s3,80003586 <bread+0x3a>
    80003592:	44dc                	lw	a5,12(s1)
    80003594:	ff2799e3          	bne	a5,s2,80003586 <bread+0x3a>
      b->refcnt++;
    80003598:	40bc                	lw	a5,64(s1)
    8000359a:	2785                	addiw	a5,a5,1
    8000359c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000359e:	00014517          	auipc	a0,0x14
    800035a2:	49250513          	addi	a0,a0,1170 # 80017a30 <bcache>
    800035a6:	ffffd097          	auipc	ra,0xffffd
    800035aa:	704080e7          	jalr	1796(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    800035ae:	01048513          	addi	a0,s1,16
    800035b2:	00001097          	auipc	ra,0x1
    800035b6:	466080e7          	jalr	1126(ra) # 80004a18 <acquiresleep>
      return b;
    800035ba:	a8b9                	j	80003618 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035bc:	0001c497          	auipc	s1,0x1c
    800035c0:	7244b483          	ld	s1,1828(s1) # 8001fce0 <bcache+0x82b0>
    800035c4:	0001c797          	auipc	a5,0x1c
    800035c8:	6d478793          	addi	a5,a5,1748 # 8001fc98 <bcache+0x8268>
    800035cc:	00f48863          	beq	s1,a5,800035dc <bread+0x90>
    800035d0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800035d2:	40bc                	lw	a5,64(s1)
    800035d4:	cf81                	beqz	a5,800035ec <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035d6:	64a4                	ld	s1,72(s1)
    800035d8:	fee49de3          	bne	s1,a4,800035d2 <bread+0x86>
  panic("bget: no buffers");
    800035dc:	00005517          	auipc	a0,0x5
    800035e0:	f8450513          	addi	a0,a0,-124 # 80008560 <syscalls+0xd0>
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	f5a080e7          	jalr	-166(ra) # 8000053e <panic>
      b->dev = dev;
    800035ec:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800035f0:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800035f4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035f8:	4785                	li	a5,1
    800035fa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035fc:	00014517          	auipc	a0,0x14
    80003600:	43450513          	addi	a0,a0,1076 # 80017a30 <bcache>
    80003604:	ffffd097          	auipc	ra,0xffffd
    80003608:	6a6080e7          	jalr	1702(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    8000360c:	01048513          	addi	a0,s1,16
    80003610:	00001097          	auipc	ra,0x1
    80003614:	408080e7          	jalr	1032(ra) # 80004a18 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003618:	409c                	lw	a5,0(s1)
    8000361a:	cb89                	beqz	a5,8000362c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000361c:	8526                	mv	a0,s1
    8000361e:	70a2                	ld	ra,40(sp)
    80003620:	7402                	ld	s0,32(sp)
    80003622:	64e2                	ld	s1,24(sp)
    80003624:	6942                	ld	s2,16(sp)
    80003626:	69a2                	ld	s3,8(sp)
    80003628:	6145                	addi	sp,sp,48
    8000362a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000362c:	4581                	li	a1,0
    8000362e:	8526                	mv	a0,s1
    80003630:	00003097          	auipc	ra,0x3
    80003634:	f06080e7          	jalr	-250(ra) # 80006536 <virtio_disk_rw>
    b->valid = 1;
    80003638:	4785                	li	a5,1
    8000363a:	c09c                	sw	a5,0(s1)
  return b;
    8000363c:	b7c5                	j	8000361c <bread+0xd0>

000000008000363e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000363e:	1101                	addi	sp,sp,-32
    80003640:	ec06                	sd	ra,24(sp)
    80003642:	e822                	sd	s0,16(sp)
    80003644:	e426                	sd	s1,8(sp)
    80003646:	1000                	addi	s0,sp,32
    80003648:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000364a:	0541                	addi	a0,a0,16
    8000364c:	00001097          	auipc	ra,0x1
    80003650:	466080e7          	jalr	1126(ra) # 80004ab2 <holdingsleep>
    80003654:	cd01                	beqz	a0,8000366c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003656:	4585                	li	a1,1
    80003658:	8526                	mv	a0,s1
    8000365a:	00003097          	auipc	ra,0x3
    8000365e:	edc080e7          	jalr	-292(ra) # 80006536 <virtio_disk_rw>
}
    80003662:	60e2                	ld	ra,24(sp)
    80003664:	6442                	ld	s0,16(sp)
    80003666:	64a2                	ld	s1,8(sp)
    80003668:	6105                	addi	sp,sp,32
    8000366a:	8082                	ret
    panic("bwrite");
    8000366c:	00005517          	auipc	a0,0x5
    80003670:	f0c50513          	addi	a0,a0,-244 # 80008578 <syscalls+0xe8>
    80003674:	ffffd097          	auipc	ra,0xffffd
    80003678:	eca080e7          	jalr	-310(ra) # 8000053e <panic>

000000008000367c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000367c:	1101                	addi	sp,sp,-32
    8000367e:	ec06                	sd	ra,24(sp)
    80003680:	e822                	sd	s0,16(sp)
    80003682:	e426                	sd	s1,8(sp)
    80003684:	e04a                	sd	s2,0(sp)
    80003686:	1000                	addi	s0,sp,32
    80003688:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000368a:	01050913          	addi	s2,a0,16
    8000368e:	854a                	mv	a0,s2
    80003690:	00001097          	auipc	ra,0x1
    80003694:	422080e7          	jalr	1058(ra) # 80004ab2 <holdingsleep>
    80003698:	c92d                	beqz	a0,8000370a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000369a:	854a                	mv	a0,s2
    8000369c:	00001097          	auipc	ra,0x1
    800036a0:	3d2080e7          	jalr	978(ra) # 80004a6e <releasesleep>

  acquire(&bcache.lock);
    800036a4:	00014517          	auipc	a0,0x14
    800036a8:	38c50513          	addi	a0,a0,908 # 80017a30 <bcache>
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	538080e7          	jalr	1336(ra) # 80000be4 <acquire>
  b->refcnt--;
    800036b4:	40bc                	lw	a5,64(s1)
    800036b6:	37fd                	addiw	a5,a5,-1
    800036b8:	0007871b          	sext.w	a4,a5
    800036bc:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800036be:	eb05                	bnez	a4,800036ee <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800036c0:	68bc                	ld	a5,80(s1)
    800036c2:	64b8                	ld	a4,72(s1)
    800036c4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800036c6:	64bc                	ld	a5,72(s1)
    800036c8:	68b8                	ld	a4,80(s1)
    800036ca:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800036cc:	0001c797          	auipc	a5,0x1c
    800036d0:	36478793          	addi	a5,a5,868 # 8001fa30 <bcache+0x8000>
    800036d4:	2b87b703          	ld	a4,696(a5)
    800036d8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800036da:	0001c717          	auipc	a4,0x1c
    800036de:	5be70713          	addi	a4,a4,1470 # 8001fc98 <bcache+0x8268>
    800036e2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800036e4:	2b87b703          	ld	a4,696(a5)
    800036e8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036ea:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800036ee:	00014517          	auipc	a0,0x14
    800036f2:	34250513          	addi	a0,a0,834 # 80017a30 <bcache>
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	5b4080e7          	jalr	1460(ra) # 80000caa <release>
}
    800036fe:	60e2                	ld	ra,24(sp)
    80003700:	6442                	ld	s0,16(sp)
    80003702:	64a2                	ld	s1,8(sp)
    80003704:	6902                	ld	s2,0(sp)
    80003706:	6105                	addi	sp,sp,32
    80003708:	8082                	ret
    panic("brelse");
    8000370a:	00005517          	auipc	a0,0x5
    8000370e:	e7650513          	addi	a0,a0,-394 # 80008580 <syscalls+0xf0>
    80003712:	ffffd097          	auipc	ra,0xffffd
    80003716:	e2c080e7          	jalr	-468(ra) # 8000053e <panic>

000000008000371a <bpin>:

void
bpin(struct buf *b) {
    8000371a:	1101                	addi	sp,sp,-32
    8000371c:	ec06                	sd	ra,24(sp)
    8000371e:	e822                	sd	s0,16(sp)
    80003720:	e426                	sd	s1,8(sp)
    80003722:	1000                	addi	s0,sp,32
    80003724:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003726:	00014517          	auipc	a0,0x14
    8000372a:	30a50513          	addi	a0,a0,778 # 80017a30 <bcache>
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	4b6080e7          	jalr	1206(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003736:	40bc                	lw	a5,64(s1)
    80003738:	2785                	addiw	a5,a5,1
    8000373a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000373c:	00014517          	auipc	a0,0x14
    80003740:	2f450513          	addi	a0,a0,756 # 80017a30 <bcache>
    80003744:	ffffd097          	auipc	ra,0xffffd
    80003748:	566080e7          	jalr	1382(ra) # 80000caa <release>
}
    8000374c:	60e2                	ld	ra,24(sp)
    8000374e:	6442                	ld	s0,16(sp)
    80003750:	64a2                	ld	s1,8(sp)
    80003752:	6105                	addi	sp,sp,32
    80003754:	8082                	ret

0000000080003756 <bunpin>:

void
bunpin(struct buf *b) {
    80003756:	1101                	addi	sp,sp,-32
    80003758:	ec06                	sd	ra,24(sp)
    8000375a:	e822                	sd	s0,16(sp)
    8000375c:	e426                	sd	s1,8(sp)
    8000375e:	1000                	addi	s0,sp,32
    80003760:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003762:	00014517          	auipc	a0,0x14
    80003766:	2ce50513          	addi	a0,a0,718 # 80017a30 <bcache>
    8000376a:	ffffd097          	auipc	ra,0xffffd
    8000376e:	47a080e7          	jalr	1146(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003772:	40bc                	lw	a5,64(s1)
    80003774:	37fd                	addiw	a5,a5,-1
    80003776:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003778:	00014517          	auipc	a0,0x14
    8000377c:	2b850513          	addi	a0,a0,696 # 80017a30 <bcache>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	52a080e7          	jalr	1322(ra) # 80000caa <release>
}
    80003788:	60e2                	ld	ra,24(sp)
    8000378a:	6442                	ld	s0,16(sp)
    8000378c:	64a2                	ld	s1,8(sp)
    8000378e:	6105                	addi	sp,sp,32
    80003790:	8082                	ret

0000000080003792 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003792:	1101                	addi	sp,sp,-32
    80003794:	ec06                	sd	ra,24(sp)
    80003796:	e822                	sd	s0,16(sp)
    80003798:	e426                	sd	s1,8(sp)
    8000379a:	e04a                	sd	s2,0(sp)
    8000379c:	1000                	addi	s0,sp,32
    8000379e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800037a0:	00d5d59b          	srliw	a1,a1,0xd
    800037a4:	0001d797          	auipc	a5,0x1d
    800037a8:	9687a783          	lw	a5,-1688(a5) # 8002010c <sb+0x1c>
    800037ac:	9dbd                	addw	a1,a1,a5
    800037ae:	00000097          	auipc	ra,0x0
    800037b2:	d9e080e7          	jalr	-610(ra) # 8000354c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800037b6:	0074f713          	andi	a4,s1,7
    800037ba:	4785                	li	a5,1
    800037bc:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800037c0:	14ce                	slli	s1,s1,0x33
    800037c2:	90d9                	srli	s1,s1,0x36
    800037c4:	00950733          	add	a4,a0,s1
    800037c8:	05874703          	lbu	a4,88(a4)
    800037cc:	00e7f6b3          	and	a3,a5,a4
    800037d0:	c69d                	beqz	a3,800037fe <bfree+0x6c>
    800037d2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800037d4:	94aa                	add	s1,s1,a0
    800037d6:	fff7c793          	not	a5,a5
    800037da:	8ff9                	and	a5,a5,a4
    800037dc:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800037e0:	00001097          	auipc	ra,0x1
    800037e4:	118080e7          	jalr	280(ra) # 800048f8 <log_write>
  brelse(bp);
    800037e8:	854a                	mv	a0,s2
    800037ea:	00000097          	auipc	ra,0x0
    800037ee:	e92080e7          	jalr	-366(ra) # 8000367c <brelse>
}
    800037f2:	60e2                	ld	ra,24(sp)
    800037f4:	6442                	ld	s0,16(sp)
    800037f6:	64a2                	ld	s1,8(sp)
    800037f8:	6902                	ld	s2,0(sp)
    800037fa:	6105                	addi	sp,sp,32
    800037fc:	8082                	ret
    panic("freeing free block");
    800037fe:	00005517          	auipc	a0,0x5
    80003802:	d8a50513          	addi	a0,a0,-630 # 80008588 <syscalls+0xf8>
    80003806:	ffffd097          	auipc	ra,0xffffd
    8000380a:	d38080e7          	jalr	-712(ra) # 8000053e <panic>

000000008000380e <balloc>:
{
    8000380e:	711d                	addi	sp,sp,-96
    80003810:	ec86                	sd	ra,88(sp)
    80003812:	e8a2                	sd	s0,80(sp)
    80003814:	e4a6                	sd	s1,72(sp)
    80003816:	e0ca                	sd	s2,64(sp)
    80003818:	fc4e                	sd	s3,56(sp)
    8000381a:	f852                	sd	s4,48(sp)
    8000381c:	f456                	sd	s5,40(sp)
    8000381e:	f05a                	sd	s6,32(sp)
    80003820:	ec5e                	sd	s7,24(sp)
    80003822:	e862                	sd	s8,16(sp)
    80003824:	e466                	sd	s9,8(sp)
    80003826:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003828:	0001d797          	auipc	a5,0x1d
    8000382c:	8cc7a783          	lw	a5,-1844(a5) # 800200f4 <sb+0x4>
    80003830:	cbd1                	beqz	a5,800038c4 <balloc+0xb6>
    80003832:	8baa                	mv	s7,a0
    80003834:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003836:	0001db17          	auipc	s6,0x1d
    8000383a:	8bab0b13          	addi	s6,s6,-1862 # 800200f0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000383e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003840:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003842:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003844:	6c89                	lui	s9,0x2
    80003846:	a831                	j	80003862 <balloc+0x54>
    brelse(bp);
    80003848:	854a                	mv	a0,s2
    8000384a:	00000097          	auipc	ra,0x0
    8000384e:	e32080e7          	jalr	-462(ra) # 8000367c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003852:	015c87bb          	addw	a5,s9,s5
    80003856:	00078a9b          	sext.w	s5,a5
    8000385a:	004b2703          	lw	a4,4(s6)
    8000385e:	06eaf363          	bgeu	s5,a4,800038c4 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003862:	41fad79b          	sraiw	a5,s5,0x1f
    80003866:	0137d79b          	srliw	a5,a5,0x13
    8000386a:	015787bb          	addw	a5,a5,s5
    8000386e:	40d7d79b          	sraiw	a5,a5,0xd
    80003872:	01cb2583          	lw	a1,28(s6)
    80003876:	9dbd                	addw	a1,a1,a5
    80003878:	855e                	mv	a0,s7
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	cd2080e7          	jalr	-814(ra) # 8000354c <bread>
    80003882:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003884:	004b2503          	lw	a0,4(s6)
    80003888:	000a849b          	sext.w	s1,s5
    8000388c:	8662                	mv	a2,s8
    8000388e:	faa4fde3          	bgeu	s1,a0,80003848 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003892:	41f6579b          	sraiw	a5,a2,0x1f
    80003896:	01d7d69b          	srliw	a3,a5,0x1d
    8000389a:	00c6873b          	addw	a4,a3,a2
    8000389e:	00777793          	andi	a5,a4,7
    800038a2:	9f95                	subw	a5,a5,a3
    800038a4:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800038a8:	4037571b          	sraiw	a4,a4,0x3
    800038ac:	00e906b3          	add	a3,s2,a4
    800038b0:	0586c683          	lbu	a3,88(a3)
    800038b4:	00d7f5b3          	and	a1,a5,a3
    800038b8:	cd91                	beqz	a1,800038d4 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038ba:	2605                	addiw	a2,a2,1
    800038bc:	2485                	addiw	s1,s1,1
    800038be:	fd4618e3          	bne	a2,s4,8000388e <balloc+0x80>
    800038c2:	b759                	j	80003848 <balloc+0x3a>
  panic("balloc: out of blocks");
    800038c4:	00005517          	auipc	a0,0x5
    800038c8:	cdc50513          	addi	a0,a0,-804 # 800085a0 <syscalls+0x110>
    800038cc:	ffffd097          	auipc	ra,0xffffd
    800038d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800038d4:	974a                	add	a4,a4,s2
    800038d6:	8fd5                	or	a5,a5,a3
    800038d8:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800038dc:	854a                	mv	a0,s2
    800038de:	00001097          	auipc	ra,0x1
    800038e2:	01a080e7          	jalr	26(ra) # 800048f8 <log_write>
        brelse(bp);
    800038e6:	854a                	mv	a0,s2
    800038e8:	00000097          	auipc	ra,0x0
    800038ec:	d94080e7          	jalr	-620(ra) # 8000367c <brelse>
  bp = bread(dev, bno);
    800038f0:	85a6                	mv	a1,s1
    800038f2:	855e                	mv	a0,s7
    800038f4:	00000097          	auipc	ra,0x0
    800038f8:	c58080e7          	jalr	-936(ra) # 8000354c <bread>
    800038fc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038fe:	40000613          	li	a2,1024
    80003902:	4581                	li	a1,0
    80003904:	05850513          	addi	a0,a0,88
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	3fc080e7          	jalr	1020(ra) # 80000d04 <memset>
  log_write(bp);
    80003910:	854a                	mv	a0,s2
    80003912:	00001097          	auipc	ra,0x1
    80003916:	fe6080e7          	jalr	-26(ra) # 800048f8 <log_write>
  brelse(bp);
    8000391a:	854a                	mv	a0,s2
    8000391c:	00000097          	auipc	ra,0x0
    80003920:	d60080e7          	jalr	-672(ra) # 8000367c <brelse>
}
    80003924:	8526                	mv	a0,s1
    80003926:	60e6                	ld	ra,88(sp)
    80003928:	6446                	ld	s0,80(sp)
    8000392a:	64a6                	ld	s1,72(sp)
    8000392c:	6906                	ld	s2,64(sp)
    8000392e:	79e2                	ld	s3,56(sp)
    80003930:	7a42                	ld	s4,48(sp)
    80003932:	7aa2                	ld	s5,40(sp)
    80003934:	7b02                	ld	s6,32(sp)
    80003936:	6be2                	ld	s7,24(sp)
    80003938:	6c42                	ld	s8,16(sp)
    8000393a:	6ca2                	ld	s9,8(sp)
    8000393c:	6125                	addi	sp,sp,96
    8000393e:	8082                	ret

0000000080003940 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003940:	7179                	addi	sp,sp,-48
    80003942:	f406                	sd	ra,40(sp)
    80003944:	f022                	sd	s0,32(sp)
    80003946:	ec26                	sd	s1,24(sp)
    80003948:	e84a                	sd	s2,16(sp)
    8000394a:	e44e                	sd	s3,8(sp)
    8000394c:	e052                	sd	s4,0(sp)
    8000394e:	1800                	addi	s0,sp,48
    80003950:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003952:	47ad                	li	a5,11
    80003954:	04b7fe63          	bgeu	a5,a1,800039b0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003958:	ff45849b          	addiw	s1,a1,-12
    8000395c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003960:	0ff00793          	li	a5,255
    80003964:	0ae7e363          	bltu	a5,a4,80003a0a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003968:	08052583          	lw	a1,128(a0)
    8000396c:	c5ad                	beqz	a1,800039d6 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000396e:	00092503          	lw	a0,0(s2)
    80003972:	00000097          	auipc	ra,0x0
    80003976:	bda080e7          	jalr	-1062(ra) # 8000354c <bread>
    8000397a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000397c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003980:	02049593          	slli	a1,s1,0x20
    80003984:	9181                	srli	a1,a1,0x20
    80003986:	058a                	slli	a1,a1,0x2
    80003988:	00b784b3          	add	s1,a5,a1
    8000398c:	0004a983          	lw	s3,0(s1)
    80003990:	04098d63          	beqz	s3,800039ea <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003994:	8552                	mv	a0,s4
    80003996:	00000097          	auipc	ra,0x0
    8000399a:	ce6080e7          	jalr	-794(ra) # 8000367c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000399e:	854e                	mv	a0,s3
    800039a0:	70a2                	ld	ra,40(sp)
    800039a2:	7402                	ld	s0,32(sp)
    800039a4:	64e2                	ld	s1,24(sp)
    800039a6:	6942                	ld	s2,16(sp)
    800039a8:	69a2                	ld	s3,8(sp)
    800039aa:	6a02                	ld	s4,0(sp)
    800039ac:	6145                	addi	sp,sp,48
    800039ae:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800039b0:	02059493          	slli	s1,a1,0x20
    800039b4:	9081                	srli	s1,s1,0x20
    800039b6:	048a                	slli	s1,s1,0x2
    800039b8:	94aa                	add	s1,s1,a0
    800039ba:	0504a983          	lw	s3,80(s1)
    800039be:	fe0990e3          	bnez	s3,8000399e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800039c2:	4108                	lw	a0,0(a0)
    800039c4:	00000097          	auipc	ra,0x0
    800039c8:	e4a080e7          	jalr	-438(ra) # 8000380e <balloc>
    800039cc:	0005099b          	sext.w	s3,a0
    800039d0:	0534a823          	sw	s3,80(s1)
    800039d4:	b7e9                	j	8000399e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800039d6:	4108                	lw	a0,0(a0)
    800039d8:	00000097          	auipc	ra,0x0
    800039dc:	e36080e7          	jalr	-458(ra) # 8000380e <balloc>
    800039e0:	0005059b          	sext.w	a1,a0
    800039e4:	08b92023          	sw	a1,128(s2)
    800039e8:	b759                	j	8000396e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800039ea:	00092503          	lw	a0,0(s2)
    800039ee:	00000097          	auipc	ra,0x0
    800039f2:	e20080e7          	jalr	-480(ra) # 8000380e <balloc>
    800039f6:	0005099b          	sext.w	s3,a0
    800039fa:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800039fe:	8552                	mv	a0,s4
    80003a00:	00001097          	auipc	ra,0x1
    80003a04:	ef8080e7          	jalr	-264(ra) # 800048f8 <log_write>
    80003a08:	b771                	j	80003994 <bmap+0x54>
  panic("bmap: out of range");
    80003a0a:	00005517          	auipc	a0,0x5
    80003a0e:	bae50513          	addi	a0,a0,-1106 # 800085b8 <syscalls+0x128>
    80003a12:	ffffd097          	auipc	ra,0xffffd
    80003a16:	b2c080e7          	jalr	-1236(ra) # 8000053e <panic>

0000000080003a1a <iget>:
{
    80003a1a:	7179                	addi	sp,sp,-48
    80003a1c:	f406                	sd	ra,40(sp)
    80003a1e:	f022                	sd	s0,32(sp)
    80003a20:	ec26                	sd	s1,24(sp)
    80003a22:	e84a                	sd	s2,16(sp)
    80003a24:	e44e                	sd	s3,8(sp)
    80003a26:	e052                	sd	s4,0(sp)
    80003a28:	1800                	addi	s0,sp,48
    80003a2a:	89aa                	mv	s3,a0
    80003a2c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a2e:	0001c517          	auipc	a0,0x1c
    80003a32:	6e250513          	addi	a0,a0,1762 # 80020110 <itable>
    80003a36:	ffffd097          	auipc	ra,0xffffd
    80003a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  empty = 0;
    80003a3e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a40:	0001c497          	auipc	s1,0x1c
    80003a44:	6e848493          	addi	s1,s1,1768 # 80020128 <itable+0x18>
    80003a48:	0001e697          	auipc	a3,0x1e
    80003a4c:	17068693          	addi	a3,a3,368 # 80021bb8 <log>
    80003a50:	a039                	j	80003a5e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a52:	02090b63          	beqz	s2,80003a88 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a56:	08848493          	addi	s1,s1,136
    80003a5a:	02d48a63          	beq	s1,a3,80003a8e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a5e:	449c                	lw	a5,8(s1)
    80003a60:	fef059e3          	blez	a5,80003a52 <iget+0x38>
    80003a64:	4098                	lw	a4,0(s1)
    80003a66:	ff3716e3          	bne	a4,s3,80003a52 <iget+0x38>
    80003a6a:	40d8                	lw	a4,4(s1)
    80003a6c:	ff4713e3          	bne	a4,s4,80003a52 <iget+0x38>
      ip->ref++;
    80003a70:	2785                	addiw	a5,a5,1
    80003a72:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a74:	0001c517          	auipc	a0,0x1c
    80003a78:	69c50513          	addi	a0,a0,1692 # 80020110 <itable>
    80003a7c:	ffffd097          	auipc	ra,0xffffd
    80003a80:	22e080e7          	jalr	558(ra) # 80000caa <release>
      return ip;
    80003a84:	8926                	mv	s2,s1
    80003a86:	a03d                	j	80003ab4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a88:	f7f9                	bnez	a5,80003a56 <iget+0x3c>
    80003a8a:	8926                	mv	s2,s1
    80003a8c:	b7e9                	j	80003a56 <iget+0x3c>
  if(empty == 0)
    80003a8e:	02090c63          	beqz	s2,80003ac6 <iget+0xac>
  ip->dev = dev;
    80003a92:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a96:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a9a:	4785                	li	a5,1
    80003a9c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003aa0:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003aa4:	0001c517          	auipc	a0,0x1c
    80003aa8:	66c50513          	addi	a0,a0,1644 # 80020110 <itable>
    80003aac:	ffffd097          	auipc	ra,0xffffd
    80003ab0:	1fe080e7          	jalr	510(ra) # 80000caa <release>
}
    80003ab4:	854a                	mv	a0,s2
    80003ab6:	70a2                	ld	ra,40(sp)
    80003ab8:	7402                	ld	s0,32(sp)
    80003aba:	64e2                	ld	s1,24(sp)
    80003abc:	6942                	ld	s2,16(sp)
    80003abe:	69a2                	ld	s3,8(sp)
    80003ac0:	6a02                	ld	s4,0(sp)
    80003ac2:	6145                	addi	sp,sp,48
    80003ac4:	8082                	ret
    panic("iget: no inodes");
    80003ac6:	00005517          	auipc	a0,0x5
    80003aca:	b0a50513          	addi	a0,a0,-1270 # 800085d0 <syscalls+0x140>
    80003ace:	ffffd097          	auipc	ra,0xffffd
    80003ad2:	a70080e7          	jalr	-1424(ra) # 8000053e <panic>

0000000080003ad6 <fsinit>:
fsinit(int dev) {
    80003ad6:	7179                	addi	sp,sp,-48
    80003ad8:	f406                	sd	ra,40(sp)
    80003ada:	f022                	sd	s0,32(sp)
    80003adc:	ec26                	sd	s1,24(sp)
    80003ade:	e84a                	sd	s2,16(sp)
    80003ae0:	e44e                	sd	s3,8(sp)
    80003ae2:	1800                	addi	s0,sp,48
    80003ae4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003ae6:	4585                	li	a1,1
    80003ae8:	00000097          	auipc	ra,0x0
    80003aec:	a64080e7          	jalr	-1436(ra) # 8000354c <bread>
    80003af0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003af2:	0001c997          	auipc	s3,0x1c
    80003af6:	5fe98993          	addi	s3,s3,1534 # 800200f0 <sb>
    80003afa:	02000613          	li	a2,32
    80003afe:	05850593          	addi	a1,a0,88
    80003b02:	854e                	mv	a0,s3
    80003b04:	ffffd097          	auipc	ra,0xffffd
    80003b08:	260080e7          	jalr	608(ra) # 80000d64 <memmove>
  brelse(bp);
    80003b0c:	8526                	mv	a0,s1
    80003b0e:	00000097          	auipc	ra,0x0
    80003b12:	b6e080e7          	jalr	-1170(ra) # 8000367c <brelse>
  if(sb.magic != FSMAGIC)
    80003b16:	0009a703          	lw	a4,0(s3)
    80003b1a:	102037b7          	lui	a5,0x10203
    80003b1e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b22:	02f71263          	bne	a4,a5,80003b46 <fsinit+0x70>
  initlog(dev, &sb);
    80003b26:	0001c597          	auipc	a1,0x1c
    80003b2a:	5ca58593          	addi	a1,a1,1482 # 800200f0 <sb>
    80003b2e:	854a                	mv	a0,s2
    80003b30:	00001097          	auipc	ra,0x1
    80003b34:	b4c080e7          	jalr	-1204(ra) # 8000467c <initlog>
}
    80003b38:	70a2                	ld	ra,40(sp)
    80003b3a:	7402                	ld	s0,32(sp)
    80003b3c:	64e2                	ld	s1,24(sp)
    80003b3e:	6942                	ld	s2,16(sp)
    80003b40:	69a2                	ld	s3,8(sp)
    80003b42:	6145                	addi	sp,sp,48
    80003b44:	8082                	ret
    panic("invalid file system");
    80003b46:	00005517          	auipc	a0,0x5
    80003b4a:	a9a50513          	addi	a0,a0,-1382 # 800085e0 <syscalls+0x150>
    80003b4e:	ffffd097          	auipc	ra,0xffffd
    80003b52:	9f0080e7          	jalr	-1552(ra) # 8000053e <panic>

0000000080003b56 <iinit>:
{
    80003b56:	7179                	addi	sp,sp,-48
    80003b58:	f406                	sd	ra,40(sp)
    80003b5a:	f022                	sd	s0,32(sp)
    80003b5c:	ec26                	sd	s1,24(sp)
    80003b5e:	e84a                	sd	s2,16(sp)
    80003b60:	e44e                	sd	s3,8(sp)
    80003b62:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b64:	00005597          	auipc	a1,0x5
    80003b68:	a9458593          	addi	a1,a1,-1388 # 800085f8 <syscalls+0x168>
    80003b6c:	0001c517          	auipc	a0,0x1c
    80003b70:	5a450513          	addi	a0,a0,1444 # 80020110 <itable>
    80003b74:	ffffd097          	auipc	ra,0xffffd
    80003b78:	fe0080e7          	jalr	-32(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b7c:	0001c497          	auipc	s1,0x1c
    80003b80:	5bc48493          	addi	s1,s1,1468 # 80020138 <itable+0x28>
    80003b84:	0001e997          	auipc	s3,0x1e
    80003b88:	04498993          	addi	s3,s3,68 # 80021bc8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b8c:	00005917          	auipc	s2,0x5
    80003b90:	a7490913          	addi	s2,s2,-1420 # 80008600 <syscalls+0x170>
    80003b94:	85ca                	mv	a1,s2
    80003b96:	8526                	mv	a0,s1
    80003b98:	00001097          	auipc	ra,0x1
    80003b9c:	e46080e7          	jalr	-442(ra) # 800049de <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003ba0:	08848493          	addi	s1,s1,136
    80003ba4:	ff3498e3          	bne	s1,s3,80003b94 <iinit+0x3e>
}
    80003ba8:	70a2                	ld	ra,40(sp)
    80003baa:	7402                	ld	s0,32(sp)
    80003bac:	64e2                	ld	s1,24(sp)
    80003bae:	6942                	ld	s2,16(sp)
    80003bb0:	69a2                	ld	s3,8(sp)
    80003bb2:	6145                	addi	sp,sp,48
    80003bb4:	8082                	ret

0000000080003bb6 <ialloc>:
{
    80003bb6:	715d                	addi	sp,sp,-80
    80003bb8:	e486                	sd	ra,72(sp)
    80003bba:	e0a2                	sd	s0,64(sp)
    80003bbc:	fc26                	sd	s1,56(sp)
    80003bbe:	f84a                	sd	s2,48(sp)
    80003bc0:	f44e                	sd	s3,40(sp)
    80003bc2:	f052                	sd	s4,32(sp)
    80003bc4:	ec56                	sd	s5,24(sp)
    80003bc6:	e85a                	sd	s6,16(sp)
    80003bc8:	e45e                	sd	s7,8(sp)
    80003bca:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bcc:	0001c717          	auipc	a4,0x1c
    80003bd0:	53072703          	lw	a4,1328(a4) # 800200fc <sb+0xc>
    80003bd4:	4785                	li	a5,1
    80003bd6:	04e7fa63          	bgeu	a5,a4,80003c2a <ialloc+0x74>
    80003bda:	8aaa                	mv	s5,a0
    80003bdc:	8bae                	mv	s7,a1
    80003bde:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003be0:	0001ca17          	auipc	s4,0x1c
    80003be4:	510a0a13          	addi	s4,s4,1296 # 800200f0 <sb>
    80003be8:	00048b1b          	sext.w	s6,s1
    80003bec:	0044d593          	srli	a1,s1,0x4
    80003bf0:	018a2783          	lw	a5,24(s4)
    80003bf4:	9dbd                	addw	a1,a1,a5
    80003bf6:	8556                	mv	a0,s5
    80003bf8:	00000097          	auipc	ra,0x0
    80003bfc:	954080e7          	jalr	-1708(ra) # 8000354c <bread>
    80003c00:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c02:	05850993          	addi	s3,a0,88
    80003c06:	00f4f793          	andi	a5,s1,15
    80003c0a:	079a                	slli	a5,a5,0x6
    80003c0c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c0e:	00099783          	lh	a5,0(s3)
    80003c12:	c785                	beqz	a5,80003c3a <ialloc+0x84>
    brelse(bp);
    80003c14:	00000097          	auipc	ra,0x0
    80003c18:	a68080e7          	jalr	-1432(ra) # 8000367c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c1c:	0485                	addi	s1,s1,1
    80003c1e:	00ca2703          	lw	a4,12(s4)
    80003c22:	0004879b          	sext.w	a5,s1
    80003c26:	fce7e1e3          	bltu	a5,a4,80003be8 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003c2a:	00005517          	auipc	a0,0x5
    80003c2e:	9de50513          	addi	a0,a0,-1570 # 80008608 <syscalls+0x178>
    80003c32:	ffffd097          	auipc	ra,0xffffd
    80003c36:	90c080e7          	jalr	-1780(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003c3a:	04000613          	li	a2,64
    80003c3e:	4581                	li	a1,0
    80003c40:	854e                	mv	a0,s3
    80003c42:	ffffd097          	auipc	ra,0xffffd
    80003c46:	0c2080e7          	jalr	194(ra) # 80000d04 <memset>
      dip->type = type;
    80003c4a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c4e:	854a                	mv	a0,s2
    80003c50:	00001097          	auipc	ra,0x1
    80003c54:	ca8080e7          	jalr	-856(ra) # 800048f8 <log_write>
      brelse(bp);
    80003c58:	854a                	mv	a0,s2
    80003c5a:	00000097          	auipc	ra,0x0
    80003c5e:	a22080e7          	jalr	-1502(ra) # 8000367c <brelse>
      return iget(dev, inum);
    80003c62:	85da                	mv	a1,s6
    80003c64:	8556                	mv	a0,s5
    80003c66:	00000097          	auipc	ra,0x0
    80003c6a:	db4080e7          	jalr	-588(ra) # 80003a1a <iget>
}
    80003c6e:	60a6                	ld	ra,72(sp)
    80003c70:	6406                	ld	s0,64(sp)
    80003c72:	74e2                	ld	s1,56(sp)
    80003c74:	7942                	ld	s2,48(sp)
    80003c76:	79a2                	ld	s3,40(sp)
    80003c78:	7a02                	ld	s4,32(sp)
    80003c7a:	6ae2                	ld	s5,24(sp)
    80003c7c:	6b42                	ld	s6,16(sp)
    80003c7e:	6ba2                	ld	s7,8(sp)
    80003c80:	6161                	addi	sp,sp,80
    80003c82:	8082                	ret

0000000080003c84 <iupdate>:
{
    80003c84:	1101                	addi	sp,sp,-32
    80003c86:	ec06                	sd	ra,24(sp)
    80003c88:	e822                	sd	s0,16(sp)
    80003c8a:	e426                	sd	s1,8(sp)
    80003c8c:	e04a                	sd	s2,0(sp)
    80003c8e:	1000                	addi	s0,sp,32
    80003c90:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c92:	415c                	lw	a5,4(a0)
    80003c94:	0047d79b          	srliw	a5,a5,0x4
    80003c98:	0001c597          	auipc	a1,0x1c
    80003c9c:	4705a583          	lw	a1,1136(a1) # 80020108 <sb+0x18>
    80003ca0:	9dbd                	addw	a1,a1,a5
    80003ca2:	4108                	lw	a0,0(a0)
    80003ca4:	00000097          	auipc	ra,0x0
    80003ca8:	8a8080e7          	jalr	-1880(ra) # 8000354c <bread>
    80003cac:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cae:	05850793          	addi	a5,a0,88
    80003cb2:	40c8                	lw	a0,4(s1)
    80003cb4:	893d                	andi	a0,a0,15
    80003cb6:	051a                	slli	a0,a0,0x6
    80003cb8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003cba:	04449703          	lh	a4,68(s1)
    80003cbe:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003cc2:	04649703          	lh	a4,70(s1)
    80003cc6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003cca:	04849703          	lh	a4,72(s1)
    80003cce:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003cd2:	04a49703          	lh	a4,74(s1)
    80003cd6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003cda:	44f8                	lw	a4,76(s1)
    80003cdc:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003cde:	03400613          	li	a2,52
    80003ce2:	05048593          	addi	a1,s1,80
    80003ce6:	0531                	addi	a0,a0,12
    80003ce8:	ffffd097          	auipc	ra,0xffffd
    80003cec:	07c080e7          	jalr	124(ra) # 80000d64 <memmove>
  log_write(bp);
    80003cf0:	854a                	mv	a0,s2
    80003cf2:	00001097          	auipc	ra,0x1
    80003cf6:	c06080e7          	jalr	-1018(ra) # 800048f8 <log_write>
  brelse(bp);
    80003cfa:	854a                	mv	a0,s2
    80003cfc:	00000097          	auipc	ra,0x0
    80003d00:	980080e7          	jalr	-1664(ra) # 8000367c <brelse>
}
    80003d04:	60e2                	ld	ra,24(sp)
    80003d06:	6442                	ld	s0,16(sp)
    80003d08:	64a2                	ld	s1,8(sp)
    80003d0a:	6902                	ld	s2,0(sp)
    80003d0c:	6105                	addi	sp,sp,32
    80003d0e:	8082                	ret

0000000080003d10 <idup>:
{
    80003d10:	1101                	addi	sp,sp,-32
    80003d12:	ec06                	sd	ra,24(sp)
    80003d14:	e822                	sd	s0,16(sp)
    80003d16:	e426                	sd	s1,8(sp)
    80003d18:	1000                	addi	s0,sp,32
    80003d1a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d1c:	0001c517          	auipc	a0,0x1c
    80003d20:	3f450513          	addi	a0,a0,1012 # 80020110 <itable>
    80003d24:	ffffd097          	auipc	ra,0xffffd
    80003d28:	ec0080e7          	jalr	-320(ra) # 80000be4 <acquire>
  ip->ref++;
    80003d2c:	449c                	lw	a5,8(s1)
    80003d2e:	2785                	addiw	a5,a5,1
    80003d30:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d32:	0001c517          	auipc	a0,0x1c
    80003d36:	3de50513          	addi	a0,a0,990 # 80020110 <itable>
    80003d3a:	ffffd097          	auipc	ra,0xffffd
    80003d3e:	f70080e7          	jalr	-144(ra) # 80000caa <release>
}
    80003d42:	8526                	mv	a0,s1
    80003d44:	60e2                	ld	ra,24(sp)
    80003d46:	6442                	ld	s0,16(sp)
    80003d48:	64a2                	ld	s1,8(sp)
    80003d4a:	6105                	addi	sp,sp,32
    80003d4c:	8082                	ret

0000000080003d4e <ilock>:
{
    80003d4e:	1101                	addi	sp,sp,-32
    80003d50:	ec06                	sd	ra,24(sp)
    80003d52:	e822                	sd	s0,16(sp)
    80003d54:	e426                	sd	s1,8(sp)
    80003d56:	e04a                	sd	s2,0(sp)
    80003d58:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d5a:	c115                	beqz	a0,80003d7e <ilock+0x30>
    80003d5c:	84aa                	mv	s1,a0
    80003d5e:	451c                	lw	a5,8(a0)
    80003d60:	00f05f63          	blez	a5,80003d7e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d64:	0541                	addi	a0,a0,16
    80003d66:	00001097          	auipc	ra,0x1
    80003d6a:	cb2080e7          	jalr	-846(ra) # 80004a18 <acquiresleep>
  if(ip->valid == 0){
    80003d6e:	40bc                	lw	a5,64(s1)
    80003d70:	cf99                	beqz	a5,80003d8e <ilock+0x40>
}
    80003d72:	60e2                	ld	ra,24(sp)
    80003d74:	6442                	ld	s0,16(sp)
    80003d76:	64a2                	ld	s1,8(sp)
    80003d78:	6902                	ld	s2,0(sp)
    80003d7a:	6105                	addi	sp,sp,32
    80003d7c:	8082                	ret
    panic("ilock");
    80003d7e:	00005517          	auipc	a0,0x5
    80003d82:	8a250513          	addi	a0,a0,-1886 # 80008620 <syscalls+0x190>
    80003d86:	ffffc097          	auipc	ra,0xffffc
    80003d8a:	7b8080e7          	jalr	1976(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d8e:	40dc                	lw	a5,4(s1)
    80003d90:	0047d79b          	srliw	a5,a5,0x4
    80003d94:	0001c597          	auipc	a1,0x1c
    80003d98:	3745a583          	lw	a1,884(a1) # 80020108 <sb+0x18>
    80003d9c:	9dbd                	addw	a1,a1,a5
    80003d9e:	4088                	lw	a0,0(s1)
    80003da0:	fffff097          	auipc	ra,0xfffff
    80003da4:	7ac080e7          	jalr	1964(ra) # 8000354c <bread>
    80003da8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003daa:	05850593          	addi	a1,a0,88
    80003dae:	40dc                	lw	a5,4(s1)
    80003db0:	8bbd                	andi	a5,a5,15
    80003db2:	079a                	slli	a5,a5,0x6
    80003db4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003db6:	00059783          	lh	a5,0(a1)
    80003dba:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003dbe:	00259783          	lh	a5,2(a1)
    80003dc2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003dc6:	00459783          	lh	a5,4(a1)
    80003dca:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003dce:	00659783          	lh	a5,6(a1)
    80003dd2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003dd6:	459c                	lw	a5,8(a1)
    80003dd8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003dda:	03400613          	li	a2,52
    80003dde:	05b1                	addi	a1,a1,12
    80003de0:	05048513          	addi	a0,s1,80
    80003de4:	ffffd097          	auipc	ra,0xffffd
    80003de8:	f80080e7          	jalr	-128(ra) # 80000d64 <memmove>
    brelse(bp);
    80003dec:	854a                	mv	a0,s2
    80003dee:	00000097          	auipc	ra,0x0
    80003df2:	88e080e7          	jalr	-1906(ra) # 8000367c <brelse>
    ip->valid = 1;
    80003df6:	4785                	li	a5,1
    80003df8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003dfa:	04449783          	lh	a5,68(s1)
    80003dfe:	fbb5                	bnez	a5,80003d72 <ilock+0x24>
      panic("ilock: no type");
    80003e00:	00005517          	auipc	a0,0x5
    80003e04:	82850513          	addi	a0,a0,-2008 # 80008628 <syscalls+0x198>
    80003e08:	ffffc097          	auipc	ra,0xffffc
    80003e0c:	736080e7          	jalr	1846(ra) # 8000053e <panic>

0000000080003e10 <iunlock>:
{
    80003e10:	1101                	addi	sp,sp,-32
    80003e12:	ec06                	sd	ra,24(sp)
    80003e14:	e822                	sd	s0,16(sp)
    80003e16:	e426                	sd	s1,8(sp)
    80003e18:	e04a                	sd	s2,0(sp)
    80003e1a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003e1c:	c905                	beqz	a0,80003e4c <iunlock+0x3c>
    80003e1e:	84aa                	mv	s1,a0
    80003e20:	01050913          	addi	s2,a0,16
    80003e24:	854a                	mv	a0,s2
    80003e26:	00001097          	auipc	ra,0x1
    80003e2a:	c8c080e7          	jalr	-884(ra) # 80004ab2 <holdingsleep>
    80003e2e:	cd19                	beqz	a0,80003e4c <iunlock+0x3c>
    80003e30:	449c                	lw	a5,8(s1)
    80003e32:	00f05d63          	blez	a5,80003e4c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e36:	854a                	mv	a0,s2
    80003e38:	00001097          	auipc	ra,0x1
    80003e3c:	c36080e7          	jalr	-970(ra) # 80004a6e <releasesleep>
}
    80003e40:	60e2                	ld	ra,24(sp)
    80003e42:	6442                	ld	s0,16(sp)
    80003e44:	64a2                	ld	s1,8(sp)
    80003e46:	6902                	ld	s2,0(sp)
    80003e48:	6105                	addi	sp,sp,32
    80003e4a:	8082                	ret
    panic("iunlock");
    80003e4c:	00004517          	auipc	a0,0x4
    80003e50:	7ec50513          	addi	a0,a0,2028 # 80008638 <syscalls+0x1a8>
    80003e54:	ffffc097          	auipc	ra,0xffffc
    80003e58:	6ea080e7          	jalr	1770(ra) # 8000053e <panic>

0000000080003e5c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e5c:	7179                	addi	sp,sp,-48
    80003e5e:	f406                	sd	ra,40(sp)
    80003e60:	f022                	sd	s0,32(sp)
    80003e62:	ec26                	sd	s1,24(sp)
    80003e64:	e84a                	sd	s2,16(sp)
    80003e66:	e44e                	sd	s3,8(sp)
    80003e68:	e052                	sd	s4,0(sp)
    80003e6a:	1800                	addi	s0,sp,48
    80003e6c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e6e:	05050493          	addi	s1,a0,80
    80003e72:	08050913          	addi	s2,a0,128
    80003e76:	a021                	j	80003e7e <itrunc+0x22>
    80003e78:	0491                	addi	s1,s1,4
    80003e7a:	01248d63          	beq	s1,s2,80003e94 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e7e:	408c                	lw	a1,0(s1)
    80003e80:	dde5                	beqz	a1,80003e78 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e82:	0009a503          	lw	a0,0(s3)
    80003e86:	00000097          	auipc	ra,0x0
    80003e8a:	90c080e7          	jalr	-1780(ra) # 80003792 <bfree>
      ip->addrs[i] = 0;
    80003e8e:	0004a023          	sw	zero,0(s1)
    80003e92:	b7dd                	j	80003e78 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e94:	0809a583          	lw	a1,128(s3)
    80003e98:	e185                	bnez	a1,80003eb8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e9a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e9e:	854e                	mv	a0,s3
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	de4080e7          	jalr	-540(ra) # 80003c84 <iupdate>
}
    80003ea8:	70a2                	ld	ra,40(sp)
    80003eaa:	7402                	ld	s0,32(sp)
    80003eac:	64e2                	ld	s1,24(sp)
    80003eae:	6942                	ld	s2,16(sp)
    80003eb0:	69a2                	ld	s3,8(sp)
    80003eb2:	6a02                	ld	s4,0(sp)
    80003eb4:	6145                	addi	sp,sp,48
    80003eb6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003eb8:	0009a503          	lw	a0,0(s3)
    80003ebc:	fffff097          	auipc	ra,0xfffff
    80003ec0:	690080e7          	jalr	1680(ra) # 8000354c <bread>
    80003ec4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ec6:	05850493          	addi	s1,a0,88
    80003eca:	45850913          	addi	s2,a0,1112
    80003ece:	a811                	j	80003ee2 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003ed0:	0009a503          	lw	a0,0(s3)
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	8be080e7          	jalr	-1858(ra) # 80003792 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003edc:	0491                	addi	s1,s1,4
    80003ede:	01248563          	beq	s1,s2,80003ee8 <itrunc+0x8c>
      if(a[j])
    80003ee2:	408c                	lw	a1,0(s1)
    80003ee4:	dde5                	beqz	a1,80003edc <itrunc+0x80>
    80003ee6:	b7ed                	j	80003ed0 <itrunc+0x74>
    brelse(bp);
    80003ee8:	8552                	mv	a0,s4
    80003eea:	fffff097          	auipc	ra,0xfffff
    80003eee:	792080e7          	jalr	1938(ra) # 8000367c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ef2:	0809a583          	lw	a1,128(s3)
    80003ef6:	0009a503          	lw	a0,0(s3)
    80003efa:	00000097          	auipc	ra,0x0
    80003efe:	898080e7          	jalr	-1896(ra) # 80003792 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f02:	0809a023          	sw	zero,128(s3)
    80003f06:	bf51                	j	80003e9a <itrunc+0x3e>

0000000080003f08 <iput>:
{
    80003f08:	1101                	addi	sp,sp,-32
    80003f0a:	ec06                	sd	ra,24(sp)
    80003f0c:	e822                	sd	s0,16(sp)
    80003f0e:	e426                	sd	s1,8(sp)
    80003f10:	e04a                	sd	s2,0(sp)
    80003f12:	1000                	addi	s0,sp,32
    80003f14:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f16:	0001c517          	auipc	a0,0x1c
    80003f1a:	1fa50513          	addi	a0,a0,506 # 80020110 <itable>
    80003f1e:	ffffd097          	auipc	ra,0xffffd
    80003f22:	cc6080e7          	jalr	-826(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f26:	4498                	lw	a4,8(s1)
    80003f28:	4785                	li	a5,1
    80003f2a:	02f70363          	beq	a4,a5,80003f50 <iput+0x48>
  ip->ref--;
    80003f2e:	449c                	lw	a5,8(s1)
    80003f30:	37fd                	addiw	a5,a5,-1
    80003f32:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f34:	0001c517          	auipc	a0,0x1c
    80003f38:	1dc50513          	addi	a0,a0,476 # 80020110 <itable>
    80003f3c:	ffffd097          	auipc	ra,0xffffd
    80003f40:	d6e080e7          	jalr	-658(ra) # 80000caa <release>
}
    80003f44:	60e2                	ld	ra,24(sp)
    80003f46:	6442                	ld	s0,16(sp)
    80003f48:	64a2                	ld	s1,8(sp)
    80003f4a:	6902                	ld	s2,0(sp)
    80003f4c:	6105                	addi	sp,sp,32
    80003f4e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f50:	40bc                	lw	a5,64(s1)
    80003f52:	dff1                	beqz	a5,80003f2e <iput+0x26>
    80003f54:	04a49783          	lh	a5,74(s1)
    80003f58:	fbf9                	bnez	a5,80003f2e <iput+0x26>
    acquiresleep(&ip->lock);
    80003f5a:	01048913          	addi	s2,s1,16
    80003f5e:	854a                	mv	a0,s2
    80003f60:	00001097          	auipc	ra,0x1
    80003f64:	ab8080e7          	jalr	-1352(ra) # 80004a18 <acquiresleep>
    release(&itable.lock);
    80003f68:	0001c517          	auipc	a0,0x1c
    80003f6c:	1a850513          	addi	a0,a0,424 # 80020110 <itable>
    80003f70:	ffffd097          	auipc	ra,0xffffd
    80003f74:	d3a080e7          	jalr	-710(ra) # 80000caa <release>
    itrunc(ip);
    80003f78:	8526                	mv	a0,s1
    80003f7a:	00000097          	auipc	ra,0x0
    80003f7e:	ee2080e7          	jalr	-286(ra) # 80003e5c <itrunc>
    ip->type = 0;
    80003f82:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f86:	8526                	mv	a0,s1
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	cfc080e7          	jalr	-772(ra) # 80003c84 <iupdate>
    ip->valid = 0;
    80003f90:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f94:	854a                	mv	a0,s2
    80003f96:	00001097          	auipc	ra,0x1
    80003f9a:	ad8080e7          	jalr	-1320(ra) # 80004a6e <releasesleep>
    acquire(&itable.lock);
    80003f9e:	0001c517          	auipc	a0,0x1c
    80003fa2:	17250513          	addi	a0,a0,370 # 80020110 <itable>
    80003fa6:	ffffd097          	auipc	ra,0xffffd
    80003faa:	c3e080e7          	jalr	-962(ra) # 80000be4 <acquire>
    80003fae:	b741                	j	80003f2e <iput+0x26>

0000000080003fb0 <iunlockput>:
{
    80003fb0:	1101                	addi	sp,sp,-32
    80003fb2:	ec06                	sd	ra,24(sp)
    80003fb4:	e822                	sd	s0,16(sp)
    80003fb6:	e426                	sd	s1,8(sp)
    80003fb8:	1000                	addi	s0,sp,32
    80003fba:	84aa                	mv	s1,a0
  iunlock(ip);
    80003fbc:	00000097          	auipc	ra,0x0
    80003fc0:	e54080e7          	jalr	-428(ra) # 80003e10 <iunlock>
  iput(ip);
    80003fc4:	8526                	mv	a0,s1
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	f42080e7          	jalr	-190(ra) # 80003f08 <iput>
}
    80003fce:	60e2                	ld	ra,24(sp)
    80003fd0:	6442                	ld	s0,16(sp)
    80003fd2:	64a2                	ld	s1,8(sp)
    80003fd4:	6105                	addi	sp,sp,32
    80003fd6:	8082                	ret

0000000080003fd8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003fd8:	1141                	addi	sp,sp,-16
    80003fda:	e422                	sd	s0,8(sp)
    80003fdc:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003fde:	411c                	lw	a5,0(a0)
    80003fe0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003fe2:	415c                	lw	a5,4(a0)
    80003fe4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003fe6:	04451783          	lh	a5,68(a0)
    80003fea:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003fee:	04a51783          	lh	a5,74(a0)
    80003ff2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ff6:	04c56783          	lwu	a5,76(a0)
    80003ffa:	e99c                	sd	a5,16(a1)
}
    80003ffc:	6422                	ld	s0,8(sp)
    80003ffe:	0141                	addi	sp,sp,16
    80004000:	8082                	ret

0000000080004002 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004002:	457c                	lw	a5,76(a0)
    80004004:	0ed7e963          	bltu	a5,a3,800040f6 <readi+0xf4>
{
    80004008:	7159                	addi	sp,sp,-112
    8000400a:	f486                	sd	ra,104(sp)
    8000400c:	f0a2                	sd	s0,96(sp)
    8000400e:	eca6                	sd	s1,88(sp)
    80004010:	e8ca                	sd	s2,80(sp)
    80004012:	e4ce                	sd	s3,72(sp)
    80004014:	e0d2                	sd	s4,64(sp)
    80004016:	fc56                	sd	s5,56(sp)
    80004018:	f85a                	sd	s6,48(sp)
    8000401a:	f45e                	sd	s7,40(sp)
    8000401c:	f062                	sd	s8,32(sp)
    8000401e:	ec66                	sd	s9,24(sp)
    80004020:	e86a                	sd	s10,16(sp)
    80004022:	e46e                	sd	s11,8(sp)
    80004024:	1880                	addi	s0,sp,112
    80004026:	8baa                	mv	s7,a0
    80004028:	8c2e                	mv	s8,a1
    8000402a:	8ab2                	mv	s5,a2
    8000402c:	84b6                	mv	s1,a3
    8000402e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004030:	9f35                	addw	a4,a4,a3
    return 0;
    80004032:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004034:	0ad76063          	bltu	a4,a3,800040d4 <readi+0xd2>
  if(off + n > ip->size)
    80004038:	00e7f463          	bgeu	a5,a4,80004040 <readi+0x3e>
    n = ip->size - off;
    8000403c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004040:	0a0b0963          	beqz	s6,800040f2 <readi+0xf0>
    80004044:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004046:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000404a:	5cfd                	li	s9,-1
    8000404c:	a82d                	j	80004086 <readi+0x84>
    8000404e:	020a1d93          	slli	s11,s4,0x20
    80004052:	020ddd93          	srli	s11,s11,0x20
    80004056:	05890613          	addi	a2,s2,88
    8000405a:	86ee                	mv	a3,s11
    8000405c:	963a                	add	a2,a2,a4
    8000405e:	85d6                	mv	a1,s5
    80004060:	8562                	mv	a0,s8
    80004062:	fffff097          	auipc	ra,0xfffff
    80004066:	a68080e7          	jalr	-1432(ra) # 80002aca <either_copyout>
    8000406a:	05950d63          	beq	a0,s9,800040c4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000406e:	854a                	mv	a0,s2
    80004070:	fffff097          	auipc	ra,0xfffff
    80004074:	60c080e7          	jalr	1548(ra) # 8000367c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004078:	013a09bb          	addw	s3,s4,s3
    8000407c:	009a04bb          	addw	s1,s4,s1
    80004080:	9aee                	add	s5,s5,s11
    80004082:	0569f763          	bgeu	s3,s6,800040d0 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004086:	000ba903          	lw	s2,0(s7)
    8000408a:	00a4d59b          	srliw	a1,s1,0xa
    8000408e:	855e                	mv	a0,s7
    80004090:	00000097          	auipc	ra,0x0
    80004094:	8b0080e7          	jalr	-1872(ra) # 80003940 <bmap>
    80004098:	0005059b          	sext.w	a1,a0
    8000409c:	854a                	mv	a0,s2
    8000409e:	fffff097          	auipc	ra,0xfffff
    800040a2:	4ae080e7          	jalr	1198(ra) # 8000354c <bread>
    800040a6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040a8:	3ff4f713          	andi	a4,s1,1023
    800040ac:	40ed07bb          	subw	a5,s10,a4
    800040b0:	413b06bb          	subw	a3,s6,s3
    800040b4:	8a3e                	mv	s4,a5
    800040b6:	2781                	sext.w	a5,a5
    800040b8:	0006861b          	sext.w	a2,a3
    800040bc:	f8f679e3          	bgeu	a2,a5,8000404e <readi+0x4c>
    800040c0:	8a36                	mv	s4,a3
    800040c2:	b771                	j	8000404e <readi+0x4c>
      brelse(bp);
    800040c4:	854a                	mv	a0,s2
    800040c6:	fffff097          	auipc	ra,0xfffff
    800040ca:	5b6080e7          	jalr	1462(ra) # 8000367c <brelse>
      tot = -1;
    800040ce:	59fd                	li	s3,-1
  }
  return tot;
    800040d0:	0009851b          	sext.w	a0,s3
}
    800040d4:	70a6                	ld	ra,104(sp)
    800040d6:	7406                	ld	s0,96(sp)
    800040d8:	64e6                	ld	s1,88(sp)
    800040da:	6946                	ld	s2,80(sp)
    800040dc:	69a6                	ld	s3,72(sp)
    800040de:	6a06                	ld	s4,64(sp)
    800040e0:	7ae2                	ld	s5,56(sp)
    800040e2:	7b42                	ld	s6,48(sp)
    800040e4:	7ba2                	ld	s7,40(sp)
    800040e6:	7c02                	ld	s8,32(sp)
    800040e8:	6ce2                	ld	s9,24(sp)
    800040ea:	6d42                	ld	s10,16(sp)
    800040ec:	6da2                	ld	s11,8(sp)
    800040ee:	6165                	addi	sp,sp,112
    800040f0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040f2:	89da                	mv	s3,s6
    800040f4:	bff1                	j	800040d0 <readi+0xce>
    return 0;
    800040f6:	4501                	li	a0,0
}
    800040f8:	8082                	ret

00000000800040fa <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040fa:	457c                	lw	a5,76(a0)
    800040fc:	10d7e863          	bltu	a5,a3,8000420c <writei+0x112>
{
    80004100:	7159                	addi	sp,sp,-112
    80004102:	f486                	sd	ra,104(sp)
    80004104:	f0a2                	sd	s0,96(sp)
    80004106:	eca6                	sd	s1,88(sp)
    80004108:	e8ca                	sd	s2,80(sp)
    8000410a:	e4ce                	sd	s3,72(sp)
    8000410c:	e0d2                	sd	s4,64(sp)
    8000410e:	fc56                	sd	s5,56(sp)
    80004110:	f85a                	sd	s6,48(sp)
    80004112:	f45e                	sd	s7,40(sp)
    80004114:	f062                	sd	s8,32(sp)
    80004116:	ec66                	sd	s9,24(sp)
    80004118:	e86a                	sd	s10,16(sp)
    8000411a:	e46e                	sd	s11,8(sp)
    8000411c:	1880                	addi	s0,sp,112
    8000411e:	8b2a                	mv	s6,a0
    80004120:	8c2e                	mv	s8,a1
    80004122:	8ab2                	mv	s5,a2
    80004124:	8936                	mv	s2,a3
    80004126:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004128:	00e687bb          	addw	a5,a3,a4
    8000412c:	0ed7e263          	bltu	a5,a3,80004210 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004130:	00043737          	lui	a4,0x43
    80004134:	0ef76063          	bltu	a4,a5,80004214 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004138:	0c0b8863          	beqz	s7,80004208 <writei+0x10e>
    8000413c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000413e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004142:	5cfd                	li	s9,-1
    80004144:	a091                	j	80004188 <writei+0x8e>
    80004146:	02099d93          	slli	s11,s3,0x20
    8000414a:	020ddd93          	srli	s11,s11,0x20
    8000414e:	05848513          	addi	a0,s1,88
    80004152:	86ee                	mv	a3,s11
    80004154:	8656                	mv	a2,s5
    80004156:	85e2                	mv	a1,s8
    80004158:	953a                	add	a0,a0,a4
    8000415a:	fffff097          	auipc	ra,0xfffff
    8000415e:	9c6080e7          	jalr	-1594(ra) # 80002b20 <either_copyin>
    80004162:	07950263          	beq	a0,s9,800041c6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004166:	8526                	mv	a0,s1
    80004168:	00000097          	auipc	ra,0x0
    8000416c:	790080e7          	jalr	1936(ra) # 800048f8 <log_write>
    brelse(bp);
    80004170:	8526                	mv	a0,s1
    80004172:	fffff097          	auipc	ra,0xfffff
    80004176:	50a080e7          	jalr	1290(ra) # 8000367c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000417a:	01498a3b          	addw	s4,s3,s4
    8000417e:	0129893b          	addw	s2,s3,s2
    80004182:	9aee                	add	s5,s5,s11
    80004184:	057a7663          	bgeu	s4,s7,800041d0 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004188:	000b2483          	lw	s1,0(s6)
    8000418c:	00a9559b          	srliw	a1,s2,0xa
    80004190:	855a                	mv	a0,s6
    80004192:	fffff097          	auipc	ra,0xfffff
    80004196:	7ae080e7          	jalr	1966(ra) # 80003940 <bmap>
    8000419a:	0005059b          	sext.w	a1,a0
    8000419e:	8526                	mv	a0,s1
    800041a0:	fffff097          	auipc	ra,0xfffff
    800041a4:	3ac080e7          	jalr	940(ra) # 8000354c <bread>
    800041a8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800041aa:	3ff97713          	andi	a4,s2,1023
    800041ae:	40ed07bb          	subw	a5,s10,a4
    800041b2:	414b86bb          	subw	a3,s7,s4
    800041b6:	89be                	mv	s3,a5
    800041b8:	2781                	sext.w	a5,a5
    800041ba:	0006861b          	sext.w	a2,a3
    800041be:	f8f674e3          	bgeu	a2,a5,80004146 <writei+0x4c>
    800041c2:	89b6                	mv	s3,a3
    800041c4:	b749                	j	80004146 <writei+0x4c>
      brelse(bp);
    800041c6:	8526                	mv	a0,s1
    800041c8:	fffff097          	auipc	ra,0xfffff
    800041cc:	4b4080e7          	jalr	1204(ra) # 8000367c <brelse>
  }

  if(off > ip->size)
    800041d0:	04cb2783          	lw	a5,76(s6)
    800041d4:	0127f463          	bgeu	a5,s2,800041dc <writei+0xe2>
    ip->size = off;
    800041d8:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800041dc:	855a                	mv	a0,s6
    800041de:	00000097          	auipc	ra,0x0
    800041e2:	aa6080e7          	jalr	-1370(ra) # 80003c84 <iupdate>

  return tot;
    800041e6:	000a051b          	sext.w	a0,s4
}
    800041ea:	70a6                	ld	ra,104(sp)
    800041ec:	7406                	ld	s0,96(sp)
    800041ee:	64e6                	ld	s1,88(sp)
    800041f0:	6946                	ld	s2,80(sp)
    800041f2:	69a6                	ld	s3,72(sp)
    800041f4:	6a06                	ld	s4,64(sp)
    800041f6:	7ae2                	ld	s5,56(sp)
    800041f8:	7b42                	ld	s6,48(sp)
    800041fa:	7ba2                	ld	s7,40(sp)
    800041fc:	7c02                	ld	s8,32(sp)
    800041fe:	6ce2                	ld	s9,24(sp)
    80004200:	6d42                	ld	s10,16(sp)
    80004202:	6da2                	ld	s11,8(sp)
    80004204:	6165                	addi	sp,sp,112
    80004206:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004208:	8a5e                	mv	s4,s7
    8000420a:	bfc9                	j	800041dc <writei+0xe2>
    return -1;
    8000420c:	557d                	li	a0,-1
}
    8000420e:	8082                	ret
    return -1;
    80004210:	557d                	li	a0,-1
    80004212:	bfe1                	j	800041ea <writei+0xf0>
    return -1;
    80004214:	557d                	li	a0,-1
    80004216:	bfd1                	j	800041ea <writei+0xf0>

0000000080004218 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004218:	1141                	addi	sp,sp,-16
    8000421a:	e406                	sd	ra,8(sp)
    8000421c:	e022                	sd	s0,0(sp)
    8000421e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004220:	4639                	li	a2,14
    80004222:	ffffd097          	auipc	ra,0xffffd
    80004226:	bba080e7          	jalr	-1094(ra) # 80000ddc <strncmp>
}
    8000422a:	60a2                	ld	ra,8(sp)
    8000422c:	6402                	ld	s0,0(sp)
    8000422e:	0141                	addi	sp,sp,16
    80004230:	8082                	ret

0000000080004232 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004232:	7139                	addi	sp,sp,-64
    80004234:	fc06                	sd	ra,56(sp)
    80004236:	f822                	sd	s0,48(sp)
    80004238:	f426                	sd	s1,40(sp)
    8000423a:	f04a                	sd	s2,32(sp)
    8000423c:	ec4e                	sd	s3,24(sp)
    8000423e:	e852                	sd	s4,16(sp)
    80004240:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004242:	04451703          	lh	a4,68(a0)
    80004246:	4785                	li	a5,1
    80004248:	00f71a63          	bne	a4,a5,8000425c <dirlookup+0x2a>
    8000424c:	892a                	mv	s2,a0
    8000424e:	89ae                	mv	s3,a1
    80004250:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004252:	457c                	lw	a5,76(a0)
    80004254:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004256:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004258:	e79d                	bnez	a5,80004286 <dirlookup+0x54>
    8000425a:	a8a5                	j	800042d2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000425c:	00004517          	auipc	a0,0x4
    80004260:	3e450513          	addi	a0,a0,996 # 80008640 <syscalls+0x1b0>
    80004264:	ffffc097          	auipc	ra,0xffffc
    80004268:	2da080e7          	jalr	730(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000426c:	00004517          	auipc	a0,0x4
    80004270:	3ec50513          	addi	a0,a0,1004 # 80008658 <syscalls+0x1c8>
    80004274:	ffffc097          	auipc	ra,0xffffc
    80004278:	2ca080e7          	jalr	714(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000427c:	24c1                	addiw	s1,s1,16
    8000427e:	04c92783          	lw	a5,76(s2)
    80004282:	04f4f763          	bgeu	s1,a5,800042d0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004286:	4741                	li	a4,16
    80004288:	86a6                	mv	a3,s1
    8000428a:	fc040613          	addi	a2,s0,-64
    8000428e:	4581                	li	a1,0
    80004290:	854a                	mv	a0,s2
    80004292:	00000097          	auipc	ra,0x0
    80004296:	d70080e7          	jalr	-656(ra) # 80004002 <readi>
    8000429a:	47c1                	li	a5,16
    8000429c:	fcf518e3          	bne	a0,a5,8000426c <dirlookup+0x3a>
    if(de.inum == 0)
    800042a0:	fc045783          	lhu	a5,-64(s0)
    800042a4:	dfe1                	beqz	a5,8000427c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800042a6:	fc240593          	addi	a1,s0,-62
    800042aa:	854e                	mv	a0,s3
    800042ac:	00000097          	auipc	ra,0x0
    800042b0:	f6c080e7          	jalr	-148(ra) # 80004218 <namecmp>
    800042b4:	f561                	bnez	a0,8000427c <dirlookup+0x4a>
      if(poff)
    800042b6:	000a0463          	beqz	s4,800042be <dirlookup+0x8c>
        *poff = off;
    800042ba:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800042be:	fc045583          	lhu	a1,-64(s0)
    800042c2:	00092503          	lw	a0,0(s2)
    800042c6:	fffff097          	auipc	ra,0xfffff
    800042ca:	754080e7          	jalr	1876(ra) # 80003a1a <iget>
    800042ce:	a011                	j	800042d2 <dirlookup+0xa0>
  return 0;
    800042d0:	4501                	li	a0,0
}
    800042d2:	70e2                	ld	ra,56(sp)
    800042d4:	7442                	ld	s0,48(sp)
    800042d6:	74a2                	ld	s1,40(sp)
    800042d8:	7902                	ld	s2,32(sp)
    800042da:	69e2                	ld	s3,24(sp)
    800042dc:	6a42                	ld	s4,16(sp)
    800042de:	6121                	addi	sp,sp,64
    800042e0:	8082                	ret

00000000800042e2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800042e2:	711d                	addi	sp,sp,-96
    800042e4:	ec86                	sd	ra,88(sp)
    800042e6:	e8a2                	sd	s0,80(sp)
    800042e8:	e4a6                	sd	s1,72(sp)
    800042ea:	e0ca                	sd	s2,64(sp)
    800042ec:	fc4e                	sd	s3,56(sp)
    800042ee:	f852                	sd	s4,48(sp)
    800042f0:	f456                	sd	s5,40(sp)
    800042f2:	f05a                	sd	s6,32(sp)
    800042f4:	ec5e                	sd	s7,24(sp)
    800042f6:	e862                	sd	s8,16(sp)
    800042f8:	e466                	sd	s9,8(sp)
    800042fa:	1080                	addi	s0,sp,96
    800042fc:	84aa                	mv	s1,a0
    800042fe:	8b2e                	mv	s6,a1
    80004300:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004302:	00054703          	lbu	a4,0(a0)
    80004306:	02f00793          	li	a5,47
    8000430a:	02f70363          	beq	a4,a5,80004330 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000430e:	ffffe097          	auipc	ra,0xffffe
    80004312:	b5a080e7          	jalr	-1190(ra) # 80001e68 <myproc>
    80004316:	17053503          	ld	a0,368(a0)
    8000431a:	00000097          	auipc	ra,0x0
    8000431e:	9f6080e7          	jalr	-1546(ra) # 80003d10 <idup>
    80004322:	89aa                	mv	s3,a0
  while(*path == '/')
    80004324:	02f00913          	li	s2,47
  len = path - s;
    80004328:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000432a:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000432c:	4c05                	li	s8,1
    8000432e:	a865                	j	800043e6 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004330:	4585                	li	a1,1
    80004332:	4505                	li	a0,1
    80004334:	fffff097          	auipc	ra,0xfffff
    80004338:	6e6080e7          	jalr	1766(ra) # 80003a1a <iget>
    8000433c:	89aa                	mv	s3,a0
    8000433e:	b7dd                	j	80004324 <namex+0x42>
      iunlockput(ip);
    80004340:	854e                	mv	a0,s3
    80004342:	00000097          	auipc	ra,0x0
    80004346:	c6e080e7          	jalr	-914(ra) # 80003fb0 <iunlockput>
      return 0;
    8000434a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000434c:	854e                	mv	a0,s3
    8000434e:	60e6                	ld	ra,88(sp)
    80004350:	6446                	ld	s0,80(sp)
    80004352:	64a6                	ld	s1,72(sp)
    80004354:	6906                	ld	s2,64(sp)
    80004356:	79e2                	ld	s3,56(sp)
    80004358:	7a42                	ld	s4,48(sp)
    8000435a:	7aa2                	ld	s5,40(sp)
    8000435c:	7b02                	ld	s6,32(sp)
    8000435e:	6be2                	ld	s7,24(sp)
    80004360:	6c42                	ld	s8,16(sp)
    80004362:	6ca2                	ld	s9,8(sp)
    80004364:	6125                	addi	sp,sp,96
    80004366:	8082                	ret
      iunlock(ip);
    80004368:	854e                	mv	a0,s3
    8000436a:	00000097          	auipc	ra,0x0
    8000436e:	aa6080e7          	jalr	-1370(ra) # 80003e10 <iunlock>
      return ip;
    80004372:	bfe9                	j	8000434c <namex+0x6a>
      iunlockput(ip);
    80004374:	854e                	mv	a0,s3
    80004376:	00000097          	auipc	ra,0x0
    8000437a:	c3a080e7          	jalr	-966(ra) # 80003fb0 <iunlockput>
      return 0;
    8000437e:	89d2                	mv	s3,s4
    80004380:	b7f1                	j	8000434c <namex+0x6a>
  len = path - s;
    80004382:	40b48633          	sub	a2,s1,a1
    80004386:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000438a:	094cd463          	bge	s9,s4,80004412 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000438e:	4639                	li	a2,14
    80004390:	8556                	mv	a0,s5
    80004392:	ffffd097          	auipc	ra,0xffffd
    80004396:	9d2080e7          	jalr	-1582(ra) # 80000d64 <memmove>
  while(*path == '/')
    8000439a:	0004c783          	lbu	a5,0(s1)
    8000439e:	01279763          	bne	a5,s2,800043ac <namex+0xca>
    path++;
    800043a2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043a4:	0004c783          	lbu	a5,0(s1)
    800043a8:	ff278de3          	beq	a5,s2,800043a2 <namex+0xc0>
    ilock(ip);
    800043ac:	854e                	mv	a0,s3
    800043ae:	00000097          	auipc	ra,0x0
    800043b2:	9a0080e7          	jalr	-1632(ra) # 80003d4e <ilock>
    if(ip->type != T_DIR){
    800043b6:	04499783          	lh	a5,68(s3)
    800043ba:	f98793e3          	bne	a5,s8,80004340 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800043be:	000b0563          	beqz	s6,800043c8 <namex+0xe6>
    800043c2:	0004c783          	lbu	a5,0(s1)
    800043c6:	d3cd                	beqz	a5,80004368 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800043c8:	865e                	mv	a2,s7
    800043ca:	85d6                	mv	a1,s5
    800043cc:	854e                	mv	a0,s3
    800043ce:	00000097          	auipc	ra,0x0
    800043d2:	e64080e7          	jalr	-412(ra) # 80004232 <dirlookup>
    800043d6:	8a2a                	mv	s4,a0
    800043d8:	dd51                	beqz	a0,80004374 <namex+0x92>
    iunlockput(ip);
    800043da:	854e                	mv	a0,s3
    800043dc:	00000097          	auipc	ra,0x0
    800043e0:	bd4080e7          	jalr	-1068(ra) # 80003fb0 <iunlockput>
    ip = next;
    800043e4:	89d2                	mv	s3,s4
  while(*path == '/')
    800043e6:	0004c783          	lbu	a5,0(s1)
    800043ea:	05279763          	bne	a5,s2,80004438 <namex+0x156>
    path++;
    800043ee:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043f0:	0004c783          	lbu	a5,0(s1)
    800043f4:	ff278de3          	beq	a5,s2,800043ee <namex+0x10c>
  if(*path == 0)
    800043f8:	c79d                	beqz	a5,80004426 <namex+0x144>
    path++;
    800043fa:	85a6                	mv	a1,s1
  len = path - s;
    800043fc:	8a5e                	mv	s4,s7
    800043fe:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004400:	01278963          	beq	a5,s2,80004412 <namex+0x130>
    80004404:	dfbd                	beqz	a5,80004382 <namex+0xa0>
    path++;
    80004406:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004408:	0004c783          	lbu	a5,0(s1)
    8000440c:	ff279ce3          	bne	a5,s2,80004404 <namex+0x122>
    80004410:	bf8d                	j	80004382 <namex+0xa0>
    memmove(name, s, len);
    80004412:	2601                	sext.w	a2,a2
    80004414:	8556                	mv	a0,s5
    80004416:	ffffd097          	auipc	ra,0xffffd
    8000441a:	94e080e7          	jalr	-1714(ra) # 80000d64 <memmove>
    name[len] = 0;
    8000441e:	9a56                	add	s4,s4,s5
    80004420:	000a0023          	sb	zero,0(s4)
    80004424:	bf9d                	j	8000439a <namex+0xb8>
  if(nameiparent){
    80004426:	f20b03e3          	beqz	s6,8000434c <namex+0x6a>
    iput(ip);
    8000442a:	854e                	mv	a0,s3
    8000442c:	00000097          	auipc	ra,0x0
    80004430:	adc080e7          	jalr	-1316(ra) # 80003f08 <iput>
    return 0;
    80004434:	4981                	li	s3,0
    80004436:	bf19                	j	8000434c <namex+0x6a>
  if(*path == 0)
    80004438:	d7fd                	beqz	a5,80004426 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000443a:	0004c783          	lbu	a5,0(s1)
    8000443e:	85a6                	mv	a1,s1
    80004440:	b7d1                	j	80004404 <namex+0x122>

0000000080004442 <dirlink>:
{
    80004442:	7139                	addi	sp,sp,-64
    80004444:	fc06                	sd	ra,56(sp)
    80004446:	f822                	sd	s0,48(sp)
    80004448:	f426                	sd	s1,40(sp)
    8000444a:	f04a                	sd	s2,32(sp)
    8000444c:	ec4e                	sd	s3,24(sp)
    8000444e:	e852                	sd	s4,16(sp)
    80004450:	0080                	addi	s0,sp,64
    80004452:	892a                	mv	s2,a0
    80004454:	8a2e                	mv	s4,a1
    80004456:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004458:	4601                	li	a2,0
    8000445a:	00000097          	auipc	ra,0x0
    8000445e:	dd8080e7          	jalr	-552(ra) # 80004232 <dirlookup>
    80004462:	e93d                	bnez	a0,800044d8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004464:	04c92483          	lw	s1,76(s2)
    80004468:	c49d                	beqz	s1,80004496 <dirlink+0x54>
    8000446a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000446c:	4741                	li	a4,16
    8000446e:	86a6                	mv	a3,s1
    80004470:	fc040613          	addi	a2,s0,-64
    80004474:	4581                	li	a1,0
    80004476:	854a                	mv	a0,s2
    80004478:	00000097          	auipc	ra,0x0
    8000447c:	b8a080e7          	jalr	-1142(ra) # 80004002 <readi>
    80004480:	47c1                	li	a5,16
    80004482:	06f51163          	bne	a0,a5,800044e4 <dirlink+0xa2>
    if(de.inum == 0)
    80004486:	fc045783          	lhu	a5,-64(s0)
    8000448a:	c791                	beqz	a5,80004496 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000448c:	24c1                	addiw	s1,s1,16
    8000448e:	04c92783          	lw	a5,76(s2)
    80004492:	fcf4ede3          	bltu	s1,a5,8000446c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004496:	4639                	li	a2,14
    80004498:	85d2                	mv	a1,s4
    8000449a:	fc240513          	addi	a0,s0,-62
    8000449e:	ffffd097          	auipc	ra,0xffffd
    800044a2:	97a080e7          	jalr	-1670(ra) # 80000e18 <strncpy>
  de.inum = inum;
    800044a6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044aa:	4741                	li	a4,16
    800044ac:	86a6                	mv	a3,s1
    800044ae:	fc040613          	addi	a2,s0,-64
    800044b2:	4581                	li	a1,0
    800044b4:	854a                	mv	a0,s2
    800044b6:	00000097          	auipc	ra,0x0
    800044ba:	c44080e7          	jalr	-956(ra) # 800040fa <writei>
    800044be:	872a                	mv	a4,a0
    800044c0:	47c1                	li	a5,16
  return 0;
    800044c2:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044c4:	02f71863          	bne	a4,a5,800044f4 <dirlink+0xb2>
}
    800044c8:	70e2                	ld	ra,56(sp)
    800044ca:	7442                	ld	s0,48(sp)
    800044cc:	74a2                	ld	s1,40(sp)
    800044ce:	7902                	ld	s2,32(sp)
    800044d0:	69e2                	ld	s3,24(sp)
    800044d2:	6a42                	ld	s4,16(sp)
    800044d4:	6121                	addi	sp,sp,64
    800044d6:	8082                	ret
    iput(ip);
    800044d8:	00000097          	auipc	ra,0x0
    800044dc:	a30080e7          	jalr	-1488(ra) # 80003f08 <iput>
    return -1;
    800044e0:	557d                	li	a0,-1
    800044e2:	b7dd                	j	800044c8 <dirlink+0x86>
      panic("dirlink read");
    800044e4:	00004517          	auipc	a0,0x4
    800044e8:	18450513          	addi	a0,a0,388 # 80008668 <syscalls+0x1d8>
    800044ec:	ffffc097          	auipc	ra,0xffffc
    800044f0:	052080e7          	jalr	82(ra) # 8000053e <panic>
    panic("dirlink");
    800044f4:	00004517          	auipc	a0,0x4
    800044f8:	28450513          	addi	a0,a0,644 # 80008778 <syscalls+0x2e8>
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	042080e7          	jalr	66(ra) # 8000053e <panic>

0000000080004504 <namei>:

struct inode*
namei(char *path)
{
    80004504:	1101                	addi	sp,sp,-32
    80004506:	ec06                	sd	ra,24(sp)
    80004508:	e822                	sd	s0,16(sp)
    8000450a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000450c:	fe040613          	addi	a2,s0,-32
    80004510:	4581                	li	a1,0
    80004512:	00000097          	auipc	ra,0x0
    80004516:	dd0080e7          	jalr	-560(ra) # 800042e2 <namex>
}
    8000451a:	60e2                	ld	ra,24(sp)
    8000451c:	6442                	ld	s0,16(sp)
    8000451e:	6105                	addi	sp,sp,32
    80004520:	8082                	ret

0000000080004522 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004522:	1141                	addi	sp,sp,-16
    80004524:	e406                	sd	ra,8(sp)
    80004526:	e022                	sd	s0,0(sp)
    80004528:	0800                	addi	s0,sp,16
    8000452a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000452c:	4585                	li	a1,1
    8000452e:	00000097          	auipc	ra,0x0
    80004532:	db4080e7          	jalr	-588(ra) # 800042e2 <namex>
}
    80004536:	60a2                	ld	ra,8(sp)
    80004538:	6402                	ld	s0,0(sp)
    8000453a:	0141                	addi	sp,sp,16
    8000453c:	8082                	ret

000000008000453e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000453e:	1101                	addi	sp,sp,-32
    80004540:	ec06                	sd	ra,24(sp)
    80004542:	e822                	sd	s0,16(sp)
    80004544:	e426                	sd	s1,8(sp)
    80004546:	e04a                	sd	s2,0(sp)
    80004548:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000454a:	0001d917          	auipc	s2,0x1d
    8000454e:	66e90913          	addi	s2,s2,1646 # 80021bb8 <log>
    80004552:	01892583          	lw	a1,24(s2)
    80004556:	02892503          	lw	a0,40(s2)
    8000455a:	fffff097          	auipc	ra,0xfffff
    8000455e:	ff2080e7          	jalr	-14(ra) # 8000354c <bread>
    80004562:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004564:	02c92683          	lw	a3,44(s2)
    80004568:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000456a:	02d05763          	blez	a3,80004598 <write_head+0x5a>
    8000456e:	0001d797          	auipc	a5,0x1d
    80004572:	67a78793          	addi	a5,a5,1658 # 80021be8 <log+0x30>
    80004576:	05c50713          	addi	a4,a0,92
    8000457a:	36fd                	addiw	a3,a3,-1
    8000457c:	1682                	slli	a3,a3,0x20
    8000457e:	9281                	srli	a3,a3,0x20
    80004580:	068a                	slli	a3,a3,0x2
    80004582:	0001d617          	auipc	a2,0x1d
    80004586:	66a60613          	addi	a2,a2,1642 # 80021bec <log+0x34>
    8000458a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000458c:	4390                	lw	a2,0(a5)
    8000458e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004590:	0791                	addi	a5,a5,4
    80004592:	0711                	addi	a4,a4,4
    80004594:	fed79ce3          	bne	a5,a3,8000458c <write_head+0x4e>
  }
  bwrite(buf);
    80004598:	8526                	mv	a0,s1
    8000459a:	fffff097          	auipc	ra,0xfffff
    8000459e:	0a4080e7          	jalr	164(ra) # 8000363e <bwrite>
  brelse(buf);
    800045a2:	8526                	mv	a0,s1
    800045a4:	fffff097          	auipc	ra,0xfffff
    800045a8:	0d8080e7          	jalr	216(ra) # 8000367c <brelse>
}
    800045ac:	60e2                	ld	ra,24(sp)
    800045ae:	6442                	ld	s0,16(sp)
    800045b0:	64a2                	ld	s1,8(sp)
    800045b2:	6902                	ld	s2,0(sp)
    800045b4:	6105                	addi	sp,sp,32
    800045b6:	8082                	ret

00000000800045b8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800045b8:	0001d797          	auipc	a5,0x1d
    800045bc:	62c7a783          	lw	a5,1580(a5) # 80021be4 <log+0x2c>
    800045c0:	0af05d63          	blez	a5,8000467a <install_trans+0xc2>
{
    800045c4:	7139                	addi	sp,sp,-64
    800045c6:	fc06                	sd	ra,56(sp)
    800045c8:	f822                	sd	s0,48(sp)
    800045ca:	f426                	sd	s1,40(sp)
    800045cc:	f04a                	sd	s2,32(sp)
    800045ce:	ec4e                	sd	s3,24(sp)
    800045d0:	e852                	sd	s4,16(sp)
    800045d2:	e456                	sd	s5,8(sp)
    800045d4:	e05a                	sd	s6,0(sp)
    800045d6:	0080                	addi	s0,sp,64
    800045d8:	8b2a                	mv	s6,a0
    800045da:	0001da97          	auipc	s5,0x1d
    800045de:	60ea8a93          	addi	s5,s5,1550 # 80021be8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045e2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045e4:	0001d997          	auipc	s3,0x1d
    800045e8:	5d498993          	addi	s3,s3,1492 # 80021bb8 <log>
    800045ec:	a035                	j	80004618 <install_trans+0x60>
      bunpin(dbuf);
    800045ee:	8526                	mv	a0,s1
    800045f0:	fffff097          	auipc	ra,0xfffff
    800045f4:	166080e7          	jalr	358(ra) # 80003756 <bunpin>
    brelse(lbuf);
    800045f8:	854a                	mv	a0,s2
    800045fa:	fffff097          	auipc	ra,0xfffff
    800045fe:	082080e7          	jalr	130(ra) # 8000367c <brelse>
    brelse(dbuf);
    80004602:	8526                	mv	a0,s1
    80004604:	fffff097          	auipc	ra,0xfffff
    80004608:	078080e7          	jalr	120(ra) # 8000367c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000460c:	2a05                	addiw	s4,s4,1
    8000460e:	0a91                	addi	s5,s5,4
    80004610:	02c9a783          	lw	a5,44(s3)
    80004614:	04fa5963          	bge	s4,a5,80004666 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004618:	0189a583          	lw	a1,24(s3)
    8000461c:	014585bb          	addw	a1,a1,s4
    80004620:	2585                	addiw	a1,a1,1
    80004622:	0289a503          	lw	a0,40(s3)
    80004626:	fffff097          	auipc	ra,0xfffff
    8000462a:	f26080e7          	jalr	-218(ra) # 8000354c <bread>
    8000462e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004630:	000aa583          	lw	a1,0(s5)
    80004634:	0289a503          	lw	a0,40(s3)
    80004638:	fffff097          	auipc	ra,0xfffff
    8000463c:	f14080e7          	jalr	-236(ra) # 8000354c <bread>
    80004640:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004642:	40000613          	li	a2,1024
    80004646:	05890593          	addi	a1,s2,88
    8000464a:	05850513          	addi	a0,a0,88
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	716080e7          	jalr	1814(ra) # 80000d64 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004656:	8526                	mv	a0,s1
    80004658:	fffff097          	auipc	ra,0xfffff
    8000465c:	fe6080e7          	jalr	-26(ra) # 8000363e <bwrite>
    if(recovering == 0)
    80004660:	f80b1ce3          	bnez	s6,800045f8 <install_trans+0x40>
    80004664:	b769                	j	800045ee <install_trans+0x36>
}
    80004666:	70e2                	ld	ra,56(sp)
    80004668:	7442                	ld	s0,48(sp)
    8000466a:	74a2                	ld	s1,40(sp)
    8000466c:	7902                	ld	s2,32(sp)
    8000466e:	69e2                	ld	s3,24(sp)
    80004670:	6a42                	ld	s4,16(sp)
    80004672:	6aa2                	ld	s5,8(sp)
    80004674:	6b02                	ld	s6,0(sp)
    80004676:	6121                	addi	sp,sp,64
    80004678:	8082                	ret
    8000467a:	8082                	ret

000000008000467c <initlog>:
{
    8000467c:	7179                	addi	sp,sp,-48
    8000467e:	f406                	sd	ra,40(sp)
    80004680:	f022                	sd	s0,32(sp)
    80004682:	ec26                	sd	s1,24(sp)
    80004684:	e84a                	sd	s2,16(sp)
    80004686:	e44e                	sd	s3,8(sp)
    80004688:	1800                	addi	s0,sp,48
    8000468a:	892a                	mv	s2,a0
    8000468c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000468e:	0001d497          	auipc	s1,0x1d
    80004692:	52a48493          	addi	s1,s1,1322 # 80021bb8 <log>
    80004696:	00004597          	auipc	a1,0x4
    8000469a:	fe258593          	addi	a1,a1,-30 # 80008678 <syscalls+0x1e8>
    8000469e:	8526                	mv	a0,s1
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	4b4080e7          	jalr	1204(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800046a8:	0149a583          	lw	a1,20(s3)
    800046ac:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800046ae:	0109a783          	lw	a5,16(s3)
    800046b2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800046b4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800046b8:	854a                	mv	a0,s2
    800046ba:	fffff097          	auipc	ra,0xfffff
    800046be:	e92080e7          	jalr	-366(ra) # 8000354c <bread>
  log.lh.n = lh->n;
    800046c2:	4d3c                	lw	a5,88(a0)
    800046c4:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800046c6:	02f05563          	blez	a5,800046f0 <initlog+0x74>
    800046ca:	05c50713          	addi	a4,a0,92
    800046ce:	0001d697          	auipc	a3,0x1d
    800046d2:	51a68693          	addi	a3,a3,1306 # 80021be8 <log+0x30>
    800046d6:	37fd                	addiw	a5,a5,-1
    800046d8:	1782                	slli	a5,a5,0x20
    800046da:	9381                	srli	a5,a5,0x20
    800046dc:	078a                	slli	a5,a5,0x2
    800046de:	06050613          	addi	a2,a0,96
    800046e2:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800046e4:	4310                	lw	a2,0(a4)
    800046e6:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800046e8:	0711                	addi	a4,a4,4
    800046ea:	0691                	addi	a3,a3,4
    800046ec:	fef71ce3          	bne	a4,a5,800046e4 <initlog+0x68>
  brelse(buf);
    800046f0:	fffff097          	auipc	ra,0xfffff
    800046f4:	f8c080e7          	jalr	-116(ra) # 8000367c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046f8:	4505                	li	a0,1
    800046fa:	00000097          	auipc	ra,0x0
    800046fe:	ebe080e7          	jalr	-322(ra) # 800045b8 <install_trans>
  log.lh.n = 0;
    80004702:	0001d797          	auipc	a5,0x1d
    80004706:	4e07a123          	sw	zero,1250(a5) # 80021be4 <log+0x2c>
  write_head(); // clear the log
    8000470a:	00000097          	auipc	ra,0x0
    8000470e:	e34080e7          	jalr	-460(ra) # 8000453e <write_head>
}
    80004712:	70a2                	ld	ra,40(sp)
    80004714:	7402                	ld	s0,32(sp)
    80004716:	64e2                	ld	s1,24(sp)
    80004718:	6942                	ld	s2,16(sp)
    8000471a:	69a2                	ld	s3,8(sp)
    8000471c:	6145                	addi	sp,sp,48
    8000471e:	8082                	ret

0000000080004720 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004720:	1101                	addi	sp,sp,-32
    80004722:	ec06                	sd	ra,24(sp)
    80004724:	e822                	sd	s0,16(sp)
    80004726:	e426                	sd	s1,8(sp)
    80004728:	e04a                	sd	s2,0(sp)
    8000472a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000472c:	0001d517          	auipc	a0,0x1d
    80004730:	48c50513          	addi	a0,a0,1164 # 80021bb8 <log>
    80004734:	ffffc097          	auipc	ra,0xffffc
    80004738:	4b0080e7          	jalr	1200(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000473c:	0001d497          	auipc	s1,0x1d
    80004740:	47c48493          	addi	s1,s1,1148 # 80021bb8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004744:	4979                	li	s2,30
    80004746:	a039                	j	80004754 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004748:	85a6                	mv	a1,s1
    8000474a:	8526                	mv	a0,s1
    8000474c:	ffffe097          	auipc	ra,0xffffe
    80004750:	f0a080e7          	jalr	-246(ra) # 80002656 <sleep>
    if(log.committing){
    80004754:	50dc                	lw	a5,36(s1)
    80004756:	fbed                	bnez	a5,80004748 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004758:	509c                	lw	a5,32(s1)
    8000475a:	0017871b          	addiw	a4,a5,1
    8000475e:	0007069b          	sext.w	a3,a4
    80004762:	0027179b          	slliw	a5,a4,0x2
    80004766:	9fb9                	addw	a5,a5,a4
    80004768:	0017979b          	slliw	a5,a5,0x1
    8000476c:	54d8                	lw	a4,44(s1)
    8000476e:	9fb9                	addw	a5,a5,a4
    80004770:	00f95963          	bge	s2,a5,80004782 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004774:	85a6                	mv	a1,s1
    80004776:	8526                	mv	a0,s1
    80004778:	ffffe097          	auipc	ra,0xffffe
    8000477c:	ede080e7          	jalr	-290(ra) # 80002656 <sleep>
    80004780:	bfd1                	j	80004754 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004782:	0001d517          	auipc	a0,0x1d
    80004786:	43650513          	addi	a0,a0,1078 # 80021bb8 <log>
    8000478a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000478c:	ffffc097          	auipc	ra,0xffffc
    80004790:	51e080e7          	jalr	1310(ra) # 80000caa <release>
      break;
    }
  }
}
    80004794:	60e2                	ld	ra,24(sp)
    80004796:	6442                	ld	s0,16(sp)
    80004798:	64a2                	ld	s1,8(sp)
    8000479a:	6902                	ld	s2,0(sp)
    8000479c:	6105                	addi	sp,sp,32
    8000479e:	8082                	ret

00000000800047a0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800047a0:	7139                	addi	sp,sp,-64
    800047a2:	fc06                	sd	ra,56(sp)
    800047a4:	f822                	sd	s0,48(sp)
    800047a6:	f426                	sd	s1,40(sp)
    800047a8:	f04a                	sd	s2,32(sp)
    800047aa:	ec4e                	sd	s3,24(sp)
    800047ac:	e852                	sd	s4,16(sp)
    800047ae:	e456                	sd	s5,8(sp)
    800047b0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800047b2:	0001d497          	auipc	s1,0x1d
    800047b6:	40648493          	addi	s1,s1,1030 # 80021bb8 <log>
    800047ba:	8526                	mv	a0,s1
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	428080e7          	jalr	1064(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800047c4:	509c                	lw	a5,32(s1)
    800047c6:	37fd                	addiw	a5,a5,-1
    800047c8:	0007891b          	sext.w	s2,a5
    800047cc:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800047ce:	50dc                	lw	a5,36(s1)
    800047d0:	efb9                	bnez	a5,8000482e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800047d2:	06091663          	bnez	s2,8000483e <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800047d6:	0001d497          	auipc	s1,0x1d
    800047da:	3e248493          	addi	s1,s1,994 # 80021bb8 <log>
    800047de:	4785                	li	a5,1
    800047e0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800047e2:	8526                	mv	a0,s1
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	4c6080e7          	jalr	1222(ra) # 80000caa <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047ec:	54dc                	lw	a5,44(s1)
    800047ee:	06f04763          	bgtz	a5,8000485c <end_op+0xbc>
    acquire(&log.lock);
    800047f2:	0001d497          	auipc	s1,0x1d
    800047f6:	3c648493          	addi	s1,s1,966 # 80021bb8 <log>
    800047fa:	8526                	mv	a0,s1
    800047fc:	ffffc097          	auipc	ra,0xffffc
    80004800:	3e8080e7          	jalr	1000(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004804:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004808:	8526                	mv	a0,s1
    8000480a:	ffffe097          	auipc	ra,0xffffe
    8000480e:	ff2080e7          	jalr	-14(ra) # 800027fc <wakeup>
    release(&log.lock);
    80004812:	8526                	mv	a0,s1
    80004814:	ffffc097          	auipc	ra,0xffffc
    80004818:	496080e7          	jalr	1174(ra) # 80000caa <release>
}
    8000481c:	70e2                	ld	ra,56(sp)
    8000481e:	7442                	ld	s0,48(sp)
    80004820:	74a2                	ld	s1,40(sp)
    80004822:	7902                	ld	s2,32(sp)
    80004824:	69e2                	ld	s3,24(sp)
    80004826:	6a42                	ld	s4,16(sp)
    80004828:	6aa2                	ld	s5,8(sp)
    8000482a:	6121                	addi	sp,sp,64
    8000482c:	8082                	ret
    panic("log.committing");
    8000482e:	00004517          	auipc	a0,0x4
    80004832:	e5250513          	addi	a0,a0,-430 # 80008680 <syscalls+0x1f0>
    80004836:	ffffc097          	auipc	ra,0xffffc
    8000483a:	d08080e7          	jalr	-760(ra) # 8000053e <panic>
    wakeup(&log);
    8000483e:	0001d497          	auipc	s1,0x1d
    80004842:	37a48493          	addi	s1,s1,890 # 80021bb8 <log>
    80004846:	8526                	mv	a0,s1
    80004848:	ffffe097          	auipc	ra,0xffffe
    8000484c:	fb4080e7          	jalr	-76(ra) # 800027fc <wakeup>
  release(&log.lock);
    80004850:	8526                	mv	a0,s1
    80004852:	ffffc097          	auipc	ra,0xffffc
    80004856:	458080e7          	jalr	1112(ra) # 80000caa <release>
  if(do_commit){
    8000485a:	b7c9                	j	8000481c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000485c:	0001da97          	auipc	s5,0x1d
    80004860:	38ca8a93          	addi	s5,s5,908 # 80021be8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004864:	0001da17          	auipc	s4,0x1d
    80004868:	354a0a13          	addi	s4,s4,852 # 80021bb8 <log>
    8000486c:	018a2583          	lw	a1,24(s4)
    80004870:	012585bb          	addw	a1,a1,s2
    80004874:	2585                	addiw	a1,a1,1
    80004876:	028a2503          	lw	a0,40(s4)
    8000487a:	fffff097          	auipc	ra,0xfffff
    8000487e:	cd2080e7          	jalr	-814(ra) # 8000354c <bread>
    80004882:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004884:	000aa583          	lw	a1,0(s5)
    80004888:	028a2503          	lw	a0,40(s4)
    8000488c:	fffff097          	auipc	ra,0xfffff
    80004890:	cc0080e7          	jalr	-832(ra) # 8000354c <bread>
    80004894:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004896:	40000613          	li	a2,1024
    8000489a:	05850593          	addi	a1,a0,88
    8000489e:	05848513          	addi	a0,s1,88
    800048a2:	ffffc097          	auipc	ra,0xffffc
    800048a6:	4c2080e7          	jalr	1218(ra) # 80000d64 <memmove>
    bwrite(to);  // write the log
    800048aa:	8526                	mv	a0,s1
    800048ac:	fffff097          	auipc	ra,0xfffff
    800048b0:	d92080e7          	jalr	-622(ra) # 8000363e <bwrite>
    brelse(from);
    800048b4:	854e                	mv	a0,s3
    800048b6:	fffff097          	auipc	ra,0xfffff
    800048ba:	dc6080e7          	jalr	-570(ra) # 8000367c <brelse>
    brelse(to);
    800048be:	8526                	mv	a0,s1
    800048c0:	fffff097          	auipc	ra,0xfffff
    800048c4:	dbc080e7          	jalr	-580(ra) # 8000367c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048c8:	2905                	addiw	s2,s2,1
    800048ca:	0a91                	addi	s5,s5,4
    800048cc:	02ca2783          	lw	a5,44(s4)
    800048d0:	f8f94ee3          	blt	s2,a5,8000486c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800048d4:	00000097          	auipc	ra,0x0
    800048d8:	c6a080e7          	jalr	-918(ra) # 8000453e <write_head>
    install_trans(0); // Now install writes to home locations
    800048dc:	4501                	li	a0,0
    800048de:	00000097          	auipc	ra,0x0
    800048e2:	cda080e7          	jalr	-806(ra) # 800045b8 <install_trans>
    log.lh.n = 0;
    800048e6:	0001d797          	auipc	a5,0x1d
    800048ea:	2e07af23          	sw	zero,766(a5) # 80021be4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048ee:	00000097          	auipc	ra,0x0
    800048f2:	c50080e7          	jalr	-944(ra) # 8000453e <write_head>
    800048f6:	bdf5                	j	800047f2 <end_op+0x52>

00000000800048f8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048f8:	1101                	addi	sp,sp,-32
    800048fa:	ec06                	sd	ra,24(sp)
    800048fc:	e822                	sd	s0,16(sp)
    800048fe:	e426                	sd	s1,8(sp)
    80004900:	e04a                	sd	s2,0(sp)
    80004902:	1000                	addi	s0,sp,32
    80004904:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004906:	0001d917          	auipc	s2,0x1d
    8000490a:	2b290913          	addi	s2,s2,690 # 80021bb8 <log>
    8000490e:	854a                	mv	a0,s2
    80004910:	ffffc097          	auipc	ra,0xffffc
    80004914:	2d4080e7          	jalr	724(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004918:	02c92603          	lw	a2,44(s2)
    8000491c:	47f5                	li	a5,29
    8000491e:	06c7c563          	blt	a5,a2,80004988 <log_write+0x90>
    80004922:	0001d797          	auipc	a5,0x1d
    80004926:	2b27a783          	lw	a5,690(a5) # 80021bd4 <log+0x1c>
    8000492a:	37fd                	addiw	a5,a5,-1
    8000492c:	04f65e63          	bge	a2,a5,80004988 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004930:	0001d797          	auipc	a5,0x1d
    80004934:	2a87a783          	lw	a5,680(a5) # 80021bd8 <log+0x20>
    80004938:	06f05063          	blez	a5,80004998 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000493c:	4781                	li	a5,0
    8000493e:	06c05563          	blez	a2,800049a8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004942:	44cc                	lw	a1,12(s1)
    80004944:	0001d717          	auipc	a4,0x1d
    80004948:	2a470713          	addi	a4,a4,676 # 80021be8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000494c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000494e:	4314                	lw	a3,0(a4)
    80004950:	04b68c63          	beq	a3,a1,800049a8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004954:	2785                	addiw	a5,a5,1
    80004956:	0711                	addi	a4,a4,4
    80004958:	fef61be3          	bne	a2,a5,8000494e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000495c:	0621                	addi	a2,a2,8
    8000495e:	060a                	slli	a2,a2,0x2
    80004960:	0001d797          	auipc	a5,0x1d
    80004964:	25878793          	addi	a5,a5,600 # 80021bb8 <log>
    80004968:	963e                	add	a2,a2,a5
    8000496a:	44dc                	lw	a5,12(s1)
    8000496c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000496e:	8526                	mv	a0,s1
    80004970:	fffff097          	auipc	ra,0xfffff
    80004974:	daa080e7          	jalr	-598(ra) # 8000371a <bpin>
    log.lh.n++;
    80004978:	0001d717          	auipc	a4,0x1d
    8000497c:	24070713          	addi	a4,a4,576 # 80021bb8 <log>
    80004980:	575c                	lw	a5,44(a4)
    80004982:	2785                	addiw	a5,a5,1
    80004984:	d75c                	sw	a5,44(a4)
    80004986:	a835                	j	800049c2 <log_write+0xca>
    panic("too big a transaction");
    80004988:	00004517          	auipc	a0,0x4
    8000498c:	d0850513          	addi	a0,a0,-760 # 80008690 <syscalls+0x200>
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	bae080e7          	jalr	-1106(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004998:	00004517          	auipc	a0,0x4
    8000499c:	d1050513          	addi	a0,a0,-752 # 800086a8 <syscalls+0x218>
    800049a0:	ffffc097          	auipc	ra,0xffffc
    800049a4:	b9e080e7          	jalr	-1122(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800049a8:	00878713          	addi	a4,a5,8
    800049ac:	00271693          	slli	a3,a4,0x2
    800049b0:	0001d717          	auipc	a4,0x1d
    800049b4:	20870713          	addi	a4,a4,520 # 80021bb8 <log>
    800049b8:	9736                	add	a4,a4,a3
    800049ba:	44d4                	lw	a3,12(s1)
    800049bc:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800049be:	faf608e3          	beq	a2,a5,8000496e <log_write+0x76>
  }
  release(&log.lock);
    800049c2:	0001d517          	auipc	a0,0x1d
    800049c6:	1f650513          	addi	a0,a0,502 # 80021bb8 <log>
    800049ca:	ffffc097          	auipc	ra,0xffffc
    800049ce:	2e0080e7          	jalr	736(ra) # 80000caa <release>
}
    800049d2:	60e2                	ld	ra,24(sp)
    800049d4:	6442                	ld	s0,16(sp)
    800049d6:	64a2                	ld	s1,8(sp)
    800049d8:	6902                	ld	s2,0(sp)
    800049da:	6105                	addi	sp,sp,32
    800049dc:	8082                	ret

00000000800049de <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800049de:	1101                	addi	sp,sp,-32
    800049e0:	ec06                	sd	ra,24(sp)
    800049e2:	e822                	sd	s0,16(sp)
    800049e4:	e426                	sd	s1,8(sp)
    800049e6:	e04a                	sd	s2,0(sp)
    800049e8:	1000                	addi	s0,sp,32
    800049ea:	84aa                	mv	s1,a0
    800049ec:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049ee:	00004597          	auipc	a1,0x4
    800049f2:	cda58593          	addi	a1,a1,-806 # 800086c8 <syscalls+0x238>
    800049f6:	0521                	addi	a0,a0,8
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	15c080e7          	jalr	348(ra) # 80000b54 <initlock>
  lk->name = name;
    80004a00:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a04:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a08:	0204a423          	sw	zero,40(s1)
}
    80004a0c:	60e2                	ld	ra,24(sp)
    80004a0e:	6442                	ld	s0,16(sp)
    80004a10:	64a2                	ld	s1,8(sp)
    80004a12:	6902                	ld	s2,0(sp)
    80004a14:	6105                	addi	sp,sp,32
    80004a16:	8082                	ret

0000000080004a18 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a18:	1101                	addi	sp,sp,-32
    80004a1a:	ec06                	sd	ra,24(sp)
    80004a1c:	e822                	sd	s0,16(sp)
    80004a1e:	e426                	sd	s1,8(sp)
    80004a20:	e04a                	sd	s2,0(sp)
    80004a22:	1000                	addi	s0,sp,32
    80004a24:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a26:	00850913          	addi	s2,a0,8
    80004a2a:	854a                	mv	a0,s2
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	1b8080e7          	jalr	440(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004a34:	409c                	lw	a5,0(s1)
    80004a36:	cb89                	beqz	a5,80004a48 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a38:	85ca                	mv	a1,s2
    80004a3a:	8526                	mv	a0,s1
    80004a3c:	ffffe097          	auipc	ra,0xffffe
    80004a40:	c1a080e7          	jalr	-998(ra) # 80002656 <sleep>
  while (lk->locked) {
    80004a44:	409c                	lw	a5,0(s1)
    80004a46:	fbed                	bnez	a5,80004a38 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a48:	4785                	li	a5,1
    80004a4a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a4c:	ffffd097          	auipc	ra,0xffffd
    80004a50:	41c080e7          	jalr	1052(ra) # 80001e68 <myproc>
    80004a54:	591c                	lw	a5,48(a0)
    80004a56:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a58:	854a                	mv	a0,s2
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	250080e7          	jalr	592(ra) # 80000caa <release>
}
    80004a62:	60e2                	ld	ra,24(sp)
    80004a64:	6442                	ld	s0,16(sp)
    80004a66:	64a2                	ld	s1,8(sp)
    80004a68:	6902                	ld	s2,0(sp)
    80004a6a:	6105                	addi	sp,sp,32
    80004a6c:	8082                	ret

0000000080004a6e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a6e:	1101                	addi	sp,sp,-32
    80004a70:	ec06                	sd	ra,24(sp)
    80004a72:	e822                	sd	s0,16(sp)
    80004a74:	e426                	sd	s1,8(sp)
    80004a76:	e04a                	sd	s2,0(sp)
    80004a78:	1000                	addi	s0,sp,32
    80004a7a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a7c:	00850913          	addi	s2,a0,8
    80004a80:	854a                	mv	a0,s2
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	162080e7          	jalr	354(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004a8a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a8e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a92:	8526                	mv	a0,s1
    80004a94:	ffffe097          	auipc	ra,0xffffe
    80004a98:	d68080e7          	jalr	-664(ra) # 800027fc <wakeup>
  release(&lk->lk);
    80004a9c:	854a                	mv	a0,s2
    80004a9e:	ffffc097          	auipc	ra,0xffffc
    80004aa2:	20c080e7          	jalr	524(ra) # 80000caa <release>
}
    80004aa6:	60e2                	ld	ra,24(sp)
    80004aa8:	6442                	ld	s0,16(sp)
    80004aaa:	64a2                	ld	s1,8(sp)
    80004aac:	6902                	ld	s2,0(sp)
    80004aae:	6105                	addi	sp,sp,32
    80004ab0:	8082                	ret

0000000080004ab2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004ab2:	7179                	addi	sp,sp,-48
    80004ab4:	f406                	sd	ra,40(sp)
    80004ab6:	f022                	sd	s0,32(sp)
    80004ab8:	ec26                	sd	s1,24(sp)
    80004aba:	e84a                	sd	s2,16(sp)
    80004abc:	e44e                	sd	s3,8(sp)
    80004abe:	1800                	addi	s0,sp,48
    80004ac0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004ac2:	00850913          	addi	s2,a0,8
    80004ac6:	854a                	mv	a0,s2
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	11c080e7          	jalr	284(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ad0:	409c                	lw	a5,0(s1)
    80004ad2:	ef99                	bnez	a5,80004af0 <holdingsleep+0x3e>
    80004ad4:	4481                	li	s1,0
  release(&lk->lk);
    80004ad6:	854a                	mv	a0,s2
    80004ad8:	ffffc097          	auipc	ra,0xffffc
    80004adc:	1d2080e7          	jalr	466(ra) # 80000caa <release>
  return r;
}
    80004ae0:	8526                	mv	a0,s1
    80004ae2:	70a2                	ld	ra,40(sp)
    80004ae4:	7402                	ld	s0,32(sp)
    80004ae6:	64e2                	ld	s1,24(sp)
    80004ae8:	6942                	ld	s2,16(sp)
    80004aea:	69a2                	ld	s3,8(sp)
    80004aec:	6145                	addi	sp,sp,48
    80004aee:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004af0:	0284a983          	lw	s3,40(s1)
    80004af4:	ffffd097          	auipc	ra,0xffffd
    80004af8:	374080e7          	jalr	884(ra) # 80001e68 <myproc>
    80004afc:	5904                	lw	s1,48(a0)
    80004afe:	413484b3          	sub	s1,s1,s3
    80004b02:	0014b493          	seqz	s1,s1
    80004b06:	bfc1                	j	80004ad6 <holdingsleep+0x24>

0000000080004b08 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b08:	1141                	addi	sp,sp,-16
    80004b0a:	e406                	sd	ra,8(sp)
    80004b0c:	e022                	sd	s0,0(sp)
    80004b0e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b10:	00004597          	auipc	a1,0x4
    80004b14:	bc858593          	addi	a1,a1,-1080 # 800086d8 <syscalls+0x248>
    80004b18:	0001d517          	auipc	a0,0x1d
    80004b1c:	1e850513          	addi	a0,a0,488 # 80021d00 <ftable>
    80004b20:	ffffc097          	auipc	ra,0xffffc
    80004b24:	034080e7          	jalr	52(ra) # 80000b54 <initlock>
}
    80004b28:	60a2                	ld	ra,8(sp)
    80004b2a:	6402                	ld	s0,0(sp)
    80004b2c:	0141                	addi	sp,sp,16
    80004b2e:	8082                	ret

0000000080004b30 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b30:	1101                	addi	sp,sp,-32
    80004b32:	ec06                	sd	ra,24(sp)
    80004b34:	e822                	sd	s0,16(sp)
    80004b36:	e426                	sd	s1,8(sp)
    80004b38:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b3a:	0001d517          	auipc	a0,0x1d
    80004b3e:	1c650513          	addi	a0,a0,454 # 80021d00 <ftable>
    80004b42:	ffffc097          	auipc	ra,0xffffc
    80004b46:	0a2080e7          	jalr	162(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b4a:	0001d497          	auipc	s1,0x1d
    80004b4e:	1ce48493          	addi	s1,s1,462 # 80021d18 <ftable+0x18>
    80004b52:	0001e717          	auipc	a4,0x1e
    80004b56:	16670713          	addi	a4,a4,358 # 80022cb8 <ftable+0xfb8>
    if(f->ref == 0){
    80004b5a:	40dc                	lw	a5,4(s1)
    80004b5c:	cf99                	beqz	a5,80004b7a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b5e:	02848493          	addi	s1,s1,40
    80004b62:	fee49ce3          	bne	s1,a4,80004b5a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b66:	0001d517          	auipc	a0,0x1d
    80004b6a:	19a50513          	addi	a0,a0,410 # 80021d00 <ftable>
    80004b6e:	ffffc097          	auipc	ra,0xffffc
    80004b72:	13c080e7          	jalr	316(ra) # 80000caa <release>
  return 0;
    80004b76:	4481                	li	s1,0
    80004b78:	a819                	j	80004b8e <filealloc+0x5e>
      f->ref = 1;
    80004b7a:	4785                	li	a5,1
    80004b7c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b7e:	0001d517          	auipc	a0,0x1d
    80004b82:	18250513          	addi	a0,a0,386 # 80021d00 <ftable>
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	124080e7          	jalr	292(ra) # 80000caa <release>
}
    80004b8e:	8526                	mv	a0,s1
    80004b90:	60e2                	ld	ra,24(sp)
    80004b92:	6442                	ld	s0,16(sp)
    80004b94:	64a2                	ld	s1,8(sp)
    80004b96:	6105                	addi	sp,sp,32
    80004b98:	8082                	ret

0000000080004b9a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b9a:	1101                	addi	sp,sp,-32
    80004b9c:	ec06                	sd	ra,24(sp)
    80004b9e:	e822                	sd	s0,16(sp)
    80004ba0:	e426                	sd	s1,8(sp)
    80004ba2:	1000                	addi	s0,sp,32
    80004ba4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004ba6:	0001d517          	auipc	a0,0x1d
    80004baa:	15a50513          	addi	a0,a0,346 # 80021d00 <ftable>
    80004bae:	ffffc097          	auipc	ra,0xffffc
    80004bb2:	036080e7          	jalr	54(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004bb6:	40dc                	lw	a5,4(s1)
    80004bb8:	02f05263          	blez	a5,80004bdc <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004bbc:	2785                	addiw	a5,a5,1
    80004bbe:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004bc0:	0001d517          	auipc	a0,0x1d
    80004bc4:	14050513          	addi	a0,a0,320 # 80021d00 <ftable>
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	0e2080e7          	jalr	226(ra) # 80000caa <release>
  return f;
}
    80004bd0:	8526                	mv	a0,s1
    80004bd2:	60e2                	ld	ra,24(sp)
    80004bd4:	6442                	ld	s0,16(sp)
    80004bd6:	64a2                	ld	s1,8(sp)
    80004bd8:	6105                	addi	sp,sp,32
    80004bda:	8082                	ret
    panic("filedup");
    80004bdc:	00004517          	auipc	a0,0x4
    80004be0:	b0450513          	addi	a0,a0,-1276 # 800086e0 <syscalls+0x250>
    80004be4:	ffffc097          	auipc	ra,0xffffc
    80004be8:	95a080e7          	jalr	-1702(ra) # 8000053e <panic>

0000000080004bec <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004bec:	7139                	addi	sp,sp,-64
    80004bee:	fc06                	sd	ra,56(sp)
    80004bf0:	f822                	sd	s0,48(sp)
    80004bf2:	f426                	sd	s1,40(sp)
    80004bf4:	f04a                	sd	s2,32(sp)
    80004bf6:	ec4e                	sd	s3,24(sp)
    80004bf8:	e852                	sd	s4,16(sp)
    80004bfa:	e456                	sd	s5,8(sp)
    80004bfc:	0080                	addi	s0,sp,64
    80004bfe:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c00:	0001d517          	auipc	a0,0x1d
    80004c04:	10050513          	addi	a0,a0,256 # 80021d00 <ftable>
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	fdc080e7          	jalr	-36(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004c10:	40dc                	lw	a5,4(s1)
    80004c12:	06f05163          	blez	a5,80004c74 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c16:	37fd                	addiw	a5,a5,-1
    80004c18:	0007871b          	sext.w	a4,a5
    80004c1c:	c0dc                	sw	a5,4(s1)
    80004c1e:	06e04363          	bgtz	a4,80004c84 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c22:	0004a903          	lw	s2,0(s1)
    80004c26:	0094ca83          	lbu	s5,9(s1)
    80004c2a:	0104ba03          	ld	s4,16(s1)
    80004c2e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c32:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c36:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c3a:	0001d517          	auipc	a0,0x1d
    80004c3e:	0c650513          	addi	a0,a0,198 # 80021d00 <ftable>
    80004c42:	ffffc097          	auipc	ra,0xffffc
    80004c46:	068080e7          	jalr	104(ra) # 80000caa <release>

  if(ff.type == FD_PIPE){
    80004c4a:	4785                	li	a5,1
    80004c4c:	04f90d63          	beq	s2,a5,80004ca6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c50:	3979                	addiw	s2,s2,-2
    80004c52:	4785                	li	a5,1
    80004c54:	0527e063          	bltu	a5,s2,80004c94 <fileclose+0xa8>
    begin_op();
    80004c58:	00000097          	auipc	ra,0x0
    80004c5c:	ac8080e7          	jalr	-1336(ra) # 80004720 <begin_op>
    iput(ff.ip);
    80004c60:	854e                	mv	a0,s3
    80004c62:	fffff097          	auipc	ra,0xfffff
    80004c66:	2a6080e7          	jalr	678(ra) # 80003f08 <iput>
    end_op();
    80004c6a:	00000097          	auipc	ra,0x0
    80004c6e:	b36080e7          	jalr	-1226(ra) # 800047a0 <end_op>
    80004c72:	a00d                	j	80004c94 <fileclose+0xa8>
    panic("fileclose");
    80004c74:	00004517          	auipc	a0,0x4
    80004c78:	a7450513          	addi	a0,a0,-1420 # 800086e8 <syscalls+0x258>
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	8c2080e7          	jalr	-1854(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004c84:	0001d517          	auipc	a0,0x1d
    80004c88:	07c50513          	addi	a0,a0,124 # 80021d00 <ftable>
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	01e080e7          	jalr	30(ra) # 80000caa <release>
  }
}
    80004c94:	70e2                	ld	ra,56(sp)
    80004c96:	7442                	ld	s0,48(sp)
    80004c98:	74a2                	ld	s1,40(sp)
    80004c9a:	7902                	ld	s2,32(sp)
    80004c9c:	69e2                	ld	s3,24(sp)
    80004c9e:	6a42                	ld	s4,16(sp)
    80004ca0:	6aa2                	ld	s5,8(sp)
    80004ca2:	6121                	addi	sp,sp,64
    80004ca4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004ca6:	85d6                	mv	a1,s5
    80004ca8:	8552                	mv	a0,s4
    80004caa:	00000097          	auipc	ra,0x0
    80004cae:	34c080e7          	jalr	844(ra) # 80004ff6 <pipeclose>
    80004cb2:	b7cd                	j	80004c94 <fileclose+0xa8>

0000000080004cb4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004cb4:	715d                	addi	sp,sp,-80
    80004cb6:	e486                	sd	ra,72(sp)
    80004cb8:	e0a2                	sd	s0,64(sp)
    80004cba:	fc26                	sd	s1,56(sp)
    80004cbc:	f84a                	sd	s2,48(sp)
    80004cbe:	f44e                	sd	s3,40(sp)
    80004cc0:	0880                	addi	s0,sp,80
    80004cc2:	84aa                	mv	s1,a0
    80004cc4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004cc6:	ffffd097          	auipc	ra,0xffffd
    80004cca:	1a2080e7          	jalr	418(ra) # 80001e68 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004cce:	409c                	lw	a5,0(s1)
    80004cd0:	37f9                	addiw	a5,a5,-2
    80004cd2:	4705                	li	a4,1
    80004cd4:	04f76763          	bltu	a4,a5,80004d22 <filestat+0x6e>
    80004cd8:	892a                	mv	s2,a0
    ilock(f->ip);
    80004cda:	6c88                	ld	a0,24(s1)
    80004cdc:	fffff097          	auipc	ra,0xfffff
    80004ce0:	072080e7          	jalr	114(ra) # 80003d4e <ilock>
    stati(f->ip, &st);
    80004ce4:	fb840593          	addi	a1,s0,-72
    80004ce8:	6c88                	ld	a0,24(s1)
    80004cea:	fffff097          	auipc	ra,0xfffff
    80004cee:	2ee080e7          	jalr	750(ra) # 80003fd8 <stati>
    iunlock(f->ip);
    80004cf2:	6c88                	ld	a0,24(s1)
    80004cf4:	fffff097          	auipc	ra,0xfffff
    80004cf8:	11c080e7          	jalr	284(ra) # 80003e10 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cfc:	46e1                	li	a3,24
    80004cfe:	fb840613          	addi	a2,s0,-72
    80004d02:	85ce                	mv	a1,s3
    80004d04:	07093503          	ld	a0,112(s2)
    80004d08:	ffffd097          	auipc	ra,0xffffd
    80004d0c:	98e080e7          	jalr	-1650(ra) # 80001696 <copyout>
    80004d10:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d14:	60a6                	ld	ra,72(sp)
    80004d16:	6406                	ld	s0,64(sp)
    80004d18:	74e2                	ld	s1,56(sp)
    80004d1a:	7942                	ld	s2,48(sp)
    80004d1c:	79a2                	ld	s3,40(sp)
    80004d1e:	6161                	addi	sp,sp,80
    80004d20:	8082                	ret
  return -1;
    80004d22:	557d                	li	a0,-1
    80004d24:	bfc5                	j	80004d14 <filestat+0x60>

0000000080004d26 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d26:	7179                	addi	sp,sp,-48
    80004d28:	f406                	sd	ra,40(sp)
    80004d2a:	f022                	sd	s0,32(sp)
    80004d2c:	ec26                	sd	s1,24(sp)
    80004d2e:	e84a                	sd	s2,16(sp)
    80004d30:	e44e                	sd	s3,8(sp)
    80004d32:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d34:	00854783          	lbu	a5,8(a0)
    80004d38:	c3d5                	beqz	a5,80004ddc <fileread+0xb6>
    80004d3a:	84aa                	mv	s1,a0
    80004d3c:	89ae                	mv	s3,a1
    80004d3e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d40:	411c                	lw	a5,0(a0)
    80004d42:	4705                	li	a4,1
    80004d44:	04e78963          	beq	a5,a4,80004d96 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d48:	470d                	li	a4,3
    80004d4a:	04e78d63          	beq	a5,a4,80004da4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d4e:	4709                	li	a4,2
    80004d50:	06e79e63          	bne	a5,a4,80004dcc <fileread+0xa6>
    ilock(f->ip);
    80004d54:	6d08                	ld	a0,24(a0)
    80004d56:	fffff097          	auipc	ra,0xfffff
    80004d5a:	ff8080e7          	jalr	-8(ra) # 80003d4e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d5e:	874a                	mv	a4,s2
    80004d60:	5094                	lw	a3,32(s1)
    80004d62:	864e                	mv	a2,s3
    80004d64:	4585                	li	a1,1
    80004d66:	6c88                	ld	a0,24(s1)
    80004d68:	fffff097          	auipc	ra,0xfffff
    80004d6c:	29a080e7          	jalr	666(ra) # 80004002 <readi>
    80004d70:	892a                	mv	s2,a0
    80004d72:	00a05563          	blez	a0,80004d7c <fileread+0x56>
      f->off += r;
    80004d76:	509c                	lw	a5,32(s1)
    80004d78:	9fa9                	addw	a5,a5,a0
    80004d7a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d7c:	6c88                	ld	a0,24(s1)
    80004d7e:	fffff097          	auipc	ra,0xfffff
    80004d82:	092080e7          	jalr	146(ra) # 80003e10 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d86:	854a                	mv	a0,s2
    80004d88:	70a2                	ld	ra,40(sp)
    80004d8a:	7402                	ld	s0,32(sp)
    80004d8c:	64e2                	ld	s1,24(sp)
    80004d8e:	6942                	ld	s2,16(sp)
    80004d90:	69a2                	ld	s3,8(sp)
    80004d92:	6145                	addi	sp,sp,48
    80004d94:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d96:	6908                	ld	a0,16(a0)
    80004d98:	00000097          	auipc	ra,0x0
    80004d9c:	3c8080e7          	jalr	968(ra) # 80005160 <piperead>
    80004da0:	892a                	mv	s2,a0
    80004da2:	b7d5                	j	80004d86 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004da4:	02451783          	lh	a5,36(a0)
    80004da8:	03079693          	slli	a3,a5,0x30
    80004dac:	92c1                	srli	a3,a3,0x30
    80004dae:	4725                	li	a4,9
    80004db0:	02d76863          	bltu	a4,a3,80004de0 <fileread+0xba>
    80004db4:	0792                	slli	a5,a5,0x4
    80004db6:	0001d717          	auipc	a4,0x1d
    80004dba:	eaa70713          	addi	a4,a4,-342 # 80021c60 <devsw>
    80004dbe:	97ba                	add	a5,a5,a4
    80004dc0:	639c                	ld	a5,0(a5)
    80004dc2:	c38d                	beqz	a5,80004de4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004dc4:	4505                	li	a0,1
    80004dc6:	9782                	jalr	a5
    80004dc8:	892a                	mv	s2,a0
    80004dca:	bf75                	j	80004d86 <fileread+0x60>
    panic("fileread");
    80004dcc:	00004517          	auipc	a0,0x4
    80004dd0:	92c50513          	addi	a0,a0,-1748 # 800086f8 <syscalls+0x268>
    80004dd4:	ffffb097          	auipc	ra,0xffffb
    80004dd8:	76a080e7          	jalr	1898(ra) # 8000053e <panic>
    return -1;
    80004ddc:	597d                	li	s2,-1
    80004dde:	b765                	j	80004d86 <fileread+0x60>
      return -1;
    80004de0:	597d                	li	s2,-1
    80004de2:	b755                	j	80004d86 <fileread+0x60>
    80004de4:	597d                	li	s2,-1
    80004de6:	b745                	j	80004d86 <fileread+0x60>

0000000080004de8 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004de8:	715d                	addi	sp,sp,-80
    80004dea:	e486                	sd	ra,72(sp)
    80004dec:	e0a2                	sd	s0,64(sp)
    80004dee:	fc26                	sd	s1,56(sp)
    80004df0:	f84a                	sd	s2,48(sp)
    80004df2:	f44e                	sd	s3,40(sp)
    80004df4:	f052                	sd	s4,32(sp)
    80004df6:	ec56                	sd	s5,24(sp)
    80004df8:	e85a                	sd	s6,16(sp)
    80004dfa:	e45e                	sd	s7,8(sp)
    80004dfc:	e062                	sd	s8,0(sp)
    80004dfe:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e00:	00954783          	lbu	a5,9(a0)
    80004e04:	10078663          	beqz	a5,80004f10 <filewrite+0x128>
    80004e08:	892a                	mv	s2,a0
    80004e0a:	8aae                	mv	s5,a1
    80004e0c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e0e:	411c                	lw	a5,0(a0)
    80004e10:	4705                	li	a4,1
    80004e12:	02e78263          	beq	a5,a4,80004e36 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e16:	470d                	li	a4,3
    80004e18:	02e78663          	beq	a5,a4,80004e44 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e1c:	4709                	li	a4,2
    80004e1e:	0ee79163          	bne	a5,a4,80004f00 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e22:	0ac05d63          	blez	a2,80004edc <filewrite+0xf4>
    int i = 0;
    80004e26:	4981                	li	s3,0
    80004e28:	6b05                	lui	s6,0x1
    80004e2a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004e2e:	6b85                	lui	s7,0x1
    80004e30:	c00b8b9b          	addiw	s7,s7,-1024
    80004e34:	a861                	j	80004ecc <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004e36:	6908                	ld	a0,16(a0)
    80004e38:	00000097          	auipc	ra,0x0
    80004e3c:	22e080e7          	jalr	558(ra) # 80005066 <pipewrite>
    80004e40:	8a2a                	mv	s4,a0
    80004e42:	a045                	j	80004ee2 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e44:	02451783          	lh	a5,36(a0)
    80004e48:	03079693          	slli	a3,a5,0x30
    80004e4c:	92c1                	srli	a3,a3,0x30
    80004e4e:	4725                	li	a4,9
    80004e50:	0cd76263          	bltu	a4,a3,80004f14 <filewrite+0x12c>
    80004e54:	0792                	slli	a5,a5,0x4
    80004e56:	0001d717          	auipc	a4,0x1d
    80004e5a:	e0a70713          	addi	a4,a4,-502 # 80021c60 <devsw>
    80004e5e:	97ba                	add	a5,a5,a4
    80004e60:	679c                	ld	a5,8(a5)
    80004e62:	cbdd                	beqz	a5,80004f18 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e64:	4505                	li	a0,1
    80004e66:	9782                	jalr	a5
    80004e68:	8a2a                	mv	s4,a0
    80004e6a:	a8a5                	j	80004ee2 <filewrite+0xfa>
    80004e6c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e70:	00000097          	auipc	ra,0x0
    80004e74:	8b0080e7          	jalr	-1872(ra) # 80004720 <begin_op>
      ilock(f->ip);
    80004e78:	01893503          	ld	a0,24(s2)
    80004e7c:	fffff097          	auipc	ra,0xfffff
    80004e80:	ed2080e7          	jalr	-302(ra) # 80003d4e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e84:	8762                	mv	a4,s8
    80004e86:	02092683          	lw	a3,32(s2)
    80004e8a:	01598633          	add	a2,s3,s5
    80004e8e:	4585                	li	a1,1
    80004e90:	01893503          	ld	a0,24(s2)
    80004e94:	fffff097          	auipc	ra,0xfffff
    80004e98:	266080e7          	jalr	614(ra) # 800040fa <writei>
    80004e9c:	84aa                	mv	s1,a0
    80004e9e:	00a05763          	blez	a0,80004eac <filewrite+0xc4>
        f->off += r;
    80004ea2:	02092783          	lw	a5,32(s2)
    80004ea6:	9fa9                	addw	a5,a5,a0
    80004ea8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004eac:	01893503          	ld	a0,24(s2)
    80004eb0:	fffff097          	auipc	ra,0xfffff
    80004eb4:	f60080e7          	jalr	-160(ra) # 80003e10 <iunlock>
      end_op();
    80004eb8:	00000097          	auipc	ra,0x0
    80004ebc:	8e8080e7          	jalr	-1816(ra) # 800047a0 <end_op>

      if(r != n1){
    80004ec0:	009c1f63          	bne	s8,s1,80004ede <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ec4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ec8:	0149db63          	bge	s3,s4,80004ede <filewrite+0xf6>
      int n1 = n - i;
    80004ecc:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004ed0:	84be                	mv	s1,a5
    80004ed2:	2781                	sext.w	a5,a5
    80004ed4:	f8fb5ce3          	bge	s6,a5,80004e6c <filewrite+0x84>
    80004ed8:	84de                	mv	s1,s7
    80004eda:	bf49                	j	80004e6c <filewrite+0x84>
    int i = 0;
    80004edc:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ede:	013a1f63          	bne	s4,s3,80004efc <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ee2:	8552                	mv	a0,s4
    80004ee4:	60a6                	ld	ra,72(sp)
    80004ee6:	6406                	ld	s0,64(sp)
    80004ee8:	74e2                	ld	s1,56(sp)
    80004eea:	7942                	ld	s2,48(sp)
    80004eec:	79a2                	ld	s3,40(sp)
    80004eee:	7a02                	ld	s4,32(sp)
    80004ef0:	6ae2                	ld	s5,24(sp)
    80004ef2:	6b42                	ld	s6,16(sp)
    80004ef4:	6ba2                	ld	s7,8(sp)
    80004ef6:	6c02                	ld	s8,0(sp)
    80004ef8:	6161                	addi	sp,sp,80
    80004efa:	8082                	ret
    ret = (i == n ? n : -1);
    80004efc:	5a7d                	li	s4,-1
    80004efe:	b7d5                	j	80004ee2 <filewrite+0xfa>
    panic("filewrite");
    80004f00:	00004517          	auipc	a0,0x4
    80004f04:	80850513          	addi	a0,a0,-2040 # 80008708 <syscalls+0x278>
    80004f08:	ffffb097          	auipc	ra,0xffffb
    80004f0c:	636080e7          	jalr	1590(ra) # 8000053e <panic>
    return -1;
    80004f10:	5a7d                	li	s4,-1
    80004f12:	bfc1                	j	80004ee2 <filewrite+0xfa>
      return -1;
    80004f14:	5a7d                	li	s4,-1
    80004f16:	b7f1                	j	80004ee2 <filewrite+0xfa>
    80004f18:	5a7d                	li	s4,-1
    80004f1a:	b7e1                	j	80004ee2 <filewrite+0xfa>

0000000080004f1c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f1c:	7179                	addi	sp,sp,-48
    80004f1e:	f406                	sd	ra,40(sp)
    80004f20:	f022                	sd	s0,32(sp)
    80004f22:	ec26                	sd	s1,24(sp)
    80004f24:	e84a                	sd	s2,16(sp)
    80004f26:	e44e                	sd	s3,8(sp)
    80004f28:	e052                	sd	s4,0(sp)
    80004f2a:	1800                	addi	s0,sp,48
    80004f2c:	84aa                	mv	s1,a0
    80004f2e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f30:	0005b023          	sd	zero,0(a1)
    80004f34:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f38:	00000097          	auipc	ra,0x0
    80004f3c:	bf8080e7          	jalr	-1032(ra) # 80004b30 <filealloc>
    80004f40:	e088                	sd	a0,0(s1)
    80004f42:	c551                	beqz	a0,80004fce <pipealloc+0xb2>
    80004f44:	00000097          	auipc	ra,0x0
    80004f48:	bec080e7          	jalr	-1044(ra) # 80004b30 <filealloc>
    80004f4c:	00aa3023          	sd	a0,0(s4)
    80004f50:	c92d                	beqz	a0,80004fc2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f52:	ffffc097          	auipc	ra,0xffffc
    80004f56:	ba2080e7          	jalr	-1118(ra) # 80000af4 <kalloc>
    80004f5a:	892a                	mv	s2,a0
    80004f5c:	c125                	beqz	a0,80004fbc <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f5e:	4985                	li	s3,1
    80004f60:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f64:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f68:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f6c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f70:	00003597          	auipc	a1,0x3
    80004f74:	7a858593          	addi	a1,a1,1960 # 80008718 <syscalls+0x288>
    80004f78:	ffffc097          	auipc	ra,0xffffc
    80004f7c:	bdc080e7          	jalr	-1060(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004f80:	609c                	ld	a5,0(s1)
    80004f82:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f86:	609c                	ld	a5,0(s1)
    80004f88:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f8c:	609c                	ld	a5,0(s1)
    80004f8e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f92:	609c                	ld	a5,0(s1)
    80004f94:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f98:	000a3783          	ld	a5,0(s4)
    80004f9c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004fa0:	000a3783          	ld	a5,0(s4)
    80004fa4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004fa8:	000a3783          	ld	a5,0(s4)
    80004fac:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004fb0:	000a3783          	ld	a5,0(s4)
    80004fb4:	0127b823          	sd	s2,16(a5)
  return 0;
    80004fb8:	4501                	li	a0,0
    80004fba:	a025                	j	80004fe2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004fbc:	6088                	ld	a0,0(s1)
    80004fbe:	e501                	bnez	a0,80004fc6 <pipealloc+0xaa>
    80004fc0:	a039                	j	80004fce <pipealloc+0xb2>
    80004fc2:	6088                	ld	a0,0(s1)
    80004fc4:	c51d                	beqz	a0,80004ff2 <pipealloc+0xd6>
    fileclose(*f0);
    80004fc6:	00000097          	auipc	ra,0x0
    80004fca:	c26080e7          	jalr	-986(ra) # 80004bec <fileclose>
  if(*f1)
    80004fce:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004fd2:	557d                	li	a0,-1
  if(*f1)
    80004fd4:	c799                	beqz	a5,80004fe2 <pipealloc+0xc6>
    fileclose(*f1);
    80004fd6:	853e                	mv	a0,a5
    80004fd8:	00000097          	auipc	ra,0x0
    80004fdc:	c14080e7          	jalr	-1004(ra) # 80004bec <fileclose>
  return -1;
    80004fe0:	557d                	li	a0,-1
}
    80004fe2:	70a2                	ld	ra,40(sp)
    80004fe4:	7402                	ld	s0,32(sp)
    80004fe6:	64e2                	ld	s1,24(sp)
    80004fe8:	6942                	ld	s2,16(sp)
    80004fea:	69a2                	ld	s3,8(sp)
    80004fec:	6a02                	ld	s4,0(sp)
    80004fee:	6145                	addi	sp,sp,48
    80004ff0:	8082                	ret
  return -1;
    80004ff2:	557d                	li	a0,-1
    80004ff4:	b7fd                	j	80004fe2 <pipealloc+0xc6>

0000000080004ff6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ff6:	1101                	addi	sp,sp,-32
    80004ff8:	ec06                	sd	ra,24(sp)
    80004ffa:	e822                	sd	s0,16(sp)
    80004ffc:	e426                	sd	s1,8(sp)
    80004ffe:	e04a                	sd	s2,0(sp)
    80005000:	1000                	addi	s0,sp,32
    80005002:	84aa                	mv	s1,a0
    80005004:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005006:	ffffc097          	auipc	ra,0xffffc
    8000500a:	bde080e7          	jalr	-1058(ra) # 80000be4 <acquire>
  if(writable){
    8000500e:	02090d63          	beqz	s2,80005048 <pipeclose+0x52>
    pi->writeopen = 0;
    80005012:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005016:	21848513          	addi	a0,s1,536
    8000501a:	ffffd097          	auipc	ra,0xffffd
    8000501e:	7e2080e7          	jalr	2018(ra) # 800027fc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005022:	2204b783          	ld	a5,544(s1)
    80005026:	eb95                	bnez	a5,8000505a <pipeclose+0x64>
    release(&pi->lock);
    80005028:	8526                	mv	a0,s1
    8000502a:	ffffc097          	auipc	ra,0xffffc
    8000502e:	c80080e7          	jalr	-896(ra) # 80000caa <release>
    kfree((char*)pi);
    80005032:	8526                	mv	a0,s1
    80005034:	ffffc097          	auipc	ra,0xffffc
    80005038:	9c4080e7          	jalr	-1596(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    8000503c:	60e2                	ld	ra,24(sp)
    8000503e:	6442                	ld	s0,16(sp)
    80005040:	64a2                	ld	s1,8(sp)
    80005042:	6902                	ld	s2,0(sp)
    80005044:	6105                	addi	sp,sp,32
    80005046:	8082                	ret
    pi->readopen = 0;
    80005048:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000504c:	21c48513          	addi	a0,s1,540
    80005050:	ffffd097          	auipc	ra,0xffffd
    80005054:	7ac080e7          	jalr	1964(ra) # 800027fc <wakeup>
    80005058:	b7e9                	j	80005022 <pipeclose+0x2c>
    release(&pi->lock);
    8000505a:	8526                	mv	a0,s1
    8000505c:	ffffc097          	auipc	ra,0xffffc
    80005060:	c4e080e7          	jalr	-946(ra) # 80000caa <release>
}
    80005064:	bfe1                	j	8000503c <pipeclose+0x46>

0000000080005066 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005066:	7159                	addi	sp,sp,-112
    80005068:	f486                	sd	ra,104(sp)
    8000506a:	f0a2                	sd	s0,96(sp)
    8000506c:	eca6                	sd	s1,88(sp)
    8000506e:	e8ca                	sd	s2,80(sp)
    80005070:	e4ce                	sd	s3,72(sp)
    80005072:	e0d2                	sd	s4,64(sp)
    80005074:	fc56                	sd	s5,56(sp)
    80005076:	f85a                	sd	s6,48(sp)
    80005078:	f45e                	sd	s7,40(sp)
    8000507a:	f062                	sd	s8,32(sp)
    8000507c:	ec66                	sd	s9,24(sp)
    8000507e:	1880                	addi	s0,sp,112
    80005080:	84aa                	mv	s1,a0
    80005082:	8aae                	mv	s5,a1
    80005084:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005086:	ffffd097          	auipc	ra,0xffffd
    8000508a:	de2080e7          	jalr	-542(ra) # 80001e68 <myproc>
    8000508e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005090:	8526                	mv	a0,s1
    80005092:	ffffc097          	auipc	ra,0xffffc
    80005096:	b52080e7          	jalr	-1198(ra) # 80000be4 <acquire>
  while(i < n){
    8000509a:	0d405163          	blez	s4,8000515c <pipewrite+0xf6>
    8000509e:	8ba6                	mv	s7,s1
  int i = 0;
    800050a0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050a2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800050a4:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800050a8:	21c48c13          	addi	s8,s1,540
    800050ac:	a08d                	j	8000510e <pipewrite+0xa8>
      release(&pi->lock);
    800050ae:	8526                	mv	a0,s1
    800050b0:	ffffc097          	auipc	ra,0xffffc
    800050b4:	bfa080e7          	jalr	-1030(ra) # 80000caa <release>
      return -1;
    800050b8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800050ba:	854a                	mv	a0,s2
    800050bc:	70a6                	ld	ra,104(sp)
    800050be:	7406                	ld	s0,96(sp)
    800050c0:	64e6                	ld	s1,88(sp)
    800050c2:	6946                	ld	s2,80(sp)
    800050c4:	69a6                	ld	s3,72(sp)
    800050c6:	6a06                	ld	s4,64(sp)
    800050c8:	7ae2                	ld	s5,56(sp)
    800050ca:	7b42                	ld	s6,48(sp)
    800050cc:	7ba2                	ld	s7,40(sp)
    800050ce:	7c02                	ld	s8,32(sp)
    800050d0:	6ce2                	ld	s9,24(sp)
    800050d2:	6165                	addi	sp,sp,112
    800050d4:	8082                	ret
      wakeup(&pi->nread);
    800050d6:	8566                	mv	a0,s9
    800050d8:	ffffd097          	auipc	ra,0xffffd
    800050dc:	724080e7          	jalr	1828(ra) # 800027fc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800050e0:	85de                	mv	a1,s7
    800050e2:	8562                	mv	a0,s8
    800050e4:	ffffd097          	auipc	ra,0xffffd
    800050e8:	572080e7          	jalr	1394(ra) # 80002656 <sleep>
    800050ec:	a839                	j	8000510a <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050ee:	21c4a783          	lw	a5,540(s1)
    800050f2:	0017871b          	addiw	a4,a5,1
    800050f6:	20e4ae23          	sw	a4,540(s1)
    800050fa:	1ff7f793          	andi	a5,a5,511
    800050fe:	97a6                	add	a5,a5,s1
    80005100:	f9f44703          	lbu	a4,-97(s0)
    80005104:	00e78c23          	sb	a4,24(a5)
      i++;
    80005108:	2905                	addiw	s2,s2,1
  while(i < n){
    8000510a:	03495d63          	bge	s2,s4,80005144 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    8000510e:	2204a783          	lw	a5,544(s1)
    80005112:	dfd1                	beqz	a5,800050ae <pipewrite+0x48>
    80005114:	0289a783          	lw	a5,40(s3)
    80005118:	fbd9                	bnez	a5,800050ae <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000511a:	2184a783          	lw	a5,536(s1)
    8000511e:	21c4a703          	lw	a4,540(s1)
    80005122:	2007879b          	addiw	a5,a5,512
    80005126:	faf708e3          	beq	a4,a5,800050d6 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000512a:	4685                	li	a3,1
    8000512c:	01590633          	add	a2,s2,s5
    80005130:	f9f40593          	addi	a1,s0,-97
    80005134:	0709b503          	ld	a0,112(s3)
    80005138:	ffffc097          	auipc	ra,0xffffc
    8000513c:	5ea080e7          	jalr	1514(ra) # 80001722 <copyin>
    80005140:	fb6517e3          	bne	a0,s6,800050ee <pipewrite+0x88>
  wakeup(&pi->nread);
    80005144:	21848513          	addi	a0,s1,536
    80005148:	ffffd097          	auipc	ra,0xffffd
    8000514c:	6b4080e7          	jalr	1716(ra) # 800027fc <wakeup>
  release(&pi->lock);
    80005150:	8526                	mv	a0,s1
    80005152:	ffffc097          	auipc	ra,0xffffc
    80005156:	b58080e7          	jalr	-1192(ra) # 80000caa <release>
  return i;
    8000515a:	b785                	j	800050ba <pipewrite+0x54>
  int i = 0;
    8000515c:	4901                	li	s2,0
    8000515e:	b7dd                	j	80005144 <pipewrite+0xde>

0000000080005160 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005160:	715d                	addi	sp,sp,-80
    80005162:	e486                	sd	ra,72(sp)
    80005164:	e0a2                	sd	s0,64(sp)
    80005166:	fc26                	sd	s1,56(sp)
    80005168:	f84a                	sd	s2,48(sp)
    8000516a:	f44e                	sd	s3,40(sp)
    8000516c:	f052                	sd	s4,32(sp)
    8000516e:	ec56                	sd	s5,24(sp)
    80005170:	e85a                	sd	s6,16(sp)
    80005172:	0880                	addi	s0,sp,80
    80005174:	84aa                	mv	s1,a0
    80005176:	892e                	mv	s2,a1
    80005178:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000517a:	ffffd097          	auipc	ra,0xffffd
    8000517e:	cee080e7          	jalr	-786(ra) # 80001e68 <myproc>
    80005182:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005184:	8b26                	mv	s6,s1
    80005186:	8526                	mv	a0,s1
    80005188:	ffffc097          	auipc	ra,0xffffc
    8000518c:	a5c080e7          	jalr	-1444(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005190:	2184a703          	lw	a4,536(s1)
    80005194:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005198:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000519c:	02f71463          	bne	a4,a5,800051c4 <piperead+0x64>
    800051a0:	2244a783          	lw	a5,548(s1)
    800051a4:	c385                	beqz	a5,800051c4 <piperead+0x64>
    if(pr->killed){
    800051a6:	028a2783          	lw	a5,40(s4)
    800051aa:	ebc1                	bnez	a5,8000523a <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051ac:	85da                	mv	a1,s6
    800051ae:	854e                	mv	a0,s3
    800051b0:	ffffd097          	auipc	ra,0xffffd
    800051b4:	4a6080e7          	jalr	1190(ra) # 80002656 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051b8:	2184a703          	lw	a4,536(s1)
    800051bc:	21c4a783          	lw	a5,540(s1)
    800051c0:	fef700e3          	beq	a4,a5,800051a0 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051c4:	09505263          	blez	s5,80005248 <piperead+0xe8>
    800051c8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051ca:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800051cc:	2184a783          	lw	a5,536(s1)
    800051d0:	21c4a703          	lw	a4,540(s1)
    800051d4:	02f70d63          	beq	a4,a5,8000520e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800051d8:	0017871b          	addiw	a4,a5,1
    800051dc:	20e4ac23          	sw	a4,536(s1)
    800051e0:	1ff7f793          	andi	a5,a5,511
    800051e4:	97a6                	add	a5,a5,s1
    800051e6:	0187c783          	lbu	a5,24(a5)
    800051ea:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051ee:	4685                	li	a3,1
    800051f0:	fbf40613          	addi	a2,s0,-65
    800051f4:	85ca                	mv	a1,s2
    800051f6:	070a3503          	ld	a0,112(s4)
    800051fa:	ffffc097          	auipc	ra,0xffffc
    800051fe:	49c080e7          	jalr	1180(ra) # 80001696 <copyout>
    80005202:	01650663          	beq	a0,s6,8000520e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005206:	2985                	addiw	s3,s3,1
    80005208:	0905                	addi	s2,s2,1
    8000520a:	fd3a91e3          	bne	s5,s3,800051cc <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000520e:	21c48513          	addi	a0,s1,540
    80005212:	ffffd097          	auipc	ra,0xffffd
    80005216:	5ea080e7          	jalr	1514(ra) # 800027fc <wakeup>
  release(&pi->lock);
    8000521a:	8526                	mv	a0,s1
    8000521c:	ffffc097          	auipc	ra,0xffffc
    80005220:	a8e080e7          	jalr	-1394(ra) # 80000caa <release>
  return i;
}
    80005224:	854e                	mv	a0,s3
    80005226:	60a6                	ld	ra,72(sp)
    80005228:	6406                	ld	s0,64(sp)
    8000522a:	74e2                	ld	s1,56(sp)
    8000522c:	7942                	ld	s2,48(sp)
    8000522e:	79a2                	ld	s3,40(sp)
    80005230:	7a02                	ld	s4,32(sp)
    80005232:	6ae2                	ld	s5,24(sp)
    80005234:	6b42                	ld	s6,16(sp)
    80005236:	6161                	addi	sp,sp,80
    80005238:	8082                	ret
      release(&pi->lock);
    8000523a:	8526                	mv	a0,s1
    8000523c:	ffffc097          	auipc	ra,0xffffc
    80005240:	a6e080e7          	jalr	-1426(ra) # 80000caa <release>
      return -1;
    80005244:	59fd                	li	s3,-1
    80005246:	bff9                	j	80005224 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005248:	4981                	li	s3,0
    8000524a:	b7d1                	j	8000520e <piperead+0xae>

000000008000524c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000524c:	df010113          	addi	sp,sp,-528
    80005250:	20113423          	sd	ra,520(sp)
    80005254:	20813023          	sd	s0,512(sp)
    80005258:	ffa6                	sd	s1,504(sp)
    8000525a:	fbca                	sd	s2,496(sp)
    8000525c:	f7ce                	sd	s3,488(sp)
    8000525e:	f3d2                	sd	s4,480(sp)
    80005260:	efd6                	sd	s5,472(sp)
    80005262:	ebda                	sd	s6,464(sp)
    80005264:	e7de                	sd	s7,456(sp)
    80005266:	e3e2                	sd	s8,448(sp)
    80005268:	ff66                	sd	s9,440(sp)
    8000526a:	fb6a                	sd	s10,432(sp)
    8000526c:	f76e                	sd	s11,424(sp)
    8000526e:	0c00                	addi	s0,sp,528
    80005270:	84aa                	mv	s1,a0
    80005272:	dea43c23          	sd	a0,-520(s0)
    80005276:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000527a:	ffffd097          	auipc	ra,0xffffd
    8000527e:	bee080e7          	jalr	-1042(ra) # 80001e68 <myproc>
    80005282:	892a                	mv	s2,a0

  begin_op();
    80005284:	fffff097          	auipc	ra,0xfffff
    80005288:	49c080e7          	jalr	1180(ra) # 80004720 <begin_op>

  if((ip = namei(path)) == 0){
    8000528c:	8526                	mv	a0,s1
    8000528e:	fffff097          	auipc	ra,0xfffff
    80005292:	276080e7          	jalr	630(ra) # 80004504 <namei>
    80005296:	c92d                	beqz	a0,80005308 <exec+0xbc>
    80005298:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000529a:	fffff097          	auipc	ra,0xfffff
    8000529e:	ab4080e7          	jalr	-1356(ra) # 80003d4e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800052a2:	04000713          	li	a4,64
    800052a6:	4681                	li	a3,0
    800052a8:	e5040613          	addi	a2,s0,-432
    800052ac:	4581                	li	a1,0
    800052ae:	8526                	mv	a0,s1
    800052b0:	fffff097          	auipc	ra,0xfffff
    800052b4:	d52080e7          	jalr	-686(ra) # 80004002 <readi>
    800052b8:	04000793          	li	a5,64
    800052bc:	00f51a63          	bne	a0,a5,800052d0 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800052c0:	e5042703          	lw	a4,-432(s0)
    800052c4:	464c47b7          	lui	a5,0x464c4
    800052c8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800052cc:	04f70463          	beq	a4,a5,80005314 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800052d0:	8526                	mv	a0,s1
    800052d2:	fffff097          	auipc	ra,0xfffff
    800052d6:	cde080e7          	jalr	-802(ra) # 80003fb0 <iunlockput>
    end_op();
    800052da:	fffff097          	auipc	ra,0xfffff
    800052de:	4c6080e7          	jalr	1222(ra) # 800047a0 <end_op>
  }
  return -1;
    800052e2:	557d                	li	a0,-1
}
    800052e4:	20813083          	ld	ra,520(sp)
    800052e8:	20013403          	ld	s0,512(sp)
    800052ec:	74fe                	ld	s1,504(sp)
    800052ee:	795e                	ld	s2,496(sp)
    800052f0:	79be                	ld	s3,488(sp)
    800052f2:	7a1e                	ld	s4,480(sp)
    800052f4:	6afe                	ld	s5,472(sp)
    800052f6:	6b5e                	ld	s6,464(sp)
    800052f8:	6bbe                	ld	s7,456(sp)
    800052fa:	6c1e                	ld	s8,448(sp)
    800052fc:	7cfa                	ld	s9,440(sp)
    800052fe:	7d5a                	ld	s10,432(sp)
    80005300:	7dba                	ld	s11,424(sp)
    80005302:	21010113          	addi	sp,sp,528
    80005306:	8082                	ret
    end_op();
    80005308:	fffff097          	auipc	ra,0xfffff
    8000530c:	498080e7          	jalr	1176(ra) # 800047a0 <end_op>
    return -1;
    80005310:	557d                	li	a0,-1
    80005312:	bfc9                	j	800052e4 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005314:	854a                	mv	a0,s2
    80005316:	ffffd097          	auipc	ra,0xffffd
    8000531a:	c12080e7          	jalr	-1006(ra) # 80001f28 <proc_pagetable>
    8000531e:	8baa                	mv	s7,a0
    80005320:	d945                	beqz	a0,800052d0 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005322:	e7042983          	lw	s3,-400(s0)
    80005326:	e8845783          	lhu	a5,-376(s0)
    8000532a:	c7ad                	beqz	a5,80005394 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000532c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000532e:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005330:	6c85                	lui	s9,0x1
    80005332:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005336:	def43823          	sd	a5,-528(s0)
    8000533a:	a42d                	j	80005564 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000533c:	00003517          	auipc	a0,0x3
    80005340:	3e450513          	addi	a0,a0,996 # 80008720 <syscalls+0x290>
    80005344:	ffffb097          	auipc	ra,0xffffb
    80005348:	1fa080e7          	jalr	506(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000534c:	8756                	mv	a4,s5
    8000534e:	012d86bb          	addw	a3,s11,s2
    80005352:	4581                	li	a1,0
    80005354:	8526                	mv	a0,s1
    80005356:	fffff097          	auipc	ra,0xfffff
    8000535a:	cac080e7          	jalr	-852(ra) # 80004002 <readi>
    8000535e:	2501                	sext.w	a0,a0
    80005360:	1aaa9963          	bne	s5,a0,80005512 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005364:	6785                	lui	a5,0x1
    80005366:	0127893b          	addw	s2,a5,s2
    8000536a:	77fd                	lui	a5,0xfffff
    8000536c:	01478a3b          	addw	s4,a5,s4
    80005370:	1f897163          	bgeu	s2,s8,80005552 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005374:	02091593          	slli	a1,s2,0x20
    80005378:	9181                	srli	a1,a1,0x20
    8000537a:	95ea                	add	a1,a1,s10
    8000537c:	855e                	mv	a0,s7
    8000537e:	ffffc097          	auipc	ra,0xffffc
    80005382:	d14080e7          	jalr	-748(ra) # 80001092 <walkaddr>
    80005386:	862a                	mv	a2,a0
    if(pa == 0)
    80005388:	d955                	beqz	a0,8000533c <exec+0xf0>
      n = PGSIZE;
    8000538a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000538c:	fd9a70e3          	bgeu	s4,s9,8000534c <exec+0x100>
      n = sz - i;
    80005390:	8ad2                	mv	s5,s4
    80005392:	bf6d                	j	8000534c <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005394:	4901                	li	s2,0
  iunlockput(ip);
    80005396:	8526                	mv	a0,s1
    80005398:	fffff097          	auipc	ra,0xfffff
    8000539c:	c18080e7          	jalr	-1000(ra) # 80003fb0 <iunlockput>
  end_op();
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	400080e7          	jalr	1024(ra) # 800047a0 <end_op>
  p = myproc();
    800053a8:	ffffd097          	auipc	ra,0xffffd
    800053ac:	ac0080e7          	jalr	-1344(ra) # 80001e68 <myproc>
    800053b0:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800053b2:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    800053b6:	6785                	lui	a5,0x1
    800053b8:	17fd                	addi	a5,a5,-1
    800053ba:	993e                	add	s2,s2,a5
    800053bc:	757d                	lui	a0,0xfffff
    800053be:	00a977b3          	and	a5,s2,a0
    800053c2:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800053c6:	6609                	lui	a2,0x2
    800053c8:	963e                	add	a2,a2,a5
    800053ca:	85be                	mv	a1,a5
    800053cc:	855e                	mv	a0,s7
    800053ce:	ffffc097          	auipc	ra,0xffffc
    800053d2:	078080e7          	jalr	120(ra) # 80001446 <uvmalloc>
    800053d6:	8b2a                	mv	s6,a0
  ip = 0;
    800053d8:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800053da:	12050c63          	beqz	a0,80005512 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800053de:	75f9                	lui	a1,0xffffe
    800053e0:	95aa                	add	a1,a1,a0
    800053e2:	855e                	mv	a0,s7
    800053e4:	ffffc097          	auipc	ra,0xffffc
    800053e8:	280080e7          	jalr	640(ra) # 80001664 <uvmclear>
  stackbase = sp - PGSIZE;
    800053ec:	7c7d                	lui	s8,0xfffff
    800053ee:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800053f0:	e0043783          	ld	a5,-512(s0)
    800053f4:	6388                	ld	a0,0(a5)
    800053f6:	c535                	beqz	a0,80005462 <exec+0x216>
    800053f8:	e9040993          	addi	s3,s0,-368
    800053fc:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005400:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005402:	ffffc097          	auipc	ra,0xffffc
    80005406:	a86080e7          	jalr	-1402(ra) # 80000e88 <strlen>
    8000540a:	2505                	addiw	a0,a0,1
    8000540c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005410:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005414:	13896363          	bltu	s2,s8,8000553a <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005418:	e0043d83          	ld	s11,-512(s0)
    8000541c:	000dba03          	ld	s4,0(s11)
    80005420:	8552                	mv	a0,s4
    80005422:	ffffc097          	auipc	ra,0xffffc
    80005426:	a66080e7          	jalr	-1434(ra) # 80000e88 <strlen>
    8000542a:	0015069b          	addiw	a3,a0,1
    8000542e:	8652                	mv	a2,s4
    80005430:	85ca                	mv	a1,s2
    80005432:	855e                	mv	a0,s7
    80005434:	ffffc097          	auipc	ra,0xffffc
    80005438:	262080e7          	jalr	610(ra) # 80001696 <copyout>
    8000543c:	10054363          	bltz	a0,80005542 <exec+0x2f6>
    ustack[argc] = sp;
    80005440:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005444:	0485                	addi	s1,s1,1
    80005446:	008d8793          	addi	a5,s11,8
    8000544a:	e0f43023          	sd	a5,-512(s0)
    8000544e:	008db503          	ld	a0,8(s11)
    80005452:	c911                	beqz	a0,80005466 <exec+0x21a>
    if(argc >= MAXARG)
    80005454:	09a1                	addi	s3,s3,8
    80005456:	fb3c96e3          	bne	s9,s3,80005402 <exec+0x1b6>
  sz = sz1;
    8000545a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000545e:	4481                	li	s1,0
    80005460:	a84d                	j	80005512 <exec+0x2c6>
  sp = sz;
    80005462:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005464:	4481                	li	s1,0
  ustack[argc] = 0;
    80005466:	00349793          	slli	a5,s1,0x3
    8000546a:	f9040713          	addi	a4,s0,-112
    8000546e:	97ba                	add	a5,a5,a4
    80005470:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005474:	00148693          	addi	a3,s1,1
    80005478:	068e                	slli	a3,a3,0x3
    8000547a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000547e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005482:	01897663          	bgeu	s2,s8,8000548e <exec+0x242>
  sz = sz1;
    80005486:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000548a:	4481                	li	s1,0
    8000548c:	a059                	j	80005512 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000548e:	e9040613          	addi	a2,s0,-368
    80005492:	85ca                	mv	a1,s2
    80005494:	855e                	mv	a0,s7
    80005496:	ffffc097          	auipc	ra,0xffffc
    8000549a:	200080e7          	jalr	512(ra) # 80001696 <copyout>
    8000549e:	0a054663          	bltz	a0,8000554a <exec+0x2fe>
  p->trapframe->a1 = sp;
    800054a2:	078ab783          	ld	a5,120(s5)
    800054a6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800054aa:	df843783          	ld	a5,-520(s0)
    800054ae:	0007c703          	lbu	a4,0(a5)
    800054b2:	cf11                	beqz	a4,800054ce <exec+0x282>
    800054b4:	0785                	addi	a5,a5,1
    if(*s == '/')
    800054b6:	02f00693          	li	a3,47
    800054ba:	a039                	j	800054c8 <exec+0x27c>
      last = s+1;
    800054bc:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800054c0:	0785                	addi	a5,a5,1
    800054c2:	fff7c703          	lbu	a4,-1(a5)
    800054c6:	c701                	beqz	a4,800054ce <exec+0x282>
    if(*s == '/')
    800054c8:	fed71ce3          	bne	a4,a3,800054c0 <exec+0x274>
    800054cc:	bfc5                	j	800054bc <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800054ce:	4641                	li	a2,16
    800054d0:	df843583          	ld	a1,-520(s0)
    800054d4:	178a8513          	addi	a0,s5,376
    800054d8:	ffffc097          	auipc	ra,0xffffc
    800054dc:	97e080e7          	jalr	-1666(ra) # 80000e56 <safestrcpy>
  oldpagetable = p->pagetable;
    800054e0:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    800054e4:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    800054e8:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800054ec:	078ab783          	ld	a5,120(s5)
    800054f0:	e6843703          	ld	a4,-408(s0)
    800054f4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800054f6:	078ab783          	ld	a5,120(s5)
    800054fa:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054fe:	85ea                	mv	a1,s10
    80005500:	ffffd097          	auipc	ra,0xffffd
    80005504:	ac4080e7          	jalr	-1340(ra) # 80001fc4 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005508:	0004851b          	sext.w	a0,s1
    8000550c:	bbe1                	j	800052e4 <exec+0x98>
    8000550e:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005512:	e0843583          	ld	a1,-504(s0)
    80005516:	855e                	mv	a0,s7
    80005518:	ffffd097          	auipc	ra,0xffffd
    8000551c:	aac080e7          	jalr	-1364(ra) # 80001fc4 <proc_freepagetable>
  if(ip){
    80005520:	da0498e3          	bnez	s1,800052d0 <exec+0x84>
  return -1;
    80005524:	557d                	li	a0,-1
    80005526:	bb7d                	j	800052e4 <exec+0x98>
    80005528:	e1243423          	sd	s2,-504(s0)
    8000552c:	b7dd                	j	80005512 <exec+0x2c6>
    8000552e:	e1243423          	sd	s2,-504(s0)
    80005532:	b7c5                	j	80005512 <exec+0x2c6>
    80005534:	e1243423          	sd	s2,-504(s0)
    80005538:	bfe9                	j	80005512 <exec+0x2c6>
  sz = sz1;
    8000553a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000553e:	4481                	li	s1,0
    80005540:	bfc9                	j	80005512 <exec+0x2c6>
  sz = sz1;
    80005542:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005546:	4481                	li	s1,0
    80005548:	b7e9                	j	80005512 <exec+0x2c6>
  sz = sz1;
    8000554a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000554e:	4481                	li	s1,0
    80005550:	b7c9                	j	80005512 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005552:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005556:	2b05                	addiw	s6,s6,1
    80005558:	0389899b          	addiw	s3,s3,56
    8000555c:	e8845783          	lhu	a5,-376(s0)
    80005560:	e2fb5be3          	bge	s6,a5,80005396 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005564:	2981                	sext.w	s3,s3
    80005566:	03800713          	li	a4,56
    8000556a:	86ce                	mv	a3,s3
    8000556c:	e1840613          	addi	a2,s0,-488
    80005570:	4581                	li	a1,0
    80005572:	8526                	mv	a0,s1
    80005574:	fffff097          	auipc	ra,0xfffff
    80005578:	a8e080e7          	jalr	-1394(ra) # 80004002 <readi>
    8000557c:	03800793          	li	a5,56
    80005580:	f8f517e3          	bne	a0,a5,8000550e <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005584:	e1842783          	lw	a5,-488(s0)
    80005588:	4705                	li	a4,1
    8000558a:	fce796e3          	bne	a5,a4,80005556 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000558e:	e4043603          	ld	a2,-448(s0)
    80005592:	e3843783          	ld	a5,-456(s0)
    80005596:	f8f669e3          	bltu	a2,a5,80005528 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000559a:	e2843783          	ld	a5,-472(s0)
    8000559e:	963e                	add	a2,a2,a5
    800055a0:	f8f667e3          	bltu	a2,a5,8000552e <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800055a4:	85ca                	mv	a1,s2
    800055a6:	855e                	mv	a0,s7
    800055a8:	ffffc097          	auipc	ra,0xffffc
    800055ac:	e9e080e7          	jalr	-354(ra) # 80001446 <uvmalloc>
    800055b0:	e0a43423          	sd	a0,-504(s0)
    800055b4:	d141                	beqz	a0,80005534 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800055b6:	e2843d03          	ld	s10,-472(s0)
    800055ba:	df043783          	ld	a5,-528(s0)
    800055be:	00fd77b3          	and	a5,s10,a5
    800055c2:	fba1                	bnez	a5,80005512 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800055c4:	e2042d83          	lw	s11,-480(s0)
    800055c8:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800055cc:	f80c03e3          	beqz	s8,80005552 <exec+0x306>
    800055d0:	8a62                	mv	s4,s8
    800055d2:	4901                	li	s2,0
    800055d4:	b345                	j	80005374 <exec+0x128>

00000000800055d6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800055d6:	7179                	addi	sp,sp,-48
    800055d8:	f406                	sd	ra,40(sp)
    800055da:	f022                	sd	s0,32(sp)
    800055dc:	ec26                	sd	s1,24(sp)
    800055de:	e84a                	sd	s2,16(sp)
    800055e0:	1800                	addi	s0,sp,48
    800055e2:	892e                	mv	s2,a1
    800055e4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800055e6:	fdc40593          	addi	a1,s0,-36
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	ba8080e7          	jalr	-1112(ra) # 80003192 <argint>
    800055f2:	04054063          	bltz	a0,80005632 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800055f6:	fdc42703          	lw	a4,-36(s0)
    800055fa:	47bd                	li	a5,15
    800055fc:	02e7ed63          	bltu	a5,a4,80005636 <argfd+0x60>
    80005600:	ffffd097          	auipc	ra,0xffffd
    80005604:	868080e7          	jalr	-1944(ra) # 80001e68 <myproc>
    80005608:	fdc42703          	lw	a4,-36(s0)
    8000560c:	01e70793          	addi	a5,a4,30
    80005610:	078e                	slli	a5,a5,0x3
    80005612:	953e                	add	a0,a0,a5
    80005614:	611c                	ld	a5,0(a0)
    80005616:	c395                	beqz	a5,8000563a <argfd+0x64>
    return -1;
  if(pfd)
    80005618:	00090463          	beqz	s2,80005620 <argfd+0x4a>
    *pfd = fd;
    8000561c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005620:	4501                	li	a0,0
  if(pf)
    80005622:	c091                	beqz	s1,80005626 <argfd+0x50>
    *pf = f;
    80005624:	e09c                	sd	a5,0(s1)
}
    80005626:	70a2                	ld	ra,40(sp)
    80005628:	7402                	ld	s0,32(sp)
    8000562a:	64e2                	ld	s1,24(sp)
    8000562c:	6942                	ld	s2,16(sp)
    8000562e:	6145                	addi	sp,sp,48
    80005630:	8082                	ret
    return -1;
    80005632:	557d                	li	a0,-1
    80005634:	bfcd                	j	80005626 <argfd+0x50>
    return -1;
    80005636:	557d                	li	a0,-1
    80005638:	b7fd                	j	80005626 <argfd+0x50>
    8000563a:	557d                	li	a0,-1
    8000563c:	b7ed                	j	80005626 <argfd+0x50>

000000008000563e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000563e:	1101                	addi	sp,sp,-32
    80005640:	ec06                	sd	ra,24(sp)
    80005642:	e822                	sd	s0,16(sp)
    80005644:	e426                	sd	s1,8(sp)
    80005646:	1000                	addi	s0,sp,32
    80005648:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000564a:	ffffd097          	auipc	ra,0xffffd
    8000564e:	81e080e7          	jalr	-2018(ra) # 80001e68 <myproc>
    80005652:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005654:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    80005658:	4501                	li	a0,0
    8000565a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000565c:	6398                	ld	a4,0(a5)
    8000565e:	cb19                	beqz	a4,80005674 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005660:	2505                	addiw	a0,a0,1
    80005662:	07a1                	addi	a5,a5,8
    80005664:	fed51ce3          	bne	a0,a3,8000565c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005668:	557d                	li	a0,-1
}
    8000566a:	60e2                	ld	ra,24(sp)
    8000566c:	6442                	ld	s0,16(sp)
    8000566e:	64a2                	ld	s1,8(sp)
    80005670:	6105                	addi	sp,sp,32
    80005672:	8082                	ret
      p->ofile[fd] = f;
    80005674:	01e50793          	addi	a5,a0,30
    80005678:	078e                	slli	a5,a5,0x3
    8000567a:	963e                	add	a2,a2,a5
    8000567c:	e204                	sd	s1,0(a2)
      return fd;
    8000567e:	b7f5                	j	8000566a <fdalloc+0x2c>

0000000080005680 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005680:	715d                	addi	sp,sp,-80
    80005682:	e486                	sd	ra,72(sp)
    80005684:	e0a2                	sd	s0,64(sp)
    80005686:	fc26                	sd	s1,56(sp)
    80005688:	f84a                	sd	s2,48(sp)
    8000568a:	f44e                	sd	s3,40(sp)
    8000568c:	f052                	sd	s4,32(sp)
    8000568e:	ec56                	sd	s5,24(sp)
    80005690:	0880                	addi	s0,sp,80
    80005692:	89ae                	mv	s3,a1
    80005694:	8ab2                	mv	s5,a2
    80005696:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005698:	fb040593          	addi	a1,s0,-80
    8000569c:	fffff097          	auipc	ra,0xfffff
    800056a0:	e86080e7          	jalr	-378(ra) # 80004522 <nameiparent>
    800056a4:	892a                	mv	s2,a0
    800056a6:	12050f63          	beqz	a0,800057e4 <create+0x164>
    return 0;

  ilock(dp);
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	6a4080e7          	jalr	1700(ra) # 80003d4e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800056b2:	4601                	li	a2,0
    800056b4:	fb040593          	addi	a1,s0,-80
    800056b8:	854a                	mv	a0,s2
    800056ba:	fffff097          	auipc	ra,0xfffff
    800056be:	b78080e7          	jalr	-1160(ra) # 80004232 <dirlookup>
    800056c2:	84aa                	mv	s1,a0
    800056c4:	c921                	beqz	a0,80005714 <create+0x94>
    iunlockput(dp);
    800056c6:	854a                	mv	a0,s2
    800056c8:	fffff097          	auipc	ra,0xfffff
    800056cc:	8e8080e7          	jalr	-1816(ra) # 80003fb0 <iunlockput>
    ilock(ip);
    800056d0:	8526                	mv	a0,s1
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	67c080e7          	jalr	1660(ra) # 80003d4e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800056da:	2981                	sext.w	s3,s3
    800056dc:	4789                	li	a5,2
    800056de:	02f99463          	bne	s3,a5,80005706 <create+0x86>
    800056e2:	0444d783          	lhu	a5,68(s1)
    800056e6:	37f9                	addiw	a5,a5,-2
    800056e8:	17c2                	slli	a5,a5,0x30
    800056ea:	93c1                	srli	a5,a5,0x30
    800056ec:	4705                	li	a4,1
    800056ee:	00f76c63          	bltu	a4,a5,80005706 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800056f2:	8526                	mv	a0,s1
    800056f4:	60a6                	ld	ra,72(sp)
    800056f6:	6406                	ld	s0,64(sp)
    800056f8:	74e2                	ld	s1,56(sp)
    800056fa:	7942                	ld	s2,48(sp)
    800056fc:	79a2                	ld	s3,40(sp)
    800056fe:	7a02                	ld	s4,32(sp)
    80005700:	6ae2                	ld	s5,24(sp)
    80005702:	6161                	addi	sp,sp,80
    80005704:	8082                	ret
    iunlockput(ip);
    80005706:	8526                	mv	a0,s1
    80005708:	fffff097          	auipc	ra,0xfffff
    8000570c:	8a8080e7          	jalr	-1880(ra) # 80003fb0 <iunlockput>
    return 0;
    80005710:	4481                	li	s1,0
    80005712:	b7c5                	j	800056f2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005714:	85ce                	mv	a1,s3
    80005716:	00092503          	lw	a0,0(s2)
    8000571a:	ffffe097          	auipc	ra,0xffffe
    8000571e:	49c080e7          	jalr	1180(ra) # 80003bb6 <ialloc>
    80005722:	84aa                	mv	s1,a0
    80005724:	c529                	beqz	a0,8000576e <create+0xee>
  ilock(ip);
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	628080e7          	jalr	1576(ra) # 80003d4e <ilock>
  ip->major = major;
    8000572e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005732:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005736:	4785                	li	a5,1
    80005738:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000573c:	8526                	mv	a0,s1
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	546080e7          	jalr	1350(ra) # 80003c84 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005746:	2981                	sext.w	s3,s3
    80005748:	4785                	li	a5,1
    8000574a:	02f98a63          	beq	s3,a5,8000577e <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000574e:	40d0                	lw	a2,4(s1)
    80005750:	fb040593          	addi	a1,s0,-80
    80005754:	854a                	mv	a0,s2
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	cec080e7          	jalr	-788(ra) # 80004442 <dirlink>
    8000575e:	06054b63          	bltz	a0,800057d4 <create+0x154>
  iunlockput(dp);
    80005762:	854a                	mv	a0,s2
    80005764:	fffff097          	auipc	ra,0xfffff
    80005768:	84c080e7          	jalr	-1972(ra) # 80003fb0 <iunlockput>
  return ip;
    8000576c:	b759                	j	800056f2 <create+0x72>
    panic("create: ialloc");
    8000576e:	00003517          	auipc	a0,0x3
    80005772:	fd250513          	addi	a0,a0,-46 # 80008740 <syscalls+0x2b0>
    80005776:	ffffb097          	auipc	ra,0xffffb
    8000577a:	dc8080e7          	jalr	-568(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000577e:	04a95783          	lhu	a5,74(s2)
    80005782:	2785                	addiw	a5,a5,1
    80005784:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005788:	854a                	mv	a0,s2
    8000578a:	ffffe097          	auipc	ra,0xffffe
    8000578e:	4fa080e7          	jalr	1274(ra) # 80003c84 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005792:	40d0                	lw	a2,4(s1)
    80005794:	00003597          	auipc	a1,0x3
    80005798:	fbc58593          	addi	a1,a1,-68 # 80008750 <syscalls+0x2c0>
    8000579c:	8526                	mv	a0,s1
    8000579e:	fffff097          	auipc	ra,0xfffff
    800057a2:	ca4080e7          	jalr	-860(ra) # 80004442 <dirlink>
    800057a6:	00054f63          	bltz	a0,800057c4 <create+0x144>
    800057aa:	00492603          	lw	a2,4(s2)
    800057ae:	00003597          	auipc	a1,0x3
    800057b2:	faa58593          	addi	a1,a1,-86 # 80008758 <syscalls+0x2c8>
    800057b6:	8526                	mv	a0,s1
    800057b8:	fffff097          	auipc	ra,0xfffff
    800057bc:	c8a080e7          	jalr	-886(ra) # 80004442 <dirlink>
    800057c0:	f80557e3          	bgez	a0,8000574e <create+0xce>
      panic("create dots");
    800057c4:	00003517          	auipc	a0,0x3
    800057c8:	f9c50513          	addi	a0,a0,-100 # 80008760 <syscalls+0x2d0>
    800057cc:	ffffb097          	auipc	ra,0xffffb
    800057d0:	d72080e7          	jalr	-654(ra) # 8000053e <panic>
    panic("create: dirlink");
    800057d4:	00003517          	auipc	a0,0x3
    800057d8:	f9c50513          	addi	a0,a0,-100 # 80008770 <syscalls+0x2e0>
    800057dc:	ffffb097          	auipc	ra,0xffffb
    800057e0:	d62080e7          	jalr	-670(ra) # 8000053e <panic>
    return 0;
    800057e4:	84aa                	mv	s1,a0
    800057e6:	b731                	j	800056f2 <create+0x72>

00000000800057e8 <sys_dup>:
{
    800057e8:	7179                	addi	sp,sp,-48
    800057ea:	f406                	sd	ra,40(sp)
    800057ec:	f022                	sd	s0,32(sp)
    800057ee:	ec26                	sd	s1,24(sp)
    800057f0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800057f2:	fd840613          	addi	a2,s0,-40
    800057f6:	4581                	li	a1,0
    800057f8:	4501                	li	a0,0
    800057fa:	00000097          	auipc	ra,0x0
    800057fe:	ddc080e7          	jalr	-548(ra) # 800055d6 <argfd>
    return -1;
    80005802:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005804:	02054363          	bltz	a0,8000582a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005808:	fd843503          	ld	a0,-40(s0)
    8000580c:	00000097          	auipc	ra,0x0
    80005810:	e32080e7          	jalr	-462(ra) # 8000563e <fdalloc>
    80005814:	84aa                	mv	s1,a0
    return -1;
    80005816:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005818:	00054963          	bltz	a0,8000582a <sys_dup+0x42>
  filedup(f);
    8000581c:	fd843503          	ld	a0,-40(s0)
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	37a080e7          	jalr	890(ra) # 80004b9a <filedup>
  return fd;
    80005828:	87a6                	mv	a5,s1
}
    8000582a:	853e                	mv	a0,a5
    8000582c:	70a2                	ld	ra,40(sp)
    8000582e:	7402                	ld	s0,32(sp)
    80005830:	64e2                	ld	s1,24(sp)
    80005832:	6145                	addi	sp,sp,48
    80005834:	8082                	ret

0000000080005836 <sys_read>:
{
    80005836:	7179                	addi	sp,sp,-48
    80005838:	f406                	sd	ra,40(sp)
    8000583a:	f022                	sd	s0,32(sp)
    8000583c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000583e:	fe840613          	addi	a2,s0,-24
    80005842:	4581                	li	a1,0
    80005844:	4501                	li	a0,0
    80005846:	00000097          	auipc	ra,0x0
    8000584a:	d90080e7          	jalr	-624(ra) # 800055d6 <argfd>
    return -1;
    8000584e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005850:	04054163          	bltz	a0,80005892 <sys_read+0x5c>
    80005854:	fe440593          	addi	a1,s0,-28
    80005858:	4509                	li	a0,2
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	938080e7          	jalr	-1736(ra) # 80003192 <argint>
    return -1;
    80005862:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005864:	02054763          	bltz	a0,80005892 <sys_read+0x5c>
    80005868:	fd840593          	addi	a1,s0,-40
    8000586c:	4505                	li	a0,1
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	946080e7          	jalr	-1722(ra) # 800031b4 <argaddr>
    return -1;
    80005876:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005878:	00054d63          	bltz	a0,80005892 <sys_read+0x5c>
  return fileread(f, p, n);
    8000587c:	fe442603          	lw	a2,-28(s0)
    80005880:	fd843583          	ld	a1,-40(s0)
    80005884:	fe843503          	ld	a0,-24(s0)
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	49e080e7          	jalr	1182(ra) # 80004d26 <fileread>
    80005890:	87aa                	mv	a5,a0
}
    80005892:	853e                	mv	a0,a5
    80005894:	70a2                	ld	ra,40(sp)
    80005896:	7402                	ld	s0,32(sp)
    80005898:	6145                	addi	sp,sp,48
    8000589a:	8082                	ret

000000008000589c <sys_write>:
{
    8000589c:	7179                	addi	sp,sp,-48
    8000589e:	f406                	sd	ra,40(sp)
    800058a0:	f022                	sd	s0,32(sp)
    800058a2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058a4:	fe840613          	addi	a2,s0,-24
    800058a8:	4581                	li	a1,0
    800058aa:	4501                	li	a0,0
    800058ac:	00000097          	auipc	ra,0x0
    800058b0:	d2a080e7          	jalr	-726(ra) # 800055d6 <argfd>
    return -1;
    800058b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058b6:	04054163          	bltz	a0,800058f8 <sys_write+0x5c>
    800058ba:	fe440593          	addi	a1,s0,-28
    800058be:	4509                	li	a0,2
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	8d2080e7          	jalr	-1838(ra) # 80003192 <argint>
    return -1;
    800058c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058ca:	02054763          	bltz	a0,800058f8 <sys_write+0x5c>
    800058ce:	fd840593          	addi	a1,s0,-40
    800058d2:	4505                	li	a0,1
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	8e0080e7          	jalr	-1824(ra) # 800031b4 <argaddr>
    return -1;
    800058dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058de:	00054d63          	bltz	a0,800058f8 <sys_write+0x5c>
  return filewrite(f, p, n);
    800058e2:	fe442603          	lw	a2,-28(s0)
    800058e6:	fd843583          	ld	a1,-40(s0)
    800058ea:	fe843503          	ld	a0,-24(s0)
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	4fa080e7          	jalr	1274(ra) # 80004de8 <filewrite>
    800058f6:	87aa                	mv	a5,a0
}
    800058f8:	853e                	mv	a0,a5
    800058fa:	70a2                	ld	ra,40(sp)
    800058fc:	7402                	ld	s0,32(sp)
    800058fe:	6145                	addi	sp,sp,48
    80005900:	8082                	ret

0000000080005902 <sys_close>:
{
    80005902:	1101                	addi	sp,sp,-32
    80005904:	ec06                	sd	ra,24(sp)
    80005906:	e822                	sd	s0,16(sp)
    80005908:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000590a:	fe040613          	addi	a2,s0,-32
    8000590e:	fec40593          	addi	a1,s0,-20
    80005912:	4501                	li	a0,0
    80005914:	00000097          	auipc	ra,0x0
    80005918:	cc2080e7          	jalr	-830(ra) # 800055d6 <argfd>
    return -1;
    8000591c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000591e:	02054463          	bltz	a0,80005946 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005922:	ffffc097          	auipc	ra,0xffffc
    80005926:	546080e7          	jalr	1350(ra) # 80001e68 <myproc>
    8000592a:	fec42783          	lw	a5,-20(s0)
    8000592e:	07f9                	addi	a5,a5,30
    80005930:	078e                	slli	a5,a5,0x3
    80005932:	97aa                	add	a5,a5,a0
    80005934:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005938:	fe043503          	ld	a0,-32(s0)
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	2b0080e7          	jalr	688(ra) # 80004bec <fileclose>
  return 0;
    80005944:	4781                	li	a5,0
}
    80005946:	853e                	mv	a0,a5
    80005948:	60e2                	ld	ra,24(sp)
    8000594a:	6442                	ld	s0,16(sp)
    8000594c:	6105                	addi	sp,sp,32
    8000594e:	8082                	ret

0000000080005950 <sys_fstat>:
{
    80005950:	1101                	addi	sp,sp,-32
    80005952:	ec06                	sd	ra,24(sp)
    80005954:	e822                	sd	s0,16(sp)
    80005956:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005958:	fe840613          	addi	a2,s0,-24
    8000595c:	4581                	li	a1,0
    8000595e:	4501                	li	a0,0
    80005960:	00000097          	auipc	ra,0x0
    80005964:	c76080e7          	jalr	-906(ra) # 800055d6 <argfd>
    return -1;
    80005968:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000596a:	02054563          	bltz	a0,80005994 <sys_fstat+0x44>
    8000596e:	fe040593          	addi	a1,s0,-32
    80005972:	4505                	li	a0,1
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	840080e7          	jalr	-1984(ra) # 800031b4 <argaddr>
    return -1;
    8000597c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000597e:	00054b63          	bltz	a0,80005994 <sys_fstat+0x44>
  return filestat(f, st);
    80005982:	fe043583          	ld	a1,-32(s0)
    80005986:	fe843503          	ld	a0,-24(s0)
    8000598a:	fffff097          	auipc	ra,0xfffff
    8000598e:	32a080e7          	jalr	810(ra) # 80004cb4 <filestat>
    80005992:	87aa                	mv	a5,a0
}
    80005994:	853e                	mv	a0,a5
    80005996:	60e2                	ld	ra,24(sp)
    80005998:	6442                	ld	s0,16(sp)
    8000599a:	6105                	addi	sp,sp,32
    8000599c:	8082                	ret

000000008000599e <sys_link>:
{
    8000599e:	7169                	addi	sp,sp,-304
    800059a0:	f606                	sd	ra,296(sp)
    800059a2:	f222                	sd	s0,288(sp)
    800059a4:	ee26                	sd	s1,280(sp)
    800059a6:	ea4a                	sd	s2,272(sp)
    800059a8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059aa:	08000613          	li	a2,128
    800059ae:	ed040593          	addi	a1,s0,-304
    800059b2:	4501                	li	a0,0
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	822080e7          	jalr	-2014(ra) # 800031d6 <argstr>
    return -1;
    800059bc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059be:	10054e63          	bltz	a0,80005ada <sys_link+0x13c>
    800059c2:	08000613          	li	a2,128
    800059c6:	f5040593          	addi	a1,s0,-176
    800059ca:	4505                	li	a0,1
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	80a080e7          	jalr	-2038(ra) # 800031d6 <argstr>
    return -1;
    800059d4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059d6:	10054263          	bltz	a0,80005ada <sys_link+0x13c>
  begin_op();
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	d46080e7          	jalr	-698(ra) # 80004720 <begin_op>
  if((ip = namei(old)) == 0){
    800059e2:	ed040513          	addi	a0,s0,-304
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	b1e080e7          	jalr	-1250(ra) # 80004504 <namei>
    800059ee:	84aa                	mv	s1,a0
    800059f0:	c551                	beqz	a0,80005a7c <sys_link+0xde>
  ilock(ip);
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	35c080e7          	jalr	860(ra) # 80003d4e <ilock>
  if(ip->type == T_DIR){
    800059fa:	04449703          	lh	a4,68(s1)
    800059fe:	4785                	li	a5,1
    80005a00:	08f70463          	beq	a4,a5,80005a88 <sys_link+0xea>
  ip->nlink++;
    80005a04:	04a4d783          	lhu	a5,74(s1)
    80005a08:	2785                	addiw	a5,a5,1
    80005a0a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a0e:	8526                	mv	a0,s1
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	274080e7          	jalr	628(ra) # 80003c84 <iupdate>
  iunlock(ip);
    80005a18:	8526                	mv	a0,s1
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	3f6080e7          	jalr	1014(ra) # 80003e10 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a22:	fd040593          	addi	a1,s0,-48
    80005a26:	f5040513          	addi	a0,s0,-176
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	af8080e7          	jalr	-1288(ra) # 80004522 <nameiparent>
    80005a32:	892a                	mv	s2,a0
    80005a34:	c935                	beqz	a0,80005aa8 <sys_link+0x10a>
  ilock(dp);
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	318080e7          	jalr	792(ra) # 80003d4e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a3e:	00092703          	lw	a4,0(s2)
    80005a42:	409c                	lw	a5,0(s1)
    80005a44:	04f71d63          	bne	a4,a5,80005a9e <sys_link+0x100>
    80005a48:	40d0                	lw	a2,4(s1)
    80005a4a:	fd040593          	addi	a1,s0,-48
    80005a4e:	854a                	mv	a0,s2
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	9f2080e7          	jalr	-1550(ra) # 80004442 <dirlink>
    80005a58:	04054363          	bltz	a0,80005a9e <sys_link+0x100>
  iunlockput(dp);
    80005a5c:	854a                	mv	a0,s2
    80005a5e:	ffffe097          	auipc	ra,0xffffe
    80005a62:	552080e7          	jalr	1362(ra) # 80003fb0 <iunlockput>
  iput(ip);
    80005a66:	8526                	mv	a0,s1
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	4a0080e7          	jalr	1184(ra) # 80003f08 <iput>
  end_op();
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	d30080e7          	jalr	-720(ra) # 800047a0 <end_op>
  return 0;
    80005a78:	4781                	li	a5,0
    80005a7a:	a085                	j	80005ada <sys_link+0x13c>
    end_op();
    80005a7c:	fffff097          	auipc	ra,0xfffff
    80005a80:	d24080e7          	jalr	-732(ra) # 800047a0 <end_op>
    return -1;
    80005a84:	57fd                	li	a5,-1
    80005a86:	a891                	j	80005ada <sys_link+0x13c>
    iunlockput(ip);
    80005a88:	8526                	mv	a0,s1
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	526080e7          	jalr	1318(ra) # 80003fb0 <iunlockput>
    end_op();
    80005a92:	fffff097          	auipc	ra,0xfffff
    80005a96:	d0e080e7          	jalr	-754(ra) # 800047a0 <end_op>
    return -1;
    80005a9a:	57fd                	li	a5,-1
    80005a9c:	a83d                	j	80005ada <sys_link+0x13c>
    iunlockput(dp);
    80005a9e:	854a                	mv	a0,s2
    80005aa0:	ffffe097          	auipc	ra,0xffffe
    80005aa4:	510080e7          	jalr	1296(ra) # 80003fb0 <iunlockput>
  ilock(ip);
    80005aa8:	8526                	mv	a0,s1
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	2a4080e7          	jalr	676(ra) # 80003d4e <ilock>
  ip->nlink--;
    80005ab2:	04a4d783          	lhu	a5,74(s1)
    80005ab6:	37fd                	addiw	a5,a5,-1
    80005ab8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005abc:	8526                	mv	a0,s1
    80005abe:	ffffe097          	auipc	ra,0xffffe
    80005ac2:	1c6080e7          	jalr	454(ra) # 80003c84 <iupdate>
  iunlockput(ip);
    80005ac6:	8526                	mv	a0,s1
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	4e8080e7          	jalr	1256(ra) # 80003fb0 <iunlockput>
  end_op();
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	cd0080e7          	jalr	-816(ra) # 800047a0 <end_op>
  return -1;
    80005ad8:	57fd                	li	a5,-1
}
    80005ada:	853e                	mv	a0,a5
    80005adc:	70b2                	ld	ra,296(sp)
    80005ade:	7412                	ld	s0,288(sp)
    80005ae0:	64f2                	ld	s1,280(sp)
    80005ae2:	6952                	ld	s2,272(sp)
    80005ae4:	6155                	addi	sp,sp,304
    80005ae6:	8082                	ret

0000000080005ae8 <sys_unlink>:
{
    80005ae8:	7151                	addi	sp,sp,-240
    80005aea:	f586                	sd	ra,232(sp)
    80005aec:	f1a2                	sd	s0,224(sp)
    80005aee:	eda6                	sd	s1,216(sp)
    80005af0:	e9ca                	sd	s2,208(sp)
    80005af2:	e5ce                	sd	s3,200(sp)
    80005af4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005af6:	08000613          	li	a2,128
    80005afa:	f3040593          	addi	a1,s0,-208
    80005afe:	4501                	li	a0,0
    80005b00:	ffffd097          	auipc	ra,0xffffd
    80005b04:	6d6080e7          	jalr	1750(ra) # 800031d6 <argstr>
    80005b08:	18054163          	bltz	a0,80005c8a <sys_unlink+0x1a2>
  begin_op();
    80005b0c:	fffff097          	auipc	ra,0xfffff
    80005b10:	c14080e7          	jalr	-1004(ra) # 80004720 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b14:	fb040593          	addi	a1,s0,-80
    80005b18:	f3040513          	addi	a0,s0,-208
    80005b1c:	fffff097          	auipc	ra,0xfffff
    80005b20:	a06080e7          	jalr	-1530(ra) # 80004522 <nameiparent>
    80005b24:	84aa                	mv	s1,a0
    80005b26:	c979                	beqz	a0,80005bfc <sys_unlink+0x114>
  ilock(dp);
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	226080e7          	jalr	550(ra) # 80003d4e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b30:	00003597          	auipc	a1,0x3
    80005b34:	c2058593          	addi	a1,a1,-992 # 80008750 <syscalls+0x2c0>
    80005b38:	fb040513          	addi	a0,s0,-80
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	6dc080e7          	jalr	1756(ra) # 80004218 <namecmp>
    80005b44:	14050a63          	beqz	a0,80005c98 <sys_unlink+0x1b0>
    80005b48:	00003597          	auipc	a1,0x3
    80005b4c:	c1058593          	addi	a1,a1,-1008 # 80008758 <syscalls+0x2c8>
    80005b50:	fb040513          	addi	a0,s0,-80
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	6c4080e7          	jalr	1732(ra) # 80004218 <namecmp>
    80005b5c:	12050e63          	beqz	a0,80005c98 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b60:	f2c40613          	addi	a2,s0,-212
    80005b64:	fb040593          	addi	a1,s0,-80
    80005b68:	8526                	mv	a0,s1
    80005b6a:	ffffe097          	auipc	ra,0xffffe
    80005b6e:	6c8080e7          	jalr	1736(ra) # 80004232 <dirlookup>
    80005b72:	892a                	mv	s2,a0
    80005b74:	12050263          	beqz	a0,80005c98 <sys_unlink+0x1b0>
  ilock(ip);
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	1d6080e7          	jalr	470(ra) # 80003d4e <ilock>
  if(ip->nlink < 1)
    80005b80:	04a91783          	lh	a5,74(s2)
    80005b84:	08f05263          	blez	a5,80005c08 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b88:	04491703          	lh	a4,68(s2)
    80005b8c:	4785                	li	a5,1
    80005b8e:	08f70563          	beq	a4,a5,80005c18 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b92:	4641                	li	a2,16
    80005b94:	4581                	li	a1,0
    80005b96:	fc040513          	addi	a0,s0,-64
    80005b9a:	ffffb097          	auipc	ra,0xffffb
    80005b9e:	16a080e7          	jalr	362(ra) # 80000d04 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ba2:	4741                	li	a4,16
    80005ba4:	f2c42683          	lw	a3,-212(s0)
    80005ba8:	fc040613          	addi	a2,s0,-64
    80005bac:	4581                	li	a1,0
    80005bae:	8526                	mv	a0,s1
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	54a080e7          	jalr	1354(ra) # 800040fa <writei>
    80005bb8:	47c1                	li	a5,16
    80005bba:	0af51563          	bne	a0,a5,80005c64 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005bbe:	04491703          	lh	a4,68(s2)
    80005bc2:	4785                	li	a5,1
    80005bc4:	0af70863          	beq	a4,a5,80005c74 <sys_unlink+0x18c>
  iunlockput(dp);
    80005bc8:	8526                	mv	a0,s1
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	3e6080e7          	jalr	998(ra) # 80003fb0 <iunlockput>
  ip->nlink--;
    80005bd2:	04a95783          	lhu	a5,74(s2)
    80005bd6:	37fd                	addiw	a5,a5,-1
    80005bd8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005bdc:	854a                	mv	a0,s2
    80005bde:	ffffe097          	auipc	ra,0xffffe
    80005be2:	0a6080e7          	jalr	166(ra) # 80003c84 <iupdate>
  iunlockput(ip);
    80005be6:	854a                	mv	a0,s2
    80005be8:	ffffe097          	auipc	ra,0xffffe
    80005bec:	3c8080e7          	jalr	968(ra) # 80003fb0 <iunlockput>
  end_op();
    80005bf0:	fffff097          	auipc	ra,0xfffff
    80005bf4:	bb0080e7          	jalr	-1104(ra) # 800047a0 <end_op>
  return 0;
    80005bf8:	4501                	li	a0,0
    80005bfa:	a84d                	j	80005cac <sys_unlink+0x1c4>
    end_op();
    80005bfc:	fffff097          	auipc	ra,0xfffff
    80005c00:	ba4080e7          	jalr	-1116(ra) # 800047a0 <end_op>
    return -1;
    80005c04:	557d                	li	a0,-1
    80005c06:	a05d                	j	80005cac <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c08:	00003517          	auipc	a0,0x3
    80005c0c:	b7850513          	addi	a0,a0,-1160 # 80008780 <syscalls+0x2f0>
    80005c10:	ffffb097          	auipc	ra,0xffffb
    80005c14:	92e080e7          	jalr	-1746(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c18:	04c92703          	lw	a4,76(s2)
    80005c1c:	02000793          	li	a5,32
    80005c20:	f6e7f9e3          	bgeu	a5,a4,80005b92 <sys_unlink+0xaa>
    80005c24:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c28:	4741                	li	a4,16
    80005c2a:	86ce                	mv	a3,s3
    80005c2c:	f1840613          	addi	a2,s0,-232
    80005c30:	4581                	li	a1,0
    80005c32:	854a                	mv	a0,s2
    80005c34:	ffffe097          	auipc	ra,0xffffe
    80005c38:	3ce080e7          	jalr	974(ra) # 80004002 <readi>
    80005c3c:	47c1                	li	a5,16
    80005c3e:	00f51b63          	bne	a0,a5,80005c54 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c42:	f1845783          	lhu	a5,-232(s0)
    80005c46:	e7a1                	bnez	a5,80005c8e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c48:	29c1                	addiw	s3,s3,16
    80005c4a:	04c92783          	lw	a5,76(s2)
    80005c4e:	fcf9ede3          	bltu	s3,a5,80005c28 <sys_unlink+0x140>
    80005c52:	b781                	j	80005b92 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c54:	00003517          	auipc	a0,0x3
    80005c58:	b4450513          	addi	a0,a0,-1212 # 80008798 <syscalls+0x308>
    80005c5c:	ffffb097          	auipc	ra,0xffffb
    80005c60:	8e2080e7          	jalr	-1822(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005c64:	00003517          	auipc	a0,0x3
    80005c68:	b4c50513          	addi	a0,a0,-1204 # 800087b0 <syscalls+0x320>
    80005c6c:	ffffb097          	auipc	ra,0xffffb
    80005c70:	8d2080e7          	jalr	-1838(ra) # 8000053e <panic>
    dp->nlink--;
    80005c74:	04a4d783          	lhu	a5,74(s1)
    80005c78:	37fd                	addiw	a5,a5,-1
    80005c7a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c7e:	8526                	mv	a0,s1
    80005c80:	ffffe097          	auipc	ra,0xffffe
    80005c84:	004080e7          	jalr	4(ra) # 80003c84 <iupdate>
    80005c88:	b781                	j	80005bc8 <sys_unlink+0xe0>
    return -1;
    80005c8a:	557d                	li	a0,-1
    80005c8c:	a005                	j	80005cac <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c8e:	854a                	mv	a0,s2
    80005c90:	ffffe097          	auipc	ra,0xffffe
    80005c94:	320080e7          	jalr	800(ra) # 80003fb0 <iunlockput>
  iunlockput(dp);
    80005c98:	8526                	mv	a0,s1
    80005c9a:	ffffe097          	auipc	ra,0xffffe
    80005c9e:	316080e7          	jalr	790(ra) # 80003fb0 <iunlockput>
  end_op();
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	afe080e7          	jalr	-1282(ra) # 800047a0 <end_op>
  return -1;
    80005caa:	557d                	li	a0,-1
}
    80005cac:	70ae                	ld	ra,232(sp)
    80005cae:	740e                	ld	s0,224(sp)
    80005cb0:	64ee                	ld	s1,216(sp)
    80005cb2:	694e                	ld	s2,208(sp)
    80005cb4:	69ae                	ld	s3,200(sp)
    80005cb6:	616d                	addi	sp,sp,240
    80005cb8:	8082                	ret

0000000080005cba <sys_open>:

uint64
sys_open(void)
{
    80005cba:	7131                	addi	sp,sp,-192
    80005cbc:	fd06                	sd	ra,184(sp)
    80005cbe:	f922                	sd	s0,176(sp)
    80005cc0:	f526                	sd	s1,168(sp)
    80005cc2:	f14a                	sd	s2,160(sp)
    80005cc4:	ed4e                	sd	s3,152(sp)
    80005cc6:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005cc8:	08000613          	li	a2,128
    80005ccc:	f5040593          	addi	a1,s0,-176
    80005cd0:	4501                	li	a0,0
    80005cd2:	ffffd097          	auipc	ra,0xffffd
    80005cd6:	504080e7          	jalr	1284(ra) # 800031d6 <argstr>
    return -1;
    80005cda:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005cdc:	0c054163          	bltz	a0,80005d9e <sys_open+0xe4>
    80005ce0:	f4c40593          	addi	a1,s0,-180
    80005ce4:	4505                	li	a0,1
    80005ce6:	ffffd097          	auipc	ra,0xffffd
    80005cea:	4ac080e7          	jalr	1196(ra) # 80003192 <argint>
    80005cee:	0a054863          	bltz	a0,80005d9e <sys_open+0xe4>

  begin_op();
    80005cf2:	fffff097          	auipc	ra,0xfffff
    80005cf6:	a2e080e7          	jalr	-1490(ra) # 80004720 <begin_op>

  if(omode & O_CREATE){
    80005cfa:	f4c42783          	lw	a5,-180(s0)
    80005cfe:	2007f793          	andi	a5,a5,512
    80005d02:	cbdd                	beqz	a5,80005db8 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d04:	4681                	li	a3,0
    80005d06:	4601                	li	a2,0
    80005d08:	4589                	li	a1,2
    80005d0a:	f5040513          	addi	a0,s0,-176
    80005d0e:	00000097          	auipc	ra,0x0
    80005d12:	972080e7          	jalr	-1678(ra) # 80005680 <create>
    80005d16:	892a                	mv	s2,a0
    if(ip == 0){
    80005d18:	c959                	beqz	a0,80005dae <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005d1a:	04491703          	lh	a4,68(s2)
    80005d1e:	478d                	li	a5,3
    80005d20:	00f71763          	bne	a4,a5,80005d2e <sys_open+0x74>
    80005d24:	04695703          	lhu	a4,70(s2)
    80005d28:	47a5                	li	a5,9
    80005d2a:	0ce7ec63          	bltu	a5,a4,80005e02 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	e02080e7          	jalr	-510(ra) # 80004b30 <filealloc>
    80005d36:	89aa                	mv	s3,a0
    80005d38:	10050263          	beqz	a0,80005e3c <sys_open+0x182>
    80005d3c:	00000097          	auipc	ra,0x0
    80005d40:	902080e7          	jalr	-1790(ra) # 8000563e <fdalloc>
    80005d44:	84aa                	mv	s1,a0
    80005d46:	0e054663          	bltz	a0,80005e32 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d4a:	04491703          	lh	a4,68(s2)
    80005d4e:	478d                	li	a5,3
    80005d50:	0cf70463          	beq	a4,a5,80005e18 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d54:	4789                	li	a5,2
    80005d56:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d5a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d5e:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d62:	f4c42783          	lw	a5,-180(s0)
    80005d66:	0017c713          	xori	a4,a5,1
    80005d6a:	8b05                	andi	a4,a4,1
    80005d6c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d70:	0037f713          	andi	a4,a5,3
    80005d74:	00e03733          	snez	a4,a4
    80005d78:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d7c:	4007f793          	andi	a5,a5,1024
    80005d80:	c791                	beqz	a5,80005d8c <sys_open+0xd2>
    80005d82:	04491703          	lh	a4,68(s2)
    80005d86:	4789                	li	a5,2
    80005d88:	08f70f63          	beq	a4,a5,80005e26 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d8c:	854a                	mv	a0,s2
    80005d8e:	ffffe097          	auipc	ra,0xffffe
    80005d92:	082080e7          	jalr	130(ra) # 80003e10 <iunlock>
  end_op();
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	a0a080e7          	jalr	-1526(ra) # 800047a0 <end_op>

  return fd;
}
    80005d9e:	8526                	mv	a0,s1
    80005da0:	70ea                	ld	ra,184(sp)
    80005da2:	744a                	ld	s0,176(sp)
    80005da4:	74aa                	ld	s1,168(sp)
    80005da6:	790a                	ld	s2,160(sp)
    80005da8:	69ea                	ld	s3,152(sp)
    80005daa:	6129                	addi	sp,sp,192
    80005dac:	8082                	ret
      end_op();
    80005dae:	fffff097          	auipc	ra,0xfffff
    80005db2:	9f2080e7          	jalr	-1550(ra) # 800047a0 <end_op>
      return -1;
    80005db6:	b7e5                	j	80005d9e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005db8:	f5040513          	addi	a0,s0,-176
    80005dbc:	ffffe097          	auipc	ra,0xffffe
    80005dc0:	748080e7          	jalr	1864(ra) # 80004504 <namei>
    80005dc4:	892a                	mv	s2,a0
    80005dc6:	c905                	beqz	a0,80005df6 <sys_open+0x13c>
    ilock(ip);
    80005dc8:	ffffe097          	auipc	ra,0xffffe
    80005dcc:	f86080e7          	jalr	-122(ra) # 80003d4e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005dd0:	04491703          	lh	a4,68(s2)
    80005dd4:	4785                	li	a5,1
    80005dd6:	f4f712e3          	bne	a4,a5,80005d1a <sys_open+0x60>
    80005dda:	f4c42783          	lw	a5,-180(s0)
    80005dde:	dba1                	beqz	a5,80005d2e <sys_open+0x74>
      iunlockput(ip);
    80005de0:	854a                	mv	a0,s2
    80005de2:	ffffe097          	auipc	ra,0xffffe
    80005de6:	1ce080e7          	jalr	462(ra) # 80003fb0 <iunlockput>
      end_op();
    80005dea:	fffff097          	auipc	ra,0xfffff
    80005dee:	9b6080e7          	jalr	-1610(ra) # 800047a0 <end_op>
      return -1;
    80005df2:	54fd                	li	s1,-1
    80005df4:	b76d                	j	80005d9e <sys_open+0xe4>
      end_op();
    80005df6:	fffff097          	auipc	ra,0xfffff
    80005dfa:	9aa080e7          	jalr	-1622(ra) # 800047a0 <end_op>
      return -1;
    80005dfe:	54fd                	li	s1,-1
    80005e00:	bf79                	j	80005d9e <sys_open+0xe4>
    iunlockput(ip);
    80005e02:	854a                	mv	a0,s2
    80005e04:	ffffe097          	auipc	ra,0xffffe
    80005e08:	1ac080e7          	jalr	428(ra) # 80003fb0 <iunlockput>
    end_op();
    80005e0c:	fffff097          	auipc	ra,0xfffff
    80005e10:	994080e7          	jalr	-1644(ra) # 800047a0 <end_op>
    return -1;
    80005e14:	54fd                	li	s1,-1
    80005e16:	b761                	j	80005d9e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005e18:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005e1c:	04691783          	lh	a5,70(s2)
    80005e20:	02f99223          	sh	a5,36(s3)
    80005e24:	bf2d                	j	80005d5e <sys_open+0xa4>
    itrunc(ip);
    80005e26:	854a                	mv	a0,s2
    80005e28:	ffffe097          	auipc	ra,0xffffe
    80005e2c:	034080e7          	jalr	52(ra) # 80003e5c <itrunc>
    80005e30:	bfb1                	j	80005d8c <sys_open+0xd2>
      fileclose(f);
    80005e32:	854e                	mv	a0,s3
    80005e34:	fffff097          	auipc	ra,0xfffff
    80005e38:	db8080e7          	jalr	-584(ra) # 80004bec <fileclose>
    iunlockput(ip);
    80005e3c:	854a                	mv	a0,s2
    80005e3e:	ffffe097          	auipc	ra,0xffffe
    80005e42:	172080e7          	jalr	370(ra) # 80003fb0 <iunlockput>
    end_op();
    80005e46:	fffff097          	auipc	ra,0xfffff
    80005e4a:	95a080e7          	jalr	-1702(ra) # 800047a0 <end_op>
    return -1;
    80005e4e:	54fd                	li	s1,-1
    80005e50:	b7b9                	j	80005d9e <sys_open+0xe4>

0000000080005e52 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e52:	7175                	addi	sp,sp,-144
    80005e54:	e506                	sd	ra,136(sp)
    80005e56:	e122                	sd	s0,128(sp)
    80005e58:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e5a:	fffff097          	auipc	ra,0xfffff
    80005e5e:	8c6080e7          	jalr	-1850(ra) # 80004720 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e62:	08000613          	li	a2,128
    80005e66:	f7040593          	addi	a1,s0,-144
    80005e6a:	4501                	li	a0,0
    80005e6c:	ffffd097          	auipc	ra,0xffffd
    80005e70:	36a080e7          	jalr	874(ra) # 800031d6 <argstr>
    80005e74:	02054963          	bltz	a0,80005ea6 <sys_mkdir+0x54>
    80005e78:	4681                	li	a3,0
    80005e7a:	4601                	li	a2,0
    80005e7c:	4585                	li	a1,1
    80005e7e:	f7040513          	addi	a0,s0,-144
    80005e82:	fffff097          	auipc	ra,0xfffff
    80005e86:	7fe080e7          	jalr	2046(ra) # 80005680 <create>
    80005e8a:	cd11                	beqz	a0,80005ea6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e8c:	ffffe097          	auipc	ra,0xffffe
    80005e90:	124080e7          	jalr	292(ra) # 80003fb0 <iunlockput>
  end_op();
    80005e94:	fffff097          	auipc	ra,0xfffff
    80005e98:	90c080e7          	jalr	-1780(ra) # 800047a0 <end_op>
  return 0;
    80005e9c:	4501                	li	a0,0
}
    80005e9e:	60aa                	ld	ra,136(sp)
    80005ea0:	640a                	ld	s0,128(sp)
    80005ea2:	6149                	addi	sp,sp,144
    80005ea4:	8082                	ret
    end_op();
    80005ea6:	fffff097          	auipc	ra,0xfffff
    80005eaa:	8fa080e7          	jalr	-1798(ra) # 800047a0 <end_op>
    return -1;
    80005eae:	557d                	li	a0,-1
    80005eb0:	b7fd                	j	80005e9e <sys_mkdir+0x4c>

0000000080005eb2 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005eb2:	7135                	addi	sp,sp,-160
    80005eb4:	ed06                	sd	ra,152(sp)
    80005eb6:	e922                	sd	s0,144(sp)
    80005eb8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005eba:	fffff097          	auipc	ra,0xfffff
    80005ebe:	866080e7          	jalr	-1946(ra) # 80004720 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ec2:	08000613          	li	a2,128
    80005ec6:	f7040593          	addi	a1,s0,-144
    80005eca:	4501                	li	a0,0
    80005ecc:	ffffd097          	auipc	ra,0xffffd
    80005ed0:	30a080e7          	jalr	778(ra) # 800031d6 <argstr>
    80005ed4:	04054a63          	bltz	a0,80005f28 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005ed8:	f6c40593          	addi	a1,s0,-148
    80005edc:	4505                	li	a0,1
    80005ede:	ffffd097          	auipc	ra,0xffffd
    80005ee2:	2b4080e7          	jalr	692(ra) # 80003192 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ee6:	04054163          	bltz	a0,80005f28 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005eea:	f6840593          	addi	a1,s0,-152
    80005eee:	4509                	li	a0,2
    80005ef0:	ffffd097          	auipc	ra,0xffffd
    80005ef4:	2a2080e7          	jalr	674(ra) # 80003192 <argint>
     argint(1, &major) < 0 ||
    80005ef8:	02054863          	bltz	a0,80005f28 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005efc:	f6841683          	lh	a3,-152(s0)
    80005f00:	f6c41603          	lh	a2,-148(s0)
    80005f04:	458d                	li	a1,3
    80005f06:	f7040513          	addi	a0,s0,-144
    80005f0a:	fffff097          	auipc	ra,0xfffff
    80005f0e:	776080e7          	jalr	1910(ra) # 80005680 <create>
     argint(2, &minor) < 0 ||
    80005f12:	c919                	beqz	a0,80005f28 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f14:	ffffe097          	auipc	ra,0xffffe
    80005f18:	09c080e7          	jalr	156(ra) # 80003fb0 <iunlockput>
  end_op();
    80005f1c:	fffff097          	auipc	ra,0xfffff
    80005f20:	884080e7          	jalr	-1916(ra) # 800047a0 <end_op>
  return 0;
    80005f24:	4501                	li	a0,0
    80005f26:	a031                	j	80005f32 <sys_mknod+0x80>
    end_op();
    80005f28:	fffff097          	auipc	ra,0xfffff
    80005f2c:	878080e7          	jalr	-1928(ra) # 800047a0 <end_op>
    return -1;
    80005f30:	557d                	li	a0,-1
}
    80005f32:	60ea                	ld	ra,152(sp)
    80005f34:	644a                	ld	s0,144(sp)
    80005f36:	610d                	addi	sp,sp,160
    80005f38:	8082                	ret

0000000080005f3a <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f3a:	7135                	addi	sp,sp,-160
    80005f3c:	ed06                	sd	ra,152(sp)
    80005f3e:	e922                	sd	s0,144(sp)
    80005f40:	e526                	sd	s1,136(sp)
    80005f42:	e14a                	sd	s2,128(sp)
    80005f44:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f46:	ffffc097          	auipc	ra,0xffffc
    80005f4a:	f22080e7          	jalr	-222(ra) # 80001e68 <myproc>
    80005f4e:	892a                	mv	s2,a0
  
  begin_op();
    80005f50:	ffffe097          	auipc	ra,0xffffe
    80005f54:	7d0080e7          	jalr	2000(ra) # 80004720 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f58:	08000613          	li	a2,128
    80005f5c:	f6040593          	addi	a1,s0,-160
    80005f60:	4501                	li	a0,0
    80005f62:	ffffd097          	auipc	ra,0xffffd
    80005f66:	274080e7          	jalr	628(ra) # 800031d6 <argstr>
    80005f6a:	04054b63          	bltz	a0,80005fc0 <sys_chdir+0x86>
    80005f6e:	f6040513          	addi	a0,s0,-160
    80005f72:	ffffe097          	auipc	ra,0xffffe
    80005f76:	592080e7          	jalr	1426(ra) # 80004504 <namei>
    80005f7a:	84aa                	mv	s1,a0
    80005f7c:	c131                	beqz	a0,80005fc0 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f7e:	ffffe097          	auipc	ra,0xffffe
    80005f82:	dd0080e7          	jalr	-560(ra) # 80003d4e <ilock>
  if(ip->type != T_DIR){
    80005f86:	04449703          	lh	a4,68(s1)
    80005f8a:	4785                	li	a5,1
    80005f8c:	04f71063          	bne	a4,a5,80005fcc <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f90:	8526                	mv	a0,s1
    80005f92:	ffffe097          	auipc	ra,0xffffe
    80005f96:	e7e080e7          	jalr	-386(ra) # 80003e10 <iunlock>
  iput(p->cwd);
    80005f9a:	17093503          	ld	a0,368(s2)
    80005f9e:	ffffe097          	auipc	ra,0xffffe
    80005fa2:	f6a080e7          	jalr	-150(ra) # 80003f08 <iput>
  end_op();
    80005fa6:	ffffe097          	auipc	ra,0xffffe
    80005faa:	7fa080e7          	jalr	2042(ra) # 800047a0 <end_op>
  p->cwd = ip;
    80005fae:	16993823          	sd	s1,368(s2)
  return 0;
    80005fb2:	4501                	li	a0,0
}
    80005fb4:	60ea                	ld	ra,152(sp)
    80005fb6:	644a                	ld	s0,144(sp)
    80005fb8:	64aa                	ld	s1,136(sp)
    80005fba:	690a                	ld	s2,128(sp)
    80005fbc:	610d                	addi	sp,sp,160
    80005fbe:	8082                	ret
    end_op();
    80005fc0:	ffffe097          	auipc	ra,0xffffe
    80005fc4:	7e0080e7          	jalr	2016(ra) # 800047a0 <end_op>
    return -1;
    80005fc8:	557d                	li	a0,-1
    80005fca:	b7ed                	j	80005fb4 <sys_chdir+0x7a>
    iunlockput(ip);
    80005fcc:	8526                	mv	a0,s1
    80005fce:	ffffe097          	auipc	ra,0xffffe
    80005fd2:	fe2080e7          	jalr	-30(ra) # 80003fb0 <iunlockput>
    end_op();
    80005fd6:	ffffe097          	auipc	ra,0xffffe
    80005fda:	7ca080e7          	jalr	1994(ra) # 800047a0 <end_op>
    return -1;
    80005fde:	557d                	li	a0,-1
    80005fe0:	bfd1                	j	80005fb4 <sys_chdir+0x7a>

0000000080005fe2 <sys_exec>:

uint64
sys_exec(void)
{
    80005fe2:	7145                	addi	sp,sp,-464
    80005fe4:	e786                	sd	ra,456(sp)
    80005fe6:	e3a2                	sd	s0,448(sp)
    80005fe8:	ff26                	sd	s1,440(sp)
    80005fea:	fb4a                	sd	s2,432(sp)
    80005fec:	f74e                	sd	s3,424(sp)
    80005fee:	f352                	sd	s4,416(sp)
    80005ff0:	ef56                	sd	s5,408(sp)
    80005ff2:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ff4:	08000613          	li	a2,128
    80005ff8:	f4040593          	addi	a1,s0,-192
    80005ffc:	4501                	li	a0,0
    80005ffe:	ffffd097          	auipc	ra,0xffffd
    80006002:	1d8080e7          	jalr	472(ra) # 800031d6 <argstr>
    return -1;
    80006006:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006008:	0c054a63          	bltz	a0,800060dc <sys_exec+0xfa>
    8000600c:	e3840593          	addi	a1,s0,-456
    80006010:	4505                	li	a0,1
    80006012:	ffffd097          	auipc	ra,0xffffd
    80006016:	1a2080e7          	jalr	418(ra) # 800031b4 <argaddr>
    8000601a:	0c054163          	bltz	a0,800060dc <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000601e:	10000613          	li	a2,256
    80006022:	4581                	li	a1,0
    80006024:	e4040513          	addi	a0,s0,-448
    80006028:	ffffb097          	auipc	ra,0xffffb
    8000602c:	cdc080e7          	jalr	-804(ra) # 80000d04 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006030:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006034:	89a6                	mv	s3,s1
    80006036:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006038:	02000a13          	li	s4,32
    8000603c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006040:	00391513          	slli	a0,s2,0x3
    80006044:	e3040593          	addi	a1,s0,-464
    80006048:	e3843783          	ld	a5,-456(s0)
    8000604c:	953e                	add	a0,a0,a5
    8000604e:	ffffd097          	auipc	ra,0xffffd
    80006052:	0aa080e7          	jalr	170(ra) # 800030f8 <fetchaddr>
    80006056:	02054a63          	bltz	a0,8000608a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000605a:	e3043783          	ld	a5,-464(s0)
    8000605e:	c3b9                	beqz	a5,800060a4 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006060:	ffffb097          	auipc	ra,0xffffb
    80006064:	a94080e7          	jalr	-1388(ra) # 80000af4 <kalloc>
    80006068:	85aa                	mv	a1,a0
    8000606a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000606e:	cd11                	beqz	a0,8000608a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006070:	6605                	lui	a2,0x1
    80006072:	e3043503          	ld	a0,-464(s0)
    80006076:	ffffd097          	auipc	ra,0xffffd
    8000607a:	0d4080e7          	jalr	212(ra) # 8000314a <fetchstr>
    8000607e:	00054663          	bltz	a0,8000608a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006082:	0905                	addi	s2,s2,1
    80006084:	09a1                	addi	s3,s3,8
    80006086:	fb491be3          	bne	s2,s4,8000603c <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000608a:	10048913          	addi	s2,s1,256
    8000608e:	6088                	ld	a0,0(s1)
    80006090:	c529                	beqz	a0,800060da <sys_exec+0xf8>
    kfree(argv[i]);
    80006092:	ffffb097          	auipc	ra,0xffffb
    80006096:	966080e7          	jalr	-1690(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000609a:	04a1                	addi	s1,s1,8
    8000609c:	ff2499e3          	bne	s1,s2,8000608e <sys_exec+0xac>
  return -1;
    800060a0:	597d                	li	s2,-1
    800060a2:	a82d                	j	800060dc <sys_exec+0xfa>
      argv[i] = 0;
    800060a4:	0a8e                	slli	s5,s5,0x3
    800060a6:	fc040793          	addi	a5,s0,-64
    800060aa:	9abe                	add	s5,s5,a5
    800060ac:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800060b0:	e4040593          	addi	a1,s0,-448
    800060b4:	f4040513          	addi	a0,s0,-192
    800060b8:	fffff097          	auipc	ra,0xfffff
    800060bc:	194080e7          	jalr	404(ra) # 8000524c <exec>
    800060c0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060c2:	10048993          	addi	s3,s1,256
    800060c6:	6088                	ld	a0,0(s1)
    800060c8:	c911                	beqz	a0,800060dc <sys_exec+0xfa>
    kfree(argv[i]);
    800060ca:	ffffb097          	auipc	ra,0xffffb
    800060ce:	92e080e7          	jalr	-1746(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060d2:	04a1                	addi	s1,s1,8
    800060d4:	ff3499e3          	bne	s1,s3,800060c6 <sys_exec+0xe4>
    800060d8:	a011                	j	800060dc <sys_exec+0xfa>
  return -1;
    800060da:	597d                	li	s2,-1
}
    800060dc:	854a                	mv	a0,s2
    800060de:	60be                	ld	ra,456(sp)
    800060e0:	641e                	ld	s0,448(sp)
    800060e2:	74fa                	ld	s1,440(sp)
    800060e4:	795a                	ld	s2,432(sp)
    800060e6:	79ba                	ld	s3,424(sp)
    800060e8:	7a1a                	ld	s4,416(sp)
    800060ea:	6afa                	ld	s5,408(sp)
    800060ec:	6179                	addi	sp,sp,464
    800060ee:	8082                	ret

00000000800060f0 <sys_pipe>:

uint64
sys_pipe(void)
{
    800060f0:	7139                	addi	sp,sp,-64
    800060f2:	fc06                	sd	ra,56(sp)
    800060f4:	f822                	sd	s0,48(sp)
    800060f6:	f426                	sd	s1,40(sp)
    800060f8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800060fa:	ffffc097          	auipc	ra,0xffffc
    800060fe:	d6e080e7          	jalr	-658(ra) # 80001e68 <myproc>
    80006102:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006104:	fd840593          	addi	a1,s0,-40
    80006108:	4501                	li	a0,0
    8000610a:	ffffd097          	auipc	ra,0xffffd
    8000610e:	0aa080e7          	jalr	170(ra) # 800031b4 <argaddr>
    return -1;
    80006112:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006114:	0e054063          	bltz	a0,800061f4 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006118:	fc840593          	addi	a1,s0,-56
    8000611c:	fd040513          	addi	a0,s0,-48
    80006120:	fffff097          	auipc	ra,0xfffff
    80006124:	dfc080e7          	jalr	-516(ra) # 80004f1c <pipealloc>
    return -1;
    80006128:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000612a:	0c054563          	bltz	a0,800061f4 <sys_pipe+0x104>
  fd0 = -1;
    8000612e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006132:	fd043503          	ld	a0,-48(s0)
    80006136:	fffff097          	auipc	ra,0xfffff
    8000613a:	508080e7          	jalr	1288(ra) # 8000563e <fdalloc>
    8000613e:	fca42223          	sw	a0,-60(s0)
    80006142:	08054c63          	bltz	a0,800061da <sys_pipe+0xea>
    80006146:	fc843503          	ld	a0,-56(s0)
    8000614a:	fffff097          	auipc	ra,0xfffff
    8000614e:	4f4080e7          	jalr	1268(ra) # 8000563e <fdalloc>
    80006152:	fca42023          	sw	a0,-64(s0)
    80006156:	06054863          	bltz	a0,800061c6 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000615a:	4691                	li	a3,4
    8000615c:	fc440613          	addi	a2,s0,-60
    80006160:	fd843583          	ld	a1,-40(s0)
    80006164:	78a8                	ld	a0,112(s1)
    80006166:	ffffb097          	auipc	ra,0xffffb
    8000616a:	530080e7          	jalr	1328(ra) # 80001696 <copyout>
    8000616e:	02054063          	bltz	a0,8000618e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006172:	4691                	li	a3,4
    80006174:	fc040613          	addi	a2,s0,-64
    80006178:	fd843583          	ld	a1,-40(s0)
    8000617c:	0591                	addi	a1,a1,4
    8000617e:	78a8                	ld	a0,112(s1)
    80006180:	ffffb097          	auipc	ra,0xffffb
    80006184:	516080e7          	jalr	1302(ra) # 80001696 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006188:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000618a:	06055563          	bgez	a0,800061f4 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000618e:	fc442783          	lw	a5,-60(s0)
    80006192:	07f9                	addi	a5,a5,30
    80006194:	078e                	slli	a5,a5,0x3
    80006196:	97a6                	add	a5,a5,s1
    80006198:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000619c:	fc042503          	lw	a0,-64(s0)
    800061a0:	0579                	addi	a0,a0,30
    800061a2:	050e                	slli	a0,a0,0x3
    800061a4:	9526                	add	a0,a0,s1
    800061a6:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800061aa:	fd043503          	ld	a0,-48(s0)
    800061ae:	fffff097          	auipc	ra,0xfffff
    800061b2:	a3e080e7          	jalr	-1474(ra) # 80004bec <fileclose>
    fileclose(wf);
    800061b6:	fc843503          	ld	a0,-56(s0)
    800061ba:	fffff097          	auipc	ra,0xfffff
    800061be:	a32080e7          	jalr	-1486(ra) # 80004bec <fileclose>
    return -1;
    800061c2:	57fd                	li	a5,-1
    800061c4:	a805                	j	800061f4 <sys_pipe+0x104>
    if(fd0 >= 0)
    800061c6:	fc442783          	lw	a5,-60(s0)
    800061ca:	0007c863          	bltz	a5,800061da <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800061ce:	01e78513          	addi	a0,a5,30
    800061d2:	050e                	slli	a0,a0,0x3
    800061d4:	9526                	add	a0,a0,s1
    800061d6:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800061da:	fd043503          	ld	a0,-48(s0)
    800061de:	fffff097          	auipc	ra,0xfffff
    800061e2:	a0e080e7          	jalr	-1522(ra) # 80004bec <fileclose>
    fileclose(wf);
    800061e6:	fc843503          	ld	a0,-56(s0)
    800061ea:	fffff097          	auipc	ra,0xfffff
    800061ee:	a02080e7          	jalr	-1534(ra) # 80004bec <fileclose>
    return -1;
    800061f2:	57fd                	li	a5,-1
}
    800061f4:	853e                	mv	a0,a5
    800061f6:	70e2                	ld	ra,56(sp)
    800061f8:	7442                	ld	s0,48(sp)
    800061fa:	74a2                	ld	s1,40(sp)
    800061fc:	6121                	addi	sp,sp,64
    800061fe:	8082                	ret

0000000080006200 <kernelvec>:
    80006200:	7111                	addi	sp,sp,-256
    80006202:	e006                	sd	ra,0(sp)
    80006204:	e40a                	sd	sp,8(sp)
    80006206:	e80e                	sd	gp,16(sp)
    80006208:	ec12                	sd	tp,24(sp)
    8000620a:	f016                	sd	t0,32(sp)
    8000620c:	f41a                	sd	t1,40(sp)
    8000620e:	f81e                	sd	t2,48(sp)
    80006210:	fc22                	sd	s0,56(sp)
    80006212:	e0a6                	sd	s1,64(sp)
    80006214:	e4aa                	sd	a0,72(sp)
    80006216:	e8ae                	sd	a1,80(sp)
    80006218:	ecb2                	sd	a2,88(sp)
    8000621a:	f0b6                	sd	a3,96(sp)
    8000621c:	f4ba                	sd	a4,104(sp)
    8000621e:	f8be                	sd	a5,112(sp)
    80006220:	fcc2                	sd	a6,120(sp)
    80006222:	e146                	sd	a7,128(sp)
    80006224:	e54a                	sd	s2,136(sp)
    80006226:	e94e                	sd	s3,144(sp)
    80006228:	ed52                	sd	s4,152(sp)
    8000622a:	f156                	sd	s5,160(sp)
    8000622c:	f55a                	sd	s6,168(sp)
    8000622e:	f95e                	sd	s7,176(sp)
    80006230:	fd62                	sd	s8,184(sp)
    80006232:	e1e6                	sd	s9,192(sp)
    80006234:	e5ea                	sd	s10,200(sp)
    80006236:	e9ee                	sd	s11,208(sp)
    80006238:	edf2                	sd	t3,216(sp)
    8000623a:	f1f6                	sd	t4,224(sp)
    8000623c:	f5fa                	sd	t5,232(sp)
    8000623e:	f9fe                	sd	t6,240(sp)
    80006240:	d85fc0ef          	jal	ra,80002fc4 <kerneltrap>
    80006244:	6082                	ld	ra,0(sp)
    80006246:	6122                	ld	sp,8(sp)
    80006248:	61c2                	ld	gp,16(sp)
    8000624a:	7282                	ld	t0,32(sp)
    8000624c:	7322                	ld	t1,40(sp)
    8000624e:	73c2                	ld	t2,48(sp)
    80006250:	7462                	ld	s0,56(sp)
    80006252:	6486                	ld	s1,64(sp)
    80006254:	6526                	ld	a0,72(sp)
    80006256:	65c6                	ld	a1,80(sp)
    80006258:	6666                	ld	a2,88(sp)
    8000625a:	7686                	ld	a3,96(sp)
    8000625c:	7726                	ld	a4,104(sp)
    8000625e:	77c6                	ld	a5,112(sp)
    80006260:	7866                	ld	a6,120(sp)
    80006262:	688a                	ld	a7,128(sp)
    80006264:	692a                	ld	s2,136(sp)
    80006266:	69ca                	ld	s3,144(sp)
    80006268:	6a6a                	ld	s4,152(sp)
    8000626a:	7a8a                	ld	s5,160(sp)
    8000626c:	7b2a                	ld	s6,168(sp)
    8000626e:	7bca                	ld	s7,176(sp)
    80006270:	7c6a                	ld	s8,184(sp)
    80006272:	6c8e                	ld	s9,192(sp)
    80006274:	6d2e                	ld	s10,200(sp)
    80006276:	6dce                	ld	s11,208(sp)
    80006278:	6e6e                	ld	t3,216(sp)
    8000627a:	7e8e                	ld	t4,224(sp)
    8000627c:	7f2e                	ld	t5,232(sp)
    8000627e:	7fce                	ld	t6,240(sp)
    80006280:	6111                	addi	sp,sp,256
    80006282:	10200073          	sret
    80006286:	00000013          	nop
    8000628a:	00000013          	nop
    8000628e:	0001                	nop

0000000080006290 <timervec>:
    80006290:	34051573          	csrrw	a0,mscratch,a0
    80006294:	e10c                	sd	a1,0(a0)
    80006296:	e510                	sd	a2,8(a0)
    80006298:	e914                	sd	a3,16(a0)
    8000629a:	6d0c                	ld	a1,24(a0)
    8000629c:	7110                	ld	a2,32(a0)
    8000629e:	6194                	ld	a3,0(a1)
    800062a0:	96b2                	add	a3,a3,a2
    800062a2:	e194                	sd	a3,0(a1)
    800062a4:	4589                	li	a1,2
    800062a6:	14459073          	csrw	sip,a1
    800062aa:	6914                	ld	a3,16(a0)
    800062ac:	6510                	ld	a2,8(a0)
    800062ae:	610c                	ld	a1,0(a0)
    800062b0:	34051573          	csrrw	a0,mscratch,a0
    800062b4:	30200073          	mret
	...

00000000800062ba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800062ba:	1141                	addi	sp,sp,-16
    800062bc:	e422                	sd	s0,8(sp)
    800062be:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800062c0:	0c0007b7          	lui	a5,0xc000
    800062c4:	4705                	li	a4,1
    800062c6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800062c8:	c3d8                	sw	a4,4(a5)
}
    800062ca:	6422                	ld	s0,8(sp)
    800062cc:	0141                	addi	sp,sp,16
    800062ce:	8082                	ret

00000000800062d0 <plicinithart>:

void
plicinithart(void)
{
    800062d0:	1141                	addi	sp,sp,-16
    800062d2:	e406                	sd	ra,8(sp)
    800062d4:	e022                	sd	s0,0(sp)
    800062d6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062d8:	ffffc097          	auipc	ra,0xffffc
    800062dc:	b5c080e7          	jalr	-1188(ra) # 80001e34 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062e0:	0085171b          	slliw	a4,a0,0x8
    800062e4:	0c0027b7          	lui	a5,0xc002
    800062e8:	97ba                	add	a5,a5,a4
    800062ea:	40200713          	li	a4,1026
    800062ee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062f2:	00d5151b          	slliw	a0,a0,0xd
    800062f6:	0c2017b7          	lui	a5,0xc201
    800062fa:	953e                	add	a0,a0,a5
    800062fc:	00052023          	sw	zero,0(a0)
}
    80006300:	60a2                	ld	ra,8(sp)
    80006302:	6402                	ld	s0,0(sp)
    80006304:	0141                	addi	sp,sp,16
    80006306:	8082                	ret

0000000080006308 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006308:	1141                	addi	sp,sp,-16
    8000630a:	e406                	sd	ra,8(sp)
    8000630c:	e022                	sd	s0,0(sp)
    8000630e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006310:	ffffc097          	auipc	ra,0xffffc
    80006314:	b24080e7          	jalr	-1244(ra) # 80001e34 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006318:	00d5179b          	slliw	a5,a0,0xd
    8000631c:	0c201537          	lui	a0,0xc201
    80006320:	953e                	add	a0,a0,a5
  return irq;
}
    80006322:	4148                	lw	a0,4(a0)
    80006324:	60a2                	ld	ra,8(sp)
    80006326:	6402                	ld	s0,0(sp)
    80006328:	0141                	addi	sp,sp,16
    8000632a:	8082                	ret

000000008000632c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000632c:	1101                	addi	sp,sp,-32
    8000632e:	ec06                	sd	ra,24(sp)
    80006330:	e822                	sd	s0,16(sp)
    80006332:	e426                	sd	s1,8(sp)
    80006334:	1000                	addi	s0,sp,32
    80006336:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006338:	ffffc097          	auipc	ra,0xffffc
    8000633c:	afc080e7          	jalr	-1284(ra) # 80001e34 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006340:	00d5151b          	slliw	a0,a0,0xd
    80006344:	0c2017b7          	lui	a5,0xc201
    80006348:	97aa                	add	a5,a5,a0
    8000634a:	c3c4                	sw	s1,4(a5)
}
    8000634c:	60e2                	ld	ra,24(sp)
    8000634e:	6442                	ld	s0,16(sp)
    80006350:	64a2                	ld	s1,8(sp)
    80006352:	6105                	addi	sp,sp,32
    80006354:	8082                	ret

0000000080006356 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006356:	1141                	addi	sp,sp,-16
    80006358:	e406                	sd	ra,8(sp)
    8000635a:	e022                	sd	s0,0(sp)
    8000635c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000635e:	479d                	li	a5,7
    80006360:	06a7c963          	blt	a5,a0,800063d2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006364:	0001d797          	auipc	a5,0x1d
    80006368:	c9c78793          	addi	a5,a5,-868 # 80023000 <disk>
    8000636c:	00a78733          	add	a4,a5,a0
    80006370:	6789                	lui	a5,0x2
    80006372:	97ba                	add	a5,a5,a4
    80006374:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006378:	e7ad                	bnez	a5,800063e2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000637a:	00451793          	slli	a5,a0,0x4
    8000637e:	0001f717          	auipc	a4,0x1f
    80006382:	c8270713          	addi	a4,a4,-894 # 80025000 <disk+0x2000>
    80006386:	6314                	ld	a3,0(a4)
    80006388:	96be                	add	a3,a3,a5
    8000638a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000638e:	6314                	ld	a3,0(a4)
    80006390:	96be                	add	a3,a3,a5
    80006392:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006396:	6314                	ld	a3,0(a4)
    80006398:	96be                	add	a3,a3,a5
    8000639a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000639e:	6318                	ld	a4,0(a4)
    800063a0:	97ba                	add	a5,a5,a4
    800063a2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800063a6:	0001d797          	auipc	a5,0x1d
    800063aa:	c5a78793          	addi	a5,a5,-934 # 80023000 <disk>
    800063ae:	97aa                	add	a5,a5,a0
    800063b0:	6509                	lui	a0,0x2
    800063b2:	953e                	add	a0,a0,a5
    800063b4:	4785                	li	a5,1
    800063b6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800063ba:	0001f517          	auipc	a0,0x1f
    800063be:	c5e50513          	addi	a0,a0,-930 # 80025018 <disk+0x2018>
    800063c2:	ffffc097          	auipc	ra,0xffffc
    800063c6:	43a080e7          	jalr	1082(ra) # 800027fc <wakeup>
}
    800063ca:	60a2                	ld	ra,8(sp)
    800063cc:	6402                	ld	s0,0(sp)
    800063ce:	0141                	addi	sp,sp,16
    800063d0:	8082                	ret
    panic("free_desc 1");
    800063d2:	00002517          	auipc	a0,0x2
    800063d6:	3ee50513          	addi	a0,a0,1006 # 800087c0 <syscalls+0x330>
    800063da:	ffffa097          	auipc	ra,0xffffa
    800063de:	164080e7          	jalr	356(ra) # 8000053e <panic>
    panic("free_desc 2");
    800063e2:	00002517          	auipc	a0,0x2
    800063e6:	3ee50513          	addi	a0,a0,1006 # 800087d0 <syscalls+0x340>
    800063ea:	ffffa097          	auipc	ra,0xffffa
    800063ee:	154080e7          	jalr	340(ra) # 8000053e <panic>

00000000800063f2 <virtio_disk_init>:
{
    800063f2:	1101                	addi	sp,sp,-32
    800063f4:	ec06                	sd	ra,24(sp)
    800063f6:	e822                	sd	s0,16(sp)
    800063f8:	e426                	sd	s1,8(sp)
    800063fa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063fc:	00002597          	auipc	a1,0x2
    80006400:	3e458593          	addi	a1,a1,996 # 800087e0 <syscalls+0x350>
    80006404:	0001f517          	auipc	a0,0x1f
    80006408:	d2450513          	addi	a0,a0,-732 # 80025128 <disk+0x2128>
    8000640c:	ffffa097          	auipc	ra,0xffffa
    80006410:	748080e7          	jalr	1864(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006414:	100017b7          	lui	a5,0x10001
    80006418:	4398                	lw	a4,0(a5)
    8000641a:	2701                	sext.w	a4,a4
    8000641c:	747277b7          	lui	a5,0x74727
    80006420:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006424:	0ef71163          	bne	a4,a5,80006506 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006428:	100017b7          	lui	a5,0x10001
    8000642c:	43dc                	lw	a5,4(a5)
    8000642e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006430:	4705                	li	a4,1
    80006432:	0ce79a63          	bne	a5,a4,80006506 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006436:	100017b7          	lui	a5,0x10001
    8000643a:	479c                	lw	a5,8(a5)
    8000643c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000643e:	4709                	li	a4,2
    80006440:	0ce79363          	bne	a5,a4,80006506 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006444:	100017b7          	lui	a5,0x10001
    80006448:	47d8                	lw	a4,12(a5)
    8000644a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000644c:	554d47b7          	lui	a5,0x554d4
    80006450:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006454:	0af71963          	bne	a4,a5,80006506 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006458:	100017b7          	lui	a5,0x10001
    8000645c:	4705                	li	a4,1
    8000645e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006460:	470d                	li	a4,3
    80006462:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006464:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006466:	c7ffe737          	lui	a4,0xc7ffe
    8000646a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000646e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006470:	2701                	sext.w	a4,a4
    80006472:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006474:	472d                	li	a4,11
    80006476:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006478:	473d                	li	a4,15
    8000647a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000647c:	6705                	lui	a4,0x1
    8000647e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006480:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006484:	5bdc                	lw	a5,52(a5)
    80006486:	2781                	sext.w	a5,a5
  if(max == 0)
    80006488:	c7d9                	beqz	a5,80006516 <virtio_disk_init+0x124>
  if(max < NUM)
    8000648a:	471d                	li	a4,7
    8000648c:	08f77d63          	bgeu	a4,a5,80006526 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006490:	100014b7          	lui	s1,0x10001
    80006494:	47a1                	li	a5,8
    80006496:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006498:	6609                	lui	a2,0x2
    8000649a:	4581                	li	a1,0
    8000649c:	0001d517          	auipc	a0,0x1d
    800064a0:	b6450513          	addi	a0,a0,-1180 # 80023000 <disk>
    800064a4:	ffffb097          	auipc	ra,0xffffb
    800064a8:	860080e7          	jalr	-1952(ra) # 80000d04 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800064ac:	0001d717          	auipc	a4,0x1d
    800064b0:	b5470713          	addi	a4,a4,-1196 # 80023000 <disk>
    800064b4:	00c75793          	srli	a5,a4,0xc
    800064b8:	2781                	sext.w	a5,a5
    800064ba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800064bc:	0001f797          	auipc	a5,0x1f
    800064c0:	b4478793          	addi	a5,a5,-1212 # 80025000 <disk+0x2000>
    800064c4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800064c6:	0001d717          	auipc	a4,0x1d
    800064ca:	bba70713          	addi	a4,a4,-1094 # 80023080 <disk+0x80>
    800064ce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800064d0:	0001e717          	auipc	a4,0x1e
    800064d4:	b3070713          	addi	a4,a4,-1232 # 80024000 <disk+0x1000>
    800064d8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800064da:	4705                	li	a4,1
    800064dc:	00e78c23          	sb	a4,24(a5)
    800064e0:	00e78ca3          	sb	a4,25(a5)
    800064e4:	00e78d23          	sb	a4,26(a5)
    800064e8:	00e78da3          	sb	a4,27(a5)
    800064ec:	00e78e23          	sb	a4,28(a5)
    800064f0:	00e78ea3          	sb	a4,29(a5)
    800064f4:	00e78f23          	sb	a4,30(a5)
    800064f8:	00e78fa3          	sb	a4,31(a5)
}
    800064fc:	60e2                	ld	ra,24(sp)
    800064fe:	6442                	ld	s0,16(sp)
    80006500:	64a2                	ld	s1,8(sp)
    80006502:	6105                	addi	sp,sp,32
    80006504:	8082                	ret
    panic("could not find virtio disk");
    80006506:	00002517          	auipc	a0,0x2
    8000650a:	2ea50513          	addi	a0,a0,746 # 800087f0 <syscalls+0x360>
    8000650e:	ffffa097          	auipc	ra,0xffffa
    80006512:	030080e7          	jalr	48(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006516:	00002517          	auipc	a0,0x2
    8000651a:	2fa50513          	addi	a0,a0,762 # 80008810 <syscalls+0x380>
    8000651e:	ffffa097          	auipc	ra,0xffffa
    80006522:	020080e7          	jalr	32(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006526:	00002517          	auipc	a0,0x2
    8000652a:	30a50513          	addi	a0,a0,778 # 80008830 <syscalls+0x3a0>
    8000652e:	ffffa097          	auipc	ra,0xffffa
    80006532:	010080e7          	jalr	16(ra) # 8000053e <panic>

0000000080006536 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006536:	7159                	addi	sp,sp,-112
    80006538:	f486                	sd	ra,104(sp)
    8000653a:	f0a2                	sd	s0,96(sp)
    8000653c:	eca6                	sd	s1,88(sp)
    8000653e:	e8ca                	sd	s2,80(sp)
    80006540:	e4ce                	sd	s3,72(sp)
    80006542:	e0d2                	sd	s4,64(sp)
    80006544:	fc56                	sd	s5,56(sp)
    80006546:	f85a                	sd	s6,48(sp)
    80006548:	f45e                	sd	s7,40(sp)
    8000654a:	f062                	sd	s8,32(sp)
    8000654c:	ec66                	sd	s9,24(sp)
    8000654e:	e86a                	sd	s10,16(sp)
    80006550:	1880                	addi	s0,sp,112
    80006552:	892a                	mv	s2,a0
    80006554:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006556:	00c52c83          	lw	s9,12(a0)
    8000655a:	001c9c9b          	slliw	s9,s9,0x1
    8000655e:	1c82                	slli	s9,s9,0x20
    80006560:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006564:	0001f517          	auipc	a0,0x1f
    80006568:	bc450513          	addi	a0,a0,-1084 # 80025128 <disk+0x2128>
    8000656c:	ffffa097          	auipc	ra,0xffffa
    80006570:	678080e7          	jalr	1656(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006574:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006576:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006578:	0001db97          	auipc	s7,0x1d
    8000657c:	a88b8b93          	addi	s7,s7,-1400 # 80023000 <disk>
    80006580:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006582:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006584:	8a4e                	mv	s4,s3
    80006586:	a051                	j	8000660a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006588:	00fb86b3          	add	a3,s7,a5
    8000658c:	96da                	add	a3,a3,s6
    8000658e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006592:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006594:	0207c563          	bltz	a5,800065be <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006598:	2485                	addiw	s1,s1,1
    8000659a:	0711                	addi	a4,a4,4
    8000659c:	25548063          	beq	s1,s5,800067dc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800065a0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800065a2:	0001f697          	auipc	a3,0x1f
    800065a6:	a7668693          	addi	a3,a3,-1418 # 80025018 <disk+0x2018>
    800065aa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800065ac:	0006c583          	lbu	a1,0(a3)
    800065b0:	fde1                	bnez	a1,80006588 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800065b2:	2785                	addiw	a5,a5,1
    800065b4:	0685                	addi	a3,a3,1
    800065b6:	ff879be3          	bne	a5,s8,800065ac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800065ba:	57fd                	li	a5,-1
    800065bc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800065be:	02905a63          	blez	s1,800065f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065c2:	f9042503          	lw	a0,-112(s0)
    800065c6:	00000097          	auipc	ra,0x0
    800065ca:	d90080e7          	jalr	-624(ra) # 80006356 <free_desc>
      for(int j = 0; j < i; j++)
    800065ce:	4785                	li	a5,1
    800065d0:	0297d163          	bge	a5,s1,800065f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065d4:	f9442503          	lw	a0,-108(s0)
    800065d8:	00000097          	auipc	ra,0x0
    800065dc:	d7e080e7          	jalr	-642(ra) # 80006356 <free_desc>
      for(int j = 0; j < i; j++)
    800065e0:	4789                	li	a5,2
    800065e2:	0097d863          	bge	a5,s1,800065f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065e6:	f9842503          	lw	a0,-104(s0)
    800065ea:	00000097          	auipc	ra,0x0
    800065ee:	d6c080e7          	jalr	-660(ra) # 80006356 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065f2:	0001f597          	auipc	a1,0x1f
    800065f6:	b3658593          	addi	a1,a1,-1226 # 80025128 <disk+0x2128>
    800065fa:	0001f517          	auipc	a0,0x1f
    800065fe:	a1e50513          	addi	a0,a0,-1506 # 80025018 <disk+0x2018>
    80006602:	ffffc097          	auipc	ra,0xffffc
    80006606:	054080e7          	jalr	84(ra) # 80002656 <sleep>
  for(int i = 0; i < 3; i++){
    8000660a:	f9040713          	addi	a4,s0,-112
    8000660e:	84ce                	mv	s1,s3
    80006610:	bf41                	j	800065a0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006612:	20058713          	addi	a4,a1,512
    80006616:	00471693          	slli	a3,a4,0x4
    8000661a:	0001d717          	auipc	a4,0x1d
    8000661e:	9e670713          	addi	a4,a4,-1562 # 80023000 <disk>
    80006622:	9736                	add	a4,a4,a3
    80006624:	4685                	li	a3,1
    80006626:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000662a:	20058713          	addi	a4,a1,512
    8000662e:	00471693          	slli	a3,a4,0x4
    80006632:	0001d717          	auipc	a4,0x1d
    80006636:	9ce70713          	addi	a4,a4,-1586 # 80023000 <disk>
    8000663a:	9736                	add	a4,a4,a3
    8000663c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006640:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006644:	7679                	lui	a2,0xffffe
    80006646:	963e                	add	a2,a2,a5
    80006648:	0001f697          	auipc	a3,0x1f
    8000664c:	9b868693          	addi	a3,a3,-1608 # 80025000 <disk+0x2000>
    80006650:	6298                	ld	a4,0(a3)
    80006652:	9732                	add	a4,a4,a2
    80006654:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006656:	6298                	ld	a4,0(a3)
    80006658:	9732                	add	a4,a4,a2
    8000665a:	4541                	li	a0,16
    8000665c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000665e:	6298                	ld	a4,0(a3)
    80006660:	9732                	add	a4,a4,a2
    80006662:	4505                	li	a0,1
    80006664:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006668:	f9442703          	lw	a4,-108(s0)
    8000666c:	6288                	ld	a0,0(a3)
    8000666e:	962a                	add	a2,a2,a0
    80006670:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006674:	0712                	slli	a4,a4,0x4
    80006676:	6290                	ld	a2,0(a3)
    80006678:	963a                	add	a2,a2,a4
    8000667a:	05890513          	addi	a0,s2,88
    8000667e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006680:	6294                	ld	a3,0(a3)
    80006682:	96ba                	add	a3,a3,a4
    80006684:	40000613          	li	a2,1024
    80006688:	c690                	sw	a2,8(a3)
  if(write)
    8000668a:	140d0063          	beqz	s10,800067ca <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000668e:	0001f697          	auipc	a3,0x1f
    80006692:	9726b683          	ld	a3,-1678(a3) # 80025000 <disk+0x2000>
    80006696:	96ba                	add	a3,a3,a4
    80006698:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000669c:	0001d817          	auipc	a6,0x1d
    800066a0:	96480813          	addi	a6,a6,-1692 # 80023000 <disk>
    800066a4:	0001f517          	auipc	a0,0x1f
    800066a8:	95c50513          	addi	a0,a0,-1700 # 80025000 <disk+0x2000>
    800066ac:	6114                	ld	a3,0(a0)
    800066ae:	96ba                	add	a3,a3,a4
    800066b0:	00c6d603          	lhu	a2,12(a3)
    800066b4:	00166613          	ori	a2,a2,1
    800066b8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800066bc:	f9842683          	lw	a3,-104(s0)
    800066c0:	6110                	ld	a2,0(a0)
    800066c2:	9732                	add	a4,a4,a2
    800066c4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800066c8:	20058613          	addi	a2,a1,512
    800066cc:	0612                	slli	a2,a2,0x4
    800066ce:	9642                	add	a2,a2,a6
    800066d0:	577d                	li	a4,-1
    800066d2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800066d6:	00469713          	slli	a4,a3,0x4
    800066da:	6114                	ld	a3,0(a0)
    800066dc:	96ba                	add	a3,a3,a4
    800066de:	03078793          	addi	a5,a5,48
    800066e2:	97c2                	add	a5,a5,a6
    800066e4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800066e6:	611c                	ld	a5,0(a0)
    800066e8:	97ba                	add	a5,a5,a4
    800066ea:	4685                	li	a3,1
    800066ec:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800066ee:	611c                	ld	a5,0(a0)
    800066f0:	97ba                	add	a5,a5,a4
    800066f2:	4809                	li	a6,2
    800066f4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800066f8:	611c                	ld	a5,0(a0)
    800066fa:	973e                	add	a4,a4,a5
    800066fc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006700:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006704:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006708:	6518                	ld	a4,8(a0)
    8000670a:	00275783          	lhu	a5,2(a4)
    8000670e:	8b9d                	andi	a5,a5,7
    80006710:	0786                	slli	a5,a5,0x1
    80006712:	97ba                	add	a5,a5,a4
    80006714:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006718:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000671c:	6518                	ld	a4,8(a0)
    8000671e:	00275783          	lhu	a5,2(a4)
    80006722:	2785                	addiw	a5,a5,1
    80006724:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006728:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000672c:	100017b7          	lui	a5,0x10001
    80006730:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006734:	00492703          	lw	a4,4(s2)
    80006738:	4785                	li	a5,1
    8000673a:	02f71163          	bne	a4,a5,8000675c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000673e:	0001f997          	auipc	s3,0x1f
    80006742:	9ea98993          	addi	s3,s3,-1558 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006746:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006748:	85ce                	mv	a1,s3
    8000674a:	854a                	mv	a0,s2
    8000674c:	ffffc097          	auipc	ra,0xffffc
    80006750:	f0a080e7          	jalr	-246(ra) # 80002656 <sleep>
  while(b->disk == 1) {
    80006754:	00492783          	lw	a5,4(s2)
    80006758:	fe9788e3          	beq	a5,s1,80006748 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000675c:	f9042903          	lw	s2,-112(s0)
    80006760:	20090793          	addi	a5,s2,512
    80006764:	00479713          	slli	a4,a5,0x4
    80006768:	0001d797          	auipc	a5,0x1d
    8000676c:	89878793          	addi	a5,a5,-1896 # 80023000 <disk>
    80006770:	97ba                	add	a5,a5,a4
    80006772:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006776:	0001f997          	auipc	s3,0x1f
    8000677a:	88a98993          	addi	s3,s3,-1910 # 80025000 <disk+0x2000>
    8000677e:	00491713          	slli	a4,s2,0x4
    80006782:	0009b783          	ld	a5,0(s3)
    80006786:	97ba                	add	a5,a5,a4
    80006788:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000678c:	854a                	mv	a0,s2
    8000678e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006792:	00000097          	auipc	ra,0x0
    80006796:	bc4080e7          	jalr	-1084(ra) # 80006356 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000679a:	8885                	andi	s1,s1,1
    8000679c:	f0ed                	bnez	s1,8000677e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000679e:	0001f517          	auipc	a0,0x1f
    800067a2:	98a50513          	addi	a0,a0,-1654 # 80025128 <disk+0x2128>
    800067a6:	ffffa097          	auipc	ra,0xffffa
    800067aa:	504080e7          	jalr	1284(ra) # 80000caa <release>
}
    800067ae:	70a6                	ld	ra,104(sp)
    800067b0:	7406                	ld	s0,96(sp)
    800067b2:	64e6                	ld	s1,88(sp)
    800067b4:	6946                	ld	s2,80(sp)
    800067b6:	69a6                	ld	s3,72(sp)
    800067b8:	6a06                	ld	s4,64(sp)
    800067ba:	7ae2                	ld	s5,56(sp)
    800067bc:	7b42                	ld	s6,48(sp)
    800067be:	7ba2                	ld	s7,40(sp)
    800067c0:	7c02                	ld	s8,32(sp)
    800067c2:	6ce2                	ld	s9,24(sp)
    800067c4:	6d42                	ld	s10,16(sp)
    800067c6:	6165                	addi	sp,sp,112
    800067c8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800067ca:	0001f697          	auipc	a3,0x1f
    800067ce:	8366b683          	ld	a3,-1994(a3) # 80025000 <disk+0x2000>
    800067d2:	96ba                	add	a3,a3,a4
    800067d4:	4609                	li	a2,2
    800067d6:	00c69623          	sh	a2,12(a3)
    800067da:	b5c9                	j	8000669c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800067dc:	f9042583          	lw	a1,-112(s0)
    800067e0:	20058793          	addi	a5,a1,512
    800067e4:	0792                	slli	a5,a5,0x4
    800067e6:	0001d517          	auipc	a0,0x1d
    800067ea:	8c250513          	addi	a0,a0,-1854 # 800230a8 <disk+0xa8>
    800067ee:	953e                	add	a0,a0,a5
  if(write)
    800067f0:	e20d11e3          	bnez	s10,80006612 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800067f4:	20058713          	addi	a4,a1,512
    800067f8:	00471693          	slli	a3,a4,0x4
    800067fc:	0001d717          	auipc	a4,0x1d
    80006800:	80470713          	addi	a4,a4,-2044 # 80023000 <disk>
    80006804:	9736                	add	a4,a4,a3
    80006806:	0a072423          	sw	zero,168(a4)
    8000680a:	b505                	j	8000662a <virtio_disk_rw+0xf4>

000000008000680c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000680c:	1101                	addi	sp,sp,-32
    8000680e:	ec06                	sd	ra,24(sp)
    80006810:	e822                	sd	s0,16(sp)
    80006812:	e426                	sd	s1,8(sp)
    80006814:	e04a                	sd	s2,0(sp)
    80006816:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006818:	0001f517          	auipc	a0,0x1f
    8000681c:	91050513          	addi	a0,a0,-1776 # 80025128 <disk+0x2128>
    80006820:	ffffa097          	auipc	ra,0xffffa
    80006824:	3c4080e7          	jalr	964(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006828:	10001737          	lui	a4,0x10001
    8000682c:	533c                	lw	a5,96(a4)
    8000682e:	8b8d                	andi	a5,a5,3
    80006830:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006832:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006836:	0001e797          	auipc	a5,0x1e
    8000683a:	7ca78793          	addi	a5,a5,1994 # 80025000 <disk+0x2000>
    8000683e:	6b94                	ld	a3,16(a5)
    80006840:	0207d703          	lhu	a4,32(a5)
    80006844:	0026d783          	lhu	a5,2(a3)
    80006848:	06f70163          	beq	a4,a5,800068aa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000684c:	0001c917          	auipc	s2,0x1c
    80006850:	7b490913          	addi	s2,s2,1972 # 80023000 <disk>
    80006854:	0001e497          	auipc	s1,0x1e
    80006858:	7ac48493          	addi	s1,s1,1964 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000685c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006860:	6898                	ld	a4,16(s1)
    80006862:	0204d783          	lhu	a5,32(s1)
    80006866:	8b9d                	andi	a5,a5,7
    80006868:	078e                	slli	a5,a5,0x3
    8000686a:	97ba                	add	a5,a5,a4
    8000686c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000686e:	20078713          	addi	a4,a5,512
    80006872:	0712                	slli	a4,a4,0x4
    80006874:	974a                	add	a4,a4,s2
    80006876:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000687a:	e731                	bnez	a4,800068c6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000687c:	20078793          	addi	a5,a5,512
    80006880:	0792                	slli	a5,a5,0x4
    80006882:	97ca                	add	a5,a5,s2
    80006884:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006886:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000688a:	ffffc097          	auipc	ra,0xffffc
    8000688e:	f72080e7          	jalr	-142(ra) # 800027fc <wakeup>

    disk.used_idx += 1;
    80006892:	0204d783          	lhu	a5,32(s1)
    80006896:	2785                	addiw	a5,a5,1
    80006898:	17c2                	slli	a5,a5,0x30
    8000689a:	93c1                	srli	a5,a5,0x30
    8000689c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800068a0:	6898                	ld	a4,16(s1)
    800068a2:	00275703          	lhu	a4,2(a4)
    800068a6:	faf71be3          	bne	a4,a5,8000685c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800068aa:	0001f517          	auipc	a0,0x1f
    800068ae:	87e50513          	addi	a0,a0,-1922 # 80025128 <disk+0x2128>
    800068b2:	ffffa097          	auipc	ra,0xffffa
    800068b6:	3f8080e7          	jalr	1016(ra) # 80000caa <release>
}
    800068ba:	60e2                	ld	ra,24(sp)
    800068bc:	6442                	ld	s0,16(sp)
    800068be:	64a2                	ld	s1,8(sp)
    800068c0:	6902                	ld	s2,0(sp)
    800068c2:	6105                	addi	sp,sp,32
    800068c4:	8082                	ret
      panic("virtio_disk_intr status");
    800068c6:	00002517          	auipc	a0,0x2
    800068ca:	f8a50513          	addi	a0,a0,-118 # 80008850 <syscalls+0x3c0>
    800068ce:	ffffa097          	auipc	ra,0xffffa
    800068d2:	c70080e7          	jalr	-912(ra) # 8000053e <panic>

00000000800068d6 <cas>:
    800068d6:	100522af          	lr.w	t0,(a0)
    800068da:	00b29563          	bne	t0,a1,800068e4 <fail>
    800068de:	18c5252f          	sc.w	a0,a2,(a0)
    800068e2:	8082                	ret

00000000800068e4 <fail>:
    800068e4:	4505                	li	a0,1
    800068e6:	8082                	ret
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
