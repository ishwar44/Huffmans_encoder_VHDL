----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.06.2021 01:12:07
-- Design Name: 
-- Module Name: sorting_cell - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sorting_cell is
    Generic
    (
        counter_width : positive := 8
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
end sorting_cell;

architecture Behavioral of sorting_cell is
signal full : std_logic := '0';
signal cell_counter_buf : STD_LOGIC_VECTOR (counter_width - 1 downto 0) := (others => '0');
signal cell_data_buf : STD_LOGIC_VECTOR (8 downto 0) := (others => '0');
signal new_data_fits : std_logic := '0';
signal priority_vector  : STD_LOGIC_VECTOR (4 downto 0);
begin
    new_data_fits <= '1' when unsigned(new_cell_counter) < unsigned(cell_counter_buf) or full = '0' else '0';
    cell_data_is_pushed <= '1' when new_data_fits = '1' and full = '1' else  '0';
    priority_vector <= shift_up & new_data_fits & prev_cell_counter_pushed & full & prev_cell_state;
    process(clk, rst_n)
    begin
        if(rst_n = '0') then
            full <= '0';
            cell_state <= '0';
            cell_counter <= (others => '0');
        elsif(rising_edge(clk)) then
            if(enable = '1') then
                if(full = '0') then
                    if(prev_cell_counter_pushed = '1') then
                        full <= '1';
                        cell_state <= '1';
                    else
                        if(prev_cell_state = '1') then
                            full <= '1';
                            cell_state <= '1';
                        else
                            full <= '0';
                            cell_state <= '0';
                        end if;
                    
                    end if;
                else
                    full <= '1';
                    cell_state <= '1'; 
                end if;
                
                case(priority_vector) is
                
                    when "0-1--" =>
                        cell_counter_buf <= prev_cell_counter;
                        cell_counter <= prev_cell_counter;
                        cell_data <= prev_cell_data;
                        cell_data_buf <= prev_cell_data;
                    
                    when "0101-" =>
                        cell_counter_buf <= new_cell_counter;
                        cell_counter <= new_cell_counter;
                        cell_data <= new_cell_data;
                        cell_data_buf <= new_cell_data;
                    
                    when "0-001" =>
                        cell_counter_buf <= new_cell_counter;
                        cell_counter <= new_cell_counter;
                        cell_data <= new_cell_data;
                        cell_data_buf <= new_cell_data;
                        
                    when "1----" =>
                        cell_counter_buf <= next_cell_counter;
                        cell_counter <= next_cell_counter;
                        cell_data <= next_cell_data;
                        cell_data_buf <= next_cell_data;
                        cell_state <= next_cell_state;
                        full      <= next_cell_state;
                        
                    when others => 
                        cell_counter <= cell_counter_buf;
                        cell_data <= cell_data_buf;
                
                end case;
                
            end if;
        end if;
        
    end process;


end Behavioral;
