package repository

import (
	"context"
	"database/sql"

	"github.com/ivanpaghubasan/mgv-hub-backend/internal/model"
)

type Users interface {
	GetAccountByEmail(ctx context.Context, email string) (*model.Account, error)
}

type UserRepoImpl struct {
	db *sql.DB
}

func NewUserRepo(db *sql.DB) *UserRepoImpl {
	return &UserRepoImpl{db: db}
}

func (s *UserRepoImpl) GetAccountByEmail(ctx context.Context, email string) (*model.Account, error) {
	ctx, cancel := context.WithTimeout(ctx, QueryTimeoutDuration)
	defer cancel()

	query := `SELECT id, role_id, email, password_hash, password_change_required, is_active, last_login_at, created_at, updated_at FROM accounts WHERE email = $1`

	rows := s.db.QueryRowContext(ctx, query, email)
	var account model.Account
	err := rows.Scan(
		&account.ID,
		&account.RoleID,
		&account.Email,
		&account.PasswordHash,
		&account.PasswordChangeRequired,
		&account.IsActive,
		&account.LastLoginAt,
		&account.CreatedAt,
		&account.UpdatedAt,
	)
	if err != nil {
		switch err {
		case sql.ErrNoRows:
			return nil, ErrNotFound
		default:
			return nil, err
		}
	}

	return &account, nil
}
