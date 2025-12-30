library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity square_root_debug is
    Port (
        clk        : in  std_logic;
        reset      : in  std_logic; -- Active Low
        start      : in  std_logic; -- Button Pulse
        
        -- Direct Interface
        s_in       : in  std_logic_vector(31 downto 0); -- Input Integer
        result_out : out std_logic_vector(35 downto 0); -- Output Fixed Point Q16.20
        
        done_led   : out std_logic
    );
end square_root_debug;

architecture Behavioral of square_root_debug is

    -- COMPONENT DECLARATIONS
    component Register_S is
        Port ( clk, rst, load_en : in std_logic; data_in : in std_logic_vector(31 downto 0); data_out : out std_logic_vector(31 downto 0));
    end component;
    component Initial_Guess is
        Port ( input_s : in std_logic_vector(31 downto 0); guess_out : out std_logic_vector(61 downto 0));
    end component;
    component mux_2to1 is
        Port ( in_A, in_B : in std_logic_vector(61 downto 0); sel_mux : in std_logic; mux_out : out std_logic_vector(61 downto 0));
    end component;
    component Register_Xn is
        Port ( clk, rst, load_xn : in std_logic; d_in : in std_logic_vector(61 downto 0); d_out : out std_logic_vector(61 downto 0));
    end component;
    component nr_block is
        Port ( clk, reset, start : in std_logic; dividend_S : in std_logic_vector(31 downto 0); xn_current : in std_logic_vector(61 downto 0); xn_next : out std_logic_vector(61 downto 0); nr_done : out std_logic);
    end component;
    component comparator is
        Port ( a_in, b_in : in std_logic_vector(61 downto 0); cmp_eq : out std_logic);
    end component;
    component output_gate is
        Port ( data_in : in std_logic_vector(61 downto 0); out_en : in std_logic; data_out : out std_logic_vector(35 downto 0));
    end component;
    component control_unit is
        Port ( clk, reset, start, cmp_eq, nr_done : in std_logic; load_xn, sel_mux, en_nr, out_en, done : out std_logic);
    end component;

    -- SIGNALS
    signal s_reg_S_out    : std_logic_vector(31 downto 0);
    signal s_guess_out    : std_logic_vector(61 downto 0);
    signal s_mux_out      : std_logic_vector(61 downto 0);
    signal s_reg_Xn_out   : std_logic_vector(61 downto 0);
    signal s_xn_next      : std_logic_vector(61 downto 0);
    signal s_nr_done, s_cmp_eq : std_logic;
    
    -- FSM Signals
    signal fsm_load_xn, fsm_sel_mux, fsm_en_nr, fsm_out_en, fsm_done : std_logic;

begin

    done_led <= fsm_done;

    -- INSTANTIATIONS
    inst_reg_s: Register_S
        port map ( clk => clk, rst => reset, load_en => start, data_in => s_in, data_out => s_reg_S_out );

    inst_initial_guess: Initial_Guess
        port map ( input_s => s_reg_S_out, guess_out => s_guess_out );

    inst_mux: mux_2to1
        port map ( in_A => s_guess_out, in_B => s_xn_next, sel_mux => fsm_sel_mux, mux_out => s_mux_out );

    inst_reg_xn: Register_Xn
        port map ( clk => clk, rst => reset, load_xn => fsm_load_xn, d_in => s_mux_out, d_out => s_reg_Xn_out );

    inst_nr_block: nr_block
        port map ( clk => clk, reset => reset, start => fsm_en_nr, dividend_S => s_reg_S_out, xn_current => s_reg_Xn_out, xn_next => s_xn_next, nr_done => s_nr_done );

    inst_comparator: comparator
        port map ( a_in => s_reg_Xn_out, b_in => s_xn_next, cmp_eq => s_cmp_eq );

    inst_output_gate: output_gate
        port map ( data_in => s_xn_next, out_en => fsm_out_en, data_out => result_out );

    inst_control: control_unit
        port map ( clk => clk, reset => reset, start => start, cmp_eq => s_cmp_eq, nr_done => s_nr_done,
                   load_xn => fsm_load_xn, sel_mux => fsm_sel_mux, en_nr => fsm_en_nr, out_en => fsm_out_en, done => fsm_done );

end Behavioral;