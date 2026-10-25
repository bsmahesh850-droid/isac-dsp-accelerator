`timescale 1ns / 1ps

module tb_cordic_axis;

    parameter WIDTH = 16;
    parameter STAGES = 16;
    parameter CLK_PERIOD = 10;

    reg         clk;
    reg         rst_n;
    reg  [31:0] s_axis_tdata;
    reg         s_axis_valid;
    wire        s_axis_tready;
    
    wire [31:0] m_axis_tdata;
    wire        m_axis_valid;
    reg         m_axis_tready;

    cordic_axis_wrapper #(
        .WIDTH(WIDTH),
        .STAGES(STAGES)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_valid(s_axis_valid),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_valid(m_axis_valid),
        .m_axis_tready(m_axis_tready)
    );

    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        s_axis_valid = 0;
        s_axis_tdata = 32'h0;
        m_axis_tready = 1'b1;

        $dumpfile("cordic_axis_sim.vcd");
        $dumpvars(0, tb_cordic_axis);

        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        // Send streaming packets
        @(posedge clk);
        s_axis_valid = 1'b1;
        s_axis_tdata  = {16'sd10000, 16'sd0};

        @(posedge clk);
        s_axis_tdata  = {16'sd7071, 16'sd7071};

        @(posedge clk);
        s_axis_tdata  = {16'sd0, 16'sd10000};

        @(posedge clk);
        s_axis_tdata  = {-16'sd5000, -16'sd5000};

        @(posedge clk);
        s_axis_valid = 1'b0;
        s_axis_tdata  = 32'h0;

        #(CLK_PERIOD * 25);
        $display("Simulation completed successfully.");
        $finish;
    end

    always @(posedge clk) begin
        if (m_axis_valid && m_axis_tready) begin
            $display("Time = %0t ns | Magnitude = %0d | Phase = %0d", 
                     $time, 
                     $signed(m_axis_tdata[31:16]), 
                     $signed(m_axis_tdata[15:0]));
        end
    end

endmodule
