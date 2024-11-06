INSERT INTO pedidos (fecha_pedido, id_cliente) 
VALUES (NOW(), 5);

SET @id_pedido = LAST_INSERT_ID();

INSERT INTO detalles_pedido (id_pedido, id_producto, cantidad) 
VALUES 
(@id_pedido, 311, 500),   -- Tornillos
(@id_pedido, 312, 300),   -- Clavos
(@id_pedido, 313, 10),    -- Martillos
(@id_pedido, 314, 5);     -- Llaves inglesas