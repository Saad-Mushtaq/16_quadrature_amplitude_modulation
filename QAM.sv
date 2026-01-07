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

endmodule
