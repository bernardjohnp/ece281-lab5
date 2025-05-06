----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is
    
--    type sm_state is (clear, operand1, operand2, result);
--    signal s_curr, s_next : sm_state;
    
    signal s_curr, s_next : std_logic_vector(3 downto 0);

begin

--concurrent statements
    
--next state logic
    s_next(0) <= (s_curr(3) and i_adv) or (s_curr(3) and i_reset and not i_adv) or (s_curr(2) and not i_adv and i_reset) or (s_curr(1) and not i_adv and i_reset);
    s_next(1) <= (s_curr(0) and i_adv) and not i_reset;
    s_next(2) <= (s_curr(1) and i_adv) and not i_reset;
    s_next(3) <= (s_curr(2) and i_adv) and not i_reset;
    
                   
--output logic
    o_cycle(0) <= s_curr(0);
    o_cycle(1) <= s_curr(1);
    o_cycle(2) <= s_curr(2);
    o_cycle(3) <= s_curr(3);

--state register
    process(i_reset, i_adv)
    begin
        if i_reset = '1' then
            s_curr <= "0001"; -- A
        elsif rising_edge(i_adv) then
            s_curr <= s_next;
        end if;
    end process;
    
    
end FSM;