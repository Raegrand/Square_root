-- Comparator Block
-- Kelompok 5
-- Deskripsi:
-- Membandingkan 60 bit MSB, jika sama cmp_eq = 1, jike berbeda cmp_eq = 0
-- input:
-- 			a_in: Input angka pertama (Q42.20)
-- 			b_in:	Input angka kedua (Q42.20)
-- Output:
-- 			cmp_eq: hasil perbandingan
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity comparator is
    Port (
        a_in   : in  std_logic_vector(61 downto 0);
        b_in   : in  std_logic_vector(61 downto 0);
        
        cmp_eq : out std_logic
    );
end comparator;

architecture Behavioral of comparator is
begin

    cmp_eq <= '1' when a_in(61 downto 2) = b_in(61 downto 2) else '0';

end Behavioral;