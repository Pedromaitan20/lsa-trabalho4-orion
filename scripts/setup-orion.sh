#!/bin/bash
# =====================================================================
#  FIAP | LSA - Trabalho 4 - Servidor de Arquivos da Orion
#  setup-orion.sh : implanta a estrutura /srv/arquivos com permissões,
#                   bits especiais, umask, ACLs e atributos.
#
#  Uso (como root):  bash setup-orion.sh "<nome-do-grupo>" "RM1 Nome1;RM2 Nome2;..."
#  Pré-requisitos:   usuários e grupos do Trabalho 3 (Versão A) já criados
#                    pacote acl instalado (apt install acl)
#  A saída mostra o ANTES/DEPOIS de cada chmod (evidências P04 e P05):
#     bash setup-orion.sh ... | tee setup-saida.txt
#  O script pode ser executado de novo: ele remove os atributos e refaz tudo.
# =====================================================================
set -euo pipefail

GRUPO_NOME="${1:-NOME-DO-GRUPO}"
INTEGRANTES="${2:-RM000000 Nome do integrante}"
B=/srv/arquivos
HUMANOS="asouza blima cmendes drocha eprado fnunes"
GRUPOS="soc redteam auditoria bkpadm monitoramento"

[ "$(id -u)" -eq 0 ] || { echo "Execute como root."; exit 1; }
command -v setfacl >/dev/null || { echo "Instale o pacote acl: apt install acl"; exit 1; }
for u in $HUMANOS svc-backup svc-monitor; do
  id "$u" >/dev/null 2>&1 || { echo "Usuário $u não existe. Recrie o Trabalho 3 (Versão A) primeiro."; exit 1; }
done

# ---------------------------------------------------------------------
# Helpers que registram ANTES e DEPOIS de cada chmod
# ---------------------------------------------------------------------
estado(){ stat -c '%A %a %U:%G %n' "$1"; }
literal(){ # literal "<modo simbólico>" caminho [opções]
  local modo="$1"; shift
  echo "[LITERAL] chmod $* $modo"
  for p in "$@"; do [ -e "$p" ] && echo "   antes : $(estado "$p")"; done
  chmod "$modo" "$@"
  for p in "$@"; do [ -e "$p" ] && echo "   depois: $(estado "$p")"; done
}
literal_r(){ # versão recursiva (para o X maiúsculo)
  local modo="$1" alvo="$2"
  echo "[LITERAL] chmod -R $modo $alvo"
  find "$alvo" -exec stat -c '   antes : %A %a %U:%G %n' {} \;
  chmod -R "$modo" "$alvo"
  find "$alvo" -exec stat -c '   depois: %A %a %U:%G %n' {} \;
}
octal(){ # octal NNNN caminho...
  local modo="$1"; shift
  echo "[OCTAL]   chmod $modo $*"
  for p in "$@"; do echo "   antes : $(estado "$p")"; done
  chmod "$modo" "$@"
  for p in "$@"; do echo "   depois: $(estado "$p")"; done
}
secao(){ echo; echo "=================== $* ==================="; }

# ---------------------------------------------------------------------
secao "1. Grupo orion (6 colaboradores humanos)"
getent group orion >/dev/null || groupadd orion
for u in $HUMANOS; do usermod -aG orion "$u"; done
getent group orion

# ---------------------------------------------------------------------
secao "2. umask 007 permanente para os membros de orion"
cat > /etc/profile.d/orion-umask.sh <<'EOF'
# FIAP LSA T4 - membros do grupo orion trabalham com umask 007:
#   dono rwx, grupo rwx (colaboração), outros nada.
if id -nG 2>/dev/null | grep -qw orion; then
    umask 007
fi
EOF
chmod 644 /etc/profile.d/orion-umask.sh
# shells interativos que não são de login (su sem "-", terminal gráfico)
grep -q orion-umask /etc/bash.bashrc || \
  echo '[ -r /etc/profile.d/orion-umask.sh ] && . /etc/profile.d/orion-umask.sh  # LSA T4' >> /etc/bash.bashrc
cat /etc/profile.d/orion-umask.sh

# ---------------------------------------------------------------------
secao "3. Estrutura de diretórios"
# se o script já rodou antes, tira os atributos para poder refazer
[ -e $B/empresa/politicas/politica-seguranca.txt ] && chattr -i $B/empresa/politicas/politica-seguranca.txt || true
[ -e $B/grupos/monitoramento/metricas/alertas.log ] && chattr -a $B/grupos/monitoramento/metricas/alertas.log || true
[ -d $B ] && setfacl -R -b $B

mkdir -p $B/{publico/{downloads,troca},empresa/{politicas,comunicados,ouvidoria},backup}
mkdir -p $B/grupos/{soc/incidentes,redteam/ferramentas,auditoria,bkpadm,monitoramento/metricas}
for u in $HUMANOS; do mkdir -p $B/individual/$u; done

