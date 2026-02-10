# Security Policy — Project: REBOOT

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

This is a student game project. If you discover a security issue (e.g., secrets in commits, unsafe file handling):

1. **Do NOT open a public issue**
2. Email: (contact the repository owner via GitHub profile)
3. Or use [GitHub's private vulnerability reporting](https://github.com/el-pablos/reboot-godot-uas-projek/security/advisories/new)

### What qualifies as a security issue:

- Secrets, tokens, or credentials accidentally committed
- Save file manipulation that could affect other users
- Arbitrary code execution via save/settings files
- Path traversal in file loading

### Response timeline

- **Acknowledgment**: within 48 hours
- **Fix**: within 7 days for critical issues

## Security Best Practices in This Project

- No secrets stored in the repository (scanned in CI baseline)
- Save data uses JSON with schema validation
- File paths use Godot's `res://` and `user://` sandboxing
- No network requests or external API calls
- `.gitignore` excludes `secrets.gd` and sensitive files
