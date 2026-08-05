# Desktop Java - UNIDADE

Desktop em JavaFX para monitoramento da estufa, com dashboard diário, semanal e mensal, além de relatórios inteligentes e exportação CSV/PDF.

## Requisitos

- Java 17+
- Gradle 8+
- API da UNIDADE em execução (`apiProjetoSensor`)

## Execução

```powershell
cd "c:\Users\Public\Documents\Nova pasta\TCC_Estufa\UNIDADE\desktop_java_unidade"
./gradlew.bat run
```

Também há um atalho em `UNIDADE/Desktop JAR/executar-desktop.bat` que inicia o projeto a partir desse diretório.

## Configurar URL da API

Por padrão o app usa `https://api-estufa.onrender.com`.

Para alterar:

```powershell
./gradlew.bat run -Destufa.api.baseUrl=https://SUA_API
```

## Funcionalidades

- Visão Geral com KPIs e gráficos
- Abas Diário, Semanal e Mensal
- Resumo inteligente com recomendações automáticas
- Exportação de relatórios em CSV e PDF

## Identidade visual do produto cliente

O desktop é um cliente do mesmo produto que o mobile, então este README e o app devem seguir a mesma paleta de cores e estilo de cards verde-suave.

## Observação sobre períodos

A API atual exposta em `/api/dados` não inclui timestamp da leitura em `SensorData`. Por isso, os períodos são estimados por janela de amostras assumindo coleta a cada 20s:

- Diário: últimas 4.320 amostras
- Semanal: últimas 30.240 amostras
- Mensal (30 dias): últimas 129.600 amostras

Quando o campo de data/hora for adicionado na API, o app pode evoluir para períodos exatos por calendário.