# donos: tudo root, exceto a área individual
chown root:root   $B $B/publico $B/publico/downloads $B/publico/troca
chown root:orion  $B/empresa $B/empresa/politicas $B/individual
chown root:soc    $B/empresa/comunicados
chown root:auditoria $B/empresa/ouvidoria $B/grupos
for g in $GRUPOS; do chown root:$g $B/grupos/$g; done
chown root:soc     $B/grupos/soc/incidentes
chown root:redteam $B/grupos/redteam/ferramentas
chown root:monitoramento $B/grupos/monitoramento/metricas
chown root:bkpadm  $B/backup
for u in $HUMANOS; do chown "$u:" $B/individual/$u; done   # "$u:" = grupo de login do usuário

# alertas.log já nasce aqui para o chmod -R com X maiúsculo mostrar a diferença arquivo x diretório
[ -s $B/grupos/monitoramento/metricas/alertas.log ] || \
  echo "$(date '+%F %T') INFO log de alertas criado" > $B/grupos/monitoramento/metricas/alertas.log
chown root:monitoramento $B/grupos/monitoramento/metricas/alertas.log
chmod 0644 $B/grupos/monitoramento/metricas/alertas.log

# ---------------------------------------------------------------------
secao "4. Permissões tradicionais - MODO LITERAL (P04)"
literal u=rwx,go=rx      $B                         # 1
literal u=rwx,go=rx      $B/publico                 # 2
literal u=rwx,go=rx      $B/publico/downloads       # 3
literal a=rwx,+t         $B/publico/troca           # 4 sticky bit (bit especial)
literal u=rwx,g=rxs,o=   $B/empresa                 # 5 setgid literal: arquivos/pastas novos ficam do grupo orion
literal u=rwx,g=x,o=     $B/individual              # 6
literal_r u=rwX,g=rwX,o= $B/grupos/monitoramento    # 7 X maiúsculo (recursivo)
literal g+s              $B/grupos/monitoramento $B/grupos/monitoramento/metricas  # 8 setgid literal

secao "5. Permissões tradicionais - MODO OCTAL (P05)"
octal 2750 $B/grupos                                # 1 setgid: novos itens ficam do grupo auditoria
octal 2770 $B/grupos/soc $B/grupos/redteam $B/grupos/auditoria $B/grupos/bkpadm   # 2 setgid em 4 dígitos
octal 2770 $B/grupos/soc/incidentes $B/grupos/redteam/ferramentas                # 3
octal 2750 $B/empresa/politicas                     # 4
octal 2770 $B/empresa/comunicados                   # 5
octal 3750 $B/empresa/ouvidoria                     # 6 setgid + sticky em 4 dígitos
octal 2750 $B/backup                                # 7
for u in $HUMANOS; do octal 0700 $B/individual/$u; done   # 8

# ---------------------------------------------------------------------
secao "6. ACLs (só onde o modelo tradicional não resolve)"
# 6.1 svc-backup lê TUDO (inclusive futuro) -> ACL de acesso + ACL padrão
setfacl -R    -m u:svc-backup:rX $B
find $B -type d -exec setfacl -d -m u:svc-backup:rx {} +

# 6.2 publico/downloads: só drocha escreve, sem usar grupo orion
setfacl -R -m u:drocha:rwX $B/publico/downloads
setfacl -d -m u:drocha:rwx $B/publico/downloads

# 6.3 publico/troca: arquivos novos legíveis por todos, mas só o dono altera
#     (sem isso, a ACL padrão copiaria o rwx de "outros" do diretório 1777)
setfacl -d -m u::rwx,g::rx,o::rx $B/publico/troca

# 6.4 empresa/politicas: orion lê (grupo), só drocha escreve (ACL)
setfacl -R -m u:drocha:rwX $B/empresa/politicas
setfacl -d -m u:drocha:rwx $B/empresa/politicas

# 6.5 empresa/comunicados: soc escreve (grupo + setgid), orion só lê (ACL)
setfacl -R -m g:orion:rX $B/empresa/comunicados
setfacl -d -m g:orion:rx $B/empresa/comunicados

# 6.6 empresa/ouvidoria: depósito cego
#     orion: -wx (cria, não lista)   auditoria: r-x pelo grupo dono
#     ACL padrão SEM orion -> o depósito nasce legível só pelo dono e pela auditoria
setfacl    -m g:orion:wx $B/empresa/ouvidoria
setfacl -d -m u::rwx,g::rx,o::--- $B/empresa/ouvidoria

# 6.7 grupos/: orion só atravessa; svc-monitor (fora de orion) precisa chegar ao alertas.log
setfacl -m g:orion:x,g:monitoramento:x $B/grupos

# 6.8 auditoria lê tudo dentro de grupos/ (inclusive futuro)
for g in soc redteam bkpadm monitoramento; do      # grupos/auditoria já é do grupo auditoria
  setfacl -R -m g:auditoria:rX $B/grupos/$g
  find $B/grupos/$g -type d -exec setfacl -d -m g:auditoria:rx {} +
done

# 6.9 conta de serviço svc-backup é do bkpadm, mas só pode escrever em backup/
#     (a entrada de usuário nomeado tem prioridade sobre o grupo)
setfacl -m u:svc-backup:rx $B/grupos/bkpadm

