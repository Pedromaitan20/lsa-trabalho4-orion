# P07 — umask dos membros de orion

**Responsável:** André Gomes Uchôa — **RM:** 574396

A umask foi configurada no arquivo `/etc/profile.d/orion-umask.sh`, que todo shell de login lê (via /etc/profile). Ele testa se o usuário pertence ao grupo orion (`id -nG | grep -qw orion`) e, nesse caso, aplica `umask 007`. Também incluímos uma linha no `/etc/bash.bashrc` para valer em shells interativos que não são de login. A configuração é permanente e vale só para os membros de orion; as contas de serviço continuam com a umask padrão do sistema.

Escolhemos 007 porque mantém tudo para o dono e para o grupo (colaboração) e retira tudo de outros: arquivo 666 − 007 = 660 (rw-rw----) e diretório 777 − 007 = 770 (rwxrwx---). Gerado com `bash demos.sh P07`.

Prints: (1) conteúdo do arquivo de configuração; (2) `su - asouza` mostrando a umask e o arquivo/diretório recém-criados.
