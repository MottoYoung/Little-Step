module MEM_stage(
    input wire clk,
    input wire reset,
    input wire WB_allow_in,
    input wire [70:0] EX_MEM_reg,
    input wire EX_to_MEM_valid,
    input wire [31:0] data_sram_rdata,
    output wire MEM_to_WB_valid,
    output wire [69:0] MEM_WB_reg,
    output wire MEM_allow_in
);

reg [31:0] MEM_pc;
reg MEM_gr_we;
reg [4:0] MEM_dest;
reg [31:0] MEM_alu_result;
reg MEM_res_from_mem;
wire [31:0] MEM_result;
wire [31:0] MEM_final_result;

reg MEM_valid;
wire MEM_ready_go;
assign MEM_ready_go=1'b1;
assign MEM_allow_in= !MEM_valid || MEM_ready_go && WB_allow_in;
assign MEM_to_WB_valid=MEM_valid && MEM_ready_go;

always@(posedge clk) begin
    if(reset) begin
        MEM_valid<=1'b0;
    end
    else if(MEM_allow_in) begin
        MEM_valid<=EX_to_MEM_valid;
    end
    if(EX_to_MEM_valid && MEM_allow_in) begin
        MEM_pc<=EX_MEM_reg[70:39];
        MEM_gr_we<=EX_MEM_reg[38];
        MEM_dest<=EX_MEM_reg[37:33];
        MEM_alu_result<=EX_MEM_reg[32:1];
        MEM_res_from_mem<=EX_MEM_reg[0];
    end
end

assign MEM_result=data_sram_rdata;
assign MEM_final_result=MEM_res_from_mem?MEM_result:MEM_alu_result;
assign MEM_WB_reg={MEM_pc,//69:38
                   MEM_gr_we,//37
                   MEM_dest,//36:32
                   MEM_final_result//31:0
                   };
endmodule