# 6.10 incidentes: blima escreve (grupo soc), asouza só lê (ACL de usuário vence o grupo)
setfacl -R -m u:asouza:rX $B/grupos/soc/incidentes
setfacl -d -m u:asouza:rx $B/grupos/soc/incidentes

# 6.11 ferramentas: cmendes escreve (grupo redteam), fnunes só lê/executa
setfacl -R -m u:fnunes:rX $B/grupos/redteam/ferramentas
setfacl -d -m u:fnunes:rx $B/grupos/redteam/ferramentas

# 6.12 backup: só svc-backup escreve, drocha (bkpadm) lê pelo grupo
setfacl -R -m u:svc-backup:rwX $B/backup
setfacl -d -m u:svc-backup:rwx $B/backup

# ---------------------------------------------------------------------
secao "7. Arquivos iniciais"
cat > $B/LEIA-ME.txt <<EOF
Servidor de Arquivos da Orion Segurança - FIAP LSA Trabalho 4
Grupo: $GRUPO_NOME
Hostname: $(hostname)
Integrantes:
$(echo "$INTEGRANTES" | tr ';' '\n' | sed 's/^ */  - /')
EOF
chown root:root $B/LEIA-ME.txt
octal 0644 $B/LEIA-ME.txt                                   # 9

cat > $B/empresa/politicas/politica-seguranca.txt <<'EOF'
POLÍTICA DE SEGURANÇA DA INFORMAÇÃO - ORION SEGURANÇA
1. Toda informação da empresa é classificada como pública, interna ou restrita.
2. Senhas são pessoais, intransferíveis e trocadas a cada 90 dias.
3. Incidentes devem ser comunicados imediatamente ao SOC.
4. O acesso a sistemas segue o princípio do menor privilégio.
EOF
chown root:orion $B/empresa/politicas/politica-seguranca.txt
octal 0640 $B/empresa/politicas/politica-seguranca.txt     # 10
# o chmod no grupo de um arquivo com ACL altera a MÁSCARA (drocha ficaria só com r--);
# o setfacl recalcula a máscara para rw- e devolve a escrita ao drocha
setfacl -m g::r,u:drocha:rw,u:svc-backup:r $B/empresa/politicas/politica-seguranca.txt

# scripts do red team criados pelo próprio cmendes (herdam grupo e ACL padrão)
runuser -u cmendes -- bash -c "cat > $B/grupos/redteam/ferramentas/varredura-portas.sh" <<'EOF'
#!/bin/bash
# Varredura simples de portas TCP em um host (uso: ./varredura-portas.sh 127.0.0.1)
alvo="${1:-127.0.0.1}"
for p in 22 80 443 3306 8080; do
  (echo > /dev/tcp/$alvo/$p) 2>/dev/null && echo "porta $p aberta" || echo "porta $p fechada"
done
EOF
runuser -u cmendes -- bash -c "cat > $B/grupos/redteam/ferramentas/coleta-info.sh" <<'EOF'
#!/bin/bash
# Coleta básica de informações do host
echo "Host: $(hostname)"; echo "Kernel: $(uname -r)"; echo "Usuário: $(id -un)"
EOF
runuser -u cmendes -- chmod 0770 $B/grupos/redteam/ferramentas/varredura-portas.sh \
                                 $B/grupos/redteam/ferramentas/coleta-info.sh
echo "[OCTAL]   chmod 0770 nos scripts (feito pelo cmendes) -> mask vira rwx, fnunes continua r-x"   # 11
ls -l $B/grupos/redteam/ferramentas

# exemplos de conteúdo criados pelos próprios usuários (herdam grupo e ACL padrão)
runuser -u blima  -- bash -c "echo 'INC-2026-001: phishing direcionado ao financeiro - em análise' > $B/grupos/soc/incidentes/INC-2026-001.txt"
runuser -u asouza -- bash -c "echo 'Comunicado SOC: janela de manutenção do SIEM no sábado, 22h' > $B/empresa/comunicados/comunicado-001.txt"
runuser -u drocha -- bash -c "echo 'Manual de acesso à VPN da Orion' > $B/publico/downloads/manual-vpn.txt"

# log de alertas: svc-monitor acrescenta (grupo monitoramento), blima só lê (ACL)
octal 0660 $B/grupos/monitoramento/metricas/alertas.log      # 12 (já estava rw-rw---- pelo X)
setfacl -m u:blima:r $B/grupos/monitoramento/metricas/alertas.log

# ---------------------------------------------------------------------
secao "8. Atributos estendidos"
chattr +i $B/empresa/politicas/politica-seguranca.txt   # imutável
chattr +a $B/grupos/monitoramento/metricas/alertas.log  # somente acréscimo
lsattr $B/empresa/politicas/politica-seguranca.txt $B/grupos/monitoramento/metricas/alertas.log

secao "9. Resultado"
find $B -exec stat -c '%A %a %U:%G %n' {} \; | sort -k4
echo; echo "Implantação concluída. Rode: bash testes.sh"
