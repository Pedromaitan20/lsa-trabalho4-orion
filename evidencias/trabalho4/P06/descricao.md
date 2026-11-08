# P06 — Prova do setgid e do sticky bit

**Responsável:** André Gomes Uchôa — **RM:** 574396

Gerado com `bash demos.sh P06`.

Setgid: asouza cria um arquivo em `grupos/soc` (drwxrws---) e outro em `/tmp` (sem setgid). O de grupos/soc nasce com grupo `soc`; o de /tmp nasce com o grupo pessoal `asouza`. Em seguida blima, que é do soc, edita o arquivo da asouza sem nenhum chgrp/chmod — é isso que permite a colaboração.

Sticky bit: em `publico/troca` (drwxrwxrwt) blima e asouza criam arquivos. asouza consegue apagar o próprio arquivo, mas recebe “Operation not permitted” ao tentar apagar ou renomear o arquivo da blima, mesmo tendo w no diretório. Sem o sticky, qualquer usuário com w+x no diretório apagaria arquivos dos outros.

Prints: (1) demonstração do setgid; (2) demonstração do sticky bit.
