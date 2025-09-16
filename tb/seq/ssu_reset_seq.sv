class ssu_reset_seq extends uvm_sequence#(ssu_transaction);

    `uvm_object_utils(ssu_reset_seq)

    function new(string name = "ssu_reset_seq");
        super.new(name);
    endfunction

    task body();
        ssu_transaction tr;

        `uvm_info("RESET_SEQ", "Testing reset functionality", UVM_MEDIUM)

        // Test 1: Software reset via SSCRL
        tr = ssu_transaction::type_id::create("tr");
        start_item(tr);
        tr.trans_type = ssu_transaction::WRITE;
        tr.addr = 5'h01; // SSCRL
        tr.wdata = 8'h20; // SRES = 1 (software reset)
        finish_item(tr);

        // Read status register to verify reset
        tr = ssu_transaction::type_id::create("tr");
        start_item(tr);
        tr.trans_type = ssu_transaction::READ;
        tr.addr = 5'h04; // SSSR
        finish_item(tr);

        // Test 2: Configure registers after reset
        tr = ssu_transaction::type_id::create("tr");
        start_item(tr);
        tr.trans_type = ssu_transaction::WRITE;
        tr.addr = 5'h00; // SSCRH
        tr.wdata = 8'h08; // Default value
        finish_item(tr);

        // Test 3: Load data and check if it's cleared on reset
        tr = ssu_transaction::type_id::create("tr");
        start_item(tr);
        tr.trans_type = ssu_transaction::WRITE;
        tr.addr = 5'h08; // SSTDR0
        tr.wdata = 8'hFF;
        finish_item(tr);

        // Software reset again
        tr = ssu_transaction::type_id::create("tr");
        start_item(tr);
        tr.trans_type = ssu_transaction::WRITE;
        tr.addr = 5'h01; // SSCRL
        tr.wdata = 8'h20; // SRES = 1
        finish_item(tr);

        // Verify data register is cleared
        tr = ssu_transaction::type_id::create("tr");
        start_item(tr);
        tr.trans_type = ssu_transaction::READ;
        tr.addr = 5'h08; // SSTDR0
        finish_item(tr);
    endtask

endclass