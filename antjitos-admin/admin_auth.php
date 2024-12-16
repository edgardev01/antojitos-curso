<?php
require 'db_connection.php';

// Registro de Administrador
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['register_admin'])) {
    $nombre = $_POST['nombre'];
    $apellido = $_POST['apellido'];
    $correo = $_POST['correo'];
    $password = $_POST['password'];

    try {
        $conn->beginTransaction(); // Iniciar transacción

        $stmt = $conn->prepare("CALL crearCuentaUsuario(:nombre, :apellido, :correo, :password)");
        $stmt->bindParam(':nombre', $nombre);
        $stmt->bindParam(':apellido', $apellido);
        $stmt->bindParam(':correo', $correo);
        $stmt->bindParam(':password', $password);
        $stmt->execute();

        $conn->commit(); // Confirmar transacción
        echo "Administrador registrado exitosamente.";
    } catch (PDOException $e) {
        $conn->rollBack(); // Revertir transacción en caso de error
        echo "Error en el registro: " . $e->getMessage();
    }
}

// Inicio de Sesión de Administrador
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['login_admin'])) {
    $correo = $_POST['correo'];
    $password = $_POST['password'];

    try {
        $conn->beginTransaction(); // Iniciar transacción

        // Crear un punto de restauración
        $conn->exec("SAVEPOINT login_checkpoint");

        $stmt = $conn->prepare("CALL iniciarSesion(:correo, :password)");
        $stmt->bindParam(':correo', $correo);
        $stmt->bindParam(':password', $password);
        $stmt->execute();

        $conn->commit(); // Confirmar transacción
        echo "Inicio de sesión exitoso.";
    } catch (PDOException $e) {
        $conn->exec("ROLLBACK TO login_checkpoint"); // Revertir al punto de restauración en caso de error
        $conn->rollBack(); // Revertir toda la transacción
        echo "Error en el inicio de sesión: " . $e->getMessage();
    }
}
?>
