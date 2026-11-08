#!/bin/bash
# =====================================================================
#  FIAP | LSA - Trabalho 4 - testes.sh (evidência P13)
#  Executa, como root, cada teste COMO o usuário correspondente
#  (runuser) e compara com a matriz de acesso (P12).
#
#  Uso:  bash testes.sh                 -> roda todos os testes
#        bash testes.sh --matriz        -> imprime a matriz em Markdown
#        bash testes.sh | tee saida-testes.txt
#
#  Tudo o que o script cria, ele remove no final (trap EXIT), inclusive
#  a linha que o svc-monitor acrescenta no alertas.log.
# =====================================================================
B=/srv/arquivos
USUARIOS=(asouza blima cmendes drocha eprado fnunes svc-backup svc-monitor)
ACOES=(entrar listar ler criar apagar)
LETRAS=(E L R C A)

# ---------------------------------------------------------------------
# MATRIZ DE ACESSO (contrato)  -  uma linha por diretório
# formato: caminho | dono-típico | dono-alternativo | 8 células na ordem de USUARIOS
# célula: E=entra L=lista R=lê arquivo alheio C=cria A=apaga arquivo alheio  (- = negado)
# "dono-típico" cria os arquivos usados nos testes de leitura e de apagar;
# quando o próprio testador é o dono típico, usa-se o arquivo do dono alternativo.
# Na área individual só o dono escreve, então os dois arquivos de teste são dele mesmo.
# ---------------------------------------------------------------------
MATRIZ=(
"                                 |root       |root    |ELR-- ELR-- ELR-- ELR-- ELR-- ELR-- ELR-- ELR--"
"publico                          |root       |root    |ELR-- ELR-- ELR-- ELR-- ELR-- ELR-- ELR-- ELR--"
"publico/downloads                |drocha     |root    |ELR-- ELR-- ELR-- ELRCA ELR-- ELR-- ELR-- ELR--"
"publico/troca                    |blima      |asouza  |ELRC- ELRC- ELRC- ELRC- ELRC- ELRC- ELR-- ELRC-"
"empresa                          |root       |root    |ELR-- ELR-- ELR-- ELR-- ELR-- ELR-- ELR-- -----"
"empresa/politicas                |drocha     |root    |ELR-- ELR-- ELR-- ELRCA ELR-- ELR-- ELR-- -----"
"empresa/comunicados              |asouza     |blima   |ELRCA ELRCA ELR-- ELR-- ELR-- ELR-- ELR-- -----"
"empresa/ouvidoria                |asouza     |cmendes |E--C- E--C- E--C- ELRC- ELRC- E--C- ELR-- -----"
"grupos                           |root       |root    |E---- E---- E---- ELR-- ELR-- E---- ELR-- E----"
"grupos/soc                       |asouza     |blima   |ELRCA ELRCA ----- ELR-- ELR-- ----- ELR-- -----"
"grupos/soc/incidentes            |blima      |root    |ELR-- ELRCA ----- ELR-- ELR-- ----- ELR-- -----"
"grupos/redteam                   |cmendes    |fnunes  |----- ----- ELRCA ELR-- ELR-- ELRCA ELR-- -----"
"grupos/redteam/ferramentas       |cmendes    |root    |----- ----- ELRCA ELR-- ELR-- ELR-- ELR-- -----"
"grupos/auditoria                 |eprado     |drocha  |----- ----- ----- ELRCA ELRCA ----- ELR-- -----"
"grupos/bkpadm                    |drocha     |root    |----- ----- ----- ELRCA ELR-- ----- ELR-- -----"
"grupos/monitoramento             |blima      |svc-monitor|----- ELRCA ----- ELR-- ELR-- ----- ELR-- ELRCA"
"grupos/monitoramento/metricas    |svc-monitor|blima   |----- ELRCA ----- ELR-- ELR-- ----- ELR-- ELRCA"
"individual                       |root       |root    |E---- E---- E---- E---- E---- E---- ELR-- -----"
"individual/asouza                |asouza     |asouza  |ELRCA ----- ----- ----- ----- ----- ELR-- -----"
"individual/blima                 |blima      |blima   |----- ELRCA ----- ----- ----- ----- ELR-- -----"
"individual/cmendes               |cmendes    |cmendes |----- ----- ELRCA ----- ----- ----- ELR-- -----"
"individual/drocha                |drocha     |drocha  |----- ----- ----- ELRCA ----- ----- ELR-- -----"
"individual/eprado                |eprado     |eprado  |----- ----- ----- ----- ELRCA ----- ELR-- -----"
"individual/fnunes                |fnunes     |fnunes  |----- ----- ----- ----- ----- ELRCA ELR-- -----"
"backup                           |svc-backup |root    |----- ----- ----- ELR-- ----- ----- ELRCA -----"
)

