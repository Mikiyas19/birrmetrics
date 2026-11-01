package service

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type SyncBatch struct {
	Expenses []map[string]any `json:"expenses"`
	Debts    []map[string]any `json:"debts"`
}

type PullResponse struct {
	ServerTime string           `json:"server_time"`
	Expenses   []map[string]any `json:"expenses"`
	Debts      []map[string]any `json:"debts"`
}

type SyncService struct {
	db *pgxpool.Pool
}

func NewSyncService(db *pgxpool.Pool) *SyncService {
	return &SyncService{db: db}
}

func (s *SyncService) ProcessBatch(ctx context.Context, userID int, batch SyncBatch) error {
	tx, err := s.db.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	// Process Expenses (UPSERT)
	for _, e := range batch.Expenses {
		_, err := tx.Exec(ctx, `
			INSERT INTO expenses (id, user_id, category_id, amount_santim, expense_date, description, client_updated_at, created_at, deleted_at)
			VALUES ($1, $2, $3, $4, $5::date, $6, $7::timestamptz, $8::timestamptz, $9::timestamptz)
			ON CONFLICT (id) DO UPDATE SET
				category_id = EXCLUDED.category_id,
				amount_santim = EXCLUDED.amount_santim,
				expense_date = EXCLUDED.expense_date,
				description = EXCLUDED.description,
				client_updated_at = EXCLUDED.client_updated_at,
				deleted_at = EXCLUDED.deleted_at
			WHERE expenses.client_updated_at < EXCLUDED.client_updated_at`,
			e["id"], userID, e["category_id"], e["amount_santim"], e["expense_date"], e["description"], e["client_updated_at"], e["created_at"], e["deleted_at"],
		)
		if err != nil {
			fmt.Printf("Failed to upsert expense: %v\n", err)
			return err
		}
	}

	// Process Debts (UPSERT)
	for _, d := range batch.Debts {
		isLentBool := false
		if val, ok := d["is_lent"]; ok {
			switch v := val.(type) {
			case bool:
				isLentBool = v
			case float64:
				isLentBool = v == 1
			case int:
				isLentBool = v == 1
			}
		}

		_, err := tx.Exec(ctx, `
			INSERT INTO debts (id, user_id, counterparty, amount_santim, remaining_santim, is_lent, due_date, status, client_updated_at, created_at, deleted_at)
			VALUES ($1, $2, $3, $4, $5, $6::boolean, $7::date, $8, $9::timestamptz, $10::timestamptz, $11::timestamptz)
			ON CONFLICT (id) DO UPDATE SET
				counterparty = EXCLUDED.counterparty,
				amount_santim = EXCLUDED.amount_santim,
				remaining_santim = EXCLUDED.remaining_santim,
				is_lent = EXCLUDED.is_lent,
				due_date = EXCLUDED.due_date,
				status = EXCLUDED.status,
				client_updated_at = EXCLUDED.client_updated_at,
				deleted_at = EXCLUDED.deleted_at
			WHERE debts.client_updated_at < EXCLUDED.client_updated_at`,
			d["id"], userID, d["counterparty"], d["amount_santim"], d["remaining_santim"], isLentBool, d["due_date"], d["status"], d["client_updated_at"], d["created_at"], d["deleted_at"],
		)
		if err != nil {
			fmt.Printf("Failed to upsert debt: %v\n", err)
			return err
		}
	}

	return tx.Commit(ctx)
}

func (s *SyncService) GetChangesSince(ctx context.Context, userID int, since time.Time) (*PullResponse, error) {
	expRows, err := s.db.Query(ctx, `
		SELECT id, category_id, amount_santim, expense_date, description, client_updated_at, created_at, deleted_at
		FROM expenses
		WHERE user_id = $1 AND created_at > $2`, userID, since)
	if err != nil {
		return nil, err
	}
	defer expRows.Close()

	var expenses []map[string]any
	for expRows.Next() {
		var id, catID int
		var amount int64
		var date, clientUpdated, createdAt time.Time
		var desc *string
		var deletedAt *time.Time
		if err := expRows.Scan(&id, &catID, &amount, &date, &desc, &clientUpdated, &createdAt, &deletedAt); err != nil {
			return nil, err
		}
		expenses = append(expenses, map[string]any{
			"id": id, "category_id": catID, "amount_santim": amount,
			"expense_date": date, "description": desc,
			"client_updated_at": clientUpdated, "created_at": createdAt,
			"deleted_at": deletedAt,
		})
	}

	debtRows, err := s.db.Query(ctx, `
		SELECT id, counterparty, amount_santim, remaining_santim, is_lent, due_date, status, client_updated_at, created_at, deleted_at
		FROM debts
		WHERE user_id = $1 AND created_at > $2`, userID, since)
	if err != nil {
		return nil, err
	}
	defer debtRows.Close()

	var debts []map[string]any
	for debtRows.Next() {
		var id int
		var amount, remaining int64
		var isLent bool
		var counterparty, status string
		var dueDate *time.Time
		var clientUpdated, createdAt time.Time
		var deletedAt *time.Time
		if err := debtRows.Scan(&id, &counterparty, &amount, &remaining, &isLent, &dueDate, &status, &clientUpdated, &createdAt, &deletedAt); err != nil {
			return nil, err
		}
		debts = append(debts, map[string]any{
			"id": id, "counterparty": counterparty, "amount_santim": amount,
			"remaining_santim": remaining, "is_lent": isLent,
			"due_date": dueDate, "status": status,
			"client_updated_at": clientUpdated, "created_at": createdAt,
			"deleted_at": deletedAt,
		})
	}

	return &PullResponse{
		ServerTime: time.Now().UTC().Format(time.RFC3339),
		Expenses:   expenses,
		Debts:      debts,
	}, nil
}
