library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;
use IEEE.std_logic_arith.all;
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
        variable dividend_var : std_logic_vector(DIVIDEND_WIDTH - 1 downto 0);
        variable divisor_var  : std_logic_vector(DIVISOR_WIDTH - 1 downto 0);
        variable quotient_var : std_logic_vector(DIVIDEND_WIDTH - 1 downto 0);
        variable remainder_var : std_logic_vector(DIVISOR_WIDTH - 1 downto 0);
    begin
        -- Read input data from file
        while not endfile(infile) loop
            -- Read the dividend
            readline(infile, inline);
            hread(inline, dividend_var);  -- Read as hex from input file
            dividend <= dividend_var;

            -- Read the divisor
            readline(infile, inline);
            hread(inline, divisor_var);  -- Read as hex from input file
            divisor <= divisor_var;

            -- Apply the test case
            start <= '1';  -- Start division

            -- Write results to output file
            write(outline, dividend_var);
            write(outline, string'("/"));
            write(outline, divisor_var);
            write(outline, string'(" = "));
            write(outline, quotient);
            write(outline, string'(" -- "));
            write(outline, remainder);
            writeline(outfile, outline);  -- Output result
				
				start <= '0';

        end loop;
        wait;
    end process;

end architecture;
