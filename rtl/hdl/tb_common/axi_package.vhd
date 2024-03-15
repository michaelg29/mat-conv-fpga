
library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
        
use std.textio.all;
use work.txt_util.all;       
                       

package AXI_package IS  
    
    
  type tArray_of_64bits  is array(natural range <>) of std_logic_vector(63 downto 0); 
  type tArray_of_32bits  is array(natural range <>) of std_logic_vector(31 downto 0); 
  type tArray_of_9bits   is array(natural range <>) of std_logic_vector(8 downto 0);   
  type axi_in_record_t is
    record                                            
      aclk            : std_logic;                                                         
      aresetn         : std_logic;                        
      m_axi_awready   : std_logic;                           
      m_axi_wready    : std_logic;  
      m_axi_bid       : std_logic_vector(0 downto 0);    
      m_axi_bresp     : std_logic_vector(1 downto 0);                                    
      m_axi_bvalid    : std_logic;   
                                                  
      m_axi_arready   : std_logic;                                             
      m_axi_rid       : std_logic_vector(4 downto 0);                                                      
      m_axi_rdata     : std_logic_vector(63 downto 0);                                  
      m_axi_rresp     : std_logic_vector(1 downto 0);                                          
      m_axi_rlast     : std_logic;                                             
      m_axi_rvalid    : std_logic;  
    end record;    
              
  type axi_out_record_t is
    record   
      m_axi_awid      : std_logic_vector(0 downto 0);  
      m_axi_awaddr    : std_logic_vector(31 downto 0);
      m_axi_awlen     : std_logic_vector(3 downto 0); 
      m_axi_awsize    : std_logic_vector(2 downto 0); 
      m_axi_awburst   : std_logic_vector(1 downto 0); 
      m_axi_awlock    : std_logic;          
      m_axi_awcache   : std_logic_vector(3 downto 0);
      m_axi_awprot    : std_logic_vector(2 downto 0);
      m_axi_awqos     : std_logic_vector(3 downto 0);                                  
      m_axi_awvalid   : std_logic;                                                  
      m_axi_wdata     : std_logic_vector(63 downto 0);                            
      m_axi_wstrb     : std_logic_vector(7 downto 0);
      m_axi_wlast     : std_logic;    
      m_axi_wvalid    : std_logic;                                  
      m_axi_bready    : std_logic;  
      
      m_axi_arid      : std_logic_vector(4 downto 0);           
      m_axi_araddr    : std_logic_vector(31 downto 0);                                      
      m_axi_arlen     : std_logic_vector(3 downto 0);                                     
      m_axi_arsize    : std_logic_vector(2 downto 0);                                     
      m_axi_arburst   : std_logic_vector(1 downto 0);                                    
      m_axi_arlock    : std_logic;                    
      m_axi_arcache   : std_logic_vector(3 downto 0);                                
      m_axi_arprot    : std_logic_vector(2 downto 0);                                     
      m_axi_arqos     : std_logic_vector(3 downto 0);                                       
      m_axi_arvalid   : std_logic;                                       
      m_axi_rready    : std_logic;
    end record;                                                 
                                                           
    
  signal AXI_0_R_CI           : axi_in_record_t; 
  signal AXI_0_R_CO           : axi_out_record_t;   
        
  function to_string_axi(sv: std_logic_vector) 
    return string;            
                                     
  procedure AXI_INTERCYCLE_GAP (
    signal clk  : in    std_logic;
    cycles      : in    integer);                              
                      
  procedure END_SIMULATION (mode : in integer);  

  procedure AXI_INIT  (                                  
    signal ctrl_out     : out   axi_out_record_t);
                            
  procedure AXI_WRITE(                            
    signal ctrl_in      : in    axi_in_record_t;
    signal ctrl_out     : out   axi_out_record_t; 
    constant address    : in    std_logic_vector(31 downto 0);   
    constant len        : in    integer := 1;
    constant data       : in    tArray_of_64bits(255 downto 0);
    constant last_BE    : in    integer := 8;
    constant echo       : in    std_logic := '0');
                                
  procedure RESET(                              
    signal ctrl_in      : in    axi_in_record_t;
    signal ctrl_out     : out   axi_out_record_t;
    signal tid          : inout std_logic_vector(31 downto 0);  
    constant F_ERROR    : in    std_logic_vector(3 downto 0);   
    constant echo       : in    std_logic := '0');
      
  procedure SET_FEATURE(                               
    signal ctrl_in      : in    axi_in_record_t;
    signal ctrl_out     : out   axi_out_record_t;
    signal tid          : inout std_logic_vector(31 downto 0); 
    constant echo       : in    std_logic := '0') ;

  procedure GET_FEATURE(                               
    signal ctrl_in      : in    axi_in_record_t;
    signal ctrl_out     : out   axi_out_record_t;
    constant bank_id    : in    std_logic_vector(0 downto 0);
    signal tid          : inout std_logic_vector(31 downto 0); 
    constant echo       : in    std_logic := '0') ;
             
  procedure READ_UNIQUE_ID(                               
    signal ctrl_in      : in    axi_in_record_t;
    signal ctrl_out     : out   axi_out_record_t;
    constant bank_id    : in    std_logic_vector(0 downto 0); 
    signal tid          : inout std_logic_vector(31 downto 0); 
    constant echo       : in    std_logic := '0');

  procedure GET_BAD_BLOCK_MARKER(                                 
    signal ctrl_in      : in    axi_in_record_t;
    signal ctrl_out     : out   axi_out_record_t;
    constant bank_id    : in    std_logic_vector(0 downto 0); 
    constant lun_id     : in    std_logic_vector(1 downto 0); 
    constant plane_id   : in    std_logic_vector(1 downto 0); 
    constant block_ids  : in    tArray_of_9bits(5 downto 0); 
    signal tid          : inout std_logic_vector(31 downto 0); 
    constant echo       : in    std_logic := '0') ;
    
  procedure SET_BAD_BLOCK_MARKER(                                 
    signal ctrl_in      : in    axi_in_record_t;
    signal ctrl_out     : out   axi_out_record_t;
    constant bank_id    : in    std_logic_vector(0 downto 0); 
    constant lun_id     : in    std_logic_vector(1 downto 0); 
    constant plane_id   : in    std_logic_vector(1 downto 0); 
    constant block_ids  : in    tArray_of_9bits(5 downto 0); 
    signal tid          : inout std_logic_vector(31 downto 0); 
    constant echo       : in    std_logic := '0') ;
    
  procedure ERASE_BLOCK(                               
    signal ctrl_in      : in    axi_in_record_t;
    signal ctrl_out     : out   axi_out_record_t;
    constant bank_id    : in    std_logic_vector(0 downto 0); 
    constant lun_id     : in    std_logic_vector(1 downto 0); 
    constant plane_id   : in    std_logic_vector(1 downto 0); 
    constant block_ids  : in    tArray_of_9bits(5 downto 0); 
    signal tid          : inout std_logic_vector(31 downto 0); 
    constant echo       : in    std_logic := '0') ;
            
  procedure PROGRAM_PAGE(                               
    signal ctrl_in      : in    axi_in_record_t;
    signal ctrl_out     : out   axi_out_record_t; 
    constant length     : in    std_logic_vector(15 downto 0); 
    constant bank_id    : in    std_logic_vector(0 downto 0); 
    constant lun_id     : in    std_logic_vector(1 downto 0); 
    constant plane_id   : in    std_logic_vector(1 downto 0); 
    constant block_ids  : in    tArray_of_9bits(5 downto 0); 
    constant page_id    : in    std_logic_vector(9 downto 0); 
    constant pattern    : in    std_logic_vector(3 downto 0); 
    signal tid          : inout std_logic_vector(31 downto 0); 
    constant echo       : in    std_logic := '0';
    constant pause      : in    std_logic := '0');

  procedure READ_PAGE(                               
    signal ctrl_in      : in    axi_in_record_t;
    signal ctrl_out     : out   axi_out_record_t; 
    constant length     : in    std_logic_vector(15 downto 0); 
    constant bank_id    : in    std_logic_vector(0 downto 0); 
    constant lun_id     : in    std_logic_vector(1 downto 0); 
    constant plane_id   : in    std_logic_vector(1 downto 0); 
    constant block_ids  : in    tArray_of_9bits(5 downto 0); 
    constant page_id    : in    std_logic_vector(9 downto 0); 
    signal tid          : inout std_logic_vector(31 downto 0); 
    constant echo       : in    std_logic := '0') ;
              

