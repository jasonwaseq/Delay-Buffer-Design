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

  localparam depth_log2_p = $clog2(delay_p + 2);
  localparam [depth_log2_p-1:0] delay_lp = delay_p[depth_log2_p-1:0];
  logic [depth_log2_p-1:0] wr_ptr;
  logic [depth_log2_p-1:0] rd_ptr;
  logic valid_l;

  assign ready_o = ready_i | ~valid_l;
  logic wr_en;  
  assign wr_en = ready_o & valid_i;
  logic rd_en;
  assign rd_en = ready_i & valid_o;

  always_ff @(posedge clk_i) begin
  if (reset_i) begin
    wr_ptr <= delay_lp;
  end
  else if (wr_en) begin
      wr_ptr <= wr_ptr + 1;
    end
  end

  always_ff @(posedge clk_i) begin
  if (reset_i) begin
    rd_ptr <= '0;
  end
  else if (rd_en) begin
      rd_ptr <= rd_ptr + 1;
    end
  end
  
  always_ff @(posedge clk_i) begin
  if (reset_i) begin
    valid_l <= '0;
  end
  else if (wr_en)
    valid_l <= 1'b1;
  else if (ready_o & ~valid_i)
    valid_l <= '0;
  end

  assign valid_o = valid_l;
  
  logic [depth_log2_p-1:0] mux;
  assign mux = (rd_en) ? (rd_ptr + 1) : rd_ptr;
  logic [width_p-1:0] rd_addr_l;
  ram_1r1w_sync #(
    .width_p(width_p),
    .depth_p(1 << depth_log2_p),
    .filename_p("")
  ) ram_inst (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .wr_valid_i(wr_en),
    .wr_data_i(data_i),
    .wr_addr_i(wr_ptr),
    .rd_valid_i(1'b1),
    .rd_addr_i(mux),
    .rd_data_o(rd_addr_l)
  );  

  assign data_o = rd_addr_l;

endmodule
