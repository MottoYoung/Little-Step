`default_nettype none

module thinpad_top(
    input wire clk_50M,           //50MHz ʱ������
    input wire clk_11M0592,       //11.0592MHz ʱ�����루���ã��ɲ��ã�

    input wire clock_btn,         //BTN5�ֶ�ʱ�Ӱ�ť���أ���������·������ʱΪ1
    input wire reset_btn,         //BTN6�ֶ���λ��ť���أ���������·������ʱΪ1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4����ť���أ�����ʱΪ1
    input  wire[31:0] dip_sw,     //32λ���뿪�أ�����"ON"ʱΪ1
    output wire[15:0] leds,       //16λLED�����ʱ1����
    output wire[7:0]  dpy0,       //����ܵ�λ�źţ�����С���㣬���1����
    output wire[7:0]  dpy1,       //����ܸ�λ�źţ�����С���㣬���1����

    //BaseRAM�ź�
    inout wire[31:0] base_ram_data,  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output wire[19:0] base_ram_addr, //BaseRAM��ַ
    output wire[3:0] base_ram_be_n,  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire base_ram_ce_n,       //BaseRAMƬѡ������Ч
    output wire base_ram_oe_n,       //BaseRAM��ʹ�ܣ�����Ч
    output wire base_ram_we_n,       //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
    inout wire[31:0] ext_ram_data,  //ExtRAM����
    output wire[19:0] ext_ram_addr, //ExtRAM��ַ
    output wire[3:0] ext_ram_be_n,  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire ext_ram_ce_n,       //ExtRAMƬѡ������Ч
    output wire ext_ram_oe_n,       //ExtRAM��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,       //ExtRAMдʹ�ܣ�����Ч

    //ֱ�������ź�
    output wire txd,  //ֱ�����ڷ��Ͷ�
    //input  wire rxd,  //ֱ�����ڽ��ն�

    //Flash�洢���źţ��ο� JS28F640 оƬ�ֲ�
    output wire [22:0]flash_a,      //Flash��ַ��a0����8bitģʽ��Ч��16bitģʽ������
    inout  wire [15:0]flash_d,      //Flash����
    output wire flash_rp_n,         //Flash��λ�źţ�����Ч
    output wire flash_vpen,         //Flashд�����źţ��͵�ƽʱ���ܲ�������д
    output wire flash_ce_n,         //FlashƬѡ�źţ�����Ч
    output wire flash_oe_n,         //Flash��ʹ���źţ�����Ч
    output wire flash_we_n,         //Flashдʹ���źţ�����Ч
    output wire flash_byte_n,       //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash��16λģʽʱ����Ϊ1

    //ͼ������ź�
    output wire[2:0] video_red,    //��ɫ���أ�3λ
    output wire[2:0] video_green,  //��ɫ���أ�3λ
    output wire[1:0] video_blue,   //��ɫ���أ�2λ
    output wire video_hsync,       //��ͬ����ˮƽͬ�����ź�
    output wire video_vsync,       //��ͬ������ֱͬ�����ź�
    output wire video_clk,         //����ʱ�����
    output wire video_de          //��������Ч�źţ���������������

);

/* =========== Demo code begin =========== */

// PLL��Ƶʾ��
wire locked, clk_10M, clk_20M;
pll_example clock_gen 
 (
  // Clock in ports
  .clk_in1(clk_50M),  // �ⲿʱ������
  // Clock out ports
  .clk_out1(clk_10M), // ʱ�����1��Ƶ����IP���ý���������
  .clk_out2(clk_20M), // ʱ�����2��Ƶ����IP���ý���������
  // Status and control signals
  .reset(reset_btn), // PLL��λ����
  .locked(locked)    // PLL����ָʾ�����"1"��ʾʱ���ȶ���
                     // �󼶵�·��λ�ź�Ӧ���������ɣ����£�
 );

reg reset_of_clk10M;
// �첽��λ��ͬ���ͷţ���locked�ź�תΪ�󼶵�·�ĸ�λreset_of_clk10M
always@(posedge clk_10M or negedge locked) begin
    if(~locked) reset_of_clk10M <= 1'b1;
    else        reset_of_clk10M <= 1'b0;
end

always@(posedge clk_10M or posedge reset_of_clk10M) begin
    if(reset_of_clk10M)begin
        // Your Code
    end
    else begin
        // Your Code
    end
end




//cpu inst sram
wire        cpu_inst_en;
wire [3 :0] cpu_inst_we;
wire [31:0] cpu_inst_addr;
wire [31:0] cpu_inst_wdata;
wire [31:0] cpu_inst_rdata;
//cpu data sram
wire        cpu_data_en;
wire [3 :0] cpu_data_we;
wire [31:0] cpu_data_addr;
wire [31:0] cpu_data_wdata;
wire [31:0] cpu_data_rdata;

mycpu_top u_mycpu(              
    .clk              (clk_20M),
    .resetn           (~reset_of_clk10M),
 
    .inst_sram_en     (cpu_inst_en   ),//1
    .inst_sram_we    (cpu_inst_we  ),//0000
    .inst_sram_addr   (cpu_inst_addr ),
    .inst_sram_wdata  (cpu_inst_wdata),
    .inst_sram_rdata  (cpu_inst_rdata),

    .data_sram_en     (cpu_data_en   ),//1
    .data_sram_we    (cpu_data_we  ),//sel
    .data_sram_addr   (cpu_data_addr ),
    .data_sram_wdata  (cpu_data_wdata),
    .data_sram_rdata  (cpu_data_rdata)
);


reg [31:0] cpu_inst_rdata_r;
reg [31:0] cpu_data_rdata_r;

reg [31:0] base_ram_data_r;
reg [19:0] base_ram_addr_r;
reg [3:0] base_ram_be_n_r;
reg base_ram_ce_n_r;
reg base_ram_oe_n_r;
reg base_ram_we_n_r;

reg [31:0] ext_ram_data_r;
reg [19:0] ext_ram_addr_r;
reg [3:0] ext_ram_be_n_r;
reg ext_ram_ce_n_r;
reg ext_ram_oe_n_r;
reg ext_ram_we_n_r;

reg sel_inst; // 1-inst 0-data for base_ram
reg sel_uart;
reg sel_uart_flag; // 1-flag 0-data


wire [31:0] uart_rdata;
reg [31:0] uart_wdata;

//ֱ�����ڽ��շ�����ʾ����ֱ�������յ��������ٷ��ͳ�ȥ
//wire [7:0] ext_uart_rx;
reg  [7:0] ext_uart_buffer, ext_uart_tx;
wire ext_uart_ready, ext_uart_clear, ext_uart_busy;
reg ext_uart_start, ext_uart_avai;


reg cpu_data_avai;

reg uart_read_flag;
reg uart_write_flag;

assign base_ram_data = ~base_ram_we_n_r ? base_ram_data_r : 32'bz;
assign ext_ram_data = ~ext_ram_we_n_r ? ext_ram_data_r : 32'bz;

assign base_ram_addr = base_ram_addr_r;
assign base_ram_be_n = base_ram_be_n_r;
assign base_ram_ce_n = base_ram_ce_n_r;
assign base_ram_oe_n = base_ram_oe_n_r;
assign base_ram_we_n = base_ram_we_n_r;

assign ext_ram_addr = ext_ram_addr_r;
assign ext_ram_be_n = ext_ram_be_n_r;
assign ext_ram_ce_n = ext_ram_ce_n_r;
assign ext_ram_oe_n = ext_ram_oe_n_r;
assign ext_ram_we_n = ext_ram_we_n_r;
// in 
always @ (*) begin
    if (reset_of_clk10M) begin
        cpu_inst_rdata_r <= 32'b0;
        cpu_data_rdata_r <= 32'b0;
    end
    else begin
        cpu_inst_rdata_r <= ~sel_inst ? 32'b0 
                            : ~base_ram_oe_n_r ? base_ram_data
                            : 32'b0;
        cpu_data_rdata_r <= sel_uart ? uart_rdata : sel_inst ? (~ext_ram_oe_n_r ? ext_ram_data : 32'b0) : (~base_ram_oe_n_r ? base_ram_data : 32'b0);
    end
end
assign cpu_inst_rdata = cpu_inst_rdata_r;
assign cpu_data_rdata = cpu_data_rdata_r;
assign uart_rdata = sel_uart_flag ? {30'b0,ext_uart_avai,~ext_uart_busy} : {24'b0,ext_uart_buffer};

reg [3:0] state;
 

 // out 
always @ (posedge clk_20M) begin
    if (reset_of_clk10M) begin
        base_ram_addr_r <= 19'b0;
        base_ram_be_n_r <= 4'b0;
        base_ram_ce_n_r <= 1'b1;
        base_ram_oe_n_r <= 1'b1;
        base_ram_we_n_r <= 1'b1;
        base_ram_data_r <= 32'b0;

        ext_ram_addr_r <= 19'b0;
        ext_ram_be_n_r <= 4'b0;
        ext_ram_ce_n_r <= 1'b1;
        ext_ram_oe_n_r <= 1'b1;
        ext_ram_we_n_r <= 1'b1;
        ext_ram_data_r <= 32'b0;

        sel_inst <= 1'b0;
        sel_uart <= 1'b0;
        sel_uart_flag <= 1'b0;
        uart_wdata <= 32'b0;
        cpu_data_avai <= 1'b0;
        state <= 4'd0;
    end
    else if (cpu_data_addr >=32'h80000000  && cpu_data_addr <= 32'h803fffff && cpu_data_en) begin
        base_ram_addr_r <= cpu_data_addr[21:2];
        base_ram_be_n_r <= 4'b0;
        base_ram_ce_n_r <= ~cpu_data_en;
        base_ram_oe_n_r <= ~(cpu_data_en & ~(|cpu_data_we));
        base_ram_we_n_r <= ~(cpu_data_en & (|cpu_data_we));
        base_ram_data_r <= cpu_data_wdata;

        ext_ram_addr_r <= 19'b0;
        ext_ram_be_n_r <= 4'b0;
        ext_ram_ce_n_r <= 1'b1;
        ext_ram_oe_n_r <= 1'b1;
        ext_ram_we_n_r <= 1'b1;  
        ext_ram_data_r <= 32'b0;

        sel_inst <= 1'b0;
        sel_uart <= 1'b0;
        sel_uart_flag <= 1'b0;
        uart_wdata <= 32'b0;
        cpu_data_avai <= 1'b0;
        state <= 4'd1;
    end
    else if (cpu_data_addr >= 32'h80400000 && cpu_data_addr <= 32'h807fffff && cpu_data_en) begin       
        base_ram_addr_r <= cpu_inst_addr[21:2];
        base_ram_be_n_r <= 4'b0;
        base_ram_ce_n_r <= ~cpu_inst_en;
        base_ram_oe_n_r <= ~cpu_inst_en ;
        base_ram_we_n_r <= 1'b1;
        base_ram_data_r <= cpu_inst_wdata;
        
        ext_ram_addr_r <= cpu_data_addr[21:2];
        ext_ram_be_n_r <= 4'b0;
        ext_ram_ce_n_r <= ~cpu_data_en;
        ext_ram_oe_n_r <= ~(cpu_data_en & ~(|cpu_data_we));
        ext_ram_we_n_r <= ~(cpu_data_en & (|cpu_data_we)); 
        ext_ram_data_r <= cpu_data_wdata;

        sel_inst <= 1'b1;
        sel_uart <= 1'b0;
        sel_uart_flag <= 1'b0;
        uart_wdata <= 32'b0;
        cpu_data_avai <= 1'b0;
        state <= 4'd2;
    end
    else if (cpu_data_addr == 32'hbfd003fc) begin
        base_ram_addr_r <= cpu_inst_addr[21:2];
        base_ram_be_n_r <= 4'b0;
        base_ram_ce_n_r <= ~cpu_inst_en;
        base_ram_oe_n_r <= ~cpu_inst_en ;
        base_ram_we_n_r <= 1'b1;
        base_ram_data_r <= cpu_inst_wdata;
      
        ext_ram_addr_r <= 19'b0;
        ext_ram_be_n_r <= 4'b0;
        ext_ram_ce_n_r <= 1'b1;
        ext_ram_oe_n_r <= 1'b1;
        ext_ram_we_n_r <= 1'b1;
        ext_ram_data_r <= 32'b0;

        sel_inst <= 1'b1;
        sel_uart <= 1'b1;
        sel_uart_flag <= 1'b1;
        uart_wdata <= 32'b0;
        cpu_data_avai <= 1'b0;
        state <= 4'd3;
    end
    else if (cpu_data_addr == 32'hbfd003f8 && cpu_data_en) begin        
        base_ram_addr_r <= cpu_inst_addr[21:2];
        base_ram_be_n_r <= 4'b0;
        base_ram_ce_n_r <= ~cpu_inst_en;
        base_ram_oe_n_r <= ~cpu_inst_en ;
        base_ram_we_n_r <= 1'b1;
        base_ram_data_r <= cpu_inst_wdata;
       
        ext_ram_addr_r <= 19'b0;
        ext_ram_be_n_r <= 4'b0;
        ext_ram_ce_n_r <= 1'b1;
        ext_ram_oe_n_r <= 1'b1;
        ext_ram_we_n_r <= 1'b1;
        ext_ram_data_r <= 32'b0;

        sel_inst <= 1'b1;
        sel_uart <= 1'b1;
        sel_uart_flag <= 1'b0;
        uart_wdata <= cpu_data_wdata;
        cpu_data_avai <= (|cpu_data_we) ? 1'b1 : 1'b0;
        state <= 4'd4;
    end
    else begin        
        base_ram_addr_r <= cpu_inst_addr[21:2];
        base_ram_be_n_r <= 4'b0;
        base_ram_ce_n_r <= ~cpu_inst_en;
        base_ram_oe_n_r <= ~cpu_inst_en ;
        base_ram_we_n_r <= 1'b1;
        base_ram_data_r <= cpu_inst_wdata;
      
        ext_ram_addr_r <= 19'b0;
        ext_ram_be_n_r <= 4'b0;
        ext_ram_ce_n_r <= 1'b1;
        ext_ram_oe_n_r <= 1'b1;
        ext_ram_we_n_r <= 1'b1;
        ext_ram_data_r <= 32'b0;

        sel_inst <= 1'b1;
        sel_uart <= 1'b0;
        sel_uart_flag <= 1'b0;
        uart_wdata <= 32'b0;
        cpu_data_avai <= 1'b0;
        state <= 4'd5;
    end
end

//simuse

reg rxd;
reg [7:0] ext_uart_rx;
cpld_model cpld(
    .clk_uart(clk_20M),         //�ڲ�����ʱ��
    .uart_rdn(rxd),         //�������źţ�����Ч
    .uart_wrn(~ext_uart_start),         //д�����źţ�����Ч
    .uart_dataready(),    //��������׼����
    .uart_tbre(),         //�������ݱ�־
    .uart_tsre(),         //���ݷ�����ϱ�־
    .RxD_data_in(ext_uart_rx),
    .data_in(ext_uart_tx),
    .data_out()
);

assign ext_uart_ready = ~rxd;


initial begin
    rxd = 1;
    ext_uart_rx = 8'h00;
    #30000;
    rxd = 0;
    ext_uart_rx = 8'h54; // char "T"
    #20;
    rxd = 1;
    ext_uart_rx = 8'h00;
end

/*
//uart
async_receiver #(.ClkFrequency(60000000),.Baud(9600)) //����ģ��,9600�޼���λ
    ext_uart_r(
        .clk(clk_20M),                       //�ⲿʱ���ź�
        .RxD(rxd),                           //�ⲿ�����ź�����
        .RxD_data_ready(ext_uart_ready),  //���ݽ��յ���־
        .RxD_clear(ext_uart_clear),       //������ձ�־
        .RxD_data(ext_uart_rx)             //���յ���һ�ֽ�����
    );
*/
assign ext_uart_clear = ext_uart_ready; //�յ����ݵ�ͬʱ�������־����Ϊ������ȡ��ext_uart_buffer��
always @(posedge clk_20M) begin //�������ݵ�ext_uart_buffer
    if (reset_of_clk10M) begin
        ext_uart_buffer <= 8'b0;
        ext_uart_avai <= 1'b0;
    end
    else if(ext_uart_ready)begin
        ext_uart_buffer <= ext_uart_rx;
        ext_uart_avai <= 1'b1;
    end 
    else if(cpu_data_addr == 32'h1fd003f8 && (cpu_data_en & ~(|cpu_data_we)) && ext_uart_avai)begin 
        ext_uart_avai <= 1'b0;
    end
end

always @(posedge clk_20M) begin //�������ݵ�ext_uart_buffer
    if(!ext_uart_busy && cpu_data_avai)begin 
        ext_uart_tx <= uart_wdata[7:0];
        ext_uart_start <= 1;
    end else begin 
        ext_uart_start <= 0;
    end
end

async_transmitter #(.ClkFrequency(60000000),.Baud(9600)) //����ģ��,9600�޼���λ
    ext_uart_t(
        .clk(clk_50M),                  //�ⲿʱ���ź�
        .TxD(txd),                      //�����ź����
        .TxD_busy(ext_uart_busy),       //������æ״ָ̬ʾ
        .TxD_start(ext_uart_start),    //��ʼ�����ź�
        .TxD_data(ext_uart_tx)        //�����͵�����
    );

endmodule
