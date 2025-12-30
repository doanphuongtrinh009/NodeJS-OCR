# Invoice JSON Schema - Mô tả cấu trúc dữ liệu hóa đơn

## 📋 Tổng quan

Tài liệu này mô tả chi tiết cấu trúc JSON trả về từ các functions trong `pkg_ai`, phục vụ việc mapping và insert dữ liệu vào hệ thống Oracle ERP.

**Tuân thủ**: Thông tư 78/2021/TT-BTC về hóa đơn điện tử Việt Nam

---

## 📊 Cấu trúc JSON tổng quan

```json
{
  "general_info": {}, // Thông tin chung hóa đơn
  "seller_info": {}, // Thông tin người bán
  "buyer_info": {}, // Thông tin người mua
  "items": [], // Danh sách hàng hóa/dịch vụ
  "financial_summary": {}, // Tổng hợp tài chính
  "digital_signature": {} // Chữ ký số (nullable)
}
```

---

## 1️⃣ GENERAL_INFO - Thông tin chung hóa đơn

| Field                     | Type   | Oracle Column                       | Mô tả                           | Ví dụ                                  |
| ------------------------- | ------ | ----------------------------------- | ------------------------------- | -------------------------------------- |
| `template_code`           | String | `TEMPLATE_CODE VARCHAR2(50)`        | Mẫu số hóa đơn                  | `"01GTKT0/001"`                        |
| `invoice_series`          | String | `INVOICE_SERIES VARCHAR2(20)`       | Ký hiệu hóa đơn                 | `"AA/23E"`                             |
| `invoice_number`          | String | `INVOICE_NUMBER VARCHAR2(20)`       | Số hóa đơn (giữ số 0 đầu)       | `"0000123"`                            |
| `invoice_date`            | String | `INVOICE_DATE DATE`                 | Ngày lập hóa đơn (YYYY-MM-DD)   | `"2025-12-30"`                         |
| `invoice_type`            | String | `INVOICE_TYPE VARCHAR2(50)`         | Loại hóa đơn                    | `"VAT"`, `"Sale"`, `"Export"`          |
| `lookup_code`             | String | `LOOKUP_CODE VARCHAR2(50)`          | Mã tra cứu từ CQT               | `"30CD4755.26112025"`                  |
| `tax_authority_code`      | String | `TAX_AUTHORITY_CODE VARCHAR2(50)`   | Mã cơ quan thuế                 | `"M1-25-LPQZG"`                        |
| `invoice_status`          | String | `INVOICE_STATUS VARCHAR2(20)`       | Trạng thái hóa đơn              | `"valid"`, `"cancelled"`, `"replaced"` |
| `original_invoice_number` | String | `ORIGINAL_INV_NUMBER VARCHAR2(20)`  | Số HĐ gốc (điều chỉnh/thay thế) | `"0000100"`                            |
| `original_invoice_date`   | String | `ORIGINAL_INV_DATE DATE`            | Ngày HĐ gốc                     | `"2025-12-01"`                         |
| `adjustment_type`         | String | `ADJUSTMENT_TYPE VARCHAR2(20)`      | Loại điều chỉnh                 | `"replace"`, `"adjust"`, `"cancel"`    |
| `currency_code`           | String | `CURRENCY_CODE VARCHAR2(3)`         | Mã tiền tệ                      | `"VND"`, `"USD"`                       |
| `exchange_rate`           | Number | `EXCHANGE_RATE NUMBER(15,4)`        | Tỷ giá (mặc định 1 cho VND)     | `1`, `24500.5`                         |
| `payment_method`          | String | `PAYMENT_METHOD VARCHAR2(50)`       | Hình thức thanh toán            | `"TM/CK"`, `"TM"`, `"CK"`              |
| `payment_status`          | String | `PAYMENT_STATUS VARCHAR2(20)`       | Trạng thái thanh toán           | `"paid"`, `"unpaid"`, `"partial"`      |
| `payment_term`            | String | `PAYMENT_TERM VARCHAR2(50)`         | Điều khoản thanh toán           | `"30 days"`, `"COD"`                   |
| `contract_number`         | String | `CONTRACT_NUMBER VARCHAR2(50)`      | Số hợp đồng                     | `"HD-2025-001"`                        |
| `purchase_order_number`   | String | `PO_NUMBER VARCHAR2(50)`            | Số đơn đặt hàng                 | `"PO-2025-001"`                        |
| `delivery_note_number`    | String | `DELIVERY_NOTE_NUMBER VARCHAR2(50)` | Số phiếu xuất kho               | `"PXK-001"`                            |
| `invoice_version`         | String | `INVOICE_VERSION VARCHAR2(20)`      | Phiên bản hóa đơn               | `"1.0"`                                |
| `notes`                   | String | `NOTES VARCHAR2(500)`               | Ghi chú chung                   | `"Giao hàng tận nơi"`                  |

