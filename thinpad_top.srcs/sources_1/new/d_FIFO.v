module async_fifo#(  
    parameter    DEPTH = 16,  
    parameter    WIDTH = 8,
    parameter    ADDR_BIT = 4,      //log2(DEPTH)
    parameter    RAM_STYLE_VAL = "distributed" 
)(  
    input        wr_clk,  
    input        rst_n,  
    input        wr_en,  
    input  [WIDTH-1:0]  data_in,  
    input        rd_clk,  
    input        rd_en,  
    output  [WIDTH-1:0]  data_out,  
    output        full,  
    output        empty
);
	(*ram_style=RAM_STYLE_VAL*)
    reg  [WIDTH-1:0]   mem [DEPTH-1:0];
    reg  [WIDTH-1:0]   data_out_r;
    reg  [ADDR_BIT:0]  wr_addr;
    wire [ADDR_BIT:0]  wr_addr_gray;
    reg  [ADDR_BIT:0]  wr_addr_w2r1;
    reg  [ADDR_BIT:0]  wr_addr_w2r2;
    reg  [ADDR_BIT:0]  rd_addr;
    wire [ADDR_BIT:0]  rd_addr_gray;
    reg  [ADDR_BIT:0]  rd_addr_r2w1;
    reg  [ADDR_BIT:0]  rd_addr_r2w2;
    
    //*********************** Address ***********************//
    //write address
    always @ (posedge wr_clk or negedge rst_n)begin  
    	if(!rst_n)    wr_addr <= 'd0;  
    	else if(wr_en)    wr_addr <= wr_addr + 1;  
    	else    wr_addr <= wr_addr;
    end

    //write address - > gray
    assign  wr_addr_gray = (wr_addr>>1)^wr_addr;
    
    //Write address synchronization to read clock domain
    always @ (posedge wr_clk or negedge rst_n)begin  
    	if(!rst_n)    
    	   {wr_addr_w2r2,wr_addr_w2r1} <= 'd0;
      	else  
      	   {wr_addr_w2r2,wr_addr_w2r1} <= {wr_addr_w2r1,wr_addr_gray};
    end
    //read address
    always @ (posedge rd_clk or negedge rst_n)begin  
    	if(!rst_n)    
    	   rd_addr <= 'd0;  
    	else if(rd_en)   
    	   rd_addr <= rd_addr + 1;  
    	else    
    	   rd_addr <= rd_addr;  
    end
    //write address - > gray
    assign  rd_addr_gray = (rd_addr>>1)^rd_addr;
    //Read address synchronization to write clock domain
    always @ (posedge rd_clk or negedge rst_n)begin  
    	if(!rst_n)    
    	   {rd_addr_r2w2,rd_addr_r2w1} <= 'd0;  
    	else    
    	   {rd_addr_r2w2,rd_addr_r2w1} <= {rd_addr_r2w1,rd_addr_gray};
    end
    //************************* Data *************************//
    //write data
    always @ (posedge wr_clk)begin  
        if(wr_en) 
            mem[wr_addr] <= data_in;
        else      
            mem[wr_addr] <= mem[wr_addr];
    end
    //read data delay 1clk
    assign  data_out = data_out_r;
    always @ (posedge rd_clk or negedge rst_n)begin  
    	if(!rst_n)    
    	   data_out_r <= {WIDTH{1'b0}};  
    	else if(rd_en==1)    
    	   data_out_r <= mem[rd_addr];  
    	else    
    	   data_out_r <= data_out_r;
    end
    //********************** Full/Empty *********************//
    //Empty signal judgment
    assign empty = (wr_addr_w2r2 == rd_addr_gray);
    //Full signal judgment
    assign full  = ({~(rd_addr_r2w2[4:3]),rd_addr_r2w2[2:0]}==wr_addr_gray[4:0]);
    
endmodule
