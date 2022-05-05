---------------------------------------------------------------------------------------------------
-- Modelsim_FLI_UART
--
-- Top Level
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

entity top is
   generic( 
      CLK16UART : integer := 2);
   port( 
      CLK    : IN     std_logic;
      RESETN : IN     std_logic;
      RX     : IN     std_logic;
      TX     : OUT    std_logic);
end entity top ;

architecture struct of top is

   -- Internal signal declarations
   SIGNAL RD    : std_logic;
   SIGNAL RDRF  : std_logic;
   SIGNAL RXREG : std_logic_vector(7 DOWNTO 0);
   SIGNAL TDRE  : std_logic;
   SIGNAL TXREG : std_logic_vector(7 DOWNTO 0);
   SIGNAL WR    : std_logic;


   -- Component Declarations
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
   
   COMPONENT uart_fli
   PORT (
      CLK    : IN     std_logic ;
      RDRF   : IN     std_logic ;
      RESETN : IN     std_logic ;
      RXREG  : IN     std_logic_vector (7 DOWNTO 0);
      TDRE   : IN     std_logic ;
      RD     : OUT    std_logic ;
      TXREG  : OUT    std_logic_vector (7 DOWNTO 0);
      WR     : OUT    std_logic 
   );
   END COMPONENT uart_fli;

begin

   -- Instance port mappings.
   U_UART : uart
      GENERIC MAP (
         CLK16UART => CLK16UART
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
         TX     => TX,
         RX     => RX
      );
   U_FLI : uart_fli
      PORT MAP (
         CLK    => CLK,
         RDRF   => RDRF,
         RESETN => RESETN,
         RXREG  => RXREG,
         TDRE   => TDRE,
         RD     => RD,
         TXREG  => TXREG,
         WR     => WR
      );

end architecture struct;
