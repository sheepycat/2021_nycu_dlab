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
    reg [15:0] prod; // reg �Ȧs
    reg [7:0] mult;
    reg [3:0] counter; //�p�ƾ��A����shift����
   
    wire shift; 
    assign C = prod;
    assign shift = |(counter^7); //shift = 1 when counter<7; shift = 0 when counter==7
    // counter���C�@bit xor 7 �A�A��Cbit���G��or
    // �u��counter = 7 = 0111�ɡAshift = 0
    always @(posedge clk) begin
        if (!enable) begin
            mult <= B;
            prod <= 0;
            counter <= 0;
        end
        else begin
            mult <= mult << 1;
            prod <= (prod + (A & {8{mult[7]}})) << shift; // A���C��bit�Mmult�̰���and -> prod+result�ᥪ�� 
            counter <= counter + shift;
        end
    end
endmodule