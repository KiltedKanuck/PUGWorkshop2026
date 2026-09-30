---
applyTo: '**/*.{c,h}'
---

# Secure String Operations (utsecstr)

Use Progress secure string operations from `utsecstr.c`/`utsecstr.h` instead of unsafe C runtime string APIs. These are cross-platform (Windows, Linux) and are the required operations for this codebase.

## Mandatory Rule

- Do not introduce new calls to unsafe string APIs such as `strcpy`, `strncpy`, `strcat`, `strncat`, or direct `memset` for security-sensitive clearing.
- Prefer the `p_*_s` APIs from `utsecstr`.

## Required Replacements

- `strcpy(dst, src)` -> `p_strcpy_s(dst, dstSize, src)`
- `strncpy(dst, src, n)` -> `p_strncpy_s(dst, dstSize, src, n)`
- `strcat(dst, src)` -> `p_strcat_s(dst, dstSize, src)`
- `strncat(dst, src, n)` -> `p_strncat_s(dst, dstSize, src, n)`
- `memset(secret, 0, len)` -> `p_zeromem_s(secret, len)` when clearing sensitive memory

## API Behavior You Must Account For

### p_strcpy_s / p_strcopy_s

- `dsize` is the full destination buffer size.
- Success requires source length to fit (`stlen(source) < dsize`).
- Truncation is not supported. If source does not fit, function returns error and destination becomes empty string.
- `p_strcopy_s` also supports optional outputs:
- `pptargetEnd`: points to destination null terminator on success.
- `pbytesCopied`: byte count excluding null terminator.

### p_strncpy_s / p_strncat_s

- These support bounded copy/append using `maxSrcBytes`.
- They still null-terminate destination on success.
- They return error if destination capacity is exceeded before null termination.
- Use these when controlled truncation is intended.

### p_strcat_s

- Appends to existing destination string.
- On failure, destination is restored to original terminating null position (no partial append retained).

### Overlap Rules

- Do not rely on overlapping source/destination behavior.
- `p_strcopy_s` supports only the historical overlap pattern where destination is below source in memory (`dst < src`).
- `p_strcat_s`, `p_strncat_s`, and `p_strncpy_s` do not support overlap.

### Error Codes and ASSERT Builds

- Functions return standard error codes such as `ERANGE`, `EOVERFLOW`, `ENOTSUP`, and `EFAULT` (under trusted-caller validation paths).
- In `ASSERT_ON` builds, assert variants intentionally crash after reporting misuse. Write call sites so preconditions always hold.

## Usage Patterns

### 1. Copy When Source Must Fully Fit

```c
if (p_strcpy_s(tempBuf, sizeof(tempBuf), pSource) != 0)
{
    return FMBADVAL;
}
```

### 2. Bounded Copy With Intentional Truncation

```c
/* Copy at most sizeof(tempBuf)-1 bytes and always keep destination terminated. */
if (p_strncpy_s(tempBuf, sizeof(tempBuf), pSource, sizeof(tempBuf) - 1) != 0)
{
    return FMBADVAL;
}
```

### 3. Append Safely

```c
if (p_strcat_s(tempBuf, sizeof(tempBuf), suffix) != 0)
{
    return FMBADVAL;
}
```

### 4. Clear Sensitive Buffers

```c
p_zeromem_s(secretBuf, secretLen);
```

## Sizing Guidance (Common Mistake Prevention)

- Always pass destination allocation size as `dsize`.
- Do not pass current length as `dsize`.
- For bounded copy, set `maxSrcBytes` explicitly to avoid truncation asserts in strict paths.
- Prefer `sizeof(buffer)` for fixed arrays.
- For pointers, pass tracked allocation size from caller-owned metadata.

## Review Checklist

- No new usage of `strcpy`/`strncpy`/`strcat`/`strncat`.
- Correct `dsize` passed (allocation size, not content length).
- Return code is checked or intentionally handled.
- Bounded copy calls use deliberate `maxSrcBytes` values.
- Sensitive data uses `p_zeromem_s` instead of raw `memset`.
