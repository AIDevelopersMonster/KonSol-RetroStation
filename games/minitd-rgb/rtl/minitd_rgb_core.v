// KonSol RetroStation RS-008 MINI TD RGB v0.1.0
// Original native-Verilog 24x16 tower defense game for Tang Nano 9K.
// All state lives in the pixel-clock domain. No framebuffer, CPU, RAM or ROM.
// Eight enemies, four independently positioned towers, five waves.
// One target-distance evaluation PER clock, not 4x8 at once.
// SPDX-License-Identifier: MIT
module minitd_rgb_core #(
    parameter integer STEP_FRAMES = 8
)(
    input wire clk, reset_n,
    input wire [7:0] rx_byte,
    input wire rx_valid,
    output reg [1:0] palette,
    output wire playing,
    input wire s_axis_tvalid, s_axis_tready,
    input wire [23:0] s_axis_tdata,
    input wire [0:0] s_axis_tuser,
    output wire m_axis_tvalid,
    input wire m_axis_tready,
    output wire [23:0] m_axis_tdata,
    output wire [0:0] m_axis_tuser
);
    localparam [1:0] READY=0, PLAY=1, WON=2, LOST=3;
    localparam [2:0] IDLE=0, SCAN=1, FIRE=2, MOVE=3, SPAWN=4, FINISH=5;
    localparam [6:0] PATH_END=7'd68;
    reg [1:0] state;
    reg [2:0] phase, wave;
    reg [7:0] credits, kills;
    reg [4:0] base_hp;
    reg [3:0] wave_goal, spawned, spawn_delay;
    reg [7:0] enemy_active;
    reg [6:0] enemy_pos [0:7];
    reg [2:0] enemy_hp [0:7];
    reg [3:0] tower_built, tower_heavy, tower_cool, tower_flash;
    reg [1:0] selected_slot;
    reg selected_heavy;
    reg [7:0] frame_count;
    reg [1:0] tower_idx;
    reg [2:0] scan_idx, enemy_idx, best_idx;
    reg [6:0] best_progress;
    reg best_valid;
    integer i;
    assign playing=(state==PLAY);

    // Original five-segment, unbranched route, 69 coordinates including
    // entrance and exit. No shortest-path solver or writable map required.
    function [4:0] route_x;
        input [6:0] p;
        begin
            if(p<=7'd20) route_x=5'd1+p[4:0];
            else if(p<=7'd24) route_x=5'd21;
            else if(p<=7'd43) route_x=5'd21-(p-7'd24);
            else if(p<=7'd48) route_x=5'd2;
            else route_x=5'd2+(p-7'd48);
        end
    endfunction
    function [4:0] route_y;
        input [6:0] p;
        begin
            if(p<=7'd20) route_y=5'd3;
            else if(p<=7'd24) route_y=5'd3+(p-7'd20);
            else if(p<=7'd43) route_y=5'd7;
            else if(p<=7'd48) route_y=5'd7+(p-7'd43);
            else route_y=5'd12;
        end
    endfunction
    function is_road;
        input [4:0] x,y;
        begin
            is_road=(y==5'd3 && x>=5'd1 && x<=5'd21) ||
                    (x==5'd21 && y>=5'd3 && y<=5'd7) ||
                    (y==5'd7 && x>=5'd2 && x<=5'd21) ||
                    (x==5'd2 && y>=5'd7 && y<=5'd12) ||
                    (y==5'd12 && x>=5'd2 && x<=5'd22);
        end
    endfunction
    function [4:0] pad_x;
        input [1:0] n;
        begin
            case(n)
                0:pad_x=5'd6;
                1:pad_x=5'd18;
                2:pad_x=5'd10;
                default:pad_x=5'd19;
            endcase
        end
    endfunction
    function [4:0] pad_y;
        input [1:0] n;
        begin
            case(n)
                0:pad_y=5'd1;
                1:pad_y=5'd5;
                2:pad_y=5'd9;
                default:pad_y=5'd14;
            endcase
        end
    endfunction
    function [4:0] abs5;
        input [4:0] a,b;
        begin abs5=(a>=b)?(a-b):(b-a);end
    endfunction
    function [2:0] wave_enemy_hp;
        input [2:0] w;
        begin
            case(w)
                1,2:wave_enemy_hp=3'd2;
                3,4:wave_enemy_hp=3'd3;
                default:wave_enemy_hp=3'd4;
            endcase
        end
    endfunction

    // One mutable enemy is examined on each 25.2 MHz pixel clock.
    // Tower/target selection is pipelined over <=36 pixel cycles per step.
    wire [6:0] examined_progress=enemy_pos[scan_idx];
    wire [4:0] examined_x=route_x(examined_progress);
    wire [4:0] examined_y=route_y(examined_progress);
    wire [4:0] candidate_tx=pad_x(tower_idx);
    wire [4:0] candidate_ty=pad_y(tower_idx);
    wire [5:0] manhattan={1'b0,abs5(examined_x,candidate_tx)}+
                          {1'b0,abs5(examined_y,candidate_ty)};
    wire in_range=(manhattan <= (tower_heavy[tower_idx]?6'd5:6'd4));
    wire can_aim=tower_built[tower_idx] && !tower_cool[tower_idx] &&
                 enemy_active[scan_idx] && in_range;
    wire [2:0] damage=tower_heavy[tower_idx]?3'd2:3'd1;
    wire frame_tick=s_axis_tvalid && m_axis_tready && s_axis_tuser[0];

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            state<=READY; phase<=IDLE; wave<=0;
            credits<=12; kills<=0; base_hp<=12;
            wave_goal<=0; spawned<=0;spawn_delay<=0;
            enemy_active<=0;
            tower_built<=0; tower_heavy<=0;tower_cool<=0;tower_flash<=0;
            selected_slot<=0;selected_heavy<=0;palette<=0;
            frame_count<=0;tower_idx<=0;scan_idx<=0;enemy_idx<=0;
            best_idx<=0;best_progress<=0;best_valid<=0;
            for(i=0;i<8;i=i+1) begin
                enemy_pos[i]<=0;enemy_hp[i]<=0;
            end
        end else if(rx_valid && rx_byte==8'h72) begin // R: full reset
            state<=READY;phase<=IDLE;wave<=0;
            credits<=12;kills<=0;base_hp<=12;
            wave_goal<=0;spawned<=0;spawn_delay<=0;
            enemy_active<=0;
            tower_built<=0;tower_heavy<=0;tower_cool<=0;tower_flash<=0;
            selected_slot<=0;selected_heavy<=0;palette<=0;
            frame_count<=0;tower_idx<=0;scan_idx<=0;enemy_idx<=0;
            best_idx<=0;best_progress<=0;best_valid<=0;
            for(i=0;i<8;i=i+1) begin
                enemy_pos[i]<=0;enemy_hp[i]<=0;
            end
        end else begin
            if(rx_valid) begin
                case(rx_byte)
                    8'h31:selected_slot<=0; // 1,2,3,4: choose pad
                    8'h32:selected_slot<=1;
                    8'h33:selected_slot<=2;
                    8'h34:selected_slot<=3;
                    8'h74:selected_heavy<=!selected_heavy; // T: type
                    8'h63:palette<=palette+2'd1; // C: palette
                    8'h62:begin // B: build if the pad is empty and funded
                        if(phase==IDLE && state!=WON && state!=LOST &&
                           !tower_built[selected_slot] &&
                           credits >= (selected_heavy?8'd5:8'd3)) begin
                            tower_built[selected_slot]<=1;
                            tower_heavy[selected_slot]<=selected_heavy;
                            tower_cool[selected_slot]<=0;
                            credits<=credits-(selected_heavy?8'd5:8'd3);
                        end
                    end
                    8'h70,8'h20:begin // P / space: advance one wave
                        if(state==READY && phase==IDLE && wave<3'd5) begin
                            wave<=wave+3'd1;
                            wave_goal<=4+{1'b0,wave}; // wave1 4 ... wave5 8
                            spawned<=0;spawn_delay<=0;
                            enemy_active<=0;frame_count<=0;
                            tower_flash<=0;tower_cool<=0;
                            state<=PLAY;
                            for(i=0;i<8;i=i+1) begin
                                enemy_pos[i]<=0;enemy_hp[i]<=0;
                            end
                        end
                    end
                    default:;
                endcase
            end
            case(phase)
                IDLE:begin
                    if(frame_tick && state==PLAY) begin
                        if(frame_count >= STEP_FRAMES-1) begin
                            frame_count<=0;
                            tower_flash<=0;
                            tower_idx<=0;scan_idx<=0;best_valid<=0;
                            best_progress<=0;phase<=SCAN;
                        end else frame_count<=frame_count+8'd1;
                    end
                end
                SCAN:begin
                    if(can_aim && (!best_valid ||
                       examined_progress > best_progress)) begin
                        best_valid<=1;
                        best_idx<=scan_idx;
                        best_progress<=examined_progress;
                    end
                    if(scan_idx==3'd7) phase<=FIRE;
                    else scan_idx<=scan_idx+3'd1;
                end
                FIRE:begin
                    if(tower_cool[tower_idx]) tower_cool[tower_idx]<=0;
                    else if(tower_built[tower_idx] && best_valid) begin
                        tower_flash[tower_idx]<=1;
                        if(tower_heavy[tower_idx]) tower_cool[tower_idx]<=1;
                        if(enemy_hp[best_idx]<=damage) begin
                            enemy_active[best_idx]<=0;
                            enemy_hp[best_idx]<=0;
                            credits<=credits+8'd1;
                            kills<=kills+8'd1;
                        end else enemy_hp[best_idx]<=enemy_hp[best_idx]-damage;
                    end
                    if(tower_idx==2'd3) begin
                        phase<=MOVE;enemy_idx<=0;
                    end else begin
                        tower_idx<=tower_idx+2'd1;
                        scan_idx<=0;best_valid<=0;best_progress<=0;
                        phase<=SCAN;
                    end
                end
                MOVE:begin
                    if(enemy_active[enemy_idx]) begin
                        if(enemy_pos[enemy_idx]>=PATH_END) begin
                            enemy_active[enemy_idx]<=0;
                            if(base_hp!=0) base_hp<=base_hp-5'd1;
                        end else enemy_pos[enemy_idx]<=enemy_pos[enemy_idx]+7'd1;
                    end
                    if(enemy_idx==3'd7) phase<=SPAWN;
                    else enemy_idx<=enemy_idx+3'd1;
                end
                SPAWN:begin
                    if(spawned < wave_goal) begin
                        if(spawn_delay!=0) spawn_delay<=spawn_delay-4'd1;
                        else begin
                            enemy_active[spawned[2:0]]<=1;
                            enemy_pos[spawned[2:0]]<=0;
                            enemy_hp[spawned[2:0]]<=wave_enemy_hp(wave);
                            spawned<=spawned+4'd1;
                            spawn_delay<=2;
                        end
                    end
                    phase<=FINISH;
                end
                FINISH:begin
                    if(base_hp==0) state<=LOST;
                    else if(spawned==wave_goal && enemy_active==8'b0)
                        state<=(wave==3'd5)?WON:READY;
                    phase<=IDLE;
                end
                default:phase<=IDLE;
            endcase
        end
    end

    // Frame-accurate source coordinates (SVO first-pixel user flag).
    assign s_axis_tready=m_axis_tready;
    assign m_axis_tvalid=s_axis_tvalid;
    assign m_axis_tuser=s_axis_tuser;
    reg [9:0] scan_x,scan_y;
    wire accepted=s_axis_tvalid && m_axis_tready;
    wire [9:0] px=s_axis_tuser[0]?10'd0:scan_x;
    wire [9:0] py=s_axis_tuser[0]?10'd0:scan_y;
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin scan_x<=0;scan_y<=0;end
        else if(accepted) begin
            if(s_axis_tuser[0]) begin scan_x<=1;scan_y<=0;end
            else if(scan_x==10'd639) begin
                scan_x<=0;
                scan_y<=(scan_y==10'd479)?10'd0:scan_y+10'd1;
            end else scan_x<=scan_x+10'd1;
        end
    end
    wire in_field=(px>=10'd128 && px<10'd512 &&
                   py>=10'd112 && py<10'd368);
    wire [9:0] local_x=px-10'd128,local_y=py-10'd112;
    wire [4:0] tx=local_x[8:4],ty=local_y[8:4];
    wire road=in_field && is_road(tx,ty);
    reg on_pad,pad_occupied,pad_heavy,pad_selected,pad_firing;
    reg on_enemy;
    integer k;
    always @* begin
        on_pad=0;pad_occupied=0;pad_heavy=0;
        pad_selected=0;pad_firing=0;on_enemy=0;
        for(k=0;k<4;k=k+1) begin
            if(in_field && tx==pad_x(k[1:0]) && ty==pad_y(k[1:0])) begin
                on_pad=1;
                pad_occupied=tower_built[k];
                pad_heavy=tower_heavy[k];
                pad_selected=(selected_slot==k[1:0]);
                pad_firing=tower_flash[k];
            end
        end
        for(k=0;k<8;k=k+1) begin
            if(in_field && enemy_active[k] &&
               tx==route_x(enemy_pos[k]) && ty==route_y(enemy_pos[k]))
                on_enemy=1;
        end
    end
    reg [23:0] bg_color,field_color,road_color,grid_color;
    reg [23:0] tower_color,heavy_color,enemy_color,hud_color;
    always @* begin
        case(palette)
            0:begin // ocean/neon
                bg_color=24'h120C10;field_color=24'h241C13;
                road_color=24'h46332A;grid_color=24'h30251D;
                tower_color=24'hCFFF39;heavy_color=24'hD080FF;
                enemy_color=24'h3378FF;hud_color=24'hA0E060;
            end
            1:begin // amber arcade
                bg_color=24'h140A18;field_color=24'h191522;
                road_color=24'h265064;grid_color=24'h202B35;
                tower_color=24'h55BFFF;heavy_color=24'h2FFFF4;
                enemy_color=24'h6D49FF;hud_color=24'h32D9FF;
            end
            2:begin // green phosphor
                bg_color=24'h060C05;field_color=24'h0A1609;
                road_color=24'h173420;grid_color=24'h10301B;
                tower_color=24'h47F27A;heavy_color=24'h7EFCB0;
                enemy_color=24'h40A0DC;hud_color=24'h59FF73;
            end
            default:begin // violet
                bg_color=24'h200817;field_color=24'h361129;
                road_color=24'h663343;grid_color=24'h422034;
                tower_color=24'hF4E2A0;heavy_color=24'hFA9BFF;
                enemy_color=24'h55CEFF;hud_color=24'hFFFFA9;
            end
        endcase
    end
    reg [23:0] pixel_color;
    always @* begin
        pixel_color=bg_color;
        if(px>=10'd124 && px<10'd516 && py>=10'd108 && py<10'd372)
            pixel_color=hud_color;
        if(in_field) begin
            pixel_color=road?road_color:field_color;
            if(local_x[3:0]==0 || local_y[3:0]==0)
                pixel_color=road?grid_color:bg_color;
            if((tx==5'd1 && ty==5'd3) ||
               (tx==5'd22 && ty==5'd12))
                if(local_x[3:0]>3 && local_x[3:0]<12 &&
                   local_y[3:0]>3 && local_y[3:0]<12)
                    pixel_color=hud_color;
            if(on_pad) begin
                if(local_x[3:0]>=2 && local_x[3:0]<=13 &&
                   local_y[3:0]>=2 && local_y[3:0]<=13)
                    pixel_color=pad_occupied?
                                (pad_heavy?heavy_color:tower_color):
                                (pad_selected?hud_color:road_color);
                if(pad_selected &&
                   (local_x[3:0]==1 || local_x[3:0]==14 ||
                    local_y[3:0]==1 || local_y[3:0]==14))
                    pixel_color=hud_color;
                if(pad_firing &&
                   (local_x[3:0]==0 || local_y[3:0]==0))
                    pixel_color=enemy_color;
            end
            if(on_enemy && local_x[3:0]>=3 && local_x[3:0]<=12 &&
               local_y[3:0]>=3 && local_y[3:0]<=12)
                pixel_color=enemy_color;
        end
        // Top HUD: remaining base health, money, wave and kills.
        if(py>=10'd22 && py<10'd36) begin
            if(px>=10'd24 && px<10'd136) pixel_color=field_color;
            if(px>=10'd24 && px<10'd24+{base_hp,3'b0})
                pixel_color=enemy_color;
            if(px>=10'd168 && px<10'd330) pixel_color=field_color;
            if(px>=10'd168 && px<10'd168+{credits,2'b0})
                pixel_color=tower_color;
            if(px>=10'd388 && px<10'd505) pixel_color=field_color;
            if(px>=10'd388 && px<10'd388+({7'd0,wave}<<4))
                pixel_color=hud_color;
            if(px>=10'd532 && px<10'd620) pixel_color=field_color;
            if(px>=10'd532 && px<10'd532+{kills[4:0],2'b0})
                pixel_color=heavy_color;
        end
        // Bottom state strip, one color for each game state.
        if(py>=10'd420 && py<10'd442 && px>=10'd128 && px<10'd512)
            pixel_color=(state==PLAY)?hud_color:
                        (state==READY)?tower_color:
                        (state==WON)?heavy_color:enemy_color;
        if(py>=10'd424 && py<10'd438 && px>=10'd134 && px<10'd506)
            pixel_color=bg_color;
        if(py>=10'd427 && py<10'd435 && px>=10'd138 &&
           px<10'd138+({7'd0,wave}<<6))
            pixel_color=hud_color;
    end
    assign m_axis_tdata=pixel_color;
    wire _unused=&s_axis_tdata;
endmodule
