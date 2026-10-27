// KonSol RetroStation RS-007 MAZE CHASE RGB v0.1.0
// Original native-Verilog 28x24 tile maze; 455 reachable energy dots.
// Two enemies: deterministic wall-following patrol and greedy axis chaser.
// UART+SVO interface; one 25.2 MHz domain, no CPU/framebuffer/external RAM.
// SPDX-License-Identifier: MIT
module mazechase_rgb_core #(
    parameter integer STEP_FRAMES=8,
    parameter integer HIT_GRACE_FRAMES=36
)(
    input wire clk,input wire reset_n,
    input wire [7:0] rx_byte,input wire rx_valid,
    output reg [1:0] palette,output wire playing,
    input wire s_axis_tvalid,output wire s_axis_tready,
    input wire [23:0] s_axis_tdata,input wire [0:0] s_axis_tuser,
    output wire m_axis_tvalid,input wire m_axis_tready,
    output wire [23:0] m_axis_tdata,output wire [0:0] m_axis_tuser
);
    localparam [1:0] READY=0,PLAY=1,WON=2,LOST=3;
    localparam [1:0] NORTH=0,EAST=1,SOUTH=2,WEST=3;
    localparam [4:0] SPAWN_X=5'd2,SPAWN_Y=5'd2;
    localparam [9:0] DOT_TOTAL=10'd455;

    reg [1:0] state;
    reg [4:0] player_x,player_y,patrol_x,patrol_y,chaser_x,chaser_y;
    reg [1:0] wanted_dir,patrol_dir,chaser_dir;
    reg [1:0] lives;
    reg [9:0] score,remaining;
    reg [7:0] frame_count,blink,grace;
    reg start_pending,reset_pending;
    reg [27:0] dots [0:23];
    assign playing=(state==PLAY);

    // Fixed original maze. Every traversable tile is reachable from (2,2);
    // a BFS check in the development notes verifies all 455 free tiles.
    // Boundary: x=0/27, y=0/23. Cross-walls have explicit four-cell gates.
    function wall;
        input [4:0] x,y;
        begin
            wall=(x==0 || x>=5'd27 || y==0 || y>=5'd23) ||
                 ((x==5'd6 || x==5'd13 || x==5'd20) &&
                  !(y==5'd4 || y==5'd11 || y==5'd18)) ||
                 ((y==5'd6 || y==5'd12 || y==5'd18) &&
                  !(x==5'd3 || x==5'd10 || x==5'd17 || x==5'd24));
        end
    endfunction
    // Per-row reset constants, not an inferred multiported pixel RAM.
    // Each bit corresponds to one open tile; exactly 455 bits are set.
    function [27:0] initial_dots;
        input [4:0] y;
        begin
            case(y)
                5'd0,5'd23: initial_dots=28'h0000000;
                5'd4,5'd11: initial_dots=28'h7fffffe;
                5'd6,5'd12,5'd18: initial_dots=28'h1020408;
                default: initial_dots=28'h7efdfbe;
            endcase
        end
    endfunction
    function [4:0] next_x;
        input [4:0] x;input [1:0] dir;
        begin
            case(dir)
                EAST: next_x=x+5'd1;
                WEST: next_x=x-5'd1;
                default:next_x=x;
            endcase
        end
    endfunction
    function [4:0] next_y;
        input [4:0] y;input [1:0] dir;
        begin
            case(dir)
                NORTH:next_y=y-5'd1;
                SOUTH:next_y=y+5'd1;
                default:next_y=y;
            endcase
        end
    endfunction

    // A direction byte persists until the player chooses another one.
    // Serial commands are one-shot, making Web Serial and PowerShell agree.
    assign s_axis_tready=m_axis_tready;
    assign m_axis_tvalid=s_axis_tvalid;
    assign m_axis_tuser=s_axis_tuser;
    wire accepted=s_axis_tvalid && m_axis_tready;
    wire frame_tick=accepted && s_axis_tuser[0];
    wire step_due=frame_count>=STEP_FRAMES-1;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            palette<=0;wanted_dir<=EAST;
            start_pending<=0;reset_pending<=0;
        end else begin
            if(frame_tick) begin
                start_pending<=0;
                reset_pending<=0;
            end
            if(rx_valid) begin
                case(rx_byte)
                    8'h77: wanted_dir<=NORTH; // w
                    8'h64: wanted_dir<=EAST;  // d
                    8'h73: wanted_dir<=SOUTH; // s
                    8'h61: wanted_dir<=WEST;  // a
                    8'h70,8'h20: start_pending<=1; // p, space
                    8'h72: reset_pending<=1;       // r
                    8'h31: palette<=0;
                    8'h32: palette<=1;
                    8'h33: palette<=2;
                    8'h34: palette<=3;
                    default:;
                endcase
            end
        end
    end

    // Player's single candidate cell and one dynamic dot read.
    wire [4:0] p_target_x=next_x(player_x,wanted_dir);
    wire [4:0] p_target_y=next_y(player_y,wanted_dir);
    wire p_can_move=!wall(p_target_x,p_target_y);
    wire [4:0] p_next_x=p_can_move?p_target_x:player_x;
    wire [4:0] p_next_y=p_can_move?p_target_y:player_y;
    wire collect=p_can_move && dots[p_next_y][p_next_x];

    // Patrol: go straight, otherwise right, then left, then reverse.
    wire [1:0] patrol_right=patrol_dir+2'd1;
    wire [1:0] patrol_left=patrol_dir-2'd1;
    wire [1:0] patrol_back=patrol_dir+2'd2;
    wire patrol_forward_ok=!wall(next_x(patrol_x,patrol_dir),
                                 next_y(patrol_y,patrol_dir));
    wire patrol_right_ok=!wall(next_x(patrol_x,patrol_right),
                               next_y(patrol_y,patrol_right));
    wire patrol_left_ok=!wall(next_x(patrol_x,patrol_left),
                              next_y(patrol_y,patrol_left));
    wire [1:0] patrol_choice=patrol_forward_ok?patrol_dir:
        patrol_right_ok?patrol_right:
        patrol_left_ok?patrol_left:patrol_back;
    wire patrol_can_move=!wall(next_x(patrol_x,patrol_choice),
                               next_y(patrol_y,patrol_choice));
    wire [4:0] patrol_nx=patrol_can_move?
        next_x(patrol_x,patrol_choice):patrol_x;
    wire [4:0] patrol_ny=patrol_can_move?
        next_y(patrol_y,patrol_choice):patrol_y;

    // Chaser: compare Manhattan axis magnitudes; prefer dominant axis,
    // try the other axis if blocked, then a deterministic wall turn.
    // This is *greedy pursuit*, not a full shortest-path/BFS solver.
    wire [4:0] dx=(player_x>chaser_x)?(player_x-chaser_x):
                                                 (chaser_x-player_x);
    wire [4:0] dy=(player_y>chaser_y)?(player_y-chaser_y):
                                                 (chaser_y-player_y);
    wire [1:0] toward_x=(player_x<chaser_x)?WEST:EAST;
    wire [1:0] toward_y=(player_y<chaser_y)?NORTH:SOUTH;
    wire chase_x_first=(dx>=dy);
    wire [1:0] preferred=chase_x_first?toward_x:toward_y;
    wire [1:0] alternate=chase_x_first?toward_y:toward_x;
    wire chase_preferred_ok=!wall(next_x(chaser_x,preferred),
                                  next_y(chaser_y,preferred));
    wire chase_alternate_ok=!wall(next_x(chaser_x,alternate),
                                  next_y(chaser_y,alternate));
    wire [1:0] chase_right=chaser_dir+2'd1;
    wire [1:0] chase_left=chaser_dir-2'd1;
    wire chase_right_ok=!wall(next_x(chaser_x,chase_right),
                              next_y(chaser_y,chase_right));
    wire chase_left_ok=!wall(next_x(chaser_x,chase_left),
                             next_y(chaser_y,chase_left));
    wire [1:0] chase_choice=chase_preferred_ok?preferred:
        chase_alternate_ok?alternate:
        chase_right_ok?chase_right:
        chase_left_ok?chase_left:(chaser_dir+2'd2);
    wire chase_can_move=!wall(next_x(chaser_x,chase_choice),
                              next_y(chaser_y,chase_choice));
    wire [4:0] chase_nx=chase_can_move?
        next_x(chaser_x,chase_choice):chaser_x;
    wire [4:0] chase_ny=chase_can_move?
        next_y(chaser_y,chase_choice):chaser_y;

    // Same-tile collision or exchanging player/enemy positions in a tick.
    wire patrol_hit=((p_next_x==patrol_nx && p_next_y==patrol_ny) ||
                     (p_next_x==patrol_x && p_next_y==patrol_y) ||
                     (player_x==patrol_nx && player_y==patrol_ny &&
                      p_next_x==patrol_x && p_next_y==patrol_y));
    wire chase_hit=((p_next_x==chase_nx && p_next_y==chase_ny) ||
                    (p_next_x==chaser_x && p_next_y==chaser_y) ||
                    (player_x==chase_nx && player_y==chase_ny &&
                     p_next_x==chaser_x && p_next_y==chaser_y));
    wire collision=patrol_hit||chase_hit;
    wire mortal_collision=collision && grace==0;
    wire eat=collect && !mortal_collision;

    // Dots are a single state plane; only one bit is cleared per game tick.
    // Never write pixels into a full 640x480 framebuffer.
    integer row;
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            for(row=0;row<24;row=row+1)
                dots[row]<=initial_dots(row);
        end else if(frame_tick) begin
            if(reset_pending || (state!=PLAY && start_pending)) begin
                for(row=0;row<24;row=row+1)
                    dots[row]<=initial_dots(row);
            end else if(state==PLAY && step_due && eat) begin
                dots[p_next_y][p_next_x]<=1'b0;
            end
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            state<=READY;player_x<=SPAWN_X;player_y<=SPAWN_Y;
            patrol_x<=5'd25;patrol_y<=5'd2;patrol_dir<=WEST;
            chaser_x<=5'd25;chaser_y<=5'd21;chaser_dir<=WEST;
            frame_count<=0;blink<=0;grace<=0;
            score<=0;remaining<=DOT_TOTAL;lives<=3;
        end else if(frame_tick) begin
            blink<=blink+8'd1;
            if(reset_pending || (state!=PLAY && start_pending)) begin
                state<=reset_pending?READY:PLAY;
                player_x<=SPAWN_X;player_y<=SPAWN_Y;
                patrol_x<=5'd25;patrol_y<=5'd2;patrol_dir<=WEST;
                chaser_x<=5'd25;chaser_y<=5'd21;chaser_dir<=WEST;
                frame_count<=0;grace<=0;
                score<=0;remaining<=DOT_TOTAL;lives<=3;
            end else if(state==PLAY) begin
                if(grace!=0) grace<=grace-8'd1;
                if(step_due) begin
                    frame_count<=0;
                    if(mortal_collision) begin
                        if(lives==1) begin
                            lives<=0;state<=LOST;
                        end else begin
                            lives<=lives-2'd1;
                            grace<=HIT_GRACE_FRAMES;
                            player_x<=SPAWN_X;player_y<=SPAWN_Y;
                            patrol_x<=5'd25;patrol_y<=5'd2;
                            patrol_dir<=WEST;
                            chaser_x<=5'd25;chaser_y<=5'd21;
                            chaser_dir<=WEST;
                        end
                    end else begin
                        player_x<=p_next_x;player_y<=p_next_y;
                        patrol_x<=patrol_nx;patrol_y<=patrol_ny;
                        patrol_dir<=patrol_choice;
                        chaser_x<=chase_nx;chaser_y<=chase_ny;
                        chaser_dir<=chase_choice;
                        if(eat) begin
                            score<=score+10'd1;
                            remaining<=remaining-10'd1;
                            if(remaining==10'd1) state<=WON;
                        end
                    end
                end else frame_count<=frame_count+8'd1;
            end
        end
    end

    // Streaming pixel coordinates. SVO user[0] denotes frame pixel (0,0).
    reg [9:0] scan_x,scan_y;
    wire [9:0] px=s_axis_tuser[0]?10'd0:scan_x;
    wire [9:0] py=s_axis_tuser[0]?10'd0:scan_y;
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin scan_x<=0;scan_y<=0;end
        else if(accepted) begin
            if(s_axis_tuser[0]) begin scan_x<=1;scan_y<=0;end
            else if(scan_x==10'd639) begin
                scan_x<=0;scan_y<= (scan_y==10'd479) ? 10'd0 : (scan_y+10'd1);
            end else scan_x<=scan_x+10'd1;
        end
    end
    // Each cell is 16x16 pixels, arena centered (448x384).
    wire in_arena=(px>=10'd96 && px<10'd544 &&
                   py>=10'd48 && py<10'd432);
    wire [9:0] dxpix=px-10'd96,dypix=py-10'd48;
    wire [4:0] tx=dxpix[8:4],ty=dypix[8:4];
    wire tile_wall=in_arena && wall(tx,ty);
    wire pellet=in_arena && dots[ty][tx] &&
        dxpix[3:0]>=4'd6 && dxpix[3:0]<4'd10 &&
        dypix[3:0]>=4'd6 && dypix[3:0]<4'd10;
    wire hero=in_arena && state!=LOST &&
        tx==player_x && ty==player_y &&
        dxpix[3:0]>=4'd3 && dxpix[3:0]<4'd13 &&
        dypix[3:0]>=4'd3 && dypix[3:0]<4'd13 &&
        (grace[2] || grace==0);
    wire sentinel=in_arena && tx==patrol_x && ty==patrol_y &&
        dxpix[3:0]>=4'd2 && dxpix[3:0]<4'd14 &&
        dypix[3:0]>=4'd2 && dypix[3:0]<4'd14;
    wire hunter=in_arena && tx==chaser_x && ty==chaser_y &&
        dxpix[3:0]>=4'd2 && dxpix[3:0]<4'd14 &&
        dypix[3:0]>=4'd2 && dypix[3:0]<4'd14;
    wire grid=in_arena && (dxpix[3:0]==0 || dypix[3:0]==0);
    wire border=px>=10'd93 && px<10'd547 &&
                py>=10'd45 && py<10'd435 && !in_arena;
    wire [9:0] shown_score=(score>=10'd48) ? 10'd384 : {score[5:0],3'b0};
    wire score_bar=(py>=10'd13 && py<10'd26 &&
        px>=10'd178 && px<10'd178+shown_score);
    wire life_bar=(py>=10'd12 && py<10'd27 &&
        ((lives>=1 && px>=10'd50 && px<10'd72) ||
         (lives>=2 && px>=10'd79 && px<10'd101) ||
         (lives>=3 && px>=10'd108 && px<10'd130)));
    wire banner=(state==READY || state==WON || state==LOST) &&
        blink[4] && py>=10'd445 && py<10'd463 &&
        px>=10'd174 && px<10'd466;
    wire screen_edge=py<10'd3 || py>=10'd477 || px<10'd3 || px>=10'd637;

    // SVO's packed color order is BGR888 (B high, R low).
    wire [23:0] bg=palette==0?24'h120B09:
                   palette==1?24'h0B2012:
                   palette==2?24'h271327:24'h151D08;
    wire [23:0] wallcolor=palette==0?24'hD56438:
                          palette==1?24'h6AE54A:
                          palette==2?24'hB94EC9:24'h5AD4CA;
    wire [23:0] dotcolor=palette==0?24'h4FE4FF:
                         palette==1?24'h67F6D5:
                         palette==2?24'hA8E5FF:24'h4DE5FD;
    assign m_axis_tdata=
        hero?24'h63FFEE:
        sentinel?24'h336BFF:
        hunter?24'hE85BA8:
        tile_wall?wallcolor:
        pellet?dotcolor:
        score_bar?24'h72EFFF:
        life_bar?24'h65F36C:
        banner?(state==WON?24'h4BF66B:
                state==LOST?24'h4D6BFF:24'hE5D96F):
        border?24'hB6B6F1:
        grid?24'h2B2B35:
        screen_edge?24'h425174:bg;
    wire _unused=^s_axis_tdata;
endmodule
