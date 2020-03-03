library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     work.sys_package.all;
use     work.sdram_functions.all;
use     work.sdram_parameters.all;

entity sdram_controller is
    port
    (
        sys_clk    : in  std_logic;
        sys_rst    : in  std_logic;
        cam_addr   : in  address_type;
        cam_data   : in  byte;
        cam_done   : in  std_logic;
        vga_addr   : in  address_type;
        vga_data   : out byte;
        vga_done   : in  std_logic;
        sdr_done   : in  std_logic;
        sdr_addr   : out address_type;
        position   : out std_logic_vector( 2 downto 0)
    );
end entity sdram_controller;

architecture rtl of sdram_controller is
    
    signal cam        : imagem;
    signal cnn        : imagem;
    signal vga        : imagem;
    
    type   control_sm is (START,READ,WRITE,IDLE);
    signal state      : control_sm := START;
    signal state_next : control_sm := START;
    
    signal addr_next  : address_type;
    
begin
    
    
    
end architecture rtl;