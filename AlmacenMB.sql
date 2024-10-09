CREATE DATABASE almacen_mb;
USE almace_mb;

CREATE TABLE clientes (
id_clientes INT AUTO_INCREMENT PRIMARY KEY,
razon_social VARCHAR(255) NOT NULL,
cuil VARCHAR(20) NOT NULL UNIQUE
); 

CREATE TABLE posiciones_almacen (
nave INT NOT NULL,
calle INT NOT NULL,
posicion INT NOT NULL,
altura INT NOT NULL,
ubicaciones_concat VARCHAR(20) NOT NULL PRIMARY KEY,
estado ENUM('vacío', 'ocupado') DEFAULT 'vacío',
CHECK (nave = 1 AND calle BETWEEN 1 AND 10 AND posicion BETWEEN 1 AND 156 AND altura BETWEEN 1 AND 6)
);

CREATE TABLE stock (
id_producto INT AUTO_INCREMENT PRIMARY KEY,
nombre_producto VARCHAR(255) NOT NULL,
ubicacion_concat VARCHAR(20),
cantidad INT NOT NULL,
unidad_medida VARCHAR(10),
id_cliente INT,
FOREIGN KEY (ubicacion_concat) REFERENCES posiciones_almacen(ubicaciones_concat),
FOREIGN KEY (id_cliente) REFERENCES clientes(id_clientes)
);

CREATE TABLE ingreso (
id_ingreso INT AUTO_INCREMENT PRIMARY KEY,
fecha_ingreso DATETIME NOT NULL,
cantidad INT NOT NULL,
ubicacion_concat VARCHAR(20),
id_producto INT,
id_cliente INT,
responsable VARCHAR(255),
FOREIGN KEY (ubicacion_concat) REFERENCES posiciones_almacen(ubicaciones_concat),
FOREIGN KEY (id_producto) REFERENCES stock(id_producto),
FOREIGN KEY (id_cliente) REFERENCES clientes(id_clientes)
);

CREATE TABLE egreso (
id_egreso INT AUTO_INCREMENT PRIMARY KEY,
fecha_egreso DATETIME NOT NULL,
cantidad INT NOT NULL,
ubicacion_concat VARCHAR(20),
id_product INT,
id_cliente INT,
responsable VARCHAR(255),
FOREIGN KEY (ubicacion_concat) REFERENCES posiciones_almacen(ubicaciones_concat),
FOREIGN KEY (id_cliente) REFERENCES clientes(id_clientes)
);

CREATE TABLE transferencias (
id_transferencias INT AUTO_INCREMENT PRIMARY KEY,
fecha_transferencia DATETIME NOT NULL,
cantidad INT NOT NULL,
ubicacion_concat_origen VARCHAR(20),
ubicacion_concat_destino VARCHAR(20),
id_producto INT,
id_cliente INT,
responsable VARCHAR(255),
FOREIGN KEY (ubicacion_concat_origen) REFERENCES posiciones_almacen(ubicaciones_concat),
FOREIGN KEY (ubicacion_concat_destino) REFERENCES posiciones_almacen(ubicaciones_concat),
FOREIGN KEY (id_producto) REFERENCES stock(id_producto),
FOREIGN KEY (id_cliente) REFERENCES clientes(id_clientes)
);

CREATE TABLE historial_stock (
id_historial INT AUTO_INCREMENT PRIMARY KEY,
id_producto INT,
fecha_cambio DATETIME NOT NULL,
cantidad_anterior INT NOT NULL,
cantidad_nueva INT NOT NULL,
ubicacion_concat_anterior VARCHAR(20),
ubicacion_concat_nueva VARCHAR(20),
tipo_movimiento ENUM('ingreso', 'egreso', 'transferencia') NOT NULL,
id_cliente INT,
responsable VARCHAR(255),
FOREIGN KEY (id_producto) REFERENCES stock(id_producto),
FOREIGN KEY (ubicacion_concat_anterior) REFERENCES posiciones_almacen(ubicaciones_concat),
FOREIGN KEY (ubicacion_concat_nueva) REFERENCES posiciones_almacen(ubicaciones_concat),
FOREIGN KEY (id_cliente) REFERENCES clientes(id_clientes)
);

