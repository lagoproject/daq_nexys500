#========================================================
# Makefile para crear firmwares para las placas Nexys2  =
#                                                       =
# Es necesario correr al menos una vez el proyecto en   =
# soft ISE de Xilinx y luego, a partir de allí realizar =
# proyectos con este make.                              =
# Para seleccionar si se quiere grabar el firmware en   =
# la FPGA o en la memoria EEPROM, es necesario correr   =
#														=
# make STARTUP_CLK=x				        			=
# Donde x puede ser jtag o cclk							=
#                                                       = 
# Horacio Arnaldi                                       =
# DPR Lab                                               =
# 05/12/2011                                            =
# Última revisión: 19/01/2012							=
#														=
#========================================================
TOP_LEVEL = lago_fpga_vhdl
GATES = 500
PLATFORM = nexys2_$(GATES)
STARTUP_CLK = jtag

ifeq ($(PLATFORM),nexys2_500)
	FPGA = xc3s500e-fg320-4
endif
ifeq ($(PLATFORM),nexys2_1200)
	FPGA = xc3s1200e-fg320-4
endif
ifeq ($(STARTUP_CLK),jtag)
	CLOCK = JtagClk

endif
ifeq ($(STARTUP_CLK),cclk)
	CLOCK = CClk
endif

all: $(TOP_LEVEL).xsvf

report: $(TOP_LEVEL).twr

# This assumes that the "XILINX" environment variable is set 
$(TOP_LEVEL).xsvf: $(PLATFORM).batch $(TOP_LEVEL).bit
	cat $< | sed s#\$${XILINX}#$(subst \,/,$(XILINX))#g > temp.batch
	impact -batch temp.batch
	rm -f temp.batch

$(TOP_LEVEL).bit: $(TOP_LEVEL).ut $(TOP_LEVEL).ncd
	bitgen -intstyle ise -f $+

$(TOP_LEVEL).twr: $(TOP_LEVEL).ncd $(TOP_LEVEL).ucf
	trce -intstyle ise -v 3 -s 4 -n 3 -fastpaths -xml ${TOP_LEVEL}.twx $< -o $@ ${TOP_LEVEL}.pcf -ucf $(TOP_LEVEL).ucf

$(TOP_LEVEL).ncd: $(TOP_LEVEL)_map.ncd
	par -w -intstyle ise -ol high -t 1 $< $@ ${TOP_LEVEL}.pcf

$(TOP_LEVEL)_map.ncd: $(TOP_LEVEL).ngd
	map -intstyle ise -p $(FPGA) -cm area -ir off -pr off -c 100 -o $@ $< ${TOP_LEVEL}.pcf

$(TOP_LEVEL).ngd: $(TOP_LEVEL).ngc $(TOP_LEVEL).ucf
	ngdbuild -intstyle ise -dd _ngo -sd ipcore_dir -nt timestamp -uc $(TOP_LEVEL).ucf -p $(FPGA) $< $@

$(TOP_LEVEL).ngc: $(TOP_LEVEL).xst $(TOP_LEVEL).prj
	mkdir -p xst/projnav.tmp
	xst -intstyle ise -ifn $< -ofn $(TOP_LEVEL).syr

$(TOP_LEVEL).ut:
	echo "-w" > $@
	echo "-g DebugBitstream:No" >> $@
	echo "-g Binary:no" >> $@
	echo "-g CRC:Enable" >> $@
	echo "-g ConfigRate:1" >> $@
	echo "-g ProgPin:PullUp" >> $@
	echo "-g DonePin:PullUp" >> $@
	echo "-g TckPin:PullUp" >> $@
	echo "-g TdiPin:PullUp" >> $@
	echo "-g TdoPin:PullUp" >> $@
	echo "-g TmsPin:PullUp" >> $@
	echo "-g UnusedPin:PullDown" >> $@
	echo "-g UserID:0xFFFFFFFF" >> $@
	echo "-g DCMShutdown:Disable" >> $@
	echo "-g StartUpClk:$(CLOCK)" >> $@
	echo "-g DONE_cycle:4" >> $@
	echo "-g GTS_cycle:5" >> $@
	echo "-g GWE_cycle:6" >> $@
	echo "-g LCK_cycle:NoWait" >> $@
	echo "-g Security:None" >> $@
	echo "-g DonePipe:No" >> $@
	echo "-g DriveDone:No" >> $@

clean: FORCE
	rm -rf *.ut *.xsvf *.csvf _ngo *.bgn *.drc *.ncd *.ntrc_log *.twr *.csv *.html fx2fpga_xdb _xmsgs *.bit *.gise *.ngc *.pad *.ptwx *.twx *.ngm *.txt *.xml *.xrpt *.bld *.ise *.ngd *.par *.stx *.map *.twr auto_project_xdb *.cmd_log *.lso *.ngr *.pcf *.syr *.unroutes *.xpi *.mrp xst *.log *.cmd *.xwbt iseconfig xlnx_auto_0_xdb

FORCE:
