library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
--
entity baseline_control is
  generic(
    W                   : natural; --:=5;     -- numero de bits de direcciones. 2**W = 32 direcciones para W=5
    ADCBITS             : natural; -- := 10;  -- numero de bits en los datos
    RBITS						    : natural; -- := 12;	-- numero de bits de los registros
    REFRESH_RATE        : natural; -- := 80000; -- 80000 clk implican un refresh rate de 2ms (80000 * 25 ns = 2ms)
    NCH     						: natural  --:= 3 		-- numero de canales de la electronica
  );

  port(
    clk_40mhz          : in std_logic;
    reset              : in std_logic;
    ptick_2ms          : out std_logic;
    data_adc1          : in   std_logic_vector(ADCBITS-1 downto 0);
    data_adc2          : in   std_logic_vector(ADCBITS-1 downto 0);
    data_adc3          : in   std_logic_vector(ADCBITS-1 downto 0);
    baseline1          : out   std_logic_vector(RBITS-1 downto 0);
    baseline2          : out   std_logic_vector(RBITS-1 downto 0);
    baseline3          : out   std_logic_vector(RBITS-1 downto 0)
	);
end baseline_control;

architecture rtl of baseline_control is
	
	signal cont_promedio_reg, cont_promedio_next : unsigned((2**W-1) downto 0);
	signal adc1_sum_reg, adc1_sum_next : unsigned((2**W-1) downto 0);
	signal adc2_sum_reg, adc2_sum_next : unsigned((2**W-1) downto 0);
	signal adc3_sum_reg, adc3_sum_next : unsigned((2**W-1) downto 0);
	signal adc1_prom_reg, adc1_prom_next : unsigned((2**W-1) downto 0);
	signal adc2_prom_reg, adc2_prom_next : unsigned((2**W-1) downto 0);
	signal adc3_prom_reg, adc3_prom_next : unsigned((2**W-1) downto 0);
	signal baseline1_buff_reg, baseline1_buff_next : unsigned((RBITS-1) downto 0);
	signal baseline2_buff_reg, baseline2_buff_next : unsigned((RBITS-1) downto 0);
	signal baseline3_buff_reg, baseline3_buff_next : unsigned((RBITS-1) downto 0);
	signal max_tick : std_logic;	

begin

	ptick_2ms <= max_tick;
	--registers
	process(clk_40mhz, reset)
	begin
		if (reset = '1') then	
			cont_promedio_reg <= (others => '0');
			adc1_sum_reg	<= (others => '0');
			adc2_sum_reg	<= (others => '0');
			adc3_sum_reg	<= (others => '0');
			adc1_prom_reg	<= (others => '0');
			adc2_prom_reg	<= (others => '0');
			adc3_prom_reg	<= (others => '0');
			baseline1_buff_reg <= (others => '0');
			baseline2_buff_reg <= (others => '0');
			baseline3_buff_reg <= (others => '0');
		elsif (clk_40mhz'event and clk_40mhz = '1') then
			cont_promedio_reg <= cont_promedio_next;
			adc1_sum_reg <= adc1_sum_next;
			adc2_sum_reg <= adc2_sum_next;
			adc3_sum_reg <= adc3_sum_next;
			adc1_prom_reg <= adc1_prom_next;
			adc2_prom_reg <= adc2_prom_next;
			adc3_prom_reg <= adc3_prom_next;
			baseline1_buff_reg <= baseline1_buff_next;
			baseline2_buff_reg <= baseline2_buff_next;
			baseline3_buff_reg <= baseline3_buff_next;
		end if;
	end process;

	--next state logic
	cont_promedio_next <= (others => '0') when (cont_promedio_reg = (REFRESH_RATE-1)) else
												cont_promedio_reg + 1;

	max_tick <= '1' when (cont_promedio_reg = (REFRESH_RATE-1)) else '0';	

	adc1_sum_next <= (others => '0') when (max_tick = '1') else
										adc1_sum_reg + unsigned(data_adc1);	
	adc2_sum_next <= (others => '0') when (max_tick = '1') else
										adc2_sum_reg + unsigned(data_adc2);	
	adc3_sum_next <= (others => '0') when (max_tick = '1') else
										adc3_sum_reg + unsigned(data_adc3);	

	adc1_prom_next <= adc1_sum_reg when (max_tick = '1') else
										adc1_prom_reg;
	adc2_prom_next <= adc2_sum_reg when (max_tick = '1') else
										adc2_prom_reg;
	adc3_prom_next <= adc3_sum_reg when (max_tick = '1') else
										adc3_prom_reg;

	process(max_tick, adc1_prom_reg)
	begin
	if (max_tick = '1') then
		if (adc1_prom_reg > 4000000) then --4000000 = 50*80000, con 50 el nivel de baseline buscado
			baseline1_buff_next <= baseline1_buff_reg + 1;
		elsif (adc1_prom_reg < 4000000) then
			baseline1_buff_next <= baseline1_buff_reg - 1;
		else
			baseline1_buff_next <= baseline1_buff_reg;
		end if;
	else
		baseline1_buff_next <= baseline1_buff_reg;
	end if;
	end process;

	process(max_tick, adc2_prom_reg)
	begin
	if (max_tick = '1') then
		if (adc2_prom_reg > 4000000) then
			baseline2_buff_next <= baseline2_buff_reg + 1;
		elsif (adc2_prom_reg < 4000000) then
			baseline2_buff_next <= baseline2_buff_reg - 1;
		else
			baseline2_buff_next <= baseline2_buff_reg;
		end if;
	else
		baseline2_buff_next <= baseline2_buff_reg;
	end if;
	end process;

	process(max_tick, adc3_prom_reg)
	begin
	if (max_tick = '1') then
		if (adc3_prom_reg > 4000000) then
			baseline3_buff_next <= baseline3_buff_reg + 1;
		elsif (adc3_prom_reg < 4000000) then
			baseline3_buff_next <= baseline3_buff_reg - 1;
		else
			baseline3_buff_next <= baseline3_buff_reg;
		end if;
	else
		baseline3_buff_next <= baseline3_buff_reg;
	end if;
	end process;

	-- output
	baseline1 <= std_logic_vector(baseline1_buff_reg);
	baseline2 <= std_logic_vector(baseline2_buff_reg);
	baseline3 <= std_logic_vector(baseline3_buff_reg);

end architecture;
