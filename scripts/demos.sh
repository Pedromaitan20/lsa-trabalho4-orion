#!/bin/bash
# =====================================================================
#  FIAP | LSA - Trabalho 4 - demos.sh
#  Gera a saída de cada evidência para tirar os prints.
#  Uso (como root):  bash demos.sh P02     (ou P06, P07, P08, P09, P10, P11, P14)
#                    bash demos.sh todas
#  Cada demonstração desfaz o que criou ao terminar.
#  Os arquivos obrigatórios (arvore.txt, getfacl.txt, suid-sgid.txt) são
#  gravados na pasta atual.
# =====================================================================
B=/srv/arquivos
[ "$(id -u)" -eq 0 ] || { echo "Execute como root."; exit 1; }

cmd(){ # mostra o prompt e executa como root
  echo; echo "root@$(hostname):~# $*"; bash -c "$*" 2>&1
}
como(){ # como USUARIO comando  -> mostra o prompt do usuário e executa
  local u="$1"; shift
  echo; echo "$u@$(hostname):~\$ $*"
  runuser -u "$u" -- bash -c "cd /; $*" 2>&1
  local rc=$?; [ $rc -ne 0 ] && echo "   -> código de saída $rc (NEGADO)"; return 0
}
titulo(){ echo; echo "#####################################################################"; echo "# $*"; echo "#####################################################################"; }

P02(){
  titulo "P02 - Árvore completa de $B (dono, grupo e permissões)"
  {
    echo "Gerado em $(date '+%F %T') no host $(hostname)"
    echo "O sinal + no fim das permissões indica que o item tem ACL (ver P09)."
    echo
    if command -v tree >/dev/null; then tree -apugf --noreport $B; echo; fi
    find $B -exec ls -ld {} + | sort -k9
    echo; echo "Modo octal:"
    find $B -exec stat -c '%a %A %U:%G %n' {} + | sort -k4
  } | tee arvore.txt
}

P06(){
  titulo "P06 - setgid: arquivos novos herdam o grupo do diretório"
  cmd "ls -ld $B/grupos/soc /tmp"
  como asouza "touch $B/grupos/soc/p06-setgid.txt /tmp/p06-sem-setgid.txt"
  cmd "ls -l $B/grupos/soc/p06-setgid.txt /tmp/p06-sem-setgid.txt"
  echo "   -> em grupos/soc (rwxrws---) o arquivo nasce com grupo soc; em /tmp (sem setgid) nasce com o grupo pessoal de asouza"
  como blima "echo 'editado pela blima' >> $B/grupos/soc/p06-setgid.txt && cat $B/grupos/soc/p06-setgid.txt"
  rm -f $B/grupos/soc/p06-setgid.txt /tmp/p06-sem-setgid.txt

  titulo "P06 - sticky bit: ninguém apaga arquivo alheio em publico/troca"
  cmd "ls -ld $B/publico/troca"
  como blima  "echo 'arquivo da blima' > $B/publico/troca/p06-blima.txt"
  como asouza "echo 'arquivo da asouza' > $B/publico/troca/p06-asouza.txt"
  cmd "ls -l $B/publico/troca"
  como asouza "rm -f $B/publico/troca/p06-blima.txt"
  como asouza "mv $B/publico/troca/p06-blima.txt $B/publico/troca/renomeado.txt"
  como asouza "rm -v $B/publico/troca/p06-asouza.txt"
  echo "   -> asouza apaga o próprio arquivo, mas não apaga nem renomeia o da blima"
  rm -f $B/publico/troca/p06-*.txt
}

P07(){
  titulo "P07 - umask 007 dos membros de orion"
  cmd "cat /etc/profile.d/orion-umask.sh"
  cmd "grep -n orion-umask /etc/bash.bashrc"
  echo; echo "root@$(hostname):~# su - asouza -c 'umask; umask -S; touch ~/p07-arq; mkdir ~/p07-dir; ls -ld ~/p07-arq ~/p07-dir'"
  su - asouza -c 'umask; umask -S; touch ~/p07-arq; mkdir ~/p07-dir; ls -ld ~/p07-arq ~/p07-dir; rm -r ~/p07-arq ~/p07-dir'
  echo "   -> arquivo 666 - 007 = 660 (rw-rw----)   diretório 777 - 007 = 770 (rwxrwx---)"
  echo; echo "root@$(hostname):~# su - svc-monitor -s /bin/bash -c umask      (conta fora de orion: umask padrão do sistema)"
  su - svc-monitor -s /bin/bash -c umask
}

