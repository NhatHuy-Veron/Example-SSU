class ssu_driver extends uvm_driver#(ssu_transaction);

    `uvm_component_utils(ssu_driver)

    virtual ssu_if.drv_mp vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ssu_if.drv_mp)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "Virtual interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        // Wait for reset to be released
        @(posedge vif.rst_n);

        forever begin
            ssu_transaction tr;
            seq_item_port.get_next_item(tr);
            drive_transaction(tr);
            seq_item_port.item_done();
        end
    endtask

    task drive_transaction(ssu_transaction tr);
        case (tr.trans_type)
            ssu_transaction::READ: drive_read(tr);
            ssu_transaction::WRITE: drive_write(tr);
            ssu_transaction::SERIAL_TX: drive_serial_tx(tr);
            ssu_transaction::SERIAL_RX: drive_serial_rx(tr);
        endcase
    endtask

    task drive_read(ssu_transaction tr);
        `uvm_info("DRV", $sformatf("Starting read transaction for addr %h", tr.addr), UVM_MEDIUM)

        @(vif.drv_cb);
        vif.drv_cb.cs <= 1'b1;
        vif.drv_cb.we <= 1'b0;
        vif.drv_cb.addr <= tr.addr;
        vif.drv_cb.wdata <= 8'h00; // Not used for read

        `uvm_info("DRV", "Asserted CS and address, waiting for ready", UVM_HIGH)

        // Wait for ready signal or timeout
        fork
            begin
                @(vif.drv_cb);
                while (!vif.drv_cb.ready) begin
                    `uvm_info("DRV", "Waiting for ready signal", UVM_HIGH)
                    @(vif.drv_cb);
                end
                tr.rdata = vif.drv_cb.rdata;
                `uvm_info("DRV", $sformatf("Read completed, data = %h", tr.rdata), UVM_MEDIUM)
            end
            begin
                repeat(1000) @(vif.drv_cb); // Longer timeout
                `uvm_error("DRV", "Read timeout - DUT not responding")
            end
        join_any
        disable fork;

        // Deassert cs
        vif.drv_cb.cs <= 1'b0;
        `uvm_info("DRV", "Deasserted CS", UVM_HIGH)
    endtask

    task drive_write(ssu_transaction tr);
        `uvm_info("DRV", $sformatf("Starting write transaction for addr %h, data %h", tr.addr, tr.wdata), UVM_MEDIUM)

        @(vif.drv_cb);
        vif.drv_cb.cs <= 1'b1;
        vif.drv_cb.we <= 1'b1;
        vif.drv_cb.addr <= tr.addr;
        vif.drv_cb.wdata <= tr.wdata;

        `uvm_info("DRV", "Asserted CS, WE, address and data, waiting for ready", UVM_HIGH)

        // Wait for ready signal or timeout
        fork
            begin
                @(vif.drv_cb);
                while (!vif.drv_cb.ready) begin
                    `uvm_info("DRV", "Waiting for ready signal", UVM_HIGH)
                    @(vif.drv_cb);
                end
                `uvm_info("DRV", "Write completed", UVM_MEDIUM)
            end
            begin
                repeat(1000) @(vif.drv_cb); // Longer timeout
                `uvm_error("DRV", "Write timeout - DUT not responding")
            end
        join_any
        disable fork;

        // Deassert cs
        vif.drv_cb.cs <= 1'b0;
        `uvm_info("DRV", "Deasserted CS", UVM_HIGH)
    endtask
        @(vif.drv_cb);
    endtask

    task drive_serial_tx(ssu_transaction tr);
        // First, configure registers for transmission
        configure_for_tx(tr);

        // Load transmit data
        load_tx_data(tr);

        // Wait for transmission to complete
        wait_for_tx_complete();

        // Capture any interrupts
        capture_interrupts(tr);
    endtask

    task drive_serial_rx(ssu_transaction tr);
        // Configure registers for reception
        configure_for_rx(tr);

        // Drive serial inputs
        drive_serial_inputs(tr);

        // Wait for reception to complete
        wait_for_rx_complete();

        // Read received data
        read_rx_data(tr);

        // Capture interrupts
        capture_interrupts(tr);
    endtask

    task configure_for_tx(ssu_transaction tr);
        // Write to SSCRH for master/slave mode
        // Write to SSCRL for data length
        // Write to SSMR for clock and data format
        // Write to SSER to enable transmission
        // Implementation depends on specific configuration needed
    endtask

    task load_tx_data(ssu_transaction tr);
        // Write data to SSTDR registers based on data_length
        case (tr.data_length)
            8: begin
                // Write to SSTDR0
                write_register(5'h08, tr.tx_data[7:0]);
            end
            16: begin
                write_register(5'h08, tr.tx_data[7:0]);
                write_register(5'h09, tr.tx_data[15:8]);
            end
            24: begin
                write_register(5'h08, tr.tx_data[7:0]);
                write_register(5'h09, tr.tx_data[15:8]);
                write_register(5'h0A, tr.tx_data[23:16]);
            end
            32: begin
                write_register(5'h08, tr.tx_data[7:0]);
                write_register(5'h09, tr.tx_data[15:8]);
                write_register(5'h0A, tr.tx_data[23:16]);
                write_register(5'h0B, tr.tx_data[31:24]);
            end
        endcase
    endtask

    task wait_for_tx_complete();
        // Wait for TEND flag to be set
        bit [7:0] status;
        do begin
            read_register(5'h04, status);
            @(vif.drv_cb);
        end while (!(status[3])); // TEND bit
    endtask

    task configure_for_rx(ssu_transaction tr);
        // Similar to configure_for_tx but for reception
    endtask

    task drive_serial_inputs(ssu_transaction tr);
        // Drive ssck_in, ssi, scs_in based on transaction
        vif.drv_cb.ssck_in <= tr.ssck_in;
        vif.drv_cb.ssi <= tr.ssi;
        vif.drv_cb.scs_in <= tr.scs_in;
    endtask

    task wait_for_rx_complete();
        // Wait for RDRF flag
        bit [7:0] status;
        do begin
            read_register(5'h04, status);
            @(vif.drv_cb);
        end while (!(status[1])); // RDRF bit
    endtask

    task read_rx_data(ssu_transaction tr);
        // Read from SSRDR registers
        case (tr.data_length)
            8: begin
                read_register(5'h0C, tr.rx_data[7:0]);
            end
            16: begin
                read_register(5'h0C, tr.rx_data[7:0]);
                read_register(5'h0D, tr.rx_data[15:8]);
            end
            24: begin
                read_register(5'h0C, tr.rx_data[7:0]);
                read_register(5'h0D, tr.rx_data[15:8]);
                read_register(5'h0E, tr.rx_data[23:16]);
            end
            32: begin
                read_register(5'h0C, tr.rx_data[7:0]);
                read_register(5'h0D, tr.rx_data[15:8]);
                read_register(5'h0E, tr.rx_data[23:16]);
                read_register(5'h0F, tr.rx_data[31:24]);
            end
        endcase
    endtask

    task capture_interrupts(ssu_transaction tr);
        tr.txi_int = vif.drv_cb.txi_int;
        tr.rxi_int = vif.drv_cb.rxi_int;
        tr.tei_int = vif.drv_cb.tei_int;
        tr.oei_int = vif.drv_cb.oei_int;
        tr.cei_int = vif.drv_cb.cei_int;
    endtask

    task write_register(bit [4:0] addr, bit [7:0] data);
        @(vif.drv_cb);
        vif.drv_cb.cs <= 1'b1;
        vif.drv_cb.we <= 1'b1;
        vif.drv_cb.addr <= addr;
        vif.drv_cb.wdata <= data;
        @(vif.drv_cb);
        vif.drv_cb.cs <= 1'b0;
        @(vif.drv_cb);
    endtask

    task read_register(bit [4:0] addr, output bit [7:0] data);
        @(vif.drv_cb);
        vif.drv_cb.cs <= 1'b1;
        vif.drv_cb.we <= 1'b0;
        vif.drv_cb.addr <= addr;
        vif.drv_cb.wdata <= 8'h00;
        @(vif.drv_cb);
        data = vif.drv_cb.rdata;
        vif.drv_cb.cs <= 1'b0;
        @(vif.drv_cb);
    endtask

endclass
