module EX_stage(
    input wire        clk,
    input wire        reset,
    input wire     MEM_allow_in,
    input wire     ID_to_EX_valid,
    input wire [34:0] ID_br_reg,//此处为将bne，beq调到ex进行判断代码
    input wire [151:0] ID_EX_reg,
    output wire EX_allow_in,
    output wire EX_to_MEM_valid,
    output wire  [70:0]EX_MEM_reg,
    output   [32:0]EX_br_reg,//此处为将bne，beq调到ex进行判断代码
    output wire  data_sram_en,
    output wire [3:0] data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    output [4:0] EX_dest_reg,
    output wire EX_load,
    input wire to_EX_inst_bl,
    output wire [31:0] fw_alu_result,
    output wire EX_load_store
);

    reg EX_valid;
    wire EX_ready_go;
    reg delay_slot;
    reg EX_inst_bl;
    //reg transfer
    reg [31:0] EX_pc;
    reg [31:0] EX_imm;
    reg [31:0] EX_rj_value;
    reg [31:0] EX_rkd_value;
    reg        EX_gr_we;
    reg [4:0]  EX_dest;
    reg        EX_mem_we;
    reg [12:0] EX_alu_op;
    reg EX_src1_is_pc;
    reg EX_src2_is_imm;
    reg EX_src2_is_4;
    reg EX_res_from_mem;
    //alu_port
    wire [31:0] alu_src1;
    wire [31:0] alu_src2;
    wire [31:0] alu_result;
    assign fw_alu_result=alu_result;
    assign EX_ready_go=1'b1;
    assign EX_allow_in= !EX_valid || EX_ready_go&&MEM_allow_in;
    assign EX_to_MEM_valid=EX_valid && EX_ready_go&&!delay_slot;
    assign EX_MEM_reg={
        EX_pc,//70:39
        EX_gr_we,//38:38
        EX_dest,//37:33
        alu_result,//32:1
        EX_res_from_mem//0:0
    };
    //此处为将bne，beq调到ex进行判断代码，改的话注释掉即可
    reg EX_inst_beq;
    reg EX_inst_bne;
    reg br_taken;//只是为了拼接，无实际作用
    reg [31:0] EX_br_target;
    
    assign EX_dest_reg=EX_dest&{5{EX_valid}};
    assign EX_br_taken=(EX_inst_beq && alu_result==0 ||
                        EX_inst_bne && alu_result!=0) && EX_valid;
    assign EX_br_reg={EX_br_taken,EX_br_target};

   
    always @(posedge clk) begin
        if (reset) begin
            EX_valid<=1'b0;
            //delay_slot<=1'b0;
        end
        else if(EX_allow_in) begin
            EX_valid<=ID_to_EX_valid;
        end

        if(ID_to_EX_valid && EX_allow_in) begin
            {EX_pc,
             EX_imm,
             EX_rj_value,
             EX_rkd_value,
             EX_gr_we,
             EX_dest,
             EX_mem_we,
             EX_alu_op,
             EX_src1_is_pc,
             EX_src2_is_imm,
             EX_src2_is_4,
             EX_res_from_mem}<=ID_EX_reg;
             EX_inst_bl<=to_EX_inst_bl;
            {EX_inst_beq,EX_inst_bne,br_taken,EX_br_target}<=ID_br_reg;
            if(EX_br_taken) begin
                delay_slot<=1'b1;
            end
            else begin
                delay_slot<=1'b0;
            end
        end
    end
    assign EX_load = EX_res_from_mem;

    alu u_alu(
        .alu_src1(alu_src1),
        .alu_src2(alu_src2),
        .alu_op(EX_alu_op),
        .alu_result(alu_result)
    );
    assign alu_src1 = EX_src1_is_pc? EX_pc: EX_rj_value;
    assign alu_src2 = EX_src2_is_imm? EX_imm: (EX_inst_bl?32'h4:EX_rkd_value);
    assign EX_load_store= EX_res_from_mem | EX_mem_we;
    assign data_sram_en=EX_res_from_mem | EX_mem_we;
    assign data_sram_we=EX_mem_we &&EX_valid?4'b1111:4'b0000;
    assign data_sram_addr=alu_result;
    assign data_sram_wdata=EX_rkd_value;
endmodule