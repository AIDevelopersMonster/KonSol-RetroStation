// KonSol RetroStation RS-005 LIGHT CYCLES RGB v0.1.0
// Two light trails, wall/trail collisions, optional simple CPU opponent.
// Verilog game logic only: no RISC-V, framebuffer, Flash, SD or external RAM.
// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
module lightcycles_rgb_core #(
    parameter integer STEP_FRAMES = 8
) (
    input wire clk, input wire reset_n,
    input wire [7:0] rx_byte, input wire rx_valid,
    output reg [1:0] palette, output wire ai_on,
    input wire s_axis_tvalid, output wire s_axis_tready,
    input wire [23:0] s_axis_tdata, input wire [0:0] s_axis_tuser,
    output wire m_axis_tvalid, input wire m_axis_tready,
    output wire [23:0] m_axis_tdata, output wire [0:0] m_axis_tuser
);
    localparam [1:0] READY=2'd0, PLAY=2'd1, OVER=2'd2;
    localparam [1:0] NORTH=2'd0, EAST=2'd1, SOUTH=2'd2, WEST=2'd3;
    localparam [9:0] BOARD_X=10'd64, BOARD_Y=10'd48;
    localparam [4:0] XMAX=5'd31, YMAX=5'd23;

    reg [1:0] state;
    reg [31:0] trail_a [0:23];
    reg [31:0] trail_b [0:23];
    reg [4:0] ax,ay,bx,by;
    reg [1:0] adir,bdir;
    reg [7:0] frame_count, blink;
    reg [3:0] wins_a, wins_b;
    reg [1:0] winner;             // 0=tie/none, 1=A, 2=B
    reg ai_enabled;
    reg start_pending, reset_pending, turn_a_valid, turn_b_valid;
    reg [1:0] turn_a,turn_b;

    assign ai_on=ai_enabled;
    assign s_axis_tready=m_axis_tready;
    assign m_axis_tvalid=s_axis_tvalid;
    assign m_axis_tuser=s_axis_tuser;
    wire accepted=s_axis_tvalid && m_axis_tready;
    wire frame_tick=accepted && s_axis_tuser[0];
    wire step_due=frame_count >= (STEP_FRAMES - 1);

    function [4:0] forward_x;
        input [4:0] x; input [1:0] direction;
        begin
            case(direction)
                EAST: forward_x=x+5'd1;
                WEST: forward_x=x-5'd1;
                default: forward_x=x;
            endcase
        end
    endfunction
    function [4:0] forward_y;
        input [4:0] y; input [1:0] direction;
        begin
            case(direction)
                NORTH: forward_y=y-5'd1;
                SOUTH: forward_y=y+5'd1;
                default: forward_y=y;
            endcase
        end
    endfunction
    // Gowin resource fix: use one dynamic trail read per player for
    // all three forward/left/right AI lookahead probes. The earlier three
    // parallel calls inferred six large independent asynchronous muxes.
    // One sweep completes in THREE pixel clocks, far faster than a game step.
    reg [1:0] ai_probe_phase;
    reg ai_forward_safe,ai_left_safe,ai_right_safe;
    wire [1:0] ai_probe_dir=(ai_probe_phase==0)?bdir:
                (ai_probe_phase==1)?(bdir-2'd1):(bdir+2'd1);
    wire [4:0] ai_probe_x=forward_x(bx,ai_probe_dir);
    wire [4:0] ai_probe_y=forward_y(by,ai_probe_dir);
    wire ai_probe_wall=(ai_probe_dir==NORTH && by==0) ||
                       (ai_probe_dir==SOUTH && by==YMAX) ||
                       (ai_probe_dir==WEST && bx==0) ||
                       (ai_probe_dir==EAST && bx==XMAX);
    wire ai_probe_busy=trail_a[ai_probe_y][ai_probe_x] ||
                       trail_b[ai_probe_y][ai_probe_x];
    wire ai_probe_safe=!ai_probe_wall && ai_probe_y<5'd24 &&
                       !ai_probe_busy;
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            ai_probe_phase<=0;
            ai_forward_safe<=0;ai_left_safe<=0;ai_right_safe<=0;
        end else begin
            if(ai_probe_phase==0) begin
                ai_forward_safe<=ai_probe_safe; ai_probe_phase<=1;
            end else if(ai_probe_phase==1) begin
                ai_left_safe<=ai_probe_safe; ai_probe_phase<=2;
            end else begin
                ai_right_safe<=ai_probe_safe; ai_probe_phase<=0;
            end
        end
    end
    // Atomic direction selection on each game step; reverse moves ignored.
    wire [1:0] a_effective=(turn_a_valid && turn_a!=(adir ^ 2'd2)) ? turn_a : adir;
    reg [1:0] b_effective;
    always @* begin
        b_effective=bdir;
        if (ai_enabled) begin
            if (!ai_forward_safe) begin
                if (ai_left_safe)
                    b_effective=bdir-2'd1;
                else if (ai_right_safe)
                    b_effective=bdir+2'd1;
            end
        end else if (turn_b_valid && turn_b!=(bdir ^ 2'd2))
            b_effective=turn_b;
    end
    wire [4:0] anx=forward_x(ax,a_effective);
    wire [4:0] any_=forward_y(ay,a_effective);
    wire [4:0] bnx=forward_x(bx,b_effective);
    wire [4:0] bny=forward_y(by,b_effective);
    wire same_target=(anx==bnx && any_==bny);
    // Direct array references: combinational collision logic must reevaluate
    // when trail RAM changes, not only when position/function arguments change.
    // Explicit wall checks prevent 5-bit coordinate wraparound.
    wire a_wall=(a_effective==NORTH && ay==0) ||
                (a_effective==SOUTH && ay==YMAX) ||
                (a_effective==WEST && ax==0) ||
                (a_effective==EAST && ax==XMAX);
    wire b_wall=(b_effective==NORTH && by==0) ||
                (b_effective==SOUTH && by==YMAX) ||
                (b_effective==WEST && bx==0) ||
                (b_effective==EAST && bx==XMAX);
    wire a_occupied=trail_a[any_][anx] || trail_b[any_][anx];
    wire b_occupied=trail_a[bny][bnx] || trail_b[bny][bnx];
    wire a_crash=a_wall || a_occupied || same_target;
    wire b_crash=b_wall || b_occupied || same_target;

    // UART commands. w/a/s/d: P1 N/W/S/E. i/j/k/l: P2 N/W/S/E.
    // A single key-down byte is enough; no held-direction state required.
    // p/space=start round, r=reset match, t=toggle AI P2, 1-4=palette.
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            palette<=0; ai_enabled<=1'b1;
            start_pending<=0; reset_pending<=0;
            turn_a_valid<=0; turn_b_valid<=0;
            turn_a<=NORTH; turn_b<=NORTH;
        end else begin
            if(frame_tick) begin
                start_pending<=0; reset_pending<=0;
                if(state!=PLAY || step_due) begin
                    turn_a_valid<=0; turn_b_valid<=0;
                end
            end
            if(rx_valid) begin
                case(rx_byte)
                    8'h77: begin turn_a<=NORTH; turn_a_valid<=1; end // w
                    8'h64: begin turn_a<=EAST;  turn_a_valid<=1; end // d
                    8'h73: begin turn_a<=SOUTH; turn_a_valid<=1; end // s
                    8'h61: begin turn_a<=WEST;  turn_a_valid<=1; end // a
                    8'h69: begin turn_b<=NORTH; turn_b_valid<=1; end // i
                    8'h6c: begin turn_b<=EAST;  turn_b_valid<=1; end // l
                    8'h6b: begin turn_b<=SOUTH; turn_b_valid<=1; end // k
                    8'h6a: begin turn_b<=WEST;  turn_b_valid<=1; end // j
                    8'h70,8'h20: start_pending<=1;
                    8'h72: reset_pending<=1;
                    8'h74: ai_enabled<=!ai_enabled;
                    8'h31: palette<=0;
                    8'h32: palette<=1;
                    8'h33: palette<=2;
                    8'h34: palette<=3;
                    default: ;
                endcase
            end
        end
    end

    integer row;
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            for(row=0;row<24;row=row+1) begin
                trail_a[row]<=0;trail_b[row]<=0;
            end
            state<=READY; ax<=7;ay<=10;adir<=EAST;
            bx<=24;by<=13;bdir<=WEST;
            frame_count<=0;blink<=0;winner<=0;
            wins_a<=0;wins_b<=0;
        end else if(frame_tick && reset_pending) begin
            for(row=0;row<24;row=row+1) begin
                trail_a[row]<=0;trail_b[row]<=0;
            end
            state<=READY; ax<=7;ay<=10;adir<=EAST;
            bx<=24;by<=13;bdir<=WEST;
            frame_count<=0;blink<=0;winner<=0;
            wins_a<=0;wins_b<=0;
        end else begin
            if(frame_tick)blink<=blink+8'd1;
            case(state)
                READY,OVER: begin
                    if(frame_tick && start_pending) begin
                        for(row=0;row<24;row=row+1) begin
                            trail_a[row]<=0;trail_b[row]<=0;
                        end
                        ax<=7;ay<=10;adir<=EAST;
                        bx<=24;by<=13;bdir<=WEST;
                        trail_a[10][7]<=1'b1;
                        trail_b[13][24]<=1'b1;
                        winner<=0;frame_count<=0;state<=PLAY;
                    end
                end
                PLAY: begin
                    if(frame_tick) begin
                        if(step_due) begin
                            frame_count<=0;
                            adir<=a_effective;
                            bdir<=b_effective;
                            if(a_crash || b_crash) begin
                                state<=OVER;
                                if(a_crash && !b_crash) begin
                                    winner<=2;
                                    if(wins_b<9) wins_b<=wins_b+4'd1;
                                end else if(b_crash && !a_crash) begin
                                    winner<=1;
                                    if(wins_a<9) wins_a<=wins_a+4'd1;
                                end else winner<=0;
                            end else begin
                                ax<=anx;ay<=any_; bx<=bnx;by<=bny;
                                trail_a[any_][anx]<=1'b1;
                                trail_b[bny][bnx]<=1'b1;
                            end
                        end else frame_count<=frame_count+8'd1;
                    end
                end
                default:state<=READY;
            endcase
        end
    end

    // 640x480 streaming raster overlay, no framebuffer, no CPU.
    reg [9:0] scan_x,scan_y;
    wire [9:0] px=s_axis_tuser[0]?10'd0:scan_x;
    wire [9:0] py=s_axis_tuser[0]?10'd0:scan_y;
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n)begin scan_x<=0;scan_y<=0;end
        else if(accepted) begin
            if(s_axis_tuser[0]) begin scan_x<=1;scan_y<=0;end
            else if(scan_x==639)begin
                scan_x<=0;scan_y<=scan_y==479?10'd0:scan_y+10'd1;
            end else scan_x<=scan_x+10'd1;
        end
    end
    wire board=px>=BOARD_X && px<BOARD_X+10'd512 &&
               py>=BOARD_Y && py<BOARD_Y+10'd384;
    wire [9:0] dx=px-BOARD_X,dy=py-BOARD_Y;
    wire [4:0] col=dx[8:4];
    wire [4:0] r=dy[8:4];
    wire cell_a=board && trail_a[r][col];
    wire cell_b=board && trail_b[r][col];
    wire head_a=board && state!=READY && col==ax && r==ay;
    wire head_b=board && state!=READY && col==bx && r==by;
    wire grid=board && ((dx[3:0]==0)||(dy[3:0]==0));
    wire border=px>=BOARD_X-10'd3 && px<BOARD_X+10'd515 &&
                py>=BOARD_Y-10'd3 && py<BOARD_Y+10'd387 && !board;
    wire top_bar=py>=10'd13 && py<10'd30;
    wire score_a_pixel=top_bar && px>=10'd84 &&
                        px<(10'd84+{wins_a,4'b0});
    wire score_b_pixel=top_bar && px>=10'd410 &&
                        px<(10'd410+{wins_b,4'b0});
    wire ready_banner=(state==READY && blink[4] && py>=10'd444 && py<10'd461
                       && px>=10'd208 && px<10'd432);
    wire game_over_banner=(state==OVER && blink[4] &&
                       py>=10'd444 && py<10'd461 &&
                       px>=10'd175 && px<10'd465);
    wire ai_indicator=ai_enabled && py>=10'd10 && py<10'd34 &&
                      px>=10'd296 && px<10'd344;
    wire top_edge=py<10'd3 || py>=10'd477 || px<10'd3 || px>=10'd637;

    wire [23:0] a_color=palette==0?24'h00E5FE:
                        palette==1?24'h65F4B7:
                        palette==2?24'hF4E55A:24'hA980FF;
    wire [23:0] b_color=palette==0?24'hFF647D:
                        palette==1?24'hFFB24B:
                        palette==2?24'hFF77CA:24'hFFCA79;
    wire [23:0] bg=palette==0?24'h090F24:
                   palette==1?24'h082222:
                   palette==2?24'h170E2D:24'h241121;
    assign m_axis_tdata=
        (head_a||score_a_pixel) ? 24'hD9FFFF:
        (head_b||score_b_pixel) ? 24'hFFE2C1:
        cell_a ? a_color:
        cell_b ? b_color:
        (ready_banner || ai_indicator) ? 24'h48E5A9:
        game_over_banner ? (winner==1?a_color:winner==2?b_color:24'hF7C85A):
        border ? 24'h4EA9F2:
        grid ? 24'h182B43:
        top_edge ? 24'h36527A : bg;
    wire _unused=^s_axis_tdata;
endmodule
