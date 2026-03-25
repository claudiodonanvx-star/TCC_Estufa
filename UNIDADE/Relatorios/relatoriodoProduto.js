const authRaw = localStorage.getItem('estufaAuth');
if (!authRaw) {
  window.location.href = 'login.html';
}

const API_CANDIDATES = [
    localStorage.getItem('estufaApiBase'),
    `http://${window.location.hostname || 'localhost'}:7002/api`,
    'http://localhost:7002/api',
    'http://127.0.0.1:7002/api',
    'http://143.106.241.4:7002/api'
  ].filter(Boolean);

  let API_BASE_ATIVA = API_CANDIDATES[0] || 'http://localhost:7002/api';

  function atualizarMensagemStatus(texto, alerta = false) {
    const badge = document.getElementById('badge-status');
    badge.textContent = texto;
    badge.className = alerta ? 'alerta' : '';
  }

  async function buscarDadosComFallback() {
    for (const base of API_CANDIDATES) {
      try {
        const res = await fetch(`${base}/dados`);
        if (!res.ok) continue;
        const lista = await res.json();
        if (!Array.isArray(lista)) continue;
        API_BASE_ATIVA = base;
        localStorage.setItem('estufaApiBase', base);
        return lista;
      } catch (_) {
      }
    }
    throw new Error('Não foi possível conectar em nenhuma API');
  }

  /* ── Gauges ── */
  function criarGauge(id, max, cor) {
    return new Chart(document.getElementById(id), {
      type: 'doughnut',
      data: {
        datasets: [{
          data: [0, max],
          backgroundColor: [cor, '#1a3a24'],
          borderWidth: 0,
          circumference: 240,
          rotation: -120
        }]
      },
      options: {
        cutout: '72%',
        plugins: {
          legend: { display: false },
          tooltip: { enabled: false }
        }
      },
      plugins: [{
        id: 'gaugeText',
        afterDraw(chart) {
          const { ctx, chartArea: { top, bottom, left, right } } = chart;
          const cx = (left + right) / 2;
          const cy = (top + bottom) / 2 + 18;
          const val = chart.data.datasets[0].data[0];
          ctx.save();
          ctx.textAlign = 'center';
          ctx.fillStyle = cor;
          ctx.font = 'bold 28px Segoe UI';
          ctx.fillText(val.toFixed(1), cx, cy);
          ctx.restore();
        }
      }]
    });
  }

  const gaugeTemp = criarGauge('gauge-temp', 60, '#ff7043');
  const gaugeUmid = criarGauge('gauge-umid', 100, '#29b6f6');
  const gaugeSolo = criarGauge('gauge-solo', 100, '#66bb6a');

  function atualizarGauge(gauge, valor, max) {
    gauge.data.datasets[0].data = [valor, Math.max(0, max - valor)];
    gauge.update();
  }

  /* ── Gráfico histórico ── */
  const ctxHist = document.getElementById('grafico-historico').getContext('2d');
  const graficoHist = new Chart(ctxHist, {
    type: 'line',
    data: {
      labels: [],
      datasets: [
        {
          label: 'Temperatura (°C)',
          data: [], borderColor: '#ff7043', backgroundColor: 'rgba(255,112,67,.12)',
          tension: .4, fill: true, pointRadius: 3
        },
        {
          label: 'Umidade (%)',
          data: [], borderColor: '#29b6f6', backgroundColor: 'rgba(41,182,246,.12)',
          tension: .4, fill: true, pointRadius: 3
        },
        {
          label: 'Solo (%)',
          data: [], borderColor: '#66bb6a', backgroundColor: 'rgba(102,187,106,.12)',
          tension: .4, fill: true, pointRadius: 3
        }
      ]
    },
    options: {
      responsive: true,
      plugins: {
        legend: { labels: { color: '#9ecfb0' } }
      },
      scales: {
        x: { ticks: { color: '#7aad90' }, grid: { color: '#1a3a24' } },
        y: { ticks: { color: '#7aad90' }, grid: { color: '#1a3a24' } }
      }
    }
  });

  /* ── Pill de status ── */
  function pillClass(sig) {
    if (!sig) return 'pill-ok';
    const s = sig.toLowerCase();
    if (s.includes('ideal') && !s.includes('abaixo') && !s.includes('acima')) return 'pill-ok';
    if (s.includes('abaixo') || s.includes('acima')) return 'pill-bad';
    return 'pill-warn';
  }

  /* ── Preenche cards do último registro ── */
  function preencherUltimoRegistro(lista) {
      if (!lista || lista.length === 0) {
        atualizarMensagemStatus('Sem registros', true);
        return;
      }

      const ordenada = [...lista].sort((a, b) => (a.id ?? 0) - (b.id ?? 0));
      const { id: _, ...d } = ordenada[ordenada.length - 1];

      document.getElementById('val-temp').textContent = (d.temperatura ?? 0).toFixed(1);
      document.getElementById('val-umid').textContent = (d.umidade ?? 0).toFixed(1);
      document.getElementById('val-solo').textContent = (d.umidadeSolo ?? 0).toFixed(2);
      document.getElementById('val-sig').textContent = d.significado ?? '–';

      atualizarGauge(gaugeTemp, d.temperatura ?? 0, 60);
      atualizarGauge(gaugeUmid, d.umidade ?? 0, 100);
      atualizarGauge(gaugeSolo, d.umidadeSolo ?? 0, 100);

      const temAlerta = (d.significado ?? '').toLowerCase().includes('abaixo') ||
                        (d.significado ?? '').toLowerCase().includes('acima');
      atualizarMensagemStatus(d.significado ?? 'Sem status', temAlerta);

      const cardSolo = document.getElementById('card-solo');
      cardSolo.className = temAlerta ? 'card alerta' : 'card';

      document.getElementById('ultima-atualizacao').textContent = new Date().toLocaleTimeString('pt-BR');
  }

  /* ── Preenche histórico ── */
  function preencherHistorico(lista) {
      const ultimos = lista.slice(-15);

      graficoHist.data.labels = ultimos.map((_, i) => `#${i + 1}`);
      graficoHist.data.datasets[0].data = ultimos.map(d => d.temperatura ?? 0);
      graficoHist.data.datasets[1].data = ultimos.map(d => d.umidade ?? 0);
      graficoHist.data.datasets[2].data = ultimos.map(d => d.umidadeSolo ?? 0);
      graficoHist.update();

      const tbody = document.getElementById('tbody-tabela');
      const recentes = lista.slice(-10).reverse();
      if (recentes.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;color:#3a6b4a">Sem dados no momento</td></tr>';
        return;
      }
      tbody.innerHTML = recentes.map((d, i) => `
        <tr>
          <td>${recentes.length - i}</td>
          <td>${(d.temperatura ?? 0).toFixed(1)}</td>
          <td>${(d.umidade ?? 0).toFixed(1)}</td>
          <td>${(d.umidadeSolo ?? 0).toFixed(2)}</td>
          <td><span class="pill ${pillClass(d.significado)}">${d.significado ?? '–'}</span></td>
        </tr>
      `).join('');
  }

  async function carregarRelatorio() {
    try {
      const lista = await buscarDadosComFallback();
      preencherUltimoRegistro(lista);
      preencherHistorico(lista);
    } catch (e) {
      console.error('Erro ao carregar relatório:', e);
      atualizarMensagemStatus('API offline', true);
      document.getElementById('ultima-atualizacao').textContent = 'Falha na conexão';
      const tbody = document.getElementById('tbody-tabela');
      tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;color:#ff9e9e">Não foi possível carregar os dados da API</td></tr>';
    }
  }

  /* ── Init ── */
  carregarRelatorio();
  setInterval(carregarRelatorio, 5000);