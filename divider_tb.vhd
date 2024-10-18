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
            start     : in std_logic;
            dividend  : in std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
            divisor   : in std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
            quotient  : out std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
            remainder : out std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
            overflow  : out std_logic
        );
    end component;

    -- Signals for inputs and outputs
    signal start      : std_logic := '0';
    signal dividend   : std_logic_vector(DIVIDEND_WIDTH - 1 downto 0) := (others => '0');
    signal divisor    : std_logic_vector(DIVISOR_WIDTH - 1 downto 0) := (others => '0');
    signal quotient   : std_logic_vector(DIVIDEND_WIDTH - 1 downto 0);
    signal remainder  : std_logic_vector(DIVISOR_WIDTH - 1 downto 0);
    signal overflow   : std_logic;

    -- File input/output
    file infile  : text open read_mode is "divider16.in";
    file outfile : text open write_mode is "divider16.out";
    
begin
    -- Instantiate the divider component (UUT)
    uut: divider
        port map (
            start      => start,
            dividend   => dividend,
            divisor    => divisor,
            quotient   => quotient,
            remainder  => remainder,
            overflow   => overflow
        );

    -- Test process to read inputs and apply them to the divider
    process
        variable inline   : line;
        variable outline  : line;
        variable dividend_int : integer;
        variable divisor_int  : integer;
        variable dividend_var : std_logic_vector(DIVIDEND_WIDTH - 1 downto 0);
        variable divisor_var  : std_logic_vector(DIVISOR_WIDTH - 1 downto 0);
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
            start <= '1';  -- Start division
            wait for 10 ns;  -- Simulate some delay for the operation to complete
            start <= '0';

            -- Write results to output file
            write(outline, dividend_var);
            write(outline, string'("/"));
            write(outline, divisor_var);
            write(outline, string'(" = "));
            write(outline, quotient);
            write(outline, string'(" -- "));
            write(outline, remainder);
            writeline(outfile, outline);  -- Output result

        end loop;
        wait;
    end process;

end architecture;
