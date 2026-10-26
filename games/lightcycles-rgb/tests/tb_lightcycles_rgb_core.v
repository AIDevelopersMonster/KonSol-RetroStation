// RS-005: deterministic self-checking 2-trail gameplay regression.
// Reports only RTL SIM, never Gowin FIT/STA or hardware board acceptance.
`timescale 1ns/1ps
module tb_lightcycles_rgb_core;
  reg clk=0;
  always #5 clk=~clk;
  reg reset_n=0,rx_valid=0;
  reg [7:0] rx_byte=0;
  reg user=0, sink_ready=1,src_valid=1;
  wire [1:0] palette;
  wire ai_on,source_ready,output_valid;
  wire [23:0] rgb;
  wire [0:0] output_user;
  integer r,checks=0;

  lightcycles_rgb_core #(.STEP_FRAMES(2)) dut(
    .clk(clk),.reset_n(reset_n),
    .rx_byte(rx_byte),.rx_valid(rx_valid),.palette(palette),.ai_on(ai_on),
    .s_axis_tvalid(src_valid),.s_axis_tready(source_ready),
    .s_axis_tdata(24'd0),.s_axis_tuser(user),
    .m_axis_tvalid(output_valid),.m_axis_tready(sink_ready),
    .m_axis_tdata(rgb),.m_axis_tuser(output_user)
  );
  task frame;
    begin
      @(negedge clk); user=1;
      @(negedge clk); user=0;
      @(negedge clk);
    end
  endtask
  task send;
    input [7:0] ch;
    begin
      @(negedge clk);rx_byte=ch;rx_valid=1;
      @(negedge clk);rx_valid=0;
    end
  endtask
  task state_is;
    input [1:0] expected;
    begin
      if(dut.state!==expected)
        $fatal(1,"state=%d expected=%d",dut.state,expected);
      checks=checks+1;
    end
  endtask
  task step;
    begin frame();frame();end
  endtask

  initial begin
    repeat(6) @(negedge clk);
    reset_n=1;
    repeat(2) @(negedge clk);
    state_is(0);
    if(ai_on!==1 || palette!==0) $fatal(1,"default AI or palette");
    checks=checks+2;
    for(r=0;r<24;r=r+1)
      if(dut.trail_a[r]!==0 || dut.trail_b[r]!==0)
        $fatal(1,"reset row %d not zero",r);
    checks=checks+24;

    // Frame beat must not advance when the HDMI downstream is stalled.
    send("p");
    sink_ready=0;
    frame();
    state_is(0);
    if(source_ready!==0) $fatal(1,"backpressure ignored");
    checks=checks+1;
    sink_ready=1;
    frame();
    state_is(1);
    if(dut.ax!==7 || dut.ay!==10 || dut.bx!==24 || dut.by!==13)
      $fatal(1,"initial positions");
    if(!dut.trail_a[10][7] || !dut.trail_b[13][24])
      $fatal(1,"head cells not initialized");
    checks=checks+2;

    send("3");
    if(palette!==2) $fatal(1,"palette byte missing");
    checks=checks+1;
    // A begins going EAST; WEST would reverse it and must be ignored.
    send("a");
    step();
    if(dut.ax!==8 || dut.ay!==10 || dut.adir!==1)
      $fatal(1,"reverse turn allowed");
    if(!dut.trail_a[10][8]) $fatal(1,"trail update absent");
    checks=checks+2;

    // A turns NORTH. The requested direction is held across frame boundary.
    send("w");
    step();
    if(dut.adir!==0 || dut.ax!==8 || dut.ay!==9)
      $fatal(1,"direction N or next head wrong");
    checks=checks+1;
    // Collision with existing trail: B wins, score increments once.
    @(negedge clk); dut.trail_a[8][8]=1'b1;
    step();
    $display("RS005_TRACE_A_TRAIL state=%d ax=%d ay=%d dir=%d count=%d",dut.state,dut.ax,dut.ay,dut.adir,dut.frame_count);
    state_is(2);
    if(dut.winner!==2 || dut.wins_b!==1 || dut.wins_a!==0)
      $fatal(1,"A trail collision / score fail");
    checks=checks+1;

    // Next round preserves match score but clears old trails.
    send("p");frame();state_is(1);
    if(dut.wins_b!==1 || dut.trail_a[8][8]!==0)
      $fatal(1,"round restart did not clear trail or preserve score");
    checks=checks+1;

    // Both choose same target cell, yielding a draw.
    send("t");
    if(ai_on!==0) $fatal(1,"AI toggle");
    checks=checks+1;
    @(negedge clk);
    dut.ax=10;dut.ay=10;dut.adir=1;
    dut.bx=12;dut.by=10;dut.bdir=3;
    dut.frame_count=0;
    step();
    $display("RS005_TRACE_HEAD_ON state=%d ax=%d ay=%d bx=%d by=%d count=%d",dut.state,dut.ax,dut.ay,dut.bx,dut.by,dut.frame_count);
    state_is(2);
    if(dut.winner!==0 || dut.wins_b!==1)
      $fatal(1,"head-on draw or score incorrect");
    checks=checks+1;

    // Two-human mode: I is P2 north, independent of P1.
    send("p");frame();state_is(1);
    send("i");step();
    if(dut.by!==12 || dut.bdir!==0 || dut.ay!==10)
      $fatal(1,"P2 manual north / P1 movement error");
    checks=checks+1;

    // The reset byte returns to READY and zeroes both scores and trails.
    send("r");frame();state_is(0);
    if(dut.wins_b!==0 || dut.wins_a!==0)
      $fatal(1,"match reset score");
    for(r=0;r<24;r=r+1)
      if(dut.trail_a[r]!==0 || dut.trail_b[r]!==0)
        $fatal(1,"match reset trail %d",r);
    checks=checks+25;

    // Starting at the boundary and moving EAST must lose, not wrap to x=0.
    send("p");frame();state_is(1);
    @(negedge clk);
    dut.ax=31;dut.ay=6;dut.adir=1;
    dut.bx=24;dut.by=13;dut.bdir=3;
    dut.frame_count=0;
    step();
    $display("RS005_TRACE_WALL state=%d ax=%d ay=%d count=%d",dut.state,dut.ax,dut.ay,dut.frame_count);
    state_is(2);
    if(dut.winner!==2 || dut.wins_b!==1)
      $fatal(1,"boundary or win accounting");
    checks=checks+1;

    // In AI mode, avoid a direct wall if either side is open.
    send("t");
    if(ai_on!==1) $fatal(1,"AI re-enable");
    checks=checks+1;
    send("p");frame();state_is(1);
    @(negedge clk);
    dut.bx=0;dut.by=13;dut.bdir=3;
    dut.frame_count=0;
    step();
    if(dut.state!==1 || dut.by!==14 || dut.bdir!==2)
      $fatal(1,"AI did not turn SOUTH when WEST blocked: bdir=%d,by=%d",dut.bdir,dut.by);
    checks=checks+1;

    // RGB stream preserves all handshake/first-pixel marker semantics.
    user=1;
    #1;
    if(output_valid!==1 || output_user!==1 || source_ready!==1)
      $fatal(1,"SVO stream passthrough");
    checks=checks+1;
    user=0;
    $display("RS005_LIGHTCYCLES_TB_PASS checks=%0d",checks);
    $finish;
  end
  initial begin
    #2500000;
    $fatal(1,"RS005_TEST_TIMEOUT");
  end
endmodule
