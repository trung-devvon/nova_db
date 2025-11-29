-- ============================================
-- NOVAORM DATABASE SCHEMA
-- Thiết kế cho hệ thống authentication & authorization bảo mật
-- Tương thích với Prisma ORM và PostgreSQL
-- ============================================

-- Tạo database (chạy riêng nếu chưa có)
-- CREATE DATABASE novaorm;

-- Kết nối vào database
-- \c novaorm;

-- Extension UUID cho PostgreSQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Extension để hash password (pgcrypto)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- FUNCTION: Tự động cập nhật updated_at
-- Dùng để trigger tự động update timestamp
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ============================================
-- TABLE: roles
-- Quản lý các vai trò trong hệ thống (Admin, User, Moderator...)
-- ============================================
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    is_system BOOLEAN DEFAULT false, -- Role hệ thống không được xóa
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: permissions
-- Định nghĩa các quyền hạn cụ thể (read:user, write:post, delete:comment...)
-- ============================================
CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL, -- Format: action:resource (VD: read:users)
    description TEXT,
    resource VARCHAR(50) NOT NULL, -- users, posts, comments...
    action VARCHAR(20) NOT NULL, -- read, write, delete, update...
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: role_permissions
-- Bảng trung gian: Liên kết Role với Permission (Many-to-Many)
-- ============================================
CREATE TABLE role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (role_id, permission_id)
);

-- ============================================
-- TABLE: users
-- Lưu thông tin người dùng và thông tin authentication
-- ============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL, -- Bcrypt hash
    full_name VARCHAR(100),
    avatar_url TEXT,
    phone VARCHAR(20),
    
    -- Thông tin authentication
    is_email_verified BOOLEAN DEFAULT false,
    email_verified_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    is_locked BOOLEAN DEFAULT false,
    locked_reason TEXT,
    locked_at TIMESTAMP,
    
    -- Security
    failed_login_attempts INTEGER DEFAULT 0,
    last_failed_login_at TIMESTAMP,
    last_login_at TIMESTAMP,
    last_login_ip VARCHAR(45), -- Hỗ trợ IPv6
    
    -- Role - denormalization để query nhanh hơn
    role_id UUID NOT NULL REFERENCES roles(id),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP -- Soft delete
);

-- ============================================
-- TABLE: user_permissions
-- Quyền đặc biệt cho từng user (override role permissions)
-- ============================================
CREATE TABLE user_permissions (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    is_granted BOOLEAN DEFAULT true, -- true: grant, false: revoke
    granted_by UUID REFERENCES users(id), -- Ai cấp quyền này
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP, -- Quyền tạm thời
    PRIMARY KEY (user_id, permission_id)
);

-- ============================================
-- TABLE: sessions
-- Quản lý phiên đăng nhập (HTTP-only cookie)
-- ============================================
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL, -- Token lưu trong cookie
    
    -- Thông tin thiết bị
    user_agent TEXT,
    ip_address VARCHAR(45),
    device_type VARCHAR(50), -- mobile, desktop, tablet
    
    -- Security
    is_valid BOOLEAN DEFAULT true,
    expires_at TIMESTAMP NOT NULL,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: refresh_tokens
-- Token để refresh access token (Rotation strategy)
-- ============================================
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) UNIQUE NOT NULL, -- Hash của refresh token
    
    -- Token family để phát hiện reuse attack
    token_family UUID NOT NULL,
    parent_token_id UUID REFERENCES refresh_tokens(id),
    
    -- Security
    is_revoked BOOLEAN DEFAULT false,
    revoked_at TIMESTAMP,
    revoked_reason TEXT,
    
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    used_at TIMESTAMP -- Khi token được dùng để refresh
);

-- ============================================
-- TABLE: password_reset_tokens
-- Token để reset mật khẩu (gửi qua email)
-- ============================================
CREATE TABLE password_reset_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) UNIQUE NOT NULL,
    
    is_used BOOLEAN DEFAULT false,
    used_at TIMESTAMP,
    
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: email_verification_tokens
-- Token xác thực email
-- ============================================
CREATE TABLE email_verification_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL, -- Email cần verify
    
    is_used BOOLEAN DEFAULT false,
    used_at TIMESTAMP,
    
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: audit_logs
-- Ghi lại mọi hành động quan trọng (security & compliance)
-- ============================================
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Thông tin action
    action VARCHAR(100) NOT NULL, -- login, logout, create_user, update_permission...
    resource_type VARCHAR(50), -- users, roles, permissions...
    resource_id UUID, -- ID của resource bị tác động
    
    -- Chi tiết
    old_values JSONB, -- Giá trị cũ (cho update)
    new_values JSONB, -- Giá trị mới
    metadata JSONB, -- Thông tin bổ sung
    
    -- Context
    ip_address VARCHAR(45),
    user_agent TEXT,
    
    -- Status
    status VARCHAR(20) DEFAULT 'success', -- success, failed, error
    error_message TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: rate_limits
