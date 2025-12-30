library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_square_root_debug is
-- No ports for a testbench
end tb_square_root_debug;

architecture behavior of tb_square_root_debug is

    -- Component Declaration for the Unit Under Test (UUT)
    component square_root_debug is
        Port (
            clk        : in  std_logic;
            reset      : in  std_logic;
            start      : in  std_logic;
            s_in       : in  std_logic_vector(31 downto 0);
            result_out : out std_logic_vector(35 downto 0);
            done_led   : out std_logic
        );
    end component;

    -- Signal Declarations
    signal clk        : std_logic := '0';
    signal reset      : std_logic := '0';
    signal start      : std_logic := '0';
    signal done_led   : std_logic := '0';
    signal s_in       : std_logic_vector(31 downto 0) := (others => '0');
    signal result_out : std_logic_vector(35 downto 0);
    
    constant T : time := 20 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: square_root_debug port map (
        clk => clk,
        reset => reset,
        start => start,
        s_in => s_in,
        result_out => result_out,
        done_led => done_led
    );

    -- Clock Process definitions
    process begin
        clk <= '0'; wait for T/2; 
        clk <= '1'; wait for T/2;
    end process;

    -- Stimulus and Verification Process
    process
        -- UPDATED PROCEDURE: Robust checking using REAL types to avoid integer overflows
        procedure check_sqrt(
            input_hex : std_logic_vector(31 downto 0); 
            exp_hex   : std_logic_vector(35 downto 0);
            desc      : string
        ) is
            variable val_s_real    : real;
            variable val_out_real  : real;
            variable val_exp_real  : real;
            variable diff_real     : real;
            variable int_part      : integer;
            variable frac_part     : integer;
        begin
            -- 1. Reset
            reset <= '0';
            wait for 100 ns; reset <= '1'; wait for 100 ns;
            
            -- 2. Apply Input
            s_in <= input_hex;
            wait for T;
            start <= '1'; wait for T; start <= '0';
            
            -- 3. Wait for Done
            wait until done_led = '1';
            wait for 1 ns; 
            
            -- 4. CONVERT INPUT S TO REAL
            -- Summing powers of 2 avoids integer overflow for large unsigned 32-bit values
            val_s_real := 0.0;
            for i in 0 to 31 loop
                if input_hex(i) = '1' then
                    val_s_real := val_s_real + (2.0**i);
                end if;
            end loop;

            -- 5. CONVERT OUTPUT Q16.20 TO REAL
            int_part  := to_integer(unsigned(result_out(35 downto 20)));
            frac_part := to_integer(unsigned(result_out(19 downto 0)));
            val_out_real := real(int_part) + (real(frac_part) / 1048576.0);
            
            -- 6. CONVERT EXPECTED TO REAL
            int_part  := to_integer(unsigned(exp_hex(35 downto 20)));
            frac_part := to_integer(unsigned(exp_hex(19 downto 0)));
            val_exp_real := real(int_part) + (real(frac_part) / 1048576.0);
            
            -- 7. Check Tolerance using REAL (Avoids integer overflow on large diffs)
            diff_real := abs(val_out_real - val_exp_real);

            -- Tolerance: 5 LSBs. 1 LSB = 1/2^20 approx 0.00000095
            -- 5 LSBs = 5.0 / 1048576.0
            if diff_real <= (5.0 / 1048576.0) then
                report "[PASS] " & desc & 
                       " | Input S: " & real'image(val_s_real) & 
                       " | Output: " & real'image(val_out_real)
                       severity note;
            else
                report "[FAIL] " & desc & 
                       " | Input S: " & real'image(val_s_real) &
                       " | Expected: " & real'image(val_exp_real) & 
                       " | Got: " & real'image(val_out_real) & 
                       " | Diff: " & real'image(diff_real)
                       severity error;
            end if;
        end procedure;

    begin
        wait for 100 ns;
        report "========================================" severity note;
        report "STARTING 100-CASE HIGH PRECISION TEST" severity note;
        report "========================================" severity note;

        check_sqrt(x"00000000", x"000000000", "Test 1");
        check_sqrt(x"00000001", x"000100000", "Test 2");
        check_sqrt(x"00000002", x"00016A09E", "Test 3");
        check_sqrt(x"00000003", x"0001BB67B", "Test 4");
        check_sqrt(x"00000004", x"000200000", "Test 5");
        check_sqrt(x"00000005", x"00023C6EF", "Test 6");
        check_sqrt(x"00000006", x"00027311C", "Test 7");
        check_sqrt(x"00000007", x"0002A54FF", "Test 8");
        check_sqrt(x"00000008", x"0002D413D", "Test 9");
        check_sqrt(x"00000009", x"000300000", "Test 10");
        check_sqrt(x"0000000A", x"0003298B0", "Test 11");
        check_sqrt(x"0000000B", x"0003510E5", "Test 12");
        check_sqrt(x"0000000C", x"000376CF6", "Test 13");
        check_sqrt(x"0000000D", x"00039B057", "Test 14");
        check_sqrt(x"0000000E", x"0003BDDD4", "Test 15");
        check_sqrt(x"0000000F", x"0003DF7BD", "Test 16");
        check_sqrt(x"00000010", x"000400000", "Test 17");
        check_sqrt(x"00000011", x"00041F83E", "Test 18");
        check_sqrt(x"00000012", x"00043E1DB", "Test 19");
        check_sqrt(x"00000013", x"00045BE0D", "Test 20");
        check_sqrt(x"00000064", x"000A00000", "Test 21");
        check_sqrt(x"000000FF", x"000FF7FE0", "Test 22");
        check_sqrt(x"00000100", x"001000000", "Test 23");
        check_sqrt(x"000003E8", x"001F9F6E5", "Test 24");
        check_sqrt(x"00000400", x"002000000", "Test 25");
        check_sqrt(x"00001000", x"004000000", "Test 26");
        check_sqrt(x"0000FFFF", x"00FFFF800", "Test 27");
        check_sqrt(x"00010000", x"010000000", "Test 28");
        check_sqrt(x"000F4240", x"03E800000", "Test 29");
        check_sqrt(x"FFFFFFF8", x"FFFFFFFC0", "Test 30");
        check_sqrt(x"4DD3C13B", x"8D26CAC27", "Test 31");
        check_sqrt(x"FAC50263", x"FD5F0CB26", "Test 32");
        check_sqrt(x"F3060E54", x"F96D6DC72", "Test 33");
        check_sqrt(x"96280440", x"C40FAE8E7", "Test 34");
        check_sqrt(x"2B4136BF", x"693AB5FB3", "Test 35");
        check_sqrt(x"D9E67283", x"EC2EDE55E", "Test 36");
        check_sqrt(x"258C3641", x"620AB936E", "Test 37");
        check_sqrt(x"5138EA6E", x"90328E9E3", "Test 38");
        check_sqrt(x"10D43419", x"41A30C4F6", "Test 39");
        check_sqrt(x"E8BA3259", x"F41621CD3", "Test 40");
        check_sqrt(x"DA333529", x"EC5874643", "Test 41");
        check_sqrt(x"EEF98682", x"F75745D54", "Test 42");
        check_sqrt(x"81938F1E", x"B6216FA60", "Test 43");
        check_sqrt(x"A39CDD6C", x"CCA86D8F1", "Test 44");
        check_sqrt(x"54E10BA0", x"93686272D", "Test 45");
        check_sqrt(x"550679EC", x"9388DF8E9", "Test 46");
        check_sqrt(x"CA7D825D", x"E3ADB398B", "Test 47");
        check_sqrt(x"B9C73376", x"DA14AA275", "Test 48");
        check_sqrt(x"33959952", x"72EA65D73", "Test 49");
        check_sqrt(x"2A7A125D", x"684760919", "Test 50");
        check_sqrt(x"C01E4949", x"DDC552EEC", "Test 51");
        check_sqrt(x"DEB93E00", x"EEC867DC4", "Test 52");
        check_sqrt(x"09AF3BCD", x"31CABA267", "Test 53");
        check_sqrt(x"6708666A", x"A2687B146", "Test 54");
        check_sqrt(x"51F884F3", x"90DC3F852", "Test 55");
        check_sqrt(x"0DE41722", x"3BA209E92", "Test 56");
        check_sqrt(x"1CF93287", x"561F86E9C", "Test 57");
        check_sqrt(x"C435905F", x"E01E998CF", "Test 58");
        check_sqrt(x"22C331E0", x"5E55E632D", "Test 59");
        check_sqrt(x"4B184286", x"8AA6CDC34", "Test 60");
        check_sqrt(x"FBB5771B", x"FDD869508", "Test 61");
        check_sqrt(x"163B3DF5", x"4B70B8DF1", "Test 62");
        check_sqrt(x"00D5B28B", x"0E9E4F0C3", "Test 63");
        check_sqrt(x"C5856933", x"E0DE17288", "Test 64");
        check_sqrt(x"F649AB46", x"FB18D081A", "Test 65");
        check_sqrt(x"B3037E45", x"D612D576A", "Test 66");
        check_sqrt(x"39420CCE", x"791207F87", "Test 67");
        check_sqrt(x"434770B7", x"833CF478B", "Test 68");
        check_sqrt(x"ABDE23F0", x"D1C1E0D4A", "Test 69");
        check_sqrt(x"D5C79E08", x"E9F078F01", "Test 70");
        check_sqrt(x"7442436E", x"AC84763E6", "Test 71");
        check_sqrt(x"D536489E", x"E9A0E672E", "Test 72");
        check_sqrt(x"665C31FD", x"A1E08993D", "Test 73");
        check_sqrt(x"F4E3AB07", x"FA620F164", "Test 74");
        check_sqrt(x"363C9945", x"75D53AB5E", "Test 75");
        check_sqrt(x"48202309", x"87E1FF8C2", "Test 76");
        check_sqrt(x"DB45164B", x"ECEC99D41", "Test 77");
        check_sqrt(x"23735F42", x"5F43C67CA", "Test 78");
        check_sqrt(x"F88BBC0F", x"FC3ED198D", "Test 79");
        check_sqrt(x"11113265", x"421993154", "Test 80");
        check_sqrt(x"1495D3F7", x"4897F4EAF", "Test 81");
        check_sqrt(x"BFEA47D9", x"DDA74CC03", "Test 82");
        check_sqrt(x"EC227ACC", x"F5DDE61DB", "Test 83");
        check_sqrt(x"93D2627A", x"C287FC338", "Test 84");
        check_sqrt(x"8722889D", x"B9FEFDAAA", "Test 85");
        check_sqrt(x"40C6E78A", x"80C64DED6", "Test 86");
        check_sqrt(x"1FFD4DC2", x"5A7EA95F1", "Test 87");
        check_sqrt(x"75E8D88B", x"ADBCE4BF1", "Test 88");
        check_sqrt(x"0F1916FE", x"3E2B7B0F5", "Test 89");
        check_sqrt(x"9509FE8D", x"C35499FD2", "Test 90");
        check_sqrt(x"A89803EF", x"CFBFF890D", "Test 91");
        check_sqrt(x"5DDF0E14", x"9B04FFFBE", "Test 92");
        check_sqrt(x"A99E7426", x"D0616BBD1", "Test 93");
        check_sqrt(x"D3FA9507", x"E8F3AEEF2", "Test 94");
        check_sqrt(x"A5005F4F", x"CD864DF45", "Test 95");
        check_sqrt(x"58BFC698", x"96BB16136", "Test 96");
        check_sqrt(x"450CF612", x"84F4696D7", "Test 97");
        check_sqrt(x"A5CFD7BE", x"CE075BAB7", "Test 98");
        check_sqrt(x"1E7A13DA", x"585451920", "Test 99");
        check_sqrt(x"2D0CE785", x"6B6430389", "Test 100");

        report "========================================" severity note;
        report "ALL 100 TESTS COMPLETED." severity failure;
        wait;
    end process;

end behavior;