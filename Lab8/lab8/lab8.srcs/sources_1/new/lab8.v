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

  // SD card specific I/O ports
  output spi_ss,
  output spi_sck,
  output spi_mosi,
  input  spi_miso,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

localparam [2:0] S_MAIN_INIT = 3'b000, S_MAIN_IDLE = 3'b001,
                 S_MAIN_WAIT = 3'b010, S_MAIN_READ = 3'b011,
                 S_MAIN_DONE = 3'b100, S_MAIN_SHOW = 3'b101,
                 S_MAIN_CAL = 3'b110;

// Declare system variables
wire btn_level, btn_pressed;
reg  prev_btn_level;
reg  [5:0] send_counter;
reg  [2:0] P, P_next;
reg  [9:0] sd_counter;
reg  [7:0] data_byte;
reg  [31:0] blk_addr;

reg  [127:0] row_A = "SD card cannot  ";
reg  [127:0] row_B = "be initialized! ";
reg  done_flag; // Signals the completion of reading one SD sector.

// Declare SD card interface signals
wire clk_sel;
wire clk_500k;
reg  rd_req;
reg  [31:0] rd_addr;
wire init_finished;
wire [7:0] sd_dout;
wire sd_valid;

// Declare the control/data signals of an SRAM memory block
wire [7:0] data_in;
wire [7:0] data_out;
wire [8:0] sram_addr;
wire       sram_we, sram_en;

assign clk_sel = (init_finished)? clk : clk_500k; // clock for the SD controller
assign usr_led = 4'h00;

clk_divider#(200) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(clk_500k)
);

debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[2]),
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

sd_card sd_card0(
  .cs(spi_ss),
  .sclk(spi_sck),
  .mosi(spi_mosi),
  .miso(spi_miso),

  .clk(clk_sel),
  .rst(~reset_n),
  .rd_req(rd_req),
  .block_addr(rd_addr),
  .init_finished(init_finished),
  .dout(sd_dout),
  .sd_valid(sd_valid)
);

sram ram0(
  .clk(clk),
  .we(sram_we),
  .en(sram_en),
  .addr(sram_addr),
  .data_i(data_in),
  .data_o(data_out)
);

//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;

// ------------------------------------------------------------------------
// The following code sets the control signals of an SRAM memory block
// that is connected to the data output port of the SD controller.
// Once the read request is made to the SD controller, 512 bytes of data
// will be sequentially read into the SRAM memory block, one byte per
// clock cycle (as long as the sd_valid signal is high).
assign sram_we = sd_valid;          // Write data into SRAM when sd_valid is high.
assign sram_en = 1;                 // Always enable the SRAM block.
assign data_in = sd_dout;           // Input data always comes from the SD controller.
assign sram_addr = sd_counter[8:0]; // Set the driver of the SRAM address signal.
// End of the SRAM memory block
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the SD card reader that reads the super block (512 bytes)
always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_INIT;
    done_flag <= 0;
    cal_in<=0;
  end
  else begin
    P <= P_next;
  end
end
reg cal_in;
always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: // wait for SD card initialization
      if (init_finished == 1) P_next = S_MAIN_IDLE;
      else P_next = S_MAIN_INIT;
    S_MAIN_IDLE: // wait for button click
      if (btn_pressed == 1) P_next = S_MAIN_WAIT;
      else P_next = S_MAIN_IDLE;
    S_MAIN_WAIT: // issue a rd_req to the SD controller until it's ready
         if(cal_in==1)P_next = S_MAIN_CAL;
         else P_next = S_MAIN_READ;
    S_MAIN_READ: // wait for the input data to enter the SRAM buffer
    if(in==1) P_next = S_MAIN_CAL;
    else begin
      if (sd_counter == 512) P_next = S_MAIN_WAIT;
      else P_next = S_MAIN_READ;
    end
    S_MAIN_CAL:begin
    cal_in<=1;
    if(dlab_cur_eight == "DLAB_END") P_next = S_MAIN_SHOW;
    else begin
      if (sd_counter == 512) P_next = S_MAIN_WAIT;
      else P_next = S_MAIN_CAL;
    end
    end
    S_MAIN_SHOW:
    P_next = S_MAIN_SHOW;
    default:
      P_next = S_MAIN_IDLE;
  endcase
end

// FSM output logic: controls the 'rd_req' and 'rd_addr' signals.
always @(*) begin
  rd_req = (P == S_MAIN_WAIT);
  rd_addr = blk_addr;
end

always @(posedge clk) begin
  if (~reset_n) blk_addr <= 32'h2000;
  else if(sd_counter == 512 )blk_addr <= blk_addr+1; // In lab 6, change this line to scan all blocks
  else blk_addr <= blk_addr;
end

// FSM output logic: controls the 'sd_counter' signal.
// SD card read address incrementer
always @(posedge clk) begin
  if (~reset_n || (P_next == S_MAIN_WAIT))
    sd_counter <= 0;
  else if ((P == S_MAIN_READ && sd_valid) ||
           (P == S_MAIN_CAL && sd_valid) ||
           (P == S_MAIN_DONE && P_next == S_MAIN_SHOW))
    sd_counter <= sd_counter + 1;
end

// FSM ouput logic: Retrieves the content of sram[] for display
always @(posedge clk) begin
  if (~reset_n) data_byte <= 8'b0;
  else if (sram_en && P == S_MAIN_DONE) data_byte <= data_out;
