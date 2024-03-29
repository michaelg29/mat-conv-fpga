
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

---------------------------------
-- AXI Receiver and Input FIFO --
---------------------------------
entity rx_buffer is
  generic (
    -- FIFO capacity
    NWORDS           : integer range 16 to 512 := 16;
    AWIDTH           : integer range  4 to  10 := 4;
    AEVAL            : integer range  3 to 510 := 4;
    AFVAL            : integer range  3 to 510 := 14;

    -- packet widths
    G_DATA_PKT_WIDTH : integer := 64; -- width of an AXI data packet
    G_ADDR_PKT_WIDTH : integer := 8   -- required relative address size
  );
  port (

    -- clock and reset interface
    i_macclk              : in  std_logic;
    i_aclk                : in  std_logic;
    i_arst_n              : in  std_logic;
    o_rst_n               : out std_logic;

    -- AXI write address channel
    i_rx_axi_awid         : in  std_logic_vector(3 downto 0);
    i_rx_axi_awaddr       : in  std_logic_vector(31 downto 0);
    i_rx_axi_awlen        : in  std_logic_vector(3 downto 0);
    i_rx_axi_awsize       : in  std_logic_vector(2 downto 0);
    i_rx_axi_awburst      : in  std_logic_vector(1 downto 0);
    i_rx_axi_awlock       : in  std_logic;
    i_rx_axi_awcache      : in  std_logic_vector(3 downto 0);
    i_rx_axi_awprot       : in  std_logic_vector(2 downto 0);
    i_rx_axi_awvalid      : in  std_logic;
    o_rx_axi_awready      : out std_logic;

    -- AXI write data channel
    i_rx_axi_wdata        : in  std_logic_vector(63 downto 0);
    i_rx_axi_wstrb        : in  std_logic_vector(7 downto 0);
    i_rx_axi_wlast        : in  std_logic;
    i_rx_axi_wvalid       : in  std_logic;
    o_rx_axi_wready       : out std_logic;

    -- AXI write response channel
    o_rx_axi_bid          : out std_logic_vector(3 downto 0);
    o_rx_axi_bresp        : out std_logic_vector(1 downto 0);
    o_rx_axi_bvalid       : out std_logic;
    i_rx_axi_bready       : in  std_logic;

    -- AXI read address channel (unused)
    i_rx_axi_arid         : in  std_logic_vector(3 downto 0);
    i_rx_axi_araddr       : in  std_logic_vector(31 downto 0);
    i_rx_axi_arlen        : in  std_logic_vector(3 downto 0);
    i_rx_axi_arsize       : in  std_logic_vector(2 downto 0);
    i_rx_axi_arburst      : in  std_logic_vector(1 downto 0);
    i_rx_axi_arlock       : in  std_logic;
    i_rx_axi_arcache      : in  std_logic_vector(3 downto 0);
    i_rx_axi_arprot       : in  std_logic_vector(2 downto 0);
    i_rx_axi_arvalid      : in  std_logic;
    o_rx_axi_arready      : out std_logic;

    -- AXI read data channel (unused)
    o_rx_axi_rid          : out std_logic_vector(3 downto 0);
    o_rx_axi_rdata        : out std_logic_vector(63 downto 0);
    o_rx_axi_rresp        : out std_logic_vector(1 downto 0);
    o_rx_axi_rlast        : out std_logic;
    o_rx_axi_rvalid       : out std_logic;
    i_rx_axi_rready       : in  std_logic;

    -- input FIFO interface
    i_rx_fifo_read        : in  std_logic;
    o_rx_rvalid           : out std_logic;
    o_rx_data             : out std_logic_vector(G_DATA_PKT_WIDTH-1 downto 0);
    o_rx_addr             : out std_logic_vector(G_ADDR_PKT_WIDTH-1 downto 0);
    o_rx_fifo_e           : out std_logic;
    o_rx_fifo_ae          : out std_logic;
    o_rx_fifo_count       : out std_logic_vector(G_ADDR_PKT_WIDTH-1 downto 0);
    o_rx_fifo_oflow       : out std_logic;
    o_rx_fifo_uflow       : out std_logic;
    o_rx_fifo_db          : out std_logic;
    o_rx_fifo_sb          : out std_logic;

    -- output FIFO interface
    i_tx_fifo_af          : in  std_logic;

    -- interface with internal controller
    i_rx_drop_pkts        : in  std_logic;
    i_write_blank_en      : in  std_logic;
    o_write_blank_ack     : out std_logic
  );
end rx_buffer;

