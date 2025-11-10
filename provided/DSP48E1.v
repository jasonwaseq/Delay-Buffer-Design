module DSP48E1 (
    output [29:0] ACOUT,
    output [17:0] BCOUT,
    output reg CARRYCASCOUT,
    output reg [3:0] CARRYOUT,
    output reg MULTSIGNOUT,
    output OVERFLOW,
    output reg signed [47:0] P,
    output reg PATTERNBDETECT,
    output reg PATTERNDETECT,
    output [47:0] PCOUT,
    output UNDERFLOW,
    input signed [29:0] A,
    input [29:0] ACIN,
    input [3:0] ALUMODE,
    input signed [17:0] B,
    input [17:0] BCIN,
    input [47:0] C,
    input CARRYCASCIN,
    input CARRYIN,
    input [2:0] CARRYINSEL,
    input CEA1,
    input CEA2,
    input CEAD,
    input CEALUMODE,
    input CEB1,
    input CEB2,
    input CEC,
    input CECARRYIN,
    input CECTRL,
    input CED,
    input CEINMODE,
    input CEM,
    input CEP,
    (* clkbuf_sink *) input CLK,
    input [24:0] D,
    input [4:0] INMODE,
    input MULTSIGNIN,
    input [6:0] OPMODE,
    input [47:0] PCIN,
    input RSTA,
    input RSTALLCARRYIN,
    input RSTALUMODE,
    input RSTB,
    input RSTC,
    input RSTCTRL,
    input RSTD,
    input RSTINMODE,
    input RSTM,
    input RSTP
);
    parameter integer ACASCREG = 1;
    parameter integer ADREG = 1;
    parameter integer ALUMODEREG = 1;
    parameter integer AREG = 1;
    parameter AUTORESET_PATDET = "NO_RESET";
    parameter A_INPUT = "DIRECT";
    parameter integer BCASCREG = 1;
    parameter integer BREG = 1;
    parameter B_INPUT = "DIRECT";
    parameter integer CARRYINREG = 1;
    parameter integer CARRYINSELREG = 1;
    parameter integer CREG = 1;
    parameter integer DREG = 1;
    parameter integer INMODEREG = 1;
    parameter integer MREG = 1;
    parameter integer OPMODEREG = 1;
    parameter integer PREG = 1;
    parameter SEL_MASK = "MASK";
    parameter SEL_PATTERN = "PATTERN";
    parameter USE_DPORT = "FALSE";
    parameter USE_MULT = "MULTIPLY";
    parameter USE_PATTERN_DETECT = "NO_PATDET";
    parameter USE_SIMD = "ONE48";
    parameter [47:0] MASK = 48'h3FFFFFFFFFFF;
    parameter [47:0] PATTERN = 48'h000000000000;
    parameter [3:0] IS_ALUMODE_INVERTED = 4'b0;
    parameter [0:0] IS_CARRYIN_INVERTED = 1'b0;
    parameter [0:0] IS_CLK_INVERTED = 1'b0;
    parameter [4:0] IS_INMODE_INVERTED = 5'b0;
    parameter [6:0] IS_OPMODE_INVERTED = 7'b0;


    initial begin
        if (AUTORESET_PATDET != "NO_RESET") $fatal(1, "Unsupported AUTORESET_PATDET value");
        if (SEL_MASK != "MASK")     $fatal(1, "Unsupported SEL_MASK value");
        if (SEL_PATTERN != "PATTERN") $fatal(1, "Unsupported SEL_PATTERN value");
        if (USE_SIMD != "ONE48" && USE_SIMD != "TWO24" && USE_SIMD != "FOUR12")    $fatal(1, "Unsupported USE_SIMD value");
        if (IS_ALUMODE_INVERTED != 4'b0) $fatal(1, "Unsupported IS_ALUMODE_INVERTED value");
        if (IS_CARRYIN_INVERTED != 1'b0) $fatal(1, "Unsupported IS_CARRYIN_INVERTED value");
        if (IS_CLK_INVERTED != 1'b0) $fatal(1, "Unsupported IS_CLK_INVERTED value");
        if (IS_INMODE_INVERTED != 5'b0) $fatal(1, "Unsupported IS_INMODE_INVERTED value");
        if (IS_OPMODE_INVERTED != 7'b0) $fatal(1, "Unsupported IS_OPMODE_INVERTED value");
    end

    wire signed [29:0] A_muxed;
    wire signed [17:0] B_muxed;

    generate
        if (A_INPUT == "CASCADE") assign A_muxed = ACIN;
        else assign A_muxed = A;

        if (B_INPUT == "CASCADE") assign B_muxed = BCIN;
        else assign B_muxed = B;
    endgenerate

    reg signed [29:0] Ar1, Ar2;
    reg signed [24:0] Dr;
    reg signed [17:0] Br1, Br2;
    reg signed [47:0] Cr;
    reg        [4:0]  INMODEr;
    reg        [6:0]  OPMODEr;
    reg        [3:0]  ALUMODEr;
    reg        [2:0]  CARRYINSELr;

    generate
        // Configurable A register
        if (AREG == 2) begin
            initial Ar1 = 30'b0;
            initial Ar2 = 30'b0;
            always @(posedge CLK)
                if (RSTA) begin
                    Ar1 <= 30'b0;
                    Ar2 <= 30'b0;
                end else begin
                    if (CEA1) Ar1 <= A_muxed;
                    if (CEA2) Ar2 <= Ar1;
                end
        end else if (AREG == 1) begin
            //initial Ar1 = 30'b0;
            initial Ar2 = 30'b0;
            always @(posedge CLK)
                if (RSTA) begin
                    Ar1 <= 30'b0;
                    Ar2 <= 30'b0;
                end else begin
                    if (CEA1) Ar1 <= A_muxed;
                    if (CEA2) Ar2 <= A_muxed;
                end
        end else begin
            always @* Ar1 <= A_muxed;
            always @* Ar2 <= A_muxed;
        end

        // Configurable B register
        if (BREG == 2) begin
            initial Br1 = 25'b0;
            initial Br2 = 25'b0;
            always @(posedge CLK)
                if (RSTB) begin
                    Br1 <= 18'b0;
                    Br2 <= 18'b0;
                end else begin
                    if (CEB1) Br1 <= B_muxed;
                    if (CEB2) Br2 <= Br1;
                end
        end else if (BREG == 1) begin
            //initial Br1 = 18'b0;
            initial Br2 = 18'b0;
            always @(posedge CLK)
                if (RSTB) begin
                    Br1 <= 18'b0;
                    Br2 <= 18'b0;
                end else begin
                    if (CEB1) Br1 <= B_muxed;
                    if (CEB2) Br2 <= B_muxed;
                end
        end else begin
            always @* Br1 <= B_muxed;
            always @* Br2 <= B_muxed;
        end

        // C and D registers
        if (CREG == 1) initial Cr = 48'b0;
        if (CREG == 1) begin always @(posedge CLK) if (RSTC) Cr <= 48'b0; else if (CEC) Cr <= C; end
        else           always @* Cr <= C;

	if (DREG == 1) initial Dr = 25'b0;
        if (DREG == 1) begin always @(posedge CLK) if (RSTD) Dr <= 25'b0; else if (CED) Dr <= D; end
        else           always @* Dr <= D;

        // Control registers
        if (INMODEREG == 1) initial INMODEr = 5'b0;
        if (INMODEREG == 1) begin always @(posedge CLK) if (RSTINMODE) INMODEr <= 5'b0; else if (CEINMODE) INMODEr <= INMODE; end
        else           always @* INMODEr <= INMODE;
        if (OPMODEREG == 1) initial OPMODEr = 7'b0;
        if (OPMODEREG == 1) begin always @(posedge CLK) if (RSTCTRL) OPMODEr <= 7'b0; else if (CECTRL) OPMODEr <= OPMODE; end
        else           always @* OPMODEr <= OPMODE;
        if (ALUMODEREG == 1) initial ALUMODEr = 4'b0;
        if (ALUMODEREG == 1) begin always @(posedge CLK) if (RSTALUMODE) ALUMODEr <= 4'b0; else if (CEALUMODE) ALUMODEr <= ALUMODE; end
        else           always @* ALUMODEr <= ALUMODE;
        if (CARRYINSELREG == 1) initial CARRYINSELr = 3'b0;
        if (CARRYINSELREG == 1) begin always @(posedge CLK) if (RSTCTRL) CARRYINSELr <= 3'b0; else if (CECTRL) CARRYINSELr <= CARRYINSEL; end
        else           always @* CARRYINSELr <= CARRYINSEL;
    endgenerate

    // A and B cascade
    generate
        if (ACASCREG == 1 && AREG == 2) assign ACOUT = Ar1;
        else assign ACOUT = Ar2;
        if (BCASCREG == 1 && BREG == 2) assign BCOUT = Br1;
        else assign BCOUT = Br2;
    endgenerate

    // A/D input selection and pre-adder
    wire signed [24:0] Ar12_muxed = INMODEr[0] ? Ar1 : Ar2;
    wire signed [24:0] Ar12_gated = INMODEr[1] ? 25'b0 : Ar12_muxed;
    wire signed [24:0] Dr_gated   = INMODEr[2] ? Dr : 25'b0;
    wire signed [24:0] AD_result  = INMODEr[3] ? (Dr_gated - Ar12_gated) : (Dr_gated + Ar12_gated);
    reg  signed [24:0] ADr;

    generate
        if (ADREG == 1) initial ADr = 25'b0;
        if (ADREG == 1) begin always @(posedge CLK) if (RSTD) ADr <= 25'b0; else if (CEAD) ADr <= AD_result; end
        else            always @* ADr <= AD_result;
    endgenerate

    // 25x18 multiplier
    wire signed [24:0] A_MULT;
    wire signed [17:0] B_MULT = INMODEr[4] ? Br1 : Br2;
    generate
        if (USE_DPORT == "TRUE") assign A_MULT = ADr;
        else assign A_MULT = Ar12_gated;
    endgenerate

    wire signed [42:0] M = A_MULT * B_MULT;
    wire signed [42:0] Mx = (CARRYINSEL == 3'b010) ? 43'bx : M;
    reg  signed [42:0] Mr = 43'b0;

    // Multiplier result register
    generate
        if (MREG == 1) begin always @(posedge CLK) if (RSTM) Mr <= 43'b0; else if (CEM) Mr <= Mx; end
        else           always @* Mr <= Mx;
    endgenerate

    wire signed [42:0] Mrx = (CARRYINSELr == 3'b010) ? 43'bx : Mr;

    // X, Y and Z ALU inputs
    reg signed [47:0] X, Y, Z;

    always @* begin
        // X multiplexer
        case (OPMODEr[1:0])
            2'b00: X = 48'b0;
            2'b01: begin X = $signed(Mrx);
                if (OPMODEr[3:2] != 2'b01) $fatal(1, "OPMODEr[3:2] must be 2'b01 when OPMODEr[1:0] is 2'b01");
            end
            2'b10:
                if (PREG == 1)
                    X = P;
                else begin
                    X = 48'bx;
                    $fatal(1, "PREG must be 1 when OPMODEr[1:0] is 2'b10");
                end
            2'b11: X = $signed({Ar2, Br2});
            default: X = 48'bx;
        endcase

        // Y multiplexer
        case (OPMODEr[3:2])
            2'b00: Y = 48'b0;
            2'b01: begin Y = 48'b0; // FIXME: more accurate partial product modelling?
                if (OPMODEr[1:0] != 2'b01) $fatal(1, "OPMODEr[1:0] must be 2'b01 when OPMODEr[3:2] is 2'b01");
            end
            2'b10: Y = {48{1'b1}};
            2'b11: Y = Cr;
            default: Y = 48'bx;
        endcase

        // Z multiplexer
        case (OPMODEr[6:4])
            3'b000: Z = 48'b0;
            3'b001: Z = PCIN;
            3'b010:
                if (PREG == 1)
                    Z = P;
                else begin
                    Z = 48'bx;
                    $fatal(1, "PREG must be 1 when OPMODEr[6:4] is 3'b010");
                end
            3'b011: Z = Cr;
            3'b100:
                if (PREG == 1 && OPMODEr[3:0] === 4'b1000)
                    Z = P;
                else begin
                    Z = 48'bx;
                    if (PREG != 1) $fatal(1, "PREG must be 1 when OPMODEr[6:4] is 3'b100");
                    if (OPMODEr[3:0] != 4'b1000) $fatal(1, "OPMODEr[3:0] must be 4'b1000 when OPMODEr[6:4] i0s 3'b100");
                end
            3'b101: Z = $signed(PCIN[47:17]);
            3'b110:
                if (PREG == 1)
                    Z = $signed(P[47:17]);
                else begin
                    Z = 48'bx;
                    $fatal(1, "PREG must be 1 when OPMODEr[6:4] is 3'b110");
                end
            default: Z = 48'bx;
        endcase
    end

    // Carry in
    wire A24_xnor_B17d = A_MULT[24] ~^ B_MULT[17];
    reg CARRYINr, A24_xnor_B17;
    generate
        if (CARRYINREG == 1) initial CARRYINr = 1'b0;
        if (CARRYINREG == 1) begin always @(posedge CLK) if (RSTALLCARRYIN) CARRYINr <= 1'b0; else if (CECARRYIN) CARRYINr <= CARRYIN; end
        else                 always @* CARRYINr = CARRYIN;

        if (MREG == 1) initial A24_xnor_B17 = 1'b0;
        if (MREG == 1) begin always @(posedge CLK) if (RSTALLCARRYIN) A24_xnor_B17 <= 1'b0; else if (CEM) A24_xnor_B17 <= A24_xnor_B17d; end
        else                 always @* A24_xnor_B17 = A24_xnor_B17d;
    endgenerate

    reg cin_muxed;

    always @(*) begin
        case (CARRYINSELr)
            3'b000: cin_muxed = CARRYINr;
            3'b001: cin_muxed = ~PCIN[47];
            3'b010: cin_muxed = CARRYCASCIN;
            3'b011: cin_muxed = PCIN[47];
            3'b100:
                if (PREG == 1)
                    cin_muxed = CARRYCASCOUT;
                else begin
                    cin_muxed = 1'bx;
                    $fatal(1, "PREG must be 1 when CARRYINSEL is 3'b100");
                end
            3'b101:
                if (PREG == 1)
                    cin_muxed = ~P[47];
                else begin
                    cin_muxed = 1'bx;
                    $fatal(1, "PREG must be 1 when CARRYINSEL is 3'b101");
                end
            3'b110: cin_muxed = A24_xnor_B17;
            3'b111:
                if (PREG == 1)
                    cin_muxed = P[47];
                else begin
                    cin_muxed = 1'bx;
                    $fatal(1, "PREG must be 1 when CARRYINSEL is 3'b111");
                end
            default: cin_muxed = 1'bx;
        endcase
    end

    wire alu_cin = (ALUMODEr[3] || ALUMODEr[2]) ? 1'b0 : cin_muxed;

    // ALU core
    wire [47:0] Z_muxinv = ALUMODEr[0] ? ~Z : Z;
    wire [47:0] xor_xyz = X ^ Y ^ Z_muxinv;
    wire [47:0] maj_xyz = (X & Y) | (X & Z_muxinv) | (Y & Z_muxinv);

    wire [47:0] xor_xyz_muxed = ALUMODEr[3] ? maj_xyz : xor_xyz;
    wire [47:0] maj_xyz_gated = ALUMODEr[2] ? 48'b0 :  maj_xyz;

    wire [48:0] maj_xyz_simd_gated;
    wire [3:0] int_carry_in, int_carry_out, ext_carry_out;
    wire [47:0] alu_sum;
    assign int_carry_in[0] = 1'b0;
    wire [3:0] carryout_reset;

    generate
        if (USE_SIMD == "FOUR12") begin
            assign maj_xyz_simd_gated = {
                    maj_xyz_gated[47:36],
                    1'b0, maj_xyz_gated[34:24],
                    1'b0, maj_xyz_gated[22:12],
                    1'b0, maj_xyz_gated[10:0],
                    alu_cin
                };
            assign int_carry_in[3:1] = 3'b000;
            assign ext_carry_out = {
                    int_carry_out[3],
                    maj_xyz_gated[35] ^ int_carry_out[2],
                    maj_xyz_gated[23] ^ int_carry_out[1],
                    maj_xyz_gated[11] ^ int_carry_out[0]
                };
            assign carryout_reset = 4'b0000;
        end else if (USE_SIMD == "TWO24") begin
            assign maj_xyz_simd_gated = {
                    maj_xyz_gated[47:24],
                    1'b0, maj_xyz_gated[22:0],
                    alu_cin
                };
            assign int_carry_in[3:1] = {int_carry_out[2], 1'b0, int_carry_out[0]};
            assign ext_carry_out = {
                    int_carry_out[3],
                    1'bx,
                    maj_xyz_gated[23] ^ int_carry_out[1],
                    1'bx
                };
            assign carryout_reset = 4'b0x0x;
        end else begin
            assign maj_xyz_simd_gated = {maj_xyz_gated, alu_cin};
            assign int_carry_in[3:1] = int_carry_out[2:0];
            assign ext_carry_out = {
                    int_carry_out[3],
                    3'bxxx
                };
            assign carryout_reset = 4'b0xxx;
        end

        genvar i;
        for (i = 0; i < 4; i = i + 1)
            assign {int_carry_out[i], alu_sum[i*12 +: 12]} = {1'b0, maj_xyz_simd_gated[i*12 +: ((i == 3) ? 13 : 12)]}
                                                              + xor_xyz_muxed[i*12 +: 12] + int_carry_in[i];
    endgenerate

    wire signed [47:0] Pd = ALUMODEr[1] ? ~alu_sum : alu_sum;
    wire [3:0] CARRYOUTd = (OPMODEr[3:0] == 4'b0101 || ALUMODEr[3:2] != 2'b00) ? 4'bxxxx :
                           ((ALUMODEr[0] & ALUMODEr[1]) ? ~ext_carry_out : ext_carry_out);
    wire CARRYCASCOUTd = ext_carry_out[3];
    wire MULTSIGNOUTd = Mrx[42];

    generate
        if (PREG == 1) begin
            initial P = 48'b0;
            initial CARRYOUT = carryout_reset;
            initial CARRYCASCOUT = 1'b0;
            initial MULTSIGNOUT = 1'b0;
            always @(posedge CLK)
                if (RSTP) begin
                    P <= 48'b0;
                    CARRYOUT <= carryout_reset;
                    CARRYCASCOUT <= 1'b0;
                    MULTSIGNOUT <= 1'b0;
                end else if (CEP) begin
                    P <= Pd;
                    CARRYOUT <= CARRYOUTd;
                    CARRYCASCOUT <= CARRYCASCOUTd;
                    MULTSIGNOUT <= MULTSIGNOUTd;
                end
        end else begin
            always @* begin
                P = Pd;
                CARRYOUT = CARRYOUTd;
                CARRYCASCOUT = CARRYCASCOUTd;
                MULTSIGNOUT = MULTSIGNOUTd;
            end
        end
    endgenerate

    assign PCOUT = P;

    generate
        wire PATTERNDETECTd, PATTERNBDETECTd;

        if (USE_PATTERN_DETECT == "PATDET") begin
            // TODO: Support SEL_PATTERN != "PATTERN" and SEL_MASK != "MASK
            assign PATTERNDETECTd = &(~(Pd ^ PATTERN) | MASK);
            assign PATTERNBDETECTd = &((Pd ^ PATTERN) | MASK);
        end else begin
            assign PATTERNDETECTd = 1'b1;
            assign PATTERNBDETECTd = 1'b1;
        end

        if (PREG == 1) begin
            reg PATTERNDETECTPAST, PATTERNBDETECTPAST;
            initial PATTERNDETECT = 1'b0;
            initial PATTERNBDETECT = 1'b0;
            initial PATTERNDETECTPAST = 1'b0;
            initial PATTERNBDETECTPAST = 1'b0;
            always @(posedge CLK)
                if (RSTP) begin
                    PATTERNDETECT <= 1'b0;
                    PATTERNBDETECT <= 1'b0;
                    PATTERNDETECTPAST <= 1'b0;
                    PATTERNBDETECTPAST <= 1'b0;
                end else if (CEP) begin
                    PATTERNDETECT <= PATTERNDETECTd;
                    PATTERNBDETECT <= PATTERNBDETECTd;
                    PATTERNDETECTPAST <= PATTERNDETECT;
                    PATTERNBDETECTPAST <= PATTERNBDETECT;
                end
            assign OVERFLOW = &{PATTERNDETECTPAST, ~PATTERNBDETECT, ~PATTERNDETECT};
            assign UNDERFLOW = &{PATTERNBDETECTPAST, ~PATTERNBDETECT, ~PATTERNDETECT};
        end else begin
            always @* begin
                PATTERNDETECT = PATTERNDETECTd;
                PATTERNBDETECT = PATTERNBDETECTd;
            end
            assign OVERFLOW = 1'bx, UNDERFLOW = 1'bx;
        end
    endgenerate

endmodule
