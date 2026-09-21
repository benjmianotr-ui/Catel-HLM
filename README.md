# Catel HLM — Modelo Conceitual de Banco de Dados

> **Base deste documento:** esta é uma cópia adaptada do modelo conceitual do projeto *We Coffee* (entidades, seções e formato preservados), reestruturada a partir de um novo levantamento de requisitos (entrevista) feito com a operação da **Catel HLM**, loja de materiais de construção (hidráulica, louças e metais) localizada na Vila Ré, São Paulo/SP. Dados de endereço, segmento e CNAE foram confirmados via Google Maps e portal AECweb; o CNPJ abaixo corresponde a uma empresa de mesmo nome, mesma atividade e mesma cidade, mas não foi possível confirmar o endereço exato na base pública gratuita consultada — vale conferir antes de usar oficialmente.

# Integrantes

| Nome | RGM |
|----|----|
| [Nome 1] | [RGM] |
| [Nome 2] | [RGM] |
| [Nome 3] | [RGM] |

## Entrega 1 — Modelo Conceitual (DER)

**Organização analisada:** Catel HLM
**Unidade:** R. Itinguçu, 2190 - Vila Ré, São Paulo - SP, 03658-001
**Segmento:** Comércio varejista de materiais de construção — hidráulica, louças, metais, acabamentos, materiais básicos, portas e janelas, pisos, azulejos, pias e gabinetes, com venda em loja física, WhatsApp e canais de venda online

> Este README apresenta o levantamento de requisitos, processos de negócio, regras, dicionário de dados, modelagem conceitual, DER e justificativas técnicas do projeto.

---

# 1. Caracterização da Organização

## Nome e natureza da organização

A organização analisada é a **Catel HLM** (nome fantasia — HLM referindo-se a Hidráulica, Louças e Metais), atuante há mais de 40 anos no mercado de materiais de construção: hidráulica, louças, metais, acabamentos, materiais básicos, portas e janelas, pisos, azulejos, pias e gabinetes, com fabricação própria de calhas e rufos. A loja comercializa produtos por meio de atendimento presencial e também por canais remotos, como WhatsApp e outros canais de venda.
**Razão social (provável):** Catel - Hidráulicos, Louças e Metais Ltda
**CNPJ (provável):** 06.969.238/0001-06 — mesmo nome, atividade (CNAE 4744-0/99 — Comércio varejista de materiais de construção em geral) e cidade, mas endereço exato não confirmado na base pública gratuita
**Telefone:** (11) 2023-9922
**Site/Redes sociais:** [não localizado em busca pública]
**Unidade analisada:** R. Itinguçu, 2190 - Vila Ré, São Paulo - SP, 03658-001

> A loja possui avaliação 4,3★ no Google (mais de 1.100 avaliações), com elogios recorrentes à variedade de materiais, preços competitivos e entrega dentro do prazo.

## Contexto e porte

A unidade trabalha com diferentes formas de atendimento:

- **Loja física:** o cliente compra diretamente no balcão/loja.
- **WhatsApp:** o cliente faz o pedido por mensagem, informando produtos e quantidades.
- **Canais de venda:** pedidos recebidos por outros canais de venda da empresa.

Após o registro do pedido, os produtos são separados no estoque, conferidos e, quando necessário, embalados para entrega.

## Problemas e necessidades identificados

Durante o levantamento, foi identificado que o controle de estoque depende do acompanhamento manual das entradas e saídas, e que, ao receber um pedido, a equipe precisa verificar a quantidade disponível no sistema e, em alguns casos, conferir fisicamente no estoque.

Também foi observado que problemas como produto errado, falta de estoque ou falha na entrega são tratados caso a caso, por meio de contato direto com o cliente, sem um registro estruturado do motivo e da solução aplicada.

Dessa forma, o projeto busca estruturar os dados de produtos, pedidos, pagamentos, estoque, separação/conferência, ocorrências e trocas/devoluções para facilitar o controle da operação e futuras análises gerenciais.

## Justificativa da escolha

A loja foi escolhida por apresentar um cenário real de operação comercial com múltiplos canais de venda (presencial, WhatsApp e canais de venda), controle de estoque, conferência de pedidos antes do envio e tratamento de problemas pós-venda (trocas e devoluções), o que oferece um bom conjunto de processos para modelagem de um banco de dados.

