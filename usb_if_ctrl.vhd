--
-- Copyright (C) 2011 Horacio Arnaldi
-- e-mail: lharnaldi@cab.cnea.gov.ar
--
-- Laboratorio de Detección de Partículas y Radiación
-- Centro Atómico Bariloche
-- Comisión Nacional de Energía Atómica (CNEA)
-- San Carlos de Bariloche
-- Date: 25/09/2011
-- Ver: v2r0  -- 
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

entity usb_if_ctrl is
	generic(
		VER 							: natural;
		REV 							: natural;
		RESET_POLARITY		: std_logic);
	port(
		-- Reset button (BTN0)
		reset                   : in    std_logic;

		u_ifclk         	: in std_logic;

		-- Data & control from the FX2
		u_fd            	: inout std_logic_vector(7 downto 0);
		u_flagc         	: in std_logic;                         -- FLAGC=EF (active-low), so '1' when there's data
		u_flagb         	: in std_logic;                         -- FLAGB=FF (active-low), so '1' when there's room

		-- Control to the FX2
		u_sloe          	: out std_logic;                                -- PA2
		u_slrd          	: out std_logic;
		u_slwr          	: out std_logic;
		u_fifoad        	: out std_logic_vector(1 downto 0);             -- PA4 & PA5
		u_pktend        	: out std_logic;                                -- PA6
	
		-- Lago Board interface
		-- Ports for settings
		T1, T2, T3              : out   std_logic_vector(9 downto 0);
		subT1, subT2, subT3     : out   std_logic_vector(9 downto 0);	
		BL1, BL2, BL3	     		  : in    std_logic_vector(11 downto 0); -- DAC
		HV1											: out   std_logic_vector(11 downto 0); -- DAC
		HV2, HV3                : out   std_logic_vector(11 downto 0);  --PWM
        
  	-- Inputs for data
  	clk40m                  : in    std_logic;                     --fifo's in clk
		fifo_A				          : in    std_logic_vector(31 downto 0);
  	-- Enables for fifos
		we_A										: in    std_logic;
		-- Data input for HP03
		pC1, pC2, pC3, pC4, pC5	: in	std_logic_vector(15 downto 0);
		pC6, pC7, pD1, pD2			: in 	std_logic_vector(15 downto 0);
		pA, pB, pC, pD					: in 	std_logic_vector(7 downto 0);

		-- GPS receiver data
		UTCnGPS						: out 	std_logic;
		month_port				: in 	std_logic_vector(7 downto 0);
		day_port					: in 	std_logic_vector(7 downto 0);
		year1_port     		: in 	std_logic_vector(7 downto 0);
		year2_port				: in 	std_logic_vector(7 downto 0);
		hours_port				: in 	std_logic_vector(7 downto 0);
		minutes_port			: in 	std_logic_vector(7 downto 0);
		seconds_port			: in 	std_logic_vector(7 downto 0);
		fract_sec1_port		: in 	std_logic_vector(7 downto 0);
		fract_sec2_port		: in 	std_logic_vector(7 downto 0);
		fract_sec3_port		: in 	std_logic_vector(7 downto 0);
		fract_sec4_port		: in 	std_logic_vector(7 downto 0);
		latitude1_port		: in 	std_logic_vector(7 downto 0);
		latitude2_port		: in 	std_logic_vector(7 downto 0);
		latitude3_port		: in 	std_logic_vector(7 downto 0);
		latitude4_port		: in 	std_logic_vector(7 downto 0); 
		longitude1_port		: in 	std_logic_vector(7 downto 0);
		longitude2_port		: in 	std_logic_vector(7 downto 0);
		longitude3_port		: in 	std_logic_vector(7 downto 0);
	 	longitude4_port		: in 	std_logic_vector(7 downto 0);
		ellipsoid1_port		: in 	std_logic_vector(7 downto 0);
		ellipsoid2_port		: in 	std_logic_vector(7 downto 0);
		ellipsoid3_port		: in 	std_logic_vector(7 downto 0);
		ellipsoid4_port		: in 	std_logic_vector(7 downto 0); 
		velocity1_port		: in 	std_logic_vector(7 downto 0);
		velocity2_port		: in 	std_logic_vector(7 downto 0);
		heading1_port			: in 	std_logic_vector(7 downto 0);
		heading2_port			: in 	std_logic_vector(7 downto 0);
		geometry2_port		: in 	std_logic_vector(7 downto 0);
		DOP_type_port			: in 	std_logic_vector(7 downto 0);
		num_vis_sat_port	: in 	std_logic_vector(7 downto 0);
		num_track_sat_port: in 	std_logic_vector(7 downto 0);
                     	
		sat_ID1_port			: in 	std_logic_vector(7 downto 0);
		chtm1_port				: in 	std_logic_vector(7 downto 0);
		CNo1_port					: in 	std_logic_vector(7 downto 0);
		chsf1_port				: in 	std_logic_vector(7 downto 0);
			 
		sat_ID2_port			: in 	std_logic_vector(7 downto 0);
		chtm2_port				: in 	std_logic_vector(7 downto 0);
		CNo2_port					: in 	std_logic_vector(7 downto 0);
		chsf2_port				: in 	std_logic_vector(7 downto 0);
			 
		sat_ID3_port			: in 	std_logic_vector(7 downto 0);
		chtm3_port				: in 	std_logic_vector(7 downto 0);
		CNo3_port					: in 	std_logic_vector(7 downto 0);
		chsf3_port				: in 	std_logic_vector(7 downto 0);
		   
		sat_ID4_port			: in 	std_logic_vector(7 downto 0);
		chtm4_port				: in 	std_logic_vector(7 downto 0);
		CNo4_port					: in 	std_logic_vector(7 downto 0);
		chsf4_port				: in 	std_logic_vector(7 downto 0);
			 
		sat_ID5_port			: in 	std_logic_vector(7 downto 0);
		chtm5_port				: in 	std_logic_vector(7 downto 0);
		CNo5_port					: in 	std_logic_vector(7 downto 0);
		chsf5_port				: in 	std_logic_vector(7 downto 0);
			 
		sat_ID6_port			: in 	std_logic_vector(7 downto 0);
		chtm6_port				: in 	std_logic_vector(7 downto 0);
		CNo6_port					: in 	std_logic_vector(7 downto 0);
		chsf6_port				: in 	std_logic_vector(7 downto 0);
			
		sat_ID7_port			:	in 	std_logic_vector(7 downto 0);
		chtm7_port				: in 	std_logic_vector(7 downto 0);
		CNo7_port					: in 	std_logic_vector(7 downto 0);
		chsf7_port				: in 	std_logic_vector(7 downto 0);
		   
		sat_ID8_port			: in 	std_logic_vector(7 downto 0);
		chtm8_port				: in 	std_logic_vector(7 downto 0);
		CNo8_port					: in 	std_logic_vector(7 downto 0);
		chsf8_port				: in 	std_logic_vector(7 downto 0);
			 
		rsf_port					: in 	std_logic_vector(7 downto 0);
      	
		--Fifo status port   
		pfifo_status			: out   std_logic_vector(7 downto 0)
	);
