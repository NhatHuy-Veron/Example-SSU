`ifndef SSU_PKG_SV
`define SSU_PKG_SV

package ssu_pkg;

    // Import UVM package
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Include transaction first (base class)
    `include "ssu_transaction.sv"

    // Include agent components (depend on transaction)
    `include "agents/ssu_driver.sv"
    `include "agents/ssu_monitor.sv"
    `include "agents/ssu_sequencer.sv"
    `include "env/ssu_scoreboard.sv"

    // Include agent (depends on driver, monitor, sequencer)
    `include "agents/ssu_agent.sv"

    // Include environment (depends on agent and scoreboard)
    `include "env/ssu_env.sv"

    // Include sequences (depend on sequencer)
    `include "seq/ssu_reset_seq.sv"
    `include "seq/ssu_seq.sv"

    // Include test (depends on environment)
    `include "tests/ssu_test.sv"

endpackage : ssu_pkg

`endif // SSU_PKG_SV
