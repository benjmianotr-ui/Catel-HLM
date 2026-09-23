# Catel HLM — Modelo Conceitual de Banco de Dados

> **Base deste documento:** esta é uma cópia adaptada do modelo conceitual do projeto *Nós Café* (entidades, seções e formato preservados), reestruturada a partir de um novo levantamento de requisitos (entrevista) feito com a operação da **Catel HLM**, loja de materiais de construção (hidráulica, louças e metais) localizada na Vila Ré, São Paulo/SP. Dados de endereço, segmento e CNAE foram confirmados via Google Maps e portal AECweb; o CNPJ baixo corresponde a uma empresa de mesmo nome, minha atividade e minha cidade, mas não foi possível confirmar o endereço exato na base pública gratuita consultada — vale conferir antes de usar oficialmente.

# Integrantes

| Nome | RGM |
|----|----|
| Benjamim Osmar | 47352663 |
| Carlos Daniel | 42869234 |
| Guilherme Enzo | 47356481 |
| Erick jaldin | 47364891 |

## Entrega 1 — Modelo Conceitual (DER)

**Organização analisada:** Catel HLM
**Unidade:** R. Itinguçu, 2190 - Vila Ré, São Paulo - SP, 03658-001
**Segmento:** Comércio varejista de materiais de construção — hidráulica, louças, metais, acabamentos, materiais básicos, portas e janelas, peixes, azulejos, pias e gabinetes, com venda em loja física, WhatsApp e canais de venda online

> Este README apresenta o levantamento de requisitos, processos de negação, registros, dicionário de dados, modelo conceitual, DER e justificativas técnicas do projeto.

---

# 1. Caracterização da Organização

## Nome e natureza da organização

Uma organização analisada é a **Catel HLM** (nome fantasia — HLM referindo-se a Hidráulica, Louças e Metais), atuante há mais de 40 anos no mercado de materiais de construção: hidráulica, louças, metais, acabamentos, materiais básicos, portas e janelas, pinos, azulejos, pias e gabinetes, com fabricação própria de calças e rufos. A loja comercializa produtos por meio de atendimento presencial e também por canais remotos, como WhatsApp e outros canais de venda.
**Razão social (provável):** Catel - Hidráulicos, Louças e Metais Ltda
**CNPJ (provável):** 06.969.238/0001-06 — mesmo nome, atividade (CNAE 4744-0/99 — Comércio varejista de materiais de construção em geral) e cidade, mas fim exato não confirmado na base pública gratuita
**Telefone:** (11) 2023-9922
**Site/Redes sociais:** [não localizado em busca pública]
**Unidade analisada:** R. Itinguçu, 2190 - Vila Ré, São Paulo - SP, 03658-001

> A loja possivelmente avaliação 4,3★ no Google (mais de 1.100 avaliações), com elogios à variedade de materiais, prêmios competitivos e entrega dentro do prazer.

## Contexto e porte

Uma unidade de trabalho com diferentes formas de atendimento:

- **Loja física:** o cliente compra diretamente no saldo/loja.
- **WhatsApp:** o cliente faz o pedido por mensagem, informando produtos e quantidades.
- **Canais de venda:** pedidos recebidos por outros canais de venda da empresa.

Após o registro do pedido, os produtos são separados no estoque, conferidos e, quando necessário, embalados para entrega.

## Problemas e necessidades identificadas

Durante o levantamento, fui identificado que o controle de estoque depende do acompanhamento manual das entradas e saídas, e que, ao receber um pedido, a equipe precisa verificar a quantidade disponível no sistema e, em alguns casos, conferindo fisicamente no estoque.

Também foi observado que problemas como produto errado, falta de estoque ou falta na entrada são tratados caso a caso, por meio de contato direto com o cliente, sem um registro estruturado do motivo e da solução aplicada.

Dessa forma, o projeto busca estruturar os dados de produtos, pedidos, pagamentos, estoque, separação/conferência, ocorrências e trocas/devoluções para facilitar o controle da operação e futuras análises gerenciais.

## Justificativa da escola

A loja foi escolar por apresentar um cenário real de operação comercial com múltiplos canais de venda (presencial, WhatsApp e canais de venda), controle de estoque, conferência de pedidos antes do ambiente e tratamento de problemas pós-venda (trocas e devoluções), o que oferece um bom conjunto de processos para modelagem de um banco de dados.

