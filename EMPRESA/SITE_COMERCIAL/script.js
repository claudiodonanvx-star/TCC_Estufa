const API_BASE = (localStorage.getItem('estufa_empresa_api_base') || 'http://localhost:8080').replace(/\/$/, '');
const form = document.getElementById('leadForm');
const statusEl = document.getElementById('status');

function setStatus(message, isError = false) {
  statusEl.textContent = message;
  statusEl.style.color = isError ? '#ffb8b8' : '#c8e7b2';
}

form.addEventListener('submit', async event => {
  event.preventDefault();
  const payload = Object.fromEntries(new FormData(form).entries());
  setStatus('Enviando...');

  try {
    const response = await fetch(`${API_BASE}/api/public/leads`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(text || `Erro ${response.status}`);
    }

    form.reset();
    setStatus('Recebemos seu interesse! Nossa equipe entrará em contato.');
  } catch {
    setStatus(`Não foi possível enviar agora para ${API_BASE}. Tente novamente em instantes.`, true);
  }
});
