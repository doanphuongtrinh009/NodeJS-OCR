# PKG_AI - Oracle PL/SQL AI Invoice Processing Package

## 📋 Tổng quan

Package PL/SQL tích hợp **OpenAI GPT** và **Google Gemini** để trích xuất dữ liệu hóa đơn điện tử Việt Nam theo chuẩn **Thông tư 78/2021/TT-BTC** cho Oracle ERP.

### ✅ Tính năng

- **Chat AI**: GPT & Gemini chatbot
- **OCR từ Text**: Trích xuất hóa đơn từ văn bản
- **OCR từ Image**: Nhận dạng hóa đơn từ ảnh (PNG, JPG, WEBP)
- **OCR từ PDF**: Đọc hóa đơn PDF (CTX_DOC + Gemini Vision)
- **Parse XML**: Phân tích hóa đơn XML điện tử
- **Voice-to-Invoice**: Chuyển đổi giọng nói thành hóa đơn

## 🏗️ Cấu trúc Files

```
oracle_plsql/
├── pkg_ai.sql           # Package chính (Spec + Body)
├── test_pkg_ai.sql      # Test cases đầy đủ
└── README.md            # File này
```

## 🚀 Cài đặt

### Bước 1: Grant Network ACL (DBA)

```sql
-- Cho phép kết nối đến OpenAI và Google APIs
BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host => 'api.openai.com',
        ace  => xs$ace_type(privilege_list => xs$name_list('connect', 'resolve'),
                           principal_name => 'YOUR_SCHEMA',
                           principal_type => xs_acl.ptype_db));

    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host => 'generativelanguage.googleapis.com',
        ace  => xs$ace_type(privilege_list => xs$name_list('connect', 'resolve'),
                           principal_name => 'YOUR_SCHEMA',
                           principal_type => xs_acl.ptype_db));
END;
/
```

### Bước 2: Setup Oracle Wallet

```bash
# Tạo wallet cho HTTPS
orapki wallet create -wallet /u01/https/wallet -pwd YourPassword -auto_login

# Import certificates (nếu cần)
orapki wallet add -wallet /u01/https/wallet -trusted_cert -cert DigiCert.pem -pwd YourPassword
```

### Bước 3: Cấu hình Wallet Path trong Package

Sửa dòng 62-63 trong `pkg_ai.sql`:

```sql
g_wallet_path VARCHAR2(500) := 'file:/u01/https/getCert/wallet';
g_wallet_pwd  VARCHAR2(100) := 'YourWalletPassword';
```

### Bước 4: Compile Package

```sql
@pkg_ai.sql
```

## 📖 API Reference

### GPT Functions

| Function                    | Mô tả                      | Input       |
| --------------------------- | -------------------------- | ----------- |
| `gpt_chat`                  | Chat với GPT               | Text prompt |
| `gpt_invoice_from_text`     | OCR từ text                | CLOB text   |
| `gpt_invoice_from_image`    | OCR từ ảnh                 | BLOB image  |
| `gpt_invoice_from_pdf`      | OCR từ PDF                 | BLOB PDF    |
| `gpt_invoice_from_xml`      | Parse XML                  | CLOB XML    |
| `gpt_invoice_from_xml_blob` | Parse XML từ BLOB          | BLOB XML    |
| `gpt_invoice_from_audio`    | Voice-to-Invoice (Whisper) | BLOB audio  |

### Gemini Functions

| Function                       | Mô tả               | Input       |
| ------------------------------ | ------------------- | ----------- |
| `gemini_chat`                  | Chat với Gemini     | Text prompt |
| `gemini_invoice_from_text`     | OCR từ text         | CLOB text   |
| `gemini_invoice_from_image`    | OCR từ ảnh (Vision) | BLOB image  |
| `gemini_invoice_from_pdf`      | OCR từ PDF (Vision) | BLOB PDF    |
| `gemini_invoice_from_xml`      | Parse XML           | CLOB XML    |
| `gemini_invoice_from_xml_blob` | Parse XML từ BLOB   | BLOB XML    |
| `gemini_invoice_from_audio`    | Voice-to-Invoice    | BLOB audio  |

### Utility Functions

| Function         | Mô tả                           |
| ---------------- | ------------------------------- |
| `blob_to_clob`   | Convert BLOB → CLOB             |
| `blob_to_base64` | Convert BLOB → Base64           |
| `clean_json`     | Remove markdown wrapper từ JSON |

## 💻 Ví dụ sử dụng

### Chat với GPT

```sql
DECLARE
    v_result CLOB;
BEGIN
    v_result := pkg_ai.gpt_chat(
        p_api_key => 'sk-your-openai-key',
        p_prompt  => '1+1=?'
    );
    DBMS_OUTPUT.PUT_LINE(v_result);
END;
/
```

### OCR hóa đơn từ PDF (Gemini - Khuyến nghị)

```sql
DECLARE
    v_pdf    BLOB;
    v_result CLOB;
BEGIN
    SELECT content INTO v_pdf FROM attachments WHERE att_id = 771;

    v_result := pkg_ai.gemini_invoice_from_pdf(
        p_api_key => 'AIzaSy...your-gemini-key',
        p_blob    => v_pdf
    );
    DBMS_OUTPUT.PUT_LINE(v_result);
END;
/
```

### OCR hóa đơn từ Image (GPT Vision)

```sql
DECLARE
    v_image  BLOB;
    v_result CLOB;
BEGIN
    SELECT content INTO v_image FROM attachments WHERE att_id = 770;

    v_result := pkg_ai.gpt_invoice_from_image(
        p_api_key   => 'sk-your-openai-key',
        p_blob      => v_image,
        p_mime_type => 'image/png'
    );
    DBMS_OUTPUT.PUT_LINE(v_result);
END;
/
```

