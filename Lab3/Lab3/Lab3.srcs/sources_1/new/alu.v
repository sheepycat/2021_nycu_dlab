`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/11 01:22:25
// Design Name: 
// Module Name: alu
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


module alu(
        input signed[7:0] data,accum,
        input [2:0] opcode, 
        input clk,reset, 
        output reg signed[7:0] alu_out,
        output zero
        );
        reg  signed[7:0] temp;
      //  assign temp <= accum;
        assign zero = (accum == 0);
        always@(posedge clk) begin
             if(reset==1)begin
                alu_out = 0;
             end
             else begin
                case(opcode)
                    3'b000 : alu_out <= accum;
                    3'b001 : alu_out <= accum + data;
                    3'b010 : alu_out <= accum - data;
                    3'b011 : alu_out <= accum & data;
                    3'b100 : alu_out <= accum ^ data;
                    3'b101 : alu_out <= -accum;
                    3'b110 : alu_out <= accum* data;
                    //3'b110 : alu_out <= $signed(accum)* $signed(data);
                    3'b111 : alu_out <= data;
                    1'bX : alu_out <= 0;
                 endcase
                    
                            
                             
                    
             
             end
        
        
        end
        
endmodule