**SQL Insert Example:**

```sql
INSERT INTO AP_INVOICES (
    TEMPLATE_CODE, INVOICE_SERIES, INVOICE_NUMBER, INVOICE_DATE,
    CURRENCY_CODE, PAYMENT_METHOD
) VALUES (
    :template_code, :invoice_series, :invoice_number,
    TO_DATE(:invoice_date, 'YYYY-MM-DD'), :currency_code, :payment_method
);
```

---

## 2️⃣ SELLER_INFO - Thông tin người bán

| Field                  | Type   | Oracle Column                      | Mô tả                           | Ví dụ                          |
| ---------------------- | ------ | ---------------------------------- | ------------------------------- | ------------------------------ |
| `name`                 | String | `SELLER_NAME VARCHAR2(500)`        | Tên đơn vị bán hàng             | `"CÔNG TY TNHH ABC"`           |
| `tax_code`             | String | `SELLER_TAX_CODE VARCHAR2(20)`     | Mã số thuế (không khoảng trắng) | `"0123456789"`                 |
| `address`              | String | `SELLER_ADDRESS VARCHAR2(500)`     | Địa chỉ đầy đủ                  | `"123 Nguyễn Huệ, Q1, TP.HCM"` |
| `phone`                | String | `SELLER_PHONE VARCHAR2(50)`        | Số điện thoại                   | `"028-1234-5678"`              |
| `email`                | String | `SELLER_EMAIL VARCHAR2(100)`       | Email                           | `"info@abc.com"`               |
| `website`              | String | `SELLER_WEBSITE VARCHAR2(200)`     | Website                         | `"https://abc.com"`            |
| `fax`                  | String | `SELLER_FAX VARCHAR2(50)`          | Số fax                          | `"028-1234-5679"`              |
| `bank_account`         | String | `SELLER_BANK_ACC VARCHAR2(50)`     | Số tài khoản ngân hàng          | `"123456789012"`               |
| `bank_name`            | String | `SELLER_BANK_NAME VARCHAR2(200)`   | Tên ngân hàng                   | `"Vietcombank"`                |
| `bank_branch`          | String | `SELLER_BANK_BRANCH VARCHAR2(200)` | Chi nhánh ngân hàng             | `"CN Hồ Chí Minh"`             |
| `legal_representative` | String | `SELLER_LEGAL_REP VARCHAR2(200)`   | Người đại diện pháp luật        | `"Nguyễn Văn A"`               |
| `position`             | String | `SELLER_POSITION VARCHAR2(100)`    | Chức vụ                         | `"Giám đốc"`                   |

---

## 3️⃣ BUYER_INFO - Thông tin người mua

| Field            | Type   | Oracle Column                    | Mô tả                           | Ví dụ                      |
| ---------------- | ------ | -------------------------------- | ------------------------------- | -------------------------- |
| `name`           | String | `BUYER_NAME VARCHAR2(200)`       | Tên cá nhân mua hàng            | `"Trần Văn B"`             |
| `company_name`   | String | `BUYER_COMPANY VARCHAR2(500)`    | Tên công ty mua hàng            | `"CÔNG TY XYZ"`            |
| `tax_code`       | String | `BUYER_TAX_CODE VARCHAR2(20)`    | Mã số thuế (không khoảng trắng) | `"9876543210"`             |
| `address`        | String | `BUYER_ADDRESS VARCHAR2(500)`    | Địa chỉ                         | `"456 Lê Lợi, Q1, TP.HCM"` |
| `phone`          | String | `BUYER_PHONE VARCHAR2(50)`       | Số điện thoại                   | `"0901234567"`             |
| `email`          | String | `BUYER_EMAIL VARCHAR2(100)`      | Email                           | `"buyer@xyz.com"`          |
| `bank_account`   | String | `BUYER_BANK_ACC VARCHAR2(50)`    | Số tài khoản (cho hoàn tiền)    | `"987654321098"`           |
| `bank_name`      | String | `BUYER_BANK_NAME VARCHAR2(200)`  | Tên ngân hàng                   | `"Techcombank"`            |
| `contact_person` | String | `BUYER_CONTACT VARCHAR2(200)`    | Người liên hệ                   | `"Lê Thị C"`               |
| `department`     | String | `BUYER_DEPARTMENT VARCHAR2(100)` | Phòng ban                       | `"Kế toán"`                |

