module post_norm_mul1(
	input wire clk_i,
	input wire [31:0] opa_i,
	input wire [31:0] opb_i,
	input wire [7:0] exp_10_i,
	input wire [47:0] fract_48_i,
	input wire [1:0] rmode_i,
	input wire [1:0] exp_ovf,
	input wire sign_i,
	output [31:0] output_o
);

wire		exp_out_00, exp_out_fe, exp_out_ff, exp_in_00, exp_in_ff;
wire		exp_in_80;
wire		exp_out_final_ff,fract_out_7fffff;
wire		fract_out_00, fract_in_00;
wire	[7:0]	exp_out_final;
wire	[7:0]	exp_out;
wire	[22:0]	fract_out;
wire		rmode_00, rmode_01, rmode_10, rmode_11;
wire	[23:0]	fract_out_pl1;
wire	[8:0]	exp_in_mi1;
wire		shft_co;
wire	[7:0]	shift_right, shftr_mul;
wire	[7:0]	shift_left,  shftl_mul;
wire		left_right, lr_mul;
wire		exp_out1_co;
wire	[7:0]	conv_shft;
reg	[5:0]	fi_ldz;
wire	[8:0]	exp_in_pl1;
wire	[47:0]	fract_in_shftr;
wire	[47:0]	fract_in_shftl;
wire	[24:0]	fract_trunc;
wire	[5:0]	fi_ldz_mi1;
wire	[5:0]	fi_ldz_mi22;
wire	[7:0]	exp_out_pl1, exp_out_mi1;
wire	[7:0]	exp_out1_mi1;
wire	[7:0]	exp_out1;
wire	[8:0]	exp_next_mi;
parameter op_mul = 1'b1;
wire		exp_rnd_adj2a,exp_rnd_adj0;
wire	[7:0]	exp_i2f, exp_f2i, conv_exp;
wire	[55:0]	exp_f2i_1;
wire	[6:0]	fi_ldz_2a;
wire	[7:0]	fi_ldz_2;
wire		g, r, s;
wire		round, round2, round2a, round2_fasu, round2_fmul;
wire	[7:0]	exp_out_rnd0, exp_out_rnd1, exp_out_rnd2, exp_out_rnd2a;
wire	[22:0]	fract_out_rnd0, fract_out_rnd1, fract_out_rnd2, fract_out_rnd2a;
wire		ovf0, ovf1;
wire		expa_dn, expb_dn;
wire		op_dn = expa_dn | expb_dn;
wire	[7:0]	expa, expb;
reg	[7:0]	exp_out_rnd;
reg	[22:0]	fract_out_rnd;
wire		round2_f2i;
wire	[22:0]	fract_out_final;
wire fracta_00, fractb_00, opa_00, opb_00, mul_00;
wire [22:0] fracta, fractb;
wire	[8:0]	div_exp1;
wire	[7:0]	f2i_shft;
wire		f2i_zero, f2i_max;
wire	[7:0]	f2i_emin;
wire [30:0] out;

assign   expa = opa_i[30:23];
assign   expb = opb_i[30:23];

//
// Calculate Exponenet
//

assign fracta = opa_i[22:0];
assign fractb = opb_i[22:0];

assign expa_dn   = !(|expa);
assign expb_dn   = !(|expb);
assign fracta_00 = !(|fracta);
assign fractb_00 = !(|fractb);

assign opa_00 = expa_dn & fracta_00;
assign opb_00 = expb_dn & fractb_00;
assign mul_00 = (opa_00 | opb_00);


