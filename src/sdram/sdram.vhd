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
        -- SDRAM interface
        DRAM_DQ    : inout byte;                           -- Data I/O
        DRAM_ADDR  : out   std_logic_vector( 12 downto 0); -- A0 - A12 Row Address Input : A0 - A9 Column Address Input
        DRAM_BA    : out   std_logic_vector(  1 downto 0); -- Bank Select Address Input
        DRAM_CLK   : out   std_logic;                      -- System Clock Input
        DRAM_CKE   : out   std_logic;                      -- Clock Enable
        DRAM_QM    : out   std_logic_vector(  1 downto 0); -- xTAM_DATA Lower Byte, Input/Output Mask
        sdr_cnt    : out   timer;
        power_s    : out   std_logic;                      -- Clock Enable
        position_s : out   std_logic_vector(  2 downto 0);
        opcode     : out   std_logic_vector(  3 downto 0)
        -- DRAM_WE_N  : out   std_logic;                      -- Write Enable (Habilita a escrita)
        -- DRAM_CAS_N : out   std_logic;                      -- Column Address Strobe Command (Comando de Armazenar o endereço como coluna)
        -- DRAM_RAS_N : out   std_logic;                      -- Row Address Strobe Command (Comando de Armazenar o endereço como linha) 
        -- DRAM_CS_N  : out   std_logic                       -- Chip Select
    );
end entity sdram;

architecture rtl of sdram is
    
    signal cmd        : std_logic_vector(3 downto 0)        := CMD_NOP;
    signal state_s    : std_logic_vector(2 downto 0)        := SM_power;
    signal state_r    : std_logic_vector(2 downto 0)        := SM_power;
    signal state_m    : std_logic_vector(2 downto 0)        := SM_power;
    -- signal opcode     : std_logic_vector(3 downto 0);
    
    signal counter_s  : timer                               := 0;
    signal counter_r  : timer                               := 0;
    signal first_s    : std_logic                           := '0';
    signal first_r    : std_logic                           := '0';
    signal position   : natural range 0 to 7                := 0;
    signal position_w : natural range 0 to 15               := 0;
    signal position_r : natural range 0 to 15               := 0;
    
    signal sdr_addr_r : std_logic_vector(14 downto 0);
    signal read_flag  : std_logic_vector(127 downto 0);
    signal flag_power : std_logic;
    signal clock      : std_logic;
    signal clk        : std_logic;
    alias  column     : unsigned(2 downto 0) is unsigned(sdr_addr(2 downto 0));
    
    signal refresh    : natural range 0 to 1023 := 1023;
    signal refresh_r  : natural range 0 to 1023 := 1023;
    signal cnt0       : std_logic;
    signal power      : std_logic := '1';
