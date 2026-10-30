var table;
var startdate = "";
var enddate = "";
var selectedStatus = $("#hdStatus").val();
var selectedInvoiceStatus = $("#ddlInvoiceStatus").val() || "";

/**
 * Reload orders DataTable without jumping to page 1 or scrolling to top.
 * Cancel / reject / status updates must use this (not a bare ajax.reload()).
 */
function refreshDatatable(tableId) {
    var id = tableId || "tblOrderList";
    var $table = $("#" + id);
    if (!$table.length || !$.fn.dataTable.isDataTable($table)) {
        return;
    }

    var dt = $table.DataTable();
    var page = dt.page.info().page;
    var winTop = $(window).scrollTop();
    var winLeft = $(window).scrollLeft();
    var $wrap = $table.closest(
        ".dataTables_scrollBody, .orders-table-wrap, .table-scroll-bottom, .card-datatable, .table-responsive"
    );
    var wrapTop = $wrap.length ? $wrap.scrollTop() : 0;
    var wrapLeft = $wrap.length ? $wrap.scrollLeft() : 0;

    dt.ajax.reload(function () {
        var pages = dt.page.info().pages;
        if (pages > 0 && page >= pages) {
            page = pages - 1;
        }
        if (page >= 0) {
            dt.page(page).draw(false);
        }
        // Restore scroll after DataTables paints (modal close often resets it).
        setTimeout(function () {
            $(window).scrollTop(winTop).scrollLeft(winLeft);
            if ($wrap.length) {
                $wrap.scrollTop(wrapTop).scrollLeft(wrapLeft);
            }
        }, 50);
    }, false); // false = keep current paging
}