end
// End of the FSM of the SD card reader
// ------------------------------------------------------------------------
reg [63:0]a_tag;
reg [63:0]b_end;
reg [63:0]dlab_cur_eight = "qqqqqqqq";
reg [39:0]dlab_cur_five = 5'b0;
reg [3:0]letter_counter;
reg [16:0]char_counter;
wire check,done;
reg [1:0]in,out;
assign check = in;
assign done = out;
always @(posedge clk)begin
    if(~reset_n) begin
        dlab_cur_eight<="initial ";
        dlab_cur_five<="-----";
        a_tag <= "--------";
        b_end <= "--------";
        char_counter<=0;
        letter_counter<=0;
        in<=0;
        out<=0;
     end
     else if ((P == S_MAIN_READ && sd_valid) ||(P == S_MAIN_CAL && sd_valid))begin
        dlab_cur_eight <= dlab_cur_eight<<8;
        dlab_cur_eight[7:0] <= sd_dout;
        
    
     if( dlab_cur_eight == "DLAB_TAG")  begin
            a_tag <= dlab_cur_eight;
            in <=1;
     end
     if( dlab_cur_eight == "DLAB_END")  begin
            b_end <= dlab_cur_eight;
            out<=1;
     end
     if(P==S_MAIN_CAL)begin
         if((sd_dout>="A"&&sd_dout<="Z")||(sd_dout>="a"&&sd_dout<="z")) letter_counter<= letter_counter+1;
         else begin
            if(letter_counter==3) begin char_counter<=char_counter+1;end
           letter_counter<=0;
         end
     //char_counter <=char_counter+1;
     /*dlab_cur_five <= dlab_cur_five<<8;
     dlab_cur_five[7:0] <=sd_dout;
      if((dlab_cur_five[39:32]=='h20||dlab_cur_five[39:32]=='hA || dlab_cur_five[39:32]=="."||dlab_cur_five[39:32]==":"||dlab_cur_five[39:32]==","||dlab_cur_five[39:32]=="?"||dlab_cur_five[39:32]=="!"||dlab_cur_five[39:32]==";"||dlab_cur_five[39:32]=="'")&&
         (dlab_cur_five[7:0]=='h20||dlab_cur_five[7:0]=='hA || dlab_cur_five[7:0]=="."||dlab_cur_five[7:0]==":"||dlab_cur_five[7:0]==","||dlab_cur_five[7:0]=="?"||dlab_cur_five[7:0]=="!"||dlab_cur_five[7:0]==";"||dlab_cur_five[7:0]=="'"))begin
            if(((dlab_cur_five[31:24]>="A"&&dlab_cur_five[31:24]<="Z")||(dlab_cur_five[31:24]>="a"&&dlab_cur_five[31:24]<="z"))&&
                ((dlab_cur_five[23:16]>="A"&&dlab_cur_five[23:16]<="Z")||(dlab_cur_five[23:16]>="a"&&dlab_cur_five[23:16]<="z"))&&
                ((dlab_cur_five[15:8]>="A"&&dlab_cur_five[15:8]<="Z")||(dlab_cur_five[15:8]>="a"&&dlab_cur_five[15:8]<="z")))begin
                char_counter <= char_counter+1;
            end
        end
     end*/
     //row_B <= {a_tag,b_end};
     end
   end
end
// ------------------------------------------------------------------------
// LCD Display function.
always @(posedge clk) begin
  if (~reset_n) begin
    row_A = "SD card cannot  ";
   row_B = "be initialized! ";
  end 
  else if (P == S_MAIN_IDLE) begin
    row_A <= "Hit BTN2 to read";
   row_B <= "the SD card ... ";
  end

 /* else if (P == S_MAIN_READ)begin
   row_A <= {"R_",dlab_cur_eight,"_"};
        row_B <={   "r_",((char_counter[15:12] > 9)? "7" : "0") + char_counter[15:12],
                 ((char_counter[11:8] > 9)? "7" : "0") + char_counter[11:8],
                 ((char_counter[7:4] > 9)? "7" : "0") + char_counter[7:4],
               ((char_counter[3:0] > 9)? "7" : "0") + char_counter[3:0],"_"};
  end
  else if (P == S_MAIN_CAL)begin
   row_A <= {"C_",dlab_cur_eight,"_"};
        row_B <={   "c_",((char_counter[15:12] > 9)? "7" : "0") + char_counter[15:12],
                 ((char_counter[11:8] > 9)? "7" : "0") + char_counter[11:8],
                 ((char_counter[7:4] > 9)? "7" : "0") + char_counter[7:4],
               ((char_counter[3:0] > 9)? "7" : "0") + char_counter[3:0],"_"};
  end*/
  else if (P == S_MAIN_SHOW)begin
   row_A <={"Found ",((char_counter[15:12] > 9)? "7" : "0") + char_counter[15:12],
                 ((char_counter[11:8] > 9)? "7" : "0") + char_counter[11:8],
                 ((char_counter[7:4] > 9)? "7" : "0") + char_counter[7:4],
               ((char_counter[3:0] > 9)? "7" : "0") + char_counter[3:0]," words"};
     row_B <="in the text file";
   
  end/*
  else if(P==S_MAIN_WAIT)begin
    row_A <= {"W_",dlab_cur_eight,"_"};
    row_B = {a_tag,b_end};
  end
   else if(P==S_MAIN_DONE)begin
    row_A <= {"D_",dlab_cur_eight,"_"};
    row_B = {a_tag,b_end};
  end

  else  begin
    row_A <= {"A_",dlab_cur_eight,"_"};
    row_B <= { "Byte ",
               sd_counter[9:8] + "0",
               ((sd_counter[7:4] > 9)? "7" : "0") + sd_counter[7:4],
               ((sd_counter[3:0] > 9)? "7" : "0") + sd_counter[3:0],
               "h = ",
               ((data_byte[7:4] > 9)? "7" : "0") + data_byte[7:4],
               ((data_byte[3:0] > 9)? "7" : "0") + data_byte[3:0], "h." };
  end*/
  end
// End of the LCD display function
// ------------------------------------------------------------------------

endmodule
