
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

------------------
-- AXI RECEIVER --
------------------
entity axi_receiver is
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
    o_rx_data             : out std_logic_vector(G_DATA_PKT_WIDTH-1 downto 0);

    -- interface with output FIFO
    i_tx_fifo_af          : in  std_logic;

    -- interface with internal controller
    i_rx_drop_pkts        : in  std_logic;
    i_write_blank_en      : in  std_logic;
    o_write_blank_ack     : out std_logic
  );
end axi_receiver;

architecture rtl of axi_receiver is

  -- AXI signals
  signal axi_awready      : std_logic;
  signal axi_wready       : std_logic;
  signal axi_bresp        : std_logic_vector(1 downto 0);
  signal axi_bvalid       : std_logic;

  -- The axi_awv_awr_flag flag marks the presence of write address valid
  signal axi_awv_awr_flag : std_logic;

  -- registers for CDC
  signal rx_drop_pkts_cdc : std_logic;
  signal write_blank_cdc  : std_logic;

  -- write blank logic
  signal write_blank_en   : std_logic;

begin
  -- I/O Connections assignments

  o_rx_axi_awready   <= axi_awready;
  o_rx_axi_wready    <= axi_wready;
  o_rx_axi_bresp     <= axi_bresp;
  o_rx_axi_bvalid    <= axi_bvalid;
  o_rx_axi_bid       <= i_rx_axi_awid;

  -- The AXI receiver reads are not supported
  o_rx_axi_arready   <= '0';
  o_rx_axi_rdata     <= (others=>'0');
  o_rx_axi_rresp     <= "10"; --SLVERR
  o_rx_axi_rlast     <= '0';
  o_rx_axi_rvalid    <= '0';
  o_rx_axi_rid       <= (others=>'0');

  -- Implement axi_awready generation
  -- axi_awready is asserted for one i_aclk clock cycle when both
  -- i_rx_axi_awvalid and i_rx_axi_wvalid are asserted. axi_awready is
  -- de-asserted when reset is low.
  p_awready: process (i_aclk)
  begin
    if rising_edge(i_aclk) then
      if i_arst_n = '0' then
        axi_awready <= '0';
        axi_awv_awr_flag <= '0';
      else
        if (axi_awready = '0' and i_rx_axi_awvalid = '1' and axi_awv_awr_flag = '0') then
          -- receiver is ready to accept an address and
          -- associated control signals
          axi_awv_awr_flag  <= '1'; -- used for generation of bresp() and bvalid
          axi_awready <= '1';
        elsif (i_rx_axi_wlast = '1' and axi_wready = '1') then
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
      if i_arst_n = '0' then
        axi_wready <= '0';
      else
        -- disable if either FIFO is backed up
        if (i_rx_fifo_af or i_tx_fifo_af) = '1' then
          axi_wready <= '0';

        -- acknowledge write
        elsif (axi_wready = '0' and i_rx_axi_wvalid = '1' and axi_awv_awr_flag = '1') then
          axi_wready <= '1';

        -- de-assert after final packet
        elsif (i_rx_axi_wlast = '1' and axi_wready = '1') then
          axi_wready <= '0';
        end if;
      end if;
    end if;
  end process p_wready;

  -- Implement write response logic generation
  -- The receiver asserts the write response and response valid signals
  -- when axi_wready, i_rx_axi_wvalid, axi_wready and i_rx_axi_wvalid are asserted.
  -- This marks the acceptance of address and indicates the status of
  -- write transaction.
  p_response: process (i_aclk)
  begin
    if rising_edge(i_aclk) then
      if i_arst_n = '0' then
        axi_bvalid  <= '0';
        axi_bresp  <= "00"; --need to work more on the responses
        -- ADD SLVERR ("10") on
        -- ADD DECERR ("11") on write to invalid address (not 64 bits align)
      else
        if (axi_awv_awr_flag = '1' and axi_wready = '1' and i_rx_axi_wvalid = '1' and axi_bvalid = '0' and i_rx_axi_wlast = '1' ) then
          axi_bvalid <= '1';
          axi_bresp  <= "00";
        elsif (i_rx_axi_bready = '1' and axi_bvalid = '1') then
          axi_bvalid <= '0';
        end if;
      end if;
    end if;
  end process p_response;

  ------------------------------------------
  -- Output to module
  ------------------------------------------

  p_output: process (i_aclk)
  begin
    if rising_edge(i_aclk) then
      if i_arst_n = '0' then
        o_rx_valid       <= '0';
        o_rx_addr        <= (others=>'0');
        o_rx_data        <= (others=>'0');
        rx_drop_pkts_cdc <= '0';
        write_blank_cdc  <= '0';
        write_blank_en   <= '0';
      else
        -- perform CDC on control signals from Input FSM
        rx_drop_pkts_cdc <= i_rx_drop_pkts;
        write_blank_cdc  <= i_write_blank_en;

        -- output write data
        if (write_blank_en = '1') then
          -- output blank packet
          o_rx_valid        <= '1';
          o_rx_data         <= (others => '0');
          o_rx_addr         <= "00000001";
          o_write_blank_ack <= '1';
          write_blank_en    <= '0';
        else
          o_rx_valid        <= axi_wready and i_rx_axi_wvalid and not(rx_drop_pkts_cdc);
          o_rx_data         <= i_rx_axi_wdata(G_DATA_PKT_WIDTH-1 downto 0);

          -- latch write address
          if (i_rx_axi_awvalid = '1') then
            o_rx_addr   <= i_rx_axi_awaddr(G_ADDR_PKT_WIDTH-1 downto 0);
          end if;

          -- write blank packet in next CC if enabled and end of burst
          write_blank_en    <= write_blank_cdc and i_rx_axi_wlast;
          o_write_blank_ack <= '0';
        end if;
      end if;
    end if;
  end process p_output;

end rtl;
