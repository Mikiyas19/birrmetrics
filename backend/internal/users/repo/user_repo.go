package repo

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type User struct {
	ID           int
	Email        string
	PasswordHash string
	FullName     string
	CreatedAt    time.Time
}

type UserRepo struct {
	db *pgxpool.Pool
}

func NewUserRepo(db *pgxpool.Pool) *UserRepo {
	return &UserRepo{db: db}
}

func (r *UserRepo) Create(ctx context.Context, email, passwordHash, fullName string) (*User, error) {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	var u User
	err = tx.QueryRow(ctx,
		`INSERT INTO users (email, password_hash, full_name)
		 VALUES ($1, $2, $3)
		 RETURNING id, email, password_hash, COALESCE(full_name, ''), created_at`,
		email, passwordHash, fullName,
	).Scan(&u.ID, &u.Email, &u.PasswordHash, &u.FullName, &u.CreatedAt)
	if err != nil {
		return nil, err
	}

	// Auto-seed default categories for the new user
	_, err = tx.Exec(ctx, `
		INSERT INTO categories (user_id, name, icon, color, is_system, is_deletable) VALUES
		($1, 'Food', '🍔', '#F2A65A', TRUE, FALSE),
		($1, 'Transport', '🚌', '#3B82F6', TRUE, FALSE),
		($1, 'Education', '📚', '#8B5CF6', TRUE, FALSE),
		($1, 'Fun', '🎬', '#EC4899', TRUE, FALSE),
		($1, 'Health', '💊', '#E04F5F', TRUE, FALSE),
		($1, 'Bills', '🧾', '#F59E0B', TRUE, FALSE),
		($1, 'Other', '🏷️', '#8B97A5', TRUE, FALSE)`,
		u.ID,
	)
	if err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return &u, nil
}

func (r *UserRepo) FindByEmail(ctx context.Context, email string) (*User, error) {
	var u User
	err := r.db.QueryRow(ctx,
		`SELECT id, email, password_hash, COALESCE(full_name, ''), created_at
		 FROM users WHERE email = $1`,
		email,
	).Scan(&u.ID, &u.Email, &u.PasswordHash, &u.FullName, &u.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &u, nil
}

func (r *UserRepo) FindByID(ctx context.Context, id int) (*User, error) {
	var u User
	err := r.db.QueryRow(ctx,
		`SELECT id, email, password_hash, COALESCE(full_name, ''), created_at
		 FROM users WHERE id = $1`,
		id,
	).Scan(&u.ID, &u.Email, &u.PasswordHash, &u.FullName, &u.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &u, nil
}
