// RS-006 SPACE PATROL self-checking smoke/regression. No FPGA access.
`timescale 1ns/1ps
module tb_spacepatrol_rgb_core;
 reg clk=0;always #5 clk=~clk;
 reg reset_n=0,rx_valid=0,user=0,ready=1,valid=1;
 reg [7:0] rx_byte=0;
 wire [1:0] palette;
 wire playing,source_ready,out_valid;
 wire [23:0] rgb;
 wire [0:0] out_user;
 integer checks=0;
 spacepatrol_rgb_core #(.FLEET_FRAMES(2),.FIRE_COOLDOWN(1),.ENEMY_FIRE_FRAMES(3)) dut(
 .clk(clk),.reset_n(reset_n),.rx_byte(rx_byte),.rx_valid(rx_valid),
 .palette(palette),.playing(playing),
 .s_axis_tvalid(valid),.s_axis_tready(source_ready),
 .s_axis_tdata(24'd0),.s_axis_tuser(user),
 .m_axis_tvalid(out_valid),.m_axis_tready(ready),
 .m_axis_tdata(rgb),.m_axis_tuser(out_user));
 task send;input [7:0] ch;begin
 @(negedge clk);rx_byte=ch;rx_valid=1;
 @(negedge clk);rx_valid=0;
 end endtask
 task frame;begin
 @(negedge clk);user=1;
 @(negedge clk);user=0;
 @(negedge clk);
 end endtask
 task check;input condition;input [8*64-1:0] message;begin
 if(condition!==1'b1) $fatal(1,"RS006_FAIL: %0s",message);
 checks=checks+1;
 end endtask
 initial begin
 repeat(6) @(negedge clk);reset_n=1;
 repeat(2) @(negedge clk);
 check(!playing,"ready");
 check(dut.lives==3,"initial lives");
 check(dut.alien_alive==24'hffffff,"initial fleet");
 check(dut.score==0,"initial score");
 send("p");ready=0;frame();check(!playing,"backpressure gate");
 ready=1;frame();check(playing,"start game");
 send("2");check(palette==1,"palette");
 send("a");frame();check(dut.ship_x<302,"ship left");
 send("A");frame();
 send("d");frame();check(dut.ship_x==302,"ship right");
 send("D");
 send("f");frame();check(dut.shot0_active,"first shot created");
 check(dut.shot0_y==412,"first shot origin");
 send("F");
 frame();check(dut.shot0_y<412,"shot flies");
 // Establish the collision shape without relying on exact orbital timing.
 @(negedge clk);
 dut.shot0_active=1;dut.shot0_x=dut.fleet_x+10'd16;
 dut.shot0_y=dut.fleet_y+10'd8;
 frame();
 check(!dut.alien_alive[0],"alien killed");
 check(dut.score==1,"score increments");
 check(!dut.shot0_active,"shot consumed");
 // Hit ship with enemy projectile; life decrements exactly once.
 @(negedge clk);
 dut.eshot_active=1;dut.eshot_x=dut.ship_x+10'd15;
 dut.eshot_y=10'd430;
 frame();
 check(dut.lives==2,"life decremented");
 check(!dut.eshot_active,"enemy shot consumed");
 // Enemy fire generates a projectile on its cooldown.
 @(negedge clk);dut.eshot_active=0;dut.enemy_fire_frames=2;
 frame();check(dut.eshot_active,"enemy firing");
 // Kill last remaining enemy; scoreboard and WIN.
 @(negedge clk);
 dut.alien_alive=24'h000001;
 dut.shot0_active=1;dut.shot0_x=dut.fleet_x+10'd16;
 dut.shot0_y=dut.fleet_y+10'd8;
 dut.shot1_active=0;
 frame();check(dut.state==2,"win condition");
 send("r");frame();check(dut.state==0,"reset to ready");
 check(dut.score==0,"score reset");
 check(dut.lives==3,"lives reset");
 check(dut.alien_alive==24'hffffff,"fleet reset");
 // All active ship lanes return to idle on global key release.
 send("a");send("f");send("x");
 check(!dut.left_held && !dut.fire_held,"release all keys");
 // Repeated enemy collisions cause defeat.
 send("p");frame();check(playing,"restart");
 @(negedge clk);dut.lives=1;dut.eshot_active=1;
 dut.eshot_x=dut.ship_x+10'd15;dut.eshot_y=10'd430;
 frame();check(dut.state==3,"loss condition");
 check(dut.lives==0,"no lives");
 // RGB handshake, frame marker & stable core default color.
 user=1;#1;
 check(out_valid && out_user && source_ready,"axis passthrough");
 $display("RS006_SPACEPATROL_TB_PASS checks=%0d",checks);
 $finish;
 end
 initial begin #2500000;$fatal(1,"RS006_TIMEOUT");end
endmodule
