-- ============================================
-- CRM SYSTEM DATABASE SCHEMA
-- Hệ thống quản lý quan hệ khách hàng toàn diện
-- Tích hợp với NovaORM Authentication System
-- ============================================

-- Giả định: Đã có database novaorm với bảng users từ script trước
-- \c novaorm;

-- ============================================
-- ENUM TYPES: Định nghĩa các kiểu dữ liệu enum
-- ============================================

-- Trạng thái lead
CREATE TYPE lead_status AS ENUM (
    'new',              -- Mới tiếp nhận
    'contacted',        -- Đã liên hệ
    'qualified',        -- Đã đủ điều kiện
    'unqualified',      -- Không đủ điều kiện
    'converted'         -- Đã chuyển thành khách hàng
);

-- Nguồn lead
CREATE TYPE lead_source AS ENUM (
    'website',
    'referral',
    'social_media',
    'email_campaign',
    'cold_call',
    'trade_show',
    'partner',
    'other'
);

-- Trạng thái opportunity (cơ hội)
CREATE TYPE opportunity_stage AS ENUM (
    'prospecting',      -- Tìm kiếm
    'qualification',    -- Đánh giá
    'proposal',         -- Đề xuất
    'negotiation',      -- Đàm phán
    'closed_won',       -- Thắng
    'closed_lost'       -- Thua
);

-- Loại hoạt động
CREATE TYPE activity_type AS ENUM (
    'call',
    'meeting',
    'email',
    'task',
    'note',
    'demo',
    'lunch'
);

-- Trạng thái ticket
CREATE TYPE ticket_status AS ENUM (
    'open',
    'in_progress',
    'pending',
    'resolved',
    'closed',
    'reopened'
);

-- Độ ưu tiên
CREATE TYPE priority_level AS ENUM (
    'low',
    'medium',
    'high',
    'urgent'
);

-- Trạng thái đơn hàng
CREATE TYPE order_status AS ENUM (
    'draft',
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
    'refunded'
);

-- Phương thức thanh toán
CREATE TYPE payment_method AS ENUM (
    'cash',
    'bank_transfer',
    'credit_card',
    'debit_card',
    'e_wallet',
    'check'
);

-- ============================================
-- TABLE: companies
-- Công ty/Tổ chức - Trung tâm của CRM B2B
-- ============================================
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Thông tin cơ bản
    name VARCHAR(255) NOT NULL,
    legal_name VARCHAR(255),
    tax_code VARCHAR(50) UNIQUE,
    website VARCHAR(255),
    
    -- Thông tin ngành nghề
    industry VARCHAR(100),
    employee_count INTEGER,
    annual_revenue DECIMAL(15, 2),
    
    -- Địa chỉ (denormalized để query nhanh)
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    
    -- Liên hệ chính
    phone VARCHAR(20),
    email VARCHAR(255),
    
    -- Phân loại
    company_type VARCHAR(50), -- prospect, customer, partner, vendor
    company_size VARCHAR(50), -- startup, small, medium, enterprise
    
    -- Quan hệ
    parent_company_id UUID REFERENCES companies(id),
    
    -- CRM metadata
    owner_id UUID NOT NULL REFERENCES users(id), -- Sales rep phụ trách
    lead_source lead_source,
    
    -- Business metrics
    lifetime_value DECIMAL(15, 2) DEFAULT 0,
    last_contact_date DATE,
    next_followup_date DATE,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP
);

-- ============================================
-- TABLE: contacts
-- Người liên hệ - Cá nhân làm việc tại công ty
-- ============================================
CREATE TABLE contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Thông tin cá nhân
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    full_name VARCHAR(255) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    
    title VARCHAR(100), -- Job title: CEO, Manager...
    department VARCHAR(100),
    
    -- Liên hệ
    email VARCHAR(255),
    phone VARCHAR(20),
    mobile VARCHAR(20),
    
    -- Quan hệ với công ty
    company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
    reports_to_id UUID REFERENCES contacts(id), -- Báo cáo cho ai
    
    -- Social
    linkedin_url VARCHAR(255),
    facebook_url VARCHAR(255),
    twitter_handle VARCHAR(100),
    
    -- CRM metadata
    owner_id UUID NOT NULL REFERENCES users(id),
    lead_source lead_source,
    
    -- Địa chỉ (có thể khác với công ty)
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    
    -- Engagement
    last_contact_date DATE,
    next_followup_date DATE,
    
    -- Flags
    is_primary BOOLEAN DEFAULT false, -- Liên hệ chính của công ty
    is_decision_maker BOOLEAN DEFAULT false,
    do_not_call BOOLEAN DEFAULT false,
    do_not_email BOOLEAN DEFAULT false,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP
);

