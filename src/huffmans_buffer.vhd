----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.11.2021 19:16:49
-- Design Name: 
-- Module Name: huffmans_buffer - Behavioral
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

entity huffmans_encoder is
    Port ( clk : in STD_LOGIC;
           rst_n : in STD_LOGIC;
           write_data : in STD_LOGIC;
           start_huff : in STD_LOGIC;
           data_in : in STD_LOGIC_VECTOR (7 downto 0);
           done   : out STD_LOGIC := '1';
           some_out : out STD_LOGIC_VECTOR (7 downto 0));
end huffmans_encoder;

architecture Behavioral of huffmans_encoder is


component sorting_array_rtl is
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
end component;

type state is (idle, load_data, wait_state_0,get_sort_data_0, get_sort_data_1, gen_node, get_sort_data_2, read_back_node,create_codeword, create_codeword_wait, init_create_codeword_0, init_create_codeword_1,done_state);
type t_counter_arr is array(0 to 255) of unsigned(15 downto 0);
type t_data_arr is array(0 to 65535) of std_logic_vector(7 downto 0);
type t_node_arr is array(0 to 127) of std_logic_vector(17 downto 0);
type t_stack is array(0 to 15) of std_logic_vector(17 downto 0);
type t_huff_table is array(0 to 255) of std_logic_vector(19 downto 0);

signal counter_arr : t_counter_arr := (others => (others => '0'));
signal data_arr : t_data_arr := (others => (others => '0'));
signal data_addr : unsigned(15 downto 0) := (others => '0');
signal enable_sort : std_logic := '0';
signal shift_up_sig : std_logic := '0';
signal counter_sig : std_logic_vector(15 downto 0) := (others => '0');
signal data_sig : std_logic_vector(8 downto 0) := (others => '0');
signal sorted_counter_sig : std_logic_vector(15 downto 0) := (others => '0');
signal sorted_data_sig : std_logic_vector(8 downto 0) := (others => '0');

signal busy_int : std_logic := '0';

signal current_state : state := idle;

signal read_sig : std_logic := '0';
signal unsorted_counter : unsigned(15 downto 0);
signal unsorted_data : std_logic_vector(7 downto 0);
signal unsorted_arr_addr : unsigned(7 downto 0) := (others => '0');
signal flag_0_sig : std_logic := '0';

signal empty_sig : std_logic := '0';
signal almost_empty_sig : std_logic := '0';

signal node_id : unsigned(7 downto 0) := (others => '0');
signal node : std_logic_vector(17 downto 0) := (others => '0');
signal node_r : std_logic_vector(17 downto 0) := (others => '0');
signal node_write_addr: unsigned(6 downto 0) := (others => '0');
signal node_arr : t_node_arr := (others => (others => '0'));
signal node_write : std_logic := '0';
signal node_read_addr: unsigned(6 downto 0) := (others => '0');

signal data_val_0 : std_logic_vector(8 downto 0);
signal data_val_1 : std_logic_vector(8 downto 0);
signal sum_counter : unsigned(15 downto 0);

signal stack : t_stack := (others => (others => '0'));
signal stack_write_element :std_logic_vector(17 downto 0);
signal stack_read_element :std_logic_vector(17 downto 0);
signal stack_pointer : unsigned(3 downto 0) := (others => '0');
signal stack_write : std_logic := '0';
signal stack_read : std_logic := '0';
signal stack_empty : std_logic := '0';

signal codeword : std_logic_vector(15 downto 0) := (others => '0');
signal codeword_bit_length : unsigned(3 downto 0) := x"1";
signal from_stack_flag  : std_logic  := '0';

signal huff_table           : t_huff_table := (others => (others => '0'));
signal huff_table_write     : std_logic := '0';
signal huff_table_read      : std_logic := '0';
signal huff_table_addr      : unsigned(7 downto 0) :=(others => '0');
signal huff_table_element   : std_logic_vector(19 downto 0) := (others => '0');

signal double_write         : std_logic := '0';

signal unique_data_num      : unsigned(7 downto 0) := (others => '0');
signal codeword_num         : unsigned(7 downto 0) := (others => '0');
signal sub_reg              : std_logic_vector(7 downto 0)  := (others => '0');

begin

inst_sorting_array_rtl : sorting_array_rtl
port map
(
    clk         => clk,
    rst_n       => rst_n,
    enable      => enable_sort,
    shift_up    => shift_up_sig,
    counter_in  => counter_sig,
    data_in     => data_sig,
    counter_out => sorted_counter_sig,
    empty       => empty_sig,
    almost_empty=> almost_empty_sig,
    data_out    => sorted_data_sig
);

