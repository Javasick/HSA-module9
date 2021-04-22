CREATE TABLE `example` (
  `id` int NOT NULL,
  `value` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`id`)
);
INSERT INTO example (id,value) VALUES (1,'row1'), (2,'row2'), (3,'row3');