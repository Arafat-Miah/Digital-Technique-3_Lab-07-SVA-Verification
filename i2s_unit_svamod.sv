////////////////////////////////////////////////////////////////////////////////////////////
//
// SystemVerilog assertion module file for i2s_unit
//
//    Contents:
//    1. X-Checks
//    2. Assumptions for formal verification
//    3. Blackbox assertions
//    4. Whitebox assertions
//    5. Covergroups
//
////////////////////////////////////////////////////////////////////////////////////////////

`include "audioport.svh"

import audioport_pkg::*;
import audioport_util_pkg::*;

module i2s_unit_svamod
  (
   input logic        clk,
   input logic        rst_n,
   input logic        play_in,
   input logic [23:0] audio0_in,
   input logic [23:0] audio1_in,
   input logic        tick_in,
   input logic        req_out,
   input logic        sck_out,
   input logic        ws_out,
   input logic        sdo_out
`ifndef SYSTEMC_DUT
   ,
   input logic        play_r,
   input logic        stop_req_r,
   input logic [8:0]  cnt_r,
   input logic [47:0] in_reg_r,
   input logic [47:0] shreg_r,

   input logic [2:0]  phase_c,
   input logic [5:0]  bit_idx_c,
   input logic        sck_c,
   input logic        ws_c,
   input logic        sck_fall_c,
   input logic        last_bit_c,
   input logic        load_en_c,
   input logic        shift_en_c
