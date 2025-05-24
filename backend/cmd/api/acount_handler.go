package main

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

type AuthenticatePayload struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required,min=6"`
}

func (app *application) Authenticate(ctx *gin.Context) {
	var payload AuthenticatePayload

	if err := ctx.BindJSON(&payload); err != nil {
		ctx.JSON(http.StatusBadRequest, err.Error())
		return
	}

	if err := app.validate.Struct(&payload); err != nil {
		ctx.JSON(http.StatusBadRequest, err.Error())
		return
	}

	account, err := app.repository.Users.GetByEmail(ctx, payload.Email)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, err.Error())
		return
	}

	valid, err := account.PasswordMatches(payload.Password)
	if err != nil || !valid {
		ctx.JSON(http.StatusBadRequest, errors.New("invalid credentials"))
		return
	}

	// JWT Token

	ctx.JSON(http.StatusOK, account)
}

type ChangePasswordPayload struct {
	OldPassword string `json:"oldPassword" validate:"required,min=6"`
	NewPassword string `json:"newPassword" validate:"required,min=6"`
}

func (app *application) ChangeDefaultPassword(c *gin.Context) {
	var payload ChangePasswordPayload
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	if err := c.BindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	if err := app.validate.Struct(&payload); err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	account, err := app.repository.GetByID(c, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, err.Error())
		return
	}

	valid, err := account.PasswordMatches(payload.OldPassword)
	if err != nil || !valid {
		c.JSON(http.StatusInternalServerError, err.Error())
		return
	}

	account.HashPassword(payload.NewPassword)

	err = app.repository.ChangePassword(c, account)
	if err != nil {
		c.JSON(http.StatusInternalServerError, err.Error())
		return
	}
    
	c.JSON(http.StatusOK, nil)
}