P08(){
  titulo "P08 - Ouvidoria: depósito cego"
  O=$B/empresa/ouvidoria
  cmd "ls -ld $O; getfacl -p $O"
  como asouza  "echo 'Denúncia de asouza' > $O/p08-denuncia-asouza.txt && echo depositado"
  como cmendes "echo 'Sugestão de cmendes' > $O/p08-sugestao-cmendes.txt && echo depositado"
  como asouza  "ls $O"
  como cmendes "cat $O/p08-denuncia-asouza.txt"
  como cmendes "echo sobrescrevendo > $O/p08-denuncia-asouza.txt"
  como eprado  "ls -l $O && cat $O/p08-denuncia-asouza.txt"
  como drocha  "cat $O/p08-sugestao-cmendes.txt"
  como eprado  "rm -f $O/p08-denuncia-asouza.txt"
  como asouza  "rm -f $O/p08-sugestao-cmendes.txt"
  rm -f $O/p08-*.txt
}

P09(){
  titulo "P09 - ACLs (getfacl de todos os itens com ACL estendida)"
  getfacl -R -s -p $B 2>/dev/null | tee getfacl.txt
  titulo "P09 - Testes de acesso das ACLs"
  F=$B/grupos/redteam/ferramentas
  como fnunes  "$F/coleta-info.sh"
  como fnunes  "echo x >> $F/coleta-info.sh"
  como fnunes  "touch $F/p09-novo.sh"
  como asouza  "cat $B/grupos/soc/incidentes/* >/dev/null && echo 'asouza leu os incidentes'"
  como asouza  "touch $B/grupos/soc/incidentes/p09.txt"
  como drocha  "echo 'arquivo novo do drocha' > $B/publico/downloads/p09-download.txt && echo criado"
  cmd  "getfacl -p $B/publico/downloads/p09-download.txt"
  como cmendes "cat $B/publico/downloads/p09-download.txt"
  como cmendes "rm -f $B/publico/downloads/p09-download.txt"
  como asouza "echo 'segredo de asouza' > $B/individual/asouza/p09-pessoal.txt && echo criado"
  cmd  "getfacl -p $B/individual/asouza/p09-pessoal.txt"
  como svc-backup "cat $B/individual/asouza/p09-pessoal.txt"
  como svc-backup "touch $B/individual/asouza/p09-backup.txt"
  como drocha "cat $B/individual/asouza/p09-pessoal.txt"
  titulo "P09 - Máscara: chmod no grupo de um arquivo com ACL altera a máscara"
  cp -p $F/coleta-info.sh /tmp/p09-mask.sh && setfacl -m u:fnunes:rwx /tmp/p09-mask.sh
  cmd "getfacl -p /tmp/p09-mask.sh"
  cmd "chmod g=r /tmp/p09-mask.sh; getfacl -p /tmp/p09-mask.sh"
  echo "   -> a entrada user:fnunes continua rwx, mas #effective mostra r-- porque a máscara caiu para r--"
  rm -f /tmp/p09-mask.sh $B/publico/downloads/p09-download.txt $B/individual/asouza/p09-pessoal.txt
}

P10(){
  titulo "P10 - Atributos estendidos"
  P=$B/empresa/politicas/politica-seguranca.txt
  L=$B/grupos/monitoramento/metricas/alertas.log
  TAM=$(stat -c %s $L)
  cmd "lsattr $P $L"
  cmd "echo 'alteração' >> $P"
  cmd "echo 'sobrescrita' > $P"
  cmd "rm -f $P"
  cmd "mv $P /tmp/"
  cmd "chmod 777 $P"
  como drocha "echo 'alteração do drocha' >> $P"
  como svc-monitor "echo \"\$(date '+%F %T') ALERTA teste do P10\" >> $L && echo 'linha acrescentada'"
  como svc-monitor "echo 'sobrescrita' > $L"
  como svc-monitor "truncate -s 0 $L"
  cmd "echo 'sobrescrita' > $L"
  cmd "rm -f $L"
  cmd "tail -n 3 $L"
  titulo "P10 - Só removendo o atributo antes o root consegue alterar"
  cp -p $P /tmp/p10-backup.txt
  cmd "chattr -i $P && lsattr $P && echo 'linha temporária' >> $P && tail -n 1 $P"
  cmd "cp -p /tmp/p10-backup.txt $P && chattr +i $P && lsattr $P"
  rm -f /tmp/p10-backup.txt
  chattr -a $L; truncate -s $TAM $L; chattr +a $L
}

