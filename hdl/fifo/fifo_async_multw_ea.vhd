
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity fifo_async_multw is
  generic (
    -- address width in terms of input elements
    ADDR_WIDTH : integer := 5;
    -- bit width of the elements to be read
    W_EL       : integer := 8;
    -- number of elements that can be written at once
    N_IN_EL    : integer := 8;
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
    i_wdata  : in  std_logic_vector(W_EL*N_IN_EL-1 downto 0);
    i_wen    : in  std_logic;
    o_full   : out std_logic;
    o_wvalid : out std_logic;
    o_werr   : out std_logic
  );
end fifo_async_multw;

architecture rtl of fifo_async_multw is

  constant W_IN     : integer := W_EL * N_IN_EL;
  constant N_BITS   : integer := integer(ceil(log2(real(W_IN))));
  constant W_EL_U   : unsigned(N_BITS-1 downto 0) := to_unsigned(W_EL, N_BITS);
  
  -- zero counter
  constant ZRO_CNT  : unsigned(N_BITS-1 downto 0) := to_unsigned(0, N_BITS);
  -- start index of penultimate element in rdata_int
  constant PEN_CNT  : unsigned(N_BITS-1 downto 0) := ZRO_CNT - W_EL_U - W_EL_U;
  
  -- current frame counters
  signal cnt        : unsigned(N_BITS-1 downto 0);
  signal max_idx    : unsigned(N_BITS-1 downto 0);
  
  -- signals to be propagated to/from internal FIFO
  signal ren_int    : std_logic; -- also indicates whether rdata_buf is valid or not
  signal empty_int  : std_logic;
  signal rdata_int  : std_logic_vector(W_IN-1 downto 0);
  signal rvalid_int : std_logic;
  
  signal rdata_rdy  : std_logic;
  -- data buffer from internal FIFO
  signal rdata_ibuf : std_logic_vector(W_IN-1 downto 0);
  -- data buffer for current word being read
  signal rdata_obuf : std_logic_vector(W_IN-1 downto 0);

begin

  -- counter process
  P_CNT : process(i_rst_n, i_rclk)
  begin
    if (i_rst_n = '0') then
      cnt        <= ZRO_CNT;
      max_idx    <= W_EL_U - 1;
      ren_int    <= '1';
      rdata_rdy  <= '0';
      rdata_ibuf <= (others => '0');
      rdata_obuf <= (others => '0');
      o_rvalid   <= '0';
      o_rerr     <= '0';
      o_rdata    <= (others => '0');
      o_empty    <= '1';
    elsif (i_rclk'event and i_rclk = '1') then
      -- increment counter
      if ((i_ren and (not(ren_int and empty_int))) = '1') then
        cnt      <= cnt + W_EL_U;
        max_idx  <= max_idx + W_EL_U;
        o_rvalid <= '1';
        o_rerr   <= '0';
      else
        cnt      <= cnt;
        max_idx  <= max_idx;
        o_rvalid <= '0';
        o_rerr   <= i_ren; -- error if trying to read
      end if;
    
      -- enable read from internal FIFO
      if (cnt = PEN_CNT) then
        ren_int <= '1';
      else
        ren_int <= ren_int and empty_int;
      end if;
      if (rvalid_int = '1') then
        rdata_rdy  <= '1';
        rdata_ibuf <= rdata_int;
      else
        -- clear rdata_rdy when reading last element in the previous buffer
        rdata_rdy  <= rdata_rdy and not(i_ren);
        rdata_ibuf <= rdata_ibuf;
      end if;
    
      -- buffer data from internal FIFO
      if ((rdata_rdy or rvalid_int) = '1' and i_ren = '1') then
        -- after reading last element in current buffer, swap frames
        rdata_obuf <= rdata_ibuf;
      else
        -- next rdata in same frame
        rdata_obuf <= rdata_obuf;
      end if;
      
      -- assign output data
      if ((rdata_rdy or rvalid_int) = '1' and cnt = ZRO_CNT) then
        -- fast track next data from internal FIFO
        o_rdata <= rdata_ibuf(to_integer(max_idx) downto to_integer(cnt));
      else
        -- next rdata in rdata_buf
        o_rdata <= rdata_obuf(to_integer(max_idx) downto to_integer(cnt));
      end if;
      
      -- update output flags
      o_empty <= ren_int and empty_int;
    end if;
  end process;
  
  -- internal FIFO
  FIFO : entity work.fifo_async
    generic map (
      ADDR_WIDTH => ADDR_WIDTH,
      W_EL       => W_IN,
      PRIORITY_W => PRIORITY_W
    ) port map (
      i_rst_n  => i_rst_n,
      
      i_rclk   => i_rclk,
      i_ren    => ren_int,
      o_rdata  => rdata_int,
      o_empty  => empty_int,
      o_rvalid => rvalid_int,
      o_rerr   => open,
      
      i_wclk   => i_wclk,
      i_wdata  => i_wdata,
      i_wen    => i_wen,
      o_full   => o_full,
      o_wvalid => o_wvalid,
      o_werr   => o_werr
    );

end rtl;

