# --- configuration ---

ifneq (,$(wildcard workspace/config))
include workspace/config
endif

BOARD ?= nexys-video
CONFIG ?= rocket64b2
HW_SERVER_ADDR ?= localhost:3121
JAVA_OPTIONS ?=

include board/$(BOARD)/Makefile.inc

# --- packages and repos ---

apt-install:
	sudo apt update
	sudo apt upgrade
	sudo apt install default-jdk device-tree-compiler python curl gawk \
	 libtinfo5 libmpc-dev gcc gcc-riscv64-linux-gnu gcc-8-riscv64-linux-gnu flex bison

# skip submodules which are not needed and take long time to update
SKIP_SUBMODULES = torture software/gemmini-rocc-tests software/onnxruntime-riscv

update-submodules:
	git $(foreach m,$(SKIP_SUBMODULES),-c submodule.$(m).update=none) submodule update --init --force --recursive

clean-submodules:
	git submodule foreach --recursive git clean -xfdq

clean:
	git submodule foreach --recursive git clean -xfdq
	sudo rm -rf debian-riscv64

# --- download gcc, initrd and rootfs from github.com ---

workspace/gcc/tools.tar.gz:
	mkdir -p workspace/gcc
	curl --netrc --location --header 'Accept: application/octet-stream' \
	  https://api.github.com/repos/eugene-tarassov/vivado-risc-v/releases/assets/18060315 \
	  -o $@.tmp
	mv $@.tmp $@

workspace/gcc/riscv: workspace/gcc/tools.tar.gz
	cd workspace/gcc && tar xzf tools.tar.gz
	touch $@

debian-riscv64/initrd:
	mkdir -p debian-riscv64
	curl --netrc --location --header 'Accept: application/octet-stream' \
	  https://api.github.com/repos/eugene-tarassov/vivado-risc-v/releases/assets/37912705 \
	  -o $@.tmp
	mv $@.tmp $@

debian-riscv64/rootfs.tar.gz:
	mkdir -p debian-riscv64
	curl --netrc --location --header 'Accept: application/octet-stream' \
	  https://api.github.com/repos/eugene-tarassov/vivado-risc-v/releases/assets/37912707 \
	  -o $@.tmp
	mv $@.tmp $@

# --- build Linux kernel ---

.PHONY: linux linux-patch

linux: linux-stable/arch/riscv/boot/Image

CROSS_COMPILE_LINUX = /usr/bin/riscv64-linux-gnu-

linux-patch: patches/linux.patch patches/fpga-axi-sdc.c patches/fpga-axi-eth.c patches/linux.config
	if [ -s patches/linux.patch ] ; then cd linux-stable && ( git apply -R --check ../patches/linux.patch 2>/dev/null || git apply ../patches/linux.patch ) ; fi
	cp -p patches/fpga-axi-eth.c  linux-stable/drivers/net/ethernet
	cp -p patches/fpga-axi-sdc.c  linux-stable/drivers/mmc/host
	cp -p patches/fpga-axi-uart.c linux-stable/drivers/tty/serial
	cp -p patches/linux.config linux-stable/.config

linux-stable/arch/riscv/boot/Image: linux-patch
	make -C linux-stable ARCH=riscv CROSS_COMPILE=$(CROSS_COMPILE_LINUX) oldconfig
	make -C linux-stable ARCH=riscv CROSS_COMPILE=$(CROSS_COMPILE_LINUX) all


# --- build U-Boot ---

ROOTFS ?= SD
ROOTFS_URL ?= 192.168.0.100:/home/nfsroot/192.168.0.243

.PHONY: u-boot u-boot-patch

u-boot: u-boot/u-boot-nodtb.bin

