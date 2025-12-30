-- ============================================================================
-- ORACLE PL/SQL - Setup Oracle Wallet cho HTTPS connections
-- Author: AI Assistant
-- Date: 2025-12-30
-- Description: Cấu hình Oracle Wallet để sử dụng SSL/TLS khi gọi HTTPS APIs
-- ============================================================================

-- CÁCH 1: Sử dụng Oracle Wallet Manager (GUI) - Khuyến nghị
-- 1. Mở Oracle Wallet Manager
-- 2. Tạo wallet mới tại: /u01/app/oracle/wallet (hoặc thư mục bạn chọn)
-- 3. Import các CA certificates cần thiết (DigiCert, GlobalSign, etc.)
-- 4. Lưu wallet với Auto Login enabled

-- CÁCH 2: Sử dụng orapki command line
-- Mở terminal và chạy các lệnh sau:

/*
-- Tạo thư mục wallet
mkdir -p /u01/app/oracle/wallet

-- Tạo wallet mới
orapki wallet create -wallet /u01/app/oracle/wallet -pwd YourWalletPassword123 -auto_login

-- Download và import certificate của OpenAI
-- Lấy certificate từ: https://api.openai.com
openssl s_client -connect api.openai.com:443 -showcerts </dev/null 2>/dev/null | \
openssl x509 -outform PEM > openai_cert.pem

orapki wallet add -wallet /u01/app/oracle/wallet -trusted_cert -cert openai_cert.pem -pwd YourWalletPassword123

-- Download và import certificate của Google Gemini
openssl s_client -connect generativelanguage.googleapis.com:443 -showcerts </dev/null 2>/dev/null | \
openssl x509 -outform PEM > gemini_cert.pem

orapki wallet add -wallet /u01/app/oracle/wallet -trusted_cert -cert gemini_cert.pem -pwd YourWalletPassword123

-- Kiểm tra certificates trong wallet
orapki wallet display -wallet /u01/app/oracle/wallet
*/

-- CÁCH 3: Cấu hình trong PL/SQL (Oracle 19c+)
-- Sử dụng DBMS_NETWORK_ACL_ADMIN để set wallet

BEGIN
    -- Set wallet location cho UTL_HTTP
    UTL_HTTP.SET_WALLET('file:/u01/app/oracle/wallet', 'YourWalletPassword123');
    DBMS_OUTPUT.PUT_LINE('Wallet da duoc cau hinh thanh cong!');
END;
/

-- Lưu ý quan trọng:
-- 1. Thay đổi đường dẫn wallet phù hợp với hệ thống của bạn
-- 2. Đảm bảo Oracle có quyền đọc thư mục wallet
-- 3. Với Oracle Cloud, wallet thường được cấu hình sẵn
-- 4. Nếu dùng Autonomous Database, không cần setup wallet riêng
