# NodeJS OCR - Vietnamese Invoice Processing Middleware

Middleware xử lý OCR hóa đơn GTGT Việt Nam sử dụng AI đa phương thức (Google Gemini & OpenAI GPT). Được thiết kế để tích hợp dễ dàng với Oracle ERP và các hệ thống tài chính khác.

## 🚀 Tính năng nổi bật

- **Đa phương thức đầu vào**:
  - 📄 **File**: Hỗ trợ ảnh (JPG, PNG) và PDF.
  - 🎤 **Voice**: Xử lý file âm thanh/ghi âm (Speech-to-Text).
  - 📝 **Text**: Xử lý trực tiếp nội dung văn bản (copy-paste).
  - 🔗 **URL**: Xử lý ảnh/PDF từ đường dẫn mạng.
- **AI Engines mạnh mẽ**:
  - Hỗ trợ Google Gemini 1.5 Flash/Pro.
  - Hỗ trợ OpenAI GPT-4o / GPT-4o Mini.
- **Schema chuẩn Thông tư 78**:
  - Trích xuất tự động >70 trường thông tin hóa đơn.
  - Bao gồm: Mã cơ quan thuế, thông tin người mua/bán, chi tiết dòng hàng, thuế suất.
- **Tối ưu cho Việt Nam**:
  - Nhận diện chính xác tiếng Việt, chữ ký số, con dấu đỏ.
- **Giao diện Web tích hợp**:
  - UI hiện đại, dễ sử dụng để test và demo.

## 📦 Cài đặt

1. **Clone repository**:

   ```bash
   git clone https://github.com/doanphuongtrinh009/NodeJS-OCR.git
   cd NodeJS-OCR
   ```

2. **Cài đặt dependencies**:
   ```bash
   npm install
   ```

## ⚙️ Cấu hình

Tạo file `.env` tại thư mục gốc:

```env
# AI Provider Keys (Bắt buộc ít nhất 1)
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=AIza...

# Server Config
PORT=8080
```

## 🏃 Chạy ứng dụng

### Chế độ Development

```bash
npm run dev
```

### Chế độ Production

```bash
npm run build
npm start
```

Server sẽ hoạt động tại: `http://localhost:8080`

## 📖 API Documentation

### 1. Upload File Hóa Đơn

**Endpoint**: `POST /ocr/invoice`

- **Body**: Form-data `file` (Image/PDF).
- **Query**: `?engine=gemini` (default) hoặc `gpt`.

### 2. Xử lý qua Giọng nói (Voice)

**Endpoint**: `POST /ocr/voice`

- **Body**: Form-data `file` (MP3, WAV, M4A...).
- **Query**: `?engine=gemini` hoặc `gpt`.
- _Mô tả: Chuyển đổi giọng nói thành văn bản và trích xuất thông tin hóa đơn._

### 3. Xử lý Văn bản (Raw Text)

**Endpoint**: `POST /ocr/text`

- **Body (JSON)**: `{ "text": "Nội dung hóa đơn...", "engine": "gemini" }`
- _Mô tả: Xử lý văn bản đã được OCR sơ bộ hoặc copy từ nguồn khác._

### 4. Xử lý từ URL

**Endpoint**: `POST /ocr/url`

- **Body (JSON)**: `{ "url": "https://example.com/invoice.jpg", "engine": "gemini" }`

## 🔧 Cấu trúc dự án

```
NodeJS-OCR/
├── src/
│   ├── config/          # Cấu hình hệ thống
│   ├── controllers/     # Điều phối request
│   ├── routes/          # Định nghĩa API endpoints (ocr.route.ts)
│   ├── services/        # Logic xử lý AI (GeminiService, OpenAIService)
│   ├── utils/           # Tiện ích chung
│   └── server.ts        # Entry point
├── public/              # Giao diện Web Demo
├── dist/                # Code đã build
└── package.json
```

## 🤝 Tích hợp Oracle ERP / PL/SQL

API này trả về JSON có cấu trúc phẳng và mảng, dễ dàng parse trong PL/SQL bằng `APEX_JSON` hoặc `JSON_TABLE`.

**Mapping gợi ý:**

- `invoice_header.invoice_number` ➡️ `AP_INVOICES_INTERFACE.INVOICE_NUM`
- `seller.tax_code` ➡️ `AP_SUPPLIERS.SEGMENT1` (Vendor Num/Tax ID)
- `tax_summary.total` ➡️ `AP_INVOICES_INTERFACE.INVOICE_AMOUNT`
- `items[]` ➡️ `AP_INVOICE_LINES_INTERFACE`

## 📊 So sánh AI Engine

| Engine               | Tốc độ           | Chi phí     | Phù hợp nhất                     |
| -------------------- | ---------------- | ----------- | -------------------------------- |
| **Gemini 1.5 Flash** | ⚡⚡⚡ Rất nhanh | 💰 Rẻ       | Xử lý số lượng lớn, OCR cơ bản   |
| **GPT-4o Mini**      | ⚡⚡ Trung bình  | 💰 Vừa phải | Độ chính xác cao, logic phức tạp |

## 📝 License

ISC
