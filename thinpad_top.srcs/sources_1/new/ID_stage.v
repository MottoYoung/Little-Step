module ID_stage(
    input  wire        clk,
    input  wire        reset,
    input  wire        EX_allow_in,
    input  wire        IF_to_ID_valid,
    input wire [63:0] IF_ID_reg,
    input wire [37:0] WB_rf_reg,
    input wire [4:0]  EX_dest_reg,
    input wire [4:0]  MEM_dest_reg,
    input wire [4:0]  WB_dest_reg,
    input wire     EX_load,
    output ID_allow_in,//for_wb_use
    output wire [153:0] ID_EX_reg,
    output  [35:0]ID_br_reg,
    output wire ID_to_EX_valid,
    output wire to_EX_inst_bl,
    input wire [31:0]fw_alu_result,
    input wire [31:0]fw_mem_final_result,
    input wire [31:0]fw_WB_final_result,
    input wire EX_br_taken,
    output wire ID_block
);

reg [31:0] ID_pc;
reg [31:0] ID_inst;
wire [31:0] ID_br_target;
wire ID_br_taken;
reg delay_slot;
//wire inst_beq_bne;

reg ID_valid;
wire ID_ready_go;

//alu_control_defination
wire [12:0] alu_op;
wire        src1_is_pc;
wire        src2_is_imm;
wire        src2_is_4;//same as src2_is_pc;

//rf_control_defination
//(wb)
wire        res_from_mem;
wire        dst_is_r1;
wire        gr_we;
wire        mem_we;
wire [4: 0] dest;
//read
wire        src_reg_is_rd;
wire        src_reg_is_rj;
wire        src_reg_is_rk;

//data_and_addr_defination
wire [31:0] rj_value;
wire [31:0] rkd_value;
wire [31:0] imm;
//br_data_defination
wire [31:0] br_offs;
wire [31:0] jirl_offs;

wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;
wire        rf_we   ;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;

//inst_decoder_related
wire [ 5:0] op_31_26;
wire [ 3:0] op_25_22;
wire [ 1:0] op_21_20;
wire [ 4:0] op_19_15;
wire [ 4:0] rd;
wire [ 4:0] rj;
wire [ 4:0] rk;
wire [11:0] i12;
wire [19:0] i20;
wire [15:0] i16;
wire [25:0] i26;

wire [63:0] op_31_26_d;
wire [15:0] op_25_22_d;
wire [ 3:0] op_21_20_d;
wire [31:0] op_19_15_d;

wire        inst_add_w;
wire        inst_sub_w;
wire        inst_srl_w;
wire        inst_slt;
wire        inst_slti;
wire        inst_sltu;
wire        inst_nor;
wire        inst_and;
wire        inst_andi;
wire        inst_or;
wire        inst_ori;
wire        inst_xor;
wire        inst_slli_w;
wire        inst_srli_w;
wire        inst_srai_w;
wire        inst_addi_w;
wire        inst_ld_w;
wire        inst_ld_b;
wire        inst_st_w;
wire        inst_st_b;
wire        inst_jirl;
wire        inst_b;
wire        inst_bl;
wire        inst_beq;
wire        inst_bne;
wire        inst_blt;
wire        inst_lu12i_w;
wire        inst_pcaddu12i;
wire        inst_mul_w;


wire        need_ui5;
wire        need_si12;
wire        need_si16;
wire        need_si20;
wire        need_si26;

assign op_31_26  = ID_inst[31:26];
assign op_25_22  = ID_inst[25:22];
assign op_21_20  = ID_inst[21:20];
assign op_19_15  = ID_inst[19:15];

assign rd   = ID_inst[ 4: 0];
assign rj   = ID_inst[ 9: 5];
assign rk   = ID_inst[14:10];

wire same_rj;
wire same_rk;
wire same_rd;
wire inst_no_dest_reg;
//wire block;
wire ID_br_stall;
assign c11=~(|(rd^EX_dest_reg));
assign c12=~(|(rd^MEM_dest_reg));
assign c13=~(|(rd^WB_dest_reg));

assign c21=~(|(rj^EX_dest_reg));
assign c22=~(|(rj^MEM_dest_reg));
assign c23=~(|(rj^WB_dest_reg));

