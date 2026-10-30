@extends('layouts.main_master')
@section('content')
@section('title')
    Mintzer | Banners
@endsection

<!-- Content -->
<div class="container-xxl flex-grow-1 container-p-y">
    <h4 class="fw-bold py-3 mb-4">Banners<span class="text-muted fw-light"> /Add/List/Update</span></h4>

    <div class="card mb-4">
        <div class="card-body">
            <form action="{{ route('banner-store') }}" method="POST" enctype="multipart/form-data">
                @csrf
                <input type="hidden" name="hdBannerId" id="hdBannerId">
                <div class="row">
                    <div class="col-6 mb-3">
                        <label for="txtBannerName" class="form-label">Banner Name<span
                                class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="txtBannerName" name="txtBannerName" placeholder=""
                            required />
                    </div>
                    <div class="col-6 mb-3" id="imageDiv">
                        <label for="bannerImage" class="form-label">Image<span class="text-danger">*</span></label>
                        <input class="form-control"  type="file" name="bannerImage" id="bannerImage" required />
                    </div>
                    <div class="col-3 mb-3" id="imageDisplayDiv" style="display: none;">
                        <img id="imageDisplay" style="max-width: 200px; max-height: 100px;">
                    </div>
                    <div class="col-6 mb-3">
                        <label class="form-label" for="txtbannermessage">Message <span
                                class="text-danger">*</span></label>
                        <textarea id="txtbannermessage" name="txtbannermessage" class="form-control" required></textarea>
                    </div>
                    <div class="col-6 mb-3">
                        <label class="form-label" for="txtbannerlink">Youtube link</label>
                        <input type="text" class="form-control" id="txtbannerlink" name="txtbannerlink"/>
                    </div>
                    <div class="col-12 ">
                        <div class="float-end demo-inline-spacing">
                            <button type="submit" id="btnsave" class="btn btn-success waves-effect waves-light">Submit</button>
                            <button type="button" onclick="cancel()" class="btn btn-danger waves-effect waves-light ">Cancel</button>
                        </div>
                    </div>
                </div>
            </form>

        </div>
    </div>


    <div class="card">
        <div class="card-datatable table-responsive pt-0">
            <table class="dt-scrollableTable table" id="tblbannersList">
                <thead>
                    <tr>
                        <th>Sl.No</th>
                        <th>Image</th>
                        <th>Banner Name</th>
                        <th>Status</th>
                        <th>Created </th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>

                </tbody>

            </table>
        </div>
    </div>
</div>
<!-- / Content -->
@endsection
@section('footer')
<script src="{{ asset('assets/js/dashboards-crm.js') }}"></script>
<script src="{{ asset('assets/js/admin/admindashboard/dashboard.js') }}"></script>
<script src="{{ asset('assets/js/admin/masters/banner.js') }}"></script>
@endsection
