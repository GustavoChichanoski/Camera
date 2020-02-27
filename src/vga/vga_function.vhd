library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.vga_param.all;

package vga_function is
    
    function calc_addr
    (
        x : address_type;
        y : address_type
    ) return address_type;
    
end package vga_function;

package body vga_function is
    
    function calc_addr
    (
        x : address_type;
        y : address_type
    ) return address_type is
    begin
        return y*VGA_HOR_PIXEL + x;
    end calc_addr;
end package body vga_function;