INSERT INTO clientes (razon_social, cuil) VALUES
('Mateo Baldoni', '30-12345678-9'),
('Miguel Figueira', '30-87654321-9'),
('DALBAN', '30-31256895-9');

CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    rol ENUM('administrador', 'empleado', 'supervisor') DEFAULT 'empleado'
);

ALTER TABLE ingreso
ADD COLUMN id_usuario INT,
ADD CONSTRAINT fk_ingreso_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario);

INSERT INTO usuarios (nombre, email, rol) VALUES
('Juan Pérez', 'juan.perez@example.com', 'empleado'),
('María Gómez', 'maria.gomez@example.com', 'supervisor');

ALTER TABLE egreso
ADD COLUMN id_usuario INT,
ADD CONSTRAINT fk_egreso_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario);

ALTER TABLE transferencias
ADD COLUMN id_usuario INT,
ADD CONSTRAINT fk_transferencias_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario);

ALTER TABLE ingreso DROP COLUMN responsable;
ALTER TABLE egreso DROP COLUMN responsable;
ALTER TABLE transferencias DROP COLUMN responsable;

DROP TABLE IF EXISTS historial_stock;

DELIMITER $$

CREATE TRIGGER after_ingreso
AFTER INSERT ON ingreso
FOR EACH ROW
BEGIN
    -- Insertar el movimiento en el historial de stock
    INSERT INTO historial_stock (id_producto, fecha_cambio, cantidad_anterior, cantidad_nueva, ubicacion_concat_anterior, ubicacion_concat_nueva, tipo_movimiento, id_cliente, responsable)
    SELECT 
        NEW.id_producto,
        NOW(),
        (SELECT cantidad FROM stock WHERE id_producto = NEW.id_producto),
        (SELECT cantidad FROM stock WHERE id_producto = NEW.id_producto) + NEW.cantidad,
        NEW.ubicacion_concat,
        NEW.ubicacion_concat,
        'ingreso',
        NEW.id_cliente,
        (SELECT nombre FROM usuarios WHERE id_usuario = NEW.id_usuario);

    -- Actualizar el estado de la posición
    UPDATE posiciones_almacen
    SET estado = 'ocupado'
    WHERE ubicaciones_concat = NEW.ubicacion_concat AND (SELECT cantidad FROM stock WHERE id_producto = NEW.id_producto) > 0;
END$$

DELIMITER ;

DROP TRIGGER IF EXISTS after_ingreso;

DELIMITER $$

CREATE TRIGGER after_ingreso
AFTER INSERT ON ingreso
FOR EACH ROW
BEGIN
    INSERT INTO historial_stock (id_producto, fecha_cambio, cantidad_anterior, cantidad_nueva, ubicacion_concat_anterior, ubicacion_concat_nueva, tipo_movimiento, id_cliente, responsable)
    SELECT 
        NEW.id_producto,
        NOW(),
        (SELECT cantidad FROM stock WHERE id_producto = NEW.id_producto),
        (SELECT cantidad FROM stock WHERE id_producto = NEW.id_producto) + NEW.cantidad,
        NEW.ubicacion_concat,
        NEW.ubicacion_concat,
        'ingreso',
        NEW.id_cliente,
        (SELECT nombre FROM usuarios WHERE id_usuario = NEW.id_usuario);
    
    -- Actualizar el estado de la posición
    UPDATE posiciones_almacen
    SET estado = 'ocupado'
    WHERE ubicaciones_concat = NEW.ubicacion_concat AND (SELECT cantidad FROM stock WHERE id_producto = NEW.id_producto) > 0;
END$$

