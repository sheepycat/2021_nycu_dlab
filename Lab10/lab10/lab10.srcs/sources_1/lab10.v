`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai 
// 
// Create Date: 2018/12/11 16:04:41
// Design Name: 
// Module Name: lab9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: A circuit that show the animation of a fish swimming in a seabed
//              scene on a screen through the VGA interface of the Arty I/O card.
// 
// Dependencies: vga_sync, clk_divider, sram 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab10(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,//水平同步信號
    output VGA_VSYNC,//垂直同步信號
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    
    );


// Declare system variables
reg  [31:0] fish_clock;
reg  [31:0] fish_clock2;
reg  [31:0] fish_clock3;
reg  [31:0] fish_clock4;
reg  [31:0] fish_clock5;
reg  [31:0] fish_clock6;
reg  [31:0] d_clock;
reg  [31:0] d_clock2;
wire [9:0]  pos;
wire [9:0]  pos2;
wire [9:0]  pos3;
wire [9:0]  pos4;
wire [9:0]  pos5;
wire [9:0]  pos6;
wire [9:0]  posd;
wire [9:0]  posd2;
wire        fish_region;
wire        fish_region2;
wire        fish_region3;
wire        fish_region4;
wire        fish_region5;
wire        fish_region6;
wire        d_region;
wire        d_region2;
// declare SRAM control signals
wire [16:0] sram_addr_d;
wire [16:0] sram_addr_f2;
wire [16:0] sram_addr_f3;
wire [16:0] sram_addr_f1;
wire [16:0] sram_addr;
wire [11:0] data_in;
wire [11:0] data_out;
wire [11:0] data_out_f1;
wire [11:0] data_out_f2;
wire [11:0] data_out_f3;
wire [11:0] data_out_d;
wire        sram_we, sram_en;

localparam [2:0] S_MAIN_INIT = 3'b000, S_MAIN_00 = 3'b001,
                 S_MAIN_01 = 3'b010, S_MAIN_02 = 3'b011,
                 S_MAIN_03 = 3'b100, S_MAIN_SHOW = 3'b101,
                 S_MAIN_CAL = 3'b110;
          
wire btn_level0, btn_pressed0;
reg  prev_btn_level0;      

debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[0]),
  .btn_output(btn_level0)
);
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level0 <= 0;
  else
    prev_btn_level0 <= btn_level0;
end
assign btn_pressed0 = (btn_level0 == 1 && prev_btn_level0 == 0)? 1 : 0;
wire btn_level1, btn_pressed1;
reg  prev_btn_level1;      

debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level1)
);
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level1 <= 0;
  else
    prev_btn_level1 <= btn_level1;
end
assign btn_pressed1 = (btn_level1 == 1 && prev_btn_level1 == 0)? 1 : 0;
reg  [2:0] P, P_next;
// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
// one vga clk one pixel
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel
  
// Application-specific VGA signals
reg  [17:0] pixel_addr;
reg  [17:0] pixel_addr1;
reg  [17:0] pixel_addr2;
reg  [17:0] pixel_addr3;
reg  [17:0] pixel_addr_b;
reg  [17:0] pixel_addr_d;

// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height 
//1 pixel -> 4 pixel 

// Set parameters for the fish images
localparam D_VPOS2   = 100;
localparam D_VPOS   = 150;
localparam FISH_VPOS6   = 82;
localparam FISH_VPOS4   = 10;
localparam FISH_VPOS5   = 160;
localparam FISH_VPOS2   = 75; // Vertical location of the fish in the sea image.
localparam FISH_VPOS3   = 160; // Vertical location of the fish in the sea image.
localparam FISH_VPOS   = 64; // Vertical location of the fish in the sea image.
localparam FISH_W      = 64; // Width of the fish.
localparam FISH_H      = 32; // Height of the fish.
localparam FISH_W2      = 64; // Width of the fish.
localparam FISH_H2      = 44; // Height of the fish.
localparam FISH_W3      = 64; // Width of the fish.
localparam FISH_H3      = 72; // Height of the fish.
localparam D_W      = 64; // Width of the fish.
localparam D_H      = 32; // Height of the fish.
reg [17:0] fish_addr[0:2];   // Address array for up to 8 fish images.
reg [17:0] fish_addr2[0:2];   // Address array for up to 8 fish images.
reg [17:0] fish_addr3[0:2];   // Address array for up to 8 fish images.
reg [17:0] d_addr[0:2];   // Address array for up to 8 fish images.
// Initializes the fish images starting addresses.
// Note: System Verilog has an easier way to initialize an array,
//       but we are using Verilog 2001 :(
initial begin
  fish_addr[0] =  18'd0;         /* Addr for fish image #1 */
  fish_addr[1] =  FISH_W*FISH_H; /* Addr for fish image #2 */
  fish_addr[2] =  FISH_W*FISH_H*2; /* Addr for fish image #2 */
  fish_addr[3] =  FISH_W*FISH_H*3; /* Addr for fish image #2 */
  fish_addr[4] =  FISH_W*FISH_H*4; /* Addr for fish image #2 */
  fish_addr[5] =  FISH_W*FISH_H*5; /* Addr for fish image #2 */
  fish_addr[6] =  FISH_W*FISH_H*6; /* Addr for fish image #2 */
  fish_addr[7] =  FISH_W*FISH_H*7; /* Addr for fish image #2 */
end
initial begin
  fish_addr2[0] =  'd0;         /* Addr for fish image #1 */
  fish_addr2[1] =  FISH_W2*FISH_H2; /* Addr for fish image #2 */
  fish_addr2[2] =  FISH_W2*FISH_H2*2; /* Addr for fish image #2 */
  fish_addr2[3] =  FISH_W2*FISH_H2*3; /* Addr for fish image #2 */
end
initial begin
  fish_addr3[0] =  'd0;         /* Addr for fish image #1 */
  fish_addr3[1] =  FISH_W3*FISH_H3; /* Addr for fish image #2 */
  fish_addr3[2] =  FISH_W3*FISH_H3*2; /* Addr for fish image #2 */
  fish_addr3[3] =  FISH_W3*FISH_H3*3; /* Addr for fish image #2 */
end
initial begin
  d_addr[0] =  'd0;         /* Addr for fish image #1 */
  d_addr[1] =  D_W*D_H; /* Addr for fish image #2 */
end
// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);

// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H))// now: background + fish*2 
 ram0 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));
sramf1 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W*FISH_H*8))// now: background + fish*2 
 ram1 (.clk(clk), .we(sram_we), .en(sram_en),
         .addr(sram_addr_f1), .data_i(data_in), .data_o(data_out_f1));
 sramf2 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W2*FISH_H2*4))// now: background + fish*2 
 ram2 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_f2), .data_i(data_in), .data_o(data_out_f2));
sramf3 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W3*FISH_H3*4))// now: background + fish*2 
 ram3 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_f3), .data_i(data_in), .data_o(data_out_f3));
sramd #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(D_W*D_H))// now: background + fish*2 
 ram4 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_d), .data_i(data_in), .data_o(data_out_d));

assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.                            
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr = (fish_region || fish_region2 || fish_region3 || fish_region4 || fish_region5 || d_region || d_region2)?pixel_addr_b:pixel_addr;
assign sram_addr_f1 = pixel_addr1;
assign sram_addr_f2 = pixel_addr2;
assign sram_addr_f3 = pixel_addr3;
assign sram_addr_d = pixel_addr_d;
assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------
reg [11:0]temp_rgb;
// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = temp_rgb;

always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_INIT;
  end
  else begin
    P <= P_next;
  end
end
reg [2:0]color;
always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT:begin // wait for SD card initialization
    color<=0;
      if (btn_pressed0 == 1) P_next = S_MAIN_01;
      else if(btn_pressed1 ==1) P_next = S_MAIN_SHOW;
      else P_next = S_MAIN_INIT;
      end
    S_MAIN_01: begin// wait for button click
     color<=1;
      if (btn_pressed0 == 1) P_next = S_MAIN_02;
       else if(btn_pressed1 ==1) P_next = S_MAIN_SHOW;
      else P_next = S_MAIN_01;
      end
    S_MAIN_02:  begin// wait for button click
     color<=2;
      if (btn_pressed0 == 1) P_next = S_MAIN_00;
       else if(btn_pressed1 ==1) P_next = S_MAIN_SHOW;
      else P_next = S_MAIN_02;
      end
    S_MAIN_00:  begin// wait for button click
     color<=3;// issue a rd_req to the SD controller until it's ready
      if (btn_pressed0 == 1) P_next = S_MAIN_03;
       else if(btn_pressed1 ==1) P_next = S_MAIN_SHOW;
      else P_next = S_MAIN_00;
      end
    S_MAIN_03: begin// wait for button click
     color<=4;
      if (btn_pressed0 == 1) P_next = S_MAIN_CAL;
       else if(btn_pressed1 ==1) P_next = S_MAIN_SHOW;
      else P_next = S_MAIN_03;
      end
    S_MAIN_SHOW:
      if(btn_pressed1 ==1) P_next = S_MAIN_INIT;
      else P_next = S_MAIN_SHOW;
    S_MAIN_CAL: begin// wait for button click
     color<=5;
      if(btn_pressed0 ==1) P_next = S_MAIN_INIT;
      else if(btn_pressed1 ==1) P_next = S_MAIN_SHOW;
      else P_next = S_MAIN_CAL;
      end
    default:
      P_next = S_MAIN_INIT;
  endcase
end
reg [31:0] x;
reg [3:0]a,b,c;
always @(posedge clk)begin
  if (~reset_n || P==S_MAIN_INIT || P==S_MAIN_SHOW) begin
    temp_rgb <=rgb_reg;
    x<=0;
  end
  else if(P==S_MAIN_01)
    temp_rgb <={rgb_reg[3:0],rgb_reg[11:8],rgb_reg[7:4]};
  else if(P==S_MAIN_02)
    temp_rgb <={rgb_reg[7:4],rgb_reg[3:0],rgb_reg[11:8]};
  else if(P==S_MAIN_00)begin
    a<= rgb_reg[3:0]/2 ; b<= rgb_reg[7:4]/2 ; c <= rgb_reg[11:8]/2;
    temp_rgb = {c,b,a};
    end
  else if(P==S_MAIN_03)begin
    a<= rgb_reg[3:0]*2 ; b<= rgb_reg[7:4]*2 ; c <= rgb_reg[11:8]*2;
    temp_rgb = {c,b,a};
    end
  else if(P==S_MAIN_CAL)begin
    if(x[31:24]%9==0) temp_rgb <={rgb_reg[3:0],rgb_reg[11:8],rgb_reg[7:4]};
    else if (x[31:24]%9==1) temp_rgb <={rgb_reg[11:8],4'b0,4'b0};
    else if (x[31:24]%9==2) temp_rgb <={rgb_reg[7:4],rgb_reg[3:0],rgb_reg[11:8]};
    else if (x[31:24]%9==3) temp_rgb <={rgb_reg[3:0],rgb_reg[7:4],rgb_reg[11:8]};
    else if (x[31:24]%9==4) temp_rgb <={4'b0,rgb_reg[7:4],4'b0};
    else if (x[31:24]%9==5) temp_rgb <={rgb_reg[7:4],rgb_reg[11:8],rgb_reg[3:0]};
    else if (x[31:24]%9==6) temp_rgb <={rgb_reg[11:8],rgb_reg[3:0],rgb_reg[7:4]};
    else if (x[31:24]%9==7) temp_rgb <={4'b0,4'b0,rgb_reg[3:0]};
    else if (x[31:24]%9==8) temp_rgb <={rgb_reg[3:0],4'b1,rgb_reg[11:8]};
    x<=x+1;
  end
  if(x>=1000000000) x<=0;
end
// ------------------------------------------------------------------------
// An animation clock for the motion of the fish, upper bits of the
// fish clock is the x position of the fish on the VGA screen.
// Note that the fish will move one screen pixel every 2^20 clock cycles,
// or 10.49 msec
assign posd2 =(P==S_MAIN_CAL)?d_clock2[31:20]*6:d_clock2[31:20]*3;
assign posd = (P==S_MAIN_CAL)? (2*VBUF_W - d_clock[31:20]+D_W*4)*2:d_clock[31:20]*2;
assign pos6 = (P==S_MAIN_CAL)?fish_clock6[31:21]*9:fish_clock6[31:21]*3;
assign pos5 = fish_clock5[31:20]*3;
assign pos4 = (P==S_MAIN_CAL)? fish_clock4[31:20]*2:(2*VBUF_W - fish_clock4[31:20]+FISH_W3*4)*2;
assign pos2 = (P==S_MAIN_CAL)?2*VBUF_W - fish_clock2[31:20]+FISH_W3*2:fish_clock2[31:20]*2;
assign pos3 = 2*VBUF_W - fish_clock3[31:20]+FISH_W3*2;
assign pos = (P==S_MAIN_CAL)?2*VBUF_W - fish_clock[31:20]+FISH_W3*2:fish_clock[31:20]; // the x position of the right edge of the fish image
                       // in the 640x480 VGA screen
always @(posedge clk) begin
  if (~reset_n || d_clock2[31:21] > VBUF_W + D_W*3)// fish counter(location)
    d_clock2 <= 0;
  else if(P == S_MAIN_SHOW) d_clock2 <= d_clock2;
  else
    d_clock2 <= d_clock2 + 1;
end
always @(posedge clk) begin
  if (~reset_n || d_clock[31:21] > VBUF_W + D_W*2)// fish counter(location)
    d_clock <= 0;
  else if(P == S_MAIN_SHOW) d_clock <= d_clock;
  else
   d_clock <= d_clock + 1;
end
always @(posedge clk) begin
  if (~reset_n || fish_clock[31:21] > VBUF_W + FISH_W)// fish counter(location)
    fish_clock <= 0;
  else if(P == S_MAIN_SHOW) fish_clock <= fish_clock;
  else
    fish_clock <= fish_clock + 1;
end
always @(posedge clk) begin
  if (~reset_n || fish_clock2[31:21] > VBUF_W + FISH_W2*2)// fish counter(location)
    fish_clock2 <= 0;
  else if(P == S_MAIN_SHOW) fish_clock2 <= fish_clock2;
  else
    fish_clock2 <= fish_clock2 + 1;
end
always @(posedge clk) begin
  if (~reset_n || fish_clock3[31:21] > VBUF_W + FISH_W3 )// fish counter(location)
    fish_clock3 <= 0;
  else if(P == S_MAIN_SHOW) fish_clock3 <= fish_clock3;
  else
    fish_clock3 <= fish_clock3 + 1;
end
always @(posedge clk) begin
  if (~reset_n || fish_clock4[31:21] > VBUF_W + FISH_W3*2 )// fish counter(location)
    fish_clock4 <= 0;
  else if(P == S_MAIN_SHOW) fish_clock4 <= fish_clock4;
  else
    fish_clock4 <= fish_clock4 + 1;
end
always @(posedge clk) begin
  if (~reset_n || fish_clock5[31:21] > VBUF_W + FISH_W*3 )// fish counter(location)
    fish_clock5 <= 0;
  else if(P == S_MAIN_SHOW) fish_clock5 <= fish_clock5;
  else
    fish_clock5 <= fish_clock5 + 1;
end
always @(posedge clk) begin
  if (~reset_n || fish_clock6[31:21] > (VBUF_W/4)*3 + FISH_W3)// fish counter(location)
    fish_clock6 <= 0;
  else if(P == S_MAIN_SHOW) fish_clock6 <= fish_clock6;
  else
    fish_clock6 <= fish_clock6 + 1;
end
// End of the animation clock code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the fish image is 64x32, when scaled-up
// on the screen, it becomes 128x64. 'pos' specifies the right edge of the
// fish image.
assign fish_region6 =// show-> pixel in fish
           pixel_y >= (FISH_VPOS6<<1) && pixel_y < (FISH_VPOS6+FISH_H3)<<1 &&
           (pixel_x + 127) >= pos6 && pixel_x < pos6 + 1;
assign fish_region4 =// show-> pixel in fish
           pixel_y >= (FISH_VPOS4<<1) && pixel_y < (FISH_VPOS4+FISH_H3)<<1 &&
           (pixel_x + 127) >= pos4 && pixel_x < pos4 + 1;
assign fish_region5 =// show-> pixel in fish
           pixel_y >= (FISH_VPOS5<<1) && pixel_y < (FISH_VPOS5+FISH_H)<<1 &&
           (pixel_x + 127) >= pos5 && pixel_x < pos5 + 1;
assign fish_region2 =// show-> pixel in fish
           pixel_y >= (FISH_VPOS2<<1) && pixel_y < (FISH_VPOS2+FISH_H2)<<1 &&
           (pixel_x + 127) >= pos2 && pixel_x < pos2 + 1;
assign fish_region3 =// show-> pixel in fish
           pixel_y >= (FISH_VPOS3<<1) && pixel_y < (FISH_VPOS3+FISH_H3)<<1 &&
           (pixel_x + 127) >= pos3 && pixel_x < pos3 +1;
assign fish_region =// show-> pixel in fish
           pixel_y >= (FISH_VPOS<<1) && pixel_y < (FISH_VPOS+FISH_H)<<1 &&
           (pixel_x + 127) >= pos && pixel_x < pos + 1;
assign d_region =// show-> pixel in fish
           pixel_y >= (D_VPOS<<1) && pixel_y < (D_VPOS+D_H)<<1 &&
           (pixel_x + 127) >= posd && pixel_x < posd + 1;
assign d_region2 =// show-> pixel in fish
           pixel_y >= (D_VPOS2<<1) && pixel_y < (D_VPOS2+D_H)<<1 &&
           (pixel_x + 127) >= posd2 && pixel_x < posd2 + 1;
           

always @ (posedge clk) begin
  if (~reset_n)begin
    pixel_addr <= 0;
    pixel_addr2 <= 0;
    pixel_addr3 <= 0;
    pixel_addr_d <=0;
    pixel_addr_b <= 0;
    end
    if(fish_region)
     pixel_addr1 <= fish_addr[fish_clock[31:24]%8] +
                  ((pixel_y>>1)-FISH_VPOS)*FISH_W + //>>1 -> /2
                  ((pixel_x +(FISH_W*2-1)-pos)>>1);
    else if(fish_region5)
    pixel_addr1 <= fish_addr[fish_clock5[31:24]%8] +
                  ((pixel_y>>1)-FISH_VPOS5)*FISH_W + //>>1 -> /2
                  ((pixel_x +(FISH_W*2-1)-pos5)>>1);
                  
    pixel_addr2 <= fish_addr2[fish_clock2[31:24]%4] +
                  ((pixel_y>>1)-FISH_VPOS2)*FISH_W2 + //>>1 -> /2
                  ((pixel_x +(FISH_W2*2-1)-pos2)>>1);
    if(fish_region3)              
    pixel_addr3 <= fish_addr3[fish_clock3[31:24]%4] +
                  ((pixel_y>>1)-FISH_VPOS3)*FISH_W3 + //>>1 -> /2
                  ((pixel_x +(FISH_W3*2-1)-pos3)>>1);
    else if(fish_region4)              
    pixel_addr3 <= fish_addr3[fish_clock4[31:24]%4] +
                  ((pixel_y>>1)-FISH_VPOS4)*FISH_W3 + //>>1 -> /2
                  ((pixel_x +(FISH_W3*2-1)-pos4)>>1);
    else if(fish_region6)
    pixel_addr3 <= fish_addr3[fish_clock6[31:24]%4] +
                  ((pixel_y>>1)-FISH_VPOS6)*FISH_W3 + //>>1 -> /2
                  ((pos6-pixel_x)>>1);
     if(d_region) 
     pixel_addr_d<= d_addr[d_clock[31:26]%2] +
                  ((pixel_y>>1)-D_VPOS)*D_W + //>>1 -> /2
                  ((posd - pixel_x)>>1);
     else if(d_region2)
     pixel_addr_d<= d_addr[d_clock2[31:26]%2] +
                  ((pixel_y>>1)-D_VPOS2)*D_W + //>>1 -> /2
                  ((posd2 - pixel_x)>>1);
     pixel_addr <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
     pixel_addr_b <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
end
// End of the AGU code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else if((fish_region||fish_region5)&&data_out_f1!=12'h1f1)begin
        rgb_next = data_out_f1; // RGB value at (pixel_x, pixel_y)
        end
  else if(fish_region2&&data_out_f2!=12'h1f1)
        rgb_next = data_out_f2; // RGB value at (pixel_x, pixel_y)
  else if((fish_region3||fish_region4||fish_region6)&&data_out_f3!=12'h1f1)
        rgb_next = data_out_f3; // RGB value at (pixel_x, pixel_y)
  else if(((d_region||d_region2)&&data_out_d!=12'h1f1&&data_out_d!=12'h0f0))begin
        rgb_next = data_out_d; // RGB value at (pixel_x, pixel_y)
        end
  else
        rgb_next = data_out;
end
// End of the video data display code.
// ------------------------------------------------------------------------

endmodule
