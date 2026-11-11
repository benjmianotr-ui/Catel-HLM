-- =====================================================================
-- CATEL HLM — Script SQL completo (MySQL 8)
-- Entrega 2 — Modelo lógico, implementação SQL e apresentação final
--
-- Ordem do script:
--   1. CREATE DATABASE        2. CREATE TABLE + constraints
--   3. INSERT INTO (massa de dados fictícia)
--   4. SELECT com JOIN        5. UPDATE        6. DELETE
--   7. Consultas gerenciais (G01...)   8. Consultas de auditoria (A01...)
--
-- Códigos citados nos comentários:
--   P  = problema declarado       RN = regra de negócio       K = indicador (KPI)
-- Todos os dados inseridos são FICTÍCIOS; nenhum dado real de clientes,
-- funcionários ou fornecedores da organização foi utilizado.
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
DROP DATABASE IF EXISTS catel_hlm;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. CREATE DATABASE ---------------------------------------------------
CREATE DATABASE catel_hlm CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE catel_hlm;

-- 2. CREATE TABLE + CONSTRAINTS ----------------------------------------

CREATE TABLE CLIENTE (
  id_cliente     INT          NOT NULL AUTO_INCREMENT,
  nome           VARCHAR(255) NOT NULL,
  telefone       VARCHAR(11)  NOT NULL,
  cpf_cnpj       VARCHAR(14)  NULL,
  logradouro     VARCHAR(150) NULL,
  numero         VARCHAR(10)  NULL,
  bairro         VARCHAR(80)  NULL,
  cep            CHAR(8)      NULL,
  data_cadastro  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
  CONSTRAINT uq_cliente_cpf_cnpj UNIQUE (cpf_cnpj),                          -- RN13
  CONSTRAINT ck_cliente_cpf_cnpj CHECK (cpf_cnpj IS NULL OR cpf_cnpj REGEXP '^[0-9]{11}([0-9]{3})?$'), -- RN13
  CONSTRAINT ck_cliente_telefone CHECK (telefone REGEXP '^[0-9]{10,11}$'),
  CONSTRAINT ck_cliente_cep CHECK (cep IS NULL OR cep REGEXP '^[0-9]{8}$')
) ENGINE=InnoDB;

