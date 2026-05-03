program automatic test (mem_if dut_if);
  // Takes full interface — accesses clocking block as dut_if.cb internally

  import mem_pkg::*;

  Transaction gen_q[$];   // generator → driver
  Transaction chk_q[$];   // driver → checker

  // ----------------------------------------------------------
  // MAIN
  // ----------------------------------------------------------
  initial begin
    // Safe init — drive all outputs to 0 before clock starts
    dut_if.cb.write   <= 0;
    dut_if.cb.read    <= 0;
    dut_if.cb.data_in <= 0;
    dut_if.cb.address <= 0;

    // Let clock stabilize for 2 cycles before driving anything
    repeat(2) @(dut_if.cb);

    fork
      generate_transactions(20);
      drive_transactions();
      check_and_collect();      // merged — avoids race on chk_q
    join_none

    // Wait for all 20 transactions to complete
    // Each = write(2 clocks) + read(2 clocks) = 4 clocks
    // 20 x 4 = 80 clocks + 20 gen clocks + 10 margin = 110 clocks
    repeat(120) @(dut_if.cb);

    Transaction::print_error();
    $display("[%0t] Simulation complete.", $time);
    $finish;
  end

  // ----------------------------------------------------------
  // TASK 1: generate_transactions
  // Creates random Transaction objects and pushes to gen_q
  // ----------------------------------------------------------
  task generate_transactions(int count);
    Transaction t;
    repeat (count) begin
      t = new();                          // randomizes address & data_in
      gen_q.push_back(t);
      $display("[%0t] GEN: addr=%0h data_in=%0h", $time, t.address, t.data_in);
      @(dut_if.cb);                       // one clock between each generation
    end
  endtask

  // ----------------------------------------------------------
  // TASK 2: drive_transactions
  // Pops from gen_q, drives WRITE then READ, pushes to chk_q
  // Uses while+@cb instead of wait() to avoid zero-time loops
  // ----------------------------------------------------------
  task drive_transactions();
    Transaction t, t_copy;
    forever begin

      // Wait for an item — clock-based polling avoids zero-time hang
      while (gen_q.size() == 0) @(dut_if.cb);
      t = gen_q.pop_front();

      // ---- WRITE ----
      dut_if.cb.write   <= 1;
      dut_if.cb.read    <= 0;
      dut_if.cb.address <= t.address;
      dut_if.cb.data_in <= t.data_in;
      @(dut_if.cb);                       // DUT latches write on this posedge

      dut_if.cb.write   <= 0;
      dut_if.cb.read    <= 0;
      @(dut_if.cb);                       // idle cycle

      // Compute expected: DUT stores {^data_in, data_in}
      t.expected_data = {^t.data_in, t.data_in};

      // ---- READ ----
      dut_if.cb.read    <= 1;
      dut_if.cb.write   <= 0;
      dut_if.cb.address <= t.address;
      @(dut_if.cb);                       // DUT drives data_out on this posedge

      dut_if.cb.read    <= 0;
      @(dut_if.cb);                       // output settle cycle

      $display("[%0t] DRV: addr=%0h data_in=%0h | expected=%0b",
               $time, t.address, t.data_in, t.expected_data);

      // Deep copy into checker queue
      t_copy = t.deep_copy();
      chk_q.push_back(t_copy);

    end
  endtask

  // ----------------------------------------------------------
  // TASK 3: check_and_collect  (merged collect + check)
  // Pops from chk_q, samples data_out, then immediately checks
  // Merging avoids the race condition of two tasks on same queue
  // ----------------------------------------------------------
  task check_and_collect();
    Transaction t;
    forever begin

      // Clock-based polling — no zero-time loops
      while (chk_q.size() == 0) @(dut_if.cb);
      t = chk_q.pop_front();

      // Sample data_out through clocking block (#1step skew built in)
      t.data_out = dut_if.cb.data_out;
      t.print_data_out();

      // Compare expected vs actual
      t.check();

      @(dut_if.cb);                       // advance time before next check
    end
  endtask

endprogram : test
