-- Multiplexer 2 to 1 block
-- Kelompok 5
-- Deskripsi:
-- Memberikan output tergantung sel, jika sel = 0, mux_out =A
-- jika sel = 1, mux_out = B
-- Input:
-- 			A		: input 1 (Q42.20)
-- 			B		: input 2 (Q42.20)
--				sel	: bit untuk memilih ooutput
-- Output:
--				mux_out: hasil output (Q42.20)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux_2to1 is
    Port (
        -- Inputs are Q42.20 (62 bits)
        in_A    : in  std_logic_vector(61 downto 0); -- Input for Select = 0
        in_B    : in  std_logic_vector(61 downto 0); -- Input for Select = 1
        
        -- Select Signal
        sel_mux : in  std_logic; -- '0' = Select in_A, '1' = Select in_B
        
        -- Output
        mux_out : out std_logic_vector(61 downto 0)
    );
end mux_2to1;

architecture Behavioral of mux_2to1 is
begin
    -- Simple Selection Logic
    process(sel_mux, in_A, in_B)
    begin
        if sel_mux = '0' then
            mux_out <= in_A;
        else
            mux_out <= in_B;
        end if;
    end process;
    
end Behavioral;