-- ============================================
-- TABLE: leads
-- Khách hàng tiềm năng chưa xác định
-- ============================================
CREATE TABLE leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Thông tin cơ bản
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    company_name VARCHAR(255),
    
    title VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    
    -- Lead info
    lead_source lead_source NOT NULL,
    lead_status lead_status DEFAULT 'new',
    
    -- Scoring
    lead_score INTEGER DEFAULT 0, -- 0-100
    
    -- Địa chỉ
    address_line1 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    
    -- Business info
    industry VARCHAR(100),
    employee_count INTEGER,
    annual_revenue DECIMAL(15, 2),
    
    -- Assignment
    owner_id UUID NOT NULL REFERENCES users(id),
    
    -- Conversion
    converted_at TIMESTAMP,
    converted_to_contact_id UUID REFERENCES contacts(id),
    converted_to_company_id UUID REFERENCES companies(id),
    converted_to_opportunity_id UUID, -- FK thêm sau
    
    -- Notes
    description TEXT,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP
);

-- ============================================
-- TABLE: opportunities
-- Cơ hội bán hàng (Deals)
-- ============================================
CREATE TABLE opportunities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Thông tin cơ bản
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Quan hệ
    company_id UUID REFERENCES companies(id),
    contact_id UUID REFERENCES contacts(id),
    
    -- Sales info
    stage opportunity_stage DEFAULT 'prospecting',
    probability INTEGER DEFAULT 0, -- 0-100%
    
    amount DECIMAL(15, 2) NOT NULL,
    expected_revenue DECIMAL(15, 2) GENERATED ALWAYS AS (amount * probability / 100.0) STORED,
    
    -- Dates
    expected_close_date DATE,
    actual_close_date DATE,
    
    -- Assignment
    owner_id UUID NOT NULL REFERENCES users(id),
    
    -- Metadata
    lead_source lead_source,
    next_step TEXT,
    loss_reason TEXT, -- Lý do thua nếu closed_lost
    
    -- Flags
    is_closed BOOLEAN DEFAULT false,
    is_won BOOLEAN DEFAULT false,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP
);

-- ============================================
-- TABLE: products
-- Sản phẩm/Dịch vụ
-- ============================================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Thông tin sản phẩm
    name VARCHAR(255) NOT NULL,
    code VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    
    -- Phân loại
    category VARCHAR(100),
    product_family VARCHAR(100),
    
    -- Giá
    unit_price DECIMAL(15, 2) NOT NULL,
    cost_price DECIMAL(15, 2),
    currency VARCHAR(3) DEFAULT 'VND',
    
    -- Inventory
    quantity_in_stock INTEGER DEFAULT 0,
    reorder_level INTEGER DEFAULT 0,
    
    -- Tax
    tax_rate DECIMAL(5, 2) DEFAULT 0, -- %
    
    -- Flags
    is_active BOOLEAN DEFAULT true,
    is_taxable BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- ============================================
-- TABLE: quotes
-- Báo giá cho khách hàng
-- ============================================
CREATE TABLE quotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quote_number VARCHAR(50) UNIQUE NOT NULL,
    
    -- Quan hệ
    opportunity_id UUID REFERENCES opportunities(id),
    company_id UUID REFERENCES companies(id),
    contact_id UUID REFERENCES contacts(id),
    
    -- Quote info
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Pricing
    subtotal DECIMAL(15, 2) DEFAULT 0,
    discount_amount DECIMAL(15, 2) DEFAULT 0,
    discount_percent DECIMAL(5, 2) DEFAULT 0,
    tax_amount DECIMAL(15, 2) DEFAULT 0,
    shipping_cost DECIMAL(15, 2) DEFAULT 0,
    total_amount DECIMAL(15, 2) DEFAULT 0,
    
    -- Dates
    quote_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    
    -- Status
    status VARCHAR(50) DEFAULT 'draft', -- draft, sent, accepted, rejected
    
    -- Assignment
    owner_id UUID NOT NULL REFERENCES users(id),
    
    -- Terms
    payment_terms TEXT,
    shipping_terms TEXT,
    notes TEXT,
    
    -- Conversion
    converted_to_order_id UUID, -- FK thêm sau
    converted_at TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- ============================================
