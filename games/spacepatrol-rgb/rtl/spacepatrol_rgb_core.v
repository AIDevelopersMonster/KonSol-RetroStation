// KonSol RetroStation RS-006 SPACE PATROL RGB v0.1.0
// Native two-dimensional FPGA arcade: 24 aliens, two player shots,
// one enemy shot, three lives, victory/defeat, palettes and UART controls.
// No CPU, DMA framebuffer, external RAM, SD, commercial ROM or sprites.
// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
module spacepatrol_rgb_core #(
    parameter integer FLEET_FRAMES = 10,
    parameter integer FIRE_COOLDOWN = 7,
    parameter integer ENEMY_FIRE_FRAMES = 42
) (
    input wire clk, input wire reset_n,
    input wire [7:0] rx_byte, input wire rx_valid,
    output reg [1:0] palette,
    output wire playing,
    input wire s_axis_tvalid, output wire s_axis_tready,
    input wire [23:0] s_axis_tdata, input wire [0:0] s_axis_tuser,
    output wire m_axis_tvalid, input wire m_axis_tready,
    output wire [23:0] m_axis_tdata, output wire [0:0] m_axis_tuser
);
    localparam [1:0] READY=2'd0, PLAY=2'd1, WON=2'd2, LOST=2'd3;
    localparam [9:0] SHIP_Y=10'd422;
    reg [1:0] state;
    assign playing = (state==PLAY);
    reg [23:0] alien_alive;
    reg [9:0] fleet_x, fleet_y, ship_x;
    reg fleet_right;
    reg [7:0] fleet_frames, enemy_fire_frames;
    reg [3:0] fire_cooldown;
    reg [7:0] score;
    reg [1:0] lives;
    reg [2:0] enemy_col;
    reg [7:0] blink;
    reg left_held, right_held, fire_held;
    reg start_pending, reset_pending;

    reg shot0_active, shot1_active, eshot_active;
    reg [9:0] shot0_x, shot0_y, shot1_x, shot1_y;
    reg [9:0] eshot_x, eshot_y;

    // All changes, including projectile movement, are gated by accepted
    // first-pixel beats of the 640x480 SVO source. One clock domain only.
    assign s_axis_tready=m_axis_tready;
    assign m_axis_tvalid=s_axis_tvalid;
    assign m_axis_tuser=s_axis_tuser;
    wire accepted=s_axis_tvalid && m_axis_tready;
    wire frame_tick=accepted && s_axis_tuser[0];

    // The console and host controller send key DOWN/UP bytes.
    // a/A=left, d/D=right, f/F=fire, x=release all.
    // p or Space=start, r=reset, digits 1-4=palettes.
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            palette<=0;
            left_held<=0;right_held<=0;fire_held<=0;
            start_pending<=0;reset_pending<=0;
        end else begin
            if(frame_tick) begin
                start_pending<=0;reset_pending<=0;
            end
            if(rx_valid) begin
                case(rx_byte)
                    8'h61: left_held<=1;          // a
                    8'h41: left_held<=0;          // A
                    8'h64: right_held<=1;         // d
                    8'h44: right_held<=0;         // D
                    8'h66: fire_held<=1;          // f
                    8'h46: fire_held<=0;          // F
                    8'h78,8'h58: begin           // x/X release
                        left_held<=0;right_held<=0;fire_held<=0;
                    end
                    8'h70,8'h20: start_pending<=1;
                    8'h72: reset_pending<=1;
                    8'h31: palette<=0;
                    8'h32: palette<=1;
                    8'h33: palette<=2;
                    8'h34: palette<=3;
                    default: ;
                endcase
            end
        end
    end

    // Display pixel coordinates: compatible with SVO first-pixel marker.
    reg [9:0] scan_x,scan_y;
    wire [9:0] px=s_axis_tuser[0]?10'd0:scan_x;
    wire [9:0] py=s_axis_tuser[0]?10'd0:scan_y;
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin scan_x<=0;scan_y<=0;end
        else if(accepted) begin
            if(s_axis_tuser[0]) begin scan_x<=1;scan_y<=0;end
            else if(scan_x==10'd639) begin
                scan_x<=0;
                scan_y <= scan_y==10'd479 ? 10'd0 : scan_y+10'd1;
            end else scan_x<=scan_x+10'd1;
        end
    end

    // 6 columns x 4 rows. Each alien uses its individual alive bit.
    // Constant offsets only; no variable-indexed RAM or divider.
    wire [23:0] hit0,hit1,alien_pixel;
    genvar g;
    generate for(g=0;g<24;g=g+1) begin:g_alien
        localparam integer COL=g%6;
        localparam integer ROW=g/6;
        wire [9:0] ex=fleet_x + (COL*64);
        wire [9:0] ey=fleet_y + (ROW*48);
        assign hit0[g]=alien_alive[g] && shot0_active &&
                       shot0_x>=ex && shot0_x<ex+10'd32 &&
                       shot0_y>=ey && shot0_y<ey+10'd24;
        assign hit1[g]=alien_alive[g] && shot1_active &&
                       shot1_x>=ex && shot1_x<ex+10'd32 &&
                       shot1_y>=ey && shot1_y<ey+10'd24;
        // Procedural, asymmetrical ship-like alien silhouette.
        assign alien_pixel[g]=alien_alive[g] &&
            ((px>=ex+10'd6 && px<ex+10'd26 &&
              py>=ey+10'd2 && py<ey+10'd21) ||
             (px>=ex && px<ex+10'd32 &&
              py>=ey+10'd12 && py<ey+10'd18)) &&
            !((px>=ex+10'd10 && px<ex+10'd14 &&
               py>=ey+10'd8 && py<ey+10'd12) ||
              (px>=ex+10'd18 && px<ex+10'd22 &&
               py>=ey+10'd8 && py<ey+10'd12));
    end endgenerate

    // Separate bullets may hit two *different* aliens in one frame.
    // If both hit the same alien the score increments only once.
    wire [23:0] kill_mask=hit0 | hit1;
    wire [23:0] alive_after_hit=alien_alive & ~kill_mask;
    wire hit0_any=|hit0, hit1_any=|hit1;
    wire [1:0] kill_count={1'b0,hit0_any}+
                          {1'b0,(hit1_any && !(|(hit0 & hit1)))};
    wire eshot_hits_ship=eshot_active &&
         eshot_x>=ship_x && eshot_x<ship_x+10'd36 &&
         eshot_y>=SHIP_Y && eshot_y<SHIP_Y+10'd26;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            state<=READY;alien_alive<=24'hffffff;
            fleet_x<=10'd96;fleet_y<=10'd64;fleet_right<=1;
            ship_x<=10'd302;lives<=2'd3;score<=0;
            fleet_frames<=0;enemy_fire_frames<=0;
            fire_cooldown<=0;enemy_col<=0;blink<=0;
            shot0_active<=0;shot1_active<=0;eshot_active<=0;
            shot0_x<=0;shot0_y<=0;shot1_x<=0;shot1_y<=0;
            eshot_x<=0;eshot_y<=0;
        end else if(frame_tick && reset_pending) begin
            state<=READY;alien_alive<=24'hffffff;
            fleet_x<=10'd96;fleet_y<=10'd64;fleet_right<=1;
            ship_x<=10'd302;lives<=2'd3;score<=0;
            fleet_frames<=0;enemy_fire_frames<=0;
            fire_cooldown<=0;enemy_col<=0;blink<=0;
            shot0_active<=0;shot1_active<=0;eshot_active<=0;
        end else if(frame_tick) begin
            blink<=blink+8'd1;
            if(state!=PLAY) begin
                if(start_pending) begin
                    state<=PLAY;alien_alive<=24'hffffff;
                    fleet_x<=10'd96;fleet_y<=10'd64;fleet_right<=1;
                    ship_x<=10'd302;lives<=2'd3;score<=0;
                    fleet_frames<=0;enemy_fire_frames<=0;
                    fire_cooldown<=0;enemy_col<=0;
                    shot0_active<=0;shot1_active<=0;eshot_active<=0;
                end
            end else begin
                // Player movement is held-key driven and saturating.
                if(left_held && !right_held) begin
                    if(ship_x>10'd28) ship_x<=ship_x-10'd6;
                    else ship_x<=10'd24;
                end else if(right_held && !left_held) begin
                    if(ship_x<10'd574) ship_x<=ship_x+10'd6;
                    else ship_x<=10'd580;
                end

                if(fleet_frames>=FLEET_FRAMES-1) begin
                    fleet_frames<=0;
                    if(fleet_right) begin
                        if(fleet_x>=10'd216) begin
                            fleet_right<=0;fleet_y<=fleet_y+10'd8;
                        end else fleet_x<=fleet_x+10'd8;
                    end else begin
                        if(fleet_x<=10'd40) begin
                            fleet_right<=1;fleet_y<=fleet_y+10'd8;
                        end else fleet_x<=fleet_x-10'd8;
                    end
                end else fleet_frames<=fleet_frames+8'd1;

                // Player projectiles: fixed two-slot pool, no allocation RAM.
                if(shot0_active) begin
                    if(hit0_any || shot0_y<=10'd16) shot0_active<=0;
                    else shot0_y<=shot0_y-10'd12;
                end
                if(shot1_active) begin
                    if(hit1_any || shot1_y<=10'd16) shot1_active<=0;
                    else shot1_y<=shot1_y-10'd12;
                end
                if(fire_cooldown!=0) fire_cooldown<=fire_cooldown-4'd1;
                else if(fire_held) begin
                    if(!shot0_active) begin
                        shot0_active<=1;
                        shot0_x<=ship_x+10'd16;shot0_y<=SHIP_Y-10'd10;
                        fire_cooldown<=FIRE_COOLDOWN;
                    end else if(!shot1_active) begin
                        shot1_active<=1;
                        shot1_x<=ship_x+10'd16;shot1_y<=SHIP_Y-10'd10;
                        fire_cooldown<=FIRE_COOLDOWN;
                    end
                end

                if(|kill_mask) begin
                    alien_alive<=alive_after_hit;
                    score<=score+{6'd0,kill_count};
                    if(alive_after_hit==24'b0) state<=WON;
                end

                // Single enemy projectile, fired periodically from the
                // current bottom-row alien in a cycling column, if alive.
                if(eshot_active) begin
                    if(eshot_hits_ship) begin
                        eshot_active<=0;
                        if(lives!=0) lives<=lives-2'd1;
                        if(lives==1) state<=LOST;
                    end else if(eshot_y>=10'd470) eshot_active<=0;
                    else eshot_y<=eshot_y+10'd8;
                end else if(enemy_fire_frames>=ENEMY_FIRE_FRAMES-1) begin
                    enemy_fire_frames<=0;
                    if(alien_alive[18+enemy_col]) begin
                        eshot_active<=1;
                        eshot_x<=fleet_x+({7'd0,enemy_col}<<6)+10'd16;
                        eshot_y<=fleet_y+10'd168;
                    end
                    if(enemy_col==3'd5) enemy_col<=0;
                    else enemy_col<=enemy_col+3'd1;
                end else enemy_fire_frames<=enemy_fire_frames+8'd1;
                if(fleet_y>=10'd248) state<=LOST;
            end
        end
    end

    // Real-time pixel overlay: background stars + 24 aliens + bullets
    // and ship; no framebuffer, no dynamically indexed tile storage.
    wire alien_draw=|alien_pixel;
    wire ship_draw=(state==PLAY || state==READY) &&
        ((px>=ship_x && px<ship_x+10'd36 &&
          py>=SHIP_Y+10'd12 && py<SHIP_Y+10'd26) ||
         (px>=ship_x+10'd12 && px<ship_x+10'd24 &&
          py>=SHIP_Y && py<SHIP_Y+10'd18));
    wire player_bullet=(shot0_active &&
        px>=shot0_x && px<shot0_x+10'd4 &&
        py>=shot0_y && py<shot0_y+10'd12) ||
        (shot1_active &&
        px>=shot1_x && px<shot1_x+10'd4 &&
        py>=shot1_y && py<shot1_y+10'd12);
    wire enemy_bullet=eshot_active &&
        px>=eshot_x && px<eshot_x+10'd5 &&
        py>=eshot_y && py<eshot_y+10'd12;
    wire star=(px[6:0]==(py[6:0] ^ 7'h35)) &&
        px[4:1]!=0 && py>10'd38 && py<10'd462;
    wire [7:0] score_bar={score,3'b0} >> 3; // 1 score point = 8 px via concatenation below
    wire score_pixel=py>=10'd12 && py<10'd24 &&
        px>=10'd250 && px<(10'd250 + {score,3'b0});
    wire life0=py>=10'd12 && py<10'd26 && px>=10'd50 && px<10'd70;
    wire life1=py>=10'd12 && py<10'd26 && px>=10'd78 && px<10'd98;
    wire life2=py>=10'd12 && py<10'd26 && px>=10'd106 && px<10'd126;
    wire life_pixel=(life0 && lives>=1) ||
                    (life1 && lives>=2) || (life2 && lives>=3);
    wire border=(px<=10'd3)||(px>=10'd636)||
                (py<=10'd3)||(py>=10'd476);
    wire end_banner=(state==WON || state==LOST) &&
        py>=10'd317 && py<10'd339 && px>=10'd150 && px<10'd490 &&
        blink[4];
    wire ready_banner=state==READY &&
        py>=10'd318 && py<10'd333 && px>=10'd180 && px<10'd460 &&
        blink[4];

    // Physical SVO expects packed BGR888 (blue high, red low).
    wire [23:0] bg=palette==0 ? 24'h190E07 :
                   palette==1 ? 24'h101B0D :
                   palette==2 ? 24'h270D16 : 24'h1A1025;
    wire [23:0] alien_color=palette==0 ? 24'h87EA4C :
                            palette==1 ? 24'h40FF92 :
                            palette==2 ? 24'hF8A6FB : 24'h85F8FF;
    wire [23:0] ship_color=palette==0 ? 24'hFFE46A :
                           palette==1 ? 24'hEFBB67 :
                           palette==2 ? 24'h6FEAFF : 24'hEFC2FB;
    assign m_axis_tdata=
        life_pixel ? 24'h40FF65 :
        score_pixel ? 24'h47D5FF :
        player_bullet ? 24'hFFFFFF :
        enemy_bullet ? 24'h5286FF :
        ship_draw ? ship_color :
        alien_draw ? alien_color :
        end_banner ? (state==WON ? 24'h62F788 : 24'h6677FF) :
        ready_banner ? 24'hA3F4FF :
        border ? 24'h54352E :
        star ? 24'h777777 : bg;
    wire _unused=^s_axis_tdata;
endmodule