`endif
   );

   /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   // 1. X-checks
   /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

   `xcheck(play_in);
   `xcheck(audio0_in);
   `xcheck(audio1_in);
   `xcheck(tick_in);
   `xcheck(req_out);
   `xcheck(sck_out);
   `xcheck(ws_out);
   `xcheck(sdo_out);

`ifndef SYSTEMC_DUT
   
   `xcheck(play_r);
   `xcheck(stop_req_r);
   `xcheck(cnt_r);
   `xcheck(in_reg_r);
   `xcheck(shreg_r);

   `xcheck(phase_c);
   `xcheck(bit_idx_c);
   `xcheck(sck_c);
   `xcheck(ws_c);
   `xcheck(sck_fall_c);
   `xcheck(last_bit_c);
   `xcheck(load_en_c);
   `xcheck(shift_en_c);
`endif

   /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   // 2. Blackbox (functional) assumptions and assertions
   /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`ifdef design_top_is_i2s_unit // Assumptions enabled only in i2s_unit verification

   // play_in_length : f_play_in_stable
   property f_play_in_stable;
   @(posedge clk ) disable iff (rst_n == '0)
     !$stable(play_in) |=> $stable(play_in) [* 384];
   endproperty
   mf_play_in_stable: assume property(f_play_in_stable) else assert_error("mf_play_in_stable");
   cf_play_in_stable: cover property(f_play_in_stable);

   // tick_in_length : f_tick_in_pulse
   property f_tick_in_pulse;
      @(posedge clk ) disable iff (rst_n == '0)
        $rose(tick_in) |=> $fell(tick_in);
   endproperty
   mf_tick_in_pulse: assume property(f_tick_in_pulse) else assert_error("mf_tick_in_pulse");
   cf_tick_in_pulse: cover property(f_tick_in_pulse);

   // tick_in_length : f_tick_in_play_only
   property f_tick_in_play_only;
      @(posedge clk ) disable iff (rst_n == '0)
        !play_in |-> !tick_in;
   endproperty
   mf_tick_in_play_only: assume property(f_tick_in_play_only) else assert_error("mf_tick_in_play_only");
   cf_tick_in_play_only: cover property(f_tick_in_play_only);

`endif //  `ifdef design_top_is_i2s_unit

   // data_request : f_req_out_pulse
   property f_req_out_pulse;
      @(posedge clk ) disable iff (rst_n == '0)
        $rose(req_out) |=> $fell(req_out);
   endproperty
   af_req_out_pulse: assert property(f_req_out_pulse) else assert_error("af_req_out_pulse");
   cf_req_out_pulse: cover property(f_req_out_pulse);

   // mode_control : f_sck_start
   property f_sck_start;
      @(posedge clk ) disable iff (rst_n == '0)
        $rose(play_in)  |=> $rose(sck_out);
   endproperty
   af_sck_start: assert property(f_sck_start) else assert_error("af_sck_start");
   cf_sck_start: cover property(f_sck_start);

   // data_request : f_req_sck_align
   property f_req_sck_align;
      @(posedge clk ) disable iff (rst_n == '0)
        $fell(req_out) |-> $fell(sck_out);
   endproperty
   af_req_sck_align: assert property(f_req_sck_align) else assert_error("af_req_sck_align");
   cf_req_sck_align: cover property(f_req_sck_align);

   // data_request : f_req_out_seen
   property f_req_out_seen;
      @(posedge clk ) disable iff (rst_n == '0)
        ($rose(play_in) || (play_in && $fell(ws_out))) ##1 (play_in throughout ($fell(sck_out) [-> 1])) |-> $past(req_out);
   endproperty
   af_req_out_seen: assert property(f_req_out_seen) else assert_error("af_req_out_seen");
   cf_req_out_seen: cover property(f_req_out_seen);

   // sck_wave : f_sck_wave
   property f_sck_wave;
      @(posedge clk ) disable iff (rst_n == '0)
        $rose(sck_out) |=> (sck_out [*3] ##1 !sck_out[*4]) or
                           (sck_out [*1] ##1 !sck_out[*2]) or
                           $fell(sck_out);
   endproperty
   af_sck_wave: assert property(f_sck_wave) else assert_error("af_sck_wave");
   cf_sck_wave: cover property(f_sck_wave);

   // ws_wave : f_ws_change
   property f_ws_change;
      @(posedge clk ) disable iff (rst_n == '0)
        !$stable(ws_out) |-> $fell(sck_out);
   endproperty
   af_ws_change: assert property(f_ws_change) else assert_error("af_ws_change");
   cf_ws_change: cover property(f_ws_change);

   // ws_wave : f_ws_wave
   property f_ws_wave;
      @(posedge clk ) disable iff (rst_n == '0)
        !ws_out throughout $rose(sck_out) [-> 24] |=> $rose(ws_out) [-> 1] ##1 (ws_out throughout $rose(sck_out) [-> 24]) ;
   endproperty
   af_ws_wave: assert property(f_ws_wave) else assert_error("af_ws_wave");
   cf_ws_wave: cover property(f_ws_wave);

   // serial_data : f_sdo_change
   property f_sdo_change;
      @(posedge clk ) disable iff (rst_n == '0)
        !$stable(sdo_out) && play_in |-> $fell(sck_out);
   endproperty
   af_sdo_change: assert property(f_sdo_change) else assert_error("af_sdo_change");
   cf_sdo_change: cover property(f_sdo_change);

   /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   // 3. Whitebox (RTL) assertions
   /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`ifndef SYSTEMC_DUT


   property r_in_reg_standby_zero;
     @(posedge clk) disable iff (rst_n == '0)
       (!play_r) |-> (in_reg_r == 48'h0);
   endproperty
   af_in_reg_standby_zero: assert property(r_in_reg_standby_zero) else assert_error("af_in_reg_standby_zero");
   cf_in_reg_standby_zero: cover  property(r_in_reg_standby_zero);

   property r_in_reg_load;
     @(posedge clk) disable iff (rst_n == '0)
       (play_r && tick_in) |=> (in_reg_r == {$past(audio0_in), $past(audio1_in)});
   endproperty
   af_in_reg_load: assert property(r_in_reg_load) else assert_error("af_in_reg_load");
   cf_in_reg_load: cover  property(r_in_reg_load);

   property r_in_reg_hold;
     @(posedge clk) disable iff (rst_n == '0)
       (play_r && !tick_in) |=> $stable(in_reg_r);
   endproperty
   af_in_reg_hold: assert property(r_in_reg_hold) else assert_error("af_in_reg_hold");
   cf_in_reg_hold: cover  property(r_in_reg_hold);

   

   property r_sdo_out_conn;
     @(posedge clk) disable iff (rst_n == '0)
       (sdo_out == shreg_r[47]);
   endproperty
   af_sdo_out_conn: assert property(r_sdo_out_conn) else assert_error("af_sdo_out_conn");
   cf_sdo_out_conn: cover  property(r_sdo_out_conn);

`endif // !SYSTEMC_DUT

   /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   // 4. Covergroups
   /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule


