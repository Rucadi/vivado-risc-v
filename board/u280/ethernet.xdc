
# QSFP28 Interfaces
set_property -dict {LOC L53 } [get_ports qsfp0_rx1_p] ;# MGTYRXP0_134 GTYE4_CHANNEL_X0Y40 / GTYE4_COMMON_X0Y10
set_property -dict {LOC L54 } [get_ports qsfp0_rx1_n] ;# MGTYRXN0_134 GTYE4_CHANNEL_X0Y40 / GTYE4_COMMON_X0Y10
set_property -dict {LOC L48 } [get_ports qsfp0_tx1_p] ;# MGTYTXP0_134 GTYE4_CHANNEL_X0Y40 / GTYE4_COMMON_X0Y10
set_property -dict {LOC L49 } [get_ports qsfp0_tx1_n] ;# MGTYTXN0_134 GTYE4_CHANNEL_X0Y40 / GTYE4_COMMON_X0Y10
#set_property -dict {LOC K51 } [get_ports qsfp0_rx2_p] ;# MGTYRXP1_134 GTYE4_CHANNEL_X0Y41 / GTYE4_COMMON_X0Y10
#set_property -dict {LOC K52 } [get_ports qsfp0_rx2_n] ;# MGTYRXN1_134 GTYE4_CHANNEL_X0Y41 / GTYE4_COMMON_X0Y10
#set_property -dict {LOC L44 } [get_ports qsfp0_tx2_p] ;# MGTYTXP1_134 GTYE4_CHANNEL_X0Y41 / GTYE4_COMMON_X0Y10
#set_property -dict {LOC L45 } [get_ports qsfp0_tx2_n] ;# MGTYTXN1_134 GTYE4_CHANNEL_X0Y41 / GTYE4_COMMON_X0Y10
#set_property -dict {LOC J53 } [get_ports qsfp0_rx3_p] ;# MGTYRXP2_134 GTYE4_CHANNEL_X0Y42 / GTYE4_COMMON_X0Y10
#set_property -dict {LOC J54 } [get_ports qsfp0_rx3_n] ;# MGTYRXN2_134 GTYE4_CHANNEL_X0Y42 / GTYE4_COMMON_X0Y10
#set_property -dict {LOC K46 } [get_ports qsfp0_tx3_p] ;# MGTYTXP2_134 GTYE4_CHANNEL_X0Y42 / GTYE4_COMMON_X0Y10
#set_property -dict {LOC K47 } [get_ports qsfp0_tx3_n] ;# MGTYTXN2_134 GTYE4_CHANNEL_X0Y42 / GTYE4_COMMON_X0Y10
#set_property -dict {LOC H51 } [get_ports qsfp0_rx4_p] ;# MGTYRXP3_134 GTYE4_CHANNEL_X0Y43 / GTYE4_COMMON_X0Y10
#set_property -dict {LOC H52 } [get_ports qsfp0_rx4_n] ;# MGTYRXN3_134 GTYE4_CHANNEL_X0Y43 / GTYE4_COMMON_X0Y10
#set_property -dict {LOC J48 } [get_ports qsfp0_tx4_p] ;# MGTYTXP3_134 GTYE4_CHANNEL_X0Y43 / GTYE4_COMMON_X0Y10
#set_property -dict {LOC J49 } [get_ports qsfp0_tx4_n] ;# MGTYTXN3_134 GTYE4_CHANNEL_X0Y43 / GTYE4_COMMON_X0Y10
#set_property -dict {LOC T42 } [get_ports qsfp0_mgt_refclk_0_p] ;# MGTREFCLK0P_134 from SI570
#set_property -dict {LOC T43 } [get_ports qsfp0_mgt_refclk_0_n] ;# MGTREFCLK0N_134 from SI570
set_property -dict {LOC R40 } [get_ports qsfp0_mgt_refclk_1_p] ;# MGTREFCLK1P_134 from SI546
set_property -dict {LOC R41 } [get_ports qsfp0_mgt_refclk_1_n] ;# MGTREFCLK1N_134 from SI546
set_property -dict {LOC H32 IOSTANDARD LVCMOS18} [get_ports qsfp0_refclk_oe_b]
set_property -dict {LOC G32 IOSTANDARD LVCMOS18} [get_ports qsfp0_refclk_fs]

# 156.25 MHz MGT reference clock (from SI570)
#create_clock -period 6.400 -name qsfp0_mgt_refclk_0 [get_ports qsfp0_mgt_refclk_0_p]

# 156.25 MHz MGT reference clock (from SI546, fs = 0)
#create_clock -period 6.400 -name qsfp0_mgt_refclk_1 [get_ports qsfp0_mgt_refclk_1_p]

# 161.1328125 MHz MGT reference clock (from SI546, fs = 1)
create_clock -period 6.206 -name qsfp0_mgt_refclk_1 [get_ports qsfp0_mgt_refclk_1_p]

set_false_path -to [get_ports {qsfp0_refclk_oe_b qsfp0_refclk_fs}]
set_output_delay 0 [get_ports {qsfp0_refclk_oe_b qsfp0_refclk_fs}]

set_property -dict {LOC G53 } [get_ports qsfp1_rx1_p] ;# MGTYRXP0_135 GTYE4_CHANNEL_X0Y44 / GTYE4_COMMON_X0Y11
set_property -dict {LOC G54 } [get_ports qsfp1_rx1_n] ;# MGTYRXN0_135 GTYE4_CHANNEL_X0Y44 / GTYE4_COMMON_X0Y11
set_property -dict {LOC G48 } [get_ports qsfp1_tx1_p] ;# MGTYTXP0_135 GTYE4_CHANNEL_X0Y44 / GTYE4_COMMON_X0Y11
set_property -dict {LOC G49 } [get_ports qsfp1_tx1_n] ;# MGTYTXN0_135 GTYE4_CHANNEL_X0Y44 / GTYE4_COMMON_X0Y11
#set_property -dict {LOC F51 } [get_ports qsfp1_rx2_p] ;# MGTYRXP1_135 GTYE4_CHANNEL_X0Y45 / GTYE4_COMMON_X0Y11
#set_property -dict {LOC F52 } [get_ports qsfp1_rx2_n] ;# MGTYRXN1_135 GTYE4_CHANNEL_X0Y45 / GTYE4_COMMON_X0Y11
#set_property -dict {LOC E48 } [get_ports qsfp1_tx2_p] ;# MGTYTXP1_135 GTYE4_CHANNEL_X0Y45 / GTYE4_COMMON_X0Y11
#set_property -dict {LOC E49 } [get_ports qsfp1_tx2_n] ;# MGTYTXN1_135 GTYE4_CHANNEL_X0Y45 / GTYE4_COMMON_X0Y11
#set_property -dict {LOC E53 } [get_ports qsfp1_rx3_p] ;# MGTYRXP2_135 GTYE4_CHANNEL_X0Y46 / GTYE4_COMMON_X0Y11
#set_property -dict {LOC E54 } [get_ports qsfp1_rx3_n] ;# MGTYRXN2_135 GTYE4_CHANNEL_X0Y46 / GTYE4_COMMON_X0Y11
#set_property -dict {LOC C48 } [get_ports qsfp1_tx3_p] ;# MGTYTXP2_135 GTYE4_CHANNEL_X0Y46 / GTYE4_COMMON_X0Y11
#set_property -dict {LOC C49 } [get_ports qsfp1_tx3_n] ;# MGTYTXN2_135 GTYE4_CHANNEL_X0Y46 / GTYE4_COMMON_X0Y11
#set_property -dict {LOC D51 } [get_ports qsfp1_rx4_p] ;# MGTYRXP3_135 GTYE4_CHANNEL_X0Y47 / GTYE4_COMMON_X0Y11
#set_property -dict {LOC D52 } [get_ports qsfp1_rx4_n] ;# MGTYRXN3_135 GTYE4_CHANNEL_X0Y47 / GTYE4_COMMON_X0Y11
#set_property -dict {LOC A49 } [get_ports qsfp1_tx4_p] ;# MGTYTXP3_135 GTYE4_CHANNEL_X0Y47 / GTYE4_COMMON_X0Y11
#set_property -dict {LOC A50 } [get_ports qsfp1_tx4_n] ;# MGTYTXN3_135 GTYE4_CHANNEL_X0Y47 / GTYE4_COMMON_X0Y11
#set_property -dict {LOC P42 } [get_ports qsfp1_mgt_refclk_0_p] ;# MGTREFCLK0P_135 from SI570
#set_property -dict {LOC P43 } [get_ports qsfp1_mgt_refclk_0_n] ;# MGTREFCLK0N_135 from SI570
set_property -dict {LOC M42 } [get_ports qsfp1_mgt_refclk_1_p] ;# MGTREFCLK1P_135 from SI546
set_property -dict {LOC M43 } [get_ports qsfp1_mgt_refclk_1_n] ;# MGTREFCLK1N_135 from SI546
set_property -dict {LOC H30 IOSTANDARD LVCMOS18} [get_ports qsfp1_refclk_oe_b]
set_property -dict {LOC G33 IOSTANDARD LVCMOS18} [get_ports qsfp1_refclk_fs]

# 156.25 MHz MGT reference clock (from SI570)
#create_clock -period 6.400 -name qsfp1_mgt_refclk_0 [get_ports qsfp1_mgt_refclk_0_p]

# 156.25 MHz MGT reference clock (from SI546, fs = 0)
#create_clock -period 6.400 -name qsfp1_mgt_refclk_1 [get_ports qsfp1_mgt_refclk_1_p]

# 161.1328125 MHz MGT reference clock (from SI546, fs = 1)
create_clock -period 6.206 -name qsfp1_mgt_refclk_1 [get_ports qsfp1_mgt_refclk_1_p]

set_false_path -to [get_ports {qsfp1_refclk_oe_b qsfp1_refclk_fs}]
set_output_delay 0 [get_ports {qsfp1_refclk_oe_b qsfp1_refclk_fs}]