$(document).ready(function () {
    var table = $("#tblbannersList").DataTable({
        processing: true,
        serverSide: true,
        order: [[0, "ASC"]],
        ajax: "banner-data",
        fnRowCallback: serialNoCount,
        columns: [
            { data: "id", orderable: false },
            {
                data: "image",
                render: function (data, type, row) {
                    return (
                        '<img src="' +
                        data +
                        '" alt="' +
                        row.name +
                        '" style="width: 64px;height: 59px;" />'
                    );
                },
            },
            { data: "name" },
            {
                data: "status",
                render: function (data, type, row) {
                    var isChecked = data == 1 ? "checked" : "";
                    return `<label class="switch">
                                <input id="chkBanner${row.id}" type="checkbox" class="switch-input" ${isChecked} onchange="doStatus(${row.id});" />
                                <span class="switch-toggle-slider">
                                    <span class="switch-on"></span>
                                    <span class="switch-off"></span>
                                </span>
                            </label>`;
                },
            },
            {
                data: "created_at",
                render: function (data, type, row) {
                    var formattedDate = moment(row.created_at).format(
                        "DD-MM-YYYY hh:mm a"
                    );
                    return formattedDate;
                },
            },
            { data: "action" },
        ],
    });
    $("#tblbannersList").on("click", ".ti-pencil", function () {
        var data = table.row($(this).parents("tr")).data();
        doEdit(data);
    });
});

//edit bank
function doEdit(data) {
    if (data.image) {
        $("#imageDisplay").attr("src", data.image);
        $("#imageDisplayDiv").show();
    } else {
        $("#imageDisplayDiv").hide();
    }

    $("#btnsave").html("Update");
    $("#imageDiv").removeClass("col-6");
    $("#imageDiv").addClass("col-3");
    $("#hdBannerId").val(data.id);
    $("#txtBannerName").val(data.name);
    $("#txtbannermessage").val(data.short_description);
    $("#txtbannerlink").val(data.url);
    $("#bannerImage").removeAttr("required");
    $("html, body").animate(
        {
            scrollTop: 0,
        },
        "slow"
    );
}

//delete store
function showDelete(id) {
    // console.log(id);
    confirmDelete(id, "banner/delete/", "tblbannersList");
}

// status change 
function doStatus(id) {
    var status = $("#chkBanner" + id).prop("checked");
    Swal.fire({
        title: "Are you sure?",
        text: "You want to change status?",
        icon: status ? "warning" : "error",
        showCancelButton: true,
        confirmButtonText: status ? "Yes, Activate it!" : "Yes, Deactivate it!",
        customClass: {
            confirmButton: "btn btn-success me-3",
            cancelButton: "btn btn-danger",
        },
        buttonsStyling: false,
        width: '20%',
    }).then(function (result) {
        if (result.isConfirmed) {
            statusUpdate(id, "banner-status-update/", status ? 1 : 0);
            Swal.fire({
                icon: "success",
                title: "Updated!",
                text: "Status changed successfully.",
                customClass: {
                    confirmButton: "btn btn-success",
                },
                width: "20%",
            }).then(function () {
                var currentPageIndex = $("#tblbannersList")
                    .DataTable()
                    .page.info().page;
                // Refresh the datatable
                $("#tblbannersList")
                    .DataTable()
                    .ajax.reload(function () {
                        $("#tblbannersList")
                            .DataTable()
                            .page(currentPageIndex)
                            .draw("page");
                    });
            });
        } else {
            $("#chkBanner" + id).prop("checked", !status);
        }
    });
}

//cancel
function cancel() {
    $("#txtBannerName").val("");
    $("#txtbannermessage").val("");
    $("#txtbannerlink").val("");
    $("#bannerImage").val("");
    $("#hdBannerId").val("");
    $("#btnsave").html("Submit");
    $("#imageDisplayDiv").hide();
    $("#imageDiv").removeClass("col-3");
    $("#imageDiv").addClass("col-6");
    $("#bank_image").attr("required", "required");
}
