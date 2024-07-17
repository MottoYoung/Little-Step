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
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
reg         reset;
always @(posedge clk) reset <= ~resetn;

//allow_in
wire IF_allow_in;
wire ID_allow_in;
wire EX_allow_in;
wire MEM_allow_in;
wire WB_allow_in;

//reg
wire [63:0]IF_ID_reg;
wire [150:0]ID_EX_reg;
wire [34:0] ID_br_reg;
wire [32:0] EX_br_reg;
wire [70:0]EX_MEM_reg;
wire br_taken;
wire [69:0]MEM_WB_reg;
wire[37:0]WB_rf_reg;
wire [4:0] br_inst;
//valid
wire IF_to_ID_valid;
wire ID_to_EX_valid;
wire EX_to_MEM_valid;
wire MEM_to_WB_valid;

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
    .IF_ID_reg(IF_ID_reg)
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
    .ID_br_reg(ID_br_reg)
);

EX_stage EX(
    .clk(clk),
    .reset(reset),
    .MEM_allow_in(MEM_allow_in),
    .ID_to_EX_valid(ID_to_EX_valid),
    //.br_inst(br_inst),
    .ID_br_reg(ID_br_reg),
    .ID_EX_reg(ID_EX_reg),
    .EX_allow_in(EX_allow_in),
    .EX_to_MEM_valid(EX_to_MEM_valid),
    .EX_br_reg(EX_br_reg),
    //.EX_br_taken(br_taken),
    .EX_MEM_reg(EX_MEM_reg),
    .data_sram_en(data_sram_en),
    .data_sram_we(data_sram_we),
    .data_sram_addr(data_sram_addr),
    .data_sram_wdata(data_sram_wdata)
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
    .MEM_allow_in(MEM_allow_in)
);

WB_stage WB(
    .clk(clk),
    .reset(reset),
    .MEM_to_WB_valid(MEM_to_WB_valid),
    .MEM_WB_reg(MEM_WB_reg),
    .WB_rf_reg(WB_rf_reg),
    .debug_wb_pc(debug_wb_pc),
    .debug_wb_rf_we(debug_wb_rf_we),
    .debug_wb_rf_wnum(debug_wb_rf_wnum),
    .debug_wb_rf_wdata(debug_wb_rf_wdata),
    .WB_allow_in(WB_allow_in)
);

endmodule