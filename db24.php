<?php
//public $dbtype = 'mysqli';

	//public $host = 'pzpo.mysql';

	//public $user = 'pzpo_test';

	//public $password =

	//public $db = 'pzpo_test';

	//public $dbprefix = 'skphf_';
$servername = "localhost";
$database = "pzpo_test";
$username = "pzpo_test";
$password =  'tn1mkqig2FdVyRQmIGTf';
// Создаем соединение
$conn = mysqli_connect($servername, $username, $password, $database);
// Проверяем соединение
if (!$conn) {
    die("Connection failed: " . mysqli_connect_error());
}
echo "Connected successfully";
mysqli_close($conn);
?>
