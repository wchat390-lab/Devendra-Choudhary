<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Patel Mobile - Billing App</title>
    <style>
        * { box-sizing: border-box; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        body { background-color: #f4f6f9; margin: 0; padding: 15px; color: #333; }
        .container { max-width: 650px; margin: 0 auto; }
        .card { background: #fff; padding: 20px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.08); margin-bottom: 20px; }
        h2 { margin-top: 0; text-align: center; color: #1a252f; font-size: 20px; }
        
        /* Controls */
        .file-input-wrapper { text-align: center; margin-bottom: 15px; }
        input[type="file"] { display: none; }
        .btn { display: inline-block; padding: 10px 18px; background-color: #007bff; color: white; border: none; border-radius: 6px; font-size: 14px; font-weight: 600; cursor: pointer; text-align: center; }
        .btn:hover { background-color: #0056b3; }
        .btn-success { background-color: #28a745; }
        .btn-success:hover { background-color: #218838; }
        .btn-add { background-color: #17a2b8; margin-top: 10px; }
        .btn-add:hover { background-color: #138496; }
        
        .status-msg { text-align: center; font-style: italic; color: #6c757d; font-size: 14px; margin-top: 8px; }

        /* Invoice Layout */
        .invoice-box { background: #fff; padding: 25px; border: 1px solid #e2e8f0; border-radius: 8px; }
        .header { text-align: center; border-bottom: 2px solid #007bff; padding-bottom: 12px; margin-bottom: 15px; }
        .shop-name { font-size: 24px; font-weight: bold; color: #007bff; margin: 0; text-transform: uppercase; }
        .shop-sub { font-size: 13px; color: #555; margin: 3px 0; font-weight: 600; }
        .shop-address { font-size: 12px; color: #666; margin: 3px 0; }
        .shop-contacts { font-size: 12px; color: #333; font-weight: bold; margin-top: 4px; }
        
        .invoice-title-bar { display: flex; justify-content: space-between; align-items: center; margin-top: 15px; margin-bottom: 10px; }
        .invoice-title { font-size: 18px; font-weight: bold; color: #333; margin: 0; }
        .invoice-date { font-size: 13px; color: #555; }

        /* Table */
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { border: 1px solid #dee2e6; padding: 10px; text-align: left; font-size: 14px; }
        th { background-color: #f8f9fa; font-weight: 600; color: #495057; }
        td input { width: 100%; border: none; background: transparent; font-size: 14px; outline: none; }
        td.num-col input { text-align: right; }
        .action-col { text-align: center; width: 40px; }
        .delete-btn { color: #dc3545; cursor: pointer; font-weight: bold; font-size: 16px; border: none; background: none; }

        /* Total Section */
        .total-section { margin-top: 20px; text-align: right; font-size: 18px; font-weight: bold; color: #1a252f; border-top: 2px solid #333; padding-top: 10px; }
        .actions-bar { text-align: center; margin-top: 20px; }
    </style>

    <!-- Tesseract.js for OCR -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/tesseract.js/4.1.1/tesseract.min.js"></script>
    <!-- html2pdf.js for PDF Download -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
</head>
<body>

<div class="container">
    
    <!-- Upload Section -->
    <div class="card">
        <h2>Patel Mobile - Invoice Generator</h2>
        <div class="file-input-wrapper">
            <label for="cameraInput" class="btn">📸 Scan Bill / Select Image</label>
            <input type="file" id="cameraInput" accept="image/*">
            <div id="status" class="status-msg">Upload a rough bill image or add items manually below.</div>
        </div>
    </div>

    <!-- Printable Invoice Box -->
    <div class="invoice-box" id="invoiceContent">
        <div class="header">
            <div class="shop-name">PATEL MOBILE</div>
            <div class="shop-sub">Mobile Accessories & Spare Parts</div>
            <div class="shop-address">Shop No. 8, Opp KT Nagar, Dream House, Phase - 1, Sai Nagar, Vasai West, Palghar - 401 202</div>
            <div class="shop-contacts">Umaramji Patel: 91727 74626 | Jagdish Patel: 95183 45140</div>
        </div>

        <div class="invoice-title-bar">
            <div class="invoice-title">INVOICE</div>
            <div class="invoice-date">Date: <span id="billDate"></span></div>
        </div>

        <table id="billingTable">
            <thead>
                <tr>
                    <th>Item Description</th>
                    <th style="width: 80px; text-align: center;">Qty</th>
                    <th style="width: 100px; text-align: right;">Price (₹)</th>
                    <th style="width: 110px; text-align: right;">Total (₹)</th>
                    <th class="action-col hide-pdf">✕</th>
                </tr>
            </thead>
            <tbody id="tableBody">
                <!-- Rows inserted dynamically -->
            </tbody>
        </table>

        <button class="btn btn-add hide-pdf" onclick="addNewRow()">+ Add Item Manually</button>

        <div class="total-section">
            Grand Total: ₹<span id="grandTotal">0.00</span>
        </div>
    </div>

    <!-- Download PDF Control -->
    <div class="actions-bar">
        <button class="btn btn-success" id="downloadPdfBtn" onclick="downloadPDF()">📄 Download PDF Invoice</button>
    </div>

</div>

<script>
    // Set Current Date
    document.getElementById('billDate').textContent = new Date().toLocaleDateString('en-IN');

    // Automatically Calculate Grand Total
    function calculateTotals() {
        const rows = document.querySelectorAll('#tableBody tr');
        let grandTotal = 0;

        rows.forEach(row => {
            const qtyInput = row.querySelector('.qty-input');
            const priceInput = row.querySelector('.price-input');
            const totalCell = row.querySelector('.total-cell');

            if (qtyInput && priceInput && totalCell) {
                const qty = parseFloat(qtyInput.value) || 0;
                const price = parseFloat(priceInput.value) || 0;
                const rowTotal = qty * price;

                totalCell.textContent = rowTotal.toFixed(2);
                grandTotal += rowTotal;
            }
        });

        document.getElementById('grandTotal').textContent = grandTotal.toFixed(2);
    }

    // Add Row Function
    function addNewRow(itemName = '', qty = 1, price = 0) {
        const tbody = document.getElementById('tableBody');
        const row = document.createElement('tr');

        row.innerHTML = `
            <td><input type="text" class="item-input" value="${itemName}" placeholder="Enter Item Name" oninput="calculateTotals()"></td>
            <td class="num-col"><input type="number" class="qty-input" value="${qty}" min="1" oninput="calculateTotals()"></td>
            <td class="num-col"><input type="number" class="price-input" value="${price}" min="0" step="0.01" oninput="calculateTotals()"></td>
            <td class="total-cell" style="text-align: right; font-weight: 600;">0.00</td>
            <td class="action-col hide-pdf"><button class="delete-btn" onclick="removeRow(this)">×</button></td>
        `;

        tbody.appendChild(row);
        calculateTotals();
    }

    // Delete Row
    function removeRow(btn) {
        const row = btn.closest('tr');
        row.remove();
        calculateTotals();
    }

    // Initialize with 3 empty rows
    addNewRow();
    addNewRow();
    addNewRow();

    // OCR Logic using Tesseract.js
    document.getElementById('cameraInput').addEventListener('change', function(e) {
        const file = e.target.files[0];
        if (!file) return;

        const status = document.getElementById('status');
        status.textContent = "Scanning bill image...";

        const reader = new FileReader();
        reader.onload = function(event) {
            Tesseract.recognize(
                event.target.result,
                'eng',
                { logger: m => {
                    if (m.status === 'recognizing text') {
                        status.textContent = `Scanning: ${Math.round(m.progress * 100)}%`;
                    }
                }}
            ).then(result => {
                status.textContent = "Scan complete! Items added below.";
                const lines = result.data.text.split('\n').filter(line => line.trim() !== '');

                const tbody = document.getElementById('tableBody');
                tbody.innerHTML = ''; // Clear empty rows

                lines.forEach(line => {
                    const numbers = line.match(/\d+(\.\d+)?/g);
                    let price = 0;
                    if (numbers && numbers.length > 0) {
                        price = parseFloat(numbers[numbers.length - 1]);
                    }
                    if (price > 0 || line.length > 2) {
                        addNewRow(line.trim(), 1, price);
                    }
                });

                if (tbody.children.length === 0) {
                    addNewRow();
                }

                calculateTotals();
            }).catch(err => {
                console.error(err);
                status.textContent = "Error reading image. Please add items manually.";
            });
        };
        reader.readAsDataURL(file);
    });

    // Generate Clean PDF
    function downloadPDF() {
        // Hide elements not needed in PDF
        const hideElements = document.querySelectorAll('.hide-pdf');
        hideElements.forEach(el => el.style.display = 'none');

        const element = document.getElementById('invoiceContent');
        const opt = {
            margin:       8,
            filename:     'Patel_Mobile_Invoice.pdf',
            image:        { type: 'jpeg', quality: 0.98 },
            html2canvas:  { scale: 2 },
            jsPDF:        { unit: 'mm', format: 'a4', orientation: 'portrait' }
        };

        html2pdf().set(opt).from(element).save().then(() => {
            // Restore hidden elements after PDF generation
            hideElements.forEach(el => el.style.display = '');
        });
    }
</script>

</body>
</html>
