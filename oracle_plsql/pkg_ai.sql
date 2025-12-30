-- ============================================================================
-- ORACLE PL/SQL - AI API Functions FULL VERSION
-- Hỗ trợ: Text, Image, PDF, XML, Voice/Audio
-- Có đầy đủ cả GPT (OpenAI) và Gemini (Google)
-- ============================================================================

CREATE OR REPLACE PACKAGE pkg_ai AS
    
    -- =======================================================================
    -- 1. CHAT FUNCTIONS
    -- =======================================================================
    FUNCTION gpt_chat(p_api_key VARCHAR2, p_prompt CLOB, p_model VARCHAR2 DEFAULT 'gpt-4o-mini') RETURN CLOB;
    FUNCTION gemini_chat(p_api_key VARCHAR2, p_prompt CLOB, p_model VARCHAR2 DEFAULT 'gemini-2.5-flash-lite') RETURN CLOB;
    
    -- =======================================================================
    -- 2. INVOICE FROM TEXT (OCR text đã có sẵn)
    -- =======================================================================
    FUNCTION gpt_invoice_from_text(p_api_key VARCHAR2, p_text CLOB, p_model VARCHAR2 DEFAULT 'gpt-4o-mini') RETURN CLOB;
    FUNCTION gemini_invoice_from_text(p_api_key VARCHAR2, p_text CLOB, p_model VARCHAR2 DEFAULT 'gemini-2.5-flash-lite') RETURN CLOB;
    
    -- =======================================================================
    -- 3. INVOICE FROM IMAGE (PNG, JPG, JPEG, GIF, WEBP)
    -- =======================================================================
    FUNCTION gpt_invoice_from_image(p_api_key VARCHAR2, p_blob BLOB, p_mime_type VARCHAR2 DEFAULT 'image/png', p_model VARCHAR2 DEFAULT 'gpt-4o-mini') RETURN CLOB;
    FUNCTION gemini_invoice_from_image(p_api_key VARCHAR2, p_blob BLOB, p_mime_type VARCHAR2 DEFAULT 'image/png', p_model VARCHAR2 DEFAULT 'gemini-2.5-flash-lite') RETURN CLOB;
    
    -- =======================================================================
    -- 4. INVOICE FROM PDF
    -- GPT: Uses Oracle Text CTX_DOC.POLICY_FILTER to extract text first
    --      Requires: GRANT EXECUTE ON CTXSYS.CTX_DOC, CTX_DDL TO schema
    --      Fallback: Returns error suggesting Gemini if extraction fails
    -- Gemini: Reads PDF directly (works with scanned/image PDFs)
    -- =======================================================================
    FUNCTION gpt_invoice_from_pdf(p_api_key VARCHAR2, p_blob BLOB, p_model VARCHAR2 DEFAULT 'gpt-4o-mini') RETURN CLOB;
    FUNCTION gemini_invoice_from_pdf(p_api_key VARCHAR2, p_blob BLOB, p_model VARCHAR2 DEFAULT 'gemini-2.5-flash-lite') RETURN CLOB;
    
    -- =======================================================================
    -- 5. INVOICE FROM XML (CLOB hoặc BLOB)
    -- =======================================================================
    FUNCTION gpt_invoice_from_xml(p_api_key VARCHAR2, p_xml CLOB, p_model VARCHAR2 DEFAULT 'gpt-4o-mini') RETURN CLOB;
    FUNCTION gpt_invoice_from_xml_blob(p_api_key VARCHAR2, p_blob BLOB, p_model VARCHAR2 DEFAULT 'gpt-4o-mini') RETURN CLOB;
    FUNCTION gemini_invoice_from_xml(p_api_key VARCHAR2, p_xml CLOB, p_model VARCHAR2 DEFAULT 'gemini-2.5-flash-lite') RETURN CLOB;
    FUNCTION gemini_invoice_from_xml_blob(p_api_key VARCHAR2, p_blob BLOB, p_model VARCHAR2 DEFAULT 'gemini-2.5-flash-lite') RETURN CLOB;
    
    -- =======================================================================
    -- 6. INVOICE FROM AUDIO (Voice, Speech-to-Text)
    -- =======================================================================
    FUNCTION gpt_invoice_from_audio(p_api_key VARCHAR2, p_audio_blob BLOB, p_audio_type VARCHAR2 DEFAULT 'audio/webm') RETURN CLOB;
    FUNCTION gemini_invoice_from_audio(p_api_key VARCHAR2, p_audio_blob BLOB, p_audio_type VARCHAR2 DEFAULT 'audio/webm', p_model VARCHAR2 DEFAULT 'gemini-2.5-flash-lite') RETURN CLOB;
    
    -- =======================================================================
    -- 7. UTILITY FUNCTIONS
    -- =======================================================================
    FUNCTION blob_to_clob(p_blob BLOB) RETURN CLOB;
    FUNCTION blob_to_base64(p_blob BLOB) RETURN CLOB;
    FUNCTION clean_json(p_text CLOB) RETURN CLOB;  -- Remove markdown wrapper from JSON
    
END pkg_ai;
/

CREATE OR REPLACE PACKAGE BODY pkg_ai AS

    -- Wallet configuration for HTTPS
    g_wallet_path VARCHAR2(500) := 'file:/u01/https/getCert/wallet';
    g_wallet_pwd  VARCHAR2(100) := 'YPb3pu1jrHnBOmVkEfOHxIQJs3tyHD15uiXhMmsE';

    -- ========================================================================
    -- INVOICE EXTRACTION PROMPT (English - Full Version matching Node.js)
    -- Based on Vietnamese Circular 78/2021/TT-BTC for Oracle ERP integration
    -- ========================================================================
    FUNCTION get_invoice_prompt RETURN CLOB IS
    BEGIN
        RETURN 'You are a professional OCR AI specialized in extracting data from Vietnamese Electronic Invoices (E-Invoice) according to Circular 78/2021/TT-BTC standard for Oracle ERP integration.

