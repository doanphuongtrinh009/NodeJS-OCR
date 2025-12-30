-- ============================================================================
-- TEST ĐẦY ĐỦ TẤT CẢ FUNCTIONS TRONG PKG_AI
-- Sắp xếp theo: GPT trước, Gemini sau
-- Compatible with PL/SQL Developer
-- ============================================================================
SET SERVEROUTPUT ON SIZE 1000000;
BEGIN DBMS_OUTPUT.ENABLE(1000000); END;
/

-- API Keys (thay bằng key của bạn)
-- GEMINI: YOUR_GEMINI_API_KEY
-- GPT: YOUR_OPENAI_API_KEY

-- Attachment IDs: Image=770, PDF=771, XML=772, Audio=774

-- ############################################################################
-- PHẦN 1: GPT FUNCTIONS
-- ############################################################################

-- ============================================================================
-- TEST 1A: gpt_chat - Chat cơ bản với GPT
-- ============================================================================
DECLARE
    v_result CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[TEST 1A] gpt_chat');
    v_result := pkg_ai.gpt_chat(
        p_api_key => 'YOUR_OPENAI_API_KEY',
        p_prompt  => '1+1=?'
    );
    DBMS_OUTPUT.PUT_LINE('Response: ' || DBMS_LOB.SUBSTR(v_result, 500, 1));
END;
/

-- ============================================================================
-- TEST 2A: gpt_invoice_from_text - Trích xuất hóa đơn từ text
-- ============================================================================
DECLARE
    v_text CLOB;
    v_result CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[TEST 2A] gpt_invoice_from_text');
    v_text := 'INVOICE No: 0005678 Date: 25/12/2025
Seller: ABC Tax: 0111222333 Buyer: XYZ Tax: 0444555666
1. Service - 10000000 VAT: 1000000 Total: 11000000';
    v_result := pkg_ai.gpt_invoice_from_text('YOUR_OPENAI_API_KEY', v_text);
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_result, 2000, 1));
END;
/

-- ============================================================================
-- TEST 3A: gpt_invoice_from_image - Trích xuất hóa đơn từ ảnh (att_id=770)
-- ============================================================================
DECLARE
    v_blob   BLOB;
    v_result CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[TEST 3A] gpt_invoice_from_image (att_id=770)');
    SELECT content INTO v_blob FROM attachments WHERE att_id = 770;
    v_result := pkg_ai.gpt_invoice_from_image('YOUR_OPENAI_API_KEY', v_blob, 'image/png');
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_result, 2000, 1));
EXCEPTION
    WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('ERROR: att_id=770 not found');
END;
/

-- ============================================================================
-- TEST 4A: gpt_invoice_from_pdf - Trích xuất hóa đơn từ PDF (att_id=771)
-- Uses CTX_DOC.POLICY_FILTER to extract text, then sends to GPT
-- ============================================================================
DECLARE
    v_blob   BLOB;
    v_result CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[TEST 4A] gpt_invoice_from_pdf (att_id=771)');
    SELECT content INTO v_blob FROM attachments WHERE att_id = 771;
    v_result := pkg_ai.gpt_invoice_from_pdf('YOUR_OPENAI_API_KEY', v_blob);
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_result, 2000, 1));
EXCEPTION
    WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('ERROR: att_id=771 not found');
END;
/

-- ============================================================================
-- TEST 5A: gpt_invoice_from_xml - Parse XML trực tiếp (CLOB)
-- ============================================================================
DECLARE
    v_xml CLOB;
    v_result CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[TEST 5A] gpt_invoice_from_xml (direct CLOB)');
    v_xml := '<Invoice><InvoiceNumber>123</InvoiceNumber><Seller><Name>ABC</Name><TaxCode>0123456789</TaxCode></Seller><GrandTotal>55000000</GrandTotal></Invoice>';
    v_result := pkg_ai.gpt_invoice_from_xml('YOUR_OPENAI_API_KEY', v_xml);
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_result, 2000, 1));
END;
/

