<?php
require_once __DIR__ . '/../models/EventModel.php';
require_once __DIR__ . '/../models/TokenModel.php';
require_once __DIR__ . '/../helpers/Response.php';

class EventController
{
    private $eventModel;
    private $tokenModel;

    public function __construct()
    {
        $this->eventModel = new EventModel();
        $this->tokenModel = new TokenModel();
    }

    // GET /events
    public function list()
    {
        $this->requireAuth();

        $events = $this->eventModel->getAll();

        foreach ($events as &$e) {
            $e['id'] = (int)$e['id'];
            $e['latitude'] = $e['latitude'] !== null ? (float)$e['latitude'] : null;
            $e['longitude'] = $e['longitude'] !== null ? (float)$e['longitude'] : null;
        }

        Response::success($events);
    }

    // GET /events/detail atau GET /events/{id}
    public function detail($id = null)
    {
        $this->requireAuth();

        $eventId = $id ?? ($_GET['id'] ?? null);
        if (!$eventId || !is_numeric($eventId)) {
            Response::error("ID event tidak valid", "VALIDATION_ERROR", 422);
        }

        $event = $this->eventModel->findById((int)$eventId);
        if (!$event) {
            Response::error("Event tidak ditemukan", "NOT_FOUND", 404);
        }

        $event['id'] = (int)$event['id'];
        $event['latitude'] = $event['latitude'] !== null ? (float)$event['latitude'] : null;
        $event['longitude'] = $event['longitude'] !== null ? (float)$event['longitude'] : null;

        Response::success($event);
    }

    private function requireAuth()
    {
        $headers = function_exists('getallheaders') ? getallheaders() : [];
        $auth = $headers['Authorization'] ?? $headers['authorization'] ?? $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';

        if (!preg_match('/Bearer\s+(\S+)/i', $auth, $matches)) {
            Response::error("Token tidak ditemukan", "TOKEN_EXPIRED", 401);
        }

        $tokenHash = hash('sha256', $matches[1]);
        $tokenData = $this->tokenModel->findValidByHash($tokenHash);

        if (!$tokenData) {
            Response::error("Token tidak valid atau kedaluwarsa", "TOKEN_EXPIRED", 401);
        }

        return (int)$tokenData['user_id'];
    }
}

