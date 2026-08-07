package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"
	"time"
)

const defaultRunnerURL = "http://runner:8090/execute"

type runnerRequest struct {
	Code     string `json:"code"`
	Language string `json:"language"`
	Stdin    string `json:"stdin"`
}

type runnerResponse struct {
	Output string `json:"output"`
	Error  string `json:"error"`
}

func executeCode(ctx context.Context, code, language, stdin string) (string, error) {
	ctx, cancel := context.WithTimeout(ctx, 12*time.Second)
	defer cancel()

	body, err := json.Marshal(runnerRequest{
		Code:     code,
		Language: language,
		Stdin:    stdin,
	})
	if err != nil {
		return "", fmt.Errorf("encode runner request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, runnerURL(), bytes.NewReader(body))
	if err != nil {
		return "", fmt.Errorf("create runner request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("call runner: %w", err)
	}
	defer resp.Body.Close()

	var result runnerResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", fmt.Errorf("decode runner response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		if result.Error != "" {
			return result.Output, fmt.Errorf("runner returned %d: %s", resp.StatusCode, result.Error)
		}
		return result.Output, fmt.Errorf("runner returned %d", resp.StatusCode)
	}

	if result.Error != "" {
		return result.Output, errors.New(result.Error)
	}

	return result.Output, nil
}

func runnerURL() string {
	if url := os.Getenv("RUNNER_URL"); url != "" {
		return url
	}
	return defaultRunnerURL
}
