-- ============================================================================
-- ORACLE PL/SQL - AI API Package Body (Fixed Version)
-- Author: AI Assistant
-- Date: 2025-12-30
-- Description: Package body implementation cho việc gọi ChatGPT và Gemini APIs
-- Based on working code template
-- ============================================================================

CREATE OR REPLACE PACKAGE BODY pkg_ai_api AS

    -- ========================================================================
    -- PRIVATE VARIABLES
    -- ========================================================================
    g_wallet_path     VARCHAR2(500) := 'file:/u01/https/getCert/wallet';
    g_wallet_password VARCHAR2(100) := 'YPb3pu1jrHnBOmVkEfOHxIQJs3tyHD15uiXhMmsE';
    
    -- ========================================================================
    -- PUBLIC FUNCTIONS & PROCEDURES
    -- ========================================================================
    
    /**
     * Gọi ChatGPT API - Based on working template
     */
    FUNCTION call_chatgpt(
        p_api_key       IN VARCHAR2,
        p_prompt        IN CLOB,
        p_model         IN VARCHAR2 DEFAULT 'gpt-4o-mini',
        p_max_tokens    IN NUMBER DEFAULT 2000,
        p_temperature   IN NUMBER DEFAULT 0.7
    ) RETURN t_api_response IS
        l_url           VARCHAR2(500) := gc_openai_endpoint;
        l_http_req      UTL_HTTP.REQ;
        l_http_res      UTL_HTTP.RESP;
        l_req_body      VARCHAR2(32767);
        l_res_buff      VARCHAR2(32767);
        l_response      t_api_response;
        l_res_body      CLOB := EMPTY_CLOB();
        l_start_time    TIMESTAMP;
    BEGIN
        l_start_time := SYSTIMESTAMP;
        
        -- Build request body using JSON_OBJECT (Oracle native JSON)
        l_req_body := JSON_OBJECT(
            'model' VALUE p_model,
            'messages' VALUE JSON_ARRAY(
                JSON_OBJECT(
                    'role' VALUE 'user',
                    'content' VALUE p_prompt
                )
            )
        );
        
        -- Setup HTTP with wallet
        UTL_HTTP.SET_WALLET(
            path     => g_wallet_path,
            password => g_wallet_password
        );
        UTL_HTTP.SET_TRANSFER_TIMEOUT(gc_default_timeout);
        UTL_HTTP.SET_BODY_CHARSET('UTF-8');
        
        -- Begin request
        l_http_req := UTL_HTTP.BEGIN_REQUEST(
            l_url,
            'POST',
            'HTTP/1.1'
        );
        
        -- Set headers
        UTL_HTTP.SET_HEADER(l_http_req, 'Authorization', 'Bearer ' || p_api_key);
        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Type', 'application/json');
        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Length', LENGTHB(l_req_body));
        
        -- Write request body directly
        UTL_HTTP.WRITE_RAW(l_http_req, UTL_RAW.CAST_TO_RAW(l_req_body));
        
        -- Get response
        l_http_res := UTL_HTTP.GET_RESPONSE(l_http_req);
        l_response.status_code := l_http_res.status_code;
        
        -- Read response body
        BEGIN
            LOOP
                UTL_HTTP.READ_TEXT(l_http_res, l_res_buff);
                l_res_body := l_res_body || l_res_buff;
            END LOOP;
        EXCEPTION
            WHEN UTL_HTTP.END_OF_BODY THEN
                UTL_HTTP.END_RESPONSE(l_http_res);
        END;
        
        l_response.response_text := l_res_body;
        l_response.execution_time := EXTRACT(SECOND FROM (SYSTIMESTAMP - l_start_time));
        
        RETURN l_response;
        
    EXCEPTION
        WHEN OTHERS THEN
            l_response.status_code := -99;
            l_response.error_message := 'ChatGPT API Error: ' || SQLERRM;
            -- Try to get response body for debugging
            BEGIN
                IF l_http_res.status_code IS NOT NULL THEN
                    UTL_HTTP.END_RESPONSE(l_http_res);
                END IF;
            EXCEPTION WHEN OTHERS THEN NULL;
            END;
            RETURN l_response;
    END call_chatgpt;
    
    /**
     * Gọi Gemini API
     */
    FUNCTION call_gemini(
        p_api_key       IN VARCHAR2,
        p_prompt        IN CLOB,
        p_model         IN VARCHAR2 DEFAULT 'gemini-flash-latest'
    ) RETURN t_api_response IS
        l_url           VARCHAR2(500);
        l_http_req      UTL_HTTP.REQ;
        l_http_res      UTL_HTTP.RESP;
        l_req_body      VARCHAR2(32767);
        l_res_buff      VARCHAR2(32767);
        l_response      t_api_response;
        l_res_body      CLOB := EMPTY_CLOB();
        l_start_time    TIMESTAMP;
    BEGIN
        l_start_time := SYSTIMESTAMP;
        
        -- Build URL with API key
        l_url := 'https://generativelanguage.googleapis.com/v1beta/models/' 
                 || p_model || ':generateContent?key=' || p_api_key;
        
        -- Build request body using JSON_OBJECT
        l_req_body := JSON_OBJECT(
            'contents' VALUE JSON_ARRAY(
                JSON_OBJECT(
                    'parts' VALUE JSON_ARRAY(
                        JSON_OBJECT('text' VALUE p_prompt)
                    )
                )
            ),
            'generationConfig' VALUE JSON_OBJECT(
                'temperature' VALUE 0.7,
                'maxOutputTokens' VALUE 2048
            )
        );
        
        -- Setup HTTP with wallet
        UTL_HTTP.SET_WALLET(
            path     => g_wallet_path,
            password => g_wallet_password
        );
        UTL_HTTP.SET_TRANSFER_TIMEOUT(gc_default_timeout);
        UTL_HTTP.SET_BODY_CHARSET('UTF-8');
        
        -- Begin request
        l_http_req := UTL_HTTP.BEGIN_REQUEST(
            l_url,
            'POST',
            'HTTP/1.1'
        );
        
        -- Set headers
        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Type', 'application/json');
        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Length', LENGTHB(l_req_body));
        
        -- Write request body directly
        UTL_HTTP.WRITE_RAW(l_http_req, UTL_RAW.CAST_TO_RAW(l_req_body));
        
        -- Get response
        l_http_res := UTL_HTTP.GET_RESPONSE(l_http_req);
        l_response.status_code := l_http_res.status_code;
        
        -- Read response body
        BEGIN
            LOOP
                UTL_HTTP.READ_TEXT(l_http_res, l_res_buff);
                l_res_body := l_res_body || l_res_buff;
            END LOOP;
        EXCEPTION
            WHEN UTL_HTTP.END_OF_BODY THEN
                UTL_HTTP.END_RESPONSE(l_http_res);
        END;
        
        l_response.response_text := l_res_body;
        l_response.execution_time := EXTRACT(SECOND FROM (SYSTIMESTAMP - l_start_time));
        
        RETURN l_response;
        
    EXCEPTION
        WHEN OTHERS THEN
            l_response.status_code := -99;
            l_response.error_message := 'Gemini API Error: ' || SQLERRM;
            BEGIN
                IF l_http_res.status_code IS NOT NULL THEN
                    UTL_HTTP.END_RESPONSE(l_http_res);
                END IF;
            EXCEPTION WHEN OTHERS THEN NULL;
            END;
            RETURN l_response;
    END call_gemini;
    
    /**
     * Extract content từ ChatGPT response using JSON_OBJECT_T
     */
    FUNCTION extract_chatgpt_content(
        p_json_response IN CLOB
    ) RETURN CLOB IS
        l_res_obj     JSON_OBJECT_T;
        l_choices_arr JSON_ARRAY_T;
        l_choice_el   JSON_ELEMENT_T;
        l_node_obj    JSON_OBJECT_T;
        l_message_obj JSON_OBJECT_T;
        l_content     CLOB;
    BEGIN
        l_res_obj := JSON_OBJECT_T(p_json_response);
        IF l_res_obj.IS_OBJECT THEN
            l_choices_arr := l_res_obj.GET_ARRAY('choices');
            FOR i IN 0 .. l_choices_arr.GET_SIZE - 1 LOOP
                l_choice_el := l_choices_arr.GET(i);
                IF l_choice_el.IS_OBJECT THEN
                    l_node_obj    := TREAT(l_choice_el AS JSON_OBJECT_T);
                    l_message_obj := l_node_obj.GET_OBJECT('message');
                    l_content     := l_message_obj.GET_STRING('content');
                END IF;
            END LOOP;
        END IF;
        RETURN l_content;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'Error extracting content: ' || SQLERRM;
    END extract_chatgpt_content;
    
    /**
     * Extract content từ Gemini response using JSON_OBJECT_T
     */
    FUNCTION extract_gemini_content(
        p_json_response IN CLOB
    ) RETURN CLOB IS
        l_res_obj       JSON_OBJECT_T;
        l_candidates    JSON_ARRAY_T;
        l_candidate     JSON_OBJECT_T;
        l_content_obj   JSON_OBJECT_T;
        l_parts_arr     JSON_ARRAY_T;
        l_part_obj      JSON_OBJECT_T;
        l_content       CLOB;
    BEGIN
        l_res_obj := JSON_OBJECT_T(p_json_response);
        IF l_res_obj.IS_OBJECT THEN
            l_candidates := l_res_obj.GET_ARRAY('candidates');
            IF l_candidates.GET_SIZE > 0 THEN
                l_candidate   := TREAT(l_candidates.GET(0) AS JSON_OBJECT_T);
                l_content_obj := l_candidate.GET_OBJECT('content');
                l_parts_arr   := l_content_obj.GET_ARRAY('parts');
                IF l_parts_arr.GET_SIZE > 0 THEN
                    l_part_obj := TREAT(l_parts_arr.GET(0) AS JSON_OBJECT_T);
                    l_content  := l_part_obj.GET_STRING('text');
                END IF;
            END IF;
        END IF;
        RETURN l_content;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'Error extracting content: ' || SQLERRM;
    END extract_gemini_content;
    
    /**
     * Procedure wrapper cho ChatGPT
     */
    PROCEDURE get_chatgpt_response(
        p_api_key       IN VARCHAR2,
        p_prompt        IN CLOB,
        p_response      OUT CLOB,
        p_error_msg     OUT VARCHAR2
    ) IS
        l_api_response t_api_response;
        l_raw_response VARCHAR2(4000);
    BEGIN
        l_api_response := call_chatgpt(
            p_api_key => p_api_key,
            p_prompt  => p_prompt
        );
        
        IF l_api_response.status_code = 200 THEN
            p_response := extract_chatgpt_content(l_api_response.response_text);
            p_error_msg := NULL;
        ELSE
            p_response := l_api_response.response_text;
            BEGIN
                l_raw_response := DBMS_LOB.SUBSTR(l_api_response.response_text, 1000, 1);
            EXCEPTION WHEN OTHERS THEN
                l_raw_response := 'Unable to read response';
            END;
            p_error_msg := 'Status: ' || l_api_response.status_code 
                          || ' - ' || NVL(l_api_response.error_message, 'Unknown error')
                          || ' | Raw: ' || l_raw_response;
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            p_response := NULL;
            p_error_msg := 'Exception: ' || SQLERRM;
    END get_chatgpt_response;
    
    /**
     * Procedure wrapper cho Gemini
     */
    PROCEDURE get_gemini_response(
        p_api_key       IN VARCHAR2,
        p_prompt        IN CLOB,
        p_response      OUT CLOB,
        p_error_msg     OUT VARCHAR2
    ) IS
        l_api_response t_api_response;
        l_raw_response VARCHAR2(4000);
    BEGIN
        l_api_response := call_gemini(
            p_api_key => p_api_key,
            p_prompt  => p_prompt
        );
        
        IF l_api_response.status_code = 200 THEN
            p_response := extract_gemini_content(l_api_response.response_text);
            p_error_msg := NULL;
        ELSE
            p_response := l_api_response.response_text;
            BEGIN
                l_raw_response := DBMS_LOB.SUBSTR(l_api_response.response_text, 1000, 1);
            EXCEPTION WHEN OTHERS THEN
                l_raw_response := 'Unable to read response';
            END;
            p_error_msg := 'Status: ' || l_api_response.status_code 
                          || ' - ' || NVL(l_api_response.error_message, 'Unknown error')
                          || ' | Raw: ' || l_raw_response;
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            p_response := NULL;
            p_error_msg := 'Exception: ' || SQLERRM;
    END get_gemini_response;
    
    /**
     * Test connections
     */
    PROCEDURE test_connections(
        p_test_openai   IN BOOLEAN DEFAULT TRUE,
        p_test_gemini   IN BOOLEAN DEFAULT TRUE
    ) IS
        l_http_request  UTL_HTTP.REQ;
        l_http_response UTL_HTTP.RESP;
    BEGIN
        UTL_HTTP.SET_WALLET(g_wallet_path, g_wallet_password);
        
        IF p_test_openai THEN
            BEGIN
                l_http_request := UTL_HTTP.BEGIN_REQUEST('https://api.openai.com', 'GET');
                l_http_response := UTL_HTTP.GET_RESPONSE(l_http_request);
                DBMS_OUTPUT.PUT_LINE('OpenAI Connection: SUCCESS (Status: ' || l_http_response.status_code || ')');
                UTL_HTTP.END_RESPONSE(l_http_response);
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('OpenAI Connection: FAILED - ' || SQLERRM);
            END;
        END IF;
        
        IF p_test_gemini THEN
            BEGIN
                l_http_request := UTL_HTTP.BEGIN_REQUEST('https://generativelanguage.googleapis.com', 'GET');
                l_http_response := UTL_HTTP.GET_RESPONSE(l_http_request);
                DBMS_OUTPUT.PUT_LINE('Gemini Connection: SUCCESS (Status: ' || l_http_response.status_code || ')');
                UTL_HTTP.END_RESPONSE(l_http_response);
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Gemini Connection: FAILED - ' || SQLERRM);
            END;
        END IF;
        
    END test_connections;
    
END pkg_ai_api;
/

SHOW ERRORS PACKAGE BODY pkg_ai_api;
