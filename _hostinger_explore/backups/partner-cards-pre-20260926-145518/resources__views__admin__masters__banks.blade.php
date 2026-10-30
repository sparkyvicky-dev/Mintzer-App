@extends('layouts.main_master')
@section('content')
@section('title')
    Mintzer | Banks
@endsection

<div class="container-xxl flex-grow-1 container-p-y">
    <h4 class="fw-bold py-3 mb-4">Banks <span class="text-muted fw-light">/ Add / List / Update</span></h4>

    <div class="card mb-4">
        <div class="card-body">
            <form action="{{ route('create.bank') }}" method="POST" enctype="multipart/form-data" name="bankForm">
                @csrf
                <input type="hidden" name="hdBankId" id="hdBankId" value="">
                <input type="hidden" name="current_image" id="current_image" value="">

                <div class="row">
                    <div class="col-6 mb-3">
                        <label for="bank_name" class="form-label">Bank Name <span class="text-danger">*</span></label>
                        <input type="text" class="form-control @error('bank_name') is-invalid @enderror"
                            id="bank_name" name="bank_name" autofocus />
                        @error('bank_name')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="col-6 mb-3">
                        <label for="bank_image" class="form-label">Bank Logo <span class="text-danger">*</span></label>
                        <input class="form-control @error('bank_image') is-invalid @enderror" type="file"
                            id="bank_image" name="bank_image" accept="image/*" />
                        @error('bank_image')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror

                        <!-- Image Preview -->
                        <div id="image-preview-container" class="mt-3">
                            <div class="row g-3" id="image-preview"></div>
                        </div>
                    </div>

                    <div class="col-12 mb-3">
                        <label for="apply_url" class="form-label">Apply URL <span class="text-muted">(Partner Apply button)</span></label>
                        <input type="url" class="form-control @error('apply_url') is-invalid @enderror"
                            id="apply_url" name="apply_url" placeholder="https://…" />
                        @error('apply_url')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="col-12">
                        <div class="float-end demo-inline-spacing">
                            <button type="submit" id="btnsave" class="btn btn-success">Submit</button>
                            <button type="button" onclick="cancelForm()" class="btn btn-danger">Cancel</button>
                        </div>
                    </div>
                </div>
            </form>
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
                <table class="dt-scrollableTable table" id="tblBanksList">
                    <thead>
                        <tr>
                            <th>Sl.No</th>
                            <th>Logo</th>
                            <th>Name</th>
                            <th>Created</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody></tbody>
                </table>
            </div>
        </div>
    </div>
</div>
@endsection

@section('footer')
<script src="{{ asset('assets/js/dashboards-crm.js') }}"></script>
<script src="{{ asset('assets/js/admin/admindashboard/dashboard.js') }}"></script>
<script src="{{ asset('assets/js/admin/masters/bank.js?v=1.0') }}"></script>

<!-- Image Preview + Smart Validation Script -->
<script>
    document.addEventListener('DOMContentLoaded', function() {
        const fileInput = document.getElementById('bank_image');
        const previewContainer = document.getElementById('image-preview');
        let currentFiles = [];
        let existingImageUrl = null;

        function updateImageRequired() {
            const hasImage = existingImageUrl || currentFiles.length > 0;
            if (hasImage) fileInput.removeAttribute('required');
            else fileInput.setAttribute('required', 'required');
        }

        function renderPreview() {
            previewContainer.innerHTML = '';

            if (existingImageUrl) {
                createPreviewItem(existingImageUrl, true);
            }

            currentFiles.forEach((file, idx) => {
                const reader = new FileReader();
                reader.onload = e => createPreviewItem(e.target.result, false, idx);
                reader.readAsDataURL(file);
            });

            updateImageRequired();
        }

        function createPreviewItem(src, isExisting = false, index = null) {
            const col = document.createElement('div');
            col.className = 'col-4 col-md-3 position-relative mb-3';

            const wrapper = document.createElement('div');
            wrapper.className = 'border rounded overflow-hidden position-relative';
            wrapper.style.cssText =
                'height:150px;display:flex;align-items:center;justify-content:center;background:#f8f9fa;';

            const img = document.createElement('img');
            img.src = src;
            img.className = 'img-fluid';
            img.style.cssText = 'max-height:150px;max-width:100%;object-fit:contain;';

            const removeBtn = document.createElement('button');
            removeBtn.type = 'button';
            removeBtn.innerHTML = '×';
            removeBtn.className =
                'btn btn-danger btn-sm position-absolute top-0 end-0 rounded-circle d-flex align-items-center justify-content-center';
            removeBtn.style.cssText = 'width:28px;height:28px;font-size:16px;z-index:10;';

            removeBtn.onclick = function() {
                if (isExisting) {
                    existingImageUrl = null;
                    document.getElementById('current_image').value = '';
                } else {
                    currentFiles.splice(index, 1);
                    updateFileInput();
                }
                renderPreview();
            };

            wrapper.appendChild(img);
            wrapper.appendChild(removeBtn);
            col.appendChild(wrapper);
            previewContainer.appendChild(col);
        }

        function updateFileInput() {
            const dt = new DataTransfer();
            currentFiles.forEach(f => dt.items.add(f));
            fileInput.files = dt.files;
        }

        fileInput.addEventListener('change', function() {
            if (this.files.length > 0) {
                currentFiles = Array.from(this.files);
                existingImageUrl = null;
            }
            renderPreview();
        });

        window.showExistingImage = function(imagePath) {
            const fullPath = imagePath.startsWith('http') ? imagePath : '/' + imagePath.replace(/^\/+/, '');
            existingImageUrl = fullPath;
            document.getElementById('current_image').value = imagePath;
            currentFiles = [];
            fileInput.value = '';
            renderPreview();
        };

        window.cancelForm = function() {
            document.querySelector('form').reset();
            currentFiles = [];
            existingImageUrl = null;
            previewContainer.innerHTML = '';
            $('#hdBankId').val('');
            $('#current_image').val('');
            $('#apply_url').val('');
            $('#btnsave').html('Submit');
            updateImageRequired();
        };

        // Initial required state
        updateImageRequired();
    });
</script>
@endsection
