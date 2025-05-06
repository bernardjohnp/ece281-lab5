----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity ALU is
    Port (
        i_A      : in  STD_LOGIC_VECTOR (7 downto 0);
        i_B      : in  STD_LOGIC_VECTOR (7 downto 0);
        i_op     : in  STD_LOGIC_VECTOR (2 downto 0);
        o_result : out STD_LOGIC_VECTOR (7 downto 0);
        o_flags  : out STD_LOGIC_VECTOR (3 downto 0)  -- [N,Z,C,V]
    );
end ALU;

architecture Behavioral of ALU is
    signal w_result : STD_LOGIC_VECTOR(7 downto 0);
    signal w_flags  : STD_LOGIC_VECTOR(3 downto 0);
    signal A_signed, B_signed : SIGNED(7 downto 0);
    signal result_9bit : SIGNED(8 downto 0);
begin

    process(i_A, i_B, i_op)
    begin
        -- Default
        A_signed <= SIGNED(i_A);
        B_signed <= SIGNED(i_B);
        result_9bit <= (others => '0');
        w_result <= (others => '0');
        w_flags  <= (others => '0');

        case i_op is
            when "000" =>  -- ADD
                result_9bit <= RESIZE(A_signed, 9) + RESIZE(B_signed, 9);
                w_result <= STD_LOGIC_VECTOR(result_9bit(7 downto 0));
                w_flags(3) <= result_9bit(7); -- Negative
                if result_9bit(7 downto 0) = "00000000" then
                    w_flags(2) <= '1';
                end if;
                w_flags(1) <= result_9bit(8); -- Carry
                if i_A(7) = i_B(7) and w_result(7) /= i_A(7) then
                    w_flags(0) <= '1';
                end if;

            when "001" =>  -- SUB
                result_9bit <= RESIZE(A_signed, 9) - RESIZE(B_signed, 9);
                w_result <= STD_LOGIC_VECTOR(result_9bit(7 downto 0));
                w_flags(3) <= result_9bit(7);
                if result_9bit(7 downto 0) = "00000000" then
                    w_flags(2) <= '1';
                end if;
                w_flags(1) <= result_9bit(8);
                if i_A(7) /= i_B(7) and w_result(7) /= i_A(7) then
                    w_flags(0) <= '1';
                end if;

            when "010" =>  -- AND
                w_result <= i_A and i_B;
                w_flags(3) <= w_result(7);
                if w_result = "00000000" then
                    w_flags(2) <= '1';
                end if;

            when "011" =>  -- OR
                w_result <= i_A or i_B;
                w_flags(3) <= w_result(7);
                if w_result = "00000000" then
                    w_flags(2) <= '1';
                end if;

            when others =>
                w_result <= (others => '0');
                w_flags  <= (others => '0');
        end case;
    end process;

    o_result <= w_result;
    o_flags  <= w_flags;
end Behavioral;