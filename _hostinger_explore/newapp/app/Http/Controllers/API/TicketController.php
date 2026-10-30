<?php

namespace App\Http\Controllers\API;

use App\Enums\LogType;
use App\Http\Controllers\Controller;
use App\Models\Ticket;
use App\Models\TicketReply;
use App\Models\Subject;
use App\Traits\Common;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;

class TicketController extends Controller
{
    use Common;

    function addnewtickets(Request $request)
    {
        $rules = [
            'subject_id' => 'required|exists:subjects,id',
            'message' => 'required|string',
        ];
        $messages = [
            'subject_id.required' => 'Please select a valid subject.',
            'subject_id.exists'   => 'The selected subject does not exist.',
            'message.required' => 'Message is required.',
        ];

        $validator = Validator::make($request->all(), $rules, $messages);

        if ($validator->fails()) {
            $response = [
                'status' => false,
                'message' => $validator->errors()->first(),
            ];
            return response()->json($response, 400);
        }
        try {
            $subjectName = Subject::find($request->subject_id)->name;
            $create = [
                'user_id' => Auth::user()->id,
                'subject_id'    => $request->subject_id,
                'subject'       => $subjectName,
                'message' => $request->message,
                'ticket_status' => 1,
            ];
            // Additive: optional order_ref when column exists (Flutter also embeds in message).
            if (Schema::hasColumn('tickets', 'order_ref') && $request->filled('order_ref')) {
                $create['order_ref'] = substr(trim((string) $request->order_ref), 0, 120);
            }
            Ticket::create($create);
            $response = [
                'message' => "Query sent Successfully",
            ];
            return response()->json($response, 200);
        } catch (Exception $e) {
            $response = array(
                'status' => false,
                'message' => $this->errorMessage,
            );
            return response($response, 400);
        }
    }

    function getTicket(Request $request)
    {
        $with = ['ticketSubject'];
        if ($this->repliesReady()) {
            $with[] = 'replies';
        }

        $ticketsQuery = Ticket::with($with)->where('user_id', Auth::user()->id);

        if ($request->ticket_id) {
            $ticketsQuery->where('id', $request->ticket_id);
        }
        $tickets = $ticketsQuery->latest()->paginate($request->input('pageSize', $this->recordsperpage));

        $data = [];

        foreach ($tickets as $ticket) {
            switch ($ticket->ticket_status) {
                case 1:
                    $status = 'Pending';
                    break;
                case 2:
                    $status = 'On Process';
                    break;
                case 3:
                    $status = 'Completed';
                    break;
                case 4:
                    $status = 'Escalated';
                    break;
                default:
                    $status = 'Pending';
            }
            $subjectName = $ticket->ticketSubject ? $ticket->ticketSubject->name : $ticket->subject;

            $row = [
                'id'            => $ticket->id,
                'subject'       => $subjectName,
                'subject_id'    => $ticket->subject_id,
                'message'       => $ticket->message,
                'ticket_status' => $status,
                'created_at'    => $ticket->created_at,
                // Additive V3 — old clients ignore
                'updated_at'    => $ticket->updated_at,
                'replies'       => $this->formatReplies($ticket),
                'supports_replies' => $this->repliesReady(),
            ];
            if (Schema::hasColumn('tickets', 'order_ref')) {
                $row['order_ref'] = $ticket->order_ref ?? '';
            }

            $data[] = $row;
        }
        $currentPageUrl = $tickets->url($tickets->currentPage());
        $prevPageUrl = $tickets->previousPageUrl();
        $nextPageUrl = $tickets->nextPageUrl();
        return response()->json([
            'data' => $data,
            'per_page_count' => $tickets->perPage(),
            'total' => $tickets->total(),
            'currentPage' => $tickets->currentPage(),
            'lastPage' => $tickets->lastPage(),
            'currentPageUrl' => $currentPageUrl,
            'prevPageUrl' => $prevPageUrl,
            'nextPageUrl' => $nextPageUrl,
        ], 200);
    }

