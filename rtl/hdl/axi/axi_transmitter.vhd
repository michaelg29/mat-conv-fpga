
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.mat_conv_axi_pkg.all;

---------------------
-- AXI TRANSMITTER --
---------------------
entity axi_transmitter is
  port (
    -- clock and reset interface
    i_aclk              : in  std_logic;
    i_areset_n          : in  std_logic;

    -- interface with internal controller
    i_payload_request   : in  std_logic;
    o_payload_done      : out std_logic;
    i_header_request    : in  std_logic;
    i_header_status_upd : in  std_logic;
    i_header            : in  TYPE_ARRAY_OF_32BITS(9 downto 0);
    o_header_ack        : out std_logic;

    -- interface with output FIFO
    i_payload_fifo_cnt  : in  std_logic_vector(9 downto 0);
    o_payload_read      : out std_logic;
    i_payload_data      : in  std_logic_vector(63 downto 0);

    -- write address channel
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

    -- write data channel
    o_tx_axi_wdata      : out std_logic_vector(63 downto 0);
    o_tx_axi_wstrb      : out std_logic_vector(7 downto 0);
    o_tx_axi_wlast      : out std_logic;
    o_tx_axi_wvalid     : out std_logic;
    i_tx_axi_wready     : in  std_logic;

    -- write response channel
    i_tx_axi_bid        : in  std_logic_vector(3 downto 0);
    i_tx_axi_bresp      : in  std_logic_vector(1 downto 0);
    i_tx_axi_bvalid     : in  std_logic;
    o_tx_axi_bready     : out std_logic;

    -- read address channel (unused)
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

    -- read data channel (unused)
    i_tx_axi_rid        : in  std_logic_vector(3 downto 0);
    i_tx_axi_rdata      : in  std_logic_vector(63 downto 0);
    i_tx_axi_rresp      : in  std_logic_vector(1 downto 0);
    i_tx_axi_rlast      : in  std_logic;
    i_tx_axi_rvalid     : in  std_logic;
    o_tx_axi_rready     : out std_logic
  );
end axi_transmitter;

architecture arch_imp of axi_transmitter is

  ---------------------------------------------------------------------------------------------------
  -- Local Constant declarations
  ---------------------------------------------------------------------------------------------------
  constant ALL_READY   : std_logic_vector(23 downto 0) := (others=>'1');
  constant ALL_NOT_READY : std_logic_vector(23 downto 0) := (others=>'0');
  ---------------------------------------------------------------------------------------------------
  -- Signal declarations
  ---------------------------------------------------------------------------------------------------
  type TYPE_AXI_MASTER_FSM_STATE is (
    IDLE,
    CHECK_PAYLOAD,
    SEND_PAYLOAD,
    SEND_HEADER,
    ACKNOWLEDGE,
    REQ_HEADER
  );
  signal axi_master_fsm_state   : TYPE_AXI_MASTER_FSM_STATE;

  signal header_request     : std_logic;
  signal header             : TYPE_ARRAY_OF_32BITS(9 downto 0);
  signal header_count       : integer range 0 to 7;
  signal payload_size_rest  : std_logic_vector(15 downto 0);
  signal payload_count      : integer range 0 to 15;
  signal only_one_payload   : std_logic;

  signal request_header     : std_logic;
  signal request_header_p   : std_logic;
  signal request_payload    : std_logic;
  signal request_payload_p  : std_logic;

  -- AXI4FULL signals
  signal axi_awaddr   : std_logic_vector(31 downto 0);
  signal axi_awvalid  : std_logic;
  signal axi_wdata    : std_logic_vector(63 downto 0);
  signal axi_wlast    : std_logic;
  signal axi_wvalid   : std_logic;
  signal axi_awlen    : std_logic_vector(3 downto 0);