### Voice-to-Invoice (Gemini - Miễn phí)

```sql
DECLARE
    v_audio  BLOB;
    v_result CLOB;
BEGIN
    SELECT content INTO v_audio FROM attachments WHERE att_id = 774;

    v_result := pkg_ai.gemini_invoice_from_audio(
        p_api_key    => 'AIzaSy...your-gemini-key',
        p_audio_blob => v_audio,
        p_audio_type => 'audio/webm'
    );
    DBMS_OUTPUT.PUT_LINE(v_result);
END;
/
```

## 📊 JSON Output Schema (Thông tư 78/2021)

```json
{
  "general_info": {
    "template_code": "01GTKT0/001",
    "invoice_series": "AA/23E",
    "invoice_number": "0000123",
    "invoice_date": "2025-12-30",
    "currency_code": "VND",
    "payment_method": "TM/CK"
  },
  "seller_info": {
    "name": "Công ty ABC",
    "tax_code": "0123456789",
    "address": "123 Đường XYZ, TP.HCM",
    "phone": "028-1234-5678",
    "bank_account": "123456789",
    "bank_name": "Vietcombank"
  },
  "buyer_info": {
    "name": "Công ty XYZ",
    "tax_code": "9876543210",
    "address": "456 Đường ABC, Hà Nội"
  },
  "items": [
    {
      "line_number": 1,
      "item_name": "Laptop Dell",
      "quantity": 2,
      "unit_price": 15000000,
      "total_amount_pre_tax": 30000000,
      "vat_rate": 10,
      "vat_amount": 3000000
    }
  ],
  "financial_summary": {
    "total_amount_pre_tax": 30000000,
    "total_vat_amount": 3000000,
    "total_payment_amount": 33000000,
    "amount_in_words": "Ba mươi ba triệu đồng"
  },
  "digital_signature": null
}
```

## 🧪 Test Results

| Test | Function                       | Status               |
| ---- | ------------------------------ | -------------------- |
| 1A   | `gpt_chat`                     | ✅ PASS              |
| 2A   | `gpt_invoice_from_text`        | ✅ PASS              |
| 3A   | `gpt_invoice_from_image`       | ✅ PASS              |
| 4A   | `gpt_invoice_from_pdf`         | ✅ PASS              |
| 5A   | `gpt_invoice_from_xml`         | ✅ PASS              |
| 5B   | `gpt_invoice_from_xml_blob`    | ✅ PASS              |
| 6A   | `gpt_invoice_from_audio`       | ⚠️ Cần OpenAI credit |
| 1B   | `gemini_chat`                  | ✅ PASS              |
| 2B   | `gemini_invoice_from_text`     | ✅ PASS              |
| 3B   | `gemini_invoice_from_image`    | ✅ PASS              |
| 4B   | `gemini_invoice_from_pdf`      | ✅ PASS              |
| 5C   | `gemini_invoice_from_xml`      | ✅ PASS              |
| 5D   | `gemini_invoice_from_xml_blob` | ✅ PASS              |
| 6B   | `gemini_invoice_from_audio`    | ✅ PASS              |
| U1   | `blob_to_clob`                 | ✅ PASS              |
| U2   | `blob_to_base64`               | ✅ PASS              |
| U3   | `clean_json`                   | ✅ PASS              |

**Pass Rate: 16/17 (94%)**

## 💰 Chi phí API

| API             | Model                 | Pricing                         |
| --------------- | --------------------- | ------------------------------- |
| **GPT**         | gpt-4o-mini           | $0.15/1M input, $0.60/1M output |
| **GPT Whisper** | whisper-1             | $0.006/minute                   |
| **Gemini**      | gemini-2.5-flash-lite | **FREE tier** (15 RPM)          |

👉 **Khuyến nghị**: Dùng **Gemini** cho PDF và Audio vì miễn phí!

## 🔑 Lấy API Keys

### OpenAI API Key

1. Đăng ký tại [platform.openai.com](https://platform.openai.com)
2. Settings → API Keys → Create new secret key

### Google Gemini API Key

1. Đăng ký tại [aistudio.google.com](https://aistudio.google.com)
2. Get API Key → Create API key

## ⚠️ Lưu ý

1. **Oracle Version**: Cần Oracle 12c+ (JSON functions)

2. **Oracle Text** (Optional): Để sử dụng CTX_DOC cho PDF:

   ```sql
   GRANT EXECUTE ON CTXSYS.CTX_DOC TO your_schema;
   GRANT EXECUTE ON CTXSYS.CTX_DDL TO your_schema;
   ```

3. **Firewall**: Cho phép kết nối đến:

   - `api.openai.com:443`
   - `generativelanguage.googleapis.com:443`

4. **Rate Limits**:
   - OpenAI Free: 3 requests/minute
   - Gemini Free: 15 requests/minute

## 🐛 Troubleshooting

| Lỗi       | Nguyên nhân               | Giải pháp                  |
| --------- | ------------------------- | -------------------------- |
| ORA-24247 | Network ACL chưa cấu hình | Grant ACL cho schema       |
| ORA-29273 | HTTP request failed       | Kiểm tra wallet, firewall  |
| ORA-29024 | Certificate validation    | Import SSL cert vào wallet |
| ERROR 429 | Rate limit exceeded       | Đợi hoặc nâng cấp plan     |
| ERROR 401 | Invalid API key           | Kiểm tra lại API key       |

## 📝 License

MIT License - Tự do sử dụng và chỉnh sửa.

## 👨‍💻 Author

Oracle PL/SQL AI Package - 2025
