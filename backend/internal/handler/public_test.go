package handler

import (
	"fmt"
	"strings"
	"testing"

	"quiz-backend/internal/model"
)

func TestSelectPerTopicSelectsOnePerPair(t *testing.T) {
	for _, prefix := range []string{"java", "solid-oop"} {
		t.Run(prefix, func(t *testing.T) {
			questions := make([]model.Question, 0, 24)
			for i := 1; i <= 12; i++ {
				id := fmt.Sprintf("%s-%03d", prefix, i)
				questions = append(questions,
					model.Question{ID: id, QuizID: "quiz", SortOrder: i},
					model.Question{ID: id + "b", QuizID: "quiz", SortOrder: i},
				)
			}
			for run := 0; run < 100; run++ {
				selected := selectPerTopic(questions)
				if len(selected) != 12 {
					t.Fatalf("selected %d questions, want 12", len(selected))
				}
				seen := make(map[string]bool)
				for _, q := range selected {
					id := strings.TrimSuffix(q.ID, "b")
					if seen[id] {
						t.Fatalf("both alternatives selected for %s", id)
					}
					seen[id] = true
				}
			}
		})
	}
}

func TestSelectPerTopicPreservesUnpairedQuestions(t *testing.T) {
	tests := []struct {
		name      string
		questions []model.Question
		want      int
	}{
		{
			name: "same order alone does not form a pair",
			questions: []model.Question{
				{ID: "java-001", SortOrder: 1},
				{ID: "java-002", SortOrder: 1},
			},
			want: 2,
		},
		{
			name: "alternative with a different order stays separate",
			questions: []model.Question{
				{ID: "java-001", SortOrder: 1},
				{ID: "java-001b", SortOrder: 2},
			},
			want: 2,
		},
		{
			name: "questions from different quizzes stay separate",
			questions: []model.Question{
				{ID: "java-001", QuizID: "one", SortOrder: 1},
				{ID: "java-001b", QuizID: "two", SortOrder: 1},
			},
			want: 2,
		},
		{
			name: "existing topic limit is preserved",
			questions: []model.Question{
				{ID: "di-001", SortOrder: 99},
				{ID: "di-002", SortOrder: 99},
				{ID: "di-003", SortOrder: 99},
			},
			want: 2,
		},
		{
			name: "paired and unpaired questions coexist",
			questions: []model.Question{
				{ID: "java-001", SortOrder: 1},
				{ID: "java-001b", SortOrder: 1},
				{ID: "java-002", SortOrder: 2},
			},
			want: 2,
		},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := len(selectPerTopic(test.questions)); got != test.want {
				t.Fatalf("selected %d questions, want %d", got, test.want)
			}
		})
	}
}

func TestDetectTopicForAlternative(t *testing.T) {
	if got, want := detectTopic(model.Question{ID: "java-002b"}), detectTopic(model.Question{ID: "java-002"}); got != want {
		t.Fatalf("alternative topic %q differs from base topic %q", got, want)
	}
}
