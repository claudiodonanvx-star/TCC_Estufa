/* ═══════════════════════════════════════════════════════════════════════════════ */
/* ESTUFA SMART - API CLIENT */
/* ═══════════════════════════════════════════════════════════════════════════════ */

window.EstufaAPI = {
  apiCandidatos: [
    localStorage.getItem('estufaApiBase'),
    `http://${window.location.hostname || 'localhost'}:7002/api`,
    'http://localhost:7002/api',
    'http://127.0.0.1:7002/api',
    'http://143.106.241.4:7002/api'
  ].filter(Boolean),

  apiAtiva: null,
  ultimoErro: null,

  // Inicializar e detectar API ativa
  async inicializar() {
    for (const base of this.apiCandidatos) {
      try {
        const res = await fetch(`${base}/saude`, { signal: AbortSignal.timeout(3000) });
        if (res.ok) {
          this.apiAtiva = base;
          localStorage.setItem('estufaApiBase', base);
          console.log(`✓ API ativa: ${base}`);
          EstufaUtils.atualizarStatusConexao(true);
          return true;
        }
      } catch (e) {
        // Continuar tentando
      }
    }
    console.error('✗ Nenhuma API disponível');
    EstufaUtils.mostrarAlerta('Erro ao conectar com a API', 'danger');
    EstufaUtils.atualizarStatusConexao(false);
    return false;
  },

  // Requisição genérica
  async requisicao(endpoint, options = {}) {
    if (!this.apiAtiva) {
      throw new Error('API não inicializada');
    }

    const url = `${this.apiAtiva}${endpoint}`;
    const config = {
      headers: {
        'Content-Type': 'application/json',
        ...options.headers
      },
      signal: AbortSignal.timeout(10000),
      ...options
    };

    try {
      const res = await fetch(url, config);
      if (!res.ok) {
        throw new Error(`HTTP ${res.status}: ${res.statusText}`);
      }
      const data = await res.json();
      return data;
    } catch (erro) {
      this.ultimoErro = erro.message;
      console.error(`Erro em ${endpoint}:`, erro);
      throw erro;
    }
  },

  // GET /dados - Última leitura
  async obterDados() {
    return this.requisicao('/dados');
  },

  // GET /dados/historico - Histórico
  async obterHistorico(limite = 100) {
    return this.requisicao(`/dados/historico?limite=${limite}`);
  },

  // GET /dados/periodo - Dados de um período
  async obterDadosPeriodo(dataInicio, dataFim) {
    return this.requisicao(`/dados/periodo?inicio=${dataInicio}&fim=${dataFim}`);
  },

  // GET /relatorios/diario - Relatório diário
  async obterRelatorioDiario(data) {
    return this.requisicao(`/relatorios/diario?data=${data}`);
  },

  // GET /relatorios/semanal - Relatório semanal
  async obterRelatorioSemanal(dataInicio) {
    return this.requisicao(`/relatorios/semanal?inicio=${dataInicio}`);
  },

  // GET /alertas - Lista de alertas
  async obterAlertas(filtro = 'todos', limite = 50) {
    return this.requisicao(`/alertas?filtro=${filtro}&limite=${limite}`);
  },

  // POST /acoes/executar - Executar ação
  async executarAcao(acao, parametros = {}) {
    return this.requisicao('/acoes/executar', {
      method: 'POST',
      body: JSON.stringify({ acao, parametros })
    });
  },

  // GET /metricas - Métricas consolidadas
  async obterMetricas() {
    return this.requisicao('/metricas');
  },

  // GET /comparativa - Dados comparativos
  async obterComparativa() {
    return this.requisicao('/comparativa');
  },

  // GET /previsoes - Previsões
  async obterPrevisoes() {
    return this.requisicao('/previsoes');
  },

  // Mock data para desenvolvimento
  obterMockDados() {
    return {
      id: Math.floor(Math.random() * 10000),
      temperatura: 23 + (Math.random() - 0.5) * 4,
      umidade: 65 + (Math.random() - 0.5) * 10,
      umidadeSolo: 58 + (Math.random() - 0.5) * 8,
      significado: 'Condições ideais',
      coletadoEm: new Date().toISOString()
    };
  },

  obterMockHistorico(limite = 20) {
    const dados = [];
    for (let i = limite - 1; i >= 0; i--) {
      const data = new Date();
      data.setHours(data.getHours() - i);
      dados.push({
        id: Math.floor(Math.random() * 10000),
        temperatura: 23 + (Math.random() - 0.5) * 3,
        umidade: 65 + (Math.random() - 0.5) * 8,
        umidadeSolo: 58 + (Math.random() - 0.5) * 6,
        significado: Math.random() > 0.8 ? 'Acima do ideal' : 'Ideal',
        coletadoEm: data.toISOString()
      });
    }
    return dados;
  }
};

// Inicializar API ao carregar
document.addEventListener('DOMContentLoaded', async () => {
  const apiOk = await EstufaAPI.inicializar();
  if (!apiOk) {
    console.warn('Usando mock data para desenvolvimento');
  }
});
