# P03 — Tabela de permissões

**Responsável:** Pedro Maitan de Moraes — **RM:** 574960

**Arquivos obrigatórios:** `tabela.md`

A tabela `tabela.md` lista cada diretório e arquivo especial com dono, grupo, o modo aplicado com chmod (literal e octal), o modo exibido pelo `ls`/`stat` depois das ACLs e a justificativa de cada escolha.

Separamos o “chmod aplicado” do “exibido” porque, quando um item tem ACL, os bits de grupo mostrados passam a ser a máscara. Exemplo: a ouvidoria foi criada com 3750 e aparece como 3770 porque a entrada `group:orion:-wx` elevou a máscara para rwx, mas o grupo dono (auditoria) continua r-x. No fim da tabela registramos as decisões de projeto para regras conflitantes: svc-backup só escreve em backup/ mesmo sendo do bkpadm, auditoria só lê fora dos próprios grupos, e svc-monitor precisa atravessar grupos/ sem ser de orion.
