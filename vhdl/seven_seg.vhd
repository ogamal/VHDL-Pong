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
use IEEE.STD_LOGIC_ARITH.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SevenSeg is
    Port ( clk 		: in	STD_LOGIC;	-- 25 Mhz clock
           reset 	: in	STD_LOGIC;
           data 	: in  STD_LOGIC_VECTOR (15 downto 0);
           seg_ca : out STD_LOGIC_VECTOR (7 downto 0);		-- bits 0-6 = A-G, bit 7 = dot
           seg_an : inout STD_LOGIC_VECTOR (3 downto 0));	-- select bit 3 = an0, bit 0 = an3
end SevenSeg;

architecture Behavioral of SevenSeg is

	signal data_chunk : std_logic_vector (3 downto 0);
	signal seg_clk		: std_logic;

begin

	
	-- 25 Mhz clock to lower clock
	process(clk)
		variable count : integer range 0 to 12000;
	begin
		if rising_edge(clk) then
			if reset = '1' then
				seg_clk <= '0';
			else
				if count = 12000 then
					seg_clk <= not seg_clk;
					count := 0;
				else
					count := count + 1;
				end if;
			end if;
		end if;
	end process;

	-- pass over all the seven segment's places
	process(clk, reset, seg_clk)
	begin
		if reset = '1' then
			seg_an <= "1110";
		else
			if rising_edge(seg_clk) then
				case seg_an is
					when "0111" => seg_an <= "1110";
					when "1110" => seg_an <= "1101";
					when "1101" => seg_an <= "1011";
					when "1011" => seg_an <= "0111";
					when others => seg_an <= "1110";
				end case;
			end if;
		end if;
	end process;
	
	-- choose place from the data input
	process(seg_an, data)
	begin
		case seg_an is
			when "1110" => data_chunk <= data(3 downto 0);
			when "1101" => data_chunk <= data(7 downto 4);
			when "1011" => data_chunk <= data(11 downto 8);
			when "0111" => data_chunk <= data(15 downto 12);
			when others => data_chunk <= data(3 downto 0);
		end case;
	end process;
	
	-- print the data_chunk
	process(data_chunk)
	begin
		case data_chunk is
			when x"0" => seg_ca <= "00000011";
			when x"1" => seg_ca <= "10011111";
			when x"2" => seg_ca <= "00100101";
			when x"3" => seg_ca <= "00001101";
			when x"4" => seg_ca <= "10011001";
			when x"5" => seg_ca <= "01001001";
			when x"6" => seg_ca <= "01000001";
			when x"7" => seg_ca <= "00011111";
			when x"8" => seg_ca <= "00000001";
			when x"9" => seg_ca <= "00001001";
			when x"A" => seg_ca <= "00010001";
			when x"B" => seg_ca <= "11000001";
			when x"C" => seg_ca <= "01100011";
			when x"D" => seg_ca <= "10000101";
			when x"E" => seg_ca <= "01100001";
			when x"F" => seg_ca <= "01110001";
			when others => seg_ca <= "01110001";
		end case;
	end process;

end Behavioral;

