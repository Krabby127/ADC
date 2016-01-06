LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_textio.all;

library std;
USE std.textio.all;

entity tb2 is
    end entity;

architecture behav2 of tb2 is
    component adclb
        port (
                 reset       :in std_logic;
                 clk         :in std_logic;
                 clrb        :in std_logic;
                 scl         :out std_logic;
                 sdai        :in std_logic;
                 sdao        :out std_logic;
                 sda_oe      :out std_logic;
                 min_flag   :out std_logic;
                 max_flag   :out std_logic;
                 diff_flag   :out std_logic;
                 max         :out std_logic_vector (7 downto 0);
                 min         :out std_logic_vector (7 downto 0);
					  value       :inout std_logic_vector (7 downto 0) -- data sent back to master
             );
    end component;

    signal clk : std_logic;
    signal reset : std_logic;
    signal sdai : std_logic;
    signal sdao : std_logic;
    signal sda_oe : std_logic;
    signal min_i : std_logic;
    signal max_i : std_logic;
    signal diff_i : std_logic;
    signal upd : std_logic;
	 signal scl : std_logic;
--	 signal start_bit : std_logic;
--	 signal stop_bit : std_logic;
--	 shared variable bit_count : integer := 0;

begin

    adc: adclb
    port map (
                 reset       => reset,
                 clk         => clk,
                 clrb        => reset,
                 scl         => scl,
                 sdai        => sdai,
                 sdao        => sdao,
                 sda_oe      => sda_oe,
                 diff_flag   => diff_i,
                 min_flag    => min_i,
                 max_flag    => max_i,
                 max         => open,
                 min         => open,
					  value		  => open
             );
				 
    clk_p:process
    begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process;

    testb:process
    begin
        reset <= '1';
--		  start_bit <= '0';
        sdai <= '0';
        upd <= '0';
        wait for 200ns;
        reset <= '0';
		  
		  wait for 5ms;
		  reset<='1';
		  wait for 200ns;
		  reset<='0';

        wait for 6103us;
        sdai <= '1';
        wait for 2us;
        sdai <= '0';



			wait;
    end process;
	 
	 
	 
--	 start_b:process
--	 begin
--		wait until falling_edge(sdao);
----			wait for 0.64us;
--			wait until falling_edge(scl);
--			if stop_bit /= '1' then
--				start_bit<='1';
--			else
--				start_bit<='0';
--			end if;
--	 end process;
--	 
--	 
--	 stop_b:process
--	 begin
--	 wait until rising_edge(scl) and sdao='0';
--	 if sdao='0' then
--		stop_bit<='1';
--	 else
--		stop_bit<='0';
--	 end if;
----			if rising_edge(sdao) then
----				stop_bit<='1';
----			else
----				stop_bit<='0';
----			end if;
--	 end process;
--	 
--	 count_bits:process
--	 begin
--		if stop_bit='1' then
--			bit_count:=0;
--		end if;
--		wait until start_bit='1';
--		if rising_edge(scl) then
--			bit_count:=bit_count+1;
--		else
--			bit_count:=bit_count;
--		end if;
--	 end process;
	 
end;
