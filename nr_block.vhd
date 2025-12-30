-- Newton raphson block
-- Kelompok : 5
-- Deskripsi
-- Menggabungkan divider, adder, shifter untuk membuat sistem newton raphson square root
-- input:
--				clk			: clock internal 50MHz
--				start			: Memerintahkan block untuk mulai kalkulasi (active High)
-- 			reset			: Membalikan block ke kondisi awal (Active low) 
--				dividend_S	: Input S (32-bit Integer)
--				xn_current	: Input Xn (Q42.20)
-- output:
-- 			xn_next		: Hasil newton raphson/tebakan yang lebih baik (Q42.20)
--				nr_done			: Penanda oprasi telah selesai (active High)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity nr_block is
    Port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        start      : in  std_logic;
        
        -- S: (32-bit Integer)
        dividend_S : in  std_logic_vector(31 downto 0);
        
        -- Xn: (Q42.20 Fixed Point)
        xn_current : in  std_logic_vector(61 downto 0);
        
        -- X_next: (Q42.20 Fixed Point)
        xn_next    : out std_logic_vector(61 downto 0);
        
        nr_done    : out std_logic
    );
end nr_block;

architecture Behavioral of nr_block is

    -- COMPONENT 1: The Divider (S / Xn)
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

    -- COMPONENT 2: The Adder & Shifter ( (Xn + Quot)/2 )
    component adder_shifter is
        Port (
            xn_in       : in  std_logic_vector(61 downto 0);
            quotient_in : in  std_logic_vector(61 downto 0);
            xn_out      : out std_logic_vector(61 downto 0)
        );
    end component;

    -- Internal Signals
    signal quotient_result : std_logic_vector(61 downto 0);
    signal div_done        : std_logic;

begin
    inst_divider: radix4_divider
        Port map (
            clk        => clk,
            reset      => reset,
            start      => start,
            dividend_S => dividend_S,
            divisor_Xn => xn_current,     
            quotient   => quotient_result, 
            done       => div_done
        );

    inst_adder: adder_shifter
        Port map (
            xn_in       => xn_current,     
            quotient_in => quotient_result, 
            xn_out      => xn_next         
        );

    nr_done <= div_done;

end Behavioral;