trim(){ local s="$*"; s="${s#"${s%%[![:space:]]*}"}"; echo "${s%"${s##*[![:space:]]}"}"; }

# ---------------------------------------------------------------------
if [ "${1:-}" = "--matriz" ]; then
  printf '| Diretório |'; for u in "${USUARIOS[@]}"; do printf ' %s |' "$u"; done; echo
  printf '|---|';        for _ in "${USUARIOS[@]}"; do printf ':---:|'; done; echo
  for linha in "${MATRIZ[@]}"; do
    IFS='|' read -r dir _ _ cel <<< "$linha"; dir=$(trim "$dir")
    printf '| `%s/` |' "$B${dir:+/$dir}"
    for c in $cel; do printf ' `%s` |' "$c"; done; echo
  done
  exit 0
fi

[ "$(id -u)" -eq 0 ] || { echo "Execute como root."; exit 1; }

# ---------------------------------------------------------------------
# Infraestrutura
# ---------------------------------------------------------------------
CRIADOS=()          # tudo que precisa ser apagado no final
TOTAL=0; OK=0; N=0
LOG=$B/grupos/monitoramento/metricas/alertas.log
TAM_LOG=$(stat -c %s "$LOG")

limpar(){
  for f in "${CRIADOS[@]}"; do rm -rf -- "$f" 2>/dev/null; done
  # devolve o alertas.log ao tamanho original (o svc-monitor acrescentou uma linha)
  if [ "$(stat -c %s "$LOG")" != "$TAM_LOG" ]; then
    chattr -a "$LOG"; truncate -s "$TAM_LOG" "$LOG"; chattr +a "$LOG"
  fi
}
trap limpar EXIT

como(){ # como USUARIO "comando"   -> retorna o código do comando executado como USUARIO
  local u="$1"; shift
  if [ "$u" = root ]; then bash -c "$*" >/dev/null 2>&1
  else runuser -u "$u" -- bash -c "cd /; $*" >/dev/null 2>&1; fi
}

fixture(){ # fixture DONO CAMINHO  -> cria arquivo como DONO (herda setgid/ACL padrão)
  local dono="$1" arq="$2"
  CRIADOS+=("$arq")
  if ! como "$dono" "echo 'arquivo de teste' > '$arq'"; then
    echo "ERRO DE PREPARAÇÃO: $dono não conseguiu criar $arq" >&2; exit 2
  fi
}

registra(){ # registra USUARIO ACAO CAMINHO ESPERADO OBTIDO
  local u="$1" a="$2" p="$3" esp="$4" obt="$5" st
  TOTAL=$((TOTAL+1))
  if [ "$esp" = "$obt" ]; then st=PASSOU; OK=$((OK+1)); else st=FALHOU; fi
  printf '%04d | %-11s | %-13s | %-58s | esperado: %-9s | obtido: %-9s | %s\n' \
         "$TOTAL" "$u" "$a" "$p" "$esp" "$obt" "$st"
}

resultado(){ [ "$1" -eq 0 ] && echo PERMITIDO || echo NEGADO; }

teste(){ # teste USUARIO ACAO CAMINHO ESPERADO "comando"
  local u="$1" a="$2" p="$3" esp="$4"; shift 4
  como "$u" "$*"; registra "$u" "$a" "$p" "$esp" "$(resultado $?)"
}

# ---------------------------------------------------------------------
echo "==================================================================="
echo " testes.sh - $(hostname) - $(date '+%F %T')"
echo "==================================================================="
echo
echo "### PARTE 1 - Matriz completa (8 usuários x ${#MATRIZ[@]} diretórios x 5 ações)"
for linha in "${MATRIZ[@]}"; do
  IFS='|' read -r dir dono alt cel <<< "$linha"
  dir=$(trim "$dir"); dono=$(trim "$dono"); alt=$(trim "$alt")
  d="$B${dir:+/$dir}"
  # arquivos para teste de leitura (um do dono típico, um do alternativo)
  N=$((N+1)); fixture "$dono" "$d/.fx_ler_${N}_a"
  fixture "$alt" "$d/.fx_ler_${N}_b"
  read -ra cel <<< "$cel"
  for i in "${!USUARIOS[@]}"; do
    u=${USUARIOS[$i]}; c=${cel[$i]}
    if [ "$u" = "$dono" ]; then outro="$alt"; arq="$d/.fx_ler_${N}_b"; else outro="$dono"; arq="$d/.fx_ler_${N}_a"; fi
    for j in 0 1 2 3 4; do
      [ "${c:$j:1}" = "-" ] && esp=NEGADO || esp=PERMITIDO
      case $j in
        0) teste "$u" entrar "$d" $esp "cd '$d'" ;;
        1) teste "$u" listar "$d" $esp "ls '$d'" ;;
        2) teste "$u" "ler($outro)" "$arq" $esp "cat '$arq'" ;;
        3) novo="$d/.fx_criar_${N}_$u"; CRIADOS+=("$novo")
           teste "$u" criar "$novo" $esp "touch '$novo'" ;;
        4) alvo="$d/.fx_apagar_${N}_$u"; fixture "$outro" "$alvo"
           teste "$u" "apagar($outro)" "$alvo" $esp "rm -f '$alvo' && [ ! -e '$alvo' ]" ;;
      esac
    done
  done
