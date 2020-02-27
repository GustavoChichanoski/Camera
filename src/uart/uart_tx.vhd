library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_tx is
    port 
    (
        i_tx_clk    : in  std_logic;
        i_tx_dv     : in  std_logic;
        i_tx_data   : in  std_logic_vector(7 downto 0);
        o_tx_serial : out std_logic;
        o_tx_done   : out std_logic;
        o_tx_active : out std_logic
    );
end entity uart_tx;

architecture arch of uart_tx is
    
    constant c_fcpu               : natural := 50_000_000;
    constant c_tx_baund_rate      : natural := 115_200;
    constant c_tx_bit_period      : natural := c_fcpu/c_tx_baund_rate;
    constant c_tx_bit_period_half : natural := c_tx_bit_period/2 - 1;
    
    type t_machine is (TX_IDLE,TX_START,TX_DATA,TX_STOP,TX_CLEAR);
    signal   s_tx_state           : t_machine;
    
    signal   s_tx_clk_counter    : natural range 0 to 434 := 0;
    
    signal   s_tx_byte_index      : natural range 0 to 8;
    signal   s_tx_byte_parity     : std_logic;
    signal   s_tx_byte_send       : std_logic_vector(8 downto 0);
    
    signal   s_parity             : std_logic;
    signal   s_parity_even        : std_logic := '1';
    signal   s_parity_odd         : std_logic := '0';
    
begin
    
    s_tx_byte_send <= i_tx_data & s_parity;
    
    baundrate_generator : process(i_tx_clk)
    begin
        if(i_tx_clk'event and i_tx_clk ='1') then
            
            case s_tx_state is
                
                when TX_IDLE =>
                    
                    s_tx_clk_counter <= 0;
                    s_tx_byte_index  <= 0;
                    
                    if(i_tx_dv = '1') then
                        s_tx_state <= TX_START;
                    end if;
                    
                when TX_START =>
                    
                    o_tx_serial <= '0';
                    
                    if(s_tx_clk_counter < c_tx_bit_period) then
                        
                        s_tx_clk_counter <= s_tx_clk_counter + 1;
                        
                    else
                        
                        s_tx_clk_counter <= 0;
                        s_tx_state       <= TX_DATA;
                        
                    end if;
                    
                when TX_DATA =>
                    
                    o_tx_serial <= s_tx_byte_send(s_tx_byte_index);
                    
                    if(s_tx_clk_counter < c_tx_bit_period) then
                        
                        s_tx_clk_counter <= s_tx_clk_counter + 1;
                        
                    else
                        
                        s_tx_clk_counter <= 0;
                        
                        if(s_tx_byte_index < 8) then
                            
                            s_tx_byte_index <= s_tx_byte_index + 1;
                            
                        else
                            
                            s_tx_byte_index <= 0;
                            s_tx_state      <= TX_STOP;
                            
                        end if;
                        
                    end if;
                when TX_STOP =>
                    
                    o_tx_serial <= '0';
                    
                    if(s_tx_clk_counter < c_tx_bit_period) then
                        
                        s_tx_clk_counter <= s_tx_clk_counter + 1;
                        
                    else
                        
                        s_tx_clk_counter <= 0;
                        s_tx_state       <= TX_CLEAR;
                        
                    end if;
                    
                when TX_CLEAR =>
                    
                    s_tx_state       <= TX_IDLE;
                    s_tx_byte_index  <= 0;
                    s_tx_clk_counter <= 0;
                    o_tx_done        <= '1';
                    
            end case;
            
        end if;
    end process baundrate_generator;
    
    s_tx_byte_parity <= 
    (
        (( i_tx_data(0) xor i_tx_data(1) ) xor ( i_tx_data(2) xor i_tx_data(3) ))
        xor 
        (( i_tx_data(4) xor i_tx_data(5) ) xor ( i_tx_data(6) xor i_tx_data(7) ))
    );
    
    o_tx_active <= '0' when s_tx_state = TX_IDLE else '1';
    
end arch ; -- arch