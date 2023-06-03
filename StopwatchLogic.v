/*
	StopwatchLogic
	-----------------
	By Longzhen Yuan
	Date: 10th April 2023
	
	Module Description:
	-----------------------
	Used to implement most of the logical function of this project.
	input:
		CLK_100Hz: generated by the ClockDivider50MHzTo100Hz module
		reset_n: the reset switch
		start_stop: the start_stop button
		hold: the hold button
		adjust: the mode selecting switch
	output:
		stopwatch_unit_mins: the minute information, this will be passed to SevenSegEncoder module for further processing
		stopwatch_unit_secs: the second information, this will be passed to SevenSegEncoder module for further processing
		stopwatch_unit_decs: the milisecond information, this will be passed to SevenSegEncoder module for further processing
		stopwatch_overflow: illumnated when the time exceeds 99:59:99
		enable: connected to breath_led module.
*/
module StopwatchLogic(
	input CLK_100Hz,
	input reset_n, //switch
	input start_stop, //key
	input hold, //key
	input adjust, //switch, change the function of two keys. 0(下方） for start_stop and hold, 1（上方） for add/subtract time
	output [6:0] stopwatch_unit_mins,
	output [5:0] stopwatch_unit_secs,
	output [6:0] stopwatch_unit_decs,
	output reg stopwatch_overflow,
	output enable //used to controll breath led module.
);



reg [19:0] percentiles; //99*60*100+59*100+99 = 599999
reg [9:0] speed_level; //8s, i.e.800 clock cycles 

wire start_stop_flag;
wire hold_flag;
reg start_stop_1;
reg start_stop_2;
reg hold_1;
reg hold_2;
reg start_stop_state; //0 pause, 1 count up




reg [5:0] cnt_0_5s;
reg change_flag;

assign stopwatch_unit_mins = percentiles/6000;     //1*60*100=6000
assign stopwatch_unit_secs = percentiles%6000/100;     //1*100 = 100
assign stopwatch_unit_decs = percentiles%100;

assign enable = adjust && reset_n; //illuminate the breath led when under adjustment mode.

assign start_stop_flag = (!start_stop_1) && (start_stop_2); // creat a flag last for 1 clock period when the key is pressed.
assign hold_flag = (!hold_1) && (hold_2);

always@(posedge CLK_100Hz or negedge reset_n)begin //generate flag
	if(!reset_n)begin
		start_stop_1 <= 1'b1;
		start_stop_2 <= 1'b1;
	end
	
	else begin
		start_stop_1 <= start_stop;
		start_stop_2 <= start_stop_1;
	end
end

always@(posedge CLK_100Hz or negedge reset_n)begin //generate flag
	if(!reset_n)begin
		hold_1 <= 1'b1;
		hold_2 <= 1'b1;
	end
	
	else begin
		hold_1 <= hold;
		hold_2 <= hold_1;
	end
end


always@(posedge CLK_100Hz or negedge reset_n)begin 

	if(!reset_n)begin
		percentiles <= 20'd0;
	end
	
	else if(!adjust) begin // start/stop mode
		if (!start_stop_state || !hold) begin //when pressing the hold button, pause the counter
			percentiles <= percentiles;
		end
		
		else begin
			percentiles <= percentiles + 1'b1;
		end
	end
	
	else begin
		if(start_stop_flag) begin //increase the time
			percentiles <= percentiles + 1'b1;
		end
		else if((hold_flag) && (percentiles>=13'd1)) begin//decrease the time
			percentiles <= percentiles - 1'b1;
		end
		else if(!start_stop && change_flag) begin //different speed level, so holding longer will result in a faster changing rate.
			if (speed_level < 10'd199)begin
				percentiles <= percentiles + 13'd1;
			end
			else if (speed_level < 10'd399)begin
				percentiles <= percentiles + 13'd10;
			end
			else if (speed_level < 10'd599)begin
				percentiles <= percentiles + 13'd100;
			end
			else if (speed_level < 10'd799)begin
				percentiles <= percentiles + 13'd1000;
			end
			else begin
				percentiles <= percentiles + 13'd6000; //finally increase by 1min/0.5sec
			end
		end
		else if(!hold && change_flag) begin //different speed level
			if ((speed_level < 10'd199) && (percentiles>=13'd1))begin
				percentiles <= percentiles - 13'd1;
			end
			else if ((speed_level < 10'd399) && (percentiles>=13'd10))begin
				percentiles <= percentiles - 13'd10;
			end
			else if ((speed_level < 10'd599) && (percentiles>=13'd100))begin
				percentiles <= percentiles - 13'd100;
			end
			else if ((speed_level < 10'd799) && (percentiles>=13'd1000))begin
				percentiles <= percentiles - 13'd1000;
			end
			else if (percentiles >= 13'd6000) begin
				percentiles <= percentiles - 13'd6000;
			end
			else begin
				percentiles <= percentiles;
			end
		end
		else begin
			percentiles <= percentiles;
		end
	
	end
	
end

always@(posedge CLK_100Hz or negedge reset_n)begin //generare a change_flag each 0.5s
	if(!reset_n)begin
		cnt_0_5s <= 6'd0;
		change_flag <= 1'b0;
	end
	
	else if (!hold || !start_stop)begin
		if (cnt_0_5s == 6'd49)begin
			cnt_0_5s <= 7'd0;
			change_flag <= 1'b1;
		end
	
		else if (change_flag > 1'b0) begin
			cnt_0_5s <= cnt_0_5s + 1'd1;
			change_flag <= change_flag - 1'b1;
		end
	
		else begin
			cnt_0_5s <= cnt_0_5s + 1'd1;
			change_flag <= change_flag;
		end
	end
	
	else begin
		cnt_0_5s <= 6'd0;
		change_flag <= 1'b0;
	end
	
	
	
	
end

always@(posedge CLK_100Hz or negedge reset_n)begin // use a counter to record how long the button has already been pressed, so that the changing rate can be determined.
	if(!reset_n)begin
		speed_level <= 10'd0;
	end
	else if (!start_stop || !hold )begin
		if (speed_level == 10'd799) begin //when press for more than 8s, keep speed_level unchanged.
			speed_level <= speed_level;
		end
		else begin
			speed_level <= speed_level + 10'd1;
		end
	end
	
	else begin //once release the button, clear speed_level
		speed_level <= 10'd0;
	end
end


always@(posedge CLK_100Hz or negedge reset_n)begin //generate overflow flag
	
	if(!reset_n)begin
		stopwatch_overflow <= 1'b0;
	end
	
	else if(percentiles > 20'd599999)begin
		stopwatch_overflow <= 1'b1;
	end
	
	else begin
		stopwatch_overflow <= stopwatch_overflow;
	end
	
end

always@(posedge CLK_100Hz or negedge reset_n)begin //change start_stop_state
	
	if(!reset_n)begin
		start_stop_state <= 1'b0;
	end
	
	else if(adjust)begin
		start_stop_state <= 1'b0; //reset the start_stop_state to make sure when switch back to normal mode, the counter will not count up automatically.
	end
	
	else if(start_stop_flag)begin //when a click on start_stop button is detected, flip over the state (start to count or stop to count)
		start_stop_state <= ~start_stop_state;
	end
	
	else begin
		start_stop_state <= start_stop_state;
	end
	
end



endmodule
	
