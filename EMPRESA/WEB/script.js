const STORAGE_API = 'estufa_empresa_api_base';
const STORAGE_TOKEN = 'estufa_empresa_token';

const refs = {
  apiBase: document.getElementById('apiBase'),
  apiStatus: document.getElementById('apiStatus'),
  userInfo: document.getElementById('userInfo'),
  loginOverlay: document.getElementById('loginOverlay'),
  loginStatus: document.getElementById('loginStatus'),
  toast: document.getElementById('toast'),
  kpiLeads: document.getElementById('kpiLeads'),
  kpiClientes: document.getElementById('kpiClientes'),
  kpiContratos: document.getElementById('kpiContratos'),
  kpiUnidades: document.getElementById('kpiUnidades'),
  kpiAtividades: document.getElementById('kpiAtividades'),
  kpiFollowup: document.getElementById('kpiFollowup'),
  leadsBody: document.getElementById('leadsBody'),
  clientesBody: document.getElementById('clientesBody'),
  contratosBody: document.getElementById('contratosBody'),
  unidadesBody: document.getElementById('unidadesBody'),
  atividadesList: document.getElementById('atividadesList'),
  usuariosBody: document.getElementById('usuariosBody'),
  contratoCliente: document.getElementById('contratoCliente'),
  unidadeContrato: document.getElementById('unidadeContrato'),
  vinculoContrato: document.getElementById('vinculoContrato'),
  vinculoUnidade: document.getElementById('vinculoUnidade'),
  atividadeUnidade: document.getElementById('atividadeUnidade')
};

let currentUser = null;

const getApiBase = () => (localStorage.getItem(STORAGE_API) || 'http://localhost:8080').replace(/\/$/, '');
const getToken = () => localStorage.getItem(STORAGE_TOKEN);

function setToken(token) {
  if (token) localStorage.setItem(STORAGE_TOKEN, token);
  else localStorage.removeItem(STORAGE_TOKEN);
}

function showToast(message, isError = false) {
  refs.toast.textContent = message;
  refs.toast.classList.add('show');
  refs.toast.classList.toggle('danger', isError);
  setTimeout(() => refs.toast.classList.remove('show'), 2500);
}

function formatDate(value) {
  if (!value) return '-';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? value : date.toLocaleDateString('pt-BR');
}

function can(permission) {
  return (currentUser?.permissoes || []).includes(permission);
}

function applyPermissions() {
  document.querySelectorAll('[data-permission]').forEach(element => {
    const perm = element.getAttribute('data-permission');
    element.style.display = can(perm) ? '' : 'none';
  });
}

async function apiFetch(path, options = {}) {
  const headers = {
    'Content-Type': 'application/json',
    ...(options.headers || {})
  };
  const token = getToken();
  if (token) headers.Authorization = `Bearer ${token}`;

  const apiBase = getApiBase();
  let response;
  try {
    response = await fetch(`${apiBase}${path}`, { ...options, headers });
  } catch {
    const mixedContentHint = window.location.protocol === 'https:' && apiBase.startsWith('http://')
      ? 'Página HTTPS com API HTTP pode ser bloqueada. Abra o painel em HTTP ou use API com HTTPS.'
      : 'Verifique a URL da API e confirme que o backend está rodando.';
    throw new Error(`Não foi possível conectar na API (${apiBase}). ${mixedContentHint}`);
  }

  if (!response.ok) {
    const text = await response.text();
    let message = `Erro ${response.status}`;

    try {
      const json = JSON.parse(text);
      message = json.message || json.error || message;
    } catch {
      if (text) {
        message = text.split('\n')[0].slice(0, 180);
      }
    }

    throw new Error(message);
  }
  if (response.status === 204) return null;
  return response.json();
}

async function checkApiHealth() {
  const apiBase = getApiBase();
  try {
    const response = await fetch(`${apiBase}/api/dashboard/health`);
    if (!response.ok) throw new Error();
    refs.apiStatus.textContent = `API conectada (${apiBase})`;
    refs.apiStatus.classList.remove('danger');
    return true;
  } catch {
    refs.apiStatus.textContent = `API indisponível (${apiBase})`;
    refs.apiStatus.classList.add('danger');
    return false;
  }
}

