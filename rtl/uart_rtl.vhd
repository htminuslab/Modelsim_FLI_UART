---------------------------------------------------------------------------------------------------
-- Modelsim_FLI_UART
--
-- UART
--
-- https://github.com/htminuslab            
--  
---------------------------------------------------------------------------------------------------
-- Version   Author          Date          Changes
-- 0.1       Hans Tiggeler   13 May 2003   Tested on Modelsim SE 5.7b   
-- 0.2       Hans Tiggeler   02 May 2022   Updated VHDL2008, Tested Modelsim 2022.2
---------------------------------------------------------------------------------------------------
LIBRARY ieee;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

entity uart is
   generic(
		CLK16UART   : integer :=96);								-- 14.7456MHz/16/9600
   port(CLK        	: in  std_logic;            					-- cpu clock
        RESETN      : in  std_logic;            					-- Active low sync reset
        WR         	: in  std_logic;            					-- Active high write strobe
		RD        	: in  std_logic;								-- Active high read strobe
		RXREG     	: out std_logic_vector(7 downto 0);				-- output from rx reg
		TXREG      	: in  std_logic_vector(7 downto 0);				-- tx reg
		TDRE		: out std_logic;
		RDRF        : out std_logic;
		TX			: out std_logic;
        RX         	: in  std_logic);            					-- receive pin              
end uart;	 

architecture rtl of uart is 

	signal txreg_s      : std_logic_vector(7 downto 0); 			-- Transmit data register
                      
    signal uartdivcnt_s : integer;-- range 0 to 651; 					-- unsigned(7 downto 0);                 

	signal rxclk16_s    : std_logic;                                	
    signal txclk1_s     : std_logic;                               	-- x1 TX clock
    signal div16_s      : unsigned(3 downto 0); 					-- divide by 16 counter
					    
	signal txshift_s    : std_logic_vector(9 downto 0); 			-- Transmit Shift Register 
					    
	signal txbitcnt_s   : unsigned(3 downto 0); 					-- 9 to 0 bit counter
	signal tsrl_s       : std_logic;								-- latch Data
	signal tsre_re_s	: std_logic;	
	
    type   rxstates is (sHigh,sLow,sData,sLatch,sError);            -- Receive Statemachine
    signal rxstate      : rxstates;
    
	type   txstates is (txidle,txdata); 			       			-- Transmit Statemachine
    signal txstate      : txstates;
	
    signal rxshift_s    : std_logic_vector(8 downto 0);             -- Receive Shift Register (9 bits!) 
    signal rxbitcnt_s   : integer range 0 to 10;
    signal samplecnt_s  : integer range 0 to 15;
              
	signal rsrl_s		: std_logic;								-- Receive Shift Register Latch (RXCLK16)
	signal rsrl_re_s	: std_logic;								-- rsrl rising edge

	component redge                             					-- Rising edge strobe set/reset flag
	generic(RESHL  : std_logic:='1';	 							-- Reset Active High/Low
            RESVAL : std_logic:='0');	 							-- Flag default value after reset
    port(clk       : in  std_logic;    								-- System Clock   
        reset      : in  std_logic;           					
        strobe     : in  std_logic;    								-- Flag assert strobe (slow clock)
        clredge    : in  std_logic;    								-- Rising_edge clear signal
   	    pulse      : out std_logic;	 								-- Rising edge clk wide pulse
   	    flag       : out std_logic);            
	end component;

