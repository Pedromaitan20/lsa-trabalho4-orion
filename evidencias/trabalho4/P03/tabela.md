# P03 — Tabela de permissões

**Como ler as colunas**
- **chmod aplicado**: o modo tradicional definido com chmod (P04/P05).
- **Exibido (ls / stat)**: o que `ls -l` e `stat -c %a` mostram depois das ACLs. Quando um item tem ACL
  estendida (`+` no `ls`), os 3 bits do meio passam a mostrar a **máscara** e não mais o grupo dono. Por
  isso, por exemplo, `ouvidoria` foi criada com `3750` e aparece como `3770`: a máscara virou `rwx` por
  causa da entrada `group:orion:-wx`, mas o grupo dono (auditoria) continua `r-x`.
- **ACL**: entradas além das básicas. *(+padrão)* = a mesma entrada também existe como ACL padrão
  (default) e vale para arquivos e pastas criados no futuro.
- Em **todos** os diretórios existe `user:svc-backup:r-x` (+padrão) para o backup ler tudo; em `backup/`
  essa entrada é `rwx`. Para não repetir, ela não aparece na coluna ACL.

## Diretórios

| Caminho (`/srv/arquivos/...`) | Dono:Grupo | chmod aplicado | Exibido (ls / stat) | ACL além do svc-backup | Justificativa |
|---|---|---|---|---|---|
| `/srv/arquivos` | root:root | `rwxr-xr-x` 0755 | `rwxr-xr-x+` 755 | — | Raiz: todos precisam atravessar para chegar ao `publico/`. |
| `publico/` | root:root | `rwxr-xr-x` 0755 | `rwxr-xr-x+` 755 | — | Qualquer usuário entra e lista; só root cria. |
| `publico/downloads/` | root:root | `rwxr-xr-x` 0755 | `rwxrwxr-x+` 775 | `user:drocha:rwx` (+padrão) | Todos leem pelo “outros”. Só drocha escreve: como o diretório é do root e o grupo orion não pode ser usado (contas de serviço também leem), a única forma é ACL de usuário. |
| `publico/troca/` | root:root | `rwxrwxrwt` 1777 | `rwxrwxrwt+` 1777 | padrão: `group::r-x`, `other::r-x` | Todos criam (`o=rwx`). Sticky bit: ninguém apaga/renomeia arquivo alheio. A ACL padrão faz os arquivos novos nascerem `rw-r--r--` (todos leem, só o dono altera). |
| `empresa/` | root:orion | `rwxr-s---` 2750 | `rwxr-s---+` 2750 | — | Só orion entra e lista (grupo); outros nem listam. Setgid: o que for criado aqui fica do grupo orion. |
| `empresa/politicas/` | root:orion | `rwxr-s---` 2750 | `rwxrws---+` 2770 | `user:drocha:rwx` (+padrão) | orion lê pelo grupo (`r-x`); só drocha escreve, por ACL. |
| `empresa/comunicados/` | root:soc | `rwxrws---` 2770 | `rwxrws---+` 2770 | `group:orion:r-x` (+padrão) | Grupo dono soc publica. Setgid + ACL padrão `group::rwx`: comunicado de um analista do soc nasce do grupo soc com `rw-`, editável pelo outro sem ajuste manual. orion só lê. |
| `empresa/ouvidoria/` | root:auditoria | `rwxr-s--T` 3750 | `rwxrws--T+` 3770 | `group:orion:-wx`; padrão **sem** orion: `group::r-x`, `other::---` | Depósito cego: orion tem `w` + `x` (cria e acessa por nome) mas não `r` (não lista). Arquivos nascem do grupo auditoria (setgid) e `rw-r-----`: só o dono e a auditoria leem. Sticky: ninguém apaga depósito alheio. |
| `grupos/` | root:auditoria | `rwxr-s---` 2750 | `rwxr-s---+` 2750 | `group:orion:--x`, `group:monitoramento:--x` | orion atravessa sem listar. auditoria lista (grupo dono). `svc-monitor` não é de orion, mas precisa chegar ao `alertas.log`, por isso o grupo monitoramento também atravessa. |
| `grupos/soc/` | root:soc | `rwxrws---` 2770 | `rwxrws---+` 2770 | `group:auditoria:r-x` (+padrão) | Membros leem e escrevem; setgid + ACL padrão `group::rwx` = arquivos novos do grupo soc e editáveis pelo outro membro. Auditoria só lê. |
| `grupos/soc/incidentes/` | root:soc | `rwxrws---` 2770 | `rwxrws---+` 2770 | `user:asouza:r-x` (+padrão), `group:auditoria:r-x` (+padrão) | blima escreve pelo grupo soc. asouza também é do soc: a entrada de usuário nomeado é avaliada antes dos grupos e limita asouza a `r-x`. |
| `grupos/redteam/` | root:redteam | `rwxrws---` 2770 | `rwxrws---+` 2770 | `group:auditoria:r-x` (+padrão) | Igual a `grupos/soc/`. |
| `grupos/redteam/ferramentas/` | root:redteam | `rwxrws---` 2770 | `rwxrws---+` 2770 | `user:fnunes:r-x` (+padrão), `group:auditoria:r-x` (+padrão) | cmendes cria/altera pelo grupo; fnunes limitado a ler e executar pela ACL nomeada. |
| `grupos/auditoria/` | root:auditoria | `rwxrws---` 2770 | `rwxrws---+` 2770 | — | drocha e eprado leem e escrevem pelo grupo dono. |
| `grupos/bkpadm/` | root:bkpadm | `rwxrws---` 2770 | `rwxrws---+` 2770 | `user:svc-backup:r-x`, `group:auditoria:r-x` (+padrão) | drocha escreve pelo grupo. svc-backup é membro, mas a regra geral diz que ele só escreve em `backup/`: a ACL nomeada `r-x` vence o grupo. |
| `grupos/monitoramento/` | root:monitoramento | `rwxrws---` 2770 (`g+s` literal) | `rwxrws---+` 2770 | `group:auditoria:r-x` (+padrão) | blima e svc-monitor leem e escrevem. |
| `grupos/monitoramento/metricas/` | root:monitoramento | `rwxrws---` 2770 (`g+s` literal) | `rwxrws---+` 2770 | `group:auditoria:r-x` (+padrão) | Igual ao anterior; a proteção do log está no próprio arquivo. |
| `individual/` | root:orion | `rwx--x---` 0710 | `rwxr-x---+` 750 | padrão `group::--x` | Colaboradores só atravessam até a própria pasta; não listam quem tem pasta. (O `r-x` exibido é a máscara do svc-backup; o grupo orion continua `--x`.) |
| `individual/<usuário>/` (6) | usuário:usuário | `rwx------` 0700 | `rwxr-x---+` 750 | — (só svc-backup, +padrão) | Só o dono entra, lê e escreve. svc-backup lê por ACL (inclusive arquivos futuros, pela ACL padrão) sem mudar dono, grupo nem a entrada `group::---`. |
| `backup/` | root:bkpadm | `rwxr-s---` 2750 | `rwxrws---+` 2770 | `user:svc-backup:rwx` (+padrão) | Só svc-backup escreve (ACL nomeada vence o grupo). drocha lê pelo grupo bkpadm. Outros não entram. |

