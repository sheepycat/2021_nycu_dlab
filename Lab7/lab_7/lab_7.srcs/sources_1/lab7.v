`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2018/11/01 11:16:50
// Design Name: 
// Module Name: lab6
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is a sample circuit to show you how to initialize an SRAM
//              with a pre-defined data file. Hit BTN0/BTN1 let you browse
//              through the data.
// 
// Dependencies: LCD_module, debounce
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab6(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,
  input  uart_rx,
  output uart_tx,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

localparam [2:0] S_MAIN_ADDR = 3'b000, S_MAIN_READ = 3'b001,
                 S_MAIN_SHOW = 3'b010, S_MAIN_WAIT = 3'b011,S_MAIN_READ_B = 3'b100,S_MAIN_COMPUTE = 3'b101;
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
localparam INIT_DELAY = 100_000; // 1 msec @ 100 MHz
localparam PROMPT_STR = 0;  // starting index of the prompt message
localparam PROMPT_LEN_A = 169; // length of the prompt message
localparam MEM_SIZE   = PROMPT_LEN_A;
// declare system variables
wire [1:0]  btn_level, btn_pressed;
reg  [1:0]  prev_btn_level;
reg  [2:0]  P, P_next;
reg  [1:0] Q, Q_next;
reg  [11:0] user_addr;
reg  [7:0]  user_data;
reg  [11:0] m_user_addr;
reg  [7:0]  m_user_data;
reg  [19:0] data_ans[0:15];
reg  [7:0]  A[0:15];
reg  [7:0]  B[0:15];
reg  [127:0] row_A, row_B;
reg [$clog2(MEM_SIZE):0] send_counter;
reg  [7:0] data[0:MEM_SIZE-1];
reg  [0:PROMPT_LEN_A*8-1] msg0 = {"\015\012The matrix multiplication result is:\015\012",
                                "[ 00000, 00000, 00000, 00000 ]\015\012",
                                "[ 00000, 00000, 00000, 00000 ]\015\012",
                                "[ 00000, 00000, 00000, 00000 ]\015\012",
                                "[ 00000, 00000, 00000, 00000 ]\015\012",8'h0 };
// declare SRAM control signals
wire [10:0] sram_addr;
wire [7:0]  data_in;
wire [7:0]  data_out;
wire        sram_we, sram_en;
wire [10:0] m_addr;
wire [7:0]  m_in;
wire [7:0]  m_out;
assign usr_led = 4'h00;
wire transmit;
wire received;
wire [7:0] rx_byte;
reg  [7:0] rx_temp;  // if recevied is true, rx_temp latches rx_byte for ONLY ONE CLOCK CYCLE!
wire [7:0] tx_byte;
wire [7:0] echo_key; // keystrokes to be echoed to the terminal
wire is_num_key;
wire is_receiving;
wire is_transmitting;
wire recv_error;
uart uart(
  .clk(clk),
  .rst(~reset_n),
  .rx(uart_rx),
  .tx(uart_tx),
  .transmit(transmit),
  .tx_byte(tx_byte),
  .received(received),
  .rx_byte(rx_byte),
  .is_receiving(is_receiving),
  .is_transmitting(is_transmitting),
  .recv_error(recv_error)
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
  
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[0]),
  .btn_output(btn_level[0])
);

debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level[1])
);

//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 2'b00;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level & ~prev_btn_level);

// ------------------------------------------------------------------------
// The following code creates an initialized SRAM memory block that
// stores an 1024x8-bit unsigned numbers.
sram ram0(.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));

assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However,
                             // if you set 'we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = (P == S_MAIN_ADDR || P == S_MAIN_READ); // Enable the SRAM block.
assign sram_addr = user_addr[11:0];
assign data_in = 8'b0; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------
sram ram1(.clk(clk), .we(sram_we), .en(sram_en),
          .addr(m_addr), .data_i(m_in), .data_o(m_out));
assign m_in = 8'b0;
assign m_addr = m_user_addr[11:0];
// ------------------------------------------------------------------------
integer idx;
integer j;
always @(posedge clk) begin
  if (~reset_n) begin
    for (idx = 0; idx < PROMPT_LEN_A; idx = idx + 1) data[idx] = msg0[idx*8 +: 8];
  end
  else if (P == S_MAIN_SHOW) begin
    /*for(idx= 0;idx<16;idx=idx+1)begin
    for(j=0;j<16;j=j+1)begin
        data[ 0+idx*32+j*2] <= ((A[idx][ 7: 4] > 9)? "7" : "0") + A[idx][ 7: 4];
        data[ 1+idx*32+j*2] <= ((A[idx][ 3: 0] > 9)? "7" : "0") +A[idx][ 3: 0];
        end
    end*/
    ////for test
    
  /* data[0]<=((A[0][ 7: 4] > 9)? "7" : "0") + A[0][ 7: 4];
    data[1]<=((A[0][ 3: 0] > 9)? "7" : "0") + A[0][ 3: 0];
    data[2]<=((A[1][ 7: 4] > 9)? "7" : "0") + A[1][ 7: 4];
    data[3]<=((A[1][ 3: 0] > 9)? "7" : "0") + A[1][ 3: 0];
    data[4]<=((A[2][ 7: 4] > 9)? "7" : "0") + A[2][ 7: 4];
    data[5]<=((A[2][ 3: 0] > 9)? "7" : "0") + A[2][ 3: 0];
    data[6]<=((A[3][ 7: 4] > 9)? "7" : "0") + A[3][ 7: 4];
    data[7]<=((A[3][ 3: 0] > 9)? "7" : "0") + A[3][ 3: 0];
    data[8]<=((A[4][ 7: 4] > 9)? "7" : "0") + A[4][ 7: 4];
    data[9]<=((A[4][ 3: 0] > 9)? "7" : "0") + A[4][ 3: 0];
    data[10]<=((A[5][ 7: 4] > 9)? "7" : "0") + A[5][ 7: 4];
    data[11]<=((A[5][ 3: 0] > 9)? "7" : "0") + A[5][ 3: 0];
    data[12]<=((A[6][ 7: 4] > 9)? "7" : "0") + A[6][ 7: 4];
    data[13]<=((A[6][ 3: 0] > 9)? "7" : "0") + A[6][ 3: 0];
    data[14]<=((A[7][ 7: 4] > 9)? "7" : "0") + A[7][ 7: 4];
    data[15]<=((A[7][ 3: 0] > 9)? "7" : "0") + A[7][ 3: 0];*/
   /*data[16]<=((A[8][ 7: 4] > 9)? "7" : "0") + A[8][ 7: 4];
    data[17]<=((A[8][ 3: 0] > 9)? "7" : "0") + A[8][ 3: 0];
    data[18]<=((A[9][ 7: 4] > 9)? "7" : "0") + A[9][ 7: 4];
    data[19]<=((A[9][ 3: 0] > 9)? "7" : "0") + A[9][ 3: 0];
    data[20]<=((A[10][ 7: 4] > 9)? "7" : "0") + A[10][ 7: 4];
    data[21]<=((A[10][ 3: 0] > 9)? "7" : "0") + A[10][ 3: 0];
    data[22]<=((A[11][ 7: 4] > 9)? "7" : "0") + A[11][ 7: 4];
    data[23]<=((A[11][ 3: 0] > 9)? "7" : "0") + A[11][ 3: 0];
    data[24]<=((A[12][ 7: 4] > 9)? "7" : "0") + A[12][ 7: 4];
    data[25]<=((A[12][ 3: 0] > 9)? "7" : "0") + A[12][ 3: 0];
    data[26]<=((A[13][ 7: 4] > 9)? "7" : "0") + A[13][ 7: 4];
    data[27]<=((A[13][ 3: 0] > 9)? "7" : "0") + A[13][ 3: 0];
    data[28]<=((A[14][ 7: 4] > 9)? "7" : "0") + A[14][ 7: 4];
    data[29]<=((A[14][ 3: 0] > 9)? "7" : "0") + A[14][ 3: 0];
    data[30]<=((A[15][ 7: 4] > 9)? "7" : "0") + A[15][ 7: 4];
    data[31]<=((A[15][ 3: 0] > 9)? "7" : "0") + A[15][ 3: 0];*/
   /* data[0]<=((B[0][ 7: 4] > 9)? "7" : "0") + B[0][ 7: 4];
    data[1]<=((B[0][ 3: 0] > 9)? "7" : "0") + B[0][ 3: 0];
    data[2]<=((B[1][ 7: 4] > 9)? "7" : "0") + B[1][ 7: 4];
    data[3]<=((B[1][ 3: 0] > 9)? "7" : "0") + B[1][ 3: 0];
    data[4]<=((B[2][ 7: 4] > 9)? "7" : "0") + B[2][ 7: 4];
    data[5]<=((B[2][ 3: 0] > 9)? "7" : "0") + B[2][ 3: 0];
    data[6]<=((B[3][ 7: 4] > 9)? "7" : "0") + B[3][ 7: 4];
    data[7]<=((B[3][ 3: 0] > 9)? "7" : "0") + B[3][ 3: 0];
    data[8]<=((B[4][ 7: 4] > 9)? "7" : "0") + B[4][ 7: 4];
    data[9]<=((B[4][ 3: 0] > 9)? "7" : "0") + B[4][ 3: 0];
    data[10]<=((B[5][ 7: 4] > 9)? "7" : "0") + B[5][ 7: 4];
    data[11]<=((B[5][ 3: 0] > 9)? "7" : "0") + B[5][ 3: 0];
    data[12]<=((B[6][ 7: 4] > 9)? "7" : "0") + B[6][ 7: 4];
    data[13]<=((B[6][ 3: 0] > 9)? "7" : "0") + B[6][ 3: 0];
    data[14]<=((B[7][ 7: 4] > 9)? "7" : "0") + B[7][ 7: 4];
    data[15]<=((B[7][ 3: 0] > 9)? "7" : "0") + B[7][ 3: 0];*/
   /* data[16]<=((B[8][ 7: 4] > 9)? "7" : "0") + B[8][ 7: 4];
    data[17]<=((B[8][ 3: 0] > 9)? "7" : "0") + B[8][ 3: 0];
    data[18]<=((B[9][ 7: 4] > 9)? "7" : "0") + B[9][ 7: 4];
    data[19]<=((B[9][ 3: 0] > 9)? "7" : "0") + B[9][ 3: 0];
    data[20]<=((B[10][ 7: 4] > 9)? "7" : "0") + B[10][ 7: 4];
    data[21]<=((B[10][ 3: 0] > 9)? "7" : "0") + B[10][ 3: 0];
    data[22]<=((B[11][ 7: 4] > 9)? "7" : "0") + B[11][ 7: 4];
    data[23]<=((B[11][ 3: 0] > 9)? "7" : "0") + B[11][ 3: 0];
    data[24]<=((B[12][ 7: 4] > 9)? "7" : "0") + B[12][ 7: 4];
    data[25]<=((B[12][ 3: 0] > 9)? "7" : "0") + B[12][ 3: 0];
    data[26]<=((B[13][ 7: 4] > 9)? "7" : "0") + B[13][ 7: 4];
    data[27]<=((B[13][ 3: 0] > 9)? "7" : "0") + B[13][ 3: 0];
    data[28]<=((B[14][ 7: 4] > 9)? "7" : "0") + B[14][ 7: 4];
    data[29]<=((B[14][ 3: 0] > 9)? "7" : "0") + B[14][ 3: 0];
    data[30]<=((B[15][ 7: 4] > 9)? "7" : "0") + B[15][ 7: 4];
    data[31]<=((B[15][ 3: 0] > 9)? "7" : "0") + B[15][ 3: 0];*/
  /* data[0]<=((data_ans[13][ 19: 16] > 9)? "7" : "0") + data_ans[13][ 19: 16];
   data[1]<=((data_ans[13][ 15: 12] > 9)? "7" : "0") + data_ans[13][ 15: 12];
   data[2]<=((data_ans[13][ 11: 8] > 9)? "7" : "0") + data_ans[13][ 11: 8];
   data[3]<=((data_ans[13][ 7: 4] > 9)? "7" : "0") + data_ans[13][ 7: 4];
   data[4]<=((data_ans[13][ 3: 0] > 9)? "7" : "0") + data_ans[13][ 3: 0];
   data[5]<=((data_ans[14][ 19: 16] > 9)? "7" : "0") + data_ans[14][ 19: 16];
   data[6]<=((data_ans[14][ 15: 12] > 9)? "7" : "0") + data_ans[14][ 15: 12];
   data[7]<=((data_ans[14][ 11: 8] > 9)? "7" : "0") + data_ans[14][ 11: 8];
   data[8]<=((data_ans[14][ 7: 4] > 9)? "7" : "0") + data_ans[14][ 7: 4];
   data[9]<=((data_ans[14][ 3: 0] > 9)? "7" : "0") + data_ans[14][ 3: 0];
   data[10]<=((data_ans[15][ 19: 16] > 9)? "7" : "0") + data_ans[15][ 19: 16];
   data[11]<=((data_ans[15][ 15: 12] > 9)? "7" : "0") + data_ans[15][ 15: 12];
   data[12]<=((data_ans[15][ 11: 8] > 9)? "7" : "0") + data_ans[15][ 11: 8];
   data[13]<=((data_ans[15][ 7: 4] > 9)? "7" : "0") + data_ans[15][ 7: 4];
   data[14]<=((data_ans[15][ 3: 0] > 9)? "7" : "0") + data_ans[15][ 3: 0];*/
        
    for(idx = 0;idx<4;idx=idx+1)begin
        for(j=0;j<4;j=j+1)begin
            data[42+j*7+idx*32] <= ((data_ans[idx+4*j][ 19: 16] > 9)? "7" : "0") + data_ans[idx+4*j][ 19: 16];
            data[43+j*7+idx*32] <= ((data_ans[idx+4*j][ 15: 12] > 9)? "7" : "0") + data_ans[idx+4*j][ 15: 12];
            data[44+j*7+idx*32] <= ((data_ans[idx+4*j][ 11: 8] > 9)? "7" : "0") + data_ans[idx+4*j][ 11: 8];
            data[45+j*7+idx*32] <= ((data_ans[idx+4*j][ 7: 4] > 9)? "7" : "0") + data_ans[idx+4*j][ 7: 4];
            data[46+j*7+idx*32] <= ((data_ans[idx+4*j][ 3: 0] > 9)? "7" : "0") + data_ans[idx+4*j][ 3: 0];
        end
    end
  end
  end

/////////////
// FSM of the main controller
always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_ADDR; // read samples at 000 first
  end
  else begin
    P <= P_next;
  end
end
wire read_finished;
wire com_finished;
always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_ADDR: // send an address to the SRAM 
      P_next = S_MAIN_READ;
    S_MAIN_READ: // fetch the sample from the SRAM
    if(read_finished) P_next = S_MAIN_COMPUTE;
    else P_next = S_MAIN_READ;
    S_MAIN_COMPUTE:
    if(com_finished)P_next = S_MAIN_SHOW;
    else P_next = S_MAIN_COMPUTE;
    S_MAIN_SHOW:
    if(print_done) P_next = S_MAIN_WAIT;
      else P_next = S_MAIN_SHOW;
    S_MAIN_WAIT: // wait for a button click
      if (| btn_pressed == 1) P_next = S_MAIN_ADDR;
      else P_next = S_MAIN_WAIT;
  endcase
end

// FSM ouput logic: Fetch the data bus of sram[] for display
always @(posedge clk) begin
  if (~reset_n) user_data <= 8'b0;
  else if (sram_en && !sram_we) user_data <= data_out;
end
always @(posedge clk) begin
  if (~reset_n) m_user_data <= 8'b0;
  else if (sram_en && !sram_we) m_user_data <= m_out;
end
// End of the main controller
// ------------------------------------------------------------------------
reg [7:0]read_counter;
//reg [4:0]com;
wire [4:0]com;
reg [3:0]com_counter;

assign com = com_counter+com_counter+com_counter+com_counter;
always @(posedge clk) begin
    if(~reset_n)begin
        m_user_addr <=0;
        read_counter<=0;
       // com<=0;
        com_counter<=0;
    end
    if(P==S_MAIN_READ)begin
    if (read_counter%2==1) m_user_addr = (m_user_addr < 2048)? m_user_addr + 1 : m_user_addr; 
    else begin
        if(read_counter<33) A[m_user_addr-1] = m_user_data;
        else B[m_user_addr-17] = m_user_data;
    end
    read_counter<=read_counter+1;
    end
    if(P==S_MAIN_COMPUTE)begin
        m_user_addr<=0;
        read_counter <=0;
      if(com_counter<4)begin
    data_ans[com]  <= B[com]*A[0]+B[com+1]*A[4]+B[com+2]*A[8]+B[com+3]*A[12];
       data_ans[com+1]<= B[com]*A[1]+B[com+1]*A[5]+B[com+2]*A[9]+B[com+3]*A[13];
       data_ans[com+2]<= B[com]*A[2]+B[com+1]*A[6]+B[com+2]*A[10]+B[com+3]*A[14];
       data_ans[com+3]<= B[com]*A[3]+B[com+1]*A[7]+B[com+2]*A[11]+B[com+3]*A[15];
     
       end
       com_counter <= com_counter+1;
    end
    if(P==S_MAIN_SHOW) com_counter<=0;
end
assign com_finished = (com_counter==4)? 1:0;
//assign read_finished = 1;
assign read_finished = (read_counter>=64)? 1:0;
// ------------------------------------------------------------------------
// The following code updates the 1602 LCD text messages.
always @(posedge clk) begin
  if (~reset_n) begin
    row_A <= "Data at [0x---] ";
  end
  else if (P == S_MAIN_SHOW) begin
    row_A[39:32] <= ((user_addr[11:08] > 9)? "7" : "0") + user_addr[11:08];
    row_A[31:24] <= ((user_addr[07:04] > 9)? "7" : "0") + user_addr[07:04];
    row_A[23:16] <= ((user_addr[03:00] > 9)? "7" : "0") + user_addr[03:00];
  end
end
reg [6:0]temp_counter=0;
always @(posedge clk) begin
  if (~reset_n) begin
    row_B <= "is equal to 0x--";
  end
  else if (P == S_MAIN_SHOW) begin
    row_B[15:08] <= ((user_data[7:4] > 9)? "7" : "0") + user_data[7:4];
    row_B[07: 0] <= ((user_data[3:0] > 9)? "7" : "0") + user_data[3:0];
  end
end
// End of the 1602 LCD text-updating code.
// ------------------------------------------------------------------------
/*if(temp_counter<16)begin
  row_B[15:08] <= ((A[temp_counter][7:4] > 9)? "7" : "0") + A[temp_counter][7:4];
  row_B[07: 0] <= ((A[temp_counter][3:0] > 9)? "7" : "0") + A[temp_counter][3:0];
  end
  else if(temp_counter<32)begin
  row_B[15:08] <= ((B[temp_counter-16][7:4] > 9)? "7" : "0") + B[temp_counter-16][7:4];
  row_B[07: 0] <= ((B[temp_counter-16][3:0] > 9)? "7" : "0") + B[temp_counter-16][3:0];
  end*/
// ------------------------------------------------------------------------
// The circuit block that processes the user's button event.
always @(posedge clk) begin
  if (~reset_n)begin
    user_addr <= 12'h000;
 
  end
  else if (btn_pressed[1])
    user_addr <= (user_addr < 2048)? user_addr + 1 : user_addr;

  else if (btn_pressed[0])
    user_addr <= (user_addr > 0)? user_addr - 1 : user_addr;
end
// End of the user's button control.
// ------------------------------------------------------------------------
assign print_enable = ( P == S_MAIN_COMPUTE && P_next == S_MAIN_SHOW) ;//«Ý½T»{
assign print_done = (tx_byte == 8'h0);

always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h0) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end

assign transmit = (Q_next == S_UART_WAIT || print_enable);
assign tx_byte  =  data[send_counter];
always @(posedge clk) begin
  case (P_next)
    S_MAIN_ADDR: send_counter <= PROMPT_STR;
    default: send_counter <= send_counter + (Q_next == S_UART_INCR);
  endcase
end
always @(posedge clk) begin
  rx_temp <= (received)? rx_byte : 8'h0;
end
endmodule
