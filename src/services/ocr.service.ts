import Tesseract from 'tesseract.js';
import { OpenAI } from 'openai';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { config } from '../config';
import { InvoiceData } from '../types/invoice';
import { preprocessImage } from '../utils/preprocess';

// Initialize AI clients
const openai = new OpenAI({ apiKey: config.openaiApiKey });
const genAI = new GoogleGenerativeAI(config.geminiApiKey);

const PROMPT_TEMPLATE = `Bạn là một AI OCR chuyên nghiệp, nhiệm vụ là trích xuất dữ liệu từ Hóa đơn Điện tử Việt Nam (Invoice) theo chuẩn Thông tư 78/2021/TT-BTC để nhập liệu vào hệ thống ERP Oracle.

YÊU CẦU ĐẦU RA (OUTPUT REQUIREMENT):

1. Trả về duy nhất một chuỗi JSON hợp lệ.
2. KHÔNG sử dụng Markdown code block (ví dụ: \`\`\`json).
3. KHÔNG thêm bất kỳ lời dẫn, mô tả hay giải thích nào trước hoặc sau JSON.
4. JSON phải parse được bằng JSON.parse trong JavaScript mà không lỗi.
5. Luôn luôn trả về đầy đủ 6 key ở root: "general_info", "seller_info", "buyer_info", "items", "financial_summary", "digital_signature"

CẤU TRÚC JSON ĐẦY ĐỦ (FULL SCHEMA - Theo Thông tư 78/2021):

{
  "general_info": {
    // Định danh hóa đơn (Bắt buộc)
    "template_code": "String (Mẫu số: 01GTKT0/001) OR null",
    "invoice_series": "String (Ký hiệu: AA/23E) OR null",
    "invoice_number": "String (Số HĐ: 0000123 - giữ số 0 đầu)",
    "invoice_date": "YYYY-MM-DD (Ngày lập)",
    "invoice_type": "String (Loại: VAT, Sale, Retail, Export...) OR null",
    
    // Thông tin cơ quan thuế
    "lookup_code": "String (Mã tra cứu từ CQT) OR null",
    "tax_authority_code": "String (Mã CQT: TCT-HCM) OR null",
    "invoice_status": "String (valid/cancelled/replaced/adjusted) OR null",
    
    // Hóa đơn liên quan (cho HĐ điều chỉnh/thay thế)
    "original_invoice_number": "String (Số HĐ gốc) OR null",
    "original_invoice_date": "YYYY-MM-DD (Ngày HĐ gốc) OR null",
    "adjustment_type": "String (replace/adjust/cancel) OR null",
    
    // Tiền tệ & Thanh toán
    "currency_code": "String (VND, USD, EUR...)",
    "exchange_rate": Number (Tỷ giá, default 1 cho VND),
    "payment_method": "String (TM/CK, TM, CK, COD...)",
    "payment_status": "String (paid/unpaid/partial) OR null",
    "payment_term": "String (30 days, COD...) OR null",
    
    // Tham chiếu khác
    "contract_number": "String (Số hợp đồng) OR null",
    "purchase_order_number": "String (Số PO) OR null",
    "delivery_note_number": "String (Số phiếu xuất kho) OR null",
    
    // Metadata
    "invoice_version": "String (Phiên bản HĐ) OR null",
    "notes": "String (Ghi chú chung) OR null"
  },
  
  "seller_info": {
    // Thông tin cơ bản (Bắt buộc)
    "name": "String (Tên đơn vị bán)",
    "tax_code": "String (MST - bỏ khoảng trắng)",
    "address": "String (Địa chỉ đầy đủ)",
    
    // Liên hệ
    "phone": "String (SĐT) OR null",
    "email": "String (Email) OR null",
    "website": "String (Website) OR null",
    "fax": "String (Fax) OR null",
    
    // Ngân hàng
    "bank_account": "String (Số TK) OR null",
    "bank_name": "String (Tên NH) OR null",
    "bank_branch": "String (Chi nhánh NH) OR null",
    
    // Đại diện pháp lý
    "legal_representative": "String (Người đại diện) OR null",
    "position": "String (Chức vụ) OR null"
  },
  
  "buyer_info": {
    // Định danh
    "name": "String (Tên cá nhân) OR null",
    "company_name": "String (Tên công ty) OR null",
    "tax_code": "String (MST - bỏ khoảng trắng) OR null",
    
    // Địa chỉ & Liên hệ
    "address": "String (Địa chỉ) OR null",
    "phone": "String (SĐT) OR null",
    "email": "String (Email) OR null",
    
    // Ngân hàng (cho hoàn tiền)
    "bank_account": "String (Số TK) OR null",
    "bank_name": "String (Tên NH) OR null",
    
    // Người liên hệ
    "contact_person": "String (Người liên hệ) OR null",
    "department": "String (Phòng ban) OR null"
  },
  
  "items": [
    {
      "line_number": Number (STT dòng: 1, 2, 3...),
      
      // Định danh sản phẩm
      "item_code": "String (Mã hàng: SKU-001) OR null",
      "item_name": "String (Tên hàng hóa/dịch vụ)",
      "item_description": "String (Mô tả chi tiết) OR null",
      
      // Đơn vị & Số lượng
      "unit_name": "String (Đơn vị: Cái, Hộp...) OR null",
      "quantity": Number (Số lượng),
      
      // Giá
      "unit_price": Number (Đơn giá),
      "total_amount_pre_tax": Number (Thành tiền chưa thuế),
      
      // Chiết khấu
      "discount_rate": Number (% CK: 5, 10...) OR null,
      "discount_amount": Number (Tiền CK) OR null,
      
      // Thuế
      "vat_rate": Number (0, 5, 8, 10, -1=KCT, -2=KKKNT, null),
      "vat_amount": Number (Tiền thuế VAT),
      "total_amount_with_tax": Number (Thành tiền sau thuế) OR null,
      
      // Bổ sung
      "promotion": "String (Khuyến mại) OR null",
      "warranty_period": "String (Bảo hành: 24 tháng) OR null",
      "origin": "String (Xuất xứ: Việt Nam, Trung Quốc...) OR null"
    }
  ],
  
  "financial_summary": {
    // Chi tiết theo thuế suất
    "tax_breakdowns": [
      {
        "vat_rate": Number (Thuế suất: 0, 5, 8, 10),
        "taxable_amount": Number (Tổng tiền chịu thuế),
        "tax_amount": Number (Tổng tiền thuế)
      }
    ] OR null,
    
    // Tổng chính (Bắt buộc)
    "total_amount_pre_tax": Number (Tổng tiền chưa thuế),
    "total_discount_amount": Number (Tổng chiết khấu) OR null,
    "total_vat_amount": Number (Tổng tiền thuế VAT),
    "total_payment_amount": Number (Tổng cộng tiền thanh toán),
    
    // Bằng chữ
    "amount_in_words": "String (Tổng tiền bằng chữ)",
    
    // Phí bổ sung
    "shipping_fee": Number (Phí vận chuyển) OR null,
    "insurance_fee": Number (Phí bảo hiểm) OR null,
    "other_fees": Number (Phí khác) OR null,
    
    // Thanh toán
    "prepaid_amount": Number (Đã thanh toán trước) OR null,
    "remaining_amount": Number (Còn phải thanh toán) OR null
  },
  
  "digital_signature": {
    "signer_name": "String (Người ký) OR null",
    "signing_time": "ISO Datetime (2024-01-15T10:30:00+07:00) OR null",
    "serial_number": "String (Serial chữ ký số) OR null",
    "authority": "String (Tổ chức cấp: VNPT-CA, Viettel-CA...) OR null",
    "valid_from": "YYYY-MM-DD (Hiệu lực từ) OR null",
    "valid_to": "YYYY-MM-DD (Hiệu lực đến) OR null",
    "hash_value": "String (Mã băm) OR null"
  } OR null
}

QUY TẮC NGHIỆP VỤ (BUSINESS RULES) - BẮT BUỘC TUÂN THỦ:

1. SỐ TIỀN (Numbers):
   - Hóa đơn VN: Dấu chấm (.) = phân cách nghìn, dấu phẩy (,) = thập phân
   - JSON Output: Loại bỏ dấu phân cách, chuyển thành Number
   - "1.000.000" → 1000000, "10,5" → 10.5
   - KHÔNG giữ dấu chấm/phẩy trong Number JSON
   - Không chắc chắn → null

2. NGÀY THÁNG (Dates):
   - Input: dd/mm/yyyy, dd-mm-yyyy, "ngày X tháng Y năm Z"
   - Output: "YYYY-MM-DD" (ISO 8601)
   - Không xác định được → null

3. THUẾ SUẤT (VAT Rate):
   - Hợp lệ: 0, 5, 8, 10
   - "Không chịu thuế" (KCT) → -1
   - "Không kê khai thuế" (KKKNT) → -2
   - Không xác định → null

4. MÃ SỐ THUẾ (Tax Code):
   - BỎ TẤT CẢ khoảng trắng
   - "0123 456 789" → "0123456789"
   - Giữ nguyên chữ và số

5. DANH SÁCH HÀNG HÓA (Items):
   - LUÔN LUÔN là Array []
   - Không có item → []
   - KHÔNG BAO GIỜ null
   - Lấy ĐẦY ĐỦ tất cả dòng trên hóa đơn

6. TAX BREAKDOWNS:
   - Nếu HĐ có nhiều thuế suất → Tạo array chi tiết
   - Ví dụ: Có cả 5% và 10% → 2 entries
   - Nếu chỉ 1 thuế suất → 1 entry
   - Nếu không phân biệt được → null

7. DIGITAL SIGNATURE:
   - Nếu hóa đơn scan/ảnh không rõ chữ ký số → toàn bộ object = null
   - Nếu thấy thông tin chữ ký → Trích xuất đầy đủ
   - Serial number, Hash thường là chuỗi HEX

8. XỬ LÝ LỖI / THIẾU DỮ LIỆU:
   - Field nào không tìm thấy → null
   - KHÔNG bỏ field khỏi JSON
   - Ưu tiên null hơn là giá trị sai

9. QUY TẮC CHUNG:
   - invoice_number: GIỮ NGUYÊN số 0 đầu
   - KHÔNG tự suy đoán thông tin không có
   - KHÔNG thêm field mới ngoài schema
   - KHÔNG thêm comment, dấu phẩy thừa
   - JSON phải valid 100%

NHIỆM VỤ:
Dựa trên nội dung hóa đơn OCR bên dưới, hãy trích xuất ĐẦY ĐỦ và chuẩn hóa thông tin theo schema trên. Trả về DUY NHẤT một JSON hợp lệ với tất cả các fields (dùng null nếu thiếu).

NỘI DUNG HÓA ĐƠN (OCR TEXT):
`;

