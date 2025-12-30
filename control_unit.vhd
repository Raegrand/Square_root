-- FSM
-- Kelompok 5
-- Deskripsi:
-- Control unit berdasarkan FSM pada rancangan	
-- Input:
--	Eksternal:
-- 		start: memulai kalkulasi sistem (active high)
--			reset: Mengulang sistem (active low) 
-- Internal:
--	 		clk		: sinyal periodik 100kHz
--			cmp_eq	: Menerima hasil block comparator (1 = Input sama, 0 = input berbeda)
--			nr_done	: Proses block newton raphson sudah selesai
--Output:
--			load_xn	: Mengupdate register Xn ke nilai terbaru
--			sel_mux	: Mengatur output multiplexer
--			en_nr		: Mengaktifkan block newton Raphson
--			out_en	: Menaktifkan block output gate
--			done		: Menandakan seluruh proses telah selesai
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_unit is
    Port (
        clk       : in  std_logic;
        reset     : in  std_logic;
        start     : in  std_logic;
        
        cmp_eq    : in  std_logic; -- IGNORED for maximum precision
        nr_done   : in  std_logic; 
        
        load_xn   : out std_logic; 
        sel_mux   : out std_logic;
        en_nr     : out std_logic; 
        out_en    : out std_logic;
        
        done      : out std_logic
    );
end control_unit;

architecture Behavioral of control_unit is

    type state_type is (IDLE, INIT, KALKULASI, WAIT_DIVIDER, UPDATE, DONE_STATE);
    signal state : state_type := IDLE;

    -- Force 32 iterations
    signal iter_count : integer range 0 to 65 := 0;

begin

    process(clk, reset)
    begin
        if reset = '0' then
            state <= IDLE;
            load_xn <= '0'; sel_mux <= '0'; en_nr <= '0'; out_en <= '0'; done <= '0';
            iter_count <= 0;
            
        elsif rising_edge(clk) then
            
            -- Reset Pulsed Outputs
            load_xn <= '0'; sel_mux <= '0'; en_nr <= '0'; out_en <= '0'; done <= '0';

            case state is
                when IDLE =>
                    if start = '1' then state <= INIT;
                    else state <= IDLE;
                    end if;

                when INIT =>
                    sel_mux <= '0';    
                    load_xn <= '1';    
                    iter_count <= 0;   
                    state   <= KALKULASI;

                when KALKULASI =>
                    en_nr <= '1';      
                    state <= WAIT_DIVIDER;

                when WAIT_DIVIDER =>
                    if nr_done = '1' then
                        if iter_count = 10 or cmp_eq = '1' then
                            state <= DONE_STATE;
                        else
                            iter_count <= iter_count + 1;
                            state <= UPDATE;
                        end if;
                    else
                        state <= WAIT_DIVIDER;
                    end if;

                when UPDATE =>
                    sel_mux <= '1';    
                    load_xn <= '1';    
                    state   <= KALKULASI;

                when DONE_STATE =>
                    out_en <= '1';     
                    done   <= '1';     
                    state  <= IDLE;
                        
            end case;
        end if;
    end process;

end Behavioral;