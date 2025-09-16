// Synchronous Serial Communication Unit (SSU)
// Based on Renesas H8S/2426 SSU specification
// Author: SystemVerilog Implementation
// Date: 2025

`timescale 1ns/1ps

module ssu (
    // Clock and Reset
    input  logic        clk,            // System clock (φ)
    input  logic        rst_n,          // Active low reset
    
    // External Serial Interface Pins
    input  logic        ssck_in,        // Serial clock input (slave mode)
    output logic        ssck_out,       // Serial clock output (master mode)
    output logic        ssck_oe,        // Clock output enable
    
    input  logic        ssi,            // Serial data input
    output logic        sso,            // Serial data output
    output logic        sso_oe,         // Data output enable
    
    input  logic        scs_in,         // Chip select input
    output logic        scs_out,        // Chip select output
    output logic        scs_oe,         // Chip select output enable
    
    // CPU Interface
    input  logic        cs,             // Chip select for register access
    input  logic        we,             // Write enable
    input  logic [4:0]  addr,           // Register address
    input  logic [7:0]  wdata,          // Write data
    output logic [7:0]  rdata,          // Read data
    output logic        ready,          // Transfer ready
    
    // Interrupt Outputs
    output logic        txi_int,        // Transmit data register empty interrupt
    output logic        rxi_int,        // Receive data register full interrupt
    output logic        tei_int,        // Transmit end interrupt
    output logic        oei_int,        // Overrun error interrupt
    output logic        cei_int,        // Conflict error interrupt
    
    // Module Stop Control
    input  logic        module_stop     // Module stop control
);

// Register Map Addresses
localparam [4:0] SSCRH_ADDR   = 5'h00;  // SS Control Register H
localparam [4:0] SSCRL_ADDR   = 5'h01;  // SS Control Register L
localparam [4:0] SSMR_ADDR    = 5'h02;  // SS Mode Register
localparam [4:0] SSER_ADDR    = 5'h03;  // SS Enable Register
localparam [4:0] SSSR_ADDR    = 5'h04;  // SS Status Register
localparam [4:0] SSCR2_ADDR   = 5'h05;  // SS Control Register 2
localparam [4:0] SSTDR0_ADDR  = 5'h08;  // SS Transmit Data Register 0
localparam [4:0] SSTDR1_ADDR  = 5'h09;  // SS Transmit Data Register 1
localparam [4:0] SSTDR2_ADDR  = 5'h0A;  // SS Transmit Data Register 2
localparam [4:0] SSTDR3_ADDR  = 5'h0B;  // SS Transmit Data Register 3
localparam [4:0] SSRDR0_ADDR  = 5'h0C;  // SS Receive Data Register 0
localparam [4:0] SSRDR1_ADDR  = 5'h0D;  // SS Receive Data Register 1
localparam [4:0] SSRDR2_ADDR  = 5'h0E;  // SS Receive Data Register 2
localparam [4:0] SSRDR3_ADDR  = 5'h0F;  // SS Receive Data Register 3

// Internal Registers
logic [7:0] sscrh;    // SS Control Register H
logic [7:0] sscrl;    // SS Control Register L
logic [7:0] ssmr;     // SS Mode Register
logic [7:0] sser;     // SS Enable Register
logic [7:0] sssr;     // SS Status Register
logic [7:0] sscr2;    // SS Control Register 2
logic [7:0] sstdr[4]; // SS Transmit Data Registers 0-3
logic [7:0] ssrdr[4]; // SS Receive Data Registers 0-3
logic [31:0] sstrsr;  // SS Shift Register (32-bit max)

// Register bit definitions
// SSCRH bits
wire mss    = sscrh[7];    // Master/Slave Select
wire bide   = sscrh[6];    // Bidirectional Mode Enable
wire sol    = sscrh[4];    // Serial Data Output Value Select
wire solp   = sscrh[3];    // SOL Bit Write Protect
wire scks   = sscrh[2];    // SSCK Pin Select
wire [1:0] css = sscrh[1:0]; // SCS Pin Select

// SSCRL bits
wire ssums  = sscrl[6];    // SSU Mode/Clock Synchronous Mode Select
wire sres   = sscrl[5];    // Software Reset
wire [1:0] dats = sscrl[1:0]; // Data Length Select

// SSMR bits
wire mls    = ssmr[7];     // MSB/LSB First Select
wire cpos   = ssmr[6];     // Clock Polarity Select
wire cphs   = ssmr[5];     // Clock Phase Select
wire [2:0] cks = ssmr[2:0]; // Clock Rate Select

// SSER bits
wire te     = sser[7];     // Transmit Enable
wire re     = sser[6];     // Receive Enable
wire teie   = sser[3];     // Transmit End Interrupt Enable
wire tie    = sser[2];     // Transmit Interrupt Enable
wire rie    = sser[1];     // Receive Interrupt Enable
wire ceie   = sser[0];     // Conflict Error Interrupt Enable

// SSSR bits
wire orer   = sssr[6];     // Overrun Error
wire tend   = sssr[3];     // Transmit End
wire tdre   = sssr[2];     // Transmit Data Register Empty
wire rdrf   = sssr[1];     // Receive Data Register Full
wire ce     = sssr[0];     // Conflict/Incomplete Error

// SSCR2 bits
wire sdos     = sscr2[7];  // Serial Data Pin Open Drain Select
wire ssckos   = sscr2[6];  // SSCK Pin Open Drain Select
wire scsos    = sscr2[5];  // SCS Pin Open Drain Select
wire tendsts  = sscr2[4];  // TEND Bit Set Timing Select
wire scsats   = sscr2[3];  // SCS Assertion Timing Select
wire ssodts   = sscr2[2];  // SSO Data Output Timing Select

// Internal signals
logic [7:0] bit_counter;
logic [7:0] data_length;
logic [15:0] clock_divider;
logic [15:0] clock_counter;
logic serial_clock;
logic shift_enable;
logic tx_shift_enable;
logic rx_shift_enable;
logic tx_active;
logic rx_active;
logic scs_active;
logic conflict_detect;

// State machines
typedef enum logic [2:0] {
    IDLE = 3'b000,
    START = 3'b001,
    SHIFT = 3'b010,
    END = 3'b011,
    ERROR = 3'b100
} state_t;

state_t tx_state, rx_state;

// Data length decode
always_comb begin
    case (dats)
        2'b00: data_length = 8'd8;   // 8 bits
        2'b01: data_length = 8'd16;  // 16 bits
        2'b10: data_length = 8'd32;  // 32 bits
        2'b11: data_length = 8'd24;  // 24 bits
    endcase
end

// Clock generation for master mode
always_comb begin
    case (cks)
        3'b001: clock_divider = 16'd4;    // φ/4
        3'b010: clock_divider = 16'd8;    // φ/8
        3'b011: clock_divider = 16'd16;   // φ/16
        3'b100: clock_divider = 16'd32;   // φ/32
        3'b101: clock_divider = 16'd64;   // φ/64
        3'b110: clock_divider = 16'd128;  // φ/128
        3'b111: clock_divider = 16'd256;  // φ/256
        default: clock_divider = 16'd8;   // Default φ/8
    endcase
end

// Clock divider counter
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clock_counter <= 16'h0;
        serial_clock <= 1'b0;
    end else if (module_stop) begin
        clock_counter <= 16'h0;
        serial_clock <= 1'b0;
    end else if (mss && scks && (tx_active || rx_active)) begin
        if (clock_counter >= (clock_divider - 1)) begin
            clock_counter <= 16'h0;
            serial_clock <= ~serial_clock;
        end else begin
            clock_counter <= clock_counter + 1'b1;
        end
    end else begin
        clock_counter <= 16'h0;
        serial_clock <= cpos ? 1'b1 : 1'b0; // Idle state based on polarity
    end
end

// Register write operations
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset all registers to initial values
        sscrh <= 8'h08;  // SOLP = 1
        sscrl <= 8'h00;
        ssmr  <= 8'h00;
        sser  <= 8'h00;
        sssr  <= 8'h0C;  // TEND = 1, TDRE = 1
        sscr2 <= 8'h00;
        for (int i = 0; i < 4; i++) begin
            sstdr[i] <= 8'h00;
        end
    end else if (module_stop) begin
        // Module stop state - retain register values
    end else if (sres) begin
        // Software reset
        sssr[6:0] <= 7'b0001100; // Clear ORER, CE, RDRF; Set TEND, TDRE
        sser[7:6] <= 2'b00;      // Clear TE, RE
    end else if (cs && we) begin
        case (addr)
            SSCRH_ADDR: begin
                if (!solp || (solp && addr != SSCRH_ADDR)) begin
                    sscrh <= wdata;
                end else begin
                    // SOL bit write protection
                    sscrh <= {wdata[7:5], solp, wdata[3:0]};
                end
            end
            SSCRL_ADDR: begin
                sscrl <= wdata;
                if (wdata[5]) begin // SRES bit
                    sssr[6:0] <= 7'b0001100;
                    sser[7:6] <= 2'b00;
                end
            end
            SSMR_ADDR:  ssmr <= wdata;
            SSER_ADDR:  sser <= wdata;
            SSSR_ADDR: begin
                // Status register - clear on write after read
                if (wdata[6] == 1'b0) sssr[6] <= 1'b0; // Clear ORER
                if (wdata[3] == 1'b0) sssr[3] <= 1'b0; // Clear TEND
                if (wdata[2] == 1'b0) sssr[2] <= 1'b0; // Clear TDRE
                if (wdata[1] == 1'b0) sssr[1] <= 1'b0; // Clear RDRF
                if (wdata[0] == 1'b0) sssr[0] <= 1'b0; // Clear CE
            end
            SSCR2_ADDR: sscr2 <= wdata;
            SSTDR0_ADDR: if (data_length >= 8'd8)  sstdr[0] <= wdata;
            SSTDR1_ADDR: if (data_length >= 8'd16) sstdr[1] <= wdata;
            SSTDR2_ADDR: if (data_length >= 8'd24) sstdr[2] <= wdata;
            SSTDR3_ADDR: if (data_length >= 8'd32) sstdr[3] <= wdata;
        endcase
    end
end

// Register read operations
always_comb begin
    rdata = 8'h00;
    ready = 1'b1;  // Always ready for both read and write operations

    if (cs) begin
        if (!we) begin
            // Read operation
            case (addr)
                SSCRH_ADDR:  rdata = sscrh;
                SSCRL_ADDR:  rdata = sscrl;
                SSMR_ADDR:   rdata = ssmr;
                SSER_ADDR:   rdata = sser;
                SSSR_ADDR:   rdata = sssr;
                SSCR2_ADDR:  rdata = sscr2;
                SSTDR0_ADDR: rdata = (data_length >= 8'd8)  ? sstdr[0] : 8'h00;
                SSTDR1_ADDR: rdata = (data_length >= 8'd16) ? sstdr[1] : 8'h00;
                SSTDR2_ADDR: rdata = (data_length >= 8'd24) ? sstdr[2] : 8'h00;
                SSTDR3_ADDR: rdata = (data_length >= 8'd32) ? sstdr[3] : 8'h00;
                SSRDR0_ADDR: rdata = (data_length >= 8'd8)  ? ssrdr[0] : 8'h00;
                SSRDR1_ADDR: rdata = (data_length >= 8'd16) ? ssrdr[1] : 8'h00;
                SSRDR2_ADDR: rdata = (data_length >= 8'd24) ? ssrdr[2] : 8'h00;
                SSRDR3_ADDR: rdata = (data_length >= 8'd32) ? ssrdr[3] : 8'h00;
                default:     rdata = 8'h00;
            endcase
        end
        // For write operations, ready is still 1'b1
    end
end

// Transmit state machine
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_state <= IDLE;
        tx_active <= 1'b0;
        bit_counter <= 8'h00;
        sstrsr <= 32'h00000000;
    end else if (module_stop || sres) begin
        tx_state <= IDLE;
        tx_active <= 1'b0;
        bit_counter <= 8'h00;
    end else begin
        case (tx_state)
            IDLE: begin
                if (te && tdre && |sstdr[0]) begin
                    // Load shift register with transmit data
                    case (data_length)
                        8'd8:  sstrsr <= {24'h000000, sstdr[0]};
                        8'd16: sstrsr <= {16'h0000, sstdr[1], sstdr[0]};
                        8'd24: sstrsr <= {8'h00, sstdr[2], sstdr[1], sstdr[0]};
                        8'd32: sstrsr <= {sstdr[3], sstdr[2], sstdr[1], sstdr[0]};
                    endcase
                    tx_state <= START;
                    tx_active <= 1'b1;
                    bit_counter <= 8'h00;
                end
            end
            
            START: begin
                if (shift_enable) begin
                    tx_state <= SHIFT;
                end
            end
            
            SHIFT: begin
                if (shift_enable) begin
                    if (mls) begin
                        // MSB first
                        sstrsr <= {sstrsr[30:0], 1'b0};
                    end else begin
                        // LSB first
                        sstrsr <= {1'b0, sstrsr[31:1]};
                    end
                    
                    bit_counter <= bit_counter + 1'b1;
                    
                    if (bit_counter >= (data_length - 1)) begin
                        tx_state <= END;
                    end
                end
            end
            
            END: begin
                tx_active <= 1'b0;
                tx_state <= IDLE;
            end
            
            default: tx_state <= IDLE;
        endcase
    end
end

// Receive state machine
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_state <= IDLE;
        rx_active <= 1'b0;
        for (int i = 0; i < 4; i++) begin
            ssrdr[i] <= 8'h00;
        end
    end else if (module_stop || sres) begin
        rx_state <= IDLE;
        rx_active <= 1'b0;
    end else begin
        case (rx_state)
            IDLE: begin
                if (re && (!mss || (mss && scs_active))) begin
                    rx_state <= START;
                    rx_active <= 1'b1;
                    bit_counter <= 8'h00;
                end
            end
            
            START: begin
                if (shift_enable) begin
                    rx_state <= SHIFT;
                end
            end
            
            SHIFT: begin
                if (shift_enable) begin
                    if (mls) begin
                        // MSB first
                        sstrsr <= {sstrsr[30:0], ssi};
                    end else begin
                        // LSB first
                        sstrsr <= {ssi, sstrsr[31:1]};
                    end
                    
                    bit_counter <= bit_counter + 1'b1;
                    
                    if (bit_counter >= (data_length - 1)) begin
                        rx_state <= END;
                    end
                end
            end
            
            END: begin
                // Transfer received data to receive registers
                case (data_length)
                    8'd8:  ssrdr[0] <= sstrsr[7:0];
                    8'd16: {ssrdr[1], ssrdr[0]} <= sstrsr[15:0];
                    8'd24: {ssrdr[2], ssrdr[1], ssrdr[0]} <= sstrsr[23:0];
                    8'd32: {ssrdr[3], ssrdr[2], ssrdr[1], ssrdr[0]} <= sstrsr[31:0];
                endcase
                
                rx_active <= 1'b0;
                rx_state <= IDLE;
            end
            
            default: rx_state <= IDLE;
        endcase
    end
end

// Shift enable generation based on clock phase and polarity
always_comb begin
    if (ssums) begin
        // Clock synchronous mode - CPHS setting invalid
        shift_enable = (mss ? serial_clock : ssck_in) ^ cpos;
    end else begin
        // SSU mode
        case ({cpos, cphs})
            2'b00: shift_enable = (mss ? serial_clock : ssck_in) & ~(mss ? serial_clock : ssck_in); // Rising edge
            2'b01: shift_enable = ~(mss ? serial_clock : ssck_in) & (mss ? serial_clock : ssck_in); // Falling edge
            2'b10: shift_enable = ~(mss ? serial_clock : ssck_in) & (mss ? serial_clock : ssck_in); // Falling edge
            2'b11: shift_enable = (mss ? serial_clock : ssck_in) & ~(mss ? serial_clock : ssck_in); // Rising edge
        endcase
    end
end

// SCS control logic
always_comb begin
    case (css)
        2'b00: begin // I/O port
            scs_out = 1'b1;
            scs_oe = 1'b0;
            scs_active = 1'b0;
        end
        2'b01: begin // SCS input
            scs_out = 1'b1;
            scs_oe = 1'b0;
            scs_active = ~scs_in;
        end
        2'b10: begin // Automatic input/output
            scs_out = tx_active || rx_active ? 1'b0 : 1'b1;
            scs_oe = mss;
            scs_active = ~scs_in;
        end
        2'b11: begin // Automatic output
            scs_out = tx_active || rx_active ? 1'b0 : 1'b1;
            scs_oe = mss;
            scs_active = mss ? (tx_active || rx_active) : ~scs_in;
        end
    endcase
end

// Conflict detection
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        conflict_detect <= 1'b0;
    end else if (mss && css == 2'b10 && !scs_in && !ssums) begin
        conflict_detect <= 1'b1;
        // Clear MSS bit on conflict
        sscrh[7] <= 1'b0;
    end else begin
        conflict_detect <= 1'b0;
    end
end

// Status flag updates
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sssr <= 8'h0C; // TEND = 1, TDRE = 1
    end else if (module_stop) begin
        // Maintain status in module stop
    end else begin
        // TDRE flag
        if (te && tx_state == IDLE && !tx_active) begin
            sssr[2] <= 1'b1; // Set TDRE
        end else if (cs && we && addr == SSTDR0_ADDR) begin
            sssr[2] <= 1'b0; // Clear TDRE on write to SSTDR
        end
        
        // TEND flag
        if (tx_state == END && !tx_active) begin
            if (tendsts) begin
                sssr[3] <= 1'b1; // Set after last bit transmitted
            end else begin
                sssr[3] <= 1'b1; // Set while last bit being transmitted
            end
        end
        
        // RDRF flag
        if (rx_state == END) begin
            if (sssr[1]) begin
                sssr[6] <= 1'b1; // Set ORER if RDRF already set
            end else begin
                sssr[1] <= 1'b1; // Set RDRF
            end
        end else if (cs && !we && (addr >= SSRDR0_ADDR && addr <= SSRDR3_ADDR)) begin
            sssr[1] <= 1'b0; // Clear RDRF on read from SSRDR
        end
        
        // CE flag
        if (conflict_detect) begin
            sssr[0] <= 1'b1; // Set conflict error
        end
        
        // Handle incomplete error for slave mode
        if (!mss && css != 2'b00 && scs_in && (tx_active || rx_active)) begin
            sssr[0] <= 1'b1; // Set incomplete error
        end
    end
end

// Output pin control
always_comb begin
    // Serial clock output
    if (scks && mss) begin
        ssck_out = serial_clock;
        ssck_oe = 1'b1;
    end else begin
        ssck_out = 1'b0;
        ssck_oe = 1'b0;
    end
    
    // Serial data output
    if (bide) begin
        // Bidirectional mode
        if (te && !re) begin
            sso = mls ? sstrsr[31] : sstrsr[0];
            sso_oe = 1'b1;
        end else begin
            sso = sol;
            sso_oe = 1'b0;
        end
    end else begin
        // Standard mode
        if ((mss && te) || (!mss && te)) begin
            sso = mls ? sstrsr[31] : sstrsr[0];
            sso_oe = (mss && te) || (!mss && te);
        end else begin
            sso = sol;
            sso_oe = 1'b0;
        end
    end
end

// Interrupt generation
always_comb begin
    txi_int = tie && tdre;          // Transmit data register empty
    rxi_int = rie && rdrf;          // Receive data register full
    tei_int = teie && tend;         // Transmit end
    oei_int = rie && orer;          // Overrun error
    cei_int = ceie && ce;           // Conflict error
end

endmodule