assign c31=~(|(rk^EX_dest_reg));
assign c32=~(|(rk^MEM_dest_reg));
assign c33=~(|(rk^WB_dest_reg));

assign same_rd=src_reg_is_rd && rd!=5'b0 && ((c11) || (c12) || (c13));
assign same_rj=src_reg_is_rj && rj!=5'b0 && ((c21) || (c22) || (c23));
assign same_rk=src_reg_is_rk && rk!=5'b0 && ((c31) || (c32) || (c33));
assign inst_no_dest_reg=inst_st_w |inst_st_b| inst_b |inst_beq |inst_beq;
assign block=((src_reg_is_rd && rd!=5'b0 && c11)||
              (src_reg_is_rj && rj!=5'b0 && c21)||
              (src_reg_is_rk && rk!=5'b0 && c31))&& EX_load;
//assign inst_beq_bne=inst_beq || inst_bne;
assign i12  = ID_inst[21:10];
assign i20  = ID_inst[24: 5];
assign i16  = ID_inst[25:10];
assign i26  = {ID_inst[ 9: 0], ID_inst[25:10]};
assign src_reg_is_rd_rj_rk = {src_reg_is_rd,src_reg_is_rj,src_reg_is_rk};

decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));

assign inst_add_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
assign inst_sub_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
assign inst_mul_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h18];
assign inst_srl_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0f];
assign inst_slt    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
assign inst_slti   = op_31_26_d[6'h00] & op_25_22_d[4'h8];
assign inst_sltu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
assign inst_nor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
assign inst_and    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
assign inst_andi   = op_31_26_d[6'h00] & op_25_22_d[4'hd];
assign inst_or     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
assign inst_ori    = op_31_26_d[6'h00] & op_25_22_d[4'he];
assign inst_xor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
assign inst_slli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
assign inst_srli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
assign inst_srai_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];
assign inst_ld_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
assign inst_ld_b   = op_31_26_d[6'h0a] & op_25_22_d[4'h0];
assign inst_st_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
assign inst_st_b   = op_31_26_d[6'h0a] & op_25_22_d[4'h4];
assign inst_jirl   = op_31_26_d[6'h13];
assign inst_b      = op_31_26_d[6'h14];
assign inst_bl     = op_31_26_d[6'h15];
assign inst_beq    = op_31_26_d[6'h16];
assign inst_bne    = op_31_26_d[6'h17];
assign inst_blt    = op_31_26_d[6'h18];
assign inst_lu12i_w= op_31_26_d[6'h05] & ~ID_inst[25];
assign inst_pcaddu12i=op_31_26_d[6'h07] & ~ID_inst[25];
assign to_EX_inst_bl=inst_bl;

assign alu_op[ 0] = inst_add_w | inst_addi_w | inst_ld_w |inst_ld_b| inst_st_w|inst_st_b
                    | inst_jirl | inst_bl|inst_pcaddu12i;
assign alu_op[ 1] = inst_sub_w|inst_beq|inst_bne|inst_blt;
assign alu_op[ 2] = inst_slt|inst_slti;
assign alu_op[ 3] = inst_sltu;
assign alu_op[ 4] = inst_and|inst_andi;
assign alu_op[ 5] = inst_nor;
assign alu_op[ 6] = inst_or|inst_ori;
assign alu_op[ 7] = inst_xor;
assign alu_op[ 8] = inst_slli_w;
assign alu_op[ 9] = inst_srli_w|inst_srl_w;
assign alu_op[10] = inst_srai_w;
assign alu_op[11] = inst_lu12i_w;
assign alu_op[12] = inst_mul_w;
assign need_ui5   =  inst_slli_w | inst_srli_w | inst_srai_w;
assign need_si12  =  inst_addi_w | inst_ld_w |inst_ld_b| inst_st_w|inst_st_b| inst_slti;
assign need_si16  =  inst_jirl | inst_beq | inst_bne;
assign need_si20  =  inst_lu12i_w|inst_pcaddu12i;
assign need_si26  =  inst_b | inst_bl;
assign need_ui12  =  inst_andi | inst_ori;
assign src2_is_4  =  inst_jirl | inst_bl;

assign imm = src2_is_4 ? 32'h4                      :
             need_si20 ? {i20[19:0], 12'b0}         :
             need_ui12 ? {20'b0, i12[11:0]} :
/*need_ui5 || need_si12*/{{20{i12[11]}}, i12[11:0]} ;

assign br_offs = need_si26 ? {{ 4{i26[25]}}, i26[25:0], 2'b0} :
                             {{14{i16[15]}}, i16[15:0], 2'b0} ;
//此处为将bne，beq调到ex进行判断代码
assign ID_br_taken=(inst_jirl
                   || inst_bl
                   || inst_b
                  ) && ID_valid;

assign ID_br_target = (inst_beq || inst_bne ||inst_blt|| inst_bl || inst_b) ? (ID_pc + br_offs) :
                                                   /*inst_jirl*/ (rj_value + jirl_offs);
assign ID_br_reg={inst_blt,inst_beq,inst_bne,ID_br_taken,ID_br_target};
assign jirl_offs = {{14{i16[15]}}, i16[15:0], 2'b0};

assign src_reg_is_rd = inst_beq | inst_bne|inst_blt | inst_st_w|inst_st_b;
assign src_reg_is_rj = ~(inst_b | inst_bl | inst_lu12i_w|inst_pcaddu12i);
assign src1_is_pc    = inst_jirl | inst_bl|inst_pcaddu12i;

assign src2_is_imm   = inst_slli_w |
                       inst_srli_w |
                       inst_srai_w |
                       inst_addi_w |
                       inst_slti   |
                       inst_ld_w   |
                       inst_ld_b   |
                       inst_st_w   |
                       inst_st_b   |
                       inst_lu12i_w|
                     inst_pcaddu12i|
                       inst_jirl   |
                       inst_bl     |
                       inst_andi   |
                       inst_ori;
assign src_reg_is_rk =  inst_add_w |
                    inst_sub_w |
                    inst_srl_w|
                    inst_and   |
                    inst_or    |
                    inst_xor   |
                    inst_slt   |
                    inst_nor   |
                    inst_mul_w |
                    inst_sltu;
assign res_from_mem  = inst_ld_w|inst_ld_b;
assign dst_is_r1     = inst_bl;
assign gr_we         = ~inst_st_w & ~inst_beq & ~inst_bne & ~inst_blt & ~inst_b & ~inst_st_b;
assign mem_we        = inst_st_w | inst_st_b;
assign dest          = inst_no_dest_reg ? 5'b0 :(dst_is_r1 ? 5'd1 : rd);

assign rf_raddr1 = rj;
assign rf_raddr2 = src_reg_is_rd ? rd :rk;

assign {rf_we,rf_waddr,rf_wdata} = WB_rf_reg;


regfile u_regfile(
    .clk    (clk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (rf_we    ),
    .waddr  (rf_waddr ),
    .wdata  (rf_wdata )
    );
//forward


assign rj_value  = same_rj ?(c21?fw_alu_result:(c22?fw_mem_final_result:fw_WB_final_result)):rf_rdata1;
assign rkd_value = same_rd ?(c11?fw_alu_result:(c12?fw_mem_final_result:fw_WB_final_result)):
                   (same_rk?(c31?fw_alu_result:(c32?fw_mem_final_result:fw_WB_final_result)):rf_rdata2);

assign ID_EX_reg={
    inst_st_b,//153
    inst_ld_b,//152
    ID_pc,//151:120
    imm,//119:88
    rj_value,//87:56
    rkd_value,//55:24
    gr_we,//23:23
    dest,//22:18
    mem_we,//17
    alu_op,//16:4
    src1_is_pc,//3:3
    src2_is_imm,//2:2
    src2_is_4,//1:1
    res_from_mem//0:0
};

assign ID_ready_go =~block;
assign ID_allow_in=!ID_valid||ID_ready_go&&EX_allow_in;
assign ID_to_EX_valid=ID_valid&&ID_ready_go&&!delay_slot&&!EX_br_taken;
assign ID_block=block;
always@(posedge clk)begin
    if(reset)begin
        ID_valid<=1'b0;
        delay_slot<=1'b0;
    end
    else if(ID_allow_in)begin
        ID_valid<=IF_to_ID_valid;
    end

    if (IF_to_ID_valid && ID_allow_in) begin
        {ID_pc,ID_inst} <= IF_ID_reg;
        if(ID_br_taken) begin
            delay_slot<=1'b1;
        end
        else begin
            delay_slot<=1'b0;
        end
    end

end

endmodule                     