begin
    
    position   <= to_integer(column) + (BURST_LENGTH) - counter_s;
    position_s <= std_logic_vector(to_unsigned(position,position_s'length));
    power_s    <= power;
    sdr_cnt    <= counter_s;
    
    clock     <= sys_clk and pll_locked;
    sdr_state <= state_s;
    -- "000" when SM_PRE    , -- 0
    -- "001" when SM_POWER  , -- 1
    -- "010" when SM_RMS    , -- 2
    -- "011" when SM_WRITE  , -- 3 
    -- "100" when SM_WRITEA , -- 4
    -- "101" when SM_READ   , -- 5 
    -- "110" when SM_READA  , -- 6
    -- "111" when SM_IDLE   ; -- 7
    
    refresh_r  <= -- Count to auto refresh banks
    1023 when cmd = CMD_PALL else
    0    when refresh < 1    else
    refresh - 1;
    cnt0       <= '1'    when counter_s < 1 else '0';          -- Flag if counter < 1
    counter_r  <=                                       -- Next counter
    sdram_timer(state_s) when first_s = '0' else
    0                    when cnt0 = '1'    else
    counter_s - 1;
    power      <= '1' when state_s = SM_POWER else '0' when state_s = SM_RMS else power;
    
    sdr_done   <= '1' when (state_s = SM_READA or state_s = SM_WRITE) and cnt0 = '1' else '0';
    sdr_busy   <= '1' when state_s /= SM_IDLE else '0';
    sdr_first  <= first_s;
    sdr_addr_r <= sdram_address(cmd,sdr_addr);
    sdr_read   <= read_flag;
    
    read_flag( 15 downto   0) <= DRAM_DQ when position = 0 and state_s = SM_READA else read_flag( 15 downto   0);
    read_flag( 31 downto  16) <= DRAM_DQ when position = 1 and state_s = SM_READA else read_flag( 31 downto  16);
    read_flag( 47 downto  32) <= DRAM_DQ when position = 2 and state_s = SM_READA else read_flag( 47 downto  32);
    read_flag( 63 downto  48) <= DRAM_DQ when position = 3 and state_s = SM_READA else read_flag( 63 downto  48);
    read_flag( 79 downto  64) <= DRAM_DQ when position = 4 and state_s = SM_READA else read_flag( 79 downto  64);
    read_flag( 95 downto  80) <= DRAM_DQ when position = 5 and state_s = SM_READA else read_flag( 95 downto  80);
    read_flag(111 downto  96) <= DRAM_DQ when position = 6 and state_s = SM_READA else read_flag(111 downto  96);
    read_flag(127 downto 112) <= DRAM_DQ when position = 7 and state_s = SM_READA else read_flag(127 downto 112);
    
    state_machine : process(clock)
    begin
        if(clock'event and clock = '1') then
            first_s    <= first_r;
            refresh    <= refresh_r;
            counter_s  <= counter_r;
            state_s    <= state_r;
            position_w <= position_r;
        end if;
        case state_s is
            when SM_POWER  => -- 1
                if(first_s = '1') then
                    if(cnt0 = '1') then
                        cmd     <= CMD_PALL;
                        state_r <= SM_PRE;
                        first_r <= '0';
                    else
                        first_r <= '1';
                        cmd     <= CMD_NOP;
                        state_r <= SM_POWER;
                    end if;
                else
                    first_r <= '1';
                    cmd     <= CMD_NOP;
                    state_r <= SM_POWER;
                end if;
            when SM_PRE   =>  -- 0
                if(first_s = '1') then
                    if(cnt0 = '1') then
                        first_r     <= '0';
                        cmd         <= CMD_NOP;
                        if(power = '1') then
                            state_r <= SM_RMS;
                        else
                            state_r <= SM_IDLE;
                        end if;
                    else
                        first_r     <= '1';
                        state_r <= SM_PRE;
                        if(counter_s = cRC or counter_s = 2*cRC) then
                            cmd     <= CMD_SELF;
                        else
                            cmd     <= CMD_NOP;
                        end if;
                    end if;
                else
                    first_r <= '1';
                    state_r <= SM_PRE;
                    cmd     <= CMD_NOP;
                end if;
            when SM_RMS    => -- 2
                if(first_s = '1') then
                    cmd <= CMD_NOP;
                    if(cnt0 = '1') then
                        first_r <= '0';
                        state_r <= SM_IDLE;
                    else
                        first_r <= '1';
                        state_r <= SM_RMS;
                    end if;
                else
                    first_r <= '1';
                    state_r <= SM_RMS;
                    cmd     <= CMD_MRS;
                end if;
            when SM_READ   => -- 5
                if(first_s = '0') then
                    first_r <= '1';
                    state_r <= SM_READ;
                    cmd     <= CMD_NOP;
                else
                    if   (cnt0 = '1') then
                        first_r <= '0';
                        state_r <= SM_READA;
                        cmd     <= CMD_NOP;
                    elsif(counter_s = cCAC - 2) then
                        first_r <= '1';
                        state_r <= SM_READ;
                        cmd     <= CMD_READA;
                    else
                        first_r <= '1';
                        state_r <= SM_READ;
                        cmd     <= CMD_NOP;
                    end if;
                end if;
            when SM_READA  => -- 6
                cmd <= CMD_NOP;
                if(first_s = '1') then
                    if(cnt0 = '1') then
                        state_r  <= SM_IDLE;
                        first_r  <= '0';
                    else
                        state_r <= SM_READA;
                        first_r <= '1';
                     end if;
                else
                    state_r <= SM_READA;
                    first_r     <= '1';
                end if;
            when SM_WRITE => -- 4
                if(first_s = '1') then
                    if(counter_s = 9) then
                        first_r <= '1';
                        cmd     <= CMD_WRITEA;
                        state_r <= SM_WRITE;
                    elsif(cnt0 = '1') then
                        first_r <= '0';
                        cmd     <= CMD_NOP;
                        state_r <= SM_IDLE;
                    else
                        first_r <= '1';
                        cmd     <= CMD_NOP;
                        state_r <= SM_WRITE;
                    end if;
                else
                    first_r    <= '1';
                    cmd        <= CMD_NOP;
                    state_r    <= SM_WRITE;
                end if;
            when others   => -- 7
                if(first_s = '1') then
                    if   (sdr_rw = "01") then
                        first_r <= '0';
                        state_r <= SM_READ;
                        cmd     <= CMD_ACT;
                    elsif(sdr_rw = "10") then
                        first_r <= '0';
                        state_r <= SM_WRITE;
                        cmd     <= CMD_ACT;
                    elsif(refresh < 1) then
                        first_r <= '0';
                        state_r <= SM_PRE;
                        cmd     <= CMD_PALL;
                    else
                        first_r <= '1';
                        state_r <= SM_IDLE;
                        cmd     <= CMD_NOP;
                    end if;
                else
                    first_r <= '1';
                    state_r <= SM_IDLE;
                    cmd     <= CMD_NOP;
                end if;
        end case;
    end process state_machine;
    
    -- Outputs blocks
    -- DRAM_CS_N  <= opcode(3); -- Chip Select
    -- DRAM_RAS_N <= opcode(2); -- Row Address Select
    -- DRAM_CAS_N <= opcode(1); -- Column Adress Select
    -- DRAM_WE_N  <= opcode(0); -- Write enable
    opcode     <= sdram_opcode(cmd);
    DRAM_CLK   <= clock;     
    DRAM_CKE   <= '1';       -- Clk suspend
    DRAM_QM    <= "11" when state_s = SM_POWER                                                else "00";
    DRAM_BA    <= sdr_addr_r(14 downto 13);
    DRAM_ADDR  <= sdr_addr_r(12 downto  0);
    DRAM_DQ    <= 
    sdr_write( 15 downto   0) when (state_s = SM_WRITEA and first_s = '1' and counter_s =  9) else
    sdr_write( 31 downto  16) when (state_s = SM_WRITEA and first_s = '1' and counter_s =  8) else
    sdr_write( 47 downto  32) when (state_s = SM_WRITEA and first_s = '1' and counter_s =  7) else
    sdr_write( 63 downto  48) when (state_s = SM_WRITEA and first_s = '1' and counter_s =  6) else
    sdr_write( 79 downto  64) when (state_s = SM_WRITEA and first_s = '1' and counter_s =  5) else
    sdr_write( 95 downto  80) when (state_s = SM_WRITEA and first_s = '1' and counter_s =  4) else
    sdr_write(111 downto  96) when (state_s = SM_WRITEA and first_s = '1' and counter_s =  3) else
    sdr_write(127 downto 112) when (state_s = SM_WRITEA and first_s = '1' and counter_s =  2) else
    (others => 'Z');
    
end architecture rtl;