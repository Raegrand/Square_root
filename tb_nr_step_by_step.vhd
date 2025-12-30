library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_nr_step_by_step is
end tb_nr_step_by_step;

architecture behavior of tb_nr_step_by_step is

    -- COMPONENT: The Newton-Raphson Calculation Core
    component nr_block is
        Port (
            clk        : in  std_logic;
            reset      : in  std_logic;
            start      : in  std_logic;
            dividend_S : in  std_logic_vector(31 downto 0);
            xn_current : in  std_logic_vector(61 downto 0);
            xn_next    : out std_logic_vector(61 downto 0);
            nr_done    : out std_logic
        );
    end component;

    -- SIGNALS
    signal clk        : std_logic := '0';
    signal reset      : std_logic := '0';
    signal start      : std_logic := '0';
    
    signal s_in_vec   : std_logic_vector(31 downto 0);
    signal xn_curr    : std_logic_vector(61 downto 0);
    signal xn_next_hw : std_logic_vector(61 downto 0);
    signal nr_done    : std_logic;

    constant T : time := 20 ns;
    
    -- Target S = 1,158,477,330
    constant S_VAL_INT : integer := 1158477330;
    
    -- Initial Guess for S (Index 30 -> 32768.0)
    -- 32768 in Q42.20 = 32768 * 2^20 = 0x800000000
    constant X0_VAL_HEX : std_logic_vector(61 downto 0) := "00" & x"000800000000000";

begin

    -- Instantiate the Calculation Block
    uut: nr_block
        port map (
            clk        => clk,
            reset      => reset,
            start      => start,
            dividend_S => s_in_vec,
            xn_current => xn_curr,
            xn_next    => xn_next_hw,
            nr_done    => nr_done
        );

    -- Clock Generation
    process
    begin
        clk <= '0'; wait for T/2;
        clk <= '1'; wait for T/2;
    end process;

    -- STEP-BY-STEP VERIFICATION PROCESS
    process
        variable current_x_real : real;
        variable next_x_theo    : real;
        variable next_x_hw      : real;
        variable diff           : real;
        
        -- Helper to convert Q42.20 std_logic_vector to REAL
        function to_real(val : std_logic_vector(61 downto 0)) return real is
            variable i_part : integer;
            variable f_part : integer;
        begin
            i_part := to_integer(unsigned(val(61 downto 20)));
            f_part := to_integer(unsigned(val(19 downto 0)));
            return real(i_part) + (real(f_part) / 1048576.0);
        end function;

    begin
        -- 1. Setup
        s_in_vec <= std_logic_vector(to_unsigned(S_VAL_INT, 32));
        xn_curr  <= X0_VAL_HEX; -- Load Initial Guess
        
        reset <= '0'; wait for 100 ns;
        reset <= '1'; wait for 100 ns; -- Release Reset

        report "========================================================" severity note;
        report " TARGET S = " & integer'image(S_VAL_INT) severity note;
        report " TRUE ROOT approx 34,036.4118..." severity note;
        report "========================================================" severity note;

        -- 2. Run 32 Manual Iterations
        for i in 1 to 32 loop
            
            -- A. Calculate Theoretical Value for this step
            -- Formula: X_next = 0.5 * (X_n + S/X_n)
            current_x_real := to_real(xn_curr);
            next_x_theo    := 0.5 * (current_x_real + (real(S_VAL_INT) / current_x_real));

            -- B. Run Hardware Step
            start <= '1'; 
            wait for T; 
            start <= '0';
            
            -- Wait for calculation to finish
            wait until nr_done = '1';
            wait for T; -- Wait for data to stabilize
            
            -- C. Capture Hardware Result
            next_x_hw := to_real(xn_next_hw);
            diff := abs(next_x_hw - next_x_theo);

            -- D. Report
            report "ITERATION " & integer'image(i) severity note;
            report "  Input Xn  : " & real'image(current_x_real) severity note;
            report "  HW Output : " & real'image(next_x_hw) severity note;
            report "  Theo Out  : " & real'image(next_x_theo) severity note;
            
            if diff < 0.00001 then
                report "  STATUS    : [PERFECT MATCH]" severity note;
            else
                report "  STATUS    : [DIFF " & real'image(diff) & "]" severity warning;
            end if;
            report "--------------------------------------------------------" severity note;

            -- E. Update for next loop (Feedback)
            -- We feed the Hardware's output back into its input
            xn_curr <= xn_next_hw;
            
            wait for 100 ns; -- Gap between steps
        end loop;

        report "SIMULATION COMPLETE." severity failure;
        wait;
    end process;

end behavior;