# Desktop Java - UNIDADE

Desktop em JavaFX para monitoramento da estufa, com dashboard diario, semanal e mensal, alem de relatorios inteligentes e exportacao CSV/PDF.

## Requisitos

- Java 17+
- Gradle 8+
- API da UNIDADE em execucao (`apiProjetoSensor`)

## Execucao

```powershell
cd "c:\Users\Public\Documents\Nova pasta\TCC_Estufa\UNIDADE\desktop_java_unidade"
gradle run
```

## Configurar URL da API

Por padrao o app usa `https://tcc-estufa.onrender.com`.

Para alterar:

```powershell
gradle run -Destufa.api.baseUrl=https://SUA_API
```

## Funcionalidades

- Visao Geral com KPIs e graficos
- Abas Diario, Semanal e Mensal
- Resumo inteligente com recomendacoes automaticas
- Exportacao de relatorio em CSV e PDF

## Observacao sobre periodos

A API atual exposta em `/api/dados` nao inclui timestamp da leitura em `SensorData`. Por isso, os periodos sao estimados por janela de amostras assumindo coleta a cada 20s:

- Diario: ultimas 4.320 amostras
- Semanal: ultimas 30.240 amostras
- Mensal (30 dias): ultimas 129.600 amostras

Quando o campo de data/hora for adicionado na API, o app pode evoluir para periodos exatos por calendario.
