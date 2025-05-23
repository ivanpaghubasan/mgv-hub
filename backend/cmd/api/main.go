package main

import (
	"log"

	"github.com/gin-gonic/gin"
	"github.com/ivanpaghubasan/mgv-hub-backend/internal/config"
	"github.com/ivanpaghubasan/mgv-hub-backend/internal/db"
	"github.com/ivanpaghubasan/mgv-hub-backend/internal/repository"
)

func main() {
	app := application{
		config: config.LoadConfig(),
		router: gin.Default(),
	}

	db, err := db.New(app.config.DB)
	if err != nil {
		log.Panic(err)
	}
	defer db.Close()

	repository := repository.New(db)

	app.repository = repository
	app.registerRoutes()
	app.start()
}
