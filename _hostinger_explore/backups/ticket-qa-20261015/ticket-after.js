$(document).ready(function () {
    let table = $("#tblTicketList").DataTable({
        processing: true,
        serverSide: true,
        order: [[0, "ASC"]],
        ajax: "tickets-data",
        fnRowCallback: serialNoCount,
        columns: [
            { data: "id", orderable: false },
            { data: "display_name" },
            { data: "mobile" },
            {
                data: null,
                render: function (data, type, row) {
                    if (row.name) {
                        return '<span class="badge bg-label-primary">' + row.name + '</span>';
                    }
                    return row.subject ? row.subject : 'No Subject';
                }
            },
            {
                data: "created_at",
                render: function (data, type, row) {
                    return moment(data).format("DD-MM-YYYY hh:mm:ss A");
                },
            },
            {
                data: "message",
                render: function (data) {
                    var shown = explainOrderTicket(data);
                    if (!shown.text) return '';
                    var t = shown.text;
                    if (!shown.expanded && t.length > 80) t = t.substring(0, 79) + '…';
                    return '<div style="white-space:pre-wrap;">' + $('<div/>').text(t).html() + '</div>';
                }
            },
            {
                data: "ticket_status",
                render: function (data, type, row) {
                    var selectHTML =
                        '<select class="form-select ticket-status" id="tickekAtatus">';
                    selectHTML +=
                        '<option value="1" ' +
                        (data == 1 ? "selected" : "") +
                        ">Pending</option>";
                    selectHTML +=
                        '<option value="2" ' +
                        (data == 2 ? "selected" : "") +
                        ">On Process</option>";
                    selectHTML +=
                        '<option value="3" ' +
                        (data == 3 ? "selected" : "") +
                        ">Completed</option>";
                    selectHTML +=
                        '<option value="4" ' +
                        (data == 4 ? "selected" : "") +
                        ">Escalated</option>";
                    selectHTML += "</select>";
                    return selectHTML;
                },
            },
            {
                data: "id",
                orderable: false,
                render: function (data) {
                    return '<button type="button" class="btn btn-sm btn-primary ticket-reply-btn" data-id="' + data + '">Reply</button>';
                }
            },
        ],
    });
    $(document).on("change", "#tickekAtatus", function () {
        var data = table.row($(this).parents("tr")).data();
        var selectedValue = $(this).val();
        updateStatus(selectedValue, data);
    });

    var replyTicketId = null;

    $(document).on("click", ".ticket-reply-btn", function () {
        replyTicketId = $(this).data("id");
        openTicketReply(replyTicketId);
    });

    $("#trSendBtn").on("click", function () {
        sendTicketReply();
    });
});

function updateStatus(status, data) {
    $.ajax({
        type: "GET",
        url: "ticket-status-update/" + data.id,
        data: { status: status },
        dataType: "json",
        success: function (data) {
            if (data.notification.type == "success") {
                toastr.success(data.notification.message);
                toastr.options = {
                    closeButton: true,
                    progressBar: true,
                };
            } else {
                toastr.error(data.notification.message);
                toastr.options = {
                    closeButton: true,
                    progressBar: true,
                };
            }
            refreshDatatable("tblTicketList");
        },
    });
}

