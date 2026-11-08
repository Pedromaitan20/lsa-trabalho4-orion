# P12 — Matriz de acesso

**Responsável:** Pedro Henrique Sá de Maria — **RM:** 559337

**Arquivos obrigatórios:** `matriz.md`

A matriz `matriz.md` mostra, para os 8 usuários e os 25 diretórios, se cada um entra (E), lista (L), lê arquivo de outra pessoa (R), cria (C) e apaga arquivo de outra pessoa (A). Ela foi escrita como contrato antes dos testes e fica dentro do próprio `testes.sh` (array MATRIZ); o arquivo md foi gerado com `bash testes.sh --matriz`, então a matriz entregue e a testada são a mesma.

Algumas células chamam atenção: a ouvidoria é `E--C-` para os colaboradores (deposita sem listar nem ler), grupos/ é `E----` (só atravessa), svc-backup é `ELR--` em todo lugar menos em backup/, e cada área individual só tem `ELRCA` para o dono e `ELR--` para o backup. As observações no fim do arquivo explicam os conflitos de regras.
