# P14 — Testes de abuso

**Responsável:** Pedro Henrique Sá de Maria — **RM:** 559337

Executamos manualmente os 8 cenários com `bash demos.sh P14`, que mostra o comando, o usuário e a mensagem de erro de cada tentativa:

1. fnunes tenta alterar varredura-portas.sh (com >> e com sed -i) — Permission denied (ACL user:fnunes:r-x). 2. asouza tenta apagar arquivo da blima em publico/troca — Operation not permitted (sticky). 3. cmendes tenta listar a ouvidoria e ler o depósito da asouza — Permission denied (orion tem só -wx; arquivo rw-r----- da auditoria). 4. svc-monitor tenta sobrescrever e zerar alertas.log — Operation not permitted (atributo a). 5. root tenta alterar politica-seguranca.txt — Operation not permitted (atributo i). 6. drocha tenta entrar em individual/asouza — Permission denied (0700). 7. svc-backup tenta criar em publico/downloads — Permission denied. 8. eprado tenta alterar arquivo em grupos/soc — Permission denied (auditoria só r-x).

Prints: 4 capturas cobrindo os 8 cenários.
