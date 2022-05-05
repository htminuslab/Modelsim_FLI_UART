---------------------------------------------------------------------------------------------------
-- Modelsim_FLI_UART
--
-- Testbench
--
-- https://github.com/htminuslab            
--  
---------------------------------------------------------------------------------------------------
-- Version   Author          Date          Changes
-- 0.1       Hans Tiggeler   13 May 2003   Tested on Modelsim SE 5.7b   
-- 0.2       Hans Tiggeler   02 May 2022   Tested Modelsim 2022.2
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;

entity top_tb is
end entity top_tb ;

architecture struct of top_tb is

   -- Internal signal declarations
   SIGNAL CLK    : std_logic;
   SIGNAL FLIRX  : std_logic;
   SIGNAL FLITX  : std_logic;
   SIGNAL RD     : std_logic;
   SIGNAL RDRF   : std_logic;
   SIGNAL RESETN : std_logic;
   SIGNAL RXREG  : std_logic_vector(7 DOWNTO 0);
   SIGNAL TDRE   : std_logic;
   SIGNAL TXREG  : std_logic_vector(7 DOWNTO 0);
   SIGNAL WR     : std_logic;


   -- Component Declarations
   COMPONENT top
   GENERIC (
      CLK16UART : integer := 2
   );
   PORT (
      CLK    : IN     std_logic ;
      RESETN : IN     std_logic ;
      RX     : IN     std_logic ;
      TX     : OUT    std_logic 
   );
   END COMPONENT top;
   
   COMPONENT top_tester
   PORT (
      RDRF   : IN     std_logic ;
      RXREG  : IN     std_logic_vector (7 DOWNTO 0);
      TDRE   : IN     std_logic ;
      CLK    : OUT    std_logic ;
      RD     : OUT    std_logic ;
      RESETN : OUT    std_logic ;
      TXREG  : OUT    std_logic_vector (7 DOWNTO 0);
      WR     : OUT    std_logic 
   );
   END COMPONENT top_tester;
   
   COMPONENT uart
   GENERIC (
      CLK16UART : integer := 96
   );
   PORT (
      CLK    : IN     std_logic;
      RD     : IN     std_logic;
      RESETN : IN     std_logic;
      RX     : IN     std_logic;
      TXREG  : IN     std_logic_vector (7 DOWNTO 0);
      WR     : IN     std_logic;
      RDRF   : OUT    std_logic;
      RXREG  : OUT    std_logic_vector (7 DOWNTO 0);
      TDRE   : OUT    std_logic;
      TX     : OUT    std_logic
   );
   END COMPONENT uart;


BEGIN

   -- Instance port mappings.
   U_DUT : top
      GENERIC MAP (
         CLK16UART => 2
      )
      PORT MAP (
         CLK    => CLK,
         RESETN => RESETN,
         RX     => FLIRX,
         TX     => FLITX
      );
	  
   U_TEST : top_tester
      PORT MAP (
         RDRF   => RDRF,
         RXREG  => RXREG,
         TDRE   => TDRE,
         CLK    => CLK,
         RD     => RD,
         RESETN => RESETN,
         TXREG  => TXREG,
         WR     => WR
      );
	  
   U_UART : uart
      GENERIC MAP (
         CLK16UART => 2
      )
      PORT MAP (
         CLK    => CLK,
         RESETN => RESETN,
         WR     => WR,
         RD     => RD,
         RXREG  => RXREG,
         TXREG  => TXREG,
         TDRE   => TDRE,
         RDRF   => RDRF,
         TX     => FLIRX,
         RX     => FLITX
      );

end architecture struct;
