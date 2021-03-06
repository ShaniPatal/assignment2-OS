#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"


int
main(int argc, char *argv[])
{
    for(int i=0;i<100;i++){
        int pid = fork();
        if(pid != 0){
            printf("pid = %d\n",pid);
        } else if(i%10 != 0)while (1);
    }

    exit(0);
}