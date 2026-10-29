-- ============================================================
-- BirrMetrics PostgreSQL Schema (Version 1)
-- Mirrors the SQLite schema, plus users.password_hash and
-- a refresh_tokens table for JWT.
-- ============================================================

-- 1. Users
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    currency VARCHAR(3) NOT NULL DEFAULT 'ETB',
    monthly_budget_santim BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_sync_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- 2. Categories
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    icon VARCHAR(10),
    color VARCHAR(10),
    is_system BOOLEAN NOT NULL DEFAULT FALSE,
    is_deletable BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, name)
);

CREATE INDEX IF NOT EXISTS idx_categories_user ON categories(user_id);

-- 3. Expenses
CREATE TABLE IF NOT EXISTS expenses (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id INT NOT NULL REFERENCES categories(id),
    amount_santim BIGINT NOT NULL CHECK (amount_santim > 0),
    expense_date DATE NOT NULL,
    description TEXT,
    notes TEXT,
    client_updated_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON expenses(user_id, expense_date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_user_cat ON expenses(user_id, category_id);

-- 4. Debts
CREATE TABLE IF NOT EXISTS debts (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    counterparty VARCHAR(100) NOT NULL,
    counterparty_phone VARCHAR(20),
    amount_santim BIGINT NOT NULL CHECK (amount_santim > 0),
    remaining_santim BIGINT NOT NULL CHECK (remaining_santim >= 0),
    is_lent BOOLEAN NOT NULL,
    due_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    notes TEXT,
    client_updated_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_debts_user_status ON debts(user_id, status);

-- 5. Repayments
CREATE TABLE IF NOT EXISTS repayments (
    id SERIAL PRIMARY KEY,
    debt_id INT NOT NULL REFERENCES debts(id) ON DELETE CASCADE,
    amount_santim BIGINT NOT NULL CHECK (amount_santim > 0),
    repayment_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_repayments_debt ON repayments(debt_id);

-- 6. Reminders
CREATE TABLE IF NOT EXISTS reminders (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expense_id INT REFERENCES expenses(id) ON DELETE SET NULL,
    debt_id INT REFERENCES debts(id) ON DELETE SET NULL,
    title VARCHAR(100) NOT NULL,
    body TEXT,
    next_trigger_at TIMESTAMPTZ NOT NULL,
    recurrence VARCHAR(20) NOT NULL DEFAULT 'none',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_triggered_at TIMESTAMPTZ,
    client_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (expense_id IS NULL OR debt_id IS NULL)
);

-- 7. Budgets
CREATE TABLE IF NOT EXISTS budgets (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    period VARCHAR(7) NOT NULL, -- 'YYYY-MM'
    amount_santim BIGINT NOT NULL CHECK (amount_santim >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, period)
);

-- 8. Insights
CREATE TABLE IF NOT EXISTS insights (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rule_key VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    payload_json JSONB,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    triggered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_insights_user ON insights(user_id, triggered_at DESC);

-- 9. Sync Logs (server-side only)
CREATE TABLE IF NOT EXISTS sync_logs (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ NOT NULL,
    finished_at TIMESTAMPTZ,
    uploaded INT NOT NULL DEFAULT 0,
    downloaded INT NOT NULL DEFAULT 0,
    conflicts INT NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL,
    error_msg TEXT
);

-- 10. Refresh Tokens (NEW — for JWT refresh)
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);