-- TABLE: quote_items
-- Chi tiết sản phẩm trong báo giá
-- ============================================
CREATE TABLE quote_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quote_id UUID NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    
    -- Item info
    product_name VARCHAR(255) NOT NULL, -- Lưu tên để giữ lịch sử
    product_code VARCHAR(100),
    description TEXT,
    
    -- Quantity & Pricing
    quantity DECIMAL(10, 2) NOT NULL,
    unit_price DECIMAL(15, 2) NOT NULL,
    discount_percent DECIMAL(5, 2) DEFAULT 0,
    tax_rate DECIMAL(5, 2) DEFAULT 0,
    
    -- Calculated
    line_total DECIMAL(15, 2) GENERATED ALWAYS AS (
        quantity * unit_price * (1 - discount_percent / 100.0) * (1 + tax_rate / 100.0)
    ) STORED,
    
    -- Sort order
    sort_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: orders
-- Đơn hàng thực tế
-- ============================================
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    
    -- Quan hệ
    quote_id UUID REFERENCES quotes(id),
    opportunity_id UUID REFERENCES opportunities(id),
    company_id UUID REFERENCES companies(id),
    contact_id UUID REFERENCES contacts(id),
    
    -- Order info
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    
    -- Pricing (denormalized)
    subtotal DECIMAL(15, 2) DEFAULT 0,
    discount_amount DECIMAL(15, 2) DEFAULT 0,
    tax_amount DECIMAL(15, 2) DEFAULT 0,
    shipping_cost DECIMAL(15, 2) DEFAULT 0,
    total_amount DECIMAL(15, 2) DEFAULT 0,
    
    -- Payment
    payment_method payment_method,
    payment_status VARCHAR(50) DEFAULT 'pending', -- pending, partial, paid, refunded
    paid_amount DECIMAL(15, 2) DEFAULT 0,
    
    -- Status
    status order_status DEFAULT 'pending',
    
    -- Shipping
    shipping_address TEXT,
    tracking_number VARCHAR(100),
    shipped_date DATE,
    delivered_date DATE,
    
    -- Assignment
    owner_id UUID NOT NULL REFERENCES users(id),
    
    -- Notes
    notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- ============================================
-- TABLE: order_items
-- Chi tiết sản phẩm trong đơn hàng
-- ============================================
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    
    -- Item info (snapshot)
    product_name VARCHAR(255) NOT NULL,
    product_code VARCHAR(100),
    
    -- Quantity & Pricing
    quantity DECIMAL(10, 2) NOT NULL,
    unit_price DECIMAL(15, 2) NOT NULL,
    discount_percent DECIMAL(5, 2) DEFAULT 0,
    tax_rate DECIMAL(5, 2) DEFAULT 0,
    
    line_total DECIMAL(15, 2) GENERATED ALWAYS AS (
        quantity * unit_price * (1 - discount_percent / 100.0) * (1 + tax_rate / 100.0)
    ) STORED,
    
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: activities
-- Hoạt động: Call, Meeting, Email, Task...
-- ============================================
CREATE TABLE activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Thông tin hoạt động
    subject VARCHAR(255) NOT NULL,
    description TEXT,
    activity_type activity_type NOT NULL,
    
    -- Quan hệ (polymorphic - có thể liên kết nhiều loại)
    related_to_type VARCHAR(50), -- lead, contact, company, opportunity, order
    related_to_id UUID,
    
    -- Assignment
    owner_id UUID NOT NULL REFERENCES users(id),
    assigned_to UUID REFERENCES users(id),
    
    -- Scheduling
    scheduled_start TIMESTAMP,
    scheduled_end TIMESTAMP,
    actual_start TIMESTAMP,
    actual_end TIMESTAMP,
    
    -- Duration (phút)
    duration INTEGER,
    
    -- Status
    status VARCHAR(50) DEFAULT 'planned', -- planned, in_progress, completed, cancelled
    priority priority_level DEFAULT 'medium',
    
    -- Results
    outcome TEXT,
    
    -- Location (cho meeting)
    location VARCHAR(255),
    
    -- Attendees (cho meeting/call)
    attendees JSONB, -- [{contact_id, email, name}]
    
    -- Reminder
    reminder_minutes INTEGER, -- Nhắc nhở trước bao nhiêu phút
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- ============================================
-- TABLE: tickets
-- Support tickets / Yêu cầu hỗ trợ
-- ============================================
CREATE TABLE tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_number VARCHAR(50) UNIQUE NOT NULL,
    
    -- Thông tin ticket
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    
    -- Quan hệ
    company_id UUID REFERENCES companies(id),
    contact_id UUID REFERENCES contacts(id),
    
    -- Classification
    category VARCHAR(100), -- technical, billing, general...
    subcategory VARCHAR(100),
    
    -- Priority & Status
    priority priority_level DEFAULT 'medium',
    status ticket_status DEFAULT 'open',
    
    -- Assignment
    assigned_to UUID REFERENCES users(id),
    assigned_team VARCHAR(100),
    
    -- SLA (Service Level Agreement)
    sla_due_date TIMESTAMP,
    first_response_at TIMESTAMP,
    resolved_at TIMESTAMP,
    closed_at TIMESTAMP,
    
    -- Metrics
    response_time_minutes INTEGER, -- Thời gian phản hồi đầu tiên
    resolution_time_minutes INTEGER, -- Thời gian giải quyết
    
    -- Related
    related_to_order_id UUID REFERENCES orders(id),
    parent_ticket_id UUID REFERENCES tickets(id), -- Ticket liên quan
    
    -- Customer satisfaction
    satisfaction_rating INTEGER, -- 1-5
    satisfaction_comment TEXT,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- ============================================