CREATE TABLE FUNCIONARIO (
  id_funcionario INT          NOT NULL AUTO_INCREMENT,
  nome           VARCHAR(255) NOT NULL,
  cargo          VARCHAR(100) NOT NULL,
  ativo          TINYINT(1)   NOT NULL DEFAULT 1,
  CONSTRAINT pk_funcionario PRIMARY KEY (id_funcionario),
  CONSTRAINT ck_funcionario_ativo CHECK (ativo IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE FORNECEDOR (
  id_fornecedor  INT          NOT NULL AUTO_INCREMENT,
  razao_social   VARCHAR(255) NOT NULL,
  cnpj           CHAR(14)     NOT NULL,
  telefone       VARCHAR(11)  NOT NULL,
  logradouro     VARCHAR(150) NULL,
  numero         VARCHAR(10)  NULL,
  bairro         VARCHAR(80)  NULL,
  cep            CHAR(8)      NULL,
  ativo          TINYINT(1)   NOT NULL DEFAULT 1,
  CONSTRAINT pk_fornecedor PRIMARY KEY (id_fornecedor),
  CONSTRAINT uq_fornecedor_cnpj UNIQUE (cnpj),                               -- RN16
  CONSTRAINT ck_fornecedor_cnpj CHECK (cnpj REGEXP '^[0-9]{14}$'),           -- RN16
  CONSTRAINT ck_fornecedor_telefone CHECK (telefone REGEXP '^[0-9]{10,11}$'),
  CONSTRAINT ck_fornecedor_ativo CHECK (ativo IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE PRODUTO (
  id_produto     INT           NOT NULL AUTO_INCREMENT,
  codigo         VARCHAR(50)   NOT NULL,
  nome           VARCHAR(255)  NOT NULL,
  preco          DECIMAL(10,2) NOT NULL,
  marca          VARCHAR(100)  NULL,
  unidade_venda  VARCHAR(20)   NOT NULL DEFAULT 'UN',
  origem         VARCHAR(10)   NOT NULL DEFAULT 'COMPRADO',
  ativo          TINYINT(1)    NOT NULL DEFAULT 1,
  CONSTRAINT pk_produto PRIMARY KEY (id_produto),
  CONSTRAINT uq_produto_codigo UNIQUE (codigo),                              -- RN01
  CONSTRAINT ck_produto_preco CHECK (preco > 0),                             -- RN01
  CONSTRAINT ck_produto_origem CHECK (origem IN ('COMPRADO','FABRICADO')),   -- RN22
  CONSTRAINT ck_produto_ativo CHECK (ativo IN (0,1))
) ENGINE=InnoDB;
CREATE INDEX idx_produto_nome ON PRODUTO (nome);

CREATE TABLE ESTOQUE (
  id_estoque            INT           NOT NULL AUTO_INCREMENT,
  id_produto            INT           NOT NULL,
  quantidade_disponivel DECIMAL(10,3) NOT NULL DEFAULT 0,
  estoque_minimo        DECIMAL(10,3) NOT NULL DEFAULT 0,
  data_atualizacao      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT pk_estoque PRIMARY KEY (id_estoque),
  CONSTRAINT uq_estoque_produto UNIQUE (id_produto),                         -- RN02 (1:1)
  CONSTRAINT fk_estoque_produto FOREIGN KEY (id_produto) REFERENCES PRODUTO (id_produto),
  CONSTRAINT ck_estoque_quantidade CHECK (quantidade_disponivel >= 0),       -- RN02
  CONSTRAINT ck_estoque_minimo CHECK (estoque_minimo >= 0)
) ENGINE=InnoDB;

CREATE TABLE PEDIDO (
  id_pedido        INT           NOT NULL AUTO_INCREMENT,
  id_cliente       INT           NULL,
  data_hora        DATETIME      NOT NULL,
  canal_pedido     VARCHAR(20)   NOT NULL,
  tipo_entrega     VARCHAR(10)   NOT NULL,
  endereco_entrega VARCHAR(255)  NULL,
  data_entrega     DATETIME      NULL,
  valor_total      DECIMAL(10,2) NOT NULL,
  status_pedido    VARCHAR(20)   NOT NULL DEFAULT 'REGISTRADO',
  CONSTRAINT pk_pedido PRIMARY KEY (id_pedido),
  CONSTRAINT fk_pedido_cliente FOREIGN KEY (id_cliente) REFERENCES CLIENTE (id_cliente),
  CONSTRAINT ck_pedido_canal CHECK (canal_pedido IN ('LOJA','WHATSAPP','CANAL_VENDA')),            -- RN03
  CONSTRAINT ck_pedido_tipo_entrega CHECK (tipo_entrega IN ('RETIRADA','ENTREGA')),                -- RN03
  CONSTRAINT ck_pedido_status CHECK (status_pedido IN ('REGISTRADO','PAGO','EM_SEPARACAO','CONFERIDO',
                                     'ENVIADO','ENTREGUE','COM_OCORRENCIA','CANCELADO')),
  CONSTRAINT ck_pedido_valor CHECK (valor_total > 0),
  CONSTRAINT ck_pedido_entrega_dados CHECK (tipo_entrega = 'RETIRADA'
                                     OR (id_cliente IS NOT NULL AND endereco_entrega IS NOT NULL)),  -- RN05
  CONSTRAINT ck_pedido_data_entrega CHECK (data_entrega IS NULL OR data_entrega >= data_hora),
  CONSTRAINT ck_pedido_entregue CHECK (status_pedido <> 'ENTREGUE' OR data_entrega IS NOT NULL)
) ENGINE=InnoDB;
CREATE INDEX idx_pedido_data ON PEDIDO (data_hora);
CREATE INDEX idx_pedido_status ON PEDIDO (status_pedido);

CREATE TABLE ITEM_PEDIDO (
  id_item        INT           NOT NULL AUTO_INCREMENT,
  id_pedido      INT           NOT NULL,
  id_produto     INT           NOT NULL,
  quantidade     DECIMAL(10,3) NOT NULL,
  preco_unitario DECIMAL(10,2) NOT NULL,
  CONSTRAINT pk_item_pedido PRIMARY KEY (id_item),
  CONSTRAINT uq_item_pedido_produto UNIQUE (id_pedido, id_produto),
  CONSTRAINT fk_item_pedido_pedido FOREIGN KEY (id_pedido) REFERENCES PEDIDO (id_pedido),
  CONSTRAINT fk_item_pedido_produto FOREIGN KEY (id_produto) REFERENCES PRODUTO (id_produto),         -- RN04
  CONSTRAINT ck_item_pedido_qtd CHECK (quantidade > 0),                                                -- RN04
  CONSTRAINT ck_item_pedido_preco CHECK (preco_unitario > 0)                                           -- RN04
) ENGINE=InnoDB;

CREATE TABLE PAGAMENTO (
  id_pagamento        INT           NOT NULL AUTO_INCREMENT,
  id_pedido           INT           NOT NULL,
  forma_pagamento     VARCHAR(10)   NOT NULL,
  valor_pagamento     DECIMAL(10,2) NOT NULL,
  status_pagamento    VARCHAR(10)   NOT NULL DEFAULT 'PENDENTE',
  data_hora_pagamento DATETIME      NOT NULL,
  CONSTRAINT pk_pagamento PRIMARY KEY (id_pagamento),
  CONSTRAINT fk_pagamento_pedido FOREIGN KEY (id_pedido) REFERENCES PEDIDO (id_pedido),
  CONSTRAINT ck_pagamento_forma CHECK (forma_pagamento IN ('PIX','CREDITO','DEBITO','DINHEIRO')),    -- RN07
  CONSTRAINT ck_pagamento_valor CHECK (valor_pagamento > 0),                                         -- RN07
  CONSTRAINT ck_pagamento_status CHECK (status_pagamento IN ('APROVADO','RECUSADO','PENDENTE'))      -- RN07
) ENGINE=InnoDB;
CREATE INDEX idx_pagamento_pedido ON PAGAMENTO (id_pedido);

CREATE TABLE NOTA_FISCAL (
  id_nota       INT           NOT NULL AUTO_INCREMENT,
  id_pedido     INT           NOT NULL,
  numero        INT           NOT NULL,
  serie         SMALLINT      NOT NULL DEFAULT 1,
  chave_acesso  CHAR(44)      NOT NULL,
  data_emissao  DATETIME      NOT NULL,
  valor_total   DECIMAL(10,2) NOT NULL,
  CONSTRAINT pk_nota_fiscal PRIMARY KEY (id_nota),
  CONSTRAINT uq_nota_pedido UNIQUE (id_pedido),                                    -- RN14 (1 nota por pedido)
  CONSTRAINT uq_nota_serie_numero UNIQUE (serie, numero),                          -- RN15
  CONSTRAINT uq_nota_chave UNIQUE (chave_acesso),                                  -- RN15
  CONSTRAINT fk_nota_pedido FOREIGN KEY (id_pedido) REFERENCES PEDIDO (id_pedido),
  CONSTRAINT ck_nota_chave CHECK (chave_acesso REGEXP '^[0-9]{44}$'),              -- RN15
  CONSTRAINT ck_nota_valor CHECK (valor_total > 0)
) ENGINE=InnoDB;

CREATE TABLE SEPARACAO_PEDIDO (
  id_separacao        INT          NOT NULL AUTO_INCREMENT,
  id_pedido           INT          NOT NULL,
  id_funcionario      INT          NOT NULL,
  data_hora_separacao DATETIME     NOT NULL,
  status_conferencia  VARCHAR(10)  NOT NULL,
  observacao          VARCHAR(255) NULL,
  CONSTRAINT pk_separacao PRIMARY KEY (id_separacao),
  CONSTRAINT fk_separacao_pedido FOREIGN KEY (id_pedido) REFERENCES PEDIDO (id_pedido),
  CONSTRAINT fk_separacao_funcionario FOREIGN KEY (id_funcionario) REFERENCES FUNCIONARIO (id_funcionario),
  CONSTRAINT ck_separacao_status CHECK (status_conferencia IN ('CONFERIDO','DIVERGENTE')),          -- RN09
  CONSTRAINT ck_separacao_obs CHECK (status_conferencia = 'CONFERIDO' OR observacao IS NOT NULL)    -- RN09
) ENGINE=InnoDB;

CREATE TABLE OCORRENCIA (
  id_ocorrencia       INT          NOT NULL AUTO_INCREMENT,
  id_pedido           INT          NOT NULL,
  tipo_ocorrencia     VARCHAR(20)  NOT NULL,
  descricao           VARCHAR(255) NOT NULL,
  solucao_aplicada    VARCHAR(20)  NULL,
  status_ocorrencia   VARCHAR(10)  NOT NULL DEFAULT 'ABERTA',
  data_hora           DATETIME     NOT NULL,
  data_hora_resolucao DATETIME     NULL,
  CONSTRAINT pk_ocorrencia PRIMARY KEY (id_ocorrencia),
  CONSTRAINT fk_ocorrencia_pedido FOREIGN KEY (id_pedido) REFERENCES PEDIDO (id_pedido),
  CONSTRAINT ck_ocorrencia_tipo CHECK (tipo_ocorrencia IN ('PRODUTO_ERRADO','FALTA_ESTOQUE','PROBLEMA_ENTREGA','OUTRO')),   -- RN10
  CONSTRAINT ck_ocorrencia_solucao CHECK (solucao_aplicada IS NULL
                                    OR solucao_aplicada IN ('SUBSTITUICAO','CORRECAO_PEDIDO','NOVA_ENTREGA','OUTRO')),     -- RN10
  CONSTRAINT ck_ocorrencia_status CHECK (status_ocorrencia IN ('ABERTA','RESOLVIDA')),                                     -- RN10
  CONSTRAINT ck_ocorrencia_resolucao CHECK (
      (status_ocorrencia = 'RESOLVIDA' AND solucao_aplicada IS NOT NULL AND data_hora_resolucao IS NOT NULL)
   OR (status_ocorrencia = 'ABERTA' AND data_hora_resolucao IS NULL)),                                                     -- RN10
  CONSTRAINT ck_ocorrencia_datas CHECK (data_hora_resolucao IS NULL OR data_hora_resolucao >= data_hora)
) ENGINE=InnoDB;
CREATE INDEX idx_ocorrencia_status ON OCORRENCIA (status_ocorrencia);

CREATE TABLE TROCA_DEVOLUCAO (
  id_troca           INT          NOT NULL AUTO_INCREMENT,
  id_pedido          INT          NOT NULL,
  id_produto         INT          NOT NULL,
  fundamento         VARCHAR(15)  NOT NULL,
  motivo             VARCHAR(255) NOT NULL,
  condicao_produto   VARCHAR(100) NOT NULL,
  tipo_solicitacao   VARCHAR(10)  NOT NULL,
  status_solicitacao VARCHAR(10)  NOT NULL DEFAULT 'EM_ANALISE',
  data_hora          DATETIME     NOT NULL,
  CONSTRAINT pk_troca PRIMARY KEY (id_troca),
  CONSTRAINT fk_troca_pedido FOREIGN KEY (id_pedido) REFERENCES PEDIDO (id_pedido),
  CONSTRAINT fk_troca_produto FOREIGN KEY (id_produto) REFERENCES PRODUTO (id_produto),
  CONSTRAINT ck_troca_fundamento CHECK (fundamento IN ('ARREPENDIMENTO','VICIO','OUTRO')),                  -- RN12
  CONSTRAINT ck_troca_tipo CHECK (tipo_solicitacao IN ('TROCA','DEVOLUCAO','REEMBOLSO')),                   -- RN11
  CONSTRAINT ck_troca_status CHECK (status_solicitacao IN ('EM_ANALISE','APROVADA','CONCLUIDA','RECUSADA')) -- RN11
) ENGINE=InnoDB;

CREATE TABLE PEDIDO_COMPRA (
  id_pedido_compra INT           NOT NULL AUTO_INCREMENT,
  id_fornecedor    INT           NOT NULL,
  data_pedido      DATETIME      NOT NULL,
  status_compra    VARCHAR(10)   NOT NULL DEFAULT 'ABERTO',
  valor_total      DECIMAL(12,2) NOT NULL,
  CONSTRAINT pk_pedido_compra PRIMARY KEY (id_pedido_compra),
  CONSTRAINT fk_pedido_compra_fornecedor FOREIGN KEY (id_fornecedor) REFERENCES FORNECEDOR (id_fornecedor),  -- RN16
  CONSTRAINT ck_pedido_compra_status CHECK (status_compra IN ('ABERTO','PARCIAL','RECEBIDO','CANCELADO')),   -- RN18
  CONSTRAINT ck_pedido_compra_valor CHECK (valor_total > 0)
) ENGINE=InnoDB;

CREATE TABLE ITEM_PEDIDO_COMPRA (
  id_item_compra   INT           NOT NULL AUTO_INCREMENT,
  id_pedido_compra INT           NOT NULL,
  id_produto       INT           NOT NULL,
  quantidade       DECIMAL(10,3) NOT NULL,
  custo_unitario   DECIMAL(10,2) NOT NULL,
  CONSTRAINT pk_item_pedido_compra PRIMARY KEY (id_item_compra),
  CONSTRAINT uq_item_compra_produto UNIQUE (id_pedido_compra, id_produto),
  CONSTRAINT fk_item_compra_pedido FOREIGN KEY (id_pedido_compra) REFERENCES PEDIDO_COMPRA (id_pedido_compra),
  CONSTRAINT fk_item_compra_produto FOREIGN KEY (id_produto) REFERENCES PRODUTO (id_produto),
  CONSTRAINT ck_item_compra_qtd CHECK (quantidade > 0),            -- RN17
  CONSTRAINT ck_item_compra_custo CHECK (custo_unitario > 0)       -- RN17
) ENGINE=InnoDB;

CREATE TABLE RECEBIMENTO (
  id_recebimento       INT         NOT NULL AUTO_INCREMENT,
  id_pedido_compra     INT         NOT NULL,
  id_funcionario       INT         NOT NULL,
  data_hora            DATETIME    NOT NULL,
  numero_nf_fornecedor VARCHAR(20) NOT NULL,
  CONSTRAINT pk_recebimento PRIMARY KEY (id_recebimento),
  CONSTRAINT uq_recebimento_nf UNIQUE (id_pedido_compra, numero_nf_fornecedor),
  CONSTRAINT fk_recebimento_pedido_compra FOREIGN KEY (id_pedido_compra) REFERENCES PEDIDO_COMPRA (id_pedido_compra),
  CONSTRAINT fk_recebimento_funcionario FOREIGN KEY (id_funcionario) REFERENCES FUNCIONARIO (id_funcionario)
) ENGINE=InnoDB;

CREATE TABLE ITEM_RECEBIMENTO (
  id_item_recebimento INT           NOT NULL AUTO_INCREMENT,
  id_recebimento      INT           NOT NULL,
  id_item_compra      INT           NOT NULL,
  quantidade_recebida DECIMAL(10,3) NOT NULL,
  CONSTRAINT pk_item_recebimento PRIMARY KEY (id_item_recebimento),
  CONSTRAINT uq_item_recebimento UNIQUE (id_recebimento, id_item_compra),
  CONSTRAINT fk_item_receb_recebimento FOREIGN KEY (id_recebimento) REFERENCES RECEBIMENTO (id_recebimento),
  CONSTRAINT fk_item_receb_item_compra FOREIGN KEY (id_item_compra) REFERENCES ITEM_PEDIDO_COMPRA (id_item_compra),
  CONSTRAINT ck_item_receb_qtd CHECK (quantidade_recebida > 0)     -- RN18
) ENGINE=InnoDB;

CREATE TABLE CONTA_PAGAR (
  id_conta        INT           NOT NULL AUTO_INCREMENT,
  id_recebimento  INT           NOT NULL,
  data_vencimento DATE          NOT NULL,
  valor           DECIMAL(12,2) NOT NULL,
  status_conta    VARCHAR(10)   NOT NULL DEFAULT 'ABERTA',
  data_pagamento  DATE          NULL,
  forma_pagamento VARCHAR(15)   NULL,
  CONSTRAINT pk_conta_pagar PRIMARY KEY (id_conta),
  CONSTRAINT uq_conta_recebimento UNIQUE (id_recebimento),                                  -- RN19
  CONSTRAINT fk_conta_recebimento FOREIGN KEY (id_recebimento) REFERENCES RECEBIMENTO (id_recebimento),
  CONSTRAINT ck_conta_valor CHECK (valor > 0),                                              -- RN20
  CONSTRAINT ck_conta_status CHECK (status_conta IN ('ABERTA','PAGA','CANCELADA')),         -- RN20
  CONSTRAINT ck_conta_forma CHECK (forma_pagamento IS NULL
                             OR forma_pagamento IN ('PIX','BOLETO','TRANSFERENCIA','DINHEIRO')),
  CONSTRAINT ck_conta_paga CHECK (
      (status_conta = 'PAGA' AND data_pagamento IS NOT NULL AND forma_pagamento IS NOT NULL)
   OR (status_conta <> 'PAGA' AND data_pagamento IS NULL))                                  -- RN20
) ENGINE=InnoDB;
CREATE INDEX idx_conta_vencimento ON CONTA_PAGAR (data_vencimento);

CREATE TABLE ORDEM_PRODUCAO (
  id_ordem_producao INT           NOT NULL AUTO_INCREMENT,
  id_produto        INT           NOT NULL,
  id_funcionario    INT           NOT NULL,
  quantidade        DECIMAL(10,3) NOT NULL,
  data_hora         DATETIME      NOT NULL,
  status_producao   VARCHAR(10)   NOT NULL DEFAULT 'ABERTA',
  CONSTRAINT pk_ordem_producao PRIMARY KEY (id_ordem_producao),
  CONSTRAINT fk_ordem_produto FOREIGN KEY (id_produto) REFERENCES PRODUTO (id_produto),
  CONSTRAINT fk_ordem_funcionario FOREIGN KEY (id_funcionario) REFERENCES FUNCIONARIO (id_funcionario),
  CONSTRAINT ck_ordem_qtd CHECK (quantidade > 0),
  CONSTRAINT ck_ordem_status CHECK (status_producao IN ('ABERTA','CONCLUIDA','CANCELADA'))  -- RN22
) ENGINE=InnoDB;

CREATE TABLE MOVIMENTACAO_ESTOQUE (
  id_movimentacao   INT           NOT NULL AUTO_INCREMENT,
  id_produto        INT           NOT NULL,
  id_funcionario    INT           NOT NULL,
  tipo_movimentacao VARCHAR(20)   NOT NULL,
  quantidade        DECIMAL(10,3) NOT NULL,
  data_hora         DATETIME      NOT NULL,
  id_pedido         INT           NULL,
  id_recebimento    INT           NULL,
  id_ordem_producao INT           NULL,
  CONSTRAINT pk_movimentacao PRIMARY KEY (id_movimentacao),
  CONSTRAINT fk_mov_produto FOREIGN KEY (id_produto) REFERENCES PRODUTO (id_produto),
  CONSTRAINT fk_mov_funcionario FOREIGN KEY (id_funcionario) REFERENCES FUNCIONARIO (id_funcionario),
  CONSTRAINT fk_mov_pedido FOREIGN KEY (id_pedido) REFERENCES PEDIDO (id_pedido),
  CONSTRAINT fk_mov_recebimento FOREIGN KEY (id_recebimento) REFERENCES RECEBIMENTO (id_recebimento),
  CONSTRAINT fk_mov_ordem FOREIGN KEY (id_ordem_producao) REFERENCES ORDEM_PRODUCAO (id_ordem_producao),
  CONSTRAINT ck_mov_qtd CHECK (quantidade > 0),                                              -- RN21
  CONSTRAINT ck_mov_tipo_origem CHECK (                                                      -- RN21
      (tipo_movimentacao = 'ENTRADA_COMPRA'    AND id_recebimento IS NOT NULL AND id_pedido IS NULL AND id_ordem_producao IS NULL)
   OR (tipo_movimentacao = 'ENTRADA_PRODUCAO'  AND id_ordem_producao IS NOT NULL AND id_pedido IS NULL AND id_recebimento IS NULL)
   OR (tipo_movimentacao IN ('SAIDA_VENDA','ENTRADA_DEVOLUCAO') AND id_pedido IS NOT NULL AND id_recebimento IS NULL AND id_ordem_producao IS NULL)
   OR (tipo_movimentacao IN ('ENTRADA_AJUSTE','SAIDA_AJUSTE') AND id_pedido IS NULL AND id_recebimento IS NULL AND id_ordem_producao IS NULL))
) ENGINE=InnoDB;
CREATE INDEX idx_mov_produto_data ON MOVIMENTACAO_ESTOQUE (id_produto, data_hora);

-- 3. INSERT INTO — MASSA DE DADOS FICTÍCIA ----------------------------
-- Período dos pedidos: 01/07/2026 a 31/10/2026. Nomes, CPFs/CNPJs, telefones e endereços são inventados.
-- Inconsistências propositais (para a demonstração das consultas de auditoria):
--   * pedido 173: em separação com pagamentos aprovados abaixo do valor total (A02)
--   * pedido 4: valor_total diferente da soma dos itens e da nota fiscal (A05, A07)
--   * pedido 12: entregue sem nota fiscal (A06)

-- CLIENTE
INSERT INTO CLIENTE (id_cliente, nome, telefone, cpf_cnpj, logradouro, numero, bairro, cep, data_cadastro) VALUES
  (1, 'Juliana Ferraz Teixeira', '11900025976', NULL, 'Avenida Central', '754', 'Vila Esperança', '03528535', '2026-05-18 14:34:00'),
  (2, 'Giovana Henriques Ferraz', '11900070126', NULL, 'Rua São Jorge', '711', 'Vila Aricanduva', '03832234', '2026-06-03 09:19:00'),
  (3, 'Wagner Henriques Queiroz', '11900023742', '00000000003', 'Rua das Acácias', '100', 'Artur Alvim', '03876192', '2026-01-03 12:22:00'),
  (4, 'Carlos Gomes Barbosa', '11900076273', NULL, 'Rua São Jorge', '923', 'Cangaíba', '03909507', '2026-02-25 11:48:00'),
  (5, 'Otávio Almeida Ibrahim', '11900002161', NULL, 'Rua das Palmeiras', '827', 'Cangaíba', '03562850', '2026-01-01 15:43:00'),
  (6, 'Isabela Almeida Henriques', '11900061710', '00000000006', 'Rua das Hortênsias', '605', 'Penha', '03960783', '2026-02-08 13:45:00'),
  (7, 'Daniela Siqueira Nogueira', '11900032918', NULL, 'Avenida dos Andradas', '724', 'Artur Alvim', '03511693', '2026-04-27 17:07:00'),
  (8, 'Patrícia Teixeira Henriques', '11900057966', NULL, 'Rua das Acácias', '452', 'Vila Ré', '03268030', '2026-05-12 09:22:00'),
  (9, 'Wagner Esteves Nogueira', '11900028454', '00000000009', 'Rua Santa Clara', '928', 'Vila Matilde', '03387340', '2026-01-10 16:48:00'),
  (10, 'Helena Cardoso Nogueira', '11900007635', NULL, 'Rua das Hortênsias', '478', 'Vila Aricanduva', '03169848', '2026-04-21 09:01:00'),
  (11, 'Reformas Esteves Ltda', '11900066219', '00000000000011', 'Rua das Palmeiras', '636', 'Vila Aricanduva', '03333628', '2026-01-09 10:52:00'),
  (12, 'Helena Ramos Vieira', '11900043032', '00000000012', 'Avenida dos Andradas', '405', 'Ponte Rasa', '03641841', '2026-01-16 14:46:00'),
  (13, 'Felipe Barbosa Ramos', '11900088357', NULL, 'Rua das Palmeiras', '101', 'Vila Esperança', '03730687', '2026-04-11 15:37:00'),
  (14, 'Wagner Dias Vieira', '11900050138', NULL, 'Rua São Jorge', '656', 'Ponte Rasa', '03268292', '2026-02-12 17:11:00'),
  (15, 'Felipe Ramos Oliveira', '11900080021', '00000000015', 'Rua do Comércio', '731', 'Vila Matilde', '03128354', '2026-06-12 17:31:00'),
  (16, 'Yasmin Esteves Nogueira', '11900036647', NULL, 'Rua São Jorge', '148', 'Ponte Rasa', '03472245', '2026-04-15 12:58:00'),
  (17, 'Joana Almeida Gomes', '11900090254', NULL, 'Rua São Jorge', '11', 'Vila Matilde', '03722126', '2026-05-26 09:31:00'),
  (18, 'Yasmin Lopes Ramos', '11900035607', '00000000018', 'Rua das Palmeiras', '905', 'Cangaíba', '03956210', '2026-06-02 15:23:00'),
  (19, 'Marcos Lopes Moreira', '11900091485', NULL, 'Rua Bela Vista', '155', 'Penha', '03915557', '2026-04-15 11:09:00'),
  (20, 'Daniela Ramos Ferraz', '11900029437', NULL, 'Rua dos Ipês', '89', 'Vila Matilde', '03912581', '2026-04-16 13:15:00'),
  (21, 'Daniela Barbosa Oliveira', '11900066470', '00000000021', 'Rua das Palmeiras', '388', 'Vila Esperança', '03224359', '2026-06-21 09:15:00'),
  (22, 'Reformas Esteves Ltda', '11900013221', '00000000000022', 'Rua do Comércio', '214', 'Vila Esperança', '03071057', '2026-01-14 13:55:00'),
  (23, 'Heitor Almeida Nogueira', '11900021738', NULL, 'Avenida Central', '857', 'Vila Aricanduva', '03170187', '2026-03-15 10:33:00'),
  (24, 'Eduardo Pacheco Vieira', '11900058372', '00000000024', 'Avenida Central', '401', 'Vila Aricanduva', '03895934', '2026-03-17 10:41:00'),
  (25, 'Davi Ferraz Siqueira', '11900001513', NULL, 'Rua das Hortênsias', '505', 'Vila Matilde', '03811855', '2026-01-01 17:23:00'),
  (26, 'Heitor Lopes Jesus', '11900021487', NULL, 'Avenida dos Andradas', '908', 'Vila Esperança', '03943544', '2026-03-06 17:12:00'),
  (27, 'Elisa Nogueira Pacheco', '11900004099', '00000000027', 'Rua das Acácias', '976', 'Cangaíba', '03730379', '2026-03-27 08:47:00'),
  (28, 'Joana Siqueira Nogueira', '11900005397', NULL, 'Rua São Jorge', '900', 'Ponte Rasa', '03412478', '2026-05-01 15:07:00'),
  (29, 'Tiago Siqueira Pacheco', '11900029237', NULL, 'Rua Santa Clara', '106', 'Vila Aricanduva', '03844691', '2026-03-04 14:52:00'),
  (30, 'Wagner Moreira Ferraz', '11900073059', '00000000030', 'Rua dos Ipês', '429', 'Artur Alvim', '03412296', '2026-01-05 17:07:00'),
  (31, 'Eduardo Lopes Barbosa', '11900038399', NULL, 'Rua das Acácias', '667', 'Vila Aricanduva', '03294835', '2026-05-13 13:13:00'),
  (32, 'Giovana Teixeira Cardoso', '11900031694', NULL, 'Rua São Jorge', '903', 'Vila Aricanduva', '03240519', '2026-06-03 12:17:00'),
  (33, 'Reformas Vieira Ltda', '11900042763', '00000000033', 'Rua Santa Clara', '554', 'Artur Alvim', '03077314', '2026-04-17 08:23:00'),
  (34, 'Rafael Dias Gomes', '11900097777', NULL, 'Avenida dos Andradas', '62', 'Penha', '03618399', '2026-01-22 09:38:00'),
  (35, 'Daniela Cardoso Moreira', '11900029659', NULL, 'Rua Bela Vista', '948', 'Penha', '03426944', '2026-06-28 12:19:00'),
  (36, 'Elisa Barbosa Henriques', '11900086738', '00000000036', 'Rua das Palmeiras', '306', 'Ponte Rasa', '03351715', '2026-02-23 11:55:00'),
  (37, 'Marcos Barbosa Ramos', '11900035048', NULL, 'Rua Bela Vista', '336', 'Artur Alvim', '03030209', '2026-04-08 13:23:00'),
  (38, 'Marcos Jesus Henriques', '11900044259', NULL, 'Rua Santa Clara', '562', 'Vila Matilde', '03763669', '2026-02-10 08:03:00'),
  (39, 'Yasmin Queiroz Ramos', '11900015786', '00000000039', 'Rua das Acácias', '741', 'Cangaíba', '03523321', '2026-03-16 08:02:00'),
  (40, 'Tiago Ramos Gomes', '11900055656', NULL, 'Rua das Acácias', '839', 'Cangaíba', '03643960', '2026-03-05 14:03:00'),
  (41, 'Wagner Jesus Gomes', '11900055967', NULL, 'Rua São Jorge', '356', 'Vila Esperança', '03770941', '2026-01-22 17:09:00'),
  (42, 'Kleber Siqueira Henriques', '11900075418', '00000000042', 'Rua Bela Vista', '591', 'Penha', '03754412', '2026-04-24 15:21:00'),
  (43, 'Otávio Gomes Siqueira', '11900075284', NULL, 'Rua Santa Clara', '961', 'Penha', '03580986', '2026-06-10 11:57:00'),
  (44, 'Engenharia Lopes Ltda', '11900061577', '00000000000044', 'Rua Santa Clara', '696', 'Penha', '03668968', '2026-03-07 09:12:00'),
  (45, 'Wagner Siqueira Ramos', '11900080730', '00000000045', 'Avenida dos Andradas', '43', 'Ponte Rasa', '03699917', '2026-02-01 17:56:00');

-- FUNCIONARIO
INSERT INTO FUNCIONARIO (id_funcionario, nome, cargo, ativo) VALUES
  (1, 'Natália Moreira Barbosa', 'Gerente', 1),
  (2, 'Felipe Oliveira Pacheco', 'Vendedor', 1),
  (3, 'Juliana Ferraz Barbosa', 'Vendedor', 1),
  (4, 'Elisa Lopes Pacheco', 'Balconista', 1),
  (5, 'Otávio Pacheco Oliveira', 'Separador de pedidos', 1),
  (6, 'Elisa Esteves Nogueira', 'Separador de pedidos', 1),
  (7, 'Kleber Dias Teixeira', 'Estoquista', 1),
  (8, 'Sandra Barbosa Esteves', 'Operador de produção', 1),
  (9, 'Isabela Ferraz Gomes', 'Auxiliar financeiro', 1);

-- FORNECEDOR (o fornecedor 8 está inativo)
INSERT INTO FORNECEDOR (id_fornecedor, razao_social, cnpj, telefone, logradouro, numero, bairro, cep, ativo) VALUES
  (1, 'Hidráulica Aurora Ltda', '00000000000001', '11900047274', 'Rua do Comércio', '839', 'Artur Alvim', '03030563', 1),
  (2, 'Louças e Metais Horizonte Ltda', '00000000000002', '11900063131', 'Rua do Comércio', '2239', 'Cangaíba', '03579745', 1),
  (3, 'Distribuidora Planalto de Materiais Ltda', '00000000000003', '11900043796', 'Rua dos Ipês', '2298', 'Vila Matilde', '03255461', 1),
  (4, 'Tubos e Conexões Vale Verde Ltda', '00000000000004', '11900015718', 'Rua das Hortênsias', '2098', 'Vila Aricanduva', '03225993', 1),
  (5, 'Reservatórios Nova Era Ltda', '00000000000005', '11900011638', 'Rua Santa Clara', '1615', 'Vila Matilde', '03355723', 1),
  (6, 'Cerâmica Santa Aurora Ltda', '00000000000006', '11900071071', 'Rua do Comércio', '1650', 'Ponte Rasa', '03093542', 1),
  (7, 'Metalúrgica Ferro Forte Ltda', '00000000000007', '11900059284', 'Rua Bela Vista', '2305', 'Vila Aricanduva', '03980568', 1),
  (8, 'Esquadrias Brasil Sul Ltda', '00000000000008', '11900080184', 'Rua do Comércio', '1113', 'Vila Matilde', '03586321', 0);

-- PRODUTO
INSERT INTO PRODUTO (id_produto, codigo, nome, preco, marca, unidade_venda, origem, ativo) VALUES
  (1, 'CTL0001', 'Tubo PVC soldável 20 mm 3 m', 9.90, 'Tigre', 'UN', 'COMPRADO', 1),
  (2, 'CTL0002', 'Tubo PVC soldável 25 mm 3 m', 12.50, 'Tigre', 'UN', 'COMPRADO', 1),
  (3, 'CTL0003', 'Tubo PVC soldável 32 mm 3 m', 18.90, 'Tigre', 'UN', 'COMPRADO', 1),
  (4, 'CTL0004', 'Tubo PVC soldável 40 mm 3 m', 27.90, 'Tigre', 'UN', 'COMPRADO', 1),
  (5, 'CTL0005', 'Tubo PVC soldável 50 mm 3 m', 35.50, 'Tigre', 'UN', 'COMPRADO', 1),
  (6, 'CTL0006', 'Tubo PVC soldável 75 mm 3 m', 62.00, 'Tigre', 'UN', 'COMPRADO', 1),
  (7, 'CTL0007', 'Joelho 90° PVC soldável 20 mm', 1.90, 'Tigre', 'UN', 'COMPRADO', 1),
  (8, 'CTL0008', 'Luva PVC soldável 20 mm', 1.71, 'Tigre', 'UN', 'COMPRADO', 1),
  (9, 'CTL0009', 'Joelho 90° PVC soldável 25 mm', 2.60, 'Tigre', 'UN', 'COMPRADO', 1),
  (10, 'CTL0010', 'Luva PVC soldável 25 mm', 2.34, 'Tigre', 'UN', 'COMPRADO', 1),
  (11, 'CTL0011', 'Joelho 90° PVC soldável 32 mm', 4.90, 'Tigre', 'UN', 'COMPRADO', 1),
  (12, 'CTL0012', 'Luva PVC soldável 32 mm', 4.41, 'Tigre', 'UN', 'COMPRADO', 1),
  (13, 'CTL0013', 'Joelho 90° PVC soldável 40 mm', 7.50, 'Tigre', 'UN', 'COMPRADO', 1),
  (14, 'CTL0014', 'Luva PVC soldável 40 mm', 6.75, 'Tigre', 'UN', 'COMPRADO', 1),
  (15, 'CTL0015', 'Joelho 90° PVC soldável 50 mm', 9.90, 'Tigre', 'UN', 'COMPRADO', 1),
  (16, 'CTL0016', 'Luva PVC soldável 50 mm', 8.91, 'Tigre', 'UN', 'COMPRADO', 1),
  (17, 'CTL0017', 'Registro de gaveta 3/4"', 42.90, 'Deca', 'UN', 'COMPRADO', 1),
  (18, 'CTL0018', 'Registro de gaveta 1/2"', 38.90, 'Deca', 'UN', 'COMPRADO', 1),
  (19, 'CTL0019', 'Registro de esfera 3/4"', 29.90, 'Docol', 'UN', 'COMPRADO', 1),
  (20, 'CTL0020', 'Registro de pressão 1/2"', 36.50, 'Docol', 'UN', 'COMPRADO', 1),
  (21, 'CTL0021', 'Torneira de mesa cromada para lavatório', 89.90, 'Docol', 'UN', 'COMPRADO', 1),
  (22, 'CTL0022', 'Torneira de parede para cozinha', 74.90, 'Docol', 'UN', 'COMPRADO', 1),
  (23, 'CTL0023', 'Misturador monocomando para lavatório', 189.00, 'Deca', 'UN', 'COMPRADO', 1),
  (24, 'CTL0024', 'Chuveiro elétrico 5500 W', 64.90, 'Lorenzetti', 'UN', 'COMPRADO', 1),
  (25, 'CTL0025', 'Ducha higiênica com registro', 112.00, 'Docol', 'UN', 'COMPRADO', 1),
  (26, 'CTL0026', 'Sifão sanfonado universal', 14.90, 'Amanco', 'UN', 'COMPRADO', 1),
  (27, 'CTL0027', 'Flexível inox 40 cm', 16.50, 'Amanco', 'UN', 'COMPRADO', 1),
  (28, 'CTL0028', 'Válvula de escoamento para pia', 21.90, 'Amanco', 'UN', 'COMPRADO', 1),
  (29, 'CTL0029', 'Vaso sanitário com caixa acoplada', 489.00, 'Deca', 'UN', 'COMPRADO', 1),
  (30, 'CTL0030', 'Lavatório com coluna', 229.00, 'Deca', 'UN', 'COMPRADO', 1),
  (31, 'CTL0031', 'Tanque de louça com coluna', 259.00, 'Deca', 'UN', 'COMPRADO', 1),
  (32, 'CTL0032', 'Cuba de apoio redonda', 139.00, 'Deca', 'UN', 'COMPRADO', 1),
  (33, 'CTL0033', 'Assento sanitário universal', 54.90, 'Tigre', 'UN', 'COMPRADO', 1),
  (34, 'CTL0034', 'Pia de cozinha em aço inox 1,20 m', 329.00, 'Tramontina', 'UN', 'COMPRADO', 1),
  (35, 'CTL0035', 'Gabinete de banheiro 60 cm', 279.00, 'Cozimax', 'UN', 'COMPRADO', 1),
  (36, 'CTL0036', 'Cuba de cozinha em aço inox', 149.00, 'Tramontina', 'UN', 'COMPRADO', 1),
  (37, 'CTL0037', 'Caixa d''água de polietileno 500 L', 429.00, 'Fortlev', 'UN', 'COMPRADO', 1),
  (38, 'CTL0038', 'Caixa d''água de polietileno 1000 L', 699.00, 'Fortlev', 'UN', 'COMPRADO', 1),
  (39, 'CTL0039', 'Boia para caixa d''água 3/4"', 19.90, 'Amanco', 'UN', 'COMPRADO', 1),
  (40, 'CTL0040', 'Argamassa AC-II 20 kg', 27.90, 'Quartzolit', 'SC', 'COMPRADO', 1),
  (41, 'CTL0041', 'Rejunte flexível 1 kg', 12.90, 'Quartzolit', 'UN', 'COMPRADO', 1),
  (42, 'CTL0042', 'Silicone neutro tubo 280 g', 24.90, 'Tigre', 'UN', 'COMPRADO', 1),
  (43, 'CTL0043', 'Fita veda rosca 18 mm x 50 m', 9.90, 'Tigre', 'UN', 'COMPRADO', 1),
  (44, 'CTL0044', 'Adesivo para PVC 175 g', 17.90, 'Tigre', 'UN', 'COMPRADO', 1),
  (45, 'CTL0045', 'Cimento CP-II 50 kg', 38.90, 'Votoran', 'SC', 'COMPRADO', 1),
  (46, 'CTL0046', 'Massa para vedação 400 g', 15.90, 'Tigre', 'UN', 'COMPRADO', 1),
  (47, 'CTL0047', 'Piso cerâmico retificado 60x60 cm', 54.90, 'Eliane', 'M2', 'COMPRADO', 1),
  (48, 'CTL0048', 'Piso porcelanato acetinado 60x60 cm', 89.90, 'Portinari', 'M2', 'COMPRADO', 1),
  (49, 'CTL0049', 'Azulejo branco brilhante 30x60 cm', 42.90, 'Eliane', 'M2', 'COMPRADO', 1),
  (50, 'CTL0050', 'Porta de madeira lisa 80 cm', 259.00, 'Pormade', 'UN', 'COMPRADO', 1),
  (51, 'CTL0051', 'Janela de alumínio de correr 1,00 x 1,00 m', 339.00, 'Sasazaki', 'UN', 'COMPRADO', 1),
  (52, 'CTL0052', 'Calha de alumínio 120 mm', 32.00, NULL, 'M', 'FABRICADO', 1),
  (53, 'CTL0053', 'Calha de alumínio 150 mm', 38.00, NULL, 'M', 'FABRICADO', 1),
  (54, 'CTL0054', 'Calha galvanizada 150 mm', 29.00, NULL, 'M', 'FABRICADO', 1),
  (55, 'CTL0055', 'Rufo de chapa galvanizada 30 cm', 27.00, NULL, 'M', 'FABRICADO', 1),
  (56, 'CTL0056', 'Condutor de alumínio 80 mm', 21.00, NULL, 'M', 'FABRICADO', 1),
  (57, 'CTL0057', 'Cumeeira de chapa galvanizada', 34.00, NULL, 'M', 'FABRICADO', 1),
  (58, 'CTL0058', 'Pingadeira de chapa galvanizada', 19.00, NULL, 'M', 'FABRICADO', 1),
  (59, 'CTL0059', 'Coifa de chapa galvanizada', 189.00, NULL, 'UN', 'FABRICADO', 1),
  (60, 'CTL0060', 'Cabeceira de calha', 12.00, NULL, 'UN', 'FABRICADO', 1);

-- ESTOQUE (saldo = soma das movimentações)
INSERT INTO ESTOQUE (id_estoque, id_produto, quantidade_disponivel, estoque_minimo, data_atualizacao) VALUES
  (1, 1, 138.000, 5.000, '2026-10-18 11:45:24'),
  (2, 2, 139.000, 20.000, '2026-10-10 17:49:38'),
  (3, 3, 50.000, 15.000, '2026-08-26 14:54:41'),
  (4, 4, 85.000, 15.000, '2026-10-13 03:43:29'),
  (5, 5, 142.000, 15.000, '2026-10-21 06:59:28'),
  (6, 6, 40.000, 15.000, '2026-10-30 15:58:20'),
  (7, 7, 145.000, 20.000, '2026-10-12 16:28:06'),
  (8, 8, 183.000, 15.000, '2026-10-10 17:49:38'),
  (9, 9, 144.000, 15.000, '2026-10-12 12:50:26'),
  (10, 10, 98.000, 15.000, '2026-10-18 11:45:24'),
  (11, 11, 206.000, 20.000, '2026-10-24 13:53:22'),
  (12, 12, 3.000, 15.000, '2026-10-13 02:12:05'),
  (13, 13, 233.000, 10.000, '2026-10-24 13:53:22'),
  (14, 14, 64.000, 10.000, '2026-09-05 11:37:54'),
  (15, 15, 136.000, 20.000, '2026-10-13 01:02:39'),
  (16, 16, 1.000, 15.000, '2026-10-12 12:50:26'),
  (17, 17, 118.000, 10.000, '2026-11-01 02:15:12'),
  (18, 18, 88.000, 20.000, '2026-10-27 06:47:46'),
  (19, 19, 125.000, 5.000, '2026-10-13 01:02:39'),
  (20, 20, 122.000, 15.000, '2026-10-25 06:24:59'),
  (21, 21, 108.000, 10.000, '2026-10-17 21:40:11'),
  (22, 22, 12.000, 15.000, '2026-10-06 02:13:58'),
  (23, 23, 57.400, 20.000, '2026-10-11 01:49:21'),
  (24, 24, 83.000, 15.000, '2026-10-13 17:01:20'),
  (25, 25, 291.500, 5.000, '2026-10-06 03:44:08'),
  (26, 26, 58.000, 20.000, '2026-10-20 11:31:58'),
  (27, 27, 144.000, 10.000, '2026-10-29 21:52:38'),
  (28, 28, 1.000, 15.000, '2026-10-19 15:23:54'),
  (29, 29, 186.500, 20.000, '2026-10-30 23:45:23'),
  (30, 30, 65.000, 10.000, '2026-10-13 02:12:05'),
  (31, 31, 256.200, 5.000, '2026-10-04 05:35:10'),
  (32, 32, 147.000, 20.000, '2026-10-08 07:13:53'),
  (33, 33, 154.000, 5.000, '2026-10-17 21:40:11'),
  (34, 34, 124.000, 10.000, '2026-10-23 22:04:59'),
  (35, 35, 0.000, 15.000, '2026-10-30 23:45:23'),
  (36, 36, 105.000, 15.000, '2026-10-01 11:09:52'),
  (37, 37, 244.400, 20.000, '2026-10-25 12:30:50'),
  (38, 38, 248.200, 20.000, '2026-09-24 16:37:06'),
  (39, 39, 101.100, 15.000, '2026-09-24 16:37:06'),
  (40, 40, 247.000, 5.000, '2026-10-13 02:12:05'),
  (41, 41, 8.000, 15.000, '2026-10-31 04:11:49'),
  (42, 42, 410.000, 5.000, '2026-10-25 14:45:56'),
  (43, 43, 113.000, 10.000, '2026-10-25 14:45:56'),
  (44, 44, 191.000, 5.000, '2026-10-25 14:45:56'),
  (45, 45, 285.000, 5.000, '2026-10-25 14:45:56'),
  (46, 46, 81.000, 5.000, '2026-10-11 01:49:21'),
  (47, 47, 416.000, 10.000, '2026-10-26 18:56:42'),
  (48, 48, 184.000, 5.000, '2026-10-26 18:56:42'),
  (49, 49, 232.000, 15.000, '2026-10-26 18:56:42'),
  (50, 50, 143.000, 20.000, '2026-10-18 11:45:24'),
  (51, 51, 113.000, 5.000, '2026-10-17 06:23:27'),
  (52, 52, 375.000, 20.000, '2026-10-19 10:31:13'),
  (53, 53, 77.000, 10.000, '2026-10-19 17:24:26'),
  (54, 54, 373.000, 15.000, '2026-09-29 14:09:40'),
  (55, 55, 241.000, 5.000, '2026-10-09 16:27:59'),
  (56, 56, 95.000, 15.000, '2026-09-30 13:09:01'),
  (57, 57, 41.000, 5.000, '2026-10-23 22:04:59'),
  (58, 58, 125.000, 15.000, '2026-09-22 19:25:57'),
  (59, 59, 130.000, 10.000, '2026-10-04 11:06:33'),
  (60, 60, 132.000, 15.000, '2026-09-29 14:09:40');

-- PEDIDO
INSERT INTO PEDIDO (id_pedido, id_cliente, data_hora, canal_pedido, tipo_entrega, endereco_entrega, data_entrega, valor_total, status_pedido) VALUES
  (1, 3, '2026-07-02 14:22:46', 'WHATSAPP', 'ENTREGA', 'Rua das Acácias, 100 - Artur Alvim, São Paulo/SP, CEP 03876-192', '2026-07-05 17:22:46', 168.90, 'ENTREGUE'),
  (2, 22, '2026-07-03 14:32:03', 'WHATSAPP', 'RETIRADA', NULL, '2026-07-05 04:09:03', 540.54, 'ENTREGUE'),
  (3, 17, '2026-07-04 10:43:08', 'WHATSAPP', 'RETIRADA', NULL, '2026-07-05 12:45:08', 9.90, 'ENTREGUE'),
  (4, NULL, '2026-07-04 12:25:40', 'LOJA', 'RETIRADA', NULL, '2026-07-05 03:08:40', 12.60, 'ENTREGUE'),
  (5, 23, '2026-07-04 17:44:32', 'WHATSAPP', 'ENTREGA', 'Avenida Central, 857 - Vila Aricanduva, São Paulo/SP, CEP 03170-187', '2026-07-08 17:37:32', 347.10, 'ENTREGUE'),
  (6, 26, '2026-07-06 10:41:28', 'LOJA', 'ENTREGA', 'Avenida dos Andradas, 908 - Vila Esperança, São Paulo/SP, CEP 03943-544', '2026-07-08 16:34:28', 1383.82, 'ENTREGUE'),
  (7, NULL, '2026-07-06 10:55:20', 'LOJA', 'RETIRADA', NULL, '2026-07-07 06:42:20', 38.90, 'ENTREGUE'),
  (8, NULL, '2026-07-06 12:40:33', 'LOJA', 'RETIRADA', NULL, '2026-07-07 10:13:33', 474.50, 'ENTREGUE'),
  (9, 25, '2026-07-06 12:46:09', 'LOJA', 'ENTREGA', 'Rua das Hortênsias, 505 - Vila Matilde, São Paulo/SP, CEP 03811-855', '2026-07-11 08:47:09', 1103.80, 'ENTREGUE'),
  (10, 30, '2026-07-06 14:36:33', 'WHATSAPP', 'ENTREGA', 'Rua dos Ipês, 429 - Artur Alvim, São Paulo/SP, CEP 03412-296', '2026-07-09 23:29:33', 685.90, 'ENTREGUE'),
  (11, 5, '2026-07-06 16:19:02', 'WHATSAPP', 'ENTREGA', 'Rua das Palmeiras, 827 - Cangaíba, São Paulo/SP, CEP 03562-850', '2026-07-09 00:25:02', 97.42, 'ENTREGUE'),
  (12, 8, '2026-07-06 17:02:04', 'LOJA', 'ENTREGA', 'Rua das Acácias, 452 - Vila Ré, São Paulo/SP, CEP 03268-030', '2026-07-11 12:17:04', 702.20, 'ENTREGUE'),
  (13, 25, '2026-07-07 09:12:40', 'CANAL_VENDA', 'ENTREGA', 'Rua das Hortênsias, 505 - Vila Matilde, São Paulo/SP, CEP 03811-855', '2026-07-12 11:28:40', 1838.00, 'ENTREGUE'),
  (14, 23, '2026-07-08 08:41:13', 'LOJA', 'RETIRADA', NULL, '2026-07-08 16:53:13', 250.80, 'ENTREGUE'),
  (15, NULL, '2026-07-08 10:08:39', 'LOJA', 'RETIRADA', NULL, '2026-07-09 15:42:39', 1665.40, 'ENTREGUE'),
  (16, NULL, '2026-07-08 12:47:25', 'LOJA', 'RETIRADA', NULL, '2026-07-08 23:52:25', 62.40, 'ENTREGUE'),
  (17, NULL, '2026-07-09 10:47:12', 'LOJA', 'RETIRADA', NULL, '2026-07-10 12:29:12', 345.20, 'ENTREGUE'),
  (18, 15, '2026-07-09 16:57:53', 'WHATSAPP', 'ENTREGA', 'Rua do Comércio, 731 - Vila Matilde, São Paulo/SP, CEP 03128-354', '2026-07-11 14:42:53', 224.70, 'ENTREGUE'),
  (19, NULL, '2026-07-13 16:41:12', 'LOJA', 'RETIRADA', NULL, '2026-07-15 03:23:12', 1372.50, 'ENTREGUE'),
  (20, 36, '2026-07-14 09:10:27', 'LOJA', 'RETIRADA', NULL, '2026-07-15 11:48:27', 3581.70, 'ENTREGUE'),
  (21, NULL, '2026-07-15 16:10:42', 'LOJA', 'RETIRADA', NULL, '2026-07-16 00:01:42', 2618.30, 'ENTREGUE'),
  (22, 1, '2026-07-15 16:25:52', 'LOJA', 'RETIRADA', NULL, '2026-07-16 18:31:52', 277.00, 'ENTREGUE'),
  (23, 30, '2026-07-16 14:51:47', 'LOJA', 'RETIRADA', NULL, '2026-07-18 04:43:47', 229.50, 'ENTREGUE'),
  (24, 11, '2026-07-17 09:34:55', 'WHATSAPP', 'ENTREGA', 'Rua das Palmeiras, 636 - Vila Aricanduva, São Paulo/SP, CEP 03333-628', '2026-07-19 03:09:55', 365.10, 'ENTREGUE'),
  (25, 17, '2026-07-17 17:11:41', 'WHATSAPP', 'ENTREGA', 'Rua São Jorge, 11 - Vila Matilde, São Paulo/SP, CEP 03722-126', '2026-07-20 04:06:41', 49.80, 'ENTREGUE'),
  (26, 2, '2026-07-18 12:29:14', 'WHATSAPP', 'ENTREGA', 'Rua São Jorge, 711 - Vila Aricanduva, São Paulo/SP, CEP 03832-234', '2026-07-21 20:51:14', 1606.20, 'ENTREGUE'),
  (27, 2, '2026-07-18 17:35:27', 'WHATSAPP', 'RETIRADA', NULL, '2026-07-19 07:59:27', 179.40, 'ENTREGUE'),
  (28, NULL, '2026-07-20 16:42:53', 'LOJA', 'RETIRADA', NULL, '2026-07-21 15:25:53', 421.80, 'ENTREGUE'),
  (29, 20, '2026-07-20 17:37:07', 'LOJA', 'RETIRADA', NULL, '2026-07-22 11:15:07', 6.84, 'ENTREGUE'),
  (30, 11, '2026-07-22 14:06:53', 'WHATSAPP', 'ENTREGA', 'Rua das Palmeiras, 636 - Vila Aricanduva, São Paulo/SP, CEP 03333-628', '2026-07-26 21:02:53', 272.30, 'ENTREGUE'),
  (31, 2, '2026-07-23 09:46:51', 'WHATSAPP', 'ENTREGA', 'Rua São Jorge, 711 - Vila Aricanduva, São Paulo/SP, CEP 03832-234', '2026-07-27 22:21:51', 1611.70, 'ENTREGUE'),
  (32, NULL, '2026-07-23 09:54:22', 'LOJA', 'RETIRADA', NULL, '2026-07-24 12:20:22', 161.10, 'ENTREGUE'),
  (33, NULL, '2026-07-23 11:44:04', 'LOJA', 'RETIRADA', NULL, '2026-07-24 02:27:04', 10.26, 'ENTREGUE'),
  (34, NULL, '2026-07-23 15:33:49', 'LOJA', 'RETIRADA', NULL, '2026-07-24 07:49:49', 4114.40, 'ENTREGUE'),
  (35, 5, '2026-07-24 08:27:40', 'LOJA', 'ENTREGA', 'Rua das Palmeiras, 827 - Cangaíba, São Paulo/SP, CEP 03562-850', '2026-07-26 19:18:40', 1631.40, 'ENTREGUE'),
  (36, 1, '2026-07-24 09:24:49', 'LOJA', 'RETIRADA', NULL, '2026-07-25 06:16:49', 109.50, 'ENTREGUE'),
  (37, 25, '2026-07-27 10:40:55', 'WHATSAPP', 'ENTREGA', 'Rua das Hortênsias, 505 - Vila Matilde, São Paulo/SP, CEP 03811-855', '2026-07-30 01:20:55', 2786.50, 'ENTREGUE'),
  (38, 25, '2026-07-27 10:50:30', 'LOJA', 'RETIRADA', NULL, NULL, 242.70, 'CANCELADO'),
  (39, 5, '2026-07-27 11:39:59', 'LOJA', 'ENTREGA', 'Rua das Palmeiras, 827 - Cangaíba, São Paulo/SP, CEP 03562-850', '2026-07-31 12:39:59', 1192.20, 'ENTREGUE'),
  (40, 11, '2026-07-27 15:07:51', 'LOJA', 'RETIRADA', NULL, '2026-07-28 13:21:51', 368.40, 'ENTREGUE'),
  (41, 14, '2026-07-27 15:48:41', 'WHATSAPP', 'ENTREGA', 'Rua São Jorge, 656 - Ponte Rasa, São Paulo/SP, CEP 03268-292', '2026-07-29 09:58:41', 2019.60, 'ENTREGUE'),
  (42, NULL, '2026-07-27 16:30:03', 'LOJA', 'RETIRADA', NULL, '2026-07-28 10:59:03', 251.10, 'ENTREGUE'),
  (43, 10, '2026-07-27 16:52:52', 'WHATSAPP', 'ENTREGA', 'Rua das Hortênsias, 478 - Vila Aricanduva, São Paulo/SP, CEP 03169-848', NULL, 169.50, 'CANCELADO'),
  (44, 18, '2026-07-28 14:34:27', 'CANAL_VENDA', 'ENTREGA', 'Rua das Palmeiras, 905 - Cangaíba, São Paulo/SP, CEP 03956-210', '2026-07-30 05:31:27', 2533.20, 'ENTREGUE'),
  (45, 7, '2026-07-28 16:21:54', 'LOJA', 'ENTREGA', 'Avenida dos Andradas, 724 - Artur Alvim, São Paulo/SP, CEP 03511-693', '2026-08-02 08:06:54', 545.50, 'ENTREGUE'),
  (46, 21, '2026-07-29 08:19:53', 'LOJA', 'ENTREGA', 'Rua das Palmeiras, 388 - Vila Esperança, São Paulo/SP, CEP 03224-359', '2026-08-03 05:13:53', 2297.00, 'ENTREGUE'),
  (47, NULL, '2026-07-29 11:23:31', 'LOJA', 'RETIRADA', NULL, '2026-07-31 06:59:31', 1124.50, 'ENTREGUE'),
  (48, 27, '2026-07-31 13:18:52', 'LOJA', 'ENTREGA', 'Rua das Acácias, 976 - Cangaíba, São Paulo/SP, CEP 03730-379', '2026-08-02 18:34:52', 367.80, 'ENTREGUE'),
  (49, 8, '2026-07-31 17:01:40', 'CANAL_VENDA', 'ENTREGA', 'Rua das Acácias, 452 - Vila Ré, São Paulo/SP, CEP 03268-030', '2026-08-05 04:09:40', 2695.00, 'ENTREGUE'),
  (50, NULL, '2026-08-01 11:56:46', 'LOJA', 'RETIRADA', NULL, '2026-08-02 07:58:46', 1639.00, 'ENTREGUE'),
  (51, 23, '2026-08-01 12:33:34', 'LOJA', 'RETIRADA', NULL, '2026-08-02 08:30:34', 229.00, 'ENTREGUE'),
  (52, 6, '2026-08-01 16:08:33', 'WHATSAPP', 'RETIRADA', NULL, '2026-08-01 23:06:33', 441.60, 'ENTREGUE'),
  (53, 9, '2026-08-01 16:53:51', 'CANAL_VENDA', 'ENTREGA', 'Rua Santa Clara, 928 - Vila Matilde, São Paulo/SP, CEP 03387-340', NULL, 1345.30, 'COM_OCORRENCIA'),
  (54, NULL, '2026-08-03 11:03:12', 'LOJA', 'RETIRADA', NULL, '2026-08-05 00:45:12', 1609.60, 'ENTREGUE'),
  (55, 31, '2026-08-03 12:24:30', 'WHATSAPP', 'ENTREGA', 'Rua das Acácias, 667 - Vila Aricanduva, São Paulo/SP, CEP 03294-835', '2026-08-05 02:51:30', 470.00, 'ENTREGUE'),
  (56, 4, '2026-08-03 12:30:47', 'WHATSAPP', 'RETIRADA', NULL, NULL, 1259.00, 'COM_OCORRENCIA'),
  (57, NULL, '2026-08-03 16:14:26', 'LOJA', 'RETIRADA', NULL, '2026-08-04 22:48:26', 6203.55, 'ENTREGUE'),
  (58, NULL, '2026-08-04 15:06:32', 'LOJA', 'RETIRADA', NULL, '2026-08-06 05:36:32', 306.00, 'ENTREGUE'),
  (59, 21, '2026-08-06 08:29:43', 'LOJA', 'ENTREGA', 'Rua das Palmeiras, 388 - Vila Esperança, São Paulo/SP, CEP 03224-359', '2026-08-09 16:41:43', 100.30, 'ENTREGUE'),
  (60, NULL, '2026-08-07 13:49:52', 'LOJA', 'RETIRADA', NULL, '2026-08-08 08:46:52', 680.90, 'ENTREGUE');
INSERT INTO PEDIDO (id_pedido, id_cliente, data_hora, canal_pedido, tipo_entrega, endereco_entrega, data_entrega, valor_total, status_pedido) VALUES
  (61, NULL, '2026-08-07 14:49:11', 'LOJA', 'RETIRADA', NULL, '2026-08-08 16:24:11', 135.90, 'ENTREGUE'),
  (62, 29, '2026-08-08 16:18:16', 'LOJA', 'RETIRADA', NULL, '2026-08-09 20:10:16', 74.70, 'ENTREGUE'),
  (63, 1, '2026-08-10 10:58:18', 'LOJA', 'RETIRADA', NULL, '2026-08-11 20:12:18', 255.80, 'ENTREGUE'),
  (64, 3, '2026-08-10 12:24:26', 'CANAL_VENDA', 'ENTREGA', 'Rua das Acácias, 100 - Artur Alvim, São Paulo/SP, CEP 03876-192', '2026-08-14 08:08:26', 338.00, 'ENTREGUE'),
  (65, 27, '2026-08-10 12:47:24', 'LOJA', 'RETIRADA', NULL, '2026-08-11 12:34:24', 3.80, 'ENTREGUE'),
  (66, NULL, '2026-08-10 17:20:48', 'LOJA', 'RETIRADA', NULL, '2026-08-11 14:40:48', 2952.00, 'ENTREGUE'),
  (67, 5, '2026-08-11 16:50:01', 'LOJA', 'ENTREGA', 'Rua das Palmeiras, 827 - Cangaíba, São Paulo/SP, CEP 03562-850', '2026-08-16 10:35:01', 1505.40, 'ENTREGUE'),
  (68, 22, '2026-08-12 12:07:23', 'LOJA', 'ENTREGA', 'Rua do Comércio, 214 - Vila Esperança, São Paulo/SP, CEP 03071-057', '2026-08-15 13:11:23', 5592.00, 'ENTREGUE'),
  (69, 17, '2026-08-12 17:39:00', 'WHATSAPP', 'ENTREGA', 'Rua São Jorge, 11 - Vila Matilde, São Paulo/SP, CEP 03722-126', '2026-08-15 11:22:00', 1356.00, 'ENTREGUE'),
  (70, 13, '2026-08-14 11:37:23', 'WHATSAPP', 'ENTREGA', 'Rua das Palmeiras, 101 - Vila Esperança, São Paulo/SP, CEP 03730-687', '2026-08-19 03:27:23', 1875.00, 'ENTREGUE'),
  (71, 37, '2026-08-15 08:06:09', 'CANAL_VENDA', 'ENTREGA', 'Rua Bela Vista, 336 - Artur Alvim, São Paulo/SP, CEP 03030-209', '2026-08-16 19:32:09', 517.00, 'ENTREGUE'),
  (72, 7, '2026-08-17 08:22:28', 'LOJA', 'ENTREGA', 'Avenida dos Andradas, 724 - Artur Alvim, São Paulo/SP, CEP 03511-693', '2026-08-19 01:19:28', 3545.00, 'ENTREGUE'),
  (73, NULL, '2026-08-17 08:48:22', 'LOJA', 'RETIRADA', NULL, '2026-08-18 13:40:22', 2270.00, 'ENTREGUE'),
  (74, 29, '2026-08-18 11:21:01', 'WHATSAPP', 'ENTREGA', 'Rua Santa Clara, 106 - Vila Aricanduva, São Paulo/SP, CEP 03844-691', '2026-08-19 17:10:01', 2601.50, 'ENTREGUE'),
  (75, NULL, '2026-08-20 08:00:25', 'LOJA', 'RETIRADA', NULL, '2026-08-21 10:39:25', 11.97, 'ENTREGUE'),
  (76, NULL, '2026-08-20 13:36:31', 'LOJA', 'RETIRADA', NULL, '2026-08-22 07:02:31', 77.40, 'ENTREGUE'),
  (77, 7, '2026-08-21 11:10:02', 'LOJA', 'ENTREGA', 'Avenida dos Andradas, 724 - Artur Alvim, São Paulo/SP, CEP 03511-693', '2026-08-23 08:29:02', 343.40, 'ENTREGUE'),
  (78, 16, '2026-08-21 17:21:13', 'WHATSAPP', 'ENTREGA', 'Rua São Jorge, 148 - Ponte Rasa, São Paulo/SP, CEP 03472-245', '2026-08-23 03:47:13', 149.50, 'ENTREGUE'),
  (79, 20, '2026-08-21 17:42:10', 'LOJA', 'RETIRADA', NULL, '2026-08-23 14:26:10', 1853.40, 'ENTREGUE'),
  (80, 25, '2026-08-26 11:07:36', 'WHATSAPP', 'RETIRADA', NULL, '2026-08-27 14:35:36', 3688.20, 'ENTREGUE'),
  (81, 16, '2026-08-26 12:43:41', 'WHATSAPP', 'ENTREGA', 'Rua São Jorge, 148 - Ponte Rasa, São Paulo/SP, CEP 03472-245', '2026-08-29 20:54:41', 465.90, 'ENTREGUE'),
  (82, NULL, '2026-08-27 11:52:51', 'LOJA', 'RETIRADA', NULL, '2026-08-27 19:10:51', 883.40, 'ENTREGUE'),
  (83, 28, '2026-08-29 12:28:25', 'WHATSAPP', 'ENTREGA', 'Rua São Jorge, 900 - Ponte Rasa, São Paulo/SP, CEP 03412-478', '2026-09-01 10:58:25', 937.50, 'ENTREGUE'),
  (84, 28, '2026-08-31 14:24:07', 'WHATSAPP', 'ENTREGA', 'Rua São Jorge, 900 - Ponte Rasa, São Paulo/SP, CEP 03412-478', '2026-09-05 04:56:07', 4172.60, 'ENTREGUE'),
  (85, NULL, '2026-08-31 17:03:07', 'LOJA', 'RETIRADA', NULL, '2026-09-02 01:28:07', 928.48, 'ENTREGUE'),
  (86, 4, '2026-09-01 10:39:51', 'WHATSAPP', 'ENTREGA', 'Rua São Jorge, 923 - Cangaíba, São Paulo/SP, CEP 03909-507', '2026-09-04 18:18:51', 124.50, 'ENTREGUE'),
  (87, 35, '2026-09-02 13:21:18', 'WHATSAPP', 'ENTREGA', 'Rua Bela Vista, 948 - Penha, São Paulo/SP, CEP 03426-944', '2026-09-04 23:46:18', 128.70, 'ENTREGUE'),
  (88, NULL, '2026-09-03 11:19:29', 'LOJA', 'RETIRADA', NULL, NULL, 317.94, 'CANCELADO'),
  (89, NULL, '2026-09-04 15:51:54', 'LOJA', 'RETIRADA', NULL, '2026-09-05 23:37:54', 1596.30, 'ENTREGUE'),
  (90, 15, '2026-09-05 09:42:57', 'LOJA', 'ENTREGA', 'Rua do Comércio, 731 - Vila Matilde, São Paulo/SP, CEP 03128-354', '2026-09-09 19:38:57', 484.20, 'ENTREGUE'),
  (91, NULL, '2026-09-05 10:12:13', 'LOJA', 'RETIRADA', NULL, '2026-09-06 07:49:13', 558.10, 'ENTREGUE'),
  (92, 3, '2026-09-07 16:36:24', 'CANAL_VENDA', 'ENTREGA', 'Rua das Acácias, 100 - Artur Alvim, São Paulo/SP, CEP 03876-192', '2026-09-09 07:04:24', 1752.00, 'ENTREGUE'),
  (93, 8, '2026-09-08 10:35:31', 'LOJA', 'RETIRADA', NULL, '2026-09-09 13:26:31', 2058.04, 'ENTREGUE'),
  (94, 10, '2026-09-09 15:45:17', 'LOJA', 'ENTREGA', 'Rua das Hortênsias, 478 - Vila Aricanduva, São Paulo/SP, CEP 03169-848', '2026-09-13 04:11:17', 123.00, 'ENTREGUE'),
  (95, 11, '2026-09-09 16:11:56', 'LOJA', 'RETIRADA', NULL, '2026-09-10 06:33:56', 1672.30, 'ENTREGUE'),
  (96, 23, '2026-09-10 09:02:19', 'WHATSAPP', 'ENTREGA', 'Avenida Central, 857 - Vila Aricanduva, São Paulo/SP, CEP 03170-187', NULL, 274.00, 'COM_OCORRENCIA'),
  (97, 31, '2026-09-10 09:28:27', 'LOJA', 'ENTREGA', 'Rua das Acácias, 667 - Vila Aricanduva, São Paulo/SP, CEP 03294-835', '2026-09-12 07:10:27', 2599.70, 'ENTREGUE'),
  (98, 31, '2026-09-10 11:20:38', 'LOJA', 'RETIRADA', NULL, '2026-09-11 16:49:38', 901.70, 'ENTREGUE'),
  (99, NULL, '2026-09-10 13:38:26', 'LOJA', 'RETIRADA', NULL, '2026-09-11 19:51:26', 3489.50, 'ENTREGUE'),
  (100, 22, '2026-09-11 11:31:14', 'CANAL_VENDA', 'ENTREGA', 'Rua do Comércio, 214 - Vila Esperança, São Paulo/SP, CEP 03071-057', '2026-09-14 18:59:14', 467.83, 'ENTREGUE'),
  (101, NULL, '2026-09-11 14:30:56', 'LOJA', 'RETIRADA', NULL, '2026-09-12 00:04:56', 732.00, 'ENTREGUE'),
  (102, NULL, '2026-09-12 08:21:23', 'LOJA', 'RETIRADA', NULL, '2026-09-12 18:30:23', 2431.20, 'ENTREGUE'),
  (103, 31, '2026-09-12 11:55:02', 'WHATSAPP', 'ENTREGA', 'Rua das Acácias, 667 - Vila Aricanduva, São Paulo/SP, CEP 03294-835', NULL, 224.00, 'CANCELADO'),
  (104, NULL, '2026-09-14 08:29:12', 'LOJA', 'RETIRADA', NULL, '2026-09-15 06:36:12', 556.00, 'ENTREGUE'),
  (105, 8, '2026-09-14 12:46:00', 'LOJA', 'RETIRADA', NULL, '2026-09-14 18:53:00', 4.41, 'ENTREGUE'),
  (106, 8, '2026-09-18 10:52:45', 'LOJA', 'RETIRADA', NULL, '2026-09-20 06:10:45', 977.70, 'ENTREGUE'),
  (107, NULL, '2026-09-18 13:47:15', 'LOJA', 'RETIRADA', NULL, '2026-09-19 10:26:15', 149.50, 'ENTREGUE'),
  (108, 18, '2026-09-18 14:07:49', 'WHATSAPP', 'ENTREGA', 'Rua das Palmeiras, 905 - Cangaíba, São Paulo/SP, CEP 03956-210', '2026-09-23 03:16:49', 4299.36, 'ENTREGUE'),
  (109, 17, '2026-09-19 13:23:15', 'CANAL_VENDA', 'ENTREGA', 'Rua São Jorge, 11 - Vila Matilde, São Paulo/SP, CEP 03722-126', NULL, 961.20, 'CANCELADO'),
  (110, 23, '2026-09-21 16:09:48', 'WHATSAPP', 'ENTREGA', 'Avenida Central, 857 - Vila Aricanduva, São Paulo/SP, CEP 03170-187', '2026-09-25 00:09:48', 2247.50, 'ENTREGUE'),
  (111, 30, '2026-09-21 17:43:53', 'LOJA', 'RETIRADA', NULL, '2026-09-22 19:44:53', 75.00, 'ENTREGUE'),
  (112, 4, '2026-09-22 11:25:57', 'LOJA', 'ENTREGA', 'Rua São Jorge, 923 - Cangaíba, São Paulo/SP, CEP 03909-507', '2026-09-24 19:25:57', 2128.50, 'ENTREGUE'),
  (113, 23, '2026-09-24 10:07:40', 'WHATSAPP', 'RETIRADA', NULL, '2026-09-25 05:45:40', 137.50, 'ENTREGUE'),
  (114, 27, '2026-09-24 10:14:05', 'LOJA', 'RETIRADA', NULL, NULL, 72.50, 'CANCELADO'),
  (115, NULL, '2026-09-25 16:45:19', 'LOJA', 'RETIRADA', NULL, '2026-09-26 09:49:19', 689.10, 'ENTREGUE'),
  (116, 31, '2026-09-28 10:12:04', 'LOJA', 'RETIRADA', NULL, '2026-09-29 12:01:04', 1877.20, 'ENTREGUE'),
  (117, NULL, '2026-09-28 13:47:38', 'LOJA', 'RETIRADA', NULL, '2026-09-29 23:28:38', 434.40, 'ENTREGUE'),
  (118, 20, '2026-09-29 10:40:48', 'WHATSAPP', 'RETIRADA', NULL, '2026-09-30 01:01:48', 558.60, 'ENTREGUE'),
  (119, 34, '2026-09-29 11:01:46', 'LOJA', 'RETIRADA', NULL, '2026-09-30 16:32:46', 3649.20, 'ENTREGUE'),
  (120, 11, '2026-09-29 11:12:40', 'LOJA', 'RETIRADA', NULL, '2026-09-30 06:09:40', 1316.26, 'ENTREGUE');
INSERT INTO PEDIDO (id_pedido, id_cliente, data_hora, canal_pedido, tipo_entrega, endereco_entrega, data_entrega, valor_total, status_pedido) VALUES
  (121, 24, '2026-09-29 11:30:55', 'WHATSAPP', 'ENTREGA', 'Avenida Central, 401 - Vila Aricanduva, São Paulo/SP, CEP 03895-934', '2026-10-04 03:32:55', 339.30, 'ENTREGUE'),
  (122, NULL, '2026-09-29 12:40:24', 'LOJA', 'RETIRADA', NULL, NULL, 4198.50, 'CANCELADO'),
  (123, 18, '2026-09-29 17:35:01', 'WHATSAPP', 'ENTREGA', 'Rua das Palmeiras, 905 - Cangaíba, São Paulo/SP, CEP 03956-210', '2026-10-03 14:09:01', 825.00, 'ENTREGUE'),
  (124, 34, '2026-09-30 09:12:16', 'CANAL_VENDA', 'ENTREGA', 'Avenida dos Andradas, 62 - Penha, São Paulo/SP, CEP 03618-399', '2026-10-03 17:11:16', 2942.90, 'ENTREGUE'),
  (125, 7, '2026-09-30 15:10:52', 'LOJA', 'RETIRADA', NULL, '2026-10-02 12:09:52', 1192.00, 'ENTREGUE'),
  (126, NULL, '2026-10-02 09:15:29', 'LOJA', 'RETIRADA', NULL, '2026-10-03 10:27:29', 122.50, 'ENTREGUE'),
  (127, 29, '2026-10-02 12:39:47', 'CANAL_VENDA', 'ENTREGA', 'Rua Santa Clara, 106 - Vila Aricanduva, São Paulo/SP, CEP 03844-691', '2026-10-06 03:53:47', 1142.34, 'ENTREGUE'),
  (128, 12, '2026-10-02 13:34:19', 'WHATSAPP', 'ENTREGA', 'Avenida dos Andradas, 405 - Ponte Rasa, São Paulo/SP, CEP 03641-841', '2026-10-04 07:50:19', 3319.30, 'ENTREGUE'),
  (129, 38, '2026-10-03 11:46:10', 'LOJA', 'ENTREGA', 'Rua Santa Clara, 562 - Vila Matilde, São Paulo/SP, CEP 03763-669', '2026-10-05 11:35:10', 1899.00, 'ENTREGUE'),
  (130, 11, '2026-10-03 12:07:20', 'LOJA', 'RETIRADA', NULL, '2026-10-04 16:18:20', 154.80, 'ENTREGUE'),
  (131, 13, '2026-10-03 16:31:33', 'WHATSAPP', 'ENTREGA', 'Rua das Palmeiras, 101 - Vila Esperança, São Paulo/SP, CEP 03730-687', '2026-10-06 12:06:33', 1239.50, 'ENTREGUE'),
  (132, 3, '2026-10-05 12:26:08', 'LOJA', 'ENTREGA', 'Rua das Acácias, 100 - Artur Alvim, São Paulo/SP, CEP 03876-192', '2026-10-07 04:44:08', 1830.00, 'ENTREGUE'),
  (133, 38, '2026-10-05 14:11:49', 'LOJA', 'RETIRADA', NULL, '2026-10-06 18:58:49', 2863.50, 'ENTREGUE'),
  (134, NULL, '2026-10-05 15:13:58', 'LOJA', 'RETIRADA', NULL, '2026-10-06 18:13:58', 3214.70, 'ENTREGUE'),
  (135, 3, '2026-10-07 09:18:28', 'WHATSAPP', 'ENTREGA', 'Rua das Acácias, 100 - Artur Alvim, São Paulo/SP, CEP 03876-192', '2026-10-10 07:54:28', 1367.80, 'ENTREGUE'),
  (136, 30, '2026-10-07 13:00:53', 'CANAL_VENDA', 'ENTREGA', 'Rua dos Ipês, 429 - Artur Alvim, São Paulo/SP, CEP 03412-296', '2026-10-12 10:13:53', 556.00, 'ENTREGUE'),
  (137, 22, '2026-10-08 08:20:42', 'WHATSAPP', 'ENTREGA', 'Rua do Comércio, 214 - Vila Esperança, São Paulo/SP, CEP 03071-057', '2026-10-12 21:52:42', 38.90, 'ENTREGUE'),
  (138, NULL, '2026-10-08 15:02:54', 'LOJA', 'RETIRADA', NULL, '2026-10-10 14:29:54', 449.55, 'ENTREGUE'),
  (139, 20, '2026-10-09 11:35:59', 'WHATSAPP', 'RETIRADA', NULL, '2026-10-10 17:27:59', 784.80, 'ENTREGUE'),
  (140, NULL, '2026-10-09 17:10:50', 'LOJA', 'RETIRADA', NULL, '2026-10-10 12:11:50', 1895.60, 'ENTREGUE'),
  (141, 7, '2026-10-10 08:23:38', 'LOJA', 'RETIRADA', NULL, '2026-10-11 17:49:38', 475.42, 'ENTREGUE'),
  (142, NULL, '2026-10-10 15:50:21', 'LOJA', 'RETIRADA', NULL, '2026-10-11 03:49:21', 588.90, 'ENTREGUE'),
  (143, 23, '2026-10-12 10:39:26', 'LOJA', 'ENTREGA', 'Avenida Central, 857 - Vila Aricanduva, São Paulo/SP, CEP 03170-187', '2026-10-13 18:50:26', 353.14, 'ENTREGUE'),
  (144, 28, '2026-10-12 12:04:39', 'WHATSAPP', 'RETIRADA', NULL, '2026-10-13 12:02:39', 390.60, 'ENTREGUE'),
  (145, 8, '2026-10-12 12:06:24', 'WHATSAPP', 'ENTREGA', 'Rua das Acácias, 452 - Vila Ré, São Paulo/SP, CEP 03268-030', '2026-10-16 02:38:24', 343.20, 'ENTREGUE'),
  (146, 2, '2026-10-12 12:37:20', 'WHATSAPP', 'ENTREGA', 'Rua São Jorge, 711 - Vila Aricanduva, São Paulo/SP, CEP 03832-234', '2026-10-13 23:11:20', 292.80, 'ENTREGUE'),
  (147, 7, '2026-10-12 14:24:29', 'LOJA', 'RETIRADA', NULL, '2026-10-13 16:43:29', 1579.20, 'ENTREGUE'),
  (148, 20, '2026-10-12 15:19:06', 'WHATSAPP', 'ENTREGA', 'Rua dos Ipês, 89 - Vila Matilde, São Paulo/SP, CEP 03912-581', '2026-10-15 21:28:06', 327.20, 'ENTREGUE'),
  (149, 23, '2026-10-12 15:24:05', 'WHATSAPP', 'ENTREGA', 'Avenida Central, 857 - Vila Aricanduva, São Paulo/SP, CEP 03170-187', '2026-10-16 05:12:05', 1819.77, 'ENTREGUE'),
  (150, 16, '2026-10-12 16:55:16', 'LOJA', 'RETIRADA', NULL, '2026-10-13 05:09:16', 151.80, 'ENTREGUE'),
  (151, 10, '2026-10-13 12:35:36', 'LOJA', 'RETIRADA', NULL, '2026-10-14 00:54:36', 549.00, 'ENTREGUE'),
  (152, 31, '2026-10-13 15:11:01', 'LOJA', 'RETIRADA', NULL, '2026-10-14 19:05:01', 352.00, 'ENTREGUE'),
  (153, 31, '2026-10-13 15:26:20', 'CANAL_VENDA', 'ENTREGA', 'Rua das Acácias, 667 - Vila Aricanduva, São Paulo/SP, CEP 03294-835', '2026-10-16 20:01:20', 499.00, 'ENTREGUE'),
  (154, 4, '2026-10-16 15:24:27', 'CANAL_VENDA', 'ENTREGA', 'Rua São Jorge, 923 - Cangaíba, São Paulo/SP, CEP 03909-507', '2026-10-21 11:23:27', 339.00, 'ENTREGUE'),
  (155, NULL, '2026-10-17 11:34:11', 'LOJA', 'RETIRADA', NULL, '2026-10-18 22:40:11', 558.50, 'ENTREGUE'),
  (156, NULL, '2026-10-17 11:42:27', 'LOJA', 'RETIRADA', NULL, '2026-10-18 10:07:27', 74.70, 'ENTREGUE'),
  (157, 29, '2026-10-17 12:08:13', 'WHATSAPP', 'ENTREGA', 'Rua Santa Clara, 106 - Vila Aricanduva, São Paulo/SP, CEP 03844-691', '2026-10-18 20:07:13', 408.00, 'ENTREGUE'),
  (158, 1, '2026-10-17 14:19:24', 'CANAL_VENDA', 'ENTREGA', 'Avenida Central, 754 - Vila Esperança, São Paulo/SP, CEP 03528-535', '2026-10-20 16:45:24', 337.18, 'ENTREGUE'),
  (159, 37, '2026-10-19 10:55:54', 'WHATSAPP', 'ENTREGA', 'Rua Bela Vista, 336 - Artur Alvim, São Paulo/SP, CEP 03030-209', '2026-10-22 19:23:54', 1249.50, 'ENTREGUE'),
  (160, NULL, '2026-10-19 14:22:26', 'LOJA', 'RETIRADA', NULL, '2026-10-19 19:24:26', 3202.00, 'ENTREGUE'),
  (161, 2, '2026-10-19 15:45:15', 'WHATSAPP', 'ENTREGA', 'Rua São Jorge, 711 - Vila Aricanduva, São Paulo/SP, CEP 03832-234', '2026-10-24 01:44:15', 173.20, 'ENTREGUE'),
  (162, NULL, '2026-10-19 17:07:58', 'LOJA', 'RETIRADA', NULL, '2026-10-20 21:31:58', 104.30, 'ENTREGUE'),
  (163, NULL, '2026-10-20 11:29:28', 'LOJA', 'RETIRADA', NULL, '2026-10-22 08:59:28', 3762.50, 'ENTREGUE'),
  (164, 36, '2026-10-22 09:42:00', 'LOJA', 'ENTREGA', 'Rua das Palmeiras, 306 - Ponte Rasa, São Paulo/SP, CEP 03351-715', NULL, 1098.00, 'CANCELADO'),
  (165, 9, '2026-10-23 08:44:18', 'WHATSAPP', 'ENTREGA', 'Rua Santa Clara, 928 - Vila Matilde, São Paulo/SP, CEP 03387-340', '2026-10-24 19:18:18', 306.00, 'ENTREGUE'),
  (166, 31, '2026-10-23 09:16:59', 'WHATSAPP', 'ENTREGA', 'Rua das Acácias, 667 - Vila Aricanduva, São Paulo/SP, CEP 03294-835', '2026-10-25 02:04:59', 1724.00, 'ENTREGUE'),
  (167, 6, '2026-10-24 12:16:22', 'WHATSAPP', 'ENTREGA', 'Rua das Hortênsias, 605 - Penha, São Paulo/SP, CEP 03960-783', '2026-10-26 14:53:22', 29.70, 'ENTREGUE'),
  (168, 20, '2026-10-24 12:32:59', 'CANAL_VENDA', 'ENTREGA', 'Rua dos Ipês, 89 - Vila Matilde, São Paulo/SP, CEP 03912-581', '2026-10-28 10:24:59', 36.50, 'ENTREGUE'),
  (169, 34, '2026-10-24 17:19:50', 'LOJA', 'ENTREGA', 'Avenida dos Andradas, 62 - Penha, São Paulo/SP, CEP 03618-399', '2026-10-27 12:30:50', 2027.20, 'ENTREGUE'),
  (170, NULL, '2026-10-26 13:53:46', 'LOJA', 'RETIRADA', NULL, '2026-10-27 20:47:46', 1635.10, 'ENTREGUE'),
  (171, 32, '2026-10-26 14:59:57', 'LOJA', 'RETIRADA', NULL, NULL, 1653.30, 'REGISTRADO'),
  (172, 18, '2026-10-27 10:28:25', 'WHATSAPP', 'ENTREGA', 'Rua das Palmeiras, 905 - Cangaíba, São Paulo/SP, CEP 03956-210', NULL, 49.50, 'PAGO'),
  (173, NULL, '2026-10-28 08:06:08', 'LOJA', 'RETIRADA', NULL, NULL, 130.84, 'EM_SEPARACAO'),
  (174, 1, '2026-10-29 10:03:13', 'CANAL_VENDA', 'ENTREGA', 'Avenida Central, 754 - Vila Esperança, São Paulo/SP, CEP 03528-535', NULL, 1814.00, 'EM_SEPARACAO'),
  (175, 38, '2026-10-29 12:27:38', 'LOJA', 'ENTREGA', 'Rua Santa Clara, 562 - Vila Matilde, São Paulo/SP, CEP 03763-669', NULL, 132.00, 'CONFERIDO'),
  (176, 16, '2026-10-30 10:32:23', 'WHATSAPP', 'ENTREGA', 'Rua São Jorge, 148 - Ponte Rasa, São Paulo/SP, CEP 03472-245', NULL, 1605.00, 'ENVIADO'),
  (177, 36, '2026-10-30 11:30:49', 'WHATSAPP', 'ENTREGA', 'Rua das Palmeiras, 306 - Ponte Rasa, São Paulo/SP, CEP 03351-715', NULL, 64.50, 'ENVIADO'),
  (178, NULL, '2026-10-30 12:30:20', 'LOJA', 'RETIRADA', NULL, NULL, 727.90, 'COM_OCORRENCIA'),
  (179, 15, '2026-10-30 13:45:07', 'LOJA', 'RETIRADA', NULL, NULL, 339.90, 'CANCELADO'),
  (180, 3, '2026-10-31 16:36:12', 'WHATSAPP', 'ENTREGA', 'Rua das Acácias, 100 - Artur Alvim, São Paulo/SP, CEP 03876-192', '2026-11-04 02:15:12', 343.20, 'ENTREGUE');

-- ITEM_PEDIDO
INSERT INTO ITEM_PEDIDO (id_item, id_pedido, id_produto, quantidade, preco_unitario) VALUES
  (1, 1, 58, 6.000, 19.00),
  (2, 1, 33, 1.000, 54.90),
  (3, 2, 47, 8.000, 54.90),
  (4, 2, 27, 6.000, 16.50),
  (5, 2, 10, 1.000, 2.34),
  (6, 3, 1, 1.000, 9.90),
  (7, 4, 9, 1.000, 2.60),
  (8, 5, 46, 4.000, 15.90),
  (9, 5, 56, 9.000, 21.00),
  (10, 5, 3, 5.000, 18.90),
  (11, 6, 16, 2.000, 8.91),
  (12, 6, 6, 8.000, 62.00),
  (13, 6, 54, 30.000, 29.00),
  (14, 7, 18, 1.000, 38.90),
  (15, 8, 22, 5.000, 74.90),
  (16, 8, 2, 8.000, 12.50),
  (17, 9, 9, 8.000, 2.60),
  (18, 9, 31, 3.000, 259.00),
  (19, 9, 57, 9.000, 34.00),
  (20, 10, 19, 3.000, 29.90),
  (21, 10, 20, 5.000, 36.50),
  (22, 10, 1, 7.000, 9.90),
  (23, 10, 13, 2.000, 7.50),
  (24, 10, 33, 6.000, 54.90),
  (25, 11, 39, 4.000, 19.90),
  (26, 11, 16, 2.000, 8.91),
  (27, 12, 46, 8.000, 15.90),
  (28, 12, 20, 4.000, 36.50),
  (29, 12, 49, 10.000, 42.90),
  (30, 13, 5, 8.000, 35.50),
  (31, 13, 50, 6.000, 259.00),
  (32, 14, 22, 1.000, 74.90),
  (33, 14, 46, 4.000, 15.90),
  (34, 14, 13, 7.000, 7.50),
  (35, 14, 19, 2.000, 29.90),
  (36, 15, 53, 9.000, 38.00),
  (37, 15, 36, 8.000, 149.00),
  (38, 15, 28, 6.000, 21.90),
  (39, 16, 13, 1.000, 7.50),
  (40, 16, 33, 1.000, 54.90),
  (41, 17, 14, 4.000, 6.75),
  (42, 17, 24, 4.000, 64.90),
  (43, 17, 9, 8.000, 2.60),
  (44, 17, 3, 2.000, 18.90),
  (45, 18, 22, 3.000, 74.90),
  (46, 19, 23, 7.000, 189.00),
  (47, 19, 27, 3.000, 16.50),
  (48, 20, 37, 6.000, 429.00),
  (49, 20, 29, 2.000, 489.00),
  (50, 20, 43, 3.000, 9.90),
  (51, 21, 15, 6.000, 9.90),
  (52, 21, 59, 3.000, 189.00),
  (53, 21, 11, 1.000, 4.90),
  (54, 21, 52, 12.000, 32.00),
  (55, 21, 30, 7.000, 229.00),
  (56, 22, 27, 5.000, 16.50),
  (57, 22, 45, 5.000, 38.90),
  (58, 23, 27, 1.000, 16.50),
  (59, 23, 5, 6.000, 35.50),
  (60, 24, 18, 7.000, 38.90);
INSERT INTO ITEM_PEDIDO (id_item, id_pedido, id_produto, quantidade, preco_unitario) VALUES
  (61, 24, 9, 2.000, 2.60),
  (62, 24, 28, 4.000, 21.90),
  (63, 25, 42, 2.000, 24.90),
  (64, 26, 45, 8.000, 38.90),
  (65, 26, 50, 5.000, 259.00),
  (66, 27, 19, 6.000, 29.90),
  (67, 28, 33, 7.000, 54.90),
  (68, 28, 2, 3.000, 12.50),
  (69, 29, 8, 4.000, 1.71),
  (70, 30, 18, 7.000, 38.90),
  (71, 31, 19, 8.000, 29.90),
  (72, 31, 47, 25.000, 54.90),
  (73, 32, 28, 1.000, 21.90),
  (74, 32, 3, 5.000, 18.90),
  (75, 32, 26, 3.000, 14.90),
  (76, 33, 8, 6.000, 1.71),
  (77, 34, 51, 4.000, 339.00),
  (78, 34, 35, 1.000, 279.00),
  (79, 34, 14, 4.000, 6.75),
  (80, 34, 34, 7.000, 329.00),
  (81, 34, 42, 6.000, 24.90),
  (82, 35, 15, 6.000, 9.90),
  (83, 35, 36, 8.000, 149.00),
  (84, 35, 58, 20.000, 19.00),
  (85, 36, 28, 5.000, 21.90),
  (86, 37, 34, 8.000, 329.00),
  (87, 37, 2, 6.000, 12.50),
  (88, 37, 46, 5.000, 15.90),
  (89, 38, 6, 3.000, 62.00),
  (90, 38, 3, 3.000, 18.90),
  (91, 39, 48, 12.000, 89.90),
  (92, 39, 3, 6.000, 18.90),
  (93, 40, 36, 1.000, 149.00),
  (94, 40, 11, 6.000, 4.90),
  (95, 40, 53, 5.000, 38.00),
  (96, 41, 29, 4.000, 489.00),
  (97, 41, 46, 4.000, 15.90),
  (98, 42, 40, 9.000, 27.90),
  (99, 43, 41, 5.000, 12.90),
  (100, 43, 56, 5.000, 21.00),
  (101, 44, 49, 12.000, 42.90),
  (102, 44, 36, 8.000, 149.00),
  (103, 44, 28, 6.000, 21.90),
  (104, 44, 32, 5.000, 139.00),
  (105, 45, 6, 8.000, 62.00),
  (106, 45, 15, 5.000, 9.90),
  (107, 46, 48, 10.000, 89.90),
  (108, 46, 38, 2.000, 699.00),
  (109, 47, 32, 8.000, 139.00),
  (110, 47, 2, 1.000, 12.50),
  (111, 48, 54, 12.000, 29.00),
  (112, 48, 43, 2.000, 9.90),
  (113, 49, 34, 5.000, 329.00),
  (114, 49, 25, 2.000, 112.00),
  (115, 49, 49, 12.000, 42.90),
  (116, 49, 18, 8.000, 38.90),
  (117, 50, 21, 4.000, 89.90),
  (118, 50, 24, 2.000, 64.90),
  (119, 50, 47, 20.000, 54.90),
  (120, 50, 41, 4.000, 12.90);
INSERT INTO ITEM_PEDIDO (id_item, id_pedido, id_produto, quantidade, preco_unitario) VALUES
  (121, 51, 30, 1.000, 229.00),
  (122, 52, 46, 4.000, 15.90),
  (123, 52, 59, 2.000, 189.00),
  (124, 53, 48, 10.000, 89.90),
  (125, 53, 33, 7.000, 54.90),
  (126, 53, 6, 1.000, 62.00),
  (127, 54, 3, 4.000, 18.90),
  (128, 54, 52, 5.000, 32.00),
  (129, 54, 30, 6.000, 229.00),
  (130, 55, 44, 5.000, 17.90),
  (131, 55, 18, 8.000, 38.90),
  (132, 55, 15, 7.000, 9.90),
  (133, 56, 31, 1.000, 259.00),
  (134, 56, 9, 5.000, 2.60),
  (135, 56, 34, 3.000, 329.00),
  (136, 57, 42, 5.000, 24.90),
  (137, 57, 12, 5.000, 4.41),
  (138, 57, 29, 8.000, 489.00),
  (139, 57, 37, 5.000, 429.00),
  (140, 58, 57, 9.000, 34.00),
  (141, 59, 15, 3.000, 9.90),
  (142, 59, 9, 8.000, 2.60),
  (143, 59, 42, 2.000, 24.90),
  (144, 60, 11, 5.000, 4.90),
  (145, 60, 55, 9.000, 27.00),
  (146, 60, 24, 6.000, 64.90),
  (147, 60, 60, 2.000, 12.00),
  (148, 61, 27, 1.000, 16.50),
  (149, 61, 39, 6.000, 19.90),
  (150, 62, 42, 3.000, 24.90),
  (151, 63, 57, 5.000, 34.00),
  (152, 63, 17, 2.000, 42.90),
  (153, 64, 27, 5.000, 16.50),
  (154, 64, 20, 7.000, 36.50),
  (155, 65, 7, 2.000, 1.90),
  (156, 66, 37, 6.000, 429.00),
  (157, 66, 59, 2.000, 189.00),
  (158, 67, 38, 2.000, 699.00),
  (159, 67, 44, 6.000, 17.90),
  (160, 68, 38, 8.000, 699.00),
  (161, 69, 51, 4.000, 339.00),
  (162, 70, 59, 1.000, 189.00),
  (163, 70, 27, 8.000, 16.50),
  (164, 70, 31, 6.000, 259.00),
  (165, 71, 60, 1.000, 12.00),
  (166, 71, 58, 3.000, 19.00),
  (167, 71, 25, 4.000, 112.00),
  (168, 72, 38, 5.000, 699.00),
  (169, 72, 2, 4.000, 12.50),
  (170, 73, 4, 5.000, 27.90),
  (171, 73, 47, 15.000, 54.90),
  (172, 73, 50, 5.000, 259.00),
  (173, 73, 60, 1.000, 12.00),
  (174, 74, 23, 5.000, 189.00),
  (175, 74, 30, 5.000, 229.00),
  (176, 74, 40, 10.000, 27.90),
  (177, 74, 2, 5.000, 12.50),
  (178, 74, 57, 5.000, 34.00),
  (179, 75, 8, 7.000, 1.71),
  (180, 76, 40, 1.000, 27.90);
INSERT INTO ITEM_PEDIDO (id_item, id_pedido, id_produto, quantidade, preco_unitario) VALUES
  (181, 76, 27, 3.000, 16.50),
  (182, 77, 43, 6.000, 9.90),
  (183, 77, 5, 8.000, 35.50),
  (184, 78, 19, 5.000, 29.90),
  (185, 79, 17, 1.000, 42.90),
  (186, 79, 24, 6.000, 64.90),
  (187, 79, 53, 20.000, 38.00),
  (188, 79, 46, 2.000, 15.90),
  (189, 79, 21, 7.000, 89.90),
  (190, 80, 50, 3.000, 259.00),
  (191, 80, 49, 8.000, 42.90),
  (192, 80, 23, 7.000, 189.00),
  (193, 80, 51, 2.000, 339.00),
  (194, 80, 59, 3.000, 189.00),
  (195, 81, 45, 6.000, 38.90),
  (196, 81, 24, 3.000, 64.90),
  (197, 81, 3, 2.000, 18.90),
  (198, 82, 60, 1.000, 12.00),
  (199, 82, 5, 3.000, 35.50),
  (200, 82, 36, 5.000, 149.00),
  (201, 82, 39, 1.000, 19.90),
  (202, 83, 13, 1.000, 7.50),
  (203, 83, 58, 15.000, 19.00),
  (204, 83, 23, 1.000, 189.00),
  (205, 83, 53, 12.000, 38.00),
  (206, 84, 7, 5.000, 1.90),
  (207, 84, 29, 8.000, 489.00),
  (208, 84, 40, 9.000, 27.90),
  (209, 85, 8, 8.000, 1.71),
  (210, 85, 50, 2.000, 259.00),
  (211, 85, 33, 7.000, 54.90),
  (212, 85, 2, 1.000, 12.50),
  (213, 86, 42, 5.000, 24.90),
  (214, 87, 17, 3.000, 42.90),
  (215, 88, 12, 4.000, 4.41),
  (216, 88, 17, 7.000, 42.90),
  (217, 89, 14, 6.000, 6.75),
  (218, 89, 28, 2.000, 21.90),
  (219, 89, 23, 8.000, 189.00),
  (220, 90, 55, 15.000, 27.00),
  (221, 90, 15, 8.000, 9.90),
  (222, 91, 24, 8.000, 64.90),
  (223, 91, 45, 1.000, 38.90),
  (224, 92, 37, 1.000, 429.00),
  (225, 92, 23, 7.000, 189.00),
  (226, 93, 10, 6.000, 2.34),
  (227, 93, 30, 5.000, 229.00),
  (228, 93, 48, 10.000, 89.90),
  (229, 94, 5, 3.000, 35.50),
  (230, 94, 27, 1.000, 16.50),
  (231, 95, 15, 7.000, 9.90),
  (232, 95, 30, 7.000, 229.00),
  (233, 96, 60, 7.000, 12.00),
  (234, 96, 53, 5.000, 38.00),
  (235, 97, 24, 8.000, 64.90),
  (236, 97, 35, 7.000, 279.00),
  (237, 97, 28, 2.000, 21.90),
  (238, 97, 40, 3.000, 27.90),
  (239, 98, 11, 8.000, 4.90),
  (240, 98, 5, 3.000, 35.50);
INSERT INTO ITEM_PEDIDO (id_item, id_pedido, id_produto, quantidade, preco_unitario) VALUES
  (241, 98, 23, 4.000, 189.00),
  (242, 99, 37, 5.000, 429.00),
  (243, 99, 1, 5.000, 9.90),
  (244, 99, 50, 5.000, 259.00),
  (245, 100, 12, 3.000, 4.41),
  (246, 100, 58, 5.000, 19.00),
  (247, 100, 21, 4.000, 89.90),
  (248, 101, 2, 6.000, 12.50),
  (249, 101, 58, 12.000, 19.00),
  (250, 101, 49, 10.000, 42.90),
  (251, 102, 22, 8.000, 74.90),
  (252, 102, 30, 8.000, 229.00),
  (253, 103, 25, 2.000, 112.00),
  (254, 104, 32, 4.000, 139.00),
  (255, 105, 12, 1.000, 4.41),
  (256, 106, 40, 3.000, 27.90),
  (257, 106, 36, 6.000, 149.00),
  (258, 107, 19, 5.000, 29.90),
  (259, 108, 51, 4.000, 339.00),
  (260, 108, 29, 6.000, 489.00),
  (261, 108, 10, 4.000, 2.34),
  (262, 109, 37, 2.000, 429.00),
  (263, 109, 41, 8.000, 12.90),
  (264, 110, 48, 25.000, 89.90),
  (265, 111, 2, 6.000, 12.50),
  (266, 112, 48, 10.000, 89.90),
  (267, 112, 58, 20.000, 19.00),
  (268, 112, 18, 7.000, 38.90),
  (269, 112, 42, 8.000, 24.90),
  (270, 112, 23, 2.000, 189.00),
  (271, 113, 2, 8.000, 12.50),
  (272, 113, 13, 5.000, 7.50),
  (273, 114, 41, 1.000, 12.90),
  (274, 114, 26, 4.000, 14.90),
  (275, 115, 45, 9.000, 38.90),
  (276, 115, 51, 1.000, 339.00),
  (277, 116, 43, 8.000, 9.90),
  (278, 116, 48, 20.000, 89.90),
  (279, 117, 21, 3.000, 89.90),
  (280, 117, 33, 3.000, 54.90),
  (281, 118, 22, 4.000, 74.90),
  (282, 118, 50, 1.000, 259.00),
  (283, 119, 29, 7.000, 489.00),
  (284, 119, 28, 5.000, 21.90),
  (285, 119, 45, 3.000, 38.90),
  (286, 120, 21, 2.000, 89.90),
  (287, 120, 54, 20.000, 29.00),
  (288, 120, 50, 2.000, 259.00),
  (289, 120, 12, 6.000, 4.41),
  (290, 120, 60, 1.000, 12.00),
  (291, 121, 43, 1.000, 9.90),
  (292, 121, 47, 6.000, 54.90),
  (293, 122, 20, 5.000, 36.50),
  (294, 122, 47, 25.000, 54.90),
  (295, 122, 27, 3.000, 16.50),
  (296, 122, 29, 5.000, 489.00),
  (297, 122, 36, 1.000, 149.00),
  (298, 123, 55, 15.000, 27.00),
  (299, 123, 56, 20.000, 21.00),
  (300, 124, 25, 3.000, 112.00);
INSERT INTO ITEM_PEDIDO (id_item, id_pedido, id_produto, quantidade, preco_unitario) VALUES
  (301, 124, 4, 1.000, 27.90),
  (302, 124, 34, 4.000, 329.00),
  (303, 124, 55, 15.000, 27.00),
  (304, 124, 37, 2.000, 429.00),
  (305, 125, 36, 8.000, 149.00),
  (306, 126, 26, 3.000, 14.90),
  (307, 126, 18, 2.000, 38.90),
  (308, 127, 57, 30.000, 34.00),
  (309, 127, 16, 4.000, 8.91),
  (310, 127, 13, 1.000, 7.50),
  (311, 127, 15, 8.000, 9.90),
  (312, 128, 44, 2.000, 17.90),
  (313, 128, 31, 4.000, 259.00),
  (314, 128, 48, 25.000, 89.90),
  (315, 129, 49, 25.000, 42.90),
  (316, 129, 31, 3.000, 259.00),
  (317, 129, 15, 5.000, 9.90),
  (318, 130, 43, 2.000, 9.90),
  (319, 130, 4, 2.000, 27.90),
  (320, 130, 15, 8.000, 9.90),
  (321, 131, 44, 1.000, 17.90),
  (322, 131, 28, 4.000, 21.90),
  (323, 131, 59, 6.000, 189.00),
  (324, 132, 50, 4.000, 259.00),
  (325, 132, 25, 2.000, 112.00),
  (326, 132, 53, 15.000, 38.00),
  (327, 133, 50, 8.000, 259.00),
  (328, 133, 21, 5.000, 89.90),
  (329, 133, 53, 9.000, 38.00),
  (330, 134, 35, 8.000, 279.00),
  (331, 134, 22, 6.000, 74.90),
  (332, 134, 20, 7.000, 36.50),
  (333, 134, 24, 4.000, 64.90),
  (334, 134, 9, 7.000, 2.60),
  (335, 135, 24, 8.000, 64.90),
  (336, 135, 19, 6.000, 29.90),
  (337, 135, 42, 7.000, 24.90),
  (338, 135, 55, 15.000, 27.00),
  (339, 135, 21, 1.000, 89.90),
  (340, 136, 32, 4.000, 139.00),
  (341, 137, 18, 1.000, 38.90),
  (342, 138, 55, 15.000, 27.00),
  (343, 138, 16, 5.000, 8.91),
  (344, 139, 41, 2.000, 12.90),
  (345, 139, 51, 2.000, 339.00),
  (346, 139, 55, 3.000, 27.00),
  (347, 140, 30, 8.000, 229.00),
  (348, 140, 46, 4.000, 15.90),
  (349, 141, 2, 8.000, 12.50),
  (350, 141, 6, 6.000, 62.00),
  (351, 141, 8, 2.000, 1.71),
  (352, 142, 27, 7.000, 16.50),
  (353, 142, 46, 6.000, 15.90),
  (354, 142, 23, 2.000, 189.00),
  (355, 143, 16, 4.000, 8.91),
  (356, 143, 9, 7.000, 2.60),
  (357, 143, 28, 2.000, 21.90),
  (358, 143, 20, 7.000, 36.50),
  (359, 144, 15, 8.000, 9.90),
  (360, 144, 19, 6.000, 29.90);
INSERT INTO ITEM_PEDIDO (id_item, id_pedido, id_produto, quantidade, preco_unitario) VALUES
  (361, 144, 27, 8.000, 16.50),
  (362, 145, 49, 8.000, 42.90),
  (363, 146, 45, 6.000, 38.90),
  (364, 146, 15, 6.000, 9.90),
  (365, 147, 4, 8.000, 27.90),
  (366, 147, 51, 4.000, 339.00),
  (367, 148, 7, 1.000, 1.90),
  (368, 148, 24, 4.000, 64.90),
  (369, 148, 28, 3.000, 21.90),
  (370, 149, 12, 7.000, 4.41),
  (371, 149, 30, 6.000, 229.00),
  (372, 149, 33, 4.000, 54.90),
  (373, 149, 40, 7.000, 27.90),
  (374, 150, 5, 4.000, 35.50),
  (375, 150, 11, 2.000, 4.90),
  (376, 151, 47, 10.000, 54.90),
  (377, 152, 20, 2.000, 36.50),
  (378, 152, 35, 1.000, 279.00),
  (379, 153, 24, 7.000, 64.90),
  (380, 153, 26, 3.000, 14.90),
  (381, 154, 51, 1.000, 339.00),
  (382, 155, 21, 1.000, 89.90),
  (383, 155, 11, 6.000, 4.90),
  (384, 155, 33, 8.000, 54.90),
  (385, 156, 42, 3.000, 24.90),
  (386, 157, 57, 12.000, 34.00),
  (387, 158, 13, 2.000, 7.50),
  (388, 158, 50, 1.000, 259.00),
  (389, 158, 10, 2.000, 2.34),
  (390, 158, 1, 2.000, 9.90),
  (391, 158, 41, 3.000, 12.90),
  (392, 159, 53, 30.000, 38.00),
  (393, 159, 28, 5.000, 21.90),
  (394, 160, 53, 15.000, 38.00),
  (395, 160, 34, 8.000, 329.00),
  (396, 161, 13, 4.000, 7.50),
  (397, 161, 44, 8.000, 17.90),
  (398, 162, 26, 7.000, 14.90),
  (399, 163, 48, 20.000, 89.90),
  (400, 163, 5, 7.000, 35.50),
  (401, 163, 37, 4.000, 429.00),
  (402, 164, 47, 20.000, 54.90),
  (403, 165, 57, 9.000, 34.00),
  (404, 166, 34, 4.000, 329.00),
  (405, 166, 57, 12.000, 34.00),
  (406, 167, 13, 2.000, 7.50),
  (407, 167, 11, 3.000, 4.90),
  (408, 168, 20, 1.000, 36.50),
  (409, 169, 37, 4.000, 429.00),
  (410, 169, 18, 8.000, 38.90),
  (411, 170, 29, 3.000, 489.00),
  (412, 170, 41, 7.000, 12.90),
  (413, 170, 18, 2.000, 38.90),
  (414, 171, 51, 1.000, 339.00),
  (415, 171, 32, 8.000, 139.00),
  (416, 171, 25, 1.000, 112.00),
  (417, 171, 41, 7.000, 12.90),
  (418, 172, 43, 5.000, 9.90),
  (419, 173, 6, 2.000, 62.00),
  (420, 173, 8, 4.000, 1.71);
INSERT INTO ITEM_PEDIDO (id_item, id_pedido, id_produto, quantidade, preco_unitario) VALUES
  (421, 174, 37, 4.000, 429.00),
  (422, 174, 28, 4.000, 21.90),
  (423, 174, 9, 4.000, 2.60),
  (424, 175, 27, 8.000, 16.50),
  (425, 176, 35, 4.000, 279.00),
  (426, 176, 29, 1.000, 489.00),
  (427, 177, 41, 5.000, 12.90),
  (428, 178, 6, 8.000, 62.00),
  (429, 178, 41, 8.000, 12.90),
  (430, 178, 17, 3.000, 42.90),
  (431, 179, 1, 8.000, 9.90),
  (432, 179, 3, 1.000, 18.90),
  (433, 179, 21, 2.000, 89.90),
  (434, 179, 6, 1.000, 62.00),
  (435, 180, 17, 8.000, 42.90);

-- PAGAMENTO
INSERT INTO PAGAMENTO (id_pagamento, id_pedido, forma_pagamento, valor_pagamento, status_pagamento, data_hora_pagamento) VALUES
  (1, 1, 'PIX', 168.90, 'APROVADO', '2026-07-02 14:28:46'),
  (2, 2, 'PIX', 540.54, 'APROVADO', '2026-07-03 15:06:03'),
  (3, 3, 'PIX', 9.90, 'APROVADO', '2026-07-04 11:14:08'),
  (4, 4, 'CREDITO', 12.60, 'APROVADO', '2026-07-04 12:28:40'),
  (5, 5, 'CREDITO', 347.10, 'APROVADO', '2026-07-04 17:54:32'),
  (6, 6, 'DEBITO', 1383.82, 'APROVADO', '2026-07-06 10:58:28'),
  (7, 7, 'PIX', 38.90, 'APROVADO', '2026-07-06 11:11:20'),
  (8, 8, 'DEBITO', 474.50, 'APROVADO', '2026-07-06 13:07:33'),
  (9, 9, 'PIX', 1103.80, 'APROVADO', '2026-07-06 12:49:09'),
  (10, 10, 'PIX', 685.90, 'APROVADO', '2026-07-06 14:53:33'),
  (11, 11, 'CREDITO', 97.42, 'APROVADO', '2026-07-06 16:33:02'),
  (12, 12, 'DEBITO', 702.20, 'APROVADO', '2026-07-06 17:25:04'),
  (13, 13, 'PIX', 1838.00, 'APROVADO', '2026-07-07 09:50:40'),
  (14, 14, 'DEBITO', 250.80, 'APROVADO', '2026-07-08 08:54:13'),
  (15, 15, 'CREDITO', 1665.40, 'APROVADO', '2026-07-08 10:29:39'),
  (16, 16, 'DEBITO', 62.40, 'APROVADO', '2026-07-08 13:15:25'),
  (17, 17, 'PIX', 345.20, 'APROVADO', '2026-07-09 10:51:12'),
  (18, 18, 'PIX', 112.35, 'APROVADO', '2026-07-09 17:16:53'),
  (19, 18, 'PIX', 112.35, 'APROVADO', '2026-07-09 17:27:53'),
  (20, 19, 'DEBITO', 686.25, 'APROVADO', '2026-07-13 17:20:12'),
  (21, 19, 'DEBITO', 686.25, 'APROVADO', '2026-07-13 17:31:12'),
  (22, 20, 'DEBITO', 3581.70, 'APROVADO', '2026-07-14 09:37:27'),
  (23, 21, 'DEBITO', 2618.30, 'APROVADO', '2026-07-15 16:17:42'),
  (24, 22, 'DEBITO', 277.00, 'APROVADO', '2026-07-15 16:39:52'),
  (25, 23, 'CREDITO', 229.50, 'APROVADO', '2026-07-16 14:56:47'),
  (26, 24, 'CREDITO', 365.10, 'APROVADO', '2026-07-17 10:01:55'),
  (27, 25, 'PIX', 49.80, 'APROVADO', '2026-07-17 17:16:41'),
  (28, 26, 'PIX', 1606.20, 'APROVADO', '2026-07-18 12:41:14'),
  (29, 27, 'PIX', 179.40, 'APROVADO', '2026-07-18 17:38:27'),
  (30, 28, 'CREDITO', 421.80, 'APROVADO', '2026-07-20 17:12:53'),
  (31, 29, 'CREDITO', 6.84, 'APROVADO', '2026-07-20 17:53:07'),
  (32, 30, 'CREDITO', 272.30, 'APROVADO', '2026-07-22 14:31:53'),
  (33, 31, 'CREDITO', 1611.70, 'APROVADO', '2026-07-23 10:26:51'),
  (34, 32, 'DINHEIRO', 161.10, 'APROVADO', '2026-07-23 10:17:22'),
  (35, 33, 'DEBITO', 10.26, 'APROVADO', '2026-07-23 11:55:04'),
  (36, 34, 'DEBITO', 4114.40, 'APROVADO', '2026-07-23 15:42:49'),
  (37, 35, 'DEBITO', 1631.40, 'APROVADO', '2026-07-24 08:40:40'),
  (38, 36, 'DEBITO', 54.75, 'APROVADO', '2026-07-24 10:00:49'),
  (39, 36, 'DEBITO', 54.75, 'APROVADO', '2026-07-24 10:12:49'),
  (40, 37, 'CREDITO', 2786.50, 'APROVADO', '2026-07-27 11:12:55'),
  (41, 38, 'DINHEIRO', 242.70, 'RECUSADO', '2026-07-27 11:04:30'),
  (42, 39, 'PIX', 1192.20, 'APROVADO', '2026-07-27 12:05:59'),
  (43, 40, 'DINHEIRO', 368.40, 'APROVADO', '2026-07-27 15:32:51'),
  (44, 41, 'PIX', 2019.60, 'APROVADO', '2026-07-27 16:27:41'),
  (45, 42, 'CREDITO', 251.10, 'APROVADO', '2026-07-27 17:09:03'),
  (46, 43, 'PIX', 169.50, 'RECUSADO', '2026-07-27 17:16:52'),
  (47, 44, 'CREDITO', 2533.20, 'APROVADO', '2026-07-28 15:04:27'),
  (48, 45, 'CREDITO', 545.50, 'APROVADO', '2026-07-28 16:30:54'),
  (49, 46, 'DINHEIRO', 2297.00, 'APROVADO', '2026-07-29 08:57:53'),
  (50, 47, 'DEBITO', 1124.50, 'APROVADO', '2026-07-29 11:43:31'),
  (51, 48, 'DINHEIRO', 367.80, 'APROVADO', '2026-07-31 13:49:52'),
  (52, 49, 'PIX', 1347.50, 'APROVADO', '2026-07-31 17:04:40'),
  (53, 49, 'PIX', 1347.50, 'APROVADO', '2026-07-31 17:15:40'),
  (54, 50, 'DINHEIRO', 1639.00, 'APROVADO', '2026-08-01 12:22:46'),
  (55, 51, 'CREDITO', 229.00, 'APROVADO', '2026-08-01 12:45:34'),
  (56, 52, 'CREDITO', 220.80, 'APROVADO', '2026-08-01 16:36:33'),
  (57, 52, 'CREDITO', 220.80, 'APROVADO', '2026-08-01 16:45:33'),
  (58, 53, 'PIX', 1345.30, 'APROVADO', '2026-08-01 17:08:51'),
  (59, 54, 'PIX', 1609.60, 'APROVADO', '2026-08-03 11:35:12'),
  (60, 55, 'PIX', 470.00, 'APROVADO', '2026-08-03 12:47:30');
INSERT INTO PAGAMENTO (id_pagamento, id_pedido, forma_pagamento, valor_pagamento, status_pagamento, data_hora_pagamento) VALUES
  (61, 56, 'PIX', 1259.00, 'APROVADO', '2026-08-03 12:34:47'),
  (62, 57, 'PIX', 6203.55, 'APROVADO', '2026-08-03 16:26:26'),
  (63, 58, 'DEBITO', 306.00, 'APROVADO', '2026-08-04 15:27:32'),
  (64, 59, 'DEBITO', 100.30, 'APROVADO', '2026-08-06 09:03:43'),
  (65, 60, 'PIX', 680.90, 'APROVADO', '2026-08-07 13:53:52'),
  (66, 61, 'PIX', 67.95, 'APROVADO', '2026-08-07 15:20:11'),
  (67, 61, 'DEBITO', 67.95, 'APROVADO', '2026-08-07 15:30:11'),
  (68, 62, 'DEBITO', 74.70, 'APROVADO', '2026-08-08 16:48:16'),
  (69, 63, 'DINHEIRO', 255.80, 'APROVADO', '2026-08-10 11:37:18'),
  (70, 64, 'CREDITO', 338.00, 'APROVADO', '2026-08-10 13:03:26'),
  (71, 65, 'DEBITO', 3.80, 'APROVADO', '2026-08-10 13:25:24'),
  (72, 66, 'DEBITO', 2952.00, 'APROVADO', '2026-08-10 17:51:48'),
  (73, 67, 'CREDITO', 1505.40, 'APROVADO', '2026-08-11 16:53:01'),
  (74, 68, 'DEBITO', 2796.00, 'APROVADO', '2026-08-12 12:34:23'),
  (75, 68, 'CREDITO', 2796.00, 'APROVADO', '2026-08-12 12:44:23'),
  (76, 69, 'CREDITO', 1356.00, 'APROVADO', '2026-08-12 18:11:00'),
  (77, 70, 'CREDITO', 1875.00, 'APROVADO', '2026-08-14 12:10:23'),
  (78, 71, 'PIX', 517.00, 'APROVADO', '2026-08-15 08:36:09'),
  (79, 72, 'DEBITO', 3545.00, 'APROVADO', '2026-08-17 08:50:28'),
  (80, 73, 'CREDITO', 2270.00, 'APROVADO', '2026-08-17 08:58:22'),
  (81, 74, 'CREDITO', 1300.75, 'APROVADO', '2026-08-18 11:42:01'),
  (82, 74, 'PIX', 1300.75, 'APROVADO', '2026-08-18 11:48:01'),
  (83, 75, 'CREDITO', 11.97, 'APROVADO', '2026-08-20 08:04:25'),
  (84, 76, 'DINHEIRO', 77.40, 'APROVADO', '2026-08-20 14:10:31'),
  (85, 77, 'DINHEIRO', 343.40, 'APROVADO', '2026-08-21 11:16:02'),
  (86, 78, 'PIX', 149.50, 'APROVADO', '2026-08-21 17:57:13'),
  (87, 79, 'PIX', 926.70, 'APROVADO', '2026-08-21 17:46:10'),
  (88, 79, 'PIX', 926.70, 'APROVADO', '2026-08-21 17:57:10'),
  (89, 80, 'CREDITO', 3688.20, 'APROVADO', '2026-08-26 11:23:36'),
  (90, 81, 'CREDITO', 465.90, 'APROVADO', '2026-08-26 13:23:41'),
  (91, 82, 'CREDITO', 883.40, 'APROVADO', '2026-08-27 12:31:51'),
  (92, 83, 'CREDITO', 468.75, 'APROVADO', '2026-08-29 12:41:25'),
  (93, 83, 'CREDITO', 468.75, 'APROVADO', '2026-08-29 12:51:25'),
  (94, 84, 'PIX', 4172.60, 'APROVADO', '2026-08-31 14:50:07'),
  (95, 85, 'CREDITO', 928.48, 'APROVADO', '2026-08-31 17:09:07'),
  (96, 86, 'CREDITO', 62.25, 'APROVADO', '2026-09-01 10:58:51'),
  (97, 86, 'CREDITO', 62.25, 'APROVADO', '2026-09-01 11:06:51'),
  (98, 87, 'CREDITO', 128.70, 'APROVADO', '2026-09-02 13:33:18'),
  (99, 89, 'PIX', 1596.30, 'APROVADO', '2026-09-04 15:54:54'),
  (100, 90, 'CREDITO', 484.20, 'APROVADO', '2026-09-05 09:52:57'),
  (101, 91, 'DEBITO', 558.10, 'APROVADO', '2026-09-05 10:50:13'),
  (102, 92, 'PIX', 1752.00, 'APROVADO', '2026-09-07 16:47:24'),
  (103, 93, 'DINHEIRO', 2058.04, 'APROVADO', '2026-09-08 10:57:31'),
  (104, 94, 'DEBITO', 61.50, 'APROVADO', '2026-09-09 16:11:17'),
  (105, 94, 'PIX', 61.50, 'APROVADO', '2026-09-09 16:17:17'),
  (106, 95, 'DINHEIRO', 1672.30, 'APROVADO', '2026-09-09 16:42:56'),
  (107, 96, 'PIX', 274.00, 'APROVADO', '2026-09-10 09:15:19'),
  (108, 97, 'DINHEIRO', 2599.70, 'APROVADO', '2026-09-10 09:53:27'),
  (109, 98, 'DINHEIRO', 901.70, 'APROVADO', '2026-09-10 11:50:38'),
  (110, 99, 'PIX', 1744.75, 'APROVADO', '2026-09-10 14:12:26'),
  (111, 99, 'CREDITO', 1744.75, 'APROVADO', '2026-09-10 14:22:26'),
  (112, 100, 'PIX', 467.83, 'APROVADO', '2026-09-11 11:40:14'),
  (113, 101, 'PIX', 732.00, 'APROVADO', '2026-09-11 15:08:56'),
  (114, 102, 'DINHEIRO', 2431.20, 'APROVADO', '2026-09-12 08:26:23'),
  (115, 103, 'PIX', 224.00, 'RECUSADO', '2026-09-12 12:31:02'),
  (116, 104, 'PIX', 556.00, 'APROVADO', '2026-09-14 08:36:12'),
  (117, 105, 'DINHEIRO', 4.41, 'APROVADO', '2026-09-14 12:53:00'),
  (118, 106, 'DEBITO', 977.70, 'APROVADO', '2026-09-18 11:10:45'),
  (119, 107, 'DEBITO', 149.50, 'APROVADO', '2026-09-18 14:02:15'),
  (120, 108, 'CREDITO', 2149.68, 'APROVADO', '2026-09-18 14:21:49');
INSERT INTO PAGAMENTO (id_pagamento, id_pedido, forma_pagamento, valor_pagamento, status_pagamento, data_hora_pagamento) VALUES
  (121, 108, 'PIX', 2149.68, 'APROVADO', '2026-09-18 14:30:49'),
  (122, 109, 'PIX', 961.20, 'RECUSADO', '2026-09-19 14:00:15'),
  (123, 110, 'CREDITO', 2247.50, 'APROVADO', '2026-09-21 16:23:48'),
  (124, 111, 'CREDITO', 75.00, 'APROVADO', '2026-09-21 17:50:53'),
  (125, 112, 'PIX', 2128.50, 'APROVADO', '2026-09-22 11:43:57'),
  (126, 113, 'PIX', 137.50, 'APROVADO', '2026-09-24 10:14:40'),
  (127, 115, 'PIX', 689.10, 'APROVADO', '2026-09-25 17:19:19'),
  (128, 116, 'CREDITO', 1877.20, 'APROVADO', '2026-09-28 10:41:04'),
  (129, 117, 'DEBITO', 434.40, 'RECUSADO', '2026-09-28 14:21:38'),
  (130, 117, 'DEBITO', 434.40, 'APROVADO', '2026-09-28 14:25:38'),
  (131, 118, 'CREDITO', 558.60, 'APROVADO', '2026-09-29 11:20:48'),
  (132, 119, 'DEBITO', 3649.20, 'APROVADO', '2026-09-29 11:15:46'),
  (133, 120, 'DINHEIRO', 1316.26, 'APROVADO', '2026-09-29 11:34:40'),
  (134, 121, 'PIX', 339.30, 'APROVADO', '2026-09-29 11:58:55'),
  (135, 122, 'DEBITO', 4198.50, 'RECUSADO', '2026-09-29 13:14:24'),
  (136, 123, 'PIX', 825.00, 'APROVADO', '2026-09-29 18:15:01'),
  (137, 124, 'PIX', 1471.45, 'APROVADO', '2026-09-30 09:23:16'),
  (138, 124, 'PIX', 1471.45, 'APROVADO', '2026-09-30 09:25:16'),
  (139, 125, 'CREDITO', 1192.00, 'APROVADO', '2026-09-30 15:48:52'),
  (140, 126, 'DEBITO', 122.50, 'APROVADO', '2026-10-02 09:23:29'),
  (141, 127, 'PIX', 1142.34, 'APROVADO', '2026-10-02 12:47:47'),
  (142, 128, 'PIX', 3319.30, 'APROVADO', '2026-10-02 14:13:19'),
  (143, 129, 'DINHEIRO', 1899.00, 'RECUSADO', '2026-10-03 12:01:10'),
  (144, 129, 'DINHEIRO', 1899.00, 'APROVADO', '2026-10-03 12:09:10'),
  (145, 130, 'DINHEIRO', 77.40, 'APROVADO', '2026-10-03 12:29:20'),
  (146, 130, 'CREDITO', 77.40, 'APROVADO', '2026-10-03 12:38:20'),
  (147, 131, 'CREDITO', 1239.50, 'APROVADO', '2026-10-03 16:40:33'),
  (148, 132, 'PIX', 1830.00, 'APROVADO', '2026-10-05 12:49:08'),
  (149, 133, 'CREDITO', 2863.50, 'APROVADO', '2026-10-05 14:23:49'),
  (150, 134, 'DEBITO', 1607.35, 'APROVADO', '2026-10-05 15:29:58'),
  (151, 134, 'PIX', 1607.35, 'APROVADO', '2026-10-05 15:33:58'),
  (152, 135, 'PIX', 1367.80, 'APROVADO', '2026-10-07 09:56:28'),
  (153, 136, 'PIX', 556.00, 'APROVADO', '2026-10-07 13:06:53'),
  (154, 137, 'CREDITO', 38.90, 'APROVADO', '2026-10-08 08:45:42'),
  (155, 138, 'DEBITO', 224.78, 'APROVADO', '2026-10-08 15:41:54'),
  (156, 138, 'DINHEIRO', 224.77, 'APROVADO', '2026-10-08 15:51:54'),
  (157, 139, 'PIX', 392.40, 'APROVADO', '2026-10-09 12:05:59'),
  (158, 139, 'PIX', 392.40, 'APROVADO', '2026-10-09 12:09:59'),
  (159, 140, 'PIX', 947.80, 'APROVADO', '2026-10-09 17:17:50'),
  (160, 140, 'PIX', 947.80, 'APROVADO', '2026-10-09 17:21:50'),
  (161, 141, 'CREDITO', 475.42, 'APROVADO', '2026-10-10 08:55:38'),
  (162, 142, 'CREDITO', 588.90, 'APROVADO', '2026-10-10 16:04:21'),
  (163, 143, 'DINHEIRO', 353.14, 'APROVADO', '2026-10-12 11:18:26'),
  (164, 144, 'PIX', 390.60, 'APROVADO', '2026-10-12 12:38:39'),
  (165, 145, 'CREDITO', 343.20, 'APROVADO', '2026-10-12 12:21:24'),
  (166, 146, 'CREDITO', 292.80, 'APROVADO', '2026-10-12 13:11:20'),
  (167, 147, 'DEBITO', 1579.20, 'APROVADO', '2026-10-12 14:45:29'),
  (168, 148, 'PIX', 327.20, 'APROVADO', '2026-10-12 15:28:06'),
  (169, 149, 'PIX', 1819.77, 'APROVADO', '2026-10-12 15:42:05'),
  (170, 150, 'DEBITO', 151.80, 'APROVADO', '2026-10-12 17:29:16'),
  (171, 151, 'DEBITO', 549.00, 'RECUSADO', '2026-10-13 13:00:36'),
  (172, 151, 'PIX', 274.50, 'APROVADO', '2026-10-13 13:05:36'),
  (173, 151, 'CREDITO', 274.50, 'APROVADO', '2026-10-13 13:17:36'),
  (174, 152, 'DEBITO', 352.00, 'RECUSADO', '2026-10-13 15:33:01'),
  (175, 152, 'DEBITO', 352.00, 'APROVADO', '2026-10-13 15:45:01'),
  (176, 153, 'CREDITO', 499.00, 'APROVADO', '2026-10-13 15:48:20'),
  (177, 154, 'CREDITO', 339.00, 'APROVADO', '2026-10-16 15:55:27'),
  (178, 155, 'DEBITO', 558.50, 'APROVADO', '2026-10-17 11:56:11'),
  (179, 156, 'CREDITO', 74.70, 'APROVADO', '2026-10-17 11:53:27'),
  (180, 157, 'PIX', 204.00, 'APROVADO', '2026-10-17 12:16:13');
INSERT INTO PAGAMENTO (id_pagamento, id_pedido, forma_pagamento, valor_pagamento, status_pagamento, data_hora_pagamento) VALUES
  (181, 157, 'CREDITO', 204.00, 'APROVADO', '2026-10-17 12:21:13'),
  (182, 158, 'PIX', 337.18, 'APROVADO', '2026-10-17 14:59:24'),
  (183, 159, 'PIX', 624.75, 'APROVADO', '2026-10-19 11:12:54'),
  (184, 159, 'PIX', 624.75, 'APROVADO', '2026-10-19 11:16:54'),
  (185, 160, 'DEBITO', 3202.00, 'APROVADO', '2026-10-19 14:52:26'),
  (186, 161, 'PIX', 173.20, 'APROVADO', '2026-10-19 16:08:15'),
  (187, 162, 'PIX', 104.30, 'APROVADO', '2026-10-19 17:31:58'),
  (188, 163, 'PIX', 3762.50, 'APROVADO', '2026-10-20 11:33:28'),
  (189, 164, 'DEBITO', 1098.00, 'RECUSADO', '2026-10-22 09:46:00'),
  (190, 165, 'PIX', 306.00, 'APROVADO', '2026-10-23 08:48:18'),
  (191, 166, 'CREDITO', 862.00, 'APROVADO', '2026-10-23 09:37:59'),
  (192, 166, 'CREDITO', 862.00, 'APROVADO', '2026-10-23 09:44:59'),
  (193, 167, 'CREDITO', 29.70, 'APROVADO', '2026-10-24 12:34:22'),
  (194, 168, 'PIX', 36.50, 'APROVADO', '2026-10-24 13:12:59'),
  (195, 169, 'DEBITO', 1013.60, 'APROVADO', '2026-10-24 17:42:50'),
  (196, 169, 'CREDITO', 1013.60, 'APROVADO', '2026-10-24 17:48:50'),
  (197, 170, 'DINHEIRO', 1635.10, 'APROVADO', '2026-10-26 14:08:46'),
  (198, 171, 'PIX', 1653.30, 'PENDENTE', '2026-10-26 15:12:57'),
  (199, 172, 'PIX', 49.50, 'APROVADO', '2026-10-27 11:06:25'),
  (200, 173, 'DINHEIRO', 65.42, 'APROVADO', '2026-10-28 08:22:08'),
  (201, 173, 'DINHEIRO', 65.42, 'PENDENTE', '2026-10-28 08:24:08'),
  (202, 174, 'PIX', 1814.00, 'APROVADO', '2026-10-29 10:19:13'),
  (203, 175, 'DEBITO', 132.00, 'APROVADO', '2026-10-29 12:35:38'),
  (204, 176, 'PIX', 1605.00, 'APROVADO', '2026-10-30 10:44:23'),
  (205, 177, 'CREDITO', 64.50, 'APROVADO', '2026-10-30 12:00:49'),
  (206, 178, 'DINHEIRO', 727.90, 'APROVADO', '2026-10-30 12:39:20'),
  (207, 179, 'DINHEIRO', 339.90, 'RECUSADO', '2026-10-30 14:14:07'),
  (208, 180, 'PIX', 171.60, 'APROVADO', '2026-10-31 17:14:12'),
  (209, 180, 'CREDITO', 171.60, 'APROVADO', '2026-10-31 17:25:12');

-- NOTA_FISCAL (venda)
INSERT INTO NOTA_FISCAL (id_nota, id_pedido, numero, serie, chave_acesso, data_emissao, valor_total) VALUES
  (1, 1, 1001, 1, '38144095178215113573418330618758993688489638', '2026-07-02 18:41:46', 168.90),
  (2, 2, 1002, 1, '77554692678907632880234139470406965761667933', '2026-07-04 02:47:03', 540.54),
  (3, 3, 1003, 1, '45550952220484335244152848851283845654227345', '2026-07-05 03:32:08', 9.90),
  (4, 4, 1004, 1, '92738331336640266966439131456980224703008401', '2026-07-04 14:45:40', 2.60),
  (5, 5, 1005, 1, '82161756215702900792757372211169575685888272', '2026-07-05 14:01:32', 347.10),
  (6, 6, 1006, 1, '22171074657144583526311275356545710540065106', '2026-07-06 16:02:28', 1383.82),
  (7, 7, 1007, 1, '46060617360422346075473912187857307066776836', '2026-07-07 00:55:20', 38.90),
  (8, 8, 1008, 1, '56817759152829141585630609317026260920345755', '2026-07-07 03:20:33', 474.50),
  (9, 9, 1009, 1, '86286952734114492812098543212003004403941024', '2026-07-07 08:11:09', 1103.80),
  (10, 10, 1010, 1, '42926178933553950962937826877303214948760621', '2026-07-06 18:18:33', 685.90),
  (11, 11, 1011, 1, '52272618083409919831707239606665450038087018', '2026-07-06 21:33:02', 97.42),
  (12, 13, 1013, 1, '88217425413734055213483655855874817384704758', '2026-07-08 07:10:40', 1838.00),
  (13, 14, 1014, 1, '93100592087904148799603409752519399648325818', '2026-07-08 13:48:13', 250.80),
  (14, 15, 1015, 1, '18887255593049952929790722931937111857299944', '2026-07-09 07:23:39', 1665.40),
  (15, 16, 1016, 1, '60533436211825424730749736454485118603621364', '2026-07-08 22:51:25', 62.40),
  (16, 17, 1017, 1, '11732157284575815323506882700676336938389589', '2026-07-10 07:42:12', 345.20),
  (17, 18, 1018, 1, '38603894916839538553361576908999763975457359', '2026-07-10 13:53:53', 224.70),
  (18, 19, 1019, 1, '57186561520179611377456778937665836813921997', '2026-07-14 12:33:12', 1372.50),
  (19, 20, 1020, 1, '41074518435356194504962707807924574442176844', '2026-07-15 00:14:27', 3581.70),
  (20, 21, 1021, 1, '81969621096275445003051432618849294263330582', '2026-07-15 22:33:42', 2618.30),
  (21, 22, 1022, 1, '07165600388837338012721200907603563145442989', '2026-07-16 00:09:52', 277.00),
  (22, 23, 1023, 1, '63954975398840529288084179609578187581103737', '2026-07-17 10:11:47', 229.50),
  (23, 24, 1024, 1, '77298693415759558993854852209513849245267822', '2026-07-18 03:42:55', 365.10),
  (24, 25, 1025, 1, '82930177270173760554321290136001693460614714', '2026-07-18 02:06:41', 49.80),
  (25, 26, 1026, 1, '00288039463941586330855935476325661169360171', '2026-07-18 18:07:14', 1606.20),
  (26, 27, 1027, 1, '92271018352049726437308621879966259432075806', '2026-07-19 02:25:27', 179.40),
  (27, 28, 1028, 1, '81362220913128962653309698289764937805520235', '2026-07-20 18:54:53', 421.80),
  (28, 29, 1029, 1, '18655363487585593209896795586797858189315766', '2026-07-21 13:11:07', 6.84),
  (29, 30, 1030, 1, '68885863386908773600689394938357517808767718', '2026-07-22 22:15:53', 272.30),
  (30, 31, 1031, 1, '09669326677124825185752997533685452344664188', '2026-07-23 21:47:51', 1611.70),
  (31, 32, 1032, 1, '00574743176877338434527899309798706149040186', '2026-07-23 21:00:22', 161.10),
  (32, 33, 1033, 1, '89980912778689706547752794201951397657471284', '2026-07-23 17:13:04', 10.26),
  (33, 34, 1034, 1, '69212040084858928934454152063437214742703080', '2026-07-23 20:01:49', 4114.40),
  (34, 35, 1035, 1, '53530560224086196861001339118703984612548609', '2026-07-24 18:43:40', 1631.40),
  (35, 36, 1036, 1, '60261260669537958073004353377151892219288740', '2026-07-25 03:44:49', 109.50),
  (36, 37, 1037, 1, '70871079128264039297890970124539259390137791', '2026-07-28 02:30:55', 2786.50),
  (37, 39, 1038, 1, '24427206921157279638317348409825607696831459', '2026-07-28 07:29:59', 1192.20),
  (38, 40, 1039, 1, '15555017953992252075202082817927959048426111', '2026-07-27 20:19:51', 368.40),
  (39, 41, 1040, 1, '28358073855459179700275234485381782642377661', '2026-07-28 10:13:41', 2019.60),
  (40, 42, 1041, 1, '25392220725667568281074462332218351263011656', '2026-07-28 08:48:03', 251.10),
  (41, 44, 1042, 1, '50292037083293329674325556960568257141350017', '2026-07-29 05:54:27', 2533.20),
  (42, 45, 1043, 1, '64135000534082162253853822968726261679968012', '2026-07-29 06:26:54', 545.50),
  (43, 46, 1044, 1, '93613070076279238284696421594874079106477480', '2026-07-30 00:08:53', 2297.00),
  (44, 47, 1045, 1, '72404269051481459576086894820422931670259690', '2026-07-30 08:18:31', 1124.50),
  (45, 48, 1046, 1, '10604876891320504460111818848964070378038465', '2026-07-31 16:07:52', 367.80),
  (46, 49, 1047, 1, '41171587764939701577452801514628612963054542', '2026-08-01 05:32:40', 2695.00),
  (47, 50, 1048, 1, '55184082788079400083865619494867025595491681', '2026-08-02 08:13:46', 1639.00),
  (48, 51, 1049, 1, '40913249010654113704303011917343744012389435', '2026-08-01 19:59:34', 229.00),
  (49, 52, 1050, 1, '77712585175162794009852205173113875370933355', '2026-08-01 20:21:33', 441.60),
  (50, 53, 1051, 1, '55630846463749288196574959345533619089323685', '2026-08-01 22:11:51', 1345.30),
  (51, 54, 1052, 1, '14400671328963889382036733209209352779419938', '2026-08-04 03:23:12', 1609.60),
  (52, 55, 1053, 1, '39701751936333429188752105018071425839141751', '2026-08-03 22:55:30', 470.00),
  (53, 56, 1054, 1, '27377766713984268840086760245284279776214823', '2026-08-03 18:03:47', 1259.00),
  (54, 57, 1055, 1, '15844585571931131591474431941468815471888143', '2026-08-04 09:46:26', 6203.55),
  (55, 58, 1056, 1, '38112688385462153362800779764017241687308165', '2026-08-05 08:03:32', 306.00),
  (56, 59, 1057, 1, '09457382498277882150142714691766394093512410', '2026-08-06 14:01:43', 100.30),
  (57, 60, 1058, 1, '78083433795041110715765657496440990832764894', '2026-08-07 23:34:52', 680.90),
  (58, 61, 1059, 1, '15098624122394762741066777278912173491925672', '2026-08-08 11:26:11', 135.90),
  (59, 62, 1060, 1, '41782525282222837960843296567673450461352235', '2026-08-09 05:59:16', 74.70),
  (60, 63, 1061, 1, '99510490943106701223496685913859207560852137', '2026-08-11 00:11:18', 255.80);
INSERT INTO NOTA_FISCAL (id_nota, id_pedido, numero, serie, chave_acesso, data_emissao, valor_total) VALUES
  (61, 64, 1062, 1, '57504945248985544988492183202872684224024881', '2026-08-11 08:27:26', 338.00),
  (62, 65, 1063, 1, '36461356554080229493650147679275492919618198', '2026-08-10 23:23:24', 3.80),
  (63, 66, 1064, 1, '76540584238754949408902224328628684263011302', '2026-08-10 22:07:48', 2952.00),
  (64, 67, 1065, 1, '59389620693754825356145116478835920198190455', '2026-08-12 09:59:01', 1505.40),
  (65, 68, 1066, 1, '97152232045073649934366113655005462695629208', '2026-08-13 09:45:23', 5592.00),
  (66, 69, 1067, 1, '91683212220137651244567131885734028052793613', '2026-08-13 12:11:00', 1356.00),
  (67, 70, 1068, 1, '15082569720454299095791148352693705147978157', '2026-08-15 03:31:23', 1875.00),
  (68, 71, 1069, 1, '81832043289714360206623320207968858668049873', '2026-08-15 15:35:09', 517.00),
  (69, 72, 1070, 1, '61226268560591099532173966571318188668001604', '2026-08-17 21:03:28', 3545.00),
  (70, 73, 1071, 1, '79560147062213851998844050677505775723936851', '2026-08-17 13:24:22', 2270.00),
  (71, 74, 1072, 1, '41784356967581587522212113001435603644331473', '2026-08-18 17:54:01', 2601.50),
  (72, 75, 1073, 1, '23342752157296822690113857868622195171016434', '2026-08-21 00:20:25', 11.97),
  (73, 76, 1074, 1, '84176014349947641762416882071389378283625959', '2026-08-21 11:46:31', 77.40),
  (74, 77, 1075, 1, '18460821042120101237028393637767362161944393', '2026-08-22 04:06:02', 343.40),
  (75, 78, 1076, 1, '26154111936705751311846033438509864865939035', '2026-08-22 03:17:13', 149.50),
  (76, 79, 1077, 1, '57885660134616730792817293756073803773374001', '2026-08-22 14:55:10', 1853.40),
  (77, 80, 1078, 1, '50237398186780973140569516545105820201442085', '2026-08-26 19:56:36', 3688.20),
  (78, 81, 1079, 1, '57607900622663141701827373254109831679001498', '2026-08-26 15:39:41', 465.90),
  (79, 82, 1080, 1, '75812975679781681299646350398287845054862552', '2026-08-27 15:03:51', 883.40),
  (80, 83, 1081, 1, '64119029484540485076799916196765010933617428', '2026-08-30 07:08:25', 937.50),
  (81, 84, 1082, 1, '58811812097715120106506763278050122138693149', '2026-09-01 03:23:07', 4172.60),
  (82, 85, 1083, 1, '29882402596664364825982986698454121647270925', '2026-09-01 14:56:07', 928.48),
  (83, 86, 1084, 1, '92616125228842580572754511470930086611210680', '2026-09-01 19:14:51', 124.50),
  (84, 87, 1085, 1, '83435115410340666638490325453417450780943229', '2026-09-02 20:21:18', 128.70),
  (85, 89, 1086, 1, '05710161019912283420433279376067775236654984', '2026-09-05 12:43:54', 1596.30),
  (86, 90, 1087, 1, '55167471182008855944405226627992172713662888', '2026-09-05 18:05:57', 484.20),
  (87, 91, 1088, 1, '18748451326889752489116209612194719766615966', '2026-09-06 05:15:13', 558.10),
  (88, 92, 1089, 1, '12371591200924944401493079425083417012499899', '2026-09-08 02:09:24', 1752.00),
  (89, 93, 1090, 1, '71908171881273291923092367722511908502988196', '2026-09-08 21:59:31', 2058.04),
  (90, 94, 1091, 1, '27755000064747116698851734232655525650131496', '2026-09-10 05:20:17', 123.00),
  (91, 95, 1092, 1, '91127128260291901445069890819436320206031885', '2026-09-10 03:15:56', 1672.30),
  (92, 96, 1093, 1, '24565052395701487163402926650626007934771521', '2026-09-11 00:21:19', 274.00),
  (93, 97, 1094, 1, '67903100408526761536887367353968482610964242', '2026-09-11 06:16:27', 2599.70),
  (94, 98, 1095, 1, '52255439568107037530198535150607562059568643', '2026-09-11 05:19:38', 901.70),
  (95, 99, 1096, 1, '54053725060230754435573188971883337471406599', '2026-09-10 19:03:26', 3489.50),
  (96, 100, 1097, 1, '77132765415005055929082967332001095260706660', '2026-09-11 18:15:14', 467.83),
  (97, 101, 1098, 1, '23343561122566585543637892669492496136196719', '2026-09-11 17:28:56', 732.00),
  (98, 102, 1099, 1, '21585754465679055509228761375547755067395535', '2026-09-12 18:48:23', 2431.20),
  (99, 104, 1100, 1, '34576716449709342521457146062600557626250875', '2026-09-14 15:41:12', 556.00),
  (100, 105, 1101, 1, '88244607990551988593640767202093226946774377', '2026-09-14 18:35:00', 4.41),
  (101, 106, 1102, 1, '79101725883499081397921403654690621173801466', '2026-09-19 05:35:45', 977.70),
  (102, 107, 1103, 1, '71887417238530947105365690816897554990822928', '2026-09-18 20:53:15', 149.50),
  (103, 108, 1104, 1, '95929786475928310191783587915298437700444650', '2026-09-18 23:40:49', 4299.36),
  (104, 110, 1105, 1, '59502023754279706387187320667835132893147097', '2026-09-21 22:18:48', 2247.50),
  (105, 111, 1106, 1, '35634124569053478555013548370543365549947882', '2026-09-22 10:23:53', 75.00),
  (106, 112, 1107, 1, '20066474422539686850218970960167693878177468', '2026-09-22 19:45:57', 2128.50),
  (107, 113, 1108, 1, '15660172211969745744365768132654138398983481', '2026-09-24 20:11:40', 137.50),
  (108, 115, 1109, 1, '71943446175874381975119871814722803621192921', '2026-09-25 21:07:19', 689.10),
  (109, 116, 1110, 1, '01717405251323661952904820693483503219469788', '2026-09-28 17:23:04', 1877.20),
  (110, 117, 1111, 1, '14450923357131829275770096870865633053787189', '2026-09-29 04:48:38', 434.40),
  (111, 118, 1112, 1, '23726255328946676588396262375974195280890601', '2026-09-29 21:49:48', 558.60),
  (112, 119, 1113, 1, '67825450098968505620008876433948635664871089', '2026-09-29 22:26:46', 3649.20),
  (113, 120, 1114, 1, '47835514859727705954480717891594362886390779', '2026-09-29 15:22:40', 1316.26),
  (114, 121, 1115, 1, '57808781775090100700783541767601985180567539', '2026-09-29 22:04:55', 339.30),
  (115, 123, 1116, 1, '88692869020497729391904270095847259254078104', '2026-09-30 14:31:01', 825.00),
  (116, 124, 1117, 1, '32311511723345925949655283982967815248959397', '2026-09-30 18:33:16', 2942.90),
  (117, 125, 1118, 1, '77531975360422055020056896017874235018278376', '2026-10-01 12:27:52', 1192.00),
  (118, 126, 1119, 1, '93419770651359919412323225709855162572859409', '2026-10-02 20:53:29', 122.50),
  (119, 127, 1120, 1, '97059050953102555056831420507679270789501796', '2026-10-02 23:58:47', 1142.34),
  (120, 128, 1121, 1, '21663095628885945898861490226671561769329579', '2026-10-03 03:06:19', 3319.30);
INSERT INTO NOTA_FISCAL (id_nota, id_pedido, numero, serie, chave_acesso, data_emissao, valor_total) VALUES
  (121, 129, 1122, 1, '77414198918911762616306248228103475429811997', '2026-10-04 06:13:10', 1899.00),
  (122, 130, 1123, 1, '81960945015221938269081210332768155712537302', '2026-10-03 15:04:20', 154.80),
  (123, 131, 1124, 1, '53008005846253748692320855710186276147122872', '2026-10-04 11:51:33', 1239.50),
  (124, 132, 1125, 1, '98107194031923640512817975114085419347768916', '2026-10-06 04:33:08', 1830.00),
  (125, 133, 1126, 1, '07430917531955114796224180114258242696053003', '2026-10-06 07:27:49', 2863.50),
  (126, 134, 1127, 1, '01610801915312586372061682547705958029064667', '2026-10-06 03:00:58', 3214.70),
  (127, 135, 1128, 1, '98051468085283250253182343375758769720921229', '2026-10-08 06:54:28', 1367.80),
  (128, 136, 1129, 1, '69553513967039103118797185208394091856258982', '2026-10-08 08:29:53', 556.00),
  (129, 137, 1130, 1, '34671351104824478863272226267035646464162492', '2026-10-08 18:20:42', 38.90),
  (130, 138, 1131, 1, '97907959038123813005360028571406458596778632', '2026-10-09 13:42:54', 449.55),
  (131, 139, 1132, 1, '98646681360517176044798692127481472248564552', '2026-10-09 17:37:59', 784.80),
  (132, 140, 1133, 1, '25267457106057088109161075770024085506971284', '2026-10-10 07:44:50', 1895.60),
  (133, 141, 1134, 1, '91519903895594296388244596030934986794097810', '2026-10-10 19:19:38', 475.42),
  (134, 142, 1135, 1, '62984919143648764391045824239402368279429347', '2026-10-11 02:33:21', 588.90),
  (135, 143, 1136, 1, '35671119312005587663620816266048825276690565', '2026-10-12 13:28:26', 353.14),
  (136, 144, 1137, 1, '38964619673506917743800239378524121827169100', '2026-10-13 02:10:39', 390.60),
  (137, 145, 1138, 1, '41905577654150840485613761404963227150318310', '2026-10-13 03:36:24', 343.20),
  (138, 146, 1139, 1, '63779181051724066074044808843233553992041917', '2026-10-12 19:28:20', 292.80),
  (139, 147, 1140, 1, '00551945755014841891936681322579692233559606', '2026-10-13 04:03:29', 1579.20),
  (140, 148, 1141, 1, '41620452731869596631663579508550179514603383', '2026-10-12 16:52:06', 327.20),
  (141, 149, 1142, 1, '64621047336438983450124657730882041659878468', '2026-10-13 03:25:05', 1819.77),
  (142, 150, 1143, 1, '18506419225600662735069875832283183623179326', '2026-10-12 23:24:16', 151.80),
  (143, 151, 1144, 1, '64113542919232489039832032839293448791778665', '2026-10-13 22:58:36', 549.00),
  (144, 152, 1145, 1, '82543934435103085088501465082422381726672714', '2026-10-14 02:16:01', 352.00),
  (145, 153, 1146, 1, '73047028377016339112348829499517764495203878', '2026-10-13 18:13:20', 499.00),
  (146, 154, 1147, 1, '01093850351432529539588675392054858509395723', '2026-10-17 06:56:27', 339.00),
  (147, 155, 1148, 1, '03456482023976208879770882076977462990798704', '2026-10-17 22:02:11', 558.50),
  (148, 156, 1149, 1, '12002932811050875072868226697956291197199656', '2026-10-18 02:34:27', 74.70),
  (149, 157, 1150, 1, '17574107129457457182278179435863444416679241', '2026-10-17 14:29:13', 408.00),
  (150, 158, 1151, 1, '89091816176312060802368904672352527680509078', '2026-10-18 12:37:24', 337.18),
  (151, 159, 1152, 1, '11981652595880013162904884533975581315876562', '2026-10-19 16:33:54', 1249.50),
  (152, 160, 1153, 1, '92975236976131373383452414646867049580982045', '2026-10-19 18:51:26', 3202.00),
  (153, 161, 1154, 1, '93931443092484279424516217801995002494639311', '2026-10-20 00:43:15', 173.20),
  (154, 162, 1155, 1, '56096645360308130286126997045479568779241354', '2026-10-20 12:57:58', 104.30),
  (155, 163, 1156, 1, '39160924738424723406215812198665969217563630', '2026-10-21 08:19:28', 3762.50),
  (156, 165, 1157, 1, '68126913212836588902051737842773436436033408', '2026-10-23 18:39:18', 306.00),
  (157, 166, 1158, 1, '48135297996714314391346638495508850345890736', '2026-10-23 23:08:59', 1724.00),
  (158, 167, 1159, 1, '22777589563722785869778547119216404936101687', '2026-10-24 15:02:22', 29.70),
  (159, 168, 1160, 1, '76910158455055994059107916972029585303962200', '2026-10-25 07:49:59', 36.50),
  (160, 169, 1161, 1, '75931670943384395460634195458620224877260096', '2026-10-25 13:32:50', 2027.20),
  (161, 170, 1162, 1, '75200942020366809821156983074621026183792679', '2026-10-27 07:09:46', 1635.10),
  (162, 176, 1163, 1, '74035947046191982591387185227020714618307073', '2026-10-31 00:06:23', 1605.00),
  (163, 177, 1164, 1, '24974822675383809320651566344610284138470116', '2026-10-31 05:31:49', 64.50),
  (164, 178, 1165, 1, '85203536437539254619138511362501522007378310', '2026-10-30 17:04:20', 727.90),
  (165, 180, 1166, 1, '71717020459079334047988297214951981762121419', '2026-11-01 03:09:12', 343.20);

-- SEPARACAO_PEDIDO
INSERT INTO SEPARACAO_PEDIDO (id_separacao, id_pedido, id_funcionario, data_hora_separacao, status_conferencia, observacao) VALUES
  (1, 1, 5, '2026-07-02 17:22:46', 'CONFERIDO', NULL),
  (2, 2, 5, '2026-07-04 02:09:03', 'CONFERIDO', NULL),
  (3, 3, 6, '2026-07-05 02:45:08', 'CONFERIDO', NULL),
  (4, 4, 6, '2026-07-04 14:08:40', 'CONFERIDO', NULL),
  (5, 5, 6, '2026-07-05 11:37:32', 'DIVERGENTE', 'Item avariado na prateleira; separado outro do lote'),
  (6, 5, 6, '2026-07-05 13:37:32', 'CONFERIDO', NULL),
  (7, 6, 5, '2026-07-06 14:34:28', 'CONFERIDO', NULL),
  (8, 7, 6, '2026-07-06 23:42:20', 'CONFERIDO', NULL),
  (9, 8, 5, '2026-07-07 02:13:33', 'CONFERIDO', NULL),
  (10, 9, 5, '2026-07-07 03:47:09', 'DIVERGENTE', 'Item avariado na prateleira; separado outro do lote'),
  (11, 9, 5, '2026-07-07 06:47:09', 'CONFERIDO', NULL),
  (12, 10, 6, '2026-07-06 17:29:33', 'CONFERIDO', NULL),
  (13, 11, 5, '2026-07-06 20:25:02', 'CONFERIDO', NULL),
  (14, 12, 5, '2026-07-07 06:17:04', 'CONFERIDO', NULL),
  (15, 13, 5, '2026-07-08 06:28:40', 'CONFERIDO', NULL),
  (16, 14, 6, '2026-07-08 12:53:13', 'CONFERIDO', NULL),
  (17, 15, 6, '2026-07-09 06:42:39', 'CONFERIDO', NULL),
  (18, 16, 5, '2026-07-08 19:52:25', 'DIVERGENTE', 'Produto separado diferente do pedido'),
  (19, 16, 5, '2026-07-08 21:52:25', 'CONFERIDO', NULL),
  (20, 17, 6, '2026-07-10 06:29:12', 'CONFERIDO', NULL),
  (21, 18, 6, '2026-07-10 12:42:53', 'CONFERIDO', NULL),
  (22, 19, 6, '2026-07-14 11:23:12', 'CONFERIDO', NULL),
  (23, 20, 6, '2026-07-14 22:48:27', 'CONFERIDO', NULL),
  (24, 21, 6, '2026-07-15 22:01:42', 'CONFERIDO', NULL),
  (25, 22, 6, '2026-07-15 22:31:52', 'DIVERGENTE', 'Quantidade separada menor que a do pedido'),
  (26, 22, 6, '2026-07-15 23:31:52', 'CONFERIDO', NULL),
  (27, 23, 6, '2026-07-17 09:43:47', 'CONFERIDO', NULL),
  (28, 24, 6, '2026-07-18 01:09:55', 'DIVERGENTE', 'Quantidade separada menor que a do pedido'),
  (29, 24, 6, '2026-07-18 03:09:55', 'CONFERIDO', NULL),
  (30, 25, 6, '2026-07-18 01:06:41', 'CONFERIDO', NULL),
  (31, 26, 5, '2026-07-18 16:51:14', 'CONFERIDO', NULL),
  (32, 27, 5, '2026-07-19 01:59:27', 'CONFERIDO', NULL),
  (33, 28, 5, '2026-07-20 18:25:53', 'CONFERIDO', NULL),
  (34, 29, 6, '2026-07-21 09:15:07', 'DIVERGENTE', 'Item avariado na prateleira; separado outro do lote'),
  (35, 29, 6, '2026-07-21 12:15:07', 'CONFERIDO', NULL),
  (36, 30, 6, '2026-07-22 21:02:53', 'CONFERIDO', NULL),
  (37, 31, 5, '2026-07-23 21:21:51', 'CONFERIDO', NULL),
  (38, 32, 6, '2026-07-23 20:20:22', 'CONFERIDO', NULL),
  (39, 33, 6, '2026-07-23 16:27:04', 'CONFERIDO', NULL),
  (40, 34, 6, '2026-07-23 18:49:49', 'CONFERIDO', NULL),
  (41, 35, 6, '2026-07-24 18:18:40', 'CONFERIDO', NULL),
  (42, 36, 6, '2026-07-25 03:16:49', 'CONFERIDO', NULL),
  (43, 37, 6, '2026-07-28 01:20:55', 'CONFERIDO', NULL),
  (44, 39, 6, '2026-07-28 06:39:59', 'CONFERIDO', NULL),
  (45, 40, 6, '2026-07-27 19:21:51', 'CONFERIDO', NULL),
  (46, 41, 5, '2026-07-28 08:58:41', 'CONFERIDO', NULL),
  (47, 42, 6, '2026-07-28 07:59:03', 'CONFERIDO', NULL),
  (48, 44, 5, '2026-07-29 04:31:27', 'CONFERIDO', NULL),
  (49, 45, 6, '2026-07-29 05:06:54', 'CONFERIDO', NULL),
  (50, 46, 5, '2026-07-29 23:13:53', 'CONFERIDO', NULL),
  (51, 47, 6, '2026-07-30 06:59:31', 'CONFERIDO', NULL),
  (52, 48, 6, '2026-07-31 15:34:52', 'CONFERIDO', NULL),
  (53, 49, 6, '2026-08-01 04:09:40', 'CONFERIDO', NULL),
  (54, 50, 5, '2026-08-02 06:58:46', 'CONFERIDO', NULL),
  (55, 51, 5, '2026-08-01 18:30:34', 'CONFERIDO', NULL),
  (56, 52, 5, '2026-08-01 19:06:33', 'CONFERIDO', NULL),
  (57, 53, 6, '2026-08-01 20:18:51', 'DIVERGENTE', 'Quantidade separada menor que a do pedido'),
  (58, 53, 6, '2026-08-01 21:18:51', 'CONFERIDO', NULL),
  (59, 54, 5, '2026-08-04 02:45:12', 'CONFERIDO', NULL),
  (60, 55, 5, '2026-08-03 21:51:30', 'CONFERIDO', NULL);
INSERT INTO SEPARACAO_PEDIDO (id_separacao, id_pedido, id_funcionario, data_hora_separacao, status_conferencia, observacao) VALUES
  (61, 56, 5, '2026-08-03 16:55:47', 'CONFERIDO', NULL),
  (62, 57, 6, '2026-08-04 08:48:26', 'CONFERIDO', NULL),
  (63, 58, 6, '2026-08-05 04:36:32', 'DIVERGENTE', 'Quantidade separada menor que a do pedido'),
  (64, 58, 6, '2026-08-05 07:36:32', 'CONFERIDO', NULL),
  (65, 59, 6, '2026-08-06 13:41:43', 'CONFERIDO', NULL),
  (66, 60, 6, '2026-08-07 22:46:52', 'CONFERIDO', NULL),
  (67, 61, 5, '2026-08-08 10:24:11', 'CONFERIDO', NULL),
  (68, 62, 6, '2026-08-09 05:10:16', 'CONFERIDO', NULL),
  (69, 63, 6, '2026-08-10 23:12:18', 'CONFERIDO', NULL),
  (70, 64, 5, '2026-08-11 07:08:26', 'CONFERIDO', NULL),
  (71, 65, 5, '2026-08-10 22:34:24', 'CONFERIDO', NULL),
  (72, 66, 6, '2026-08-10 21:40:48', 'CONFERIDO', NULL),
  (73, 67, 6, '2026-08-12 08:35:01', 'CONFERIDO', NULL),
  (74, 68, 5, '2026-08-13 09:11:23', 'CONFERIDO', NULL),
  (75, 69, 5, '2026-08-13 11:22:00', 'CONFERIDO', NULL),
  (76, 70, 5, '2026-08-15 02:27:23', 'CONFERIDO', NULL),
  (77, 71, 5, '2026-08-15 14:32:09', 'CONFERIDO', NULL),
  (78, 72, 5, '2026-08-17 20:19:28', 'CONFERIDO', NULL),
  (79, 73, 5, '2026-08-17 12:40:22', 'CONFERIDO', NULL),
  (80, 74, 5, '2026-08-18 17:10:01', 'CONFERIDO', NULL),
  (81, 75, 6, '2026-08-20 23:39:25', 'CONFERIDO', NULL),
  (82, 76, 5, '2026-08-21 11:02:31', 'CONFERIDO', NULL),
  (83, 77, 6, '2026-08-22 03:29:02', 'CONFERIDO', NULL),
  (84, 78, 5, '2026-08-22 02:47:13', 'CONFERIDO', NULL),
  (85, 79, 5, '2026-08-22 13:26:10', 'CONFERIDO', NULL),
  (86, 80, 5, '2026-08-26 19:35:36', 'CONFERIDO', NULL),
  (87, 81, 5, '2026-08-26 14:54:41', 'CONFERIDO', NULL),
  (88, 82, 6, '2026-08-27 14:10:51', 'CONFERIDO', NULL),
  (89, 83, 6, '2026-08-30 05:58:25', 'CONFERIDO', NULL),
  (90, 84, 6, '2026-09-01 01:56:07', 'CONFERIDO', NULL),
  (91, 85, 5, '2026-09-01 10:28:07', 'DIVERGENTE', 'Item avariado na prateleira; separado outro do lote'),
  (92, 85, 5, '2026-09-01 13:28:07', 'CONFERIDO', NULL),
  (93, 86, 6, '2026-09-01 18:18:51', 'CONFERIDO', NULL),
  (94, 87, 5, '2026-09-02 19:46:18', 'CONFERIDO', NULL),
  (95, 89, 6, '2026-09-05 11:37:54', 'CONFERIDO', NULL),
  (96, 90, 5, '2026-09-05 16:38:57', 'CONFERIDO', NULL),
  (97, 91, 6, '2026-09-06 04:49:13', 'CONFERIDO', NULL),
  (98, 92, 5, '2026-09-08 01:04:24', 'CONFERIDO', NULL),
  (99, 93, 5, '2026-09-08 21:26:31', 'CONFERIDO', NULL),
  (100, 94, 5, '2026-09-10 04:11:17', 'CONFERIDO', NULL),
  (101, 95, 5, '2026-09-10 02:33:56', 'CONFERIDO', NULL),
  (102, 96, 5, '2026-09-10 23:24:19', 'CONFERIDO', NULL),
  (103, 97, 6, '2026-09-11 05:10:27', 'CONFERIDO', NULL),
  (104, 98, 6, '2026-09-11 04:49:38', 'CONFERIDO', NULL),
  (105, 99, 6, '2026-09-10 17:51:26', 'CONFERIDO', NULL),
  (106, 100, 5, '2026-09-11 16:59:14', 'CONFERIDO', NULL),
  (107, 101, 6, '2026-09-11 17:04:56', 'CONFERIDO', NULL),
  (108, 102, 5, '2026-09-12 17:30:23', 'CONFERIDO', NULL),
  (109, 104, 6, '2026-09-14 12:36:12', 'DIVERGENTE', 'Quantidade separada menor que a do pedido'),
  (110, 104, 6, '2026-09-14 14:36:12', 'CONFERIDO', NULL),
  (111, 105, 6, '2026-09-14 16:53:00', 'DIVERGENTE', 'Quantidade separada menor que a do pedido'),
  (112, 105, 6, '2026-09-14 17:53:00', 'CONFERIDO', NULL),
  (113, 106, 5, '2026-09-19 05:10:45', 'CONFERIDO', NULL),
  (114, 107, 6, '2026-09-18 20:26:15', 'CONFERIDO', NULL),
  (115, 108, 5, '2026-09-18 22:16:49', 'CONFERIDO', NULL),
  (116, 110, 6, '2026-09-21 21:09:48', 'CONFERIDO', NULL),
  (117, 111, 5, '2026-09-22 09:44:53', 'CONFERIDO', NULL),
  (118, 112, 6, '2026-09-22 19:25:57', 'CONFERIDO', NULL),
  (119, 113, 5, '2026-09-24 17:45:40', 'DIVERGENTE', 'Quantidade separada menor que a do pedido'),
  (120, 113, 5, '2026-09-24 18:45:40', 'CONFERIDO', NULL);
INSERT INTO SEPARACAO_PEDIDO (id_separacao, id_pedido, id_funcionario, data_hora_separacao, status_conferencia, observacao) VALUES
  (121, 115, 5, '2026-09-25 19:49:19', 'CONFERIDO', NULL),
  (122, 116, 5, '2026-09-28 16:01:04', 'CONFERIDO', NULL),
  (123, 117, 6, '2026-09-29 04:28:38', 'CONFERIDO', NULL),
  (124, 118, 6, '2026-09-29 21:01:48', 'CONFERIDO', NULL),
  (125, 119, 6, '2026-09-29 21:32:46', 'CONFERIDO', NULL),
  (126, 120, 5, '2026-09-29 14:09:40', 'CONFERIDO', NULL),
  (127, 121, 5, '2026-09-29 21:32:55', 'CONFERIDO', NULL),
  (128, 123, 5, '2026-09-30 13:09:01', 'CONFERIDO', NULL),
  (129, 124, 6, '2026-09-30 17:11:16', 'CONFERIDO', NULL),
  (130, 125, 6, '2026-10-01 11:09:52', 'CONFERIDO', NULL),
  (131, 126, 5, '2026-10-02 19:27:29', 'CONFERIDO', NULL),
  (132, 127, 5, '2026-10-02 22:53:47', 'CONFERIDO', NULL),
  (133, 128, 6, '2026-10-03 01:50:19', 'CONFERIDO', NULL),
  (134, 129, 5, '2026-10-04 05:35:10', 'CONFERIDO', NULL),
  (135, 130, 5, '2026-10-03 14:18:20', 'CONFERIDO', NULL),
  (136, 131, 6, '2026-10-04 11:06:33', 'CONFERIDO', NULL),
  (137, 132, 5, '2026-10-06 03:44:08', 'CONFERIDO', NULL),
  (138, 133, 6, '2026-10-06 05:58:49', 'CONFERIDO', NULL),
  (139, 134, 5, '2026-10-06 02:13:58', 'CONFERIDO', NULL),
  (140, 135, 6, '2026-10-08 05:54:28', 'CONFERIDO', NULL),
  (141, 136, 6, '2026-10-08 07:13:53', 'CONFERIDO', NULL),
  (142, 137, 6, '2026-10-08 17:52:42', 'CONFERIDO', NULL),
  (143, 138, 5, '2026-10-09 12:29:54', 'CONFERIDO', NULL),
  (144, 139, 6, '2026-10-09 16:27:59', 'CONFERIDO', NULL),
  (145, 140, 5, '2026-10-10 06:11:50', 'DIVERGENTE', 'Item avariado na prateleira; separado outro do lote'),
  (146, 140, 5, '2026-10-10 07:11:50', 'CONFERIDO', NULL),
  (147, 141, 5, '2026-10-10 17:49:38', 'CONFERIDO', NULL),
  (148, 142, 6, '2026-10-11 01:49:21', 'CONFERIDO', NULL),
  (149, 143, 6, '2026-10-12 12:50:26', 'CONFERIDO', NULL),
  (150, 144, 5, '2026-10-13 01:02:39', 'CONFERIDO', NULL),
  (151, 145, 5, '2026-10-13 02:38:24', 'CONFERIDO', NULL),
  (152, 146, 6, '2026-10-12 18:11:20', 'CONFERIDO', NULL),
  (153, 147, 5, '2026-10-13 03:43:29', 'CONFERIDO', NULL),
  (154, 148, 5, '2026-10-12 16:28:06', 'CONFERIDO', NULL),
  (155, 149, 6, '2026-10-12 23:12:05', 'DIVERGENTE', 'Item avariado na prateleira; separado outro do lote'),
  (156, 149, 6, '2026-10-13 02:12:05', 'CONFERIDO', NULL),
  (157, 150, 6, '2026-10-12 21:09:16', 'DIVERGENTE', 'Item avariado na prateleira; separado outro do lote'),
  (158, 150, 6, '2026-10-12 22:09:16', 'CONFERIDO', NULL),
  (159, 151, 5, '2026-10-13 21:54:36', 'CONFERIDO', NULL),
  (160, 152, 5, '2026-10-14 01:05:01', 'CONFERIDO', NULL),
  (161, 153, 5, '2026-10-13 17:01:20', 'CONFERIDO', NULL),
  (162, 154, 6, '2026-10-17 06:23:27', 'CONFERIDO', NULL),
  (163, 155, 6, '2026-10-17 21:40:11', 'CONFERIDO', NULL),
  (164, 156, 5, '2026-10-18 02:07:27', 'CONFERIDO', NULL),
  (165, 157, 5, '2026-10-17 14:07:13', 'CONFERIDO', NULL),
  (166, 158, 5, '2026-10-18 11:45:24', 'CONFERIDO', NULL),
  (167, 159, 5, '2026-10-19 15:23:54', 'CONFERIDO', NULL),
  (168, 160, 5, '2026-10-19 17:24:26', 'CONFERIDO', NULL),
  (169, 161, 5, '2026-10-19 23:44:15', 'CONFERIDO', NULL),
  (170, 162, 5, '2026-10-20 11:31:58', 'CONFERIDO', NULL),
  (171, 163, 6, '2026-10-21 06:59:28', 'CONFERIDO', NULL),
  (172, 165, 6, '2026-10-23 17:18:18', 'CONFERIDO', NULL),
  (173, 166, 5, '2026-10-23 22:04:59', 'CONFERIDO', NULL),
  (174, 167, 5, '2026-10-24 13:53:22', 'CONFERIDO', NULL),
  (175, 168, 5, '2026-10-25 06:24:59', 'CONFERIDO', NULL),
  (176, 169, 5, '2026-10-25 12:30:50', 'CONFERIDO', NULL),
  (177, 170, 6, '2026-10-27 06:47:46', 'CONFERIDO', NULL),
  (178, 175, 6, '2026-10-29 21:52:38', 'CONFERIDO', NULL),
  (179, 176, 6, '2026-10-30 21:45:23', 'DIVERGENTE', 'Quantidade separada menor que a do pedido'),
  (180, 176, 6, '2026-10-30 23:45:23', 'CONFERIDO', NULL);
INSERT INTO SEPARACAO_PEDIDO (id_separacao, id_pedido, id_funcionario, data_hora_separacao, status_conferencia, observacao) VALUES
  (181, 177, 6, '2026-10-31 04:11:49', 'CONFERIDO', NULL),
  (182, 178, 6, '2026-10-30 15:58:20', 'CONFERIDO', NULL),
  (183, 180, 5, '2026-11-01 02:15:12', 'CONFERIDO', NULL);

-- OCORRENCIA
INSERT INTO OCORRENCIA (id_ocorrencia, id_pedido, tipo_ocorrencia, descricao, solucao_aplicada, status_ocorrencia, data_hora, data_hora_resolucao) VALUES
  (1, 3, 'FALTA_ESTOQUE', 'Item sem saldo físico na conferência', 'NOVA_ENTREGA', 'RESOLVIDA', '2026-07-06 18:45:08', '2026-07-08 21:45:08'),
  (2, 7, 'FALTA_ESTOQUE', 'Item sem saldo físico na conferência', 'NOVA_ENTREGA', 'RESOLVIDA', '2026-07-08 20:42:20', '2026-07-11 03:42:20'),
  (3, 52, 'OUTRO', 'Cliente solicitou alteração de quantidade após a separação', 'OUTRO', 'RESOLVIDA', '2026-08-02 13:06:33', '2026-08-02 23:06:33'),
  (4, 53, 'PROBLEMA_ENTREGA', 'Entrega não realizada no endereço informado', NULL, 'ABERTA', '2026-08-03 00:18:51', NULL),
  (5, 56, 'PROBLEMA_ENTREGA', 'Produto entregue com embalagem danificada', NULL, 'ABERTA', '2026-08-04 11:55:47', NULL),
  (6, 59, 'PROBLEMA_ENTREGA', 'Produto entregue com embalagem danificada', 'NOVA_ENTREGA', 'RESOLVIDA', '2026-08-09 22:41:43', '2026-08-11 18:41:43'),
  (7, 63, 'PRODUTO_ERRADO', 'Cliente recebeu modelo diferente do pedido', 'CORRECAO_PEDIDO', 'RESOLVIDA', '2026-08-12 07:12:18', '2026-08-13 11:12:18'),
  (8, 67, 'FALTA_ESTOQUE', 'Item sem saldo físico na conferência', 'NOVA_ENTREGA', 'RESOLVIDA', '2026-08-17 10:35:01', '2026-08-19 18:35:01'),
  (9, 96, 'PRODUTO_ERRADO', 'Cor do produto diferente da pedida', NULL, 'ABERTA', '2026-09-11 04:24:19', NULL),
  (10, 142, 'PROBLEMA_ENTREGA', 'Entrega não realizada no endereço informado', 'NOVA_ENTREGA', 'RESOLVIDA', '2026-10-11 07:49:21', '2026-10-14 03:49:21'),
  (11, 153, 'OUTRO', 'Cliente solicitou alteração de quantidade após a separação', 'OUTRO', 'RESOLVIDA', '2026-10-18 12:01:20', '2026-10-21 09:01:20'),
  (12, 165, 'PRODUTO_ERRADO', 'Cor do produto diferente da pedida', 'CORRECAO_PEDIDO', 'RESOLVIDA', '2026-10-24 22:18:18', '2026-10-25 12:18:18'),
  (13, 178, 'FALTA_ESTOQUE', 'Item sem saldo físico na conferência', NULL, 'ABERTA', '2026-10-31 04:58:20', NULL);

-- TROCA_DEVOLUCAO
INSERT INTO TROCA_DEVOLUCAO (id_troca, id_pedido, id_produto, fundamento, motivo, condicao_produto, tipo_solicitacao, status_solicitacao, data_hora) VALUES
  (1, 154, 51, 'ARREPENDIMENTO', 'Produto não atende à necessidade da obra', 'Embalagem aberta, sem uso', 'REEMBOLSO', 'CONCLUIDA', '2026-10-24 15:23:27'),
  (2, 80, 49, 'ARREPENDIMENTO', 'Produto não atende à necessidade da obra', 'Lacrado, sem uso', 'REEMBOLSO', 'APROVADA', '2026-08-30 19:35:36'),
  (3, 118, 50, 'ARREPENDIMENTO', 'Produto não atende à necessidade da obra', 'Embalagem aberta, sem uso', 'REEMBOLSO', 'CONCLUIDA', '2026-10-05 05:01:48'),
  (4, 44, 36, 'ARREPENDIMENTO', 'Produto não atende à necessidade da obra', 'Embalagem aberta, sem uso', 'REEMBOLSO', 'CONCLUIDA', '2026-07-31 10:31:27'),
  (5, 136, 32, 'ARREPENDIMENTO', 'Cliente desistiu da compra', 'Embalagem aberta, sem uso', 'DEVOLUCAO', 'RECUSADA', '2026-10-21 18:13:53'),
  (6, 113, 13, 'ARREPENDIMENTO', 'Cliente desistiu da compra', 'Embalagem aberta, sem uso', 'DEVOLUCAO', 'RECUSADA', '2026-10-04 10:45:40'),
  (7, 145, 49, 'VICIO', 'Peça com vazamento', 'Danificado no transporte', 'TROCA', 'CONCLUIDA', '2026-11-09 18:00:00'),
  (8, 139, 55, 'VICIO', 'Peça com vazamento', 'Danificado no transporte', 'TROCA', 'CONCLUIDA', '2026-10-21 21:27:59'),
  (9, 59, 15, 'VICIO', 'Peça com vazamento', 'Com defeito de fabricação', 'REEMBOLSO', 'APROVADA', '2026-09-04 22:41:43'),
  (10, 75, 8, 'VICIO', 'Produto danificado ao instalar', 'Danificado no transporte', 'TROCA', 'APROVADA', '2026-10-09 18:39:25'),
  (11, 133, 21, 'VICIO', 'Produto com defeito de fabricação', 'Com defeito de fabricação', 'TROCA', 'APROVADA', '2026-11-09 18:00:00'),
  (12, 111, 2, 'VICIO', 'Produto danificado ao instalar', 'Com defeito de fabricação', 'TROCA', 'CONCLUIDA', '2026-11-09 18:00:00'),
  (13, 113, 13, 'OUTRO', 'Cliente pediu outro modelo do mesmo produto', 'Embalagem aberta, sem uso', 'TROCA', 'CONCLUIDA', '2026-09-27 09:45:40'),
  (14, 90, 15, 'OUTRO', 'Cliente pediu outro modelo do mesmo produto', 'Lacrado, sem uso', 'TROCA', 'CONCLUIDA', '2026-09-13 03:38:57'),
  (15, 168, 20, 'VICIO', 'Produto com defeito de fabricação', 'Danificado no transporte', 'TROCA', 'EM_ANALISE', '2026-10-29 15:24:59'),
  (16, 180, 17, 'VICIO', 'Produto danificado ao instalar', 'Com defeito de fabricação', 'TROCA', 'EM_ANALISE', '2026-11-05 10:15:12');

-- PEDIDO_COMPRA
INSERT INTO PEDIDO_COMPRA (id_pedido_compra, id_fornecedor, data_pedido, status_compra, valor_total) VALUES
  (1, 1, '2026-06-10 09:44:50', 'CANCELADO', 1601.00),
  (2, 6, '2026-06-15 13:36:56', 'CANCELADO', 7236.80),
  (3, 5, '2026-06-15 14:34:31', 'RECEBIDO', 68249.00),
  (4, 8, '2026-06-17 15:55:08', 'RECEBIDO', 16546.50),
  (5, 1, '2026-06-27 15:23:29', 'ABERTO', 2175.10),
  (6, 3, '2026-07-17 11:38:32', 'ABERTO', 3836.50),
  (7, 4, '2026-07-25 12:51:19', 'RECEBIDO', 1523.00),
  (8, 2, '2026-07-29 08:08:14', 'RECEBIDO', 17802.20),
  (9, 2, '2026-07-31 13:58:31', 'PARCIAL', 38332.20),
  (10, 6, '2026-08-03 15:17:25', 'ABERTO', 7742.40),
  (11, 3, '2026-08-04 08:28:53', 'RECEBIDO', 3889.90),
  (12, 6, '2026-08-04 17:41:35', 'RECEBIDO', 6724.20),
  (13, 6, '2026-08-29 10:20:35', 'RECEBIDO', 8584.00),
  (14, 2, '2026-09-01 11:35:26', 'RECEBIDO', 22166.20),
  (15, 5, '2026-09-04 14:57:49', 'PARCIAL', 41260.20),
  (16, 2, '2026-09-14 09:37:18', 'RECEBIDO', 12624.00),
  (17, 2, '2026-09-16 11:55:21', 'PARCIAL', 12077.40),
  (18, 5, '2026-09-17 11:37:06', 'PARCIAL', 77892.40),
  (19, 3, '2026-09-21 13:53:04', 'RECEBIDO', 6002.70),
  (20, 4, '2026-10-02 10:49:49', 'RECEBIDO', 3019.20),
  (21, 6, '2026-10-03 14:51:03', 'RECEBIDO', 7745.60),
  (22, 3, '2026-10-07 11:45:56', 'RECEBIDO', 5589.70),
  (23, 6, '2026-10-12 16:56:42', 'RECEBIDO', 7945.00);

-- ITEM_PEDIDO_COMPRA
INSERT INTO ITEM_PEDIDO_COMPRA (id_item_compra, id_pedido_compra, id_produto, quantidade, custo_unitario) VALUES
  (1, 1, 19, 60.000, 17.97),
  (2, 1, 18, 20.000, 26.14),
  (3, 2, 49, 120.000, 26.13),
  (4, 2, 47, 40.000, 31.73),
  (5, 2, 48, 60.000, 47.20),
  (6, 3, 38, 100.000, 420.80),
  (7, 3, 37, 100.000, 261.69),
  (8, 4, 51, 50.000, 179.67),
  (9, 4, 50, 50.000, 151.26),
  (10, 5, 18, 30.000, 25.67),
  (11, 5, 17, 50.000, 28.10),
  (12, 6, 40, 60.000, 15.79),
  (13, 6, 43, 120.000, 5.99),
  (14, 6, 42, 50.000, 15.26),
  (15, 6, 44, 20.000, 10.94),
  (16, 6, 45, 50.000, 23.77),
  (17, 7, 5, 30.000, 18.99),
  (18, 7, 8, 120.000, 1.12),
  (19, 7, 13, 120.000, 4.89),
  (20, 7, 14, 30.000, 4.35),
  (21, 7, 7, 80.000, 1.27),
  (22, 8, 25, 20.000, 62.61),
  (23, 8, 31, 100.000, 165.50),
  (24, 9, 29, 50.000, 298.78),
  (25, 9, 25, 50.000, 65.86),
  (26, 9, 31, 60.000, 164.72),
  (27, 9, 36, 80.000, 82.99),
  (28, 9, 23, 30.000, 119.26),
  (29, 10, 49, 120.000, 28.01),
  (30, 10, 47, 120.000, 36.51),
  (31, 11, 44, 100.000, 12.15),
  (32, 11, 45, 50.000, 22.72),
  (33, 11, 40, 20.000, 15.57),
  (34, 11, 42, 60.000, 13.25),
  (35, 11, 46, 50.000, 8.65),
  (36, 12, 48, 60.000, 53.31),
  (37, 12, 47, 60.000, 29.59),
  (38, 12, 49, 60.000, 29.17),
  (39, 13, 47, 60.000, 36.67),
  (40, 13, 49, 60.000, 27.41),
  (41, 13, 48, 80.000, 59.24),
  (42, 14, 25, 120.000, 75.71),
  (43, 14, 29, 50.000, 261.62),
  (44, 15, 39, 50.000, 12.04),
  (45, 15, 38, 80.000, 448.06),
  (46, 15, 37, 20.000, 240.67),
  (47, 16, 36, 50.000, 84.78),
  (48, 16, 33, 20.000, 28.99),
  (49, 16, 32, 80.000, 86.46),
  (50, 16, 22, 20.000, 44.42),
  (51, 17, 23, 60.000, 111.89),
  (52, 17, 36, 60.000, 89.40),
  (53, 18, 37, 100.000, 239.38),
  (54, 18, 39, 120.000, 10.65),
  (55, 18, 38, 120.000, 438.97),
  (56, 19, 45, 100.000, 22.56),
  (57, 19, 40, 120.000, 15.01),
  (58, 19, 43, 30.000, 6.29),
  (59, 19, 42, 120.000, 14.64),
  (60, 20, 5, 100.000, 19.42);
INSERT INTO ITEM_PEDIDO_COMPRA (id_item_compra, id_pedido_compra, id_produto, quantidade, custo_unitario) VALUES
  (61, 20, 2, 100.000, 8.18),
  (62, 20, 11, 80.000, 3.24),
  (63, 21, 49, 120.000, 24.11),
  (64, 21, 47, 80.000, 36.29),
  (65, 21, 48, 40.000, 48.73),
  (66, 22, 41, 30.000, 6.82),
  (67, 22, 42, 120.000, 14.82),
  (68, 22, 45, 120.000, 23.57),
  (69, 22, 44, 50.000, 11.87),
  (70, 22, 43, 30.000, 6.16),
  (71, 23, 49, 40.000, 24.28),
  (72, 23, 48, 60.000, 57.81),
  (73, 23, 47, 120.000, 29.21);

-- RECEBIMENTO
INSERT INTO RECEBIMENTO (id_recebimento, id_pedido_compra, id_funcionario, data_hora, numero_nf_fornecedor) VALUES
  (1, 3, 7, '2026-06-18 19:34:31', '90920'),
  (2, 4, 7, '2026-06-26 17:55:08', '67619'),
  (3, 7, 7, '2026-07-31 13:51:19', '13472'),
  (4, 8, 7, '2026-08-06 11:08:14', '77451'),
  (5, 9, 7, '2026-08-09 14:58:31', '39087'),
  (6, 11, 7, '2026-08-10 11:28:53', '83968'),
  (7, 11, 7, '2026-08-18 14:28:53', '83375'),
  (8, 12, 7, '2026-08-12 18:41:35', '85195'),
  (9, 12, 7, '2026-08-16 22:41:35', '83338'),
  (10, 13, 7, '2026-08-31 16:20:35', '34479'),
  (11, 14, 7, '2026-09-08 13:35:26', '65036'),
  (12, 15, 7, '2026-09-06 16:57:49', '77582'),
  (13, 16, 7, '2026-09-16 15:37:18', '52466'),
  (14, 17, 7, '2026-09-22 12:55:21', '54841'),
  (15, 18, 7, '2026-09-24 16:37:06', '90210'),
  (16, 19, 7, '2026-09-28 18:53:04', '80665'),
  (17, 20, 7, '2026-10-10 12:49:49', '93903'),
  (18, 21, 7, '2026-10-12 17:51:03', '52659'),
  (19, 21, 7, '2026-10-09 19:51:03', '97692'),
  (20, 22, 7, '2026-10-09 14:45:56', '62574'),
  (21, 22, 7, '2026-10-25 14:45:56', '91321'),
  (22, 23, 7, '2026-10-20 19:56:42', '54945'),
  (23, 23, 7, '2026-10-26 18:56:42', '72881');

-- ITEM_RECEBIMENTO
INSERT INTO ITEM_RECEBIMENTO (id_item_recebimento, id_recebimento, id_item_compra, quantidade_recebida) VALUES
  (1, 1, 6, 100.000),
  (2, 1, 7, 100.000),
  (3, 2, 8, 50.000),
  (4, 2, 9, 50.000),
  (5, 3, 17, 30.000),
  (6, 3, 18, 120.000),
  (7, 3, 19, 120.000),
  (8, 3, 20, 30.000),
  (9, 3, 21, 80.000),
  (10, 4, 22, 20.000),
  (11, 4, 23, 100.000),
  (12, 5, 24, 33.500),
  (13, 5, 25, 33.500),
  (14, 5, 26, 40.200),
  (15, 5, 27, 53.600),
  (16, 5, 28, 20.100),
  (17, 6, 31, 50.000),
  (18, 6, 32, 25.000),
  (19, 6, 33, 10.000),
  (20, 6, 34, 30.000),
  (21, 6, 35, 25.000),
  (22, 7, 31, 50.000),
  (23, 7, 32, 25.000),
  (24, 7, 33, 10.000),
  (25, 7, 34, 30.000),
  (26, 7, 35, 25.000),
  (27, 8, 36, 30.000),
  (28, 8, 37, 30.000),
  (29, 8, 38, 30.000),
  (30, 9, 36, 30.000),
  (31, 9, 37, 30.000),
  (32, 9, 38, 30.000),
  (33, 10, 39, 60.000),
  (34, 10, 40, 60.000),
  (35, 10, 41, 80.000),
  (36, 11, 42, 120.000),
  (37, 11, 43, 50.000),
  (38, 12, 44, 18.500),
  (39, 12, 45, 29.600),
  (40, 12, 46, 7.400),
  (41, 13, 47, 50.000),
  (42, 13, 48, 20.000),
  (43, 13, 49, 80.000),
  (44, 13, 50, 20.000),
  (45, 14, 51, 20.400),
  (46, 14, 52, 20.400),
  (47, 15, 53, 68.000),
  (48, 15, 54, 81.600),
  (49, 15, 55, 81.600),
  (50, 16, 56, 100.000),
  (51, 16, 57, 120.000),
  (52, 16, 58, 30.000),
  (53, 16, 59, 120.000),
  (54, 17, 60, 100.000),
  (55, 17, 61, 100.000),
  (56, 17, 62, 80.000),
  (57, 18, 63, 60.000),
  (58, 18, 64, 40.000),
  (59, 18, 65, 20.000),
  (60, 19, 63, 60.000);
INSERT INTO ITEM_RECEBIMENTO (id_item_recebimento, id_recebimento, id_item_compra, quantidade_recebida) VALUES
  (61, 19, 64, 40.000),
  (62, 19, 65, 20.000),
  (63, 20, 66, 15.000),
  (64, 20, 67, 60.000),
  (65, 20, 68, 60.000),
  (66, 20, 69, 25.000),
  (67, 20, 70, 15.000),
  (68, 21, 66, 15.000),
  (69, 21, 67, 60.000),
  (70, 21, 68, 60.000),
  (71, 21, 69, 25.000),
  (72, 21, 70, 15.000),
  (73, 22, 71, 20.000),
  (74, 22, 72, 30.000),
  (75, 22, 73, 60.000),
  (76, 23, 71, 20.000),
  (77, 23, 72, 30.000),
  (78, 23, 73, 60.000);

-- CONTA_PAGAR
INSERT INTO CONTA_PAGAR (id_conta, id_recebimento, data_vencimento, valor, status_conta, data_pagamento, forma_pagamento) VALUES
  (1, 1, '2026-07-16', 68249.00, 'PAGA', '2026-07-15', 'TRANSFERENCIA'),
  (2, 2, '2026-07-24', 16546.50, 'PAGA', '2026-07-24', 'TRANSFERENCIA'),
  (3, 3, '2026-08-28', 1523.00, 'PAGA', '2026-08-28', 'TRANSFERENCIA'),
  (4, 4, '2026-09-03', 17802.20, 'PAGA', '2026-09-03', 'BOLETO'),
  (5, 5, '2026-09-06', 25682.57, 'ABERTA', NULL, NULL),
  (6, 6, '2026-09-07', 1944.95, 'PAGA', '2026-09-06', 'BOLETO'),
  (7, 7, '2026-09-15', 1944.95, 'ABERTA', NULL, NULL),
  (8, 8, '2026-09-09', 3362.10, 'PAGA', '2026-09-07', 'BOLETO'),
  (9, 9, '2026-09-13', 3362.10, 'PAGA', '2026-09-12', 'TRANSFERENCIA'),
  (10, 10, '2026-09-28', 8584.00, 'PAGA', '2026-09-28', 'BOLETO'),
  (11, 11, '2026-10-06', 22166.20, 'PAGA', '2026-10-05', 'BOLETO'),
  (12, 12, '2026-10-04', 15266.27, 'PAGA', '2026-10-01', 'BOLETO'),
  (13, 13, '2026-10-14', 12624.00, 'PAGA', '2026-10-11', 'TRANSFERENCIA'),
  (14, 14, '2026-10-20', 4106.32, 'PAGA', '2026-10-18', 'PIX'),
  (15, 15, '2026-10-22', 52966.83, 'PAGA', '2026-10-19', 'TRANSFERENCIA'),
  (16, 16, '2026-10-26', 6002.70, 'PAGA', '2026-10-25', 'PIX'),
  (17, 17, '2026-11-07', 3019.20, 'ABERTA', NULL, NULL),
  (18, 18, '2026-11-09', 3872.80, 'ABERTA', NULL, NULL),
  (19, 19, '2026-11-06', 3872.80, 'ABERTA', NULL, NULL),
  (20, 20, '2026-11-06', 2794.85, 'ABERTA', NULL, NULL),
  (21, 21, '2026-11-22', 2794.85, 'ABERTA', NULL, NULL),
  (22, 22, '2026-11-17', 3972.50, 'ABERTA', NULL, NULL),
  (23, 23, '2026-11-23', 3972.50, 'ABERTA', NULL, NULL);

-- ORDEM_PRODUCAO
INSERT INTO ORDEM_PRODUCAO (id_ordem_producao, id_produto, id_funcionario, quantidade, data_hora, status_producao) VALUES
  (1, 59, 8, 10.000, '2026-07-01 13:01:49', 'CONCLUIDA'),
  (2, 54, 8, 30.000, '2026-07-20 16:50:26', 'CONCLUIDA'),
  (3, 55, 8, 30.000, '2026-07-21 09:44:30', 'CONCLUIDA'),
  (4, 55, 8, 60.000, '2026-07-24 08:36:17', 'CONCLUIDA'),
  (5, 54, 8, 90.000, '2026-07-25 15:42:32', 'CONCLUIDA'),
  (6, 52, 8, 120.000, '2026-07-28 09:26:09', 'CONCLUIDA'),
  (7, 52, 8, 60.000, '2026-08-06 12:12:25', 'CONCLUIDA'),
  (8, 60, 8, 10.000, '2026-08-12 11:45:46', 'CONCLUIDA'),
  (9, 56, 8, 30.000, '2026-08-21 10:13:52', 'CANCELADA'),
  (10, 55, 8, 120.000, '2026-08-28 09:30:44', 'CONCLUIDA'),
  (11, 56, 8, 30.000, '2026-09-04 17:34:17', 'CONCLUIDA'),
  (12, 55, 8, 60.000, '2026-09-11 14:01:29', 'CONCLUIDA'),
  (13, 54, 8, 30.000, '2026-09-17 08:42:14', 'CONCLUIDA'),
  (14, 54, 8, 120.000, '2026-09-23 09:32:45', 'CONCLUIDA'),
  (15, 59, 8, 20.000, '2026-10-03 16:02:16', 'CONCLUIDA'),
  (16, 52, 8, 90.000, '2026-10-19 10:31:13', 'CONCLUIDA'),
  (17, 59, 8, 20.000, '2026-10-19 17:13:02', 'ABERTA'),
  (18, 55, 8, 60.000, '2026-11-02 15:31:53', 'ABERTA');

-- MOVIMENTACAO_ESTOQUE (inventário inicial + entradas e saídas do período)
INSERT INTO MOVIMENTACAO_ESTOQUE (id_movimentacao, id_produto, tipo_movimentacao, quantidade, data_hora, id_funcionario, id_pedido, id_recebimento, id_ordem_producao) VALUES
  (1, 38, 'ENTRADA_COMPRA', 100.000, '2026-06-18 19:34:31', 7, NULL, 1, NULL),
  (2, 37, 'ENTRADA_COMPRA', 100.000, '2026-06-18 19:34:31', 7, NULL, 1, NULL),
  (3, 51, 'ENTRADA_COMPRA', 50.000, '2026-06-26 17:55:08', 7, NULL, 2, NULL),
  (4, 50, 'ENTRADA_COMPRA', 50.000, '2026-06-26 17:55:08', 7, NULL, 2, NULL),
  (5, 1, 'ENTRADA_AJUSTE', 153.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (6, 2, 'ENTRADA_AJUSTE', 95.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (7, 3, 'ENTRADA_AJUSTE', 74.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (8, 4, 'ENTRADA_AJUSTE', 101.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (9, 5, 'ENTRADA_AJUSTE', 54.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (10, 6, 'ENTRADA_AJUSTE', 71.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (11, 7, 'ENTRADA_AJUSTE', 73.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (12, 8, 'ENTRADA_AJUSTE', 90.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (13, 9, 'ENTRADA_AJUSTE', 190.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (14, 10, 'ENTRADA_AJUSTE', 111.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (15, 11, 'ENTRADA_AJUSTE', 157.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (16, 12, 'ENTRADA_AJUSTE', 25.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (17, 13, 'ENTRADA_AJUSTE', 138.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (18, 14, 'ENTRADA_AJUSTE', 48.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (19, 15, 'ENTRADA_AJUSTE', 213.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (20, 16, 'ENTRADA_AJUSTE', 18.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (21, 17, 'ENTRADA_AJUSTE', 135.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (22, 18, 'ENTRADA_AJUSTE', 139.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (23, 19, 'ENTRADA_AJUSTE', 166.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (24, 20, 'ENTRADA_AJUSTE', 155.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (25, 21, 'ENTRADA_AJUSTE', 135.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (26, 22, 'ENTRADA_AJUSTE', 19.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (27, 23, 'ENTRADA_AJUSTE', 59.900, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (28, 24, 'ENTRADA_AJUSTE', 143.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (29, 25, 'ENTRADA_AJUSTE', 129.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (30, 26, 'ENTRADA_AJUSTE', 74.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (31, 27, 'ENTRADA_AJUSTE', 200.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (32, 28, 'ENTRADA_AJUSTE', 46.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (33, 29, 'ENTRADA_AJUSTE', 142.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (34, 30, 'ENTRADA_AJUSTE', 118.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (35, 31, 'ENTRADA_AJUSTE', 133.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (36, 32, 'ENTRADA_AJUSTE', 88.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (37, 33, 'ENTRADA_AJUSTE', 178.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (38, 34, 'ENTRADA_AJUSTE', 163.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (39, 35, 'ENTRADA_AJUSTE', 21.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (40, 36, 'ENTRADA_AJUSTE', 25.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (41, 37, 'ENTRADA_AJUSTE', 102.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (42, 38, 'ENTRADA_AJUSTE', 54.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (43, 39, 'ENTRADA_AJUSTE', 12.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (44, 40, 'ENTRADA_AJUSTE', 149.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (45, 41, 'ENTRADA_AJUSTE', 7.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (46, 42, 'ENTRADA_AJUSTE', 151.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (47, 43, 'ENTRADA_AJUSTE', 75.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (48, 44, 'ENTRADA_AJUSTE', 63.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (49, 45, 'ENTRADA_AJUSTE', 53.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (50, 46, 'ENTRADA_AJUSTE', 72.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (51, 47, 'ENTRADA_AJUSTE', 180.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (52, 48, 'ENTRADA_AJUSTE', 86.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (53, 49, 'ENTRADA_AJUSTE', 37.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (54, 50, 'ENTRADA_AJUSTE', 135.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (55, 51, 'ENTRADA_AJUSTE', 85.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (56, 52, 'ENTRADA_AJUSTE', 122.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (57, 53, 'ENTRADA_AJUSTE', 197.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (58, 54, 'ENTRADA_AJUSTE', 165.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (59, 55, 'ENTRADA_AJUSTE', 58.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (60, 56, 'ENTRADA_AJUSTE', 94.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_movimentacao, id_produto, tipo_movimentacao, quantidade, data_hora, id_funcionario, id_pedido, id_recebimento, id_ordem_producao) VALUES
  (61, 57, 'ENTRADA_AJUSTE', 132.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (62, 58, 'ENTRADA_AJUSTE', 206.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (63, 59, 'ENTRADA_AJUSTE', 117.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (64, 60, 'ENTRADA_AJUSTE', 135.000, '2026-06-30 07:30:00', 7, NULL, NULL, NULL),
  (65, 59, 'ENTRADA_PRODUCAO', 10.000, '2026-07-01 13:01:49', 8, NULL, NULL, 1),
  (66, 58, 'SAIDA_VENDA', 6.000, '2026-07-02 17:22:46', 5, 1, NULL, NULL),
  (67, 33, 'SAIDA_VENDA', 1.000, '2026-07-02 17:22:46', 5, 1, NULL, NULL),
  (68, 47, 'SAIDA_VENDA', 8.000, '2026-07-04 02:09:03', 5, 2, NULL, NULL),
  (69, 27, 'SAIDA_VENDA', 6.000, '2026-07-04 02:09:03', 5, 2, NULL, NULL),
  (70, 10, 'SAIDA_VENDA', 1.000, '2026-07-04 02:09:03', 5, 2, NULL, NULL),
  (71, 9, 'SAIDA_VENDA', 1.000, '2026-07-04 14:08:40', 6, 4, NULL, NULL),
  (72, 1, 'SAIDA_VENDA', 1.000, '2026-07-05 02:45:08', 6, 3, NULL, NULL),
  (73, 46, 'SAIDA_VENDA', 4.000, '2026-07-05 13:37:32', 6, 5, NULL, NULL),
  (74, 56, 'SAIDA_VENDA', 9.000, '2026-07-05 13:37:32', 6, 5, NULL, NULL),
  (75, 3, 'SAIDA_VENDA', 5.000, '2026-07-05 13:37:32', 6, 5, NULL, NULL),
  (76, 16, 'SAIDA_VENDA', 2.000, '2026-07-06 14:34:28', 5, 6, NULL, NULL),
  (77, 6, 'SAIDA_VENDA', 8.000, '2026-07-06 14:34:28', 5, 6, NULL, NULL),
  (78, 54, 'SAIDA_VENDA', 30.000, '2026-07-06 14:34:28', 5, 6, NULL, NULL),
  (79, 19, 'SAIDA_VENDA', 3.000, '2026-07-06 17:29:33', 6, 10, NULL, NULL),
  (80, 20, 'SAIDA_VENDA', 5.000, '2026-07-06 17:29:33', 6, 10, NULL, NULL),
  (81, 1, 'SAIDA_VENDA', 7.000, '2026-07-06 17:29:33', 6, 10, NULL, NULL),
  (82, 13, 'SAIDA_VENDA', 2.000, '2026-07-06 17:29:33', 6, 10, NULL, NULL),
  (83, 33, 'SAIDA_VENDA', 6.000, '2026-07-06 17:29:33', 6, 10, NULL, NULL),
  (84, 39, 'SAIDA_VENDA', 4.000, '2026-07-06 20:25:02', 5, 11, NULL, NULL),
  (85, 16, 'SAIDA_VENDA', 2.000, '2026-07-06 20:25:02', 5, 11, NULL, NULL),
  (86, 18, 'SAIDA_VENDA', 1.000, '2026-07-06 23:42:20', 6, 7, NULL, NULL),
  (87, 22, 'SAIDA_VENDA', 5.000, '2026-07-07 02:13:33', 5, 8, NULL, NULL),
  (88, 2, 'SAIDA_VENDA', 8.000, '2026-07-07 02:13:33', 5, 8, NULL, NULL),
  (89, 46, 'SAIDA_VENDA', 8.000, '2026-07-07 06:17:04', 5, 12, NULL, NULL),
  (90, 20, 'SAIDA_VENDA', 4.000, '2026-07-07 06:17:04', 5, 12, NULL, NULL),
  (91, 49, 'SAIDA_VENDA', 10.000, '2026-07-07 06:17:04', 5, 12, NULL, NULL),
  (92, 9, 'SAIDA_VENDA', 8.000, '2026-07-07 06:47:09', 5, 9, NULL, NULL),
  (93, 31, 'SAIDA_VENDA', 3.000, '2026-07-07 06:47:09', 5, 9, NULL, NULL),
  (94, 57, 'SAIDA_VENDA', 9.000, '2026-07-07 06:47:09', 5, 9, NULL, NULL),
  (95, 5, 'SAIDA_VENDA', 8.000, '2026-07-08 06:28:40', 5, 13, NULL, NULL),
  (96, 50, 'SAIDA_VENDA', 6.000, '2026-07-08 06:28:40', 5, 13, NULL, NULL),
  (97, 22, 'SAIDA_VENDA', 1.000, '2026-07-08 12:53:13', 6, 14, NULL, NULL),
  (98, 46, 'SAIDA_VENDA', 4.000, '2026-07-08 12:53:13', 6, 14, NULL, NULL),
  (99, 13, 'SAIDA_VENDA', 7.000, '2026-07-08 12:53:13', 6, 14, NULL, NULL),
  (100, 19, 'SAIDA_VENDA', 2.000, '2026-07-08 12:53:13', 6, 14, NULL, NULL),
  (101, 13, 'SAIDA_VENDA', 1.000, '2026-07-08 21:52:25', 5, 16, NULL, NULL),
  (102, 33, 'SAIDA_VENDA', 1.000, '2026-07-08 21:52:25', 5, 16, NULL, NULL),
  (103, 53, 'SAIDA_VENDA', 9.000, '2026-07-09 06:42:39', 6, 15, NULL, NULL),
  (104, 36, 'SAIDA_VENDA', 8.000, '2026-07-09 06:42:39', 6, 15, NULL, NULL),
  (105, 28, 'SAIDA_VENDA', 6.000, '2026-07-09 06:42:39', 6, 15, NULL, NULL),
  (106, 14, 'SAIDA_VENDA', 4.000, '2026-07-10 06:29:12', 6, 17, NULL, NULL),
  (107, 24, 'SAIDA_VENDA', 4.000, '2026-07-10 06:29:12', 6, 17, NULL, NULL),
  (108, 9, 'SAIDA_VENDA', 8.000, '2026-07-10 06:29:12', 6, 17, NULL, NULL),
  (109, 3, 'SAIDA_VENDA', 2.000, '2026-07-10 06:29:12', 6, 17, NULL, NULL),
  (110, 22, 'SAIDA_VENDA', 3.000, '2026-07-10 12:42:53', 6, 18, NULL, NULL),
  (111, 23, 'SAIDA_VENDA', 7.000, '2026-07-14 11:23:12', 6, 19, NULL, NULL),
  (112, 27, 'SAIDA_VENDA', 3.000, '2026-07-14 11:23:12', 6, 19, NULL, NULL),
  (113, 37, 'SAIDA_VENDA', 6.000, '2026-07-14 22:48:27', 6, 20, NULL, NULL),
  (114, 29, 'SAIDA_VENDA', 2.000, '2026-07-14 22:48:27', 6, 20, NULL, NULL),
  (115, 43, 'SAIDA_VENDA', 3.000, '2026-07-14 22:48:27', 6, 20, NULL, NULL),
  (116, 15, 'SAIDA_VENDA', 6.000, '2026-07-15 22:01:42', 6, 21, NULL, NULL),
  (117, 59, 'SAIDA_VENDA', 3.000, '2026-07-15 22:01:42', 6, 21, NULL, NULL),
  (118, 11, 'SAIDA_VENDA', 1.000, '2026-07-15 22:01:42', 6, 21, NULL, NULL),
  (119, 52, 'SAIDA_VENDA', 12.000, '2026-07-15 22:01:42', 6, 21, NULL, NULL),
  (120, 30, 'SAIDA_VENDA', 7.000, '2026-07-15 22:01:42', 6, 21, NULL, NULL);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_movimentacao, id_produto, tipo_movimentacao, quantidade, data_hora, id_funcionario, id_pedido, id_recebimento, id_ordem_producao) VALUES
  (121, 27, 'SAIDA_VENDA', 5.000, '2026-07-15 23:31:52', 6, 22, NULL, NULL),
  (122, 45, 'SAIDA_VENDA', 5.000, '2026-07-15 23:31:52', 6, 22, NULL, NULL),
  (123, 27, 'SAIDA_VENDA', 1.000, '2026-07-17 09:43:47', 6, 23, NULL, NULL),
  (124, 5, 'SAIDA_VENDA', 6.000, '2026-07-17 09:43:47', 6, 23, NULL, NULL),
  (125, 42, 'SAIDA_VENDA', 2.000, '2026-07-18 01:06:41', 6, 25, NULL, NULL),
  (126, 18, 'SAIDA_VENDA', 7.000, '2026-07-18 03:09:55', 6, 24, NULL, NULL),
  (127, 9, 'SAIDA_VENDA', 2.000, '2026-07-18 03:09:55', 6, 24, NULL, NULL),
  (128, 28, 'SAIDA_VENDA', 4.000, '2026-07-18 03:09:55', 6, 24, NULL, NULL),
  (129, 45, 'SAIDA_VENDA', 8.000, '2026-07-18 16:51:14', 5, 26, NULL, NULL),
  (130, 50, 'SAIDA_VENDA', 5.000, '2026-07-18 16:51:14', 5, 26, NULL, NULL),
  (131, 19, 'SAIDA_VENDA', 6.000, '2026-07-19 01:59:27', 5, 27, NULL, NULL),
  (132, 54, 'ENTRADA_PRODUCAO', 30.000, '2026-07-20 16:50:26', 8, NULL, NULL, 2),
  (133, 33, 'SAIDA_VENDA', 7.000, '2026-07-20 18:25:53', 5, 28, NULL, NULL),
  (134, 2, 'SAIDA_VENDA', 3.000, '2026-07-20 18:25:53', 5, 28, NULL, NULL),
  (135, 55, 'ENTRADA_PRODUCAO', 30.000, '2026-07-21 09:44:30', 8, NULL, NULL, 3),
  (136, 8, 'SAIDA_VENDA', 4.000, '2026-07-21 12:15:07', 6, 29, NULL, NULL),
  (137, 18, 'SAIDA_VENDA', 7.000, '2026-07-22 21:02:53', 6, 30, NULL, NULL),
  (138, 8, 'SAIDA_VENDA', 6.000, '2026-07-23 16:27:04', 6, 33, NULL, NULL),
  (139, 51, 'SAIDA_VENDA', 4.000, '2026-07-23 18:49:49', 6, 34, NULL, NULL),
  (140, 35, 'SAIDA_VENDA', 1.000, '2026-07-23 18:49:49', 6, 34, NULL, NULL),
  (141, 14, 'SAIDA_VENDA', 4.000, '2026-07-23 18:49:49', 6, 34, NULL, NULL),
  (142, 34, 'SAIDA_VENDA', 7.000, '2026-07-23 18:49:49', 6, 34, NULL, NULL),
  (143, 42, 'SAIDA_VENDA', 6.000, '2026-07-23 18:49:49', 6, 34, NULL, NULL),
  (144, 28, 'SAIDA_VENDA', 1.000, '2026-07-23 20:20:22', 6, 32, NULL, NULL),
  (145, 3, 'SAIDA_VENDA', 5.000, '2026-07-23 20:20:22', 6, 32, NULL, NULL),
  (146, 26, 'SAIDA_VENDA', 3.000, '2026-07-23 20:20:22', 6, 32, NULL, NULL),
  (147, 19, 'SAIDA_VENDA', 8.000, '2026-07-23 21:21:51', 5, 31, NULL, NULL),
  (148, 47, 'SAIDA_VENDA', 25.000, '2026-07-23 21:21:51', 5, 31, NULL, NULL),
  (149, 55, 'ENTRADA_PRODUCAO', 60.000, '2026-07-24 08:36:17', 8, NULL, NULL, 4),
  (150, 15, 'SAIDA_VENDA', 6.000, '2026-07-24 18:18:40', 6, 35, NULL, NULL),
  (151, 36, 'SAIDA_VENDA', 8.000, '2026-07-24 18:18:40', 6, 35, NULL, NULL),
  (152, 58, 'SAIDA_VENDA', 20.000, '2026-07-24 18:18:40', 6, 35, NULL, NULL),
  (153, 28, 'SAIDA_VENDA', 5.000, '2026-07-25 03:16:49', 6, 36, NULL, NULL),
  (154, 54, 'ENTRADA_PRODUCAO', 90.000, '2026-07-25 15:42:32', 8, NULL, NULL, 5),
  (155, 36, 'SAIDA_VENDA', 1.000, '2026-07-27 19:21:51', 6, 40, NULL, NULL),
  (156, 11, 'SAIDA_VENDA', 6.000, '2026-07-27 19:21:51', 6, 40, NULL, NULL),
  (157, 53, 'SAIDA_VENDA', 5.000, '2026-07-27 19:21:51', 6, 40, NULL, NULL),
  (158, 34, 'SAIDA_VENDA', 8.000, '2026-07-28 01:20:55', 6, 37, NULL, NULL),
  (159, 2, 'SAIDA_VENDA', 6.000, '2026-07-28 01:20:55', 6, 37, NULL, NULL),
  (160, 46, 'SAIDA_VENDA', 5.000, '2026-07-28 01:20:55', 6, 37, NULL, NULL),
  (161, 48, 'SAIDA_VENDA', 12.000, '2026-07-28 06:39:59', 6, 39, NULL, NULL),
  (162, 3, 'SAIDA_VENDA', 6.000, '2026-07-28 06:39:59', 6, 39, NULL, NULL),
  (163, 40, 'SAIDA_VENDA', 9.000, '2026-07-28 07:59:03', 6, 42, NULL, NULL),
  (164, 29, 'SAIDA_VENDA', 4.000, '2026-07-28 08:58:41', 5, 41, NULL, NULL),
  (165, 46, 'SAIDA_VENDA', 4.000, '2026-07-28 08:58:41', 5, 41, NULL, NULL),
  (166, 52, 'ENTRADA_PRODUCAO', 120.000, '2026-07-28 09:26:09', 8, NULL, NULL, 6),
  (167, 49, 'SAIDA_VENDA', 12.000, '2026-07-29 04:31:27', 5, 44, NULL, NULL),
  (168, 36, 'SAIDA_VENDA', 8.000, '2026-07-29 04:31:27', 5, 44, NULL, NULL),
  (169, 28, 'SAIDA_VENDA', 6.000, '2026-07-29 04:31:27', 5, 44, NULL, NULL),
  (170, 32, 'SAIDA_VENDA', 5.000, '2026-07-29 04:31:27', 5, 44, NULL, NULL),
  (171, 6, 'SAIDA_VENDA', 8.000, '2026-07-29 05:06:54', 6, 45, NULL, NULL),
  (172, 15, 'SAIDA_VENDA', 5.000, '2026-07-29 05:06:54', 6, 45, NULL, NULL),
  (173, 48, 'SAIDA_VENDA', 10.000, '2026-07-29 23:13:53', 5, 46, NULL, NULL),
  (174, 38, 'SAIDA_VENDA', 2.000, '2026-07-29 23:13:53', 5, 46, NULL, NULL),
  (175, 32, 'SAIDA_VENDA', 8.000, '2026-07-30 06:59:31', 6, 47, NULL, NULL),
  (176, 2, 'SAIDA_VENDA', 1.000, '2026-07-30 06:59:31', 6, 47, NULL, NULL),
  (177, 5, 'ENTRADA_COMPRA', 30.000, '2026-07-31 13:51:19', 7, NULL, 3, NULL),
  (178, 8, 'ENTRADA_COMPRA', 120.000, '2026-07-31 13:51:19', 7, NULL, 3, NULL),
  (179, 13, 'ENTRADA_COMPRA', 120.000, '2026-07-31 13:51:19', 7, NULL, 3, NULL),
  (180, 14, 'ENTRADA_COMPRA', 30.000, '2026-07-31 13:51:19', 7, NULL, 3, NULL);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_movimentacao, id_produto, tipo_movimentacao, quantidade, data_hora, id_funcionario, id_pedido, id_recebimento, id_ordem_producao) VALUES
  (181, 7, 'ENTRADA_COMPRA', 80.000, '2026-07-31 13:51:19', 7, NULL, 3, NULL),
  (182, 54, 'SAIDA_VENDA', 12.000, '2026-07-31 15:34:52', 6, 48, NULL, NULL),
  (183, 43, 'SAIDA_VENDA', 2.000, '2026-07-31 15:34:52', 6, 48, NULL, NULL),
  (184, 34, 'SAIDA_VENDA', 5.000, '2026-08-01 04:09:40', 6, 49, NULL, NULL),
  (185, 25, 'SAIDA_VENDA', 2.000, '2026-08-01 04:09:40', 6, 49, NULL, NULL),
  (186, 49, 'SAIDA_VENDA', 12.000, '2026-08-01 04:09:40', 6, 49, NULL, NULL),
  (187, 18, 'SAIDA_VENDA', 8.000, '2026-08-01 04:09:40', 6, 49, NULL, NULL),
  (188, 30, 'SAIDA_VENDA', 1.000, '2026-08-01 18:30:34', 5, 51, NULL, NULL),
  (189, 46, 'SAIDA_VENDA', 4.000, '2026-08-01 19:06:33', 5, 52, NULL, NULL),
  (190, 59, 'SAIDA_VENDA', 2.000, '2026-08-01 19:06:33', 5, 52, NULL, NULL),
  (191, 48, 'SAIDA_VENDA', 10.000, '2026-08-01 21:18:51', 6, 53, NULL, NULL),
  (192, 33, 'SAIDA_VENDA', 7.000, '2026-08-01 21:18:51', 6, 53, NULL, NULL),
  (193, 6, 'SAIDA_VENDA', 1.000, '2026-08-01 21:18:51', 6, 53, NULL, NULL),
  (194, 21, 'SAIDA_VENDA', 4.000, '2026-08-02 06:58:46', 5, 50, NULL, NULL),
  (195, 24, 'SAIDA_VENDA', 2.000, '2026-08-02 06:58:46', 5, 50, NULL, NULL),
  (196, 47, 'SAIDA_VENDA', 20.000, '2026-08-02 06:58:46', 5, 50, NULL, NULL),
  (197, 41, 'SAIDA_VENDA', 4.000, '2026-08-02 06:58:46', 5, 50, NULL, NULL),
  (198, 31, 'SAIDA_VENDA', 1.000, '2026-08-03 16:55:47', 5, 56, NULL, NULL),
  (199, 9, 'SAIDA_VENDA', 5.000, '2026-08-03 16:55:47', 5, 56, NULL, NULL),
  (200, 34, 'SAIDA_VENDA', 3.000, '2026-08-03 16:55:47', 5, 56, NULL, NULL),
  (201, 44, 'SAIDA_VENDA', 5.000, '2026-08-03 21:51:30', 5, 55, NULL, NULL),
  (202, 18, 'SAIDA_VENDA', 8.000, '2026-08-03 21:51:30', 5, 55, NULL, NULL),
  (203, 15, 'SAIDA_VENDA', 7.000, '2026-08-03 21:51:30', 5, 55, NULL, NULL),
  (204, 3, 'SAIDA_VENDA', 4.000, '2026-08-04 02:45:12', 5, 54, NULL, NULL),
  (205, 52, 'SAIDA_VENDA', 5.000, '2026-08-04 02:45:12', 5, 54, NULL, NULL),
  (206, 30, 'SAIDA_VENDA', 6.000, '2026-08-04 02:45:12', 5, 54, NULL, NULL),
  (207, 42, 'SAIDA_VENDA', 5.000, '2026-08-04 08:48:26', 6, 57, NULL, NULL),
  (208, 12, 'SAIDA_VENDA', 5.000, '2026-08-04 08:48:26', 6, 57, NULL, NULL),
  (209, 29, 'SAIDA_VENDA', 8.000, '2026-08-04 08:48:26', 6, 57, NULL, NULL),
  (210, 37, 'SAIDA_VENDA', 5.000, '2026-08-04 08:48:26', 6, 57, NULL, NULL),
  (211, 57, 'SAIDA_VENDA', 9.000, '2026-08-05 07:36:32', 6, 58, NULL, NULL),
  (212, 25, 'ENTRADA_COMPRA', 20.000, '2026-08-06 11:08:14', 7, NULL, 4, NULL),
  (213, 31, 'ENTRADA_COMPRA', 100.000, '2026-08-06 11:08:14', 7, NULL, 4, NULL),
  (214, 52, 'ENTRADA_PRODUCAO', 60.000, '2026-08-06 12:12:25', 8, NULL, NULL, 7),
  (215, 15, 'SAIDA_VENDA', 3.000, '2026-08-06 13:41:43', 6, 59, NULL, NULL),
  (216, 9, 'SAIDA_VENDA', 8.000, '2026-08-06 13:41:43', 6, 59, NULL, NULL),
  (217, 42, 'SAIDA_VENDA', 2.000, '2026-08-06 13:41:43', 6, 59, NULL, NULL),
  (218, 11, 'SAIDA_VENDA', 5.000, '2026-08-07 22:46:52', 6, 60, NULL, NULL),
  (219, 55, 'SAIDA_VENDA', 9.000, '2026-08-07 22:46:52', 6, 60, NULL, NULL),
  (220, 24, 'SAIDA_VENDA', 6.000, '2026-08-07 22:46:52', 6, 60, NULL, NULL),
  (221, 60, 'SAIDA_VENDA', 2.000, '2026-08-07 22:46:52', 6, 60, NULL, NULL),
  (222, 27, 'SAIDA_VENDA', 1.000, '2026-08-08 10:24:11', 5, 61, NULL, NULL),
  (223, 39, 'SAIDA_VENDA', 6.000, '2026-08-08 10:24:11', 5, 61, NULL, NULL),
  (224, 42, 'SAIDA_VENDA', 3.000, '2026-08-09 05:10:16', 6, 62, NULL, NULL),
  (225, 29, 'ENTRADA_COMPRA', 33.500, '2026-08-09 14:58:31', 7, NULL, 5, NULL),
  (226, 25, 'ENTRADA_COMPRA', 33.500, '2026-08-09 14:58:31', 7, NULL, 5, NULL),
  (227, 31, 'ENTRADA_COMPRA', 40.200, '2026-08-09 14:58:31', 7, NULL, 5, NULL),
  (228, 36, 'ENTRADA_COMPRA', 53.600, '2026-08-09 14:58:31', 7, NULL, 5, NULL),
  (229, 23, 'ENTRADA_COMPRA', 20.100, '2026-08-09 14:58:31', 7, NULL, 5, NULL),
  (230, 44, 'ENTRADA_COMPRA', 50.000, '2026-08-10 11:28:53', 7, NULL, 6, NULL),
  (231, 45, 'ENTRADA_COMPRA', 25.000, '2026-08-10 11:28:53', 7, NULL, 6, NULL),
  (232, 40, 'ENTRADA_COMPRA', 10.000, '2026-08-10 11:28:53', 7, NULL, 6, NULL),
  (233, 42, 'ENTRADA_COMPRA', 30.000, '2026-08-10 11:28:53', 7, NULL, 6, NULL),
  (234, 46, 'ENTRADA_COMPRA', 25.000, '2026-08-10 11:28:53', 7, NULL, 6, NULL),
  (235, 37, 'SAIDA_VENDA', 6.000, '2026-08-10 21:40:48', 6, 66, NULL, NULL),
  (236, 59, 'SAIDA_VENDA', 2.000, '2026-08-10 21:40:48', 6, 66, NULL, NULL),
  (237, 7, 'SAIDA_VENDA', 2.000, '2026-08-10 22:34:24', 5, 65, NULL, NULL),
  (238, 57, 'SAIDA_VENDA', 5.000, '2026-08-10 23:12:18', 6, 63, NULL, NULL),
  (239, 17, 'SAIDA_VENDA', 2.000, '2026-08-10 23:12:18', 6, 63, NULL, NULL),
  (240, 27, 'SAIDA_VENDA', 5.000, '2026-08-11 07:08:26', 5, 64, NULL, NULL);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_movimentacao, id_produto, tipo_movimentacao, quantidade, data_hora, id_funcionario, id_pedido, id_recebimento, id_ordem_producao) VALUES
  (241, 20, 'SAIDA_VENDA', 7.000, '2026-08-11 07:08:26', 5, 64, NULL, NULL),
  (242, 38, 'SAIDA_VENDA', 2.000, '2026-08-12 08:35:01', 6, 67, NULL, NULL),
  (243, 44, 'SAIDA_VENDA', 6.000, '2026-08-12 08:35:01', 6, 67, NULL, NULL),
  (244, 60, 'ENTRADA_PRODUCAO', 10.000, '2026-08-12 11:45:46', 8, NULL, NULL, 8),
  (245, 48, 'ENTRADA_COMPRA', 30.000, '2026-08-12 18:41:35', 7, NULL, 8, NULL),
  (246, 47, 'ENTRADA_COMPRA', 30.000, '2026-08-12 18:41:35', 7, NULL, 8, NULL),
  (247, 49, 'ENTRADA_COMPRA', 30.000, '2026-08-12 18:41:35', 7, NULL, 8, NULL),
  (248, 38, 'SAIDA_VENDA', 8.000, '2026-08-13 09:11:23', 5, 68, NULL, NULL),
  (249, 51, 'SAIDA_VENDA', 4.000, '2026-08-13 11:22:00', 5, 69, NULL, NULL),
  (250, 59, 'SAIDA_VENDA', 1.000, '2026-08-15 02:27:23', 5, 70, NULL, NULL),
  (251, 27, 'SAIDA_VENDA', 8.000, '2026-08-15 02:27:23', 5, 70, NULL, NULL),
  (252, 31, 'SAIDA_VENDA', 6.000, '2026-08-15 02:27:23', 5, 70, NULL, NULL),
  (253, 60, 'SAIDA_VENDA', 1.000, '2026-08-15 14:32:09', 5, 71, NULL, NULL),
  (254, 58, 'SAIDA_VENDA', 3.000, '2026-08-15 14:32:09', 5, 71, NULL, NULL),
  (255, 25, 'SAIDA_VENDA', 4.000, '2026-08-15 14:32:09', 5, 71, NULL, NULL),
  (256, 48, 'ENTRADA_COMPRA', 30.000, '2026-08-16 22:41:35', 7, NULL, 9, NULL),
  (257, 47, 'ENTRADA_COMPRA', 30.000, '2026-08-16 22:41:35', 7, NULL, 9, NULL),
  (258, 49, 'ENTRADA_COMPRA', 30.000, '2026-08-16 22:41:35', 7, NULL, 9, NULL),
  (259, 4, 'SAIDA_VENDA', 5.000, '2026-08-17 12:40:22', 5, 73, NULL, NULL),
  (260, 47, 'SAIDA_VENDA', 15.000, '2026-08-17 12:40:22', 5, 73, NULL, NULL),
  (261, 50, 'SAIDA_VENDA', 5.000, '2026-08-17 12:40:22', 5, 73, NULL, NULL),
  (262, 60, 'SAIDA_VENDA', 1.000, '2026-08-17 12:40:22', 5, 73, NULL, NULL),
  (263, 38, 'SAIDA_VENDA', 5.000, '2026-08-17 20:19:28', 5, 72, NULL, NULL),
  (264, 2, 'SAIDA_VENDA', 4.000, '2026-08-17 20:19:28', 5, 72, NULL, NULL),
  (265, 44, 'ENTRADA_COMPRA', 50.000, '2026-08-18 14:28:53', 7, NULL, 7, NULL),
  (266, 45, 'ENTRADA_COMPRA', 25.000, '2026-08-18 14:28:53', 7, NULL, 7, NULL),
  (267, 40, 'ENTRADA_COMPRA', 10.000, '2026-08-18 14:28:53', 7, NULL, 7, NULL),
  (268, 42, 'ENTRADA_COMPRA', 30.000, '2026-08-18 14:28:53', 7, NULL, 7, NULL),
  (269, 46, 'ENTRADA_COMPRA', 25.000, '2026-08-18 14:28:53', 7, NULL, 7, NULL),
  (270, 23, 'SAIDA_VENDA', 5.000, '2026-08-18 17:10:01', 5, 74, NULL, NULL),
  (271, 30, 'SAIDA_VENDA', 5.000, '2026-08-18 17:10:01', 5, 74, NULL, NULL),
  (272, 40, 'SAIDA_VENDA', 10.000, '2026-08-18 17:10:01', 5, 74, NULL, NULL),
  (273, 2, 'SAIDA_VENDA', 5.000, '2026-08-18 17:10:01', 5, 74, NULL, NULL),
  (274, 57, 'SAIDA_VENDA', 5.000, '2026-08-18 17:10:01', 5, 74, NULL, NULL),
  (275, 8, 'SAIDA_VENDA', 7.000, '2026-08-20 23:39:25', 6, 75, NULL, NULL),
  (276, 40, 'SAIDA_VENDA', 1.000, '2026-08-21 11:02:31', 5, 76, NULL, NULL),
  (277, 27, 'SAIDA_VENDA', 3.000, '2026-08-21 11:02:31', 5, 76, NULL, NULL),
  (278, 19, 'SAIDA_VENDA', 5.000, '2026-08-22 02:47:13', 5, 78, NULL, NULL),
  (279, 43, 'SAIDA_VENDA', 6.000, '2026-08-22 03:29:02', 6, 77, NULL, NULL),
  (280, 5, 'SAIDA_VENDA', 8.000, '2026-08-22 03:29:02', 6, 77, NULL, NULL),
  (281, 17, 'SAIDA_VENDA', 1.000, '2026-08-22 13:26:10', 5, 79, NULL, NULL),
  (282, 24, 'SAIDA_VENDA', 6.000, '2026-08-22 13:26:10', 5, 79, NULL, NULL),
  (283, 53, 'SAIDA_VENDA', 20.000, '2026-08-22 13:26:10', 5, 79, NULL, NULL),
  (284, 46, 'SAIDA_VENDA', 2.000, '2026-08-22 13:26:10', 5, 79, NULL, NULL),
  (285, 21, 'SAIDA_VENDA', 7.000, '2026-08-22 13:26:10', 5, 79, NULL, NULL),
  (286, 45, 'SAIDA_VENDA', 6.000, '2026-08-26 14:54:41', 5, 81, NULL, NULL),
  (287, 24, 'SAIDA_VENDA', 3.000, '2026-08-26 14:54:41', 5, 81, NULL, NULL),
  (288, 3, 'SAIDA_VENDA', 2.000, '2026-08-26 14:54:41', 5, 81, NULL, NULL),
  (289, 50, 'SAIDA_VENDA', 3.000, '2026-08-26 19:35:36', 5, 80, NULL, NULL),
  (290, 49, 'SAIDA_VENDA', 8.000, '2026-08-26 19:35:36', 5, 80, NULL, NULL),
  (291, 23, 'SAIDA_VENDA', 7.000, '2026-08-26 19:35:36', 5, 80, NULL, NULL),
  (292, 51, 'SAIDA_VENDA', 2.000, '2026-08-26 19:35:36', 5, 80, NULL, NULL),
  (293, 59, 'SAIDA_VENDA', 3.000, '2026-08-26 19:35:36', 5, 80, NULL, NULL),
  (294, 60, 'SAIDA_VENDA', 1.000, '2026-08-27 14:10:51', 6, 82, NULL, NULL),
  (295, 5, 'SAIDA_VENDA', 3.000, '2026-08-27 14:10:51', 6, 82, NULL, NULL),
  (296, 36, 'SAIDA_VENDA', 5.000, '2026-08-27 14:10:51', 6, 82, NULL, NULL),
  (297, 39, 'SAIDA_VENDA', 1.000, '2026-08-27 14:10:51', 6, 82, NULL, NULL),
  (298, 55, 'ENTRADA_PRODUCAO', 120.000, '2026-08-28 09:30:44', 8, NULL, NULL, 10),
  (299, 13, 'SAIDA_VENDA', 1.000, '2026-08-30 05:58:25', 6, 83, NULL, NULL),
  (300, 58, 'SAIDA_VENDA', 15.000, '2026-08-30 05:58:25', 6, 83, NULL, NULL);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_movimentacao, id_produto, tipo_movimentacao, quantidade, data_hora, id_funcionario, id_pedido, id_recebimento, id_ordem_producao) VALUES
  (301, 23, 'SAIDA_VENDA', 1.000, '2026-08-30 05:58:25', 6, 83, NULL, NULL),
  (302, 53, 'SAIDA_VENDA', 12.000, '2026-08-30 05:58:25', 6, 83, NULL, NULL),
  (303, 47, 'ENTRADA_COMPRA', 60.000, '2026-08-31 16:20:35', 7, NULL, 10, NULL),
  (304, 49, 'ENTRADA_COMPRA', 60.000, '2026-08-31 16:20:35', 7, NULL, 10, NULL),
  (305, 48, 'ENTRADA_COMPRA', 80.000, '2026-08-31 16:20:35', 7, NULL, 10, NULL),
  (306, 7, 'SAIDA_VENDA', 5.000, '2026-09-01 01:56:07', 6, 84, NULL, NULL),
  (307, 29, 'SAIDA_VENDA', 8.000, '2026-09-01 01:56:07', 6, 84, NULL, NULL),
  (308, 40, 'SAIDA_VENDA', 9.000, '2026-09-01 01:56:07', 6, 84, NULL, NULL),
  (309, 8, 'SAIDA_VENDA', 8.000, '2026-09-01 13:28:07', 5, 85, NULL, NULL),
  (310, 50, 'SAIDA_VENDA', 2.000, '2026-09-01 13:28:07', 5, 85, NULL, NULL),
  (311, 33, 'SAIDA_VENDA', 7.000, '2026-09-01 13:28:07', 5, 85, NULL, NULL),
  (312, 2, 'SAIDA_VENDA', 1.000, '2026-09-01 13:28:07', 5, 85, NULL, NULL),
  (313, 42, 'SAIDA_VENDA', 5.000, '2026-09-01 18:18:51', 6, 86, NULL, NULL),
  (314, 17, 'SAIDA_VENDA', 3.000, '2026-09-02 19:46:18', 5, 87, NULL, NULL),
  (315, 56, 'ENTRADA_PRODUCAO', 30.000, '2026-09-04 17:34:17', 8, NULL, NULL, 11),
  (316, 14, 'SAIDA_VENDA', 6.000, '2026-09-05 11:37:54', 6, 89, NULL, NULL),
  (317, 28, 'SAIDA_VENDA', 2.000, '2026-09-05 11:37:54', 6, 89, NULL, NULL),
  (318, 23, 'SAIDA_VENDA', 8.000, '2026-09-05 11:37:54', 6, 89, NULL, NULL),
  (319, 55, 'SAIDA_VENDA', 15.000, '2026-09-05 16:38:57', 5, 90, NULL, NULL),
  (320, 15, 'SAIDA_VENDA', 8.000, '2026-09-05 16:38:57', 5, 90, NULL, NULL),
  (321, 24, 'SAIDA_VENDA', 8.000, '2026-09-06 04:49:13', 6, 91, NULL, NULL),
  (322, 45, 'SAIDA_VENDA', 1.000, '2026-09-06 04:49:13', 6, 91, NULL, NULL),
  (323, 39, 'ENTRADA_COMPRA', 18.500, '2026-09-06 16:57:49', 7, NULL, 12, NULL),
  (324, 38, 'ENTRADA_COMPRA', 29.600, '2026-09-06 16:57:49', 7, NULL, 12, NULL),
  (325, 37, 'ENTRADA_COMPRA', 7.400, '2026-09-06 16:57:49', 7, NULL, 12, NULL),
  (326, 37, 'SAIDA_VENDA', 1.000, '2026-09-08 01:04:24', 5, 92, NULL, NULL),
  (327, 23, 'SAIDA_VENDA', 7.000, '2026-09-08 01:04:24', 5, 92, NULL, NULL),
  (328, 25, 'ENTRADA_COMPRA', 120.000, '2026-09-08 13:35:26', 7, NULL, 11, NULL),
  (329, 29, 'ENTRADA_COMPRA', 50.000, '2026-09-08 13:35:26', 7, NULL, 11, NULL),
  (330, 10, 'SAIDA_VENDA', 6.000, '2026-09-08 21:26:31', 5, 93, NULL, NULL),
  (331, 30, 'SAIDA_VENDA', 5.000, '2026-09-08 21:26:31', 5, 93, NULL, NULL),
  (332, 48, 'SAIDA_VENDA', 10.000, '2026-09-08 21:26:31', 5, 93, NULL, NULL),
  (333, 15, 'SAIDA_VENDA', 7.000, '2026-09-10 02:33:56', 5, 95, NULL, NULL),
  (334, 30, 'SAIDA_VENDA', 7.000, '2026-09-10 02:33:56', 5, 95, NULL, NULL),
  (335, 5, 'SAIDA_VENDA', 3.000, '2026-09-10 04:11:17', 5, 94, NULL, NULL),
  (336, 27, 'SAIDA_VENDA', 1.000, '2026-09-10 04:11:17', 5, 94, NULL, NULL),
  (337, 37, 'SAIDA_VENDA', 5.000, '2026-09-10 17:51:26', 6, 99, NULL, NULL),
  (338, 1, 'SAIDA_VENDA', 5.000, '2026-09-10 17:51:26', 6, 99, NULL, NULL),
  (339, 50, 'SAIDA_VENDA', 5.000, '2026-09-10 17:51:26', 6, 99, NULL, NULL),
  (340, 60, 'SAIDA_VENDA', 7.000, '2026-09-10 23:24:19', 5, 96, NULL, NULL),
  (341, 53, 'SAIDA_VENDA', 5.000, '2026-09-10 23:24:19', 5, 96, NULL, NULL),
  (342, 11, 'SAIDA_VENDA', 8.000, '2026-09-11 04:49:38', 6, 98, NULL, NULL),
  (343, 5, 'SAIDA_VENDA', 3.000, '2026-09-11 04:49:38', 6, 98, NULL, NULL),
  (344, 23, 'SAIDA_VENDA', 4.000, '2026-09-11 04:49:38', 6, 98, NULL, NULL),
  (345, 24, 'SAIDA_VENDA', 8.000, '2026-09-11 05:10:27', 6, 97, NULL, NULL),
  (346, 35, 'SAIDA_VENDA', 7.000, '2026-09-11 05:10:27', 6, 97, NULL, NULL),
  (347, 28, 'SAIDA_VENDA', 2.000, '2026-09-11 05:10:27', 6, 97, NULL, NULL),
  (348, 40, 'SAIDA_VENDA', 3.000, '2026-09-11 05:10:27', 6, 97, NULL, NULL),
  (349, 55, 'ENTRADA_PRODUCAO', 60.000, '2026-09-11 14:01:29', 8, NULL, NULL, 12),
  (350, 12, 'SAIDA_VENDA', 3.000, '2026-09-11 16:59:14', 5, 100, NULL, NULL),
  (351, 58, 'SAIDA_VENDA', 5.000, '2026-09-11 16:59:14', 5, 100, NULL, NULL),
  (352, 21, 'SAIDA_VENDA', 4.000, '2026-09-11 16:59:14', 5, 100, NULL, NULL),
  (353, 2, 'SAIDA_VENDA', 6.000, '2026-09-11 17:04:56', 6, 101, NULL, NULL),
  (354, 58, 'SAIDA_VENDA', 12.000, '2026-09-11 17:04:56', 6, 101, NULL, NULL),
  (355, 49, 'SAIDA_VENDA', 10.000, '2026-09-11 17:04:56', 6, 101, NULL, NULL),
  (356, 22, 'SAIDA_VENDA', 8.000, '2026-09-12 17:30:23', 5, 102, NULL, NULL),
  (357, 30, 'SAIDA_VENDA', 8.000, '2026-09-12 17:30:23', 5, 102, NULL, NULL),
  (358, 32, 'SAIDA_VENDA', 4.000, '2026-09-14 14:36:12', 6, 104, NULL, NULL),
  (359, 12, 'SAIDA_VENDA', 1.000, '2026-09-14 17:53:00', 6, 105, NULL, NULL),
  (360, 36, 'ENTRADA_COMPRA', 50.000, '2026-09-16 15:37:18', 7, NULL, 13, NULL);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_movimentacao, id_produto, tipo_movimentacao, quantidade, data_hora, id_funcionario, id_pedido, id_recebimento, id_ordem_producao) VALUES
  (361, 33, 'ENTRADA_COMPRA', 20.000, '2026-09-16 15:37:18', 7, NULL, 13, NULL),
  (362, 32, 'ENTRADA_COMPRA', 80.000, '2026-09-16 15:37:18', 7, NULL, 13, NULL),
  (363, 22, 'ENTRADA_COMPRA', 20.000, '2026-09-16 15:37:18', 7, NULL, 13, NULL),
  (364, 54, 'ENTRADA_PRODUCAO', 30.000, '2026-09-17 08:42:14', 8, NULL, NULL, 13),
  (365, 19, 'SAIDA_VENDA', 5.000, '2026-09-18 20:26:15', 6, 107, NULL, NULL),
  (366, 51, 'SAIDA_VENDA', 4.000, '2026-09-18 22:16:49', 5, 108, NULL, NULL),
  (367, 29, 'SAIDA_VENDA', 6.000, '2026-09-18 22:16:49', 5, 108, NULL, NULL),
  (368, 10, 'SAIDA_VENDA', 4.000, '2026-09-18 22:16:49', 5, 108, NULL, NULL),
  (369, 40, 'SAIDA_VENDA', 3.000, '2026-09-19 05:10:45', 5, 106, NULL, NULL),
  (370, 36, 'SAIDA_VENDA', 6.000, '2026-09-19 05:10:45', 5, 106, NULL, NULL),
  (371, 48, 'SAIDA_VENDA', 25.000, '2026-09-21 21:09:48', 6, 110, NULL, NULL),
  (372, 2, 'SAIDA_VENDA', 6.000, '2026-09-22 09:44:53', 5, 111, NULL, NULL),
  (373, 23, 'ENTRADA_COMPRA', 20.400, '2026-09-22 12:55:21', 7, NULL, 14, NULL),
  (374, 36, 'ENTRADA_COMPRA', 20.400, '2026-09-22 12:55:21', 7, NULL, 14, NULL),
  (375, 48, 'SAIDA_VENDA', 10.000, '2026-09-22 19:25:57', 6, 112, NULL, NULL),
  (376, 58, 'SAIDA_VENDA', 20.000, '2026-09-22 19:25:57', 6, 112, NULL, NULL),
  (377, 18, 'SAIDA_VENDA', 7.000, '2026-09-22 19:25:57', 6, 112, NULL, NULL),
  (378, 42, 'SAIDA_VENDA', 8.000, '2026-09-22 19:25:57', 6, 112, NULL, NULL),
  (379, 23, 'SAIDA_VENDA', 2.000, '2026-09-22 19:25:57', 6, 112, NULL, NULL),
  (380, 54, 'ENTRADA_PRODUCAO', 120.000, '2026-09-23 09:32:45', 8, NULL, NULL, 14),
  (381, 37, 'ENTRADA_COMPRA', 68.000, '2026-09-24 16:37:06', 7, NULL, 15, NULL),
  (382, 39, 'ENTRADA_COMPRA', 81.600, '2026-09-24 16:37:06', 7, NULL, 15, NULL),
  (383, 38, 'ENTRADA_COMPRA', 81.600, '2026-09-24 16:37:06', 7, NULL, 15, NULL),
  (384, 2, 'SAIDA_VENDA', 8.000, '2026-09-24 18:45:40', 5, 113, NULL, NULL),
  (385, 13, 'SAIDA_VENDA', 5.000, '2026-09-24 18:45:40', 5, 113, NULL, NULL),
  (386, 45, 'SAIDA_VENDA', 9.000, '2026-09-25 19:49:19', 5, 115, NULL, NULL),
  (387, 51, 'SAIDA_VENDA', 1.000, '2026-09-25 19:49:19', 5, 115, NULL, NULL),
  (388, 43, 'SAIDA_VENDA', 8.000, '2026-09-28 16:01:04', 5, 116, NULL, NULL),
  (389, 48, 'SAIDA_VENDA', 20.000, '2026-09-28 16:01:04', 5, 116, NULL, NULL),
  (390, 45, 'ENTRADA_COMPRA', 100.000, '2026-09-28 18:53:04', 7, NULL, 16, NULL),
  (391, 40, 'ENTRADA_COMPRA', 120.000, '2026-09-28 18:53:04', 7, NULL, 16, NULL),
  (392, 43, 'ENTRADA_COMPRA', 30.000, '2026-09-28 18:53:04', 7, NULL, 16, NULL),
  (393, 42, 'ENTRADA_COMPRA', 120.000, '2026-09-28 18:53:04', 7, NULL, 16, NULL),
  (394, 21, 'SAIDA_VENDA', 3.000, '2026-09-29 04:28:38', 6, 117, NULL, NULL),
  (395, 33, 'SAIDA_VENDA', 3.000, '2026-09-29 04:28:38', 6, 117, NULL, NULL),
  (396, 21, 'SAIDA_VENDA', 2.000, '2026-09-29 14:09:40', 5, 120, NULL, NULL),
  (397, 54, 'SAIDA_VENDA', 20.000, '2026-09-29 14:09:40', 5, 120, NULL, NULL),
  (398, 50, 'SAIDA_VENDA', 2.000, '2026-09-29 14:09:40', 5, 120, NULL, NULL),
  (399, 12, 'SAIDA_VENDA', 6.000, '2026-09-29 14:09:40', 5, 120, NULL, NULL),
  (400, 60, 'SAIDA_VENDA', 1.000, '2026-09-29 14:09:40', 5, 120, NULL, NULL),
  (401, 22, 'SAIDA_VENDA', 4.000, '2026-09-29 21:01:48', 6, 118, NULL, NULL),
  (402, 50, 'SAIDA_VENDA', 1.000, '2026-09-29 21:01:48', 6, 118, NULL, NULL),
  (403, 29, 'SAIDA_VENDA', 7.000, '2026-09-29 21:32:46', 6, 119, NULL, NULL),
  (404, 28, 'SAIDA_VENDA', 5.000, '2026-09-29 21:32:46', 6, 119, NULL, NULL),
  (405, 45, 'SAIDA_VENDA', 3.000, '2026-09-29 21:32:46', 6, 119, NULL, NULL),
  (406, 43, 'SAIDA_VENDA', 1.000, '2026-09-29 21:32:55', 5, 121, NULL, NULL),
  (407, 47, 'SAIDA_VENDA', 6.000, '2026-09-29 21:32:55', 5, 121, NULL, NULL),
  (408, 55, 'SAIDA_VENDA', 15.000, '2026-09-30 13:09:01', 5, 123, NULL, NULL),
  (409, 56, 'SAIDA_VENDA', 20.000, '2026-09-30 13:09:01', 5, 123, NULL, NULL),
  (410, 25, 'SAIDA_VENDA', 3.000, '2026-09-30 17:11:16', 6, 124, NULL, NULL),
  (411, 4, 'SAIDA_VENDA', 1.000, '2026-09-30 17:11:16', 6, 124, NULL, NULL),
  (412, 34, 'SAIDA_VENDA', 4.000, '2026-09-30 17:11:16', 6, 124, NULL, NULL),
  (413, 55, 'SAIDA_VENDA', 15.000, '2026-09-30 17:11:16', 6, 124, NULL, NULL),
  (414, 37, 'SAIDA_VENDA', 2.000, '2026-09-30 17:11:16', 6, 124, NULL, NULL),
  (415, 36, 'SAIDA_VENDA', 8.000, '2026-10-01 11:09:52', 6, 125, NULL, NULL),
  (416, 26, 'SAIDA_VENDA', 3.000, '2026-10-02 19:27:29', 5, 126, NULL, NULL),
  (417, 18, 'SAIDA_VENDA', 2.000, '2026-10-02 19:27:29', 5, 126, NULL, NULL),
  (418, 57, 'SAIDA_VENDA', 30.000, '2026-10-02 22:53:47', 5, 127, NULL, NULL),
  (419, 16, 'SAIDA_VENDA', 4.000, '2026-10-02 22:53:47', 5, 127, NULL, NULL),
  (420, 13, 'SAIDA_VENDA', 1.000, '2026-10-02 22:53:47', 5, 127, NULL, NULL);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_movimentacao, id_produto, tipo_movimentacao, quantidade, data_hora, id_funcionario, id_pedido, id_recebimento, id_ordem_producao) VALUES
  (421, 15, 'SAIDA_VENDA', 8.000, '2026-10-02 22:53:47', 5, 127, NULL, NULL),
  (422, 44, 'SAIDA_VENDA', 2.000, '2026-10-03 01:50:19', 6, 128, NULL, NULL),
  (423, 31, 'SAIDA_VENDA', 4.000, '2026-10-03 01:50:19', 6, 128, NULL, NULL),
  (424, 48, 'SAIDA_VENDA', 25.000, '2026-10-03 01:50:19', 6, 128, NULL, NULL),
  (425, 43, 'SAIDA_VENDA', 2.000, '2026-10-03 14:18:20', 5, 130, NULL, NULL),
  (426, 4, 'SAIDA_VENDA', 2.000, '2026-10-03 14:18:20', 5, 130, NULL, NULL),
  (427, 15, 'SAIDA_VENDA', 8.000, '2026-10-03 14:18:20', 5, 130, NULL, NULL),
  (428, 59, 'ENTRADA_PRODUCAO', 20.000, '2026-10-03 16:02:16', 8, NULL, NULL, 15),
  (429, 49, 'SAIDA_VENDA', 25.000, '2026-10-04 05:35:10', 5, 129, NULL, NULL),
  (430, 31, 'SAIDA_VENDA', 3.000, '2026-10-04 05:35:10', 5, 129, NULL, NULL),
  (431, 15, 'SAIDA_VENDA', 5.000, '2026-10-04 05:35:10', 5, 129, NULL, NULL),
  (432, 44, 'SAIDA_VENDA', 1.000, '2026-10-04 11:06:33', 6, 131, NULL, NULL),
  (433, 28, 'SAIDA_VENDA', 4.000, '2026-10-04 11:06:33', 6, 131, NULL, NULL),
  (434, 59, 'SAIDA_VENDA', 6.000, '2026-10-04 11:06:33', 6, 131, NULL, NULL),
  (435, 35, 'SAIDA_VENDA', 8.000, '2026-10-06 02:13:58', 5, 134, NULL, NULL),
  (436, 22, 'SAIDA_VENDA', 6.000, '2026-10-06 02:13:58', 5, 134, NULL, NULL),
  (437, 20, 'SAIDA_VENDA', 7.000, '2026-10-06 02:13:58', 5, 134, NULL, NULL),
  (438, 24, 'SAIDA_VENDA', 4.000, '2026-10-06 02:13:58', 5, 134, NULL, NULL),
  (439, 9, 'SAIDA_VENDA', 7.000, '2026-10-06 02:13:58', 5, 134, NULL, NULL),
  (440, 50, 'SAIDA_VENDA', 4.000, '2026-10-06 03:44:08', 5, 132, NULL, NULL),
  (441, 25, 'SAIDA_VENDA', 2.000, '2026-10-06 03:44:08', 5, 132, NULL, NULL),
  (442, 53, 'SAIDA_VENDA', 15.000, '2026-10-06 03:44:08', 5, 132, NULL, NULL),
  (443, 50, 'SAIDA_VENDA', 8.000, '2026-10-06 05:58:49', 6, 133, NULL, NULL),
  (444, 21, 'SAIDA_VENDA', 5.000, '2026-10-06 05:58:49', 6, 133, NULL, NULL),
  (445, 53, 'SAIDA_VENDA', 9.000, '2026-10-06 05:58:49', 6, 133, NULL, NULL),
  (446, 24, 'SAIDA_VENDA', 8.000, '2026-10-08 05:54:28', 6, 135, NULL, NULL),
  (447, 19, 'SAIDA_VENDA', 6.000, '2026-10-08 05:54:28', 6, 135, NULL, NULL),
  (448, 42, 'SAIDA_VENDA', 7.000, '2026-10-08 05:54:28', 6, 135, NULL, NULL),
  (449, 55, 'SAIDA_VENDA', 15.000, '2026-10-08 05:54:28', 6, 135, NULL, NULL),
  (450, 21, 'SAIDA_VENDA', 1.000, '2026-10-08 05:54:28', 6, 135, NULL, NULL),
  (451, 32, 'SAIDA_VENDA', 4.000, '2026-10-08 07:13:53', 6, 136, NULL, NULL),
  (452, 18, 'SAIDA_VENDA', 1.000, '2026-10-08 17:52:42', 6, 137, NULL, NULL),
  (453, 55, 'SAIDA_VENDA', 15.000, '2026-10-09 12:29:54', 5, 138, NULL, NULL),
  (454, 16, 'SAIDA_VENDA', 5.000, '2026-10-09 12:29:54', 5, 138, NULL, NULL),
  (455, 41, 'ENTRADA_COMPRA', 15.000, '2026-10-09 14:45:56', 7, NULL, 20, NULL),
  (456, 42, 'ENTRADA_COMPRA', 60.000, '2026-10-09 14:45:56', 7, NULL, 20, NULL),
  (457, 45, 'ENTRADA_COMPRA', 60.000, '2026-10-09 14:45:56', 7, NULL, 20, NULL),
  (458, 44, 'ENTRADA_COMPRA', 25.000, '2026-10-09 14:45:56', 7, NULL, 20, NULL),
  (459, 43, 'ENTRADA_COMPRA', 15.000, '2026-10-09 14:45:56', 7, NULL, 20, NULL),
  (460, 41, 'SAIDA_VENDA', 2.000, '2026-10-09 16:27:59', 6, 139, NULL, NULL),
  (461, 51, 'SAIDA_VENDA', 2.000, '2026-10-09 16:27:59', 6, 139, NULL, NULL),
  (462, 55, 'SAIDA_VENDA', 3.000, '2026-10-09 16:27:59', 6, 139, NULL, NULL),
  (463, 49, 'ENTRADA_COMPRA', 60.000, '2026-10-09 19:51:03', 7, NULL, 19, NULL),
  (464, 47, 'ENTRADA_COMPRA', 40.000, '2026-10-09 19:51:03', 7, NULL, 19, NULL),
  (465, 48, 'ENTRADA_COMPRA', 20.000, '2026-10-09 19:51:03', 7, NULL, 19, NULL),
  (466, 30, 'SAIDA_VENDA', 8.000, '2026-10-10 07:11:50', 5, 140, NULL, NULL),
  (467, 46, 'SAIDA_VENDA', 4.000, '2026-10-10 07:11:50', 5, 140, NULL, NULL),
  (468, 5, 'ENTRADA_COMPRA', 100.000, '2026-10-10 12:49:49', 7, NULL, 17, NULL),
  (469, 2, 'ENTRADA_COMPRA', 100.000, '2026-10-10 12:49:49', 7, NULL, 17, NULL),
  (470, 11, 'ENTRADA_COMPRA', 80.000, '2026-10-10 12:49:49', 7, NULL, 17, NULL),
  (471, 2, 'SAIDA_VENDA', 8.000, '2026-10-10 17:49:38', 5, 141, NULL, NULL),
  (472, 6, 'SAIDA_VENDA', 6.000, '2026-10-10 17:49:38', 5, 141, NULL, NULL),
  (473, 8, 'SAIDA_VENDA', 2.000, '2026-10-10 17:49:38', 5, 141, NULL, NULL),
  (474, 27, 'SAIDA_VENDA', 7.000, '2026-10-11 01:49:21', 6, 142, NULL, NULL),
  (475, 46, 'SAIDA_VENDA', 6.000, '2026-10-11 01:49:21', 6, 142, NULL, NULL),
  (476, 23, 'SAIDA_VENDA', 2.000, '2026-10-11 01:49:21', 6, 142, NULL, NULL),
  (477, 16, 'SAIDA_VENDA', 4.000, '2026-10-12 12:50:26', 6, 143, NULL, NULL),
  (478, 9, 'SAIDA_VENDA', 7.000, '2026-10-12 12:50:26', 6, 143, NULL, NULL),
  (479, 28, 'SAIDA_VENDA', 2.000, '2026-10-12 12:50:26', 6, 143, NULL, NULL),
  (480, 20, 'SAIDA_VENDA', 7.000, '2026-10-12 12:50:26', 6, 143, NULL, NULL);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_movimentacao, id_produto, tipo_movimentacao, quantidade, data_hora, id_funcionario, id_pedido, id_recebimento, id_ordem_producao) VALUES
  (481, 7, 'SAIDA_VENDA', 1.000, '2026-10-12 16:28:06', 5, 148, NULL, NULL),
  (482, 24, 'SAIDA_VENDA', 4.000, '2026-10-12 16:28:06', 5, 148, NULL, NULL),
  (483, 28, 'SAIDA_VENDA', 3.000, '2026-10-12 16:28:06', 5, 148, NULL, NULL),
  (484, 49, 'ENTRADA_COMPRA', 60.000, '2026-10-12 17:51:03', 7, NULL, 18, NULL),
  (485, 47, 'ENTRADA_COMPRA', 40.000, '2026-10-12 17:51:03', 7, NULL, 18, NULL),
  (486, 48, 'ENTRADA_COMPRA', 20.000, '2026-10-12 17:51:03', 7, NULL, 18, NULL),
  (487, 45, 'SAIDA_VENDA', 6.000, '2026-10-12 18:11:20', 6, 146, NULL, NULL),
  (488, 15, 'SAIDA_VENDA', 6.000, '2026-10-12 18:11:20', 6, 146, NULL, NULL),
  (489, 5, 'SAIDA_VENDA', 4.000, '2026-10-12 22:09:16', 6, 150, NULL, NULL),
  (490, 11, 'SAIDA_VENDA', 2.000, '2026-10-12 22:09:16', 6, 150, NULL, NULL),
  (491, 15, 'SAIDA_VENDA', 8.000, '2026-10-13 01:02:39', 5, 144, NULL, NULL),
  (492, 19, 'SAIDA_VENDA', 6.000, '2026-10-13 01:02:39', 5, 144, NULL, NULL),
  (493, 27, 'SAIDA_VENDA', 8.000, '2026-10-13 01:02:39', 5, 144, NULL, NULL),
  (494, 12, 'SAIDA_VENDA', 7.000, '2026-10-13 02:12:05', 6, 149, NULL, NULL),
  (495, 30, 'SAIDA_VENDA', 6.000, '2026-10-13 02:12:05', 6, 149, NULL, NULL),
  (496, 33, 'SAIDA_VENDA', 4.000, '2026-10-13 02:12:05', 6, 149, NULL, NULL),
  (497, 40, 'SAIDA_VENDA', 7.000, '2026-10-13 02:12:05', 6, 149, NULL, NULL),
  (498, 49, 'SAIDA_VENDA', 8.000, '2026-10-13 02:38:24', 5, 145, NULL, NULL),
  (499, 4, 'SAIDA_VENDA', 8.000, '2026-10-13 03:43:29', 5, 147, NULL, NULL),
  (500, 51, 'SAIDA_VENDA', 4.000, '2026-10-13 03:43:29', 5, 147, NULL, NULL),
  (501, 24, 'SAIDA_VENDA', 7.000, '2026-10-13 17:01:20', 5, 153, NULL, NULL),
  (502, 26, 'SAIDA_VENDA', 3.000, '2026-10-13 17:01:20', 5, 153, NULL, NULL),
  (503, 47, 'SAIDA_VENDA', 10.000, '2026-10-13 21:54:36', 5, 151, NULL, NULL),
  (504, 20, 'SAIDA_VENDA', 2.000, '2026-10-14 01:05:01', 5, 152, NULL, NULL),
  (505, 35, 'SAIDA_VENDA', 1.000, '2026-10-14 01:05:01', 5, 152, NULL, NULL),
  (506, 51, 'SAIDA_VENDA', 1.000, '2026-10-17 06:23:27', 6, 154, NULL, NULL),
  (507, 57, 'SAIDA_VENDA', 12.000, '2026-10-17 14:07:13', 5, 157, NULL, NULL),
  (508, 21, 'SAIDA_VENDA', 1.000, '2026-10-17 21:40:11', 6, 155, NULL, NULL),
  (509, 11, 'SAIDA_VENDA', 6.000, '2026-10-17 21:40:11', 6, 155, NULL, NULL),
  (510, 33, 'SAIDA_VENDA', 8.000, '2026-10-17 21:40:11', 6, 155, NULL, NULL),
  (511, 42, 'SAIDA_VENDA', 3.000, '2026-10-18 02:07:27', 5, 156, NULL, NULL),
  (512, 13, 'SAIDA_VENDA', 2.000, '2026-10-18 11:45:24', 5, 158, NULL, NULL),
  (513, 50, 'SAIDA_VENDA', 1.000, '2026-10-18 11:45:24', 5, 158, NULL, NULL),
  (514, 10, 'SAIDA_VENDA', 2.000, '2026-10-18 11:45:24', 5, 158, NULL, NULL),
  (515, 1, 'SAIDA_VENDA', 2.000, '2026-10-18 11:45:24', 5, 158, NULL, NULL),
  (516, 41, 'SAIDA_VENDA', 3.000, '2026-10-18 11:45:24', 5, 158, NULL, NULL),
  (517, 52, 'ENTRADA_PRODUCAO', 90.000, '2026-10-19 10:31:13', 8, NULL, NULL, 16),
  (518, 53, 'SAIDA_VENDA', 30.000, '2026-10-19 15:23:54', 5, 159, NULL, NULL),
  (519, 28, 'SAIDA_VENDA', 5.000, '2026-10-19 15:23:54', 5, 159, NULL, NULL),
  (520, 53, 'SAIDA_VENDA', 15.000, '2026-10-19 17:24:26', 5, 160, NULL, NULL),
  (521, 34, 'SAIDA_VENDA', 8.000, '2026-10-19 17:24:26', 5, 160, NULL, NULL),
  (522, 13, 'SAIDA_VENDA', 4.000, '2026-10-19 23:44:15', 5, 161, NULL, NULL),
  (523, 44, 'SAIDA_VENDA', 8.000, '2026-10-19 23:44:15', 5, 161, NULL, NULL),
  (524, 26, 'SAIDA_VENDA', 7.000, '2026-10-20 11:31:58', 5, 162, NULL, NULL),
  (525, 49, 'ENTRADA_COMPRA', 20.000, '2026-10-20 19:56:42', 7, NULL, 22, NULL),
  (526, 48, 'ENTRADA_COMPRA', 30.000, '2026-10-20 19:56:42', 7, NULL, 22, NULL),
  (527, 47, 'ENTRADA_COMPRA', 60.000, '2026-10-20 19:56:42', 7, NULL, 22, NULL),
  (528, 48, 'SAIDA_VENDA', 20.000, '2026-10-21 06:59:28', 6, 163, NULL, NULL),
  (529, 5, 'SAIDA_VENDA', 7.000, '2026-10-21 06:59:28', 6, 163, NULL, NULL),
  (530, 37, 'SAIDA_VENDA', 4.000, '2026-10-21 06:59:28', 6, 163, NULL, NULL),
  (531, 57, 'SAIDA_VENDA', 9.000, '2026-10-23 17:18:18', 6, 165, NULL, NULL),
  (532, 34, 'SAIDA_VENDA', 4.000, '2026-10-23 22:04:59', 5, 166, NULL, NULL),
  (533, 57, 'SAIDA_VENDA', 12.000, '2026-10-23 22:04:59', 5, 166, NULL, NULL),
  (534, 13, 'SAIDA_VENDA', 2.000, '2026-10-24 13:53:22', 5, 167, NULL, NULL),
  (535, 11, 'SAIDA_VENDA', 3.000, '2026-10-24 13:53:22', 5, 167, NULL, NULL),
  (536, 20, 'SAIDA_VENDA', 1.000, '2026-10-25 06:24:59', 5, 168, NULL, NULL),
  (537, 37, 'SAIDA_VENDA', 4.000, '2026-10-25 12:30:50', 5, 169, NULL, NULL),
  (538, 18, 'SAIDA_VENDA', 8.000, '2026-10-25 12:30:50', 5, 169, NULL, NULL),
  (539, 41, 'ENTRADA_COMPRA', 15.000, '2026-10-25 14:45:56', 7, NULL, 21, NULL),
  (540, 42, 'ENTRADA_COMPRA', 60.000, '2026-10-25 14:45:56', 7, NULL, 21, NULL);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_movimentacao, id_produto, tipo_movimentacao, quantidade, data_hora, id_funcionario, id_pedido, id_recebimento, id_ordem_producao) VALUES
  (541, 45, 'ENTRADA_COMPRA', 60.000, '2026-10-25 14:45:56', 7, NULL, 21, NULL),
  (542, 44, 'ENTRADA_COMPRA', 25.000, '2026-10-25 14:45:56', 7, NULL, 21, NULL),
  (543, 43, 'ENTRADA_COMPRA', 15.000, '2026-10-25 14:45:56', 7, NULL, 21, NULL),
  (544, 49, 'ENTRADA_COMPRA', 20.000, '2026-10-26 18:56:42', 7, NULL, 23, NULL),
  (545, 48, 'ENTRADA_COMPRA', 30.000, '2026-10-26 18:56:42', 7, NULL, 23, NULL),
  (546, 47, 'ENTRADA_COMPRA', 60.000, '2026-10-26 18:56:42', 7, NULL, 23, NULL),
  (547, 29, 'SAIDA_VENDA', 3.000, '2026-10-27 06:47:46', 6, 170, NULL, NULL),
  (548, 41, 'SAIDA_VENDA', 7.000, '2026-10-27 06:47:46', 6, 170, NULL, NULL),
  (549, 18, 'SAIDA_VENDA', 2.000, '2026-10-27 06:47:46', 6, 170, NULL, NULL),
  (550, 27, 'SAIDA_VENDA', 8.000, '2026-10-29 21:52:38', 6, 175, NULL, NULL),
  (551, 6, 'SAIDA_VENDA', 8.000, '2026-10-30 15:58:20', 6, 178, NULL, NULL),
  (552, 41, 'SAIDA_VENDA', 8.000, '2026-10-30 15:58:20', 6, 178, NULL, NULL),
  (553, 17, 'SAIDA_VENDA', 3.000, '2026-10-30 15:58:20', 6, 178, NULL, NULL),
  (554, 35, 'SAIDA_VENDA', 4.000, '2026-10-30 23:45:23', 6, 176, NULL, NULL),
  (555, 29, 'SAIDA_VENDA', 1.000, '2026-10-30 23:45:23', 6, 176, NULL, NULL),
  (556, 41, 'SAIDA_VENDA', 5.000, '2026-10-31 04:11:49', 6, 177, NULL, NULL),
  (557, 17, 'SAIDA_VENDA', 8.000, '2026-11-01 02:15:12', 5, 180, NULL, NULL);

-- 4. SELECT COM JOIN (consultas que cruzam várias tabelas) ----------------

-- J01 — Pedidos entregues com cliente, itens e valor (últimos 10).
SELECT p.id_pedido, p.data_hora, p.canal_pedido, COALESCE(c.nome,'Venda de balcão') AS cliente,
       COUNT(i.id_item) AS itens, p.valor_total
FROM PEDIDO p
LEFT JOIN CLIENTE c     ON c.id_cliente = p.id_cliente
JOIN ITEM_PEDIDO i      ON i.id_pedido = p.id_pedido
WHERE p.status_pedido = 'ENTREGUE'
GROUP BY p.id_pedido, p.data_hora, p.canal_pedido, c.nome, p.valor_total
ORDER BY p.data_hora DESC
LIMIT 10;

-- J02 — Itens de um pedido com produto, quantidade, preço praticado e subtotal.
SELECT i.id_pedido, pr.codigo, pr.nome, i.quantidade, pr.unidade_venda, i.preco_unitario,
       ROUND(i.quantidade * i.preco_unitario, 2) AS subtotal
FROM ITEM_PEDIDO i
JOIN PRODUTO pr ON pr.id_produto = i.id_produto
WHERE i.id_pedido = 10
ORDER BY pr.nome;

-- J03 — Pagamentos de cada pedido com a forma e o status.
SELECT p.id_pedido, pg.forma_pagamento, pg.valor_pagamento, pg.status_pagamento, pg.data_hora_pagamento
FROM PEDIDO p
JOIN PAGAMENTO pg ON pg.id_pedido = p.id_pedido
WHERE p.id_pedido BETWEEN 1 AND 15
ORDER BY p.id_pedido, pg.data_hora_pagamento;

-- J04 — Recebimentos de mercadoria com fornecedor, nota do fornecedor e funcionário.
SELECT r.id_recebimento, f.razao_social, pc.id_pedido_compra, r.numero_nf_fornecedor,
       r.data_hora, fu.nome AS recebido_por
FROM RECEBIMENTO r
JOIN PEDIDO_COMPRA pc ON pc.id_pedido_compra = r.id_pedido_compra
JOIN FORNECEDOR f     ON f.id_fornecedor = pc.id_fornecedor
JOIN FUNCIONARIO fu   ON fu.id_funcionario = r.id_funcionario
ORDER BY r.data_hora
LIMIT 10;

-- 5. UPDATE ------------------------------------------------------------

-- U01 — Reajuste de 5% no preço dos produtos da marca Tigre.
-- Os pedidos já feitos não mudam: ITEM_PEDIDO guarda o preço praticado na venda (RN04).
UPDATE PRODUTO SET preco = ROUND(preco * 1.05, 2) WHERE marca = 'Tigre';

-- U02 — Resolução de uma ocorrência em aberto (RN10: solução e data de resolução juntas).
-- O pedido volta para ENVIADO antes de a ocorrência ser fechada (senão a subconsulta não a encontraria mais).
UPDATE PEDIDO SET status_pedido = 'ENVIADO'
 WHERE id_pedido = (SELECT id_pedido FROM (SELECT MIN(id_ocorrencia) AS m FROM OCORRENCIA
                     WHERE status_ocorrencia = 'ABERTA' AND tipo_ocorrencia = 'PROBLEMA_ENTREGA') x
                     JOIN OCORRENCIA o ON o.id_ocorrencia = x.m);
UPDATE OCORRENCIA
   SET status_ocorrencia = 'RESOLVIDA', solucao_aplicada = 'NOVA_ENTREGA',
       data_hora_resolucao = data_hora + INTERVAL 1 DAY
 WHERE id_ocorrencia = (SELECT id_ocorrencia FROM (SELECT MIN(id_ocorrencia) AS id_ocorrencia
                          FROM OCORRENCIA WHERE status_ocorrencia = 'ABERTA' AND tipo_ocorrencia = 'PROBLEMA_ENTREGA') t);

-- 6. DELETE ------------------------------------------------------------

-- D01 — Cliente cadastrado por engano e sem nenhum pedido (cadastro de teste removido).
INSERT INTO CLIENTE (nome, telefone) VALUES ('Cadastro de Teste', '11900000000');
DELETE FROM CLIENTE
 WHERE nome = 'Cadastro de Teste'
   AND NOT EXISTS (SELECT 1 FROM PEDIDO p WHERE p.id_cliente = CLIENTE.id_cliente);

-- 7. CONSULTAS GERENCIAIS -------------------------------------------------
-- Data de referência fixa, para que a demonstração dê o mesmo resultado em qualquer dia.
SET @data_ref = '2026-11-10';

-- G01 — Quais produtos estão abaixo do estoque mínimo hoje?
-- Atende: P1 (controle de estoque manual) | KPI K1 (produtos abaixo do estoque mínimo)
SELECT p.codigo, p.nome, e.quantidade_disponivel AS saldo, e.estoque_minimo AS minimo,
       (e.estoque_minimo - e.quantidade_disponivel) AS falta
FROM ESTOQUE e
JOIN PRODUTO p ON p.id_produto = e.id_produto
WHERE p.ativo = 1 AND e.quantidade_disponivel < e.estoque_minimo
ORDER BY falta DESC;

-- G02 — Quanto entrou e saiu do estoque em cada mês, por tipo de movimentação?
-- Atende: P1 (histórico de entradas e saídas)
SELECT DATE_FORMAT(m.data_hora, '%Y-%m') AS mes, m.tipo_movimentacao,
       COUNT(*) AS movimentacoes, SUM(m.quantidade) AS quantidade_total
FROM MOVIMENTACAO_ESTOQUE m
GROUP BY DATE_FORMAT(m.data_hora, '%Y-%m'), m.tipo_movimentacao
ORDER BY mes, m.tipo_movimentacao;

-- G03 — Quantos dias de venda o estoque atual cobre, nos 10 produtos de menor cobertura?
-- Atende: P1 | KPI K2 (cobertura de estoque em dias = saldo / saída média diária dos últimos 90 dias)
SELECT p.codigo, p.nome, e.quantidade_disponivel AS saldo,
       ROUND(SUM(m.quantidade) / 90, 3) AS saida_media_dia,
       ROUND(e.quantidade_disponivel / (SUM(m.quantidade) / 90), 1) AS cobertura_dias
FROM PRODUTO p
JOIN ESTOQUE e ON e.id_produto = p.id_produto
JOIN MOVIMENTACAO_ESTOQUE m ON m.id_produto = p.id_produto AND m.tipo_movimentacao = 'SAIDA_VENDA'
     AND m.data_hora >= DATE_SUB(@data_ref, INTERVAL 90 DAY)
GROUP BY p.id_produto, p.codigo, p.nome, e.quantidade_disponivel
ORDER BY cobertura_dias
LIMIT 10;

-- G04 — Quantas ocorrências houve por tipo, quantas seguem abertas e quanto tempo levam para ser resolvidas?
-- Atende: P2 (ocorrências sem registro de motivo e solução) | KPI K3 (tempo médio de resolução de ocorrências)
SELECT tipo_ocorrencia, COUNT(*) AS total,
       SUM(status_ocorrencia = 'ABERTA') AS abertas,
       ROUND(AVG(TIMESTAMPDIFF(HOUR, data_hora, data_hora_resolucao)), 1) AS horas_medias_resolucao
FROM OCORRENCIA
GROUP BY tipo_ocorrencia
ORDER BY total DESC;

-- G05 — Qual a taxa de conferências divergentes por funcionário?
-- Atende: P2 | KPI K4 (taxa de divergência na separação)
SELECT f.nome, COUNT(*) AS conferencias,
       SUM(s.status_conferencia = 'DIVERGENTE') AS divergentes,
       ROUND(100 * SUM(s.status_conferencia = 'DIVERGENTE') / COUNT(*), 1) AS pct_divergente
FROM SEPARACAO_PEDIDO s
JOIN FUNCIONARIO f ON f.id_funcionario = s.id_funcionario
GROUP BY f.id_funcionario, f.nome
ORDER BY pct_divergente DESC, conferencias DESC;

-- G06 — Quantas trocas, devoluções e reembolsos houve, por fundamento e situação?
-- Atende: P3 (trocas e devoluções sem registro estruturado)
SELECT t.fundamento, t.tipo_solicitacao, t.status_solicitacao, COUNT(*) AS solicitacoes
FROM TROCA_DEVOLUCAO t
GROUP BY t.fundamento, t.tipo_solicitacao, t.status_solicitacao
ORDER BY t.fundamento, t.tipo_solicitacao, t.status_solicitacao;

-- G07 — Qual o percentual de pedidos entregues que geraram troca/devolução, e quais produtos mais aparecem?
-- Atende: P3 | KPI K5 (taxa de troca/devolução)
SELECT pr.codigo, pr.nome, COUNT(*) AS solicitacoes,
       ROUND(100 * COUNT(DISTINCT t.id_pedido) /
             (SELECT COUNT(*) FROM PEDIDO WHERE status_pedido = 'ENTREGUE'), 2) AS pct_pedidos_entregues
FROM TROCA_DEVOLUCAO t
JOIN PRODUTO pr ON pr.id_produto = t.id_produto
GROUP BY pr.id_produto, pr.codigo, pr.nome
ORDER BY solicitacoes DESC, pr.nome;

-- G08 — Qual o faturamento mensal por canal de venda (pagamentos aprovados de pedidos não cancelados)?
-- Atende: KPI K6 (faturamento mensal por canal)
SELECT DATE_FORMAT(p.data_hora, '%Y-%m') AS mes, p.canal_pedido, SUM(pg.valor_pagamento) AS faturamento
FROM PEDIDO p
JOIN PAGAMENTO pg ON pg.id_pedido = p.id_pedido AND pg.status_pagamento = 'APROVADO'
WHERE p.status_pedido <> 'CANCELADO'
GROUP BY DATE_FORMAT(p.data_hora, '%Y-%m'), p.canal_pedido
ORDER BY mes, p.canal_pedido;

-- G09 — Qual o ticket médio por canal de venda?
-- Atende: KPI K7 (ticket médio = valor total dos pedidos / número de pedidos, sem cancelados)
SELECT canal_pedido, COUNT(*) AS pedidos, ROUND(AVG(valor_total), 2) AS ticket_medio
FROM PEDIDO
WHERE status_pedido <> 'CANCELADO'
GROUP BY canal_pedido
ORDER BY ticket_medio DESC;

-- G10 — Qual a taxa de cancelamento de pedidos em cada mês?
-- Atende: KPI K8 (taxa de cancelamento = pedidos cancelados / pedidos registrados no mês)
SELECT DATE_FORMAT(data_hora, '%Y-%m') AS mes, COUNT(*) AS pedidos,
       SUM(status_pedido = 'CANCELADO') AS cancelados,
       ROUND(100 * SUM(status_pedido = 'CANCELADO') / COUNT(*), 1) AS pct_cancelamento
FROM PEDIDO
GROUP BY DATE_FORMAT(data_hora, '%Y-%m')
ORDER BY mes;

-- G11 — Quais os 10 produtos que mais geram receita?
-- Atende: KPI K9 (receita por produto, curva ABC)
SELECT pr.codigo, pr.nome, SUM(i.quantidade) AS quantidade_vendida,
       SUM(ROUND(i.quantidade * i.preco_unitario, 2)) AS receita
FROM ITEM_PEDIDO i
JOIN PEDIDO p   ON p.id_pedido = i.id_pedido AND p.status_pedido <> 'CANCELADO'
JOIN PRODUTO pr ON pr.id_produto = i.id_produto
GROUP BY pr.id_produto, pr.codigo, pr.nome
ORDER BY receita DESC
LIMIT 10;

-- G12 — Quanto tempo, em média, leva entre o pedido e a entrega ao cliente?
-- Atende: KPI K10 (prazo médio de entrega, em horas, por tipo de entrega)
SELECT tipo_entrega, COUNT(*) AS pedidos_entregues,
       ROUND(AVG(TIMESTAMPDIFF(HOUR, data_hora, data_entrega)), 1) AS horas_medias
FROM PEDIDO
WHERE data_entrega IS NOT NULL
GROUP BY tipo_entrega;

-- G13 — Quanto foi faturado por forma de pagamento?
-- Atende: KPI K11 (mix de formas de pagamento)
SELECT pg.forma_pagamento, COUNT(*) AS pagamentos, SUM(pg.valor_pagamento) AS valor,
       ROUND(100 * SUM(pg.valor_pagamento) /
             (SELECT SUM(valor_pagamento) FROM PAGAMENTO WHERE status_pagamento = 'APROVADO'), 1) AS pct
FROM PAGAMENTO pg
WHERE pg.status_pagamento = 'APROVADO'
GROUP BY pg.forma_pagamento
ORDER BY valor DESC;

-- G14 — Quais contas a pagar estão em aberto ou vencidas, por fornecedor?
-- Atende: KPI K12 (contas a pagar em aberto e vencidas)
SELECT f.razao_social, COUNT(*) AS contas_abertas, SUM(c.valor) AS valor_em_aberto,
       SUM(CASE WHEN c.data_vencimento < @data_ref THEN c.valor ELSE 0 END) AS valor_vencido
FROM CONTA_PAGAR c
JOIN RECEBIMENTO r    ON r.id_recebimento = c.id_recebimento
JOIN PEDIDO_COMPRA pc ON pc.id_pedido_compra = r.id_pedido_compra
JOIN FORNECEDOR f     ON f.id_fornecedor = pc.id_fornecedor
WHERE c.status_conta = 'ABERTA'
GROUP BY f.id_fornecedor, f.razao_social
ORDER BY valor_vencido DESC, valor_em_aberto DESC;

-- G15 — Quais pedidos de compra ainda têm mercadoria a receber?
-- Atende: KPI K13 (pedidos de compra com recebimento pendente ou parcial)
SELECT pc.id_pedido_compra, f.razao_social, pc.status_compra,
       SUM(ic.quantidade) AS quantidade_pedida,
       COALESCE(SUM(r.recebido), 0) AS quantidade_recebida
FROM PEDIDO_COMPRA pc
JOIN FORNECEDOR f ON f.id_fornecedor = pc.id_fornecedor
JOIN ITEM_PEDIDO_COMPRA ic ON ic.id_pedido_compra = pc.id_pedido_compra
LEFT JOIN (SELECT id_item_compra, SUM(quantidade_recebida) AS recebido
           FROM ITEM_RECEBIMENTO GROUP BY id_item_compra) r ON r.id_item_compra = ic.id_item_compra
WHERE pc.status_compra IN ('ABERTO','PARCIAL')
GROUP BY pc.id_pedido_compra, f.razao_social, pc.status_compra
ORDER BY pc.data_pedido;

-- G16 — Qual a margem bruta estimada (preço de venda x último custo de compra) dos 10 produtos mais rentáveis?
-- Atende: KPI K14 (margem bruta estimada por produto)
SELECT p.codigo, p.nome, p.preco, uc.custo_unitario AS ultimo_custo,
       ROUND(100 * (p.preco - uc.custo_unitario) / p.preco, 1) AS margem_pct
FROM PRODUTO p
JOIN (SELECT ic.id_produto, ic.custo_unitario,
             ROW_NUMBER() OVER (PARTITION BY ic.id_produto ORDER BY pc.data_pedido DESC) AS rn
      FROM ITEM_PEDIDO_COMPRA ic
      JOIN PEDIDO_COMPRA pc ON pc.id_pedido_compra = ic.id_pedido_compra) uc
  ON uc.id_produto = p.id_produto AND uc.rn = 1
ORDER BY margem_pct DESC
LIMIT 10;

-- G17 — Quanto foi produzido internamente de cada item de fabricação própria e quanto foi vendido?
-- Atende: KPI K15 (produção x venda dos itens de fabricação própria)
SELECT pr.codigo, pr.nome,
       COALESCE((SELECT SUM(o.quantidade) FROM ORDEM_PRODUCAO o
                 WHERE o.id_produto = pr.id_produto AND o.status_producao = 'CONCLUIDA'), 0) AS produzido,
       COALESCE((SELECT SUM(i.quantidade) FROM ITEM_PEDIDO i
                 JOIN PEDIDO p ON p.id_pedido = i.id_pedido AND p.status_pedido <> 'CANCELADO'
                 WHERE i.id_produto = pr.id_produto), 0) AS vendido
FROM PRODUTO pr
WHERE pr.origem = 'FABRICADO'
ORDER BY produzido DESC;

-- G18 — Quais clientes cadastrados nunca fizeram um pedido?
-- Atende: KPI K16 (clientes cadastrados sem compra)
SELECT c.id_cliente, c.nome, c.data_cadastro
FROM CLIENTE c
LEFT JOIN PEDIDO p ON p.id_cliente = c.id_cliente
WHERE p.id_pedido IS NULL
ORDER BY c.data_cadastro;

-- 8. CONSULTAS DE AUDITORIA ----------------------------------------------
-- Cada consulta lista os registros que VIOLAM a regra; resultado vazio = dados consistentes.

-- A01 — Existe pedido registrado sem nenhum item?
-- Verifica: RN04 (todo pedido tem ao menos um item)
SELECT p.id_pedido, p.data_hora, p.status_pedido
FROM PEDIDO p
LEFT JOIN ITEM_PEDIDO i ON i.id_pedido = p.id_pedido
WHERE i.id_item IS NULL;

-- A02 — Existe pedido em separação ou além sem pagamentos aprovados que cubram o valor total?
-- Verifica: RN08 (pedido só é liberado quando os pagamentos aprovados cobrem o total)
SELECT p.id_pedido, p.status_pedido, p.valor_total, COALESCE(SUM(pg.valor_pagamento), 0) AS aprovado
FROM PEDIDO p
LEFT JOIN PAGAMENTO pg ON pg.id_pedido = p.id_pedido AND pg.status_pagamento = 'APROVADO'
WHERE p.status_pedido IN ('EM_SEPARACAO','CONFERIDO','ENVIADO','ENTREGUE','COM_OCORRENCIA')
GROUP BY p.id_pedido, p.status_pedido, p.valor_total
HAVING COALESCE(SUM(pg.valor_pagamento), 0) < p.valor_total;

-- A03 — Existe produto com saldo de estoque negativo?
-- Verifica: RN02 (saldo nunca negativo)
SELECT e.id_produto, e.quantidade_disponivel FROM ESTOQUE e WHERE e.quantidade_disponivel < 0;

-- A04 — Existe pedido para entrega sem cliente ou sem endereço de entrega?
-- Verifica: RN05 (entrega exige cliente e endereço)
SELECT p.id_pedido, p.id_cliente, p.endereco_entrega
FROM PEDIDO p
WHERE p.tipo_entrega = 'ENTREGA' AND (p.id_cliente IS NULL OR p.endereco_entrega IS NULL);

-- A05 — Existe pedido cujo valor total difere da soma dos itens?
-- Verifica: RN04 (valor_total = soma de quantidade x preço unitário)
SELECT p.id_pedido, p.valor_total, SUM(ROUND(i.quantidade * i.preco_unitario, 2)) AS soma_itens
FROM PEDIDO p
JOIN ITEM_PEDIDO i ON i.id_pedido = p.id_pedido
GROUP BY p.id_pedido, p.valor_total
HAVING p.valor_total <> SUM(ROUND(i.quantidade * i.preco_unitario, 2));

-- A06 — Existe pedido enviado ou entregue sem nota fiscal?
-- Verifica: RN14 (pedido enviado/entregue possui nota fiscal de venda)
SELECT p.id_pedido, p.status_pedido, p.data_hora
FROM PEDIDO p
LEFT JOIN NOTA_FISCAL n ON n.id_pedido = p.id_pedido
WHERE p.status_pedido IN ('ENVIADO','ENTREGUE') AND n.id_nota IS NULL;

-- A07 — Existe nota fiscal com valor diferente do pedido?
-- Verifica: RN14 (nota fiscal reflete o valor do pedido)
SELECT n.id_nota, n.numero, p.id_pedido, n.valor_total AS valor_nota, p.valor_total AS valor_pedido
FROM NOTA_FISCAL n
JOIN PEDIDO p ON p.id_pedido = n.id_pedido
WHERE n.valor_total <> p.valor_total;

-- A08 — Existe ocorrência resolvida sem solução, ou pedido "com ocorrência" sem ocorrência aberta?
-- Verifica: RN10
SELECT o.id_ocorrencia AS referencia, 'resolvida sem solução' AS problema
FROM OCORRENCIA o WHERE o.status_ocorrencia = 'RESOLVIDA' AND o.solucao_aplicada IS NULL
UNION ALL
SELECT p.id_pedido, 'pedido com ocorrência sem ocorrência aberta'
FROM PEDIDO p
WHERE p.status_pedido = 'COM_OCORRENCIA'
  AND NOT EXISTS (SELECT 1 FROM OCORRENCIA o WHERE o.id_pedido = p.id_pedido AND o.status_ocorrencia = 'ABERTA');

-- A09 — Existe troca/devolução aprovada fora do prazo legal (7 dias para arrependimento, 90 dias para vício)?
-- Verifica: RN12 (prazos do Código de Defesa do Consumidor)
SELECT t.id_troca, t.fundamento, t.status_solicitacao, p.data_entrega, t.data_hora,
       TIMESTAMPDIFF(DAY, p.data_entrega, t.data_hora) AS dias_apos_entrega
FROM TROCA_DEVOLUCAO t
JOIN PEDIDO p ON p.id_pedido = t.id_pedido
WHERE t.status_solicitacao IN ('APROVADA','CONCLUIDA')
  AND ((t.fundamento = 'ARREPENDIMENTO' AND TIMESTAMPDIFF(DAY, p.data_entrega, t.data_hora) > 7)
    OR (t.fundamento = 'VICIO' AND TIMESTAMPDIFF(DAY, p.data_entrega, t.data_hora) > 90));

-- A10 — Existe troca/devolução de produto que não consta no pedido?
-- Verifica: RN11 (a solicitação refere-se a um produto do pedido)
SELECT t.id_troca, t.id_pedido, t.id_produto
FROM TROCA_DEVOLUCAO t
LEFT JOIN ITEM_PEDIDO i ON i.id_pedido = t.id_pedido AND i.id_produto = t.id_produto
WHERE i.id_item IS NULL;

-- A11 — Existe item recebido em quantidade maior que a pedida ao fornecedor?
-- Verifica: RN18 (recebimento não ultrapassa o pedido de compra)
SELECT ic.id_item_compra, ic.quantidade AS pedida, SUM(ir.quantidade_recebida) AS recebida
FROM ITEM_PEDIDO_COMPRA ic
JOIN ITEM_RECEBIMENTO ir ON ir.id_item_compra = ic.id_item_compra
GROUP BY ic.id_item_compra, ic.quantidade
HAVING SUM(ir.quantidade_recebida) > ic.quantidade;

-- A12 — Existe pedido de compra com situação incoerente com o que foi recebido?
-- Verifica: RN18 (RECEBIDO = tudo recebido; PARCIAL = recebido em parte)
SELECT pc.id_pedido_compra, pc.status_compra, SUM(ic.quantidade) AS pedida,
       COALESCE(SUM(r.recebido), 0) AS recebida
FROM PEDIDO_COMPRA pc
JOIN ITEM_PEDIDO_COMPRA ic ON ic.id_pedido_compra = pc.id_pedido_compra
LEFT JOIN (SELECT id_item_compra, SUM(quantidade_recebida) AS recebido
           FROM ITEM_RECEBIMENTO GROUP BY id_item_compra) r ON r.id_item_compra = ic.id_item_compra
WHERE pc.status_compra <> 'CANCELADO'
GROUP BY pc.id_pedido_compra, pc.status_compra
HAVING (pc.status_compra = 'RECEBIDO' AND COALESCE(SUM(r.recebido), 0) < SUM(ic.quantidade))
    OR (pc.status_compra = 'PARCIAL'  AND (COALESCE(SUM(r.recebido), 0) = 0
                                         OR COALESCE(SUM(r.recebido), 0) >= SUM(ic.quantidade)))
    OR (pc.status_compra = 'ABERTO'   AND COALESCE(SUM(r.recebido), 0) > 0);

-- A13 — Existe recebimento sem conta a pagar?
-- Verifica: RN19 (todo recebimento gera uma conta a pagar)
SELECT r.id_recebimento
FROM RECEBIMENTO r
LEFT JOIN CONTA_PAGAR c ON c.id_recebimento = r.id_recebimento
WHERE c.id_conta IS NULL;

-- A14 — Existe item recebido sem a entrada correspondente no estoque?
-- Verifica: RN19 e RN21 (todo recebimento gera entrada de estoque)
SELECT ir.id_item_recebimento, ir.id_recebimento, ic.id_produto
FROM ITEM_RECEBIMENTO ir
JOIN ITEM_PEDIDO_COMPRA ic ON ic.id_item_compra = ir.id_item_compra
LEFT JOIN MOVIMENTACAO_ESTOQUE m ON m.id_recebimento = ir.id_recebimento AND m.id_produto = ic.id_produto
                                AND m.tipo_movimentacao = 'ENTRADA_COMPRA' AND m.quantidade = ir.quantidade_recebida
WHERE m.id_movimentacao IS NULL;

-- A15 — Existe produto cujo saldo em ESTOQUE difere da soma das movimentações?
-- Verifica: RN21 (saldo = entradas - saídas registradas)
SELECT e.id_produto, e.quantidade_disponivel AS saldo,
       SUM(CASE WHEN m.tipo_movimentacao LIKE 'ENTRADA%' THEN m.quantidade ELSE -m.quantidade END) AS saldo_movimentacoes
FROM ESTOQUE e
JOIN MOVIMENTACAO_ESTOQUE m ON m.id_produto = e.id_produto
GROUP BY e.id_produto, e.quantidade_disponivel
HAVING e.quantidade_disponivel <> SUM(CASE WHEN m.tipo_movimentacao LIKE 'ENTRADA%' THEN m.quantidade ELSE -m.quantidade END);

-- A16 — Existe produto sem registro de estoque?
-- Verifica: RN02 (todo produto tem exatamente um registro de estoque)
SELECT p.id_produto, p.nome
FROM PRODUTO p
LEFT JOIN ESTOQUE e ON e.id_produto = p.id_produto
WHERE e.id_estoque IS NULL;

-- A17 — Existe pedido de compra em andamento com fornecedor inativo?
-- Verifica: RN16 (compras apenas de fornecedor cadastrado e ativo)
SELECT pc.id_pedido_compra, f.razao_social, pc.status_compra
FROM PEDIDO_COMPRA pc
JOIN FORNECEDOR f ON f.id_fornecedor = pc.id_fornecedor
WHERE f.ativo = 0 AND pc.status_compra IN ('ABERTO','PARCIAL');

-- A18 — Existe ordem de produção concluída para produto que não é de fabricação própria?
-- Verifica: RN22
SELECT o.id_ordem_producao, pr.nome, pr.origem
FROM ORDEM_PRODUCAO o
JOIN PRODUTO pr ON pr.id_produto = o.id_produto
WHERE o.status_producao = 'CONCLUIDA' AND pr.origem <> 'FABRICADO';
