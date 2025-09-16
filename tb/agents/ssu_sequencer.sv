class ssu_sequencer extends uvm_sequencer#(ssu_transaction);

    `uvm_component_utils(ssu_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass
