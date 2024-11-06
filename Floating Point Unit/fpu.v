module fpu (
    input wire clk_i,
    input wire [31:0] opa_i,
    input wire [31:0] opb_i,
    input wire [2:0] fpu_op_i,
    input wire [1:0] rmode_i,
	 input wire start_i,
    output [31:0] output_o,
    output reg ready_o,
    output ine_o,
    output overflow_o,
    output underflow_o,
    output div_zero_o,
    output inf_o,
    output zero_o,
    output qnan_o,
    output snan_o
);

	parameter EXP_WIDTH = 7; // Assuming EXP_WIDTH is 7
	parameter FP_WIDTH = 32; // Assuming FP_WIDTH is 32
	parameter FRAC_WIDTH = 23; // Assuming FRAC_WIDTH is 23
	parameter [30:0] ZERO_VECTOR = 31'b0000000000000000000000000000000;
	parameter [30:0] INF = 31'b1111111100000000000000000000000;
	parameter [30:0] QNAN = 31'b1111111110000000000000000000000;
	parameter [30:0] SNAN = 31'b1111111100000000000000000000001;

parameter MUL_SERIAL = 0;
parameter MUL_COUNT = 11;

// Input/output registers
reg [FP_WIDTH-1:0] s_opa_i, s_opb_i;
reg [2:0] s_fpu_op_i;
reg [1:0] s_rmode_i;
wire [FP_WIDTH-1:0] s_output_o, s_output1;
reg s_ine_o, s_overflow_o, s_underflow_o, s_div_zero_o, s_inf_o, s_zero_o, s_qnan_o, s_snan_o;

// FSM state
parameter waiting = 1'b0;
parameter busy = 1'b1;
reg s_state;
reg s_start_i;
reg [2:0] s_count;

// Add/Substract units signals
wire [27:0] prenorm_addsub_fracta_28_o, prenorm_addsub_fractb_28_o;
wire [7:0] prenorm_addsub_exp_o;
wire [27:0] addsub_fract_o;
wire [26:0] sum_o1;
wire co_o1;
wire addsub_sign_o;
wire [31:0] postnorm_addsub_output_o;
wire postnorm_addsub_ine_o;
wire sign_o1;
wire fasu_op;

// Multiply units signals
wire [9:0] pre_norm_mul_exp_10;
wire [23:0] pre_norm_mul_fracta_24, pre_norm_mul_fractb_24;
wire pre_norm_mul_sign;
wire [1:0] pre_norm_mul_exp_ovf;
wire [47:0] mul_24_fract_48;
wire mul_24_sign;
wire [47:0] serial_mul_fract_48;
wire [31:0] post_norm_mul_output;

// Division units signals
wire [49:0] pre_norm_div_dvdnd;
wire [26:0] pre_norm_div_dvsor;
wire [EXP_WIDTH+1:0] pre_norm_div_exp;
wire [26:0] serial_div_qutnt, serial_div_rmndr;
wire serial_div_sign, serial_div_div_zero;
wire [31:0] post_norm_div_output;
wire post_norm_div_ine;

wire s_infa, s_infb;

initial begin
	s_count = 3'b000;
end

pre_norm_addsub2 pre_norm_addsub_inst (
    .clk(clk_i),
	 .add (!s_fpu_op_i[0]),
    .opa(s_opa_i),
    .opb(s_opb_i),
    .fracta_out(prenorm_addsub_fracta_28_o),
    .fractb_out(prenorm_addsub_fractb_28_o),
    .exp_dn_out(prenorm_addsub_exp_o),
	 .sign (sign_o1),
	 .fasu_op (fasu_op)
);

addsub_281 addsub_inst(
	 .add (fasu_op),
	 .opa (prenorm_addsub_fracta_28_o),
	 .opb (prenorm_addsub_fractb_28_o),
	 .sum (sum_o1),
	 .co (co_o1)
);

assign addsub_fract_o = {co_o1, sum_o1};

