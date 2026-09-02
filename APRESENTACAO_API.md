# Apresentação — API da Estufa Inteligente (TCC)

> Roteiro de apresentação para a Facitec do Cotil. Cada `---` marca um novo "slide"/tópico.

---

## 1. Contexto do projeto

- Projeto de estufa inteligente (TCC) dividido em duas frentes:
  - **UNIDADE**: hardware (ESP32) + API + apps que monitoram e controlam a estufa.
  - **EMPRESA**: sistema comercial (site, API de empresa, banco de dados).
- Hoje o foco é a **API da Unidade** (`apiProjetoSensor`), o "cérebro" que conecta o hardware aos aplicativos.

---

## 2. Visão geral da arquitetura

```
ESP32 (sensores + relés)
   │  HTTPS (POST/GET a cada 20s)
   ▼
API Spring Boot  ──►  Banco de dados (JPA/Repository)
   ▲
   │  HTTPS (REST)
   ├── App Flutter (mobile)
   ├── App Desktop (JavaFX)
   └── Monitor Serial Web (HTML/JS, hospedado pela própria API)
```

- A API é o ponto único de verdade: ela recebe as leituras do ESP32, decide o estado dos atuadores e serve esses dados para todos os clientes (app, desktop, web).
- Hospedada no **Render** (nuvem), então tanto o ESP32 quanto os apps falam com ela pela internet, não em rede local.

---

## 3. Tecnologias utilizadas

- **Java 17/21 + Spring Boot** — framework da API.
- **Gradle** — build e gerenciamento de dependências (`gradlew bootRun`).
- **Docker** — imagem de deploy (`Dockerfile` multi-stage: build com JDK, execução com JRE).
- **Render** — hospedagem em nuvem (plano free, com "cold start").
- **ArduinoJson / HTTPClient (ESP32)** — comunicação do hardware com a API via HTTPS.

---

## 4. Organização em camadas (arquitetura em Spring Boot)

```
controller/   -> recebe requisições HTTP, valida entrada
service/      -> regras de negócio (ex.: quando ligar a bomba)
repository/   -> acesso ao banco de dados (JPA)
model/        -> entidades (Cultivo, SensorData, Cliente...)
dto/          -> objetos de transferência de dados
exception/    -> tratamento de erros
```

- Separação clássica de responsabilidades: o controller não sabe *como* a regra funciona, só delega ao service.

---

## 5. Principais grupos de endpoints

| Grupo | Exemplos | Função |
|---|---|---|
| **Sensores** | `POST /api/dados`, `GET /api/dados`, `GET /api/ping` | ESP32 envia leituras (temperatura, umidade, solo); apps consultam histórico. |
| **Validação** | `POST /api/validar` | Recebe leitura do ESP32, retorna cor RGB + significado (ex.: "solo seco"). |
| **Atuadores** | `GET/PUT/POST /api/atuadores/...` | Liga/desliga bomba, cooler e aquecedor; controla modo automático. |
| **Cultivos** | `GET/POST/PUT/DELETE /api/cultivos` | Cadastro de cultivos com faixas ideais (temperatura, umidade do solo). |
| **Clientes/Usuários** | `/api/clientes`, `/api/usuarios` | Cadastro, login, aprovação de pendências. |
| **Alertas** | `/api/alertas` | Lista alertas críticos gerados pelas leituras fora da faixa. |
| **Relatórios** | `/api/relatorios/diario|semanal|mensal|anual` | Consolidação e exportação (CSV) dos dados históricos. |
| **Health** | `/api/health` | Verifica se a API está no ar (útil por causa do "sleep" do Render free). |

---

## 6. Fluxo principal (o "coração" do sistema)

1. ESP32 lê temperatura, umidade do ar e umidade do solo.
2. Envia via `POST /api/validar` → API compara com os limites do cultivo ativo e responde com uma cor (LED RGB) + significado.
3. A API guarda o histórico (`/api/dados`) e recalcula o estado dos atuadores (`AtuadorService`): se a umidade do solo está abaixo do mínimo, a bomba deve ligar.
4. O ESP32, no mesmo ciclo, consulta `GET /api/atuadores` e liga/desliga fisicamente os relés (bomba, cooler, aquecedor).
5. Esse ciclo se repete a cada **20 segundos** — por isso o acionamento manual pelo app não é instantâneo no relé físico, é uma questão de arquitetura de *polling*, não de fila de processamento.

---

## 7. Controle manual x automático dos atuadores

- **Modo automático**: a própria API decide ligar/desligar com base nos limites do cultivo cadastrado.
- **Modo manual**: usuário aciona pelo app/desktop por um tempo limitado, evitando esquecimentos:
  - Bomba: até **15s** (ajustado recentemente para não drenar água rápido demais).
  - Cooler: até 55s.
  - Aquecedor: até 35s (limite menor por segurança).

---

## 8. Deploy

- `Dockerfile` multi-stage: builda o `.jar` com Gradle e roda numa imagem JRE enxuta.
- Deploy contínuo no **Render**, plano gratuito (o serviço "dorme" sem tráfego e demora alguns segundos para acordar na primeira requisição — por isso existe `/api/health`).
- Repositório: `github.com/claudiodonanvx-star/TCC_Estufa`.

---

## 9. Pontos fortes para destacar na apresentação

- API única servindo 3 clientes diferentes (mobile, desktop, hardware) — reaproveitamento real.
- Separação clara de camadas (controller/service/repository).
- Regras de negócio configuráveis por cultivo (cada planta tem sua faixa ideal).
- Segurança simples de tempo de acionamento manual, evitando desperdício de água/energia.
- Resiliência: ESP32 trata erros de sensor, Wi-Fi e falha de API sem travar.

---

## 10. Possíveis perguntas da banca (e respostas rápidas)

- **"Por que Spring Boot?"** → Produtividade, ecossistema maduro, fácil de estruturar em camadas.
- **"Por que o relé demora para responder?"** → ESP32 usa polling a cada 20s, não há push/websocket; simplicidade > tempo real perfeito.
- **"Como garantem que a bomba não fique ligada demais?"** → Limite de duração no backend (`AtuadorService`), respeitado tanto no acionamento manual quanto validado no servidor (não confia só no app).
- **"E se a internet cair?"** → ESP32 desliga os atuadores por segurança (`desligarAtuadores()`) quando perde a leitura da API.
