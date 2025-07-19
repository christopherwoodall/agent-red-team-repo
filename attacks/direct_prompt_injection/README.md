# Confusables
Use zero‑width and look‑alike Unicode characters to craft inputs that look normal to humans but are distinct under the hood, causing AI models to misinterpret or misroute text.

---

## Description
By inserting invisible characters (for example, ZERO WIDTH SPACE) or visually confusable code points (such as Cyrillic “а” instead of Latin “a”), this attack can:  
- Bypass keyword filters  
- Redirect model behavior  
- Smuggle hidden instructions or data  

It exploits the model’s tokenization and normalization processes to hide malicious payloads.

---

## Techniques
1. Unicode Homoglyph Substitution
    - Replace characters with visually identical Unicode characters (e.g., Cyrillic 'а' vs. Latin 'a') to confuse tokenization.
    
    Example: Instead of "Аpple", use "Apple" (where the a is actually Cyrillic).

    This can lead to incorrect keyword extraction, reducing effective NLP processing.





---

## Mitigation
- Normalize or strip invisible Unicode characters before sending user input.  
- Display hidden characters in text editors or diff tools.  
- Include Unicode-aware filters in your input sanitation pipeline.

---

## Resources
  - [Andrew Karpathy on X](https://x.com/karpathy/status/1889714240878940659)
  - [Joseph Thacker on X](https://x.com/rez0__/status/1942563155005026598)
  - [Joseph Thacker - Invisible Prompt Injection](https://josephthacker.com/invisible_prompt_injection)
  - [Paul Butler - Smuggling Arbitrary Data Through an Emoji](https://paulbutler.org/2025/smuggling-arbitrary-data-through-an-emoji/)
  - [Google Bard Data Exfiltration through Markdown](https://embracethered.com/blog/posts/2023/google-bard-data-exfiltration/)
  - [Covert Prompt Injection Techniques](https://www.reddit.com/r/feddiscussion/comments/1j2l6xy/fun_with_ai/?utm_source=chatgpt.com)
