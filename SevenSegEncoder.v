/*
	SevenSegEncoder
	-----------------
	By Longzhen Yuan
	Date: 10th April 2023
	
	Module Description:
	-----------------------
	Accept time information from StopwatchLogic module. Display number on the 7-segment display by instantiating several BCDEncoder and BCD2Seven module
	input:
		stopwatch_unit_mins: minute information generated by StopwatchLogic module
		stopwatch_unit_secs: second information generated by StopwatchLogic module
		stopwatch_unit_decs: milisecond information generated by StopwatchLogic module
	output:
		hex_10_mins: Used to control the 10min digit of the 7-segment display array.
		hex_1_min: Used to control the 1min digit of the 7-segment display array.
		hex_10_secs: Used to control the 10seconds digit of the 7-segment display array.
		hex_1_sec: Used to control the 1second digit of the 7-segment display array.
		hex_hundredths: Used to control the 0.01second digit of the 7-segment display array.
		hex_tenths: Used to control the 0.1second digit of the 7-segment display array.
*/
module SevenSegEncoder( //Use BCD code to display number on the 7-segment display, BCD to 7 segment
	input [6:0] stopwatch_unit_mins, //0-99
	input [5:0] stopwatch_unit_secs, //0-59
	input [6:0] stopwatch_unit_decs, //0-99
	output [7:0] hex_10_mins,
	output [7:0] hex_1_min,
	output [7:0] hex_10_secs,
	output [7:0] hex_1_sec,
	output [7:0] hex_hundredths, //0.01
	output [7:0] hex_tenths // 0.1
);

wire [3:0] BCD_10_mins;
wire [3:0] BCD_1_mins;

wire [3:0] BCD_10_secs;
wire [3:0] BCD_1_secs;

wire [3:0] BCD_10_percentiles;
wire [3:0] BCD_1_percentiles;

BCDEncoder inst1( // convert a 8 digits number to 12 digits BCD code
    .BinaryIn({1'd0,stopwatch_unit_mins}), //8digits input 0-255
    .BCDOut({BCD_10_mins, BCD_1_mins}) //each four bits represent hundred, ten and one respectively,[11:8],[7:4],[3:0]
);

BCDEncoder inst2( //convert a 8 digits number to 12 digits BCD code
    .BinaryIn({2'd0,stopwatch_unit_secs}), //8digits input 0-255
    .BCDOut({BCD_10_secs, BCD_1_secs}) //each four bits represent hundred, ten and one respectively,[11:8],[7:4],[3:0]
);

BCDEncoder inst3( //convert a 8 digits number to 12 digits BCD code
    .BinaryIn({1'd0,stopwatch_unit_decs}), //8digits input 0-255
    .BCDOut({BCD_10_percentiles, BCD_1_percentiles}) //each four bits represent hundred, ten and one respectively,[11:8],[7:4],[3:0]
);

BCD2Seven inst4(

	.BCD(BCD_10_mins),

	
	.HEX(hex_10_mins)
	
);

BCD2Seven inst5(

	.BCD(BCD_1_mins),

	
	.HEX(hex_1_min)
	
);

BCD2Seven inst6(

	.BCD(BCD_10_secs),

	
	.HEX(hex_10_secs)
	
);

BCD2Seven inst7(

	.BCD(BCD_1_secs),

	
	.HEX(hex_1_sec)
	
);

BCD2Seven inst8(

	.BCD(BCD_10_percentiles),

	
	.HEX(hex_tenths)
	
);

BCD2Seven inst9(

	.BCD(BCD_1_percentiles),

	
	.HEX(hex_hundredths)
	
);





endmodule