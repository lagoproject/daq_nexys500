library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity interfaz_spi is
  generic(
    iCLK : boolean  := false;
    iCNV : boolean  := false;
    iDIN : boolean  := false;
    iDOU : boolean  := false;
    NB   : positive := 16;   -- number of bits of DAC
    NDIV : positive := 10    -- divide the clock to get the spi clock
  );
  port (
  --Entradas
  clk       : in std_logic;          -- global clock input. 40 MHz en este caso, para estar en orden con baseline_ctrl
  reset     : in std_logic;
  ptick_2ms : in std_logic;						-- Con esta señal se sincroniza todo cada 2ms
  data_dac1 : in std_logic_vector(11 downto 0);
  data_dac2 : in std_logic_vector(11 downto 0);
  data_dac3 : in std_logic_vector(11 downto 0);
  data_dac4 : in std_logic_vector(11 downto 0);
  --Señales a la E2PROM
  cs_e2prom : out std_logic;
  --Señales al DAC MAX5501
  spi_sdo : out std_logic;
  spi_clk : out std_logic;
  spi_csn : out std_logic
  );
end entity interfaz_spi;

architecture rtl of interfaz_spi is

  type state_type is (STATE_IDLE,
						 					STATE_INIT_TX,
                      STATE_SPI_IDLE, 
											STATE_SPI_CLK0, 
											STATE_SPI_CLK1, 
											STATE_SPI_FINISH);
  signal state_reg, state_next          : state_type;

  signal rdy        							      : std_logic;
  signal busy       							      : std_logic;
  signal load_reg, load_next     	      : std_logic;
  signal spi_conv   							  		: std_logic;
  signal spi_clk_i  							    	: std_logic;
  signal start_reg, start_next   	   		: std_logic;
  signal shift_out  										: std_logic;

  signal dac1_buff_reg, dac1_buff_next  : unsigned(11 downto 0);
  signal dac2_buff_reg, dac2_buff_next  : unsigned(11 downto 0);
  signal dac3_buff_reg, dac3_buff_next  : unsigned(11 downto 0);
  signal dac4_buff_reg, dac4_buff_next  : unsigned(11 downto 0);

  signal sel_reg, sel_next 							: std_logic_vector(1 downto 0);
  signal mux_signal 										: std_logic_vector(NB-1 downto 0);
  constant DAC1                         : std_logic_vector(1 downto 0) := "00";  -- selector de DAC1
  constant DAC2                         : std_logic_vector(1 downto 0) := "01";  -- selector de DAC2
  constant DAC3                         : std_logic_vector(1 downto 0) := "10";  -- selector de DAC3
  constant DAC4                         : std_logic_vector(1 downto 0) := "11";  -- selector de DAC4

  signal bits_reg, bits_next            : integer range 0 to NB-1;
  signal bcnt_reg, bcnt_next            : integer range 0 to NDIV-1;
	signal data_reg, data_next  					: std_logic_vector(NB-1 downto 0);
  signal count_reg, count_next  				: unsigned(1 downto 0);

