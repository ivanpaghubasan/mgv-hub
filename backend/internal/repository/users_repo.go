package repository

import (
	"context"
	"database/sql"

	"github.com/ivanpaghubasan/mgv-hub-backend/internal/model"
)

type Users interface {
	GetByEmail(ctx context.Context, email string) (*model.Account, error)
	GetByID(ctx context.Context, id int) (*model.Account, error)
	ChangePassword(ctx context.Context, account *model.Account) error
}

type UsersRepoImpl struct {
	db *sql.DB
}

func NewUsersRepo(db *sql.DB) *UsersRepoImpl {
	return &UsersRepoImpl{db: db}
}

func (s *UsersRepoImpl) GetByEmail(ctx context.Context, email string) (*model.Account, error) {
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

func (s *UsersRepoImpl) GetByID(ctx context.Context, id int) (*model.Account, error) {
	ctx, cancel := context.WithTimeout(ctx, QueryTimeoutDuration)
	defer cancel()

	query := `SELECT id, role_id, email, password_hash, password_change_required, is_active, last_login_at, created_at, updated_at FROM accounts WHERE id = $1`

	rows := s.db.QueryRowContext(ctx, query, id)
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

func (c *UsersRepoImpl) ChangePassword(ctx context.Context, account *model.Account) error {
	ctx, cancel := context.WithTimeout(ctx, QueryTimeoutDuration)
	defer cancel()

	query := `UPDATE accounts SET password_hash = $1 WHERE id = $2`

	_, err := c.db.ExecContext(ctx, query, account.PasswordHash, account.ID)

	return err
}
