# P13 — Script de testes automatizado

**Responsável:** Pedro Henrique Sá de Maria — **RM:** 559337

**Arquivos obrigatórios:** `testes.sh, saida-testes.txt`

O `testes.sh` roda como root e executa cada teste como o usuário certo com `runuser -u <usuário>`. A parte 1 percorre a matriz inteira: 8 usuários × 25 diretórios × 5 ações (entrar, listar, ler, criar, apagar). A parte 2 testa regras que não cabem na matriz: edição colaborativa no soc e nos comunicados, herança de grupo pelo setgid, fnunes executando mas não alterando scripts, svc-monitor só acrescentando no log, imutabilidade da política. A parte 3 repete os 8 testes de abuso.

Cada linha mostra número, usuário, ação, caminho, resultado esperado, resultado obtido e PASSOU/FALHOU; no final aparece o total e a porcentagem (100%). Os arquivos de teste são criados pelos próprios usuários para herdarem setgid e ACL padrão, e um trap remove tudo no final, inclusive a linha acrescentada no alertas.log.

Print: final da execução com o total e 100%.
