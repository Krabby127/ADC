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
                 diff_flag   :out std_logic;
                 max         :inout std_logic_vector (7 downto 0);
                 min         :inout std_logic_vector (7 downto 0)
             );
    end component;

    signal clk : std_logic;
    signal reset : std_logic;
    signal sdai : std_logic;
    signal sdao : std_logic;
    signal sda_oe : std_logic;
    signal diff_i : std_logic;
--    signal diff : std_logic_vector(8 downto 0);
    signal upd : std_logic;
	 signal scl : std_logic;
	 signal start_bit : std_logic;


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
                 max         => open,
                 min         => open
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
		  start_bit <= '0';
        sdai <= '0';
        upd <= '0';
        wait for 200ns;
        reset <= '0';
		  
--		  wait for 200us;
--		  reset<='1';
--		  wait for 200ns;
--		  reset<='0';

        wait for 6103us;
        sdai <= '1';
        wait for 2us;
        sdai <= '0';


        -- wait for 510920 ns; -- startup period
        -- start_bit
--        if scl = '1' and sdao = '0' and falling_edge(sdao) then
--            start_bit <= '1';
--            bit_count <= "0000000";
--				-- report state;
--            assert start_bit='0' report "start_bit got did\n" severity note;
--        end if;
			wait;
    end process;
end;
