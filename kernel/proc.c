#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

volatile int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

extern uint64 cas(volatile void *addr, int expected, int newval);

int zombie_head = -1;
int sleeping_head = -1;
int unused_head = -1;
struct spinlock zombie_lock, sleeping_lock, unused_lock;

void print_list(int first_id)
{
  printf("list:      ");
  int curr = first_id;
  while (curr != -1)
  {
    printf("%d -> ", curr);
    curr = proc[curr].next;
  }
  printf("\n");
}

// void remove_proc(int* first_proc_id, struct proc* remove_proc, struct spinlock* first_lock) { // Tali's
//     struct proc *curr_proc;
//     struct proc *prev_proc;
//     acquire(first_lock);
//     // print_list(first_proc_id);
//     if (*first_proc_id == -1)
//         panic("list is empty - can't remove");

//     curr_proc = &proc[*first_proc_id];
//     acquire(&curr_proc->p_lock);
//     if (curr_proc->proc_idx == remove_proc->proc_idx){
//         *first_proc_id = remove_proc->next;
//         remove_proc->next= -1;
//         release(&curr_proc->p_lock);
//         release(first_lock);
//         return;
//     }

//     release(first_lock);
//     while (curr_proc->next != remove_proc->proc_idx){
//         if (curr_proc->next  == -1)
//             panic("finished the list - didnt find removed proc");

//         prev_proc = curr_proc;
//         curr_proc = &proc[prev_proc->next];
//         acquire(&curr_proc->p_lock);
//         release(&prev_proc->p_lock);
//     }
//     acquire(&remove_proc->p_lock);
//     curr_proc->next = remove_proc->next;
//     remove_proc->next= -1;
//     release(&remove_proc->p_lock);
//     release(&curr_proc->p_lock);
// }

int find_remove(struct proc *curr_proc, struct proc *to_remove)
{
  while (curr_proc->next != -1)
  {
    acquire(&proc[curr_proc->next].p_lock);
    if (proc[curr_proc->next].proc_idx == to_remove->proc_idx)
    {
      curr_proc->next = to_remove->next;
      to_remove->next = -1;
      release(&curr_proc->p_lock);
      release(&to_remove->p_lock);
      return 1;
    }
    else
      release(&curr_proc->p_lock);
    curr_proc = &proc[curr_proc->next];
  }
  release(&curr_proc->p_lock);
  return -1;
}

int remove_proc(int *head_list, struct proc *to_remove, struct spinlock *head_lock)
{
  // printf("%s \n", "im in remove------------------------------------");
  // printf("%d\n", to_remove->proc_idx );

  acquire(head_lock);
  if (*head_list == -1) // empty list case
  {
    printf("%s \n ", head_lock->name);
    release(head_lock);

    return -1;
  }
  acquire(&proc[*head_list].p_lock);
  if (*head_list == to_remove->proc_idx)
  {
    *head_list = to_remove->next;
    release(&to_remove->p_lock);
    release(head_lock);
    return 1;
  }
  release(head_lock);
  return find_remove(&proc[*head_list], to_remove);
}

// void add_proc(int* first_proc_id, struct proc* new_proc, struct spinlock* first_lock) {  //Tali's
//     struct proc *curr_proc;
//     struct proc *prev_proc;
//     acquire(first_lock);
//     if (*first_proc_id == -1){
//         *first_proc_id = new_proc->proc_idx;
//         new_proc->next = -1;
//         release(first_lock);
//         return;
//     }
//     curr_proc = &proc[*first_proc_id];
//     acquire(&curr_proc->p_lock);
//     release(first_lock);
//     while (curr_proc->next != -1){
//         prev_proc = curr_proc;
//         curr_proc = &proc[curr_proc->next];
//         acquire(&curr_proc->p_lock);
//         release(&prev_proc->p_lock);
//     }
//     curr_proc->next = new_proc->proc_idx;
//     new_proc->next= -1;
//     release(&curr_proc->p_lock);
// }

void add_not_first(struct proc *curr, struct proc *to_add)
{
  while (curr->next != -1)
  {
    release(&curr->p_lock); // probablly need those locks.
    curr = &proc[curr->next];
    acquire(&curr->p_lock);
  }
  curr->next = to_add->proc_idx;
  release(&curr->p_lock);
}

