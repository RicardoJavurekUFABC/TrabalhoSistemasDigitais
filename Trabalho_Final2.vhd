library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Trabalho_Final2 is
    port (
        SW   : in  std_logic_vector(9 downto 0);
        KEY  : in  std_logic_vector(1 downto 0);
        LEDR : out std_logic_vector(9 downto 0);
        HEX0 : out std_logic_vector(6 downto 0); -- Exibe exp_out
        HEX1 : out std_logic_vector(6 downto 0); -- Exibe frac_out (nibble baixo)
        HEX2 : out std_logic_vector(6 downto 0)  -- Exibe frac_out (nibble alto)
    );
end entity Trabalho_Final2;

architecture rtl of Trabalho_Final2 is

    -- Registradores internos para armazenar os operandos
    signal sign1_r, sign2_r : std_logic := '0';
    signal exp1_r,  exp2_r  : std_logic_vector(3 downto 0) := "0000";
    signal frac1_r, frac2_r : std_logic_vector(7 downto 0) := "00000000";
    
    -- Saídas do somador
    signal sign_out_s : std_logic;
    signal exp_out_s  : std_logic_vector(3 downto 0);
    signal frac_out_s : std_logic_vector(7 downto 0);

    -- Função de conversão Hex -> 7 Segmentos (Anodo Comum)
    function hex_to_7seg(hex_digit : std_logic_vector(3 downto 0)) return std_logic_vector is
        variable seg : std_logic_vector(6 downto 0);
    begin
        case hex_digit is
            when "0000" => seg := "1000000"; -- 0
            when "0001" => seg := "1111001"; -- 1
            when "0010" => seg := "0100100"; -- 2
            when "0011" => seg := "0110000"; -- 3
            when "0100" => seg := "0011001"; -- 4
            when "0101" => seg := "0010010"; -- 5 (Corrigido)
            when "0110" => seg := "0000010"; -- 6
            when "0111" => seg := "1111000"; -- 7
            when "1000" => seg := "0000000"; -- 8
            when "1001" => seg := "0010000"; -- 9
            when "1010" => seg := "0001000"; -- A
            when "1011" => seg := "0000011"; -- b
            when "1100" => seg := "1000110"; -- C
            when "1101" => seg := "0100001"; -- d
            when "1110" => seg := "0000110"; -- E
            when "1111" => seg := "0001110"; -- F
            when others => seg := "1111111"; -- Apagado
        end case;
        return seg;
    end function;

begin

    --------------------------------------------------------------------
    -- Processo 1: Salva o Operando 1 ao pressionar KEY(0)
    --------------------------------------------------------------------
    process(KEY(0))
    begin
        if falling_edge(KEY(0)) then
            sign1_r <= SW(9);
            exp1_r  <= SW(8 downto 5);
            frac1_r <= SW(4 downto 0) & "000";
        end if;
    end process;

    --------------------------------------------------------------------
    -- Processo 2: Salva o Operando 2 ao pressionar KEY(1)
    --------------------------------------------------------------------
    process(KEY(1))
    begin
        if falling_edge(KEY(1)) then
            sign2_r <= SW(9);
            exp2_r  <= SW(8 downto 5);
            frac2_r <= SW(4 downto 0) & "000";
        end if;
    end process;

    --------------------------------------------------------------------
    -- Instância do Somador Principal (DUT)
    --------------------------------------------------------------------
    U_FP_ADDER : entity work.Trabalho_Final
        port map (
            sign1    => sign1_r,
            sign2    => sign2_r,
            exp1     => exp1_r,
            exp2     => exp2_r,
            frac1    => frac1_r,
            frac2    => frac2_r,
            sign_out => sign_out_s,
            exp_out  => exp_out_s,
            frac_out => frac_out_s
        );

    --------------------------------------------------------------------
    -- Mapeamento para os LEDs e Displays
    --------------------------------------------------------------------
    LEDR(0) <= sign_out_s;                  -- LEDR0 aceso = Resultado Negativo
    LEDR(9 downto 1) <= (others => '0');

    HEX0 <= hex_to_7seg(exp_out_s);         -- Expoente Resultante
    HEX1 <= hex_to_7seg(frac_out_s(3 downto 0)); -- Mantissa (Parte Baixa)
    HEX2 <= hex_to_7seg(frac_out_s(7 downto 4)); -- Mantissa (Parte Alta)

end architecture rtl;