done

echo
echo "### PARTE 2 - Regras específicas (colaboração, ACL, setgid, atributos)"
COM=$B/empresa/comunicados/.fx_comunicado_asouza.txt
fixture asouza "$COM"
teste blima  "alterar(asouza)" "$COM" PERMITIDO "echo 'revisado por blima' >> '$COM'"
teste cmendes "alterar"        "$COM" NEGADO    "echo x >> '$COM'"
teste root   "grupo=soc(sgid)" "$COM" PERMITIDO "[ \$(stat -c %G '$COM') = soc ]"

SOC=$B/grupos/soc/.fx_soc_asouza.txt
fixture asouza "$SOC"
teste root   "grupo=soc(sgid)"  "$SOC" PERMITIDO "[ \$(stat -c %G '$SOC') = soc ]"
teste blima  "alterar(asouza)"  "$SOC" PERMITIDO "echo 'editado por blima' >> '$SOC'"
teste eprado "alterar"          "$SOC" NEGADO    "echo x >> '$SOC'"
teste drocha "alterar"          "$SOC" NEGADO    "echo x >> '$SOC'"

INC=$B/grupos/soc/incidentes/.fx_incidente_blima.txt
fixture blima "$INC"
teste asouza "ler"      "$INC" PERMITIDO "cat '$INC'"
teste asouza "alterar"  "$INC" NEGADO    "echo x >> '$INC'"
teste blima  "alterar"  "$INC" PERMITIDO "echo 'atualizado' >> '$INC'"

F=$B/grupos/redteam/ferramentas
teste fnunes  "executar" "$F/coleta-info.sh"      PERMITIDO "'$F/coleta-info.sh'"
teste fnunes  "alterar"  "$F/varredura-portas.sh" NEGADO    "echo x >> '$F/varredura-portas.sh'"
teste fnunes  "chmod"    "$F/varredura-portas.sh" NEGADO    "chmod o+w '$F/varredura-portas.sh'"
teste cmendes "executar" "$F/coleta-info.sh"      PERMITIDO "'$F/coleta-info.sh'"
NOVO=$F/.fx_novo-script.sh; CRIADOS+=("$NOVO")
teste cmendes "criar+chmod" "$NOVO" PERMITIDO "printf '#!/bin/bash\necho ok\n' > '$NOVO' && chmod 0770 '$NOVO'"
teste fnunes  "executar"    "$NOVO" PERMITIDO "'$NOVO'"
teste fnunes  "alterar"     "$NOVO" NEGADO    "echo x >> '$NOVO'"
teste cmendes "alterar"     "$NOVO" PERMITIDO "echo 'echo v2' >> '$NOVO'"

