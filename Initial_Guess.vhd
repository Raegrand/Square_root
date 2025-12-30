-- Initial_Guess 

-- Kelompok : 5 

-- Deskripsi 

-- Memberikan output initial guess atau tebakan awal untuk operasi Newton-Raphson 

-- Untuk saat ini initial guess bernilai 1, tetapi ke depannya ada kemungkinan untuk menggunakan LUT & LZT 

-- input_s : digunakan untuk operasi LUT dan LZT jika akan digunakan 

-- guess_out : tebakan awal yang akan dikirimkan ke mux (saat ini bernilai 1) 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Initial_Guess is 
    Port ( 
        input_s      : in  STD_LOGIC_VECTOR (31 downto 0);  
        guess_out    : out STD_LOGIC_VECTOR (61 downto 0) 
    );
end Initial_Guess; 

architecture Behavioral of Initial_Guess is 

    -- Helper: Pads hex literal to 62 bits
    function pad_hex(val : std_logic_vector) return std_logic_vector is
        variable result : std_logic_vector(61 downto 0) := (others => '0');
    begin
        result(val'length-1 downto 0) := val;
        return result;
    end function;

begin 

    process(input_s)
        variable msb_index : integer range -1 to 31;
    begin
        -- 1. LEADING ZERO DETECTOR
        msb_index := -1; 
        for i in 31 downto 0 loop
            if input_s(i) = '1' then
                msb_index := i;
                exit; 
            end if;
        end loop;

        -- 2. LOOKUP TABLE
        case msb_index is
            when 0 => guess_out <= pad_hex(std_logic_vector'(x"100000"));
            when 1 => guess_out <= pad_hex(std_logic_vector'(x"16A09E"));
            when 2 => guess_out <= pad_hex(std_logic_vector'(x"200000"));
            when 3 => guess_out <= pad_hex(std_logic_vector'(x"2D413D"));
            when 4 => guess_out <= pad_hex(std_logic_vector'(x"400000"));
            when 5 => guess_out <= pad_hex(std_logic_vector'(x"5A827A"));
            when 6 => guess_out <= pad_hex(std_logic_vector'(x"800000"));
            when 7 => guess_out <= pad_hex(std_logic_vector'(x"B504F3"));
            
            when 8 => guess_out <= pad_hex(std_logic_vector'(x"1000000"));
            when 9 => guess_out <= pad_hex(std_logic_vector'(x"16A09E6"));
            when 10 => guess_out <= pad_hex(std_logic_vector'(x"2000000"));
            when 11 => guess_out <= pad_hex(std_logic_vector'(x"2D413CD"));
            when 12 => guess_out <= pad_hex(std_logic_vector'(x"4000000"));
            when 13 => guess_out <= pad_hex(std_logic_vector'(x"5A8279A"));
            when 14 => guess_out <= pad_hex(std_logic_vector'(x"8000000"));
            when 15 => guess_out <= pad_hex(std_logic_vector'(x"B504F33"));
            
            when 16 => guess_out <= pad_hex(std_logic_vector'(x"10000000"));
            when 17 => guess_out <= pad_hex(std_logic_vector'(x"16A09E66"));
            when 18 => guess_out <= pad_hex(std_logic_vector'(x"20000000"));
            when 19 => guess_out <= pad_hex(std_logic_vector'(x"2D413CCD"));
            when 20 => guess_out <= pad_hex(std_logic_vector'(x"40000000"));
            when 21 => guess_out <= pad_hex(std_logic_vector'(x"5A82799A"));
            
            -- Large Values
            when 22 => guess_out <= pad_hex(std_logic_vector'(x"80000000"));
            when 23 => guess_out <= pad_hex(std_logic_vector'(x"B504F334"));
            when 24 => guess_out <= pad_hex(std_logic_vector'(x"100000000"));
            when 25 => guess_out <= pad_hex(std_logic_vector'(x"16A09E668"));
            when 26 => guess_out <= pad_hex(std_logic_vector'(x"200000000"));
            when 27 => guess_out <= pad_hex(std_logic_vector'(x"2D413CCD0"));
            when 28 => guess_out <= pad_hex(std_logic_vector'(x"400000000"));
            when 29 => guess_out <= pad_hex(std_logic_vector'(x"5A82799A0"));
            when 30 => guess_out <= pad_hex(std_logic_vector'(x"800000000"));
            when 31 => guess_out <= pad_hex(std_logic_vector'(x"B504F3340"));
            
            when others => guess_out <= pad_hex(std_logic_vector'(x"000010"));
        end case;
    end process;
end Behavioral;