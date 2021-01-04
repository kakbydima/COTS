`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:55:07 09/23/2020 
// Design Name: 
// Module Name:    READOUT 
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
module READOUT(
	input wire SYS_CLK,
	input wire RST,
	input wire DVALID_BAR,
	input wire DOUT,
//	input wire  [10:0] fifo_cnt,
	input wire  [9:0] fifo_cnt,
	input wire  [31:0] TINT,
	
	output reg DXMIT_BAR,
	
	output wire fifo_flag,
	output reg [64-1:0] data2pipe,
	input fiforead,
	
	output reg state,
	output reg done,
	output [31:0] fifo_th
    );
	 
	 parameter bitnum=40; 
//	 parameter fifo_flagnum = 64;
	 reg [31:0] fifo_th;
	 
	 reg [8:0] bitcnt;
	 reg [bitnum-1:0] doutreg;
	 
	 reg dxmit_bar_old;
	 
	 
	 reg dvalid_bar_old;
	 parameter IDLE=0, RETRIEVE=1;
	 
	 //shine LED when DATA needs to be retrieved 
	 // Given that we want to readout each ~200msec, we need to adjust FIFO flag when changing integration time 
	 wire tintless1msec;
	 wire tintless5msec;
	 wire tintless10msec;
	 wire tintless05msec;
	 
	 assign tintless05msec = ((TINT<5000))? 1:0;
	 assign tintless1msec = ((TINT<10000)&&(TINT>5000-1))? 1:0;
	 assign tintless5msec = ((TINT<50000)&&(TINT>10000-1))? 1:0;
	 assign tintless10msec = ((TINT<100000)&&(TINT>50000-1))? 1:0;
	 
	 assign fifo_flag= (fifo_cnt>(2*fifo_th))? 1:0;
	 
	 always @(posedge SYS_CLK or posedge RST)
	 begin
		if (RST)
		begin
			doutreg			<=0;
			dxmit_bar_old	<=1;
			bitcnt			<=0;
			state				<= IDLE;
			done 				<=0;
			data2pipe 		<=0;
			DXMIT_BAR 		<=1;
			fifo_th			<=100;
		end
		else
		begin
			if (tintless05msec)
			begin
				fifo_th <= 400;
			end
			else
			begin
				if (tintless1msec)
				begin
					fifo_th <= 200;
				end
				else
				begin
					if (tintless5msec)
					begin
						fifo_th <= 50;
					end
					else
					begin
						if (tintless10msec)
						begin
							fifo_th <= 25;
						end
						else
						begin
							fifo_th <= 20;
						end
					end
				end
			end
			
			
			dvalid_bar_old	<=DVALID_BAR;
			case (state)
			IDLE:
			begin
				done 			<= 0;
				//if ((DVALID_BAR==0)&(dvalid_bar_old==0)) //negative edge of DXMIT_BAR
				if ((DVALID_BAR==0)&(dvalid_bar_old==1)) //negative edge of DXMIT_BAR
				begin
					state <=RETRIEVE;
					DXMIT_BAR <=0;
				end
				else
				begin
					state <=IDLE;
					DXMIT_BAR <=1;
				end
			end
			RETRIEVE:
			begin
				if (bitcnt<bitnum)// bitcount is not yet finished 
				begin
					doutreg[bitcnt]	<=DOUT; //shifting data 
					bitcnt	<= bitcnt+1;
					done 		<= 0;
					DXMIT_BAR<= 0;
				end
				else
				begin
					done 			<= 1;
					data2pipe 	<= doutreg; // MSB --> LSB of IN2, LSB --> LSB of IN1
					state 		<= IDLE;
					DXMIT_BAR	<= 1;
					bitcnt		<= 0;
				end
			end
			default:
			begin
				doutreg		<= 0;
				data2pipe	<= 0;
				done			<= 0;
				bitcnt		<= 0;
				dxmit_bar_old		<= 1;
				state 		<= IDLE;
				DXMIT_BAR	<= 1;
			end
			endcase
		end
	 end
	 


endmodule
