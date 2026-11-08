# P15 — Respostas às perguntas

> Todos os exemplos foram executados na VM do grupo, na estrutura `/srv/arquivos`.

## 1. Qual a diferença entre `x` e `X` no chmod e por que o `X` é útil em operações recursivas?

`x` dá permissão de execução para **todo** item atingido, seja arquivo ou diretório. `X` (maiúsculo) só
dá execução se o item for **diretório** ou se for um arquivo que **já tem execução** para alguém.

Em um `chmod -R` isso evita transformar documentos e logs em “executáveis” só porque os diretórios
precisavam de `x` para serem atravessados. Na nossa VM:

```
# chmod -R u=rwX,g=rwX,o= /srv/arquivos/grupos/monitoramento
drwxrwx--- grupos/monitoramento                     <- diretório: ganhou x
drwxrwx--- grupos/monitoramento/metricas            <- diretório: ganhou x
-rw-rw---- grupos/monitoramento/metricas/alertas.log <- arquivo de texto: NÃO ganhou x
```

Com `u=rwx,g=rwx` o `alertas.log` viraria `rwxrwx---`, o que não faz sentido para um log. Também usamos
`X` nas ACLs (`setfacl -R -m u:svc-backup:rX`): o backup atravessa os diretórios e só “executa” os scripts
que já eram executáveis.

## 2. O que cada bit (r, w, x) permite em um diretório? Use a ouvidoria para explicar.

Um diretório é uma lista de nomes → inodes.

| Bit | Em diretório permite |
|---|---|
| `r` | ler a lista de nomes (`ls`) |
| `w` | alterar a lista: criar, apagar e renomear entradas — **só funciona junto com `x`** |
| `x` | atravessar o diretório e acessar um item **pelo nome** (`cd`, abrir arquivo, `stat`) |

A ouvidoria (`drwxrws--T+ root:auditoria`) usa isso para o depósito cego:

```
group:orion:-wx     -> colaborador cria arquivo (w+x) e acessa pelo nome (x), mas não lista (sem r)
group::r-x          -> auditoria (grupo dono) lista e lê
other::---          -> quem não é de orion nem entra
sticky (T)          -> ninguém apaga ou renomeia depósito alheio
```

Mesmo sabendo o nome exato, `cmendes` não lê o depósito de `asouza`, porque o `x` do diretório só o deixa
chegar ao arquivo, e o **arquivo** nasce `rw-r-----` com grupo auditoria (setgid + ACL padrão sem orion):

```
cmendes$ ls /srv/arquivos/empresa/ouvidoria
ls: cannot open directory '/srv/arquivos/empresa/ouvidoria': Permission denied
cmendes$ cat /srv/arquivos/empresa/ouvidoria/denuncia-asouza.txt
cat: ...: Permission denied
eprado$ ls -l /srv/arquivos/empresa/ouvidoria
-rw-r-----+ 1 asouza  auditoria 29 ... denuncia-asouza.txt
-rw-r-----+ 1 cmendes auditoria 21 ... sugestao-cmendes.txt
```

## 3. Efeito do sticky bit e diferença entre `t` e `T`

Em um diretório com sticky bit, mesmo quem tem `w` no diretório só pode apagar ou renomear um arquivo se
for o **dono do arquivo**, o **dono do diretório** ou o root. Sem o sticky, qualquer um com `w`+`x` no
diretório apaga arquivos dos outros.

O sticky aparece na posição de execução de “outros”:
- `t` minúsculo = sticky **e** outros têm `x` → `publico/troca` = `drwxrwxrwt` (1777)
- `T` maiúsculo = sticky **sem** `x` para outros → `empresa/ouvidoria` = `drwxrws--T` (3770)

```
asouza$ rm -f /srv/arquivos/publico/troca/arquivo-da-blima.txt
rm: cannot remove '...arquivo-da-blima.txt': Operation not permitted
```

## 4. Como o SGID em diretório e a umask trabalham juntos? O que acontece se faltar cada um?

- **SGID no diretório** (`rwxrws---`) faz todo arquivo criado ali nascer com o **grupo do diretório** (e
  subdiretórios herdam o próprio SGID).
- **umask 007** faz o grupo receber `rw` (arquivo 660, diretório 770) e outros nada.

