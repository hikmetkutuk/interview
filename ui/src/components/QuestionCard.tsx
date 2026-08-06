import type { Question, Option } from "../types";

interface Props {
  readonly question: Question;
  readonly options: Option[];
  readonly selectedIds: string[];
  readonly onSelect: (optionId: string) => void;
  readonly questionIndex: number;
  readonly totalQuestions: number;
}

export default function QuestionCard({
  question,
  options,
  selectedIds,
  onSelect,
  questionIndex,
  totalQuestions,
}: Props) {
  const isMulti = question.type === "maq";

  return (
    <div className="bg-white border border-gray-200 rounded-lg p-6">
      <div className="flex items-center justify-between mb-4">
        <span className="text-sm font-medium text-indigo-600">
          Question {questionIndex + 1} of {totalQuestions}
        </span>
        <span className="text-xs text-gray-400 bg-gray-100 px-2 py-1 rounded">
          {question.type.toUpperCase()} &middot; {question.score} pts
        </span>
      </div>

      <h2 className="text-lg font-semibold text-gray-900 mb-3">{question.text}</h2>

      {question.image_url && (
        <img
          src={question.image_url}
          alt=""
          className="max-w-full rounded-md mb-3"
        />
      )}

      {question.code_snippet && (
        <pre className="bg-gray-900 text-green-300 text-sm p-4 rounded-md overflow-x-auto mb-3">
          <code>{question.code_snippet}</code>
        </pre>
      )}

      <div className="flex flex-col gap-2 mt-4">
        {options.map((opt) => {
          const checked = selectedIds.includes(opt.id);
          return (
            <label
              key={opt.id}
              className={`flex items-center gap-3 p-3 rounded-md border cursor-pointer transition-colors ${
                checked
                  ? "border-indigo-500 bg-indigo-50"
                  : "border-gray-200 hover:bg-gray-50"
              }`}
            >
              <input
                type={isMulti ? "checkbox" : "radio"}
                name={`question-${question.id}`}
                checked={checked}
                onChange={() => onSelect(opt.id)}
                className="accent-indigo-600"
              />
              <span className="text-sm text-gray-800">{opt.text}</span>
            </label>
          );
        })}
      </div>
    </div>
  );
}
