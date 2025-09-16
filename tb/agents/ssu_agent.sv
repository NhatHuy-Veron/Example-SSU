class ssu_agent extends uvm_agent;

    `uvm_component_utils(ssu_agent)

    ssu_driver drv;
    ssu_monitor mon;
    ssu_sequencer seqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = ssu_driver::type_id::create("drv", this);
        mon = ssu_monitor::type_id::create("mon", this);
        seqr = ssu_sequencer::type_id::create("seqr", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
    endfunction

endclass
