# Trabalho 4 — Servidor de Arquivos da Orion: passo a passo

Tudo foi testado em uma VM Linux com os mesmos usuários e grupos do Trabalho 3: **1050 testes, 100% de acertos**.
Os prints e os arquivos `.txt` precisam sair da **VM do grupo** (o enunciado invalida imagens falsas).

## Conteúdo do pacote

```
scripts/
  setup-orion.sh   implanta toda a estrutura (diretórios, chmod, SGID/sticky, umask, ACLs, chattr)
  testes.sh        P13: 1050 testes (matriz completa + regras específicas + abuso)
  demos.sh         gera a saída de P02, P06, P07, P08, P09, P10, P11 e P14 para os prints
evidencias/trabalho4/
  P01 … P15/descricao.md   texto de cada evidência (≥300 caracteres) — preencher NOME e RM
  P03/tabela.md            tabela de permissões
  P12/matriz.md            matriz de acesso
  P13/testes.sh            script de testes
  P15/respostas.md         respostas das 10 perguntas
```

## 1. Preparar a VM (Debian)

```bash
# snapshot da VM ANTES de tudo (o mesmo snapshot é a base do Trabalho 5)
sudo hostnamectl set-hostname lsa-<nome-do-grupo>
sudo apt update && sudo apt install -y acl tree
# recrie a Versão A do Trabalho 3 e rode o script de verificação -> print do P01
# copie a pasta scripts/ para a VM (scp, pasta compartilhada ou git clone do repositório)
```

## 2. Implantar

```bash
sudo bash setup-orion.sh "<nome-do-grupo>" "RM111111 Nome 1;RM222222 Nome 2;RM333333 Nome 3" | tee setup-saida.txt
getent group orion; for u in asouza blima cmendes drocha eprado fnunes; do id $u; done   # P01
```
A saída do setup tem as seções **MODO LITERAL** (print do P04) e **MODO OCTAL** (print do P05), com antes e depois.

## 3. Testes e demonstrações (cada um gera o print da evidência)

```bash
sudo bash testes.sh | tee saida-testes.txt     # P13 (print do final com 100%)
sudo bash demos.sh P02    # gera arvore.txt
sudo bash demos.sh P06
sudo bash demos.sh P07
sudo bash demos.sh P08
sudo bash demos.sh P09    # gera getfacl.txt
sudo bash demos.sh P10
sudo bash demos.sh P11    # gera suid-sgid.txt
sudo bash demos.sh P14
```
Rode cada `demos.sh` separado e tire os prints na hora (o enunciado pede no mínimo: P01 2, P02 1, P04 2, P05 2,
P06 2, P07 2, P08 3, P09 3, P10 2, P11 2, P13 1, P14 4). Todas as demos desfazem o que criam.

## 4. Repositório

1. Criar o repositório a partir do modelo do professor (privado), adicionar colegas e professor.
2. Preencher `grupo.json` (nome do grupo, hostname, integrantes com nome, RM, GitHub e função).
3. Copiar os arquivos de `evidencias/trabalho4/` para as pastas correspondentes e colocar os prints e os
   `.txt` gerados na VM (`verificacao.txt`, `arvore.txt`, `getfacl.txt`, `suid-sgid.txt`, `saida-testes.txt`).
4. Em cada `descricao.md`, trocar “NOME DO INTEGRANTE / RM” pelo responsável. **Cada integrante precisa
   ser responsável por pelo menos 3 evidências e fazer os próprios commits.** Sugestão para 5 pessoas:
   - Coordenador: P01, P02, P03
   - Administrador de permissões: P04, P05, P06
   - Analista de testes: P12, P13, P14
   - Responsável pelo boot: P07, P09, P10
   - Sabotador: P08, P11, P15
5. Releiam e ajustem os textos com as palavras do grupo — a regra exige texto escrito pelo grupo.

## Se algo falhar no testes.sh

A linha com `FALHOU` diz usuário, ação, caminho, esperado e obtido. As causas mais comuns:
- usuário fora de algum grupo do Trabalho 3 (`id <usuário>`);
- pacote `acl` não instalado ou partição sem suporte a ACL;
- o setup foi rodado por cima de uma estrutura antiga — volte o snapshot e rode de novo.
