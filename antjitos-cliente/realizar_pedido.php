<?php
require 'db_connection.php'; // Archivo de conexión a la base de datos

header('Content-Type: application/json');

// Leer el cuerpo de la solicitud
$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['producto'], $input['cantidad'])) {
    echo json_encode(['success' => false, 'message' => 'Datos incompletos.']);
    exit;
}

$producto = (int)$input['producto'];
$cantidad = (int)$input['cantidad'];

try {
    // Iniciar una transacción
    $conn->beginTransaction();

    // Insertar el pedido (estado inicial: Pendiente)
    $stmt = $conn->prepare("INSERT INTO pedidos (estado) VALUES ('Pendiente')");
    $stmt->execute();

    // Obtener el ID del pedido recién creado
    $pedido_id = $conn->lastInsertId();

    // Insertar el detalle del pedido
    $detalle_stmt = $conn->prepare("INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad) VALUES (:id_pedido, :id_producto, :cantidad)");
    $detalle_stmt->execute([
        ':id_pedido' => $pedido_id,
        ':id_producto' => $producto,
        ':cantidad' => $cantidad,
    ]);

    // Confirmar la transacción
    $conn->commit();

    echo json_encode(['success' => true, 'message' => 'Pedido realizado correctamente.']);
} catch (PDOException $e) {
    // Revertir la transacción en caso de error
    $conn->rollBack();
    
    // Capturar errores de los triggers o SQL
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
