-- ============================================================================
-- DEBUG TEST - Xem chi tiết response từ API
-- ============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED;

-- Test ChatGPT với debug output
DECLARE
    v_api_response  pkg_ai_api.t_api_response;
    v_api_key       VARCHAR2(500) := 'YOUR_OPENAI_API_KEY';
BEGIN
    v_api_response := pkg_ai_api.call_chatgpt(
        p_api_key     => v_api_key,
        p_prompt      => 'Hello',
        p_model       => 'gpt-3.5-turbo',
        p_max_tokens  => 100,
        p_temperature => 0.7
    );
    
    DBMS_OUTPUT.PUT_LINE('===========================================');
    DBMS_OUTPUT.PUT_LINE('Status Code: ' || v_api_response.status_code);
    DBMS_OUTPUT.PUT_LINE('Error Message: ' || NVL(v_api_response.error_message, 'None'));
    DBMS_OUTPUT.PUT_LINE('Execution Time: ' || v_api_response.execution_time || ' seconds');
    DBMS_OUTPUT.PUT_LINE('===========================================');
    DBMS_OUTPUT.PUT_LINE('RAW RESPONSE (first 4000 chars):');
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_api_response.response_text, 4000, 1));
    DBMS_OUTPUT.PUT_LINE('===========================================');
END;
/

-- Test Gemini với debug output
DECLARE
    v_api_response  pkg_ai_api.t_api_response;
    v_api_key       VARCHAR2(200) := 'YOUR_GEMINI_API_KEY';
BEGIN
    v_api_response := pkg_ai_api.call_gemini(
        p_api_key     => v_api_key,
        p_prompt      => 'Hello',
        p_model       => 'gemini-pro'
    );
    
    DBMS_OUTPUT.PUT_LINE('===========================================');
    DBMS_OUTPUT.PUT_LINE('Status Code: ' || v_api_response.status_code);
    DBMS_OUTPUT.PUT_LINE('Error Message: ' || NVL(v_api_response.error_message, 'None'));
    DBMS_OUTPUT.PUT_LINE('Execution Time: ' || v_api_response.execution_time || ' seconds');
    DBMS_OUTPUT.PUT_LINE('===========================================');
    DBMS_OUTPUT.PUT_LINE('RAW RESPONSE (first 4000 chars):');
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_api_response.response_text, 4000, 1));
    DBMS_OUTPUT.PUT_LINE('===========================================');
END;
/