function openTicketReply(id) {
    $("#trThread").html('<div class="text-muted">Loading…</div>');
    $("#trMessage").val("");
    renderReplyTemplates();
    $.ajax({
        type: "GET",
        url: "tickets/" + id + "/thread",
        dataType: "json",
        success: function (res) {
            if (!res.success) {
                toastr.error(res.message || "Couldn’t load ticket");
                return;
            }
            var t = res.ticket;
            $("#trTicketId").text(t.id);
            $("#trSubject").text(t.subject || "Support");
            $("#trCustomer").text(t.customer || "");
            $("#trMobile").text(t.mobile || "");
            $("#trCreated").text(t.created_at || "");

            var html = "";
            html += bubbleHtml(true, t.customer || "User", explainOrderTicket(t.message || "").text, t.created_at || "");
            (res.replies || []).forEach(function (r) {
                html += bubbleHtml(!!r.from_user, r.author || (r.from_user ? "User" : "Mintzer"), r.message || "", r.created_at || "");
            });
            $("#trThread").html(html || '<div class="text-muted">No messages</div>');

            if (!res.supports_replies) {
                toastr.warning("Replies table not ready — run migrator on the server.");
                $("#trSendBtn").prop("disabled", true);
            } else {
                $("#trSendBtn").prop("disabled", false);
            }

            var modalEl = document.getElementById("ticketReplyModal");
            if (window.bootstrap && bootstrap.Modal) {
                bootstrap.Modal.getOrCreateInstance(modalEl).show();
            } else {
                $(modalEl).modal("show");
            }
        },
        error: function () {
            toastr.error("Couldn’t load ticket thread");
        }
    });
}

/** Logical fast replies — payment · delivery · invoice · order · resolve. */
var REPLY_TEMPLATES = [
    { cat: "Delivery", label: "Tracking check", text: "Thanks for writing in. We’re checking the courier tracking for your order and will update you here shortly." },
    { cat: "Delivery", label: "OFD / OTP", text: "Your parcel looks out for delivery. Please keep the delivery OTP ready and share it in the app once you receive it." },
    { cat: "Delivery", label: "Delayed courier", text: "Sorry for the delay. We’ve escalated this with the courier and will confirm as soon as there’s a fresh scan update." },
    { cat: "Invoice", label: "Need clearer invoice", text: "Please re-upload a clearer invoice (JPG/PNG/PDF) showing the store Order ID, product, and amount. Blurry or cropped files can’t be verified." },
    { cat: "Invoice", label: "GST mismatch", text: "The GST / company details on the invoice don’t match the delivery address on this deal. Please upload a corrected GST invoice." },
    { cat: "Invoice", label: "Invoice OK", text: "Invoice received and looks good. We’re moving your order to payment — usually within 48 working hours (no bank holidays)." },
    { cat: "Payment", label: "Payout in progress", text: "Your payout is in progress. Mintzer pays within 48 working hours after verification. We’ll confirm here once the UTR is available." },
    { cat: "Payment", label: "Bank details", text: "Please confirm the payout account saved in Profile → Payout account (name, account number, IFSC). We’ll re-check against that." },
    { cat: "Payment", label: "Paid / UTR", text: "Payment has been sent to your registered bank account. Please check your statement; if it doesn’t show in 24 hours, reply here with a screenshot." },
    { cat: "Order", label: "Need Order ID", text: "Please share the Flipkart/Amazon Order ID in the app (Place / Order detail) so we can match your purchase." },
    { cat: "Order", label: "Wrong amount", text: "We’re comparing what you paid at checkout with the deal’s You pay amount. Reply with a clear payment screenshot if you still see a gap." },
    { cat: "Order", label: "Cancel / refund", text: "We’ve noted the cancel/refund. If the store refunds your card, that follows the store’s timeline — Mintzer payout only applies to completed verified orders." },
    { cat: "Resolve", label: "Resolved", text: "This looks resolved on our side. If anything is still off, reply on this ticket within 48 hours — otherwise you can mark it resolved in the app." },
    { cat: "Resolve", label: "More info needed", text: "Could you share a bit more detail (Order ID, screenshot, or what you expected vs what happened)? We’ll pick it up as soon as we have that." },
];

function renderReplyTemplates() {
    var $box = $("#trTemplates");
    if (!$box.length) return;
    var html = "";
    REPLY_TEMPLATES.forEach(function (t, i) {
        html +=
            '<button type="button" class="btn btn-sm btn-outline-secondary tr-tpl" data-i="' +
            i +
            '" title="' +
            $("<div/>").text(t.cat).html() +
            '">' +
            $("<div/>").text(t.label).html() +
            "</button>";
    });
    $box.html(html);
}

$(document).on("click", ".tr-tpl", function () {
    var i = parseInt($(this).data("i"), 10);
    var t = REPLY_TEMPLATES[i];
    if (!t) return;
    $("#trMessage").val(t.text).focus();
});

