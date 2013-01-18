<?php

$devmode = defined("DEV_MODE") && DEV_MODE;

$headers = getPreparedHeader();
$receiptdata = $_POST['receipt'];
$uuid = $headers["x-device-uuid"];

$verificationStatus = false;

if ($receiptdata && $uuid && strlen($uuid) > 1) {
	$response = verificationResultForReceipt($receiptdata, $devmode);
	if($response && $response->{'status'} == 0) {
		$verificationStatus = true;
	}
}

header('Content-type: application/json');
echo json_encode(array("status" => $verificationStatus));
die();

function getPreparedHeader() {
	if(!function_exists('apache_request_headers')) {
        $headers = array();
        foreach($_SERVER as $key => $value) {
            if(substr($key, 0, 5) == 'HTTP_') {
                $headers[str_replace('_', '-', strtolower(substr($key, 5)))] = $value;
            }
        }
        return $headers;
	} else {
		$_headers = apache_request_headers();
		$headers = array();
		foreach($_headers AS $k => $v) {
			$headers[strtolower($k)] = $v;
		}
		
		return $headers;
	}
}

function verificationResultForReceipt($receiptdata, $devmode) {
	if (!$receiptdata) {
		return false;
	}

	if($devmode) {
		$appleURL = "https://sandbox.itunes.apple.com/verifyReceipt";
	} else {
		$appleURL = "https://buy.itunes.apple.com/verifyReceipt";
	}	
	$receipt = json_encode(array("receipt-data" => $receiptdata));

	$params = array('http' => array(
	              		'method' => 'POST',
	              		'content' => $receipt
	            ));

	$ctx = stream_context_create($params);

	$fp = @fopen($appleURL, 'rb', false, $ctx);
	if (!$fp) {
		return false;
	}

	$response_json = @stream_get_contents($fp);	
	if ($response_json === false) {
		return false;
	}

	$response = json_decode($response_json);
	if($response && $response->{'status'} === 21007 && !$devmode) {
		return verificationResultForReceipt($receiptdata, true);
	}

	return $response;
}

?>