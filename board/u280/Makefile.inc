BOARD_PART  ?= xilinx.com:au280:part0:1.1
XILINX_PART ?= xcu280-fsvh2892-2L-e
CFG_DEVICE  ?= SPIx4 -size 128
CFG_PART    ?= mt25qu01g-spi-x1_x2_x4
CFG_BOOT    ?= -loaddata {up 0x07000000 workspace/boot.elf}
MEMORY_SIZE ?= 0x800000000
ETHER_MAC   ?= 00 0a 35 00 00 03
ETHER_PHY   ?= 10gbase-r