end usb_if_ctrl;

architecture sync of usb_if_ctrl is

	component fifo
		port(
			din    : in  std_logic_vector(31 downto 0);
			rd_clk : in  std_logic;
			rd_en  : in  std_logic;
			wr_clk : in  std_logic;
			wr_en  : in  std_logic;
			dout   : out std_logic_vector(7 downto 0);
			rst    : in  std_logic;
			empty  : out std_logic;
			full   : out std_logic;
			prog_full: OUT std_logic);
	end component;
	
	attribute box_type : string;
	attribute box_type of fifo : component is "black_box";

	type StateType is (
		STATE_IDLE,
		STATE_GET_COUNT0,
		STATE_GET_COUNT1,
		STATE_GET_COUNT2,
		STATE_GET_COUNT3,
		STATE_BEGIN_WRITE,
		STATE_WRITE,
		STATE_END_WRITE_ALIGNED,
		STATE_END_WRITE_NONALIGNED,
		STATE_READ);

    signal state, state_next        : StateType;
    signal count, count_next        : unsigned(31 downto 0);  -- Read/Write count
    signal addr, addr_next          : std_logic_vector(6 downto 0);
    signal isWrite, isWrite_next    : std_logic;
    signal isAligned, isAligned_next: std_logic;
    signal fifoOp                   : std_logic_vector(2 downto 0);
    constant FIFO_READ              : std_logic_vector(2 downto 0) := "100";  -- assert u_slrd & u_sloe
    constant FIFO_WRITE      	      : std_logic_vector(2 downto 0) := "011";  -- assert u_slwr
    constant FIFO_NOP               : std_logic_vector(2 downto 0) := "111";  -- assert nothing
    constant OUT_FIFO               : std_logic_vector(1 downto 0) := "10";   -- EP6OUT
    constant IN_FIFO                : std_logic_vector(1 downto 0) := "11";   -- EP8IN

	-- FIFO read/write enables, and data to be mux'd back to host
	signal iReadEnable_A						: std_logic;
	signal iFifoData_A           		: std_logic_vector(7 downto 0);
	
	-- HP03 inputs
	signal sC1_msb, sNext_sC1_msb 	: std_logic_vector(7 downto 0);
	signal sC1_lsb, sNext_sC1_lsb 	: std_logic_vector(7 downto 0);
	signal sC2_msb, sNext_sC2_msb   : std_logic_vector(7 downto 0);
	signal sC2_lsb, sNext_sC2_lsb   : std_logic_vector(7 downto 0);
	signal sC3_msb, sNext_sC3_msb 	: std_logic_vector(7 downto 0);
	signal sC3_lsb, sNext_sC3_lsb   : std_logic_vector(7 downto 0);
	signal sC4_msb, sNext_sC4_msb   : std_logic_vector(7 downto 0);
	signal sC4_lsb, sNext_sC4_lsb   : std_logic_vector(7 downto 0);
	signal sC5_msb, sNext_sC5_msb   : std_logic_vector(7 downto 0);
	signal sC5_lsb, sNext_sC5_lsb		: std_logic_vector(7 downto 0);
	signal sC6_msb, sNext_sC6_msb   : std_logic_vector(7 downto 0);
	signal sC6_lsb, sNext_sC6_lsb   : std_logic_vector(7 downto 0);
	signal sC7_msb, sNext_sC7_msb   : std_logic_vector(7 downto 0);
	signal sC7_lsb, sNext_sC7_lsb   : std_logic_vector(7 downto 0);
	signal sA, sNext_sA     	  		: std_logic_vector(7 downto 0);
	signal sB, sNext_sB   	    		: std_logic_vector(7 downto 0);
	signal sC, sNext_sC 		    		: std_logic_vector(7 downto 0);
	signal sD, sNext_sD		    			: std_logic_vector(7 downto 0);
	signal sD1_msb, sNext_sD1_msb   : std_logic_vector(7 downto 0);	
	signal sD1_lsb, sNext_sD1_lsb   : std_logic_vector(7 downto 0);
	signal sD2_msb, sNext_sD2_msb  	: std_logic_vector(7 downto 0);	
	signal sD2_lsb, sNext_sD2_lsb		: std_logic_vector(7 downto 0);

	-- GPS fifo signals
	signal smonth, sNext_month     				: std_logic_vector(7 downto 0);
	signal sday, sNext_day       					: std_logic_vector(7 downto 0);
	signal syear1, sNext_year1        		: std_logic_vector(7 downto 0);
	signal syear2, sNext_year2        		: std_logic_vector(7 downto 0);
	signal shours, sNext_hours        		: std_logic_vector(7 downto 0);
	signal sminutes, sNext_minutes        : std_logic_vector(7 downto 0);
	signal sseconds, sNext_seconds        : std_logic_vector(7 downto 0);
	signal sfract_sec1, sNext_fract_sec1	: std_logic_vector(7 downto 0);
	signal sfract_sec2, sNext_fract_sec2	: std_logic_vector(7 downto 0);
	signal sfract_sec3, sNext_fract_sec3	: std_logic_vector(7 downto 0);
	signal sfract_sec4, sNext_fract_sec4	: std_logic_vector(7 downto 0);
	signal slatitude1, sNext_latitude1		: std_logic_vector(7 downto 0);
	signal slatitude2, sNext_latitude2		: std_logic_vector(7 downto 0);
	signal slatitude3, sNext_latitude3		: std_logic_vector(7 downto 0);
	signal slatitude4, sNext_latitude4		: std_logic_vector(7 downto 0);
	signal slongitude1, sNext_longitude1	: std_logic_vector(7 downto 0);
	signal slongitude2, sNext_longitude2	: std_logic_vector(7 downto 0);
	signal slongitude3, sNext_longitude3	: std_logic_vector(7 downto 0);
	signal slongitude4, sNext_longitude4	: std_logic_vector(7 downto 0);
	signal sellipsoid1, sNext_ellipsoid1	: std_logic_vector(7 downto 0);
	signal sellipsoid2, sNext_ellipsoid2	: std_logic_vector(7 downto 0);
	signal sellipsoid3, sNext_ellipsoid3	: std_logic_vector(7 downto 0);
	signal sellipsoid4, sNext_ellipsoid4	: std_logic_vector(7 downto 0);
	signal svelocity1, sNext_velocity1		: std_logic_vector(7 downto 0);
	signal svelocity2, sNext_velocity2		: std_logic_vector(7 downto 0);
	signal sheading1, sNext_heading1      : std_logic_vector(7 downto 0);
	signal sheading2, sNext_heading2      : std_logic_vector(7 downto 0);	
	signal sgeometry2, sNext_geometry2    : std_logic_vector(7 downto 0);
	signal sDOP_type, sNext_DOP_type      : std_logic_vector(7 downto 0);
	signal sNVS, sNext_NVS        				: std_logic_vector(7 downto 0);
	signal sNTS, sNext_NTS        				: std_logic_vector(7 downto 0);
	signal ssat_ID1, sNext_sat_ID1        : std_logic_vector(7 downto 0);	
	signal schtm1, sNext_chtm1        		: std_logic_vector(7 downto 0);
	signal sCNo1, sNext_CNo1        			: std_logic_vector(7 downto 0);
	signal schsf1, sNext_chsf1        		: std_logic_vector(7 downto 0);
	signal ssat_ID2, sNext_sat_ID2        : std_logic_vector(7 downto 0);
	signal schtm2, sNext_chtm2        		: std_logic_vector(7 downto 0);	
	signal sCNo2, sNext_CNo2        			: std_logic_vector(7 downto 0);
	signal schsf2, sNext_chsf2        		: std_logic_vector(7 downto 0);
	signal ssat_ID3, sNext_sat_ID3        : std_logic_vector(7 downto 0);
	signal schtm3, sNext_chtm3        		: std_logic_vector(7 downto 0);
	signal sCNo3, sNext_CNo3        			: std_logic_vector(7 downto 0);	
	signal schsf3, sNext_chsf3        		: std_logic_vector(7 downto 0);
	signal ssat_ID4, sNext_sat_ID4        : std_logic_vector(7 downto 0);
	signal schtm4, sNext_chtm4        		: std_logic_vector(7 downto 0);
	signal sCNo4, sNext_CNo4        			: std_logic_vector(7 downto 0);	
	signal schsf4, sNext_chsf4        		: std_logic_vector(7 downto 0);
	signal ssat_ID5, sNext_sat_ID5        : std_logic_vector(7 downto 0);
	signal schtm5, sNext_chtm5        		: std_logic_vector(7 downto 0);
	signal sCNo5, sNext_CNo5        			: std_logic_vector(7 downto 0);	
	signal schsf5, sNext_chsf5        		: std_logic_vector(7 downto 0);
	signal ssat_ID6, sNext_sat_ID6       	: std_logic_vector(7 downto 0);
	signal schtm6, sNext_chtm6        		: std_logic_vector(7 downto 0);
	signal sCNo6, sNext_CNo6        			: std_logic_vector(7 downto 0);	
	signal schsf6, sNext_chsf6        		: std_logic_vector(7 downto 0);
	signal ssat_ID7, sNext_sat_ID7        : std_logic_vector(7 downto 0);
	signal schtm7, sNext_chtm7        		: std_logic_vector(7 downto 0);
	signal sCNo7, sNext_CNo7        			: std_logic_vector(7 downto 0);	
	signal schsf7, sNext_chsf7        		: std_logic_vector(7 downto 0);
	signal ssat_ID8, sNext_sat_ID8        : std_logic_vector(7 downto 0);
	signal schtm8, sNext_chtm8        		: std_logic_vector(7 downto 0);
	signal sCNo8, sNext_CNo8        			: std_logic_vector(7 downto 0);	
	signal schsf8, sNext_chsf8        		: std_logic_vector(7 downto 0);
	signal srsf, sNext_rsf        				: std_logic_vector(7 downto 0);
	signal sutcngps, sNextutcngps					: std_logic_vector(7 downto 0);			
	

	-- Registers
	signal iR0, iNextR0									: std_logic_vector(7 downto 0); --reserved
	signal iT1_msb, iNext_T1_msb				: std_logic_vector(7 downto 0);	--1
	signal iT1_lsb, iNext_T1_lsb				: std_logic_vector(7 downto 0);	--2
	signal iT2_msb, iNext_T2_msb				: std_logic_vector(7 downto 0);	--3
	signal iT2_lsb, iNext_T2_lsb				: std_logic_vector(7 downto 0);	--4
	signal iT3_msb, iNext_T3_msb				: std_logic_vector(7 downto 0);	--5
	signal iT3_lsb, iNext_T3_lsb				: std_logic_vector(7 downto 0);	--6
	signal isubT1_msb, iNext_subT1_msb	: std_logic_vector(7 downto 0);	--7
	signal isubT1_lsb, iNext_subT1_lsb	: std_logic_vector(7 downto 0);	--8
	signal isubT2_msb, iNext_subT2_msb	: std_logic_vector(7 downto 0);	--9
	signal isubT2_lsb, iNext_subT2_lsb	: std_logic_vector(7 downto 0);	--10
	signal isubT3_msb, iNext_subT3_msb	: std_logic_vector(7 downto 0);	--11
	signal isubT3_lsb, iNext_subT3_lsb	: std_logic_vector(7 downto 0);	--12
	signal iBL1_msb, iNext_BL1_msb			: std_logic_vector(7 downto 0);	--13
	signal iBL1_lsb, iNext_BL1_lsb		: std_logic_vector(7 downto 0);	--14
	signal iBL2_msb, iNext_BL2_msb		: std_logic_vector(7 downto 0);	--15
	signal iBL2_lsb, iNext_BL2_lsb		: std_logic_vector(7 downto 0);	--16
	signal iBL3_msb, iNext_BL3_msb		: std_logic_vector(7 downto 0);	--17
	signal iBL3_lsb, iNext_BL3_lsb		: std_logic_vector(7 downto 0);	--18
	signal iHV1_msb, iNext_HV1_msb		: std_logic_vector(7 downto 0);	--19
	signal iHV1_lsb, iNext_HV1_lsb		: std_logic_vector(7 downto 0);	--20
	signal iHV2_msb, iNext_HV2_msb		: std_logic_vector(7 downto 0);	--21
	signal iHV2_lsb, iNext_HV2_lsb		: std_logic_vector(7 downto 0);	--22
	signal iHV3_msb, iNext_HV3_msb		: std_logic_vector(7 downto 0);	--23
	signal iHV3_lsb, iNext_HV3_lsb		: std_logic_vector(7 downto 0);	--24
	signal irstatus, iNext_rstatus		: std_logic_vector(7 downto 0);	--25
	
	-- HP03 fifo status 
	signal iVerID, iNext_iVerID			: std_logic_vector(7 downto 0);	--26
 	-- GPS fifo status 
	signal iRevID, iNext_iRevID			: std_logic_vector(7 downto 0);	--27
	signal sfull_A				: std_logic;
	signal sempty_A		: std_logic;
	signal spf_A			: std_logic; -- prog full A and B

