@extends('layouts.main_master')
@section('content')
@section('title')
    Mintzer | Orders
@endsection
<link rel="stylesheet" href="https://cdn.datatables.net/buttons/2.3.3/css/buttons.dataTables.min.css">

<style>
    .form-select {
        width: 170px;
    }
    .left {
        float: left;
        display: flex;
        gap: 10px;
    }
    .right {
        float: right;
    }
    .dt-button.btn-success {
        background-color: #26c47a !important;
        border: 1px solid #20ad6c !important;
        color: #fff !important;
        padding: 6px 12px !important;
        border-radius: 4px !important;
    }
    .btn-columns-compact {
        border-radius: 4px !important;
        padding: 6px 10px !important;
        font-weight: 600;
    }
    .btn-preset-compact {
        border-radius: 4px !important;
        padding: 6px 10px !important;
        font-weight: 600;
    }
    .payout-header-meta {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        gap: 10px;
    }
    .payout-amount-pill {
        background: #edf2ff;
        border: 1px solid #cad7ff;
        color: #2b3c89;
        border-radius: 999px;
        padding: 5px 12px;
        font-weight: 700;
        font-size: 13px;
    }
    .payout-order-model {
        font-size: 12px;
        color: #5b607d;
        max-width: 100%;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }
    .payout-note-chips {
        display: flex;
        flex-wrap: wrap;
        gap: 6px;
        margin-top: 8px;
    }
    .payout-note-chip {
        border: 1px solid #d9dcef;
        background: #f7f8ff;
        color: #404767;
        border-radius: 999px;
        font-size: 12px;
        padding: 4px 10px;
        cursor: pointer;
    }
    .payout-note-chip:hover {
        background: #ecefff;
        border-color: #bfc9ff;
        color: #2c3c92;
    }
    .bank-readonly-field {
        background: #f2f3f8 !important;
        border-color: #d9dce8 !important;
        color: #4a4f69 !important;
        font-weight: 500;
    }
    .payout-id-line {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        gap: 8px;
    }
    .payout-id-chip {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        background: #f7f8fc;
        border: 1px solid #e4e7f2;
        border-radius: 8px;
        padding: 4px 8px;
        font-size: 13px;
        font-weight: 700;
    }
    .payout-copy-row {
        display: flex;
        align-items: center;
        gap: 6px;
    }
    .payout-copy-row .form-control {
        flex: 1;
    }
    .payout-copy-btn {
        border: 1px solid #d9dcef;
        background: #fff;
        color: #3d2e9e;
        border-radius: 8px;
        font-size: 12px;
        font-weight: 700;
        padding: 6px 8px;
        white-space: nowrap;
    }
    .transaction-helper {
        font-size: 11px;
        color: #7b8098;
        margin-top: 5px;
    }
    div.dt-button-collection {
        min-width: 280px !important;
        max-width: 360px;
        padding: 8px !important;
        border-radius: 10px;
        box-shadow: 0 8px 22px rgba(38, 38, 58, 0.16);
        border: 1px solid #ececf5;
    }
    div.dt-button-collection .dt-button {
        margin: 3px !important;
        border-radius: 7px !important;
        border: 1px solid #e6e7f3 !important;
        background: #f8f9ff !important;
        color: #3a3d57 !important;
        font-size: 12px !important;
        padding: 6px 8px !important;
        text-align: left !important;
        line-height: 1.2;
    }
    div.dt-button-collection .dt-button.active {
        background: #e9edff !important;
        border-color: #bfc8ff !important;
        color: #28307e !important;
        font-weight: 600;
    }
    div.dt-button-collection .buttons-colvisRestore {
        background: #fff !important;
        border-style: dashed !important;
        color: #5a5e7a !important;
        text-align: center !important;
    }
    button.dt-button:focus:not(.disabled), div.dt-button:focus:not(.disabled), a.dt-button:focus:not(.disabled), input.dt-button:focus:not(.disabled){
        background-color: #26c47a !important;
        border: 1px solid #20ad6c !important;
        color: #fff !important;
    }
    .orders-compact-heading {
        margin-bottom: 0.35rem !important;
        padding-top: 0.15rem !important;
        padding-bottom: 0.2rem !important;
    }
    .orders-filter-card {
        margin-bottom: 0.25rem !important;
    }
    .orders-filter-body {
        padding: 3px 10px 2px !important;
    }
    .orders-filter-row {
        padding: 0 !important;
        align-items: end;
        row-gap: 6px;
    }
    .orders-table-card .card-datatable {
        padding-top: 0.2rem !important;
        overflow-x: hidden;
    }
    .orders-table-wrap {
        max-height: calc(100vh - 225px);
        overflow: auto;
    }
    #tblOrderList {
        min-width: 1100px;
        width: 100%;
    }
    #tblOrderList thead th {
        background: #f2f4fc !important;
        color: #3a4460;
        font-size: 11px;
        font-weight: 700;
        text-align: center !important;
        white-space: nowrap;
        vertical-align: middle;
    }
    #tblOrderList th,
    #tblOrderList td {
        vertical-align: middle;
        padding: 8px 10px;
    }
    #tblOrderList td {
        text-align: center;
    }
    #tblOrderList td.ord-user,
    #tblOrderList td.deal-name-cell {
        text-align: left;
    }
    #tblOrderList .deal-name-cell {
        max-width: 200px;
    }
    #tblOrderList .ord-deal {
        display: -webkit-box;
        -webkit-box-orient: vertical;
        -webkit-line-clamp: 2;
        line-clamp: 2;
        overflow: hidden;
        white-space: normal;
        word-break: break-word;
        line-height: 1.25;
        font-size: 12.5px;
        text-align: left;
    }
    #tblOrderList .ord-user-cell { text-align: left; max-width: 140px; }
    #tblOrderList .ord-user-name {
        display: block;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        font-size: 13px;
        font-weight: 700;
        color: #5b4bdb;
        text-decoration: none;
    }
    #tblOrderList a.ord-user-name:hover {
        text-decoration: underline;
    }
    #tblOrderList .ord-user-ord {
        font-size: 11px;
        color: #6b7289;
        font-family: Consolas, ui-monospace, monospace;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }
    #tblOrderList .ord-money {
        display: inline-flex;
        flex-direction: column;
        align-items: flex-start;
        gap: 1px;
        font-variant-numeric: tabular-nums;
        line-height: 1.3;
        white-space: nowrap;
        text-align: left;
    }
    #tblOrderList .ord-money .row-m { display: flex; align-items: baseline; gap: 6px; }
    #tblOrderList .ord-money .lbl {
        font-size: 11px; font-weight: 600; color: #6b7289; width: 54px; flex-shrink: 0;
    }
    #tblOrderList .ord-money .ordered { color: #5b647a; font-weight: 600; }
    #tblOrderList .ord-money .topay { color: #0f7a3a; font-weight: 800; font-size: 13px; }

    #tblOrderList .ord-store-cell { text-align: center; line-height: 1.3; max-width: 180px; margin: 0 auto; }
    #tblOrderList .ord-store {
        display: inline-block;
        max-width: 150px;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        font-family: Consolas, ui-monospace, monospace;
        font-size: 14px;
        font-weight: 700;
        vertical-align: middle;
    }
    #tblOrderList .ord-store-date {
        margin-top: 3px;
        font-size: 12px;
        color: #6b7289;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }
    #tblOrderList .ord-store-edit { display: inline-flex; align-items: center; gap: 4px; justify-content: center; }

    #tblOrderList .ord-ship {
        display: inline-flex;
        flex-direction: column;
        align-items: center;
        gap: 2px;
        max-width: 170px;
        line-height: 1.2;
    }
    #tblOrderList .ord-ship .l1,
    #tblOrderList .ord-ship .l2 {
        max-width: 170px;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }
    #tblOrderList .ord-ship .track {
        font-family: Consolas, ui-monospace, monospace;
        font-weight: 700;
        font-size: 13.5px;
        color: #1a1f2e;
    }
    #tblOrderList .ord-ship .l2 { color: #5b647a; font-size: 11.5px; }
    #tblOrderList .ord-ship .courier { font-weight: 700; }
    #tblOrderList .ord-ship .sep { color: #c0c5d2; margin: 0 3px; }
    #tblOrderList .c-ekart { color: #c2410c; }
    #tblOrderList .c-delh { color: #0369a1; }
    #tblOrderList .c-blue { color: #1d4ed8; }
    #tblOrderList .c-xpress { color: #7e22ce; }
    #tblOrderList .c-shadow { color: #047857; }
    #tblOrderList .c-other { color: #4b5563; }

    #tblOrderList .bell-wrap {
        display: inline-flex;
        flex-direction: column;
        align-items: center;
        gap: 2px;
    }
    #tblOrderList .bell-wrap .hint { font-size: 10px; color: #6b7289; font-weight: 600; }
    #tblOrderList .ord-bell {
        width: 32px; height: 32px; border-radius: 10px;
        border: 1px solid #ddd6fe; background: #f5f3ff;
        cursor: pointer; font-size: 14px;
        display: inline-flex; align-items: center; justify-content: center;
        padding: 0;
    }
    #tblOrderList .ord-bell:hover { background: #ede9fe; }
    #tblOrderList .ord-bell-sm {
        width: 24px; height: 24px; border-radius: 7px; font-size: 12px;
        vertical-align: middle;
    }
    #tblOrderList .bell-inline {
        display: inline-flex;
        align-items: center;
        gap: 3px;
        vertical-align: middle;
    }
    #tblOrderList .bell-inline .hint {
        font-size: 10px; color: #6b7289; font-weight: 600;
    }
    #tblOrderList .ord-inv { white-space: nowrap; }
    #tblOrderList .ord-inv a { color: #1a73e8; font-weight: 600; text-decoration: none; }
    #tblOrderList .ord-inv a:hover { text-decoration: underline; }

    #tblOrderList td.ord-dd-col,
    #tblOrderList td.ord-pay-col {
        padding-left: 14px;
        padding-right: 14px;
        border-left: 1px solid #eef0f6;
    }
    #tblOrderList select.ord-dd {
        width: 118px;
        max-width: 100%;
        height: 28px;
        font-size: 12px;
        text-align: center;
        text-align-last: center;
        padding: 2px 8px;
        white-space: nowrap;
        margin: 0 auto;
        display: block;
    }
    #tblOrderList .ord-pay-col .btn,
    #tblOrderList .ord-pay-col .badge {
        white-space: nowrap;
    }

    #tblOrderList .order-id-cell {
        display: inline-flex;
        align-items: center;
        gap: 5px;
        white-space: nowrap;
    }
    #tblOrderList .inline-ellipsis {
        display: inline-block;
        max-width: 220px;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        vertical-align: middle;
    }
    #tblOrderList .sticky-col-1,
    #tblOrderList .sticky-col-2,
    #tblOrderList .sticky-col-3 {
        position: sticky;
        background: #f7f8ff;
        box-shadow: 1px 0 0 #e7e8f2;
        z-index: 2;
    }
    #tblOrderList th.sticky-col-1,
    #tblOrderList th.sticky-col-2,
    #tblOrderList th.sticky-col-3 {
        background: #eef0ff;
        z-index: 3;
    }
    #tblOrderList .sticky-col-1 { left: 48px; min-width: 120px; }
    #tblOrderList .sticky-col-2 { left: 168px; min-width: 160px; }
    #tblOrderList .sticky-col-3 { left: 328px; min-width: 120px; }
    #tblOrderList tr.row-payout-pending td {
        background: #eef5ff;
    }
    #tblOrderList tr.row-ready-to-pay td {
        background: #eaf8f1;
    }
    #tblOrderList tr.row-out-for-delivery td {
        background: #fff8e7;
    }
    #tblOrderList tr.row-payout-completed td {
        opacity: 0.72;
    }

    /* Soft full-row hover — long rows easier to track */
    #tblOrderList tbody tr {
        transition: background-color 0.18s ease, box-shadow 0.18s ease, filter 0.18s ease;
    }
    #tblOrderList tbody tr td {
        transition: background-color 0.18s ease, box-shadow 0.18s ease;
        box-shadow: inset 0 0 0 0 transparent;
    }
    #tblOrderList tbody tr:hover td {
        background: #e8f1ff !important;
        box-shadow: inset 3px 0 0 #1a73e8;
    }
    #tblOrderList tbody tr:hover td.sticky-col-1,
    #tblOrderList tbody tr:hover td.sticky-col-2,
    #tblOrderList tbody tr:hover td.sticky-col-3 {
        background: #e8f1ff !important;
    }
    #tblOrderList tbody tr:hover {
        filter: brightness(1.01);
    }
    /* Keep completed rows readable but still show hover */
    #tblOrderList tbody tr.row-payout-completed:hover {
        opacity: 0.92;
    }
    #tblOrderList tbody tr.row-payout-pending:hover td {
        background: #dceaff !important;
    }
    #tblOrderList tbody tr.row-ready-to-pay:hover td {
        background: #d8f3e6 !important;
    }
    #tblOrderList tbody tr.row-out-for-delivery:hover td {
        background: #fff0d4 !important;
    }
    .focus-summary {
        display: flex;
        align-items: center;
        gap: 8px;
        flex-wrap: wrap;
    }
    .focus-summary .badge {
        font-size: 12px;
        padding: 7px 10px;
        border-radius: 6px;
    }
    .focus-summary .badge .count {
        font-weight: 700;
        margin-left: 4px;
    }
    #tblOrderList_wrapper .top {
        position: sticky;
        top: 0;
        left: 0;
        right: 0;
        z-index: 16;
        background: #fff;
        padding: 4px 0;
        border-bottom: 1px solid #ececf5;
        width: 100%;
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 8px;
        flex-wrap: nowrap;
        overflow: visible;
        scrollbar-width: thin;
    }
    #tblOrderList_wrapper {
        width: 100%;
    }
    #tblOrderList_wrapper .top .left {
        display: flex;
        align-items: center;
        gap: 6px;
        flex-wrap: nowrap;
        flex: 1 1 auto;
        min-width: 0;
        overflow-x: auto;
        overflow-y: hidden;
        padding-right: 8px;
    }
    #tblOrderList_wrapper .top .right {
        position: sticky;
        right: 0;
        z-index: 2;
        background: #fff;
        padding-left: 8px;
        margin-left: 0;
        min-width: 180px;
        flex: 0 0 auto;
    }
    #tblOrderList_wrapper .top .right input[type="search"] {
        min-width: 170px;
    }
    #tblOrderList_wrapper .top .dt-button {
        margin-top: 0 !important;
        margin-bottom: 0 !important;
    }
    #tblOrderList_wrapper .bottom {
        padding-top: 4px;
    }
    .orders-table-wrap.sticky-disabled #tblOrderList .sticky-col-1,
    .orders-table-wrap.sticky-disabled #tblOrderList .sticky-col-2,
    .orders-table-wrap.sticky-disabled #tblOrderList .sticky-col-3 {
        position: static !important;
        left: auto !important;
        box-shadow: none !important;
        background: transparent !important;
    }
    .orders-table-wrap.sticky-disabled #tblOrderList th.sticky-col-1,
    .orders-table-wrap.sticky-disabled #tblOrderList th.sticky-col-2,
    .orders-table-wrap.sticky-disabled #tblOrderList th.sticky-col-3 {
        background: #fff !important;
    }
    #tblOrderList thead th {
        background: #f7f8fc;
    }
    #tblOrderList thead th:nth-child(2) { background: #eef0ff; color: #2c3a8e; }
    #tblOrderList thead th:nth-child(3) { background: #f0efff; color: #4b3a8e; }
    #tblOrderList thead th:nth-child(4) { background: #eaf7ff; color: #275f8b; }
    #tblOrderList thead th:nth-child(5) { background: #edf9f0; color: #2a6a3e; }
    #tblOrderList thead th:nth-child(15) { background: #fff5e8; color: #8d5b20; }
    #tblOrderList thead th:nth-child(16) { background: #ffeef0; color: #8f3040; }
    #tblOrderList thead th:nth-child(17) { background: #fff1f2; color: #97353f; }
