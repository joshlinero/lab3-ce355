library IEEE;
use IEEE.std_logic_1164.all;
use WORK.divider_const.all;

entity divider is
	generic (
		DATA_WIDTH : natural := 16
    );
    port(
        -- Inputs
--		  clk			: 	in std_logic;
        start 		: 	in std_logic;
        dividend 	: 	in std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
        divisor 	: 	in std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
        
        -- Outputs
        quotient 	:	out std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
        remainder :	out std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
        overflow 	:	out std_logic
    );
end entity divider;

architecture structural_combinational of divider is

	component comparator
		generic(
        DATA_WIDTH : natural := 16 
		);
		port(
			DINL				:	in std_logic_vector (DATA_WIDTH downto 0);
			DINR				:	in std_logic_vector (DATA_WIDTH - 1 downto 0);
			DOUT				:	out std_logic_vector (DATA_WIDTH - 1 downto 0);
			isGreaterEq		:	out std_logic
		);
	end component;
	
	type temp_DOUT_array is array (0 to (DATA_WIDTH + 1) * 2) of std_logic_vector (DATA_WIDTH - 1 downto 0);
	signal temp_DOUT		:	temp_DOUT_array;
	signal temp_quotient	:	std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
	signal div_start     : std_logic := '0';
	
begin

	-- Comparator instantiations
	comparator_gen : for i in 0 to (DATA_WIDTH + 1) * 2 generate
	begin
	
		firstslice: if (i = 0) generate
		begin
			comp_first : comparator
			generic map (
				DATA_WIDTH => DATA_WIDTH
			)
			port map (
				DINL => dividend,
				DINR => divisor,
				DOUT => temp_DOUT(i),
				isGreaterEq => temp_quotient(i)
			);
		end generate firstslice;
		
		middleslice: if (i > 0 and i < (DATA_WIDTH + 1) * 2) generate
		begin
			comp_middle : comparator
			generic map (
				DATA_WIDTH => DATA_WIDTH
			)
			port map (
				DINL => temp_DOUT(i-1),
				DINR => divisor,
				DOUT => temp_DOUT(i),
				isGreaterEq => temp_quotient(i)
			);
		end generate middleslice;
		
		lastslice: if (i = (DATA_WIDTH + 1) * 2) generate
		begin
			comp_last : comparator
			generic map (
				DATA_WIDTH => DATA_WIDTH
			)
			port map (
				DINL => temp_DOUT(i-1),
				DINR => divisor,
				DOUT => remainder,
				isGreaterEq => temp_quotient(i)
			);
		end generate lastslice;
	end generate comparator_gen;
	
	-- Process to control division operation
	division_process: process(start)
	begin
		if rising_edge(start) then
			-- Check for division by zero
			if divisor = (divisor'range => '0') then
				overflow <= '1';
				quotient <= (others => '0');
				remainder <= (others => '0');
			else
				overflow <= '0';
				div_start <= '1';  -- Trigger the division
			end if;
		end if;
	end process division_process;
end architecture structural_combinational;
