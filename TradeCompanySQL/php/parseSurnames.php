<?php
$url = "http://localhost/berlit/dict/Surnames";
$content = file_get_contents($url);
//var_dump($content);

$surnames = explode(' ', $content);
//var_dump($surnames);

$pattern = '/[а-яА-Я]/';
foreach($surnames as $str) {
	if( preg_match ($pattern , $str) ) {
		$manSurnames[] = $str;
	}
}

// Женские фамилии : 
foreach($manSurnames as $str) {
	$len = iconv_strlen($str); $len1 = $len-1;
	$start = $len - 2; 
	$end = mb_substr ($str, $start, 2);
	if( ($end == 'ий') || ($end == 'ый') ) {
		$wsurn = mb_substr ($str, 0, $len-2) . 'ая'; 
	} else {$wsurn = $str . 'а';}
		$womanSurnames[] = $wsurn;
}
//var_dump( $womanSurnames );
$rusSurnames = array_combine ( $manSurnames, $womanSurnames );
foreach($rusSurnames as $man => $woman) {
	echo $man.' / '.$woman.'<br>';
}

// Запись мужских $manSurnames и женских $womanSurnames фамилий в таблицу SQL rusSurnames :
$servername = "localhost";
$username = "bigtrader";
$password = "secretgoods";
$dbname = "TradeCompany";

foreach($rusSurnames as $man => $woman) {
$man = trim($man);	$woman = trim($woman);
		try {
			//$conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
		$conn = new PDO('mysql:host=' .$servername. ';dbname=' .$dbname.';charset=utf8', $username, $password);
			// set the PDO error mode to exception
			$conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
			
			$sql = "INSERT INTO rusSurnames (msurname, wsurname)
			VALUES ('$man', '$woman')";
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
