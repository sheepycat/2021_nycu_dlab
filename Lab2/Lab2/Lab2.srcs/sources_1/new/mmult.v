`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/01 18:32:42
// Design Name: 
// Module Name: mmult
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


module mmult(
        input clk, // Clock signal.
        input reset_n, // Reset signal (negative logic).
        input enable, // Activation signal for matrix multiplication (tells the circuit that A and B are ready for use).
        input [0:9*8-1] A_mat, // A matrix.
        input [0:9*8-1] B_mat, // B matrix.
        output valid, // Signals that the output is valid to read.
        output reg [0:9*17-1] C_mat // The result of A x B.
        );
     //reg [0:9*17-1] result_store;
     reg [16:0] counter;
     wire shift;
     reg [7:0] A [0:2][0:2];
     reg [7:0] B [0:2][0:2];
     reg [16:0] C [0:2][0:2];
     integer i,j,k,done;
     
     
     assign valid = !(|(counter^1));//=1 when counter==1
     always @(enable && !reset_n) //enable+reset
     begin
        C_mat = 152'b0;
        counter = 0;
     end
     always @(!enable)
     begin
         C_mat = 152'b0;
         counter = 0;
         {A[0][0],A[0][1],A[0][2],A[1][0],A[1][1],A[1][2],A[2][0],A[2][1],A[2][2]} = A_mat;
         {B[0][0],B[0][1],B[0][2],B[1][0],B[1][1],B[1][2],B[2][0],B[2][1],B[2][2]} = B_mat;
         {C[0][0],C[0][1],C[0][2],C[1][0],C[1][1],C[1][2],C[2][0],C[2][1],C[2][2]} = C_mat;
     end
        
     
     always @(posedge clk) begin
       if(enable&&!counter) begin
       i=0;
       j=0;
       k=0;
            for(i=0;i<3;i = i+1)
                for(j=0;j<3;j = j+1)
                    for(k=0;k<3;k = k+1)
                       C[i][j] = C[i][j]+(A[i][k]*B[k][j]);
         counter = 1;       
        C_mat = {C[0][0],C[0][1],C[0][2],C[1][0],C[1][1],C[1][2],C[2][0],C[2][1],C[2][2]} ;
       end
     
     end


endmodule
