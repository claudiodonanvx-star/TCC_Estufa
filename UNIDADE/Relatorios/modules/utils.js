/* ═══════════════════════════════════════════════════════════════════════════════ */
/* ESTUFA SMART - UTILITIES */
/* ═══════════════════════════════════════════════════════════════════════════════ */

window.EstufaUtils = {
  // Validação de autenticação
  verificarAuth() {
    const auth = localStorage.getItem('estufaAuth');
    if (!auth) {
      window.location.href = 'login.html';
      return false;
    }
    return true;
  },

  // Parsing de auth
  obterUsuario() {
    const auth = localStorage.getItem('estufaAuth');
    if (!auth) return null;
    try {
      const parsed = JSON.parse(auth);
      return parsed.usuario || 'Usuário';
    } catch (e) {
      return 'Usuário';
    }
  },

  // Logout
  logout() {
    localStorage.removeItem('estufaAuth');
    localStorage.removeItem('estufaApiBase');
    window.location.href = 'login.html';
  },

  // Formatação de números
  formatarValor(valor, casasDecimais = 1) {
    if (valor === null || valor === undefined) return '--';
    return parseFloat(valor).toFixed(casasDecimais);
  },

  // Formatação de data/hora
  formatarData(dataIso) {
    if (!dataIso) return '--';
    const data = new Date(dataIso);
    const horas = String(data.getHours()).padStart(2, '0');
    const minutos = String(data.getMinutes()).padStart(2, '0');
    return `${horas}:${minutos}`;
  },

  formatarDataCompleta(dataIso) {
    if (!dataIso) return '--';
    const data = new Date(dataIso);
    const dia = String(data.getDate()).padStart(2, '0');
    const mes = String(data.getMonth() + 1).padStart(2, '0');
    const ano = data.getFullYear();
    return `${dia}/${mes}/${ano}`;
  },

  // Cálculo de trend (tendência)
  calcularTrend(valorAtual, valorAnterior) {
    if (!valorAnterior || valorAtual === valorAnterior) return { dir: '↔', texto: 'Estável', classe: 'trend-estavel' };
    if (valorAtual > valorAnterior) return { dir: '↑', texto: 'Subindo', classe: 'trend-up' };
    return { dir: '↓', texto: 'Descendo', classe: 'trend-down' };
  },

  // Calcular score de saúde (0-100)
  calcularScoreSaude(temperatura, umidade, umidadeSolo, significado) {
    let score = 100;

    // Penalidades por afastamento dos ideais
    const tempIdeal = 24;
    const desvioTemp = Math.abs(temperatura - tempIdeal);
    score -= desvioTemp * 2;

    const umidIdeal = 65;
    const desvioUmid = Math.abs(umidade - umidIdeal);
    score -= desvioUmid * 1.5;

    const soloIdeal = 60;
    if (umidadeSolo !== null) {
      const desvioSolo = Math.abs(umidadeSolo - soloIdeal);
      score -= desvioSolo * 1;
    }

    // Penalidade se há significado crítico
    if (significado && (significado.includes('acima') || significado.includes('abaixo'))) {
      score -= 15;
    }

    return Math.max(0, Math.min(100, Math.round(score)));
  },

  // Determinar cor baseada em valor
  obterCor(tipo, valor) {
    if (tipo === 'temperatura') {
      if (valor < 18 || valor > 30) return '#ef5350';
      if (valor < 22 || valor > 26) return '#fdd835';
      return '#66bb6a';
    }
    if (tipo === 'umidade') {
      if (valor < 40 || valor > 80) return '#ef5350';
      if (valor < 50 || valor > 70) return '#fdd835';
      return '#66bb6a';
    }
    if (tipo === 'solo') {
      if (valor < 30 || valor > 80) return '#ef5350';
      if (valor < 40 || valor > 70) return '#fdd835';
      return '#66bb6a';
    }
    return '#66bb6a';
  },

  // Gerar recomendações
  gerarRecomendacoes(dados) {
    const recos = [];

    // Temperatura
    if (dados.temperatura < 20) {
      recos.push({
        tipo: 'temperature',
        titulo: 'Aumentar aquecimento',
        desc: `Temperatura em ${dados.temperatura}°C. Ideal: 22-25°C`,
        acao: 'Ligar aquecedor',
        confianca: 95
      });
    }
    if (dados.temperatura > 28) {
      recos.push({
        tipo: 'temperature',
        titulo: 'Aumentar ventilação',
        desc: `Temperatura em ${dados.temperatura}°C. Ideal: 22-25°C`,
        acao: 'Ligar ventilador',
        confianca: 92
      });
    }

    // Umidade do ar
    if (dados.umidade < 50) {
      recos.push({
        tipo: 'humidity',
        titulo: 'Aumentar umidade',
        desc: `Umidade em ${dados.umidade}%. Ideal: 60-70%`,
        acao: 'Ligar umidificador',
        confianca: 88
      });
    }
    if (dados.umidade > 75) {
      recos.push({
        tipo: 'humidity',
        titulo: 'Reduzir umidade',
        desc: `Umidade em ${dados.umidade}%. Ideal: 60-70%`,
        acao: 'Aumentar ventilação',
        confianca: 85
      });
    }

    // Umidade do solo
    if (dados.umidadeSolo !== null) {
      if (dados.umidadeSolo < 40) {
        recos.push({
          tipo: 'soil',
          titulo: 'Solo muito seco',
          desc: `Umidade do solo em ${dados.umidadeSolo}%. Ideal: 50-70%`,
          acao: 'Iniciar irrigação',
          confianca: 98
        });
      }
      if (dados.umidadeSolo > 75) {
        recos.push({
          tipo: 'soil',
          titulo: 'Solo muito úmido',
          desc: `Umidade do solo em ${dados.umidadeSolo}%. Ideal: 50-70%`,
          acao: 'Reduzir irrigação',
          confianca: 91
        });
      }
    }

    return recos.slice(0, 3); // Retornar top 3
  },

  // Mostrar alerta flutuante
  mostrarAlerta(mensagem, tipo = 'info', duracao = 5000) {
    const container = document.getElementById('alert-container');
    if (!container) return;

    const alerta = document.createElement('div');
    alerta.className = `alert-item ${tipo}`;
    alerta.innerHTML = `
      <div>${mensagem}</div>
      <button class="alert-close">✕</button>
    `;

    container.appendChild(alerta);

    alerta.querySelector('.alert-close').addEventListener('click', () => {
      alerta.remove();
    });

    if (duracao > 0) {
      setTimeout(() => alerta.remove(), duracao);
    }
  },

  // Atualizar status de conexão
  atualizarStatusConexao(conectado) {
    const badge = document.getElementById('status-conexao');
    if (!badge) return;

    if (conectado) {
      badge.textContent = '● Conectado';
      badge.className = 'status-badge';
    } else {
      badge.textContent = '● Desconectado';
      badge.className = 'status-badge disconnected';
    }
  },

  // Atualizar tempo de última sincronização
  atualizarUltimaSincronizacao() {
    const syncElement = document.getElementById('ultima-sync');
    if (!syncElement) return;

    const agora = new Date();
    syncElement.textContent = `Sincronizado às ${this.formatarData(agora.toISOString())}`;
  }
};

// Verificar auth ao carregar
document.addEventListener('DOMContentLoaded', () => {
  EstufaUtils.verificarAuth();
});
