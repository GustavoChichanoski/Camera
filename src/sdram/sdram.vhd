library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     work.sys_package.all;
use     work.sdram_parameters.all;
use     work.sdram_functions.all;

-- VGA pode apresentar no máximo 6 imagens ao mesmo tempo
entity sdram is
    port
    (
        -- User interface
        sys_clk     : in    std_logic;
        sdr_addr    : in    address_type;
        sdr_write   : in    std_logic_vector(127 downto 0);
        sdr_read    : out   std_logic_vector(127 downto 0);
        sdr_rw      : in    std_logic_vector(  1 downto 0); -- Posição 0 : Read - Posicao 1 : Write
        sdr_done    : out   std_logic;
        sdr_busy    : out   std_logic;
        -- SDRAM interface
        DRAM_DQ     : inout byte;                           -- Data I/O
        DRAM_ADDR   : out   std_logic_vector(12 downto 0);  -- A0 - A12 Row Address Input : A0 - A9 Column Address Input
        DRAM_BA     : out   std_logic_vector( 1 downto 0);  -- Bank Select Address Input
        DRAM_CLK    : out   std_logic;                      -- System Clock Input
        DRAM_CKE    : out   std_logic;                      -- Clock Enable
        DRAM_LDQM   : out   std_logic;                      -- x16 Lower Byte, Input/Output Mask
        DRAM_UDQM   : out   std_logic;                      -- x16 Upper Byte, Input/Output Mask
        DRAM_WE_N   : out   std_logic;                      -- Write Enable (Habilita a escrita)
        DRAM_CAS_N  : out   std_logic;                      -- Column Address Strobe Command (Comando de Armazenar o endereço como coluna)
        DRAM_RAS_N  : out   std_logic;                      -- Row Address Strobe Command (Comando de Armazenar o endereço como linha) 
        DRAM_CS_N   : out   std_logic                       -- Chip Select
    );
end entity sdram;

architecture rtl of sdram is
    
    signal sdr_funct  : sdram_function                        := NOP;
    signal state_s    : sdram_sm                              := POWER_ON;
    signal state_r    : sdram_sm                              := IDLE;
    signal state_prev : sdram_sm                              := IDLE;
    
    signal counter_s  : timer                                 := cSETUP;
    signal counter_r  : timer                                 := cSETUP;
    signal first      : std_logic                             := '0';
    signal position   : natural range 0 to (BURST_LENGTH-1)   := BURST_LENGTH - 1;
    
    signal data_read  : data((BURST_LENGTH - 1) downto 0);
    signal data_write : data((BURST_LENGTH - 1) downto 0);
    
    signal r_col      : unsigned( 9 downto 0);
    signal r_row      : unsigned(12 downto 0);
    signal bank_r     : unsigned( 1 downto 0);
    signal busy_r     : std_logic;
    signal r_length   : natural range (BURST_LENGTH - 1) to 0 := 0;
    
    signal flag_auto  : std_logic := '0';
    signal MRD_SET    : std_logic := '0';
    
    signal sdr_addr_r : std_logic_vector(14 downto 0);
    
begin
    
    counter_r <=  0  when counter_s < 1                                                else counter_s - 1;
    first     <= '1' when state_s = state_prev                                         else '0';
    sdr_done  <= '1' when state_s = IDLE and (state_prev = READ or state_prev = WRITE) else '0';
    sdr_busy  <= '0' when state_s /= IDLE                                              else '1';
    
    sdr_read  <= 
    data_read(0) & data_read(1) & data_read(2) & data_read(3) & 
    data_read(4) & data_read(5) & data_read(6) & data_read(7);
    
    data_complete : for i in (BURST_LENGTH-1) downto 0 generate
        data_write(i) <= sdr_write((BURST_LENGTH - 1)*(i+1) downto BURST_LENGTH*i);
    end generate data_complete;
    
    data_read(position) <= DRAM_DQ  when state_s = READ  and counter_s < 1 else data_read(position);
    DRAM_DQ <= data_write(position) when state_s = WRITE and counter_s < 1 else (others => 'Z');
        
    state_machine: process(sys_clk)
    begin
        if(sys_clk'event and sys_clk = '0') then
            state_prev <= state_s;
            case state_s is
                when POWER_ON  =>
                    sdr_funct <= sdram_function_next(first,counter_s,state_s);
                    if(first = '0') then
                        counter_s <= sdram_timer(state_s);
                    else
                        counter_s <= counter_r;
                    end if;
                when PRECHARGE =>
                    sdr_funct <= sdram_function_next(first,counter_s,state_s);
                    if(first = '1') then
                        counter_s <= counter_r;
                    else
                        counter_s <= sdram_timer(state_s);
                    end if;
                when READ      =>
                    sdr_funct <= sdram_function_next(first,counter_s,state_s);
                    if(first = '1') then
                        counter_s <= counter_r;
                        if(counter_s = 0) then
                            data_read(position) <= DRAM_DQ;
                            if(position > 0) then
                                position <= position - 1;
                            else
                                state_s <= IDLE;
                            end if;
                        end if;
                    else
                        position   <= BURST_LENGTH - 1;
                        counter_s <= sdram_timer(state_s);
                    end if;
                when WRITE     =>
                    sdr_funct <= sdram_function_next(first,counter_s,state_s);
                    if(first = '1') then
                        counter_s <= counter_r;
                        if(counter_s = 0) then
                            DRAM_DQ <= data_write(position);
                            if(position = 0) then
                                state_s  <= IDLE;
                            else
                                position <= position - 1;
                            end if;
                        end if;
                    else
                        position <= BURST_LENGTH - 1;
                        counter_s <= sdram_timer(state_s);
                    end if;
                when IDLE      =>
                    sdr_funct <= NOP;
                    if(first = '1') then
                        counter_s <= counter_r;
                        if(sdr_rw(0) = '1') then
                            state_s <= READ;
                        elsif(sdr_rw(1) = '1') then
                            state_s <= WRITE;
                        end if;
                    else
                        counter_s <= sdram_timer(state_s);
                    end if;
                when REFRESH   =>
                    sdr_funct <= sdram_function_next(first,counter_s,state_s);
                    if(first = '1') then
                        counter_s <= counter_r;
                        if(counter_s = 0) then
                            state_s <= IDLE;
                        end if;
                    else
                        counter_s <= sdram_timer(state_s);
                    end if;
            end case;
        end if;
    end process state_machine;
    
    (DRAM_CS_N,DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N) <= sdram_opcode(sdr_funct);
    
    DRAM_CKE   <= '1';
    
    sdr_addr_r <= sdram_address(sdr_funct,sdr_addr);
    DRAM_BA    <= sdr_addr_r(14 downto 13);
    DRAM_ADDR  <= sdr_addr_r(12 downto  0);
    
    sdr_read   <= 
    data_read(7) & data_read(6) & data_read(5) & data_read(4) &
    data_read(3) & data_read(2) & data_read(1) & data_read(0);
    
    DRAM_CLK   <= sys_clk;
    
end architecture rtl;