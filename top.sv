// top.sv


module top;

  // Clock generation — 10MHz = 100ns period
  logic clk;

  initial clk = 0;
  always #50 clk = ~clk;

  // Waveform dumping for Verdi
  initial begin
    $fsdbDumpfile("waves.fsdb");      // output file name
    $fsdbDumpvars(0, top);            // dump ALL signals under top, recursively
    $fsdbDumpSVA;                     // also capture assertion results
  end

  // Interface
  mem_if dut_if (.clk(clk));

  // DUT
  my_mem dut (
    .clk  (clk),
    .port (dut_if)
  );

  // Program
  test tb (.dut_if(dut_if));

endmodule : top