end package;

-------------------------------------------------------------------------------
--
package body AXI_package is
                 
  function to_string_axi(sv: std_logic_vector) return string is
    use Std.TextIO.all;
    use IEEE.std_logic_TextIO.all;
    variable lp: line;
    begin
      hwrite(lp, sv);
      return lp.all;
    end;            
          
  procedure AXI_INTERCYCLE_GAP (
    signal clk  : in std_logic;
    cycles      : in integer) is
      begin      
        for i in 0 to cycles-1 loop
          wait until rising_edge(clk);
        end loop;
  end AXI_INTERCYCLE_GAP;  
                     
    
  procedure END_SIMULATION (mode : in integer) is
    begin  
      print(LF  & LF  & "Simulation completed" );  
      print(" " );            
      assert FALSE report "(not a real failure...)"  
                & LF  & "----------------------------------" & LF 
                & "Simulation END" & LF 
                & "----------------------------------" & LF 
                & LF & LF severity failure;        
      wait;
  end END_SIMULATION;  
                    
                      
  procedure AXI_INIT (                                  
    signal ctrl_out     : out   axi_out_record_t) is 
  begin     
    ctrl_out.m_axi_awid      <= (others=>'0'); 
    ctrl_out.m_axi_awaddr    <= (others=>'0');
    ctrl_out.m_axi_awlen     <= (others=>'0');
    ctrl_out.m_axi_awsize    <= (others=>'0');
    ctrl_out.m_axi_awburst   <= (others=>'0');   
    ctrl_out.m_axi_awlock    <= '0';        
    ctrl_out.m_axi_awcache   <= (others=>'0');
    ctrl_out.m_axi_awprot    <= (others=>'0');
    ctrl_out.m_axi_awqos     <= (others=>'0');                                  
    ctrl_out.m_axi_awvalid   <= '0';                                              
    ctrl_out.m_axi_wdata     <= (others=>'0');                          
    ctrl_out.m_axi_wstrb     <= (others=>'0');
    ctrl_out.m_axi_wlast     <= '0';
    ctrl_out.m_axi_wvalid    <= '0';                              
    ctrl_out.m_axi_bready    <= '0';
    
    ctrl_out.m_axi_arid      <= (others=>'0');         
    ctrl_out.m_axi_araddr    <= (others=>'0');                                     
    ctrl_out.m_axi_arlen     <= (others=>'0');                                   
    ctrl_out.m_axi_arsize    <= (others=>'0');                                   
    ctrl_out.m_axi_arburst   <= (others=>'0');                                     
    ctrl_out.m_axi_arlock    <= '0';                 
    ctrl_out.m_axi_arcache   <= (others=>'0');                           
    ctrl_out.m_axi_arprot    <= (others=>'0');                                
    ctrl_out.m_axi_arqos     <= (others=>'0');                                     
    ctrl_out.m_axi_arvalid   <= '0';                                    
    ctrl_out.m_axi_rready    <= '0';  
  end AXI_INIT;
            
                     

                   
  procedure AXI_WRITE(                               
    signal ctrl_in      : in    axi_in_record_t;
    signal ctrl_out     : out   axi_out_record_t; 
    constant address    : in    std_logic_vector(31 downto 0);   
    constant len        : in    integer := 1;
    constant data       : in    tArray_of_64bits(255 downto 0);
    constant last_BE    : in    integer := 8;
    constant echo       : in    std_logic := '0') is                        
      variable tmp_len    : integer;   
      variable tmp_ready  : std_logic_vector(1 downto 0) := "00"; 
  begin  
    wait until rising_edge(ctrl_in.aclk); 
      tmp_ready                 := "00"; 
      tmp_len                   := len;   
      ctrl_out.m_axi_araddr     <= address;  
      ctrl_out.m_axi_awaddr     <= address;   
      ctrl_out.m_axi_awlen      <= conv_std_logic_vector(len-1, 4);   
      ctrl_out.m_axi_awsize     <= "011";                                                                           
      ctrl_out.m_axi_awburst    <= "01";                                
      ctrl_out.m_axi_awcache    <= "0011";                                                                
      ctrl_out.m_axi_wdata      <= data(0);                                
      ctrl_out.m_axi_wstrb      <= (others=>'1');                                    
      ctrl_out.m_axi_awvalid    <= '0';                                           
      ctrl_out.m_axi_wvalid     <= '0';                                                        
      ctrl_out.m_axi_bready     <= '1';   
    wait until rising_edge(ctrl_in.aclk);  
      if (len = 1) then
        ctrl_out.m_axi_wlast  <= '1';  
        if (last_BE = 7) then                         
          ctrl_out.m_axi_wstrb      <= "01111111";   
        elsif (last_BE = 6) then                        
          ctrl_out.m_axi_wstrb      <= "00111111";   
        elsif (last_BE = 5) then                        
          ctrl_out.m_axi_wstrb      <= "00011111";   
        elsif (last_BE = 4) then                        
          ctrl_out.m_axi_wstrb      <= "00001111";   
        elsif (last_BE = 3) then                        
          ctrl_out.m_axi_wstrb      <= "00000111";   
        elsif (last_BE = 2) then                        
          ctrl_out.m_axi_wstrb      <= "00000011";   
        elsif (last_BE = 1) then                        
          ctrl_out.m_axi_wstrb      <= "00000001";   
        else                       
          ctrl_out.m_axi_wstrb      <= "11111111";   
        end if;
      end if;                                  
      ctrl_out.m_axi_awvalid    <= '1'; 
      if (ctrl_in.m_axi_awready = '1') then    
        wait until rising_edge(ctrl_in.aclk);                                    
        ctrl_out.m_axi_awvalid    <= '0';  
      else
        wait until rising_edge(ctrl_in.aclk);  
      end if;                                          
      ctrl_out.m_axi_wvalid     <= '1';        
      wait until (ctrl_in.m_axi_awready = '1') or (ctrl_in.m_axi_wready = '1');  
      if ctrl_in.m_axi_awready = '1' then   
        tmp_ready(0) := '1';
      end if;                 
      if ctrl_in.m_axi_wready = '1' then   
        tmp_ready(1) := '1'; 
      end if;           
      wait until rising_edge(ctrl_in.aclk);    
      if ctrl_in.m_axi_wready = '1' then     
        tmp_ready(1) := '1'; 
      end if;            
      if ctrl_in.m_axi_awready = '1' then     
        tmp_ready(0) := '1';
      end if;      
      if tmp_ready(0) = '1' then
        ctrl_out.m_axi_awvalid    <= '0'; 
      end if;
      if tmp_ready(1) = '1' then
        if (len = 1) then  
          ctrl_out.m_axi_wvalid    <= '0'; 
        end if;   
        tmp_len                 := tmp_len - 1;                                        
        ctrl_out.m_axi_wdata    <= data(len - tmp_len);  
      end if;    
             
      if (tmp_ready /= "11") then   
        wait until (ctrl_in.m_axi_awready = '1') or (ctrl_in.m_axi_wready = '1');  
        if ctrl_in.m_axi_awready = '1' then     
          tmp_ready(0) := '1';
        end if;                 
        if ctrl_in.m_axi_wready = '1' then     
          tmp_ready(1) := '1'; 
        end if; 
      end if;                                  
      wait until rising_edge(ctrl_in.aclk);                                   
      ctrl_out.m_axi_awvalid    <= '0';   
      if (len = 1) then                                                             
        ctrl_out.m_axi_wvalid     <= '0';    
      end if;      
                     
      ----------------------
      -- wait until (ctrl_in.m_axi_wready = '1');   
      if (len = 1) then                     
        wait until rising_edge(ctrl_in.aclk);                                   
        ctrl_out.m_axi_awvalid    <= '0';                                           
        ctrl_out.m_axi_wvalid     <= '0';                                                      
        ctrl_out.m_axi_bready     <= '1';  
      else      
        tmp_len                 := tmp_len - 1;                                             
        ctrl_out.m_axi_wdata    <= data(len - tmp_len); 
        while (tmp_len /= 0) loop   
          if (ctrl_in.m_axi_wready = '1') then  
            ctrl_out.m_axi_wdata    <= data(len - tmp_len); 
            tmp_len                 := tmp_len - 1; 
          end if;
          wait until rising_edge(ctrl_in.aclk);    
          if (tmp_len = 1) then
            if (ctrl_in.m_axi_wready = '1') then
              ctrl_out.m_axi_wlast  <= '1'; 
            end if;
            if (last_BE = 7) then                         
              ctrl_out.m_axi_wstrb      <= "01111111";   
            elsif (last_BE = 6) then                        
              ctrl_out.m_axi_wstrb      <= "00111111";   
            elsif (last_BE = 5) then                        
              ctrl_out.m_axi_wstrb      <= "00011111";   
            elsif (last_BE = 4) then                        
              ctrl_out.m_axi_wstrb      <= "00001111";   
            elsif (last_BE = 3) then                        
              ctrl_out.m_axi_wstrb      <= "00000111";   
            elsif (last_BE = 2) then                        
              ctrl_out.m_axi_wstrb      <= "00000011";   
            elsif (last_BE = 1) then                        
              ctrl_out.m_axi_wstrb      <= "00000001";   
            else                       
              ctrl_out.m_axi_wstrb      <= "11111111";   
            end if;  
          end if;                         
        end loop;    
        if (ctrl_in.m_axi_wready /= '1') then 
          wait until (ctrl_in.m_axi_wready = '1'); 
          wait until rising_edge(ctrl_in.aclk);  
                
        end if;                                     
        ctrl_out.m_axi_bready     <= '1';   
      end if;                             
      ctrl_out.m_axi_wlast      <= '0';                                        
      ctrl_out.m_axi_wvalid     <= '0';  
      wait until (ctrl_in.m_axi_bvalid  = '1'); 
      wait until rising_edge(ctrl_in.aclk);                                  
      ctrl_out.m_axi_bready     <= '0';  
      wait until rising_edge(ctrl_in.aclk);      
      wait until rising_edge(ctrl_in.aclk);                                                    
      ctrl_out.m_axi_rready     <= '0';    
      wait until rising_edge(ctrl_in.aclk);   
      if echo = '1' then 
        if (len > 1) then 
          print("AXI Write to addr 0x" &to_string_axi(address) & ":" );  
          for i in 0 to len-1 loop
            print("      0x" & to_string_axi(data(i))); 
          end loop;
          print("  " );  
        else
          print("AXI Write 0x" & to_string_axi(data(0)) & "  to  addr 0x" &to_string_axi(address));
        end if;
      end if;            
                 
  end AXI_WRITE; 
                  
  procedure RESET(                               
    signal ctrl_in          : in    axi_in_record_t;
    signal ctrl_out         : out   axi_out_record_t;
    signal tid              : inout std_logic_vector(31 downto 0); 
    constant F_ERROR        : in    std_logic_vector(3 downto 0);            
    constant echo           : in    std_logic := '0') is                         
      variable header         : tArray_of_32bits(9 downto 0);
      variable axi_write_data : tArray_of_64bits(255 downto 0):= (others=>(others=>'0'));   

  begin    

 
    header(0)  := x"cafecafe";  -- S_KEY  
    header(1)  := x"0F000000";  -- COMMAND          
    header(2)  := x"00000000";  -- BLOCK_IDs_012
    header(3)  := x"00000000";  -- BLOCK_IDs_345   
    header(4)  := x"00000000";  -- SIZE
    header(5)  := x"DF400000";  -- TX_ADDR         
    header(6)  := tid;--x"0000000a";  -- TRANS_ID 
    header(7)  := x"00000000";  -- STATUS(rsvd)  
    header(8)  := x"DEADBEEF";  -- E_KEY
 


    if (F_ERROR = x"1") then
      header(6)  := (others=>'0');  -- Trans_ID ERROR
    end if;
    if (F_ERROR = x"2") then
      header(0)  := x"12345678";  -- S_KEY ERROR 
    end if;
    if (F_ERROR = x"3") then
      header(4)  := x"00000001";  -- SIZE ERROR
      end if;
    if (F_ERROR = x"4") then 
      header(8)  := x"12345678";  -- E_KEY ERROR 
    end if;

    wait for 1 ns;   -- CHKSUM   
    header(9)  := header(0) + header(1) + header(2) + header(3) + header(4) + header(5) + header(6) + header(7) + header(8);   
 

    if (F_ERROR = x"5") then 
      header(9)  := x"aaaaaaaa";  -- CHKSUM ERROR 
    end if;
    wait for 1 ns; 
    
    print ("  ");
    print ("send RESET command");
    axi_write_data(0)  := header(1) & header(0);
    axi_write_data(1)  := header(3) & header(2);
    axi_write_data(2)  := header(5) & header(4);
    axi_write_data(3)  := header(7) & header(6);
    axi_write_data(4)  := header(9) & header(8);      

    wait for 1 ns;            
    AXI_WRITE(ctrl_in, ctrl_out, x"00000000", 5, axi_write_data, 8, echo); 
    tid <= tid + '1';

