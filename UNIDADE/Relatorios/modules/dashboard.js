/* ═══════════════════════════════════════════════════════════════════════════════ */
/* ESTUFA SMART - DASHBOARD MAIN */
/* ═══════════════════════════════════════════════════════════════════════════════ */

window.chartesGauges = {};
let graficoHistorico = null;

document.addEventListener('DOMContentLoaded', () => {
  inicializarDashboard();
});

// ═════════════════════════════════════════════════════════════════════════════
// INICIALIZAÇÃO
// ═════════════════════════════════════════════════════════════════════════════

function inicializarDashboard() {
  console.log('Inicializando Dashboard...');

  // Navegação
  inicializarNavegacao();

  // Gauges
  criarGauges();

  // Gráficos
  criarGraficoHistorico();

  // Eventos
  atarEventos();

  // Carregamento inicial de dados
  carregarDadosIniciais();

  console.log('✓ Dashboard pronto');
}

// ═════════════════════════════════════════════════════════════════════════════
// NAVEGAÇÃO ENTRE VIEWS
// ═════════════════════════════════════════════════════════════════════════════

function inicializarNavegacao() {
  const navLinks = document.querySelectorAll('.nav-link');

  navLinks.forEach(link => {
    link.addEventListener('click', (e) => {
      e.preventDefault();
      const view = link.dataset.view;

      // Remover active de todos
      navLinks.forEach(l => l.classList.remove('active'));
      link.classList.add('active');

      // Mostrar view
      mostrarView(view);
    });
  });

  // Logout
  const btnLogout = document.getElementById('btn-logout');
  if (btnLogout) {
    btnLogout.addEventListener('click', () => {
      if (confirm('Deseja realmente sair?')) {
        EstufaUtils.logout();
      }
    });
  }
}

function mostrarView(viewName) {
  // Ocultar todas as views
  document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));

  // Mostrar view selecionada
  const viewEl = document.getElementById(`view-${viewName}`);
  if (viewEl) {
    viewEl.classList.add('active');
  }

  // Atualizar título
  atualizarTituloView(viewName);

  // Carregar dados específicos da view
  carregarDadosView(viewName);
}

function atualizarTituloView(viewName) {
  const titles = {
    dashboard: { h1: 'Dashboard em Tempo Real', p: 'Monitoramento inteligente da sua estufa' },
    mapa: { h1: 'Mapa Visual da Estufa', p: 'Visualize sensores e condições por zona' },
    alerts: { h1: 'Alertas e Eventos', p: 'Histórico de eventos e ações' },
    comparativa: { h1: 'Análise Comparativa', p: 'Compare seu desempenho' },
    calendario: { h1: 'Calendário Agrícola', p: 'Timeline do cultivo' },
    relatorios: { h1: 'Relatórios Automáticos', p: 'Gere e configure relatórios' },
    gamificacao: { h1: 'Metas e Gamificação', p: 'Acompanhe suas metas e ganhe pontos' },
    previsoes: { h1: 'Previsões Preditivas', p: '7 dias de previsões com IA' },
    'mobile-sync': { h1: 'Sincronização Mobile', p: 'Sincronize com seu app' }
  };

  const info = titles[viewName] || titles.dashboard;
  const titleEl = document.getElementById('page-title');
  const subtitleEl = document.getElementById('page-subtitle');

  if (titleEl) titleEl.textContent = info.h1;
  if (subtitleEl) subtitleEl.textContent = info.p;
}

// ═════════════════════════════════════════════════════════════════════════════
// GAUGES
// ═════════════════════════════════════════════════════════════════════════════

