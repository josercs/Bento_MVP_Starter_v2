# MVP Shadow Gateway — S7‑1200 (CPU 1214C) como Modbus/TCP Server

Este guia cria, do zero, um **gateway sombra** que lê sinais não‑intrusivos e expõe **Coils/Holding Registers** via Modbus/TCP para o seu coletor.

## 1) Pré‑requisitos (mínimos)
- TIA Portal (V13+ recomendado V15+)
- CPU **S7‑1200 1214C** com porta Ethernet
- (Opcional) Módulo **SM1231 AI** (se precisar de AIs dedicadas)
- Módulos **isoladores**: DI 24V, splitter 4–20 mA, isolador 0–10 V
- Fonte 24 Vdc própria do seu painel (não use a do cliente)

## 2) Rede e IP
- Defina IP fixo da CPU (ex.: `192.168.1.121/24`), gateway conforme sua rede.
- **Modbus/TCP** usa porta `502`.

## 3) Projeto no TIA
1. **Novo Projeto** → adicione **CPU 1214C** (versão conforme hardware).
2. Em *Device & Networks*, configure o **IP**.
3. Crie **Tag Table** com seus sinais (ex.: `DI_S1`, `DI_S2`, `DI_RUN`, `AI_Current_Raw`, `AI_Vib_Raw`). Mapas típicos:
   - `DI_S1` → `%I0.0`
   - `DI_S2` → `%I0.1`
   - `DI_RUN` → `%I0.2`
   - `AI_Current_Raw` → `%IW64` (4–20 mA)
   - `AI_Vib_Raw` → `%IW66` (0–10 V)
   > Ajuste para seus endereços reais.

4. Crie os **DBs** (Global DBs com estes **nomes/arrays**):
   - `DB500` → variável `HoldReg : ARRAY[1..64] OF WORD`
   - `DB501` → variável `InReg  : ARRAY[1..32] OF WORD` *(opcional, reservado)*
   - `DB510` → variável `Coils  : ARRAY[1..64] OF BOOL`
   - `DB520` → variável `DiscIn : ARRAY[1..64] OF BOOL` *(opcional)*

5. Crie o **FB** `FB200_MVP` (linguagem **SCL**) e **cole** o conteúdo do arquivo `FB200_MVP.scl`.

## 4) OB1 — chamadas
No **OB1**, faça **duas redes** (LAD/FBD é mais simples aqui):

### Rede 1 — MB_SERVER
- Arraste o bloco **`MB_SERVER`** (biblioteca de instruções de comunicação do S7‑1200).
- Ao inserir, o TIA pedirá um **DB de instância** → crie (ex.: `DB100_MBServer`).
- Parâmetros (exemplo):
  - `REQ` = **TRUE**
  - `ID`  = **1** (Unit ID Modbus)
  - `MB_HOLD_REG`    = `P#DB500.DBX0.0 WORD 64`
  - `MB_INPUT_REG`   = `P#DB501.DBX0.0 WORD 32`
  - `MB_COILS`       = `P#DB510.DBX0.0 BOOL 64`
  - `MB_DISC_INPUTS` = `P#DB520.DBX0.0 BOOL 64`

> Dica: deixe `MB_INPUT_REG` e `MB_DISC_INPUTS` reservados para futuro (não usados no MVP).

### Rede 2 — Lógica do MVP
- Insira chamada do **`FB200_MVP`**, crie DB de instância (ex.: `DB200_MVP`).
- Conecte entradas:
  - `S1` ← `DI_S1`
  - `S2` ← `DI_S2`
  - `RUN_RAW` ← `DI_RUN`
  - `AI_CUR_RAW` ← `AI_Current_Raw`
  - `AI_VIB_RAW` ← `AI_Vib_Raw`

## 5) Mapa Modbus (MVP)
**Coils**
- 00001 → `S1` (peça, estado instantâneo)
- 00002 → `S2` (refugo, estado instantâneo)
- 00003 → `RUN` (filtrado 500 ms)

**Holding Registers**
- 40001 → Corrente, **x10** (0..1000 ↔ 0.0..100.0)
- 40002 → Vibração, **x10** (0..1000 ↔ 0.0..100.0)
- 40010 → Peças boas **lo-word**
- 40011 → Peças boas **hi-word**
- 40012 → Refugo **lo-word**
- 40013 → Refugo **hi-word**

> Ajuste escalas (4–20 mA e 0–10 V) conforme **raw** do seu módulo analógico (os valores no código usam 5530..27648 e 0..27648 como exemplo).

## 6) Download e Teste
1. Compile, **Download** para a CPU, **Run**.
2. Teste com QModMaster/Modbus Poll:
   - **Coils**: leia 00001..00003.
   - **Holding**: leia 40001..40013.
3. Acione S1/S2 e confirme a contagem/estados. Varie corrente/vibração e verifique 40001/40002.

## 7) Coletor Python (opcional, anexo)
Arquivo `collector.py` lê Modbus e imprime/publica CSV. Ajuste IP/Unit ID e rode em um PC da mesma rede.

## 8) Boas práticas (NR‑10/12)
- Tudo via **isolação galvânica** (DI, 4–20 mA e 0–10 V).
- **Não** compartilhar 0V do cliente com seu painel.
- Documente bornes, fotos e laudo de comissionamento.
