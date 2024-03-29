
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------
-- AXI Transmitter and Output FIFO --
-------------------------------------
entity tx_buffer is
  generic (
    -- FIFO capacity
    NWORDS           : integer range 16 to 512 := 512;
    AWIDTH           : integer range  4 to  10 := 10;
    AEVAL            : integer range  3 to 510 := 4;
    AFVAL            : integer range  3 to 510 := 500;

    -- packet widths
    G_DATA_PKT_WIDTH : integer := 64 -- width of an AXI data packet
  );
  port (

    -- clock and reset interface
    i_macclk            : in  std_logic;
    i_aclk              : in  std_logic;
    i_arst_n            : in  std_logic;

    -- interface with internal controller
    i_accept_w          : in  std_logic_vector(1 downto 0);
    i_base_addr         : in  std_logic_vector(31 downto 0);
    i_new_addr          : in  std_logic;

    -- FIFO interface
    i_w0_wdata          : in  std_logic_vector(31 downto 0);
    i_w0_wen            : in  std_logic;
    i_w1_wdata          : in  std_logic_vector(31 downto 0);
    i_w1_wen            : in  std_logic;
    o_tx_fifo_af        : out std_logic;
    o_tx_fifo_db        : out std_logic;
    o_tx_fifo_sb        : out std_logic;
    o_tx_fifo_oflow     : out std_logic;
    o_tx_fifo_uflow     : out std_logic;

    -- AXI write address channel
    o_tx_axi_awid       : out std_logic_vector(3 downto 0);
    o_tx_axi_awaddr     : out std_logic_vector(31 downto 0);
    o_tx_axi_awlen      : out std_logic_vector(3 downto 0);
    o_tx_axi_awsize     : out std_logic_vector(2 downto 0);
    o_tx_axi_awburst    : out std_logic_vector(1 downto 0);
    o_tx_axi_awlock     : out std_logic;
    o_tx_axi_awcache    : out std_logic_vector(3 downto 0);
    o_tx_axi_awprot     : out std_logic_vector(2 downto 0);
    o_tx_axi_awvalid    : out std_logic;
    i_tx_axi_awready    : in  std_logic;

    -- AXI write data channel
    o_tx_axi_wdata      : out std_logic_vector(63 downto 0);
    o_tx_axi_wstrb      : out std_logic_vector(7 downto 0);
    o_tx_axi_wlast      : out std_logic;
    o_tx_axi_wvalid     : out std_logic;
    i_tx_axi_wready     : in  std_logic;

    -- AXI write response channel
    i_tx_axi_bid        : in  std_logic_vector(3 downto 0);
    i_tx_axi_bresp      : in  std_logic_vector(1 downto 0);
    i_tx_axi_bvalid     : in  std_logic;
    o_tx_axi_bready     : out std_logic;

    -- AXI read address channel (unused)
    o_tx_axi_arid       : out std_logic_vector(3 downto 0);
    o_tx_axi_araddr     : out std_logic_vector(31 downto 0);
    o_tx_axi_arlen      : out std_logic_vector(3 downto 0);
    o_tx_axi_arsize     : out std_logic_vector(2 downto 0);
    o_tx_axi_arburst    : out std_logic_vector(1 downto 0);
    o_tx_axi_arlock     : out std_logic;
    o_tx_axi_arcache    : out std_logic_vector(3 downto 0);
    o_tx_axi_arprot     : out std_logic_vector(2 downto 0);
    o_tx_axi_arvalid    : out std_logic;
    i_tx_axi_arready    : in  std_logic;

    -- AXI read data channel (unused)
    i_tx_axi_rid        : in  std_logic_vector(3 downto 0);
    i_tx_axi_rdata      : in  std_logic_vector(63 downto 0);
    i_tx_axi_rresp      : in  std_logic_vector(1 downto 0);
    i_tx_axi_rlast      : in  std_logic;
    i_tx_axi_rvalid     : in  std_logic;
    o_tx_axi_rready     : out std_logic
  );
end tx_buffer;