end RESET; 
     
    
                   
procedure SET_FEATURE(                               
  signal ctrl_in            : in    axi_in_record_t;
  signal ctrl_out           : out   axi_out_record_t;
  signal tid                : inout std_logic_vector(31 downto 0); 
  constant echo             : in    std_logic := '0') is                          
    variable set_feature_1    : std_logic_vector(63 downto 0);                
    variable set_feature_2    : std_logic_vector(63 downto 0);                 
    variable command          : std_logic_vector(31 downto 0);               
    variable header           : tArray_of_32bits(9 downto 0);
    variable axi_write_data   : tArray_of_64bits(255 downto 0):= (others=>(others=>'0'));   
        

  begin     
    set_feature_1  := x"0000EF01_00000003";   -- SET_FEATURE (0xEF) - Timing mode (0x01) - Asynchronous - timing mode 3 (0x03)
    set_feature_2  := x"0000EF91_00000000";   -- SET_FEATURE (0xEF) - SLC (0x91)  - 1Bit per Cell (0x00)


    command(9 downto 0)     := "00" & x"00";    -- Page_ID
    command(18 downto 10)   := (others=>'0');   -- Reserved
    command(20 downto 19)   := "00";            -- Plane_ID
    command(22 downto 21)   := "00";            -- LUN_ID
    command(23)             := '0';             -- BANK_ID
    command(27 downto 24)   := x"0";            -- FEATURE
    command(31 downto 28)   := (others=>'0');   -- Reserved

    wait for 1 ns;  

    header(0)  := x"cafecafe";  -- S_KEY 
    header(1)  := command;      -- COMMAND          
    header(2)  := x"00000000";  -- BLOCK_IDs_012
    header(3)  := x"00000000";  -- BLOCK_IDs_345   
    header(4)  := x"00000002";  -- SIZE
    header(5)  := x"DF400000";  -- TX_ADDR         
    header(6)  := tid;          -- TRANS_ID 
    header(7)  := x"00000000";  -- STATUS(rsvd)   
    header(8)  := x"DEADBEEF";  -- E_KEY                   

    wait for 1 ns;   -- CHKSUM   
    header(9)  := header(0) + header(1) + header(2) + header(3) + header(4) + header(5) + header(6) + header(7) + header(8);   
    wait for 1 ns;  
 
    axi_write_data(0)  := header(1) & header(0);
    axi_write_data(1)  := header(3) & header(2);
    axi_write_data(2)  := header(5) & header(4);
    axi_write_data(3)  := header(7) & header(6);
    axi_write_data(4)  := header(9) & header(8);      

    axi_write_data(5)  := set_feature_1;
    axi_write_data(6)  := set_feature_2;

    wait for 1 ns;     
    print ("  ");       
    print ("send FEATURE command (SET)" );
    print ("      ASYNC timing mode 3" );
    print ("      SLC 1 mode" );
    AXI_WRITE(ctrl_in, ctrl_out, x"00000000", 7, axi_write_data, 8, echo); 
    
    
    tid <= tid + '1';

