library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     work.sys_package.all;

package sdram_parameters is
    
    constant TAM_DATA     : natural := 16;
    
    -- Timing SDRAM parameters in cycles
    constant RAM_CLK      : natural := 200_000_000;
    constant fSetup       : natural :=      10_000;
    constant fRECYCLE     : natural :=     138_888;
    constant cRECYCLE     : natural := RAM_CLK/fRECYCLE;
    constant cSETUP       : natural := 1_440; -- RAM_CLK/fSetup
    constant cCAC         : natural := 3;     -- CAS latency
    constant cRCD         : natural := 3;     
    constant cRAC         : natural := 6;     -- RAS latency
    constant cRC          : natural := 10;
    constant cRAS         : natural := 7;
    constant cRP          : natural := 3;
    constant cXSR         : natural := 36 - cRP - cRAS;
    constant cRRD         : natural := 2;
    constant cCCD         : natural := 1;
    constant cDPL         : natural := 2;
    constant cDAL         : natural := 5;
    constant cRBD         : natural := 3;
    constant cWBD         : natural := 0;
    constant cRQL         : natural := 3;
    constant cWDL         : integer := 0;
    constant cPQL         : integer := -2;
    constant cQMD         : natural := 2;     -- Read
    constant cDMD         : natural := 0;     -- Write
    constant cMRD         : natural := 2;
    -- Valores do registrador
    constant MRD          : std_logic_vector(12 downto 0) := "0000000100000";
    -- parameters SDRAM
    constant ROW_N        : natural := 8192;
    constant COL_N        : natural := 1024;
    constant NUM_BANKS    : natural := 4;
    constant BURST_LENGTH : natural := 8;
    -- Parameters ADDR
    
    type ram_type is array (0 to 15) of byte;
    
    constant CMD_DESL   : std_logic_vector(3 downto 0) := "1111"; -- Device deselect
    constant CMD_NOP    : std_logic_vector(3 downto 0) := "0111"; -- No operation
    constant CMD_READ   : std_logic_vector(3 downto 0) := "0101"; -- Read
    constant CMD_BST    : std_logic_vector(3 downto 0) := "0110"; -- Burst stop
    constant CMD_READA  : std_logic_vector(3 downto 0) := "1101"; -- Read with auto precharge
    constant CMD_WRITE  : std_logic_vector(3 downto 0) := "0100"; -- Write
    constant CMD_WRITEA : std_logic_vector(3 downto 0) := "1100"; -- Write with auto precharge
    constant CMD_ACT    : std_logic_vector(3 downto 0) := "0011"; -- Bank activate
    constant CMD_PRE    : std_logic_vector(3 downto 0) := "0010"; -- Precharge select bank
    constant CMD_PALL   : std_logic_vector(3 downto 0) := "1010"; -- Precharge all banks
    constant CMD_SELF   : std_logic_vector(3 downto 0) := "0001"; -- Self-Refresh
    constant CMD_REF    : std_logic_vector(3 downto 0) := "1001"; -- CBR Auto-Refresh
    constant CMD_MRS    : std_logic_vector(3 downto 0) := "0000"; -- Mode Register Set
    
    constant SM_PRE    : std_logic_vector(2 downto 0) := "000"; -- 0
    constant SM_POWER  : std_logic_vector(2 downto 0) := "001"; -- 1
    constant SM_RMS    : std_logic_vector(2 downto 0) := "010"; -- 2
    constant SM_WRITE  : std_logic_vector(2 downto 0) := "011"; -- 3
    constant SM_WRITEA : std_logic_vector(2 downto 0) := "100"; -- 4
    constant SM_READ   : std_logic_vector(2 downto 0) := "101"; -- 5
    constant SM_READA  : std_logic_vector(2 downto 0) := "110"; -- 6
    constant SM_IDLE   : std_logic_vector(2 downto 0) := "111"; -- 7
    
    type t_memory is
    (
        SETUP   ,
        READY   ,
        READER  ,
        READER_0,
        READER_1,
        READER_2,
        READER_3,
        WRITER  ,
        WRITER_0,
        WRITER_1,
        WRITER_2,
        SREF
    );
    
    type imagem is record
        start    : address_type;
        addr     : address_type;
        position : address_type;
        pid      : natural range 0 to 15;
        data     : std_logic_vector(255 downto 0);
        img      : std_logic;
        cs       : std_logic;
    end record imagem;
    
    subtype address  is std_logic_vector(14 downto 0);
    subtype timer    is natural range 0 to 65535;
    type    data     is array((BURST_LENGTH - 1) downto 0) of std_logic_vector(15 downto 0);
    
    -- VGA pode apresentar no máximo 6 imagens ao mesmo tempo
    component sdram is
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
        DRAM_ADDR  : out   std_logic_vector(12 downto 0);  -- A0 - A12 Row Address Input : A0 - A9 Column Address Input
        DRAM_BA    : out   std_logic_vector( 1 downto 0);  -- Bank Select Address Input
        DRAM_CLK   : out   std_logic;                      -- System Clock Input
        DRAM_CKE   : out   std_logic;                      -- Clock Enable
        DRAM_QM    : out   std_logic_vector(1 downto 0);   -- xTAM_DATA Lower Byte, Input/Output Mask
        DRAM_WE_N  : out   std_logic;                      -- Write Enable (Habilita a escrita)
        DRAM_CAS_N : out   std_logic;                      -- Column Address Strobe Command (Comando de Armazenar o endereço como coluna)
        DRAM_RAS_N : out   std_logic;                      -- Row Address Strobe Command (Comando de Armazenar o endereço como linha) 
        DRAM_CS_N  : out   std_logic                       -- Chip Select
    );
    end component sdram;
    
end package sdram_parameters;