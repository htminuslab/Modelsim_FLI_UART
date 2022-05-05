---------------------------------------------------------------------------------------------------
-- Modelsim_FLI_UART
--
-- FLI Interface
--
-- https://github.com/htminuslab            
--  
---------------------------------------------------------------------------------------------------
-- Version   Author          Date          Changes
-- 0.1       Hans Tiggeler   13 May 2003   Tested on Modelsim SE 5.7b   
-- 0.2       Hans Tiggeler   02 May 2022   Tested Modelsim 2022.2
---------------------------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY uart_fli IS
   PORT( 
      CLK    : IN     std_logic;
      RDRF   : IN     std_logic;
      RESETN : IN     std_logic;
      RXREG  : IN     std_logic_vector (7 DOWNTO 0);
      TDRE   : IN     std_logic;
      RD     : OUT    std_logic;
      TXREG  : OUT    std_logic_vector (7 DOWNTO 0);
      WR     : OUT    std_logic);
END ENTITY uart_fli ;


architecture rtl of uart_fli is

	attribute foreign : string;
	attribute foreign of rtl: architecture is "cif_init ./uart_fli.dll";

begin	
 	assert false report "*** fli failure ***" severity failure;	-- never called
end rtl;
