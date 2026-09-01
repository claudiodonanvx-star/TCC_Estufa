// =========================================================
// VARIÁVEIS
// =========================================================

let apiBase = "";
let pollTimer = null;
let conectado = false;

let ultimoDadoId = null;
let ultimoAlertaId = null;
let ultimoEstadoAtuadores = null;


// =========================================================
// ELEMENTOS HTML
// =========================================================

const connectButton =
    document.getElementById("connectButton");

const apiBaseInput =
    document.getElementById("apiBaseInput");

const connectionDot =
    document.getElementById("connectionDot");

const connectionText =
    document.getElementById("connectionText");

const serialMonitor =
    document.getElementById("serialMonitor");

const warning =
    document.getElementById("warning");

const clearButton =
    document.getElementById("clearButton");


// Abas

const tabButtons =
    document.querySelectorAll(".tab-button");

const tabContents =
    document.querySelectorAll(".tab-content");


// Sensores

const tempValue = document.getElementById("tempValue");
const tempStatus = document.getElementById("tempStatus");
const umidadeValue = document.getElementById("umidadeValue");
const umidadeStatus = document.getElementById("umidadeStatus");
const soloValue = document.getElementById("soloValue");
const soloStatus = document.getElementById("soloStatus");
const sensoresAtualizadoEm = document.getElementById("sensoresAtualizadoEm");


// Relé e falhas

const releLog = document.getElementById("releLog");
const falhasLog = document.getElementById("falhasLog");
const clearReleButton = document.getElementById("clearReleButton");
const clearFalhasButton = document.getElementById("clearFalhasButton");


// Cadastro (somente leitura, não altera cadastros do sistema)

const cadastroApi = document.getElementById("cadastroApi");
const cadastroModo = document.getElementById("cadastroModo");
const cadastroLeituras = document.getElementById("cadastroLeituras");
const cadastroAlertas24h = document.getElementById("cadastroAlertas24h");


// =========================================================
// CARREGAR ENDEREÇO DA API SALVO
// =========================================================

apiBaseInput.value =
    localStorage.getItem("estufaApiBase") ||
    (location.protocol.startsWith("http")
        ? location.origin
        : "https://api-estufa.onrender.com");


// =========================================================
// BOTÃO CONECTAR / DESCONECTAR
// =========================================================

connectButton.addEventListener(
    "click",
    alternarConexao
);


// =========================================================
// BOTÃO LIMPAR
// =========================================================

clearButton.addEventListener(
    "click",
    limparMonitor
);


// =========================================================
// ABAS
// =========================================================

tabButtons.forEach(function (botao) {

    botao.addEventListener("click", function () {
        trocarAba(botao.dataset.tab);
    });

});


function trocarAba(aba) {

    tabButtons.forEach(function (botao) {
        botao.classList.toggle("active", botao.dataset.tab === aba);
    });

    tabContents.forEach(function (conteudo) {
        conteudo.classList.toggle("active", conteudo.dataset.tabContent === aba);
    });
}


// =========================================================
// LIMPAR RELÉ / FALHAS
// =========================================================

clearReleButton.addEventListener("click", function () {
    releLog.innerHTML = "Nenhum evento de relé ainda.";
});

clearFalhasButton.addEventListener("click", function () {
    falhasLog.innerHTML = "Nenhuma falha registrada.";
});


// =========================================================
// CONECTAR / DESCONECTAR DA API
// =========================================================

function alternarConexao() {

    if (conectado) {
        desconectar();
    } else {
        conectar();
    }
}


function normalizarApiBase(valor) {

    let base = valor.trim().replace(/\/+$/, "");

    if (base.length === 0) {
        return "";
    }

    if (!/^https?:\/\//i.test(base)) {
        base = "https://" + base;
    }

    return base;
}


function conectar() {

    apiBase = normalizarApiBase(apiBaseInput.value);

    localStorage.setItem("estufaApiBase", apiBase);

    ultimoDadoId = null;
    ultimoAlertaId = null;
    ultimoEstadoAtuadores = null;

    conectado = true;

    connectButton.textContent =
        "🔌 Desconectar";

    adicionarLog(
        "Conectando à API: " + (apiBase || location.origin)
    );

    atualizarTudo();

    pollTimer = setInterval(atualizarTudo, 5000);
}


function desconectar() {

    clearInterval(pollTimer);

    conectado = false;

    connectButton.textContent =
        "🔌 Conectar";

    connectionDot.classList.remove("connected");

    connectionText.textContent =
        "Desconectado da API";

    adicionarLog(
        "Monitoramento pausado."
    );
}


// =========================================================
// BUSCAR DADOS DA API (SUBSTITUI A LEITURA SERIAL)
// =========================================================

async function atualizarTudo() {

    await Promise.all([
        verificarPing(),
        verificarDados(),
        verificarAtuadores(),
        verificarAlertas()
    ]);
}


async function verificarPing() {

    try {

        const resposta =
            await fetch(apiBase + "/api/ping");

        if (!resposta.ok) {
            throw new Error("ping falhou");
        }

        const dados =
            await resposta.json();

        connectionDot.classList.add("connected");

        connectionText.textContent =
            "API conectada";

        warning.style.display = "none";

        cadastroApi.textContent =
            apiBase || location.origin;

        cadastroLeituras.textContent =
            dados.totalLeituras ?? "--";

        cadastroAlertas24h.textContent =
            dados.alertas24h ?? "--";

    }

    catch (error) {

        connectionDot.classList.remove("connected");

        connectionText.textContent =
            "Falha ao conectar à API";

        warning.style.display = "block";

    }
}


