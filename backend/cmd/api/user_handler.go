package main

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
)

type AuthenticatePayload struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (app *application) Authenticate(ctx *gin.Context) {
	var payload AuthenticatePayload

	if err := ctx.BindJSON(&payload); err != nil {
		ctx.JSON(http.StatusBadRequest, err.Error())
		return
	}

	account, err := app.repository.Users.GetAccountByEmail(ctx, payload.Email)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, err.Error())
		return
	}

	valid, err := account.PasswordMatches(payload.Password)
	if err != nil || !valid {
		ctx.JSON(http.StatusBadRequest, errors.New("invalid credentials"))
		return
	}

	ctx.JSON(http.StatusOK, account)
}
