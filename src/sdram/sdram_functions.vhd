library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     work.sdram_parameters.all;
use     work.sys_package.all;

package sdram_functions is
    
    function sdram_address (
            state    : sdram_function; 
            sdr_addr : std_logic_vector(14 downto 0)
        )
    return address;
    
    function sdram_opcode (state : sdram_function) return std_logic_vector;
    
    function sdram_timer (state : sdram_sm) return timer;
    
    function sdram_read_burst
        (
            start_column : std_logic_vector(2 downto 0);
            data_in      : data((BURST_LENGTH - 1) downto 0)
        ) 
    return data;
    
    function sdram_function_next
        (
            first : std_logic;
            count : timer;
            state : sdram_sm
        )
    return sdram_function;
    
    function shift_data(
            data_in : data(7 downto 0);
            posicao : natural range 0 to 7
        )
    return data;
    
    function sdram_addr_flag(
            addr_start : std_logic_vector(2 downto 0);
            addr_curr  : std_logic_vector(2 downto 0)
        )
    return std_logic;
    
    function sdram_cont_data
        (
            position : std_logic_vector(  2 downto 0);
            img      : std_logic_vector(255 downto 0);
            data     : std_logic_vector( 15 downto 0)
        )
    return std_logic_vector;
    
    function distance
        (
            start : address_type;
            addr  : address_type
        )
    return address_type;
    
end package sdram_functions;

package body sdram_functions is
    
    function sdram_opcode
        (
            state : sdram_function
        ) 
        return std_logic_vector is
    begin
        case state is
            when NOP            => return "0111";
            when BST            => return "0110";
            when READ  | READA  => return "0101";
            when WRITE | WRITEA => return "0100";
            when ACT            => return "0011";
            when PRE   | PALL   => return "0010";
            when REF   | SELF   => return "0001";
            when MRS            => return "0000";
            when others         => return "1111";
        end case;
    end sdram_opcode;
    
    function sdram_address
        (
            state    : sdram_function; 
            sdr_addr : std_logic_vector(25 downto 0)
        ) 
        return address is
    begin
        case state is
            when WRITEA | READA | PALL => return sdr_addr(24 downto 23) & "001" & sdr_addr(9 downto 0);
            when WRITE  | READ  | PRE  => return sdr_addr(24 downto 23) & "000" & sdr_addr(9 downto 0);
            when MRS                   => return "000001000110011";
            when others =>
                return sdr_addr(24 downto 10);
        end case;
    end sdram_address;
    
    function sdram_timer 
        (
            state   : sdram_sm
        ) 
        return timer is 
    begin
        case state is
            when POWER_ON            =>
                return cSetup + cRP + 2*cRC + cMRD;
            when PRECHARGE | REFRESH =>
                return cRP + 2*cRC;
            when READ                =>
                return cRCD + cCAC;
            when IDLE                =>
                return cRECYCLE;
            when ROW_ACTIVE | WRITE  =>
                return cRCD;
        end case;
    end sdram_timer;
    
    function sdram_read_burst
        (
            start_column : std_logic_vector(2 downto 0);
            data_in      : data((BURST_LENGTH - 1) downto 0)
        ) 
        return data is 
        variable aux : data((BURST_LENGTH - 1) downto 0);
    begin
        return shift_data(data_in,to_integer(unsigned(start_column(2 downto 0))));
    end sdram_read_burst;
    
    function shift_data
        (
            data_in : data((BURST_LENGTH - 1) downto 0);
            posicao : natural range 0 to BURST_LENGTH - 1
        )
        return data is
            variable i   : natural range (BURST_LENGTH - 1) downto 0;
            variable j   : natural range (BURST_LENGTH - 1) downto 0;
            variable aux : data(BURST_LENGTH - 1 downto 0);
    begin
        for j in 0 to posicao loop
            for i in 0 to BURST_LENGTH - 1 loop
                aux(i) := data_in(i-1);
            end loop;
        end loop;
        return aux;
    end shift_data;
    
    function sdram_function_next
        (
            first : std_logic;
            count : timer;
            state : sdram_sm
        )
        return sdram_function is
    begin
        case state is
            when POWER_ON  =>
                if    (first = '1') then
                    return NOP;
                elsif (count = cRP + 2*cRC + cMRD) then
                    return PALL;
                elsif (count = 2*cRC + cMRD or count = cRC + cMRD) then
                    return SELF;
                elsif (count = cMRD) then
                    return MRS;
                else
                    return NOP;
                end if;
            when PRECHARGE =>
                if   (first = '0') then
                    return PALL;
                elsif(count = 2*cRC or count = cRC) then
                    return SELF;
                else
                    return NOP;
                end if;
            when READ      =>
                if   (first = '0') then
                    return ACT;
                elsif(count = cRCD) then
                    return READ;
                else
                    return NOP;
                end if;
            when WRITE     =>
                if   (first = '0') then
                    return ACT;
                elsif(count = cRCD) then
                    return WRITE;
                else
                    return NOP;
                end if;
            when REFRESH   =>
                if   (first = '1') then
                    return PALL;
                elsif(count = 2*cRC or count = cRC) then
                    return SELF;
                else
                    return NOP;
                end if;
        end case;
    end sdram_function_next;
    
    function distance
        (
            start : address_type;
            addr  : address_type
        )
    return address_type is
        variable start_v : unsigned(24 downto 0);
        variable addr_v  : unsigned(24 downto 0);
    begin
        start_v <= unsigned(start);
        addr_v  <= unsigned(addr);
        if(start_v > addr_v) then
            return std_logic_vector(addr_v + CAM_PX_NUM - start_v);
        else
            return std_logic_vector(addr_v              - start_v);
        end if;
    end distance;
end package body sdram_functions;