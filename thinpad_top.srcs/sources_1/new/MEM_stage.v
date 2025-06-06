module MEM_stage(
    input wire clk,
    input wire reset,
    input wire WB_allow_in,
    input wire [71:0] EX_MEM_reg,
    input wire EX_to_MEM_valid,
    input wire [31:0] data_sram_rdata,
    output wire MEM_to_WB_valid,
    output wire [69:0] MEM_WB_reg,
    output wire MEM_allow_in,
    output wire [4:0] MEM_dest_reg,
    output wire [31:0] fw_mem_final_result
);

reg MEM_ld_b;
reg [31:0] MEM_pc;
reg MEM_gr_we;
reg [4:0] MEM_dest;
reg [31:0] MEM_alu_result;
reg MEM_res_from_mem;
wire [31:0] MEM_result;
wire [31:0] MEM_final_result;
wire [31:0] ld_b_data_sram_rdata;
wire [4:0]off;
assign off={MEM_alu_result[1:0],3'b0};
assign ld_b_data_sram_rdata=data_sram_rdata>>off;
reg MEM_valid;
wire MEM_ready_go;
assign MEM_ready_go=1'b1;
assign MEM_allow_in= !MEM_valid || MEM_ready_go && WB_allow_in;
assign MEM_to_WB_valid=MEM_valid && MEM_ready_go;
assign MEM_dest_reg=MEM_dest & {5{MEM_valid}};
always@(posedge clk) begin
    if(reset) begin
        MEM_valid<=1'b0;
    end
    else if(MEM_allow_in) begin
        MEM_valid<=EX_to_MEM_valid;
    end
    if(EX_to_MEM_valid && MEM_allow_in) begin
        MEM_ld_b<=EX_MEM_reg[71];
        MEM_pc<=EX_MEM_reg[70:39];
        MEM_gr_we<=EX_MEM_reg[38];
        MEM_dest<=EX_MEM_reg[37:33];
        MEM_alu_result<=EX_MEM_reg[32:1];
        MEM_res_from_mem<=EX_MEM_reg[0];
    end
end
assign fw_mem_final_result=MEM_final_result;
assign MEM_result=MEM_ld_b?{{24{ld_b_data_sram_rdata[7]}},ld_b_data_sram_rdata[7:0]}:data_sram_rdata;
assign MEM_final_result=MEM_res_from_mem?MEM_result:MEM_alu_result;
assign MEM_WB_reg={MEM_pc,//69:38
                   MEM_gr_we,//37
                   MEM_dest,//36:32
                   MEM_final_result//31:0
                   };
endmodule