-- TABLE: ticket_comments
-- Bình luận/Trả lời trong ticket
-- ============================================
CREATE TABLE ticket_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    
    -- Content
    comment TEXT NOT NULL,
    
    -- Author
    user_id UUID REFERENCES users(id),
    
    -- Flags
    is_internal BOOLEAN DEFAULT false, -- Internal note không hiện cho khách
    is_solution BOOLEAN DEFAULT false, -- Đánh dấu là giải pháp
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: emails
-- Lịch sử email gửi/nhận (Email tracking)
-- ============================================
CREATE TABLE emails (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Email info
    subject VARCHAR(500) NOT NULL,
    body TEXT,
    
    -- From/To
    from_address VARCHAR(255) NOT NULL,
    to_addresses TEXT[], -- Array of email addresses
    cc_addresses TEXT[],
    bcc_addresses TEXT[],
    
    -- Related to
    related_to_type VARCHAR(50),
    related_to_id UUID,
    
    -- Status
    status VARCHAR(50) DEFAULT 'draft', -- draft, sent, delivered, opened, bounced, failed
    
    -- Tracking
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    opened_at TIMESTAMP,
    clicked_at TIMESTAMP,
    bounced_at TIMESTAMP,
    
    open_count INTEGER DEFAULT 0,
    click_count INTEGER DEFAULT 0,
    
    -- Metadata
    message_id VARCHAR(255), -- Email service provider message ID
    thread_id VARCHAR(255),
    
    -- Assignment
    owner_id UUID REFERENCES users(id),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- ============================================
-- TABLE: notes
-- Ghi chú cho bất kỳ entity nào
-- ============================================
CREATE TABLE notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Content
    title VARCHAR(255),
    content TEXT NOT NULL,
    
    -- Quan hệ polymorphic
    related_to_type VARCHAR(50) NOT NULL,
    related_to_id UUID NOT NULL,
    
    -- Privacy
    is_private BOOLEAN DEFAULT false,
    
    -- Author
    created_by UUID NOT NULL REFERENCES users(id),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: attachments
-- File đính kèm cho các entity
-- ============================================
CREATE TABLE attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- File info
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT, -- bytes
    mime_type VARCHAR(100),
    
    -- Quan hệ polymorphic
    related_to_type VARCHAR(50) NOT NULL,
    related_to_id UUID NOT NULL,
    
    -- Description
    description TEXT,
    
    -- Uploaded by
    uploaded_by UUID NOT NULL REFERENCES users(id),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: tags
-- Tags để phân loại dữ liệu
-- ============================================
CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    color VARCHAR(7), -- Hex color code
    description TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- ============================================
-- TABLE: taggables
-- Bảng trung gian polymorphic cho tags
-- ============================================
CREATE TABLE taggables (
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    taggable_type VARCHAR(50) NOT NULL, -- company, contact, lead, opportunity...
    taggable_id UUID NOT NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    
    PRIMARY KEY (tag_id, taggable_type, taggable_id)
);

-- ============================================
-- TABLE: sales_pipelines
-- Quy trình bán hàng (có thể custom nhiều pipeline)
-- ============================================
CREATE TABLE sales_pipelines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- ============================================
-- TABLE: pipeline_stages
-- Các giai đoạn trong pipeline
-- ============================================
CREATE TABLE pipeline_stages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pipeline_id UUID NOT NULL REFERENCES sales_pipelines(id) ON DELETE CASCADE,
    
    name VARCHAR(100) NOT NULL,
    probability INTEGER DEFAULT 0, -- Win probability %
    sort_order INTEGER DEFAULT 0,
    
    is_closed BOOLEAN DEFAULT false,
    is_won BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: campaigns
-- Chiến dịch Marketing
-- ============================================
CREATE TABLE campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Campaign info
    name VARCHAR(255) NOT NULL,
    description TEXT,
    campaign_type VARCHAR(50), -- email, social, event, webinar...
    
    -- Status
    status VARCHAR(50) DEFAULT 'planning', -- planning, active, completed, cancelled
    
    -- Budget
    budget_amount DECIMAL(15, 2),
    actual_cost DECIMAL(15, 2) DEFAULT 0,
    
    -- Dates
    start_date DATE,
    end_date DATE,
    
    -- Targets
    expected_response INTEGER,
    expected_revenue DECIMAL(15, 2),
    
    -- Results
    num_sent INTEGER DEFAULT 0,
    num_delivered INTEGER DEFAULT 0,
    num_opened INTEGER DEFAULT 0,
    num_clicked INTEGER DEFAULT 0,
    num_leads INTEGER DEFAULT 0,
    num_converted INTEGER DEFAULT 0,
    actual_revenue DECIMAL(15, 2) DEFAULT 0,
    
    -- Assignment
    owner_id UUID NOT NULL REFERENCES users(id),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- ============================================
-- TABLE: campaign_members
-- Thành viên trong chiến dịch (Leads/Contacts)
-- ============================================
CREATE TABLE campaign_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    
    -- Member (polymorphic)
    member_type VARCHAR(50) NOT NULL, -- lead, contact
    member_id UUID NOT NULL,
    
    -- Status
    status VARCHAR(50) DEFAULT 'sent', -- sent, opened, clicked, responded, converted
    
    -- Tracking
    sent_at TIMESTAMP,
    opened_at TIMESTAMP,
    clicked_at TIMESTAMP,
    responded_at TIMESTAMP,
    
    -- Response
    response_notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(campaign_id, member_type, member_id)
);

