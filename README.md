# Tutorial: Implementação de Somador Ponto Flutuante na DE10-Lite

**Autores:** Ricardo Javurek Rihan, [Nome do Aluno 2], , Paloma Valéria Campos de Lima.

**Disciplina:** Sistemas Digitais Q2.20026

**Data:** 09/08/2026

---
*Etapa 1*
## 1. Objetivo do Projeto
Este projeto adapta o somador de ponto flutuante simplificado (13 bits) do livro-texto para a placa Terasic DE10-Lite (MAX 10). O objetivo é demonstrar a síntese lógica e a simulação de hardware usando VHDL.

## 2. Descrição gráfica do funcionamento do sistema
Usar os elementos necessários para descrever o fucnionamento, isto é, tabelas verdade, diagramas de estados, etc.
Usar as variáveis de entrada e saída especificadas no VHDL.

*Etapa 2*
## 3. Adaptações de Hardware (DE10-Lite)
Indicar o que a arquitetura original usava e quais mudanças foram feitas para a implementação na placa

**O que mudamos no VHDL original:**
* Removemos...
* Roteamos ...
* Reorganizamos ...

**Descrição gráfica do sistema**
* Caso mudar a descrição gráfica feita no item 2, atualizar aqui.
* Usar as variáveis de entrada e saída especificadas no VHDL.

## 4. Evidências de Validação

### Simulação 
Abaixo, a imagem do funcionamento do 4º estágio (normalização). Considerar os 4 casos detalhados.

![Print das Telas do Simulador com as Formas de Onda](link-da-imagem-aqui.jpg)

### Código VHDL Final

** TrabalhoFinal2.vhd -> Responsável por salvar em memória os dois operandos ao clicar os KEY0 e KEY1
```vhdl
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
```

