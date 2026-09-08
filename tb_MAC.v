`timescale 1ns / 1ps

module tb_MAC_20cases;

    // --- Thông s? c?u hình ---
    localparam WADDR_WIDTH  = 3;
    localparam WDATA_DWIDTH = 32;
    localparam RADDR_WIDTH  = 1;
    localparam RDATA_DWIDTH = 32;

    // --- Khai báo tín hi?u ---
    reg                      CLK;
    reg                      RST;
    reg [WADDR_WIDTH-1:0]    waddr_i;
    reg [WDATA_DWIDTH-1:0]   wdata_i;
    reg                      wvalid_i;
    reg [RADDR_WIDTH-1:0]    raddr_i;
    reg                      arvalid_i;
    wire [RDATA_DWIDTH-1:0]  rdata_o;

    integer pass_count = 0;
    integer fail_count = 0;
    integer test_index = 0;

    // --- Kh?i t?o module MAC ---
    MAC #(
        .WADDR_WIDTH(WADDR_WIDTH),
        .WDATA_DWIDTH(WDATA_DWIDTH),
        .RADDR_WIDTH(RADDR_WIDTH),
        .RDATA_DWIDTH(RDATA_DWIDTH)
    ) uut (
        .CLK(CLK),
        .RST(RST),
        .waddr_i(waddr_i),
        .wdata_i(wdata_i),
        .wvalid_i(wvalid_i),
        .raddr_i(raddr_i),
        .arvalid_i(arvalid_i),
        .rdata_o(rdata_o)
    );

    // --- T?o xung clock ---
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end

    localparam LOAD_FLAG_ADDR  = 3'd0;
    localparam A_ADDR          = 3'd1;
    localparam X_ADDR          = 3'd2;
    localparam B_ADDR          = 3'd3;
    localparam START_FLAG_ADDR = 3'd4;
    localparam DONE_FLAG_ADDR  = 3'd5;

    // --- Task Ghi d? li?u ---
    task write_data;
        input [WADDR_WIDTH-1:0] addr;
        input [WDATA_DWIDTH-1:0] data;
        begin
            @(posedge CLK);
            waddr_i  = addr;
            wdata_i  = data;
            wvalid_i = 1'b1;
            @(posedge CLK);
            wvalid_i = 1'b0;
        end
    endtask

    // --- Task ??c d? li?u ---
    task read_data;
        input [RADDR_WIDTH-1:0] addr;
        begin
            @(posedge CLK);
            raddr_i   = addr;
            arvalid_i = 1'b1;
            @(posedge CLK);
            arvalid_i = 1'b0;
        end
    endtask

    // --- Task ch?y 1 Test Case ---
    task run_test;
        input [31:0] a_val;
        input [31:0] x_val;
        input [31:0] b_val;
        input [31:0] expected_y;
        begin
            test_index = test_index + 1;
            
            // 1. Chuy?n tr?ng thái LOAD
            write_data(LOAD_FLAG_ADDR, 32'd1);
            
            // 2. N?p d? li?u
            write_data(A_ADDR, a_val);
            write_data(X_ADDR, x_val);
            write_data(B_ADDR, b_val);
            
            // 3. B?t ??u tính toán
            write_data(START_FLAG_ADDR, 32'd1);
            
            // Ch? FSM x? lý
            #40;
            
            // 4. ??c k?t qu?
            read_data(1'b0);
            #10; 
            
            // 5. So sánh k?t qu?
            if (rdata_o == expected_y) begin
                $display("[Test %0d] PASS: %0d * %0d + %0d = %0d", test_index, a_val, x_val, b_val, rdata_o);
                pass_count = pass_count + 1;
            end else begin
                $display("[Test %0d] FAIL: %0d * %0d + %0d = %0d (Expected: %0d)", test_index, a_val, x_val, b_val, rdata_o, expected_y);
                fail_count = fail_count + 1;
            end
            
            // L?NH QUAN TR?NG: Xóa c? Done ?? FSM quay v? vòng l?p m?i
            write_data(DONE_FLAG_ADDR, 32'd1);
            
            #20;
        end
    endtask

    // --- K?ch b?n Test ---
    initial begin
        RST = 1'b1;
        wvalid_i = 1'b0; arvalid_i = 1'b0;
        waddr_i = 0; wdata_i = 0; raddr_i = 0;

        #15 RST = 1'b0; 
        #20 RST = 1'b1; 
        #10;
        
        $display("===========================================");
        $display("          B?T ??U CH?Y 20 TEST CASES       ");
        $display("===========================================");

        run_test(10,    5,     7,     57);      
        run_test(0,     5,     7,     7);       
        run_test(10,    0,     7,     7);       
        run_test(10,    5,     0,     50);      
        run_test(0,     0,     0,     0);       
        run_test(1,     1,     1,     2);       
        run_test(100,   2,     50,    250);     
        run_test(2,     100,   50,    250);     
        run_test(12,    12,    10,    154);     
        run_test(50,    50,    100,   2600);    
        run_test(99,    0,     99,    99);      
        run_test(255,   2,     10,    520);     
        run_test(1024,  4,     0,     4096);    
        run_test(11,    11,    11,    132);     
        run_test(5,     20,    0,     100);     
        run_test(8,     8,     64,    128);     
        run_test(3,     33,    1,     100);     
        run_test(15,    10,    50,    200);     
        run_test(1000,  1000,  500,   1000500); 
        run_test(4095,  2,     10,    8200);    
        
        $display("===========================================");
        $display("                TEST SUMMARY               ");
        $display("===========================================");
        $display("T?ng s? Test Cases: %0d", pass_count + fail_count);
        $display("Thành công (PASS) : %0d", pass_count);
        $display("Th?t b?i   (FAIL) : %0d", fail_count);
        
        if (fail_count == 0)
            $display(">>> K?T LU?N: M?CH HO?T ??NG CHÍNH XÁC 100% <<<");
        else
            $display(">>> K?T LU?N: M?CH CÓ L?I, C?N KI?M TRA L?I <<<");
        $display("===========================================");

        #50;
        $finish;
    end

endmodule