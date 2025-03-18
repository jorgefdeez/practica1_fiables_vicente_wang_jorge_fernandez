library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity debouncer is
    generic(
        g_timeout          : integer   := 5;       
        g_clock_freq_KHZ   : integer   := 100_000   
    );   
    port (  
        rst_n       : in    std_logic; 
        clk         : in    std_logic; 
        ena         : in    std_logic; 
        sig_in      : in    std_logic; 
        debounced   : out   std_logic  
    ); 
end debouncer;

architecture Behavioural of debouncer is 
      
    constant c_cycles           : integer := integer(g_timeout * g_clock_freq_KHZ) ;
    constant c_counter_width    : integer := integer(ceil(log2(real(c_cycles))));
    
    type state_type is (IDLE, COUNTING, STABLE);
    signal state, next_state : state_type;
    
    signal counter : integer range 0 to c_cycles := 0;
    signal sig_stable : std_logic := '0';
    
begin
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            counter <= 0;
        elsif rising_edge(clk) then
            if state = COUNTING then
                if counter < c_cycles then
                    counter <= counter + 1;
                end if;
            else
                counter <= 0;
            end if;
        end if;
    end process;

    process (clk, rst_n)
    begin
        if rst_n = '0' then
            state <= IDLE;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;
    
    process (state, sig_in, counter)
    begin
        case state is
            when IDLE =>
                if sig_in = '1' then
                    next_state <= COUNTING;
                else
                    next_state <= IDLE;
                end if;
            
            when COUNTING =>
                if counter >= c_cycles then
                    next_state <= STABLE;
                else
                    next_state <= COUNTING;
                end if;
            
            when STABLE =>
                if sig_in = '0' then
                    next_state <= IDLE;
                else
                    next_state <= STABLE;
                end if;
            
            when others =>
                next_state <= IDLE;
        end case;
    end process;
    
    debounced <= '1' when state = STABLE else '0';
    
end Behavioural;
