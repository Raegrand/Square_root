-- Radix 4 Divider
-- Kelompok : 5
-- Deskripsi
-- Melakaukan pembagian S/Xn dengan meninjau setiap 2 bit dengan bantuan lookup table
-- Kalkulasi 2 kali lebih cepat dibandingkan Radix 2, durasi = 32/clock
-- input:
--				clk			: clock internal 50MHz
--				start			: Memerintahkan block untuk mulai kalkulasi (active High)
--				dividend_S	: Input pembilang S (32-bit Integer)
--				divisor_Xn	: Input penyebut Xn (Q42.20)
-- output:
-- 			quotient		: Hasil pembagian (Q42.20)
--				done			: Penanda oprasi telah selesai (active High)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity radix4_divider is
    Port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        start      : in  std_logic;
        
        dividend_S : in  std_logic_vector(31 downto 0);
        divisor_Xn : in  std_logic_vector(61 downto 0);
        
        quotient   : out std_logic_vector(61 downto 0);
        done       : out std_logic
    );
end radix4_divider;

architecture Behavioral of radix4_divider is

    constant ITERATIONS : integer := 40;
    
    type state_type is (IDLE, CALC, FINISH);
    signal state : state_type := IDLE;

    -- WIDENED REGISTER: 180 bits to prevent overflow during 80 shifts
    signal rem_reg : unsigned(179 downto 0);
    
    signal quo_reg : unsigned(81 downto 0);
    signal div_reg : unsigned(61 downto 0);
    
    signal div_x3 : unsigned(63 downto 0);
    signal div_x2 : unsigned(63 downto 0);
    signal div_x1 : unsigned(63 downto 0);

    signal count : integer range 0 to ITERATIONS;

begin

    div_x1 <= resize(div_reg, 64);
    div_x2 <= resize(div_reg & '0', 64);
    div_x3 <= resize(div_reg & '0', 64) + resize(div_reg, 64);

    process(clk, reset)
        variable v_rem : unsigned(179 downto 0);
        variable v_quo : unsigned(81 downto 0);
        variable v_compare_window : unsigned(63 downto 0);
    begin
        if reset = '0' then
            state   <= IDLE;
            rem_reg <= (others => '0');
            quo_reg <= (others => '0');
            div_reg <= (others => '0');
            done    <= '0';
            
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    done <= '0';
                    if start = '1' then
                        div_reg <= unsigned(divisor_Xn);
                        
                        -- ALIGNMENT UPDATE:
                        -- Pad with 62 zeros (was 42).
                        -- This corresponds to moving the Window up by 20 bits.
                        -- 62 bits = 15 hex zeros + "00"
                        rem_reg <= resize(unsigned(dividend_S) & x"000000000000000" & "00", 180);
                        
                        quo_reg <= (others => '0');
                        count   <= ITERATIONS; 
                        state   <= CALC;
                    end if;

                when CALC =>
                    if count = 0 then
                        state <= FINISH;
                    else
                        v_rem := rem_reg;
                        v_quo := quo_reg;
                        
                        -- Shift Left 2
                        v_rem := v_rem sll 2;
                        v_quo := v_quo sll 2;
                        
                        -- WINDOW MOVED UP: [165 downto 102]
                        -- This captures the MSBs even after 80 shifts for large inputs.
                        v_compare_window := v_rem(165 downto 102);
                        
                        if v_compare_window >= div_x3 then
                            v_quo(1 downto 0) := "11";
                            v_rem(165 downto 102) := v_compare_window - div_x3;
                        elsif v_compare_window >= div_x2 then
                            v_quo(1 downto 0) := "10";
                            v_rem(165 downto 102) := v_compare_window - div_x2;
                        elsif v_compare_window >= div_x1 then
                            v_quo(1 downto 0) := "01";
                            v_rem(165 downto 102) := v_compare_window - div_x1;
                        else
                            v_quo(1 downto 0) := "00";
                        end if;

                        rem_reg <= v_rem;
                        quo_reg <= v_quo;
                        count   <= count - 1;
                    end if;

                when FINISH =>
                    done  <= '1';
                    state <= IDLE; 
            end case;
        end if;
    end process;

    quotient <= std_logic_vector(quo_reg(61 downto 0));

end Behavioral;