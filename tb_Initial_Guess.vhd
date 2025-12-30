library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_Initial_Guess is
-- No ports for a testbench
end tb_Initial_Guess;

architecture behavior of tb_Initial_Guess is

    -- Component Declaration
    component Initial_Guess is
        Port (
            input_s   : in  STD_LOGIC_VECTOR (31 downto 0);
            guess_out : out STD_LOGIC_VECTOR (61 downto 0)
        );
    end component;

    -- Signals
    signal s_in  : std_logic_vector(31 downto 0) := (others => '0');
    signal s_out : std_logic_vector(61 downto 0);
    
    -- Helper for readable delay
    constant T : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: Initial_Guess
        port map (
            input_s   => s_in,
            guess_out => s_out
        );

    -- Stimulus Process
    process
        
        -- Procedure to simplify applying inputs
        procedure check_val(val : integer; desc : string) is
        begin
            s_in <= std_logic_vector(to_unsigned(val, 32));
            wait for T;
            report "Input: " & integer'image(val) & " (" & desc & ") " & 
                   "| Guess MSB: " & to_hstring(s_out(61 downto 32)) & 
                   " LSB: " & to_hstring(s_out(31 downto 0))
                   severity note;
        end procedure;

        -- Procedure for massive numbers (avoiding integer limit)
        procedure check_hex(val_hex : std_logic_vector(31 downto 0); desc : string) is
        begin
            s_in <= val_hex;
            wait for T;
            report "Input: HEX " & to_hstring(val_hex) & " (" & desc & ") " & 
                   "| Guess MSB: " & to_hstring(s_out(61 downto 32)) & 
                   " LSB: " & to_hstring(s_out(31 downto 0))
                   severity note;
        end procedure;

    begin
        wait for T;
        report "===========================================" severity note;
        report "       TESTING INITIAL GUESS MODULE        " severity note;
        report "===========================================" severity note;

        ------------------------------------------------------------
        -- 1. EDGE CASE: ZERO
        ------------------------------------------------------------
        -- Should return safe seed 0x100000 (1.0)
        check_val(0, "Zero Case");

        ------------------------------------------------------------
        -- 2. LOW INDICES (Powers of 2)
        ------------------------------------------------------------
        -- Index 0 (S=1) -> Expect 0x100000
        check_val(1, "Index 0");
        
        -- Index 1 (S=2) -> Expect 0x16A09E
        check_val(2, "Index 1");
        
        -- Index 2 (S=4) -> Expect 0x200000
        check_val(4, "Index 2");

        ------------------------------------------------------------
        -- 3. PRIORITY ENCODER CHECK
        ------------------------------------------------------------
        -- Input 3 is binary "11". MSB is bit 1.
        -- Should return same result as Input 2 (Index 1).
        check_val(3, "Index 1 (Non-Power 2)");

        -- Input 255 is "11111111". MSB is bit 7.
        -- Should return result for Index 7 (0xB504F3).
        check_val(255, "Index 7 (Max 8-bit)");

        ------------------------------------------------------------
        -- 4. HIGH INDICES (Large Numbers)
        ------------------------------------------------------------
        -- Index 16 (S=65536) -> Expect 0x10000000
        check_val(65536, "Index 16");

        -- Index 30 (S = 2^30 = 0x40000000)
        check_hex(x"40000000", "Index 30");

        -- Index 31 (S = 2^31 = 0x80000000) - Max MSB
        check_hex(x"80000000", "Index 31");

        -- Max 32-bit Value (0xFFFFFFFF). MSB is bit 31.
        -- Should match Index 31.
        check_hex(x"FFFFFFFF", "Index 31 (Max Int)");

        report "===========================================" severity note;
        report "TEST COMPLETED" severity failure;
        wait;
    end process;

end behavior;