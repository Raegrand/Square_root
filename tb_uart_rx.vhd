library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_rx is
-- No ports
end tb_uart_rx;

architecture behavior of tb_uart_rx is

    -- COMPONENT DECLARATION
    component uart_rx is
        port (
            clk         : in  std_logic;
            rx_line     : in  std_logic;
            data_out_32 : out std_logic_vector(31 downto 0);
            data_valid  : out std_logic
        );
    end component;

    -- SIGNALS
    signal clk         : std_logic := '0';
    signal rx_line     : std_logic := '1'; -- Idle state is High
    signal data_out_32 : std_logic_vector(31 downto 0);
    signal data_valid  : std_logic;

    -- TIMING CONSTANTS (50MHz Clock, 9600 Baud)
    constant CLK_PERIOD : time := 20 ns;
    constant BIT_PERIOD : time := 5208 * CLK_PERIOD; -- Approx 104.16 us

begin

    -- INSTANTIATION
    uut: uart_rx
        port map (
            clk         => clk,
            rx_line     => rx_line,
            data_out_32 => data_out_32,
            data_valid  => data_valid
        );

    -- CLOCK PROCESS
    process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- STIMULUS PROCESS
    process
        -- Helper Procedure to simulate UART Serial Transmission
        procedure send_byte(data_in : in std_logic_vector(7 downto 0)) is
        begin
            -- 1. Start Bit (Low)
            rx_line <= '0';
            wait for BIT_PERIOD;

            -- 2. Data Bits (LSB First)
            for i in 0 to 7 loop
                rx_line <= data_in(i);
                wait for BIT_PERIOD;
            end loop;

            -- 3. Stop Bit (High)
            rx_line <= '1';
            wait for BIT_PERIOD;
            
            -- Small gap between bytes
            wait for BIT_PERIOD; 
        end procedure;

    begin
        wait for 100 ns;

        ------------------------------------------------------------
        -- TEST SEQUENCE: Send 0x12345678
        ------------------------------------------------------------
        
        report "Step 1: Sending Byte 0x12 (MSB)..." severity note;
        send_byte(x"12");

        report "Step 2: Sending Byte 0x34..." severity note;
        send_byte(x"34");

        report "Step 3: Sending Byte 0x56..." severity note;
        send_byte(x"56");

        report "Step 4: Sending Byte 0x78 (LSB)..." severity note;
        send_byte(x"78");

        -- Wait for internal processing to latch valid signal
        wait for 100 ns;

        -- CHECK RESULT
        if data_out_32 = x"12345678" and data_valid = '1' then
            report "[PASS] Successfully received 32-bit Integer: 0x12345678" severity note;
        else
            report "[FAIL] Expected 0x12345678, Got: " & to_hstring(data_out_32) severity error;
        end if;

        report "Simulation Completed." severity failure;
        wait;
    end process;

end behavior;