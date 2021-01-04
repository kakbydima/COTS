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
	output reg DXMIT_BAR,
	
	output wire fifo_flag,
	output reg [64-1:0] data2pipe,
	input fiforead,
	
	output reg state,
	output reg done
    );
	 
	 parameter bitnum=40; 
	 parameter fifo_flagnum = 64;
	 
	 reg [8:0] bitcnt;
	 reg [bitnum-1:0] doutreg;
	 
	 reg  [7:0] fifo_cnt;
	 reg fifo_read_done;
	 reg fifo_read_old;
	 reg dxmit_bar_old;
	 
	 
	 reg dvalid_bar_old;
	 parameter IDLE=0, RETRIEVE=1;
	 
	 //shine LED when DATA needs to be retrieved 
	 assign fifo_flag= (fifo_cnt>63)? 1:0;
	 
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
			
			fifo_read_done <=0;
			fifo_cnt 		<=0;
			fifo_read_old	<=0;
		end
		else
		begin
			// to set flag for fifo 
			fifo_read_old	<=fiforead;
			if (done==1)
			begin
				if (fifo_read_done==1)
				begin
					fifo_cnt <= fifo_cnt-fifo_flagnum;
					fifo_read_done <=0;
				end
				else
				begin
					if (fifo_cnt<127)
					begin
						fifo_cnt <= fifo_cnt+1;
					end
					else
					begin
						fifo_cnt <= 127;
					end
					//if (fiforead<=1)
					if (fiforead==1)
					begin
							fifo_read_done<=1;
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
