const API_CANDIDATES = [
  localStorage.getItem('estufaApiBase'),
  `http://${window.location.hostname || 'localhost'}:7002/api`,
  'http://localhost:7002/api',
  'http://127.0.0.1:7002/api',
  'http://143.106.241.4:7002/api'
].filter(Boolean);

const form = document.getElementById('login-form');
const msg = document.getElementById('mensagem');
const btn = document.getElementById('btn-entrar');

function mostrarMensagem(texto, tipo) {
  msg.textContent = texto;
  msg.className = `mensagem ${tipo || ''}`.trim();
}

function jaAutenticado() {
  const auth = localStorage.getItem('estufaAuth');
  if (auth) {
    window.location.href = 'relatoriodoProduto.html';
  }
}

async function tentarLogin(apiBase, login, senha) {
  const response = await fetch(`${apiBase}/usuarios/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ login, senha })
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    const mensagemErro = data?.mensagem || 'Falha no login';
    throw new Error(mensagemErro);
  }

  return data;
}

async function autenticar(login, senha) {
  let ultimaErro = 'Não foi possível conectar na API';

  for (const apiBase of API_CANDIDATES) {
    try {
      const data = await tentarLogin(apiBase, login, senha);
      localStorage.setItem('estufaApiBase', apiBase);
      localStorage.setItem('estufaAuth', JSON.stringify({
        login,
        cpf: data?.cpf || login,
        administrador: !!data?.administrador,
        loginEm: Date.now()
      }));
      return;
    } catch (err) {
      ultimaErro = err.message || ultimaErro;
    }
  }

  throw new Error(ultimaErro);
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  const login = document.getElementById('login').value.trim();
  const senha = document.getElementById('senha').value;

  if (!login || !senha) {
    mostrarMensagem('Preencha usuário e senha.', 'erro');
    return;
  }

  btn.disabled = true;
  mostrarMensagem('Validando acesso...', '');

  try {
    await autenticar(login, senha);
    mostrarMensagem('Login realizado com sucesso. Redirecionando...', 'ok');
    window.location.href = 'relatoriodoProduto.html';
  } catch (err) {
    mostrarMensagem(err.message || 'Erro no login', 'erro');
  } finally {
    btn.disabled = false;
  }
});

jaAutenticado();
