`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:14:13 05/06/2011 
// Design Name: 
// Module Name:    clk_40mhz 
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
module clk_40mhz(clk_50mhz,clk_40mhz);

//Entradas
input wire clk_50mhz;

//Salidas
output reg clk_40mhz;

//Variables Internas
wire clk_200mhz;
reg [7:0] contador;

//Inicio
initial
begin
	clk_40mhz=0;
	contador = 8'b00000000;
end

//instanciacion del DCM
dcm_200mhz i_dcm_200mhz (.CLKIN_IN(clk_50mhz),.RST_IN(1'b0),.CLKFX_OUT(clk_200mhz),.CLKIN_IBUFG_OUT(),.CLK0_OUT(),.CLK2X_OUT(),.LOCKED_OUT());

always @(posedge clk_200mhz)
begin
	contador = contador + 1;
	if(contador == 5)
		contador = 0;
	//if(contador >= 3)
	//begin
	//	contador = 0;
	//	clk_40mhz = ~clk_40mhz;
	//end
end

always @(posedge clk_200mhz)
begin
	case(contador)
		8'b00000001:  clk_40mhz=1;	//1
		8'b00000010:	clk_40mhz=1;	//2
		8'b00000011:	clk_40mhz=1;	//3
		8'b00000100:	clk_40mhz=0;	//4
		8'b00000101:	clk_40mhz=0;	//5
		default: clk_40mhz = 0;
	endcase
end
endmodule
