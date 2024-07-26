`define BUF_WIDTH 4 //地址宽度为3+1
`define BUF_SIZE  8 //数据个数，FIFO深度
 
module FIFO(clk,rst_n,buf_in,buf_out,wr_en,rd_en,buf_empty,buf_full);
	input clk,rst_n;
	input wr_en,rd_en;
	input [7:0] buf_in; //data input to be pushed to buffer
	output reg [7:0] buf_out; //port to output the data using pop
	output wire buf_empty,buf_full; //buffer empty and full indication
	reg [`BUF_WIDTH-1:0] fifo_cnt; //number of data pushed in to buffer
	//当写入数据个数为8时，FIFO为满
	reg [`BUF_WIDTH-2:0] rd_ptr,wr_ptr;
	//数据指针3位宽度，0-7索引，8个数据深度，循环指针0-7-0-7
	reg [7:0] buf_mem [0:`BUF_SIZE-1];
	//判断空满
	assign buf_empty=(fifo_cnt==0);
	assign buf_full=(fifo_cnt==`BUF_SIZE);
	
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
		  fifo_cnt<=0;
		else if((!buf_full&&wr_en)&&(!buf_empty&&rd_en))//同时读写，counter不变
		  fifo_cnt<=fifo_cnt;
		else if(!buf_full&&wr_en) //写数据
		  fifo_cnt<=fifo_cnt+1;
		else if(!buf_empty&&rd_en) //读数据
		  fifo_cnt<=fifo_cnt-1;
		else
		  fifo_cnt<=fifo_cnt;
		end
	
	always@(posedge clk or negedge rst_n)begin //读数据
		if(!rst_n)
		  buf_out<=0;
		else if(rd_en&&!buf_empty)
		  buf_out<=buf_mem[rd_ptr];
		end
		
	always@(posedge clk )begin  //写数据
	    if(wr_en&&!buf_full)
		  buf_mem[wr_ptr]<=buf_in;
		end
		
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
		  rd_ptr<=0;
		  wr_ptr<=0;
		end
		else begin
		  if(!buf_empty&&rd_en)
			rd_ptr<=rd_ptr+1;
		  if(!buf_full&&wr_en)
		    wr_ptr<=wr_ptr+1;
		end
		end
endmodule