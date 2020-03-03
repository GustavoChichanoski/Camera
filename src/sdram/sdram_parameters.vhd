library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     work.sys_package.all;

package sdram_parameters is
    
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
    type sdram_function is
    (
        CMD_DESL  ,  -- Device deselect
        CMD_NOP   ,  -- No operation
        CMD_BST   ,  -- Burst stop
        CMD_READ  ,  -- Read
        CMD_READA ,  -- Read with auto precharge
        CMD_WRITE ,  -- Write
        CMD_WRITEA,  -- Write with auto precharge
        CMD_ACT   ,  -- Bank activate
        CMD_PRE   ,  -- Precharge select bank
        CMD_PALL  ,  -- Precharge all banks
        CMD_REF   ,  -- CBR Auto-Refresh
        CMD_SELF  ,  -- Self-Refresh
        CMD_MRS      -- Mode Register Set
    );
    
    type sdram_sm is 
    (
        SM_POWER_ON  ,
        SM_PRECHARGE ,
        SM_IDLE      ,
        SM_READ      ,
        SM_WRITE     
    );
    
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
        
end package sdram_parameters;