begin 

	EDGE1 :redge generic map ('0','0') port map (clk,RESETN,rsrl_s,'0',rsrl_re_s,OPEN);
	EDGE2 :redge generic map ('0','1') port map (clk,RESETN,tsrl_s,'0',tsre_re_s,OPEN);

	process(clk)  
    begin 			
		if rising_edge(clk) then
			if RESETN='0' then  									-- Sync Reset                   
				TDRE 	 <= '1';
				RDRF     <= '0';
				txreg_s	 <= (others => '1');
			else
				if WR='1' then 										-- Write clears TDRE
					txreg_s <= TXREG;								-- And transfer data to Transmit Register
					TDRE    <= '0';
				elsif tsre_re_s='1' then
					TDRE    <= '1';
				end if;
				
				if rsrl_re_s='1' then
					RDRF    <= '1';
				elsif RD='1' then			 						-- Read clears RDRF
					RDRF    <= '0';
				end if;
				
			end if;
		end if;
	end process;

    -----------------------------------------------------------------------------------------------
    -- UART bitrate divider, create x16 rx and and x1 txclock
	-- System clock CLK is divided by CLK16UART then by another 16 for TX clock (=baudrate)
    -----------------------------------------------------------------------------------------------
    process(clk)                                                    
    begin
        if rising_edge(clk) then 
            if RESETN='0' then                     
                uartdivcnt_s <= 0;  
				div16_s      <= (others => '0');				
                rxclk16_s    <= '0';
				txclk1_s     <= '0';
            else               
                if uartdivcnt_s=CLK16UART-1 then 
                    uartdivcnt_s <= 0;
                    rxclk16_s    <= '1';
					div16_s <= div16_s + 1;					
					if div16_s="1110" then
						txclk1_s <= '1';
					else
						txclk1_s <= '0';
					end if;					
                else 
					rxclk16_s    <= '0';
					txclk1_s     <= '0';
                    uartdivcnt_s <= uartdivcnt_s + 1;
                end if;	
            end if;
      end if;   
    end process;
	
    -----------------------------------------------------------------------------------------------
    -- RX UART
    -----------------------------------------------------------------------------------------------
    process(clk)  
    begin           
        if rising_edge(clk) then
            if RESETN='0' then                                      -- Sync Reset                   
                RXREG     <= (others => '1');                     -- Sim only 
                rxstate     <= sHigh;                               -- Wait for Rising edge
                samplecnt_s <= 6;
                rxbitcnt_s  <= 0;
                rsrl_s      <= '0';
				rxshift_s   <= (others => '1'); 
            elsif rxclk16_s='1' then                              	-- Only action on Sampling clock
                case rxstate is                       
                    when sHigh => 
                        rsrl_s      <= '0'; 
						samplecnt_s <= 6;
						rxbitcnt_s  <= 0;
                        if RX='1' then                               
                            rxstate <= sHigh;                       -- Wait for falling edge
                        else 
                            rxstate <= sLow;                        -- rx data line is low, start bit?
                        end if;                 
                        
                    when sLow =>                                    -- Next wait 16/2 samples
                        if RX='0' AND samplecnt_s=0 then            -- After 8 samples RX is still low so startbit detected
                            rxstate <= sData;                       -- Start filling RX reg
                            samplecnt_s <= 15;
                        elsif RX='1' then                           -- Not a valid startbit, 
                            rxstate <= sHigh;                         
                        else
                            samplecnt_s <= samplecnt_s-1;			
                        end if;
						
                    when sData =>                                   -- Start logging 8 databits
                        if samplecnt_s=0 then                       -- sample bit
                            rxshift_s <= RX & rxshift_s(8 downto 1);-- 9bits
                            if rxbitcnt_s=8 AND RX='1' then
                                rxstate <= sLatch;    
                            elsif rxbitcnt_s=8 AND RX='0' then      -- Incorrect Stopbit, must be 1
                                rxstate <= sError;    
                            else
                                rxstate <= sData;
                            end if;
                            rxbitcnt_s  <= rxbitcnt_s+1;
							samplecnt_s <= 15;
						else
							samplecnt_s <= samplecnt_s-1;
                        end if;
						
                    when sLatch =>                                  -- Valid frame received latch into rxchar and set RDRF flag
                        RXREG <= rxshift_s(7 downto 0);         
                        rsrl_s  <= '1';                     
                        rxstate <= sHigh;
                    
                    when sError =>
                        if RX='0' then                               
                            rxstate <= sError;                      -- Wait RX to go high again
                        else 
                            rxstate <= sHigh;                       -- Restart checking for falling edge
                        end if; 
                         
                    when others => rxstate <= sHigh;              
                end case;                       
            end if;  
        end if;
    end process;    
    
    -----------------------------------------------------------------------------------------------
    -- TX UART
    -----------------------------------------------------------------------------------------------
	process (clk)  	
    begin        
		if (rising_edge(clk)) then		
			if RESETN='0' then
				txshift_s  <= (others => '1');       				-- init to all '1' (including start bit)                      
				txbitcnt_s <= (others => '0');        				-- bit counter
				txstate    <= txidle;
			else
				if txclk1_s='1' then
					case txstate is
						when txidle =>
							txshift_s  <= (others => '1');      	-- No data, tx continuous 1
							txbitcnt_s <= (others => '0');	
							if TDRE='0' then
								txstate   <= txdata;
								txshift_s <= '1'&txreg_s&'0';      	-- yes, latch it and start shifting 
							end if;
						when txdata =>	
							if tsrl_s='1' AND TDRE='0' then  		-- New data pending
								txshift_s  <= '1'&txreg_s&'0';      -- yes, latch it and start shifting again
								txbitcnt_s <= (others => '0');							
							elsif tsrl_s='1' AND TDRE='1' then	-- No new data pending, goto idle
								txshift_s  <= (others => '1');      -- No data, tx continuous 1
								txbitcnt_s <= (others => '0');	
								txstate    <= txidle;		
							else
								txshift_s  <= '1' & txshift_s(9 downto 1);	-- shift right
								txbitcnt_s <= txbitcnt_s + 1;
							end if; 
						when others => 
							txstate <= txidle;		
					end case;
				end if;
			end if;
		end if;                                               
	end process; 
	
	tsrl_s <= '1' when txbitcnt_s="1001" else '0';
	tx   <= txshift_s(0);                       					-- transmit pin	
	
	   
end rtl;

