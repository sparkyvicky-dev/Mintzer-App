<?php

namespace App\Services\AdminApp;

/**
 * One-line hooks for live newapp holder APIs (Phase 3).
 *
 * Example after invoice upload in API OrderController:
 *   \App\Services\AdminApp\AdminEventHooks::invoiceUploaded($order->id);
 */
class AdminEventHooks
{
    public static function invoiceUploaded(int $orderId): void
    {
        AdminPushService::notifyFromOrderEvent('invoice_uploaded', $orderId);
    }

    public static function pinePaymentWaiting(int $orderId): void
    {
        AdminPushService::notifyFromOrderEvent('waiting_payment', $orderId);
    }

    public static function payoutReady(int $orderId): void
    {
        AdminPushService::notifyFromOrderEvent('payout_ready', $orderId);
    }

    public static function storeOrderIdEntered(int $orderId): void
    {
        AdminPushService::notifyFromOrderEvent('new_order', $orderId);
    }

    public static function trackingIdEntered(int $orderId): void
    {
        AdminPushService::notifyFromOrderEvent('tracking_updated', $orderId);
    }

    public static function otpEntered(int $orderId): void
    {
        AdminPushService::notifyFromOrderEvent('otp_updated', $orderId);
    }

    public static function newTicket(int $ticketId, string $subject, string $userName): void
    {
        AdminPushService::notifyNewTicket($ticketId, $subject, $userName);
    }
}
