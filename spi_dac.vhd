--****************************************************************************
--  SPI_DAC.vhd
--
--  Horacio Arnaldi <lharnaldi@gmail.com>
--  20/11/2013
--  
--  For MAX5501 DAC control.
--
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------

entity spi_dac is                        -- MSB first
  generic (
    iCLK : boolean  := false;
    iCNV : boolean  := false;
    iDIN : boolean  := false;
    iDOU : boolean  := false;
    NB   : positive := 16;   -- number of bits of DAC
    NDIV : positive := 10);  -- divide the clock to get the spi clock
  port (
    clk   : in  std_logic;
    srst  : in  std_logic;
    valid : in  std_logic;
    din   : in  std_logic_vector(NB-1 downto 0);
    rdy   : out std_logic;

    busy : out std_logic;

    spi_sdo : out std_logic;
    spi_clk : out std_logic;
    spi_csn : out std_logic);
end spi_dac;

-------------------------------------------------------------------------------

architecture arch of spi_dac is



  signal bits : integer range 0 to NB-1;
  signal bcnt : integer range 0 to NDIV-1;

-- 12 data bits and 4 configuration bit.
-- Bit 15 should be 0
-- Bit 14 Vref 1 buffered, 0 unbuffered
-- Bit 13 Gain 1 1x      , 0 2x
-- Bit 12 Gain 1 output enables, 0 output disabled

  type sm_type is (idle, clk0, clk1, finish);

  signal sm : sm_type;

  signal dac : std_logic_vector(NB-1 downto 0);

  signal din_i : std_logic_vector(NB-1 downto 0);
  signal spi_cnv_i : std_logic;
  signal spi_clk_i : std_logic;
  signal busy_i    : std_logic;
  signal start     : std_logic;
  signal shift_out : std_logic;

begin
--  -- Data selector
--  process (din)
--  begin
--    case din is                --MSB   -    LSB 
--      when "0000" => din_i <= "0111000000000000";
--      when "0001" => din_i <= "0111000000000001";
--      when "0010" => din_i <= "0111000000000111";
--      when "0011" => din_i <= "0111000000001111";
--      when "0100" => din_i <= "0111000000011111";
--      when "0101" => din_i <= "0111000000111111";
--      when "0110" => din_i <= "0111000001111111";
--      when "0111" => din_i <= "0111000011111111";
--      when "1000" => din_i <= "0111000111111111";
--      when "1001" => din_i <= "0111001111111111";
--      when "1010" => din_i <= "0111011111111111";
--      when "1011" => din_i <= "0111111111111111";
--      when "1100" => din_i <= "0111111111110000";
--      when "1101" => din_i <= "0111111111100000";
--      when "1110" => din_i <= "0111111111000000";
--      when "1111" => din_i <= "0111111110000000";
--      when others => din_i <= "0111111100000000";   
--    end case;
--  end process;

  -- write to the DAC shift register, only if not busy!
  -- else shift
  process(clk)
  begin
    if clk'event and clk = '1' then
      start <= '0';
      -- write the new values to the dac registers
      if valid = '1' and busy_i = '0' then
        --dac    <= din_i;
        dac    <= din;
        start  <= '1';
        busy_i <= '1';
      else
        if shift_out = '1' then 
	    		dac <= dac(dac'high-1 downto 0) & dac(dac'high); 
				end if;
      end if;
      
      if start = '1' then 
				busy_i  <= '1';
      elsif sm = idle then 
				busy_i <= '0'; 
      end if;

    end if;
  end process;

  spi_sdo   <= not dac(dac'high) when iDOU else dac(dac'high);
  busy      <= busy_i;

  process(clk)
  begin
    if clk'event and clk = '1' then
      shift_out <= '0';
      spi_clk_i <= '1';
      spi_cnv_i <= '1';
      rdy       <= '0';
      if srst = '1' then
        sm   <= idle;
        bcnt <= NDIV - 1;
        bits <= NB-1;
      else
        case sm is
          when idle => 
	    			bcnt <= NDIV - 1;
            bits <= NB - 1;
            
	    			if start = '1' then
            	sm <= clk0;
            end if;
          when clk0 => 
	    			bcnt <= bcnt - 1;
            spi_clk_i <= '0';
            spi_cnv_i <= '0';

            if bcnt = Ndiv/2 then
            	sm <= clk1;
            end if;
          when clk1 =>
            spi_cnv_i <= '0';
            if bcnt = 0 then
             	bcnt <= Ndiv - 1;
             	if bits = 0 then
              	sm  <= finish;
                rdy <= '1';
             	else
                sm <= clk0;
                shift_out <= '1';
                bits <= bits - 1;
             	end if;
            else
            	bcnt <= bcnt - 1;
            end if;

          when finish =>
            if bcnt = 0 then
              sm <= idle;
            else
              bcnt <= bcnt - 1;
            end if;
        end case;
      end if;
    end if;
  end process;

  spi_clk <= not spi_clk_i when iCLK else spi_clk_i;
  spi_csn <= not spi_cnv_i when iCNV else spi_cnv_i;
end arch;