export const processInvoice = async (
    fileBuffer: Buffer, 
    mimeType: string,
    engine: 'gemini' | 'gpt' = 'gemini',
    modelName?: string
): Promise<{ 
    json: InvoiceData | null, 
    text: string, 
    confidence: number,
    engine_used: string,
    model_used: string,
    processing_time_ms: number 
}> => {
    const startTime = Date.now();
    
    // Model defaults - TESTED & WORKING models
    const GEMINI_MODELS = {
        'flash': 'gemini-flash-latest',
        'flash-2': 'gemini-2.5-flash',
        'flash-lite': 'gemini-2.5-flash-lite'
    };
    
    const GPT_MODELS = {
        'mini': 'gpt-4o-mini'
    };
    
    // Determine actual model to use
    let actualModel: string;
    if (engine === 'gemini') {
        actualModel = modelName || GEMINI_MODELS.flash;
        // Validate if custom model name
        if (modelName && !modelName.startsWith('gemini-')) {
            actualModel = GEMINI_MODELS[modelName as keyof typeof GEMINI_MODELS] || GEMINI_MODELS.flash;
        }
    } else {
        actualModel = modelName || GPT_MODELS.mini;
        // Validate if custom model name
        if (modelName && !modelName.startsWith('gpt-')) {
            actualModel = GPT_MODELS[modelName as keyof typeof GPT_MODELS] || GPT_MODELS.mini;
        }
    }
    
    // 1. Preprocessing & Text Extraction
    let text = "";
    let confidence = 0.9; // Default for PDF text

    if (mimeType === 'application/pdf') {
        const customPdfParse = require('pdf-parse');
        try {
           const pdfData = await customPdfParse(fileBuffer);
           text = pdfData.text;
           // If text is too short, it might be scanned PDF
           if (text.length < 50) {
               console.warn("PDF appears to be scanned (little text found). OCR on PDF not fully implemented without conversion tools.");
               confidence = 0.1;
           }
        } catch(e) {
            console.error("PDF Parse Error", e);
        }
    } else {
        // Image
        const processedBuffer = await preprocessImage(fileBuffer);
        // 2. OCR Engine (Tesseract)
        console.log("Starting OCR...");
        try {
            const result = await Tesseract.recognize(
                processedBuffer,
                'vie+eng', 
                { logger: m => console.log(m) }
            );
            text = result.data.text;
            confidence = result.data.confidence / 100;
        } catch (e) {
            console.error("OCR Error:", e);
            throw new Error("OCR Failed");
        }
    }

    // 3. AI Layer - Now with engine selection
    console.log(`Sending to AI (${engine.toUpperCase()})...`);
    const aiStartTime = Date.now();
    let aiJson: InvoiceData | null = null;
    let engineUsed = engine;
    
    if (engine === 'gpt') {
        if (!config.openaiApiKey) {
            throw new Error("OpenAI API key not configured");
        }
        try {
            const completion = await openai.chat.completions.create({
                messages: [
                    { role: "system", content: "You are an AI assistant that extracts data from Vietnamese VAT invoices. Return only valid JSON without markdown formatting." },
                    { role: "user", content: PROMPT_TEMPLATE + text }
                ],
                model: actualModel,
                response_format: { type: "json_object" }
            });
            const content = completion.choices[0].message.content;
            if (content) aiJson = JSON.parse(content);
            console.log(`GPT processing time: ${Date.now() - aiStartTime}ms`);
        } catch (e: any) {
            console.error("OpenAI Error:", e);
            throw new Error(`GPT Error: ${e.message}`);
        }
    } else {
        // Gemini
        if (!config.geminiApiKey) {
            throw new Error("Gemini API key not configured");
        }
        try {
            const model = genAI.getGenerativeModel({ 
                model: actualModel
            });
            const result = await model.generateContent({
                contents: [{ role: "user", parts: [{ text: PROMPT_TEMPLATE + text }] }],
                generationConfig: {
                    temperature: 0.1,
                    maxOutputTokens: 8192
                }
            });
            const response = await result.response;
            const content = response.text();
            // Gemini might emit markdown code blocks, clean it
            const jsonStr = content.replace(/```json/g, '').replace(/```/g, '').trim();
            aiJson = JSON.parse(jsonStr);
            console.log(`Gemini processing time: ${Date.now() - aiStartTime}ms`);
        } catch (e: any) {
            console.error("Gemini Error:", e);
            throw new Error(`Gemini Error: ${e.message}`);
        }
    }

    const totalTime = Date.now() - startTime;

    return {
        json: aiJson,
        text,
        confidence,
        engine_used: engineUsed,
        model_used: actualModel,
        processing_time_ms: totalTime
    };
};

