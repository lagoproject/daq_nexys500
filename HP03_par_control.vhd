--
-- Copyright (C) 2011 Horacio Arnaldi
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
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--
------------------------------------------------------------------------------------
--
--
entity HP03_cntrl is
    Port ( 	clk 		: in std_logic;
				-- I2C and HP03 related signals
				SDA 		: inout std_logic;
            SCL 		: out std_logic;
            XCLR 		: out std_logic;
            MCLK	 	: out std_logic;
				-- Costants data output
				C1		 	: out std_logic_vector(15 downto 0);
				C2		 	: out std_logic_vector(15 downto 0);
				C3		 	: out std_logic_vector(15 downto 0);
				C4		 	: out std_logic_vector(15 downto 0);
				C5		 	: out std_logic_vector(15 downto 0);
				C6		 	: out std_logic_vector(15 downto 0);
				C7		 	: out std_logic_vector(15 downto 0);
				A		 	: out std_logic_vector(7 downto 0);
				B		 	: out std_logic_vector(7 downto 0);
				C		 	: out std_logic_vector(7 downto 0);
				D		 	: out std_logic_vector(7 downto 0);
				-- ADC data output
				-- Pressure data
				D1		 	: out std_logic_vector(15 downto 0);
				-- Temperature data
				D2		 	: out std_logic_vector(15 downto 0));
    end HP03_cntrl;
--
------------------------------------------------------------------------------------
--
-- Start of test architecture
--
architecture rtl of HP03_cntrl is
--
------------------------------------------------------------------------------------

--
-- declaration of KCPSM3
--
  component kcpsm3 
    Port (      address : out std_logic_vector(9 downto 0);
            instruction : in std_logic_vector(17 downto 0);
                port_id : out std_logic_vector(7 downto 0);
           write_strobe : out std_logic;
               out_port : out std_logic_vector(7 downto 0);
            read_strobe : out std_logic;
                in_port : in std_logic_vector(7 downto 0);
              interrupt : in std_logic;
          interrupt_ack : out std_logic;
                  reset : in std_logic;
                    clk : in std_logic);
    end component;
--
-- declaration of program ROM
--
  component hp_lago 
    Port (      address : in std_logic_vector(9 downto 0);
            instruction : out std_logic_vector(17 downto 0);
                    clk : in std_logic);
    end component;
--
------------------------------------------------------------------------------------
--
-- Signals used to connect KCPSM3 to program ROM and I/O logic
--
signal  address         : std_logic_vector(9 downto 0);
signal  instruction     : std_logic_vector(17 downto 0);
signal  port_id         : std_logic_vector(7 downto 0);
signal  out_port        : std_logic_vector(7 downto 0);
signal  in_port         : std_logic_vector(7 downto 0);
signal  swrite_strobe   : std_logic;
signal  sread_strobe    : std_logic;
signal  interrupt       : std_logic;
signal  interrupt_ack   : std_logic;
signal  kcpsm3_reset    : std_logic;
--
-- Signals for connection of peripherals
--
-- Signals for mclk generation 
--
signal  mclk_count : integer range 0 to 763 :=0; --32khz
signal    mclk_int : std_logic;
--
signal sC1_msb, sC1_lsb	: std_logic_vector(7 downto 0);
signal sC2_msb, sC2_lsb	: std_logic_vector(7 downto 0);
signal sC3_msb, sC3_lsb	: std_logic_vector(7 downto 0);
signal sC4_msb, sC4_lsb	: std_logic_vector(7 downto 0);
signal sC5_msb, sC5_lsb	: std_logic_vector(7 downto 0);
signal sC6_msb, sC6_lsb	: std_logic_vector(7 downto 0);
signal sC7_msb, sC7_lsb	: std_logic_vector(7 downto 0);
signal sA, sB				: std_logic_vector(7 downto 0);
signal sC, sD				: std_logic_vector(7 downto 0);
signal sD1_msb, sD1_lsb	: std_logic_vector(7 downto 0);
signal sD2_msb, sD2_lsb	: std_logic_vector(7 downto 0);
-- Signal to connect to HP03 SDA interface 
--
signal drive_hp_wire, sSCL, sXCLR : std_logic;
--
--
begin
  --
  ----------------------------------------------------------------------------------------------------------------------------------
  -- Open Collector Bidirectional data interface to HP03  
  ----------------------------------------------------------------------------------------------------------------------------------
  --
  -- The I2C interface is an open collector interface with an external pull-up resistor  
  -- fitted on the board. 
  --
  -- To transmit a Low signal, the output buffer must be enabled with a data value of '0'.
  -- To transmit a High, the output buffer is disabled (tri-state) and the external 
  -- pull-up generates the '1'.
  -- Receiving a bit is again performed with the output buffer disabled.
  --
  --
  SDA <= '0' when (drive_hp_wire='0') else 'Z';
  SCL <= sSCL;
  XCLR <= sXCLR;
  --
  C1 <= sC1_msb & sC1_lsb;
  C2 <= sC2_msb & sC2_lsb;
  C3 <= sC3_msb & sC3_lsb;
  C4 <= sC4_msb & sC4_lsb;
  C5 <= sC5_msb & sC5_lsb;
  C6 <= sC6_msb & sC6_lsb;
  C7 <= sC7_msb & sC7_lsb;
  A  <= sA;
  B  <= sB;
  C  <= sC;
  D  <= sD;
  D1 <= sD1_msb & sD1_lsb;
  D2 <= sD2_msb & sD2_lsb;
  --
  -------------------------------------------------------------------------------------------
  -- KCPSM3 and the program memory 
  -------------------------------------------------------------------------------------------
  --
  processor: kcpsm3 
    port map(      address => address,
               instruction => instruction,
                   port_id => port_id,
              write_strobe => swrite_strobe,
                  out_port => out_port,
               read_strobe => sread_strobe,
                   in_port => in_port,
                 interrupt => interrupt,
             interrupt_ack => interrupt_ack,
                     reset => kcpsm3_reset,
                       clk => clk);
 
  program_rom: hp_lago
    port map(      address => address,
               instruction => instruction,
                       clk => clk);
  --
  --
  -------------------------------------------------------------------------------------------
  -- Interrupt 
  -------------------------------------------------------------------------------------------
  --
  --
  -- Interrupt is not used in this version of the design.
  --
  interrupt <= interrupt_ack;
  --
  -------------------------------------------------------------------------------------------
  -- KCPSM3 input ports 
  -------------------------------------------------------------------------------------------
  --
  input_ports: process(clk)
  begin
	if clk'event and clk = '1' then
		if port_id(5) = '1' then
			in_port <= "0000000" & SDA;
		else 
			in_port <= "XXXXXXXX";
		end if;
	end if;

  end process input_ports;
  --
  -------------------------------------------------------------------------------------------
  -- KCPSM3 output ports 
  -------------------------------------------------------------------------------------------
  --
  -- adding the output registers to the processor
   
  output_ports: process(clk)
  begin

	if clk'event and clk='1' then
		if swrite_strobe='1' then
			if port_id(6) = '1' then
				drive_hp_wire 	<= out_port(0);
					sSCL			 	<= out_port(1);
					sXCLR 				<= out_port(2);
			end if;

			case port_id(4 downto 0) is
				-- Write C1_msb constant at address 01 hex
				when "00001" =>
					sC1_msb <= out_port
