# P11 — Auditoria de SUID/SGID e demonstração do risco

**Responsável:** Thiago Carvalho da Silveira Abbade — **RM:** 575722

**Arquivos obrigatórios:** `suid-sgid.txt`

O inventário foi gerado com `find / -xdev -type f \( -perm -4000 -o -perm -2000 \)` e está em `suid-sgid.txt`.

Análise de 3 binários: `/usr/bin/passwd` (SUID root) precisa gravar o hash da nova senha em /etc/shadow, que só o root pode alterar; `/usr/bin/su` (SUID root) precisa trocar a identidade do processo (setuid) para outro usuário depois de validar a senha; `/usr/sbin/unix_chkpwd` (SGID shadow) só precisa LER /etc/shadow para o PAM validar senhas, então usa SGID do grupo shadow em vez de SUID root (menor privilégio).

Demonstração controlada: copiamos /usr/bin/cat para /usr/local/bin/cat-suid e aplicamos 4755. Com o cat normal, fnunes não lê o arquivo pessoal da asouza; com a cópia SUID, lê, porque o processo roda com EUID 0. A cópia foi apagada logo em seguida e provamos que ela não existe mais. Não usamos /etc/shadow para não expor hashes de senha.

Prints: (1) inventário; (2) demonstração e remoção.
