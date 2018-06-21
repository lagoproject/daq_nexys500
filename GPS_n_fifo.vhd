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
entity Oncore_ctrl is
	Port ( 	
		clk 		: in std_logic;
    		tx_female 	: out std_logic;
                rx_female 	: in std_logic;
		UTCnGPS		: in std_logic;
		
		-- Costants data output
		month_port	: out std_logic_vector(7 downto 0);
		day_port	: out std_logic_vector(7 downto 0);
               	year1_port     	: out std_logic_vector(7 downto 0);
               	year2_port	: out std_logic_vector(7 downto 0);
                hours_port	: out std_logic_vector(7 downto 0);
               	minutes_port	: out std_logic_vector(7 downto 0);
                seconds_port	: out std_logic_vector(7 downto 0);
                fract_sec1_port	: out std_logic_vector(7 downto 0);
                fract_sec2_port	: out std_logic_vector(7 downto 0);
                fract_sec3_port	: out std_logic_vector(7 downto 0);
                fract_sec4_port	: out std_logic_vector(7 downto 0);
                latitude1_port	: out std_logic_vector(7 downto 0);
                latitude2_port	: out std_logic_vector(7 downto 0);
                latitude3_port	: out std_logic_vector(7 downto 0);
                latitude4_port	: out std_logic_vector(7 downto 0);
                longitude1_port	: out std_logic_vector(7 downto 0);
                longitude2_port	: out std_logic_vector(7 downto 0);
                longitude3_port	: out std_logic_vector(7 downto 0);
                longitude4_port	: out std_logic_vector(7 downto 0);
                ellipsoid1_port	: out std_logic_vector(7 downto 0);
                ellipsoid2_port	: out std_logic_vector(7 downto 0);
                ellipsoid3_port	: out std_logic_vector(7 downto 0);
                ellipsoid4_port	: out std_logic_vector(7 downto 0);
		velocity1_port	: out std_logic_vector(7 downto 0);
		velocity2_port	: out std_logic_vector(7 downto 0);
               	heading1_port	: out std_logic_vector(7 downto 0);
		heading2_port	: out std_logic_vector(7 downto 0);
                geometry2_port	: out std_logic_vector(7 downto 0);
                DOP_type_port	: out std_logic_vector(7 downto 0);
                num_vis_sat_port	: out std_logic_vector(7 downto 0);
                num_track_sat_port	: out std_logic_vector(7 downto 0);
                     
                sat_ID1_port	: out std_logic_vector(7 downto 0);
                chtm1_port	: out std_logic_vector(7 downto 0);
                CNo1_port	: out std_logic_vector(7 downto 0);
                chsf1_port	: out std_logic_vector(7 downto 0);
                     
                sat_ID2_port	: out std_logic_vector(7 downto 0);
                chtm2_port	: out std_logic_vector(7 downto 0);
                CNo2_port	: out std_logic_vector(7 downto 0);
                chsf2_port	: out std_logic_vector(7 downto 0);
                     
                sat_ID3_port	: out std_logic_vector(7 downto 0);
                chtm3_port	: out std_logic_vector(7 downto 0);
                CNo3_port	: out std_logic_vector(7 downto 0);
                chsf3_port	: out std_logic_vector(7 downto 0);
                 
                sat_ID4_port	: out std_logic_vector(7 downto 0);
                chtm4_port	: out std_logic_vector(7 downto 0);
                CNo4_port	: out std_logic_vector(7 downto 0);
                chsf4_port	: out std_logic_vector(7 downto 0);
                  
                sat_ID5_port	: out std_logic_vector(7 downto 0);
                chtm5_port	: out std_logic_vector(7 downto 0);
                CNo5_port	: out std_logic_vector(7 downto 0);
                chsf5_port	: out std_logic_vector(7 downto 0);
                     
                sat_ID6_port	: out std_logic_vector(7 downto 0);
                chtm6_port	: out std_logic_vector(7 downto 0);
                CNo6_port	: out std_logic_vector(7 downto 0);
                chsf6_port	: out std_logic_vector(7 downto 0);
                     
                sat_ID7_port	: out std_logic_vector(7 downto 0);
                chtm7_port	: out std_logic_vector(7 downto 0);
                CNo7_port	: out std_logic_vector(7 downto 0);
                chsf7_port	: out std_logic_vector(7 downto 0);
                 
                sat_ID8_port	: out std_logic_vector(7 downto 0);
                chtm8_port	: out std_logic_vector(7 downto 0);
                CNo8_port	: out std_logic_vector(7 downto 0);
                chsf8_port	: out std_logic_vector(7 downto 0);
                  
                rsf_port	: out std_logic_vector(7 downto 0));
end Oncore_ctrl;
--
------------------------------------------------------------------------------------
--
-- Start of test architecture
--
architecture rtl of Oncore_ctrl is
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
  component gpsnfifo 
    Port (      address : in std_logic_vector(9 downto 0);
            instruction : out std_logic_vector(17 downto 0);
                    clk : in std_logic);
    end component;
