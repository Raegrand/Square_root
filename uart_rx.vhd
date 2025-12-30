library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    port (
        clk         : in  std_logic;
        rx_line     : in  std_logic;
        
        -- Output 32-bit Integer
        data_out_32 : out std_logic_vector(31 downto 0);
        
        -- Valid Pulse (Fires when 'Enter' is detected)
        data_valid  : out std_logic
    );
end uart_rx;

architecture behavior of uart_rx is

    component uart_rx_byte is
        port (
            i_CLOCK         : in  std_logic;
            i_RX            : in  std_logic;
            o_DATA          : out std_logic_vector(7 downto 0);
            o_sig_CRRP_DATA : out std_logic;
            o_BUSY          : out std_logic
        );
    end component;

    signal s_rx_data    : std_logic_vector(7 downto 0);
    signal s_busy       : std_logic;
    signal s_busy_prev  : std_logic := '0';
    
    -- Accumulator to store the text number being typed
    signal r_accum      : unsigned(31 downto 0) := (others => '0');

begin

    inst_uart_byte: uart_rx_byte
        port map (
            i_CLOCK         => clk,
            i_RX            => rx_line,
            o_DATA          => s_rx_data,
            o_sig_CRRP_DATA => open,
            o_BUSY          => s_busy
        );

    process(clk)
    begin
        if rising_edge(clk) then
            
            data_valid <= '0';
            s_busy_prev <= s_busy;
            
            -- Detect Falling Edge of BUSY (New Byte Received)
            if s_busy_prev = '1' and s_busy = '0' then
                
                -- CASE 1: The byte is a DIGIT ('0' to '9')
                if unsigned(s_rx_data) >= 48 and unsigned(s_rx_data) <= 57 then
                    -- Math: New Value = (Old Value * 10) + (Digit - 48)
                    -- Example: "12" becomes "120" + "3" = 123
                    r_accum <= resize((r_accum * 10) + (unsigned(s_rx_data) - 48), 32);
                    
                -- CASE 2: The byte is a TERMINATOR (Enter / Line Feed)
                -- 0x0A = LF, 0x0D = CR, 0x20 = Space
                elsif s_rx_data = x"0A" or s_rx_data = x"0D" or s_rx_data = x"20" then
                    
                    data_out_32 <= std_logic_vector(r_accum);
                    data_valid  <= '1'; -- FIRE SIGNAL!
                    
                    -- Reset accumulator for the next number
                    r_accum <= (others => '0');
                end if;
            end if;
            
        end if;
    end process;

end behavior;