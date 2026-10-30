$(document).ready(function () {
    let table = $("#tblBanksList").DataTable({
        processing: true,
        serverSide: true,
        order: [[0, "ASC"]],
        ajax: "bank-data",
        fnRowCallback: serialNoCount,
        columns: [
            { data: "id", orderable: false },
            {
                data: "image",
                render: function (data, type, row) {
                    const src = data ? data : '{{ asset("assets/img/avatars/1.png") }}';
                    return `<img src="${src}" alt="${row.name}" style="width:64px;height:59px;object-fit:contain;">`;
                },
            },
            { data: "name" },
            {
                data: "created_at",
                render: function (data) {
                    return moment(data).format("DD-MM-YYYY hh:mm a");
                },
            },
            { data: "action" },
        ],
    });

    $("#tblBanksList").on("click", ".ti-pencil", function () {
        var data = table.row($(this).parents("tr")).data();
        doEdit(data);
    });
});

function showDelete(id) {
    confirmDelete(id, "bank/delete/", "tblBanksList");
}

function doEdit(data) {
    $('#hdBankId').val(data.id);
    $('#bank_name').val(data.name);
    $('#apply_url').val(data.apply_url || '');
    $('#btnsave').html('Update');

    if (data.image && data.image.trim() !== '') {
        window.showExistingImage(data.image);
    } else {
        $('#image-preview').html('');
        $('#current_image').val('');
    }

    $("html, body").animate({ scrollTop: 0 }, "slow");
}