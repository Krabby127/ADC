-------------------------------------------------------
-- Design Name : adclb
-- File Name   : adclb.vhd
-- Function    : 2wire i/f for ADC
-- Author      : Michael Eller
-------------------------------------------------------
-- Standard libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity adclb is
    port (
             reset       :in  std_logic; -- reset ADC
             clk         :in  std_logic; -- clock
             clrb        :in  std_logic; -- clear interrupt bit
             scl         :out std_logic; -- I2C clock
             sdai        :in  std_logic; -- data in
             sdao        :out std_logic; -- data out
             sda_oe      :out std_logic; -- data out enable
             diff_flag   :out std_logic; -- whether the threshold has been met
             max         :out std_logic_vector (7 downto 0); -- max value read from ADC
				 min         :out std_logic_vector (7 downto 0) -- min value read from ADC
);
end entity;


architecture rtl of adclb is

    signal datao     :std_logic_vector (7 downto 0); -- data output
    signal datai     :std_logic_vector (7 downto 0); -- data input
    signal amux      :std_logic_vector (7 downto 0); -- address selection
    signal dmux      :std_logic_vector (7 downto 0); -- data selection
    signal max_seen  :std_logic_vector (7 downto 0); -- maximum value seen so far
    signal min_seen  :std_logic_vector (7 downto 0); -- minimum value seen so far
    signal val       :std_logic_vector (7 downto 0); -- internal signal for value read
    signal diff      :std_logic_vector (8 downto 0); -- difference between min and max
    signal count     :std_logic_vector (6 downto 0); -- clock counter
    signal bit_cnt   :std_logic_vector (6 downto 0); -- bit counter
    signal init_cnt  :std_logic_vector (2 downto 0); -- initialization counter
    signal state     :std_logic_vector (3 downto 0); -- the current state we're in
    signal upd_cnt   :std_logic_vector (10 downto 0); -- uptime counter
    signal diff_i    :std_logic; -- internal difference flag
    signal count_half:std_logic; -- midway state counter
    signal count_end :std_logic; -- state counter
    signal sdao_i    :std_logic; -- internal data out
    signal upd_i     :std_logic; -- internal uptime counter finish flag