**Trabalho_Final.vhd -> Responsável pela lógica do Somado Principal (É instanciado no Trabalho_Final2.vhdl)
```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Trabalho_Final is
    port (
        sign1, sign2 : in std_logic;
        exp1, exp2   : in std_logic_vector(3 downto 0);
        frac1, frac2 : in std_logic_vector(7 downto 0);
        sign_out     : out std_logic;
        exp_out      : out std_logic_vector(3 downto 0);
        frac_out     : out std_logic_vector(7 downto 0)
    );
end Trabalho_Final;

architecture arch of Trabalho_Final is

    -- Sufixos:
    -- b = bigger (maior)
    -- s = smaller (menor)
    -- a = aligned (alinhado)
    -- n = normalized (normalizado)

    signal signb, signs : std_logic;
    signal expb, exps, expn : unsigned(3 downto 0);
    signal fracb, fracs, fraca, fracn : unsigned(7 downto 0);
    signal sum_norm : unsigned(7 downto 0);
    signal exp_diff : unsigned(3 downto 0);
    signal sum : unsigned(8 downto 0); -- bit extra para carry
    signal leado : unsigned(2 downto 0);

begin

    --------------------------------------------------------------------
    -- 1º estágio: determina qual número possui maior magnitude
    --------------------------------------------------------------------
    process(sign1, sign2, exp1, exp2, frac1, frac2)
    begin
        if (exp1 & frac1) > (exp2 & frac2) then
            signb <= sign1;
            signs <= sign2;
            expb <= unsigned(exp1);
            exps <= unsigned(exp2);
            fracb <= unsigned(frac1);
            fracs <= unsigned(frac2);
        else
            signb <= sign2;
            signs <= sign1;
            expb <= unsigned(exp2);
            exps <= unsigned(exp1);
            fracb <= unsigned(frac2);
            fracs <= unsigned(frac1);
        end if;
    end process;

    --------------------------------------------------------------------
    -- 2º estágio: alinhamento da mantissa do menor operando
    --------------------------------------------------------------------
    exp_diff <= expb - exps;

    with exp_diff select
        fraca <=
            fracs                        when "0000",
            "0" & fracs(7 downto 1)      when "0001",
            "00" & fracs(7 downto 2)     when "0010",
            "000" & fracs(7 downto 3)    when "0011",
            "0000" & fracs(7 downto 4)   when "0100",
            "00000" & fracs(7 downto 5)  when "0101",
            "000000" & fracs(7 downto 6) when "0110",
            "0000000" & fracs(7)         when "0111",
            "00000000"                   when others;

    --------------------------------------------------------------------
    -- 3º estágio: soma ou subtração das mantissas
    --------------------------------------------------------------------
    sum <=
        ('0' & fracb) + ('0' & fraca) when signb = signs else
        ('0' & fracb) - ('0' & fraca);

    --------------------------------------------------------------------
    -- 4º estágio: contagem de zeros à esquerda
    --------------------------------------------------------------------
    leado <=
        "000" when (sum(7) = '1') else
        "001" when (sum(6) = '1') else
        "010" when (sum(5) = '1') else
        "011" when (sum(4) = '1') else
        "100" when (sum(3) = '1') else
        "101" when (sum(2) = '1') else
        "110" when (sum(1) = '1') else
        "111";

    --------------------------------------------------------------------
    -- Deslocamento da mantissa para normalização
    --------------------------------------------------------------------
    with leado select
        sum_norm <=
            sum(7 downto 0)             when "000",
            sum(6 downto 0) & '0'       when "001",
            sum(5 downto 0) & "00"      when "010",
            sum(4 downto 0) & "000"     when "011",
            sum(3 downto 0) & "0000"    when "100",
            sum(2 downto 0) & "00000"   when "101",
            sum(1 downto 0) & "000000"  when "110",
            sum(0) & "0000000"          when others;

    --------------------------------------------------------------------
    -- Ajuste final do expoente e da mantissa
    --------------------------------------------------------------------
    process(sum, sum_norm, expb, leado)
    begin
        if sum(8) = '1' then
            -- Carry gerado
            expn <= expb + 1;
            fracn <= sum(8 downto 1);

        elsif leado > expb then
            -- Underflow
            expn <= (others => '0');
            fracn <= (others => '0');

        else
            -- Normalização convencional
            expn <= expb - leado;
            fracn <= sum_norm;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Saídas
    --------------------------------------------------------------------
    sign_out <= signb;
    exp_out <= std_logic_vector(expn);
    frac_out <= std_logic_vector(fracn);

end arch;
```

*Etapa 3*

### Funcionamento na Placa
Abaixo, imagens do funcionamento na Placa para 4 casos.

*Etapa 4 (considerando qeu a Etapa 4 considera toda a documentação em si)*
## 5. Diário de Bordo de IA 
Utilizamos o [ChatGPT/Claude/Gemini] para auxiliar na geração do Testbench e na refatoração do código. Abaixo está a análise crítica do uso da ferramenta.

**Prompts Utilizados:**
> "Gemini, gere casos de teste pra que eu consiga validar com assertividade que o código que coloquei na placa esta funcionando da forma esperada"

**O Erro da IA (Alucinação):**
> Descreva aqui o que a IA errou (ex: tentou usar pinos inexistentes, criou clock em testbench de circuito combinacional, etc).

**A Correção Humana:**
> Como você corrigiu o código gerado para que ele funcionasse na nossa placa e na simulação.

## 6. Contribuição dos participantes
Utilize a taxonomia CRediT, seguem exemplos:
 * Ricardo Javurek Rihan, Administração do Projeto, Desenvolvimento, implementação e teste de software, Análise Formal, Validação de dados e experimentos
 * [Nome do Aluno 2], Administração do Projeto, Desenvolvimento,  Análise Formal, Validação de dados e experimentos, Redação do manuscrito original
 * Paloma Valéria Campos de Lima, Administração do Projeto, Desenvolvimento, implementação e teste de software, Validação de dados e experimentos, Redação do manuscrito original
