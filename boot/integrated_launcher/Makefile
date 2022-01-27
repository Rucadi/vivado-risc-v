CROSS_COMPILE=$(CROSS_COMPILE_LINUX) 
CC=$(CROSS_COMPILE)gcc
OBJCOPY=$(CROSS_COMPILE)objcopy
OBJDUMP=$(CROSS_COMPILE)objdump


CFLAGS = -march=rv64imafdc -mabi=lp64 -O3
CCFLAGS = $(CFLAGS) -mcmodel=medany  -Wall -fPIC -fpic  -fno-common  -I. -fPIE -O3
LFLAGS = -static -nostartfiles -nodefaultlibs -T launcher.lds   $(CCFLAGS)



all: launcher.img
%.img: %.elf
	$(OBJCOPY) -O binary $< $@
	ls -l $@

%.elf: head.S launcher.c 
	$(CC) $(CCFLAGS) $(LFLAGS) -o $@ head.S launcher.c
	$(OBJDUMP) -h -p $@
	$(OBJDUMP) -S  $@ > LAUNCHER_DEC.S

clean:
	rm -f *.elf *.img  LAUNCHER_DEC.S gen
