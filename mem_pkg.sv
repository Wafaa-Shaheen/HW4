// mem_pkg.sv
package mem_pkg;

  class Transaction;

    rand logic [15:0] address;
    rand logic [7:0]  data_in;
    logic      [8:0]  data_out;
    logic      [8:0]  expected_data;

    static int error = 0;

    function new();
      address = $urandom;
      data_in = $urandom;
    endfunction

    function void print_data_out();
      $display("[%0t] data_out = %0b (hex: %0h)",
               $time, data_out, data_out);
    endfunction

    static function void print_error();
      $display("[%0t] Total errors = %0d", $time, error);
    endfunction

    function void check();
      if (data_out !== expected_data) begin
        $display("[%0t] ERROR: addr=%0h | expected=%0b | got=%0b",
                  $time, address, expected_data, data_out);
        error++;
      end else begin
        $display("[%0t] PASS:  addr=%0h | data=%0b",
                  $time, address, data_out);
      end
    endfunction

    function Transaction deep_copy();
      Transaction copy = new();
      copy.address       = this.address;
      copy.data_in       = this.data_in;
      copy.data_out      = this.data_out;
      copy.expected_data = this.expected_data;
      return copy;
    endfunction

  endclass : Transaction

endpackage : mem_pkg
