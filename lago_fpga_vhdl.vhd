--
-- Copyright (C) 2011 Horacio Arnaldi
-- e-mail: lharnaldi@cab.cnea.gov.ar
--
-- Laboratorio de Detección de Partículas y Radiación
-- Centro Atómico Bariloche
-- Comisión Nacional de Energía Atómica (CNEA)
-- San Carlos de Bariloche
-- Date: 26/09/2011
-- Ver: v1r7  -- 
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--  
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lago_fpga_vhdl is
	generic (
    VER 							: natural := 2;			--Code Version
    REV 							: natural := 0;			--Code Revision
    RESET_POLARITY		: std_logic := '1';	--Polarity of reset signal
    W                 : natural := 5;			--Number of addres bits. 2**W = 32 addres for W=5
    ADCBITS           : natural := 10;		--Number of ADC bits
    L_ARRAY_MUESTRAS  : natural := 12;		--Samples Longitude of 
    L_ARRAY_PPS       : natural := 10;		--PPS longitude array
    L_ARRAY_SCALERS   : natural := 3;			--Scalers longitude array
    RBITS             : natural := 12; 		-- := 12;  -- numero de bits de los registros
    REFRESH_RATE      : natural	:= 80000; -- := 80000; -- 80000 clk implican un refresh rate de 2ms (80000 * 25 ns = 2ms)
    NCH               : natural := 3 --:= 3     -- numero de canales de la electronica
  );

	port(
	-- Main 50 MHz clk
	clk_50m                                          : in    std_logic;
	-- Reset button (BTN0)
	reset                                            : in    std_logic;

	-- USB interface
	u_ifclk                                          : in    std_logic;

	-- Data & control from the FX2
	u_flagb                                          : in    std_logic;         -- EP2 empty, active low
	u_flagc                                          : in    std_logic;         -- EP6 full, active low
	u_fd                                             : inout std_logic_vector(7 downto 0);

	-- Control to the FX2
	u_fifoad                                         : out   std_logic_vector(1 downto 0);
	u_sloe                                           : out   std_logic;
	u_slrd                                           : out   std_logic;         -- active low
	u_slwr                                           : out   std_logic;         -- active low
	u_pktend                                         : out   std_logic;         -- active low
	-- ADC inputs and clocks
	ch1                                              : in    std_logic_vector(9 downto 0);
	ch2                                              : in    std_logic_vector(9 downto 0);
	ch3                                              : in    std_logic_vector(9 downto 0);
	adc_clk1                                         : out   std_logic;
	adc_clk2                                         : out   std_logic;
	adc_clk3                                         : out   std_logic;

	-- SPI outputs
	cs_e2prom                                        : out   std_logic;
	cs_max5501                                       : out   std_logic;
	spi_dout                                         : out   std_logic;
	spi_sck                                          : out   std_logic;

	-- PWM outputs
	hv2                                              : out   std_logic;
	hv3                                              : out   std_logic;

	-- I2C and HP03 related signals
	pSDA                                             : inout std_logic;
	pSCL                                             : out	std_logic;
	pXCLR                                            : out		std_logic;
	pMCLK                                            : out		std_logic;

	--GPS realted signals
	GPSen                                            : in	std_logic;

	-- 1PPS signal
	pps_port                                         : in	std_logic;

	--UART ports
	tx_uart                                          : out		std_logic;
	rx_uart                                          : in	std_logic;

	--Copy of GPS received signals to sync two Nexys
	rx_uart_copy                                     : inout std_logic;
	pps_port_copy                                    : inout std_logic;

 	--BCD leds dirvers
  an                                               : out std_logic_vector(3 downto 0);
  seg                                              : out std_logic_vector(6 downto 0);
  dp                                               : out std_logic;


	-- Status signals
	led                                              : out   std_logic_vector(7 downto 0)
	);
end lago_fpga_vhdl;

