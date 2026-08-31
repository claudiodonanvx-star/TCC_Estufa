// =========================================================
// VARIÁVEIS
// =========================================================

let port = null;
let reader = null;
let writer = null;

let buffer = "";


// =========================================================
// ELEMENTOS HTML
// =========================================================

const connectButton =
    document.getElementById("connectButton");

const connectionDot =
    document.getElementById("connectionDot");

const connectionText =
    document.getElementById("connectionText");

const statusCircle =
    document.getElementById("statusCircle");

const statusText =
    document.getElementById("statusText");

const serialMonitor =
    document.getElementById("serialMonitor");

const warning =
    document.getElementById("warning");

const onButton =
    document.getElementById("onButton");

const offButton =
    document.getElementById("offButton");

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

const cadastroConexao = document.getElementById("cadastroConexao");
const cadastroWifi = document.getElementById("cadastroWifi");
const cadastroIp = document.getElementById("cadastroIp");


// =========================================================
// VERIFICAR SUPORTE AO WEB SERIAL
// =========================================================

if (!("serial" in navigator)) {

    warning.style.display = "block";

    adicionarSerial(
        "ERRO: Web Serial não é suportado neste navegador."
    );
}


// =========================================================
// BOTÃO CONECTAR
// =========================================================

connectButton.addEventListener(
    "click",
    connectSerial
);


// =========================================================
// BOTÃO LIGAR
// =========================================================

onButton.addEventListener(
    "click",
    ligarBomba
);


// =========================================================
// BOTÃO DESLIGAR
// =========================================================

