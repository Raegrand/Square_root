-- Register_Xn 

-- Kelompok 5 

-- Deskripsi 

-- Menyimpan data integer yang diambil dari hasil pemilihan mux 

-- dengan output awalnya akan menjadi 1, kemudian akan berganti menyesuaikan 

-- dengan hasil operasi Newton-Raphson 

-- clk : clock internal 50MHz 

-- rst : Mereset nilai yang tersimpan menjadi 0 (logika active low) 

-- load_xn : enable xn dari FSM 

-- d_in : input yang akan disimpan dari MUX 

-- d_out: input yang disimpan akan menjadi output untuk dikirimkan 

-- 		 ke blok operasi newton-rapsshon dan comperators 

library IEEE; 

use IEEE.STD_LOGIC_1164.ALL; 

use IEEE.NUMERIC_STD.ALL; 

 

entity Register_Xn is 

    Port ( 

        clk      : in  STD_LOGIC; 

        rst      : in  STD_LOGIC; -- Active Low 

        load_xn  : in  STD_LOGIC; -- Enable dari FSM (load_xn) 

        d_in     : in  STD_LOGIC_VECTOR (61 downto 0); -- dari MUX 

        d_out    : out STD_LOGIC_VECTOR (61 downto 0)  -- Ke blok kalkulasi & comparator 

    ); 

end Register_Xn; 

 

architecture Behavioral of Register_Xn is 

begin 

    process(clk, rst) 

    begin 

        if rst = '0' then 

            -- Reset ke 0 

            d_out <= (others => '0'); 

        elsif rising_edge(clk) then 

            -- Hanya update nilai jika FSM memberikan sinyal load_xn = 1 

            if load_xn = '1' then 

                d_out <= d_in; 

            end if; 

        end if; 

    end process; 

end Behavioral; 