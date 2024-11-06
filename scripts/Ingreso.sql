SET @fecha_ingreso = NOW();
SET @cantidad = 100;          
SET @ubicacion_concat = '1-1-140-1'; 
SET @id_producto = 325;         
SET @id_cliente = 6;          
SET @id_usuario = 1;          

INSERT INTO ingreso (fecha_ingreso, cantidad, ubicacion_concat, id_producto, id_cliente, id_usuario) 
VALUES (@fecha_ingreso, @cantidad, @ubicacion_concat, @id_producto, @id_cliente, @id_usuario);


