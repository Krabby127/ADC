-------------------------------------------------------
-- Design Name : accelb
-- File Name   : accelb.vhd
-- Function    : 2wire i/f for accelerometer
-- Author      : J Rigg
-------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

entity accelb is
    port (
             reset       :in  std_logic;
             clk         :in  std_logic;
             clrb        :in  std_logic;
             scl         :out std_logic;
             sdai        :in  std_logic;
             sdao        :out std_logic;
             sda_oe      :out std_logic;
             bump        :out std_logic;
             st          :out std_logic_vector (7 downto 0);
             xd          :out std_logic_vector (11 downto 0);
             yd          :out std_logic_vector (11 downto 0);
             zd          :out std_logic_vector (11 downto 0)
         );
end entity;


architecture rtl of accelb is

signal datao     :std_logic_vector (7 downto 0);
signal datai     :std_logic_vector (7 downto 0);
signal amux      :std_logic_vector (7 downto 0);
signal dmux      :std_logic_vector (7 downto 0);
signal xdi       :std_logic_vector (11 downto 0);
signal ydi       :std_logic_vector (11 downto 0);
signal zdi       :std_logic_vector (11 downto 0);
signal lastx     :std_logic_vector (11 downto 0);
signal lasty     :std_logic_vector (11 downto 0);
signal lastz     :std_logic_vector (11 downto 0);
signal bx        :std_logic_vector (12 downto 0);
signal by        :std_logic_vector (12 downto 0);
signal bz        :std_logic_vector (12 downto 0);
signal count     :std_logic_vector (6 downto 0);
signal bit_cnt   :std_logic_vector (6 downto 0);
signal init_cnt  :std_logic_vector (2 downto 0);
signal state     :std_logic_vector (3 downto 0);
signal upd_cnt   :std_logic_vector (10 downto 0);
signal bumpi     :std_logic;
signal bumpx     :std_logic;
signal bumpy     :std_logic;
signal bumpz     :std_logic;
signal count_half:std_logic;
signal count_end :std_logic;
signal sdao_i    :std_logic;
signal upd_i     :std_logic;

begin

sdao<=sdao_i;
xd<=xdi;
yd<=ydi;
zd<=zdi;
bump<=bumpi;

count_proc: process (clk, reset)
begin
  if reset = '1' then
    count <= "0000000";
    count_end<='0';
    count_half<='0';
    bit_cnt <= "0000000";
    init_cnt <= "000";
    sda_oe<='0';
  elsif clk'event and clk='1' then
    count <= count+'1';
    if count="0111110" then
      count_half<='1';
    else
      count_half<='0';
    end if;
    if count="1111110" then
      count_end<='1';
    else
      count_end<='0';
    end if;
    if state="0101" and count_end='1' then
      if init_cnt="110" then
        init_cnt<="000";
      else
        init_cnt<=init_cnt+'1';
      end if;
    end if;
    if state(1 downto 0)="01" then
      bit_cnt<="0000000";
    elsif state(1 downto 0)="11" and count_end='1' then
      bit_cnt<=bit_cnt+'1';
    end if;
    if count_half='1' then
      if state="1100" and bit_cnt="1011010" then
        sdao_i<='1'; --NAK
      elsif bit_cnt="1011010" then
        sdao_i<=sdao_i; --NAK
      elsif state(2 downto 0)="000" then
        sdao_i<='1';
      elsif state(2 downto 0)="101" then
        sdao_i<='1';
      elsif state="1100" and bit_cnt="0010010" then
        sdao_i<='1';
      elsif state="1011" and bit_cnt="0010010" then
        sdao_i<='0';
      elsif bit_cnt="0010010" then
        sdao_i<=sdao_i;
      else
        sdao_i<=datao(7);
      end if;
    end if;

    if count_half='1' then
      if bit_cnt="0001000" or bit_cnt="0010001" or (state(3)='0' and bit_cnt="0011010") then
         --(state(3)='1' and bit_cnt="011011") then
        sda_oe<='0';
      elsif state(3)='1' and bit_cnt>"0011010" and bit_cnt/="0100100" and bit_cnt/="0101101" and bit_cnt/="0110110" and bit_cnt/="0111111" and bit_cnt/="1001000" and bit_cnt/="1010001" and bit_cnt/="1011010" then
        sda_oe<='0';
      else
        sda_oe<='1';
      end if;
    end if;

    if state(2 downto 0)="010" or state(2 downto 0)="100" then
      scl<='0';
    else
      scl<='1';
    end if;
  end if;
end process;

