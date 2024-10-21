library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.divider_const.all;

entity divider is
    port(
        -- Inputs
--		  clk			: 	in std_logic;
        start 		: 	in std_logic;
        dividend 	: 	in std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
        divisor 	: 	in std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
        
        -- Outputs
        quotient 	:	out std_logic_vector (DIVIDEND_WIDTH - 1 downto 0) := (others => '0');
        remainder :	out std_logic_vector (DIVISOR_WIDTH - 1 downto 0) := (others => '0');
        overflow 	:	out std_logic := '0'
    );
end entity divider;

architecture structural_combinational of divider is

	component comparator
		generic(
        DATA_WIDTH : natural
		);
		port(
			DINL				:	in std_logic_vector (DATA_WIDTH downto 0);
			DINR				:	in std_logic_vector (DATA_WIDTH - 1 downto 0);
			DOUT				:	out std_logic_vector (DATA_WIDTH - 1 downto 0);
			isGreaterEq		:	out std_logic
		);
	end component;
	
	type temp_DOUT_array is array (0 to DIVIDEND_WIDTH - 2) of std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
	
	signal temp_DOUT		:	temp_DOUT_array;
	signal temp_quotient	:	std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
	signal zext_divisor 	: 	std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
	signal temp_remainder:	std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
	
begin
	zext_divisor <= (DIVIDEND_WIDTH-1 downto DIVISOR_WIDTH => '0') & divisor;

	-- Comparator instantiations
	comparator_gen : for i in 0 to DIVIDEND_WIDTH - 1 generate
	begin
	
		firstslice: if (i = 0) generate
		begin
			comp_first : comparator
			generic map (
				DATA_WIDTH => DIVIDEND_WIDTH
			)
			port map (
				DINL(DIVIDEND_WIDTH) => '0',
				DINL(DIVIDEND_WIDTH - 1 downto 0) => dividend,
				DINR => zext_divisor,
				DOUT => temp_DOUT(i),
				isGreaterEq => temp_quotient(i)
			);
		end generate firstslice;
		
		middleslice: if (i > 0 and i < DIVIDEND_WIDTH - 1) generate
		begin
			comp_middle : comparator
			generic map (
				DATA_WIDTH => DIVIDEND_WIDTH
			)
			port map (
				DINL(DIVIDEND_WIDTH) => '0',
				DINL(DIVIDEND_WIDTH - 1 downto 0) => temp_DOUT(i-1),
				DINR => zext_divisor,
				DOUT => temp_DOUT(i),
				isGreaterEq => temp_quotient(i)
			);
		end generate middleslice;
		
		lastslice: if (i = DIVIDEND_WIDTH - 1) generate
		begin
			comp_last : comparator
			generic map (
				DATA_WIDTH => DIVIDEND_WIDTH
			)
			port map (
				DINL(DIVIDEND_WIDTH) => '0',
				DINL(DIVIDEND_WIDTH - 1 downto 0) => temp_DOUT(i-1),
				DINR => zext_divisor,
				DOUT => temp_remainder,
				isGreaterEq => temp_quotient(i)
			);
		end generate lastslice;
	end generate comparator_gen;
	
	-- Process to control division operation
	division_process: process(start)
		variable quotient_sum : integer := 0;
	begin
			if rising_edge(start) then
			  -- Check for division by zero
			  if divisor = (divisor'range => '0') then
					overflow <= '1';
					quotient <= (others => '0');
					remainder <= (others => '0');
			  else
					overflow <= '0';
					
					-- Calculate sum of digits in temp_quotient
                quotient_sum := 0;
                for i in 0 to DIVIDEND_WIDTH - 1 loop
                    if temp_quotient(i) = '1' then
                        quotient_sum := quotient_sum + 1;
                    end if;
                end loop;
                
               -- Convert sum to std_logic_vector and assign to quotient
               quotient <= std_logic_vector(to_unsigned(quotient_sum, DIVIDEND_WIDTH));
					
					remainder <= temp_remainder(DIVISOR_WIDTH - 1 downto 0);
			  end if;
		 end if;
	end process division_process;
end architecture structural_combinational;