architecture rtl of tx_buffer is

  ---------------------------------------------------------------------------------------------------
  -- Signal declarations
  ---------------------------------------------------------------------------------------------------

  -- internal signals interfacing with the Output FIFO
  signal tx_fifo_data       : std_logic_vector(63 downto 0);
  signal tx_fifo_wen        : std_logic;
  signal tx_fifo_slot       : std_logic;

  -- internal signals interfacing with the AXI Transmitter
  signal payload_fifo_count : std_logic_vector(AWIDTH-1 downto 0);
  signal payload_read       : std_logic;
  signal payload_data       : std_logic_vector(63 downto 0);

  ---------------------------------------------------------------------------------------------------
  -- Component declarations
  ---------------------------------------------------------------------------------------------------
  component axi_transmitter is
    generic (
      -- FIFO capacity
      NWORDS              : integer range 16 to 512 := 512;
      AWIDTH              : integer range  4 to  10 := 10
    );
    port (
      -- clock and reset interface
      i_macclk            : in  std_logic;
      i_aclk              : in  std_logic;
      i_arst_n            : in  std_logic;

      -- interface with internal controller
      i_header_request    : in  std_logic;
      i_payload_request   : in  std_logic;
      i_base_addr         : in  std_logic_vector(31 downto 0);
      i_new_addr          : in  std_logic;

      -- interface with output FIFO
      i_pkt_cnt           : in  std_logic_vector(AWIDTH-1 downto 0);
      o_pkt_read          : out std_logic;
      i_pkt               : in  std_logic_vector(63 downto 0);

      -- write address channel
      o_tx_axi_awid       : out std_logic_vector( 3 downto 0);
      o_tx_axi_awaddr     : out std_logic_vector(31 downto 0);
      o_tx_axi_awlen      : out std_logic_vector( 3 downto 0);
      o_tx_axi_awsize     : out std_logic_vector( 2 downto 0);
      o_tx_axi_awburst    : out std_logic_vector( 1 downto 0);
      o_tx_axi_awlock     : out std_logic;
      o_tx_axi_awcache    : out std_logic_vector( 3 downto 0);
      o_tx_axi_awprot     : out std_logic_vector( 2 downto 0);
      o_tx_axi_awvalid    : out std_logic;
      i_tx_axi_awready    : in  std_logic;

      -- write data channel
      o_tx_axi_wdata      : out std_logic_vector(63 downto 0);
      o_tx_axi_wstrb      : out std_logic_vector( 7 downto 0);
      o_tx_axi_wlast      : out std_logic;
      o_tx_axi_wvalid     : out std_logic;
      i_tx_axi_wready     : in  std_logic;

      -- write response channel
      i_tx_axi_bid        : in  std_logic_vector( 3 downto 0);
      i_tx_axi_bresp      : in  std_logic_vector( 1 downto 0);
      i_tx_axi_bvalid     : in  std_logic;
      o_tx_axi_bready     : out std_logic;

      -- read address channel (unused)
      o_tx_axi_arid       : out std_logic_vector( 3 downto 0);
      o_tx_axi_araddr     : out std_logic_vector(31 downto 0);
      o_tx_axi_arlen      : out std_logic_vector( 3 downto 0);
      o_tx_axi_arsize     : out std_logic_vector( 2 downto 0);
      o_tx_axi_arburst    : out std_logic_vector( 1 downto 0);
      o_tx_axi_arlock     : out std_logic;
      o_tx_axi_arcache    : out std_logic_vector( 3 downto 0);
      o_tx_axi_arprot     : out std_logic_vector( 2 downto 0);
      o_tx_axi_arvalid    : out std_logic;
      i_tx_axi_arready    : in  std_logic;

      -- read data channel (unused)
      i_tx_axi_rid        : in  std_logic_vector( 3 downto 0);
      i_tx_axi_rdata      : in  std_logic_vector(63 downto 0);
      i_tx_axi_rresp      : in  std_logic_vector( 1 downto 0);
      i_tx_axi_rlast      : in  std_logic;
      i_tx_axi_rvalid     : in  std_logic;
      o_tx_axi_rready     : out std_logic
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

  -- process to arbitrate 64-bit writes to the Output FIFO
  p_fifo_arbitrate : process(i_macclk)
  begin
    if (i_macclk'event and i_macclk = '1') then
      if (i_arst_n = '0') then
        tx_fifo_slot <= '0';
        tx_fifo_wen  <= '0';
        tx_fifo_data <= (others => '0');
      else
        -- accept write from writer 0 when enabled
        if ((i_accept_w(0) and i_w0_wen) = '1') then
          tx_fifo_slot <= not(tx_fifo_slot);
          if (tx_fifo_slot = '0') then
            -- copy to the 32 LSbs
            tx_fifo_data(31 downto 0) <= i_w0_wdata;
          else
            -- copy to the 32 MSbs
            tx_fifo_data(63 downto 32) <= i_w0_wdata;
            -- write a full 64-bit packet
            tx_fifo_wen <= '1';
          end if;

        -- accept write from writer 1 when enabled
        elsif ((i_accept_w(1) and i_w1_wen) = '1') then
          tx_fifo_slot <= not(tx_fifo_slot);
          if (tx_fifo_slot = '0') then
            -- copy to the 32 LSbs
            tx_fifo_data(31 downto 0) <= i_w1_wdata;
          else
            -- copy to the 32 MSbs
            tx_fifo_data(63 downto 32) <= i_w1_wdata;
            -- write a full 64-bit packet
            tx_fifo_wen <= '1';
          end if;

        -- no write or not enabled
        else
          tx_fifo_wen <= '0';
        end if;
      end if;
    end if;
  end process p_fifo_arbitrate;

  -- Output FIFO
  u_tx_fifo : fifo_DWxNW
    generic map(
      DWIDTH     => ( G_DATA_PKT_WIDTH ),
      NWORDS     => ( NWORDS ),
      AWIDTH     => ( AWIDTH ),
      AEVAL      => ( AEVAL ),
      AFVAL      => ( AFVAL )
    )
    port map(
      -- Inputs
      CLK        => i_macclk,
      RCLK       => i_aclk,
      WCLK       => i_macclk,
      RESET_N    => i_arst_n,
      DATA       => tx_fifo_data,
      RE         => payload_read,
      WE         => tx_fifo_wen,
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

  -- AXI Transmitter
  u_axi_transmitter : axi_transmitter
    generic map (
      -- FIFO capacity
      NWORDS              => ( NWORDS ),
      AWIDTH              => ( AWIDTH )
    )
    port map (
      -- clock and reset interface
      i_macclk            => i_macclk,
      i_aclk              => i_aclk,
      i_arst_n            => i_arst_n,

      -- interface with internal controller
      i_header_request    => i_accept_w(1), -- header is writer 1
      i_payload_request   => i_accept_w(0), -- payload is writer 0
      i_base_addr         => i_base_addr,
      i_new_addr          => i_new_addr,

      -- interface with output FIFO
      i_pkt_cnt           => payload_fifo_count,
      o_pkt_read          => payload_read,
      i_pkt               => payload_data,

      -- write address channel
      o_tx_axi_awid       => o_tx_axi_awid,
      o_tx_axi_awaddr     => o_tx_axi_awaddr,
      o_tx_axi_awlen      => o_tx_axi_awlen,
      o_tx_axi_awsize     => o_tx_axi_awsize,
      o_tx_axi_awburst    => o_tx_axi_awburst,
      o_tx_axi_awlock     => o_tx_axi_awlock,
      o_tx_axi_awcache    => o_tx_axi_awcache,
      o_tx_axi_awprot     => o_tx_axi_awprot,
      o_tx_axi_awvalid    => o_tx_axi_awvalid,
      i_tx_axi_awready    => i_tx_axi_awready,

      -- write data channel
      o_tx_axi_wdata      => o_tx_axi_wdata,
      o_tx_axi_wstrb      => o_tx_axi_wstrb,
      o_tx_axi_wlast      => o_tx_axi_wlast,
      o_tx_axi_wvalid     => o_tx_axi_wvalid,
      i_tx_axi_wready     => i_tx_axi_wready,

      -- write response channel
      i_tx_axi_bid        => i_tx_axi_bid,
      i_tx_axi_bresp      => i_tx_axi_bresp,
      i_tx_axi_bvalid     => i_tx_axi_bvalid,
      o_tx_axi_bready     => o_tx_axi_bready,

      -- read address channel (unused)
      o_tx_axi_arid       => open,
      o_tx_axi_araddr     => open,
      o_tx_axi_arlen      => open,
      o_tx_axi_arsize     => open,
      o_tx_axi_arburst    => open,
      o_tx_axi_arlock     => open,
      o_tx_axi_arcache    => open,
      o_tx_axi_arprot     => open,
      o_tx_axi_arvalid    => open,
      i_tx_axi_arready    => '0',

      -- read data channel (unused)
      i_tx_axi_rid        => (others => '0'),
      i_tx_axi_rdata      => (others => '0'),
      i_tx_axi_rresp      => (others => '0'),
      i_tx_axi_rlast      => '0',
      i_tx_axi_rvalid     => '0',
      o_tx_axi_rready     => open
    );

  o_tx_axi_arid       <= (others => '0');
  o_tx_axi_araddr     <= (others => '0');
  o_tx_axi_arlen      <= (others => '0');
  o_tx_axi_arsize     <= (others => '0');
  o_tx_axi_arburst    <= (others => '0');
  o_tx_axi_arlock     <= '0';
  o_tx_axi_arcache    <= (others => '0');
  o_tx_axi_arprot     <= (others => '0');
  o_tx_axi_arvalid    <= '0';
  o_tx_axi_rready     <= '0';

end rtl;