-- ============================================================================
-- ORACLE PL/SQL - Ví dụ sử dụng AI API Package
-- Author: AI Assistant
-- Date: 2025-12-30
-- Description: Các ví dụ thực tế về cách sử dụng package gọi ChatGPT và Gemini
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

-- ============================================================================
-- VÍ DỤ 1: Gọi ChatGPT đơn giản
-- ============================================================================
DECLARE
    v_response      CLOB;
    v_error_msg     VARCHAR2(4000);
    v_api_key       VARCHAR2(200) := 'YOUR_OPENAI_API_KEY';
BEGIN
    pkg_ai_api.get_chatgpt_response(
        p_api_key   => v_api_key,
        p_prompt    => 'Xin chào! Bạn có thể giới thiệu về Oracle Database không?',
        p_response  => v_response,
        p_error_msg => v_error_msg
    );
    
    IF v_error_msg IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('=== ChatGPT Response ===');
        DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_response, 4000, 1));
    ELSE
        DBMS_OUTPUT.PUT_LINE('Error: ' || v_error_msg);
    END IF;
END;
/

-- ============================================================================
-- VÍ DỤ 2: Gọi Gemini đơn giản
-- ============================================================================
DECLARE
    v_response      CLOB;
    v_error_msg     VARCHAR2(4000);
    v_api_key       VARCHAR2(200) := 'YOUR_GEMINI_API_KEY';
BEGIN
    pkg_ai_api.get_gemini_response(
        p_api_key   => v_api_key,
        p_prompt    => 'Hãy giải thích PL/SQL là gì?',
        p_response  => v_response,
        p_error_msg => v_error_msg
    );
    
    IF v_error_msg IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('=== Gemini Response ===');
        DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_response, 4000, 1));
    ELSE
        DBMS_OUTPUT.PUT_LINE('Error: ' || v_error_msg);
    END IF;
END;
/

-- ============================================================================
-- VÍ DỤ 3: Sử dụng Function trực tiếp với đầy đủ options
-- ============================================================================
DECLARE
    v_api_response  pkg_ai_api.t_api_response;
    v_api_key       VARCHAR2(200) := 'YOUR_OPENAI_API_KEY';
BEGIN
    v_api_response := pkg_ai_api.call_chatgpt(
        p_api_key     => v_api_key,
        p_prompt      => 'Viết một đoạn code PL/SQL tính tổng các số từ 1 đến 100',
        p_model       => 'gpt-4',           -- Sử dụng GPT-4
        p_max_tokens  => 1000,
        p_temperature => 0.3                 -- Ít sáng tạo, chính xác hơn
    );
    
    DBMS_OUTPUT.PUT_LINE('Status Code: ' || v_api_response.status_code);
    DBMS_OUTPUT.PUT_LINE('Execution Time: ' || v_api_response.execution_time || ' seconds');
    
    IF v_api_response.status_code = 200 THEN
        DBMS_OUTPUT.PUT_LINE('=== Full Response ===');
        DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_api_response.response_text, 4000, 1));
        
        DBMS_OUTPUT.PUT_LINE('=== Extracted Content ===');
        DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(
            pkg_ai_api.extract_chatgpt_content(v_api_response.response_text), 
            4000, 1
        ));
    ELSE
        DBMS_OUTPUT.PUT_LINE('Error: ' || v_api_response.error_message);
    END IF;
END;
/

-- ============================================================================
-- VÍ DỤ 4: So sánh response từ cả ChatGPT và Gemini
-- ============================================================================
DECLARE
    v_chatgpt_response  CLOB;
    v_gemini_response   CLOB;
    v_chatgpt_error     VARCHAR2(4000);
    v_gemini_error      VARCHAR2(4000);
    v_openai_key        VARCHAR2(200) := 'YOUR_OPENAI_API_KEY';
    v_gemini_key        VARCHAR2(200) := 'YOUR_GEMINI_API_KEY';
    v_prompt            CLOB := 'Giải thích ngắn gọn về ACID trong database?';
BEGIN
    -- Gọi ChatGPT
    pkg_ai_api.get_chatgpt_response(
        p_api_key   => v_openai_key,
        p_prompt    => v_prompt,
        p_response  => v_chatgpt_response,
        p_error_msg => v_chatgpt_error
    );
    
    -- Gọi Gemini
    pkg_ai_api.get_gemini_response(
        p_api_key   => v_gemini_key,
        p_prompt    => v_prompt,
        p_response  => v_gemini_response,
        p_error_msg => v_gemini_error
    );
    
    -- In kết quả
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('PROMPT: ' || DBMS_LOB.SUBSTR(v_prompt, 200, 1));
    DBMS_OUTPUT.PUT_LINE('============================================');
    
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== CHATGPT RESPONSE ===');
    IF v_chatgpt_error IS NULL THEN
        DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_chatgpt_response, 4000, 1));
    ELSE
        DBMS_OUTPUT.PUT_LINE('Error: ' || v_chatgpt_error);
    END IF;
    
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== GEMINI RESPONSE ===');
    IF v_gemini_error IS NULL THEN
        DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_gemini_response, 4000, 1));
    ELSE
        DBMS_OUTPUT.PUT_LINE('Error: ' || v_gemini_error);
    END IF;
END;
/

-- ============================================================================
-- VÍ DỤ 5: Lưu response vào table
-- ============================================================================