async function verificarDados() {

    try {

        const resposta =
            await fetch(apiBase + "/api/dados?page=0&size=1&ordem=desc");

        const lista =
            await resposta.json();

        if (!Array.isArray(lista) || lista.length === 0) {
            return;
        }

        const ultimo = lista[0];

        if (ultimo.id === ultimoDadoId) {
            return;
        }

        ultimoDadoId = ultimo.id;

        atualizarSensor(tempValue, tempStatus, ultimo.temperatura, "°C");
        atualizarSensor(umidadeValue, umidadeStatus, ultimo.umidade, "%");

        if (ultimo.umidadeSolo != null) {
            atualizarSensor(soloValue, soloStatus, ultimo.umidadeSolo, "%");
        } else {
            marcarSensorComoFalha(soloStatus);
            registrarFalha("Sensor de solo sem leitura recente");
        }

        const solo =
            ultimo.umidadeSolo != null
                ? ultimo.umidadeSolo.toFixed(1) + "%"
                : "--";

        adicionarLog(
            `🌡️ ${ultimo.temperatura.toFixed(1)}°C · 💧 ${ultimo.umidade.toFixed(1)}% · 🌱 ${solo} — ${ultimo.significado ?? ""}`
        );

    }

    catch (error) {

        console.error(error);

    }
}


async function verificarAtuadores() {

    try {

        const resposta =
            await fetch(apiBase + "/api/atuadores");

        const estado =
            await resposta.json();

        cadastroModo.textContent =
            estado.modoAutomatico ? "Automático" : "Manual";

        if (ultimoEstadoAtuadores) {

            if (estado.bombaLigada !== ultimoEstadoAtuadores.bombaLigada) {
                registrarRele(estado.bombaLigada ? "Bomba ligada" : "Bomba desligada");
            }

            if (estado.coolerLigado !== ultimoEstadoAtuadores.coolerLigado) {
                registrarRele(estado.coolerLigado ? "Cooler ligado" : "Cooler desligado");
            }
        }

        ultimoEstadoAtuadores = estado;

    }

    catch (error) {

        console.error(error);

    }
}


async function verificarAlertas() {

    try {

        const resposta =
            await fetch(apiBase + "/api/alertas");

        const lista =
            await resposta.json();

        if (!Array.isArray(lista) || lista.length === 0) {
            return;
        }

        // Primeira consulta: só define o marco, sem repetir todo o histórico

        if (ultimoAlertaId === null) {

            lista
                .slice(0, 10)
                .slice()
                .reverse()
                .forEach(function (alerta) {
                    registrarFalha(`[${alerta.severidade}] ${alerta.mensagem}`);
                });

            ultimoAlertaId = Math.max(...lista.map((a) => a.id));

            return;
        }

        const novos =
            lista.filter((a) => a.id > ultimoAlertaId);

        novos
            .slice()
            .reverse()
            .forEach(function (alerta) {
                registrarFalha(`[${alerta.severidade}] ${alerta.mensagem}`);
            });

        if (novos.length > 0) {
            ultimoAlertaId = Math.max(...lista.map((a) => a.id));
        }

    }

    catch (error) {

        console.error(error);

    }
}


// =========================================================
// ATUALIZAR CARD DE SENSOR
// =========================================================

function atualizarSensor(valorEl, statusEl, valor, unidade) {

    if (valor == null || isNaN(valor)) {
        return;
    }

    valorEl.textContent = Number(valor).toFixed(1) + " " + unidade;

    statusEl.textContent = "OK";
    statusEl.classList.remove("erro");
    statusEl.classList.add("ok");

    sensoresAtualizadoEm.textContent =
        "Última leitura: " + new Date().toLocaleTimeString();
}


function marcarSensorComoFalha(statusEl) {

    statusEl.textContent = "FALHA";
    statusEl.classList.remove("ok");
    statusEl.classList.add("erro");
}


// =========================================================
// REGISTRAR EVENTO DE RELÉ
// =========================================================

function registrarRele(mensagem) {

    if (releLog.textContent.trim() === "Nenhum evento de relé ainda.") {
        releLog.innerHTML = "";
    }

    const hora = new Date().toLocaleTimeString();

    const item = document.createElement("span");
    item.className = "log-item rele";
    item.textContent = `[${hora}] ${mensagem}`;

    releLog.appendChild(item);
    releLog.scrollTop = releLog.scrollHeight;
}


// =========================================================
// REGISTRAR FALHA
// =========================================================

function registrarFalha(mensagem) {

    if (falhasLog.textContent.trim() === "Nenhuma falha registrada.") {
        falhasLog.innerHTML = "";
    }

    const hora = new Date().toLocaleTimeString();

    const item = document.createElement("span");
    item.className = "log-item falha";
    item.textContent = `[${hora}] ${mensagem}`;

    falhasLog.appendChild(item);
    falhasLog.scrollTop = falhasLog.scrollHeight;
}


// =========================================================
// MONITOR (LOG DE EVENTOS VINDOS DA API)
// =========================================================

function adicionarLog(mensagem) {

    const hora =
        new Date().toLocaleTimeString();


    serialMonitor.textContent +=
        `[${hora}] ${mensagem}\n`;


    // Scroll automático para o final

    serialMonitor.scrollTop =
        serialMonitor.scrollHeight;
}


// =========================================================
// LIMPAR MONITOR
// =========================================================

function limparMonitor() {

    serialMonitor.textContent = "";

}
