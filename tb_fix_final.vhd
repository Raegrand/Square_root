library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_fix_final is
    -- No ports
end tb_fix_final;

architecture Behavioral of tb_fix_final is

    -- 1. Component Declaration
    component square_root
        Port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            uart_rx_line : in  std_logic;
            uart_tx_line : out std_logic;
            led_busy     : out std_logic;
            led_done     : out std_logic
        );
    end component;

    -- 2. Signals
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    signal uart_rx_line : std_logic := '1'; -- Idle High
    signal uart_tx_line : std_logic;
    signal led_busy     : std_logic;
    signal led_done     : std_logic;

    -- 3. Constants
    constant CLK_PERIOD : time := 20 ns;     -- 50 MHz
    constant BIT_PERIOD : time := 104167 ns; -- 9600 Baud (1/9600)
    
    -- Safety Buffer: Wait for this long after TX goes silent
    constant INTER_INPUT_DELAY : time := 20 ms; 

begin

    -- 4. Instantiate the System
    uut: square_root
        port map (
            clk          => clk,
            reset        => reset,
            uart_rx_line => uart_rx_line,
            uart_tx_line => uart_tx_line,
            led_busy     => led_busy,
            led_done     => led_done
        );

    -- 5. Clock Generation
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- 6. Stimulus Process
    stim_proc: process
        
        -- Helper: Send Byte
        procedure UART_SEND_BYTE(data_in : in std_logic_vector(7 downto 0)) is
        begin
            -- Start Bit
            uart_rx_line <= '0';
            wait for BIT_PERIOD;
            -- Data Bits
            for i in 0 to 7 loop
                uart_rx_line <= data_in(i);
                wait for BIT_PERIOD;
            end loop;
            -- Stop Bit
            uart_rx_line <= '1';
            wait for BIT_PERIOD;
            wait for BIT_PERIOD; -- Small inter-char delay
        end procedure;

        -- Helper: Send String
        procedure SEND_STRING(s : string) is
            variable char_byte : std_logic_vector(7 downto 0);
        begin
            for i in s'range loop
                char_byte := std_logic_vector(to_unsigned(character'pos(s(i)), 8));
                UART_SEND_BYTE(char_byte);
            end loop;
            UART_SEND_BYTE(x"0A"); -- Send 'Enter' to start
        end procedure;

    begin
        -- Initial Reset
        reset <= '0';
        wait for 100 ns;
        reset <= '1';
        wait for 100 ns;

        ------------------------------------------------------------
        -- TEST LOOP: Send 10 numbers safely
        ------------------------------------------------------------
        
        report "Starting Test Sequence...";

        -- 1. Input: 4
        SEND_STRING("4");
        wait until led_done = '1';
        report "Calculation 1 Done. Waiting for UART TX...";
        wait for INTER_INPUT_DELAY; 
        
        -- 2. Input: 9
        SEND_STRING("9");
        wait until led_done = '1';
        report "Calculation 2 Done. Waiting for UART TX...";
        wait for INTER_INPUT_DELAY;

        -- 3. Input: 16
        SEND_STRING("16");
        wait until led_done = '1';
        report "Calculation 3 Done. Waiting for UART TX...";
        wait for INTER_INPUT_DELAY;

        -- 4. Input: 25
        SEND_STRING("25");
        wait until led_done = '1';
        report "Calculation 4 Done. Waiting for UART TX...";
        wait for INTER_INPUT_DELAY;

        -- 5. Input: 36
        SEND_STRING("36");
        wait until led_done = '1';
        report "Calculation 5 Done. Waiting for UART TX...";
        wait for INTER_INPUT_DELAY;

        -- 6. Input: 49
        SEND_STRING("49");
        wait until led_done = '1';
        report "Calculation 6 Done. Waiting for UART TX...";
        wait for INTER_INPUT_DELAY;

        -- 7. Input: 64
        SEND_STRING("64");
        wait until led_done = '1';
        report "Calculation 7 Done. Waiting for UART TX...";
        wait for INTER_INPUT_DELAY;

        -- 8. Input: 81
        SEND_STRING("81");
        wait until led_done = '1';
        report "Calculation 8 Done. Waiting for UART TX...";
        wait for INTER_INPUT_DELAY;

        -- 9. Input: 100
        SEND_STRING("100");
        wait until led_done = '1';
        report "Calculation 9 Done. Waiting for UART TX...";
        wait for INTER_INPUT_DELAY;

        -- 10. Input: 144
        SEND_STRING("144");
        wait until led_done = '1';
        report "Calculation 10 Done. Waiting for UART TX...";
        wait for INTER_INPUT_DELAY;

        report "===================================";
        report "SUCCESS: All 10 inputs processed.";
        report "===================================";
        wait;
    end process;

end Behavioral;