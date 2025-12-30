-- tb_nr_block.vhd  (fixed)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_nr_block is
end tb_nr_block;

architecture sim of tb_nr_block is

    -- Component under test
    component nr_block
        Port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            start       : in  std_logic;
            dividend_S  : in  std_logic_vector(31 downto 0);
            xn_current  : in  std_logic_vector(61 downto 0); -- Q42.20
            xn_next     : out std_logic_vector(61 downto 0);
            nr_done     : out std_logic
        );
    end component;

    signal clk        : std_logic := '0';
    signal reset      : std_logic := '1'; -- keep reset high for normal operation
    signal start      : std_logic := '0';
    signal dividend_S : std_logic_vector(31 downto 0) := (others => '0');
    signal xn_current : std_logic_vector(61 downto 0) := (others => '0');
    signal xn_next    : std_logic_vector(61 downto 0);
    signal nr_done    : std_logic;

    constant PERIOD : time := 20 ns; -- 50 MHz clock

begin

    -- instantiate DUT
    DUT: nr_block
        port map (
            clk => clk,
            reset => reset,
            start => start,
            dividend_S => dividend_S,
            xn_current => xn_current,
            xn_next => xn_next,
            nr_done => nr_done
        );

    -- clock generation
    clk_proc : process
    begin
        while now < 5 ms loop
            clk <= '0'; wait for PERIOD/2;
            clk <= '1'; wait for PERIOD/2;
        end loop;
        wait;
    end process;

    stim_proc : process
        variable cycles_waited : integer := 0;
        constant TIMEOUT_CYCLES : integer := 5000; -- fail if not done in this many clocks
    begin
        -- apply reset (active low pulse)
        reset <= '0'; wait for 2 * PERIOD; -- assert reset (active low)
        reset <= '1'; wait for 4 * PERIOD; -- release reset

        -- set test vectors:
        dividend_S <= x"00000004";  -- S = 4 decimal (example)

        -- Example initial guess xn_current = 1.0 in Q42.20 -> 1 << 20
        xn_current <= std_logic_vector(to_unsigned(1 * 2**20, xn_current'length));

        -- pulse start for 1 clock
        start <= '1'; wait for PERIOD; start <= '0';

        -- wait for nr_done with timeout (counting clock edges)
        cycles_waited := 0;
        wait until rising_edge(clk);
        while nr_done = '0' and cycles_waited < TIMEOUT_CYCLES loop
            cycles_waited := cycles_waited + 1;
            wait until rising_edge(clk);
        end loop;

        if nr_done = '1' then
            report "nr_block: FINISHED normally after " & integer'image(cycles_waited) & " clock cycles" severity note;
            -- print a small diagnostic sample of xn_next (upper 32 bits as integer)
            report "xn_next(61 downto 30) as integer = " &
                   integer'image(to_integer(unsigned(xn_next(61 downto 30)))) severity note;
        else
            assert false report "ERROR: nr_block did NOT assert nr_done within timeout (" &
                                 integer'image(TIMEOUT_CYCLES) & " cycles)" severity failure;
        end if;

        wait for 100 * PERIOD;
        assert false report "End of simulation" severity note;
        wait;
    end process;

end sim;
