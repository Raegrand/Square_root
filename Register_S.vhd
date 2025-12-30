-- Register_S 

-- Kelompok 5 

-- Deskripsi 

-- Menyimpan data integer yang diambil dari sinyal input 

-- dengan outputnya selalu konstan berdasarkan input yang diberikan pengguna 

-- input: user based 

-- clk: internal clock 50MHz 

-- rst: reset nilai yang tersimpan dalam register (0) 

-- load_en: Penanda State telah Start dari FSM 

-- data_in: Input integer yang akan disimpan (S) 

-- data_out: Output integer yang akan digunakan dalam fungsi (S) 

library IEEE; 

use IEEE.STD_LOGIC_1164.ALL; 

use IEEE.NUMERIC_STD.ALL; 

 

entity Register_S is 

    Port ( 

        clk      : in  STD_LOGIC; 

        rst      : in  STD_LOGIC; -- Logika Active Low 

        load_en  : in  STD_LOGIC; -- Penanda Start dari FSM 

        data_in  : in  STD_LOGIC_VECTOR (31 downto 0); -- Input integer S 

        data_out : out STD_LOGIC_VECTOR (31 downto 0)  -- Output stabil ke Datapath 

    ); 

end Register_S; 

 

architecture Behavioral of Register_S is 

begin 

    process(clk, rst) 

    begin 

        if rst = '0' then 

            data_out <= (others => '0'); 

        elsif rising_edge(clk) then 

            if load_en = '1' then 

                data_out <= data_in; 

            end if; 

        end if; 

    end process; 

end Behavioral; 