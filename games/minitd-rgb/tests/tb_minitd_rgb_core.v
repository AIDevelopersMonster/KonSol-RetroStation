// RS-008 deterministic Icarus self-check. No hardware interaction.
`timescale 1ns/1ps
module tb_minitd_rgb_core;
    reg clk=0;always #5 clk=~clk;
    reg reset_n=0,rx_valid=0,source_valid=1,ready=1,user=0;
    reg [7:0] rx_byte=0;
    wire [1:0] palette;
    wire playing,src_ready,out_valid;
    wire [23:0] pixel;
    wire [0:0] out_user;
    integer checks=0,j;
    minitd_rgb_core #(.STEP_FRAMES(1)) dut (
        .clk(clk),.reset_n(reset_n),.rx_byte(rx_byte),.rx_valid(rx_valid),
        .palette(palette),.playing(playing),
        .s_axis_tvalid(source_valid),.s_axis_tready(src_ready),
        .s_axis_tdata(24'h0),.s_axis_tuser(user),
        .m_axis_tvalid(out_valid),.m_axis_tready(ready),
        .m_axis_tdata(pixel),.m_axis_tuser(out_user)
    );
    task check;
        input value;
        input [8*95-1:0] what;
        begin
            if(value!==1'b1)$fatal(1,"RS008_FAIL: %0s",what);
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
        end
    endtask
    task tick;
        begin frame();repeat(50) @(negedge clk);end
    endtask
    initial begin
        repeat(5) @(negedge clk);reset_n=1;
        check(!playing && dut.wave==0 && dut.credits==12 && dut.base_hp==12,"power-on READY/credits/hp");
        for(j=0;j<8;j=j+1) begin
            check(!dut.enemy_active[j] && dut.enemy_pos[j]==0,"inactive reset enemy");
        end
        check(dut.route_x(0)==1 && dut.route_y(0)==3,"route entry");
        check(dut.route_x(20)==21 && dut.route_y(20)==3,"route east turn");
        check(dut.route_x(24)==21 && dut.route_y(24)==7,"route west turn");
        check(dut.route_x(43)==2 && dut.route_y(43)==7,"route south turn");
        check(dut.route_x(48)==2 && dut.route_y(48)==12,"route last turn");
        check(dut.route_x(68)==22 && dut.route_y(68)==12,"route exit");
        check(dut.is_road(10,3) && dut.is_road(10,7) && !dut.is_road(10,4),"path only in allowed rows");
        for(j=0;j<4;j=j+1)begin
            check(!dut.is_road(dut.pad_x(j),dut.pad_y(j)),"tower pads not on route");
        end
        send("b");check(dut.tower_built==1 && dut.credits==9,"build first light tower cost 3");
        send("b");check(dut.tower_built==1 && dut.credits==9,"cannot double-build");
        send("2");send("t");send("b");
        check(dut.tower_built==3 && dut.tower_heavy[1] && dut.credits==4,"heavy turret cost 5");
        send("3");send("b");
        check(!dut.tower_built[2] && dut.credits==4,"insufficient funds heavy");
        send("t");send("b");
        check(dut.tower_built[2] && dut.credits==1,"change type and buy cheap tower");
        send("c");check(palette==1,"palette cycles");
        ready=0;frame();check(!src_ready && !playing,"SVO stall no frame progress");
        ready=1;
        send("p");
        check(playing && dut.wave==1 && dut.wave_goal==4,"start wave one of five");
        tick();
        check(dut.spawned==1 && dut.enemy_active[0] && dut.enemy_hp[0]==2,
              "first enemy spawned with wave-1 health");
        tick();tick();tick();
        check(dut.spawned>=2,"more enemies spawn over time");

        // Deterministic test of target acquisition, serialized single
        // enemy per pixel clock; this does not depend on slow HDMI frames.
        @(negedge clk);
        dut.phase=1; dut.tower_idx=0;dut.scan_idx=0;
        dut.best_valid=0;dut.best_progress=0;
        dut.tower_cool=0;
        dut.enemy_active=8'b00000101;
        dut.enemy_pos[0]=5;dut.enemy_hp[0]=2;
        dut.enemy_pos[2]=7;dut.enemy_hp[2]=2;
        // Pad0 (6,1), route y=3: pos5 (x6) and pos7 (x8) in range.
        repeat(9) @(negedge clk);
        check(dut.phase==2 && dut.best_valid && dut.best_idx==2,"serialized scan selects furthest in-range enemy");
        @(negedge clk);
        check(dut.enemy_hp[2]==1 && dut.enemy_hp[0]==2,"light tower hits selected target");
        // Overwrite phase to make next deterministic targeting frame.
        @(negedge clk);
        dut.phase=1;dut.tower_idx=0;dut.scan_idx=0;
        dut.best_valid=0;dut.best_progress=0;
        repeat(9) @(negedge clk);
        @(negedge clk);
        check(!dut.enemy_active[2] && dut.credits==2 && dut.kills==1,
              "kill yields one credit and increases score");

        // Avoid recursing through more waves in a slow 60-Hz simulation:
        // the wave controller itself is tested at its state transition.
        @(negedge clk);
        dut.state=1;dut.phase=5;dut.wave=1;dut.spawned=4;
        dut.wave_goal=4;dut.enemy_active=0;
        @(negedge clk);
        check(dut.state==0 && dut.phase==0,"wave finish enters between-wave READY");
        send("p");check(dut.state==1 && dut.wave==2 && dut.wave_goal==5,
                         "P starts wave two with five enemies");
        @(negedge clk);
        dut.phase=5;dut.wave=5;dut.spawned=8;dut.wave_goal=8;
        dut.enemy_active=0;dut.base_hp=1;
        @(negedge clk);
        check(dut.state==2,"wave five ends in victory");
        send("r");
        check(!playing && dut.state==0 && dut.tower_built==0 &&
              dut.credits==12 && dut.base_hp==12 && dut.wave==0,"full reset restores state");

        // Every leak costs one base HP; after final leak game terminates.
        @(negedge clk);
        dut.state=1;dut.phase=3;dut.enemy_idx=7;
        dut.enemy_active=8'b10000000;dut.enemy_pos[7]=68;dut.base_hp=1;
        @(negedge clk);
        check(dut.base_hp==0 && !dut.enemy_active[7],"leak depletes one base HP");
        @(negedge clk); // SPAWN
        dut.spawned=4;dut.wave_goal=4;
        @(negedge clk); // FINISH
        check(dut.state==3 && !playing,"zero base HP is defeat");

        user=1;#1;
        check(out_valid && out_user && src_ready,"SVO first-pixel passthrough");
        ready=0;#1;check(!src_ready,"SVO backpressure");
        $display("RS008_MINITD_TB_PASS checks=%0d",checks);
        $finish;
    end
    initial begin #2000000;$fatal(1,"RS008_TIMEOUT");end
endmodule
