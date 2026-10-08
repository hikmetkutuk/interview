package handler

import (
	"fmt"
	"strings"
	"testing"

	"quiz-backend/internal/model"
)

const (
	javaQuestionOneID            = "java-001"
	javaQuestionTwoID            = "java-002"
	javaQuestionOneAlternativeID = "java-001b"
)

func TestSelectPerTopicSelectsOnePerPair(t *testing.T) {
	for _, prefix := range []string{"java", "solid-oop", "mj"} {
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
				assertOneQuestionPerPair(t, selectPerTopic(questions), 12)
			}
		})
	}
}

func assertOneQuestionPerPair(t *testing.T, selected []model.Question, want int) {
	t.Helper()
	if len(selected) != want {
		t.Fatalf("selected %d questions, want %d", len(selected), want)
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

func TestSelectPerTopicPreservesUnpairedQuestions(t *testing.T) {
	tests := []struct {
		name      string
		questions []model.Question
		want      int
	}{
		{
			name: "same order alone does not form a pair",
			questions: []model.Question{
				{ID: javaQuestionOneID, SortOrder: 1},
				{ID: javaQuestionTwoID, SortOrder: 1},
			},
			want: 2,
		},
		{
			name: "alternative with a different order stays separate",
			questions: []model.Question{
				{ID: javaQuestionOneID, SortOrder: 1},
				{ID: javaQuestionOneAlternativeID, SortOrder: 2},
			},
			want: 2,
		},
		{
			name: "questions from different quizzes stay separate",
			questions: []model.Question{
				{ID: javaQuestionOneID, QuizID: "one", SortOrder: 1},
				{ID: javaQuestionOneAlternativeID, QuizID: "two", SortOrder: 1},
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
				{ID: javaQuestionOneID, SortOrder: 1},
				{ID: javaQuestionOneAlternativeID, SortOrder: 1},
				{ID: javaQuestionTwoID, SortOrder: 2},
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
	if got, want := detectTopic(model.Question{ID: javaQuestionTwoID + "b"}), detectTopic(model.Question{ID: javaQuestionTwoID}); got != want {
		t.Fatalf("alternative topic %q differs from base topic %q", got, want)
	}
}

func TestDetectOOPTopics(t *testing.T) {
	topics := map[string]string{
		"oop-001": "OOP Prensipleri",
		"oop-002": "Tasarım Kalıpları",
		"oop-003": "SOLID",
		"oop-004": "Interface / Abstract Class",
		"oop-005": "Abstraction / Polymorphism",
		"oop-006": "Inheritance / Composition",
		"oop-007": "Overloading / Overriding",
		"oop-008": "Encapsulation",
	}
	for id, want := range topics {
		for _, suffix := range []string{"", "b"} {
			t.Run(id+suffix, func(t *testing.T) {
				if got := detectTopic(model.Question{ID: id + suffix}); got != want {
					t.Fatalf("topic = %q, want %q", got, want)
				}
			})
		}
	}
}

func TestDetectModernJavaTopics(t *testing.T) {
	topics := map[string]string{
		"mj-001": "Stream API",
		"mj-002": "Optional",
		"mj-003": "Lambda / Functional Interface",
		"mj-004": "Record",
		"mj-005": "Sealed Classes / Pattern Matching",
		"mj-006": "var / Switch Expressions",
		"mj-007": "Generics / Wildcards / PECS",
		"mj-008": "Java LTS / Virtual Threads / ScopedValue",
	}
	for id, want := range topics {
		for _, suffix := range []string{"", "b"} {
			t.Run(id+suffix, func(t *testing.T) {
				if got := detectTopic(model.Question{ID: id + suffix}); got != want {
					t.Fatalf("topic = %q, want %q", got, want)
				}
			})
		}
	}
}