-- ============================================
-- TABLE: custom_fields
-- Định nghĩa các trường custom
-- ============================================
CREATE TABLE custom_fields (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Field definition
    entity_type VARCHAR(50) NOT NULL, -- company, contact, lead...
    field_name VARCHAR(100) NOT NULL,
    field_label VARCHAR(100) NOT NULL,
    field_type VARCHAR(50) NOT NULL, -- text, number, date, boolean, picklist...
    
    -- Options (cho picklist)
    field_options JSONB, -- ['Option1', 'Option2']
    
    -- Validation
    is_required BOOLEAN DEFAULT false,
    default_value TEXT,
    
    -- Display
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    
    UNIQUE(entity_type, field_name)
);

-- ============================================
-- TABLE: custom_field_values
-- Giá trị của custom fields
-- ============================================
CREATE TABLE custom_field_values (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    custom_field_id UUID NOT NULL REFERENCES custom_fields(id) ON DELETE CASCADE,
    
    -- Entity
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    
    -- Value (lưu dạng text, convert khi query)
    value TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(custom_field_id, entity_type, entity_id)
);

-- ============================================
-- INDEXES: Performance optimization
-- ============================================

-- Companies indexes
CREATE INDEX idx_companies_name ON companies(name) WHERE deleted_at IS NULL;
CREATE INDEX idx_companies_tax_code ON companies(tax_code) WHERE deleted_at IS NULL;
CREATE INDEX idx_companies_owner ON companies(owner_id);
CREATE INDEX idx_companies_parent ON companies(parent_company_id);
CREATE INDEX idx_companies_type ON companies(company_type);

