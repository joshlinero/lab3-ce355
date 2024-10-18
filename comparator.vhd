library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity comparator is
    generic(
        DATA_WIDTH : natural := 4 
    );
    port(
        DINL : in std_logic_vector (DATA_WIDTH downto 0);
        DINR : in std_logic_vector (DATA_WIDTH - 1 downto 0);
        DOUT : out std_logic_vector (DATA_WIDTH - 1 downto 0);
        isGreaterEq : out std_logic -- '1' if DINL >= DINR, '0' otherwise
    );
end entity comparator;

architecture behavioral of comparator is
begin
    process(DINL, DINR)
        variable DINL_ext : unsigned(DATA_WIDTH downto 0); 
        variable DINR_ext : unsigned(DATA_WIDTH downto 0); 
        variable result : unsigned(DATA_WIDTH downto 0);   
    begin
        -- Convert inputs to unsigned for proper comparison
        DINL_ext := unsigned(DINL);
        DINR_ext := unsigned('0' & DINR);
        
        -- Perform the comparison
        if DINL_ext >= DINR_ext then
            isGreaterEq <= '1'; 
            result := DINL_ext - DINR_ext;
            DOUT <= std_logic_vector(result(DATA_WIDTH - 1 downto 0));
        else
            isGreaterEq <= '0'; 
            DOUT <= DINL(DATA_WIDTH - 1 downto 0); 
        end if;
    end process;
end architecture behavioral;
