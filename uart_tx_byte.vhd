library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx_byte is
    port (
        i_CLOCK : in  std_logic;
        i_START : in  std_logic;
        i_DATA  : in  std_logic_vector(7 downto 0);
        o_BUSY  : out std_logic;
        o_TX    : out std_logic := '1'
    );
end uart_tx_byte;

architecture behavior of uart_tx_byte is
    -- 50MHz / 9600 baud = 5208 ticks
    constant PRESCALER_MAX : integer := 5207;
    
    signal r_PRESCALER   : integer range 0 to PRESCALER_MAX := 0;
    signal r_INDEX       : integer range 0 to 9 := 0;
    signal r_DATA_BUFFER : std_logic_vector(9 downto 0) := (others => '1');
    signal s_TX_FLAG     : std_logic := '0';

begin
    process(i_CLOCK)
    begin
        if rising_edge(i_CLOCK) then
            
            -- START CONDITION
            if s_TX_FLAG = '0' and i_START = '1' then
                r_DATA_BUFFER(0) <= '0';          -- Start Bit
                r_DATA_BUFFER(9) <= '1';          -- Stop Bit
                r_DATA_BUFFER(8 downto 1) <= i_DATA;
                
                s_TX_FLAG <= '1';	 
                o_BUSY    <= '1';
                
                -- Update Output IMMEDIATELY (Start Bit)
                o_TX      <= '0'; 
                
                r_PRESCALER <= 0;
                r_INDEX     <= 0;
            end if;

            -- TRANSMISSION LOOP
            if s_TX_FLAG = '1' then
                if r_PRESCALER < PRESCALER_MAX then
                    r_PRESCALER <= r_PRESCALER + 1;
                else
                    r_PRESCALER <= 0;
                    
                    -- Update Output at the START of the new bit period
                    if r_INDEX < 9 then
                        r_INDEX <= r_INDEX + 1;
                        o_TX    <= r_DATA_BUFFER(r_INDEX + 1); -- Shift to next bit
                    else
                        -- Finish
                        s_TX_FLAG <= '0';
                        o_BUSY    <= '0';
                        o_TX      <= '1'; -- Return to Idle
                    end if;
                end if;
            end if;
            
        end if;
    end process;
end behavior;