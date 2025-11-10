module delaybuffer
  #(parameter int width_p = 8,
    parameter int delay_p = 8)
  (input  logic               clk_i,
   input  logic               reset_i,
   input  logic [width_p-1:0] data_i,
   input  logic               valid_i,
   output logic               ready_o,
   output logic [width_p-1:0] data_o,
   output logic               valid_o,
   input  logic               ready_i);

  logic [width_p-1:0] buffer [delay_p:0];
  logic valid_l;

  assign ready_o = ~valid_l || ready_i;

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      valid_l<= 1'b0;
      for (int i = 0; i < delay_p; i++) begin
        buffer[i] <= '0;
      end
    end
    else if (ready_o) begin
      valid_l <= valid_i;
      if (valid_i) begin
      buffer[0] <= data_i;
        for (int i = 0; i < delay_p; i++) begin
          buffer[i+1] <= buffer[i];
        end 
      end
    end
  end

  assign data_o  = buffer[delay_p];
  assign valid_o = valid_l;

endmodule
