package db

import (
	"context"
	"database/sql"
	"time"

	_ "github.com/lib/pq"

	"github.com/ivanpaghubasan/mgv-hub-backend/internal/config"
)

func New(config config.DbConfig) (*sql.DB, error) {
	db, err := sql.Open("postgres", config.DSN)
	if err != nil {
		return nil, err
	}

	db.SetMaxOpenConns(config.MaxOpenConns)
	db.SetMaxIdleConns(config.MaxIdleConns)

	duration, err := time.ParseDuration(config.MaxIdleItem)
	if err != nil {
		return nil, err
	}

	db.SetConnMaxIdleTime(duration)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		return nil, err
	}

	return db, nil
}
