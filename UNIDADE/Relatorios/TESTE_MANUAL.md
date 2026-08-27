# 🧪 GUIA DE TESTE MANUAL - Dashboard Estufa Smart

## 🎯 Objetivo
Validar todas as 10 ideias implementadas funcionando corretamente.

## 🔧 Preparação

### 1. Iniciar Servidor
```bash
cd "UNIDADE/Relatorios"
python -m http.server 8000
```

### 2. Acessar
- URL: `http://localhost:8000/login.html`

### 3. Login Teste (se sua API exigir)
- Usuário: `admin` ou `teste`
- Senha: `123456`

---

## ✅ CHECKLIST DE TESTES

### [1] Dashboard em Tempo Real
- [ ] **Carregar Dashboard**
  - Abra `dashboard.html`
  - Verifique se carrega sem erros (F12 console)
  
- [ ] **Cards Atualizando**
  - Temperatura, Umidade, Solo, Score mostram valores
  - Valores mudam a cada 15 segundos (ou vê "Estável")
  
- [ ] **Gauges Animadas**
  - 3 gauges (temp/umid/solo) aparecem na seção abaixo
  - Valores se movem suavemente
  - Cores mudam conforme valor (verde/amarelo/vermelho)
  
- [ ] **Status de Conexão**
  - Canto superior direito mostra "● Conectado" (verde)
  - Se offline, mostra "● Desconectado" (vermelho)
  
- [ ] **Sincronização**
  - Texto "Sincronizado às HH:MM" atualiza
  
- [ ] **Gráfico Histórico**
  - 3 linhas coloridas (temp/umid/solo)
  - Pontos no gráfico
  - Botões 24h/7d/30d funcionam

### [2] Recomendações Contextuais
- [ ] **Recomendações Aparecem**
  - Seção "💡 Sugestões Inteligentes" tem 1-3 items
  - Cada item tem: ícone, título, descrição, confiança %
  
- [ ] **Tipos de Recomendação**
  - Se temp baixa: "Aumentar aquecimento"
  - Se temp alta: "Aumentar ventilação"
  - Se solo seco: "Solo muito seco"
  
- [ ] **Níveis de Confiança**
  - Mostram % (ex: 87%, 92%, 98%)
  - Maiores que 90% = verde
  
- [ ] **Botão Executar**
  - Cada recomendação tem botão "Executar"
  - Clique não deve gerar erro

### [3] Mapa Visual da Estufa
- [ ] **Navegação para Mapa**
  - Sidebar: clique "🗺️ Mapa Visual"
  - Página muda para visualização de mapa
  
- [ ] **SVG da Estufa**
  - Retângulo verde claro de fundo
  - 6 círculos (sensores) com cores
  
- [ ] **Interatividade**
  - Passe mouse em sensor → tamanho aumenta
  - Clique em sensor → cor muda para azul
  - Seção "Detalhes do Sensor" atualiza com dados
  
- [ ] **Legenda**
  - Lado direito tem legenda com cores
  - Cada cor explica: verde=ideal, amarelo=aviso, vermelho=crítico
  
- [ ] **Dados Realistas**
  - Cada zona tem temperatura e umidade
  - Ex: Zona A 24.2°C, 65%

### [4] Comparativa Inteligente
- [ ] **Navegação**
  - Sidebar: clique "📈 Comparativa"
  
- [ ] **Três Abas**
  - Clique "vs. Histórico" → mostra gráfico barras
  - Clique "vs. Outros" → mostra radar chart
  - Clique "Benchmark" → mostra dados
  
- [ ] **vs. Histórico**
  - Gráfico barras comparando 2 semanas
  - Mostra: Temperatura, Umidade, Produtividade
  - 3 cards de stats (Produtividade +8%, Eficiência +12%, Score 92)
  
- [ ] **vs. Outros**
  - Gráfico radar (spider) comparativo
  - 2 linhas: "Sua Estufa" vs "Média de Mercado"
  - 6 eixos: Temperatura, Umidade, Solo, Luz, CO₂, Eficiência
  - Leaderboard com 3+ estufas ranking
  
