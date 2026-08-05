# Teste da API de Cultivos

## Problema Identificado
O POST `/api/cultivos` estava falhando com erro "Failed to fetch" no Flutter.

### Causas Corrigidas:
1. ✅ Classe `Cultivo` não tinha construtor vazio (necessário para desserialização JSON)
2. ✅ Falta de validação e logs no controller
3. ✅ Erro genérico no Flutter sem detalhes da resposta

## Como Testar

### 1. Compilar a API
```bash
cd UNIDADE/apiProjetoSensor
./gradlew.bat build
./gradlew.bat bootRun
```

### 2. Teste com CURL (GET)
```bash
curl -H "ngrok-skip-browser-warning: true" \
  https://api-estufa.onrender.com/api/cultivos
```

### 3. Teste com CURL (POST)
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "ngrok-skip-browser-warning: true" \
  -d '{
    "nome": "Tomate",
    "tipo": "horta",
    "temperaturaMinima": 18,
    "temperaturaMaxima": 30,
    "umidadeMinima": 60,
    "umidadeMaxima": 85,
    "umidadeSoloMinima": 30,
    "umidadeSoloMaxima": 80
  }' \
  https://api-estufa.onrender.com/api/cultivos
```

### 4. Verificar Logs
Após compilar e rodar a API localmente, procure por:
- `🌱 POST /api/cultivos recebido` → indica que a requisição chegou
- `✅ Cultivo criado com ID: X` → indica sucesso
- Mensagens de erro se houver problema

## Próximos Passos
1. [ ] Testar POST com Flutter localmente
2. [ ] Verificar logs na consola
3. [ ] Deploy na API do Render
4. [ ] Testar novamente no Flutter em produção

## Estrutura JSON Esperada
```json
{
  "nome": "String (obrigatório)",
  "tipo": "String (obrigatório)",
  "temperaturaMinima": "float",
  "temperaturaMaxima": "float",
  "umidadeMinima": "float",
  "umidadeMaxima": "float",
  "umidadeSoloMinima": "float",
  "umidadeSoloMaxima": "float"
}
```

**Nota:** A API ignora o campo `habilitada` e sempre seta como `false` no servidor.
