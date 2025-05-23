package main

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func (app *application) registerRoutes() {
	r := app.router
	v1Router := r.Group("/v1")
	v1Router.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "pong",
		})
	})

	authRouter := v1Router.Group("/auth")
	authRouter.POST("/login", app.Authenticate)

}