end SET_FEATURE; 
     
procedure GET_FEATURE(                               
  signal ctrl_in            : in    axi_in_record_t;
  signal ctrl_out           : out   axi_out_record_t;
  constant bank_id          : in    std_logic_vector(0 downto 0); 
  signal tid                : inout std_logic_vector(31 downto 0); 
  constant echo             : in    std_logic := '0') is                          
    variable set_feature_1    : std_logic_vector(63 downto 0);                
    variable set_feature_2    : std_logic_vector(63 downto 0);                 
    variable command          : std_logic_vector(31 downto 0);               
    variable header           : tArray_of_32bits(9 downto 0);
    variable axi_write_data   : tArray_of_64bits(255 downto 0):= (others=>(others=>'0'));   
        

  begin     
    set_feature_1  := x"0000EE01_00000000";   -- GET_FEATURE (0xEE) (0x01)
    set_feature_2  := x"0000EE91_00000000";   -- GET_FEATURE (0xEE) (0x91)


    command(9 downto 0)     := "00" & x"00";    -- Page_ID
    command(18 downto 10)   := (others=>'0');   -- Reserved
    command(20 downto 19)   := "00";            -- Plane_ID
    command(22 downto 21)   := "00";            -- LUN_ID
    command(23)             := bank_id(0);      -- BANK_ID
    command(27 downto 24)   := x"0";            -- FEATURE
    --command(27 downto 24)   := x"d";            -- bad command test
    command(31 downto 28)   := (others=>'0');   -- Reserved

    wait for 1 ns;  

    header(0)  := x"cafecafe";  -- S_KEY 
    header(1)  := command;      -- COMMAND          
    header(2)  := x"00000000";  -- BLOCK_IDs_012
    header(3)  := x"00000000";  -- BLOCK_IDs_345   
    header(4)  := x"00020002";  -- SIZE
    header(5)  := x"DF400000";  -- TX_ADDR         
    header(6)  := tid;          -- TRANS_ID 
    header(7)  := x"00000000";  -- STATUS(rsvd)   
    header(8)  := x"DEADBEEF";  -- E_KEY                   

    wait for 1 ns;   -- CHKSUM   
    header(9)  := header(0) + header(1) + header(2) + header(3) + header(4) + header(5) + header(6) + header(7) + header(8);   
    wait for 1 ns;  
    
    axi_write_data(0)  := header(1) & header(0);
    axi_write_data(1)  := header(3) & header(2);
    axi_write_data(2)  := header(5) & header(4);
    axi_write_data(3)  := header(7) & header(6);
    axi_write_data(4)  := header(9) & header(8);      

    axi_write_data(5)  := set_feature_1;
    axi_write_data(6)  := set_feature_2;

    wait for 1 ns;       
    print ("  ");     
    print ("send FEATURE command (GET) on Bank "  & to_string_axi(bank_id)); 

    AXI_WRITE(ctrl_in, ctrl_out, x"00000000", 7, axi_write_data, 8, echo); 
    
    
    tid <= tid + '1';

