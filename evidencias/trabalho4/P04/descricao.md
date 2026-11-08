# P04 — Alterações em modo literal (simbólico)

**Responsável:** André Gomes Uchôa — **RM:** 574396

Todas as alterações foram feitas pelo `setup-orion.sh`, que imprime o ANTES e o DEPOIS de cada chmod. Foram 8 alterações em modo literal:

1. `u=rwx,go=rx` em /srv/arquivos; 2. `u=rwx,go=rx` em publico/; 3. `u=rwx,go=rx` em publico/downloads; 4. `a=rwx,+t` em publico/troca (sticky bit, bit especial); 5. `u=rwx,g=rxs,o=` em empresa/ (setgid em literal); 6. `u=rwx,g=x,o=` em individual/; 7. `chmod -R u=rwX,g=rwX,o=` em grupos/monitoramento — uso do X maiúsculo: os diretórios ganharam x e o alertas.log continuou rw-rw----; 8. `g+s` em grupos/monitoramento e metricas.

O X maiúsculo foi escolhido para mostrar que em operação recursiva ele só dá execução a diretórios (e a arquivos que já eram executáveis), sem transformar o log em executável.

Prints: trechos da seção “MODO LITERAL” da saída do setup.
