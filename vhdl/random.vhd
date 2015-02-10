----------------------------------------------------------------------------------
-- Company:  Iowa State University
--           Cpre 583 - Project Group 4
--
-- Engineer: Osama G. Attia - Parth V. Malkan
-- 
-- Create Date:    13:32:33 11/03/2012 
-- Module Name:    vga_test - Behavioral 
-- Project Name: Arcade Game-station
-- Target Devices: Nexys 3
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.math_real.all; -- for UNIFORM, TRUNC

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity random is
	generic (
		width : integer := 150);
	port (
		clk : in std_logic;
		random_num1 : out std_logic_vector (width-1 downto 0);
		random_num2 : out std_logic_vector (width-1 downto 0));
end random;

architecture Behavioral of random is

begin
	
	process(clk)
		variable seed1, seed2: positive;
		-- Random real-number value in range 0 to 1.0
		variable rand1, rand2: real;
		-- Random integer value in range 0..4095
		variable int_rand1, int_rand2: integer;
	begin
		if (rising_edge(clk)) then
			UNIFORM(seed1, seed2, rand1);
			UNIFORM(seed1, seed2, rand2);
			int_rand1 := INTEGER(TRUNC(rand1*100.0));
			int_rand2 := INTEGER(TRUNC(rand2*80.0));
			random_num1 <= std_logic_vector(to_unsigned(int_rand1, random_num1'LENGTH));
			random_num2 <= std_logic_vector(to_unsigned(int_rand2, random_num2'LENGTH));
		end if;		
	end process;


end Behavioral;

