class test_class;

static function void print_hello();
    $display("Hello, world!\n");
endfunction

static function void uvm_log();
    `uvm_info("hello type", $sformatf("Hello on %0d", 5), UVM_NONE);
endfunction

endclass