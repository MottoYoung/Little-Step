module IF_stage(
    input  wire        clk,
    input  wire        reset,
    //next_stage_ready
    input  wire       ID_allow_in,
    input  wire       [35:0] ID_br_reg,//此处为将bne，beq调到ex进行判断代码
    input  wire       [32:0] EX_br_reg,//此处为将bne，beq调到ex进行判断代码
    // inst sram interface
    output wire        inst_sram_en,
    output wire [3:0]  inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    //IF_to_ID ok
    output wire     IF_to_ID_valid,
    //IF/ID_cache
    output wire [63:0] IF_ID_reg,
    input wire EX_load_store,
    input wire ID_block
);
//延迟相关指令
wire pre_if_ready_go;
//此处为将bne，beq调到ex进行判断代码，改的话注释掉即可
wire [31:0] ID_br_target;
wire [31:0] EX_br_target;
wire inst_beq;
wire inst_bne;
wire inst_blt;
wire ID_br_taken;

//variables definition
(*mark_debug="true"*)reg [31:0] IF_pc;
wire [31:0] IF_nextpc;
wire [31:0] IF_seq_pc;
wire IF_br_taken;
wire [31:0] IF_br_target;
wire EX_br_taken;


wire [31:0] IF_inst;
reg  [31:0] old_inst;
reg old_block;

//pre_if_to_if
wire to_IF_valid;
//valid(working in IF)
reg IF_valid;
//permission to go if
wire IF_allow_in;
//ready to go ID
wire IF_ready_go;

//stall_logic
assign pre_if_ready_go=~EX_load_store || IF_pc<=32'h80000004;

//flow_control
assign to_IF_valid=~reset && pre_if_ready_go;
assign IF_ready_go=1'b1;
assign IF_allow_in= !IF_valid||IF_ready_go && ID_allow_in;//IF is working all the time,so it could always go to ID
assign IF_to_ID_valid = IF_valid && IF_ready_go&&!IF_br_taken;
assign IF_ID_reg={IF_pc,IF_inst};

//flow_control
always @(posedge clk) begin
    if (reset) begin
        IF_valid<=1'b0;
    end
   else if(IF_allow_in) begin
        IF_valid<=to_IF_valid;
    end
end

always @(posedge clk) begin
    if (reset) begin
        IF_pc<=32'h7ffffffc;
    end
    else if(IF_allow_in && to_IF_valid) begin
        IF_pc<=IF_nextpc;
        old_inst<=inst_sram_rdata;
        old_block<=ID_block;
    end
    else begin
        old_inst<=inst_sram_rdata;
        old_block<=ID_block;
    end
end
assign {inst_blt,inst_beq,inst_bne,ID_br_taken,ID_br_target}=ID_br_reg;
assign {EX_br_taken,EX_br_target}=EX_br_reg;
assign IF_br_taken=ID_br_taken || EX_br_taken;
assign IF_br_target=EX_br_taken?EX_br_target:ID_br_target;
//pc logic
assign IF_seq_pc       = IF_pc + 3'h4;
assign IF_nextpc       = IF_br_taken ? IF_br_target : IF_seq_pc;
assign inst_sram_en = ~EX_load_store && ~reset || IF_pc<=32'h80000004;
assign inst_sram_we = 4'b0000;
assign inst_sram_addr = IF_nextpc;
assign inst_sram_wdata = 32'b0;
//assign IF_inst=inst_sram_rdata;
assign IF_inst=~pre_if_ready_go && old_block?old_inst:inst_sram_rdata;

endmodule

