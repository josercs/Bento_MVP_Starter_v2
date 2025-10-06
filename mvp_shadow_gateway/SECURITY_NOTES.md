# Segurança v1.1 — credenciais e superfície de rede

1) Mantenha binds apenas em 127.0.0.1 no ambiente local (compose.override já faz isso).
2) Troque credenciais padrão na primeira execução e mantenha `.env` fora do Git (.gitignore).
3) Se precisar expor externamente, use TLS e um reverse proxy (Traefik/Caddy) + basic auth.
4) Gire o token do Influx periodicamente e revogue tokens antigos via `influx auth list`.
