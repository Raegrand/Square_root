-- Output gate block
-- Kelompok 5
-- Deskripsi:
-- Mengubah format Q42.20 ke Q16.20, output =0 jika out_en = 0
-- input:
--			data_in	:(Q42.20) 
-- 		out_en	: active high output control
-- output:
--			data_out	:(Q16.20)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity output_gate is
    Port (
        data_in  : in  std_logic_vector(61 downto 0);
        
        out_en   : in  std_logic;
        
        data_out : out std_logic_vector(35 downto 0)
    );
end output_gate;

architecture Behavioral of output_gate is
begin
    process(out_en, data_in)
    begin
        if out_en = '1' then

            data_out <= data_in(35 downto 0);
        else
            data_out <= (others => '0');
        end if;
    end process;
end Behavioral;