- [ ] **Stats Aparecem**
  - Produtividade: 92/100
  - Eficiência: 88/100
  - Score Saúde: 94/100

### [5] Calendário Agrícola
- [ ] **Navegação**
  - Sidebar: clique "📅 Calendário"
  
- [ ] **Timeline de Fases**
  - 4 fases visuais (com cores)
  - Fase 1: Plantio (verde)
  - Fase 2: Crescimento (azul)
  - Fase 3: Amadurecimento (amarelo)
  - Fase 4: Colheita (laranja)
  
- [ ] **Marcos do Cultivo**
  - Seção inferior com lista de marcos
  - Pelo menos 3 marcos com datas
  - Ex: "Dia 1: Plantio realizado"
  
- [ ] **Duração**
  - Próximos check-ups mostram data
  - Estimativas claras

### [6] Relatórios Automáticos
- [ ] **Navegação**
  - Sidebar: clique "📄 Relatórios"
  
- [ ] **Botões de Ação**
  - "📄 Gerar Relatório Agora" → clique e vê alerta de sucesso
  - "📧 Enviar por E-mail" → clique e vê alerta
  - "💾 Exportar PDF" → clique e vê alerta
  
- [ ] **Agendamento**
  - Checkbox "Ativar relatórios automáticos" funciona
  - Selects com opções:
    - Frequência: Diário / Semanal / Mensal
    - Dia: Segunda / ... / Sexta (etc)
  
- [ ] **Histórico**
  - Seção "Relatórios Anteriores"
  - Lista com 2+ relatórios
  - Cada um tem: data, link baixar, link e-mail

### [7] Gamificação e Metas
- [ ] **Navegação**
  - Sidebar: clique "🎮 Metas"
  
- [ ] **4 Metas Visíveis**
  - Meta 1: "Temperatura Estável" (85% progresso)
  - Meta 2: "Umidade Ideal" (92% progresso)
  - Meta 3: "Zero Alertas Críticos" (100% ✅ Concluída)
  - Meta 4: "Eficiência Energética" (65% progresso)
  
- [ ] **Barra de Progresso**
  - Cada meta tem barra visual
  - Cores mudam conforme progresso
  - Texto mostra porcentagem
  
- [ ] **Recompensas**
  - Meta incompleta mostra: "🏆 +100 pontos se alcançar"
  - Meta concluída mostra: "🏆 +250 pontos" (verde)
  
- [ ] **Badges/Troféus**
  - Seção "Troféus e Badges"
  - 4 items: 2 desbloqueados ✅, 2 bloqueados 🔒
  - Ex: "🥇 Iniciante" (desbloqueado)
  - Ex: "👑 Mês Sem Alertas" (bloqueado - faltam 8 dias)
  
- [ ] **Pontuação**
  - Card grande mostrando "2,450 Pontos Totais"
  - Breakdown: Metas (+1200), Badges (+750), Operação (+500)

### [8] Alertas com Timeline
- [ ] **Navegação**
  - Sidebar: clique "⚠️ Alertas"
  
- [ ] **Timeline Vertical**
  - 4+ items em coluna
  - Cada item tem: ícone (⚠️/⏱️/✅), título, desc, hora, ação
  
- [ ] **Filtros Funcionam**
  - Botões: "Todos", "Temperatura", "Umidade", "Manutenção", "Automação"
  - Clique em cada um → lista filtra (ou mostra mensagem)
  
- [ ] **Histórico Realista**
  - Ex: "14:32 - Temperatura elevada - Ventilador acionado"
  - Ex: "14:15 - Umidade acima - Nenhuma ação"
  - Ex: "13:58 - Solo seco - Irrigação iniciada"

### [9] Previsões Preditivas
- [ ] **Navegação**
  - Sidebar: clique "🔮 Previsões"
  
- [ ] **3 Cards de Previsão**
  - Temperatura (87% confiança)
  - Umidade (92% confiança)
  - Solo (79% confiança)
  
