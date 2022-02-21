-- Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
-- Date        : Sat Oct  2 15:29:05 2021
-- Host        : DESKTOP-MB5IJCE running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub -rename_top div_gen_1 -prefix
--               div_gen_1_ div_gen_1_stub.vhdl
-- Design      : div_gen_1
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7z020clg400-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity div_gen_1 is
  Port ( 
    aclk : in STD_LOGIC;
    aresetn : in STD_LOGIC;
    s_axis_divisor_tvalid : in STD_LOGIC;
    s_axis_divisor_tdata : in STD_LOGIC_VECTOR ( 7 downto 0 );
    s_axis_dividend_tvalid : in STD_LOGIC;
    s_axis_dividend_tdata : in STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axis_dout_tvalid : out STD_LOGIC;
    m_axis_dout_tuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axis_dout_tdata : out STD_LOGIC_VECTOR ( 15 downto 0 )
  );

end div_gen_1;

architecture stub of div_gen_1 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "aclk,aresetn,s_axis_divisor_tvalid,s_axis_divisor_tdata[7:0],s_axis_dividend_tvalid,s_axis_dividend_tdata[7:0],m_axis_dout_tvalid,m_axis_dout_tuser[0:0],m_axis_dout_tdata[15:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "div_gen_v5_1_17,Vivado 2020.2";
begin
end;
