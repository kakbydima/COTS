`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:21:58 09/23/2020 
// Design Name: 
// Module Name:    DDC112_mock 
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
	
	 //------------------------------------------------------------------------------------------
	 // Test bench to give mock data output given that DVALID toggles after 422usec @ 10MHz clk 
	 //------------------------------------------------------------------------------------------
	
module DDC112_mock(
	input RST,
	input SYS_CLK,
	input DCLK,
	input CONV,
	input DXMIT_BAR,
	output reg DVALID_BAR,
	//output reg DOUT,
	output  DOUT,
	
	output reg [1:0] mock_state //0 - IDLE, 1 - COUNT, 2 - DATAshift
    );

 //look for posedge or negedge of the CONV--> count for 422usec--> update output with clock DCLK given saw pattern(how many bits?).
	 // also each 20/40 bits are separated from each other (down and up saw)
	 
	 reg conv_old;
	 reg [30:0] mock_cnt;
	 reg [19:0] mock_data; // mock data(increases each time by one)
	 reg [5:0] shift_cnt;
	 parameter mockIDLE=0, mockCOUNT=1, mockDATAshift=2; 
	 parameter mock_time = 4500; // how long it would take to present data and DVALID_BAR at the output 
	 
	 always @(posedge SYS_CLK or posedge RST)
	 begin
		if (RST)
		begin
			conv_old			<= 0;
			mock_state		<= mockIDLE;
			mock_cnt			<=0;
			DVALID_BAR 		<=1;
			mock_data		<=0;
			shift_cnt		<=0;
		end
		else
		begin
			conv_old<= CONV;
			case (mock_state)
			mockIDLE:
			begin
				if (CONV!=conv_old) // at the moments of CONV toggling 
				begin
					mock_state<=mockCOUNT;
				end
				else
				begin
					mock_state<=mockIDLE;
				end
				mock_cnt			<=0;
				DVALID_BAR 		<=1;
			end
			
			mockCOUNT: //waiting for the "conversion to happen"
			begin
					if (mock_cnt< mock_time-1)
					begin
						mock_cnt<=mock_cnt+1;
						mock_state <= mockCOUNT;
					end
					else
					begin
						mock_cnt<=0;
						shift_cnt<=shift_cnt+1;
						mock_state <= mockDATAshift;
						mock_data		<=mock_data+1; // to have different output for different channel // not the best evaluation
						//mock_data		<=mock_data-1; // to have different output for different channel // not the best evaluation
						//mock_data <= 
					end
					DVALID_BAR 		<=1;
			end
			
			mockDATAshift:
			begin
					if (DXMIT_BAR==1)
					begin
						DVALID_BAR 		<=0;
					end
					else
					begin
						DVALID_BAR 		<=1;
						mock_state 		<= mockIDLE;
					end
			end
				
			default: 
			begin
				mock_state<=mockIDLE;
				mock_cnt			<=0;
				DVALID_BAR 		<=1;
			end
			
			endcase
			
		end
	 end
	 //------------------------------------------------------------------------------------------
	 
	 reg [7:0] mock_bitshift; // to cnt bits from 0->39 and then switch to idle;
	 wire [40:0] mock_data_ch2ch1;
//	 assign mock_data_ch2ch1 = {1'b0,mock_data, (mock_data)};
	 assign mock_data_ch2ch1 = {1'b0,mock_data, (mock_data)};
//	 assign mock_data_ch2ch1 = {1'b0,20'b11111111111111111111,20'b11111111111111111111}<<shift_cnt;
//	 assign mock_data_ch2ch1 = {1'b0,20'b10111111111111111101,20'b10000111111111100001};
	 
	// always @(negedge DCLK or posedge RST) // changes DOUT
	 always @(negedge DCLK or posedge DXMIT_BAR) // changes DOUT
	 begin
		if (DXMIT_BAR)
		begin
			mock_bitshift 	<=39;
			//DOUT				<=0;
		end
		else
		begin
			if (mock_bitshift>0)
			begin
				mock_bitshift<=mock_bitshift-1;
				//DOUT<=mock_data_ch2ch1[mock_bitshift];
			end
			//else
			//begin
			//	mock_bitshift<=40;
				//DOUT<=0;
			//end
			
		end
	 end
	 assign DOUT = (DXMIT_BAR==0)? mock_data_ch2ch1[mock_bitshift]:0;
endmodule
