`timescale 1ns/1ps

module top_tb;

    import uvm_pkg::*;
    import ssu_pkg::*;

    bit clk;
    bit rst_n;

    // Generate main system clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz
    end

    // Generate reset
    initial begin
        rst_n = 0;
        #50 rst_n = 1;
    end

    // Interface
    ssu_if vif (clk, rst_n);

    // DUT instantiation
    ssu dut (
        .clk(vif.clk),
        .rst_n(vif.rst_n),
        .ssck_in(vif.ssck_in),
        .ssck_out(vif.ssck_out),
        .ssck_oe(vif.ssck_oe),
        .ssi(vif.ssi),
        .sso(vif.sso),
        .sso_oe(vif.sso_oe),
        .scs_in(vif.scs_in),
        .scs_out(vif.scs_out),
        .scs_oe(vif.scs_oe),
        .cs(vif.cs),
        .we(vif.we),
        .addr(vif.addr),
        .wdata(vif.wdata),
        .rdata(vif.rdata),
        .ready(vif.ready),
        .txi_int(vif.txi_int),
        .rxi_int(vif.rxi_int),
        .tei_int(vif.tei_int),
        .oei_int(vif.oei_int),
        .cei_int(vif.cei_int),
        .module_stop(vif.module_stop)
    );

    initial begin
        // Set virtual interfaces
        uvm_config_db#(virtual ssu_if.drv_mp)::set(null, "*", "vif", vif.drv_mp);
        uvm_config_db#(virtual ssu_if.mon_mp)::set(null, "*", "vif", vif.mon_mp);

        // Run test
        run_test("ssu_test");
    end

endmodule
