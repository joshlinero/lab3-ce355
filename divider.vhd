library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.divider_const.all;

entity divider is
    port(
        -- Inputs
 		  clk			: 	in std_logic;
        start 		: 	in std_logic;
        dividend 	: 	in std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
        divisor 	: 	in std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
        
        -- Outputs
        quotient 	:	out std_logic_vector (DIVIDEND_WIDTH - 1 downto 0) := (others => '0');
        remainder :	out std_logic_vector (DIVISOR_WIDTH - 1 downto 0) := (others => '0');
        overflow 	:	out std_logic := '0';
		  sign		:	out std_logic := '0'
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

architecture behavioral_sequential of divider is

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
	
	signal zext_divisor : std_logic_vector (DIVIDEND_WIDTH + DIVISOR_WIDTH - 1 downto 0);
	signal zext_dividend : std_logic_vector (DIVIDEND_WIDTH + DIVISOR_WIDTH - 1 downto 0);
	signal temp_DOUT : std_logic_vector (DIVIDEND_WIDTH + DIVISOR_WIDTH - 1 downto 0);
	signal temp_quotient : std_logic;
	signal quotient_out : std_logic_vector (DIVIDEND_WIDTH downto 0); 
	--signal counter : unsigned(DIVIDEND_WIDTH + DIVISOR_WIDTH - 1 downto 0); 
	signal shift_position : std_logic_vector(DIVIDEND_WIDTH downto 0);
	constant ZERO_VECTOR : std_logic_vector(DIVISOR_WIDTH - 1 downto 0) := (others => '0');
	constant ZERO_VECTOR2 : std_logic_vector(DIVIDEND_WIDTH - 1 downto 0) := (others => '0');
	constant ONE_VECTOR : std_logic_vector(DIVIDEND_WIDTH downto 0) := "1" & (DIVIDEND_WIDTH - 1 downto 0 => '0');
	signal done : std_logic := '0';
	
	
begin	

	looping_comparator : comparator
		generic map (
			DATA_WIDTH => DIVIDEND_WIDTH + DIVISOR_WIDTH
		)
		port map (
			DINL(DIVIDEND_WIDTH + DIVISOR_WIDTH) => '0',
			DINL(DIVIDEND_WIDTH + DIVISOR_WIDTH - 1 downto 0) => zext_dividend,
			DINR => zext_divisor,
			DOUT => temp_DOUT,
			isGreaterEq => temp_quotient
	);
	
		
	looping_process : process (divisor, start, clk)
	begin 
		if (start = '1') then
				done <= '0';
				overflow <= '0';
				quotient <= (others => '0');
				remainder <= (others => '0');
			
				if divisor = ZERO_VECTOR then
					overflow <= '1';
					quotient <= (others => '0');
					remainder <= (others => '0');
					done <= '1';
				else
					zext_dividend(DIVIDEND_WIDTH - 1 downto 0) <= dividend;
					zext_dividend(DIVIDEND_WIDTH + DIVISOR_WIDTH - 1 downto DIVIDEND_WIDTH) <= (others => '0');
					zext_divisor(DIVIDEND_WIDTH + DIVISOR_WIDTH - 1 downto 0) <= (others => '0');
					zext_divisor(DIVIDEND_WIDTH + DIVISOR_WIDTH - 1 downto DIVIDEND_WIDTH) <= divisor; 
					quotient_out <= (others => '0');
					shift_position <= ONE_VECTOR;
				end if;
			
		elsif (rising_edge(clk)) and done = '0' then
				--counter <= counter + 1;
				
				zext_dividend <= temp_DOUT;
				zext_divisor <= std_logic_vector(unsigned(zext_divisor) SRL 1);

				--quotient_out((DIVIDEND_WIDTH - 1) - to_integer(counter)) <= temp_quotient;
				--remainder <= std_logic_vector(resize(unsigned(temp_DOUT), 4));
				
				if temp_quotient = '1' then
					quotient_out <= quotient_out or shift_position;
				end if;
		
				-- Shift the position for the next bit
				shift_position <= std_logic_vector(unsigned(shift_position) SRL 1);
				
				if (unsigned(temp_DOUT) < resize(unsigned(divisor), DIVIDEND_WIDTH + DIVISOR_WIDTH - 1)) or (shift_position = ZERO_VECTOR2) then
					-- Stop division as remainder is now less than divisor
					--quotient <= std_logic_vector(resize(unsigned(quotient_out), DIVIDEND_WIDTH));
					remainder <= std_logic_vector(resize(unsigned(temp_DOUT), DIVISOR_WIDTH));
					done <= '1';
				end if;

		
		end if;
		
		if done = '1' and divisor /= ZERO_VECTOR then
			quotient <= std_logic_vector(resize(unsigned(quotient_out), DIVIDEND_WIDTH));
			--remainder <= std_logic_vector(resize(unsigned(temp_DOUT), DIVISOR_WIDTH));
		end if;
		
		
	end process looping_process;
	
	
end architecture behavioral_sequential;

architecture fsm_behavioral of divider is

	function get_msb_pos(vec_in: std_logic_vector) return unsigned is
		variable msb: unsigned;
	begin
		
	end function get_msb_pos;
	
	signal N :	unsigned;
	signal a	:	signed;
	signal b	:	signed;
	signal p :	unsigned;
	signal q :	unsigned;
	
	type states is (idle, init, div_by_1, loop_state, done);
	signal state	:	states;
	signal next_state : states;
	
begin
	
	state_reg: process (clk, start)
	begin
		-- Clocked process for state updates
		if(start = '1') then
			-- Reset logic
			state <= idle;
		elsif (rising_edge(clk)) then
			-- Start and continue logic
			state <= next_state;
		end if;
	end process;

	output_and_next_state_logic: process (state, dividend, divisor)
	begin
		-- Default assignements
		next_state <= state;
		-- State logic
		case (state) is
			when init =>
				N <= DIVIDEND_WIDTH;
				a <= signed(dividend);
				b <= signed(divisor);
				p <= 0;
				q <= 0;
				if (b = 1) then
					next_state <= div_by_1;
				else
					next_state <= loop_state;
				end if;
			when div_by_1 =>
				q <= a;
				a <= 0;
				next_state <= done;
			when loop_state =>
				if (b /= 0 AND b < a) then
					p <= get_msb_pos(a) - get_msb_pos(b);
					if ((b SLL p) > a ) then
						p <= p - 1;
					end if;
					q <= q + (1 SLL p);
					a <= a - ( b SLL p);
					next_state <= loop_state;
				else
					next_state <= done;
				end if;
			when done =>
				sign <= (dividend SRL (N-1)) XOR (divisor SRL (N-1));
				if (sign = 1) then
					quotient <= -q;
				else
					quotient <= q;
				end if;
				if (dividend SRL (N-1) = 1) then
					remainder <= -a;
				else
					remainder <= a;
				end if;
				next_state <= idle;
			when others =>
				next_state <= idle;
		end case;
	end process;
end architecture fsm_behavioral;