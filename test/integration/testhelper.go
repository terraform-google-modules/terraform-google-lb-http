package test

import (
	"io"
	"net/http"

	"github.com/stretchr/testify/assert"
)

func AssertResponseStatus(assert *assert.Assertions, url string, statusCode int) {
	var resStatusCode int
	resStatusCode, _, _ = httpGetRequest(url)
	assert.Equal(resStatusCode, statusCode)
}

func httpGetRequest(url string) (statusCode int, body string, err error) {
	res, err := http.Get(url)
	if err != nil {
		return 0, "", err
	}
	defer res.Body.Close()

	buffer, err := io.ReadAll(res.Body)
	return res.StatusCode, string(buffer), err
}
