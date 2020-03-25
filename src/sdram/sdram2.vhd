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
        DRAM_QM    : out   std_logic_vector(  1 downto 0); -- xTAM_DATA Lower Byte, Input/Output Mask
        -- DRAM_WE_N  : out   std_logic;                      -- Write Enable (Habilita a escrita)
        -- DRAM_CAS_N : out   std_logic;                      -- Column Address Strobe Command (Comando de Armazenar o endereço como coluna)
        -- DRAM_RAS_N : out   std_logic;                      -- Row Address Strobe Command (Comando de Armazenar o endereço como linha) 
        -- DRAM_CS_N  : out   std_logic                       -- Chip Select
    );
end entity sdram;

architecture rtl of sdram is
    
    constant IDLE  : natural range 0 to 7 := 0; -- 000
    constant POWER : natural range 0 to 7 := 1; -- 001
    constant PRE   : natural range 0 to 7 := 2; -- 010
    constant READ  : natural range 0 to 7 := 3; -- 011
    constant WRITE : natural range 0 to 7 := 4; -- 101

    
    signal cmd        : sdram_function                      := CMD_NOP;
    signal state_s    : natural range 0 to 7                := POWER;
    signal state_r    : natural range 0 to 7                := IDLE;
    -- signal opcode     : std_logic_vector(3 downto 0);
    
    signal counter_s  : timer                               := 0;
    signal counter_r  : timer                               := 0;
    signal first      : std_logic                           := '0';
    signal position   : natural range 0 to (BURST_LENGTH-1) := 0;
    
    signal sdr_addr_r : std_logic_vector(14 downto 0);
    signal read_flag  : std_logic_vector(127 downto 0);
    signal flag_power : std_logic;
    
begin
    
    counter_r <= 
    sdram_timer(state_s) when first = '0'   else 
    counter_s - 1        when counter_r > 0 else 0;
    
    position_r <= 
    position_s - 1 when counter_s < 1 and first = '1' and state_s > 2 else
    0              when position_s < 0                                else
    BURST_LENGTH - 1;
    
    first <= '1' when state_s = state_r else '0';
    
    state_r <= 
        POWER when first = '0'     and state_s = POWER else
        IDLE  when first = '0'     and state_s = IDLE  else
        PRE   when first = '0'     and state_s = PRE   else
        READ  when first = '0'     and state_s = READ  else
        WRITE when first = '0'     and state_s = WRITE else
        POWER when state_s = POWER and counter_s > 0   else
        READ  when state_s = READ  and counter_s > 0   else
        WRITE when state_s = WRITE and counter_s > 0   else
        READ  when state_s = READ  and position  > 0   else
        WRITE when state_s = WRITE and position  > 0   else
        READ  when state_s = IDLE  and sdr_rw(0) = '1' else
        WRITE when state_s = IDLE  and sdr_rw(1) = '1' else
        IDLE  when state_s = IDLE  and counter_s > 0   else
        PRE   when state_s = PRE   and counter_s > 0   else
        PRE   when state   = IDLE                      else
        IDLE;
    
    process(sys_clk) is begin
        if(sys_clk'event and sys_clk = '1') then
            counter_s  <= counter_r;
            state_s    <= state_r;
            position_s <= position_r;
        end if;
    end process;
    
end architecture rtl;