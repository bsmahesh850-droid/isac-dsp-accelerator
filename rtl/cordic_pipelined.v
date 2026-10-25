// =====================================================================
// Module 1: cordic_stage
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
    input  signed [WIDTH-1:0]     atan_const,
    output reg                    out_valid,
    output reg signed [WIDTH-1:0] x_out,
    output reg signed [WIDTH-1:0] y_out,
    output reg signed [WIDTH-1:0] z_out
);

    wire direction = y_in[WIDTH-1]; 

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
                x_out <= x_in + y_shifted;
                y_out <= y_in - x_shifted;
                z_out <= z_in - atan_const;
            end else begin
                x_out <= x_in - y_shifted;
                y_out <= y_in + x_shifted;
                z_out <= z_in + atan_const;
            end
        end
    end

endmodule


// =====================================================================
// Module 2: cordic_pipelined
// Description: Multi-stage pipelined CORDIC processor for Vectoring Mode
// =====================================================================

module cordic_pipelined #(
    parameter WIDTH = 16,
    parameter STAGES = 16
) (
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   s_axis_valid,
    input  signed [WIDTH-1:0]     x_start,
    input  signed [WIDTH-1:0]     y_start,
    output wire                   m_axis_valid,
    output wire signed [WIDTH-1:0] magnitude,
    output wire signed [WIDTH-1:0] phase
);

    wire signed [WIDTH-1:0] x_wire [0:STAGES];
    wire signed [WIDTH-1:0] y_wire [0:STAGES];
    wire signed [WIDTH-1:0] z_wire [0:STAGES];
    wire                    valid_wire [0:STAGES];

    function signed [WIDTH-1:0] get_atan_const;
        input integer idx;
        begin
            case (idx)
                0:  get_atan_const = 16'sd12868;
                1:  get_atan_const = 16'sd7593;
                2:  get_atan_const = 16'sd4013;
                3:  get_atan_const = 16'sd2036;
                4:  get_atan_const = 16'sd1022;
                5:  get_atan_const = 16'sd511;
                6:  get_atan_const = 16'sd256;
                7:  get_atan_const = 16'sd128;
                8:  get_atan_const = 16'sd64;
                9:  get_atan_const = 16'sd32;
                10: get_atan_const = 16'sd16;
                11: get_atan_const = 16'sd8;
                12: get_atan_const = 16'sd4;
                13: get_atan_const = 16'sd2;
                14: get_atan_const = 16'sd1;
                15: get_atan_const = 16'sd1;
                default: get_atan_const = 16'sd0;
            endcase
        end
    endfunction

    assign x_wire[0]     = x_start;
    assign y_wire[0]     = y_start;
    assign z_wire[0]     = {WIDTH{1'b0}};
    assign valid_wire[0] = s_axis_valid;

    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : gen_cordic_stages
            cordic_stage #(
                .WIDTH(WIDTH),
                .STAGE_IDX(i)
            ) u_stage (
                .clk(clk),
                .rst_n(rst_n),
                .in_valid(valid_wire[i]),
                .x_in(x_wire[i]),
                .y_in(y_wire[i]),
                .z_in(z_wire[i]),
                .atan_const(get_atan_const(i)),
                .out_valid(valid_wire[i+1]),
                .x_out(x_wire[i+1]),
                .y_out(y_wire[i+1]),
                .z_out(z_wire[i+1])
            );
        end
    endgenerate

    assign m_axis_valid = valid_wire[STAGES];
    assign magnitude    = x_wire[STAGES];
    assign phase        = z_wire[STAGES];

endmodule
