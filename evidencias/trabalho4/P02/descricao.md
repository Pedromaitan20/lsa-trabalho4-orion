# P02 — Árvore completa de /srv/arquivos

**Responsável:** Pedro Maitan de Moraes — **RM:** 574960

**Arquivos obrigatórios:** `arvore.txt`

A árvore foi gerada depois da implantação com `bash demos.sh P02`, que grava `arvore.txt` com `tree -apugf` e com `ls -ld` de todos os itens, além do modo octal (`stat -c %a`). Assim cada diretório aparece com dono, grupo e permissões nos dois formatos.

Pontos para conferir na árvore: todos os diretórios são do root, menos as 6 pastas de `individual/`, que pertencem ao respectivo usuário; o `+` no final das permissões indica ACL estendida (detalhada no P09); `publico/troca` mostra o `t` do sticky bit, `empresa/ouvidoria` mostra `s` e `T` (setgid + sticky sem execução para outros) e os diretórios de grupo mostram `rws` (setgid). Os bits do meio dos itens com ACL mostram a máscara, como explicado na tabela do P03.

Print: saída do comando `tree`/`ls` mostrando a estrutura inteira.