architecture rtl of rx_buffer is
  ---------------------------------------------------------------------------------------------------
  -- Signal declarations
  ---------------------------------------------------------------------------------------------------

  -- internal signals interfacing with the Input FIFO
  signal rx_fifo_ren   : std_logic;
  signal rx_fifo_af    : std_logic;
  signal rx_fifo_valid : std_logic;
  signal rx_fifo_data  : std_logic_vector(G_ADDR_PKT_WIDTH+G_DATA_PKT_WIDTH-1 downto 0);
  signal rx_fifo_e     : std_logic;

  -- CDC signals
  signal rst_n_cdc     : std_logic;

  ---------------------------------------------------------------------------------------------------
  -- Component declarations
  ---------------------------------------------------------------------------------------------------
  component axi_receiver is
    generic (
      -- packet widths
      G_DATA_PKT_WIDTH   : integer := 64; -- width of an AXI data packet
      G_ADDR_PKT_WIDTH   : integer := 8   -- required relative address size
    );
    port (
      -- clock and reset interface
      i_aclk                : in  std_logic;
      i_arst_n              : in  std_logic;

      -- write address channel
      i_rx_axi_awid         : in  std_logic_vector(3 downto 0);
      i_rx_axi_awaddr       : in  std_logic_vector(31 downto 0);
      i_rx_axi_awlen        : in  std_logic_vector(3 downto 0);
      i_rx_axi_awsize       : in  std_logic_vector(2 downto 0);
      i_rx_axi_awburst      : in  std_logic_vector(1 downto 0);
      i_rx_axi_awlock       : in  std_logic;
      i_rx_axi_awcache      : in  std_logic_vector(3 downto 0);
      i_rx_axi_awprot       : in  std_logic_vector(2 downto 0);
      i_rx_axi_awvalid      : in  std_logic;
      o_rx_axi_awready      : out std_logic;

      -- write data channel
      i_rx_axi_wdata        : in  std_logic_vector(63 downto 0);
      i_rx_axi_wstrb        : in  std_logic_vector(7 downto 0);
      i_rx_axi_wlast        : in  std_logic;
      i_rx_axi_wvalid       : in  std_logic;
      o_rx_axi_wready       : out std_logic;

      -- write response channel
      o_rx_axi_bid          : out std_logic_vector(3 downto 0);
      o_rx_axi_bresp        : out std_logic_vector(1 downto 0);
      o_rx_axi_bvalid       : out std_logic;
      i_rx_axi_bready       : in  std_logic;

      -- read address channel (unused)
      i_rx_axi_arid         : in  std_logic_vector(3 downto 0);
      i_rx_axi_araddr       : in  std_logic_vector(31 downto 0);
      i_rx_axi_arlen        : in  std_logic_vector(3 downto 0);
      i_rx_axi_arsize       : in  std_logic_vector(2 downto 0);
      i_rx_axi_arburst      : in  std_logic_vector(1 downto 0);
      i_rx_axi_arlock       : in  std_logic;
      i_rx_axi_arcache      : in  std_logic_vector(3 downto 0);
      i_rx_axi_arprot       : in  std_logic_vector(2 downto 0);
      i_rx_axi_arvalid      : in  std_logic;
      o_rx_axi_arready      : out std_logic;

      -- read data channel (unused)
      o_rx_axi_rid          : out std_logic_vector(3 downto 0);
      o_rx_axi_rdata        : out std_logic_vector(63 downto 0);
      o_rx_axi_rresp        : out std_logic_vector(1 downto 0);
      o_rx_axi_rlast        : out std_logic;
      o_rx_axi_rvalid       : out std_logic;
      i_rx_axi_rready       : in  std_logic;

      -- interface with input FIFO
      i_rx_fifo_af          : in  std_logic;
      o_rx_valid            : out std_logic;
      o_rx_addr             : out std_logic_vector(G_ADDR_PKT_WIDTH-1 downto 0);
      o_rx_data             : out std_logic_vector(G_DATA_PKT_WIDTH downto 0);

      -- interface with output FIFO
      i_tx_fifo_af          : in  std_logic;

      -- interface with internal controller
      i_rx_drop_pkts        : in  std_logic;
      i_write_blank_en      : in  std_logic;
      o_write_blank_ack     : out std_logic
    );
  end component;

  component fifo_DWxNW is
    generic (
      DWIDTH     : integer range 64 to  72 := 64;
      NWORDS     : integer range 16 to 512 := 512;
      AWIDTH     : integer range  4 to  10 := 10;
      AEVAL      : integer range  3 to 510 := 4;
      AFVAL      : integer range  3 to 510 := 500
    );
    port(
      -- Inputs
      CLK        : in  std_logic;
      RCLK       : in  std_logic;
      WCLK       : in  std_logic;
      DATA       : in  std_logic_vector(DWIDTH-1 downto 0);
      RE         : in  std_logic;
      RESET_N    : in  std_logic;
      WE         : in  std_logic;
      -- Outputs
      AEMPTY     : out std_logic;
      AFULL      : out std_logic;
      DB_DETECT  : out std_logic;
      EMPTY      : out std_logic;
      FULL       : out std_logic;
      OVERFLOW   : out std_logic;
      Q          : out std_logic_vector(DWIDTH-2 downto 0);
      RDCNT      : out std_logic_vector(AWIDTH-1 downto 0);
      SB_CORRECT : out std_logic;
      UNDERFLOW  : out std_logic
    );
  end component;

