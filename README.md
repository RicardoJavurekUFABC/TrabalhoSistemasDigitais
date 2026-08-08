# Tutorial: Implementação de Somador Ponto Flutuante na DE10-Lite

**Autores:** Ricardo Javurek Rihan, Gustavo Ruiz Lirola Yokooji, Paloma Valéria Campos de Lima

**Disciplina:** Sistemas Digitais Q2.20026

**Data:** 09/08/2026

---
## 1. Objetivo do Projeto
Este projeto adapta o somador de ponto flutuante simplificado (13 bits) do livro-texto para a placa Terasic DE10-Lite (MAX 10). O objetivo é demonstrar a síntese lógica e a simulação de hardware usando VHDL.

## 2. Descrição gráfica do funcionamento do sistema
<img width="1787" height="889" alt="image" src="https://github.com/user-attachments/assets/beb1b75c-b2ae-4eda-892a-5852cda15a4d" />

## 3. Adaptações de Hardware (DE10-Lite)
A arquitetura original do livro-texto pressupõe a entrada simultânea de todos os bits dos dois operandos (26 bits no total: 2 bits de sinal, 8 bits de expoente e 16 bits de mantissa). Como a placa DE10-Lite possui apenas 10 chaves deslizantes (`SW`), foi necessário projetar um módulo *Top-Level* (`Trabalho_Final2.vhd`) para fazer a ponte entre o usuário e o somador aritmético principal (`Trabalho_Final.vhd`).

**O que mudamos no VHDL original (Integração e Roteamento):**
* **Implementação de Multiplexação Temporal:** Utilizamos os botões `KEY0` e `KEY1` como sinais de *clock* pontuais (`falling_edge`) para registrar sequencialmente o Operando 1 e o Operando 2 usando as mesmas 10 chaves (`SW`).
* **Adaptação da Mantissa (Zero-Padding):** Como utilizamos 1 bit para sinal (`SW9`), 4 bits para expoente (`SW8-5`) e restaram apenas 5 bits para a mantissa (`SW4-0`), preenchemos os 3 bits menos significativos exigidos pelo somador original com zeros: `SW(4 downto 0) & "000"`.
* **Decodificação Visual (Displays de 7 Segmentos):** Roteamos o resultado para a interface física da placa. O bit de sinal acende o `LEDR0`, enquanto a mantissa resultante (8 bits) foi dividida em dois *nibbles* e enviada para o `HEX2` (parte alta) e `HEX1` (parte baixa). O expoente resultante foi mapeado no `HEX0`.
* **Lógica Anodo Comum:** Desenvolvemos a função interna `hex_to_7seg` respeitando o padrão elétrico dos displays do MAX 10 (onde '0' acende o segmento e '1' o apaga).

## 4. Evidências de Validação

### Simulação
Abaixo, a imagem do funcionamento das etapas internas do somador, com destaque para o 4º estágio (normalização). Validamos 4 casos fundamentais da aritmética de ponto flutuante: (1) Soma convencional, (2) Geração de *Carry-out* (deslocamento para a direita), (3) Deslocamento para a esquerda (contagem de zeros) e (4) Condição de *Underflow*.

### Descrição dos Casos de Simulação para o Relatório

A simulação temporal do módulo `Trabalho_Final` valida o comportamento do datapath em 4 cenários fundamentais da aritmética de ponto flutuante (intervalos de $100\text{ ns}$):

1. **Intervalo 0 a 100 ns — (1) Soma Convencional (Sem deslocamentos extras):**
* **Entradas:** $\text{Op1} = +1.0 \times 2^4$ (`exp1 = 4`, `frac1 = 0x80`), $\text{Op2} = +0.5 \times 2^4$ (`exp2 = 4`, `frac2 = 0x40`).
* **Saídas:** `exp_out = 4`, `frac_out = 0xC0` ($192$ em decimal), `sign_out = 0`.
* **Análise:** A soma das mantissas resulta em `0x80 + 0x40 = 0xC0`. Como o resultado já está normalizado (bit MSB igual a `'1'`), não há necessidade de ajuste no expoente nem na mantissa.


2. **Intervalo 100 a 200 ns — (2) Geração de *Carry-out* (Deslocamento para a Direita):**
* **Entradas:** $\text{Op1} = -1.0 \times 2^4$ (`sign1 = 1`, `exp1 = 4`, `frac1 = 0x80`), $\text{Op2} = -1.0 \times 2^4$ (`sign2 = 1`, `exp2 = 4`, `frac2 = 0x80`).
* **Saídas:** `exp_out = 5`, `frac_out = 0x80`, `sign_out = 1`.
* **Análise:** A soma $0\text{x}80 + 0\text{x}80 = 0\text{x}100$ gera um bit de estouro (*carry* no bit 8 de `sum`). O circuito detecta `sum(8) = '1'`, divide a mantissa por 2 via deslocamento à direita (`0x100 -> 0x80`) e incrementa o expoente de $4$ para **$5$**.


3. **Intervalo 200 a 300 ns — (3) Deslocamento para a Esquerda (Contagem de Zeros à Esquerda):**
* **Entradas:** $\text{Op1} = +1.0 \times 2^5$ (`sign1 = 0`, `exp1 = 5`, `frac1 = 0x80`), $\text{Op2} = -0.875 \times 2^5$ (`sign2 = 1`, `exp2 = 5`, `frac2 = 0x70`).
* **Saídas:** `exp_out = 2`, `frac_out = 0x80`, `sign_out = 0`.
* **Análise:** A subtração resulta em $0\text{x}80 - 0\text{x}70 = 0\text{x}10$ (`00010000` em binário). O **4º estágio** (Leading Zero Count — LZC) detecta **3 zeros à esquerda** (`leado = 3`). O circuito desloca a mantissa 3 posições à esquerda (`0x10 -> 0x80`) e reduz o expoente em 3 unidades ($5 - 3 = \mathbf{2}$).


