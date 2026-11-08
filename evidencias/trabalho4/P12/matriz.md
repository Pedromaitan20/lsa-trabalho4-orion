# P12 — Matriz de acesso (8 usuários × diretórios)

Esta matriz é o **contrato** que o `testes.sh` (P13) comprova. Ela fica dentro do próprio script
(array `MATRIZ`) e esta tabela foi gerada a partir dele com `bash testes.sh --matriz`, então
matriz e testes nunca ficam diferentes.

**Legenda** — cada célula tem 5 posições, nesta ordem:

| Letra | Ação | Como o script testa |
|---|---|---|
| **E** | entra no diretório | `cd <dir>` |
| **L** | lista o conteúdo | `ls <dir>` |
| **R** | lê arquivo de outra pessoa | `cat <arquivo criado pelo dono típico>` |
| **C** | cria arquivo | `touch <dir>/novo` |
| **A** | apaga arquivo de outra pessoa | `rm <arquivo criado pelo dono típico>` |

`-` na posição = **negado**. Exemplo: `E--C-` = entra e cria, mas não lista, não lê e não apaga (depósito cego).

| Diretório | asouza | blima | cmendes | drocha | eprado | fnunes | svc-backup | svc-monitor |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `/srv/arquivos/` | `ELR--` | `ELR--` | `ELR--` | `ELR--` | `ELR--` | `ELR--` | `ELR--` | `ELR--` |
| `/srv/arquivos/publico/` | `ELR--` | `ELR--` | `ELR--` | `ELR--` | `ELR--` | `ELR--` | `ELR--` | `ELR--` |
| `/srv/arquivos/publico/downloads/` | `ELR--` | `ELR--` | `ELR--` | `ELRCA` | `ELR--` | `ELR--` | `ELR--` | `ELR--` |
| `/srv/arquivos/publico/troca/` | `ELRC-` | `ELRC-` | `ELRC-` | `ELRC-` | `ELRC-` | `ELRC-` | `ELR--` | `ELRC-` |
| `/srv/arquivos/empresa/` | `ELR--` | `ELR--` | `ELR--` | `ELR--` | `ELR--` | `ELR--` | `ELR--` | `-----` |
| `/srv/arquivos/empresa/politicas/` | `ELR--` | `ELR--` | `ELR--` | `ELRCA` | `ELR--` | `ELR--` | `ELR--` | `-----` |
| `/srv/arquivos/empresa/comunicados/` | `ELRCA` | `ELRCA` | `ELR--` | `ELR--` | `ELR--` | `ELR--` | `ELR--` | `-----` |
| `/srv/arquivos/empresa/ouvidoria/` | `E--C-` | `E--C-` | `E--C-` | `ELRC-` | `ELRC-` | `E--C-` | `ELR--` | `-----` |
| `/srv/arquivos/grupos/` | `E----` | `E----` | `E----` | `ELR--` | `ELR--` | `E----` | `ELR--` | `E----` |
| `/srv/arquivos/grupos/soc/` | `ELRCA` | `ELRCA` | `-----` | `ELR--` | `ELR--` | `-----` | `ELR--` | `-----` |
| `/srv/arquivos/grupos/soc/incidentes/` | `ELR--` | `ELRCA` | `-----` | `ELR--` | `ELR--` | `-----` | `ELR--` | `-----` |
| `/srv/arquivos/grupos/redteam/` | `-----` | `-----` | `ELRCA` | `ELR--` | `ELR--` | `ELRCA` | `ELR--` | `-----` |
| `/srv/arquivos/grupos/redteam/ferramentas/` | `-----` | `-----` | `ELRCA` | `ELR--` | `ELR--` | `ELR--` | `ELR--` | `-----` |
| `/srv/arquivos/grupos/auditoria/` | `-----` | `-----` | `-----` | `ELRCA` | `ELRCA` | `-----` | `ELR--` | `-----` |
| `/srv/arquivos/grupos/bkpadm/` | `-----` | `-----` | `-----` | `ELRCA` | `ELR--` | `-----` | `ELR--` | `-----` |
| `/srv/arquivos/grupos/monitoramento/` | `-----` | `ELRCA` | `-----` | `ELR--` | `ELR--` | `-----` | `ELR--` | `ELRCA` |
| `/srv/arquivos/grupos/monitoramento/metricas/` | `-----` | `ELRCA` | `-----` | `ELR--` | `ELR--` | `-----` | `ELR--` | `ELRCA` |
| `/srv/arquivos/individual/` | `E----` | `E----` | `E----` | `E----` | `E----` | `E----` | `ELR--` | `-----` |
| `/srv/arquivos/individual/asouza/` | `ELRCA` | `-----` | `-----` | `-----` | `-----` | `-----` | `ELR--` | `-----` |
| `/srv/arquivos/individual/blima/` | `-----` | `ELRCA` | `-----` | `-----` | `-----` | `-----` | `ELR--` | `-----` |
| `/srv/arquivos/individual/cmendes/` | `-----` | `-----` | `ELRCA` | `-----` | `-----` | `-----` | `ELR--` | `-----` |
| `/srv/arquivos/individual/drocha/` | `-----` | `-----` | `-----` | `ELRCA` | `-----` | `-----` | `ELR--` | `-----` |
| `/srv/arquivos/individual/eprado/` | `-----` | `-----` | `-----` | `-----` | `ELRCA` | `-----` | `ELR--` | `-----` |
| `/srv/arquivos/individual/fnunes/` | `-----` | `-----` | `-----` | `-----` | `-----` | `ELRCA` | `ELR--` | `-----` |
| `/srv/arquivos/backup/` | `-----` | `-----` | `-----` | `ELR--` | `-----` | `-----` | `ELRCA` | `-----` |

## Observações

- **Arquivo de outra pessoa**: o script cria os arquivos de teste com o usuário que normalmente escreve
  no diretório (“dono típico”, coluna 2 do array `MATRIZ`). Se o testador for o próprio dono típico, ele
  usa o arquivo de um segundo usuário. Na área individual, só o dono escreve, então ali os arquivos
  de teste são do próprio dono.
- **publico/troca**: todos criam, ninguém apaga arquivo alheio (sticky bit). `svc-backup` não cria
  porque só pode escrever em `backup/` (regra geral 5.1, ACL `user:svc-backup:r-x` vence o “outros” rwx).
- **empresa/ouvidoria**: `E--C-` para os colaboradores (depósito cego); `drocha` e `eprado` listam e
  leem porque são da auditoria, mas também não apagam (sticky bit).
- **grupos/**: os colaboradores só atravessam (`E----`); `svc-monitor` também atravessa (precisa
  chegar ao `alertas.log`), mas não lista.
- **grupos/bkpadm**: `svc-backup` é membro do bkpadm, mas aqui só lê — conflito resolvido a favor da
  regra geral “svc-backup só escreve em backup/”.
- **auditoria** (`drocha`, `eprado`) lê tudo em `grupos/` e nunca altera; o `drocha` escreve em
  `grupos/bkpadm` e ambos em `grupos/auditoria` porque são membros desses grupos.
- Regras que não cabem nas 5 colunas (alterar, executar, acrescentar, imutável) são testadas na
  parte 2 do `testes.sh`.