U_BOOT_SRC = $(wildcard patches/u-boot/*/*) \
  patches/u-boot/vivado_riscv64_defconfig \
  patches/u-boot/vivado_riscv64.h \
  patches/u-boot.patch

u-boot/configs/vivado_riscv64_defconfig: patches/u-boot/vivado_riscv64_defconfig Makefile
	cp patches/u-boot/vivado_riscv64_defconfig u-boot/configs
ifeq ($(ROOTFS),NFS)
	echo 'CONFIG_USE_BOOTARGS=y' >>u-boot/configs/vivado_riscv64_defconfig
	echo 'CONFIG_BOOTCOMMAND="booti $${kernel_addr_r} - $${fdt_addr}"' >>u-boot/configs/vivado_riscv64_defconfig
	echo 'CONFIG_BOOTARGS="root=/dev/nfs rootfstype=nfs rw nfsroot='$(ROOTFS_URL)',nolock,vers=4,tcp ip=dhcp earlycon console=ttyAU0,115200n8 locale.LANG=en_US.UTF-8"' >>u-boot/configs/vivado_riscv64_defconfig
else ifeq ($(JTAG_BOOT),1)
	echo 'CONFIG_USE_BOOTARGS=y' >>u-boot/configs/vivado_riscv64_defconfig
	echo 'CONFIG_BOOTCOMMAND="booti $${kernel_addr_r} $${ramdisk_addr_r} $${fdt_addr}"' >>u-boot/configs/vivado_riscv64_defconfig
	echo 'CONFIG_BOOTARGS="ro root=UUID=68d82fa1-1bb5-435f-a5e3-862176586eec earlycon initramfs.runsize=24M locale.LANG=en_US.UTF-8"' >>u-boot/configs/vivado_riscv64_defconfig
endif

u-boot-patch: u-boot/configs/vivado_riscv64_defconfig
	if [ -s patches/u-boot.patch ] ; then cd u-boot && ( git apply -R --check ../patches/u-boot.patch 2>/dev/null || git apply ../patches/u-boot.patch ) ; fi
	cp -p -r patches/u-boot/vivado_riscv64 u-boot/board/xilinx
	cp -p patches/u-boot/vivado_riscv64.h u-boot/include/configs

u-boot/u-boot-nodtb.bin: u-boot-patch $(U_BOOT_SRC)
	make -C u-boot CROSS_COMPILE=$(CROSS_COMPILE_LINUX) BOARD=vivado_riscv64 vivado_riscv64_config
	make -C u-boot \
	  BOARD=vivado_riscv64 \
	  CC=$(CROSS_COMPILE_LINUX)gcc-8 \
	  CROSS_COMPILE=$(CROSS_COMPILE_LINUX) \
	  KCFLAGS='-O1 -gno-column-info' \
	  all
	mkdir -p workspace/bin && cp u-boot/u-boot-nodtb.bin workspace/bin/u_boot



# --- build RISC-V Open Source Supervisor Binary Interface (OpenSBI) ---

bootloader: workspace/boot.elf

workspace/boot.elf: opensbi/build/platform/vivado-risc-v/firmware/fw_payload.elf
	mkdir -p workspace
	cp $< $@

opensbi/build/platform/vivado-risc-v/firmware/fw_payload.elf: $(wildcard patches/opensbi/*) u-boot/u-boot-nodtb.bin
	mkdir -p opensbi/platform/vivado-risc-v
	mkdir -p workspace/bin 
	cp -p patches/opensbi/* opensbi/platform/vivado-risc-v
	make -C opensbi CROSS_COMPILE=$(CROSS_COMPILE_LINUX) PLATFORM=vivado-risc-v \
	 FW_JUMP_ADDR=0x80200000 FW_PAYLOAD_PATH=`realpath u-boot/u-boot-nodtb.bin` 
	cp opensbi/build/platform/vivado-risc-v/firmware/fw_jump.bin workspace/bin/opensbi

integrated_launcher/gen/opensbi.h: bootloader
	mkdir -p boot/integrated_launcher/gen/
	cd workspace/bin && xxd -i opensbi > ../../boot/integrated_launcher/gen/opensbi.h
	sed -i 's/unsigned/const static unsigned/g' boot/integrated_launcher/gen/opensbi.h

integrated_launcher/gen/u_boot.h: bootloader
	mkdir -p boot/integrated_launcher/gen/
	cd workspace/bin && xxd -i u_boot > ../../boot/integrated_launcher/gen/u_boot.h
	sed -i 's/unsigned/const static unsigned/g' boot/integrated_launcher/gen/u_boot.h


workspace/bin/datgen:
	mkdir -p workspace/bin
	g++ -std=c++17 patches/datgen.cpp -o workspace/bin/datgen




# --- generate HDL ---

CONFIG_SCALA := $(subst rocket,Rocket,$(CONFIG))

# valid ROCKET_FREQ_MHZ values (MHz): 160 125 100 80 62.5 50 40 31.25 25 20
ROCKET_FREQ_MHZ ?= $(shell awk '$$3 != "" && "$(BOARD)" ~ $$1 && "$(CONFIG_SCALA)" ~ ("^" $$2 "$$") {print $$3; exit}' board/rocket-freq)

ROCKET_CLOCK_FREQ := $(shell echo - | awk '{printf("%.0f\n", $(ROCKET_FREQ_MHZ) * 1000000)}')
ROCKET_TIMEBASE_FREQ := $(shell echo - | awk '{printf("%.0f\n", $(ROCKET_FREQ_MHZ) * 10000)}')

MEMORY_SIZE ?= 0x40000000

ifneq ($(findstring Rocket32t,$(CONFIG_SCALA)),)
  CROSS_COMPILE_NO_OS_TOOLS = $(realpath workspace/gcc/riscv/bin)/riscv32-unknown-elf-
  CROSS_COMPILE_NO_OS_FLAGS = -march=rv32imac -mabi=ilp32 -DFF_FS_EXFAT=0
else ifneq ($(findstring Rocket32,$(CONFIG_SCALA)),)
  CROSS_COMPILE_NO_OS_TOOLS = $(realpath workspace/gcc/riscv/bin)/riscv32-unknown-elf-
  CROSS_COMPILE_NO_OS_FLAGS = -march=rv32imac -mabi=ilp32
else
  CROSS_COMPILE_NO_OS_TOOLS = $(realpath workspace/gcc/riscv/bin)/riscv64-unknown-elf-
  CROSS_COMPILE_NO_OS_FLAGS = -march=rv64imac -mabi=lp64
endif

ifeq ($(shell echo $$(($(MEMORY_SIZE) <= 0x80000000))),1)
  MEMORY_ADDR_RANGE = 0x80000000 $(MEMORY_SIZE)
  MEMORY_ADDR_RANGE32 = 0x80000000 $(MEMORY_SIZE)
else ifeq ($(shell echo $$(($(MEMORY_SIZE) / 0x100000000))),0)
  MEMORY_ADDR_RANGE = 0x80000000 0x80000000
  MEMORY_ADDR_RANGE32 = 0x80000000 0x80000000
else
  MEMORY_ADDR_RANGE = 0x0 0x80000000 $(shell echo - | awk '{printf "0x%x", $(MEMORY_SIZE) / 0x100000000 - 1}') 0x80000000
  MEMORY_ADDR_RANGE32 = 0x80000000 0x80000000
endif

SBT := java -Xmx8G -Xss8M $(JAVA_OPTIONS) -jar $(realpath rocket-chip/sbt-launch.jar)

CHISEL_SRC_DIRS = \
  src/main \
  rocket-chip/src/main \
  generators/gemmini/src/main \
  generators/riscv-boom/src/main \
  generators/sifive-cache/design/craft \
  generators/testchipip/src/main

CHISEL_SRC := $(foreach path, $(CHISEL_SRC_DIRS), $(shell test -d $(path) && find $(path) -iname "*.scala"))
FIRRTL = java -Xmx12G -Xss8M $(JAVA_OPTIONS) -cp target/scala-2.12/classes:rocket-chip/rocketchip.jar firrtl.stage.FirrtlMain

# Generate payload 
workspace/$(CONFIG)/payload.dat: workspace/bin/datgen integrated_launcher/gen/u_boot.h integrated_launcher/gen/opensbi.h
	make -C  boot/integrated_launcher  CROSS_COMPILE=$(CROSS_COMPILE_NO_OS_TOOLS)  all
	./workspace/bin/datgen boot/integrated_launcher/launcher.img > workspace/$(CONFIG)/payload.dat




# Generate default device tree - not including peripheral devices or board specific data
workspace/$(CONFIG)/system.dts: $(CHISEL_SRC) rocket-chip/bootrom/bootrom.img
	if [ -s patches/rocket-chip.patch ] ; then cd rocket-chip && ( git apply -R --check ../patches/rocket-chip.patch 2>/dev/null || git apply ../patches/rocket-chip.patch ) ; fi
	if [ -s patches/gemmini.patch ] ; then cd generators/gemmini && ( git apply -R --check ../../patches/gemmini.patch 2>/dev/null || git apply ../../patches/gemmini.patch ) ; fi
	mkdir -p workspace/$(CONFIG)/tmp
	cp rocket-chip/bootrom/bootrom.img workspace/bootrom.img
	$(SBT) "runMain freechips.rocketchip.system.Generator -td workspace/$(CONFIG)/tmp -T Vivado.RocketSystem -C Vivado.$(CONFIG_SCALA)"
	mv workspace/$(CONFIG)/tmp/Vivado.$(CONFIG_SCALA).anno.json workspace/$(CONFIG)/system.anno.json
	mv workspace/$(CONFIG)/tmp/Vivado.$(CONFIG_SCALA).dts workspace/$(CONFIG)/system.dts
	rm -rf workspace/$(CONFIG)/tmp

# Generate board specific device tree, boot ROM and FIRRTL
workspace/$(CONFIG)/system-$(BOARD)/Vivado.$(CONFIG_SCALA).fir: workspace/$(CONFIG)/system.dts $(wildcard bootrom/*) workspace/gcc/riscv
	mkdir -p workspace/$(CONFIG)/system-$(BOARD)
	cat workspace/$(CONFIG)/system.dts board/$(BOARD)/bootrom.dts >bootrom/system.dts
	sed -i "s#reg = <0x80000000 *0x.*>#reg = <$(MEMORY_ADDR_RANGE32)>#g" bootrom/system.dts
	sed -i "s#reg = <0x0 0x80000000 *0x.*>#reg = <$(MEMORY_ADDR_RANGE)>#g" bootrom/system.dts
	sed -i "s#clock-frequency = <[0-9]*>#clock-frequency = <$(ROCKET_CLOCK_FREQ)>#g" bootrom/system.dts
	sed -i "s#timebase-frequency = <[0-9]*>#timebase-frequency = <$(ROCKET_TIMEBASE_FREQ)>#g" bootrom/system.dts
	sed -i "s#local-mac-address = \[.*\]#local-mac-address = [$(ETHER_MAC)]#g" bootrom/system.dts
	sed -i "s#phy-mode = \".*\"#phy-mode = \"$(ETHER_PHY)\"#g" bootrom/system.dts
	sed -i "/interrupts-extended = <&.* 65535>;/d" bootrom/system.dts
	make -C bootrom CROSS_COMPILE="$(CROSS_COMPILE_NO_OS_TOOLS)" CFLAGS="$(CROSS_COMPILE_NO_OS_FLAGS)" BOARD=$(BOARD) INTEGRATED_LAUNCHER=1 clean bootrom.img
	mv bootrom/system.dts workspace/$(CONFIG)/system-$(BOARD).dts
	mv bootrom/bootrom.img workspace/bootrom.img
	$(SBT) "runMain freechips.rocketchip.system.Generator -td workspace/$(CONFIG)/system-$(BOARD) -T Vivado.RocketSystem -C Vivado.$(CONFIG_SCALA)"
	cd rocket-chip && $(SBT) assembly
	rm workspace/bootrom.img

# Generate Rocket SoC HDL
workspace/$(CONFIG)/system-$(BOARD).v: workspace/$(CONFIG)/system-$(BOARD)/Vivado.$(CONFIG_SCALA).fir
	$(FIRRTL) -i $< -o system-$(BOARD).v -X verilog --infer-rw RocketSystem --repl-seq-mem \
	  -c:RocketSystem:-o:workspace/$(CONFIG)/system.conf \
	  -faf workspace/$(CONFIG)/system.anno.json \
	  -td workspace/$(CONFIG)/ \
	  -fct firrtl.passes.InlineInstances
	rocket-chip/scripts/vlsi_mem_gen workspace/$(CONFIG)/system.conf >workspace/$(CONFIG)/srams.v
	rocket-chip/scripts/vlsi_rom_gen workspace/$(CONFIG)/system-$(BOARD)/Vivado.$(CONFIG_SCALA).rom.conf payload.dat > workspace/$(CONFIG)/payload.v


# Generate Rocket SoC wrapper for Vivado
workspace/$(CONFIG)/rocket.vhdl: workspace/$(CONFIG)/system-$(BOARD).v workspace/$(CONFIG)/payload.dat
	mkdir -p vhdl-wrapper/bin
	javac -g -nowarn \
	  -sourcepath vhdl-wrapper/src -d vhdl-wrapper/bin \
	  -classpath vhdl-wrapper/antlr-4.8-complete.jar \
	  vhdl-wrapper/src/net/largest/riscv/vhdl/Main.java
	java -Xmx4G -Xss8M $(JAVA_OPTIONS) -cp \
	  vhdl-wrapper/src:vhdl-wrapper/bin:vhdl-wrapper/antlr-4.8-complete.jar \
	  net.largest.riscv.vhdl.Main -m $(CONFIG_SCALA) \
	  workspace/$(CONFIG)/system-$(BOARD).v >$@

# --- utility make targets to run SBT command line ---

.PHONY: sbt rocket-sbt

sbt:
	$(SBT)

rocket-sbt:
	cd rocket-chip && $(SBT)

# --- generate Vivado Project ---

.PHONY: vivado-tcl vivado-project vivado-gui bitstream

proj_name = $(BOARD)-riscv
proj_path = workspace/$(CONFIG)/vivado-$(proj_name)
proj_file = $(proj_path)/$(proj_name).xpr
proj_time = $(proj_path)/timestamp.txt
synthesis = $(proj_path)/$(proj_name).runs/synth_1/riscv_wrapper.dcp
bitstream = $(proj_path)/$(proj_name).runs/impl_1/riscv_wrapper.bit
mcs_file  = workspace/$(CONFIG)/$(proj_name).mcs
prm_file  = workspace/$(CONFIG)/$(proj_name).prm
vivado    = env XILINX_LOCAL_USER_DATA=no vivado -mode batch -nojournal -nolog -notrace -quiet

workspace/$(CONFIG)/system-$(BOARD).tcl: workspace/$(CONFIG)/rocket.vhdl
	echo "set vivado_board_name $(BOARD)" >$@
	echo "set vivado_board_part $(BOARD_PART)" >>$@
	echo "set xilinx_part $(XILINX_PART)" >>$@
	echo "set rocket_module_name $(CONFIG_SCALA)" >>$@
	echo "set riscv_clock_frequency $(ROCKET_FREQ_MHZ)" >>$@
	echo 'cd [file dirname [file normalize [info script]]]' >>$@
	echo 'source ../../vivado.tcl' >>$@

vivado-tcl: workspace/$(CONFIG)/system-$(BOARD).tcl

$(proj_time): workspace/$(CONFIG)/system-$(BOARD).tcl
	if [ ! -e $(proj_path) ] ; then $(vivado) -source workspace/$(CONFIG)/system-$(BOARD).tcl ; fi
	date >$@

vivado-project: $(proj_time)

# --- generate FPGA bitstream ---

# Multi-threading appears broken in Vivado. It causes intermittent failures.
MAX_THREADS ?= 1

$(synthesis): $(proj_time)
	echo "open_project $(proj_file)" >$(proj_path)/make-synthesis.tcl
	echo "update_compile_order -fileset sources_1" >>$(proj_path)/make-synthesis.tcl
	echo "set_param general.maxThreads $(MAX_THREADS)" >>$(proj_path)/make-synthesis.tcl
	echo "reset_run synth_1" >>$(proj_path)/make-synthesis.tcl
	echo "launch_runs -jobs $(MAX_THREADS) synth_1" >>$(proj_path)/make-synthesis.tcl
	echo "wait_on_run synth_1" >>$(proj_path)/make-synthesis.tcl
	$(vivado) -source $(proj_path)/make-synthesis.tcl
	if find $(proj_path) -name "*.log" -exec cat {} \; | grep 'ERROR: ' ; then exit 1 ; fi

$(bitstream): $(synthesis)
	echo "open_project $(proj_file)" >$(proj_path)/make-bitstream.tcl
	echo "set_param general.maxThreads $(MAX_THREADS)" >>$(proj_path)/make-bitstream.tcl
	echo "reset_run impl_1" >>$(proj_path)/make-bitstream.tcl
	echo "launch_runs -to_step write_bitstream -jobs $(MAX_THREADS) impl_1" >>$(proj_path)/make-bitstream.tcl
	echo "wait_on_run impl_1" >>$(proj_path)/make-bitstream.tcl
	faketime '2021-12-24 08:15:42' $(vivado) -source $(proj_path)/make-bitstream.tcl
	if find $(proj_path) -name "*.log" -exec cat {} \; | grep 'ERROR: ' ; then exit 1 ; fi

$(mcs_file) $(prm_file): $(bitstream) workspace/boot.elf
	echo "open_project $(proj_file)" >$(proj_path)/make-mcs.tcl
	echo "write_cfgmem -format mcs -interface $(CFG_DEVICE) -loadbit {up 0x0 $(bitstream)} $(CFG_BOOT) -file $(mcs_file) -force" >>$(proj_path)/make-mcs.tcl
	$(vivado) -source $(proj_path)/make-mcs.tcl

bitstream: $(bitstream) $(mcs_file)

# --- program flash memory ---

flash: $(mcs_file) $(prm_file)
	env HW_SERVER_URL=tcp:$(HW_SERVER_ADDR) \
	 xsdb -quiet board/jtag-freq.tcl
	env HW_SERVER_ADDR=$(HW_SERVER_ADDR) \
	env CFG_PART=$(CFG_PART) \
	env mcs_file=$(mcs_file) \
	env prm_file=$(prm_file) \
	 $(vivado) -source board/program-flash.tcl

# --- program FPGA and boot Linux ---

debian-riscv64/ramdisk: debian-riscv64/initrd
ifeq ($(ROOTFS),NFS)
	mkdir -p debian-riscv64
	rm -f debian-riscv64/ramdisk
	dd if=/dev/zero of=debian-riscv64/ramdisk bs=32 count=1
else ifeq ($(JTAG_BOOT),1)
	mkimage -A riscv -T ramdisk -C gzip -d debian-riscv64/initrd debian-riscv64/ramdisk
else
	echo "JTAG boot requires either ROOTFS=NFS or JTAG_BOOT=1" && exit 1
endif

jtag-boot: $(bitstream) linux-stable/arch/riscv/boot/Image debian-riscv64/ramdisk workspace/boot.elf
	env HW_SERVER_URL=tcp:$(HW_SERVER_ADDR) \
	 xsdb -quiet board/jtag-freq.tcl
	env BITSTREAM=$(bitstream) \
	env HW_SERVER_URL=tcp:$(HW_SERVER_ADDR) \
	 xsdb -quiet board/jtag-boot.tcl

# --- launch Vivado GUI ---

vivado-gui: $(proj_time)
	vivado $(proj_file)