async function fetchMe() {
  currentUser = await apiFetch('/api/internal/auth/me');
  refs.userInfo.textContent = `${currentUser.nome} • ${currentUser.perfil}`;
  applyPermissions();
}

async function loadDashboard() {
  if (!can('DASHBOARD')) return;
  const data = await apiFetch('/api/internal/dashboard/resumo');
  refs.kpiLeads.textContent = data.totais?.leadsAbertos ?? 0;
  refs.kpiClientes.textContent = data.totais?.clientesAtivos ?? 0;
  refs.kpiContratos.textContent = data.totais?.contratosAtivos ?? 0;
  refs.kpiUnidades.textContent = data.totais?.unidadesAtivas ?? 0;
  refs.kpiAtividades.textContent = data.totais?.atividadesPendentes ?? 0;
  refs.kpiFollowup.textContent = data.totais?.followUp30Dias ?? 0;
}

async function loadLeads() {
  if (!can('COMERCIAL')) return;
  const leads = await apiFetch('/api/internal/leads');
  refs.leadsBody.innerHTML = leads.length
    ? leads
        .map(
          lead => `<tr><td>${lead.nomeContato || '-'}</td><td>${lead.empresa || '-'}</td><td>${lead.status || '-'}</td><td>${formatDate(lead.proximoContatoEm)}</td></tr>`
        )
        .join('')
    : '<tr><td colspan="4">Sem dados</td></tr>';
}

async function loadClientes() {
  if (!can('CONTRATOS')) return;
  const clientes = await apiFetch('/api/internal/clientes');
  refs.clientesBody.innerHTML = clientes.length
    ? clientes
        .map(
          c => `<tr><td>${c.razaoSocial || '-'}</td><td>${c.nomeFantasia || '-'}</td><td>${c.cnpj || '-'}</td><td>${c.cidade || '-'} / ${c.estado || '-'}</td></tr>`
        )
        .join('')
    : '<tr><td colspan="4">Sem dados</td></tr>';

  refs.contratoCliente.innerHTML = '<option value="">Selecione o cliente</option>';
  clientes.forEach(c => {
    const option = document.createElement('option');
    option.value = c.id;
    option.textContent = c.nomeFantasia || c.razaoSocial;
    refs.contratoCliente.appendChild(option);
  });
}

async function loadContratos() {
  if (!can('CONTRATOS')) return;
  const contratos = await apiFetch('/api/internal/contratos');
  refs.contratosBody.innerHTML = contratos.length
    ? contratos
        .map(
          c => `<tr><td>${c.cliente || '-'}</td><td>${c.plano || '-'}</td><td>${c.status || '-'}</td><td>${c.qtdUnidades || 0}</td></tr>`
        )
        .join('')
    : '<tr><td colspan="4">Sem dados</td></tr>';

  const fill = select => {
    select.innerHTML = '<option value="">Selecione o contrato</option>';
    contratos.forEach(c => {
      const option = document.createElement('option');
      option.value = c.id;
      option.textContent = `${c.cliente} • ${c.plano}`;
      select.appendChild(option);
    });
  };
  fill(refs.unidadeContrato);
  fill(refs.vinculoContrato);
}

async function loadUnidades() {
  if (!can('UNIDADES')) return;
  const unidades = await apiFetch('/api/internal/unidades');
  refs.unidadesBody.innerHTML = unidades.length
    ? unidades
        .map(u => {
          const contratos = (u.contratos || []).map(c => `${c.cliente} (${c.plano})`).join(', ') || '-';
          return `<tr><td>${u.nomeUnidade}</td><td>${u.cidade || '-'} / ${u.estado || '-'}</td><td>${u.quantidadeEstufas || 0}</td><td>${contratos}</td></tr>`;
        })
        .join('')
    : '<tr><td colspan="4">Sem dados</td></tr>';

  const fill = select => {
    select.innerHTML = '<option value="">Selecione a unidade</option>';
    unidades.forEach(u => {
      const option = document.createElement('option');
      option.value = u.id;
      option.textContent = u.nomeUnidade;
      select.appendChild(option);
    });
  };
  fill(refs.vinculoUnidade);
  fill(refs.atividadeUnidade);
}

