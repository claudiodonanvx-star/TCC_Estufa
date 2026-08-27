# apiProjetoSensor

API de backend para o projeto de estufa.

## Melhorias aplicadas

- Atualizado para Java 21 no `build.gradle`.
- Adicionado `spring-boot-starter-validation` para validação de dados de entrada.
- Adicionado `springdoc-openapi-starter-webmvc-ui` para documentação Swagger.
- Criado teste de integração para `POST /api/cultivos`.
- Validação de limites lógicos para temperatura, umidade e umidade do solo.
- Health check disponível em `/api/health` e `/api/health/ping`.

## Endpoints principais

- `GET /api/health`
- `GET /api/health/ping`
- `GET /api/cultivos`
- `GET /api/cultivo-habilitado`
- `POST /api/cultivos`
- `PUT /api/cultivos/{id}/habilitar`

## Documentação Swagger

Após iniciar a aplicação, a documentação está disponível em:

- `http://localhost:8080/swagger-ui/index.html`

## Build local

No diretório `UNIDADE/apiProjetoSensor`:

```bash
./gradlew clean build
```

## Docker

O projeto já possui `Dockerfile` para build multi-stage com Java 21.
