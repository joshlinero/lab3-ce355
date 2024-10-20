library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity comparator_tb is
end entity comparator_tb;

architecture testbench of comparator_tb is
    -- Component declaration for the comparator
    component comparator
        generic(
            DATA_WIDTH : natural := 4
        );
        port(
            DINL : in std_logic_vector(DATA_WIDTH downto 0);
            DINR : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            DOUT : out std_logic_vector(DATA_WIDTH - 1 downto 0);
            isGreaterEq : out std_logic
        );
    end component;

    -- Signal declarations
    signal DINL : std_logic_vector(4 downto 0); -- 5 bits for DINL
    signal DINR : std_logic_vector(3 downto 0); -- 4 bits for DINR
    signal DOUT : std_logic_vector(3 downto 0); -- Output
    signal isGreaterEq : std_logic;

begin
    -- Instantiate the comparator as a component
    dut: comparator
        generic map (DATA_WIDTH => 4)
        port map (
            DINL => DINL,
            DINR => DINR,
            DOUT => DOUT,
            isGreaterEq => isGreaterEq
        );
    
    -- Testbench process
    process
    begin
        -- Test case 1: 
        DINL <= "10100"; 
        DINR <= "1010";  
        wait for 10 ns;

        -- Test case 2: 
        DINL <= "10001"; 
        DINR <= "0111";  
        wait for 10 ns;

        -- Test case 3: 
        DINL <= "00101"; 
        DINR <= "1010";  
        wait for 10 ns;

        -- Test case 4: 
        DINL <= "00000"; 
        DINR <= "0000";  
        wait for 10 ns;

        -- Test case 5:
        DINL <= "11010"; 
        DINR <= "1110";  
        wait for 10 ns;

        -- Test case 6: 
        DINL <= "00100"; 
        DINR <= "1101"; 
        wait for 10 ns;

        -- Test case 7: 
        DINL <= "01111"; 
        DINR <= "1111";  
        wait for 10 ns;

        -- Test case 8: 
        DINL <= "00011"; 
        DINR <= "0111";  
        wait for 10 ns;

        -- Stop simulation
        wait;
    end process;
end architecture testbench;
