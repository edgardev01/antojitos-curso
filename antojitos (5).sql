-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 16-12-2024 a las 06:47:22
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `antojitos`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `crearCuentaUsuario` (IN `nombre` VARCHAR(255), IN `apellido` VARCHAR(255), IN `correo_electronico` VARCHAR(255), IN `password` VARCHAR(255))   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Verificar si el correo electrónico ya está en uso
    IF EXISTS (SELECT 1 FROM usuarios WHERE correo_electronico = correo_electronico) 
    THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'El correo electrónico ya está en uso';
        ROLLBACK;
    ELSE
        INSERT INTO usuarios (nombre, apellido, correo_electronico, password) 
        VALUES (nombre, apellido, correo_electronico, password);
        COMMIT;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `iniciarSesion` (IN `correo` VARCHAR(255), IN `contrasena` VARCHAR(255))   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error durante el inicio de sesión';
    END;

    START TRANSACTION;

    -- Verificar credenciales
    IF EXISTS (SELECT 1 FROM usuarios WHERE correo_electronico = correo AND password = contrasena) THEN

        -- Paso 2: Registrar log de sesión
        INSERT INTO logs_sesion (usuario_id, fecha_hora)
        VALUES ((SELECT id FROM usuarios WHERE correo_electronico = correo), NOW());

        -- Paso 3: Actualizar último inicio en `estado_inicio`
        INSERT INTO estado_inicio (usuario_id, ultimo_inicio)
        VALUES ((SELECT id FROM usuarios WHERE correo_electronico = correo), NOW())
        ON DUPLICATE KEY UPDATE ultimo_inicio = VALUES(ultimo_inicio);

    ELSE
        -- Si las credenciales son incorrectas
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credenciales incorrectas';
    END IF;

    -- Confirmar cambios
    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `iniciarSesionCliente` (IN `correo` VARCHAR(255), IN `contrasena` VARCHAR(255))   BEGIN
    DECLARE cliente_id INT;

    -- Verificar credenciales
    SELECT id_cliente INTO cliente_id
    FROM clientes
    WHERE correo_electronico = correo AND password = contrasena;

    IF cliente_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Credenciales incorrectas';
    ELSE
        -- Registrar log de sesión
        INSERT INTO logs_sesion_clientes (cliente_id, fecha_hora)
        VALUES (cliente_id, NOW());
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registrarCliente` (IN `nombre_param` VARCHAR(255), IN `apellido_param` VARCHAR(255), IN `correo_param` VARCHAR(255), IN `password_param` VARCHAR(255))   BEGIN
    -- Declaración de variables
    DECLARE resultado_validacion VARCHAR(255);

    -- Validar la contraseña
    SET resultado_validacion = validar_contraseña(password_param);
    IF resultado_validacion != 'La contraseña es válida' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = resultado_validacion;
    END IF;

    -- Verificar si el correo ya existe
    IF EXISTS (SELECT 1 FROM clientes WHERE correo_electronico = correo_param) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El correo electrónico ya está en uso';
    ELSE
        -- Insertar al cliente
        INSERT INTO clientes (nombre, apellido, correo_electronico, password)
        VALUES (nombre_param, apellido_param, correo_param, password_param);
    END IF;
END$$

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `calcular_total_pedido` (`id_pedido` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
    DECLARE total DECIMAL(10,2);
    
    -- Sumar los precios de los productos relacionados con el pedido
    SELECT SUM(p.precio * dp.cantidad) INTO total
    FROM productos p
    INNER JOIN detalle_pedido dp ON p.id_producto = dp.id_producto
    WHERE dp.id_pedido = id_pedido;
    
    RETURN IFNULL(total, 0);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `validar_contraseña` (`contra_input` VARCHAR(255)) RETURNS VARCHAR(255) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
    DECLARE largo INT;
    DECLARE tiene_numero INT;
    DECLARE tiene_mayuscula INT;
    DECLARE tiene_caracter_especial INT;

    SET largo = CHAR_LENGTH(contra_input);
    SET tiene_numero = IF(contra_input REGEXP '[0-9]', 1, 0);
    SET tiene_mayuscula = IF(contra_input REGEXP '[A-Z]', 1, 0);
    SET tiene_caracter_especial = IF(contra_input REGEXP '[^A-Za-z0-9]', 1, 0);

    IF largo < 8 THEN
        RETURN 'La contraseña debe tener al menos 8 caracteres';
    ELSEIF tiene_numero = 0 THEN
        RETURN 'La contraseña debe contener al menos un número';
    ELSEIF tiene_mayuscula = 0 THEN
        RETURN 'La contraseña debe contener al menos una letra mayúscula';
    ELSEIF tiene_caracter_especial = 0 THEN
        RETURN 'La contraseña debe contener al menos un carácter especial';
    ELSE
        RETURN 'La contraseña es válida';
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `bebidas`
--

CREATE TABLE `bebidas` (
  `id_bebida` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `descripcion` text NOT NULL,
  `imagen` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `checkbox`
--

CREATE TABLE `checkbox` (
  `id` int(11) NOT NULL,
  `tipo_producto_id` int(11) NOT NULL,
  `nombre_tipo` varchar(255) NOT NULL,
  `columna` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clientes`
