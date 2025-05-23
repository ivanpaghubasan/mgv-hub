package config

import (
	"fmt"
	"os"
	"strconv"
)

type Config struct {
	Port   string
	DB     DbConfig
	Env    string
	ApiUrl string
}

type DbConfig struct {
	DSN          string
	MaxOpenConns int
	MaxIdleConns int
	MaxIdleItem  string
}

func LoadConfig() Config {
	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s", getEnvString("DB_USER", "mgv_user"), getEnvString("DB_PASSWORD", "mgv_password"), getEnvString("DB_HOST", "localhost"), os.Getenv("DB_PORT"), getEnvString("DB_NAME", "mgv_hub_db"), os.Getenv("DB_SSLMODE"))

	return Config{
		Port:   getEnvString("PORT", "9090"),
		ApiUrl: getEnvString("API_URL", "localhost:9090"),
		DB: DbConfig{
			DSN:          dsn,
			MaxOpenConns: getEnvInt("DB_MAX_OPEN_CONNS", 30),
			MaxIdleConns: getEnvInt("DB_MAX_IDLE_CONNS", 30),
			MaxIdleItem:  getEnvString("DB_NAX_IDLE_TIME", "15m"),
		},
	}
}

func getEnvString(key, fallback string) string {
	val, ok := os.LookupEnv(key)
	if !ok {
		return fallback
	}

	return val
}

func getEnvInt(key string, fallback int) int {
	val, ok := os.LookupEnv(key)
	if !ok {
		return fallback
	}

	envInt, err := strconv.Atoi(val)
	if err != nil {
		return fallback
	}

	return envInt
}
