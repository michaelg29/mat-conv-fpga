
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

 

library matrix_multiplier_library;
use matrix_multiplier_library.all;

entity tx_buffer is  
  port ( 
    -- AXI Clocks and Resets Interface
    i_aclk                  : in std_logic;
    i_areset_n              : in std_logic;
    
    -- interface from core
    i_payload_request         : in  std_logic; 
    o_payload_done            : out std_logic;
    i_header_request          : in  std_logic; 
    i_header_status_upd       : in  std_logic; 
    i_header                  : in  TYPE_ARRAY_OF_32BITS(9 downto 0);
    o_header_ack              : out std_logic;

    o_tx_fifo_af              : out std_logic;
    o_tx_fifo_db              : out std_logic;
    o_tx_fifo_sb              : out std_logic;
    o_tx_fifo_oflow           : out std_logic;
    o_tx_fifo_uflow           : out std_logic;
    i_payload_valid           : in  std_logic;
    i_payload_data            : in  std_logic_vector(63 downto 0);


    -- AXI Master Interface (TX)
    o_m_axi_awid            : out std_logic_vector(3 downto 0);  
    o_m_axi_awaddr          : out std_logic_vector(31 downto 0); 
    o_m_axi_awlen           : out std_logic_vector(3 downto 0);                     
    o_m_axi_awsize          : out std_logic_vector(2 downto 0); 
    o_m_axi_awburst         : out std_logic_vector(1 downto 0);  
    o_m_axi_awlock          : out std_logic;           
    o_m_axi_awcache         : out std_logic_vector(3 downto 0);    
    o_m_axi_awprot          : out std_logic_vector(2 downto 0);     
    o_m_axi_awvalid         : out std_logic;                 
    i_m_axi_awready         : in  std_logic;  
    o_m_axi_wdata           : out std_logic_vector(63 downto 0);  
    o_m_axi_wstrb           : out std_logic_vector(7 downto 0); 
    o_m_axi_wlast           : out std_logic;                     
    o_m_axi_wvalid          : out std_logic;   
    i_m_axi_wready          : in  std_logic; 
    i_m_axi_bid             : in  std_logic_vector(3 downto 0);   
    i_m_axi_bresp           : in  std_logic_vector(1 downto 0);   
    i_m_axi_bvalid          : in  std_logic;                     
    o_m_axi_bready          : out std_logic;     
    o_m_axi_arid            : out std_logic_vector(3 downto 0);
    o_m_axi_araddr          : out std_logic_vector(31 downto 0);      
    o_m_axi_arlen           : out std_logic_vector(3 downto 0);                        
    o_m_axi_arsize          : out std_logic_vector(2 downto 0);  
    o_m_axi_arburst         : out std_logic_vector(1 downto 0);    
    o_m_axi_arlock          : out std_logic;       
    o_m_axi_arcache         : out std_logic_vector(3 downto 0);  
    o_m_axi_arprot          : out std_logic_vector(2 downto 0);    
    o_m_axi_arvalid         : out std_logic;                       
    i_m_axi_arready         : in  std_logic;                     
    i_m_axi_rid             : in  std_logic_vector(3 downto 0);  
    i_m_axi_rdata           : in  std_logic_vector(63 downto 0); 
    i_m_axi_rresp           : in  std_logic_vector(1 downto 0);                    
    i_m_axi_rlast           : in  std_logic;                      
    i_m_axi_rvalid          : in  std_logic;          
    o_m_axi_rready          : out std_logic

  );
end tx_buffer;

architecture rtl of tx_buffer is  
  
  ---------------------------------------------------------------------------------------------------
  -- Local Constant declarations
  ---------------------------------------------------------------------------------------------------
   

  ---------------------------------------------------------------------------------------------------
  -- Signal declarations
  ---------------------------------------------------------------------------------------------------
        
                                    
  signal payload_fifo_count : std_logic_vector(9 downto 0);    
  signal payload_read       : std_logic; 
  signal payload_data       : std_logic_vector(63 downto 0);  

  ---------------------------------------------------------------------------------------------------
  -- Component declarations
  ---------------------------------------------------------------------------------------------------
 

