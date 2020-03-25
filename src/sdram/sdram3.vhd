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
        -- SDRAM interface
        DRAM_DQ    : inout byte;                           -- Data I/O
        DRAM_ADDR  : out   std_logic_vector( 12 downto 0); -- A0 - A12 Row Address Input : A0 - A9 Column Address Input
        DRAM_BA    : out   std_logic_vector(  1 downto 0); -- Bank Select Address Input
        DRAM_CLK   : out   std_logic;                      -- System Clock Input
        DRAM_CKE   : out   std_logic;                      -- Clock Enable
        DRAM_QM    : out   std_logic_vector(  1 downto 0); -- xTAM_DATA Lower Byte, Input/Output Mask
        opcode     : out   std_logic_vector(3 downto 0)
        -- DRAM_WE_N  : out   std_logic;                      -- Write Enable (Habilita a escrita)
        -- DRAM_CAS_N : out   std_logic;                      -- Column Address Strobe Command (Comando de Armazenar o endereço como coluna)
        -- DRAM_RAS_N : out   std_logic;                      -- Row Address Strobe Command (Comando de Armazenar o endereço como linha) 
        -- DRAM_CS_N  : out   std_logic                       -- Chip Select
    );
end entity sdram;

architecture rtl of sdram is
    
    signal cmd        : sdram_function                      := CMD_NOP;
    signal state_s    : std_logic_vector(3 downto 0)        := SM_power;
    signal state_r    : std_logic_vector(3 downto 0)        := SM_power;
    signal state_m    : std_logic_vector(3 downto 0)        := SM_power;
    -- signal opcode     : std_logic_vector(3 downto 0);
    
    signal counter_s  : timer                               := 0;
    signal counter_r  : timer                               := 0;
    signal first_s    : std_logic                           := '0';
    signal first_r    : std_logic                           := '0';
    signal position   : natural range 0 to (BURST_LENGTH-1) := 0;
    
    signal sdr_addr_r : std_logic_vector(14 downto 0);
    signal read_flag  : std_logic_vector(127 downto 0);
    signal flag_power : std_logic;
    signal clock      : std_logic;
    
    signal refresh    : natural range 0 to 1023 := 1000;
    signal refresh_r  : natural range 0 to 1023 := 1000;
    
begin
    
    clock <= '1' when sys_clk = '1' and pll_locked = '1' else '0';
    with state_s select
        sdr_state <= 
        "001" when SM_POWER ,
        "010" when SM_PRE0  ,
        "011" when SM_WRITE ,
        "100" when SM_WRITEA,
        "101" when SM_READ  ,
        "110" when SM_READA ,
        "111" when SM_PRE   ,
        "000" when others   ;
    refresh_r  <= 
    0    when refresh < 1      else
    1000 when state_s = SM_PRE else
    refresh - 1;
    counter_r  <=
    sdram_timer(state_s) when first_s = '0' else
    0                    when counter_s < 1 else 
    counter_s - 1;
    first_r <= '0' when (counter_s < 1) else '1';
    state_r <= sdram_state(counter_s,first_s,state_s,refresh,sdr_rw);
    cmd     <= sdram_cmd(counter_s,first_s,state_s);
    
    sdr_cnt    <= counter_s;
    sdr_done   <= '1' when (state_s = SM_READ or state_s = SM_WRITE) and position < 1 and first_s = '1' else '0';
    sdr_busy   <= '1' when state_s = SM_IDLE  else '0';
    sdr_first  <= first_s;
    sdr_addr_r <= sdram_address(cmd,sdr_addr);
    sdr_read   <= read_flag;
    
    state_machine : process(sys_clk)
    begin
        if(clock'event and clock = '1') then
            first_s   <= first_r;
            refresh   <= refresh_r;
            counter_s <= counter_r;
            state_s   <= state_r;
        end if;
    end process state_machine;
    
    -- Outputs blocks
    -- DRAM_CS_N  <= opcode(3); -- Chip Select
    -- DRAM_RAS_N <= opcode(2); -- Row Address Select
    -- DRAM_CAS_N <= opcode(1); -- Column Adress Select
    -- DRAM_WE_N  <= opcode(0); -- Write enable
    opcode     <= sdram_opcode(cmd);
    DRAM_CLK   <= clock;
    DRAM_CKE   <= '1'  when state_s /= SM_IDLE or cmd = CMD_SELF else '0';  -- Clk suspend
    DRAM_QM    <= "11" when state_s = SM_power                else "00";
    DRAM_BA    <= sdr_addr_r(14 downto 13);
    DRAM_ADDR  <= sdr_addr_r(12 downto  0);
    DRAM_DQ    <= sdr_write((TAM_DATA*(counter_s + 1) - 1) downto TAM_DATA*counter_s) when state_s = SM_WRITEA else (others => 'Z');
    
end architecture rtl;