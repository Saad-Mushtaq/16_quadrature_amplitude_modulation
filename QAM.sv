`timescale 1ns / 1ps

// You MUST NOT change the module name or the ports declarations

module QAM(
    input wire clk,
    input wire rst,
    input wire [3:0] symbol,
    input wire data_valid_i,
    input wire start,
    input wire done_flag_i,

    output reg [7:0] I_data,
    output reg [7:0] Q_data,
    output reg data_valid_o,
    output reg done_flag_o
);
    // ----------- Insert your codes below --------------//

    localparam INIT = 0,
               CALC_I = 1,
               CALC_Q = 2,
               DONE = 3;

    reg [1:0] current_state, next_state;
    reg done_flag_i_d1;
    reg [1:0] lut_i;
    reg [7:0] lut_o;
    reg [7:0] I_data_a1;

    //****************************************************//
    ////////////////////////16-QAM FSM//////////////////////
    //****************************************************//

// FSM State register

always @ (posedge clk, negedge rst) begin
    if(!rst) begin
        current_state <= 2'b0;
    end
    else begin
        current_state <= next_state;
    end
end

// FSM next state logic

always @ * begin
    case (current_state)
        INIT: next_state = start ?  CALC_I : INIT;
        CALC_I: next_state = data_valid_i ? CALC_Q : done_flag_i ? DONE : CALC_I;
        CALC_Q: next_state = (done_flag_i_d1 | done_flag_i) ? DONE : CALC_I;
        DONE: next_state = INIT;
        default: next_state = INIT;
    endcase
end

always @ (posedge clk, negedge rst) begin
    if(!rst) begin
        done_flag_i_d1 <= 1'b0;
    end
    else begin
        done_flag_i_d1 <= done_flag_i;
    end
end

always @ (posedge clk, negedge rst) begin
    if(!rst) begin
        I_data <= 8'b0;
    end
    else begin
        I_data <= I_data_a1;
    end
end

assign lut_i = current_state == CALC_I ? symbol[3:2] : current_state == CALC_Q ? symbol[1:0] : 2'b0;
assign I_data_a1 = current_state == CALC_I ? lut_o : I_data;
assign Q_data = current_state == CALC_Q ? lut_o : 8'b0;
assign data_valid_o = current_state == CALC_Q;
assign done_flag_o = current_state == DONE;

always @ * begin
    case (lut_i)
        2'b00: lut_o = 8'b11000011;
        2'b01: lut_o = 8'b00111101;
        2'b10: lut_o = 8'b11101100;
        2'b11: lut_o = 8'b00010100;
        default: lut_o = 8'b0;
    endcase
end

endmodule
