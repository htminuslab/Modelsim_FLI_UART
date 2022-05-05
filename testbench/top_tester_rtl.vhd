---------------------------------------------------------------------------------------------------
-- Modelsim_FLI_UART
--
-- Testbench Stimuli generator
--
-- https://github.com/htminuslab            
--  
---------------------------------------------------------------------------------------------------
-- Version   Author          Date          Changes
-- 0.1       Hans Tiggeler   13 May 2003   Tested on Modelsim SE 5.7b   
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;

entity top_tester is
   port( 
      RDRF   : IN     std_logic;
      RXREG  : IN     std_logic_vector (7 DOWNTO 0);
      TDRE   : IN     std_logic;
      CLK    : OUT    std_logic;
      RD     : OUT    std_logic;
      RESETN : OUT    std_logic;
      TXREG  : OUT    std_logic_vector (7 DOWNTO 0);
      WR     : OUT    std_logic);
end entity top_tester;


architecture rtl of top_tester is
	
	signal clk_s    : std_logic := '0';					
	signal resetn_s : std_logic := '0';

begin

	resetn_s <= '1' after 136 us;
	RESETN  <= resetn_s;

	clk_s   <= NOT clk_s after 1627.6042 ns;		-- Test UART clock, 9600bps*16
	CLK     <= clk_s;
	

	-----------------------------------------------------------------------------------------------
	-- Echo characters back to terminal, press ESC to stop
	-----------------------------------------------------------------------------------------------
	process
	begin
		WR <= '0';
		RD <= '0';
		wait for 200 us;
		
		loop
			wait until rising_edge(RDRF);
			wait until rising_edge(clk_s); 		
			RD <= '1';
			wait until rising_edge(clk_s); 
			RD <= '0';			
			TXREG <= RXREG;
			exit when RXREG=X"40";					-- @ character
			WR <= '1';
			wait until rising_edge(clk_s); 
			WR <= '0';
		end loop;

		STOP(0);
		wait;
		
	end process;
			
END ARCHITECTURE rtl;

