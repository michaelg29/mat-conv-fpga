
 
library ieee;
use ieee.std_logic_1164.all;

--library rtg4;
--use rtg4.all;
--library COREFIFO_LIB;
--use COREFIFO_LIB.all;

library fifo_library;
use fifo_library.all;

entity fifo_64x512 is
    generic (
      AEVAL        : integer range 3 to 510 := 4;
      AFVAL        : integer range 3 to 510 := 500
    );
    port(
        -- Inputs
        CLK        : in  std_logic;
        DATA       : in  std_logic_vector(63 downto 0);
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
        Q          : out std_logic_vector(63 downto 0);
        RDCNT      : out std_logic_vector(9 downto 0);
        SB_CORRECT : out std_logic;
        UNDERFLOW  : out std_logic
        );
end fifo_64x512;
----------------------------------------------------------------------
-- fifo_64x512 architecture body
----------------------------------------------------------------------
architecture RTL of fifo_64x512 is
----------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------
-- fifo_64x512_fifo_64x512_0_COREFIFO   -   Actel:DirectCore:COREFIFO:3.0.101
component fifo_64x512_fifo_64x512_0_COREFIFO
    generic( 
        AE_STATIC_EN : integer := 1 ;
        AEVAL        : integer := 4 ;
        AF_STATIC_EN : integer := 1 ;
        AFVAL        : integer := 500 ;
        CTRL_TYPE    : integer := 2 ;
        DIE_SIZE     : integer := 28 ;
        ECC          : integer := 2 ;
        ESTOP        : integer := 1 ;
        FAMILY       : integer := 25 ;
        FSTOP        : integer := 1 ;
        FWFT         : integer := 1 ;
        NUM_STAGES   : integer := 2 ;
        OVERFLOW_EN  : integer := 1 ;
        PIPE         : integer := 1 ;
        PREFETCH     : integer := 0 ;
        RAM_OPT      : integer := 0 ;
        RDCNT_EN     : integer := 1 ;
        RDEPTH       : integer := 512 ;
        RE_POLARITY  : integer := 0 ;
        READ_DVALID  : integer := 0 ;
        RWIDTH       : integer := 64 ;
        SYNC         : integer := 1 ;
        SYNC_RESET   : integer := 1 ;
        UNDERFLOW_EN : integer := 1 ;
        WDEPTH       : integer := 512 ;
        WE_POLARITY  : integer := 0 ;
        WRCNT_EN     : integer := 0 ;
        WRITE_ACK    : integer := 0 ;
        WWIDTH       : integer := 64 
        );
    -- Port list
    port(
        -- Inputs
        CLK        : in  std_logic;
        DATA       : in  std_logic_vector(63 downto 0);
        MEMRD      : in  std_logic_vector(63 downto 0);
        RCLOCK     : in  std_logic;
        RE         : in  std_logic;
        RESET_N    : in  std_logic;
        RRESET_N   : in  std_logic;
        WCLOCK     : in  std_logic;
        WE         : in  std_logic;
        WRESET_N   : in  std_logic;
        -- Outputs
        AEMPTY     : out std_logic;
        AFULL      : out std_logic;
        DB_DETECT  : out std_logic;
        DVLD       : out std_logic;
        EMPTY      : out std_logic;
        FULL       : out std_logic;
        MEMRADDR   : out std_logic_vector(8 downto 0);
        MEMRE      : out std_logic;
        MEMWADDR   : out std_logic_vector(8 downto 0);
        MEMWD      : out std_logic_vector(63 downto 0);
        MEMWE      : out std_logic;
        OVERFLOW   : out std_logic;
        Q          : out std_logic_vector(63 downto 0);
        RDCNT      : out std_logic_vector(9 downto 0);
        SB_CORRECT : out std_logic;
        UNDERFLOW  : out std_logic;
        WACK       : out std_logic;
        WRCNT      : out std_logic_vector(9 downto 0)
        );
end component;
----------------------------------------------------------------------
-- Signal declarations
----------------------------------------------------------------------
signal AEMPTY_net_0     : std_logic;
signal AFULL_net_0      : std_logic;
signal DB_DETECT_net_0  : std_logic;
signal EMPTY_net_0      : std_logic;
signal FULL_net_0       : std_logic;
signal OVERFLOW_net_0   : std_logic;
signal Q_net_0          : std_logic_vector(63 downto 0);
signal RDCNT_net_0      : std_logic_vector(9 downto 0);
signal SB_CORRECT_net_0 : std_logic;
signal UNDERFLOW_net_0  : std_logic;
signal FULL_net_1       : std_logic;
signal EMPTY_net_1      : std_logic;
signal AFULL_net_1      : std_logic;
signal AEMPTY_net_1     : std_logic;
signal OVERFLOW_net_1   : std_logic;
signal UNDERFLOW_net_1  : std_logic;
signal SB_CORRECT_net_1 : std_logic;
signal DB_DETECT_net_1  : std_logic;
signal Q_net_1          : std_logic_vector(63 downto 0);
signal RDCNT_net_1      : std_logic_vector(9 downto 0);
----------------------------------------------------------------------
-- TiedOff Signals
----------------------------------------------------------------------
signal GND_net          : std_logic;
signal MEMRD_const_net_0: std_logic_vector(63 downto 0);