teste svc-monitor "acrescentar" "$LOG" PERMITIDO "echo \"\$(date '+%F %T') TESTE linha do testes.sh\" >> '$LOG'"
teste svc-monitor "sobrescrever" "$LOG" NEGADO   "echo x > '$LOG'"
teste svc-monitor "zerar"       "$LOG" NEGADO    "truncate -s 0 '$LOG'"
teste svc-monitor "apagar"      "$LOG" NEGADO    "rm -f '$LOG' && [ ! -e '$LOG' ]"
teste blima       "ler"         "$LOG" PERMITIDO "cat '$LOG'"
teste blima       "acrescentar" "$LOG" NEGADO    "echo x >> '$LOG'"
teste root        "sobrescrever" "$LOG" NEGADO   "echo x > '$LOG'"
teste root        "apagar"      "$LOG" NEGADO    "rm -f '$LOG' && [ ! -e '$LOG' ]"

POL=$B/empresa/politicas/politica-seguranca.txt
teste asouza      "ler"      "$POL" PERMITIDO "cat '$POL'"
teste drocha      "alterar"  "$POL" NEGADO    "echo x >> '$POL'"
teste root        "alterar"  "$POL" NEGADO    "echo x >> '$POL'"
teste root        "apagar"   "$POL" NEGADO    "rm -f '$POL' && [ ! -e '$POL' ]"
teste root        "renomear" "$POL" NEGADO    "mv '$POL' '$POL.bak'"
teste svc-monitor "ler"      "$POL" NEGADO    "cat '$POL'"

OUV=$B/empresa/ouvidoria
DEP=$OUV/.fx_denuncia_asouza.txt
fixture asouza "$DEP"
teste cmendes "ler(sabe nome)" "$DEP" NEGADO    "cat '$DEP'"
teste cmendes "sobrescrever"   "$DEP" NEGADO    "echo x > '$DEP'"
teste eprado  "ler"            "$DEP" PERMITIDO "cat '$DEP'"
teste eprado  "apagar(asouza)" "$DEP" NEGADO    "rm -f '$DEP' && [ ! -e '$DEP' ]"
teste root    "grupo=auditoria" "$DEP" PERMITIDO "[ \$(stat -c %G '$DEP') = auditoria ]"

teste svc-backup "ler(individual)" "$B/individual/asouza" PERMITIDO "ls '$B/individual/asouza'"
teste svc-backup "alterar"   "$B/LEIA-ME.txt" NEGADO "echo x >> '$B/LEIA-ME.txt'"
teste fnunes     "listar"    "$B/grupos"      NEGADO "ls '$B/grupos'"

echo
echo "### PARTE 3 - Testes de abuso obrigatórios (seção 7.3)"
T=$B/publico/troca/.fx_troca_blima.txt; fixture blima "$T"
teste fnunes      "abuso1:alterar script" "$F/varredura-portas.sh" NEGADO "echo 'rm -rf /' >> '$F/varredura-portas.sh'"
teste asouza      "abuso2:apagar(blima)"  "$T"                     NEGADO "rm -f '$T' && [ ! -e '$T' ]"
teste cmendes     "abuso3:listar"         "$OUV"                   NEGADO "ls '$OUV'"
teste cmendes     "abuso3:ler(asouza)"    "$DEP"                   NEGADO "cat '$DEP'"
teste svc-monitor "abuso4:sobrescrever"   "$LOG"                   NEGADO "echo x > '$LOG'"
teste svc-monitor "abuso4:zerar"          "$LOG"                   NEGADO "truncate -s 0 '$LOG'"
teste root        "abuso5:alterar"        "$POL"                   NEGADO "echo x >> '$POL'"
teste drocha      "abuso6:entrar"         "$B/individual/asouza"   NEGADO "cd '$B/individual/asouza'"
X=$B/publico/downloads/.fx_abuso7; CRIADOS+=("$X")
teste svc-backup  "abuso7:criar"          "$X"                     NEGADO "touch '$X'"
teste eprado      "abuso8:alterar"        "$SOC"                   NEGADO "echo x >> '$SOC'"

echo
echo "==================================================================="
PCT=$(awk -v a=$OK -v t=$TOTAL 'BEGIN{printf "%.2f", (t? a*100/t : 0)}')
echo " TOTAL DE TESTES: $TOTAL   PASSARAM: $OK   FALHARAM: $((TOTAL-OK))   ACERTO: $PCT%"
echo "==================================================================="
[ "$OK" -eq "$TOTAL" ]