void add_proc(int *head, struct proc *to_add, struct spinlock *head_lock)
{
  acquire(head_lock);
  if (*head == -1)
  {
    *head = to_add->proc_idx;
    proc[*head].next = -1;
    release(head_lock);
  }
  else
  {
    acquire(&proc[*head].p_lock);
    release(head_lock);
    add_not_first(&proc[*head], to_add);
  }
}

void init_locks()
{
  struct cpu *c;
  initlock(&zombie_lock, "zombie");
  initlock(&unused_lock, "unused");
  initlock(&sleeping_lock, "sleeping");
  for (c = cpus; c < &cpus[NCPU]; c++)
  {
    c->runnable_head = -1;
    initlock(&c->head_lock, "runnable");
  }
}

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// void procinit(void) //   Tali's
// {
//   init_locks();
//   struct proc *p;
//   struct cpu *c;
//   initlock(&pid_lock, "nextpid");
//   initlock(&wait_lock, "wait_lock");
//   int i = -1;
//   for(p = proc; p < &proc[NPROC]; p++) {
//       i++;
//       initlock(&p->lock, "proc");
//       initlock(&p->p_lock, "node");
//       p->kstack = KSTACK((int) (p - proc));
//       p->proc_idx = i;
//       p->next = -1;
//       add_proc(&unused_head, p, &unused_lock);
//   }
//     for(c = cpus; c < &cpus[NCPU]; c++) {
//         c->runnable_head = -1;
//         initlock(&c->head_lock, "runnable_node");
//     }
// }

// initialize the proc table at boot time.
void procinit(void)
{
  init_locks();
  int i = 0;
  struct proc *p;
  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    initlock(&p->lock, "proc");
    initlock(&p->p_lock, "p_lock");

    p->kstack = KSTACK((int)(p - proc));
    p->proc_idx = i;
    p->next = -1;
    add_proc(&unused_head, p, &unused_lock);
    i++;
  }

  // printing TESTS:

  // p = &proc[unused_head];
  // while (p->next!= -1){
  //   printf("%d\n", p->proc_idx);
  //   p = &proc[p->next];
  // }
  // p = &proc[unused_head];
  // while (p->next!= -1){
  //   p = &proc[p->next];
  // }
  // remove_proc(&unused_head, p, &unused_lock);
  // // p = &proc[unused_head];
  // while (p->next!= -1){
  //   printf("%d\n", p->proc_idx);
  //   p = &proc[p->next];
  // }
  // struct cpu *c = &cpus[p->cpu];
  // printf("%s\n", "end printing test!");
  // print_list(c->runnable_head);
  // print_list(unused_head);
  // print_list(sleeping_head);
  // print_list(zombie_head);
  // print_list(c->ru)
  // for (p = proc; p < &proc[NPROC]-1; p++)
  // {
  //   remove_proc(&unused_head, p, &unused_lock);
  //   printf("%d\n", p->proc_idx );
  // }
  //   printf("last %d\n", proc[unused_head].next);
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.  
int cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int allocpid()
{
  int pid;
  do
  {
    pid = nextpid;
  } while (cas(&nextpid, pid, pid + 1));
  return pid;
}

// static struct proc *
// allocproc(void)                  // Tali's
// {
//     struct proc *p;

//     if (unused_head != -1)
//     {
//         p = &proc[unused_head];
//         acquire(&p->lock);
//         goto found;
//     }

//     return 0;

// found:
//     p->pid = allocpid();
//     remove_proc(&unused_head, p, &unused_lock);
//     p->state = USED;

//     // Allocate a trapframe page.
//     if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
//     {
//         freeproc(p);
//         release(&p->lock);
//         // releaseAndPrint(&p->lock, "allocproc 2", p);
//         return 0;
//     }

//     // An empty user page table.
//     p->pagetable = proc_pagetable(p);
//     if (p->pagetable == 0)
//     {
//         freeproc(p);
//         release(&p->lock);
//         // releaseAndPrint(&p->lock, "allocproc", p);
//         return 0;
//     }