function criarGauges() {
  console.log('Criando gauges...');

  // Gauge Temperatura
  window.chartesGauges.temp = new Chart(
    document.getElementById('gauge-temp-realtime'),
    {
      type: 'doughnut',
      data: {
        datasets: [{
          data: [0, 60],
          backgroundColor: ['#ff7043', '#1a3a24'],
          borderWidth: 0,
          circumference: 240,
          rotation: -120
        }]
      },
      options: {
        cutout: '72%',
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: { display: false },
          tooltip: { enabled: false }
        }
      },
      plugins: [{
        id: 'gaugeTextTemp',
        afterDraw(chart) {
          const { ctx, chartArea: { top, bottom, left, right }, data } = chart;
          const cx = (left + right) / 2;
          const cy = (top + bottom) / 2 + 18;
          const val = data.datasets[0].data[0];
          ctx.save();
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillStyle = '#ff7043';
          ctx.font = 'bold 32px Segoe UI';
          ctx.fillText(val.toFixed(1), cx, cy);
          ctx.font = 'bold 14px Segoe UI';
          ctx.fillText('°C', cx, cy + 24);
          ctx.restore();
        }
      }]
    }
  );

  // Gauge Umidade
  window.chartesGauges.umid = new Chart(
    document.getElementById('gauge-umid-realtime'),
    {
      type: 'doughnut',
      data: {
        datasets: [{
          data: [0, 100],
          backgroundColor: ['#29b6f6', '#1a3a24'],
          borderWidth: 0,
          circumference: 240,
          rotation: -120
        }]
      },
      options: {
        cutout: '72%',
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: { display: false },
          tooltip: { enabled: false }
        }
      },
      plugins: [{
        id: 'gaugeTextUmid',
        afterDraw(chart) {
          const { ctx, chartArea: { top, bottom, left, right }, data } = chart;
          const cx = (left + right) / 2;
          const cy = (top + bottom) / 2 + 18;
          const val = data.datasets[0].data[0];
          ctx.save();
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillStyle = '#29b6f6';
          ctx.font = 'bold 32px Segoe UI';
          ctx.fillText(val.toFixed(0), cx, cy);
          ctx.font = 'bold 14px Segoe UI';
          ctx.fillText('%', cx, cy + 24);
          ctx.restore();
        }
      }]
    }
  );

  // Gauge Solo
  window.chartesGauges.solo = new Chart(
    document.getElementById('gauge-solo-realtime'),
    {
      type: 'doughnut',
      data: {
        datasets: [{
          data: [0, 100],
          backgroundColor: ['#66bb6a', '#1a3a24'],
          borderWidth: 0,
          circumference: 240,
          rotation: -120
        }]
      },
      options: {
        cutout: '72%',
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: { display: false },
          tooltip: { enabled: false }
        }
      },
      plugins: [{
        id: 'gaugeTextSolo',
        afterDraw(chart) {
          const { ctx, chartArea: { top, bottom, left, right }, data } = chart;
          const cx = (left + right) / 2;
          const cy = (top + bottom) / 2 + 18;
          const val = data.datasets[0].data[0];
          ctx.save();
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillStyle = '#66bb6a';
          ctx.font = 'bold 32px Segoe UI';
          ctx.fillText(val.toFixed(1), cx, cy);
          ctx.font = 'bold 14px Segoe UI';
          ctx.fillText('%', cx, cy + 24);
          ctx.restore();
        }
      }]
    }
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// GRÁFICO DE HISTÓRICO
// ═════════════════════════════════════════════════════════════════════════════

