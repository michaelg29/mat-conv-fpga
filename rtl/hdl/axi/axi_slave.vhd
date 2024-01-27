

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_slave is 
    port (   
        i_aclk                : in  std_logic;   
        i_areset_n            : in  std_logic;  
        
        i_s_axi_awid          : in  std_logic_vector(3 downto 0); 
        i_s_axi_awaddr        : in  std_logic_vector(31 downto 0);      
        i_s_axi_awlen         : in  std_logic_vector(3 downto 0); 
        i_s_axi_awsize        : in  std_logic_vector(2 downto 0);  
        i_s_axi_awburst       : in  std_logic_vector(1 downto 0);  
        i_s_axi_awlock        : in  std_logic; 
        i_s_axi_awcache       : in  std_logic_vector(3 downto 0); 
        i_s_axi_awprot        : in  std_logic_vector(2 downto 0);  
        i_s_axi_awvalid       : in  std_logic;    
        o_s_axi_awready       : out std_logic; 
        i_s_axi_wdata         : in  std_logic_vector(63 downto 0); 
        i_s_axi_wstrb         : in  std_logic_vector(7 downto 0); 
        i_s_axi_wlast         : in  std_logic;          
        i_s_axi_wvalid        : in  std_logic;           
        o_s_axi_wready        : out std_logic;    
        o_s_axi_bid           : out std_logic_vector(3 downto 0);
        o_s_axi_bresp         : out std_logic_vector(1 downto 0);    
        o_s_axi_bvalid        : out std_logic;        
        i_s_axi_bready        : in  std_logic;                          
        i_s_axi_arid          : in  std_logic_vector(3 downto 0);  
        i_s_axi_araddr        : in  std_logic_vector(31 downto 0);           
        i_s_axi_arlen         : in  std_logic_vector(3 downto 0);                            
        i_s_axi_arsize        : in  std_logic_vector(2 downto 0);      
        i_s_axi_arburst       : in  std_logic_vector(1 downto 0); 
        i_s_axi_arlock        : in  std_logic;    
        i_s_axi_arcache       : in  std_logic_vector(3 downto 0);    
        i_s_axi_arprot        : in  std_logic_vector(2 downto 0);   
        i_s_axi_arvalid       : in  std_logic;  
        o_s_axi_arready       : out std_logic;  
        o_s_axi_rid           : out std_logic_vector(3 downto 0);  
        o_s_axi_rdata         : out std_logic_vector(63 downto 0);  
        o_s_axi_rresp         : out std_logic_vector(1 downto 0);  
        o_s_axi_rlast         : out std_logic;                     
        o_s_axi_rvalid        : out std_logic;         
        i_s_axi_rready        : in  std_logic;
      
        i_rx_fifo_af          : in  std_logic;
        o_rx_valid            : out std_logic;       
        o_rx_data             : out std_logic_vector(63 downto 0) 

    );
end axi_slave;

architecture arch_imp of axi_slave is

    -- AXI signals 
    signal axi_awready    : std_logic;
    signal axi_wready     : std_logic;
    signal axi_bresp      : std_logic_vector(1 downto 0); 
    signal axi_bvalid     : std_logic;
    
    -- The axi_awv_awr_flag flag marks the presence of write address valid
    signal axi_awv_awr_flag : std_logic; 

 
 
begin
    -- I/O Connections assignments
                           
    o_s_axi_awready   <= axi_awready;
    o_s_axi_wready    <= axi_wready;
    o_s_axi_bresp     <= axi_bresp;  
    o_s_axi_bvalid    <= axi_bvalid;
    o_s_axi_bid       <= i_s_axi_awid;

    -- The AXI slave reads are not supported
    o_s_axi_arready   <= '0';           
    o_s_axi_rdata     <= (others=>'0');
    o_s_axi_rresp     <= "10"; --SLVERR
    o_s_axi_rlast     <= '0'; 
    o_s_axi_rvalid    <= '0';
    o_s_axi_rid       <= (others=>'0');

    -- Implement axi_awready generation
    -- axi_awready is asserted for one i_aclk clock cycle when both
    -- i_s_axi_awvalid and i_s_axi_wvalid are asserted. axi_awready is
    -- de-asserted when reset is low.
    p_awready: process (i_aclk)
    begin
      if rising_edge(i_aclk) then 
        if i_areset_n = '0' then
          axi_awready <= '0';
          axi_awv_awr_flag <= '0';
        else
          if (axi_awready = '0' and i_s_axi_awvalid = '1' and axi_awv_awr_flag = '0') then
            -- slave is ready to accept an address and
            -- associated control signals
            axi_awv_awr_flag  <= '1'; -- used for generation of bresp() and bvalid
            axi_awready <= '1';
          elsif (i_s_axi_wlast = '1' and axi_wready = '1') then 
          -- preparing to accept next address after current write burst tx completion
            axi_awv_awr_flag  <= '0';
          else
            axi_awready <= '0';
          end if;
        end if;
      end if;         
    end process p_awready; 
 

    -- Implement axi_wready generation
    p_wready: process (i_aclk)
    begin
      if rising_edge(i_aclk) then 
        if i_areset_n = '0' then
          axi_wready <= '0';
        else
          if i_rx_fifo_af = '1' then
            axi_wready <= '0';

          elsif (axi_wready = '0' and i_s_axi_wvalid = '1' and axi_awv_awr_flag = '1') then
            axi_wready <= '1';
            
          elsif (i_s_axi_wlast = '1' and axi_wready = '1') then
            axi_wready <= '0';
          end if;
        end if;
      end if;         
    end process p_wready; 

    -- Implement write response logic generation
    -- The write response and response valid signals are asserted by the slave 
    -- when axi_wready, i_s_axi_wvalid, axi_wready and i_s_axi_wvalid are asserted.  
    -- This marks the acceptance of address and indicates the status of 
    -- write transaction.
    p_response: process (i_aclk)
    begin
      if rising_edge(i_aclk) then 
        if i_areset_n = '0' then
          axi_bvalid  <= '0';
          axi_bresp  <= "00"; --need to work more on the responses 
          -- ADD SLVERR ("10") on   
          -- ADD DECERR ("11") on write to invalid address (not 64 bits align)
        else
          if (axi_awv_awr_flag = '1' and axi_wready = '1' and i_s_axi_wvalid = '1' and axi_bvalid = '0' and i_s_axi_wlast = '1' ) then
            axi_bvalid <= '1';
            axi_bresp  <= "00"; 
          elsif (i_s_axi_bready = '1' and axi_bvalid = '1') then 
            axi_bvalid <= '0';                      
          end if;
        end if;
      end if;         
    end process p_response; 

     ------------------------------------------
     -- Out....
     ------------------------------------------

    p_output: process (i_aclk)
    begin
      if rising_edge(i_aclk) then
        if i_areset_n = '0' then
          o_rx_valid  <= '0';
          o_rx_data   <= (others=>'0');
        else                        
          o_rx_valid  <= axi_wready and i_s_axi_wvalid;
          o_rx_data   <= i_s_axi_wdata;
        end if;
      end if;
    end  process p_output;

       

end arch_imp;
