library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_adder_shifter is
-- Testbench has no ports
end tb_adder_shifter;

architecture Behavioral of tb_adder_shifter is

    component adder_shifter is
        Port (
            xn_in       : in  std_logic_vector(61 downto 0);
            quotient_in : in  std_logic_vector(61 downto 0);
            xn_out      : out std_logic_vector(61 downto 0)
        );
    end component;

    -- SIGNALS
    signal xn_in       : std_logic_vector(61 downto 0) := (others => '0');
    signal quotient_in : std_logic_vector(61 downto 0) := (others => '0');
    signal xn_out      : std_logic_vector(61 downto 0);

begin

    uut: adder_shifter
        Port map (
            xn_in       => xn_in,
            quotient_in => quotient_in,
            xn_out      => xn_out
        );

    process
        -- Procedure for easy checking
        procedure check_add(
            constant a_hex      : in std_logic_vector(61 downto 0); 
            constant b_hex      : in std_logic_vector(61 downto 0); 
            constant res_hex    : in std_logic_vector(61 downto 0); 
            constant test_name  : in string
        ) is
        begin
            xn_in       <= a_hex;
            quotient_in <= b_hex;
            
            wait for 10 ns; -- Combinational delay
            
            if xn_out = res_hex then
                report "[PASS] " & test_name severity note;
            else
                report "[FAIL] " & test_name & 
                       " | Expected: " & to_hstring(res_hex) & 
                       " | Got: " & to_hstring(xn_out) severity error;
            end if;
            
            wait for 10 ns;
        end procedure;

    begin
        wait for 50 ns;

        ------------------------------------------------------------
        -- TEST VECTORS
        -- Note: Manual padding "00" & x"..." ensures 62 bits
        ------------------------------------------------------------

        -- CASE 1: 2.0 + 2.0 = 4.0 / 2 = 2.0
        check_add("00" & x"000000000" & x"200000", 
                  "00" & x"000000000" & x"200000", 
                  "00" & x"000000000" & x"200000", 
                  "Test 1: 2.0 + 2.0");

        -- CASE 2: 10.0 + 2.0 = 12.0 / 2 = 6.0
        check_add("00" & x"000000000" & x"A00000", 
                  "00" & x"000000000" & x"200000", 
                  "00" & x"000000000" & x"600000", 
                  "Test 2: 10.0 + 2.0");

        -- CASE 3: 0 + 0 = 0
        check_add((others => '0'), (others => '0'), (others => '0'), 
                  "Test 3: Zeroes");

        -- CASE 4: Odd Number Truncation check
        -- Input A: ...100001 (Ends in 1)
        -- Input B: ...100000 (Ends in 0)
        -- Sum: ...200001
        -- Result / 2: ...100000 (The LSB '1' is lost)
        check_add("00" & x"000000000" & x"100001", 
                  "00" & x"000000000" & x"100000", 
                  "00" & x"000000000" & x"100000", 
                  "Test 4: Odd Sum Truncation");

        -- CASE 5: Max Value Check (Carry Handling)
        -- Max (All 1s) + Max (All 1s) = Result with carry
        -- Shift Right brings the carry back in. Result should be Max.
        check_add((others => '1'), (others => '1'), (others => '1'), 
                  "Test 5: Max Values");

        -- CASE 6: 1.0 + 3.0 = 4.0 / 2 = 2.0
        check_add("00" & x"000000000" & x"100000", 
                  "00" & x"000000000" & x"300000", 
                  "00" & x"000000000" & x"200000", 
                  "Test 6: 1.0 + 3.0");

        -- CASE 7: Small Numbers
        -- 2 + 4 = 6. Divide by 2 = 3.
        check_add(std_logic_vector(to_unsigned(2, 62)), 
                  std_logic_vector(to_unsigned(4, 62)), 
                  std_logic_vector(to_unsigned(3, 62)), 
                  "Test 7: Small Integers");

        report "Adder Tests Completed." severity failure;
        wait;
    end process;

end Behavioral;