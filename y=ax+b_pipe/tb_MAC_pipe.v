`timescale 1ns / 1ps

module tb_MAC_50cases;

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
    integer i; // Bi?n cho vòng l?p for

    // --- Kh?i t?o module MAC (DUT) ---
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

    // --- T?o xung clock chu k? 10ns ---
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
    task write_data(input [WADDR_WIDTH-1:0] addr, input [WDATA_DWIDTH-1:0] data);
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
    task read_data(input [RADDR_WIDTH-1:0] addr);
        begin
            @(posedge CLK);
            raddr_i   = addr;
            arvalid_i = 1'b1;
            @(posedge CLK);
            arvalid_i = 1'b0;
        end
    endtask

    // --- Task ch?y 1 Test Case T? ??ng ---
    task run_test_auto(input [31:0] a_val, input [31:0] x_val, input [31:0] b_val);
        reg [31:0] expected_y;
        begin
            // T? ??ng tính k?t qu? ?úng ?? so sánh
            expected_y = a_val * x_val + b_val; 
            test_index = test_index + 1;
            
            write_data(LOAD_FLAG_ADDR, 32'd1);
            
            write_data(A_ADDR, a_val);
            write_data(X_ADDR, x_val);
            write_data(B_ADDR, b_val);
            
            write_data(START_FLAG_ADDR, 32'd1);
            
            #40; // ??i FSM x? lý (?? cho c? Single-cycle và Pipeline)
            
            read_data(1'b0);
            #10; 
            
            if (rdata_o == expected_y) begin
                $display("[Test %02d] PASS: %0d * %0d + %0d = %0d", test_index, a_val, x_val, b_val, rdata_o);
                pass_count = pass_count + 1;
            end else begin
                $display("[Test %02d] FAIL: %0d * %0d + %0d = %0d (Expected: %0d)", test_index, a_val, x_val, b_val, rdata_o, expected_y);
                fail_count = fail_count + 1;
            end
            
            // ??a FSM quay l?i s_LOAD
            write_data(DONE_FLAG_ADDR, 32'd1);
            
            #20;
        end
    endtask

    // --- K?ch b?n Test 50 Cases ---
    initial begin
        RST = 1'b1;
        wvalid_i = 1'b0; arvalid_i = 1'b0;
        waddr_i = 0; wdata_i = 0; raddr_i = 0;

        #15 RST = 1'b0; 
        #20 RST = 1'b1; 
        #10;
        
        $display("===========================================");
        $display("          B?T ??U CH?Y 50 TEST CASES       ");
        $display("===========================================");

        // --- 10 Edge Cases (Tr??ng h?p góc c?n ki?m tra k?) ---
        run_test_auto(10,    5,     7);     // Test 1: Bình th??ng
        run_test_auto(0,     5,     7);     // Test 2: A = 0
        run_test_auto(10,    0,     7);     // Test 3: X = 0
        run_test_auto(10,    5,     0);     // Test 4: B = 0
        run_test_auto(0,     0,     0);     // Test 5: T?t c? b?ng 0
        run_test_auto(1,     1,     1);     // Test 6: T?t c? b?ng 1
        run_test_auto(255,   255,   10);    // Test 7: Max 8-bit
        run_test_auto(1024,  1024,  4096);  // Test 8: L?y th?a c?a 2
        run_test_auto(65535, 2,     0);     // Test 9: Max 16-bit
        run_test_auto(999,   999,   999);   // Test 10: S? l?

        // --- 40 Random Cases (Tr??ng h?p ng?u nhiên) ---
        // S? d?ng $random % 10000 ?? gi?i h?n giá tr? không quá l?n tránh tràn s? 32-bit
        for (i = 0; i < 40; i = i + 1) begin
            run_test_auto(
                {$random} % 5000,   // Random A t? 0 ??n 4999
                {$random} % 5000,   // Random X t? 0 ??n 4999
                {$random} % 100000  // Random B t? 0 ??n 99999
            );
        end
        
        // --- T?ng k?t báo cáo ---
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
