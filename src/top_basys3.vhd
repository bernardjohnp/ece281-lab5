--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
 
 
entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        btnL    :   in std_logic; -- master reset
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;
 
architecture top_basys3_arch of top_basys3 is 
	-- declare components and signals
 
--components  
    component sevenseg_decoder is
            port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
            );
        end component sevenseg_decoder;
        
    component controller_fsm is
            port (
            i_reset : in  STD_LOGIC;
            i_adv  : in  STD_LOGIC;
            o_cycle : out STD_LOGIC_VECTOR (3 downto 0)		   
	        );
	   end component controller_fsm;
 
    component twos_comp is
	       port (
	       i_bin   : in STD_LOGIC_VECTOR(7 downto 0);
	       o_sign  : out STD_LOGIC;
	       o_hund  : out STD_LOGIC_VECTOR(3 downto 0);
	       o_tens  : out STD_LOGIC_VECTOR(3 downto 0);
	       o_ones  : out STD_LOGIC_VECTOR(3 downto 0)
	       );
	   end component twos_comp;
 
    component TDM4 is
		  generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
          port(i_clk		: in  STD_LOGIC;
               i_reset		: in  STD_LOGIC; -- asynchronous
               i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	       );
        end component TDM4;
        
    component clock_divider is
            generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
            port (  i_clk    : in std_logic;
                    i_reset  : in std_logic;		   -- asynchronous
                    o_clk    : out std_logic		   -- divided (slow) clock
            );
        end component clock_divider;
 
    component ALU is
            Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
                i_B : in STD_LOGIC_VECTOR (7 downto 0);
                i_op : in STD_LOGIC_VECTOR (2 downto 0);
                o_result : out STD_LOGIC_VECTOR (7 downto 0);
                o_flags : out STD_LOGIC_VECTOR (3 downto 0)
            );
        end component ALU;
 
 
-- hot singles
    signal w_data, w_cycle, w_sel, w_flags   : std_logic_vector(3 downto 0);
    signal master_reset : std_logic;
    signal w_result, w_i_A, w_i_B : std_logic_vector(7 downto 0);
    signal w_D3, w_D2, w_D1, w_D0 : std_logic_vector(3 downto 0);
    signal w_bin    : std_logic_vector(7 downto 0);
    signal w_clkdiv_to_tdm    : std_logic;
    signal w_opp    : std_logic_vector(2 downto 0);
    signal w_sign : std_logic;

    
 
begin
	-- PORT MAPS ----------------------------------------
    sevenseg_decoder_mappings : sevenseg_decoder port map (
        i_Hex => w_data,
        o_seg_n => seg
    );
    
    controller_fsm_mappings : controller_fsm port map (
        i_reset => btnU,
        i_adv => btnC,
        o_cycle => w_cycle
    );
    
    --        need to find solution for o_sign and its mapping in twos_comp_mappings
    twos_comp_mappings : twos_comp port map (
        i_bin => w_result,
        o_sign => w_sign,
        o_hund => w_D2,
        o_tens => w_D1,
        o_ones => w_D0
    );
    
    TDM4_mappings : TDM4 port map (
        i_clk => w_clkdiv_to_tdm,
        i_reset => btnU,
        i_D3 => w_D3,
        i_D2 => w_D2,
        i_D1 => w_D1,
        i_D0 => w_D0,
        o_data => w_data,
        o_sel => w_sel
    );
    
    ALU_mappings : ALU port map (
        i_A => w_i_A,
        i_B => w_i_B,
        i_op => w_opp,
        o_result => w_result,
        o_flags => w_flags
    );
    
--    dont know if k_DIV is the correct number
	clkdiv_inst : clock_divider 		--instantiation of clock_divider to take 
        generic map ( k_DIV => 50000000 ) -- 1 Hz clock from 100 MHz
        port map (					    	  
            i_clk   => clk,
            i_reset => master_reset,
            o_clk => w_clkdiv_to_tdm
    );
    
	-- CONCURRENT STATEMENTS ----------------------------
    master_reset <= btnL or btnU;
    led(3 downto 0) <= w_cycle;
    led(15 downto 12) <= w_flags;
    
    with w_cycle select
    w_i_A <= sw when "0001", w_i_A when others;

    with w_cycle select
        w_i_B <= sw when "0010", w_i_B when others;
    
    with w_cycle select
        w_opp <= sw(2 downto 0) when "0100", w_opp when others;
    
    
--    mux logic not working
    with w_cycle select
    w_bin <= w_i_A    when "0001",  -- state A
             w_i_B    when "0010",  -- state B
             w_result when "1000",  -- state RESULT
             (others => '0') when others;
    
    w_D3 <= "1010" when w_sign = '1' else "0000";  -- dash or blank

end top_basys3_arch;