Juntos: `asouza` cria um arquivo em `grupos/soc` → ele fica `asouza:soc rw-rw----` → `blima`, do soc,
edita sem ninguém precisar rodar `chgrp`/`chmod`.

- **Sem SGID**: o arquivo nasce com o grupo primário de quem criou (`asouza:asouza`). blima não está
  nesse grupo, cai em “outros” (`---`) e não consegue nem ler. Prova da VM:
  ```
  -rw-rw----+ 1 asouza soc    0 ... /srv/arquivos/grupos/soc/p06-setgid.txt   (com setgid)
  -rw-rw----  1 asouza asouza 0 ... /tmp/p06-sem-setgid.txt                   (sem setgid)
  ```
- **Sem a umask 007** (com a 022 padrão): o arquivo nasceria `rw-r--r--` — o grupo certo, mas só com
  leitura, e ainda legível por “outros”.

Observação da nossa estrutura: nos diretórios que têm **ACL padrão**, o kernel ignora a umask e usa a ACL
padrão (`default:group::rwx` → arquivo com grupo `rw-`). Por isso, dentro de `/srv/arquivos`, a dupla
“SGID + ACL padrão” é quem garante a colaboração; a umask 007 garante o mesmo comportamento em qualquer
outro lugar (home, `/tmp`, pastas sem ACL).

## 5. Cálculo das permissões finais com a umask definida (007)

A umask **remove** bits do modo pedido pelo programa (arquivos: 666; diretórios: 777):

```
Arquivo:    666  = 110 110 110        Diretório:  777  = 111 111 111
umask 007 → ~007 = 111 111 000        ~007             = 111 111 000
AND         660  = 110 110 000        AND         770  = 111 111 000
            rw-rw----                             rwxrwx---
```

Prova da VM (P07):
```
# su - asouza -c 'umask; touch ~/p07-arq; mkdir ~/p07-dir; ls -ld ~/p07-arq ~/p07-dir'
0007
-rw-rw---- 1 asouza asouza    0 ... /home/asouza/p07-arq
drwxrwx--- 2 asouza asouza 4096 ... /home/asouza/p07-dir
```

## 6. Ordem de avaliação de uma ACL, papel da máscara e efeito do chmod no grupo

O kernel para na **primeira classe** que combina com o processo:

1. **`user::`** — se o processo é o dono do arquivo, usa essa entrada e para.
2. **`user:<nome>:`** — se existe entrada para aquele usuário, usa (limitada pela máscara) e para.
3. **Grupos** — `group::` (grupo dono) e `group:<nome>:`. Se o processo está em um ou mais desses grupos,
   o acesso é concedido se **alguma** dessas entradas (limitada pela máscara) tiver tudo o que foi pedido;
   se nenhuma tiver, é **negado** (não passa para “outros”).
4. **`other::`** — só se nenhuma das anteriores combinou.

A **máscara** (`mask::`) é o teto das permissões para usuários nomeados, grupo dono e grupos nomeados (não
afeta `user::` nem `other::`). O `getfacl` mostra `#effective:` quando a máscara corta algo.

Quando o arquivo tem ACL, os bits de grupo do `chmod` passam a ser a **máscara**. Então `chmod g=...` não
mexe no `group::`, mexe na máscara — e pode cortar, sem aviso, permissões de usuários nomeados. Prova (P09):

```
# chmod g=r /tmp/p09-mask.sh ; getfacl /tmp/p09-mask.sh
user:fnunes:rwx        #effective:r--
group::rwx             #effective:r--
mask::r--
```

Isso aconteceu no nosso projeto com a `politica-seguranca.txt`: o `chmod 0640` derrubou a máscara para
`r--` e o drocha perdeu a escrita; um `setfacl -m` depois recalculou a máscara para `rw-`.

## 7. Por que a ACL de fnunes prevalece sobre as permissões do grupo redteam?

Porque a entrada **`user:fnunes:r-x`** é da classe “usuário nomeado”, que é avaliada **antes** das
entradas de grupo. Quando ela combina, a avaliação termina e o `group::rwx` do redteam nem é consultado.