end GET_FEATURE; 
        
         
procedure READ_UNIQUE_ID(                               
  signal ctrl_in            : in    axi_in_record_t;
  signal ctrl_out           : out   axi_out_record_t;
  constant bank_id          : in    std_logic_vector(0 downto 0); 
  signal tid                : inout std_logic_vector(31 downto 0); 
  constant echo             : in    std_logic := '0') is                      
    variable command          : std_logic_vector(31 downto 0);                    
    variable header           : tArray_of_32bits(9 downto 0);
    variable axi_write_data   : tArray_of_64bits(255 downto 0):= (others=>(others=>'0'));   
        

  begin    
    command(9 downto 0)     := "00" & x"00";    -- Page_ID
    command(18 downto 10)   := (others=>'0');   -- Reserved
    command(20 downto 19)   := "00";            -- Plane_ID
    command(22 downto 21)   := "00";            -- LUN_ID
    command(23)             := bank_id(0);      -- BANK_ID
    command(27 downto 24)   := x"3";            -- READ_UNIQUE_ID
    command(31 downto 28)   := (others=>'0');   -- Reserved

    wait for 1 ns;  

    header(0)  := x"cafecafe";  -- S_KEY 
    header(1)  := command;      -- COMMAND          
    header(2)  := x"00000000";  -- BLOCK_IDs_012
    header(3)  := x"00000000";  -- BLOCK_IDs_345   
    header(4)  := x"00C00000";  -- SIZE
    header(5)  := x"DF400000";  -- TX_ADDR         
    header(6)  := tid;          -- TRANS_ID 
    header(7)  := x"00000000";  -- STATUS(rsvd)   
    header(8)  := x"DEADBEEF";  -- E_KEY                   

    wait for 1 ns;   -- CHKSUM   
    header(9)  := header(0) + header(1) + header(2) + header(3) + header(4) + header(5) + header(6) + header(7) + header(8);   
    wait for 1 ns;  

    print ("  ");
    print ("send READ_UNIQUE_ID command on Bank "  & to_string_axi(bank_id)); 
    axi_write_data(0)  := header(1) & header(0);
    axi_write_data(1)  := header(3) & header(2);
    axi_write_data(2)  := header(5) & header(4);
    axi_write_data(3)  := header(7) & header(6);
    axi_write_data(4)  := header(9) & header(8);      

    wait for 1 ns;            
    AXI_WRITE(ctrl_in, ctrl_out, x"00000000", 5, axi_write_data, 8, echo); 
    tid <= tid + '1';

end READ_UNIQUE_ID; 
    
