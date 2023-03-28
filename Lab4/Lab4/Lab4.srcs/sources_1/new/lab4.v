`timescale 1ns / 1ps
module lab4(
  input  clk,            // System clock at 100 MHz
  input  reset_n,        // System reset signal, in negative logic
  input  [3:0] usr_btn,  // Four user pushbuttons
  output [3:0] usr_led   // Four yellow LEDs
);
reg [3:0] init;
reg [3:0] final=0;
reg signed [3:0] store=0;
reg [3:0] light_sign=0;//0~4
reg [30:0] counter=0;
integer cycle = 0;
integer accum = 0;
reg [1:0] cur_light = 0;

assign usr_led =final;
always @(posedge clk )begin
    if(!reset_n)begin
        counter <= 'd0;
        store<='d0;
        light_sign <='d0;
    end
     counter <= counter+1'd1; 
         if(usr_btn[0]==1 && counter>'d25000000) begin
              counter <=  'd0;
             if(store == -8) store <= -8;
             else if(store >-8) store <= store-1'd1;
         // store <= (store!=-8)? store-1:-8;
         end
         if(usr_btn[1]==1 && counter>'d25000000)  begin
             // store <= (store!=7)? store+1:7;
             counter <=  'd0;
             if(store == 7) store <= 7;
             else if(store < 7) store <= store+1'd1;
         end
          if(usr_btn[2]==1 && counter>'d25000000) begin//decrease
              counter <=  'd0;
              if(light_sign==0) light_sign <= 0;
              else if(light_sign>0) light_sign <= light_sign-1'd1;
         end
          if(usr_btn[3]==1 && counter>'d25000000) begin//increase
              counter <=  'd0;
              if(light_sign==4) light_sign <= 4;
              else if(light_sign<4) light_sign <= light_sign+1'd1;
         end
         case(light_sign)
            4'b0000: cycle <= 'd5;
            4'b0001: cycle <= 'd25;
            4'b0010: cycle <= 'd50;
            4'b0011: cycle <= 'd75;
            4'b0100: cycle <= 'd100;
         endcase
        if(accum=='d100) accum<='d0;
        else begin
            accum <= accum+'d1;
            if(accum<=cycle) cur_light <= 'd1;
            else if(accum>cycle) cur_light <= 'd0;
        end
        final[0] = (cur_light&&store[0]);
        final[1] = (cur_light&&store[1]);
        final[2] = (cur_light&&store[2]);
        final[3] = (cur_light&&store[3]);
           
    end


endmodule