$(document).ready(function () {
    function getDefaultPageLength() {
        return window.innerHeight >= 900 ? 15 : 10;
    }

    const defaultPageLength = getDefaultPageLength();

    function applyColumnPreset(visibleColumns) {
        if (!table) return;
        table.columns().every(function (idx) {
            const shouldShow = visibleColumns.includes(idx);
            this.visible(shouldShow, false);
        });
        table.columns.adjust().draw(false);
    }

    function setStickyColumnsEnabled(enabled) {
        const $wrap = $('.orders-table-wrap');
        if (!$wrap.length) return;
        $wrap.toggleClass('sticky-disabled', !enabled);
    }

    function escapeAttr(value) {
        return String(value ?? "")
            .replace(/&/g, "&amp;")
            .replace(/"/g, "&quot;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;");
    }

    function stampIcon(label, raw) {
        if (!raw) return "";
        const t = moment(raw).format("DD-MM-YYYY hh:mm:ss A");
        if (!t || t === "Invalid date") return "";
        return ' <i class="ti ti-clock text-info ms-1" data-bs-toggle="tooltip" data-bs-placement="top" title="' + escapeAttr(label + ": " + t) + '"></i>';
    }

    function truncateText(value, maxLength) {
        const str = String(value ?? "");
        if (str.length <= maxLength) return str;
        return str.substring(0, maxLength) + "...";
    }

    function rupee(n) {
        const v = Math.round(Number(n) || 0);
        return "₹" + v.toLocaleString("en-IN");
    }

    function holderToPay(row) {
        let amount = Number(row.order_deal_card_holder_recieve ?? row.card_holder_recieve ?? 0);
        if (row.tds_amount && Number(row.tds_amount) > 0) {
            amount = amount - Number(row.tds_amount);
        }
        return Math.round(amount);
    }

    function courierClass(name) {
        const n = String(name || "").toLowerCase();
        if (n.includes("ekart") || n.includes("e-kart") || n.includes("flipkart")) return "c-ekart";
        if (n.includes("delhivery")) return "c-delh";
        if (n.includes("bluedart") || n.includes("blue dart")) return "c-blue";
        if (n.includes("xpress")) return "c-xpress";
        if (n.includes("shadow")) return "c-shadow";
        return "c-other";
    }

    function last4Mobile(mobile) {
        const digits = String(mobile || "").replace(/\D/g, "");
        if (digits.length < 4) return "";
        return "··" + digits.slice(-4);
    }

    /** Compact Orders row: hide columns merged into User / Money / Store / Ship */
    const COMPACT_VISIBLE = [0, 2, 3, 4, 7, 8, 12, 13, 14, 15, 16];

    // ---------------- DATE RANGE PICKER ----------------
    $("#btnDate").daterangepicker({
            autoUpdateInput: false,
            opens: "right",
            startDate: moment().startOf("day"),
            endDate: moment().endOf("day"),
            ranges: {
                All: [moment().startOf("day"), moment().endOf("day")],
                Today: [moment(), moment()],
                Yesterday: [
                    moment().subtract(1, "days"),
                    moment().subtract(1, "days"),
                ],
                "Last 7 Days": [moment().subtract(6, "days"), moment()],
                "Last 30 Days": [moment().subtract(29, "days"), moment()],
                "This Month": [
                    moment().startOf("month"),
                    moment().endOf("month"),
                ],
                "Last Month": [
                    moment().subtract(1, "month").startOf("month"),
                    moment().subtract(1, "month").endOf("month"),
                ],
            },
        },
        getDate
    );

    function getDate(start, end, label) {
        if (label === "All") {
            startdate = "";
            enddate = "";
            $("#btnDate span").html("All Orders");
        } else {
            startdate = start.format("YYYY-MM-DD");
            enddate = end.format("YYYY-MM-DD");

            $("#btnDate span").html(
                start.format("MMM D, YYYY") + " - " + end.format("MMM D, YYYY")
            );
        }

        table.ajax.reload();
    }

    // ---------------- DATATABLE ----------------
    table = $("#tblOrderList").DataTable({
        processing: true,
        serverSide: true,
        order: [
            [0, "DESC"]
        ],
        pageLength: defaultPageLength,
        lengthMenu: [
            [10, 15, 25, 50, -1],
            [10, 15, 25, 50, "All"],
        ],
        dom: '<"top d-flex justify-content-between align-items-center"<"left"lB><"right"f>>t<"bottom"ip>',
        buttons: [{
            extend: "excelHtml5",
            text: '<i class="fa-solid fa-file-excel"></i> Export Excel',
            className: "btn btn-success dt-button",

            title: function () {
                return (
                    "Order List - " + moment().format("YYYY-MM-DD HH:mm:ss")
                );
            },
            exportOptions: {
                columns: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 13],
                orthogonal: "export",
                format: {
                    body: function (data) {
                        if (data === null || data === undefined) return "";
                        if (typeof data !== "string")
                            data = data.toString();
                        return data.replace(/(<([^>]+)>)/gi, "").trim();
                    },
                },
            },

            // ---------------- CUSTOM EXPORT ALL HANDLER ----------------
            action: function (e, dt, button, config) {
                let totalRecords = dt.page.info().recordsTotal;
                let currentPageLength = dt.page.len();

                if (
                    currentPageLength !== -1 &&
                    currentPageLength < totalRecords
                ) {
                    Swal.fire({
                        title: "Export All Data?",
                        text: "You did not select 'All'. Export only displayed rows?",
                        icon: "warning",
                        showCancelButton: true,
                        confirmButtonText: "Export Displayed",
                        cancelButtonText: "Select All First",
                    }).then((result) => {
                        if (result.isConfirmed) {
                            $.fn.dataTable.ext.buttons.excelHtml5.action.call(
                                this,
                                e,
                                dt,
                                button,
                                config
                            );
                        }
                    });
                } else {
                    $.fn.dataTable.ext.buttons.excelHtml5.action.call(
                        this,
                        e,
                        dt,
                        button,
                        config
                    );
                }
            },
        },
        {
            extend: "colvis",
            text: '<i class="fas fa-columns"></i> Columns',
            className: "btn btn-outline-primary dt-button btn-columns-compact",
            columns: ':not(:first-child)',
            collectionLayout: 'fixed two-column',
            postfixButtons: ['colvisRestore']
        },
        {
            text: '<i class="fas fa-money-check-dollar"></i> Payout View',
            className: "btn btn-outline-info dt-button btn-preset-compact",
            action: function () {
                applyColumnPreset([0, 2, 3, 4, 12, 13, 14, 15, 16]);
                setStickyColumnsEnabled(false);
            }
        },
        {
            text: '<i class="fas fa-truck-fast"></i> Tracking View',
            className: "btn btn-outline-secondary dt-button btn-preset-compact",
            action: function () {
                applyColumnPreset([0, 2, 3, 7, 8, 9, 10, 11, 12]);
                setStickyColumnsEnabled(false);
            }
        },
        {
            text: '<i class="fas fa-rotate-left"></i> Default View',
            className: "btn btn-outline-dark dt-button btn-preset-compact",
            action: function () {
                applyColumnPreset(COMPACT_VISIBLE);
                setStickyColumnsEnabled(true);
            }
        }],
        ajax: {
            url: "/order-data",
            dataSrc: function (json) {
                $("#payoutPendingCount").text(json.payout_pending_count ?? 0);
                $("#outForDeliveryCount").text(json.out_for_delivery_count ?? 0);
                $("#orderedValue").text(rupee(json.ordered_value));
                $("#payoutPendingValue").text(rupee(json.payout_pending_value));
                return json.data;
            },
            data: function (d) {
                d.startdate = startdate;
                d.enddate = enddate;
                d.status = selectedStatus;
                d.invoice_status = selectedInvoiceStatus;
                d.user_id = $("#hdUserId").val() || "";
            },
        },
        fnRowCallback: function (nRow, aData, iDisplayIndex) {
            var tableInfo = table.page.info();
            var index = tableInfo.start + iDisplayIndex + 1;
            $("td:eq(0)", nRow).html(index);
            return nRow;
        },
        createdRow: function (row, data) {
            $(row).removeClass("row-payout-pending row-out-for-delivery row-payout-completed row-ready-to-pay");
            const isReadyForPayout = Number(data.is_ready_for_payout || 0) === 1;
            const isPayoutDone = Number(data.is_payout || 0) === 1;
            const isDelivered = (data.order_status || "") === "Delivered";
            const isVerified = (data.verification_status || "") === "Verified";
            if (Number(data.is_payout || 0) === 1) {
                $(row).addClass("row-payout-completed");
                return;
            }
            if (
                isReadyForPayout &&
                !isPayoutDone &&
                isDelivered &&
                isVerified
            ) {
                $(row).addClass("row-ready-to-pay");
                return;
            }
            if (
                isReadyForPayout &&
                !isPayoutDone &&
                !["Cancelled", "Declined"].includes(data.order_status)
            ) {
                $(row).addClass("row-payout-pending");
                return;
            }
            if (data.order_status === "Out For Delivery" && Number(data.is_payout || 0) === 0) {
                $(row).addClass("row-out-for-delivery");
            }
        },
        drawCallback: function () {
            const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
            tooltipTriggerList.forEach(function (el) {
                if (window.bootstrap && window.bootstrap.Tooltip) {
                    const existing = window.bootstrap.Tooltip.getInstance(el);
                    if (existing) existing.dispose();
                    new window.bootstrap.Tooltip(el);
                }
            });
        },
        columns: [{
                data: "id",
                orderable: false
            },
            {
                data: "order_number",
                visible: false,
                render: function (data, type) {
                    return data ?? "";
                }
            },
            {
                data: "user_name",
                className: "sticky-col-1 ord-user",
                render: function (data, type, row) {
                    if (type !== "display") return data ?? "";
                    const name = data ?? "-";
                    const ord = row.order_number ? String(row.order_number) : "";
                    const uid = row.user_id ? String(row.user_id) : "";
                    const nameHtml = uid
                        ? '<a class="ord-user-name" href="/orders?user=' + encodeURIComponent(uid) + '">' + escapeAttr(name) + "</a>"
                        : '<strong class="ord-user-name">' + escapeAttr(name) + "</strong>";
                    return (
                        '<div class="ord-user-cell" title="' + escapeAttr(name + (ord ? " · " + ord : "")) + '">' +
                        nameHtml +
                        (ord ? '<div class="ord-user-ord mono">' + escapeAttr(ord) + "</div>" : "") +
                        "</div>"
                    );
                }
            },
            {
                data: "order_deal_name",
                className: "sticky-col-2 deal-name-cell",
                render: function (data, type, row) {
                    const dealName = data ?? row.deal_name ?? "-";
                    if (type === "display") {
                        return '<span class="ord-deal" title="' + escapeAttr(dealName) + '">' + escapeAttr(dealName) + "</span>";
                    }
                    return dealName;
                },
            },
            {
                data: "order_amount",
                className: "sticky-col-3 ord-money-col",
                render: function (data, type, row) {
                    const ordered = Math.round(Number(data ?? 0));
                    const toPay = holderToPay(row);
                    if (type !== "display") return ordered;
                    return (
                        '<div class="ord-money" title="Ordered / To Pay (holder)">' +
                        '<div class="row-m"><span class="lbl">Ordered</span><span class="ordered">' + ordered + "</span></div>" +
                        '<div class="row-m"><span class="lbl">To Pay</span><span class="topay">' + toPay + "</span></div>" +
                        "</div>"
                    );
                }
            },
            {
                data: "order_deal_card_holder_recieve",
                visible: false,
                render: function (data, type, row) {
                    return holderToPay(row);
                },
            },
            {
                data: "order_date",
                name: "order_date",
                visible: false,
                render: function (data, type, row) {
                    if (!data) return "";
                    return moment(data).format("DD-MM-YYYY hh:mm:ss A");
                },
            },
            {
                data: "store_order_id",
                className: "ord-store-col",
                render: function (data, type, row) {
                    if (type !== "display") return data ? data : "";
                    const dateStr = row.order_date
                        ? moment(row.order_date).format("DD MMM YY · h:mm A")
                        : "";
                    const dateTitle = row.order_date
                        ? moment(row.order_date).format("DD-MM-YYYY hh:mm:ss A")
                        : "";
                    let storeHtml;
                    if (data) {
                        const fullValue = String(data);
                        storeHtml =
                            '<span class="editable-field order-id-cell ord-store-edit" data-field="store_order_id" data-order-id="' + row.id + '">' +
                            '<span class="ord-store" title="' + escapeAttr(fullValue) + '" data-current-value="' + escapeAttr(fullValue) + '">' + escapeAttr(fullValue) + "</span>" +
                            ' <i class="fas fa-edit edit-tick" style="color: #28a745; cursor: pointer; font-size: 12px;" title="Edit"></i>' +
                            stampIcon("Entered", row.store_order_at) +
                            "</span>";
                    } else {
                        storeHtml = '<span class="text-muted">—</span>';
                    }
                    return (
                        '<div class="ord-store-cell">' +
                        storeHtml +
                        (dateStr
                            ? '<div class="ord-store-date" title="' + escapeAttr(dateTitle) + '">' + escapeAttr(dateStr) + "</div>"
                            : "") +
                        "</div>"
                    );
                },
            },
            {
                data: "order_tracking_id",
                className: "ord-ship-col",
                render: {
                    display: function (data, type, row) {
                        // No tracking → tracking reminder only
                        if (data === null || data === "" || data === undefined) {
                            return (
                                '<span class="bell-wrap">' +
                                '<button type="button" class="ord-bell tracking-notify" data-order-id="' + row.id + '" title="Remind: add tracking ID">🔔</button>' +
                                '<span class="hint">tracking</span></span>'
                            );
                        }
                        const fullValue = String(data);
                        const partner = row.delivery_partner_name || "";
                        const otp = row.order_delivery_otp;
                        const otpMissing = (otp === null || otp === "" || otp === undefined);
                        const otpText = otpMissing ? "" : String(otp);
                        const mob = last4Mobile(row.account_mobile_number);
                        const cClass = courierClass(partner);
                        const partnerLabel = partner || "—";
                        const title = [fullValue, partnerLabel, otpMissing ? "OTP?" : otpText, mob].filter(Boolean).join(" · ");

                        // OTP missing → OTP notify bell (same otp-notify API as before)
                        var otpPart;
                        if (otpMissing) {
                            otpPart =
                                '<button type="button" class="ord-bell ord-bell-sm otp-notify" data-order-id="' + row.id + '" title="Remind: add delivery OTP">🔔</button>' +
                                '<span class="hint">OTP</span>';
                        } else {
                            otpPart = escapeAttr(otpText);
                        }

                        return (
                            '<div class="ord-ship" title="' + escapeAttr(title) + '">' +
                            '<div class="l1">' +
                            '<span class="editable-field order-id-cell" data-field="order_tracking_id" data-order-id="' + row.id + '">' +
                            '<span class="track" title="' + escapeAttr(fullValue) + '" data-current-value="' + escapeAttr(fullValue) + '">' + escapeAttr(fullValue) + "</span>" +
                            ' <i class="fas fa-edit edit-tick" style="color: #28a745; cursor: pointer; font-size: 11px;" title="Edit"></i>' +
                            stampIcon("Shipped", row.shipped_date) +
                            "</span>" +
                            "</div>" +
                            '<div class="l2">' +
                            '<span class="courier ' + cClass + '">' + escapeAttr(partnerLabel) + "</span>" +
                            '<span class="sep">·</span>' +
                            (otpMissing
                                ? '<span class="bell-inline">' + otpPart + "</span>"
                                : otpPart) +
                            (mob ? '<span class="sep">·</span>' + escapeAttr(mob) : "") +
                            "</div></div>"
                        );
                    },
                    export: function (data) {
                        return data ? data : "-";
                    }
                },
            },
            {
                data: "delivery_partner_name",
                visible: false
            },
            {
                data: "order_delivery_otp",
                visible: false,
                render: {
                    display: function (data, type, row) {
                        if (data === null || data === "" || data === undefined) {
                            return '<button type="button" class="btn btn-xs btn-info otp-notify" data-order-id="' + row.id + '">Reminder</button>';
                        }
                        const fullValue = String(data ?? "");
                        const shortValue = truncateText(fullValue, 24);
                        return data ?
                            '<span class="editable-field order-id-cell" data-field="order_delivery_otp" data-order-id="' + row.id + '">' +
                            '<span class="inline-ellipsis" title="' + escapeAttr(fullValue) + '" data-current-value="' + escapeAttr(fullValue) + '">' + shortValue + '</span>' +
                            ' <i class="fas fa-edit edit-tick" style="color: #28a745; cursor: pointer; font-size: 14px;" title="Edit"></i></span>' :
                            data;
                    },
                    export: function (data) {
                        return data ? data : "-";
                    }
                },
            },
            {
                data: "account_mobile_number",
                visible: false,
                render: function (data, type, row) {
                    return data ?? "-";
                },
            },
            {
                data: "order_status",
                className: "ord-dd-col",
                render: {
                    display: function (data, type, row) {
                        // ONLY terminal states lose the dropdown (same as pre-compact)
                        if (data === "Delivered") {
                            return '<span class="badge bg-success">Delivered</span>';
                        }
                        if (data === "Rejected") {
                            return '<span class="badge bg-danger">Rejected</span>';
                        }
                        if (data === "Cancelled") {
                            return '<span class="badge bg-secondary">Cancelled</span>';
                        }

                        // Shipped / OFD / Accepted / etc. — keep Delivered / Reject dropdown
                        var label = data ? String(data) : "Status";
                        return (
                            '<select class="form-select order-status ord-dd">' +
                            '<option value="" selected disabled>' + escapeAttr(label) + "</option>" +
                            '<option value="Delivered">Delivered</option>' +
                            '<option value="Rejected">Reject</option>' +
                            "</select>"
                        );
                    },
                    export: function (data) {
                        return data ?? "-";
                    },
                },
            },
            {
                data: "account_order_pdf",
                className: "ord-bill-col",
                render: function (data, type, row) {
                    if (type === "sort" || type === "filter" || type === "type") {
                        return data ? "Invoice" : "";
                    }
                    if (data) {
                        const uploadTime = row.invoice_upload_date
                            ? moment(row.invoice_upload_date).format("DD-MM-YYYY hh:mm:ss A")
                            : "Upload time not available";
                        return (
                            '<div class="ord-inv">' +
                            '<a href="' + baseUrl + "/" + data + '" target="_blank"><i class="fa fa-file"></i> Invoice</a>' +
                            ' <i class="ti ti-clock text-info ms-1" data-bs-toggle="tooltip" data-bs-placement="top" title="Uploaded: ' + escapeAttr(uploadTime) + '"></i>' +
                            "</div>"
                        );
                    }
                    return (
                        '<span class="bell-wrap">' +
                        '<button type="button" class="ord-bell invoice-notify" data-order-id="' + row.id + '" title="Remind: upload invoice">🔔</button>' +
                        '<span class="hint">invoice</span></span>'
                    );
                },
            },
            {
                data: "verification_status",
                orderable: false,
                className: "ord-dd-col",
                render: function (data, type, row) {
                    // Keep sort/filter plain; never skip HTML on display
                    if (type === "sort" || type === "filter" || type === "type") {
                        return data ?? "";
                    }
                    if (data == "Verified") {
                        return '<span class="badge bg-success"><i class="fas fa-check"></i> Verified</span>';
                    }
                    var selectHTML =
                        '<select class="form-select verify-status ord-dd">';
                    selectHTML +=
                        '<option value="" selected disabled>Select</option>';

                    // Same as live before: no PDF → Alert; has PDF → Verify / Re-Upload
                    if (!row.account_order_pdf) {
                        selectHTML +=
                            '<option value="Alerted" ' +
                            (data == "Alerted" ? "selected" : "") +
                            ">Alert</option>";
                    } else {
                        selectHTML +=
                            '<option value="Verified" ' +
                            (data == "Verified" ? "selected" : "") +
                            ">Verify</option>";
                        selectHTML +=
                            '<option value="Re-Upload" ' +
                            (data == "Re-Upload" ? "selected" : "") +
                            ">Re-Upload</option>";
                    }

                    selectHTML += "</select>";
                    return selectHTML;
                },
            },
            {
                data: null,
                orderable: false,
                className: "ord-pay-col",
                render: function (data, type, row) {
                    const encodedModel = encodeURIComponent(row.order_deal_name || row.deal_name || "");
                    const isVerified = row.verification_status === "Verified";
                    const isDelivered = row.order_status === "Delivered";
                    const hasInvoice = !!row.account_order_pdf;
                    if (row.is_payout == 1) {
                        const completedClass = (isVerified && isDelivered)
                            ? "badge bg-success"
                            : "badge bg-primary";
                        const completedText = (isVerified && isDelivered)
                            ? "Paid"
                            : "Payout Completed";
                        return `
                            <button 
                                type="button" 
                                onclick="openModel(${row.id}, '${row.order_deal_card_holder_recieve ?? row.card_holder_recieve}', '${row.tds_amount ?? 0}', 'confirmed', '${encodedModel}')"
                                class="${completedClass}" style="border: none;">
                                <i class="fas fa-check"></i> ${completedText}
                            </button>
                        `;
                    } else if (row.is_ready_for_payout == 1) {
                        let payoutClass = "btn btn-xs btn-info waves-effect waves-light";
                        let payoutText = "Payout";
                        if (isVerified && isDelivered) {
                            payoutClass = "btn btn-xs btn-primary waves-effect waves-light";
                            payoutText = "Payout Pending";
                        } else if (isVerified) {
                            payoutClass = "btn btn-xs btn-warning waves-effect waves-light";
                            payoutText = "Ready for Payout";
                        } else if (hasInvoice) {
                            payoutClass = "btn btn-xs btn-secondary waves-effect waves-light";
                            payoutText = "Invoice Uploaded";
                        }
                        return `
                            <button 
                                type="button"                                               
                                onclick="openModel(${row.id}, '${row.order_deal_card_holder_recieve ?? row.card_holder_recieve}', '${row.tds_amount ?? 0}', 'pending', '${encodedModel}')"
                                class="${payoutClass}">
                                ${payoutText}
                            </button>
                        `;
                    } else {
                        return '<button type="button" disabled class="btn btn-xs btn-secondary waves-effect waves-light">Not Ready</button>';
                    }
                },
            },
            {
                data: null,
                render: function (data, type, row) {
                    if (['Delivered', 'Cancelled'].includes(row.order_status)) {
                        return '<button class="btn btn-danger" disabled>Cancel</button>';
                    }
                    return `<button class="btn btn-danger" onclick="openCancelModal(${row.id})">Cancel</button>`;
                }
            }
        ]
    });

    applyColumnPreset(COMPACT_VISIBLE);

    setStickyColumnsEnabled(true);
    table.on('column-visibility.dt', function () {
        const stickyOk = table.column(2).visible() && table.column(3).visible() && table.column(4).visible();
        setStickyColumnsEnabled(stickyOk);
    });

    $("#tblOrderList").on("click", ".tracking-notify", function () {
        const $btn = $(this);
        if ($btn.data("sending")) return;
        $btn.data("sending", true).prop("disabled", true);

        var orderId = $btn.data("order-id");
        $.ajax({
            url: baseUrl + "/tracking-send-notify/" + orderId,
            type: "GET",
            success: function (response) {
                toastr.success(
                    response.message || "Reminder Notification sent successfully",
                    "Remainder Notification sent successfully"
                );
                refreshDatatable("tblOrderList");
            },
            error: function (xhr, status, error) {
                console.error(xhr.responseText);
                toastr.error("Error sending notification", "Error");
            },
            complete: function () {
                $btn.data("sending", false).prop("disabled", false);
            },
        });
    });

    $("#tblOrderList").on("click", ".invoice-notify", function () {
        const $btn = $(this);
        if ($btn.data("sending")) return;
        const data = table.row($btn.closest("tr")).data();
        if (!data) return;
        $btn.data("sending", true).prop("disabled", true);
        updateVerifyStatus("Alerted", data);
        setTimeout(function () {
            $btn.data("sending", false).prop("disabled", false);
        }, 800);
    });

    $("#tblOrderList").on("click", ".otp-notify", function () {
        const $btn = $(this);
        if ($btn.data("sending")) return;
        $btn.data("sending", true).prop("disabled", true);

        var orderId = $btn.data("order-id");
        $.ajax({
            url: baseUrl + "/otp-send-notify/" + orderId,
            type: "GET",
            success: function (response) {
                toastr.success(
                    response.message || "Reminder Notification sent successfully",
                    "Remainder Notification sent successfully"
                );
                refreshDatatable("tblOrderList");
            },
            error: function (xhr, status, error) {
                console.error(xhr.responseText);
                toastr.error("Error sending notification", "Error");
            },
            complete: function () {
                $btn.data("sending", false).prop("disabled", false);
            },
        });
    });

    // ---------------- FILTER CHANGE EVENTS ----------------
    $(document).on("change", "#statusFilter", function () {
        selectedStatus = $(this).val();
        table.ajax.reload();
    });

    $(document).on("change", "#ddlInvoiceStatus", function () {
        selectedInvoiceStatus = $(this).val();
        table.ajax.reload();
    });

    // ---------------- BLOCK EXPORT UNTIL DATA LOADED ----------------

    // Disable the export button on load
    $(".buttons-excel").prop("disabled", true).addClass("disabled");

    table.on("processing.dt", function (e, settings, processing) {
        if (processing) {
            // Table is loading → disable export
            $(".buttons-excel").prop("disabled", true).addClass("disabled");
        } else {
            // Table finished loading → enable export
            $(".buttons-excel").prop("disabled", false).removeClass("disabled");
        }
    });

    // Show cancel modal


    // Show/hide "Other" reason textarea
    $(document).on('change', '#cancelReason', function () {
        if ($(this).val() === 'Other') {
            $('#otherReasonDiv').show();
            $('#otherReason').prop('required', true);
        } else {
            $('#otherReasonDiv').hide();
            $('#otherReason').prop('required', false);
        }
    });

    $(document).ready(function () {
        $(document).on('click', '.edit-tick', function (e) {
            e.stopPropagation();

            const $parentSpan = $(this).closest('.editable-field');
            const orderId = $parentSpan.data('order-id');
            const fieldName = $parentSpan.data('field');
            const currentValue = $parentSpan.find('[data-current-value]').attr('data-current-value') || $parentSpan.text().trim();
            const fieldLabels = {
                'store_order_id': 'Store Order ID',
                'order_tracking_id': 'Tracking ID',
                'order_delivery_otp': 'Delivery OTP'
            };

            Swal.fire({
                html: `<p>Edit ${fieldLabels[fieldName]}</p>
                        <input type="text" id="editField" class="swal2-input" style="width: 68%;" value="${currentValue}" placeholder="Enter ${fieldLabels[fieldName]}">`,
                showCancelButton: true,
                confirmButtonText: 'Update',
                cancelButtonText: 'Cancel',
                width: "20%",
                preConfirm: () => {
                    const value = $('#editField').val().trim();
                    if (!value) {
                        Swal.showValidationMessage('Please enter a value');
                    }
                    return {
                        value: value
                    };
                }
            }).then((result) => {
                if (result.isConfirmed) {
                    updateField(orderId, fieldName, result.value.value);
                }
            });
        });

        function updateField(orderId, fieldName, value) {
            $.ajax({
                url: baseUrl +'/update-order-field',
                type: 'POST',
                data: {
                    order_id: orderId,
                    field: fieldName,
                    value: value,
                    _token: $('meta[name="csrf-token"]').attr('content') // For Laravel
                },
                beforeSend: function () {
                    Swal.fire({
                        title: 'Updating...',
                        text: 'Please wait',
                        allowOutsideClick: false,
                        width: "20%",
                        didOpen: () => {
                            Swal.showLoading();
                        }
                    });
                },
                success: function (response) {
                    Swal.close();
                    if (response.success) {
                        Swal.fire({
                            icon: 'success',
                            title: 'Success!',
                            text: response.message || 'Field updated successfully',
                            timer: 2000,
                            showConfirmButton: false,
                            width: "20%",
                        });
                        refreshDatatable("tblOrderList");
                    } else {
                        Swal.fire({
                            icon: 'error',
                            title: 'Error!',
                            text: response.message || 'Failed to update field',
                            width: "20%",
                        });
                    }
                },

                error: function (xhr, status, error) {
                    Swal.close();
                    Swal.fire({
                        icon: 'error',
                        title: 'Error!',
                        text: 'An error occurred while updating. Please try again.'
                    });
                }
            });
        }
    });


    // Submit cancel form
    $('#cancelOrderForm').on('submit', function (e) {
        e.preventDefault();

        const formData = new FormData(this);

        Swal.fire({
            title: 'Are you sure?',
            text: "This order will be cancelled permanently!",
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'Yes, cancel it!',
            cancelButtonText: 'No, keep it'
        }).then((result) => {
            if (result.isConfirmed) {
                $.ajax({
                    url: '{{ route("order.cancel") }}',
                    type: 'POST',
                    data: formData,
                    processData: false,
                    contentType: false,
                    success: function (res) {
                        $('#cancelOrderModal').modal('hide');
                        toastr[res.notification.type](res.notification.message);
                        refreshDatatable('tblOrderList');
                    },
                    error: function () {
                        toastr.error('Failed to cancel order.');
                    }
                });
            }
        });
    });

    // ---------------- CLEAR FILTERS ----------------
    $("#clearFilters").click(function () {
        startdate = "";
        enddate = "";
        selectedInvoiceStatus = "";
        selectedStatus = "";

        $("#btnDate span").html("All Orders");
        $("#ddlInvoiceStatus").val("");
        $("#statusFilter").val("");

        table.ajax.reload();
    });

    // ---------------- STATUS UPDATE ----------------
    $(document).on("change", ".verify-status", function () {
        var data = table.row($(this).closest("tr")).data();
        var selectedValue = $(this).val();
        if (!selectedValue) return;
        updateVerifyStatus(selectedValue, data);
    });

    $(document).on("change", ".order-status", function () {
        var data = table.row($(this).closest("tr")).data();
        var selectedValue = $(this).val();
        if (!selectedValue) return;
        updateOrderStatus(selectedValue, data);
    });

    function updateVerifyStatus(status, data) {
        // Display SweetAlert confirmation dialog
        Swal.fire({
            title: "Are you sure?",
            text: "You are about to update verification status to '" +
                status +
                "'.",
            icon: "warning",
            showCancelButton: true,
            confirmButtonColor: "#3085d6",
            cancelButtonColor: "#d33",
            confirmButtonText: "Yes, update it!",
            width: "20%",
        }).then((result) => {
            if (result.isConfirmed) {
                // If user confirms, proceed with AJAX request
                $.ajax({
                    type: "GET",
                    url: "/verification-status-update/" + data.id,
                    data: {
                        status: status
                    },
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
                        // Keep page + scroll (do not jump to top / first 15 rows)
                        refreshDatatable("tblOrderList");
                    },
                });
            }
        });
    }

    function updateOrderStatus(status, data) {
        // Display SweetAlert for confirmation
        Swal.fire({
            title: "Are you sure?",
            text: "You are about to update the order status. This action cannot be undone!",
            icon: "warning",
            showCancelButton: true,
            confirmButtonColor: "#3085d6",
            cancelButtonColor: "#d33",
            confirmButtonText: "Yes, update it!",
            width: "20%",
        }).then((result) => {
            if (result.isConfirmed) {
                // If confirmed, proceed with the AJAX request
                $.ajax({
                    type: "GET",
                    url: "/order-status-update/" + data.id,
                    data: {
                        status: status
                    },
                    dataType: "json",
                    success: function (data) {
                        if (data.notification.type == "success") {
                            toastr.success(data.notification.message);
                        } else {
                            toastr.error(data.notification.message);
                        }
                        refreshDatatable("tblOrderList");
                    },
                });
            }
        });
    }

    $(document).on('click', '#approvePayoutBtn', function () {

        const $btn = $(this);
        const form = document.getElementById('approvePayoutForm');
        const $cancelBtn = $('#approvePayoutForm').find('.btn-reset');
        const transactionId = ($('#transaction_id').val() || '').trim();
        const payoutAmount = ($('#payout_amount').text() || '').trim();
        const orderId = ($('#hdOrderId').val() || '').trim();
    
        if ($btn.prop('disabled')) return;

        if (!transactionId) {
            toastr.error('Transaction ID is required');
            return;
        }
    
        Swal.fire({
            title: 'Confirm payout?',
            html: `Order #${orderId}<br>Payout Amount: <b>${payoutAmount}</b><br>Transaction ID: <b>${transactionId}</b>`,
            icon: 'question',
            showCancelButton: true,
            confirmButtonText: 'Yes, submit payout',
            cancelButtonText: 'Cancel',
            width: "24%",
        }).then((result) => {
            if (!result.isConfirmed) return;

            $btn.prop('disabled', true).text('Submitting...');
            $cancelBtn.prop('disabled', true);

            const formData = new FormData(form);

            $.ajax({
                url: '/approve-payout',
                type: 'POST',
                data: formData,
                processData: false,
                contentType: false,
                headers: {
                    'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
                },
                success: function (res) {
                    if (res.status) {
                        $('#modalCenter').modal('hide');
                        form.reset();
                        toastr.success(res.message);
                        refreshDatatable('tblOrderList');
                    } else {
                        toastr.error(res.message || 'Failed');
                    }
                },
                error: function () {
                    toastr.error('Payout failed');
                },
                complete: function () {
                    $btn.prop('disabled', false).text('Submit');
                    $cancelBtn.prop('disabled', false);
                }
            });
        });
    });

    $(document).on('click', '.payout-note-chip', function () {
        if (this.id === 'clearPayoutNote') {
            $('#payout_notes').val('').trigger('focus');
            return;
        }
        const note = ($(this).data('note') || '').toString();
        if (!note) return;
        const $notes = $('#payout_notes');
        const existing = ($notes.val() || '').trim();
        if (!existing) {
            $notes.val(note);
            $notes.trigger('focus');
            return;
        }
        if (existing.includes(note)) {
            $notes.trigger('focus');
            return;
        }
        $notes.val(`${existing} | ${note}`);
        $notes.trigger('focus');
    });

    $(document).on('input', '#transaction_id', function () {
        const normalized = ($(this).val() || '')
            .replace(/\s+/g, '')
            .toUpperCase();
        $(this).val(normalized);
    });

    $(document).on('change', '.cancel-reason', function () {
        if ($(this).val().toLowerCase() === 'other') {
            $('#otherReasonDiv').removeClass('d-none');
        } else {
            $('#otherReasonDiv').addClass('d-none');
            $('#otherReason').val('');
        }
    });

    $(document).on('click', '#cancelOrderBtn', function () {

        const $btn = $(this);
        const form = document.getElementById('cancelOrderForm');
        const formData = new FormData(form);
    
        if (!formData.get('cancelReason')) {
            toastr.error('Please select a cancel reason');
            return;
        }
    
        if (
            formData.get('cancelReason').toLowerCase() === 'other' &&
            !formData.get('otherReason')
        ) {
            toastr.error('Please enter other reason');
            return;
        }
    
        if ($btn.prop('disabled')) return;
        $btn.prop('disabled', true);
    
        $.ajax({
            url: '/order-cancel',
            type: 'POST',
            data: formData,
            processData: false,
            contentType: false,
            headers: {
                'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
            },
            success: function (res) {
                if (res.status) {
                    var scrollY = $(window).scrollTop();
                    var scrollX = $(window).scrollLeft();
                    $('#cancelReasonsModal')
                        .one('hidden.bs.modal', function () {
                            $(window).scrollTop(scrollY).scrollLeft(scrollX);
                            refreshDatatable('tblOrderList');
                        })
                        .modal('hide');
                    toastr.success(res.message);
                } else {
                    toastr.error(res.message || 'Cancel failed');
                }
            },
            error: function () {
                toastr.error('Something went wrong');
            },
            complete: function () {
                $btn.prop('disabled', false);
            }
        });
    });
});