## Evidências da organização

Foram obtidas evidências da existência e do acesso à organização, incluindo:

- endereço confirmado: R. Itinguçu, 2190 - Vila Ré, São Paulo - SP, 03658-001 (Google Maps);
- telefone de contato: (11) 2023-9922;
- perfil como fornecedor de materiais de construção no portal AECweb (hidráulica, louças, metais, acabamentos, portas e janelas, pinos, azulejos, pias e gabinetes, calhas e rufos de fabricação própria);
- avaliações de clientes no Google (4,3★, +1.100 avaliações) citando variedade de materiais, preços competitivos e entrega dentro do prazer;
- entrevista com a operação da loja sobre cadastro de produtos, pedidos, estoque, pagamento, separação e trocas/devoluções.

---

# 2. Processos de Negócio

## Principais processos mapeados

Com base na entrevista, foram identificados os seguintes processos:

- **Cadastro de produtos:** registro de nome, preto, código e quantidade em estoque, além de marca e unidade de venda quando aplicável.
- **Realização do pedido:** o cliente compra diretamente na loja ou faz o pedido pelo WhatsApp/canais de venda.
- **Registro do pedido:** registro dos produtos escolares, quantidades, valor da compra, forma de pagamento e, quando há entrega, dados do cliente e endereço.
- **Controle de estoque:** acompanhamento das entradas e saídas e verificação da disponibilidade do produto no momento do pedido, com conferência física quando necessário.
- **Confirmação de pagamento:** verificação da aprovação do pagamento; após confirmado, o pedido é liberado para separação e preparo.
- **Separação e conferência:** o funcionamento retira os produtos do estoque, confere a quantidade e se são os produtos corretos, e embala os itens para entrega.
- **Tratamento de problemas:** contato com o cliente em casos de produto errado, falta de estoque ou problema na entrega, com substituição do produto, correção do pedido ou nova entrega, conforme o caso.
- **Troca ou devolução:** verificação do motivo e da condição do produto, seguindo o procedimento da empresa para troca, devolução ou reembolso.

## Fluxograma

> Insira aqui o fluxograma do processo (pedido → pagamento → separação/conferência → entrega → pós-venda), no mesmo formato usado no projeto original (`imagem-1.png`).

### Legenda

| Elemento | Significado |
|---|---|
| 🟢 | Início / Fim |
 A loja possivelmente avaliação 4,3★ no Google (mais de 1.100 avaliações), com elogios à variedade de materiais, prêmios competitivos e entrega dentro do prazer. ▭ | Processo / Atividade |
| ♦️ | Decisão |
| Setas | Fluxo de execução |

---

# 3. Requisitos do Sistema

## 3.1 Requisitos Funcionais

