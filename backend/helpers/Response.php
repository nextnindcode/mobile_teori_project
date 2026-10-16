<?php
class Response
{
    public static function success($data = null, $message = "OK", $code = 200)
    {
        http_response_code($code);
        header('Content-Type: application/json');
        echo json_encode([
            "success" => true,
            "message" => $message,
            "data" => $data
        ]);
        exit;
    }

    public static function error($message, $code = "ERROR", $httpCode = 400)
    {
        http_response_code($httpCode);
        header('Content-Type: application/json');
        echo json_encode([
            "success" => false,
            "message" => $message,
            "code" => $code
        ]);
        exit;
    }
}
