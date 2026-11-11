# Modelagem de Banco de Dados para a Catel HLM, loja de materiais de construção

## Integrantes

| Nome | RGM | GitHub |
|----|----|----|
| Benjamim Osmar | 47352663 | https://github.com/benjmianotr-ui |
| Carlos Daniel | 42869234 |https://github.com/benjmianotr-ui |
| Guilherme Enzo | 47356481 |
| Erick Jaldin | 47364891 |

**Entrega 2 — Modelo lógico, implementação SQL, normalização e proposta de BI/IA**
(refaz também a Entrega 1, conforme a devolutiva do professor; ver "Correções da Entrega 1" ao final do desenvolvimento)

## Sumário

1. [Introdução](#introdução)
2. [Caracterização da organização](#1-caracterização-da-organização)
3. [Problemas e necessidades](#2-problemas-e-necessidades)
4. [Processos de negócio](#3-processos-de-negócio)
5. [Requisitos](#4-requisitos-do-sistema)
6. [Regras de negócio](#5-regras-de-negócio)
7. [Modelo conceitual (DER)](#6-modelo-conceitual-der)
8. [Modelo lógico](#7-modelo-lógico)
9. [Normalização](#8-normalização)
10. [Justificativas técnicas](#9-justificativas-técnicas)
11. [Implementação SQL e massa de dados](#10-implementação-sql-e-massa-de-dados)
12. [BI e IA: rastreabilidade](#11-bi-e-ia-rastreabilidade)
13. [Estrutura do repositório](#12-estrutura-do-repositório)
14. [Uso de IA](#13-uso-de-inteligência-artificial)
15. [Conclusão e referências](#conclusão)

---

## Introdução

A Catel HLM (Hidráulica, Louças e Metais) é uma loja de materiais de construção da Vila Ré, em São Paulo/SP. Vende no balcão, por WhatsApp e por outros canais, tem fabricação própria de calhas e rufos e compra de fornecedores o restante do que vende.

**Objetivo geral:** projetar e implementar o banco de dados relacional (MySQL 8) de um sistema de gestão para a Catel HLM, do modelo conceitual ao script SQL executável, com propostas de BI e IA ligadas aos problemas da loja.

**Objetivos específicos:**

- levantar problemas, processos, requisitos e regras de negócio;
- construir o DER conceitual e convertê-lo em modelo lógico;
- normalizar o modelo até a 3FN e justificar cada decisão;
- implementar o banco (DDL, dados fictícios, consultas de manipulação, gerenciais e de auditoria);
- relacionar cada problema a indicadores, tabelas e consultas (rastreabilidade).

**Delimitação:** o modelo cobre toda a cadeia da loja: cadastro (clientes, funcionários, fornecedores, produtos), venda (pedido, itens, pagamento, nota fiscal), estoque (saldo e movimentação), separação e conferência, ocorrências, trocas e devoluções, compras e recebimento de fornecedores, contas a pagar e produção própria de calhas e rufos. Não são modelados: folha de pagamento, contabilidade e emissão fiscal eletrônica (a nota fiscal é registrada com os dados da nota emitida pelo sistema fiscal da loja), e o módulo financeiro de contas a receber (as vendas são pagas no ato).

---

## 1. Caracterização da organização

**Catel HLM** é o nome fantasia de Catel - Hidráulicos, Louças e Metais Ltda, empresa do comércio varejista de materiais de construção com mais de 40 anos de atuação segundo o perfil no AECweb (o CNPJ atual foi aberto em 2004).

| Item | Dado |
|---|---|
| Razão social | Catel - Hidráulicos, Louças e Metais Ltda |
| Nome fantasia | Catel HLM |
| Natureza jurídica | Sociedade Empresária Limitada |
| CNPJ da matriz | 06.969.238/0001-06 (aberto em 18/08/2004) |
| Filial | CNPJ 06.969.238/0002-97, Rua São Severo, 800, Vila Ré, São Paulo/SP (ativa) |
| CNAE | 4744-0/99, comércio varejista de materiais de construção em geral |
| Unidade analisada | Matriz: R. Itinguçu, 2190, Vila Ré, São Paulo/SP, CEP 03658-001 |
| Telefone | (11) 2023-9922 |
| Produtos | Hidráulica, louças, metais, acabamentos, materiais básicos, portas e janelas, pisos, azulejos, pias e gabinetes; fabricação própria de calhas e rufos |
| Canais de venda | Loja física, WhatsApp e outros canais de venda |
| Reputação pública | 4,3 estrelas no Google, com mais de 1.100 avaliações |

**Justificativa da escolha:** operação comercial real, com múltiplos canais, estoque, compras de fornecedores, produção própria, nota fiscal e pós-venda. Há processos suficientes para um modelo relacional com várias entidades e relacionamentos N:M.

**Evidências:** endereço da matriz no Google Maps; telefone; perfil de fornecedor no AECweb; dados cadastrais públicos do CNPJ (ver Referências); entrevista com a operação da loja; avaliações de clientes no Google.

---

## 2. Problemas e necessidades

Cada problema recebe um código (P1 a P4) usado nas tabelas de rastreabilidade (seção 11) e nos comentários do script SQL.

| Código | Problema ou necessidade | Evidência |
|---|---|---|
| P1 | O controle de estoque depende de acompanhamento manual de entradas e saídas; o saldo é conferido fisicamente quando há dúvida. Falta histórico de movimentação e alerta de estoque mínimo. | Entrevista |
| P2 | Produto errado, falta de estoque e falha na entrega são resolvidos caso a caso, sem registro estruturado do tipo, do tempo de resolução e da solução. A conferência na separação não é medida por funcionário. | Entrevista |
| P3 | Trocas e devoluções seguem procedimento próprio, sem registro do fundamento (arrependimento ou vício) nem controle do prazo legal do Código de Defesa do Consumidor. | Entrevista e CDC |
| P4 | Compras de fornecedores, recebimento de mercadoria, contas a pagar, produção própria de calhas e rufos e nota fiscal de venda não estavam representados no modelo da Entrega 1, e a avaliação do professor apontou essa lacuna. | Devolutiva do professor |

---

## 3. Processos de negócio

Os processos foram detalhados com os dados registrados em cada etapa e a tabela do banco que os guarda.

| Nº | Processo | Passos e dados registrados | Tabelas |
|---|---|---|---|
| 1 | Cadastro de clientes | Nome, telefone, CPF/CNPJ (opcional), endereço, data de cadastro. | CLIENTE |
| 2 | Cadastro de produtos | Código, nome, preço, marca, unidade de venda, origem (comprado ou fabricado). | PRODUTO, ESTOQUE |
| 3 | Cadastro de fornecedores | Razão social, CNPJ, telefone, endereço, situação (ativo ou inativo). | FORNECEDOR |
| 4 | Registro do pedido | Canal, cliente, itens com quantidade e preço praticado, tipo de entrega, endereço, valor total, situação. | PEDIDO, ITEM_PEDIDO |
| 5 | Verificação de estoque | Consulta do saldo do produto no momento do pedido, com conferência física quando necessário. | ESTOQUE |
| 6 | Pagamento | Forma, valor, situação e data de cada pagamento; o pedido só segue quando os aprovados cobrem o total. | PAGAMENTO |
| 7 | Emissão da nota fiscal | Número, série, chave de acesso, data e valor da nota do pedido. | NOTA_FISCAL |
| 8 | Separação e conferência | Funcionário, data e hora, resultado (conferido ou divergente) e observação. | SEPARACAO_PEDIDO |
| 9 | Baixa de estoque | Saída por venda registrada com tipo, quantidade, data, funcionário e pedido. | MOVIMENTACAO_ESTOQUE, ESTOQUE |
| 10 | Entrega ou retirada | Data de entrega e situação do pedido (enviado, entregue). | PEDIDO |
| 11 | Tratamento de ocorrências | Tipo, descrição, solução aplicada, data de abertura e de resolução. | OCORRENCIA |
| 12 | Troca, devolução ou reembolso | Produto, fundamento, motivo, condição do produto, tipo e situação. | TROCA_DEVOLUCAO |
| 13 | Pedido de compra | Fornecedor, itens com quantidade e custo, valor total e situação. | PEDIDO_COMPRA, ITEM_PEDIDO_COMPRA |
| 14 | Recebimento de mercadoria | Pedido de compra, funcionário, data, nota do fornecedor e itens recebidos. | RECEBIMENTO, ITEM_RECEBIMENTO |
| 15 | Entrada em estoque | Entrada por compra, produção ou ajuste. | MOVIMENTACAO_ESTOQUE, ESTOQUE |
| 16 | Contas a pagar | Uma conta por recebimento, com vencimento, valor, situação e pagamento. | CONTA_PAGAR |
| 17 | Produção própria | Ordem de produção de calhas e rufos, com produto, quantidade, responsável e situação; gera entrada em estoque. | ORDEM_PRODUCAO, MOVIMENTACAO_ESTOQUE |

---

## 4. Requisitos do sistema

### 4.1 Requisitos funcionais

| Código | Requisito | Tabelas |
|---|---|---|
| RF01 | Cadastrar clientes. | CLIENTE |
| RF02 | Cadastrar funcionários. | FUNCIONARIO |
| RF03 | Cadastrar fornecedores e controlar se estão ativos. | FORNECEDOR |
| RF04 | Cadastrar produtos com código, nome, preço, marca, unidade e origem. | PRODUTO |
| RF05 | Registrar e consultar o saldo e o estoque mínimo de cada produto. | ESTOQUE |
| RF06 | Registrar pedidos feitos na loja, por WhatsApp ou por outros canais. | PEDIDO |
| RF07 | Registrar os produtos, quantidades e preços praticados em cada pedido. | ITEM_PEDIDO |
| RF08 | Registrar pagamentos de um pedido (forma, valor, situação). | PAGAMENTO |
| RF09 | Liberar o pedido para separação somente quando os pagamentos aprovados cobrirem o total. | PEDIDO, PAGAMENTO |
| RF10 | Registrar cliente e endereço quando o pedido for para entrega. | PEDIDO, CLIENTE |
| RF11 | Registrar a nota fiscal de cada pedido enviado ou entregue. | NOTA_FISCAL |
| RF12 | Registrar a separação e a conferência dos produtos. | SEPARACAO_PEDIDO |
| RF13 | Registrar cada entrada e saída de estoque, com tipo, data e responsável. | MOVIMENTACAO_ESTOQUE |
| RF14 | Registrar ocorrências, com solução e data de resolução. | OCORRENCIA |
| RF15 | Registrar trocas, devoluções e reembolsos, com fundamento, motivo e condição do produto. | TROCA_DEVOLUCAO |
| RF16 | Registrar pedidos de compra a fornecedores e seus itens. | PEDIDO_COMPRA, ITEM_PEDIDO_COMPRA |
| RF17 | Registrar o recebimento de mercadoria e os itens recebidos. | RECEBIMENTO, ITEM_RECEBIMENTO |
| RF18 | Gerar e acompanhar contas a pagar a partir dos recebimentos. | CONTA_PAGAR |
| RF19 | Registrar ordens de produção de produtos fabricados pela loja. | ORDEM_PRODUCAO |
| RF20 | Consultar pedidos, pagamentos e situação de entrega. | PEDIDO, PAGAMENTO |
| RF21 | Emitir consultas gerenciais (indicadores) e de auditoria (inconsistências). | Todas |

### 4.2 Requisitos não funcionais

| Código | Requisito | Descrição |
|---|---|---|
| RNF01 | Usabilidade | Informações apresentadas de forma clara e organizada. |
| RNF02 | Integridade | Chaves primárias, estrangeiras, UNIQUE e CHECK impedem dados inconsistentes. |
| RNF03 | Segurança e LGPD | Dados pessoais com acesso restrito ao necessário (matriz de acesso no dicionário de dados). |
| RNF04 | Desempenho | Consultas de estoque e de situação do pedido com resposta rápida; índices nas chaves estrangeiras e UNIQUE. |
| RNF05 | Disponibilidade | O saldo reflete todos os canais de venda. |
| RNF06 | Escalabilidade | O modelo comporta mais produtos, canais, fornecedores e funcionários sem mudar a estrutura. |
| RNF07 | Rastreabilidade | Toda alteração de saldo tem uma movimentação registrada; ocorrências e trocas ficam ligadas ao pedido. |
| RNF08 | Portabilidade | Script único para MySQL 8, InnoDB, utf8mb4. |

---

## 5. Regras de negócio

As regras têm código (RN01 a RN22). O mesmo código aparece nos comentários das restrições do script SQL e nas consultas de auditoria.

| Código | Regra | Onde é garantida |
|---|---|---|
| RN01 | Todo produto tem código único, nome e preço maior que zero. | UNIQUE e CHECK em PRODUTO |
| RN02 | Todo produto tem exatamente um registro de estoque e o saldo nunca é negativo. | UNIQUE, FK e CHECK em ESTOQUE; auditorias A03 e A16 |
| RN03 | Todo pedido tem canal (LOJA, WHATSAPP ou CANAL_VENDA) e tipo (RETIRADA ou ENTREGA). | CHECK em PEDIDO |
| RN04 | Todo pedido tem ao menos um item de quantidade maior que zero, com o preço praticado; o valor total é a soma dos itens. | CHECK em ITEM_PEDIDO; auditorias A01 e A05 |
| RN05 | Pedido para entrega exige cliente e endereço de entrega. | CHECK em PEDIDO; auditoria A04 |
| RN06 | Clientes: CPF/CNPJ opcional (LGPD, coleta mínima de dados); nome e telefone obrigatórios. | Colunas de CLIENTE |
| RN07 | Pagamento: PIX, crédito, débito ou dinheiro; valor maior que zero; situação aprovado, recusado ou pendente. | CHECK em PAGAMENTO |
| RN08 | O pedido só é liberado para separação quando os pagamentos aprovados cobrem o valor total. | Auditoria A02 |
| RN09 | Toda separação é conferida; resultado divergente exige observação. | CHECK em SEPARACAO_PEDIDO |
| RN10 | Ocorrência tem tipo e descrição; ao ser resolvida exige solução e data de resolução; ocorrência aberta não tem solução. | CHECK em OCORRENCIA; auditoria A08 |
| RN11 | Troca ou devolução refere-se a produto do pedido, com tipo e situação definidos. | CHECK em TROCA_DEVOLUCAO; auditoria A10 |
| RN12 | Prazos legais (CDC): arrependimento em compra fora da loja, 7 dias (art. 49); vício de produto, 30 dias para não durável e 90 para durável (art. 26). | Coluna `fundamento`; auditoria A09 |
| RN13 | CPF (11 dígitos) ou CNPJ (14 dígitos), sem repetição entre clientes. | UNIQUE e CHECK em CLIENTE |
| RN14 | Pedido enviado ou entregue tem uma nota fiscal, com valor igual ao do pedido. | UNIQUE em NOTA_FISCAL; auditorias A06 e A07 |
| RN15 | Nota fiscal tem número e série únicos e chave de acesso de 44 dígitos única. | UNIQUE e CHECK em NOTA_FISCAL |
| RN16 | Compras só de fornecedor cadastrado e ativo; CNPJ do fornecedor único. | FK, UNIQUE e CHECK; auditoria A17 |
| RN17 | Item de pedido de compra tem quantidade e custo maiores que zero. | CHECK em ITEM_PEDIDO_COMPRA |
| RN18 | O recebimento não ultrapassa o pedido de compra; a situação do pedido de compra reflete o recebido. | CHECK; auditorias A11 e A12 |
| RN19 | Todo recebimento gera uma conta a pagar e uma entrada em estoque. | UNIQUE em CONTA_PAGAR; auditorias A13 e A14 |
| RN20 | Conta a pagar tem valor maior que zero; conta paga exige data e forma de pagamento. | CHECK em CONTA_PAGAR |
| RN21 | O saldo do estoque é igual à soma das movimentações; cada movimentação tem a origem correspondente ao seu tipo (venda, compra, produção ou ajuste). | CHECK em MOVIMENTACAO_ESTOQUE; auditoria A15 |
| RN22 | Somente produto de origem FABRICADO tem ordem de produção. | CHECK em PRODUTO; auditoria A18 |

**Restrições externas:** LGPD (Lei 13.709/2018), com CPF como dado pessoal (art. 5º, I) e coleta limitada à finalidade; Código de Defesa do Consumidor (Lei 8.078/1990), arts. 26 e 49.

---

## 6. Modelo conceitual (DER)

O DER conceitual foi feito no brModelo, com notação (mínimo, máximo) e sem chaves estrangeiras. O arquivo está em `modelagem/` (ver seção 12). A tabela resume as entidades e as cardinalidades.

| Relacionamento | Cardinalidade |
|---|---|
| CLIENTE realiza PEDIDO | CLIENTE (0,N) — PEDIDO (0,1) |
| PEDIDO possui ITEM_PEDIDO | PEDIDO (1,N) — ITEM_PEDIDO (1,1) |
| PRODUTO compõe ITEM_PEDIDO | PRODUTO (0,N) — ITEM_PEDIDO (1,1) |
| PEDIDO é pago por PAGAMENTO | PEDIDO (0,N) — PAGAMENTO (1,1) |
| PEDIDO tem NOTA_FISCAL | PEDIDO (0,1) — NOTA_FISCAL (1,1) |
| PRODUTO possui ESTOQUE | PRODUTO (1,1) — ESTOQUE (1,1) |
| PEDIDO passa por SEPARACAO_PEDIDO | PEDIDO (0,N) — SEPARACAO_PEDIDO (1,1) |
| FUNCIONARIO realiza SEPARACAO_PEDIDO | FUNCIONARIO (0,N) — SEPARACAO_PEDIDO (1,1) |
| PEDIDO gera OCORRENCIA | PEDIDO (0,N) — OCORRENCIA (1,1) |
| PEDIDO origina TROCA_DEVOLUCAO | PEDIDO (0,N) — TROCA_DEVOLUCAO (1,1) |
| PRODUTO é objeto de TROCA_DEVOLUCAO | PRODUTO (0,N) — TROCA_DEVOLUCAO (1,1) |
| FORNECEDOR recebe PEDIDO_COMPRA | FORNECEDOR (0,N) — PEDIDO_COMPRA (1,1) |
| PEDIDO_COMPRA possui ITEM_PEDIDO_COMPRA | PEDIDO_COMPRA (1,N) — ITEM_PEDIDO_COMPRA (1,1) |
| PRODUTO é comprado em ITEM_PEDIDO_COMPRA | PRODUTO (0,N) — ITEM_PEDIDO_COMPRA (1,1) |
| PEDIDO_COMPRA é atendido por RECEBIMENTO | PEDIDO_COMPRA (0,N) — RECEBIMENTO (1,1) |
| RECEBIMENTO possui ITEM_RECEBIMENTO | RECEBIMENTO (1,N) — ITEM_RECEBIMENTO (1,1) |
| ITEM_PEDIDO_COMPRA é recebido em ITEM_RECEBIMENTO | ITEM_PEDIDO_COMPRA (0,N) — ITEM_RECEBIMENTO (1,1) |
| FUNCIONARIO realiza RECEBIMENTO | FUNCIONARIO (0,N) — RECEBIMENTO (1,1) |
| RECEBIMENTO gera CONTA_PAGAR | RECEBIMENTO (0,1) — CONTA_PAGAR (1,1) |
| PRODUTO é fabricado em ORDEM_PRODUCAO | PRODUTO (0,N) — ORDEM_PRODUCAO (1,1) |
| FUNCIONARIO executa ORDEM_PRODUCAO | FUNCIONARIO (0,N) — ORDEM_PRODUCAO (1,1) |
| PRODUTO tem MOVIMENTACAO_ESTOQUE | PRODUTO (0,N) — MOVIMENTACAO_ESTOQUE (1,1) |
| FUNCIONARIO registra MOVIMENTACAO_ESTOQUE | FUNCIONARIO (0,N) — MOVIMENTACAO_ESTOQUE (1,1) |
| PEDIDO, RECEBIMENTO ou ORDEM_PRODUCAO originam MOVIMENTACAO_ESTOQUE | cada um (0,N) — MOVIMENTACAO_ESTOQUE (0,1); a movimentação tem uma única origem, conforme o tipo (RN21) |

Entidades associativas: ITEM_PEDIDO (PEDIDO N:M PRODUTO), ITEM_PEDIDO_COMPRA (PEDIDO_COMPRA N:M PRODUTO) e ITEM_RECEBIMENTO (RECEBIMENTO N:M ITEM_PEDIDO_COMPRA).


### 7.1 Conversão do conceitual para o lógico

| Regra de conversão | Aplicação |
|---|---|
| Entidade vira tabela, atributo vira coluna | As 20 entidades viram as 20 tabelas do script. |
| Relacionamento 1:N: a chave do lado 1 vai como FK para o lado N | Por exemplo, `PEDIDO.id_cliente`, `PAGAMENTO.id_pedido`, `PEDIDO_COMPRA.id_fornecedor`. |
| Relacionamento 1:1: a FK recebe UNIQUE | `ESTOQUE.id_produto`, `NOTA_FISCAL.id_pedido`, `CONTA_PAGAR.id_recebimento`. |
| Relacionamento N:M vira tabela associativa com duas FKs | ITEM_PEDIDO, ITEM_PEDIDO_COMPRA e ITEM_RECEBIMENTO, com atributos próprios (quantidade, preço, custo). |
| Participação mínima 0 vira FK opcional (NULL) | `PEDIDO.id_cliente` (venda de balcão) e as três FKs de origem em MOVIMENTACAO_ESTOQUE. |
| Atributo com domínio fixo vira CHECK | Canal, forma de pagamento, situações, tipos. |

### 7.2 Chaves primárias e estrangeiras

| Tabela | Chave primária | Chaves estrangeiras |
|---|---|---|
| CLIENTE | id_cliente | — |
| FUNCIONARIO | id_funcionario | — |
| FORNECEDOR | id_fornecedor | — |
| PRODUTO | id_produto | — |
| ESTOQUE | id_estoque | id_produto → PRODUTO |
| PEDIDO | id_pedido | id_cliente → CLIENTE |
| ITEM_PEDIDO | id_item | id_pedido → PEDIDO; id_produto → PRODUTO |
| PAGAMENTO | id_pagamento | id_pedido → PEDIDO |
| NOTA_FISCAL | id_nota | id_pedido → PEDIDO |
| SEPARACAO_PEDIDO | id_separacao | id_pedido → PEDIDO; id_funcionario → FUNCIONARIO |
| OCORRENCIA | id_ocorrencia | id_pedido → PEDIDO |
| TROCA_DEVOLUCAO | id_troca | id_pedido → PEDIDO; id_produto → PRODUTO |
| PEDIDO_COMPRA | id_pedido_compra | id_fornecedor → FORNECEDOR |
| ITEM_PEDIDO_COMPRA | id_item_compra | id_pedido_compra → PEDIDO_COMPRA; id_produto → PRODUTO |
| RECEBIMENTO | id_recebimento | id_pedido_compra → PEDIDO_COMPRA; id_funcionario → FUNCIONARIO |
| ITEM_RECEBIMENTO | id_item_recebimento | id_recebimento → RECEBIMENTO; id_item_compra → ITEM_PEDIDO_COMPRA |
| CONTA_PAGAR | id_conta | id_recebimento → RECEBIMENTO |
| ORDEM_PRODUCAO | id_ordem_producao | id_produto → PRODUTO; id_funcionario → FUNCIONARIO |
| MOVIMENTACAO_ESTOQUE | id_movimentacao | id_produto → PRODUTO; id_funcionario → FUNCIONARIO; id_pedido → PEDIDO; id_recebimento → RECEBIMENTO; id_ordem_producao → ORDEM_PRODUCAO |

---

## 8. Normalização

### 8.1 Primeira forma normal (1FN)

Todas as colunas guardam valores atômicos e não há grupos repetidos. O endereço do cliente foi dividido em logradouro, número, bairro e CEP; os itens de um pedido, que numa planilha ficariam em colunas "produto1, produto2...", ficam em linhas de ITEM_PEDIDO. O mesmo vale para itens de compra e de recebimento.

### 8.2 Segunda forma normal (2FN)

As tabelas com chave composta natural seriam ITEM_PEDIDO (pedido + produto), ITEM_PEDIDO_COMPRA e ITEM_RECEBIMENTO. Nelas, `quantidade` e `preco_unitario` dependem do par inteiro. O nome e o preço atual do produto dependem só de `id_produto` e por isso ficam em PRODUTO, e não repetidos em cada item. Para evitar dependência parcial, as tabelas têm chave substituta e UNIQUE sobre o par (por exemplo, `uq_item_pedido_produto` em pedido + produto).

### 8.3 Terceira forma normal (3FN)

Não há dependência transitiva entre colunas não chave:

- o nome e o telefone do cliente não são copiados em PEDIDO (dependem de `id_cliente`);
- o saldo do estoque fica em ESTOQUE, e não em PRODUTO;
- a razão social do fornecedor não é repetida em PEDIDO_COMPRA;
- o funcionário que separa, recebe ou produz aparece apenas por `id_funcionario`.

### 8.4 Redundâncias mantidas de propósito

| Coluna | Motivo | Controle |
|---|---|---|
| `PEDIDO.valor_total` e `PEDIDO_COMPRA.valor_total` | Guardam o total no momento do fechamento, sem recalcular a cada consulta. | Auditoria A05 |
| `ITEM_PEDIDO.preco_unitario` | Preço praticado na venda; se o preço do produto mudar, o histórico não muda. | RN04 |
| `NOTA_FISCAL.valor_total` | Valor da nota emitida, que pode ser conferido com o pedido. | Auditoria A07 |
| `ESTOQUE.quantidade_disponivel` | Saldo acumulado para consulta rápida; a verdade está em MOVIMENTACAO_ESTOQUE. | Auditoria A15 |

---

## 9. Justificativas técnicas

| Decisão | Justificativa | Regra |
|---|---|---|
| PEDIDO como entidade central | Liga cliente, itens, pagamento, nota, separação, ocorrência, troca e movimentação. | RN03, RN04 |
| ITEM_PEDIDO associativa | Resolve o N:M entre pedido e produto e guarda quantidade e preço histórico. | RN04 |
| `canal_pedido` como atributo | O canal é característica do pedido; uma entidade por canal duplicaria estrutura. | RN03 |
| Cliente opcional no pedido | Venda de balcão não exige identificação (coleta mínima de dados, LGPD). | RN05, RN06 |
| ESTOQUE separado de PRODUTO | Evita duplicar o saldo no cadastro. | RN02 |
| MOVIMENTACAO_ESTOQUE | Dá histórico ao estoque e permite auditar o saldo. | RN21 |
| PEDIDO 1:N PAGAMENTO | Os pagamentos aprovados somados definem a liberação do pedido; o modelo comporta mais de um pagamento. | RN07, RN08 |
| NOTA_FISCAL 1:1 com PEDIDO | Cada pedido enviado ou entregue tem uma nota. | RN14, RN15 |
| OCORRENCIA separada de TROCA_DEVOLUCAO | A primeira trata de problema no processo do pedido; a segunda, de pós-venda de produto já recebido, com prazo legal. | RN10 a RN12 |
| `fundamento` em TROCA_DEVOLUCAO | Distingue arrependimento (7 dias) de vício (30 ou 90 dias). | RN12 |
| FORNECEDOR, PEDIDO_COMPRA, RECEBIMENTO | Compra e entrada de mercadoria são processos reais; o recebimento pode ser parcial. | RN16 a RN18 |
| ITEM_RECEBIMENTO ligado ao item comprado | Permite comparar o recebido com o pedido item a item. | RN18 |
| CONTA_PAGAR 1:1 com RECEBIMENTO | O compromisso financeiro nasce da mercadoria recebida. | RN19, RN20 |
| ORDEM_PRODUCAO | A loja fabrica calhas e rufos; a produção gera entrada em estoque. | RN22 |
| `ativo` em FUNCIONARIO, FORNECEDOR e PRODUTO | Permite desativar sem apagar o histórico (as FKs impedem exclusão). | RN16 |
| `DECIMAL(10,3)` para quantidade | Há produtos vendidos por metro e quilo. | RN02 |
| CHECK em vez de tabelas de domínio | Os domínios são pequenos e fixos; o CHECK é mais simples e mantém a regra junto da coluna. | RN03, RN07 |

**Alternativas rejeitadas:**

| Alternativa | Motivo |
|---|---|
| Saldo apenas em PRODUTO | Duas fontes para a mesma informação e sem histórico. |
| PEDIDO ligado direto a PRODUTO | Não guardaria quantidade nem preço histórico. |
| Unificar OCORRENCIA e TROCA_DEVOLUCAO | Misturaria problema de processo com pós-venda e prazos legais. |
| Unificar PEDIDO e PEDIDO_COMPRA | São processos distintos, com atores, itens e situações diferentes. |
| Endereço do cliente em campo único | Quebraria a 1FN e impediria consultas por bairro. |

---

## 10. Implementação SQL e massa de dados

O arquivo [`docs/script.sql`](docs/script.sql) cria o banco do zero em MySQL 8 e foi executado do início ao fim, sem erros, em MySQL 8.0.46. Ele contém:

1. `CREATE DATABASE catel_hlm` (utf8mb4);
2. `CREATE TABLE` das 20 tabelas, com PK, FK, UNIQUE, CHECK e DEFAULT, cada restrição comentada com o código da regra (RN01 a RN22);
3. `INSERT INTO` da massa de dados fictícia;
4. quatro `SELECT` com `JOIN` (J01 a J04);
5. dois `UPDATE` (U01 e U02) e um `DELETE` (D01);
6. 18 consultas gerenciais (G01 a G18);
7. 18 consultas de auditoria (A01 a A18).

Para executar: `mysql -u root -p < docs/script.sql`.

### 10.1 Massa de dados

Todos os dados são fictícios (nomes, CPFs, CNPJs, telefones e endereços inventados); nenhum dado real de cliente, funcionário ou fornecedor foi usado. Os dados foram gerados por um script Python com semente fixa (resultado reproduzível) e escritos como comandos `INSERT` no script SQL.

| Tabela | Linhas | Como o volume foi definido |
|---|---|---|
| CLIENTE | 45 | Cadastro de quem compra com entrega; vendas de balcão não têm cliente. |
| FUNCIONARIO | 9 | Cargos de balcão, separação, estoque, produção e financeiro. |
| FORNECEDOR | 8 | Um fornecedor por família de produto; um deles inativo. |
| PRODUTO | 60 | Cobre as famílias vendidas (hidráulica, louças, metais, acabamentos, portas e janelas, pisos, caixas d'água) e 9 itens de fabricação própria (calhas, rufos e acessórios). |
| PEDIDO | 180 | Período de 01/07/2026 a 31/10/2026, com mais pedidos de loja do que de WhatsApp. |
| ITEM_PEDIDO | 435 | Entre 1 e 5 itens por pedido. |
| PAGAMENTO | 209 | Pelo menos um pagamento por pedido; 30 pedidos têm mais de um pagamento. |
| NOTA_FISCAL | 165 | Uma por pedido enviado ou entregue. |
| SEPARACAO_PEDIDO | 183 | Uma conferência por pedido liberado, com alguns divergentes. |
| OCORRENCIA | 13 | Poucas, como é esperado em operação estável. |
| TROCA_DEVOLUCAO | 16 | Parte por arrependimento (compras remotas) e parte por vício. |
| PEDIDO_COMPRA | 23 | Entre 5 e 6 por mês, em situações ABERTO, PARCIAL e RECEBIDO. |
| ITEM_PEDIDO_COMPRA | 73 | Entre 2 e 5 itens por compra. |
| RECEBIMENTO | 23 | Alguns pedidos de compra recebidos em duas entregas. |
| ITEM_RECEBIMENTO | 78 | Itens recebidos de cada compra. |
| CONTA_PAGAR | 23 | Uma por recebimento. |
| ORDEM_PRODUCAO | 18 | Produção de calhas, rufos e acessórios. |
| MOVIMENTACAO_ESTOQUE | 557 | Entradas (compra, produção, ajuste inicial) e saídas por venda. |

**Coerência dos dados:** cada pedido tem itens com o preço do produto na data; o valor total é a soma dos itens; o saldo do estoque é calculado a partir das movimentações; cada recebimento gera conta a pagar e entrada em estoque; as datas seguem a ordem do processo (pedido, pagamento, separação, entrega, ocorrência ou troca).

**Inconsistências propositais:** o script insere quatro inconsistências para demonstrar as consultas de auditoria, e elas estão comentadas no início da seção de INSERT:

| Pedido | Inconsistência | Auditoria |
|---|---|---|
| 173 | Em separação com pagamentos aprovados abaixo do valor total | A02 |
| 4 | Valor total diferente da soma dos itens e da nota fiscal | A05 e A07 |
| 12 | Entregue sem nota fiscal | A06 |

As demais auditorias retornam vazio, o que mostra que as restrições do banco impedem as outras inconsistências.

### 10.2 Consultas de manipulação

| Código | Comando | O que faz |
|---|---|---|
| J01 a J04 | SELECT com JOIN | Pedidos com cliente e itens, itens com produto, pagamentos, recebimentos com fornecedor. |
| U01 | UPDATE | Reajuste de 5% nos preços da marca Tigre; os pedidos antigos não mudam porque guardam o preço praticado (RN04). |
| U02 | UPDATE | Resolve uma ocorrência aberta e devolve o pedido para ENVIADO (RN10). |
| D01 | DELETE | Remove um cadastro de teste sem pedidos; as FKs impedem apagar cliente com pedido. |

---

## 11. BI e IA: rastreabilidade

### 11.1 Do problema ao indicador

| Problema | Pergunta de negócio | Indicador | Consulta | Tabelas |
|---|---|---|---|---|
| P1 | Quais produtos estão abaixo do mínimo? | Itens abaixo do estoque mínimo | G01 | ESTOQUE, PRODUTO |
| P1 | Quanto entrou e saiu por mês? | Entradas e saídas por tipo | G02 | MOVIMENTACAO_ESTOQUE |
| P1 | Quantos dias de venda o estoque cobre? | Cobertura de estoque em dias | G03 | ESTOQUE, MOVIMENTACAO_ESTOQUE, PRODUTO |
| P2 | Quantas ocorrências, de que tipo e em quanto tempo resolvidas? | Ocorrências por tipo, abertas, tempo de resolução | G04 | OCORRENCIA |
| P2 | Quem erra mais na conferência? | Taxa de conferência divergente por funcionário | G05 | SEPARACAO_PEDIDO, FUNCIONARIO |
| P3 | Quantas trocas e devoluções, por quê? | Solicitações por fundamento e situação | G06 | TROCA_DEVOLUCAO |
| P3 | Quais produtos mais voltam? | Percentual de pedidos entregues com troca, por produto | G07 | TROCA_DEVOLUCAO, PEDIDO, PRODUTO |
| Vendas | Quanto cada canal fatura? | Faturamento mensal por canal | G08 | PEDIDO, PAGAMENTO |
| Vendas | Qual o ticket médio? | Ticket médio por canal | G09 | PEDIDO |
| Vendas | Quantos pedidos são cancelados? | Taxa de cancelamento mensal | G10 | PEDIDO |
| Vendas | O que mais gera receita? | Top 10 produtos por receita | G11 | ITEM_PEDIDO, PRODUTO |
| P2 | Quanto leva do pedido à entrega? | Prazo médio de entrega | G12 | PEDIDO |
| Vendas | Como o cliente paga? | Faturamento por forma de pagamento | G13 | PAGAMENTO |
| P4 | Quanto devemos aos fornecedores? | Contas em aberto e vencidas por fornecedor | G14 | CONTA_PAGAR, RECEBIMENTO, PEDIDO_COMPRA, FORNECEDOR |
| P4 | O que ainda falta receber? | Pedidos de compra com saldo a receber | G15 | PEDIDO_COMPRA, ITEM_PEDIDO_COMPRA, ITEM_RECEBIMENTO |
| P4 | Qual a margem dos produtos? | Margem bruta estimada (preço x último custo) | G16 | PRODUTO, ITEM_PEDIDO_COMPRA |
| P4 | A produção própria acompanha as vendas? | Produzido x vendido | G17 | ORDEM_PRODUCAO, ITEM_PEDIDO |
| Vendas | Quais clientes nunca compraram? | Clientes sem pedido | G18 | CLIENTE, PEDIDO |

### 11.2 Auditoria: regra e consulta

| Consulta | Regra verificada | Consulta | Regra verificada |
|---|---|---|---|
| A01 | RN04 (pedido sem item) | A10 | RN11 (produto fora do pedido) |
| A02 | RN08 (liberado sem pagamento) | A11 | RN18 (recebido a mais) |
| A03 | RN02 (saldo negativo) | A12 | RN18 (situação da compra) |
| A04 | RN05 (entrega sem cliente ou endereço) | A13 | RN19 (recebimento sem conta) |
| A05 | RN04 (total diferente dos itens) | A14 | RN19 e RN21 (sem entrada em estoque) |
| A06 | RN14 (sem nota fiscal) | A15 | RN21 (saldo diferente das movimentações) |
| A07 | RN14 (nota com valor diferente) | A16 | RN02 (produto sem estoque) |
| A08 | RN10 (ocorrência incoerente) | A17 | RN16 (compra com fornecedor inativo) |
| A09 | RN12 (troca fora do prazo) | A18 | RN22 (produção de item não fabricado) |

### 11.3 Proposta de BI

Um painel (por exemplo, Power BI ou Metabase) ligado ao MySQL, com as consultas G01 a G18 como fontes: estoque (G01 a G03), qualidade da operação (G04, G05, G12), pós-venda (G06, G07), vendas (G08 a G11, G13, G18) e compras e finanças (G14 a G17). As consultas A01 a A18 alimentam uma página de alertas que deve estar vazia.

### 11.4 Proposta de IA

| Aplicação | Dados | Problema |
|---|---|---|
| Previsão de demanda por produto, para sugerir quantidade de compra ou produção | Saídas por venda em MOVIMENTACAO_ESTOQUE | P1 |
| Alerta antecipado de ruptura, combinando cobertura (G03) e prazo de entrega do fornecedor | ESTOQUE, PEDIDO_COMPRA, RECEBIMENTO | P1, P4 |
| Classificação automática de ocorrências a partir da descrição | OCORRENCIA | P2 |
| Previsão de risco de devolução por produto e fundamento | TROCA_DEVOLUCAO, ITEM_PEDIDO | P3 |
| Detecção de anomalias nos dados (complementa A01 a A18) | Todas | P2, P4 |

A previsão exige mais histórico do que os quatro meses da massa fictícia; as propostas são o próximo passo, não parte da implementação desta entrega.

---

## 12. Estrutura do repositório

```
Catel-HLM/
├── README.md                      relatório (este arquivo)
├── levantamento/                  roteiro e registro do levantamento de campo
├── modelagem/                     DER conceitual e modelo lógico (brModelo e imagens)
├── docs/
│   ├── script.sql                 script SQL completo
│   └── dicionario_de_dados.html   dicionário de dados
└── evidencias/                    fotos e imagens da organização
```

Os commits são feitos por cada integrante com a própria conta, e as alterações entram na `main` por pull request.

---

## 13. Uso de inteligência artificial

| Item | Registro |
|---|---|
| **Ferramenta e etapa** | Claude (Anthropic), em três etapas: (1) revisão do README contra a avaliação do professor; (2) escrita do script SQL (DDL, consultas gerenciais e de auditoria) e de um gerador de dados fictícios em Python; (3) reescrita do README da Entrega 2. |
| **Motivação** | Ganhar tempo em partes repetitivas (INSERTs, consultas) e conferir a consistência entre regras, tabelas e consultas. |
| **Prompts utilizados** | "Veja se o que já foi melhorado corresponde com aquilo que o professor apontou."; "Utilizando essas exigências, quais são as melhorias que eu deveria colocar no repositório?"; "Melhore tudo o que puder." |
| **Resposta recebida** | Lista de lacunas em relação à avaliação (fornecedor, nota fiscal, movimentação de estoque, rastreabilidade); proposta do modelo lógico de 20 tabelas; script SQL; gerador de massa de dados; rascunho deste README. |
| **Como foi verificado** | O script foi executado do zero em MySQL 8.0.46 sem erros; as 18 consultas de auditoria foram executadas e só as inconsistências propositais apareceram; as consultas gerenciais foram conferidas contra os dados inseridos. |
| **Trechos rejeitados ou corrigidos** | Foi removida uma afirmação gerada pela IA de que o pagamento dividido seria prática comum na loja, por não ter vindo da pesquisa de campo. Uma consulta de atualização (U02) foi corrigida porque deixava o pedido com situação incoerente. A IA também não conseguiu ler o PDF do DER, então a conferência da imagem ficou com o grupo. |
| **Reflexão crítica** | A IA acelera a escrita de SQL e a conferência cruzada, mas inventou um fato sobre a loja e deixou uma inconsistência no UPDATE; só a execução e a leitura do grupo pegaram esses erros. Dados sobre a organização devem vir do campo, e o grupo precisa entender cada consulta que entrega. |

---

## Correções da Entrega 1

Pontos apontados na avaliação do professor (issue #5 do repositório e devolutiva em aula) e o que foi feito.

| Ponto apontado | Correção nesta entrega |
|---|---|
| Processos superficiais | Seção 3: 17 processos, cada um com os dados registrados e as tabelas que os guardam. |
| Faltava nota fiscal | Entidade NOTA_FISCAL, regras RN14 e RN15 e auditorias A06 e A07. |
| Faltava fornecedor | FORNECEDOR, PEDIDO_COMPRA, ITEM_PEDIDO_COMPRA, RECEBIMENTO, ITEM_RECEBIMENTO e CONTA_PAGAR (RN16 a RN20). |
| Faltava movimentação de estoque | MOVIMENTACAO_ESTOQUE (RN21), com auditoria do saldo (A15). |
| Faltava a fabricação própria de calhas e rufos | ORDEM_PRODUCAO e `PRODUTO.origem` (RN22). |
| Problemas, processos e requisitos sem numeração | Códigos P1 a P4, RF01 a RF21, RNF01 a RNF08 e RN01 a RN22, um por linha. |
| Falta de rastreabilidade | Seção 11: problema, indicador, consulta e tabelas; auditoria, regra e consulta. |
| Falta de normalização | Seção 8: 1FN, 2FN, 3FN e redundâncias mantidas, com justificativa. |
| Falta de explicação da massa de dados | Seção 10.1: origem, volume por tabela e inconsistências propositais. |
| Uso de IA sem registro completo | Seção 13, com prompts, verificação e trechos corrigidos. |
| Imagens do DER e do modelo lógico | Pasta `modelagem/` (ver seção 12). |

---

## Conclusão

**Síntese:** o projeto entrega o modelo conceitual, o modelo lógico (20 tabelas), a normalização até a 3FN, um script SQL executável com massa de dados fictícia, consultas gerenciais e de auditoria, e a rastreabilidade entre problemas, regras, tabelas e consultas.

**Contribuições:** a loja passa a ter uma estrutura de dados única para vendas, estoque, compras, produção e pós-venda, com regras garantidas pelo próprio banco e consultas prontas para acompanhar a operação.

**Aprendizados:** a diferença entre modelo conceitual e lógico; o uso de entidades associativas; a normalização como forma de evitar redundância, e as redundâncias que se mantêm de propósito, com auditoria; e o valor de ligar cada regra a uma restrição e a uma consulta.

**Trabalhos futuros:** interface de cadastro e consulta, integração com o emissor de nota fiscal, contas a receber e implantação do painel de BI.

---

## Referências

- BRASIL. Lei nº 8.078, de 11 de setembro de 1990 (Código de Defesa do Consumidor).
- BRASIL. Lei nº 13.709, de 14 de agosto de 2018 (Lei Geral de Proteção de Dados Pessoais).
- EMPRESAQUI. *Catel - Hidraulicos, Loucas e Metais Ltda*. Disponível em: https://www.empresaqui.com.br/detalhes-de-empresas/06969238000106-CATEL---HIDRAULICOS-LOUCAS-E-METAIS-LTDA. Acesso em: 27 out. 2026.
- AECWEB. Guia de fornecedores: Catel Hidráulicos, Louças e Metais. Disponível em: https://www.aecweb.com.br. Acesso em: 27 out. 2026.
- GOOGLE MAPS. Catel HLM, R. Itinguçu, 2190, São Paulo. Disponível em: https://www.google.com/maps.
- ORACLE. *MySQL 8.0 Reference Manual*. Disponível em: https://dev.mysql.com/doc/refman/8.0/en/.
- ANTHROPIC. Claude. Modelo de linguagem utilizado em 2026.
