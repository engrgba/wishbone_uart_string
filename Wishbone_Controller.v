`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:08:31 05/24/2024 
// Design Name: 
// Module Name:    Wishbone_Controller 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Wishbone_Controller(
        input wire  i_clk,
        input wire  i_rst,
		  input wire  push_button,
		  input wire i_uart_rx,
//wishbone signals
  

        output reg         o_wb_we,
        output reg         o_wb_cyc,
        output reg         o_wb_stb,
		  output reg  [3:0]  o_wb_sel,
        output reg  [1:0]  o_wb_addr,
        output reg  [31:0] o_wb_data ,
		  output	wire		   o_uart_tx
        );
//reg [8*9-1:0] string = "Gul Bahar";

wire [7:0]tx_byte[9:0];

/*	
assign		 tx_byte[8] = string[71:64];
assign		 tx_byte[7] = string[63:56];
assign		 tx_byte[6] = string[55:48];
assign		 tx_byte[5] = string[47:40];
assign		 tx_byte[4] = string[39:32];
assign		 tx_byte[3] = string[31:24];
assign		 tx_byte[2] = string[23:16];
assign		 tx_byte[1] = string[15:8];
assign		 tx_byte[0] = string[7:0];
*/
assign		 tx_byte[9] = "\n";
assign		 tx_byte[8] = "R";
assign		 tx_byte[7] = "A";
assign		 tx_byte[6] = "H";
assign		 tx_byte[5] = "A";
assign		 tx_byte[4] = "B";
assign		 tx_byte[3] = " ";
assign		 tx_byte[2] = "L";
assign		 tx_byte[1] = "U";
assign		 tx_byte[0] = "G";
	
wire 		   i_wb_ack;
wire [31:0] i_wb_data;

reg setup = 1'b0;
reg [25:0] t_a_time = 26'd0; 
reg [3:0]  location = 4'd0;

  wbuart wbu(
						.i_clk(i_clk),
						.i_reset(1'b0),
						.o_wb_ack(i_wb_ack),
						.o_wb_data(i_wb_data),
						.i_wb_we(o_wb_we),
						.i_wb_cyc(o_wb_cyc),
						.i_wb_stb(o_wb_stb),
						.i_wb_sel(o_wb_sel),
						.i_wb_addr(o_wb_addr),
						.i_wb_data(o_wb_data),
						.o_uart_tx(o_uart_tx)
						);

wire [35:0]CONTROL0;
						

						
localparam IDLE        			 	= 3'd0,//states
			  UART_SETUP   			= 3'd1,
			  Setup_wait            = 3'd2,
			  UART_TX               = 3'd3,
			  Turn_Around_time      = 3'd4,
			  Ack          			= 3'd5,
			  END                   = 3'd6;
		
reg [2:0]state = IDLE;
        always@(posedge i_clk)
        begin
        
       
		 case(state) 
		 IDLE: //0
						begin
							 o_wb_we    <= 1'b0; 
                      o_wb_stb   <= 1'b0;
                      o_wb_cyc   <= 1'b0;
							 o_wb_addr  <= 2'b00;
                      o_wb_data  <= 32'd0;
							 if(!push_button && !setup && (state == IDLE))
							 begin
									state      <= UART_SETUP;
									o_wb_we    <= 1'b1;
									o_wb_stb   <= 1'b1;
                           o_wb_cyc   <= 1'b1;
									t_a_time   <= 26'd0;
									o_wb_addr  <= 2'b00;
									o_wb_data  <= 32'd434;
							 end
							 else if(!push_button && setup && (state == IDLE))
							 begin
									state      <= UART_TX;
									location   <= 4'd0;
									//o_wb_we    <= 1'b1;
									//o_wb_stb   <= 1'b1;
                          // o_wb_cyc   <= 1'b1;
									//o_wb_addr  <= 2'b11; 
									//o_wb_data  <= tx_byte[location];
							 end
							 else state      <= IDLE;
						end
		 UART_SETUP://1
						begin
							 if(i_wb_ack)
							 begin
									o_wb_we    <= 1'b0;
									setup      <= 1'b1;
									o_wb_stb   <= 1'b0;
									o_wb_cyc   <= 1'b0;
									o_wb_addr  <= 2'b00;
									o_wb_data  <= 32'h00;
									state      <= Setup_wait;
									t_a_time   <= 26'd0;
								end
							  else state <= UART_SETUP;
							  
						end
		Setup_wait://2
					begin
							 if(t_a_time == 26'd50000000)
									begin
									 state    <= IDLE;
									 t_a_time <= 26'd0;
									end
									else   
									  begin
									  	t_a_time <= t_a_time+1;
										state    <= Setup_wait;
									  end
					end

		UART_TX://3
						begin
							 o_wb_we    <= 1'b1;
                      o_wb_stb   <= 1'b1;
                      o_wb_cyc   <= 1'b1;
                      o_wb_addr  <= 2'b11;
                      o_wb_data  <= tx_byte[location];
							 o_wb_sel   <= 4'b1111;
							 state      <= Ack;
							 location   <= location +1;
						end
						
		Turn_Around_time://4
						begin
							if(t_a_time == 26'd50000)
								begin
									 t_a_time <= 26'd0;
									 if(location < 4'd10)
										begin
											  state    <= UART_TX;
											  
									   end
										else 
										   begin
												 location  <= 4'd0;
												  state    <= END;
												  t_a_time <= 0;
											end
									 
								end
							else   
								begin
											t_a_time <= t_a_time+1;
											 state   <= Turn_Around_time;
								end
						end
		Ack://5
						begin
							o_wb_stb   <= 1'b0;
							 if(i_wb_ack)  
								begin
									
							      o_wb_we      <= 1'b0;
									o_wb_cyc     <= 1'b0;
									o_wb_stb     <= 1'b0;
									o_wb_cyc     <= 1'b0;
									o_wb_addr    <= 2'b0;
									o_wb_data    <= 32'd0;
									t_a_time     <= 26'd0;
									state        <= Turn_Around_time;
								end	
							 else 
								state <= Ack;
						end
		END://6
						begin
							 if(t_a_time == 26'd50000000)
							 begin
								  state    <= IDLE;
								  t_a_time <= 0;
							 end
							 else
							  begin
							      state    <= END;
									t_a_time <= t_a_time + 1;
									
							  end
						end
						
				default: state <= IDLE;
			endcase
		 
end 

wire [255:0]DATA;
ILA ila (
    .CONTROL(CONTROL0), // INOUT BUS [35:0]
    .CLK(i_clk), // IN
    .DATA(DATA), // IN BUS [255:0]
    .TRIG0({o_uart_tx, o_wb_stb, push_button} ) // IN BUS [7:0]
);
control cntrl (
    .CONTROL0(CONTROL0) // INOUT BUS [35:0]
);


		assign DATA[1]     =  i_rst;
		assign DATA[2]     =  push_button;
		assign DATA[3]     =  i_wb_ack;
		assign DATA[4]     =  o_wb_stb;
		assign DATA[7:5]   =  state;
		assign DATA[39:8]  =  o_wb_data;
		assign DATA[41:40] =  o_wb_addr;
		assign DATA[73:42] =  i_wb_data;
		assign DATA[74]    =  o_wb_we;
		assign DATA[75]    =  o_wb_cyc;
		assign DATA[76]    =  o_uart_tx;
		assign DATA[80:77] =  o_wb_sel;
		//assign DATA[91:81] =  t_a_time;
		assign DATA[99:92] =  tx_byte[location];
		assign DATA[114:100] = location;
		
  endmodule


//reset fn khatam
//state machine should run on push button 
//add uart delay of 30us after every transaction

