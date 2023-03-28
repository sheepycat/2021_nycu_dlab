`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/25 17:17:44
// Design Name: 
// Module Name: SeqMultiplier
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module SeqMultiplier(input wire clk, input wire enable,
                     input wire [7:0] A, input wire [7:0] B,
                     output wire [15:0] C);
    reg [15:0] prod; // reg 暫存
    reg [7:0] mult;
    reg [3:0] counter; //計數器，控制shift次數
   
    wire shift; 
    assign C = prod;
    assign shift = |(counter^7); //shift = 1 when counter<7; shift = 0 when counter==7
    // counter的每一bit xor 7 ，再對每bit結果做or
    // 只有counter = 7 = 0111時，shift = 0
    always @(posedge clk) begin
        if (!enable) begin
            mult <= B;
            prod <= 0;
            counter <= 0;
        end
        else begin
            mult <= mult << 1;
            prod <= (prod + (A & {8{mult[7]}})) << shift; // A的每個bit和mult最高位and -> prod+result後左移 
            counter <= counter + shift;
        end
    end
endmodule