## Arquivos especiais

| Arquivo | Dono:Grupo | Modo (ls / stat) | ACL | Atributo | Justificativa |
|---|---|---|---|---|---|
| `LEIA-ME.txt` | root:root | `rw-r--r--+` 0644 | svc-backup `r--` | — | Informativo, todos leem. |
| `empresa/politicas/politica-seguranca.txt` | root:orion | `rw-rw----+` 0660 | `group::r--`, `user:drocha:rw-` | `i` (imutável) | orion lê, drocha escreveria — mas `+i` impede qualquer alteração, inclusive do root, até alguém remover o atributo. |
| `grupos/monitoramento/metricas/alertas.log` | root:monitoramento | `rw-rw----+` 0660 | `user:blima:r--`, `group:auditoria:r--` | `a` (só acréscimo) | svc-monitor escreve pelo grupo, e `+a` só permite abrir em modo append: ninguém (nem root) sobrescreve, zera ou apaga. blima também é do grupo, mas a ACL nomeada a limita a leitura. |
| `grupos/redteam/ferramentas/*.sh` (2) | cmendes:redteam | `rwxrwx---+` 0770 | `user:fnunes:r-x`, `group:auditoria:r-x` | — | Executáveis. O `chmod 0770` subiu a máscara para `rwx`, mas fnunes continua `r-x`: executa sem poder alterar. |

## Decisões de projeto (conflitos entre regras)

1. **svc-backup × grupos/bkpadm e publico/troca** — a regra geral (“só escreve em backup/”) foi tratada
   como mais forte que “membros escrevem no grupo” e “qualquer usuário cria”. A ACL `user:svc-backup:r-x`
   em todos os diretórios resolve os dois casos, porque usuário nomeado é avaliado antes de grupo e outros.
2. **Auditoria “nunca altera” × membros de grupo** — drocha e eprado leem tudo em `grupos/` pela ACL
   `group:auditoria:r-x`; só escrevem onde são membros (`grupos/auditoria`, e drocha em `grupos/bkpadm`).
3. **svc-monitor precisa atravessar `grupos/`** — não é de orion, então ganhou `group:monitoramento:--x`
   (só atravessa, não lista).
4. **ACL padrão × umask** — onde há ACL padrão, o kernel ignora a umask e usa a ACL padrão. Por isso
   `publico/troca` e `empresa/ouvidoria` têm entradas padrão de grupo/outros escritas à mão.
