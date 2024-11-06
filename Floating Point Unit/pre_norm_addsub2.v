module pre_norm_addsub2 (
    input        clk,
    input        add,
    input  [31:0] opa, opb,
    output reg [26:0] fracta_out, fractb_out,
    output reg [7:0]  exp_dn_out,
    output reg   sign,
	 output reg	fasu_op
);

reg add_d;


//
// Aliases
//
    wire signa = opa[31];
    wire signb = opb[31];
    wire [7:0] expa = opa[30:23];
    wire [7:0] expb = opb[30:23];
    wire [22:0] fracta = opa[22:0];
    wire [22:0] fractb = opb[22:0];
	 
// Normalize
    wire expa_dn = !(|expa);
    wire expb_dn = !(|expb);
	 
// Calculate the difference between the smaller and larger exponent
    wire expa_lt_expb = expa > expb;
    wire [7:0] exp_small = expa_lt_expb ? expb : expa;
    wire [7:0] exp_large = expa_lt_expb ? expa : expb;
    wire [7:0] exp_diff = exp_large - exp_small;
    wire [7:0] adjusted_exp_diff = (expa_dn | expb_dn) ? (exp_diff - 1) : exp_diff;
    wire [7:0] final_exp_diff = (expa_dn & expb_dn) ? 8'h0 : adjusted_exp_diff;

// If numbers are equal we should return zero
    always @(posedge clk) begin
        exp_dn_out <= (!add_d & expa == expb & fracta == fractb) ? 8'h0 : exp_large;
    end

// Adjust the smaller fraction
    wire op_dn = expa_lt_expb ? expb_dn : expa_dn;
    wire [22:0] adj_op = expa_lt_expb ? fractb : fracta;
    wire [26:0] adj_op_tmp = { ~op_dn, adj_op, 3'b0 };
	 

// adj_op_out is 27 bits wide, so can only be shifted 27 bits to the right
    wire exp_lt_27 = final_exp_diff > 8'd27;
    wire [4:0] exp_diff_sft = exp_lt_27 ? 5'd27 : final_exp_diff[4:0];
    wire [26:0] adj_op_out_sft = adj_op_tmp >> exp_diff_sft;
	reg		sticky;
	
// Get truncated portion (sticky bit)
always @(exp_diff_sft or adj_op_tmp)
   case(exp_diff_sft)		// synopsys full_case parallel_case
	00: sticky = 1'h0;
	01: sticky =  adj_op_tmp[0]; 
	02: sticky = |adj_op_tmp[01:0];
	03: sticky = |adj_op_tmp[02:0];
	04: sticky = |adj_op_tmp[03:0];
	05: sticky = |adj_op_tmp[04:0];
	06: sticky = |adj_op_tmp[05:0];
	07: sticky = |adj_op_tmp[06:0];
	08: sticky = |adj_op_tmp[07:0];
	09: sticky = |adj_op_tmp[08:0];
	10: sticky = |adj_op_tmp[09:0];
	11: sticky = |adj_op_tmp[10:0];
	12: sticky = |adj_op_tmp[11:0];
	13: sticky = |adj_op_tmp[12:0];
	14: sticky = |adj_op_tmp[13:0];
	15: sticky = |adj_op_tmp[14:0];
	16: sticky = |adj_op_tmp[15:0];
	17: sticky = |adj_op_tmp[16:0];
	18: sticky = |adj_op_tmp[17:0];
	19: sticky = |adj_op_tmp[18:0];
	20: sticky = |adj_op_tmp[19:0];
	21: sticky = |adj_op_tmp[20:0];
	22: sticky = |adj_op_tmp[21:0];
	23: sticky = |adj_op_tmp[22:0];
	24: sticky = |adj_op_tmp[23:0];
	25: sticky = |adj_op_tmp[24:0];
	26: sticky = |adj_op_tmp[25:0];
	27: sticky = |adj_op_tmp[26:0];
   endcase
	
	wire [26:0] adj_op_out = { adj_op_out_sft[26:1], adj_op_out_sft[0] | sticky };

// Select operands for add/sub (recover hidden bit)
    wire [26:0] fracta_n = expa_lt_expb ? {~expa_dn, fracta, 3'b0} : adj_op_out;
    wire [26:0] fractb_n = expa_lt_expb ? adj_op_out : {~expb_dn, fractb, 3'b0};

// Sort operands (for sub only)
    wire fractb_lt_fracta = fractb_n > fracta_n;
    wire [26:0] fracta_s = fractb_lt_fracta ? fractb_n : fracta_n;
    wire [26:0] fractb_s = fractb_lt_fracta ? fracta_n : fractb_n;
	 
    always @(posedge clk) begin
        fracta_out <= fracta_s;
        fractb_out <= fractb_s;
    end

// Determine sign for the output
// sign: 0=Positive Number; 1=Negative Number
    reg sign_d;
    always @* begin
        case ({signa, signb, add})
            3'b0_0_1: sign_d = 0;
            3'b0_1_1: sign_d = fractb_lt_fracta;
            3'b1_0_1: sign_d = !fractb_lt_fracta;
            3'b0_0_0: sign_d = fractb_lt_fracta;
            3'b1_1_0: sign_d = !fractb_lt_fracta;
            3'b0_1_0: sign_d = 0;
            3'b1_0_0: sign_d = 1;
				3'b1_1_1: sign_d = 1;
        endcase
    end

    always @(posedge clk) begin
        sign <= sign_d;
    end

    always @* begin
        case ({signa, signb, add})
            3'b0_0_1, 3'b1_1_1, 3'b0_1_0, 3'b1_0_0: add_d = 1;
            3'b0_1_1, 3'b1_0_1, 3'b0_0_0, 3'b1_1_0: add_d = 0;
        endcase
    end
	 
	always @(posedge clk)
		fasu_op <= #1 add_d;

endmodule
