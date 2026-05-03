// my_mem.sv

module my_mem(
  input  logic clk,
  mem_if.dut_mp port
);

  logic [8:0] mem_array [int];

  always @(posedge clk) begin
    if (port.write)
      mem_array[port.address] = {^port.data_in, port.data_in};
    else if (port.read)
      port.data_out = mem_array[port.address];
  end

endmodule : my_mem