| Requisito | Entidade e associação |
|---|---|
| O sistema deve permitir clientes cadastrados. | CLIENTE — identificado por CPF/CNPJ (opcional) e associado a PEDIDO. |
| O sistema deve permitir funções cadastrais. | FUNCIONARIO — identificado por ID e associado à SEPARACAO_PEDIDO e OCORRENCIA. |
| O sistema deve permitir cadastrar produtos com nome, preto, código e quantidade em estoque. | PRODUTO — identificado por ID/código e associado a ESTOQUE, ITEM_PEDIDO e TROCA_DEVOLUCAO. |
| O sistema deve permitir registrar marca e unidade de venda quando aplicável ao produto. | PRODUTO — atributos opcionais MARCA e UNIDADE_VENDA. |
| O sistema deve permitir registrar pedidos feitos na loja, pelo WhatsApp ou por outros canais de venda. | PEDIDO — possui o atributo CANAL_PEDIDO. |
| O sistema deve permitir registrar os produtos e quantidades de cada pedido. | ITEM_PEDIDO — associação PEDIDO e PRODUTO, registro quantidade e preço unitário. |
| O sistema deve permitir registrar a forma de pagamento e o valor da compra. | PAGAMENTO — associado a PEDIDO, registra forma e valor. |
| O sistema deve permitir registrar o status de aprovação do pagamento. | PAGAMENTO — atributo STATUS_PAGAMENTO. |
| O sistema deve liberar o pedido para separação somente após o pagamento ser confirmado. | PEDIDO — atributo STATUS_PEDIDO, atualizado conforme confirmação do PAGAMENTO. |
| O sistema deve permitir registrar dados do cliente e fazer quando o pedido para entrega. | PEDIDO — atributos condicionais TIPO_ENTREGA e ENDERECO_ENTREGA, associação um CLIENTE. |
| O sistema deve permitir consultar a quantidade disponível de cada produto no estoque. | ESTOQUE — associado a PRODUTO, registro quantidade disponível. |
| O sistema deve permitir registrar a separação e conferência dos produtos de um pedido antes do meio ambiente. | SEPARACAO_PEDIDO — associado a PEDIDO e FUNCIONARIO. |
| O sistema deve permitir registrar ocorrências como produto errado, falta de estoque ou problema na entrega. | OCORRENCIA — associada a PEDIDO, com tipo e solução aplicada. |
| O sistema deve permitir registrar solicitações de troca, devolução ou reembolso de um produto. | TROCA_DEVOLUCAO — associado a PEDIDO e PRODUTO, com motivo e status. |
A loja foi escolar por apresentar um cenário real de operação comercial com múltiplos canais de venda (presencial, WhatsApp e canais de venda), controle de estoque, conferência de pedidos antes do ambiente e tratamento de problemas pós-venda (trocas e devoluções), o que oferece um bom conjunto de processos para modelagem de um banco de dados. O sistema deve permitir consultar pedidos, pagamentos e status de entrega. | PEDIDO + PAGAMENTO — associados para consulta e consolidação de vendas. |

## 3.2 Requisitos Não Funcionais

| Requisito |
|---|
| **Usabilidade:** as informações devem ser apresentadas de forma clara e organizada. |
| **Integridade:** os relacionamentos entre pedidos, produtos, pagamentos, estoque e ocupações devem permanecer consistentes. |
| **Segurança:** dados de clientes (endereço, contato) e informações financeiras devem possuir controle de acesso adequado. |
| **Desempenho:** consultas de disponibilidade de estoque e status de pedido devem apresentar resposta rápida, já que impactam diretamente a venda. |
| **Disponibilidade:** como informações de estoque devem ser atualizadas para refletir corretamente a disponibilidade nos canais de venda. |
| **Escalabilidade:** o modelo deve permitir o crescimento da quantidade de produtos, pedidos, canais de venda e funções. |
| **Rastreabilidade:** o sistema deve manter o histórico de ocorrências e trocas/devoluções associadas a cada pedido. |

---

# 4. Regras de Negócio

## 4.1 Regras Operacionais

| Regras |
|---|
| Todo produto deve possuir nome, preto, código e quantidade em estoque cadastrados. |
| Marca e unidade de venda são atributos opcionais do produto, aplicados conforme o tipo de item. |
| Todo pedido deve possuir um identificador único e pelo menos um item. |
| A quantidade de um item de pedido deve ser maior que zero. |
| Cada item de pedido deve estar associado a um produto cadastrado. |
| O preço unitário registrado no item deve representar o valor praticado no momento da venda. |
| Todo pedido deve identificar o canal de origem: LOJA, WHATSAPP ou CANAL_VENDA. |
| Quando o pedido para entrega, os dados do cliente e o esforço são obrigatórios. |
| A disponibilidade do produto deve ser verificada no estoque no momento do pedido. |
| A quantidade disponível no estoque não pode ser negativa. |
| O pedido só é liberado para separação após a confirmação do pagamento. |
| Pagamentos recusados não foram o pedido para separação. |
| Todo item separado deve ser conferido quanto à quantidade e à correspondência com o produto pedido antes do barco. |
| Toda ocorrência (produto errado, falta de estoque, problema na entrega) deve ser registrada com tipo, descrição e solução aplicada. |
| Toda solicitação de troca ou devolução deve registrar o motivo e a condição do produto. |
| A solução de uma troca/desenvolvimento (substituição, devolução, reembolso) deve seguir o procedimento definido pela empresa. |

## 4.2 Restrições Organizacionais

