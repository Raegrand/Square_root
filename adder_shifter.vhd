-- Adder and Shifter block
-- Kelompok : 5
-- Deskripsi
-- Menjumlahkan 2 input kemudian right shift hasilnya satu kali
-- input:
-- 			quotient_in	: input 1 (Q42.20)
-- 			xn_in			: input 2 (Q42.20)
-- output:
-- 			xn_out		: hasil penjumlahan dan right shift (Q42.20)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder_shifter is
    Port (
        xn_in       : in  std_logic_vector(61 downto 0);
        quotient_in : in  std_logic_vector(61 downto 0);
        
        xn_out      : out std_logic_vector(61 downto 0)
    );
end adder_shifter;

architecture Behavioral of adder_shifter is
    
    signal sum_extended : unsigned(62 downto 0);

begin

    process(xn_in, quotient_in)
    begin
        sum_extended <= ('0' & unsigned(xn_in)) + ('0' & unsigned(quotient_in));
    end process;

    xn_out <= std_logic_vector(sum_extended(62 downto 1));

end Behavioral;