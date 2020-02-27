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
    
    signal cam        : ram_type;
    signal vga        : ram_type;
    
begin
    
    cam.position <= distance(cam.start,cam.addr);
    vga.position <= distance(vga.start,vga.addr);
    
    --  24   23  | 22 21 20 19 18 17 16 15 14 13 12 11 10 | 09 08 07 06 05 04 03 02 01 00 |
    -- BS00 BS01 |         ROW (A12-A0) 8192 rows         |     COL (A9-A0) 1024 cols     |
    
    control : process(sys_clk)
    begin
        if rising_edge(sys_clk) then
            if sys_rst = '0' then
                
            else
                if(cam.addr /= cam_addr) then
                    cam.addr <= cam_addr;
                end if;
                if(vga.addr /= vga_addr) then
                    vga.addr <= vga_addr;
                end if;
            end if;
        end if;
    end process control;
    
    proc_name: process(sdr_done)
    begin
        if(rising_edge(sdr_done)) then
            if(cam.cs = '0' and vga.cs = '0') then
                if(unsigned(cam.position) > 7) then
                    cam.cs    <= '1';
                    sdr_addr  <= cam.start;
                    cam.start <= ;
                elsif(unsigned(vga.position > 7)) then
                    vga.cs   <= '1';
                    sdr_addr <= vga.start;
                end if;
            end if;
        end if;
    end process proc_name;
    
    ram : process(sys_clk,sys_rst)
    begin
        if rising_edge(sys_clk) then
            cam(to_integer(unsigned(cam.position))) <= cam_data;
            vga(to_integer(unsigned(vga.position))) <= sdr_data;
        end if;
    end process ram;
    
end architecture rtl;