| Restrição | Impacto no modelo |
|---|---|
| O estoque é controlado por produto, com verificação manual quando necessário. | Cada produto possui um registro de estoque (ESTOQUE), e a conferência física é tratada como parte da SEPARACAO_PEDIDO. |
| Pedidos podem chegar por canais diferentes (loja, WhatsApp, canais de venda). | O modelo usa o atributo CANAL_PEDIDO em vez de uma entidade para cada canal. |
| Nem todo pedido tem entrega — pode ser retirado/comprado na loja. | Os atributos de entrega em PEDIDO são condicionais ao TIPO_ENTREGA. |
| Problemas não pedido são resolvidos caso a caso pela equipe. | Foi criada a entidade OCORRENCIA para registrar tipo, descrição e solução. |
| Trocas e devoluções seguem um procedimento próprio da empresa. | Foi criada a entidade TROCA_DEVOLUCAO, separada de OCORRENCIA, pois trata especificamente da pós-venda de um produto já entregue/comprado. |

---

# PRODUTO — identificado por ID/código e associado a ESTOQUE, ITEM_PEDIDO e TROCA_DEVOLUCAO. 

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
| id_funcionário | Identificador único do funcionamento | Obrigatório e único (PK) |
| nome | Nome do funcionário | Obrigatório |
| carga | Função exercida pelo funcional | Obrigatório |

## 5.3 Entidade: PRODUTO

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_produto | Identificador único do produto | Obrigatório e único (PK) |
| nome | Nome do produto | Obrigatório |
| código | Código do produto (SKU/código de barras) | Obrigatório e único |
| preco | Preço atual de venda | Obrigatório; maior que zero |
| marca | Marca do produto (ex.: Tigre, Deca, Docol) | Opcional; depende do tipo de produto |
| unidade_venda | Unidade utilizada na venda (unidade, m², metro, saco, kg, etc) | Opcional; depende do tipo de produto |

## 5.4 Entidade: ESTOQUE

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_estoque | Identificador único do estoque | Obrigatório e único (PK) |
| id_produto | Produto controlado pelo estoque | Obrigatório e único (FK) |
| quantidade_disponivel | Quantidade disponível | Obrigatório; maior ou igual a zero |
| dados_atualizacao | Dados da última atualização | Obrigatório |

## 5.5 Entidade: PEDIDO

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_pedido | Identificador único do pedido | Obrigatório e único (PK) |
| id_cliente | Cliente relacionado ao pedido | Condicional (FK); obrigatório quando há entrega |
| data_hora | Dados e horário do registro | Obrigatório |
| canal_pedido | Canal utilizado para realizar o pedido | Obrigado: LOJA, WHATSAPP ou CANAL_VENDA |
| tipo_entrega | Indica se o pedido é retirado na loja ou entregue | Obrigatório: RETIRADA ou ENTREGA |
| endereco_entrega | Endereço para entrega do pedido | Condicional; obrigatório quando tipo_entrega = ENTREGA |
| valor_total | Valor total do pedido | Obrigatório; calculado a partir dos itens |
| status_pedido | Situação do pedido no fluxo (registrado, pago, em separação, conferido, ambiente/entregue, com corrência, cancelado) | Obrigatório |

## 5.6 Entidade: ITEM_PEDIDO

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_item | Identificador único do item | Obrigatório e único (PK) |
| id_pedido | Pedido ao qual o item pertença | Obrigatório (FK) |
| id_produto | Produto associado ao item | Obrigatório (FK) |
| quantidade | Quantidade do produto vendida | Obrigatório; maior que zero |
| preco_unitário | Preço do produto no momento da venda | Obrigatório; preservação do histórico |

## 5.7 Entidade: PAGAMENTO

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_pagamento | Identificador único do pagamento | Obrigatório e único (PK) |
| id_pedido | Pedido relacionado ao pagamento | Obrigatório (FK) |
| forma_pagamento | Forma utilizada no pagamento | Obrigatório: PIX, Crédito, Débito ou Dinheiro |
| valor_pagamento | Valor correspondente ao pagamento | Obrigatório; maior que zero |
| status_pagamento | Situação do pagamento | Obrigatório: Aprovado, Recusado ou Pendente |
| data_hora_pagamento | Dados e horário do pagamento | Obrigatório |

