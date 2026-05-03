// mem_if.sv
interface mem_if (input logic clk);

  logic        write;
  logic        read;
  logic [7:0]  data_in;
  logic [15:0] address;
  logic [8:0]  data_out;

  modport dut_mp (
    input  write,
    input  read,
    input  data_in,
    input  address,
    output data_out
  );

  clocking cb @(posedge clk);
    default input #1step output #1;
    output write;
    output read;
    output data_in;
    output address;
    input  data_out;
  endclocking : cb

  property no_simultaneous_rw;
    @(posedge clk) not (read && write);
  endproperty

  assert property (no_simultaneous_rw)
    else $error("[%0t] CHECKER ERROR: read and write both asserted!", $time);

endinterface : mem_if
