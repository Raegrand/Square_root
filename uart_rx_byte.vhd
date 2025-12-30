library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx_byte is
    port (
        i_CLOCK         : in  std_logic;
        i_RX            : in  std_logic;
        o_DATA          : out std_logic_vector(7 downto 0);
        o_sig_CRRP_DATA : out std_logic;
        o_BUSY          : out std_logic
    );
end uart_rx_byte;

architecture behavior of uart_rx_byte is

    -- 50MHz / 9600 baud = 5208 ticks
    constant PRESCALER_MAX : integer := 5207;
    constant PRESCALER_MID : integer := 2603;

    signal r_PRESCALER      : integer range 0 to PRESCALER_MAX := 0;
    signal r_INDEX          : integer range 0 to 9 := 0;
    signal r_DATA_BUFFER    : std_logic_vector(9 downto 0) := (others => '0');
    signal s_RECIEVING_FLAG : std_logic := '0';
    signal r_RECEIVED_BYTE  : std_logic_vector(7 downto 0) := (others => '0');

begin
    process(i_CLOCK)
    begin
        if rising_edge(i_CLOCK) then
            -- 1. Idle State
            if s_RECIEVING_FLAG = '0' then
                o_BUSY <= '0';
                o_sig_CRRP_DATA <= '0';
                
                if i_RX = '0' then 
                    s_RECIEVING_FLAG <= '1';
                    o_BUSY <= '1';
                    r_PRESCALER <= 0;
                    r_INDEX <= 0;
                end if;
            -- 2. Receiving State
            else
                if r_PRESCALER < PRESCALER_MAX then
                    r_PRESCALER <= r_PRESCALER + 1;
                else
                    r_PRESCALER <= 0;
                end if;

                if r_PRESCALER = PRESCALER_MID then
                    r_DATA_BUFFER(r_INDEX) <= i_RX;
                    
                    if r_INDEX < 9 then
                        r_INDEX <= r_INDEX + 1;
                    else
                        -- Finished
                        s_RECIEVING_FLAG <= '0';
                        o_BUSY <= '0';
                        
                        -- [[ CRITICAL FIX ]]
                        -- Check i_RX (live) for Stop Bit '1' AND Start Bit '0'
                        if r_DATA_BUFFER(0) = '0' and i_RX = '1' then
                            o_sig_CRRP_DATA <= '0';
                            r_RECEIVED_BYTE <= r_DATA_BUFFER(8 downto 1);
                        else
                            o_sig_CRRP_DATA <= '1'; -- Framing Error
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
    o_DATA <= r_RECEIVED_BYTE;
end behavior;