## 5.8 Entidade: SEPARACAO_PEDIDO

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_separacao | Identificador único da separação | Obrigatório e único (PK) |
| id_pedido | Pedido relacionado à separação | Obrigatório (FK) |
| id_funcionário | Funcionário responsável pela separação/conferência | Obrigatório (FK) |
| data_hora_separacao | Dados e horário da separação | Obrigatório |
| status_conferência | Resultado da conferência | Obrigatório: Conferido ou Divergente |
| observação | Observações sobre uma conferência | Opcional |

## 5.9 Entidade: OCORRENCIA

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_ocorrencia | Identificador único da odorrência | Obrigatório e único (PK) |
| id_pedido | Pedido relacionado à corrosão | Obrigatório (FK) |
| tipo_ocorrencia | Tipo do problema identificado | Obrigatório: Produto Errado, Falta de Estoque, Problema na Entrega ou Outro |
| descrição | Descrição do problema relacionado | Obrigatório |
| solução_aplicada | Resolução dada ao problema | Obrigatório: Substituição, Correção do Pedido, Nova Entrada ou Outro |
| status_ocorrencia | Situação da corrupção | Obrigatório: Aberta ou Resolvida |
| data_hora | Dados e horário do registro da ocupação | Obrigatório |

## 5.10 Entidade: TROCA_DEVOLUCAO

| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_troca | Identificador único da solicitação | Obrigatório e único (PK) |
| id_pedido | Pedido relacionado à solicitação | Obrigatório (FK) |
| id_produto | Produto envolvido na troca/devolução | Obrigatório (FK) |
| motivação | Motivo informado pelo cliente | Obrigatório |
| condicao_produto | Condição do produto no momento da análise | Obrigatório |
| tipo_solicitacao | Tipo de solicitação | Obrigatório: Troca, Devolução ou Reembolso |
| status_solicitacao | Situação da solicitação | Obrigatório: Em Análise, Aprovada, Concluída ou Recusada |
| data_hora | Dados e horário da solicitação | Obrigatório |

---

# 6. Modelagem Conceitual

## 6.1 Entidades reconhecidas

| Entidade | Justificativa |
|---|---|
| CLIENTE | Representa o cliente relacionado ao pedido, especialmente quando há entrega. |
| FUNCIONÁRIO | Representa como funções respostas pela separação, conferência e tratamento de ocorrências. |
| PRODUTO | Representa os itens comercializados, com nome, preto, código e, quando aplicável, marca e unidade de venda. |
| ESTOQUE | Controle uma quantidade disponível de cada produto. |
| PEDIDO | Representa a realização de uma compra, feita na loja, pelo WhatsApp ou por outro canal de venda. |
| ITEM_PEDIDO | Representa cada produto e quantidade percentual a um pedido. |
| PAGAMENTO | Registra os pagamentos associados aos pedidos e seu status de aprovação. |
| SEPARACAO_PEDIDO | Representa a conferência dos produtos antes do embalo/envio. |
| OCORRÊNCIA | Representa problemas identificados no pedido (produto errado, falta de estoque, problema na entrega) e a solução aplicada. |
| TROCA_DEVOLUCAO | Representa solicitações de troca, devolução ou reembolso de um produto já vendido. |

## 6.2 Atributos e classificações

Os atributos foram definidos a partir dos processos levantados na entrevista e estão detalhados no Dicionário de Dados da Seção 5.

Foram classificados principalmente como:

- **PK:** identificadores públicos das entidades;
- Obrigatório; maior que zero **FK:** atributos utilizados para entidades relacionais;
- **Obrigatórios:** informações necessárias para o registro;
- **Opcionais:** informações que podem não ser fornecidas (ex.: marca, unidade de venda, CPF/CNPJ);
- **Condições:** atributos utilizados conforme o tipo de pedido (ex.: dados de entrega);
- **Calculadas:** informações derivadas de outros registros (ex.: valor_total do pedido).

## 6.3 Relacionamentos pertinentes