state_proc: process (clk, reset)
begin
    if reset = '1' then
        state <= (others=>'0');
  elsif clk'event and clk='1' then
    if count_end='1' then
      if state(3 downto 2)= "00" then
        state <= state+'1';
      elsif state = "0100" then
        if bit_cnt="0011011" then
          state <= "0101";
        else
          state <= "0011";
        end if;
      elsif state = "0101" then
        if init_cnt="110" then
          state <= "1000";
        else
          state <= "0001";
        end if;
      elsif (state = "1000" and upd_i='1') or
            (state(3 downto 2)="10" and state(1 downto 0)/="00") then
        state <= state+'1';
      elsif state = "1100" then
        if bit_cnt="1011010" then
          state <= "1101";
        else
          state <= "1011";
        end if;
      elsif state = "1101" then
        state <= "1000";
      end if;
    end if;
  end if;
end process;

mux_p:process(init_cnt)
begin
  case init_cnt is
    when "000" => amux<="00101010"; -- 2A
                  dmux<="00000100"; -- 04 low noise, disable
    when "001" => amux<="00101101"; -- 2D
                  dmux<="00000100"; -- 04
    when "010" => amux<="00101110"; -- 2e
                  dmux<="00000100"; -- 04
    when "011" => amux<="00010111"; -- 17
                  dmux<="00010000"; -- 10
    when "100" => amux<="00011000"; -- 18
                  dmux<="00000001"; -- 01
    when "101" => amux<="00010101"; -- 15
                  dmux<="11111000"; -- f8
    when "110" => amux<="00101010"; -- 2A
                  dmux<="00000101"; -- 05 enable
    when others => amux<="00101010"; -- 2A
                   dmux<="00000100"; -- 04 disable
  end case;
end process;

dio_proc: process
begin
    wait until clk'event and clk='1';
    if state="1011" and count_half='1' then
        datai<=datai(6 downto 0) & sdai;
    end if;
    if state(2 downto 0)="001" then
        datao<="00111000"; --chip address, write
    elsif state="0100" and count_half='1' and bit_cnt="0001001" then
        datao<=amux;
    elsif state="0100" and count_half='1' and bit_cnt="0010010" then
        datao<=dmux;
    --elsif state="1100" and count_half='1' and bit_cnt="001001" then
    elsif state="1100" and count_half='1' and bit_cnt="0010011" then
        datao<="00111001"; -- chip address, read
    elsif state(2 downto 0)="011" and count_half='1' then
        datao<=datao(6 downto 0) & '0';
    end if;
    if reset='1' or clrb='1' then
        upd_cnt <= (others=>'0');
    elsif state="1000" and count_end='1' and upd_i='0' then
        upd_cnt<=upd_cnt+'1';
    end if;
    if upd_cnt="11111111111" and count_end='1' then
        upd_i <= '1';
    elsif count_end='1' then
        upd_i <= '0';
    end if;
end process;

bx<=('0'&lastx)-('0'&xdi);
by<=('0'&lasty)-('0'&ydi);
bz<=('0'&lastz)-('0'&zdi);

bumpx<='1' when (bx(12)='0' and bx(11 downto 4)/="00000000") or (bx(12)='1' and bx(11 downto 4)/="11111111") else '0';
bumpy<='1' when (by(12)='0' and by(11 downto 4)/="00000000") or (by(12)='1' and by(11 downto 4)/="11111111") else '0';
bumpz<='1' when (bz(12)='0' and bz(11 downto 4)/="00000000") or (bz(12)='1' and bz(11 downto 4)/="11111111") else '0';

reg_proc: process
begin
  wait until clk'event and clk='1';
  if state="1011" and bit_cnt="0100011" and count_end='1' then
    st <= datai;
  end if;
  if state="1011" and bit_cnt="0101100" and count_end='1' then
    xdi(11 downto 4) <= datai;
    lastx<=xdi;
  end if;
  if state="1011" and bit_cnt="0110101" and count_end='1' then
    xdi(3 downto 0) <= datai(7 downto 4);
  end if;
  if state="1011" and bit_cnt="0111110" and count_end='1' then
    ydi(11 downto 4) <= datai;
    lasty<=ydi;
  end if;
  if state="1011" and bit_cnt="1000111" and count_end='1' then
    ydi(3 downto 0) <= datai(7 downto 4);
  end if;
  if state="1011" and bit_cnt="1010000" and count_end='1' then
    zdi(11 downto 4) <= datai;
    lastz<=zdi;
  end if;
  if state="1011" and bit_cnt="1011001" and count_end='1' then
    zdi(3 downto 0) <= datai(7 downto 4);
  end if;
  if reset='1' or clrb='1' then
    bumpi<='0';
  elsif state="1100" and bit_cnt="1011010" then
    bumpi<= bumpx or bumpy or bumpz or bumpi;
  end if;
end process;

end architecture;