post_norm_addsub post_norm_addsub_inst (
    .clk_i(clk_i),
    .opa_i(s_opa_i),
    .opb_i(s_opb_i),
    .fract_28_i(addsub_fract_o),
    .exp_i(prenorm_addsub_exp_o),
    .sign_i(sign_o1),
    .fpu_op_i(s_fpu_op_i[0]),
    .rmode_i(s_rmode_i),
    .output_o(postnorm_addsub_output_o),
    .ine_o(postnorm_addsub_ine_o)
);

// Multiply Units

pre_norm_mul1 pre_norm_mul_inst (
    .clk_i(clk_i),
    .opa_i(s_opa_i),
    .opb_i(s_opb_i),
    .exp_10_o(pre_norm_mul_exp_10),
    .fracta_24_o(pre_norm_mul_fracta_24),
    .fractb_24_o(pre_norm_mul_fractb_24),
	 .sign(pre_norm_mul_sign),
	 .exp_ovf(pre_norm_mul_exp_ovf)
	 
);

mul mul_inst(
	.clk_i(clk_i),
	.fracta_i(pre_norm_mul_fracta_24),
	.fractb_i(pre_norm_mul_fractb_24),
	.fract_o(serial_mul_fract_48)
);

post_norm_mul1 post_norm_mul_inst (
    .clk_i(clk_i),
    .opa_i(s_opa_i),
    .opb_i(s_opb_i),
    .exp_10_i(pre_norm_mul_exp_10),
    .fract_48_i(serial_mul_fract_48),
    .rmode_i(s_rmode_i),
	 .exp_ovf(pre_norm_mul_exp_ovf),
	 .sign_i(pre_norm_mul_sign),
    .output_o(post_norm_mul_output)
);


// Input Register
always @(posedge clk_i) begin
    if (start_i) begin
        s_opa_i <= opa_i;
        s_opb_i <= opb_i;
        s_fpu_op_i <= fpu_op_i;
        s_rmode_i <= rmode_i;
        s_start_i <= start_i;
    end
end