| Relacionamento | Descrição | Cardinalidade |
|---|---|---|
| CLIENTE — PEDIDO | Um cliente pode realizar caminhos pedidos. | 1:N |
| PEDIDO — ITEM_PEDIDO | Um pedido possui um ou mais itens. | 1:N |
| PRODUTO — ITEM_PEDIDO | Um produto pode aparecer em vários itens de pedidos. | 1:N |
| PEDIDO — PAGAMENTO | Um pedido pode possuir um ou mais pagamentos. | 1:N |
| PRODUTO — ESTOQUE | Cada produto possui um único registro de estoque. | 1:1 |
| FUNCIONÁRIO — SEPARACAO_PEDIDO | Um funcional pode realizar vias separadas/conferências. | 1:N |
| PEDIDO — SEPARACAO_PEDIDO | Um pedido pode ter uma ou mais conferências (ex.: aplicação correta de um problema). | 1:N |
| PEDIDO — OCORRÊNCIA | Um pedido pode ter uma ou mais ocorrências registradas. | 1:N |
| PEDIDO — TROCA_DEVOLUCAO | Um pedido pode originar uma ou mais solicitações de troca/desvolução. | 1:N |
| PRODUTO — TROCA_DEVOLUCAO | Um produto pode estar envolvido em viagens solicitações de troca/desenvolvimento. | 1:N |

## 6.4 Restrições aplicadas ao modelo

- O canal do pedido deve ser LOJA, WHATSAPP ou CANAL_VENDA.
- Dados de cliente e atendimento são obrigatórios apenas quando o pedido para o tipo EMPRESA.
- Um pedido só é liberado para SEPARACAO_PEDIDO após o PAGAMENTO estar com status Aprovado.
- Obrigatório 
- Marca e unidade de venda em PRODUTO são opcionais, pois dependem do tipo do item.
- OCORRENCIA e TROCA_DEVOLUCAO foram mantidas como entidades separadas: a primeira trata de problemas no processo do pedido (antes/durante a entrega), e a segunda trata da pós-venda de um produto já recebido pelo cliente.

---

# 7. Diagrama Entidade-Relacionamento (DER)

## 7.1 DER — Catel HLM

```sereia
erDiagrama
    CLIENTE ||--o{ PEDIDO: realização
    PEDIDO ||--|{ ITEM_PEDIDO: possui
    PRODUTO ||--o{ ITEM_PEDIDO: compoe
    PEDIDO ||--o{ PAGAMENTO: possui
    PRODUTO ||--|| ESTOQUE: possui
    FUNCIONÁRIO ||--o{ SEPARACAO_PEDIDO: realização
    PEDIDO ||--o{ SEPARACAO_PEDIDO: passa_por
    PEDIDO ||--o{ OCORRENCIA: gera
    PEDIDO ||--o{ TROCA_DEVOLUCAO: origem
 Representa como funções respostas pela separação, conferência e tratamento de ocorrências. 

    CLIENTE {
        int id_cliente PK
        string nome
        telefone de corda
        string endereco
        string cpf_cnpj
    }
    FUNCIONALISMO 
        int id_funcionario PK
        string nome
        carga de corda
    }
    PRODUTO {
        int id_produto PK
        string nome
        string codigo
        decimal preco
        corda marca
        string unidade_venda
    }
    ESTOQUE {
        int id_estoque PK
        int id_produto FK
        int quantidade_disponivel
|---|---|---|
    }
    PEDIDO {
        int id_pedido PK
        int id_cliente FK
        dados de dados e hora_hora
        string canal_pedido
        string tipo_entrega
        string endereco_entrega
        valor decimal_total
        string status_pedido
    }
    ITEM_PEDIDO {
        int id_item PK
        int id_pedido FK
        int id_produto FK
        quantidade interna
        decimal preco_unitario
    }
    PAGAMENTO {
        int id_pagamento PK
        int id_pedido FK
        string forma_pagamento
        valor decimal_pagamento
        string status_pagamento
        dados de dados e hora_hora_pagamento
    }
    SEPARACAO_PEDIDO {{
        int id_separacao PK
        int id_pedido FK
        int id_funcionario FK
        dados de dados e hora_hora_separacao
        string status_conferência
        observação de cordas
    }
    OCORRÊNCIA {
        int id_ocorrencia PK
        int id_pedido FK
        string tipo_ocorrencia
        descrição da string
        string solucao_aplicada
        string status_ocorrencia
        dados de dados e hora_hora
    }
    TROCA_DEVOLUCAO 
        int id_troca PK
        int id_pedido FK
        int id_produto FK
        motivação de corda
        string condicao_produto
        string tipo_solicitacao
        string status_solicitacao
        dados de dados e hora_hora
    }
```

## 7.2 Principais relações