procedure GET_BAD_BLOCK_MARKER(                               
  signal ctrl_in            : in    axi_in_record_t;
  signal ctrl_out           : out   axi_out_record_t;
  constant bank_id          : in    std_logic_vector(0 downto 0); 
  constant lun_id           : in    std_logic_vector(1 downto 0); 
  constant plane_id         : in    std_logic_vector(1 downto 0); 
  constant block_ids        : in    tArray_of_9bits(5 downto 0); 
  signal tid                : inout std_logic_vector(31 downto 0); 
  constant echo             : in    std_logic := '0') is                      
    variable command          : std_logic_vector(31 downto 0);                    
    variable block_ids_012    : std_logic_vector(31 downto 0) := (others=>'0');                 
    variable block_ids_345    : std_logic_vector(31 downto 0) := (others=>'0');                      
    variable header           : tArray_of_32bits(9 downto 0);
    variable axi_write_data   : tArray_of_64bits(255 downto 0):= (others=>(others=>'0'));   
        

  begin    
    command(9 downto 0)     := "00" & x"00";    -- Page_ID
    command(18 downto 10)   := (others=>'0');   -- Reserved
    command(20 downto 19)   := plane_id;        -- Plane_ID
    command(22 downto 21)   := lun_id;          -- LUN_ID
    command(23)             := bank_id(0);      -- BANK_ID
    command(27 downto 24)   := x"1";            -- GET_BAD_BLOCK_MARKER
    command(31 downto 28)   := (others=>'0');   -- Reserved

    block_ids_012(8 downto 0)     := block_ids(0); 
    block_ids_012(18 downto 10)   := block_ids(1); 
    block_ids_012(28 downto 20)   := block_ids(2); 
    block_ids_345(8 downto 0)     := block_ids(3); 
    block_ids_345(18 downto 10)   := block_ids(4); 
    block_ids_345(28 downto 20)   := block_ids(5); 
    wait for 1 ns;  

    header(0)  := x"cafecafe";   -- S_KEY 
    header(1)  := command;       -- COMMAND          
    header(2)  := block_ids_012; -- BLOCK_IDs_012
    header(3)  := block_ids_345; -- BLOCK_IDs_345   
    header(4)  := x"00010000";   -- SIZE
    header(5)  := x"DF400000";   -- TX_ADDR         
    header(6)  := tid;           -- TRANS_ID 
    header(7)  := x"00000000";   -- STATUS(rsvd)   
    header(8)  := x"DEADBEEF";   -- E_KEY                   

    wait for 1 ns;   -- CHKSUM   
    header(9)  := header(0) + header(1) + header(2) + header(3) + header(4) + header(5) + header(6) + header(7) + header(8);   
    wait for 1 ns;  

    print ("  ");
    print ("send GET_BAD_BLOCK_MARKER command on Bank "  & to_string_axi(bank_id)); 
    axi_write_data(0)  := header(1) & header(0);
    axi_write_data(1)  := header(3) & header(2);
    axi_write_data(2)  := header(5) & header(4);
    axi_write_data(3)  := header(7) & header(6);
    axi_write_data(4)  := header(9) & header(8);      

    wait for 1 ns;            
    AXI_WRITE(ctrl_in, ctrl_out, x"00000000", 5, axi_write_data, 8, echo); 
    tid <= tid + '1';


    
end GET_BAD_BLOCK_MARKER; 


procedure SET_BAD_BLOCK_MARKER(                               
  signal ctrl_in            : in    axi_in_record_t;
  signal ctrl_out           : out   axi_out_record_t;
  constant bank_id          : in    std_logic_vector(0 downto 0); 
  constant lun_id           : in    std_logic_vector(1 downto 0); 
  constant plane_id         : in    std_logic_vector(1 downto 0); 
  constant block_ids        : in    tArray_of_9bits(5 downto 0); 
  signal tid                : inout std_logic_vector(31 downto 0); 
  constant echo             : in    std_logic := '0') is                      
    variable command          : std_logic_vector(31 downto 0);                    
    variable block_ids_012    : std_logic_vector(31 downto 0) := (others=>'0');                 
    variable block_ids_345    : std_logic_vector(31 downto 0) := (others=>'0');                      
    variable header           : tArray_of_32bits(9 downto 0);
    variable axi_write_data   : tArray_of_64bits(255 downto 0):= (others=>(others=>'0'));   
        

  begin    
    command(9 downto 0)     := "00" & x"00";    -- Page_ID
    command(18 downto 10)   := (others=>'0');   -- Reserved
    command(20 downto 19)   := plane_id;        -- Plane_ID
    command(22 downto 21)   := lun_id;          -- LUN_ID
    command(23)             := bank_id(0);      -- BANK_ID
    command(27 downto 24)   := x"2";            -- SET_BAD_BLOCK_MARKER
    command(31 downto 28)   := (others=>'0');   -- Reserved

    block_ids_012(8 downto 0)     := block_ids(0); 
    block_ids_012(18 downto 10)   := block_ids(1); 
    block_ids_012(28 downto 20)   := block_ids(2); 
    block_ids_345(8 downto 0)     := block_ids(3); 
    block_ids_345(18 downto 10)   := block_ids(4); 
    block_ids_345(28 downto 20)   := block_ids(5); 
    wait for 1 ns;  

    header(0)  := x"cafecafe";   -- S_KEY 
    header(1)  := command;       -- COMMAND          
    header(2)  := block_ids_012; -- BLOCK_IDs_012
    header(3)  := block_ids_345; -- BLOCK_IDs_345   
    header(4)  := x"00000000";   -- SIZE
    header(5)  := x"DF400000";   -- TX_ADDR         
    header(6)  := tid;           -- TRANS_ID 
    header(7)  := x"00000000";   -- STATUS(rsvd)   
    header(8)  := x"DEADBEEF";   -- E_KEY                   

    wait for 1 ns;   -- CHKSUM   
    header(9)  := header(0) + header(1) + header(2) + header(3) + header(4) + header(5) + header(6) + header(7) + header(8);   
    wait for 1 ns;  

    print ("  ");
    print ("send SET_BAD_BLOCK_MARKER command on Bank "  & to_string_axi(bank_id)); 
    axi_write_data(0)  := header(1) & header(0);
    axi_write_data(1)  := header(3) & header(2);
    axi_write_data(2)  := header(5) & header(4);
    axi_write_data(3)  := header(7) & header(6);
    axi_write_data(4)  := header(9) & header(8);      

    wait for 1 ns;            
    AXI_WRITE(ctrl_in, ctrl_out, x"00000000", 5, axi_write_data, 8, echo); 
    tid <= tid + '1';


    
end SET_BAD_BLOCK_MARKER; 