begin

  	-- Drive mixed signals...
	pfifo_status	<= "00000" & sfull_A & spf_A & sempty_A;
	iNext_rstatus	<= spf_A & "0" & sfull_A & "000" & sempty_A & "0"; 
	iNext_iVerID	<= std_logic_vector(to_unsigned(VER, 8));	-- Actual Soft Version
	iNext_iRevID	<= std_logic_vector(to_unsigned(REV, 8));	-- Actual Soft Revision
	UTCnGPS			<= sutcngps(0);
	-- Drive module outputs
	-- Trigger levels 
	T1 				<= iT1_msb(1 downto 0) & iT1_lsb;
	T2 				<= iT2_msb(1 downto 0) & iT2_lsb;
	T3 				<= iT3_msb(1 downto 0) & iT3_lsb;
	-- subTrigger levels 
	subT1 			<= isubT1_msb(1 downto 0) & isubT1_lsb;
	subT2 			<= isubT2_msb(1 downto 0) & isubT2_lsb;
	subT3 			<= isubT3_msb(1 downto 0) & isubT3_lsb;
	iNext_BL1_msb 	<= x"0" & BL1(11 downto 8);
	iNext_BL1_lsb 	<= BL1(7 downto 0);
	iNext_BL2_msb 	<= x"0" & BL2(11 downto 8);
	iNext_BL2_lsb 	<= BL2(7 downto 0);
	iNext_BL3_msb 	<= x"0" & BL3(11 downto 8);
	iNext_BL3_lsb 	<= BL3(7 downto 0);
	
   	-- High Voltages
   	HV1 			<= iHV1_msb(3 downto 0) & iHV1_lsb;
   	HV2 			<= iHV2_msb(3 downto 0) & iHV2_lsb;
   	HV3 			<= iHV3_msb(3 downto 0) & iHV3_lsb;

	-- Drive HP03 inputs
	sNext_sC1_msb 	<= pC1(15 downto 8);
	sNext_sC1_lsb 	<= pC1(7 downto 0);
	sNext_sC2_msb 	<= pC2(15 downto 8);
	sNext_sC2_lsb 	<= pC2(7 downto 0);
	sNext_sC3_msb 	<= pC3(15 downto 8);
	sNext_sC3_lsb 	<= pC3(7 downto 0);
	sNext_sC4_msb 	<= pC4(15 downto 8);
	sNext_sC4_lsb 	<= pC4(7 downto 0);
 	sNext_sC5_msb 	<= pC5(15 downto 8);
	sNext_sC5_lsb 	<= pC5(7 downto 0);
	sNext_sC6_msb 	<= pC6(15 downto 8);
	sNext_sC6_lsb 	<= pC6(7 downto 0);
	sNext_sC7_msb 	<= pC7(15 downto 8);
	sNext_sC7_lsb 	<= pC7(7 downto 0);
	sNext_sA      	<= pA;
	sNext_sB      	<= pB;
	sNext_sC      	<= pC;
	sNext_sD      	<= pD;
	sNext_sD1_msb 	<= pD1(15 downto 8);
	sNext_sD1_lsb 	<= pD1(7 downto 0);
	sNext_sD2_msb 	<= pD2(15 downto 8);
	sNext_sD2_lsb 	<= pD2(7 downto 0);

	   -- Drive GPS inputs
	sNext_month 	<= month_port;
	sNext_day 	 	<= day_port;
	sNext_year1 	<= year1_port;
	sNext_year2 	<= year2_port;
	sNext_hours 	<= hours_port;
	sNext_minutes 	<= minutes_port;
	sNext_seconds 	<= seconds_port;
	sNext_fract_sec1<= fract_sec1_port;
 	sNext_fract_sec2<= fract_sec2_port;
	sNext_fract_sec3<= fract_sec3_port;
	sNext_fract_sec4<= fract_sec4_port;
	sNext_latitude1 <= latitude1_port;
	sNext_latitude2 <= latitude2_port;
	sNext_latitude3 <= latitude3_port;
	sNext_latitude4 <= latitude4_port;
	sNext_longitude1<= longitude1_port;
	sNext_longitude2<= longitude2_port;
	sNext_longitude3<= longitude3_port;
	sNext_longitude4<= longitude4_port;
	sNext_ellipsoid1<= ellipsoid1_port;
	sNext_ellipsoid2<= ellipsoid2_port;
	sNext_ellipsoid3<= ellipsoid3_port;
	sNext_ellipsoid4<= ellipsoid4_port;
	sNext_velocity1 <= velocity1_port;
	sNext_velocity2 <= velocity2_port;
	sNext_heading1 	<= heading1_port;
	sNext_heading2 	<= heading2_port;
	sNext_geometry2 <= geometry2_port;
	sNext_DOP_type 	<= DOP_type_port;
	sNext_NVS 	 		<= num_vis_sat_port;
	sNext_NTS 	 		<= num_track_sat_port;
	sNext_sat_ID1 	<= sat_ID1_port;
 	sNext_chtm1 		<= chtm1_port;
	sNext_CNo1 	 		<= CNo1_port;
	sNext_chsf1 		<= chsf1_port;
	sNext_sat_ID2 	<= sat_ID2_port;
	sNext_chtm2 		<= chtm2_port;
	sNext_CNo2 	 		<= CNo2_port;
	sNext_chsf2 		<= chsf2_port;
	sNext_sat_ID3 	<= sat_ID3_port;
	sNext_chtm3 		<= chtm3_port;
	sNext_CNo3 	 		<= CNo3_port;
	sNext_chsf3 		<= chsf3_port;
	sNext_sat_ID4 	<= sat_ID4_port;
 	sNext_chtm4 		<= chtm4_port;
	sNext_CNo4 	 		<= CNo4_port;
	sNext_chsf4 		<= chsf4_port;
	sNext_sat_ID5 	<= sat_ID5_port;
	sNext_chtm5 		<= chtm5_port;
	sNext_CNo5 	 		<= CNo5_port;
	sNext_chsf5 		<= chsf5_port;
	sNext_sat_ID6 	<= sat_ID6_port;
	sNext_chtm6 		<= chtm6_port;
	sNext_CNo6 	 		<= CNo6_port;
	sNext_chsf6 		<= chsf6_port;
	sNext_sat_ID7 	<= sat_ID7_port;
	sNext_chtm7 		<= chtm7_port;
	sNext_CNo7 	 		<= CNo7_port;
	sNext_chsf7 		<= chsf7_port;
	sNext_sat_ID8 	<= sat_ID8_port;
	sNext_chtm8 		<= chtm8_port;
	sNext_CNo8 	 		<= CNo8_port;
	sNext_chsf8 		<= chsf8_port;
	sNext_rsf 	 		<= rsf_port;
	--End of GPS signals
    
	--FIFO's     
	fifoA : fifo
		port map(
			din             => fifo_A,
			rd_clk          => u_ifclk,
			rd_en           => iReadEnable_A,
			wr_clk          => clk40m,
			wr_en           => we_A,
			dout            => iFifoData_A,
			rst             => reset,
			empty           => sempty_A,
			full            => sfull_A,
			prog_full				=> spf_A
		);

	-- Infer registers
	process(u_ifclk, reset)
	begin
		if ( reset = RESET_POLARITY) then
			state     		<= STATE_IDLE;
			count     		<= (others => '0');
			addr      		<= (others => '0');
			isWrite   		<= '0';
			isAligned 		<= '0';
			iR0        		<= (others => '0');
			iT1_msb    		<= x"03";
			iT1_lsb    		<= x"E8";
			iT2_msb    		<= x"03";
			iT2_lsb    		<= x"E8";
			iT3_msb    		<= x"03";
			iT3_lsb    		<= x"E8";
			isubT1_msb 		<= x"03";
			isubT1_lsb      <= x"E8";
			isubT2_msb      <= x"03";
			isubT2_lsb      <= x"E8";
			isubT3_msb      <= x"03";
			isubT3_lsb      <= x"E8";
			iBL1_msb        <= (others => '0');
			iBL1_lsb        <= (others => '0');
			iBL2_msb        <= (others => '0');
			iBL2_lsb        <= (others => '0');
			iBL3_msb        <= (others => '0');
			iBL3_lsb        <= (others => '0');
			iHV1_msb        <= (others => '0');
			iHV1_lsb        <= (others => '0');
			iHV2_msb        <= (others => '0');
			iHV2_lsb        <= (others => '0');
			iHV3_msb        <= (others => '0');
			iHV3_lsb        <= (others => '0');
			irstatus				<= (others => '0');
			--HP03 signals
			sC1_msb					<= (others => '0');
			sC1_lsb  				<= (others => '0');
			sC2_msb     		<= (others => '0');
			sC2_lsb        	<= (others => '0');
			sC3_msb         <= (others => '0');
			sC3_lsb         <= (others => '0');
			sC4_msb         <= (others => '0');
			sC4_lsb         <= (others => '0');
			sC5_msb         <= (others => '0');
			sC5_lsb         <= (others => '0');
			sC6_msb         <= (others => '0');
			sC6_lsb         <= (others => '0');
			sC7_msb         <= (others => '0');
			sC7_lsb         <= (others => '0');
			sA							<= (others => '0');
			sB         			<= (others => '0');
			sC         			<= (others => '0');
			sD         			<= (others => '0');
			sD1_msb         <= (others => '0');
			sD1_lsb         <= (others => '0');
			sD2_msb         <= (others => '0');
			sD2_lsb         <= (others => '0');
			--GPS signals
			smonth		<= (others => '0');
	 		sday		<= (others => '0');
	 		syear1		<= (others => '0');
	 		syear2		<= (others => '0');
	 		shours		<= (others => '0');
	 		sminutes	<= (others => '0');
	 		sseconds	<= (others => '0');
	 		sfract_sec1	<= (others => '0');
	 		sfract_sec2	<= (others => '0');
	 		sfract_sec3	<= (others => '0');
	 		sfract_sec4	<= (others => '0');
	 		slatitude1	<= (others => '0');
	 		slatitude2	<= (others => '0');
	 		slatitude3	<= (others => '0');
	 		slatitude4	<= (others => '0');
			slongitude1	<= (others => '0');
			slongitude2	<= (others => '0');
			slongitude3	<= (others => '0');
			slongitude4	<= (others => '0');
	 		sellipsoid1	<= (others => '0');
	 		sellipsoid2	<= (others => '0');
	 		sellipsoid3	<= (others => '0');
	 		sellipsoid4	<= (others => '0');
	 		svelocity1	<= (others => '0');
	 		svelocity2	<= (others => '0');
	 		sheading1	<= (others => '0');
	 		sheading2	<= (others => '0');	
	 		sgeometry2	<= (others => '0');
	 		sDOP_type	<= (others => '0');
	 		sNVS		<= (others => '0');
	 		sNTS		<= (others => '0');
	 		ssat_ID1	<= (others => '0');	
	 		schtm1		<= (others => '0');
	 		sCNo1		<= (others => '0');
	 		schsf1		<= (others => '0');
	 		ssat_ID2	<= (others => '0');
	 		schtm2		<= (others => '0');	
	 		sCNo2		<= (others => '0');
	 		schsf2		<= (others => '0');
	 		ssat_ID3	<= (others => '0');
	 		schtm3		<= (others => '0');
	 		sCNo3		<= (others => '0');
	 		schsf3		<= (others => '0');
	 		ssat_ID4	<= (others => '0');
	 		schtm4		<= (others => '0');
	 		sCNo4		<= (others => '0');
	 		schsf4		<= (others => '0');
	 		ssat_ID5	<= (others => '0');
	 		schtm5		<= (others => '0');
	 		sCNo5		<= (others => '0');
	 		schsf5		<= (others => '0');
	 		ssat_ID6	<= (others => '0');
	 		schtm6		<= (others => '0');
	 		sCNo6		<= (others => '0');	
	 		schsf6		<= (others => '0');
	 		ssat_ID7	<= (others => '0');
	 		schtm7		<= (others => '0');
	 		sCNo7		<= (others => '0');
	 		schsf7		<= (others => '0');
	 		ssat_ID8	<= (others => '0');
	 		schtm8		<= (others => '0');
	 		sCNo8		<= (others => '0');
	 		schsf8		<= (others => '0');
	 		srsf		<= (others => '0');
			sutcngps 	<= (others => '0');
		   	
		elsif rising_edge(u_ifclk) then 
			state     	<= state_next;
      count     	<= count_next;
      addr      	<= addr_next;
			isWrite   	<= isWrite_next;
      isAligned 	<= isAligned_next;
			iR0			<= iNextR0;
			iT1_msb         <= iNext_T1_msb;
			iT1_lsb         <= iNext_T1_lsb;
			iT2_msb         <= iNext_T2_msb;
			iT2_lsb         <= iNext_T2_lsb;
			iT3_msb         <= iNext_T3_msb;
			iT3_lsb         <= iNext_T3_lsb;
			isubT1_msb      <= iNext_subT1_msb;
			isubT1_lsb      <= iNext_subT1_lsb;
			isubT2_msb      <= iNext_subT2_msb;
			isubT2_lsb      <= iNext_subT2_lsb;
			isubT3_msb      <= iNext_subT3_msb;
			isubT3_lsb      <= iNext_subT3_lsb;
			iBL1_msb        <= iNext_BL1_msb;
			iBL1_lsb        <= iNext_BL1_lsb;
			iBL2_msb        <= iNext_BL2_msb;
			iBL2_lsb        <= iNext_BL2_lsb;
			iBL3_msb        <= iNext_BL3_msb;
			iBL3_lsb        <= iNext_BL3_lsb;
			iHV1_msb        <= iNext_HV1_msb;
			iHV1_lsb        <= iNext_HV1_lsb;
			iHV2_msb        <= iNext_HV2_msb;
			iHV2_lsb        <= iNext_HV2_lsb;
			iHV3_msb        <= iNext_HV3_msb;
			iHV3_lsb        <= iNext_HV3_lsb;
			irstatus        <= iNext_rstatus;
			--HP03 signals
			sC1_msb         <= sNext_sC1_msb;
			sC1_lsb         <= sNext_sC1_lsb;
			sC2_msb         <= sNext_sC2_msb;
			sC2_lsb         <= sNext_sC2_lsb;
			sC3_msb         <= sNext_sC3_msb;
			sC3_lsb         <= sNext_sC3_lsb;
			sC4_msb         <= sNext_sC4_msb;
			sC4_lsb         <= sNext_sC4_lsb;
			sC5_msb         <= sNext_sC5_msb;
			sC5_lsb         <= sNext_sC5_lsb;
			sC6_msb         <= sNext_sC6_msb;
			sC6_lsb         <= sNext_sC6_lsb;
			sC7_msb         <= sNext_sC7_msb;
			sC7_lsb    			<= sNext_sC7_lsb;
			sA							<= sNext_sA;
			sB							<= sNext_sB;
			sC     		    	<= sNext_sC;
			sD							<= sNext_sD;
			sD1_msb         <= sNext_sD1_msb;
			sD1_lsb         <= sNext_sD1_lsb;
			sD2_msb         <= sNext_sD2_msb;
			sD2_lsb         <= sNext_sD2_lsb;
			--GPS signals
			smonth 		<= sNext_month;
			sday		<= sNext_day;
			syear1		<= sNext_year1;   
	 		syear2		<= sNext_year2;  
	 		shours		<= sNext_hours; 
	 		sminutes	<= sNext_minutes;    
	 		sseconds	<= sNext_seconds;   
	 		sfract_sec1	<= sNext_fract_sec1;        
	 		sfract_sec2	<= sNext_fract_sec2;       
	 		sfract_sec3	<= sNext_fract_sec3;      
	 		sfract_sec4	<= sNext_fract_sec4;     
	 		slatitude1	<= sNext_latitude1;  
	 		slatitude2	<= sNext_latitude2; 
	 		slatitude3	<= sNext_latitude3;
	 		slatitude4	<= sNext_latitude4;
	 		slongitude1	<= sNext_longitude1;  
	 		slongitude2	<= sNext_longitude2; 
	 		slongitude3	<= sNext_longitude3;
	 		slongitude4	<= sNext_longitude4;
	 		sellipsoid1	<= sNext_ellipsoid1;
	 		sellipsoid2	<= sNext_ellipsoid2;
	 		sellipsoid3	<= sNext_ellipsoid3;
	 		sellipsoid4	<= sNext_ellipsoid4;
	 		svelocity1	<= sNext_velocity1;
	 		svelocity2	<= sNext_velocity2;
	 		sheading1	<= sNext_heading1;
	 		sheading2	<= sNext_heading2;	
	 		sgeometry2	<= sNext_geometry2;
	 		sDOP_type	<= sNext_DOP_type;
	 		sNVS		<= sNext_NVS;
	 		sNTS		<= sNext_NTS;
	 		ssat_ID1	<= sNext_sat_ID1;	
	 		schtm1		<= sNext_chtm1;
	 		sCNo1		<= sNext_CNo1;
	 		schsf1		<= sNext_chsf1;
	 		ssat_ID2	<= sNext_sat_ID2;
	 		schtm2		<= sNext_chtm2;	
	 		sCNo2		<= sNext_CNo2;
	 		schsf2		<= sNext_chsf2;
	 		ssat_ID3	<= sNext_sat_ID3;
	 		schtm3		<= sNext_chtm3;
	 		sCNo3		<= sNext_CNo3;	
	 		schsf3		<= sNext_chsf3;
	 		ssat_ID4	<= sNext_sat_ID4;
	 		schtm4		<= sNext_chtm4;
	 		sCNo4		<= sNext_CNo4;	
	 		schsf4		<= sNext_chsf4;
	 		ssat_ID5	<= sNext_sat_ID5;
	 		schtm5		<= sNext_chtm5;
	 		sCNo5		<= sNext_CNo5;	
	 		schsf5		<= sNext_chsf5;
	 		ssat_ID6	<= sNext_sat_ID6;
	 		schtm6		<= sNext_chtm6;
	 		sCNo6		<= sNext_CNo6;	
	 		schsf6		<= sNext_chsf6;
	 		ssat_ID7	<= sNext_sat_ID7;
	 		schtm7		<= sNext_chtm7;
	 		sCNo7		<= sNext_CNo7;	
	 		schsf7		<= sNext_chsf7;
	 		ssat_ID8	<= sNext_sat_ID8;
	 		schtm8		<= sNext_chtm8;
	 		sCNo8		<= sNext_CNo8;	
	 		schsf8		<= sNext_chsf8;
	 		srsf		<= sNext_rsf;
	 		sutcngps 	<= sNextutcngps;
			iVerID      <= iNext_iVerID;
			iRevID		<= iNext_iRevID;
		end if;
	end process;

	-- Next state logic
	process(
			state, u_fd, u_flagc, u_flagb, count, isAligned, isWrite, addr,
				
			iR0, iT1_msb, iT1_lsb, iT2_msb, iT2_lsb, iT3_msb, iT3_lsb, 
			isubT1_msb, isubT1_lsb, isubT2_msb, isubT2_lsb, isubT3_msb, 
			isubT3_lsb,	iBL1_msb, iBL1_lsb, iBL2_msb, iBL2_lsb, iBL3_msb, 
			iBL3_lsb, iHV1_msb, iHV1_lsb, iHV2_msb, iHV2_lsb, iHV3_msb, 
			iHV3_lsb, irstatus, iVerID, iRevID, sutcngps)
	begin
		state_next      <= state;
		count_next      <= count;
		addr_next       <= addr;
		isWrite_next    <= isWrite;
		isAligned_next  <= isAligned;           -- does this FIFO write end on a block (512-byte) boundary?
		u_fd            <= (others => 'Z');     -- Tristated unless explicitly driven
		fifoOp          <= FIFO_READ;           -- read the FX2LP FIFO by default
		u_pktend        <= '1';                 -- inactive: FPGA does not commit a short packet.

		iNextR0              <= iR0;
		iNext_T1_msb         <= iT1_msb;
		iNext_T1_lsb         <= iT1_lsb;
		iNext_T2_msb         <= iT2_msb;
		iNext_T2_lsb         <= iT2_lsb;
		iNext_T3_msb         <= iT3_msb;
		iNext_T3_lsb         <= iT3_lsb;
		iNext_subT1_msb      <= isubT1_msb;
		iNext_subT1_lsb      <= isubT1_lsb;
		iNext_subT2_msb      <= isubT2_msb;
		iNext_subT2_lsb      <= isubT2_lsb;
		iNext_subT3_msb      <= isubT3_msb;
		iNext_subT3_lsb      <= isubT3_lsb;
		iNext_HV1_msb        <= iHV1_msb;
		iNext_HV1_lsb        <= iHV1_lsb;
		iNext_HV2_msb        <= iHV2_msb;
		iNext_HV2_lsb        <= iHV2_lsb;
		iNext_HV3_msb        <= iHV3_msb;
		iNext_HV3_lsb        <= iHV3_lsb;
		sNextutcngps	     <= sutcngps;
		-- No read from FIFO
		iReadEnable_A	     <= '0';
		
		case state is
			when STATE_IDLE =>
				u_fifoad <= OUT_FIFO;  -- Reading from FX2LP
				if ( u_flagc = '1' ) then
					-- The read/write flag and a seven-bit register address
					-- will be available on the next clock edge.
					addr_next    <= u_fd(6 downto 0);
					isWrite_next <= u_fd(7);
					state_next   <= STATE_GET_COUNT0;
				end if;

			when STATE_GET_COUNT0 =>
				u_fifoad <= OUT_FIFO;  -- Reading from FX2LP
				if ( u_flagc = '1' ) then
					-- The count high word high byte will be available on the 
					-- next clock edge.
					count_next(31 downto 24) <= unsigned(u_fd);
					state_next <= STATE_GET_COUNT1;
				end if;

			when STATE_GET_COUNT1 =>
				u_fifoad <= OUT_FIFO;  -- Reading from FX2LP
				if ( u_flagc = '1' ) then
					-- The count high word low byte will be available on the 
					-- next clock edge.
					count_next(23 downto 16) <= unsigned(u_fd);
					state_next <= STATE_GET_COUNT2;
				end if;

			when STATE_GET_COUNT2 =>
				u_fifoad <= OUT_FIFO;  -- Reading from FX2LP
				if ( u_flagc = '1' ) then
					-- The count low word high byte will be available on the 
					-- next clock edge.
					count_next(15 downto 8) <= unsigned(u_fd);
					state_next <= STATE_GET_COUNT3;
				end if;

			when STATE_GET_COUNT3 =>
				u_fifoad <= OUT_FIFO;  -- Reading from FX2LP
				if ( u_flagc = '1' ) then
					-- The count low word low byte will be available on the 
					-- next clock edge.
					count_next(7 downto 0) <= unsigned(u_fd);
					if ( isWrite = '1' ) then
						state_next <= STATE_BEGIN_WRITE;
					else
						state_next <= STATE_READ;
					end if;
				end if;

			when STATE_BEGIN_WRITE =>
				u_fifoad   	<= IN_FIFO;   -- Writing to FX2LP
				fifoOp		<= FIFO_NOP;
				isAligned_next <=  not(count(0) or count(1) or count(2) or count(3) 
								   or count(4) or count(5) or count(6) or count(7) 
								   or count(8));
				state_next     <= STATE_WRITE;

			when STATE_WRITE =>
				u_fifoad <= IN_FIFO;   -- Writing to FX2LP
				if ( u_flagb = '1' ) then
					fifoOp <= FIFO_WRITE;
					case addr is
						when "0000000" =>  	--reserved
							u_fd <= iR0;
						when "0000001" =>  	--1
							u_fd <= iT1_msb;
						when "0000010" =>   --2
							u_fd <= iT1_lsb;
						when "0000011" =>	--3
							u_fd <= iT2_msb;
						when "0000100" =>	--4
							u_fd <= iT2_lsb;
						when "0000101" =>	--5
							u_fd <= iT3_msb;
						when "0000110" => 	--6
							u_fd <= iT3_lsb;
						when "0000111" =>	--7
							u_fd <= isubT1_msb;
						when "0001000" => 	--8
							u_fd <= isubT1_lsb;
						when "0001001" =>	--9
							u_fd <= isubT2_msb;
						when "0001010" => 	--10     
							u_fd <= isubT2_lsb;
						when "0001011" => 	--11    
							u_fd <= isubT3_msb;
						when "0001100" => 	--12      
							u_fd <= isubT3_lsb;
						when "0001101" => 	--13      
							u_fd <= iBL1_msb;
						when "0001110" => 	--14
							u_fd <= iBL1_lsb;
						when "0001111" => 	--15
							u_fd <= iBL2_msb;
						when "0010000" =>	--16
							u_fd <= iBL2_lsb;
						when "0010001" =>	--17
							u_fd <= iBL3_msb;
						when "0010010" =>	--18
							u_fd <= iBL3_lsb;
						when "0010011" =>	--19
							u_fd <= iHV1_msb;
						when "0010100" => 	--20
							u_fd <= iHV1_lsb;
						when "0010101" =>   --21
							u_fd <= iHV2_msb;
						when "0010110" =>   --22     
							u_fd <= iHV2_lsb;
						when "0010111" => 	--23
							u_fd <= iHV3_msb;
						when "0011000" =>   --24
							u_fd <= iHV3_lsb;
						when "0011001" =>   --25
							u_fd <= sutcngps;
						when "0011010" =>   --26
							u_fd <= irstatus;
						when "0011011" =>   --27
							iReadEnable_A <= '1';	-- Enable read FIFO
							u_fd <= iFifoData_A;	-- Read FIFO A when addr=1B
						--HP03 signals
						when "0011101" =>   --29
							u_fd <= sC1_msb;
						when "0011110" =>   --30
								u_fd <= sC1_lsb;
						when "0011111" =>   --31
								u_fd <= sC2_msb;
						when "0100000" =>   --32
								u_fd <= sC2_lsb;
						when "0100001" =>   --33
								u_fd <= sC3_msb;
						when "0100010" =>   --34
								u_fd <= sC3_lsb;
						when "0100011" =>   --35
								u_fd <= sC4_msb;
						when "0100100" =>   --36
								u_fd <= sC4_lsb;
						when "0100101" =>   --37
								u_fd <= sC5_msb;
						when "0100110" =>   --38
								u_fd <= sC5_lsb;
						when "0100111" =>   --39     
								u_fd <= sC6_msb;
						when "0101000" =>   --40    
								u_fd <= sC6_lsb;
						when "0101001" =>   --41      
								u_fd <= sC7_msb;
						when "0101010" =>   --42      
								u_fd <= sC7_lsb;
						when "0101011" =>   --43
								u_fd <= sA;
						when "0101100" =>   --44
								u_fd <= sB;
						when "0101101" =>   --45
							u_fd <= sC;
						when "0101110" =>   --46
								u_fd <= sD;
						when "0101111" =>   --47
								u_fd <= sD1_msb;
						when "0110000" =>   --48
								u_fd <= sD1_lsb;
						when "0110001" =>   --49
								u_fd <= sD2_msb;
						when "0110010" =>   --50
							u_fd <= sD2_lsb;
						--GPS signals
						when "0110011" =>   --51     
								u_fd <= smonth;
						when "0110100" =>   --52
								u_fd <= sday;
						when "0110101" =>   --53
								u_fd <= syear1;
						when "0110110" =>   --54
							u_fd <= syear2;
						when "0110111" =>   --55     
								u_fd <= shours;
						when "0111000" =>   --56
								u_fd <= sminutes;
						when "0111001" =>   --57
								u_fd <= sseconds;
						when "0111010" =>   --58
								u_fd <= sfract_sec1;
						when "0111011" =>   --59     
								u_fd <= sfract_sec2;
						when "0111100" =>   --60
								u_fd <= sfract_sec3;
						when "0111101" =>   --61
								u_fd <= sfract_sec4;
						when "0111110" =>   --62
							u_fd <= slatitude1;
						when "0111111" =>   --63     
							u_fd <= slatitude2;
						when "1000000" =>   --64
								u_fd <= slatitude3;
						when "1000001" =>   --65
								u_fd <= slatitude4;
						when "1000010" =>   --66
								u_fd <= slongitude1;
						when "1000011" =>   --67
								u_fd <= slongitude2;
						when "1000100" =>   --68     
								u_fd <= slongitude3;
						when "1000101" =>   --69
								u_fd <= slongitude4;
						when "1000110" =>   --70
								u_fd <= sellipsoid1;
						when "1000111" =>   --71
								u_fd <= sellipsoid2;
						when "1001000" =>   --72     
								u_fd <= sellipsoid3;
						when "1001001" =>   --73
								u_fd <= sellipsoid4;
						when "1001010" =>   --74
								u_fd <= svelocity1;
						when "1001011" =>   --75
								u_fd <= svelocity2;
						when "1001100" =>   --76
								u_fd <= sheading1;
						when "1001101" =>   --77     
								u_fd <= sheading2;
						when "1001110" =>   --78
							u_fd <= sgeometry2;
						when "1001111" =>   --79
							u_fd <= sDOP_type;
						when "1010000" =>   --80
								u_fd <= sNVS;
						when "1010001" =>   --81     
								u_fd <= sNTS;
						when "1010010" =>   --82
								u_fd <= ssat_ID1;
						when "1010011" =>   --83
								u_fd <= schtm1;
						when "1010100" =>   --84
								u_fd <= sCNo1;
						when "1010101" =>   --85
								u_fd <= schsf1;
						when "1010110" =>   --86
								u_fd <= ssat_ID2;
						when "1010111" =>   --87
								u_fd <= schtm2;
						when "1011000" =>   --88
								u_fd <= sCNo2;
						when "1011001" =>   --89
								u_fd <= schsf2;
						when "1011010" =>   --90
								u_fd <= ssat_ID3;
						when "1011011" =>   --91
								u_fd <= schtm3;
						when "1011100" =>   --92
								u_fd <= sCNo3;
						when "1011101" =>   --93
								u_fd <= schsf3;
						when "1011110" =>   --94
								u_fd <= ssat_ID4;
						when "1011111" =>   --95
								u_fd <= schtm4;
						when "1100000" =>   --96
								u_fd <= sCNo4;
						when "1100001" =>   --97
								u_fd <= schsf4;
						when "1100010" =>   --98
								u_fd <= ssat_ID5;
						when "1100011" =>   --99
								u_fd <= schtm5;
						when "1100100" =>   --100
								u_fd <= sCNo5;
						when "1100101" =>   --101
								u_fd <= schsf5;
						when "1100110" =>   --102
								u_fd <= ssat_ID6;
						when "1100111" =>   --103
								u_fd <= schtm6;
						when "1101000" =>   --104
								u_fd <= sCNo6;
						when "1101001" =>   --105
								u_fd <= schsf6;
						when "1101010" =>   --106
								u_fd <= ssat_ID7;
						when "1101011" =>   --107
								u_fd <= schtm7;
						when "1101100" =>   --108
								u_fd <= sCNo7;
						when "1101101" =>   --109
								u_fd <= schsf7;
						when "1101110" =>   --110
								u_fd <= ssat_ID8;
						when "1101111" =>   --111
								u_fd <= schtm8;
						when "1110000" =>   --112
								u_fd <= sCNo8;
						when "1110001" =>   --113
								u_fd <= schsf8;
						when "1110010" =>   --114
							u_fd <= srsf;
						when "1110011" =>   --115
							u_fd <= iVerID;
						when "1110100" =>   --116
							u_fd <= iRevID;
						when others =>
							u_fd <= "00000000";	
					end case;
					count_next  <= count - 1;
           	if ( count = 1 ) then
             	if ( isAligned = '1' ) then
               	state_next <= STATE_END_WRITE_ALIGNED;  -- don't assert u_pktend
						else
							state_next <= STATE_END_WRITE_NONALIGNED;  -- assert u_pktend to commit small packet
						end if;
					end if;
				else
					fifoOp <= FIFO_NOP;
				end if;

			when STATE_END_WRITE_ALIGNED =>
				u_fifoad     <= IN_FIFO;   -- Writing to FX2LP
				fifoOp       <= FIFO_NOP;
				state_next   <= STATE_IDLE;
	
			when STATE_END_WRITE_NONALIGNED =>
				u_fifoad     <= IN_FIFO;   -- Writing to FX2LP
				fifoOp       <= FIFO_NOP;
				u_pktend     <= '0';       -- Active: FPGA commits the packet.
				state_next   <= STATE_IDLE;

			when STATE_READ =>
				u_fifoad <= OUT_FIFO;  -- Reading from FX2LP
				if ( u_flagc = '1' ) then
					-- A data byte will be available on the next clock edge
					case addr is
                      	when "0000000" =>
                           	iNextR0         <= u_fd;
                       	when "0000001" =>
                           	iNext_T1_msb    <= u_fd;
                       	when "0000010" =>
                           	iNext_T1_lsb    <= u_fd;
                       	when "0000011" =>
                      		iNext_T2_msb    <= u_fd;
                        when "0000100" =>
                          	iNext_T2_lsb    <= u_fd;
                        when "0000101" =>
                           	iNext_T3_msb    <= u_fd;
                        when "0000110" =>
                          	iNext_T3_lsb    <= u_fd;
                       	when "0000111" =>
                           	iNext_subT1_msb <= u_fd;
                      	when "0001000" =>
                           	iNext_subT1_lsb <= u_fd;
                       	when "0001001" =>
                           	iNext_subT2_msb <= u_fd;
 												when "0001010" =>
                           	iNext_subT2_lsb <= u_fd;
                       	when "0001011" =>
                           	iNext_subT3_msb <= u_fd;
                       	when "0001100" =>
                           	iNext_subT3_lsb <= u_fd;
                       	when "0001101" =>
                           	iNext_HV1_msb   <= u_fd;
                        when "0001110" =>
                           	iNext_HV1_lsb   <= u_fd;
                       	when "0001111" =>
                           	iNext_HV2_msb   <= u_fd;
                       	when "0010000" =>
                           	iNext_HV2_lsb   <= u_fd;
                        when "0010001" =>
                           	iNext_HV3_msb   <= u_fd;
                       	when "0010010" =>
                           	iNext_HV3_lsb   <= u_fd;
                       	when "0010011" => --19
												--Do nothing, this is for c code                           	
                       	when "0010100" => --20
                           	sNextutcngps    <= u_fd;

                        when others =>

					end case;
					count_next  <= count - 1;
					if ( count = 1 ) then
						state_next <= STATE_IDLE;
					end if;
				end if;
			end case;
    end process;

	-- Breakout fifoOp
	u_sloe <= fifoOp(0);
	u_slrd <= fifoOp(1);
	u_slwr <= fifoOp(2);

end sync;
