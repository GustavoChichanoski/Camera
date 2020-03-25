library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     work.sdram_parameters.all;
use     work.sys_package.all;

package sdram_functions is
    
    function sdram_address 
        (
            cmd  : std_logic_vector(3 downto 0); 
            addr : std_logic_vector(14 downto 0)
        )
    return address;
    
    function sdram_opcode(cmd : std_logic_vector(3 downto 0)) return std_logic_vector;
    
    function sdram_timer (state : std_logic_vector(2 downto 0)) return timer;
    
    function sdram_read_burst
        (
            start_column : std_logic_vector(2 downto 0);
            data_in      : data((BURST_LENGTH - 1) downto 0)
        ) 
    return data;
    
    function shift_data
        (
            data_in : data(7 downto 0);
            posicao : natural range 0 to 7
        )
    return data;
    
end package sdram_functions;

package body sdram_functions is
    
    function sdram_opcode
        (
            cmd : std_logic_vector(3 downto 0)
        ) 
        return std_logic_vector is
    begin
        case cmd is
            when CMD_NOP                => return "0111";
            when CMD_BST                => return "0110";
            when CMD_READ  | CMD_READA  => return "0101";
            when CMD_WRITE | CMD_WRITEA => return "0100";
            when CMD_ACT                => return "0011";
            when CMD_PRE   | CMD_PALL   => return "0010";
            when CMD_REF   | CMD_SELF   => return "0001";
            when CMD_MRS                => return "0000";
            when others                 => return "1111";
        end case;
    end sdram_opcode;
    
    function sdram_address
        (
            cmd  : std_logic_vector(3 downto 0); 
            addr : std_logic_vector(24 downto 0)
        ) 
        return address is
    begin
        case cmd is
            when CMD_WRITEA | CMD_READA | CMD_PALL => 
                return addr(24 downto 23) & "001" & addr(9 downto 0);
            when CMD_WRITE  | CMD_READ  | CMD_PRE  => 
                return addr(24 downto 23) & "000" & addr(9 downto 0);
            when CMD_MRS                           => 
                -- Reserved - Write Burst - Operation Mode - Latency Mode - Burst Type - Burst Length
                return "00000" & "0" & "00" & "011" & "0" & "011";
            when others =>
                return addr(24 downto 23) & addr(22 downto 10);
        end case;
    end sdram_address;
    
    function sdram_timer 
        (
            state   : std_logic_vector(2 downto 0)
        ) 
        return timer is 
    begin
        case state is
            when SM_PRE     => return cRP + 2*cRC;       -- 0
            -- when SM_POWER  => return cSetup - 1;
            when SM_POWER   => return 2;                      -- 1
            when SM_RMS     => return cMRD - 1;               -- 2
            when SM_WRITE   => return cRCD + BURST_LENGTH - 4 + cRP; -- 3 : 3 + 8 + 3 - 4 : 10 * 5 ns : 70 ns
            when SM_WRITEA  => return cRCD + BURST_LENGTH - 1 + cRP; -- 4 : 3 + 8 + 3 - 1 : 14 * 5 ns : 70 ns
            when SM_READ    => return cRCD + cCAC  - 4;       -- 5 -- cRCD + cCAC
            when SM_READA   => return BURST_LENGTH - 1;       -- 6
            when SM_IDLE    => return 5;                      -- 7
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
    
    function sdram_cmd
        (
            first : std_logic;
            count : timer;
            state : std_logic_vector(3 downto 0)
        )
        return std_logic_vector is
    begin
        case state is
            when SM_POWER  =>
                if    (first = '1') then
                    return CMD_NOP;
                elsif (count = cRP + 2*cRC + cMRD) then
                    return CMD_PALL;
                elsif (count = 2*cRC + cMRD or count = cRC + cMRD) then
                    return CMD_SELF;
                elsif (count = cMRD) then
                    return CMD_MRS;
                else
                    return CMD_NOP;
                end if;
            when SM_PRE   =>
                if   (first = '0') then
                    return CMD_PALL;
                elsif(count = 2*cRC or count = cRC) then
                    return CMD_SELF;
                else
                    return CMD_NOP;
                end if;
            when SM_READ   =>
                if(first = '0') then
                    return CMD_ACT;
                elsif(count = cCAC - 1) then
                    return CMD_READA;
                else
                    return CMD_NOP;
                end if;
            when SM_READA  =>
                return CMD_NOP;
            when SM_WRITE  =>
                if(first = '0') then
                    return CMD_ACT;
                else
                    return CMD_NOP;
                end if;
            when SM_WRITEA =>
                if   (first = '0') then
                    return CMD_WRITEA;
                else
                    return CMD_NOP;
                end if;
            when SM_IDLE   =>
                return CMD_NOP;
            when SM_RMS    =>
                return CMD_NOP;
        end case;
    end sdram_cmd;
    
    function distance
        (
            start : address_type;
            addr  : address_type
        )
        return address_type is
        variable start_v : unsigned(24 downto 0);
        variable addr_v  : unsigned(24 downto 0);
    begin
        start_v := unsigned(start);
        addr_v  := unsigned(addr);
        if(start_v > addr_v) then
            return std_logic_vector(addr_v + 307_200 - start_v);
        else
            return std_logic_vector(addr_v              - start_v);
        end if;
    end distance;
    
    function dq_value
        (
            state   : std_logic_vector(3 downto 0);
            counter : timer
        )
        return std_logic_vector is
    begin
        if(counter > 0) then
            return "00";
        end if;
    end dq_value;
    
end package body sdram_functions;