```
# getfacl /srv/arquivos/grupos/redteam/ferramentas/varredura-portas.sh
# owner: cmendes
# group: redteam
user::rwx
user:fnunes:r-x
group::rwx
mask::rwx
fnunes$ echo x >> varredura-portas.sh   -> Permission denied
fnunes$ ./coleta-info.sh                -> executa normalmente
```

A máscara é `rwx`, então ela não é o motivo da restrição: é a ordem de avaliação.

## 8. Para apagar um arquivo importa a permissão do arquivo ou a do diretório?

A do **diretório**. Apagar é remover um nome da lista do diretório, então é preciso `w` + `x` no
diretório. As permissões do arquivo não importam (exceções: sticky bit no diretório e atributos `i`/`a`
no arquivo).

```
# como drocha (tem w no diretório pela ACL), arquivo SEM nenhuma permissão:
drocha$ echo teste > /srv/arquivos/publico/downloads/p8.txt
drocha$ chmod 000 /srv/arquivos/publico/downloads/p8.txt
drocha$ ls -l /srv/arquivos/publico/downloads/p8.txt
----------+ 1 drocha drocha 6 ... p8.txt
drocha$ rm -f /srv/arquivos/publico/downloads/p8.txt && echo apagado
apagado

# como cmendes, arquivo que ele consegue LER, mas sem w no diretório:
cmendes$ rm -f /srv/arquivos/publico/downloads/manual-vpn.txt
rm: cannot remove '...manual-vpn.txt': Permission denied
```

## 9. Se o root não altera um arquivo imutável, por que isso não protege contra quem já tem root? Defesas complementares

O `chattr +i` só bloqueia alteração enquanto o atributo existe. O próprio root (que tem a capacidade
`CAP_LINUX_IMMUTABLE`) pode rodar `chattr -i`, alterar o arquivo e rodar `chattr +i` de novo. É uma proteção
contra **erro** e contra processos/usuários sem essa capacidade, não contra um atacante com root:

```
# echo x >> politica-seguranca.txt  -> Operation not permitted
# chattr -i politica-seguranca.txt && echo x >> politica-seguranca.txt   -> funciona
```

Defesas complementares:
- **Auditoria**: `auditd` com regras para `chattr` e escrita em `empresa/politicas/` (gera rastro).
- **Integridade**: AIDE/Tripwire comparando hashes com uma base guardada fora da máquina.
- **Logs fora do host**: syslog remoto/SIEM, para o atacante não apagar o rastro localmente.
- **Backups imutáveis/offline** para recuperar o arquivo.
- **Controle de acesso obrigatório** (SELinux/AppArmor) e retirar `CAP_LINUX_IMMUTABLE` do bounding set
  depois do boot, para nem o root conseguir remover o atributo sem reiniciar.
- **Reduzir quem vira root**: sudo com menor privilégio, MFA, sem login direto de root por SSH.

## 10. Por que o Linux ignora o SUID em scripts? O que faz `nosuid` e onde usar nesta estrutura?

Um script não é executado diretamente: o kernel lê o `#!` e roda o interpretador passando o **caminho** do
script. Entre o kernel checar o arquivo e o interpretador abri-lo existe uma janela de tempo (condição de
corrida / TOCTOU): o atacante troca o script (por exemplo, com um link simbólico) e o interpretador executa
como root um código que não é o original. Além disso, o interpretador herda variáveis de ambiente (`PATH`,
`IFS`, `BASH_ENV`, `LD_*`) que o usuário controla. Por isso o Linux ignora SUID/SGID em scripts e só os
respeita em binários.

A opção de montagem **`nosuid`** faz o kernel ignorar os bits SUID e SGID (e as file capabilities) de
todos os arquivos daquele sistema de arquivos. Mesmo que alguém consiga criar um binário SUID ali, ele roda
com a identidade de quem executou.

Na nossa estrutura, o ideal é `/srv/arquivos` ficar em uma partição própria montada com `nosuid,nodev`
(recomendação do CIS para áreas de dados). Os pontos mais críticos são `publico/troca` (qualquer usuário
grava) e `grupos/redteam/ferramentas` (scripts e ferramentas ofensivas). `noexec` também serviria para
`publico/` e `individual/`, mas não para `ferramentas`, onde os scripts precisam ser executados.

```
# /etc/fstab (exemplo)
/dev/sdb1  /srv/arquivos  ext4  defaults,nosuid,nodev  0 2
```