    /**
     * Additive: holder reply on own ticket.
     * POST /api/addticketreply  { ticket_id, message }
     */
    function addTicketReply(Request $request)
    {
        if (!$this->repliesReady()) {
            return response()->json([
                'status' => false,
                'message' => 'Replies are not available yet.',
            ], 503);
        }

        $validator = Validator::make($request->all(), [
            'ticket_id' => 'required|integer|exists:tickets,id',
            'message' => 'required|string|max:2000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => $validator->errors()->first(),
            ], 400);
        }

        try {
            $ticket = Ticket::where('id', $request->ticket_id)
                ->where('user_id', Auth::user()->id)
                ->first();

            if (!$ticket) {
                return response()->json([
                    'status' => false,
                    'message' => 'Ticket not found.',
                ], 404);
            }

            if ((int) $ticket->ticket_status === 3) {
                return response()->json([
                    'status' => false,
                    'message' => 'This ticket is resolved. Open a new ticket if you still need help.',
                ], 400);
            }

            $reply = TicketReply::create([
                'ticket_id' => $ticket->id,
                'staff_user_id' => null,
                'staff_name' => null,
                'user_id' => Auth::user()->id,
                'is_from_user' => true,
                'message' => trim($request->message),
            ]);

            // Keep open / in process when user replies.
            if ((int) $ticket->ticket_status === 1) {
                $ticket->ticket_status = 2;
            }
            $ticket->touch();
            $ticket->save();

            return response()->json([
                'message' => 'Reply sent',
                'data' => [
                    'id' => $reply->id,
                    'message' => $reply->message,
                    'from_user' => true,
                    'created_at' => $reply->created_at,
                ],
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'status' => false,
                'message' => $this->errorMessage,
            ], 400);
        }
    }

    /**
     * Additive: holder closes own ticket (status → Completed).
     * POST /api/closeticket  { ticket_id }
     */
    function closeTicket(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'ticket_id' => 'required|integer|exists:tickets,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => $validator->errors()->first(),
            ], 400);
        }

        try {
            $ticket = Ticket::where('id', $request->ticket_id)
                ->where('user_id', Auth::user()->id)
                ->first();

            if (!$ticket) {
                return response()->json([
                    'status' => false,
                    'message' => 'Ticket not found.',
                ], 404);
            }

            if ((int) $ticket->ticket_status === 3) {
                return response()->json([
                    'message' => 'Ticket already resolved',
                    'data' => ['ticket_status' => 'Completed'],
                ], 200);
            }

            $ticket->ticket_status = 3; // Completed — same as admin
            $ticket->updated_by = Auth::user()->id;
            $ticket->save();

            return response()->json([
                'message' => 'Ticket marked resolved',
                'data' => ['ticket_status' => 'Completed'],
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'status' => false,
                'message' => $this->errorMessage,
            ], 400);
        }
    }

    function getSubjects()
    {
        try {
            $subjects = Subject::where('is_active', true)
                ->select('id', 'name')
                ->get();

            return response()->json([
                'data'   => $subjects
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'status'  => false,
                'message' => 'Failed to fetch subjects.',
            ], 500);
        }
    }

    private function repliesReady(): bool
    {
        return class_exists(TicketReply::class)
            && Schema::hasTable('ticket_replies');
    }

    private function formatReplies(Ticket $ticket): array
    {
        if (!$this->repliesReady()) {
            return [];
        }

        $replies = $ticket->relationLoaded('replies')
            ? $ticket->replies
            : TicketReply::where('ticket_id', $ticket->id)->orderBy('created_at')->get();

        $out = [];
        foreach ($replies as $r) {
            $fromUser = (bool) ($r->is_from_user ?? false);
            $out[] = [
                'id' => $r->id,
                'message' => $r->message,
                'from_user' => $fromUser,
                'author' => $fromUser
                    ? 'You'
                    : ($r->staff_name ?: 'Mintzer'),
                'created_at' => $r->created_at,
            ];
        }
        return $out;
    }
}
