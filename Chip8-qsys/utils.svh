`ifndef CHIP8_UTILS_SVH
`define CHIP8_UTILS_SVH

function reg inbetween(input [17:0] low, value, high); 
begin
  inbetween = value >= low && value <= high;
end
endfunction

`endif