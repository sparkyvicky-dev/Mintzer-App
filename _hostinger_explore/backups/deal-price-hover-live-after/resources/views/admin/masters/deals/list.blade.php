@extends('layouts.main_master')
@section('content')
@section('title')
    Mintzer | Deal List
@endsection

<style>
    .deal-price-tip { cursor: default; }
    .deal-price-tip-box {
        position: fixed;
        z-index: 1080;
        display: none;
        background: #1c2434;
        color: #fff;
        border-radius: 8px;
        padding: 7px 10px;
        font-size: 12px;
        font-weight: 650;
        box-shadow: 0 8px 20px rgba(20, 24, 40, .18);
        max-width: 460px;
        line-height: 1.5;
        pointer-events: none;
    }
    .deal-price-tip-box.show { display: block; }
    .deal-price-tip-box b { color: #d6c2ff; font-weight: 750; }
</style>
<!-- Content -->
<div class="container-xxl flex-grow-1 container-p-y">
    <div class="row mb-4 align-items-center">
        <div class="col-sm-6">
            <div>
                <h4 class="fw-bold py-3 mb-0">
                    <i class="ti ti-shopping-cart me-2" style="font-size: 1.5rem;"></i>Deals Management
                </h4>
            </div>
        </div>
        <div class="col-sm-6 text-end">
            @if (auth()->user()->role_id == App\Enums\RoleTypes::Admin)
                <button type="button" id="createDealBtn" class="btn btn-primary btn-sm waves-effect waves-light shadow-sm"
                    style="border-radius: 20px; padding: 8px 24px;">
                    <span class="ti ti-plus me-1"></span>New Deal
                </button>
            @endif
        </div>
    </div>


    <div class="row mb-4">
        <div class="col-4">
            <div class="nav-align-top nav-tabs-shadow">
                <ul class="nav nav-tabs mb-3">
                    <li class="nav-item">
                        <a class="nav-link active" data-type="0" id="tabDeals" role="tab">
                            <span class="d-flex align-items-center gap-2">
                                <i class="ti ti-tag"></i> Deals
                            </span>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" data-type="1" id="tabPineDeals" role="tab">
                            <span class="d-flex align-items-center gap-2">
                                <i class="ti ti-device-floppy"></i> Pine Lab Deals
                            </span>
                        </a>
                    </li>
                </ul>
            </div>
        </div>
    </div>
    <div class="card">

        <div class="card-datatable table-responsive pt-0">
            <!-- Top scrollbar wrapper -->
            <div class="table-scroll-top">
                <div class="table-scroll-spacer"></div>
            </div>

            <!-- Main table wrapper -->
            <div class="table-scroll-bottom">
                <table class="dt-scrollableTable table" id="tblDealList">
                    <thead>
                        <tr>
                            <th>Sl.No</th>
                            <th>Image</th>
                            <th>Deal Name</th>
                            <th>Deal Price</th>
                            <th>Order Qty </th>
                            <th>Status</th>
                            <th>Last live</th>
                            <th>Action</th>
                        </tr>
                    </thead>

                    <tbody>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
<div id="dealPriceTip" class="deal-price-tip-box"></div>
<!-- / Content -->
@endsection
@section('footer')
<script src="{{ asset('assets/js/dashboards-crm.js') }}"></script>
<script src="{{ asset('assets/js/admin/admindashboard/dashboard.js') }}"></script>
<script src="{{ asset('assets/js/admin/masters/deal.js?v=3.2-price-hover') }}"></script>
@endsection
