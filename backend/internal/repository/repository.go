package repository

import (
	"database/sql"
	"errors"
	"time"
)

var (
	ErrNotFound          = errors.New("record not found")
	QueryTimeoutDuration = time.Second * 5
)

type Repository struct {
	Users
}

func New(db *sql.DB) Repository {
	return Repository{
		Users: NewUserRepo(db),
	}
}
