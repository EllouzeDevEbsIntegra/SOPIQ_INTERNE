-- PosCaisse — schéma initial (PostgreSQL)
-- Montants : NUMERIC(14,3) (TND, 3 décimales)

CREATE TABLE company (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    trade_name VARCHAR(150),
    address VARCHAR(255),
    phone VARCHAR(50),
    tax_id VARCHAR(80),
    currency VARCHAR(3) NOT NULL DEFAULT 'TND',
    currency_symbol VARCHAR(8) NOT NULL DEFAULT 'DT',
    decimals INT NOT NULL DEFAULT 3,
    timezone VARCHAR(60) NOT NULL DEFAULT 'Africa/Tunis',
    logo_data TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE point_of_sale (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT NOT NULL REFERENCES company(id),
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    address VARCHAR(255),
    phone VARCHAR(50),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE register (
    id BIGSERIAL PRIMARY KEY,
    point_of_sale_id BIGINT NOT NULL REFERENCES point_of_sale(id),
    code VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (point_of_sale_id, code)
);

CREATE TABLE role (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(40) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    system_role BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE role_permission (
    role_id BIGINT NOT NULL REFERENCES role(id) ON DELETE CASCADE,
    permission VARCHAR(60) NOT NULL,
    PRIMARY KEY (role_id, permission)
);

CREATE TABLE app_user (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(60) NOT NULL UNIQUE,
    full_name VARCHAR(120) NOT NULL,
    password_hash VARCHAR(120),
    pin_hash VARCHAR(120),
    role_id BIGINT NOT NULL REFERENCES role(id),
    point_of_sale_id BIGINT REFERENCES point_of_sale(id),
    max_discount_percent NUMERIC(5,2),
    color VARCHAR(12),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE register_session (
    id BIGSERIAL PRIMARY KEY,
    register_id BIGINT NOT NULL REFERENCES register(id),
    opened_by BIGINT NOT NULL REFERENCES app_user(id),
    closed_by BIGINT REFERENCES app_user(id),
    status VARCHAR(10) NOT NULL DEFAULT 'OPEN',
    opened_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_at TIMESTAMPTZ,
    opening_float NUMERIC(14,3) NOT NULL DEFAULT 0,
    cash_sales NUMERIC(14,3),
    card_sales NUMERIC(14,3),
    other_sales NUMERIC(14,3),
    cash_refunds NUMERIC(14,3),
    cash_in NUMERIC(14,3),
    cash_out NUMERIC(14,3),
    expected_cash NUMERIC(14,3),
    counted_cash NUMERIC(14,3),
    cash_difference NUMERIC(14,3),
    tickets_count INT,
    revenue NUMERIC(14,3),
    closing_note VARCHAR(500),
    version BIGINT NOT NULL DEFAULT 0
);
CREATE UNIQUE INDEX ux_register_session_open ON register_session(register_id) WHERE status = 'OPEN';
CREATE INDEX ix_register_session_opened ON register_session(opened_at);

CREATE TABLE print_destination (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    kind VARCHAR(20) NOT NULL DEFAULT 'PREP',
    copies INT NOT NULL DEFAULT 1,
    show_prices BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE category (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    color VARCHAR(12) NOT NULL DEFAULT '#3b82f6',
    icon VARCHAR(40),
    sort_order INT NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    print_destination_id BIGINT REFERENCES print_destination(id)
);

CREATE TABLE product (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(40) NOT NULL UNIQUE,
    reference VARCHAR(60),
    name VARCHAR(150) NOT NULL,
    short_name VARCHAR(40),
    description VARCHAR(500),
    category_id BIGINT NOT NULL REFERENCES category(id),
    product_type VARCHAR(10) NOT NULL DEFAULT 'SIMPLE',
    price NUMERIC(14,3) NOT NULL DEFAULT 0,
    tax_rate NUMERIC(5,2) NOT NULL DEFAULT 0,
    image_url TEXT,
    color VARCHAR(12),
    sort_order INT NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    available BOOLEAN NOT NULL DEFAULT TRUE,
    favorite BOOLEAN NOT NULL DEFAULT FALSE,
    favorite_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_product_category ON product(category_id);
CREATE INDEX ix_product_name ON product(lower(name));

CREATE TABLE product_print_destination (
    product_id BIGINT NOT NULL REFERENCES product(id) ON DELETE CASCADE,
    print_destination_id BIGINT NOT NULL REFERENCES print_destination(id) ON DELETE CASCADE,
    PRIMARY KEY (product_id, print_destination_id)
);

CREATE TABLE modifier_group (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    required BOOLEAN NOT NULL DEFAULT FALSE,
    multiple BOOLEAN NOT NULL DEFAULT TRUE,
    min_select INT NOT NULL DEFAULT 0,
    max_select INT NOT NULL DEFAULT 0,
    sort_order INT NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE modifier (
    id BIGSERIAL PRIMARY KEY,
    group_id BIGINT NOT NULL REFERENCES modifier_group(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    price_delta NUMERIC(14,3) NOT NULL DEFAULT 0,
    sort_order INT NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE product_modifier_group (
    product_id BIGINT NOT NULL REFERENCES product(id) ON DELETE CASCADE,
    modifier_group_id BIGINT NOT NULL REFERENCES modifier_group(id) ON DELETE CASCADE,
    sort_order INT NOT NULL DEFAULT 0,
    PRIMARY KEY (product_id, modifier_group_id)
);

CREATE TABLE menu_component (
    id BIGSERIAL PRIMARY KEY,
    menu_product_id BIGINT NOT NULL REFERENCES product(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE menu_component_product (
    menu_component_id BIGINT NOT NULL REFERENCES menu_component(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES product(id) ON DELETE CASCADE,
    price_delta NUMERIC(14,3) NOT NULL DEFAULT 0,
    PRIMARY KEY (menu_component_id, product_id)
);

CREATE TABLE customer (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    phone VARCHAR(40),
    note VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_customer_phone ON customer(phone);

CREATE TABLE payment_method (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(80) NOT NULL,
    kind VARCHAR(20) NOT NULL DEFAULT 'OTHER',
    opens_drawer BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE document_sequence (
    id BIGSERIAL PRIMARY KEY,
    scope_key VARCHAR(80) NOT NULL UNIQUE,
    next_value BIGINT NOT NULL DEFAULT 1
);

CREATE TABLE sale_order (
    id BIGSERIAL PRIMARY KEY,
    client_ref VARCHAR(64) UNIQUE,
    ticket_number VARCHAR(40) UNIQUE,
    held_ref VARCHAR(20),
    company_id BIGINT NOT NULL REFERENCES company(id),
    point_of_sale_id BIGINT NOT NULL REFERENCES point_of_sale(id),
    register_id BIGINT NOT NULL REFERENCES register(id),
    session_id BIGINT REFERENCES register_session(id),
    cashier_id BIGINT NOT NULL REFERENCES app_user(id),
    customer_id BIGINT REFERENCES customer(id),
    customer_name VARCHAR(120),
    customer_phone VARCHAR(40),
    note VARCHAR(255),
    service_mode VARCHAR(15) NOT NULL DEFAULT 'TAKEAWAY',
    status VARCHAR(25) NOT NULL,
    subtotal NUMERIC(14,3) NOT NULL DEFAULT 0,
    line_discount_total NUMERIC(14,3) NOT NULL DEFAULT 0,
    discount_percent NUMERIC(5,2) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(14,3) NOT NULL DEFAULT 0,
    tax_total NUMERIC(14,3) NOT NULL DEFAULT 0,
    total NUMERIC(14,3) NOT NULL DEFAULT 0,
    paid_total NUMERIC(14,3) NOT NULL DEFAULT 0,
    change_amount NUMERIC(14,3) NOT NULL DEFAULT 0,
    refunded_total NUMERIC(14,3) NOT NULL DEFAULT 0,
    cancel_reason VARCHAR(255),
    cancelled_by BIGINT REFERENCES app_user(id),
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    paid_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX ix_sale_order_status ON sale_order(status);
CREATE INDEX ix_sale_order_paid_at ON sale_order(paid_at);
CREATE INDEX ix_sale_order_session ON sale_order(session_id);
CREATE INDEX ix_sale_order_register ON sale_order(register_id);
CREATE INDEX ix_sale_order_cashier ON sale_order(cashier_id);
CREATE INDEX ix_sale_order_pos ON sale_order(point_of_sale_id);

CREATE TABLE order_line (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES sale_order(id) ON DELETE CASCADE,
    parent_line_id BIGINT REFERENCES order_line(id) ON DELETE CASCADE,
    product_id BIGINT REFERENCES product(id),
    category_id BIGINT REFERENCES category(id),
    product_code VARCHAR(40),
    product_name VARCHAR(150) NOT NULL,
    quantity NUMERIC(10,3) NOT NULL DEFAULT 1,
    original_unit_price NUMERIC(14,3) NOT NULL DEFAULT 0,
    unit_price NUMERIC(14,3) NOT NULL DEFAULT 0,
    modifiers_total NUMERIC(14,3) NOT NULL DEFAULT 0,
    discount_percent NUMERIC(5,2) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(14,3) NOT NULL DEFAULT 0,
    tax_rate NUMERIC(5,2) NOT NULL DEFAULT 0,
    line_total NUMERIC(14,3) NOT NULL DEFAULT 0,
    note VARCHAR(255),
    sort_order INT NOT NULL DEFAULT 0
);
CREATE INDEX ix_order_line_order ON order_line(order_id);
CREATE INDEX ix_order_line_product ON order_line(product_id);

CREATE TABLE order_line_modifier (
    id BIGSERIAL PRIMARY KEY,
    order_line_id BIGINT NOT NULL REFERENCES order_line(id) ON DELETE CASCADE,
    modifier_id BIGINT REFERENCES modifier(id),
    modifier_name VARCHAR(100) NOT NULL,
    price_delta NUMERIC(14,3) NOT NULL DEFAULT 0
);

CREATE TABLE payment (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES sale_order(id) ON DELETE CASCADE,
    session_id BIGINT REFERENCES register_session(id),
    payment_method_id BIGINT NOT NULL REFERENCES payment_method(id),
    amount NUMERIC(14,3) NOT NULL,
    tendered NUMERIC(14,3),
    change_given NUMERIC(14,3) NOT NULL DEFAULT 0,
    reference VARCHAR(80),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_payment_order ON payment(order_id);
CREATE INDEX ix_payment_session ON payment(session_id);

CREATE TABLE refund (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES sale_order(id),
    session_id BIGINT REFERENCES register_session(id),
    user_id BIGINT NOT NULL REFERENCES app_user(id),
    payment_method_id BIGINT NOT NULL REFERENCES payment_method(id),
    amount NUMERIC(14,3) NOT NULL,
    reason VARCHAR(255) NOT NULL,
    kind VARCHAR(20) NOT NULL DEFAULT 'REFUND',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_refund_order ON refund(order_id);
CREATE INDEX ix_refund_session ON refund(session_id);

CREATE TABLE cash_movement (
    id BIGSERIAL PRIMARY KEY,
    session_id BIGINT NOT NULL REFERENCES register_session(id),
    user_id BIGINT NOT NULL REFERENCES app_user(id),
    movement_type VARCHAR(5) NOT NULL,
    reason VARCHAR(120) NOT NULL,
    amount NUMERIC(14,3) NOT NULL,
    comment VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_cash_movement_session ON cash_movement(session_id);

CREATE TABLE register_journal (
    id BIGSERIAL PRIMARY KEY,
    point_of_sale_id BIGINT REFERENCES point_of_sale(id),
    register_id BIGINT REFERENCES register(id),
    session_id BIGINT REFERENCES register_session(id),
    user_id BIGINT REFERENCES app_user(id),
    event_type VARCHAR(30) NOT NULL,
    amount NUMERIC(14,3),
    reference VARCHAR(60),
    description VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_journal_created ON register_journal(created_at);
CREATE INDEX ix_journal_session ON register_journal(session_id);

CREATE TABLE daily_closure (
    id BIGSERIAL PRIMARY KEY,
    point_of_sale_id BIGINT NOT NULL REFERENCES point_of_sale(id),
    business_date DATE NOT NULL,
    closed_by BIGINT NOT NULL REFERENCES app_user(id),
    closed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    revenue NUMERIC(14,3) NOT NULL DEFAULT 0,
    tickets_count INT NOT NULL DEFAULT 0,
    average_ticket NUMERIC(14,3) NOT NULL DEFAULT 0,
    cash_total NUMERIC(14,3) NOT NULL DEFAULT 0,
    card_total NUMERIC(14,3) NOT NULL DEFAULT 0,
    other_total NUMERIC(14,3) NOT NULL DEFAULT 0,
    discounts_total NUMERIC(14,3) NOT NULL DEFAULT 0,
    cancellations_count INT NOT NULL DEFAULT 0,
    cancellations_total NUMERIC(14,3) NOT NULL DEFAULT 0,
    refunds_total NUMERIC(14,3) NOT NULL DEFAULT 0,
    cash_in NUMERIC(14,3) NOT NULL DEFAULT 0,
    cash_out NUMERIC(14,3) NOT NULL DEFAULT 0,
    cash_difference NUMERIC(14,3) NOT NULL DEFAULT 0,
    details_json TEXT,
    note VARCHAR(500),
    UNIQUE (point_of_sale_id, business_date)
);

CREATE TABLE receipt_template (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    paper_width INT NOT NULL DEFAULT 80,
    font_size INT NOT NULL DEFAULT 12,
    margin_mm INT NOT NULL DEFAULT 3,
    show_logo BOOLEAN NOT NULL DEFAULT TRUE,
    header_text VARCHAR(500),
    footer_text VARCHAR(500),
    config_json TEXT NOT NULL DEFAULT '{}',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE print_job (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT REFERENCES sale_order(id) ON DELETE CASCADE,
    destination_id BIGINT REFERENCES print_destination(id),
    destination_code VARCHAR(30) NOT NULL,
    title VARCHAR(100) NOT NULL,
    copies INT NOT NULL DEFAULT 1,
    content TEXT NOT NULL,
    status VARCHAR(15) NOT NULL DEFAULT 'PENDING',
    duplicate BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    printed_at TIMESTAMPTZ
);
CREATE INDEX ix_print_job_order ON print_job(order_id);

CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT,
    username VARCHAR(60),
    action VARCHAR(60) NOT NULL,
    entity_type VARCHAR(60),
    entity_id VARCHAR(60),
    details VARCHAR(1000),
    ip_address VARCHAR(60),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_audit_created ON audit_log(created_at);

CREATE TABLE app_setting (
    setting_key VARCHAR(80) PRIMARY KEY,
    setting_value TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
