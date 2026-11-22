# Gemini Prompt Comparison

Model: `gemini-3.5-flash-lite`
Temperature: `0`

## Classification results

- Valid classifications: 9
- Blank notes skipped: 1
- Total notes processed: 10

## V1 versus V2

| Note | V1 Simple | V2 CRAFT |
|---|---|---|
| N007 | invalid | valid |
| N009 | invalid | valid |

## Findings

V1 simple prompting returned JSON that failed the required Pydantic schema for both evaluated notes.

V2 CRAFT prompting returned schema-valid JSON for both notes.

This small two-note experiment supports using the CRAFT prompt for structured extraction, but does not establish general superiority or clinical accuracy.

Raw responses and validation details are preserved in `gemini_prompt_comparison.json`.
