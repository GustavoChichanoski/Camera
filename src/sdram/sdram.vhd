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
        DRAM_QM     : out   std_logic_vector(1 downto 0);   -- x16 Lower Byte, Input/Output Mask
        DRAM_WE_N   : out   std_logic;                      -- Write Enable (Habilita a escrita)
        DRAM_CAS_N  : out   std_logic;                      -- Column Address Strobe Command (Comando de Armazenar o endereço como coluna)
        DRAM_RAS_N  : out   std_logic;                      -- Row Address Strobe Command (Comando de Armazenar o endereço como linha) 
        DRAM_CS_N   : out   std_logic                       -- Chip Select
    );
end entity sdram;

architecture rtl of sdram is
    
    signal funct_sdr   : sdram_function                      := CMD_NOP;
    signal state_s     : sdram_sm                            := SM_POWER_ON;
    signal state_r     : sdram_sm                            := SM_IDLE;
    signal state_prev  : sdram_sm                            := SM_IDLE;
    
    signal counter_s   : timer                               := cSETUP;
    signal counter_r   : timer                               := cSETUP;
    signal first       : std_logic                           := '0';
    signal position    : natural range 0 to (BURST_LENGTH-1) := BURST_LENGTH - 1;
    signal position_nx : natural range 0 to (BURST_LENGTH-1) := BURST_LENGTH - 1;
    
    signal data_read   : data;
    signal data_write  : data;
    
    signal sdr_addr_r  : std_logic_vector(14 downto 0);
    
begin
    
    counter_r <=  0  when counter_s < 1 else counter_s - 1;
    first     <= '1' when state_s = state_prev else '0';
    sdr_done  <= '1' when state_s = SM_IDLE and (state_prev = SM_READ or state_prev = SM_WRITE) else '0';
    sdr_busy  <= '0' when state_s /= SM_IDLE else '1';
    
    data_complete : for i in (BURST_LENGTH-1) downto 0 generate
        data_write(i) <= sdr_write((16*(i+1)-1) downto 16*i);
    end generate data_complete;
    
    state_machine : process(sys_clk)
    begin
        if(sys_clk'event and sys_clk = '0') then
            state_prev <= state_s;
            if(first = '0') then
                counter_s <= sdram_timer(state_s);
            else
                counter_s <= counter_r;
            end if;
            case state_s is
                when SM_POWER_ON =>
                    funct_sdr <= sdram_function_next(first,counter_s,state_s);
                    if(counter_s < 1) then
                        state_s <= SM_IDLE;
                    end if;
                when SM_PRECHARGE =>
                    funct_sdr <= sdram_function_next(first,counter_s,state_s);
                    if(first = '1' and counter_s < 1) then
                        state_s <= SM_IDLE;
                    end if;
                when SM_READ =>
                    funct_sdr <= sdram_function_next(first,counter_s,state_s);
                    if(first = '1') then
                        if(counter_s = 0) then
                            if(position > 0) then
                                position <= position - 1;
                            else
                                state_s <= SM_IDLE;
                            end if;
                        end if;
                    else
                        position  <= BURST_LENGTH - 1;
                    end if;
                when SM_WRITE =>
                    funct_sdr <= sdram_function_next(first,counter_s,state_s);
                    if(first = '1') then
                        if(counter_s = 0) then
                            if(position = 0) then
                                state_s  <= SM_IDLE;
                            else
                                position <= position - 1;
                            end if;
                        end if;
                    else
                        position  <= BURST_LENGTH - 1;
                    end if;
                when SM_IDLE =>
                    funct_sdr <= sdram_function_next(first,counter_s,state_s);
                    if(first = '1' and counter_s > 0) then
                        if(sdr_rw(0) = '1') then
                            state_s <= SM_READ;
                        elsif(sdr_rw(1) = '1') then
                            state_s <= SM_WRITE;
                        end if;
                    elsif(counter_s = 0) then
                        state_s <= SM_PRECHARGE;
                    end if;
            end case;   
        end if;
    end process state_machine;
    
    data_read(position) <= DRAM_DQ when state_s = SM_READ and counter_s < 1 else data_read(position);
    sdr_addr_r <= sdram_address(funct_sdr,sdr_addr);
    sdr_read   <= 
    data_read(7) & data_read(6) & data_read(5) & data_read(4) &
    data_read(3) & data_read(2) & data_read(1) & data_read(0);
    
    -- Outputs blocks
    (
        DRAM_CS_N , -- Chip Select
        DRAM_RAS_N, -- Row Address Select
        DRAM_CAS_N, -- Column Adress Select
        DRAM_WE_N   -- Write enable
    ) <= sdram_opcode(funct_sdr);
    DRAM_CKE   <= '1'; -- Clk suspend
    DRAM_DQ    <= data_write(position) when state_s = SM_WRITE and counter_s < 1 else (others => 'Z');
    DRAM_QM    <= "11" when state_s = SM_POWER_ON else "00";
    DRAM_BA    <= sdr_addr_r(14 downto 13);
    DRAM_ADDR  <= sdr_addr_r(12 downto  0);
    DRAM_CLK   <= sys_clk;
    
end architecture rtl;