## 🚧👷 Under Construction 👷🚧

# AI Agent Red Team Repository
An adversarial repository for agent testing.

## Overview
Unlike traditional chatbots, where the user converses with the system via a textbox, AI agents operate in a more complex environment. They can execute code, interact with APIs, and perform tasks autonomously. This repository is designed to test the robustness of AI agents against various forms of [prompt injection attacks](https://en.wikipedia.org/wiki/Prompt_injection).

---

## How It Works
### Expected Behavior

| Model Type     |  Behavior                                             |
|----------------|-------------------------------------------------------|
| **Vulnerable** | Follows the hidden instruction (e.g., replying in a language it shouldn’t) |
| **Hardened**   | Ignores hidden instructions or raises an error, responding only to visible text |

---

## Attack Inventory

- `prompt_injection__direct__basic` — classic suffix override
- `confusables__invisible_unicode` — zero-width stealth injection
- `whisper_attack__trigger_audio` — audio poisoning using phrases
- `tool_injection__flask_trap` — tool misuse via poisoned webserver

---

## Resources

### Design Patterns for Securing LLM Agents against Prompt Injection
  - [Rohan Paul](https://x.com/rohanpaul_ai/status/1934384162418708536)
  - [arxiv](https://arxiv.org/abs/2506.08837)

### Google's Approach to AI security
  - [Simon Willison](https://simonwillison.net/2025/Jun/15/ai-agent-security/)

### Misc
  - [Indirect Prompt Injection](https://x.com/lefthanddraft/status/1920546798893998402)
  - [Abusing Images and Sounds for Indirect Instruction Injection in Multi-Modal LLMs](https://arxiv.org/abs/2307.10490)
  - [Prompt Injection ToolKit](https://x.com/PreambleAI/status/1946179395040710702)
  - [OWASP](https://genai.owasp.org/resource/owasp-top-10-for-llm-applications-2025/)
  - [Andrew Karpathy on X](https://x.com/karpathy/status/1889714240878940659)
  - [Joseph Thacker on X](https://x.com/rez0__/status/1942563155005026598)
  - [Joseph Thacker - Invisible Prompt Injection](https://josephthacker.com/invisible_prompt_injection)
  - [Covert Prompt Injection Techniques](https://www.reddit.com/r/feddiscussion/comments/1j2l6xy/fun_with_ai/?utm_source=chatgpt.com)
  - [Paul Butler - Smuggling Arbitrary Data Through an Emoji](https://paulbutler.org/2025/smuggling-arbitrary-data-through-an-emoji/)
  - [Google Bard Data Exfiltration through Markdown](https://embracethered.com/blog/posts/2023/google-bard-data-exfiltration/)