always @(fract_48_i)
   casex(fract_48_i)	// synopsys full_case parallel_case
	48'b1???????????????????????????????????????????????: fi_ldz =  1;
	48'b01??????????????????????????????????????????????: fi_ldz =  2;
	48'b001?????????????????????????????????????????????: fi_ldz =  3;
	48'b0001????????????????????????????????????????????: fi_ldz =  4;
	48'b00001???????????????????????????????????????????: fi_ldz =  5;
	48'b000001??????????????????????????????????????????: fi_ldz =  6;
	48'b0000001?????????????????????????????????????????: fi_ldz =  7;
	48'b00000001????????????????????????????????????????: fi_ldz =  8;
	48'b000000001???????????????????????????????????????: fi_ldz =  9;
	48'b0000000001??????????????????????????????????????: fi_ldz =  10;
	48'b00000000001?????????????????????????????????????: fi_ldz =  11;
	48'b000000000001????????????????????????????????????: fi_ldz =  12;
	48'b0000000000001???????????????????????????????????: fi_ldz =  13;
	48'b00000000000001??????????????????????????????????: fi_ldz =  14;
	48'b000000000000001?????????????????????????????????: fi_ldz =  15;
	48'b0000000000000001????????????????????????????????: fi_ldz =  16;
	48'b00000000000000001???????????????????????????????: fi_ldz =  17;
	48'b000000000000000001??????????????????????????????: fi_ldz =  18;
	48'b0000000000000000001?????????????????????????????: fi_ldz =  19;
	48'b00000000000000000001????????????????????????????: fi_ldz =  20;
	48'b000000000000000000001???????????????????????????: fi_ldz =  21;
	48'b0000000000000000000001??????????????????????????: fi_ldz =  22;
	48'b00000000000000000000001?????????????????????????: fi_ldz =  23;
	48'b000000000000000000000001????????????????????????: fi_ldz =  24;
	48'b0000000000000000000000001???????????????????????: fi_ldz =  25;
	48'b00000000000000000000000001??????????????????????: fi_ldz =  26;
	48'b000000000000000000000000001?????????????????????: fi_ldz =  27;
	48'b0000000000000000000000000001????????????????????: fi_ldz =  28;
	48'b00000000000000000000000000001???????????????????: fi_ldz =  29;
	48'b000000000000000000000000000001??????????????????: fi_ldz =  30;
	48'b0000000000000000000000000000001?????????????????: fi_ldz =  31;
	48'b00000000000000000000000000000001????????????????: fi_ldz =  32;
	48'b000000000000000000000000000000001???????????????: fi_ldz =  33;
	48'b0000000000000000000000000000000001??????????????: fi_ldz =  34;
	48'b00000000000000000000000000000000001?????????????: fi_ldz =  35;
	48'b000000000000000000000000000000000001????????????: fi_ldz =  36;
	48'b0000000000000000000000000000000000001???????????: fi_ldz =  37;
	48'b00000000000000000000000000000000000001??????????: fi_ldz =  38;
	48'b000000000000000000000000000000000000001?????????: fi_ldz =  39;
	48'b0000000000000000000000000000000000000001????????: fi_ldz =  40;
	48'b00000000000000000000000000000000000000001???????: fi_ldz =  41;
	48'b000000000000000000000000000000000000000001??????: fi_ldz =  42;
	48'b0000000000000000000000000000000000000000001?????: fi_ldz =  43;
	48'b00000000000000000000000000000000000000000001????: fi_ldz =  44;
	48'b000000000000000000000000000000000000000000001???: fi_ldz =  45;
	48'b0000000000000000000000000000000000000000000001??: fi_ldz =  46;
	48'b00000000000000000000000000000000000000000000001?: fi_ldz =  47;
	48'b00000000000000000000000000000000000000000000000?: fi_ldz =  48;
   endcase

	
assign exp_in_ff        = &exp_10_i;
assign exp_in_00        = !(|exp_10_i);
assign exp_in_80	= exp_10_i[7] & !(|exp_10_i[6:0]);
assign exp_out_ff       = &exp_out;
assign exp_out_00       = !(|exp_out);
assign exp_out_fe       = &exp_out[7:1] & !exp_out[0];
assign exp_out_final_ff = &exp_out_final;

assign fract_out_7fffff = &fract_out;
assign fract_out_00     = !(|fract_out);
assign fract_in_00      = !(|fract_48_i);

