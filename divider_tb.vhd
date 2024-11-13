library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;
use IEEE.numeric_std.all;
use std.textio.all;
use WORK.divider_const.all;

entity divider_tb is
end divider_tb;

architecture behavior of divider_tb is
    -- Component declaration of the unit under test (UUT)
    component divider
        port(
				clk       : in std_logic;
            start     : in std_logic;
            dividend  : in std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
            divisor   : in std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
            quotient  : out std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
            remainder : out std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
            overflow  : out std_logic;
				sign		 : out std_logic
        );
    end component;
	 for all : divider use entity WORK.divider (fsm_behavioral);

    -- Signals for inputs and outputs
	 signal clk        : std_logic := '0';
    signal start      : std_logic := '0';
    signal dividend   : std_logic_vector(DIVIDEND_WIDTH - 1 downto 0) := (others => '0');
    signal divisor    : std_logic_vector(DIVISOR_WIDTH - 1 downto 0) := (others => '0');
    signal quotient   : std_logic_vector(DIVIDEND_WIDTH - 1 downto 0);
    signal remainder  : std_logic_vector(DIVISOR_WIDTH - 1 downto 0);
    signal overflow   : std_logic;
	 signal sign		 : std_logic;

    -- File input/output
    file infile  : text open read_mode is "divider32.in";
    file outfile : text open write_mode is "divider32.out";
    
begin
    -- Instantiate the divider component (UUT)
    uut: divider
        port map (
				clk        => clk,
            start      => start,
            dividend   => dividend,
            divisor    => divisor,
            quotient   => quotient,
            remainder  => remainder,
            overflow   => overflow,
				sign		  => sign
        );
	 
	 clock_process : process
    begin
        while true loop
            clk <= '0';
            wait for 2 ns;  -- Half period of 10ns for a 20ns clock period
            clk <= '1';
            wait for 2 ns;
        end loop;
    end process clock_process;

    -- Test process to read inputs and apply them to the divider
    read_process : process
        variable inline   : line;
        variable outline  : line;
        variable dividend_int : integer;
        variable divisor_int  : integer;
        variable dividend_var : std_logic_vector(DIVIDEND_WIDTH - 1 downto 0);
        variable divisor_var  : std_logic_vector(DIVISOR_WIDTH - 1 downto 0);
		  variable quotient_int : integer;
		  variable remainder_int: integer;
    begin
        -- Read input data from file
        while not endfile(infile) loop
            -- Read the dividend (integer from file)
            readline(infile, inline);
            read(inline, dividend_int);  -- Read integer

            -- Convert integer to std_logic_vector
            dividend_var := std_logic_vector(to_unsigned(dividend_int, DIVIDEND_WIDTH));
            dividend <= dividend_var;

            -- Read the divisor (integer from file)
            readline(infile, inline);
            read(inline, divisor_int);  -- Read integer

            -- Convert integer to std_logic_vector
            divisor_var := std_logic_vector(to_unsigned(divisor_int, DIVISOR_WIDTH));
            divisor <= divisor_var;

            -- Apply the test case
				wait for 10 ns;
            start <= '1';  -- Start division
            wait for 10 ns;  -- Simulate some delay for the operation to complete
            start <= '0';
				wait for 100 ns;
				
				wait until clk = '1' and clk'event;
				
				quotient_int := to_integer(unsigned(quotient));
				remainder_int:= to_integer(unsigned(remainder));

            -- Write results to output file
            write(outline, dividend_int);
            write(outline, string'("/"));
            write(outline, divisor_int);
            write(outline, string'(" = "));
            write(outline, quotient_int);
            write(outline, string'(" -- "));
            write(outline, remainder_int);
				--write(outline, string'("sign: "));
				--write(outline, sign);
            writeline(outfile, outline);  -- Output result

        end loop;
		  
        wait for 10 ns;
		  --std.env.stop;
    end process read_process;

end architecture;
