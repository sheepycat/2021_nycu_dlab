`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/05 21:43:22
// Design Name: 
// Module Name: md5_cal
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


module md5_cal(
    input passwd_hash,
    input clk,
    input reset_n,
    input enable,
    input [63:0] data_in,
    output reg done,
    output [127:0] data_out
    );
    reg [31:0]r_temp;
    reg [31:0] r[0:63];
    reg [31:0] k[0:63];
    reg [31:0] word[0:15];
    reg [2:0] P,P_next;
    reg [31:0] h0, h1, h2, h3;
    reg [31:0] a, b, c, d ,f ,g;
    reg [6:0] i;
    parameter [2:0] S_INIT = 3'b000,S_VAL = 3'b001, S_FOR = 3'b010,S_FADD = 3'b011,
                     S_HVAL = 3'b100,S_FIN = 3'b101,S_BACK = 3'b110;
    always @(posedge clk)begin
    if(~reset_n)
            begin
                r[0]=7; r[1]=12; r[2]=17; r[3]=22; r[4]=7; r[5]=12; r[6]=17; r[7]=22; r[8]=7; r[9]=12; r[10]=17; r[11]=22; r[12]=7; r[13]=12; r[14]=17; r[15]=22;
                r[16]=5; r[17]=9; r[18]=14; r[19]=20; r[20]=5; r[21]=9; r[22]=14; r[23]=20; r[24]=5; r[25]=9; r[26]=14; r[27]=20; r[28]=5; r[29]=9; r[30]=14; r[31]=20;
                r[32]=4; r[33]=11; r[34]=16; r[35]=23; r[36]=4; r[37]=11; r[38]=16; r[39]=23; r[40]=4; r[41]=11; r[42]=16; r[43]=23; r[44]=4; r[45]=11; r[46]=16; r[47]=23;
                r[48]=6; r[49]=10; r[50]=15; r[51]=21; r[52]=6; r[53]=10; r[54]=15; r[55]=21; r[56]=6; r[57]=10; r[58]=15; r[59]=21; r[60]=6; r[61]=10; r[62]=15; r[63]=21;
                
                k[0]=32'hd76aa478; k[1]=32'he8c7b756; k[2]=32'h242070db; k[3]=32'hc1bdceee;
                k[4]=32'hf57c0faf; k[5]=32'h4787c62a; k[6]=32'ha8304613; k[7]=32'hfd469501;
                k[8]=32'h698098d8; k[9]=32'h8b44f7af; k[10]=32'hffff5bb1; k[11]=32'h895cd7be;
                k[12]=32'h6b901122; k[13]=32'hfd987193; k[14]=32'ha679438e; k[15]=32'h49b40821;
                k[16]=32'hf61e2562; k[17]=32'hc040b340; k[18]=32'h265e5a51; k[19]=32'he9b6c7aa;
                k[20]=32'hd62f105d; k[21]=32'h02441453; k[22]=32'hd8a1e681; k[23]=32'he7d3fbc8;
                k[24]=32'h21e1cde6; k[25]=32'hc33707d6; k[26]=32'hf4d50d87; k[27]=32'h455a14ed;
                k[28]=32'ha9e3e905; k[29]=32'hfcefa3f8; k[30]=32'h676f02d9; k[31]=32'h8d2a4c8a;
                k[32]=32'hfffa3942; k[33]=32'h8771f681; k[34]=32'h6d9d6122; k[35]=32'hfde5380c;
                k[36]=32'ha4beea44; k[37]=32'h4bdecfa9; k[38]=32'hf6bb4b60; k[39]=32'hbebfbc70;
                k[40]=32'h289b7ec6; k[41]=32'heaa127fa; k[42]=32'hd4ef3085; k[43]=32'h04881d05;
                k[44]=32'hd9d4d039; k[45]=32'he6db99e5; k[46]=32'h1fa27cf8; k[47]=32'hc4ac5665;
                k[48]=32'hf4292244; k[49]=32'h432aff97; k[50]=32'hab9423a7; k[51]=32'hfc93a039;
                k[52]=32'h655b59c3; k[53]=32'h8f0ccc92; k[54]=32'hffeff47d; k[55]=32'h85845dd1;
                k[56]=32'h6fa87e4f; k[57]=32'hfe2ce6e0; k[58]=32'ha3014314; k[59]=32'h4e0811a1;
                k[60]=32'hf7537e82; k[61]=32'hbd3af235; k[62]=32'h2ad7d2bb; k[63]=32'heb86d391;
         end
     end
    always@ (posedge clk)begin
        if(~reset_n)
            P=S_INIT;
        else
            P=P_next;
    end
    always @(*)begin
        case(P)
        S_INIT:
           if(enable==1) P_next = S_VAL;
           else P_next = S_INIT;
        S_VAL:
            P_next = S_FOR;
        S_FOR:
            P_next = S_FADD;
        S_FADD:
            if(i==63)P_next =S_HVAL;
            else P_next = S_FOR;
        S_HVAL:
            P_next = S_FIN;
        S_FIN:
            P_next = S_BACK;
        S_BACK:
            P_next = S_INIT;
        endcase
    end  
    
    always@(posedge clk)begin
        if(P==S_INIT)begin
            h0 <= 'h67452301;
            h1 <= 'hefcdab89;
            h2 <= 'h98badcfe;
            h3 <= 'h10325476;
            word[0]<=0;word[1]<=0;word[2]<=0; word[3]<=0; word[4]<=0; word[5]<=0; word[6]<=0; word[7]<=0;
            word[8]<=0; word[9]<=0; word[10]<=0; word[11]<=0; word[12]<=0; word[13]<=0; word[14]<=0;word[15]<=0;
            word[0]<= data_in[63:32];
            word[1]<= data_in[31:0];
            i<=0;
            done<=0;
        end
        else if(P==S_VAL)begin
        word[0]<= data_in[63:32];
            word[1]<= data_in[31:0];
           word[2]<=128;
           word[14] <=64;
            a<=h0;
            b<=h1;
            c<=h2;
            d<=h3;
        end
        else if(P==S_FOR)begin
                if(i<=15)begin
                  f=(b&c)|((~b)&d);
                  g=i;
            end
            else if(i<=31)begin
                  f=(b&d)|(c&(~d));
                  g=((5*i)+1)%16;
            end
            else if(i<=47)begin
                  f=b^c^d;
                  g=((3*i)+5)%16;
            end
            else if(i<=63)begin
                  f=c^(b|(~d));
                  g=(7*i)%16;
            end
            f=f+a+k[i]+word[g];
            f=( (f<<(r[i])) | (f>>(32-r[i])) );
        end
        else if(P==S_FADD)begin
            a<=d;
            d<=c;
            c<=b;
            b<=b+f;//left rotate((a + f + k[i] + w[g]), r[i]);
            
            i<=i+1;
        end
        else if(P==S_HVAL)begin
            h0  <=h0+a;
            h1  <=h1+b;
            h2  <=h2+c;
            h3  <=h3+d;
        end
        else if(P==S_FIN)begin
            
            done<=1;
        end
    end
    assign data_out = { h0[7:0],h0[15:8],h0[23:16],h0[31:24],
                  h1[7:0],h1[15:8],h1[23:16],h1[31:24],
                  h2[7:0],h2[15:8],h2[23:16],h2[31:24],
                  h3[7:0],h3[15:8],h3[23:16],h3[31:24] };
     
endmodule