---

## 4️⃣ ITEMS - Chi tiết hàng hóa/dịch vụ

**⚠️ Luôn là ARRAY [], không bao giờ là null**

| Field                   | Type   | Oracle Column                  | Mô tả                           | Ví dụ                           |
| ----------------------- | ------ | ------------------------------ | ------------------------------- | ------------------------------- |
| `line_number`           | Number | `LINE_NUMBER NUMBER(5)`        | Số thứ tự dòng                  | `1`, `2`, `3`                   |
| `item_code`             | String | `ITEM_CODE VARCHAR2(50)`       | Mã hàng hóa/SKU                 | `"SKU-001"`                     |
| `item_name`             | String | `ITEM_NAME VARCHAR2(500)`      | Tên hàng hóa/dịch vụ            | `"Laptop Dell XPS 15"`          |
| `item_description`      | String | `ITEM_DESC VARCHAR2(1000)`     | Mô tả chi tiết                  | `"Core i7, RAM 16GB"`           |
| `unit_name`             | String | `UNIT_NAME VARCHAR2(50)`       | Đơn vị tính                     | `"Cái"`, `"Hộp"`, `"Kg"`        |
| `quantity`              | Number | `QUANTITY NUMBER(15,4)`        | Số lượng                        | `2`, `1.5`                      |
| `unit_price`            | Number | `UNIT_PRICE NUMBER(18,2)`      | Đơn giá (số nguyên, không phẩy) | `15000000`                      |
| `total_amount_pre_tax`  | Number | `AMOUNT_PRE_TAX NUMBER(18,2)`  | Thành tiền trước thuế           | `30000000`                      |
| `discount_rate`         | Number | `DISCOUNT_RATE NUMBER(5,2)`    | % Chiết khấu                    | `5`, `10`                       |
| `discount_amount`       | Number | `DISCOUNT_AMT NUMBER(18,2)`    | Tiền chiết khấu                 | `1500000`                       |
| `vat_rate`              | Number | `VAT_RATE NUMBER(3)`           | Thuế suất VAT                   | `0`, `5`, `8`, `10`, `-1`, `-2` |
| `vat_amount`            | Number | `VAT_AMOUNT NUMBER(18,2)`      | Tiền thuế VAT                   | `3000000`                       |
| `total_amount_with_tax` | Number | `AMOUNT_WITH_TAX NUMBER(18,2)` | Thành tiền sau thuế             | `33000000`                      |
| `promotion`             | String | `PROMOTION VARCHAR2(200)`      | Khuyến mại                      | `"Tặng chuột không dây"`        |
| `warranty_period`       | String | `WARRANTY VARCHAR2(50)`        | Thời hạn bảo hành               | `"24 tháng"`                    |
| `origin`                | String | `ORIGIN VARCHAR2(100)`         | Xuất xứ                         | `"Việt Nam"`, `"Trung Quốc"`    |

### Quy tắc VAT Rate:

| Giá trị | Ý nghĩa                    |
| ------- | -------------------------- |
| `0`     | Thuế suất 0%               |
| `5`     | Thuế suất 5%               |
| `8`     | Thuế suất 8%               |
| `10`    | Thuế suất 10%              |
| `-1`    | Không chịu thuế (KCT)      |
| `-2`    | Không kê khai thuế (KKKNT) |
| `null`  | Không xác định             |

**SQL Insert Example:**

```sql
INSERT INTO AP_INVOICE_LINES (
    INVOICE_ID, LINE_NUMBER, ITEM_CODE, ITEM_NAME, UNIT_NAME,
    QUANTITY, UNIT_PRICE, AMOUNT_PRE_TAX, VAT_RATE, VAT_AMOUNT
) VALUES (
    :invoice_id, :line_number, :item_code, :item_name, :unit_name,
    :quantity, :unit_price, :total_amount_pre_tax, :vat_rate, :vat_amount
);
```

