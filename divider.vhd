library IEEE;
use IEEE.std_logic_1164.all;
use WORK.divider_const.all;
use WORK.comparator.all;

entity divider is
    port(
        -- Inputs
        start : in std_logic;
        dividend : in std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
        divisor : in std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
        
        -- Outputs
        quotient : out std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
        remainder : out std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
        overflow : out std_logic
    );
end entity divider;

architecture structural_combinational of divider is
    signal temp_quotient : std_logic_vector(DIVIDEND_WIDTH - 1 downto 0);
    signal temp_remainder : std_logic_vector(DIVISOR_WIDTH downto 0);  -- One more bit for comparison
    signal compare_result : std_logic;
    
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

-- Division process
divider_loop: process (start)
    variable partial_dividend : std_logic_vector(DIVISOR_WIDTH downto 0);  -- Stores the partial dividend (one bit larger)
    variable quotient_accumulator : std_logic_vector(DIVIDEND_WIDTH - 1 downto 0);  -- Accumulates quotient
begin
    if start = '1' then
        -- Initialize the partial dividend and quotient accumulator
        partial_dividend := (others => '0');  
        quotient_accumulator := (others => '0');  

        -- Perform long division
        for i in DIVIDEND_WIDTH-1 downto 0 loop
            -- Shift partial dividend left by 1 bit and bring in the next bit from the dividend
            partial_dividend := partial_dividend(DIVISOR_WIDTH-1 downto 0) & dividend(i);

            -- Compare partial_dividend (which is DIVISOR_WIDTH+1 bits) with divisor
            comparator_inst: comparator
                generic map (
                    DATA_WIDTH => DIVISOR_WIDTH  -- Comparing DIVISOR_WIDTH+1 bits to DIVISOR_WIDTH bits
                )
                port map (
                    DINL => partial_dividend,
                    DINR => divisor,
                    DOUT => temp_remainder(DIVISOR_WIDTH-1 downto 0),  -- Update remainder
                    isGreaterEq => compare_result  -- '1' if partial_dividend >= divisor
                );

            -- If the partial dividend is greater than or equal to the divisor, subtract and set quotient bit
            if compare_result = '1' then
                -- Subtract divisor from partial dividend
                partial_dividend := temp_remainder;
                -- Set the corresponding quotient bit to '1'
                quotient_accumulator(i) := '1';
            end if;
        end loop;

        -- Assign final quotient and remainder outputs
        quotient <= quotient_accumulator;
        remainder <= partial_dividend(DIVISOR_WIDTH-1 downto 0);  -- Remainder is in the lower bits
    end if;
end process divider_loop;

end architecture structural_combinational;
