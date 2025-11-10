module SRL16E (
  output Q,
  input A0, A1, A2, A3, CE,
  input CLK,
  input D
);
  parameter [15:0] INIT = 16'h0000;
  parameter [0:0] IS_CLK_INVERTED = 1'b0;

  reg [15:0] r = INIT;
  assign Q = r[{A3,A2,A1,A0}];
  generate
    if (IS_CLK_INVERTED) begin
      always @(negedge CLK) if (CE) r <= { r[14:0], D };
    end
    else
      always @(posedge CLK) if (CE) r <= { r[14:0], D };
  endgenerate
  specify
    // Max delay from: https://github.com/SymbiFlow/prjxray-db/blob/34ea6eb08a63d21ec16264ad37a0a7b142ff6031/artix7/timings/CLBLM_R.sdf#L912
    $setup(D , posedge CLK &&& !IS_CLK_INVERTED, 173);
    $setup(D , negedge CLK &&&  IS_CLK_INVERTED, 173);
    // Max delay from: https://github.com/SymbiFlow/prjxray-db/blob/34ea6eb08a63d21ec16264ad37a0a7b142ff6031/artix7/timings/CLBLM_R.sdf#L905
    if (!IS_CLK_INVERTED && CE) (posedge CLK => (Q : D)) = 1472;
    if ( IS_CLK_INVERTED && CE) (negedge CLK => (Q : D)) = 1472;
    // Max delay from: https://github.com/SymbiFlow/prjxray-db/blob/34ea6eb08a63d21ec16264ad37a0a7b142ff6031/artix7/timings/CLBLM_R.sdf#L905
    if (!IS_CLK_INVERTED && CE) (posedge CLK => (Q : 1'bx)) = 1472;
    if ( IS_CLK_INVERTED && CE) (negedge CLK => (Q : 1'bx)) = 1472;
    (A0 => Q) = 631;
    (A1 => Q) = 472;
    (A2 => Q) = 407;
    (A3 => Q) = 238;
  endspecify
endmodule
