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

	function get_msb_pos(vec : std_logic_vector; low_pos : integer; high_pos : integer) return integer is
        variable mid : integer;
    begin
        if low_pos > high_pos then
            return -1;  -- No '1' found
        end if;

        if low_pos = high_pos then
            if vec(low_pos) = '1' then
                return low_pos;
            else
                return -1;
            end if;
        end if;

        mid := (low_pos + high_pos) / 2;

        if vec(high_pos downto mid+1) /= (high_pos-mid-1 downto 0 => '0') then
            return get_msb_pos(vec, mid+1, high_pos);
        else
            return get_msb_pos(vec, low_pos, mid);
        end if;
    end function;

--	function get_msb_pos(vec_in: std_logic_vector) return integer is
--	  variable result	: 	integer;
--	begin
--	  result := vec_in'left;
--	  while vec_in(result) = '0' and result > 1 loop
--		 result := result - 1;
--	  end loop;
--	  return result;
--	end function get_msb_pos;
	
	signal sN :	unsigned(31 downto 0) := to_unsigned(0, 32);
	signal sa	:	unsigned(DIVIDEND_WIDTH - 1 downto 0) := to_unsigned(0, DIVIDEND_WIDTH);
	signal sb	:	unsigned(DIVISOR_WIDTH - 1 downto 0) := to_unsigned(0, DIVISOR_WIDTH);
	signal sp :	integer := 0;
	signal sq :	unsigned(DIVIDEND_WIDTH - 1 downto 0) := to_unsigned(0, DIVIDEND_WIDTH);
	
	type states is (idle, init, div_by_1, loop_state, done);
	signal state	:	states;
	signal next_state : states;
	
begin
	
	state_reg: process (clk, start)
	begin
		-- Clocked process for state updates
		if(start = '1') then
			-- Reset logic
			state <= init;
		elsif (rising_edge(clk)) then
			-- Start and continue logic
			state <= next_state;
		end if;
	end process;

	output_and_next_state_logic: process (state, dividend, divisor, clk)
		variable N :	unsigned(31 downto 0) := to_unsigned(0, 32);
		variable a	:	unsigned(DIVIDEND_WIDTH - 1 downto 0) := to_unsigned(0, DIVIDEND_WIDTH);
		variable b	:	unsigned(DIVISOR_WIDTH - 1 downto 0) := to_unsigned(0, DIVISOR_WIDTH);
		variable p :	integer := 0;
		variable q :	unsigned(DIVIDEND_WIDTH - 1 downto 0) := to_unsigned(0, DIVIDEND_WIDTH);
		
		variable temp_quotient 	: std_logic_vector (DIVIDEND_WIDTH - 1 downto 0) := (others => '0');
		variable temp_remainder 	: std_logic_vector (DIVISOR_WIDTH - 1 downto 0) := (others => '0');
		variable temp_overflow 	: std_logic := '0';
		variable temp_sign			: std_logic := '0';
	begin
		if (rising_edge(clk)) then
			-- Default assignements
			next_state <= state;
			N := sN;
			a := sa;
			b := sb;
			p := sp;
			q := sq;
			-- State logic
			case (state) is
				when init =>
					N := to_unsigned(DIVIDEND_WIDTH, 32);
					a := (others => '0');
					if (signed(dividend) < 0) then
						a := (unsigned(not dividend) + 1);
					else
						a := unsigned(dividend);
					end if;
					b := (others => '0');
					if (signed(divisor) < 0) then
						b := (unsigned(not divisor) + 1);
					else
						b := unsigned(divisor);
					end if;
					p := 0;
					q := (others => '0');
					if (b = to_unsigned(1, DIVISOR_WIDTH)) then
						next_state <= div_by_1;
					else
						next_state <= loop_state;
					end if;
				when div_by_1 =>
					q := a;
					next_state <= done;
				when loop_state =>
					if (b /= to_unsigned(0, DIVISOR_WIDTH) AND b <= a) then
						p := get_msb_pos(std_logic_vector(a), a'right, a'left) - get_msb_pos(std_logic_vector(b), b'right, b'left);
						--p := get_msb_pos(std_logic_vector(a)) - get_msb_pos(std_logic_vector(b));
						if ((b SLL p) > a ) then
							p := p - 1;
						end if;
						q := q + (to_unsigned(1, DIVIDEND_WIDTH) SLL p);
						a := a - (b SLL p);
						next_state <= loop_state;
					else
						next_state <= done;
					end if;
				when done =>
					temp_sign := dividend(dividend'left) XOR divisor(divisor'left);
					if (to_integer(unsigned(divisor)) = 0) then
						temp_overflow := '1';
					else
						temp_overflow := '0';
					end if;
					if (dividend(dividend'left) XOR divisor(divisor'left)) = '1' then
						temp_quotient := std_logic_vector(unsigned(not q) + 1);
					else
						temp_quotient := std_logic_vector(q);
					end if;
					if ((unsigned(dividend) SRL to_integer(N-1)) = 1) then
						temp_remainder := std_logic_vector(resize((unsigned(not a) + 1), DIVISOR_WIDTH));
					else
						temp_remainder := std_logic_vector(resize(a, DIVISOR_WIDTH));
					end if;
					if (to_integer(unsigned(divisor)) = 1 OR to_integer(signed(divisor)) = -1) then
						temp_remainder := (others => '0');
					end if;
					next_state <= idle;
					temp_quotient := std_logic_vector(q);
				when others =>
					N := (others => '0');
					a := (others => '0');
					b := (others => '0');
					p := 0;
					q := (others => '0');
					next_state <= idle;
			end case;
			sN <= N;
			sa <= a;
			sb <= b;
			sp <= p;
			sq <= q;
			quotient <= temp_quotient;
			remainder <= temp_remainder;
			overflow <= temp_overflow;
			sign <= temp_sign;
		end if;
	end process;
end architecture fsm_behavioral;