---

## 5️⃣ FINANCIAL_SUMMARY - Tổng hợp tài chính

| Field                   | Type   | Oracle Column                   | Mô tả                        | Ví dụ                     |
| ----------------------- | ------ | ------------------------------- | ---------------------------- | ------------------------- |
| `tax_breakdowns`        | Array  | -                               | Chi tiết theo từng thuế suất | (xem bên dưới)            |
| `total_amount_pre_tax`  | Number | `TOTAL_PRE_TAX NUMBER(18,2)`    | Tổng tiền trước thuế         | `30000000`                |
| `total_discount_amount` | Number | `TOTAL_DISCOUNT NUMBER(18,2)`   | Tổng chiết khấu              | `1000000`                 |
| `total_vat_amount`      | Number | `TOTAL_VAT NUMBER(18,2)`        | Tổng tiền thuế VAT           | `3000000`                 |
| `total_payment_amount`  | Number | `TOTAL_PAYMENT NUMBER(18,2)`    | Tổng cộng thanh toán         | `33000000`                |
| `amount_in_words`       | String | `AMOUNT_IN_WORDS VARCHAR2(500)` | Số tiền bằng chữ             | `"Ba mươi ba triệu đồng"` |
| `shipping_fee`          | Number | `SHIPPING_FEE NUMBER(18,2)`     | Phí vận chuyển               | `50000`                   |
| `insurance_fee`         | Number | `INSURANCE_FEE NUMBER(18,2)`    | Phí bảo hiểm                 | `0`                       |
| `other_fees`            | Number | `OTHER_FEES NUMBER(18,2)`       | Phí khác                     | `0`                       |
| `prepaid_amount`        | Number | `PREPAID_AMT NUMBER(18,2)`      | Đã thanh toán trước          | `10000000`                |
| `remaining_amount`      | Number | `REMAINING_AMT NUMBER(18,2)`    | Còn phải thanh toán          | `23000000`                |

### TAX_BREAKDOWNS (Chi tiết thuế):

```json
"tax_breakdowns": [
  {
    "vat_rate": 10,
    "taxable_amount": 25000000,
    "tax_amount": 2500000
  },
  {
    "vat_rate": 5,
    "taxable_amount": 5000000,
    "tax_amount": 250000
  }
]
```

---

## 6️⃣ DIGITAL_SIGNATURE - Chữ ký số

**⚠️ Có thể là `null` nếu không có thông tin chữ ký**

| Field           | Type   | Oracle Column                  | Mô tả                   | Ví dụ                         |
| --------------- | ------ | ------------------------------ | ----------------------- | ----------------------------- |
| `signer_name`   | String | `SIGNER_NAME VARCHAR2(200)`    | Tên người ký            | `"Nguyễn Văn A"`              |
| `signing_time`  | String | `SIGNING_TIME TIMESTAMP`       | Thời gian ký (ISO 8601) | `"2025-12-30T10:30:00+07:00"` |
| `serial_number` | String | `CERT_SERIAL VARCHAR2(100)`    | Serial chữ ký số        | `"7A3F2B1C..."`               |
| `authority`     | String | `CERT_AUTHORITY VARCHAR2(100)` | Tổ chức cấp chứng thư   | `"VNPT-CA"`, `"Viettel-CA"`   |
| `valid_from`    | String | `CERT_VALID_FROM DATE`         | Hiệu lực từ             | `"2024-01-01"`                |
| `valid_to`      | String | `CERT_VALID_TO DATE`           | Hiệu lực đến            | `"2026-12-31"`                |
| `hash_value`    | String | `HASH_VALUE VARCHAR2(200)`     | Mã băm                  | `"SHA256:ABC123..."`          |

---

## 🔄 Quy tắc chuyển đổi dữ liệu

### 1. Số tiền (Numbers)

```
Đầu vào (Hóa đơn VN)     →    Đầu ra (JSON)
"1.000.000"               →    1000000
"10,5"                    →    10.5
"1.234.567,89"            →    1234567.89
```

### 2. Ngày tháng (Dates)

```
Đầu vào                   →    Đầu ra
"30/12/2025"              →    "2025-12-30"
"30-12-2025"              →    "2025-12-30"
"ngày 30 tháng 12 năm 2025" →  "2025-12-30"
```

