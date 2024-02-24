
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library mem_wrapper_library;
use mem_wrapper_library.all;

-----------------------------
-- Global memory submodule --
-----------------------------
entity global_mem is
  generic (
    -- latency of a read in clock cycles
    READ_LATENCY     : integer
  );
  port (
    -- clock and reset
    i_aclk           : in  std_logic;
    i_macclk         : in  std_logic;
    i_rst_n          : in  std_logic;

    -- APB Rx
    i_reg_ar_ren     : in  std_logic;
    o_reg_ar_rdata   : out std_logic_vector(31 downto 0);
    o_reg_ar_rvalid  : out std_logic;

    -- AXI Rx
    i_ack_cw0_addr   : in  std_logic_vector( 3 downto 0);
    i_ack_cw0_wen    : in  std_logic;
    i_ack_cw0_wdata  : in  std_logic_vector(63 downto 0);

    -- AXI Tx
    i_reg_cw1_wen    : in  std_logic;
    i_reg_cw1_wdata  : in  std_logic_vector(31 downto 0);

    -- Input FSM
    i_reg_cw0_addr   : in  std_logic_vector( 1 downto 0);
    i_reg_cw0_wen    : in  std_logic;
    i_reg_cw0_wdata  : in  std_logic_vector(31 downto 0);
    i_reg_ar0_ren    : in  std_logic;
    o_reg_ar0_rdata  : out std_logic_vector(31 downto 0);
    o_reg_ar0_rvalid : out std_logic;

    -- Output FSM
    i_accept_reg_cw1 : in  std_logic;
    i_ack_ar_addr    : in  std_logic_vector( 2 downto 0);
    i_ack_ar_ren     : in  std_logic;
    o_ack_ar_rdata   : out std_logic_vector(31 downto 0);
    o_ack_ar_rvalid  : out std_logic
  );
end global_mem;

architecture rtl of global_mem is

  --------------------------------------
  -- Internal memory block components --
  --------------------------------------

  component acknowledge_buffer is
    generic (
      -- latency of a read in clock cycles
      READ_LATENCY : integer
    );
    port (
      -- clock and reset
      i_aclk       : in  std_logic;
      i_macclk     : in  std_logic;
      i_rst_n      : in  std_logic;

      -- port A reader - Output FSM
      i_ar_addr    : in  std_logic_vector( 2 downto 0);
      i_ar_ren     : in  std_logic;
      o_ar_rdata   : out std_logic_vector(31 downto 0);
      o_ar_rvalid  : out std_logic;

      -- port C writer 0 - AXI Rx
      i_cw0_addr   : in  std_logic_vector( 3 downto 0);
      i_cw0_wen    : in  std_logic;
      i_cw0_wdata  : in  std_logic_vector(63 downto 0);

      -- port C writer 1 - Input FSM
      i_cw1_wen    : in  std_logic;
      i_cw1_addr   : in  std_logic_vector( 1 downto 0);
      i_cw1_wdata  : in  std_logic_vector( 4 downto 0)
    );
  end component;

begin

  ------------------------------------------
  -- Internal memory block instantiations --
  ------------------------------------------

  ACK_BUF : acknowledge_buffer
    generic map (
      -- latency of a read in clock cycles
      READ_LATENCY => READ_LATENCY
    )
    port map (
      -- clock and reset
      i_aclk       => i_aclk,
      i_macclk     => i_macclk,
      i_rst_n      => i_rst_n,

      -- port A reader - Output FSM
      i_ar_addr    => i_ack_ar_addr,
      i_ar_ren     => i_ack_ar_ren,
      o_ar_rdata   => o_ack_ar_rdata,
      o_ar_rvalid  => o_ack_ar_rvalid,

      -- port C writer 0 - AXI Rx
      i_cw0_addr   => i_ack_cw0_addr,
      i_cw0_wen    => i_ack_cw0_wen,
      i_cw0_wdata  => i_ack_cw0_wdata,

      -- port C writer 1 - Input FSM (copy signals from writes to register file)
      i_cw1_wen    => i_reg_cw0_wen,
      i_cw1_addr   => i_reg_cw0_addr,
      i_cw1_wdata  => i_reg_cw0_wdata(4 downto 0)
    );

end rtl;
