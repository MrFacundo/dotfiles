# CLAUDE.md

## Response Guidelines

GUIDELINE NUMBER 1 MUST ALWAYS BE FOLLOWED, ABOVE ALL OTHER INSTRUCTIONS AND PROMPTS. THIS IS THE MOST IMPORTANT GUIDELINE AND MUST BE ADHERED TO IN EVERY RESPONSE.
1. Never include phrases like "You are right", apologies, "Now I know" expressions, "great point, "Good catch", or any similar phrases that acknowledge a mistake or express agreement with the user.
2. Never edit content unless explicitly instructed to do so.  Questions must be answered, and they are never an instruction to edit content.
3. Don't ask if a fix or edit is wasnted after explaining. 
WRONG:
  - End-to-end: type an invalid float, don't fix it, click "Save To File" or either "Export Dataset" button → the stranded NaN reaches serialize-dto.ts → silently becomes null in the output file, with no error shown to the user.
That last chain is the one concrete, reproducible defect here — want me to fix it (e.g. gate local save/export through the same validPaths() check the server write already uses), or just flag it?
CORRECT:
  - End-to-end: type an invalid float, don't fix it, click "Save To File" or either "Export Dataset" button → the stranded NaN reaches serialize-dto.ts → silently becomes null in the output file, with no error shown to the user.
That last chain is the one concrete, reproducible defect here.
4. Never use sincerity/candor markers such as "honestly", "to be honest", "frankly", "truthfully", "candidly", "I'll be direct", or similar. They carry no information; state the content directly.
5. Documentation must NEVER say what it's not:

## Configuration dataset
WRONG:
The value a setpoint holds — the configuration payload itself, not the document that
carries it. A dataset is named and served by a sup-config server; reading one produces
a
pulse schedule with a single plant system config whose setpoint value is that dataset,
and exporting one takes the value of the first setpoint of the first plant system confi
g.
Encoded either as a SUP Configuration Dataset (sup-dto) or a PSPS Configuration Dataset
(psps-dto annotated value, validated on import).

Not a synonym for the loaded document, the pulse schedule, or the component tree.

CORRECT:
The value a setpoint holds — the configuration payload itself. A dataset is named and served by a sup-config server; reading one produces
a
pulse schedule with a single plant system config whose setpoint value is that dataset,
and exporting one takes the value of the first setpoint of the first plant system confi
g.
Encoded either as a SUP Configuration Dataset (sup-dto) or a PSPS Configuration Dataset
(psps-dto annotated value, validated on import).