4. **Intervalo 300 a 400 ns — (4) Condição de *Underflow* (Anulação Total):**
* **Entradas:** $\text{Op1} = +1.0 \times 2^1$ (`sign1 = 0`, `exp1 = 1`, `frac1 = 0x80`), $\text{Op2} = -1.0 \times 2^1$ (`sign2 = 1`, `exp2 = 1`, `frac2 = 0x80`).
* **Saídas:** `exp_out = 0`, `frac_out = 0x00`, `sign_out = 0`.
* **Análise:** A subtração de valores idênticos resulta em mantissa igual a zero ($0\text{x}80 - 0\text{x}80 = 0$). O detector de zeros calcula `leado = 7`. Como $7 > \text{expb}$ ($7 > 1$), a cláusula `elsif leado > expb` é ativada, acionando a flag de *underflow* e zerando totalmente a saída (`0 0000 00000000`).

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/6ba56824-5a5b-47fa-9e6c-b82421631aba" />

### Código VHDL Final

**TrabalhoFinal2.vhd** -> Responsável por salvar em memória os dois operandos ao clicar em KEY0 e KEY1 e instanciar o Somador Principal.
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

**Trabalho_Final.vhd** -> Responsável pela lógica central (Datapath) do Somador de Ponto Flutuante.
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
### Funcionamento na Placa
Abaixo, imagens do funcionamento na Placa DE10-Lite para 4 casos distintos. As fotos evidenciam a precisão da interface homem-máquina através das chaves (`SW`), visualizada diretamente nos Displays de 7 segmentos.

**Caso 1: Operandos com mesmo expoente (Soma direta)**
* **Cálculo:** `16 + 8 = 24`
* **Saída Esperada:** `C04` (LED apagado)
<img width="1600" height="1200" alt="Caso 1" src="https://github.com/user-attachments/assets/aad4f75d-8606-4a26-a158-6f5b68b2d0c6" />

**Caso 2: Operandos com sinais diferentes (Subtração interna)**
* **Cálculo:** `(-16) + (-16) = -32`
* **Saída Esperada:** `805` (LED aceso, confirmando resultado negativo)
<img width="1600" height="1200" alt="Caso 2" src="https://github.com/user-attachments/assets/35ec5369-6b10-4bed-afdd-9e894ef49576" />

**Caso 3: Necessidade de normalização (Deslocamento)**
* **Cálculo:** `32 - 28 = 4`
* **Saída Esperada:** `802` (LED apagado)
<img width="1600" height="1200" alt="Caso 3" src="https://github.com/user-attachments/assets/f6413e47-7489-4ba0-94e6-71ff911d1bd8" />

**Caso 4: Teste do bit de sinal**
* **Cálculo:** `16 - 32 = -16`
* **Saída Esperada:** `804` (LED aceso, confirmando resultado negativo)
<img width="1600" height="1200" alt="Caso 4" src="https://github.com/user-attachments/assets/04c778a1-89b9-4846-a8f3-10b8e4ae1a17" />

## 5. Diário de Bordo de IA 
Utilizamos IA generativa (Gemini) atuando estritamente como ferramenta de apoio técnico para gerar cenários de testes preliminares. Abaixo está a análise crítica do uso da ferramenta e como aplicamos correções humanas aos seus resultados.

**Auxílio na Geração de Casos de Teste**
* **Prompt Utilizado:** "Gemini, por favor gere 4 cenários de teste manuais para que eu consiga validar com assertividade que meu somador de ponto flutuante de 13 bits está funcionando. Preciso de testes que forcem a geração de carry na mantissa, underflow e alinhamento de expoentes distintos."
* **O Erro da IA (Falta de Contexto Físico):** A IA sugeriu valores de teste perfeitos do ponto de vista teórico para um somador de 8 bits de mantissa. No entanto, ela falhou em considerar a restrição arquitetural do nosso *Top-Level* físico: os testes propostos exigiam entradas como `frac = 10101111`. Isso era fisicamente impossível na nossa montagem, pois limitamos a entrada da mantissa na DE10-Lite a apenas 5 chaves (`SW4` a `SW0`), concatenando estaticamente `000` nos bits menos significativos via código (`SW(4 downto 0) & "000"`). 
* **A Correção Humana:** Identificamos que as massas de teste da IA não poderiam ser replicadas na placa. O grupo teve que refatorar os casos de teste sugeridos manualmente, truncando a parte menos significativa dos valores e recalculando os resultados esperados levando em consideração apenas valores de mantissa terminados obrigatoriamente em `000`. 


## 6. Contribuição dos participantes
A divisão de tarefas seguiu a taxonomia CRediT, garantindo contribuição equivalente entre todos os membros do grupo:

* **Ricardo Javurek Rihan:** Administração do Projeto, Desenvolvimento da lógica Top-Level em VHDL, Implementação e teste de hardware (DE10-Lite), Análise Formal, Validação de dados e experimentos.
* **Gustavo Ruiz Lirola Yokooji:** Administração do Projeto, Desenvolvimento da adaptação da interface com displays de 7 segmentos, Análise Formal, Validação de dados e experimentos, Redação do manuscrito original (Relatório/README).
* **Paloma Valéria Campos de Lima:** Administração do Projeto, Desenvolvimento da lógica de controle e captura de estados temporais (`falling_edge`), Implementação e teste de hardware, Validação de dados e experimentos, Redação do manuscrito original.