-- Contacts indexes
CREATE INDEX idx_contacts_company ON contacts(company_id);
CREATE INDEX idx_contacts_email ON contacts(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_contacts_owner ON contacts(owner_id);
CREATE INDEX idx_contacts_full_name ON contacts(full_name);
CREATE INDEX idx_contacts_primary ON contacts(company_id, is_primary) WHERE is_primary = true;

-- Leads indexes
CREATE INDEX idx_leads_email ON leads(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_leads_owner ON leads(owner_id);
CREATE INDEX idx_leads_status ON leads(lead_status);
CREATE INDEX idx_leads_source ON leads(lead_source);
CREATE INDEX idx_leads_converted ON leads(converted_at, converted_to_contact_id);

-- Opportunities indexes
CREATE INDEX idx_opportunities_company ON opportunities(company_id);
CREATE INDEX idx_opportunities_contact ON opportunities(contact_id);
CREATE INDEX idx_opportunities_owner ON opportunities(owner_id);
CREATE INDEX idx_opportunities_stage ON opportunities(stage);
CREATE INDEX idx_opportunities_close_date ON opportunities(expected_close_date);
CREATE INDEX idx_opportunities_amount ON opportunities(amount);
CREATE INDEX idx_opportunities_open ON opportunities(is_closed, stage) WHERE is_closed = false;

-- Products indexes
CREATE INDEX idx_products_code ON products(code);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_active ON products(is_active) WHERE is_active = true;

-- Orders indexes
CREATE INDEX idx_orders_number ON orders(order_number);
CREATE INDEX idx_orders_company ON orders(company_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_date ON orders(order_date DESC);
CREATE INDEX idx_orders_owner ON orders(owner_id);

-- Activities indexes
CREATE INDEX idx_activities_owner ON activities(owner_id);
CREATE INDEX idx_activities_assigned ON activities(assigned_to);
CREATE INDEX idx_activities_type ON activities(activity_type);
CREATE INDEX idx_activities_status ON activities(status);
CREATE INDEX idx_activities_scheduled ON activities(scheduled_start);
CREATE INDEX idx_activities_related ON activities(related_to_type, related_to_id);

-- Tickets indexes
CREATE INDEX idx_tickets_number ON tickets(ticket_number);
CREATE INDEX idx_tickets_company ON tickets(company_id);
CREATE INDEX idx_tickets_contact ON tickets(contact_id);
CREATE INDEX idx_tickets_assigned ON tickets(assigned_to);
CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_tickets_priority ON tickets(priority, status);
CREATE INDEX idx_tickets_sla ON tickets(sla_due_date) WHERE status NOT IN ('resolved', 'closed');

-- Emails indexes
CREATE INDEX idx_emails_related ON emails(related_to_type, related_to_id);
CREATE INDEX idx_emails_status ON emails(status);
CREATE INDEX idx_emails_sent ON emails(sent_at DESC);

-- Notes indexes
CREATE INDEX idx_notes_related ON notes(related_to_type, related_to_id);
CREATE INDEX idx_notes_author ON notes(created_by);

-- Attachments indexes
CREATE INDEX idx_attachments_related ON attachments(related_to_type, related_to_id);

-- Tags indexes
CREATE INDEX idx_taggables_tag ON taggables(tag_id);
CREATE INDEX idx_taggables_entity ON taggables(taggable_type, taggable_id);

-- Campaign indexes
CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_campaigns_dates ON campaigns(start_date, end_date);
CREATE INDEX idx_campaign_members_campaign ON campaign_members(campaign_id);
CREATE INDEX idx_campaign_members_member ON campaign_members(member_type, member_id);

-- Custom fields indexes
CREATE INDEX idx_custom_fields_entity ON custom_fields(entity_type);
CREATE INDEX idx_custom_field_values_field ON custom_field_values(custom_field_id);
CREATE INDEX idx_custom_field_values_entity ON custom_field_values(entity_type, entity_id);

-- ============================================
-- TRIGGERS: Auto-update timestamps
-- ============================================

CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contacts_updated_at BEFORE UPDATE ON contacts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON leads
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_opportunities_updated_at BEFORE UPDATE ON opportunities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tickets_updated_at BEFORE UPDATE ON tickets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_campaigns_updated_at BEFORE UPDATE ON campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- FUNCTIONS: Business logic helpers
-- ============================================

-- Function: Convert lead to contact/company/opportunity
CREATE OR REPLACE FUNCTION convert_lead(
    p_lead_id UUID,
    p_create_company BOOLEAN DEFAULT true,
    p_create_opportunity BOOLEAN DEFAULT true,
    p_opportunity_amount DECIMAL DEFAULT 0,
    p_converted_by UUID DEFAULT NULL
)
RETURNS TABLE (
    contact_id UUID,
    company_id UUID,
    opportunity_id UUID
) AS $$
DECLARE
    v_lead RECORD;
    v_contact_id UUID;
    v_company_id UUID;
    v_opportunity_id UUID;
BEGIN
    -- Get lead info
    SELECT * INTO v_lead FROM leads WHERE id = p_lead_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Lead not found';
    END IF;
    
    -- Create company if needed
    IF p_create_company AND v_lead.company_name IS NOT NULL THEN
        INSERT INTO companies (
            name, phone, email, owner_id, lead_source, created_by,
            city, state, country, postal_code
        ) VALUES (
            v_lead.company_name, v_lead.phone, v_lead.email, v_lead.owner_id, 
            v_lead.lead_source, COALESCE(p_converted_by, v_lead.owner_id),
            v_lead.city, v_lead.state, v_lead.country, v_lead.postal_code
        ) RETURNING id INTO v_company_id;
    END IF;
    
    -- Create contact
    INSERT INTO contacts (
        first_name, last_name, email, phone, company_id, owner_id, 
        lead_source, created_by,
        address_line1, city, state, country, postal_code
    ) VALUES (
        v_lead.first_name, v_lead.last_name, v_lead.email, v_lead.phone,
        v_company_id, v_lead.owner_id, v_lead.lead_source,
        COALESCE(p_converted_by, v_lead.owner_id),
        v_lead.address_line1, v_lead.city, v_lead.state, v_lead.country, v_lead.postal_code
    ) RETURNING id INTO v_contact_id;
    
    -- Create opportunity if needed
    IF p_create_opportunity AND p_opportunity_amount > 0 THEN
        INSERT INTO opportunities (
            name, company_id, contact_id, amount, owner_id, lead_source, created_by
        ) VALUES (
            v_lead.company_name || ' - ' || v_lead.first_name || ' ' || v_lead.last_name,
            v_company_id, v_contact_id, p_opportunity_amount, v_lead.owner_id,
            v_lead.lead_source, COALESCE(p_converted_by, v_lead.owner_id)
        ) RETURNING id INTO v_opportunity_id;
    END IF;
    
    -- Update lead
    UPDATE leads SET
        lead_status = 'converted',
        converted_at = CURRENT_TIMESTAMP,
        converted_to_contact_id = v_contact_id,
        converted_to_company_id = v_company_id,
        converted_to_opportunity_id = v_opportunity_id
    WHERE id = p_lead_id;
    
    RETURN QUERY SELECT v_contact_id, v_company_id, v_opportunity_id;
END;
$$ LANGUAGE plpgsql;

-- Function: Calculate opportunity win rate by user
CREATE OR REPLACE FUNCTION calculate_win_rate(p_user_id UUID)
RETURNS TABLE (
    total_opportunities BIGINT,
    won_opportunities BIGINT,
    lost_opportunities BIGINT,
    win_rate DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_opportunities,
        COUNT(*) FILTER (WHERE stage = 'closed_won') as won_opportunities,
        COUNT(*) FILTER (WHERE stage = 'closed_lost') as lost_opportunities,
        ROUND(
            (COUNT(*) FILTER (WHERE stage = 'closed_won')::DECIMAL / 
            NULLIF(COUNT(*) FILTER (WHERE is_closed = true), 0)) * 100, 
            2
        ) as win_rate
    FROM opportunities
    WHERE owner_id = p_user_id
    AND deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql;

-- Function: Update quote totals
CREATE OR REPLACE FUNCTION update_quote_totals()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE quotes SET
        subtotal = (
            SELECT COALESCE(SUM(quantity * unit_price * (1 - discount_percent / 100.0)), 0)
            FROM quote_items WHERE quote_id = NEW.quote_id
        ),
        tax_amount = (
            SELECT COALESCE(SUM(quantity * unit_price * (1 - discount_percent / 100.0) * tax_rate / 100.0), 0)
            FROM quote_items WHERE quote_id = NEW.quote_id
        )
    WHERE id = NEW.quote_id;
    
    UPDATE quotes SET
        total_amount = subtotal + tax_amount + shipping_cost - discount_amount
    WHERE id = NEW.quote_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_quote_totals_trigger
    AFTER INSERT OR UPDATE OR DELETE ON quote_items
    FOR EACH ROW EXECUTE FUNCTION update_quote_totals();

-- Similar trigger for orders
CREATE OR REPLACE FUNCTION update_order_totals()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE orders SET
        subtotal = (
            SELECT COALESCE(SUM(quantity * unit_price * (1 - discount_percent / 100.0)), 0)
            FROM order_items WHERE order_id = NEW.order_id
        ),
        tax_amount = (
            SELECT COALESCE(SUM(quantity * unit_price * (1 - discount_percent / 100.0) * tax_rate / 100.0), 0)
            FROM order_items WHERE order_id = NEW.order_id
        )
    WHERE id = NEW.order_id;
    
    UPDATE orders SET
        total_amount = subtotal + tax_amount + shipping_cost - discount_amount
    WHERE id = NEW.order_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_order_totals_trigger
    AFTER INSERT OR UPDATE OR DELETE ON order_items
    FOR EACH ROW EXECUTE FUNCTION update_order_totals();

-- ============================================
-- VIEWS: Reporting và Analytics
-- ============================================

-- View: Sales pipeline overview
CREATE VIEW v_sales_pipeline AS
SELECT 
    o.stage,
    COUNT(*) as count,
    SUM(o.amount) as total_amount,
    SUM(o.expected_revenue) as total_expected_revenue,
    AVG(o.probability) as avg_probability,
    u.username as owner_name
FROM opportunities o
JOIN users u ON o.owner_id = u.id
WHERE o.is_closed = false
AND o.deleted_at IS NULL
GROUP BY o.stage, u.username;

-- View: Customer lifetime value
CREATE VIEW v_customer_lifetime_value AS
SELECT 
    c.id as company_id,
    c.name as company_name,
    COUNT(DISTINCT o.id) as total_orders,
    SUM(o.total_amount) as lifetime_value,
    AVG(o.total_amount) as avg_order_value,
    MAX(o.order_date) as last_order_date,
    u.username as account_owner
FROM companies c
LEFT JOIN orders o ON c.id = o.company_id AND o.status != 'cancelled'
LEFT JOIN users u ON c.owner_id = u.id
WHERE c.deleted_at IS NULL
GROUP BY c.id, c.name, u.username;

-- View: Support ticket metrics
CREATE VIEW v_ticket_metrics AS
SELECT 
    t.status,
    t.priority,
    COUNT(*) as ticket_count,
    AVG(t.response_time_minutes) as avg_response_time,
    AVG(t.resolution_time_minutes) as avg_resolution_time,
    AVG(t.satisfaction_rating) as avg_satisfaction
FROM tickets t
WHERE t.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY t.status, t.priority;

-- View: Sales leaderboard
CREATE VIEW v_sales_leaderboard AS
SELECT 
    u.id as user_id,
    u.username,
    u.full_name,
    COUNT(DISTINCT o.id) FILTER (WHERE o.stage = 'closed_won') as won_deals,
    SUM(o.amount) FILTER (WHERE o.stage = 'closed_won') as total_revenue,
    COUNT(DISTINCT o.id) FILTER (WHERE o.is_closed = false) as open_opportunities,
    SUM(o.expected_revenue) FILTER (WHERE o.is_closed = false) as pipeline_value
FROM users u
LEFT JOIN opportunities o ON u.id = o.owner_id 
    AND o.deleted_at IS NULL
    AND EXTRACT(YEAR FROM o.created_at) = EXTRACT(YEAR FROM CURRENT_DATE)
WHERE u.is_active = true
AND u.deleted_at IS NULL
GROUP BY u.id, u.username, u.full_name
ORDER BY total_revenue DESC NULLS LAST;

-- ============================================
-- SEED DATA: Dữ liệu mẫu
-- ============================================

-- Add FK constraint for leads
ALTER TABLE leads ADD CONSTRAINT fk_leads_opportunity 
    FOREIGN KEY (converted_to_opportunity_id) REFERENCES opportunities(id);

ALTER TABLE quotes ADD CONSTRAINT fk_quotes_order
    FOREIGN KEY (converted_to_order_id) REFERENCES orders(id);



-- ============================================
-- PERFORMANCE: Materialized views (optional)
-- ============================================

-- Materialized view for dashboard stats (refresh định kỳ)
CREATE MATERIALIZED VIEW mv_dashboard_stats AS
SELECT 
    -- Leads
    (SELECT COUNT(*) FROM leads WHERE lead_status = 'new' AND deleted_at IS NULL) as new_leads,
    (SELECT COUNT(*) FROM leads WHERE lead_status = 'qualified' AND deleted_at IS NULL) as qualified_leads,
    
    -- Opportunities
    (SELECT COUNT(*) FROM opportunities WHERE is_closed = false AND deleted_at IS NULL) as open_opportunities,
    (SELECT SUM(expected_revenue) FROM opportunities WHERE is_closed = false AND deleted_at IS NULL) as pipeline_value,
    
    -- Orders
    (SELECT COUNT(*) FROM orders WHERE EXTRACT(MONTH FROM order_date) = EXTRACT(MONTH FROM CURRENT_DATE)) as orders_this_month,
    (SELECT SUM(total_amount) FROM orders WHERE status NOT IN ('cancelled', 'refunded') 
        AND EXTRACT(MONTH FROM order_date) = EXTRACT(MONTH FROM CURRENT_DATE)) as revenue_this_month,
    
    -- Tickets
    (SELECT COUNT(*) FROM tickets WHERE status IN ('open', 'in_progress')) as open_tickets,
    (SELECT AVG(satisfaction_rating) FROM tickets WHERE satisfaction_rating IS NOT NULL) as avg_satisfaction,
    
    -- Activities
    (SELECT COUNT(*) FROM activities WHERE scheduled_start::DATE = CURRENT_DATE AND status = 'planned') as activities_today,
    
    CURRENT_TIMESTAMP as refreshed_at;

-- Index for materialized view
CREATE UNIQUE INDEX idx_mv_dashboard_stats ON mv_dashboard_stats(refreshed_at);

-- Refresh command (chạy định kỳ):
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_dashboard_stats;

-- ============================================
-- COMPLETED!
-- CRM System with full features:
-- - Lead Management
-- - Contact & Company Management
-- - Sales Pipeline & Opportunities
-- - Product Catalog
-- - Quotes & Orders
-- - Support Tickets
-- - Activities & Email Tracking
-- - Campaigns
-- - Custom Fields
-- - Tags & Notes
-- - Reporting & Analytics
-- ============================================