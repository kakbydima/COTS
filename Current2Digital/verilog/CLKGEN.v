`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: KIST
// Engineer: KOTOV DMYTRO
// 
// Create Date:    15:27:29 09/23/2020 
// Design Name: 
// Module Name:    CLKGEN 
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
module CLKGEN(
	input wire clk,
	input wire reset,
	input wire DXMIT_BAR,
	output reg SYS_CLK,
	//output reg DCLK,
	output  DCLK,
	input wire [31:0] TINT,
	output reg CONV
    );
	 
	 reg [4:0] cnt_10M; //to be able to count to 1sec with 100MHz clk 
	 reg [27:0] cnt_int; //to be able to count to 1sec with 100MHz clk 
// 10MHz generation SYS_CLK & DCLK
	 always @(posedge clk or posedge reset)
	 begin
		if (reset)
		begin
			cnt_10M <=0;
			SYS_CLK <=0;
		//	DCLK	  <=0;
		end
		else
		begin
			if (cnt_10M<5-1) 
			begin
				cnt_10M 	<=cnt_10M+1;
			end
			else
			begin
				SYS_CLK	<=~SYS_CLK;
				cnt_10M 	<=0;
				/*if (DXMIT_BAR==0) //
				begin
					DCLK		<=~SYS_CLK;
				end
				else
				begin
					DCLK		<=0;
				end*/
			end
		end
	 end	
	reg dxmit_bar_del;
	 // Tint generation 
	 always @(posedge SYS_CLK or posedge reset)
	 begin
		if (reset)
		begin
			cnt_int 	<=0;
			CONV		<=0;
			dxmit_bar_del<=0;
		end
		else
		begin
			dxmit_bar_del<=DXMIT_BAR;
			if (cnt_int<TINT-1) 
			begin
				cnt_int <=cnt_int+1;
			end
			else
			begin
				CONV		<=~CONV;
				cnt_int 	<=0;
			end
		end
	 end
//asd
assign 	 DCLK = (dxmit_bar_del==0)? SYS_CLK:0;
endmodule