procedure ERASE_BLOCK(                               
  signal ctrl_in            : in    axi_in_record_t;
  signal ctrl_out           : out   axi_out_record_t;
  constant bank_id          : in    std_logic_vector(0 downto 0); 
  constant lun_id           : in    std_logic_vector(1 downto 0); 
  constant plane_id         : in    std_logic_vector(1 downto 0); 
  constant block_ids        : in    tArray_of_9bits(5 downto 0); 
  signal tid                : inout std_logic_vector(31 downto 0); 
  constant echo             : in    std_logic := '0') is                      
    variable command          : std_logic_vector(31 downto 0);                    
    variable block_ids_012    : std_logic_vector(31 downto 0) := (others=>'0');                 
    variable block_ids_345    : std_logic_vector(31 downto 0) := (others=>'0');                      
    variable header           : tArray_of_32bits(9 downto 0);
    variable axi_write_data   : tArray_of_64bits(255 downto 0):= (others=>(others=>'0'));   
      

  begin    
    command(9 downto 0)     := "00" & x"00";    -- Page_ID
    command(18 downto 10)   := (others=>'0');   -- Reserved
    command(20 downto 19)   := plane_id;        -- Plane_ID
    command(22 downto 21)   := lun_id;          -- LUN_ID
    command(23)             := bank_id(0);      -- BANK_ID
    command(27 downto 24)   := x"4";            -- ERASE
    command(31 downto 28)   := (others=>'0');   -- Reserved

    block_ids_012(8 downto 0)     := block_ids(0); 
    block_ids_012(18 downto 10)   := block_ids(1); 
    block_ids_012(28 downto 20)   := block_ids(2); 
    block_ids_345(8 downto 0)     := block_ids(3); 
    block_ids_345(18 downto 10)   := block_ids(4); 
    block_ids_345(28 downto 20)   := block_ids(5); 
    wait for 1 ns;  

    header(0)  := x"cafecafe";   -- S_KEY 
    header(1)  := command;       -- COMMAND          
    header(2)  := block_ids_012; -- BLOCK_IDs_012
    header(3)  := block_ids_345; -- BLOCK_IDs_345   
    header(4)  := x"00000000";   -- SIZE
    header(5)  := x"DF400000";   -- TX_ADDR         
    header(6)  := tid;           -- TRANS_ID 
    header(7)  := x"00000000";   -- STATUS(rsvd)   
    header(8)  := x"DEADBEEF";   -- E_KEY                   

    wait for 1 ns;   -- CHKSUM   
    header(9)  := header(0) + header(1) + header(2) + header(3) + header(4) + header(5) + header(6) + header(7) + header(8);   
    wait for 1 ns;  

    print ("  ");
    print ("send ERASE_BLOCK command on Bank "  & to_string_axi(bank_id)); 
    axi_write_data(0)  := header(1) & header(0);
    axi_write_data(1)  := header(3) & header(2);
    axi_write_data(2)  := header(5) & header(4);
    axi_write_data(3)  := header(7) & header(6);
    axi_write_data(4)  := header(9) & header(8);      

    wait for 1 ns;            
    AXI_WRITE(ctrl_in, ctrl_out, x"00000000", 5, axi_write_data, 8, echo); 
    tid <= tid + '1';


    
end ERASE_BLOCK; 



                   
procedure PROGRAM_PAGE(                               
  signal ctrl_in            : in    axi_in_record_t;
  signal ctrl_out           : out   axi_out_record_t; 
  constant length           : in    std_logic_vector(15 downto 0); 
  constant bank_id          : in    std_logic_vector(0 downto 0); 
  constant lun_id           : in    std_logic_vector(1 downto 0); 
  constant plane_id         : in    std_logic_vector(1 downto 0); 
  constant block_ids        : in    tArray_of_9bits(5 downto 0); 
  constant page_id          : in    std_logic_vector(9 downto 0); 
  constant pattern          : in    std_logic_vector(3 downto 0); 
  signal tid                : inout std_logic_vector(31 downto 0); 
  constant echo             : in    std_logic := '0';
  constant pause            : in    std_logic := '0') is                              
    variable command          : std_logic_vector(31 downto 0);                    
    variable block_ids_012    : std_logic_vector(31 downto 0) := (others=>'0');                 
    variable block_ids_345    : std_logic_vector(31 downto 0) := (others=>'0');                      
    variable header           : tArray_of_32bits(9 downto 0);
    variable axi_write_data   : tArray_of_64bits(255 downto 0):= (others=>(others=>'0'));                 
    variable payload_data     : std_logic_vector(63 downto 0) := (others=>'0');                    
    variable address          : std_logic_vector(31 downto 0) := (others=>'0');    
    variable length_rest      : integer;    

