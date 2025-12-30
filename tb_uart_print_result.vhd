library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_uart_print_result is
end tb_uart_print_result;

architecture behavior of tb_uart_print_result is

    -- 1. DUT Declaration
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

    constant CLK_PERIOD   : time := 20 ns;
    constant BAUD_PERIOD  : time := 104167 ns;

begin

    uut: square_root port map (
        clk => clk, reset => reset, uart_rx_line => uart_rx_line, 
        uart_tx_line => uart_tx_line, led_busy => led_busy, led_done => led_done
    );

    clk_process :process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    stim_proc: process
        variable v_received_bytes : std_logic_vector(39 downto 0);
        variable v_temp_byte      : std_logic_vector(7 downto 0);
        variable v_timeout        : boolean;

        -- [[ 1. SPY SIGNAL ]] Access the internal iteration counter
        subtype t_iter_range is integer range 0 to 65;
        alias spy_iter_count is << signal uut.inst_control.iter_count : t_iter_range >>;
        
        procedure UART_SEND_BYTE(data_byte : in std_logic_vector(7 downto 0)) is
        begin
            uart_rx_line <= '0'; wait for BAUD_PERIOD; 
            for i in 0 to 7 loop
                uart_rx_line <= data_byte(i); wait for BAUD_PERIOD;
            end loop;
            uart_rx_line <= '1'; wait for BAUD_PERIOD; 
        end procedure;

        procedure UART_RECEIVE_BYTE(
            variable byte_out : out std_logic_vector(7 downto 0);
            variable timeout  : out boolean
        ) is
            variable t_start : time;
        begin
            timeout := false; t_start := now;
            while uart_tx_line = '1' loop
                if (now - t_start) > 50 ms then timeout := true; byte_out := (others => '0'); return; end if;
                wait for 1 us;
            end loop;
            wait for BAUD_PERIOD + (BAUD_PERIOD / 2); 
            for i in 0 to 7 loop
                byte_out(i) := uart_tx_line; if i < 7 then wait for BAUD_PERIOD; end if;
            end loop;
            wait for BAUD_PERIOD; 
        end procedure;

        function slv_to_hex(val : std_logic_vector) return string is
            variable l : line;
        begin
            hwrite(l, val); return l.all;
        end function;

        procedure CHECK_UART_SQRT(input_hex : std_logic_vector(31 downto 0)) is
            variable v_uns_input : unsigned(31 downto 0);
            variable v_digit     : integer;
            variable v_str_len   : integer := 0;
            type char_array is array(0 to 10) of std_logic_vector(7 downto 0);
            variable v_ascii_digits : char_array;
            variable v_final_result : std_logic_vector(35 downto 0);
            
            variable val_s_real     : real;
            variable val_out_real   : real;
            variable val_exp_real   : real;
            variable val_error      : real;
            variable int_part       : integer;
            variable frac_part      : integer;
            variable captured_iters : integer; -- Variable to store count
        begin
            v_uns_input := unsigned(input_hex);
            val_s_real  := real(to_integer(v_uns_input));
            val_exp_real := sqrt(val_s_real);

            v_str_len := 0;
            if v_uns_input = 0 then
                v_ascii_digits(0) := x"30"; v_str_len := 1;
            else
                while v_uns_input > 0 loop
                    v_digit := to_integer(v_uns_input mod 10);
                    v_ascii_digits(v_str_len) := std_logic_vector(to_unsigned(v_digit + 48, 8));
                    v_uns_input := v_uns_input / 10; v_str_len := v_str_len + 1;
                end loop;
            end if;

            for i in v_str_len - 1 downto 0 loop
                UART_SEND_BYTE(v_ascii_digits(i)); wait for 50 us; 
            end loop;
            UART_SEND_BYTE(x"0A"); 

            for i in 4 downto 0 loop
                UART_RECEIVE_BYTE(v_temp_byte, v_timeout);
                if v_timeout then report "!!! TIMEOUT !!!" severity error; return; end if;
                v_received_bytes( (i*8)+7 downto (i*8) ) := v_temp_byte;
            end loop;
            
            -- [[ 2. CAPTURE COUNT ]] 
            captured_iters := integer(spy_iter_count);

            v_final_result := v_received_bytes(35 downto 0);
            int_part  := to_integer(unsigned(v_final_result(35 downto 20)));
            frac_part := to_integer(unsigned(v_final_result(19 downto 0)));
            val_out_real := real(int_part) + (real(frac_part) / 1048576.0);
            val_error := abs(val_out_real - val_exp_real);

            -- [[ 3. PRINT WITH ITER COUNT ]]
            report "| " & integer'image(to_integer(unsigned(input_hex))) & 
                   " | " & slv_to_hex(v_final_result) & 
                   " | " & real'image(val_out_real) & 
                   " | " & real'image(val_exp_real) & 
                   " | " & real'image(val_error) &
                   " | " & integer'image(captured_iters) severity note;
            
            wait for 200 us; 
        end procedure;

    begin
        reset <= '0'; wait for 100 ns; reset <= '1'; wait for 100 ns;

        report "==================================================================================================================" severity note;
        report "| Input S | Hex Output (Q16.20) | Decimal Output | Expected Output | Error Rate (Abs) | Iter Count |" severity note;
        report "==================================================================================================================" severity note;

        CHECK_UART_SQRT(x"00000000"); 
        CHECK_UART_SQRT(x"00000001"); 
        CHECK_UART_SQRT(x"00000002"); 
        CHECK_UART_SQRT(x"00000003"); 
        CHECK_UART_SQRT(x"00000004"); 
        CHECK_UART_SQRT(x"00000005"); 
        CHECK_UART_SQRT(x"0000000A"); 
        CHECK_UART_SQRT(x"00000010"); 
        CHECK_UART_SQRT(x"00000064"); 
        CHECK_UART_SQRT(x"00000100"); 
        CHECK_UART_SQRT(x"00000400"); 
        CHECK_UART_SQRT(x"00003039"); 
        CHECK_UART_SQRT(x"0000C350"); 
        CHECK_UART_SQRT(x"00010000"); 
        CHECK_UART_SQRT(x"000F4240"); 
        CHECK_UART_SQRT(x"075BCD15"); 
        CHECK_UART_SQRT(x"7FFFF010"); 

        report "==================================================================================================================" severity note;
        report "TEST COMPLETED" severity note;
        wait;
    end process;

end behavior;