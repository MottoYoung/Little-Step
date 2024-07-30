module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_en,
    output wire [3:0]  inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_en,
    output wire [3:0]  data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata
);

wire EX_load_store;
wire EX_br_taken;
reg         reset;
always @(posedge clk) reset <= ~resetn;
//allow_in
wire IF_allow_in;
wire ID_allow_in;
wire EX_allow_in;
wire MEM_allow_in;
wire WB_allow_in;
//reg
wire EX_load;
wire [31:0] inst;
wire [63:0]IF_ID_reg;
wire [153:0]ID_EX_reg;
wire [35:0] ID_br_reg;
wire [32:0] EX_br_reg;
wire [71:0]EX_MEM_reg;
wire br_taken;
wire [69:0]MEM_WB_reg;
wire[37:0]WB_rf_reg;
wire [4:0] EX_dest_reg;
wire [4:0] MEM_dest_reg;
wire [4:0] WB_dest_reg;
wire [31:0] fw_alu_result;
wire [31:0] fw_mem_final_result;
wire [31:0] fw_WB_final_result;
wire block;
//valid
wire IF_to_ID_valid;
wire ID_to_EX_valid;
wire EX_to_MEM_valid;
wire MEM_to_WB_valid;
wire to_EX_inst_bl;
IF_stage IF(
    .clk(clk),
    .reset(reset),
    .ID_allow_in(ID_allow_in),
    .ID_br_reg(ID_br_reg),
    .EX_br_reg(EX_br_reg),
    .inst_sram_en(inst_sram_en),
    .inst_sram_we(inst_sram_we),
    .inst_sram_addr(inst_sram_addr),
    .inst_sram_wdata(inst_sram_wdata),
    .inst_sram_rdata(inst_sram_rdata),
    .IF_to_ID_valid(IF_to_ID_valid),
    .IF_ID_reg(IF_ID_reg),
    .EX_load_store(EX_load_store),
    .ID_block(block)

);

ID_stage ID(
    .clk(clk),
    .reset(reset),
    .EX_allow_in(EX_allow_in),
    .IF_to_ID_valid(IF_to_ID_valid),
    .IF_ID_reg(IF_ID_reg),
    .WB_rf_reg(WB_rf_reg),
    .ID_allow_in(ID_allow_in),
    .ID_EX_reg(ID_EX_reg),
    .ID_to_EX_valid(ID_to_EX_valid),
    .ID_br_reg(ID_br_reg),
    .EX_load(EX_load),
    .EX_dest_reg(EX_dest_reg),
    .MEM_dest_reg(MEM_dest_reg),
    .WB_dest_reg(WB_dest_reg),
    .to_EX_inst_bl(to_EX_inst_bl),
    .fw_alu_result(fw_alu_result),
    .fw_mem_final_result(fw_mem_final_result),
    .fw_WB_final_result(fw_WB_final_result),
    .EX_br_taken(EX_br_taken),
    .ID_block(block)
);

EX_stage EX(
    .clk(clk),
    .reset(reset),
    .MEM_allow_in(MEM_allow_in),
    .ID_to_EX_valid(ID_to_EX_valid),
    .ID_br_reg(ID_br_reg),
    .ID_EX_reg(ID_EX_reg),
    .EX_allow_in(EX_allow_in),
    .EX_to_MEM_valid(EX_to_MEM_valid),
    .EX_br_reg(EX_br_reg),
    .EX_MEM_reg(EX_MEM_reg),
    .data_sram_en(data_sram_en),
    .data_sram_we(data_sram_we),
    .data_sram_addr(data_sram_addr),
    .data_sram_wdata(data_sram_wdata),
    .EX_load(EX_load),
    .EX_dest_reg(EX_dest_reg),
    .to_EX_inst_bl(to_EX_inst_bl),
    .fw_alu_result(fw_alu_result),
    .EX_load_store(EX_load_store),
    .EX_br_taken(EX_br_taken)
);

MEM_stage MEM(
    .clk(clk),
    .reset(reset),
    .WB_allow_in(WB_allow_in),
    .EX_MEM_reg(EX_MEM_reg),
    .EX_to_MEM_valid(EX_to_MEM_valid),
    .data_sram_rdata(data_sram_rdata),
    .MEM_to_WB_valid(MEM_to_WB_valid),
    .MEM_WB_reg(MEM_WB_reg),
    .MEM_allow_in(MEM_allow_in),
    .MEM_dest_reg(MEM_dest_reg),
    .fw_mem_final_result(fw_mem_final_result)
);

WB_stage WB(
    .clk(clk),
    .reset(reset),
    .MEM_to_WB_valid(MEM_to_WB_valid),
    .MEM_WB_reg(MEM_WB_reg),
    .WB_rf_reg(WB_rf_reg),
    .WB_allow_in(WB_allow_in),
    .WB_dest_reg(WB_dest_reg),
    .fw_WB_final_result(fw_WB_final_result)
);

endmodule