## Evidências da organização

Foram obtidas evidências da existência e do acesso à organização, incluindo:

- endereço confirmado: R. Itinguçu, 2190 - Vila Ré, São Paulo - SP, 03658-001 (Google Maps);
- telefone de contato: (11) 2023-9922;
- perfil como fornecedor de materiais de construção no portal AECweb (hidráulica, louças, metais, acabamentos, portas e janelas, pisos, azulejos, pias e gabinetes, calhas e rufos de fabricação própria);
- avaliações de clientes no Google (4,3★, +1.100 avaliações) citando variedade de materiais, preços competitivos e entrega dentro do prazo;
- entrevista com a operação da loja sobre cadastro de produtos, pedidos, estoque, pagamento, separação e trocas/devoluções.

---

# 2. Processos de Negócio

## Principais processos mapeados

Com base na entrevista, foram identificados os seguintes processos:

- **Cadastro de produtos:** registro de nome, preço, código e quantidade em estoque, além de marca e unidade de venda quando aplicável.
- **Realização do pedido:** o cliente compra diretamente na loja ou faz o pedido pelo WhatsApp/canais de venda.
- **Registro do pedido:** registro dos produtos escolhidos, quantidades, valor da compra, forma de pagamento e, quando há entrega, dados do cliente e endereço.
- **Controle de estoque:** acompanhamento das entradas e saídas e verificação da disponibilidade do produto no momento do pedido, com conferência física quando necessário.
- **Confirmação de pagamento:** verificação da aprovação do pagamento; após confirmado, o pedido é liberado para separação e preparo.
- **Separação e conferência:** o funcionário retira os produtos do estoque, confere a quantidade e se são os produtos corretos, e embala os itens para entrega.
- **Tratamento de problemas:** contato com o cliente em casos de produto errado, falta de estoque ou problema na entrega, com substituição do produto, correção do pedido ou nova entrega, conforme o caso.
- **Troca ou devolução:** verificação do motivo e da condição do produto, seguindo o procedimento da empresa para troca, devolução ou reembolso.

## Fluxograma

> Insira aqui o fluxograma do processo (pedido → pagamento → separação/conferência → entrega → pós-venda), no mesmo formato usado no projeto original (`image-1.png`).

### Legenda

| Elemento | Significado |
|---|---|
| 🟢 | Início / Fim |
| ▭ | Processo / Atividade |
| ♦️ | Decisão |
| Setas | Fluxo de execução |

---

# 3. Requisitos do Sistema

## 3.1 Requisitos Funcionais

| Requisito | Entidade e associação |
|---|---|
| O sistema deve permitir cadastrar clientes. | CLIENTE — identificado por CPF/CNPJ (opcional) e associado a PEDIDO. |
| O sistema deve permitir cadastrar funcionários. | FUNCIONARIO — identificado por ID e associado à SEPARACAO_PEDIDO e OCORRENCIA. |
| O sistema deve permitir cadastrar produtos com nome, preço, código e quantidade em estoque. | PRODUTO — identificado por ID/código e associado a ESTOQUE, ITEM_PEDIDO e TROCA_DEVOLUCAO. |
| O sistema deve permitir registrar marca e unidade de venda quando aplicável ao produto. | PRODUTO — atributos opcionais MARCA e UNIDADE_VENDA. |
| O sistema deve permitir registrar pedidos feitos na loja, pelo WhatsApp ou por outros canais de venda. | PEDIDO — possui o atributo CANAL_PEDIDO. |
| O sistema deve permitir registrar os produtos e quantidades de cada pedido. | ITEM_PEDIDO — associa PEDIDO e PRODUTO, registrando quantidade e preço unitário. |
| O sistema deve permitir registrar a forma de pagamento e o valor da compra. | PAGAMENTO — associado a PEDIDO, registra forma e valor. |
| O sistema deve permitir registrar o status de aprovação do pagamento. | PAGAMENTO — atributo STATUS_PAGAMENTO. |
| O sistema deve liberar o pedido para separação somente após o pagamento ser confirmado. | PEDIDO — atributo STATUS_PEDIDO, atualizado conforme confirmação do PAGAMENTO. |
| O sistema deve permitir registrar dados do cliente e endereço quando o pedido for para entrega. | PEDIDO — atributos condicionais TIPO_ENTREGA e ENDERECO_ENTREGA, associados a CLIENTE. |
| O sistema deve permitir consultar a quantidade disponível de cada produto no estoque. | ESTOQUE — associado a PRODUTO, registra quantidade disponível. |
| O sistema deve permitir registrar a separação e conferência dos produtos de um pedido antes do envio. | SEPARACAO_PEDIDO — associada a PEDIDO e FUNCIONARIO. |
| O sistema deve permitir registrar ocorrências como produto errado, falta de estoque ou problema na entrega. | OCORRENCIA — associada a PEDIDO, com tipo e solução aplicada. |
| O sistema deve permitir registrar solicitações de troca, devolução ou reembolso de um produto. | TROCA_DEVOLUCAO — associada a PEDIDO e PRODUTO, com motivo e status. |
| O sistema deve permitir consultar pedidos, pagamentos e status de entrega. | PEDIDO + PAGAMENTO — associados para consulta e consolidação de vendas. |