async function loadAtividades() {
  if (!can('ATIVIDADES')) return;
  const atividades = await apiFetch('/api/internal/atividades');
  refs.atividadesList.innerHTML = atividades.length
    ? atividades
        .map(
          a => `<li><strong>${a.titulo}</strong><br/><span>${a.unidade || '-'} • ${a.prioridade || '-'} • ${formatDate(a.prazoEm)}</span>
          ${a.concluida ? '<br/><small>Concluída</small>' : `<div style="margin-top:8px"><button class="btn small" data-concluir="${a.id}">Concluir</button></div>`}
          </li>`
        )
        .join('')
    : '<li>Sem atividades.</li>';
}

async function loadUsuarios() {
  if (!can('USUARIOS')) return;
  const usuarios = await apiFetch('/api/internal/usuarios');
  refs.usuariosBody.innerHTML = usuarios.length
    ? usuarios
        .map(u => `<tr><td>${u.nome}</td><td>${u.login}</td><td>${u.perfil}</td><td>${u.gerente ? 'SIM' : 'NÃO'}</td><td>${u.ativo ? 'SIM' : 'NÃO'}</td></tr>`)
        .join('')
    : '<tr><td colspan="5">Sem usuários.</td></tr>';
}

async function refreshAll() {
  refs.apiStatus.textContent = 'Sincronizando dados...';
  refs.apiStatus.classList.remove('danger');
  try {
    await Promise.all([loadDashboard(), loadLeads(), loadClientes(), loadContratos(), loadUnidades(), loadAtividades(), loadUsuarios()]);
    refs.apiStatus.textContent = 'API conectada';
  } catch (error) {
    refs.apiStatus.textContent = 'Erro ao carregar dados';
    refs.apiStatus.classList.add('danger');
    showToast(`Falha ao carregar painel: ${error.message}`, true);
  }
}

async function onLogin(event) {
  event.preventDefault();
  try {
    const payload = Object.fromEntries(new FormData(event.target).entries());
    const result = await apiFetch('/api/auth/login', { method: 'POST', body: JSON.stringify(payload) });
    setToken(result.token);
    refs.loginOverlay.style.display = 'none';
    await fetchMe();
    await refreshAll();
    showToast('Login realizado');
  } catch (error) {
    refs.loginStatus.textContent = `Falha no login: ${error.message}`;
    showToast(error.message, true);
  }
}

async function onLogout() {
  try {
    await apiFetch('/api/auth/logout', { method: 'POST' });
  } catch {}
  setToken(null);
  currentUser = null;
  refs.loginOverlay.style.display = 'grid';
  refs.userInfo.textContent = '';
  refs.apiStatus.textContent = 'Aguardando login...';
}

async function submitLead(event) {
  event.preventDefault();
  await apiFetch('/api/internal/leads', { method: 'POST', body: JSON.stringify(Object.fromEntries(new FormData(event.target).entries())) });
  event.target.reset();
  await Promise.all([loadLeads(), loadDashboard()]);
}

async function submitCliente(event) {
  event.preventDefault();
  const payload = Object.fromEntries(new FormData(event.target).entries());
  payload.ativo = true;
  await apiFetch('/api/internal/clientes', { method: 'POST', body: JSON.stringify(payload) });
  event.target.reset();
  await Promise.all([loadClientes(), loadDashboard()]);
}

async function submitContrato(event) {
  event.preventDefault();
  const payload = Object.fromEntries(new FormData(event.target).entries());
  payload.clienteId = Number(payload.clienteId);
  payload.valorMensal = Number(payload.valorMensal);
  await apiFetch('/api/internal/contratos', { method: 'POST', body: JSON.stringify(payload) });
  event.target.reset();
  await Promise.all([loadContratos(), loadDashboard()]);
}

