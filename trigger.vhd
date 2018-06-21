library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
--
entity trigger_in is
  generic(
	 	W										: natural; --:=5;			-- numero de bits de direcciones. 2**W = 32 direcciones para W=5
    ADCBITS 						: natural; -- := 10;	-- numero de bits en los datos
		L_ARRAY_MUESTRAS 		: natural; -- := 12;
  	L_ARRAY_PPS 				: natural; -- := 10;
  	L_ARRAY_SCALERS 		: natural  --:= 3
  );

  port(
		clk_40mhz          : in std_logic;
	 	reset				  		 : in std_logic;
    data_adc1          : in   std_logic_vector(ADCBITS-1 downto 0);
    data_adc2          : in   std_logic_vector(ADCBITS-1 downto 0);
    data_adc3          : in   std_logic_vector(ADCBITS-1 downto 0);
    trigg_set1         : in   std_logic_vector(ADCBITS-1 downto 0);
    trigg_set2         : in   std_logic_vector(ADCBITS-1 downto 0);
    trigg_set3         : in   std_logic_vector(ADCBITS-1 downto 0);
    subtrigg_set1      : in   std_logic_vector(ADCBITS-1 downto 0);
    subtrigg_set2      : in   std_logic_vector(ADCBITS-1 downto 0);
    subtrigg_set3      : in   std_logic_vector(ADCBITS-1 downto 0);
    pwr_enA            : out  std_logic;
    data_out           : out  std_logic_vector(2**W-1 downto 0);
    pfifo_status       : in   std_logic_vector(2 downto 0);
    ptemperatura       : in 	std_logic_vector(15 downto 0);
    ppresion           : in 	std_logic_vector(15 downto 0);
    phora              : in 	std_logic_vector(7 downto 0);
    pminutos           : in 	std_logic_vector(7 downto 0);
    psegundos          : in 	std_logic_vector(7 downto 0);
    pps_signal         : in 	std_logic;
    gpsen              : in 	std_logic;
    pps_falso_led      : out  std_logic;
    latitude1_port     : in 	std_logic_vector(7 downto 0);
    latitude2_port     : in 	std_logic_vector(7 downto 0);
    latitude3_port     : in 	std_logic_vector(7 downto 0);
    latitude4_port     : in 	std_logic_vector(7 downto 0);
    longitude1_port    : in 	std_logic_vector(7 downto 0);
    longitude2_port    : in 	std_logic_vector(7 downto 0);
    longitude3_port    : in 	std_logic_vector(7 downto 0);
    longitude4_port    : in 	std_logic_vector(7 downto 0);
    ellipsoid1_port    : in 	std_logic_vector(7 downto 0);
    ellipsoid2_port    : in 	std_logic_vector(7 downto 0);
    ellipsoid3_port    : in 	std_logic_vector(7 downto 0);
    ellipsoid4_port    : in 	std_logic_vector(7 downto 0);
    num_vis_sat_port   : in 	std_logic_vector(7 downto 0);
    num_track_sat_port : in 	std_logic_vector(7 downto 0);
    rsf_port           : in 	std_logic_vector(7 downto 0)
	);
end trigger_in;

