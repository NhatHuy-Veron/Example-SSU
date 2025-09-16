class ssu_monitor extends uvm_monitor;

    `uvm_component_utils(ssu_monitor)

    virtual ssu_if.mon_mp vif;
    uvm_analysis_port#(ssu_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ssu_if.mon_mp)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "Virtual interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        // Wait for reset to be released
        @(posedge vif.rst_n);

        forever begin
            monitor_transactions();
        end
    endtask

    task monitor_transactions();
        ssu_transaction tr;

        // Monitor register accesses
        if (vif.mon_cb.cs) begin
            tr = ssu_transaction::type_id::create("tr");
            tr.addr = vif.mon_cb.addr;
            tr.wdata = vif.mon_cb.wdata;
            tr.ready = vif.mon_cb.ready;

            if (vif.mon_cb.we) begin
                tr.trans_type = ssu_transaction::WRITE;
            end else begin
                tr.trans_type = ssu_transaction::READ;
                tr.rdata = vif.mon_cb.rdata;
            end

            ap.write(tr);
            @(vif.mon_cb);
        end

        // Monitor serial communication
        monitor_serial_activity();

        // Monitor interrupts
        monitor_interrupts();

        @(vif.mon_cb);
    endtask

    task monitor_serial_activity();
        ssu_transaction tr;

        // Detect start of transmission
        if (vif.mon_cb.sso_oe && !vif.mon_cb.module_stop) begin
            tr = ssu_transaction::type_id::create("tr");
            tr.trans_type = ssu_transaction::SERIAL_TX;

            // Sample serial signals
            tr.ssck_out = vif.mon_cb.ssck_out;
            tr.ssck_oe = vif.mon_cb.ssck_oe;
            tr.sso = vif.mon_cb.sso;
            tr.sso_oe = vif.mon_cb.sso_oe;
            tr.scs_out = vif.mon_cb.scs_out;
            tr.scs_oe = vif.mon_cb.scs_oe;

            ap.write(tr);
        end

        // Detect start of reception
        if (vif.mon_cb.ssck_in && !vif.mon_cb.module_stop) begin
            tr = ssu_transaction::type_id::create("tr");
            tr.trans_type = ssu_transaction::SERIAL_RX;

            // Sample serial signals
            tr.ssck_in = vif.mon_cb.ssck_in;
            tr.ssi = vif.mon_cb.ssi;
            tr.scs_in = vif.mon_cb.scs_in;

            ap.write(tr);
        end
    endtask

    task monitor_interrupts();
        ssu_transaction tr;

        // Monitor each interrupt
        if (vif.mon_cb.txi_int || vif.mon_cb.rxi_int || vif.mon_cb.tei_int ||
            vif.mon_cb.oei_int || vif.mon_cb.cei_int) begin

            tr = ssu_transaction::type_id::create("tr");
            tr.trans_type = ssu_transaction::READ; // Interrupt status read
            tr.txi_int = vif.mon_cb.txi_int;
            tr.rxi_int = vif.mon_cb.rxi_int;
            tr.tei_int = vif.mon_cb.tei_int;
            tr.oei_int = vif.mon_cb.oei_int;
            tr.cei_int = vif.mon_cb.cei_int;

            ap.write(tr);
        end
    endtask

endclass