begin

    sdao<=sdao_i;
    max<=max_seen;
	 min<=min_seen;
    diff_flag<=diff_i;

    count_proc: process (clk, reset)
    begin
        if reset = '1' then
            count <= "0000000";
            count_end<='0';
            count_half<='0';
            bit_cnt <= "0000000";
            init_cnt <= "000";
            sda_oe<='0';
            max_seen<="00000000";
            min_seen<="11111111";
        -- Merely maintaining a large 7 bit counter
        -- Counting to 127
        elsif clk'event and clk='1' then
            count <= count+'1';
            if count="0111110" then
                count_half<='1';
            else
                count_half<='0';
            end if;
            if count="1111110" then
                count_end<='1';
            -- high every 1280 ns for 1 tick
            else
                -- only high for one tick
                count_end<='0';
            end if;
            -- Increment to next state
            -- state 0101 lives for 1280 ns

            -- Initialization timer
            if state="0101" and count_end='1' then
                if init_cnt="110" then
                    -- turn off init_cnt
                    init_cnt<="000";
                else
                    init_cnt<=init_cnt+'1';
                end if;
            end if;


            -- Reset bit_cnt at states 1,5,9,d
            -- Intended for only d and 9, but doesn't matter for 1 and 5
            if state(1 downto 0)="01" then
                bit_cnt<="0000000";
            -- Increment bit_cnt if in stage 3 or b
            elsif state(1 downto 0)="11" and count_end='1' then
                bit_cnt<=bit_cnt+'1';
            end if;
            -- count_end is the state transition timer
            -- count_half means we're in the middle of a state
            -- good time to transmit data
            if count_half='1' then
                if state="1100" and bit_cnt="0010010" then
                    -- NAK from state 0d12 0hC
                    sdao_i<='1'; --NAK
                elsif bit_cnt="0010010" then
                    sdao_i<=sdao_i; --NAK
                elsif state(2 downto 0)="000" then
                    sdao_i<='1'; -- NAK
                elsif state(2 downto 0)="101" then
                    sdao_i<='1'; -- NAK
                elsif state="1100" and bit_cnt="0010010" then
                    sdao_i<='1'; -- NAK; done reading
                                 -- just finished reading 2 bytes
                elsif state="1011" and bit_cnt="0010010" then
                    sdao_i<='0'; -- ACK
                elsif bit_cnt="0010010" then
                    sdao_i<=sdao_i;
                elsif state(2 downto 0)="001" then
                    sdao_i<='0';
                    sdao_i<=datao(7);
                end if;
            end if;


            if count_half='1' then
                -- bit_cnt is 8 or 17 or if done with init with bit_cnt at 0x1A 0d26
                -- after 1 packet or 3 packets in case of init
                -- just finished address byte
                if bit_cnt="0001000" or bit_cnt="0010001" or (state(3)='0' and bit_cnt="0011010") then
                    --(state(3)='1' and bit_cnt="011011") then
                    -- ACK
                    sda_oe<='0';
                -- packets 4,5,6,7,8,9,10
                -- bit_cnt > 8, /= 36, /= 45, /= 54, /= 63, /= 72, /= 81, /= 90
                -- ony if in active reading/writing
                elsif state(3)='1' and bit_cnt>"0001000" and bit_cnt/="0010001"  and bit_cnt/="0101101" and bit_cnt/="0110110" and bit_cnt/="0111111" and bit_cnt/="1001000" and bit_cnt/="1010001" then
                    -- Corresponding ACK after each of 8 bits
                    sda_oe<='0';
                else
                    -- Otherwise, keep high
                    sda_oe<='1';
                end if;
            end if;

            -- toggle sclock high when in states 2,A,4,C
            -- keep high when sleeping (state 8) to prepare for start bit
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
            -- set to state 0
            state <= (others=>'0');
        elsif clk'event and clk='1' then
            -- count_end occurs when count reaches 127
            -- 2.56 us
            if count_end='1' then
                -- if we're still in initialization, increment state
                -- states 0,1,2,3
                if state(3 downto 2)= "00" then
                    state <= state+'1';
                elsif state = "0100" then -- after reading 27 bits
                                          -- go from state 4 to 5
                    if bit_cnt="0011011" then -- 0x1B 0d27
                        state <= "0101"; -- now in state 5
                    else
                        state <= "0011"; -- not 27 bits read: go to state 3
                    end if;
                elsif state = "0101" then -- if in state 5 after 2.56 us
                    if init_cnt="110" then -- once initialization is done, go to state 8
                        state <= "1000";
                    else
                        state <= "0001"; -- otherwise go to state 1
                    end if;
                elsif (state = "1000" and upd_i='1') or
                (state(3 downto 2)="10" and state(1 downto 0)/="00") then
                    -- upd_i time is 2622.72 us
                    -- if in state 8 after waiting for upd_i time, or in state 9,a,b
                    -- go to next state
                    state <= state+'1';
                elsif state = "1100" then
                    -- after reading 18 bits in state c,
                    -- go to state d
                    -- change to reading 18 bits for ADC
                    if bit_cnt="0010010" then
                        state <= "1101";
                        diff<=('0'&max_seen)-('0'&min_seen);
                    else
                        -- otherwise, go back to reading in state b
                        state <= "1011";
                    end if;
                elsif state = "1101" then
                    if diff>"000110000" then -- some arbitrary number right now
                        diff_i<='1';
                    else
                        diff_i<='0';
                    end if;
                    -- go from d to 8
                    -- not done reading yet
                    state <= "1000";
                end if;
            end if;
        end if;
    end process;



    dio_proc: process
    begin
        wait until clk'event and clk='1';
        if state="1011" and count_half='1' then
            -- v Reading the data v
            datai<=datai(6 downto 0) & sdai;
        -- ^ Reading the data ^
        end if;
        -- before writes, in state 1 or 9
        if state(2 downto 0)="001" then
            -- Slave address check
            datao<="10100010"; --chip address, write

        elsif state="1100" and count_half='1' and bit_cnt="0010011" then
            -- Slave address check
            datao<="10100011"; -- chip address, read
                               -- read from states b or 3 every count_half
        elsif state(2 downto 0)="011" and count_half='1' then
            -- shift left one bit
            datao<=datao(6 downto 0) & '0';
        end if;
        if reset='1' or clrb='1' then
            upd_cnt <= (others=>'0');
            diff_i<='0';
        elsif state="1000" and count_end='1' and upd_i='0' then
            upd_cnt<=upd_cnt+'1';
        end if;
        if upd_cnt="11111111111" and count_end='1' then
            -- upd_cnt maxxed every 1.31072 ms
            -- state changes from == 8
            upd_i <= '1';
        -- upd_i goes high every 3.13216 ms for 1280 ns
        elsif count_end='1' then
            upd_i <= '0';
        end if;
    end process;

    -- '0'&XXXX forces unsigned math
    diff<=('0'&max_seen)-('0'&min_seen);

    reg_proc: process
    begin
        -- all the reading is done in state b
        wait until clk'event and clk='1';
        -- state b, bit_cnt 0d35
        if state="1011" and bit_cnt="0100011" and count_end='1' then
            val(7 downto 4) <= datai(3 downto 0);
        end if;
        -- state b, bit_cnt 0d44
        if state="1011" and bit_cnt="0101100" and count_end='1' then
            val(3 downto 0) <= datai(7 downto 4);
        end if;
        if state="1011" and bit_cnt="0110101" and count_end='1' then
            if val>max_seen then
                max_seen<=val;
            else
                max_seen<=max_seen;
            end if;
            if val<min_seen then
                min_seen<=val;
            else
                min_seen<=min_seen;
            end if;
        end if;
        if reset='1' or clrb='1' then
            diff_flag<='0';
        end if;
    end process;

end architecture;