-- Giới hạn số lần request (chống brute force & DDoS)
-- ============================================
CREATE TABLE rate_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    identifier VARCHAR(255) NOT NULL, -- IP hoặc user_id
    action VARCHAR(50) NOT NULL, -- login, register, reset_password...
    
    attempt_count INTEGER DEFAULT 1,
    first_attempt_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_attempt_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    is_blocked BOOLEAN DEFAULT false,
    blocked_until TIMESTAMP,
    
    UNIQUE(identifier, action)
);

-- ============================================
-- INDEXES: Tối ưu hóa query performance
-- ============================================

-- Users indexes
CREATE INDEX idx_users_email ON users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_username ON users(username) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_role_id ON users(role_id);
CREATE INDEX idx_users_is_active ON users(is_active) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_created_at ON users(created_at DESC);

-- Sessions indexes (query theo user_id và token thường xuyên)
CREATE INDEX idx_sessions_user_id ON sessions(user_id) WHERE is_valid = true;
CREATE INDEX idx_sessions_token ON sessions(session_token) WHERE is_valid = true;
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at) WHERE is_valid = true;

-- Refresh tokens indexes
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash) WHERE is_revoked = false;
CREATE INDEX idx_refresh_tokens_family ON refresh_tokens(token_family);

-- Password reset tokens indexes
CREATE INDEX idx_password_reset_user_id ON password_reset_tokens(user_id);
CREATE INDEX idx_password_reset_token_hash ON password_reset_tokens(token_hash) WHERE is_used = false;

-- Audit logs indexes (query theo user và time range)
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);

-- Rate limits indexes
CREATE INDEX idx_rate_limits_identifier ON rate_limits(identifier, action);
CREATE INDEX idx_rate_limits_blocked ON rate_limits(is_blocked, blocked_until);

-- Role permissions indexes
CREATE INDEX idx_role_permissions_role ON role_permissions(role_id);
CREATE INDEX idx_role_permissions_permission ON role_permissions(permission_id);

-- User permissions indexes
CREATE INDEX idx_user_permissions_user ON user_permissions(user_id);
CREATE INDEX idx_user_permissions_expires ON user_permissions(expires_at) WHERE expires_at IS NOT NULL;

-- ============================================
-- TRIGGERS: Tự động cập nhật timestamps
-- ============================================

CREATE TRIGGER update_roles_updated_at BEFORE UPDATE ON roles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sessions_activity BEFORE UPDATE ON sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- FUNCTION: Clean up expired data
-- Chạy định kỳ để xóa các bản ghi hết hạn
-- ============================================
CREATE OR REPLACE FUNCTION cleanup_expired_data()
RETURNS void AS $$
BEGIN
    -- Xóa sessions hết hạn (giữ lại 30 ngày cho audit)
    DELETE FROM sessions 
    WHERE expires_at < CURRENT_TIMESTAMP - INTERVAL '30 days';
    
    -- Xóa refresh tokens hết hạn
    DELETE FROM refresh_tokens 
    WHERE expires_at < CURRENT_TIMESTAMP - INTERVAL '30 days';
    
    -- Xóa password reset tokens hết hạn
    DELETE FROM password_reset_tokens 
    WHERE expires_at < CURRENT_TIMESTAMP - INTERVAL '7 days';
    
    -- Xóa email verification tokens hết hạn
    DELETE FROM email_verification_tokens 
    WHERE expires_at < CURRENT_TIMESTAMP - INTERVAL '7 days';
    
    -- Xóa rate limits cũ
    DELETE FROM rate_limits 
    WHERE last_attempt_at < CURRENT_TIMESTAMP - INTERVAL '7 days';
    
    -- Xóa audit logs cũ (giữ lại 90 ngày)
    DELETE FROM audit_logs 
    WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: Check user permissions
