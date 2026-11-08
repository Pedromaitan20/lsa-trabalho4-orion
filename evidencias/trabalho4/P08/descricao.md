# P08 — Ouvidoria: depósito cego

**Responsável:** Thiago Carvalho da Silveira Abbade — **RM:** 575722

Gerado com `bash demos.sh P08`. A ouvidoria é `root:auditoria` com setgid e sticky (drwxrws--T) e ACL `group:orion:-wx`.

1. asouza e cmendes depositam arquivos (w + x permitem criar). 2. asouza tenta `ls` e recebe Permission denied (orion não tem r). 3. cmendes tenta ler e sobrescrever o depósito da asouza sabendo o nome exato e é negado, porque o arquivo nasce rw-r----- do grupo auditoria (setgid + ACL padrão sem orion). 4. eprado e drocha (auditoria) listam e leem todos os depósitos. 5. eprado tenta apagar o depósito da asouza e asouza tenta apagar o do cmendes: os dois são bloqueados pelo sticky bit.

Prints: (1) depósito e tentativas negadas do colaborador; (2) auditoria listando e lendo; (3) tentativas de apagar negadas.