assign rmode_00 = (rmode_i==2'b00);
assign rmode_01 = (rmode_i==2'b01);
assign rmode_10 = (rmode_i==2'b10);
assign rmode_11 = (rmode_i==2'b11);


parameter	f2i_emax = 8'h9d;

// Incremented fraction for rounding
assign fract_out_pl1 = fract_out + 1;

// Special Signals for f2i
assign f2i_emin = rmode_00 ? 8'h7e : 8'h7f;
assign f2i_zero = (!opa_i[31] & (exp_10_i<f2i_emin)) | (opa_i[31] & (exp_10_i>f2i_emax)) | (opa_i[31] & (exp_10_i<f2i_emin) & (fract_in_00 | !rmode_11));
assign f2i_max = (!opa_i[31] & (exp_10_i>f2i_emax)) | (opa_i[31] & (exp_10_i<f2i_emin) & !fract_in_00 & rmode_11);

assign {shft_co,shftr_mul} = (!exp_ovf[1] & exp_in_00) ? {1'b0, exp_out} : exp_in_mi1 ;

assign f2i_shft  = exp_10_i-8'h7d;

assign left_right = lr_mul;

assign lr_mul = 	(shft_co | (!exp_ovf[1] & exp_in_00) |
			(!exp_ovf[1] & !exp_in_00 & (exp_out1_co | exp_out_00) )) ? 	1 :
			( exp_ovf[1] | exp_in_00 ) ?					0 :
											1;
											
assign shift_right = shftr_mul;
assign conv_shft = {2'h0, fi_ldz};
assign shift_left  = shftl_mul;

assign shftl_mul = 	(shft_co |
			(!exp_ovf[1] & exp_in_00) |
			(!exp_ovf[1] & !exp_in_00 & (exp_out1_co | exp_out_00))) ? exp_in_pl1[7:0] : {2'h0, fi_ldz};
			
assign fract_in_shftr   = (|shift_right[7:6])                      ? 0 : fract_48_i>>shift_right[5:0];
assign fract_in_shftl   = (|shift_left[7:6] | (f2i_zero & 1'b0)) ? 0 : fract_48_i<<shift_left[5:0];

// Chose final fraction output
assign {fract_out,fract_trunc} = left_right ? fract_in_shftl : fract_in_shftr;

// Exponent Normalization

assign fi_ldz_mi1    = fi_ldz - 1;
assign fi_ldz_mi22   = fi_ldz - 22;
assign exp_out_pl1   = exp_out + 1;
assign exp_out_mi1   = exp_out - 1;
assign exp_in_pl1    = exp_10_i  + 1;	// 9 bits - includes carry out
assign exp_in_mi1    = exp_10_i  - 1;	// 9 bits - includes carry out
assign exp_out1_mi1  = exp_out1 - 1;

assign exp_next_mi  = exp_in_pl1 - fi_ldz_mi1;	// 9 bits - includes carry out

assign exp_zero  = (exp_ovf[1] & !exp_ovf[0] & op_mul & (!exp_rnd_adj2a | !rmode_i[1])) | (op_mul & exp_out1_co);
assign {exp_out1_co, exp_out1} = fract_48_i[47] ? exp_in_pl1 : exp_next_mi;

assign f2i_out_sign =  !opa_i[31] ? ((exp_10_i<f2i_emin) ? 0 : (exp_10_i>f2i_emax) ? 0 : opa_i[31]) :
			       ((exp_10_i<f2i_emin) ? 0 : (exp_10_i>f2i_emax) ? 1 : opa_i[31]);

assign exp_i2f   = fract_in_00 ? (opa_i[31] ? 8'h9e : 0) : (8'h9e-fi_ldz);
assign exp_f2i_1 = {{8{fract_48_i[47]}}, fract_48_i }<<f2i_shft;
assign exp_f2i   = f2i_zero ? 0 : f2i_max ? 8'hff : exp_f2i_1[55:48];
assign conv_exp  = exp_i2f;

assign div_exp1  = exp_in_mi1 + fi_ldz_2;	// 9 bits - includes carry out
assign exp_out = exp_zero ? 8'h0 : exp_out1;

assign fi_ldz_2a = 6'd23 - fi_ldz;
assign fi_ldz_2  = {fi_ldz_2a[6], fi_ldz_2a[6:0]};

assign div_inf = expb_dn & !expa_dn & (div_exp1[7:0] < 8'h7f);

assign g = fract_out[0];
assign r = fract_trunc[24];
assign s = (|fract_trunc[23:0] | (fract_trunc[24] & 1'b0));

// Round to nearest even
assign round = (g & r) | (r & s) ;
assign {exp_rnd_adj0, fract_out_rnd0} = round ? fract_out_pl1 : {1'b0, fract_out};
assign exp_out_rnd0 =  exp_rnd_adj0 ? exp_out_pl1 : exp_out;
assign ovf0 = exp_out_final_ff & !rmode_01 & !1'b0;

// round to zero
assign fract_out_rnd1 = (exp_out_ff & !1'b0 & !1'b0  & !1'b0) ? 23'h7fffff : fract_out;
assign exp_out_rnd1   = (g & r & s & exp_in_ff) ? (exp_next_mi[7:0]) :
			(exp_out_ff & !1'b0 ) ? exp_10_i : exp_out;
assign ovf1 = exp_out_ff & !1'b0;

// round to +inf (UP) and -inf (DOWN)
assign r_sign = sign_i;

assign round2a = !exp_out_fe | !fract_out_7fffff | (exp_out_fe & fract_out_7fffff);
assign round2_fasu = ((r | s) & !r_sign) & (!exp_out[7] | (exp_out[7] & round2a));

assign round2_fmul = !r_sign & 
		(
			(exp_ovf[1] & !fract_in_00 &
				( ((!exp_out1_co | op_dn) & (r | s | (!1'b0 & 1'b0) )) | fract_out_00 | (!op_dn & !1'b0))
			 ) |
			(
				(r | s | (!1'b0 & 1'b0)) & (
						(!exp_ovf[1] & (exp_in_80 | !exp_ovf[0])) | 1'b0 |
						( exp_ovf[1] & !exp_ovf[0] & exp_out1_co)
					)
			)
		);

assign round2_f2i = rmode_10 & (( |fract_48_i[23:0] & !opa_i[31] & (exp_10_i<8'h80 )) | (|fract_trunc));
assign round2 = round2_fmul;

assign {exp_rnd_adj2a, fract_out_rnd2a} = round2 ? fract_out_pl1 : {1'b0, fract_out};
assign exp_out_rnd2a  = exp_rnd_adj2a ? ((exp_ovf[1] & op_mul) ? exp_out_mi1 : exp_out_pl1) : exp_out;

assign fract_out_rnd2 = (r_sign & exp_out_ff & !1'b0 & !1'b0 & !1'b0) ? 23'h7fffff : fract_out_rnd2a;
assign exp_out_rnd2   = (r_sign & exp_out_ff & !1'b0) ? 8'hfe      : exp_out_rnd2a;

// Choose rounding mode
always @(rmode_i or exp_out_rnd0 or exp_out_rnd1 or exp_out_rnd2)
	case(rmode_i)
	   0: exp_out_rnd = exp_out_rnd0;
	   1: exp_out_rnd = exp_out_rnd1;
	 2,3: exp_out_rnd = exp_out_rnd2;
	endcase

always @(rmode_i or fract_out_rnd0 or fract_out_rnd1 or fract_out_rnd2)
	case(rmode_i)	
	   0: fract_out_rnd = fract_out_rnd0;
	   1: fract_out_rnd = fract_out_rnd1;
	 2,3: fract_out_rnd = fract_out_rnd2;
	endcase
	
// ---------------------------------------------------------------------
// Final Output Mux
// Fix Output for denormalized and special numbers
wire	max_num, inf_out;

assign	max_num =  ( !rmode_00 & (1'b1 ) & (
							  ( exp_ovf[1] &  exp_ovf[0]) |
							  (!exp_ovf[1] & !exp_ovf[0] & exp_in_ff & (fi_ldz_2<24) & (exp_out!=8'hfe) )
							  )
		   ) |

		   ( 1'b0 & (
				   ( rmode_01 & ( div_inf |
							 (exp_out_ff & !exp_ovf[1] ) |
							 (exp_ovf[1] &  exp_ovf[0] )
						)
				   ) |
		
				   ( rmode_i[1] & !exp_ovf[1] & (
								   ( exp_ovf[0] & exp_in_ff & r_sign & fract_48_i[47]
								   ) |
						
								   (  r_sign & (
										(fract_48_i[47] & div_inf) |
										(exp_10_i[7] & !exp_out_rnd[7] & !exp_in_80 & exp_out!=8'h7f ) |
										(exp_10_i[7] &  exp_out_rnd[7] & r_sign & exp_out_ff & op_dn &
											 div_exp1>9'h0fe )
										)
								   ) |

								   ( exp_in_00 & r_sign & (
												div_inf |
												(r_sign & exp_out_ff & fi_ldz_2<24)
											  )
								   )
							       )
				  )
			    )
		   );


assign inf_out = (rmode_i[1] & (1'b1) & !r_sign & (	(exp_in_ff & !1'b0) |
								(exp_ovf[1] & exp_ovf[0] & (exp_in_00 | exp_10_i[7]) ) 
							   )
		) | (div_inf & 1'b0 & (
				 rmode_00 |
				(rmode_i[1] & !exp_in_ff & !exp_ovf[1] & !exp_ovf[0] & !r_sign ) |
				(rmode_i[1] & !exp_ovf[1] & exp_ovf[0] & exp_in_00 & !r_sign)
				)
		) | (1'b0 & rmode_i[1] & exp_in_ff & op_dn & !r_sign & (fi_ldz_2 < 24)  & (exp_out_rnd!=8'hfe) );

assign fract_out_final =	(inf_out | ovf0 | mul_00 ) ? 23'h0 :
				(max_num | (f2i_max & 1'b0) ) ? 23'h7fffff :
				fract_out_rnd;

assign exp_out_final =	((1'b0 & exp_ovf[1] & !exp_ovf[0]) | mul_00 ) ? 8'h00 :
			((1'b0 & exp_ovf[1] &  exp_ovf[0] & rmode_00) | inf_out | (f2i_max & 1'b0) ) ? 8'hff :
			max_num ? 8'hfe :
			exp_out_rnd;


// ---------------------------------------------------------------------
// Pack Result

assign out = {exp_out_final, fract_out_final};
assign output_o = {sign_i, out};

endmodule
