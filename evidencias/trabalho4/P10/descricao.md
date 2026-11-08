# P10 — Atributos imutável e somente acréscimo

**Responsável:** Thiago Carvalho da Silveira Abbade — **RM:** 575722

Gerado com `bash demos.sh P10`. O `lsattr` mostra `i` na politica-seguranca.txt e `a` no alertas.log.

Com o atributo `i`, o root recebe “Operation not permitted” ao acrescentar, sobrescrever, apagar, renomear e até ao dar chmod na política; drocha, que tem escrita pela ACL, também é bloqueado. Com o atributo `a`, svc-monitor acrescenta uma linha normalmente, mas não consegue sobrescrever (`>`) nem zerar (`truncate`), e o root também não consegue sobrescrever nem apagar o log. Por fim mostramos que o root só altera a política depois de remover o atributo com `chattr -i` — o arquivo foi restaurado e o atributo recolocado em seguida.

Prints: (1) lsattr + tentativas negadas na política; (2) testes do alertas.log.