CREATE TRIGGER after_egreso
AFTER INSERT ON egreso
FOR EACH ROW
BEGIN
    INSERT INTO historial_stock (id_producto, fecha_cambio, cantidad_anterior, cantidad_nueva, ubicacion_concat_anterior, ubicacion_concat_nueva, tipo_movimiento, id_cliente, responsable)
    SELECT 
        NEW.id_product,
        NOW(),
        (SELECT cantidad FROM stock WHERE id_producto = NEW.id_product),
        (SELECT cantidad FROM stock WHERE id_producto = NEW.id_product) - NEW.cantidad,
        NEW.ubicacion_concat,
        NEW.ubicacion_concat,
        'egreso',
        NEW.id_cliente,
        (SELECT nombre FROM usuarios WHERE id_usuario = NEW.id_usuario);
    
    -- Actualizar el estado de la posición
    UPDATE posiciones_almacen
    SET estado = CASE 
                    WHEN (SELECT cantidad FROM stock WHERE id_producto = NEW.id_product) - NEW.cantidad <= 0 THEN 'vacío'
                    ELSE 'ocupado'
                END
    WHERE ubicaciones_concat = NEW.ubicacion_concat;
END$$

CREATE TRIGGER after_transferencias
AFTER INSERT ON transferencias
FOR EACH ROW
BEGIN
    INSERT INTO historial_stock (id_producto, fecha_cambio, cantidad_anterior, cantidad_nueva, ubicacion_concat_anterior, ubicacion_concat_nueva, tipo_movimiento, id_cliente, responsable)
    SELECT 
        NEW.id_producto,
        NOW(),
        (SELECT cantidad FROM stock WHERE id_producto = NEW.id_producto),
        (SELECT cantidad FROM stock WHERE id_producto = NEW.id_producto) - NEW.cantidad,
        NEW.ubicacion_concat_origen,
        NEW.ubicacion_concat_destino,
        'transferencia',
        NEW.id_cliente,
        (SELECT nombre FROM usuarios WHERE id_usuario = NEW.id_usuario);
END$$

DELIMITER ;

-- Historial de estado actual del stock por cliente

CREATE VIEW vista_estado_stock AS
SELECT 
    s.id_producto, 
    s.nombre_producto, 
    s.cantidad, 
    c.razon_social AS cliente,
    p.estado
FROM stock s
JOIN clientes c ON s.id_cliente = c.id_clientes
JOIN posiciones_almacen p ON s.ubicacion_concat = p.ubicaciones_concat;

-- Vista de transferencias y movimientos

CREATE VIEW v_movimientos_por_producto AS
SELECT 
    i.id_producto,
    i.fecha_ingreso AS fecha,
    i.cantidad,
    'ingreso' AS tipo
FROM ingreso i
UNION ALL
SELECT 
    e.id_product,
    e.fecha_egreso AS fecha,
    e.cantidad,
    'egreso' AS tipo
FROM egreso e
UNION ALL
SELECT 
    t.id_producto,
    t.fecha_transferencia AS fecha,
    t.cantidad,
    'transferencia' AS tipo
FROM transferencias t;

DELIMITER $$

CREATE PROCEDURE registrar_ingreso(
    IN p_fecha_ingreso DATETIME, 
    IN p_cantidad INT, 
    IN p_ubicacion_concat VARCHAR(20), 
    IN p_id_producto INT, 
    IN p_id_cliente INT, 
    IN p_id_usuario INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Manejo de errores
        ROLLBACK; 
        -- Deshacer cualquier cambio si ocurre un error
        SELECT 'Error al registrar ingreso' AS mensaje_error; 
        -- Mensaje de error
    END;

    START TRANSACTION; 
    -- Iniciar la transacción

    INSERT INTO ingreso (fecha_ingreso, cantidad, ubicacion_concat, id_producto, id_cliente, id_usuario)
    VALUES (p_fecha_ingreso, p_cantidad, p_ubicacion_concat, p_id_producto, p_id_cliente, p_id_usuario);

    COMMIT; 
    -- Confirmar la transacción si todo sale bien
END$$

DELIMITER ;

SHOW CREATE VIEW vista_estado_stock;
SHOW CREATE TRIGGER after_ingreso;
SHOW TRIGGERS;
SHOW PROCEDURE STATUS WHERE Db = 'almacen_mb';
SHOW CREATE PROCEDURE registrar_ingreso;









