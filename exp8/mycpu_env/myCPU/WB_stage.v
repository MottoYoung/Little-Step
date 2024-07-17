module WB_stage(
    input wire clk,
    input wire reset,
    input wire MEM_to_WB_valid,
    input wire [69:0] MEM_WB_reg,
    output wire [37:0] WB_rf_reg,
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata,
    output wire WB_allow_in
);
    
    reg WB_valid;
    wire WB_ready_go;

    reg [31:0] WB_pc;
    reg WB_gr_we;
    reg [4:0] WB_dest;
    reg [31:0] WB_final_result;

    wire rf_we;
    wire [4:0] rf_waddr;
    wire [31:0] rf_wdata;

    assign WB_ready_go=1'b1;
    assign WB_allow_in= !WB_valid || WB_ready_go;
    assign rf_we=WB_gr_we && WB_valid;
    assign rf_waddr=WB_dest;
    assign rf_wdata=WB_final_result;

    assign WB_rf_reg={rf_we,rf_waddr,rf_wdata};
    always@(posedge clk) begin
        if(reset) begin
            WB_valid<=1'b0;
        end
        else if(WB_allow_in) begin
            WB_valid<=MEM_to_WB_valid;
        end

        if(MEM_to_WB_valid && WB_allow_in) begin
            WB_pc[31:0]<=MEM_WB_reg[69:38];
            WB_gr_we<=MEM_WB_reg[37];
            WB_dest<=MEM_WB_reg[36:32];
            WB_final_result<=MEM_WB_reg[31:0];
        end
    end

    assign debug_wb_pc=WB_pc;
    assign debug_wb_rf_we={4{rf_we}};
    assign debug_wb_rf_wnum=WB_dest;
    assign debug_wb_rf_wdata=WB_final_result;

endmodule