// FSM
always @(posedge clk_i) begin
	if(start_i) begin
		s_state<=busy;
		if(s_state == 1'b1) begin
			if ((s_count == 3 && (fpu_op_i == 3'b000 || fpu_op_i == 3'b001)) ||
            (s_count == 1 && fpu_op_i == 3'b010)) begin
            s_state <= waiting;
            ready_o <= 1'b1;
            s_count <= 0;
         end else begin
				s_count <= s_count + 1'b1;
         end
		end
	end else begin
        s_state <= waiting;
        ready_o <= 1'b0;
    end
end
			


    // Output Assignment Logic
    assign s_output1 = (fpu_op_i == 3'b000 || fpu_op_i == 3'b001) ? postnorm_addsub_output_o :
                       (fpu_op_i == 3'b010) ? post_norm_mul_output :
                       {32{1'b0}};

    assign s_infa = (opa_i[30:23] == 8'hFF);
    assign s_infb = (opb_i[30:23] == 8'hFF);

    assign output_o = 
        (rmode_i == 2'b00 || div_zero_o || s_infa || s_infb || qnan_o || snan_o) ? s_output1 :
        (rmode_i == 2'b01 && s_output1[30:23] == 8'hFF) ? {s_output1[31], 8'b11111110, 22'b1111111111111111111111} :
        (rmode_i == 2'b10 && s_output1[31:23] == 9'hFF) ? 32'hFFFFFFF7 :
        (rmode_i == 2'b11) ? (
            ((fpu_op_i == 3'b000 || fpu_op_i == 3'b001) && zero_o && (opa_i[31] || (fpu_op_i[0] ^ opb_i[31]))) ? 
                {1'b1, s_output1[30:0]} :
            (s_output1[31:23] == 9'h7F) ? 
                32'b01111110111111111111111111111111 :
                s_output1
        ) : s_output1;

    assign ine_o = (fpu_op_i == 3'b000 || fpu_op_i == 3'b001) ? postnorm_addsub_ine_o : 1'b0;

    // Exception Logic (Combinational Logic)
    assign underflow_o = (output_o[30:23] == 8'b00000000 && ine_o);
    assign overflow_o = (output_o[30:23] == 8'b11111111 && ine_o);
    assign div_zero_o = (serial_div_div_zero && fpu_op_i == 3'b011);
    assign inf_o = (output_o[30:23] == 8'b11111111 && !(qnan_o || snan_o));
    assign zero_o = (output_o[30:0] == 31'b0);
    assign qnan_o = (output_o[30:0] == 32'b01111111111111111111111111111111);
    assign snan_o = (opa_i[30:0] == 32'b01111111111111111111111111111111 || 
                     opb_i[30:0] == 32'b01111111111111111111111111111111);

//// Output Multiplexer
//always @(posedge clk_i) begin
//    if (fpu_op_i == 3'b000 || fpu_op_i == 3'b001) begin
//        s_output1 <= postnorm_addsub_output_o;
//        s_ine_o <= postnorm_addsub_ine_o;
//    end else if (fpu_op_i == 3'b010) begin
//        s_output1 <= post_norm_mul_output;
//        s_ine_o <= 1'b0;
//    end else begin
//        s_output1 <= {FP_WIDTH{1'b0}};
//        s_ine_o <= 1'b0;
//    end
//end

//assign s_infa = (s_opa_i[30:23] == 8'hFF) ? 1'b1 : 1'b0;
//assign s_infb = (s_opb_i[30:23] == 8'hFF) ? 1'b1 : 1'b0;
//
//always @(posedge clk_i) begin
//    if (s_rmode_i == 2'b00 || s_div_zero_o || s_infa || s_infb || s_qnan_o || s_snan_o) begin
//        s_output_o <= s_output1;
//    end else if (s_rmode_i == 2'b01 && s_output1[30:23] == 8'hFF) begin
//        s_output_o <= {s_output1[31], 8'b11111110, 22'b1111111111111111111111};
//    end else if (s_rmode_i == 2'b10 && s_output1[31:23] == 9'hFF) begin
//        s_output_o <= 32'hFFFFFFF7;
//    end else if (s_rmode_i == 2'b11) begin
//        if ((s_fpu_op_i == 3'b000 || s_fpu_op_i == 3'b001) && s_zero_o && (s_opa_i[31] || (s_fpu_op_i[0] ^ s_opb_i[31]))) begin
//            s_output_o <= {1'b1, s_output1[30:0]};
//        end else if (s_output1[31:23] == 9'h7F) begin
//            s_output_o <= 32'b01111110111111111111111111111111;
//        end else begin
//            s_output_o <= s_output1;
//        end
//    end else begin
//        s_output_o <= s_output1;
//    end
//end



//// Generate Exceptions
//always @* begin
//s_underflow_o <= (s_output1[30:23] == 8'b00000000 && s_ine_o) ? 1'b1 : 1'b0;
//s_overflow_o <= (s_output1[30:23] == 8'b11111111 && s_ine_o) ? 1'b1 : 1'b0;
//s_div_zero_o <= (serial_div_div_zero && fpu_op_i == 3'b011) ? 1'b1 : 1'b0;
//s_inf_o <= (s_output1[30:23] == 8'b11111111 && !(s_qnan_o || s_snan_o)) ? 1'b1 : 1'b0;
//s_zero_o <= (|s_output1[30:0] == 1'b0) ? 1'b1 : 1'b0;
//s_qnan_o <= (s_output1[30:0] == 32'b01111111111111111111111111111111) ? 1'b1 : 1'b0;
//s_snan_o <= (s_opa_i[30:0] == 32'b01111111111111111111111111111111 || s_opb_i[30:0] == 32'b01111111111111111111111111111111) ? 1'b1 : 1'b0;
//end

endmodule
