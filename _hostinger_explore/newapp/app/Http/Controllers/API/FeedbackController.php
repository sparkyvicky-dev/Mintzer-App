<?php

namespace App\Http\Controllers\API;

use App\Enums\LogType;
use App\Http\Controllers\Controller;
use App\Models\Feedback;
use App\Traits\Common;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class FeedbackController extends Controller
{
    use Common;
    public function submitFeedback(Request $request)
    {
        $rules = [
            'feedback' => 'required|string'
        ];
        $messages = [
            'feedback.required' => 'feedback is required.'
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
            $feedback = Feedback::create([
                'user_id' => Auth::user()->id,
                'feedback_content' => $request->feedback
            ]);
            $response = [
                'message' => "Feedback submitted successfully"
            ];
            return response()->json($response, 200);
            $this->Log(__FUNCTION__, request()->method(), 'Feedback submitted successfully.', $feedback->user_id, request()->ip(), gethostname(), 1, LogType::Activity);
        } catch (\Exception $e) {
            // dd($e);
            $response = [
                'message' => "Feedback not submitted"
            ];
            return response()->json($response, 400);
        }
    }
}