async function submitUnidade(event) {
  event.preventDefault();
  const payload = Object.fromEntries(new FormData(event.target).entries());
  const contratoId = payload.contratoId ? Number(payload.contratoId) : null;
  delete payload.contratoId;
  payload.quantidadeEstufas = Number(payload.quantidadeEstufas || 1);
  payload.ativa = true;

  const unidade = await apiFetch('/api/internal/unidades', { method: 'POST', body: JSON.stringify(payload) });
  if (contratoId && unidade?.id) {
    await apiFetch(`/api/internal/contratos/${contratoId}/unidades/${unidade.id}`, { method: 'POST', body: JSON.stringify({}) });
  }
  event.target.reset();
  await Promise.all([loadUnidades(), loadContratos(), loadDashboard()]);
}

async function submitVinculo(event) {
  event.preventDefault();
  const payload = Object.fromEntries(new FormData(event.target).entries());
  await apiFetch(`/api/internal/contratos/${Number(payload.contratoId)}/unidades/${Number(payload.unidadeId)}`, {
    method: 'POST',
    body: JSON.stringify({})
  });
  event.target.reset();
  await Promise.all([loadUnidades(), loadContratos()]);
}

async function submitAtividade(event) {
  event.preventDefault();
  const payload = Object.fromEntries(new FormData(event.target).entries());
  payload.unidadeId = Number(payload.unidadeId);
  await apiFetch('/api/internal/atividades', { method: 'POST', body: JSON.stringify(payload) });
  event.target.reset();
  await Promise.all([loadAtividades(), loadDashboard()]);
}

async function submitUsuario(event) {
  event.preventDefault();
  const payload = Object.fromEntries(new FormData(event.target).entries());
  payload.gerente = !!payload.gerente;
  await apiFetch('/api/internal/usuarios', { method: 'POST', body: JSON.stringify(payload) });
  event.target.reset();
  await loadUsuarios();
}

async function bootstrap() {
  refs.apiBase.value = getApiBase();
  document.getElementById('saveApi').addEventListener('click', async () => {
    localStorage.setItem(STORAGE_API, refs.apiBase.value.trim());
    const ok = await checkApiHealth();
    showToast(ok ? 'URL da API salva e conectada' : 'URL da API salva, mas sem conexão', !ok);
  });

  document.getElementById('loginForm').addEventListener('submit', onLogin);
  document.getElementById('logoutBtn').addEventListener('click', onLogout);
  document.getElementById('reloadLeads').addEventListener('click', loadLeads);
  document.getElementById('reloadClientes').addEventListener('click', loadClientes);
  document.getElementById('reloadContratos').addEventListener('click', loadContratos);
  document.getElementById('reloadUnidades').addEventListener('click', loadUnidades);
  document.getElementById('reloadAtividades').addEventListener('click', loadAtividades);
  document.getElementById('reloadUsuarios').addEventListener('click', loadUsuarios);

  document.getElementById('leadForm').addEventListener('submit', submitLead);
  document.getElementById('clienteForm').addEventListener('submit', submitCliente);
  document.getElementById('contratoForm').addEventListener('submit', submitContrato);
  document.getElementById('unidadeForm').addEventListener('submit', submitUnidade);
  document.getElementById('vinculoForm').addEventListener('submit', submitVinculo);
  document.getElementById('atividadeForm').addEventListener('submit', submitAtividade);
  document.getElementById('usuarioForm').addEventListener('submit', submitUsuario);

  await checkApiHealth();

  refs.atividadesList.addEventListener('click', async event => {
    const id = event.target.getAttribute('data-concluir');
    if (!id) return;
    await apiFetch(`/api/internal/atividades/${id}/concluir`, { method: 'PATCH' });
    await Promise.all([loadAtividades(), loadDashboard()]);
  });

  if (!getToken()) {
    refs.loginOverlay.style.display = 'grid';
    return;
  }

  try {
    await fetchMe();
    refs.loginOverlay.style.display = 'none';
    await refreshAll();
  } catch {
    setToken(null);
    refs.loginOverlay.style.display = 'grid';
  }
}

bootstrap();
