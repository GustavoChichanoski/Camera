library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     work.sdram_parameters.all;
use     work.sdram.all;

entity sdram_tb is end;

architecture bench of sdram_tb is

  component sdram
      port
      (
          pll_locked : in    std_logic;
          sys_clk    : in    std_logic;
          sdr_rw     : in    std_logic_vector(  1 downto 0);
          sdr_addr   : in    std_logic_vector( 24 downto 0);
          sdr_write  : in    std_logic_vector(127 downto 0);
          sdr_read   : out   std_logic_vector(127 downto 0);
          sdr_done   : out   std_logic;
          sdr_busy   : out   std_logic;
          sdr_first  : out   std_logic;
          sdr_state  : out   sdram_sm;
          DRAM_DQ    : inout std_logic_vector( 15 downto 0);
          DRAM_ADDR  : out   std_logic_vector( 12 downto 0);
          DRAM_BA    : out   std_logic_vector(  1 downto 0);
          DRAM_CLK   : out   std_logic;
          DRAM_CKE   : out   std_logic;
          DRAM_QM    : out   std_logic_vector(  1 downto 0);
          DRAM_WE_N  : out   std_logic;
          DRAM_CAS_N : out   std_logic;
          DRAM_RAS_N : out   std_logic;
          DRAM_CS_N  : out   std_logic
    );
  end component;

  signal pll_locked : std_logic;
  signal sys_clk    : std_logic;
  signal sdr_rw     : std_logic_vector(  1 downto 0);
  signal sdr_addr   : std_logic_vector( 24 downto 0);
  signal sdr_write  : std_logic_vector(127 downto 0);
  signal sdr_read   : std_logic_vector(127 downto 0);
  signal sdr_done   : std_logic;
  signal sdr_busy   : std_logic;
  signal sdr_first  : std_logic;
  signal sdr_state  : sdram_sm;
  signal DRAM_DQ    : std_logic_vector( 15 downto 0);
  signal DRAM_ADDR  : std_logic_vector( 12 downto 0);
  signal DRAM_BA    : std_logic_vector(  1 downto 0);
  signal DRAM_CLK   : std_logic;
  signal DRAM_CKE   : std_logic;
  signal DRAM_QM    : std_logic_vector(  1 downto 0);
  signal DRAM_WE_N  : std_logic;
  signal DRAM_CAS_N : std_logic;
  signal DRAM_RAS_N : std_logic;
  signal DRAM_CS_N  : std_logic ;

  constant clock_period: time := 5 ns;
  signal stop_the_clock: boolean;

begin

    uut : sdram port map 
    ( 
        pll_locked => pll_locked,
        sys_clk    => sys_clk   ,
        sdr_rw     => sdr_rw    ,
        sdr_addr   => sdr_addr  ,
        sdr_write  => sdr_write ,
        sdr_read   => sdr_read  ,
        sdr_done   => sdr_done  ,
        sdr_busy   => sdr_busy  ,
        sdr_first  => sdr_first ,
        sdr_state  => sdr_state ,
        DRAM_DQ    => DRAM_DQ   ,
        DRAM_ADDR  => DRAM_ADDR ,
        DRAM_BA    => DRAM_BA   ,
        DRAM_CLK   => DRAM_CLK  ,
        DRAM_CKE   => DRAM_CKE  ,
        DRAM_QM    => DRAM_QM   ,
        DRAM_WE_N  => DRAM_WE_N ,
        DRAM_CAS_N => DRAM_CAS_N,
        DRAM_RAS_N => DRAM_RAS_N,
        DRAM_CS_N  => DRAM_CS_N  
    );

    stimulus: process
    begin
        
        -- Put initialisation code here
        pll_locked <= '1';
        sdr_rw     <= "10";
        sdr_addr   <= (others => '0');
        sdr_write  <= (others => '0');
        
        -- Put test bench stimulus code here
       
        stop_the_clock <= true;
        wait;
    end process;

    clocking: process
    begin
        while not stop_the_clock loop
        sys_clk <= '0', '1' after clock_period / 2;
        wait for clock_period;
        end loop;
        wait;
    end process;

end;