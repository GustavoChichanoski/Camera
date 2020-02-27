library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package par_vga is
    
    constant VGA_HOR_PIXEL : natural := 640;
    constant VGA_VER_PIXEL : natural := 480;
     
    -- VGA Horizontal Constant
    constant VGA_HOR_SYNC  : natural := 96; 
    constant VGA_HOR_BACK  : natural := VGA_HOR_SYNC + 48;
    constant VGA_HOR_ACT   : natural := VGA_HOR_BACK + VGA_HOR_PIXEL;
    constant VGA_HOR_MAX   : natural := VGA_HOR_ACT  + 16;
    -- VGA Vertical Constant
    constant VGA_VER_SYNC  : natural := 2;
    constant VGA_VER_BACK  : natural := VGA_VER_SYNC + 33;
    constant VGA_VER_ACT   : natural := VGA_VER_BACK + VGA_VER_PIXEL;
    constant VGA_VER_MAX   : natural := VGA_VER_ACT  + 10;
    
end package ;