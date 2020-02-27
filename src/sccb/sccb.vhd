library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sccb is
    generic
    (
        fpga_clk : natural := 50_000_000;
        sbbc_clk : natural :=    400_000
    );
    port
    (
        user_reset : in    std_logic;
        user_clk   : in    std_logic;
        user_send  : in    std_logic;
        sccb_write : in    std_logic_vector(7 downto 0);
        sccb_reg   : in    std_logic_vector(7 downto 0);
        sccb_addr  : in    std_logic_vector(7 downto 0);
        sccb_busy  : out   std_logic;
        sccb_find  : out   std_logic;
        sccb_pwdn  : out   std_logic;
        sccb_sioc  : inout std_logic;
        sccb_siod  : inout std_logic
    );
end sccb;

architecture rtl of sccb is
    
    constant divider1         : natural := (fpga_clk/sbbc_clk)/4;
    constant divider2         : natural := 2*divider1;
    constant divider3         : natural := 3*divider1;
    constant divider4         : natural := 4*divider1;
    -- 0    ,     1,       2,   3,   4,     5,     6
    -- ready, start, address, ack, reg, write e stop
    type machine is (ready,start,address,ack,registrador,write,stop);
    signal   state            : machine;
    signal   next_state       : machine;
    signal   reg_state        : machine;
    signal   address_camera   : std_logic_vector(6 downto 0);

    signal   sioc_enable      : std_logic;
    signal   sioc_intern      : std_logic;
    signal   sioc_extend      : std_logic;
    signal   siod_enable      : std_logic;
    signal   siod_intern      : std_logic;
    
    signal   data_clock       : std_logic;
    signal   data_clock_prev  : std_logic;
    signal   counter_divider  : natural range 0 to divider4;
    signal   next_counter     : natural range 0 to divider4;
    signal   bit_counter      : natural range 0 to 7 := 7;
    signal   next_bit_counter : natural range 0 to 7;

    signal   sioc_intern_1    : std_logic;
    signal   sioc_intern_2    : std_logic;
    signal   sioc_intern_3    : std_logic;
    signal   sioc_intern_4    : std_logic;

    signal   find_slave       : std_logic;
    signal   falling_data     : std_logic;
    signal   rising_data      : std_logic;

begin
    
    sccb_pwdn     <= '0';
    
    sioc_intern_1 <= '1' when (counter_divider < divider1) else '0';
    sioc_intern_2 <= '1' when (counter_divider < divider2) else '0';
    sioc_intern_3 <= '1' when (counter_divider < divider3) else '0';
    sioc_intern_4 <= '1' when (counter_divider < divider4) else '0';
    sioc_intern   <= sioc_intern_2;
    
    sccb_sioc     <= 
    'Z' when (sioc_intern = '1') else 
    '0';
    
    -- falling edge (sioc : '1') and rising edge (sioc : '0')
    data_clock   <= 
    '0' when 
    (
        sioc_intern_1 = '0' and 
        sioc_intern_4 = '0'
    ) else 
    '1';

    next_counter <= 
    0               when ((sioc_intern_4 = '1') or (user_reset = '0')) else 
    counter_divider when (sioc_extend    = '1')                         else 
    counter_divider + 1;
    
    sioc_extend  <= 
    '1' when
    (
        data_clock    = '1' and 
        sioc_intern_2 = '0' and 
        sioc_intern_3 = '1' and 
        user_reset    = '1'
    ) else '0';
    
    sccb_clk_generator : process(user_clk,user_reset) begin
        if(user_clk'event and user_clk = '1') then
            counter_divider <= next_counter;
            data_clock_prev <= data_clock;
        end if;
    end process sccb_clk_generator;
    
    sccb_busy <= '0' when state = start else '1';
    
    next_state <= 
    ready     when (user_reset = '0')                                                                      else
    start     when ((state = ready)   and (user_send = '1'))                                               else
    address   when (state = start)                                                                         else
    reg_state when ((sccb_siod = '0') and (state = ack))                                                   else
    ack       when ((bit_counter < 1) and ((state = address) or (state = registrador) or (state = write))) else
    state     when ((bit_counter > 0) and ((state = address) or (state = registrador) or (state = write))) else
    stop;
    
    reg_state <= 
    registrador when state = address     else 
    write       when state = registrador else 
    stop;
    
    sccb_find    <= find_slave;
    find_slave   <= 
    '1' when (state = ack and sccb_siod = '0') else 
    '0' when (state = ready)                   else find_slave;
    
    falling_data <= '1' when (data_clock_prev = '1' and data_clock = '0') else '1';
    rising_data  <= '1' when (data_clock_prev = '0' and data_clock = '1') else '0';
    
    next_bit_counter <= 7   when bit_counter < 1                              else bit_counter - 1;
    
    sccb_siod <= 
    '1' when falling_data = '1' and state = start else
    '0' when 
    (
        (falling_data = '1' and state = stop) or 
        (
            rising_data  = '1' and 
            (
                (state = address     and sccb_addr( bit_counter) = '0')  or 
                (state = registrador and sccb_reg(  bit_counter) = '0')  or 
                (state = write       and sccb_write(bit_counter) = '0')
            )
        )
    ) else 'Z';
    
    communication : process(user_clk)
    begin
        if(user_clk'event and user_clk = '1') then
            state <= next_state;
            -- Falling edge
            -- Rising edge
            if(rising_data = '1') then -- sioc em '0'
                case(state) is
                    when address | registrador | write =>
                        bit_counter <= next_bit_counter;
                    when others => NULL;
                end case;
            end if;
        end if;
    end process communication;
    
end architecture rtl;