function criarGraficoHistorico() {
  const ctx = document.getElementById('chart-historico-realtime');
  if (!ctx) return;

  graficoHistorico = new Chart(ctx, {
    type: 'line',
    data: {
      labels: [],
      datasets: [
        {
          label: 'Temperatura (°C)',
          data: [],
          borderColor: '#ff7043',
          backgroundColor: 'rgba(255, 112, 67, 0.1)',
          tension: 0.4,
          fill: true,
          pointRadius: 4,
          pointHoverRadius: 6,
          pointBackgroundColor: '#ff7043'
        },
        {
          label: 'Umidade (%)',
          data: [],
          borderColor: '#29b6f6',
          backgroundColor: 'rgba(41, 182, 246, 0.1)',
          tension: 0.4,
          fill: true,
          pointRadius: 4,
          pointHoverRadius: 6,
          pointBackgroundColor: '#29b6f6'
        },
        {
          label: 'Solo (%)',
          data: [],
          borderColor: '#66bb6a',
          backgroundColor: 'rgba(102, 187, 106, 0.1)',
          tension: 0.4,
          fill: true,
          pointRadius: 4,
          pointHoverRadius: 6,
          pointBackgroundColor: '#66bb6a'
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: true,
      interaction: {
        mode: 'index',
        intersect: false
      },
      plugins: {
        legend: {
          labels: {
            color: '#9e9e9e',
            usePointStyle: true,
            padding: 20
          }
        },
        tooltip: {
          backgroundColor: '#1a2332',
          borderColor: '#66bb6a',
          borderWidth: 1,
          titleColor: '#e0e0e0',
          bodyColor: '#9e9e9e'
        }
      },
      scales: {
        x: {
          ticks: { color: '#7aad90' },
          grid: { color: '#1a3a24' }
        },
        y: {
          ticks: { color: '#7aad90' },
          grid: { color: '#1a3a24' }
        }
      }
    }
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// CARREGAR DADOS
// ═════════════════════════════════════════════════════════════════════════════

async function carregarDadosIniciais() {
  try {
    // Carregar histórico
    let historico;
    try {
      historico = await EstufaAPI.obterHistorico(20);
    } catch (e) {
      console.warn('Usando mock para histórico');
      historico = EstufaAPI.obterMockHistorico(20);
    }

    atualizarGraficoHistorico(historico);

  } catch (erro) {
    console.error('Erro ao carregar dados iniciais:', erro);
  }
}

function atualizarGraficoHistorico(dados) {
  if (!graficoHistorico || !Array.isArray(dados)) return;

  const labels = dados.map(d => {
    const data = new Date(d.coletadoEm);
    return `${data.getHours()}:${String(data.getMinutes()).padStart(2, '0')}`;
  });

  const temps = dados.map(d => d.temperatura);
  const umids = dados.map(d => d.umidade);
  const solos = dados.map(d => d.umidadeSolo);

  graficoHistorico.data.labels = labels;
  graficoHistorico.data.datasets[0].data = temps;
  graficoHistorico.data.datasets[1].data = umids;
  graficoHistorico.data.datasets[2].data = solos;
  graficoHistorico.update();
}

function carregarDadosView(viewName) {
  switch (viewName) {
    case 'mapa':
      carregarMapaVisual();
      break;
    case 'alerts':
      carregarAlertas();
      break;
    case 'comparativa':
      carregarComparativa();
      break;
    case 'calendario':
      carregarCalendario();
      break;
    case 'relatorios':
      carregarRelatorios();
      break;
    case 'gamificacao':
      carregarGamificacao();
      break;
    case 'previsoes':
      carregarPrevisoes();
      break;
    case 'mobile-sync':
      carregarMobileSync();
      break;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MAPA VISUAL
// ═════════════════════════════════════════════════════════════════════════════

function carregarMapaVisual() {
  const svg = document.getElementById('mapa-svg');
  if (!svg) return;

  const sensoresContainer = document.getElementById('sensores-container');
  if (!sensoresContainer) return;

  // Limpar
  sensoresContainer.innerHTML = '';

  // Criar zonas e sensores mock
  const sensores = [
    { id: 1, x: 150, y: 150, nome: 'Zona A', temp: 24.2, umid: 65 },
    { id: 2, x: 500, y: 150, nome: 'Zona B', temp: 23.8, umid: 63 },
    { id: 3, x: 850, y: 150, nome: 'Zona C', temp: 25.1, umid: 68 },
    { id: 4, x: 150, y: 400, nome: 'Zona D', temp: 22.9, umid: 64 },
    { id: 5, x: 500, y: 400, nome: 'Zona E (Central)', temp: 24.0, umid: 66 },
    { id: 6, x: 850, y: 400, nome: 'Zona F', temp: 24.3, umid: 67 }
  ];

  sensores.forEach(sensor => {
    const cor = EstufaUtils.obterCor('temperatura', sensor.temp);
    const g = document.createElementNS('http://www.w3.org/2000/svg', 'g');
    g.classList.add('sensor-svg');
    g.style.cursor = 'pointer';

    const circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
    circle.setAttribute('cx', sensor.x);
    circle.setAttribute('cy', sensor.y);
    circle.setAttribute('r', '20');
    circle.setAttribute('fill', cor);
    circle.style.transition = 'all 0.2s ease';

    const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
    text.setAttribute('x', sensor.x);
    text.setAttribute('y', sensor.y);
    text.setAttribute('text-anchor', 'middle');
    text.setAttribute('dy', '0.3em');
    text.setAttribute('fill', 'white');
    text.setAttribute('font-weight', 'bold');
    text.setAttribute('font-size', '12');
    text.textContent = sensor.id;

    g.appendChild(circle);
    g.appendChild(text);

    g.addEventListener('click', () => {
      // Mostrar detalhes
      const detailsEl = document.getElementById('sensor-details');
      if (detailsEl) {
        detailsEl.innerHTML = `
          <h3>${sensor.nome}</h3>
          <div class="sensor-info">
            <div><strong>Temperatura:</strong> ${sensor.temp}°C</div>
            <div><strong>Umidade:</strong> ${sensor.umid}%</div>
            <div style="margin-top: 12px;">
              <button class="btn-secondary" style="padding: 6px 12px; font-size: 12px;">Ver Histórico</button>
            </div>
          </div>
        `;
      }

      // Highlight
      sensoresContainer.querySelectorAll('.sensor-svg circle').forEach(c => {
        c.style.filter = 'drop-shadow(0 0 0 rgba(0,0,0,0))';
      });
      circle.style.filter = 'drop-shadow(0 0 8px #90caf9)';
    });

    g.addEventListener('mouseenter', () => {
      circle.style.filter = 'drop-shadow(0 0 4px currentColor)';
      circle.setAttribute('r', '25');
    });

    g.addEventListener('mouseleave', () => {
      if (circle.style.filter === 'drop-shadow(0 0 8px #90caf9)') return;
      circle.style.filter = 'drop-shadow(0 0 0 rgba(0,0,0,0))';
      circle.setAttribute('r', '20');
    });

    sensoresContainer.appendChild(g);
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// ALERTAS
// ═════════════════════════════════════════════════════════════════════════════

function carregarAlertas() {
  const timelineEl = document.getElementById('timeline-alerts');
  if (!timelineEl) return;

  // Dados mock
  const alertas = [
    {
      titulo: 'Temperatura elevada',
      desc: 'Temperatura atingiu 28.5°C em Zona C',
      tipo: 'danger',
      hora: '14:32',
      acao: 'Ventilador acionado automaticamente'
    },
    {
      titulo: 'Umidade acima do ideal',
      desc: 'Umidade em 72% na Zona E',
      tipo: 'warning',
      hora: '14:15',
      acao: 'Nenhuma ação necessária'
    },
    {
      titulo: 'Solo seco detectado',
      desc: 'Umidade do solo em 35% na Zona D',
      tipo: 'danger',
      hora: '13:58',
      acao: 'Sistema de irrigação iniciado por 5 minutos'
    },
    {
      titulo: 'Condições normalizadas',
      desc: 'Todos os parâmetros em faixa ideal',
      tipo: 'success',
      hora: '13:45',
      acao: 'Sistema retornou ao modo automático'
    }
  ];

  timelineEl.innerHTML = alertas.map(a => `
    <div class="timeline-item ${a.tipo}">
      <div class="timeline-icon">${a.tipo === 'danger' ? '⚠️' : a.tipo === 'warning' ? '⏱️' : '✅'}</div>
      <div class="timeline-content">
        <div class="timeline-title">${a.titulo}</div>
        <div class="timeline-desc">${a.desc}</div>
        <div class="timeline-meta">
          <span class="timeline-time">${a.hora}</span>
          <span>Ação: ${a.acao}</span>
        </div>
      </div>
    </div>
  `).join('');
}

// ═════════════════════════════════════════════════════════════════════════════
// COMPARATIVA
// ═════════════════════════════════════════════════════════════════════════════

function carregarComparativa() {
  // Tabs
  const tabs = document.querySelectorAll('.comparativa-tabs .tab-btn');
  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      const tabName = tab.dataset.tab;

      // Remover active
      tabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');

      // Mostrar conteúdo
      document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
      const content = document.querySelector(`.tab-content[data-tab="${tabName}"]`);
      if (content) content.classList.add('active');

      // Carregar dados específicos
      if (tabName === 'vs-outros') {
        criarGraficoComparativoOutros();
      }
    });
  });

  // Gráfico padrão
  criarGraficoComparativoHistorico();
}

function criarGraficoComparativoHistorico() {
  const canvas = document.getElementById('chart-comparativa-historico');
  if (!canvas) return;

  new Chart(canvas, {
    type: 'bar',
    data: {
      labels: ['Semana Passada', 'Semana Atual'],
      datasets: [
        {
          label: 'Temperatura Média (°C)',
          data: [23.5, 24.2],
          backgroundColor: '#ff7043'
        },
        {
          label: 'Umidade Média (%)',
          data: [64, 66],
          backgroundColor: '#29b6f6'
        },
        {
          label: 'Produtividade Estimada',
          data: [87, 92],
          backgroundColor: '#66bb6a'
        }
      ]
    },
    options: {
      responsive: true,
      plugins: {
        legend: { labels: { color: '#9e9e9e' } }
      },
      scales: {
        x: { ticks: { color: '#7aad90' }, grid: { color: '#1a3a24' } },
        y: { ticks: { color: '#7aad90' }, grid: { color: '#1a3a24' } }
      }
    }
  });
}

function criarGraficoComparativoOutros() {
  const canvas = document.getElementById('chart-comparativa-outros');
  if (!canvas) return;

  new Chart(canvas, {
    type: 'radar',
    data: {
      labels: ['Temperatura', 'Umidade', 'Solo', 'Luz', 'CO₂', 'Eficiência'],
      datasets: [
        {
          label: 'Sua Estufa',
          data: [92, 88, 85, 90, 87, 89],
          borderColor: '#66bb6a',
          backgroundColor: 'rgba(102, 187, 106, 0.1)'
        },
        {
          label: 'Média de Mercado',
          data: [85, 80, 78, 82, 79, 81],
          borderColor: '#9e9e9e',
          backgroundColor: 'rgba(158, 158, 158, 0.05)'
        }
      ]
    },
    options: {
      responsive: true,
      plugins: {
        legend: { labels: { color: '#9e9e9e' } }
      },
      scales: {
        r: {
          ticks: { color: '#7aad90' },
          grid: { color: '#1a3a24' }
        }
      }
    }
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// CALENDÁRIO
// ═════════════════════════════════════════════════════════════════════════════

function carregarCalendario() {
  const vizEl = document.getElementById('calendar-visualization');
  if (!vizEl) return;

  // Timeline visual
  vizEl.innerHTML = `
    <div style="display: flex; flex-direction: column; gap: 20px;">
      <div style="display: flex; align-items: center; gap: 8px;">
        <div style="width: 40px; height: 40px; background: #66bb6a; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold;">1</div>
        <div>
          <div style="font-weight: 600;">Plantio</div>
          <div style="font-size: 12px; color: var(--text-secondary);">Dia 1-3</div>
        </div>
        <div style="flex: 1; height: 2px; background: #66bb6a; margin: 0 16px;"></div>
      </div>
      <div style="display: flex; align-items: center; gap: 8px;">
        <div style="width: 40px; height: 40px; background: #4fc3f7; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold;">2</div>
        <div>
          <div style="font-weight: 600;">Crescimento</div>
          <div style="font-size: 12px; color: var(--text-secondary);">Dia 4-20</div>
        </div>
        <div style="flex: 1; height: 2px; background: #4fc3f7; margin: 0 16px;"></div>
      </div>
      <div style="display: flex; align-items: center; gap: 8px;">
        <div style="width: 40px; height: 40px; background: #fdd835; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold;">3</div>
        <div>
          <div style="font-weight: 600;">Amadurecimento</div>
          <div style="font-size: 12px; color: var(--text-secondary);">Dia 21-35</div>
        </div>
        <div style="flex: 1; height: 2px; background: #fdd835; margin: 0 16px;"></div>
      </div>
      <div style="display: flex; align-items: center; gap: 8px;">
        <div style="width: 40px; height: 40px; background: #ff7043; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold;">4</div>
        <div>
          <div style="font-weight: 600;">Colheita</div>
          <div style="font-size: 12px; color: var(--text-secondary);">Dia 36-40</div>
        </div>
      </div>
    </div>
  `;

  // Marcos
  const marcosEl = document.getElementById('marcos-list');
  if (marcosEl) {
    marcosEl.innerHTML = `
      <div class="marco-item">
        <div class="marco-date">📅 Dia 1</div>
        <div class="marco-desc">Plantio realizado - 50 mudas</div>
      </div>
      <div class="marco-item">
        <div class="marco-date">📅 Dia 10 (próximo)</div>
        <div class="marco-desc">Próximo check-up de crescimento</div>
      </div>
      <div class="marco-item">
        <div class="marco-date">📅 Dia 35</div>
        <div class="marco-desc">Estimativa: início da colheita</div>
      </div>
    `;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// RELATÓRIOS
// ═════════════════════════════════════════════════════════════════════════════

function carregarRelatorios() {
  // Botões de ação
  const btnGerar = document.getElementById('btn-gerar-relatorio');
  const btnEmail = document.getElementById('btn-enviar-email');
  const btnPdf = document.getElementById('btn-exportar-pdf');

  if (btnGerar) {
    btnGerar.addEventListener('click', () => {
      EstufaUtils.mostrarAlerta('Relatório gerado com sucesso!', 'success');
    });
  }

  if (btnEmail) {
    btnEmail.addEventListener('click', () => {
      EstufaUtils.mostrarAlerta('Relatório enviado para seu e-mail!', 'success');
    });
  }

  if (btnPdf) {
    btnPdf.addEventListener('click', () => {
      EstufaUtils.mostrarAlerta('PDF baixado!', 'success');
    });
  }

  // Histórico
  const listaEl = document.getElementById('relatorios-list');
  if (listaEl) {
    listaEl.innerHTML = `
      <div class="relatorio-item">
        <div>
          <div style="font-weight: 600;">Relatório Semanal - Semana 20</div>
          <div class="relatorio-date">17-23 mai 2026</div>
        </div>
        <div class="relatorio-actions">
          <button class="relatorio-action">📥 Baixar</button>
          <button class="relatorio-action">📧 E-mail</button>
        </div>
      </div>
      <div class="relatorio-item">
        <div>
          <div style="font-weight: 600;">Relatório Semanal - Semana 19</div>
          <div class="relatorio-date">10-16 mai 2026</div>
        </div>
        <div class="relatorio-actions">
          <button class="relatorio-action">📥 Baixar</button>
          <button class="relatorio-action">📧 E-mail</button>
        </div>
      </div>
    `;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// GAMIFICAÇÃO
// ═════════════════════════════════════════════════════════════════════════════

function carregarGamificacao() {
  // Já está carregado no HTML estático
  console.log('Gamificação carregada');
}

// ═════════════════════════════════════════════════════════════════════════════
// PREVISÕES
// ═════════════════════════════════════════════════════════════════════════════

function carregarPrevisoes() {
  // Gráfico previsão temperatura
  criarGraficoPrevisao('chart-previsao-temp', 'Temperatura (°C)', '#ff7043');

  // Gráfico previsão umidade
  criarGraficoPrevisao('chart-previsao-umid', 'Umidade (%)', '#29b6f6');

  // Gráfico previsão solo
  criarGraficoPrevisao('chart-previsao-solo', 'Umidade Solo (%)', '#66bb6a');
}

function criarGraficoPrevisao(canvasId, label, cor) {
  const canvas = document.getElementById(canvasId);
  if (!canvas) return;

  const dias = ['Hoje', 'Amanhã', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
  const dados = [24, 23.5, 25.2, 24.8, 26.1, 25.5, 24.2];
  const min = [22, 21.5, 23.2, 22.8, 24.1, 23.5, 22.2];
  const max = [26, 25.5, 27.2, 26.8, 28.1, 27.5, 26.2];

  new Chart(canvas, {
    type: 'line',
    data: {
      labels: dias,
      datasets: [
        {
          label: label,
          data: dados,
          borderColor: cor,
          backgroundColor: `${cor}22`,
          fill: true,
          tension: 0.4,
          pointRadius: 5,
          pointHoverRadius: 7,
          pointBackgroundColor: cor
        },
        {
          label: 'Mínima',
          data: min,
          borderColor: `${cor}88`,
          borderDash: [5, 5],
          borderWidth: 1,
          fill: false,
          pointRadius: 0
        },
        {
          label: 'Máxima',
          data: max,
          borderColor: `${cor}88`,
          borderDash: [5, 5],
          borderWidth: 1,
          fill: false,
          pointRadius: 0
        }
      ]
    },
    options: {
      responsive: true,
      plugins: {
        legend: { labels: { color: '#9e9e9e' } }
      },
      scales: {
        x: { ticks: { color: '#7aad90' }, grid: { color: '#1a3a24' } },
        y: { ticks: { color: '#7aad90' }, grid: { color: '#1a3a24' } }
      }
    }
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// MOBILE SYNC
// ═════════════════════════════════════════════════════════════════════════════

function carregarMobileSync() {
  // Já carregado no HTML
  console.log('Mobile sync carregado');
}

// ═════════════════════════════════════════════════════════════════════════════
// EVENTOS
// ═════════════════════════════════════════════════════════════════════════════

function atarEventos() {
  // Controles de período do gráfico
  const periodBtns = document.querySelectorAll('.chart-period');
  periodBtns.forEach(btn => {
    btn.addEventListener('click', async () => {
      periodBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      // Recarregar dados
      const periodo = btn.dataset.period;
      console.log('Mudando período para:', periodo);

      // Aqui você carregaria dados diferentes baseado no período
      try {
        let historico;
        try {
          historico = await EstufaAPI.obterHistorico(100);
        } catch (e) {
          historico = EstufaAPI.obterMockHistorico(100);
        }
        atualizarGraficoHistorico(historico);
      } catch (erro) {
        console.error('Erro ao atualizar período:', erro);
      }
    });
  });

  // Filtros de alertas
  const filterBtns = document.querySelectorAll('.filter-btn');
  filterBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      filterBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      const filtro = btn.dataset.filter;
      console.log('Filtrando por:', filtro);
      // Aqui você filtraria os alertas
    });
  });
}
