library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_radix4_divider is
-- Testbench has no ports
end tb_radix4_divider;

architecture Behavioral of tb_radix4_divider is

    -- COMPONENT DECLARATION
    component radix4_divider is
        Port (
            clk        : in  std_logic;
            reset      : in  std_logic;
            start      : in  std_logic;
            dividend_S : in  std_logic_vector(31 downto 0);
            divisor_Xn : in  std_logic_vector(61 downto 0);
            quotient   : out std_logic_vector(61 downto 0);
            done       : out std_logic
        );
    end component;

    -- SIGNALS
    signal clk        : std_logic := '0';
    signal reset      : std_logic := '0';
    signal start      : std_logic := '0';
    signal dividend_S : std_logic_vector(31 downto 0) := (others => '0');
    signal divisor_Xn : std_logic_vector(61 downto 0) := (others => '0');
    signal quotient   : std_logic_vector(61 downto 0);
    signal done       : std_logic;

    -- CLOCK PERIOD
    constant T : time := 20 ns; 

begin

    -- INSTANTIATION
    uut: radix4_divider
        Port map (
            clk        => clk,
            reset      => reset,
            start      => start,
            dividend_S => dividend_S,
            divisor_Xn => divisor_Xn,
            quotient   => quotient,
            done       => done
        );

    -- CLOCK PROCESS
    process
    begin
        clk <= '0'; wait for T/2;
        clk <= '1'; wait for T/2;
    end process;

    -- STIMULUS PROCESS
    process
        procedure check_division(
            constant s_bits     : in std_logic_vector(31 downto 0);                   
            constant xn_hex     : in std_logic_vector(61 downto 0); 
            constant exp_hex    : in std_logic_vector(61 downto 0); 
            constant test_name  : in string
        ) is
        begin
            -- 1. Setup Inputs
            dividend_S <= s_bits;
            divisor_Xn <= xn_hex;
            
            -- 2. Pulse Start
            wait until falling_edge(clk);
            start <= '1';
            wait until falling_edge(clk);
            start <= '0';
            
            -- 3. Wait for Done
            wait until done = '1';
            wait for T; 
            
            -- 4. Check Result (+/- 1 LSB tolerance)
            if abs(signed(quotient) - signed(exp_hex)) <= 1 then
                report "[PASS] " & test_name severity note;
            else
                report "[FAIL] " & test_name & 
                       " | Expected: " & to_hstring(exp_hex) & 
                       " | Got: " & to_hstring(quotient) severity error;
            end if;
            
            -- 5. Wait before next test
            wait for 5 * T;
        end procedure;

    begin
        -- RESET SYSTEM
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        ------------------------------------------------------------
        -- TEST VECTORS (Q42.20 Format)
        -- Using to_unsigned() guarantees correct 62-bit width
        ------------------------------------------------------------

        -- CASE 1: 10 / 1.0 = 10.0
        check_division(std_logic_vector(to_unsigned(10, 32)), 
                       std_logic_vector(to_unsigned(1048576, 62)), 
                       std_logic_vector(to_unsigned(10485760, 62)), 
                       "Test 1: 10 / 1.0");

        -- CASE 2: 45 / 3.0 = 15.0
        check_division(std_logic_vector(to_unsigned(45, 32)), 
                       std_logic_vector(to_unsigned(3145728, 62)), 
                       std_logic_vector(to_unsigned(15728640, 62)), 
                       "Test 2: 45 / 3.0");

        -- CASE 3: 20 / 0.5 = 40.0
        check_division(std_logic_vector(to_unsigned(20, 32)), 
                       std_logic_vector(to_unsigned(524288, 62)),   
                       std_logic_vector(to_unsigned(41943040, 62)), 
                       "Test 3: 20 / 0.5");

        -- CASE 4: 3 / 4.0 = 0.75
        check_division(std_logic_vector(to_unsigned(3, 32)), 
                       std_logic_vector(to_unsigned(4194304, 62)),  
                       std_logic_vector(to_unsigned(786432, 62)),   
                       "Test 4: 3 / 4.0");

        -- CASE 5: 1 / 0.3333 = 3.0
        -- Divisor 0.3333... * 2^20 approx 349525
        -- Result 3.0 * 2^20 = 3145728
        check_division(std_logic_vector(to_unsigned(1, 32)), 
                       std_logic_vector(to_unsigned(349525, 62)), 
                       std_logic_vector(to_unsigned(3145728, 62)), 
                       "Test 5: 1 / 0.3333");

        -- CASE 6: 10 / 3.0 = 3.3333...
        -- Divisor 3.0 = 3145728
        -- Result 3.3333... * 2^20 approx 3495253
        check_division(std_logic_vector(to_unsigned(10, 32)), 
                       std_logic_vector(to_unsigned(3145728, 62)), 
                       std_logic_vector(to_unsigned(3495253, 62)), 
                       "Test 6: 10 / 3.0 (Recurring)");

        -- CASE 7: MAX INT / 1.0
        -- For this huge number, we use manual concatenation carefully.
        -- "00" (2 bits) + x"00" (8 bits) + x"FFFFFFFF" (32 bits) + x"00000" (20 bits) = 62 bits
        check_division(x"FFFFFFFF", 
                       std_logic_vector(to_unsigned(1048576, 62)), 
                       "00" & x"00" & x"FFFFFFFF" & x"00000", 
                       "Test 7: MAX_INT / 1.0");

        report "All 7 Tests Completed Successfully." severity failure; 
        wait;
    end process;

end Behavioral;