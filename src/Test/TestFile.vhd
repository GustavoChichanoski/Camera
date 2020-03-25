library ieee, UNISIM;
use     ieee.std_logic_1164.all;
use     ieee.std_logic_unsigned.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

entity TestFile is
    port
    (
        -- Host side
        sys_clk   : in  std_logic;
        sw_i      : in  std_logic_vector(  9 downto 0);
        key_i     : in  std_logic_vector(  1 downto 0);
        sdr_busy  : in  std_logic;
        sdr_done  : in  std_logic;
        sdr_state : in  std_logic_vector(  2 downto 0);
        data_i    : in  std_logic_vector(127 downto 0);
        sdr_first : in  std_logic;
        sdr_rw    : out std_logic_vector(  1 downto 0);
        sdr_addr  : out std_logic_vector( 24 downto 0);
        data_o    : out std_logic_vector(127 downto 0);
        led_o     : out std_logic_vector(  9 downto 0) := (others => '0');
        hex0      : out std_logic_vector( 3 downto 0);
        hex1      : out std_logic_vector( 3 downto 0);
        hex2      : out std_logic_vector( 3 downto 0);
        hex3      : out std_logic_vector( 3 downto 0);
        hex4      : out std_logic_vector( 3 downto 0);
        hex5      : out std_logic_vector( 3 downto 0)
    );
end entity;

architecture rtl of TestFile is
    signal address : std_logic_vector(24 downto 0) := (others => '0');
    signal data    : std_logic_vector(15 downto 0);
    signal data2   : std_logic_vector(15 downto 0);
    signal flag_rw : std_logic_vector( 1 downto 0);
begin
    
    led_o(9)          <= sdr_busy;
    led_o(8)          <= sdr_done;
    led_o(7 downto 6) <= flag_rw;
    led_o(5)          <= sdr_first;
    led_o(4)          <= sys_clk;
    led_o(2 downto 0) <= sdr_state;
    
    sdr_rw                <= flag_rw;
    address(24 downto 10) <= (others => '0');
    data_o(127 downto 16) <= (others => '0');
    data_o( 15 downto  0) <= data2;
    data    <= data_i(15 downto 0) when flag_rw = "01" and sdr_done = '1' else data;
    test : process(sys_clk)
    begin
        if(sdr_done = '1') then
            flag_rw <= "00";
        else
            if(sdr_busy = '0') then
                if(key_i = "00") then
                    address(9 downto 0) <= sw_i;
                    flag_rw             <= "00";
                elsif(key_i = "10") then -- Write
                    data2(9 downto 0)   <= sw_i;
                    flag_rw             <= "10";
                elsif(key_i = "01") then -- Read
                    flag_rw             <= "01";
                end if;
            end if;
        end if;
    end process test;
    
    hex0 <= address(3 downto 0);
    hex1 <= address(7 downto 4);
    hex2 <= data2(3 downto 0);
    hex3 <= data2(7 downto 4);
    hex4 <= data(3 downto 0);
    hex5 <= data(7 downto 4);
    
end architecture;