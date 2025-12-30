-- ============================================================================
-- ORACLE PL/SQL - Script Chẩn đoán lỗi HTTP Request
-- Author: AI Assistant
-- Date: 2025-12-30
-- Description: Kiểm tra và debug các lỗi kết nối HTTP/HTTPS
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

-- ============================================================================
-- BƯỚC 1: Kiểm tra ACL đã được cấu hình chưa
-- ============================================================================
PROMPT === KIEM TRA ACL ===
SELECT host, lower_port, upper_port, acl 
FROM dba_network_acls 
WHERE host IN ('api.openai.com', 'generativelanguage.googleapis.com', '*');

-- Kiểm tra quyền của user hiện tại
SELECT acl, principal, privilege, is_grant 
FROM dba_network_acl_privileges 
WHERE principal = USER;

-- ============================================================================
-- BƯỚC 2: Test kết nối HTTP cơ bản (không SSL)
-- ============================================================================
PROMPT === TEST KET NOI HTTP CO BAN ===
DECLARE
    v_req   UTL_HTTP.REQ;
    v_resp  UTL_HTTP.RESP;
BEGIN
    -- Test với một URL HTTP đơn giản
    v_req := UTL_HTTP.BEGIN_REQUEST('http://httpbin.org/get', 'GET');
    v_resp := UTL_HTTP.GET_RESPONSE(v_req);
    DBMS_OUTPUT.PUT_LINE('HTTP Test: SUCCESS - Status: ' || v_resp.status_code);
    UTL_HTTP.END_RESPONSE(v_resp);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('HTTP Test: FAILED');
        DBMS_OUTPUT.PUT_LINE('Error Code: ' || SQLCODE);
        DBMS_OUTPUT.PUT_LINE('Error Message: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Detailed: ' || UTL_HTTP.GET_DETAILED_SQLERRM);
END;
/

-- ============================================================================
-- BƯỚC 3: Test kết nối HTTPS với Wallet
-- ============================================================================
PROMPT === TEST KET NOI HTTPS VOI WALLET ===
DECLARE
    v_req   UTL_HTTP.REQ;
    v_resp  UTL_HTTP.RESP;
    v_wallet_path VARCHAR2(500) := 'file:/u01/https/getCert/wallet';
    v_wallet_pwd  VARCHAR2(100) := 'YPb3pu1jrHnBOmVkEfOHxIQJs3tyHD15uiXhMmsE';
BEGIN
    -- Set wallet
    UTL_HTTP.SET_WALLET(v_wallet_path, v_wallet_pwd);
    DBMS_OUTPUT.PUT_LINE('Wallet set successfully: ' || v_wallet_path);
    
    -- Test HTTPS connection
    v_req := UTL_HTTP.BEGIN_REQUEST('https://www.google.com', 'GET');
    v_resp := UTL_HTTP.GET_RESPONSE(v_req);
    DBMS_OUTPUT.PUT_LINE('HTTPS Test (Google): SUCCESS - Status: ' || v_resp.status_code);
    UTL_HTTP.END_RESPONSE(v_resp);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('HTTPS Test: FAILED');
        DBMS_OUTPUT.PUT_LINE('Error Code: ' || SQLCODE);
        DBMS_OUTPUT.PUT_LINE('Error Message: ' || SQLERRM);
        BEGIN
            DBMS_OUTPUT.PUT_LINE('Detailed: ' || UTL_HTTP.GET_DETAILED_SQLERRM);
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
END;
/

-- ============================================================================
-- BƯỚC 4: Test kết nối đến OpenAI và Gemini
-- ============================================================================
PROMPT === TEST KET NOI DEN OPENAI ===
DECLARE
    v_req   UTL_HTTP.REQ;
    v_resp  UTL_HTTP.RESP;
    v_wallet_path VARCHAR2(500) := 'file:/u01/https/getCert/wallet';
    v_wallet_pwd  VARCHAR2(100) := 'YPb3pu1jrHnBOmVkEfOHxIQJs3tyHD15uiXhMmsE';
BEGIN
    UTL_HTTP.SET_WALLET(v_wallet_path, v_wallet_pwd);
    UTL_HTTP.SET_TRANSFER_TIMEOUT(30);
    
    v_req := UTL_HTTP.BEGIN_REQUEST('https://api.openai.com', 'GET');
    v_resp := UTL_HTTP.GET_RESPONSE(v_req);
    DBMS_OUTPUT.PUT_LINE('OpenAI Connection: SUCCESS - Status: ' || v_resp.status_code);
    UTL_HTTP.END_RESPONSE(v_resp);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OpenAI Connection: FAILED');
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        BEGIN
            DBMS_OUTPUT.PUT_LINE('Detailed: ' || UTL_HTTP.GET_DETAILED_SQLERRM);
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
END;
/

