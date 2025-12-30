// ==================== COMPLETE VIETNAMESE E-INVOICE SCHEMA ====================
// Based on Circular 78/2021/TT-BTC and industry standards

// General Invoice Info (Thông tin chung - TTChung)
export interface GeneralInfo {
  // Basic identification
  template_code: string | null; // Mẫu số hóa đơn (KHMSHDon)
  invoice_series: string | null; // Ký hiệu hóa đơn (KHHDon)
  invoice_number: string; // Số hóa đơn (SHDon) - keep leading zeros
  invoice_date: string; // Ngày lập (NLap) - YYYY-MM-DD
  invoice_type: string | null; // Loại hóa đơn: "VAT", "Sale", "Retail", etc. (THDon)
  
  // Tax authority reference
  lookup_code: string | null; // Mã tra cứu (MCQTCap)
  tax_authority_code: string | null; // Mã cơ quan thuế cấp
  invoice_status: string | null; // Trạng thái: "valid", "cancelled", "replaced", "adjusted"
  
  // Related invoices
  original_invoice_number: string | null; // Số hóa đơn gốc (nếu là HĐ điều chỉnh/thay thế)
  original_invoice_date: string | null; // Ngày HĐ gốc
  adjustment_type: string | null; // Loại điều chỉnh: "replace", "adjust", "cancel"
  
  // Currency & Payment
  currency_code: string; // Mã tiền tệ (DVTTe): VND, USD, EUR...
  exchange_rate: number; // Tỷ giá (default 1 for VND)
  payment_method: string; // Hình thức thanh toán (HTTToan): TM/CK, TM, CK
  payment_status: string | null; // Trạng thái thanh toán: "paid", "unpaid", "partial"
  payment_term: string | null; // Điều kiện thanh toán (ví dụ: "30 days", "COD")
  
  // Additional references
  contract_number: string | null; // Số hợp đồng
  purchase_order_number: string | null; // Số đơn hàng
  delivery_note_number: string | null; // Số phiếu xuất kho
  
  // Metadata
  invoice_version: string | null; // Phiên bản hóa đơn (PBan)
  notes: string | null; // Ghi chú
}

// Seller Info (Người bán - NBan)
export interface SellerInfo {
  name: string; // Tên (Ten)
  tax_code: string; // MST - no spaces
  address: string; // Địa chỉ (DChi)
  
  // Contact details
  phone: string | null; // Số điện thoại (SDThoai)
  email: string | null; // Email (DCTDTu)
  website: string | null; // Website
  fax: string | null; // Fax
  
  // Banking info
  bank_account: string | null; // Số tài khoản
  bank_name: string | null; // Tên ngân hàng
  bank_branch: string | null; // Chi nhánh ngân hàng
  
  // Legal representative
  legal_representative: string | null; // Người đại diện pháp luật
  position: string | null; // Chức vụ
}

// Buyer Info (Người mua - NMua)
export interface BuyerInfo {
  // Identification
  name: string | null; // Tên người mua (cá nhân) (Ten)
  company_name: string | null; // Tên đơn vị (HVTNMHang)
  tax_code: string | null; // MST - no spaces
  
  // Address & Contact
  address: string | null; // Địa chỉ (DChi)
  phone: string | null; // Số điện thoại (SDThoai)
  email: string | null; // Email (DCTDTu)
  
  // Banking (for refund purposes)
  bank_account: string | null; // Số tài khoản
  bank_name: string | null; // Tên ngân hàng
  
  // Contact person
  contact_person: string | null; // Người liên hệ
  department: string | null; // Phòng ban
}

// Invoice Line Item (Hàng hóa dịch vụ - HHDVu)
export interface InvoiceItem {
  line_number: number; // STT
  
  // Product/Service identification
  item_code: string | null; // Mã hàng (MHHDVu)
  item_name: string; // Tên hàng hóa, dịch vụ (THHDVu)
  item_description: string | null; // Mô tả chi tiết
  
  // Unit & Quantity
  unit_name: string | null; // Đơn vị tính (DVTinh)
  quantity: number; // Số lượng (SLuong)
  
  // Pricing
  unit_price: number; // Đơn giá (DGia)
  total_amount_pre_tax: number; // Thành tiền chưa thuế (ThTien)
  
  // Discount
  discount_rate: number | null; // Tỷ lệ chiết khấu % (TLCKhau)
  discount_amount: number | null; // Tiền chiết khấu (STCKhau)
  
  // Tax
  vat_rate: number; // Thuế suất (TSuat): 0, 5, 8, 10, -1 (KCT), -2 (KKKNT), null
  vat_amount: number; // Tiền thuế GTGT (TThue)
  total_amount_with_tax: number | null; // Thành tiền sau thuế
  
  // Additional
  promotion: string | null; // Khuyến mại
  warranty_period: string | null; // Thời gian bảo hành
  origin: string | null; // Xuất xứ
}

// Financial Summary (Tổng hợp thanh toán - TToan)
export interface FinancialSummary {
  // Subtotals by tax rate (for each VAT rate)
  tax_breakdowns: TaxBreakdown[] | null; // Chi tiết theo từng thuế suất
  
  // Main totals
  total_amount_pre_tax: number; // Tổng tiền chưa thuế (TgTCThue)
  total_discount_amount: number | null; // Tổng tiền chiết khấu (TTCKTMai)
  total_vat_amount: number; // Tổng tiền thuế GTGT (TgTThue)
  total_payment_amount: number; // Tổng tiền thanh toán (TgTTTBSo)
  
  // Amount in words
  amount_in_words: string; // Tổng tiền bằng chữ (TgTTTBChu)
  
  // Additional fees
  shipping_fee: number | null; // Phí vận chuyển
  insurance_fee: number | null; // Phí bảo hiểm
  other_fees: number | null; // Phí khác
  
  // Prepayment & Balance
  prepaid_amount: number | null; // Tiền đã thanh toán trước
  remaining_amount: number | null; // Còn phải thanh toán
}

// Tax breakdown by rate (Chi tiết thuế theo từng thuế suất - LTSuat)
export interface TaxBreakdown {
  vat_rate: number; // Thuế suất (TSuat): 0%, 5%, 8%, 10%
  taxable_amount: number; // Tổng tiền chịu thuế (ThTien)
  tax_amount: number; // Tổng tiền thuế (TThue)
}

// Digital Signature Info (Chữ ký số - DSCKS)
export interface DigitalSignature {
  signer_name: string | null; // Người ký
  signing_time: string | null; // Thời gian ký (ISO datetime)
  serial_number: string | null; // Serial của chữ ký số
  authority: string | null; // Tổ chức cấp chữ ký số
  valid_from: string | null; // Hiệu lực từ
  valid_to: string | null; // Hiệu lực đến
  hash_value: string | null; // Mã băm (hash)
}

// Complete Invoice Data Structure
export interface InvoiceData {
  general_info: GeneralInfo;
  seller_info: SellerInfo;
  buyer_info: BuyerInfo;
  items: InvoiceItem[];
  financial_summary: FinancialSummary;
  digital_signature?: DigitalSignature | null; // Optional for scanned invoices
}

// API Response
export interface OcrResponse {
  status: 'success' | 'error';
  json?: InvoiceData;
  text_ocr?: string;
  confidence?: number;
  engine_used?: string;
  model_used?: string;
  processing_time_ms?: number;
  message?: string;
}
