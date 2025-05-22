package main

import (
	"fmt"

	"github.com/gin-gonic/gin"
	"github.com/ivanpaghubasan/mgv-hub-backend/internal/config"
	"github.com/ivanpaghubasan/mgv-hub-backend/internal/repository"
)

type application struct {
	config     config.Config
	repository repository.Repositories
	router     *gin.Engine
}

func (app *application) start() {
	app.router.Run(fmt.Sprintf(":%s", app.config.Port))
}