architecture rtl of lago_fpga_vhdl is

	component clk_40mhz
		port(
			clk_50mhz		: in  	std_logic;
			clk_40mhz  		: out 	std_logic);
	end component;

	signal sclk40m                                     : std_logic;
	-- Trigger related signals
	signal sT1, sT2, sT3                               : std_logic_vector(9 downto 0);
	-- SubTrigger related signals
	signal ssubT1, ssubT2, ssubT3                      : std_logic_vector(9 downto 0);
	signal swr_fifo_A, swr_fifo_B                      : std_logic;
	signal sBL1, sBL2, sBL3, siHV1                     : std_logic_vector(11 downto 0);
	signal siHV2, siHV3, soHV1, soHV2, soHV3           : std_logic_vector(11 downto 0);
	signal sfifo_in                                    : std_logic_vector(31 downto 0);
	signal sfifo_status                                : std_logic_vector(7 downto 0);
	signal sstatus_port, srx_data, sout_port           : std_logic_vector(7 downto 0);
	signal swrite_to_fifo, sread_from_fifo             : std_logic;
	--HP03 related signals
	signal sC1, sC2, sC3, sC4, sC5, sC6, sC7, sD1, sD2 : std_logic_vector(15 downto 0);
	signal sA, sB, sC, sD                              : std_logic_vector(7 downto 0);
	--GPS realted signals
	signal sutcngps                                    : std_logic;
	signal smonth                                      : std_logic_vector(7 downto 0);
	signal sday                                        : std_logic_vector(7 downto 0);
	signal syear1                                      : std_logic_vector(7 downto 0);
	signal syear2                                      : std_logic_vector(7 downto 0);
	signal shours                                      : std_logic_vector(7 downto 0);
	signal sminutes                                    : std_logic_vector(7 downto 0);
	signal sseconds                                    : std_logic_vector(7 downto 0);
	signal sfract_sec1                                 : std_logic_vector(7 downto 0);
	signal sfract_sec2                                 : std_logic_vector(7 downto 0);
	signal sfract_sec3                                 : std_logic_vector(7 downto 0);
	signal sfract_sec4                                 : std_logic_vector(7 downto 0);
	signal slatitude1                                  : std_logic_vector(7 downto 0);
	signal slatitude2                                  : std_logic_vector(7 downto 0);
	signal slatitude3                                  : std_logic_vector(7 downto 0);
	signal slatitude4                                  : std_logic_vector(7 downto 0);
	signal slongitude1                                 : std_logic_vector(7 downto 0);
	signal slongitude2                                 : std_logic_vector(7 downto 0);
	signal slongitude3                                 : std_logic_vector(7 downto 0);
	signal slongitude4                                 : std_logic_vector(7 downto 0);
	signal sellipsoid1                                 : std_logic_vector(7 downto 0);
	signal sellipsoid2                                 : std_logic_vector(7 downto 0);
	signal sellipsoid3                                 : std_logic_vector(7 downto 0);
	signal sellipsoid4                                 : std_logic_vector(7 downto 0);
	signal svelocity1                                  : std_logic_vector(7 downto 0);
	signal svelocity2                                  : std_logic_vector(7 downto 0);
	signal sheading1                                   : std_logic_vector(7 downto 0);
	signal sheading2                                   : std_logic_vector(7 downto 0);
	signal sgeometry2                                  : std_logic_vector(7 downto 0);
	signal sDOP_type                                   : std_logic_vector(7 downto 0);
	signal sNVS                                        : std_logic_vector(7 downto 0);
	signal sNTS                                        : std_logic_vector(7 downto 0);
	signal ssat_ID1                                    : std_logic_vector(7 downto 0);
	signal schtm1                                      : std_logic_vector(7 downto 0);
	signal sCNo1                                       : std_logic_vector(7 downto 0);
	signal schsf1                                      : std_logic_vector(7 downto 0);
	signal ssat_ID2                                    : std_logic_vector(7 downto 0);
	signal schtm2                                      : std_logic_vector(7 downto 0);
	signal sCNo2                                       : std_logic_vector(7 downto 0);
	signal schsf2                                      : std_logic_vector(7 downto 0);
	signal ssat_ID3                                    : std_logic_vector(7 downto 0);
	signal schtm3                                      : std_logic_vector(7 downto 0);
	signal sCNo3                                       : std_logic_vector(7 downto 0);
	signal schsf3                                      : std_logic_vector(7 downto 0);
	signal ssat_ID4                                    : std_logic_vector(7 downto 0);
	signal schtm4                                      : std_logic_vector(7 downto 0);
	signal sCNo4                                       : std_logic_vector(7 downto 0);
	signal schsf4                                      : std_logic_vector(7 downto 0);
	signal ssat_ID5                                    : std_logic_vector(7 downto 0);
	signal schtm5                                      : std_logic_vector(7 downto 0);
	signal sCNo5                                       : std_logic_vector(7 downto 0);
	signal schsf5                                      : std_logic_vector(7 downto 0);
	signal ssat_ID6                                    : std_logic_vector(7 downto 0);
	signal schtm6                                      : std_logic_vector(7 downto 0);
	signal sCNo6                                       : std_logic_vector(7 downto 0);
	signal schsf6                                      : std_logic_vector(7 downto 0);
	signal ssat_ID7                                    : std_logic_vector(7 downto 0);
	signal schtm7                                      : std_logic_vector(7 downto 0);
	signal sCNo7                                       : std_logic_vector(7 downto 0);
	signal schsf7                                      : std_logic_vector(7 downto 0);
	signal ssat_ID8                                    : std_logic_vector(7 downto 0);
	signal schtm8                                      : std_logic_vector(7 downto 0);
	signal sCNo8                                       : std_logic_vector(7 downto 0);
	signal schsf8                                      : std_logic_vector(7 downto 0);
	signal srsf                                        : std_logic_vector(7 downto 0);
	signal HV1_led, HV2_led, HV3_led                   : std_logic;
	signal stick_2ms																	 : std_logic;

