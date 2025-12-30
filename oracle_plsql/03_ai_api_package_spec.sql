-- ============================================================================
-- ORACLE PL/SQL - AI API Package Specification
-- Author: AI Assistant
-- Date: 2025-12-30
-- Description: Package specification cho việc gọi ChatGPT và Gemini APIs
-- ============================================================================

CREATE OR REPLACE PACKAGE pkg_ai_api AS
    
    -- ========================================================================
    -- CONSTANTS
    -- ========================================================================
    
    -- API Endpoints
    gc_openai_endpoint    CONSTANT VARCHAR2(200) := 'https://api.openai.com/v1/chat/completions';
    gc_gemini_endpoint    CONSTANT VARCHAR2(200) := 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
    
    -- Default timeout (seconds)
    gc_default_timeout    CONSTANT NUMBER := 60;
    
    -- Max response size
    gc_max_response_size  CONSTANT NUMBER := 32767;
    
    -- ========================================================================
    -- TYPES
    -- ========================================================================
    
    -- Type để lưu kết quả API response
    TYPE t_api_response IS RECORD (
        status_code     NUMBER,
        response_text   CLOB,
        error_message   VARCHAR2(4000),
        execution_time  NUMBER
    );
    
    -- ========================================================================
    -- PROCEDURES & FUNCTIONS
    -- ========================================================================
    
    /**
     * Gọi ChatGPT API (OpenAI)
     * @param p_api_key      API Key của OpenAI
     * @param p_prompt       Câu hỏi/prompt gửi đến ChatGPT
     * @param p_model        Model sử dụng (default: gpt-3.5-turbo)
     * @param p_max_tokens   Số tokens tối đa cho response
     * @param p_temperature  Độ sáng tạo (0-2, default 0.7)
     * @return               Response từ ChatGPT
     */
    FUNCTION call_chatgpt(
        p_api_key       IN VARCHAR2,
        p_prompt        IN CLOB,
        p_model         IN VARCHAR2 DEFAULT 'gpt-4o-mini',
        p_max_tokens    IN NUMBER DEFAULT 2000,
        p_temperature   IN NUMBER DEFAULT 0.7
    ) RETURN t_api_response;
    
    /**
     * Gọi Gemini API (Google)
     * @param p_api_key      API Key của Google
     * @param p_prompt       Câu hỏi/prompt gửi đến Gemini
     * @param p_model        Model sử dụng (default: gemini-pro)
     * @return               Response từ Gemini
     */
    FUNCTION call_gemini(
        p_api_key       IN VARCHAR2,
        p_prompt        IN CLOB,
        p_model         IN VARCHAR2 DEFAULT 'gemini-flash-latest'
    ) RETURN t_api_response;
    
    /**
     * Procedure wrapper để gọi ChatGPT và lấy text response
     * @param p_api_key      API Key
     * @param p_prompt       Prompt
     * @param p_response     OUT - Response text
     * @param p_error_msg    OUT - Error message nếu có
     */
    PROCEDURE get_chatgpt_response(
        p_api_key       IN VARCHAR2,
        p_prompt        IN CLOB,
        p_response      OUT CLOB,
        p_error_msg     OUT VARCHAR2
    );
    
    /**
     * Procedure wrapper để gọi Gemini và lấy text response
     * @param p_api_key      API Key
     * @param p_prompt       Prompt
     * @param p_response     OUT - Response text
     * @param p_error_msg    OUT - Error message nếu có
     */
    PROCEDURE get_gemini_response(
        p_api_key       IN VARCHAR2,
        p_prompt        IN CLOB,
        p_response      OUT CLOB,
        p_error_msg     OUT VARCHAR2
    );
    
    /**
     * Extract text content từ ChatGPT JSON response
     * @param p_json_response   JSON response từ API
     * @return                  Extracted text
     */
    FUNCTION extract_chatgpt_content(
        p_json_response IN CLOB
    ) RETURN CLOB;
    
    /**
     * Extract text content từ Gemini JSON response
     * @param p_json_response   JSON response từ API
     * @return                  Extracted text
     */
    FUNCTION extract_gemini_content(
        p_json_response IN CLOB
    ) RETURN CLOB;
    
    /**
     * Test connection đến các API endpoints
     * @param p_test_openai    Test OpenAI endpoint
     * @param p_test_gemini    Test Gemini endpoint
     */
    PROCEDURE test_connections(
        p_test_openai   IN BOOLEAN DEFAULT TRUE,
        p_test_gemini   IN BOOLEAN DEFAULT TRUE
    );
    
END pkg_ai_api;
/

SHOW ERRORS PACKAGE pkg_ai_api;