;
				-- Write C1_lsb constant at address 02 hex
				when "00010" =>
					sC1_lsb <= out_port;
        	
				-- Write C2_msb constant at address 03 hex
				when "00011" =>
					sC2_msb <= out_port;

				-- Write C2_lsb constant at address 04 hex
				when "00100" =>
					sC2_lsb <= out_port;

				-- Write C3_msb constant at address 05 hex
				when "00101" =>
					sC3_msb <= out_port;

				-- Write C3_lsb constant at address 06 hex
				when "00110" =>
					sC3_lsb <= out_port;

				-- Write C4_msb constant at address 07 hex
				when "00111" =>
					sC4_msb <= out_port;

				-- Write C4_lsb constant at address 08 hex
				when "01000" =>
					sC4_lsb <= out_port;
				-- Write C5_msb constant at address 09 hex
				when "01001" =>
					sC5_msb <= out_port;
				-- Write C5_lsb constant at address 0A hex
				when "01010" =>
					sC5_lsb <= out_port;
				-- Write C6_msb constant at address 0B hex
				when "01011" =>
					sC6_msb <= out_port;
				-- Write C6_lsb constant at address 0C hex
				when "01100" =>
					sC6_lsb <= out_port;
				-- Write C7_msb constant at address 0D hex
				when "01101" =>
					sC7_msb <= out_port;
				-- Write C7_lsb constant at address 0E hex
				when "01110" =>
					sC7_lsb <= out_port;
				-- Write A constant at address 0F hex
				when "01111" =>
					sA				<= out_port;
				-- Write B constant at address 10 hex
				when "10000" =>
					sB				<= out_port;
				-- Write C constant at address 11 hex
				when "10001" =>
					sC				<= out_port;
				-- Write D constant at address 12 hex
				when "10010" =>
					sD				<= out_port;
				-- Write ADC data D1_msb at address 13 hex
				when "10011" =>
					sD1_msb <= out_port;
				-- Write ADC data D1_lsb at address 14 hex
				when "10100" =>
					sD1_lsb <= out_port;
				-- Write ADC data D2_msb at address 15 hex
				when "10101" =>
					sD2_msb <= out_port;
				-- Write ADC data D2_lsb at address 16 hex
				when "10110" =>
					sD2_lsb <= out_port;
				-- Don't care used for all other addresses to 
				-- ensure minimum logic implementation
				when others => 
						sC1_msb	<= "XXXXXXXX";
						sC1_lsb	<= "XXXXXXXX";
						sC2_msb	<= "XXXXXXXX";
						sC2_lsb	<= "XXXXXXXX";
						sC3_msb	<= "XXXXXXXX";
						sC3_lsb	<= "XXXXXXXX";
						sC4_msb	<= "XXXXXXXX";
						sC4_lsb	<= "XXXXXXXX";
						sC5_msb	<= "XXXXXXXX";
						sC5_lsb	<= "XXXXXXXX";
						sC6_msb	<= "XXXXXXXX";
						sC6_lsb	<= "XXXXXXXX";
						sC7_msb	<= "XXXXXXXX";
						sC7_lsb	<= "XXXXXXXX";
						sA	<= "XXXXXXXX";
						sB	<= "XXXXXXXX";
						sC	<= "XXXXXXXX";
						sD	<= "XXXXXXXX";
						sD1_msb	<= "XXXXXXXX";
						sD1_lsb	<= "XXXXXXXX";
						sD2_msb	<= "XXXXXXXX";
						sD2_lsb	<= "XXXXXXXX";
						  	
      	end case;

      end if;

    end if; 

  end process output_ports;

  -- Set MCLK to drive HP03 
  --
  mclk_timer: process(clk)
  begin
    if clk'event and clk='1' then
      if mclk_count=763 then
         mclk_count <= 0;
         mclk_int <= not mclk_int;
       else
         mclk_count <= mclk_count + 1;
         mclk_int <= mclk_int;
      end if;
    end if;
  end process mclk_timer;
  MCLK <= mclk_int;
  --
  ---------------------------------------------------------------------------------

end rtl;
