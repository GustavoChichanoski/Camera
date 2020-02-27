library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ent is
    port 
    (
        data_in  : in  std_logic_vector(3 downto 0);
        data_out : out std_logic_vector(6 downto 0)
    );
end ent ;

architecture arch of ent is



begin
    
    data_out <= 
    "1111110" when data_in = "0000" else -- 0
    "0110000" when data_in = "0001" else -- 1
    "1101101" when data_in = "0010" else -- 2
    "1111001" when data_in = "0011" else -- 3
    "0110011" when data_in = "0100" else -- 4
    "1011011" when data_in = "0101" else -- 5
    "1011111" when data_in = "0110" else -- 6
    "1110000" when data_in = "0111" else -- 7
    "1111111" when data_in = "1000" else -- 8
    "1111011" when data_in = "1001" else -- 9
    "1110111" when data_in = "1010" else -- A
    "0011111" when data_in = "1011" else -- B
    "1001110" when data_in = "1100" else -- C
    "0111101" when data_in = "1101" else -- D
    "1001111" when data_in = "1110" else -- E
    "1110001";
    
    
end architecture ; -- arch