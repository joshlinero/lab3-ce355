library IEEE;

use IEEE.std_logic_1164.all;
use WORK.divider_const.all;
--Additional standard or custom libraries go here
use WORK.comparator.all;


entity divider is
	port(
		--Inputs
		--clk : in std_logic;
		--COMMENT OUT clk signal for Part A.
		
		start : in std_logic;
		dividend : in std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
		divisor : in std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
		
		--Outputs
		quotient : out std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
		remainder : out std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
		overflow : out std_logic
	 );
end entity divider;

architecture structural_combinational of divider is
--Signals and components go here

    signal compare_result : std_logic;  -- To store comparator result
    signal remainder_signal : std_logic_vector(DIVISOR_WIDTH - 1 downto 0); -- Internal remainder storage
	 
	 signal partial_dividend : std_logic_vector(DIVISOR_WIDTH downto 0);

    -- Declare the comparator component for structural instantiation
    component comparator
        generic(
            DATA_WIDTH : natural := 4
        );
        port(
            DINL : in std_logic_vector (DATA_WIDTH downto 0);
            DINR : in std_logic_vector (DATA_WIDTH - 1 downto 0);
            DOUT : out std_logic_vector (DATA_WIDTH - 1 downto 0);
            isGreaterEq : out std_logic  -- '1' if DINL >= DINR, '0' otherwise
        );
    end component;


begin
--Structural design goes here
divider_loop: process (start)
	begin
		if start = '1' then
			-- Initialize the partial dividend with the dividend
			partial_dividend <= left'dividend; -- left MSB of divided of size divisor
	
			 -- Loop through each bit of the dividend
			 for i in DIVIDEND_WIDTH-1 downto 0 loop
			 -- Perform the comparison and subtraction
				dut: comparator
					generic map (
						DATA_WIDTH => DIVISOR_WIDTH
					)
					port map (   (i + 1) * 4 - 1 downto i * 4
						DINL => partial_dividend((i + 1) * DIVISOR_WIDTH - 1 downto i * DIVISOR_WIDTH), -- Slice of partial dividend
						DINR => divisor,
						DOUT => remainder_signal,
						isGreaterEq => compare_result
					);
	
					-- Check if subtraction can happen
					if compare_result = '1' then
						 -- Update quotient and partial_dividend
						 partial_dividend(DIVIDEND_WIDTH downto DIVIDEND_WIDTH-DIVISOR_WIDTH) <= remainder_signal;
						 quotient(i) <= '1'; -- Set this bit of the quotient to 1
					else
						 quotient(i) <= '0'; -- Set this bit of the quotient to 0
					end if;
			  end loop;

           -- After the loop, assign the final remainder
           remainder <= partial_dividend(DIVISOR_WIDTH-1 downto 0); -- The remainder is the lower bits
       end if;
		 
 end process divider_loop;



end architecture structural_combinational;