begin
  

    
    u_axi_master: entity matrix_multiplier_library.axi_master  
      port map( 
        -- Clocks and Resets Interface
        i_aclk                => i_aclk,
        i_areset_n            => i_areset_n,
                         
        
        i_payload_request     => i_payload_request,
        o_payload_done        => o_payload_done,
        i_header_request      => i_header_request,
        i_header_status_upd   => i_header_status_upd,
        i_header              => i_header,
        o_header_ack          => o_header_ack,
    
        i_payload_fifo_count  => payload_fifo_count,
        o_payload_read        => payload_read,
        i_payload_data        => payload_data,
            
        -- AXI Master Interface (TX)
        o_m_axi_awid            => o_m_axi_awid,
        o_m_axi_awaddr          => o_m_axi_awaddr,
        o_m_axi_awlen           => o_m_axi_awlen,
        o_m_axi_awsize          => o_m_axi_awsize,
        o_m_axi_awburst         => o_m_axi_awburst,
        o_m_axi_awlock          => o_m_axi_awlock,
        o_m_axi_awcache         => o_m_axi_awcache,
        o_m_axi_awprot          => o_m_axi_awprot,
        o_m_axi_awvalid         => o_m_axi_awvalid,
        i_m_axi_awready         => i_m_axi_awready,
        o_m_axi_wdata           => o_m_axi_wdata,
        o_m_axi_wstrb           => o_m_axi_wstrb,
        o_m_axi_wlast           => o_m_axi_wlast,
        o_m_axi_wvalid          => o_m_axi_wvalid,
        i_m_axi_wready          => i_m_axi_wready,
        i_m_axi_bid             => i_m_axi_bid,
        i_m_axi_bresp           => i_m_axi_bresp,
        i_m_axi_bvalid          => i_m_axi_bvalid,
        o_m_axi_bready          => o_m_axi_bready,
        o_m_axi_arid            => o_m_axi_arid,
        o_m_axi_araddr          => o_m_axi_araddr,
        o_m_axi_arlen           => o_m_axi_arlen, 
        o_m_axi_arsize          => o_m_axi_arsize,
        o_m_axi_arburst         => o_m_axi_arburst,
        o_m_axi_arlock          => o_m_axi_arlock,
        o_m_axi_arcache         => o_m_axi_arcache,
        o_m_axi_arprot          => o_m_axi_arprot,
        o_m_axi_arvalid         => o_m_axi_arvalid,
        i_m_axi_arready         => i_m_axi_arready,
        i_m_axi_rid             => i_m_axi_rid,
        i_m_axi_rdata           => i_m_axi_rdata,
        i_m_axi_rresp           => i_m_axi_rresp,
        i_m_axi_rlast           => i_m_axi_rlast,
        i_m_axi_rvalid          => i_m_axi_rvalid,
        o_m_axi_rready          => o_m_axi_rready   


    );
      
  u_tx_payload_fifo: entity matrix_multiplier_library.fifo_64x512
    generic map(
      AEVAL    => 4,   
      AFVAL    => 340
    )
    port map(
      -- Inputs
      CLK        => i_aclk,
      RESET_N    => i_areset_n,
      DATA       => i_payload_data,
      RE         => payload_read,
      WE         => i_payload_valid,
      -- Outputs
      AEMPTY     => open,
      AFULL      => o_tx_fifo_af,
      DB_DETECT  => o_tx_fifo_db,
      EMPTY      => open,
      FULL       => open,
      OVERFLOW   => o_tx_fifo_oflow,
      Q          => payload_data,  
      RDCNT      => payload_fifo_count,  
      SB_CORRECT => o_tx_fifo_sb,
      UNDERFLOW  => o_tx_fifo_uflow
    ); 

end rtl;