-- Kiểm tra user có quyền thực hiện action trên resource không
-- ============================================
CREATE OR REPLACE FUNCTION check_user_permission(
    p_user_id UUID,
    p_permission_name VARCHAR(100)
)
RETURNS BOOLEAN AS $$
DECLARE
    has_permission BOOLEAN;
BEGIN
    -- Kiểm tra user có active không
    IF NOT EXISTS (
        SELECT 1 FROM users 
        WHERE id = p_user_id 
        AND is_active = true 
        AND is_locked = false
        AND deleted_at IS NULL
    ) THEN
        RETURN false;
    END IF;
    
    -- Kiểm tra user_permissions (override)
    SELECT is_granted INTO has_permission
    FROM user_permissions up
    JOIN permissions p ON up.permission_id = p.id
    WHERE up.user_id = p_user_id
    AND p.name = p_permission_name
    AND (up.expires_at IS NULL OR up.expires_at > CURRENT_TIMESTAMP);
    
    IF has_permission IS NOT NULL THEN
        RETURN has_permission;
    END IF;
    
    -- Kiểm tra role permissions
    SELECT EXISTS (
        SELECT 1
        FROM users u
        JOIN role_permissions rp ON u.role_id = rp.role_id
        JOIN permissions p ON rp.permission_id = p.id
        WHERE u.id = p_user_id
        AND p.name = p_permission_name
    ) INTO has_permission;
    
    RETURN COALESCE(has_permission, false);
END;
$$ LANGUAGE plpgsql;



-- ============================================
-- VIEWS: Các view để query dễ dàng hơn
-- ============================================

-- View: user_roles_permissions
-- Hiển thị tất cả quyền của user (từ role + custom permissions)
CREATE VIEW user_roles_permissions AS
SELECT 
    u.id as user_id,
    u.username,
    u.email,
    r.name as role_name,
    p.name as permission_name,
    p.resource,
    p.action,
    'role' as source
FROM users u
JOIN roles r ON u.role_id = r.id
JOIN role_permissions rp ON r.id = rp.role_id
JOIN permissions p ON rp.permission_id = p.id
WHERE u.deleted_at IS NULL

UNION

SELECT 
    u.id as user_id,
    u.username,
    u.email,
    r.name as role_name,
    p.name as permission_name,
    p.resource,
    p.action,
    CASE WHEN up.is_granted THEN 'granted' ELSE 'revoked' END as source
FROM users u
JOIN roles r ON u.role_id = r.id
JOIN user_permissions up ON u.id = up.user_id
JOIN permissions p ON up.permission_id = p.id
WHERE u.deleted_at IS NULL
AND (up.expires_at IS NULL OR up.expires_at > CURRENT_TIMESTAMP);

-- View: active_sessions
-- Hiển thị các session đang hoạt động
CREATE VIEW active_sessions AS
SELECT 
    s.id,
    s.user_id,
    u.username,
    u.email,
    s.ip_address,
    s.device_type,
    s.last_activity_at,
    s.expires_at,
    s.created_at
FROM sessions s
JOIN users u ON s.user_id = u.id
WHERE s.is_valid = true
AND s.expires_at > CURRENT_TIMESTAMP
AND u.is_active = true
AND u.deleted_at IS NULL;

-- ============================================
-- COMMENTS: Mô tả bảng cho Prisma
-- ============================================

COMMENT ON TABLE roles IS 'Quản lý vai trò người dùng trong hệ thống';
COMMENT ON TABLE permissions IS 'Định nghĩa các quyền hạn cụ thể';
COMMENT ON TABLE users IS 'Thông tin người dùng và authentication';
COMMENT ON TABLE sessions IS 'Quản lý phiên đăng nhập HTTP-only cookie';
COMMENT ON TABLE refresh_tokens IS 'Token để refresh access token với rotation strategy';
COMMENT ON TABLE password_reset_tokens IS 'Token reset mật khẩu gửi qua email';
COMMENT ON TABLE audit_logs IS 'Log mọi hành động quan trọng cho security và compliance';
COMMENT ON TABLE rate_limits IS 'Giới hạn rate request chống brute force';

-- ============================================
-- COMPLETED!
-- Để chạy cleanup định kỳ, tạo cron job:
-- SELECT cron.schedule('cleanup-expired-data', '0 2 * * *', 'SELECT cleanup_expired_data()');
-- ============================================