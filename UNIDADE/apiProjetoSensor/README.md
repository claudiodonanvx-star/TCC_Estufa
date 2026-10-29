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

Para perguntas factuais sobre plantas, cultivo, condições ideais, identificação ou doenças, o agente aciona `buscar_fontes_cultivo` antes de responder. O Gemini faz uma pesquisa na web em tempo real usando Google Search Grounding e devolve citações verificáveis, priorizando fontes técnicas como Embrapa, universidades e órgãos públicos. Os trechos citados e os URLs são mostrados no chat e usados para fundamentar a resposta. Se o Grounding falhar ou não trouxer citações, a API tenta a busca de artigos da Wikipedia como alternativa. Sem fontes verificáveis, o agente não deve inventar fatos nem faixas agronômicas. Para gerar texto narrativo e habilitar a busca com Gemini, configure `AI_API_KEY` no Render e use um modelo compatível com Google Search Grounding. O Grounding pode gerar cobrança conforme o plano e o modelo. Também é possível trocar `AI_ENDPOINT` e `AI_MODEL` por um provedor compatível com a API OpenAI; nesse caso, a busca alternativa da Wikipedia é usada.

## IA explicável

O módulo de IA usa o histórico real ou sintético persistido em `sensor_data`. Ele calcula médias da janela recente e compara o início com o fim da janela para identificar tendência de temperatura e umidade. Também gera alertas interpretáveis quando a umidade do solo está baixa ou alta. A resposta informa a quantidade de amostras, as médias, as tendências, os insights e o método utilizado, permitindo demonstrar o raciocínio durante a banca.

## Consultas de dados pelo agente

Além das ferramentas de consulta específicas, o agente pode executar buscas somente leitura diretamente no banco, sem criar uma rota de API para cada consulta. A ferramenta aceita apenas as tabelas operacionais `sensor_data`, `cultivos`, `alertas` e `relatorio_diario`; não aceita SQL livre, limita cada busca a 50 linhas e usa parâmetros para os termos pesquisados. Também aceita intervalos de datas em leituras, alertas e relatórios diários.

Como a resposta da ferramenta é enviada ao provedor de IA configurado, mantenha nessa lista apenas dados operacionais que podem ser compartilhados com esse provedor.

Para pedir um arquivo pelo chat, solicite um relatório CSV ou PDF e informe o período. O agente gera um link de download dos dados operacionais selecionados; exportações aceitam até 31 dias e 5.000 registros. A consulta em linguagem natural suporta até oito rodadas de ferramentas por pergunta.

Para cadastrar um cultivo pelo chat, informe o nome e as faixas mínima e máxima de temperatura, umidade do ar e umidade do solo. Se os valores não forem informados, o agente pode pesquisar fontes técnicas da web e propor valores somente quando eles estiverem presentes nos trechos citados. A proposta exibe os links consultados e não é salva até a confirmação explícita no chat. Cultivos criados pelo chat permanecem desabilitados; habilitá-los é uma ação separada. Se as fontes não trouxerem todas as seis faixas, o agente deve pedir os valores faltantes em vez de estimá-los.

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