### 3. Mã số thuế (Tax Code)

```
Đầu vào                   →    Đầu ra
"0123 456 789"            →    "0123456789"
"0102721191-001"          →    "0102721191-001" (giữ nguyên dấu -)
```

---

## 📝 PL/SQL Insert Template

```sql
DECLARE
    l_json      CLOB;
    l_general   JSON_OBJECT_T;
    l_seller    JSON_OBJECT_T;
    l_buyer     JSON_OBJECT_T;
    l_items     JSON_ARRAY_T;
    l_summary   JSON_OBJECT_T;
    l_inv_id    NUMBER;
BEGIN
    -- Gọi API lấy JSON
    l_json := pkg_ai.gemini_invoice_from_pdf('API_KEY', v_pdf_blob);

    -- Parse JSON
    l_general := JSON_OBJECT_T(l_json).get_Object('general_info');
    l_seller  := JSON_OBJECT_T(l_json).get_Object('seller_info');
    l_buyer   := JSON_OBJECT_T(l_json).get_Object('buyer_info');
    l_items   := JSON_OBJECT_T(l_json).get_Array('items');
    l_summary := JSON_OBJECT_T(l_json).get_Object('financial_summary');

    -- Insert Header
    INSERT INTO AP_INVOICES (
        INVOICE_NUMBER, INVOICE_DATE, SELLER_NAME, SELLER_TAX_CODE,
        BUYER_NAME, BUYER_TAX_CODE, TOTAL_AMOUNT, CURRENCY_CODE
    ) VALUES (
        l_general.get_String('invoice_number'),
        TO_DATE(l_general.get_String('invoice_date'), 'YYYY-MM-DD'),
        l_seller.get_String('name'),
        l_seller.get_String('tax_code'),
        NVL(l_buyer.get_String('company_name'), l_buyer.get_String('name')),
        l_buyer.get_String('tax_code'),
        l_summary.get_Number('total_payment_amount'),
        l_general.get_String('currency_code')
    ) RETURNING INVOICE_ID INTO l_inv_id;

    -- Insert Lines
    FOR i IN 0 .. l_items.get_Size - 1 LOOP
        DECLARE
            l_item JSON_OBJECT_T := TREAT(l_items.get(i) AS JSON_OBJECT_T);
        BEGIN
            INSERT INTO AP_INVOICE_LINES (
                INVOICE_ID, LINE_NUMBER, ITEM_NAME, QUANTITY,
                UNIT_PRICE, AMOUNT_PRE_TAX, VAT_RATE, VAT_AMOUNT
            ) VALUES (
                l_inv_id,
                l_item.get_Number('line_number'),
                l_item.get_String('item_name'),
                l_item.get_Number('quantity'),
                l_item.get_Number('unit_price'),
                l_item.get_Number('total_amount_pre_tax'),
                l_item.get_Number('vat_rate'),
                l_item.get_Number('vat_amount')
            );
        END;
    END LOOP;

    COMMIT;
END;
/
```

---

## 📊 Mapping với Oracle ERP Tables

| JSON Object         | Oracle Table                    | Mô tả              |
| ------------------- | ------------------------------- | ------------------ |
| `general_info`      | `AP_INVOICES`                   | Header hóa đơn     |
| `seller_info`       | `AP_INVOICES` hoặc `PO_VENDORS` | Thông tin NCC      |
| `buyer_info`        | `AP_INVOICES` hoặc `HZ_PARTIES` | Thông tin KH       |
| `items`             | `AP_INVOICE_LINES`              | Chi tiết dòng      |
| `financial_summary` | `AP_INVOICES`                   | Tổng hợp tài chính |
| `digital_signature` | `AP_INVOICE_SIGNATURES`         | Chữ ký số          |

---

## ✅ Validation Rules

1. **invoice_number**: Bắt buộc, không null
2. **invoice_date**: Bắt buộc, định dạng YYYY-MM-DD
3. **seller_tax_code**: Bắt buộc cho hóa đơn VAT
4. **items**: Luôn là array, có thể rỗng []
5. **total_payment_amount**: Bắt buộc
6. **vat_rate**: Phải nằm trong {0, 5, 8, 10, -1, -2, null}

---

**Document Version**: 1.0  
**Last Updated**: 2025-12-30  
**Author**: PKG_AI - Oracle PL/SQL AI Package
