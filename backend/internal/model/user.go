package model

import "time"

type Role struct {
	ID        int64     `db:"id" json:"id"`
	Name      string    `db:"name" json:"name"`
	CreatedAt time.Time `db:"created_at" json:"created_at"`
	UpdatedAt time.Time `db:"updated_at" json:"updated_at"`
}

type Account struct {
	ID                     int64      `db:"id" json:"id"`
	RoleID                 int64      `db:"role_id" json:"role_id"`
	Email                  string     `db:"email" json:"email"`
	PasswordHash           string     `db:"password_hash" json:"-"` // Don't expose password hash in json
	PasswordChangeRequired bool       `db:"password_change_required" json:"password_change_required"`
	IsActive               bool       `db:"is_active" json:"is_active"`
	LastLoginAt            *time.Time `db:"last_login_at" json:"last_login_at,omitempty"`
	CreatedAt              time.Time  `db:"created_at" json:"created_at"`
	UpdatedAt              time.Time  `db:"updated_at" json:"updated_at"`
	Role                   *Role      `db:"-" json:"role,omitempty"` // db:"-" prevents sqlx from trying to scan into this field
}
