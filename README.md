# TCC Estufa

Repositório do projeto de monitoramento de estufa com aplicação mobile (Flutter), desktop (JavaFX) e backend/API.

## Estrutura

- `UNIDADE/flutter_application_finalProject` — app Flutter para mobile/web
- `UNIDADE/desktop_java_unidade` — app desktop JavaFX
- `UNIDADE/apiProjetoSensor` — API de sensores, relatórios e usuários
- `UNIDADE/sql` — scripts SQL de schema e seed
- `UNIDADE/Desktop JAR` — atalho/script para iniciar o desktop

## Produto cliente

O desktop e o mobile fazem parte do mesmo produto cliente, então eles devem compartilhar identidade visual, cores e experiência de uso sempre que possível.

## Desktop Java

Veja detalhes em `UNIDADE/desktop_java_unidade/README.md`.

## Flutter Mobile

Veja detalhes em `UNIDADE/flutter_application_finalProject/README.md`.

## OBS

O desktop não lê o banco diretamente; ele consome dados da API via HTTP.
O app mobile também usa o mesmo backend e deve compartilhar a mesma identidade visual de produto cliente.
