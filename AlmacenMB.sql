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