// ============================================
// PROCESS TEXT INPUT DIRECTLY
// ============================================
export const processText = async (
    inputText: string,
    engine: 'gemini' | 'gpt' = 'gemini',
    modelName?: string
): Promise<{ 
    json: InvoiceData | null, 
    text: string, 
    confidence: number,
    engine_used: string,
    model_used: string,
    processing_time_ms: number 
}> => {
    const startTime = Date.now();
    
    // Model defaults
    const GEMINI_MODELS = {
        'flash': 'gemini-flash-latest',
        'flash-2': 'gemini-2.5-flash',
        'flash-lite': 'gemini-2.5-flash-lite'
    };
    
    const GPT_MODELS = {
        'mini': 'gpt-4o-mini'
    };
    
    let actualModel: string;
    if (engine === 'gemini') {
        actualModel = modelName || GEMINI_MODELS.flash;
        if (modelName && !modelName.startsWith('gemini-')) {
            actualModel = GEMINI_MODELS[modelName as keyof typeof GEMINI_MODELS] || GEMINI_MODELS.flash;
        }
    } else {
        actualModel = modelName || GPT_MODELS.mini;
        if (modelName && !modelName.startsWith('gpt-')) {
            actualModel = GPT_MODELS[modelName as keyof typeof GPT_MODELS] || GPT_MODELS.mini;
        }
    }

    const text = inputText.trim();
    const confidence = 1.0; // Direct text input has 100% confidence

    // AI processing
    console.log(`Sending text to AI (${engine.toUpperCase()})...`);
    const aiStartTime = Date.now();
    let aiJson: InvoiceData | null = null;
    let engineUsed = engine;
    
    if (engine === 'gpt') {
        if (!config.openaiApiKey) throw new Error("OpenAI API key not configured");
        try {
            const completion = await openai.chat.completions.create({
                messages: [
                    { role: "system", content: "You are an AI that extracts data from Vietnamese VAT invoices. Return only valid JSON." },
                    { role: "user", content: PROMPT_TEMPLATE + text }
                ],
                model: actualModel,
                response_format: { type: "json_object" }
            });
            const content = completion.choices[0].message.content;
            if (content) aiJson = JSON.parse(content);
            console.log(`GPT processing time: ${Date.now() - aiStartTime}ms`);
        } catch (e: any) {
            throw new Error(`GPT Error: ${e.message}`);
        }
    } else {
        if (!config.geminiApiKey) throw new Error("Gemini API key not configured");
        try {
            const model = genAI.getGenerativeModel({ model: actualModel });
            const result = await model.generateContent({
                contents: [{ role: "user", parts: [{ text: PROMPT_TEMPLATE + text }] }],
                generationConfig: { temperature: 0.1, maxOutputTokens: 8192 }
            });
            const response = await result.response;
            const content = response.text();
            const jsonStr = content.replace(/```json/g, '').replace(/```/g, '').trim();
            aiJson = JSON.parse(jsonStr);
            console.log(`Gemini processing time: ${Date.now() - aiStartTime}ms`);
        } catch (e: any) {
            throw new Error(`Gemini Error: ${e.message}`);
        }
    }

    return {
        json: aiJson,
        text,
        confidence,
        engine_used: engineUsed,
        model_used: actualModel,
        processing_time_ms: Date.now() - startTime
    };
};

