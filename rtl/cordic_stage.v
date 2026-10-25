// =====================================================================
// Module: cordic_stage
// Description: Single pipeline stage for CORDIC processor (Vectoring Mode)
// =====================================================================

module cordic_stage #(
    parameter WIDTH = 16,
    parameter STAGE_IDX = 0
) (
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   in_valid,
    input  signed [WIDTH-1:0]     x_in,
    input  signed [WIDTH-1:0]     y_in,
    input  signed [WIDTH-1:0]     z_in,
    input  signed [WIDTH-1:0]     atan_const, // Pre-calculated fixed-point angle constant
    output reg                    out_valid,
    output reg signed [WIDTH-1:0] x_out,
    output reg signed [WIDTH-1:0] y_out,
    output reg signed [WIDTH-1:0] z_out
);

    // Determine rotation direction based on the sign of y_in
    // Vectoring mode: if y < 0, rotate positive (direction = 1); else rotate negative (direction = 0)
    wire direction = y_in[WIDTH-1]; 

    // Shift values by STAGE_IDX (simulating division by 2^i using arithmetic right shift)
    wire signed [WIDTH-1:0] x_shifted = x_in >>> STAGE_IDX;
    wire signed [WIDTH-1:0] y_shifted = y_in >>> STAGE_IDX;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            x_out     <= {WIDTH{1'b0}};
            y_out     <= {WIDTH{1'b0}};
            z_out     <= {WIDTH{1'b0}};
        end else begin
            out_valid <= in_valid;
            
            if (direction) begin
                // y is negative -> add shifted components, subtract angle
                x_out <= x_in + y_shifted;
                y_out <= y_in - x_shifted;
                z_out <= z_in - atan_const;
            end else begin
                // y is positive -> subtract shifted components, add angle
                x_out <= x_in - y_shifted;
                y_out <= y_in + x_shifted;
                z_out <= z_in + atan_const;
            end
        end
    end

endmodule
