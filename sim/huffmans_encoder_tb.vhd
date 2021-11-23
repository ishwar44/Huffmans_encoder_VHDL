-- Testbench created online at:
--   https://www.doulos.com/knowhow/perl/vhdl-testbench-creation-using-perl/
-- Copyright Doulos Ltd

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity huffmans_encoder_tb is
end;

architecture bench of huffmans_encoder_tb is

  component huffmans_encoder
      Port ( clk : in STD_LOGIC;
             rst_n : in STD_LOGIC;
             write_data : in STD_LOGIC;
             start_huff : in STD_LOGIC;
             data_in : in STD_LOGIC_VECTOR (7 downto 0);
             done   : out STD_LOGIC := '1';
             some_out : out STD_LOGIC_VECTOR (7 downto 0));
  end component;

  signal clk: STD_LOGIC;
  signal rst_n: STD_LOGIC;
  signal write_data: STD_LOGIC;
  signal start_huff: STD_LOGIC;
  signal data_in: STD_LOGIC_VECTOR (7 downto 0);
  signal done: STD_LOGIC := '1';
  signal some_out: STD_LOGIC_VECTOR (7 downto 0);

  constant clock_period: time := 10 ns;
  signal stop_the_clock: boolean;

begin

  uut: huffmans_encoder port map ( clk        => clk,
                                   rst_n      => rst_n,
                                   write_data => write_data,
                                   start_huff => start_huff,
                                   data_in    => data_in,
                                   done       => done,
                                   some_out   => some_out );

  stimulus: process
  begin
  
    -- Put initialisation code here
    rst_n <= '0';
    wait for clock_period * 10;
    rst_n <= '1';
    wait for clock_period * 10;
    write_data <= '1';
    data_in <= x"02";
    wait for clock_period * 10;
    data_in <= x"04";
    wait for clock_period * 15;
    data_in <= x"0a";
    wait for clock_period * 2;
    data_in <= x"05";
    wait for clock_period * 12;
    data_in <= x"07";
    wait for clock_period * 2;
    data_in <= x"1f";
    wait for clock_period * 35;
    data_in <= x"18";
    wait for clock_period * 15;
    data_in <= x"00";
    wait for clock_period * 8;
    data_in <= x"ff";
    wait for clock_period * 37;
     data_in <= x"32";
    wait for clock_period * 13;
    write_data <= '0';
    wait for clock_period;
    start_huff <= '1';
     wait for clock_period;
    

    -- Put test bench stimulus code here

    wait;
  end process;

  clocking: process
  begin
    while not stop_the_clock loop
      clk <= '0', '1' after clock_period / 2;
      wait for clock_period;
    end loop;
    wait;
  end process;

end;