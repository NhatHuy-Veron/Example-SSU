interface ssu_if (
    input clk,
    input rst_n
);

    // External Serial Interface Pins
    logic        ssck_in;        // Serial clock input (slave mode)
    logic        ssck_out;       // Serial clock output (master mode)
    logic        ssck_oe;        // Clock output enable

    logic        ssi;            // Serial data input
    logic        sso;            // Serial data output
    logic        sso_oe;         // Data output enable

    logic        scs_in;         // Chip select input
    logic        scs_out;        // Chip select output
    logic        scs_oe;         // Chip select output enable

    // CPU Interface
    logic        cs;             // Chip select for register access
    logic        we;             // Write enable
    logic [4:0]  addr;           // Register address
    logic [7:0]  wdata;          // Write data
    logic [7:0]  rdata;          // Read data
    logic        ready;          // Transfer ready

    // Interrupt Outputs
    logic        txi_int;        // Transmit data register empty interrupt
    logic        rxi_int;        // Receive data register full interrupt
    logic        tei_int;        // Transmit end interrupt
    logic        oei_int;        // Overrun error interrupt
    logic        cei_int;        // Conflict error interrupt

    // Module Stop Control
    logic        module_stop;    // Module stop control

    // Clocking block for driver
    clocking drv_cb @(posedge clk);
        output ssck_in, ssi, scs_in;
        output cs, we, addr, wdata, module_stop;
        input ssck_out, ssck_oe, sso, sso_oe, scs_out, scs_oe;
        input rdata, ready;
        input txi_int, rxi_int, tei_int, oei_int, cei_int;
    endclocking

    // Clocking block for monitor
    clocking mon_cb @(posedge clk);
        input ssck_in, ssck_out, ssck_oe, ssi, sso, sso_oe, scs_in, scs_out, scs_oe;
        input cs, we, addr, wdata, rdata, ready;
        input txi_int, rxi_int, tei_int, oei_int, cei_int, module_stop;
    endclocking

    // Modport for driver
    modport drv_mp (clocking drv_cb, input rst_n);

    // Modport for monitor
    modport mon_mp (clocking mon_cb, input rst_n);

endinterface
