<?php

namespace App\Services\AdminApp;

use App\Models\Order;
use App\Models\Ticket;
use App\Observers\OrderAdminPushObserver;
use App\Observers\TicketAdminPushObserver;

/**
 * Registers Eloquent observers for live holder events → admin phone push.
 * Called from routes/admin-app.php (loaded on every /api request).
 */
class LivePushRegistrar
{
    private static bool $registered = false;

    public static function register(): void
    {
        if (self::$registered) {
            return;
        }
        self::$registered = true;

        if (!class_exists(Order::class)) {
            return;
        }

        Order::observe(OrderAdminPushObserver::class);

        if (class_exists(Ticket::class)) {
            Ticket::observe(TicketAdminPushObserver::class);
        }
    }
}
