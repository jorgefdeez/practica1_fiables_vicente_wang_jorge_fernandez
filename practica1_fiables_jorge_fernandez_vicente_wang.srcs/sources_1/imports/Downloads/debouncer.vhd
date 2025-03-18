library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity debouncer is
    generic(
        g_timeout          : integer   := 5;        -- Time in ms
        g_clock_freq_KHZ   : integer   := 100_000   -- Frequency in KHz of the system 
    );   
    port (  
        rst_n       : in    std_logic; -- asynchronous reset, low -active
        clk         : in    std_logic; -- system clk
        ena         : in    std_logic; -- enable must be on 1 to work (kind of synchronous reset)
        sig_in      : in    std_logic; -- signal to debounce
        debounced   : out   std_logic  -- 1 pulse flag output when the timeout has occurred
    ); 
end debouncer;

architecture Behavioural of debouncer is 
      
    -- Calculate the number of cycles of the counter (debounce_time * freq), result in cycles
    constant c_cycles           : integer := integer(g_timeout * g_clock_freq_KHZ) ;
	-- Calculate the length of the counter so the count fits
    constant c_counter_width    : integer := integer(ceil(log2(real(c_cycles))));
    
    -- Declarar un tipo para los estados de la FSM
    type state_type is (IDLE, COUNTING, STABLE);
    signal state, next_state : state_type;
    
    signal counter : integer range 0 to c_cycles := 0;
    signal sig_stable : std_logic := '0';
    
begin
    -- Timer process
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

    -- FSM Register of next state
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            state <= IDLE;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;
    
    -- Combinational logic for FSM
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
    
    -- Output assignment
    debounced <= '1' when state = STABLE else '0';
    
end Behavioural;