stack_proc : process(clk, rst_n)
begin
    if(rst_n = '0') then
        stack <= (others => (others => '0'));
    elsif(rising_edge(clk)) then
        if(stack_write = '1') then
            stack(to_integer(stack_pointer)) <= stack_write_element;
            stack_pointer <= stack_pointer + 1;
        elsif(stack_read = '1') then
            stack_read_element <= stack(to_integer(stack_pointer-1));
            if(stack_pointer /= 0) then
                stack_pointer <= stack_pointer - 1;
            end if;
        end if;
        if(stack_pointer = 0 or (stack_pointer = 1 and stack_read = '1')) then
            stack_empty <= '1';
        else
            stack_empty <= '0';
        end if;
    end if;
end process;

counter_write_proc : process(clk, rst_n)
begin
    if(rst_n = '0') then
        counter_arr <= (others => (others => '0'));
    elsif(rising_edge(clk)) then
        if(write_data = '1' and busy_int = '0') then
            counter_arr(to_integer(unsigned(data_in))) <= counter_arr(to_integer(unsigned(data_in))) + 1;
        end if;
    end if;
end process;

data_write_proc : process(clk, rst_n)
begin
    if(rst_n = '0') then
        data_arr <= (others => (others => '0'));
    elsif(rising_edge(clk)) then
        if(write_data = '1' and busy_int = '0') then
            data_arr(to_integer(unsigned(data_addr))) <= data_in;
            data_addr <= data_addr + 1;
        end if;
    end if;
end process;

counter_read_proc : process(clk, rst_n)
begin
    if(rst_n = '0') then
        unsorted_counter <= (others => '0');
    elsif(rising_edge(clk)) then
        unsorted_counter <= counter_arr(to_integer(unsorted_arr_addr)) ;
    end if;
end process;

node_write_proc : process(clk, rst_n)
begin
    if(rst_n = '0') then
        node_arr <= (others => (others => '0'));
    elsif(rising_edge(clk)) then
        if(node_write = '1') then
            node_arr(to_integer(node_write_addr)) <= node;
            node_write_addr <= node_write_addr + 1;
        end if;
    end if;
end process;

node_read_proc : process(clk, rst_n)
begin
    if(rst_n = '0') then
        node_r <= (others => '0');
    elsif(rising_edge(clk)) then
        node_r <=  node_arr(to_integer(node_read_addr));
    end if;
end process;

table_proc : process(clk, rst_n)
begin
    if(rst_n = '0') then
        huff_table <= (others => (others => '0'));
    elsif(rising_edge(clk)) then
        if(huff_table_write = '1') then
            huff_table(to_integer(huff_table_addr)) <= huff_table_element;
        end if;
    end if;
    
    
end process;