## 3.2 Requisitos Não Funcionais

| Requisito |
|---|
| **Usabilidade:** as informações devem ser apresentadas de forma clara e organizada. |
| **Integridade:** os relacionamentos entre pedidos, produtos, pagamentos, estoque e ocorrências devem permanecer consistentes. |
| **Segurança:** dados de clientes (endereço, contato) e informações financeiras devem possuir controle de acesso adequado. |
| **Desempenho:** consultas de disponibilidade de estoque e status de pedido devem apresentar resposta rápida, já que impactam diretamente a venda. |
| **Disponibilidade:** as informações de estoque devem estar atualizadas para refletir corretamente a disponibilidade nos canais de venda. |
| **Escalabilidade:** o modelo deve permitir o crescimento da quantidade de produtos, pedidos, canais de venda e funcionários. |
| **Rastreabilidade:** o sistema deve manter o histórico de ocorrências e trocas/devoluções associadas a cada pedido. |

---

# 4. Regras de Negócio

## 4.1 Regras Operacionais

| Regras |
|---|
| Todo produto deve possuir nome, preço, código e quantidade em estoque cadastrados. |
| Marca e unidade de venda são atributos opcionais do produto, aplicados conforme o tipo de item. |
| Todo pedido deve possuir um identificador único e pelo menos um item. |
| A quantidade de um item de pedido deve ser maior que zero. |
| Cada item de pedido deve estar associado a um produto cadastrado. |
| O preço unitário registrado no item deve representar o valor praticado no momento da venda. |
| Todo pedido deve identificar o canal de origem: LOJA, WHATSAPP ou CANAL_VENDA. |
| Quando o pedido for para entrega, os dados do cliente e o endereço são obrigatórios. |
| A disponibilidade do produto deve ser verificada no estoque no momento do pedido. |
| A quantidade disponível no estoque não pode ser negativa. |
| O pedido só é liberado para separação após a confirmação do pagamento. |
| Pagamentos recusados não liberam o pedido para separação. |
| Todo item separado deve ser conferido quanto à quantidade e à correspondência com o produto pedido antes do embalo. |
| Toda ocorrência (produto errado, falta de estoque, problema na entrega) deve ser registrada com tipo, descrição e solução aplicada. |
| Toda solicitação de troca ou devolução deve registrar o motivo e a condição do produto. |
| A solução de uma troca/devolução (substituição, devolução, reembolso) deve seguir o procedimento definido pela empresa. |

## 4.2 Restrições Organizacionais

| Restrição | Impacto no modelo |
|---|---|
| O estoque é controlado por produto, com verificação manual quando necessário. | Cada produto possui um registro de estoque (ESTOQUE), e a conferência física é tratada como parte da SEPARACAO_PEDIDO. |
| Pedidos podem chegar por canais diferentes (loja, WhatsApp, canais de venda). | O modelo usa o atributo CANAL_PEDIDO em vez de uma entidade para cada canal. |
| Nem todo pedido tem entrega — pode ser retirado/comprado na loja. | Os atributos de entrega em PEDIDO são condicionais ao TIPO_ENTREGA. |
| Problemas no pedido são resolvidos caso a caso pela equipe. | Foi criada a entidade OCORRENCIA para registrar tipo, descrição e solução. |
| Trocas e devoluções seguem um procedimento próprio da empresa. | Foi criada a entidade TROCA_DEVOLUCAO, separada de OCORRENCIA, pois trata especificamente da pós-venda de um produto já entregue/comprado. |

