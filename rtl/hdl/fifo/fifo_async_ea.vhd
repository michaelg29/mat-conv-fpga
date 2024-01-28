
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_async is
  generic (
    -- address depth in bits (2**ADDR_WIDTH-1 elements)
    ADDR_WIDTH : integer   := 5;
    -- element width
    W_EL       : integer   := 64;
    -- give priority to the writer ('1') or reader ('0')
    PRIORITY_W : std_logic := '0'
  );
  port (
    -- Asynchronous
    i_rst_n  : in  std_logic;

    -- Reader clock domain
    i_rclk   : in  std_logic;
    i_ren    : in  std_logic;
    o_rdata  : out std_logic_vector(W_EL-1 downto 0);
    o_empty  : out std_logic;
    o_rvalid : out std_logic;
    o_rerr   : out std_logic;

    -- Writer clock domain
    i_wclk   : in  std_logic;
    i_wdata  : in  std_logic_vector(W_EL-1 downto 0);
    i_wen    : in  std_logic;
    o_full   : out std_logic;
    o_wvalid : out std_logic;
    o_werr   : out std_logic
  );
end fifo_async;

architecture rtl of fifo_async is

  type fifo_mem_t is array (2 ** ADDR_WIDTH-1 downto 0) of std_logic_vector(W_EL-1 downto 0);
  signal mem    : fifo_mem_t;

  signal wptr   : unsigned(ADDR_WIDTH downto 0);
  signal rptr   : unsigned(ADDR_WIDTH downto 0);

  signal empty  : std_logic := '1';
  signal full   : std_logic := '0';

  signal rerr   : std_logic := '0';
  signal werr   : std_logic := '0';

  signal wgrant : std_logic := '0';

begin

  -- internal continuous signal assignments
  --full  <= '1' when rptr(ADDR_WIDTH-1 downto 0) = wptr(ADDR_WIDTH-1 downto 0) and not(rptr(ADDR_WIDTH) = wptr(ADDR_WIDTH)) else '0';
  --empty <= '1' when rptr(ADDR_WIDTH-1 downto 0) = wptr(ADDR_WIDTH-1 downto 0) and rptr(ADDR_WIDTH) = wptr(ADDR_WIDTH) else '0';

  --rerr  <= i_ren and empty;
  --werr  <= i_wen and full;

  -- continuous external signal assignments
  o_empty <= empty;
  o_full  <= full;
  o_rerr  <= rerr;
  o_werr  <= werr;

  G_WRITE_PRIORITY: if PRIORITY_W = '1' generate begin
    -- writer has priority
    -- reader can only read when not empty and writer is not writing
    function WriterGrant (ren: std_logic, wen: std_logic, empty: std_logic, full: std_logic) is
    begin
      return wen and not(full);
    end;
  end generate;

  G_READ_PRIORITY: if PRIORITY_W = '0' generate begin
    -- reader has priority
    -- writer can only write when not full and reader is not reading
    function WriterGrant (ren: std_logic, wen: std_logic, empty: std_logic, full: std_logic) is
    begin
      return (not(ren) or empty) and not(full);
    end;
  end generate;

  -- check if the buffer is empty or full with an update to the internal pointers
  P_CHECK_EMPTY_FULL : process(i_rst_n, rptr, wptr)
  begin
    if (i_rst_n = '0') then
      -- reset internal status asynchronously
      empty <= '1';
      full  <= '0';
    -- check address equality
    elsif (rptr(ADDR_WIDTH-1 downto 0) = wptr(ADDR_WIDTH-1 downto 0)) then
      if (rptr(ADDR_WIDTH) = wptr(ADDR_WIDTH)) then
        empty <= '1';
        full  <= '0';
      else
        empty <= '0';
        full  <= '1';
      end if;
    else
      empty <= '0';
      full  <= '1';
    end if;
  end process;

  -- read process, clocked by i_rclk
  P_READ : process(i_rst_n, i_rclk)
  begin
    if (i_rst_n = '0') then
      -- reset internal status asynchronously
      rerr  <= '0';
      rptr  <= (others => '0');
    end if;
    if (i_rclk'event and i_rclk = '1') then
      if (i_rst_n = '0') then
        -- reset read interface synchronously
        o_rdata  <= (others => '0');
        o_rvalid <= '0';
      else
        if (i_ren = '1') then
          -- check for error
          if (empty = '1') then
            rerr <= '1';
          else
            rerr <= '0';
          end if;

          -- execute read
          if (WriterGrant(i_ren, i_wen, empty, full) = '0') then
            -- update internal status
            rptr <= rptr + 1;

            -- update interface
            o_rvalid <= '1';
            o_rdata  <= mem(to_integer(rptr(ADDR_WIDTH-1 downto 0)));
          else
            -- persist internal status
            rptr <= rptr;

            -- update interface
            o_rvalid <= '0';
            o_rdata  <= (others => '0');
          end if;
        else
          -- persist internal status
          rerr <= '0';
          rptr <= rptr;

          -- update interface
          o_rvalid <= '0';
          o_rdata  <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  -- write process, clocked by i_wclk
  P_WRITE : process(i_rst_n, i_wclk)
  begin
    if (i_rst_n = '0') then
      -- reset internal status asynchronously
      wptr <= (others => '0');
    end if;
    if (i_wclk'event and i_wclk = '1') then
      if (i_rst_n = '0') then
        -- reset write interface synchronously
        o_full   <= '0';
        o_wvalid <= '0';
        o_werr   <= '0';
      else
        o_full <= full;
        o_werr <= werr;
        if (i_wen = '1' and wgrant = '1') then
          -- update internal status
          wptr <= wptr + 1;

          -- update memory
          mem(to_integer(wptr(ADDR_WIDTH-1 downto 0))) <= i_wdata;

          -- update interface
          o_wvalid <= '1';
        else
          -- update interface
          o_wvalid <= '0';
        end if;
      end if;
    end if;
  end process;

end rtl;

