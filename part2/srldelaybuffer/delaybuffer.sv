module delaybuffer
  #(parameter [31:0] width_p = 8
   ,parameter [31:0] delay_p = 8
   )
  (input [0:0] clk_i
  ,input [0:0] reset_i
  ,input [width_p-1:0] data_i
  ,input [0:0] ready_i
  ,input [0:0] valid_i
  ,output [0:0] ready_o 
  ,output [0:0] valid_o 
  ,output [width_p-1:0] data_o 
  );

  logic valid_l;
  assign ready_o = ~valid_l || ready_i;

  always_ff @(posedge clk_i) begin
    if (reset_i)
      valid_l <= 1'b0;
    else if (ready_o)
      valid_l <= valid_i;
  end

  assign valid_o = valid_l;
  wire [3:0] address = delay_p[3:0];

  wire [width_p-1:0] q_out;

  genvar i;
  generate
    for (i = 0; i < width_p; i = i + 1) begin : gen_srl
      SRL16E #(
        .INIT(16'h0000),
        .IS_CLK_INVERTED(1'b0)
      ) SRL16E_inst (
        .Q(q_out[i]),
        .A0(address[0]),
        .A1(address[1]),
        .A2(address[2]),
        .A3(address[3]),
        .CE(ready_o && valid_i),
        .CLK(clk_i),
        .D(data_i[i])
      );
    end
  endgenerate

  assign data_o = q_out;

endmodule