--
------------------------------------------------------------------------------------
--
--
-- declaration of UART transmitter with integral 16 byte FIFO buffer.
--  
  component uart_tx
    Port (              data_in : in std_logic_vector(7 downto 0);
                   write_buffer : in std_logic;
                   reset_buffer : in std_logic;
                   en_16_x_baud : in std_logic;
                     serial_out : out std_logic;
                    buffer_full : out std_logic;
               buffer_half_full : out std_logic;
                            clk : in std_logic);
    end component;
--
-- declaration of UART Receiver with integral 16 byte FIFO buffer
--
  component uart_rx
    Port (            serial_in : in std_logic;
                       data_out : out std_logic_vector(7 downto 0);
                    read_buffer : in std_logic;
                   reset_buffer : in std_logic;
                   en_16_x_baud : in std_logic;
            buffer_data_present : out std_logic;
                    buffer_full : out std_logic;
               buffer_half_full : out std_logic;
                            clk : in std_logic);
  end component;
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
signal      status_port : std_logic_vector(7 downto 0);
--
-- Signals for interrupt generation 
--
--signal  interrupt_count : integer range 0 to 1526 :=0;
--signal  interrupt_event : std_logic;
--
-- Signals for UART connections
--
signal       baud_count : integer range 0 to 325 :=0;
signal     en_16_x_baud : std_logic;
signal    write_to_uart : std_logic;
signal          tx_full : std_logic;
signal     tx_half_full : std_logic;
signal   read_from_uart : std_logic;
signal          rx_data : std_logic_vector(7 downto 0);
signal  rx_data_present : std_logic;
signal          rx_full : std_logic;
signal     rx_half_full : std_logic;
--
--
--
begin

  ----------------------------------------------------------------------------------------------------------------------------------
  -- KCPSM3 and the program memory 
  ----------------------------------------------------------------------------------------------------------------------------------
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
 
  program_rom: gpsnfifo
    port map(      address => address,
               instruction => instruction,
                       clk => clk);

  --
  --
  -- Interrupt is not used in this version of the design.
  --
  interrupt <= interrupt_ack;
  --
  --
  --
  ----------------------------------------------------------------------------------------------------------------------------------
  -- KCPSM3 input ports 
  ----------------------------------------------------------------------------------------------------------------------------------
  --
  --
  -- UART FIFO status signals to form a bus
  -- 

  status_port <= UTCnGPS & "00" & rx_full & rx_half_full & rx_data_present & tx_full & tx_half_full;

  --
  --
  -- The inputs connect via a pipelined multiplexer
  --
  input_ports: process(clk)
  begin
    if clk'event and clk='1' then

      case port_id(7 downto 6) is

        
        -- read status signals at address 00 hex
        when "01" =>    in_port <= status_port;

        -- read UART receive data at address 01 hex
        when "10" =>    in_port <= rx_data;

        -- Don't care used for all other addresses to ensure minimum logic implementation
        when others =>    in_port <= "XXXXXXXX";  

      end case;

      -- Form read strobe for UART receiver FIFO buffer at address 01 hex.
      -- The fact that the read strobe will occur after the actual data is read by 
      -- the KCPSM3 is acceptable because it is really means 'I have read you'!
 
      if (sread_strobe='1' and port_id(7 downto 6)="10") then 
        read_from_uart <= '1';
       else 
        read_from_uart <= '0';
      end if;

    end if;

  end process input_ports;

  --
  ----------------------------------------------------------------------------------------------------------------------------------
  -- KCPSM3 output ports 
  ----------------------------------------------------------------------------------------------------------------------------------
  --

  -- adding the output registers to the processor
   
  output_ports: process(clk)
  begin

	if clk'event and clk='1' then
		if swrite_strobe='1' then

			case port_id is--(5 downto 0) is
 
				when x"00" =>	month_port 	<= out_port;
				when x"01" => 	day_port   	<= out_port;
				when x"02" =>	year1_port 	<= out_port;
				when x"03" =>	year2_port 	<= out_port;
				when x"04" =>	hours_port 	<= out_port;
				when x"05" =>	minutes_port 	<= out_port;
				when x"06" =>	seconds_port 	<= out_port;
				when x"07" =>	fract_sec1_port <= out_port;
				when x"08" =>	fract_sec2_port <= out_port;
				when x"09" =>	fract_sec3_port <= out_port;
				when x"0A" =>	fract_sec4_port <= out_port;
				when x"0B" =>	latitude1_port  <= out_port;
				when x"0C" =>	latitude2_port  <= out_port;
				when x"0D" =>	latitude3_port  <= out_port;
				when x"0E" =>	latitude4_port  <= out_port;
				when x"0F" =>	longitude1_port <= out_port;
				when x"10" =>	longitude2_port	<= out_port;
				when x"11" =>	longitude3_port	<= out_port;
				when x"12" =>	longitude4_port	<= out_port;
				when x"13" =>	ellipsoid1_port <= out_port;
				when x"14" =>	ellipsoid2_port <= out_port;
				when x"15" =>	ellipsoid3_port <= out_port;
				when x"16" =>	ellipsoid4_port <= out_port;
				when x"17" =>	velocity1_port 	<= out_port;
				when x"18" => 	velocity2_port 	<= out_port;
				when x"19" =>	heading1_port 	<= out_port;
				when x"1A" =>	heading2_port 	<= out_port;
				when x"1B" =>	geometry2_port 	<= out_port;
				when x"1C" =>	DOP_type_port 	<= out_port;
				when x"1D" =>	num_vis_sat_port   <= out_port;
				when x"1E" =>	num_track_sat_port <= out_port;
				when x"1F" =>	sat_ID1_port 	<= out_port;
				when x"20" =>	chtm1_port 	<= out_port;
				when x"21" =>	CNo1_port 	<= out_port;
				when x"22" =>	chsf1_port	<= out_port;
				when x"23" =>	sat_ID2_port  	<= out_port;
				when x"24" =>	chtm2_port  	<= out_port;
				when x"25" =>	CNo2_port  	<= out_port;
				when x"26" =>	chsf2_port 	<= out_port;
				when x"27" =>	sat_ID3_port	<= out_port;
				when x"28" =>	chtm3_port	<= out_port;
				when x"29" =>	CNo3_port	<= out_port;
				when x"2A" =>	chsf3_port 	<= out_port;
				when x"2B" =>	sat_ID4_port 	<= out_port;
				when x"2C" =>	chtm4_port 	<= out_port;
				when x"2D" =>	CNo4_port 	<= out_port;
				when x"2E" =>	chsf4_port 	<= out_port;
				when x"2F" =>	sat_ID5_port  	<= out_port;
				when x"30" =>	chtm5_port  	<= out_port;
				when x"31" =>	CNo5_port  	<= out_port;
				when x"32" =>	chsf5_port  	<= out_port;
				when x"33" =>	sat_ID6_port 	<= out_port;
				when x"34" =>	chtm6_port	<= out_port;
				when x"35" =>	CNo6_port	<= out_port;
				when x"36" =>	chsf6_port	<= out_port;
				when x"37" =>	sat_ID7_port 	<= out_port;
				when x"38" =>	chtm7_port 	<= out_port;
				when x"39" =>	CNo7_port 	<= out_port;
				when x"3A" =>	chsf7_port 	<= out_port;
				when x"3B" =>	sat_ID8_port	<= out_port;
				when x"3C" =>	chtm8_port 	<= out_port;
				when x"3D" =>	CNo8_port 	<= out_port;
				when x"3E" =>	chsf8_port 	<= out_port;
				when x"3F" =>	rsf_port 	<= out_port;
           	
				-- Don't care used for all other addresses to 
				-- ensure minimum logic implementation
				when others => 
					
      	end case;

      end if;

    end if; 

  end process output_ports;
  
   --
  -- write to UART transmitter FIFO buffer at address 20 hex.
  -- This is a combinatorial decode because the FIFO is the 'port register'.
  --

  write_to_uart <= '1' when (swrite_strobe='1' and port_id(7 downto 6) ="11") else '0';


  --
  ----------------------------------------------------------------------------------------------------------------------------------
  -- UART  
  ----------------------------------------------------------------------------------------------------------------------------------
  --
  -- Connect the 8-bit, 1 stop-bit, no parity transmit and receive macros.
  -- Each contains an embedded 16-byte FIFO buffer.
  --

  transmit: uart_tx 
  port map (              data_in => out_port, 
                     write_buffer => write_to_uart,
                     reset_buffer => '0',
                     en_16_x_baud => en_16_x_baud,
                       serial_out => tx_female,
                      buffer_full => tx_full,
                 buffer_half_full => tx_half_full,
                              clk => clk );

  receive: uart_rx
  port map (            serial_in => rx_female,
                         data_out => rx_data,
                      read_buffer => read_from_uart,
                     reset_buffer => '0',
                     en_16_x_baud => en_16_x_baud,
              buffer_data_present => rx_data_present,
                      buffer_full => rx_full,
                 buffer_half_full => rx_half_full,
                              clk => clk );  
  
  --
  -- Set baud rate to 9600 for the UART communications
  -- Requires en_16_x_baud to be 153600Hz which is a single cycle pulse every 326 cycles at 50MHz 
  --

  baud_timer: process(clk)
  begin
    if clk'event and clk='1' then
      if baud_count=325 then
         baud_count <= 0;
         en_16_x_baud <= '1';
       else
         baud_count <= baud_count + 1;
         en_16_x_baud <= '0';
      end if;
    end if;
  end process baud_timer;

  --
  --
  ----------------------------------------------------------------------------------------------------------------------------------

end rtl;
