const DEFAULT_API_BASE = 'http://localhost:8080';
let apiBaseUrl = localStorage.getItem('estufa_api_base') || DEFAULT_API_BASE;
const statusText = {
  healthy: 'OK',
  warning: 'Atenção',
  critical: 'Crítico'
};

const elements = {
  apiInput: null,
  apiLink: null,
  statusMain: null,
  updatedAt: null,
  issues: null,
  serialStatus: null,
  apiStatus: null,
  activeIssues: null,
  riskScore: null,
  serialProblems: null,
  serialNormality: null,
  serialFuture: null,
  serialTable: null,
  serialForecast: null,
  apiProblems: null,
  apiNormality: null,
  apiFuture: null,
  apiAlertsBody: null,
  apiUptime: null,
  apiTotalReadings: null,
  apiCriticalCount: null,
  apiAlertCount: null,
  overallStatus: null,
  pendingIssues: null,
};

const niceDate = (isoString) => {
  if (!isoString) return '--';
  const d = new Date(isoString);
  return d.toLocaleString('pt-BR', { hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit' });
};

const clamp = (value, min, max) => Math.max(min, Math.min(max, value));

const buildStatusBadge = (score) => {
  if (score >= 80) return `<span class="badge success">${statusText.healthy}</span>`;
  if (score >= 55) return `<span class="badge warning">${statusText.warning}</span>`;
  return `<span class="badge danger">${statusText.critical}</span>`;
};

const detectReadingRisk = (reading) => {
  const issues = [];
  const risk = { score: 100, labels: [] };
  if (reading.temperatura < 16 || reading.temperatura > 32) {
    risk.score -= 40;
    issues.push('Temperatura fora do range seguro');
  } else if (reading.temperatura < 18 || reading.temperatura > 28) {
    risk.score -= 18;
    issues.push('Temperatura fora do ideal');
  }

  if (reading.umidade < 35 || reading.umidade > 88) {
    risk.score -= 35;
    issues.push('Umidade do ar fora de controle');
  } else if (reading.umidade < 40 || reading.umidade > 75) {
    risk.score -= 15;
    issues.push('Umidade do ar em limiar de alerta');
  }

  if (reading.umidadeSolo === null || reading.umidadeSolo === undefined) {
    risk.score -= 12;
    issues.push('Umidade do solo não informada');
  } else if (reading.umidadeSolo < 28 || reading.umidadeSolo > 78) {
    risk.score -= 25;
    issues.push('Solo fora da faixa segura');
  } else if (reading.umidadeSolo < 35 || reading.umidadeSolo > 70) {
    risk.score -= 12;
    issues.push('Solo perto do limite');
  }

  risk.score = clamp(risk.score, 0, 100);
  risk.labels = issues;
  return risk;
};

const createStatusText = (health, apiHealthy) => {
  if (!health || !apiHealthy) return 'Crítico';
  if (health >= 70 && apiHealthy) return 'OK';
  if (health >= 45) return 'Atenção';
  return 'Crítico';
};

const setApiBaseUrl = () => {
  const input = elements.apiInput.value.trim();
  apiBaseUrl = input || DEFAULT_API_BASE;
  localStorage.setItem('estufa_api_base', apiBaseUrl);
  elements.apiLink.innerHTML = `API: <strong>${apiBaseUrl}</strong>`;
  refreshAll();
};

const resetApiBaseUrl = () => {
  apiBaseUrl = DEFAULT_API_BASE;
  localStorage.setItem('estufa_api_base', apiBaseUrl);
  elements.apiInput.value = apiBaseUrl;
  elements.apiLink.innerHTML = `API: <strong>${apiBaseUrl}</strong>`;
  refreshAll();
};

const fetchJson = async (path) => {
  const response = await fetch(`${apiBaseUrl}${path}`);
  if (!response.ok) throw new Error(`${response.status} ${response.statusText}`);
  return response.json();
};

const buildIssueLines = (list, limit = 4) => {
  if (!list || !list.length) return 'Nenhum alerta crítico recente.';
  return list.slice(0, limit).map((item) => {
    const time = item.geradoEm || item.coletadoEm || item.data || 'sem data';
    const type = item.tipo || item.severidade || 'ALERTA';
    return `• ${niceDate(time)} — ${type}: ${item.mensagem || item.significado || 'Sem descrição'}`;
  }).join('<br>');
};

const renderAlertRows = (alerts) => {
  if (!alerts || !alerts.length) {
    elements.apiAlertsBody.innerHTML = '<tr><td colspan="4">Nenhum alerta encontrado.</td></tr>';
    return;
  }
  elements.apiAlertsBody.innerHTML = alerts.slice(0, 15).map((alert) => {
    const data = niceDate(alert.geradoEm);
    return `<tr>
      <td>${data}</td>
      <td>${alert.tipo || 'Sensor'}</td>
      <td>${alert.severidade || 'N/A'}</td>
      <td>${alert.mensagem || alert.significado || 'Sem mensagem'}</td>
    </tr>`;
  }).join('');
};

const renderSerialTable = (readings) => {
  if (!readings || !readings.length) {
    elements.serialTable.innerHTML = '<tr><td colspan="5">Nenhuma leitura disponível.</td></tr>';
    return;
  }
  elements.serialTable.innerHTML = readings.slice(0, 12).map((reading) => {
    const risk = detectReadingRisk(reading);
    const badge = buildStatusBadge(risk.score);
    return `<tr>
      <td>${niceDate(reading.coletadoEm)}</td>
      <td>${reading.temperatura?.toFixed(1)} ºC</td>
      <td>${reading.umidade?.toFixed(1)} %</td>
      <td>${reading.umidadeSolo != null ? reading.umidadeSolo.toFixed(1) + ' %' : 'N/A'}</td>
      <td>${badge}</td>
    </tr>`;
  }).join('');
};

const buildReadingSummary = (latest) => {
  const risk = detectReadingRisk(latest);
  if (!latest) return 'Nenhuma leitura disponível para análise.';
  if (!risk.labels.length) return 'Condicões normais; mantenha monitoramento contínuo.';
  return [`Resultado: score ${risk.score}/100.`, 'Possíveis problemas:', ...risk.labels].join(' ');
};

const buildAnalysisText = (latest, alertCount) => {
  if (!latest) return 'Nenhum registro de leitura para calcular risco.';
  const risk = detectReadingRisk(latest);
  const lines = [];
  if (risk.score >= 80) {
    lines.push('O hardware está saudável e a maior parte das leituras está dentro dos limites esperados.');
  } else if (risk.score >= 55) {
    lines.push('Algumas medições estão fora do ideal. Atenção a possíveis flutuações de ambiente.');
  } else {
    lines.push('Risco elevado: o monitor serial indica instabilidade ou falha iminente.');
  }
  if (alertCount.criticos > 0) {
    lines.push(`Há ${alertCount.criticos} alertas críticos recentes; trate-os como prioridade.`);
  }
  if (latest.umidadeSolo == null) {
    lines.push('O sensor de umidade do solo não retornou dados recentemente, verifique o cabo ou a leitura do módulo.');
  }
  return lines.join(' ');
};

const refreshAll = async () => {
  elements.serialStatus.textContent = 'Carregando...';
  elements.apiStatus.textContent = 'Carregando...';
  elements.activeIssues.textContent = '...';
  elements.lastUpdated.textContent = '...';
  try {
    const [pingData, alertCount, alerts, sensorReadings] = await Promise.all([
      fetchJson('/api/ping'),
      fetchJson('/api/alertas/count?horas=24'),
      fetchJson('/api/alertas'),
      fetchJson('/api/dados?page=0&size=20&ordem=desc')
    ]);

    const latestReading = sensorReadings && sensorReadings.length ? sensorReadings[0] : null;
    const readingRisk = latestReading ? detectReadingRisk(latestReading).score : 35;
    const apiHealthy = pingData && pingData.status === 'ok';
    const overall = createStatusText(readingRisk, apiHealthy);

    elements.overallStatus.textContent = overall;
    elements.pendingIssues.textContent = alertCount.total;
    elements.lastUpdated.textContent = new Date().toLocaleTimeString('pt-BR');

    elements.apiLink.innerHTML = `API: <strong>${apiBaseUrl}</strong>`;
    elements.serialStatus.innerHTML = buildStatusBadge(readingRisk);
    elements.apiStatus.innerHTML = apiHealthy ? buildStatusBadge(90) : buildStatusBadge(20);
    elements.activeIssues.textContent = `${alertCount.total} alertas, ${alertCount.criticos} críticos`;
    elements.riskScore.textContent = `${clamp(Math.round((100 + readingRisk) / 2), 0, 100)} / 100`;

    elements.serialProblems.innerHTML = latestReading
      ? buildReadingSummary(latestReading)
      : 'Nenhuma leitura recebida recentemente.';
    elements.serialNormality.textContent = latestReading
      ? (detectReadingRisk(latestReading).score >= 70 ? 'Sensores estáveis e medição dentro do esperado.' : 'Alguma leitura está fora do limiar ideal.')
      : 'Sem dados suficientes.';
    elements.serialFuture.textContent = latestReading
      ? `Risco de falha ${latestReading.temperatura > 30 || latestReading.umidade > 80 ? 'alto' : 'moderado'} se as condições permanecerem.`
      : 'Aguardando primeira leitura.';

    elements.apiProblems.textContent = alertCount.criticos > 0
      ? `Existem ${alertCount.criticos} alertas críticos de backend.`
      : 'Sem alertas críticos recentes.';
    elements.apiNormality.textContent = apiHealthy
      ? 'API respondendo e em operação.'
      : 'Falha de conexão ou resposta lenta detectada.';
    elements.apiFuture.textContent = apiHealthy && alertCount.total < 10
      ? 'Boa estabilidade esperada nas próximas horas.'
      : 'Observe a frequência de alertas e verifique os endpoints.';

    renderSerialTable(sensorReadings);
    renderAlertRows(alerts);

    elements.apiUptime.textContent = pingData?.uptimeMinutos != null ? `${pingData.uptimeMinutos} min` : 'N/A';
    elements.apiTotalReadings.textContent = pingData?.totalLeituras != null ? `${pingData.totalLeituras}` : 'N/A';
    elements.apiCriticalCount.textContent = alertCount.criticos;
    elements.apiAlertCount.textContent = alertCount.total;
    elements.serialForecast.innerHTML = buildAnalysisText(latestReading, alertCount);
  } catch (error) {
    elements.overallStatus.textContent = 'Erro';
    elements.serialStatus.textContent = 'Erro';
    elements.apiStatus.textContent = 'Erro';
    elements.serialProblems.textContent = `Falha ao conectar: ${error.message}`;
    elements.apiProblems.textContent = `Falha ao conectar: ${error.message}`;
    elements.apiAlertsBody.innerHTML = '<tr><td colspan="4">Erro ao carregar alertas.</td></tr>';
    elements.serialTable.innerHTML = '<tr><td colspan="5">Erro ao carregar leituras.</td></tr>';
  }
};

const activateTab = (tab) => {
  document.querySelectorAll('.tab-button').forEach((button) => {
    button.classList.toggle('active', button.dataset.tab === tab);
  });
  document.querySelectorAll('.view').forEach((section) => {
    section.classList.toggle('active', section.id === `view-${tab}`);
  });
};

const init = () => {
  elements.apiInput = document.getElementById('api-base-url');
  elements.apiLink = document.getElementById('api-link');
  elements.statusMain = document.getElementById('status-main');
  elements.updatedAt = document.getElementById('last-updated');
  elements.issues = document.getElementById('pending-issues');
  elements.serialStatus = document.getElementById('serial-status');
  elements.apiStatus = document.getElementById('api-status');
  elements.activeIssues = document.getElementById('active-issues');
  elements.riskScore = document.getElementById('risk-score');
  elements.serialProblems = document.getElementById('serial-problems');
  elements.serialNormality = document.getElementById('serial-normality');
  elements.serialFuture = document.getElementById('serial-future');
  elements.serialTable = document.getElementById('serial-table-body');
  elements.serialForecast = document.getElementById('serial-forecast');
  elements.apiProblems = document.getElementById('api-problems');
  elements.apiNormality = document.getElementById('api-normality');
  elements.apiFuture = document.getElementById('api-future');
  elements.apiAlertsBody = document.getElementById('api-alerts-body');
  elements.apiUptime = document.getElementById('api-uptime');
  elements.apiTotalReadings = document.getElementById('api-total-readings');
  elements.apiCriticalCount = document.getElementById('api-critical-count');
  elements.apiAlertCount = document.getElementById('api-alert-count');
  elements.overallStatus = document.getElementById('overall-status');
  elements.pendingIssues = document.getElementById('pending-issues');

  elements.apiInput.value = apiBaseUrl;
  elements.apiLink.innerHTML = `API: <strong>${apiBaseUrl}</strong>`;

  document.querySelectorAll('.tab-button').forEach((button) => {
    button.addEventListener('click', () => activateTab(button.dataset.tab));
  });

  document.getElementById('btn-save-url').addEventListener('click', setApiBaseUrl);
  document.getElementById('btn-reset-url').addEventListener('click', resetApiBaseUrl);
  document.getElementById('btn-refresh').addEventListener('click', refreshAll);

  refreshAll();
  setInterval(refreshAll, 15000);
};

window.addEventListener('DOMContentLoaded', init);
