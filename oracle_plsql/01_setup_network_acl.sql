-- ============================================================================
-- ORACLE PL/SQL - Setup Network ACL cho phép gọi API bên ngoài
-- Author: AI Assistant
-- Date: 2025-12-30
-- Description: Cấu hình quyền network để Oracle có thể gọi HTTP/HTTPS APIs
-- ============================================================================

-- Chạy script này với quyền SYS hoặc DBA

-- 1. Tạo ACL (Access Control List) cho phép truy cập mạng
BEGIN
    -- Xóa ACL cũ nếu tồn tại
    BEGIN
        DBMS_NETWORK_ACL_ADMIN.DROP_ACL(acl => 'ai_api_acl.xml');
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
    
    -- Tạo ACL mới
    DBMS_NETWORK_ACL_ADMIN.CREATE_ACL(
        acl          => 'ai_api_acl.xml',
        description  => 'ACL cho phep goi API ChatGPT va Gemini',
        principal    => 'YOUR_SCHEMA_NAME',  -- Thay đổi thành schema của bạn
        is_grant     => TRUE,
        privilege    => 'connect'
    );
    
    -- Thêm quyền resolve
    DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(
        acl       => 'ai_api_acl.xml',
        principal => 'YOUR_SCHEMA_NAME',  -- Thay đổi thành schema của bạn
        is_grant  => TRUE,
        privilege => 'resolve'
    );
    
    -- Gán ACL cho host OpenAI
    DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL(
        acl  => 'ai_api_acl.xml',
        host => 'api.openai.com',
        lower_port => 443,
        upper_port => 443
    );
    
    -- Gán ACL cho host Google Gemini
    DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL(
        acl  => 'ai_api_acl.xml',
        host => 'generativelanguage.googleapis.com',
        lower_port => 443,
        upper_port => 443
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('ACL da duoc tao thanh cong!');
END;
/

-- 2. Kiểm tra ACL đã được tạo
SELECT acl, host, lower_port, upper_port 
FROM dba_network_acls 
WHERE acl LIKE '%ai_api%';

-- 3. Kiểm tra quyền của user
SELECT acl, principal, privilege, is_grant 
FROM dba_network_acl_privileges 
WHERE acl LIKE '%ai_api%';