begin
----------------------------------------------------------------------
-- Constant assignments
----------------------------------------------------------------------
 GND_net           <= '0';
 MEMRD_const_net_0 <= B"0000000000000000000000000000000000000000000000000000000000000000";
----------------------------------------------------------------------
-- Top level output port assignments
----------------------------------------------------------------------
 FULL_net_1        <= FULL_net_0;
 FULL              <= FULL_net_1;
 EMPTY_net_1       <= EMPTY_net_0;
 EMPTY             <= EMPTY_net_1;
 AFULL_net_1       <= AFULL_net_0;
 AFULL             <= AFULL_net_1;
 AEMPTY_net_1      <= AEMPTY_net_0;
 AEMPTY            <= AEMPTY_net_1;
 OVERFLOW_net_1    <= OVERFLOW_net_0;
 OVERFLOW          <= OVERFLOW_net_1;
 UNDERFLOW_net_1   <= UNDERFLOW_net_0;
 UNDERFLOW         <= UNDERFLOW_net_1;
 SB_CORRECT_net_1  <= SB_CORRECT_net_0;
 SB_CORRECT        <= SB_CORRECT_net_1;
 DB_DETECT_net_1   <= DB_DETECT_net_0;
 DB_DETECT         <= DB_DETECT_net_1;
 Q_net_1           <= Q_net_0;
 Q(63 downto 0)    <= Q_net_1;
 RDCNT_net_1       <= RDCNT_net_0;
 RDCNT(9 downto 0) <= RDCNT_net_1;
----------------------------------------------------------------------
-- Component instances
----------------------------------------------------------------------
-- fifo_64x512_0   -   Actel:DirectCore:COREFIFO:3.0.101
fifo_64x512_0 : fifo_64x512_fifo_64x512_0_COREFIFO
    generic map( 
        AE_STATIC_EN => ( 1 ),
        AEVAL        => AEVAL,
        AF_STATIC_EN => ( 1 ),
        AFVAL        => AFVAL,
        CTRL_TYPE    => ( 2 ),
        DIE_SIZE     => ( 28 ),
        ECC          => ( 2 ),
        ESTOP        => ( 1 ),
        FAMILY       => ( 25 ),
        FSTOP        => ( 1 ),
        FWFT         => ( 1 ),
        NUM_STAGES   => ( 2 ),
        OVERFLOW_EN  => ( 1 ),
        PIPE         => ( 1 ),
        PREFETCH     => ( 0 ),
        RAM_OPT      => ( 0 ),
        RDCNT_EN     => ( 1 ),
        RDEPTH       => ( 512 ),
        RE_POLARITY  => ( 0 ),
        READ_DVALID  => ( 0 ),
        RWIDTH       => ( 64 ),
        SYNC         => ( 1 ),
        SYNC_RESET   => ( 1 ),
        UNDERFLOW_EN => ( 1 ),
        WDEPTH       => ( 512 ),
        WE_POLARITY  => ( 0 ),
        WRCNT_EN     => ( 0 ),
        WRITE_ACK    => ( 0 ),
        WWIDTH       => ( 64 )
        )
    port map( 
        -- Inputs
        CLK        => CLK,
        WCLOCK     => GND_net, -- tied to '0' from definition
        RCLOCK     => GND_net, -- tied to '0' from definition
        RESET_N    => RESET_N,
        WRESET_N   => GND_net, -- tied to '0' from definition
        RRESET_N   => GND_net, -- tied to '0' from definition
        WE         => WE,
        RE         => RE,
        DATA       => DATA,
        MEMRD      => MEMRD_const_net_0, -- tied to X"0" from definition
        -- Outputs
        FULL       => FULL_net_0,
        EMPTY      => EMPTY_net_0,
        AFULL      => AFULL_net_0,
        AEMPTY     => AEMPTY_net_0,
        OVERFLOW   => OVERFLOW_net_0,
        UNDERFLOW  => UNDERFLOW_net_0,
        WACK       => OPEN,
        DVLD       => OPEN,
        MEMWE      => OPEN,
        MEMRE      => OPEN,
        SB_CORRECT => SB_CORRECT_net_0,
        DB_DETECT  => DB_DETECT_net_0,
        Q          => Q_net_0,
        WRCNT      => OPEN,
        RDCNT      => RDCNT_net_0,
        MEMWADDR   => OPEN,
        MEMRADDR   => OPEN,
        MEMWD      => OPEN 
        );

end RTL;
