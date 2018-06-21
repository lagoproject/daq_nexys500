`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Laboratorio de Particulas - Centro Atomico Bariloche
// Engineer: Miguel Sofo Haro
// 
// Create Date:    14:13:56 10/29/2010 
// Design Name: 
// Module Name:    clock_divider 
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
// A partir del clock global de la FPGA, el proposito del modulo es generar 
//	una señal de clock de frecuencia inferior (< frecuencia del clock global)
//
//////////////////////////////////////////////////////////////////////////////////
module clock_divider
(
		input wire global_clock,
		output reg clock
);

//Parameters,
parameter	o_freq_MHz = 10;	//Output clock frecuency in MHz
parameter 	gc_freq_MHz = 50;	//Global clock frecuency in MHz

//Local Paramters
localparam 	first_trigger = ((gc_freq_MHz/o_freq_MHz)+1)/2;
localparam	second_trigger = (gc_freq_MHz/o_freq_MHz)+1;

//Internal Variables
reg [31:0]	counter;

//Initial Variables Values
initial 
begin
	counter = 0;
	clock = 0;
end
//Circuit
always @(posedge global_clock)
begin
	counter = counter + 1;
	if(counter == first_trigger)
	begin
		clock = ~clock;
	end
	else
	begin
		if(counter == second_trigger)
		begin
			counter = 0;
			clock = ~clock;
		end
	end
end
endmodule
