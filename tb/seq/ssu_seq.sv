class ssu_seq extends uvm_sequence#(ssu_transaction);

    `uvm_object_utils(ssu_seq)

    function new(string name = "ssu_seq");
        super.new(name);
    endfunction

    task body();
        // Test register access
        test_register_access();

        // Test serial transmission
        test_serial_transmission();

        // Test serial reception
        test_serial_reception();

        // Test interrupts
        test_interrupts();
    endtask

    task test_register_access();
        ssu_transaction tr;

        `uvm_info("SEQ", "Testing register access", UVM_MEDIUM)

        // Write to control registers
        tr = ssu_transaction::type_id::create("tr");
        start_item(tr);
        tr.trans_type = ssu_transaction::WRITE;
        tr.addr = 5'h00; // SSCRH
        tr.wdata = 8'h80; // Master mode
        finish_item(tr);

        // Write to mode register
        tr = ssu_transaction::type_id::create("tr");
        start_item(tr);
        tr.trans_type = ssu_transaction::WRITE;
        tr.addr = 5'h02; // SSMR
        tr.wdata = 8'h00; // Default mode
        finish_item(tr);

        // Read back registers
        tr = ssu_transaction::type_id::create("tr");
        start_item(tr);
        tr.trans_type = ssu_transaction::READ;
        tr.addr = 5'h00; // SSCRH
        finish_item(tr);

        tr = ssu_transaction::type_id::create("tr");
        start_item(tr);
        tr.trans_type = ssu_transaction::READ;
        tr.addr = 5'h02; // SSMR
        finish_item(tr);
    endtask

    task test_serial_transmission();
        ssu_transaction tr;

        `uvm_info("SEQ", "Testing serial transmission", UVM_MEDIUM)

        // Configure for transmission (8-bit)
        tr = ssu_transaction::type_id::create("tr");
        start_item(tr);
        tr.trans_type = ssu_transaction::WRITE;
        tr.addr = 5'h01; // SSCRL
        tr.wdata = 8'h00; // 8-bit data
        finish_item(tr);

        // Enable transmission
        tr = ssu_transaction::type_id::create("tr");
        start_item(tr);
        tr.trans_type = ssu_transaction::WRITE;
        tr.addr = 5'h03; // SSER
        tr.wdata = 8'h80; // TE = 1
        finish_item(tr);

        // Load transmit data
        tr = ssu_transaction::type_id::create("tr");
        start_item(tr);
        tr.trans_type = ssu_transaction::WRITE;
        tr.addr = 5'h08; // SSTDR0
        tr.wdata = 8'hAA;
        finish_item(tr);

        // Start transmission
        tr = ssu_transaction::type_id::create("tr");
        start_item(tr);
        tr.trans_type = ssu_transaction::SERIAL_TX;
        tr.tx_data = 32'h000000AA;
        tr.data_length = 8;
        finish_item(tr);
    endtask

    task test_serial_reception();
        ssu_transaction tr;

        `uvm_info("SEQ", "Testing serial reception", UVM_MEDIUM)

        // Configure for reception
        tr = ssu_transaction::type_id::create("tr");
        start_item(tr);
        tr.trans_type = ssu_transaction::WRITE;
        tr.addr = 5'h03; // SSER
        tr.wdata = 8'h40; // RE = 1
        finish_item(tr);

        // Start reception
        tr = ssu_transaction::type_id::create("tr");
        start_item(tr);
        tr.trans_type = ssu_transaction::SERIAL_RX;
        tr.data_length = 8;
        tr.ssck_in = 1'b1;
        tr.ssi = 1'b1;
        tr.scs_in = 1'b0;
        finish_item(tr);
    endtask

    task test_interrupts();
        ssu_transaction tr;

        `uvm_info("SEQ", "Testing interrupts", UVM_MEDIUM)

        // Read status register to check interrupts
        tr = ssu_transaction::type_id::create("tr");
        start_item(tr);
        tr.trans_type = ssu_transaction::READ;
        tr.addr = 5'h04; // SSSR
        finish_item(tr);
    endtask

endclass
