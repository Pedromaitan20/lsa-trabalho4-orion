# P05 — Alterações em modo octal

**Responsável:** André Gomes Uchôa — **RM:** 574396

As alterações em modo octal também foram feitas pelo `setup-orion.sh`, com ANTES e DEPOIS impressos:

1. `2750` em grupos/ (setgid); 2. `2770` em grupos/soc, redteam, auditoria e bkpadm (setgid em 4 dígitos); 3. `2770` em incidentes e ferramentas; 4. `2750` em empresa/politicas; 5. `2770` em empresa/comunicados; 6. `3750` em empresa/ouvidoria (setgid + sticky em 4 dígitos); 7. `2750` em backup/; 8. `0700` em cada pasta individual; 9. `0644` no LEIA-ME.txt; 10. `0640` na politica-seguranca.txt; 11. `0770` nos scripts do red team (feito pelo cmendes); 12. `0660` no alertas.log.

O primeiro dígito do modo de 4 dígitos é a soma dos bits especiais: 4 = SUID, 2 = SGID, 1 = sticky. Por isso 3750 = SGID (2) + sticky (1) com rwxr-x---.

Prints: trechos da seção “MODO OCTAL” da saída do setup.