architecture rtl of trigger_in is

	type	array_muestras_adc_type is array (L_ARRAY_MUESTRAS-1 downto 0) of 
				std_logic_vector(ADCBITS-1 downto 0);	
	signal muestras_adc1_reg, muestras_adc1_next : array_muestras_adc_type;
	signal muestras_adc2_reg, muestras_adc2_next : array_muestras_adc_type;
	signal muestras_adc3_reg, muestras_adc3_next : array_muestras_adc_type;

	type 	array_pps_type is array (L_ARRAY_PPS-1 downto 0) of
				std_logic_vector(2**W-1 downto 0);	
	signal array_pps_reg, array_pps_next : array_pps_type;

	type 	array_scalers_type is array (L_ARRAY_SCALERS-1 downto 0) of
				std_logic_vector(2**W-1 downto 0);	
	signal array_scalers_reg, array_scalers_next : array_scalers_type;

	signal clk_para_pps_falso_reg, clk_para_pps_falso_next : unsigned(2**W-1 downto 0); -- contador para falso pps
	signal cont_pps_reg, cont_pps_next : unsigned(15 downto 0); -- contador para pps
	signal cont_clk_entre_pps_reg, cont_clk_entre_pps_next : unsigned(29 downto 0); -- contador de pulsos de clock entre cada PPS, se resetea en cada pps
	signal pps, pps_falso : std_logic;

  type statepps_type is (zero, edge, one);
  signal statepps_reg, statepps_next: statepps_type;
	signal one_clk_pps : std_logic;
	
	signal s_tr1, s_tr2, s_tr3, s_tr : std_logic;	--Triggers
	signal s_subtr1, s_subtr2, s_subtr3, s_subtr : std_logic;	--Sub-Triggers
	
	signal tr_status_reg, tr_status_next : std_logic_vector(2**W-1 downto 0);
	signal ctr_status_reg, ctr_status_next : std_logic_vector(2**W-1 downto 0);
	
	signal cont_trigger_reg, cont_trigger_next : unsigned(29 downto 0); -- contador de triggers
	signal cont_bines_reg, cont_bines_next : unsigned(2**W-1 downto 0); -- contador de bines

	signal charge1_reg, charge1_next : unsigned(ADCBITS-1 downto 0); 
	signal charge2_reg, charge2_next : unsigned(ADCBITS-1 downto 0); 
	signal charge3_reg, charge3_next : unsigned(ADCBITS-1 downto 0); 

  type state_type is (STATE_IDLE, 
											STATE_ATT_TR,
											STATE_SEND_TR_STATUS,
											STATE_SEND_CTR_STATUS, 
											STATE_ATT_SUBTR, 
											STATE_ATT_PPS);
  signal state_reg, state_next: state_type;

	signal wr_count_reg, wr_count_next : unsigned(7 downto 0);
	signal data_to_fifo_reg, data_to_fifo_next : std_logic_vector(2**W-1 downto 0);	
	signal wr_fifo_en_reg, wr_fifo_en_next	: std_logic;
	signal status	: std_logic_vector(2 downto 0);

begin

