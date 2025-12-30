library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_control_unit is
-- No ports
end tb_control_unit;

architecture Behavioral of tb_control_unit is

    component control_unit is
        Port (
            clk       : in  std_logic;
            reset     : in  std_logic; -- Active Low
            start     : in  std_logic;
            cmp_eq    : in  std_logic;
            nr_done   : in  std_logic;
            load_xn   : out std_logic;
            sel_mux   : out std_logic;
            en_nr     : out std_logic;
            out_en    : out std_logic;
            done      : out std_logic
        );
    end component;

    -- SIGNALS
    signal clk       : std_logic := '0';
    signal reset     : std_logic := '0';
    signal start     : std_logic := '0';
    signal cmp_eq    : std_logic := '0';
    signal nr_done   : std_logic := '0';
    
    signal load_xn   : std_logic;
    signal sel_mux   : std_logic;
    signal en_nr     : std_logic;
    signal out_en    : std_logic;
    signal done      : std_logic;

    constant T : time := 20 ns;

begin

    uut: control_unit
        Port map (
            clk     => clk,
            reset   => reset,
            start   => start,
            cmp_eq  => cmp_eq,
            nr_done => nr_done,
            load_xn => load_xn,
            sel_mux => sel_mux,
            en_nr   => en_nr,
            out_en  => out_en,
            done    => done
        );

    process
    begin
        clk <= '0'; wait for T/2;
        clk <= '1'; wait for T/2;
    end process;

    process
    begin
        -- 1. Reset (ACTIVE LOW)
        reset <= '0'; -- Hold Reset
        wait for T*2;
        reset <= '1'; -- Release Reset (System Active)
        wait for T;

        -----------------------------------------------------
        -- SCENARIO: 2 Iterations then Converge
        -----------------------------------------------------

        -- 2. Pulse Start
        report "Step 1: Start Pulse" severity note;
        start <= '1';
        wait for T;
        start <= '0';

        -- FSM should be in INIT
        wait for T; 
        
        -- FSM should be in KALKULASI
        report "Step 2: Waiting in CALC state..." severity note;
        wait for T*3; 
        
        -- 3. Calc Done -> Not Equal
        report "Step 3: Calc Done, Not Equal" severity note;
        nr_done <= '1';
        cmp_eq  <= '0';
        wait for T; 
        nr_done <= '0'; 
        
        -- FSM goes UPDATE -> KALKULASI
        wait for T*2; 
        
        -- 4. Calc Done -> EQUAL
        report "Step 4: Calc Done, Converged!" severity note;
        nr_done <= '1';
        cmp_eq  <= '1'; 
        wait for T;
        nr_done <= '0';
        
        -- FSM goes DONE
        wait for T;
        
        if done = '1' and out_en = '1' then
            report "[PASS] FSM reached DONE state." severity note;
        else
            report "[FAIL] FSM did not finish." severity error;
        end if;

        wait;
    end process;

end Behavioral;