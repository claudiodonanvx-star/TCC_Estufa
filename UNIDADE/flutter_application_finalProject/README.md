# Flutter Mobile - UNIDADE

App mobile Flutter para o mesmo produto de monitoramento de estufa.

## Requisitos

- Flutter 3.x ou superior
- SDK Dart compatível
- API da UNIDADE disponível em `https://api-estufa.onrender.com` ou em outra URL configurada

## Execução

```bash
cd "UNIDADE/flutter_application_finalProject"
flutter pub get
flutter run
```

## Configuração da API

O app carrega a URL a partir de `assets/ipexterno.txt` ou `assets/IPAPI/ipexterno.txt`.

O conteúdo padrão destes arquivos é:

```text
https://api-estufa.onrender.com
```

Se o valor for `localhost` ou `127.0.0.1`, o app normaliza para HTTP local.

## Funcionalidades

- Login de usuário
- Conexão com backend Render
- Consumo de dados `api/ping`, `api/usuarios/login`, `api/clientes/cadastro`
- Tela de cadastro e autenticação

## Produto cliente

O mobile e o desktop fazem parte do mesmo produto cliente.
Ambos devem compartilhar a mesma paleta de cores verde, estilo de cards e a sensação de app leve e moderna.

## Observação

O mobile e o desktop compartilham o mesmo backend, mas usam tecnologias diferentes.
Ainda assim, é recomendável manter identidade visual e comportamentos semelhantes entre os dois produtos.
