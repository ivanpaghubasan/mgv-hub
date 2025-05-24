package main

import (
	"fmt"

	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
	"github.com/ivanpaghubasan/mgv-hub-backend/internal/config"
	"github.com/ivanpaghubasan/mgv-hub-backend/internal/repository"
)

type application struct {
	config     config.Config
	repository repository.Repository
	router     *gin.Engine
	validate   *validator.Validate
}

func (app *application) start() {
	app.router.Run(fmt.Sprintf(":%s", app.config.Port))
}
