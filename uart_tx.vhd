library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    port (
        clk         : in  std_logic;
        start       : in  std_logic;
        data_in_36  : in  std_logic_vector(35 downto 0); -- Q16.20 Input
        tx_line     : out std_logic;
        busy        : out std_logic
    );
end uart_tx;

architecture behavior of uart_tx is

    component uart_tx_byte is
        port (
            i_CLOCK : in  std_logic;
            i_START : in  std_logic;
            i_DATA  : in  std_logic_vector(7 downto 0);
            o_BUSY  : out std_logic;
            o_TX    : out std_logic
        );
    end component;

    -- State Machine to send 5 Bytes sequentially
    type state_type is (IDLE, SEND_B1, WAIT_B1, SEND_B2, WAIT_B2, SEND_B3, WAIT_B3, SEND_B4, WAIT_B4, SEND_B5, WAIT_B5, FINISH);
    signal state : state_type := IDLE;

    signal tx_start_pulse : std_logic := '0';
    signal tx_data_byte   : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_busy_flag   : std_logic;
    signal r_data_latch   : std_logic_vector(35 downto 0) := (others => '0');

begin

    inst_tx_byte: uart_tx_byte
        port map (
            i_CLOCK => clk,
            i_START => tx_start_pulse,
            i_DATA  => tx_data_byte,
            o_BUSY  => tx_busy_flag,
            o_TX    => tx_line
        );

    process(clk)
    begin
        if rising_edge(clk) then
            
            tx_start_pulse <= '0'; -- Default low
            
            case state is
                when IDLE =>
                    busy <= '0';
                    if start = '1' then
                        r_data_latch <= data_in_36; -- Latch input
                        busy <= '1';
                        state <= SEND_B1;
                    end if;

                -- BYTE 1: Padding + Bits [35:32]
                when SEND_B1 =>
                    tx_data_byte <= "0000" & r_data_latch(35 downto 32);
                    tx_start_pulse <= '1';
                    state <= WAIT_B1;
                when WAIT_B1 =>
                    if tx_busy_flag = '0' and tx_start_pulse = '0' then state <= SEND_B2; end if;

                -- BYTE 2: Bits [31:24]
                when SEND_B2 =>
                    tx_data_byte <= r_data_latch(31 downto 24);
                    tx_start_pulse <= '1';
                    state <= WAIT_B2;
                when WAIT_B2 =>
                    if tx_busy_flag = '0' and tx_start_pulse = '0' then state <= SEND_B3; end if;

                -- BYTE 3: Bits [23:16]
                when SEND_B3 =>
                    tx_data_byte <= r_data_latch(23 downto 16);
                    tx_start_pulse <= '1';
                    state <= WAIT_B3;
                when WAIT_B3 =>
                    if tx_busy_flag = '0' and tx_start_pulse = '0' then state <= SEND_B4; end if;

                -- BYTE 4: Bits [15:8]
                when SEND_B4 =>
                    tx_data_byte <= r_data_latch(15 downto 8);
                    tx_start_pulse <= '1';
                    state <= WAIT_B4;
                when WAIT_B4 =>
                    if tx_busy_flag = '0' and tx_start_pulse = '0' then state <= SEND_B5; end if;

                -- BYTE 5: Bits [7:0]
                when SEND_B5 =>
                    tx_data_byte <= r_data_latch(7 downto 0);
                    tx_start_pulse <= '1';
                    state <= WAIT_B5;
                when WAIT_B5 =>
                    if tx_busy_flag = '0' and tx_start_pulse = '0' then state <= FINISH; end if;

                when FINISH =>
                    busy <= '0';
                    state <= IDLE;
                    
            end case;
        end if;
    end process;

end behavior;