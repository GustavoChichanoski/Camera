library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package vga_param is
    
    subtype  address_type is unsigned(24 downto 0);
    
    constant VGA_HOR_PIXEL : address_type := x"0000280";
    constant VGA_VER_PIXEL : address_type := x"00001E0";
     
    -- VGA Horizontal Constant
    constant VGA_HOR_SYNC  : address_type := x"000060"; 
    constant VGA_HOR_BACK  : address_type := VGA_HOR_SYNC + x"000030";
    constant VGA_HOR_ACT   : address_type := VGA_HOR_BACK + VGA_HOR_PIXEL;
    constant VGA_HOR_MAX   : address_type := VGA_HOR_ACT  + x"000010";
    -- VGA Vertical Constant
    constant VGA_VER_SYNC  : address_type := x"000002";
    constant VGA_VER_BACK  : address_type := VGA_VER_SYNC + x"000021";
    constant VGA_VER_ACT   : address_type := VGA_VER_BACK + VGA_VER_PIXEL;
    constant VGA_VER_MAX   : address_type := VGA_VER_ACT  + x"00000A";
    
    constant ONE           : address_type := x"000001";
    
end package vga_param;