-- Tạo table để lưu history
CREATE TABLE ai_api_history (
    id              NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    api_provider    VARCHAR2(20),
    prompt          CLOB,
    response        CLOB,
    status_code     NUMBER,
    error_message   VARCHAR2(4000),
    created_at      TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- Procedure lưu và gọi API
CREATE OR REPLACE PROCEDURE save_ai_response(
    p_provider      IN VARCHAR2,  -- 'CHATGPT' hoặc 'GEMINI'
    p_api_key       IN VARCHAR2,
    p_prompt        IN CLOB
) AS
    v_response      CLOB;
    v_error_msg     VARCHAR2(4000);
    v_status_code   NUMBER := 200;
BEGIN
    IF UPPER(p_provider) = 'CHATGPT' THEN
        pkg_ai_api.get_chatgpt_response(
            p_api_key   => p_api_key,
            p_prompt    => p_prompt,
            p_response  => v_response,
            p_error_msg => v_error_msg
        );
    ELSIF UPPER(p_provider) = 'GEMINI' THEN
        pkg_ai_api.get_gemini_response(
            p_api_key   => p_api_key,
            p_prompt    => p_prompt,
            p_response  => v_response,
            p_error_msg => v_error_msg
        );
    ELSE
        v_error_msg := 'Invalid provider. Use CHATGPT or GEMINI';
        v_status_code := -1;
    END IF;
    
    IF v_error_msg IS NOT NULL THEN
        v_status_code := -1;
    END IF;
    
    -- Lưu vào history table
    INSERT INTO ai_api_history (api_provider, prompt, response, status_code, error_message)
    VALUES (UPPER(p_provider), p_prompt, v_response, v_status_code, v_error_msg);
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Response saved to ai_api_history table');
END;
/

-- Sử dụng
BEGIN
    save_ai_response(
        p_provider  => 'CHATGPT',
        p_api_key   => 'YOUR_OPENAI_API_KEY',
        p_prompt    => 'Viết một stored procedure đơn giản trong Oracle'
    );
END;
/

-- Query history
SELECT id, api_provider, 
       DBMS_LOB.SUBSTR(prompt, 100, 1) AS prompt_preview,
       DBMS_LOB.SUBSTR(response, 200, 1) AS response_preview,
       status_code, created_at
FROM ai_api_history
ORDER BY created_at DESC;

-- ============================================================================
-- VÍ DỤ 6: Test kết nối
-- ============================================================================
BEGIN
    pkg_ai_api.test_connections(
        p_test_openai => TRUE,
        p_test_gemini => TRUE
    );
END;
/

-- ============================================================================
-- VÍ DỤ 7: Xử lý OCR Invoice với AI
-- ============================================================================
CREATE OR REPLACE PROCEDURE process_invoice_with_ai(
    p_raw_ocr_text  IN CLOB,
    p_api_key       IN VARCHAR2,
    p_provider      IN VARCHAR2 DEFAULT 'GEMINI',
    p_result        OUT CLOB,
    p_error         OUT VARCHAR2
) AS
    v_prompt CLOB;
BEGIN
    -- Tạo prompt cho việc extract thông tin hóa đơn
    v_prompt := 'Bạn là chuyên gia phân tích hóa đơn VAT Việt Nam. 
Hãy trích xuất thông tin từ văn bản OCR sau và trả về JSON với format:
{
    "invoice_number": "",
    "invoice_date": "",
    "seller_name": "",
    "seller_tax_code": "",
    "buyer_name": "",
    "buyer_tax_code": "",
    "total_amount": "",
    "vat_amount": "",
    "grand_total": ""
}

Văn bản OCR:
' || p_raw_ocr_text;

    IF UPPER(p_provider) = 'CHATGPT' THEN
        pkg_ai_api.get_chatgpt_response(
            p_api_key   => p_api_key,
            p_prompt    => v_prompt,
            p_response  => p_result,
            p_error_msg => p_error
        );
    ELSE
        pkg_ai_api.get_gemini_response(
            p_api_key   => p_api_key,
            p_prompt    => v_prompt,
            p_response  => p_result,
            p_error_msg => p_error
        );
    END IF;
END;
/

-- Test invoice processing
DECLARE
    v_ocr_text  CLOB := 'HÓA ĐƠN GIÁ TRỊ GIA TĂNG
Ký hiệu: AA/22E
Số: 0001234
Ngày: 30/12/2025
Đơn vị bán: CÔNG TY TNHH ABC
Mã số thuế: 0123456789
Đơn vị mua: CÔNG TY XYZ
MST: 9876543210
Tổng tiền hàng: 10,000,000
Thuế GTGT (10%): 1,000,000
Tổng thanh toán: 11,000,000';
    
    v_result    CLOB;
    v_error     VARCHAR2(4000);
BEGIN
    process_invoice_with_ai(
        p_raw_ocr_text  => v_ocr_text,
        p_api_key       => 'YOUR_GEMINI_API_KEY',
        p_provider      => 'GEMINI',
        p_result        => v_result,
        p_error         => v_error
    );
    
    IF v_error IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('Invoice Data (JSON):');
        DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_result, 4000, 1));
    ELSE
        DBMS_OUTPUT.PUT_LINE('Error: ' || v_error);
    END IF;
END;
/
