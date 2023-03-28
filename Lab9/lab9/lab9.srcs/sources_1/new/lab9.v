`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2017/05/08 15:29:41
// Design Name: 
// Module Name: lab6
// Project Name: 
// Target Devices: 
// Tool Versions:
// Description: The sample top module of lab 6: sd card reader. The behavior of
//              this module is as follows
//              1. When the SD card is initialized, display a message on the LCD.
//                 If the initialization fails, an error message will be shown.
//              2. The user can then press usr_btn[2] to trigger the sd card
//                 controller to read the super block of the sd card (located at
//                 block # 8192) into the SRAM memory.
//              3. During SD card reading time, the four LED lights will be turned on.
//                 They will be turned off when the reading is done.
//              4. The LCD will then displayer the sector just been read, and the
//                 first byte of the sector.
//              5. Everytime you press usr_btn[2], the next byte will be displayed.
// 
// Dependencies: clk_divider, LCD_module, debounce, sd_card
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab8(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,


  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

localparam [2:0]  S_MAIN_IDLE = 3'b001,
                 S_MAIN_CAL = 3'b010, S_MAIN_SHOW = 3'b011, S_MAIN_NEXT = 3'b100;
                 


// Declare system variables
wire btn_level, btn_pressed;
reg  prev_btn_level;
reg  [2:0] P, P_next;
wire [127:0]data_out;
wire done;
wire [7:0] answer [0:7];
assign answer[3] = data_in[63:56];
assign answer[2] = data_in[55:48];
assign answer[1] = data_in[47:40];
assign answer[0] = data_in[39:32];
assign answer[7] = data_in[31:24];
assign answer[6] = data_in[23:16];
assign answer[5] = data_in[15: 8];
assign answer[4] = data_in[ 7: 0];
reg  [127:0] passwd_hash = 128'hE8CD0953ABDFDE433DFEC7FAA70DF7F6;
//md5 hash0(.clk(clk), .reset_n(reset_n), .enable(enable), .msg1(data_in[63:32]), .msg2(data_in[31:0]), .hash(data_out), .done(done));
md5_cal hash0(.clk(clk), .reset_n(reset_n), .enable(enable), .data_in(data_in), .data_out(data_out), .done(done));
reg  [127:0] row_A = "---HASH  INIT---";
reg  [127:0] row_B = "----------------";



assign usr_led = 4'h00;


debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level)
);

LCD_module lcd0( 
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);
wire [63:0]data_in;
assign     data_in[63:56] = passwd_try/10000000+'d48;
assign     data_in[55:48] = (passwd_try%10000000)/1000000+'d48;
assign     data_in[47:40] = (passwd_try%1000000)/100000+'d48;
assign     data_in[39:32] = (passwd_try%100000)/10000+'d48;
assign     data_in[31:24] = (passwd_try%10000)/1000+'d48;
assign     data_in[23:16] = (passwd_try%1000)/100+'d48;
assign     data_in[15:8] = (passwd_try%100)/10+'d48;
assign     data_in[7:0] = (passwd_try%10)+'d48;
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end
assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;
reg [1:0] find;
reg [1:0] enable;


always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_IDLE;
  end
  else begin
    P <= P_next;
  end
end
always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_IDLE: // wait for button clic
      if (btn_pressed == 1) P_next = S_MAIN_CAL;
      else P_next = S_MAIN_IDLE;
    S_MAIN_CAL:
     if(done==1)P_next = S_MAIN_NEXT;
     else P_next = S_MAIN_CAL;
     S_MAIN_NEXT:
        if(passwd_try==99999999 || data_out == passwd_hash)P_next = S_MAIN_SHOW;
        //if(passwd_hash==)P_next = S_MAIN_SHOW;
        else P_next = S_MAIN_CAL;
     S_MAIN_SHOW:
    P_next = S_MAIN_SHOW;
    default:
      P_next = S_MAIN_IDLE;
  endcase
end

//reg  [0:127] passwd_hash = 128'hE8CD0953ABDFDE433DFEC7FAA70DF7F6;
reg [31:0]word[15:0];
reg [63:0]passwd_try;

always @(posedge clk)begin
    if(~reset_n)begin
        passwd_try<=64'b0;
    end
    else if((P==S_MAIN_NEXT&&P_next == S_MAIN_CAL)&&passwd_try<99999999&&(data_out != passwd_hash))begin 
    passwd_try <=passwd_try+1;
    end
end
always @(posedge clk)begin
    if(~reset_n)begin
        enable<=0;
    end
    else if(P==S_MAIN_CAL)begin 
     enable<=1;
    end
    else if(P==S_MAIN_NEXT||P==S_MAIN_SHOW||P==S_MAIN_IDLE)begin 
     enable<=0;
    end
end
//clk 100_000ns = 1 ms
reg [23:0] clock;
reg [16:0] counter;
reg [55:0] counter_show;
wire [63:0] ans_out;


always @(posedge clk) begin
    if(~reset_n) begin
        clock <=0;
        counter<=0;
        
        
    end
    else if(P==S_MAIN_CAL||P==S_MAIN_NEXT)begin
       if(counter == 'd100000)begin
            clock <= clock+'d1;
            counter <= 0;
            counter_show[55:48] <= clock/1000000+'d48;
            counter_show[47:40] <= (clock%1000000)/100000+'d48;
            counter_show[39:32] <= (clock%100000)/10000+'d48;
            counter_show[31:24] <= (clock%10000)/1000+'d48;
            counter_show[23:16] <= (clock%1000)/100+'d48;
            counter_show[15:8] <= (clock%100)/10+'d48;
            counter_show[7:0] <= (clock%10)+'d48;
            
        end
        else if(counter<='d100000)begin
            counter <= counter+'d1;
        end
    end
end

assign     ans_out[63:56] = passwd_try/10000000+'d48;
assign     ans_out[55:48] = (passwd_try%10000000)/1000000+'d48;
assign     ans_out[47:40] = (passwd_try%1000000)/100000+'d48;
assign     ans_out[39:32] = (passwd_try%100000)/10000+'d48;
assign     ans_out[31:24] = (passwd_try%10000)/1000+'d48;
assign     ans_out[23:16] = (passwd_try%1000)/100+'d48;
assign     ans_out[15:8] = (passwd_try%100)/10+'d48;
assign     ans_out[7:0] = (passwd_try%10)+'d48;

// ------------------------------------------------------------------------
// LCD Display function.
always @(posedge clk) begin
  if (~reset_n) begin
    row_A = "---HASH  INIT---";
    row_B = "---HASH -INIT---";
  end 
  else if(P == S_MAIN_IDLE)begin
    row_A = "---HASH  INIT---";
    //row_A = passwd_hash;
    //row_B = try[511:384];
    row_B = "Press BTN3------";
  end
  
  else if(P==S_MAIN_SHOW)begin
    //row_A = {"Find: ",ans_out};
    //row_A = { "show:",data_in};
    //row_B = data_out;
    row_B = {"Time: ",counter_show," ms"};
    //row_B = {data_out};
    row_A <= {"Passwd: ", answer[0], answer[1], answer[2], answer[3], answer[4], answer[5], answer[6], answer[7]};
  end
   else if(P==S_MAIN_CAL || P==S_MAIN_NEXT)begin
  //else if(P==S_MDF_ADD2||P==S_MDF_ADD2||P==S_MDF_DONE||P==S_MDF_INIT||P==S_MDF_READ||P==S_MDF_REPLY||P==S_MDF_REPLY2)begin
    
    //row_A = {"add",data_in};
    //row_B = {done_hash+'d48,"-",hash_result[31:0]};
    //row_A = passwd_hash;
    row_B = {"Time: ",counter_show," ms"};
    row_A <= {"Passwd: ", answer[0], answer[1], answer[2], answer[3], answer[4], answer[5], answer[6], answer[7]};
   // row_B = {data_out};
  end
end
// End of the LCD display function
// ------------------------------------------------------------------------

endmodule
