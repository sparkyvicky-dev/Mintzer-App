@extends('layouts.main_master')
@section('content')
@section('title')
    Mintzer | Tickets
@endsection

<!-- Content -->

<div class="container-xxl flex-grow-1 container-p-y">
    <h4 class="fw-bold py-3 mb-4">Tickets<span class="text-muted fw-light"> /List</span></h4>


    <div class="card">
        <div class="card-datatable table-responsive pt-0">
            <!-- Top scrollbar wrapper -->
            <div class="table-scroll-top">
                <div class="table-scroll-spacer"></div>
            </div>

            <!-- Main table wrapper -->
            <div class="table-scroll-bottom">
                <table class="datatables-basic table" id="tblTicketList">
                    <thead>
                        <tr>
                            <th>Sl.No</th>
                            <th>Customer</th>
                            <th>Mobile</th>
                            <th>Subject</th>
                            <th>Date</th>
                            <th>Message</th>
                            <th>Status</th>
                            <th>Reply</th>
                        </tr>
                    </thead>
                    <tbody>

                    </tbody>

                </table>
            </div>
        </div>
    </div>
</div>

{{-- Additive: staff reply modal --}}
<div class="modal fade" id="ticketReplyModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-scrollable">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Ticket #<span id="trTicketId"></span> · <span id="trSubject"></span></h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div class="mb-2 text-muted small">
                    <span id="trCustomer"></span> · <span id="trMobile"></span> · <span id="trCreated"></span>
                </div>
                <div id="trThread" class="border rounded p-3 mb-3" style="max-height: 360px; overflow-y: auto; background: #f8f9fa;"></div>
                <label class="form-label fw-semibold">Quick templates</label>
                <div id="trTemplates" class="d-flex flex-wrap gap-2 mb-3"></div>
                <label class="form-label fw-semibold">Your reply</label>
                <textarea id="trMessage" class="form-control" rows="4" maxlength="5000" placeholder="Write a reply to the customer…"></textarea>
                <div class="form-text">Tap a template to fill, then edit if needed. Customer sees it in the Mintzer app.</div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary" id="trSendBtn">Send reply</button>
            </div>
        </div>
    </div>
</div>
<!-- / Content -->

@endsection
@section('footer')
<script src="{{ asset('assets/js/dashboards-crm.js') }}"></script>
<script src="{{ asset('assets/js/admin/admindashboard/dashboard.js') }}"></script>
<script src="{{ asset('assets/js/admin/masters/ticket.js?v=1.2') }}"></script>
@endsection