| Entidade A | Relacionamento | Entidade B | Cardinalidade |
|---|---|---|---|
| CLIENTE | realizar | PEDIDO | 1:N |
| PEDIDO | possui | ITEM_PEDIDO | 1:N |
| PRODUTO | compõe | ITEM_PEDIDO | 1:N |
| PEDIDO | possui | PAGAMENTO | 1:N |
| PRODUTO | possui | ESTOQUE | 1:1 |
| FUNCIONÁRIO | realizar | SEPARACAO_PEDIDO | 1:N |
| PEDIDO | passa por | SEPARACAO_PEDIDO | 1:N |
| PEDIDO | Gera | OCORRÊNCIA | 1:N |
| PEDIDO | origina | TROCA_DEVOLUCAO | 1:N |
| PRODUTO | envolver | TROCA_DEVOLUCAO | 1:N |

### Observação sobre PEDIDO e PRODUTO

Uma relação conceitual entre **PEDIDO** e **PRODUTO** é de muitos-para-muitos, pois um pedido pode conter caminhos produtos e um produto pode aparecer em caminhos pedidos.

No DER, essa relação é representada por meio da entidade associada **ITEM_PEDIDO**:

**PEDIDO 1:N ITEM_PEDIDO N:1 PRODUTO**

### Observação sobre separação/conferência

Uma relação **PEDIDO — SEPARACAO_PEDIDO** foi definitivamente como **1:N** para permitir registrar uma nova conferência caso o pedido voltou para separação após a correção de um problema (ex.: produto errado identificado).

---

# 8. Técnica Justificativa

## 8.1 Decisões de abstração e modelagem

| Decisão | Justificativa |
|---|---|
| Escola das entidades | Foram selecionadas entidades diretamente relacionadas aos processos observados: cadastro de produto, pedido, pagamento, estoque, separação/conferência, ocorrências e pós-venda. |
| PEDIDO como entidade central | O pedido conecta o processo de venda ao cliente, aos canais, aos itens, aos pagamentos e ao fluxo de separação/entrega. |
| ITEM_PEDIDO como entidade associativa | Resolva uma relação N:M entre pedestres e produtos e permita registrar quantidade e preço histórico. |
| `canal_pedido` | Permitir diferenciar LOJA, WHATSAPP e CANAL_VENDA sem criar uma entidade artificial para cada canal. |
| `tipo_entrega` e `endereco_entrega` condicionais em PEDIDO | Refletem que nem todo pedido tem entrega — dados de entrega só são obrigatórios quando aplicável. |
| ESTOQUE separado de PRODUTO | Evita duplicar a informação de quantidade disponível dentro do cadastro do produto. |
| SEPARACAO_PEDIDO como entidade própria | Representa a etapa de conferência de quantidade/produto antes do embalo, citada explicitamente no levantamento. |
| OCORRENCIA separada de TROCA_DEVOLUCAO | OCORRENCIA trata de problemas no processo do pedido (produto errado, falta de estoque, problema de entrega); TROCA_DEVOLUCAO trata da pós-venda de um produto já recebido pelo cliente. Separar como duas evita confundir nossos momentos diferentes do processo. |

## 8.2 Por que não há alternativas?

| Alternativa | Motivo da rejeição |
|---|---|
| Manter uma quantidade em estoque apenas em PRODUTO | Criaria duas fontes possíveis para a mesma informação de quantidade e poder gerar inconsistência entre cadastro e estoque. |
| Relacionar PEDIDO diretamente com PRODUTO sem ITEM_PEDIDO | Não permitir representar corretamente quantidade e preço histórico de cada produto vendido. |
| Unificar OCORRENCIA e TROCA_DEVOLUCAO em uma unidade pública | Misturaria problemas do processo de venda/entrega com solicitações de pós-venda, que são fluxos e respostas diferentes. |
| Tornar CLIENTE obrigatório em todo pedido | Nem toda venda na loja exigência identificação do cliente; tornar obrigatório difícil o registro de vendas de saldo simples. |
| Criar uma entidade separada para cada canal de venda (LOJA, WHATSAPP, etc) | O levantamento identificou o canal como uma característica do pé, não como uma entidade de negação própria. |

## 8.3 Justificativa do DER

O DER foi elaborado para representar os principais processos da loja de forma integrada: cadastro de produtos, realização e registro do pedido, controle de estoque, confirmação de pagamento, separação/conferência, tratamento de ocorrências e trocas/devoluções.