P11(){
  titulo "P11 - Inventário de SUID e SGID"
  {
    echo "Inventário de arquivos com SUID (4000) ou SGID (2000) - $(hostname) - $(date '+%F %T')"
    echo "Comando: find / -xdev -type f \\( -perm -4000 -o -perm -2000 \\) -exec ls -l {} +"
    echo
    echo "== SUID =="; find / -xdev -type f -perm -4000 -exec ls -l {} + 2>/dev/null
    echo
    echo "== SGID =="; find / -xdev -type f -perm -2000 -exec ls -l {} + 2>/dev/null
  } | tee suid-sgid.txt
  titulo "P11 - Demonstração controlada do risco de um SUID indevido"
  como asouza "echo 'Dados pessoais de asouza - confidencial' > $B/individual/asouza/p11-segredo.txt && echo criado"
  como fnunes "cat $B/individual/asouza/p11-segredo.txt"
  cmd "cp /usr/bin/cat /usr/local/bin/cat-suid && chown root:root /usr/local/bin/cat-suid && chmod 4755 /usr/local/bin/cat-suid && ls -l /usr/local/bin/cat-suid"
  como fnunes "id; /usr/local/bin/cat-suid $B/individual/asouza/p11-segredo.txt"
  echo "   -> com SUID de root, o cat roda com EUID 0 e ignora as permissões: fnunes leu o arquivo da asouza"
  cmd "rm -v /usr/local/bin/cat-suid"
  cmd "ls -l /usr/local/bin/cat-suid; find / -xdev -name 'cat-suid' 2>/dev/null | wc -l"
  como fnunes "/usr/local/bin/cat-suid $B/individual/asouza/p11-segredo.txt"
  rm -f $B/individual/asouza/p11-segredo.txt
  { echo; echo "== Demonstração (cópia /usr/local/bin/cat-suid criada, usada e REMOVIDA em $(date '+%F %T')) =="; } >> suid-sgid.txt
}

P14(){
  titulo "P14 - Testes de abuso (todos devem ser NEGADOS)"
  F=$B/grupos/redteam/ferramentas
  runuser -u blima  -- bash -c "echo 'arquivo da blima' > $B/publico/troca/p14-blima.txt"
  runuser -u asouza -- bash -c "echo 'denúncia' > $B/empresa/ouvidoria/p14-denuncia-asouza.txt"
  runuser -u asouza -- bash -c "echo 'análise' > $B/grupos/soc/p14-analise.txt"
  echo; echo "---- 1. fnunes tenta alterar um script do red team"
  como fnunes "echo 'rm -rf /' >> $F/varredura-portas.sh"
  como fnunes "sed -i 's/22/2222/' $F/varredura-portas.sh"
  echo; echo "---- 2. asouza tenta apagar arquivo da blima em publico/troca"
  como asouza "rm -f $B/publico/troca/p14-blima.txt"
  echo; echo "---- 3. cmendes tenta listar a ouvidoria e ler o depósito da asouza"
  como cmendes "ls $B/empresa/ouvidoria"
  como cmendes "cat $B/empresa/ouvidoria/p14-denuncia-asouza.txt"
  echo; echo "---- 4. svc-monitor tenta sobrescrever ou zerar alertas.log"
  como svc-monitor "echo 'apagando rastros' > $B/grupos/monitoramento/metricas/alertas.log"
  como svc-monitor "truncate -s 0 $B/grupos/monitoramento/metricas/alertas.log"
  echo; echo "---- 5. root tenta alterar politica-seguranca.txt sem remover a proteção"
  cmd "echo 'nova regra' >> $B/empresa/politicas/politica-seguranca.txt"
  echo; echo "---- 6. drocha tenta entrar em individual/asouza"
  como drocha "cd $B/individual/asouza"
  echo; echo "---- 7. svc-backup tenta criar arquivo em publico/downloads"
  como svc-backup "touch $B/publico/downloads/p14-backup.txt"
  echo; echo "---- 8. eprado tenta alterar arquivo em grupos/soc"
  como eprado "echo 'alterado pela auditoria' >> $B/grupos/soc/p14-analise.txt"
  rm -f $B/publico/troca/p14-blima.txt $B/empresa/ouvidoria/p14-denuncia-asouza.txt $B/grupos/soc/p14-analise.txt
}

case "${1:-}" in
  P02|P06|P07|P08|P09|P10|P11|P14) "$1" ;;
  todas) for p in P02 P06 P07 P08 P09 P10 P11 P14; do $p; done ;;
  *) echo "Uso: bash demos.sh {P02|P06|P07|P08|P09|P10|P11|P14|todas}"; exit 1 ;;
esac
