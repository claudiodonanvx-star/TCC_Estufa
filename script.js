const menuBtn = document.getElementById("menuBtn")
const menu = document.getElementById("menu")
const closeMenu = document.getElementById("closeMenu")
const overlay = document.getElementById("overlay")

const loginBtn = document.getElementById("loginBtn")
const registerBtn = document.getElementById("registerBtn")

const loginModal = document.getElementById("loginModal")
const registerModal = document.getElementById("registerModal")

const closeModal = document.querySelectorAll(".closeModal")

/* MENU */

menuBtn.onclick = () => {
menu.classList.add("open")
overlay.classList.add("show")
}

closeMenu.onclick = () => {
menu.classList.remove("open")
overlay.classList.remove("show")
}

overlay.onclick = () => {
menu.classList.remove("open")
overlay.classList.remove("show")
}

/* MODAIS */

loginBtn.onclick = () => {
loginModal.classList.add("show")
}

registerBtn.onclick = () => {
registerModal.classList.add("show")
}

closeModal.forEach(btn=>{
btn.onclick = ()=>{
loginModal.classList.remove("show")
registerModal.classList.remove("show")
}
})

/* CADASTRO */

const registerForm = registerModal.querySelector("form")

registerForm.addEventListener("submit", function(e){

e.preventDefault()

const nome = registerForm.children[0].value
const email = registerForm.children[4].value
const senha = registerForm.children[5].value

const user = {
nome,
email,
senha
}

localStorage.setItem("usuario", JSON.stringify(user))

alert("Cadastro realizado com sucesso!")

registerModal.classList.remove("show")

})

/* LOGIN */

const loginForm = loginModal.querySelector("form")

loginForm.addEventListener("submit", function(e){

e.preventDefault()

const usuarioSalvo = JSON.parse(localStorage.getItem("usuario"))

const user = loginForm.children[0].value
const senha = loginForm.children[1].value

if(!usuarioSalvo){
alert("Nenhum usuário cadastrado!")
return
}

if(user === usuarioSalvo.email && senha === usuarioSalvo.senha){

alert("Login realizado!")

loginModal.classList.remove("show")

/* DESABILITA BOTÕES */

loginBtn.disabled = true
registerBtn.disabled = true

loginBtn.innerText = "Logado"
registerBtn.innerText = "Conta criada"

/* VOLTA PARA TELA INICIAL */

window.scrollTo({
top:0,
behavior:"smooth"
})

}else{

alert("Usuário ou senha incorretos")

}

})

/* FORM CONTATO */

const form = document.getElementById('leadForm')
const status = document.getElementById('status')

form.addEventListener('submit', e=>{

e.preventDefault()

status.innerText="Mensagem enviada com sucesso!"

form.reset()

})

/* MAPA CLIENTES */

const clientMapElement = document.getElementById("clientMap")

if(clientMapElement && typeof L !== "undefined"){

const clientMap = L.map("clientMap", {
scrollWheelZoom:false
}).setView([-14.2350, -51.9253], 4)

L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
maxZoom:19,
attribution:"&copy; OpenStreetMap contributors"
}).addTo(clientMap)

const clientes = [
{ nome:"Estufa Aurora", endereco:"Rua das Palmeiras, 184 - Manaus/AM", lat:-3.1190, lng:-60.0217 },
{ nome:"Horta Sol Nascente", endereco:"Av. Ver-o-Peso, 322 - Belem/PA", lat:-1.4558, lng:-48.4902 },
{ nome:"Verde Novo Agro", endereco:"Rua da Estacao, 77 - Sao Luis/MA", lat:-2.5307, lng:-44.3068 },
{ nome:"Campo Limpo Cultivo", endereco:"Rua das Flores, 911 - Fortaleza/CE", lat:-3.7319, lng:-38.5267 },
{ nome:"Estufa Sao Jorge", endereco:"Av. Beira Mar, 456 - Recife/PE", lat:-8.0476, lng:-34.8770 },
{ nome:"Raiz Forte", endereco:"Rua do Comercio, 208 - Salvador/BA", lat:-12.9777, lng:-38.5016 },
{ nome:"Plantio Horizonte", endereco:"SQN 410, Bloco B - Brasilia/DF", lat:-15.7939, lng:-47.8828 },
{ nome:"Viva Verde", endereco:"Rua Serra Azul, 67 - Goiania/GO", lat:-16.6869, lng:-49.2648 },
{ nome:"Estufa Rio Dourado", endereco:"Rua do Mercado, 395 - Belo Horizonte/MG", lat:-19.9167, lng:-43.9345 },
{ nome:"Jardim Sensorial", endereco:"Rua das Acacias, 143 - Sao Paulo/SP", lat:-23.5505, lng:-46.6333 },
{ nome:"Agro Costa Sul", endereco:"Av. Atlantica, 501 - Florianopolis/SC", lat:-27.5954, lng:-48.5480 },
{ nome:"EcoPlant Solutions", endereco:"Rua Bento Goncalves, 812 - Porto Alegre/RS", lat:-30.0346, lng:-51.2177 }
]

const pontos = []

clientes.forEach(cliente => {
const marker = L.circleMarker([cliente.lat, cliente.lng], {
radius:7,
color:"#7fd45b",
weight:2,
fillColor:"#b7f08c",
fillOpacity:0.9
}).addTo(clientMap)

marker.bindPopup(`<strong>${cliente.nome}</strong><br>${cliente.endereco}`)
pontos.push([cliente.lat, cliente.lng])
})

if(pontos.length){
clientMap.fitBounds(pontos, { padding:[35, 35] })
}

}

if(clientMapElement && typeof L === "undefined"){
clientMapElement.innerHTML = "Nao foi possivel carregar o mapa agora. Verifique sua conexao com a internet."
clientMapElement.style.display = "flex"
clientMapElement.style.alignItems = "center"
clientMapElement.style.justifyContent = "center"
clientMapElement.style.textAlign = "center"
clientMapElement.style.padding = "20px"
}