library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_tx is
-- No ports
end tb_uart_tx;

architecture behavior of tb_uart_tx is

    -- COMPONENT DECLARATION
    component uart_tx is
        port (
            clk         : in  std_logic;
            start       : in  std_logic;
            data_in_36  : in  std_logic_vector(35 downto 0);
            tx_line     : out std_logic;
            busy        : out std_logic
        );
    end component;

    -- SIGNALS
    signal clk        : std_logic := '0';
    signal start      : std_logic := '0';
    signal data_in_36 : std_logic_vector(35 downto 0) := (others => '0');
    signal tx_line    : std_logic;
    signal busy       : std_logic;

    -- TIMING CONSTANTS (50MHz Clock, 9600 Baud)
    constant CLK_PERIOD : time := 20 ns;
    constant BIT_PERIOD : time := 5208 * CLK_PERIOD; -- Approx 104.16 us

begin

    -- INSTANTIATION
    uut: uart_tx
        port map (
            clk        => clk,
            start      => start,
            data_in_36 => data_in_36,
            tx_line    => tx_line,
            busy       => busy
        );

    -- CLOCK PROCESS
    process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- VERIFICATION PROCESS
    process
        -- Helper procedure to "Receive" a byte from the serial line
        procedure check_serial_byte(expected : in std_logic_vector(7 downto 0)) is
            variable received_byte : std_logic_vector(7 downto 0);
        begin
            -- 1. Wait for Start Bit (Falling Edge on tx_line)
            wait until tx_line = '0';
            
            -- 2. Align to Middle of Start Bit
            wait for BIT_PERIOD / 2;
            
            -- 3. Move to Middle of Bit 0 (First Data Bit)
            wait for BIT_PERIOD;

            -- 4. Sample 8 Data Bits
            for i in 0 to 7 loop
                received_byte(i) := tx_line;
                wait for BIT_PERIOD;
            end loop;

            -- 5. Check Stop Bit
            if tx_line /= '1' then
                report "[FAIL] Framing Error! Stop bit was not '1'" severity error;
            end if;

            -- 6. Verify Content
            if received_byte = expected then
                report "[PASS] Received Byte: " & to_hstring(expected) severity note;
            else
                report "[FAIL] Expected: " & to_hstring(expected) & ", Got: " & to_hstring(received_byte) severity error;
            end if;
        end procedure;

    begin
        -- Initial Setup
        wait for 100 ns;

        -- 1. Apply Input Data: 0x1_2345_6789 (36 bits)
        -- Constructed as: Top nibble '1' & 32-bit word '23456789'
        data_in_36 <= x"1" & x"23456789";
        
        -- 2. Trigger Transmission
        wait until falling_edge(clk);
        start <= '1';
        wait until falling_edge(clk);
        start <= '0';

        -- 3. Verify Serial Stream (5 Bytes sequentially)
        report "Checking Byte 1 (0x01)..." severity note;
        check_serial_byte(x"01"); -- Padded top nibble

        report "Checking Byte 2 (0x23)..." severity note;
        check_serial_byte(x"23");

        report "Checking Byte 3 (0x45)..." severity note;
        check_serial_byte(x"45");

        report "Checking Byte 4 (0x67)..." severity note;
        check_serial_byte(x"67");

        report "Checking Byte 5 (0x89)..." severity note;
        check_serial_byte(x"89");

        -- 4. Check if BUSY goes low
        wait for 1 us;
        if busy = '0' then
            report "[PASS] Transmitter returned to IDLE (Busy=0)" severity note;
        else
            report "[FAIL] Transmitter stuck busy" severity error;
        end if;

        report "Simulation Completed." severity failure;
        wait;
    end process;

end behavior;