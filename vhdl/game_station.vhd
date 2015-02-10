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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity GameStation is
	Port (
		-- clock signals
		fpga_clk	: in		STD_LOGIC;
		rst				: in		STD_LOGIC;
		buttons		: in		STD_LOGIC_VECTOR (3 downto 0);	-- down, up, right, left
		sw				: in		STD_LOGIC_VECTOR (7 downto 0);	-- game selection
		-- Wii Nunchuck signals (I2C)
		wii_sda		: inout std_logic;
		wii_scl		: inout	std_logic;
		-- vga interface outputs
		vga_red 	: out		STD_LOGIC_VECTOR (2 downto 0);
		vga_green : out		STD_LOGIC_VECTOR (2 downto 0);
		vga_blue 	: out		STD_LOGIC_VECTOR (1 downto 0);
		vga_hsync : out		STD_LOGIC;
		vga_vsync : out		STD_LOGIC;
		-- seven segment's outputs
		sseg_ca		: out		STD_LOGIC_VECTOR (7 downto 0);
		sseg_an		:	inout		STD_LOGIC_VECTOR (3 downto 0);
		-- test outputs
		counter_led : out STD_LOGIC := '0');
end GameStation;

architecture Behavioral of GameStation is
	signal clk25				:	std_logic;
	signal clk40				:	std_logic;
	signal clk100				:	std_logic;
	signal vread_inv		: std_logic;					-- Negated vread
	signal vread				: std_logic;
	signal hpos     		: std_logic_vector (10 downto 0);
	signal vpos     		: std_logic_vector (10 downto 0);
	signal vwrite				: std_logic;
	signal write_hpos		: std_logic_vector (10 downto 0);
	signal write_vpos		: std_logic_vector (10 downto 0);
	signal write_red 		: std_logic_vector (2 downto 0);
	signal write_green 	: std_logic_vector (2 downto 0);
	signal write_blue 	: std_logic_vector (1 downto 0);
	signal locked				: std_logic;					-- clock locked
	signal sseg_data		: std_logic_vector (15 downto 0);	-- Seven segment data

	component VgaRefComp
		port (
			CLK_25MHz  : in    std_logic;
			CLK_40MHz  : in    std_logic; 
			RESOLUTION : in    std_logic;
			RST        : in    std_logic;
			BLANK      : out   std_logic;
			HCOUNT     : out   std_logic_vector (10 downto 0); 
			HS         : out   std_logic;
			VCOUNT     : out   std_logic_vector (10 downto 0); 
			VS         : out   std_logic
		);
  end component;
	
	COMPONENT GameEngine
		PORT(
			clk 			: IN std_logic;
			reset 		: IN std_logic;
			btns			: in std_logic_vector (3 downto 0);
			sw				: in		STD_LOGIC_VECTOR (7 downto 0);
			i2c_sda		: inout std_logic;
			i2c_scl		: inout	std_logic;			
			clk25 		: in		STD_LOGIC;
			seg_ca 		: out 	STD_LOGIC_VECTOR (7 downto 0);
			seg_an		: inout STD_LOGIC_VECTOR (3 downto 0);
			vread 		: IN std_logic;
			read_hpos : IN std_logic_vector(10 downto 0);
			read_vpos : IN std_logic_vector(10 downto 0);          
			out_red 	: OUT std_logic_vector(2 downto 0);
			out_green : OUT std_logic_vector(2 downto 0);
			out_blue 	: OUT std_logic_vector(1 downto 0)
		);
	END COMPONENT;
	
	component dcm_40
		port (
			CLK_IN1			: in     std_logic;
			CLK_OUT_25	: out    std_logic;
			CLK_OUT_40	: out    std_logic;
			CLK_OUT_100	: out		 std_logic;
			RESET				: in     std_logic;
			LOCKED			: out    std_logic
		);
	end component;
	
begin
	vread <= not vread_inv;

	clk_signal : dcm_40 port map (
    CLK_IN1 			=> fpga_clk,
    CLK_OUT_40 		=> clk40,
    CLK_OUT_25 		=> clk25,
		CLK_OUT_100		=> clk100,
    RESET  				=> rst,
    LOCKED 				=> locked
	);

	vga_ref_comp : VgaRefComp port map (
		CLK_25MHz 	=> clk25,
		CLK_40MHz		=> clk40,
		RESOLUTION	=> '1',				-- 1 for 800x600 and 0 for = 640x480
		RST					=> rst,
		BLANK				=> vread_inv,
		HCOUNT			=> hpos,
		HS					=> vga_hsync,
		VCOUNT			=> vpos,
		VS					=> vga_vsync
	);
	
	game_engine: GameEngine PORT MAP(
		clk 				=> clk100,
		reset 			=> rst,
		btns				=> buttons,
		sw					=> sw,
		i2c_sda			=> wii_sda,
		i2c_scl			=> wii_scl,
		clk25				=> clk25,
		seg_ca			=> sseg_ca,
		seg_an			=> sseg_an,
		vread 			=> vread,		-- not 'blank' signal
		read_hpos 	=> hpos,
		read_vpos 	=> vpos,
		out_red 		=> vga_red,
		out_green 	=> vga_green,
		out_blue 		=> vga_blue
	);

	-- testing flashing led
	process(rst, clk25)
		variable count : integer range 0 to 100;
	begin
		if rst = '1' then
			count := 0;
		elsif rising_edge(clk25) then
			if count > 10000 then 
				count := 0;
			else
				count := count + 1;
				if count > 5000 then
					counter_led <= '1';
				else
					counter_led <= '0';
				end if;
			end if;
		end if;
	end process;

end Behavioral;

