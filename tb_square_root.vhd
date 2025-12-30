library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_square_root is
-- No ports
end tb_square_root;

architecture behavior of tb_square_root is

    component square_root is
        Port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            uart_rx_line : in  std_logic;
            uart_tx_line : out std_logic;
            led_busy     : out std_logic;
            led_done     : out std_logic
        );
    end component;

    signal clk          : std_logic := '0';
    signal reset        : std_logic := '1'; -- Active Low (Default '1')
    signal uart_rx_line : std_logic := '1'; 
    signal uart_tx_line : std_logic;
    signal led_busy     : std_logic;
    signal led_done     : std_logic;

    constant CLK_PERIOD : time := 20 ns;
    constant BIT_PERIOD : time := 5208 * CLK_PERIOD; -- 104.16 us

begin

    uut: square_root
        port map (
            clk          => clk,
            reset        => reset,
            uart_rx_line => uart_rx_line, 
            uart_tx_line => uart_tx_line, 
            led_busy     => led_busy,
            led_done     => led_done
        );

    -- Clock Generation
    process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Stimulus Process
    process
        
        -- Send 32-bit Integer via UART
        procedure send_input_s(value : in std_logic_vector(31 downto 0)) is
            variable byte_to_send : std_logic_vector(7 downto 0);
        begin
            report ">> UART TX: Sending S = " & to_hstring(value) severity note;
            
            for b in 3 downto 0 loop
                byte_to_send := value((b*8)+7 downto b*8);
                uart_rx_line <= '0'; wait for BIT_PERIOD; -- Start
                for i in 0 to 7 loop
                    uart_rx_line <= byte_to_send(i); wait for BIT_PERIOD;
                end loop;
                uart_rx_line <= '1'; wait for BIT_PERIOD; -- Stop
                wait for BIT_PERIOD; 
            end loop;
        end procedure;

        -- Receive 36-bit Result via UART
        procedure check_output_result(expected_hex : in std_logic_vector(35 downto 0)) is
            variable received_frame : std_logic_vector(39 downto 0) := (others => '0');
            variable rx_byte        : std_logic_vector(7 downto 0);
            variable reconstructed  : std_logic_vector(35 downto 0);
        begin
            for b in 4 downto 0 loop
                wait until uart_tx_line = '0'; -- Wait for Start Bit
                wait for BIT_PERIOD/2;
                wait for BIT_PERIOD;
                for i in 0 to 7 loop
                    rx_byte(i) := uart_tx_line;
                    wait for BIT_PERIOD;
                end loop;
                received_frame((b*8)+7 downto b*8) := rx_byte;
                wait for BIT_PERIOD; 
            end loop;

            reconstructed(35 downto 32) := received_frame(35 downto 32); 
            reconstructed(31 downto 0)  := received_frame(31 downto 0);

            report "<< UART RX: Received Result = " & to_hstring(reconstructed);

            if reconstructed = expected_hex then
                report "[PASS] Result Matched Expected." severity note;
            else
                report "[FAIL] Mismatch! Expected: " & to_hstring(expected_hex) severity error;
            end if;
            report "------------------------------------------------" severity note;
        end procedure;

        -- PROCEDURE: Hard Reset the System
        procedure system_reset is
        begin
            report "Performing System Reset..." severity note;
            reset <= '0';         -- Hold Reset
            wait for 500 ns;      -- Hold long enough for all registers to clear
            reset <= '1';         -- Release Reset
            wait for 500 ns;      -- Wait for system to stabilize
        end procedure;

    begin
        wait for 100 ns;

        -- TEST 1: S = 16
        system_reset; -- <--- RESET HERE
        report "------------------------------------------------" severity note;
        send_input_s(x"00000010"); 
        check_output_result(x"000400000");

        -- TEST 2: S = 100
        wait for 10 us;
        system_reset; -- <--- RESET HERE
        send_input_s(x"00000064"); 
        check_output_result(x"000A00000");

        -- TEST 3: S = 2
        wait for 10 us;
        system_reset; -- <--- RESET HERE
        send_input_s(x"00000002"); 
        check_output_result(x"00016A09E"); 

        report "All Tests Completed." severity failure;
        wait;
    end process;

end behavior;