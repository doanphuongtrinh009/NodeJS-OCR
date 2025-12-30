# Oracle ERP OCR - Vietnamese Invoice Processing API

Hệ thống xử lý OCR hóa đơn GTGT Việt Nam sử dụng AI (Gemini & ChatGPT) theo chuẩn **Thông tư 78/2021/TT-BTC**.

## 🚀 Tính năng

- ✅ **Schema đầy đủ**: ~70 fields theo Thông tư 78/2021/TT-BTC
- ✅ **Đa AI Engine**: Hỗ trợ cả Google Gemini 1.5 Flash và OpenAI GPT-4o Mini
- ✅ **So sánh hiệu suất**: Đo thời gian xử lý và độ tin cậy của từng AI engine
- ✅ **OCR đa định dạng**: Hỗ trợ ảnh (JPG, PNG) và PDF
- ✅ **Trích xuất đầy đủ**:
  - Thông tin cơ quan thuế (mã tra cứu, lookup code)
  - Thông tin liên hệ (phone, email, bank account)
  - Chữ ký số (digital signature)
  - Chi tiết theo thuế suất (tax breakdowns)
  - Hóa đơn điều chỉnh/thay thế
- ✅ **Giao diện hiện đại**: UI đẹp với Tailwind CSS
- ✅ **RESTful API**: Dễ dàng tích hợp với Oracle ERP

## 📦 Cài đặt

```bash
npm install
```

## ⚙️ Cấu hình

Tạo file `.env` với nội dung:

```env
OPENAI_API_KEY=your-openai-api-key-here
GEMINI_API_KEY=your-gemini-api-key-here
PORT=8080
```

## 🏃 Chạy ứng dụng

### Development Mode

```bash
npm run dev
```

### Production Mode

```bash
npm run build
npm start
```

Server sẽ chạy tại: **http://localhost:8080**

## 📖 API Documentation

### POST `/ocr/invoice`

Xử lý hóa đơn và trả về dữ liệu JSON.

#### Query Parameters

- `engine` (optional): Chọn AI engine - `gemini` hoặc `gpt` (mặc định: `gemini`)

#### Request

- **Content-Type**: `multipart/form-data`
- **Body**:
  - `file`: File hóa đơn (image/pdf)

#### Response

```json
{
  "status": "success",
  "json": {
    "invoice_header": {
      "invoice_number": "0001234",
      "invoice_symbol": "01AA-23TT",
      "invoice_form": "01GTKT0/001",
      "issue_date": "2024-01-15",
      "invoice_type": "VAT",
      "currency": "VND",
      "payment_method": "TM/CK"
    },
    "seller": {
      "name": "CÔNG TY TNHH ABC",
      "tax_code": "0123456789",
      "address": "123 Đường ABC, P. XYZ, Q. 1, TP.HCM",
      "phone": "028-12345678",
      "bank_account": "1234567890-VCB"
    },
    "buyer": {
      "name": "CÔNG TY CP DEF",
      "tax_code": "9876543210",
      "address": "456 Đường DEF, P. KLM, Q. 2, TP.HCM",
      "email": "contact@def.com"
    },
    "items": [
      {
        "name": "Sản phẩm A",
        "unit": "Cái",
        "quantity": 10,
        "unit_price": 100000,
        "amount": 1000000,
        "vat_rate": 10,
        "vat_amount": 100000
      }
    ],
    "tax_summary": {
      "sub_total": 1000000,
      "vat_total": 100000,
      "discount": 0,
      "total": 1100000,
      "amount_in_words": "Một triệu một trăm nghìn đồng chẵn"
    },
    "metadata": {
      "confidence": 0.95,
      "signed": true,
      "signature_stamp": true,
      "hash": "",
      "uuid": ""
    }
  },
  "text_ocr": "Full extracted text...",
  "confidence": 0.92,
  "engine_used": "gemini",
  "processing_time_ms": 3245
}
```

## 🌐 Sử dụng giao diện Web

1. Mở trình duyệt: `http://localhost:8080`
2. Chọn AI Engine (Gemini hoặc GPT)
3. Tải lên file hóa đơn
4. Nhấn "BẮT ĐẦU TRÍCH XUẤT"
5. Xem kết quả với:
   - Thông tin quan trọng (số hóa đơn, người bán, người mua, tổng tiền)
   - Thời gian xử lý
   - Độ tin cậy
   - Raw JSON đầy đủ

## 🧪 Test với cURL

### Sử dụng Gemini (mặc định)

```bash
curl -X POST http://localhost:8080/ocr/invoice \
  -F "file=@/path/to/invoice.jpg"
```

### Sử dụng GPT

```bash
curl -X POST "http://localhost:8080/ocr/invoice?engine=gpt" \
  -F "file=@/path/to/invoice.jpg"
```

## 📊 So sánh Gemini vs GPT

| Tiêu chí     | Gemini 1.5 Flash | GPT-4o Mini     |
| ------------ | ---------------- | --------------- |
| Tốc độ       | ⚡⚡⚡ Nhanh hơn | ⚡⚡ Trung bình |
| Chi phí      | 💰 Rẻ hơn        | 💰💰 Đắt hơn    |
| Độ chính xác | 🎯 Cao           | 🎯🎯 Rất cao    |
| Ngôn ngữ VN  | ✅ Tốt           | ✅ Rất tốt      |

**Khuyến nghị**: Dùng Gemini cho xử lý hàng loạt, GPT cho độ chính xác cao nhất.

## 🔧 Cấu trúc dự án

```
Node js OCR/
├── src/
│   ├── config/          # Cấu hình (API keys, env)
│   ├── controllers/     # Xử lý request/response
│   ├── routes/          # Định nghĩa API endpoints
│   ├── services/        # Logic nghiệp vụ (OCR, AI)
│   ├── types/           # TypeScript interfaces
│   ├── utils/           # Hàm tiện ích
│   └── server.ts        # Entry point
├── public/              # Giao diện web
├── .env                 # Biến môi trường
└── package.json
```

## 🐛 Xử lý lỗi

### Lỗi thường gặp

**1. "OpenAI API key not configured"**

- Kiểm tra `.env` có `OPENAI_API_KEY` chưa

**2. "Gemini API key not configured"**

- Kiểm tra `.env` có `GEMINI_API_KEY` chưa

**3. "OCR Failed"**

- File ảnh quá mờ hoặc chất lượng thấp
- Thử tăng độ phân giải ảnh

## 📝 Lưu ý

- File upload tối đa: 10MB
- Hỗ trợ định dạng: JPG, PNG, PDF
- PDF scan cần độ phân giải tốt để OCR chính xác
- Hóa đơn cần rõ ràng, không bị che khuất

## 🤝 Tích hợp Oracle ERP

API trả về JSON chuẩn, dễ dàng map vào Oracle ERP:

- `invoice_number` → Invoice Number
- `seller.tax_code` → Vendor Tax ID
- `total` → Total Amount
- `items[]` → Line Items

## 📞 Hỗ trợ

Nếu gặp vấn đề, kiểm tra:

1. Console log của server
2. Network tab trong DevTools
3. File `.env` đã cấu hình đúng chưa
