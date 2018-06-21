--
-- Copyright (C) 2012 Horacio Arnaldi
-- e-mail: lharnaldi@cab.cnea.gov.ar
--
-- Laboratorio de Detección de Partículas y Radiación
-- Centro Atómico Bariloche
-- Comisión Nacional de Energía Atómica (CNEA)
-- San Carlos de Bariloche
-- Date: 12/02/2012
-- Ver: v0r2 -- 
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

entity ramp is
	generic(
	  N: integer := 18;       -- numero de bits del contador
  	M: integer := 200000;		-- mod-M
		P: integer := 12);			-- numero de bits para los datos
  port(
    -- Main clock
    clk       			: in    std_logic;
		reset  					: in 		std_logic;
		data_in					: in 		std_logic_vector(P-1 downto 0);
		data_out				: out 	std_logic_vector(P-1 downto 0);
		pwm_pulse				: out		std_logic;
		led_indicador		: out 	std_logic);
end ramp;

architecture rtl of ramp is
  signal count_reg, count_next	: unsigned(N-1 downto 0);
  signal in_reg, in_next	: unsigned(P-1 downto 0);
  signal r_reg, r_next	: unsigned(P-1 downto 0);
  signal out_reg, out_next	: unsigned(P-1 downto 0);
	signal buff_reg, buff_next			: std_logic;
	signal max_tick			: std_logic;

begin
	-- Drive inputs
	in_next	<= unsigned(data_in);

	--registers
 	process (clk, reset)
 	begin
    if (reset = '1') then
    	count_reg 	<= (others => '0');
    	in_reg 		<= (others => '0');
    	out_reg 	<= (others => '0');
    	r_reg		 	<= (others => '0');
    	buff_reg 	<= '0';
 	
    elsif (clk'event and clk = '1') then
     	count_reg 	<= count_next;
     	r_reg 		<= r_next;
     	buff_reg 		<= buff_next;
     	in_reg 		<= in_next;
     	out_reg 	<= out_next;
    end if;
 	end process;
	--next-state logic for counter
	count_next	<= 	(others => '0') when count_reg = (M-1) else
          				count_reg + 1;

	buff_next <= '1' when (r_reg < out_reg) else '0';          		

	r_next <= r_reg + 1;          		

	--output logic
	max_tick <= '1' when count_reg = (M-1) else '0';

	process(max_tick, in_reg, out_reg)
	begin
		if (max_tick = '1') then
			if (in_reg > out_reg) then			
				out_next <= out_reg + 1;
			elsif (in_reg < out_reg) then
				out_next <= out_reg - 1;
			else
				out_next <= out_reg;	-- default
			end if;
		else
			out_next <= out_reg;
		end if;
	end process;
	
	--next-state logic for output
	data_out	<= std_logic_vector(out_reg);
	led_indicador <= 	'0' when (out_reg = 0) else
										'1';
	pwm_pulse <= buff_reg;

end rtl;
