// Monitor final processed outputs including FFT + CORDIC stages
    always @(posedge clk) begin
        if (m_axis_valid && m_axis_tready) begin
            $display("Time = %0t ns | Magnitude = %0d | Phase Angle = %0d", 
                     $time, 
                     $signed(m_axis_tdata[31:16]), 
                     $signed(m_axis_tdata[15:0]));
        end
    end