A entidade PEDIDO funciona como núcleo do processo de vendas, conectando cliente, canal, itens, pagamento e o fluxo pós-pagamento (separação, odorrência e, se necessário, troca/devolução).

O modelo de estoque foi separado do cadastro de produtos para evitar redundância e permitir o controle da quantidade atual, verificado tanto pelo sistema quanto fisicamente quando necessário.

A modelagem também foi preparada para crescer futuro, permitindo novos produtos, canais de venda, funções e tipos de operação sem alterar a estrutura principal.

---

# 9. Uso de Inteligência Artificial

A Inteligência Artificial foi utilizada como ferragem de apoio durante a adaptação deste modelo.

| Item | Registro |
|---|---|
| **Ferramenta e etapa** | Claude (Antrópico), utilizada para analisar e organizar o README (entidades, dicionário de dados, DER e justificativas) com base em um novo levantamento de requisitos (respostas de entrevista sobre cadastro de produtos, pedidos, estoque, pagamento, separação, ocorrências e trocas/devoluções). |
| **Motivação** | Auxiliar na organização das informações levantadas e revisar a consistência entre processos, requisitos, registros, entidades e relacionamentos. |
| **Solicita utilizações** | "Utilizando como informações reunidas durante o levantamento de requisitos da Catel HLM, ponte que entidades precisas constar no modelo conceitual."; "Faça uma análise cruzada entre esses dois documentos para verificar se corresponde ao que foi pedido. O segundo material é de um colega meu, não use-o como parâmetro: aponte os acertos dele e os pontos em que o nosso trabalho pode estar equivocado. Para montar esse prompt, reuni o modelo-base do professor, o README.md da nossa equipe e o README.md do faculdade, trabalho um comparativo que nos ajuda a preparar o projeto."; "Revise o modelo considerando que um pedido pode ser dividido em dois pagamentos"; "Analise o controle de estoque e fornecedor e indique como representar isso no modelo conceitual"; "Faça uma revisão detalhada do README, certificando-se de que requisitos, regras de negócio, dicionário de dados e DER estejam todos alinhados e sem contradições entre si" |
| **Resposta recebida** | A IA forneceu sugestões de estrutura de entidades (CLIENTE, FUNCIONARIO, PRODUTO, ESTOQUE, PEDIDO, ITEM_PEDIDO, PAGAMENTO, SEPARACAO_PEDIDO, OCORRENCIA, TROCA_DEVOLUCAO), com dicionário de dados, DER e justificativas técnicas equivalentes as comparações. |
| **Trechos rejeitados ou corrigidos** | **Nem todas as recomendações da IA foram incorporadas à versão final do modelo. O caso mais evidente diz respeito à cardinalidade entre PEDIDO e PAGAMENTO: inicialmente, a IA propôs uma relação 1:1, mas isso não condizia com a realidade observada na loja, onde dividir a conta é uma prática comum e frequente. Por esse motivo, justamos a cardinalidade para 1:N. Também revisamos a ideia inicial de registrar a quantidade em estoque simultaneamente nas entidades PRODUTO e ESTOQUE; ao perceber que isso geraria vermelhoundância de dados, optamos por manter essa informação apenas em ESTOQUE..** |
| **Justificativa da escola final** | **As decisões finais foram tomadas pelo grupo com base nas informações obtidas na organização e na necessidade de manter a coerência entre o modelo e os processos observados**. |
| **Reflexão crítica** | **De forma geral, a IA ajudou muito a botar as ideias no lugar e pegou umas inconsistências que a gente nem tinha percebido, toda decisão final passou pelo filho do grupo, sempre em cima do que a gente realmente viu e coletou na visita e na entrevista. A IA até deu palpite, mas quem bate o martelo somos nós mesmos.** |

---

# Conclusão

O modelo conceitual desenvolvido representa os principais processos identificados na entrevista: cadastro de produtos, realização do pedido (loja, WhatsApp e canais de venda), registro do pedido, controle de estoque, confirmação de pagamento, separação e conferência dos produtos, tratamento de ocorrências e troca/desenvolvimento.

A modelagem foi estruturada para manter consistência entre os processos levantados, os requisitos, como registros de negação, o dicionário de dados e o DER.
