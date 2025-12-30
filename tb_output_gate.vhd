library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_output_gate is
-- No ports
end tb_output_gate;

architecture Behavioral of tb_output_gate is

    component output_gate is
        Port (
            data_in  : in  std_logic_vector(61 downto 0);
            out_en   : in  std_logic;
            data_out : out std_logic_vector(35 downto 0) -- 36 bits
        );
    end component;

    -- SIGNALS
    signal data_in  : std_logic_vector(61 downto 0) := (others => '0');
    signal out_en   : std_logic := '0';
    signal data_out : std_logic_vector(35 downto 0); 

begin

    uut: output_gate
        Port map (
            data_in  => data_in,
            out_en   => out_en,
            data_out => data_out
        );

    -- STIMULUS PROCESS
    process
        procedure check_gate(
            constant en_val     : in std_logic;
            constant in_hex     : in std_logic_vector(61 downto 0);
            constant exp_hex    : in std_logic_vector(35 downto 0);
            constant test_name  : in string
        ) is
        begin
            out_en  <= en_val;
            data_in <= in_hex;
            
            wait for 10 ns; 
            
            if data_out = exp_hex then
                report "[PASS] " & test_name severity note;
            else
                report "[FAIL] " & test_name severity error;
            end if;
            
            wait for 10 ns;
        end procedure;

    begin
        wait for 50 ns;

        -- CASE 1: Disabled (Input 1.0) -> Output 0
        check_gate('0', 
                   "00" & x"000000000" & x"100000", 
                   x"000000000", -- 9 Hex Digits
                   "Test 1: Disabled (Output 0)");

        -- CASE 2: Enabled Zero
        check_gate('1', 
                   (others => '0'), 
                   x"000000000", 
                   "Test 2: Enabled Zero");

        -- CASE 3: Enabled 1.0
        -- Input Q42.20 (1.0) = ...00100000
        -- Output Q16.20 (1.0) = 000100000
        check_gate('1', 
                   "00" & x"000000000" & x"100000", 
                   x"000100000", 
                   "Test 3: Pass 1.0");

        -- CASE 4: Enabled 2.0
        check_gate('1', 
                   "00" & x"000000000" & x"200000", 
                   x"000200000", 
                   "Test 4: Pass 2.0");

        -- CASE 5: Enabled 1.5
        check_gate('1', 
                   "00" & x"000000000" & x"180000", 
                   x"000180000", 
                   "Test 5: Pass 1.5");

        -- CASE 6: LSB Pass-through
        check_gate('1', 
                   "00" & x"000000000" & x"000001", 
                   x"000000001", 
                   "Test 6: LSB Pass-through");

        -- CASE 7: Max 36-bit Pattern
        -- Input has 1s in bottom 36 bits
        check_gate('1', 
                   "00" & x"000000FFF" & x"FFFFFF", 
                   x"FFFFFFFFF", 
                   "Test 7: Max Pattern");

        report "Output Gate Tests Completed." severity failure;
        wait;
    end process;

end Behavioral;