--------------------------------------------------------------------------
	-- PPS falso
	-- registers
  process(clk_40mhz, reset)
  begin
		if (reset = '1') then
			clk_para_pps_falso_reg <= (others => '0');	-- Contador de clocks entre PPS's
			cont_pps_reg <= (others => '0');						-- Contador de PPS's
			cont_clk_entre_pps_reg <= (others => '0');				-- Contador de muestras adquiridas entre cada PPS
		elsif (clk_40mhz'event and clk_40mhz = '1') then
			clk_para_pps_falso_reg <= clk_para_pps_falso_next;
			cont_pps_reg <= cont_pps_next;
			cont_clk_entre_pps_reg <= cont_clk_entre_pps_next;
		end if;
	end process;
	--next state logic
	clk_para_pps_falso_next <= 	(others => '0') when (clk_para_pps_falso_reg = 39999999) else
															clk_para_pps_falso_reg + 1;

	pps_falso <= 	'1' when (clk_para_pps_falso_reg < 8000000) else
								'0';

	cont_pps_next <= 	cont_pps_reg + 1 when (one_clk_pps = '1') else
										cont_pps_reg;

	cont_clk_entre_pps_next <= 	(others => '0') when (one_clk_pps = '1') else
															cont_clk_entre_pps_reg + 1;

---------------------------------------------------------------------------

---------------------------------------------------------------------------
	--MUX de PPS
	pps <= 	pps_falso when (gpsen = '1') else
					pps_signal;

	pps_falso_led <= 	pps_falso when (gpsen = '1') else
										'0';
---------------------------------------------------------------------------

---------------------------------------------------------------------------
	-- one clock pps: en cada pps se mantiene en alto la bandera one_clk_pps durante un ciclo de reloj de 40MHz
	-- detector de flancos
	-- state register
  process(clk_40mhz,reset)
  begin
  	if (reset='1') then
        statepps_reg <= zero;
    elsif (clk_40mhz'event and clk_40mhz='1') then
        statepps_reg <= statepps_next;
    end if;
  end process;
  -- next-state/output logic
  process(statepps_reg,pps)
  begin
     statepps_next <= statepps_reg;
     one_clk_pps <= '0';
     case statepps_reg is
        when zero=>
           if pps= '1' then
              statepps_next <= edge;
           end if;
        when edge =>
           one_clk_pps <= '1';
           if pps= '1' then
              statepps_next <= one;
           else
              statepps_next <= zero;
           end if;
        when one =>
           if pps= '0' then
              statepps_next <= zero;
           end if;
     end case;
  end process;

-----------------------------------------------------------------------------

-----------------------------------------------------------------------------

	-- registros de datos por segundo
	process(clk_40mhz, reset)
	begin
		for i in L_ARRAY_PPS-1 downto 0 loop
			if (reset = '1') then
				array_pps_reg(i) <= (others => '0');
			elsif (clk_40mhz'event and clk_40mhz = '1') then
				array_pps_reg(i) <= array_pps_next(i);
			end if;
		end loop;
	end process;
	--next state logic
	array_pps_next(L_ARRAY_PPS-10)<= x"FFFFFFFF" when (one_clk_pps = '1') else array_pps_reg(L_ARRAY_PPS-10);
	array_pps_next(L_ARRAY_PPS-9)<= "11" & "000" & std_logic_vector(cont_clk_entre_pps_reg(26 downto 0)) when (one_clk_pps = '1') else array_pps_reg(L_ARRAY_PPS-9);	
	array_pps_next(L_ARRAY_PPS-8)<= "11" & "001" & "00000000000" & ptemperatura when (one_clk_pps = '1') else array_pps_reg(L_ARRAY_PPS-8);
	array_pps_next(L_ARRAY_PPS-7)<= "11" & "010" & "00000000000" & ppresion when (one_clk_pps = '1') else array_pps_reg(L_ARRAY_PPS-7);
	array_pps_next(L_ARRAY_PPS-6)<= "11" & "011" & "000" & phora & pminutos & psegundos when (one_clk_pps = '1') else array_pps_reg(L_ARRAY_PPS-6);
	array_pps_next(L_ARRAY_PPS-5)<= "11" & "100" & "000" & latitude1_port & latitude2_port & latitude3_port when (one_clk_pps = '1') else array_pps_reg(L_ARRAY_PPS-5);
	array_pps_next(L_ARRAY_PPS-4)<= "11" & "100" & "001" & longitude1_port & longitude2_port & latitude4_port when (one_clk_pps = '1') else array_pps_reg(L_ARRAY_PPS-4);
	array_pps_next(L_ARRAY_PPS-3)<= "11" & "100" & "010" & ellipsoid1_port & longitude3_port & longitude4_port when (one_clk_pps = '1') else array_pps_reg(L_ARRAY_PPS-3);
	array_pps_next(L_ARRAY_PPS-2)<= "11" & "100" & "011" & ellipsoid2_port & ellipsoid3_port & ellipsoid4_port when (one_clk_pps = '1') else array_pps_reg(L_ARRAY_PPS-2);
	array_pps_next(L_ARRAY_PPS-1)<= "11" & "100" & "100" & num_track_sat_port & num_vis_sat_port & rsf_port when (one_clk_pps = '1') else array_pps_reg(L_ARRAY_PPS-1);

------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------
	--adquisicion de las muestras de los canales
	process(clk_40mhz, reset)
	begin	
  	for i in (L_ARRAY_MUESTRAS-1) downto 0 loop
     	if (reset='1') then
      	muestras_adc1_reg(i) <= (others=>'0');
        muestras_adc2_reg(i) <= (others=>'0');
        muestras_adc3_reg(i) <= (others=>'0');
     	elsif (clk_40mhz'event and clk_40mhz='1') then
        muestras_adc1_reg(i) <= muestras_adc1_next(i);
        muestras_adc2_reg(i) <= muestras_adc2_next(i);
        muestras_adc3_reg(i) <= muestras_adc3_next(i);
     	end if;
   		-- next state logic
     	if (i = (L_ARRAY_MUESTRAS-1)) then
				muestras_adc1_next(i) <= data_adc1;
				muestras_adc2_next(i) <= data_adc2;
				muestras_adc3_next(i) <= data_adc3;
			else
				muestras_adc1_next(i) <= muestras_adc1_reg(i+1);
				muestras_adc2_next(i) <= muestras_adc2_reg(i+1);
				muestras_adc3_next(i) <= muestras_adc3_reg(i+1);
			end if;
		end loop;
	end process;

-----------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------
	--trigger
	process(clk_40mhz, reset)
  begin
    if (reset='1') then
      tr_status_reg   	<= (others => '0');
      ctr_status_reg   	<= (others => '0');
 			cont_trigger_reg 	<= (others => '0');
    elsif (clk_40mhz'event and clk_40mhz='1') then
      tr_status_reg 		<= tr_status_next;
      ctr_status_reg 		<= ctr_status_next;
      cont_trigger_reg 	<= cont_trigger_next;
    end if;
  end process;
	-- El trigger lo hago en el bin 4 porque luego pierdo un clock en la maquina de estados
  -- next state logic
  s_tr1 <=	'1' when ((unsigned(muestras_adc1_reg(4)) >= unsigned(subtrigg_set1)) and 
											(unsigned(muestras_adc1_reg(3)) >= unsigned(trigg_set1)) and
                      (unsigned(muestras_adc1_reg(2)) < unsigned(trigg_set1)) and
                      (unsigned(muestras_adc1_reg(1)) < unsigned(trigg_set1)) ) else
            '0';
  s_tr2 <=	'1' when ((unsigned(muestras_adc2_reg(4)) >= unsigned(subtrigg_set2)) and
                      (unsigned(muestras_adc2_reg(3)) >= unsigned(trigg_set2)) and
                      (unsigned(muestras_adc2_reg(2)) < unsigned(trigg_set2)) and
                      (unsigned(muestras_adc2_reg(1)) < unsigned(trigg_set2)) ) else
            '0';
  s_tr3 <=	'1' when ((unsigned(muestras_adc3_reg(4)) >= unsigned(subtrigg_set3)) and
                      (unsigned(muestras_adc3_reg(3)) >= unsigned(trigg_set3)) and
                      (unsigned(muestras_adc3_reg(2)) < unsigned(trigg_set3)) and
                      (unsigned(muestras_adc3_reg(1)) < unsigned(trigg_set3)) ) else
            '0';
  s_tr 	<=	'1' when ((s_tr1 = '1') or
                      (s_tr2 = '1') or
                      (s_tr3 = '1') ) else
            '0';

  tr_status_next 		<=	"01" & s_tr3 & s_tr2 & s_tr1 & std_logic_vector(cont_clk_entre_pps_reg(26 downto 0)) when (s_tr = '1') else
												tr_status_reg; 
  ctr_status_next 	<=	"10" & std_logic_vector(cont_trigger_reg) when (s_tr = '1') else	
												ctr_status_reg; 

  cont_trigger_next <= 	cont_trigger_reg + 1 when (s_tr = '1') else
                       	cont_trigger_reg;

----------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------
	--scalers
	-- sub-trigger: se controla que tengamos un subtrigger y que no tengamos un trigger en los proximos dos clocks
	process(clk_40mhz, reset)
  begin
    if (reset='1') then
			charge1_reg <= (others => '0');
			charge2_reg <= (others => '0');
			charge3_reg <= (others => '0');
			array_scalers_reg(L_ARRAY_SCALERS-1) <= (others => '0');
			array_scalers_reg(L_ARRAY_SCALERS-2) <= (others => '0');
			array_scalers_reg(L_ARRAY_SCALERS-3) <= (others => '0');
    elsif (clk_40mhz'event and clk_40mhz='1') then
			charge1_reg <= charge1_next;
			charge2_reg <= charge2_next;
			charge3_reg <= charge3_next;
			array_scalers_reg(L_ARRAY_SCALERS-1) <= array_scalers_reg(L_ARRAY_SCALERS-1);
			array_scalers_reg(L_ARRAY_SCALERS-2) <= array_scalers_reg(L_ARRAY_SCALERS-2);
			array_scalers_reg(L_ARRAY_SCALERS-3) <= array_scalers_reg(L_ARRAY_SCALERS-3);
    end if;
  end process;
  -- next state logic
  --s_subtr1 <=	'1' when unsigned(muestras_adc1_reg(2)) >= unsigned(subtrigg_set1) and 
  s_subtr1 <=	'1' when unsigned(muestras_adc1_reg(2)) > to_unsigned(1023, muestras_adc1_reg'length) and 
											unsigned(muestras_adc1_reg(1)) < unsigned(muestras_adc1_reg(2)) and
                   		(unsigned(muestras_adc1_reg(3)) < unsigned(muestras_adc1_reg(2)) or 
											(unsigned(muestras_adc1_reg(3)) = unsigned(muestras_adc1_reg(2)) and 
											unsigned(muestras_adc1_reg(4)) < unsigned(muestras_adc1_reg(2)))) and
											unsigned(muestras_adc1_reg(2)) < unsigned(trigg_set1) and 
											unsigned(muestras_adc1_reg(3)) < unsigned(trigg_set1) and
											unsigned(muestras_adc1_reg(4)) < unsigned(trigg_set1) else
                		'0';
  --s_subtr2 <=	'1' when unsigned(muestras_adc2_reg(2)) >= unsigned(subtrigg_set2) and 
  s_subtr2 <=	'1' when unsigned(muestras_adc2_reg(2)) > to_unsigned(1023, muestras_adc2_reg'length) and 
											unsigned(muestras_adc2_reg(1)) < unsigned(muestras_adc2_reg(2)) and
                   		(unsigned(muestras_adc2_reg(3)) < unsigned(muestras_adc2_reg(2)) or 
											(unsigned(muestras_adc2_reg(3)) = unsigned(muestras_adc2_reg(2)) and 
											unsigned(muestras_adc2_reg(4)) < unsigned(muestras_adc2_reg(2)))) and
											unsigned(muestras_adc2_reg(2)) < unsigned(trigg_set2) and 
											unsigned(muestras_adc2_reg(3)) < unsigned(trigg_set2) and
											unsigned(muestras_adc2_reg(4)) < unsigned(trigg_set2) else
                		'0';
  --s_subtr3 <=	'1' when unsigned(muestras_adc3_reg(2)) >= unsigned(subtrigg_set3) and 
  s_subtr3 <=	'1' when unsigned(muestras_adc3_reg(2)) > to_unsigned(1023, muestras_adc3_reg'length) and 
											unsigned(muestras_adc3_reg(1)) < unsigned(muestras_adc3_reg(2)) and
                   		(unsigned(muestras_adc3_reg(3)) < unsigned(muestras_adc3_reg(2)) or 
											(unsigned(muestras_adc3_reg(3)) = unsigned(muestras_adc3_reg(2)) and 
											unsigned(muestras_adc3_reg(4)) < unsigned(muestras_adc3_reg(2)))) and
											unsigned(muestras_adc3_reg(2)) < unsigned(trigg_set3) and 
											unsigned(muestras_adc3_reg(3)) < unsigned(trigg_set3) and
											unsigned(muestras_adc3_reg(4)) < unsigned(trigg_set3) else
                		'0';
  s_subtr <=	'1' when  (	(s_subtr1 = '1') or (s_subtr2 = '1') or (s_subtr3 = '1') ) else
                	'0';
	charge1_next <= charge1_reg + muestras_adc1_reg'left - muestras_adc1_reg'right;
	charge2_next <= charge2_reg + muestras_adc2_reg'left - muestras_adc2_reg'right;
	charge3_next <= charge3_reg + muestras_adc3_reg'left - muestras_adc3_reg'right;
	
	array_scalers_next(L_ARRAY_SCALERS-1) <= "01" & s_subtr3 & s_subtr2 & s_subtr1 & std_logic_vector(cont_clk_entre_pps_reg(26 downto 0)) when (s_subtr = '1') else
																							array_scalers_reg(L_ARRAY_SCALERS-1);
	array_scalers_next(L_ARRAY_SCALERS-2) <= "00" & std_logic_vector(charge1_reg) & std_logic_vector(charge2_reg) & std_logic_vector(charge3_reg) when (s_subtr = '1') else
																							array_scalers_reg(L_ARRAY_SCALERS-2); --valores de carga por canal
	array_scalers_next(L_ARRAY_SCALERS-3) <= "00" & muestras_adc1_reg(2) & muestras_adc2_reg(2) & muestras_adc3_reg(2) when (s_subtr = '1') else
																							array_scalers_reg(L_ARRAY_SCALERS-3); --se manda el maximo del pulso tambien
		 	
----------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------
	-- FSM que controla todo
	--================================================================
-- state and data registers
--================================================================
    process (clk_40mhz, reset)
    begin
        if (reset = '1') then
            state_reg <= STATE_IDLE;
            wr_fifo_en_reg <= '0';
            wr_count_reg <= (others => '0');
						data_to_fifo_reg <= (others => '0');
        elsif (clk_40mhz'event and clk_40mhz = '1') then
            state_reg <= state_next;
            wr_fifo_en_reg <= wr_fifo_en_next;
            wr_count_reg <= wr_count_next;
						data_to_fifo_reg <= data_to_fifo_next;
        end if;
    end process;
--=================================================================
--next-state logic & data path functional units/routing
--=================================================================
    --process(state_reg, s_tr, s_subtr, one_clk_pps, wr_count_reg, pfifo_status)
    process(state_reg, status, wr_count_reg, pfifo_status)
    begin
    	state_next <= state_reg; 								-- default volver al estado inicial
      wr_fifo_en_next <= '0';       					-- default deshabilitar la escritura en la fifo
			wr_count_next <= (others => '0');
			data_to_fifo_next <= data_to_fifo_reg;	--default mantener el valor
      case state_reg is
      	when STATE_IDLE =>
					if (pfifo_status(2) = '0') then			-- si la FIFO no esta llena pfifo_status <= full & pfull & empy
						case status is
							when "001" | "011" | "101" | "111" => -- le doy prioridad a la escritura de los datos pps cada segundo
								state_next <= STATE_ATT_PPS;
							when "100" | "110" => 
								state_next <= STATE_ATT_TR;
							when "010" =>
								state_next <= STATE_ATT_SUBTR;
							when others => --"000"
								state_next <= STATE_IDLE;
						end case;	
--        		if s_tr = '1' then
--		  				state_next <= STATE_ATT_TR;	
--		  			elsif s_subtr = '1' then
--		  				state_next <= STATE_ATT_SUBTR;	
--		  			elsif one_clk_pps = '1' then
--							state_next <= STATE_ATT_PPS;
--						end if;
					else
						state_next <= STATE_IDLE;
          end if;

				when STATE_ATT_TR =>
					wr_fifo_en_next <= '1';
					wr_count_next <= wr_count_reg + 1;
					data_to_fifo_next <= "00" & muestras_adc1_reg(0) & muestras_adc2_reg(0) & muestras_adc3_reg(0);
					if (wr_count_reg = (L_ARRAY_MUESTRAS - 1)) then
						state_next <= STATE_SEND_TR_STATUS;
					else
						state_next <= STATE_ATT_TR;
					end if;

				when STATE_SEND_TR_STATUS =>
					wr_fifo_en_next <= '1';
					data_to_fifo_next <= tr_status_reg;
					state_next <= STATE_SEND_CTR_STATUS;
					
				when STATE_SEND_CTR_STATUS =>
					wr_fifo_en_next <= '1';
					data_to_fifo_next <= ctr_status_reg;
					state_next <= STATE_IDLE;

        when STATE_ATT_SUBTR =>
					wr_fifo_en_next <= '1';
					wr_count_next <= wr_count_reg + 1;
					data_to_fifo_next <= array_scalers_reg(to_integer(wr_count_reg));
					if (wr_count_reg = (L_ARRAY_SCALERS - 1)) then
						state_next <= STATE_IDLE;
					else
						state_next <= STATE_ATT_SUBTR;
					end if;

        when STATE_ATT_PPS =>
					wr_fifo_en_next <= '1';
					wr_count_next <= wr_count_reg + 1;
					data_to_fifo_next <= array_pps_reg(to_integer(wr_count_reg));
					if (wr_count_reg = (L_ARRAY_PPS - 1)) then
						state_next <= STATE_IDLE;
					else
						state_next <= STATE_ATT_PPS;
					end if;
     end case;
    end process;

		status <= s_tr & s_subtr & one_clk_pps;
		data_out <=	data_to_fifo_reg;
		pwr_enA <= wr_fifo_en_reg;

	
end architecture rtl;

