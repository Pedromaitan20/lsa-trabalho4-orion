# P01 — Hostname da VM, verificação do Trabalho 3 (Versão A) e grupo orion

**Responsável:** Pedro Maitan de Moraes — **RM:** 574960

**Arquivos obrigatórios:** `verificacao.txt`

A VM do grupo se chama `lsa-rm574960` (Debian 13). Antes de qualquer alteração foi criado o snapshot `antes-trabalho4`, base também do Trabalho 5. Recriamos o estado da Versão A do Trabalho 3: os grupos soc, redteam, auditoria, bkpadm e monitoramento, os 6 colaboradores com seus grupos funcionais, blima como administradora do grupo soc (`gpasswd -A`) e as contas de serviço svc-backup e svc-monitor como contas de sistema com shell `/usr/sbin/nologin`.

Em seguida criamos o grupo `orion` (`groupadd orion`) e adicionamos apenas os 6 colaboradores humanos com `usermod -aG orion`. As contas de serviço ficaram de fora de propósito, porque o grupo identifica funcionários da empresa e é usado nas regras da área empresarial. O arquivo `verificacao.txt` traz o hostname, a linha do grupo orion e o `id` dos 8 usuários.

Prints: (1) `hostnamectl` + `getent group` de orion e dos grupos do Trabalho 3; (2) `id` dos 8 usuários.