//     // Set up new context to start executing at forkret,
//     // which returns to user space.
//     memset(&p->context, 0, sizeof(p->context));
//     p->context.ra = (uint64)forkret;
//     p->context.sp = p->kstack + PGSIZE;

//     return p;
// }

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc *
allocproc(void)
{
  struct proc *p;

  if (unused_head != -1)
  {
    p = &proc[unused_head];
    acquire(&p->lock);
    goto found;
  }

  return 0;

found:
  p->pid = allocpid();
  // release(&p->p_lock); // if we release then panic. WHY??
  remove_proc(&unused_head, p, &unused_lock);
  p->state = USED;

  //  acquire(&p->p_lock); // Tali didnt

  // Allocate a trapframe page.
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }
  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if (p->pagetable == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;

  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  if (p->trapframe)
    kfree((void *)p->trapframe);
  p->trapframe = 0;
  if (p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  remove_proc(&zombie_head, p, &zombie_lock);
  p->state = UNUSED;
  add_proc(&unused_head, p, &unused_lock);
}

// Create a user page table for a given process,
// with no user memory, but with trampoline pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if (pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
               (uint64)trampoline, PTE_R | PTE_X) < 0)
  {
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe just below TRAMPOLINE, for trampoline.S.
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
               (uint64)(p->trapframe), PTE_R | PTE_W) < 0)
  {
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// od -t xC initcode
uchar initcode[] = {
    0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
    0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
    0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
    0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
    0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
    0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00};

// Set up first user process.
void userinit(void)
{
  struct proc *p;

  p = allocproc();
  initproc = p;

  // allocate one user page and copy init's instructions
  // and data into it.
  uvminit(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;     // user program counter
  p->trapframe->sp = PGSIZE; // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");
  p->state = RUNNABLE;
  add_proc(&cpus[0].runnable_head, p, &cpus[0].head_lock);
  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int growproc(int n)
{
  uint sz;
  struct proc *p = myproc();

  sz = p->sz;
  if (n > 0)
  {
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    {
      return -1;
    }
  }
  else if (n < 0)
  {
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if ((np = allocproc()) == 0)
  {
    return -1;
  }
  // Copy user memory from parent to child.
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
  {
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for (i = 0; i < NOFILE; i++)
    if (p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  np->cpu = p->cpu; // need to modify later (q.4)
  release(&wait_lock);
  acquire(&np->lock);
  np->state = RUNNABLE;
  struct cpu *c = &cpus[np->cpu]; // is p and np must be in the same cpu?
  // printf("p %d \n", p->cpu);
  // printf("np %d \n", np->cpu);
  add_proc(&c->runnable_head, np, &c->head_lock);
  release(&np->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void reparent(struct proc *p)
{
  struct proc *pp;

  for (pp = proc; pp < &proc[NPROC]; pp++)
  {
    if (pp->parent == p)
    {
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void exit(int status)
{
  struct proc *p = myproc();

  if (p == initproc)
    panic("init exiting");

  // Close all open files.
  for (int fd = 0; fd < NOFILE; fd++)
  {
    if (p->ofile[fd])
    {
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);

  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;
  add_proc(&zombie_head, p, &zombie_lock);
  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int wait(uint64 addr)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (np = proc; np < &proc[NPROC]; np++)
    {
      if (np->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
        {
          // Found one.
          pid = np->pid;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                   sizeof(np->xstate)) < 0)
          {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || p->killed)
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();

  c->proc = 0;
  for (;;)
  {
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();
    if (c->runnable_head != -1)
    {
      //   printf("runnable\n");
      //  print_list(c->runnable_head);
      p = &proc[c->runnable_head];
      acquire(&p->lock);
      remove_proc(&c->runnable_head, p, &c->head_lock);
      p->state = RUNNING;
      c->proc = p;
      swtch(&c->context, &p->context);

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      c->proc = 0;
      release(&p->lock);
    }
  }
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void sched(void)
{
  int intena;
  struct proc *p = myproc();

  if (!holding(&p->lock))
    panic("sched p->lock");
  if (mycpu()->noff != 1)
    panic("sched locks");
  if (p->state == RUNNING)
    panic("sched running");
  if (intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  struct cpu *c = &cpus[p->cpu];
  add_proc(&c->runnable_head, p, &c->head_lock);
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first)
  {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();

  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
  // printf("unused\n");
  // print_list(unused_head);
  // printf("sleepig\n");
  // print_list(sleeping_head);
  add_proc(&sleeping_head, p, &sleeping_lock);
  // printf("sleepig\n");
  release(lk);
  p->chan = chan;
  p->state = SLEEPING;

  // Go to sleep.

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// void wakeup(void *chan)    // Tali's
// {
//   struct proc *p;
//   for (p = proc; p < &proc[NPROC]; p++)
//   { // TODO: update to run on sleeping only
//     if (p != myproc())
//     {
//       acquire(&p->lock);
//       if (p->state == SLEEPING && p->chan == chan)
//       {
//         // printf("%s \n","sleeping");
//         remove_proc(&sleeping_head, p, &sleeping_lock);
//         p->state = RUNNABLE;
//         // p->cpu = update_cpu(p->cpu);
//         struct cpu *c = &cpus[p->cpu];
//         add_proc(&c->runnable_head, p, &c->head_lock);
//       }
//       release(&p->lock);
//     }
//   }
// }

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
// int i = 0;
void wakeup(void *chan)
{
  // while(proc[sleeping_head].next != -1){
  //   printf("%d\n", proc[sleeping_head].proc_idx);
  //   sleeping_head = proc[sleeping_head].next;
  // }
  struct proc *p;
  // printf("%s\n", "line 700---------------------");
  // printf("%d\n", sleeping_head);
  //       p=proc;
  //   printf("running\n");
  // print_list(cpus[p->cpu].runnable_head);
  if (sleeping_head != -1)
  {
    // printf("%d\n", p->proc_idx);
    p = &proc[sleeping_head];
    acquire(&p->p_lock);
    int cpu_num = p->cpu;
    int next_proc = p->next;
    if (p->chan == chan)
    {
      // i++;
      // printf("%d \n", i);
      // printf("%s\n","line 714 ----------------");
      release(&p->p_lock);
      remove_proc(&sleeping_head, p, &sleeping_lock);
      p->state = RUNNABLE;
      add_proc(&cpus[cpu_num].runnable_head, p, &cpus[cpu_num].head_lock);
    }
    else
    {
      release(&p->p_lock);
    }
    // printf("%s \n", p->state);  // when activated makes panice accuire. WHY?

    while (next_proc != -1)
    {
      p = &proc[next_proc];
      acquire(&p->p_lock);
      cpu_num = p->cpu;
      next_proc = p->next;
      if (p->chan == chan)
      {
        release(&p->p_lock);
        p->state = RUNNABLE;
        remove_proc(&sleeping_head, p, &sleeping_lock);
        add_proc(&cpus[cpu_num].runnable_head, p, &cpus[cpu_num].head_lock);
      }
      else
        release(&p->p_lock);
    }
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->pid == pid)
    {
      p->killed = 1;
      if (p->state == SLEEPING)
      {
        remove_proc(&sleeping_head, p, &sleeping_lock);
        // Wake process from sleep().
        p->state = RUNNABLE;
        struct cpu *c = &cpus[p->cpu];
        add_proc(&c->runnable_head, p, &c->head_lock);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if (user_dst)
  {
    return copyout(p->pagetable, dst, src, len);
  }
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if (user_src)
  {
    return copyin(p->pagetable, dst, src, len);
  }
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
  static char *states[] = {
      [UNUSED] "unused",
      [SLEEPING] "sleep ",
      [RUNNABLE] "runble",
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}

int set_cpu(int cpu_num)
{
  struct proc *p = myproc();
  if (cas(&p->cpu, p->cpu, cpu_num) != 0)
    return -1;
  yield();
  return cpu_num;
}

int get_cpu()
{
  struct proc *p = myproc();
  int cpu_num = -1;
  acquire(&p->lock);
  cpu_num = p->cpu;
  release(&p->lock);
  return cpu_num;
}