OUTPUT REQUIREMENTS:
1. Return ONLY a valid JSON string.
2. DO NOT use Markdown code blocks (e.g., ```json).
3. DO NOT add any introduction, description, or explanation before or after JSON.
4. JSON must be parseable by JSON.parse in JavaScript without errors.
5. ALWAYS return all 6 root keys: "general_info", "seller_info", "buyer_info", "items", "financial_summary", "digital_signature"

FULL JSON SCHEMA (Circular 78/2021):

{
  "general_info": {
    "template_code": "String (Template: 01GTKT0/001) OR null",
    "invoice_series": "String (Series: AA/23E) OR null",
    "invoice_number": "String (Number: 0000123 - keep leading zeros)",
    "invoice_date": "YYYY-MM-DD (Issue date)",
    "invoice_type": "String (Type: VAT, Sale, Retail, Export...) OR null",
    "lookup_code": "String (Tax authority lookup code) OR null",
    "tax_authority_code": "String (Tax authority code) OR null",
    "invoice_status": "String (valid/cancelled/replaced/adjusted) OR null",
    "original_invoice_number": "String (Original invoice number for adjustments) OR null",
    "original_invoice_date": "YYYY-MM-DD (Original invoice date) OR null",
    "adjustment_type": "String (replace/adjust/cancel) OR null",
    "currency_code": "String (VND, USD, EUR...)",
    "exchange_rate": "Number (Exchange rate, default 1 for VND)",
    "payment_method": "String (TM/CK, TM, CK, COD...)",
    "payment_status": "String (paid/unpaid/partial) OR null",
    "payment_term": "String (30 days, COD...) OR null",
    "contract_number": "String (Contract number) OR null",
    "purchase_order_number": "String (PO number) OR null",
    "delivery_note_number": "String (Delivery note number) OR null",
    "invoice_version": "String (Invoice version) OR null",
    "notes": "String (General notes) OR null"
  },
  
  "seller_info": {
    "name": "String (Seller company name)",
    "tax_code": "String (Tax code - remove all spaces)",
    "address": "String (Full address)",
    "phone": "String (Phone) OR null",
    "email": "String (Email) OR null",
    "website": "String (Website) OR null",
    "fax": "String (Fax) OR null",
    "bank_account": "String (Bank account number) OR null",
    "bank_name": "String (Bank name) OR null",
    "bank_branch": "String (Bank branch) OR null",
    "legal_representative": "String (Legal representative) OR null",
    "position": "String (Position) OR null"
  },
  
  "buyer_info": {
    "name": "String (Individual name) OR null",
    "company_name": "String (Company name) OR null",
    "tax_code": "String (Tax code - remove all spaces) OR null",
    "address": "String (Address) OR null",
    "phone": "String (Phone) OR null",
    "email": "String (Email) OR null",
    "bank_account": "String (Bank account for refunds) OR null",
    "bank_name": "String (Bank name) OR null",
    "contact_person": "String (Contact person) OR null",
    "department": "String (Department) OR null"
  },
  
  "items": [
    {
      "line_number": "Number (Line: 1, 2, 3...)",
      "item_code": "String (SKU code) OR null",
      "item_name": "String (Product/service name)",
      "item_description": "String (Detailed description) OR null",
      "unit_name": "String (Unit: Piece, Box...) OR null",
      "quantity": "Number (Quantity)",
      "unit_price": "Number (Unit price)",
      "total_amount_pre_tax": "Number (Amount before tax)",
      "discount_rate": "Number (Discount %: 5, 10...) OR null",
      "discount_amount": "Number (Discount amount) OR null",
      "vat_rate": "Number (0, 5, 8, 10, -1=Non-taxable, -2=Not declared, null)",
      "vat_amount": "Number (VAT amount)",
      "total_amount_with_tax": "Number (Amount after tax) OR null",
      "promotion": "String (Promotion) OR null",
      "warranty_period": "String (Warranty: 24 months) OR null",
      "origin": "String (Origin: Vietnam, China...) OR null"
    }
  ],
  
  "financial_summary": {
    "tax_breakdowns": [
      {
        "vat_rate": "Number (Rate: 0, 5, 8, 10)",
        "taxable_amount": "Number (Taxable amount)",
        "tax_amount": "Number (Tax amount)"
      }
    ],
    "total_amount_pre_tax": "Number (Total before tax)",
    "total_discount_amount": "Number (Total discount) OR null",
    "total_vat_amount": "Number (Total VAT)",
    "total_payment_amount": "Number (Total payment)",
    "amount_in_words": "String (Amount in words)",
    "shipping_fee": "Number (Shipping fee) OR null",
    "insurance_fee": "Number (Insurance fee) OR null",
    "other_fees": "Number (Other fees) OR null",
    "prepaid_amount": "Number (Prepaid amount) OR null",
    "remaining_amount": "Number (Remaining amount) OR null"
  },
  
  "digital_signature": {
    "signer_name": "String (Signer name) OR null",
    "signing_time": "ISO Datetime (2024-01-15T10:30:00+07:00) OR null",
    "serial_number": "String (Certificate serial) OR null",
    "authority": "String (CA: VNPT-CA, Viettel-CA...) OR null",
    "valid_from": "YYYY-MM-DD (Valid from) OR null",
    "valid_to": "YYYY-MM-DD (Valid to) OR null",
    "hash_value": "String (Hash value) OR null"
  }
}

BUSINESS RULES (MANDATORY):

1. AMOUNTS (Numbers):
   - Vietnamese invoices: dot (.) = thousand separator, comma (,) = decimal
   - JSON Output: Remove separators, convert to Number
   - "1.000.000" -> 1000000, "10,5" -> 10.5
   - DO NOT keep dots/commas in JSON Numbers
   - If uncertain -> null

2. DATES:
   - Input: dd/mm/yyyy, dd-mm-yyyy, "day X month Y year Z"
   - Output: "YYYY-MM-DD" (ISO 8601)
   - Cannot determine -> null

3. VAT RATE:
   - Valid: 0, 5, 8, 10
   - "Non-taxable" (KCT) -> -1
   - "Not declared" (KKKNT) -> -2
   - Unknown -> null

4. TAX CODE:
   - REMOVE ALL spaces
   - "0123 456 789" -> "0123456789"
   - Keep letters and numbers only

5. ITEMS ARRAY:
   - ALWAYS an Array []
   - No items -> []
   - NEVER null
   - Extract ALL lines from invoice

6. TAX BREAKDOWNS:
   - Multiple tax rates -> Create array entries
   - Example: 5% and 10% -> 2 entries
   - Single rate -> 1 entry
   - Cannot distinguish -> null

7. DIGITAL SIGNATURE:
   - Scanned/photo without clear signature -> entire object = null
   - If signature info visible -> Extract fully
   - Serial/Hash are usually HEX strings

8. MISSING DATA:
   - Field not found -> null
   - DO NOT remove field from JSON
   - Prefer null over wrong value

9. GENERAL RULES:
   - invoice_number: KEEP leading zeros
   - DO NOT guess missing information
   - DO NOT add fields outside schema
   - DO NOT add comments, trailing commas
   - JSON must be 100% valid

TASK:
Based on the invoice content below, extract COMPLETE and standardized information according to the schema above. Return ONLY a valid JSON with all fields (use null if missing).

INVOICE CONTENT:
';
    END get_invoice_prompt;

    -- ========================================================================
    -- XML PARSING PROMPT (English - uses same schema)
    -- ========================================================================
    FUNCTION get_xml_prompt RETURN CLOB IS
    BEGIN
        RETURN 'You are an AI specialized in parsing Vietnamese e-invoice XML according to Circular 78/2021.

Task: Read XML content and extract invoice information.
Return ONLY valid JSON, no explanation, no markdown.

Use the same schema as invoice extraction with all fields.
Follow all business rules for amounts, dates, tax codes.

XML Content:
';
    END get_xml_prompt;

    -- ========================================================================
    -- IMAGE OCR PROMPT (English - compact version for Vision API)
    -- ========================================================================
    FUNCTION get_image_prompt RETURN CLOB IS
    BEGIN
        RETURN 'Extract Vietnamese invoice data from this image. Return ONLY valid JSON (no markdown).

Required structure with ALL fields (use null if not found):
- general_info: template_code, invoice_series, invoice_number (keep leading zeros), invoice_date (YYYY-MM-DD), invoice_type, lookup_code, currency_code, exchange_rate, payment_method, payment_status, contract_number, notes
- seller_info: name, tax_code (no spaces), address, phone, email, bank_account, bank_name, bank_branch, legal_representative
- buyer_info: name, company_name, tax_code (no spaces), address, phone, email, bank_account, bank_name, contact_person
- items: Array of {line_number, item_code, item_name, item_description, unit_name, quantity, unit_price, total_amount_pre_tax, discount_rate, discount_amount, vat_rate (0/5/8/10/-1/-2), vat_amount, total_amount_with_tax, origin}
- financial_summary: tax_breakdowns array, total_amount_pre_tax, total_discount_amount, total_vat_amount, total_payment_amount, amount_in_words, shipping_fee, prepaid_amount, remaining_amount
- digital_signature: signer_name, signing_time (ISO datetime), serial_number, authority, valid_from, valid_to, hash_value (or null if not visible)

RULES:
1. Amounts: Remove thousand separators, convert to integers (1.000.000 -> 1000000)
2. Dates: Convert to YYYY-MM-DD format
3. Tax codes: Remove all spaces
4. VAT rates: 0, 5, 8, 10, or -1 (non-taxable), -2 (not declared)
5. Items: ALWAYS array, never null
6. Return COMPLETE JSON with all fields';
    END get_image_prompt;

    -- ========================================================================
    -- AUDIO PROMPT (English - for voice input)
    -- ========================================================================
    FUNCTION get_audio_prompt RETURN CLOB IS
    BEGIN
        RETURN 'Listen to this audio containing Vietnamese invoice information. Extract and return JSON.

Required structure (use null for missing fields):
- general_info: invoice_number, invoice_date (YYYY-MM-DD), currency_code, payment_method
- seller_info: name, tax_code (no spaces), address, phone, bank_account, bank_name
- buyer_info: name, company_name, tax_code (no spaces), address, phone
- items: Array of {line_number, item_name, quantity, unit_price (integer), total_amount_pre_tax (integer), vat_rate (0/5/8/10), vat_amount (integer)}
- financial_summary: total_amount_pre_tax, total_vat_amount, total_payment_amount (all integers), amount_in_words
- digital_signature: null (audio has no signature info)

RULES:
1. All amounts must be integers without separators
2. Dates in YYYY-MM-DD format
3. Tax codes without spaces
4. Return ONLY valid JSON, no explanation';
    END get_audio_prompt;

    -- ========================================================================
    -- UTILITY: BLOB to CLOB
    -- ========================================================================
    FUNCTION blob_to_clob(p_blob BLOB) RETURN CLOB IS
        l_clob CLOB;
        l_dest_offset NUMBER := 1;
        l_src_offset NUMBER := 1;
        l_lang_context NUMBER := DBMS_LOB.DEFAULT_LANG_CTX;
        l_warning NUMBER;
    BEGIN
        IF p_blob IS NULL OR DBMS_LOB.GETLENGTH(p_blob) = 0 THEN RETURN NULL; END IF;
        DBMS_LOB.CREATETEMPORARY(l_clob, TRUE);
        DBMS_LOB.CONVERTTOCLOB(l_clob, p_blob, DBMS_LOB.LOBMAXSIZE, l_dest_offset, l_src_offset, DBMS_LOB.DEFAULT_CSID, l_lang_context, l_warning);
        RETURN l_clob;
    EXCEPTION WHEN OTHERS THEN RETURN 'ERROR: ' || SQLERRM;
    END blob_to_clob;

    -- ========================================================================
    -- UTILITY: BLOB to Base64
    -- ========================================================================
    FUNCTION blob_to_base64(p_blob BLOB) RETURN CLOB IS
        l_base64 CLOB;
        l_step PLS_INTEGER := 12000;
        l_offset PLS_INTEGER := 1;
        l_len PLS_INTEGER;
    BEGIN
        IF p_blob IS NULL THEN RETURN NULL; END IF;
        l_len := DBMS_LOB.GETLENGTH(p_blob);
        DBMS_LOB.CREATETEMPORARY(l_base64, TRUE);
        WHILE l_offset <= l_len LOOP
            DBMS_LOB.APPEND(l_base64, UTL_RAW.CAST_TO_VARCHAR2(UTL_ENCODE.BASE64_ENCODE(DBMS_LOB.SUBSTR(p_blob, l_step, l_offset))));
            l_offset := l_offset + l_step;
        END LOOP;
        l_base64 := REPLACE(REPLACE(l_base64, CHR(10), ''), CHR(13), '');
        RETURN l_base64;
    EXCEPTION WHEN OTHERS THEN RETURN 'ERROR: ' || SQLERRM;
    END blob_to_base64;

    -- ========================================================================
    -- HELPER: Clean JSON - Remove markdown wrapper (```json ... ```)
    -- Đảm bảo output là JSON thuần túy để insert vào ERP
    -- ========================================================================
    FUNCTION clean_json(p_text CLOB) RETURN CLOB IS
        l_result CLOB;
        l_start_pos NUMBER;
        l_end_pos NUMBER;
    BEGIN
        IF p_text IS NULL THEN RETURN NULL; END IF;
        
        l_result := p_text;
        
        -- Remove leading markdown code block: ```json or ```
        IF INSTR(l_result, '```json') > 0 THEN
            l_start_pos := INSTR(l_result, '```json') + 7;
            l_result := SUBSTR(l_result, l_start_pos);
        ELSIF INSTR(l_result, '```JSON') > 0 THEN
            l_start_pos := INSTR(l_result, '```JSON') + 7;
            l_result := SUBSTR(l_result, l_start_pos);
        ELSIF INSTR(l_result, '```') = 1 THEN
            l_start_pos := INSTR(l_result, '```') + 3;
            l_result := SUBSTR(l_result, l_start_pos);
        END IF;
        
        -- Remove trailing markdown code block: ```
        l_end_pos := INSTR(l_result, '```', -1);
        IF l_end_pos > 0 THEN
            l_result := SUBSTR(l_result, 1, l_end_pos - 1);
        END IF;
        
        -- Trim whitespace
        l_result := TRIM(l_result);
        
        -- Remove leading/trailing newlines
        WHILE SUBSTR(l_result, 1, 1) IN (CHR(10), CHR(13)) LOOP
            l_result := SUBSTR(l_result, 2);
        END LOOP;
        WHILE SUBSTR(l_result, -1, 1) IN (CHR(10), CHR(13)) LOOP
            l_result := SUBSTR(l_result, 1, LENGTH(l_result) - 1);
        END LOOP;
        
        RETURN l_result;
    EXCEPTION WHEN OTHERS THEN RETURN p_text;
    END clean_json;

    -- ========================================================================
    -- HELPER: Extract text from GPT response and clean JSON
    -- ========================================================================
    FUNCTION extract_gpt_text(p_json CLOB) RETURN CLOB IS
        l_obj JSON_OBJECT_T;
        l_choices JSON_ARRAY_T;
        l_choice JSON_OBJECT_T;
        l_message JSON_OBJECT_T;
        l_content CLOB;
    BEGIN
        l_obj := JSON_OBJECT_T(p_json);
        l_choices := l_obj.GET_ARRAY('choices');
        l_choice := TREAT(l_choices.GET(0) AS JSON_OBJECT_T);
        l_message := l_choice.GET_OBJECT('message');
        l_content := l_message.GET_STRING('content');
        -- Clean markdown wrapper if present
        RETURN clean_json(l_content);
    EXCEPTION WHEN OTHERS THEN RETURN p_json;
    END extract_gpt_text;

    -- ========================================================================
    -- HELPER: Extract text from Gemini response and clean JSON
    -- ========================================================================
    FUNCTION extract_gemini_text(p_json CLOB) RETURN CLOB IS
        l_obj JSON_OBJECT_T;
        l_candidates JSON_ARRAY_T;
        l_candidate JSON_OBJECT_T;
        l_content JSON_OBJECT_T;
        l_parts JSON_ARRAY_T;
        l_part JSON_OBJECT_T;
        l_text CLOB;
    BEGIN
        l_obj := JSON_OBJECT_T(p_json);
        l_candidates := l_obj.GET_ARRAY('candidates');
        l_candidate := TREAT(l_candidates.GET(0) AS JSON_OBJECT_T);
        l_content := l_candidate.GET_OBJECT('content');
        l_parts := l_content.GET_ARRAY('parts');
        l_part := TREAT(l_parts.GET(0) AS JSON_OBJECT_T);
        l_text := l_part.GET_STRING('text');
        -- Clean markdown wrapper if present
        RETURN clean_json(l_text);
    EXCEPTION WHEN OTHERS THEN RETURN p_json;
    END extract_gemini_text;

    -- ========================================================================
    -- 1A. GPT_CHAT - Chat with GPT
    -- ========================================================================
    FUNCTION gpt_chat(p_api_key VARCHAR2, p_prompt CLOB, p_model VARCHAR2 DEFAULT 'gpt-4o-mini') RETURN CLOB IS
        l_url VARCHAR2(500) := 'https://api.openai.com/v1/chat/completions';
        l_req_body VARCHAR2(32767);
        l_http_req UTL_HTTP.REQ;
        l_http_res UTL_HTTP.RESP;
        l_res_body CLOB := EMPTY_CLOB();
        l_buffer VARCHAR2(32767);
    BEGIN
        l_req_body := JSON_OBJECT('model' VALUE p_model, 'messages' VALUE JSON_ARRAY(JSON_OBJECT('role' VALUE 'user', 'content' VALUE p_prompt)));
        
        UTL_HTTP.SET_WALLET(g_wallet_path, g_wallet_pwd);
        UTL_HTTP.SET_TRANSFER_TIMEOUT(120);
        UTL_HTTP.SET_BODY_CHARSET('UTF-8');
        
        l_http_req := UTL_HTTP.BEGIN_REQUEST(l_url, 'POST', 'HTTP/1.1');
        UTL_HTTP.SET_HEADER(l_http_req, 'Authorization', 'Bearer ' || p_api_key);
        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Type', 'application/json');
        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Length', LENGTHB(l_req_body));
        UTL_HTTP.WRITE_RAW(l_http_req, UTL_RAW.CAST_TO_RAW(l_req_body));
        
        l_http_res := UTL_HTTP.GET_RESPONSE(l_http_req);
        BEGIN
            LOOP UTL_HTTP.READ_TEXT(l_http_res, l_buffer); l_res_body := l_res_body || l_buffer; END LOOP;
        EXCEPTION WHEN UTL_HTTP.END_OF_BODY THEN UTL_HTTP.END_RESPONSE(l_http_res);
        END;
        
        IF l_http_res.status_code = 200 THEN RETURN extract_gpt_text(l_res_body);
        ELSE RETURN 'ERROR ' || l_http_res.status_code || ': ' || DBMS_LOB.SUBSTR(l_res_body, 2000, 1);
        END IF;
    EXCEPTION WHEN OTHERS THEN RETURN 'ERROR: ' || SQLERRM;
    END gpt_chat;

    -- ========================================================================
    -- 1B. GEMINI_CHAT - Chat with Gemini
    -- ========================================================================
    FUNCTION gemini_chat(p_api_key VARCHAR2, p_prompt CLOB, p_model VARCHAR2 DEFAULT 'gemini-2.5-flash-lite') RETURN CLOB IS
        l_url VARCHAR2(500);
        l_req_body VARCHAR2(32767);
        l_http_req UTL_HTTP.REQ;
        l_http_res UTL_HTTP.RESP;
        l_res_body CLOB := EMPTY_CLOB();
        l_buffer VARCHAR2(32767);
    BEGIN
        l_url := 'https://generativelanguage.googleapis.com/v1beta/models/' || p_model || ':generateContent?key=' || p_api_key;
        l_req_body := JSON_OBJECT('contents' VALUE JSON_ARRAY(JSON_OBJECT('parts' VALUE JSON_ARRAY(JSON_OBJECT('text' VALUE p_prompt)))));
        
        UTL_HTTP.SET_WALLET(g_wallet_path, g_wallet_pwd);
        UTL_HTTP.SET_TRANSFER_TIMEOUT(120);
        UTL_HTTP.SET_BODY_CHARSET('UTF-8');
        
        l_http_req := UTL_HTTP.BEGIN_REQUEST(l_url, 'POST', 'HTTP/1.1');
        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Type', 'application/json');
        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Length', LENGTHB(l_req_body));
        UTL_HTTP.WRITE_RAW(l_http_req, UTL_RAW.CAST_TO_RAW(l_req_body));
        
        l_http_res := UTL_HTTP.GET_RESPONSE(l_http_req);
        BEGIN
            LOOP UTL_HTTP.READ_TEXT(l_http_res, l_buffer); l_res_body := l_res_body || l_buffer; END LOOP;
        EXCEPTION WHEN UTL_HTTP.END_OF_BODY THEN UTL_HTTP.END_RESPONSE(l_http_res);
        END;
        
        IF l_http_res.status_code = 200 THEN RETURN extract_gemini_text(l_res_body);
        ELSE RETURN 'ERROR ' || l_http_res.status_code || ': ' || DBMS_LOB.SUBSTR(l_res_body, 2000, 1);
        END IF;
    EXCEPTION WHEN OTHERS THEN RETURN 'ERROR: ' || SQLERRM;
    END gemini_chat;

    -- ========================================================================
    -- 2A. GPT_INVOICE_FROM_TEXT - Extract invoice from text
    -- ========================================================================
    FUNCTION gpt_invoice_from_text(p_api_key VARCHAR2, p_text CLOB, p_model VARCHAR2 DEFAULT 'gpt-4o-mini') RETURN CLOB IS
    BEGIN
        RETURN gpt_chat(p_api_key, get_invoice_prompt() || p_text, p_model);
    END gpt_invoice_from_text;

    -- ========================================================================
    -- 2B. GEMINI_INVOICE_FROM_TEXT - Extract invoice from text
    -- ========================================================================
    FUNCTION gemini_invoice_from_text(p_api_key VARCHAR2, p_text CLOB, p_model VARCHAR2 DEFAULT 'gemini-2.5-flash-lite') RETURN CLOB IS
    BEGIN
        RETURN gemini_chat(p_api_key, get_invoice_prompt() || p_text, p_model);
    END gemini_invoice_from_text;

    -- ========================================================================
    -- 3A. GPT_INVOICE_FROM_IMAGE - Extract invoice from image using GPT Vision
    -- ========================================================================
    FUNCTION gpt_invoice_from_image(p_api_key VARCHAR2, p_blob BLOB, p_mime_type VARCHAR2 DEFAULT 'image/png', p_model VARCHAR2 DEFAULT 'gpt-4o-mini') RETURN CLOB IS
        l_url VARCHAR2(500) := 'https://api.openai.com/v1/chat/completions';
        l_base64 CLOB;
        l_req_body CLOB;
        l_http_req UTL_HTTP.REQ;
        l_http_res UTL_HTTP.RESP;
        l_res_body CLOB := EMPTY_CLOB();
        l_buffer VARCHAR2(32767);
        l_offset PLS_INTEGER := 1;
        l_chunk_size PLS_INTEGER := 8000;
        l_req_length PLS_INTEGER;
    BEGIN
        IF p_blob IS NULL OR DBMS_LOB.GETLENGTH(p_blob) = 0 THEN RETURN 'ERROR: BLOB is empty'; END IF;
        
        l_base64 := blob_to_base64(p_blob);
        
        -- Build GPT Vision request
        DBMS_LOB.CREATETEMPORARY(l_req_body, TRUE);
        DBMS_LOB.APPEND(l_req_body, '{"model":"' || p_model || '","messages":[{"role":"user","content":[{"type":"text","text":"' || get_image_prompt() || '"},{"type":"image_url","image_url":{"url":"data:' || p_mime_type || ';base64,');
        DBMS_LOB.APPEND(l_req_body, l_base64);
        DBMS_LOB.APPEND(l_req_body, '"}}]}],"max_tokens":4096}');
        
        UTL_HTTP.SET_WALLET(g_wallet_path, g_wallet_pwd);
        UTL_HTTP.SET_TRANSFER_TIMEOUT(180);
        UTL_HTTP.SET_BODY_CHARSET('UTF-8');
        
        l_http_req := UTL_HTTP.BEGIN_REQUEST(l_url, 'POST', 'HTTP/1.1');
        UTL_HTTP.SET_HEADER(l_http_req, 'Authorization', 'Bearer ' || p_api_key);
        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Type', 'application/json');
        l_req_length := DBMS_LOB.GETLENGTH(l_req_body);
        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Length', l_req_length);
        
        WHILE l_offset <= l_req_length LOOP
            UTL_HTTP.WRITE_RAW(l_http_req, UTL_RAW.CAST_TO_RAW(DBMS_LOB.SUBSTR(l_req_body, l_chunk_size, l_offset)));
            l_offset := l_offset + l_chunk_size;
        END LOOP;
        
        l_http_res := UTL_HTTP.GET_RESPONSE(l_http_req);
        BEGIN
            LOOP UTL_HTTP.READ_TEXT(l_http_res, l_buffer); l_res_body := l_res_body || l_buffer; END LOOP;
        EXCEPTION WHEN UTL_HTTP.END_OF_BODY THEN UTL_HTTP.END_RESPONSE(l_http_res);
        END;
        
        DBMS_LOB.FREETEMPORARY(l_req_body);
        
        IF l_http_res.status_code = 200 THEN RETURN extract_gpt_text(l_res_body);
        ELSE RETURN 'ERROR ' || l_http_res.status_code || ': ' || DBMS_LOB.SUBSTR(l_res_body, 2000, 1);
        END IF;
    EXCEPTION WHEN OTHERS THEN RETURN 'ERROR: ' || SQLERRM;
    END gpt_invoice_from_image;

    -- ========================================================================
    -- 3B. GEMINI_INVOICE_FROM_IMAGE - Extract invoice from image using Gemini Vision
    -- ========================================================================
    FUNCTION gemini_invoice_from_image(p_api_key VARCHAR2, p_blob BLOB, p_mime_type VARCHAR2 DEFAULT 'image/png', p_model VARCHAR2 DEFAULT 'gemini-2.5-flash-lite') RETURN CLOB IS
        l_url VARCHAR2(500);
        l_base64 CLOB;
        l_req_body CLOB;
        l_http_req UTL_HTTP.REQ;
        l_http_res UTL_HTTP.RESP;
        l_res_body CLOB := EMPTY_CLOB();
        l_buffer VARCHAR2(32767);
        l_offset PLS_INTEGER := 1;
        l_chunk_size PLS_INTEGER := 8000;
        l_req_length PLS_INTEGER;
    BEGIN
        IF p_blob IS NULL OR DBMS_LOB.GETLENGTH(p_blob) = 0 THEN RETURN 'ERROR: BLOB is empty'; END IF;
        
        l_url := 'https://generativelanguage.googleapis.com/v1beta/models/' || p_model || ':generateContent?key=' || p_api_key;
        l_base64 := blob_to_base64(p_blob);
        
        -- Build Gemini Vision request
        DBMS_LOB.CREATETEMPORARY(l_req_body, TRUE);
        DBMS_LOB.APPEND(l_req_body, '{"contents":[{"parts":[{"text":"' || get_image_prompt() || '"},{"inline_data":{"mime_type":"' || p_mime_type || '","data":"');
        DBMS_LOB.APPEND(l_req_body, l_base64);
        DBMS_LOB.APPEND(l_req_body, '"}}]}]}');
        
        UTL_HTTP.SET_WALLET(g_wallet_path, g_wallet_pwd);
        UTL_HTTP.SET_TRANSFER_TIMEOUT(180);
        UTL_HTTP.SET_BODY_CHARSET('UTF-8');
        
        l_http_req := UTL_HTTP.BEGIN_REQUEST(l_url, 'POST', 'HTTP/1.1');
        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Type', 'application/json');
        l_req_length := DBMS_LOB.GETLENGTH(l_req_body);
        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Length', l_req_length);
        
        WHILE l_offset <= l_req_length LOOP
            UTL_HTTP.WRITE_RAW(l_http_req, UTL_RAW.CAST_TO_RAW(DBMS_LOB.SUBSTR(l_req_body, l_chunk_size, l_offset)));
            l_offset := l_offset + l_chunk_size;
        END LOOP;
        
        l_http_res := UTL_HTTP.GET_RESPONSE(l_http_req);
        BEGIN
            LOOP UTL_HTTP.READ_TEXT(l_http_res, l_buffer); l_res_body := l_res_body || l_buffer; END LOOP;
        EXCEPTION WHEN UTL_HTTP.END_OF_BODY THEN UTL_HTTP.END_RESPONSE(l_http_res);
        END;
        
        DBMS_LOB.FREETEMPORARY(l_req_body);
        
        IF l_http_res.status_code = 200 THEN RETURN extract_gemini_text(l_res_body);
        ELSE RETURN 'ERROR ' || l_http_res.status_code || ': ' || DBMS_LOB.SUBSTR(l_res_body, 2000, 1);
        END IF;
    EXCEPTION WHEN OTHERS THEN RETURN 'ERROR: ' || SQLERRM;
    END gemini_invoice_from_image;

    -- ========================================================================
    -- 4A. GPT_INVOICE_FROM_PDF - Extract invoice from PDF
    -- Uses CTX_DOC.POLICY_FILTER (Oracle Text) to extract text from PDF
    -- Then sends text to GPT for processing
    -- If Oracle Text not available or PDF is scanned → use Gemini instead
    -- ========================================================================
    FUNCTION gpt_invoice_from_pdf(p_api_key VARCHAR2, p_blob BLOB, p_model VARCHAR2 DEFAULT 'gpt-4o-mini') RETURN CLOB IS
        l_text CLOB;
        l_policy_name VARCHAR2(30) := 'PKG_AI_PDF_POLICY';
        l_policy_exists NUMBER := 0;
        l_ctx_available NUMBER := 0;
    BEGIN
        IF p_blob IS NULL OR DBMS_LOB.GETLENGTH(p_blob) = 0 THEN 
            RETURN '{"error": "BLOB is empty"}'; 
        END IF;
        
        -- Method 1: Try CTX_DOC.POLICY_FILTER (Oracle Text)
        -- Use dynamic SQL to avoid compile errors if Oracle Text not installed
        BEGIN
            -- Check if CTX_DOC package exists
            EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM all_objects WHERE object_name = ''CTX_DOC'' AND object_type = ''PACKAGE'' AND owner = ''CTXSYS'''
            INTO l_ctx_available;
            
            IF l_ctx_available > 0 THEN
                -- Check if policy exists using dynamic SQL
                BEGIN
                    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ctxsys.ctx_policies WHERE pol_name = :1'
                    INTO l_policy_exists USING l_policy_name;
                EXCEPTION
                    WHEN OTHERS THEN l_policy_exists := 0;
                END;
                
                -- Create policy if not exists
                IF l_policy_exists = 0 THEN
                    BEGIN
                        EXECUTE IMMEDIATE 'BEGIN CTX_DDL.CREATE_POLICY(:1, ''CTXSYS.AUTO_FILTER''); END;'
                        USING l_policy_name;
                    EXCEPTION
                        WHEN OTHERS THEN NULL; -- Policy creation failed, continue
                    END;
                END IF;
                
                -- Create temporary CLOB for output
                DBMS_LOB.CREATETEMPORARY(l_text, TRUE);
                
                -- Extract text from PDF using dynamic SQL
                BEGIN
                    EXECUTE IMMEDIATE 'BEGIN CTX_DOC.POLICY_FILTER(:1, :2, :3, TRUE); END;'
                    USING l_policy_name, p_blob, IN OUT l_text;
                    
                    -- Check if we got text
                    IF l_text IS NOT NULL AND DBMS_LOB.GETLENGTH(l_text) > 50 THEN
                        RETURN gpt_invoice_from_text(p_api_key, l_text, p_model);
                    END IF;
                EXCEPTION
                    WHEN OTHERS THEN NULL; -- CTX_DOC.POLICY_FILTER failed
                END;
            END IF;
            
        EXCEPTION
            WHEN OTHERS THEN NULL; -- Oracle Text not available
        END;
        
        -- Method 2: Try simple BLOB to CLOB conversion (for text-based PDFs)
        BEGIN
            l_text := blob_to_clob(p_blob);
            
            IF l_text IS NOT NULL AND DBMS_LOB.GETLENGTH(l_text) > 100 THEN
                -- Check if it looks like readable text (not binary PDF data)
                IF INSTR(l_text, '%PDF') = 0 
                   AND (INSTR(UPPER(l_text), 'INVOICE') > 0 
                        OR INSTR(UPPER(l_text), 'HOA DON') > 0
                        OR INSTR(UPPER(l_text), 'MST') > 0
                        OR INSTR(UPPER(l_text), 'TAX') > 0)
                THEN
                    RETURN gpt_invoice_from_text(p_api_key, l_text, p_model);
                END IF;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
        
        -- Fallback: PDF is scanned/image-based or all extraction methods failed
        RETURN '{"error": "GPT_PDF_EXTRACTION_FAILED", "message": "Could not extract text from PDF. The PDF may be scanned/image-based, or Oracle Text (CTX_DOC) is not available. Please use gemini_invoice_from_pdf() instead.", "suggestion": "pkg_ai.gemini_invoice_from_pdf(gemini_api_key, pdf_blob)"}';
        
    EXCEPTION 
        WHEN OTHERS THEN 
            RETURN '{"error": "' || REPLACE(SQLERRM, '"', '''') || '"}';
    END gpt_invoice_from_pdf;

    -- ========================================================================
    -- 4B. GEMINI_INVOICE_FROM_PDF - Extract invoice from PDF using Gemini Vision
    -- ========================================================================
    FUNCTION gemini_invoice_from_pdf(p_api_key VARCHAR2, p_blob BLOB, p_model VARCHAR2 DEFAULT 'gemini-2.5-flash-lite') RETURN CLOB IS
    BEGIN
        RETURN gemini_invoice_from_image(p_api_key, p_blob, 'application/pdf', p_model);
    END gemini_invoice_from_pdf;

    -- ========================================================================
    -- 5A. GPT_INVOICE_FROM_XML - Parse XML invoice using GPT
    -- ========================================================================
    FUNCTION gpt_invoice_from_xml(p_api_key VARCHAR2, p_xml CLOB, p_model VARCHAR2 DEFAULT 'gpt-4o-mini') RETURN CLOB IS
    BEGIN
        RETURN gpt_chat(p_api_key, get_xml_prompt() || p_xml, p_model);
    END gpt_invoice_from_xml;

    -- ========================================================================
    -- 5B. GPT_INVOICE_FROM_XML_BLOB - Parse XML invoice from BLOB using GPT
    -- ========================================================================
    FUNCTION gpt_invoice_from_xml_blob(p_api_key VARCHAR2, p_blob BLOB, p_model VARCHAR2 DEFAULT 'gpt-4o-mini') RETURN CLOB IS
        l_xml CLOB;
    BEGIN
        l_xml := blob_to_clob(p_blob);
        IF l_xml LIKE 'ERROR%' THEN RETURN l_xml; END IF;
        RETURN gpt_invoice_from_xml(p_api_key, l_xml, p_model);
    END gpt_invoice_from_xml_blob;

    -- ========================================================================
    -- 5C. GEMINI_INVOICE_FROM_XML - Parse XML invoice using Gemini
    -- ========================================================================
    FUNCTION gemini_invoice_from_xml(p_api_key VARCHAR2, p_xml CLOB, p_model VARCHAR2 DEFAULT 'gemini-2.5-flash-lite') RETURN CLOB IS
    BEGIN
        RETURN gemini_chat(p_api_key, get_xml_prompt() || p_xml, p_model);
    END gemini_invoice_from_xml;

    -- ========================================================================
    -- 5D. GEMINI_INVOICE_FROM_XML_BLOB - Parse XML invoice from BLOB using Gemini
    -- ========================================================================
    FUNCTION gemini_invoice_from_xml_blob(p_api_key VARCHAR2, p_blob BLOB, p_model VARCHAR2 DEFAULT 'gemini-2.5-flash-lite') RETURN CLOB IS
        l_xml CLOB;
    BEGIN
        l_xml := blob_to_clob(p_blob);
        IF l_xml LIKE 'ERROR%' THEN RETURN l_xml; END IF;
        RETURN gemini_invoice_from_xml(p_api_key, l_xml, p_model);
    END gemini_invoice_from_xml_blob;

    -- ========================================================================
    -- 6A. GPT_INVOICE_FROM_AUDIO - Extract invoice from audio using Whisper + GPT
    -- Step 1: Whisper transcribe audio to text
    -- Step 2: GPT process text to extract invoice
    -- ========================================================================
    FUNCTION gpt_invoice_from_audio(p_api_key VARCHAR2, p_audio_blob BLOB, p_audio_type VARCHAR2 DEFAULT 'audio/webm') RETURN CLOB IS
        l_url         VARCHAR2(500) := 'https://api.openai.com/v1/audio/transcriptions';
        l_boundary    VARCHAR2(50) := '----WebKitFormBoundary' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF');
        l_http_req    UTL_HTTP.REQ;
        l_http_res    UTL_HTTP.RESP;
        l_res_body    CLOB := EMPTY_CLOB();
        l_buffer      VARCHAR2(32767);
        l_body_start  RAW(32767);
        l_body_end    RAW(32767);
        l_audio_raw   RAW(32767);
        l_offset      PLS_INTEGER := 1;
        l_chunk_size  PLS_INTEGER := 8000;
        l_audio_len   PLS_INTEGER;
        l_ext         VARCHAR2(20);
        l_transcript  CLOB;
        l_content_len PLS_INTEGER;
    BEGIN
        IF p_audio_blob IS NULL OR DBMS_LOB.GETLENGTH(p_audio_blob) = 0 THEN 
            RETURN 'ERROR: Audio BLOB is empty'; 
        END IF;
        
        -- Determine file extension from mime type
        l_ext := CASE 
            WHEN p_audio_type LIKE '%webm%' THEN 'webm'
            WHEN p_audio_type LIKE '%mp3%' THEN 'mp3'
            WHEN p_audio_type LIKE '%wav%' THEN 'wav'
            WHEN p_audio_type LIKE '%m4a%' THEN 'm4a'
            WHEN p_audio_type LIKE '%ogg%' THEN 'ogg'
            ELSE 'webm'
        END;
        
        -- Build multipart body parts
        l_body_start := UTL_RAW.CAST_TO_RAW(
            '--' || l_boundary || CHR(13) || CHR(10) ||
            'Content-Disposition: form-data; name="file"; filename="audio.' || l_ext || '"' || CHR(13) || CHR(10) ||
            'Content-Type: ' || p_audio_type || CHR(13) || CHR(10) || CHR(13) || CHR(10)
        );
        
        l_body_end := UTL_RAW.CAST_TO_RAW(
            CHR(13) || CHR(10) ||
            '--' || l_boundary || CHR(13) || CHR(10) ||
            'Content-Disposition: form-data; name="model"' || CHR(13) || CHR(10) || CHR(13) || CHR(10) ||
            'whisper-1' || CHR(13) || CHR(10) ||
            '--' || l_boundary || CHR(13) || CHR(10) ||
            'Content-Disposition: form-data; name="language"' || CHR(13) || CHR(10) || CHR(13) || CHR(10) ||
            'vi' || CHR(13) || CHR(10) ||
            '--' || l_boundary || '--' || CHR(13) || CHR(10)
        );
        
        l_audio_len := DBMS_LOB.GETLENGTH(p_audio_blob);
        l_content_len := UTL_RAW.LENGTH(l_body_start) + l_audio_len + UTL_RAW.LENGTH(l_body_end);
        
        UTL_HTTP.SET_WALLET(g_wallet_path, g_wallet_pwd);
        UTL_HTTP.SET_TRANSFER_TIMEOUT(180);
        
        l_http_req := UTL_HTTP.BEGIN_REQUEST(l_url, 'POST', 'HTTP/1.1');
        UTL_HTTP.SET_HEADER(l_http_req, 'Authorization', 'Bearer ' || p_api_key);
        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Type', 'multipart/form-data; boundary=' || l_boundary);
        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Length', l_content_len);
        
        -- Write body start
        UTL_HTTP.WRITE_RAW(l_http_req, l_body_start);
        
        -- Write audio blob in chunks
        WHILE l_offset <= l_audio_len LOOP
            l_audio_raw := DBMS_LOB.SUBSTR(p_audio_blob, LEAST(l_chunk_size, l_audio_len - l_offset + 1), l_offset);
            UTL_HTTP.WRITE_RAW(l_http_req, l_audio_raw);
            l_offset := l_offset + l_chunk_size;
        END LOOP;
        
        -- Write body end
        UTL_HTTP.WRITE_RAW(l_http_req, l_body_end);
        
        -- Get response
        l_http_res := UTL_HTTP.GET_RESPONSE(l_http_req);
        BEGIN
            LOOP UTL_HTTP.READ_TEXT(l_http_res, l_buffer); l_res_body := l_res_body || l_buffer; END LOOP;
        EXCEPTION WHEN UTL_HTTP.END_OF_BODY THEN UTL_HTTP.END_RESPONSE(l_http_res);
        END;
        
        IF l_http_res.status_code = 200 THEN
            -- Extract transcript from response
            DECLARE
                l_json JSON_OBJECT_T := JSON_OBJECT_T(l_res_body);
            BEGIN
                l_transcript := l_json.GET_STRING('text');
            EXCEPTION WHEN OTHERS THEN
                l_transcript := l_res_body;
            END;
            
            -- Step 2: Process transcript with GPT to extract invoice
            RETURN gpt_invoice_from_text(p_api_key, l_transcript);
        ELSE
            RETURN 'ERROR Whisper ' || l_http_res.status_code || ': ' || DBMS_LOB.SUBSTR(l_res_body, 2000, 1);
        END IF;
        
    EXCEPTION WHEN OTHERS THEN 
        RETURN 'ERROR: ' || SQLERRM;
    END gpt_invoice_from_audio;

    -- ========================================================================
    -- 6B. GEMINI_INVOICE_FROM_AUDIO - Extract invoice from audio using Gemini
    -- ========================================================================
    FUNCTION gemini_invoice_from_audio(p_api_key VARCHAR2, p_audio_blob BLOB, p_audio_type VARCHAR2 DEFAULT 'audio/webm', p_model VARCHAR2 DEFAULT 'gemini-2.5-flash-lite') RETURN CLOB IS
        l_url VARCHAR2(500);
        l_base64 CLOB;
        l_req_body CLOB;
        l_http_req UTL_HTTP.REQ;
        l_http_res UTL_HTTP.RESP;
        l_res_body CLOB := EMPTY_CLOB();
        l_buffer VARCHAR2(32767);
        l_offset PLS_INTEGER := 1;
        l_chunk_size PLS_INTEGER := 8000;
        l_req_length PLS_INTEGER;
    BEGIN
        IF p_audio_blob IS NULL OR DBMS_LOB.GETLENGTH(p_audio_blob) = 0 THEN RETURN 'ERROR: Audio BLOB is empty'; END IF;
        
        l_url := 'https://generativelanguage.googleapis.com/v1beta/models/' || p_model || ':generateContent?key=' || p_api_key;
        l_base64 := blob_to_base64(p_audio_blob);
        
        -- Build Gemini request with audio
        DBMS_LOB.CREATETEMPORARY(l_req_body, TRUE);
        DBMS_LOB.APPEND(l_req_body, '{"contents":[{"parts":[{"text":"' || get_audio_prompt() || '"},{"inline_data":{"mime_type":"' || p_audio_type || '","data":"');
        DBMS_LOB.APPEND(l_req_body, l_base64);
        DBMS_LOB.APPEND(l_req_body, '"}}]}]}');
        
        UTL_HTTP.SET_WALLET(g_wallet_path, g_wallet_pwd);
        UTL_HTTP.SET_TRANSFER_TIMEOUT(180);
        UTL_HTTP.SET_BODY_CHARSET('UTF-8');
        
        l_http_req := UTL_HTTP.BEGIN_REQUEST(l_url, 'POST', 'HTTP/1.1');
        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Type', 'application/json');
        l_req_length := DBMS_LOB.GETLENGTH(l_req_body);
        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Length', l_req_length);
        
        WHILE l_offset <= l_req_length LOOP
            UTL_HTTP.WRITE_RAW(l_http_req, UTL_RAW.CAST_TO_RAW(DBMS_LOB.SUBSTR(l_req_body, l_chunk_size, l_offset)));
            l_offset := l_offset + l_chunk_size;
        END LOOP;
        
        l_http_res := UTL_HTTP.GET_RESPONSE(l_http_req);
        BEGIN
            LOOP UTL_HTTP.READ_TEXT(l_http_res, l_buffer); l_res_body := l_res_body || l_buffer; END LOOP;
        EXCEPTION WHEN UTL_HTTP.END_OF_BODY THEN UTL_HTTP.END_RESPONSE(l_http_res);
        END;
        
        DBMS_LOB.FREETEMPORARY(l_req_body);
        
        IF l_http_res.status_code = 200 THEN RETURN extract_gemini_text(l_res_body);
        ELSE RETURN 'ERROR ' || l_http_res.status_code || ': ' || DBMS_LOB.SUBSTR(l_res_body, 2000, 1);
        END IF;
    EXCEPTION WHEN OTHERS THEN RETURN 'ERROR: ' || SQLERRM;
    END gemini_invoice_from_audio;

END pkg_ai;
/

SHOW ERRORS;
