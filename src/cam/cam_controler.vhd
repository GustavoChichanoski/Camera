library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity cam_controler is
    port (
        sys_clock : in std_logic
    ) ;
end cam_controler;

architecture arch of cam_controler is
    
    
    
begin
    
    control : process(sys_clk, rst)
    begin
        if rst = '0' then
            
        elsif rising_edge(sys_clk) then
            
        end if;
    end process control;
    
end architecture arch; -- arch