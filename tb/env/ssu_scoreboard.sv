class ssu_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(ssu_scoreboard)

    uvm_analysis_imp#(ssu_transaction, ssu_scoreboard) ap;

    // Reference model for SSU registers
    bit [7:0] ref_sscrh = 8'h08;  // SS Control Register H
    bit [7:0] ref_sscrl = 8'h00;  // SS Control Register L
    bit [7:0] ref_ssmr  = 8'h00;  // SS Mode Register
    bit [7:0] ref_sser  = 8'h00;  // SS Enable Register
    bit [7:0] ref_sssr  = 8'h0C;  // SS Status Register
    bit [7:0] ref_sscr2 = 8'h00;  // SS Control Register 2
    bit [7:0] ref_sstdr[4] = '{0,0,0,0}; // Transmit Data Registers
    bit [7:0] ref_ssrdr[4] = '{0,0,0,0}; // Receive Data Registers

    // Expected serial data
    bit [31:0] expected_tx_data;
    bit [31:0] expected_rx_data;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    // Write function called by monitor
    function void write(ssu_transaction tr);
        case (tr.trans_type)
            ssu_transaction::READ: check_read(tr);
            ssu_transaction::WRITE: check_write(tr);
            ssu_transaction::SERIAL_TX: check_serial_tx(tr);
            ssu_transaction::SERIAL_RX: check_serial_rx(tr);
        endcase
    endfunction

    function void check_read(ssu_transaction tr);
        bit [7:0] expected_rdata;

        case (tr.addr)
            5'h00: expected_rdata = ref_sscrh;
            5'h01: expected_rdata = ref_sscrl;
            5'h02: expected_rdata = ref_ssmr;
            5'h03: expected_rdata = ref_sser;
            5'h04: expected_rdata = ref_sssr;
            5'h05: expected_rdata = ref_sscr2;
            5'h08: expected_rdata = ref_sstdr[0];
            5'h09: expected_rdata = ref_sstdr[1];
            5'h0A: expected_rdata = ref_sstdr[2];
            5'h0B: expected_rdata = ref_sstdr[3];
            5'h0C: expected_rdata = ref_ssrdr[0];
            5'h0D: expected_rdata = ref_ssrdr[1];
            5'h0E: expected_rdata = ref_ssrdr[2];
            5'h0F: expected_rdata = ref_ssrdr[3];
            default: expected_rdata = 8'h00;
        endcase

        if (tr.rdata !== expected_rdata) begin
            `uvm_error("SCOREBOARD", $sformatf("Read data mismatch! Addr: %h, Expected: %h, Actual: %h",
                      tr.addr, expected_rdata, tr.rdata))
        end else begin
            `uvm_info("SCOREBOARD", $sformatf("Read OK - Addr: %h, Data: %h", tr.addr, tr.rdata), UVM_MEDIUM)
        end

        // Clear status flags on read if applicable
        if (tr.addr == 5'h04) begin // SSSR read
            // Clear flags that are cleared on read
        end
    endfunction

    function void check_write(ssu_transaction tr);
        case (tr.addr)
            5'h00: begin // SSCRH
                ref_sscrh = tr.wdata;
                `uvm_info("SCOREBOARD", $sformatf("Write SSCRH: %h", tr.wdata), UVM_MEDIUM)
            end
            5'h01: begin // SSCRL
                ref_sscrl = tr.wdata;
                `uvm_info("SCOREBOARD", $sformatf("Write SSCRL: %h", tr.wdata), UVM_MEDIUM)
            end
            5'h02: begin // SSMR
                ref_ssmr = tr.wdata;
                `uvm_info("SCOREBOARD", $sformatf("Write SSMR: %h", tr.wdata), UVM_MEDIUM)
            end
            5'h03: begin // SSER
                ref_sser = tr.wdata;
                `uvm_info("SCOREBOARD", $sformatf("Write SSER: %h", tr.wdata), UVM_MEDIUM)
            end
            5'h04: begin // SSSR
                // Status register write - clear flags
                ref_sssr = ref_sssr & ~tr.wdata;
                `uvm_info("SCOREBOARD", $sformatf("Write SSSR: %h", tr.wdata), UVM_MEDIUM)
            end
            5'h05: begin // SSCR2
                ref_sscr2 = tr.wdata;
                `uvm_info("SCOREBOARD", $sformatf("Write SSCR2: %h", tr.wdata), UVM_MEDIUM)
            end
            5'h08, 5'h09, 5'h0A, 5'h0B: begin // SSTDR
                ref_sstdr[tr.addr - 5'h08] = tr.wdata;
                `uvm_info("SCOREBOARD", $sformatf("Write SSTDR%d: %h", tr.addr - 5'h08, tr.wdata), UVM_MEDIUM)
            end
        endcase
    endfunction

    function void check_serial_tx(ssu_transaction tr);
        // Check that transmission data matches what was loaded
        bit [31:0] loaded_data;

        case (tr.data_length)
            8: loaded_data = ref_sstdr[0];
            16: loaded_data = {ref_sstdr[1], ref_sstdr[0]};
            24: loaded_data = {ref_sstdr[2], ref_sstdr[1], ref_sstdr[0]};
            32: loaded_data = {ref_sstdr[3], ref_sstdr[2], ref_sstdr[1], ref_sstdr[0]};
        endcase

        if (tr.tx_data !== loaded_data) begin
            `uvm_error("SCOREBOARD", $sformatf("TX data mismatch! Loaded: %h, Transmitted: %h",
                      loaded_data, tr.tx_data))
        end else begin
            `uvm_info("SCOREBOARD", $sformatf("TX OK - Data: %h", tr.tx_data), UVM_MEDIUM)
        end
    endfunction

    function void check_serial_rx(ssu_transaction tr);
        // For reception, we mainly check that data was received
        // The actual data checking would depend on the serial protocol
        `uvm_info("SCOREBOARD", $sformatf("RX Data: %h", tr.rx_data), UVM_MEDIUM)

        // Update reference model with received data
        case (tr.data_length)
            8: ref_ssrdr[0] = tr.rx_data[7:0];
            16: {ref_ssrdr[1], ref_ssrdr[0]} = tr.rx_data[15:0];
            24: {ref_ssrdr[2], ref_ssrdr[1], ref_ssrdr[0]} = tr.rx_data[23:0];
            32: {ref_ssrdr[3], ref_ssrdr[2], ref_ssrdr[1], ref_ssrdr[0]} = tr.rx_data[31:0];
        endcase
    endfunction

endclass