---

# 5. Dicionário de Dados Conceitual

## 5.1 Entidade: CLIENTE

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_cliente | Identificador único do cliente | Obrigatório e único (PK) |
| nome | Nome do cliente | Obrigatório quando há entrega |
| telefone | Telefone/WhatsApp de contato | Obrigatório quando há entrega |
| endereco | Endereço para entrega | Condicional (obrigatório quando TIPO_ENTREGA = ENTREGA) |
| cpf_cnpj | CPF ou CNPJ informado pelo cliente | Opcional; quando informado, deve ser único |

## 5.2 Entidade: FUNCIONARIO

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_funcionario | Identificador único do funcionário | Obrigatório e único (PK) |
| nome | Nome do funcionário | Obrigatório |
| cargo | Função exercida pelo funcionário | Obrigatório |

## 5.3 Entidade: PRODUTO

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_produto | Identificador único do produto | Obrigatório e único (PK) |
| nome | Nome do produto | Obrigatório |
| codigo | Código do produto (SKU/código de barras) | Obrigatório e único |
| preco | Preço atual de venda | Obrigatório; maior que zero |
| marca | Marca do produto (ex.: Tigre, Deca, Docol) | Opcional; depende do tipo de produto |
| unidade_venda | Unidade utilizada na venda (unidade, m², metro, saco, kg, etc.) | Opcional; depende do tipo de produto |

## 5.4 Entidade: ESTOQUE

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_estoque | Identificador único do estoque | Obrigatório e único (PK) |
| id_produto | Produto controlado pelo estoque | Obrigatório e único (FK) |
| quantidade_disponivel | Quantidade atual disponível | Obrigatório; maior ou igual a zero |
| data_atualizacao | Data da última atualização | Obrigatório |

## 5.5 Entidade: PEDIDO

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_pedido | Identificador único do pedido | Obrigatório e único (PK) |
| id_cliente | Cliente relacionado ao pedido | Condicional (FK); obrigatório quando há entrega |
| data_hora | Data e horário do registro | Obrigatório |
| canal_pedido | Canal utilizado para realizar o pedido | Obrigatório: LOJA, WHATSAPP ou CANAL_VENDA |
| tipo_entrega | Indica se o pedido é retirado na loja ou entregue | Obrigatório: RETIRADA ou ENTREGA |
| endereco_entrega | Endereço para entrega do pedido | Condicional; obrigatório quando tipo_entrega = ENTREGA |
| valor_total | Valor total do pedido | Obrigatório; calculado a partir dos itens |
| status_pedido | Situação do pedido no fluxo (registrado, pago, em separação, conferido, enviado/entregue, com ocorrência, cancelado) | Obrigatório |

## 5.6 Entidade: ITEM_PEDIDO

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_item | Identificador único do item | Obrigatório e único (PK) |
| id_pedido | Pedido ao qual o item pertence | Obrigatório (FK) |
| id_produto | Produto associado ao item | Obrigatório (FK) |
| quantidade | Quantidade do produto vendida | Obrigatório; maior que zero |
| preco_unitario | Preço do produto no momento da venda | Obrigatório; preserva o histórico |

## 5.7 Entidade: PAGAMENTO

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_pagamento | Identificador único do pagamento | Obrigatório e único (PK) |
| id_pedido | Pedido relacionado ao pagamento | Obrigatório (FK) |
| forma_pagamento | Forma utilizada no pagamento | Obrigatório: PIX, Crédito, Débito ou Dinheiro |
| valor_pagamento | Valor correspondente ao pagamento | Obrigatório; maior que zero |
| status_pagamento | Situação do pagamento | Obrigatório: Aprovado, Recusado ou Pendente |
| data_hora_pagamento | Data e horário do pagamento | Obrigatório |

