module MAC #(
    parameter WADDR_WIDTH  = 3,
    parameter WDATA_DWIDTH = 32,
    parameter RADDR_WIDTH  = 1,
    parameter RDATA_DWIDTH = 32
) (
    input wire                     CLK,
    input wire                     RST,

    // Write Channel
    input wire [WADDR_WIDTH-1:0]   waddr_i,
    input wire [WDATA_DWIDTH-1:0]  wdata_i,
    input wire                     wvalid_i,

    // Read Channel
    input wire [RADDR_WIDTH-1:0]   raddr_i,
    input wire                     arvalid_i,
    output reg [RDATA_DWIDTH-1:0]  rdata_o
);

    //-----------------------------------------//
    //       Parameter Declarations            //
    //-----------------------------------------//
    localparam s_IDLE            = 2'd0;
    localparam s_LOAD            = 2'd1;
    localparam s_EXEC            = 2'd2;
    localparam s_READ            = 2'd3;

    localparam LOAD_FLAG_ADDR    = 3'd0;
    localparam A_ADDR            = 3'd1;
    localparam X_ADDR            = 3'd2;
    localparam B_ADDR            = 3'd3;
    localparam START_FLAG_ADDR   = 3'd4;
    localparam DONE_FLAG_ADDR    = 3'd5;

    //-----------------------------------------//
    //       Wire Declarations                 //
    //-----------------------------------------//
    wire                         load_flag_w;
    wire                         start_flag_w;
    wire                         complete_flag_w;
    wire                         done_flag_w;

    //-----------------------------------------//
    //       Register Declarations             //
    //-----------------------------------------//
    reg [WDATA_DWIDTH-1:0]       A_r, X_r, B_r;
    reg [WDATA_DWIDTH-1:0]       Y_r; // Thanh ghi l?u k?t qu?
    reg [1:0]                    current_state_r;
    reg [1:0]                    next_state_r;

    //-----------------------------------------//
    //       Flag Assignment                   //
    //-----------------------------------------//
    assign load_flag_w     = (wvalid_i && waddr_i == LOAD_FLAG_ADDR)  ? wdata_i[0:0] : 1'b0;
    assign start_flag_w    = (wvalid_i && waddr_i == START_FLAG_ADDR) ? wdata_i[0:0] : 1'b0;
    assign done_flag_w     = (wvalid_i && waddr_i == DONE_FLAG_ADDR)  ? wdata_i[0:0] : 1'b0;
    assign complete_flag_w = (current_state_r == s_EXEC) ? 1'b1 : 1'b0; 

    //-----------------------------------------//
    //       Finite State Machine (FSM)        //
    //-----------------------------------------//
    always @(*) begin
        case (current_state_r)
            s_IDLE: begin
                if (load_flag_w)
                    next_state_r = s_LOAD;
                else
                    next_state_r = s_IDLE;
            end
            
            s_LOAD: begin
                if (start_flag_w)
                    next_state_r = s_EXEC;
                else
                    next_state_r = s_LOAD;
            end
            
            s_EXEC: begin
                if (complete_flag_w)
                    next_state_r = s_READ;
                else
                    next_state_r = s_EXEC;
            end
            
            s_READ: begin
                if (done_flag_w)
                    next_state_r = s_LOAD; // Quay l?i LOAD theo nh? logic trong ?nh
                else
                    next_state_r = s_READ;
            end
            
            default: begin
                next_state_r = s_IDLE;
            end
        endcase
    end

    always @(posedge CLK or negedge RST) begin
        if (!RST)
            current_state_r <= s_IDLE;
        else
            current_state_r <= next_state_r;
    end

    //-----------------------------------------//
    //              LOAD_STATE                 //
    //-----------------------------------------//
    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            A_r <= 0;
            X_r <= 0;
            B_r <= 0;
        end else if (wvalid_i) begin
            case (waddr_i)
                A_ADDR: A_r <= wdata_i;
                X_ADDR: X_r <= wdata_i;
                B_ADDR: B_r <= wdata_i;
            endcase
        end
    end

    //-----------------------------------------//
    //              EXEC_STATE                 //
    //-----------------------------------------//
    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            Y_r <= 0;
        end else if (current_state_r == s_EXEC) begin
            Y_r <= (A_r * X_r) + B_r;
        end
    end

    //-----------------------------------------//
    //              READ_STATE                 //
    //-----------------------------------------//
    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            rdata_o <= 0;
        end else if (arvalid_i) begin
            if (raddr_i == 1'b0) begin
                rdata_o <= Y_r;
            end else begin
                rdata_o <= {30'd0, current_state_r}; 
            end
        end
    end

endmodule