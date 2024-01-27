
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


library matrix_multiplier_library;
use matrix_multiplier_library.all;

entity rx_buffer is 
  port ( 
    
    -- AXI Clocks and Resets Interface
    i_aclk              : in std_logic;
    i_areset_n          : in std_logic;
    
    -- AXI Slave Interface (RX)
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
    
    i_rx_fifo_read        : in  std_logic;
    o_rx_data             : out std_logic_vector(63 downto 0);    

    o_rx_fifo_e           : out std_logic;         
    o_rx_fifo_ae          : out std_logic;         
    o_rx_fifo_count       : out std_logic_vector(9 downto 0);         
    o_rx_fifo_oflow       : out std_logic;         
    o_rx_fifo_uflow       : out std_logic;         
    o_rx_fifo_db          : out std_logic;         
    o_rx_fifo_sb          : out std_logic  

  );
end rx_buffer;

architecture rtl of rx_buffer is  
  
 

  ---------------------------------------------------------------------------------------------------
  -- Signal declarations
  ---------------------------------------------------------------------------------------------------
        
  signal rx_fifo_af     : std_logic;
  signal rx_valid       : std_logic;  
  signal rx_data        : std_logic_vector(63 downto 0);
  ---------------------------------------------------------------------------------------------------
  -- Component declarations
  ---------------------------------------------------------------------------------------------------
 

begin
  

    
  u_axi_slave: entity matrix_multiplier_library.axi_slave 
  port map(   
      i_aclk                => i_aclk,
      i_areset_n            => i_areset_n,
      
      i_s_axi_awid          => i_s_axi_awid    ,
      i_s_axi_awaddr        => i_s_axi_awaddr  ,
      i_s_axi_awlen         => i_s_axi_awlen   ,
      i_s_axi_awsize        => i_s_axi_awsize  ,
      i_s_axi_awburst       => i_s_axi_awburst ,
      i_s_axi_awlock        => i_s_axi_awlock  ,
      i_s_axi_awcache       => i_s_axi_awcache ,
      i_s_axi_awprot        => i_s_axi_awprot  ,
      i_s_axi_awvalid       => i_s_axi_awvalid ,
      o_s_axi_awready       => o_s_axi_awready ,
      i_s_axi_wdata         => i_s_axi_wdata   ,
      i_s_axi_wstrb         => i_s_axi_wstrb   ,
      i_s_axi_wlast         => i_s_axi_wlast   ,
      i_s_axi_wvalid        => i_s_axi_wvalid  ,
      o_s_axi_wready        => o_s_axi_wready  ,
      o_s_axi_bid           => o_s_axi_bid     ,
      o_s_axi_bresp         => o_s_axi_bresp   ,
      o_s_axi_bvalid        => o_s_axi_bvalid  ,
      i_s_axi_bready        => i_s_axi_bready  ,
      i_s_axi_arid          => i_s_axi_arid    ,
      i_s_axi_araddr        => i_s_axi_araddr  ,
      i_s_axi_arlen         => i_s_axi_arlen   ,        
      i_s_axi_arsize        => i_s_axi_arsize  ,
      i_s_axi_arburst       => i_s_axi_arburst ,
      i_s_axi_arlock        => i_s_axi_arlock  ,
      i_s_axi_arcache       => i_s_axi_arcache ,
      i_s_axi_arprot        => i_s_axi_arprot  ,
      i_s_axi_arvalid       => i_s_axi_arvalid ,
      o_s_axi_arready       => o_s_axi_arready ,
      o_s_axi_rid           => o_s_axi_rid     ,
      o_s_axi_rdata         => o_s_axi_rdata   ,
      o_s_axi_rresp         => o_s_axi_rresp   ,
      o_s_axi_rlast         => o_s_axi_rlast   ,
      o_s_axi_rvalid        => o_s_axi_rvalid  ,
      i_s_axi_rready        => i_s_axi_rready  ,
                  
      i_rx_fifo_af          => rx_fifo_af,
      o_rx_valid            => rx_valid,         
      o_rx_data             => rx_data
  ); 

 
  u_rx_fifo: entity matrix_multiplier_library.fifo_64x512
    generic map(
      AEVAL    => 4,   
      AFVAL    => 500
    )
    port map(
        -- Inputs
        CLK        => i_aclk,
        RESET_N    => i_areset_n,
        DATA       => rx_data,
        RE         => i_rx_fifo_read,
        WE         => rx_valid,
        -- Outputs
        AEMPTY     => o_rx_fifo_ae,
        AFULL      => rx_fifo_af,
        DB_DETECT  => o_rx_fifo_db,
        EMPTY      => o_rx_fifo_e,
        FULL       => open,
        OVERFLOW   => o_rx_fifo_oflow,
        Q          => o_rx_data,
        RDCNT      => o_rx_fifo_count,
        SB_CORRECT => o_rx_fifo_sb,
        UNDERFLOW  => o_rx_fifo_uflow
        ); 
end rtl;