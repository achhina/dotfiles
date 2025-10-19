---
description: Insert clipboard content as code block
---

```
$(if command -v pbpaste >/dev/null 2>&1; then pbpaste; else xclip -selection clipboard -o; fi)
```