begin

  -- BCD drivers
  an  <= (others => '0');
  seg <= (others => '1');
  dp  <= '1';

	rx_uart_copy 	<= rx_uart;
	pps_port_copy 	<= pps_port;
	led(0) <= sfifo_status(0);
	led(1) <= sfifo_status(1);
	led(2) <= sfifo_status(2);
	led(4) <= pps_port;
	led(5) <= HV3_led;
	led(6) <= HV2_led;
	led(7) <= HV1_led;
	adc_clk1 		<= sclk40m;
	adc_clk2 		<= sclk40m;
	adc_clk3 		<= sclk40m;

	clk40mgen: clk_40mhz
	port map(
						clk_50mhz 			=> clk_50m,
						clk_40mhz 			=> sclk40m);

	USB_interface: entity work.usb_if_ctrl
  generic map(
    VER 					=> VER,
    REV 					=> REV,
    RESET_POLARITY	=> RESET_POLARITY
	)

	port map(
		reset   		=> reset,
		u_ifclk         => u_ifclk,
		u_fd       		=> u_fd,
		u_flagc     	=> u_flagc,
		u_flagb     	=> u_flagb,
		u_sloe      	=> u_sloe,
		u_slrd      	=> u_slrd,
		u_slwr      	=> u_slwr,
		u_fifoad    	=> u_fifoad,
		u_pktend    	=> u_pktend,
		T1         		=> sT1, 
		T2         		=> sT2, 
		T3         		=> sT3,
		subT1				=> ssubT1,
		subT2				=> ssubT2,
		subT3				=> ssubT3,
		BL1        		=> sBL1, 
		BL2        		=> sBL2, 
		BL3        		=> sBL3, 
		HV1        		=> siHV1,
		HV2        		=> siHV2, 
		HV3        		=> siHV3,
		clk40m     		=> sclk40m,
		fifo_A     		=> sfifo_in, 
		we_A 				=> swr_fifo_A,
--HP03 signals	
		pC1				=> sC1,
		pC2				=> sC2,
		pC3				=> sC3,
		pC4				=> sC4,
		pC5				=> sC5,
		pC6				=> sC6,
		pC7				=> sC7,
		pA					=> sA,
		pB					=> sB,
		pC					=> sC,
		pD					=> sD,
		pD1				=> sD1,
		pD2				=> sD2,
--GPS signals
		UTCnGPS			=> sutcngps,
		month_port		=> smonth,
		day_port			=> sday,
		year1_port     	=> syear1,
		year2_port			=> syear2,
		hours_port			=> shours,
		minutes_port		=> sminutes,
		seconds_port		=> sseconds,
		fract_sec1_port		=> sfract_sec1,
		fract_sec2_port		=> sfract_sec2,
		fract_sec3_port		=> sfract_sec3,
		fract_sec4_port		=> sfract_sec4,
		latitude1_port		=> slatitude1,
		latitude2_port		=> slatitude2,
		latitude3_port		=> slatitude3,
		latitude4_port		=> slatitude4,
		longitude1_port		=> slongitude1,
		longitude2_port		=> slongitude2,
		longitude3_port		=> slongitude3,
		longitude4_port		=> slongitude4,
		ellipsoid1_port		=> sellipsoid1,
		ellipsoid2_port		=> sellipsoid2,
		ellipsoid3_port		=> sellipsoid3,
		ellipsoid4_port		=> sellipsoid4,
		velocity1_port		=> svelocity1,
		velocity2_port		=> svelocity2,
		heading1_port		=> sheading1,
		heading2_port		=> sheading2,
		geometry2_port		=> sgeometry2,
		DOP_type_port		=> sDOP_type,
		num_vis_sat_port	=> sNVS,
		num_track_sat_port	=> sNTS,

		sat_ID1_port	=> ssat_ID1,
		chtm1_port		=> schtm1,
		CNo1_port		=> sCNo1,
		chsf1_port		=> schsf1,

		sat_ID2_port	=> ssat_ID2,
		chtm2_port		=> schtm2,
		CNo2_port		=> sCNo2,
		chsf2_port		=> schsf2,

		sat_ID3_port	=> ssat_ID3,
		chtm3_port		=> schtm3,
		CNo3_port		=> sCNo3,
		chsf3_port		=> schsf3,

		sat_ID4_port	=> ssat_ID4,
		chtm4_port		=> schtm4,
		CNo4_port		=> sCNo4,
		chsf4_port		=> schsf4,

		sat_ID5_port	=> ssat_ID5,
		chtm5_port		=> schtm5,
		CNo5_port		=> sCNo5,
		chsf5_port		=> schsf5,

		sat_ID6_port	=> ssat_ID6,
		chtm6_port		=> schtm6,
		CNo6_port		=> sCNo6,
		chsf6_port		=> schsf6,

		sat_ID7_port	=> ssat_ID7,
		chtm7_port		=> schtm7,
		CNo7_port		=> sCNo7,
		chsf7_port		=> schsf7,

		sat_ID8_port	=> ssat_ID8,
		chtm8_port		=> schtm8,
		CNo8_port		=> sCNo8,
		chsf8_port		=> schsf8,

		rsf_port		=> srsf,
		pfifo_status	=> sfifo_status);

	ramp_ctrl1: entity work.ramp
  generic map (
    N	=> 18,    
    M	=> 200000,
    P => 12
	)
	port map(
		clk				=> sclk40m,
		reset				=> reset,
		data_in			=> siHV1,
		data_out			=> soHV1,
		pwm_pulse		=> open,
		led_indicador	=> HV1_led);

	ramp_ctrl2: entity work.ramp
  generic map (
    N	=> 18,    
    M	=> 200000,
    P => 12
	)
	port map(
		clk				=> sclk40m,
		reset				=> reset,
		data_in			=> siHV2,
		data_out			=> open,
		pwm_pulse		=> hv2,
		led_indicador	=> HV2_led);

	ramp_ctrl3: entity work.ramp
  generic map (
    N	=> 18,    
    M	=> 200000,
    P => 12
	)
	port map(
		clk				=> sclk40m,
		reset				=> reset,
		data_in			=> siHV3,
		data_out			=> open,
		pwm_pulse		=> hv3,
		led_indicador	=> HV3_led);

	baseline: entity work.baseline_control
	generic map (
    W               => W,
    ADCBITS         => ADCBITS,
    RBITS           => RBITS,
    REFRESH_RATE    => REFRESH_RATE,
    NCH             => NCH
	)
	port map(
		clk_40mhz		=> sclk40m,
		reset				=> reset,
		ptick_2ms		=> stick_2ms,
		data_adc1		=> ch1,
		data_adc2		=> ch2,
		data_adc3		=> ch3,
		baseline1   	=> sBL1,
		baseline2   	=> sBL2,
		baseline3  	 	=> sBL3);
		
	spi_controller: entity work.interfaz_spi
	port map(
		clk   			=> sclk40m,
		reset   			=> reset,
		ptick_2ms		=> stick_2ms,
		data_dac1  		=> sBL3, --"011010001010",
		data_dac2  		=> sBL2,--"011010001010",
		data_dac3  		=> soHV1,
		data_dac4  		=> sBL1,--"011010001010",
		cs_e2prom  		=> cs_e2prom,
		spi_csn		 	=> cs_max5501,
		spi_sdo   		=> spi_dout,
		spi_clk    		=> spi_sck);

	comp_trigger: entity work.trigger_in
	generic map(
    W 								=> W,    
    ADCBITS 					=> ADCBITS,
    L_ARRAY_MUESTRAS  => L_ARRAY_MUESTRAS,
    L_ARRAY_PPS 			=> L_ARRAY_PPS,
    L_ARRAY_SCALERS 	=> L_ARRAY_SCALERS
	)
	port map(
		clk_40mhz   		=> sclk40m,
		reset					=> reset,
		data_adc1   		=> ch1,
		data_adc2   		=> ch2,
		data_adc3   		=> ch3,
		trigg_set1  		=> sT1,
		trigg_set2  		=> sT2,
		trigg_set3  		=> sT3,
		subtrigg_set1  	=> ssubT1,
		subtrigg_set2  	=> ssubT2,
		subtrigg_set3  	=> ssubT3,
		pwr_enA     		=> swr_fifo_A,
		data_out    		=> sfifo_in,
		pfifo_status		=> sfifo_status(2 downto 0),
		ptemperatura		=> sD2,
		ppresion				=> sD1,
		phora					=> shours,
		pminutos				=> sminutes,
		psegundos			=> sseconds,
		pps_signal			=> pps_port,
		gpsen					=> GPSen,
		pps_falso_led		=> led(3),
		latitude1_port		=> slatitude1,
		latitude2_port		=> slatitude2,
		latitude3_port		=> slatitude3,
		latitude4_port		=> slatitude4,
		longitude1_port		=> slongitude1,
		longitude2_port		=> slongitude2,
		longitude3_port		=> slongitude3,
		longitude4_port		=> slongitude4,
		ellipsoid1_port		=> sellipsoid1,
		ellipsoid2_port		=> sellipsoid2,
		ellipsoid3_port		=> sellipsoid3,
		ellipsoid4_port		=> sellipsoid4,
		num_vis_sat_port	=> sNVS,
		num_track_sat_port	=> sNTS,
		rsf_port		=> srsf);

	hp03_controller: entity work.HP03_cntrl
	Port map ( 	
		clk			=> clk_50m,
		SDA			=> pSDA,
		SCL			=> pSCL,
		XCLR		=> pXCLR,
		MCLK		=> pMCLK,
		C1			=> sC1,
		C2			=> sC2,
		C3		 	=> sC3,
		C4		 	=> sC4,
		C5		 	=> sC5,
		C6		 	=> sC6,
		C7		 	=> sC7,
		A		 	=> sA,
		B		 	=> sB,
		C		 	=> sC,
		D		 	=> sD,
		D1		 	=> sD1,
		D2		 	=> sD2);

	gps_interface: entity work.Oncore_ctrl
	port map(
		clk					=> clk_50m,
		tx_female			=> tx_uart,
		rx_female			=> rx_uart,
		UTCnGPS				=> sutcngps,
		month_port			=> smonth,
		day_port			=> sday,
		year1_port     		=> syear1,
		year2_port			=> syear2,
		hours_port			=> shours,
		minutes_port		=> sminutes,
		seconds_port		=> sseconds,
		fract_sec1_port		=> sfract_sec1,
		fract_sec2_port		=> sfract_sec2,
		fract_sec3_port		=> sfract_sec3,
		fract_sec4_port		=> sfract_sec4,
		latitude1_port		=> slatitude1,
		latitude2_port		=> slatitude2,
		latitude3_port		=> slatitude3,
		latitude4_port		=> slatitude4,
		longitude1_port		=> slongitude1,
		longitude2_port		=> slongitude2,
		longitude3_port		=> slongitude3,
		longitude4_port		=> slongitude4,
		ellipsoid1_port		=> sellipsoid1,
		ellipsoid2_port		=> sellipsoid2,
		ellipsoid3_port		=> sellipsoid3,
		ellipsoid4_port		=> sellipsoid4,
		velocity1_port		=> svelocity1,
		velocity2_port		=> svelocity2,
		heading1_port		=> sheading1,
		heading2_port		=> sheading2,
		geometry2_port		=> sgeometry2,
		DOP_type_port		=> sDOP_type,
		num_vis_sat_port	=> sNVS,
		num_track_sat_port	=> sNTS,

		sat_ID1_port	=> ssat_ID1,
		chtm1_port		=> schtm1,
		CNo1_port		=> sCNo1,
		chsf1_port		=> schsf1,

		sat_ID2_port	=> ssat_ID2,
		chtm2_port		=> schtm2,
		CNo2_port		=> sCNo2,
		chsf2_port		=> schsf2,

		sat_ID3_port	=> ssat_ID3,
		chtm3_port		=> schtm3,
		CNo3_port		=> sCNo3,
		chsf3_port		=> schsf3,

		sat_ID4_port	=> ssat_ID4,
		chtm4_port		=> schtm4,
		CNo4_port		=> sCNo4,
		chsf4_port		=> schsf4,

		sat_ID5_port	=> ssat_ID5,
		chtm5_port		=> schtm5,
		CNo5_port		=> sCNo5,
		chsf5_port		=> schsf5,

		sat_ID6_port	=> ssat_ID6,
		chtm6_port		=> schtm6,
		CNo6_port		=> sCNo6,
		chsf6_port		=> schsf6,

		sat_ID7_port	=> ssat_ID7,
		chtm7_port		=> schtm7,
		CNo7_port		=> sCNo7,
		chsf7_port		=> schsf7,

		sat_ID8_port	=> ssat_ID8,
		chtm8_port		=> schtm8,
		CNo8_port		=> sCNo8,
		chsf8_port		=> schsf8,

		rsf_port		=> srsf);

end rtl;	    	    
