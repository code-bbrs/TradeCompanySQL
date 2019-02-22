<?php
$url = "http://localhost/berlit/dict/Wnames";
$content = file_get_contents($url);
//var_dump($content);

$surnames = explode(' ', $content);
//var_dump($surnames);

$pattern = '/[а-яА-Я]/';
foreach($surnames as $str) {
	if( preg_match ($pattern , $str) ) {
		$womanNames[] = trim($str);
	}
}

foreach($womanNames as $str) {
	echo( $str.'<br>' );
}


// Запись женских имен $womanNames в таблицу SQL rusWomanNames :
$servername = "localhost";
$username = "bigtrader";
$password = "secretgoods";
$dbname = "TradeCompany";

foreach($womanNames as $wname) {
$wname = trim($wname);
		try {
			//$conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
		$conn = new PDO('mysql:host=' .$servername. ';dbname=' .$dbname.';charset=utf8', $username, $password);
			// set the PDO error mode to exception
			$conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
			
			$sql = "INSERT INTO rusWomanNames (wname)
			VALUES ( '$wname' )";
			// use exec() because no results are returned
			$conn->exec($sql);
			echo "New record created successfully";
			}
		catch(PDOException $e)
			{
			echo $sql . "<br>" . $e->getMessage();
			}

		$conn = null;


}

