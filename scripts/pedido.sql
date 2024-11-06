INSERT INTO pedidos (fecha_pedido, id_cliente) 
VALUES (NOW(), 4); 

SET @id_pedido = LAST_INSERT_ID();

INSERT INTO detalles_pedido (id_pedido, id_producto, cantidad) 
VALUES 
(@id_pedido, 301, 200),  -- Mascarillas
(@id_pedido, 302, 100),  -- Guantes quirúrgicos
(@id_pedido, 303, 50),   -- Alcohol en gel
(@id_pedido, 304, 20);   -- Termómetros

UPDATE pedidos
SET estado = 'procesado'
WHERE id_pedido = 5;



