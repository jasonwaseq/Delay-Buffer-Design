module counter_roll
  #(parameter [31:0] max_val_p = 15
   ,parameter width_p = $clog2(max_val_p)  
    /* verilator lint_off WIDTHTRUNC */
   ,parameter [width_p-1:0] reset_val_p = '0
    )
    /* verilator lint_on WIDTHTRUNC */
   (input [0:0] clk_i
   ,input [0:0] reset_i
   ,input [0:0] up_i
   ,input [0:0] down_i
   ,output [width_p-1:0] count_o);

   localparam [width_p-1:0] max_val_lp = max_val_p[width_p-1:0];

   // Your code here:

  logic [width_p-1:0] count_l;
  always_ff @(posedge clk_i) begin
    if (reset_i)
      count_l <= reset_val_p;
    else if ((up_i && ~down_i) && (count_l < max_val_lp))
      count_l <= count_l + 1;
    else if ((up_i && ~down_i) && (count_l == max_val_lp))
      count_l <= '0;
    else if ((down_i && ~up_i) && (count_l > 0))
      count_l <= count_l - 1;
    else if ((down_i && ~up_i) && (count_l == 0))
      count_l <= max_val_lp;
    else 
      count_l <= count_l;
  end

  assign count_o = count_l;

endmodule
