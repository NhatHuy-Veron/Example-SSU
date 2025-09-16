package ssu_pkg;

    import uvm_pkg::*;

    `include "uvm_macros.svh"

    // Include transaction
    `include "ssu_transaction.sv"

    // Include all UVM components
    `include "ssu_agent.sv"
    `include "ssu_driver.sv"
    `include "ssu_monitor.sv"
    `include "ssu_sequencer.sv"
    `include "ssu_env.sv"
    `include "ssu_scoreboard.sv"
    `include "ssu_reset_seq.sv"
    `include "ssu_seq.sv"
    `include "ssu_test.sv"

endpackage