function copyPayoutText(text) {
    const value = String(text || "").trim();
    if (!value || value === "-") {
        toastr.error("Nothing to copy");
        return;
    }
    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(value).then(function () {
            toastr.success("Copied");
        }).catch(function () {
            toastr.error("Copy failed");
        });
        return;
    }
    toastr.error("Copy failed");
}

$(document).on("click", "[data-copy-target]", function () {
    const id = $(this).attr("data-copy-target");
    const el = document.getElementById(id);
    if (!el) return;
    copyPayoutText(el.value || el.textContent);
});

function openModel(orderId, payout_amount, tds_amount, type, encodedModel) {
    document.getElementById("hdOrderId").value = orderId;
    const decodedModel = encodedModel ? decodeURIComponent(encodedModel) : "";
    $("#payout_user_name").text("-");
    $("#payout_order_number").text("-");
    $("#payout_order_model").text(decodedModel || "-");
    $("#transaction_div").show();
    $("#bank_details_button").show();
    $("#transaction_id").prop("readonly", false);
    $("#payout_notes").prop("readonly", false);
    $("#transaction_id").val('');
    $("#payout_notes").val('');

    $.ajax({
        url: "/get-bank-data",
        type: "GET",
        data: {
            id: orderId,
        },
        success: function (response) {
            const orderModel = response.order_list?.order_deal_name || response.order_list?.deal_name || decodedModel || '-';
            $("#payout_order_model").text(orderModel);
            $("#payout_user_name").text(response.customer?.display_name || "-");
            $("#payout_order_number").text(response.order_list?.order_number || "-");
            $("#bank_name").val(response.customer.bank_name ?? "");
            $("#payee_name").val(response.customer.bank_full_name ?? "");
            $("#account_number").val(
                response.customer.bank_account_number ?? ""
            );
            $("#ifsc").val(response.customer.bank_ifsc ?? "");
            $("#upi").val(response.customer.upi_address ?? "");
            if(tds_amount && tds_amount > 0){
                $("#payout_amount").text(payout_amount - tds_amount ?? "0");
            }else{
                $("#payout_amount").text(payout_amount ?? "0");
            }
            if (response.order_list.transaction_id && type === 'confirmed') {
                $("#transaction_id").prop("readonly", true);
                $("#payout_notes").prop("readonly", true);
                $("#transaction_div").hide();
                $("#bank_details_button").hide();
                $("#transaction_id").val(response.order_list.transaction_id);
                $("#payout_notes").val(response.order_list.payout_notes);
            }
            $("#modalCenter").modal("show");
        },
        error: function (xhr, status, error) {
            console.error(xhr.responseText);
        },
    });
}

function openCancelModal(orderId) {
    $('#hdOrderCancelId').val(orderId);
    $('#cancelOrderForm')[0].reset();
    $('#otherReasonDiv').addClass('d-none');
    $('#cancelReasonsModal').modal('show');
}
