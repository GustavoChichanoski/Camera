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
        pll_locked : in    std_logic;
        sys_clk    : in    std_logic;                      -- Clock input
        sdr_rw     : in    std_logic_vector(  1 downto 0); -- Posição 0 : Read - Posicao 1 : Write
        sdr_addr   : in    std_logic_vector( 24 downto 0); -- Endereço a ser escrito
        sdr_write  : in    std_logic_vector(127 downto 0); -- Dado a ser escrito
        sdr_read   : out   std_logic_vector(127 downto 0); -- Dado lido
        sdr_done   : out   std_logic;                      -- SDRAM terminou de ler ou escrever
        sdr_busy   : out   std_logic;                      -- SDRAM está ocupada
        sdr_first  : out   std_logic;
        sdr_state  : out   std_logic_vector(  2 downto 0);
        sdr_cnt    : out   timer;
        opcode     : out   std_logic_vector(3 downto 0);
        -- SDRAM interface
        DRAM_DQ    : inout byte;                           -- Data I/O
        DRAM_ADDR  : out   std_logic_vector( 12 downto 0); -- A0 - A12 Row Address Input : A0 - A9 Column Address Input
        DRAM_BA    : out   std_logic_vector(  1 downto 0); -- Bank Select Address Input
        DRAM_CLK   : out   std_logic;                      -- System Clock Input
        DRAM_CKE   : out   std_logic;                      -- Clock Enable
        DRAM_QM    : out   std_logic_vector(  1 downto 0) -- xTAM_DATA Lower Byte, Input/Output Mask
        -- DRAM_WE_N  : out   std_logic;                      -- Write Enable (Habilita a escrita)
        -- DRAM_CAS_N : out   std_logic;                      -- Column Address Strobe Command (Comando de Armazenar o endereço como coluna)
        -- DRAM_RAS_N : out   std_logic;                      -- Row Address Strobe Command (Comando de Armazenar o endereço como linha) 
        -- DRAM_CS_N  : out   std_logic                       -- Chip Select
    );
end entity sdram;

architecture rtl of sdram is
    
    signal cmd        : sdram_function                      := CMD_NOP;
    signal state_s    : sdram_sm                            := SM_POWER_ON;
    -- signal opcode     : std_logic_vector(3 downto 0);
    
    signal counter_s  : timer                               := 0;
    signal counter_r  : timer                               := 0;
    signal first      : std_logic                           := '0';
    signal position   : natural range 0 to (BURST_LENGTH-1) := 0;
    
    signal sdr_addr_r : std_logic_vector(14 downto 0);
    signal read_flag  : std_logic_vector(127 downto 0);
    signal flag_power : std_logic;
     
