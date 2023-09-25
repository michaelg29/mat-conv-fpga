
library ieee;
use ieee.std_logic_1164.all;

-- Register definitions
package mat_mult_reg_pkg is

  ----------------------------------
  ------- register definitions -----
  ----------------------------------

  -- Input dimension register
  --   Dimensions of input image and matrix
  type dimensions_t is record
    -- length of the image minus 1
    img_len  : std_logic_vector(10 downto 0);
    -- width of the image minus 1
    img_wid  : std_logic_vector(10 downto 0); 
    -- size of the transformation matrix minus 1
    mat_size : std_logic_vector(9 downto 0);
  end record;
  
  -- Offset Register
  --   Offset into input image
  type offset_t is record
    -- Starting pixel from left side of image in multiples of 8 pixels
    left_start : std_logic_vector(7 downto 0);
    -- Starting pixel from top of image in multiples of 8 pixels
    top_start  : std_logic_vector(7 downto 0);
  end record;
  
  -- repetition control
  type repetition_ctl_t is record
    -- Whether to enable repetition
    en : std_logic;
  end record;
  
  -- status register
  type status_reg_t is record
    -- Whether the module is currently computing a result
    multiplying : std_logic;
  end record;
  
  ----------------------------------
  ------- register collections -----
  ----------------------------------

  -- all HW-accessible registers
  type regs_sw2hw_t is record
    dimensions     : dimensions_t;
    offset         : offset_t;
    repetition_ctl : repetition_ctl_t;
    status_reg     : status_reg_t;
  end record;
  
  -- all HW-writeable registers
  type regs_hw2sw_t is record
    status_reg : status_reg_t;
  end record;
  
  -- reset value of regs_sw2hw_t
  constant r_regs_sw2hw : regs_sw2hw_t := (
    -- default dimensions: (1919, 1079, 1023)
    ("11101111111", "10000110111", "1111111111"),
    ("00111000", "00000100"),
    ('0'),
    ('0')
  );
  
  -- reset value of regs_hw2sw_t
  constant r_regs_hw2sw : regs_hw2sw_t := (
    ('0')
  );
  
  -----------------------------
  ------- register events -----
  -----------------------------
  
  -- SW-RW event pulses
  type rw_reg_evnt_t is record
    w_pls : std_logic;
    r_pls : std_logic;
  end record;
  
  -- SW-WO event pulses
  type wo_reg_evnt_t is record
    w_pls : std_logic;
  end record;
  
  -- SW-RO event pulses
  type ro_reg_evnt_t is record
    r_pls : std_logic;
  end record;
  
  -- SW-accessible registers
  type regs_evnt_t is record
    dimensions     : rw_reg_evnt_t;
    offset         : rw_reg_evnt_t;
    repetition_ctl : rw_reg_evnt_t;
    status_reg     : ro_reg_evnt_t;
  end record;
  
  -- HW-writeable event pulses
  type reg_resp_t is record
    ack_pls : std_logic;
    err_pls : std_logic;
  end record;
  
  -- SW-writeable registers
  type regs_resp_t is record
    dimensions     : reg_resp_t;
    offset         : reg_resp_t;
    repetition_ctl : reg_resp_t;
  end record;
    
end package mat_mult_reg_pkg;