controller_proc : process(clk, rst_n)
begin
    if(rst_n = '0') then
        node_read_addr <= (others => '0');
        enable_sort <= '0';
        shift_up_sig <= '0';
        node_write <= '0';
        current_state <= idle;
        from_stack_flag <= '0';
    elsif(rising_edge(clk)) then
         enable_sort <= '0';
         shift_up_sig <= '0';
         node_write <= '0';
         stack_write <= '0';
         stack_read <= '0';
         huff_table_write <= '0';
         from_stack_flag <= '0';
        case(current_state) is
        
        when idle =>
            if(start_huff = '1') then
                busy_int <= '1';
                current_state <= load_data;
                unsorted_arr_addr <= (others => '0');
                --unsorted_arr_addr <= unsorted_arr_addr + 1;
            end if;
        
        when load_data =>
            enable_sort <= '0';
            if(flag_0_sig = '0') then
                flag_0_sig <= '1';
                
            end if;
            if(flag_0_sig = '1') then
                flag_0_sig <= '0';
                if(unsorted_arr_addr = 255) then
                    unsorted_arr_addr <= (others => '0');
                    current_state <= wait_state_0;
                    enable_sort <= '1';
                    --shift_up_sig <= '1';
                else
                    current_state <= load_data;
                    unsorted_arr_addr <= unsorted_arr_addr + 1;
                end if;
                if(unsorted_counter > 0) then
                    enable_sort <= '1';
                    counter_sig <= std_logic_vector(unsorted_counter);
                    data_sig <= '0' & std_logic_vector(unsorted_arr_addr);
                    unique_data_num <= unique_data_num + 1;
                else
                    enable_sort <= '0';
                end if;
            end if;
        
        when wait_state_0 =>
            enable_sort <= '1';
            shift_up_sig <= '1';
            current_state <= get_sort_data_0;
        
        when get_sort_data_0 =>
            enable_sort <= '1';
            shift_up_sig <= '1';
            sum_counter <= unsigned(sorted_counter_sig);
            data_val_0 <= sorted_data_sig;
            current_state <= get_sort_data_1;
       
        when get_sort_data_1 =>
            sum_counter <= sum_counter + unsigned(sorted_counter_sig);
            data_val_1 <= sorted_data_sig;
            current_state <= gen_node;
       
        when gen_node =>
            node_write <= '1';
            node <= data_val_0 & data_val_1;
            enable_sort <= '1';
            counter_sig <= std_logic_vector(sum_counter);
            data_sig <= '1' & std_logic_vector(node_id);
            node_id <= node_id + 1;
            current_state <= get_sort_data_2;
            
        
        when get_sort_data_2 =>
            if(empty_sig = '1') then
                current_state <= init_create_codeword_0;
            else
                current_state <= get_sort_data_0;
                enable_sort <= '1';
                shift_up_sig <= '1';
                node_read_addr <= node_read_addr + 1;
            end if;
        
        when init_create_codeword_0 =>
            current_state <= init_create_codeword_1;
            
        when init_create_codeword_1 =>
            current_state <= create_codeword;
        
        when create_codeword =>
            current_state <= create_codeword_wait;
            if(node_r(17) = '1' and node_r(8) = '1' and from_stack_flag = '0') then
                stack_write_element <= node_r;
                stack_write <= '1';
                codeword <= codeword(14 downto 0) & '1';
                node_read_addr <= unsigned(node_r(15 downto 9));
                codeword_bit_length <= codeword_bit_length + 1;
                if(sub_reg /= x"00") then
                    sub_reg <= sub_reg(6 downto 0) & '0';
                end if;
                
            
            elsif(stack_read_element(17) = '1' and stack_read_element(8) = '1' and from_stack_flag = '1') then
                
                if(sub_reg(0) = '1') then
                    stack_read <= '1';
                    from_stack_flag <= '1';
                    codeword <= '0' & codeword(15 downto 1);
                    codeword_bit_length <= codeword_bit_length - 1;
                    sub_reg <= '0' & sub_reg(7 downto 1);
                else
                    codeword <= codeword(14 downto 0) & '0';
                    node_read_addr <= unsigned(stack_read_element(6 downto 0));
                    codeword_bit_length <= codeword_bit_length + 1;
                    stack_write <= '1';
                    stack_write_element <= stack_read_element;
                    sub_reg <= std_logic_vector(unsigned(sub_reg) + 1);
                end if;
                
            
            elsif(node_r(17) = '1' and node_r(8) = '0' and from_stack_flag = '0') then
                stack_write_element <= node_r;
                stack_write <= '1';
                codeword <= codeword(14 downto 0) & '1';
                node_read_addr <= unsigned(node_r(15 downto 9));
                codeword_bit_length <= codeword_bit_length + 1;
            
            elsif(stack_read_element(17) = '1' and stack_read_element(8) = '0' and from_stack_flag = '1') then
                huff_table_write <= '1';
                codeword_num <= codeword_num + 1;
                huff_table_element <= std_logic_vector(codeword_bit_length) & codeword(14 downto 0) & '0';
                huff_table_addr <= unsigned(stack_read_element(7 downto 0));
                codeword <= '0' & codeword(15 downto 1);
                from_stack_flag <= '1';
                codeword_bit_length <= codeword_bit_length - 1;
                if(stack_empty = '1') then
                    stack_read <= '0';
                else
                    stack_read <= '1';
                end if;
            
            elsif(node_r(17) = '0' and node_r(8) = '1' and from_stack_flag = '0') then
                stack_write_element <= node_r;
                stack_write <= '1';
                codeword <= codeword(14 downto 0) & '0';
                node_read_addr <= unsigned(node_r(6 downto 0));
                codeword_bit_length <= codeword_bit_length + 1;
            
            elsif(stack_read_element(17) = '0' and stack_read_element(8) = '1' and from_stack_flag = '1') then
                huff_table_write <= '1';
                codeword_num <= codeword_num + 1;
                huff_table_element <= std_logic_vector(codeword_bit_length) & codeword(14 downto 0) & '1';
                huff_table_addr <= unsigned(stack_read_element(16 downto 9));
                if(stack_empty = '1') then
                    stack_read <= '0';
                else
                    stack_read <= '1';
                end if;
                codeword <= '0' & codeword(15 downto 1);
                from_stack_flag <= '1';
                codeword_bit_length <= codeword_bit_length - 1;
            else
                huff_table_write <= '1';
                codeword_num <= codeword_num + 1;
                if(double_write = '0') then
                    double_write <= '1';
                    huff_table_element <= std_logic_vector(codeword_bit_length) & codeword(14 downto 0) & '1';
                    huff_table_addr <= unsigned(node_r(16 downto 9));
                    current_state <= create_codeword;
                else
                    double_write <= '0';
                    if(stack_empty = '1') then
                        stack_read <= '0';
                    else
                        stack_read <= '1';
                    end if;
                    codeword <= '0' & codeword(15 downto 1);
                    from_stack_flag <= '1';
                    codeword_bit_length <= codeword_bit_length - 1;
                    huff_table_element <= std_logic_vector(codeword_bit_length) & codeword(14 downto 0) & '0';
                    huff_table_addr <= unsigned(node_r(7 downto 0));
                end if;
            end if;
            if(codeword_num = unique_data_num) then
                current_state <= done_state;
            end if;
            
            
        when create_codeword_wait =>
            current_state <= create_codeword;
            from_stack_flag <= from_stack_flag;
           
        when done_state =>
            
       
        when others => 
               
        end case;
       
       
    
    end if;
end process;

end Behavioral;
