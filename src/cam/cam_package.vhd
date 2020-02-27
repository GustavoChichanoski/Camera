library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package cam_package is
    
    -- Parametros da camera
    constant CAM_PX_HOR : natural := 640;
    constant CAM_PX_VER : natural := 480;
    constant CAM_PX_NUM : natural := CAM_PX_HOR*CAM_PX_VER;
    
    type t_image is record
        data : std_logic_vector(15 downto 0);
        addr : unsigned(18 downto 0);
    end record t_image;
    
    component opcode
        port
        (
            user_reset  : in  std_logic;
            user_clk    : in  std_logic;
            registrador : out std_logic_vector(7 downto 0);
            write       : out std_logic_vector(7 downto 0);
            done        : out std_logic
        );
    end component;
    
    component sccb 
        generic
        (
            fpga_clk   : natural := 50_000_000;
            sbbc_clk   : natural :=    400_000
        );
        port
        (
            user_reset : in    std_logic;
            user_clk   : in    std_logic;
            user_send  : in    std_logic;
            sccb_write : in    std_logic_vector(7 downto 0);
            sccb_reg   : in    std_logic_vector(7 downto 0);
            sccb_addr  : in    std_logic_vector(7 downto 0);
            sccb_busy  : out   std_logic;
            sccb_find  : out   std_logic;
            sccb_pwdn  : out   std_logic;
            sccb_sioc  : inout std_logic;
            sccb_siod  : inout std_logic
        );
    end component;
    
    function cam_addr_next
        (
            addr : unsigned(18 downto 0);
            href : std_logic;
            vref : std_logic
        )
    return unsigned;
    
end package cam_package;

package body cam_package is
    
    function cam_addr_next
        (
            addr : unsigned(18 downto 0);
            href : std_logic;
            vref : std_logic
        )
        return unsigned is
    begin
        if(href = '1' and vref = '1') then
            if(addr = "1001011000000000000‬") then
                addr <= (others => '0');
            else
                addr <= addr + 1;
            end if;
        end if;
    end cam_addr_next;
end package body cam_package;