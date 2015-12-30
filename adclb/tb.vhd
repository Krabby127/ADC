LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_textio.all;

library std;
USE std.textio.all;

entity tb is
end entity;

architecture behav of tb is

component adclb
    port (
        reset       :in  std_logic;
        clk         :in  std_logic;
        clrb        :in  std_logic;
        scl         :out std_logic;
        sdai        :in  std_logic;
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
signal upd : std_logic;
signal scl : std_logic;
signal sdao : std_logic;
signal sda_oe : std_logic;
signal diff_i : std_logic;
signal diff: std_logic_vector(7 downto 0);

--signal val : std_logic_vector(7 downto 0);

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
  max			  => open,
  min			  => open
);


clk_p:process
begin
  clk<='1';
  wait for 5 ns;
  clk <= '0';
  wait for 5 ns;
end process;

testb:process
begin
  reset <= '1';
  sdai <= '0';
  upd <= '0';
  wait for 200ns;
  reset <= '0';

  wait for 6103us;
  sdai<='1';
  wait for 2us;
  sdai<='0';
  wait;
end process;

end;

