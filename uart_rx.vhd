library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        rx_line     : in  std_logic;
        data_out_32 : out std_logic_vector(31 downto 0);
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
            if reset = '0' then
                r_accum     <= (others => '0');
                data_valid  <= '0';
                s_busy_prev <= '0';
            else
                data_valid <= '0';
                s_busy_prev <= s_busy;
                
                if s_busy_prev = '1' and s_busy = '0' then
                    
                    if unsigned(s_rx_data) >= 48 and unsigned(s_rx_data) <= 57 then
                        r_accum <= resize((r_accum * 10) + (unsigned(s_rx_data) - 48), 32);
                        
                    elsif s_rx_data = x"0A" or s_rx_data = x"0D" or s_rx_data = x"20" then
                        data_out_32 <= std_logic_vector(r_accum);
                        data_valid  <= '1'; 
                        r_accum <= (others => '0');
                    end if;
                end if;
            end if; 
        end if;
    end process;

end behavior;