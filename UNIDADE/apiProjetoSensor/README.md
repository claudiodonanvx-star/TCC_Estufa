# apiProjetoSensor

API de backend para o projeto de estufa.

## Melhorias aplicadas

- Atualizado para Java 21 no `build.gradle`.
- Adicionado `spring-boot-starter-validation` para validação de dados de entrada.
- Adicionado `springdoc-openapi-starter-webmvc-ui` para documentação Swagger.
- Criado teste de integração para `POST /api/cultivos`.
- Validação de limites lógicos para temperatura, umidade e umidade do solo.
- Health check disponível em `/api/health` e `/api/health/ping`.
- Login com emissão de token JWT e migração automática de senhas antigas para BCrypt.
- Validação de limites físicos em leituras de temperatura e umidade.
- Eventos em tempo real em `/ws/sincronizacao`, com tópicos `/topic/sensores` e `/topic/atuadores`.
- Endpoint `/api/insights` com análise explicável do histórico recente.

## Endpoints principais

- `GET /api/health`
- `GET /api/health/ping`
- `GET /api/cultivos`
- `GET /api/cultivo-habilitado`
- `POST /api/cultivos`
- `PUT /api/cultivos/{id}/habilitar`
- `POST /api/usuarios/login`
- `GET /api/insights?limite=30`
- `POST /api/ia/consulta-planta`

## Migration do cadastro

Execute `UNIDADE/sql/10_add_usuario_cadastro.sql` no banco de produção antes do deploy, caso o Hibernate ainda não tenha criado a coluna `usuario`. A migration é idempotente e mantém os campos antigos para compatibilidade com cadastros existentes.

## Consulta botânica com IA

O endpoint recebe, por exemplo:

```json
{
	"planta": "tomate",
	"pergunta": "Qual umidade é ideal nesta fase?",
	"umidadeAtual": 42,
	"temperaturaAtual": 25
}
```

Ele busca fontes públicas na Wikipedia, combina a informação com a leitura da estufa e retorna um relatório. Para gerar texto narrativo por um modelo de IA, configure `AI_API_KEY` no Render. Também é possível trocar `AI_ENDPOINT` e `AI_MODEL` por um provedor compatível com a API OpenAI. Sem essa chave, o sistema continua funcionando com fontes e análise local, mas não deve ser apresentado como IA generativa.

## IA explicável

O módulo de IA usa o histórico real ou sintético persistido em `sensor_data`. Ele calcula médias da janela recente e compara o início com o fim da janela para identificar tendência de temperatura e umidade. Também gera alertas interpretáveis quando a umidade do solo está baixa ou alta. A resposta informa a quantidade de amostras, as médias, as tendências, os insights e o método utilizado, permitindo demonstrar o raciocínio durante a banca.

## Segurança e sincronização

O login retorna um JWT assinado por HMAC e as senhas novas são armazenadas com BCrypt. Usuários antigos são convertidos para BCrypt no primeiro login bem-sucedido. Para exigir JWT nas rotas da API, configure `JWT_ENFORCE=true` e defina `JWT_SECRET` com pelo menos 32 caracteres. O padrão permanece desativado durante a migração dos clientes e do firmware.

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
