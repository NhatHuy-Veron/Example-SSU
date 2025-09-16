class ssu_transaction extends uvm_sequence_item;

    `uvm_object_utils(ssu_transaction)

    // Transaction types
    typedef enum {READ, WRITE, SERIAL_TX, SERIAL_RX} trans_type_e;

    // Fields
    rand trans_type_e trans_type;

    // CPU Interface fields
    rand bit [4:0]  addr;
    rand bit [7:0]  wdata;
    bit [7:0]       rdata;
    bit             ready;

    // Serial Interface fields
    rand bit        ssck_in;
    bit             ssck_out;
    bit             ssck_oe;

    rand bit        ssi;
    bit             sso;
    bit             sso_oe;

    rand bit        scs_in;
    bit             scs_out;
    bit             scs_oe;

    // Interrupt fields
    bit             txi_int;
    bit             rxi_int;
    bit             tei_int;
    bit             oei_int;
    bit             cei_int;

    // Module stop
    rand bit        module_stop;

    // Data for serial transactions
    rand bit [31:0] tx_data;
    bit [31:0]      rx_data;
    rand bit [7:0]  data_length; // 8, 16, 24, 32

    // Register access constraints
    constraint addr_valid {
        addr inside {[0:15]};
    }

    constraint data_length_valid {
        data_length inside {8, 16, 24, 32};
    }

    function new(string name = "ssu_transaction");
        super.new(name);
    endfunction

    // Copy function
    function void do_copy(uvm_object rhs);
        ssu_transaction rhs_;
        if (!$cast(rhs_, rhs)) begin
            `uvm_error("do_copy", "Cast failed")
            return;
        end
        super.do_copy(rhs);
        this.trans_type = rhs_.trans_type;
        this.addr = rhs_.addr;
        this.wdata = rhs_.wdata;
        this.rdata = rhs_.rdata;
        this.ready = rhs_.ready;
        this.ssck_in = rhs_.ssck_in;
        this.ssck_out = rhs_.ssck_out;
        this.ssck_oe = rhs_.ssck_oe;
        this.ssi = rhs_.ssi;
        this.sso = rhs_.sso;
        this.sso_oe = rhs_.sso_oe;
        this.scs_in = rhs_.scs_in;
        this.scs_out = rhs_.scs_out;
        this.scs_oe = rhs_.scs_oe;
        this.txi_int = rhs_.txi_int;
        this.rxi_int = rhs_.rxi_int;
        this.tei_int = rhs_.tei_int;
        this.oei_int = rhs_.oei_int;
        this.cei_int = rhs_.cei_int;
        this.module_stop = rhs_.module_stop;
        this.tx_data = rhs_.tx_data;
        this.rx_data = rhs_.rx_data;
        this.data_length = rhs_.data_length;
    endfunction

    // Compare function
    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        ssu_transaction rhs_;
        if (!$cast(rhs_, rhs)) begin
            `uvm_error("do_compare", "Cast failed")
            return 0;
        end
        return super.do_compare(rhs, comparer) &&
               (this.trans_type === rhs_.trans_type) &&
               (this.addr === rhs_.addr) &&
               (this.wdata === rhs_.wdata) &&
               (this.rdata === rhs_.rdata) &&
               (this.ready === rhs_.ready) &&
               (this.ssck_in === rhs_.ssck_in) &&
               (this.ssck_out === rhs_.ssck_out) &&
               (this.ssck_oe === rhs_.ssck_oe) &&
               (this.ssi === rhs_.ssi) &&
               (this.sso === rhs_.sso) &&
               (this.sso_oe === rhs_.sso_oe) &&
               (this.scs_in === rhs_.scs_in) &&
               (this.scs_out === rhs_.scs_out) &&
               (this.scs_oe === rhs_.scs_oe) &&
               (this.txi_int === rhs_.txi_int) &&
               (this.rxi_int === rhs_.rxi_int) &&
               (this.tei_int === rhs_.tei_int) &&
               (this.oei_int === rhs_.oei_int) &&
               (this.cei_int === rhs_.cei_int) &&
               (this.module_stop === rhs_.module_stop) &&
               (this.tx_data === rhs_.tx_data) &&
               (this.rx_data === rhs_.rx_data) &&
               (this.data_length === rhs_.data_length);
    endfunction

    // Print function
    function void do_print(uvm_printer printer);
        super.do_print(printer);
        printer.print_string("trans_type", trans_type.name());
        printer.print_field("addr", addr, 5);
        printer.print_field("wdata", wdata, 8);
        printer.print_field("rdata", rdata, 8);
        printer.print_field("ready", ready, 1);
        printer.print_field("ssck_in", ssck_in, 1);
        printer.print_field("ssck_out", ssck_out, 1);
        printer.print_field("ssck_oe", ssck_oe, 1);
        printer.print_field("ssi", ssi, 1);
        printer.print_field("sso", sso, 1);
        printer.print_field("sso_oe", sso_oe, 1);
        printer.print_field("scs_in", scs_in, 1);
        printer.print_field("scs_out", scs_out, 1);
        printer.print_field("scs_oe", scs_oe, 1);
        printer.print_field("txi_int", txi_int, 1);
        printer.print_field("rxi_int", rxi_int, 1);
        printer.print_field("tei_int", tei_int, 1);
        printer.print_field("oei_int", oei_int, 1);
        printer.print_field("cei_int", cei_int, 1);
        printer.print_field("module_stop", module_stop, 1);
        printer.print_field("tx_data", tx_data, 32);
        printer.print_field("rx_data", rx_data, 32);
        printer.print_field("data_length", data_length, 8);
    endfunction

endclass
    endfunction

    // Print function
    function string convert2string();
        string s;
        s = super.convert2string();
        $sformat(s, "%s\n clk_in: %b\n data_in: %h\n data_out: %h\n clk_out: %b\n sync_ok: %b",
                 s, clk_in, data_in, data_out, clk_out, sync_ok);
        return s;
    endfunction

endclass
