library ieee, UNISIM;
use     ieee.std_logic_1164.all;
use     ieee.std_logic_unsigned.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

entity testfile is
    port
    (
        -- Host side
        sys_clk  : in  std_logic;
        sw_i     : in  std_logic_vector(  9 downto 0);
        key_i    : in  std_logic_vector(  3 downto 0);
        sdr_busy : in  std_logic;
        sdr_done : in  std_logic;
        sdr_rw   : out std_logic_vector(  1 downto 0);
        sdr_addr : out std_logic_vector( 24 downto 0);
        data_i   : in  std_logic_vector(127 downto 0);
        data_o   : out std_logic_vector(127 downto 0);
        led_o    : out std_logic_vector(  9 downto 0)
    );
end entity;

architecture rtl of testfile is
    signal address : std_logic_vector(24 downto 0);
    signal flag_r  : std_logic;
    signal flag_w  : std_logic;
    signal flag_rw : std_logic_vector(1 downto 0);
begin
    
    data_o(127 downto 10) <= (others => '0');
    flag_rw <= 
    "00" when sdr_done = '1' else
    "10" when flag_r   = '1' else
    "01" when flag_w   = '1' else
    flag_rw;
    
    sdr_rw <= flag_rw;
    
    test : process(sys_clk)
    begin
        if rising_edge(sys_clk) then
            if(sdr_busy = '0') then
                if(sdr_done = '1') then
                    flag_r <= '0';
                    flag_w <= '0';
                elsif(key_i(3) = '0') then
                    address(9 downto 0) <= sw_i;
                elsif(key_i(2) = '0') then -- Write
                    flag_w <= '1';
                    data_o(9 downto 0) <= sw_i;
                elsif(key_i(1) = '0') then -- Read
                    flag_r <= '1';
                    if(sdr_done = '1') then
                        led_o(9 downto 0) <= data_i(9 downto 0);
                    end if;
                end if;
            end if;
        end if;
    end process test;
end architecture;