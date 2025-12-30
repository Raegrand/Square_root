library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_mux_2to1 is
-- No ports
end tb_mux_2to1;

architecture Behavioral of tb_mux_2to1 is

    component mux_2to1 is
        Port (
            in_A    : in  std_logic_vector(61 downto 0);
            in_B    : in  std_logic_vector(61 downto 0);
            sel     : in  std_logic;
            mux_out : out std_logic_vector(61 downto 0)
        );
    end component;

    -- SIGNALS
    signal in_A    : std_logic_vector(61 downto 0) := (others => '0');
    signal in_B    : std_logic_vector(61 downto 0) := (others => '0');
    signal sel     : std_logic := '0';
    signal mux_out : std_logic_vector(61 downto 0);

begin

    uut: mux_2to1
        Port map (
            in_A    => in_A,
            in_B    => in_B,
            sel     => sel,
            mux_out => mux_out
        );

    -- STIMULUS PROCESS
    process
        procedure check_mux(
            constant sel_val    : in std_logic;
            constant a_hex      : in std_logic_vector(61 downto 0);
            constant b_hex      : in std_logic_vector(61 downto 0);
            constant exp_hex    : in std_logic_vector(61 downto 0);
            constant test_name  : in string
        ) is
        begin
            sel   <= sel_val;
            in_A  <= a_hex;
            in_B  <= b_hex;
            
            wait for 10 ns; 
            
            if mux_out = exp_hex then
                report "[PASS] " & test_name severity note;
            else
                report "[FAIL] " & test_name severity error;
            end if;
            
            wait for 10 ns;
        end procedure;

    begin
        wait for 50 ns;

        -- CASE 1: Select A (Zero)
        check_mux('0', (others => '0'), (others => '1'), (others => '0'), 
                  "Test 1: Select 0 (Zeroes)");

        -- CASE 2: Select B (Ones)
        check_mux('1', (others => '0'), (others => '1'), (others => '1'), 
                  "Test 2: Select 1 (Ones)");

        -- CASE 3: Select A (Pattern A)
        -- FIXED: Used explicit Hex strings instead of (others => 'A')
        -- "00" + 15 Hex Digits (60 bits) = 62 bits
        check_mux('0', 
                  "00" & x"AAAAAAAAAAAAAAA", 
                  "00" & x"555555555555555", 
                  "00" & x"AAAAAAAAAAAAAAA", 
                  "Test 3: Select 0 (Pattern A)");

        -- CASE 4: Select B (Pattern 5)
        -- FIXED: Used explicit Hex strings
        check_mux('1', 
                  "00" & x"AAAAAAAAAAAAAAA", 
                  "00" & x"555555555555555", 
                  "00" & x"555555555555555", 
                  "Test 4: Select 1 (Pattern 5)");

        -- CASE 5: Random Data Ch A
        check_mux('0', 
                  "00" & x"000000000" & x"123456", 
                  "00" & x"000000000" & x"789ABC", 
                  "00" & x"000000000" & x"123456", 
                  "Test 5: Random Data Ch A");

        -- CASE 6: Random Data Ch B
        check_mux('1', 
                  "00" & x"000000000" & x"123456", 
                  "00" & x"000000000" & x"789ABC", 
                  "00" & x"000000000" & x"789ABC", 
                  "Test 6: Random Data Ch B");

        -- CASE 7: Real Values Select A
        check_mux('0', 
                  "00" & x"000000000" & x"100000", 
                  "00" & x"000000000" & x"200000", 
                  "00" & x"000000000" & x"100000", 
                  "Test 7: Real Values Select A");

        report "Mux Tests Completed." severity failure;
        wait;
    end process;

end Behavioral;