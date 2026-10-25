// =====================================================================
// Module: fft_butterfly_axis
// Description: Pipelined Radix-2 Butterfly Processing Element 
//              with AXI-Stream Interface for 6G Baseband OFDM/FFT
// =====================================================================

`timescale 1ns / 1ps

module fft_butterfly_axis #(
    parameter WIDTH = 16
) (
    input  wire                   clk,
    input  wire                   rst_n,
    
    // AXI-Stream Slave Interface (Combined Complex Inputs A and B)
    // Format: {Real_A [31:16], Imag_A [15:0]} or stream control
    input  wire [31:0]       s_axis_tdata_a,
    input  wire [31:0]       s_axis_tdata_b,
    input  wire                   s_axis_valid,
    output wire                   s_axis_tready,
    
    // AXI-Stream Master Interface (Butterfly Outputs X and Y)
    output reg  [31:0]       m_axis_tdata_x,
    output reg  [31:0]       m_axis_tdata_y,
    output reg                    m_axis_valid,
    input  wire                   m_axis_tready
);

    // Unpack Complex Input A (Real and Imaginary)
    wire signed [WIDTH-1:0] real_a = s_axis_tdata_a[31:16];
    wire signed [WIDTH-1:0] imag_a = s_axis_tdata_a[15:0];

    // Unpack Complex Input B (Real and Imaginary)
    wire signed [WIDTH-1:0] real_b = s_axis_tdata_b[31:16];
    wire signed [WIDTH-1:0] imag_b = s_axis_tdata_b[15:0];

    // Pipeline registers for butterfly arithmetic stages
    reg signed [WIDTH:0]    sum_real, sub_real;
    reg signed [WIDTH:0]    sum_imag, sub_imag;
    reg                     stage_valid;

    assign s_axis_tready = m_axis_tready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_real       <= 0;
            sub_real       <= 0;
            sum_imag       <= 0;
            sub_imag       <= 0;
            stage_valid    <= 1'b0;
            m_axis_tdata_x <= 32'h0;
            m_axis_tdata_y <= 32'h0;
            m_axis_valid   <= 1'b0;
        end else if (s_axis_tready) begin
            // -------------------------------------------------------------
            // Pipeline Stage 1: Radix-2 Complex Addition & Subtraction
            // X = A + B
            // Y = A - B
            // -------------------------------------------------------------
            if (s_axis_valid) begin
                sum_real <= $signed(real_a) + $signed(real_b);
                sub_real <= $signed(real_a) - $signed(real_b);
                sum_imag <= $signed(imag_a) + $signed(imag_b);
                sub_imag <= $signed(imag_a) - $signed(imag_b);
                stage_valid <= 1'b1;
            end else begin
                stage_valid <= 1'b0;
            end

            // -------------------------------------------------------------
            // Pipeline Stage 2: Output Registration & Truncation/Scaling
            // -------------------------------------------------------------
            if (stage_valid) begin
                m_axis_tdata_x <= {sum_real[WIDTH:1], sum_imag[WIDTH:1]};
                m_axis_tdata_y <= {sub_real[WIDTH:1], sub_imag[WIDTH:1]};
                m_axis_valid   <= 1'b1;
            end else begin
                m_axis_valid   <= 1'b0;
            end
        end
    end

endmodule
