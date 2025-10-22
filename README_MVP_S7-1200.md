# MVP Shadow Gateway — S7‑1200 (CPU 1214C) como Modbus/TCP Server

Guia avançado e prático para configurar seu S7‑1200 como servidor Modbus/TCP alinhado ao mapa do gateway. Foco em rapidez, estabilidade e aderência ao projeto.

## ✅ Checklist rápido (5 minutos)
1) IP da CPU: fixe para 192.168.1.121/24 (ou o IP da sua rede) e confirme ping a partir do PC do gateway.
2) Crie 4 DBs globais NÃO OTIMIZADOS (Standard/Non‑optimized):
    - DB500 HoldReg: ARRAY[1..64] OF WORD
    - DB501 InReg: ARRAY[1..32] OF WORD (reserva)
    - DB510 Coils: ARRAY[1..64] OF BOOL
    - DB520 DiscIn: ARRAY[1..64] OF BOOL (reserva)
3) OB1 — Rede 1: MB_SERVER com REQ=TRUE, ID=1 e janelas:
    - MB_HOLD_REG = P#DB500.DBX0.0 WORD 64
    - MB_INPUT_REG = P#DB501.DBX0.0 WORD 32
    - MB_COILS = P#DB510.DBX0.0 BOOL 64
    - MB_DISC_INPUTS = P#DB520.DBX0.0 BOOL 64
4) OB1 — Rede 2: chame FB200_MVP (DB200_MVP) e conecte S1, S2, RUN_RAW, AI_CUR_RAW, AI_VIB_RAW.
5) Download e Run. Teste com QModMaster: Coils 1..3 e Holding 40001..40013.

## 1) Pré‑requisitos
- TIA Portal (V13+ recomendável V15+)
- CPU S7‑1200 1214C com Ethernet
- (Opcional) SM1231 AI (analógicas dedicadas)
- Isolação de sinais (DI/AI) e fonte 24 Vdc própria

## 2) Rede e IP
- IP fixo (ex.: 192.168.1.121/24) e gateway conforme a rede. Modbus/TCP usa porta 502.
- Verifique do PC: Test‑NetConnection -ComputerName 192.168.1.121 -Port 502 (no Windows)

## 3) Projeto no TIA (passo a passo)
1. Crie o projeto e adicione CPU 1214C (versão conforme hardware).
2. Em Device & Networks, configure o IP.
3. Crie Tag Table com: DI_S1, DI_S2, DI_RUN, AI_Current_Raw, AI_Vib_Raw.
    - Exemplos típicos (ajuste aos seus endereços):
       - DI_S1 → %I0.0; DI_S2 → %I0.1; DI_RUN → %I0.2
       - AI_Current_Raw → %IW64 (4–20 mA); AI_Vib_Raw → %IW66 (0–10 V)
4. Crie os DBs globais abaixo e DESATIVE “Acesso otimizado ao bloco” (tem que ser Standard):
    - DB500 HoldReg: ARRAY[1..64] OF WORD
    - DB501 InReg: ARRAY[1..32] OF WORD
    - DB510 Coils: ARRAY[1..64] OF BOOL
    - DB520 DiscIn: ARRAY[1..64] OF BOOL
5. Adicione o FB200_MVP (SCL). O arquivo FB200_MVP.scl já está no repositório; importe/cole o conteúdo e crie DB200_MVP.

## 4) OB1 — redes e parâmetros
### Rede 1 — MB_SERVER
- Instrução MB_SERVER (Biblioteca de Comunicação). Crie DB de instância (ex.: DB100_MBServer).
- Parâmetros:
   - REQ = TRUE
   - ID = 1
   - MB_HOLD_REG = P#DB500.DBX0.0 WORD 64
   - MB_INPUT_REG = P#DB501.DBX0.0 WORD 32
   - MB_COILS = P#DB510.DBX0.0 BOOL 64
   - MB_DISC_INPUTS = P#DB520.DBX0.0 BOOL 64
> Dica: mantenha MB_SERVER como a primeira rede do OB1, sempre ativo.