offButton.addEventListener(
    "click",
    desligarBomba
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
// CONECTAR AO ARDUINO
// =========================================================

async function connectSerial() {

    try {

        adicionarSerial(
            "Solicitando conexão com o Arduino..."
        );


        // Abre janela para selecionar a porta

        port =
            await navigator.serial.requestPort();


        // Abre a porta em 9600 baud

        await port.open({
            baudRate: 9600
        });


        // Atualiza interface

        connectionDot
            .classList
            .add("connected");

        connectionText.textContent =
            "Arduino conectado";

        connectButton.textContent =
            "✅ Arduino conectado";

        cadastroConexao.textContent =
            "Arduino conectado (aguardando dados)";


        adicionarSerial(
            "Arduino conectado com sucesso."
        );


        // Cria escritor da porta

        writer =
            port.writable.getWriter();


        // Começa a leitura

        readSerial();

    }

    catch (error) {

        console.error(error);

        adicionarSerial(
            "ERRO: Não foi possível conectar ao Arduino."
        );

    }
}


// =========================================================
// LER PORTA SERIAL
// =========================================================

async function readSerial() {

    reader =
        port.readable.getReader();


    const decoder =
        new TextDecoder();


    try {

        while (true) {

            const {
                value,
                done
            } = await reader.read();


            if (done) {
                break;
            }


            if (!value) {
                continue;
            }


            // Converte os bytes recebidos para texto

            buffer +=
                decoder.decode(value);


            // Divide por linhas

            const linhas =
                buffer.split("\n");


            // Guarda a última linha incompleta

            buffer =
                linhas.pop();


            // Processa as linhas completas

            for (let linha of linhas) {

                linha =
                    linha.trim();


                if (linha.length === 0) {
                    continue;
                }


                // Mostra no monitor

                adicionarSerial(linha);


                // Analisa a mensagem

                interpretarMensagem(linha);
            }

        }

    }

    catch (error) {

        console.error(error);

        adicionarSerial(
            "ERRO: conexão serial encerrada."
        );

    }

    finally {

        reader.releaseLock();

    }
}


// =========================================================
// INTERPRETAR MENSAGEM DO ARDUINO
// =========================================================

function interpretarMensagem(mensagem) {

    const msgLower = mensagem.toLowerCase();


    // Bomba

    if (msgLower.includes("bomba:") && msgLower.includes("ligada")) {
        atualizarStatus(true);
        registrarRele("Bomba ligada");
    }

    if (msgLower.includes("bomba:") && msgLower.includes("desligada")) {
        atualizarStatus(false);
        registrarRele("Bomba desligada");
    }


    // Cooler

    if (msgLower.includes("cooler:") && msgLower.includes("ligado")) {
        registrarRele("Cooler ligado");
    }

    if (msgLower.includes("cooler:") && msgLower.includes("desligado")) {
        registrarRele("Cooler desligado");
    }


    // Sensores (temperatura, umidade do ar, umidade do solo)

    if (mensagem.includes("Temperatura:")) {
        atualizarSensor(tempValue, tempStatus, extrairNumero(mensagem), "°C");
    }

    if (mensagem.includes("Umidade:")) {
        atualizarSensor(umidadeValue, umidadeStatus, extrairNumero(mensagem), "%");
    }

    if (mensagem.includes("Umidade do solo:")) {
        atualizarSensor(soloValue, soloStatus, extrairNumero(mensagem), "%");
    }


    // Falhas de sensores e comunicação

    if (msgLower.includes("erro na leitura do dht11")) {
        marcarSensorComoFalha(tempStatus);
        marcarSensorComoFalha(umidadeStatus);
        registrarFalha("Falha no sensor DHT11 (temperatura/umidade)");
    }

    if (msgLower.includes("sensor de solo desconectado")) {
        marcarSensorComoFalha(soloStatus);
        registrarFalha("Falha no sensor de umidade do solo");
    }

    if (msgLower.includes("erro http")) {
        registrarFalha("Falha ao enviar dados para a API (erro HTTP)");
    }

    if (msgLower.includes("erro ao interpretar json")) {
        registrarFalha("Falha ao interpretar resposta da API (JSON inválido)");
    }

    if (msgLower.includes("wi-fi desconectado")) {
        registrarFalha("Falha de conexão Wi-Fi");
        cadastroConexao.textContent = "Desconectado";
    }

    if (msgLower.includes("nenhuma rede conhecida")) {
        registrarFalha("Nenhuma rede Wi-Fi conhecida encontrada");
    }


    // Cadastro (leitura das informações de rede, sem alterar nada)

    if (mensagem.includes("Tentando SSID:")) {
        cadastroWifi.textContent = mensagem.split("Tentando SSID:")[1].trim();
    }

    if (msgLower.includes("conectado ao wi-fi")) {
        cadastroConexao.textContent = "Wi-Fi conectado";
    }

    if (mensagem.includes("IP do ESP32:")) {
        cadastroIp.textContent = mensagem.split("IP do ESP32:")[1].trim();
    }
}


// =========================================================
// EXTRAIR NÚMERO DE UMA MENSAGEM (ex: "Temperatura: 25.30 °C")
// =========================================================

function extrairNumero(mensagem) {

    const match = mensagem.match(/-?\d+(\.\d+)?/);

    return match ? parseFloat(match[0]) : NaN;
}


// =========================================================
// ATUALIZAR CARD DE SENSOR
// =========================================================

function atualizarSensor(valorEl, statusEl, valor, unidade) {

    if (isNaN(valor)) {
        return;
    }

    valorEl.textContent = valor.toFixed(1) + " " + unidade;

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
// ATUALIZAR STATUS
// =========================================================

function atualizarStatus(ligada) {

    if (ligada) {

        statusCircle
            .classList
            .add("ligada");

        statusText.textContent =
            "BOMBA LIGADA";

    }

    else {

        statusCircle
            .classList
            .remove("ligada");

        statusText.textContent =
            "BOMBA DESLIGADA";

    }
}


// =========================================================
// ENVIAR COMANDO PARA O ARDUINO
// =========================================================

async function enviarComando(comando) {

    if (!port || !writer) {

        adicionarSerial(
            "ERRO: Arduino não está conectado."
        );

        return;
    }


    try {

        const encoder =
            new TextEncoder();


        await writer.write(
            encoder.encode(comando)
        );


        adicionarSerial(
            ">> Enviado: " + comando
        );

    }

    catch (error) {

        console.error(error);

        adicionarSerial(
            "ERRO ao enviar comando."
        );

    }
}


// =========================================================
// LIGAR BOMBA
// =========================================================

async function ligarBomba() {

    await enviarComando("1");

}


// =========================================================
// DESLIGAR BOMBA
// =========================================================

async function desligarBomba() {

    await enviarComando("0");

}


// =========================================================
// MONITOR SERIAL
// =========================================================

function adicionarSerial(mensagem) {

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
