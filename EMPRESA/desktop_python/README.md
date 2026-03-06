# Desktop Python - Dashboard Empresa

Aplicação desktop em Python para visualizar dados das tabelas `emp_` no MySQL.

## Requisitos

- Python 3.10+
- Acesso ao banco MySQL

## Configuração

1. Abra esta pasta no terminal:

```powershell
cd c:\Users\Public\Documents\quimica\desktop_python
```

2. Crie o ambiente virtual e instale dependências:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

3. Crie o arquivo `.env` com base no exemplo:

```powershell
copy .env.example .env
```

4. Edite o `.env` com usuário e senha do banco.

## Executar

```powershell
python app.py
```

## Executar com 1 clique

- Crie o `.env` (se ainda nao criou) usando o `.env.example`
- Clique duas vezes em `abrir_dashboard.bat`

## O que o dashboard mostra

- Cards com total de registros por tabela `emp_`
- Navegador de tabelas com grade de ate 150 registros
- Aba de funil de leads com grafico e resumo por status
- Aba de alertas (contratos proximos do fim e atividades com prazo curto)
- Aba Cliente 360 com contratos, unidades, atividades e receita ativa
- Card de adimplencia no Cliente 360 (percentual de pagamentos dentro da regra de 5 dias)
- Aba Financeiro com boletos por unidade e status `ATIVO/CANCELADO/BFP`
- Botão de atualização em tempo real

## Historico de pagamentos por cliente

- Na aba `Cliente 360`, de duplo clique em um cliente para abrir o historico completo de boletos pagos
- O historico mostra todos os boletos pagos, independente de estarem perto do vencimento
- Tambem exibe indicadores de regularidade: pagos no prazo de 5 dias e pagos apos 5 dias

## Regra de pagamento (boleto)

- Forma de pagamento considerada: boleto
- Cada unidade recebe boletos mensais simulados desde `criado_em` ate o mes atual
- Cada boleto tem um PDF simulado salvo em `LONGBLOB` (campo `arquivo_pdf`)
- Regra de 5 dias: se um boleto ficar sem pagamento por mais de 5 dias apos o vencimento, a unidade fica `BFP`
- Status financeiro da unidade:
	- `ATIVO`: sem pendencia acima de 5 dias
	- `CANCELADO`: unidade inativa (`ativa = 0`)
	- `BFP`: bloqueado por falta de pagamento

## Estrutura financeira criada automaticamente

Na primeira atualizacao, o app cria/ajusta no MySQL:

- Tabela `emp_boletos`
- Coluna `emp_unidades.status_financeiro`

Tambem gera os registros simulados de boletos por unidade e sincroniza o status financeiro.

## Simular baixa e pagamento

Na aba `Financeiro`:

- Selecione uma unidade
- Selecione um boleto na grade
- Clique em `Baixar PDF selecionado` para salvar o arquivo local
- Clique em `Confirmar pagamento` para marcar o boleto como pago

Ao confirmar o pagamento, o sistema atualiza os status da unidade automaticamente pela regra de 5 dias.
