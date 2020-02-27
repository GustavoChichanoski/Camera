library ieee;
use     ieee.std_logic_1164.all;
use     ieee.std_logic_unsigned.all;
use     ieee.numeric_std.all;
use     work.vga_param.all;
use     work.vga_function.all;

entity my_vga is
    port
    (
        pll_clk        : in  std_logic;
        rst            : in  std_logic;
        img            : in  std_logic_vector(15 downto 0);
        RGB            : out std_logic_vector(23 downto 0);
        hsync          : out std_logic;
        vsync          : out std_logic;
        disp_ena       : out std_logic;
        position       : out address_type
    );
end entity;

architecture rtl of my_vga is
    -- Flags
    signal flag_horz_max      : std_logic;
    signal flag_vert_max      : std_logic;
    signal flag_horz_enable   : std_logic;
    signal flag_vert_enable   : std_logic;
    -- Positions
    signal position_horz      : address_type := VGA_HOR_MAX;
    signal position_vert      : address_type := VGA_VER_MAX;
    signal position_horz_next : address_type;
    signal position_vert_next : address_type;
    signal address            : address_type;
    signal disp_ena_r         : std_logic;
    -- Alias
    alias  red                : std_logic_vector(5 downto 0) is img( 7 downto  2);
    alias  green              : std_logic_vector(5 downto 0) is img(15 downto 10);
    alias  blue               : std_logic_vector(5 downto 0) is img(23 downto 19);
begin
    -- Calc Flags
    flag_horz_max    <= 
    '0' when (position_horz < VGA_HOR_MAX)                                      else '1';
    flag_vert_max    <= 
    '0' when (position_vert < VGA_VER_MAX)                                      else '1';
    flag_horz_enable <= 
    '1' when ((VGA_HOR_BACK < position_horz) and (position_horz < VGA_HOR_ACT)) else '0';
    flag_vert_enable <= 
    '1' when ((VGA_VER_BACK < position_vert) and (position_vert < VGA_VER_ACT)) else '0';
    
    -- Calc Position
    position_horz_next <= 
    (position_horz + ONE) when (flag_horz_max = '0') else (others => '0');
    position_vert_next <= 
    (others => '0')       when (flag_vert_max = '1') else 
    (position_vert + ONE) when (flag_horz_max = '1') else position_vert;
    
    -- Calc outputs
    hsync      <= '0' when (position_horz < VGA_HOR_SYNC)                      else '1';
    vsync      <= '0' when (position_vert < VGA_VER_SYNC)                      else '1';
    disp_ena_r <= '0' when (flag_horz_enable = '1' and flag_vert_enable = '1') else '1';
    RGB        <= 
    red & "000" & green & "00" & blue & "000"          when (disp_ena_r = '1') else (others => '1');
    
    position <= calc_addr(position_horz,position_vert) when (disp_ena_r = '1') else (others => '0');
    disp_ena <= disp_ena_r;
    
    -- Sequential code
    process(pll_clk) begin
        -- Reset regsiter
        if(rst = '0') then
            -- Reset of positions
            position_vert <= VGA_VER_ACT;
            position_horz <= VGA_HOR_ACT;
        elsif(pll_clk'event and pll_clk = '1') then
            -- Update positon
            position_horz <= position_horz_next;
            position_vert <= position_vert_next;
        end if;
    end process;
    
end architecture;