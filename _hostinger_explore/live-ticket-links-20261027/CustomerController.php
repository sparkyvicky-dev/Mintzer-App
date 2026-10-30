<?php

namespace App\Http\Controllers\Admin\Customer;

use App\Enums\LogType;
use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Models\Order;
use App\Models\Ticket;
use App\Models\TicketReply;
use App\Models\User;
use App\Traits\Common;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Schema;

class CustomerController extends Controller
{
    use Common;
    public function customers()
    {
        try {
            $verified_Count = User::Customer()->VerifiedCustomer()->count();
            $unVerified_Count = User::Customer()->where('is_verified', 0)->count();
            return view('admin.customer.customer-list', compact('verified_Count', 'unVerified_Count'));
        } catch (\Exception $th) {
            $this->Log(__FUNCTION__, "GET", $th->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
            $notification = array(
                'message' => 'Somthing wend wrong!',
                'alert-type' => 'error'
            );
            return redirect()->back()->with($notification);
        }
    }
    public function customersInfo($id)
    {
        try {
            $customer = User::where('id', $id)->first();
            // dd($customer);
            return view('admin.customer.customer-info', compact('customer'));
        } catch (\Exception $th) {
            $this->Log(__FUNCTION__, "GET", $th->getMessage(), Auth::user()->id, request()->ip(), gethostname(),0,LogType::Error);
            $notification = array(
                'message' => 'Somthing wend wrong!',
                'alert-type' => 'error'
            );
            return redirect()->back()->with($notification);
        }
    }

    public function customerInfo($id)
    {
        try {
            $customer = User::with(['orders' => function ($q) {
                $q->where('order_status', 'Delivered')
                    ->with('deal')
                    ->orderBy('id', 'DESC');
            }])->findOrFail($id);

            $totalOrders = $customer->orders->count();
            $totalEarnings = $customer->orders->sum('earnings');

            return view('admin.customer.customer-info', compact(
                'customer',
                'totalOrders',
                'totalEarnings'
            ));
        } catch (\Exception $th) {
            $this->Log(__FUNCTION__, "GET", $th->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
            $notification = ['message' => 'Customer not found!', 'alert-type' => 'error'];
            return redirect()->route('customers')->with($notification);
        }
    }

    public function getCustomerDeliveredOrders(Request $request)
    {
        $id = $request->get('user_id');
        $orders = Order::select(
            'orders.*',
            'users.display_name as user_name',
            'deals.name as deal_name',
            'deals.card_holder_recieve'
        )
            ->join('users', 'users.id', '=', 'orders.user_id')
            ->join('deals', 'deals.id', '=', 'orders.deal_id')
            ->where('orders.user_id', $id)
            ->where('orders.order_status', 'Delivered')
            ->where('orders.is_payout', 1)
            ->whereNull('orders.deleted_at')
            ->orderBy('orders.id', 'DESC')
            ->get();

        return datatables()
            ->of($orders)
            ->addIndexColumn()
            ->toJson();
    }

    public function get_customers_data(Request $request)
    {
        $isVerified = $request->get('isVerified');
        $status = $request->get('status');
        $customers = User::Customer();
        if ($isVerified === '0') {
            $customers = $customers->where('is_verified', 0);
        } elseif ($isVerified === '1') {
            $customers = $customers->where('is_verified', 1);
        }

        if ($status === '0') {
            $customers = $customers->where('is_active', 0);
        } elseif ($status === '1') {
            $customers = $customers->where('is_active', 1);
        }

        $sort = (string) $request->get('sort', 'joined_desc');
        if ($sort === 'name_asc') {
            $customers = $customers->orderBy('display_name', 'asc')->orderBy('id', 'asc');
        } elseif ($sort === 'name_desc') {
            $customers = $customers->orderBy('display_name', 'desc')->orderBy('id', 'desc');
        } elseif ($sort === 'joined_asc') {
            $customers = $customers->orderBy('created_at', 'asc')->orderBy('id', 'asc');
        } else {
            $customers = $customers->orderBy('created_at', 'desc')->orderBy('id', 'desc');
        }

        $customers = $customers->get();

        return datatables()->of($customers)
            ->editColumn('created_at', function ($user) {
                if (empty($user->created_at)) {
                    return '';
                }
                try {
                    return \Carbon\Carbon::parse($user->created_at)->format('d M Y, h:i A');
                } catch (\Throwable $e) {
                    return (string) $user->created_at;
                }
            })
            ->toJson();
    }

    public function get_customers_detail(Request $request)
    {
        $customers = User::where('id', $request->id)->first();
        return response()->json(['customer' => $customers]);
    }

    public function tickets()
    {
        try {
            return view('admin.customer.tickets');
        } catch (\Exception $th) {
            $this->Log(__FUNCTION__, "GET", $th->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
        }
    }


    public function getTicketsdata()
    {
        $tickets = Ticket::select(
            'tickets.*',
            'users.display_name',
            'users.mobile',
            'subjects.name'
        )->join('users', 'users.id', '=', 'tickets.user_id')
            ->leftJoin('subjects', 'subjects.id', '=', 'tickets.subject_id')
            ->orderBy('tickets.id', 'DESC')
            ->get();

        return datatables()->of($tickets)->toJson();
    }

    public function statusUpdate(Request $request, $id)
    {
        try {
            $ticket = Ticket::find($id);
            if ($ticket) {
                $ticket->ticket_status = $request->status;
                $ticket->updated_by = Auth::user()->id;
                $ticket->update();
                $notification = array(
                    'message' => 'Ticket Status Updated Successfully',
                    'type' => 'success'
                );
            } else {
                $notification = array(
                    'message' => 'Ticket Not Found',
                    'type' => 'error'
                );
            }
        } catch (\Throwable $th) {
            $this->Log(__FUNCTION__, "GET", $th->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
            $notification = array(
                'message' => 'Something Wend Wrong',
                'type' => 'error'
            );
        }

        return response()->json([
            'notification' => $notification,
        ]);
    }

    public function customerChangeStatus($id, $status)
    {
        try {
            $ordersCount = Order::whereNotIn('order_status', ['Delivered', 'Declined', 'Cancelled'])
                ->where('user_id', $id)
                ->count();
            $pineLabOrdersCount = Order::where('is_pine_lab_deal', 1)
                ->where('is_payment_verified', 0)
                ->where('user_id', $id)
                ->count();
            $overAllCount = $ordersCount + $pineLabOrdersCount;
            if ($overAllCount > 0 && $status == 0) {
                return response()->json(['success' => false, 'message' => 'Cannot deactivate customer with pending orders.']);
            }
            $customer = User::findOrFail($id);
            
            $customer->update([
                'is_active' => $status
            ]);

            $fcmTokens = $customer->fcm_token;
            $title = $status == 1 ? 'Account Activated' : 'Account Deactivated';
            $body = $status == 1 ? 'Your account has been activated.' : 'Your account has been deactivated.';

            // Send Push Notification
            if ($fcmTokens) {
                $notification = new Notification();
                $notification->user_id = $id;
                $notification->title = $title;
                $notification->content = $body;
                $notification->save();
                $this->sendVerificationPushNotify($fcmTokens, $title, $body, null, null);
            }

            return response()->json(['success' => true, 'message' => 'Status updated successfully.']);
        } catch (Exception $e) {
            $this->Log(__FUNCTION__, "POST", $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
        }
    }

    public function notifications()
    {
        try {
            $tickets = Ticket::where('is_notified', 0)->with(['ticketSubject'])->orderBy('id', 'desc')->get();
            return response()->json(['tickets' => $tickets]);
        } catch (\Exception $th) {
            $this->Log(__FUNCTION__, "GET", $th->getMessage(), Auth::user()->id ?? null, request()->ip(), gethostname(), 0, LogType::Error);
            return response()->json(['tickets' => []], 500);
        }
    }

    public function markNotified(Request $request)
    {
        try {
            $id = $request->id;
            $ticket = Ticket::find($id);
            if ($ticket) {
                $ticket->is_notified = 1;
                $ticket->update();
                return response()->json(['success' => true]);
            }

            return response()->json(['success' => false], 404);
        } catch (\Exception $th) {
            $this->Log(__FUNCTION__, "POST", $th->getMessage(), Auth::user()->id ?? null, request()->ip(), gethostname(), 0, LogType::Error);
            return response()->json(['success' => false], 500);
        }
    }

    /** Additive: ticket thread for admin reply modal. */
    public function ticketThread($id)
    {
        try {
            $ticket = Ticket::with(['user', 'ticketSubject'])->find($id);
            if (!$ticket) {
                return response()->json(['success' => false, 'message' => 'Ticket not found'], 404);
            }

            $replies = [];
            if (class_exists(TicketReply::class) && Schema::hasTable('ticket_replies')) {
                $replies = TicketReply::where('ticket_id', $ticket->id)
                    ->orderBy('created_at')
                    ->get()
                    ->map(function ($r) {
                        $fromUser = (bool) ($r->is_from_user ?? false);
                        return [
                            'id' => $r->id,
                            'from_user' => $fromUser,
                            'author' => $fromUser
                                ? ($ticket->user->display_name ?? 'User')
                                : ($r->staff_name ?: 'Mintzer'),
                            'message' => $r->message,
                            'created_at' => optional($r->created_at)->format('d-m-Y h:i A'),
                        ];
                    })
                    ->values();
            }

            return response()->json([
                'success' => true,
                'ticket' => [
                    'id' => $ticket->id,
                    'user_id' => $ticket->user_id,
                    'customer' => $ticket->user->display_name ?? '',
                    'mobile' => $ticket->user->mobile ?? '',
                    'subject' => $ticket->ticketSubject->name ?? $ticket->subject,
                    'message' => $ticket->message,
                    'status' => (int) $ticket->ticket_status,
                    'created_at' => optional($ticket->created_at)->format('d-m-Y h:i A'),
                ],
                'replies' => $replies,
                'supports_replies' => class_exists(TicketReply::class) && Schema::hasTable('ticket_replies'),
            ]);
        } catch (\Exception $th) {
            $this->Log(__FUNCTION__, "GET", $th->getMessage(), Auth::user()->id ?? null, request()->ip(), gethostname(), 0, LogType::Error);
            return response()->json(['success' => false, 'message' => 'Something went wrong'], 500);
        }
    }

    /** Additive: staff reply from web admin Tickets page. */
    public function ticketReply(Request $request, $id)
    {
        try {
            if (!class_exists(TicketReply::class) || !Schema::hasTable('ticket_replies')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Replies table not ready. Run the one-shot migrator first.',
                ], 503);
            }

            $request->validate([
                'message' => 'required|string|max:5000',
            ]);

            $ticket = Ticket::find($id);
            if (!$ticket) {
                return response()->json(['success' => false, 'message' => 'Ticket not found'], 404);
            }

            $reply = TicketReply::create([
                'ticket_id' => $ticket->id,
                'staff_user_id' => Auth::id(),
                'staff_name' => Auth::user()->display_name ?? Auth::user()->email ?? 'Mintzer',
                'user_id' => null,
                'is_from_user' => false,
                'message' => trim($request->message),
            ]);

            if ((int) $ticket->ticket_status === 1) {
                $ticket->ticket_status = 2;
            }
            $ticket->updated_by = Auth::id();
            $ticket->save();

            // Bell inbox + push so the holder sees admin replies.
            $preview = trim($reply->message);
            if (mb_strlen($preview) > 140) {
                $preview = mb_substr($preview, 0, 137) . '...';
            }
            $title = 'Mintzer replied';
            $body = '[ticket:' . $ticket->id . '] ' . $preview;

            try {
                if ($ticket->user_id) {
                    $notification = new Notification();
                    $notification->user_id = $ticket->user_id;
                    $notification->title = $title;
                    $notification->content = $body;
                    $notification->is_readed = 0;
                    $notification->save();

                    $user = User::find($ticket->user_id);
                    $fcm = $user->fcm_token ?? null;
                    if (!empty($fcm)) {
                        $this->sendVerificationPushNotify(
                            $fcm,
                            $title,
                            $preview,
                            'ticket_reply',
                            $ticket->id
                        );
                    }
                }
            } catch (\Exception $notifyEx) {
                // Reply already saved — never fail the admin action on notify.
                $this->Log(__FUNCTION__, 'POST', $notifyEx->getMessage(), Auth::id(), request()->ip(), gethostname(), 0, LogType::Error);
            }

            return response()->json([
                'success' => true,
                'message' => 'Reply sent',
                'reply' => [
                    'id' => $reply->id,
                    'from_user' => false,
                    'author' => $reply->staff_name,
                    'message' => $reply->message,
                    'created_at' => optional($reply->created_at)->format('d-m-Y h:i A'),
                ],
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->validator->errors()->first(),
            ], 422);
        } catch (\Exception $th) {
            $this->Log(__FUNCTION__, "POST", $th->getMessage(), Auth::user()->id ?? null, request()->ip(), gethostname(), 0, LogType::Error);
            return response()->json(['success' => false, 'message' => 'Something went wrong'], 500);
        }
    }
}