--

CREATE TABLE `clientes` (
  `id_cliente` int(11) NOT NULL,
  `nombre` varchar(255) NOT NULL,
  `apellido` varchar(255) NOT NULL,
  `correo_electronico` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `clientes`
--

INSERT INTO `clientes` (`id_cliente`, `nombre`, `apellido`, `correo_electronico`, `password`) VALUES
(1, 'Carlos', 'González', 'carlos.gonzalez@example.com', 'Password123!'),
(2, 'test1', 'test1', 'test@gmail.com', 'Password123!');

--
-- Disparadores `clientes`
--
DELIMITER $$
CREATE TRIGGER `before_insert_cliente` BEFORE INSERT ON `clientes` FOR EACH ROW BEGIN
    DECLARE resultado_validacion VARCHAR(255);

    -- Validar contraseña
    SET resultado_validacion = validar_contraseña(NEW.password);

    IF resultado_validacion != 'La contraseña es válida' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = resultado_validacion;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `combobox`
--

CREATE TABLE `combobox` (
  `id` int(11) NOT NULL,
  `tipo_producto_id` int(11) NOT NULL,
  `tipo` varchar(255) NOT NULL,
  `ingredientes` varchar(255) NOT NULL,
  `columna` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_pedido`
--

CREATE TABLE `detalle_pedido` (
  `id_detalle` int(11) NOT NULL,
  `id_pedido` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `estado_inicio`
--

CREATE TABLE `estado_inicio` (
  `usuario_id` int(11) NOT NULL,
  `ultimo_inicio` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Disparadores `estado_inicio`
--
DELIMITER $$
CREATE TRIGGER `after_update_estado_inicio` AFTER UPDATE ON `estado_inicio` FOR EACH ROW BEGIN
    -- Insertar un log de sesión
    INSERT INTO logs_sesion (usuario_id, fecha_hora)
    VALUES (NEW.usuario_id, NOW());
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `estado_inicio_clientes`
--

CREATE TABLE `estado_inicio_clientes` (
  `cliente_id` int(11) NOT NULL,
  `ultimo_inicio` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `estado_inicio_clientes`
--

INSERT INTO `estado_inicio_clientes` (`cliente_id`, `ultimo_inicio`) VALUES
(1, '2024-12-15 23:06:30'),
(2, '2024-12-15 23:18:53');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `logs_sesion`
--

CREATE TABLE `logs_sesion` (
  `id` int(11) NOT NULL,
  `usuario_id` int(11) DEFAULT NULL,
  `fecha_hora` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Disparadores `logs_sesion`
--
DELIMITER $$
CREATE TRIGGER `after_insert_logs_sesion` AFTER INSERT ON `logs_sesion` FOR EACH ROW BEGIN
    -- Actualizar el último inicio de sesión en `estado_inicio`
    INSERT INTO estado_inicio (usuario_id, ultimo_inicio)
    VALUES (NEW.usuario_id, NEW.fecha_hora)
    ON DUPLICATE KEY UPDATE ultimo_inicio = VALUES(ultimo_inicio);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `logs_sesion_clientes`
--

CREATE TABLE `logs_sesion_clientes` (
  `id` int(11) NOT NULL,
  `cliente_id` int(11) NOT NULL,
  `fecha_hora` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `logs_sesion_clientes`
--

INSERT INTO `logs_sesion_clientes` (`id`, `cliente_id`, `fecha_hora`) VALUES
(2, 1, '2024-12-15 23:03:23'),
(3, 1, '2024-12-15 23:04:35'),
(4, 1, '2024-12-15 23:06:30'),
(5, 2, '2024-12-15 23:18:53');

--
-- Disparadores `logs_sesion_clientes`
--
DELIMITER $$
CREATE TRIGGER `after_insert_logs_sesion_clientes` AFTER INSERT ON `logs_sesion_clientes` FOR EACH ROW BEGIN
    INSERT INTO estado_inicio_clientes (cliente_id, ultimo_inicio)
    VALUES (NEW.cliente_id, NEW.fecha_hora)
    ON DUPLICATE KEY UPDATE ultimo_inicio = VALUES(ultimo_inicio);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pedidos`
--

CREATE TABLE `pedidos` (
  `id_pedido` int(11) NOT NULL,
  `fecha_hora` datetime NOT NULL DEFAULT current_timestamp(),
  `estado` enum('Pendiente','Confirmado','Cancelado') NOT NULL DEFAULT 'Pendiente'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Disparadores `pedidos`
--
DELIMITER $$
CREATE TRIGGER `verificar_horario_pedido` BEFORE INSERT ON `pedidos` FOR EACH ROW BEGIN
    DECLARE hora_actual TIME;
    SET hora_actual = CURRENT_TIME;

    IF hora_actual NOT BETWEEN '09:00:00' AND '22:00:00' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se pueden realizar pedidos fuera del horario permitido.';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `verificar_pedido_con_productos` BEFORE UPDATE ON `pedidos` FOR EACH ROW BEGIN
    -- Declarar la variable al inicio del bloque
    DECLARE num_productos INT DEFAULT 0;

    -- Verificar si el estado es "Confirmado"
    IF NEW.estado = 'Confirmado' THEN
        -- Contar los productos asociados al pedido
        SELECT COUNT(*)
        INTO num_productos
        FROM detalle_pedido
        WHERE id_pedido = NEW.id_pedido;

        -- Validar si no hay productos
        IF num_productos = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede confirmar un pedido sin productos.';
        END IF;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `producto`
--

CREATE TABLE `producto` (
  `id` int(11) NOT NULL,
  `nombre_producto` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id_producto` int(11) NOT NULL,
  `nombre_producto` varchar(255) NOT NULL,
  `precio` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`id_producto`, `nombre_producto`, `precio`) VALUES
(1, 'Producto 1', 10.50),
(2, 'Producto 2', 20.00),
(3, 'Producto 3', 15.75),
(4, 'Producto 1', 10.50),
(5, 'Producto 2', 20.00),
(6, 'Producto 3', 15.75);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_producto`
--

CREATE TABLE `tipo_producto` (
  `id` int(11) NOT NULL,
  `producto_id` int(11) NOT NULL,
  `nombre_tipo` varchar(255) NOT NULL,
  `imagen_url` varchar(255) DEFAULT NULL,
  `frase1` varchar(255) DEFAULT NULL,
  `precio` decimal(10,2) NOT NULL,
  `cantidad_max` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id` int(11) NOT NULL,
  `nombre` varchar(255) NOT NULL,
  `apellido` varchar(255) NOT NULL,
  `correo_electronico` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id`, `nombre`, `apellido`, `correo_electronico`, `password`) VALUES
(1, 'Juan', 'Pérez', 'juan.perez@example.com', 'Password123!');

--
-- Disparadores `usuarios`
--
DELIMITER $$
CREATE TRIGGER `before_insert_usuario` BEFORE INSERT ON `usuarios` FOR EACH ROW BEGIN
    DECLARE resultado_validacion VARCHAR(255);
    -- Validar contraseña con la función
    SET resultado_validacion = validar_contraseña(NEW.password);

    -- Si la contraseña no es válida, genera un error
    IF resultado_validacion != 'La contraseña es válida' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = resultado_validacion;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_insert_usuarios` BEFORE INSERT ON `usuarios` FOR EACH ROW BEGIN
    -- Verificar si el correo ya existe
    IF EXISTS (SELECT 1 FROM usuarios WHERE correo_electronico = NEW.correo_electronico) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El correo electrónico ya está en uso';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `volumenes`
--

CREATE TABLE `volumenes` (
  `id_volumen` int(11) NOT NULL,
  `id_bebida` int(11) NOT NULL,
  `volumen` varchar(50) NOT NULL,
  `precio` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Disparadores `volumenes`
--
DELIMITER $$
CREATE TRIGGER `before_insert_volumenes` BEFORE INSERT ON `volumenes` FOR EACH ROW BEGIN
    -- Verificar que el precio sea mayor a 0
    IF NEW.precio <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El precio debe ser mayor a cero';
    END IF;
END
$$
DELIMITER ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `bebidas`
--
ALTER TABLE `bebidas`
  ADD PRIMARY KEY (`id_bebida`);

--
-- Indices de la tabla `checkbox`
--
ALTER TABLE `checkbox`
  ADD PRIMARY KEY (`id`),
  ADD KEY `tipo_producto_id` (`tipo_producto_id`);

--
-- Indices de la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`id_cliente`),
  ADD UNIQUE KEY `correo_electronico` (`correo_electronico`);

--
-- Indices de la tabla `combobox`
--
ALTER TABLE `combobox`
  ADD PRIMARY KEY (`id`),
  ADD KEY `tipo_producto_id` (`tipo_producto_id`);

--
-- Indices de la tabla `detalle_pedido`
--
ALTER TABLE `detalle_pedido`
  ADD PRIMARY KEY (`id_detalle`),
  ADD KEY `id_pedido` (`id_pedido`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `estado_inicio`
--
ALTER TABLE `estado_inicio`
  ADD PRIMARY KEY (`usuario_id`);

--
-- Indices de la tabla `estado_inicio_clientes`
--
ALTER TABLE `estado_inicio_clientes`
  ADD PRIMARY KEY (`cliente_id`);

--
-- Indices de la tabla `logs_sesion`
--
ALTER TABLE `logs_sesion`
  ADD PRIMARY KEY (`id`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `logs_sesion_clientes`
--
ALTER TABLE `logs_sesion_clientes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `cliente_id` (`cliente_id`);

--
-- Indices de la tabla `pedidos`
--
ALTER TABLE `pedidos`
  ADD PRIMARY KEY (`id_pedido`);

--
-- Indices de la tabla `producto`
--
ALTER TABLE `producto`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id_producto`);

--
-- Indices de la tabla `tipo_producto`
--
ALTER TABLE `tipo_producto`
  ADD PRIMARY KEY (`id`),
  ADD KEY `producto_id` (`producto_id`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `correo_electronico` (`correo_electronico`);

--
-- Indices de la tabla `volumenes`
--
ALTER TABLE `volumenes`
  ADD PRIMARY KEY (`id_volumen`),
  ADD KEY `id_bebida` (`id_bebida`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `bebidas`
--
ALTER TABLE `bebidas`
  MODIFY `id_bebida` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `checkbox`
--
ALTER TABLE `checkbox`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `clientes`
--
ALTER TABLE `clientes`
  MODIFY `id_cliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `combobox`
--
ALTER TABLE `combobox`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `detalle_pedido`
--
ALTER TABLE `detalle_pedido`
  MODIFY `id_detalle` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `logs_sesion`
--
ALTER TABLE `logs_sesion`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `logs_sesion_clientes`
--
ALTER TABLE `logs_sesion_clientes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `pedidos`
--
ALTER TABLE `pedidos`
  MODIFY `id_pedido` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `producto`
--
ALTER TABLE `producto`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `id_producto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `tipo_producto`
--
ALTER TABLE `tipo_producto`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `volumenes`
--
ALTER TABLE `volumenes`
  MODIFY `id_volumen` int(11) NOT NULL AUTO_INCREMENT;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `checkbox`
--
ALTER TABLE `checkbox`
  ADD CONSTRAINT `checkbox_ibfk_1` FOREIGN KEY (`tipo_producto_id`) REFERENCES `tipo_producto` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `combobox`
--
ALTER TABLE `combobox`
  ADD CONSTRAINT `combobox_ibfk_1` FOREIGN KEY (`tipo_producto_id`) REFERENCES `tipo_producto` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `detalle_pedido`
--
ALTER TABLE `detalle_pedido`
  ADD CONSTRAINT `detalle_pedido_ibfk_1` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`) ON DELETE CASCADE,
  ADD CONSTRAINT `detalle_pedido_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE CASCADE;

--
-- Filtros para la tabla `estado_inicio`
--
ALTER TABLE `estado_inicio`
  ADD CONSTRAINT `estado_inicio_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`);

--
-- Filtros para la tabla `estado_inicio_clientes`
--
ALTER TABLE `estado_inicio_clientes`
  ADD CONSTRAINT `estado_inicio_clientes_ibfk_1` FOREIGN KEY (`cliente_id`) REFERENCES `clientes` (`id_cliente`);

--
-- Filtros para la tabla `logs_sesion`
--
ALTER TABLE `logs_sesion`
  ADD CONSTRAINT `logs_sesion_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`);

--
-- Filtros para la tabla `logs_sesion_clientes`
--
ALTER TABLE `logs_sesion_clientes`
  ADD CONSTRAINT `logs_sesion_clientes_ibfk_1` FOREIGN KEY (`cliente_id`) REFERENCES `clientes` (`id_cliente`) ON DELETE CASCADE;

--
-- Filtros para la tabla `tipo_producto`
--
ALTER TABLE `tipo_producto`
  ADD CONSTRAINT `tipo_producto_ibfk_1` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `volumenes`
--
ALTER TABLE `volumenes`
  ADD CONSTRAINT `volumenes_ibfk_1` FOREIGN KEY (`id_bebida`) REFERENCES `bebidas` (`id_bebida`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