- [ ] **Gráficos de 7 Dias**
  - Cada card tem linha do tempo
  - 7 pontos: Hoje, Amanhã, Qua, Qui, Sex, Sab, Dom
  - Mostram mín, máx, valor esperado
  
- [ ] **Recomendações**
  - Cada card tem caixa amarela com recomendação
  - Ex: "Com 85% confiança, temperatura cairá sexta 14h. Ação: aquecer 1h antes"
  
- [ ] **Confiança Visual**
  - Badge com %: 79%, 87%, 92%

### [10] Sincronização Mobile
- [ ] **Navegação**
  - Sidebar: clique "📱 Sincronização"
  
- [ ] **Status Box**
  - Mostra: "Última ação app: Ventilador ligado"
  - Confirmação: "✅ Sincronizado"
  - Tempo: "Há 5 minutos (via app)"
  
- [ ] **Histórico de Ações**
  - Timeline com 3+ ações
  - Cada uma mostra: data/hora, 📱/🖥️, descrição, ✅ status
  
- [ ] **QR Code**
  - Seção "Conectar com App Mobile"
  - QR code visual (placeholder)
  - Texto: "Escaneie este QR code..."

---

## 🔄 FLUXOS COMPLETOS

### Fluxo 1: Alerta até Resolução
1. Abra Dashboard
2. Veja alerta de temperatura alta
3. Clique em recomendação "Aumentar ventilação"
4. Vá para "Alertas" e veja timeline atualizada
5. Vá para "Metas" e veja impacto na pontuação

### Fluxo 2: Análise de Decisão
1. Abra Dashboard (veja dados atuais)
2. Vá para "Comparativa" 
3. Compare com semana passada
4. Vá para "Previsões"
5. Veja recomendação para próximos dias
6. Volte e execute ação sugerida

### Fluxo 3: Relatório Semanal
1. Abra Dashboard
2. Vá para "Calendário" (veja marcos)
3. Vá para "Relatórios"
4. Clique "Gerar Relatório Agora"
5. Veja em histórico
6. Clique "Enviar por E-mail"

---

## ⚙️ VERIFICAÇÕES TÉCNICAS

- [ ] **Console (F12)**
  - Nenhum erro vermelho
  - Logs verdes ✓ indicando conexão/carregamento
  
- [ ] **Performance**
  - Página não congela ao clicar
  - Gráficos renderizam em <1s
  - Animações são suaves
  
- [ ] **Responsividade**
  - Redimensione para 1024px (tablet)
  - Redimensione para 480px (mobile)
  - Layout se adapta (sidebar some em mobile)
  
- [ ] **Cores e Acessibilidade**
  - Botões aparecem com destaque
  - Links são distinguíveis
  - Texto tem contraste suficiente

---

## 🐛 BUGS REPORTADOS

Se encontrar algum bug:

1. **Anote o passo exato** para reproduzir
2. **Screenshot** da tela
3. **Console output** (F12 → Console)
4. **Navegador** e **versão**

Exemplo:
```
BUG: Gráfico não atualiza
Passo: 1) Abra Dashboard 2) Espere 15s 3) Gráfico não muda
Console: Erro em fetch /api/dados
Browser: Chrome 120.0
```

---

## ✨ TESTE DE ACEITAÇÃO

Para aprovar o dashboard, todos estes itens devem estar ✅:

- [ ] As 10 ideias implementadas
- [ ] Sem erros no console
- [ ] Performance aceitável
- [ ] Responsivo em desktop/tablet/mobile
- [ ] Dados mock funcionam (se API offline)
- [ ] Fluxos completos funcionam
- [ ] UI/UX está atraente
- [ ] Documentação clara

---

**Data do Teste**: _____/2026  
**Testador**: _________________  
**Status Final**: ⬜ Passou / ⬜ Falhou / ⬜ Com Ressalvas

**Observações**:
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

**Próximo**: Se passou, pode fazer deploy em produção! 🚀