-- ============================================================================
-- TEST 5B: gpt_invoice_from_xml_blob - Parse XML từ BLOB (att_id=772)
-- ============================================================================
DECLARE
    v_blob   BLOB;
    v_result CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[TEST 5B] gpt_invoice_from_xml_blob (att_id=772)');
    SELECT content INTO v_blob FROM attachments WHERE att_id = 772;
    v_result := pkg_ai.gpt_invoice_from_xml_blob('YOUR_OPENAI_API_KEY', v_blob);
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_result, 2000, 1));
EXCEPTION
    WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('ERROR: att_id=772 not found');
END;
/

-- ============================================================================
-- TEST 6A: gpt_invoice_from_audio - Trích xuất hóa đơn từ audio (att_id=774)
-- ============================================================================
DECLARE
    v_audio  BLOB;
    v_result CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[TEST 6A] gpt_invoice_from_audio (att_id=774)');
    SELECT content INTO v_audio FROM attachments WHERE att_id = 774;
    v_result := pkg_ai.gpt_invoice_from_audio('YOUR_OPENAI_API_KEY', v_audio, 'audio/webm');
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_result, 2000, 1));
EXCEPTION
    WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('ERROR: att_id=774 not found');
END;
/

-- ############################################################################
-- PHẦN 2: GEMINI FUNCTIONS
-- ############################################################################

-- ============================================================================
-- TEST 1B: gemini_chat - Chat cơ bản với Gemini
-- ============================================================================
DECLARE
    v_result CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[TEST 1B] gemini_chat');
    v_result := pkg_ai.gemini_chat(
        p_api_key => 'YOUR_GEMINI_API_KEY',
        p_prompt  => 'Hello! Reply briefly.'
    );
    DBMS_OUTPUT.PUT_LINE('Response: ' || DBMS_LOB.SUBSTR(v_result, 500, 1));
END;
/

-- ============================================================================
-- TEST 2B: gemini_invoice_from_text - Trích xuất hóa đơn từ text
-- ============================================================================
DECLARE
    v_text CLOB;
    v_result CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[TEST 2B] gemini_invoice_from_text');
    v_text := 'INVOICE No: 0001234 Date: 30/12/2025
SELLER: ABC LTD Tax: 0123456789
BUYER: XYZ Tax: 9876543210
1. Laptop - 50000000
VAT 10%: 5000000 Total: 55000000';
    v_result := pkg_ai.gemini_invoice_from_text('YOUR_GEMINI_API_KEY', v_text);
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_result, 2000, 1));
END;
/

-- ============================================================================
-- TEST 3B: gemini_invoice_from_image - Trích xuất hóa đơn từ ảnh (att_id=770)
-- ============================================================================
DECLARE
    v_blob   BLOB;
    v_result CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[TEST 3B] gemini_invoice_from_image (att_id=770)');
    SELECT content INTO v_blob FROM attachments WHERE att_id = 770;
    v_result := pkg_ai.gemini_invoice_from_image('YOUR_GEMINI_API_KEY', v_blob, 'image/png');
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_result, 2000, 1));
EXCEPTION
    WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('ERROR: att_id=770 not found');
END;
/

-- ============================================================================
-- TEST 4B: gemini_invoice_from_pdf - Trích xuất hóa đơn từ PDF (att_id=771)
-- ============================================================================
DECLARE
    v_blob   BLOB;
    v_result CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[TEST 4B] gemini_invoice_from_pdf (att_id=771)');
    SELECT content INTO v_blob FROM attachments WHERE att_id = 771;
    v_result := pkg_ai.gemini_invoice_from_pdf('YOUR_GEMINI_API_KEY', v_blob);
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_result, 2000, 1));
EXCEPTION
    WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('ERROR: att_id=771 not found');
END;
/

-- ============================================================================
-- TEST 5C: gemini_invoice_from_xml - Parse XML trực tiếp (CLOB)
-- ============================================================================
DECLARE
    v_xml CLOB;
    v_result CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[TEST 5C] gemini_invoice_from_xml (direct CLOB)');
    v_xml := '<Invoice><InvoiceNumber>456</InvoiceNumber><Seller><Name>XYZ Corp</Name><TaxCode>9876543210</TaxCode></Seller><GrandTotal>99000000</GrandTotal></Invoice>';
    v_result := pkg_ai.gemini_invoice_from_xml('YOUR_GEMINI_API_KEY', v_xml);
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_result, 2000, 1));
END;
/

