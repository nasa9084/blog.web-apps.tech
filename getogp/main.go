package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/otiai10/opengraph/v2"
)

func main() {
	if err := execute(); err != nil {
		log.Print(err)
		os.Exit(1)
	}
}

func execute() error {
	http.HandleFunc("/ogp", func(w http.ResponseWriter, r *http.Request) {
		url := r.URL.Query().Get("url")
		if url == "" {
			http.Error(w, `{"message": "url parameter is required"}`, http.StatusBadRequest)
			return
		}
		log.Printf("request URL: %s", url)

		ogp, err := opengraph.Fetch(url)
		if err != nil {
			http.Error(w, fmt.Sprintf(`{"message": "error fetching OGP", "error": "%s"}`, err.Error()), http.StatusInternalServerError)
			return
		}

		if err := ogp.ToAbs(); err != nil {
			http.Error(w, fmt.Sprintf(`{"message": "error converting relative URLs to absolute URLs", "error": "%s"}`, err.Error()), http.StatusInternalServerError)
			return
		}

		var body bytes.Buffer
		if err := json.NewEncoder(&body).Encode(ogp); err != nil {
			http.Error(w, fmt.Sprintf(`{"message": "error encoding OGP info to JSON", "error": "%s"}`, err.Error()), http.StatusInternalServerError)
			return
		}

		w.WriteHeader(http.StatusOK)
		body.WriteTo(w)
	})

	return http.ListenAndServe(":8080", nil)
}