## 5.8 Entidade: SEPARACAO_PEDIDO

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_separacao | Identificador único da separação | Obrigatório e único (PK) |
| id_pedido | Pedido relacionado à separação | Obrigatório (FK) |
| id_funcionario | Funcionário responsável pela separação/conferência | Obrigatório (FK) |
| data_hora_separacao | Data e horário da separação | Obrigatório |
| status_conferencia | Resultado da conferência | Obrigatório: Conferido ou Divergente |
| observacao | Observações sobre a conferência | Opcional |

## 5.9 Entidade: OCORRENCIA

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_ocorrencia | Identificador único da ocorrência | Obrigatório e único (PK) |
| id_pedido | Pedido relacionado à ocorrência | Obrigatório (FK) |
| tipo_ocorrencia | Tipo do problema identificado | Obrigatório: Produto Errado, Falta de Estoque, Problema na Entrega ou Outro |
| descricao | Descrição do problema relatado | Obrigatório |
| solucao_aplicada | Solução dada ao problema | Obrigatório: Substituição, Correção do Pedido, Nova Entrega ou Outro |
| status_ocorrencia | Situação da ocorrência | Obrigatório: Aberta ou Resolvida |
| data_hora | Data e horário do registro da ocorrência | Obrigatório |

## 5.10 Entidade: TROCA_DEVOLUCAO

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_troca | Identificador único da solicitação | Obrigatório e único (PK) |
| id_pedido | Pedido relacionado à solicitação | Obrigatório (FK) |
| id_produto | Produto envolvido na troca/devolução | Obrigatório (FK) |
| motivo | Motivo informado pelo cliente | Obrigatório |
| condicao_produto | Condição do produto no momento da análise | Obrigatório |
| tipo_solicitacao | Tipo de solicitação | Obrigatório: Troca, Devolução ou Reembolso |
| status_solicitacao | Situação da solicitação | Obrigatório: Em Análise, Aprovada, Concluída ou Recusada |
| data_hora | Data e horário da solicitação | Obrigatório |

---

# 6. Modelagem Conceitual

## 6.1 Entidades reconhecidas

| Entidade | Justificativa |
|---|---|
| CLIENTE | Representa o cliente relacionado ao pedido, especialmente quando há entrega. |
| FUNCIONARIO | Representa os funcionários responsáveis pela separação, conferência e tratamento de ocorrências. |
| PRODUTO | Representa os itens comercializados, com nome, preço, código e, quando aplicável, marca e unidade de venda. |
| ESTOQUE | Controla a quantidade disponível de cada produto. |
| PEDIDO | Representa a realização de uma compra, feita na loja, pelo WhatsApp ou por outro canal de venda. |
| ITEM_PEDIDO | Representa cada produto e quantidade pertencentes a um pedido. |
| PAGAMENTO | Registra os pagamentos associados aos pedidos e seu status de aprovação. |
| SEPARACAO_PEDIDO | Representa a conferência dos produtos antes do embalo/envio. |
| OCORRENCIA | Representa problemas identificados no pedido (produto errado, falta de estoque, problema na entrega) e a solução aplicada. |
| TROCA_DEVOLUCAO | Representa solicitações de troca, devolução ou reembolso de um produto já vendido. |

## 6.2 Atributos e classificações

Os atributos foram definidos a partir dos processos levantados na entrevista e estão detalhados no Dicionário de Dados da Seção 5.

Foram classificados principalmente como:

- **PK:** identificadores únicos das entidades;
- **FK:** atributos utilizados para relacionar entidades;
- **Obrigatórios:** informações necessárias para o registro;
- **Opcionais:** informações que podem não ser fornecidas (ex.: marca, unidade de venda, CPF/CNPJ);
- **Condicionais:** atributos utilizados conforme o tipo de pedido (ex.: dados de entrega);
- **Calculados:** informações derivadas de outros registros (ex.: valor_total do pedido).

## 6.3 Relacionamentos pertinentes

| Relacionamento | Descrição | Cardinalidade |
|---|---|---|
| CLIENTE — PEDIDO | Um cliente pode realizar vários pedidos. | 1:N |
| PEDIDO — ITEM_PEDIDO | Um pedido possui um ou mais itens. | 1:N |
| PRODUTO — ITEM_PED