begin
    
    sdr_cnt <= counter_s;
    with state_s select
        sdr_state <= 
            "000" when SM_IDLE,
            "001" when SM_POWER_ON,
            "010" when SM_PRECHARGE,
            "011" when SM_WRITE,
            "100" when SM_READ,
            "101" when others;
    
    counter_r  <=  sdram_timer(state_s) when first = '0' else 0  when counter_s < 1 and first = '1' else counter_s - 1;
    sdr_done   <= '1' when (state_s = SM_READ or state_s = SM_WRITE) and position < 1 else '0';
    sdr_busy   <= '1' when state_s = SM_IDLE  else '0';
    sdr_first  <= first;
    sdr_addr_r <= sdram_address(cmd,sdr_addr);
    sdr_read   <= read_flag;
    
    state_r <= 
    SM_POWER_ON  when first = '0'            and state_s = SM_POWER_ON  else
    SM_IDLE      when first = '0'            and state_s = SM_IDLE      else
    SM_PRECHARGE when first = '0'            and state_s = SM_PRECHARGE else
    SM_READ      when first = '0'            and state_s = SM_READ      else
    SM_WRITE     when first = '0'            and state_s = SM_WRITE     else
    SM_POWER_ON  when state_s = SM_POWER_ON  and counter_s > 0          else
    SM_READ      when state_s = READ         and counter_s > 0          else
    SM_WRITE     when state_s = WRITE        and counter_s > 0          else
    SM_READ      when state_s = READ         and position  > 0          else
    SM_WRITE     when state_s = WRITE        and position  > 0          else
    SM_READ      when state_s = SM_IDLE      and sdr_rw(0) = '1'        else
    SM_WRITE     when state_s = SM_IDLE      and sdr_rw(1) = '1'        else
    SM_IDLE      when state_s = SM_IDLE      and counter_s > 0          else
    SM_PRECHARGE when state_s = SM_PRECHARGE and counter_s > 0          else
    SM_PRECHARGE when state   = SM_IDLE                                 else
    SM_IDLE;
    
    state_machine : process(sys_clk)
    begin
        if(sys_clk'event and sys_clk = '1') then
            if(first = '0') then
                counter_s <= sdram_timer(state_s);
            else
                counter_s <= counter_r;
            end if;
            case state_s is
                when SM_POWER_ON  =>
                    if(pll_locked = '1') then
                        if(first = '1') then
                            cmd <= sdram_cmd(first,counter_s,state_s);
                            if(counter_s < 1) then
                                first   <= '0';
                                state_s <= SM_IDLE;
                            else
                                state_s <= SM_POWER_ON;
                            end if;
                        else
                            first   <= '1';
                            state_s <= SM_POWER_ON;
                        end if;
                    else
                        first   <= '0';
                        state_s <= SM_POWER_ON;
                    end if;
                when SM_PRECHARGE =>
                    cmd <= sdram_cmd(first,counter_s,state_s);
                    if(first = '1') then
                        if(counter_s < 1) then
                            first   <= '0';
                        end if;
                    else
                        first   <= '1';
                    end if;
                when SM_READ      =>
                    cmd <= sdram_cmd(first,counter_s,state_s);
                    if(first = '1') then
                        if(counter_s < 1) then
                            read_flag(16*(position + 1) - 1 downto position*16) <= DRAM_DQ;
                            if(position < 1) then
                                first    <= '0';
                                position <= BURST_LENGTH - 1;
                            else
                                position <= position - 1;
                            end if;
                        end if;
                    else
                        position  <= BURST_LENGTH - 1;
                        first     <= '1';
                    end if;
                when SM_WRITE     =>
                    if(first = '1') then
                        if(counter_s < 1) then
                            if(position < 1) then
                                first    <= '0';
                                state_s  <= SM_IDLE;
                                position <= BURST_LENGTH - 1;
                            elsif(position  = 7) then
                                position <= position - 1;
                                cmd      <= CMD_WRITEA;
                            else
                                state_s  <= SM_WRITE;
                                cmd      <= CMD_NOP;
                                position <= position - 1;
                            end if;
                        else
                            state_s  <= SM_WRITE;
                            cmd      <= CMD_NOP;
                        end if;
                    else
                        position <= BURST_LENGTH - 1;
                        state_s  <= SM_WRITE;
                        cmd      <= CMD_ACT;
                        first    <= '1';
                    end if;
                when SM_IDLE      =>
                    cmd        <= sdram_cmd(first,counter_s,state_s);
                    if(first = '1') then
                        if   (sdr_rw(0) = '1') then
                            state_s <= SM_READ;
                            first   <= '0';
                        elsif(sdr_rw(1) = '1') then
                            state_s <= SM_WRITE;
                            first   <= '0';
                        elsif(counter_s < 1) then
                            state_s <= SM_PRECHARGE;
                            first   <= '0';
                        else
                            state_s    <= SM_IDLE;
                        end if;
                    else
                        first <= '1';
                    end if;
            end case;
        end if;
    end process state_machine;
    
    -- Outputs blocks
    -- DRAM_CS_N  <= opcode(3); -- Chip Select
    -- DRAM_RAS_N <= opcode(2); -- Row Address Select
    -- DRAM_CAS_N <= opcode(1); -- Column Adress Select
    -- DRAM_WE_N  <= opcode(0); -- Write enable
    opcode     <= sdram_opcode(cmd);
    DRAM_CLK   <= sys_clk;
    DRAM_CKE   <= '1'  when state_s /= SM_IDLE or cmd = CMD_SELF else '0';  -- Clk suspend
    DRAM_QM    <= "11" when state_s = SM_POWER_ON                else "00";
    DRAM_BA    <= sdr_addr_r(14 downto 13);
    DRAM_ADDR  <= sdr_addr_r(12 downto  0);
    DRAM_DQ    <= sdr_write((TAM_DATA*(position + 1) - 1) downto TAM_DATA*position) when state_s = SM_WRITE and counter_s < 1 else (others => 'Z');
    
end architecture rtl;