</style>

<!-- Modal -->
<div class="modal fade" id="modalCenter" tabindex="-1" data-bs-backdrop="static">
    <div class="modal-dialog modal-dialog-centered modal-m">
        <div class="modal-content">
            <div class="modal-header">
                <div class="payout-header-meta">
                    <span class="payout-amount-pill">Payout: <span id="payout_amount"></span></span>
                    <span class="payout-id-line">
                        <span class="payout-id-chip">User <span id="payout_user_name">-</span>
                            <button type="button" class="payout-copy-btn" data-copy-target="payout_user_name">Copy</button>
                        </span>
                        <span class="payout-id-chip">Order <span id="payout_order_number">-</span>
                            <button type="button" class="payout-copy-btn" data-copy-target="payout_order_number">Copy</button>
                        </span>
                    </span>
                    <span class="payout-order-model" id="payout_order_model">Deal: -</span>
                </div>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div class="row">
                    <!-- Bank Details -->
                    <div class="col-md-6">
                        <h6>Bank Details</h6>
                        <div class="mb-3">
                            <label for="payee_name" class="form-label">Payee name</label>
                            <div class="payout-copy-row">
                                <input class="form-control bank-readonly-field" type="text" value="" id="payee_name" disabled />
                                <button type="button" class="payout-copy-btn" data-copy-target="payee_name">Copy</button>
                            </div>
                        </div>
                        <div class="mb-3">
                            <label for="account_number" class="form-label">Account number</label>
                            <div class="payout-copy-row">
                                <input class="form-control bank-readonly-field" type="text" value="" id="account_number" disabled />
                                <button type="button" class="payout-copy-btn" data-copy-target="account_number">Copy</button>
                            </div>
                        </div>
                        <div class="mb-3">
                            <label for="ifsc" class="form-label">IFSC</label>
                            <input class="form-control bank-readonly-field" type="text" value="" id="ifsc" disabled />
                        </div>
                        <div class="mb-3">
                            <label for="bank_name" class="form-label">Bank name</label>
                            <input class="form-control bank-readonly-field" type="text" value="" id="bank_name" disabled />
                        </div>
                        <div class="mb-3">
                            <label for="upi" class="form-label">UPI</label>
                            <input class="form-control bank-readonly-field" type="text" value="" id="upi"
                                disabled />
                        </div>
                    </div>
                    <!-- Payout Details -->
                    <div class="col-md-6">
                        <form id="approvePayoutForm" enctype="multipart/form-data">
                            @csrf
                            <h6>Payout Details</h6>
                            <input type="hidden" name="hdOrderId" id="hdOrderId" value="">
                            {{-- <div class="mb-3">
                                <label for="payout_amount" class="form-label">Payout Amount: <span id="payout_amount"></span></label>
                            </div> --}}
                            <div class="mb-3">
                                <label for="transaction_id" class="form-label">Transaction ID:</label>
                                <input class="form-control" type="text" value=""
                                    id="transaction_id" name="transaction_id" placeholder="Enter UTR / Reference ID" required />
                                <div class="transaction-helper">Example: UPI12345678 or NEFTREF9876</div>
                            </div>
                            <div class="mb-3" id="transaction_div">
                                <label for="transaction_file" class="form-label">Transaction File:</label>
                                <input class="form-control" type="file" value=""
                                    id="transaction_file" name="transaction_file" />
                            </div>
                            <div class="mb-3">
                                <label for="payout_notes" class="form-label">Payout Note:</label>
                                <textarea class="form-control" rows="4" id="payout_notes" name="payout_notes"></textarea>
                                <div class="payout-note-chips">
                                    <button type="button" class="payout-note-chip" data-note="Paid via UPI">Paid via UPI</button>
                                    <button type="button" class="payout-note-chip" data-note="Paid via NEFT">Paid via NEFT</button>
                                    <button type="button" class="payout-note-chip" data-note="Paid via IMPS">Paid via IMPS</button>
                                    <button type="button" class="payout-note-chip" data-note="Processed successfully">Processed successfully</button>
                                    <button type="button" class="payout-note-chip" id="clearPayoutNote">Clear</button>
                                </div>
                            </div>
                            <div class="text-center" id="bank_details_button">
                                <button type="button"
                                        id="approvePayoutBtn"
                                        class="btn btn-label-primary me-sm-3 me-1">
                                    Submit
                                </button>
                                <button type="reset" class="btn btn-label-danger btn-reset" data-bs-dismiss="modal"
                                    aria-label="Close">Cancel</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<!-- / Modal -->

