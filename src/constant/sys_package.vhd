library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package sys_package is
    
    constant BIT_ADDR   : integer := 25;
    constant GLOBAL_CLK : natural := 50_000_000;
    
    type sdram_type is record
        data   : std_logic_vector(15 downto 0);
        addr   : unsigned(24 downto 0);
        rw     : std_logic;
        cs     : std_logic;
        length : unsigned(3 downto 0);
    end record sdram_type;
    
    type BANK         is array (3 downto 0) of natural range 0 to 26;
    subtype address_type is std_logic_vector(24 downto 0);
    subtype byte         is std_logic_vector(15 downto 0);
    
    type t_opcode is 
    (
        MRS, REF, SELF, PRE, PALL, ACT, 
        WRITE, WRITEA, READ, READA, 
        BST, NOP, DESL, ENB, MASK
    );
    
    component camera is
        generic
        (
            VGA_HORZ_PIXEL  : unsigned (10 downto 0) := "11110000000"; -- 1920
            VGA_VERT_PIXEL  : unsigned (10 downto 0) := "10000111000"; -- 1080
            CAM_HORZ_PIXEL  : unsigned ( 8 downto 0) := "110100000";   -- 640
            CAM_VERT_PIXEL  : unsigned ( 8 downto 0) := "111100000"    -- 480
        );
        port
        (
            user_reset   : in    std_logic;                    -- Assynchronous active low reset
            user_clk     : in    std_logic;                    -- System clock
            ov7670_href  : in    std_logic;                    -- Horizonta reference
            ov7670_vref  : in    std_logic;                    -- Vertical reference
            ov7670_data  : in    std_logic_vector(7 downto 0); -- Color output
            ov7670_pclk  : in    std_logic;                    -- Pixel clock
            ov7670_xclk  : out   std_logic;                    -- ov7670 clock input
            ov7670_siod  : inout std_logic;                    -- ov7670 clock input
            ov7670_sioc  : inout std_logic;                    -- ov7670 clock input
            ov7670_reset : out   std_logic;                    -- ov7670 reset
            ov7670_pwdn  : out   std_logic;                    -- ov7670 power down
            vga_x        : in    unsigned(14 downto 0);
            vga_y        : in    unsigned(14 downto 0);
            vga_ena      : in    std_logic;
            vga_img      : out   std_logic_vector(15 downto 0)
        );
    end component camera;
    
    component my_i2c is
        port 
        ( 
            i2c_clk       : in     std_logic;                    -- System clock
            i2c_reset     : in     std_logic;                    -- Active low reset
            i2c_ena       : in     std_logic;                    -- Latch in command
            i2c_addr      : in     std_logic_vector(6 downto 0); -- Address of target slave
            i2c_rw        : in     std_logic;                    -- '0': Write - '1' : Read 
            i2c_busy      : out    std_logic;                    -- Indicates transaction in progress
            i2c_data_rw   : out    std_logic_vector(7 downto 0); -- Data to write to slave
            i2c_ack_error : buffer std_logic;                    -- flag if improper acknowledge from slave
            i2c_sda       : inout  std_logic;                    -- Serial data output of i2c bus
            i2c_scl       : inout  std_logic                     -- Serial clock output of i2c bus
        );
    end component my_i2c;
        
end package sys_package;