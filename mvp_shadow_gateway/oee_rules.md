# Regras de Cálculo — OEE (Base para Fase 2)

## Definições (MVP)
- **GoodCount** = peças boas acumuladas
- **ScrapCount** = peças rejeitadas acumuladas
- **RUN** = 1 quando máquina em operação (contator ativo / corrente acima do limiar / torre verde)

## Qualidade (Q)
Q = GoodCount / (GoodCount + ScrapCount)

## Disponibilidade (A) — proxy no MVP
A ≈ (tempo com RUN=1) / (tempo total observado)
> Para disponibilidade real, considerar calendário de produção (planejado x não planejado).

## Performance (P) — requer ciclo nominal (futuro)
P = (Peças produzidas / tempo de RUN) / (Taxa nominal)
> Integrar ERP/MES ou parâmetro de ciclo para cada produto.

## OEE
OEE = A × P × Q