<div class="container-xxl flex-grow-1 pt-1 pb-0">
    <h4 class="fw-bold orders-compact-heading">{{ $formattedStatus ?? "" }} Orders<span class="text-muted fw-light"> /List</span></h4>
    <input type="hidden" id="hdStatus" value="{{ $formattedStatus }}">
    <input type="hidden" id="hdUserId" value="{{ !empty($holder) ? $holder->id : '' }}">
    @if(!empty($holder))
        <div class="card mb-2">
            <div class="card-body py-2">
                <div class="d-flex justify-content-between align-items-center mb-2">
                    <strong>{{ $holder->display_name ?: 'User' }}</strong>
                    <a href="{{ url('orders') }}">All orders</a>
                </div>
                <div class="row small">
                    <div class="col-md-3 mb-1"><b>Phone:</b> {{ $holder->mobile ?: '-' }}</div>
                    <div class="col-md-3 mb-1"><b>Email:</b> {{ $holder->email ?: '-' }}</div>
                    <div class="col-md-3 mb-1"><b>PAN:</b> {{ $holder->pan ?: '-' }}</div>
                    <div class="col-md-3 mb-1"><b>PAN name:</b> {{ $holder->pan_name ?: '-' }}</div>
                    <div class="col-md-3 mb-1"><b>Wallet:</b> ₹{{ number_format((float) ($holder->wallet ?? 0), 2) }}</div>
                    <div class="col-md-3 mb-1"><b>Status:</b> {{ (int) $holder->is_active === 1 ? 'Active' : 'Inactive' }}</div>
                    <div class="col-md-3 mb-1"><b>Bank:</b> {{ $holder->bank_name ?: '-' }}</div>
                    <div class="col-md-3 mb-1"><b>Payee:</b> {{ $holder->bank_full_name ?: '-' }}</div>
                    <div class="col-md-3 mb-1"><b>Account:</b> {{ $holder->bank_account_number ?: '-' }}</div>
                    <div class="col-md-3 mb-1"><b>IFSC:</b> {{ $holder->bank_ifsc ?: '-' }}</div>
                    <div class="col-md-3 mb-1"><b>UPI:</b> {{ $holder->upi_address ?: '-' }}</div>
                    <div class="col-md-3 mb-1"><b>City:</b> {{ $holder->city ?: '-' }}</div>
                </div>
            </div>
        </div>
    @endif

    <div class="card orders-filter-card">
        <div class="row">
            <div class="card-body orders-filter-body">

                <form class="browser-default-validation">
                    <div class="row orders-filter-row">
                        @if(!$formattedStatus) 
                            <div class="col-md-2">
                                <label class="form-label" for="basic-default-name">Status</label>
                                <select id="statusFilter" class="form-select w-auto d-inline-block">
                                    <option value="">All</option>
                                    <option value="Placed">Placed</option>
                                    <option value="Shipped">Shipped</option>
                                    <option value="Out For Delivery">Out For Delivery</option>
                                    <option value="Delivered">Delivered</option>
                                </select>
                            </div>
                        @endif
                        
                        @if($formattedStatus == "Out For Delivery")
                            <div class="col-md-2">
                                <label class="form-label" for="basic-default-name">Invoice Status</label>
                                <select name="ddlInvoiceStatus" id="ddlInvoiceStatus" class="form-select">
                                    <option value="All">All</option>
                                    <option value="not-upload">Not Uploaded</option>
                                    <option value="re-upload">Re-Upload Request</option>
                                </select>
                            </div>
                        @endif
                        <div class="col-md-4 mt-0">
                            <div class="d-flex align-items-center gap-2">
                                <div id="hdDivDate">
                                    <button type="button" class="btn btn-flat btn-primary" id="btnDate"
                                        style="height: 36px;">
                                        <i class="fa fa-calendar"></i>
                                        <span id="spnDate" style="padding-left: 5px;">All Orders</span>
                                        <i class="fa fa-caret-down" style="padding-left: 5px;"></i>
                                    </button>
                                </div>
                                <div>
                                    <button type="button" class="btn btn-primary" id="clearFilters">
                                        <i class="fas fa-sync-alt"></i>
                                    </button>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-5 mt-0">
                            <label class="form-label d-block">Focus Orders</label>
                            <div class="focus-summary">
                                <span class="badge bg-primary">Payout Pending:<span class="count" id="payoutPendingCount">0</span></span>
                                <span class="badge bg-warning text-dark">Out For Delivery:<span class="count" id="outForDeliveryCount">0</span></span>
                                <span class="badge bg-info text-dark">Ordered value:<span class="count" id="orderedValue">₹0</span></span>
                                <span class="badge bg-success">Payout pending:<span class="count" id="payoutPendingValue">₹0</span></span>
                            </div>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