> Se esses parâmetros não aparecem no seu TIA:
> - Use “Mostrar todos os parâmetros/Exibir interface completa”: clique com o botão direito no bloco MB_SERVER no OB1 e selecione a opção para exibir a interface completa (em algumas versões há um ícone de chevron/reticências “…” no cabeçalho do bloco).
> - Garanta que inseriu o MB_SERVER da biblioteca padrão da CPU (Instruções > Comunicação > Modbus > MB_SERVER para S7‑1200/1500). Evite variantes legadas de bibliotecas antigas, que têm menos pinos.
> - Em versões mais antigas/FW da CPU, alguns pinos podem ficar ocultos por padrão. Após habilitar a interface completa, os pinos MB_INPUT_REG, MB_COILS e MB_DISC_INPUTS ficam visíveis para configurar os ponteiros ANY (P#DB… COUNT).
> - Ainda não aparecem? Atualize a biblioteca/firmware da CPU no TIA. Como alternativa temporária, você pode mapear S1/S2/RUN e demais sinais em Holding Registers (WORDs/flags) e, se necessário, ajustamos o telegraf.conf para ler apenas Holding.

> Variante TIA v16 (como no seu screenshot):
> - Pinos visíveis: EN, DISCONNECT, MB_HOLD_REG, CONNECT, ENO, NDR, DR, ERROR, STATUS.
> - Use assim:
>   - CONNECT: este pino é IN_OUT (não aceita constante). Crie uma tag BOOL (ex.: `MB_Params.ConnectEnable`) com valor inicial TRUE e conecte ao pino. Opcional: garantir TRUE no start em OB100: `MB_Params.ConnectEnable := TRUE;`
>   - MB_HOLD_REG = P#DB500.DBX0.0 WORD 64
>   - Deixe MB_INPUT_REG/MB_COILS/MB_DISC_INPUTS em branco (não disponíveis nesta visualização)
> - Para Coils e Inputs indisponíveis: mapeie S1/S2/RUN em WORDs de Holding (40003..40005) com valores 0/1.
> - No gateway, use o arquivo `mvp_shadow_gateway/telegraf/telegraf.v16-holding-only.conf` que lê apenas Holding.

### Rede 2 — Lógica do MVP
- Chame o FB200_MVP com DB200_MVP.
- Conexões:
   - S1 ← DI_S1; S2 ← DI_S2; RUN_RAW ← DI_RUN
   - AI_CUR_RAW ← AI_Current_Raw; AI_VIB_RAW ← AI_Vib_Raw
- O FB já implementa: filtro RUN (TON 500 ms), contagem por borda (R_TRIG), escalas analógicas e mapeamento para DBs Modbus.

## 5) Mapa Modbus alinhado ao gateway
Coils (DB510.Coils):
- 00001 → S1 (instante)
- 00002 → S2 (instante)
- 00003 → RUN (filtrado 500 ms)

Holding (DB500.HoldReg):
- 40001 → Corrente, x10 (0..1000 ↔ 0.0..100.0)
- 40002 → Vibração, x10 (0..1000 ↔ 0.0..100.0)
- 40010/40011 → GoodCount lo/hi (UDInt em duas WORDs)
- 40012/40013 → ScrapCount lo/hi

> Mapa alternativo para TIA v16 (Holding‑only):
> - Holding (DB500.HoldReg)
>   - 40001 → Corrente x10
>   - 40002 → Vibração x10
>   - 40003 → S1_piece (0/1)
>   - 40004 → S2_scrap (0/1)
>   - 40005 → RUN (0/1 com filtro 500 ms)
>   - 40010/40011 → GoodCount lo/hi
>   - 40012/40013 → ScrapCount lo/hi

Observações práticas:
- Alguns mestres usam base 0. Se ler “deslocado”, tente iniciar em 0 em vez de 1.
- Contadores 32‑bit: no master, combine hi/lo. O gateway já faz o join 32‑bit via Telegraf.

## 6) Escalas e retentividade (recomendado)
- 4–20 mA (AI_CUR_RAW): raw típico 5530..27648 → normalize para 0..1 e multiplique por 1000 (x10).
- 0–10 V (AI_VIB_RAW): raw típico 0..27648 → normalize para 0..1 e multiplique por 1000 (x10).
- Contadores Good/Scrap: DINT/UDInt em DB retentivo (para não zerar em power‑off). Trate rollover (o join 32‑bit no gateway suporta).
- RUN com TON 500 ms evita ruído.

## 7) Download e Teste (QModMaster/Modbus Poll)
1. Compile, Download, Run.
2. Conecte no IP 192.168.1.121, porta 502, Unit ID = 1.
3. Leia:
    - Coils 00001..00003 (acionar DI_S1/DI_S2; RUN fica ON após 500 ms contínuos)
    - Holding 40001..40013 (varie analógicos e dispare S1/S2 para ver contadores)
4. Se vier tudo 0/deslocado: verifique DBs não otimizados, tamanhos e offset 0/1 do master.

## 8) Integração com o Shadow Gateway
- O arquivo `mvp_shadow_gateway/telegraf/telegraf.conf` já espera o mapa acima (coils 1..3; holdings 1,2,10..13).
- Ajuste apenas o IP do CLP no `.env` do gateway: `MB_HOST=192.168.1.121` e reinicie o Telegraf (`docker restart mvp_telegraf`).
- O gateway compõe Good/Scrap 32‑bit, calcula Quality e grava no Influx.

> Para TIA v16 Holding‑only:
> - Copie `telegraf.v16-holding-only.conf` para dentro do container (ou monte via volume) como `/etc/telegraf/telegraf.conf`.
> - Reinicie o Telegraf. Ele deixará de consumir Coils e passará a ler S1/S2/RUN das WORDs 40003..40005.

## 9) Troubleshooting rápido
- MB_SERVER não responde:
   - DBs com acesso otimizado (ERRADO) → desative (usar Standard).
   - MB_SERVER não está em REQ=TRUE ou não é chamado na primeira rede.
   - IP/porta 502 bloqueados na rede/firewall.
- Endereços “trocados”:
   - Offset do master (0‑based vs 1‑based) ou ordem hi/lo.
- Valores analógicos fora de faixa:
   - Revise limites do módulo (datasheet) e ajuste a normalização.

## 10) Boas práticas (NR‑10/NR‑12) e confiabilidade
- Isolação galvânica em DI/AI; fonte 24 Vdc própria.
- DBs retentivos para contadores; registre um heartbeat para diagnosticar resets.
- Documente bornes, fotos e laudo de comissionamento.

Recursos do projeto (repo)
- FB e DBs de exemplo: `FB200_MVP.scl`, `DB500/501/510/520.scl`
- TagTable para alinhamento: `TIA_TagTable_MVP.csv`