function explainOrderTicket(message) {
    var raw = String(message || "").replace(/\r\n/g, "\n").trim();
    if (!raw) return { text: "", expanded: false };
    var orderLine = "";
    var body = raw;
    var parts = raw.split("\n");
    if (parts.length > 1 && /^Order\s+/i.test(parts[0].trim())) {
        orderLine = parts[0].trim();
        body = parts.slice(1).join("\n").trim();
    }
    var explained = explainTicketAnswers(body);
    if (!explained) return { text: raw, expanded: false };
    return { text: orderLine ? orderLine + "\n" + explained : explained, expanded: true };
}

function explainTicketAnswers(body) {
    var key = String(body || "").replace(/\s+/g, " ").trim().toLowerCase();
    var map = {
        "yes. yes": "Was checkout more than You pay? Yes\nHave a payment screenshot? Yes",
        "yes yes": "Was checkout more than You pay? Yes\nHave a payment screenshot? Yes",
        "yes. no": "Was checkout more than You pay? Yes\nHave a payment screenshot? No",
        "yes no": "Was checkout more than You pay? Yes\nHave a payment screenshot? No",
        "not sure. yes": "Was checkout more than You pay? Not sure\nHave a payment screenshot? Yes",
        "not sure yes": "Was checkout more than You pay? Not sure\nHave a payment screenshot? Yes",
        "not sure. no": "Was checkout more than You pay? Not sure\nHave a payment screenshot? No",
        "not sure no": "Was checkout more than You pay? Not sure\nHave a payment screenshot? No",
        "store canceled. yes": "Who canceled it? Store canceled\nGot cancel SMS or email? Yes",
        "store canceled. no": "Who canceled it? Store canceled\nGot cancel SMS or email? No",
        "i canceled. yes": "Who canceled it? I canceled\nGot cancel SMS or email? Yes",
        "i canceled. no": "Who canceled it? I canceled\nGot cancel SMS or email? No",
        "no": "Was that color on the deal? No",
        "deal said any color": "Was that color on the deal? Deal said any color",
        "storage / size": "What was different? Storage / size",
        "model": "What was different? Model",
        "not sure": "What was different? Not sure"
    };
    return map[key] || "";
}

function bubbleHtml(fromUser, author, message, at) {
    var align = fromUser ? "text-start" : "text-start";
    var bg = fromUser ? "#fff" : "#e8f0fe";
    var border = fromUser ? "#dadce0" : "#c2d7ff";
    return (
        '<div class="mb-2 p-2 rounded ' + align + '" style="background:' + bg + ';border:1px solid ' + border + ';">' +
        '<div class="small fw-semibold mb-1">' + $('<div/>').text(author).html() +
        ' <span class="text-muted fw-normal">· ' + $('<div/>').text(at).html() + '</span></div>' +
        '<div style="white-space:pre-wrap;">' + $('<div/>').text(message).html() + '</div>' +
        "</div>"
    );
}

function sendTicketReply() {
    var id = $("#trTicketId").text();
    var msg = ($("#trMessage").val() || "").trim();
    if (!id || msg.length < 1) {
        toastr.warning("Write a reply first");
        return;
    }
    $("#trSendBtn").prop("disabled", true);
    $.ajax({
        type: "POST",
        url: "tickets/" + id + "/reply",
        data: {
            message: msg,
            _token: $('meta[name="csrf-token"]').attr("content"),
        },
        dataType: "json",
        success: function (res) {
            $("#trSendBtn").prop("disabled", false);
            if (!res.success) {
                toastr.error(res.message || "Failed");
                return;
            }
            toastr.success(res.message || "Reply sent");
            $("#trMessage").val("");
            openTicketReply(id);
            refreshDatatable("tblTicketList");
        },
        error: function (xhr) {
            $("#trSendBtn").prop("disabled", false);
            var m = (xhr.responseJSON && xhr.responseJSON.message) || "Couldn’t send reply";
            toastr.error(m);
        }
    });
}
