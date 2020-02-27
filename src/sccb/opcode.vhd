library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity opcode is
  port (
    user_reset  : in  std_logic;
    user_clk    : in  std_logic;
    registrador : out std_logic_vector(7 downto 0);
    write       : out std_logic_vector(7 downto 0);
    done        : out std_logic
  );
end opcode;

architecture rtl of opcode is
    
    signal reg_rgt         : std_logic_vector(7 downto 0) := "00010010";
    signal nxt_registrador : std_logic_vector(7 downto 0) := "00010010";
    signal reg_write       : std_logic_vector(7 downto 0) := "10000000";
    signal nxt_write       : std_logic_vector(7 downto 0) := "10000000";
    signal counter         : natural range 0 to 72        := 72;
    
begin

    registrador <= reg_rgt;
    write <= reg_write;

    setup : process(user_clk)
    begin
        if(user_reset = '0') then
            counter <= 72;
        elsif(user_clk'event and user_clk = '1') then
            reg_rgt     <= nxt_registrador;
            reg_write   <= nxt_write;
            counter     <= counter - 1;
            if(counter > 1) then
                done <= '0';
            else
                done <= '1';
            end if;
        end if;
    end process setup;
    
    nxt_registrador <=
    "11111111" when reg_rgt = "00010010" else
    "00010001" when reg_rgt = "11111111" else
    "00001100" when reg_rgt = "00010001" else
    "00111110" when reg_rgt = "00001100" else
    "00000100" when reg_rgt = "00111110" else
    "01000000" when reg_rgt = "00000100" else
    "00111010" when reg_rgt = "01000000" else
    "00010100" when reg_rgt = "00111010" else
    "01001111" when reg_rgt = "00010100" else
    "01010000" when reg_rgt = "01001111" else
    "01010001" when reg_rgt = "01010000" else
    "01010010" when reg_rgt = "01010001" else
    "01010011" when reg_rgt = "01010010" else
    "01010100" when reg_rgt = "01010011" else
    "01011000" when reg_rgt = "01010100" else
    "00111101" when reg_rgt = "01011000" else
    "00010111" when reg_rgt = "00111101" else
    "00011000" when reg_rgt = "00010111" else
    "00110010" when reg_rgt = "00011000" else
    "00011001" when reg_rgt = "00110010" else
    "00011010" when reg_rgt = "00011001" else
    "00000011" when reg_rgt = "00011010" else
    "00001111" when reg_rgt = "00000011" else
    "00011110" when reg_rgt = "00001111" else
    "00110011" when reg_rgt = "00011110" else
    "00111100" when reg_rgt = "00110011" else
    "01101001" when reg_rgt = "00111100" else
    "01110100" when reg_rgt = "01101001" else
    "10110000" when reg_rgt = "01110100" else
    "10110001" when reg_rgt = "10110000" else
    "10110010" when reg_rgt = "10110001" else
    "10110011" when reg_rgt = "10110010" else
    "01110000" when reg_rgt = "10110011" else
    "01110001" when reg_rgt = "01110000" else
    "01110010" when reg_rgt = "01110001" else
    "01110011" when reg_rgt = "01110010" else
    "10100010" when reg_rgt = "01110011" else
    "01111010" when reg_rgt = "10100010" else
    "01111011" when reg_rgt = "01111010" else
    "01111100" when reg_rgt = "01111011" else
    "01111101" when reg_rgt = "01111100" else
    "01111110" when reg_rgt = "01111101" else
    "01111111" when reg_rgt = "01111110" else
    "10000000" when reg_rgt = "01111111" else
    "10000001" when reg_rgt = "10000000" else
    "10000010" when reg_rgt = "10000001" else
    "10000011" when reg_rgt = "10000010" else
    "10000100" when reg_rgt = "10000011" else
    "10000101" when reg_rgt = "10000100" else
    "10000110" when reg_rgt = "10000101" else
    "10000111" when reg_rgt = "10000110" else
    "10001000" when reg_rgt = "10000111" else
    "10001001" when reg_rgt = "10001000" else
    "00010011" when reg_rgt = "10001001" else
    "00000000" when reg_rgt = "00010011" else
    "00010000" when reg_rgt = "00000000" else
    "00001101" when reg_rgt = "00010000" else
    "00010100" when reg_rgt = "00001101" else
    "10100101" when reg_rgt = "00010100" else
    "10101011" when reg_rgt = "10100101" else
    "00100100" when reg_rgt = "10101011" else
    "00100101" when reg_rgt = "00100100" else
    "00100110" when reg_rgt = "00100101" else
    "10011111" when reg_rgt = "00100110" else
    "10100000" when reg_rgt = "10011111" else
    "10100001" when reg_rgt = "10100000" else
    "10100110" when reg_rgt = "10100001" else
    "10100111" when reg_rgt = "10100110" else
    "10101000" when reg_rgt = "10100111" else
    "10101001" when reg_rgt = "10101000" else
    "10101010" when reg_rgt = "10101001" else
    "00010011";

    nxt_write <=
    "10000000" when 
    (
        reg_rgt = "00010010" or reg_rgt = "00010001" or reg_rgt = "00110010" or reg_rgt = "10110011"
    ) else
    "11110000" when reg_rgt = "11111111" or reg_rgt = "01110011" or reg_rgt = "10101000" else
    "00000100" when reg_rgt = "00111010" else
    "00000000" when
    (
        reg_rgt = "00001100" or reg_rgt = "00111110" or reg_rgt = "00000100" or reg_rgt = "01010001" or 
        reg_rgt = "00011110" or reg_rgt = "01101001" or reg_rgt = "01110100" or reg_rgt = "10000001" or
        reg_rgt = "00000000" or reg_rgt = "00010000"
    ) else
    "11010000" when reg_rgt = "01000000" else -- COM15
    "00011000" when reg_rgt = "00010100" else
    "10110011" when reg_rgt = "01001111" or reg_rgt = "01010000" else
    "00111101" when reg_rgt = "01010010" else
    "10100111" when reg_rgt = "01010011" else
    "11100100" when reg_rgt = "01010100" else
    "10011110" when reg_rgt = "01011000" else
    "11000000" when reg_rgt = "00111101" else
    "00010100" when reg_rgt = "00010111" else
    "00000010" when reg_rgt = "00011000" else
    "00000011" when reg_rgt = "00011001" else
    "01111011" when reg_rgt = "00011010" else
    "00001010" when reg_rgt = "00000011" else
    "01000001" when reg_rgt = "00001111" else
    "00001011" when reg_rgt = "00110011" else
    "01111000" when reg_rgt = "00111100" else
    "10000100" when reg_rgt = "10110000" else
    "00001100" when reg_rgt = "10110001" else
    "00001110" when reg_rgt = "10110010" else
    "00111010" when reg_rgt = "01110000" else
    "00110101" when reg_rgt = "01110001" else
    "00010001" when reg_rgt = "01110010" else
    "00000010" when reg_rgt = "10100010" else
    "00100000" when reg_rgt = "01111010" else
    "00010000" when reg_rgt = "01111011" else
    "00011110" when reg_rgt = "01111100" else
    "00110101" when reg_rgt = "01111101" else
    "01011010" when reg_rgt = "01111110" else
    "01101001" when reg_rgt = "01111111" else
    "01110110" when reg_rgt = "10000000" else
    "10001000" when reg_rgt = "10000010" else
    "10001111" when reg_rgt = "10000011" else
    "10010110" when reg_rgt = "10000100" else
    "10100011" when reg_rgt = "10000101" else
    "10101111" when reg_rgt = "10000110" else
    "11000100" when reg_rgt = "10000111" else
    "11010111" when reg_rgt = "10001000" else
    "11101000" when reg_rgt = "10001001" else
    "11100000" when reg_rgt = "00010011" else
    "01000000" when reg_rgt = "00001101" else
    "00000101" when reg_rgt = "10100101" else
    "00000111" when reg_rgt = "10101011" else
    "10010101" when reg_rgt = "00100100" else
    "00110011" when reg_rgt = "00100101" else
    "11100011" when reg_rgt = "00100110" else
    "01111000" when reg_rgt = "10011111" else
    "01101000" when reg_rgt = "10100000" else
    "00000011" when reg_rgt = "10100001" else
    "11011000" when reg_rgt = "10100110" else
    "11011000" when reg_rgt = "10100111" else
    "10010000" when reg_rgt = "10101001" else
    "10010100" when reg_rgt = "10101010" else
    "11100101" when reg_rgt = "00010011" else
    "11100101";
    
end architecture rtl;