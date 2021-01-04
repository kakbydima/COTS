`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: KIST
// Engineer: DMYTRO KOTOV
// 
// Create Date:    17:24:55 09/18/2020 
// Design Name: 
// Module Name:    pipeout_testc1 
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
module pipeout_testc1(
        input wire [4:0] okUH,
        output wire[2:0] okHU,
        inout wire[31:0] okUHU,
        inout wire okAA,
        input wire sys_clkn,
        input wire sys_clkp,
        input wire reset,
		  output [7:0] led,
        // Your signals here
		  // Wire declarations
		 
		  output wire DXMIT_BAR, //output
		  output wire SYS_CLK,	//output
		  output wire DCLK,		//output
		  output wire CONV,		//output
		 // static to DDC112
		  output wire [2:0] RANGE,
		  output wire TEST,
		  input wire DOUT,		//input 
		  input wire DVALID_BAR,//input
	
		  output wire OE// for translators
    );
    
    //FP wires    
		wire okClk;
		wire [112:0] okHE;
		wire [64:0] okEH;
		wire [31:0] dataA;
		wire [31:0] dataB;
    //Your HDL here
		
		  // ==== wires for DDC112 interface ====
		  wire reset_fsm;	//wire
		  wire fifo_flag; //wire
		  wire fiforead;	//wire
		  wire [31:0] dataout; //wire
		  wire [31:0] TINT;
		  wire [31:0] fifo_th;
 		  
			 FSM fsm1(
        .sys_clkn(sys_clkn),			// for clock generation 100MHz
        .sys_clkp(sys_clkp),			// for clock generation 100MHz
		  
        .okClk(okClk),			// 
		  .DOUT(DOUT), 					//for chip interface
		  .DVALID_BAR(DVALID_BAR), 	//for chip interface
		  .DXMIT_BAR(DXMIT_BAR), 		//for chip interface
		  .SYS_CLK(SYS_CLK), 			//for chip interface
		  .DCLK(DCLK), 					//for chip interface
		  .CONV(CONV), 					//for chip interface
		  
		  .reset_fsm(reset_fsm), 		// from wirein 
		  .fifo_flag(fifo_flag), 		// to either trigger or wireout
		  .fiforead(fiforead),			// for pipeout
		  .dataout(dataout),  			// for pipeout
		  .TINT(TINT),
		  .fifo_th(fifo_th)
    );
		
	 assign OE=1;
    assign dataA=32'd123456;
    assign dataB=32'd224466;
	 assign led [7:6] = 1;
	 assign led [5] = TEST;
	 assign led [4:2] = RANGE[2:0];
	 assign led [1] = reset_fsm;
	
	 // FrontPanel module instantiations
	  okHost hostIF (
        .okUH(okUH),
        .okHU(okHU),
        .okUHU(okUHU),
        .okClk(okClk),
        .okAA(okAA),
        .okHE(okHE),
        .okEH(okEH)
    );
	    // Adjust NUMBER_OF_OUTPUTS to fit the number of outgoing endpoints in your design
    localparam NUMBER_OF_OUTPUTS = 6;
    wire [NUMBER_OF_OUTPUTS*65-1:0] okEHx;
	 
    okWireOR # (.N(NUMBER_OF_OUTPUTS)) wireOR (okEH, okEHx);
		assign led[0] = ~fifo_flag;
		wire emptywire;
		
    okWireIn epwire03(
			.okHE(okHE), 
			.ep_addr(8'h03), 
			.ep_dataout(RANGE)
	 );
			
	okWireIn wire02(
		  .okHE(okHE),
		  .ep_addr(8'h02),
		  .ep_dataout(reset_fsm)
	);
			
	okWireIn wire04(
		  .okHE(okHE),
		  .ep_addr(8'h04),
		  .ep_dataout(TINT)
	);
    okWireIn epwire01(
			.okHE(okHE), 
			.ep_addr(8'h01), 
			.ep_dataout(TEST)
	);
			
    okWireOut outA20(
         .okHE(okHE),
         .okEH(okEHx[1*65 +: 65]),
         .ep_addr (8'h20),
         .ep_datain(dataA)
    );
    okWireOut outB21(
             .okHE(okHE),
             .okEH(okEHx[0*65 +: 65]),
             .ep_addr (8'h21),
             .ep_datain(dataB)
    );
   
	okWireOut outC23(
         .okHE(okHE),
         .okEH(okEHx[2*65 +: 65]),
         .ep_addr (8'h23),
         .ep_datain(RANGE)
    );
	 
	 okWireOut outtrig22(
             .okHE(okHE),
             .okEH(okEHx[3*65 +: 65]),
             .ep_addr (8'h22),
             .ep_datain(fifo_flag)
    );
	 
	 okWireOut fifo_thwire24(
             .okHE(okHE),
             .okEH(okEHx[5*65 +: 65]),
             .ep_addr (8'h24),
             .ep_datain(fifo_th)
    );
//	 pipeout
	okPipeOut pipeA0(
		  .okHE(okHE),
		  .okEH(okEHx[4*65 +: 65]),
		  .ep_addr(8'hA0),
		  .ep_read(fiforead),
		  .ep_datain(dataout)
	);
//     ------------------------------------------------------------------------------------------
//	  Test bench to give mock data output given that DVALID toggles after 422usec @ 10MHz clk 
//	 ------------------------------------------------------------------------------------------
//	  Delete when data transfer to Python via USB will be confirmed 
//	 ------------------------------------------------------------------------------------------
//	 wire [1:0] mock_state;
//	 DDC112_mock ddc112(
//	 .RST(reset_fsm),
//	 .SYS_CLK(SYS_CLK),
//	 .DCLK(DCLK),
//	 .CONV(CONV),
//	 .DXMIT_BAR(DXMIT_BAR),
//	 .DVALID_BAR(DVALID_BAR),
//	 .DOUT(DOUT),
//	
//	 .mock_state(mock_state) //0 - IDLE, 1 - COUNT, 2 - DATAshift
//    );
endmodule

