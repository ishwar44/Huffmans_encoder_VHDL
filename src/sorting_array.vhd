----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.06.2021 01:39:00
-- Design Name: 
-- Module Name: top_level - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sorting_array_rtl is
    Generic
    (
        counter_width : positive := 16;
        arr_size : positive := 256
    );
    Port ( clk : in STD_LOGIC;
           rst_n : in STD_LOGIC;
           enable : in STD_LOGIC;
           shift_up : in std_logic;
           counter_in : in STD_LOGIC_VECTOR (counter_width - 1 downto 0);
           data_in : in STD_LOGIC_VECTOR (8 downto 0);
           counter_out : out STD_LOGIC_VECTOR (counter_width - 1 downto 0);
           empty    : out std_logic;
           almost_empty : out std_logic;
           data_out : out std_logic_vector(8 downto 0));
end sorting_array_rtl;

architecture Behavioral of sorting_array_rtl is
component sorting_cell is
    Generic
    (
        counter_width : positive := 16
    );
    Port ( clk : in STD_LOGIC;
           rst_n : in STD_LOGIC;
           enable : in STD_LOGIC;
           shift_up : in std_logic;
           prev_cell_data : in STD_LOGIC_VECTOR (8 downto 0);
           new_cell_data : in STD_LOGIC_VECTOR (8 downto 0);
           next_cell_data : in STD_LOGIC_VECTOR (8 downto 0);
           prev_cell_counter : in STD_LOGIC_VECTOR (counter_width - 1 downto 0);
           new_cell_counter : in STD_LOGIC_VECTOR (counter_width - 1 downto 0);
           next_cell_counter : in STD_LOGIC_VECTOR (counter_width - 1 downto 0);
           prev_cell_counter_pushed : in STD_LOGIC;
           prev_cell_state : in STD_LOGIC;
           cell_counter : out STD_LOGIC_VECTOR (counter_width - 1 downto 0) := (others => '0');
           cell_data : out STD_LOGIC_VECTOR (8 downto 0) := (others => '0');
           cell_data_is_pushed : out STD_LOGIC := '0';
           next_cell_state  : in STD_LOGIC;
           cell_state : out STD_LOGIC := '0');
end component;
type t_cell_counter_arr is array(0 to arr_size - 1) of std_logic_vector(counter_width - 1 downto 0);
type t_cell_data_arr is array(0 to arr_size - 1) of std_logic_vector(8 downto 0);
signal cell_data_arr : t_cell_data_arr := (others => (others => '0'));
signal cell_counter_arr : t_cell_counter_arr := (others => (others => '0'));
signal cell_data_is_pushed_arr : std_logic_vector(arr_size - 1 downto 0) := (others => '0');
signal cell_state_arr : std_logic_vector(arr_size - 1 downto 0) := (others => '0');
begin
    data_out <= cell_data_arr(0);
    counter_out <= cell_counter_arr(0);
    empty <= not cell_state_arr(0);
    almost_empty <= '1' when (cell_state_arr(0) = '1' and cell_state_arr(1) = '0') else '0';
    sorting_array : for i in 0 to arr_size - 1  generate
    begin
    first_cell : if i = 0 generate
        begin
        U0 : sorting_cell
        generic map
        (
            counter_width => counter_width
        )
        port map
        (
            clk => clk,
            rst_n => rst_n,
            enable => enable,
            shift_up => shift_up,
            new_cell_counter => counter_in,
            new_cell_data => data_in,
            prev_cell_counter => (others => '0'),
            prev_cell_data => (others => '0'),
            next_cell_data => cell_data_arr(i+1),
            next_cell_counter => cell_counter_arr(i+1),
            next_cell_state =>  cell_state_arr(i+1),
            prev_cell_counter_pushed => '0',
            prev_cell_state => '1',
            cell_counter => cell_counter_arr(i),
            cell_data => cell_data_arr(i),
            cell_data_is_pushed => cell_data_is_pushed_arr(i),
            cell_state => cell_state_arr(i)
        );
    
        end generate first_cell;
    
        rest_of_cells : if i < arr_size - 2 and i > 0 generate
        begin
        UX : sorting_cell
        generic map
        (
            counter_width => counter_width
        )
        port map
        (
            clk => clk,
            rst_n => rst_n,
            enable => enable,
            shift_up => shift_up,
            new_cell_data => data_in,
            new_cell_counter => counter_in,
            prev_cell_data => cell_data_arr(i - 1),
            prev_cell_counter => cell_counter_arr(i-1),
            next_cell_data => cell_data_arr(i+1),
            next_cell_counter => cell_counter_arr(i+1),
            next_cell_state =>  cell_state_arr(i+1),
            prev_cell_counter_pushed => cell_data_is_pushed_arr(i - 1),
            prev_cell_state => cell_state_arr(i - 1),
            cell_data => cell_data_arr(i),
            cell_counter => cell_counter_arr(i),
            cell_data_is_pushed => cell_data_is_pushed_arr(i),
            cell_state => cell_state_arr(i)
        );
        
        end generate rest_of_cells;
        
     last_cell : if i = arr_size - 1 generate
        begin
        UX : sorting_cell
        generic map
        (
            counter_width => counter_width
        )
        port map
        (
            clk => clk,
            rst_n => rst_n,
            enable => enable,
            shift_up => shift_up,
            new_cell_data => data_in,
            new_cell_counter => counter_in,
            prev_cell_data => cell_data_arr(i - 1),
            prev_cell_counter => cell_counter_arr(i-1),
            next_cell_data => (others => '0'),
            next_cell_counter => (others => '0'),
            next_cell_state =>  '0',
            prev_cell_counter_pushed => cell_data_is_pushed_arr(i - 1),
            prev_cell_state => cell_state_arr(i - 1),
            cell_data => cell_data_arr(i),
            cell_counter => cell_counter_arr(i),
            cell_data_is_pushed => cell_data_is_pushed_arr(i),
            cell_state => cell_state_arr(i)
        );
    
        end generate last_cell;
    
    end generate sorting_array;


end Behavioral;
