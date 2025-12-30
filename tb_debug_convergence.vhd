library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_debug_convergence is
end tb_debug_convergence;

architecture behavior of tb_debug_convergence is

    -- DUT Component
    component square_root is
        port(
            clk           : in  std_logic;
            reset         : in  std_logic;
            uart_rx_line  : in  std_logic;
            uart_tx_line  : out std_logic;
            led_busy      : out std_logic;
            led_done      : out std_logic
        );
    end component;

    -- Signals
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    signal uart_rx_line : std_logic := '1';
    signal uart_tx_line : std_logic;
    signal led_busy     : std_logic;
    signal led_done     : std_logic;
    
    signal sim_finished : boolean := false;

    constant CLK_PERIOD  : time := 20 ns;
    constant BAUD_PERIOD : time := 104167 ns; -- 9600 Baud

    -- Helper Function to convert Fixed Point to Real
    function to_real(slv : std_logic_vector) return real is
    begin
        return real(to_integer(unsigned(slv))) / 1048576.0;
    end function;

begin

    uut: square_root port map (
        clk => clk, reset => reset, uart_rx_line => uart_rx_line, 
        uart_tx_line => uart_tx_line, led_busy => led_busy, led_done => led_done
    );

    -- Clock Generation
    clk_process :process
    begin
        while not sim_finished loop
            clk <= '0'; wait for CLK_PERIOD/2;
            clk <= '1'; wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    -- =========================================================
    -- PROCESS 1: MONITOR (The Spy)
    -- =========================================================
    monitor_proc: process
        -- [[ CRITICAL ]] Must match your Control Unit range (0 to 31)
        subtype t_iter_range is integer range 0 to 65;
        
        alias spy_iter     is << signal uut.inst_control.iter_count : t_iter_range >>;
        alias spy_xn       is << signal uut.inst_reg_xn.d_out : std_logic_vector(61 downto 0) >>;
        alias spy_quotient is << signal uut.inst_nr_block.quotient_result : std_logic_vector(61 downto 0) >>;

        variable last_iter : integer := -99;
    begin
        wait until rising_edge(clk);
        
        -- Print strictly on CHANGE
        if spy_iter /= last_iter then
            
            -- Skip the '0' idle state to keep logs clean (optional)
            if spy_iter >= 0 then 
                report " Iter: " & integer'image(spy_iter) & 
                       " | Xn: " & real'image(to_real(spy_xn)) & 
                       " | Div: " & real'image(to_real(spy_quotient));
            end if;
            
            last_iter := spy_iter;
        end if;
        
        if sim_finished then wait; end if;
    end process;

    -- =========================================================
    -- PROCESS 2: STIMULUS (The Driver)
    -- =========================================================
    stim_proc: process
        procedure UART_SEND_STR(s : string) is
        begin
            for i in s'range loop
                uart_rx_line <= '0'; wait for BAUD_PERIOD; 
                for b in 0 to 7 loop
                    uart_rx_line <= std_logic(to_unsigned(character'pos(s(i)), 8)(b));
                    wait for BAUD_PERIOD;
                end loop;
                uart_rx_line <= '1'; wait for BAUD_PERIOD; 
            end loop;
            -- Send Enter (0x0A)
            uart_rx_line <= '0'; wait for BAUD_PERIOD;
            for b in 0 to 7 loop
                uart_rx_line <= std_logic(to_unsigned(10, 8)(b));
                wait for BAUD_PERIOD;
            end loop;
            uart_rx_line <= '1'; wait for BAUD_PERIOD;
        end procedure;

    begin
        reset <= '0'; wait for 100 ns; 
        reset <= '1'; wait for 100 ns;

        report "======================================================" severity note;
        report "       DEBUGGER: 32-ITERATION SAFE MODE               " severity note;
        report "======================================================" severity note;

        -- TEST 1: 100 (Exp: 10.0)
        report "--- TEST 1: Input '100' ---" severity note;
        UART_SEND_STR("100");
        wait for 5 ms; 

        -- TEST 2: 1024 (Exp: 32.0)
        report "--- TEST 2: Input '1024' ---" severity note;
        UART_SEND_STR("1024");
        wait for 5 ms;
        
        -- TEST 3: 12345 (Exp: 111.108)
        report "--- TEST 3: Input '12345' ---" severity note;
        UART_SEND_STR("12345");
        wait for 5 ms;

        sim_finished <= true;
        report "=== DEBUG FINISHED ===" severity note;
        wait;
    end process;

end behavior;