-- ============================================================================
-- TEST 5D: gemini_invoice_from_xml_blob - Parse XML từ BLOB (att_id=772)
-- ============================================================================
DECLARE
    v_blob   BLOB;
    v_result CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[TEST 5D] gemini_invoice_from_xml_blob (att_id=772)');
    SELECT content INTO v_blob FROM attachments WHERE att_id = 772;
    v_result := pkg_ai.gemini_invoice_from_xml_blob('YOUR_GEMINI_API_KEY', v_blob);
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_result, 2000, 1));
EXCEPTION
    WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('ERROR: att_id=772 not found');
END;
/

-- ============================================================================
-- TEST 6B: gemini_invoice_from_audio - Trích xuất hóa đơn từ audio (att_id=774)
-- ============================================================================
DECLARE
    v_audio  BLOB;
    v_result CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[TEST 6B] gemini_invoice_from_audio (att_id=774)');
    SELECT content INTO v_audio FROM attachments WHERE att_id = 774;
    v_result := pkg_ai.gemini_invoice_from_audio('YOUR_GEMINI_API_KEY', v_audio, 'audio/webm');
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_result, 2000, 1));
EXCEPTION
    WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('ERROR: att_id=774 not found');
END;
/

-- ############################################################################
-- PHẦN 3: UTILITY FUNCTIONS
-- ############################################################################

-- ============================================================================
-- TEST U1: blob_to_clob - Chuyển đổi BLOB sang CLOB
-- ============================================================================
DECLARE
    v_blob BLOB;
    v_clob CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[TEST U1] blob_to_clob');
    v_blob := UTL_RAW.CAST_TO_RAW('Text in BLOB');
    v_clob := pkg_ai.blob_to_clob(v_blob);
    DBMS_OUTPUT.PUT_LINE('Result: ' || v_clob);
END;
/

-- ============================================================================
-- TEST U2: blob_to_base64 - Chuyển đổi BLOB sang Base64
-- ============================================================================
DECLARE
    v_blob   BLOB;
    v_base64 CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[TEST U2] blob_to_base64');
    v_blob := UTL_RAW.CAST_TO_RAW('Hello');
    v_base64 := pkg_ai.blob_to_base64(v_blob);
    DBMS_OUTPUT.PUT_LINE('Base64: ' || v_base64);
END;
/

-- ============================================================================
-- TEST U3: clean_json - Loại bỏ markdown wrapper từ JSON
-- ============================================================================
DECLARE
    v_dirty_json CLOB;
    v_clean_json CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[TEST U3] clean_json');
    v_dirty_json := '```json
{"name": "Test", "value": 123}
```';
    v_clean_json := pkg_ai.clean_json(v_dirty_json);
    DBMS_OUTPUT.PUT_LINE('Before: ' || DBMS_LOB.SUBSTR(v_dirty_json, 100, 1));
    DBMS_OUTPUT.PUT_LINE('After:  ' || v_clean_json);
END;
/

-- ############################################################################
-- KẾT THÚC TEST
-- ############################################################################
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('=== TEST COMPLETED ===');
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('SUMMARY:');
    DBMS_OUTPUT.PUT_LINE('- GPT Functions:    1A, 2A, 3A, 4A, 5A, 5B, 6A');
    DBMS_OUTPUT.PUT_LINE('- Gemini Functions: 1B, 2B, 3B, 4B, 5C, 5D, 6B');
    DBMS_OUTPUT.PUT_LINE('- Utility Functions: U1, U2, U3');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Attachment IDs: Image=770, PDF=771, XML=772, Audio=774');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('PDF EXTRACTION:');
    DBMS_OUTPUT.PUT_LINE('  4A: GPT + CTX_DOC.POLICY_FILTER (Oracle Text)');
    DBMS_OUTPUT.PUT_LINE('  4B: Gemini Vision (built-in OCR)');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('NOTE: All JSON outputs are CLEAN (no markdown wrapper)');
    DBMS_OUTPUT.PUT_LINE('      Ready for INSERT into ERP system!');
END;
/
