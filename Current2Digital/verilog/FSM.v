`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: KIST
// Engineer: DMYTRO KOTOV
// 
// Create Date:    10:35:49 09/21/2020 
// Design Name: 
// Module Name:    FSM 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: FSM to control to extract data and set different timing 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module FSM(
        input wire sys_clkn,			// for clock generation 100MHz
        input wire sys_clkp,			// for clock generation 100MHz
		  input wire okClk,
		  
		  input wire DOUT, 				//for DDC112 interface
		  input wire DVALID_BAR, 		//for DDC112 interface
		  output wire DXMIT_BAR, 		//for DDC112 interface
		  output wire SYS_CLK, 			//for DDC112 interface
		  output wire DCLK, 				//for DDC112 interface
		  output wire CONV, 				//for DDC112 interface
		  
		  input wire reset_fsm, 		// from wirein 
		  output wire fifo_flag, 		// to either trigger or wireout
		  input wire fiforead,			// for pipeout
		  output wire [31:0] dataout  // for pipeout
		 // input 
    );
 
	 // My code is here 
	 wire [31:0] TINT; // integration time(in 10MHz clocks)gets connected to wireouts
	 // TINT TEMP
	 assign TINT = 10000;
	 
	 // Clock
    wire clk;
    wire done;
	 wire [64-1:0] data2pipe;
	 wire state;
	 
    IBUFGDS osc_clk(
        .O(clk), //100MHz
        .I(sys_clkp),
        .IB(sys_clkn)
    );
   	 
	 // ====Main part==== 
	 //10 MHz clock gen and CONV
	 CLKGEN clkgen1 (
			.clk(clk),
			.reset(reset_fsm),
			.DXMIT_BAR(DXMIT_BAR),
			.SYS_CLK(SYS_CLK),
			.DCLK(DCLK),
			.TINT(TINT),
			.CONV(CONV)
		);
	
	READOUT readout1(
			.SYS_CLK(SYS_CLK),
			.RST(reset_fsm),
			.DVALID_BAR(DVALID_BAR),
			.DOUT(DOUT),
			.DXMIT_BAR(DXMIT_BAR),
			
			.fifo_flag(fifo_flag),
			.data2pipe(data2pipe),
			.fiforead(fiforead),
			
			.state(state),
			.done(done)
    );
	     
	// Xilinx Core IP Generated FIFO	
	FIFO_I64_O32 fifo(
     .din(data2pipe),
     .dout(dataout),
     .wr_en(done),
     .rd_en(fiforead),
     //.clk(ti_clk), not sure if the clock should be the same as system clock 
     .wr_clk(SYS_CLK),
     .rd_clk(okClk),
     .rst(reset_fsm)
	);
	

endmodule