begin

  -- reset signal CDC
  p_rst_n_cdc : process(i_macclk)
  begin
    if (i_macclk'event and i_macclk = '1') then
      rst_n_cdc <= i_arst_n;
      o_rst_n   <= rst_n_cdc;
    end if;
  end process p_rst_n_cdc;

  -- AXI Receiver
  u_axi_receiver : axi_receiver
    generic map (
      G_DATA_PKT_WIDTH => G_DATA_PKT_WIDTH,
      G_ADDR_PKT_WIDTH => G_ADDR_PKT_WIDTH
    )
    port map(
      i_aclk                => i_aclk,
      i_arst_n              => i_arst_n,

      i_rx_axi_awid         => i_rx_axi_awid,
      i_rx_axi_awaddr       => i_rx_axi_awaddr,
      i_rx_axi_awlen        => i_rx_axi_awlen,
      i_rx_axi_awsize       => i_rx_axi_awsize,
      i_rx_axi_awburst      => i_rx_axi_awburst,
      i_rx_axi_awlock       => i_rx_axi_awlock,
      i_rx_axi_awcache      => i_rx_axi_awcache,
      i_rx_axi_awprot       => i_rx_axi_awprot,
      i_rx_axi_awvalid      => i_rx_axi_awvalid,
      o_rx_axi_awready      => o_rx_axi_awready,
      i_rx_axi_wdata        => i_rx_axi_wdata,
      i_rx_axi_wstrb        => i_rx_axi_wstrb,
      i_rx_axi_wlast        => i_rx_axi_wlast,
      i_rx_axi_wvalid       => i_rx_axi_wvalid,
      o_rx_axi_wready       => o_rx_axi_wready,
      o_rx_axi_bid          => o_rx_axi_bid,
      o_rx_axi_bresp        => o_rx_axi_bresp,
      o_rx_axi_bvalid       => o_rx_axi_bvalid,
      i_rx_axi_bready       => i_rx_axi_bready,
      i_rx_axi_arid         => i_rx_axi_arid,
      i_rx_axi_araddr       => i_rx_axi_araddr,
      i_rx_axi_arlen        => i_rx_axi_arlen,
      i_rx_axi_arsize       => i_rx_axi_arsize,
      i_rx_axi_arburst      => i_rx_axi_arburst,
      i_rx_axi_arlock       => i_rx_axi_arlock,
      i_rx_axi_arcache      => i_rx_axi_arcache,
      i_rx_axi_arprot       => i_rx_axi_arprot,
      i_rx_axi_arvalid      => i_rx_axi_arvalid,
      o_rx_axi_arready      => o_rx_axi_arready,
      o_rx_axi_rid          => o_rx_axi_rid,
      o_rx_axi_rdata        => o_rx_axi_rdata,
      o_rx_axi_rresp        => o_rx_axi_rresp,
      o_rx_axi_rlast        => o_rx_axi_rlast,
      o_rx_axi_rvalid       => o_rx_axi_rvalid,
      i_rx_axi_rready       => i_rx_axi_rready,

      i_rx_fifo_af          => rx_fifo_af,
      o_rx_valid            => rx_fifo_valid,
      o_rx_addr             => rx_fifo_data(G_ADDR_PKT_WIDTH+G_DATA_PKT_WIDTH-1 downto G_DATA_PKT_WIDTH),
      o_rx_data             => rx_fifo_data(G_DATA_PKT_WIDTH-1 downto 0),
      i_tx_fifo_af          => i_tx_fifo_af,

      i_rx_drop_pkts        => i_rx_drop_pkts,
      i_write_blank_en      => i_write_blank_en,
      o_write_blank_ack     => o_write_blank_ack
    );

  -- Input FIFO
  u_rx_fifo : fifo_DWxNW
    generic map(
      DWIDTH     => ( G_ADDR_PKT_WIDTH+G_DATA_PKT_WIDTH ),
      NWORDS     => ( NWORDS ),
      AWIDTH     => ( AWIDTH ),
      AEVAL      => ( AEVAL ),
      AFVAL      => ( AFVAL )
    )
    port map(
      -- Inputs
      CLK        => i_macclk,
      RCLK       => i_macclk,
      WCLK       => i_aclk,
      RESET_N    => i_arst_n,
      DATA       => rx_fifo_data,
      RE         => rx_fifo_ren,
      WE         => rx_fifo_valid,
      -- Outputs
      AEMPTY     => o_rx_fifo_ae,
      AFULL      => rx_fifo_af,
      DB_DETECT  => o_rx_fifo_db,
      EMPTY      => rx_fifo_e,
      FULL       => open,
      OVERFLOW   => o_rx_fifo_oflow,
      Q          => o_rx_data,
      RDCNT      => o_rx_fifo_count,
      SB_CORRECT => o_rx_fifo_sb,
      UNDERFLOW  => o_rx_fifo_uflow
    );

  -- process to set read signals on the Input FIFO
  p_fifo_read : process (i_macclk)
  begin
    if (i_macclk'event and i_macclk = '1') then
      if (i_arst_n = '0') then -- TODO need reset synchronous to
        rx_fifo_ren <= '0';
        o_rx_rvalid <= '0';
      else
        rx_fifo_ren <= i_rx_fifo_read and not(rx_fifo_e);
        o_rx_rvalid <= rx_fifo_ren;
      end if;
    end if;
  end process p_fifo_read;

end rtl;
