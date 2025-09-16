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

        // First run reset sequence
        reset_seq = ssu_reset_seq::type_id::create("reset_seq");
        reset_seq.start(env.agt.seqr);

        // Wait a bit after reset
        #100;

        // Then run main sequence
        seq = ssu_seq::type_id::create("seq");
        seq.start(env.agt.seqr);

        phase.drop_objection(this);
    endtask

endclass
