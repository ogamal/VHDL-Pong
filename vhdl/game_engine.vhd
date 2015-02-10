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

use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
--use ieee.math_real.all; -- for UNIFORM, TRUNC

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity GameEngine is
	Port (
		clk					: in 		STD_LOGIC;
		reset				:	in		STD_LOGIC;
		btns				: in		STD_LOGIC_VECTOR (3 downto 0);		-- down, up, right, left
		sw					: in 		STD_LOGIC_VECTOR (7 downto 0);		-- game selection
		-- Wii Nunchuck signals
		i2c_sda			: inout std_logic;			-- Wii data
		i2c_scl			: inout	std_logic;			-- Wii clock
		-- Seven Segment signals
		clk25 			: in		STD_LOGIC;
		seg_ca 			: out 	STD_LOGIC_VECTOR (7 downto 0);
		seg_an			: inout STD_LOGIC_VECTOR (3 downto 0);
		-- VGA read input signals
		vread				: in		STD_LOGIC;			-- 'blank' signal negated
		read_hpos		: in		STD_LOGIC_VECTOR (10 downto 0);
		read_vpos		:	in		STD_LOGIC_VECTOR (10 downto 0);
		-- VGA output signals
		out_red 		: out		STD_LOGIC_VECTOR (2 downto 0);
		out_green 	: out		STD_LOGIC_VECTOR (2 downto 0);
		out_blue 		: out		STD_LOGIC_VECTOR (1 downto 0));
end GameEngine;

