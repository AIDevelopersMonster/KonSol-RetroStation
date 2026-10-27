// RS-007 MAZE CHASE: self-checking game logic; no FPGA hardware.
`timescale 1ns/1ps
module tb_mazechase_rgb_core;
    reg clk=0;
    always #5 clk=~clk;
    reg reset_n=0,rx_valid=0,src_valid=1,sink_ready=1,user=0;
    reg [7:0] rx_byte=0;
    wire [1:0] palette;
    wire playing,source_ready,out_valid;
    wire [23:0] rgb;
    wire [0:0] out_user;
    integer checks=0,y,x,cells;

    mazechase_rgb_core #(.STEP_FRAMES(2),.HIT_GRACE_FRAMES(8)) dut (
        .clk(clk),.reset_n(reset_n),.rx_byte(rx_byte),.rx_valid(rx_valid),
        .palette(palette),.playing(playing),
        .s_axis_tvalid(src_valid),.s_axis_tready(source_ready),
        .s_axis_tdata(24'h0),.s_axis_tuser(user),
        .m_axis_tvalid(out_valid),.m_axis_tready(sink_ready),
        .m_axis_tdata(rgb),.m_axis_tuser(out_user)
    );
    task check;
        input condition;
        input [8*90-1:0] description;
        begin
            if(condition!==1'b1)
                $fatal(1,"RS007_FAIL: %0s",description);
            checks=checks+1;
        end
    endtask
    task send;
        input [7:0] ch;
        begin
            @(negedge clk);rx_byte=ch;rx_valid=1;
            @(negedge clk);rx_valid=0;
        end
    endtask
    task frame;
        begin
            @(negedge clk);user=1;
            @(negedge clk);user=0;
            @(negedge clk);
        end
    endtask
    task step;
        begin
            frame();frame();
            // Frame-start proposes movement; two pixel clocks resolve and
            // atomically commit score, lives and dots after the last frame.
            repeat(3) @(negedge clk);
        end
    endtask

    initial begin
        repeat(6) @(negedge clk);reset_n=1;
        repeat(2) @(negedge clk);
        check(dut.state==0 && !playing,"reset -> READY");
        check(dut.lives==3 && dut.score==0 && dut.remaining==455,
              "three lives, all 455 dots remaining");
        check(palette==0,"default palette");

        cells=0;
        for(y=0;y<24;y=y+1) begin
            for(x=0;x<28;x=x+1) begin
                if(dut.dots[y][x]) cells=cells+1;
                if(dut.dots[y][x] === dut.wall(x,y))
                    $fatal(1,"wall/dot mismatch x=%0d y=%0d",x,y);
            end
            checks=checks+1;
        end
        check(cells==455,"exact 455 accessible dots seeded");
        check(dut.wall(0,2) && dut.wall(27,2) && dut.wall(5,6),
              "fixed boundary and internal wall");
        check(!dut.wall(3,6) && !dut.wall(6,4) && !dut.wall(10,12),
              "known maze doors open");
        check(!dut.wall(2,2) && !dut.wall(25,21),"spawns valid");

        // A stalled stream cannot begin the round or consume frames.
        send("p");sink_ready=0;frame();
        check(!playing && !source_ready,"HDMI backpressure");
        sink_ready=1;frame();
        check(playing && dut.state==1,"P starts the round");
        send("4");check(palette==3,"fourth palette");
        send("1");check(palette==0,"first palette");
        frame();
        @(negedge clk);user=1;
        @(negedge clk);user=0;
        check(dut.proposed_valid && dut.proposed_px==3 &&
              dut.proposed_py==2,"proposal captures target cell");
        check(dut.dots[2][3] && dut.score==0,
              "score and dot unchanged before resolution");
        @(negedge clk);
        check(dut.resolved_valid && dut.resolved_collect &&
              !dut.resolved_hit,"resolved pellet and collision flags");
        check(dut.dots[2][3] && dut.score==0,
              "resolution does not modify game state");
        @(negedge clk);
        check(!dut.dots[2][3] && dut.score==1,
              "score and dot clear committed together");
        check(dut.dots[2][4] && dut.dots[3][3],
              "other dots remain untouched");
        check(dut.player_x==3 && dut.player_y==2,"player moves one tile east");
        check(dut.score==1 && dut.remaining==454 && !dut.dots[2][3],
              "pellet eaten once and score incremented");
        check(dut.patrol_x==24 && dut.patrol_y==2,"patrol heading west");
        check(dut.chaser_x==24 && dut.chaser_y==21,"chaser greedily heading west");
        step();
        check(dut.player_x==4 && dut.score==2,"second pellet earned");
        @(negedge clk);
        dut.player_x=5;dut.player_y=2;dut.wanted_dir=1;
        step();
        check(dut.player_x==5 && dut.player_y==2 && dut.score==2,
              "cannot pass a vertical wall");
        send("s");step();
        check(dut.player_x==5 && dut.player_y==3,"south turn through corridor");
        check(dut.score==3,"new corridor pellet counted");

        // Greedy chaser changes axis when vertical distance dominates.
        @(negedge clk);
        dut.chaser_x=3;dut.chaser_y=20;
        dut.player_x=3;dut.player_y=3;
        dut.wanted_dir=3;
        step();
        check(dut.chaser_x==3 && dut.chaser_y==19,
              "chaser chooses vertical axis over horizontal");
        check(!dut.wall(dut.patrol_x,dut.patrol_y) &&
              !dut.wall(dut.chaser_x,dut.chaser_y),
              "both enemies stay within walkable cells");

        // Both move into each other's previous tile: life loss on swap.
        @(negedge clk);
        dut.player_x=2;dut.player_y=2;dut.wanted_dir=1;
        dut.patrol_x=3;dut.patrol_y=2;dut.patrol_dir=3;
        dut.chaser_x=25;dut.chaser_y=21;dut.grace=0;
        step();
        check(dut.state==1 && dut.lives==2,"swap collision costs one life");
        check(dut.player_x==2 && dut.player_y==2,"respawn at original tile");
        check(dut.grace>0,"temporary post-hit invulnerability");
        // A collision during grace must not drain more lives.
        @(negedge clk);
        dut.patrol_x=3;dut.patrol_y=2;dut.patrol_dir=3;
        step();
        check(dut.lives==2 && dut.state==1,"grace prevents double life loss");

        // Reset clears all prior dot activity and restores defaults.
        send("r");frame();
        check(dut.state==0 && dut.lives==3,"R returns to ready/three lives");
        check(dut.score==0 && dut.remaining==455 && dut.dots[2][3],
              "R restores dot field");
        send("p");frame();
        check(playing,"new game after reset");

        // Last life: game over (not a fourth free respawn).
        @(negedge clk);
        dut.lives=1;dut.grace=0;
        dut.player_x=2;dut.player_y=2;dut.wanted_dir=1;
        dut.patrol_x=3;dut.patrol_y=2;dut.patrol_dir=3;
        step();
        check(dut.state==3 && dut.lives==0,"third collision -> LOST");
        send("p");frame();
        check(dut.state==1 && dut.lives==3 && dut.remaining==455,
              "restart after loss resets match");

        // Complete last dot: win without a CPU or external RAM.
        @(negedge clk);
        dut.player_x=2;dut.player_y=2;dut.wanted_dir=1;
        dut.patrol_x=25;dut.patrol_y=2;dut.patrol_dir=3;
        dut.chaser_x=25;dut.chaser_y=21;dut.grace=0;
        dut.remaining=1;dut.dots[2][3]=1;
        step();
        check(dut.state==2 && dut.remaining==0,"collect final dot -> WON");
        send("p");frame();
        check(dut.state==1 && dut.remaining==455 && dut.score==0,
              "restart after win resets the board");

        // Independently test SVO stream first-pixel and stalled handshake.
        user=1;#1;
        check(out_valid && out_user && source_ready,"SVO stream passthrough");
        sink_ready=0;#1;
        check(!source_ready,"SVO ready follows sink ready");
        $display("RS007_MAZECHASE_TB_PASS checks=%0d",checks);
        $finish;
    end
    initial begin #3000000;$fatal(1,"RS007_TIMEOUT");end
endmodule
