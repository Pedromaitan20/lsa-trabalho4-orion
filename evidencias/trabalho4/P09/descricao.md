# P09 — ACLs, ACLs padrão e máscara

**Responsável:** Thiago Carvalho da Silveira Abbade — **RM:** 575722

**Arquivos obrigatórios:** `getfacl.txt`

O `getfacl.txt` foi gerado com `getfacl -R -s -p /srv/arquivos` (só itens com ACL estendida). Usamos ACL apenas onde o modelo dono/grupo/outros não resolve: svc-backup lendo tudo (inclusive áreas individuais); drocha escrevendo em downloads e politicas sem usar o grupo orion; orion lendo comunicados do soc; depósito cego da ouvidoria; orion só atravessando grupos/; auditoria lendo grupos/; asouza só lendo incidentes e fnunes só lendo/executando ferramentas, embora sejam do mesmo grupo; svc-backup sem escrita em bkpadm.

As entradas `default:` fazem os arquivos futuros herdarem as permissões. A máscara é o teto de usuários nomeados e grupos; a demonstração mostra que `chmod g=r` em um arquivo com ACL rebaixa a máscara e o getfacl passa a exibir `#effective:r--`.

Prints: (1) getfacl de diretórios com ACL padrão; (2) testes de acesso; (3) efeito da máscara.