architecture Behavioral of GameEngine is
	signal ctrl_clk		: std_logic := '0';

	type ram_type is array (149 downto 0) of std_logic_vector(199 downto 0);
	signal vga_buffer	: ram_type := (others => (others => '0'));

	-- vga scanner signals
	signal color 			: std_logic_vector(7 downto 0) := x"00";
	signal hpos				: integer range 0 to 799;		-- vga scanner horizontal position
	signal vpos				: integer range 0 to 599;		-- vga scanner vertical position

	-- object location on 200x150 grid
	signal obj_hpos		: integer range 0 to 799 := 200;
	signal obj_vpos		: integer range 0 to 599 := 299;

	-- pads specs
	-- each pad has height of 30 and width of 2
	-- left_racket will be the player, right_racket is the computer
	signal left_racket, right_racket	: integer range 0 to 149 := 74;

	-- Wiichuck FSM signals
	type wii_state_type is (init, get_data);
	signal wii_state			: wii_state_type;
	signal wii_state_next : wii_state_type;
	signal busy_prev 			: std_logic;

	-- Wii Nunchuck data signals
	signal wii_joy_x		: std_logic_vector(7 downto 0);
	signal wii_joy_y		: std_logic_vector(7 downto 0);
	signal wii_accel_x	: std_logic_vector(9 downto 0);
	signal wii_accel_y	: std_logic_vector(9 downto 0);
	signal wii_accel_z	: std_logic_vector(9 downto 0);
	signal wii_btn_c		: std_logic;
	signal wii_btn_z		: std_logic;

	-- I2C signals
	signal i2c_ena			: std_logic;
	signal i2c_rw				: std_logic;
	signal i2c_busy			: std_logic;
	signal i2c_ack_err	: std_logic;
	signal i2c_reset_n	: std_logic;
	signal i2c_data_rd	: std_logic_vector (7 downto 0);
	signal i2c_data_wr	: std_logic_vector (7 downto 0);

	-- I2C ports
	COMPONENT i2c_master
		PORT(
			clk       : IN     STD_LOGIC;                    --system clock
			reset_n   : IN     STD_LOGIC;                    --active low reset
			ena       : IN     STD_LOGIC;                    --latch in command
			addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
			rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
			data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
			busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
			data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
			ack_error : OUT 	 STD_LOGIC;                    --flag if improper acknowledge from slave
			sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
			scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
	END COMPONENT;

	-- Seven Segement's ports
	signal seven_seg_data : std_logic_vector (15 downto 0) := (others => '0');
	component SevenSeg
		port (
			clk 				: in		STD_LOGIC;
			reset 			: in		STD_LOGIC;
			data 				: in  	STD_LOGIC_VECTOR (15 downto 0);
			seg_ca 			: out 	STD_LOGIC_VECTOR (7 downto 0);
			seg_an			: inout 	STD_LOGIC_VECTOR (3 downto 0)
		);
	end component;

--	-- random number generator
--	signal random_num1, random_num2 : std_logic_vector (149 downto 0);
--	COMPONENT random
--	PORT(
--		clk : IN std_logic;
--		random_num1 : OUT std_logic_vector(149 downto 0);
--		random_num2 : OUT std_logic_vector(149 downto 0)
--		);
--	END COMPONENT;

begin
	-- converting 800x600 screen to 200x150
	hpos <= conv_integer(read_hpos) / 4;
	vpos <= conv_integer(read_vpos) / 4;

	i2c_reset_n <= not reset;
	-- VGA screen's sanity test
	-- vga_buffer(0)(0) <= '1';
	-- vga_buffer(149)(199) <= '1';

	-- I2C insta
	Inst_i2c_master: i2c_master PORT MAP(
		clk 			=> clk,
		reset_n 	=> i2c_reset_n,
		ena 			=> i2c_ena,
		addr 			=> "1010010",			-- i2c address 0x52
		rw 				=> i2c_rw,
		data_wr 	=> i2c_data_wr,
		busy 			=> i2c_busy,
		data_rd 	=> i2c_data_rd,
		ack_error => i2c_ack_err,
		sda 			=> i2c_sda,
		scl 			=> i2c_scl
	);

	-- 7-segment instantiation
	seven_seg: SevenSeg PORT MAP(
		clk 			=> clk25,
		reset 		=> reset,
		data 			=> seven_seg_data,
		seg_ca 		=> seg_ca,
		seg_an 		=> seg_an
	);

--	-- random number generation
--	rand: random PORT MAP(
--		clk => clk,
--		random_num1 => random_num1,
--		random_num2 => random_num2
--	);


	-- Converting the clock to lower clock (ctrl_clk)
	process(clk)
		variable count : integer range 0 to 1250000;
	begin
		if rising_edge(clk) then
			if reset = '1' then
				ctrl_clk <= '0';
			else
				if count = 1250000 then
					ctrl_clk <= not ctrl_clk;
					count := 0;
				else
					count := count + 1;
				end if;
			end if;
		end if;
	end process;

	-- Move the object using the ctrl_clk
	process(ctrl_clk, reset, btns)
		 variable right_racket_dir : std_logic := '0';
	begin
		if reset = '1' then
			left_racket <= 74;
			right_racket <= 74;
		else
			if rising_edge(ctrl_clk) then
				-- Moving the left player
				-- down
				if (btns(2) = '1' and left_racket < 132) then
					left_racket <= left_racket + 1;
				end if;
				-- up
				if (btns(3) = '1' and left_racket > 15) then
					left_racket <= left_racket - 1;
				end if;

				-- Moving the right player (computer-controled)
				if (obj_vpos/4 > right_racket) then
					right_racket_dir := '1';
				else
					right_racket_dir := '0';
				end if;
				if (obj_hpos/4 > 99 and (right_racket-(obj_vpos/4) > 3 or right_racket-(obj_vpos/4) < -3)) then
					if (right_racket_dir = '1' and right_racket < 132) then
						right_racket <= right_racket + 1;
					elsif (right_racket_dir = '0' and right_racket > 15) then
						 right_racket <= right_racket - 1;
					end if;
				else
					right_racket <= right_racket;
				end if;

				-- Wii  and other controllers - the wii is not working unfortunately
				-- left
--				if btns(0) = '1' and obj_hpos > 0 then
--					obj_hpos <= obj_hpos - 4;
--				end if;
--				-- right
--				if (btns(1) = '1' or conv_integer(wii_joy_x) > 140) and obj_hpos < 799 then
--					obj_hpos <= obj_hpos + 4;
--				end if;
--				-- up
--				if (btns(2) = '1' or wii_btn_c = '1') and obj_vpos < 599 then
--					obj_vpos <= obj_vpos + 4;
--				end if;
--				-- down
--				if (btns(3) = '1' or wii_btn_z = '1') and obj_vpos > 0 then
--					obj_vpos <= obj_vpos - 4;
--				end if;
			end if;	-- end control clock
		end if;
	end process;

	-- ball controller and collision detector
	process(ctrl_clk)
		type direction_type is (start, right_down, right_up, left_down, left_up);
		-- variables for game 1 (snake)
		variable ball_direction : direction_type := start;
	begin
		if rising_edge(ctrl_clk) then
			if reset = '1' then
				ball_direction := start;
				seven_seg_data(3 downto 0) <= x"0";
				seven_seg_data(15 downto 12) <= x"0";
			else
				-- Direction and collision detection
				case ball_direction is
					when start =>
						obj_hpos <= 200;
						obj_vpos <= 299;
						ball_direction := right_down;
					when right_down =>
						-- did the ball hit the bottom wall?
						if (obj_vpos + 12 > 147*4) then
							ball_direction := right_up;
							obj_vpos <= obj_vpos - 4;
							obj_hpos <= obj_hpos + 4;
						-- did the ball reach the right racket?
						elsif (obj_hpos + 12 > 194*4) then
							ball_direction := left_down;
							obj_vpos <= obj_vpos + 4;
							obj_hpos <= obj_hpos - 4;
						-- else continue getting right down
						else
							obj_vpos <= obj_vpos + 4;
							obj_hpos <= obj_hpos + 4;
						end if;
					when right_up =>
						-- did the ball hit the top wall?
						if (obj_vpos - 12 < 2*4) then
							ball_direction := right_down;
							obj_vpos <= obj_vpos + 4;
							obj_hpos <= obj_hpos + 4;
						-- did the ball hit the right ricket?
						elsif (obj_hpos + 12 > 194*4) then
							ball_direction := left_up;
							obj_vpos <= obj_vpos - 4;
							obj_hpos <= obj_hpos - 4;
						else
							obj_vpos <= obj_vpos - 4;
							obj_hpos <= obj_hpos + 4;
						end if;
					when left_up =>
					-- did the ball hit the top wall?
						if (obj_vpos - 12 < 2*4) then
							ball_direction := left_down;
							obj_vpos <= obj_vpos + 4;
							obj_hpos <= obj_hpos - 4;
						-- did the ball hit the left ricket?
						elsif (obj_hpos - 12 < 4*4) then
							ball_direction := right_up;
							obj_vpos <= obj_vpos - 4;
							obj_hpos <= obj_hpos + 4;
						else
							obj_vpos <= obj_vpos - 4;
							obj_hpos <= obj_hpos - 4;
						end if;
					when left_down =>
						-- did the ball hit the bottom wall?
						if (obj_vpos + 12 > 147*4) then
							ball_direction := left_up;
							obj_vpos <= obj_vpos - 4;
							obj_hpos <= obj_hpos - 4;
						-- did the ball hit the right ricket?
						elsif (obj_hpos - 12 < 4*4) then
							ball_direction := right_down;
							obj_vpos <= obj_vpos + 4;
							obj_hpos <= obj_hpos + 4;
						else
							obj_vpos <= obj_vpos + 4;
							obj_hpos <= obj_hpos - 4;
						end if;
					when others =>
						ball_direction := start;
				end case;

				-- Goal detection (point for computer)
				if (obj_hpos-12 < 4*4) and not ((obj_vpos+8)/4 < left_racket+15 and (obj_vpos-8)/4 > left_racket-15) then
					ball_direction := start;
					seven_seg_data(15 downto 12) <= seven_seg_data(15 downto 12) + '1';
				end if;
				-- Goal detection (point for player)
				if (obj_hpos-12 > 194*4) and not ((obj_vpos+8)/4 < right_racket+15 and (obj_vpos-8)/4 > right_racket-15) then
					ball_direction := start;
					seven_seg_data(3 downto 0) <= seven_seg_data(3 downto 0) + '1';
				end if;

				-- Restart game if any scores more than 7
				if seven_seg_data(3 downto 0) > x"7" or seven_seg_data(15 downto 12) > x"7" then
					seven_seg_data(3 downto 0) <= x"0";
					seven_seg_data(15 downto 12) <= x"0";
					ball_direction := start;
				end if;
			end if;
		end if;
	end process;

	-- Draw pixel by pixel
	process(clk, reset, vread, obj_hpos, obj_vpos, hpos, vpos)
		variable temp : integer;
	begin
		if rising_edge(clk) then
			-- if blank pixel or reset signal write zeros
			if reset = '1' or vread = '0' then
				color <= (others => '0');
			-- if not blank write the color of the pixels
			elsif vread = '1' then
				-- draw battle borders
				if (hpos = 0 or hpos = 99 or hpos = 199) or (vpos = 0 or vpos = 149) then
					color <= "11010010";
				-- draw the background in white
				else
					color <= "11111111";
				end if;

				-- draw the ball
				temp := (obj_vpos-conv_integer(read_vpos))*(obj_vpos-conv_integer(read_vpos));
				temp := temp +(obj_hpos-conv_integer(read_hpos))*(obj_hpos-conv_integer(read_hpos));
				if temp <= 144 and temp >= 36 then
					color <= "11100000";
				end if;

				-- draw left player
				if (vpos < left_racket+16) and (vpos > left_racket-14) and (hpos > 1) and (hpos < 5) then
					color <= "01100011";
				-- draw the right player (computer)
				elsif (vpos < right_racket+16) and (vpos > right_racket-14) and (hpos > 194) and (hpos < 198) then
					color <= "01100011";
				end if;

			end if;
		end if;
	end process;

	-- ouptut color to the VGA ports
	out_red <= color(7 downto 5);
	out_green <= color(4 downto 2);
	out_blue <= color(1 downto 0);

	-- update wii states
	process(clk, wii_state, wii_state_next)
	begin
		if rising_edge(clk) then
			if (reset = '1') then
				wii_state <= init;
			else
				wii_state <= wii_state_next;
			end if;
		end if;
	end process;


end Behavioral;