begin    
    length_rest:= conv_integer(length);
    address     := x"00000000";
                    
    command(9 downto 0)     := page_id;         -- Page_ID
    command(18 downto 10)   := (others=>'0');   -- Reserved
    command(20 downto 19)   := plane_id;        -- Plane_ID
    command(22 downto 21)   := lun_id;          -- LUN_ID
    command(23)             := bank_id(0);      -- BANK_ID
    command(27 downto 24)   := x"8";            -- PROGRAM
    command(31 downto 28)   := (others=>'0');   -- Reserved

    block_ids_012(8 downto 0)     := block_ids(0); 
    block_ids_012(18 downto 10)   := block_ids(1); 
    block_ids_012(28 downto 20)   := block_ids(2); 
    block_ids_345(8 downto 0)     := block_ids(3); 
    block_ids_345(18 downto 10)   := block_ids(4); 
    block_ids_345(28 downto 20)   := block_ids(5); 
    wait for 1 ns;  

    header(0)  := x"cafecafe";      -- S_KEY 
    header(1)  := command;          -- COMMAND          
    header(2)  := block_ids_012;    -- BLOCK_IDs_012
    header(3)  := block_ids_345;    -- BLOCK_IDs_345   
    header(4)  := x"0000" & length; -- SIZE
    header(5)  := x"DF400000";      -- TX_ADDR         
    header(6)  := tid;              -- TRANS_ID 
    header(7)  := x"00000000";      -- STATUS(rsvd)   
    header(8)  := x"DEADBEEF";      -- E_KEY                   

    wait for 1 ns;   -- CHKSUM   
    header(9)  := header(0) + header(1) + header(2) + header(3) + header(4) + header(5) + header(6) + header(7) + header(8);   
    wait for 1 ns;  

    print ("  ");
    print ("send PROGRAM_PAGE command on Bank "  & to_string_axi(bank_id)); 
    axi_write_data(0)  := header(1) & header(0);
    axi_write_data(1)  := header(3) & header(2);
    axi_write_data(2)  := header(5) & header(4);
    axi_write_data(3)  := header(7) & header(6);
    axi_write_data(4)  := header(9) & header(8);      

    if (pattern = x"F") then
      payload_data := x"ffffffff_ffffffff";
    elsif (pattern = x"0") then
      payload_data := x"80000001_80000000"; 
    else
      payload_data := x"07060504_03020100"; 
    end if;

    for i in 0 to 10 loop
      axi_write_data(i+5)  := payload_data; 
            
      if (pattern = x"F") then
        payload_data := x"ffffffff_ffffffff";
      elsif (pattern = x"0") then   
        payload_data := payload_data + x"00000002_00000002"; 
      else
        if (payload_data = x"FFFEFDFCFBFAF9F8") then
          payload_data := x"07060504_03020100";
        else    
          payload_data := payload_data + x"08080808_08080808"; 
        end if;
      end if;

    end loop;
     
    wait for 1 ns;               
    if (length_rest <= 11) then
      AXI_WRITE(ctrl_in, ctrl_out, address, length_rest + 5, axi_write_data, 8, echo); 
    else 
      AXI_WRITE(ctrl_in, ctrl_out, address, 16, axi_write_data, 8, echo);  
      length_rest:= length_rest - 11; 
      address := address + x"80";
    end if;
    tid <= tid + '1'; 
    wait for 1 ns;   


    while (length_rest /= 0) loop

      if (pause = '1' and length_rest = 9013) then
       
        print ("pause, length_rest = 0x"  & to_string_axi(conv_std_logic_vector(length_rest,16))); 
        wait for 100 us;
        wait until rising_edge(ctrl_in.aclk);   
        --END_SIMULATION(0);

      end if;

      for i in 0 to 15 loop
        axi_write_data(i)  := payload_data; 
        if (pattern = x"F") then
          payload_data := x"ffffffff_ffffffff";
        elsif (pattern = x"0") then   
          payload_data := payload_data + x"00000002_00000002"; 
        else
          if (payload_data = x"FFFEFDFCFBFAF9F8") then
            payload_data := x"07060504_03020100";
          else    
            payload_data := payload_data + x"08080808_08080808"; 
          end if;
        end if;
      end loop;
             
      if (length_rest <= 16) then
        AXI_WRITE(ctrl_in, ctrl_out, address, length_rest, axi_write_data, 8, echo); 
        length_rest := 0;
      else 
        AXI_WRITE(ctrl_in, ctrl_out, address, 16, axi_write_data, 8, echo);  
        length_rest:= length_rest - 16; 
        address := address + x"80";
      end if;
    end loop;



end PROGRAM_PAGE; 
     
     

                   
procedure READ_PAGE(                               
  signal ctrl_in            : in    axi_in_record_t;
  signal ctrl_out           : out   axi_out_record_t; 
  constant length           : in    std_logic_vector(15 downto 0); 
  constant bank_id          : in    std_logic_vector(0 downto 0); 
  constant lun_id           : in    std_logic_vector(1 downto 0); 
  constant plane_id         : in    std_logic_vector(1 downto 0); 
  constant block_ids        : in    tArray_of_9bits(5 downto 0); 
  constant page_id          : in    std_logic_vector(9 downto 0); 
  signal tid                : inout std_logic_vector(31 downto 0); 
  constant echo             : in    std_logic := '0') is                              
    variable command          : std_logic_vector(31 downto 0);                    
    variable block_ids_012    : std_logic_vector(31 downto 0) := (others=>'0');                 
    variable block_ids_345    : std_logic_vector(31 downto 0) := (others=>'0');                      
    variable header           : tArray_of_32bits(9 downto 0);
    variable axi_write_data   : tArray_of_64bits(255 downto 0):= (others=>(others=>'0'));                 
    variable payload_data     : std_logic_vector(63 downto 0) := (others=>'0');                    
    variable address          : std_logic_vector(31 downto 0) := (others=>'0');    
    variable length_rest      : integer;    

begin    
    length_rest:= conv_integer(length);
    address     := x"00000000";
                    
    command(9 downto 0)     := page_id;         -- Page_ID
    command(18 downto 10)   := (others=>'0');   -- Reserved
    command(20 downto 19)   := plane_id;        -- Plane_ID
    command(22 downto 21)   := lun_id;          -- LUN_ID
    command(23)             := bank_id(0);      -- BANK_ID
    command(27 downto 24)   := x"C";            -- READ PAGE
    command(31 downto 28)   := (others=>'0');   -- Reserved

    block_ids_012(8 downto 0)     := block_ids(0); 
    block_ids_012(18 downto 10)   := block_ids(1); 
    block_ids_012(28 downto 20)   := block_ids(2); 
    block_ids_345(8 downto 0)     := block_ids(3); 
    block_ids_345(18 downto 10)   := block_ids(4); 
    block_ids_345(28 downto 20)   := block_ids(5); 
    wait for 1 ns;  

    header(0)  := x"cafecafe";      -- S_KEY 
    header(1)  := command;          -- COMMAND          
    header(2)  := block_ids_012;    -- BLOCK_IDs_012
    header(3)  := block_ids_345;    -- BLOCK_IDs_345   
    header(4)  := length & x"0000"; -- SIZE
    header(5)  := x"DF400000";      -- TX_ADDR         
    header(6)  := tid;              -- TRANS_ID 
    header(7)  := x"00000000";      -- STATUS(rsvd)   
    header(8)  := x"DEADBEEF";      -- E_KEY                   

    wait for 1 ns;   -- CHKSUM   
    header(9)  := header(0) + header(1) + header(2) + header(3) + header(4) + header(5) + header(6) + header(7) + header(8);   
    wait for 1 ns;  

    print ("  ");
    print ("send READ_PAGE command on Bank "  & to_string_axi(bank_id)); 
    axi_write_data(0)  := header(1) & header(0);
    axi_write_data(1)  := header(3) & header(2);
    axi_write_data(2)  := header(5) & header(4);
    axi_write_data(3)  := header(7) & header(6);
    axi_write_data(4)  := header(9) & header(8);      
   
    wait for 1 ns;      
    AXI_WRITE(ctrl_in, ctrl_out, address, 5, axi_write_data, 8, echo); 
    tid <= tid + '1';  

end READ_PAGE; 


     
end package body;    

 