<!-- Modal for Cancellation Reason -->
<div id="cancelReasonsModal" class="modal fade" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered modal-m">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Cancel Reason</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>

            <div class="modal-body">
                <form id="cancelOrderForm">
                    @csrf
                    <input type="hidden" name="hdOrderId" id="hdOrderCancelId">

                    @foreach ($reasonList as $index => $item)
                        <div class="form-check">
                            <input class="form-check-input cancel-reason"
                                   type="radio"
                                   name="cancelReason"
                                   id="cancelReason{{ $index }}"
                                   value="{{ $item->content }}">
                            <label class="form-check-label" for="cancelReason{{ $index }}">
                                {{ $item->content }}
                            </label>
                        </div>
                    @endforeach

                    <!-- Other Reason -->
                    <div id="otherReasonDiv" class="mt-2 d-none">
                        <label>Please specify:</label>
                        <input type="text" class="form-control" name="otherReason" id="otherReason">
                    </div>

                    <div class="text-end mt-3">
                        <button type="button"
                                id="cancelOrderBtn"
                                class="btn btn-danger">
                            Submit
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
<div class="container-xxl flex-grow-1 pt-0 pb-0">
    <div class="card orders-table-card">
        <div class="card-datatable pt-0 p-3">
            <!-- Main table wrapper -->
            <div class="table-scroll-bottom orders-table-wrap">
                <table class="dt-scrollableTable table" id="tblOrderList">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Order_No</th>
                            <th>User</th>
                            <th>Deal</th>
                            <th>Money</th>
                            <th>Card_Holder Receive_Amount</th>
                            <th>Order_Date</th>
                            <th>Store ID</th>
                            <th>Ship</th>
                            <th>Delivery_Partner_Name</th>
                            <th>Delivery_OTP</th>
                            <th>Delivery_Mobile</th>
                            <th>Status</th>
                            <th>Bill</th>
                            <th>Verify</th>
                            <th>Payout</th>
                            <th>Cancel</th>
                        </tr>
                    </thead>
                    <tbody>
                        <!-- Your table data here -->
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
<!-- / Content -->

@endsection
@section('footer')

<script src="{{ asset('assets/js/dashboards-crm.js') }}"></script>
<script src="{{ asset('assets/js/admin/admindashboard/dashboard.js') }}"></script>
<script src="{{ asset('assets/js/admin/masters/orders.js?v=7.7-payout-copy') }}"></script>
<script type="text/javascript" charset="utf8" src="https://cdn.datatables.net/buttons/2.3.3/js/dataTables.buttons.min.js"></script>
<script type="text/javascript" charset="utf8" src="https://cdnjs.cloudflare.com/ajax/libs/jszip/3.7.1/jszip.min.js"></script>
<script type="text/javascript" charset="utf8" src="https://cdn.datatables.net/buttons/2.3.3/js/buttons.html5.min.js">
</script>
<script type="text/javascript" charset="utf8" src="https://cdn.datatables.net/buttons/2.3.3/js/buttons.colVis.min.js"></script>
<script src="{{ asset('assets/vendor/libs/moment/moment.js') }}" ></script>
@endsection
