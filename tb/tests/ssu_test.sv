class ssu_test extends uvm_test;

    `uvm_component_utils(ssu_test)

    ssu_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = ssu_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        ssu_reset_seq reset_seq;
        ssu_seq seq;

        phase.raise_objection(this);
        `uvm_info("TEST", "Starting SSU test", UVM_LOW)

        // First run reset sequence
        reset_seq = ssu_reset_seq::type_id::create("reset_seq");
        reset_seq.start(env.agt.seqr);
        `uvm_info("TEST", "Reset sequence completed", UVM_MEDIUM)

        // Wait a bit after reset
        #100;
        `uvm_info("TEST", "Wait after reset completed", UVM_MEDIUM)

        // Then run main sequence
        seq = ssu_seq::type_id::create("seq");
        seq.start(env.agt.seqr);
        `uvm_info("TEST", "Main sequence completed", UVM_MEDIUM)

        // Wait a bit before ending
        #100;
        `uvm_info("TEST", "Test completed successfully", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass
