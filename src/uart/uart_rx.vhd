library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_rx is
    port 
    (
        i_rx_clk    : in  std_logic;
        i_rx_rst    : in  std_logic;
        i_rx_serial : in  std_logic;
        o_rx_data   : out std_logic_vector(8 downto 0);
        o_rx_dv     : out std_logic
    );
end entity uart_rx;

architecture rtl of uart_rx is
    
    constant c_rx_period_bit  : natural range 0 to 434 := 434;
    constant c_rx_period_half : natural range 0 to 217 := 217;
    
    type     t_machine_state is (RX_IDLE,RX_START,RX_DATA,RX_STOP,RX_CLEAR);
    signal   r_rx_state      : t_machine_state;
    
    signal   r_rx_byte       : std_logic_vector(7 downto 0) := (others => '0'); -- Byte recebido
    signal   r_rx_byte_index : natural range 0 to 8         := 0;               -- Bit atual
    signal   r_rx_byte_count : natural range 0 to 434       := 0;               -- 
    signal   r_rx_dv         : std_logic                    := '0';
    
    signal   r_rx_sample     : std_logic_vector(1 downto 0) := (others => '1');
    signal   r_rx_data_bit   : std_logic := '1';
    
begin
    -- Purpose: Double-register the incoming data.
    -- This allows it to be used in the UART RX Clock Domain.
    -- (It removes problems caused by metastabiliy)
    
    r_rx_data_bit <= r_rx_sample(0) when r_rx_sample(0) = r_rx_sample(1) else r_rx_sample(1);
    
    p_states : process(i_rx_clk,i_rx_rst)
    begin
        
        if(i_rx_rst = '0') then
            
            r_rx_sample    <= "11";
            
        elsif(i_rx_clk'event and i_rx_clk = '1') then
            
            r_rx_sample(0) <= i_rx_serial;
            r_rx_sample(1) <= r_rx_sample(0);
            
        end if;
        
    end process p_states;
    
    p_UART_rx: process(i_rx_clk,i_rx_rst)
    begin
        
        if i_rx_rst = '0' then
            
            r_rx_state <= RX_IDLE;
            
        elsif i_rx_clk'event and i_rx_clk = '1' then
            
            case r_rx_state is
                
                when RX_IDLE  =>
                    
                    r_rx_dv <= '0';
                    r_rx_byte_count <= 0;
                    r_rx_byte_index <= 0;
                    
                    if(r_rx_sample(1) = '0') then
                        
                        r_rx_state <= RX_START;
                        
                    end if;
                    
                when RX_START =>
                    
                    if(r_rx_byte_count = c_rx_period_bit/2 - 1) then
                        
                        if(r_rx_sample(1) = '0') then
                            
                            r_rx_byte_count <= 0;
                            r_rx_state <= RX_DATA;
                            
                        else
                            
                            r_rx_state <= RX_IDLE;
                            
                        end if;
                    else
                        
                        r_rx_byte_count <= r_rx_byte_count + 1;
                        
                    end if;
                    
                when RX_DATA  =>
                    
                    if(r_rx_byte_count < c_rx_period_bit - 1) then
                        
                        r_rx_byte_count <= r_rx_byte_count + 1;
                        
                    else
                        
                        r_rx_byte(r_rx_byte_index) <= r_rx_sample(1);
                        
                        if(r_rx_byte_index < 8) then
                            
                            r_rx_byte_index <= r_rx_byte_index + 1;
                            
                        else
                            
                            r_rx_byte_index <= 0;
                            r_rx_state      <= RX_STOP;
                            
                        end if;
                        
                    end if;
                    
                when RX_STOP  =>
                    
                    if(r_rx_byte_count < c_rx_period_bit - 1) then
                        
                        r_rx_byte_count <= r_rx_byte_count + 1;
                        
                    else
                        
                        r_rx_dv         <= '1';
                        r_rx_byte_count <= 0;
                        r_rx_state      <= RX_CLEAR;
                        
                    end if;
                    
                when RX_CLEAR =>
                    
                    r_rx_dv    <= '0';
                    r_rx_state <= RX_IDLE;
                    
            end case;
            
        end if;
        
    end process p_UART_rx;
    
    o_rx_dv   <= r_rx_dv;
    o_rx_data <= r_rx_byte;
    
end architecture rtl;