begin

  axi_wdata <= header((2*header_count) + 1) & header(2*header_count) when request_header = '1' else i_payload_data;

  o_payload_read <= request_payload and i_tx_axi_wready and axi_wvalid;

  p_main: process (i_aclk)
  begin
    if rising_edge (i_aclk) then
      if (i_areset_n = '0') then
        axi_master_fsm_state  <= IDLE;
        header_request        <= '0';
        o_payload_done        <= '0';
        o_header_ack          <= '0';
        header                <= (others=>(others=>'0'));
        header_count          <= 0;
        payload_count         <= 0;
        only_one_payload      <= '0';

        request_header        <= '0';
        request_header_p      <= '0';
        request_payload       <= '0';
        request_payload_p     <= '0';

        axi_awaddr    <= (others=>'0');
        axi_awlen     <= (others=>'0');

        axi_awvalid   <= '0';
        axi_wvalid    <= '0';
        axi_wlast     <= '0';

      else
        if (i_header_request = '1') then
          header_request <= '1';
        end if;

        o_header_ack          <= '0';
        request_header_p      <= '0';
        request_payload_p     <= '0';
        case (axi_master_fsm_state) is
          when IDLE =>
            header_count           <= 0;
            request_header         <= '0';
            request_payload        <= '0';
            only_one_payload       <= '0';
            if (i_header_request = '1') then
              o_payload_done  <= '0';
              header       <= i_header;
              if ((i_header(4)(31 downto 16) = 0) or ( i_header(7)(0) = '0') or ( i_header(7)(10) = '1')) then -- no payload in tx packet or CMD not OK or PHY Timeout
                axi_master_fsm_state  <= SEND_HEADER;
                axi_awaddr            <= i_header(5);
                axi_awlen             <= x"4"; -- 5 QWords for header only
                request_header        <= '1';
                request_header_p      <= '1';
              else
                axi_master_fsm_state   <= CHECK_PAYLOAD;
                axi_awaddr             <= i_header(5) + x"28"; -- skip header
                if (i_header(4)(31 downto 16) > 16) then
                  payload_size_rest      <= i_header(4)(31 downto 16) - x"10";
                  axi_awlen              <= x"F";
                  payload_count          <= 15;
                else
                  payload_size_rest      <= (others=>'0');
                  axi_awlen              <= i_header(4)(19 downto 16) - '1'; -- payload size (minus 1)
                  payload_count          <= conv_integer(i_header(4)(31 downto 16) - '1');
                  if (i_header(4)(31 downto 16) = 1) then
                    only_one_payload <= '1';
                  end if;
                end if;
              end if;
            elsif (i_payload_request = '1') then
              header          <= i_header;

              axi_master_fsm_state   <= CHECK_PAYLOAD;
              axi_awaddr             <= i_header(5) + x"28"; -- skip header
              payload_size_rest      <= i_header(4)(31 downto 16) - x"10";
              axi_awlen              <= x"F";
              payload_count          <= 15;


            end if;

          when CHECK_PAYLOAD =>
            if  (i_header(7)(10) = '1') then
              axi_master_fsm_state  <= SEND_HEADER;
              axi_awaddr            <= i_header(5);
              axi_awlen             <= x"4"; -- 5 QWords for header only
              request_header        <= '1';
              request_header_p      <= '1';
            elsif (i_payload_fifo_count >= payload_count + 1) then
              axi_master_fsm_state   <= SEND_PAYLOAD;
              request_payload        <= '1';
              request_payload_p      <= '1';
            end if;


          when SEND_PAYLOAD =>
            if (request_payload_p = '1') then
              axi_wvalid   <= '1';
            elsif ((payload_count = 0) and (i_tx_axi_wready = '1')) then
              axi_wvalid   <= '0';
            end if;

            if (payload_count = 0) then
              if (only_one_payload = '0') then
                if (payload_size_rest = 0 ) then
                  axi_master_fsm_state   <= REQ_HEADER;

                  o_payload_done         <= '1';
                  request_payload        <= '0';
                else
                  if (payload_size_rest > 16) then
                    payload_size_rest      <= payload_size_rest - x"10";
                    axi_awlen              <= x"F";
                    payload_count          <= 15;
                  else
                    payload_size_rest      <= (others=>'0');
                    if (only_one_payload = '1') then
                      axi_awlen              <= x"0";
                      payload_count          <= 0;
                    else
                      axi_awlen              <= payload_size_rest(3 downto 0) - '1'; -- payload size (minus 1)
                      payload_count          <= conv_integer(payload_size_rest - '1');
                    end if;
                  end if;

                  axi_master_fsm_state   <= CHECK_PAYLOAD;
                  axi_awaddr             <= axi_awaddr + x"80";

                end if;
              end if;

            elsif (i_tx_axi_wready = '1') then
              payload_count <= payload_count - 1;
            end if;

            if (only_one_payload = '1' ) then
              axi_wlast     <= '1';
              if (i_tx_axi_wready = '1') then
                only_one_payload <= '0';
              end if;
            elsif ((payload_count = 1) and (i_tx_axi_wready = '1')) then
              axi_wlast     <= '1';
            else
              axi_wlast     <= '0';
            end if;

          when SEND_HEADER =>

            if (request_header_p = '1') then
              axi_wvalid   <= '1';
            elsif ((header_count = 4) and (i_tx_axi_wready = '1')) then
              axi_wvalid   <= '0';
            end if;

            if ((header_count = 4) and (i_tx_axi_wready = '1')) then
              o_header_ack          <= '1';
              axi_master_fsm_state  <= IDLE;
              header_request        <= '0';
            elsif (i_tx_axi_wready = '1') then
              header_count <= header_count + 1;
            end if;

            if ((header_count = 3) and (i_tx_axi_wready = '1')) then
              axi_wlast     <= '1';
            elsif (i_tx_axi_wready = '1') then
              axi_wlast     <= '0';
            end if;

        when REQ_HEADER =>
          if (header_request = '1') then
            header_request        <= '0';
            axi_master_fsm_state  <= SEND_HEADER;
            axi_awaddr            <= header(5);
            axi_awlen             <= x"4"; -- 5 QWords for header only
            request_header        <= '1';
            request_header_p      <= '1';
          end if;

        when ACKNOWLEDGE =>
          axi_master_fsm_state   <= IDLE;

        when others =>
          axi_master_fsm_state   <= IDLE;
        end case;

      end if;
      -- Always take latest status info
      header(7)             <= i_header(7); -- update Status

      if ((request_header_p = '1') or (request_payload_p = '1')) then
        axi_awvalid   <= '1';
      elsif ((i_tx_axi_awready = '1') and (axi_awvalid = '1')) then
          axi_awvalid   <= '0';
      end if;

    end if;
  end process p_main;


  -- I/O Connections assignments
  o_tx_axi_awid    <= (others=>'0');
  o_tx_axi_awaddr  <= axi_awaddr;
  o_tx_axi_awlen   <= axi_awlen;
  o_tx_axi_awsize  <= "011";
  o_tx_axi_awburst <= "01";
  o_tx_axi_awlock  <= '0';
  o_tx_axi_awcache <= "0010";
  o_tx_axi_awprot  <= "000";
  o_tx_axi_awvalid <= axi_awvalid;
  o_tx_axi_wdata   <= axi_wdata;
  o_tx_axi_wstrb   <= (others=>'1');
  o_tx_axi_wlast   <= axi_wlast;
  o_tx_axi_wvalid  <= axi_wvalid;
  o_tx_axi_bready  <= '1';

  -- The AXI transmitter reads are not supported
  o_tx_axi_arid    <= (others=>'0');
  o_tx_axi_araddr  <= (others=>'0');
  o_tx_axi_arlen   <= (others=>'0');
  o_tx_axi_arsize  <= (others=>'0');
  o_tx_axi_arburst <= "01";
  o_tx_axi_arlock  <= '0';
  o_tx_axi_arcache <= "0010";
  o_tx_axi_arprot  <= "000";
  o_tx_axi_arvalid <= '0';
  o_tx_axi_rready  <= '0';
  ----------------------

end arch_imp;
