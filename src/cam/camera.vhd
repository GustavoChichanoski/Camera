library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     work.cam_package.all;
use     work.sdram_parameters.all;
use     work.sys_package.all;

entity camera is
    port
    (
        sys_rst        : in    std_logic;    -- Assynchronous active low reset
        sys_clk        : in    std_logic;    -- System clock
        cam_clk_i      : in    std_logic;    -- Cam clock
        cam_pclk_o     : out   std_logic;    -- Pixel clock
        cam_done       : out   std_logic;    -- Finish image
        ov7670_href_i  : in    std_logic;    -- Horizonta reference
        ov7670_vref_i  : in    std_logic;    -- Vertical reference
        ov7670_data_i  : in    byte;         -- Color input
        ov7670_data_o  : out   byte;         -- Color output
        ov7670_pclk_i  : in    std_logic;    -- Pixel clock
        ov7670_xclk_o  : out   std_logic;    -- ov7670 clock input
        ov7670_siod_io : inout std_logic;    -- ov7670 clock input
        ov7670_sioc_io : inout std_logic;    -- ov7670 clock input
        ov7670_addr_o  : out   address_type; -- Address output
        ov7670_rst_o   : out   std_logic;    -- ov7670 reset
        ov7670_pwdn_o  : out   std_logic     -- ov7670 power down
    );
end camera;

architecture rtl of camera is
    
    signal write         : std_logic_vector(7 downto 0);
    signal registrador   : std_logic_vector(7 downto 0);
    signal busy          : std_logic;
    signal find          : std_logic;
    
    signal write_reg     : data;
    
    signal cam           : t_image;
    
    signal red           : std_logic_vector(4 downto 0);
    signal green         : std_logic_vector(5 downto 0);
    signal blue          : std_logic_vector(4 downto 0);
    
    signal cam_find      : std_logic := '0';
    signal setup_ok      : std_logic := '0';
    
    signal clk_pixel_s     : std_logic := '0';
    
    signal opcode_clk    : std_logic;
    signal opcode_clk_en : std_logic := '0';
    signal sccb_clk      : std_logic;
    signal sccb_clk_en   : std_logic;
    
    signal counter       : natural range 0 to 15_000_000 := 0;
    
begin
    
    delay : process(sys_clk, sys_rst)
    begin
        if sys_rst = '0' then
            counter <= 15_000_000;
        elsif rising_edge(sys_clk) then
            if(counter < 1) then
                sccb_clk_en <= '1';
                counter     <= 0;
            else
                counter <= counter - 1;
            end if;
        end if;
    end process delay;
    
    ov7670_xclk_o <= cam_clk_i;          -- Define clock camera
    ov7670_rst_o  <= not sys_rst;        -- Send the reset signal
    ov7670_data_o <= blue & green & red; -- Define color output
    -- Fill pixel color
    blue (4 downto 0) <= ov7670_data_i(4 downto 0) when (clk_pixel_s = '0') else blue (4 downto 0);
    green(2 downto 0) <= ov7670_data_i(7 downto 5) when (clk_pixel_s = '0') else green(2 downto 0);
    green(5 downto 3) <= ov7670_data_i(2 downto 0) when (clk_pixel_s = '1') else green(5 downto 3);
    red  (4 downto 0) <= ov7670_data_i(7 downto 3) when (clk_pixel_s = '1') else red  (4 downto 0);
    -- Find cam_address
    cam_find      <= '1'  when find     = '1'      else '0' when sys_rst = '0' else cam_find; -- Find camera
    opcode_clk    <= busy when opcode_clk_en = '1' else '0';                                  -- 
    opcode_clk_en <= '1'  when cam_find = '1'      else opcode_clk_en;
        
    C2 : opcode port map 
    (
        user_reset  => sys_rst, 
        user_clk    => opcode_clk, 
        registrador => registrador, 
        write       => write, 
        done        => setup_ok
    );
    
    sccb_clk <= sys_clk when sccb_clk_en = '1' else '0';
    
    C1 : sccb port map
    (
        user_reset => sys_rst,
        user_clk   => sccb_clk,
        user_send  => not setup_ok,
        sccb_write => write,
        sccb_reg   => registrador,
        sccb_addr  => std_logic_vector(cam.addr),
        sccb_busy  => busy,
        sccb_find  => find,
        sccb_pwdn  => ov7670_pwdn_o,
        sccb_sioc  => ov7670_sioc_io,
        sccb_siod  => ov7670_siod_io
    );
    
    px_clk : process(ov7670_pclk_i) begin
        if rising_edge(ov7670_pclk_i) then
            if(ov7670_href_i = '0' or ov7670_vref_i = '0') then
                clk_pixel_s <= '1';
            else
                clk_pixel_s <= not clk_pixel_s;
            end if;
        end if;
    end process px_clk;
    
    addr: process(clk_pixel_s)
    begin
        if (falling_edge(clk_pixel_s)) then
            cam.addr <= 
            cam_addr_next
            (
                cam.addr,
                ov7670_href_i,
                ov7670_vref_i
            );
        end if;
    end process addr;
    
    ov7670_addr_o   <= std_logic_vector(cam.addr);
    cam_pclk_o <= clk_pixel_s;
    
end rtl ; -- camera rtl camera