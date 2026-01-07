`timescale 1ns/1ps

module tb_QAM;
    // ----------------------------------------------------------------------
    // DUT I/O
    // ----------------------------------------------------------------------
    logic clk;
    logic rst;
    logic [3:0] symbol;
    logic data_valid_i;
    logic start;
    logic done_flag_i;

    logic [7:0] I_data;
    logic [7:0] Q_data;
    logic data_valid_o;
    logic done_flag_o;

    // ----------------------------------------------------------------------
    // Clock generator
    // ----------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;   // 100MHz

    // ----------------------------------------------------------------------
    // Instantiate DUT
    // ----------------------------------------------------------------------
    QAM dut (
        .clk(clk),
        .rst(rst),
        .symbol(symbol),
        .data_valid_i(data_valid_i),
        .start(start),
        .done_flag_i(done_flag_i),

        .I_data(I_data),
        .Q_data(Q_data),
        .data_valid_o(data_valid_o),
        .done_flag_o(done_flag_o)
    );

    // ----------------------------------------------------------------------
    // Storage for outputs
    // ----------------------------------------------------------------------
    localparam int NUM_TEST = 12;

    logic [3:0] test_symbols   [0:NUM_TEST-1];
    logic [7:0] cap_I          [0:NUM_TEST-1];
    logic [7:0] cap_Q          [0:NUM_TEST-1];
    int out_count;

    // ----------------------------------------------------------------------
    // QAM mapping function
    // ----------------------------------------------------------------------
    function automatic [7:0] map_qam(input bit [1:0] bits);
        case(bits)
            2'b00: map_qam = 8'b11000011;  // -3/sqrt(10)
            2'b10: map_qam = 8'b11101100;  // -1/sqrt(10)
            2'b01: map_qam = 8'b00111101;  //  3/sqrt(10)
            2'b11: map_qam = 8'b00010100;  //  1/sqrt(10)
        endcase
    endfunction

    // ----------------------------------------------------------------------
    // Reset task
    // ----------------------------------------------------------------------
    task automatic apply_reset();
        rst = 0;
        start = 0;
        data_valid_i = 0;
        done_flag_i = 0;
        symbol = 0;

        repeat(20) @(posedge clk);
        rst = 1;
        @(posedge clk);
    endtask

    // ----------------------------------------------------------------------
    // Stimulus: send random/selected symbols
    // ----------------------------------------------------------------------
    initial begin : stim_proc
        apply_reset();

        for (int i = 0; i < NUM_TEST; i++)
        test_symbols[i] = $urandom_range(0, 15);

        // ====== start pulse ======
        @(posedge clk);
        start <= 1;
        @(posedge clk);
        start <= 0;

        out_count = 0;

        for (int i = 0; i < NUM_TEST; i++) begin
            @(posedge clk);
            symbol <= test_symbols[i];
            data_valid_i <= 1;
            @(posedge clk);
            data_valid_i <= 0;
        end

        @(posedge clk);
        done_flag_i <= 1;
        @(posedge clk);
        done_flag_i <= 0;
    end


    // ----------------------------------------------------------------------
    // Monitor outputs
    // ----------------------------------------------------------------------
    initial begin : monitor_proc
        wait(rst == 1);

        forever begin
            @(posedge clk);

            if (data_valid_o) begin
                cap_I[out_count] = I_data;
                cap_Q[out_count] = Q_data;
                out_count++;
            end

            if (done_flag_o) begin
                $display("[%0t] done_flag_o detected, output count = %0d", $time, out_count);
                break;
            end
        end

        assert(out_count == NUM_TEST) else begin
            $error("Output symbol count mismatch: got=%0d exp=%0d", out_count, NUM_TEST);
            $finish;
        end
        
        for (int j = 0; j < NUM_TEST; j++) begin
            automatic logic [7:0] exp_I = map_qam(test_symbols[j][3:2]);
            automatic logic [7:0] exp_Q = map_qam(test_symbols[j][1:0]);
            $display("Iter @%0d: I_act=%b I_exp=%b | Q_act=%b Q_exp=%b", 
                         j, cap_I[j], exp_I, cap_Q[j], exp_Q);
            assert(cap_I[j] === exp_I) else begin
                $error("I_data mismatch @%0d: got=%b expected=%b",
                            j, cap_I[j], exp_I);
                $finish;
            end

            assert(cap_Q[j] === exp_Q) else begin
                $error("Q_data mismatch @%0d: got=%b expected=%b",
                            j, cap_Q[j], exp_Q);
                $finish;
            end
        end

        $display("QAM module TEST PASS!");
        #20;
        $finish;
    end

    // ----------------------------------------------------------------------
    // Check done_flag_o must appear within 5 cycles of done_flag_i
    // ----------------------------------------------------------------------
    int cycles = 0;
    initial begin : done_flag_check
        wait(done_flag_i == 1);
    
        while (cycles < 5) begin
            @(posedge clk);
            if (done_flag_o == 1) begin
                assert(1) else $error("Should never fail");
                disable done_flag_check;
            end
            cycles++;
        end

        $error("? done_flag_o did not assert within 5 cycles of done_flag_i!");
        disable done_flag_check;
    end

    // ----------------------------------------------------------------------
    // Timeout protection
    // ----------------------------------------------------------------------
    initial begin
        #20000;
        $error(" Simulation timeout!");
        $finish;
    end

endmodule
