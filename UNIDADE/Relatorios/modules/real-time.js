/* ═══════════════════════════════════════════════════════════════════════════════ */
/* ESTUFA SMART - REAL-TIME UPDATES */
/* ═══════════════════════════════════════════════════════════════════════════════ */

window.EstufaRealTime = {
  intervaloAtualizar: 15000, // 15 segundos
  intervaloId: null,
  ultimosDados: null,
  historicoValores: [], // Para calcular trends
  maxHistorico: 60,

  // Iniciar atualização em tempo real
  iniciar() {
    console.log('Iniciando atualizações em tempo real...');
    
    // Atualizar imediatamente
    this.atualizar();

    // Depois a cada intervalo
    this.intervaloId = setInterval(() => this.atualizar(), this.intervaloAtualizar);
  },

  // Parar atualização
  parar() {
    if (this.intervaloId) {
      clearInterval(this.intervaloId);
      this.intervaloId = null;
      console.log('Atualizações paradas');
    }
  },

  // Atualizar dados
  async atualizar() {
    try {
      // Tentar obter de API, senão usar mock
      let dados;
      try {
        const lista = await EstufaAPI.obterDados();
        dados = Array.isArray(lista) ? lista[lista.length - 1] : lista;
      } catch (e) {
        console.warn('API indisponível, usando mock');
        dados = EstufaAPI.obterMockDados();
      }

      // Armazenar histórico para trends
      this.historicoValores.push({
        temperatura: dados.temperatura,
        umidade: dados.umidade,
        umidadeSolo: dados.umidadeSolo,
        timestamp: Date.now()
      });

      if (this.historicoValores.length > this.maxHistorico) {
        this.historicoValores.shift();
      }

      // Atualizar UI
      this.atualizarCards(dados);
      this.atualizarGauges(dados);
      this.atualizarRecomendacoes(dados);
      this.atualizarGraficoHistorico(dados);

      // Armazenar como último
      this.ultimosDados = dados;

      // Atualizar timestamp de sincronização
      EstufaUtils.atualizarUltimaSincronizacao();
      EstufaUtils.atualizarStatusConexao(true);

    } catch (erro) {
      console.error('Erro ao atualizar dados:', erro);
      EstufaUtils.atualizarStatusConexao(false);
    }
  },

  // Atualizar cards de valores
  atualizarCards(dados) {
    // Temperatura
    const valTemp = document.querySelector('#rt-temp .rt-value');
    if (valTemp) {
      const novoValor = EstufaUtils.formatarValor(dados.temperatura, 1);
      if (valTemp.textContent !== novoValor) {
        valTemp.textContent = novoValor;
        this.animarMudanca(valTemp);
      }
    }

    // Umidade
    const valUmid = document.querySelector('#rt-umid .rt-value');
    if (valUmid) {
      const novoValor = EstufaUtils.formatarValor(dados.umidade, 0);
      if (valUmid.textContent !== novoValor) {
        valUmid.textContent = novoValor;
        this.animarMudanca(valUmid);
      }
    }

    // Solo
    const valSolo = document.querySelector('#rt-solo .rt-value');
    if (valSolo && dados.umidadeSolo !== null) {
      const novoValor = EstufaUtils.formatarValor(dados.umidadeSolo, 1);
      if (valSolo.textContent !== novoValor) {
        valSolo.textContent = novoValor;
        this.animarMudanca(valSolo);
      }
    }

    // Score de saúde
    const score = EstufaUtils.calcularScoreSaude(
      dados.temperatura,
      dados.umidade,
      dados.umidadeSolo,
      dados.significado
    );
    const scoreEl = document.getElementById('health-score');
    if (scoreEl && scoreEl.textContent !== score.toString()) {
      scoreEl.textContent = score;
      this.animarMudanca(scoreEl);
    }

    // Trends
    this.atualizarTrends(dados);
  },

  // Animar mudança de valor
  animarMudanca(elemento) {
    if (!elemento) return;
    elemento.style.animation = 'none';
    setTimeout(() => {
      elemento.style.animation = 'pulse 0.5s ease-out';
    }, 10);
  },

  // Atualizar trends (setas de tendência)
  atualizarTrends(dados) {
    if (this.historicoValores.length < 2) return;

    const atual = this.historicoValores[this.historicoValores.length - 1];
    const anterior = this.historicoValores[this.historicoValores.length - 2];

    // Temperatura
    const trendTemp = EstufaUtils.calcularTrend(atual.temperatura, anterior.temperatura);
    const trendTempEl = document.getElementById('trend-temp');
    if (trendTempEl) {
      trendTempEl.textContent = `${trendTemp.dir} ${trendTemp.texto}`;
      trendTempEl.className = `rt-trend ${trendTemp.classe}`;
    }

    // Umidade
    const trendUmid = EstufaUtils.calcularTrend(atual.umidade, anterior.umidade);
    const trendUmidEl = document.getElementById('trend-umid');
    if (trendUmidEl) {
      trendUmidEl.textContent = `${trendUmid.dir} ${trendUmid.texto}`;
      trendUmidEl.className = `rt-trend ${trendUmid.classe}`;
    }

    // Solo
    const trendSolo = EstufaUtils.calcularTrend(atual.umidadeSolo, anterior.umidadeSolo);
    const trendSoloEl = document.getElementById('trend-solo');
    if (trendSoloEl) {
      trendSoloEl.textContent = `${trendSolo.dir} ${trendSolo.texto}`;
      trendSoloEl.className = `rt-trend ${trendSolo.classe}`;
    }
  },

  // Atualizar gauges
  atualizarGauges(dados) {
    // Nota: Os gauges são criados no dashboard.js
    // Aqui apenas guardamos referência para atualizar
    if (window.chartesGauges) {
      if (window.chartesGauges.temp) {
        window.chartesGauges.temp.data.datasets[0].data[0] = dados.temperatura;
        window.chartesGauges.temp.update();
      }
      if (window.chartesGauges.umid) {
        window.chartesGauges.umid.data.datasets[0].data[0] = dados.umidade;
        window.chartesGauges.umid.update();
      }
      if (window.chartesGauges.solo && dados.umidadeSolo !== null) {
        window.chartesGauges.solo.data.datasets[0].data[0] = dados.umidadeSolo;
        window.chartesGauges.solo.update();
      }
    }
  },

  // Atualizar recomendações
  atualizarRecomendacoes(dados) {
    const recos = EstufaUtils.gerarRecomendacoes(dados);
    const container = document.getElementById('recommendations-list');
    if (!container) return;

    container.innerHTML = recos.map(reco => `
      <div class="recommendation-item ${reco.tipo === 'soil' ? 'danger' : reco.confianca < 90 ? 'warning' : ''}">
        <div style="display: flex; align-items: center; flex: 1;">
          <span class="rec-icon">${reco.tipo === 'temperature' ? '🌡️' : reco.tipo === 'humidity' ? '💧' : '🌱'}</span>
          <div class="rec-content">
            <div class="rec-title">${reco.titulo}</div>
            <div class="rec-desc">${reco.desc}</div>
          </div>
        </div>
        <div style="display: flex; align-items: center; gap: 12px;">
          <span class="rec-confidence">${reco.confianca}%</span>
          <button class="btn-secondary" style="padding: 6px 12px; font-size: 12px;">Executar</button>
        </div>
      </div>
    `).join('');

    // Se nenhuma recomendação
    if (recos.length === 0) {
      container.innerHTML = '<div style="text-align: center; color: var(--text-secondary); padding: 20px;">✅ Tudo em perfeitas condições!</div>';
    }
  },

  // Atualizar gráfico de histórico
  atualizarGraficoHistorico(dados) {
    // Gráfico será atualizado pelo dashboard quando solicitado
  }
};

// CSS para animação de mudança
const estilo = document.createElement('style');
estilo.textContent = `
  @keyframes pulse {
    0% { transform: scale(1); }
    50% { transform: scale(1.05); }
    100% { transform: scale(1); }
  }
  
  .trend-estavel { color: var(--primary); }
  .trend-up { color: var(--secondary); }
  .trend-down { color: var(--warning); }
`;
document.head.appendChild(estilo);

// Iniciar ao carregar
document.addEventListener('DOMContentLoaded', () => {
  EstufaRealTime.iniciar();
});