// ============================================
// PROCESS VOICE/AUDIO INPUT
// ============================================
export const processVoice = async (
    audioBuffer: Buffer,
    mimeType: string,
    engine: 'gemini' | 'gpt' = 'gemini',
    modelName?: string
): Promise<{ 
    json: InvoiceData | null, 
    text: string, 
    confidence: number,
    engine_used: string,
    model_used: string,
    processing_time_ms: number 
}> => {
    const startTime = Date.now();
    
    // Use OpenAI Whisper for speech-to-text
    console.log("Transcribing audio with Whisper...");
    let transcribedText = "";
    
    try {
        // Import toFile from openai for proper buffer handling
        const { toFile } = await import('openai');
        const audioFile = await toFile(audioBuffer, 'audio.webm', { type: mimeType });
        
        const transcription = await openai.audio.transcriptions.create({
            file: audioFile,
            model: "whisper-1",
            language: "vi" // Vietnamese
        });
        
        transcribedText = transcription.text;
        console.log(`Transcribed text: ${transcribedText.substring(0, 100)}...`);
    } catch (e: any) {
        console.error("Whisper Error:", e);
        throw new Error(`Speech-to-Text Error: ${e.message}`);
    }

    // Now process the transcribed text
    return processText(transcribedText, engine, modelName);
};

// ============================================
// PROCESS URL INPUT (fetch image from URL)
// ============================================
export const processUrl = async (
    imageUrl: string,
    engine: 'gemini' | 'gpt' = 'gemini',
    modelName?: string
): Promise<{ 
    json: InvoiceData | null, 
    text: string, 
    confidence: number,
    engine_used: string,
    model_used: string,
    processing_time_ms: number 
}> => {
    console.log(`Fetching image from URL: ${imageUrl}`);
    
    try {
        const response = await fetch(imageUrl);
        if (!response.ok) {
            throw new Error(`Failed to fetch URL: ${response.statusText}`);
        }
        
        const contentType = response.headers.get('content-type') || 'image/jpeg';
        const arrayBuffer = await response.arrayBuffer();
        const buffer = Buffer.from(arrayBuffer);
        
        // Process as image
        return processInvoice(buffer, contentType, engine, modelName);
    } catch (e: any) {
        throw new Error(`URL Fetch Error: ${e.message}`);
    }
};