begin

  dac1_buff_next <= unsigned(data_dac1) when (ptick_2ms = '1') else dac1_buff_reg;
  dac2_buff_next <= unsigned(data_dac2) when (ptick_2ms = '1') else dac2_buff_reg;
  dac3_buff_next <= unsigned(data_dac3) when (ptick_2ms = '1') else dac3_buff_reg;
  dac4_buff_next <= unsigned(data_dac4) when (ptick_2ms = '1') else dac4_buff_reg;

	--regusters
	process(clk, reset)
	begin
	if (reset ='1') then
		state_reg <= STATE_IDLE;
		data_reg <= (others => '0');
    dac1_buff_reg <= (others => '0');
    dac2_buff_reg <= (others => '0');
    dac3_buff_reg <= (others => '0');
    dac4_buff_reg <= (others => '0');
		count_reg <= (others => '0');
		sel_reg <= (others => '0');
		start_reg <= '0';
		load_reg <= '0';
    bcnt_reg <= 0;
    bits_reg <= 0;
	elsif rising_edge(clk) then
		state_reg <= state_next;
		data_reg <= data_next;
    dac1_buff_reg <= dac1_buff_next;
    dac2_buff_reg <= dac2_buff_next;
    dac3_buff_reg <= dac3_buff_next;
    dac4_buff_reg <= dac4_buff_next;
		count_reg <= count_next;
		sel_reg <= sel_next;
		start_reg <= start_next;
		load_reg <= load_next;
    bcnt_reg <= bcnt_next;
    bits_reg <= bits_next;
	end if;
	end process;

	--next state logic
	--MUX
	with sel_reg select
    mux_signal <= "1011" & std_logic_vector(dac1_buff_reg) when DAC1,--"00", -- Canal C DAC. Baseline canal 3  
                    "1111" & std_logic_vector(dac2_buff_reg) when DAC2,--"01", -- Canal D DAC. Baseline canal 2
                    "0111" & std_logic_vector(dac3_buff_reg) when DAC3,--"10", -- Canal B DAC. HV canal 1
                    "0011" & std_logic_vector(dac4_buff_reg) when others; -- Canal A DAC. Baseline canal 1

	data_next <= 	mux_signal when (load_reg = '1') else
								data_reg(data_reg'high-1 downto 0) & data_reg(data_reg'high) when (shift_out = '1') else
								data_reg;

  -- maquina de estados que maneja todo
  process(state_reg, ptick_2ms)
  begin
  state_next <= state_reg;
  start_next <= '0';
	load_next <= '0';
  sel_next <= sel_reg;
	count_next <= count_reg;
  shift_out <= '0';
  spi_clk_i <= '0';
  spi_conv <= '1';
  rdy <= '0';
  busy <= '0';
  bcnt_next <= 0;
  bits_next <= bits_reg;
  case state_reg is

    when STATE_IDLE =>
			count_next <= (others => '0');
			sel_next <= DAC1;
			if (ptick_2ms = '1') then
				state_next <= STATE_INIT_TX;
			else
				state_next <= STATE_IDLE;
			end if;

		when STATE_INIT_TX =>
			if (busy = '0') then
				count_next <= count_reg + 1;
				start_next <= '1';
				load_next <= '1';
				state_next <= STATE_SPI_IDLE;
				if ( count_reg = 0 ) then
						sel_next <= DAC1;
				elsif ( count_reg = 1 ) then
						sel_next <= DAC2;
		  	elsif ( count_reg = 2 ) then
						sel_next <= DAC3;
		  	else	
						sel_next <= DAC4;
		  	end if;
			else
				state_next <= STATE_INIT_TX;
			end if;

    when STATE_SPI_IDLE =>
      if (start_reg <= '1') then
				shift_out <= '1';
        state_next <= STATE_SPI_CLK0;
      end if;

    when STATE_SPI_CLK0 =>
      busy <= '1';
      bcnt_next <= bcnt_reg+1;
      spi_conv <= '0';
      if (bcnt_reg = NDIV/2) then
        state_next <= STATE_SPI_CLK1;
      end if;

    when STATE_SPI_CLK1 =>
      busy <= '1';
      bcnt_next <= bcnt_reg+1;
      spi_clk_i <= '1';
      spi_conv <= '0';
      if (bcnt_reg = NDIV-1) then
          bits_next <= bits_reg+1;
        if (bits_reg = NB-1) then
          rdy <= '1';
          state_next <= STATE_SPI_FINISH;
        else
          shift_out <= '1';
          state_next <= STATE_SPI_CLK0;
        end if;
      end if;

    when STATE_SPI_FINISH =>
      busy <= '1';
      bcnt_next <= bcnt_reg+1;
      if (bcnt_reg = NDIV-1) then
				if (count_reg = 4) then
					state_next <= STATE_IDLE;
				else
        state_next <= STATE_INIT_TX;
      	end if;
      end if;
  end case;
  end process;

  --output
  spi_sdo   <= not data_reg(data_reg'high) when iDOU else data_reg(data_reg'high);

  spi_clk <= not spi_clk_i when iCLK else spi_clk_i;
  spi_csn <= not spi_conv when iCNV else spi_conv;

  cs_e2prom <= '1';

end architecture;
