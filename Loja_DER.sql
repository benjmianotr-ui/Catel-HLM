CREATE TABLE IF NOT EXISTS `Cliente` (
	`id_cliente` int NOT NULL AUTO_INCREMENT,
	`nome` varchar(255) NULL,
	`telefone` varchar(20) NULL,
	`endereco` varchar(255) NULL,
	`cpf_cnpj` varchar(20) NULL,
	PRIMARY KEY (`id_cliente`)
);

CREATE TABLE IF NOT EXISTS `Funcionario` (
	`id_funcionario` int NOT NULL AUTO_INCREMENT,
	`nome` varchar(255) NOT NULL,
	`cargo` varchar(100) NOT NULL,
	PRIMARY KEY (`id_funcionario`)
);

CREATE TABLE IF NOT EXISTS `Produto` (
	`id_produto` int NOT NULL AUTO_INCREMENT,
	`nome` varchar(255) NOT NULL,
	`codigo` varchar(50) NOT NULL,
	`preco` decimal(10,2) NOT NULL,
	`marca` varchar(100) NULL,
	`unidade_venda` varchar(20) NULL,
	PRIMARY KEY (`id_produto`),
	UNIQUE KEY `uk_produto_codigo` (`codigo`)
);

CREATE TABLE IF NOT EXISTS `Estoque` (
	`id_estoque` int NOT NULL AUTO_INCREMENT,
	`id_produto` int NOT NULL,
	`quantidade_disponivel` int NOT NULL DEFAULT 0,
	`data_atualizacao` datetime NOT NULL,
	PRIMARY KEY (`id_estoque`),
	UNIQUE KEY `uk_estoque_produto` (`id_produto`)
);

CREATE TABLE IF NOT EXISTS `Pedido` (
	`id_pedido` int NOT NULL AUTO_INCREMENT,
	`id_cliente` int NULL,
	`data_hora` datetime NOT NULL,
	`canal_pedido` varchar(20) NOT NULL,
	`tipo_entrega` varchar(20) NOT NULL,
	`endereco_entrega` varchar(255) NULL,
	`valor_total` decimal(10,2) NOT NULL,
	`status_pedido` varchar(30) NOT NULL,
	PRIMARY KEY (`id_pedido`)
);

CREATE TABLE IF NOT EXISTS `Item_Pedido` (
	`id_item` int NOT NULL AUTO_INCREMENT,
	`id_pedido` int NOT NULL,
	`id_produto` int NOT NULL,
	`quantidade` int NOT NULL,
	`preco_unitario` decimal(10,2) NOT NULL,
	PRIMARY KEY (`id_item`)
);

CREATE TABLE IF NOT EXISTS `Pagamento` (
	`id_pagamento` int NOT NULL AUTO_INCREMENT,
	`id_pedido` int NOT NULL,
	`forma_pagamento` varchar(20) NOT NULL,
	`valor_pagamento` decimal(10,2) NOT NULL,
	`status_pagamento` varchar(20) NOT NULL,
	`data_hora_pagamento` datetime NOT NULL,
	PRIMARY KEY (`id_pagamento`)
);

CREATE TABLE IF NOT EXISTS `Separacao_Pedido` (
	`id_separacao` int NOT NULL AUTO_INCREMENT,
	`id_pedido` int NOT NULL,
	`id_funcionario` int NOT NULL,
	`data_hora_separacao` datetime NOT NULL,
	`status_conferencia` varchar(20) NOT NULL,
	`observacao` varchar(255) NULL,
	PRIMARY KEY (`id_separacao`)
);

CREATE TABLE IF NOT EXISTS `Ocorrencia` (
	`id_ocorrencia` int NOT NULL AUTO_INCREMENT,
	`id_pedido` int NOT NULL,
	`tipo_ocorrencia` varchar(30) NOT NULL,
	`descricao` varchar(255) NOT NULL,
	`solucao_aplicada` varchar(30) NULL,
	`status_ocorrencia` varchar(20) NOT NULL,
	`data_hora` datetime NOT NULL,
	PRIMARY KEY (`id_ocorrencia`)
);

CREATE TABLE IF NOT EXISTS `Troca_Devolucao` (
	`id_troca` int NOT NULL AUTO_INCREMENT,
	`id_pedido` int NOT NULL,
	`id_produto` int NOT NULL,
	`motivo` varchar(255) NOT NULL,
	`condicao_produto` varchar(100) NOT NULL,
	`tipo_solicitacao` varchar(20) NOT NULL,
	`status_solicitacao` varchar(20) NOT NULL,
	`data_hora` datetime NOT NULL,
	PRIMARY KEY (`id_troca`)
);

ALTER TABLE `Estoque` ADD CONSTRAINT `Estoque_fk1` FOREIGN KEY (`id_produto`) REFERENCES `Produto`(`id_produto`);
ALTER TABLE `Pedido` ADD CONSTRAINT `Pedido_fk1` FOREIGN KEY (`id_cliente`) REFERENCES `Cliente`(`id_cliente`);
ALTER TABLE `Item_Pedido` ADD CONSTRAINT `Item_Pedido_fk1` FOREIGN KEY (`id_pedido`) REFERENCES `Pedido`(`id_pedido`);
ALTER TABLE `Item_Pedido` ADD CONSTRAINT `Item_Pedido_fk2` FOREIGN KEY (`id_produto`) REFERENCES `Produto`(`id_produto`);
ALTER TABLE `Pagamento` ADD CONSTRAINT `Pagamento_fk1` FOREIGN KEY (`id_pedido`) REFERENCES `Pedido`(`id_pedido`);
ALTER TABLE `Separacao_Pedido` ADD CONSTRAINT `Separacao_Pedido_fk1` FOREIGN KEY (`id_pedido`) REFERENCES `Pedido`(`id_pedido`);
ALTER TABLE `Separacao_Pedido` ADD CONSTRAINT `Separacao_Pedido_fk2` FOREIGN KEY (`id_funcionario`) REFERENCES `Funcionario`(`id_funcionario`);
ALTER TABLE `Ocorrencia` ADD CONSTRAINT `Ocorrencia_fk1` FOREIGN KEY (`id_pedido`) REFERENCES `Pedido`(`id_pedido`);
ALTER TABLE `Troca_Devolucao` ADD CONSTRAINT `Troca_Devolucao_fk1` FOREIGN KEY (`id_pedido`) REFERENCES `Pedido`(`id_pedido`);
ALTER TABLE `Troca_Devolucao` ADD CONSTRAINT `Troca_Devolucao_fk2` FOREIGN KEY (`id_produto`) REFERENCES `Produto`(`id_produto`);