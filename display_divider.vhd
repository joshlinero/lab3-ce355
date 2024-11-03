library IEEE;
use IEEE.std_logic_1164.all;
--Additional standard or custom libraries go here
use WORK.decoder.all; 
use WORK.divider_const.all;

entity display_divider is
	port(
		--You will replace these with your actual inputs and outputs
		clk   		: in std_logic;
		start 		: in std_logic;
      dividend 	: in std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
      divisor 		: in std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
        
      -- Outputs
      overflow 	: out std_logic;
		output_display : out std_logic_vector((DIVIDEND_WIDTH/4 * 7) + (DIVISOR_WIDTH/4 * 7) - 1 downto 0)
	 );
end entity display_divider;

architecture structural of display_divider is
--Signals and components go here
	constant decoder_quotient : integer := DIVIDEND_WIDTH / 4;
	constant decoder_remainder : integer := DIVISOR_WIDTH / 4;

	signal temp_clk 		   : std_logic;
   signal temp_start 		: std_logic;
	signal temp_dividend 	: std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
	signal temp_divisor 	   : std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
   signal temp_quotient 	: std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
   signal temp_remainder 	: std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
   signal temp_overflow 	: std_logic;
	
   signal decoded_quotient : std_logic_vector(DIVIDEND_WIDTH / 4 * 7 - 1 downto 0);
	signal decoded_remainder : std_logic_vector(DIVISOR_WIDTH / 4 * 7 - 1 downto 0);

	component divider is
        port(
				clk			: in std_logic;
            start 		: in std_logic;
				dividend 	: in std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
				divisor 		: in std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
        
				-- Outputs
				quotient 	: out std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
				remainder 	: out std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
				overflow 	: out std_logic
        );
    end component divider;

    component leddcd is
        port(
            data_in      : in std_logic_vector(3 downto 0);
            segments_out : out std_logic_vector(6 downto 0)
        );
    end component leddcd;

begin
--Structural design goes here
	dut : divider
        port map(
				clk			=> temp_clk,
            start 		=> temp_start,
				dividend 	=> temp_dividend,
				divisor 		=> temp_divisor,
				quotient 	=> temp_quotient,
				remainder 	=> temp_remainder,
				overflow 	=> temp_overflow
        );
		  
	 -- Loop over answers  in groups of 4 bits using a generate statement
    g1: for i in 0 to decoder_quotient - 1 generate
		 nth_display: leddcd
			  port map(
					data_in => temp_quotient((i + 1) * 4 - 1 downto i * 4),
					segments_out => decoded_quotient((i + 1) * 7 - 1 downto i * 7)
			  );
	 end generate g1;

	 g2: for i in 0 to decoder_remainder - 1 generate
		 mth_display: leddcd
			  port map(
					data_in => temp_remainder((i + 1) * 4 - 1 downto i * 4),
					segments_out => decoded_remainder((i + 1) * 7 - 1 downto i * 7)
			  );
	 end generate g2;
	 
	 
	 temp_clk <= clk;
	 temp_start <= start;
	 temp_dividend <= dividend;
	 temp_divisor <= divisor;
	 output_display <= decoded_quotient & decoded_remainder;
	 overflow <= temp_overflow;

end architecture structural;