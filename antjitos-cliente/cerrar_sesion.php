<?php
// Iniciar la sesión
session_start();

// Destruir todas las variables de sesión
$_SESSION = [];

// Destruir la sesión por completo
session_destroy();

// Redirigir al usuario a la página de inicio de sesión
header("Location: index.html");
exit;
?>