PROMPT === TEST KET NOI DEN GEMINI ===
DECLARE
    v_req   UTL_HTTP.REQ;
    v_resp  UTL_HTTP.RESP;
    v_wallet_path VARCHAR2(500) := 'file:/u01/https/getCert/wallet';
    v_wallet_pwd  VARCHAR2(100) := 'YPb3pu1jrHnBOmVkEfOHxIQJs3tyHD15uiXhMmsE';
BEGIN
    UTL_HTTP.SET_WALLET(v_wallet_path, v_wallet_pwd);
    UTL_HTTP.SET_TRANSFER_TIMEOUT(30);
    
    v_req := UTL_HTTP.BEGIN_REQUEST('https://generativelanguage.googleapis.com', 'GET');
    v_resp := UTL_HTTP.GET_RESPONSE(v_req);
    DBMS_OUTPUT.PUT_LINE('Gemini Connection: SUCCESS - Status: ' || v_resp.status_code);
    UTL_HTTP.END_RESPONSE(v_resp);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Gemini Connection: FAILED');
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        BEGIN
            DBMS_OUTPUT.PUT_LINE('Detailed: ' || UTL_HTTP.GET_DETAILED_SQLERRM);
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
END;
/

-- ============================================================================
-- BƯỚC 5: Kiểm tra Wallet tồn tại và có certificates
-- ============================================================================
PROMPT === KIEM TRA WALLET ===
DECLARE
    v_wallet_path VARCHAR2(500) := 'file:/u01/https/getCert/wallet';
    v_wallet_pwd  VARCHAR2(100) := 'YPb3pu1jrHnBOmVkEfOHxIQJs3tyHD15uiXhMmsE';
BEGIN
    -- Thử set wallet
    UTL_HTTP.SET_WALLET(v_wallet_path, v_wallet_pwd);
    DBMS_OUTPUT.PUT_LINE('Wallet loaded successfully!');
    DBMS_OUTPUT.PUT_LINE('Path: ' || v_wallet_path);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Wallet load FAILED!');
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('=== HUONG DAN SUA LOI ===');
        DBMS_OUTPUT.PUT_LINE('1. Kiem tra thu muc wallet ton tai: /u01/https/getCert/wallet');
        DBMS_OUTPUT.PUT_LINE('2. Kiem tra file cwallet.sso hoac ewallet.p12 trong thu muc');
        DBMS_OUTPUT.PUT_LINE('3. Kiem tra quyen doc cua Oracle user tren thu muc wallet');
END;
/

-- ============================================================================
-- BƯỚC 6: Test với HTTPS Proxy (nếu có)
-- ============================================================================
PROMPT === CAU HINH PROXY (NEU CAN) ===
-- Nếu server của bạn cần proxy để ra internet, uncomment và chỉnh sửa code dưới:
/*
BEGIN
    UTL_HTTP.SET_PROXY('http://your-proxy-server:port', 'localhost');
    DBMS_OUTPUT.PUT_LINE('Proxy configured');
END;
/
*/

-- ============================================================================
-- TOM TAT CAC LOI PHO BIEN
-- ============================================================================
/*
LOI ORA-29273: HTTP request failed
Nguyen nhan:
1. Wallet khong dung hoac khong co SSL certificates
   => Kiem tra lai wallet path va password
   => Dam bao wallet chua CA certificates cua OpenAI/Google

2. ACL chua duoc cau hinh
   => Chay script 01_setup_network_acl.sql voi quyen DBA

3. Firewall chan ket noi
   => Kiem tra server co the ket noi den:
      - api.openai.com:443
      - generativelanguage.googleapis.com:443

4. DNS khong resolve duoc
   => Kiem tra: nslookup api.openai.com

5. Can proxy de ra internet
   => Su dung UTL_HTTP.SET_PROXY

LOI ORA-29024: Certificate validation failure
   => Wallet thieu CA certificates
   => Can import DigiCert, GlobalSign certificates vao wallet

LOI ORA-12535: TNS:operation timed out
   => Firewall chan hoac network cham
   => Tang timeout: UTL_HTTP.SET_TRANSFER_TIMEOUT(120)
*/

-- ============================================================================
-- SCRIPT KIEM TRA NHANH
-- ============================================================================
PROMPT === KIEM TRA NHANH ===
BEGIN
    DBMS_OUTPUT.PUT_LINE('Current User: ' || USER);
    DBMS_OUTPUT.PUT_LINE('Current Schema: ' || SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'));
    DBMS_OUTPUT.PUT_LINE('Database Name: ' || SYS_CONTEXT('USERENV', 'DB_NAME'));
    DBMS_OUTPUT.PUT_LINE('Server Host: ' || SYS_CONTEXT('USERENV', 'SERVER_HOST'));
END;
/
